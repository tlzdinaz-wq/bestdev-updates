local Ammunition = {
    shops = {},
    items = {},
}

local BUILDER_PERM = "builder_ammunition"
local VALID_CATEGORIES = {
    tous = true,
    arme_blanche = true,
    munition = true,
    arme_legere = true,
    arme_lourde = true,
}

local function rowToShop(row)
    return {
        id = row.id,
        name = row.name or "Ammu-Nation",
        pos = { x = row.pos_x or 0.0, y = row.pos_y or 0.0, z = row.pos_z or 0.0, h = row.pos_h or 0.0 },
        npcPos = { x = row.npc_x or 0.0, y = row.npc_y or 0.0, z = row.npc_z or 0.0, h = row.npc_h or 0.0 },
        active = IL.Bool(row.active),
        blipEnabled = IL.Bool(row.blip_enabled),
    }
end

local function LoadShops()
    Ammunition.shops = {}
    local rows = IL.Query("SELECT * FROM ammunition_shops")
    for i = 1, #rows do
        local shop = rowToShop(rows[i])
        Ammunition.shops[shop.id] = shop
    end
end

local function LoadItems()
    Ammunition.items = {}
    local rows = IL.Query("SELECT * FROM ammunition_items ORDER BY category, name")
    for i = 1, #rows do
        local row = rows[i]
        Ammunition.items[#Ammunition.items + 1] = {
            id = row.id,
            name = row.name,
            label = row.label or IL.ItemLabel(row.name),
            price = IL.Int(row.price, 0),
            category = row.category or "tous",
            description = row.description,
            enabled = IL.Bool(row.enabled),
        }
    end
end

local function ShopsMap()
    local out = {}
    for id, shop in pairs(Ammunition.shops) do
        if shop.active then
            out[id] = shop
        end
    end
    return out
end

local function Broadcast()
    TriggerClientEvent("core:ammunition:syncAmmunitions", -1, ShopsMap())
end

local function InvalidateItems()
    TriggerClientEvent("core:ammunition:invalidateGlobalItemsCache", -1)
end

IL.OnReady(function()
    LoadShops()
    LoadItems()
    Broadcast()
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("core:ammunition:receiveAmmunitionsList", source, ShopsMap())
end)

RegisterNetEvent("core:ammunition:requestAmmunitionsList", function()
    local source = source
    TriggerClientEvent("core:ammunition:receiveAmmunitionsList", source, ShopsMap())
end)

