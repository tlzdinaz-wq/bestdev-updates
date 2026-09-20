local BlackMarket = {
    locations = {},
    items = {},
    deliverySpots = {},
    deliveries = {},
}

local BUILDER_PERM = "builder_blackmarket"
local DELIVERY_TTL = 900
local DELIVERY_VEHICLE = "burrito3"

local function LoadLocations()
    BlackMarket.locations = {}
    local rows = IL.Query("SELECT * FROM blackmarket_locations")
    for i = 1, #rows do
        local row = rows[i]
        BlackMarket.locations[row.id] = {
            id = row.id,
            position = {
                x = IL.Num(row.pos_x, 0.0),
                y = IL.Num(row.pos_y, 0.0),
                z = IL.Num(row.pos_z, 0.0),
                h = IL.Num(row.pos_h, 0.0),
            },
            active = IL.Bool(row.active),
        }
    end
end

local function LoadItems()
    BlackMarket.items = {}
    local rows = IL.Query("SELECT * FROM blackmarket_items")
    for i = 1, #rows do
        local row = rows[i]
        local marketId = row.market_id
        BlackMarket.items[marketId] = BlackMarket.items[marketId] or {}
        BlackMarket.items[marketId][row.item_name] = {
            id = row.id,
            market_id = marketId,
            item_name = row.item_name,
            label = row.label,
            transaction_type = row.transaction_type or "buy",
            price = IL.Int(row.price, 0),
            category = row.category or "misc",
            stock_quantity = IL.Int(row.stock_quantity, 0),
            max_quantity = IL.Int(row.max_quantity, 100),
            enabled = row.enabled == nil and true or IL.Bool(row.enabled),
        }
    end
end

local function LoadDeliverySpots()
    BlackMarket.deliverySpots = {}
    local rows = IL.Query("SELECT * FROM blackmarket_delivery_spots WHERE enabled = 1")
    for i = 1, #rows do
        local row = rows[i]
        BlackMarket.deliverySpots[#BlackMarket.deliverySpots + 1] = {
            x = IL.Num(row.pos_x, 0.0),
            y = IL.Num(row.pos_y, 0.0),
            z = IL.Num(row.pos_z, 0.0),
            h = IL.Num(row.pos_h, 0.0),
        }
    end
end

