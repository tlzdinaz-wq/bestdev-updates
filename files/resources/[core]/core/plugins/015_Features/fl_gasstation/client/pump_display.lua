---@meta _
---@diagnostic disable: duplicate-doc-field

-- Écran de la pompe : compteurs Prix / Carburant à chiffres roulants.
-- Reprise du système de fscripts_fuel : une page NUI (interface/gasstation) rendue dans un DUI,
-- collée comme texture sur le scaleform `generic_texture_renderer` (stream/), lui-même dessiné
-- en 3D à côté de la pompe. L'orientation suit celle de la pompe et le panneau bascule de côté
-- selon que le joueur est devant ou derrière.
--
-- API inchangée pour le reste du plugin : ShowIdle / StartFueling / Update / Hide.

PumpDisplay = {}

local SCALEFORM = "generic_texture_renderer"
local DUI_WIDTH = 1900
local DUI_HEIGHT = 1000
-- Réglages du panneau, ajustables en jeu avec /pumpui (voir en bas du fichier).
local tuning = {
    scale = 0.05,   -- taille du panneau
    dz = 1.35,      -- hauteur au-dessus du pied de la pompe (hauteur de l'écran)
    dist = 0.5,     -- décalage vers le joueur : l'écran se plaque sur la face avant
    rot = 180.0,    -- orientation : la face du panneau regarde le joueur
}
local TXD_NAME = "gasstation_screen_txd"
local TEX_NAME = "gasstation_screen"

-- Modèles de pompes vanilla (mêmes hashs que fscripts_fuel).
local PUMP_MODELS = {
    [-2007231801] = true,
    [1339433404] = true,
    [1694452750] = true,
    [1933174915] = true,
    [-462817101] = true,
    [-469694731] = true,
    [-164877493] = true,
}

local state = {
    visible = false,
    dui = nil,
    sf = nil,
    txdSet = false,
    pos = nil,
    heading = 0.0,
    price = 0,
    liters = 0,
    preview = false,
}

local renderThread = false
-- Mode test (/pumpdebug, staff) : écran visible dès l'approche, plein non facturé, repère rouge.
local debugMode = false

local function toVector3(coords)
    if not coords or not coords.x or not coords.y or not coords.z then
        return nil
    end

    return vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
end

--- Pompe la plus proche de ces coordonnées. Deux passes : le pool d'objets (qui ne contient
--- pas toujours les props de la map), puis GetClosestObjectOfType modèle par modèle.
local function findPump(coords)
    local best, bestDist = nil, 6.0

    local handle, object = FindFirstObject()
    local success = true
    repeat
        if PUMP_MODELS[GetEntityModel(object)] then
            local dist = #(coords - GetEntityCoords(object))
            if dist < bestDist then
                best, bestDist = object, dist
            end
        end
        success, object = FindNextObject(handle, object)
    until not success
    EndFindObject(handle)

    if best then
        return best
    end

    for model in pairs(PUMP_MODELS) do
        local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 6.0, model, false, false, false)
        if object and object ~= 0 and DoesEntityExist(object) then
            local dist = #(coords - GetEntityCoords(object))
            if dist < bestDist then
                best, bestDist = object, dist
            end
        end
    end

    return best
end

--- Aide au diagnostic : liste les objets autour du point quand aucune pompe connue n'est trouvée.
local function reportUnknownPump(coords)
    local seen = {}
    local handle, object = FindFirstObject()
    local success = true
    repeat
        if DoesEntityExist(object) then
            local dist = #(coords - GetEntityCoords(object))
            if dist < 4.0 then
                local model = GetEntityModel(object)
                if not seen[model] then
                    seen[model] = true
                    print(("[GasStation] objet proche : modèle %d (distance %.1fm)"):format(model, dist))
                end
            end
        end
        success, object = FindNextObject(handle, object)
    until not success
    EndFindObject(handle)
end

