--[[
    FloatingUI - Bibliothèque pour afficher des interactions flottantes en 3D

    Usage:
    FloatingUI.Create("zone_id", coords, radius, {
        title = "Titre",
        subtitle = "Sous-titre optionnel",
        buttons = {
            { label = "Action", key = "E", icon = "home", action = function() end }
            -- condition = function() return bool end  →  bouton affiché seulement si true
        }
    })

    FloatingUI.Remove("zone_id")
    FloatingUI.Update("zone_id", { title = "Nouveau titre", subtitle = "État", buttons = {...} })

    Icons disponibles: discord, globe, message, users, map, info, star, heart, zap, gift,
                       coffee, music, camera, phone, mail, settings, home, shop, truck, car, plane
]]

FloatingUI = {}

local activeZones = {}
local currentZone = nil

--- Convertir les coordonnées 3D en position écran 2D
---@param coords vector3
---@return number|nil x Position X (0-1)
---@return number|nil y Position Y (0-1)
---@return boolean onScreen Si visible à l'écran
local function WorldToScreen(coords)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 0.3)
    if onScreen then
        return screenX, screenY, true
    end
    return nil, nil, false
end

--- Construire la liste de boutons NUI en appliquant les conditions
---@param rawButtons table
---@return table
local function BuildNuiButtons(rawButtons)
    local nuiButtons = {}
    for _, button in ipairs(rawButtons) do
        if not button.condition or button.condition() then
            table.insert(nuiButtons, {
                label = button.label,
                key   = button.key or "E",
                icon  = button.icon
            })
        end
    end
    return nuiButtons
end

--- Créer une zone d'interaction flottante
---@param id string Identifiant unique de la zone
---@param coords vector3 Position de la zone
---@param radius number Rayon de détection
---@param options table Options de la zone
function FloatingUI.Create(id, coords, radius, options)
    if activeZones[id] then
        FloatingUI.Remove(id)
    end

    local rawButtons = options.buttons or {}

    local zoneData = {
        id         = id,
        coords     = coords,
        radius     = radius,
        title      = options.title or "",
        subtitle   = options.subtitle,
        size       = options.size,
        rawButtons = rawButtons,
        isInside   = false
    }

    activeZones[id] = zoneData

    -- Thread de détection de proximité + mise à jour position chaque frame
    CreateThread(function()
        local isShowing = false

        while activeZones[id] == zoneData do
            local wait = 500
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - coords)

            if distance <= radius then
                wait = 0
                currentZone = id
                zoneData.isInside = true

                local screenX, screenY, onScreen = WorldToScreen(coords)

                if onScreen then
                    local nuiButtons = BuildNuiButtons(rawButtons)

                    if not isShowing then
                        -- Enregistrer les interactions clavier
                        FloatingUI._RegisterInteractions(id)
                        SendNUIMessage({
                            action = "floatingInteraction:show",
                            data = {
                                id       = id,
                                title    = zoneData.title,
                                subtitle = zoneData.subtitle,
                                buttons  = nuiButtons,
                                screenX  = screenX,
                                screenY  = screenY,
                                size     = zoneData.size
                            }
                        })
                        isShowing = true
                    else
                        SendNUIMessage({
                            action = "floatingInteraction:update",
                            data = {
                                id       = id,
                                title    = zoneData.title,
                                subtitle = zoneData.subtitle,
                                buttons  = nuiButtons,
                                screenX  = screenX,
                                screenY  = screenY,
                                size     = zoneData.size
                            }
                        })
                    end
                else
                    if isShowing then
                        FloatingUI._UnregisterInteractions(id)
                        SendNUIMessage({ action = "floatingInteraction:hide" })
                        isShowing = false
                    end
                end
            else
                zoneData.isInside = false
                if currentZone == id then
                    currentZone = nil
                end
                FloatingUI._UnregisterInteractions(id)
                if isShowing then
                    SendNUIMessage({ action = "floatingInteraction:hide" })
                    isShowing = false
                end
            end

            Wait(wait)
        end

        -- Nettoyage si la zone a été supprimée pendant le thread
        if isShowing then
            SendNUIMessage({ action = "floatingInteraction:hide" })
        end
    end)
