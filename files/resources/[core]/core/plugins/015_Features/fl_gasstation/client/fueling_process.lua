---@meta _
---@diagnostic disable: duplicate-doc-field

FuelingProcess = {}

local isProcessActive = false
local processData = nil
local processThread = nil
local startTime = 0
local totalDuration = 0
local cachedTimePerLiter = 0.5

RegisterNetEvent('fl_gasstation:settingUpdated', function(key, value)
    if key == "time_per_liter" then
        cachedTimePerLiter = value
    end
end)

CreateThread(function()
    Wait(2000)
    local settings = TriggerServerCallback("fl_gasstation:getSettings")
    if settings and settings.time_per_liter then
        cachedTimePerLiter = settings.time_per_liter
    end
end)

---@param data table
function FuelingProcess.Start(data)
    if isProcessActive then
        FuelingProcess.Cancel()
    end

    if not data or not data.liters or not data.vehicleNetId then
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(data.vehicleNetId)
    if not vehicle or not DoesEntityExist(vehicle) then
        VFW.ShowNotification({
            type = 'ROUGE',
            subtitle = 'Station Essence',
            message = "Véhicule introuvable"
        })
        return
    end

    processData = data
    isProcessActive = true
    startTime = GetGameTimer()
    totalDuration = data.liters * cachedTimePerLiter * 1000

    PumpObject.Attach(data.pumpCoords)
    FuelingAnimation.Start()

    FuelingProcess.ShowProgressInterface(true)

    processThread = CreateThread(function()
        local updateInterval = FuelingConfig.ProgressBar.updateInterval
        local lastUpdate = 0

        while isProcessActive and processData do
            Wait(updateInterval)

            if not processData then break end

            local currentTime = GetGameTimer()
            local elapsed = currentTime - startTime
            local progress = math.min((elapsed / totalDuration) * 100, 100)

            local currentLiters = (progress / 100) * processData.liters
            local timeRemaining = math.max((totalDuration - elapsed) / 1000, 0)

            if currentTime - lastUpdate >= updateInterval then
                FuelingProcess.UpdateProgress({
                    progress = progress,
                    currentLiters = currentLiters,
                    totalLiters = processData.liters,
                    timeRemaining = timeRemaining
                })
                lastUpdate = currentTime
            end

            if progress >= 100 then
                FuelingProcess.Complete()
                break
            end

            if elapsed > 3000 and (elapsed % 2000) < updateInterval then
                if FuelingProcess.CheckCancelConditions() then
                    FuelingProcess.Cancel()
                    break
                end
            end
        end
    end)

end

---@param progressData table
function FuelingProcess.UpdateProgress(progressData)
    SendNUIMessage({
        action = 'nui:gasstation:fuelingProgress',
        data = {
            visible = true,
            progress = progressData.progress,
            currentLiters = progressData.currentLiters,
            totalLiters = progressData.totalLiters,
            timeRemaining = progressData.timeRemaining
        }
    })
end

---@param visible boolean
function FuelingProcess.ShowProgressInterface(visible)
    SendNUIMessage({
        action = 'nui:gasstation:fuelingProgress',
        data = {
            visible = visible,
            progress = 0,
            currentLiters = 0,
            totalLiters = processData and processData.liters or 0,
            timeRemaining = 0
        }
    })
end

---@return boolean shouldCancel
function FuelingProcess.CheckCancelConditions()
    local playerPed = PlayerPedId()

    if IsEntityDead(playerPed) then
        return true
    end

    if IsPedInAnyVehicle(playerPed, false) then
        return true
    end

    if not processData or not processData.vehicleNetId then
        return true
    end

    local vehicle = NetworkGetEntityFromNetworkId(processData.vehicleNetId)
    if not vehicle or vehicle == 0 then
        Wait(500)
        vehicle = NetworkGetEntityFromNetworkId(processData.vehicleNetId)
        if not vehicle or vehicle == 0 then
            return true
        end
    end

    if not DoesEntityExist(vehicle) then
        return true
    end

    local playerPos = GetEntityCoords(playerPed)
    local vehiclePos = GetEntityCoords(vehicle)
    local distance = #(playerPos - vehiclePos)

    if distance > FuelingConfig.MaxFuelNozzleDistance then
        return true
    end

    return false
end

function FuelingProcess.Complete()
    if not isProcessActive or not processData then
        return
    end

    if processData.vehicleNetId then
        local vehicle = NetworkGetEntityFromNetworkId(processData.vehicleNetId)
        if vehicle and DoesEntityExist(vehicle) then
            local newFuelPercent = VehicleFuel.AddLiters(vehicle, processData.liters, true)
            TriggerServerEvent("fl_gasstation:syncVehicleFuel", processData.vehicleNetId, newFuelPercent)
            TriggerServerEvent("fl_gasstation:fuelingComplete", processData.vehicleNetId)

            VFW.ShowNotification({
                type = 'VERT',
                subtitle = 'Station Essence',
                message = string.format("Remplissage terminé ! +%.2fL d'essence", processData.liters)
            })
        end
    end

    FuelingProcess.Cleanup()
end

function FuelingProcess.Cancel(silent)
    if not isProcessActive then
        return
    end

    local partialLiters = 0

    if processData and processData.vehicleNetId then
        local elapsed = GetGameTimer() - startTime
        local progress = math.min((elapsed / totalDuration) * 100, 100)
        partialLiters = (progress / 100) * processData.liters
        local unusedLiters = processData.liters - partialLiters

        if partialLiters > 0.1 then
            local vehicle = NetworkGetEntityFromNetworkId(processData.vehicleNetId)
            if vehicle and DoesEntityExist(vehicle) then
                local newFuelPercent = VehicleFuel.AddLiters(vehicle, partialLiters, true)
                TriggerServerEvent("fl_gasstation:syncVehicleFuel", processData.vehicleNetId, newFuelPercent)
            end
        end

        TriggerServerEvent("fl_gasstation:fuelingCancelled", processData.vehicleNetId, unusedLiters)
    end

    if not silent then
        if partialLiters > 0.1 then
            VFW.ShowNotification({
                type = 'JAUNE',
                subtitle = 'Station Essence',
                message = string.format("Remplissage annulé. %.1fL ajoutés, reste remboursé.", partialLiters)
            })
        else
            VFW.ShowNotification({
                type = 'JAUNE',
                subtitle = 'Station Essence',
                message = "Remplissage annulé. Montant remboursé."
            })
        end
    end

    FuelingProcess.Cleanup()
end

function FuelingProcess.Cleanup()
    isProcessActive = false

    if processThread then
        processThread = nil
    end

    FuelingAnimation.Stop()
    PumpObject.Detach()
    FuelingProcess.ShowProgressInterface(false)

    processData = nil
    startTime = 0
    totalDuration = 0
end

---@return boolean
function FuelingProcess.IsActive()
    return isProcessActive
end

---@return table|nil
function FuelingProcess.GetProcessData()
    return processData
end

RegisterNetEvent('fl_gasstation:beginFuelingProcess', function(data)
    FuelingProcess.Start(data)
end)

RegisterNetEvent('fl_gasstation:cancelFueling', function()
    FuelingProcess.Cancel()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        FuelingProcess.Cleanup()
    end
end)
