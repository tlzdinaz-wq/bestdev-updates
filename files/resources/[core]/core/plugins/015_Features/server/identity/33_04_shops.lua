local Cl = VFW.Cloths

local shops = {}
local loaded = false

local VALID_TYPES = {
    clothing = true,
    barber = true,
    tattoo = true,
    mask = true,
}

local function buildEntry(row)
    local position = VFW.DB.Decode(row.position, { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 })
    local chairs = VFW.DB.Decode(row.chairs, {})
    if type(chairs) ~= "table" then chairs = {} end

    return {
        id = row.id,
        shopId = row.id,
        type = row.type,
        position = {
            x = tonumber(position.x) or 0.0,
            y = tonumber(position.y) or 0.0,
            z = tonumber(position.z) or 0.0,
            heading = tonumber(position.heading) or 0.0,
        },
        blip = tonumber(row.blip) or 52,
        blipColor = tonumber(row.blip_color) or 0,
        priceMultiplier = tonumber(row.price_multiplier) or 1.0,
        chairs = chairs,
    }
end

function Cl.LoadShops()
    local rows = MySQL.query.await("SELECT * FROM shops") or {}
    local out = {}
    for i = 1, #rows do
        local entry = buildEntry(rows[i])
        out[entry.id] = entry
    end
    shops = out
    loaded = true
    return shops
end

function Cl.Shops()
    if not loaded then
        Cl.LoadShops()
    end
    return shops
end

function Cl.GetShop(shopId)
    local id = Cl.Int(shopId, nil)
    if not id then return nil end
    return Cl.Shops()[id]
end

function Cl.ShopMultiplier(shopId)
    local shop = Cl.GetShop(shopId)
    if not shop then return 1.0 end
    local mult = tonumber(shop.priceMultiplier) or 1.0
    if mult < 0.0 then mult = 0.0 end
    if mult > 10.0 then mult = 10.0 end
    return mult
end

local function sanitizeChairs(value)
    if type(value) ~= "table" then return {} end
    local out = {}
    for i = 1, #value do
        local chair = value[i]
        if type(chair) == "table" and tonumber(chair.x) and tonumber(chair.y) and tonumber(chair.z) then
            out[#out + 1] = {
                x = tonumber(chair.x),
                y = tonumber(chair.y),
                z = tonumber(chair.z),
                model = tonumber(chair.model) or chair.model,
            }
        end
        if #out >= 32 then break end
    end
    return out
end

local function sanitizePosition(value)
    if type(value) ~= "table" then return nil end
    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z, heading = tonumber(value.heading) or 0.0 }
end

local function pushBarber(target, shop)
    TriggerClientEvent("vfw:barber:add", target, {
        id = shop.id,
        position = shop.position,
        chairs = shop.chairs,
    })
end

function Cl.SyncBarbersTo(source)
    for _, shop in pairs(Cl.Shops()) do
        if shop.type == "barber" then
            pushBarber(source, shop)
        end
    end
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 400 do
        Wait(250)
        tries = tries + 1
    end
    Cl.LoadShops()
end)

AddEventHandler("vfw:playerLoaded", function(source)
    Cl.SyncBarbersTo(source)
end)

RegisterServerCallback("shops:getAll", function(source)
    return Cl.Shops()
end)

RegisterServerCallback("staff:getShops", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return {} end
    return Cl.Shops()
end)

RegisterServerCallback("staff:createShop", function(source, shopData)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return false end
    if type(shopData) ~= "table" then return false end

    local shopType = shopData.type
    if type(shopType) ~= "string" or not VALID_TYPES[shopType] then return false end

    local position = sanitizePosition(shopData.position)
    if not position then return false end

    local multiplier = tonumber(shopData.priceMultiplier) or 1.0
    if multiplier < 0.0 then multiplier = 0.0 end
    if multiplier > 10.0 then multiplier = 10.0 end

    local chairs = sanitizeChairs(shopData.chairs)

    local id = MySQL.insert.await([[
        INSERT INTO shops (type, position, blip, blip_color, price_multiplier, chairs)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        shopType,
        VFW.DB.Encode(position),
        Cl.Int(shopData.blip, 52),
        Cl.Int(shopData.blipColor, 0),
        multiplier,
        VFW.DB.Encode(chairs),
    })

    if not id then return false end

    local entry = {
        id = id,
        shopId = id,
        type = shopType,
        position = position,
        blip = Cl.Int(shopData.blip, 52),
        blipColor = Cl.Int(shopData.blipColor, 0),
        priceMultiplier = multiplier,
        chairs = chairs,
    }

    Cl.Shops()[id] = entry
    TriggerClientEvent("shops:create", -1, id, entry)
    if shopType == "barber" then
        pushBarber(-1, entry)
    end

    return true
end)

RegisterServerCallback("staff:deleteShop", function(source, shopId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return false end

    local id = Cl.Int(shopId, nil)
    if not id then return false end

    local shop = Cl.Shops()[id]
    if not shop then return false end

    MySQL.query.await("DELETE FROM shops WHERE id = ?", { id })
    Cl.Shops()[id] = nil

    TriggerClientEvent("shops:delete", -1, id)
    if shop.type == "barber" then
        TriggerClientEvent("vfw:barber:remove", -1, id)
    end

    return true
end)

RegisterServerCallback("staff:updateShopPosition", function(source, shopId, newPosition)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return false end

    local id = Cl.Int(shopId, nil)
    if not id then return false end

    local shop = Cl.Shops()[id]
    if not shop then return false end

    local position = sanitizePosition(newPosition)
    if not position then return false end

    MySQL.update("UPDATE shops SET position = ? WHERE id = ?", { VFW.DB.Encode(position), id })
    shop.position = position

    TriggerClientEvent("shops:updatePosition", -1, id, position)
    if shop.type == "barber" then
        pushBarber(-1, shop)
    end

    return true
end)

RegisterServerCallback("staff:updateShopPriceMultiplier", function(source, shopId, multiplier)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("staff_menu") then return false end

    local id = Cl.Int(shopId, nil)
    if not id then return false end

    local shop = Cl.Shops()[id]
    if not shop then return false end

    local value = tonumber(multiplier)
    if not value then return false end
    if value < 0.0 then value = 0.0 end
    if value > 10.0 then value = 10.0 end

    MySQL.update("UPDATE shops SET price_multiplier = ? WHERE id = ?", { value, id })
    shop.priceMultiplier = value

    TriggerClientEvent("shops:forceReload", -1)
    return true
end)
