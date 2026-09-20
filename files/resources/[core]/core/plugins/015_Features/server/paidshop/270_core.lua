Feat27 = Feat27 or {}

PaidShop = PaidShop or {}

PaidShop.ADMIN_PERMISSION = "boutique"

local itemCache = nil

local function decode(value, fallback)
    if VFW and VFW.DB and VFW.DB.Decode then
        return VFW.DB.Decode(value, fallback)
    end
    if type(value) == "table" then return value end
    if value == nil or value == "" then return fallback end
    local ok, res = pcall(json.decode, value)
    if ok and res ~= nil then return res end
    return fallback
end

PaidShop.Decode = decode

function PaidShop.IsAdmin(xPlayer)
    if not xPlayer then return false end
    return xPlayer.hasPermission(PaidShop.ADMIN_PERMISSION) or xPlayer.hasPermission("gestion")
end

function PaidShop.EnsureAccount(xPlayer)
    if not xPlayer then return nil end

    local row = MySQL.single.await("SELECT `unique_id`, `spacecoins`, `vip_tier` FROM paidshop_accounts WHERE `identifier` = ?", { xPlayer.identifier })
    if row then return row end

    MySQL.insert.await("INSERT IGNORE INTO paidshop_accounts (`identifier`, `spacecoins`, `vip_tier`) VALUES (?, 0, ?)", {
        xPlayer.identifier, tonumber(xPlayer.vipTier) or 0,
    })

    return MySQL.single.await("SELECT `unique_id`, `spacecoins`, `vip_tier` FROM paidshop_accounts WHERE `identifier` = ?", { xPlayer.identifier })
end

function PaidShop.GetCoins(xPlayer)
    if not xPlayer then return 0 end
    local row = MySQL.single.await("SELECT `spacecoins` FROM users WHERE `id` = ?", { xPlayer.accountId })
    if row then
        local value = math.floor(tonumber(row.spacecoins) or 0)
        if xPlayer.globalData then xPlayer.globalData.spacecoins = value end
        return value
    end
    return math.floor(tonumber(xPlayer.globalData and xPlayer.globalData.spacecoins) or 0)
end

function PaidShop.SetCoins(xPlayer, amount)
    if not xPlayer then return 0 end
    local value = math.floor(tonumber(amount) or 0)
    if value < 0 then value = 0 end

    MySQL.update.await("UPDATE users SET `spacecoins` = ? WHERE `id` = ?", { value, xPlayer.accountId })
    MySQL.update.await("UPDATE paidshop_accounts SET `spacecoins` = ? WHERE `identifier` = ?", { value, xPlayer.identifier })

    if xPlayer.globalData then
        xPlayer.globalData.spacecoins = value
        xPlayer.triggerEvent("vfw:updatePlayerGlobalData", xPlayer.getGlobalData())
    end
    xPlayer.triggerEvent("paidshop:updateCoins", value)
    return value
end

function PaidShop.AddCoins(xPlayer, amount)
    return PaidShop.SetCoins(xPlayer, PaidShop.GetCoins(xPlayer) + math.floor(tonumber(amount) or 0))
end

function PaidShop.RemoveCoins(xPlayer, amount)
    return PaidShop.SetCoins(xPlayer, PaidShop.GetCoins(xPlayer) - math.floor(tonumber(amount) or 0))
end

function PaidShop.TakeCoins(xPlayer, amount)
    if not xPlayer then return false, 0 end

    local value = math.floor(tonumber(amount) or 0)
    if value <= 0 then return true, PaidShop.GetCoins(xPlayer) end

    local affected = MySQL.update.await("UPDATE users SET `spacecoins` = `spacecoins` - ? WHERE `id` = ? AND `spacecoins` >= ?", {
        value, xPlayer.accountId, value,
    })

    if (tonumber(affected) or 0) <= 0 then
        return false, PaidShop.GetCoins(xPlayer)
    end

    local balance = PaidShop.GetCoins(xPlayer)
    MySQL.update.await("UPDATE paidshop_accounts SET `spacecoins` = ? WHERE `identifier` = ?", { balance, xPlayer.identifier })

    if xPlayer.globalData then
        xPlayer.triggerEvent("vfw:updatePlayerGlobalData", xPlayer.getGlobalData())
    end
    xPlayer.triggerEvent("paidshop:updateCoins", balance)

    return true, balance
end

function PaidShop.GetVipTier(xPlayer)
    if not xPlayer then return 0 end
    return math.floor(tonumber(xPlayer.vipTier) or 0)
end

local function seedItems()
    local existing = MySQL.query.await("SELECT `id` FROM paidshop_items LIMIT 1") or {}
    if #existing > 0 then return end

    local source = (PaidShopConfig and PaidShopConfig.Items) or {}
    for category, list in pairs(source) do
        if type(list) == "table" then
            for i = 1, #list do
                local item = list[i]
                local spawnName = item.spawnName or item.spawn_name or item.name
                if type(spawnName) == "string" then
                    local extra = {}
                    for key, value in pairs(item) do
                        if key ~= "name" and key ~= "price" and key ~= "originalPrice" and key ~= "image"
                            and key ~= "tags" and key ~= "description" and key ~= "rarity"
                            and key ~= "content" and key ~= "spawnName" then
                            extra[key] = value
                        end
                    end

                    MySQL.query.await([[
                        INSERT IGNORE INTO paidshop_items
                            (`category`, `spawn_name`, `name`, `price`, `original_price`, `image`, `tags`, `description`, `rarity`, `content`, `extra`, `enabled`)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
                    ]], {
                        category, spawnName, item.name or spawnName,
                        math.floor(tonumber(item.price) or 0),
                        tonumber(item.originalPrice),
                        item.image or "",
                        json.encode(item.tags or {}),
                        item.description or "",
                        item.rarity or "common",
                        item.content and json.encode(item.content) or nil,
                        json.encode(extra),
                    })
                end
            end
        end
    end
