---@meta _
---@diagnostic disable: duplicate-doc-field

-- Video Menu Data (accessible via StaffMenu pour affichage dans global.lua)
StaffMenu.videoData = StaffMenu.videoData or {
    videoLink = nil,
    targetType = 1, -- 1 = Player, 2 = Zone, 3 = All
    targetInfo = nil,
    placementType = 2, -- 1 = Fullscreen, 2 = Top right
}
local videoData = StaffMenu.videoData

-- Target Type Enum
local TargetType = {
    PLAYER = 1,
    ZONE = 2,
    SERVER = 3
}

-- Placement Type Enum
local PlacementType = {
    FULLSCREEN = 1,
    TOP_RIGHT = 2
}

-- Build Video Management Menu
function StaffMenu.BuildVideoManagementMenu()
    StaffMenu.videoManagement.Separator(":film: CONFIGURATION VIDÉO")

    -- Video link input with dynamic display
    local linkDisplay = "Non défini"
  if videoData.videoLink then
        -- Truncate long URLs for display
        if string.len(videoData.videoLink) > 30 then
            linkDisplay = string.sub(videoData.videoLink, 1, 27) .. "..."
      else
            linkDisplay = videoData.videoLink
        end
    end

    StaffMenu.videoManagement.Button(":chat: LIEN VIDÉO", linkDisplay, nil, "chevron", false, function()
        StaffMenu.videoManagement.close()
        Wait(200)
        local videoUrl = VFW.Nui.KeyboardInput(true, "Lien YouTube (youtube.com ou youtu.be)", "")

        if videoUrl and videoUrl ~= "" then
            if string.find(videoUrl, "youtube.com") or string.find(videoUrl, "youtu.be") then
                videoData.videoLink = videoUrl
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Vidéos',
                    message = "Lien vidéo défini."
              })
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Vidéos',
                    message = "Ce lien n'est pas valide, utilisez YouTube uniquement."
              })
            end
        end
        Wait(200)
        StaffMenu.videoManagement.open()
    end)

    -- Target type selection
    local targetTypes = {"Joueur", "Zone", "Tous"}
    StaffMenu.videoManagement.List(":target: Cible", nil, false, targetTypes, videoData.targetType, function(index, item)
        videoData.targetType = index
        videoData.targetInfo = nil -- Reset target info when changing type

        if index == TargetType.PLAYER then
            -- Ask for player ID
            local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur", "")
            playerId = tonumber(playerId)

            if playerId then
                videoData.targetInfo = playerId
            end
        elseif index == TargetType.ZONE then
            -- Ask for radius
            local radius = VFW.Nui.KeyboardInput(true, "Rayon de la zone (mètres)", "50")
            radius = tonumber(radius)

            if radius and radius > 0 then
                videoData.targetInfo = radius
            end
        elseif index == TargetType.SERVER then
            -- All players
            videoData.targetInfo = -1
        end
    end)

    -- Placement type
    StaffMenu.videoManagement.Checkbox(":monitor: PLEIN ÉCRAN", nil, false, videoData.placementType == PlacementType.FULLSCREEN, function(_checked)
        videoData.placementType = _checked and PlacementType.FULLSCREEN or PlacementType.TOP_RIGHT
        VFW.ShowNotification({
            type = 'STAFF', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Gestion Vidéos',
            message = _checked and "Mode plein écran activé." or "Mode coin supérieur droit activé."
      })
    end)

    StaffMenu.videoManagement.Separator(":settings: ACTIONS")

    -- Launch video button
    StaffMenu.videoManagement.Button(":film: LANCER LA VIDÉO", nil, nil, "chevron", false, function()
        if not videoData.videoLink then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Vidéos',
                message = "Veuillez définir un lien vidéo."
          })
            return
        end

        if not videoData.targetInfo then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Vidéos',
                message = "Veuillez définir une cible."
          })
            return
        end

        TriggerServerEvent("vfw:staff:playVideo", videoData.videoLink, videoData.placementType, videoData.targetType, videoData.targetInfo)
    end)

    -- Stop video button
    StaffMenu.videoManagement.Button("⏹ ARRÊTER LA VIDÉO", nil, nil, "chevron", false, function()
        TriggerServerEvent("vfw:staff:stopVideo")
    end)

    StaffMenu.videoManagement.Separator(":bolt: OPTIONS RAPIDES")

    -- Quick launch for all players
    StaffMenu.videoManagement.Button(":monitor: DIFFUSER À TOUS", nil, nil, "chevron", false, function()
        local videoUrl = VFW.Nui.KeyboardInput(true, "Lien YouTube pour diffusion générale", "")

        if videoUrl and videoUrl ~= "" then
            if string.find(videoUrl, "youtube.com") or string.find(videoUrl, "youtu.be") then
                TriggerServerEvent("vfw:staff:playVideo", videoUrl, PlacementType.TOP_RIGHT, TargetType.SERVER, -1)
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Vidéos',
                    message = "Ce lien n'est pas valide, YouTube uniquement."
              })
            end
        end
    end)

    -- Quick stop for all
    StaffMenu.videoManagement.Button(" ARRÊTER POUR TOUS", nil, nil, "chevron", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour arrêter toutes les vidéos", "")

        if confirm and string.lower(confirm) == "confirmer" then
            TriggerServerEvent("vfw:staff:stopVideoForAll")
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Vidéos',
                message = "Toutes les vidéos arrêtées."
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Vidéos',
                message = "Action annulée."
          })
        end
    end)
