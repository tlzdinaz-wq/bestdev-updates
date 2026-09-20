local blips = {}

CreateThread(function()
    -- Récupérer la config depuis le serveur
    local jobCenterConfig = TriggerServerCallback("interim:getJobCenterConfig")

    if not jobCenterConfig or not jobCenterConfig.npcs then
        return
    end

    local npcs = jobCenterConfig.npcs

    for i, config in ipairs(npcs) do
        SpawnNpcsInterimJobs(
            config.model,
            config.coords,
            config.heading,
            config.label,
            function()
                TriggerServerEvent("interimjobscenter:requestData")
            end
        )

        if config.blip.enabled then
            local blip = AddBlipForCoord(config.coords.x, config.coords.y, config.coords.z)
            SetBlipSprite(blip, config.blip.sprite)
            SetBlipScale(blip, config.blip.scale)
            SetBlipColour(blip, config.blip.color)
            SetBlipDisplay(blip, 4)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(config.blip.name)
            EndTextCommandSetBlipName(blip)
            table.insert(blips, blip)
        end
    end
end)

RegisterNetEvent("nui:interimjobscenter:open", function(data)
    VFW.Nui.Focus(true)

    SendNUIMessage({
        action = "nui:interimjobscenter:open",
        data = data
    })
end)

RegisterNetEvent("nui:interimjobscenter:close", function()
    VFW.Nui.Focus(false)
    SendNUIMessage({
        action = "nui:interimjobscenter:close"
    })
end)

RegisterNUICallback("interimjobscenter:close", function(data, cb)
    VFW.Nui.Focus(false)
    cb("ok")
end)

RegisterNUICallback("interimjobscenter:markLocation", function(data, cb)
    TriggerServerEvent("interimjobscenter:markLocation", data)
    cb("ok")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, blip in ipairs(blips) do
            RemoveBlip(blip)
        end
    end
end)
