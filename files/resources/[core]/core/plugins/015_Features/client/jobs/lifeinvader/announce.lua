---@meta _
---@diagnostic disable: duplicate-doc-field

local isOpen = false
lifeinvaderImage = ""

-- Le relay vers lifeinvader-app:newBroadcast est fait directement côté serveur (announce.lua server)
-- pour éviter que chaque client connecté re-trigger l'event (N fois au lieu de 1)

-- Receive broadcast announcement from server (all players)
-- La notification JOB est déjà envoyée par le serveur via BroadcastLifeInvaderJobNotification
RegisterNetEvent("core:lifeinvader:sendAnnounceAll")
AddEventHandler("core:lifeinvader:sendAnnounceAll", function(data)
end)

-- JT event: receive an array of announcements
RegisterNetEvent("core:lifeinvader:sendJT")
AddEventHandler("core:lifeinvader:sendJT", function(announcements)
    if not announcements or #announcements == 0 then
        return
    end

    local jtData = {}
    for i, data in ipairs(announcements) do
        table.insert(jtData, {
            type = "JOB",
            category = data.type or "news",
            media = data.media or "image",
            media_url = data.media_url or "",
            buttons = data.buttons or {},
            preview = false,
            format = data.format or "breaking",
            title = data.title,
            content = data.content,
            jtIndex = i,
            jtTotal = #announcements,
        })
    end

    SendNUIMessage({
        action = "nui:hud:create-jt",
        data = jtData
    })
end)

RegisterNUICallback("CreateLifeInvader", function(data)
    if not VFW.PlayerData.job or VFW.PlayerData.job.name ~= "lifeinvader" then
        return
    end

    data.isInPreview = false

    if IsWaypointActive() then
        data.position = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
    else
        data.position = GetEntityCoords(PlayerPedId())
    end

    VFW.ClearPreview()

    TriggerServerEvent("core:lifeinvader:sendAnnounce", data)
end)

RegisterNuiCallback("PreviewLifeInvader", function(data, cb)
    if not VFW.PlayerData.job or VFW.PlayerData.job.name ~= "lifeinvader" then
        cb({ ok = false })
        return
    end

    local subtitle = data.format == "flash" and "FLASH INFO" or "BREAKING NEWS"
    local subtitleColor = data.format == "flash" and "#e03030" or "#e8a820"
    local announceTitle = data.title or ""
    local content = announceTitle
    if data.content and data.content ~= "" then
        content = content .. "\n" .. data.content
    end

    VFW.ShowNotification({
        type = "JOB",
        title = "LifeInvader",
        subtitle = subtitle,
        subtitleColor = subtitleColor,
        image = lifeinvaderImage,
        content = content,
        duration = 10,
    })
    cb({ ok = true })
end)

VFW.Nui.AnnounceLifeInvader = function(visible)
    if visible then
        SendNUIMessage({
            action = "nui:lifeinvaderAnnouncement:data",
            data = {
                job = VFW.PlayerData.job.name,
            }
        })
    end

    SendNUIMessage({
        action = "nui:lifeinvaderAnnouncement:visible",
        data = visible
    })

    VFW.Nui.Focus(visible)
    isOpen = visible

    if visible then
        CreateThread(function()
            while isOpen do
                DisableControlAction(0, 245, true) -- T (chat)
                Wait(0)
            end
        end)
    end
end

--- OpenMenuAnnonceLifeInvader
function OpenMenuAnnonceLifeInvader()
    VFW.Nui.AnnounceLifeInvader(true)
end

RegisterNuiCallback("nui:closeLifeInvaderAnnouncement", function()
    VFW.Nui.AnnounceLifeInvader(false)
    isOpen = false
    VFW.ClearPreview()
end)

-- CRUD NUI callbacks for lifeinvaderPanel

RegisterNUICallback("lifeinvader:create", function(data, cb)
    local result = TriggerServerCallback("lifeinvader:createAnnouncement", data)
    cb(result)
end)

RegisterNUICallback("lifeinvader:update", function(data, cb)
    local result = TriggerServerCallback("lifeinvader:updateAnnouncement", data.id, data)
    cb(result)
end)

RegisterNUICallback("lifeinvader:delete", function(data, cb)
    local result = TriggerServerCallback("lifeinvader:deleteAnnouncement", data.id)
    cb(result)
end)

RegisterNUICallback("lifeinvader:markBroadcasted", function(data, cb)
    local result = TriggerServerCallback("lifeinvader:markBroadcasted", data.id)
    cb(result)
end)
