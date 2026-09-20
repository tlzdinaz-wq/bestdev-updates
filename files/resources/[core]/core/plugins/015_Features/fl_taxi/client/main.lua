local Config <const> = TaxiJob.Config

-- State machine states
local STATE_IDLE = "IDLE"
local STATE_GOTO_PICKUP = "GOTO_PICKUP"
local STATE_SPAWNING_NPC = "SPAWNING_NPC"
local STATE_WAITING_NPC_SPAWN = "WAITING_NPC_SPAWN"
local STATE_WAITING_PICKUP = "WAITING_PICKUP"
local STATE_NPC_ENTERING = "NPC_ENTERING"
local STATE_DRIVING = "DRIVING"
local STATE_ARRIVING = "ARRIVING"
local STATE_NPC_EXITING = "NPC_EXITING"
local STATE_DROPOFF = "DROPOFF"
local STATE_PAYMENT = "PAYMENT"

local mission = {
    state = STATE_IDLE,
    npcPed = nil,
    npcNetId = nil,
    npcSpawnRequestTime = 0,
    npcBlip = nil,
    destBlip = nil,
    destination = nil,
    totalDistance = 0.0,
    lastPos = nil,
    vehicle = nil,
    active = false,
    enteringTimestamp = 0,
    pickupStartTime = 0,
    pickupLocation = nil,
    dropoffHeading = 0,
    dropoffGroundZ = 0,
    initialHealth = 0,
    maxDistance = 0,
}

-- Cached taxi job detection
local isTaxiJob = false
local missionCooldown = false
local rideCount = 0
local missionStartTime = 0
local societyConfig = nil
local dropoffMarkerActive = false
local sessionEarnings = 0
local sessionStartTime = 0
local cooldownStartTime = 0
local awaitingChoice = false
local lastFare = 0
local lastFareBreakdown = {}
local stoppedCountdown = false
local stoppedStartTime = 0
local STOPPED_GRACE <const> = 5000 -- 5s before timer appears
local STOPPED_TIMEOUT <const> = 15000
local STOPPED_SPEED <const> = 0.5 -- m/s (~1.8 km/h)
local abandonCountdown = false
local abandonStartTime = 0
local ABANDON_TIMEOUT <const> = 15000

local ABANDON_STATES <const> = {
    [STATE_GOTO_PICKUP] = true,
    [STATE_SPAWNING_NPC] = true,
    [STATE_WAITING_NPC_SPAWN] = true,
    [STATE_WAITING_PICKUP] = true,
    [STATE_NPC_ENTERING] = true,
    [STATE_DRIVING] = true,
    [STATE_DROPOFF] = true,
}

-- Allowed taxi vehicle hashes (precomputed)
local allowedVehicleHashes = {}
for _, model in ipairs(Config.AllowedVehicles or {}) do
    allowedVehicleHashes[joaat(model)] = true
end

local function IsAllowedTaxiVehicle(veh)
    if not veh or veh == 0 then return false end
    return allowedVehicleHashes[GetEntityModel(veh)] == true
end

-- Forward declarations (used in GetDashboardState before definition)
local playerRideActive = false
local playerRideClientName = nil
local IsInVehicle

local function FormatDuration(startTime)
    local elapsed = math.floor((GetGameTimer() - startTime) / 1000)
    return ("%02d:%02d"):format(math.floor(elapsed / 60), elapsed % 60)
end

local function GetDamagePenalty()
    if not mission.vehicle or not DoesEntityExist(mission.vehicle) then return 0 end
    if mission.initialHealth <= 0 then return 0 end
    local currentHealth = GetVehicleBodyHealth(mission.vehicle) + GetVehicleEngineHealth(mission.vehicle)
    local healthLost = mission.initialHealth - currentHealth
    local threshold = Config.DamagePenaltyThreshold
    if healthLost <= threshold then return 0 end
    local effectiveDamage = healthLost - threshold
    local maxDamage = mission.initialHealth - threshold
    if maxDamage <= 0 then return 0 end
    local ratio = math.min(1.0, effectiveDamage / maxDamage)
    return math.floor(ratio * Config.DamagePenaltyMax)
end

local function GetDashboardState()
    if abandonCountdown then return "abandoned" end
    if stoppedCountdown and (GetGameTimer() - stoppedStartTime) >= STOPPED_GRACE then return "vehicle_stopped" end
    -- Active driving states take priority
    if mission.active and (mission.state == STATE_DRIVING or mission.state == STATE_DROPOFF
        or mission.state == STATE_ARRIVING or mission.state == STATE_NPC_EXITING) then
        return "driving"
    end
    if playerRideActive then return "player_ride" end
    if awaitingChoice then return "course_complete" end
    if missionCooldown then return "cooldown" end
    if mission.active and (mission.state == STATE_GOTO_PICKUP or mission.state == STATE_WAITING_PICKUP or mission.state == STATE_NPC_ENTERING) then
        return "pickup"
    end
    if mission.active and mission.state == STATE_SPAWNING_NPC then return "searching" end
    if mission.active and mission.state == STATE_IDLE then
        local inVeh, veh = IsInVehicle()
        if not inVeh then return "on_foot" end
        return IsAllowedTaxiVehicle(veh) and "searching" or "wrong_vehicle"
    end
    local inVeh, veh = IsInVehicle()
    if inVeh then
        return IsAllowedTaxiVehicle(veh) and "ready" or "wrong_vehicle"
    end
    return "on_foot"
end

local function GetSessionDuration()
    if sessionStartTime <= 0 then return "00:00" end
    local elapsed = math.floor((GetGameTimer() - sessionStartTime) / 1000)
    return ("%02d:%02d"):format(math.floor(elapsed / 60), elapsed % 60)
end

local function UpdateDashboardUI()
    local dashState = GetDashboardState()
    local data = {
        visible = true,
        state = dashState,
        rideCount = rideCount,
        companyName = societyConfig and societyConfig.label or "Taxi",
        sessionEarnings = sessionEarnings,
        sessionTime = GetSessionDuration(),
    }

    if dashState == "driving" then
        local currentPos = GetEntityCoords(PlayerPedId())
        local remainingDist = 0
        if mission.destination then
            -- Utiliser la distance GPS reelle (meme valeur que le HUD)
            local gpsDist = GetGpsBlipRouteLength()
            if gpsDist and gpsDist > 1 and gpsDist < 50000 then
                remainingDist = gpsDist
            else
                -- Fallback: distance a vol d'oiseau
                remainingDist = #(vector2(currentPos.x, currentPos.y) - vector2(mission.destination.x, mission.destination.y))
            end
        end
        local totalEst = mission.totalDistance + remainingDist
        local progress = totalEst > 0 and (mission.totalDistance / totalEst * 100) or 0
        local tarif = societyConfig and societyConfig.tarifPerMeter or Config.DefaultTarifPerMeter
        local pct = societyConfig and societyConfig.playerPercent or Config.DefaultPlayerPercent

        local billableDistance = mission.maxDistance > 0 and math.min(mission.totalDistance, mission.maxDistance) or mission.totalDistance
        data.fare = billableDistance * tarif
        data.distance = mission.totalDistance
        data.remaining = remainingDist
        data.progress = progress
        data.duration = FormatDuration(missionStartTime)
        data.tarifPerMeter = tarif
        data.playerPercent = pct
        data.damagePenalty = GetDamagePenalty()
    elseif dashState == "player_ride" then
        data.playerName = playerRideClientName or "Client"
    elseif dashState == "cooldown" then
        local elapsed = GetGameTimer() - cooldownStartTime
        data.cooldownProgress = math.min(100, (elapsed / Config.NewNpcCooldown) * 100)
        data.cooldownRemaining = math.max(0, math.ceil((Config.NewNpcCooldown - elapsed) / 1000))
    elseif dashState == "course_complete" then
        data.lastFare = lastFareBreakdown.totalFare or lastFare
        data.playerCut = lastFareBreakdown.playerCut or 0
        data.companyCut = lastFareBreakdown.companyCut or 0
        data.penaltyPercent = lastFareBreakdown.penaltyPercent or 0
        data.penaltyAmount = lastFareBreakdown.penaltyAmount or 0
    elseif dashState == "abandoned" then
        local elapsed = GetGameTimer() - abandonStartTime
        data.abandonRemaining = math.max(0, math.ceil((ABANDON_TIMEOUT - elapsed) / 1000))
        data.abandonProgress = math.min(100, (elapsed / ABANDON_TIMEOUT) * 100)
    elseif dashState == "vehicle_stopped" then
        local elapsed = (GetGameTimer() - stoppedStartTime) - STOPPED_GRACE
        data.stoppedRemaining = math.max(0, math.ceil((STOPPED_TIMEOUT - elapsed) / 1000))
        data.stoppedProgress = math.min(100, (elapsed / STOPPED_TIMEOUT) * 100)
    end

    SendNUIMessage({
        action = "nui:taxiMeter:update",
        data = data,
    })
