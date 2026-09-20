Feat27 = Feat27 or {}

local JOB = "pizza"

local stocks = {}
local carrying = {}
local runs = {}
local cancelCooldowns = {}

local function cfg()
    return InterimServer.GetConfig(JOB) or {}
end

local function pos()
    return InterimServer.GetPositions(JOB) or {}
end

local function maxStock()
    return math.floor(tonumber(cfg().maxStock) or 10)
end

local function stockOf(source)
    return math.floor(tonumber(stocks[source]) or 0)
end

local function nearPoint(source, point, radius)
    local target = Feat27.Vec3(point)
    if not target then return true end
    local coords = Feat27.PlayerCoords(source)
    if not coords then return false end
    return #(coords - target) <= (tonumber(radius) or 3.0)
end

local function nearPizzaiolo(source)
    local p = pos()
    return nearPoint(source, p.startplace, (tonumber(p.startplace_radius) or 2.0) + 3.0)
end

local function vehicleOf(source)
    local bag = InterimServer.Vehicle(source)
    if not bag[JOB] then return nil end
    if not Feat27.EntityFromNet(bag[JOB]) then
        bag[JOB] = nil
        InterimServer.ReleaseSpots(JOB, source)
        return nil
    end
    return bag[JOB]
end

local function nearVehicle(source, radius)
    local netId = vehicleOf(source)
    if not netId then return false end
    local entity = Feat27.EntityFromNet(netId)
    if not entity then return false end
    local coords = Feat27.PlayerCoords(source)
    if not coords then return false end
    return #(coords - GetEntityCoords(entity)) <= (radius or 5.0)
end

local function startService(source) end

local function stopService(source)
    local run = runs[source]
    if run then
        runs[source] = nil
        TriggerClientEvent("interim:pizza:client:cancelled", source, {
            start = pos().startplace,
            msg = "Tournée annulée.",
        })
    end
    stocks[source] = nil
    carrying[source] = nil
end

InterimServer.RegisterService(JOB, { start = startService, stop = stopService })

RegisterServerCallback("interim:pizza:getPositionsAll", function(source)
    local p = pos()
    return {
        startplace = p.startplace,
        startplacenpc = p.startplacenpc,
        startplace_npcheading = p.startplace_npcheading or 180.0,
        startplace_radius = p.startplace_radius or 2.0,
        pickuppoint = p.pickuppoint,
        pickuppoint_radius = p.pickuppoint_radius or 1.75,
        returnpoint = p.returnpoint,
        returnpoint_radius = p.returnpoint_radius or 3.0,
    }
end)

RegisterServerCallback("interim:pizza:getConfig", function(source)
    local c = cfg()
    local p = pos()
    return {
        main = c.main or { pedService = "a_m_m_indian_01" },
        possibleNPCS = c.possibleNPCS or { "a_m_y_business_01", "a_f_y_hipster_01" },
        PositionsPizza = c.PositionsPizza or {
            startplace = { x = (p.startplace and p.startplace.x) or 0.0, y = (p.startplace and p.startplace.y) or 0.0 },
        },
        interactionCircle = c.interactionCircle or {
            doorColor = { r = 255, g = 140, b = 0, a = 120 },
            trunkColor = { r = 255, g = 200, b = 60, a = 120 },
        },
    }
end)

RegisterServerCallback("interim:pizza:getVehicleNetId", function(source)
    local netId = vehicleOf(source)
    if not netId then return false end
    return netId
end)

RegisterServerCallback("interim:pizza:requestvehicle", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not InterimServer.HasJob(xPlayer, JOB) then return false end
    if not Feat27.RateLimit(source, "interim:pz:veh", 3000) then return false end

    local existing = vehicleOf(source)
    if existing then return existing end

    local spots = pos().scooterSpots or {}
    if #spots == 0 then return false end

    for index = 1, #spots do
        if InterimServer.LockSpot(JOB, index, source) then
            local spot = spots[index]
            local netId = Feat27.SpawnVehicle(cfg().vehicle or "faggio2", spot, tonumber(spot.w) or 0.0)
            if netId then
                InterimServer.Vehicle(source)[JOB] = netId
                stocks[source] = 0
                return netId
            end
            InterimServer.ReleaseSpots(JOB, source)
        end
    end

    return false
end)

RegisterNetEvent("interim:pizza:unregisterVehicle", function(netId)
    local source = source
    local id = tonumber(netId)
    if not id then return end

    local bag = InterimServer.Vehicle(source)
    if bag[JOB] ~= id then
        local xPlayer = VFW.GetPlayerFromId(source)
        if not xPlayer or not xPlayer.hasPermission("gestion") then return end
    end

    Feat27.DeleteNet(id)
    bag[JOB] = nil
    stocks[source] = nil
    carrying[source] = nil
    InterimServer.ReleaseSpots(JOB, source)
end)

