local pendingAccounts = {}

--- Remet au client les donnees de son loading screen (fond, musique, textes), avant qu'il ne l'affiche.
---
--- Elles viennent de la charte du serveur, qui vit en base : tant que les variables ne sont pas lues, la charte rendue est
--- celle du fichier config/branding_overrides.json, vide ou perimee (dossier remplace par une mise a jour, dossier non
--- inscriptible). Transmises des la connexion, juste apres un redemarrage, le fond et la musique regles dans Gestion ne
--- s'affichaient pas et n'apparaissaient qu'a la fin du chargement, quand le serveur repoussait la charte a jour.
--- On attend donc la lecture des variables (10 s au plus : sans base, on transmet ce que l'on a). Une fois l'attente
--- abandonnee, les joueurs suivants ne la refont pas : un serveur dont les variables ne se lisent pas ne doit pas retenir
--- chaque connexion 10 s de plus.
local variablesGaveUp = false

local function handOverLoadingScreen(deferrals)
    if type(deferrals.handover) ~= "function"
        or type(VFW.LoadingScreen) ~= "table"
        or type(VFW.LoadingScreen.GetHandoverData) ~= "function" then
        return
    end

    if not variablesGaveUp then
        local waited = 0
        while VFW.Variables and VFW.Variables.Loaded ~= true and waited < 10000 do
            Wait(100)
            waited = waited + 100
        end
        if VFW.Variables and VFW.Variables.Loaded ~= true then variablesGaveUp = true end
    end

    local ok, err = pcall(deferrals.handover, VFW.LoadingScreen.GetHandoverData())
    if not ok then
        console.warn(("[connexion] deferrals.handover a echoue : %s"):format(tostring(err)))
    end
end

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    Wait(0)

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
            -- Sans trace, ce refus ne disait rien : on indique en console si la base de
            -- données n'a jamais répondu, ou si c'est le démarrage qui est resté bloqué.
            if VFW.DbCallbackFired then
                console.error("[connexion] refus : le démarrage n'a jamais abouti alors que la base a répondu.")
                deferrals.done("Le serveur n'a pas fini de démarrer. Prévenez le staff si cela persiste.")
            else
                console.error("[connexion] refus : la base de données n'a jamais répondu (vérifiez mysql_connection_string).")
                deferrals.done("Le serveur n'arrive pas à joindre sa base de données. Prévenez le staff.")
            end
            return
        end
    end

    handOverLoadingScreen(deferrals)

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

    -- Un echec peut etre passager : connexion MySQL qui se renouvelle, insertion refusee
    -- parce que le joueur a tente deux fois de suite. Un refus definitif sur un premier
    -- echec laissait des joueurs dehors pour de bon. On retente une fois avant d'abandonner.
    if not ok or not account then
        console.warn(("[connexion] premier échec du chargement du compte %s : %s — nouvelle tentative")
            :format(identifier, tostring(account)))

        Wait(500)
        local retry = nil
        CreateThread(function()
            local okRetry, accountRetry = pcall(VFW.DB.LoadAccount, identifier)
            retry = { ok = okRetry, account = accountRetry }
        end)

        local waitedRetry = 0
        while not retry do
            Wait(100)
            waitedRetry = waitedRetry + 100
            if waitedRetry > 15000 then break end
        end

        if retry then
            ok, account = retry.ok, retry.account
        end
    end

    if not ok or not account then
        console.error(("[connexion] échec du chargement du compte %s : %s"):format(identifier, tostring(account)))

        -- La raison figurait uniquement dans la console du serveur. Un joueur qui
        -- n'entre pas ne peut rien en dire d'autre que « ça ne marche pas », et
        -- l'hébergeur n'a pas toujours accès au journal. On la lui montre : il peut
        -- alors la transmettre telle quelle.
        local reason = tostring(account or "raison inconnue")
        reason = reason:gsub("^.-:%d+:%s*", ""):gsub("%s+", " ")
        if #reason > 160 then reason = reason:sub(1, 157) .. "..." end

        deferrals.done(("Erreur lors du chargement de votre compte. Contactez le staff.\n\nDétail : %s")
            :format(reason))
        return
    end

    -- `users.banned` est un TINYINT(1) : suivant la version d'oxmysql il revient en booléen
    -- (true), en nombre (1) ou en texte ("1"). Le test `== 1` laissait donc entrer un compte
    -- banni — le bannissement semblait levé tout seul à la reconnexion.
    local banned = account.banned
    if banned == true or banned == 1 or banned == "1" then
        local message = "Vous êtes banni de ce serveur."
        if VFW.GetActiveBanMessage then
            local ok, detailed = pcall(VFW.GetActiveBanMessage, account.id)
            if ok and type(detailed) == "string" and detailed ~= "" then message = detailed end
        end
        console.warn(("[connexion] compte banni refusé : %s (compte %s)"):format(identifier, tostring(account.id)))
        deferrals.done(message)
        return
    end

    -- Le pseudo du compte n'etait ecrit nulle part : la colonne `users.name` existe depuis
    -- toujours mais aucune requete ne la remplissait, et la liste des joueurs hors ligne
    -- affichait donc « Sans pseudo » pour tout le monde. On la met a jour a chaque
    -- connexion : le pseudo suit ainsi les changements de nom FiveM.
    local playerName = GetPlayerName(source)
    if type(playerName) == "string" and playerName ~= "" then
        playerName = playerName:sub(1, 100)
        if account.name ~= playerName then
            account.name = playerName
            MySQL.update("UPDATE users SET name = ? WHERE id = ?", { playerName, account.id })
        end
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
