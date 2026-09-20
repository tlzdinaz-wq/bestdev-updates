---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- SYSTEME GPS MISSION (Style GTA)
-- Tracé jaune sur la route + marqueurs visuels
-- ============================================

local GPSMission = {}

-- Configuration
local Config = {
    -- Couleurs GPS disponibles
    Colors = {
        RED = 1,
        GREEN = 2,
        BLUE = 3,
        YELLOW = 5,      -- Mission standard
        ORANGE = 17,
        PURPLE = 7,
        PINK = 8
    },

    -- Sprites blip courants
    Sprites = {
        STANDARD = 1,
        DESTINATION = 38,
        OBJECTIVE = 58,
        WAYPOINT = 8,
        PERSON = 480,
        DRUG = 140,
        MONEY = 500,
        WARNING = 60
    },

    -- Marqueurs visuels (désactivés par défaut - la minimap suffit)
    Markers = {
        showLightColumn = false,     -- Colonne de lumière (désactivé)
        showGroundCircle = false,    -- Cercle au sol (désactivé)
        showDistance = false,        -- Affichage distance (désactivé)
        columnHeight = 80.0,         -- Hauteur de la colonne
        circleRadius = 2.5,          -- Rayon du cercle au sol
        distanceY = 0.92             -- Position Y du texte distance
    },

    -- Sons
    Sounds = {
        onSet = { name = "WAYPOINT_SET", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
        onReach = { name = "CHECKPOINT_NORMAL", set = "HUD_MINI_GAME_SOUNDSET" },
        onRemove = { name = "CANCEL", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" }
    }
}

-- État interne
local State = {
    objectives = {},           -- Table des objectifs actifs (par ID)
    activeThreads = {},        -- Threads actifs
    primaryObjective = nil     -- ID de l'objectif principal (pour le tracé GPS)
}

-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================

local function PlayGPSSound(soundType)
    local sound = Config.Sounds[soundType]
    if sound then
        PlaySoundFrontend(-1, sound.name, sound.set, false)
    end
end

local function DrawText2D(text, x, y, scale, centered)
    scale = scale or 0.4
    centered = centered ~= false

    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextOutline()
    SetTextDropShadow()

    if centered then
        SetTextCentre(true)
    end

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function GetDistanceToObjective(objectiveId)
    local obj = State.objectives[objectiveId]
    if not obj then return 0 end

    local playerCoords = GetEntityCoords(PlayerPedId())
    return #(playerCoords - obj.coords)
end

-- ============================================
-- GESTION DES OBJECTIFS
-- ============================================

--- Crée un nouvel objectif GPS avec tracé sur la route
---@param id string Identifiant unique de l'objectif
---@param x number Coordonnée X
---@param y number Coordonnée Y
---@param z number Coordonnée Z
---@param options table Options (sprite, label, color, routeColor, showMarkers, sound)
function GPSMission.SetObjective(id, x, y, z, options)
    options = options or {}

    -- Supprimer l'ancien objectif avec cet ID s'il existe
    if State.objectives[id] then
        GPSMission.RemoveObjective(id)
    end

    local coords = vector3(x, y, z)

    -- Créer le blip
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, options.sprite or Config.Sprites.DESTINATION)
    SetBlipColour(blip, options.color or Config.Colors.YELLOW)
    SetBlipScale(blip, options.scale or 0.5)
    SetBlipAsShortRange(blip, false)

    -- Nom du blip
    if options.label then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(options.label)
        EndTextCommandSetBlipName(blip)
    end

    -- Activer le tracé GPS si c'est l'objectif principal ou si demandé
    local showRoute = options.showRoute ~= false
    if showRoute then
        -- Désactiver le tracé de l'ancien objectif principal
        if State.primaryObjective and State.objectives[State.primaryObjective] then
            local oldBlip = State.objectives[State.primaryObjective].blip
            if oldBlip and DoesBlipExist(oldBlip) then
                SetBlipRoute(oldBlip, false)
            end
        end

        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, options.routeColor or Config.Colors.YELLOW)
        State.primaryObjective = id
    end

    -- Stocker l'objectif
    State.objectives[id] = {
        blip = blip,
        coords = coords,
        options = options,
        hasRoute = showRoute,
        showMarkers = options.showMarkers ~= false,
        markerColor = options.markerColor or { r = 255, g = 255, b = 0, a = 150 },
        createdAt = GetGameTimer()
    }

    -- Démarrer le thread des marqueurs visuels si demandé
    if options.showMarkers ~= false then
        GPSMission.StartMarkerThread(id)
    end

    -- Son de confirmation
    if options.sound ~= false then
        PlayGPSSound("onSet")
    end

    return id
