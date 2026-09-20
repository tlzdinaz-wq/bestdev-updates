Feat27 = Feat27 or {}

local JOB = "routier"

local deliveries = {}

local function cfg()
    return InterimServer.GetConfig(JOB) or {}
end

local function pos()
    return InterimServer.GetPositions(JOB) or {}
end

local function vehicleBag(source)
    local bag = InterimServer.Vehicle(source)
    bag[JOB] = bag[JOB] or {}
    return bag[JOB]
end

local function startService(source) end

local function stopService(source)
    local delivery = deliveries[source]
    if delivery then
        deliveries[source] = nil
        TriggerClientEvent("interim:routier:delivery:cleanup", source, { reason = "fin de contrat" })
    end
end

InterimServer.RegisterService(JOB, { start = startService, stop = stopService })

RegisterServerCallback("interim:routier:getPositionsAll", function(source)
    local p = pos()
    return {
        startplace = p.startplace,
        startplace_radius = p.startplace_radius or 3.0,
        returnPoint = p.returnPoint,
        returnpoint = p.returnPoint,
        returnTruckPoint = p.returnTruckPoint,
        returnPoint_radius = p.returnPoint_radius or 5.0,
        returnpoint_radius = p.returnPoint_radius or 5.0,
        truckSpots = p.truckSpots or {},
        trailerSpots = p.trailerSpots or {},
    }
end)

RegisterServerCallback("interim:routier:getConfig", function(source)
    local c = cfg()
    return {
        pedService = c.pedService or "s_m_m_dockwork_01",
        startplacenpc = c.startplacenpc,
        startplace_npcheading = c.startplace_npcheading or 0.0,
        interactionCircle = c.interactionCircle or {
            color = { r = 0, g = 100, b = 0, a = 200 },
            deliveryColor = { r = 70, g = 130, b = 180, a = 120 },
        },
    }
end)

RegisterServerCallback("interim:routier:getVehicleNetId", function(source)
    local bag = vehicleBag(source)

    if bag.truck and not Feat27.EntityFromNet(bag.truck) then bag.truck = nil end
    if bag.trailer and not Feat27.EntityFromNet(bag.trailer) then bag.trailer = nil end

    return { truck = bag.truck, trailer = bag.trailer }
end)

RegisterServerCallback("interim:routier:requestvehicle", function(source, coords, heading, options)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not InterimServer.HasJob(xPlayer, JOB) then return false end

    local kind = type(options) == "table" and options.type or nil
    if kind ~= "truck" and kind ~= "trailer" then return false end

    local target = Feat27.Vec3(coords)
    if not target then return false end

    local spots = kind == "truck" and (pos().truckSpots or {}) or (pos().trailerSpots or {})
    local spotIndex = nil
    for i = 1, #spots do
        local spot = spots[i]
        if #(target - vector3(spot.x, spot.y, spot.z)) <= 4.0 then
            spotIndex = i
            break
        end
    end
    if not spotIndex then return false end

    local lockKey = ("%s:%d"):format(kind, spotIndex)
    if not Feat27.RateLimit(source, "interim:rt:veh:" .. lockKey, 800) then return false end
    if not InterimServer.LockSpot(JOB, lockKey, source) then return false end

    local bag = vehicleBag(source)
    if bag[kind] and Feat27.EntityFromNet(bag[kind]) then
        return bag[kind]
    end

    local model = kind == "truck" and (cfg().truckVehicle or "phantom") or (cfg().trailerVehicle or "trailers")
    local netId = Feat27.SpawnVehicle(model, target, tonumber(heading) or 0.0, kind == "trailer" and "trailer" or "automobile")
    if not netId then
        InterimServer.SpotLocks[JOB][lockKey] = nil
        return false
    end

    bag[kind] = netId
    return netId
end)

RegisterNetEvent("interim:routier:unregisterVehicle", function(netId)
    local source = source
    local id = tonumber(netId)
    if not id then return end

    local bag = vehicleBag(source)
    local matched = false

    for kind, value in pairs(bag) do
        if value == id then
            bag[kind] = nil
            matched = true
        end
    end

    if not matched then
        local xPlayer = VFW.GetPlayerFromId(source)
        if not xPlayer or not xPlayer.hasPermission("gestion") then return end
    end

    Feat27.DeleteNet(id)

    if not bag.truck and not bag.trailer then
        InterimServer.ReleaseSpots(JOB, source)
    end
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
                radius = tonumber(point.radius) or 8.0,
            }
        end
    end
    return out
end

