---@meta _
---@diagnostic disable: duplicate-doc-field

local BoomBox = {
    open = false,
    Volume = 0.7,
    holdingboom = false,
    currentEntity = nil,
    currentMusicId = nil,
    mode = nil,
    isGroundInteraction = false,
    isPickingUp = false,
    queue = {},
    queueIndex = 0,
    shuffle = false,
}
local xSound = exports.xsound

--region ------ SYSTÈME DE COOLDOWNS (ANTI-SPAM) ------

-- Cooldowns par action et par musicId
local ActionCooldowns = {
    play = {},      -- [musicId] = lastTimestamp
    stop = {},
    pause = {},
    volume = {},
    seek = {}
}

-- Durées des cooldowns en millisecondes
local COOLDOWN_MS = {
    play = 1000,    -- 1 seconde entre chaque play
    stop = 500,     -- 500ms entre chaque stop
    pause = 300,    -- 300ms entre chaque pause/resume
    volume = 100,   -- 100ms entre chaque changement de volume
    seek = 200      -- 200ms entre chaque seek
}

-- Timestamp du dernier cleanup des cooldowns
local LastCooldownCleanup = 0
local CLEANUP_INTERVAL = 60000 -- Nettoyer toutes les 60 secondes

--- Nettoie les cooldowns expirés (évite memory leak)
local function CleanupExpiredCooldowns()
    local now = GetGameTimer()
    if (now - LastCooldownCleanup) < CLEANUP_INTERVAL then return end
    LastCooldownCleanup = now

    for action, cooldowns in pairs(ActionCooldowns) do
        local maxCooldown = COOLDOWN_MS[action] or 500
        for identifier, timestamp in pairs(cooldowns) do
            if (now - timestamp) > maxCooldown * 2 then
                cooldowns[identifier] = nil
            end
        end
    end
end

--- Vérifie si une action est en cooldown
---@param action string Type d'action (play, stop, pause, volume, seek)
---@param identifier string Identifiant (musicId, netId, etc.)
---@return boolean True si l'action est en cooldown
local function IsActionOnCooldown(action, identifier)
    CleanupExpiredCooldowns() -- Cleanup périodique
    local lastTime = ActionCooldowns[action] and ActionCooldowns[action][identifier]
    if not lastTime then return false end
    return (GetGameTimer() - lastTime) < (COOLDOWN_MS[action] or 500)
end

--- Définit le timestamp d'une action
---@param action string Type d'action
---@param identifier string Identifiant
local function SetActionCooldown(action, identifier)
    if not ActionCooldowns[action] then
        ActionCooldowns[action] = {}
    end
    ActionCooldowns[action][identifier] = GetGameTimer()
end

--endregion

-- Forward declarations (fonctions définies plus bas mais utilisées plus haut)
local FuncUpdatePosition
local StartCarryControlThread

--region ------ SAFE ASYNC LOADERS ------

--- Attend le controle d'une entite avec timeout
---@param entity number Entity handle
---@param maxAttempts number|nil Nombre max de tentatives (defaut: 100)
---@return boolean True si le controle a ete obtenu
local function WaitForEntityControl(entity, maxAttempts)
    maxAttempts = maxAttempts or 100
    local attempts = 0
    while not NetworkHasControlOfEntity(entity) and attempts < maxAttempts do
        Wait(10)
        if not DoesEntityExist(entity) then return false end
        NetworkRequestControlOfEntity(entity)
        attempts = attempts + 1
    end
    return NetworkHasControlOfEntity(entity)
end

--- Charge un modele avec timeout
---@param model number|string Model hash
---@param timeout number|nil Timeout en ms (defaut: 5000)
---@return boolean True si le modele a ete charge
local function LoadModelAsync(model, timeout)
    timeout = timeout or 5000
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local startTime = GetGameTimer()
    while not HasModelLoaded(model) do
        if (GetGameTimer() - startTime) > timeout then return false end
        Wait(10)
    end
    return true
end

--- Charge un dictionnaire d'animations avec timeout
---@param dict string Nom du dictionnaire
---@param timeout number|nil Timeout en ms (defaut: 5000)
---@return boolean True si le dict a ete charge
local function LoadAnimDictAsync(dict, timeout)
    timeout = timeout or 5000
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local startTime = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        if (GetGameTimer() - startTime) > timeout then return false end
        Wait(10)
    end
    return true
end

--endregion

--region ------ ROOM OCCLUSION (INTÉRIEURS) ------

--- Vérifie si le joueur est dans la même pièce que la source sonore
---@param sourcePos vector3 Position de la source sonore
---@return boolean True si le joueur est dans la même pièce
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

--- Vérifie si le joueur peut entendre un son (distance + room)
---@param soundPos vector3 Position du son
---@param maxDistance number Distance maximale d'écoute
---@param sourceEntity? number Entité source optionnelle pour la détection de room précise
---@return boolean canHear, number volumeMultiplier
local function CheckPlayerAudioEligibility(soundPos, maxDistance, sourceEntity)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - soundPos)

    if distance > maxDistance then
        return false, 0.0
    end

    local sameRoom = IsPlayerInSameRoom(soundPos, sourceEntity)

    if sameRoom then
        return true, 1.0
    else
        -- Dans une pièce différente = volume réduit drastiquement
        return true, 0.15
    end
end

--endregion

-- Compteur de sons actifs et cache pour le monitoring de room occlusion
local ActiveBoomboxCount = 0
local ActiveBoomboxSounds = {} -- [musicId] = { coords, baseVolume, currentMultiplier, entity }

--- Extrait l'entite depuis un musicId au format 'id_<netId>' (stable cross-client)
---@param musicId string
---@return number|nil
local function GetEntityFromMusicId(musicId)
    if type(musicId) ~= "string" then return nil end
    local netId = tonumber(musicId:match("^id_(%d+)$"))
    if not netId then return nil end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end
    return nil
end

--- Construit le musicId stable a partir d'une entite boombox (utilise le netId, identique sur tous les clients)
---@param entity number Entity handle local
---@return string|nil musicId, number|nil netId
local function GetBoomboxMusicId(entity)
    if not entity or entity == 0 or entity == -1 then return nil end
    if not DoesEntityExist(entity) then return nil end
    if not NetworkGetEntityIsNetworked(entity) then return nil end
    local netId = NetworkGetNetworkIdFromEntity(entity)
    if not netId or netId == 0 then return nil end
    return 'id_' .. netId, netId
end

--- Attend que l'entite soit registered comme networked et retourne son netId
---@param entity number
---@param timeout number|nil ms
---@return number|nil netId
local function WaitForNetId(entity, timeout)
    timeout = timeout or 2000
    local start = GetGameTimer()
    while GetGameTimer() - start < timeout do
        if not DoesEntityExist(entity) then return nil end
        if NetworkGetEntityIsNetworked(entity) then
            local netId = NetworkGetNetworkIdFromEntity(entity)
            if netId and netId ~= 0 then return netId end
        end
        Wait(0)
    end
    return nil
end

--region ------ SYSTÈME DE MUSIQUE VÉHICULE AVEC FENÊTRES ------

-- Configuration des distances de son
local SOUND_DISTANCE_CLOSED = 3.0    -- Fenêtres fermées = son très faible dehors
local SOUND_DISTANCE_OPEN = 15.0     -- Fenêtres ouvertes = 15m de portée
local MIN_SOUND_DISTANCE = 10.0      -- Distance minimale du son (volume bas)
local MAX_SOUND_DISTANCE = 40.0      -- Distance maximale du son (volume max)

-- Cache des véhicules avec musique active
local VehicleMusicActive = {} -- [netId] = { musicId, url, volume, vehicle }

--- Vérifie si le son doit sortir du véhicule (fenêtres/portes ouvertes ou cassées)
---@param vehicle number Le véhicule à vérifier
---@return boolean True si le son doit être audible à l'extérieur
local function ShouldSoundLeakFromVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    -- 1. Vérifier fenêtres cassées (0-3 = 4 fenêtres principales)
    for i = 0, 3 do
        if not IsVehicleWindowIntact(vehicle, i) then
            return true
        end
    end

    -- 2. Vérifier portes ouvertes (0-3 = 4 portes)
    for i = 0, 3 do
        if GetVehicleDoorAngleRatio(vehicle, i) > 0.1 then
            return true
        end
    end

    -- 3. Vérifier fenêtres baissées (via le cache global de menu_vehicles.lua)
    if IsVehicleWindowRolledDown then
        for i = 0, 3 do
            if IsVehicleWindowRolledDown(vehicle, i) then
                return true
            end
        end
    end

    return false
end

--- Met à jour la distance du son pour un véhicule selon l'état des fenêtres
local function UpdateVehicleSoundDistance(netId)
    local data = VehicleMusicActive[netId]
    if not data then return end

    local vehicle = data.vehicle
    if not vehicle or not DoesEntityExist(vehicle) then
        -- Véhicule n'existe plus, nettoyer
        if xSound:soundExists(data.musicId) then
            xSound:Destroy(data.musicId)
        end
        VehicleMusicActive[netId] = nil
        return
    end

    local musicId = data.musicId
    if not xSound:soundExists(musicId) then return end

    local shouldLeak = ShouldSoundLeakFromVehicle(vehicle)
    local playerPed = PlayerPedId()
    local isInVehicle = IsPedInVehicle(playerPed, vehicle, false)

    -- Toggle 2D/3D quand le joueur entre/sort du véhicule.
    -- En 2D (dynamic=false) : pas de spatialisation, donc plus de saccade à grande vitesse.
    if data.isDynamic == nil then data.isDynamic = true end
    if isInVehicle and data.isDynamic then
        xSound:setSoundDynamic(musicId, false)
        data.isDynamic = false
    elseif not isInVehicle and not data.isDynamic then
        xSound:setSoundDynamic(musicId, true)
        data.isDynamic = true
    end

    if isInVehicle then
        -- Le joueur est dans le véhicule = volume normal, mode 2D, pas besoin de Position
        xSound:setVolume(musicId, data.volume)
        xSound:Distance(musicId, SOUND_DISTANCE_OPEN)
        return
    elseif shouldLeak then
        -- Fenêtres ouvertes = son audible dehors
        xSound:setVolume(musicId, data.volume)
        xSound:Distance(musicId, SOUND_DISTANCE_OPEN)
    else
        -- Fenêtres fermées = son très faible dehors
        xSound:setVolume(musicId, data.volume * 0.15) -- 15% du volume
        xSound:Distance(musicId, SOUND_DISTANCE_CLOSED)
    end

    -- Mettre à jour la position du son (mode 3D seulement)
    xSound:Position(musicId, GetEntityCoords(vehicle))
end

-- Compteur de véhicules avec musique active
local ActiveVehicleMusicCount = 0

--- Vérifie si le joueur est dans un véhicule avec musique active
---@return boolean, number|nil True si dans un véhicule avec musique, et le netId
local function IsPlayerInVehicleWithMusic()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle == 0 or not DoesEntityExist(vehicle) or not NetworkGetEntityIsNetworked(vehicle) then return false, nil end

    local netId = VehToNet(vehicle)
    if netId and VehicleMusicActive[netId] then
        return true, netId
    end
    return false, nil
end

