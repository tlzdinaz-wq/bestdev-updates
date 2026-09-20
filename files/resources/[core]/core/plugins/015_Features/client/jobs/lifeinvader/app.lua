---@meta _
---@diagnostic disable: duplicate-doc-field

-- =====================
-- LifeInvader APP (lb-phone)
-- =====================

local function SendReactMessage(event, data)
    exports["lb-phone"]:SendCustomAppMessage("lifeinvader-live", {
        action = event,
        data = data
    })
end

-- Live viewing state (no camera takeover — game render mirrors the player's own view like lb-phone calls)
local isWatchingLive = false

local broadcastVoiceOverrides = {} -- serverId -> true (viewer side: track volume overrides)
local broadcastViewerIds = {} -- viewerId -> true (journalist side: track viewers)

local function ClearAllBroadcastVoiceOverrides()
    for serverId, _ in pairs(broadcastVoiceOverrides) do
        MumbleSetVolumeOverrideByServerId(serverId, -1.0)
    end
    broadcastVoiceOverrides = {}
end

local function StopWatchingLive()
    if not isWatchingLive then return end
    isWatchingLive = false
    ClearAllBroadcastVoiceOverrides()
    TriggerServerEvent("lifeinvader-app:webrtc:stopWatching")
end

-- Register custom app on lb-phone
local appConfig = {
    identifier = "lifeinvader-live",
    name = "LifeInvader",
    description = "Flash infos et direct camera LifeInvader",
    developer = "LifeInvader Inc.",
    defaultApp = true,
    size = 4200,
    icon = "https://cfx-nui-core/plugins/015_Features/ui/lifeinvader/icon.png",
    ui = "https://cfx-nui-core/plugins/015_Features/ui/lifeinvader/index.html",
    keepOpen = true, -- Keep iframe alive for WebRTC capture even when app is in background
    fixBlur = true,
}

local function RegisterLifeInvaderApp()
    local ok, added
    for attempt = 1, 5 do
        ok, added = pcall(exports["lb-phone"].AddCustomApp, exports["lb-phone"], appConfig)
        if ok and added then break end
        Wait(2000)
    end

    if not ok or not added then return end
end

CreateThread(function()
    while not VFW.PlayerLoaded do
        Wait(500)
    end

    local waited = 0
    while GetResourceState("lb-phone") ~= "started" do
        waited = waited + 1
        if waited > 60 then return end
        Wait(500)
    end

    Wait(2000)
    RegisterLifeInvaderApp()
end)

-- Re-register when lb-phone restarts (ensure lb-phone)
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= "lb-phone" then return end
    Wait(2000)
    RegisterLifeInvaderApp()
end)

-- =====================
-- WebRTC Capture via main NUI (LifeInvaderCapture React component)
-- =====================
local isCapturing = false

-- Receive WebRTC signals from NUI (LifeInvaderCapture component)
RegisterNUICallback("lifeinvader:captureSignal", function(data, cb)
    if data.action == "webrtcSignal" then
        TriggerServerEvent("lifeinvader-app:webrtc:signal", {
            target = data.target,
            type = data.type,
            data = data.data
        })
    end
    cb({ ok = true })
end)

-- Refresh full feed (e.g. after staff deletes an announcement)
RegisterNetEvent("lifeinvader-app:client:refreshFeed", function(newsList)
    SendReactMessage("refreshFeed", newsList)
end)

-- Receive new news from server
RegisterNetEvent("lifeinvader-app:client:newNews", function(newsItem)
    SendReactMessage("newNews", newsItem)
end)

-- =====================
-- BROADCAST VOICE (MumbleAddVoiceTargetPlayerByServerId)
-- Journalist + nearby players target viewers directly (works at any distance)
-- Viewers set volume overrides to hear them
-- No conflict with phone calls or radio
-- =====================

local voiceTarget = GetConvarInt('voice_defaultVoiceTarget', 1)

-- Journalist: server tells us about viewers
RegisterNetEvent("lifeinvader-app:client:addBroadcastViewer", function(viewerId)
    broadcastViewerIds[viewerId] = true
    MumbleAddVoiceTargetPlayerByServerId(voiceTarget, viewerId)
end)

