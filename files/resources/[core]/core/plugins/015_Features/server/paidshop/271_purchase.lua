Feat27 = Feat27 or {}

local function addPending(identifier, category, item, quantity, price)
    return MySQL.insert.await([[
        INSERT INTO paidshop_pending_items (`identifier`, `category`, `spawn_name`, `name`, `image`, `quantity`, `price`, `status`)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], {
        identifier, category, item.spawnName, item.name or item.spawnName,
        item.image or "", quantity, price,
    })
end

local function logPurchase(identifier, category, spawnName, quantity, price, giftedTo)
    MySQL.insert("INSERT INTO paidshop_purchases (`identifier`, `category`, `item_name`, `quantity`, `price`, `gifted_to`) VALUES (?, ?, ?, ?, ?, ?)", {
        identifier, category, spawnName, quantity, price, giftedTo,
    })
end

local function pendingCount(identifier)
    local row = MySQL.single.await("SELECT COUNT(*) AS total FROM paidshop_pending_items WHERE `identifier` = ? AND `status` = 'pending'", { identifier })
    return row and tonumber(row.total) or 0
end

local function pushPendingCount(xPlayer)
    xPlayer.triggerEvent("paidshop:updatePendingItemCount", pendingCount(xPlayer.identifier))
end

PaidShop.PushPendingCount = pushPendingCount
PaidShop.AddPending = addPending
PaidShop.LogPurchase = logPurchase

local function resolveQuantity(categoryConfig, quantity)
    local value = math.floor(tonumber(quantity) or 1)
    if value < 1 then value = 1 end
    local maxQuantity = categoryConfig and tonumber(categoryConfig.maxQuantity)
    if maxQuantity and value > maxQuantity then value = maxQuantity end
    if value > 50 then value = 50 end
    return value
end

local function doPurchase(source, spawnName, quantity, category, targetIdentifier, targetXPlayer)
    if type(spawnName) ~= "string" or type(category) ~= "string" then
        return false, "Cette demande n'a pas pu être traitée", nil
    end

    if not Feat27.RateLimit(source, "paidshop:buy", 800) then
        return false, "Veuillez patienter un instant", nil
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable", nil end

    local categoryConfig = PaidShop.CategoryConfig(category)
    if not categoryConfig or categoryConfig.enabled == false then
        return false, "Catégorie indisponible", nil
    end

    if categoryConfig.adminOnly and not PaidShop.IsAdmin(xPlayer) then
        return false, "Catégorie réservée au staff", nil
    end

    if category == "vip" then
        return false, "Les rangs VIP s'achètent sur la boutique web", nil
    end

    local item = PaidShop.FindItem(category, spawnName)
    if not item then return false, "Article introuvable", nil end

    local amount = resolveQuantity(categoryConfig, quantity)
    local price = math.floor((tonumber(item.price) or 0) * amount)
    if price <= 0 then return false, "Article non achetable", nil end

    local paid, newBalance = PaidShop.TakeCoins(xPlayer, price)
    if not paid then
        return false, "Solde de Coins insuffisant", newBalance
    end

    local receiverIdentifier = targetIdentifier or xPlayer.identifier
    addPending(receiverIdentifier, category, item, amount, price)
    logPurchase(xPlayer.identifier, category, spawnName, amount, price, targetIdentifier and 1 or nil)

    pushPendingCount(xPlayer)
    if targetXPlayer then
        pushPendingCount(targetXPlayer)
        PaidShop.Notify(targetXPlayer.source, "SUCCESS", ("Vous avez reçu %s en cadeau !"):format(item.name or spawnName), 6)
    end

    PaidShop.Broadcast({
        player = xPlayer.name or xPlayer.playerName,
        item = item.name or spawnName,
        category = category,
        rarity = item.rarity,
    })

    return true, "Achat effectué, retrouvez l'article dans vos objets en attente", newBalance
end

PaidShop.DoPurchase = doPurchase

RegisterServerCallback("paidshop:purchaseItem", function(source, spawnName, quantity, category)
    return doPurchase(source, spawnName, quantity, category or "vehicules")
end)

RegisterServerCallback("paidshop:buyItem", function(source, itemName, quantity, category, isOpeningCase)
    return doPurchase(source, itemName, quantity, category)
end)

RegisterServerCallback("paidshop:giftItem", function(source, itemName, quantity, category, targetUniqueId)
    local uniqueId = tonumber(targetUniqueId)
    if not uniqueId then return false, "Cet ID boutique n'est pas valide", nil end

    local row = MySQL.single.await("SELECT `identifier` FROM paidshop_accounts WHERE `unique_id` = ?", { uniqueId })
    if not row then return false, "Aucun joueur avec cet ID boutique", nil end

    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer and row.identifier == xPlayer.identifier then
        return false, "Vous ne pouvez pas vous offrir un cadeau", nil
    end

    local target = VFW.GetPlayerFromIdentifier(row.identifier)
    return doPurchase(source, itemName, quantity, category, row.identifier, target)
end)

RegisterServerCallback("paidshop:getPendingItems", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local rows = MySQL.query.await([[
        SELECT *, DATE_FORMAT(`created_at`, '%Y-%m-%d %H:%i:%s') AS created_at_text
        FROM paidshop_pending_items WHERE `identifier` = ? AND `status` = 'pending' ORDER BY `id` DESC
    ]], { xPlayer.identifier }) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local date = tostring(row.created_at_text or "")
        out[i] = {
            itemId = row.id,
            id = row.id,
            category = row.category,
            spawnName = row.spawn_name,
            name = row.name,
            item_label = row.name ~= "" and row.name or row.spawn_name,
            image = row.image,
            quantity = row.quantity,
            price = row.price,
            date = date,
            purchase_date = date,
        }
    end
    return out
end)

local function deliverItem(xPlayer, row)
    local category = row.category
    local categoryConfig = PaidShop.CategoryConfig(category)
    local itemType = categoryConfig and categoryConfig.itemType or "consumable"
    local definition = PaidShop.FindItem(category, row.spawn_name)

    if itemType == "vehicle" then
        local ok, result = Feat27.Vehicles.Store(xPlayer.identifier, row.spawn_name, {}, nil, { kind = "car" })
        if not ok then
            return false, "Livraison du véhicule impossible (garage indisponible)"
        end
        return true, ("Véhicule livré au garage (plaque %s)"):format(tostring(result))
    end

    if itemType == "ped" or category == "peds" then
        MySQL.query.await("INSERT IGNORE INTO owned_peds (`identifier`, `ped_model`, `name`, `image`) VALUES (?, ?, ?, ?)", {
            xPlayer.identifier, row.spawn_name, row.name or row.spawn_name, row.image or "",
        })
        return true, "Animal débloqué"
    end

    if itemType == "pack" or category == "packs" then
        local content = definition and definition.content
        if type(content) ~= "table" then
            return false, "Contenu du pack introuvable"
        end
        for _, entry in pairs(content) do
            if type(entry) == "table" and type(entry.item) == "string" then
                Feat27.Inv.Give(xPlayer, entry.item, math.floor(tonumber(entry.count) or 1), nil, false)
            elseif type(entry) == "string" then
                Feat27.Inv.Give(xPlayer, entry, 1, nil, false)
            end
        end
        return true, "Pack livré dans votre inventaire"
    end

    local giveName = row.spawn_name
    local giveCount = math.floor(tonumber(row.quantity) or 1)

    if definition then
        if type(definition.claimItem) == "string" then
            giveName = definition.claimItem
            giveCount = math.floor(tonumber(definition.claimCount) or giveCount)
        end
    end

    if not Feat27.Inv.Exists(giveName) then
        return false, "Cet article n'existe pas dans l'inventaire"
    end

    if not Feat27.Inv.CanCarry(xPlayer, giveName, giveCount) then
        return false, "Votre inventaire est plein"
    end

    if not Feat27.Inv.Give(xPlayer, giveName, giveCount, nil, true) then
        return false, "Livraison impossible"
    end

    return true, "Article livré dans votre inventaire"
end

RegisterServerCallback("paidshop:claimItem", function(source, itemId)
    local id = tonumber(itemId)
    if not id then return false, "Cet identifiant n'est pas valide" end
    if not Feat27.RateLimit(source, "paidshop:claim", 700) then return false, "Veuillez patienter" end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local row = MySQL.single.await("SELECT * FROM paidshop_pending_items WHERE `id` = ? AND `identifier` = ? AND `status` = 'pending'", {
        id, xPlayer.identifier,
    })
    if not row then return false, "Article introuvable" end

    local ok, message = deliverItem(xPlayer, row)
    if not ok then return false, message end

    MySQL.update.await("UPDATE paidshop_pending_items SET `status` = 'claimed', `claimed_at` = NOW() WHERE `id` = ?", { id })
    pushPendingCount(xPlayer)

    return true, message
end)

RegisterServerCallback("paidshop:refundItem", function(source, itemId)
    local id = tonumber(itemId)
    if not id then return false, "Cet identifiant n'est pas valide" end
    if not Feat27.RateLimit(source, "paidshop:refund", 700) then return false, "Veuillez patienter" end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local row = MySQL.single.await("SELECT * FROM paidshop_pending_items WHERE `id` = ? AND `identifier` = ? AND `status` = 'pending'", {
        id, xPlayer.identifier,
    })
    if not row then return false, "Article introuvable" end

    local categoryConfig = PaidShop.CategoryConfig(row.category)
    if categoryConfig and categoryConfig.allowRefund == false then
        return false, "Cet article n'est pas remboursable"
    end

    MySQL.update.await("UPDATE paidshop_pending_items SET `status` = 'refunded', `claimed_at` = NOW() WHERE `id` = ?", { id })

    local refunded = math.floor(tonumber(row.price) or 0)
    PaidShop.AddCoins(xPlayer, refunded)
    pushPendingCount(xPlayer)

    return true, ("Remboursement de %d Coins effectué"):format(refunded)
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    SetTimeout(8000, function()
        if VFW.GetPlayerFromId(source) then
            PaidShop.EnsureAccount(xPlayer)
            pushPendingCount(xPlayer)
            xPlayer.triggerEvent("paidshop:updateAdminStatus", PaidShop.IsAdmin(xPlayer))
        end
    end)
end)
