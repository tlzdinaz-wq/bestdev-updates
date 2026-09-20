---@meta _
---@diagnostic disable: duplicate-doc-field

local isOpen = false

RegisterNuiCallback("notificationCreateSociety_callback", function(data)
    if not isOpen then
        return
    end

    if VFW.PlayerData.job.label ~= data.name_entreprise_notif then
        return
    end

    if not VFW.PlayerData.job.onDuty then
        return
    end

    if not data.choiceType_notif or not data.message_notif or not data.telephone_notif then
        return VFW.ShowNotification({type = "ROUGE", content = "Veuillez remplir tout les champs !"})
    end

    TriggerServerEvent("core:server:announceEntreprise:sendData", data)
end)

VFW.Nui.AnnounceEntreprise = function(visible)
    isOpen = visible
    if visible then 
        SendNUIMessage({
            action = "nui:CardNewsSocietyCreate:data",
            data = {
                name_society = VFW.PlayerData.job.label,
                logo_society = VFW.CDN.Get("hud/notifications/" .. VFW.PlayerData.job.name .. ".webp"),
                preset = preset
            }
        })
    end

    SendNUIMessage({
        action = "nui:CardNewsSocietyCreate:visible",
        data = visible
    })
    VFW.Nui.Focus(visible)
end

RegisterNuiCallback("nui:CardNewsSocietyCreate:close", function()
    VFW.Nui.AnnounceEntreprise(false)
end)
