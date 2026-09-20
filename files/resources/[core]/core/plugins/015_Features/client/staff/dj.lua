---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- PLATINE DJ CLIENT HANDLERS
-- ============================================

local PlatinesData = {}
local djFloatingShown = false
local djFloatingId = nil
local CurrentPlatineId = nil

local function ShowDJFloating(id, worldPos, title, subtitle, buttons, floatingZ)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + (floatingZ or 0.5))
    if not onScreen then
        if djFloatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            djFloatingShown = false
            djFloatingId = nil
        end
        return
    end

    local data = {
        id = "dj_platine_" .. tostring(id),
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = buttons or {}
    }

    if djFloatingShown and djFloatingId == id then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        djFloatingShown = true
        djFloatingId = id
    end
end

local function HideDJFloating()
    if djFloatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        djFloatingShown = false
        djFloatingId = nil
    end
end

---Créer un point d'interaction pour une platine
---@param platineId number
---@param platineData table
local function CreatePlatineInteraction(platineId, platineData)
    if not platineData or not platineData.position then
        return
    end

    local pos = platineData.position
    local platineName = platineData.name or ("Platine #" .. platineId)

    -- Stocker les données de la platine
    PlatinesData[platineId] = {
        id = platineId,
        name = platineName,
        position = vector3(pos.x, pos.y, pos.z),
        radius = platineData.radius or 50.0,
        scope = platineData.scope or "public",
        job = platineData.job or nil
    }
end

---Vérifie si le joueur a accès à une platine
---@param platineData table
---@return boolean hasAccess
---@return string|nil reason
local function CanAccessPlatine(platineData)
    if not platineData then
        return false, "Platine introuvable"
  end

    local scope = platineData.scope or "public"

  -- Si public, tout le monde y a accès
    if scope == "public" then
        return true, nil
    end

    -- Si job, vérifier le job du joueur
    if scope == "job" then
        local requiredJob = platineData.job
        if not requiredJob then
            return true, nil -- Pas de job défini = public
        end

        local playerJob = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name
        if playerJob == requiredJob then
            return true, nil
        else
            return false, "Réservé au job: " .. (requiredJob or "Inconnu")
        end
    end

    return true, nil
end

---Charge toutes les platines
---@param data table
local function loadPlatines(data)
    -- Nettoyer les données stockées
    PlatinesData = {}

    -- Créer les points d'interaction
    if type(data) == "table" then
        for platineId, platineData in pairs(data) do
            CreatePlatineInteraction(platineId, platineData)
        end
    end
end

-- Thread pour gérer l'interaction avec les platines (FloatingInteraction NUI)
CreateThread(function()
    while true do
        local sleep = 500

        -- Si la platine est ouverte mais le NUI n'a plus le focus, fermer proprement
        if CurrentPlatineId and not IsNuiFocused() then
            djFloatingShown = false
            djFloatingId = nil
            CurrentPlatineId = nil
        end

        if not CurrentPlatineId then
            if IsNuiFocused() then
                HideDJFloating()
            else
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local closestPlatine = nil
                local closestDistance = 2.0

                for platineId, data in pairs(PlatinesData) do
                    if data.position then
                        local distance = #(playerCoords - data.position)
                        if distance < closestDistance then
                            closestDistance = distance
                            closestPlatine = platineId
                        end
                    end
                end

                if closestPlatine then
                    sleep = 0
                    local platineInfo = PlatinesData[closestPlatine]
                    local canAccess, reason = CanAccessPlatine(platineInfo)

                    if canAccess then
                        ShowDJFloating(closestPlatine, platineInfo.position, "PLATINE DJ", platineInfo.name or "Platine DJ", {
                            { label = "Ouvrir la platine", key = "E" }
                        }, platineInfo.floatingZ)

                        if VFW.Interact.JustReleased(0, 38) then
                            CurrentPlatineId = closestPlatine
                            HideDJFloating()
                            OpenDJPlatineUI(closestPlatine)
                        end
                    else
                        ShowDJFloating(closestPlatine, platineInfo.position, "PLATINE DJ", reason or "Accès refusé", {}, platineInfo.floatingZ)
                    end
                else
                    HideDJFloating()
                end
            end
        end

        Wait(sleep)
    end
end)

-- Charger les platines au démarrage
CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(500) end

    local allPlatines = TriggerServerCallback("vfw:staff:getAllPlatines")
    local attempts = 0
    local maxAttempts = 20 -- Timeout de 10 secondes (20 * 500ms)

    while not allPlatines and attempts < maxAttempts do
        Wait(500)
        attempts = attempts + 1
        allPlatines = TriggerServerCallback("vfw:staff:getAllPlatines")
    end

    if allPlatines then
        loadPlatines(allPlatines)
    else
        console.warn("Failed to load DJ platines after " .. maxAttempts .. " attempts")
    end
end)

---@param data table
RegisterNetEvent("core:createDJPlatines", function(data)
    loadPlatines(data)
end)

---@param platineId number
RegisterNetEvent("core:deleteDJPlatine", function(platineId)
    -- Supprimer les données stockées
    PlatinesData[platineId] = nil
end)

---@param platineId number
---@param platineData table
RegisterNetEvent("core:updateDJPlatine", function(platineId, platineData)
    if not platineData then return end

    -- Mettre à jour les données stockées
    local pos = platineData.position
    PlatinesData[platineId] = {
        id = platineId,
        name = platineData.name or ("Platine #" .. platineId),
        position = vector3(pos.x, pos.y, pos.z),
        radius = platineData.radius or 50.0,
        scope = platineData.scope or "public",
        job = platineData.job or nil
    }
end)

