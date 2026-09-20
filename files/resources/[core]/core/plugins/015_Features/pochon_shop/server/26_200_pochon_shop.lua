local LB = {}

function LB.Num(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

function LB.Int(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return math.floor(n)
end

function LB.Str(value, fallback)
    if type(value) == "string" then return value end
    return fallback
end

function LB.IsTable(value)
    return type(value) == "table"
end

function LB.Bool(value)
    if value == nil then return false end
    if type(value) == "boolean" then return value end
    if type(value) == "number" then return value ~= 0 end
    if type(value) == "string" then return value == "1" or value == "true" end
    return false
end

function LB.Now()
    return os.time()
end

function LB.Clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function LB.Decode(value, fallback)
    if value == nil then return fallback end
    if type(value) == "table" then return value end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

function LB.Encode(value)
    return json.encode(value)
end

function LB.Query(query, params)
    local ok, result = pcall(function()
        return MySQL.query.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return {}
    end
    return result or {}
end

function LB.Single(query, params)
    local ok, result = pcall(function()
        return MySQL.single.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function LB.Scalar(query, params)
    local ok, result = pcall(function()
        return MySQL.scalar.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function LB.Insert(query, params)
    local ok, result = pcall(function()
        return MySQL.insert.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function LB.Execute(query, params)
    local ok, result = pcall(function()
        return MySQL.update.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return 0
    end
    return result or 0
end

function LB.Player(source)
    if not VFW or not VFW.GetPlayerFromId then return nil end
    return VFW.GetPlayerFromId(source)
end

function LB.Coords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function LB.DistanceTo(source, x, y, z)
    local coords = LB.Coords(source)
    if not coords then return 9999.0 end
    local dx, dy, dz = coords.x - (x or 0.0), coords.y - (y or 0.0), coords.z - (z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function LB.Notify(source, kind, message)
    if not source or not message then return end
    TriggerClientEvent("vfw:showNotification", source, {
        type = kind or "ILLEGAL",
        message = message,
        content = message,
    })
end

function LB.ItemLabel(itemName)
    if VFW and VFW.Items and VFW.Items[itemName] and VFW.Items[itemName].label then
        return VFW.Items[itemName].label
    end
    return itemName
end

function LB.ItemExists(itemName)
    return VFW ~= nil and VFW.Items ~= nil and VFW.Items[itemName] ~= nil
end

function LB.GiveItem(xPlayer, itemName, count, notify)
    if not xPlayer or type(itemName) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end
    if not LB.ItemExists(itemName) then return false end
    if not xPlayer.canCarryItem(itemName, count) then return false end
    return xPlayer.addInventoryItem(itemName, count, nil, notify ~= false)
end

function LB.TakeItem(xPlayer, itemName, count)
    if not xPlayer or type(itemName) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end
    if not xPlayer.haveItem(itemName, count) then return false end
    return xPlayer.removeInventoryItem(itemName, count, nil, true)
end

function LB.AccountMoney(xPlayer, account)
    if not xPlayer then return 0 end
    local acc = xPlayer.getAccount(account)
    return acc and acc.money or 0
end

function LB.GiveMoney(xPlayer, account, amount, reason)
    if not xPlayer or not amount or amount <= 0 then return false end
    xPlayer.addAccountMoney(account, math.floor(amount), reason or "illegal")
    return true
end

function LB.TakeMoney(xPlayer, account, amount, reason)
    if not xPlayer or not amount or amount <= 0 then return false end
    local acc = xPlayer.getAccount(account)
    if not acc or acc.money < amount then return false end
    xPlayer.removeAccountMoney(account, math.floor(amount), reason or "illegal")
    return true
end

function LB.RegisterCallback(name, fn)
    if type(name) ~= "string" or type(fn) ~= "function" then return false end
    local ok, err = pcall(RegisterServerCallback, name, fn)
    if not ok then
        console.warn(("[illegal] impossible d'enregistrer le callback '%s': %s"):format(name, tostring(err)))
        return false
    end
    return true
end

function LB.OnReady(fn)
    if type(fn) ~= "function" then return end
    CreateThread(function()
        local attempts = 0
        while not (VFW and VFW.Ready) and attempts < 200 do
            Wait(250)
            attempts = attempts + 1
        end
        Wait(800)
        local ok, err = pcall(fn)
        if not ok then
            console.warn(("[illegal] erreur d'initialisation: %s"):format(tostring(err)))
        end
    end)
end

function LB.OnPlayerLoaded(fn)
    if type(fn) ~= "function" then return end
    AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
        local src = source
        CreateThread(function()
            Wait(2500)
            pcall(fn, src, xPlayer)
        end)
    end)
end

function LB.OnPlayerDropped(fn)
    if type(fn) ~= "function" then return end
    AddEventHandler("vfw:playerDropped", function(source, xPlayer)
        pcall(fn, source, xPlayer)
    end)
end

local PochonShop = {
    config = { price = 50, dirty_money_price = 75, dirty_money_allowed = false },
}

local BUILDER_PERM = "pochon_shop_builder"
local ITEM_NAME = "pochon_vide"
local MAX_QUANTITY = 250

local function LoadConfig()
    local row = LB.Single("SELECT * FROM pochon_shop_config WHERE id = 1")
    if not row then
        LB.Execute("INSERT IGNORE INTO pochon_shop_config (id, price, dirty_money_price, dirty_money_allowed) VALUES (1, 50, 75, 0)")
        return
    end
    PochonShop.config = {
        price = LB.Int(row.price, 50),
        dirty_money_price = LB.Int(row.dirty_money_price, 75),
        dirty_money_allowed = LB.Bool(row.dirty_money_allowed),
    }
end

local function ConfigPayload()
    return {
        price = PochonShop.config.price,
        dirty_money_price = PochonShop.config.dirty_money_price,
        dirty_money_allowed = PochonShop.config.dirty_money_allowed,
    }
end

LB.OnReady(function()
    LoadConfig()
    TriggerClientEvent("pochonShop:syncConfig", -1, ConfigPayload())
end)

LB.OnPlayerLoaded(function(source)
    TriggerClientEvent("pochonShop:syncConfig", source, ConfigPayload())
end)

LB.RegisterCallback("pochonShop:getShopData", function(source)
    local xPlayer = LB.Player(source)
    if not xPlayer then
        return {
            price = PochonShop.config.price,
            dirtyMoneyPrice = PochonShop.config.dirty_money_price,
            dirty_money_allowed = PochonShop.config.dirty_money_allowed,
            playerMoney = 0,
            playerBank = 0,
            dirtyMoney = 0,
        }
    end

    return {
        price = PochonShop.config.price,
        dirtyMoneyPrice = PochonShop.config.dirty_money_price,
        dirty_money_allowed = PochonShop.config.dirty_money_allowed,
        playerMoney = LB.AccountMoney(xPlayer, "money"),
        playerBank = LB.AccountMoney(xPlayer, "bank"),
        dirtyMoney = LB.AccountMoney(xPlayer, "black_money"),
    }
end)

LB.RegisterCallback("pochonShop:purchase", function(source, quantity, paymentMethod)
    local xPlayer = LB.Player(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end

    local count = LB.Int(quantity, nil)
    if not count or count <= 0 or count > MAX_QUANTITY then
        return { success = false, message = "Cette quantite n'est pas valide" }
    end

    if type(paymentMethod) ~= "string" then
        return { success = false, message = "Ce moyen de paiement n'est pas valide" }
    end

    local account, unitPrice
    if paymentMethod == "dirty" or paymentMethod == "dirty_money" or paymentMethod == "black_money" then
        if not PochonShop.config.dirty_money_allowed then
            return { success = false, message = "L'argent sale n'est pas accepte ici" }
        end
        account = "black_money"
        unitPrice = PochonShop.config.dirty_money_price
    elseif paymentMethod == "bank" then
        account = "bank"
        unitPrice = PochonShop.config.price
    elseif paymentMethod == "cash" or paymentMethod == "money" then
        account = "money"
        unitPrice = PochonShop.config.price
    else
        return { success = false, message = "Ce moyen de paiement n'est pas valide" }
    end

    if unitPrice < 0 then unitPrice = 0 end
    local total = unitPrice * count

    if not LB.ItemExists(ITEM_NAME) then
        return { success = false, message = "Article indisponible" }
    end

    if not xPlayer.canCarryItem(ITEM_NAME, count) then
        return { success = false, message = "Votre inventaire est plein" }
    end

    if total > 0 and not LB.TakeMoney(xPlayer, account, total, "pochon-shop") then
        return { success = false, message = "Fonds insuffisants" }
    end

    if not LB.GiveItem(xPlayer, ITEM_NAME, count, true) then
        if total > 0 then
            LB.GiveMoney(xPlayer, account, total, "pochon-shop-refund")
        end
        return { success = false, message = "Votre inventaire est plein" }
    end

    return { success = true }
end)

LB.RegisterCallback("pochonShop:getConfig", function(source)
    local xPlayer = LB.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer la boutique de pochons." }
    end
    local payload = ConfigPayload()
    payload.ok = true
    payload.success = true
    return payload
end)

LB.RegisterCallback("pochonShop:updatePrice", function(source, price)
    local xPlayer = LB.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then
        return { success = false, ok = false, error = "Permission refusée." }
    end
    TriggerEvent("pochonShop:internal:update", { price = price })
    local payload = ConfigPayload()
    payload.ok = true
    payload.success = true
    return payload
end)

LB.RegisterCallback("pochonShop:updateDirtyMoneyPrice", function(source, price)
    local xPlayer = LB.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then
        return { success = false, ok = false, error = "Permission refusée." }
    end
    TriggerEvent("pochonShop:internal:update", { dirty_money_price = price })
    local payload = ConfigPayload()
    payload.ok = true
    payload.success = true
    return payload
end)

LB.RegisterCallback("pochonShop:updateDirtyMoney", function(source, allowed)
    local xPlayer = LB.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then
        return { success = false, ok = false, error = "Permission refusée." }
    end
    TriggerEvent("pochonShop:internal:update", { dirty_money_allowed = allowed })
    local payload = ConfigPayload()
    payload.ok = true
    payload.success = true
    return payload
end)

LB.RegisterCallback("gestionPochonShop:save", function(source, data)
    local xPlayer = LB.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer la boutique de pochons." }
    end
    TriggerEvent("pochonShop:internal:update", data)
    local payload = ConfigPayload()
    payload.ok = true
    payload.success = true
    return payload
end)

local function ApplyConfig(data)
    if not LB.IsTable(data) then return false end
    local price = PochonShop.config.price
    local dirtyPrice = PochonShop.config.dirty_money_price
    local allowed = PochonShop.config.dirty_money_allowed

    if data.price ~= nil and tonumber(data.price) then
        price = math.max(0, LB.Int(data.price, price))
    end
    if data.dirty_money_price ~= nil and tonumber(data.dirty_money_price) then
        dirtyPrice = math.max(0, LB.Int(data.dirty_money_price, dirtyPrice))
    end
    if data.dirtyMoneyPrice ~= nil and tonumber(data.dirtyMoneyPrice) then
        dirtyPrice = math.max(0, LB.Int(data.dirtyMoneyPrice, dirtyPrice))
    end
    if data.dirty_money_allowed ~= nil then
        allowed = LB.Bool(data.dirty_money_allowed)
    end
    if data.dirtyMoneyAllowed ~= nil then
        allowed = LB.Bool(data.dirtyMoneyAllowed)
    end

    LB.Execute([[
        INSERT INTO pochon_shop_config (id, price, dirty_money_price, dirty_money_allowed)
        VALUES (1, ?, ?, ?)
        ON DUPLICATE KEY UPDATE price = VALUES(price), dirty_money_price = VALUES(dirty_money_price),
            dirty_money_allowed = VALUES(dirty_money_allowed)
    ]], { price, dirtyPrice, allowed and 1 or 0 })

    LoadConfig()
    TriggerClientEvent("pochonShop:syncConfig", -1, ConfigPayload())
    return true
end

AddEventHandler("pochonShop:internal:update", function(data)
    ApplyConfig(data)
end)

RegisterNetEvent("pochonShop:updateConfig", function(data)
    local source = source
    local xPlayer = LB.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    ApplyConfig(data)
end)

RegisterNetEvent("pochonShop:requestConfig", function()
    local source = source
    if not LB.Player(source) then return end
    TriggerClientEvent("pochonShop:syncConfig", source, ConfigPayload())
end)