end

local function HideDashboardUI()
    SendNUIMessage({
        action = "nui:taxiMeter:update",
        data = { visible = false }
    })
end

local function CleanupBlip(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    return nil
end

local function CleanupNpc()
    -- Le ped est networked: c'est le serveur qui le supprime
    if mission.npcNetId then
        TriggerServerEvent("taxi:npc:requestDespawn", mission.npcNetId)
    end
    mission.npcPed = nil
    mission.npcNetId = nil
    mission.npcZFixed = false
    mission.npcSpawnRequestTime = 0
    mission.npcBlip = CleanupBlip(mission.npcBlip)
    mission.destBlip = CleanupBlip(mission.destBlip)
end

local function ResetMission()
    dropoffMarkerActive = false
    CleanupNpc()
    mission.npcBlip = CleanupBlip(mission.npcBlip)
    mission.destBlip = CleanupBlip(mission.destBlip)
    SetWaypointOff()
    mission.state = STATE_IDLE
    mission.destination = nil
    mission.totalDistance = 0.0
    mission.lastPos = nil
    mission.vehicle = nil
    mission.pickupLocation = nil
    mission.dropoffHeading = 0
    mission.dropoffGroundZ = 0
    mission.dropoffX = nil
    mission.dropoffY = nil
    mission.initialHealth = 0
    mission.maxDistance = 0
end

local function RebuildAllowedVehicles()
    allowedVehicleHashes = {}
    local vehicles = societyConfig and societyConfig.allowedVehicles
    if not vehicles or #vehicles == 0 then
        vehicles = Config.AllowedVehicles or {}
    end
    for _, model in ipairs(vehicles) do
        allowedVehicleHashes[joaat(model)] = true
    end
end

local function RefreshTaxiJobStatus()
    local result = TriggerServerCallback("taxi:isJobTaxi")
    isTaxiJob = result == true
    if isTaxiJob then
        societyConfig = TriggerServerCallback("taxi:getSocietyConfig")
        RebuildAllowedVehicles()
    end
end

local function IsOnDutyTaxi()
    if not isTaxiJob then return false end
    local job = VFW.PlayerData.job
    return job and job.onDuty
end

IsInVehicle = function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    return veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped, veh
end

local function CreateNpcBlip(entity)
    local blip = AddBlipForEntity(entity)
    SetBlipSprite(blip, Config.BlipSprite)
    SetBlipColour(blip, Config.BlipColor)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Client Taxi")
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, Config.BlipColor)
    return blip
end

local function CreatePickupBlip(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.BlipSprite)
    SetBlipColour(blip, Config.BlipColor)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Client Taxi")
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, Config.BlipColor)
    return blip
end

local function CreateDestBlip(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, Config.BlipColor)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Destination")
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, Config.BlipColor)
    return blip
end

-- ============================================
-- DESTINATION: Road nodes (pathfinding) pour les destinations lointaines
-- Les road nodes fonctionnent sur toute la map sans streaming
-- Filtre: pas d'autoroute, pas de terre, zone avec trafic
-- ============================================
local HIGHWAY_BIT <const> = 64
local BAD_FLAGS <const> = { [11] = true, [15] = true }

local function IsValidTaxiNode(x, y, z, allowRural)
    local success, density, flags = GetVehicleNodeProperties(x, y, z)
    if not success then return false end
    if not allowRural and density < 1 then return false end
    if flags & HIGHWAY_BIT ~= 0 then return false end
    if BAD_FLAGS[flags] then return false end
    return true
end

local function FindDestinationNode(originX, originY, originZ)
    for attempt = 1, 30 do
        local angle = math.random() * 2 * math.pi
        local distance = Config.DestinationMinDistance + math.random() * (Config.DestinationMaxDistance - Config.DestinationMinDistance)
        local targetX = originX + math.cos(angle) * distance
        local targetY = originY + math.sin(angle) * distance

        local found, nodePos = GetNthClosestVehicleNode(targetX, targetY, 0.0, 1, 0, 0, 0)

        if found and nodePos and nodePos.x ~= 0.0 and nodePos.y ~= 0.0 then
            local actualDist = #(vector2(nodePos.x, nodePos.y) - vector2(originX, originY))
            if actualDist >= Config.DestinationMinDistance * 0.8 and actualDist <= Config.DestinationMaxDistance * 1.2 then
                if IsValidTaxiNode(nodePos.x, nodePos.y, nodePos.z) then
                    return nodePos
                end
            end
        end
    end
    return nil
end

