local pendingAccounts = {}

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    Wait(0)

    if type(deferrals.handover) == "function"
        and type(VFW.LoadingScreen) == "table"
        and type(VFW.LoadingScreen.GetHandoverData) == "function" then
        local okHandover, errHandover = pcall(deferrals.handover, VFW.LoadingScreen.GetHandoverData())
        if not okHandover then
            console.warn(("[connexion] deferrals.handover a echoue : %s"):format(tostring(errHandover)))
        end
    end

    local identifier = VFW.GetIdentifier(source)
    if not identifier then
        deferrals.done("Impossible de lire votre licence Rockstar. Redémarrez FiveM.")
        return
    end

    deferrals.update(("Bienvenue sur %s, chargement de votre compte..."):format(VFW.BrandName()))

    local waited = 0
    while not VFW.Ready do
        Wait(100)
        waited = waited + 100
        if waited > 30000 then
            deferrals.done("Le serveur n'a pas fini de démarrer. Réessayez dans quelques secondes.")
            return
        end
    end

    -- Chargement du compte avec délai maximum : si la base de données ne répond pas,
    -- le joueur ne doit pas rester bloqué sur « chargement de votre compte… ».
    local result = nil
    CreateThread(function()
        local ok, account = pcall(VFW.DB.LoadAccount, identifier)
        result = { ok = ok, account = account }
    end)
    local waitedDb = 0
    while not result do
        Wait(100)
        waitedDb = waitedDb + 100
        if waitedDb == 5000 then deferrals.update(("Bienvenue sur %s, la base de données met un peu de temps à répondre..."):format(VFW.BrandName())) end
        if waitedDb > 20000 then
            console.error(("[connexion] chargement du compte %s : pas de réponse de la base de données après 20 s"):format(identifier))
            deferrals.done("Le serveur n'a pas pu charger votre compte à temps (base de données). Réessayez dans quelques secondes.")
            return
        end
    end
    local ok, account = result.ok, result.account
    if not ok or not account then
        console.error(("[connexion] échec du chargement du compte %s : %s"):format(identifier, tostring(account)))
        deferrals.done("Erreur lors du chargement de votre compte. Contactez le staff.")
        return
    end

    if account.banned == 1 then
        deferrals.done("Vous êtes banni de ce serveur.")
        return
    end

    pendingAccounts[identifier] = account
    deferrals.done()
end)

RegisterNetEvent("core:server:loadPlayerGlobal", function()
    local source = source
    local identifier = VFW.GetIdentifier(source)
    if not identifier then return end

    local account = pendingAccounts[identifier] or VFW.DB.LoadAccount(identifier)
    pendingAccounts[identifier] = account

    Player(source).state:set("id", account.id, true)

    local globalPayload = {
        id = account.id,
        uuid = account.uuid,
        permissions = account.permissions or {},
        vip_tier = account.vip_tier or 0,
        level = account.level or 0,
        spacecoins = account.spacecoins or 0,
        role = account.role or "user",
        roleId = account.role_id or 0,
    }
    if VFW.HydrateNiveau6Permissions then
        VFW.HydrateNiveau6Permissions(globalPayload)
        account.permissions = globalPayload.permissions
        account.role = globalPayload.role
    end
    TriggerClientEvent("vfw:updatePlayerGlobalData", source, globalPayload)

    TriggerClientEvent("vfw:loadItems", source, VFW.Items)
end)

function VFW.GetPendingAccount(source)
    local identifier = VFW.GetIdentifier(source)
    if not identifier then return nil end
    local account = pendingAccounts[identifier]
    if not account then
        account = VFW.DB.LoadAccount(identifier)
        pendingAccounts[identifier] = account
    end
    return account
end

function VFW.LogoutPlayer(source, keepConnected)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.save()

    VFW.Players[source] = nil
    -- Reconnexion rapide : une nouvelle session a pu charger le même personnage avant que
    -- l'ancienne soit détectée comme déconnectée — on ne retire que nos propres entrées.
    if VFW.PlayersByIdentifier[xPlayer.identifier] == xPlayer then VFW.PlayersByIdentifier[xPlayer.identifier] = nil end
    if VFW.PlayersByCharId[xPlayer.charId] == xPlayer then VFW.PlayersByCharId[xPlayer.charId] = nil end
    VFW.SetGlobalPlayerCount()

    TriggerEvent("vfw:playerDropped", source, xPlayer)

    if keepConnected then
        TriggerClientEvent("vfw:onPlayerLogout", source)
    end
end

AddEventHandler("playerDropped", function(reason)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)

    TriggerClientEvent("onPlayerDropped", -1, source, GetPlayerName(source) or "unknown", source)

    local identifier = VFW.GetIdentifier(source)
    if identifier then
        -- ne pas effacer le compte d'une nouvelle session du même joueur (reconnexion rapide)
        local otherSession = false
        for _, other in ipairs(GetPlayers()) do
            if tonumber(other) ~= tonumber(source) and VFW.GetIdentifier(other) == identifier then
                otherSession = true
                break
            end
        end
        if not otherSession then pendingAccounts[identifier] = nil end
    end

    if xPlayer then
        VFW.LogoutPlayer(source, false)
    end
end)

RegisterNetEvent("vfw:onPlayerLoaded", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.loaded = true
    TriggerEvent("vfw:playerLoaded", source, xPlayer)
end)

RegisterNetEvent("vfw:onPlayerConnect", function()
    local source = source
    if Config.Multichar then return end
    TriggerEvent("vfw:multicharacter:loadSlot", source, 1, false)
end)
