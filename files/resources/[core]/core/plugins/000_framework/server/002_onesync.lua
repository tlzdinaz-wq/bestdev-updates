local WINDOW_MS = 10000
local MAX_PER_WINDOW = 20

local budgets = {}

local function consumeBudget(source, amount)
    local now = GetGameTimer()
    local budget = budgets[source]

    if not budget or now >= budget.resetAt then
        budget = { resetAt = now + WINDOW_MS, used = 0 }
        budgets[source] = budget
    end

    if budget.used + amount > MAX_PER_WINDOW then
        return false
    end

    budget.used = budget.used + amount
    return true
end

local function allowSpawn(source, permission)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    if xPlayer.hasPermission(permission) then return true end

    if not consumeBudget(source, 1) then
        console.warn(("[OneSync] %s (%d) depasse le quota de creation d'entites."):format(tostring(xPlayer.name), source))
        return false
    end

    return true
end

local function waitForEntity(entity)
    local tries = 0
    while not DoesEntityExist(entity) and tries < 100 do
        Wait(10)
        tries = tries + 1
    end
    return DoesEntityExist(entity)
end

RegisterServerCallback("vfw:onesync:createObject", function(source, model, coords, heading)
    if type(model) ~= "number" or type(coords) ~= "table" then return nil end
    if not allowSpawn(source, "alt_spawn_object") then return nil end

    local object = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    if not waitForEntity(object) then return nil end

    SetEntityHeading(object, heading or 0.0)
    SetEntityOrphanMode(object, 2)
    return NetworkGetNetworkIdFromEntity(object)
end)

RegisterServerCallback("vfw:onesync:createPed", function(source, pedType, model, coords, heading)
    if type(model) ~= "number" or type(coords) ~= "table" then return nil end
    if not allowSpawn(source, "alt_spawn_ped") then return nil end

    local ped = CreatePed(pedType or 4, model, coords.x, coords.y, coords.z, heading or 0.0, true, true)
    if not waitForEntity(ped) then return nil end

    SetEntityOrphanMode(ped, 2)
    return NetworkGetNetworkIdFromEntity(ped)
end)

RegisterServerCallback("vfw:onesync:createVehicle", function(source, model, coords, heading, properties)
    if type(model) ~= "number" or type(coords) ~= "table" then return nil end
    if not allowSpawn(source, "alt_spawn_vehicle") then return nil end

    local vehicleType = VFW.GetVehicleType and VFW.GetVehicleType(model, source) or "automobile"
    local vehicle = CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z, heading or 0.0)
    if not waitForEntity(vehicle) then return nil end

    SetEntityOrphanMode(vehicle, 2)

    local state = Entity(vehicle).state
    state:set("OwnedVehicle", true, true)
    if properties then
        state:set("VehicleProperties", properties, true)
    end

    return NetworkGetNetworkIdFromEntity(vehicle)
end)

RegisterServerCallback("vfw:onesync:createVehicleRaw", function(source, model, coords, heading)
    if type(model) ~= "number" or type(coords) ~= "table" then return nil end
    if not allowSpawn(source, "alt_spawn_vehicle") then return nil end

    local vehicleType = VFW.GetVehicleType and VFW.GetVehicleType(model, source) or "automobile"
    local vehicle = CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z, heading or 0.0)
    if not waitForEntity(vehicle) then return nil end

    SetEntityOrphanMode(vehicle, 2)
    return NetworkGetNetworkIdFromEntity(vehicle)
end)

RegisterServerCallback("vfw:onesync:createPedInVehicle", function(source, model, vehicleNetId, seat, pedType)
    if type(model) ~= "number" then return nil end
    if not allowSpawn(source, "alt_spawn_ped") then return nil end

    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end

    local coords = GetEntityCoords(vehicle)
    local ped = CreatePed(pedType or 4, model, coords.x, coords.y, coords.z, GetEntityHeading(vehicle), true, true)
    if not waitForEntity(ped) then return nil end

    SetPedIntoVehicle(ped, vehicle, seat or -1)
    SetEntityOrphanMode(ped, 2)
    return NetworkGetNetworkIdFromEntity(ped)
end)

function VFW.GetVehicleType(model, source)
    local src = source
    if not src then
        local players = VFW.GetPlayers()
        src = players[1]
    end
    if not src then return "automobile" end

    local ok, result = pcall(TriggerClientCallback, src, "vfw:GetVehicleType", model)
    if ok and result then return result end
    return "automobile"
end

AddEventHandler("playerDropped", function()
    local source = source
    budgets[source] = nil
end)