RegisterNetEvent("lifeinvader-app:client:removeBroadcastViewer", function(viewerId)
    broadcastViewerIds[viewerId] = nil
end)

RegisterNetEvent("lifeinvader-app:client:clearBroadcastViewers", function()
    broadcastViewerIds = {}
end)

-- Any player near journalist: server tells us to target broadcast viewers
RegisterNetEvent("lifeinvader-app:client:setBroadcastTargets", function(viewerIds)
    for _, viewerId in ipairs(viewerIds) do
        MumbleAddVoiceTargetPlayerByServerId(voiceTarget, viewerId)
    end
end)

-- Any player near journalist: server tells us broadcast ended, clear player targets
RegisterNetEvent("lifeinvader-app:client:clearBroadcastTargets", function()
    MumbleClearVoiceTargetPlayers(voiceTarget)
end)

-- Viewer: set volume override to hear journalist
RegisterNetEvent("lifeinvader-app:client:listenBroadcast", function(journalistServerId)
    broadcastVoiceOverrides[journalistServerId] = true
    MumbleSetVolumeOverrideByServerId(journalistServerId, 1.0)
end)

RegisterNetEvent("lifeinvader-app:client:stopListenBroadcast", function()
    ClearAllBroadcastVoiceOverrides()
end)

-- Viewer: update volume overrides for journalist + nearby players
RegisterNetEvent("lifeinvader-app:client:updateBroadcastVoices", function(serverIds)
    if not isWatchingLive then return end

    local wantedIds = {}
    for _, serverId in ipairs(serverIds) do
        wantedIds[serverId] = true
        if not broadcastVoiceOverrides[serverId] then
            broadcastVoiceOverrides[serverId] = true
            MumbleSetVolumeOverrideByServerId(serverId, 1.0)
        end
    end

    -- Remove overrides for players no longer in broadcast
    for serverId, _ in pairs(broadcastVoiceOverrides) do
        if not wantedIds[serverId] then
            MumbleSetVolumeOverrideByServerId(serverId, -1.0)
            broadcastVoiceOverrides[serverId] = nil
        end
    end
end)

-- Camera started
RegisterNetEvent("lifeinvader-app:client:cameraStart", function(data)
    SendReactMessage("cameraStart", data)

    exports["lb-phone"]:SendNotification({
        app = "lifeinvader-live",
        title = "Direct en cours",
        content = (data.name or "Un journaliste") .. " est en direct !",
    })
end)

-- Camera position update
RegisterNetEvent("lifeinvader-app:client:cameraUpdate", function(data)
    SendReactMessage("cameraUpdate", data)
end)

-- WebRTC: Server tells journalist to start/stop capture (via main NUI)
local NEARBY_VOICE_RANGE = 15.0

