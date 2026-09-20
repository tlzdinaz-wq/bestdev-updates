if MENTA_SERVER ~= 'FR' then return end

AddStateBagChangeHandler("projector", nil, function(bagName, key, value, reserved, replicated)
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
        while not Entity(vehicle).state.projector do
            Wait(0)
        end

        for _, entry in ipairs(SirensConfig) do
            if GetHashKey(entry.model) == GetEntityModel(vehicle) then
                local projectorExtra = entry.extra[4]

                if projectorExtra then
                    SetVehicleExtra(vehicle, projectorExtra, false)
                    SetVehicleAutoRepairDisabled(vehicle, true)

                    if VehicleData[tostring(netId)] == nil then
                        VehicleData[tostring(netId)] = {}
                    end

                    VehicleData[tostring(netId)].projector = true

                    while DoesEntityExist(vehicle) and Entity(vehicle).state.projector do
                        Wait(100)
                    end

                    SetVehicleExtra(vehicle, projectorExtra, true)
                    SetVehicleAutoRepairDisabled(vehicle, true)

                    if VehicleData[tostring(netId)] == nil then
                        VehicleData[tostring(netId)] = {}
                    end

                    VehicleData[tostring(netId)].projector = nil

                    return true
                end
            end
        end
    end

    return false
end)
