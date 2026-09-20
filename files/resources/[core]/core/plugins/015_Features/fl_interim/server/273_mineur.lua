Feat27 = Feat27 or {}

local JOB = "mineur"

local mining = {}
local cleaning = {}
local sellLoops = {}

local function cfg()
    return InterimServer.GetConfig(JOB) or {}
end

local function pos()
    return InterimServer.GetPositions(JOB) or {}
end

local function ores()
    local list = cfg().ores
    if type(list) ~= "table" or #list == 0 then
        return {
            { dirty = "charcoal_dirty", clean = "charcoal", price = 150, weight = 50 },
            { dirty = "cuivre_dirty", clean = "cuivre", price = 250, weight = 35 },
            { dirty = "gold_dirty", clean = "gold", price = 350, weight = 15 },
        }
    end
    return list
end

local function rollOre()
    local list = ores()
    local total = 0
    for i = 1, #list do total = total + (tonumber(list[i].weight) or 1) end
    if total <= 0 then return list[1] end

    local roll = math.random(1, total)
    local acc = 0
    for i = 1, #list do
        acc = acc + (tonumber(list[i].weight) or 1)
        if roll <= acc then return list[i] end
    end
    return list[#list]
end

local function mineSpots()
    local spots = pos().mineSpots
    if type(spots) ~= "table" then return {} end
    return spots
end

local function startService(source)
    local spots = {}
    for id, spot in pairs(mineSpots()) do
        local coords = Feat27.Vec3(spot)
        if coords then
            spots[id] = { x = coords.x, y = coords.y, z = coords.z, radius = tonumber(spot.radius) or 2.0 }
        end
    end
    TriggerClientEvent("interim:miner:setMineSpots", source, spots)

    local area = pos().cleanArea
    if area then
        TriggerClientEvent("interim:miner:setCleanArea", source, {
            x = area.x + 0.0, y = area.y + 0.0, z = area.z + 0.0,
            radius = tonumber(area.radius) or 30.0,
        })
    end

    local buyer = pos().buyer
    if buyer then
        TriggerClientEvent("interim:miner:setBuyerZone", source, {
            x = buyer.x + 0.0, y = buyer.y + 0.0, z = buyer.z + 0.0,
            heading = tonumber(buyer.heading) or 0.0,
            model = buyer.model or "s_m_y_dockwork_01",
        })
    end
end

local function stopService(source)
    sellLoops[source] = nil
    mining[source] = nil
    cleaning[source] = nil
    TriggerClientEvent("interim:miner:clearMineSpots", source)
    TriggerClientEvent("interim:miner:stopCleaning", source)
    TriggerClientEvent("interim:miner:clearBlip", source)
    TriggerClientEvent("interim:miner:stopSell", source)
end

InterimServer.RegisterService(JOB, { start = startService, stop = stopService })

RegisterServerCallback("interim:miner:getPositionsAll", function(source)
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

RegisterServerCallback("interim:miner:getConfig", function(source)
    local c = cfg()
    return {
        pedService = c.pedService or "s_m_y_dockwork_01",
        interactionCircle = c.interactionCircle or {
            color = { r = 255, g = 200, b = 0, a = 180 },
            processColor = { r = 120, g = 120, b = 120, a = 120 },
        },
    }
end)

RegisterServerCallback("interim:miner:getVehicleNetId", function(source)
    local bag = InterimServer.Vehicle(source)
    if not bag[JOB] then return false end
    if not Feat27.EntityFromNet(bag[JOB]) then
        bag[JOB] = nil
        InterimServer.ReleaseSpots(JOB, source)
        return false
    end
    return bag[JOB]
end)

RegisterServerCallback("interim:miner:requestvehicle", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not InterimServer.HasJob(xPlayer, JOB) then return false end
    if not Feat27.RateLimit(source, "interim:mn:veh", 3000) then return false end

    local bag = InterimServer.Vehicle(source)
    if bag[JOB] and Feat27.EntityFromNet(bag[JOB]) then return bag[JOB] end

    local spots = pos().truckSpots or {}
    if #spots == 0 then return false end

    for index = 1, #spots do
        if InterimServer.LockSpot(JOB, index, source) then
            local spot = spots[index]
            local netId = Feat27.SpawnVehicle(cfg().vehicle or "bison", spot, tonumber(spot.w) or 0.0)
            if netId then
                bag[JOB] = netId
                return netId
            end
            InterimServer.ReleaseSpots(JOB, source)
        end
    end

    return false
end)

RegisterNetEvent("interim:miner:unregisterVehicle", function(netId)
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

RegisterNetEvent("interim:miner:requestMine", function(spotId)
    local source = source
    if spotId == nil then return end
    if not Feat27.RateLimit(source, "interim:mn:mine", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if not InterimServer.HasJob(xPlayer, JOB) then
        TriggerClientEvent("interim:miner:miningCancel", source, "Vous n'êtes pas mineur intérimaire.")
        return
    end

    if mining[source] then return end

    local spots = mineSpots()
    local spot = spots[spotId] or spots[tostring(spotId)] or spots[tonumber(spotId) or -1]
    local target = spot and Feat27.Vec3(spot) or nil

    if not target then
        TriggerClientEvent("interim:miner:miningCancel", source, "Ce filon n'existe pas.")
        return
    end

    local coords = Feat27.PlayerCoords(source)
    if not coords or #(coords - target) > ((tonumber(spot.radius) or 2.0) + 5.0) then
        TriggerClientEvent("interim:miner:miningCancel", source, "Vous êtes trop loin du filon.")
        return
    end

    local c = cfg()
    local delay = math.floor(tonumber(c.miningDelay) or 5000)

    mining[source] = true
    TriggerClientEvent("interim:miner:miningStart", source, {
        dict = c.animDict or "amb@world_human_hammering@male@base",
        name = c.animName or "base",
        delay = delay,
        flag = tonumber(c.animFlag) or 49,
    })

    SetTimeout(delay, function()
        mining[source] = nil
        local player = VFW.GetPlayerFromId(source)
        if not player then return end

        local ore = rollOre()
        if not ore then
            TriggerClientEvent("interim:miner:miningCancel", source, "Le filon est vide.")
            return
        end

        if not Feat27.Inv.CanCarry(player, ore.dirty, 1) then
            TriggerClientEvent("interim:miner:miningCancel", source, "Votre inventaire est plein.")
            return
        end

        Feat27.Inv.Give(player, ore.dirty, 1, nil, true)
        TriggerClientEvent("interim:miner:miningSuccess", source)
    end)
end)

RegisterNetEvent("interim:miner:requestClean", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:mn:clean", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return end
    if cleaning[source] then return end

    local area = pos().cleanArea
    if area then
        local coords = Feat27.PlayerCoords(source)
        local center = Feat27.Vec3(area)
        if center and (not coords or #(coords - center) > ((tonumber(area.radius) or 30.0) + 10.0)) then
            TriggerClientEvent("interim:miner:notify", source, "ROUGE", "Vous n'êtes pas dans la zone de nettoyage.")
            return
        end
    end

    local list = ores()
    local target = nil
    for i = 1, #list do
        if Feat27.Inv.Has(xPlayer, list[i].dirty, 1) then
            target = list[i]
            break
        end
    end

    if not target then
        TriggerClientEvent("interim:miner:notify", source, "ROUGE", "Vous n'avez aucun minerai brut.")
        return
    end

    local c = cfg()
    local delay = math.floor(tonumber(c.cleaningDelay) or 5000)

    cleaning[source] = true
    TriggerClientEvent("interim:miner:cleaningStart", source, {
        dict = c.animDict or "amb@world_human_hammering@male@base",
        name = c.animName or "base",
        flag = tonumber(c.animFlag) or 49,
        delay = delay,
    })

    SetTimeout(delay, function()
        cleaning[source] = nil
        local player = VFW.GetPlayerFromId(source)
        if not player then return end

        if not Feat27.Inv.Has(player, target.dirty, 1) then return end
        if not Feat27.Inv.CanCarry(player, target.clean, 1) then
            TriggerClientEvent("interim:miner:notify", source, "ROUGE", "Votre inventaire est plein.")
            return
        end

        if not Feat27.Inv.Take(player, target.dirty, 1, false) then return end
        Feat27.Inv.Give(player, target.clean, 1, nil, true)
        TriggerClientEvent("interim:miner:notify", source, "VERT", "Minerai nettoyé.")
    end)
end)

local function buildShopData(xPlayer)
    local list = ores()
    local items = {}
    for i = 1, #list do
        local ore = list[i]
        items[#items + 1] = {
            name = ore.clean,
            label = Feat27.Inv.Label(ore.clean),
            count = Feat27.Inv.Count(xPlayer, ore.clean),
            price = math.floor(tonumber(ore.price) or 0),
            image = Feat27.Inv.Image(ore.clean),
        }
    end
    return { title = "Revente de minerais", type = "miner", items = items }
end

RegisterNetEvent("interim:miner:requestShopRefresh", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:mn:shop", 300) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    TriggerClientEvent("interim:miner:shopRefresh", source, buildShopData(xPlayer))
end)

local function buyerPoint()
    local buyer = pos().buyer
    if not buyer then return nil end
    return Feat27.Vec3(buyer)
end

RegisterNetEvent("interim:miner:startSell", function()
    local source = source
    if sellLoops[source] then return end
    if not Feat27.RateLimit(source, "interim:mn:sell", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not InterimServer.HasJob(xPlayer, JOB) then return end

    local target = buyerPoint()
    sellLoops[source] = true

    CreateThread(function()
        local total = 0

        while sellLoops[source] do
            local player = VFW.GetPlayerFromId(source)
            if not player then break end

            local coords = Feat27.PlayerCoords(source)
            if target and (not coords or #(coords - target) > 6.0) then
                TriggerClientEvent("interim:miner:notify", source, "ROUGE", "Vous vous êtes éloigné de l'acheteur.")
                break
            end

            local list = ores()
            local sold = false
            for i = 1, #list do
                local ore = list[i]
                if Feat27.Inv.Has(player, ore.clean, 1) then
                    if Feat27.Inv.Take(player, ore.clean, 1, false) then
                        local price = math.floor(tonumber(ore.price) or 0)
                        player.addAccountMoney("money", price, "interim-mineur")
                        total = total + price
                        sold = true
                    end
                    break
                end
            end

            if not sold then
                TriggerClientEvent("interim:miner:notify", source, "JAUNE", "Vous n'avez plus de minerai propre.")
                break
            end

            TriggerClientEvent("interim:miner:startSellingAnimation", source)
            Wait(2500)
        end

        sellLoops[source] = nil
        TriggerClientEvent("interim:miner:stopSell", source)

        if total > 0 then
            TriggerClientEvent("interim:miner:sellSuccess", source, { total = total })
        end
    end)
end)

RegisterNetEvent("interim:miner:stopSell", function()
    local source = source
    sellLoops[source] = nil
end)

AddEventHandler("vfw:playerDropped", function(source)
    sellLoops[source] = nil
    mining[source] = nil
    cleaning[source] = nil
end)
