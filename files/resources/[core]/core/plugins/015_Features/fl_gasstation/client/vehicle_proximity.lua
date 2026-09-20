---@meta _
---@diagnostic disable: duplicate-doc-field

VehicleProximity = {}

local isActive = false
local targetVehicleNetId = nil
local litersToAdd = 0
local proximityThread = nil

---@param vehicleNetId number
---@param liters number
function VehicleProximity.Start(vehicleNetId, liters)
    if isActive then
        VehicleProximity.Stop()
    end

    targetVehicleNetId = vehicleNetId
    litersToAdd = liters
    isActive = true

    proximityThread = CreateThread(function()
        while isActive and targetVehicleNetId do
            Wait(0)

            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            local vehicle = NetworkGetEntityFromNetworkId(targetVehicleNetId)

            if vehicle and DoesEntityExist(vehicle) then
                local vehiclePos = GetEntityCoords(vehicle)
                local distance = #(playerPos - vehiclePos)

                if distance <= FuelingConfig.VehicleInteractionDistance then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour faire le plein")

                    if VFW.Interact.JustPressed(0, 38) then
                        VehicleProximity.StartFueling()
                    end
                else
                    VFW.ShowHelpNotification("Approchez-vous du vehicule")
                end
            else
                VFW.ShowNotification({
                    type = 'ROUGE',
                    subtitle = 'Station Essence',
                    message = "Véhicule introuvable"
                })
                VehicleProximity.Stop()
            end
        end
    end)
end

function VehicleProximity.Stop()
    isActive = false
    targetVehicleNetId = nil
    litersToAdd = 0

    if proximityThread then
        proximityThread = nil
    end
end

---@param vehicle number
---@return string side
function VehicleProximity.GetFuelCapSide(vehicle)
    local model = GetEntityModel(vehicle)
    local modelHash = tostring(model)

    for _, leftHash in ipairs(FuelingConfig.FuelCapSides.leftSide) do
        if modelHash == tostring(leftHash) then
            return "left"
        end
    end

    return FuelingConfig.FuelCapSides.default
end

---@param vehicle number
---@param playerPos vector3
---@return string side
function VehicleProximity.GetPlayerSideRelativeToVehicle(vehicle, playerPos)
    local vehiclePos = GetEntityCoords(vehicle)
    local vehicleHeading = GetEntityHeading(vehicle)

    local radHeading = math.rad(vehicleHeading)
    local vehicleForward = vector3(math.cos(radHeading), math.sin(radHeading), 0.0)
    local toPlayer = playerPos - vehiclePos
    toPlayer = vector3(toPlayer.x, toPlayer.y, 0.0)

    local crossProduct = vehicleForward.x * toPlayer.y - vehicleForward.y * toPlayer.x

    return crossProduct > 0 and "left" or "right"
end

function VehicleProximity.StartFueling()
    if not targetVehicleNetId or not litersToAdd then
        return
    end

    local fuelingData = {
        vehicleNetId = targetVehicleNetId,
        liters = litersToAdd
    }

    VehicleProximity.Stop()

    TriggerEvent('fl_gasstation:beginFuelingProcess', fuelingData)
end

---@return boolean
function VehicleProximity.IsActive()
    return isActive
end