-- ============================================
-- DJ PLATINE NUI INTERFACE
-- ============================================

local CurrentPlaylists = {}

-- ============================================
-- XSOUND AUDIO MANAGEMENT
-- ============================================

local xSound = exports.xsound

-- État des decks scopé par platine pour garantir l'indépendance
-- Format: DeckSoundsByPlatine[platineId] = { A = {...}, B = {...} }
local DeckSoundsByPlatine = {}

local function GetOrCreateDecks(platineId)
    if not platineId then return nil end
    if not DeckSoundsByPlatine[platineId] then
        DeckSoundsByPlatine[platineId] = {
            A = { soundId = nil, isPlaying = false, isPaused = false, track = nil },
            B = { soundId = nil, isPlaying = false, isPaused = false, track = nil }
        }
    end
    return DeckSoundsByPlatine[platineId]
end

local function GetDeck(platineId, deckId)
    local decks = GetOrCreateDecks(platineId)
    return decks and decks[deckId] or nil
end

-- Stockage des sons actifs de toutes les platines (pour la gestion room)
-- Format: ActivePlatineSounds[platineId][deckId] = { soundId, coords, radius, volume, isMutedByRoom }
local ActivePlatineSounds = {}
local ActiveSoundsCount = 0 -- Compteur pour optimiser le thread

-- Anti-spam : cooldowns scopés par platine pour ne pas bloquer entre platines distinctes
-- Format: ActionCooldownsByPlatine[platineId][action][deckId] = timestamp
local ActionCooldownsByPlatine = {}
local COOLDOWN_MS = {
    play = 1000,   -- 1 seconde entre chaque play
    stop = 500,    -- 500ms entre chaque stop
    pause = 300,   -- 300ms entre chaque pause
    volume = 100   -- 100ms entre chaque changement de volume (pour le slider)
}

---Vérifie si une action est en cooldown
---@param platineId number
---@param action string "play"|"stop"|"pause"|"volume"
---@param deckId string "A"|"B"
---@return boolean
local function IsActionOnCooldown(platineId, action, deckId)
    local platineCooldowns = ActionCooldownsByPlatine[platineId]
    if not platineCooldowns then return false end

    local lastTime = platineCooldowns[action] and platineCooldowns[action][deckId]
    if not lastTime then return false end

    local cooldown = COOLDOWN_MS[action] or 500
    return (GetGameTimer() - lastTime) < cooldown
end

---Enregistre le timestamp d'une action
---@param platineId number
---@param action string
---@param deckId string
local function SetActionCooldown(platineId, action, deckId)
    if not ActionCooldownsByPlatine[platineId] then
        ActionCooldownsByPlatine[platineId] = {}
    end
    if not ActionCooldownsByPlatine[platineId][action] then
        ActionCooldownsByPlatine[platineId][action] = {}
    end
    ActionCooldownsByPlatine[platineId][action][deckId] = GetGameTimer()
end

-- Nettoyage périodique des cooldowns (toutes les 5 minutes)
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes

        local now = GetGameTimer()
        for platineId, actions in pairs(ActionCooldownsByPlatine) do
            for action, decks in pairs(actions) do
                for deckId, timestamp in pairs(decks) do
                    -- Nettoyer les entrées > 10 minutes
                    if (now - timestamp) > 600000 then
                        decks[deckId] = nil
                    end
                end
            end
        end
    end
end)

-- ============================================
-- ROOM/INTERIOR OCCLUSION SYSTEM
-- ============================================

---Vérifie si le joueur est dans la même room qu'une position donnée
---@param sourcePos vector3 Position de la source audio
---@param sourceEntity? number Entité source optionnelle pour la détection de room précise
---@return boolean
local function IsPlayerInSameRoom(sourcePos, sourceEntity)
    local ped = PlayerPedId()
    local playerInterior = GetInteriorFromEntity(ped)
    local sourceInterior = GetInteriorAtCoords(sourcePos.x, sourcePos.y, sourcePos.z)

    -- Joueur dehors, source dehors = pas d'occlusion
    if playerInterior == 0 and sourceInterior == 0 then
        return true
    end

    -- Joueur dehors, source dedans = occlusion
    if playerInterior == 0 and sourceInterior ~= 0 then
        return false
    end

    -- Joueur dedans, source dehors = occlusion
    if playerInterior ~= 0 and sourceInterior == 0 then
        return false
    end

    -- Intérieurs différents = occlusion
    if playerInterior ~= sourceInterior then
        return false
    end

    -- Même intérieur : vérifier les rooms si on a l'entité source
    if sourceEntity and DoesEntityExist(sourceEntity) then
        local playerRoomHash = GetRoomKeyFromEntity(ped)
        local sourceRoomHash = GetRoomKeyFromEntity(sourceEntity)

        if playerRoomHash ~= sourceRoomHash then
            return false
        end
    end

    return true
end

---Vérifie si le joueur est dans le radius ET dans la même room
---@param sourcePos vector3 Position de la source audio
---@param radius number Rayon d'écoute
---@return boolean inRange, number volumeMultiplier (1.0 = même room, 0.15 = room différente)
local function CheckPlayerAudioEligibility(sourcePos, radius)
    local playerPos = GetEntityCoords(PlayerPedId())
    local distance = #(playerPos - sourcePos)

    local inRange = distance <= radius
    local inSameRoom = IsPlayerInSameRoom(sourcePos)

    -- Même comportement que la boombox : volume réduit à 15% si room différente
    local volumeMultiplier = inSameRoom and 1.0 or 0.15

    return inRange, volumeMultiplier