-- Thread de mise à jour de la distance du son pour tous les véhicules (OPTIMISÉ)
CreateThread(function()
    while true do
        -- Attendre plus longtemps si aucun véhicule n'a de musique
        if ActiveVehicleMusicCount == 0 then
            Wait(2000) -- 2 secondes si pas de musique
        else
            -- Vérifier si le joueur est dans un véhicule avec musique
            local inVehicleWithMusic, playerVehicleNetId = IsPlayerInVehicleWithMusic()

            if inVehicleWithMusic then
                -- Joueur dans un véhicule avec musique = mise à jour rapide (50ms)
                -- À 200 km/h, le véhicule parcourt ~2.8m en 50ms (acceptable)
                Wait(50)

                -- Mettre à jour uniquement le véhicule du joueur en priorité
                if playerVehicleNetId then
                    UpdateVehicleSoundDistance(playerVehicleNetId)
                end
            else
                -- Joueur pas dans un véhicule avec musique = mise à jour normale
                Wait(500)

                for netId, _ in pairs(VehicleMusicActive) do
                    UpdateVehicleSoundDistance(netId)
                end
            end
        end
    end
end)

-- Écouter les changements d'état des fenêtres
AddEventHandler("vfw:vehicle:windowStateChanged", function(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) or not NetworkGetEntityIsNetworked(vehicle) then return end
    local netId = VehToNet(vehicle)
    if netId and VehicleMusicActive[netId] then
        UpdateVehicleSoundDistance(netId)
    end
end)

--endregion

-- Mode Streamer
-- Charger l'état depuis KVP (persistant)
local _streamerKvp = GetResourceKvpString("streamer_mode_enabled")
local streamerModeEnabled = (_streamerKvp == "1")

-- Exposer globalement pour le menu F5
StreamerModeEnabled = streamerModeEnabled

function SetStreamerMode(enabled)
    streamerModeEnabled = enabled
    StreamerModeEnabled = enabled
    SetResourceKvp("streamer_mode_enabled", enabled and "1" or "0")
    TriggerEvent("xsound:streamerMode", enabled)
end

-- Appliquer au chargement si activé
AddEventHandler("vfw:playerLoaded", function()
    if streamerModeEnabled then
        TriggerEvent("xsound:streamerMode", true)
    end
end)

--- Commande /streamermode - Active/désactive le mode streamer
--- Coupe les sons des boombox, radios véhicules et médias
RegisterCommand("streamermode", function()
    SetStreamerMode(not streamerModeEnabled)

    if streamerModeEnabled then
        TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            args = {"Streamer", "^0Mode activé - Sons des boombox, radios, télés et médias désactivés"}
        })
    else
        TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            args = {"Streamer", "^0Mode désactivé - Sons réactivés"}
        })
    end
end, false)

-- Volume Master xSound (client-side uniquement)
local function ApplyMasterVolume(volume)
    xSound:setMasterVolume(volume)
end

-- Charger le volume sauvegardé au démarrage
CreateThread(function()
    while GetResourceState("xsound") ~= "started" or not exports.xsound.setMasterVolume do
        Wait(500)
    end
    Wait(500)
    local savedVolume = GetResourceKvpFloat("xsound_master_volume")
    if savedVolume and savedVolume > 0 then
        ApplyMasterVolume(savedVolume)
    else
        SetResourceKvpFloat("xsound_master_volume", 1.0)
        ApplyMasterVolume(1.0)
    end
end)

--- Commande /xvol - Modifie le volume master de xSound (client-side)
--- Note: /vol est utilisé par pma-voice pour le volume vocal
RegisterCommand("xvol", function(_, args)
    local volumeArg = tonumber(args[1])

    if not volumeArg then
        local currentVol = GetResourceKvpFloat("xsound_master_volume") or 1.0
        TriggerEvent("chat:addMessage", {
            color = {255, 165, 0},
            args = {"Volume", ("^0Volume actuel : %d%%"):format(math.floor(currentVol * 100))}
        })
        return
    end

    -- Clamp entre 0 et 100
    volumeArg = math.max(0, math.min(100, volumeArg))
    local volumeNormalized = volumeArg / 100

    -- Sauvegarder en KVP (persistant)
    SetResourceKvpFloat("xsound_master_volume", volumeNormalized)

    -- Appliquer le volume
    ApplyMasterVolume(volumeNormalized)

    TriggerEvent("chat:addMessage", {
        color = {255, 165, 0},
        args = {"Volume", ("^0Volume réglé à %d%%"):format(volumeArg)}
    })
end, false)

--- Calcule la distance d'écoute en fonction du volume
---@param volume number Volume entre 0 et 1
---@return number Distance d'écoute en mètres
local function GetSoundDistance(volume)
    return MIN_SOUND_DISTANCE + (volume * (MAX_SOUND_DISTANCE - MIN_SOUND_DISTANCE))
end

--- Calcule la position correcte pour poser la boombox au sol
---@param playerPed number Le ped du joueur
---@return vector3 Position correcte pour la boombox
local function GetBoomboxDropPosition(playerPed)
    local playerCoords = GetEntityCoords(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)

    -- Position devant le joueur (0.8m devant)
    local dropX = playerCoords.x + forwardVector.x * 0.8
    local dropY = playerCoords.y + forwardVector.y * 0.8

    -- Trouver la hauteur du sol à cette position
    local foundGround, groundZ = GetGroundZFor_3dCoord(dropX, dropY, playerCoords.z + 2.0, false)

    if foundGround then
        return vector3(dropX, dropY, groundZ)
    else
        -- Fallback: utiliser la position du joueur - 1.0 (hauteur approximative des pieds)
        return vector3(dropX, dropY, playerCoords.z - 1.0)
    end
end

--- Place la boombox correctement au sol après création/placement
---@param entity number L'entité boombox
local function PlaceBoomboxOnGround(entity)
    if not entity or not DoesEntityExist(entity) then return end
    PlaceObjectOnGroundProperly(entity)
end

RegisterNUICallback("nui:boombox:close", function()
    if BoomBox.open then
        BoomBox.open = false
        SetModelAsNoLongerNeeded(joaat("prop_boombox_01"))
        RemoveAnimDict("pickup_object")
        SendNUIMessage({
            action = "nui:boombox:visible",
            data = false
        })
        VFW.Nui.Focus(false, false)
        VFW.DisableEscapeMenu(false)
        TriggerEvent('chat:setDisabled', false)
    end
    --cb('ok')
end)

-- Fermer l'UI boombox quand l'inventaire s'ouvre
AddEventHandler("core:inventory:opened", function()
    if BoomBox.open then
        BoomBox.open = false
        BoomBox.currentEntity = nil
        VFW.Nui.Focus(false, false)
        VFW.DisableEscapeMenu(false)
        TriggerEvent('chat:setDisabled', false)
        ClearPedTasks(PlayerPedId())
        BoomBox.isGroundInteraction = false
        SendNUIMessage({ action = "nui:musicradio:close", data = {} })
    end
end)

-- MusicRadio NUI Callbacks
RegisterNUICallback("nui:musicradio:close", function()
    if BoomBox.open then
        BoomBox.open = false
        BoomBox.currentEntity = nil
        VFW.Nui.Focus(false, false)
        VFW.DisableEscapeMenu(false)
        TriggerEvent('chat:setDisabled', false)
        ClearPedTasks(PlayerPedId())
        BoomBox.isGroundInteraction = false
    end
end)

RegisterNUICallback("nui:musicradio:play", function(data)
    local playerPed = PlayerPedId()
    if IsEntityDead(playerPed) or IsPedRagdoll(playerPed) then return end

    if not data.url or data.url == "" then return end

    -- Mode véhicule
    if BoomBox.mode == "vehicle" then
        local vehicle = BoomBox.currentEntity
        if not vehicle or not DoesEntityExist(vehicle) then return end

        local netId = VehToNet(vehicle)
        if not netId or netId == 0 then return end

        local musicId = 'veh_' .. netId

        -- Vérifier cooldown
        if IsActionOnCooldown("play", musicId) then
            return
        end
        SetActionCooldown("play", musicId)

        local coords = GetEntityCoords(vehicle)
        local title = data.title or "Lecture directe"

        -- Stocker dans le cache local
        VehicleMusicActive[netId] = {
            musicId = musicId,
            url = data.url,
            volume = BoomBox.Volume,
            vehicle = vehicle,
            title = title
        }
        ActiveVehicleMusicCount = ActiveVehicleMusicCount + 1

        -- Envoyer au serveur pour sync avec les autres joueurs (avec titre)
        TriggerServerEvent("core:vehicleMusic:play", netId, data.url, BoomBox.Volume, coords, title)
        return
    end

    -- Mode boombox
    local closestBoombox = BoomBox.currentEntity or GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 or closestBoombox == 0 then
        return
    end

    local musicId = GetBoomboxMusicId(closestBoombox)
    if not musicId then return end

    -- Vérifier cooldown
    if IsActionOnCooldown("play", musicId) then
        return
    end
    SetActionCooldown("play", musicId)

    -- Stocker le musicId pour le thread de timeUpdate
    BoomBox.currentMusicId = musicId

    local title = data.title or "Lecture directe"
    local coords = GetEntityCoords(closestBoombox)

    -- Utiliser le nouvel event avec titre pour la sync UI
    TriggerServerEvent("core:boombox:playTrack", musicId, data.url, title, BoomBox.Volume, coords)
    FuncUpdatePosition(musicId, coords)
end)

RegisterNUICallback("nui:musicradio:pause", function()
    local playerPed = PlayerPedId()

    -- Mode véhicule
    if BoomBox.mode == "vehicle" then
        local vehicle = BoomBox.currentEntity
        if not vehicle or not DoesEntityExist(vehicle) then return end

        local netId = VehToNet(vehicle)
        local musicId = 'veh_' .. netId

        -- Vérifier cooldown
        if IsActionOnCooldown("pause", musicId) then
            return
        end
        SetActionCooldown("pause", musicId)

        if xSound:soundExists(musicId) then
            if xSound:isPaused(musicId) then
                xSound:Resume(musicId)
                TriggerServerEvent("core:vehicleMusic:pause", netId, "resume")
            else
                -- Récupérer le timestamp ACTUEL depuis le player JS avant de mettre en pause
                local currentTime = xSound:getCurrentTime(musicId) or 0
                xSound:Pause(musicId)
                TriggerServerEvent("core:vehicleMusic:pause", netId, "pause", currentTime)
            end
        end
        return
    end

    -- Mode boombox
    local closestBoombox = BoomBox.currentEntity or GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 or closestBoombox == 0 then
        return
    end

    local musicId = GetBoomboxMusicId(closestBoombox)
    if not musicId then return end

    -- Vérifier cooldown
    if IsActionOnCooldown("pause", musicId) then
        return
    end
    SetActionCooldown("pause", musicId)

    if xSound:soundExists(musicId) then
        if xSound:isPaused(musicId) then
            xSound:Resume(musicId)
            TriggerServerEvent("core:PauseBoomSong", musicId, "resume")
        else
            -- Récupérer le timestamp ACTUEL depuis le player JS avant de mettre en pause
            local currentTime = xSound:getCurrentTime(musicId) or 0
            xSound:Pause(musicId)
            TriggerServerEvent("core:PauseBoomSong", musicId, "pause", currentTime)
        end
    end
end)

RegisterNUICallback("nui:musicradio:stop", function()
    local playerPed = PlayerPedId()

    -- Mode véhicule
    if BoomBox.mode == "vehicle" then
        local vehicle = BoomBox.currentEntity
        if not vehicle or not DoesEntityExist(vehicle) then return end

        local netId = VehToNet(vehicle)
        local musicId = 'veh_' .. netId

        -- Vérifier cooldown
        if IsActionOnCooldown("stop", musicId) then
            return
        end
        SetActionCooldown("stop", musicId)

        if xSound:soundExists(musicId) then
            xSound:Destroy(musicId)
        end
        VehicleMusicActive[netId] = nil
        ActiveVehicleMusicCount = math.max(0, ActiveVehicleMusicCount - 1)
        TriggerServerEvent("core:vehicleMusic:stop", netId)
        return
    end

    -- Mode boombox
    local closestBoombox = BoomBox.currentEntity or GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 or closestBoombox == 0 then
        return
    end

    local musicId = GetBoomboxMusicId(closestBoombox)
    if not musicId then return end

    -- Vérifier cooldown
    if IsActionOnCooldown("stop", musicId) then
        return
    end
    SetActionCooldown("stop", musicId)

    if xSound:soundExists(musicId) then
        xSound:Destroy(musicId)
    end
    TriggerServerEvent("core:PauseBoomSong", musicId, "stop")
end)

