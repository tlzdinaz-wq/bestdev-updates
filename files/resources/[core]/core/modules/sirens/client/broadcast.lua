if MENTA_SERVER ~= 'FR' then return end

RegisterNetEvent("nui:update:siren", function(netId, state, sirenId)
    local timeout = GetGameTimer() + 1000

    while not (NetworkDoesNetworkIdExist(netId) and NetworkDoesEntityExistWithNetworkId(netId)) do
        Wait(0)

        if timeout <= GetGameTimer() then
            return
        end
    end

    if PlayerPedId() ~= NetworkGetEntityFromNetworkId(netId) then
        return
    end

    NuiSound()
    NuiSiren(state)

    if state and sirenId == "02" then
        NuiNightSiren(true)
    else
        NuiNightSiren(false)
    end
end)

RegisterNetEvent("nui:update:flashingLight", function(netId, state)
    local timeout = GetGameTimer() + 1000

    while not (NetworkDoesNetworkIdExist(netId) and NetworkDoesEntityExistWithNetworkId(netId)) do
        Wait(0)

        if timeout <= GetGameTimer() then
            return
        end
    end

    if PlayerPedId() ~= NetworkGetEntityFromNetworkId(netId) then
        return
    end

    NuiSound()
    NuiFlashingLight(state)

    if not state then
        NuiNightSiren(false)
    end

    if not state then
        NuiSiren(state)
    end
end)

RegisterNetEvent("nui:update:extra", function(netId, state, extraSlot)
    local timeout = GetGameTimer() + 1000

    while not (NetworkDoesNetworkIdExist(netId) and NetworkDoesEntityExistWithNetworkId(netId)) do
        Wait(0)

        if timeout <= GetGameTimer() then
            return
        end
    end

    if PlayerPedId() ~= NetworkGetEntityFromNetworkId(netId) then
        return
    end

    NuiSound()

    if state then
        if extraSlot == 1 then
            NuiBanisterLeft(true)
            NuiBanisterCenter(false)
            NuiBanisterRight(false)
        elseif extraSlot == 2 then
            NuiBanisterLeft(false)
            NuiBanisterCenter(true)
            NuiBanisterRight(false)
        elseif extraSlot == 3 then
            NuiBanisterLeft(false)
            NuiBanisterCenter(false)
            NuiBanisterRight(true)
        end
    else
        NuiBanisterLeft(false)
        NuiBanisterCenter(false)
        NuiBanisterRight(false)
    end
end)

RegisterNetEvent("nui:update:projector", function(netId, state)
    local timeout = GetGameTimer() + 1000

    while not (NetworkDoesNetworkIdExist(netId) and NetworkDoesEntityExistWithNetworkId(netId)) do
        Wait(0)

        if timeout <= GetGameTimer() then
            return
        end
    end

    if PlayerPedId() ~= NetworkGetEntityFromNetworkId(netId) then
        return
    end

    NuiSound()
    NuiLight(state)
end)
