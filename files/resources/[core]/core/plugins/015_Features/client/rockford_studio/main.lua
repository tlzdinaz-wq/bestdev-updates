--[[
    Rockford Studio - Client
    Gestion de l'UI, points d'interaction et streaming live
]]

local isStudioOpen = false
local currentStudio = nil
local currentRole = nil -- "singer" ou "engineer"
local currentSessionStudioId = nil
local studioBlips = {}

-- Animation state
local isStudioFrozen = false

-- Cache des sessions actives (pour afficher/masquer la table de mixage)
local studioSessionCache = {} -- studioSessionCache[studioId] = true/false
local lastSessionCheck = 0
local SESSION_CHECK_INTERVAL = 2000 -- Refresh toutes les 2 secondes

-- FloatingInteraction state
local studioFloatingShown = false
local studioFloatingId = nil
local mixingFloatingShown = false
local mixingFloatingId = nil

local function ShowStudioFloating(id, worldPos, title, subtitle, buttons)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + 0.5)
    if not onScreen then
        if studioFloatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            studioFloatingShown = false
            studioFloatingId = nil
        end
        return
    end

    local data = {
        id = "studio_" .. tostring(id),
        title = "",

        screenX = screenX,
        screenY = screenY,
        buttons = buttons or {}
    }

    if studioFloatingShown and studioFloatingId == id then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        studioFloatingShown = true
        studioFloatingId = id
    end
end

local function HideStudioFloating()
    if studioFloatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        studioFloatingShown = false
        studioFloatingId = nil
    end
end

local function ShowMixingFloating(id, worldPos, title, subtitle, buttons)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + 0.5)
    if not onScreen then
        if mixingFloatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            mixingFloatingShown = false
            mixingFloatingId = nil
        end
        return
    end

    local data = {
        id = "mixing_" .. tostring(id),
        title = "",

        screenX = screenX,
        screenY = screenY,
        buttons = buttons or {}
    }

    if mixingFloatingShown and mixingFloatingId == id then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        mixingFloatingShown = true
        mixingFloatingId = id
    end
end

local function HideMixingFloating()
    if mixingFloatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        mixingFloatingShown = false
        mixingFloatingId = nil
    end
end

-- =====================================================
-- STUDIO ANIMATIONS (via emote system)
-- =====================================================

--- Démarre une emote studio (tablette ou micro)
--- @param animType string "tablet" ou "singer"
function StartStudioAnimation(animType)
    local plyPed = PlayerPedId()

    -- Annuler toute emote en cours
    EmoteCancel()
    Wait(100)

    if animType == "tablet" then
        EmoteCommandStart("tablet2", plyPed)
        TriggerServerEvent("vfw:newanim:sync", "tablet2")
    elseif animType == "singer" then
        EmoteCommandStart("microckj", plyPed)
        TriggerServerEvent("vfw:newanim:sync", "microckj")
    end
end

