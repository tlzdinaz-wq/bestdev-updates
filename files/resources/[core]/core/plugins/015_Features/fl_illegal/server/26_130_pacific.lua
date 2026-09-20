local Pacific = {
    positions = {},
    codes = {},
    numpadLocks = {},
    securityPCHolder = nil,
    drilling = {},
    drilledSmall = {},
    drilledBig = {},
    goldCollected = false,
    robbery = nil,
    lastRobbed = 0,
}

local BUILDER_PERM = "builder_pacific"
local DRILL_ITEM = "foreuse"
local ROBBERY_DURATION_MIN = 15
local VAULT_OPEN_MS = 1800000
local COOLDOWN = 7200
local MIN_POLICE = 0
local BAG_ITEMS = { "heist_bag", "lootbag", "money_bag", "dufflebag", "backpack", "clothes_bag", "bag" }
local GOLD_ITEM = "lingot_or"
local SMALL_SAFE_COUNT = 20
local BIG_SAFE_COUNT = 6

local function LoadPositions()
    Pacific.positions = {}
    local rows = IL.Query("SELECT * FROM pacific_positions")
    for i = 1, #rows do
        local row = rows[i]
        local entry = { x = IL.Num(row.x, 0.0), y = IL.Num(row.y, 0.0), z = IL.Num(row.z, 0.0) }
        if row.heading ~= nil then
            entry.heading = IL.Num(row.heading, 0.0)
        end
        Pacific.positions[row.config_key] = entry
    end

    local smallSafes, bigSafes = {}, {}
    local safeRows = IL.Query("SELECT * FROM pacific_safes ORDER BY safe_type, safe_index")
    for i = 1, #safeRows do
        local row = safeRows[i]
        local entry = {
            x = IL.Num(row.x, 0.0), y = IL.Num(row.y, 0.0), z = IL.Num(row.z, 0.0),
            heading = IL.Num(row.heading, 0.0),
        }
        if row.safe_type == "big" then
            bigSafes[IL.Int(row.safe_index, #bigSafes + 1)] = entry
        else
            smallSafes[IL.Int(row.safe_index, #smallSafes + 1)] = entry
        end
    end
    if next(smallSafes) then Pacific.positions.smallSafes = smallSafes end
    if next(bigSafes) then Pacific.positions.bigSafes = bigSafes end

    local doorRows = IL.Query("SELECT * FROM pacific_doors")
    if #doorRows > 0 then
        local doors = {}
        for i = 1, #doorRows do
            local row = doorRows[i]
            doors[row.door_index] = { x = IL.Num(row.x, 0.0), y = IL.Num(row.y, 0.0), z = IL.Num(row.z, 0.0) }
        end
        Pacific.positions.doors = doors
    end
end

local function LoadState()
    local row = IL.Single("SELECT * FROM pacific_state WHERE id = 1")
    if not row then
        Pacific.codes = { vault = "4517", entry = "2841", computer = "9034", securityPC = "1265" }
        return
    end
    Pacific.codes = {
        vault = row.vault_code or "4517",
        entry = row.entry_code or "2841",
        computer = row.computer_code or "9034",
        securityPC = row.security_code or "1265",
    }
    Pacific.lastRobbed = IL.Int(row.last_robbed, 0)
end

local function IsKnownSafe(index, isSmall)
    local list = isSmall and Pacific.positions.smallSafes or Pacific.positions.bigSafes
    if IL.IsTable(list) then
        return IL.IsTable(list[index])
    end
    return index >= 1 and index <= (isSmall and SMALL_SAFE_COUNT or BIG_SAFE_COUNT)
end

local function HasBag(xPlayer)
    for i = 1, #BAG_ITEMS do
        if xPlayer.haveItem(BAG_ITEMS[i], 1) then return true end
    end
    return false
end

local function ResetHeist()
    Pacific.robbery = nil
    Pacific.drilledSmall = {}
    Pacific.drilledBig = {}
    Pacific.drilling = {}
    Pacific.numpadLocks = {}
    Pacific.securityPCHolder = nil
    Pacific.goldCollected = false
    TriggerClientEvent("core:pacific:stopRobberyTimer", -1)
    TriggerClientEvent("core:pacific:lockDoors", -1)
    TriggerClientEvent("core:pacific:resetSmallSafes", -1)
end

IL.OnReady(function()
    LoadPositions()
    LoadState()
    TriggerClientEvent("core:pacific:syncPositions", -1, Pacific.positions)
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("core:pacific:syncPositions", source, Pacific.positions)
    if Pacific.robbery then
        local remaining = math.max(1, math.ceil((Pacific.robbery.endsAt - IL.Now()) / 60))
        TriggerClientEvent("core:pacific:startRobberyTimer", source, remaining)
        if Pacific.robbery.entryDoorOpen then
            TriggerClientEvent("core:pacific:syncEntryDoor", source)
        end
        if Pacific.robbery.door1Open then
            TriggerClientEvent("core:pacific:syncDoor1Unlock", source)
        end
        if Pacific.robbery.computerUnlocked then
            TriggerClientEvent("core:pacific:syncComputer", source)
        end
        if Pacific.robbery.vaultOpen then
            TriggerClientEvent("core:pacific:openVaultDoor", source, VAULT_OPEN_MS)
        end
        for index in pairs(Pacific.drilledSmall) do
            TriggerClientEvent("core:pacific:smallSafeDrilled", source, index)
        end
        for index in pairs(Pacific.drilledBig) do
            TriggerClientEvent("core:pacific:bigSafeDrilled", source, index)
        end
        if Pacific.goldCollected then
            TriggerClientEvent("core:pacific:goldCollected", source)
        end
    end
end)

IL.OnPlayerDropped(function(source)
    for codeType, holder in pairs(Pacific.numpadLocks) do
        if holder == source then Pacific.numpadLocks[codeType] = nil end
    end
    if Pacific.securityPCHolder == source then
        Pacific.securityPCHolder = nil
    end
    for key, drill in pairs(Pacific.drilling) do
        if drill.source == source then
            Pacific.drilling[key] = nil
            TriggerClientEvent("core:pacific:syncDrillingState", -1, drill.safeIndex, drill.isSmall, false, 0)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(10000)
        if Pacific.robbery and IL.Now() >= Pacific.robbery.endsAt then
            ResetHeist()
        end
        local now = IL.Now()
        for key, drill in pairs(Pacific.drilling) do
            if now - drill.startedAt > 300 then
                Pacific.drilling[key] = nil
                TriggerClientEvent("core:pacific:syncDrillingState", -1, drill.safeIndex, drill.isSmall, false, 0)
            end
        end
    end
end)

IL.RegisterCallback("core:pacific:getPositions", function(source)
    return Pacific.positions
end)

IL.RegisterCallback("core:pacific:canHackSecurityPC", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable" end

    if Pacific.robbery then return false, "Un braquage est deja en cours" end
    if Pacific.securityPCHolder and Pacific.securityPCHolder ~= source then
        return false, "Le poste est deja occupe"
    end
    if Pacific.lastRobbed > 0 and (IL.Now() - Pacific.lastRobbed) < COOLDOWN then
        return false, "La banque a ete braquee recemment"
    end
    if MIN_POLICE > 0 and IL.PoliceOnDutyCount() < MIN_POLICE then
        return false, "Trop peu de policiers en service"
    end

    Pacific.securityPCHolder = source
    return true, nil
end)

IL.RegisterCallback("core:pacific:canHackBank", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable" end
    if not Pacific.robbery then return false, "Le systeme de securite est actif" end
    if Pacific.robbery.entryDoorOpen then return false, "La porte est deja ouverte" end
    return true, nil
end)

IL.RegisterCallback("core:pacific:canUseNumpad", function(source, codeType)
    codeType = IL.Str(codeType, nil)
    if codeType ~= "securityPC" and codeType ~= "entry" and codeType ~= "computer" and codeType ~= "vault" then
        return false, "Ce terminal n'est pas valide"
    end

    local holder = Pacific.numpadLocks[codeType]
    if holder and holder ~= source and IL.Player(holder) then
        return false, "Terminal deja utilise"
    end

    Pacific.numpadLocks[codeType] = source
    return true, nil
end)

IL.RegisterCallback("core:pacific:releaseNumpad", function(source, codeType)
    codeType = IL.Str(codeType, nil)
    if not codeType then return true end
    if Pacific.numpadLocks[codeType] == source then
        Pacific.numpadLocks[codeType] = nil
    end
    return true
end)

IL.RegisterCallback("core:pacific:releaseSecurityPC", function(source)
    if Pacific.securityPCHolder == source then
        Pacific.securityPCHolder = nil
    end
    return true
end)

IL.RegisterCallback("core:pacific:verifyCode", function(source, code)
    if type(code) ~= "string" and type(code) ~= "number" then return false end
    local value = tostring(code)

    for _, expected in pairs(Pacific.codes) do
        if expected ~= nil and tostring(expected) == value then
            return true
        end
    end
    return false
end)

IL.RegisterCallback("core:pacific:canDrillSafe", function(source, safeIndex, isSmallSafe)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local index = IL.Int(safeIndex, nil)
    if not index then return false, "Ce coffre n'est pas valide" end
    local isSmall = isSmallSafe == true
    if not IsKnownSafe(index, isSmall) then return false, "Ce coffre n'est pas valide" end

    if not Pacific.robbery then return false, "Aucun braquage en cours" end
    if not Pacific.robbery.vaultOpen then return false, "La salle des coffres est fermee" end

    if isSmall and Pacific.drilledSmall[index] then return false, "Ce coffre a deja ete perce" end
    if not isSmall and Pacific.drilledBig[index] then return false, "Ce coffre a deja ete perce" end

    local key = (isSmall and "s" or "b") .. index
    if Pacific.drilling[key] then return false, "Ce coffre est en cours de percage" end

    if not xPlayer.haveItem(DRILL_ITEM, 1) then
        return false, "Il vous faut une foreuse"
    end

    return true, nil
end)

RegisterNetEvent("core:pacific:unlockEntryDoor", function()
    local source = source
    if not Pacific.robbery then return end
    if Pacific.robbery.entryDoorOpen then return end

    Pacific.robbery.entryDoorOpen = true
    TriggerClientEvent("core:pacific:syncEntryDoor", -1)
    IL.Notify(source, "ILLEGAL", "Porte d'entree deverrouillee.")
end)

RegisterNetEvent("core:pacific:unlockDoor1", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    if Pacific.robbery then return end
    if Pacific.lastRobbed > 0 and (IL.Now() - Pacific.lastRobbed) < COOLDOWN then return end

    local now = IL.Now()
    Pacific.lastRobbed = now
    IL.Execute("UPDATE pacific_state SET last_robbed = ? WHERE id = 1", { now })

    Pacific.robbery = {
        source = source,
        startedAt = now,
        endsAt = now + (ROBBERY_DURATION_MIN * 60),
        entryDoorOpen = false,
        door1Open = true,
        computerUnlocked = false,
        vaultOpen = false,
    }
    Pacific.drilledSmall = {}
    Pacific.drilledBig = {}
    Pacific.goldCollected = false

    TriggerClientEvent("core:pacific:syncDoor1Unlock", -1)
    TriggerClientEvent("core:pacific:startRobberyTimer", -1, ROBBERY_DURATION_MIN)

    local blipPos = Pacific.positions.blip or Pacific.positions.securityPC
    if not blipPos and Pacific then
        blipPos = { x = 255.001, y = 225.855, z = 101.005 }
    end
    IL.AlertPolice("core:pacific:createPoliceBlip", blipPos)
end)

RegisterNetEvent("core:pacific:unlockComputer", function()
    local source = source
    if not Pacific.robbery then return end
    if Pacific.robbery.computerUnlocked then return end

    Pacific.robbery.computerUnlocked = true
    TriggerClientEvent("core:pacific:syncComputer", -1)
end)

RegisterNetEvent("core:pacific:openVault", function()
    local source = source
    if not Pacific.robbery then return end
    if Pacific.robbery.vaultOpen then return end

    Pacific.robbery.vaultOpen = true
    TriggerClientEvent("core:pacific:openVaultDoor", -1, VAULT_OPEN_MS)

    SetTimeout(VAULT_OPEN_MS, function()
        TriggerClientEvent("core:pacific:closeVaultDoor", -1)
        if Pacific.robbery then
            Pacific.robbery.vaultOpen = false
        end
        ResetHeist()
    end)
end)

RegisterNetEvent("core:pacific:collectGold", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    if not Pacific.robbery or not Pacific.robbery.vaultOpen then return end
    if Pacific.goldCollected then return end

    if not HasBag(xPlayer) then
        IL.Notify(source, "ILLEGAL", "Il vous faut un sac pour transporter l'or.")
        return
    end

    Pacific.goldCollected = true

    local count = math.random(8, 14)
    if IL.ItemExists(GOLD_ITEM) and xPlayer.canCarryItem(GOLD_ITEM, count) then
        IL.GiveItem(xPlayer, GOLD_ITEM, count, true)
    else
        IL.GiveMoney(xPlayer, "black_money", count * 2500, "pacific-gold")
    end

    TriggerClientEvent("core:pacific:goldCollected", -1)
end)

RegisterNetEvent("core:pacific:startDrill", function(safeIndex, isSmallSafe)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local index = IL.Int(safeIndex, nil)
    if not index then return end
    local isSmall = isSmallSafe == true
    if not IsKnownSafe(index, isSmall) then return end

    if not Pacific.robbery or not Pacific.robbery.vaultOpen then return end
    if isSmall and Pacific.drilledSmall[index] then return end
    if not isSmall and Pacific.drilledBig[index] then return end

    local key = (isSmall and "s" or "b") .. index
    if Pacific.drilling[key] then return end
    if not xPlayer.haveItem(DRILL_ITEM, 1) then return end

    Pacific.drilling[key] = { source = source, safeIndex = index, isSmall = isSmall, startedAt = IL.Now() }
    TriggerClientEvent("core:pacific:syncDrillingState", -1, index, isSmall, true, source)
end)

RegisterNetEvent("core:pacific:completeDrill", function(safeIndex, isSmallSafe)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local index = IL.Int(safeIndex, nil)
    if not index then return end
    local isSmall = isSmallSafe == true

    local key = (isSmall and "s" or "b") .. index
    local drill = Pacific.drilling[key]
    if not drill or drill.source ~= source then return end
    Pacific.drilling[key] = nil

    if not Pacific.robbery then
        TriggerClientEvent("core:pacific:syncDrillingState", -1, index, isSmall, false, 0)
        return
    end

    if isSmall then
        if Pacific.drilledSmall[index] then
            TriggerClientEvent("core:pacific:syncDrillingState", -1, index, isSmall, false, 0)
            return
        end
        Pacific.drilledSmall[index] = true
    else
        if Pacific.drilledBig[index] then
            TriggerClientEvent("core:pacific:syncDrillingState", -1, index, isSmall, false, 0)
            return
        end
        Pacific.drilledBig[index] = true
    end

    local amount = isSmall and math.random(4000, 7000) or math.random(12000, 20000)
    IL.GiveMoney(xPlayer, "black_money", amount, "pacific-safe")

    if isSmall then
        TriggerClientEvent("core:pacific:smallSafeDrilled", -1, index)
    else
        TriggerClientEvent("core:pacific:bigSafeDrilled", -1, index)
    end
    TriggerClientEvent("core:pacific:syncDrillingState", -1, index, isSmall, false, 0)
    IL.Notify(source, "ILLEGAL", ("Coffre perce : %d$ sale."):format(amount))
end)

RegisterNetEvent("core:pacific:failDrill", function(safeIndex, isSmallSafe)
    local source = source
    local index = IL.Int(safeIndex, nil)
    if not index then return end
    local isSmall = isSmallSafe == true

    local key = (isSmall and "s" or "b") .. index
    local drill = Pacific.drilling[key]
    if not drill or drill.source ~= source then return end

    Pacific.drilling[key] = nil
    TriggerClientEvent("core:pacific:syncDrillingState", -1, index, isSmall, false, 0)
end)

RegisterNetEvent("core:pacific:savePositions", function(cfg)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if not IL.IsTable(cfg) then return end

    for key, value in pairs(cfg) do
        if type(key) == "string" and IL.IsTable(value) and value.x then
            IL.Execute([[
                INSERT INTO pacific_positions (config_key, x, y, z, heading)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE x = VALUES(x), y = VALUES(y), z = VALUES(z), heading = VALUES(heading)
            ]], { key, IL.Num(value.x, 0.0), IL.Num(value.y, 0.0), IL.Num(value.z, 0.0), IL.Num(value.heading, 0.0) })
        end
    end

    LoadPositions()
    TriggerClientEvent("core:pacific:syncPositions", -1, Pacific.positions)
end)

RegisterNetEvent("core:pacific:resetHeist", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    ResetHeist()
end)
