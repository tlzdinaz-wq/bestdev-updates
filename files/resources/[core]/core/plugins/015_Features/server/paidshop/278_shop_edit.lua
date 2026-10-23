Feat27 = Feat27 or {}
PaidShop = PaidShop or {}

-- Mode édition de la boutique (interface/boutique) : modifier un article à la volée (image, prix,
-- nom, promo, description, rareté, étiquettes, contenu d'un pack, lots d'une caisse) et chercher
-- l'objet à vendre. Toutes les autres actions d'administration (ajout, suppression, coins, offrir,
-- récompenses quotidiennes, scanner, pool « Pour moi », catégories) existent déjà dans
-- 272_admin.lua et 277_admin_hub.lua : la boutique les appelle telles quelles.

local MAX_PRICE = 10000000
local MAX_LIST = 60

local RARITIES = { common = true, uncommon = true, rare = true, epic = true, legendary = true }

local function adminOf(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not PaidShop.IsAdmin(xPlayer) then return nil end
    return xPlayer
end

--- Texte propre : une chaîne, sans caractère de contrôle, rognée.
---@return string|nil
local function cleanText(value, max)
    if type(value) ~= "string" then return nil end
    value = value:gsub("[%c]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if #value > max then value = value:sub(1, max) end
    return value
end

--- Image d'un article : lien https, image intégrée, ou chemin du CDN (complété avec le CDN du serveur).
--- La colonne fait 500 caractères : un lien plus long serait refusé par la base, autant le dire.
---@return string|nil image, string|nil err
local function cleanImage(value)
    if value == nil then return "" end
    if type(value) ~= "string" then return nil, "Image invalide." end
    value = value:gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return "" end

    local lower = value:lower()
    local out
    if lower:match("^https?://") or lower:match("^data:image/") then
        out = value
    elseif lower:match("^[%w%-%.]+%.[%a]+/") then
        -- r2.fivemanage.com/...  (collé sans https://)
        out = "https://" .. value
    elseif value:match("^[%w_%-%./]+$") and not value:find("..", 1, true) then
        out = (VFW.CdnUrl and VFW.CdnUrl(value)) or nil
        if not out then return nil, "Chemin d'image inconnu : colle un lien complet." end
    else
        return nil, "Image invalide : colle un lien https."
    end

    if #out > 500 then return nil, "Lien trop long (500 caractères au plus)." end
    return out
end

local function cleanTags(value)
    if type(value) ~= "table" then return nil end
    local out = {}
    for i = 1, #value do
        local tag = cleanText(value[i], 24)
        if tag and tag ~= "" then out[#out + 1] = tag end
        if #out >= 8 then break end
    end
    return out
end

local function cleanCount(value)
    local n = math.floor(tonumber(value) or 1)
    if n < 1 then n = 1 end
    if n > 9999 then n = 9999 end
    return n
end

--- Contenu d'un pack : liste plate { item, count, label }, le seul format que la remise du pack
--- (271_purchase.lua) sait donner.
local function cleanPackContent(value)
    if type(value) ~= "table" then return nil end
    local out = {}
    for i = 1, #value do
        local entry = value[i]
        if type(entry) == "table" then
            local item = cleanText(entry.item, 100)
            if item and item ~= "" then
                out[#out + 1] = {
                    item = item,
                    count = cleanCount(entry.count),
                    label = cleanText(entry.label, 80) or item,
                }
            end
        end
        if #out >= MAX_LIST then break end
    end
    return out
end

--- Lots d'une caisse. La pioche (274_cases.lua) tire au hasard selon `weight` (entier) : on écrit donc
--- aussi `weight` à partir de la chance, sinon tous les lots auraient la même.
local function cleanPrizes(value)
    if type(value) ~= "table" then return nil end
    local out = {}
    for i = 1, #value do
        local entry = value[i]
        if type(entry) == "table" then
            local spawnName = cleanText(entry.spawnName or entry.item, 100)
            if spawnName and spawnName ~= "" then
                local chance = tonumber(entry.chance) or 10
                if chance < 0.1 then chance = 0.1 end
                if chance > 100 then chance = 100 end
                local image = cleanImage(entry.image)
                out[#out + 1] = {
                    name = cleanText(entry.name, 80) or spawnName,
                    type = "item",
                    spawnName = spawnName,
                    image = image or "",
                    rarity = RARITIES[entry.rarity] and entry.rarity or "common",
                    count = cleanCount(entry.count),
                    chance = chance,
                    weight = math.max(1, math.floor(chance * 10 + 0.5)),
                }
            end
        end
        if #out >= MAX_LIST then break end
    end
    return out
end

local function cleanLines(value, maxLines, maxLen)
    if type(value) ~= "table" then return nil end
    local out = {}
    for i = 1, #value do
        local line = cleanText(value[i], maxLen)
        if line and line ~= "" then out[#out + 1] = line end
        if #out >= maxLines then break end
    end
    return out
end

--- Modifie quelques champs d'un article sans toucher aux autres (contrairement à editItemServer, qui
--- réécrit toute la ligne). `patch` ne contient que ce qui change.
---   colonnes : name, price, originalPrice, image, description, rarity, tags, content
---   extra    : tebexUrl, advantages, vipTier, possible_items
RegisterServerCallback("paidshop:quickEditItem", function(source, category, spawnName, patch)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(category) ~= "string" or type(spawnName) ~= "string" or type(patch) ~= "table" then
        return false, "Cette demande n'a pas pu être traitée"
    end
    if not Feat27.RateLimit(source, "paidshop:quickedit", 150) then return false, "Veuillez patienter" end

    local row = MySQL.single.await("SELECT `id`, `extra` FROM paidshop_items WHERE `category` = ? AND `spawn_name` = ?", { category, spawnName })
    if not row then return false, "Article introuvable" end

    local sets, params = {}, {}
    local function set(column, value)
        sets[#sets + 1] = ("`%s` = ?"):format(column)
        params[#params + 1] = value
    end

    if patch.name ~= nil then
        local name = cleanText(patch.name, 150)
        if not name or name == "" then return false, "Le nom ne peut pas être vide" end
        set("name", name)
    end

    if patch.price ~= nil then
        local price = tonumber(patch.price)
        if not price or price < 0 or price > MAX_PRICE then return false, "Ce prix n'est pas valide" end
        set("price", math.floor(price))
    end

    if patch.originalPrice ~= nil then
        local original = tonumber(patch.originalPrice)
        if not original or original < 0 or original > MAX_PRICE then return false, "Ce prix barré n'est pas valide" end
        set("original_price", math.floor(original))
    end

    if patch.image ~= nil then
        local image, err = cleanImage(patch.image)
        if not image then return false, err end
        set("image", image)
    end

    if patch.description ~= nil then
        local description = cleanText(patch.description, 1000)
        if not description then return false, "Description invalide" end
        set("description", description)
    end

    if patch.rarity ~= nil then
        if not RARITIES[patch.rarity] then return false, "Cette rareté n'existe pas" end
        set("rarity", patch.rarity)
    end

    if patch.tags ~= nil then
        local tags = cleanTags(patch.tags)
        if not tags then return false, "Étiquettes invalides" end
        set("tags", json.encode(tags))
    end

    if patch.content ~= nil then
        local content = cleanPackContent(patch.content)
        if not content then return false, "Contenu invalide" end
        -- NULL en clair : un nil dans la liste des paramètres décalerait tous les suivants.
        if #content > 0 then set("content", json.encode(content)) else sets[#sets + 1] = "`content` = NULL" end
    end

    local extra = PaidShop.Decode(row.extra, {})
    if type(extra) ~= "table" then extra = {} end
    local extraChanged = false

    if patch.tebexUrl ~= nil then
        local url = cleanText(patch.tebexUrl, 300)
        if not url or (url ~= "" and not url:lower():match("^https?://")) then return false, "Lien d'abonnement invalide (https://...)" end
        extra.tebexUrl = url ~= "" and url or nil
        extraChanged = true
    end

    if patch.advantages ~= nil then
        local lines = cleanLines(patch.advantages, 12, 90)
        if not lines then return false, "Avantages invalides" end
        extra.advantages = lines
        extraChanged = true
    end

    if patch.vipTier ~= nil then
        local tier = math.floor(tonumber(patch.vipTier) or -1)
        if tier < 0 or tier > 3 then return false, "Palier VIP invalide (0 à 3)" end
        extra.vipTier = tier
        extraChanged = true
    end

    if patch.possible_items ~= nil then
        local prizes = cleanPrizes(patch.possible_items)
        if not prizes then return false, "Lots invalides" end
        extra.possible_items = prizes
        extraChanged = true
    end

    if extraChanged then set("extra", json.encode(extra)) end
    if #sets == 0 then return false, "Rien à modifier" end

    params[#params + 1] = row.id
    MySQL.update.await(("UPDATE paidshop_items SET %s WHERE `id` = ?"):format(table.concat(sets, ", ")), params)

    PaidShop.LoadItems(true)
    return true, "Enregistré"
end)

local function resolveImage(raw)
    if type(raw) ~= "string" or raw == "" then return "" end
    if raw:match("^https?://") or raw:match("^data:") then return raw end
    if VFW.CdnUrl then return VFW.CdnUrl(raw) end
    return raw
end

--- Cherche l'objet d'inventaire (ou l'arme) à vendre dans une catégorie d'objets.
--- Pour un véhicule ou un animal il n'y a pas de liste : l'interface laisse saisir le modèle.
RegisterServerCallback("paidshop:searchCatalog", function(source, category, query)
    if not adminOf(source) then return {} end
    if type(category) ~= "string" then return {} end

    -- "*" : n'importe quel objet ou arme (contenu d'un pack, lots d'une caisse).
    local kind
    if category == "*" then
        kind = "personal"
    else
        local config = PaidShop.CategoryConfig(category)
        kind = config and config.itemType
    end
    if kind ~= "weapon" and kind ~= "consumable" and kind ~= "personal" then return {} end

    local needle = type(query) == "string" and query:lower():gsub("^%s+", ""):gsub("%s+$", "") or ""
    local out = {}
    for name, def in pairs(VFW.Items or {}) do
        if type(name) == "string" and type(def) == "table" and def.type ~= "clothes" and def.type ~= "outfit" then
            local isWeapon = name:sub(1, 7) == "weapon_"
            if (kind == "weapon") == isWeapon or kind == "personal" then
                local label = tostring(def.label or name)
                if needle == "" or name:lower():find(needle, 1, true) or label:lower():find(needle, 1, true) then
                    out[#out + 1] = { spawnName = name, label = label, image = resolveImage(def.image) }
                end
            end
        end
    end

    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    while #out > 12 do out[#out] = nil end
    return out
end)