end

-- Thread de vérification de room pour mute/unmute les sons
-- Optimisé : cache le ped/interior pour réduire les appels natives
CreateThread(function()
    while true do
        -- Si aucun son actif, attendre plus longtemps
        if ActiveSoundsCount <= 0 then
            Wait(5000) -- Vérifier toutes les 5 secondes quand aucun son
        else
            Wait(500) -- Vérification toutes les 500ms quand il y a des sons

            -- Cache du ped et de l'interior pour cette frame
            local ped = PlayerPedId()
            local playerInterior = GetInteriorFromEntity(ped)
            local playerRoomHash = playerInterior ~= 0 and GetRoomKeyFromEntity(ped) or 0

            for platineId, decks in pairs(ActivePlatineSounds) do
                for deckId, soundData in pairs(decks) do
                    if soundData.soundId and xSound:soundExists(soundData.soundId) then
                        local coords = soundData.coords
                        local sourceInterior = GetInteriorAtCoords(coords.x, coords.y, coords.z)
                        local shouldBeMuted = false

                        -- Joueur dehors, source dehors = pas d'occlusion
                        if playerInterior == 0 and sourceInterior == 0 then
                            shouldBeMuted = false
                        -- Joueur dehors, source dedans = occlusion
                        elseif playerInterior == 0 and sourceInterior ~= 0 then
                            shouldBeMuted = true
                        -- Joueur dedans, source dehors = occlusion
                        elseif playerInterior ~= 0 and sourceInterior == 0 then
                            shouldBeMuted = true
                        -- Intérieurs différents = occlusion
                        elseif playerInterior ~= sourceInterior then
                            shouldBeMuted = true
                        -- Même intérieur = vérifier les rooms si entité disponible
                        elseif playerRoomHash ~= 0 and soundData.entity and DoesEntityExist(soundData.entity) then
                            local sourceRoomHash = GetRoomKeyFromEntity(soundData.entity)
                            shouldBeMuted = (playerRoomHash ~= sourceRoomHash)
                        end
                        -- Note: Sans entité (platines), on ne peut pas vérifier les rooms précises
                        -- La vérification d'intérieur suffit

                        -- Appliquer le multiplicateur de volume (comme la boombox)
                        local newMultiplier = shouldBeMuted and 0.15 or 1.0
                        if newMultiplier ~= (soundData.currentMultiplier or 1.0) then
                            local effectiveVolume = soundData.volume * newMultiplier
                            xSound:setVolumeMax(soundData.soundId, effectiveVolume)
                            xSound:setVolume(soundData.soundId, effectiveVolume)
                            soundData.currentMultiplier = newMultiplier
                            soundData.isMutedByRoom = shouldBeMuted
                        end
                    end
                end
            end
        end
    end
end)

---Générer un ID unique pour un son
---@param deckId string "A" ou "B"
---@return string
local function GenerateSoundId(deckId)
    return string.format("djplatine_%s_%s_%d", CurrentPlatineId or 0, deckId, math.random(1000, 9999))
end

---Obtenir le rayon de la platine actuelle
---@return number
local function GetCurrentPlatineRadius()
    if CurrentPlatineId and PlatinesData[CurrentPlatineId] then
        return PlatinesData[CurrentPlatineId].radius or 50.0
    end
    return 50.0
end

---Obtenir la position de la platine actuelle
---@return vector3|nil
local function GetCurrentPlatinePosition()
    if CurrentPlatineId and PlatinesData[CurrentPlatineId] then
        local pos = PlatinesData[CurrentPlatineId].position
        if pos then
            return vector3(pos.x, pos.y, pos.z)
        end
    end
    return GetEntityCoords(PlayerPedId())
end

---Jouer un son sur un deck
---@param deckId string "A" ou "B"
---@param track table { url: string, title: string, duration: number }
---@param volume number 0-100
---@return boolean success
local function PlayDeckSound(deckId, track, volume)
    if not CurrentPlatineId then return false end
    local deck = GetDeck(CurrentPlatineId, deckId)
    if not deck then return false end

    -- Anti-spam : vérifier le cooldown
    if IsActionOnCooldown(CurrentPlatineId, "play", deckId) then
        return false
    end
    SetActionCooldown(CurrentPlatineId, "play", deckId)

    -- Stopper l'ancien son s'il existe (localement, pas de server event)
    if deck.soundId and xSound:soundExists(deck.soundId) then
        xSound:Destroy(deck.soundId)
    end

    -- Générer un nouvel ID
    local soundId = GenerateSoundId(deckId)
    local coords = GetCurrentPlatinePosition()
    local radius = GetCurrentPlatineRadius()
    local vol = (volume or 75) / 100.0

    -- Jouer le son via serveur pour synchroniser tous les joueurs (avec titre)
    TriggerServerEvent("vfw:djplatine:playSound", CurrentPlatineId, deckId, soundId, track.url, vol, coords, radius, track.title)

    -- Mettre à jour l'état local
    deck.soundId = soundId
    deck.isPlaying = true
    deck.isPaused = false
    deck.track = track

    return true
end

