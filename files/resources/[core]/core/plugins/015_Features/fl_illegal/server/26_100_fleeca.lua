local Fleeca = {
    banks = {},
    hacking = {},
    robberies = {},
    drilling = {},
    settings = {},
}

local BUILDER_PERM = "builder_fleeca"
local DRILL_ITEM = "foreuse"
local HACK_ITEM = "usb_piratage_fleeca"
local ROBBERY_DURATION = 600
local DOOR_CLOSE_DELAY = 1800
local BANK_COOLDOWN = 3600
local MIN_POLICE = 0
local SAFE_LOOT_ITEM = "liasse_argent"

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
                model = row.vault_door_model or "v_ilev_gb_vauldr",
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
    if bank.lastRobbed > 0 and (now - bank.lastRobbed) < BANK_COOLDOWN then
        return false, "Cette banque a ete braquee recemment"
    end

    if MIN_POLICE > 0 and IL.PoliceOnDutyCount() < MIN_POLICE then
        return false, "Trop peu de policiers en service"
    end

    if not xPlayer.haveItem(HACK_ITEM, 1) then
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
    if not xPlayer.haveItem(HACK_ITEM, 1) then return end

    Fleeca.hacking[id] = { source = source, startedAt = IL.Now() }
    TriggerClientEvent("core:fleeca:syncHackingState", -1, id, true, source)
    IL.AlertPolice("core:fleeca:createPoliceBlip", id)
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

    IL.TakeItem(xPlayer, HACK_ITEM, 1)

    local now = IL.Now()
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

    SetTimeout(DOOR_CLOSE_DELAY * 1000, function()
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
        IL.TakeItem(xPlayer, HACK_ITEM, 1)
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

    local bundles = math.random(215, 235)
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
