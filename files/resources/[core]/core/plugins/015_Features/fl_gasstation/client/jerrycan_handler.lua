---@meta _
---@diagnostic disable: duplicate-doc-field

JerrycanHandler = {}

local isHoldingJerrycan = false
local targetVehicleNetId = nil
local litersToAdd = 0
local jerrycanThread = nil
local storedPumpCoords = nil

---@param vehicleNetId number
---@param liters number
---@param pumpCoords vector3|nil
function JerrycanHandler.Start(vehicleNetId, liters, pumpCoords)
    if isHoldingJerrycan then
        JerrycanHandler.Stop()
    end

    targetVehicleNetId = vehicleNetId
    litersToAdd = liters
    storedPumpCoords = pumpCoords
    isHoldingJerrycan = true

    PumpObject.Attach(pumpCoords)

    jerrycanThread = CreateThread(function()
        while isHoldingJerrycan do
            Wait(0)

            if IsControlJustPressed(0, 73) then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    subtitle = 'Station Essence',
                    message = "Pompe lâchée"
                })
                JerrycanHandler.Cancel()
                break
            end

            local playerPed = PlayerPedId()

            if IsPedInAnyVehicle(playerPed, false) then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    subtitle = 'Station Essence',
                    message = "Vous êtes monté dans un véhicule"
                })
                JerrycanHandler.Cancel()
                break
            end
            local playerPos = GetEntityCoords(playerPed)
            local vehicle = NetworkGetEntityFromNetworkId(targetVehicleNetId)

            if vehicle and DoesEntityExist(vehicle) then
                local vehiclePos = GetEntityCoords(vehicle)
                local distance = #(playerPos - vehiclePos)

                if distance > FuelingConfig.MaxFuelNozzleDistance then
                    VFW.ShowNotification({
                        type = 'ROUGE',
                        subtitle = 'Station Essence',
                        message = "Vous vous êtes trop éloigné du véhicule"
                    })
                    JerrycanHandler.Cancel()
                    break
                end

                if distance <= FuelingConfig.VehicleInteractionDistance then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour faire le plein")

                    if VFW.Interact.JustPressed(0, 38) then
                        JerrycanHandler.StartFueling()
                        break
                    end
                else
                    VFW.ShowHelpNotification("Approchez-vous du véhicule")
                end
            else
                VFW.ShowHelpNotification("~r~Véhicule introuvable")
            end
        end
    end)

    VFW.ShowNotification({
        type = 'BLEU',
        subtitle = 'Station Essence',
        message = "Jerrycan en main. Approchez-vous de votre véhicule"
    })
end

function JerrycanHandler.StartFueling()
    if not targetVehicleNetId or not litersToAdd then
        return
    end

    local fuelingData = {
        vehicleNetId = targetVehicleNetId,
        liters = litersToAdd,
        pumpCoords = storedPumpCoords
    }

    local pumpCoordsBackup = storedPumpCoords
    JerrycanHandler.Stop()

    fuelingData.pumpCoords = pumpCoordsBackup

    TriggerEvent('fl_gasstation:beginFuelingProcess', fuelingData)
end

function JerrycanHandler.Cancel()
    if not isHoldingJerrycan then
        return
    end

    if targetVehicleNetId then
        TriggerServerEvent("fl_gasstation:fuelingCancelled", targetVehicleNetId, litersToAdd)
    end

    JerrycanHandler.Stop()
end

function JerrycanHandler.Stop()
    isHoldingJerrycan = false
    targetVehicleNetId = nil
    litersToAdd = 0
    storedPumpCoords = nil

    if jerrycanThread then
        jerrycanThread = nil
    end

    PumpObject.Detach()
end

---@return boolean
function JerrycanHandler.IsHolding()
    return isHoldingJerrycan
end

---@param vehicle number
---@return string side
function JerrycanHandler.GetFuelCapSide(vehicle)
    local model = GetEntityModel(vehicle)

    if FuelingConfig.FuelCapSides.leftSide[model] then
        return "left"
    end

    return FuelingConfig.FuelCapSides.default
end

---@param vehicle number
---@param playerPos vector3
---@return string side
function JerrycanHandler.GetPlayerSideRelativeToVehicle(vehicle, playerPos)
    local vehiclePos = GetEntityCoords(vehicle)
    local vehicleHeading = GetEntityHeading(vehicle)

    local toPlayer = vector2(playerPos.x - vehiclePos.x, playerPos.y - vehiclePos.y)

    local vehicleForward = vector2(
        math.sin(math.rad(vehicleHeading)),
        math.cos(math.rad(vehicleHeading))
    )

    local crossProduct = toPlayer.x * vehicleForward.y - toPlayer.y * vehicleForward.x

    return crossProduct > 0 and "left" or "right"
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        JerrycanHandler.Stop()
    end
end)