--- Change la pose du singer (l'emote microckj a une seule pose)
--- @param newState string "waiting", "listening", "recording"
function ChangeSingerAnimState(newState)
    -- No-op: l'emote microckj gere la pose automatiquement
end

--- Freeze/unfreeze le joueur et désactive les contrôles de mouvement
--- @param freeze boolean
function FreezeStudioPlayer(freeze)
    local playerPed = PlayerPedId()

    if freeze then
        FreezeEntityPosition(playerPed, true)
        SetPlayerControl(PlayerId(), false, 0)
        isStudioFrozen = true

        CreateThread(function()
            while isStudioFrozen do
                Wait(0)
                DisableControlAction(0, 30, true)  -- Move LR
                DisableControlAction(0, 31, true)  -- Move UD
                DisableControlAction(0, 32, true)  -- Move Up
                DisableControlAction(0, 33, true)  -- Move Down
                DisableControlAction(0, 34, true)  -- Move Left
                DisableControlAction(0, 35, true)  -- Move Right
                DisableControlAction(0, 21, true)  -- Sprint
                DisableControlAction(0, 22, true)  -- Jump
                DisableControlAction(0, 36, true)  -- Stealth
            end
        end)
    else
        FreezeEntityPosition(playerPed, false)
        SetPlayerControl(PlayerId(), true, 0)
        isStudioFrozen = false
    end
end

--- Arrête toutes les animations studio et unfreeze le joueur
function StopStudioAnimation()
    EmoteCancel()
    FreezeStudioPlayer(false)
end

-- Studios chargés depuis la base de données (via serveur)
local LocalStudios = {}

-- =====================================================
-- XSOUND - Declarations et helpers (avant CloseStudio)
-- =====================================================

local xSound = exports.xsound
local previewSoundId = "studio_preview"
local ActiveStudioSounds = {}

local function SafeDestroySound(soundId)
    if soundId and xSound:soundExists(soundId) then
        xSound:Destroy(soundId)
    end
end

local function DestroyAllSounds()
    for soundId, _ in pairs(ActiveStudioSounds) do
        SafeDestroySound(soundId)
    end
    ActiveStudioSounds = {}
    SafeDestroySound("studio_preview")
    SafeDestroySound("studio_beat")
end

-- =====================================================
-- SYNC STUDIOS DEPUIS LE SERVEUR
-- =====================================================

local function ClearAllBlips()
    for id, blip in pairs(studioBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    studioBlips = {}
end

local function CreateStudiosBlips()
    ClearAllBlips()
    -- Pas de blips sur la carte/minimap, les studios sont visibles uniquement via marker au sol à 3m
end

-- Recevoir les studios du serveur (push depuis le serveur)
RegisterNetEvent("rockfordstudio:syncStudios", function(studios)
    LocalStudios = studios or {}
    CreateStudiosBlips()
end)

-- Charger les studios au démarrage côté client (pull - plus fiable après restart)
CreateThread(function()
    Wait(2000)
    local studios = TriggerServerCallback("vfw:staff:getAllStudios")
    if studios then
        LocalStudios = studios
        CreateStudiosBlips()
    end
end)

-- Helper: dessiner du texte 3D au-dessus d'un point
local function DrawText3D(x, y, z, text, r, g, b)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.3, 0.3)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(r or 255, g or 255, b or 255, 215)
        SetTextDropshadow(1, 0, 0, 0, 200)
        SetTextEdge(1, 0, 0, 0, 150)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Helper: obtenir les coords depuis une position (table ou vector3)
local function GetCoordsFromPosition(pos)
    if not pos then return nil end
    if type(pos) == "vector3" then return pos end
    return vector3(pos.x or pos[1], pos.y or pos[2], pos.z or pos[3])
end

-- Point d'interaction pour chaque studio (FloatingInteraction NUI)
CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        if isStudioOpen then
            HideStudioFloating()
            Wait(sleep)
            goto nextStudio
        end

        local closestStudio = nil
        local closestCoords = nil
        local closestDistance = 2.0

        for id, studio in pairs(LocalStudios) do
            -- Masquer le point si le joueur n'a pas le job requis
            if studio.scope == "job" and studio.job then
                local playerJob = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name
                if type(studio.job) == "table" then
                    local hasJob = false
                    for _, j in ipairs(studio.job) do
                        if playerJob == j then hasJob = true break end
                    end
                    if not hasJob then goto continue end
                else
                    if playerJob ~= studio.job then goto continue end
                end
            end

            local studioCoords = GetCoordsFromPosition(studio.position)
            if studioCoords then
                local distance = #(playerCoords - studioCoords)
                if distance < closestDistance then
                    closestDistance = distance
                    closestStudio = id
                    closestCoords = studioCoords
                end
            end
            ::continue::
        end

        if closestStudio then
            sleep = 0
            local studio = LocalStudios[closestStudio]
            ShowStudioFloating(closestStudio, closestCoords, "STUDIO", studio.name or "Studio d'enregistrement", {
                { label = "Ouvrir le studio", key = "E" }
            })

            if VFW.Interact.JustPressed(0, 38) then
                HideStudioFloating()
                local studioObj = {
                    id = closestStudio,
                    name = studio.name,
                    coords = closestCoords,
                    liveZoneRadius = studio.liveZoneRadius or 15.0,
                    scope = studio.scope,
                    job = studio.job
                }
                OpenStudio(studioObj)
            end
        else
            HideStudioFloating()
        end

        Wait(sleep)
        ::nextStudio::
    end
end)

