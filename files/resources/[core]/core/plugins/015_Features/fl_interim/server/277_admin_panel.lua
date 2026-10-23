---@meta _
---@diagnostic disable: duplicate-doc-field

-- Gestion > Intérim : le staff gère les métiers d'intérim depuis le hub de gestion.
--
--   · fiche d'un métier : nom, description, horaires / zone / véhicule / prérequis (affichés dans le centre
--     d'emploi), image, activé ou non ;
--   · points : PNJ, zones d'interaction, emplacements de véhicules, points de livraison, acheteurs, zones de
--     minage... (chacun se pose sur le monde ou à la position du staff) ;
--   · réglages : modèles de véhicules et de PNJ, délais, quantités, paiements ;
--   · centre d'emploi : PNJ qui présentent les offres.
--
-- Les points sont écrits dans `interim_job_positions`, les réglages dans `interim_job_config` (comme les
-- anciennes valeurs d'origine) ; le serveur relit tout à chaque action (véhicules, livraisons, validations) : les
-- changements y sont immédiats. Les PNJ et marqueurs déjà affichés chez un joueur se mettent à jour à sa
-- reconnexion.

local PERMS <const> = { "builder_interim_economy", "server_management", "dev", "admin", "gestion" }

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    for i = 1, #PERMS do
        if xPlayer.hasPermission(PERMS[i]) then return xPlayer end
    end
    return nil
end

local function fail(message) return { ok = false, error = message or "Action impossible." } end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = deepCopy(v) end
    return out
end

local function getAt(root, path)
    local node = root
    for i = 1, #path do
        if type(node) ~= "table" then return nil end
        node = node[path[i]]
    end
    return node
end

local function setAt(root, path, value)
    local node = root
    for i = 1, #path - 1 do
        if type(node[path[i]]) ~= "table" then node[path[i]] = {} end
        node = node[path[i]]
    end
    node[path[#path]] = value
end

local function round(n) return math.floor((tonumber(n) or 0) * 100 + 0.5) / 100 end

-- ═══════════════════════════════════════════════════════════════
-- Ce que chaque métier sait lire (les clefs sont celles des fichiers 272 à 275)
-- ═══════════════════════════════════════════════════════════════

local function point(id, label, path, extra)
    local f = { id = id, label = label, kind = "point", path = path }
    for k, v in pairs(extra or {}) do f[k] = v end
    return f
end

--- shape : "flat" ({ x, y, z, [w], [radius] }), "coords" ({ coords = { x, y, z }, radius }) ;
--- map = true : table à clefs « spot_1 », « spot_2 »... au lieu d'une liste.
local function list(id, label, path, extra)
    local f = { id = id, label = label, kind = "list", path = path, shape = "flat" }
    for k, v in pairs(extra or {}) do f[k] = v end
    return f
end

local function setting(id, label, path, kind, extra)
    local f = { id = id, label = label, path = path, type = kind, scope = "config" }
    for k, v in pairs(extra or {}) do f[k] = v end
    return f
end

local SCHEMA <const> = {
    pizza = {
        points = {
            point("startplace", "Pizzaiolo : zone d'interaction", { "startplace" }, { radius = { "startplace_radius" }, radiusDefault = 2.5 }),
            point("npc", "Pizzaiolo : PNJ", { "startplacenpc" }, { heading = { "startplace_npcheading" } }),
            point("pickup", "Prise des pizzas", { "pickuppoint" }, { radius = { "pickuppoint_radius" }, radiusDefault = 1.75 }),
            point("return", "Retour du scooter", { "returnpoint" }, { radius = { "returnpoint_radius" }, radiusDefault = 3.0 }),
            list("scooters", "Emplacements des scooters", { "scooterSpots" }, { heading = "w", ground = true }),
            list("deliveries", "Points de livraison (portes)", { "deliveryPoints" }, { heading = "w" }),
        },
        settings = {
            setting("vehicle", "Modèle du scooter", { "vehicle" }, "model"),
            setting("maxStock", "Pizzas par tournée", { "maxStock" }, "number", { min = 1, max = 50 }),
            setting("pay", "Paiement par livraison ($)", { "payPerDelivery" }, "number", { min = 0, max = 100000 }),
            setting("cooldown", "Délai avant d'annuler une tournée (ms)", { "cancelCooldown" }, "number", { min = 0, max = 3600000 }),
            setting("ped", "Modèle du pizzaiolo", { "main", "pedService" }, "model"),
            setting("customers", "Modèles des clients", { "possibleNPCS" }, "models", { hint = "séparés par des virgules" }),
        },
    },
    lumberjack = {
        points = {
            point("startplace", "Garage : zone d'interaction", { "startplace" }, { radius = { "startplace_radius" }, radiusDefault = 3.0 }),
            point("npc", "Garage : PNJ", { "startplacenpc" }, { heading = { "startplace_npcheading" } }),
            point("return", "Retour du véhicule", { "returnPoint" }, { radius = { "returnPoint_radius" }, radiusDefault = 4.0 }),
            list("trucks", "Emplacements des véhicules", { "truckSpots" }, { heading = "w", ground = true }),
            list("wood", "Arbres à abattre", { "woodSpots" }, { shape = "coords", radius = true }),
            list("process", "Scierie (transformation)", { "processSpots" }, { shape = "coords", radius = true }),
            point("buyer", "Acheteur : PNJ", { "buyer", "buyerLocation" }, { heading = { "buyer", "buyerHeading" } }),
        },
        settings = {
            setting("vehicle", "Modèle du véhicule", { "vehicle" }, "model"),
            setting("ped", "Modèle du PNJ du garage", { "pedService" }, "model"),
            setting("buyerPed", "Modèle de l'acheteur", { "buyer", "pedBuyer" }, "model", { scope = "positions" }),
            setting("sell", "Vente d'une planche ($)", { "sellPrice" }, "number", { min = 0, max = 100000 }),
            setting("maxDeposit", "Bûches déposables d'un coup", { "maxDeposit" }, "number", { min = 1, max = 100 }),
            setting("planks", "Planches par bûche", { "planksPerLog" }, "number", { min = 1, max = 20 }),
            setting("chop", "Durée d'abattage (ms)", { "chopDelay" }, "number", { min = 500, max = 120000 }),
            setting("processDelay", "Durée de transformation (ms)", { "processDelay" }, "number", { min = 500, max = 120000 }),
        },
    },
    mineur = {
        points = {
            point("startplace", "Garage : zone d'interaction", { "startplace" }, { radius = { "startplace_radius" }, radiusDefault = 3.0 }),
            point("npc", "Garage : PNJ", { "startplacenpc" }, { heading = { "startplace_npcheading" } }),
            point("return", "Retour du véhicule", { "returnPoint" }, { radius = { "returnPoint_radius" }, radiusDefault = 4.0 }),
            list("trucks", "Emplacements des véhicules", { "truckSpots" }, { heading = "w", ground = true }),
            list("mines", "Rochers à miner", { "mineSpots" }, { radius = true, map = true, prefix = "spot_" }),
            point("clean", "Zone de nettoyage", { "cleanArea" }, { radius = { "cleanArea", "radius" }, radiusDefault = 60.0 }),
            point("buyer", "Acheteur : PNJ", { "buyer" }, { heading = { "buyer", "heading" } }),
        },
        settings = {
            setting("vehicle", "Modèle du véhicule", { "vehicle" }, "model"),
            setting("ped", "Modèle du PNJ du garage", { "pedService" }, "model"),
            setting("buyerPed", "Modèle de l'acheteur", { "buyer", "model" }, "model", { scope = "positions" }),
            setting("mining", "Durée du minage (ms)", { "miningDelay" }, "number", { min = 500, max = 120000 }),
            setting("cleaning", "Durée du nettoyage (ms)", { "cleaningDelay" }, "number", { min = 500, max = 120000 }),
        },
    },
    routier = {
        points = {
            point("startplace", "Dépôt : zone d'interaction", { "startplace" }, { radius = { "startplace_radius" }, radiusDefault = 3.5 }),
            point("npc", "Dépôt : PNJ", { "startplacenpc" }, { heading = { "startplace_npcheading" }, scope = "config" }),
            point("return", "Retour du camion et de la remorque", { "returnPoint" }, { radius = { "returnPoint_radius" }, radiusDefault = 5.0 }),
            point("returnTruck", "Retour du camion seul", { "returnTruckPoint" }),
            list("trucks", "Emplacements des camions", { "truckSpots" }, { heading = "w", ground = true }),
            list("trailers", "Emplacements des remorques", { "trailerSpots" }, { heading = "w", ground = true }),
            list("deliveries", "Points de livraison", { "deliveryPoints" }, { radius = true }),
        },
        settings = {
            setting("truck", "Modèle du camion", { "truckVehicle" }, "model"),
            setting("trailer", "Modèle de la remorque", { "trailerVehicle" }, "model"),
            setting("ped", "Modèle du PNJ du dépôt", { "pedService" }, "model"),
            setting("reward", "Paiement d'une livraison ($)", { "reward" }, "number", { min = 0, max = 1000000 }),
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Lecture / écriture
-- ═══════════════════════════════════════════════════════════════

local function scopeOf(field) return field.scope or "positions" end

local function loadRoot(job, scope)
    local source
    if scope == "config" then source = InterimServer.GetConfig(job) else source = InterimServer.GetPositions(job) end
    return deepCopy(source or {})
end

local function saveRoot(job, scope, root)
    if scope == "config" then return InterimServer.SaveConfig(job, root) end
    return InterimServer.SavePositions(job, root)
end

local function validPos(p)
    if type(p) ~= "table" then return nil end
    local x, y, z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
    if not (x and y and z) then return nil end
    if math.abs(x) > 10000 or math.abs(y) > 10000 or z < -500 or z > 3000 then return nil end
    local h = tonumber(p.h)
    if h then h = h % 360 end
    return { x = round(x), y = round(y), z = round(z), h = h and round(h) or nil }
end

local function findField(job, kind, id)
    local schema = SCHEMA[job]
    if not schema then return nil end
    local group = kind == "setting" and schema.settings or schema.points
    for i = 1, #group do
        if group[i].id == id then return group[i] end
    end
    return nil
end

local function mapKeys(table_, prefix)
    local keys = {}
    for k in pairs(table_ or {}) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        local na, nb = tonumber(tostring(a):match("(%d+)$")), tonumber(tostring(b):match("(%d+)$"))
        if na and nb and na ~= nb then return na < nb end
        return tostring(a) < tostring(b)
    end)
    return keys
end

--- Les entrées d'une liste : { ref = indice ou clef, entry = table }.
local function entriesOf(root, field)
    local container = getAt(root, field.path)
    local out = {}
    if type(container) ~= "table" then return out end
    if field.map then
        for _, key in ipairs(mapKeys(container, field.prefix)) do
            if type(container[key]) == "table" then out[#out + 1] = { ref = key, entry = container[key] } end
        end
    else
        for i = 1, #container do
            if type(container[i]) == "table" then out[#out + 1] = { ref = i, entry = container[i] } end
        end
    end
    return out
end

local function entryPos(field, entry)
    if field.shape == "coords" then return type(entry.coords) == "table" and entry.coords or {} end
    return entry
end

local function describePoint(root, field)
    local value = getAt(root, field.path)
    local out = { id = field.id, label = field.label, kind = "point" }
    if type(value) == "table" and tonumber(value.x) then
        out.value = { x = round(value.x), y = round(value.y), z = round(value.z) }
    end
    if field.heading then
        local h = tonumber(getAt(root, field.heading))
        out.heading = h and round(h) or nil
        out.hasHeading = true
    end
    if field.radius then
        local r = tonumber(getAt(root, field.radius))
        out.radius = r or field.radiusDefault
        out.hasRadius = true
    end
    return out
end

local function describeList(root, field)
    local out = { id = field.id, label = field.label, kind = "list", hasHeading = field.heading ~= nil, hasRadius = field.radius == true, entries = {} }
    for _, item in ipairs(entriesOf(root, field)) do
        local p = entryPos(field, item.entry)
        out.entries[#out.entries + 1] = {
            ref = item.ref,
            x = round(p.x), y = round(p.y), z = round(p.z),
            heading = field.heading and tonumber(item.entry[field.heading]) and round(item.entry[field.heading]) or nil,
            radius = field.radius and (tonumber(item.entry.radius) or 0) or nil,
        }
    end
    return out
end

local function describeSetting(roots, field)
    local root = roots[field.scope]
    local value = getAt(root, field.path)
    if field.type == "models" then
        value = type(value) == "table" and table.concat(value, ", ") or ""
    end
    return { id = field.id, label = field.label, type = field.type, min = field.min, max = field.max, hint = field.hint, value = value }
end

local function jobRow(row)
    local meta = VFW.DB.Decode(row.meta, {})
    if type(meta) ~= "table" then meta = {} end
    return {
        id = row.id,
        label = row.label or row.id,
        description = row.description or "",
        image = row.image or "",
        enabled = VFW.DB.IsSet(row.enabled),
        order = tonumber(row.sort_order) or 0,
        meta = {
            hours = meta.hours or "",
            zone = meta.zone or "",
            vehicle = meta.vehicle or "",
            requirements = meta.requirements or "",
        },
    }
end

local function jobsList()
    local rows = MySQL.query.await("SELECT * FROM interim_jobs ORDER BY `sort_order` ASC, `id` ASC") or {}
    local out = {}
    for i = 1, #rows do
        local job = jobRow(rows[i])
        local schema = SCHEMA[job.id]
        job.managed = schema ~= nil
        if schema then
            local roots = { positions = loadRoot(job.id, "positions"), config = loadRoot(job.id, "config") }
            local set, total = 0, #schema.points
            for _, field in ipairs(schema.points) do
                local root = roots[scopeOf(field)]
                if field.kind == "point" then
                    local v = getAt(root, field.path)
                    if type(v) == "table" and tonumber(v.x) then set = set + 1 end
                elseif #entriesOf(root, field) > 0 then
                    set = set + 1
                end
            end
            job.points = { set = set, total = total }
        end
        out[#out + 1] = job
    end
    return out
end

local function centerList()
    local rows = MySQL.query.await("SELECT * FROM interim_jobs_center ORDER BY `id` ASC") or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = row.id,
            model = row.model,
            x = round(row.x), y = round(row.y), z = round(row.z),
            heading = round(row.heading),
            label = row.label or "",
            blipEnabled = VFW.DB.IsSet(row.blip_enabled),
            blipName = row.blip_name or "",
        }
    end
    return out
end

local function overview()
    return { ok = true, jobs = jobsList(), center = centerList() }
end

local function jobData(jobId)
    local schema = SCHEMA[jobId]
    local row = MySQL.single.await("SELECT * FROM interim_jobs WHERE `id` = ?", { jobId })
    if not row then return fail("Métier introuvable.") end
    local roots = { positions = loadRoot(jobId, "positions"), config = loadRoot(jobId, "config") }

    local points, settings = {}, {}
    if schema then
        for _, field in ipairs(schema.points) do
            local root = roots[scopeOf(field)]
            if field.kind == "point" then
                points[#points + 1] = describePoint(root, field)
            else
                points[#points + 1] = describeList(root, field)
            end
        end
        for _, field in ipairs(schema.settings) do
            settings[#settings + 1] = describeSetting(roots, field)
        end
    end
    return { ok = true, job = jobRow(row), points = points, settings = settings, managed = schema ~= nil }
end

-- ═══════════════════════════════════════════════════════════════
-- Actions
-- ═══════════════════════════════════════════════════════════════

local function log(source, action, payload)
    TriggerEvent("vfw:logs:staff", source, "interim_admin", { action = action, data = payload })
end

local function cleanText(value, max)
    if type(value) ~= "string" then return nil end
    value = value:gsub("[%c]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if #value > max then value = value:sub(1, max) end
    return value
end

local function cleanImage(value)
    if value == nil then return "" end
    if type(value) ~= "string" then return nil end
    value = value:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("^[\"']", ""):gsub("[\"']$", "")
    if value == "" then return "" end
    if value:match("^r2%.fivemanage%.com/") or value:match("^[%w%-]+%.fivemanage%.com/") or value:match("^[%w%-]+%.fmfile%.com/") then
        value = "https://" .. value
    end
    if #value > 1024 then return nil end
    return value
end

local function cleanModel(value)
    if type(value) ~= "string" then return nil end
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" or #value > 60 or not value:match("^[%w_%-]+$") then return nil end
    return value
end

local ACTIONS = {}

function ACTIONS.overview() return overview() end

function ACTIONS.job(_, a) return jobData(type(a.id) == "string" and a.id or "") end

function ACTIONS.saveJob(source, a)
    local id = type(a.id) == "string" and a.id or ""
    local row = MySQL.single.await("SELECT * FROM interim_jobs WHERE `id` = ?", { id })
    if not row then return fail("Métier introuvable.") end

    local label = cleanText(a.label, 100)
    if not label or label == "" then return fail("Le nom du métier ne peut pas être vide.") end
    local description = cleanText(a.description, 500) or ""
    local image = cleanImage(a.image)
    if not image then return fail("Image invalide (1024 caractères au plus).") end

    local meta = type(a.meta) == "table" and a.meta or {}
    local stored = VFW.DB.Decode(row.meta, {})
    if type(stored) ~= "table" then stored = {} end
    for _, key in ipairs({ "hours", "zone", "vehicle", "requirements" }) do
        if meta[key] ~= nil then stored[key] = cleanText(meta[key], 80) or "" end
    end

    MySQL.update.await(
        "UPDATE interim_jobs SET `label` = ?, `description` = ?, `image` = ?, `meta` = ?, `enabled` = ? WHERE `id` = ?",
        { label, description, image, json.encode(stored), a.enabled == false and 0 or 1, id }
    )
    log(source, "saveJob", { job = id, enabled = a.enabled ~= false })
    return jobData(id)
end

--- Pose un point simple.
function ACTIONS.setPoint(source, a)
    local field = findField(a.job, "point", a.field)
    if not field or field.kind ~= "point" then return fail("Point inconnu.") end
    local pos = validPos(a.pos)
    if not pos then return fail("Position invalide.") end

    local scope = scopeOf(field)
    local root = loadRoot(a.job, scope)
    local value = getAt(root, field.path)
    if type(value) ~= "table" then value = {} end
    value.x, value.y, value.z = pos.x, pos.y, pos.z
    setAt(root, field.path, value)
    if field.heading and pos.h then setAt(root, field.heading, pos.h) end

    if not saveRoot(a.job, scope, root) then return fail("Enregistrement impossible.") end
    log(source, "setPoint", { job = a.job, field = a.field })
    return jobData(a.job)
end

--- Rayon ou cap d'un point simple.
function ACTIONS.setNumber(source, a)
    local field = findField(a.job, "point", a.field)
    if not field or field.kind ~= "point" then return fail("Point inconnu.") end
    local value = tonumber(a.value)
    if not value then return fail("Valeur invalide.") end

    local path
    if a.what == "radius" and field.radius then
        if value < 0.5 or value > 500 then return fail("Rayon entre 0,5 et 500 m.") end
        path = field.radius
    elseif a.what == "heading" and field.heading then
        value = value % 360
        path = field.heading
    else
        return fail("Réglage inconnu.")
    end

    local scope = scopeOf(field)
    local root = loadRoot(a.job, scope)
    setAt(root, path, round(value))
    if not saveRoot(a.job, scope, root) then return fail("Enregistrement impossible.") end
    return jobData(a.job)
end

local function entryFor(root, field, ref)
    for _, item in ipairs(entriesOf(root, field)) do
        if tostring(item.ref) == tostring(ref) then return item end
    end
    return nil
end

local function writeEntryPos(field, entry, pos)
    local z = field.ground and (pos.z - 0.99) or pos.z
    if field.shape == "coords" then
        entry.coords = { x = pos.x, y = pos.y, z = round(z) }
    else
        entry.x, entry.y, entry.z = pos.x, pos.y, round(z)
    end
    if field.heading and pos.h then entry[field.heading] = pos.h end
end

function ACTIONS.addEntry(source, a)
    local field = findField(a.job, "point", a.field)
    if not field or field.kind ~= "list" then return fail("Liste inconnue.") end
    local pos = validPos(a.pos)
    if not pos then return fail("Position invalide.") end

    local scope = scopeOf(field)
    local root = loadRoot(a.job, scope)
    local container = getAt(root, field.path)
    if type(container) ~= "table" then
        container = {}
        setAt(root, field.path, container)
    end

    local entry = {}
    if field.radius then entry.radius = 2.0 end
    if field.id == "deliveries" and a.job == "routier" then entry.radius = 10.0 end
    if field.id == "mines" then entry.radius = 2.0 end
    writeEntryPos(field, entry, pos)

    if field.map then
        local n = #mapKeys(container, field.prefix) + 1
        local key = field.prefix .. n
        while container[key] ~= nil do
            n = n + 1
            key = field.prefix .. n
        end
        container[key] = entry
    else
        if #container >= 100 then return fail("Cent points au plus dans cette liste.") end
        container[#container + 1] = entry
    end

    if not saveRoot(a.job, scope, root) then return fail("Enregistrement impossible.") end
    log(source, "addEntry", { job = a.job, field = a.field })
    return jobData(a.job)
end

function ACTIONS.setEntry(source, a)
    local field = findField(a.job, "point", a.field)
    if not field or field.kind ~= "list" then return fail("Liste inconnue.") end
    local pos = validPos(a.pos)
    if not pos then return fail("Position invalide.") end

    local scope = scopeOf(field)
    local root = loadRoot(a.job, scope)
    local item = entryFor(root, field, a.ref)
    if not item then return fail("Point introuvable.") end
    writeEntryPos(field, item.entry, pos)

    if not saveRoot(a.job, scope, root) then return fail("Enregistrement impossible.") end
    log(source, "setEntry", { job = a.job, field = a.field, ref = a.ref })
    return jobData(a.job)
end

function ACTIONS.setEntryNumber(source, a)
    local field = findField(a.job, "point", a.field)
    if not field or field.kind ~= "list" then return fail("Liste inconnue.") end
    local value = tonumber(a.value)
    if not value then return fail("Valeur invalide.") end

    local key
    if a.what == "radius" and field.radius then
        if value < 0.5 or value > 500 then return fail("Rayon entre 0,5 et 500 m.") end
        key = "radius"
    elseif a.what == "heading" and field.heading then
        value = value % 360
        key = field.heading
    else
        return fail("Réglage inconnu.")
    end

    local scope = scopeOf(field)
    local root = loadRoot(a.job, scope)
    local item = entryFor(root, field, a.ref)
    if not item then return fail("Point introuvable.") end
    item.entry[key] = round(value)

    if not saveRoot(a.job, scope, root) then return fail("Enregistrement impossible.") end
    return jobData(a.job)
end

function ACTIONS.removeEntry(source, a)
    local field = findField(a.job, "point", a.field)
    if not field or field.kind ~= "list" then return fail("Liste inconnue.") end

    local scope = scopeOf(field)
    local root = loadRoot(a.job, scope)
    local item = entryFor(root, field, a.ref)
    if not item then return fail("Point introuvable.") end
    local container = getAt(root, field.path)
    if field.map then container[item.ref] = nil else table.remove(container, item.ref) end

    if not saveRoot(a.job, scope, root) then return fail("Enregistrement impossible.") end
    log(source, "removeEntry", { job = a.job, field = a.field, ref = a.ref })
    return jobData(a.job)
end

function ACTIONS.saveSettings(source, a)
    local schema = SCHEMA[a.job]
    if not schema then return fail("Métier inconnu.") end
    local values = type(a.values) == "table" and a.values or {}

    local roots, dirty = { positions = loadRoot(a.job, "positions"), config = loadRoot(a.job, "config") }, {}
    for _, field in ipairs(schema.settings) do
        local raw = values[field.id]
        if raw ~= nil then
            local value
            if field.type == "number" then
                value = tonumber(raw)
                if not value or value < (field.min or -math.huge) or value > (field.max or math.huge) then
                    return fail(("%s : valeur entre %s et %s."):format(field.label, tostring(field.min), tostring(field.max)))
                end
                value = math.floor(value)
            elseif field.type == "model" then
                value = cleanModel(raw)
                if not value then return fail(("%s : nom de modèle invalide (lettres, chiffres et _)."):format(field.label)) end
            else
                value = {}
                for model in tostring(raw):gmatch("[^,]+") do
                    local clean = cleanModel(model)
                    if clean then value[#value + 1] = clean end
                    if #value >= 30 then break end
                end
                if #value == 0 then return fail(("%s : au moins un modèle."):format(field.label)) end
            end
            setAt(roots[field.scope], field.path, value)
            dirty[field.scope] = true
        end
    end

    for scope in pairs(dirty) do
        if not saveRoot(a.job, scope, roots[scope]) then return fail("Enregistrement impossible.") end
    end
    log(source, "saveSettings", { job = a.job })
    return jobData(a.job)
end

-- ── centre d'emploi ──

function ACTIONS.centerAdd(source, a)
    local pos = validPos(a.pos)
    if not pos then return fail("Position invalide.") end
    local count = MySQL.single.await("SELECT COUNT(*) AS n FROM interim_jobs_center")
    if count and tonumber(count.n) and tonumber(count.n) >= 10 then return fail("Dix centres d'emploi au plus.") end
    MySQL.insert.await([[
        INSERT INTO interim_jobs_center (`model`, `x`, `y`, `z`, `heading`, `label`, `blip_enabled`, `blip_sprite`, `blip_scale`, `blip_color`, `blip_name`)
        VALUES (?, ?, ?, ?, ?, ?, 1, 351, 0.5, 5, ?)
    ]], { "s_f_y_scrubs_01", pos.x, pos.y, pos.z, pos.h or 0.0, "Appuyez sur ~INPUT_CONTEXT~ pour consulter les offres d'intérim", "Centre d'intérim" })
    log(source, "centerAdd", {})
    return overview()
end

function ACTIONS.centerSet(source, a)
    local pos = validPos(a.pos)
    if not pos then return fail("Position invalide.") end
    local id = math.floor(tonumber(a.id) or 0)
    local row = MySQL.single.await("SELECT `id` FROM interim_jobs_center WHERE `id` = ?", { id })
    if not row then return fail("Centre introuvable.") end
    MySQL.update.await("UPDATE interim_jobs_center SET `x` = ?, `y` = ?, `z` = ?, `heading` = ? WHERE `id` = ?", { pos.x, pos.y, pos.z, pos.h or 0.0, id })
    log(source, "centerSet", { id = id })
    return overview()
end

function ACTIONS.centerSave(source, a)
    local id = math.floor(tonumber(a.id) or 0)
    local row = MySQL.single.await("SELECT `id` FROM interim_jobs_center WHERE `id` = ?", { id })
    if not row then return fail("Centre introuvable.") end
    local model = cleanModel(a.model)
    if not model then return fail("Modèle du PNJ invalide (lettres, chiffres et _).") end
    local label = cleanText(a.label, 100) or ""
    local blipName = cleanText(a.blipName, 100) or ""
    MySQL.update.await(
        "UPDATE interim_jobs_center SET `model` = ?, `label` = ?, `blip_enabled` = ?, `blip_name` = ? WHERE `id` = ?",
        { model, label, a.blipEnabled == false and 0 or 1, blipName, id }
    )
    log(source, "centerSave", { id = id })
    return overview()
end

function ACTIONS.centerDelete(source, a)
    local id = math.floor(tonumber(a.id) or 0)
    MySQL.update.await("DELETE FROM interim_jobs_center WHERE `id` = ?", { id })
    log(source, "centerDelete", { id = id })
    return overview()
end

RegisterServerCallback("gestion:interim:do", function(source, action, args)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(action) ~= "string" then return fail("Action inconnue.") end
    local handler = ACTIONS[action]
    if not handler then return fail("Action inconnue.") end
    local ok, result = pcall(handler, source, type(args) == "table" and args or {})
    if not ok then
        console.warn(("[interim:admin] %s : %s"):format(action, tostring(result)))
        return fail("Erreur interne, voir la console serveur.")
    end
    return result
end)

-- Utilisé par les tests ; sans effet en jeu.
InterimAdminPanel = { SCHEMA = SCHEMA }
