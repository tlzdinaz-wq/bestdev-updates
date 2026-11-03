-- Prix des customs mécano : le côté serveur du builder.
--
-- Gestion > Builders > PRIX CUSTOM se sert de neuf appels serveur. Aucun
-- n'existait. Le menu demandait la liste des modifications, attendait quinze
-- secondes, recevait `nil`, et affichait des titres de rubriques sans une seule
-- ligne dessous — d'où « on ne peut pas changer le prix des full perf ni des
-- couleurs ». Les trois sous-menus (prix de base, % par catégorie, % par
-- modèle) étaient tous muets, et rien ne s'enregistrait.
--
-- Les tables existent depuis toujours (`custom_prices_base`,
-- `custom_prices_category`, `custom_prices_model`) et le menu mécano sait déjà
-- les lire : il ne manquait que de quoi écrire dedans.
--
-- Les identifiants ci-dessous sont ceux que le menu mécano consulte
-- (society/client/customs.lua) : en changer un reviendrait à régler un prix que
-- personne ne lit.

local MOD_TYPES <const> = {
    -- Performance : le prix par niveau s'ajoute au prix de base à chaque cran.
    { id = "engine",          label = "Moteur",                   category = "performance", hasLevels = true },
    { id = "brakes",          label = "Freins",                   category = "performance", hasLevels = true },
    { id = "transmission",    label = "Transmission",             category = "performance", hasLevels = true },
    { id = "suspension",      label = "Suspension",               category = "performance", hasLevels = true },
    { id = "turbo",           label = "Turbo",                    category = "performance", hasLevels = false },

    { id = "spoiler",         label = "Aileron",                  category = "aesthetic",   hasLevels = false },
    { id = "front_bumper",    label = "Pare-chocs avant",         category = "aesthetic",   hasLevels = false },
    { id = "rear_bumper",     label = "Pare-chocs arriere",       category = "aesthetic",   hasLevels = false },
    { id = "side_skirts",     label = "Bas de caisse",            category = "aesthetic",   hasLevels = false },
    { id = "exhaust",         label = "Echappement",              category = "aesthetic",   hasLevels = false },
    { id = "grille",          label = "Calandre",                 category = "aesthetic",   hasLevels = false },
    { id = "hood",            label = "Capot",                    category = "aesthetic",   hasLevels = false },
    { id = "fender",          label = "Ailes",                    category = "aesthetic",   hasLevels = false },
    { id = "roof",            label = "Toit",                     category = "aesthetic",   hasLevels = false },

    { id = "primary_color",   label = "Couleur primaire",         category = "color",       hasLevels = false },
    { id = "secondary_color", label = "Couleur secondaire",       category = "color",       hasLevels = false },
    { id = "pearlescent",     label = "Nacre",                    category = "color",       hasLevels = false },

    { id = "wheel_type",      label = "Type de jantes",           category = "wheels",      hasLevels = false },
    { id = "wheel_model",     label = "Modele de jantes",         category = "wheels",      hasLevels = false },
    { id = "wheel_color",     label = "Couleur des jantes",       category = "wheels",      hasLevels = false },
    { id = "tire_smoke",      label = "Fumee de pneus",           category = "wheels",      hasLevels = false },

    { id = "xenon",           label = "Xenon",                    category = "lights",      hasLevels = false },
    { id = "xenon_color",     label = "Couleur des xenons",       category = "lights",      hasLevels = false },
    { id = "neon",            label = "Neons",                    category = "lights",      hasLevels = false },
    { id = "neon_color",      label = "Couleur des neons",        category = "lights",      hasLevels = false },

    { id = "window_tint",     label = "Vitres teintees",          category = "interior",    hasLevels = false },
    { id = "interior_color",  label = "Couleur interieure",       category = "interior",    hasLevels = false },
    { id = "dashboard_color", label = "Couleur du tableau de bord", category = "interior",  hasLevels = false },

    { id = "plate_style",     label = "Style de plaque",          category = "other",       hasLevels = false },
    { id = "livery",          label = "Livree",                   category = "other",       hasLevels = false },
    { id = "horn",            label = "Klaxon",                   category = "other",       hasLevels = false },
}

