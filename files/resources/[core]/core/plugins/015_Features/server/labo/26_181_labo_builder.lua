---@meta _
---@diagnostic disable: duplicate-doc-field

-- Builder des laboratoires : cote serveur.
--
-- Le menu staff (client/staff/menu/builderLabo.lua, 1 559 lignes) appelle trente points
-- d'entree `laboBuilder:*`. Aucun n'avait ete ecrit : le menu restait bloque sur son
-- premier appel, `getTemplates`, et chargeait indefiniment. Le cote joueur des labos, lui,
-- fonctionne — ses vingt-trois points d'entree `labo:*` sont dans 26_180_labo.lua.
--
-- Le menu manipule aussi des notions que la base ne stockait pas : les templates (un modele
-- d'interieur reutilisable avec ses propres points), les quantites mini/maxi d'une recolte,
-- le rayon et le nombre de recolteurs simultanes, les blips par point, les entrees multiples
-- d'une transformation, et la configuration des attaques. Les tables et colonnes manquantes
-- sont creees au demarrage, sans toucher aux donnees existantes.

local BUILDER_PERM = "labo_builder"
local ATTACK_CONFIG_KEY = "labo_attack_config"

local DEFAULT_ATTACK_CONFIG = {
    attackSlots = {},
    attackCooldownMinutes = 120,
    minFactionOnline = 2,
}

--- Animations proposees dans le menu. Il n'existait aucune liste : le builder demandait des
--- presets a un serveur qui n'en connaissait aucun. Celles-ci sont des animations du jeu de
--- base, utilisables telles quelles ; la liste se complete librement.
local PRESET_ANIMATIONS = {
    { id = "mix",        label = "Melanger (chimie)",     dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",     name = "weed_crouch_checking_leaf_v1_grower" },
    { id = "weigh",      label = "Peser",                 dict = "anim@amb@business@weed@weed_sorting_seated@",          name = "sorter_idle_01_sorter" },
    { id = "pack",       label = "Conditionner",          dict = "anim@amb@business@weed@weed_sorting_seated@",          name = "sorter_idle_02_sorter" },
    { id = "cut",        label = "Decouper",              dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",             name = "machinic_loop_mechandplayer" },
    { id = "cook",       label = "Cuisiner",              dict = "anim@heists@prison_heiststation@cop_reactions",        name = "cop_a_idle" },
    { id = "clean",      label = "Nettoyer",              dict = "timetable@maid@cleaning_surface@idle_a",               name = "idle_a" },
    { id = "crouch",     label = "Accroupi (ramasser)",   dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",             name = "machinic_loop_mechandplayer" },
    { id = "inspect",    label = "Inspecter",             dict = "anim@amb@business@bgen@bgen_no_work@",                 name = "sit_phone_phoneputdown_idle_nowork" },
    { id = "drill",      label = "Percer",                dict = "anim@heists@fleeca_bank@drilling",                     name = "drill_straight_idle" },
    { id = "none",       label = "Aucune animation",      dict = nil,                                                    name = nil },
}

local function num(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

local function int(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return math.floor(n)
end

local function str(value, maxLen)
    if type(value) ~= "string" then return nil end
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return nil end
    return value:sub(1, maxLen or 100)
end

local function encode(value)
    if VFW and VFW.DB and VFW.DB.Encode then return VFW.DB.Encode(value) end
    return json.encode(value or {})
end

local function decode(value, fallback)
    if type(value) == "table" then return value end
    if type(value) ~= "string" or value == "" then return fallback end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

local function query(sql, params)
    local ok, result = pcall(MySQL.query.await, sql, params or {})
    if not ok then
        console.error(("[labo builder] SQL : %s"):format(tostring(result)))
        return {}
    end
    return result or {}
end

local function single(sql, params)
    local ok, result = pcall(MySQL.single.await, sql, params or {})
    if not ok then return nil end
    return result
end

local function execute(sql, params)
    local ok, result = pcall(MySQL.update.await, sql, params or {})
    if not ok then
        console.error(("[labo builder] SQL : %s"):format(tostring(result)))
        return false
    end
    return result
end

local function insert(sql, params)
    local ok, result = pcall(MySQL.insert.await, sql, params or {})
    if not ok then
        console.error(("[labo builder] SQL : %s"):format(tostring(result)))
        return nil
    end
    return result
end

--- Seul le staff autorise touche au builder.
local function builder(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission(BUILDER_PERM) then return nil end
    return xPlayer
end

-- ── Schema ──────────────────────────────────────────────────────────────────────────────

local function hasColumn(table_, column)
    local n = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { table_, column })
    return (tonumber(n) or 0) > 0
end

local function addColumn(table_, column, definition)
    if hasColumn(table_, column) then return end
    execute(("ALTER TABLE `%s` ADD COLUMN `%s` %s"):format(table_, column, definition))
end

--- Colonnes communes aux points de recolte et de transformation, cote labo comme template.
local function pointColumns(table_)
    addColumn(table_, "name", "VARCHAR(100) DEFAULT NULL")
    addColumn(table_, "min_quantity", "INT(11) NOT NULL DEFAULT 1")
    addColumn(table_, "max_quantity", "INT(11) NOT NULL DEFAULT 1")
    addColumn(table_, "radius", "FLOAT NOT NULL DEFAULT 1.5")
    addColumn(table_, "max_harvesters", "INT(11) NOT NULL DEFAULT 1")
    addColumn(table_, "blip_enabled", "TINYINT(1) NOT NULL DEFAULT 0")
    addColumn(table_, "blip_sprite", "INT(11) NOT NULL DEFAULT 1")
    addColumn(table_, "blip_color", "INT(11) NOT NULL DEFAULT 1")
    addColumn(table_, "blip_scale", "FLOAT NOT NULL DEFAULT 0.6")
    addColumn(table_, "blip_label", "VARCHAR(100) DEFAULT NULL")
    addColumn(table_, "inputs", "LONGTEXT DEFAULT NULL")
end

local function ensureSchema()
    -- Colonnes attendues par le menu et absentes de `labos`.
    addColumn("labos", "template_id", "INT(11) DEFAULT NULL")
    addColumn("labos", "owner_player_name", "VARCHAR(100) DEFAULT NULL")
    addColumn("labos", "chest_max_weight", "INT(11) NOT NULL DEFAULT 100000")

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS labo_templates (
            id               INT(11)      NOT NULL AUTO_INCREMENT,
            name             VARCHAR(100) NOT NULL,
            label            VARCHAR(100) DEFAULT NULL,
            interior_x       DOUBLE       NOT NULL DEFAULT 0,
            interior_y       DOUBLE       NOT NULL DEFAULT 0,
            interior_z       DOUBLE       NOT NULL DEFAULT 0,
            interior_heading DOUBLE       NOT NULL DEFAULT 0,
            chest_x          DOUBLE       DEFAULT NULL,
            chest_y          DOUBLE       DEFAULT NULL,
            chest_z          DOUBLE       DEFAULT NULL,
            management_x     DOUBLE       DEFAULT NULL,
            management_y     DOUBLE       DEFAULT NULL,
            management_z     DOUBLE       DEFAULT NULL,
            blip_sprite      INT(11)      NOT NULL DEFAULT 499,
            blip_color       INT(11)      NOT NULL DEFAULT 1,
            blip_scale       FLOAT        NOT NULL DEFAULT 0.8,
            PRIMARY KEY (id),
            UNIQUE KEY uniq_labo_template_name (name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Les points d'un template ont la meme forme que ceux d'un labo : deux tables miroirs,
    -- pour que les points d'un modele ne polluent pas le cache des labos en jeu.
    for _, kind in ipairs({ "harvest", "transform" }) do
        MySQL.query.await(([[
            CREATE TABLE IF NOT EXISTS labo_template_%s_points (
                id               INT(11)      NOT NULL AUTO_INCREMENT,
                template_id      INT(11)      NOT NULL,
                label            VARCHAR(100) DEFAULT NULL,
                coords_x         DOUBLE       NOT NULL DEFAULT 0,
                coords_y         DOUBLE       NOT NULL DEFAULT 0,
                coords_z         DOUBLE       NOT NULL DEFAULT 0,
                rotation_z       DOUBLE       NOT NULL DEFAULT 0,
                marker_x         DOUBLE       DEFAULT NULL,
                marker_y         DOUBLE       DEFAULT NULL,
                marker_z         DOUBLE       DEFAULT NULL,
                prop_model       VARCHAR(60)  DEFAULT NULL,
                item_output      VARCHAR(64)  DEFAULT NULL,
                output_item      VARCHAR(64)  DEFAULT NULL,
                output_quantity  INT(11)      NOT NULL DEFAULT 1,
                harvest_time     INT(11)      NOT NULL DEFAULT 5000,
                transform_time   INT(11)      NOT NULL DEFAULT 5000,
                cooldown_seconds INT(11)      NOT NULL DEFAULT 0,
                animation_type   VARCHAR(32)  NOT NULL DEFAULT 'predefined',
                animation_dict   VARCHAR(100) DEFAULT NULL,
                animation_name   VARCHAR(100) DEFAULT NULL,
                animation_preset VARCHAR(60)  DEFAULT NULL,
                animation_prop   VARCHAR(60)  DEFAULT NULL,
                PRIMARY KEY (id),
                KEY idx_template (template_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]]):format(kind))
    end

    for _, t in ipairs({ "labo_harvest_points", "labo_transform_points",
                         "labo_template_harvest_points", "labo_template_transform_points" }) do
        pointColumns(t)
    end
end

-- ── Lecture ─────────────────────────────────────────────────────────────────────────────

local function attackConfig()
    local saved = nil
    if VFW.Variables and VFW.Variables.GetVariable then
        local ok, value = pcall(VFW.Variables.GetVariable, ATTACK_CONFIG_KEY)
        if ok and type(value) == "table" then saved = value end
    end

    local cfg = {
        attackSlots = type(saved) == "table" and saved.attackSlots or {},
        attackCooldownMinutes = int(saved and saved.attackCooldownMinutes, DEFAULT_ATTACK_CONFIG.attackCooldownMinutes),
        minFactionOnline = int(saved and saved.minFactionOnline, DEFAULT_ATTACK_CONFIG.minFactionOnline),
    }

    if type(cfg.attackSlots) ~= "table" then cfg.attackSlots = {} end
    return cfg
end

RegisterServerCallback("laboBuilder:getLabos", function(source)
    if not builder(source) then return {} end

    local rows = query([[
        SELECT l.*, t.label AS template_label
        FROM labos l
        LEFT JOIN labo_templates t ON t.id = l.template_id
        ORDER BY l.id
    ]])
    return rows
end)

RegisterServerCallback("laboBuilder:getTemplates", function(source)
    if not builder(source) then return {} end
    return query("SELECT * FROM labo_templates ORDER BY id")
end)

RegisterServerCallback("laboBuilder:getItems", function(source)
    if not builder(source) then return {} end

    local out, n = {}, 0
    for name, item in pairs(VFW.Items or {}) do
        n = n + 1
        out[n] = { name = name, label = (type(item) == "table" and item.label) or name }
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end)

RegisterServerCallback("laboBuilder:getFactions", function(source)
    if not builder(source) then return {} end

    local out, n = {}, 0
    for name, job in pairs(VFW.Jobs or {}) do
        local isJob = type(job) == "table" and job.name == name and job.grades ~= nil
        if isJob then
            n = n + 1
            out[n] = { name = name, label = job.label or name }
        end
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end)

RegisterServerCallback("laboBuilder:getPresetAnimations", function(source)
    if not builder(source) then return {} end
    return PRESET_ANIMATIONS
end)

RegisterServerCallback("laboBuilder:getAllPlayers", function(source)
    if not builder(source) then return {} end

    local rows = query([[
        SELECT c.identifier, c.firstname, c.lastname, u.name AS pseudo
        FROM characters c
        LEFT JOIN users u ON u.id = c.account_id
        WHERE c.deleted_at IS NULL
        ORDER BY c.lastname, c.firstname
        LIMIT 300
    ]])

    local out = {}
    for i = 1, #rows do
        out[i] = {
            id = rows[i].identifier,
            identifier = rows[i].identifier,
            name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or ""),
            pseudo = rows[i].pseudo,
        }
    end
    return out
end)

RegisterServerCallback("laboBuilder:searchPlayers", function(source, needle)
    if not builder(source) then return {} end

    local search = str(needle, 64)
    if not search or #search < 2 then return {} end

    local pattern = "%" .. search:gsub("[%%_]", "\\%0") .. "%"
    local rows = query([[
        SELECT c.identifier, c.firstname, c.lastname, u.name AS pseudo
        FROM characters c
        LEFT JOIN users u ON u.id = c.account_id
        WHERE c.deleted_at IS NULL
          AND (c.firstname LIKE ? OR c.lastname LIKE ? OR u.name LIKE ? OR c.identifier LIKE ?)
        ORDER BY c.lastname, c.firstname
        LIMIT 50
    ]], { pattern, pattern, pattern, pattern })

    local out = {}
    for i = 1, #rows do
        out[i] = {
            id = rows[i].identifier,
            identifier = rows[i].identifier,
            name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or ""),
            pseudo = rows[i].pseudo,
        }
    end
    return out
end)

RegisterServerCallback("laboBuilder:getAttackConfig", function(source)
    if not builder(source) then return nil end
    return attackConfig()
end)

RegisterServerCallback("laboBuilder:updateAttackConfig", function(source, payload)
    if not builder(source) then return { success = false } end
    if type(payload) ~= "table" then return { success = false } end

    local slots = {}
    if type(payload.attackSlots) == "table" then
        for i = 1, #payload.attackSlots do
            local slot = payload.attackSlots[i]
            if type(slot) == "table" then
                slots[#slots + 1] = {
                    startHour = math.max(0, math.min(23, int(slot.startHour, 0))),
                    startMin = math.max(0, math.min(59, int(slot.startMin, 0))),
                    endHour = math.max(0, math.min(23, int(slot.endHour, 0))),
                    endMin = math.max(0, math.min(59, int(slot.endMin, 0))),
                }
            end
        end
    end

    local cfg = {
        attackSlots = slots,
        attackCooldownMinutes = math.max(0, int(payload.attackCooldownMinutes, DEFAULT_ATTACK_CONFIG.attackCooldownMinutes)),
        minFactionOnline = math.max(0, int(payload.minFactionOnline, DEFAULT_ATTACK_CONFIG.minFactionOnline)),
    }

    if VFW.Variables and VFW.Variables.SetVariable then
        pcall(VFW.Variables.SetVariable, ATTACK_CONFIG_KEY, cfg)
    end

    TriggerEvent("labo:attackConfig:updated", cfg)
    return { success = true }
end)

-- ── Points de recolte et de transformation ──────────────────────────────────────────────

--- Traduit ce que le menu envoie vers les colonnes de la table, pour les quatre tables
--- (recolte / transformation, labo / template) qui partagent la meme forme.
---@param data table
---@return table|nil
local function sanitizePoint(data)
    if type(data) ~= "table" then return nil end

    local coords = data.coords
    if type(coords) ~= "table" or not tonumber(coords.x) then return nil end

    local marker = type(data.markerCoords) == "table" and data.markerCoords or nil

    return {
        name = str(data.name, 100),
        label = str(data.label, 100) or str(data.name, 100),
        coords_x = num(coords.x, 0.0),
        coords_y = num(coords.y, 0.0),
        coords_z = num(coords.z, 0.0),
        rotation_z = num(data.rotationZ, 0.0),
        marker_x = marker and num(marker.x, nil) or nil,
        marker_y = marker and num(marker.y, nil) or nil,
        marker_z = marker and num(marker.z, nil) or nil,
        prop_model = str(data.propModel, 60),
        item_output = str(data.itemOutput, 64),
        output_item = str(data.outputItem, 64),
        output_quantity = math.max(1, int(data.outputQuantity, 1)),
        min_quantity = math.max(1, int(data.minQuantity, 1)),
        max_quantity = math.max(1, int(data.maxQuantity, int(data.minQuantity, 1))),
        harvest_time = math.max(0, int(data.harvestTime, 5000)),
        transform_time = math.max(0, int(data.transformTime, 5000)),
        cooldown_seconds = math.max(0, int(data.cooldown, 0)),
        radius = math.max(0.5, num(data.radius, 1.5)),
        max_harvesters = math.max(1, int(data.maxHarvesters, 1)),
        animation_type = str(data.animationType, 32) or "predefined",
        animation_dict = str(data.animationDict, 100),
        animation_name = str(data.animationName, 100),
        animation_preset = str(data.animationPreset, 60),
        animation_prop = str(data.animationProp, 60),
        blip_enabled = data.blipEnabled and 1 or 0,
        blip_sprite = int(data.blipSprite, 1),
        blip_color = int(data.blipColor, 1),
        blip_scale = num(data.blipScale, 0.6),
        blip_label = str(data.blipLabel, 100),
        inputs = type(data.inputs) == "table" and encode(data.inputs) or nil,
    }
end

local POINT_COLUMNS <const> = {
    "name", "label", "coords_x", "coords_y", "coords_z", "rotation_z",
    "marker_x", "marker_y", "marker_z", "prop_model", "item_output", "output_item",
    "output_quantity", "min_quantity", "max_quantity", "harvest_time", "transform_time",
    "cooldown_seconds", "radius", "max_harvesters", "animation_type", "animation_dict",
    "animation_name", "animation_preset", "animation_prop", "blip_enabled", "blip_sprite",
    "blip_color", "blip_scale", "blip_label", "inputs",
}

--- Insertion montee colonne par colonne : un `nil` au milieu d'un tableau de parametres en
--- tronque la longueur et la requete partirait decalee.
local function insertPoint(table_, ownerColumn, ownerId, point)
    local names, marks, params = { ("`%s`"):format(ownerColumn) }, { "?" }, { ownerId }

    for i = 1, #POINT_COLUMNS do
        local column = POINT_COLUMNS[i]
        local value = point[column]
        if value ~= nil then
            names[#names + 1] = ("`%s`"):format(column)
            marks[#marks + 1] = "?"
            params[#params + 1] = value
        end
    end

    return insert(("INSERT INTO `%s` (%s) VALUES (%s)")
        :format(table_, table.concat(names, ", "), table.concat(marks, ", ")), params)
end

local function updatePoint(table_, id, point)
    local sets, params = {}, {}

    for i = 1, #POINT_COLUMNS do
        local column = POINT_COLUMNS[i]
        sets[#sets + 1] = ("`%s` = ?"):format(column)
        params[#params + 1] = point[column]
    end

    params[#params + 1] = id
    return execute(("UPDATE `%s` SET %s WHERE id = ?"):format(table_, table.concat(sets, ", ")), params)
end

--- Enregistre les quatre points d'entree d'un type de point (lister, creer, modifier,
--- supprimer) pour une table donnee.
local function registerPointEndpoints(prefix, table_, ownerColumn)
    RegisterServerCallback("laboBuilder:get" .. prefix .. "s", function(source, ownerId)
        if not builder(source) then return {} end
        local id = int(ownerId, nil)
        if not id then return {} end

        local rows = query(("SELECT * FROM `%s` WHERE `%s` = ? ORDER BY id"):format(table_, ownerColumn), { id })
        for i = 1, #rows do
            rows[i].inputs = decode(rows[i].inputs, {})
            rows[i].blip_enabled = rows[i].blip_enabled == 1
        end
        return rows
    end)

    RegisterServerCallback("laboBuilder:create" .. prefix, function(source, ownerId, data)
        if not builder(source) then return { success = false, error = "Permission refusee." } end

        local id = int(ownerId, nil)
        local point = sanitizePoint(data)
        if not id or not point then return { success = false, error = "Donnees invalides." } end

        local newId = insertPoint(table_, ownerColumn, id, point)
        if not newId then return { success = false, error = "Creation impossible." } end

        TriggerEvent("labo:builder:changed")
        return { success = true, id = newId }
    end)

    RegisterServerCallback("laboBuilder:update" .. prefix, function(source, pointId, data)
        if not builder(source) then return { success = false, error = "Permission refusee." } end

        local id = int(pointId, nil)
        local point = sanitizePoint(data)
        if not id or not point then return { success = false, error = "Donnees invalides." } end

        updatePoint(table_, id, point)
        TriggerEvent("labo:builder:changed")
        return { success = true }
    end)

    RegisterServerCallback("laboBuilder:delete" .. prefix, function(source, pointId)
        if not builder(source) then return { success = false } end

        local id = int(pointId, nil)
        if not id then return { success = false } end

        execute(("DELETE FROM `%s` WHERE id = ?"):format(table_), { id })
        TriggerEvent("labo:builder:changed")
        return { success = true }
    end)
end

registerPointEndpoints("HarvestPoint", "labo_harvest_points", "labo_id")
registerPointEndpoints("TransformPoint", "labo_transform_points", "labo_id")
registerPointEndpoints("TemplateHarvestPoint", "labo_template_harvest_points", "template_id")
registerPointEndpoints("TemplateTransformPoint", "labo_template_transform_points", "template_id")

-- ── Laboratoires ────────────────────────────────────────────────────────────────────────

--- Recopie les points d'un template dans un labo fraichement cree.
local function copyTemplatePoints(templateId, laboId)
    for _, kind in ipairs({ "harvest", "transform" }) do
        local rows = query(("SELECT * FROM labo_template_%s_points WHERE template_id = ?"):format(kind), { templateId })
        for i = 1, #rows do
            local row = rows[i]
            local point = {}
            for j = 1, #POINT_COLUMNS do
                point[POINT_COLUMNS[j]] = row[POINT_COLUMNS[j]]
            end
            insertPoint(("labo_%s_points"):format(kind), "labo_id", laboId, point)
        end
    end
end

---@param data table
---@return table|nil
local function sanitizeLabo(data)
    if type(data) ~= "table" then return nil end

    local label = str(data.label, 100)
    local door = data.doorCoords
    if not label or type(door) ~= "table" or not tonumber(door.x) then return nil end

    local interior = type(data.interiorCoords) == "table" and data.interiorCoords or nil
    local chest = type(data.chestCoords) == "table" and data.chestCoords or nil
    local management = type(data.managementCoords) == "table" and data.managementCoords or nil

    return {
        name = str(data.name, 100) or label:lower():gsub("[^%w]+", "_"),
        label = label,
        template_id = int(data.templateId, nil),
        owner_faction = str(data.ownerFaction, 60) or "no_owner",
        owner_player_name = str(data.ownerPlayerName, 100),
        door_x = num(door.x, 0.0), door_y = num(door.y, 0.0), door_z = num(door.z, 0.0),
        door_heading = num(door.heading, 0.0),
        interior_x = interior and num(interior.x, 0.0) or 0.0,
        interior_y = interior and num(interior.y, 0.0) or 0.0,
        interior_z = interior and num(interior.z, 0.0) or 0.0,
        interior_heading = interior and num(interior.heading, 0.0) or 0.0,
        chest_x = chest and num(chest.x, nil) or nil,
        chest_y = chest and num(chest.y, nil) or nil,
        chest_z = chest and num(chest.z, nil) or nil,
        management_x = management and num(management.x, nil) or nil,
        management_y = management and num(management.y, nil) or nil,
        management_z = management and num(management.z, nil) or nil,
        chest_max_slots = math.max(1, int(data.chestMaxSlots, 40)),
        chest_max_weight = math.max(1, int(data.chestMaxWeight, 100000)),
    }
end

--- Un labo cree depuis un template herite de son interieur et de ses blips.
local function applyTemplate(labo)
    if not labo.template_id then return labo end

    local template = single("SELECT * FROM labo_templates WHERE id = ?", { labo.template_id })
    if not template then return labo end

    if labo.interior_x == 0.0 and labo.interior_y == 0.0 then
        labo.interior_x = template.interior_x
        labo.interior_y = template.interior_y
        labo.interior_z = template.interior_z
        labo.interior_heading = template.interior_heading
    end

    if labo.chest_x == nil then
        labo.chest_x, labo.chest_y, labo.chest_z = template.chest_x, template.chest_y, template.chest_z
    end

    if labo.management_x == nil then
        labo.management_x, labo.management_y, labo.management_z =
            template.management_x, template.management_y, template.management_z
    end

    labo.blip_sprite = template.blip_sprite
    labo.blip_color = template.blip_color
    labo.blip_scale = template.blip_scale

    return labo
end

local LABO_COLUMNS <const> = {
    "name", "label", "template_id", "owner_faction", "owner_player_name",
    "door_x", "door_y", "door_z", "door_heading",
    "interior_x", "interior_y", "interior_z", "interior_heading",
    "chest_x", "chest_y", "chest_z", "management_x", "management_y", "management_z",
    "chest_max_slots", "chest_max_weight", "blip_sprite", "blip_color", "blip_scale",
}

RegisterServerCallback("laboBuilder:createLabo", function(source, data)
    local xPlayer = builder(source)
    if not xPlayer then return { success = false, error = "Permission refusee." } end

    local labo = sanitizeLabo(data)
    if not labo then return { success = false, error = "Il faut un label, une porte et un interieur." } end

    applyTemplate(labo)

    local names, marks, params = {}, {}, {}
    for i = 1, #LABO_COLUMNS do
        local column = LABO_COLUMNS[i]
        if labo[column] ~= nil then
            names[#names + 1] = ("`%s`"):format(column)
            marks[#marks + 1] = "?"
            params[#params + 1] = labo[column]
        end
    end

    local id = insert(("INSERT INTO labos (%s) VALUES (%s)")
        :format(table.concat(names, ", "), table.concat(marks, ", ")), params)

    if not id then return { success = false, error = "Creation impossible." } end

    if labo.template_id then copyTemplatePoints(labo.template_id, id) end

    TriggerEvent("labo:builder:changed")
    return { success = true, id = id }
end)

RegisterServerCallback("laboBuilder:updateLabo", function(source, laboId, data)
    if not builder(source) then return { success = false, error = "Permission refusee." } end

    local id = int(laboId, nil)
    local labo = sanitizeLabo(data)
    if not id or not labo then return { success = false, error = "Donnees invalides." } end

    local sets, params = {}, {}
    for i = 1, #LABO_COLUMNS do
        local column = LABO_COLUMNS[i]
        if labo[column] ~= nil or column:find("^chest_") or column:find("^management_") then
            sets[#sets + 1] = ("`%s` = ?"):format(column)
            params[#params + 1] = labo[column]
        end
    end

    params[#params + 1] = id
    execute(("UPDATE labos SET %s WHERE id = ?"):format(table.concat(sets, ", ")), params)

    TriggerEvent("labo:builder:changed")
    return { success = true }
end)

RegisterServerCallback("laboBuilder:deleteLabo", function(source, laboId)
    if not builder(source) then return { success = false } end

    local id = int(laboId, nil)
    if not id then return { success = false } end

    execute("DELETE FROM labo_harvest_points WHERE labo_id = ?", { id })
    execute("DELETE FROM labo_transform_points WHERE labo_id = ?", { id })
    execute("DELETE FROM labo_access WHERE labo_id = ?", { id })
    execute("DELETE FROM labo_stats WHERE labo_id = ?", { id })
    execute("DELETE FROM labos WHERE id = ?", { id })

    TriggerEvent("labo:builder:changed")
    return { success = true }
end)

-- ── Templates ───────────────────────────────────────────────────────────────────────────

RegisterServerCallback("laboBuilder:updateTemplate", function(source, templateId, data)
    if not builder(source) then return { success = false, error = "Permission refusee." } end
    if type(data) ~= "table" then return { success = false, error = "Donnees invalides." } end

    local label = str(data.label, 100)
    local name = str(data.name, 100) or (label and label:lower():gsub("[^%w]+", "_"))
    if not label or not name then return { success = false, error = "Il faut un nom et un label." } end

    local interior = type(data.interiorCoords) == "table" and data.interiorCoords or {}
    local chest = type(data.chestCoords) == "table" and data.chestCoords or nil
    local management = type(data.managementCoords) == "table" and data.managementCoords or nil

    local fields = {
        name = name,
        label = label,
        interior_x = num(interior.x, 0.0),
        interior_y = num(interior.y, 0.0),
        interior_z = num(interior.z, 0.0),
        interior_heading = num(interior.heading, 0.0),
        chest_x = chest and num(chest.x, nil) or nil,
        chest_y = chest and num(chest.y, nil) or nil,
        chest_z = chest and num(chest.z, nil) or nil,
        management_x = management and num(management.x, nil) or nil,
        management_y = management and num(management.y, nil) or nil,
        management_z = management and num(management.z, nil) or nil,
        blip_sprite = int(data.blipSprite, 499),
        blip_color = int(data.blipColor, 1),
        blip_scale = num(data.blipScale, 0.8),
    }

    local columns = { "name", "label", "interior_x", "interior_y", "interior_z", "interior_heading",
                      "chest_x", "chest_y", "chest_z", "management_x", "management_y", "management_z",
                      "blip_sprite", "blip_color", "blip_scale" }

    local id = int(templateId, nil)

    if id then
        local sets, params = {}, {}
        for i = 1, #columns do
            sets[#sets + 1] = ("`%s` = ?"):format(columns[i])
            params[#params + 1] = fields[columns[i]]
        end
        params[#params + 1] = id
        execute(("UPDATE labo_templates SET %s WHERE id = ?"):format(table.concat(sets, ", ")), params)
        return { success = true, id = id }
    end

    local names, marks, params = {}, {}, {}
    for i = 1, #columns do
        if fields[columns[i]] ~= nil then
            names[#names + 1] = ("`%s`"):format(columns[i])
            marks[#marks + 1] = "?"
            params[#params + 1] = fields[columns[i]]
        end
    end

    local newId = insert(("INSERT INTO labo_templates (%s) VALUES (%s)")
        :format(table.concat(names, ", "), table.concat(marks, ", ")), params)

    if not newId then return { success = false, error = "Un template porte deja ce nom." } end
    return { success = true, id = newId }
end)

RegisterServerCallback("laboBuilder:syncLabos", function(source)
    if not builder(source) then return { success = false } end
    TriggerEvent("labo:builder:changed")
    return { success = true }
end)

MySQL.ready(function()
    local ok, err = pcall(ensureSchema)
    if not ok then
        console.error("[labo builder] schema : " .. tostring(err))
        return
    end
    console.info("[labo builder] points d'entree prets")
end)