--- Position et orientation du panneau : il flotte au-dessus de la pompe, légèrement décalé
--- vers le joueur, et lui fait face. (fscripts_fuel utilisait un décalage fixe de 2,7 m sur le
--- côté et 3,3 m de haut, calibré pour ses stations : chez nous il finissait dans l'auvent.)
local function panelPlacement()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local dx, dy = playerCoords.x - state.pos.x, playerCoords.y - state.pos.y
    local length = math.sqrt((dx * dx) + (dy * dy))

    if length < 0.1 then
        return state.pos.x, state.pos.y, state.pos.z + tuning.dz, tuning.rot - state.heading
    end

    local nx, ny = dx / length, dy / length
    local heading = GetHeadingFromVector_2d(nx, ny)

    return state.pos.x + (nx * tuning.dist), state.pos.y + (ny * tuning.dist), state.pos.z + tuning.dz, tuning.rot - heading
end

local function loadScaleform(name)
    local handle = RequestScaleformMovie(name)
    local deadline = GetGameTimer() + 5000

    while not HasScaleformMovieLoaded(handle) and GetGameTimer() < deadline do
        Wait(0)
    end

    if not HasScaleformMovieLoaded(handle) then
        return nil
    end

    return handle
end

local function cleanup()
    state.visible = false

    if state.dui then
        DestroyDui(state.dui)
        state.dui = nil
    end

    if state.sf then
        SetScaleformMovieAsNoLongerNeeded(state.sf)
        state.sf = nil
    end

    state.txdSet = false
    state.pos = nil
    state.price = 0
    state.liters = 0
    state.preview = false
end

local function sendToDui()
    if not state.dui then return end

    SendDuiMessage(state.dui, json.encode({
        type = "updateGasStation",
        price = state.price,
        fuel = state.liters,
    }))
end

local function ensureRenderThread()
    if renderThread then return end

    renderThread = true
    CreateThread(function()
        while state.visible do
            Wait(0)

            if state.sf and state.pos then
                if not state.txdSet then
                    PushScaleformMovieFunction(state.sf, "SET_TEXTURE")
                    PushScaleformMovieMethodParameterString(TXD_NAME)
                    PushScaleformMovieMethodParameterString(TEX_NAME)
                    PushScaleformMovieFunctionParameterInt(0)
                    PushScaleformMovieFunctionParameterInt(0)
                    PushScaleformMovieFunctionParameterInt(DUI_WIDTH)
                    PushScaleformMovieFunctionParameterInt(DUI_HEIGHT)
                    PopScaleformMovieFunctionVoid()
                    state.txdSet = true
                end

                local drawX, drawY, drawZ, rotation = panelPlacement()

                DrawScaleformMovie_3dNonAdditive(
                    state.sf,
                    drawX, drawY, drawZ,
                    0.0, 0.0, rotation,
                    0.0, 0.0, 0.0,
                    tuning.scale, tuning.scale * (9 / 16),
                    1, 2
                )

                if debugMode then
                    DrawMarker(28, drawX, drawY, drawZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        0.15, 0.15, 0.15, 255, 60, 60, 160, false, false, 2, false, nil, nil, false)
                end
            end
        end

        renderThread = false
    end)
end

--- Pompe libre : rien à afficher en temps normal, l'invite « Appuyez sur E » suffit.
function PumpDisplay.ShowIdle()
end

---@return boolean
function PumpDisplay.IsDebug()
    return debugMode
end

---@return boolean
function PumpDisplay.IsVisible()
    return state.visible
end

---@return boolean
function PumpDisplay.IsPreview()
    return state.preview
end

---@param pumpCoords vector3|table position de la pompe (le vrai objet est retrouvé par modèle)
---@param vehicleNetId number|nil
---@param data table|nil { currentLiters, pricePerLiter, ... }
function PumpDisplay.StartFueling(pumpCoords, vehicleNetId, data)
    local coords = toVector3(pumpCoords)
    if not coords then
        print("[GasStation] écran : pas de coordonnées de pompe, affichage ignoré.")
        return
    end

    cleanup()

    -- L'objet pompe donne une position et un cap exacts ; à défaut (pompe d'un MLO, modèle
    -- inconnu) on retombe sur les coordonnées envoyées par le serveur.
    local entity = findPump(coords)
    if not entity then
        print("[GasStation] écran : pompe non identifiée, position serveur utilisée.")
        reportUnknownPump(coords)
    end

    local sf = loadScaleform(SCALEFORM)
    if not sf then
        print(("[GasStation] écran : scaleform '%s' introuvable (le .gfx de core/stream n'est pas chargé ?)."):format(SCALEFORM))
        return
    end

    state.sf = sf
    state.price = 0
    state.liters = tonumber(data and data.currentLiters) or 0

    local txd = CreateRuntimeTxd(TXD_NAME)
    local url = ("nui://%s/interface/gasstation/index.html?price=%d&fuel=%d"):format(
        GetCurrentResourceName(), math.floor(state.price), math.floor(state.liters))

    state.dui = CreateDui(url, DUI_WIDTH, DUI_HEIGHT)
    CreateRuntimeTextureFromDuiHandle(txd, TEX_NAME, GetDuiHandle(state.dui))

    -- Base = le pied de la pompe : la hauteur de l'écran est pilotée uniquement par tuning.dz.
    local base = entity and GetEntityCoords(entity) or coords
    state.pos = vector3(base.x, base.y, base.z)
    state.heading = entity and GetEntityHeading(entity) or 0.0
    state.visible = true

    print(("[GasStation] écran affiché (pompe %s)."):format(entity and GetEntityModel(entity) or "inconnue"))
    ensureRenderThread()

    -- La page met un instant à s'initialiser : premier envoi différé, sinon il est perdu.
    CreateThread(function()
        Wait(250)
        sendToDui()
    end)
