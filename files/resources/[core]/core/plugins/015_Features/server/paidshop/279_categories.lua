Feat27 = Feat27 or {}
PaidShop = PaidShop or {}

-- Gestion des rayons de la boutique depuis le mode édition : créer, renommer, changer l'icône, réordonner,
-- masquer (adminSetCategoryEnabled) et supprimer. Les rayons d'origine viennent de config/paidshop.lua ; ce que
-- l'administrateur change est gardé dans paidshop_settings (clé « categories_custom ») et réappliqué au
-- démarrage par-dessus la config :
--   { [id] = { label, icon, order, deleted = true, custom = true, itemType } }

local SETTING = "categories_custom"
local MAX_LABEL = 28
local MAX_CUSTOM = 30

-- Rayons qu'on ne supprime pas : « Pour moi » et le VIP ont leur propre mécanique, et les récompenses
-- quotidiennes vivent dans une pseudo-catégorie qui n'est pas un rayon. On peut les masquer.
local PROTECTED = { vip = true, pour_moi = true, daily_reward = true }

-- Ce que vend un rayon créé par l'admin ; décide comment l'achat est livré et ce que la fiche demande.
local TYPES = {
    consumable = { purchaseHandler = "buyItem", maxQuantity = 10, allowRefund = true },
    weapon = { purchaseHandler = "buyItem", maxQuantity = nil, allowRefund = true },
    vehicle = { purchaseHandler = "buyVehicle", maxQuantity = 1, allowRefund = true, requiresPreview = true },
    pack = { purchaseHandler = "buyItem", maxQuantity = 1, allowRefund = true, autoGenerateSpawnName = true },
    case = { purchaseHandler = "buyItem", maxQuantity = 5, allowRefund = false, autoGenerateSpawnName = true },
    ped = { purchaseHandler = "buyItem", maxQuantity = 1, allowRefund = true },
}

local function adminOf(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not PaidShop.IsAdmin(xPlayer) then return nil end
    return xPlayer
end

local function loadMap()
    local row = MySQL.single.await("SELECT `svalue` FROM paidshop_settings WHERE `skey` = ?", { SETTING })
    local value = row and row.svalue and row.svalue ~= "" and PaidShop.Decode(row.svalue, {}) or {}
    return type(value) == "table" and value or {}
end

local function saveMap(map)
    MySQL.query.await([[
        INSERT INTO paidshop_settings (`skey`, `svalue`) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)
    ]], { SETTING, json.encode(map) })
end

local function cut(text, max)
    local length = utf8.len(text)
    if not length then return text:sub(1, max) end
    if length <= max then return text end
    return text:sub(1, utf8.offset(text, max + 1) - 1)
end

local function cleanLabel(value)
    if type(value) ~= "string" then return nil end
    value = value:gsub("%c", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    if value == "" then return nil end
    return cut(value, MAX_LABEL)
end

local function cleanIcon(value)
    if type(value) ~= "string" then return nil end
    if #value > 40 or not value:match("^fa%-[%a%d%-]+$") then return nil end
    return value
end

local function categoryConfig(id)
    if id == "vip" then return PaidShopConfig.VIPCategory end
    return PaidShopConfig.ConfigurableCategories[id]
end

--- Pose ce que l'admin a choisi sur la config en mémoire (et crée le rayon s'il vient de lui).
local function applyEntry(id, entry)
    if type(id) ~= "string" or type(entry) ~= "table" then return nil end
    local cfg = categoryConfig(id)
    if not cfg and entry.custom and TYPES[entry.itemType] then
        cfg = { enabled = true, adminOnly = false, itemType = entry.itemType, requiresPreview = false, customFields = {} }
        for key, value in pairs(TYPES[entry.itemType]) do cfg[key] = value end
        PaidShopConfig.ConfigurableCategories[id] = cfg
    end
    if not cfg then return nil end
    if type(entry.label) == "string" then cfg.label = entry.label end
    if type(entry.icon) == "string" then cfg.icon = entry.icon end
    if tonumber(entry.order) then cfg.order = tonumber(entry.order) end
    cfg.removed = entry.deleted == true or nil
    cfg.custom = entry.custom == true or nil
    return cfg
