local Firework = {
    shops = {},
    items = {},
    settings = {},
}

local BUILDER_PERM = "builder_firework"
local DEFAULT_SETTINGS = {
    basePriceMultiplier = 1.0,
    maxDailyPurchases = 0,
}

local function LoadShops()
    Firework.shops = {}
    local rows = IL.Query("SELECT * FROM firework_shops")
    for i = 1, #rows do
        local row = rows[i]
        Firework.shops[row.id] = {
            id = row.id,
            name = row.name or "Feux d'artifice",
            pos = { x = IL.Num(row.pos_x, 0.0), y = IL.Num(row.pos_y, 0.0), z = IL.Num(row.pos_z, 0.0), h = IL.Num(row.pos_h, 0.0) },
            npcPos = { x = IL.Num(row.npc_x, 0.0), y = IL.Num(row.npc_y, 0.0), z = IL.Num(row.npc_z, 0.0), h = IL.Num(row.npc_h, 0.0) },
            npcModel = row.npc_model or "s_m_y_dealer_01",
            active = IL.Bool(row.active),
        }
    end
end

local function LoadItems()
    Firework.items = {}
    local rows = IL.Query("SELECT * FROM firework_items ORDER BY category, name")
    for i = 1, #rows do
        local row = rows[i]
        Firework.items[#Firework.items + 1] = {
            id = row.id,
            name = row.name,
            label = row.label or IL.ItemLabel(row.name),
            price = IL.Int(row.price, 0),
            category = row.category or "tous",
            stock = IL.Int(row.stock, 0),
            enabled = IL.Bool(row.enabled),
        }
    end
end

local function LoadSettings()
    Firework.settings = IL.LoadSettings("firework_settings", DEFAULT_SETTINGS)
end

local function ShopsMap()
    local out = {}
    for id, shop in pairs(Firework.shops) do
        if shop.active then out[id] = shop end
    end
    return out
end

local function Broadcast()
    TriggerClientEvent("core:firework:syncShops", -1, ShopsMap())
end

local function InvalidateItems()
    TriggerClientEvent("core:firework:invalidateGlobalItemsCache", -1)
end

local function FindItem(itemName)
    for i = 1, #Firework.items do
        if Firework.items[i].name == itemName then return Firework.items[i] end
    end
    return nil
end

local function DailyPurchases(identifier)
    local count = IL.Scalar([[
        SELECT COALESCE(SUM(quantity), 0) FROM firework_purchases
        WHERE identifier = ? AND created_at >= CURDATE()
    ]], { identifier })
    return IL.Int(count, 0)
end

IL.OnReady(function()
    LoadShops()
    LoadItems()
    LoadSettings()
    Broadcast()
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("core:firework:syncShops", source, ShopsMap())
end)

RegisterNetEvent("core:firework:requestShopsList", function()
    local source = source
    TriggerClientEvent("core:firework:syncShops", source, ShopsMap())
end)

