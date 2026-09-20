Feat27 = Feat27 or {}
PaidShop = PaidShop or {}

local function adminOf(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not PaidShop.IsAdmin(xPlayer) then return nil end
    return xPlayer
end

local function getSetting(key, fallback)
    local row = MySQL.single.await("SELECT `svalue` FROM paidshop_settings WHERE `skey` = ?", { key })
    if not row or not row.svalue or row.svalue == "" then return fallback end
    return PaidShop.Decode(row.svalue, fallback)
end

local function setSetting(key, value)
    local encoded = json.encode(value)
    MySQL.query.await([[
        INSERT INTO paidshop_settings (`skey`, `svalue`) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)
    ]], { key, encoded })
end

local function applyCategoryFlags(flags)
    if type(flags) ~= "table" then return end
    for id, enabled in pairs(flags) do
        local cfg = PaidShopConfig and PaidShopConfig.GetCategoryConfig and PaidShopConfig.GetCategoryConfig(id)
        if cfg then cfg.enabled = enabled and true or false end
    end
    if PaidShopConfig and PaidShopConfig.RebuildCategoriesList then
        PaidShopConfig.RebuildCategoriesList()
    end
end

local function applyStreak(slots)
    if type(slots) ~= "table" then return end
    if not PaidShopConfig then return end
    PaidShopConfig.DailyBonus = PaidShopConfig.DailyBonus or {}
    PaidShopConfig.DailyBonus.StreakRewards = slots
end

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `paidshop_settings` (
            `skey` VARCHAR(64) NOT NULL,
            `svalue` LONGTEXT DEFAULT NULL,
            PRIMARY KEY (`skey`)
        )
    ]])
    Wait(500)
    applyCategoryFlags(getSetting("categories_enabled", nil))
    applyStreak(getSetting("daily_streak", nil))
end)

RegisterServerCallback("paidshop:getCoinsAdmin", function(source, targetId)
    if not adminOf(source) then return false, "Non autorisé" end
    local id = tonumber(targetId)
    if not id then return false, "Cet ID n'est pas valide" end

    local target = VFW.GetPlayerFromId(id)
    if target then
        PaidShop.EnsureAccount(target)
        return true, { name = target.name or target.playerName, spacecoins = PaidShop.GetCoins(target), online = true }
    end

    local row = MySQL.single.await("SELECT `identifier`, `spacecoins` FROM paidshop_accounts WHERE `unique_id` = ?", { id })
    if not row then return false, "Joueur introuvable" end
    local coins = math.floor(tonumber(row.spacecoins) or 0)
    local char = MySQL.single.await("SELECT `firstname`, `lastname` FROM characters WHERE `identifier` = ?", { row.identifier })
    local name = char and ((char.firstname or "") .. " " .. (char.lastname or "")):gsub("^%s+", ""):gsub("%s+$", "") or ("ID " .. tostring(id))
    if name == "" then name = "Joueur hors ligne" end
    return true, { name = name, spacecoins = coins, online = false }
end)

RegisterServerCallback("paidshop:giveItemAdmin", function(source, mode, targetValue, spawnName, category, quantity)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(spawnName) ~= "string" or type(category) ~= "string" then return false, "Article invalide" end

    local qty = math.floor(tonumber(quantity) or 1)
    if qty < 1 or qty > 100 then return false, "Cette quantité n'est pas valide (1-100)" end

    local item = PaidShop.FindItem(category, spawnName)
    if not item then return false, "Article introuvable" end

    local identifier
    local xTarget
    if mode == "online" then
        xTarget = VFW.GetPlayerFromId(tonumber(targetValue))
        if not xTarget then return false, "Joueur introuvable" end
        identifier = xTarget.identifier
    else
        local uniqueId = tonumber(targetValue)
        if not uniqueId then return false, "Cet ID boutique n'est pas valide" end
        local row = MySQL.single.await("SELECT `identifier` FROM paidshop_accounts WHERE `unique_id` = ?", { uniqueId })
        if not row then return false, "Aucun joueur avec cet ID boutique" end
        identifier = row.identifier
        xTarget = VFW.GetPlayerFromIdentifier(identifier)
    end

    local pendingId = PaidShop.AddPending(identifier, category, {
        spawnName = item.spawnName,
        name = item.name or item.spawnName,
        image = item.image,
    }, qty, 0)
    if not pendingId then return false, "Attribution impossible" end

    if xTarget then PaidShop.PushPendingCount(xTarget) end
    return true, ("Article offert: %dx %s"):format(qty, item.name or item.spawnName)
end)

