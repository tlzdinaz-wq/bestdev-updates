local Fleeca = {
    banks = {},
    hacking = {},
    robberies = {},
    drilling = {},
    settings = {},
}

local BUILDER_PERM = "builder_fleeca"
local DRILL_ITEM = "foreuse"
local ROBBERY_DURATION = 600
local SAFE_LOOT_ITEM = "liasse_argent"
local SETTINGS_TABLE = "fleeca_settings"

-- Réglages du menu Builders > Fleeca > Paramètres globaux (durées en minutes).
local DEFAULT_SETTINGS = {
    globalCooldown = 60,
    playerCooldown = 0,
    minPoliceRequired = 0,
    safeRewardMin = 215,
    safeRewardMax = 235,
    requiredUsbItem = "usb_piratage_fleeca",
    policeBlipDuration = 8,
    doorOpenDuration = 30,
}

local playerCooldowns = {}

local function LoadSettings()
    IL.EnsureSettingsTable(SETTINGS_TABLE)
    Fleeca.settings = IL.LoadSettings(SETTINGS_TABLE, DEFAULT_SETTINGS)
    local s = Fleeca.settings
    for key, default in pairs(DEFAULT_SETTINGS) do
        if type(default) == "number" then
            s[key] = math.max(0, IL.Num(s[key], default))
        end
    end
    s.safeRewardMin = math.max(1, math.floor(s.safeRewardMin))
    s.safeRewardMax = math.max(s.safeRewardMin, math.floor(s.safeRewardMax))
    if type(s.requiredUsbItem) ~= "string" or s.requiredUsbItem == "" then
        s.requiredUsbItem = DEFAULT_SETTINGS.requiredUsbItem
    end
end