---Changer le son sur un deck (utilisé par le bouton Change)
---@param deckId string "A" ou "B"
---@param track table { url: string, title: string, duration: number }
---@param volume number 0-100
---@return boolean success
local function ChangeDeckSound(deckId, track, volume)
    return PlayDeckSound(deckId, track, volume)
end

---Stopper un deck
---@param deckId string "A" ou "B"
---@return boolean success
local function StopDeckSound(deckId)
    if not CurrentPlatineId then return false end
    local deck = GetDeck(CurrentPlatineId, deckId)
    if not deck or not deck.soundId then return false end

    -- Anti-spam : vérifier le cooldown
    if IsActionOnCooldown(CurrentPlatineId, "stop", deckId) then
        return false
    end
    SetActionCooldown(CurrentPlatineId, "stop", deckId)

    TriggerServerEvent("vfw:djplatine:stopSound", CurrentPlatineId, deckId, deck.soundId)

    deck.isPlaying = false
    deck.isPaused = false
    deck.track = nil

    return true
end

---Pause/Resume un deck
---@param deckId string "A" ou "B"
---@return boolean success
local function TogglePauseDeck(deckId)
    if not CurrentPlatineId then return false end
    local deck = GetDeck(CurrentPlatineId, deckId)
    if not deck or not deck.soundId then return false end

    -- Anti-spam : vérifier le cooldown
    if IsActionOnCooldown(CurrentPlatineId, "pause", deckId) then
        return false
    end
    SetActionCooldown(CurrentPlatineId, "pause", deckId)

    -- Récupérer le timestamp actuel si on met en pause
    local currentTime = 0
    if not deck.isPaused and xSound:soundExists(deck.soundId) then
        currentTime = xSound:getTimeStamp(deck.soundId) or 0
    end

    TriggerServerEvent("vfw:djplatine:pauseSound", CurrentPlatineId, deckId, deck.soundId, currentTime)
    deck.isPaused = not deck.isPaused
    deck.isPlaying = not deck.isPaused

    return true
end

---Changer le volume d'un deck
---@param deckId string "A" ou "B"
---@param volume number 0-100
---@return boolean success
local function SetDeckVolume(deckId, volume)
    if not CurrentPlatineId then return false end
    local deck = GetDeck(CurrentPlatineId, deckId)
    if not deck or not deck.soundId then return false end

    -- Anti-spam : vérifier le cooldown (plus court pour le volume)
    if IsActionOnCooldown(CurrentPlatineId, "volume", deckId) then
        return false
    end
    SetActionCooldown(CurrentPlatineId, "volume", deckId)

    TriggerServerEvent("vfw:djplatine:volumeSound", CurrentPlatineId, deckId, deck.soundId, volume)

    return true
end

--- Envoyer une mise a jour du deck a l'UI si le menu de cette platine est ouvert
---@param platineId number
---@param deckId string
---@param updates table
local function SendDeckUpdate(platineId, deckId, updates)
    if CurrentPlatineId ~= platineId then return end
    SendNUIMessage({
        action = "nui:djplatine:deckUpdate",
        data = { deckId = deckId, updates = updates }
    })
end

-- Events pour synchroniser les sons (reçus du serveur)
RegisterNetEvent("vfw:djplatine:playSound", function(platineId, deckId, soundId, url, volume, coords, radius, title)
    -- Convertir coords en vector3 si nécessaire
    local soundCoords = type(coords) == "vector3" and coords or vector3(coords.x, coords.y, coords.z)

    -- Détruire l'ancien son s'il existe (et décrémenter le compteur)
    if ActivePlatineSounds[platineId] and ActivePlatineSounds[platineId][deckId] then
        local oldSoundId = ActivePlatineSounds[platineId][deckId].soundId
        if oldSoundId and xSound:soundExists(oldSoundId) then
            xSound:Destroy(oldSoundId)
        end
        ActiveSoundsCount = math.max(0, ActiveSoundsCount - 1)
    end

    -- Vérifier room occlusion : volume réduit si room différente (comme la boombox)
    local inSameRoom = IsPlayerInSameRoom(soundCoords)
    local volumeMultiplier = inSameRoom and 1.0 or 0.15
    local effectiveVolume = volume * volumeMultiplier

    xSound:PlayUrlPos(soundId, url, effectiveVolume, soundCoords)
    xSound:Distance(soundId, radius)
    xSound:setVolumeMax(soundId, effectiveVolume)
    xSound:setVolume(soundId, effectiveVolume)

    -- Enregistrer dans ActivePlatineSounds pour le système de room (avec titre)
    if not ActivePlatineSounds[platineId] then
        ActivePlatineSounds[platineId] = {}
    end
    ActivePlatineSounds[platineId][deckId] = {
        soundId = soundId,
        coords = soundCoords,
        radius = radius,
        volume = volume,
        title = title or "Lecture directe",
        url = url,
        currentMultiplier = volumeMultiplier,
        isMutedByRoom = not inSameRoom
    }
    ActiveSoundsCount = ActiveSoundsCount + 1

    -- Mettre à jour l'état local de cette platine
    local deck = GetDeck(platineId, deckId)
    if deck then
        deck.soundId = soundId
        deck.isPlaying = true
        deck.isPaused = false
        deck.track = { title = title or "Lecture directe", url = url }
    end

    SendDeckUpdate(platineId, deckId, {
        isPlaying = true,
        isPaused = false,
        volume = (volume or 0.75) * 100,
        currentTime = 0,
        track = { title = title or "Lecture directe", url = url }
    })
end)