RegisterNUICallback("nui:musicradio:volume", function(data)
    local playerPed = PlayerPedId()

    if not data.volume then return end
    BoomBox.Volume = data.volume / 100

    -- Mode véhicule
    if BoomBox.mode == "vehicle" then
        local vehicle = BoomBox.currentEntity
        if not vehicle or not DoesEntityExist(vehicle) then return end

        local netId = VehToNet(vehicle)
        local musicId = 'veh_' .. netId

        -- Mettre à jour le cache local immédiatement (pour l'UI)
        if VehicleMusicActive[netId] then
            VehicleMusicActive[netId].volume = BoomBox.Volume
        end

        -- Appliquer localement immédiatement
        if xSound:soundExists(musicId) then
            UpdateVehicleSoundDistance(netId)
        end

        -- Vérifier cooldown seulement pour l'envoi au serveur
        if IsActionOnCooldown("volume", musicId) then
            return
        end
        SetActionCooldown("volume", musicId)

        TriggerServerEvent("core:vehicleMusic:volume", netId, BoomBox.Volume)
        return
    end

    -- Mode boombox
    local closestBoombox = BoomBox.currentEntity or GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 or closestBoombox == 0 then
        return
    end

    local musicId = GetBoomboxMusicId(closestBoombox)
    if not musicId then return end

    -- Appliquer localement immédiatement (pas de latence pour le joueur)
    if xSound:soundExists(musicId) then
        -- Tenir compte du multiplicateur de room occlusion actuel
        local multiplier = 1.0
        if ActiveBoomboxSounds[musicId] then
            multiplier = ActiveBoomboxSounds[musicId].currentMultiplier
            ActiveBoomboxSounds[musicId].baseVolume = BoomBox.Volume
        end
        xSound:setVolume(musicId, BoomBox.Volume * multiplier)
        xSound:Distance(musicId, GetSoundDistance(BoomBox.Volume * multiplier))
    end

    -- Vérifier cooldown seulement pour l'envoi au serveur
    if IsActionOnCooldown("volume", musicId) then
        return
    end
    SetActionCooldown("volume", musicId)

    TriggerServerEvent("core:BoomSongVolume", musicId, BoomBox.Volume)
end)

RegisterNUICallback("nui:musicradio:drop", function()
    local playerPed = PlayerPedId()
    local closestBoombox = BoomBox.currentEntity or GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 or closestBoombox == 0 then
        return
    end

    if BoomBox.holdingboom then
        if not WaitForEntityControl(closestBoombox) then return end

        if IsEntityAttached(closestBoombox) then
            if GetEntityAttachedTo(closestBoombox) == playerPed then
                BoomBox.holdingboom = false
                ClearPedTasks(playerPed)
            end
            DetachEntity(closestBoombox)
        end

        local dropPos = GetBoomboxDropPosition(playerPed)
        SetEntityCoords(closestBoombox, dropPos.x, dropPos.y, dropPos.z)
        PlaceBoomboxOnGround(closestBoombox)

        -- Freeze au sol et désactiver collision avec les joueurs
        FreezeEntityPosition(closestBoombox, true)
        SetEntityCollision(closestBoombox, false, false)

        local musicId = GetBoomboxMusicId(closestBoombox)
        if musicId then
            FuncUpdatePosition(musicId, GetEntityCoords(closestBoombox))
        end
    end
end)

RegisterNUICallback("nui:musicradio:carry", function()
    local playerPed = PlayerPedId()
    local closestBoombox = BoomBox.currentEntity or GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 or closestBoombox == 0 then
        return
    end

    if not IsEntityAttached(closestBoombox) then
        -- Fermer l'UI et nettoyer l'état avant de porter
        SendNUIMessage({ action = "nui:musicradio:close", data = {} })
        BoomBox.open = false
        BoomBox.currentEntity = nil
        VFW.Nui.Focus(false, false)
        VFW.DisableEscapeMenu(false)
        TriggerEvent('chat:setDisabled', false)

        -- Arrêter l'animation penchée (ground interaction) avant de lancer la carry
        ClearPedTasks(playerPed)
        BoomBox.isGroundInteraction = false

        PorterBoombox(closestBoombox)
    end
end)

RegisterNUICallback("nui:musicradio:pickup", function()
    local playerPed = PlayerPedId()
    local closestBoombox = BoomBox.currentEntity or GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 or closestBoombox == 0 then
        return
    end

    if BoomBox.isGroundInteraction then
        ClearPedTasks(PlayerPedId())
        BoomBox.isGroundInteraction = false
    end

    PickupBoombox(closestBoombox)

    -- Close the UI after picking up
    SendNUIMessage({
        action = "nui:musicradio:close",
        data = {}
    })
    BoomBox.open = false
    BoomBox.currentEntity = nil
    VFW.Nui.Focus(false, false)
    VFW.DisableEscapeMenu(false)
    TriggerEvent('chat:setDisabled', false)
end)

--region ------ GESTION DES PLAYLISTS (PERSISTANCE) ------

-- Cache local des playlists du joueur
BoomBox.playlists = {}

--- Charger les playlists depuis le serveur
local function LoadPlayerPlaylists()
    local playlists = TriggerServerCallback("musicradio:getPlaylists")
    BoomBox.playlists = playlists or {}
    return BoomBox.playlists
end

--- NUI Callback: Créer une playlist
RegisterNUICallback("nui:musicradio:playlist:create", function(data, cb)
    if not data or not data.name then
        if cb then cb({ success = false }) end
        return
    end

    TriggerServerEvent("musicradio:playlist:create", {
        name = data.name
    })

    if cb then cb({ success = true }) end
end)

--- NUI Callback: Supprimer une playlist
RegisterNUICallback("nui:musicradio:playlist:delete", function(data, cb)
    if not data or not data.playlistId then
        if cb then cb({ success = false }) end
        return
    end

    TriggerServerEvent("musicradio:playlist:delete", {
        playlistId = data.playlistId
    })

    if cb then cb({ success = true }) end
end)

--- NUI Callback: Renommer une playlist
RegisterNUICallback("nui:musicradio:playlist:rename", function(data, cb)
    if not data or not data.playlistId or not data.name then
        if cb then cb({ success = false }) end
        return
    end

    TriggerServerEvent("musicradio:playlist:rename", {
        playlistId = data.playlistId,
        name = data.name
    })

    if cb then cb({ success = true }) end
end)

--- NUI Callback: Ajouter une piste à une playlist
RegisterNUICallback("nui:musicradio:track:add", function(data, cb)
    if not data or not data.playlistId or not data.track then
        if cb then cb({ success = false }) end
        return
    end

    TriggerServerEvent("musicradio:track:add", {
        playlistId = data.playlistId,
        track = data.track
    })

    if cb then cb({ success = true }) end
end)

--- NUI Callback: Supprimer une piste d'une playlist
RegisterNUICallback("nui:musicradio:track:remove", function(data, cb)
    if not data or not data.playlistId or not data.trackId then
        if cb then cb({ success = false }) end
        return
    end

    TriggerServerEvent("musicradio:track:remove", {
        playlistId = data.playlistId,
        trackId = data.trackId
    })

    if cb then cb({ success = true }) end
end)

--- Event: Playlist créée (confirmation serveur)
RegisterNetEvent("musicradio:playlist:created", function(playlist)
    if not playlist then return end

    table.insert(BoomBox.playlists, playlist)

    -- Mettre à jour l'UI si ouverte
    if BoomBox.open then
        SendNUIMessage({
            action = "nui:musicradio:playlists:update",
            data = { playlists = BoomBox.playlists }
        })
    end
end)

--- Event: Playlist supprimée (confirmation serveur)
RegisterNetEvent("musicradio:playlist:deleted", function(playlistId)
    for i, playlist in ipairs(BoomBox.playlists) do
        if playlist.id == playlistId then
            table.remove(BoomBox.playlists, i)
            break
        end
    end

    if BoomBox.open then
        SendNUIMessage({
            action = "nui:musicradio:playlists:update",
            data = { playlists = BoomBox.playlists }
        })
    end
end)

--- Event: Playlist renommée (confirmation serveur)
RegisterNetEvent("musicradio:playlist:renamed", function(playlistId, newName)
    for _, playlist in ipairs(BoomBox.playlists) do
        if playlist.id == playlistId then
            playlist.name = newName
            break
        end
    end

    if BoomBox.open then
        SendNUIMessage({
            action = "nui:musicradio:playlists:update",
            data = { playlists = BoomBox.playlists }
        })
    end
end)

--- Event: Piste ajoutée (confirmation serveur)
RegisterNetEvent("musicradio:track:added", function(playlistId, track)
    for _, playlist in ipairs(BoomBox.playlists) do
        if playlist.id == playlistId then
            table.insert(playlist.tracks, track)
            break
        end
    end

    if BoomBox.open then
        SendNUIMessage({
            action = "nui:musicradio:playlists:update",
            data = { playlists = BoomBox.playlists }
        })
    end
end)

--- Event: Piste supprimée (confirmation serveur)
RegisterNetEvent("musicradio:track:removed", function(playlistId, trackId)
    for _, playlist in ipairs(BoomBox.playlists) do
        if playlist.id == playlistId then
            for i, track in ipairs(playlist.tracks) do
                if track.id == trackId then
                    table.remove(playlist.tracks, i)
                    break
                end
            end
            break
        end
    end

    if BoomBox.open then
        SendNUIMessage({
            action = "nui:musicradio:playlists:update",
            data = { playlists = BoomBox.playlists }
        })
    end
end)

--- Event: Notification du serveur
RegisterNetEvent("musicradio:notify", function(type, message)
    VFW.ShowNotification({
        type = type,
        content = message
    })
end)

--endregion

---Get AllPlayersIdsInArea
---@param coords vector3|table Coordinates
---@param zone any
---@return table|nil Player object
local function GetAllPlayersIdsInArea(coords, zone)
    local playersInArea = {}

    if zone == nil then
        zone = 150.0
    end

    for playerId, player in pairs(GetActivePlayers()) do
        local pPed = GetPlayerPed(player)
        local pCoords = GetEntityCoords(pPed)

        if #(vector3(pCoords.x, pCoords.y, pCoords.z) - vector3(coords.x, coords.y, coords.z)) <= zone then
            table.insert(playersInArea, GetPlayerServerId(player))
        end
    end

    return playersInArea
end

-- Tracking des threads de position actifs pour éviter les doublons
local ActivePositionThreads = {} -- [musicId] = threadId (unique per thread)
local PositionThreadCounter = 0

---Update FuncPosition (OPTIMISÉ - Race condition fixée)
---@param musicid number|string
---@param coords vector3|table Coordinates
FuncUpdatePosition = function(musicid, coords)
    -- Générer un ID unique pour ce thread
    PositionThreadCounter = PositionThreadCounter + 1
    local myThreadId = PositionThreadCounter

    -- Marquer comme actif avec notre ID (écrase l'ancien thread s'il existe)
    ActivePositionThreads[musicid] = myThreadId

    CreateThread(function()
        local playerPed = PlayerPedId()
        local noSoundCounter = 0

        while true do
            -- Vérifier si on est toujours le thread actif pour ce musicId
            if ActivePositionThreads[musicid] ~= myThreadId then
                return -- Un nouveau thread a pris le relais, on s'arrête
            end

            -- Vérifier si le son existe toujours
            if not xSound:soundExists(musicid) then
                noSoundCounter = noSoundCounter + 1
                -- Après 3 vérifications sans son (3 secondes), arrêter le thread
                if noSoundCounter >= 3 then
                    if ActivePositionThreads[musicid] == myThreadId then
                        ActivePositionThreads[musicid] = nil
                    end
                    return -- Sortir du thread
                end
                Wait(1000)
            else
                noSoundCounter = 0

                if BoomBox.holdingboom then
                    -- Boombox portée = mises à jour fréquentes
                    local currentCoords = GetEntityCoords(playerPed)
                    xSound:Position(musicid, currentCoords)

                    -- Envoyer au serveur toutes les 1.5 secondes seulement
                    local plys = GetAllPlayersIdsInArea(currentCoords, 10.0)
                    TriggerServerEvent("core:updateSongPos", plys, musicid, currentCoords)
                    Wait(1500)
                else
                    -- Boombox posée = mises à jour rares
                    -- Si coords est nil (passage de carry à posé), récupérer les coords de l'entité via netId
                    if not coords then
                        local ent = GetEntityFromMusicId(musicid)
                        if ent then
                            coords = GetEntityCoords(ent)
                        else
                            -- Pas de coords et entité introuvable, arrêter le thread
                            if ActivePositionThreads[musicid] == myThreadId then
                                ActivePositionThreads[musicid] = nil
                            end
                            return
                        end
                    end
                    xSound:Position(musicid, coords)

                    -- Envoyer au serveur toutes les 10 secondes seulement
                    local plys = GetAllPlayersIdsInArea(coords, 10.0)
                    TriggerServerEvent("core:updateSongPos", plys, musicid, coords)
                    Wait(10000)
                end
            end
        end
    end)
end

---@param musicid any
---@param coooords any
RegisterNetEvent("core:updateSongPosC", function(musicid, coooords)
    if xSound:soundExists(musicid) then
        xSound:Position(musicid, coooords)
        -- Synchroniser le cache ActiveBoomboxSounds avec les nouvelles coordonnées
        if ActiveBoomboxSounds[musicid] then
            ActiveBoomboxSounds[musicid].coords = vector3(coooords.x, coooords.y, coooords.z)
        end
    end
end)

RegisterNUICallback("nui:boombox:user_action", function(data)
    local playerPed = PlayerPedId()
    if IsEntityDead(playerPed) or IsPedRagdoll(playerPed) then return end

    local closestBoombox = GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 then
        return
    end

    if data.action_user and data.action_user == "ramasser" then
        if not LoadAnimDictAsync("move_weapon@jerrycan@generic") then return end

        TaskPlayAnim(playerPed, "move_weapon@jerrycan@generic", "idle", 1.0, -1, -1, 50, 0, 0, 0, 0)

        NetworkRequestControlOfEntity(closestBoombox)
        if not WaitForEntityControl(closestBoombox) then return end

        AttachEntityToEntity(closestBoombox, playerPed, GetPedBoneIndex(playerPed, 57005), 0.27, 0.0, 0.0, 0.0, 263.0, 58.0, true, true, false , true, 1, true)

        BoomBox.holdingboom = true
        StartCarryControlThread()

        RemoveAnimDict("move_weapon@jerrycan@generic")

        local musicId = GetBoomboxMusicId(closestBoombox)
        if musicId then FuncUpdatePosition(musicId) end
    elseif data.action_user == "porter" then
        if not LoadAnimDictAsync("molly@boombox1") then return end

        TaskPlayAnim(playerPed, "molly@boombox1", "boombox1_clip", 1.0, -1, -1, 50, 0, 0, 0, 0)

        NetworkRequestControlOfEntity(closestBoombox)
        if not WaitForEntityControl(closestBoombox) then return end

        AttachEntityToEntity(closestBoombox, playerPed, GetPedBoneIndex(playerPed, 10706), -0.2310, -0.0770, 0.2410, -179.7256, 176.7406, 23.0190, true, true, false , true, 1, true)

        RemoveAnimDict("molly@boombox1")

        BoomBox.holdingboom = true
        StartCarryControlThread()

        local musicId = GetBoomboxMusicId(closestBoombox)
        if musicId then FuncUpdatePosition(musicId) end
    elseif data.action_user == "poser" then
        if BoomBox.holdingboom then
            if not WaitForEntityControl(closestBoombox) then return end

            if IsEntityAttached(closestBoombox) then
                if GetEntityAttachedTo(closestBoombox) == playerPed then
                    BoomBox.holdingboom = false
                    ClearPedTasks(playerPed)
                end

                DetachEntity(closestBoombox)
            end

            local dropPos = GetBoomboxDropPosition(playerPed)
            SetEntityCoords(closestBoombox, dropPos.x, dropPos.y, dropPos.z)
            PlaceBoomboxOnGround(closestBoombox)

            -- Freeze au sol et désactiver collision avec les joueurs
            FreezeEntityPosition(closestBoombox, true)
            SetEntityNoCollisionEntity(closestBoombox, playerPed, true)

            local musicId = GetBoomboxMusicId(closestBoombox)
            if musicId then
                FuncUpdatePosition(musicId, GetEntityCoords(closestBoombox))
            end
        end
    end
end)

--- PoseLaBoombox
function PoseLaBoombox()
    local playerPed = PlayerPedId()
    local closestBoombox = GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if BoomBox.holdingboom then
        if not WaitForEntityControl(closestBoombox) then return end

        if IsEntityAttached(closestBoombox) then
            if GetEntityAttachedTo(closestBoombox) == playerPed then
                BoomBox.holdingboom = false
                ClearPedTasks(playerPed)
            end

            DetachEntity(closestBoombox)
        end

        local dropPos = GetBoomboxDropPosition(playerPed)
        SetEntityCoords(closestBoombox, dropPos.x, dropPos.y, dropPos.z)
        PlaceBoomboxOnGround(closestBoombox)

        -- Freeze au sol et désactiver collision avec les joueurs
        FreezeEntityPosition(closestBoombox, true)
        SetEntityNoCollisionEntity(closestBoombox, playerPed, true)

        local musicId = GetBoomboxMusicId(closestBoombox)
        if musicId then
            FuncUpdatePosition(musicId, GetEntityCoords(closestBoombox))
        end
    end
end

--region ------ ANTI-BUG : VÉRIFICATION COHÉRENCE BOOMBOX ------

--- Thread de vérification de cohérence de l'état de la boombox
--- Si l'état est incohérent (holdingboom désynchronisé), force le drop au sol
CreateThread(function()
    while true do
        Wait(2000) -- Vérifier toutes les 2 secondes

        local playerPed = PlayerPedId()

        -- Chercher une boombox attachée au joueur
        local attachedBoombox = nil
        local nearbyBoombox = GetClosestObjectOfType(GetEntityCoords(playerPed), 5.0, `prop_boombox_01`, false, false, false)

        if nearbyBoombox and nearbyBoombox ~= 0 and nearbyBoombox ~= -1 then
            if IsEntityAttached(nearbyBoombox) and GetEntityAttachedTo(nearbyBoombox) == playerPed then
                attachedBoombox = nearbyBoombox
            end
        end

        -- Cas 1: On pense porter la boombox mais rien n'est attaché
        if BoomBox.holdingboom and not attachedBoombox then
            BoomBox.holdingboom = false
            ClearPedTasks(playerPed)

            -- Fermer l'UI si ouverte
            if BoomBox.open then
                BoomBox.open = false
                BoomBox.currentEntity = nil
                VFW.Nui.Focus(false, false)
                VFW.DisableEscapeMenu(false)
                TriggerEvent('chat:setDisabled', false)
                SendNUIMessage({ action = "nui:musicradio:close", data = {} })
            end
        end

        -- Cas 2: UI ouverte en interaction au sol mais l'entité n'existe plus (ramassée par un autre joueur)
        if BoomBox.open and BoomBox.isGroundInteraction and BoomBox.currentEntity then
            if not DoesEntityExist(BoomBox.currentEntity) then
                BoomBox.open = false
                BoomBox.currentEntity = nil
                BoomBox.isGroundInteraction = false
                ClearPedTasks(playerPed)
                VFW.Nui.Focus(false, false)
                VFW.DisableEscapeMenu(false)
                TriggerEvent('chat:setDisabled', false)
                SendNUIMessage({ action = "nui:musicradio:close", data = {} })
            end
        end

        -- Cas 3: Une boombox est attachée mais on ne pense pas la porter -> forcer drop
        if attachedBoombox and not BoomBox.holdingboom then
            -- Forcer le drop au sol
            NetworkRequestControlOfEntity(attachedBoombox)
            local attempts = 0
            while not NetworkHasControlOfEntity(attachedBoombox) and attempts < 50 do
                Wait(10)
                NetworkRequestControlOfEntity(attachedBoombox)
                attempts = attempts + 1
            end

            if NetworkHasControlOfEntity(attachedBoombox) then
                DetachEntity(attachedBoombox)
                ClearPedTasks(playerPed)

                local dropPos = GetBoomboxDropPosition(playerPed)
                SetEntityCoords(attachedBoombox, dropPos.x, dropPos.y, dropPos.z)
                PlaceBoomboxOnGround(attachedBoombox)
                FreezeEntityPosition(attachedBoombox, true)
                SetEntityCollision(attachedBoombox, false, false)

                local musicId = GetBoomboxMusicId(attachedBoombox)
                if musicId then
                    FuncUpdatePosition(musicId, GetEntityCoords(attachedBoombox))
                end
            end

            -- Fermer l'UI si ouverte
            if BoomBox.open then
                BoomBox.open = false
                BoomBox.currentEntity = nil
                VFW.Nui.Focus(false, false)
                VFW.DisableEscapeMenu(false)
                TriggerEvent('chat:setDisabled', false)
                SendNUIMessage({ action = "nui:musicradio:close", data = {} })
            end
        end
    end
end)

--endregion

---@param musicId any
---@param url any
---@param volume any
---@param coords vector3|table
RegisterNetEvent("core:plyBoomSongC", function(musicId, url, volume, coords)
    if streamerModeEnabled then return end

    local playerPed = PlayerPedId()
    local mycoords = GetEntityCoords(playerPed)
    local distance = #(vector3(mycoords.x, mycoords.y, mycoords.z) - vector3(coords.x, coords.y, coords.z))

    if distance < MAX_SOUND_DISTANCE + 10.0 then
        -- Vérifier room occlusion
        local soundCoords = vector3(coords.x, coords.y, coords.z)
        local entity = GetEntityFromMusicId(musicId)
        local canHear, volumeMultiplier = CheckPlayerAudioEligibility(soundCoords, MAX_SOUND_DISTANCE, entity)

        if canHear then
            local adjustedVolume = volume * volumeMultiplier
            local soundDistance = GetSoundDistance(adjustedVolume)

            xSound:PlayUrlPos(musicId, url, adjustedVolume, coords)
            xSound:Distance(musicId, soundDistance)
            xSound:setVolume(musicId, adjustedVolume)

            -- Enregistrer pour le monitoring de room occlusion
            if ActiveBoomboxSounds then
                if not ActiveBoomboxSounds[musicId] then
                    ActiveBoomboxCount = ActiveBoomboxCount + 1
                end
                ActiveBoomboxSounds[musicId] = {
                    coords = soundCoords,
                    baseVolume = volume,
                    currentMultiplier = volumeMultiplier,
                    entity = entity
                }
            end
        end
    end
end)

--- Resync boombox via state bag entite (auto-replique quand l'entite entre dans le scope du client)
--- Remplace l'ancien event 'core:boombox:syncJoin' qui ne se declenchait qu'au playerJoining.
--- Couvre: late-join, joueur qui se teleporte/marche dans la zone, respawn, scope-in initial.
AddStateBagChangeHandler('boombox', nil, function(bagName, _key, value, _, _)
    local netId = tonumber(bagName:match("^entity:(%d+)$"))
    if not netId then return end
    local musicId = 'id_' .. netId

    -- Bag efface = arret => detruire le son local s'il existe
    if not value then
        if xSound:soundExists(musicId) then
            xSound:Destroy(musicId)
        end
        if ActiveBoomboxSounds[musicId] then
            ActiveBoomboxSounds[musicId] = nil
            ActiveBoomboxCount = math.max(0, ActiveBoomboxCount - 1)
        end
        return
    end

    -- Sound deja en cours localement (initie via core:plyBoomSongC) => rien a faire
    if xSound:soundExists(musicId) then return end

    if streamerModeEnabled then return end

    -- Resync uniquement pour les boombox en lecture
    if value.playState ~= "playing" then return end
    if not value.url then return end

    local ent = NetworkGetEntityFromNetworkId(netId)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return end

    local coords = GetEntityCoords(ent)
    local mycoords = GetEntityCoords(PlayerPedId())
    if #(mycoords - coords) > MAX_SOUND_DISTANCE + 10.0 then return end

    local canHear, volumeMultiplier = CheckPlayerAudioEligibility(coords, MAX_SOUND_DISTANCE, ent)
    if not canHear then return end

    local volume = value.volume or 0.7
    local adjustedVolume = volume * volumeMultiplier
    local soundDistance = GetSoundDistance(adjustedVolume)

    xSound:PlayUrlPos(musicId, value.url, adjustedVolume, coords)
    xSound:Distance(musicId, soundDistance)
    xSound:setVolume(musicId, adjustedVolume)

    -- Calcul de l'offset via horloge serveur partagee (os.time secondes)
    if value.startedAtEpoch then
        local elapsed = GetCloudTimeAsInt() - value.startedAtEpoch
        if elapsed > 1 then
            CreateThread(function()
                local tries = 0
                while not xSound:isPlaying(musicId) and tries < 50 do
                    Wait(100)
                    tries = tries + 1
                end
                if xSound:soundExists(musicId) then
                    xSound:setTimeStamp(musicId, elapsed)
                end
            end)
        end
    end

    if not ActiveBoomboxSounds[musicId] then
        ActiveBoomboxCount = ActiveBoomboxCount + 1
    end
    ActiveBoomboxSounds[musicId] = {
        coords = coords,
        baseVolume = volume,
        currentMultiplier = volumeMultiplier,
        entity = ent
    }
end)

---@param musicid any
---@param typer any
---@param resumeTime number|nil Timestamp à reprendre (en secondes)
RegisterNetEvent("core:PauseBoomSongC", function(musicid, typer, resumeTime)
    if xSound:soundExists(musicid) then
        if typer == "resume" then
            -- Reprendre au timestamp sauvegardé
            if resumeTime and resumeTime > 0 then
                xSound:setTimeStamp(musicid, resumeTime)
            end
            xSound:Resume(musicid)
        elseif typer == "pause" then
            xSound:Pause(musicid)
        elseif typer == "stop" then
            xSound:Destroy(musicid)
            -- Retirer du monitoring de room occlusion
            if ActiveBoomboxSounds[musicid] then
                ActiveBoomboxSounds[musicid] = nil
                ActiveBoomboxCount = math.max(0, ActiveBoomboxCount - 1)
            end
        end
    end
end)

RegisterNUICallback("nui:boombox:volume", function(data)
    local playerPed = PlayerPedId()
    local closestBoombox = GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 then
        return
    end

    local musicId = GetBoomboxMusicId(closestBoombox)
    if not musicId then return end

    if data.volume and data.volume/100 ~= BoomBox.Volume then
        BoomBox.Volume = data.volume/100

        -- Appliquer localement immédiatement
        if xSound:soundExists(musicId) then
            -- Tenir compte du multiplicateur de room occlusion actuel
            local multiplier = 1.0
            if ActiveBoomboxSounds[musicId] then
                multiplier = ActiveBoomboxSounds[musicId].currentMultiplier
                ActiveBoomboxSounds[musicId].baseVolume = BoomBox.Volume
            end
            xSound:setVolume(musicId, BoomBox.Volume * multiplier)
            xSound:Distance(musicId, GetSoundDistance(BoomBox.Volume * multiplier))
        end

        -- Vérifier cooldown seulement pour l'envoi au serveur
        if IsActionOnCooldown("volume", musicId) then
            return
        end
        SetActionCooldown("volume", musicId)

        TriggerServerEvent("core:BoomSongVolume", musicId, BoomBox.Volume)
    end
end)

RegisterNUICallback("nui:boombox:action_son", function(data)
    local playerPed = PlayerPedId()
    local closestBoombox = GetClosestObjectOfType(GetEntityCoords(playerPed), 3.0, `prop_boombox_01`, false)

    if closestBoombox == -1 then
        return
    end

    if data.url_youtube ~= "" then
        local musicId = GetBoomboxMusicId(closestBoombox)
        if not musicId then return end

        if data.action_son == "play" then
            -- Vérifier cooldown
            if IsActionOnCooldown("play", musicId) then
                return
            end
            SetActionCooldown("play", musicId)

            TriggerServerEvent("core:plyBoomSong", musicId, data.url_youtube, data.volume, GetEntityCoords(playerPed))
            FuncUpdatePosition(musicId, GetEntityCoords(playerPed))

        elseif data.action_son == "pause" then
            -- Vérifier cooldown
            if IsActionOnCooldown("pause", musicId) then
                return
            end
            SetActionCooldown("pause", musicId)

            if xSound:isPaused(musicId) then
                xSound:Resume(musicId)
                TriggerServerEvent("core:PauseBoomSong", musicId, "resume")
            else
                -- Récupérer le timestamp ACTUEL depuis le player JS avant de mettre en pause
                local currentTime = xSound:getCurrentTime(musicId) or 0
                xSound:Pause(musicId)
                TriggerServerEvent("core:PauseBoomSong", musicId, "pause", currentTime)
            end

        elseif data.action_son == "stop" then
            -- Vérifier cooldown
            if IsActionOnCooldown("stop", musicId) then
                return
            end
            SetActionCooldown("stop", musicId)

            xSound:Destroy(musicId)
            TriggerServerEvent("core:PauseBoomSong", musicId, "stop")
        end
    end
end)

---@param musicId any
---@param volum any
RegisterNetEvent("core:BoomSongVolumeC", function(musicId, volum)
    if xSound:soundExists(musicId) then
        xSound:setVolume(musicId, volum)
        xSound:Distance(musicId, GetSoundDistance(volum))
        -- Synchroniser le cache ActiveBoomboxSounds
        if ActiveBoomboxSounds[musicId] then
            ActiveBoomboxSounds[musicId].baseVolume = volum
        end
    end
end)

OpenBoomBoxUI = function()
    if BoomBox.open then return end
    BoomBox.open = true

    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "nui:boombox:visible",
        data = true
    })

    VFW.DisableEscapeMenu(true)
    TriggerEvent('chat:setDisabled', true)

    CreateThread(function()
        while BoomBox.open do
            Wait(0)
        end
    end)
