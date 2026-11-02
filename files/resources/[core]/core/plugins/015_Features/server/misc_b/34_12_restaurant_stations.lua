-- Builders > « Positions stations restaurants » (grill, friteuse, four, table de préparation… de chaque restaurant).
--
-- Le menu du staff appelait `restaurant_stations:update / create / getCreatable / addSlot / removeSlot / reset /
-- delete`, mais seul `getAll` existait côté serveur : déplacer, ajouter ou supprimer une station répondait toujours
-- « Échec ». Ce fichier fournit tout le builder.
--
-- Table `restaurant_stations` : une ligne par station modifiée (resto_key, loc_key, station_key), `data` = définition
-- complète de la station (RestaurantStations.FullSnapshot) ou `{ deleted = true }` pour une station d'origine retirée.
-- La config des restaurants n'est jamais modifiée côté serveur : elle reste la référence « d'origine ».
-- Les joueurs reçoivent l'état effectif de chaque emplacement modifié (cl_restaurant_stations_sync.lua vide les stations
-- de l'emplacement puis les reconstruit).

local Util = RestaurantStations
local overrides = nil -- overrides[resto][loc][station] = définition | { deleted = true }
local loading = false
local MAX_COORD <const> = 20000.0

local function isStaff(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.hasPermission("restaurant_builder") or xPlayer.hasPermission("staff") or xPlayer.hasPermission("admin")
end

local function validKey(v)
    return type(v) == "string" and #v > 0 and #v <= 60 and v:match("^[%w_]+$") ~= nil
end

local function num(v)
    local n = tonumber(v)
    if not n or n ~= n or math.abs(n) > MAX_COORD then return nil end
    return n + 0.0
end

local function point(v)
    if type(v) ~= "table" and type(v) ~= "vector3" then return nil end
    local x, y, z = num(v.x), num(v.y), num(v.z)
    if not (x and y and z) then return nil end
    return { x = x, y = y, z = z }
end

local function load()
    if overrides then return overrides end
    if loading then
        local waited = 0
        while loading and waited < 5000 do Wait(10) waited = waited + 10 end
        return overrides or {}
    end
    loading = true
    local rows = MiscB.Query("SELECT resto_key, loc_key, station_key, data FROM restaurant_stations", {}) or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[row.resto_key] = out[row.resto_key] or {}
        out[row.resto_key][row.loc_key] = out[row.resto_key][row.loc_key] or {}
        out[row.resto_key][row.loc_key][row.station_key] = VFW.DB.Decode(row.data, {})
    end
    overrides = out
    loading = false
    return overrides
end

local function defaultLoc(key, locKey)
    local cfg = Util.GetConfig(key)
    local loc = cfg and type(cfg.Locations) == "table" and cfg.Locations[locKey] or nil
    return type(loc) == "table" and loc or nil
end

--- Stations effectives d'un emplacement (config d'origine + modifications du staff), en définitions sérialisables
local function effectiveLoc(key, locKey)
    local loc = defaultLoc(key, locKey)
    if not loc then return nil end
    local out = {}
    for stKey, st in pairs(loc) do
        if Util.IsStation(st) then out[stKey] = Util.FullSnapshot(st) end
    end
    local changed = (load()[key] or {})[locKey] or {}
    for stKey, def in pairs(changed) do
        if type(def) == "table" and def.deleted then
            out[stKey] = nil
        elseif Util.IsStation(def) then
            out[stKey] = json.decode(json.encode(def)) -- copie : le cache ne bouge qu'une fois l'écriture faite
        end
    end
    return out
end

local function payload()
    local out = {}
    for key, locs in pairs(load()) do
        for locKey in pairs(locs) do
            local eff = effectiveLoc(key, locKey)
            if eff then
                out[key] = out[key] or {}
                out[key][locKey] = eff
            end
        end
    end
    return out
end

local function broadcast(key, locKey)
    TriggerClientEvent("restaurant_stations:sync", -1, { [key] = { [locKey] = effectiveLoc(key, locKey) or {} } })
end

local function writeRow(key, locKey, stKey, def)
    local ok, err = pcall(MySQL.update.await, [[
        INSERT INTO restaurant_stations (resto_key, loc_key, station_key, data) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE data = VALUES(data)
    ]], { key, locKey, stKey, json.encode(def) })
    if not ok then
        console.error("[restaurant_stations] SQL : " .. tostring(err))
        return false
    end
    local all = load()
    all[key] = all[key] or {}
    all[key][locKey] = all[key][locKey] or {}
    all[key][locKey][stKey] = def
    return true
end

local function deleteRow(key, locKey, stKey)
    local ok, err = pcall(MySQL.update.await,
        "DELETE FROM restaurant_stations WHERE resto_key = ? AND loc_key = ? AND station_key = ?", { key, locKey, stKey })
    if not ok then
        console.error("[restaurant_stations] SQL : " .. tostring(err))
        return false
    end
    local all = load()
    if all[key] and all[key][locKey] then
        all[key][locKey][stKey] = nil
        if next(all[key][locKey]) == nil then all[key][locKey] = nil end
        if next(all[key]) == nil then all[key] = nil end
    end
    return true
end

--- Contrôles communs : staff, restaurant + emplacement connus, station existante (si demandée)
local function context(source, key, locKey, stKey)
    if not isStaff(source) or not validKey(key) or not validKey(locKey) then return nil end
    local eff = effectiveLoc(key, locKey)
    if not eff then return nil end
    if stKey ~= nil then
        if not validKey(stKey) or not eff[stKey] then return nil end
    end
    return eff
end