RegisterNetEvent("vfw:djplatine:stopSound", function(platineId, deckId, soundId)
    if xSound:soundExists(soundId) then
        xSound:Destroy(soundId)
    end

    -- Retirer de ActivePlatineSounds et décrémenter le compteur
    if ActivePlatineSounds[platineId] and ActivePlatineSounds[platineId][deckId] then
        ActivePlatineSounds[platineId][deckId] = nil
        ActiveSoundsCount = math.max(0, ActiveSoundsCount - 1)
    end

    local deck = GetDeck(platineId, deckId)
    if deck then
        deck.soundId = nil
        deck.isPlaying = false
        deck.isPaused = false
        deck.track = nil
    end

    SendDeckUpdate(platineId, deckId, {
        isPlaying = false,
        isPaused = false,
        currentTime = 0,
        track = nil
    })
end)

RegisterNetEvent("vfw:djplatine:pauseSound", function(platineId, deckId, soundId, action, resumeTime)
    if xSound:soundExists(soundId) then
        if action == "pause" then
            xSound:Pause(soundId)
        elseif action == "resume" then
            xSound:Resume(soundId)
            if resumeTime and resumeTime > 0 then
                -- Le son est deja charge (Resume), donc setTimeStamp est immediat
                xSound:setTimeStamp(soundId, resumeTime)
            end
        end
    end

    -- Toujours mettre a jour l'etat local + UI, meme si le son n'existe pas
    -- (cas: joueur arrivant dans le radius juste apres une pause)
    local deck = GetDeck(platineId, deckId)
    if deck then
        if action == "pause" then
            deck.isPaused = true
            deck.isPlaying = false
        elseif action == "resume" then
            deck.isPaused = false
            deck.isPlaying = true
        end
    end

    if action == "pause" then
        SendDeckUpdate(platineId, deckId, { isPlaying = false, isPaused = true })
    elseif action == "resume" then
        SendDeckUpdate(platineId, deckId, { isPlaying = true, isPaused = false })
    end
end)

RegisterNetEvent("vfw:djplatine:volumeSound", function(platineId, deckId, soundId, volume)
    local vol = volume / 100.0

    if xSound:soundExists(soundId) then
        if ActivePlatineSounds[platineId] and ActivePlatineSounds[platineId][deckId] then
            ActivePlatineSounds[platineId][deckId].volume = vol

            if not ActivePlatineSounds[platineId][deckId].isMutedByRoom then
                xSound:setVolumeMax(soundId, vol)
                xSound:setVolume(soundId, vol)
            end
        else
            xSound:setVolumeMax(soundId, vol)
            xSound:setVolume(soundId, vol)
        end
    end

    SendDeckUpdate(platineId, deckId, { volume = volume })
end)

--- Sync platine pour les joueurs qui rejoignent (avec timestamp et titre)
RegisterNetEvent("vfw:djplatine:syncJoin", function(platineId, deckId, soundId, url, volume, coords, radius, currentTime, title)
    local soundCoords = type(coords) == "vector3" and coords or vector3(coords.x, coords.y, coords.z)
    local mycoords = GetEntityCoords(PlayerPedId())
    local distance = #(mycoords - soundCoords)

    if distance < (radius + 50.0) then
        local inSameRoom = IsPlayerInSameRoom(soundCoords)
        local volumeMultiplier = inSameRoom and 1.0 or 0.15
        local effectiveVolume = volume * volumeMultiplier

        xSound:PlayUrlPos(soundId, url, effectiveVolume, soundCoords)
        xSound:Distance(soundId, radius)
        xSound:setVolumeMax(soundId, effectiveVolume)
        xSound:setVolume(soundId, effectiveVolume)

        -- Seek une fois le son charge (YouTube/stream prend du temps a charger)
        if currentTime > 0 then
            xSound:onLoading(soundId, function()
                if xSound:soundExists(soundId) then
                    xSound:setTimeStamp(soundId, currentTime)
                end
            end)
        end

        -- Enregistrer pour le monitoring de room (avec titre)
        if not ActivePlatineSounds[platineId] then
            ActivePlatineSounds[platineId] = {}
        end
        ActivePlatineSounds[platineId][deckId] = {
            soundId = soundId,
            coords = soundCoords,
            radius = radius,
            volume = volume,
            title = title or "Lecture directe",
            url = url,
            currentMultiplier = volumeMultiplier,
            isMutedByRoom = not inSameRoom
        }
        ActiveSoundsCount = ActiveSoundsCount + 1
    end
end)