end

--- Crée un objectif attaché à une entité (PNJ, véhicule, etc.)
---@param id string Identifiant unique
---@param entity number Handle de l'entité
---@param options table Options
function GPSMission.SetEntityObjective(id, entity, options)
    options = options or {}

    if State.objectives[id] then
        GPSMission.RemoveObjective(id)
    end

    if not entity or not DoesEntityExist(entity) then
        print("[GPS MISSION] Error: Entity does not exist")
        return nil
    end

    -- Créer le blip sur l'entité
    local blip = AddBlipForEntity(entity)
    SetBlipSprite(blip, options.sprite or Config.Sprites.PERSON)
    SetBlipColour(blip, options.color or Config.Colors.YELLOW)
    SetBlipScale(blip, options.scale or 0.5)
    SetBlipAsShortRange(blip, false)

    if options.label then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(options.label)
        EndTextCommandSetBlipName(blip)
    end

    -- Tracé GPS
    local showRoute = options.showRoute ~= false
    if showRoute then
        if State.primaryObjective and State.objectives[State.primaryObjective] then
            local oldBlip = State.objectives[State.primaryObjective].blip
            if oldBlip and DoesBlipExist(oldBlip) then
                SetBlipRoute(oldBlip, false)
            end
        end

        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, options.routeColor or Config.Colors.YELLOW)
        State.primaryObjective = id
    end

    State.objectives[id] = {
        blip = blip,
        entity = entity,
        coords = nil, -- Sera mis à jour dynamiquement
        options = options,
        hasRoute = showRoute,
        showMarkers = options.showMarkers == true, -- Désactivé par défaut pour entités
        markerColor = options.markerColor or { r = 255, g = 255, b = 0, a = 150 },
        createdAt = GetGameTimer()
    }

    -- Thread pour mettre à jour les coords et marqueurs
    if options.showMarkers then
        GPSMission.StartEntityMarkerThread(id)
    end

    if options.sound ~= false then
        PlayGPSSound("onSet")
    end

    return id
end

--- Supprime un objectif
---@param id string Identifiant de l'objectif
---@param playSound boolean Jouer le son de suppression
function GPSMission.RemoveObjective(id, playSound)
    local obj = State.objectives[id]
    if not obj then return end

    -- Arrêter le thread des marqueurs
    if State.activeThreads[id] then
        State.activeThreads[id] = false
    end

    -- Supprimer le blip
    if obj.blip and DoesBlipExist(obj.blip) then
        SetBlipRoute(obj.blip, false)
        RemoveBlip(obj.blip)
    end

    -- Nettoyer
    State.objectives[id] = nil

    -- Si c'était l'objectif principal, en désigner un autre
    if State.primaryObjective == id then
        State.primaryObjective = nil
        -- Chercher un autre objectif avec route
        for otherId, otherObj in pairs(State.objectives) do
            if otherObj.hasRoute and otherObj.blip and DoesBlipExist(otherObj.blip) then
                SetBlipRoute(otherObj.blip, true)
                State.primaryObjective = otherId
                break
            end
        end
    end

    if playSound then
        PlayGPSSound("onRemove")
    end
end

--- Supprime tous les objectifs
function GPSMission.ClearAllObjectives()
    for id, _ in pairs(State.objectives) do
        GPSMission.RemoveObjective(id, false)
    end
    State.primaryObjective = nil
    PlayGPSSound("onRemove")
