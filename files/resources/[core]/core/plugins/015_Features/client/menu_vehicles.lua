---@meta _
---@diagnostic disable: duplicate-doc-field

local infoVeh, maxSpeed, limitateur, autoDrive, open = nil , 50, false, false, false
local speedLimiterOpen = false

-- Cache global de l'état des fenêtres baissées par véhicule (netId -> {[windowIndex] = bool})
VehicleWindowsRolledDown = {}

-- Fonction pour mettre à jour l'état d'une fenêtre
local function SetWindowRolledState(vehicle, windowIndex, isRolledDown)
    if not DoesEntityExist(vehicle) then return end
    local netId = VehToNet(vehicle)
    if not netId or netId == 0 then return end

    if not VehicleWindowsRolledDown[netId] then
        VehicleWindowsRolledDown[netId] = {}
    end
    VehicleWindowsRolledDown[netId][windowIndex] = isRolledDown

    -- Notifier le système de musique
    TriggerEvent("vfw:vehicle:windowStateChanged", vehicle)
end

-- Fonction globale pour vérifier si une fenêtre est baissée
function IsVehicleWindowRolledDown(vehicle, windowIndex)
    if not DoesEntityExist(vehicle) then return false end
    local netId = VehToNet(vehicle)
    if not netId or netId == 0 then return false end

    if VehicleWindowsRolledDown[netId] and VehicleWindowsRolledDown[netId][windowIndex] then
        return true
    end
    return false
end

-- Ouvre/ferme l'UI du limitateur de vitesse
local function ToggleSpeedLimiter()
    if not IsPedInAnyVehicle(VFW.PlayerData.ped, false) then return end
    if GetPedInVehicleSeat(GetVehiclePedIsIn(VFW.PlayerData.ped, false), -1) ~= VFW.PlayerData.ped then return end

    speedLimiterOpen = not speedLimiterOpen

    -- Désactiver/activer le chat
    TriggerEvent('chat:setDisabled', speedLimiterOpen)

    if speedLimiterOpen then
        local vehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
        local currentSpeed = GetEntitySpeed(vehicle) * 3.6

        SendNUIMessage({
            action = "nui:speedLimiter:visible",
            data = true
        })
        SendNUIMessage({
            action = "nui:speedLimiter:data",
            data = {
                currentSpeed = currentSpeed,
                maxSpeed = maxSpeed,
                isActive = limitateur
            }
        })

        -- Activer le focus NUI tout en gardant les contrôles du véhicule
        VFW.Nui.Focus(true, true)

        -- Thread pour désactiver la rotation de la caméra avec la souris et le chat
        CreateThread(function()
            while speedLimiterOpen do
                DisableControlAction(0, 1, true)   -- Look Left/Right
                DisableControlAction(0, 2, true)   -- Look Up/Down
                DisableControlAction(0, 106, true) -- Vehicle Mouse Control Override
                Wait(0)
            end
        end)
        -- Thread pour mettre à jour la vitesse en temps réel
        CreateThread(function()
            while speedLimiterOpen do
                if IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
                    local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
                    local speed = GetEntitySpeed(veh) * 3.6
                    SendNUIMessage({
                        action = "nui:speedLimiter:updateSpeed",
                        data = speed
                    })
                else
                    -- Joueur sorti du véhicule, fermer l'UI
                    speedLimiterOpen = false
                    SendNUIMessage({
                        action = "nui:speedLimiter:visible",
                        data = false
                    })
                    VFW.Nui.Focus(false, false)
                end
                Wait(100)
            end
        end)
    else
        SendNUIMessage({
            action = "nui:speedLimiter:visible",
            data = false
        })
        VFW.Nui.Focus(false, false)
    end
end

VFW.RegisterInput("__limitateur", "Limitateur de vitesse", "keyboard", "M", ToggleSpeedLimiter)

-- NUI Callbacks pour le limitateur de vitesse
RegisterNUICallback("nui:speedLimiter:close", function(data, cb)
    speedLimiterOpen = false
    TriggerEvent('chat:setDisabled', false)
    SendNUIMessage({
        action = "nui:speedLimiter:visible",
        data = false
    })
    VFW.Nui.Focus(false)
    cb('ok')
end)

RegisterNUICallback("nui:speedLimiter:activate", function(data, cb)
    if not IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
        cb('ok')
        return
    end

    local vehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
    local speed = tonumber(data.speed) or 50

    if speed < 10 then speed = 10 end
    if speed > 180 then speed = 180 end

    maxSpeed = speed
    limitateur = true

    -- Attendre que la vitesse soit en dessous de la limite avant d'appliquer
    CreateThread(function()
        while GetEntitySpeed(vehicle) > maxSpeed / 3.6 do
            Wait(1)
        end
        if limitateur then
            SetVehicleMaxSpeed(vehicle, maxSpeed / 3.6)
        end
    end)

    VFW.ShowNotification({
        type = 'JAUNE',
        content = "Limitateur activé à " .. maxSpeed .. " km/h"
    })

    cb('ok')
end)

