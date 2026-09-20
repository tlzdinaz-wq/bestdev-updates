VFW.Vehicles = VFW.Vehicles or {}

local Rental = VFW.Rental
local Vehicles = VFW.Vehicles

local renting = {}

local function canManage(xPlayer)
    return xPlayer ~= nil and xPlayer.hasPermission("manage_vehicleRental")
end

function Rental.EndRental(plate, notifySource)
    local normalized = Vehicles.NormalizePlate(plate)
    if not normalized then return false end

    Vehicles.DeleteByPlate(normalized)
    MySQL.update.await("DELETE FROM vehicle_rental_active WHERE sPlate = ?", { normalized })

    for i = #Rental.active, 1, -1 do
        if Rental.active[i].sPlate == normalized then
            table.remove(Rental.active, i)
        end
    end

    if notifySource then
        Vehicles.Notify(notifySource, "VERT", "Location", "Véhicule restitué.")
    end

    return true
end

local function findFreeSpot(source, point)
    local spots = point.tVehiclePos
    if type(spots) ~= "table" or #spots == 0 then return nil end

    for i = 1, #spots do
        local spot = spots[i]
        if type(spot) == "table" and tonumber(spot.x) then
            local occupied = TriggerClientCallback(source, "core:getClosestVehicle", {
                x = tonumber(spot.x) + 0.0,
                y = tonumber(spot.y) + 0.0,
                z = tonumber(spot.z) + 0.0,
            })

            if occupied ~= true then
                return {
                    x = tonumber(spot.x) + 0.0,
                    y = tonumber(spot.y) + 0.0,
                    z = tonumber(spot.z) + 0.0,
                    w = tonumber(spot.w) or 0.0,
                }
            end
        end
    end
end

RegisterNetEvent("core:vehicleRental:rent", function(tData, iOpenId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if type(tData) ~= "table" then return end
    if type(tData.vehicleName) ~= "string" or tData.vehicleName == "" then return end

    local method = tData.method
    if method ~= "cash" and method ~= "card" then return end

    local point = Rental.Get(iOpenId)
    if not point then return end

    local playerCoords = Vehicles.PlayerCoords(source)
    if playerCoords and Vehicles.Distance(playerCoords, point.tPos) > 25.0 then
        Vehicles.Notify(source, "ROUGE", "Location", "Vous êtes trop loin du point de location.")
        return
    end

    if renting[xPlayer.identifier] or Rental.FindActive(xPlayer.identifier, point.iType) then
        Vehicles.Notify(source, "ROUGE", "Location", "Vous avez déjà un véhicule en location.")
        return
    end

    local vehicle = Rental.FindCatalogVehicle(point.iType, tData.vehicleName)
    if not vehicle then
        Vehicles.Notify(source, "ROUGE", "Location", "Ce véhicule n'est pas disponible ici.")
        return
    end

    renting[xPlayer.identifier] = true

    local spot = findFreeSpot(source, point)
    if not spot then
        renting[xPlayer.identifier] = nil
        Vehicles.Notify(source, "ROUGE", "Location", "Aucun emplacement libre pour sortir le véhicule.")
        return
    end

    local accountMethod = method == "cash" and "cash" or "bank"
    local paid = Vehicles.Charge(xPlayer, accountMethod, vehicle.price, "location-vehicule")
    if not paid then
        renting[xPlayer.identifier] = nil
        Vehicles.Notify(source, "ROUGE", "Location", "Fonds insuffisants.")
        return
    end

    local plate = Vehicles.GeneratePlate("LOC")
    local props = {
        plate = plate,
        model = joaat(vehicle.name),
        engineHealth = 1000.0,
        bodyHealth = 1000.0,
        fuelLevel = 100.0,
    }

    local entity, netId = Vehicles.Spawn(source, vehicle.name, spot, spot.w, props)
    if not entity or not netId then
        renting[xPlayer.identifier] = nil
        xPlayer.addAccountMoney(accountMethod == "cash" and "money" or "bank", vehicle.price, "location-remboursement")
        Vehicles.Notify(source, "ROUGE", "Location", "Impossible de sortir le véhicule, vous avez été remboursé.")
        return
    end

    local durationSeconds = math.floor(Rental.DurationMs / 1000)
    local insertId = MySQL.insert.await([[
        INSERT INTO vehicle_rental_active (owner, iType, iPointId, sVehicleName, sLabel, sPlate, iPrice, rented_at, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? SECOND))
    ]], {
        xPlayer.identifier,
        point.iType,
        point.iId,
        vehicle.name,
        vehicle.label,
        plate,
        vehicle.price,
        durationSeconds,
    })

    Rental.active[#Rental.active + 1] = {
        id = tonumber(insertId),
        owner = xPlayer.identifier,
        iType = point.iType,
        iPointId = point.iId,
        sVehicleName = vehicle.name,
        sLabel = vehicle.label,
        sPlate = plate,
        iPrice = vehicle.price,
        netId = netId,
    }

    renting[xPlayer.identifier] = nil

    TriggerClientEvent("garage:placeVehicleOnGround", source, netId)
    Vehicles.Notify(source, "VERT", "Location", ("Véhicule loué : %s (%s)."):format(vehicle.label, plate))
end)