--- Point de référence d'une station (centre, zone, sinon moyenne des slots)
local function refPoint(def)
    if def.center then return def.center end
    if def.coords then return def.coords end
    if type(def.slots) == "table" then
        local sx, sy, sz, n = 0, 0, 0, 0
        for _, s in pairs(def.slots) do sx, sy, sz, n = sx + s.x, sy + s.y, sz + s.z, n + 1 end
        if n > 0 then return { x = sx / n, y = sy / n, z = sz / n } end
    end
    return nil
end

MiscB.Cb("restaurant_stations:getAll", function(source)
    return payload()
end)

-- Déplacement d'une station ou d'un point : seuls les points déjà présents sont repris (jamais d'ajout ici)
MiscB.Cb("restaurant_stations:update", function(source, key, locKey, stKey, snap)
    local eff = context(source, key, locKey, stKey)
    if not eff or type(snap) ~= "table" then return false end
    local def = eff[stKey]
    if def.center and snap.center then def.center = point(snap.center) or def.center end
    if def.coords and snap.coords then def.coords = point(snap.coords) or def.coords end
    if def.heading ~= nil and num(snap.heading) then def.heading = num(snap.heading) end
    if type(def.slots) == "table" and type(snap.slots) == "table" then
        for name, s in pairs(def.slots) do
            local moved = type(snap.slots[name]) == "table" and point(snap.slots[name]) or nil
            if moved then
                moved.heading = num(snap.slots[name].heading) or s.heading or 0.0
                def.slots[name] = moved
            end
        end
    end
    if not writeRow(key, locKey, stKey, def) then return false end
    broadcast(key, locKey)
    return true
end)

-- Types de station de ce restaurant absents de l'emplacement (pris dans la config de tous ses emplacements)
MiscB.Cb("restaurant_stations:getCreatable", function(source, key, locKey)
    local eff = context(source, key, locKey)
    if not eff then return {} end
    local types, seen = {}, {}
    Util.ForEachStation(Util.GetConfig(key), function(_, stKey)
        if not eff[stKey] and not seen[stKey] then
            seen[stKey] = true
            types[#types + 1] = stKey
        end
    end)
    table.sort(types)
    return types
end)

-- Nouvelle station : copie d'une station du même type (celle d'origine de l'emplacement si elle existe), recentrée
-- sur la position du staff en gardant sa disposition
MiscB.Cb("restaurant_stations:create", function(source, key, locKey, stKey, x, y, z, h)
    local eff = context(source, key, locKey)
    local pos = point({ x = x, y = y, z = z })
    if not eff or not validKey(stKey) or eff[stKey] or not pos then return false end

    local template = nil
    local own = defaultLoc(key, locKey)
    if own and Util.IsStation(own[stKey]) then template = own[stKey] end
    if not template then
        Util.ForEachStation(Util.GetConfig(key), function(_, k, st)
            if not template and k == stKey then template = st end
        end)
    end
    if not template then return false end

    local def = Util.FullSnapshot(template)
    local ref = refPoint(def)
    if not ref then return false end
    local dx, dy, dz = pos.x - ref.x, pos.y - ref.y, pos.z - ref.z
    if def.center then def.center = { x = def.center.x + dx, y = def.center.y + dy, z = def.center.z + dz } end
    if def.coords then def.coords = { x = def.coords.x + dx, y = def.coords.y + dy, z = def.coords.z + dz } end
    if def.heading ~= nil then def.heading = num(h) or def.heading end
    if type(def.slots) == "table" then
        for name, s in pairs(def.slots) do
            def.slots[name] = { x = s.x + dx, y = s.y + dy, z = s.z + dz, heading = s.heading }
        end
    end
    if not writeRow(key, locKey, stKey, def) then return false end
    broadcast(key, locKey)
    return true
end)

MiscB.Cb("restaurant_stations:addSlot", function(source, key, locKey, stKey, x, y, z, h)
    local eff = context(source, key, locKey, stKey)
    local pos = point({ x = x, y = y, z = z })
    if not eff or not pos then return false end
    local def = eff[stKey]
    if type(def.slots) ~= "table" then return false end -- station à zone unique : pas de slots
    local i = 1
    while def.slots["slot" .. i] do i = i + 1 end
    pos.heading = num(h) or 0.0
    def.slots["slot" .. i] = pos
    if not writeRow(key, locKey, stKey, def) then return false end
    broadcast(key, locKey)
    return true
end)

MiscB.Cb("restaurant_stations:removeSlot", function(source, key, locKey, stKey, name)
    local eff = context(source, key, locKey, stKey)
    if not eff or type(name) ~= "string" then return false end
    local def = eff[stKey]
    if type(def.slots) ~= "table" or not def.slots[name] then return false end
    local count = 0
    for _ in pairs(def.slots) do count = count + 1 end
    if count <= 1 then return false end -- une station garde au moins un poste (sinon : la supprimer)
    def.slots[name] = nil
    if not writeRow(key, locKey, stKey, def) then return false end
    broadcast(key, locKey)
    return true
end)

-- Retour à la config d'origine (une station ajoutée par le staff disparaît)
MiscB.Cb("restaurant_stations:reset", function(source, key, locKey, stKey)
    local eff = context(source, key, locKey, stKey)
    if not eff then return false end
    if not deleteRow(key, locKey, stKey) then return false end
    broadcast(key, locKey)
    return true
end)

MiscB.Cb("restaurant_stations:delete", function(source, key, locKey, stKey)
    local eff = context(source, key, locKey, stKey)
    if not eff then return false end
    local own = defaultLoc(key, locKey)
    local ok
    if own and Util.IsStation(own[stKey]) then
        ok = writeRow(key, locKey, stKey, { deleted = true })
    else
        ok = deleteRow(key, locKey, stKey)
    end
    if not ok then return false end
    broadcast(key, locKey)
    return true
end)
