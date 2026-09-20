local lastCoreHeartbeat = 0
local heartbeatSeen = false

AddEventHandler('esx_ambulancejobIsPlayerInLife', function()
    lastCoreHeartbeat = GetGameTimer()
    heartbeatSeen = true
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(1000)
    end

    local bootDeadline = GetGameTimer() + 120000

    while not heartbeatSeen do
        if GetGameTimer() > bootDeadline then
            TriggerServerEvent('esx_ambulanceJob:playerNowDead', 'core')
            return
        end

        Wait(1000)
    end

    while true do
        Wait(5000)

        local now = GetGameTimer()
        if (now - lastCoreHeartbeat) > 15000 then
            TriggerServerEvent('esx_ambulanceJob:playerNowDead', 'core')
            return
        end
    end
end)
