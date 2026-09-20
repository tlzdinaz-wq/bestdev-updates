if MENTA_SERVER ~= 'FR' then return end

AddStateBagChangeHandler("extra", nil, function(bagName, key, value, reserved, replicated)
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
        while not Entity(vehicle).state.extra do
            Wait(0)
        end

        for _, entry in ipairs(SirensConfig) do
            if GetHashKey(entry.model) == GetEntityModel(vehicle) then
                local banisters = {
                    [1] = entry.extra[1] or nil,
                    [2] = entry.extra[2] or nil,
                    [3] = entry.extra[3] or nil
                }

                local target = banisters[value]

                if target then
                    SetVehicleExtra(vehicle, banisters[1], true)
                    SetVehicleExtra(vehicle, banisters[2], true)
                    SetVehicleExtra(vehicle, banisters[3], true)
                    SetVehicleExtra(vehicle, target, false)
                    SetVehicleAutoRepairDisabled(vehicle, true)

                    if VehicleData[tostring(netId)] == nil then
                        VehicleData[tostring(netId)] = {}
                    end

                    VehicleData[tostring(netId)].extra = value

                    while DoesEntityExist(vehicle) and Entity(vehicle).state.extra do
                        Wait(100)
                    end

                    SetVehicleExtra(vehicle, target, true)
                    SetVehicleAutoRepairDisabled(vehicle, true)

                    if VehicleData[tostring(netId)] == nil then
                        VehicleData[tostring(netId)] = {}
                    end

                    VehicleData[tostring(netId)].extra = nil

                    return true
                end
            end
        end
    end

    return false
end)
