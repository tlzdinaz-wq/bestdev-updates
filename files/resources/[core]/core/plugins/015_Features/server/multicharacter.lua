local pendingSlot = {}

local function getSlots(account)
    return tonumber(account.slots) or Config.Multicharacter.Slots
end

local function buildSelectionEntry(row)
    local job = VFW.DB.BuildJob(row.job, row.job_grade)
    local faction = row.job2 ~= "" and VFW.DB.BuildJob(row.job2, row.job2_grade) or nil

    local cash = 0
    for i = 1, #row.accounts do
        if row.accounts[i].name == "money" then
            cash = row.accounts[i].money
            break
        end
    end

    return {
        id = row.id,
        charId = row.id,
        slot = row.char_slot,
        info = row.address ~= "" and row.address or nil,
        firstname = row.firstname,
        lastname = row.lastname,
        mugshot = row.mugshot,
        jobLabel = job.label,
        factionLabel = faction and faction.label or "",
        cash = cash,
        height = row.height,
        dateofbirth = row.dateofbirth,
        skin = row.skin,
        tattoos = row.tattoos,
    }
end

-- Chargement des personnages avec nouvelle tentative : une erreur SQL passagère ne doit
-- jamais se traduire par « aucun personnage » (le joueur serait envoyé au créateur).
local function loadCharactersSafe(account)
    for attempt = 1, 3 do
        local ok, rows = pcall(VFW.DB.LoadCharacters, account.id)
        if ok and type(rows) == "table" then return rows end
        console.warn(("[multichar] chargement des personnages de %s échoué (essai %d) : %s"):format(tostring(account.identifier), attempt, tostring(rows)))
        Wait(400 * attempt)
    end
    return nil
end

local function sendSelection(source)
    local account = VFW.GetPendingAccount(source)
    if not account then
        -- compte pas encore prêt (reconnexion rapide) : on laisse un peu de temps
        for _ = 1, 10 do
            Wait(200)
            account = VFW.GetPendingAccount(source)
            if account then break end
        end
        if not account then
            DropPlayer(source, "Votre compte n'a pas pu être chargé. Reconnectez-vous.")
            return
        end
    end

    local rows = loadCharactersSafe(account)
    if not rows then
        DropPlayer(source, "Erreur de base de données lors du chargement de vos personnages. Reconnectez-vous dans quelques secondes.")
        return
    end

    local characters = {}
    for i = 1, #rows do
        characters[i] = buildSelectionEntry(rows[i])
    end

    TriggerClientEvent("vfw:multicharacter:SetupUI", source, characters, getSlots(account))
end

local function firstFreeSlot(account)
    local rows = VFW.DB.LoadCharacters(account.id)
    local used = {}
    for i = 1, #rows do
        used[rows[i].char_slot] = true
    end
    for slot = 1, getSlots(account) do
        if not used[slot] then return slot end
    end
    return nil
end

function VFW.LoadCharacterForSource(source, row, account, isNew)
    local xPlayer = VFW.CreateExtendedPlayer(source, row, account)

    VFW.Players[source] = xPlayer
    VFW.PlayersByIdentifier[xPlayer.identifier] = xPlayer
    VFW.PlayersByCharId[xPlayer.charId] = xPlayer
    VFW.SetGlobalPlayerCount()

    local playerData = xPlayer.getPlayerData()

    TriggerClientEvent("vfw:loadItems", source, VFW.Items)
    TriggerClientEvent("vfw:loadPlayerData", source, playerData)
    TriggerClientEvent("vfw:playerLoaded", source, playerData, isNew and true or false, xPlayer.skin)

    if not Config.Multichar then
        TriggerClientEvent("vfw:client:playerLoaded", source, playerData, isNew and true or false, xPlayer.skin)
    end

    TriggerEvent("vfw:characterLoaded", source, xPlayer)
    return xPlayer
end

RegisterNetEvent("vfw:multicharacter:SetupCharacters", function()
    local source = source
    if VFW.GetPlayerFromId(source) then
        VFW.LogoutPlayer(source, false)
    end
    sendSelection(source)
end)

AddEventHandler("vfw:multicharacter:loadSlot", function(source, slot, isNew)
    local account = VFW.GetPendingAccount(source)
    if not account then return end

    local identifier = VFW.GetCharIdentifier(source, slot)
    if not identifier then return end

    local row = VFW.DB.LoadCharacter(identifier)
    if not row then
        pendingSlot[source] = slot
        TriggerClientEvent("vfw:multicharacter:forceCreator", source, slot)
        return
    end

    VFW.LoadCharacterForSource(source, row, account, isNew)
end)