local function PickDeliverySpot(marketId)
    if #BlackMarket.deliverySpots > 0 then
        return BlackMarket.deliverySpots[math.random(1, #BlackMarket.deliverySpots)]
    end
    local market = BlackMarket.locations[marketId]
    if market then
        return { x = market.position.x, y = market.position.y, z = market.position.z, h = market.position.h }
    end
    return nil
end

local function DeleteDeliveryVehicle(delivery)
    if not delivery or not delivery.vehicleEntity then return end
    if DoesEntityExist(delivery.vehicleEntity) then
        DeleteEntity(delivery.vehicleEntity)
    end
    delivery.vehicleEntity = nil
    delivery.vehicleNetId = nil
end

local function CloseDelivery(deliveryId, status)
    local delivery = BlackMarket.deliveries[deliveryId]
    if not delivery then return end
    DeleteDeliveryVehicle(delivery)
    BlackMarket.deliveries[deliveryId] = nil
    IL.Execute("UPDATE blackmarket_deliveries SET status = ? WHERE id = ?", { status or "expired", deliveryId })
end

IL.OnReady(function()
    LoadLocations()
    LoadItems()
    LoadDeliverySpots()
    IL.Execute("UPDATE blackmarket_deliveries SET status = 'expired' WHERE status = 'pending'")
end)

CreateThread(function()
    while true do
        Wait(30000)
        local now = IL.Now()
        for id, delivery in pairs(BlackMarket.deliveries) do
            if now > delivery.expiresAt then
                local target = delivery.source
                CloseDelivery(id, "expired")
                if target then
                    TriggerClientEvent("core:blackmarket:deliveryExpired", target, id)
                end
            end
        end
    end
end)

IL.RegisterCallback("core:blackmarket:getLocations", function(source)
    local out = {}
    for id, market in pairs(BlackMarket.locations) do
        if market.active then
            out[id] = market
        end
    end
    return out
end)

IL.RegisterCallback("core:blackmarket:getItems", function(source, marketId)
    marketId = IL.Int(marketId, nil)
    if not marketId then return {} end
    local out = {}
    local catalog = BlackMarket.items[marketId]
    if not catalog then return out end
    for _, item in pairs(catalog) do
        if item.enabled ~= false then
            out[#out + 1] = {
                id = item.id,
                market_id = item.market_id,
                item_name = item.item_name,
                label = item.label,
                transaction_type = item.transaction_type or "buy",
                price = item.price,
                category = item.category or "misc",
                stock_quantity = item.stock_quantity,
                max_quantity = item.max_quantity or 100,
            }
        end
    end
    return out
end)

RegisterNetEvent("core:blackmarket:buyItems", function(marketId, items)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    marketId = IL.Int(marketId, nil)
    if not marketId or not BlackMarket.locations[marketId] then return end
    if not IL.IsTable(items) then return end

    local catalog = BlackMarket.items[marketId]
    if not catalog then
        IL.Notify(source, "ILLEGAL", "Aucun article disponible.")
        return
    end

    local total = 0
    local lines = {}
    for _, entry in pairs(items) do
        if IL.IsTable(entry) then
            local name = IL.Str(entry.name or entry.itemName, nil)
            local quantity = IL.Int(entry.quantity or entry.count, 0)
            if name and quantity > 0 then
                local def = catalog[name]
                if not def or def.enabled == false or (def.transaction_type ~= "buy" and def.transaction_type ~= "both") then
                    IL.Notify(source, "ILLEGAL", "Article indisponible.")
                    return
                end
                if quantity > def.max_quantity then
                    IL.Notify(source, "ILLEGAL", "Quantite trop elevee.")
                    return
                end
                if def.stock_quantity < quantity then
                    IL.Notify(source, "ILLEGAL", "Stock insuffisant.")
                    return
                end
                total = total + (def.price * quantity)
                lines[#lines + 1] = { name = name, quantity = quantity }
            end
        end
    end

    if #lines == 0 or total <= 0 then return end

    if not IL.TakeMoney(xPlayer, "black_money", total, "blackmarket-buy") then
        IL.Notify(source, "ILLEGAL", "Vous n'avez pas assez d'argent sale.")
        return
    end

    for i = 1, #lines do
        local line = lines[i]
        catalog[line.name].stock_quantity = catalog[line.name].stock_quantity - line.quantity
        IL.Execute("UPDATE blackmarket_items SET stock_quantity = GREATEST(stock_quantity - ?, 0) WHERE market_id = ? AND item_name = ?", {
            line.quantity, marketId, line.name,
        })
    end

    local spot = PickDeliverySpot(marketId)
    if not spot then
        for i = 1, #lines do
            IL.GiveItem(xPlayer, lines[i].name, lines[i].quantity, true)
        end
        IL.Notify(source, "ILLEGAL", "Marchandise remise en main propre.")
        return
    end

    local expiresAt = IL.Now() + DELIVERY_TTL
    local deliveryId = IL.Insert([[
        INSERT INTO blackmarket_deliveries (identifier, market_id, items, pos_x, pos_y, pos_z, pos_h, status, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?)
    ]], {
        xPlayer.identifier, marketId, IL.Encode(lines),
        spot.x, spot.y, spot.z, spot.h, expiresAt,
    })

    if not deliveryId then
        IL.GiveMoney(xPlayer, "black_money", total, "blackmarket-refund")
        return
    end

    BlackMarket.deliveries[deliveryId] = {
        id = deliveryId,
        source = source,
        identifier = xPlayer.identifier,
        marketId = marketId,
        items = lines,
        position = spot,
        expiresAt = expiresAt,
        vehicleEntity = nil,
        vehicleNetId = nil,
    }

    TriggerClientEvent("core:blackmarket:deliveryCreated", source, {
        deliveryId = deliveryId,
        position = spot,
        items = lines,
        vehicleNetId = nil,
    })
end)

RegisterNetEvent("core:blackmarket:sellItems", function(marketId, items)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    marketId = IL.Int(marketId, nil)
    if not marketId or not BlackMarket.locations[marketId] then return end
    if not IL.IsTable(items) then return end

    local catalog = BlackMarket.items[marketId]
    if not catalog then return end

    local total = 0
    local sold = {}
    for _, entry in pairs(items) do
        if IL.IsTable(entry) then
            local name = IL.Str(entry.name or entry.itemName, nil)
            local quantity = IL.Int(entry.quantity or entry.count, 0)
            if name and quantity > 0 then
                local def = catalog[name]
                if not def or def.enabled == false or (def.transaction_type ~= "sell" and def.transaction_type ~= "both") then
                    IL.Notify(source, "ILLEGAL", "Cet article n'est pas rachete ici.")
                    return
                end
                if not xPlayer.haveItem(name, quantity) then
                    IL.Notify(source, "ILLEGAL", "Vous n'avez pas assez de marchandise.")
                    return
                end
                total = total + (def.price * quantity)
                sold[#sold + 1] = { name = name, quantity = quantity }
            end
        end
    end

    if #sold == 0 or total <= 0 then return end

    for i = 1, #sold do
        if not IL.TakeItem(xPlayer, sold[i].name, sold[i].quantity) then
            IL.Notify(source, "ILLEGAL", "Transaction annulee.")
            return
        end
        IL.Execute("UPDATE blackmarket_items SET stock_quantity = stock_quantity + ? WHERE market_id = ? AND item_name = ?", {
            sold[i].quantity, marketId, sold[i].name,
        })
        local def = catalog[sold[i].name]
        if def then def.stock_quantity = def.stock_quantity + sold[i].quantity end
    end

    IL.GiveMoney(xPlayer, "black_money", total, "blackmarket-sell")
    IL.Notify(source, "ILLEGAL", "Marchandise vendue.")
end)

IL.RegisterCallback("core:blackmarket:requestDeliveryVehicleSpawn", function(source, deliveryId)
    deliveryId = IL.Int(deliveryId, nil)
    if not deliveryId then return nil end

    local delivery = BlackMarket.deliveries[deliveryId]
    if not delivery or delivery.source ~= source then return nil end
    if delivery.vehicleNetId and DoesEntityExist(delivery.vehicleEntity) then
        return delivery.vehicleNetId
    end

    local pos = delivery.position
    local vehicle = CreateVehicle(GetHashKey(DELIVERY_VEHICLE), pos.x, pos.y, pos.z, pos.h or 0.0, true, true)
    local attempts = 0
    while not DoesEntityExist(vehicle) and attempts < 50 do
        Wait(20)
        attempts = attempts + 1
    end
    if not DoesEntityExist(vehicle) then return nil end

    delivery.vehicleEntity = vehicle
    delivery.vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    IL.Execute("UPDATE blackmarket_deliveries SET vehicle_net_id = ? WHERE id = ?", { delivery.vehicleNetId, deliveryId })

    return delivery.vehicleNetId
end)

IL.RegisterCallback("core:blackmarket:canPickupDelivery", function(source, deliveryId)
    deliveryId = IL.Int(deliveryId, nil)
    if not deliveryId then return false end

    local xPlayer = IL.Player(source)
    local delivery = BlackMarket.deliveries[deliveryId]
    if not xPlayer or not delivery or delivery.source ~= source then return false end

    for i = 1, #delivery.items do
        if not xPlayer.canCarryItem(delivery.items[i].name, delivery.items[i].quantity) then
            return false
        end
    end
    return true
end)

IL.RegisterCallback("core:blackmarket:pickupDelivery", function(source, deliveryId)
    deliveryId = IL.Int(deliveryId, nil)
    if not deliveryId then return { success = false, message = "Livraison introuvable" } end

    local xPlayer = IL.Player(source)
    local delivery = BlackMarket.deliveries[deliveryId]
    if not xPlayer or not delivery or delivery.source ~= source then
        return { success = false, message = "Livraison introuvable" }
    end
    if delivery.picked then
        return { success = false, message = "Livraison deja recuperee" }
    end

    for i = 1, #delivery.items do
        if not xPlayer.canCarryItem(delivery.items[i].name, delivery.items[i].quantity) then
            return { success = false, message = "Votre inventaire est plein" }
        end
    end

    delivery.picked = true

    for i = 1, #delivery.items do
        IL.GiveItem(xPlayer, delivery.items[i].name, delivery.items[i].quantity, true)
    end

    IL.Execute("UPDATE blackmarket_deliveries SET status = 'picked' WHERE id = ?", { deliveryId })

    return { success = true }
end)

RegisterNetEvent("core:blackmarket:cleanupDeliveryVehicle", function(deliveryId)
    local source = source
    deliveryId = IL.Int(deliveryId, nil)
    if not deliveryId then return end

    local delivery = BlackMarket.deliveries[deliveryId]
    if not delivery or delivery.source ~= source then return end

    CloseDelivery(deliveryId, delivery.picked and "picked" or "expired")
end)

IL.OnPlayerDropped(function(source)
    for id, delivery in pairs(BlackMarket.deliveries) do
        if delivery.source == source then
            CloseDelivery(id, delivery.picked and "picked" or "expired")
        end
    end
end)

local function staffOk(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission(BUILDER_PERM)
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function fail(message)
    return { success = false, ok = false, error = message or "Action impossible." }
end

local function ReadVec(data)
    if type(data) ~= "table" then return nil end
    local src = type(data.coords) == "table" and data.coords or (type(data.position) == "table" and data.position or data)
    if src.x == nil and src.pos_x == nil then return nil end
    return {
        x = IL.Num(src.x or src.pos_x, 0.0),
        y = IL.Num(src.y or src.pos_y, 0.0),
        z = IL.Num(src.z or src.pos_z, 0.0),
        h = IL.Num(src.h or src.heading or src.w or src.pos_h, 0.0),
    }
end

local function ItemsCatalog()
    local out = {}
    for name, def in pairs(VFW.Items or {}) do
        if type(name) == "string" and name ~= "" then
            out[#out + 1] = {
                name = name,
                label = (type(def) == "table" and (def.label or name)) or name,
            }
        end
    end
    table.sort(out, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return out
end

local function MarketRows()
    local rows = IL.Query("SELECT * FROM blackmarket_locations ORDER BY id")
    for i = 1, #rows do
        local row = rows[i]
        row.active = IL.Bool(row.active)
        row.coords = {
            x = IL.Num(row.pos_x, 0.0),
            y = IL.Num(row.pos_y, 0.0),
            z = IL.Num(row.pos_z, 0.0),
            h = IL.Num(row.pos_h, 0.0),
            heading = IL.Num(row.pos_h, 0.0),
            w = IL.Num(row.pos_h, 0.0),
        }
        row.name = "Marché #" .. tostring(row.id)
    end
    return rows
end

local function ItemRows()
    local rows = IL.Query("SELECT * FROM blackmarket_items ORDER BY market_id, item_name")
    for i = 1, #rows do
        rows[i].enabled = IL.Bool(rows[i].enabled)
        rows[i].transaction_type = rows[i].transaction_type or "buy"
        rows[i].max_quantity = IL.Int(rows[i].max_quantity, 100)
    end
    return rows
end

local function DeliveryRows()
    local rows = IL.Query("SELECT * FROM blackmarket_delivery_spots ORDER BY id")
    for i = 1, #rows do
        local row = rows[i]
        row.enabled = IL.Bool(row.enabled)
        row.coords = {
            x = IL.Num(row.pos_x, 0.0),
            y = IL.Num(row.pos_y, 0.0),
            z = IL.Num(row.pos_z, 0.0),
            h = IL.Num(row.pos_h, 0.0),
            heading = IL.Num(row.pos_h, 0.0),
            w = IL.Num(row.pos_h, 0.0),
        }
    end
    return rows
end

local function HubPanel()
    return {
        ok = true,
        success = true,
        markets = MarketRows(),
        items = ItemRows(),
        deliveries = DeliveryRows(),
        catalog = ItemsCatalog(),
    }
end

local function SyncLocationAdded(id)
    LoadLocations()
    if BlackMarket.locations[id] then
        TriggerClientEvent("core:blackmarket:locationAdded", -1, id, BlackMarket.locations[id])
    end
end

local function CreateLocation(data, active)
    local coords = ReadVec(data)
    if not coords then return nil, "Définissez la position." end
    local state = active
    if state == nil then state = true end
    local id = IL.Insert("INSERT INTO blackmarket_locations (pos_x, pos_y, pos_z, pos_h, active) VALUES (?, ?, ?, ?, ?)", {
        coords.x, coords.y, coords.z, coords.h, IL.Bool(state) and 1 or 0,
    })
    if not id then return nil, "Création impossible." end
    SyncLocationAdded(id)
    return id
end

local function UpdateLocation(marketId, data)
    local coords = ReadVec(data)
    if not coords then return false, "Définissez la position." end
    IL.Execute("UPDATE blackmarket_locations SET pos_x = ?, pos_y = ?, pos_z = ?, pos_h = ? WHERE id = ?", {
        coords.x, coords.y, coords.z, coords.h, marketId,
    })
    if data.active ~= nil then
        IL.Execute("UPDATE blackmarket_locations SET active = ? WHERE id = ?", { IL.Bool(data.active) and 1 or 0, marketId })
    end
    LoadLocations()
    local market = BlackMarket.locations[marketId]
    if market then
        TriggerClientEvent("core:blackmarket:locationUpdated", -1, marketId, market.position)
        TriggerClientEvent("core:blackmarket:statusChanged", -1, marketId, market.active)
    end
    return true
end

local function DeleteLocation(marketId)
    IL.Execute("DELETE FROM blackmarket_items WHERE market_id = ?", { marketId })
    IL.Execute("DELETE FROM blackmarket_locations WHERE id = ?", { marketId })
    LoadLocations()
    LoadItems()
    TriggerClientEvent("core:blackmarket:locationDeleted", -1, marketId)
    return true
end

local function SetLocationActive(marketId, active)
    local state = IL.Bool(active)
    IL.Execute("UPDATE blackmarket_locations SET active = ? WHERE id = ?", { state and 1 or 0, marketId })
    LoadLocations()
    TriggerClientEvent("core:blackmarket:statusChanged", -1, marketId, state)
    return true
end

local function UpsertItem(data)
    local marketId = IL.Int(data.market_id or data.marketId, nil)
    local name = IL.Str(data.item_name or data.itemName or data.name, "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if not marketId then return nil, "Choisissez un marché." end
    if name == "" then return nil, "Item obligatoire." end
    if not BlackMarket.locations[marketId] then
        LoadLocations()
        if not BlackMarket.locations[marketId] then return nil, "Marché introuvable." end
    end
    local label = IL.Str(data.label, nil)
    if (not label or label == "") and VFW.Items and VFW.Items[name] then
        label = VFW.Items[name].label or name
    end
    local price = math.max(0, IL.Int(data.price, 0))
    local stock = math.max(0, IL.Int(data.stock_quantity or data.stock, 0))
    local enabled = data.enabled
    if enabled == nil then enabled = true end
    IL.Execute([[
        INSERT INTO blackmarket_items (market_id, item_name, label, price, stock_quantity, enabled)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), price = VALUES(price),
            stock_quantity = VALUES(stock_quantity), enabled = VALUES(enabled)
    ]], { marketId, name:sub(1, 64), label, price, stock, IL.Bool(enabled) and 1 or 0 })
    LoadItems()
    return true
end

local function DeleteItem(itemId)
    local id = IL.Int(itemId, nil)
    if not id then return false, "Item introuvable." end
    IL.Execute("DELETE FROM blackmarket_items WHERE id = ?", { id })
    LoadItems()
    return true
end

local function UpsertDelivery(data)
    local coords = ReadVec(data)
    if not coords then return nil, "Définissez la position." end
    local name = IL.Str(data.name, "Livraison")
    local enabled = data.enabled
    if enabled == nil then enabled = true end
    local id = IL.Int(data.id, nil)
    if id then
        IL.Execute([[
            UPDATE blackmarket_delivery_spots SET name = ?, pos_x = ?, pos_y = ?, pos_z = ?, pos_h = ?, enabled = ?
            WHERE id = ?
        ]], { name, coords.x, coords.y, coords.z, coords.h, IL.Bool(enabled) and 1 or 0, id })
        LoadDeliverySpots()
        return id
    end
    id = IL.Insert([[
        INSERT INTO blackmarket_delivery_spots (name, pos_x, pos_y, pos_z, pos_h, enabled)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { name, coords.x, coords.y, coords.z, coords.h, IL.Bool(enabled) and 1 or 0 })
    if not id then return nil, "Création impossible." end
    LoadDeliverySpots()
    return id
end

RegisterNetEvent("core:blackmarket:createLocation", function(a, b)
    local source = source
    if not staffOk(source) then return end
    local data = a
    if type(a) == "string" and IL.IsTable(b) then
        data = b
    elseif type(a) == "table" and a.x == nil and IL.IsTable(b) then
        data = b
    end
    CreateLocation(data, true)
end)

RegisterNetEvent("core:blackmarket:updateLocation", function(marketId, position)
    local source = source
    if not staffOk(source) then return end
    marketId = IL.Int(marketId, nil)
    if not marketId then return end
    UpdateLocation(marketId, position)
end)

RegisterNetEvent("core:blackmarket:deleteLocation", function(marketId)
    local source = source
    if not staffOk(source) then return end
    marketId = IL.Int(marketId, nil)
    if not marketId then return end
    DeleteLocation(marketId)
end)

RegisterNetEvent("core:blackmarket:setLocationStatus", function(marketId, active)
    local source = source
    if not staffOk(source) then return end
    marketId = IL.Int(marketId, nil)
    if not marketId then return end
    SetLocationActive(marketId, active)
end)

RegisterNetEvent("core:blackmarket:toggleStatus", function(marketId)
    local source = source
    if not staffOk(source) then return end
    marketId = IL.Int(marketId, nil)
    if not marketId then return end
    LoadLocations()
    local market = BlackMarket.locations[marketId]
    if not market then return end
    SetLocationActive(marketId, not market.active)
end)

RegisterNetEvent("core:blackmarket:addItem", function(marketId, itemData)
    local source = source
    if not staffOk(source) then return end
    local payload = IL.IsTable(itemData) and itemData or {}
    payload.market_id = IL.Int(marketId or payload.market_id, nil)
    UpsertItem(payload)
end)

RegisterNetEvent("core:blackmarket:updateItemPrice", function(itemId, price)
    local source = source
    if not staffOk(source) then return end
    itemId = IL.Int(itemId, nil)
    if not itemId then return end
    IL.Execute("UPDATE blackmarket_items SET price = ? WHERE id = ?", { math.max(0, IL.Int(price, 0)), itemId })
    LoadItems()
end)

RegisterNetEvent("core:blackmarket:toggleItemStatus", function(itemId)
    local source = source
    if not staffOk(source) then return end
    itemId = IL.Int(itemId, nil)
    if not itemId then return end
    IL.Execute("UPDATE blackmarket_items SET enabled = IF(enabled = 1, 0, 1) WHERE id = ?", { itemId })
    LoadItems()
end)

RegisterNetEvent("core:blackmarket:deleteItem", function(itemId)
    local source = source
    if not staffOk(source) then return end
    DeleteItem(itemId)
end)

RegisterNetEvent("core:blackmarket:createDeliveryPoint", function(_, position)
    local source = source
    if not staffOk(source) then return end
    UpsertDelivery(position)
end)

RegisterNetEvent("core:blackmarket:updateDeliveryPoint", function(pointId, position)
    local source = source
    if not staffOk(source) then return end
    if IL.IsTable(position) then position.id = pointId end
    UpsertDelivery(position)
end)

RegisterNetEvent("core:blackmarket:deleteDeliveryPoint", function(pointId)
    local source = source
    if not staffOk(source) then return end
    local id = IL.Int(pointId, nil)
    if not id then return end
    IL.Execute("DELETE FROM blackmarket_delivery_spots WHERE id = ?", { id })
    LoadDeliverySpots()
end)

IL.RegisterCallback("core:blackmarket:getDeliveryPoints", function(source)
    if not staffOk(source) then return {} end
    local rows = DeliveryRows()
    local out = {}
    for i = 1, #rows do
        out[#out + 1] = {
            id = rows[i].id,
            position = IL.Encode(rows[i].coords),
        }
    end
    return out
end)

IL.RegisterCallback("gestionBlackmarket:hubPanel", function(source)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer le marché noir." }
    end
    return HubPanel()
end)

IL.RegisterCallback("gestionBlackmarket:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) ~= "table" then return fail("Données invalides.") end
    local action = tostring(data.action or "")
    local err

    if action == "market:create" then
        local id
        id, err = CreateLocation(data, data.active)
        if not id then return fail(err) end
    elseif action == "market:update" then
        local id = IL.Int(data.id, nil)
        if not id then return fail("Marché introuvable.") end
        local ok
        ok, err = UpdateLocation(id, data)
        if not ok then return fail(err) end
    elseif action == "market:delete" then
        local id = IL.Int(data.id, nil)
        if not id then return fail("Marché introuvable.") end
        DeleteLocation(id)
    elseif action == "item:save" then
        local ok
        ok, err = UpsertItem(data)
        if not ok then return fail(err) end
    elseif action == "item:delete" then
        local ok
        ok, err = DeleteItem(data.id)
        if not ok then return fail(err) end
    elseif action == "delivery:save" then
        local id
        id, err = UpsertDelivery(data)
        if not id then return fail(err) end
    elseif action == "delivery:delete" then
        local id = IL.Int(data.id, nil)
        if not id then return fail("Point introuvable.") end
        IL.Execute("DELETE FROM blackmarket_delivery_spots WHERE id = ?", { id })
        LoadDeliverySpots()
    else
        return fail("Action inconnue.")
    end

    local panel = HubPanel()
    panel.success = true
    return panel
end)
