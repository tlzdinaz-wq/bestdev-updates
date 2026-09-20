VFW.Vehicles = VFW.Vehicles or {}

local Pounds = VFW.Pounds
local Vehicles = VFW.Vehicles

local function poundPrice(pound)
    if pound and tonumber(pound.price) then
        return math.floor(tonumber(pound.price))
    end
    return Pounds.DefaultPrice()
end

local function toPoundRow(row)
    local label = row.label
    if type(label) ~= "string" or label == "" then
        label = row.vehName or ""
    end

    return {
        plate = row.plate,
        label = label,
        name = row.vehName,
        vehName = row.vehName,
        engineHealth = row.engineHealth,
        bodyHealth = row.bodyHealth,
        fuelLevel = row.fuelLevel,
        modTurbo = row.modTurbo == true,
        props = row.props,
    }
end

RegisterServerCallback("garage:getAllPoundedPlayerVehicles", function(source, poundId)
    local pound = Pounds.Get(poundId)
    local result = { vehicles = {}, price = poundPrice(pound) }

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return result end

    local ok, rows = pcall(Vehicles.Query, [[
        SELECT * FROM owned_vehicles
        WHERE owner = ? AND pounded = 1 AND (group_type IS NULL OR group_type = '')
        ORDER BY vehName ASC
    ]], { xPlayer.identifier })

    if not ok or type(rows) ~= "table" then
        console.error(("garage:getAllPoundedPlayerVehicles: %s"):format(tostring(rows)))
        return result
    end

    for i = 1, #rows do
        result.vehicles[#result.vehicles + 1] = toPoundRow(rows[i])
    end

    return result
end)

RegisterNetEvent("pound:restoreVehicle", function(plate, poundId, paymentMethod)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local normalized = Vehicles.NormalizePlate(plate)
    if not normalized then return end

    local id = tonumber(poundId)
    local pound = id and Pounds.Get(id) or nil
    if not pound then
        Vehicles.Notify(source, "ROUGE", "Fourrière", "Fourrière introuvable.")
        return
    end

    local method = "bank"
    if paymentMethod == "cash" then
        method = "cash"
    elseif paymentMethod ~= nil and paymentMethod ~= "bank" then
        return
    end

    local row = Vehicles.GetByPlate(normalized)
    if not row then
        Vehicles.Notify(source, "ROUGE", "Fourrière", "Ce véhicule est introuvable.")
        return
    end

    if row.pounded ~= 1 then
        Vehicles.Notify(source, "ROUGE", "Fourrière", "Ce véhicule n'est pas en fourrière.")
        return
    end

    if not Vehicles.OwnsVehicle(xPlayer, row) then
        Vehicles.Notify(source, "ROUGE", "Fourrière", "Ce véhicule ne vous appartient pas.")
        return
    end

    local price = poundPrice(pound)
    local paid = Vehicles.Charge(xPlayer, method, price, "fourriere-sortie")
    if not paid then
        Vehicles.Notify(source, "ROUGE", "Fourrière", "Fonds insuffisants.")
        return
    end

    local garageId = tonumber(row.garage_id)
    local garage = garageId and VFW.Garages and VFW.Garages.Get(garageId) or nil

    if garage then
        MySQL.update.await([[
            UPDATE owned_vehicles SET pounded = 0, pound_id = NULL, stored = 1,
            engineHealth = 1000, bodyHealth = 1000 WHERE plate = ?
        ]], { normalized })

        Vehicles.Notify(source, "VERT", "Fourrière", "Véhicule récupéré, il est rangé dans votre garage.")
        return
    end

    local coords = Pounds.PickSpawn(pound)
    if not coords then
        MySQL.update.await([[
            UPDATE owned_vehicles SET pounded = 0, pound_id = NULL, stored = 1,
            engineHealth = 1000, bodyHealth = 1000 WHERE plate = ?
        ]], { normalized })

        Vehicles.Notify(source, "ORANGE", "Fourrière", "Véhicule récupéré mais aucune place de sortie disponible.")
        return
    end

    row.engineHealth = 1000.0
    row.bodyHealth = 1000.0

    Vehicles.DeleteByPlate(normalized)

    local props = Vehicles.BuildProps(row)
    local vehicle, netId = Vehicles.Spawn(source, row.vehName, coords, coords.w, props)
    if not vehicle or not netId then
        MySQL.update.await([[
            UPDATE owned_vehicles SET pounded = 0, pound_id = NULL, stored = 1,
            engineHealth = 1000, bodyHealth = 1000 WHERE plate = ?
        ]], { normalized })

        Vehicles.Notify(source, "ORANGE", "Fourrière", "Véhicule récupéré mais impossible à faire sortir.")
        return
    end

    MySQL.update.await([[
        UPDATE owned_vehicles SET pounded = 0, pound_id = NULL, stored = 0,
        engineHealth = 1000, bodyHealth = 1000 WHERE plate = ?
    ]], { normalized })

    TriggerClientEvent("garage:placeVehicleOnGround", source, netId)
    TriggerClientEvent("vfw:repairVehicle", source, netId)
    Vehicles.Notify(source, "VERT", "Fourrière", "Véhicule récupéré.")
end)

RegisterServerCallback("core:getAllPounds", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_pounds") then return {} end
    return Pounds.BuildPayload()
end)

RegisterServerCallback("core:createPound", function(source, payload)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_pounds") then return false end

    local data = Pounds.Sanitize(payload)
    if not data then return false end

    local id = Pounds.Insert(data)
    if not id then return false end

    TriggerClientEvent("pound:create", -1, id, Pounds.Serialize(data))
    return true
end)

RegisterServerCallback("core:updatePound", function(source, poundId, payload)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_pounds") then return false end

    local id = tonumber(poundId)
    if not id or not Pounds.Get(id) then return false end

    local data = Pounds.Sanitize(payload)
    if not data then return false end

    data.id = id
    Pounds.Update(id, data)
    TriggerClientEvent("pound:update", -1, id, Pounds.Serialize(data))
    return true
end)

RegisterServerCallback("core:deletePound", function(source, poundId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_pounds") then return false end

    local id = tonumber(poundId)
    if not id or not Pounds.Get(id) then return false end

    Pounds.Delete(id)
    TriggerClientEvent("pound:delete", -1, id)
    return true
end)

function Pounds.Impound(plate, poundId)
    local normalized = Vehicles.NormalizePlate(plate)
    if not normalized then return false end

    local row = Vehicles.GetByPlate(normalized)
    if not row then return false end

    local id = tonumber(poundId)
    if id and not Pounds.Get(id) then id = nil end

    Vehicles.DeleteByPlate(normalized)

    if id then
        MySQL.update.await([[
            UPDATE owned_vehicles SET pounded = 1, pound_id = ?, stored = 0 WHERE plate = ?
        ]], { id, normalized })
    else
        MySQL.update.await([[
            UPDATE owned_vehicles SET pounded = 1, pound_id = NULL, stored = 0 WHERE plate = ?
        ]], { normalized })
    end

    return true
end

AddEventHandler("vfw:playerLoaded", function(playerSource)
    CreateThread(function()
        local waited = 0
        while not Pounds.loaded and waited < 20000 do
            Wait(250)
            waited = waited + 250
        end

        if not VFW.GetPlayerFromId(playerSource) then return end

        TriggerClientEvent("pound:load", playerSource, Pounds.BuildPayload())
    end)
end)
