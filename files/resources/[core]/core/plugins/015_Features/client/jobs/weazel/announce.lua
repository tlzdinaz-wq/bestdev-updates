---@meta _
---@diagnostic disable: duplicate-doc-field

local isOpen = false
weazelImage = ""

-- Le relay vers weazel-app:newBroadcast est fait directement côté serveur (announce.lua server)
-- pour éviter que chaque client connecté re-trigger l'event (N fois au lieu de 1)

-- Receive broadcast announcement from server (all players)
-- La notification JOB est déjà envoyée par le serveur via BroadcastWeazelJobNotification
RegisterNetEvent("core:weazel:sendAnnounceAll")
AddEventHandler("core:weazel:sendAnnounceAll", function(data)
end)

-- JT event: receive an array of announcements
RegisterNetEvent("core:weazel:sendJT")
AddEventHandler("core:weazel:sendJT", function(announcements)
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

RegisterNUICallback("CreateWeazelNews", function(data)
    if VFW.PlayerData.job.name ~= "weazelnews" then
        return
    end

    data.isInPreview = false

    if IsWaypointActive() then
        data.position = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
    else
        data.position = GetEntityCoords(PlayerPedId())
    end

    VFW.ClearPreview()

    TriggerServerEvent("core:weazel:sendAnnounce", data)
end)

RegisterNuiCallback("PreviewWeazelNews", function(data, cb)
    if VFW.PlayerData.job.name ~= "weazelnews" then
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
        title = "Weazel News",
        subtitle = subtitle,
        subtitleColor = subtitleColor,
        image = weazelImage,
        content = content,
        duration = 10,
    })
    cb({ ok = true })
end)

VFW.Nui.AnnounceWeazel = function(visible)
    if visible then
        SendNUIMessage({
            action = "nui:weazelNewsAnnouncement:data",
            data = {
                job = VFW.PlayerData.job.name,
            }
        })
    end

    SendNUIMessage({
        action = "nui:weazelNewsAnnouncement:visible",
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

--- OpenMenuAnnonceWeazel
function OpenMenuAnnonceWeazel()
    VFW.Nui.AnnounceWeazel(true)
end

RegisterNuiCallback("nui:closeWeazelNewsAnnouncement", function()
    VFW.Nui.AnnounceWeazel(false)
    isOpen = false
    VFW.ClearPreview()
end)

-- CRUD NUI callbacks for WeazelNewsPanel

RegisterNUICallback("weazel:create", function(data, cb)
    local result = TriggerServerCallback("weazel:createAnnouncement", data)
    cb(result)
end)

RegisterNUICallback("weazel:update", function(data, cb)
    local result = TriggerServerCallback("weazel:updateAnnouncement", data.id, data)
    cb(result)
end)

RegisterNUICallback("weazel:delete", function(data, cb)
    local result = TriggerServerCallback("weazel:deleteAnnouncement", data.id)
    cb(result)
end)

RegisterNUICallback("weazel:markBroadcasted", function(data, cb)
    local result = TriggerServerCallback("weazel:markBroadcasted", data.id)
    cb(result)
end)