end

local function rebuild()
    if PaidShopConfig.RebuildCategoriesList then PaidShopConfig.RebuildCategoriesList() end
end

--- Tous les rayons pour le panneau d'administration (les supprimés d'origine y sont, pour pouvoir les restaurer).
function PaidShop.ListCategories()
    local counts = {}
    local rows = MySQL.query.await("SELECT `category`, COUNT(*) AS total FROM paidshop_items WHERE `enabled` = 1 GROUP BY `category`") or {}
    for i = 1, #rows do counts[rows[i].category] = tonumber(rows[i].total) or 0 end

    local out = {}
    local function add(id, cfg)
        if id == "daily_reward" then return end
        out[#out + 1] = {
            id = id,
            label = cfg.label or id,
            icon = cfg.icon,
            enabled = cfg.enabled ~= false,
            order = cfg.order or 100,
            itemType = cfg.itemType,
            custom = cfg.custom == true,
            protected = PROTECTED[id] == true,
            removed = cfg.removed == true,
            itemCount = counts[id] or 0,
        }
    end
    for id, cfg in pairs(PaidShopConfig.ConfigurableCategories) do add(id, cfg) end
    add("vip", PaidShopConfig.VIPCategory)
    table.sort(out, function(a, b)
        if (a.order or 100) ~= (b.order or 100) then return (a.order or 100) < (b.order or 100) end
        return a.id < b.id
    end)
    return out
end

local function nextOrder()
    local last = 0
    for id, cfg in pairs(PaidShopConfig.ConfigurableCategories) do
        if not cfg.removed and id ~= "daily_reward" and (tonumber(cfg.order) or 0) > last then last = tonumber(cfg.order) end
    end
    return last + 1
end

local function newId(label)
    local base = label:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if base == "" then base = "rayon" end
    base = "rayon_" .. base:sub(1, 24)
    local id, n = base, 1
    while categoryConfig(id) do
        n = n + 1
        id = base .. "_" .. n
    end
    return id
end

--- Crée (id vide) ou modifie un rayon : nom et icône ; le type de ce qu'il vend se choisit à la création.
RegisterServerCallback("paidshop:adminSaveCategory", function(source, id, data)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(data) ~= "table" then return false, "Cette demande n'a pas pu être traitée" end
    if not Feat27.RateLimit(source, "paidshop:category", 300) then return false, "Veuillez patienter" end

    local label = cleanLabel(data.label)
    if not label then return false, "Le nom du rayon ne peut pas être vide" end
    local icon = cleanIcon(data.icon) or "fa-tag"

    local map = loadMap()
    if id == nil or id == "" then
        if not TYPES[data.itemType] then return false, "Choisis ce que vend ce rayon" end
        local custom = 0
        for _, entry in pairs(map) do if entry.custom then custom = custom + 1 end end
        if custom >= MAX_CUSTOM then return false, ("Tu as déjà %d rayons ajoutés, c'est le maximum"):format(MAX_CUSTOM) end

        local created = newId(label)
        map[created] = { custom = true, itemType = data.itemType, label = label, icon = icon, order = nextOrder() }
        applyEntry(created, map[created])
        saveMap(map)
        rebuild()
        return true, "Rayon créé", created
    end

    if type(id) ~= "string" then return false, "Rayon inconnu" end
    local cfg = categoryConfig(id)
    if not cfg or cfg.removed then return false, "Rayon inconnu" end

    local entry = map[id] or {}
    entry.label = label
    entry.icon = icon
    map[id] = entry
    applyEntry(id, entry)
    saveMap(map)
    rebuild()
    return true, "Rayon modifié", id
end)