end

RegisterNetEvent("core:UseBoombox", function()
    local playerPed = PlayerPedId()

    -- Guards : ne pas permettre si mort ou en vehicule
    if IsEntityDead(playerPed) or IsPedInAnyVehicle(playerPed, false) then
        VFW.ShowNotification({ type = 'ERROR', content = 'Impossible de poser la boombox ici.' })
        return
    end

    if not BoomBox.holdingboom then
        if not LoadModelAsync(joaat("prop_boombox_01")) then return end

        local dropPos = GetBoomboxDropPosition(playerPed)

        -- Creation cote serveur pour que l'entite ne soit pas culled
        -- quand le poseur s'eloigne ou se deconnecte (cf bug LTD).
        local netId = TriggerServerCallback("core:boombox:requestPlacement", dropPos)
        if not netId then
            VFW.ShowNotification({ type = 'ERROR', content = 'Erreur lors du placement de la boombox.' })
            return
        end

        -- Attendre que l'entite soit streamee localement
        local obj = NetworkGetEntityFromNetworkId(netId)
        local tries = 0
        while (not obj or obj == 0 or not DoesEntityExist(obj)) and tries < 40 do
            Wait(50)
            obj = NetworkGetEntityFromNetworkId(netId)
            tries = tries + 1
        end

        if obj and obj ~= 0 and DoesEntityExist(obj) then
            PlaceBoomboxOnGround(obj)
            FreezeEntityPosition(obj, true)
            SetEntityNoCollisionEntity(obj, playerPed, true)
            CheckBoomBoxPresence(obj, netId)
        end

        VFW.CloseInventory()
    else
        VFW.CloseInventory()
    end
end)