RegisterNetEvent("lifeinvader-app:client:startCapture", function()
    isCapturing = true
    SendNUIMessage({ action = "lifeinvader:startCapture" })

    -- Periodically send nearby player IDs and re-add viewer voice targets
    CreateThread(function()
        while isCapturing do
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            local nearbyIds = {}
            for _, playerId in ipairs(GetActivePlayers()) do
                if playerId ~= PlayerId() then
                    local targetPed = GetPlayerPed(playerId)
                    if targetPed and targetPed ~= 0 then
                        if #(myCoords - GetEntityCoords(targetPed)) <= NEARBY_VOICE_RANGE then
                            nearbyIds[#nearbyIds + 1] = GetPlayerServerId(playerId)
                        end
                    end
                end
            end
            TriggerServerEvent("lifeinvader-app:broadcast:nearbyPlayers", nearbyIds)

            -- Re-add viewer voice targets (survives any clears from pma-voice)
            for viewerId, _ in pairs(broadcastViewerIds) do
                MumbleAddVoiceTargetPlayerByServerId(voiceTarget, viewerId)
            end

            Wait(1000)
        end
    end)
end)

RegisterNetEvent("lifeinvader-app:client:stopCapture", function()
    isCapturing = false
    broadcastViewerIds = {}
    MumbleClearVoiceTargetPlayers(voiceTarget)
    SendNUIMessage({ action = "lifeinvader:stopCapture" })
end)

-- WebRTC: Server tells journalist a viewer wants to watch (send to NUI)
RegisterNetEvent("lifeinvader-app:client:viewerRequest", function(data)
    if isCapturing then
        SendNUIMessage({ action = "lifeinvader:viewerRequest", data = { viewerId = data.viewerId } })
    end
end)

-- WebRTC: Receive signaling data from server
-- Route to main NUI (journalist/sender) or to lb-phone app (viewer)
RegisterNetEvent("lifeinvader-app:client:webrtcSignal", function(data)
    if isCapturing and (data.type == "answer" or data.type == "ice") then
        -- Journalist receiving answer/ICE from viewer → send to NUI capture component
        SendNUIMessage({
            action = "lifeinvader:webrtcSignal",
            data = {
                type = data.type,
                from = data.from,
                data = data.data
            }
        })
    else
        -- Viewer receiving offer/ICE from journalist → send to lb-phone app
        SendReactMessage("webrtcSignal", data)
    end
end)

-- Camera stopped
RegisterNetEvent("lifeinvader-app:client:cameraStop", function()
    SendReactMessage("cameraStop", {})

    if isCapturing then
        isCapturing = false
        SendNUIMessage({ action = "lifeinvader:stopCapture" })
    end

    if isWatchingLive then
        StopWatchingLive()
    end
end)

-- Also cleanup if resource stops
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == "lb-phone" or resourceName == "pma-voice" or resourceName == GetCurrentResourceName() then
        if isCapturing then
            isCapturing = false
            SendNUIMessage({ action = "lifeinvader:stopCapture" })
        end
        if isWatchingLive then
            StopWatchingLive()
        end
    end
end)

-- NUI Callbacks (lb-phone app)
RegisterNUICallback("getRecentNews", function(_, cb)
    local news = TriggerServerCallback("lifeinvader-app:getRecentNews")
    cb(news or {})
end)

RegisterNUICallback("getActiveCamera", function(_, cb)
    local camera = TriggerServerCallback("lifeinvader-app:getActiveCamera")
    cb(camera)
end)

RegisterNUICallback("startWatchingLive", function(_, cb)
    if isWatchingLive then
        cb({ ok = true })
        return
    end

    local camera = TriggerServerCallback("lifeinvader-app:getActiveCamera")

    if not camera then
        cb({ ok = false, error = "Aucun direct en cours" })
        return
    end

    isWatchingLive = true
    TriggerServerEvent("lifeinvader-app:webrtc:requestStream")
    cb({ ok = true })
end)

RegisterNUICallback("stopWatchingLive", function(_, cb)
    StopWatchingLive()
    cb({ ok = true })
end)

RegisterNUICallback("isWatchingLive", function(_, cb)
    cb({ watching = isWatchingLive })
end)

-- WebRTC: NUI sends signaling data to server
RegisterNUICallback("webrtcSignal", function(data, cb)
    TriggerServerEvent("lifeinvader-app:webrtc:signal", data)
    cb({ ok = true })
end)


-- =====================
-- BROADCAST OVERLAY
-- =====================

local isBroadcasting = false

function ShowLifeInvaderOverlay(subtitle)
    isBroadcasting = true
    VFW.Nui.HudVisible(false)
    SendNUIMessage({
        action = "lifeinvader:showOverlay",
        data = {
            subtitle = subtitle or "Suivez l'actu EN DIRECT de LifeInvader"
        }
    })
end

function HideLifeInvaderOverlay()
    isBroadcasting = false
    VFW.Nui.HudVisible(true)
    SendNUIMessage({
        action = "lifeinvader:hideOverlay",
        data = {}
    })
end

function UpdateLifeInvaderSubtitle(subtitle)
    if isBroadcasting then
        SendNUIMessage({
            action = "lifeinvader:updateSubtitle",
            data = {
                subtitle = subtitle
            }
        })
    end
end

-- NUI callback for closing overlay via ESC
RegisterNUICallback("closeOverlay", function(_, cb)
    cb({ ok = true })
end)
