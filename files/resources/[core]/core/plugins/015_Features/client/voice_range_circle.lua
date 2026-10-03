---@meta _
---@diagnostic disable: duplicate-doc-field

-- Cercle de portée vocale.
--
-- pma-voice dessinait autrefois un marqueur à chaque changement de portée ; ses appels ont
-- été commentés (client/commands.lua) au profit d'un « cercle bleu personnalisé » qui n'a
-- jamais été livré. Résultat : changer de portée ne donnait plus aucun retour visuel.
--
-- Le cercle réapparaît ici, au sol, le temps de quelques secondes après chaque changement,
-- et son rayon s'anime de l'ancienne portée vers la nouvelle — on voit donc la zone
-- grandir quand on parle plus fort, et rétrécir quand on chuchote.

local DISPLAY_MS = 2600       -- durée d'affichage après un changement
local GROW_MS = 320           -- durée de l'animation du rayon
local FADE_MS = 500           -- fondu de sortie

local shownUntil = 0
local fromRadius = 0.0
local toRadius = 0.0
local changedAt = 0
local drawing = false

--- Portée en mètres du mode vocal courant, lue chez pma-voice.
---@return number
local function currentRange()
    local state = LocalPlayer and LocalPlayer.state
    local proximity = state and state.proximity

    if type(proximity) == "table" and tonumber(proximity.distance) then
        return tonumber(proximity.distance)
    end

    return 4.0
end

--- Couleur du cercle selon la portée : chuchotement plus discret, cri plus marqué.
---@param radius number
---@return number, number, number
local function colorFor(radius)
    if radius <= 2.0 then return 120, 170, 255 end
    if radius <= 5.0 then return 90, 150, 255 end
    return 255, 170, 80
end

local function startDraw()
    if drawing then return end
    drawing = true

    CreateThread(function()
        while GetGameTimer() < shownUntil do
            Wait(0)

            local now = GetGameTimer()
            local coords = GetEntityCoords(PlayerPedId())

            -- rayon animé de l'ancienne portée vers la nouvelle
            local progress = math.min(1.0, (now - changedAt) / GROW_MS)
            local eased = 1.0 - (1.0 - progress) * (1.0 - progress)
            local radius = fromRadius + (toRadius - fromRadius) * eased

            -- fondu sur la fin de l'affichage
            local remaining = shownUntil - now
            local alpha = 110
            if remaining < FADE_MS then
                alpha = math.floor(110 * (remaining / FADE_MS))
            end

            local r, g, b = colorFor(toRadius)

            DrawMarker(
                25,
                coords.x, coords.y, coords.z - 0.97,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                radius * 2.0, radius * 2.0, radius * 2.0,
                r, g, b, alpha,
                false, false, 2, false,
                nil, nil, false
            )
        end

        drawing = false
    end)
end

--- Affiche le cercle pour la portée courante.
local function show()
    local target = currentRange()

    fromRadius = (toRadius > 0.0) and toRadius or target
    toRadius = target
    changedAt = GetGameTimer()
    shownUntil = changedAt + DISPLAY_MS

    startDraw()
end

-- pma-voice émet cet événement à chaque changement de mode (touche de portée, commande,
-- ou forçage par un script).
AddEventHandler("pma-voice:setTalkingMode", function()
    -- l'état `proximity` est posé juste après l'événement : on laisse passer une frame
    CreateThread(function()
        Wait(0)
        show()
    end)
end)

-- Permet à un autre script (ou une commande) de rappeler le cercle à l'écran.
RegisterNetEvent("vfw:voice:showRange", show)

exports("ShowVoiceRange", show)