RegisterNetEvent("core:ammunition:createAmmunition", function(shopData)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if not IL.IsTable(shopData) then return end

    local pos = IL.IsTable(shopData.pos) and shopData.pos or {}
    local npcPos = IL.IsTable(shopData.npcPos) and shopData.npcPos or pos

    local id = IL.Insert([[
        INSERT INTO ammunition_shops (name, pos_x, pos_y, pos_z, pos_h, npc_x, npc_y, npc_z, npc_h, active, blip_enabled)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        IL.Str(shopData.name, "Ammu-Nation"),
        IL.Num(pos.x, 0.0), IL.Num(pos.y, 0.0), IL.Num(pos.z, 0.0), IL.Num(pos.h or pos.heading, 0.0),
        IL.Num(npcPos.x, 0.0), IL.Num(npcPos.y, 0.0), IL.Num(npcPos.z, 0.0), IL.Num(npcPos.h or npcPos.heading, 0.0),
        shopData.active == false and 0 or 1,
        shopData.blipEnabled == false and 0 or 1,
    })
    if not id then return end

    LoadShops()
    TriggerClientEvent("core:ammunition:cleanupAllNPCs", -1)
    Broadcast()
    IL.Notify(source, "STAFF", "Armurerie creee.")
end)

RegisterNetEvent("core:ammunition:updateAmmunition", function(shopId, field, value)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    shopId = IL.Int(shopId, nil)
    if not shopId or type(field) ~= "string" then return end
    if not Ammunition.shops[shopId] then return end

    if field == "pos" or field == "npcPos" then
        if not IL.IsTable(value) then return end
        local prefix = field == "pos" and "pos" or "npc"
        IL.Execute(("UPDATE ammunition_shops SET %s_x = ?, %s_y = ?, %s_z = ?, %s_h = ? WHERE id = ?"):format(prefix, prefix, prefix, prefix), {
            IL.Num(value.x, 0.0), IL.Num(value.y, 0.0), IL.Num(value.z, 0.0), IL.Num(value.h or value.heading, 0.0), shopId,
        })
    elseif field == "active" then
        IL.Execute("UPDATE ammunition_shops SET active = ? WHERE id = ?", { IL.Bool(value) and 1 or 0, shopId })
    elseif field == "blipEnabled" then
        IL.Execute("UPDATE ammunition_shops SET blip_enabled = ? WHERE id = ?", { IL.Bool(value) and 1 or 0, shopId })
    else
        return
    end

    LoadShops()
    TriggerClientEvent("core:ammunition:cleanupAllNPCs", -1)
    Broadcast()
end)

RegisterNetEvent("core:ammunition:deleteAmmunition", function(shopId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    shopId = IL.Int(shopId, nil)
    if not shopId or not Ammunition.shops[shopId] then return end

    IL.Execute("DELETE FROM ammunition_shops WHERE id = ?", { shopId })
    LoadShops()
    TriggerClientEvent("core:ammunition:cleanupAllNPCs", -1)
    Broadcast()
    IL.Notify(source, "STAFF", "Armurerie supprimee.")
end)

RegisterNetEvent("core:ammunition:addGlobalItem", function(itemName, price, category)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(itemName) ~= "string" or itemName == "" then return end

    price = IL.Int(price, 0)
    if price < 0 then price = 0 end
    category = IL.Str(category, "tous")
    if not VALID_CATEGORIES[category] then category = "tous" end

    IL.Execute([[
        INSERT INTO ammunition_items (name, label, price, category, enabled)
        VALUES (?, ?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE price = VALUES(price), category = VALUES(category), enabled = 1
    ]], { itemName, IL.ItemLabel(itemName), price, category })

    LoadItems()
    InvalidateItems()
end)

RegisterNetEvent("core:ammunition:updateGlobalItem", function(itemName, price, category, description)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(itemName) ~= "string" or itemName == "" then return end

    if price ~= nil then
        IL.Execute("UPDATE ammunition_items SET price = ? WHERE name = ?", { IL.Int(price, 0), itemName })
    end
    if type(category) == "string" and VALID_CATEGORIES[category] then
        IL.Execute("UPDATE ammunition_items SET category = ? WHERE name = ?", { category, itemName })
    end
    if type(description) == "string" then
        IL.Execute("UPDATE ammunition_items SET description = ? WHERE name = ?", { description, itemName })
    end

    LoadItems()
    InvalidateItems()
end)

RegisterNetEvent("core:ammunition:removeGlobalItem", function(itemName)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(itemName) ~= "string" or itemName == "" then return end

    IL.Execute("DELETE FROM ammunition_items WHERE name = ?", { itemName })
    LoadItems()
    InvalidateItems()
end)

IL.RegisterCallback("core:ammunition:getGlobalItems", function(source)
    local out = {}
    for i = 1, #Ammunition.items do
        local item = Ammunition.items[i]
        if item.enabled then
            out[#out + 1] = {
                name = item.name,
                label = item.label,
                price = item.price,
                category = item.category,
            }
        end
    end
    return out
end)

IL.RegisterCallback("core:ammunition:getPlayerAccounts", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { cash = 0, bank = 0 } end
    return {
        cash = IL.AccountMoney(xPlayer, "money"),
        bank = IL.AccountMoney(xPlayer, "bank"),
    }
end)

IL.RegisterCallback("core:ammunition:getAmmunitions", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return {} end
    local out = {}
    for _, shop in pairs(Ammunition.shops) do
        out[#out + 1] = shop
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end)

IL.RegisterCallback("core:ammunition:getGlobalItemsForBuilder", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return {} end
    local out = {}
    for i = 1, #Ammunition.items do
        local item = Ammunition.items[i]
        out[#out + 1] = {
            id = item.id,
            name = item.name,
            label = item.label,
            price = item.price,
            category = item.category,
            description = item.description,
            enabled = item.enabled,
        }
    end
    return out
end)

IL.RegisterCallback("core:ammunition:purchaseItems", function(source, purchaseData, total, paymentMethod)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end
    if not IL.IsTable(purchaseData) or #purchaseData == 0 then
        return { success = false, message = "Panier vide" }
    end

    paymentMethod = IL.Str(paymentMethod, "cash")
    local account = paymentMethod == "bank" and "bank" or "money"

    local catalog = {}
    for i = 1, #Ammunition.items do
        local item = Ammunition.items[i]
        if item.enabled then catalog[item.name] = item end
    end

    local realTotal = 0
    local lines = {}
    for i = 1, #purchaseData do
        local entry = purchaseData[i]
        if not IL.IsTable(entry) then
            return { success = false, message = "Votre panier n'est pas valide" }
        end
        local name = IL.Str(entry.name, nil)
        local quantity = IL.Int(entry.quantity, 0)
        if not name or quantity <= 0 or quantity > 500 then
            return { success = false, message = "Votre panier n'est pas valide" }
        end
        local def = catalog[name]
        if not def then
            return { success = false, message = "Article indisponible" }
        end
        realTotal = realTotal + (def.price * quantity)
        lines[#lines + 1] = { name = name, quantity = quantity }
    end

    if realTotal <= 0 then
        return { success = false, message = "Votre panier n'est pas valide" }
    end

    if IL.AccountMoney(xPlayer, account) < realTotal then
        return { success = false, message = "Fonds insuffisants" }
    end

    for i = 1, #lines do
        if not xPlayer.canCarryItem(lines[i].name, lines[i].quantity) then
            return { success = false, message = "Votre inventaire est plein" }
        end
    end

    if not IL.TakeMoney(xPlayer, account, realTotal, "ammunition") then
        return { success = false, message = "Fonds insuffisants" }
    end

    for i = 1, #lines do
        if not IL.GiveItem(xPlayer, lines[i].name, lines[i].quantity, false) then
            for j = 1, i - 1 do
                IL.TakeItem(xPlayer, lines[j].name, lines[j].quantity)
            end
            IL.GiveMoney(xPlayer, account, realTotal, "ammunition-refund")
            return { success = false, message = "Votre inventaire est plein" }
        end
    end

    return { success = true }
end)
