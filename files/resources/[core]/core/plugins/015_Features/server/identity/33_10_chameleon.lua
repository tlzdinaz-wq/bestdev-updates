local Cl = VFW.Cloths

VFW.Chameleon = VFW.Chameleon or {}

local Ch = VFW.Chameleon

local SPRAY_ITEM = "chameleon_spray"
local MAX_VEHICLE_DISTANCE = 8.0

local colors = {}
local loaded = false

local function loadColors()
    local rows = MySQL.query.await("SELECT id, label, native_color FROM chameleon_colors ORDER BY id ASC") or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[tostring(row.id)] = {
            id = row.id,
            label = row.label,
            color = tonumber(row.native_color) or 0,
        }
    end
    colors = out
    loaded = true
    return colors
end

function Ch.Colors()
    if not loaded then
        loadColors()
    end
    return colors
end

function Ch.ResolveColor(chameleonId)
    if chameleonId == nil then return nil end
    local entry = Ch.Colors()[tostring(chameleonId)]
    if entry then return entry end

    local direct = tonumber(chameleonId)
    if direct and direct >= 0 and direct <= 159 then
        return { id = direct, label = ("Couleur %d"):format(direct), color = math.floor(direct) }
    end

    return nil
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 400 do
        Wait(250)
        tries = tries + 1
    end
    loadColors()
end)

local function findSpray(xPlayer, itemUniqueId)
    local Inv = VFW.Inventory
    if not Inv or not Inv.PlayerList then return nil, nil end

    local list = Inv.PlayerList(xPlayer)
    if type(itemUniqueId) == "string" and itemUniqueId ~= "" then
        for i = 1, #list do
            local entry = list[i]
            if entry.name == SPRAY_ITEM and entry.meta and entry.meta.uid == itemUniqueId then
                return entry, list
            end
        end
        return nil, list
    end

    for i = 1, #list do
        if list[i].name == SPRAY_ITEM then
            return list[i], list
        end
    end

    return nil, list
end

local function vehicleFor(source, vehicleNetId)
    local netId = Cl.Int(vehicleNetId, nil)
    if not netId or netId == 0 then return nil, "Vehicule introuvable." end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return nil, "Vehicule introuvable."
    end

    local playerCoords = Cl.Coords(source)
    local vehicleCoords = GetEntityCoords(entity)
    if playerCoords and Cl.Distance(playerCoords, { x = vehicleCoords.x, y = vehicleCoords.y, z = vehicleCoords.z }) > MAX_VEHICLE_DISTANCE then
        return nil, "Vous etes trop loin du vehicule."
    end

    return entity, nil
end

local function canPaint(xPlayer, entity)
    local plate = GetVehicleNumberPlateText(entity)
    if type(plate) ~= "string" then return true, nil end

    plate = plate:gsub("%s+$", "")
    if plate == "" then return true, nil end

    local row = MySQL.single.await("SELECT owner, owner_charid FROM owned_vehicles WHERE plate = ?", { plate })
    if not row then return true, plate end

    if row.owner == xPlayer.identifier then return true, plate end
    if tonumber(row.owner_charid) == tonumber(xPlayer.charId) then return true, plate end

    return false, plate
end

RegisterServerCallback("chameleon:checkOwnership", function(source, chameleonId, itemUniqueId, vehicleNetId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable." end

    local color = Ch.ResolveColor(chameleonId)
    if not color then return false, "Couleur inconnue." end

    local entry = findSpray(xPlayer, itemUniqueId)
    if not entry then return false, "Vous n'avez pas ce spray." end

    local entity, err = vehicleFor(source, vehicleNetId)
    if not entity then return false, err end

    local allowed = canPaint(xPlayer, entity)
    if not allowed then
        return false, "Ce vehicule ne vous appartient pas."
    end

    return true, nil
end)

RegisterNetEvent("chameleon:apply", function(chameleonId, itemUniqueId, vehicleNetId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Cl.RateLimit(source, "chameleon", 2000) then return end

    local color = Ch.ResolveColor(chameleonId)
    if not color then return end

    local entry, list = findSpray(xPlayer, itemUniqueId)
    if not entry then
        Cl.Notify(source, "Vous n'avez pas ce spray.")
        return
    end

    local entity, err = vehicleFor(source, vehicleNetId)
    if not entity then
        Cl.Notify(source, err or "Vehicule introuvable.")
        return
    end

    local allowed, plate = canPaint(xPlayer, entity)
    if not allowed then
        Cl.Notify(source, "Ce vehicule ne vous appartient pas.")
        return
    end

    local Inv = VFW.Inventory
    if Inv and list then
        Inv.RemoveFromSlot(list, entry.slot, 1)
        Inv.PushPlayer(xPlayer)
    else
        Cl.RemoveItem(xPlayer, SPRAY_ITEM, 1)
    end

    if plate and plate ~= "" then
        MySQL.query.await([[
            INSERT INTO vehicle_chameleon (plate, native_color, applied_by, applied_at)
            VALUES (?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE native_color = VALUES(native_color), applied_by = VALUES(applied_by), applied_at = NOW()
        ]], { plate, color.color, xPlayer.charId })
    end

    TriggerClientEvent("chameleon:syncColor", -1, Cl.Int(vehicleNetId, 0), color.color)
    Cl.Notify(source, "Peinture cameleon appliquee.", "VERT")
end)

local function resyncFor(source)
    local ok, vehicles = pcall(GetAllVehicles)
    if not ok or type(vehicles) ~= "table" then return end

    local rows = MySQL.query.await("SELECT plate, native_color FROM vehicle_chameleon") or {}
    if #rows == 0 then return end

    local byPlate = {}
    for i = 1, #rows do
        byPlate[rows[i].plate] = tonumber(rows[i].native_color) or 0
    end

    for i = 1, #vehicles do
        local entity = vehicles[i]
        if DoesEntityExist(entity) then
            local plate = GetVehicleNumberPlateText(entity)
            if type(plate) == "string" then
                plate = plate:gsub("%s+$", "")
                local color = byPlate[plate]
                if color then
                    local netId = NetworkGetNetworkIdFromEntity(entity)
                    if netId and netId ~= 0 then
                        TriggerClientEvent("chameleon:syncColor", source, netId, color)
                    end
                end
            end
        end
    end
end

AddEventHandler("vfw:playerLoaded", function(source)
    CreateThread(function()
        Wait(8000)
        if VFW.GetPlayerFromId(source) then
            resyncFor(source)
        end
    end)
end)

Cl.WaitInventory(function(Inv)
    Inv.RegisterUsableItem(SPRAY_ITEM, function(xPlayer, entry)
        local source = xPlayer.source
        if not Cl.RateLimit(source, "chameleonuse", 2000) then return end

        local meta = entry.meta
        if type(meta) ~= "table" then meta = {} end

        if type(meta.uid) ~= "string" or meta.uid == "" then
            meta.uid = "ch" .. Cl.Uuid():gsub("[^%w]", "")
            entry.meta = meta
            Inv.PushPlayer(xPlayer)
        end

        local color = Ch.ResolveColor(meta.chameleonId)
        if not color then
            Cl.Notify(source, "Ce spray n'a pas de couleur configuree.")
            return
        end

        TriggerClientEvent("chameleon:use", source, meta.chameleonId, meta.uid)
    end)
end)