end

-- ============================================
-- THREADS MARQUEURS VISUELS
-- ============================================

--- Thread pour marqueurs sur coordonnées fixes
function GPSMission.StartMarkerThread(id)
    if State.activeThreads[id] then return end
    State.activeThreads[id] = true

    Citizen.CreateThread(function()
        while State.activeThreads[id] and State.objectives[id] do
            local obj = State.objectives[id]
            if not obj then break end

            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - obj.coords)

            -- Afficher les marqueurs seulement si assez proche (optimisation)
            if distance < 500.0 then
                local x, y, z = obj.coords.x, obj.coords.y, obj.coords.z
                local color = obj.markerColor

                -- Colonne de lumière (visible de loin)
                if Config.Markers.showLightColumn then
                    DrawMarker(
                        27, -- Type: colonne verticale
                        x, y, z,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        1.0, 1.0, Config.Markers.columnHeight,
                        color.r, color.g, color.b, math.floor(color.a * 0.6),
                        false, false, 2, false, nil, nil, false
                    )
                end

                -- Cercle au sol
                if Config.Markers.showGroundCircle and distance < 100.0 then
                    DrawMarker(
                        1, -- Type: cercle
                        x, y, z - 0.5,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        Config.Markers.circleRadius, Config.Markers.circleRadius, 0.5,
                        color.r, color.g, color.b, color.a,
                        false, false, 2, false, nil, nil, false
                    )
                end
            end

            -- Afficher la distance
            local needsRender = false
            if Config.Markers.showDistance and obj.options.showDistance ~= false then
                needsRender = true
                local distText
                if distance >= 1000 then
                    distText = string.format("~y~%s: ~w~%.1f km", obj.options.label or "Objectif", distance / 1000)
                else
                    distText = string.format("~y~%s: ~w~%d m", obj.options.label or "Objectif", math.floor(distance))
                end
                DrawText2D(distText, 0.5, Config.Markers.distanceY)
            end

            if distance < 500.0 and (Config.Markers.showLightColumn or Config.Markers.showGroundCircle) then
                needsRender = true
            end

            if needsRender or distance < 50.0 then
                Citizen.Wait(0)
            elseif distance < 200.0 then
                Citizen.Wait(100)
            else
                Citizen.Wait(500)
            end
        end

        State.activeThreads[id] = nil
    end)
end

--- Thread pour marqueurs sur entité mobile
function GPSMission.StartEntityMarkerThread(id)
    if State.activeThreads[id] then return end
    State.activeThreads[id] = true

    Citizen.CreateThread(function()
        while State.activeThreads[id] and State.objectives[id] do
            local obj = State.objectives[id]
            if not obj or not obj.entity or not DoesEntityExist(obj.entity) then
                break
            end

            local entityCoords = GetEntityCoords(obj.entity)
            obj.coords = entityCoords -- Mettre à jour les coords

            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - entityCoords)

            if distance < 500.0 then
                local x, y, z = entityCoords.x, entityCoords.y, entityCoords.z
                local color = obj.markerColor

                -- Colonne au-dessus de l'entité (plus petite)
                if Config.Markers.showLightColumn then
                    DrawMarker(
                        27,
                        x, y, z + 1.5,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.5, 0.5, 30.0,
                        color.r, color.g, color.b, math.floor(color.a * 0.5),
                        false, false, 2, false, nil, nil, false
                    )
                end
            end

            -- Afficher la distance
            local needsRender = false
            if Config.Markers.showDistance and obj.options.showDistance ~= false then
                needsRender = true
                local distText
                if distance >= 1000 then
                    distText = string.format("~y~%s: ~w~%.1f km", obj.options.label or "Objectif", distance / 1000)
                else
                    distText = string.format("~y~%s: ~w~%d m", obj.options.label or "Objectif", math.floor(distance))
                end
                DrawText2D(distText, 0.5, Config.Markers.distanceY)
            end

            if distance < 500.0 and Config.Markers.showLightColumn then
                needsRender = true
            end

            if needsRender or distance < 50.0 then
                Citizen.Wait(0)
            elseif distance < 200.0 then
                Citizen.Wait(100)
            else
                Citizen.Wait(500)
            end
        end

        State.activeThreads[id] = nil
    end)