end

--- Mode test : montre l'écran à l'approche d'une pompe, sans remplissage en cours.
---@param pumpCoords vector3|table
function PumpDisplay.Preview(pumpCoords)
    if state.visible then return end

    PumpDisplay.StartFueling(pumpCoords, nil, { currentLiters = 0 })
    state.preview = true
end

---@param data table { currentLiters, currentPrice, pricePerLiter }
function PumpDisplay.Update(data)
    if not state.visible or not data then return end

    local liters = tonumber(data.currentLiters)
    if liters then
        state.liters = liters
    end

    local price = tonumber(data.currentPrice)
    if not price then
        local perLiter = tonumber(data.pricePerLiter) or 0
        price = state.liters * perLiter
    end
    state.price = price

    sendToDui()
end

function PumpDisplay.Hide()
    if state.dui then
        SendDuiMessage(state.dui, json.encode({ type = "hideGasStation" }))
    end

    cleanup()
end

--- Réglage en jeu : /pumpui [taille] [hauteur] [distance] [rotation]
--- Sans argument, affiche les valeurs courantes. Les changements sont immédiats.
RegisterCommand("pumpui", function(_, args)
    local names = { "scale", "dz", "dist", "rot" }
    for i = 1, #names do
        local value = tonumber(args[i])
        if value then
            tuning[names[i]] = value
        end
    end

    print(("[GasStation] panneau : taille %.3f, hauteur %.2f, distance %.2f, rotation %.0f")
        :format(tuning.scale, tuning.dz, tuning.dist, tuning.rot))
end, false)

--- Mode test des pompes : écran visible dès l'approche, plein non facturé, repère rouge sur
--- la position du panneau. Réservé au staff (vérifié côté serveur).
RegisterCommand("pumpdebug", function()
    if debugMode then
        debugMode = false
        if state.preview then PumpDisplay.Hide() end
        print("[GasStation] mode test : désactivé")
        return
    end

    if not TriggerServerCallback("fl_gasstation:canDebug") then
        VFW.ShowNotification({
            type = 'ROUGE',
            subtitle = 'Station Essence',
            message = "Mode test réservé au staff."
        })
        return
    end

    debugMode = true
    print("[GasStation] mode test : activé (écran en approche, plein gratuit)")
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        cleanup()
    end
end)