RegisterServerCallback("paidshop:getDailyRewards", function(source)
    if not adminOf(source) then return {} end
    local items = PaidShop.LoadItems() or {}
    return items.daily_reward or {}
end)

RegisterServerCallback("paidshop:addDailyReward", function(source, data)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(data) ~= "table" or type(data.name) ~= "string" or data.name == "" then
        return false, "Le nom est requis"
    end
    local rewardType = data.rewardType or "money"
    local extra = {
        isDailyReward = true,
        rewardType = rewardType,
        requiredVipTier = math.floor(tonumber(data.requiredVipTier) or 0),
        cashAmount = data.cashAmount,
        rewardItem = data.rewardItem,
        rewardCount = data.rewardCount,
        rewardVehicle = data.rewardVehicle,
    }
    local spawnName = ("daily_%s_%d"):format(rewardType, math.random(1000, 9999))
    local inserted = pcall(MySQL.insert.await, [[
        INSERT INTO paidshop_items
            (`category`, `spawn_name`, `name`, `price`, `original_price`, `image`, `tags`, `description`, `rarity`, `content`, `extra`, `enabled`)
        VALUES ('daily_reward', ?, ?, 0, 0, ?, '[]', ?, 'common', NULL, ?, 1)
    ]], {
        spawnName, data.name, data.image or "", data.description or "", json.encode(extra),
    })
    if not inserted then return false, "Impossible d'ajouter cette récompense" end
    PaidShop.LoadItems(true)
    return true, "Récompense ajoutée"
end)

RegisterServerCallback("paidshop:editDailyReward", function(source, reward)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(reward) ~= "table" or type(reward.spawnName) ~= "string" then return false, "Récompense invalide" end
    local extra = {
        isDailyReward = true,
        rewardType = reward.rewardType,
        requiredVipTier = math.floor(tonumber(reward.requiredVipTier) or 0),
        cashAmount = reward.cashAmount,
        rewardItem = reward.rewardItem,
        rewardCount = reward.rewardCount,
        rewardVehicle = reward.rewardVehicle,
    }
    MySQL.update.await([[
        UPDATE paidshop_items SET `name` = ?, `image` = ?, `description` = ?, `extra` = ?
        WHERE `category` = 'daily_reward' AND `spawn_name` = ?
    ]], { reward.name, reward.image or "", reward.description or "", json.encode(extra), reward.spawnName })
    PaidShop.LoadItems(true)
    return true, "Récompense modifiée"
end)

RegisterServerCallback("paidshop:deleteDailyReward", function(source, spawnName)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(spawnName) ~= "string" then return false, "Récompense invalide" end
    MySQL.query.await("DELETE FROM paidshop_items WHERE `category` = 'daily_reward' AND `spawn_name` = ?", { spawnName })
    PaidShop.LoadItems(true)
    return true, "Récompense supprimée"
end)