end

local currentVideoFrame = nil
local currentVideoStyle = nil
local isVideoLauncher = false

local function stopLocalVideo()
    SendNUIMessage({
        action = "nui:video:stop",
        data = {}
    })
    currentVideoFrame = nil
    currentVideoStyle = nil
    isVideoLauncher = false
end

-- Thread to handle key input (same controls for all modes)
CreateThread(function()
    while true do
        Wait(0)

        if currentVideoFrame then
            -- Video is playing - handle controls (same for all modes)

            -- Désactiver le scroll wheel pour éviter qu'il n'affecte l'iframe YouTube
            DisableControlAction(2, 241, true) -- Scroll up
            DisableControlAction(2, 242, true) -- Scroll down
            DisableControlAction(0, 241, true) -- Scroll up (input group 0)
            DisableControlAction(0, 242, true) -- Scroll down (input group 0)

            -- Scroll wheel for volume control (using disabled controls)
            if IsDisabledControlJustPressed(2, 241) or IsDisabledControlJustPressed(0, 241) then
                SendNUIMessage({
                    action = "nui:video:adjustVolume",
                    data = { delta = 10 }
                })
            elseif IsDisabledControlJustPressed(2, 242) or IsDisabledControlJustPressed(0, 242) then
                SendNUIMessage({
                    action = "nui:video:adjustVolume",
                    data = { delta = -10 }
                })
            end

            -- Touche X (INPUT_VEH_DUCK = 73) - Stop video for self
            if IsControlJustPressed(0, 73) or IsDisabledControlJustPressed(0, 73) then
                stopLocalVideo()
            end

            if IsControlJustPressed(0, 26) or IsDisabledControlJustPressed(0, 26) then
                if isVideoLauncher then
                    TriggerServerEvent("vfw:staff:stopVideoForAll")
                else
                    stopLocalVideo()
                end
            end
        else
            Wait(500)
        end
    end
end)

-- Function to extract video ID from YouTube URL
local function extractYouTubeId(url)
    -- Handle youtu.be links
    local shortId = string.match(url, "youtu%.be/([%w%-_]+)")
    if shortId then
        return shortId
    end

    -- Handle youtube.com links
    local longId = string.match(url, "youtube%.com/watch%?v=([%w%-_]+)")
    if longId then
        return longId
    end

    -- Handle youtube.com embed links
    local embedId = string.match(url, "youtube%.com/embed/([%w%-_]+)")
    if embedId then
        return embedId
    end

    return nil
end

-- Start video playback
RegisterNetEvent("vfw:staff:startVideo", function(videoLink, placementType, launcher)
    local videoId = extractYouTubeId(videoLink)
    if not videoId then return end

    if currentVideoFrame then
        SendNUIMessage({ action = "nui:video:stop" })
    end

    local videoStyle = placementType == PlacementType.FULLSCREEN and "fullscreen" or "topright"

  local isLauncher = launcher == true

    SendNUIMessage({
        action = "nui:video:play",
        data = {
            videoId = videoId,
            style = videoStyle,
            url = "https://www.youtube.com/embed/" .. videoId .. "?autoplay=1&controls=1&modestbranding=1&rel=0",
            isLauncher = isLauncher
        }
    })

    currentVideoFrame = true
    currentVideoStyle = videoStyle
    isVideoLauncher = isLauncher

    if isVideoLauncher then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Vidéos',
            message = "Lecture vidéo démarrée."
      })
    end
end)

-- Stop video playback
RegisterNetEvent("vfw:staff:stopVideoClient", function()
    if currentVideoFrame then
        stopLocalVideo()
    end
end)