---Lance localement un deck a partir d'un etat serveur (si pas deja actif).
---Utilise pour la sync a l'ouverture du menu et la sync de proximite.
---@param platineId number
---@param deckId string "A" ou "B"
---@param deckData table { soundId, url, volume, coords, radius, title, isPaused, currentTime }
local function SyncPlatineDeck(platineId, deckId, deckData)
    if not deckData or not deckData.soundId or not deckData.url then return end
    if xSound:soundExists(deckData.soundId) then return end -- deja actif

    local rawCoords = deckData.coords
    if not rawCoords then return end
    local soundCoords = type(rawCoords) == "vector3" and rawCoords or vector3(rawCoords.x, rawCoords.y, rawCoords.z)

    local inSameRoom = IsPlayerInSameRoom(soundCoords)
    local volumeMultiplier = inSameRoom and 1.0 or 0.15
    local volume = deckData.volume or 0.75
    local radius = deckData.radius or 50.0
    local effectiveVolume = volume * volumeMultiplier
    local soundId = deckData.soundId
    local currentTime = deckData.currentTime or 0
    local isPaused = deckData.isPaused

    xSound:PlayUrlPos(soundId, deckData.url, effectiveVolume, soundCoords)
    xSound:Distance(soundId, radius)
    xSound:setVolumeMax(soundId, effectiveVolume)
    xSound:setVolume(soundId, effectiveVolume)

    -- Attendre que le son soit charge avant de seek (sinon YouTube/stream seek a 0)
    if currentTime > 0 or isPaused then
        xSound:onLoading(soundId, function()
            if not xSound:soundExists(soundId) then return end
            if currentTime > 0 then
                xSound:setTimeStamp(soundId, currentTime)
            end
            if isPaused then
                xSound:Pause(soundId)
            end
        end)
    end

    if not ActivePlatineSounds[platineId] then
        ActivePlatineSounds[platineId] = {}
    end
    ActivePlatineSounds[platineId][deckId] = {
        soundId = deckData.soundId,
        coords = soundCoords,
        radius = radius,
        volume = volume,
        title = deckData.title or "Lecture directe",
        url = deckData.url,
        currentMultiplier = volumeMultiplier,
        isMutedByRoom = not inSameRoom
    }
    ActiveSoundsCount = ActiveSoundsCount + 1
end

--- Ouvrir l'interface DJ Platine
---@param platineId number
function OpenDJPlatineUI(platineId)
    CurrentPlatineId = platineId

    -- Récupérer les données de la platine
    local platineInfo = PlatinesData[platineId] or {}

    -- Charger les playlists de cette platine
    local playlists = TriggerServerCallback("vfw:djplatine:getPlaylists", platineId) or {}
    CurrentPlaylists = {}

    for _, playlist in ipairs(playlists) do
        CurrentPlaylists[playlist.id] = {
            id = playlist.id,
            name = playlist.name,
            track_count = playlist.track_count or 0,
            tracks = {}
        }
    end

    -- Récupérer l'état actuel des decks depuis le serveur
    local serverDeckState = TriggerServerCallback("vfw:djplatine:getDeckState", platineId)
    local deckA = nil
    local deckB = nil

    -- Forcer la création/reset des slots pour cette platine (évite tout résidu)
    DeckSoundsByPlatine[platineId] = {
        A = { soundId = nil, isPlaying = false, isPaused = false, track = nil },
        B = { soundId = nil, isPlaying = false, isPaused = false, track = nil }
    }
    local decks = DeckSoundsByPlatine[platineId]

    local function applyDeck(serverDeck)
        if not serverDeck then return nil end
        return {
            isPlaying = not serverDeck.isPaused,
            isPaused = serverDeck.isPaused or false,
            volume = (serverDeck.volume or 0.75) * 100,
            currentTime = serverDeck.currentTime or 0,
            track = serverDeck.title and { title = serverDeck.title, url = serverDeck.url } or nil
        }
    end

    if serverDeckState then
        if serverDeckState["A"] then
            local deckData = serverDeckState["A"]
            deckA = applyDeck(deckData)
            decks.A.isPlaying = deckA.isPlaying
            decks.A.isPaused = deckA.isPaused
            decks.A.soundId = deckData.soundId
            decks.A.track = deckA.track
            SyncPlatineDeck(platineId, "A", deckData)
        end
        if serverDeckState["B"] then
            local deckData = serverDeckState["B"]
            deckB = applyDeck(deckData)
            decks.B.isPlaying = deckB.isPlaying
            decks.B.isPaused = deckB.isPaused
            decks.B.soundId = deckData.soundId
            decks.B.track = deckB.track
            SyncPlatineDeck(platineId, "B", deckData)
        end
    end

    VFW.Nui.Focus(true, false)
    SendNUIMessage({
        action = "nui:djplatine:show",
        data = true
    })
    SendNUIMessage({
        action = "nui:djplatine:init",
        data = {
            platineId = platineId,
            platineName = platineInfo.name or ("Platine #" .. platineId),
            radius = platineInfo.radius or 50.0,
            playlists = playlists,
            deckA = deckA,
            deckB = deckB
        }
    })
end

--- Fermer l'interface DJ Platine
function CloseDJPlatineUI()
    -- Purger l'état UI local de la platine fermée pour éviter tout résidu
    -- (les sons effectifs restent gérés via ActivePlatineSounds)
    if CurrentPlatineId then
        DeckSoundsByPlatine[CurrentPlatineId] = nil
    end
    CurrentPlatineId = nil
    VFW.Nui.Focus(false, false)
    SendNUIMessage({
        action = "nui:djplatine:show",
        data = false
    })
end

-- NUI Callbacks
RegisterNUICallback("nui:djplatine:close", function(data, cb)
    CloseDJPlatineUI()
    cb({})
end)

RegisterNUICallback("nui:djplatine:getPlaylists", function(data, cb)
    if not CurrentPlatineId then
        cb({ playlists = {} })
        return
    end

    local playlists = TriggerServerCallback("vfw:djplatine:getPlaylists", CurrentPlatineId) or {}
    cb({ playlists = playlists })
end)

RegisterNUICallback("nui:djplatine:getPlaylistTracks", function(data, cb)
    if not data.playlistId then
        cb({ tracks = {} })
        return
    end

    local tracks = TriggerServerCallback("vfw:djplatine:getPlaylistTracks", data.playlistId) or {}
    cb({ tracks = tracks })
end)