-- ============================================
-- PICKUP: Trouve un point trottoir dans les zones de spawn actives
-- Utilise GetSafeCoordForPed directement dans le rayon de la zone
-- ============================================
local function FindRandomPickupNode()
    local playerPos = GetEntityCoords(PlayerPedId())

    -- S'assurer que la config societe est chargee
    if not societyConfig then
        societyConfig = TriggerServerCallback("taxi:getSocietyConfig")
    end

    -- Construire la liste des zones: base zones activees + zones custom
    local zones = {}
    local enabledBase = societyConfig and societyConfig.enabledBaseZones
    if enabledBase and next(enabledBase) then
        local enabledSet = {}
        for k, v in pairs(enabledBase) do
            if type(k) == "number" then
                enabledSet[v] = true
            else
                enabledSet[k] = v
            end
        end
        for _, bz in ipairs(Config.BaseZones or {}) do
            if enabledSet[bz.key] then
                zones[#zones + 1] = { x = bz.x, y = bz.y, z = bz.z, radius = bz.radius }
            end
        end
    end
    local customZones = societyConfig and societyConfig.taxiSpawnZones
    if customZones then
        for _, cz in ipairs(customZones) do
            zones[#zones + 1] = cz
        end
    end
    if #zones == 0 then
        return nil
    end

    -- Reindexer pour eviter les trous (zones venant de la DB)
    local zoneList = {}
    for _, z in pairs(zones) do zoneList[#zoneList + 1] = z end

    for attempt = 1, 30 do
        -- Choisir une zone aleatoire
        local zone = zoneList[math.random(#zoneList)]
        if not zone then break end
        local zoneRadius = zone.radius or Config.DefaultZoneRadius

        -- Point aleatoire dans le radius (distribution uniforme avec sqrt)
        local angle = math.random() * 2 * math.pi
        local dist = math.sqrt(math.random()) * zoneRadius
        local x = zone.x + math.cos(angle) * dist
        local y = zone.y + math.sin(angle) * dist

        -- Trouver la route pavee la plus proche puis se placer sur le bord
        local nodeFound, nodePos, nodeHeading = GetClosestVehicleNodeWithHeading(x, y, zone.z, 0, 3.0, 0)
        local found = false
        local safeCoords = nil

        if nodeFound and nodePos and nodePos.x ~= 0.0 then
            -- Bord de route (meme methode que les zones de depot)
            local sideFound, sidePos = GetRoadSidePointWithHeading(nodePos.x, nodePos.y, nodePos.z, nodeHeading)
            if sideFound and sidePos and sidePos.x ~= 0.0 then
                local headingRad = math.rad(nodeHeading)
                local perpX = -math.cos(headingRad)
                local perpY = math.sin(headingRad)
                -- Direction: du centre de la route vers le sidePos
                local dirX = sidePos.x - nodePos.x
                local dirY = sidePos.y - nodePos.y
                -- S'assurer qu'on decale dans le bon sens (meme cote que sidePos)
                local dot = dirX * perpX + dirY * perpY
                local sign = dot >= 0 and 1 or -1

                -- Scan progressif jusqu'a sortir de la chaussee (gere les routes larges)
                -- + verif que le sol est au niveau du trottoir (pas un toit, balcon, etc)
                for offset = 3.0, 12.0, 1.0 do
                    local cx = sidePos.x + perpX * offset * sign
                    local cy = sidePos.y + perpY * offset * sign
                    if not IsPointOnRoad(cx, cy, sidePos.z, 0) then
                        local groundOk, gz = GetGroundZFor_3dCoord(cx, cy, sidePos.z + 5.0, false)
                        local zAtSidewalkLevel = groundOk and gz > 0.5 and math.abs(gz - sidePos.z) <= 2.0
                        if zAtSidewalkLevel then
                            safeCoords = vector3(cx, cy, gz)
                            found = true
                            break
                        end
                    end
                end
            end
        end

        if found and safeCoords and safeCoords.x ~= 0.0 and safeCoords.y ~= 0.0 then
            local pos = vector3(safeCoords.x, safeCoords.y, safeCoords.z)
            -- Verifier que le point est bien dans le radius de la zone
            local distFromZone = #(vector2(pos.x, pos.y) - vector2(zone.x, zone.y))
            if distFromZone <= zoneRadius then
                -- Eviter de spawn trop pres du joueur (min 200m)
                local distFromPlayer = #(vector2(playerPos.x, playerPos.y) - vector2(pos.x, pos.y))
                if distFromPlayer >= 200.0 and IsValidTaxiNode(pos.x, pos.y, pos.z, true) then
                    return pos
                end
            else
            end
        end
    end

    return nil
end

-- Demande la network ownership et attend qu'elle soit obtenue (max 2s)
local function RequestControlAndWait(entity, timeoutMs)
    if not entity or not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end

    NetworkRequestControlOfEntity(entity)
    local deadline = GetGameTimer() + (timeoutMs or 2000)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < deadline do
        NetworkRequestControlOfEntity(entity)
        Wait(50)
    end
    return NetworkHasControlOfEntity(entity)
end

-- Attend que l'entite netId soit streamee localement, puis execute callback
local function WaitForNetworkedEntity(netId, onReady)
    CreateThread(function()
        local timeout = GetGameTimer() + 30000
        while GetGameTimer() < timeout do
            if NetworkDoesNetworkIdExist(netId) then
                local entity = NetworkGetEntityFromNetworkId(netId)
                if entity ~= 0 and DoesEntityExist(entity) then
                    onReady(entity)
                    return
                end
            end
            Wait(250)
        end
    end)
end

-- Configure le ped networked (flags d'attente au point de pickup)
-- Doit etre appele par le owner apres avoir acquis la network ownership
local function ConfigureNetworkedTaxiPed(ped)
    if not ped or not DoesEntityExist(ped) then return end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetEntityInvincible(ped, true)
    SetPedCanBeTargetted(ped, false)
    SetPedKeepTask(ped, true)
    SetPedCanRagdoll(ped, false)
    PlaceObjectOnGroundProperly(ped)
    FreezeEntityPosition(ped, true)
end

-- Calcule la position de spawn (Z sol + heading) avant l'envoi serveur
local function ComputeSpawnData(spawnPos)
    -- Charger la collision au point de spawn pour fiabiliser le Z
    RequestCollisionAtCoord(spawnPos.x, spawnPos.y, spawnPos.z)
    NewLoadSceneStart(spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.x, spawnPos.y, spawnPos.z, 50.0, 0)
    local timeout = 0
    while not IsNewLoadSceneLoaded() and timeout < 40 do
        Wait(50)
        timeout = timeout + 1
    end
    NewLoadSceneStop()

    local groundZ = spawnPos.z
    local zFound = false

    local found, gz = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 10.0, false)
    if found and gz > 0.5 then
        groundZ = gz
        zFound = true
    end

    if not zFound then
        local rayHandle = StartShapeTestRay(
            spawnPos.x, spawnPos.y, spawnPos.z + 50.0,
            spawnPos.x, spawnPos.y, spawnPos.z - 50.0,
            1, 0, 4
        )
        Wait(0)
        local _, hit, endCoords = GetShapeTestResult(rayHandle)
        if hit and endCoords.z > 0.5 then
            groundZ = endCoords.z
        end
    end

    local _, _, roadHeading = GetClosestVehicleNodeWithHeading(spawnPos.x, spawnPos.y, groundZ, 0, 3.0, 0)
    local heading = (roadHeading or 0.0) + 90.0

    return { x = spawnPos.x, y = spawnPos.y, z = groundZ, heading = heading }
end

-- Demande au serveur de spawn un ped networked au point indique.
-- Retourne ("requested") ou ("too_far") - le ped sera fourni par l'event "taxi:npc:spawned"
local function RequestNetworkedNpcSpawn(spawnPos)
    local playerPos = GetEntityCoords(PlayerPedId())
    local distToPlayer = #(playerPos - spawnPos)

    -- Ne pas spawn si le joueur est trop loin (collision pas chargee)
    if distToPlayer > 200.0 then
        return false, "too_far"
    end

    local spawnData = ComputeSpawnData(spawnPos)
    TriggerServerEvent("taxi:npc:requestSpawn", spawnData)
    return true, "requested"
end

-- ============================================
-- DROPOFF ZONE: Square marker + 5s timer
-- ============================================
local DROPOFF_EDGE_THICKNESS <const> = 0.15

local function DrawEdgeStrip(ax, ay, bx, by, z, r, g, b, a)
    local dx = bx - ax
    local dy = by - ay
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return end

    local nx = (-dy / len) * (DROPOFF_EDGE_THICKNESS / 2)
    local ny = (dx / len) * (DROPOFF_EDGE_THICKNESS / 2)

    local p1x, p1y = ax + nx, ay + ny
    local p2x, p2y = ax - nx, ay - ny
    local p3x, p3y = bx - nx, by - ny
    local p4x, p4y = bx + nx, by + ny

    DrawPoly(p1x, p1y, z, p2x, p2y, z, p3x, p3y, z, r, g, b, a)
    DrawPoly(p1x, p1y, z, p3x, p3y, z, p4x, p4y, z, r, g, b, a)
    DrawPoly(p3x, p3y, z, p2x, p2y, z, p1x, p1y, z, r, g, b, a)
    DrawPoly(p4x, p4y, z, p3x, p3y, z, p1x, p1y, z, r, g, b, a)
end

local function DrawDropoffRect(cx, cy, z, length, width, heading, r, g, b, a)
    local halfL = length / 2
    local halfW = width / 2
    local rad = math.rad(heading)
    local cosR = math.cos(rad)
    local sinR = math.sin(rad)

    local c = {}
    local offsets = { {-halfW, -halfL}, {halfW, -halfL}, {halfW, halfL}, {-halfW, halfL} }
    for i, off in ipairs(offsets) do
        c[i] = {
            x = cx + off[1] * cosR - off[2] * sinR,
            y = cy + off[1] * sinR + off[2] * cosR,
        }
    end

    DrawEdgeStrip(c[1].x, c[1].y, c[2].x, c[2].y, z, r, g, b, a)
    DrawEdgeStrip(c[2].x, c[2].y, c[3].x, c[3].y, z, r, g, b, a)
    DrawEdgeStrip(c[3].x, c[3].y, c[4].x, c[4].y, z, r, g, b, a)
    DrawEdgeStrip(c[4].x, c[4].y, c[1].x, c[1].y, z, r, g, b, a)
end

local function IsInDropoffZone(px, py, cx, cy, length, width, heading)
    local dx = px - cx
    local dy = py - cy
    local rad = math.rad(-heading)
    local cosR = math.cos(rad)
    local sinR = math.sin(rad)
    local localX = dx * cosR - dy * sinR
    local localY = dx * sinR + dy * cosR
    return math.abs(localX) <= width / 2 and math.abs(localY) <= length / 2
end

local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(sx, sy)
end

local function StopDropoffMarker()
    dropoffMarkerActive = false
end

local function StartDropoffMarker()
    if dropoffMarkerActive then return end
    dropoffMarkerActive = true

    CreateThread(function()
        local cx = mission.dropoffX or mission.destination.x
        local cy = mission.dropoffY or mission.destination.y
        local baseZ = mission.dropoffGroundZ
        local heading = mission.dropoffHeading
        local length = Config.DropoffZoneLength
        local width = Config.DropoffZoneWidth
        local waitTime = Config.DropoffWaitTime

        local timerStart = 0
        local wasInZone = false

        while dropoffMarkerActive and mission.state == STATE_DROPOFF do
            -- Check vehicle still valid
            if not mission.vehicle or not DoesEntityExist(mission.vehicle) then
                break
            end

            -- Check NPC still in vehicle
            if mission.npcPed and DoesEntityExist(mission.npcPed) then
                if not IsPedInVehicle(mission.npcPed, mission.vehicle, false) then
                    break
                end
            end

            local vehPos = GetEntityCoords(mission.vehicle)
            local inZone = IsInDropoffZone(vehPos.x, vehPos.y, cx, cy, length, width, heading)

            local bob = math.sin(GetGameTimer() / 500.0) * 0.06
            local z = baseZ + 0.4 + bob

            if inZone then
                if not wasInZone then
                    timerStart = GetGameTimer()
                    wasInZone = true
                end

                local elapsed = GetGameTimer() - timerStart

                if elapsed >= waitTime then
                    dropoffMarkerActive = false
                    mission.state = STATE_ARRIVING
                    break
                end

                -- Yellow → Green color transition
                local progress = elapsed / waitTime
                local r = math.floor(245 + (52 - 245) * progress)
                local g = math.floor(197 + (199 - 197) * progress)
                local b = math.floor(24 + (89 - 24) * progress)

                DrawDropoffRect(cx, cy, z, length, width, heading, r, g, b, 160)

                local remaining = math.ceil((waitTime - elapsed) / 1000)
                DrawText3D(cx, cy, baseZ + 1.5, ("~y~Depose en cours... %ds"):format(remaining))
            else
                wasInZone = false
                timerStart = 0

                -- Pulsing yellow
                local pulse = (math.sin(GetGameTimer() / 400.0) + 1) / 2
                local alpha = math.floor(100 + pulse * 80)

                DrawDropoffRect(cx, cy, z, length, width, heading, 245, 197, 24, alpha)
                DrawText3D(cx, cy, baseZ + 1.5, "~y~Garez-vous dans la zone")
            end

            Wait(0)
        end

        dropoffMarkerActive = false
    end)
end

-- Distance tracking thread
local trackingActive = false

local function StartDistanceTracking()
    if trackingActive then return end
    trackingActive = true

    CreateThread(function()
        while trackingActive and mission.state == STATE_DRIVING do
            local currentPos = GetEntityCoords(PlayerPedId())
            if mission.lastPos then
                local segmentDist = #(currentPos - mission.lastPos)
                if segmentDist < 100.0 then
                    mission.totalDistance = mission.totalDistance + segmentDist
                end
            end
            mission.lastPos = currentPos
            Wait(Config.DistanceTrackInterval)
        end
        trackingActive = false
    end)
end

local function StopDistanceTracking()
    trackingActive = false
end

-- State machine
local function ProcessStateMachine()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    if mission.state == STATE_IDLE then
        local inVeh, veh = IsInVehicle()
        if not inVeh then
            return
        end
        if not IsAllowedTaxiVehicle(veh) then
            mission.active = false
            return
        end

        mission.vehicle = veh

        -- Trouver un point de pickup aleatoire dans les zones actives
        local pickupNode = FindRandomPickupNode()
        if not pickupNode then
            mission.state = STATE_IDLE
            mission.active = false
            missionCooldown = true
            SetTimeout(Config.SpawnRetryDelay, function()
                missionCooldown = false
                if IsOnDutyTaxi() then
                    mission.active = true
                    mission.state = STATE_IDLE
                end
            end)
            return
        end

        mission.pickupLocation = pickupNode
        mission.npcBlip = CleanupBlip(mission.npcBlip)
        mission.npcBlip = CreatePickupBlip(pickupNode)
        mission.state = STATE_GOTO_PICKUP

    elseif mission.state == STATE_GOTO_PICKUP then
        if not mission.pickupLocation then
            ResetMission()
            return
        end

        local inVeh = IsInVehicle()
        if not inVeh then return end

        local dist = #(vector2(playerPos.x, playerPos.y) - vector2(mission.pickupLocation.x, mission.pickupLocation.y))

        if dist < 150.0 then
            mission.state = STATE_SPAWNING_NPC
        end

    elseif mission.state == STATE_SPAWNING_NPC then
        -- Spawn le PNJ directement au point de pickup (deja un point trottoir)
        local spawnPos = mission.pickupLocation

        if not spawnPos then
            CleanupNpc()
            local pickupNode = FindRandomPickupNode()
            if pickupNode then
                mission.pickupLocation = pickupNode
                mission.npcBlip = CleanupBlip(mission.npcBlip)
                mission.npcBlip = CreatePickupBlip(pickupNode)
                mission.state = STATE_GOTO_PICKUP
            else
                mission.state = STATE_IDLE
            end
            return
        end

        -- Garde: une seule requete de spawn en vol a la fois.
        -- ComputeSpawnData contient des Wait() bloquants, ce qui ouvrait une fenetre
        -- de double-envoi si le tick de 500ms tombait dedans.
        if mission.npcSpawnRequestTime > 0 then
            mission.state = STATE_WAITING_NPC_SPAWN
            return
        end
        mission.npcSpawnRequestTime = GetGameTimer()

        local ok, reason = RequestNetworkedNpcSpawn(spawnPos)
        if reason == "too_far" then
            -- Joueur trop loin, rester en GOTO_PICKUP pour attendre qu'il se rapproche
            mission.npcSpawnRequestTime = 0
            mission.state = STATE_GOTO_PICKUP
            return
        end
        if not ok then
            mission.npcSpawnRequestTime = 0
            mission.npcBlip = CleanupBlip(mission.npcBlip)
            mission.state = STATE_IDLE
            return
        end

        mission.state = STATE_WAITING_NPC_SPAWN

    elseif mission.state == STATE_WAITING_NPC_SPAWN then
        -- Le ped est spawn cote serveur via OneSync, l'event "taxi:npc:spawned"
        -- transitionne vers STATE_WAITING_PICKUP en remplissant mission.npcPed.
        if mission.npcPed and DoesEntityExist(mission.npcPed) then
            mission.state = STATE_WAITING_PICKUP
            return
        end

        -- Timeout 30s: si pas de spawn confirme, on retry
        local elapsed = GetGameTimer() - mission.npcSpawnRequestTime
        if elapsed > 30000 then
            CleanupNpc()
            mission.state = STATE_GOTO_PICKUP
        end

    elseif mission.state == STATE_WAITING_PICKUP then
        if not mission.npcPed or not DoesEntityExist(mission.npcPed) then
            ResetMission()
            return
        end

        -- Recaler le Z du ped au sol (a chaque approche)
        if not mission.npcZFixed then
            local npcPos = GetEntityCoords(mission.npcPed)
            FreezeEntityPosition(mission.npcPed, false)
            PlaceObjectOnGroundProperly(mission.npcPed)
            FreezeEntityPosition(mission.npcPed, true)
            mission.npcZFixed = true
        end

        -- Timeout: si le chauffeur ne recupere pas le client a temps, annuler
        if GetGameTimer() - mission.pickupStartTime > Config.PickupTimeout then
            CleanupNpc()
            -- Nouveau pickup aleatoire
            local pickupNode = FindRandomPickupNode()
            if pickupNode then
                mission.pickupLocation = pickupNode
                mission.npcBlip = CleanupBlip(mission.npcBlip)
                mission.npcBlip = CreatePickupBlip(pickupNode)
                mission.state = STATE_GOTO_PICKUP
            else
                mission.state = STATE_IDLE
            end
            return
        end

        local inVeh, veh = IsInVehicle()
        if not inVeh then return end

        local npcPos = GetEntityCoords(mission.npcPed)
        local dist = #(playerPos - npcPos)

        if dist < Config.PickupRadius then
            mission.vehicle = veh
            mission.npcBlip = CleanupBlip(mission.npcBlip)

            RequestControlAndWait(mission.npcPed)
            RequestControlAndWait(veh)
            SetVehicleDoorsLocked(veh, 1)
            SetPedKeepTask(mission.npcPed, false)
            FreezeEntityPosition(mission.npcPed, false)
            SetBlockingOfNonTemporaryEvents(mission.npcPed, true)
            SetPedFleeAttributes(mission.npcPed, 0, 0)
            ClearPedTasks(mission.npcPed)
            -- Siege arriere: seat index 1 = rear left, 2 = rear right
            local maxPass = GetVehicleMaxNumberOfPassengers(veh)
            local rearSeat
            if maxPass >= 2 then
                rearSeat = math.random(1, 2)
            elseif maxPass >= 1 then
                rearSeat = 0
            else
                rearSeat = 0
            end
            TaskEnterVehicle(mission.npcPed, veh, 15000, rearSeat, 2.0, 1, 0)

            mission.state = STATE_NPC_ENTERING
            mission.enteringTimestamp = GetGameTimer()
            mission.targetSeat = rearSeat
            mission.warpFallbackDone = false
        end

    elseif mission.state == STATE_NPC_ENTERING then
        if not mission.npcPed or not DoesEntityExist(mission.npcPed) then
            ResetMission()
            return
        end

        if IsPedInVehicle(mission.npcPed, mission.vehicle, false) then
            -- Trouver une destination via road nodes (fonctionne a n'importe quelle distance)
            local dest = FindDestinationNode(playerPos.x, playerPos.y, playerPos.z)

            if not dest then
                ResetMission()
                return
            end

            mission.destination = dest
            mission.destBlip = CleanupBlip(mission.destBlip)
            mission.destBlip = CreateDestBlip(dest)
            -- Efface tout waypoint manuel precedent; le route du destBlip prend le relais
            SetWaypointOff()
            mission.totalDistance = 0.0
            mission.lastPos = playerPos

            -- Cap deterministe via la distance route reelle (independante du GPS)
            local roadDist = CalculateTravelDistanceBetweenPoints(
                playerPos.x, playerPos.y, playerPos.z,
                dest.x, dest.y, dest.z
            )
            if roadDist and roadDist > 0 then
                mission.maxDistance = roadDist * (Config.MaxDistanceBuffer or 1.20)
            end

            rideCount = rideCount + 1
            missionStartTime = GetGameTimer()
            -- Note: societyConfig est rafraichi a chaque setJob/menu open, pas besoin de bloquer ici
            TriggerServerEvent("taxi:npc:rideStarted")
            StartDistanceTracking()
            mission.initialHealth = GetVehicleBodyHealth(mission.vehicle) + GetVehicleEngineHealth(mission.vehicle)
            mission.state = STATE_DRIVING
        end

        -- Fallback warp: si apres 5s le NPC n'est toujours pas dans la caisse, on force.
        local elapsed = GetGameTimer() - mission.enteringTimestamp
        if not mission.warpFallbackDone and elapsed > 5000 then
            mission.warpFallbackDone = true
            if not IsPedInVehicle(mission.npcPed, mission.vehicle, false) then
                local inVeh, veh = IsInVehicle()
                if inVeh and DoesEntityExist(veh) then
                    RequestControlAndWait(mission.npcPed)
                    RequestControlAndWait(veh)
                    ClearPedTasks(mission.npcPed)
                    SetPedIntoVehicle(mission.npcPed, veh, mission.targetSeat or 1)
                end
            end
        end

    elseif mission.state == STATE_DRIVING then
        if not mission.destination then
            StopDistanceTracking()
            ResetMission()
            return
        end

        -- Distance 2D (le Z des road nodes distants peut etre approximatif)
        local dist = #(vector2(playerPos.x, playerPos.y) - vector2(mission.destination.x, mission.destination.y))

        if dist < Config.ArrivalRadius then
            StopDistanceTracking()

            -- Get road heading for the dropoff marker
            local _, _, nodeHeading = GetClosestVehicleNodeWithHeading(mission.destination.x, mission.destination.y, mission.destination.z, 1, 3.0, 0)
            mission.dropoffHeading = nodeHeading or 0.0

            -- Offset dropoff zone to roadside (curb) instead of road center
            local found, sidePos = GetRoadSidePointWithHeading(mission.destination.x, mission.destination.y, mission.destination.z, mission.dropoffHeading)
            if found and sidePos then
                mission.dropoffX = sidePos.x
                mission.dropoffY = sidePos.y
                local _, sideGz = GetGroundZFor_3dCoord(sidePos.x, sidePos.y, sidePos.z + 5.0, false)
                mission.dropoffGroundZ = sideGz or mission.destination.z
            else
                mission.dropoffX = mission.destination.x
                mission.dropoffY = mission.destination.y
                local _, gz = GetGroundZFor_3dCoord(mission.destination.x, mission.destination.y, mission.destination.z + 5.0, false)
                mission.dropoffGroundZ = gz or mission.destination.z
            end

            -- Remove GPS route but keep blip visible
            if mission.destBlip and DoesBlipExist(mission.destBlip) then
                SetBlipRoute(mission.destBlip, false)
            end

            mission.state = STATE_DROPOFF
            StartDropoffMarker()
        end

        -- NPC sorti du vehicule
        if mission.npcPed and DoesEntityExist(mission.npcPed) then
            if not IsPedInVehicle(mission.npcPed, mission.vehicle, false) then
                StopDistanceTracking()
                ResetMission()
                return
            end
        end

    elseif mission.state == STATE_DROPOFF then
        -- Marker rendering + timer handled by StartDropoffMarker thread
        -- Here we just validate preconditions
        local inVeh, veh = IsInVehicle()
        if not inVeh then
            dropoffMarkerActive = false
            ResetMission()
            return
        end

        if mission.npcPed and DoesEntityExist(mission.npcPed) then
            if not IsPedInVehicle(mission.npcPed, veh, false) then
                dropoffMarkerActive = false
                ResetMission()
                return
            end
        end

    elseif mission.state == STATE_ARRIVING then
        mission.destBlip = CleanupBlip(mission.destBlip)

        if mission.npcPed and DoesEntityExist(mission.npcPed) then
            RequestControlAndWait(mission.npcPed)
            TaskLeaveVehicle(mission.npcPed, mission.vehicle, 0)
        end

        mission.state = STATE_NPC_EXITING

    elseif mission.state == STATE_NPC_EXITING then
        if not mission.npcPed or not DoesEntityExist(mission.npcPed) then
            mission.state = STATE_PAYMENT
            return
        end

        if not IsPedInVehicle(mission.npcPed, mission.vehicle, false) then
            RequestControlAndWait(mission.npcPed)
            TaskWanderStandard(mission.npcPed, 10.0, 10)

            local netIdToDespawn = mission.npcNetId
            mission.npcPed = nil
            mission.npcNetId = nil

            -- Despawn networked apres delay (le ped marche en attendant)
            SetTimeout(Config.NpcDespawnDelay, function()
                if netIdToDespawn then
                    TriggerServerEvent("taxi:npc:requestDespawn", netIdToDespawn)
                end
            end)

            mission.state = STATE_PAYMENT
        end

    elseif mission.state == STATE_PAYMENT then
        local tarif = societyConfig and societyConfig.tarifPerMeter or Config.DefaultTarifPerMeter
        local pct = societyConfig and societyConfig.playerPercent or Config.DefaultPlayerPercent
        local billableDistance = mission.maxDistance > 0 and math.min(mission.totalDistance, mission.maxDistance) or mission.totalDistance
        local penalty = GetDamagePenalty()
        local totalFare = math.floor(billableDistance * tarif)
        local penaltyAmount = math.floor(totalFare * (penalty / 100))
        local adjustedAmount = totalFare - penaltyAmount
        local playerCut = math.floor(adjustedAmount * (pct / 100))
        local companyCut = adjustedAmount - playerCut

        lastFare = totalFare
        lastFareBreakdown = {
            totalFare = totalFare,
            penaltyPercent = penalty,
            penaltyAmount = penaltyAmount,
            playerCut = playerCut,
            companyCut = companyCut,
        }

        TriggerServerEvent("taxi:npc:requestPayment", billableDistance, penalty)
        mission.state = STATE_IDLE
        mission.destination = nil
        mission.totalDistance = 0.0
        mission.lastPos = nil
        mission.destBlip = CleanupBlip(mission.destBlip)
        mission.npcBlip = CleanupBlip(mission.npcBlip)
        SetWaypointOff()

        mission.active = false
        awaitingChoice = true
        VFW.Nui.Focus(true)
    end
end

-- Payment confirmation
RegisterNetEvent("taxi:npc:paymentReceived", function(totalAmount, playerCut, penaltyAmount)
    sessionEarnings = sessionEarnings + playerCut
end)

-- ============================================
-- Networked NPC events (OneSync)
-- ============================================
RegisterNetEvent("taxi:npc:spawned", function(netId, ownerId)
    -- Tous les clients recoivent l'event, mais seul le owner configure le ped
    local isOwner = (ownerId == GetPlayerServerId(PlayerId()))
    if not isOwner then return end
    if mission.state ~= STATE_WAITING_NPC_SPAWN then return end
    if mission.npcNetId then
        -- Un autre spawn est deja en cours: demander au serveur de despawn ce ped orphelin
        TriggerServerEvent("taxi:npc:requestDespawn", netId)
        return
    end

    mission.npcNetId = netId

    WaitForNetworkedEntity(netId, function(entity)
        -- Verifier que la mission est toujours sur ce netId
        if mission.npcNetId ~= netId then return end

        RequestControlAndWait(entity)
        ConfigureNetworkedTaxiPed(entity)

        -- Remplacer le blip coord par un blip entity, en supprimant toujours l'existant
        if mission.npcBlip and DoesBlipExist(mission.npcBlip) then
            RemoveBlip(mission.npcBlip)
        end
        mission.npcBlip = nil
        mission.npcPed = entity
        mission.npcBlip = CreateNpcBlip(entity)
        mission.pickupStartTime = GetGameTimer()
        -- Le state passera a WAITING_PICKUP au prochain tick du state machine
    end)
end)

RegisterNetEvent("taxi:npc:despawned", function(netId)
    if mission.npcNetId == netId then
        mission.npcPed = nil
        mission.npcNetId = nil
        mission.npcZFixed = false
    end
end)

RegisterNetEvent("taxi:npc:spawnFailed", function()
    if mission.state == STATE_WAITING_NPC_SPAWN then
        mission.npcSpawnRequestTime = 0
        mission.npcNetId = nil
        mission.state = STATE_GOTO_PICKUP
    end
end)

-- Refresh taxi status on player load
CreateThread(function()
    while not VFW.PlayerLoaded do
        Wait(500)
    end
    RefreshTaxiJobStatus()
end)

-- Refresh taxi status when job changes
RegisterNetEvent("vfw:setJob", function()
    RefreshTaxiJobStatus()
    stoppedCountdown = false
    abandonCountdown = false
    if not isTaxiJob and (mission.active or awaitingChoice or sessionStartTime > 0) then
        if awaitingChoice then VFW.Nui.Focus(false) end
        ResetMission()
        HideDashboardUI()
        mission.active = false
        missionCooldown = false
        awaitingChoice = false
        lastFare = 0
        rideCount = 0
        sessionEarnings = 0
        sessionStartTime = 0
    end
end)

-- Main loop
CreateThread(function()
    while not VFW.PlayerLoaded do
        Wait(500)
    end

    while true do
        if IsOnDutyTaxi() then
            if sessionStartTime <= 0 then
                sessionStartTime = GetGameTimer()
            end

            -- Stopped detection: vehicle not moving during DRIVING
            if stoppedCountdown then
                if not mission.active or mission.state ~= STATE_DRIVING then
                    stoppedCountdown = false
                else
                    local speed = mission.vehicle and DoesEntityExist(mission.vehicle) and GetEntitySpeed(mission.vehicle) or 0
                    if speed >= STOPPED_SPEED then
                        stoppedCountdown = false
                    else
                        local elapsed = GetGameTimer() - stoppedStartTime
                        if elapsed >= STOPPED_GRACE + STOPPED_TIMEOUT then
                            stoppedCountdown = false
                            StopDistanceTracking()
                            StopDropoffMarker()

                            if mission.npcPed and DoesEntityExist(mission.npcPed) then
                                if mission.vehicle and DoesEntityExist(mission.vehicle) and IsPedInVehicle(mission.npcPed, mission.vehicle, false) then
                                    RequestControlAndWait(mission.npcPed)
                                    TaskLeaveVehicle(mission.npcPed, mission.vehicle, 4160)
                                    local npcRef = mission.npcPed
                                    local netIdRef = mission.npcNetId
                                    mission.npcPed = nil
                                    mission.npcNetId = nil
                                    SetTimeout(1500, function()
                                        if npcRef and DoesEntityExist(npcRef) then
                                            RequestControlAndWait(npcRef)
                                            TaskWanderStandard(npcRef, 10.0, 10)
                                        end
                                        SetTimeout(Config.NpcDespawnDelay, function()
                                            if netIdRef then
                                                TriggerServerEvent("taxi:npc:requestDespawn", netIdRef)
                                            end
                                        end)
                                    end)
                                else
                                    CleanupNpc()
                                end
                            end

                            mission.npcBlip = CleanupBlip(mission.npcBlip)
                            mission.destBlip = CleanupBlip(mission.destBlip)
                            SetWaypointOff()
                            dropoffMarkerActive = false
                            mission.state = STATE_IDLE
                            mission.destination = nil
                            mission.totalDistance = 0.0
                            mission.lastPos = nil
                            mission.vehicle = nil
                            mission.pickupLocation = nil
                            mission.initialHealth = 0
                            mission.active = false
                        end
                    end
                end
            elseif mission.active and mission.state == STATE_DRIVING and not abandonCountdown then
                local speed = mission.vehicle and DoesEntityExist(mission.vehicle) and GetEntitySpeed(mission.vehicle) or 0
                if speed < STOPPED_SPEED then
                    stoppedCountdown = true
                    stoppedStartTime = GetGameTimer()
                end
            end

            -- Abandon detection: player left vehicle during active mission
            if mission.active and not abandonCountdown and ABANDON_STATES[mission.state] then
                local inVeh = IsInVehicle()
                if not inVeh then
                    abandonCountdown = true
                    abandonStartTime = GetGameTimer()
                    StopDistanceTracking()
                    StopDropoffMarker()
                end
            end

            -- Abandon handling
            if abandonCountdown then
                local inVeh, veh = IsInVehicle()
                if inVeh and mission.vehicle and veh == mission.vehicle then
                    -- Player returned to same vehicle: resume
                    abandonCountdown = false
                    if mission.state == STATE_DRIVING then
                        mission.lastPos = GetEntityCoords(PlayerPedId())
                        StartDistanceTracking()
                    elseif mission.state == STATE_DROPOFF then
                        StartDropoffMarker()
                    end
                elseif not mission.vehicle or not DoesEntityExist(mission.vehicle) then
                    -- Vehicle gone: abort immediately
                    abandonCountdown = false
                    CleanupNpc()
                    ResetMission()
                    mission.active = false
                else
                    local elapsed = GetGameTimer() - abandonStartTime
                    if elapsed >= ABANDON_TIMEOUT then
                        -- 15s expired: abort mission, NPC leaves
                        abandonCountdown = false

                        if mission.npcPed and DoesEntityExist(mission.npcPed) then
                            if mission.vehicle and DoesEntityExist(mission.vehicle) and IsPedInVehicle(mission.npcPed, mission.vehicle, false) then
                                RequestControlAndWait(mission.npcPed)
                                TaskLeaveVehicle(mission.npcPed, mission.vehicle, 4160)
                                local npcRef = mission.npcPed
                                local netIdRef = mission.npcNetId
                                mission.npcPed = nil
                                mission.npcNetId = nil
                                SetTimeout(1500, function()
                                    if npcRef and DoesEntityExist(npcRef) then
                                        RequestControlAndWait(npcRef)
                                        TaskWanderStandard(npcRef, 10.0, 10)
                                    end
                                    SetTimeout(Config.NpcDespawnDelay, function()
                                        if netIdRef then
                                            TriggerServerEvent("taxi:npc:requestDespawn", netIdRef)
                                        end
                                    end)
                                end)
                            else
                                CleanupNpc()
                            end
                        end

                        mission.npcBlip = CleanupBlip(mission.npcBlip)
                        mission.destBlip = CleanupBlip(mission.destBlip)
                        dropoffMarkerActive = false
                        mission.state = STATE_IDLE
                        mission.destination = nil
                        mission.totalDistance = 0.0
                        mission.lastPos = nil
                        mission.vehicle = nil
                        mission.pickupLocation = nil
                        mission.initialHealth = 0
                        mission.active = false
                    end
                end
            elseif mission.active then
                ProcessStateMachine()
            end

            if mission.active or missionCooldown or awaitingChoice or stoppedCountdown or abandonCountdown then
                UpdateDashboardUI()
            else
                HideDashboardUI()
            end

            -- Maintain NUI focus while course_complete popup is shown
            if awaitingChoice then
                VFW.Nui.Focus(true)
            end

            Wait(500)
        else
            if mission.active or missionCooldown or awaitingChoice or stoppedCountdown or abandonCountdown or sessionStartTime > 0 then
                if awaitingChoice then VFW.Nui.Focus(false) end
                abandonCountdown = false
                ResetMission()
                HideDashboardUI()
                mission.active = false
                missionCooldown = false
                awaitingChoice = false
                stoppedCountdown = false
                lastFare = 0

                rideCount = 0
                sessionEarnings = 0
                sessionStartTime = 0
            end
            Wait(2000)
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ResetMission()
        HideDashboardUI()
    end
end)

-- ============================================
-- PLAYER RIDE HANDLING (from app)
-- ============================================
-- playerRideActive and playerRideClientName declared at top (used in GetDashboardState)
local playerRideClientId = nil
local playerRidePosition = nil
local playerRideArrived = false
local playerRideProximityActive = false

local function CleanupPlayerRide()
    playerRideActive = false
    playerRideClientId = nil
    playerRidePosition = nil
    playerRideClientName = nil
    playerRideArrived = false
    playerRideProximityActive = false
end

local function GetClientLivePosition()
    if playerRideClientId then
        local targetPlayer = GetPlayerFromServerId(playerRideClientId)
        if targetPlayer ~= -1 then
            local targetPed = GetPlayerPed(targetPlayer)
            if targetPed and targetPed ~= 0 then
                return GetEntityCoords(targetPed)
            end
        end
    end
    return playerRidePosition
end

local PLAYER_RIDE_ARRIVAL_DIST <const> = 10.0

local function StartPlayerRideProximityCheck()
    if playerRideProximityActive then return end
    playerRideProximityActive = true
    CreateThread(function()
        while playerRideActive and not playerRideArrived do
            Wait(1000)
            if not playerRideActive or playerRideArrived then break end
            local checkPos = GetClientLivePosition()
            if checkPos and checkPos.x then
                local playerPos = GetEntityCoords(PlayerPedId())
                local dx = playerPos.x - checkPos.x
                local dy = playerPos.y - checkPos.y
                local dz = playerPos.z - checkPos.z
                local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                if dist < PLAYER_RIDE_ARRIVAL_DIST then
                    TriggerServerEvent("taxi:ride:driverArrived")
                    break
                end
            end
        end
        playerRideProximityActive = false
    end)
end

RegisterNetEvent("taxi:driver:rideConfirmed", function(clientId, position, clientName)
    playerRideActive = true
    playerRideArrived = false
    playerRideClientId = clientId
    playerRidePosition = position
    playerRideClientName = clientName
    StartPlayerRideProximityCheck()
end)

-- Internal restore (when app reopens / driver relogs and a ride is already active)
AddEventHandler("taxi:internal:restorePlayerRide", function(clientId, position, clientName, arrived)
    playerRideActive = true
    playerRideArrived = arrived == true
    playerRideClientId = clientId
    playerRidePosition = position
    playerRideClientName = clientName
    if not playerRideArrived then
        StartPlayerRideProximityCheck()
    end
end)

local positionUpdateTick = 0

-- Client position update (refreshes cached position for on-demand locate)
RegisterNetEvent("taxi:driver:clientPositionUpdate", function(position)
    if not playerRideActive then return end
    playerRidePosition = position
    positionUpdateTick = positionUpdateTick + 1
end)

RegisterNetEvent("taxi:driver:rideTaken", function(driverName, _requestId)
    if playerRideActive then
        CleanupPlayerRide()
    end

    exports["lb-phone"]:SendNotification({
        app = "taxi-app",
        title = "Course prise",
        content = "Course prise par " .. driverName,
    })
end)

-- Driver reached the pickup zone (arrived state, ride still active)
RegisterNetEvent("taxi:driver:arrivedAtClient", function()
    playerRideArrived = true
end)

-- Ride fully completed (driver or client clicked Terminer)
RegisterNetEvent("taxi:driver:rideCompleted", function()
    CleanupPlayerRide()
end)

AddEventHandler("taxi:internal:cancelRide", function()
    CleanupPlayerRide()
end)

RegisterNetEvent("taxi:driver:rideCancelled", function()
    if playerRideActive then
        CleanupPlayerRide()
    end
end)

RegisterNUICallback("taxi-app:locateClient", function(_, cb)
    cb({ ok = true })
    CreateThread(function()
        local pos = nil
        if playerRideClientId then
            local targetPlayer = GetPlayerFromServerId(playerRideClientId)
            if targetPlayer ~= -1 then
                local targetPed = GetPlayerPed(targetPlayer)
                if targetPed and targetPed ~= 0 then
                    pos = GetEntityCoords(targetPed)
                end
            end
        end

        if not pos or not pos.x then
            local prevTick = positionUpdateTick
            TriggerServerEvent("taxi:ride:requestClientPosition")
            local waited = 0
            while positionUpdateTick == prevTick and waited < 1500 do
                Wait(50)
                waited = waited + 50
            end
            pos = playerRidePosition
        end

        if (not pos or not pos.x) then
            local serverRide = TriggerServerCallback("taxi:getDriverActiveRide")
            if serverRide and serverRide.position then
                pos = serverRide.position
                playerRidePosition = pos
            end
        end

        if not pos or not pos.x then return end
        SetWaypointOff()
        SetNewWaypoint(pos.x + 0.0, pos.y + 0.0)
    end)
end)

RegisterNUICallback("taxi-app:completeRide", function(_, cb)
    TriggerServerEvent("taxi:ride:complete")
    cb({ ok = true })
end)

-- NUI callbacks for course control
RegisterNUICallback("taxi:startCourse", function(_, cb)
    cb("ok")
    if not IsOnDutyTaxi() then return end
    local inVeh, veh = IsInVehicle()
    if not inVeh or not IsAllowedTaxiVehicle(veh) then return end
    awaitingChoice = false
    mission.active = true
    mission.state = STATE_IDLE
end)

RegisterNUICallback("taxi:choice:nextCourse", function(_, cb)
    cb("ok")
    VFW.Nui.Focus(false)
    awaitingChoice = false
    local _, veh = IsInVehicle()
    if not IsAllowedTaxiVehicle(veh) then return end
    missionCooldown = true
    cooldownStartTime = GetGameTimer()
    SetTimeout(Config.NewNpcCooldown, function()
        missionCooldown = false
        if IsOnDutyTaxi() then
            mission.active = true
            mission.state = STATE_IDLE
        end
    end)
end)

RegisterNUICallback("taxi:choice:endService", function(_, cb)
    cb("ok")
    VFW.Nui.Focus(false)
    awaitingChoice = false
    mission.active = false
end)

-- Job menu registration
CreateThread(function()
    Wait(1500)

    local registry = exports["core"]:getJobMenuRegistry()
    if not registry then return end

    registry.registerByType("taxi", function(menu)
        -- Refresh config a chaque ouverture du menu (prend en compte les changements builder)
        societyConfig = TriggerServerCallback("taxi:getSocietyConfig")
        RebuildAllowedVehicles()

        local inVeh, veh = IsInVehicle()
        local isTaxiVeh = inVeh and IsAllowedTaxiVehicle(veh)

        if mission.active and mission.state ~= STATE_IDLE then
            menu.Separator("Course PNJ en cours")

            local stateLabels = {
                [STATE_GOTO_PICKUP] = "En route vers le client...",
                [STATE_SPAWNING_NPC] = "Arrivee au point de pickup...",
                [STATE_WAITING_PICKUP] = "Client en attente",
                [STATE_NPC_ENTERING] = "Client monte à bord...",
                [STATE_DRIVING] = ("En course - %.0fm parcourus"):format(mission.totalDistance),
                [STATE_DROPOFF] = "Zone de depose - Restez en place",
                [STATE_ARRIVING] = "Arrivee a destination",
                [STATE_NPC_EXITING] = "Client descend...",
                [STATE_PAYMENT] = "Paiement en cours..."
            }

            menu.Button(stateLabels[mission.state] or "En cours...", "", nil, nil, true)

            menu.Button("Annuler la course PNJ", "", nil, "trash", false, function()
                ResetMission()
                mission.active = false
                if awaitingChoice then VFW.Nui.Focus(false) end
                awaitingChoice = false
                menu.refresh()
            end)
        else
            local btnLabel = not inVeh and "Vous devez être dans un véhicule" or (not isTaxiVeh and "Véhicule non-taxi" or "Trouver un client PNJ")
            menu.Button(
                "Lancer une course",
                btnLabel,
                nil,
                "arrow",
                not isTaxiVeh,
                function()
                    awaitingChoice = false
                    mission.active = true
                    mission.state = STATE_IDLE
                    menu.close()
                end
            )
        end

        if playerRideActive then
            menu.Separator("Course joueur")
            menu.Button("Client en attente", "Suivez le GPS", nil, nil, true)
            menu.Button("Annuler la course joueur", "", nil, "trash", false, function()
                CleanupPlayerRide()
                TriggerServerEvent("taxi:ride:cancel")
                TriggerEvent("taxi:internal:rideEnded")
                menu.refresh()
            end)
        end
    end, 50)
end)
