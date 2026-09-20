Feat27 = Feat27 or {}

local JOB = "lumberjack"

local processStates = {}
local sellLoops = {}
local chopping = {}

local function cfg()
    return InterimServer.GetConfig(JOB) or {}
end

local function pos()
    return InterimServer.GetPositions(JOB) or {}
end

local function stateOf(source)
    local state = processStates[source]
    if not state then
        state = { deposited = 0, produced = 0 }
        processStates[source] = state
    end
    return state
end

local function pushState(source)
    local state = stateOf(source)
    TriggerClientEvent("interim:lumberjack:processStateUpdated", source, {
        deposited = state.deposited,
        produced = state.produced,
    })
end

local function woodSpots()
    local list = pos().woodSpots or {}
    local out = {}
    for i = 1, #list do
        local spot = list[i]
        local coords = Feat27.Vec3(spot.coords or spot)
        if coords then
            out[#out + 1] = { coords = coords, radius = tonumber(spot.radius) or 1.5 }
        end
    end
    return out
end

local function processSpots()
    local list = pos().processSpots or {}
    local out = {}
    for i = 1, #list do
        local spot = list[i]
        local coords = Feat27.Vec3(spot.coords or spot)
        if coords then
            out[#out + 1] = { coords = coords, radius = tonumber(spot.radius) or 1.5 }
        end
    end
    return out
end

local function startService(source)
    TriggerClientEvent("interim:lumberjack:setWoodSpots", source, woodSpots())
    TriggerClientEvent("interim:lumberjack:setProcessSpots", source, processSpots())

    local buyer = pos().buyer
    if buyer and buyer.buyerLocation then
        TriggerClientEvent("interim:lumberjack:setBuyer", source, {
            pedBuyer = buyer.pedBuyer or "s_m_y_construct_01",
            buyerLocation = buyer.buyerLocation,
            buyerHeading = tonumber(buyer.buyerHeading) or 0.0,
        })
    end

    pushState(source)
end

local function stopService(source)
    sellLoops[source] = nil
    chopping[source] = nil
    TriggerClientEvent("interim:lumberjack:clearWoodSpots", source)
    TriggerClientEvent("interim:lumberjack:clearProcessSpots", source)
    TriggerClientEvent("interim:lumberjack:clearBuyer", source)
    TriggerClientEvent("interim:lumberjack:stopSell", source)
end

InterimServer.RegisterService(JOB, { start = startService, stop = stopService })

RegisterServerCallback("interim:lumberjack:getPositionsAll", function(source)
    local p = pos()
    return {
        startplace = p.startplace,
        startplacenpc = p.startplacenpc,
        startplace_npcheading = p.startplace_npcheading or 0.0,
        startplace_radius = p.startplace_radius or 2.0,
        returnPoint = p.returnPoint,
        returnpoint = p.returnPoint,
        returnPoint_radius = p.returnPoint_radius or 3.0,
        returnpoint_radius = p.returnPoint_radius or 3.0,
        truckSpots = p.truckSpots or {},
    }
end)

RegisterServerCallback("interim:lumberjack:getConfig", function(source)
    local c = cfg()
    return {
        pedService = c.pedService or "s_m_y_construct_02",
        interactionCircle = c.interactionCircle or {
            color = { r = 0, g = 0, b = 255, a = 255 },
            processColor = { r = 139, g = 69, b = 19, a = 120 },
        },
        animDict = c.animDict,
        animName = c.animName,
        animFlag = c.animFlag,
        processDelay = c.processDelay or 5000,
    }
end)

RegisterServerCallback("interim:lumberjack:getVehicleNetId", function(source)
    local bag = InterimServer.Vehicle(source)
    if not bag[JOB] then return false end
    if not Feat27.EntityFromNet(bag[JOB]) then
        bag[JOB] = nil
        InterimServer.ReleaseSpots(JOB, source)
        return false
    end
    return bag[JOB]
end)

RegisterServerCallback("interim:lumberjack:requestvehicle", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not InterimServer.HasJob(xPlayer, JOB) then return false end
    if not Feat27.RateLimit(source, "interim:lj:veh", 3000) then return false end

    local bag = InterimServer.Vehicle(source)
    if bag[JOB] and Feat27.EntityFromNet(bag[JOB]) then return bag[JOB] end

    local spots = pos().truckSpots or {}
    if #spots == 0 then return false end

    for index = 1, #spots do
        if InterimServer.LockSpot(JOB, index, source) then
            local spot = spots[index]
            local netId = Feat27.SpawnVehicle(cfg().vehicle or "rebel2", spot, tonumber(spot.w) or 0.0)
            if netId then
                bag[JOB] = netId
                return netId
            end
            InterimServer.ReleaseSpots(JOB, source)
        end
    end

    return false
end)

RegisterNetEvent("interim:lumberjack:unregisterVehicle", function(netId)
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
    InterimServer.ReleaseSpots(JOB, source)
end)

RegisterNetEvent("interim:lumberjack:requestChop", function(spotIndex)
    local source = source
    local index = tonumber(spotIndex)
    if not index then return end
    if not Feat27.RateLimit(source, "interim:lj:chop", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if not InterimServer.HasJob(xPlayer, JOB) then
        TriggerClientEvent("interim:lumberjack:notify", source, "ROUGE", "Vous n'êtes pas bûcheron intérimaire.")
        return
    end

    if chopping[source] then return end

    local spots = woodSpots()
    local spot = spots[index]
    if not spot then return end

    local coords = Feat27.PlayerCoords(source)
    if not coords or #(coords - spot.coords) > (spot.radius + 4.0) then
        TriggerClientEvent("interim:lumberjack:notify", source, "ROUGE", "Vous êtes trop loin du spot de récolte.")
        return
    end

    local c = cfg()
    local delay = math.floor(tonumber(c.chopDelay) or 5000)
    local item = c.item or "rawwood"

    if not Feat27.Inv.CanCarry(xPlayer, item, 1) then
        TriggerClientEvent("interim:lumberjack:notify", source, "ROUGE", "Votre inventaire est plein.")
        return
    end

    chopping[source] = true
    TriggerClientEvent("interim:lumberjack:startChopAnim", source, { flag = tonumber(c.animFlag) or 49, delay = delay })

    SetTimeout(delay, function()
        chopping[source] = nil
        local player = VFW.GetPlayerFromId(source)
        if not player then return end

        local newCoords = Feat27.PlayerCoords(source)
        if not newCoords or #(newCoords - spot.coords) > (spot.radius + 6.0) then
            TriggerClientEvent("interim:lumberjack:notify", source, "ROUGE", "Récolte interrompue.")
            return
        end

        if not Feat27.Inv.CanCarry(player, item, 1) then
            TriggerClientEvent("interim:lumberjack:notify", source, "ROUGE", "Votre inventaire est plein.")
            return
        end

        Feat27.Inv.Give(player, item, 1, nil, true)
        TriggerClientEvent("interim:lumberjack:notify", source, "VERT", "Vous avez récolté une bûche.")
    end)
end)

RegisterServerCallback("interim:lumberjack:getProcessState", function(source)
    local state = stateOf(source)
    return { deposited = state.deposited, produced = state.produced }
end)

local function nearProcess(source)
    local coords = Feat27.PlayerCoords(source)
    if not coords then return false end
    local spots = processSpots()
    for i = 1, #spots do
        if #(coords - spots[i].coords) <= (spots[i].radius + 4.0) then return true end
    end
    return false
end

RegisterNetEvent("interim:lumberjack:depositWood", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:lj:deposit", 400) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return end
    if not nearProcess(source) then return end

    local c = cfg()
    local state = stateOf(source)
    local maxDeposit = math.floor(tonumber(c.maxDeposit) or 5)

    if state.deposited >= maxDeposit then
        TriggerClientEvent("interim:lumberjack:notify", source, "JAUNE", "La scierie est pleine.")
        return
    end

    local item = c.item or "rawwood"
    if not Feat27.Inv.Has(xPlayer, item, 1) then
        TriggerClientEvent("interim:lumberjack:notify", source, "ROUGE", "Vous n'avez pas de bûche.")
        return
    end

    if not Feat27.Inv.Take(xPlayer, item, 1, false) then return end

    state.deposited = state.deposited + 1
    pushState(source)
end)

RegisterNetEvent("interim:lumberjack:startProcessing", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:lj:process", 2000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return end
    if not nearProcess(source) then return end

    local state = stateOf(source)
    if state.deposited <= 0 then return end
    if state.processing then return end

    local c = cfg()
    local delay = math.floor(tonumber(c.processDelay) or 5000)
    local perLog = math.floor(tonumber(c.planksPerLog) or 2)

    state.processing = true
    TriggerClientEvent("interim:lumberjack:processStart", source)

    SetTimeout(delay, function()
        local current = processStates[source]
        if not current then return end
        current.processing = nil

        local logs = current.deposited
        current.deposited = 0
        current.produced = current.produced + (logs * perLog)
        pushState(source)
    end)
end)

RegisterNetEvent("interim:lumberjack:collectPlanks", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:lj:collect", 500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return end
    if not nearProcess(source) then return end

    local state = stateOf(source)
    if state.produced <= 0 then return end

    local plank = cfg().plank or "wooden_plank"
    local amount = state.produced

    if not Feat27.Inv.CanCarry(xPlayer, plank, amount) then
        TriggerClientEvent("interim:lumberjack:notify", source, "ROUGE", "Votre inventaire est plein.")
        return
    end

    Feat27.Inv.Give(xPlayer, plank, amount, nil, true)
    state.produced = 0
    pushState(source)
end)

local function buyerCoords()
    local buyer = pos().buyer
    if not buyer then return nil end
    return Feat27.Vec3(buyer.buyerLocation)
end

RegisterNetEvent("interim:lumberjack:startSell", function()
    local source = source
    if sellLoops[source] then return end
    if not Feat27.RateLimit(source, "interim:lj:sell", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return end

    local target = buyerCoords()
    local plank = cfg().plank or "wooden_plank"
    local price = math.floor(tonumber(cfg().sellPrice) or 250)

    if not Feat27.Inv.Has(xPlayer, plank, 1) then
        TriggerClientEvent("interim:lumberjack:notify", source, "ROUGE", "Vous n'avez aucune planche à vendre.")
        TriggerClientEvent("interim:lumberjack:stopSell", source)
        return
    end

    sellLoops[source] = true

    CreateThread(function()
        while sellLoops[source] do
            local player = VFW.GetPlayerFromId(source)
            if not player then break end

            local coords = Feat27.PlayerCoords(source)
            if target and (not coords or #(coords - target) > 6.0) then
                TriggerClientEvent("interim:lumberjack:notify", source, "ROUGE", "Vous vous êtes éloigné de l'acheteur.")
                break
            end

            if not Feat27.Inv.Has(player, plank, 1) then
                TriggerClientEvent("interim:lumberjack:notify", source, "JAUNE", "Vous n'avez plus de planches.")
                break
            end

            if not Feat27.Inv.Take(player, plank, 1, false) then break end

            player.addAccountMoney("money", price, "interim-bucheron")
            TriggerClientEvent("interim:lumberjack:startSellingAnimation", source)

            Wait(2500)
        end

        sellLoops[source] = nil
        TriggerClientEvent("interim:lumberjack:stopSell", source)
    end)
end)

RegisterNetEvent("interim:lumberjack:stopSell", function()
    local source = source
    sellLoops[source] = nil
end)

AddEventHandler("vfw:playerDropped", function(source)
    processStates[source] = nil
    sellLoops[source] = nil
    chopping[source] = nil
end)
