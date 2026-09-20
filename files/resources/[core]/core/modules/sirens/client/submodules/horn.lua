if MENTA_SERVER ~= 'FR' then return end

AddStateBagChangeHandler("horn", nil, function(bagName, key, value, reserved, replicated)
    local netIdText = bagName:gsub("entity:", "")
    local netId = tonumber(netIdText)

    if not netId then
        return
    end

    local timeout = GetGameTimer() + 1000

    while not (NetworkDoesNetworkIdExist(netId) and NetworkDoesEntityExistWithNetworkId(netId)) do
        Wait(0)

        if timeout < GetGameTimer() then
            local pending = VehicleData[tostring(netId)]

            if pending and pending.horn then
                StopSound(pending.horn)
                ReleaseSoundId(pending.horn)
                pending.horn = nil
            end

            return
        end
    end

    local vehicle = NetToVeh(netId)

    if not DoesEntityExist(vehicle) or IsEntityDead(vehicle) then
        return
    end

    local vehicleKey = tostring(netId)

    VehicleData[vehicleKey] = VehicleData[vehicleKey] or {}

    local data = VehicleData[vehicleKey]

    if not value then
        if data.horn then
            StopSound(data.horn)
            ReleaseSoundId(data.horn)
            data.horn = nil
        end

        return
    end

    while not Entity(vehicle).state.horn do
        Wait(0)
    end

    if data.horn and data.lastValue == value then
        return
    end

    if data.horn then
        StopSound(data.horn)
        ReleaseSoundId(data.horn)
        data.horn = nil
    end

    local soundId = GetSoundId()
    local sound = GetVehicleHorn(vehicle)

    if not sound then
        ReleaseSoundId(soundId)
        return
    end

    PlaySoundFromEntity(soundId, sound, vehicle, "sirens", false, 0)

    data.horn = soundId
    data.lastValue = value

    while DoesEntityExist(vehicle) and not IsEntityDead(vehicle) and Entity(vehicle).state.horn do
        Wait(100)
    end

    if data.horn then
        StopSound(data.horn)
        ReleaseSoundId(data.horn)
        data.horn = nil
    end

    data.lastValue = nil
end)
