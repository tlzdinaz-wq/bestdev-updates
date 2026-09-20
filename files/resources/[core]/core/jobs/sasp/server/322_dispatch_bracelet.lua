VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Dispatch = VFW.Dispatch or {}

local JC = VFW.JobsCommon
local Dispatch = VFW.Dispatch

local bracelets = {}

local function payload(row)
    return {
        id = tonumber(row.id),
        identifier = row.identifier,
        name = row.name or "",
        reason = row.reason or "",
        description = row.description or "",
        paletteIndex = JC.Int(row.palette_index, 0) or 0,
    }
end

function Dispatch.LoadBracelets()
    local rows = JC.Query([[
        SELECT id, identifier, name, reason, description, palette_index
        FROM dispatch_bracelets ORDER BY id ASC
    ]])

    local out = {}
    for i = 1, #rows do
        local entry = payload(rows[i])
        if entry.id then out[entry.id] = entry end
    end

    bracelets = out
    return bracelets
end

function Dispatch.BraceletList()
    local out = {}
    for _, entry in pairs(bracelets) do
        out[#out + 1] = entry
    end
    table.sort(out, function(a, b) return (a.id or 0) < (b.id or 0) end)
    return out
end

function Dispatch.Bracelet(id)
    local wanted = JC.Int(id)
    if not wanted then return nil end
    return bracelets[wanted]
end

function Dispatch.WearerOf(identifier)
    local players = VFW.GetPlayers()
    for i = 1, #players do
        local xPlayer = VFW.GetPlayerFromId(players[i])
        if xPlayer and xPlayer.identifier == identifier then return players[i], xPlayer end
    end
    return nil, nil
end

function Dispatch.AttachBracelet(targetIdentifier, name, reason, description, paletteIndex)
    if type(targetIdentifier) ~= "string" or targetIdentifier == "" then return nil end

    local id = JC.Insert([[
        INSERT INTO dispatch_bracelets (identifier, name, reason, description, palette_index)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        targetIdentifier,
        JC.Str(name, 128) or "",
        JC.Str(reason, 255) or "",
        JC.Str(description, 1000) or "",
        JC.Int(paletteIndex, 0) or 0,
    })

    if not id then return nil end

    local entry = {
        id = id,
        identifier = targetIdentifier,
        name = JC.Str(name, 128) or "",
        reason = JC.Str(reason, 255) or "",
        description = JC.Str(description, 1000) or "",
        paletteIndex = JC.Int(paletteIndex, 0) or 0,
    }
    bracelets[id] = entry

    local wearer = Dispatch.WearerOf(targetIdentifier)
    if wearer then
        TriggerClientEvent("dispatch_bracelet:clientApplyBracelet", wearer)
    end

    Dispatch.Broadcast("d_dispatch:addBracelet", entry)
    return entry
end

RegisterNetEvent("dispatch_bracelet:updateBracelet", function(id, data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end
    if type(data) ~= "table" then return end

    local entry = Dispatch.Bracelet(id)
    if not entry then return end

    entry.name = JC.Str(data.name, 128) or ""
    entry.reason = JC.Str(data.reason, 255) or ""
    entry.description = JC.Str(data.description, 1000) or ""
    entry.paletteIndex = JC.Int(data.paletteIndex, 0, 32) or 0

    JC.Exec([[
        UPDATE dispatch_bracelets SET name = ?, reason = ?, description = ?, palette_index = ?
        WHERE id = ?
    ]], { entry.name, entry.reason, entry.description, entry.paletteIndex, entry.id })

    Dispatch.Broadcast("d_dispatch:updateBracelet", entry)
end)

RegisterNetEvent("dispatch_bracelet:ping", function(id)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end

    if not JC.Throttle(source, "dispatch:braceletping", 3000) then return end

    local entry = Dispatch.Bracelet(id)
    if not entry then return end

    local wearer = Dispatch.WearerOf(entry.identifier)
    if not wearer then
        JC.Notify(source, "Le porteur est hors ligne.", true)
        return
    end

    local coords = JC.Coords(wearer)
    if not coords then return end

    TriggerClientEvent("dispatch_bracelet:clientPingBlip", source, { x = coords.x, y = coords.y, z = coords.z })
end)

RegisterNetEvent("dispatch_bracelet:removeBracelet", function(id)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end

    local entry = Dispatch.Bracelet(id)
    if not entry then return end

    bracelets[entry.id] = nil
    JC.Exec("DELETE FROM dispatch_bracelets WHERE id = ?", { entry.id })

    local wearer = Dispatch.WearerOf(entry.identifier)
    if wearer then
        TriggerClientEvent("dispatch_bracelet:clientRemoveBracelet", wearer)
    end

    Dispatch.Broadcast("d_dispatch:removeBracelet", entry.id)
end)

JC.Cb("dispatch:getBracelets", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return {} end
    return Dispatch.BraceletList()
end)

VFW.RegisterCommand("bracelet", nil, function(source, xPlayer, args)
    if not Dispatch.IsAllowed(xPlayer) then
        JC.Notify(source, "Reserve aux forces de l'ordre.", true)
        return
    end

    local targetId = JC.Int(args[1], 1)
    if not targetId then
        JC.Notify(source, "Usage : /bracelet [id] [motif]", true)
        return
    end

    local target = VFW.GetPlayerFromId(targetId)
    if not target then
        JC.Notify(source, "Joueur introuvable.", true)
        return
    end

    if JC.DistPlayers(source, targetId) > 5.0 then
        JC.Notify(source, "Le joueur est trop loin.", true)
        return
    end

    local reason = table.concat(args, " ", 2)
    local entry = Dispatch.AttachBracelet(target.identifier, JC.PlayerName(target), reason, "", 0)
    if not entry then
        JC.Notify(source, "Impossible de poser le bracelet.", true)
        return
    end

    JC.Notify(source, ("Bracelet #%d pose sur %s."):format(entry.id, JC.PlayerName(target)), false)
    JC.Notify(targetId, "Un bracelet electronique vous a ete pose.", true)
end, {
    help = "Poser un bracelet electronique sur un joueur",
    params = {
        { name = "id", help = "ID du joueur" },
        { name = "motif", help = "Motif du bracelet" },
    },
})

local function policeAction(commandName, clientEvent, helpText, sendCopId)
    VFW.RegisterCommand(commandName, nil, function(source, xPlayer, args)
        if not Dispatch.IsAllowed(xPlayer) then
            JC.Notify(source, "Reserve aux forces de l'ordre.", true)
            return
        end

        local targetId = JC.Int(args[1], 1)
        if not targetId or targetId == source then
            JC.Notify(source, ("Usage : /%s [id]"):format(commandName), true)
            return
        end

        local target = VFW.GetPlayerFromId(targetId)
        if not target then
            JC.Notify(source, "Joueur introuvable.", true)
            return
        end

        if JC.DistPlayers(source, targetId) > 5.0 then
            JC.Notify(source, "Le joueur est trop loin.", true)
            return
        end

        if not JC.Throttle(source, "dispatch:action:" .. commandName, 1500) then return end

        if sendCopId then
            TriggerClientEvent(clientEvent, targetId, source)
        else
            TriggerClientEvent(clientEvent, targetId)
        end
    end, {
        help = helpText,
        params = { { name = "id", help = "ID du joueur" } },
    })
end

policeAction("dcuff", "dispatch:client:toggleCuffs", "Menotter / demenotter un joueur proche", false)
policeAction("dput", "dispatch:client:putInVehicle", "Placer un joueur proche dans le vehicule devant lui", false)
policeAction("dgrab", "dispatch:client:grabCitizen", "Saisir un joueur proche", true)

local function recordTable(citizen)
    return citizen and "dispatch_advanced_records_citizen" or "dispatch_advanced_records"
end

local function loadRecords(citizen)
    local rows = JC.Query(("SELECT id, payload FROM %s ORDER BY id ASC LIMIT 500"):format(recordTable(citizen)))
    local out = {}
    for i = 1, #rows do
        local decoded = JC.Decode(rows[i].payload, {})
        if type(decoded) ~= "table" then decoded = {} end
        decoded.id = tonumber(rows[i].id)
        out[#out + 1] = decoded
    end
    return out
end

local function addRecord(source, data, citizen)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end
    if type(data) ~= "table" then return end
    if not JC.Throttle(source, "dispatch:record:add", 500) then return end

    local encoded = JC.Encode(data)
    if not encoded or #encoded > 60000 then return end

    local id = JC.Insert(("INSERT INTO %s (payload) VALUES (?)"):format(recordTable(citizen)), { encoded })
    if not id then return end

    local record = JC.Copy(data)
    record.id = id

    Dispatch.Broadcast(citizen and "dispatch:client:addAdvancedRecordCitizen" or "dispatch:client:addAdvancedRecord", record)
end

local function updateRecord(source, data, citizen)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end
    if type(data) ~= "table" then return end

    local id = JC.Int(data.id, 1)
    if not id then return end

    local encoded = JC.Encode(data)
    if not encoded or #encoded > 60000 then return end

    JC.Exec(("UPDATE %s SET payload = ? WHERE id = ?"):format(recordTable(citizen)), { encoded, id })

    Dispatch.Broadcast(citizen and "dispatch:client:updateAdvancedRecordCitizen" or "dispatch:client:updateAdvancedRecord", data)
end

local function deleteRecord(source, id, citizen)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end

    local wanted = JC.Int(id, 1)
    if not wanted then return end

    JC.Exec(("DELETE FROM %s WHERE id = ?"):format(recordTable(citizen)), { wanted })

    Dispatch.Broadcast(citizen and "dispatch:client:removeAdvancedRecordCitizen" or "dispatch:client:removeAdvancedRecord", wanted)
end

RegisterNetEvent("dispatch:server:requestAdvancedRecords", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end
    TriggerClientEvent("dispatch:client:setAdvancedRecords", source, loadRecords(false))
end)

RegisterNetEvent("dispatch:server:addAdvancedRecord", function(data)
    local source = source
    addRecord(source, data, false)
end)

RegisterNetEvent("dispatch:server:updateAdvancedRecord", function(data)
    local source = source
    updateRecord(source, data, false)
end)

RegisterNetEvent("dispatch:server:deleteAdvancedRecord", function(id)
    local source = source
    deleteRecord(source, id, false)
end)

RegisterNetEvent("dispatch:server:requestAdvancedRecordsCitizen", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end
    TriggerClientEvent("dispatch:client:setAdvancedRecordsCitizen", source, loadRecords(true))
end)

RegisterNetEvent("dispatch:server:addAdvancedRecordCitizen", function(data)
    local source = source
    addRecord(source, data, true)
end)

RegisterNetEvent("dispatch:server:updateAdvancedRecordCitizen", function(data)
    local source = source
    updateRecord(source, data, true)
end)

RegisterNetEvent("dispatch:server:deleteAdvancedRecordCitizen", function(id)
    local source = source
    deleteRecord(source, id, true)
end)

AddEventHandler("vfw:playerLoaded", function(playerSource)
    local src = playerSource
    CreateThread(function()
        Wait(5000)
        local xPlayer = VFW.GetPlayerFromId(src)
        if not xPlayer then return end

        for _, entry in pairs(bracelets) do
            if entry.identifier == xPlayer.identifier then
                TriggerClientEvent("dispatch_bracelet:clientApplyBracelet", src)
                break
            end
        end
    end)
end)

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    Wait(2500)
    Dispatch.LoadBracelets()
end)
