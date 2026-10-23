-- ptelevision (serveur) : l'etat des ecrans allumes.
--
-- Un ecran = une television du monde, reperee par ses coordonnees et l'instance (routing bucket) dans
-- laquelle elle se trouve : deux appartements identiques dans deux instances ont les memes coordonnees
-- sans partager leur video. Le serveur garde ce qui joue et a quelle position ; chaque client dessine
-- lui-meme l'image (voir client.lua).

local CFG = PTVConfig

local States = {}       -- key -> etat d'un ecran
local LastAction = {}   -- source -> GetGameTimer() du dernier lancement / controle
local Models = {}       -- hash -> true, modeles de television connus (builder)

local function dbg(...)
    if CFG.Debug then print('[ptelevision]', ...) end
end

local function now()
    return GetGameTimer()
end

-- ---------------------------------------------------------------------------
-- Lecture des entrees
-- ---------------------------------------------------------------------------

local function trim(value)
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Un client qui envoie GetEntityCoords() fait arriver un vector3, pas une table.
local function readVec3(value)
    local kind = type(value)
    if kind ~= 'table' and kind ~= 'vector3' and kind ~= 'vector4' then return nil end

    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z or x ~= x or y ~= y or z ~= z then return nil end

    return { x = x, y = y, z = z }
end

--- GetEntityModel (client) renvoie un entier signe ; on compare toujours sur 32 bits signes.
local function normHash(hash)
    hash = (tonumber(hash) or 0) % 4294967296
    if hash >= 2147483648 then hash = hash - 4294967296 end
    return hash
end

local function keyOf(coords, bucket)
    return ('%d:%.1f:%.1f:%.1f'):format(bucket or 0, coords.x, coords.y, coords.z)
end

local YOUTUBE_HOSTS = {
    ['youtube.com'] = true, ['www.youtube.com'] = true, ['m.youtube.com'] = true,
    ['music.youtube.com'] = true, ['youtube-nocookie.com'] = true, ['www.youtube-nocookie.com'] = true,
    ['youtu.be'] = true,
}

local VIDEO_EXTENSIONS = { mp4 = true, webm = true, ogv = true, m4v = true, mov = true }

--- "90", "90s", "1m30s", "1h2m3s" -> secondes.
local function parseOffset(text)
    if not text or text == '' then return 0 end

    local plain = text:match('^(%d+)s?$')
    if plain then return math.min(tonumber(plain), 86400) end

    local hours = tonumber(text:match('(%d+)h')) or 0
    local minutes = tonumber(text:match('(%d+)m')) or 0
    local seconds = tonumber(text:match('(%d+)s')) or 0
    return math.min(hours * 3600 + minutes * 60 + seconds, 86400)
end

local function youtubeId(host, path, query)
    local id
    if host == 'youtu.be' then
        id = path:match('^/([%w_%-]+)')
    else
        id = (query or ''):match('[%?&]v=([%w_%-]+)')
            or path:match('^/embed/([%w_%-]+)')
            or path:match('^/shorts/([%w_%-]+)')
            or path:match('^/live/([%w_%-]+)')
            or path:match('^/v/([%w_%-]+)')
    end
    if id and #id == 11 then return id end
    return nil
end

