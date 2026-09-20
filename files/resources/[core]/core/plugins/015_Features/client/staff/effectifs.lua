---@meta _
---@diagnostic disable: duplicate-doc-field

local effectifsOpen = false

local function CloseEffectifs()
    if not effectifsOpen then return end
    effectifsOpen = false
    SendNUIMessage({ action = "nui:effectifs:close" })
    VFW.Nui.Focus(false)
end

RegisterNUICallback("effectifs:close", function(_, cb)
    CloseEffectifs()
    cb("ok")
end)

RegisterCommand("checkJob", function()
    if not VFW.PlayerGlobalData or not VFW.PlayerGlobalData.permissions or not VFW.PlayerGlobalData.permissions["check_effectifs"] then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas la permission d'utiliser cette commande." })
        return
    end
    if effectifsOpen then return end

    local data = TriggerServerCallback("vfw:staff:checkJob")
    if not data then
        VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de récupérer les effectifs." })
        return
    end

    effectifsOpen = true
    SendNUIMessage({ action = "nui:effectifs:open", data = { type = "job", items = data } })
    VFW.Nui.Focus(true)
end)

RegisterCommand("checkFaction", function()
    if not VFW.PlayerGlobalData or not VFW.PlayerGlobalData.permissions or not VFW.PlayerGlobalData.permissions["check_effectifs"] then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas la permission d'utiliser cette commande." })
        return
    end
    if effectifsOpen then return end

    local data = TriggerServerCallback("vfw:staff:checkFaction")
    if not data then
        VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de récupérer les effectifs." })
        return
    end

    effectifsOpen = true
    SendNUIMessage({ action = "nui:effectifs:open", data = { type = "faction", items = data } })
    VFW.Nui.Focus(true)
end)

VFW.AddChatSuggestions({
    {name = '/checkJob', help = 'Consulter les effectifs des jobs'},
    {name = '/checkFaction', help = 'Consulter les effectifs des factions'},
})