-- Ouvrir le studio (mode solo par defaut, ou comme singer en studio)
function OpenStudio(studio)
    if isStudioOpen then return end

    -- Vérifier l'accès via callback serveur
    local canAccess = TriggerServerCallback("rockfordstudio:canAccess", studio.id)

    if canAccess == false then
        VFW.ShowNotification("ERROR", "Vous n'avez pas accès à ce studio")
        return
    end

    isStudioOpen = true
    currentStudio = studio

    -- Freeze + animation tablette
    FreezeStudioPlayer(true)
    StartStudioAnimation("tablet")

    VFW.Nui.Focus(true)
    SendNUIMessage({
        action = "nui:rockfordstudio:open",
        data = {
            studioId = studio.id,
            studioName = studio.name
        }
    })

    -- Démarrer le tracking des joueurs dans la zone
    StartLiveZoneTracking()
end

-- Ouvrir le studio en tant qu'ingenieur (depuis la table de mixage)
function OpenStudioAsEngineer(studio)
    if isStudioOpen then return end

    -- Verifier qu'une session existe (un singer est dans le studio)
    local hasSession = TriggerServerCallback("rockfordstudio:hasSession", studio.id)

    if not hasSession then
        VFW.ShowNotification("ERROR", "Nous attendons l'artiste")
        return
    end

    isStudioOpen = true
    currentStudio = studio
    currentRole = "engineer"
    currentSessionStudioId = studio.id

    -- Freeze + animation tablette
    FreezeStudioPlayer(true)
    StartStudioAnimation("tablet")

    -- Rejoindre la session
    TriggerServerEvent("rockfordstudio:joinSession", studio.id)

    VFW.Nui.Focus(true)
    SendNUIMessage({
        action = "nui:rockfordstudio:open",
        data = {
            studioId = studio.id,
            studioName = studio.name,
            mode = "studio",
            role = "engineer"
        }
    })
end

-- Fermer le studio
function CloseStudio()
    if not isStudioOpen then return end

    -- Arrêter les animations et props en premier
    StopStudioAnimation()

    -- Arreter le broadcast live avant de perdre la ref au studio
    if currentStudio then
        TriggerServerEvent("rockfordstudio:stopLive", currentStudio.id)
    end

    -- Quitter la session studio si active
    if currentSessionStudioId then
        TriggerServerEvent("rockfordstudio:leaveSession", currentSessionStudioId)
        currentSessionStudioId = nil
    end

    isStudioOpen = false
    currentStudio = nil
    currentRole = nil

    VFW.Nui.Focus(false)
    SendNUIMessage({
        action = "nui:rockfordstudio:close"
    })

    -- Arreter tous les sons du studio
    DestroyAllSounds()

    StopLiveZoneTracking()
end

-- Callback NUI: Fermer le studio
RegisterNuiCallback("nui:rockfordstudio:close", function(_, cb)
    CloseStudio()
    cb({ success = true })
end)

-- =====================================================
-- PREVIEW AUDIO (NUI Callbacks xSound)
-- =====================================================

-- Generation counter pour annuler les seeks obsoletes
local previewSeekGeneration = 0

-- Dernier preview joue (pour re-broadcast au resume)
local lastPreviewUrl = nil
local lastPreviewVolume = 0.5