--- CheckBoomBoxPresence (avec timeout pour éviter threads zombies)
---@param obj any
---@param netId number netId capture au placement (stable meme si l'entite disparait localement)
function CheckBoomBoxPresence(obj, netId)
    CreateThread(function()
        local maxWaitTime = 3600000 -- 1 heure max (timeout sécurité)
        local startTime = GetGameTimer()

        while DoesEntityExist(obj) do
            -- Timeout de sécurité pour éviter les threads zombies
            if (GetGameTimer() - startTime) > maxWaitTime then
                break
            end
            Wait(250)
        end

        -- L'entite n'existe plus localement. Comme la boombox est creee cote
        -- serveur avec un culling radius infini, elle peut etre vivante chez
        -- d'autres joueurs meme si elle est unstreamee chez nous. On nettoie
        -- juste notre son local sans notifier le serveur (sinon on stopperait
        -- la musique pour tout le monde alors qu'elle joue toujours ailleurs).
        local musicId = 'id_' .. netId
        if xSound:soundExists(musicId) then
            xSound:Destroy(musicId)
        end
    end)
end

--- PlayAnim
---@param dict any
---@param anim any
---@param flag any
local function PlayAnim(dict, anim, flag)
    if dict ~= "" then
        if not LoadAnimDictAsync(dict) then return end
        TaskPlayAnim(PlayerPedId(), dict, anim, 2.0, 2.0, -1, flag, 0, false, false, false)
        RemoveAnimDict(dict)
    end
end

--- PickupBoombox
---@param entity any
function PickupBoombox(entity)
    if BoomBox.isPickingUp then return end
    if not DoesEntityExist(entity) then return end
    BoomBox.isPickingUp = true

    local playerPed = PlayerPedId()
    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or 0
    if netId == 0 then BoomBox.isPickingUp = false return end
    local musicId = 'id_' .. netId

    if BoomBox.holdingboom then
        BoomBox.holdingboom = false
        ClearPedTasks(playerPed)

        if IsEntityAttached(entity) and GetEntityAttachedTo(entity) == playerPed then
            DetachEntity(entity)
        end
    else
        PlayAnim("pickup_object", "pickup_low", 0)
    end

    TriggerServerEvent("vfw:deleteEntity", { netId })
    xSound:Destroy(musicId)
    TriggerServerEvent("core:PauseBoomSong", musicId, "stop")
    TriggerServerEvent("core:boombox:pickup", musicId)

    -- Local fallback delete : `vfw:deleteEntity` peut échouer côté serveur
    -- (permission `clean_zone` requise, ou DeleteEntity silencieusement
    -- inopérant sur une entité networked dont un client a l'ownership). On
    -- prend le contrôle local et on supprime nous-même.
    CreateThread(function()
        if not DoesEntityExist(entity) then return end
        NetworkRequestControlOfEntity(entity)
        local tries = 0
        while not NetworkHasControlOfEntity(entity) and tries < 20 do
            Wait(50)
            NetworkRequestControlOfEntity(entity)
            tries = tries + 1
        end
        if DoesEntityExist(entity) then
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end)

    VFW.ShowNotification({
        type = 'VERT',
        content = 'Vous avez ramassé une boombox.'
    })

    SetTimeout(2000, function()
        BoomBox.isPickingUp = false
    end)
end

--- PorterBoombox
---@param entity any
function PorterBoombox(entity)
    local playerPed = PlayerPedId()

    if not WaitForEntityControl(entity) then return end

    -- Unfreeze et réactiver collision (la boombox était freeze au sol)
    FreezeEntityPosition(entity, false)
    SetEntityCollision(entity, true, true)

    if not LoadAnimDictAsync("molly@boombox1") then return end

    TaskPlayAnim(playerPed, "molly@boombox1", "boombox1_clip", 1.0, -1, -1, 50, 0, 0, 0, 0)

    AttachEntityToEntity(entity, playerPed, GetPedBoneIndex(playerPed, 10706), -0.2310, -0.0770, 0.2410, -179.7256, 176.7406, 23.0190, true, true, false, true, 1, true)

    RemoveAnimDict("molly@boombox1")

    BoomBox.holdingboom = true
    StartCarryControlThread()

    local musicId = GetBoomboxMusicId(entity)
    if musicId then FuncUpdatePosition(musicId) end
end

local carryControlThread = false

local function ReattachBoombox(ped)
    local boombox = GetClosestObjectOfType(GetEntityCoords(ped), 5.0, `prop_boombox_01`, false, false, false)
    if boombox == 0 or boombox == -1 then return end

    NetworkRequestControlOfEntity(boombox)
    local attempts = 0
    while not NetworkHasControlOfEntity(boombox) and attempts < 30 do
        Wait(10)
        NetworkRequestControlOfEntity(boombox)
        attempts = attempts + 1
    end
    if not NetworkHasControlOfEntity(boombox) then return end

    if IsEntityAttached(boombox) then
        DetachEntity(boombox)
    end

    FreezeEntityPosition(boombox, false)
    SetEntityCollision(boombox, true, true)

    if not LoadAnimDictAsync("molly@boombox1") then return end
    TaskPlayAnim(ped, "molly@boombox1", "boombox1_clip", 1.0, -1, -1, 50, 0, 0, 0, 0)
    AttachEntityToEntity(boombox, ped, GetPedBoneIndex(ped, 10706), -0.2310, -0.0770, 0.2410, -179.7256, 176.7406, 23.0190, true, true, false, true, 1, true)
    RemoveAnimDict("molly@boombox1")
end

StartCarryControlThread = function()
    if carryControlThread then return end
    carryControlThread = true

    CreateThread(function()
        local combatKeys = {21, 24, 25, 36, 44, 58, 140, 141, 142, 257, 263, 264}
        local lastReattach = 0

        while BoomBox.holdingboom do
            Wait(0)
            local ped = PlayerPedId()
            DisablePlayerFiring(ped, true)
            for _, keyCode in ipairs(combatKeys) do
                DisableControlAction(0, keyCode, true)
            end
            if GetPedStealthMovement(ped) then
                SetPedStealthMovement(ped, false, "DEFAULT_ACTION")
            end

            local now = GetGameTimer()
            if (now - lastReattach) > 500 then
                local broken = false

                if IsPedRagdoll(ped) or IsPedFalling(ped) or IsEntityPlayingAnim(ped, "move_crouch_proto", "idle_intro", 3) then
                    broken = true
                end

                if not broken then
                    local boombox = GetClosestObjectOfType(GetEntityCoords(ped), 5.0, `prop_boombox_01`, false, false, false)
                    if boombox ~= 0 and boombox ~= -1 then
                        if not IsEntityAttached(boombox) or GetEntityAttachedTo(boombox) ~= ped then
                            broken = true
                        elseif not IsEntityPlayingAnim(ped, "molly@boombox1", "boombox1_clip", 3) then
                            broken = true
                        end
                    end
                end

                if broken then
                    lastReattach = now
                    if IsPedRagdoll(ped) then
                        while IsPedRagdoll(ped) do Wait(100) end
                        Wait(500)
                    end
                    if BoomBox.holdingboom then
                        ReattachBoombox(ped)
                    end
                end
            end
        end

        carryControlThread = false
    end)
end

--- Open MusicRadio UI for boombox
---@param entity number The boombox entity
function OpenMusicRadioUI(entity)
    if BoomBox.open then return end
    local musicId = GetBoomboxMusicId(entity)
    if not musicId then
        VFW.ShowNotification({ type = 'ERROR', content = 'Boombox non synchronisee, reessayez dans un instant.' })
        return
    end
    BoomBox.open = true
    BoomBox.currentEntity = entity
    BoomBox.mode = "boombox"
    BoomBox.currentMusicId = musicId

    -- Auto-detect: si la boombox n'est pas attachée à un ped, c'est une interaction au sol
    if not IsEntityAttached(entity) then
        BoomBox.isGroundInteraction = true
    end

    -- Charger les playlists depuis le serveur
    local playlists = LoadPlayerPlaylists()

    -- Récupérer l'état actuel de la boombox depuis le serveur
    local serverState = TriggerServerCallback("boombox:getState", BoomBox.currentMusicId)
    local myServerId = GetPlayerServerId(PlayerId())

    local isController = true
    local controllerName = nil
    local currentTrack = nil
    local playState = "stopped"
    local volume = BoomBox.Volume * 100

    if serverState then
        isController = (serverState.controllerId == myServerId) or (serverState.controllerId == nil)
        controllerName = serverState.controllerName
        currentTrack = serverState.currentTrack
        playState = serverState.playState or "stopped"
        volume = (serverState.volume or BoomBox.Volume) * 100
    end

    -- KeepInput true si on porte (pour pouvoir marcher), false si au sol
    VFW.Nui.Focus(true, not BoomBox.isGroundInteraction)
    TriggerEvent('chat:setDisabled', true)

    SendNUIMessage({
        action = "nui:musicradio:open",
        data = {
            mode = "boombox",
            volume = volume,
            playlists = playlists,
            isController = isController,
            controllerName = controllerName,
            currentTrack = currentTrack,
            playState = playState
        }
    })

    VFW.DisableEscapeMenu(true)

    CreateThread(function()
        if BoomBox.isGroundInteraction then
            if not LoadAnimDictAsync("pickup_object") then return end
            TaskPlayAnim(PlayerPedId(), "pickup_object", "pickup_low", 2.0, 2.0, -1, 0, 0, false, false, false)
            RemoveAnimDict("pickup_object")
        end
    end)

    CreateThread(function()
        while BoomBox.open do
            Wait(0)
        end
    end)
end

--- Open MusicRadio UI for vehicle
---@param vehicle number The vehicle entity
function OpenVehicleMusicRadioUI(vehicle)
    if BoomBox.open then return end
    BoomBox.open = true
    BoomBox.currentEntity = vehicle
    BoomBox.mode = "vehicle"

    local netId = VehToNet(vehicle)
    BoomBox.currentMusicId = 'veh_' .. netId

    -- Charger les playlists depuis le serveur
    local playlists = LoadPlayerPlaylists()

    -- Récupérer l'état actuel du véhicule depuis le serveur
    local serverState = TriggerServerCallback("vehicleMusic:getState", netId)

    -- Déterminer les infos à afficher
    local myServerId = GetPlayerServerId(PlayerId())
    local isController = true
    local controllerName = nil
    local currentTrack = nil
    local playState = "stopped"
    local volume = BoomBox.Volume * 100

    if serverState then
        isController = (serverState.controllerId == myServerId) or (serverState.controllerId == nil)
        controllerName = serverState.controllerName
        currentTrack = serverState.title and { title = serverState.title, url = serverState.url } or nil
        playState = serverState.playState or "stopped"
        volume = (serverState.volume or BoomBox.Volume) * 100
    end

    VFW.Nui.Focus(true, false)
    TriggerEvent('chat:setDisabled', true)

    SendNUIMessage({
        action = "nui:musicradio:open",
        data = {
            mode = "vehicle",
            volume = volume,
            playlists = playlists,
            isController = isController,
            controllerName = controllerName,
            currentTrack = currentTrack,
            playState = playState
        }
    })

    VFW.DisableEscapeMenu(true)

    CreateThread(function()
        while BoomBox.open do
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 47, true)
            DisableControlAction(0, 58, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            DisableControlAction(0, 270, true)
            DisableControlAction(0, 271, true)
            Wait(0)
        end
    end)
end

--- Thread to detect nearby boombox and show interaction prompt
CreateThread(function()
    while true do
        local sleep = 500

        -- Don't show prompt if UI is already open
        if not BoomBox.open then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local closestBoombox = GetClosestObjectOfType(playerCoords, 3.0, `prop_boombox_01`, false, false, false)

            -- Si on porte la boombox sur l'épaule
            if BoomBox.holdingboom and closestBoombox ~= 0 and closestBoombox ~= -1 then
                sleep = 0

                -- Helper en haut à gauche
                VFW.ShowHelpNotification("~INPUT_CONTEXT~ Ouvrir la BoomBox~n~~INPUT_DETONATE~ Poser la BoomBox", nil, false)

                -- E pour ouvrir l'UI
                if VFW.Interact.JustPressed(0, 38) then
                    OpenMusicRadioUI(closestBoombox)
                end

                -- G pour poser
                if IsControlJustPressed(0, 47) then
                    PoseLaBoombox()
                end

            -- Boombox posée au sol à proximité (uniquement celles posées par les joueurs, pas les props de décor)
            elseif closestBoombox ~= 0 and closestBoombox ~= -1 then
                if not IsEntityAttached(closestBoombox) and NetworkGetEntityIsNetworked(closestBoombox) then
                    local boomboxCoords = GetEntityCoords(closestBoombox)
                    local distance = #(playerCoords - boomboxCoords)

                    if distance < 1.0 then
                        sleep = 0

                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir la BoomBox", nil, false)

                        if VFW.Interact.JustPressed(0, 38) then
                            BoomBox.isGroundInteraction = true
                            OpenMusicRadioUI(closestBoombox)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

--region ------ EVENTS CLIENT POUR SYNC UI BOOMBOX ------

--- Recevoir une mise à jour d'état de boombox (sync temps réel)
RegisterNetEvent("core:boombox:stateUpdate", function(musicId, state)
    -- Si l'UI est ouverte pour cette boombox, mettre à jour
    if BoomBox.open and BoomBox.currentMusicId == musicId then
        local myServerId = GetPlayerServerId(PlayerId())
        local isController = (state.controllerId == myServerId) or (state.controllerId == nil)

        SendNUIMessage({
            action = "nui:musicradio:stateUpdate",
            data = {
                isController = isController,
                controllerName = state.controllerName,
                currentTrack = state.currentTrack,
                playState = state.playState,
                volume = state.volume * 100
            }
        })
    end
end)

--- Recevoir notification que l'état d'une boombox a été effacé (stop)
RegisterNetEvent("core:boombox:stateCleared", function(musicId)
    -- Si l'UI est ouverte pour cette boombox, réinitialiser
    if BoomBox.open and BoomBox.currentMusicId == musicId then
        SendNUIMessage({
            action = "nui:musicradio:stateUpdate",
            data = {
                isController = true,
                controllerName = nil,
                currentTrack = nil,
                playState = "stopped",
                volume = BoomBox.Volume * 100
            }
        })
    end
end)

--- Recevoir un seek depuis le serveur (sync)
RegisterNetEvent("core:boombox:seekC", function(musicId, time)
    if xSound:soundExists(musicId) then
        xSound:setTimeStamp(musicId, time)
    end
end)

--- NUI Callback: Prendre le contrôle de la boombox
RegisterNUICallback("nui:musicradio:takeControl", function(data, cb)
    if BoomBox.currentMusicId then
        TriggerServerEvent("core:boombox:takeControl", BoomBox.currentMusicId)
    end
    if cb then cb({ success = true }) end
end)

--- NUI Callback: Seek (changer la position de lecture)
RegisterNUICallback("nui:musicradio:seek", function(data, cb)
    if not data.time then
        if cb then cb({ success = false }) end
        return
    end

    -- Déterminer le musicId selon le mode
    local musicId = nil
    if BoomBox.mode == "boombox" then
        musicId = BoomBox.currentMusicId
    elseif BoomBox.mode == "vehicle" and BoomBox.currentEntity then
        local vehicle = BoomBox.currentEntity
        if vehicle and DoesEntityExist(vehicle) then
            local netId = VehToNet(vehicle)
            if netId then
                musicId = 'veh_' .. netId
            end
        end
    end

    if not musicId then
        if cb then cb({ success = false }) end
        return
    end

    -- Appliquer localement immédiatement
    if xSound:soundExists(musicId) then
        xSound:setTimeStamp(musicId, data.time)
    end

    -- Vérifier cooldown seulement pour l'envoi au serveur
    if IsActionOnCooldown("seek", musicId) then
        if cb then cb({ success = true }) end
        return
    end
    SetActionCooldown("seek", musicId)

    -- Sync avec le serveur (boombox uniquement pour l'instant)
    if BoomBox.mode == "boombox" then
        TriggerServerEvent("core:boombox:seek", musicId, data.time)
    elseif BoomBox.mode == "vehicle" and BoomBox.currentEntity and DoesEntityExist(BoomBox.currentEntity) then
        TriggerServerEvent("core:vehicleMusic:seek", VehToNet(BoomBox.currentEntity), data.time)
    end

    if cb then cb({ success = true }) end
end)

--- Thread de mise à jour du temps de lecture (quand UI ouverte)
CreateThread(function()
    while true do
        Wait(500) -- Mise à jour toutes les 500ms

        if BoomBox.open then
            local musicId = nil

            -- Déterminer le musicId selon le mode
            if BoomBox.mode == "boombox" and BoomBox.currentMusicId then
                musicId = BoomBox.currentMusicId
            elseif BoomBox.mode == "vehicle" and BoomBox.currentEntity then
                local vehicle = BoomBox.currentEntity
                if vehicle and DoesEntityExist(vehicle) then
                    local netId = VehToNet(vehicle)
                    if netId then
                        musicId = 'veh_' .. netId
                    end
                end
            end

            if musicId and xSound:soundExists(musicId) then
                -- Ne pas mettre à jour le temps si le son est en pause
                if not xSound:isPaused(musicId) then
                    local currentTime = xSound:getCurrentTime(musicId)
                    local duration = xSound:getMaxDuration(musicId)

                    -- Envoyer à l'UI si valeurs valides
                    if currentTime and currentTime >= 0 and duration and duration > 0 then
                        SendNUIMessage({
                            action = "nui:musicradio:timeUpdate",
                            data = {
                                currentTime = currentTime,
                                duration = duration
                            }
                        })
                    end
                end
            end
        end
    end
end)

--- Thread de détection de fin de piste (pour passer à la suivante)
CreateThread(function()
    local lastMusicId = nil
    local wasPlaying = false

    while true do
        Wait(1000)

        if BoomBox.currentMusicId and #BoomBox.queue > 0 and BoomBox.queueIndex > 0 then
            local musicId = BoomBox.currentMusicId

            if xSound:soundExists(musicId) then
                local currentTime = xSound:getCurrentTime(musicId)
                local duration = xSound:getMaxDuration(musicId)
                local isPlaying = xSound:isPlaying(musicId)

                -- Détecter fin de piste (temps >= durée - 1 seconde)
                if duration and duration > 0 and currentTime and currentTime >= (duration - 1) then
                    -- Passer à la piste suivante
                    PlayNextTrack()
                end

                wasPlaying = isPlaying
            else
                -- Le son n'existe plus, vérifier s'il jouait avant
                if wasPlaying and lastMusicId == musicId then
                    PlayNextTrack()
                end
                wasPlaying = false
            end

            lastMusicId = musicId
        end
    end
end)

local function SendQueueTrack(track, coords)
    if BoomBox.mode == "vehicle" then
        local vehicle = BoomBox.currentEntity
        if not vehicle or not DoesEntityExist(vehicle) then return end

        local netId = VehToNet(vehicle)
        if not netId or netId == 0 then return end

        local musicId = 'veh_' .. netId
        local title = track.title or "Lecture directe"

        if not VehicleMusicActive[netId] then
            ActiveVehicleMusicCount = ActiveVehicleMusicCount + 1
        end
        VehicleMusicActive[netId] = {
            musicId = musicId,
            url = track.url,
            volume = BoomBox.Volume,
            vehicle = vehicle,
            title = title
        }

        TriggerServerEvent("core:vehicleMusic:play", netId, track.url, BoomBox.Volume, coords, title)
        return
    end

    TriggerServerEvent("core:boombox:playTrack", BoomBox.currentMusicId, track.url, track.title, BoomBox.Volume, coords)
end

--- Jouer la piste suivante dans la queue
function PlayNextTrack()
    if #BoomBox.queue == 0 then return end

    local nextIndex = BoomBox.queueIndex + 1

    -- Si on dépasse la fin de la queue, arrêter ou boucler
    if nextIndex > #BoomBox.queue then
        -- Fin de la playlist
        BoomBox.queueIndex = 0
        BoomBox.queue = {}

        -- Notifier l'UI
        SendNUIMessage({
            action = "nui:musicradio:queueEnd",
            data = {}
        })
        return
    end

    BoomBox.queueIndex = nextIndex
    local track = BoomBox.queue[nextIndex]

    if track and BoomBox.currentMusicId then
        local entity = (BoomBox.currentEntity and DoesEntityExist(BoomBox.currentEntity)) and BoomBox.currentEntity or PlayerPedId()
        local coords = GetEntityCoords(entity)

        -- Jouer la nouvelle piste
        SendQueueTrack(track, coords)

        -- Mettre à jour l'UI
        SendNUIMessage({
            action = "nui:musicradio:queueUpdate",
            data = {
                queue = BoomBox.queue,
                queueIndex = BoomBox.queueIndex,
                currentTrack = track
            }
        })
    end
end

--- Jouer la piste précédente dans la queue
function PlayPreviousTrack()
    if #BoomBox.queue == 0 or BoomBox.queueIndex <= 1 then return end

    BoomBox.queueIndex = BoomBox.queueIndex - 1
    local track = BoomBox.queue[BoomBox.queueIndex]

    if track and BoomBox.currentMusicId then
        local entity = (BoomBox.currentEntity and DoesEntityExist(BoomBox.currentEntity)) and BoomBox.currentEntity or PlayerPedId()
        local coords = GetEntityCoords(entity)

        SendQueueTrack(track, coords)

        SendNUIMessage({
            action = "nui:musicradio:queueUpdate",
            data = {
                queue = BoomBox.queue,
                queueIndex = BoomBox.queueIndex,
                currentTrack = track
            }
        })
    end
end

--- Mélanger un tableau
local function ShuffleTable(tbl)
    local shuffled = {}
    for i, v in ipairs(tbl) do
        shuffled[i] = v
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

--- NUI Callback: Lancer une playlist
RegisterNUICallback("nui:musicradio:playPlaylist", function(data, cb)
    if not data.tracks or #data.tracks == 0 then
        if cb then cb({ success = false }) end
        return
    end

    local tracks = data.tracks
    local shuffle = data.shuffle or false

    -- Mélanger si demandé
    if shuffle then
        tracks = ShuffleTable(tracks)
        BoomBox.shuffle = true
    else
        BoomBox.shuffle = false
    end

    -- Initialiser la queue
    BoomBox.queue = tracks
    BoomBox.queueIndex = 1

    local firstTrack = tracks[1]
    if firstTrack and BoomBox.currentMusicId then
        local entity = (BoomBox.currentEntity and DoesEntityExist(BoomBox.currentEntity)) and BoomBox.currentEntity or PlayerPedId()
        local coords = GetEntityCoords(entity)

        -- Jouer la première piste
        SendQueueTrack(firstTrack, coords)

        -- Sync la queue avec le serveur
        if BoomBox.mode ~= "vehicle" then
            TriggerServerEvent("core:boombox:setQueue", BoomBox.currentMusicId, tracks, 1)
        end
    end

    if cb then cb({ success = true }) end
end)

--- NUI Callback: Piste suivante
RegisterNUICallback("nui:musicradio:nextTrack", function(data, cb)
    PlayNextTrack()
    if cb then cb({ success = true }) end
end)

--- NUI Callback: Piste précédente
RegisterNUICallback("nui:musicradio:prevTrack", function(data, cb)
    PlayPreviousTrack()
    if cb then cb({ success = true }) end
end)

--- NUI Callback: Vider la queue
RegisterNUICallback("nui:musicradio:clearQueue", function(data, cb)
    BoomBox.queue = {}
    BoomBox.queueIndex = 0
    TriggerServerEvent("core:boombox:clearQueue", BoomBox.currentMusicId)
    if cb then cb({ success = true }) end
end)

--endregion

--region ------ EVENTS CLIENT POUR MUSIQUE VÉHICULE (SYNC) ------

-- Recevoir la musique d'un véhicule (depuis le serveur)
RegisterNetEvent("core:vehicleMusic:playC", function(netId, url, volume, coords, title)
    if streamerModeEnabled then return end
    if type(netId) ~= "number" or type(url) ~= "string" or url == "" then return end
    if not coords or type(coords) ~= "vector3" and type(coords) ~= "table" then return end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))

    -- Ne pas jouer si trop loin
    if distance > MAX_SOUND_DISTANCE then return end

    local musicId = 'veh_' .. netId

    -- Déduplication : si la même URL joue déjà sur ce véhicule, ne rien faire
    local existing = VehicleMusicActive[netId]
    if existing and existing.url == url and xSound:soundExists(musicId) then
        if existing.volume ~= volume then
            xSound:setVolume(musicId, volume)
            existing.volume = volume
        end
        return
    end

    -- Détruire le son existant si présent (changement de track)
    if xSound:soundExists(musicId) then
        xSound:Destroy(musicId)
    end

    -- Jouer le son
    xSound:PlayUrlPos(musicId, url, volume, coords)

    -- Attendre que l'entité véhicule soit dispo localement (peut prendre quelques frames après un join/scope)
    local vehicle = NetToVeh(netId)
    if not DoesEntityExist(vehicle) then
        local tries = 0
        while not DoesEntityExist(vehicle) and tries < 20 do
            Wait(100)
            vehicle = NetToVeh(netId)
            tries = tries + 1
        end
    end

    -- Déterminer la distance selon l'état des fenêtres
    local shouldLeak = false
    if DoesEntityExist(vehicle) then
        shouldLeak = ShouldSoundLeakFromVehicle(vehicle)
    end

    local soundDistance = shouldLeak and SOUND_DISTANCE_OPEN or SOUND_DISTANCE_CLOSED
    xSound:Distance(musicId, soundDistance)
    xSound:setVolume(musicId, volume)

    -- Stocker dans le cache (même si le véhicule n'a pas encore son entité locale)
    if not VehicleMusicActive[netId] then
        ActiveVehicleMusicCount = ActiveVehicleMusicCount + 1
    end
    VehicleMusicActive[netId] = {
        musicId = musicId,
        url = url,
        volume = volume,
        vehicle = DoesEntityExist(vehicle) and vehicle or nil,
        title = title or "Lecture directe"
    }
end)

-- Recevoir pause/resume d'un véhicule
---@param netId number Network ID du véhicule
---@param action string "pause" ou "resume"
---@param resumeTime number|nil Timestamp à reprendre (en secondes)
RegisterNetEvent("core:vehicleMusic:pauseC", function(netId, action, resumeTime)
    local musicId = 'veh_' .. netId

    if xSound:soundExists(musicId) then
        if action == "resume" then
            -- Reprendre au timestamp sauvegardé
            if resumeTime and resumeTime > 0 then
                xSound:setTimeStamp(musicId, resumeTime)
            end
            xSound:Resume(musicId)
        elseif action == "pause" then
            xSound:Pause(musicId)
        end
    end
end)

-- Recevoir stop d'un véhicule
RegisterNetEvent("core:vehicleMusic:stopC", function(netId)
    local musicId = 'veh_' .. netId

    if xSound:soundExists(musicId) then
        xSound:Destroy(musicId)
    end
    if VehicleMusicActive[netId] then
        VehicleMusicActive[netId] = nil
        ActiveVehicleMusicCount = math.max(0, ActiveVehicleMusicCount - 1)
    end
end)

-- Recevoir changement de volume d'un véhicule
RegisterNetEvent("core:vehicleMusic:volumeC", function(netId, volume)
    if VehicleMusicActive[netId] then
        VehicleMusicActive[netId].volume = volume
        UpdateVehicleSoundDistance(netId)
    end
end)

--- Resync musique vehicule via state bag entite (auto-replique au scope-in).
--- Couvre: late-join, joueur qui s'approche du vehicule apres le play, respawn.
AddStateBagChangeHandler('vehicleMusic', nil, function(bagName, _key, value, _, _)
    if streamerModeEnabled then return end

    local netId = tonumber(bagName:match("^entity:(%d+)$"))
    if not netId then return end
    local musicId = 'veh_' .. netId

    -- Bag efface = stop => detruire le son local s'il existe
    if not value then
        if xSound:soundExists(musicId) then
            xSound:Destroy(musicId)
        end
        if VehicleMusicActive[netId] then
            VehicleMusicActive[netId] = nil
            ActiveVehicleMusicCount = math.max(0, ActiveVehicleMusicCount - 1)
        end
        return
    end

    -- Sound deja en cours localement (initie via core:vehicleMusic:playC) => rien a faire
    if xSound:soundExists(musicId) then return end

    -- Resync uniquement si en lecture
    if value.playState ~= "playing" then return end
    if not value.url then return end

    local ent = NetworkGetEntityFromNetworkId(netId)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return end

    local coords = GetEntityCoords(ent)
    local mycoords = GetEntityCoords(PlayerPedId())
    if #(mycoords - coords) > MAX_SOUND_DISTANCE + 10.0 then return end

    local volume = value.volume or 0.7

    xSound:PlayUrlPos(musicId, value.url, volume, coords)

    -- Distance selon etat fenetres
    local shouldLeak = ShouldSoundLeakFromVehicle(ent)
    local soundDistance = shouldLeak and SOUND_DISTANCE_OPEN or SOUND_DISTANCE_CLOSED
    xSound:Distance(musicId, soundDistance)
    xSound:setVolume(musicId, volume)

    VehicleMusicActive[netId] = {
        musicId = musicId,
        url = value.url,
        volume = volume,
        vehicle = ent,
        title = value.title or "Lecture directe"
    }
    ActiveVehicleMusicCount = ActiveVehicleMusicCount + 1

    -- Offset via horloge serveur partagee (os.time secondes)
    if value.startedAtEpoch then
        local elapsed = GetCloudTimeAsInt() - value.startedAtEpoch
        if elapsed > 1 then
            CreateThread(function()
                local tries = 0
                while not xSound:isPlaying(musicId) and tries < 50 do
                    Wait(100)
                    tries = tries + 1
                end
                if xSound:soundExists(musicId) then
                    xSound:setTimeStamp(musicId, elapsed)
                end
            end)
        end
    end
end)

--endregion

--region ------ ROOM OCCLUSION MONITORING (BOOMBOX) ------

-- Thread de monitoring de room occlusion pour les boombox (OPTIMISÉ)
CreateThread(function()
    while true do
        -- Attendre plus longtemps si aucune boombox active
        if ActiveBoomboxCount == 0 then
            Wait(3000)
        else
            Wait(1000) -- Vérifier chaque seconde si des boombox sont actives

            -- Vérifier l'occlusion pour toutes les boombox actives
            for musicId, data in pairs(ActiveBoomboxSounds) do
                if xSound:soundExists(musicId) then
                    -- Récupérer l'entité depuis le cache ou le musicId
                    local entity = data.entity or GetEntityFromMusicId(musicId)
                    local canHear, volumeMultiplier = CheckPlayerAudioEligibility(data.coords, MAX_SOUND_DISTANCE, entity)

                    -- Appliquer le nouveau multiplicateur si différent
                    if volumeMultiplier ~= data.currentMultiplier then
                        local newVolume = data.baseVolume * volumeMultiplier
                        xSound:setVolume(musicId, newVolume)
                        xSound:Distance(musicId, GetSoundDistance(newVolume))
                        data.currentMultiplier = volumeMultiplier
                    end
                else
                    -- Le son n'existe plus, le retirer du cache
                    ActiveBoomboxSounds[musicId] = nil
                    ActiveBoomboxCount = math.max(0, ActiveBoomboxCount - 1)
                end
            end
        end
    end
end)

--endregion

--region ------ PROXIMITY SYNC (PATTERN PLATINE) ------

--- Lance localement un son boombox a partir d'un etat serveur (si pas deja actif).
--- Calque sur core:plyBoomSongC mais sans broadcast (utilise par le poll).
---@param data table { musicId, url, volume, coords, title, currentTime }
local function SyncBoomboxFromServerState(data)
    if streamerModeEnabled then return end
    if not data or not data.musicId or not data.url then return end
    if xSound:soundExists(data.musicId) then return end -- deja actif

    local coords = type(data.coords) == "vector3" and data.coords
        or vector3(data.coords.x, data.coords.y, data.coords.z)

    local mycoords = GetEntityCoords(PlayerPedId())
    if #(mycoords - coords) > MAX_SOUND_DISTANCE + 10.0 then return end

    local entity = GetEntityFromMusicId(data.musicId)
    local canHear, volumeMultiplier = CheckPlayerAudioEligibility(coords, MAX_SOUND_DISTANCE, entity)
    if not canHear then return end

    local volume = data.volume or 0.7
    local adjustedVolume = volume * volumeMultiplier
    local soundDistance = GetSoundDistance(adjustedVolume)

    xSound:PlayUrlPos(data.musicId, data.url, adjustedVolume, coords)
    xSound:Distance(data.musicId, soundDistance)
    xSound:setVolume(data.musicId, adjustedVolume)

    if ActiveBoomboxSounds then
        if not ActiveBoomboxSounds[data.musicId] then
            ActiveBoomboxCount = ActiveBoomboxCount + 1
        end
        ActiveBoomboxSounds[data.musicId] = {
            coords = coords,
            baseVolume = volume,
            currentMultiplier = volumeMultiplier,
            entity = entity
        }
    end

    -- Rattraper l'offset de lecture
    local currentTime = data.currentTime or 0
    if currentTime > 1 then
        CreateThread(function()
            local tries = 0
            while not xSound:isPlaying(data.musicId) and tries < 50 do
                Wait(100)
                tries = tries + 1
            end
            if xSound:soundExists(data.musicId) then
                xSound:setTimeStamp(data.musicId, currentTime)
            end
        end)
    end
end

--- Lance localement un son vehicule a partir d'un etat serveur (si pas deja actif).
---@param data table { netId, url, volume, coords, title, currentTime }
local function SyncVehicleMusicFromServerState(data)
    if streamerModeEnabled then return end
    if not data or not data.netId or not data.url then return end

    local musicId = 'veh_' .. data.netId
    if xSound:soundExists(musicId) then return end -- deja actif

    local coords = type(data.coords) == "vector3" and data.coords
        or vector3(data.coords.x, data.coords.y, data.coords.z)

    local mycoords = GetEntityCoords(PlayerPedId())
    if #(mycoords - coords) > MAX_SOUND_DISTANCE + 10.0 then return end

    local vehicle = NetToVeh(data.netId)
    local volume = data.volume or 0.7

    xSound:PlayUrlPos(musicId, data.url, volume, coords)

    local shouldLeak = false
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        shouldLeak = ShouldSoundLeakFromVehicle(vehicle)
    end
    local soundDistance = shouldLeak and SOUND_DISTANCE_OPEN or SOUND_DISTANCE_CLOSED
    xSound:Distance(musicId, soundDistance)
    xSound:setVolume(musicId, volume)

    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        VehicleMusicActive[data.netId] = {
            musicId = musicId,
            url = data.url,
            volume = volume,
            vehicle = vehicle,
            title = data.title or "Lecture directe"
        }
        ActiveVehicleMusicCount = ActiveVehicleMusicCount + 1
    end

    -- Rattraper l'offset de lecture
    local currentTime = data.currentTime or 0
    if currentTime > 1 then
        CreateThread(function()
            local tries = 0
            while not xSound:isPlaying(musicId) and tries < 50 do
                Wait(100)
                tries = tries + 1
            end
            if xSound:soundExists(musicId) then
                xSound:setTimeStamp(musicId, currentTime)
            end
        end)
    end
end

--- Sync depuis le serveur tous les sons proches (boombox + vehicules).
local function PollServerForNearbySounds()
    local result = TriggerServerCallback("core:audio:getActiveSounds")
    if not result then return end

    if result.boomboxes then
        for _, data in pairs(result.boomboxes) do
            SyncBoomboxFromServerState(data)
        end
    end

    if result.vehicles then
        for _, data in pairs(result.vehicles) do
            SyncVehicleMusicFromServerState(data)
        end
    end
end

-- Sync initiale au chargement du joueur (rattrape les sons deja actifs)
CreateThread(function()
    while not VFW or not VFW.IsPlayerLoaded or not VFW.IsPlayerLoaded() do
        Wait(500)
    end
    Wait(3000) -- Laisser le temps a xsound et au scope reseau de s'initialiser
    PollServerForNearbySounds()
end)

-- Thread de proximite : re-sync periodiquement pour rattraper les sons
-- des qu'on entre dans le rayon (calque sur le thread de proximite des platines).
CreateThread(function()
    while not VFW or not VFW.IsPlayerLoaded or not VFW.IsPlayerLoaded() do
        Wait(1000)
    end
    Wait(8000)
    while true do
        Wait(5000)
        if not streamerModeEnabled then
            PollServerForNearbySounds()
        end
    end
end)

--endregion

--region ------ CLEANUP ON RESOURCE STOP ------

--- Nettoie toutes les ressources audio lors de l'arrêt de la ressource
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Détruire tous les sons actifs
    for musicId, _ in pairs(ActiveBoomboxSounds) do
        if xSound:soundExists(musicId) then
            xSound:Destroy(musicId)
        end
    end

    -- Reset des caches boombox
    ActiveBoomboxSounds = {}
    ActiveBoomboxCount = 0

    -- Détruire tous les sons véhicules actifs
    for netId, data in pairs(VehicleMusicActive) do
        if data.musicId and xSound:soundExists(data.musicId) then
            xSound:Destroy(data.musicId)
        end
    end
    VehicleMusicActive = {}
    ActiveVehicleMusicCount = 0

    -- Reset des threads de position
    ActivePositionThreads = {}

    -- Fermer l'UI si ouverte
    if BoomBox.open then
        VFW.Nui.Focus(false, false)
        VFW.DisableEscapeMenu(false)
        TriggerEvent('chat:setDisabled', false)
        BoomBox.open = false
    end
end)

--endregion