end

-- ============================================
-- FONCTIONS UTILITAIRES PUBLIQUES
-- ============================================

--- Vérifie si le joueur est proche d'un objectif
---@param id string ID de l'objectif
---@param radius number Rayon de détection
---@return boolean
function GPSMission.IsNearObjective(id, radius)
    radius = radius or 3.0
    return GetDistanceToObjective(id) <= radius
end

--- Obtient la distance vers un objectif
---@param id string ID de l'objectif
---@return number
function GPSMission.GetDistance(id)
    return GetDistanceToObjective(id)
end

--- Vérifie si un objectif existe
---@param id string ID de l'objectif
---@return boolean
function GPSMission.ObjectiveExists(id)
    return State.objectives[id] ~= nil
end

--- Change la couleur du tracé GPS
---@param id string ID de l'objectif
---@param color number Code couleur
function GPSMission.SetRouteColor(id, color)
    local obj = State.objectives[id]
    if obj and obj.blip and DoesBlipExist(obj.blip) then
        SetBlipRouteColour(obj.blip, color)
    end
end

--- Active/désactive les marqueurs visuels
---@param id string ID de l'objectif
---@param show boolean
function GPSMission.SetMarkersVisible(id, show)
    local obj = State.objectives[id]
    if not obj then return end

    obj.showMarkers = show

    if show and not State.activeThreads[id] then
        if obj.entity then
            GPSMission.StartEntityMarkerThread(id)
        else
            GPSMission.StartMarkerThread(id)
        end
    elseif not show and State.activeThreads[id] then
        State.activeThreads[id] = false
    end
end

--- Joue le son d'objectif atteint
function GPSMission.PlayReachSound()
    PlayGPSSound("onReach")
end

--- Obtient la configuration
function GPSMission.GetConfig()
    return Config
end

--- Met à jour la configuration des marqueurs
function GPSMission.UpdateMarkerConfig(key, value)
    if Config.Markers[key] ~= nil then
        Config.Markers[key] = value
    end
end

-- ============================================
-- EXPORTS
-- ============================================

exports("SetGPSObjective", GPSMission.SetObjective)
exports("SetGPSEntityObjective", GPSMission.SetEntityObjective)
exports("RemoveGPSObjective", GPSMission.RemoveObjective)
exports("ClearAllGPSObjectives", GPSMission.ClearAllObjectives)
exports("IsNearGPSObjective", GPSMission.IsNearObjective)
exports("GetGPSDistance", GPSMission.GetDistance)
exports("GPSObjectiveExists", GPSMission.ObjectiveExists)
exports("SetGPSRouteColor", GPSMission.SetRouteColor)
exports("SetGPSMarkersVisible", GPSMission.SetMarkersVisible)
exports("PlayGPSReachSound", GPSMission.PlayReachSound)

-- ============================================
-- NETTOYAGE
-- ============================================

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        GPSMission.ClearAllObjectives()
    end
end)

-- ============================================
-- COMMANDES DEBUG
-- ============================================

--[[ DEBUG COMMAND DISABLED
RegisterCommand("gpsdebug", function()
    local playerCoords = GetEntityCoords(PlayerPedId())

    -- Créer un objectif test à 100m devant
    local heading = GetEntityHeading(PlayerPedId())
    local rad = math.rad(heading)
    local testX = playerCoords.x + math.sin(rad) * 100
    local testY = playerCoords.y + math.cos(rad) * 100

    GPSMission.SetObjective("debug_test", testX, testY, playerCoords.z, {
        sprite = 38,
        label = "Test GPS",
        color = 5,
        routeColor = 5,
        showMarkers = true,
        showDistance = true
    })
end, false)
--]]

RegisterCommand("gpsclear", function()
    GPSMission.ClearAllObjectives()
end, false)

return GPSMission
