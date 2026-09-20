---@meta _
---@diagnostic disable: duplicate-doc-field

VehicleDetection = {}

local nearbyPumps = {}
local detectedVehicles = {}
local currentSelectedVehicle = nil
local detectionThread = nil
local isDetectionActive = false

---@param pumpPos vector3
---@param pumpHeading number
---@param targetPos vector3
---@return string side
local function calculateSide(pumpPos, pumpHeading, targetPos)
    local radHeading = math.rad(pumpHeading)

    local pumpForward = vector3(math.cos(radHeading), math.sin(radHeading), 0.0)

    local toTarget = targetPos - pumpPos
    toTarget = vector3(toTarget.x, toTarget.y, 0.0)

    local crossProduct = pumpForward.x * toTarget.y - pumpForward.y * toTarget.x

    return crossProduct > 0 and "left" or "right"
end

---@param pump table
---@param playerPos vector3
---@return table vehicles
local function detectVehiclesNearPump(pump, playerPos)
    local vehicles = {}
    local allVehicles = GetGamePool('CVehicle')
    local playerSide = calculateSide(pump.coords, pump.heading, playerPos)

    for _, vehicle in ipairs(allVehicles) do
        if DoesEntityExist(vehicle) then
            local vehiclePos = GetEntityCoords(vehicle)
            local distance = #(pump.coords - vehiclePos)

            if distance <= GasStationConfig.VehicleDetectionRadius then
                local vehicleSide = calculateSide(pump.coords, pump.heading, vehiclePos)
                local plate = GetVehicleNumberPlateText(vehicle)
                local model = GetEntityModel(vehicle)
                local displayName = GetDisplayNameFromVehicleModel(model)
                local fuelPercent = VehicleFuel and VehicleFuel.Get(vehicle) or GetVehicleFuelLevel(vehicle)
                local fuelCapacity = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fPetrolTankVolume")
                local fuelLiters = (fuelPercent / 100.0) * fuelCapacity

                local sidePriority = (vehicleSide == playerSide) and 1 or 0

                table.insert(vehicles, {
                    entity = vehicle,
                    plate = plate and plate:gsub("^%s*(.-)%s*$", "%1") or "UNKNOWN",
                    model = model,
                    displayName = displayName,
                    coords = vehiclePos,
                    distance = distance,
                    side = vehicleSide,
                    sidePriority = sidePriority,
                    playerSide = playerSide,
                    fuelLevel = fuelLiters,
                    fuelPercent = fuelPercent,
                    fuelCapacity = fuelCapacity,
                    maxFuel = fuelCapacity,
                    engineRunning = GetIsVehicleEngineRunning(vehicle),
                    pumpId = pump.id or "unknown"
                })
            end
        end
    end

    table.sort(vehicles, function(a, b)
        if a.sidePriority ~= b.sidePriority then
            return a.sidePriority > b.sidePriority
        end

        if a.engineRunning ~= b.engineRunning then
            return not a.engineRunning and b.engineRunning
        end

        return a.distance < b.distance
    end)

    return vehicles
end

---@param vehicles table
---@param playerSide string
---@return table|nil bestVehicle
local function selectBestVehicle(vehicles, playerSide)
    if #vehicles == 0 then
        return nil
    end

    for _, vehicle in ipairs(vehicles) do
        if vehicle.side == playerSide then
            return vehicle
        end
    end

    return nil
end

function VehicleDetection.Start()
    if isDetectionActive then
        return
    end

    isDetectionActive = true
    detectionThread = CreateThread(function()
        while isDetectionActive do
            Wait(500)

            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            detectedVehicles = {}

            for pumpId, pumpData in pairs(nearbyPumps) do
                local distance = #(playerPos - pumpData.coords)

                if distance <= GasStationConfig.PumpDetectionRadius then
                    local vehicles = detectVehiclesNearPump(pumpData, playerPos)

                    if #vehicles > 0 then
                        local playerSide = vehicles[1].playerSide
                        local selectedVehicle = selectBestVehicle(vehicles, playerSide)

                        if selectedVehicle then
                            detectedVehicles[pumpId] = {
                                vehicle = selectedVehicle,
                                allVehicles = vehicles,
                                pumpData = pumpData
                            }
                        end
                    end
                end
            end

            TriggerEvent('fl_gasstation:vehicleDetectionUpdate', detectedVehicles)
        end
    end)
end

function VehicleDetection.Stop()
    isDetectionActive = false
    if detectionThread then
        detectionThread = nil
    end
    detectedVehicles = {}
    currentSelectedVehicle = nil
    TriggerEvent('fl_gasstation:vehicleDetectionUpdate', {})
end

---@param pumpId string
---@param pumpData table
function VehicleDetection.AddPump(pumpId, pumpData)
    nearbyPumps[pumpId] = pumpData
end

---@param pumpId string
function VehicleDetection.RemovePump(pumpId)
    nearbyPumps[pumpId] = nil
    if detectedVehicles[pumpId] then
        detectedVehicles[pumpId] = nil
        TriggerEvent('fl_gasstation:vehicleDetectionUpdate', detectedVehicles)
    end
end

---@return table detectedVehicles
function VehicleDetection.GetDetectedVehicles()
    return detectedVehicles
end

---@param pumpId string
---@return table|nil vehicleData
function VehicleDetection.GetVehicleForPump(pumpId)
    return detectedVehicles[pumpId]
end

function VehicleDetection.ForceUpdate()
    if not isDetectionActive then
        return
    end

    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    detectedVehicles = {}

    for pumpId, pumpData in pairs(nearbyPumps) do
        local distance = #(playerPos - pumpData.coords)

        if distance <= GasStationConfig.PumpDetectionRadius then
            local vehicles = detectVehiclesNearPump(pumpData, playerPos)

            if #vehicles > 0 then
                local playerSide = vehicles[1].playerSide
                local selectedVehicle = selectBestVehicle(vehicles, playerSide)

                if selectedVehicle then
                    detectedVehicles[pumpId] = {
                        vehicle = selectedVehicle,
                        allVehicles = vehicles,
                        pumpData = pumpData
                    }
                end
            end
        end
    end

    TriggerEvent('fl_gasstation:vehicleDetectionUpdate', detectedVehicles)
end

RegisterNetEvent('fl_gasstation:startVehicleDetection', function()
    VehicleDetection.Start()
end)

RegisterNetEvent('fl_gasstation:stopVehicleDetection', function()
    VehicleDetection.Stop()
end)

if GetConvar("fl_gasstation_debug", "false") == "true" then
    AddEventHandler('fl_gasstation:vehicleDetectionUpdate', function(vehicles)
        for pumpId, data in pairs(vehicles) do
            local veh = data.vehicle
        end
    end)
end