end

function PaidShop.LoadItems(force)
    if itemCache and not force then return itemCache end

    local rows = MySQL.query.await("SELECT * FROM paidshop_items WHERE `enabled` = 1 ORDER BY `category` ASC, `id` ASC") or {}
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        local entry = {
            spawnName = row.spawn_name,
            name = row.name,
            price = math.floor(tonumber(row.price) or 0),
            originalPrice = tonumber(row.original_price),
            image = row.image or "",
            tags = decode(row.tags, {}),
            description = row.description or "",
            rarity = row.rarity or "common",
            content = decode(row.content, nil),
            category = row.category,
            id = row.id,
        }

        local extra = decode(row.extra, {})
        if type(extra) == "table" then
            for key, value in pairs(extra) do
                if entry[key] == nil then entry[key] = value end
            end
        end

        out[row.category] = out[row.category] or {}
        table.insert(out[row.category], entry)
    end

    itemCache = out
    return out
end

function PaidShop.InvalidateItems()
    itemCache = nil
end

function PaidShop.FindItem(category, spawnName)
    if type(category) ~= "string" or type(spawnName) ~= "string" then return nil end
    local items = PaidShop.LoadItems()
    local list = items[category]
    if not list then return nil end
    for i = 1, #list do
        if list[i].spawnName == spawnName then return list[i] end
    end
    return nil
end

function PaidShop.CategoryConfig(category)
    if not PaidShopConfig or not PaidShopConfig.GetCategoryConfig then return nil end
    return PaidShopConfig.GetCategoryConfig(category)
end

RegisterServerCallback("paidshop:isPlayerBoutiqueAdmin", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    return PaidShop.IsAdmin(xPlayer) == true
end)

RegisterServerCallback("paidshop:getPlayerInfo", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { identifier = "", name = "", spacecoins = 0, vip_tier = 0 }
    end

    PaidShop.EnsureAccount(xPlayer)

    return {
        identifier = xPlayer.identifier,
        name = xPlayer.name or xPlayer.playerName,
        spacecoins = PaidShop.GetCoins(xPlayer),
        vip_tier = PaidShop.GetVipTier(xPlayer),
    }
end)

RegisterServerCallback("paidshop:getShopData", function(source)
    local categories = {}
    if PaidShopConfig then
        categories = PaidShopConfig.Categories or {}
    end

    local rarityColors = (PaidShopConfig and PaidShopConfig.RarityColors) or {
        common = "#b0b0b0", uncommon = "#6bdb6b", rare = "#4a90e2",
        epic = "#b24ae2", legendary = "#f4b245",
    }

    local items = PaidShop.LoadItems()
    for i = 1, #categories do
        local id = categories[i].id
        if id and not items[id] then items[id] = {} end
    end

    return {
        categories = categories,
        items = items,
        rarityColors = rarityColors,
    }
end)

RegisterServerCallback("paidshop:getPurchaseHistory", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local rows = MySQL.query.await([[
        SELECT `id`, `category`, `item_name`, `quantity`, `price`, `gifted_to`,
               DATE_FORMAT(`created_at`, '%Y-%m-%d %H:%i:%s') AS created_at
        FROM paidshop_purchases WHERE `identifier` = ? ORDER BY `id` DESC LIMIT 100
    ]], { xPlayer.identifier }) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local date = tostring(row.created_at or "")
        out[i] = {
            id = row.id,
            category = row.category,
            itemName = row.item_name,
            item_name = row.item_name,
            item_label = row.item_name,
            quantity = row.quantity,
            price = row.price,
            giftedTo = row.gifted_to,
            date = date,
            purchase_date = date,
        }
    end
    return out
end)

RegisterNetEvent("paidshop:analytics:flush", function(batch)
    local source = source
    if type(batch) ~= "table" then return end
    if not Feat27.RateLimit(source, "paidshop:analytics", 5000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local count = 0
    for i = 1, #batch do
        local entry = batch[i]
        if count >= 50 then break end
        if type(entry) == "table" and type(entry.event_type) == "string" then
            count = count + 1
            MySQL.insert("INSERT INTO paidshop_analytics (`identifier`, `event_type`, `category`, `item_name`, `price`, `fail_reason`) VALUES (?, ?, ?, ?, ?, ?)", {
                xPlayer.identifier,
                entry.event_type:sub(1, 40),
                type(entry.category) == "string" and entry.category:sub(1, 40) or "",
                type(entry.item_name) == "string" and entry.item_name:sub(1, 80) or "",
                tonumber(entry.price) or 0,
                type(entry.fail_reason) == "string" and entry.fail_reason:sub(1, 160) or "",
            })
        end
    end
end)

function PaidShop.Broadcast(message)
    TriggerClientEvent("paidshop:liveActivity", -1, message)
end

function PaidShop.Notify(source, kind, message, duration)
    TriggerClientEvent("paidshop:uiNotification", source, {
        type = kind or "INFO",
        message = message or "",
        duration = duration or 5,
    })
end

CreateThread(function()
    while not VFW or not VFW.Ready do Wait(200) end
    local ok, err = pcall(function()
        seedItems()
        PaidShop.LoadItems(true)
    end)
    if not ok then
        console.warn(("paidshop: initialisation impossible (%s)"):format(tostring(err)))
        return
    end
    console.init("paidshop", "Catalogue boutique chargé")
end)
