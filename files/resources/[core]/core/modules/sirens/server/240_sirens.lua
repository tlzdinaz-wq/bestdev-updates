local SIREN_IDS = { ["01"] = true, ["02"] = true, ["03"] = true }
local EXTRA_SLOTS = { [1] = true, [2] = true, [3] = true }
local COOLDOWN_MS = 80

local cooldowns = {}
local hornOwners = {}

VFW.Sirens = VFW.Sirens or {}

local function throttled(source, key)
    local now = GetGameTimer()
    local bucket = cooldowns[source]

    if not bucket then
        bucket = {}
        cooldowns[source] = bucket
    end

    if bucket[key] and now < bucket[key] then
        return true
    end

    bucket[key] = now + COOLDOWN_MS
    return false
end

local function resolveVehicle(netId)
    netId = tonumber(netId)
    if not netId or netId <= 0 then return nil end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    if GetEntityType(entity) ~= 2 then return nil end

    return entity
end

local function authorize(source, netId, key)
    if throttled(source, key) then return nil end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local vehicle = resolveVehicle(netId)
    if not vehicle then return nil end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    if GetVehiclePedIsIn(ped) ~= vehicle then return nil end

    return vehicle, ped
end

local function pedNetId(ped)
    if not ped or ped == 0 then return nil end
    local netId = NetworkGetNetworkIdFromEntity(ped)
    if not netId or netId == 0 then return nil end
    return netId
end

local function setBag(vehicle, key, value)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    Entity(vehicle).state:set(key, value, true)
end

function VFW.Sirens.Reset(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local state = Entity(vehicle).state
    state:set("siren", false, true)
    state:set("flashingLight", false, true)
    state:set("extra", false, true)
    state:set("projector", false, true)
    state:set("horn", false, true)
end

function VFW.Sirens.StopHornFor(source)
    local netId = hornOwners[source]
    if not netId then return end

    hornOwners[source] = nil

    local vehicle = resolveVehicle(netId)
    if vehicle then
        setBag(vehicle, "horn", false)
    end
end

RegisterNetEvent("broadcast:siren:start", function(netId, sirenId)
    local source = source

    if type(sirenId) ~= "string" or not SIREN_IDS[sirenId] then return end

    local vehicle, ped = authorize(source, netId, "siren")
    if not vehicle then return end

    setBag(vehicle, "siren", sirenId)

    local pnid = pedNetId(ped)
    if pnid then
        TriggerClientEvent("nui:update:siren", source, pnid, true, sirenId)
    end
end)

RegisterNetEvent("broadcast:siren:stop", function(netId)
    local source = source

    local vehicle, ped = authorize(source, netId, "siren")
    if not vehicle then return end

    setBag(vehicle, "siren", false)

    local pnid = pedNetId(ped)
    if pnid then
        TriggerClientEvent("nui:update:siren", source, pnid, false)
    end
end)

RegisterNetEvent("broadcast:flashingLight:start", function(netId)
    local source = source

    local vehicle, ped = authorize(source, netId, "flashingLight")
    if not vehicle then return end

    setBag(vehicle, "flashingLight", true)

    local pnid = pedNetId(ped)
    if pnid then
        TriggerClientEvent("nui:update:flashingLight", source, pnid, true)
    end
end)

RegisterNetEvent("broadcast:flashingLight:stop", function(netId)
    local source = source

    local vehicle, ped = authorize(source, netId, "flashingLight")
    if not vehicle then return end

    setBag(vehicle, "flashingLight", false)
    setBag(vehicle, "siren", false)
    setBag(vehicle, "extra", false)
    setBag(vehicle, "projector", false)

    local pnid = pedNetId(ped)
    if pnid then
        TriggerClientEvent("nui:update:flashingLight", source, pnid, false)
        TriggerClientEvent("nui:update:extra", source, pnid, false)
        TriggerClientEvent("nui:update:projector", source, pnid, false)
    end
end)

RegisterNetEvent("broadcast:extra:start", function(netId, extraSlot)
    local source = source

    extraSlot = tonumber(extraSlot)
    if not extraSlot or not EXTRA_SLOTS[extraSlot] then return end

    local vehicle, ped = authorize(source, netId, "extra")
    if not vehicle then return end

    setBag(vehicle, "extra", extraSlot)

    local pnid = pedNetId(ped)
    if pnid then
        TriggerClientEvent("nui:update:extra", source, pnid, true, extraSlot)
    end
end)

RegisterNetEvent("broadcast:extra:stop", function(netId)
    local source = source

    local vehicle, ped = authorize(source, netId, "extra")
    if not vehicle then return end

    setBag(vehicle, "extra", false)

    local pnid = pedNetId(ped)
    if pnid then
        TriggerClientEvent("nui:update:extra", source, pnid, false)
    end
end)

RegisterNetEvent("broadcast:projector:start", function(netId)
    local source = source

    local vehicle, ped = authorize(source, netId, "projector")
    if not vehicle then return end

    setBag(vehicle, "projector", true)

    local pnid = pedNetId(ped)
    if pnid then
        TriggerClientEvent("nui:update:projector", source, pnid, true)
    end
end)

RegisterNetEvent("broadcast:projector:stop", function(netId)
    local source = source

    local vehicle, ped = authorize(source, netId, "projector")
    if not vehicle then return end

    setBag(vehicle, "projector", false)

    local pnid = pedNetId(ped)
    if pnid then
        TriggerClientEvent("nui:update:projector", source, pnid, false)
    end
end)

RegisterNetEvent("broadcast:horn:start", function(netId)
    local source = source

    local vehicle = authorize(source, netId, "horn")
    if not vehicle then return end

    hornOwners[source] = tonumber(netId)
    setBag(vehicle, "horn", true)
end)

RegisterNetEvent("broadcast:horn:stop", function(netId)
    local source = source

    local requested = tonumber(netId) or hornOwners[source]
    if not requested then return end

    hornOwners[source] = nil

    local vehicle = resolveVehicle(requested)
    if not vehicle then return end

    setBag(vehicle, "horn", false)
end)

AddEventHandler("vfw:game:vehicleExited", function(source)
    VFW.Sirens.StopHornFor(source)
end)

AddEventHandler("playerDropped", function()
    local source = source
    VFW.Sirens.StopHornFor(source)
    cooldowns[source] = nil
end)

AddEventHandler("vfw:playerDropped", function(source)
    VFW.Sirens.StopHornFor(source)
    cooldowns[source] = nil
end)

CreateThread(function()
    while true do
        Wait(5000)

        for source, netId in pairs(hornOwners) do
            local ped = GetPlayerPed(source)
            local vehicle = resolveVehicle(netId)

            if not ped or ped == 0 or not vehicle or GetVehiclePedIsIn(ped) ~= vehicle then
                hornOwners[source] = nil
                if vehicle then
                    setBag(vehicle, "horn", false)
                end
            end
        end
    end
end)
