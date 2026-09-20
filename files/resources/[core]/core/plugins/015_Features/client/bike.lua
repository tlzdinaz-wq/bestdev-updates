---@meta _
---@diagnostic disable: duplicate-doc-field

RegisterNetEvent("core:client:UseBike")
---@param props any
AddEventHandler("core:client:UseBike", function(props)
    VFW.Game.SpawnVehicle(joaat(props), vector3(GetEntityCoords(VFW.PlayerData.ped)), GetEntityHeading(VFW.PlayerData.ped), function(vehicle)
        TaskWarpPedIntoVehicle(VFW.PlayerData.ped, vehicle, -1)
    end)
end)

local allowedModels = {
    [joaat("cruiser")] = true,
    [joaat("bmx")] = true,
    [joaat("fixter")] = true,
    [joaat("scorcher")] = true,
    [joaat("tribike")] = true,
    [joaat("tribike2")] = true,
    [joaat("tribike3")] = true
}

local function isBikeCloseEnough(vehicle)
    local ped = VFW.PlayerData.ped
    local playerCoords = GetEntityCoords(ped)
    local vehicleCoords = GetEntityCoords(vehicle)
    return #(playerCoords - vehicleCoords) <= 3.0
end

local function canPickupBike(vehicle)
    if not allowedModels[GetEntityModel(vehicle)] then
        return false
    end
    if not isBikeCloseEnough(vehicle) then
        return false
    end
    if not IsPedOnFoot(VFW.PlayerData.ped) then
        return false
    end
    if not AreAnyVehicleSeatsFree(vehicle) or GetPedInVehicleSeat(vehicle, -1) ~= 0 then
        return false
    end
    return true
end

local function taskTakeBike(target)
    local ped = VFW.PlayerData.ped

    if not DoesEntityExist(target) then
        return
    end

    VFW.Streaming.RequestAnimDict("pickup_object")
    TaskPlayAnim(ped, "pickup_object", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)

    local netId = VehToNet(target)
    local bikeModel = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(target)))

    TriggerServerEvent("core:server:pickupBike", bikeModel, netId)

    RemoveAnimDict("pickup_object")
end

VFW.ContextAddButton("vehicle", " Prendre le vélo", function(vehicle)
    return canPickupBike(vehicle)
end, function(vehicle)
    taskTakeBike(vehicle)
end)