-- Callback NUI: Jouer un preview audio
RegisterNuiCallback("nui:rockfordstudio:playPreview", function(data, cb)
    if not data or not data.url then
        cb({ success = false, message = "URL manquante" })
        return
    end

    local volume = data.volume or 0.5
    local startTime = data.startTime or 0
    lastPreviewUrl = data.url
    lastPreviewVolume = volume

    -- Arreter l'ancien son si existant
    SafeDestroySound(previewSoundId)

    -- Incrementer la generation pour annuler tout seek en cours
    previewSeekGeneration = previewSeekGeneration + 1
    local myGeneration = previewSeekGeneration

    -- Si on doit seek, jouer en muet d'abord pour eviter d'entendre le debut
    local initialVolume = startTime > 0 and 0.0 or volume
    xSound:PlayUrl(previewSoundId, data.url, initialVolume, false)
    ActiveStudioSounds[previewSoundId] = true

    -- Broadcaster aux joueurs proches
    if currentStudio and data.url then
        TriggerServerEvent("rockfordstudio:playLive", currentStudio.id, data.url, volume)
    end

    if startTime > 0 then
        Citizen.CreateThread(function()
            -- Phase 1: Attendre que l'audio joue vraiment (currentTime avance)
            -- Cela confirme que Howler a charge le stream et peut etre manipule
            for _ = 1, 100 do -- 10 secondes max
                Wait(100)
                if myGeneration ~= previewSeekGeneration then return end
                if not xSound:soundExists(previewSoundId) then return end

                local t = xSound:getCurrentTime(previewSoundId)
                if t and t > 0.1 then
                    break
                end
            end

            if myGeneration ~= previewSeekGeneration then return end
            if not xSound:soundExists(previewSoundId) then return end

            -- Phase 2: Pause → seek → verifier → resume
            -- Pause stabilise l'etat interne de Howler avant le seek
            xSound:Pause(previewSoundId)
            Wait(100)

            for attempt = 1, 5 do
                if myGeneration ~= previewSeekGeneration then return end
                if not xSound:soundExists(previewSoundId) then return end

                xSound:setTimeStamp(previewSoundId, startTime)
                -- Laisser le navigateur traiter la Range request
                Wait(300)

                -- Verifier la position reelle via le player JS
                if myGeneration ~= previewSeekGeneration then return end
                local actualTime = xSound:getCurrentTime(previewSoundId)

                if actualTime and math.abs(actualTime - startTime) < 2.0 then
                    break -- Seek confirme
                end

                -- Delai croissant avant retry
                Wait(500 * attempt)
            end

            -- Phase 3: Resume depuis la position seekee + unmute
            if myGeneration == previewSeekGeneration and xSound:soundExists(previewSoundId) then
                xSound:Resume(previewSoundId)
                Wait(50)
                xSound:setVolume(previewSoundId, volume)
            end
        end)
    end

    cb({ success = true, soundId = previewSoundId })
end)

-- Callback NUI: Pause le preview
RegisterNuiCallback("nui:rockfordstudio:pausePreview", function(_, cb)
    if xSound:soundExists(previewSoundId) then
        xSound:Pause(previewSoundId)
    end
    -- Arreter le live pour les joueurs proches
    if currentStudio then
        TriggerServerEvent("rockfordstudio:stopLive", currentStudio.id)
    end
    cb({ success = true })
end)

-- Callback NUI: Resume le preview
RegisterNuiCallback("nui:rockfordstudio:resumePreview", function(_, cb)
    if xSound:soundExists(previewSoundId) then
        xSound:Resume(previewSoundId)
        -- Re-broadcaster aux joueurs proches (ils reprendront depuis le debut, limitation acceptee)
        if currentStudio and lastPreviewUrl then
            TriggerServerEvent("rockfordstudio:playLive", currentStudio.id, lastPreviewUrl, lastPreviewVolume)
        end
    end
    cb({ success = true })
end)

-- Callback NUI: Stop le preview
RegisterNuiCallback("nui:rockfordstudio:stopPreview", function(_, cb)
    SafeDestroySound(previewSoundId)
    ActiveStudioSounds[previewSoundId] = nil
    lastPreviewUrl = nil
    -- Arreter le live pour les joueurs proches
    if currentStudio then
        TriggerServerEvent("rockfordstudio:stopLive", currentStudio.id)
    end
    cb({ success = true })
end)

-- Callback NUI: Changer le volume du preview
RegisterNuiCallback("nui:rockfordstudio:setPreviewVolume", function(data, cb)
    if xSound:soundExists(previewSoundId) and data and data.volume then
        xSound:setVolume(previewSoundId, data.volume)
    end
    cb({ success = true })
end)

