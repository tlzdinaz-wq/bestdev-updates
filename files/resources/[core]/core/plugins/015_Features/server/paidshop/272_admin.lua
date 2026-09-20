Feat27 = Feat27 or {}

local function sanitizeItem(item)
    if type(item) ~= "table" then return nil end

    local out = {
        spawnName = type(item.spawnName) == "string" and item.spawnName or nil,
        name = type(item.name) == "string" and item.name or nil,
        price = math.floor(tonumber(item.price) or 0),
        originalPrice = tonumber(item.originalPrice),
        image = type(item.image) == "string" and item.image or "",
        tags = type(item.tags) == "table" and item.tags or {},
        description = type(item.description) == "string" and item.description or "",
        rarity = type(item.rarity) == "string" and item.rarity or "common",
        content = type(item.content) == "table" and item.content or nil,
    }

    local extra = {}
    for key, value in pairs(item) do
        if out[key] == nil and key ~= "spawnName" and key ~= "originalPrice" and key ~= "content" then
            extra[key] = value
        end
    end
    out.extra = extra

    return out
end

local function generateSpawnName(category, name)
    local base = tostring(name or category):lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if base == "" then base = category end
    return ("%s_%s_%d"):format(category, base, math.random(1000, 9999))
end

RegisterServerCallback("paidshop:addItemServer", function(source, item, category)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not PaidShop.IsAdmin(xPlayer) then return false, "Non autorisé" end
    if type(category) ~= "string" then return false, "Catégorie manquante" end

    local clean = sanitizeItem(item)
    if not clean then return false, "Cet article n'est pas valide" end

    local categoryConfig = PaidShop.CategoryConfig(category)
    if not categoryConfig then return false, "Catégorie inconnue" end

    if not clean.spawnName or clean.spawnName == "" then
        if categoryConfig.autoGenerateSpawnName then
            clean.spawnName = generateSpawnName(category, clean.name)
        else
            return false, "Nom technique (spawnName) manquant"
        end
    end

    if not clean.name then clean.name = clean.spawnName end

    local ok = pcall(MySQL.insert.await, [[
        INSERT INTO paidshop_items
            (`category`, `spawn_name`, `name`, `price`, `original_price`, `image`, `tags`, `description`, `rarity`, `content`, `extra`, `enabled`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
    ]], {
        category, clean.spawnName, clean.name, clean.price, clean.originalPrice, clean.image,
        json.encode(clean.tags), clean.description, clean.rarity,
        clean.content and json.encode(clean.content) or nil,
        json.encode(clean.extra),
    })

    if not ok then return false, "Cet article existe déjà" end

    PaidShop.LoadItems(true)
    return true, "Article ajouté"
end)

RegisterServerCallback("paidshop:editItemServer", function(source, item, category)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not PaidShop.IsAdmin(xPlayer) then return false, "Non autorisé" end
    if type(category) ~= "string" then return false, "Catégorie manquante" end

    local clean = sanitizeItem(item)
    if not clean or not clean.spawnName then return false, "Cet article n'est pas valide" end

    MySQL.update.await([[
        UPDATE paidshop_items SET
            `name` = ?, `price` = ?, `original_price` = ?, `image` = ?, `tags` = ?,
            `description` = ?, `rarity` = ?, `content` = ?, `extra` = ?
        WHERE `category` = ? AND `spawn_name` = ?
    ]], {
        clean.name or clean.spawnName, clean.price, clean.originalPrice, clean.image,
        json.encode(clean.tags), clean.description, clean.rarity,
        clean.content and json.encode(clean.content) or nil,
        json.encode(clean.extra),
        category, clean.spawnName,
    })

    PaidShop.LoadItems(true)
    return true, "Article modifié"
end)

RegisterServerCallback("paidshop:deleteItemServer", function(source, spawnName, category)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not PaidShop.IsAdmin(xPlayer) then return false, "Non autorisé" end
    if type(spawnName) ~= "string" or type(category) ~= "string" then return false, "Cette demande n'a pas pu être traitée" end

    MySQL.query.await("DELETE FROM paidshop_items WHERE `category` = ? AND `spawn_name` = ?", { category, spawnName })
    PaidShop.LoadItems(true)
    return true, "Article supprimé"
end)

local function resolveTargetAccount(targetId)
    local id = tonumber(targetId)
    if not id then return nil end

    local xPlayer = VFW.GetPlayerFromId(id)
    if xPlayer then return xPlayer end

    local row = MySQL.single.await("SELECT `identifier` FROM paidshop_accounts WHERE `unique_id` = ?", { id })
    if not row then return nil end
    return VFW.GetPlayerFromIdentifier(row.identifier), row.identifier
end

RegisterServerCallback("paidshop:addCoinsAdmin", function(source, targetId, amount)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not PaidShop.IsAdmin(xPlayer) then return false, "Non autorisé" end

    local value = math.floor(tonumber(amount) or 0)
    if value <= 0 or value > 10000000 then return false, "Ce montant n'est pas valide" end

    local target, identifier = resolveTargetAccount(targetId)
    if not target then
        if not identifier then return false, "Joueur introuvable" end
        MySQL.update.await("UPDATE paidshop_accounts SET `spacecoins` = `spacecoins` + ? WHERE `identifier` = ?", { value, identifier })
        MySQL.update.await("UPDATE users SET `spacecoins` = `spacecoins` + ? WHERE `id` = (SELECT `account_id` FROM characters WHERE `identifier` = ?)", { value, identifier })
        return true, ("%d Coins ajoutés (joueur hors ligne)"):format(value)
    end

    PaidShop.AddCoins(target, value)
    PaidShop.Notify(target.source, "SUCCESS", ("Vous avez reçu %d Coins."):format(value), 6)
    return true, ("%d Coins ajoutés"):format(value)
end)

RegisterServerCallback("paidshop:removeCoinsAdmin", function(source, targetId, amount)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not PaidShop.IsAdmin(xPlayer) then return false, "Non autorisé" end

    local value = math.floor(tonumber(amount) or 0)
    if value <= 0 or value > 10000000 then return false, "Ce montant n'est pas valide" end

    local target, identifier = resolveTargetAccount(targetId)
    if not target then
        if not identifier then return false, "Joueur introuvable" end
        MySQL.update.await("UPDATE paidshop_accounts SET `spacecoins` = GREATEST(`spacecoins` - ?, 0) WHERE `identifier` = ?", { value, identifier })
        MySQL.update.await("UPDATE users SET `spacecoins` = GREATEST(`spacecoins` - ?, 0) WHERE `id` = (SELECT `account_id` FROM characters WHERE `identifier` = ?)", { value, identifier })
        return true, ("%d Coins retirés (joueur hors ligne)"):format(value)
    end

    PaidShop.RemoveCoins(target, value)
    return true, ("%d Coins retirés"):format(value)
end)

CreateThread(function()
    Wait(3000)
    VFW.RegisterCommand("givespacecoins", "givespacecoins", function(source, xPlayer, args)
        local targetId = tonumber(args[1])
        local amount = math.floor(tonumber(args[2]) or 0)

        if not targetId or amount <= 0 then
            Feat27.NotifyError(source, "Usage : /givespacecoins [id] [montant]")
            return
        end

        local target = VFW.GetPlayerFromId(targetId)
        if not target then
            Feat27.NotifyError(source, "Joueur introuvable.")
            return
        end

        PaidShop.EnsureAccount(target)
        PaidShop.AddCoins(target, amount)
        Feat27.NotifyOk(source, ("%d Coins donnés à %s."):format(amount, target.name or target.playerName))
        PaidShop.Notify(target.source, "SUCCESS", ("Vous avez reçu %d Coins."):format(amount), 6)
    end, {
        help = "Donner des Coins boutique à un joueur",
        params = {
            { name = "id", help = "ID serveur du joueur" },
            { name = "montant", help = "Nombre de Coins" },
        },
    })
end)