--- Ce que le joueur a saisi -> { kind = 'youtube', id, start } | { kind = 'video', url } | nil, raison
local function parseSource(raw)
    if type(raw) ~= 'string' then return nil, 'Lien invalide.' end

    local url = trim(raw)
    if url == '' or #url > 400 then return nil, 'Lien invalide.' end
    if url:find('[%c%s]') then return nil, 'Lien invalide.' end

    -- Un identifiant YouTube seul.
    if #url == 11 and url:match('^[%w_%-]+$') then
        return { kind = 'youtube', id = url, start = 0 }
    end

    if not url:find('^%a[%w+.%-]*://') then url = 'https://' .. url end
    if not url:find('^https?://') then return nil, 'Seuls les liens http(s) sont acceptes.' end

    local authority, rest = url:match('^https?://([^/%?#]+)(.*)$')
    if not authority or authority:find('@', 1, true) then return nil, 'Lien invalide.' end

    local host = authority:lower():gsub(':%d+$', '')
    local path, query = rest:match('^([^%?#]*)(.*)$')
    path = path ~= '' and path or '/'

    if YOUTUBE_HOSTS[host] then
        local id = youtubeId(host, path, query)
        if not id then return nil, 'Lien YouTube non reconnu.' end

        local start = parseOffset((query or ''):match('[%?&#]t=([%w]+)') or (query or ''):match('[%?&]start=(%d+)'))
        return { kind = 'youtube', id = id, start = start }
    end

    if not CFG.AllowDirectLinks then
        return nil, 'Seuls les liens YouTube sont acceptes.'
    end

    local extension = path:lower():match('%.(%w+)$')
    if extension and VIDEO_EXTENSIONS[extension] then
        return { kind = 'video', url = url, start = 0 }
    end

    return nil, 'Lien non reconnu : YouTube ou fichier .mp4 / .webm.'
end

-- ---------------------------------------------------------------------------
-- Joueurs, instances
-- ---------------------------------------------------------------------------

local function bucketOf(source)
    return GetPlayerRoutingBucket(source) or 0
end

local function playerNear(source, coords, range)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local p = GetEntityCoords(ped)
    local dx, dy, dz = p.x - coords.x, p.y - coords.y, p.z - coords.z
    return (dx * dx + dy * dy + dz * dz) <= range * range
end

local function notify(source, message, kind)
    TriggerClientEvent('ptelevision:notify', source, message, kind or 'inform')
end

--- true si la source n'a pas agi depuis moins de `delay` ms (et note l'action).
local function throttled(source, delay)
    local t = now()
    local last = LastAction[source]
    if last and (t - last) < delay then return true end
    LastAction[source] = t
    return false
end

-- ---------------------------------------------------------------------------
-- Etat des ecrans
-- ---------------------------------------------------------------------------

local function position(state)
    if state.paused then return state.pos end
    return state.pos + (now() - state.at) / 1000.0
end

local function view(state)
    return {
        key = state.key,
        coords = state.coords,
        model = state.model,
        kind = state.kind,
        id = state.id,
        url = state.url,
        pos = position(state),
        paused = state.paused,
        rev = state.rev,
    }
end

