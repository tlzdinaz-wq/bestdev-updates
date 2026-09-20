local gasStationOpen = false

function VFW.IsGasStationOpen()
    return gasStationOpen
end

RegisterNetEvent('fl_gasstation:openInterface', function(data)
    gasStationOpen = true
    SendNUIMessage({
        action = 'nui:gasstation:visible',
        data = data
    })
    VFW.Nui.Focus(true)
end)

RegisterNUICallback('nui:gasstation:close', function(data, cb)
    gasStationOpen = false
    VFW.Nui.Focus(false)
    PumpInteraction.ClearCurrentPumpCoords()
    PumpInteraction.ClearCurrentVehicleNetId()
    cb('ok')
end)

RegisterNUICallback('nui:gasstation:purchase', function(data, cb)
    local validatedNetId = PumpInteraction.GetCurrentVehicleNetId()
    if not validatedNetId then
        VFW.ShowNotification({
            type = 'ROUGE',
            subtitle = 'Station Essence',
            message = "Aucun véhicule validé. Recommencez l'interaction avec la pompe."
        })
        cb('ok')
        return
    end

    data.vehicleNetId = validatedNetId
    TriggerServerEvent('fl_gasstation:purchaseFuel', data)
    cb('ok')
end)

RegisterNetEvent('fl_gasstation:startManualFueling', function(response)
    if response.success then
        gasStationOpen = false
        VFW.ShowNotification({
            type = 'VERT',
            subtitle = 'Station Essence',
            message = response.message
        })

        VFW.Nui.Focus(false)
        SendNUIMessage({
            action = 'nui:gasstation:visible',
            data = { visible = false }
        })

        local pumpCoords = nil
        if response.pumpCoords then
            pumpCoords = vector3(response.pumpCoords.x, response.pumpCoords.y, response.pumpCoords.z)
        else
            pumpCoords = PumpInteraction.GetCurrentPumpCoords()
        end

        TriggerEvent('fl_gasstation:beginFuelingProcess', {
            vehicleNetId = response.vehicleNetId,
            liters = response.liters,
            pumpCoords = pumpCoords
        })

        PumpInteraction.ClearCurrentPumpCoords()
        PumpInteraction.ClearCurrentVehicleNetId()
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            subtitle = 'Station Essence',
            message = response.message
        })
    end
end)

RegisterNetEvent('fl_gasstation:purchaseComplete', function(response)
    if response.success then
        VFW.ShowNotification({
            type = 'VERT',
            subtitle = 'Station Essence',
            message = response.message
        })

        if response.vehicleNetId and response.liters then
            local vehicle = NetworkGetEntityFromNetworkId(response.vehicleNetId)
            if vehicle and DoesEntityExist(vehicle) then
                VehicleFuel.AddLiters(vehicle, response.liters, true)
            end
        end

        gasStationOpen = false
        VFW.Nui.Focus(false)
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            subtitle = 'Station Essence',
            message = response.message
        })
    end
end)
