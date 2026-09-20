local Cl = VFW.Cloths

local cache = nil

local function defaults()
    local out = {}
    for g = 1, #Cl.Genders do
        local gender = Cl.Genders[g]
        out[gender] = {}
        for i = 1, #Cl.Categories do
            local entry = Cl.Categories[i]
            out[gender][entry.key] = { label = entry.label, price = entry.price }
        end
    end
    return out
end

local function seed()
    for g = 1, #Cl.Genders do
        local gender = Cl.Genders[g]
        for i = 1, #Cl.Categories do
            local entry = Cl.Categories[i]
            MySQL.insert.await(
                "INSERT IGNORE INTO clothes_prices (sex, category, label, price) VALUES (?, ?, ?, ?)",
                { gender, entry.key, entry.label, entry.price }
            )
        end
    end
end

function Cl.LoadPrices()
    local table1 = defaults()

    local rows = MySQL.query.await("SELECT sex, category, label, price FROM clothes_prices") or {}
    for i = 1, #rows do
        local row = rows[i]
        local gender = Cl.NormalizeGender(row.sex)
        if not table1[gender] then table1[gender] = {} end
        table1[gender][row.category] = {
            label = row.label ~= nil and row.label ~= "" and row.label or row.category,
            price = tonumber(row.price) or 0,
        }
    end

    cache = table1
    return cache
end

function Cl.Prices()
    if not cache then
        Cl.LoadPrices()
    end
    return cache
end

function Cl.PriceOf(gender, category)
    local prices = Cl.Prices()
    local key = Cl.ResolvePriceName(category)
    if not key then return 0 end

    local set = prices[Cl.NormalizeGender(gender)]
    if not set then return 0 end

    local entry = set[key]
    if not entry then return 0 end
    return tonumber(entry.price) or 0
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 400 do
        Wait(250)
        tries = tries + 1
    end
    seed()
    Cl.LoadPrices()
end)

RegisterServerCallback("core:getClothesPrice", function(source, sex)
    local prices = Cl.Prices()

    if sex == nil then
        return prices
    end

    local gender = Cl.NormalizeGender(sex)
    return prices[gender] or prices.Homme or {}
end)

RegisterServerCallback("core:setClothesPrice", function(source, sex, category, price)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not (xPlayer.hasPermission("manage_clothes") or xPlayer.hasPermission("staff_menu")) then
        return false
    end

    if type(category) ~= "string" or category == "" or #category > 32 then return false end

    local gender = Cl.NormalizeGender(sex)
    local value = Cl.Int(price, nil)
    if not value or value < 0 or value > 10000000 then return false end

    local prices = Cl.Prices()
    local current = prices[gender] and prices[gender][category]
    local label = current and current.label or category

    MySQL.query.await([[
        INSERT INTO clothes_prices (sex, category, label, price) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE price = VALUES(price)
    ]], { gender, category, label, value })

    if not prices[gender] then prices[gender] = {} end
    prices[gender][category] = { label = label, price = value }

    return true
end)

RegisterServerCallback("core:server:getClothesPlayerAccounts", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { cash = 0, bank = 0 } end

    return {
        cash = Cl.Balance(xPlayer, "cash"),
        bank = Cl.Balance(xPlayer, "bank"),
    }
end)

RegisterServerCallback("core:server:getClothesMoney", function(source, category, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if type(category) ~= "string" then return false end
    if not Cl.RateLimit(source, "clothesmoney", 250) then return false end

    local method = (paymentMethod == "bank") and "bank" or "cash"
    local gender = Cl.GenderOf(xPlayer)
    local price = Cl.PriceOf(gender, category)

    if not Cl.Charge(xPlayer, method, price, "clothes-" .. category) then
        Cl.Notify(source, "Fonds insuffisants.")
        return false
    end

    return true
end)

RegisterServerCallback("bagweight:getWeightForDrawable", function(source, sex, drawableId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return 10 end

    local drawable = Cl.Int(drawableId, 0)
    local normalized = (sex == "w" or sex == "f" or sex == "Femme") and "w" or "m"

    local Inv = VFW.Inventory
    if Inv and Inv.ResolveBagCapacity then
        local capacity = Inv.ResolveBagCapacity(drawable, normalized)
        capacity = tonumber(capacity) or 0
        if capacity > 0 then return capacity end
    end

    return 10
end)