RegisterServerCallback("paidshop:adminGetAllCategories", function(source)
    if not adminOf(source) then return false, {} end
    local out = {}
    if PaidShopConfig and PaidShopConfig.ConfigurableCategories then
        for id, cfg in pairs(PaidShopConfig.ConfigurableCategories) do
            out[#out + 1] = { id = id, label = cfg.label or id, enabled = cfg.enabled ~= false, order = cfg.order or 100 }
        end
    end
    if PaidShopConfig and PaidShopConfig.VIPCategory then
        local cfg = PaidShopConfig.VIPCategory
        out[#out + 1] = { id = "vip", label = cfg.label or "VIP", enabled = cfg.enabled ~= false, order = cfg.order or 999 }
    end
    table.sort(out, function(a, b) return (a.order or 100) < (b.order or 100) end)
    return true, out
end)

RegisterServerCallback("paidshop:adminSetCategoryEnabled", function(source, categoryId, enabled)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(categoryId) ~= "string" then return false, "Catégorie inconnue" end
    local cfg = PaidShopConfig and PaidShopConfig.GetCategoryConfig and PaidShopConfig.GetCategoryConfig(categoryId)
    if not cfg then return false, "Catégorie inconnue" end
    cfg.enabled = enabled and true or false
    if PaidShopConfig.RebuildCategoriesList then PaidShopConfig.RebuildCategoriesList() end
    local flags = getSetting("categories_enabled", {}) or {}
    flags[categoryId] = cfg.enabled
    setSetting("categories_enabled", flags)
    return true, cfg.enabled and "Catégorie activée" or "Catégorie désactivée"
end)

RegisterServerCallback("paidshop:adminGetDailyStreak", function(source)
    if not adminOf(source) then return { success = false } end
    local defaults = (PaidShopConfig and PaidShopConfig.DailyBonus and PaidShopConfig.DailyBonus.StreakRewards) or {}
    local saved = getSetting("daily_streak", nil)
    local slots = {}
    for day = 1, 7 do
        slots[day] = (saved and (saved[day] or saved[tostring(day)])) or defaults[day] or { type = "spacecoins", amount = 50 }
    end
    return { success = true, slots = slots }
end)

RegisterServerCallback("paidshop:adminEditDailyStreakSlot", function(source, slot, draft)
    if not adminOf(source) then return false, "Non autorisé" end
    slot = math.floor(tonumber(slot) or 0)
    if slot < 1 or slot > 7 or type(draft) ~= "table" then return false, "Slot invalide" end
    local current = getSetting("daily_streak", nil)
    if type(current) ~= "table" then
        current = {}
        local defaults = (PaidShopConfig and PaidShopConfig.DailyBonus and PaidShopConfig.DailyBonus.StreakRewards) or {}
        for day = 1, 7 do current[day] = defaults[day] or { type = "spacecoins", amount = 50 } end
    end
    current[slot] = draft
    setSetting("daily_streak", current)
    applyStreak(current)
    return true, "Slot enregistré"
end)

local function hydratePourMoi(pool)
    local out = {}
    for i = 1, #(pool or {}) do
        local ref = pool[i]
        if type(ref) == "table" then
            local src = PaidShop.FindItem(ref.sourceCategory, ref.sourceSpawnName)
            local sourcePrice = src and math.floor(tonumber(src.price) or 0) or 0
            local reduction = math.floor(tonumber(ref.reductionPercent) or 0)
            out[#out + 1] = {
                sourceCategory = ref.sourceCategory,
                sourceSpawnName = ref.sourceSpawnName,
                rarity = ref.rarity or "common",
                reductionPercent = reduction,
                sourceLabel = src and (src.name or src.spawnName) or ref.sourceSpawnName,
                sourcePrice = sourcePrice,
                sourceMissing = src == nil,
                computedPrice = math.floor(sourcePrice * (1 - reduction / 100)),
            }
        end
    end
    return out
end

RegisterServerCallback("paidshop:adminGetPourMoiPool", function(source)
    if not adminOf(source) then return { success = false, pool = {} } end
    return { success = true, pool = hydratePourMoi(getSetting("pour_moi_pool", {}) or {}) }
end)

RegisterServerCallback("paidshop:adminAddPourMoiItem", function(source, sourceCategory, sourceSpawnName, rarity, reductionPercent)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(sourceCategory) ~= "string" or type(sourceSpawnName) ~= "string" then return false, "Item source requis" end
    local pool = getSetting("pour_moi_pool", {}) or {}
    for i = 1, #pool do
        if pool[i].sourceCategory == sourceCategory and pool[i].sourceSpawnName == sourceSpawnName then
            return false, "Déjà dans le pool"
        end
    end
    pool[#pool + 1] = {
        sourceCategory = sourceCategory,
        sourceSpawnName = sourceSpawnName,
        rarity = rarity or "common",
        reductionPercent = math.floor(tonumber(reductionPercent) or 0),
    }
    setSetting("pour_moi_pool", pool)
    return true, "Ajouté"
end)

RegisterServerCallback("paidshop:adminUpdatePourMoiItem", function(source, sourceCategory, sourceSpawnName, rarity, reductionPercent)
    if not adminOf(source) then return false, "Non autorisé" end
    local pool = getSetting("pour_moi_pool", {}) or {}
    for i = 1, #pool do
        if pool[i].sourceCategory == sourceCategory and pool[i].sourceSpawnName == sourceSpawnName then
            pool[i].rarity = rarity or pool[i].rarity
            pool[i].reductionPercent = math.floor(tonumber(reductionPercent) or pool[i].reductionPercent or 0)
            setSetting("pour_moi_pool", pool)
            return true, "Modifié"
        end
    end
    return false, "Introuvable dans le pool"
end)

RegisterServerCallback("paidshop:adminRemovePourMoiItem", function(source, sourceCategory, sourceSpawnName)
    if not adminOf(source) then return false, "Non autorisé" end
    local pool = getSetting("pour_moi_pool", {}) or {}
    local nextPool = {}
    for i = 1, #pool do
        if not (pool[i].sourceCategory == sourceCategory and pool[i].sourceSpawnName == sourceSpawnName) then
            nextPool[#nextPool + 1] = pool[i]
        end
    end
    setSetting("pour_moi_pool", nextPool)
    return true, "Supprimé"
end)

RegisterServerCallback("paidshop:builder:getDisplayedCases", function(source)
    if not adminOf(source) then return { success = false, displayedCases = {} } end
    local list = getSetting("displayed_cases", {}) or {}
    return { success = true, displayedCases = list }
end)

RegisterServerCallback("paidshop:builder:setDisplayedCases", function(source, list)
    if not adminOf(source) then return { success = false, error = "Non autorisé" } end
    if type(list) ~= "table" then return { success = false, error = "Liste invalide" } end
    local clean = {}
    for i = 1, #list do
        if type(list[i]) == "string" and list[i] ~= "" then
            clean[#clean + 1] = list[i]
        end
    end
    setSetting("displayed_cases", clean)
    return { success = true, displayedCases = clean }
end)

RegisterServerCallback("paidshop:builder:getAvailableCases", function(source)
    if not adminOf(source) then return { success = false, availableCases = {} } end
    local items = PaidShop.LoadItems() or {}
    local cases = items.caisses or {}
    local available = {}
    for i = 1, #cases do
        local item = cases[i]
        local pool = item.possible_items or item.possibleItems or item.content
        local count = type(pool) == "table" and #pool or 0
        available[#available + 1] = {
            id = item.spawnName,
            name = item.name or item.spawnName,
            possibleItemsCount = count,
            isValid = count > 0,
        }
    end
    return { success = true, availableCases = available }
end)

RegisterServerCallback("paidshop:setFeaturedItem", function(source, category, spawnName)
    if not adminOf(source) then return false, "Non autorisé" end
    if type(category) ~= "string" then return false, "Catégorie manquante" end
    local items = PaidShop.LoadItems() or {}
    local list = items[category] or {}
    for i = 1, #list do
        local it = list[i]
        local featured = (type(spawnName) == "string" and spawnName ~= "" and it.spawnName == spawnName) or nil
        local row = MySQL.single.await("SELECT `extra` FROM paidshop_items WHERE `category` = ? AND `spawn_name` = ?", { category, it.spawnName })
        local extra = PaidShop.Decode(row and row.extra, {}) or {}
        extra.featured = featured == true or nil
        MySQL.update.await("UPDATE paidshop_items SET `extra` = ? WHERE `category` = ? AND `spawn_name` = ?", {
            json.encode(extra), category, it.spawnName,
        })
    end
    PaidShop.LoadItems(true)
    return true, (spawnName and spawnName ~= "") and "Véhicule mis en avant" or "Mise en avant retirée"
end)
