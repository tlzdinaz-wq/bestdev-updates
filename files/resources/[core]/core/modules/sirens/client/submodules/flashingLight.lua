if MENTA_SERVER ~= 'FR' then return end

AddStateBagChangeHandler("flashingLight", nil, function(bagName, key, value, reserved, replicated)
    local netIdText = bagName:gsub("entity:", "")
    local netId = tonumber(netIdText)

    if not netId then
        return false
    end

    local timeout = GetGameTimer() + 1000

    while not (NetworkDoesNetworkIdExist(netId) and NetworkDoesEntityExistWithNetworkId(netId)) do
        Wait(0)

        if timeout <= GetGameTimer() then
            return
        end
    end

    local vehicle = NetworkGetEntityFromNetworkId(netId)

    if not DoesEntityExist(vehicle) then
        return
    end

    if replicated then
        return
    end

    if value then
        while not Entity(vehicle).state.flashingLight do
            Wait(0)
        end

        SetVehicleSiren(vehicle, true)
        DisableVehicleImpactExplosionActivation(vehicle, true)

        if VehicleData[tostring(netId)] == nil then
            VehicleData[tostring(netId)] = {}
        end

        VehicleData[tostring(netId)].flashingLight = true

        while DoesEntityExist(vehicle) and Entity(vehicle).state.flashingLight do
            SetVehicleHasMutedSirens(vehicle, true)
            Wait(100)
        end

        SetVehicleSiren(vehicle, false)
        DisableVehicleImpactExplosionActivation(vehicle, true)
        Entity(vehicle).state:set("siren", false, true)

        if VehicleData[tostring(netId)] == nil then
            VehicleData[tostring(netId)] = {}
        end

        VehicleData[tostring(netId)].flashingLight = nil

        return true
    end
end)
