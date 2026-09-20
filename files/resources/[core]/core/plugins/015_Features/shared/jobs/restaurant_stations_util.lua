-- ══════════════════════════════════════════════════════════════════
-- RestaurantStations — utilitaires partagés (positions des stations)
-- ══════════════════════════════════════════════════════════════════
-- Permet de déplacer les stations de craft des restaurants (Grill,
-- Friteuse, Four, Table de préparation, Machine, etc.) depuis le menu
-- F10. Les helpers ci-dessous sont génériques : ils introspectent la
-- config (center / coords / slots) sans connaître la forme exacte de
-- chaque station.
-- ══════════════════════════════════════════════════════════════════

RestaurantStations = RestaurantStations or {}

-- clé interne -> nom du global de config (shared/jobs/<resto>.lua)
RestaurantStations.Mapping = {
    burgershot  = "BurgerShotConfig",
    pizzeria    = "PizzeriaConfig",
    pearls      = "PearlsConfig",
    noodle      = "NoodleConfig",
    bean_coffee = "BeanCoffeeConfig",
    uwu_cafe    = "UwuCafeConfig",
}

-- libellés FR des stations connues (sinon on affiche la clé brute)
RestaurantStations.StationLabels = {
    Machine          = "Machine à boissons",
    SteakStation     = "Grill",
    GrillStation     = "Grill",
    FryerStation     = "Friteuse",
    OvenStation      = "Four",
    BrothStation     = "Bouillon",
    CraftingTable    = "Table de préparation",
    MilkshakeStation = "Milkshake",
    GranitaStation   = "Granita",
}

---@param key string clé restaurant
---@return table|nil cfg le global de config (ou nil)
function RestaurantStations.GetConfig(key)
    local name = RestaurantStations.Mapping[key]
    if not name then return nil end
    return _G[name]
end

-- une "station" est une table contenant un point d'interaction
local function isStation(v)
    return type(v) == "table" and (v.center ~= nil or v.coords ~= nil or v.slots ~= nil)
end
RestaurantStations.IsStation = isStation

---Itère sur toutes les stations d'une config : fn(locKey, stationKey, station)
---@param cfg table config restaurant (doit avoir .Locations)
---@param fn fun(locKey:string, stationKey:string, station:table)
function RestaurantStations.ForEachStation(cfg, fn)
    if not cfg or type(cfg.Locations) ~= "table" then return end
    for locKey, loc in pairs(cfg.Locations) do
        if type(loc) == "table" then
            for stKey, st in pairs(loc) do
                if isStation(st) then fn(locKey, stKey, st) end
            end
        end
    end
end

---Capture la géométrie modifiable d'une station -> table de nombres (sérialisable)
---@param st table
---@return table
function RestaurantStations.Snapshot(st)
    local o = {}
    if st.center then o.center = { x = st.center.x, y = st.center.y, z = st.center.z } end
    if st.coords then o.coords = { x = st.coords.x, y = st.coords.y, z = st.coords.z } end
    if st.heading ~= nil then o.heading = st.heading + 0.0 end
    if st.slots then
        o.slots = {}
        for name, s in pairs(st.slots) do
            if s.pos then
                o.slots[name] = { x = s.pos.x, y = s.pos.y, z = s.pos.z, heading = (s.heading or 0.0) + 0.0 }
            end
        end
    end
    return o
end

---Applique une géométrie (snapshot) sur une station live.
---N'écrit que les champs déjà présents sur la station (jamais d'ajout).
---@param st table station live (mutée en place)
---@param data table snapshot
function RestaurantStations.Apply(st, data)
    if type(st) ~= "table" or type(data) ~= "table" then return end
    if data.center and st.center then
        st.center = vector3(data.center.x + 0.0, data.center.y + 0.0, data.center.z + 0.0)
    end
    if data.coords and st.coords then
        st.coords = vector3(data.coords.x + 0.0, data.coords.y + 0.0, data.coords.z + 0.0)
    end
    if data.heading ~= nil and st.heading ~= nil then
        st.heading = data.heading + 0.0
    end
    if data.slots and st.slots then
        for name, s in pairs(data.slots) do
            if st.slots[name] then
                st.slots[name].pos = vector3(s.x + 0.0, s.y + 0.0, s.z + 0.0)
                if s.heading ~= nil then st.slots[name].heading = s.heading + 0.0 end
            end
        end
    end
end

---Capture la définition COMPLÈTE d'une station -> table sérialisable
---(géométrie + radius/duration + tout champ scalaire). Sert à recréer
---une station identique (templates, sync structurelle).
---@param st table
---@return table
function RestaurantStations.FullSnapshot(st)
    local o = {}
    for k, v in pairs(st) do
        if k == "center" or k == "coords" then
            o[k] = { x = v.x, y = v.y, z = v.z }
        elseif k == "slots" then
            o.slots = {}
            for name, s in pairs(v) do
                if s.pos then
                    o.slots[name] = { x = s.pos.x, y = s.pos.y, z = s.pos.z, heading = (s.heading or 0.0) + 0.0 }
                end
            end
        elseif type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
            o[k] = v
        end
    end
    return o
end

---Reconstruit une station live (avec vector3) depuis une définition complète.
---@param def table
---@return table
function RestaurantStations.BuildStation(def)
    local st = {}
    for k, v in pairs(def) do
        if k == "center" or k == "coords" then
            st[k] = vector3(v.x + 0.0, v.y + 0.0, v.z + 0.0)
        elseif k == "slots" then
            st.slots = {}
            for name, s in pairs(v) do
                st.slots[name] = { pos = vector3(s.x + 0.0, s.y + 0.0, s.z + 0.0), heading = (s.heading or 0.0) + 0.0 }
            end
        else
            st[k] = v
        end
    end
    return st
end