-- =====================================================
-- EXPORT UPLOAD (via server-side HTTP)
-- =====================================================

local pendingExportCb = nil

-- Chunked export: NUI sends base64 in small chunks instead of one huge payload
RegisterNuiCallback("nui:rockfordstudio:exportChunkedStart", function(data, cb)
    if not data or not data.exportId or not data.filename or not data.totalChunks then
        cb({ success = false, error = "Données manquantes" })
        return
    end
    TriggerServerEvent("rockfordstudio:exportStart", data.exportId, data.filename, data.totalChunks)
    cb({ success = true })
end)

RegisterNuiCallback("nui:rockfordstudio:exportChunkedData", function(data, cb)
    if not data or not data.exportId or not data.chunkIndex or not data.chunk then
        cb({ success = false, error = "Chunk invalide" })
        return
    end
    TriggerServerEvent("rockfordstudio:exportChunk", data.exportId, data.chunkIndex, data.chunk)
    cb({ success = true })
end)

RegisterNuiCallback("nui:rockfordstudio:exportChunkedFinish", function(data, cb)
    if not data or not data.exportId then
        cb({ success = false, error = "Export ID manquant" })
        return
    end
    -- Store NUI callback to resolve when server responds with upload result
    pendingExportCb = cb
    TriggerServerEvent("rockfordstudio:exportFinish", data.exportId)
end)

