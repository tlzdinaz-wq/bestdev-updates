if MENTA_SERVER ~= 'FR' then return end

AddStateBagChangeHandler("siren", nil, function(bagName, key, value, reserved, replicated)
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

            if pending and pending.soundId then
                StopSound(pending.soundId)
                ReleaseSoundId(pending.soundId)
                pending.soundId = nil
                pending.siren = nil
            end

            return
        end
    end

    local vehicle = NetToVeh(netId)

    if not DoesEntityExist(vehicle) or IsEntityDead(vehicle) then
        return
    end

    if value then
        while not Entity(vehicle).state.siren do
            Wait(0)
        end

        local vehicleKey = tostring(netId)

        VehicleData[vehicleKey] = VehicleData[vehicleKey] or {}

        if VehicleData[vehicleKey].soundId and VehicleData[vehicleKey].siren == value then
            return
        end

        if VehicleData[vehicleKey].soundId then
            StopSound(VehicleData[vehicleKey].soundId)
            ReleaseSoundId(VehicleData[vehicleKey].soundId)
            VehicleData[vehicleKey].soundId = nil
            VehicleData[vehicleKey].siren = nil
        end

        local soundId = GetSoundId()
        local sound = GetVehicleServices(vehicle)

        if not sound then
            ReleaseSoundId(soundId)
            return
        end

        sound = sound .. value

        PlaySoundFromEntity(soundId, sound, vehicle, "sirens", false, 0)

        VehicleData[vehicleKey].siren = value
        VehicleData[vehicleKey].soundId = soundId

        while DoesEntityExist(vehicle) and not IsEntityDead(vehicle) and Entity(vehicle).state.siren do
            Wait(100)
        end

        if VehicleData[vehicleKey].soundId then
            StopSound(VehicleData[vehicleKey].soundId)
            ReleaseSoundId(VehicleData[vehicleKey].soundId)
        end

        VehicleData[vehicleKey].soundId = nil
        VehicleData[vehicleKey].siren = nil
    end
end)
