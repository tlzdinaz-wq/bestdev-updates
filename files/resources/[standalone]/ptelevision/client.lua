-- ptelevision (client) : dessine la video d'un ecran sur le modele de television le plus proche.
--
-- Principe : un DUI (navigateur hors ecran, page html/player.html) lit la video ; sa texture est dessinee
-- chaque image dans le "render target" du modele de television (tvscreen...). Un render target est lie a
-- un MODELE, pas a un objet : toutes les televisions du meme modele montrent la meme image. On n'allume
-- donc qu'un ecran a la fois, le plus proche, a moins de CFG.VisualRange metres.

local CFG = PTVConfig

local PAGE = CFG.PlayerUrl or 'nui://ptelevision/html/player.html'
local TXD = 'ptv_txd_' .. GetGameTimer()
local TxdHandle = CreateRuntimeTxd(TXD)
local KNOWN_TARGETS = { 'tvscreen', 'script_rt_ex_tvscreen', 'cinscreen', 'Big_Disp', 'ECG' }
local DROP_MARGIN = 10.0         -- on n'eteint un ecran qu'un peu au-dela de la portee d'allumage
local SWITCH_MARGIN = 3.0        -- un autre ecran ne prend la place que s'il est nettement plus proche
local TEXTURE_SEQ = 0

local Models = {}                -- hash -> reglages (liste du builder)
local States = {}                -- key -> etat envoye par le serveur, avec `received` (GetGameTimer a la reception)
local UserVolume = {}            -- key -> volume choisi par ce joueur (0..1)
local Unsupported = {}           -- hash -> GetGameTimer() jusqu'auquel on ne reessaie pas (pas de render target)
local Active = nil               -- ecran actuellement affiche
local Controlled = nil           -- key de l'ecran ouvert dans le controleur video
local ErrorShown = {}

local function dbg(...)
    if CFG.Debug then print('[ptelevision]', ...) end
end

local function notify(message, kind)
    local ok = pcall(function() exports.core:PhoneClientNotify(message, kind or 'inform') end)
    if not ok then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

--- GetEntityModel renvoie un entier signe ; on compare toujours sur 32 bits signes.
local function normHash(hash)
    hash = (tonumber(hash) or 0) % 4294967296
    if hash >= 2147483648 then hash = hash - 4294967296 end
    return hash
end

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- ---------------------------------------------------------------------------
-- Modeles
-- ---------------------------------------------------------------------------

local function modelConfig(entry)
    local out = {}
    for k, v in pairs(CFG.DefaultModel) do out[k] = v end
    for k, v in pairs(entry) do
        if v ~= nil then out[k] = v end
    end
    return out
end

local function setModels(list)
    if type(list) ~= 'table' then return end

    local map = {}
    for i = 1, #list do
        local entry = list[i]
        if type(entry) == 'table' and type(entry.model) == 'string' then
            map[normHash(joaat(entry.model))] = modelConfig(entry)
        end
    end

    Models = map
end

RegisterNetEvent('ptelevision:setModels', setModels)

-- Le builder vient de modifier la liste : core l'envoie a tout le monde.
RegisterNetEvent('core:television:modelsUpdated', setModels)

-- ---------------------------------------------------------------------------
-- Etat des ecrans
-- ---------------------------------------------------------------------------

--- Position de lecture (secondes) d'un ecran, d'apres ce que le serveur a envoye.
local function positionOf(state)
    if state.paused then return state.pos end
    return state.pos + (GetGameTimer() - state.received) / 1000.0
end

RegisterNetEvent('ptelevision:sync', function(list)
    if type(list) ~= 'table' then return end

    local fresh = {}
    local t = GetGameTimer()
    for i = 1, #list do
        local entry = list[i]
        if type(entry) == 'table' and type(entry.key) == 'string' and entry.coords then
            entry.received = t
            fresh[entry.key] = entry
        end
    end

    States = fresh
end)

RegisterNetEvent('ptelevision:notify', function(message, kind)
    if type(message) == 'string' then notify(message, kind) end
end)

local function distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- La television du monde qui correspond a un ecran du serveur, ou 0.
local function findEntity(state)
    local c = state.coords
    return GetClosestObjectOfType(c.x, c.y, c.z, 1.5, state.model, false, false, false)
end

--- L'ecran allume le plus proche du joueur, a moins de `range` metres.
local function nearestScreen(range)
    local player = GetEntityCoords(PlayerPedId())
    local best, bestDistance, bestEntity

    for _, state in pairs(States) do
        local entity = findEntity(state)
        if entity ~= 0 then
            local d = distance(player, GetEntityCoords(entity))
            if d <= range and (not bestDistance or d < bestDistance) then
                best, bestDistance, bestEntity = state, d, entity
            end
        end
    end

    return best, bestEntity, bestDistance