RegisterNetEvent("vfw:multicharacter:CharacterChosen", function(id, isNew)
    local source = source
    local account = VFW.GetPendingAccount(source)
    if not account then return end

    if isNew then
        local slot = firstFreeSlot(account)
        if not slot then
            VFW.ShowNotification(source, {
                type = "ROUGE",
                content = "Vous n'avez plus de slot de personnage disponible.",
            })
            return
        end
        pendingSlot[source] = slot
        return
    end

    local rows = loadCharactersSafe(account)
    if not rows then
        DropPlayer(source, "Erreur de base de données lors du chargement de votre personnage. Reconnectez-vous.")
        return
    end
    local wanted = tonumber(id)
    local row
    for i = 1, #rows do
        if tonumber(rows[i].id) == wanted then
            row = rows[i]
            break
        end
    end
    if not row and wanted and rows[wanted] then
        -- secours : un client qui envoie encore l'index de la liste (1, 2, 3…)
        row = rows[wanted]
    end
    if not row then
        console.warn(("[multichar] personnage %s introuvable pour %s (%d personnage(s))"):format(tostring(id), account.identifier, #rows))
        VFW.ShowNotification(source, { type = "ROUGE", content = "Personnage introuvable, sélection rechargée." })
        sendSelection(source)
        return
    end

    pendingSlot[source] = row.char_slot
    VFW.LoadCharacterForSource(source, row, account, false)
end)

RegisterNetEvent("core:server:createIdentity", function(data)
    local source = source
    if type(data) ~= "table" then return end

    local account = VFW.GetPendingAccount(source)
    if not account then return end

    local slot = pendingSlot[source] or firstFreeSlot(account)
    if not slot then return end

    local identifier = VFW.GetCharIdentifier(source, slot)
    if not identifier then return end

    local existing = VFW.DB.LoadCharacter(identifier)
    if existing then
        -- Le personnage existe déjà (créateur rouvert après une apparence non enregistrée,
        -- ou reconnexion pendant la création) : on complète l'apparence et on le charge,
        -- au lieu de laisser le joueur sans interface.
        console.warn(("[multichar] slot %d de %s existe déjà : apparence mise à jour et personnage chargé"):format(slot, account.identifier))
        local skin = type(data.skin) == "table" and next(data.skin) ~= nil and data.skin or nil
        if skin then
            pcall(MySQL.update.await, "UPDATE characters SET skin = ?, tattoos = ? WHERE identifier = ?", {
                json.encode(skin), json.encode(data.tattoos or existing.tattoos or {}), identifier,
            })
            existing.skin = skin
            if type(data.tattoos) == "table" then existing.tattoos = data.tattoos end
        end
        pendingSlot[source] = nil
        VFW.LoadCharacterForSource(source, existing, account, false)
        return
    end

    local firstname = tostring(data.firstname or ""):sub(1, 50)
    local lastname = tostring(data.lastname or ""):sub(1, 50)
    if firstname == "" or lastname == "" then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Cette identité n'est pas valide." })
        return
    end

    VFW.DB.CreateCharacter(account.id, slot, identifier, {
        firstname = firstname,
        lastname = lastname,
        dateofbirth = tostring(data.dateofbirth or ""):sub(1, 10),
        sex = (data.sex == "f" or data.sex == "F") and "f" or "m",
        birthplace = tostring(data.birthplace or ""):sub(1, 80),
        height = tonumber(data.height) or 175,
        skin = data.skin or {},
        tattoos = data.tattoos or {},
        mugshot = data.mugshot or "",
    })

    local row = VFW.DB.LoadCharacter(identifier)
    if not row then
        console.error(("[multichar] création du personnage %s échouée"):format(identifier))
        return
    end

    pendingSlot[source] = nil
    VFW.LoadCharacterForSource(source, row, account, false)
end)

RegisterNetEvent("core:server:startCreator", function()
    local source = source
    TriggerClientEvent("core:client:spawnCharCreator", source)
end)

RegisterNetEvent("vfw:multicharacter:RequestTimeSync", function()
    local source = source
    TriggerClientEvent("vfw:sync:time", source, GlobalState.EnvironmentTime, GlobalState.EnvironmentWeather)
    TriggerEvent("vfw:sync:requestTime", source)
end)

RegisterNetEvent("vfw:multicharacter:relog", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if Player(source).state.isCuffed then return end

    VFW.LogoutPlayer(source, true)
end)

RegisterNetEvent("vfw:multicharacter:spawnAnimationComplete", function()
    local source = source
    TriggerEvent("vfw:spawnProtection:release", source)
end)

RegisterNetEvent("vfw:sync:onPlayerJoined", function()
    local source = source
    TriggerEvent("vfw:sync:playerJoined", source)
end)

RegisterNetEvent("core:sync:onPlayerJoined", function()
    local source = source
    TriggerEvent("vfw:sync:playerJoined", source)
end)

RegisterServerCallback("vfw:staff:getStaffPed", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission("persist_staff_ped") then return nil end
    return xPlayer.getMeta("staffPed")
end)

RegisterServerCallback("core:server:characterCreator", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    local account = VFW.GetPendingAccount(source)
    if not account then return {} end

    local perms = (xPlayer and xPlayer.permissions) or account.permissions or {}
    if not (perms.vip_bronze or perms.vip_silver or perms.vip_gold) then return {} end

    local rows = MySQL.query.await(
        "SELECT * FROM characters WHERE account_id = ? AND deleted_at IS NOT NULL",
        { account.id }
    ) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local tattoos = VFW.DB.Decode(row.tattoos, {})
        local mapped = {}
        for t = 1, #tattoos do
            mapped[t] = { Collection = tattoos[t].Collection, HashName = tattoos[t].Hash or tattoos[t].HashName }
        end

        out[i] = {
            firstname = row.firstname,
            lastname = row.lastname,
            age = tostring(row.dateofbirth or ""),
            birthplaces = row.birthplace,
            sex = (row.sex == "f") and "F" or "M",
            skin = VFW.DB.Decode(row.skin, {}),
            tattoos = mapped,
        }
    end

    return out
end)

local function canManageMugshots(xPlayer)
    if not xPlayer then return false end
    return xPlayer.hasPermission("mugshot")
        or xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("gestion_items")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin")
        or xPlayer.hasPermission("server_management")
end

RegisterServerCallback("vfw:server:getSkinByCharId", function(source, charId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canManageMugshots(xPlayer) then return nil end

    local row = MySQL.single.await("SELECT skin, tattoos FROM characters WHERE id = ?", { tonumber(charId) })
    if not row then return nil end

    local tattoos = VFW.DB.Decode(row.tattoos, {})
    local mapped = {}
    for t = 1, #tattoos do
        mapped[t] = { Collection = tattoos[t].Collection, HashName = tattoos[t].Hash or tattoos[t].HashName }
    end

    return VFW.DB.Decode(row.skin, {}), mapped
end)

RegisterServerCallback("vfw:skin:getPlayerSkin", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    return xPlayer.skin, xPlayer.tattoos
end)

RegisterServerCallback("core:server:checkIdentityName", function(source, firstname, lastname)
    local row = MySQL.single.await(
        "SELECT id FROM characters WHERE firstname = ? AND lastname = ? AND deleted_at IS NULL",
        { firstname, lastname }
    )
    return row == nil
end)

local MUGSHOT_MAX_LENGTH = 512

local function mugshotCdnBase()
    local base = GetConvar("core_cdn_public_base", "")
    if base ~= "" then return base end
    if BRANDING and type(BRANDING.cdnBase) == "string" then return BRANDING.cdnBase end
    return ""
end

local function isValidMugshotUrl(url)
    if not url or type(url) ~= "string" or url == "" then
        return false
    end

    if #url > MUGSHOT_MAX_LENGTH then
        return false
    end

    if not url:match("^https://") then
        return false
    end

    if url:find("[%s\"'<>\\]") then
        return false
    end

    local host = (url:match("^https://([^/]+)") or ""):lower()
    if host:find("fivemanage.com", 1, true) or host:find("fmfile.com", 1, true) then
        return true
    end

    local base = mugshotCdnBase()
    if base ~= "" then
        return url:sub(1, #base) == base
    end

    return true
end

RegisterNetEvent("vfw:server:setMugshot", function(url)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not isValidMugshotUrl(url) then return end
    xPlayer.mugshot = url
    xPlayer.setPlayerData("mugshot", url)
    pcall(MySQL.update.await, "UPDATE characters SET mugshot = ? WHERE identifier = ?", { url, xPlayer.identifier })
    if VFW.GestionImages and VFW.GestionImages.Persist then
        VFW.GestionImages.Persist("mugshot", tostring(xPlayer.charId or xPlayer.identifier), url)
    end
end)

RegisterNetEvent("vfw:server:setMugshotForChar", function(charId, url)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canManageMugshots(xPlayer) then return end
    if not isValidMugshotUrl(url) then return end
    local id = tonumber(charId)
    if not id then return end
    pcall(MySQL.update.await, "UPDATE characters SET mugshot = ? WHERE id = ?", { url, id })
    if VFW.GestionImages and VFW.GestionImages.Persist then
        VFW.GestionImages.Persist("mugshot", tostring(id), url)
    end
    local target = VFW.GetPlayerFromCharId and VFW.GetPlayerFromCharId(id)
    if target then
        target.mugshot = url
        if target.setPlayerData then
            target.setPlayerData("mugshot", url)
        end
    end
end)

RegisterNetEvent("core:server:instanceCreator", function(state)
    local source = source

    if state then
        if not pendingSlot[source] then
            local xPlayer = VFW.GetPlayerFromId(source)
            if not xPlayer then return end
            if not (xPlayer.hasPermission("staff_menu") or canManageMugshots(xPlayer)) then return end
        end
        SetPlayerRoutingBucket(source, 10000 + source)
        return
    end

    if GetPlayerRoutingBucket(source) ~= 10000 + source then return end

    SetPlayerRoutingBucket(source, 0)
end)

AddEventHandler("playerDropped", function()
    local source = source
    pendingSlot[source] = nil
end)
