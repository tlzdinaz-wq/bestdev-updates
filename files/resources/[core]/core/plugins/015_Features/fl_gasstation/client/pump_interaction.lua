---@meta _
---@diagnostic disable: duplicate-doc-field

PumpInteraction = {}

local activePumps = {}
local interactionThread = nil
local isInteractionActive = false
local serverPumps = {}
local lastPumpUpdate = -20000
local pumpUpdateInterval = 20000
local isUpdatingPumps = false
local currentPumpCoords = nil
local currentHelpText = nil
local currentVehicleNetId = nil

function PumpInteraction.GetCurrentPumpCoords()
    return currentPumpCoords
end

function PumpInteraction.SetCurrentPumpCoords(coords)
    currentPumpCoords = coords
end

function PumpInteraction.ClearCurrentPumpCoords()
    currentPumpCoords = nil
end

function PumpInteraction.GetCurrentVehicleNetId()
    return currentVehicleNetId
end

function PumpInteraction.SetCurrentVehicleNetId(netId)
    currentVehicleNetId = netId
end

function PumpInteraction.ClearCurrentVehicleNetId()
    currentVehicleNetId = nil
end

local VEHICLE_INTERACT_DISTANCE = 3.5
local PUMP_PROXIMITY_HINT = 8.0

local function findClosestVehicleToPump(pumpCoords, radius)
    local best = nil
    local bestDist = radius
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle) then
            local vehPos = GetEntityCoords(vehicle)
            local dist = #(pumpCoords - vehPos)
            if dist <= bestDist then
                best = vehicle
                bestDist = dist
            end
        end
    end
    return best, bestDist
end

function PumpInteraction.Start()
    if isInteractionActive then
        return
    end

    isInteractionActive = true

    local nearVehicleFound = false

    interactionThread = CreateThread(function()
        while isInteractionActive do
            if nearVehicleFound then
                Wait(0)
            else
                Wait(500)
            end

            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            local currentTime = GetGameTimer()

            if currentTime - lastPumpUpdate > pumpUpdateInterval and not isUpdatingPumps then
                isUpdatingPumps = true

                local pumps = TriggerServerCallback('fl_gasstation:getPumpsNear', playerPos, 50.0)
                serverPumps = pumps or {}
                lastPumpUpdate = currentTime
                isUpdatingPumps = false

                if PumpProtection and PumpProtection.UpdateKnownPumps then
                    PumpProtection.UpdateKnownPumps(serverPumps)
                end
            end

            local nearestPump = nil
            local nearestPumpDistance = PUMP_PROXIMITY_HINT
            for _, pump in ipairs(serverPumps) do
                local distance = #(playerPos - pump.coords)
                if distance <= nearestPumpDistance then
                    nearestPump = pump
                    nearestPumpDistance = distance
                end
            end

            nearVehicleFound = false

            if nearestPump then
                local playerInVehicle = IsPedInAnyVehicle(playerPed, false)
                local hasPumpInHand = PumpObject.IsAttached()
                local isFuelingActive = FuelingProcess.IsActive()
                local isHoldingJerrycan = JerrycanHandler.IsHolding()

                if not playerInVehicle and not hasPumpInHand and not isFuelingActive and not isHoldingJerrycan then
                    local closestVehicle = findClosestVehicleToPump(nearestPump.coords, VEHICLE_INTERACT_DISTANCE)

                    if closestVehicle and DoesEntityExist(closestVehicle) and NetworkGetEntityIsNetworked(closestVehicle) then
                        nearVehicleFound = true
                        currentHelpText = "fuel"
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour faire le plein")

                        if VFW.Interact.JustPressed(0, 38) then
                            PumpInteraction.StartFueling(nearestPump, closestVehicle)
                        end
                    else
                        currentHelpText = nil
                    end
                else
                    currentHelpText = nil
                end
            else
                currentHelpText = nil
            end
        end
    end)
end

function PumpInteraction.Stop()
    isInteractionActive = false
    if interactionThread then
        interactionThread = nil
    end
    activePumps = {}
    serverPumps = {}
    lastPumpUpdate = 0
    isUpdatingPumps = false
end

function PumpInteraction.ForceRefresh()
    lastPumpUpdate = -pumpUpdateInterval
end

---@param pumpData table|nil pompe la plus proche côté client (hint, le serveur valide)
---@param vehicle number entité du véhicule
function PumpInteraction.StartFueling(pumpData, vehicle)
    local realFuelLevel = VehicleFuel and VehicleFuel.Get(vehicle) or GetVehicleFuelLevel(vehicle)
    local realEngineRunning = GetIsVehicleEngineRunning(vehicle)
    local realMaxFuel = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fPetrolTankVolume")

    if realFuelLevel >= 95.0 then
        VFW.ShowNotification({
            type = 'JAUNE',
            subtitle = 'Station Essence',
            message = "Le réservoir est déjà plein"
        })
        return
    end

    if not NetworkGetEntityIsNetworked(vehicle) then
        VFW.ShowNotification({
            type = 'JAUNE',
            subtitle = 'Station Essence',
            message = "Le véhicule n'est pas encore synchronisé"
        })
        return
    end

    currentPumpCoords = pumpData and pumpData.coords or nil

    TriggerServerEvent('fl_gasstation:validateFueling', {
        vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle),
        clientFuelLevel = realFuelLevel,
        clientMaxFuel = realMaxFuel,
        clientEngineRunning = realEngineRunning
    })
end


RegisterNetEvent('fl_gasstation:fuelingValidated', function(data)
    if data.success then
        local moneyData = TriggerServerCallback('fl_gasstation:getPlayerMoneyAndPrice')
        local vehData = data.vehicleData

        if vehData.vehicle and vehData.vehicle.netId then
            currentVehicleNetId = vehData.vehicle.netId
        end

        if vehData.pumpCoords then
            currentPumpCoords = vector3(vehData.pumpCoords.x, vehData.pumpCoords.y, vehData.pumpCoords.z)
        end

        local fuelPercent = vehData.clientFuelLevel or 0
        local tankCapacity = vehData.clientMaxFuel or 65
        local currentFuelLiters = (fuelPercent / 100.0) * tankCapacity

        local interfaceData = {
            visible = true,
            stationName = "Station Essence",
            pricePerLiter = moneyData.pricePerLiter or 150,
            currentFuel = currentFuelLiters,
            maxFuel = tankCapacity,
            playerCash = moneyData.cash or 0,
            playerBank = moneyData.bank or 0
        }

        TriggerEvent('fl_gasstation:openInterface', interfaceData)
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            subtitle = 'Station Essence',
            message = data.message
        })
    end
end)
