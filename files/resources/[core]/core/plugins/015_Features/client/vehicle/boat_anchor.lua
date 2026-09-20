local CHECK_INTERVAL = 1500
local SETTLE_DELAY = 1000
local BOAT_CLASS = 14

local firstSeenAt = {}

local function setBoatFrozen(veh, freeze)
    if not NetworkHasControlOfEntity(veh) then
        NetworkRequestControlOfEntity(veh)
    end
    FreezeEntityPosition(veh, freeze)
end

CreateThread(function()
    while true do
        Wait(CHECK_INTERVAL)
        local vehicles = GetGamePool('CVehicle')
        local seen = {}
        local now = GetGameTimer()
        for i = 1, #vehicles do
            local veh = vehicles[i]
            if DoesEntityExist(veh) and GetVehicleClass(veh) == BOAT_CLASS then
                seen[veh] = true
                local driver = GetPedInVehicleSeat(veh, -1)
                local hasDriver = driver ~= 0 and DoesEntityExist(driver) and not IsPedDeadOrDying(driver, true)
                local frozen = IsEntityPositionFrozen(veh)
                if hasDriver then
                    firstSeenAt[veh] = nil
                    if frozen then
                        setBoatFrozen(veh, false)
                    end
                else
                    if not firstSeenAt[veh] then
                        firstSeenAt[veh] = now
                    end
                    if not frozen and now - firstSeenAt[veh] >= SETTLE_DELAY then
                        setBoatFrozen(veh, true)
                    end
                end
            end
        end
        for veh in pairs(firstSeenAt) do
            if not seen[veh] then
                firstSeenAt[veh] = nil
            end
        end
    end
end)