local function listFor(bucket)
    local list = {}
    for _, state in pairs(States) do
        if state.bucket == bucket then list[#list + 1] = view(state) end
    end
    return list
end

local function countStates()
    local n = 0
    for _ in pairs(States) do n = n + 1 end
    return n
end

--- Renvoie l'etat complet de l'instance a ses joueurs : c'est la verite, un ecran absent est eteint.
local function broadcast(bucket)
    local list = listFor(bucket)
    for _, id in ipairs(GetPlayers()) do
        local source = tonumber(id)
        if source and bucketOf(source) == bucket then
            TriggerClientEvent('ptelevision:sync', source, list)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Modeles de television (liste du builder, fournie par core)
-- ---------------------------------------------------------------------------

local function modelConfig(entry)
    local out = {}
    for k, v in pairs(CFG.DefaultModel) do out[k] = v end
    for k, v in pairs(entry) do
        if v ~= nil then out[k] = v end
    end
    return out
end

local function loadModels()
    local list
    local ok, result = pcall(function() return exports.core:TelevisionModels() end)
    if ok and type(result) == 'table' and #result > 0 then list = result end

    if not list then
        list = {}
        for i = 1, #CFG.SeedModels do list[i] = { model = CFG.SeedModels[i] } end
    end

    local out, map = {}, {}
    for i = 1, #list do
        local entry = list[i]
        if type(entry) == 'table' and type(entry.model) == 'string' and entry.model ~= '' then
            out[#out + 1] = modelConfig(entry)
            map[normHash(joaat(entry.model))] = true
        end
    end

    Models = map
    return out
end

RegisterNetEvent('ptelevision:requestModels', function()
    TriggerClientEvent('ptelevision:setModels', source, loadModels())
end)

RegisterNetEvent('ptelevision:requestSync', function()
    local source = source
    TriggerClientEvent('ptelevision:sync', source, listFor(bucketOf(source)))
end)

-- ---------------------------------------------------------------------------
-- Lancer / arreter
-- ---------------------------------------------------------------------------

local function play(source, coords, model, raw)
    local parsed, reason = parseSource(raw)
    if not parsed then
        notify(source, reason or 'Lien invalide.', 'error')
        return
    end

    local bucket = bucketOf(source)
    local key = keyOf(coords, bucket)
    local previous = States[key]

    if not previous and countStates() >= CFG.MaxScreens then
        notify(source, "Trop de télévisions allumées sur le serveur.", 'error')
        return
    end

    local t = now()
    States[key] = {
        key = key,
        coords = coords,
        model = model,
        bucket = bucket,
        kind = parsed.kind,
        id = parsed.id,
        url = parsed.url,
        pos = parsed.start or 0,
        at = t,
        since = t,
        paused = false,
        rev = (previous and previous.rev or 0) + 1,
    }

    dbg(('play %s %s %s par %d'):format(key, parsed.kind, parsed.id or parsed.url, source))
    broadcast(bucket)
end

local function stop(source, coords)
    local bucket = bucketOf(source)
    local key = keyOf(coords, bucket)
    if not States[key] then return end

    States[key] = nil
    dbg(('stop %s par %d'):format(key, source))
    broadcast(bucket)
end

-- Evenement historique de la ressource : ("ptelevision:event", { coords, model, entity }, "ptv_status", { type, url })
RegisterNetEvent('ptelevision:event', function(info, kind, data)
    local source = source
    if kind ~= 'ptv_status' or type(info) ~= 'table' or type(data) ~= 'table' then return end

    local coords = readVec3(info.coords)
    local model = tonumber(info.model)
    if not coords or not model then return end

    -- Une television que le builder ne connait pas n'a pas de reglage d'ecran : rien a allumer.
    loadModels()
    if next(Models) ~= nil and not Models[normHash(model)] then return end

    if not playerNear(source, coords, CFG.PlayRange) then return end

    if data.type == 'play' then
        if throttled(source, CFG.PlayCooldownMs) then return end
        play(source, coords, model, data.url)
    elseif data.type == 'stop' then
        stop(source, coords)
    end
end)

-- Controleur video : { seek, temps } et { pause, etat, temps }
RegisterNetEvent('ptelevision:control', function(key, action, a, b)
    local source = source
    if type(key) ~= 'string' then return end

    local state = States[key]
    if not state or state.bucket ~= bucketOf(source) then return end
    if not playerNear(source, state.coords, CFG.ControlRange + 10.0) then return end
    if throttled(source, 150) then return end

    local function clamp(value)
        return math.max(0.0, math.min(value, 86400.0))
    end

    if action == 'seek' then
        local t = tonumber(a)
        if not t or t ~= t then return end
        state.pos = clamp(t)
        state.at = now()
    elseif action == 'pause' then
        local t = tonumber(b)
        if t ~= t then t = nil end

        if a == true then
            state.pos = t and clamp(t) or position(state)
            state.paused = true
        else
            if t then state.pos = clamp(t) end
            state.at = now()
            state.paused = false
        end
    else
        return
    end

    state.rev = state.rev + 1
    broadcast(state.bucket)
end)

-- ---------------------------------------------------------------------------
-- Entretien
-- ---------------------------------------------------------------------------

CreateThread(function()
    while true do
        Wait(30000)

        local expired = {}
        local limit = CFG.MaxPlaySeconds * 1000
        for key, state in pairs(States) do
            if (now() - state.since) > limit then expired[#expired + 1] = state end
        end

        local touched = {}
        for i = 1, #expired do
            States[expired[i].key] = nil
            touched[expired[i].bucket] = true
        end
        for bucket in pairs(touched) do broadcast(bucket) end
    end
end)

AddEventHandler('playerDropped', function()
    LastAction[source] = nil
end)

-- Utilise par les tests ; sans effet en jeu.
PTV = PTV or {}
PTV.server = { parseSource = parseSource, keyOf = keyOf, states = States, loadModels = loadModels }
