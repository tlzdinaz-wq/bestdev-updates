-- ========================================================================
-- VIP VEHICLE DIRT REDUCTION
-- Reduces dirt accumulation speed based on VIP tier
-- ========================================================================

local lastDirtLevel = 0.0
local threadActive = false

local function StartDirtThread()
    if threadActive then return end
    threadActive = true

    CreateThread(function()
        while threadActive do
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                local tier = VFW.PlayerGlobalData and VFW.PlayerGlobalData.vip_tier or 0
                local factor = VIPConfig.VehicleDirt.reductionFactor[tier] or 0.0

                if factor > 0.0 then
                    local currentDirt = GetVehicleDirtLevel(vehicle)

                    if currentDirt > lastDirtLevel then
                        local increase = currentDirt - lastDirtLevel
                        local reducedDirt = lastDirtLevel + increase * (1.0 - factor)
                        SetVehicleDirtLevel(vehicle, reducedDirt)
                        lastDirtLevel = reducedDirt
                    else
                        lastDirtLevel = currentDirt
                    end
                else
                    lastDirtLevel = GetVehicleDirtLevel(vehicle)
                end

                Wait(VIPConfig.VehicleDirt.interval)
            else
                lastDirtLevel = 0.0
                Wait(VIPConfig.VehicleDirt.idleInterval)
            end
        end
    end)
end

local function StopDirtThread()
    threadActive = false
    lastDirtLevel = 0.0
end

-- Start thread when VIP config is enabled
CreateThread(function()
    if not VIPConfig.VehicleDirt.enabled then return end

    while not VFW.PlayerGlobalData do
        Wait(1000)
    end

    StartDirtThread()
end)

-- Restart tracking when entering a new vehicle
AddEventHandler("vfw:enteredVehicle", function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        lastDirtLevel = GetVehicleDirtLevel(vehicle)
    end
end)

-- Handle VIP status changes
RegisterNetEvent("vip:updateStatus", function()
    if not VIPConfig.VehicleDirt.enabled then return end

    local tier = VFW.PlayerGlobalData and VFW.PlayerGlobalData.vip_tier or 0
    if tier > 0 and not threadActive then
        StartDirtThread()
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        StopDirtThread()
    end
end)