local function EnsureBanksTable()
    IL.Query([[
        CREATE TABLE IF NOT EXISTS `fleeca_banks` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(100) NOT NULL,
            `pos_x` DOUBLE NOT NULL DEFAULT 0,
            `pos_y` DOUBLE NOT NULL DEFAULT 0,
            `pos_z` DOUBLE NOT NULL DEFAULT 0,
            `active` TINYINT(1) NOT NULL DEFAULT 1,
            `blip_enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `can_rob` TINYINT(1) NOT NULL DEFAULT 1,
            `door_hack_x` DOUBLE DEFAULT NULL,
            `door_hack_y` DOUBLE DEFAULT NULL,
            `door_hack_z` DOUBLE DEFAULT NULL,
            `vault_door_x` DOUBLE DEFAULT NULL,
            `vault_door_y` DOUBLE DEFAULT NULL,
            `vault_door_z` DOUBLE DEFAULT NULL,
            `vault_door_model` VARCHAR(60) DEFAULT NULL,
            `safe_positions` LONGTEXT DEFAULT NULL,
            `account_access_positions` LONGTEXT DEFAULT NULL,
            `last_robbed` BIGINT(20) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

local function LoadBanks()
    Fleeca.banks = {}
    local rows = IL.Query("SELECT * FROM fleeca_banks")
    for i = 1, #rows do
        local row = rows[i]
        Fleeca.banks[row.id] = {
            id = row.id,
            name = row.name or "Fleeca",
            pos = { x = IL.Num(row.pos_x, 0.0), y = IL.Num(row.pos_y, 0.0), z = IL.Num(row.pos_z, 0.0) },
            active = IL.Bool(row.active),
            blipEnabled = IL.Bool(row.blip_enabled),
            canRob = IL.Bool(row.can_rob),
            doorHackPos = { x = IL.Num(row.door_hack_x, 0.0), y = IL.Num(row.door_hack_y, 0.0), z = IL.Num(row.door_hack_z, 0.0) },
            vaultDoorPos = {
                x = IL.Num(row.vault_door_x, 0.0),
                y = IL.Num(row.vault_door_y, 0.0),
                z = IL.Num(row.vault_door_z, 0.0),
                model = tonumber(row.vault_door_model) or row.vault_door_model or "v_ilev_gb_vauldr",
            },
            safePositions = IL.Decode(row.safe_positions, {}),
            accountAccessPositions = IL.Decode(row.account_access_positions, {}),
            lastRobbed = IL.Int(row.last_robbed, 0),
        }
    end
end

local function BanksMap()
    local out = {}
    for id, bank in pairs(Fleeca.banks) do
        out[id] = {
            pos = bank.pos,
            active = bank.active,
            blipEnabled = bank.blipEnabled,
            canRob = bank.canRob,
            doorHackPos = bank.doorHackPos,
            safePositions = bank.safePositions,
            accountAccessPositions = bank.accountAccessPositions,
            vaultDoorPos = bank.vaultDoorPos,
            name = bank.name,
        }
    end
    return out
end

local function CloseRobbery(bankId)
    local robbery = Fleeca.robberies[bankId]
    if not robbery then return end
    Fleeca.robberies[bankId] = nil
    TriggerClientEvent("core:fleeca:robberyTimeoutSync", -1, bankId)
    TriggerClientEvent("core:fleeca:syncRobberyState", -1, bankId, false, 0)
end

IL.OnReady(function()
    EnsureBanksTable()
    LoadSettings()
    LoadBanks()
    TriggerClientEvent("core:fleeca:syncBanks", -1, BanksMap())
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("core:fleeca:syncBanks", source, BanksMap())
    for bankId, robbery in pairs(Fleeca.robberies) do
        local remaining = math.max(0, (robbery.endsAt - IL.Now()) * 1000)
        TriggerClientEvent("core:fleeca:syncRobberyState", source, bankId, true, remaining)
        local bank = Fleeca.banks[bankId]
        if bank and robbery.doorOpen then
            TriggerClientEvent("core:fleeca:openVaultDoor", source, bankId, bank.vaultDoorPos, bank.vaultDoorPos.model)
        end
        for safeIndex in pairs(robbery.drilled) do
            TriggerClientEvent("core:fleeca:syncDrilledSafe", source, bankId, safeIndex)
        end
    end
    for bankId, hack in pairs(Fleeca.hacking) do
        TriggerClientEvent("core:fleeca:syncHackingState", source, bankId, true, hack.source)
    end
end)

IL.OnPlayerDropped(function(source)
    for bankId, hack in pairs(Fleeca.hacking) do
        if hack.source == source then
            Fleeca.hacking[bankId] = nil
            TriggerClientEvent("core:fleeca:syncHackingState", -1, bankId, false, 0)
        end
    end
    for key, drill in pairs(Fleeca.drilling) do
        if drill.source == source then
            Fleeca.drilling[key] = nil
            TriggerClientEvent("core:fleeca:syncDrillingState", -1, drill.bankId, drill.safeIndex, false, 0)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        local now = IL.Now()
        for bankId, robbery in pairs(Fleeca.robberies) do
            if now >= robbery.endsAt then
                CloseRobbery(bankId)
            end
        end
        for bankId, hack in pairs(Fleeca.hacking) do
            if now - hack.startedAt > 300 then
                Fleeca.hacking[bankId] = nil
                TriggerClientEvent("core:fleeca:syncHackingState", -1, bankId, false, 0)
            end
        end
        for key, drill in pairs(Fleeca.drilling) do
            if now - drill.startedAt > 300 then
                Fleeca.drilling[key] = nil
                TriggerClientEvent("core:fleeca:syncDrillingState", -1, drill.bankId, drill.safeIndex, false, 0)
            end
        end
    end
end)

RegisterNetEvent("core:fleeca:requestBanksList", function()
    local source = source
    TriggerClientEvent("core:fleeca:syncBanks", source, BanksMap())
end)

local function PlayerKey(source, xPlayer)
    return (xPlayer and xPlayer.identifier) or source
end

IL.RegisterCallback("core:fleeca:canHackBank", function(source, bankId)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local id = IL.Int(bankId, nil)
    local bank = id and Fleeca.banks[id] or nil
    if not bank then return false, "Cette banque n'est pas valide" end
    if not bank.active or not bank.canRob then return false, "Cette banque n'est pas braquable" end

    if Fleeca.hacking[id] then return false, "Un piratage est deja en cours" end
    if Fleeca.robberies[id] then return false, "Un braquage est deja en cours" end

    local now = IL.Now()
    local settings = Fleeca.settings
    if bank.lastRobbed > 0 and (now - bank.lastRobbed) < settings.globalCooldown * 60 then
        return false, "Cette banque a ete braquee recemment"
    end

    local lastByPlayer = playerCooldowns[PlayerKey(source, xPlayer)]
    if settings.playerCooldown > 0 and lastByPlayer and (now - lastByPlayer) < settings.playerCooldown * 60 then
        return false, "Vous avez braque une banque recemment"
    end

    local minPolice = math.floor(settings.minPoliceRequired)
    if minPolice > 0 and IL.PoliceOnDutyCount() < minPolice then
        return false, "Trop peu de policiers en service"
    end

    if not xPlayer.haveItem(settings.requiredUsbItem, 1) then
        return false, "Il vous faut une cle USB de piratage"
    end

    if IL.DistanceTo(source, bank.doorHackPos.x, bank.doorHackPos.y, bank.doorHackPos.z) > 10.0 then
        return false, "Vous etes trop loin du terminal"
    end

    return true, nil
end)

IL.RegisterCallback("core:fleeca:canDrillSafe", function(source, bankId, safeIndex)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local id = IL.Int(bankId, nil)
    local index = IL.Int(safeIndex, nil)
    local bank = id and Fleeca.banks[id] or nil
    if not bank or not index then return false, "Ce coffre n'est pas valide" end

    local robbery = Fleeca.robberies[id]
    if not robbery then return false, "Aucun braquage en cours" end
    if robbery.drilled[index] then return false, "Ce coffre a deja ete perce" end

    local key = id .. ":" .. index
    if Fleeca.drilling[key] then return false, "Ce coffre est deja en cours de percage" end

    if not xPlayer.haveItem(DRILL_ITEM, 1) then
        return false, "Il vous faut une foreuse"
    end

    local safePos = IL.IsTable(bank.safePositions) and bank.safePositions[index] or nil
    if not IL.IsTable(safePos) then return false, "Ce coffre n'est pas valide" end

    if IL.DistanceTo(source, IL.Num(safePos.x, 0.0), IL.Num(safePos.y, 0.0), IL.Num(safePos.z, 0.0)) > 10.0 then
        return false, "Vous etes trop loin du coffre"
    end

    return true, nil
end)

RegisterNetEvent("core:fleeca:startHack", function(bankId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(bankId, nil)
    local bank = id and Fleeca.banks[id] or nil
    if not bank or not bank.active or not bank.canRob then return end
    if Fleeca.hacking[id] or Fleeca.robberies[id] then return end
    if not xPlayer.haveItem(Fleeca.settings.requiredUsbItem, 1) then return end

    Fleeca.hacking[id] = { source = source, startedAt = IL.Now() }
    TriggerClientEvent("core:fleeca:syncHackingState", -1, id, true, source)
    IL.AlertPolice("core:fleeca:createPoliceBlip", id, math.floor(Fleeca.settings.policeBlipDuration * 60000))
end)

RegisterNetEvent("core:fleeca:completeHack", function(bankId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(bankId, nil)
    local bank = id and Fleeca.banks[id] or nil
    if not bank then return end

    local hack = Fleeca.hacking[id]
    if not hack or hack.source ~= source then return end

    Fleeca.hacking[id] = nil
    TriggerClientEvent("core:fleeca:syncHackingState", -1, id, false, 0)

    IL.TakeItem(xPlayer, Fleeca.settings.requiredUsbItem, 1)

    local now = IL.Now()
    playerCooldowns[PlayerKey(source, xPlayer)] = now
    bank.lastRobbed = now
    IL.Execute("UPDATE fleeca_banks SET last_robbed = ? WHERE id = ?", { now, id })

    Fleeca.robberies[id] = {
        source = source,
        startedAt = now,
        endsAt = now + ROBBERY_DURATION,
        drilled = {},
        doorOpen = true,
    }

    TriggerClientEvent("core:fleeca:openVaultDoor", -1, id, bank.vaultDoorPos, bank.vaultDoorPos.model)
    TriggerClientEvent("core:fleeca:syncRobberyState", -1, id, true, ROBBERY_DURATION * 1000)

    SetTimeout(math.floor(Fleeca.settings.doorOpenDuration * 60000), function()
        local robbery = Fleeca.robberies[id]
        if robbery then
            robbery.doorOpen = false
        end
        TriggerClientEvent("core:fleeca:closeVaultDoor", -1, id, bank.vaultDoorPos, bank.vaultDoorPos.model)
    end)
end)

RegisterNetEvent("core:fleeca:failHack", function(bankId)
    local source = source
    local id = IL.Int(bankId, nil)
    if not id then return end

    local hack = Fleeca.hacking[id]
    if not hack or hack.source ~= source then return end

    Fleeca.hacking[id] = nil
    TriggerClientEvent("core:fleeca:syncHackingState", -1, id, false, 0)

    local xPlayer = IL.Player(source)
    if xPlayer then
        IL.TakeItem(xPlayer, Fleeca.settings.requiredUsbItem, 1)
    end
end)

RegisterNetEvent("core:fleeca:robberyTimeout", function(bankId)
    local source = source
    local id = IL.Int(bankId, nil)
    if not id then return end

    local robbery = Fleeca.robberies[id]
    if not robbery then return end
    if IL.Now() < robbery.endsAt then return end

    CloseRobbery(id)
end)

RegisterNetEvent("core:fleeca:startDrill", function(bankId, safeIndex)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(bankId, nil)
    local index = IL.Int(safeIndex, nil)
    if not id or not index then return end

    local bank = Fleeca.banks[id]
    if not bank or not IL.IsTable(bank.safePositions) or not IL.IsTable(bank.safePositions[index]) then return end

    local robbery = Fleeca.robberies[id]
    if not robbery or robbery.drilled[index] then return end

    local key = id .. ":" .. index
    if Fleeca.drilling[key] then return end
    if not xPlayer.haveItem(DRILL_ITEM, 1) then return end

    Fleeca.drilling[key] = { source = source, bankId = id, safeIndex = index, startedAt = IL.Now() }
    TriggerClientEvent("core:fleeca:syncDrillingState", -1, id, index, true, source)
end)

RegisterNetEvent("core:fleeca:completeDrill", function(bankId, safeIndex)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(bankId, nil)
    local index = IL.Int(safeIndex, nil)
    if not id or not index then return end

    local key = id .. ":" .. index
    local drill = Fleeca.drilling[key]
    if not drill or drill.source ~= source then return end
    Fleeca.drilling[key] = nil

    local robbery = Fleeca.robberies[id]
    if not robbery or robbery.drilled[index] then
        TriggerClientEvent("core:fleeca:syncDrillingState", -1, id, index, false, 0)
        return
    end

    robbery.drilled[index] = true

    local bundles = math.random(Fleeca.settings.safeRewardMin, Fleeca.settings.safeRewardMax)
    if IL.ItemExists(SAFE_LOOT_ITEM) and xPlayer.canCarryItem(SAFE_LOOT_ITEM, bundles) then
        IL.GiveItem(xPlayer, SAFE_LOOT_ITEM, bundles, true)
    else
        IL.GiveMoney(xPlayer, "black_money", bundles * 10, "fleeca-safe")
    end

    TriggerClientEvent("core:fleeca:syncDrilledSafe", -1, id, index)
    TriggerClientEvent("core:fleeca:syncDrillingState", -1, id, index, false, 0)
end)

RegisterNetEvent("core:fleeca:failDrill", function(bankId, safeIndex)
    local source = source
    local id = IL.Int(bankId, nil)
    local index = IL.Int(safeIndex, nil)
    if not id or not index then return end

    local key = id .. ":" .. index
    local drill = Fleeca.drilling[key]
    if not drill or drill.source ~= source then return end

    Fleeca.drilling[key] = nil
    TriggerClientEvent("core:fleeca:syncDrillingState", -1, id, index, false, 0)
end)

RegisterNetEvent("core:fleeca:reload", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    LoadBanks()
    TriggerClientEvent("core:fleeca:syncBanks", -1, BanksMap())
end)

-- ── Builder (Builders > Fleeca) ──────────────────────────────────────────────────────────────
-- Le menu du staff appelait des callbacks / événements que le serveur ne gérait pas : créer, modifier
-- ou supprimer une banque ne faisait rien, la liste et les paramètres restaient vides.

local function IsBuilder(source)
    local xPlayer = IL.Player(source)
    return xPlayer ~= nil and xPlayer.hasPermission(BUILDER_PERM)
end

local function Trim(value)
    local text = IL.Str(value, "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function CleanPos(value, keepHeading)
    if not IL.IsTable(value) then return nil end
    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z then return nil end
    local out = { x = x, y = y, z = z }
    if keepHeading and tonumber(value.h) then out.h = tonumber(value.h) end
    return out
end

-- Une liste à trous (coffre #3 défini sans le #1) arrive sous forme de table à clés numériques :
-- on la remet à plat dans l'ordre des clés.
local function CleanPosList(value, max)
    local out = {}
    if not IL.IsTable(value) then return out end
    local keys = {}
    for k in pairs(value) do
        if tonumber(k) then keys[#keys + 1] = tonumber(k) end
    end
    table.sort(keys)
    for i = 1, #keys do
        local pos = CleanPos(value[keys[i]] or value[tostring(keys[i])], true)
        if pos then
            out[#out + 1] = pos
            if max and #out >= max then break end
        end
    end
    return out
end

local function CleanVault(value)
    local pos = CleanPos(value)
    if not pos then return nil end
    local model = value.model
    if type(model) ~= "string" and type(model) ~= "number" then model = "v_ilev_gb_vauldr" end
    pos.model = tonumber(model) or tostring(model)
    return pos
end

local function Broadcast()
    TriggerClientEvent("core:fleeca:syncBanks", -1, BanksMap())
end

local function SaveBank(bank)
    local hack, vault = bank.doorHackPos, bank.vaultDoorPos
    IL.Execute([[
        UPDATE fleeca_banks SET name = ?, pos_x = ?, pos_y = ?, pos_z = ?, active = ?, blip_enabled = ?, can_rob = ?,
            door_hack_x = ?, door_hack_y = ?, door_hack_z = ?, vault_door_x = ?, vault_door_y = ?, vault_door_z = ?,
            vault_door_model = ?, safe_positions = ?, account_access_positions = ?
        WHERE id = ?
    ]], {
        bank.name, bank.pos.x, bank.pos.y, bank.pos.z,
        bank.active and 1 or 0, bank.blipEnabled and 1 or 0, bank.canRob and 1 or 0,
        hack.x, hack.y, hack.z, vault.x, vault.y, vault.z, tostring(vault.model),
        IL.Encode(bank.safePositions), IL.Encode(bank.accountAccessPositions), bank.id,
    })
end

local function SortedBanks()
    local list = {}
    for _, bank in pairs(Fleeca.banks) do
        list[#list + 1] = {
            id = bank.id,
            name = bank.name,
            pos = bank.pos,
            active = bank.active,
            canRob = bank.canRob,
            blipEnabled = bank.blipEnabled,
            doorHackPos = bank.doorHackPos,
            vaultDoorPos = bank.vaultDoorPos,
            safePositions = bank.safePositions,
            accountAccessPositions = bank.accountAccessPositions,
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

IL.RegisterCallback("core:fleeca:getBanks", function(source)
    if not IsBuilder(source) then return {} end
    return SortedBanks()
end)

IL.RegisterCallback("core:fleeca:getSettings", function(source)
    if not IsBuilder(source) then return nil end
    local out = {}
    for key, value in pairs(Fleeca.settings) do out[key] = value end
    return out
end)

RegisterNetEvent("core:fleeca:createBank", function(data)
    local source = source
    if not IsBuilder(source) then return end
    if not IL.IsTable(data) then return end

    local name = Trim(data.name)
    local pos = CleanPos(data.pos)
    local hack = CleanPos(data.doorHackPos, true)
    if name == "" or #name > 100 or not pos or not hack then
        IL.Notify(source, "ERROR", "Banque Fleeca : informations manquantes ou invalides.")
        return
    end

    local access = CleanPosList(data.accountAccessPositions)
    if #access == 0 then
        IL.Notify(source, "ERROR", "Banque Fleeca : ajoutez au moins un point d'acces bancaire.")
        return
    end

    local bank = {
        name = name,
        pos = pos,
        active = data.active ~= false,
        canRob = data.canRob ~= false,
        blipEnabled = data.blipEnabled ~= false,
        doorHackPos = hack,
        vaultDoorPos = CleanVault(data.vaultDoorPos) or { x = 0.0, y = 0.0, z = 0.0, model = "v_ilev_gb_vauldr" },
        safePositions = CleanPosList(data.safePositions, 4),
        accountAccessPositions = access,
        lastRobbed = 0,
    }

    local id = IL.Insert("INSERT INTO fleeca_banks (name, pos_x, pos_y, pos_z) VALUES (?, ?, ?, ?)", { bank.name, pos.x, pos.y, pos.z })
    if not id or id == 0 then
        IL.Notify(source, "ERROR", "Banque Fleeca : l'enregistrement en base a echoue.")
        return
    end

    bank.id = id
    SaveBank(bank)
    Fleeca.banks[id] = bank
    Broadcast()
    IL.Notify(source, "STAFF", ("Banque Fleeca \"%s\" creee (#%d)."):format(bank.name, id))
end)

local function IsOn(value) return value == true or value == 1 end

local BANK_FIELDS = {
    name = function(v)
        local text = Trim(v)
        if text == "" or #text > 100 then return nil end
        return text
    end,
    active = IsOn,
    canRob = IsOn,
    blipEnabled = IsOn,
    pos = function(v) return CleanPos(v) end,
    doorHackPos = function(v) return CleanPos(v, true) end,
    vaultDoorPos = function(v) return CleanVault(v) end,
    safePositions = function(v) return CleanPosList(v, 4) end,
    accountAccessPositions = function(v) return CleanPosList(v) end,
}

RegisterNetEvent("core:fleeca:updateBank", function(bankId, field, value)
    local source = source
    if not IsBuilder(source) then return end

    local id = IL.Int(bankId, nil)
    local bank = id and Fleeca.banks[id] or nil
    local clean = type(field) == "string" and BANK_FIELDS[field] or nil
    if not bank or not clean then return end

    local result = clean(value)
    if result == nil then
        IL.Notify(source, "ERROR", "Banque Fleeca : valeur invalide.")
        return
    end

    bank[field] = result
    SaveBank(bank)
    Broadcast()
end)

RegisterNetEvent("core:fleeca:deleteBank", function(bankId)
    local source = source
    if not IsBuilder(source) then return end

    local id = IL.Int(bankId, nil)
    local bank = id and Fleeca.banks[id] or nil
    if not bank then return end

    CloseRobbery(id)
    Fleeca.hacking[id] = nil
    IL.Execute("DELETE FROM fleeca_banks WHERE id = ?", { id })
    Fleeca.banks[id] = nil
    Broadcast()
    IL.Notify(source, "STAFF", ("Banque Fleeca \"%s\" supprimee."):format(bank.name))
end)

RegisterNetEvent("core:fleeca:updateSettings", function(key, value)
    local source = source
    if not IsBuilder(source) then return end
    if type(key) ~= "string" or DEFAULT_SETTINGS[key] == nil then return end

    if type(DEFAULT_SETTINGS[key]) == "number" then
        local number = tonumber(value)
        if not number or number < 0 then return end
        IL.SaveSetting(SETTINGS_TABLE, key, number)
    else
        if type(value) ~= "string" or not value:match("^[%w_%-]+$") then return end
        IL.SaveSetting(SETTINGS_TABLE, key, value)
    end
    LoadSettings()
end)

RegisterNetEvent("core:fleeca:reloadSettings", function()
    local source = source
    if not IsBuilder(source) then return end
    LoadSettings()
end)

RegisterNetEvent("core:fleeca:reloadFromDatabase", function()
    local source = source
    if not IsBuilder(source) then return end
    LoadBanks()
    Broadcast()
end)

RegisterNetEvent("core:fleeca:resetCooldowns", function()
    local source = source
    if not IsBuilder(source) then return end

    playerCooldowns = {}
    for _, bank in pairs(Fleeca.banks) do bank.lastRobbed = 0 end
    IL.Execute("UPDATE fleeca_banks SET last_robbed = 0")
end)