RegisterNetEvent("interim:routier:delivery:requestStart", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:rt:start", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if not InterimServer.HasJob(xPlayer, JOB) then
        TriggerClientEvent("interim:routier:notify", source, "ROUGE", "Vous n'êtes pas routier intérimaire.")
        return
    end

    if deliveries[source] then
        TriggerClientEvent("interim:routier:notify", source, "JAUNE", "Une livraison est déjà en cours.")
        return
    end

    local pool = deliveryPool()
    if #pool == 0 then
        TriggerClientEvent("interim:routier:notify", source, "ROUGE", "Aucun point de livraison configuré.")
        return
    end

    local point = pool[math.random(1, #pool)]
    deliveries[source] = {
        phase = "deliver",
        arrive = { x = point.x, y = point.y, z = point.z },
        radius = point.radius,
        startedAt = GetGameTimer(),
    }

    TriggerClientEvent("interim:routier:delivery:setPhaseDeliver", source, {
        arrive = deliveries[source].arrive,
        radius = point.radius,
    })
end)

RegisterNetEvent("interim:routier:delivery:cancel", function(reason)
    local source = source
    local delivery = deliveries[source]
    if not delivery then return end

    deliveries[source] = nil
    TriggerClientEvent("interim:routier:delivery:cleanup", source, {
        reason = type(reason) == "string" and reason or "annulation",
    })
end)

RegisterNetEvent("interim:routier:delivery:tryDeliver", function(truckNet, trailerNet)
    local source = source
    if not Feat27.RateLimit(source, "interim:rt:deliver", 1000) then return end

    local delivery = deliveries[source]
    if not delivery or delivery.phase ~= "deliver" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return end

    local truck = Feat27.EntityFromNet(truckNet)
    local trailer = Feat27.EntityFromNet(trailerNet)
    if not truck or not trailer then
        TriggerClientEvent("interim:routier:notify", source, "ROUGE", "Camion ou remorque introuvable.")
        return
    end

    local bag = vehicleBag(source)
    if bag.truck ~= tonumber(truckNet) then
        TriggerClientEvent("interim:routier:notify", source, "ROUGE", "Ce camion n'est pas le vôtre.")
        return
    end

    if bag.trailer ~= tonumber(trailerNet) then
        TriggerClientEvent("interim:routier:notify", source, "ROUGE", "Cette remorque n'est pas la vôtre.")
        return
    end

    if #(GetEntityCoords(truck) - GetEntityCoords(trailer)) > 25.0 then
        TriggerClientEvent("interim:routier:notify", source, "ROUGE", "La remorque n'est pas attelée.")
        return
    end

    local arrive = Feat27.Vec3(delivery.arrive)
    if not arrive or #(GetEntityCoords(truck) - arrive) > (delivery.radius + 12.0) then
        TriggerClientEvent("interim:routier:notify", source, "ROUGE", "Vous n'êtes pas sur le point de livraison.")
        return
    end

    delivery.phase = "return"
    delivery.deliveredAt = GetGameTimer()

    TriggerClientEvent("interim:routier:delivery:setPhaseReturn", source, { ok = true })
end)

RegisterNetEvent("interim:routier:delivery:tryReturn", function(continueWork)
    local source = source
    if not Feat27.RateLimit(source, "interim:rt:return", 1000) then return end

    local delivery = deliveries[source]
    if not delivery or delivery.phase ~= "return" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local p = pos()
    local depot = Feat27.Vec3(continueWork and p.returnPoint or p.returnTruckPoint) or Feat27.Vec3(p.returnPoint)
    local coords = Feat27.PlayerCoords(source)
    local radius = (tonumber(p.returnPoint_radius) or 5.0) + 12.0

    if depot and coords and #(coords - depot) > radius then
        TriggerClientEvent("interim:routier:notify", source, "ROUGE", "Vous n'êtes pas au dépôt.")
        return
    end

    local reward = math.floor(tonumber(cfg().reward) or 950)
    if reward > 0 then
        xPlayer.addAccountMoney("money", reward, "interim-routier")
    end

    deliveries[source] = nil
    TriggerClientEvent("interim:routier:delivery:finished", source, { reward = reward })

    if continueWork == true then
        TriggerClientEvent("interim:routier:delivery:prepareNewMission", source)
        return
    end

    local bag = vehicleBag(source)
    for kind, netId in pairs(bag) do
        Feat27.DeleteNet(netId)
        bag[kind] = nil
    end
    InterimServer.ReleaseSpots(JOB, source)
end)

AddEventHandler("vfw:playerDropped", function(source)
    deliveries[source] = nil
end)