-- Classes de véhicules du jeu, dans l'ordre de GetVehicleClass : le menu mécano
-- retient le même nom pour chercher le pourcentage de la classe.
local VEHICLE_CLASSES <const> = {
    { name = "Compacts",        label = "Compactes" },
    { name = "Sedans",          label = "Berlines" },
    { name = "SUVs",            label = "SUV" },
    { name = "Coupes",          label = "Coupes" },
    { name = "Muscle",          label = "Muscle" },
    { name = "SportsClassics",  label = "Sport classique" },
    { name = "Sports",          label = "Sport" },
    { name = "Super",           label = "Super" },
    { name = "Motorcycles",     label = "Motos" },
    { name = "OffRoad",         label = "Tout-terrain" },
    { name = "Industrial",      label = "Industriel" },
    { name = "Utility",         label = "Utilitaire" },
    { name = "Vans",            label = "Fourgons" },
    { name = "Cycles",          label = "Velos" },
    { name = "Boats",           label = "Bateaux" },
    { name = "Helicopters",     label = "Helicopteres" },
    { name = "Planes",          label = "Avions" },
    { name = "Service",         label = "Service" },
    { name = "Emergency",       label = "Urgence" },
    { name = "Military",        label = "Militaire" },
    { name = "Commercial",      label = "Commercial" },
    { name = "Trains",          label = "Trains" },
    { name = "OpenWheel",       label = "Formule" },
}

local MOD_TYPE_IDS = {}
for i = 1, #MOD_TYPES do MOD_TYPE_IDS[MOD_TYPES[i].id] = true end

local CLASS_NAMES = {}
for i = 1, #VEHICLE_CLASSES do CLASS_NAMES[VEHICLE_CLASSES[i].name] = true end

local PRICE_MAX <const> = 10000000
local PERCENT_MIN <const> = -100
local PERCENT_MAX <const> = 1000

local function fail(message)
    return { success = false, error = message or "Action impossible." }
end