-- Legacy: single-payload upload (kept for backward compat, small files only)
RegisterNuiCallback("nui:rockfordstudio:uploadExport", function(data, cb)
    if not data or not data.base64 or not data.filename then
        cb({ success = false, error = "Données manquantes" })
        return
    end

    pendingExportCb = cb

    local base64 = data.base64
    local chunkSize = 500000
    local totalChunks = math.ceil(#base64 / chunkSize)
    local exportId = tostring(GetGameTimer()) .. "_" .. tostring(math.random(1000, 9999))

    TriggerServerEvent("rockfordstudio:exportStart", exportId, data.filename, totalChunks)

    for i = 1, totalChunks do
        local startIdx = (i - 1) * chunkSize + 1
        local endIdx = math.min(i * chunkSize, #base64)
        local chunk = base64:sub(startIdx, endIdx)
        TriggerServerEvent("rockfordstudio:exportChunk", exportId, i, chunk)
        Wait(50)
    end

    TriggerServerEvent("rockfordstudio:exportFinish", exportId)
end)

-- Receive upload result from server
RegisterNetEvent("rockfordstudio:exportResult", function(result)
    if pendingExportCb then
        pendingExportCb(result)
        pendingExportCb = nil
    end
end)

-- =====================================================
-- AUDIO DOWNLOAD PROXY (bypass CEF CORS restrictions)
-- =====================================================

-- Base64 encode (client-side, pour renvoyer les données audio au NUI)
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64Encode(data)
    local parts = {}
    for i = 1, #data, 3 do
        local a = data:byte(i)
        local b = data:byte(i + 1) or 0
        local c = data:byte(i + 2) or 0
        local n = a * 65536 + b * 256 + c

        parts[#parts + 1] = b64chars:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
        parts[#parts + 1] = b64chars:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)

        if i + 1 <= #data then
            parts[#parts + 1] = b64chars:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
        else
            parts[#parts + 1] = '='
        end

        if i + 2 <= #data then
            parts[#parts + 1] = b64chars:sub(n % 64 + 1, n % 64 + 1)
        else
            parts[#parts + 1] = '='
        end
    end
    return table.concat(parts)
end

-- NUI: Telecharger un fichier audio via PerformHttpRequest (pas de CORS)
RegisterNuiCallback("nui:rockfordstudio:downloadAudio", function(data, cb)
    if not data or not data.url or data.url == "" then
        cb({ success = false, error = "URL manquante" })
        return
    end

    console.debug(("[RockfordStudio] Download proxy: %s"):format(data.url:sub(1, 100)))

    PerformHttpRequest(data.url, function(statusCode, response, headers)
        if statusCode == 200 and response and #response > 0 then
            console.debug(("[RockfordStudio] Download OK: %d bytes"):format(#response))
            local encoded = base64Encode(response)
            cb({ success = true, base64 = encoded, size = #response })
        else
            console.debug(("[RockfordStudio] Download failed: HTTP %s"):format(tostring(statusCode)))
            cb({ success = false, error = "HTTP " .. tostring(statusCode) })
        end
    end, "GET", "", {})
end)

-- =====================================================
-- URL RESOLUTION (cobalt.tools proxy)
-- =====================================================

-- NUI: Résoudre une URL YouTube/SoundCloud en lien audio direct
RegisterNuiCallback("nui:rockfordstudio:resolveAudioUrl", function(data, cb)
    if not data or not data.url then
        cb({ success = false })
        return
    end

    local resolvedUrl = TriggerServerCallback("rockfordstudio:resolveAudioUrl", data.url)
    if resolvedUrl then
        cb({ success = true, url = resolvedUrl })
    else
        cb({ success = false })
    end
end)

-- =====================================================
-- MODE STUDIO - NUI CALLBACKS
-- =====================================================

-- NUI: Le singer choisit mode STUDIO
RegisterNuiCallback("nui:rockfordstudio:selectStudioMode", function(_, cb)
    if not currentStudio then
        cb({ success = false })
        return
    end

    currentRole = "singer"
    currentSessionStudioId = currentStudio.id

    -- Passer de la tablette au micro
    StartStudioAnimation("singer")

    -- Creer la session cote serveur
    TriggerServerEvent("rockfordstudio:createSession", currentStudio.id)
    cb({ success = true })
end)

-- NUI: Quitter la session
RegisterNuiCallback("nui:rockfordstudio:leaveSession", function(_, cb)
    if currentSessionStudioId then
        TriggerServerEvent("rockfordstudio:leaveSession", currentSessionStudioId)
        currentSessionStudioId = nil
    end
    CloseStudio()
    cb({ success = true })
end)

-- NUI: L'engineer envoie un transport au singer
RegisterNuiCallback("nui:rockfordstudio:studioTransport", function(data, cb)
    if not currentSessionStudioId or currentRole ~= "engineer" then
        cb({ success = false })
        return
    end

    TriggerServerEvent("rockfordstudio:studioTransport", currentSessionStudioId, data.action, data)
    cb({ success = true })
end)

-- =====================================================
-- MODE STUDIO - SESSION EVENTS (recus du serveur)
-- =====================================================

-- Session creee (singer)
RegisterNetEvent("rockfordstudio:sessionCreated", function(studioId)
    currentSessionStudioId = studioId
end)

-- Engineer a rejoint (notifie le singer)
RegisterNetEvent("rockfordstudio:engineerJoined", function(studioId, engineerName)
    SendNUIMessage({
        action = "nui:rockfordstudio:singerSync",
        data = {
            status = "waiting",
            engineerName = engineerName
        }
    })
    VFW.ShowNotification("VERT", engineerName .. " a rejoint en tant qu'ingénieur")
end)

-- Session rejointe (engineer recoit info)
RegisterNetEvent("rockfordstudio:sessionJoined", function(studioId, singerName)
    VFW.ShowNotification("VERT", "Connecte a la session de " .. singerName)
end)

-- Transport du singer (recu depuis le serveur, envoi par l'engineer)
RegisterNetEvent("rockfordstudio:singerTransport", function(action, data)
    if action == "playBeat" then
        -- Jouer le beat via xSound pour le singer
        SafeDestroySound("studio_beat")
        xSound:PlayUrl("studio_beat", data.url, data.volume or 0.5, false)
        ActiveStudioSounds["studio_beat"] = true

        ChangeSingerAnimState("listening")

        SendNUIMessage({
            action = "nui:rockfordstudio:singerSync",
            data = {
                status = "listening",
                engineerName = data.engineerName
            }
        })
    elseif action == "stopBeat" then
        SafeDestroySound("studio_beat")
        ActiveStudioSounds["studio_beat"] = nil

        ChangeSingerAnimState("waiting")

        SendNUIMessage({
            action = "nui:rockfordstudio:singerSync",
            data = { status = "waiting" }
        })
    elseif action == "startRecording" then
        ChangeSingerAnimState("recording")

        SendNUIMessage({
            action = "nui:rockfordstudio:singerSync",
            data = {
                status = "recording",
                engineerName = data.engineerName
            }
        })
    elseif action == "stopRecording" then
        SafeDestroySound("studio_beat")
        ActiveStudioSounds["studio_beat"] = nil

        ChangeSingerAnimState("waiting")

        SendNUIMessage({
            action = "nui:rockfordstudio:singerSync",
            data = { status = "waiting" }
        })
    end
end)

-- NUI: Le singer envoie son enregistrement audio au serveur
RegisterNuiCallback("nui:rockfordstudio:recordingComplete", function(data, cb)
    if currentSessionStudioId then
        TriggerServerEvent("rockfordstudio:recordingComplete", currentSessionStudioId, data)
    end
    cb({ success = true })
end)

-- L'engineer recoit l'audio du singer (relaye par le serveur)
RegisterNetEvent("rockfordstudio:recordingReady", function(audioData)
    SendNUIMessage({
        action = "nui:rockfordstudio:recordingReady",
        data = audioData
    })
end)

-- Session terminee (l'autre partie est partie)
RegisterNetEvent("rockfordstudio:sessionEnded", function(studioId, reason)
    VFW.ShowNotification("ERROR", reason or "La session a été terminée")
    currentSessionStudioId = nil
    currentRole = nil

    -- Arreter tous les sons avant de fermer
    DestroyAllSounds()
    CloseStudio()
end)

-- =====================================================
-- INTERACTION TABLE DE MIXAGE (pour l'ingenieur)
-- =====================================================

CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local now = GetGameTimer()

        if isStudioOpen then
            HideMixingFloating()
            Wait(sleep)
            goto nextMixing
        end

        local needsSessionCheck = (now - lastSessionCheck) > SESSION_CHECK_INTERVAL
        local closestMixing = nil
        local closestMixingCoords = nil
        local closestMixingDistance = 2.0

        for id, studio in pairs(LocalStudios) do
            local mixingCoords = GetCoordsFromPosition(studio.mixingTablePosition)
            if mixingCoords then
                local distance = #(playerCoords - mixingCoords)

                if distance < 10.0 then
                    if needsSessionCheck then
                        studioSessionCache[id] = TriggerServerCallback("rockfordstudio:hasSession", id)
                        lastSessionCheck = now
                    end

                    if studioSessionCache[id] and distance < closestMixingDistance then
                        closestMixingDistance = distance
                        closestMixing = id
                        closestMixingCoords = mixingCoords
                    end
                end
            end
        end

        if closestMixing then
            sleep = 0
            local studio = LocalStudios[closestMixing]
            ShowMixingFloating(closestMixing, closestMixingCoords, "MIXAGE", "Table de mixage", {
                { label = "Ouvrir la table", key = "E" }
            })

            if VFW.Interact.JustPressed(0, 38) then
                HideMixingFloating()
                local studioObj = {
                    id = closestMixing,
                    name = studio.name,
                    coords = GetCoordsFromPosition(studio.position),
                    liveZoneRadius = studio.liveZoneRadius or 15.0,
                    scope = studio.scope,
                    job = studio.job
                }
                OpenStudioAsEngineer(studioObj)
            end
        else
            HideMixingFloating()
        end

        Wait(sleep)
        ::nextMixing::
    end
end)

-- =====================================================
-- LIVE ZONE TRACKING
-- =====================================================

local liveTrackingActive = false

function StartLiveZoneTracking()
    if not currentStudio then return end
    if liveTrackingActive then return end

    liveTrackingActive = true
    CreateThread(function()
        while liveTrackingActive and isStudioOpen and currentStudio do
            local listeners = GetPlayersInLiveZone()

            SendNUIMessage({
                action = "nui:rockfordstudio:listeners",
                data = {
                    listeners = listeners
                }
            })

            Wait(2000) -- Sync interval 2 secondes
        end
    end)
end

function StopLiveZoneTracking()
    liveTrackingActive = false
end

function GetPlayersInLiveZone()
    if not currentStudio then return {} end

    local listeners = {}
    local studioCoords = currentStudio.coords
    local radius = currentStudio.liveZoneRadius

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(targetCoords - studioCoords)

                if distance <= radius then
                    local serverId = GetPlayerServerId(playerId)
                    table.insert(listeners, {
                        id = serverId,
                        name = GetPlayerName(playerId),
                        isListening = true
                    })
                end
            end
        end
    end

    return listeners
end

-- =====================================================
-- LIVE STREAMING (faire écouter aux joueurs dans la zone)
-- =====================================================

-- Event pour jouer un son aux joueurs dans la zone
RegisterNetEvent("rockfordstudio:playLive", function(studioId, url, volume)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local studio = LocalStudios[studioId]
    if studio then
        local studioCoords = GetCoordsFromPosition(studio.position)
        if studioCoords then
            local distance = #(playerCoords - studioCoords)
            local radius = studio.liveZoneRadius or 15.0
            if distance <= radius then
                if exports.xsound then
                    local soundId = "studio_live_" .. studioId
                    SafeDestroySound(soundId)
                    exports.xsound:PlayUrlPos(soundId, url, volume, studioCoords, false)
                    exports.xsound:Distance(soundId, radius)
                    ActiveStudioSounds[soundId] = true
                end
            end
        end
    end
end)

-- Event pour arrêter le son live
RegisterNetEvent("rockfordstudio:stopLive", function(studioId)
    local soundId = "studio_live_" .. studioId
    SafeDestroySound(soundId)
    ActiveStudioSounds[soundId] = nil
end)

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Supprimer les blips
    for _, blip in pairs(studioBlips) do
        RemoveBlip(blip)
    end

    -- Toujours detruire les sons, meme si le studio n'est pas "ouvert"
    DestroyAllSounds()

    -- Filet de securite: arreter les animations/props
    StopStudioAnimation()

    -- Fermer le studio si ouvert
    if isStudioOpen then
        CloseStudio()
    end
end)

-- Escape pour fermer
CreateThread(function()
    while true do
        if isStudioOpen then
            if IsControlJustPressed(0, 322) then -- ESC
                CloseStudio()
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Detection de mort pendant le studio
CreateThread(function()
    while true do
        if isStudioOpen then
            if IsEntityDead(PlayerPedId()) then
                CloseStudio()
            end
            Wait(1000)
        else
            Wait(2000)
        end
    end
end)

-- =====================================================
-- UTILISATION DES ITEMS USB/CD
-- =====================================================

-- Event quand un item USB/CD est utilisé
RegisterNetEvent("rockfordstudio:useMusicItem", function(itemData)
    if not itemData or not itemData.url then return end

    -- Vérifier si le joueur est proche d'une boombox
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Pour l'instant, ouvrir un menu contextuel pour choisir quoi faire
    VFW.ShowContextMenu({
        {
            title = itemData.title,
            description = "par " .. itemData.artist,
            disabled = true
        },
        {
            title = "Jouer sur la boombox la plus proche",
            description = "Diffuse la musique sur une boombox à proximité",
            event = "rockfordstudio:playOnBoombox",
            args = { url = itemData.url, title = itemData.title }
        },
        {
            title = "Copier le lien",
            description = itemData.url,
            event = "rockfordstudio:copyUrl",
            args = { url = itemData.url }
        }
    })
end)

-- Jouer sur une boombox proche
RegisterNetEvent("rockfordstudio:playOnBoombox", function(data)
    if not data or not data.url then return end

    -- Chercher une boombox proche (via le système existant)
    -- Ceci dépend de l'implémentation de la boombox
    TriggerEvent("core:boombox:playFromItem", data.url, data.title)
end)

-- Copier l'URL
RegisterNetEvent("rockfordstudio:copyUrl", function(data)
    if not data or not data.url then return end

    -- Utiliser le système de clipboard NUI
    SendNUIMessage({
        action = "nui:clipboard",
        data = data.url
    })

    VFW.ShowNotification("VERT", "Lien copié dans le presse-papiers")
end)
