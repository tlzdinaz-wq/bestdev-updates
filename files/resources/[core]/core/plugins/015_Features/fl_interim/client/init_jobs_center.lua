RegisterNetEvent("interim:receiveJobsCenterConfig", function(config)
    InterimJobsCenterConfig = config
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent("interim:requestJobsCenterConfig")
end)