---@meta _
---@diagnostic disable: duplicate-doc-field

-- Callback pour récupérer la config du crash d'avion
RegisterNUICallback("nui:server-gestion-illegal:getPlaneCrash", function(data, cb)
    console.debug("nui:server-gestion-illegal:getPlaneCrash called")
    local config = TriggerServerCallback("core:planecrash:getConfig")

    if config then
        SendNUIMessage({
            action = "nui:server-gestion-illegal:setPlaneCrash",
            data = config
        })
    end

    cb("ok")
end)

-- Callback pour sauvegarder la config du crash d'avion
RegisterNUICallback("nui:server-gestion-illegal:sendPlaneCrash", function(data, cb)
    console.debug("nui:server-gestion-illegal:sendPlaneCrash", json.encode(data, {indent = true}))
    TriggerServerEvent("core:planecrash:saveConfig", data)
    cb("ok")
end)

-- Callback pour reset le cooldown de l'ATC
RegisterNUICallback("nui:server-gestion-illegal:resetAtcCooldown", function(data, cb)
    console.debug("nui:server-gestion-illegal:resetAtcCooldown called")
    TriggerServerEvent("core:planecrash:resetAtcCooldown")
    cb("ok")
end)

-- Callback pour récupérer la config du loot
RegisterNUICallback("nui:server-gestion-illegal:getLootConfig", function(data, cb)
    console.debug("nui:server-gestion-illegal:getLootConfig called")
    local lootConfig = TriggerServerCallback("core:planecrash:getLootConfig")

    if lootConfig then
        SendNUIMessage({
            action = "nui:server-gestion-illegal:setLootConfig",
            data = lootConfig
        })
    end

    cb("ok")
end)

-- Callback pour sauvegarder la config du loot
RegisterNUICallback("nui:server-gestion-illegal:saveLootConfig", function(data, cb)
    console.debug("nui:server-gestion-illegal:saveLootConfig", json.encode(data, {indent = true}))
    TriggerServerEvent("core:planecrash:saveLootConfig", data)

    -- Recharger la config après sauvegarde
    SetTimeout(500, function()
        local lootConfig = TriggerServerCallback("core:planecrash:getLootConfig")
        if lootConfig then
            SendNUIMessage({
                action = "nui:server-gestion-illegal:setLootConfig",
                data = lootConfig
            })
        end
    end)

    cb("ok")
end)