RegisterServerCallback("interim:pizza:getStockCount", function(source)
    return stockOf(source), maxStock()
end)

RegisterServerCallback("interim:pizza:canPickupPizza", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return false end
    if not Feat27.RateLimit(source, "interim:pz:pickup", 500) then return false end
    if carrying[source] then return false end
    if not nearPizzaiolo(source) then return false end

    carrying[source] = true
    return true
end)

RegisterServerCallback("interim:pizza:canDropPizza", function(source)
    if not carrying[source] then return false end
    carrying[source] = nil
    return true
end)

RegisterServerCallback("interim:pizza:canStockPizza", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return false end
    if not carrying[source] then return false end
    if not nearVehicle(source, 5.0) then return false end
    if stockOf(source) >= maxStock() then return false end

    carrying[source] = nil
    stocks[source] = stockOf(source) + 1
    return true
end)

RegisterServerCallback("interim:pizza:depositToTrunk", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return false end
    if not carrying[source] then return false end
    if not nearVehicle(source, 5.0) then return false end
    if stockOf(source) >= maxStock() then return false end

    carrying[source] = nil
    stocks[source] = stockOf(source) + 1
    return true
end)

RegisterServerCallback("interim:pizza:takeFromTrunk", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return false end
    if carrying[source] then return false end
    if not nearVehicle(source, 5.0) then return false end
    if stockOf(source) <= 0 then return false end

    stocks[source] = stockOf(source) - 1
    carrying[source] = true
    return true
end)

local function deliveryPool()
    local list = pos().deliveryPoints or {}
    local out = {}
    for i = 1, #list do
        local point = list[i]
        if point and point.x and point.y and point.z then
            out[#out + 1] = {
                x = point.x + 0.0,
                y = point.y + 0.0,
                z = point.z + 0.0,
                w = (point.w or 0.0) + 0.0,
            }
        end
    end
    return out
end

RegisterServerCallback("interim:pizza:startDeliveryRun", function(source, stock)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return false end
    if not Feat27.RateLimit(source, "interim:pz:run", 2000) then return false end
    if runs[source] then return false end

    local available = stockOf(source)
    local requested = math.floor(tonumber(stock) or 0)
    if requested < 1 then return false end
    if requested > available then requested = available end
    if requested < 1 then return false end

    local pool = deliveryPool()
    if #pool == 0 then return false end

    local steps = {}
    for i = 1, requested do
        steps[i] = pool[math.random(1, #pool)]
    end

    local run = {
        id = Feat27.Uuid(),
        steps = steps,
        index = 1,
        delivered = 0,
        total = requested,
    }
    runs[source] = run

    return { runId = run.id, total = run.total, next = steps[1] }
end)

RegisterServerCallback("interim:pizza:validateDeliveryAtDoor", function(source, runId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local run = runs[source]
    if not run or run.id ~= runId then return false end
    if not Feat27.RateLimit(source, "interim:pz:deliver", 1000) then return false end
    if not carrying[source] then return false end

    local step = run.steps[run.index]
    if not step then return false end

    local coords = Feat27.PlayerCoords(source)
    if not coords or #(coords - vector3(step.x, step.y, step.z)) > 8.0 then return false end

    carrying[source] = nil
    run.delivered = run.delivered + 1
    run.index = run.index + 1

    local pay = math.floor(tonumber(cfg().payPerDelivery) or 180)
    if pay > 0 then
        xPlayer.addAccountMoney("money", pay, "interim-pizza")
    end

    local nextStep = run.steps[run.index]
    if not nextStep then
        local delivered, total = run.delivered, run.total
        runs[source] = nil
        return { done = true, delivered = delivered, total = total }
    end

    return { done = false, delivered = run.delivered, total = run.total, next = nextStep }
end)

RegisterServerCallback("interim:pizza:cancelRun", function(source, reason)
    local run = runs[source]
    if not run then return false end

    local now = GetGameTimer()
    local last = cancelCooldowns[source]
    local cooldown = math.floor(tonumber(cfg().cancelCooldown) or 60000)
    if last and (now - last) < cooldown then return false end

    cancelCooldowns[source] = now
    runs[source] = nil
    return true
end)

AddEventHandler("vfw:playerDropped", function(source)
    runs[source] = nil
    stocks[source] = nil
    carrying[source] = nil
    cancelCooldowns[source] = nil
end)