--- Le staff autorisé à toucher aux prix.
---@param source number
---@return table|nil
local function allowed(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("manage_custom_prices")
        or xPlayer.hasPermission("staff_menu")
        or xPlayer.hasPermission("dev") then
        return xPlayer
    end
    return nil
end

---@param value any
---@param min number
---@param max number
---@return number|nil
local function clampNumber(value, min, max)
    local n = tonumber(value)
    if not n or n ~= n then return nil end
    n = math.floor(n + 0.5)
    if n < min then n = min end
    if n > max then n = max end
    return n
end

--- Recharge le cache des prix et le renvoie à tout le monde.
---
--- Sans cela, un prix changé ne vaudrait qu'au prochain démarrage du serveur :
--- le mécano continuerait de facturer l'ancien.
local function refresh()
    if type(VFW.Society.ReloadCustomPrices) == "function" then
        VFW.Society.ReloadCustomPrices()
    elseif type(VFW.Society.SyncCustomPrices) == "function" then
        VFW.Society.SyncCustomPrices()
    end
end

--- Les surcharges d'une ligne (catégorie ou modèle), nettoyées.
---@param table_ string
---@param column string
---@param key string
---@return table
local function readOverrides(table_, column, key)
    local row = VFW.Society.Single(
        ("SELECT overrides FROM %s WHERE %s = ? LIMIT 1"):format(table_, column), { key })
    local decoded = row and VFW.DB.Decode(row.overrides, {}) or {}
    return type(decoded) == "table" and decoded or {}
end

local register = VFW.Society.RegisterCallback

-- ── Lecture ─────────────────────────────────────────────────────

register("customPrices:getModTypes", function(source)
    if not allowed(source) then return {} end
    return MOD_TYPES
end)

register("customPrices:getVehicleClasses", function(source)
    if not allowed(source) then return {} end
    return VEHICLE_CLASSES
end)

-- ── Prix de base ────────────────────────────────────────────────

register("customPrices:updateBasePrice", function(source, modType, basePrice, pricePerLevel)
    if not allowed(source) then return fail("Permission refusee.") end
    if type(modType) ~= "string" or not MOD_TYPE_IDS[modType] then
        return fail("Cette modification n'existe pas.")
    end

    local price = clampNumber(basePrice, 0, PRICE_MAX)
    if not price then return fail("Ce prix n'est pas un nombre.") end
    local perLevel = clampNumber(pricePerLevel, 0, PRICE_MAX) or 0

    local saved = VFW.Society.Insert([[
        INSERT INTO custom_prices_base (mod_type, base_price, price_per_level)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE base_price = VALUES(base_price), price_per_level = VALUES(price_per_level)
    ]], { modType, price, perLevel })

    if saved == nil then return fail("Enregistrement impossible.") end

    refresh()
    return { success = true }
end)

-- ── Pourcentage par classe de véhicule ──────────────────────────

register("customPrices:setCategoryModifier", function(source, category, percent)
    if not allowed(source) then return fail("Permission refusee.") end
    if type(category) ~= "string" or not CLASS_NAMES[category] then
        return fail("Cette classe de vehicule n'existe pas.")
    end

    local value = clampNumber(percent, PERCENT_MIN, PERCENT_MAX)
    if not value then return fail("Ce pourcentage n'est pas un nombre.") end

    local overrides = readOverrides("custom_prices_category", "category", category)

    -- Zéro et aucune surcharge : la ligne n'a plus de raison d'être.
    if value == 0 and next(overrides) == nil then
        VFW.Society.Update("DELETE FROM custom_prices_category WHERE category = ?", { category })
        refresh()
        return { success = true }
    end

    local saved = VFW.Society.Insert([[
        INSERT INTO custom_prices_category (category, modifier, overrides)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE modifier = VALUES(modifier)
    ]], { category, value, json.encode(overrides) })

    if saved == nil then return fail("Enregistrement impossible.") end

    refresh()
    return { success = true }
end)

register("customPrices:setCategoryOverride", function(source, category, modType, percent)
    if not allowed(source) then return fail("Permission refusee.") end
    if type(category) ~= "string" or not CLASS_NAMES[category] then
        return fail("Cette classe de vehicule n'existe pas.")
    end
    if type(modType) ~= "string" or not MOD_TYPE_IDS[modType] then
        return fail("Cette modification n'existe pas.")
    end

    local value = clampNumber(percent, PERCENT_MIN, PERCENT_MAX)
    if not value then return fail("Ce pourcentage n'est pas un nombre.") end

    local overrides = readOverrides("custom_prices_category", "category", category)
    -- Zéro veut dire « revenir au pourcentage global » : on retire la surcharge.
    overrides[modType] = value ~= 0 and value or nil

    local row = VFW.Society.Single(
        "SELECT modifier FROM custom_prices_category WHERE category = ? LIMIT 1", { category })
    local modifier = row and tonumber(row.modifier) or 0

    if modifier == 0 and next(overrides) == nil then
        VFW.Society.Update("DELETE FROM custom_prices_category WHERE category = ?", { category })
        refresh()
        return { success = true }
    end

    local saved = VFW.Society.Insert([[
        INSERT INTO custom_prices_category (category, modifier, overrides)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE overrides = VALUES(overrides)
    ]], { category, modifier, json.encode(overrides) })

    if saved == nil then return fail("Enregistrement impossible.") end

    refresh()
    return { success = true }
end)

-- ── Pourcentage par modèle ──────────────────────────────────────

--- Le menu mécano cherche le modèle en minuscules : on range pareil.
---@param model any
---@return string|nil
local function modelKey(model)
    if type(model) ~= "string" then return nil end
    local clean = model:gsub("[^%w_%-]", ""):lower()
    if clean == "" or #clean > 60 then return nil end
    return clean
end

register("customPrices:setModelModifier", function(source, model, percent)
    if not allowed(source) then return fail("Permission refusee.") end

    local key = modelKey(model)
    if not key then return fail("Ce modele n'est pas valide.") end

    local value = clampNumber(percent, PERCENT_MIN, PERCENT_MAX)
    if not value then return fail("Ce pourcentage n'est pas un nombre.") end

    local overrides = readOverrides("custom_prices_model", "model", key)

    if value == 0 and next(overrides) == nil then
        VFW.Society.Update("DELETE FROM custom_prices_model WHERE model = ?", { key })
        refresh()
        return { success = true }
    end

    local saved = VFW.Society.Insert([[
        INSERT INTO custom_prices_model (model, modifier, overrides)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE modifier = VALUES(modifier)
    ]], { key, value, json.encode(overrides) })

    if saved == nil then return fail("Enregistrement impossible.") end

    refresh()
    return { success = true }
end)

register("customPrices:setModelOverride", function(source, model, modType, percent)
    if not allowed(source) then return fail("Permission refusee.") end

    local key = modelKey(model)
    if not key then return fail("Ce modele n'est pas valide.") end
    if type(modType) ~= "string" or not MOD_TYPE_IDS[modType] then
        return fail("Cette modification n'existe pas.")
    end

    local value = clampNumber(percent, PERCENT_MIN, PERCENT_MAX)
    if not value then return fail("Ce pourcentage n'est pas un nombre.") end

    local overrides = readOverrides("custom_prices_model", "model", key)
    overrides[modType] = value ~= 0 and value or nil

    local row = VFW.Society.Single(
        "SELECT modifier FROM custom_prices_model WHERE model = ? LIMIT 1", { key })
    local modifier = row and tonumber(row.modifier) or 0

    if modifier == 0 and next(overrides) == nil then
        VFW.Society.Update("DELETE FROM custom_prices_model WHERE model = ?", { key })
        refresh()
        return { success = true }
    end

    local saved = VFW.Society.Insert([[
        INSERT INTO custom_prices_model (model, modifier, overrides)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE overrides = VALUES(overrides)
    ]], { key, modifier, json.encode(overrides) })

    if saved == nil then return fail("Enregistrement impossible.") end

    refresh()
    return { success = true }
end)

register("customPrices:deleteModelModifier", function(source, model)
    if not allowed(source) then return fail("Permission refusee.") end

    local key = modelKey(model)
    if not key then return fail("Ce modele n'est pas valide.") end

    VFW.Society.Update("DELETE FROM custom_prices_model WHERE model = ?", { key })
    refresh()
    return { success = true }
end)