--- Nouvel ordre des rayons : `ids` dans l'ordre voulu (ceux qu'on ne cite pas gardent leur place).
RegisterServerCallback("paidshop:adminReorderCategories", function(source, ids)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(ids) ~= "table" then return false, "Cette demande n'a pas pu être traitée" end
    if not Feat27.RateLimit(source, "paidshop:category", 300) then return false, "Veuillez patienter" end

    local map = loadMap()
    local position = 0
    local seen = {}
    for i = 1, math.min(#ids, 60) do
        local id = ids[i]
        local cfg = type(id) == "string" and not seen[id] and categoryConfig(id) or nil
        if cfg and not cfg.removed then
            seen[id] = true
            position = position + 1
            local entry = map[id] or {}
            entry.order = position * 10
            map[id] = entry
            applyEntry(id, entry)
        end
    end
    if position == 0 then return false, "Rien à ranger" end
    saveMap(map)
    rebuild()
    return true, "Ordre enregistré"
end)

--- Supprime un rayon et ses articles. Refusé tant que des joueurs ont un achat de ce rayon à récupérer :
--- sans l'article, l'achat ne pourrait plus leur être livré. Dans ce cas on masque le rayon.
RegisterServerCallback("paidshop:adminDeleteCategory", function(source, id)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(id) ~= "string" then return false, "Rayon inconnu" end
    if PROTECTED[id] then return false, "Ce rayon est indispensable : tu peux le masquer, pas le supprimer" end
    local cfg = categoryConfig(id)
    if not cfg or cfg.removed then return false, "Rayon inconnu" end
    if not Feat27.RateLimit(source, "paidshop:category", 300) then return false, "Veuillez patienter" end

    local waiting = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM paidshop_pending_items WHERE `category` = ? AND `status` = 'pending'", { id })) or 0
    if waiting > 0 then
        return false, ("%d achat(s) de ce rayon attendent d'être récupérés par des joueurs : masque le rayon pour l'instant"):format(waiting)
    end

    MySQL.query.await("DELETE FROM paidshop_items WHERE `category` = ?", { id })

    local map = loadMap()
    if cfg.custom then
        map[id] = nil
        PaidShopConfig.ConfigurableCategories[id] = nil
    else
        local entry = map[id] or {}
        entry.deleted = true
        map[id] = entry
        applyEntry(id, entry)
    end
    saveMap(map)
    rebuild()
    PaidShop.LoadItems(true)
    return true, "Rayon supprimé"
end)

--- Remet un rayon d'origine supprimé (vide : ses articles ont été supprimés avec lui).
RegisterServerCallback("paidshop:adminRestoreCategory", function(source, id)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(id) ~= "string" then return false, "Rayon inconnu" end
    local cfg = categoryConfig(id)
    if not cfg or not cfg.removed then return false, "Ce rayon n'est pas supprimé" end

    local map = loadMap()
    local entry = map[id] or {}
    entry.deleted = nil
    map[id] = entry
    applyEntry(id, entry)
    cfg.enabled = true
    saveMap(map)
    rebuild()
    return true, "Rayon restauré"
end)

CreateThread(function()
    -- après 277_admin_hub, qui crée paidshop_settings et applique la visibilité des rayons
    Wait(900)
    local map = loadMap()
    for id, entry in pairs(map) do applyEntry(id, entry) end

    -- la visibilité d'un rayon créé n'a pas pu être appliquée plus tôt : il n'existait pas encore
    local row = MySQL.single.await("SELECT `svalue` FROM paidshop_settings WHERE `skey` = ?", { "categories_enabled" })
    local flags = row and row.svalue and row.svalue ~= "" and PaidShop.Decode(row.svalue, {}) or {}
    if type(flags) == "table" then
        for id, enabled in pairs(flags) do
            local cfg = categoryConfig(id)
            if cfg and cfg.custom then cfg.enabled = enabled and true or false end
        end
    end
    rebuild()
end)