RegisterNUICallback("nui:djplatine:createPlaylist", function(data, cb)
    if not CurrentPlatineId then
        cb({ success = false, error = "Platine non sélectionnée" })
        return
    end

    -- Validation du nom
    if not data.name or type(data.name) ~= "string" then
        cb({ success = false, error = "Ce nom n'est pas valide" })
        return
    end

    local name = data.name:gsub("^%s+", ""):gsub("%s+$", "") -- Trim
    if #name < 1 or #name > 100 then
        cb({ success = false, error = "Nom doit faire 1-100 caractères" })
        return
    end

    TriggerServerEvent("vfw:djplatine:createPlaylist", CurrentPlatineId, name)
    cb({ success = true })
end)

RegisterNUICallback("nui:djplatine:deletePlaylist", function(data, cb)
    if not CurrentPlatineId or not data.playlistId then
        cb({ success = false })
        return
    end

    -- Validation de l'ID
    if type(data.playlistId) ~= "number" then
        cb({ success = false, error = "Cet ID playlist n'est pas valide" })
        return
    end

    TriggerServerEvent("vfw:djplatine:deletePlaylist", CurrentPlatineId, data.playlistId)
    cb({ success = true })
end)

RegisterNUICallback("nui:djplatine:addTrack", function(data, cb)
    if not CurrentPlatineId or not data.playlistId or not data.track then
        cb({ success = false })
        return
    end

    -- Validation des données du track
    local track = data.track
    if type(track) ~= "table" then
        cb({ success = false, error = "Ces données track ne sont pas valides" })
        return
    end

    if not track.url or type(track.url) ~= "string" or #track.url < 10 or #track.url > 500 then
        cb({ success = false, error = "Cette URL n'est pas valide (10-500 caractères)" })
        return
    end

    if not track.title or type(track.title) ~= "string" or #track.title < 1 or #track.title > 200 then
        cb({ success = false, error = "Ce titre n'est pas valide (1-200 caractères)" })
        return
    end

    TriggerServerEvent("vfw:djplatine:addTrack", CurrentPlatineId, data.playlistId, {
        url = track.url,
        title = track.title,
        duration = tonumber(track.duration) or 180
    })
    cb({ success = true })
end)

RegisterNUICallback("nui:djplatine:deleteTrack", function(data, cb)
    if not CurrentPlatineId or not data.playlistId or not data.trackId then
        cb({ success = false })
        return
    end

    TriggerServerEvent("vfw:djplatine:deleteTrack", CurrentPlatineId, data.playlistId, data.trackId)
    cb({ success = true })
end)

--- Récupérer les métadonnées d'une URL (titre, durée)
RegisterNUICallback("nui:djplatine:getUrlMetadata", function(data, cb)
    if not data.url or data.url == "" then
        cb({ success = false, error = "URL manquante" })
        return
    end

    local metadata = TriggerServerCallback("vfw:djplatine:getUrlMetadata", data.url)
    if metadata then
        cb({ success = true, metadata = metadata })
    else
        cb({ success = false, error = "Impossible de récupérer les métadonnées" })
    end
end)

-- ============================================
-- NUI CALLBACKS - AUDIO CONTROLS
-- ============================================

---Jouer une piste sur un deck
RegisterNUICallback("nui:djplatine:play", function(data, cb)
    if not CurrentPlatineId or not data.deckId or not data.track then
        cb({ success = false })
        return
    end

    local track = {
        url = data.track.url,
        title = data.track.title,
        duration = data.track.duration or 180
    }

    PlayDeckSound(data.deckId, track, data.volume or 75)
    cb({ success = true })
end)

---Changer la piste sur un deck (bouton Change)
RegisterNUICallback("nui:djplatine:changeSound", function(data, cb)
    if not CurrentPlatineId or not data.deckId or not data.track then
        cb({ success = false })
        return
    end

    local track = {
        url = data.track.url,
        title = data.track.title,
        duration = data.track.duration or 180
    }

    ChangeDeckSound(data.deckId, track, data.volume or 75)
    cb({ success = true })
end)

---Stopper un deck
RegisterNUICallback("nui:djplatine:stop", function(data, cb)
    if not CurrentPlatineId or not data.deckId then
        cb({ success = false })
        return
    end

    StopDeckSound(data.deckId)
    cb({ success = true })
end)

---Pause/Resume un deck
RegisterNUICallback("nui:djplatine:togglePause", function(data, cb)
    if not CurrentPlatineId or not data.deckId then
        cb({ success = false })
        return
    end

    TogglePauseDeck(data.deckId)
    cb({ success = true })
end)

