if MENTA_SERVER ~= 'FR' then return end

function GetVehicleServices(vehicle)
    for _, entry in ipairs(SirensConfig) do
        if GetHashKey(entry.model) == GetEntityModel(vehicle) then
            return entry.type
        end
    end

    return nil
end

function GetVehicleHorn(vehicle)
    for _, entry in ipairs(SirensConfig) do
        if GetHashKey(entry.model) == GetEntityModel(vehicle) then
            return entry.horn == 1 and "carhorn" or "truckhorn"
        end
    end

    return nil
end

function IsVehicleAllowed(vehicle)
    for _, entry in ipairs(SirensConfig) do
        if GetHashKey(entry.model) == GetEntityModel(vehicle) then
            return true
        end
    end

    return false
end

function IsPlayerIsInVehicle(vehicle, driverOnly)
    if GetVehiclePedIsIn(PlayerPedId(), false) == vehicle then
        if not driverOnly then
            if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() or GetPedInVehicleSeat(vehicle, 0) == PlayerPedId() then
                return true
            end
        else
            if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                return true
            end
        end
    end

    return false
end