RegisterNetEvent("core:firework:createShop", function(shopData)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if not IL.IsTable(shopData) then return end

    local pos = IL.IsTable(shopData.pos) and shopData.pos or {}
    local npcPos = IL.IsTable(shopData.npcPos) and shopData.npcPos or pos

    IL.Insert([[
        INSERT INTO firework_shops (name, pos_x, pos_y, pos_z, pos_h, npc_x, npc_y, npc_z, npc_h, npc_model, active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        IL.Str(shopData.name, "Feux d'artifice"),
        IL.Num(pos.x, 0.0), IL.Num(pos.y, 0.0), IL.Num(pos.z, 0.0), IL.Num(pos.h or pos.heading, 0.0),
        IL.Num(npcPos.x, 0.0), IL.Num(npcPos.y, 0.0), IL.Num(npcPos.z, 0.0), IL.Num(npcPos.h or npcPos.heading, 0.0),
        IL.Str(shopData.npcModel, "s_m_y_dealer_01"),
        shopData.active == false and 0 or 1,
    })

    LoadShops()
    TriggerClientEvent("core:firework:cleanupAllNPCs", -1)
    Broadcast()
end)

RegisterNetEvent("core:firework:updateShop", function(shopId, field, value)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    shopId = IL.Int(shopId, nil)
    if not shopId or type(field) ~= "string" then return end
    if not Firework.shops[shopId] then return end

    if field == "npcPos" then
        if not IL.IsTable(value) then return end
        IL.Execute("UPDATE firework_shops SET npc_x = ?, npc_y = ?, npc_z = ?, npc_h = ? WHERE id = ?", {
            IL.Num(value.x, 0.0), IL.Num(value.y, 0.0), IL.Num(value.z, 0.0), IL.Num(value.h or value.heading, 0.0), shopId,
        })
    elseif field == "npcModel" then
        if type(value) ~= "string" then return end
        IL.Execute("UPDATE firework_shops SET npc_model = ? WHERE id = ?", { value, shopId })
    elseif field == "active" then
        IL.Execute("UPDATE firework_shops SET active = ? WHERE id = ?", { IL.Bool(value) and 1 or 0, shopId })
    else
        return
    end

    LoadShops()
    TriggerClientEvent("core:firework:cleanupAllNPCs", -1)
    Broadcast()
end)

RegisterNetEvent("core:firework:deleteShop", function(shopId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    shopId = IL.Int(shopId, nil)
    if not shopId then return end

    IL.Execute("DELETE FROM firework_shops WHERE id = ?", { shopId })
    LoadShops()
    TriggerClientEvent("core:firework:cleanupAllNPCs", -1)
    Broadcast()
end)

RegisterNetEvent("core:firework:reloadFromDatabase", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    LoadShops()
    LoadItems()
    LoadSettings()
    TriggerClientEvent("core:firework:cleanupAllNPCs", -1)
    Broadcast()
    InvalidateItems()
end)

RegisterNetEvent("core:firework:addGlobalItem", function(itemName, price, category, stock)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(itemName) ~= "string" or itemName == "" then return end

    IL.Execute([[
        INSERT INTO firework_items (name, label, price, category, stock, enabled)
        VALUES (?, ?, ?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE price = VALUES(price), category = VALUES(category), stock = VALUES(stock), enabled = 1
    ]], {
        itemName, IL.ItemLabel(itemName),
        math.max(0, IL.Int(price, 0)),
        IL.Str(category, "tous"),
        math.max(0, IL.Int(stock, 0)),
    })

    LoadItems()
    InvalidateItems()
end)

RegisterNetEvent("core:firework:updateGlobalItem", function(itemName, price, category, unused, stock)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(itemName) ~= "string" or itemName == "" then return end

    if price ~= nil and tonumber(price) then
        IL.Execute("UPDATE firework_items SET price = ? WHERE name = ?", { math.max(0, IL.Int(price, 0)), itemName })
    end
    if type(category) == "string" and category ~= "" then
        IL.Execute("UPDATE firework_items SET category = ? WHERE name = ?", { category, itemName })
    end
    if stock ~= nil and tonumber(stock) then
        IL.Execute("UPDATE firework_items SET stock = ? WHERE name = ?", { math.max(0, IL.Int(stock, 0)), itemName })
    end

    LoadItems()
    InvalidateItems()
end)

RegisterNetEvent("core:firework:removeGlobalItem", function(itemName)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(itemName) ~= "string" or itemName == "" then return end

    IL.Execute("UPDATE firework_items SET enabled = 0 WHERE name = ?", { itemName })
    LoadItems()
    InvalidateItems()
end)

RegisterNetEvent("core:firework:enableGlobalItem", function(itemName)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(itemName) ~= "string" or itemName == "" then return end

    IL.Execute("UPDATE firework_items SET enabled = 1 WHERE name = ?", { itemName })
    LoadItems()
    InvalidateItems()
end)

RegisterNetEvent("core:firework:updateSettings", function(key, value)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(key) ~= "string" or DEFAULT_SETTINGS[key] == nil then return end

    local number = tonumber(value)
    if not number then return end

    IL.SaveSetting("firework_settings", key, number)
    Firework.settings[key] = number
    InvalidateItems()
end)

IL.RegisterCallback("core:firework:getGlobalItems", function(source)
    local multiplier = IL.Num(Firework.settings.basePriceMultiplier, 1.0)
    local out = {}
    for i = 1, #Firework.items do
        local item = Firework.items[i]
        if item.enabled and item.stock > 0 then
            out[#out + 1] = {
                name = item.name,
                label = item.label,
                price = math.max(1, math.floor(item.price * multiplier)),
                category = item.category,
            }
        end
    end
    return out
end)

IL.RegisterCallback("core:firework:getPlayerAccounts", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { cash = 0, bank = 0 } end
    return {
        cash = IL.AccountMoney(xPlayer, "money"),
        bank = IL.AccountMoney(xPlayer, "bank"),
    }
end)

IL.RegisterCallback("core:firework:getShops", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return {} end
    local out = {}
    for _, shop in pairs(Firework.shops) do
        out[#out + 1] = shop
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end)

IL.RegisterCallback("core:firework:getGlobalItemsForBuilder", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return {} end
    return Firework.items
end)

IL.RegisterCallback("core:firework:getSettings", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return DEFAULT_SETTINGS end
    return {
        basePriceMultiplier = IL.Num(Firework.settings.basePriceMultiplier, 1.0),
        maxDailyPurchases = IL.Int(Firework.settings.maxDailyPurchases, 0),
    }
end)

IL.RegisterCallback("core:firework:purchaseItems", function(source, purchaseData, total, paymentMethod)
    local xPlayer = IL.Player(source)
    if not xPlayer then
        return { success = false, message = "Joueur introuvable", cash = 0, bank = 0 }
    end

    local cash = IL.AccountMoney(xPlayer, "money")
    local bank = IL.AccountMoney(xPlayer, "bank")

    if not IL.IsTable(purchaseData) or #purchaseData == 0 then
        return { success = false, message = "Panier vide", cash = cash, bank = bank }
    end

    paymentMethod = IL.Str(paymentMethod, "cash")
    local account = paymentMethod == "bank" and "bank" or "money"
    local multiplier = IL.Num(Firework.settings.basePriceMultiplier, 1.0)

    local realTotal = 0
    local lines = {}
    local totalQuantity = 0

    for i = 1, #purchaseData do
        local entry = purchaseData[i]
        if not IL.IsTable(entry) then
            return { success = false, message = "Votre panier n'est pas valide", cash = cash, bank = bank }
        end
        local name = IL.Str(entry.name, nil)
        local quantity = IL.Int(entry.quantity, 0)
        if not name or quantity <= 0 or quantity > 500 then
            return { success = false, message = "Votre panier n'est pas valide", cash = cash, bank = bank }
        end
        local def = FindItem(name)
        if not def or not def.enabled then
            return { success = false, message = "Article indisponible", cash = cash, bank = bank }
        end
        if def.stock < quantity then
            return { success = false, message = "Stock insuffisant", cash = cash, bank = bank }
        end
        realTotal = realTotal + math.max(1, math.floor(def.price * multiplier)) * quantity
        totalQuantity = totalQuantity + quantity
        lines[#lines + 1] = { name = name, quantity = quantity, def = def }
    end

    local maxDaily = IL.Int(Firework.settings.maxDailyPurchases, 0)
    if maxDaily > 0 then
        if DailyPurchases(xPlayer.identifier) + totalQuantity > maxDaily then
            return { success = false, message = "Limite d'achat journaliere atteinte", cash = cash, bank = bank }
        end
    end

    if realTotal <= 0 then
        return { success = false, message = "Votre panier n'est pas valide", cash = cash, bank = bank }
    end

    for i = 1, #lines do
        if not xPlayer.canCarryItem(lines[i].name, lines[i].quantity) then
            return { success = false, message = "Votre inventaire est plein", cash = cash, bank = bank }
        end
    end

    if not IL.TakeMoney(xPlayer, account, realTotal, "firework") then
        return { success = false, message = "Fonds insuffisants", cash = cash, bank = bank }
    end

    for i = 1, #lines do
        IL.GiveItem(xPlayer, lines[i].name, lines[i].quantity, false)
        lines[i].def.stock = lines[i].def.stock - lines[i].quantity
        IL.Execute("UPDATE firework_items SET stock = GREATEST(stock - ?, 0) WHERE name = ?", {
            lines[i].quantity, lines[i].name,
        })
    end

    IL.Execute("INSERT INTO firework_purchases (identifier, quantity) VALUES (?, ?)", {
        xPlayer.identifier, totalQuantity,
    })

    InvalidateItems()

    return {
        success = true,
        cash = IL.AccountMoney(xPlayer, "money"),
        bank = IL.AccountMoney(xPlayer, "bank"),
    }
end)
