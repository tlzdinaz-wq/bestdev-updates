Feat27 = Feat27 or {}

local npcOwners = {}
local activeNpcRides = {}

local MAX_NPCS_PER_PLAYER = 2
local MAX_SPEED_MPS = 70.0

local function config()
    return (TaxiJob and TaxiJob.Config) or {}
end

local function countNpcs(source)
    local count = 0
    for _, owner in pairs(npcOwners) do
        if owner == source then count = count + 1 end
    end
    return count
end

local function pickNpcModel()
    local models = config().NpcModels
    if type(models) ~= "table" or #models == 0 then
        return "a_m_y_business_01"
    end
    return models[math.random(1, #models)]
end

RegisterNetEvent("taxi:npc:requestSpawn", function(spawnData)
    local source = source
    if type(spawnData) ~= "table" then return end
    if not Feat27.RateLimit(source, "taxi:npcSpawn", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not TaxiServer.IsOnDuty(xPlayer) then
        TriggerClientEvent("taxi:npc:spawnFailed", source)
        return
    end

    if countNpcs(source) >= MAX_NPCS_PER_PLAYER then
        TriggerClientEvent("taxi:npc:spawnFailed", source)
        return
    end

    local coords = Feat27.Vec3(spawnData)
    if not coords then
        TriggerClientEvent("taxi:npc:spawnFailed", source)
        return
    end

    local playerCoords = Feat27.PlayerCoords(source)
    if not playerCoords or #(playerCoords - coords) > 300.0 then
        TriggerClientEvent("taxi:npc:spawnFailed", source)
        return
    end

    local netId = Feat27.SpawnPed(pickNpcModel(), coords, tonumber(spawnData.heading) or 0.0)
    if not netId then
        TriggerClientEvent("taxi:npc:spawnFailed", source)
        return
    end

    npcOwners[netId] = source
    TriggerClientEvent("taxi:npc:spawned", -1, netId, source)
end)

RegisterNetEvent("taxi:npc:requestDespawn", function(netId)
    local source = source
    local id = tonumber(netId)
    if not id then return end

    local owner = npcOwners[id]
    if owner and owner ~= source then
        local xPlayer = VFW.GetPlayerFromId(source)
        if not xPlayer or not xPlayer.hasPermission("gestion") then return end
    end

    npcOwners[id] = nil
    Feat27.DeleteNet(id)
    TriggerClientEvent("taxi:npc:despawned", -1, id)
end)

RegisterNetEvent("taxi:npc:rideStarted", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not TaxiServer.IsOnDuty(xPlayer) then return end

    activeNpcRides[source] = {
        startedAt = GetGameTimer(),
        society = xPlayer.job.name,
    }
end)

RegisterNetEvent("taxi:npc:requestPayment", function(billableDistance, penalty)
    local source = source
    if not Feat27.RateLimit(source, "taxi:npcPay", 2000) then return end

    local ride = activeNpcRides[source]
    if not ride then return end
    activeNpcRides[source] = nil

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not TaxiServer.IsTaxi(xPlayer) then return end

    local cfg = TaxiServer.SocietyConfig(xPlayer.job.name)
    if not cfg then return end

    local defaults = config()

    local distance = tonumber(billableDistance) or 0.0
    if distance < 0.0 then distance = 0.0 end

    local elapsedSeconds = (GetGameTimer() - ride.startedAt) / 1000.0
    local maxDistance = elapsedSeconds * MAX_SPEED_MPS * (defaults.MaxDistanceBuffer or 1.20)
    if maxDistance > 0.0 and distance > maxDistance then distance = maxDistance end
    if distance > 60000.0 then distance = 60000.0 end

    local penaltyPercent = math.floor(tonumber(penalty) or 0)
    if penaltyPercent < 0 then penaltyPercent = 0 end
    local penaltyMax = math.floor(defaults.DamagePenaltyMax or 70)
    if penaltyPercent > penaltyMax then penaltyPercent = penaltyMax end

    local tarif = tonumber(cfg.tarifPerMeter) or (defaults.DefaultTarifPerMeter or 0.50)
    local percent = tonumber(cfg.playerPercent) or (defaults.DefaultPlayerPercent or 80)
    if percent < 0 then percent = 0 end
    if percent > 100 then percent = 100 end

    local totalFare = math.floor(distance * tarif)
    if totalFare < 0 then totalFare = 0 end

    local penaltyAmount = math.floor(totalFare * (penaltyPercent / 100))
    local adjusted = totalFare - penaltyAmount
    if adjusted < 0 then adjusted = 0 end

    local playerCut = math.floor(adjusted * (percent / 100))
    local companyCut = adjusted - playerCut

    if playerCut > 0 then
        xPlayer.addAccountMoney("money", playerCut, "taxi-course-pnj")
    end
    if companyCut > 0 then
        Feat27.Society.AddMoney(xPlayer.job.name, companyCut, "taxi-course-pnj")
    end

    MySQL.insert("INSERT INTO taxi_npc_rides (`identifier`, `society`, `distance`, `total_fare`, `penalty_percent`, `penalty_amount`, `player_cut`, `company_cut`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", {
        xPlayer.identifier, xPlayer.job.name, distance, totalFare, penaltyPercent, penaltyAmount, playerCut, companyCut,
    })

    TriggerClientEvent("taxi:npc:paymentReceived", source, totalFare, playerCut, penaltyAmount)
end)

AddEventHandler("vfw:playerDropped", function(source)
    activeNpcRides[source] = nil
    for netId, owner in pairs(npcOwners) do
        if owner == source then
            npcOwners[netId] = nil
            Feat27.DeleteNet(netId)
            TriggerClientEvent("taxi:npc:despawned", -1, netId)
        end
    end
end)