---Seek dans un deck
RegisterNUICallback("nui:djplatine:seek", function(data, cb)
    if not CurrentPlatineId or not data.deckId or not data.time then
        cb({ success = false })
        return
    end

    local deck = GetDeck(CurrentPlatineId, data.deckId)
    if deck and deck.soundId and deck.isPlaying then
        TriggerServerEvent("vfw:djplatine:seekSound", CurrentPlatineId, data.deckId, deck.soundId, data.time)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

-- Réception du seek synchronisé depuis le serveur
RegisterNetEvent("vfw:djplatine:seekSound", function(platineId, deckId, soundId, time)
    if xSound:soundExists(soundId) then
        xSound:setTimeStamp(soundId, time)
    end

    local deck = GetDeck(platineId, deckId)
    if deck then
        deck.currentTime = time
    end
end)

---Changer le volume d'un deck
RegisterNUICallback("nui:djplatine:setVolume", function(data, cb)
    if not CurrentPlatineId or not data.deckId or not data.volume then
        cb({ success = false })
        return
    end

    SetDeckVolume(data.deckId, data.volume)
    cb({ success = true })
end)

-- Synchronisation Events (reçus de tous les joueurs)
RegisterNetEvent("vfw:djplatine:playlistCreated", function(platineId, playlist)
    if CurrentPlatineId == platineId then
        SendNUIMessage({
            action = "nui:djplatine:playlistCreated",
            data = playlist
        })
    end
end)

RegisterNetEvent("vfw:djplatine:playlistDeleted", function(platineId, playlistId)
    if CurrentPlatineId == platineId then
        SendNUIMessage({
            action = "nui:djplatine:playlistDeleted",
            data = { playlistId = playlistId }
        })
    end
end)

RegisterNetEvent("vfw:djplatine:trackAdded", function(platineId, playlistId, track)
    if CurrentPlatineId == platineId then
        SendNUIMessage({
            action = "nui:djplatine:trackAdded",
            data = {
                playlistId = playlistId,
                track = track
            }
        })
    end
end)

RegisterNetEvent("vfw:djplatine:trackDeleted", function(platineId, playlistId, trackId)
    if CurrentPlatineId == platineId then
        SendNUIMessage({
            action = "nui:djplatine:trackDeleted",
            data = {
                playlistId = playlistId,
                trackId = trackId
            }
        })
    end
end)

RegisterNetEvent("vfw:djplatine:tracksReordered", function(platineId, playlistId, trackOrder)
    if CurrentPlatineId == platineId then
        SendNUIMessage({
            action = "nui:djplatine:tracksReordered",
            data = {
                playlistId = playlistId,
                trackOrder = trackOrder
            }
        })
    end
end)

-- ============================================
-- THREAD DE MISE À JOUR DU TEMPS DE LECTURE
-- ============================================

CreateThread(function()
    while true do
        Wait(500) -- Mise à jour toutes les 500ms

        -- Seulement si l'interface est ouverte
        if CurrentPlatineId then
            local updates = {}
            local hasUpdates = false
            local decks = DeckSoundsByPlatine[CurrentPlatineId]

            if decks then
                for deckId, deck in pairs(decks) do
                    if deck.soundId and deck.isPlaying and not deck.isPaused then
                        if xSound:soundExists(deck.soundId) then
                            local currentTime = xSound:getTimeStamp(deck.soundId) or 0
                            local duration = xSound:getMaxDuration(deck.soundId) or 0

                            updates[deckId] = {
                                currentTime = currentTime,
                                duration = duration -- Toujours envoyer, même si 0
                            }
                            hasUpdates = true
                        end
                    end
                end
            end

            if hasUpdates then
                SendNUIMessage({
                    action = "nui:djplatine:timeUpdate",
                    data = updates
                })
            end
        end
    end
end)

-- Export pour ouvrir depuis d'autres scripts
exports("OpenDJPlatineUI", OpenDJPlatineUI)
exports("CloseDJPlatineUI", CloseDJPlatineUI)

-- ============================================
-- THREAD DE SYNC PROXIMITE
-- ============================================
-- Quand un joueur entre dans le radius d'une platine en cours de lecture,
-- recupere son etat depuis le serveur et lance le son localement.

local ProximityCheckedPlatines = {} -- [platineId] = true tant que dans le radius

CreateThread(function()
    Wait(5000) -- Laisser le temps aux platines de charger au join
    while true do
        Wait(2500)

        local playerPed = PlayerPedId()
        if playerPed ~= 0 and DoesEntityExist(playerPed) then
            local playerCoords = GetEntityCoords(playerPed)

            for platineId, platineData in pairs(PlatinesData) do
                local pos = platineData.position
                local radius = platineData.radius or 50.0
                if pos then
                    local distance = #(playerCoords - pos)
                    local inRange = distance <= (radius + 25.0)

                    if inRange then
                        if not ProximityCheckedPlatines[platineId] then
                            ProximityCheckedPlatines[platineId] = true
                            local existing = ActivePlatineSounds[platineId]
                            local needsSync = true
                            if existing and (existing["A"] or existing["B"]) then
                                local hasActiveSound = false
                                for _, deckSound in pairs(existing) do
                                    if deckSound.soundId and xSound:soundExists(deckSound.soundId) then
                                        hasActiveSound = true
                                        break
                                    end
                                end
                                needsSync = not hasActiveSound
                            end

                            if needsSync then
                                local pid = platineId
                                CreateThread(function()
                                    local serverState = TriggerServerCallback("vfw:djplatine:getDeckState", pid)
                                    if serverState then
                                        for deckId, deckData in pairs(serverState) do
                                            SyncPlatineDeck(pid, deckId, deckData)
                                        end
                                    end
                                end)
                            end
                        end
                    else
                        ProximityCheckedPlatines[platineId] = nil
                    end
                end
            end
        end
    end
end)

-- Nettoyage des sons lors de l'arrêt de la ressource
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Détruire tous les sons actifs
        for platineId, decks in pairs(ActivePlatineSounds) do
            for deckId, soundData in pairs(decks) do
                if soundData.soundId and xSound:soundExists(soundData.soundId) then
                    xSound:Destroy(soundData.soundId)
                end
            end
        end
        ActivePlatineSounds = {}
        ActiveSoundsCount = 0
    end
end)