end

--- Enregistrer les interactions clavier d'une zone
function FloatingUI._RegisterInteractions(id)
    local zone = activeZones[id]
    if not zone or not zone.rawButtons then return end

    for i, button in ipairs(zone.rawButtons) do
        if button.action then
            local interactionId = "floatingui_" .. id .. "_" .. i
            VFW.RegisterInteraction(interactionId, button.action, function() return true end)
        end
    end
end

--- Supprimer les interactions clavier d'une zone
function FloatingUI._UnregisterInteractions(id)
    local zone = activeZones[id]
    if not zone or not zone.rawButtons then return end

    for i, button in ipairs(zone.rawButtons) do
        if button.action then
            local interactionId = "floatingui_" .. id .. "_" .. i
            VFW.RemoveInteraction(interactionId)
        end
    end
end

--- Supprimer une zone d'interaction
---@param id string Identifiant de la zone
function FloatingUI.Remove(id)
    local zone = activeZones[id]
    if not zone then return end

    if zone.isInside then
        FloatingUI._UnregisterInteractions(id)
        if currentZone == id then
            currentZone = nil
        end
        SendNUIMessage({ action = "floatingInteraction:hide" })
    end

    activeZones[id] = nil
end

--- Mettre à jour le titre, subtitle ou boutons d'une zone existante
---@param id string Identifiant de la zone
---@param options table Nouvelles options (partielles)
function FloatingUI.Update(id, options)
    local zone = activeZones[id]
    if not zone then return end

    if options.title    ~= nil then zone.title    = options.title    end
    if options.subtitle ~= nil then zone.subtitle = options.subtitle end

    if options.buttons ~= nil then
        -- Re-enregistrer les interactions si le joueur est dedans
        if zone.isInside then
            FloatingUI._UnregisterInteractions(id)
        end
        zone.rawButtons = options.buttons
        if zone.isInside then
            FloatingUI._RegisterInteractions(id)
        end
    end
    -- Le thread de position appliquera les changements à la prochaine frame
end

--- Vérifier si une zone existe
---@param id string Identifiant de la zone
---@return boolean
function FloatingUI.Exists(id)
    return activeZones[id] ~= nil
end

--- Obtenir la zone actuellement affichée
---@return string|nil
function FloatingUI.GetCurrentZone()
    return currentZone
end

-- =============================================
-- Preview de hauteur floating (texte 3D natif)
-- =============================================
local _previewActive = false
local _previewPos = nil
local _previewOffset = 0.5

local function Draw3dTextSimple(coords, text)
    local camCoords = GetGameplayCamCoord()
    local dist = #(coords - camCoords)
    local scale = 200 / (GetGameplayCamFov() * dist)
    SetTextScale(0.0, 0.4 * scale)
    SetTextFont(4)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 255)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function FloatingUI.StartHeightPreview(pos, offset)
    _previewActive = false
    Wait(0)
    _previewPos = pos
    _previewOffset = offset or 0.5
    _previewActive = true

    SendNUIMessage({ action = "floatingInteraction:hide" })

    CreateThread(function()
        while _previewActive do
            Draw3dTextSimple(
                vector3(_previewPos.x, _previewPos.y, _previewPos.z + _previewOffset),
                ("~w~Hauteur: ~o~%.2f"):format(_previewOffset)
            )
            if IsControlPressed(0, 172) or IsDisabledControlPressed(0, 172) then
                _previewOffset = _previewOffset + 0.01
            end
            if IsControlPressed(0, 173) or IsDisabledControlPressed(0, 173) then
                _previewOffset = _previewOffset - 0.01
            end
            Wait(0)
        end
    end)
end

function FloatingUI.StopHeightPreview()
    _previewActive = false
    return _previewOffset
end

function FloatingUI.IsPreviewActive()
    return _previewActive
end

-- Export global
exports("FloatingUI", function()
    return FloatingUI
end)
