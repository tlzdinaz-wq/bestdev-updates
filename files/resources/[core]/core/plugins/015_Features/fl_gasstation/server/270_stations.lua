Feat27 = Feat27 or {}

GasStationServer = GasStationServer or {}

local settings = {
    global_price = 150.0,
    price_min = 100.0,
    price_max = 250.0,
    time_per_liter = 0.5,
}

local stations = {}
local pumps = {}
local loaded = false

local STAFF_PERMISSION = "builder_menu"

local function loadSettings()
    local rows = MySQL.query.await("SELECT `key`, `value` FROM gas_station_settings") or {}
    for i = 1, #rows do
        local row = rows[i]
        settings[row.key] = (tonumber(row.value) or 0) + 0.0
    end
    return settings
end

local function saveSetting(key, value)
    settings[key] = value + 0.0
    MySQL.query.await(
        "INSERT INTO gas_station_settings (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)",
        { key, value }
    )
end

local function loadStations()
    local stationRows = MySQL.query.await("SELECT * FROM gas_stations") or {}
    local pumpRows = MySQL.query.await("SELECT * FROM gas_station_pumps") or {}

    local list = {}
    for i = 1, #stationRows do
        local row = stationRows[i]
        list[row.id] = {
            id = row.id,
            name = row.name or "Station Essence",
            coords = { x = row.coords_x + 0.0, y = row.coords_y + 0.0, z = row.coords_z + 0.0 },
            blipCoords = { x = row.blip_x + 0.0, y = row.blip_y + 0.0, z = row.blip_z + 0.0 },
            pumps = {},
        }
    end

    local flat = {}
    for i = 1, #pumpRows do
        local row = pumpRows[i]
        local station = list[row.station_id]
        local pump = {
            id = row.id,
            stationId = row.station_id,
            coords = vector3(row.coords_x + 0.0, row.coords_y + 0.0, row.coords_z + 0.0),
            model = row.model,
            heading = (row.heading or 0.0) + 0.0,
        }
        flat[#flat + 1] = pump
        if station then
            station.pumps[#station.pumps + 1] = pump
        end
    end

    stations = list
    pumps = flat
    loaded = true
end

local function ensureLoaded()
    if not loaded then pcall(loadStations) end
end

function GasStationServer.GetSettings()
    return settings
end

function GasStationServer.GetPrice()
    return math.floor(tonumber(settings.global_price) or 150)
end

--- Recharge stations + pompes depuis la base (apres une ecriture externe).
function GasStationServer.Reload()
    loadStations()
end

--- Liste des stations chargees, indexee par id.
function GasStationServer.ListStations()
    ensureLoaded()
    return stations
end

function GasStationServer.NearestPump(coords, radius)
    ensureLoaded()
    local best, bestDist = nil, radius or 12.0
    for i = 1, #pumps do
        local dist = #(coords - pumps[i].coords)
        if dist <= bestDist then
            best, bestDist = pumps[i], dist
        end
    end
    return best, bestDist
end

function GasStationServer.StationOf(pump)
    if not pump then return nil end
    ensureLoaded()
    return stations[pump.stationId]
end

local function broadcastSetting(key, value)
    TriggerClientEvent("fl_gasstation:settingUpdated", -1, key, value)
end

RegisterServerCallback("fl_gasstation:getSettings", function(source)
    return {
        global_price = tonumber(settings.global_price) or 150,
        price_min = tonumber(settings.price_min) or 100,
        price_max = tonumber(settings.price_max) or 250,
        time_per_liter = tonumber(settings.time_per_liter) or 0.5,
    }
end)

RegisterServerCallback("fl_gasstation:getGlobalPrice", function(source)
    return GasStationServer.GetPrice()
end)

RegisterServerCallback("fl_gasstation:getStationCount", function(source)
    ensureLoaded()
    local count = 0
    for _ in pairs(stations) do count = count + 1 end
    return count
end)

RegisterServerCallback("fl_gasstation:getStationList", function(source)
    ensureLoaded()
    local out = {}
    for _, station in pairs(stations) do
        local pumpList = {}
        for i = 1, #station.pumps do
            local pump = station.pumps[i]
            pumpList[i] = {
                id = pump.id,
                coords = { x = pump.coords.x, y = pump.coords.y, z = pump.coords.z },
                model = pump.model,
                heading = pump.heading,
            }
        end
        out[#out + 1] = {
            id = station.id,
            name = station.name,
            coords = station.coords,
            pumps = pumpList,
        }
    end
    table.sort(out, function(a, b) return (tonumber(a.id) or 0) < (tonumber(b.id) or 0) end)
    return out
end)

RegisterServerCallback("fl_gasstation:getPumpsNear", function(source, playerPos, radius)
    ensureLoaded()

    local center = Feat27.Vec3(playerPos)
    if not center then return {} end

    local range = tonumber(radius) or 50.0
    if range <= 0 or range > 300.0 then range = 50.0 end

    local out = {}
    for i = 1, #pumps do
        local pump = pumps[i]
        if #(center - pump.coords) <= range then
            out[#out + 1] = {
                id = pump.id,
                stationId = pump.stationId,
                coords = pump.coords,
                model = pump.model,
                heading = pump.heading,
            }
        end
    end
    return out
end)

--- Mode test des pompes (/pumpdebug) : écran en approche et plein gratuit, donc réservé
--- à ceux qui peuvent déjà configurer les stations.
RegisterServerCallback("fl_gasstation:canDebug", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.hasPermission("builder_gas_station")
        or xPlayer.hasPermission("builder")
        or xPlayer.hasPermission("admin") or false
end)

RegisterServerCallback("fl_gasstation:getPlayerMoneyAndPrice", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { pricePerLiter = GasStationServer.GetPrice(), cash = 0, bank = 0 }
    end
    local bank = xPlayer.getAccount("bank")
    return {
        pricePerLiter = GasStationServer.GetPrice(),
        cash = xPlayer.getMoney(),
        bank = bank and bank.money or 0,
    }
end)

RegisterNetEvent("fl_gasstation:requestStationBlips", function()
    local source = source
    if not Feat27.RateLimit(source, "gas:blips", 2000) then return end
    ensureLoaded()
    for _, station in pairs(stations) do
        TriggerClientEvent("fl_gasstation:createBlip", source, {
            id = station.id,
            blipCoords = station.blipCoords,
        })
    end
end)

RegisterNetEvent("fl_gasstation:createStation", function(stationData)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not Feat27.HasStaff(xPlayer, STAFF_PERMISSION) then return end
    if type(stationData) ~= "table" then return end
    if not Feat27.RateLimit(source, "gas:create", 1000) then return end

    local coords = Feat27.Vec3(stationData.coords)
    if not coords then return end
    local blipCoords = Feat27.Vec3(stationData.blipCoords) or coords

    local name = type(stationData.name) == "string" and stationData.name ~= "" and stationData.name or "Station Essence"
    if #name > 64 then name = name:sub(1, 64) end

    local stationId = MySQL.insert.await([[
        INSERT INTO gas_stations (`name`, `coords_x`, `coords_y`, `coords_z`, `blip_x`, `blip_y`, `blip_z`, `created_by`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], { name, coords.x, coords.y, coords.z, blipCoords.x, blipCoords.y, blipCoords.z, xPlayer.identifier })

    if not stationId then return end

    if type(stationData.pumps) == "table" then
        for i = 1, #stationData.pumps do
            local pump = stationData.pumps[i]
            local pumpCoords = type(pump) == "table" and Feat27.Vec3(pump.coords) or nil
            if pumpCoords then
                MySQL.insert.await([[
                    INSERT INTO gas_station_pumps (`station_id`, `coords_x`, `coords_y`, `coords_z`, `model`, `heading`)
                    VALUES (?, ?, ?, ?, ?, ?)
                ]], {
                    stationId, pumpCoords.x, pumpCoords.y, pumpCoords.z,
                    math.floor(tonumber(pump.model) or 0), tonumber(pump.heading) or 0.0,
                })
            end
        end
    end

    loadStations()

    TriggerClientEvent("fl_gasstation:createBlip", -1, {
        id = stationId,
        blipCoords = { x = blipCoords.x, y = blipCoords.y, z = blipCoords.z },
    })
    TriggerClientEvent("fl_gasstation:forceRefreshPumps", -1)
end)

RegisterNetEvent("fl_gasstation:deleteStation", function(stationId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not Feat27.HasStaff(xPlayer, STAFF_PERMISSION) then return end

    local id = tonumber(stationId)
    if not id then return end
    if not Feat27.RateLimit(source, "gas:delete", 500) then return end

    MySQL.query.await("DELETE FROM gas_station_pumps WHERE `station_id` = ?", { id })
    MySQL.query.await("DELETE FROM gas_stations WHERE `id` = ?", { id })
    loadStations()

    TriggerClientEvent("fl_gasstation:deleteBlip", -1, id)
    TriggerClientEvent("fl_gasstation:forceRefreshPumps", -1)
end)

RegisterNetEvent("fl_gasstation:setGlobalPrice", function(newPrice)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not Feat27.HasStaff(xPlayer, STAFF_PERMISSION) then return end

    local price = tonumber(newPrice)
    if not price or price <= 0 or price > 100000 then return end

    saveSetting("global_price", math.floor(price))
    broadcastSetting("global_price", math.floor(price))
end)

RegisterNetEvent("fl_gasstation:setSetting", function(key, value)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not Feat27.HasStaff(xPlayer, STAFF_PERMISSION) then return end

    if key ~= "price_min" and key ~= "price_max" and key ~= "time_per_liter" then return end

    local number = tonumber(value)
    if not number or number <= 0 then return end
    if key == "time_per_liter" and number > 60 then return end
    if key ~= "time_per_liter" and number > 100000 then return end

    saveSetting(key, number)
    broadcastSetting(key, number)
end)

RegisterNetEvent("fl_gasstation:generateRandomPrice", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not Feat27.HasStaff(xPlayer, STAFF_PERMISSION) then return end

    local min = math.floor(tonumber(settings.price_min) or 100)
    local max = math.floor(tonumber(settings.price_max) or 250)
    if max < min then min, max = max, min end

    local price = math.random(min, max)
    saveSetting("global_price", price)
    broadcastSetting("global_price", price)
end)

CreateThread(function()
    while not VFW or not VFW.Ready do Wait(200) end
    local ok, err = pcall(function()
        loadSettings()
        loadStations()
    end)
    if not ok then
        console.warn(("fl_gasstation: initialisation impossible (%s)"):format(tostring(err)))
        return
    end

    local count = 0
    for _ in pairs(stations) do count = count + 1 end
    console.init("fl_gasstation", ("%d station(s), %d pompe(s)"):format(count, #pumps))
end)