RegisterNetEvent("core:vehicleRental:return", function(iOpenType)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local rentalType = tonumber(iOpenType)
    if not rentalType or rentalType < 1 or rentalType > 3 then return end

    local entry = Rental.FindActive(xPlayer.identifier, math.floor(rentalType))
    if not entry then
        Vehicles.Notify(source, "ROUGE", "Location", "Vous n'avez aucun véhicule en location.")
        return
    end

    Rental.EndRental(entry.sPlate, source)
end)

RegisterNetEvent("core:createVehicleRental", function(payload)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canManage(xPlayer) then return end

    local data = Rental.SanitizePoint(payload)
    if not data then
        Vehicles.Notify(source, "ROUGE", "Location", "Ces données de location ne sont pas valides.")
        return
    end

    local iId = Rental.InsertPoint(data)
    if not iId then return end

    TriggerClientEvent("core:vehicleRental:Create", -1, Rental.Serialize(data), iId)
    Vehicles.Notify(source, "VERT", "Location", "Point de location créé.")
end)

RegisterNetEvent("core:editVehicleRental", function(payload)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canManage(xPlayer) then return end

    if type(payload) ~= "table" then return end

    local iId = tonumber(payload.iId)
    if not iId or not Rental.Get(iId) then return end

    local data = Rental.SanitizePoint(payload)
    if not data then
        Vehicles.Notify(source, "ROUGE", "Location", "Ces données de location ne sont pas valides.")
        return
    end

    data.iId = iId
    Rental.UpdatePoint(iId, data)

    TriggerClientEvent("core:vehicleRental:Update", -1, Rental.Serialize(data), iId)
    Vehicles.Notify(source, "VERT", "Location", "Point de location modifié.")
end)

RegisterNetEvent("core:deleteVehicleRental", function(iOpenId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canManage(xPlayer) then return end

    local iId = tonumber(iOpenId)
    if not iId or not Rental.Get(iId) then return end

    Rental.DeletePoint(iId)
    TriggerClientEvent("core:vehicleRental:Delete", -1, iId)
end)

RegisterNetEvent("core:vehicleRental:addVehicle", function(iType, sName, sLabel, iPrice)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canManage(xPlayer) then return end

    local rentalType = tonumber(iType)
    if not rentalType or rentalType < 1 or rentalType > 3 then return end
    if type(sName) ~= "string" or sName == "" then return end
    if type(sLabel) ~= "string" or sLabel == "" then return end

    local price = math.floor(tonumber(iPrice) or 0)
    if price < 0 then price = 0 end

    local model = sName:lower():gsub("%s+", "")
    if model == "" or #model > 64 then return end

    MySQL.insert.await([[
        INSERT INTO vehicle_rental_catalog (iType, name, label, price) VALUES (?, ?, ?, ?)
    ]], { math.floor(rentalType), model, sLabel:sub(1, 96), price })

    Rental.LoadCatalog()
    Rental.BroadcastConfig()
    Vehicles.Notify(source, "VERT", "Location", "Véhicule ajouté au catalogue.")
end)

RegisterNetEvent("core:vehicleRental:updateVehicle", function(id, label, price)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canManage(xPlayer) then return end

    local vehicleId = tonumber(id)
    if not vehicleId then return end
    if type(label) ~= "string" or label == "" then return end

    local newPrice = math.floor(tonumber(price) or 0)
    if newPrice < 0 then newPrice = 0 end

    MySQL.update.await("UPDATE vehicle_rental_catalog SET label = ?, price = ? WHERE id = ?", {
        label:sub(1, 96),
        newPrice,
        vehicleId,
    })

    Rental.LoadCatalog()
    Rental.BroadcastConfig()
    Vehicles.Notify(source, "VERT", "Location", "Véhicule mis à jour.")
end)

RegisterNetEvent("core:vehicleRental:deleteVehicle", function(id)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not canManage(xPlayer) then return end

    local vehicleId = tonumber(id)
    if not vehicleId then return end

    MySQL.update.await("DELETE FROM vehicle_rental_catalog WHERE id = ?", { vehicleId })

    Rental.LoadCatalog()
    Rental.BroadcastConfig()
    Vehicles.Notify(source, "VERT", "Location", "Véhicule supprimé du catalogue.")
end)

AddEventHandler("vfw:playerLoaded", function(playerSource)
    CreateThread(function()
        local waited = 0
        while not Rental.loaded and waited < 20000 do
            Wait(250)
            waited = waited + 250
        end

        if not VFW.GetPlayerFromId(playerSource) then return end

        TriggerClientEvent("core:vehicleRental:Init", playerSource, Rental.BuildPointsPayload(), Rental.BuildCatalogPayload())
    end)
end)

AddEventHandler("vfw:playerDropped", function(playerSource, xPlayer)
    if not xPlayer then return end

    renting[xPlayer.identifier] = nil

    CreateThread(function()
        for i = #Rental.active, 1, -1 do
            local entry = Rental.active[i]
            if entry.owner == xPlayer.identifier then
                Rental.EndRental(entry.sPlate)
            end
        end
    end)
end)

CreateThread(function()
    while true do
        Wait(60000)

        if Rental.loaded then
            local expired = MySQL.query.await([[
                SELECT sPlate FROM vehicle_rental_active WHERE expires_at IS NOT NULL AND expires_at <= NOW()
            ]]) or {}

            for i = 1, #expired do
                Rental.EndRental(expired[i].sPlate)
            end
        end
    end
end)