RegisterNUICallback("nui:speedLimiter:deactivate", function(data, cb)
    if not IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
        cb('ok')
        return
    end

    local vehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
    SetVehicleMaxSpeed(vehicle, GetVehicleEstimatedMaxSpeed(vehicle))
    limitateur = false

    VFW.ShowNotification({
        type = 'JAUNE',
        content = "Limitateur désactivé"
    })

    cb('ok')
end)

--- StartAutoDrive
local function StartAutoDrive()
    local coords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))

    if coords ~= nil and coords ~= 0 then
        TaskVehicleDriveToCoordLongrange(VFW.PlayerData.ped, GetVehiclePedIsIn(VFW.PlayerData.ped, false), coords.x, coords.y, coords.z, 50.0, 907, 20.0)
    end

    CreateThread(function()
        while autoDrive do
            if #(GetEntityCoords(VFW.PlayerData.ped) - coords) <= 20.0 then
                if autoDrive then
                    ClearPedTasks(VFW.PlayerData.ped)
                    SetVehicleForwardSpeed(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 19.0)
                    Wait(200)
                    SetVehicleForwardSpeed(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 15.0)
                    Wait(200)
                    SetVehicleForwardSpeed(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 11.0)
                    Wait(200)
                    SetVehicleForwardSpeed(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 6.0)
                    Wait(200)
                    SetVehicleForwardSpeed(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 0.0)
                    VFW.ShowNotification({
                        type = 'JAUNE',
                        content = "Vous êtes arrivé ~c à destination"
                    })
                    autoDrive = false
                    return
                else
                    return
                end
            end

            Wait(1)
        end
    end)
end

RegisterNUICallback("nui:vehicleMenu", function(data)
    console.debug("nui:vehicleMenu", json.encode(data))

    for k, v in pairs(data) do
        if k == "engine" then
            if v then
                SetVehicleEngineOn(GetVehiclePedIsIn(VFW.PlayerData.ped, false), false, false, true)
                SetVehicleUndriveable(GetVehiclePedIsIn(VFW.PlayerData.ped, false), true)
            else
                SetVehicleEngineOn(GetVehiclePedIsIn(VFW.PlayerData.ped, false), true, false, true)
                SetVehicleUndriveable(GetVehiclePedIsIn(VFW.PlayerData.ped, false), false)
            end

            return
        elseif k == "frontLeft" then
            if v then
                SetVehicleDoorOpen(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 0, false, false)
            else
                SetVehicleDoorShut(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 0, false)
            end

            return
        elseif k == "frontRight" then
            if v then
                SetVehicleDoorOpen(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 1, false, false)
            else
                SetVehicleDoorShut(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 1, false)
            end

            return
        elseif k == "backLeft" then
            if v then
                SetVehicleDoorOpen(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 2, false, false)
            else
                SetVehicleDoorShut(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 2, false)
            end

            return
        elseif k == "backRight" then
            if v then
                SetVehicleDoorOpen(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 3, false, false)
            else
                SetVehicleDoorShut(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 3, false)
            end

            return
        elseif k == "hood" then
            if v then
                SetVehicleDoorOpen(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 4, false, false)
            else
                SetVehicleDoorShut(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 4, false)
            end

            return
        elseif k == "trunk" then
            if v then
                SetVehicleDoorOpen(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 5, false, false)
            else
                SetVehicleDoorShut(GetVehiclePedIsIn(VFW.PlayerData.ped, false), 5, false)
            end

            return
        elseif k == "windowsFrontLeft" then
            local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
            if v then
                RollUpWindow(veh, 0)
                SetWindowRolledState(veh, 0, false)
            else
                RollDownWindow(veh, 0)
                SetWindowRolledState(veh, 0, true)
            end

            return
        elseif k == "windowsFrontRight" then
            local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
            if v then
                RollUpWindow(veh, 1)
                SetWindowRolledState(veh, 1, false)
            else
                RollDownWindow(veh, 1)
                SetWindowRolledState(veh, 1, true)
            end

            return
        elseif k == "windowsBackLeft" then
            local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
            if v then
                RollUpWindow(veh, 2)
                SetWindowRolledState(veh, 2, false)
            else
                RollDownWindow(veh, 2)
                SetWindowRolledState(veh, 2, true)
            end

            return
        elseif k == "windowsBackRight" then
            local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
            if v then
                RollUpWindow(veh, 3)
                SetWindowRolledState(veh, 3, false)
            else
                RollDownWindow(veh, 3)
                SetWindowRolledState(veh, 3, true)
            end

            return
        elseif k == "limitateurVitesse" then
            maxSpeed = v
            return
        elseif k == "autoDrive" then
            if not v then
                if IsWaypointActive() then
                    StartAutoDrive()
                    autoDrive = true
                else
                    VFW.ShowNotification({
                        type = 'ROUGE',
                        content = "Vous devez avoir un point d'arrivée pour lancer la conduite auto"
                    })
                end
            else
                ClearPedTasks(VFW.PlayerData.ped)
                autoDrive = false
            end

            return
        end
    end
end)

RegisterNUICallback("nui:vehicleMenu:close", function(data)
    open = false
    VFW.Nui.VehiclesMenu(false)
end)