end

local function stateAt(coords, radius)
    for _, state in pairs(States) do
        if distance(state.coords, coords) <= (radius or 0.25) then return state end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- DUI + render target
-- ---------------------------------------------------------------------------

local function sendPage(screen, payload)
    if screen and screen.dui then
        SendDuiMessage(screen.dui, json.encode(payload))
    end
end

--- Lie un render target au modele. Essaie celui du builder puis les noms connus : un reglage faux ne doit
--- pas laisser l'ecran noir si un autre nom convient.
local function openRenderTarget(hash, preferred)
    local names = {}
    if type(preferred) == 'string' and preferred ~= '' then names[1] = preferred end
    for i = 1, #KNOWN_TARGETS do
        if KNOWN_TARGETS[i] ~= preferred then names[#names + 1] = KNOWN_TARGETS[i] end
    end

    for i = 1, #names do
        local name = names[i]
        if not IsNamedRendertargetRegistered(name) then RegisterNamedRendertarget(name, false) end
        if not IsNamedRendertargetLinked(hash) then LinkNamedRendertarget(hash) end

        if IsNamedRendertargetLinked(hash) then
            local id = GetNamedRendertargetRenderId(name)
            if id and id ~= 0 and id ~= -1 then return name, id end
        end

        ReleaseNamedRendertarget(name)
    end

    return nil
end

local function volumeFor(screen)
    local cfg = screen.cfg
    local base = UserVolume[screen.key] or cfg.default_volume or 0.5
    local range = cfg.range or 20.0
    if range <= 0 then return 0.0 end

    local entity = screen.entity
    if not entity or not DoesEntityExist(entity) then return 0.0 end

    local d = distance(GetEntityCoords(PlayerPedId()), GetEntityCoords(entity))
    return clamp(base * (1.0 - d / range), 0.0, 1.0)
end

local function teardown(screen)
    if not screen then return end

    screen.stopped = true
    screen.ready = false
    if Active == screen then Active = nil end

    pcall(sendPage, screen, { action = 'stop' })
    if screen.dui then DestroyDui(screen.dui) end
    if screen.target then ReleaseNamedRendertarget(screen.target) end

    dbg('ecran eteint', screen.key)
end

--- On donne la video a la page : source, position, pause, volume. A chaque passage et non une seule fois :
--- la page peut ne pas etre prete au premier message, et pour la meme source elle ne fait que se resynchroniser.
local function sendLoad(screen)
    local state = States[screen.key]
    if not state then return end

    sendPage(screen, {
        action = 'load',
        kind = state.kind,
        id = state.id,
        url = state.url,
        pos = positionOf(state),
        paused = state.paused == true,
        volume = volumeFor(screen),
    })
end

local function setup(state, entity)
    local hash = state.model
    local cfg = Models[normHash(hash)] or modelConfig({})

    local target, renderId = openRenderTarget(hash, cfg.target)
    if not target then
        Unsupported[hash] = GetGameTimer() + 30000
        dbg('pas de render target pour ce modele', hash)
        return
    end

    local width = clamp(math.floor(tonumber(cfg.dui_width) or 1280), 64, 4096)
    local height = clamp(math.floor(tonumber(cfg.dui_height) or 720), 64, 4096)
    local dui = CreateDui(PAGE, width, height)

    TEXTURE_SEQ = TEXTURE_SEQ + 1
    local textureName = 'ptv_tex_' .. TEXTURE_SEQ
    CreateRuntimeTextureFromDuiHandle(TxdHandle, textureName, GetDuiHandle(dui))

    local screen = {
        key = state.key, hash = hash, entity = entity, cfg = cfg, dui = dui, target = target,
        renderId = renderId, texture = textureName, ready = false, rev = state.rev,
    }
    Active = screen
    dbg('ecran allume', state.key, target)

    CreateThread(function()
        local deadline = GetGameTimer() + 10000
        while not screen.stopped and not IsDuiAvailable(dui) and GetGameTimer() < deadline do
            Wait(50)
        end
        if screen.stopped then return end

        screen.ready = true
        sendLoad(screen)
    end)
end

--- L'image du DUI dans le render target du modele (une image).
local function drawScreen(screen)
    SetTextRenderId(screen.renderId)
    SetScriptGfxDrawOrder(4)
    SetScriptGfxDrawBehindPausemenu(true)
    DrawInteractiveSprite(TXD, screen.texture, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    SetTextRenderId(1)
end

CreateThread(function()
    while true do
        local screen = Active
        if screen and screen.ready and not screen.stopped then
            drawScreen(screen)
            Wait(0)
        else
            Wait(250)
        end
    end
end)

--- Met l'ecran affiche d'accord avec le serveur : ecran proche, nouvelle video, saut de lecture, volume.
local function reconcile()
    local best, bestEntity, bestDistance = nearestScreen(CFG.VisualRange)

    if Active then
        local state = States[Active.key]
        local keep = false

        if state and Active.entity and DoesEntityExist(Active.entity) then
            local d = distance(GetEntityCoords(PlayerPedId()), GetEntityCoords(Active.entity))
            -- Marge d'extinction et de changement d'ecran : sans elle, deux televisions a egale distance
            -- s'eteindraient et se rallumeraient tour a tour.
            keep = d <= CFG.VisualRange + DROP_MARGIN
            if keep and best and best.key ~= Active.key and (bestDistance + SWITCH_MARGIN) < d then keep = false end
        end

        if not keep then teardown(Active) end
    end

    if not Active and best and bestEntity then
        local retryAt = Unsupported[best.model]
        if not retryAt or GetGameTimer() > retryAt then setup(best, bestEntity) end
    end

    if Active and Active.ready then
        local state = States[Active.key]
        if not state then return end

        Active.entity = findEntity(state)
        if Active.entity == 0 then return end

        if state.rev ~= Active.rev then
            -- Nouvelle video, saut ou pause demandes au serveur : une erreur precedente ne vaut plus.
            Active.rev = state.rev
            ErrorShown[Active.key] = nil
        end
        sendLoad(Active)
    end
end

CreateThread(function()
    while true do
        local ok, err = pcall(reconcile)
        if not ok then dbg('reconcile', err) end
        Wait(Active and 400 or 1000)
    end
end)

-- La page rend compte de son etat (duree, erreur de lecture) par un callback NUI.
RegisterNUICallback('ptv:report', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' or not Active then return end

    if tonumber(data.duration) then Active.duration = tonumber(data.duration) end

    if data.error and not ErrorShown[Active.key] then
        ErrorShown[Active.key] = true
        notify(('La vidéo ne peut pas être lue (%s).'):format(tostring(data.error)), 'error')
    end
end)

-- ---------------------------------------------------------------------------
-- Interface avec core : volume, controleur video
-- ---------------------------------------------------------------------------

-- Menu contextuel de la television > Gerer le volume (valeur 0..1, propre a ce joueur).
AddEventHandler('ptelevision:clientSetVolume', function(coords, volume)
    local v = tonumber(volume)
    if not v or not coords then return end

    local state = stateAt(coords, 0.5)
    local key = state and state.key or ('local:%.1f:%.1f:%.1f'):format(coords.x, coords.y, coords.z)
    UserVolume[key] = clamp(v, 0.0, 1.0)
end)

exports('IsVideoPlayingAt', function(coords)
    if not coords then return false end
    return stateAt(coords, 1.5) ~= nil
end)

exports('OpenVideoController', function()
    local state = nearestScreen(CFG.ControlRange)
    if not state then
        notify("Aucune vidéo à contrôler à proximité.", 'error')
        return false
    end

    Controlled = state.key
    TriggerEvent('core:videoController:open')

    CreateThread(function()
        local key = state.key
        while Controlled == key do
            local current = States[key]
            if not current then
                TriggerEvent('core:videoController:close')
                Controlled = nil
                break
            end

            local duration = Active and Active.key == key and Active.duration or 0
            TriggerEvent('core:videoController:update', {
                currentTime = positionOf(current),
                duration = duration or 0,
                paused = current.paused == true,
            })
            Wait(500)
        end
    end)

    return true
end)

AddEventHandler('ptelevision:controllerSeek', function(time)
    if Controlled and tonumber(time) then
        TriggerServerEvent('ptelevision:control', Controlled, 'seek', tonumber(time))
    end
end)

AddEventHandler('ptelevision:controllerPlayPause', function(paused, currentTime)
    if Controlled then
        TriggerServerEvent('ptelevision:control', Controlled, 'pause', paused == true, tonumber(currentTime))
    end
end)

AddEventHandler('ptelevision:controllerClose', function()
    Controlled = nil
end)

-- ---------------------------------------------------------------------------
-- Demarrage
-- ---------------------------------------------------------------------------

CreateThread(function()
    -- Modeles par defaut tout de suite, puis la liste du builder.
    local seeded = {}
    for i = 1, #CFG.SeedModels do seeded[i] = { model = CFG.SeedModels[i] } end
    setModels(seeded)

    while true do
        TriggerServerEvent('ptelevision:requestModels')
        TriggerServerEvent('ptelevision:requestSync')
        Wait(CFG.SyncIntervalMs)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    teardown(Active)
end)

-- Utilise par les tests ; sans effet en jeu.
PTV = PTV or {}
PTV.client = {
    setModels = setModels, states = function() return States end, active = function() return Active end,
    reconcile = reconcile, positionOf = positionOf, volumeFor = volumeFor, drawScreen = drawScreen,
    txd = TXD,
}
