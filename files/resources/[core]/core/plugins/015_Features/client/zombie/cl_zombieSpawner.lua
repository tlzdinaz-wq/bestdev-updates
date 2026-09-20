local ZombieZones = {}
local ZombieZonesById = {}
local SpawnedZombies = {}
local IsInZone = {}
local OwnedZones = {}
local ModelsPreloaded = false
local ZombieRelGroup = nil
local BurstPendingZones = {}
local LootableZombies = {}
local IsLooting = false

local function GetPolygonCenter(polygon)
    local sumX, sumY = 0, 0
    for i = 1, #polygon do
        sumX = sumX + polygon[i].x
        sumY = sumY + polygon[i].y
    end
    return sumX / #polygon, sumY / #polygon
end

local function GetPolygonRadiusSq(polygon, cx, cy)
    local maxDistSq = 0
    for i = 1, #polygon do
        local dx = polygon[i].x - cx
        local dy = polygon[i].y - cy
        local dSq = dx * dx + dy * dy
        if dSq > maxDistSq then maxDistSq = dSq end
    end
    return maxDistSq
end

local function PrecalcZone(zone)
    if zone.polygon and #zone.polygon >= 3 then
        local cx, cy = GetPolygonCenter(zone.polygon)
        zone._cx = cx
        zone._cy = cy
        zone._radiusSq = GetPolygonRadiusSq(zone.polygon, cx, cy)
        zone._radius = math.sqrt(zone._radiusSq)
    end
end

local function IndexZones(zones)
    ZombieZones = zones or {}
    ZombieZonesById = {}
    for _, zone in ipairs(ZombieZones) do
        PrecalcZone(zone)
        ZombieZonesById[zone.id] = zone
    end
end

RegisterNetEvent("zombie:syncZones")
AddEventHandler("zombie:syncZones", function(zones)
    IndexZones(zones)
end)

RegisterNetEvent("zombie:syncZoneUpdate")
AddEventHandler("zombie:syncZoneUpdate", function(zone)
    if not zone or not zone.id then return end
    PrecalcZone(zone)

    local found = false
    for i, z in ipairs(ZombieZones) do
        if z.id == zone.id then
            ZombieZones[i] = zone
            found = true
            break
        end
    end
    if not found then
        ZombieZones[#ZombieZones + 1] = zone
    end
    ZombieZonesById[zone.id] = zone
end)

RegisterNetEvent("zombie:syncZoneDelete")
AddEventHandler("zombie:syncZoneDelete", function(zoneId)
    if not zoneId then return end
    ZombieZonesById[zoneId] = nil
    for i, z in ipairs(ZombieZones) do
        if z.id == zoneId then
            table.remove(ZombieZones, i)
            break
        end
    end
    IsInZone[zoneId] = nil
end)

RegisterNetEvent("zombie:recheckZone")
AddEventHandler("zombie:recheckZone", function(zoneId)
    local zone = ZombieZonesById[zoneId]
    if not zone or not zone.active then return end
    local playerPos = GetEntityCoords(PlayerPedId())
    if IsPointInZoneFast(zone, playerPos.x, playerPos.y) then
        if not IsInZone[zoneId] then
            IsInZone[zoneId] = true
            TriggerServerEvent("zombie:enterZone", zoneId)
        end
    end
end)

RegisterNetEvent("zombie:setOwner")
AddEventHandler("zombie:setOwner", function(zoneId, isOwner)
    if isOwner then
        OwnedZones[zoneId] = true
        BurstPendingZones[zoneId] = true
    else
        OwnedZones[zoneId] = nil
        BurstPendingZones[zoneId] = nil
    end
end)

RegisterNetEvent("zombie:clearZone")
AddEventHandler("zombie:clearZone", function(zoneId)
    for ped, data in pairs(SpawnedZombies) do
        if data.zoneId == zoneId then
            SpawnedZombies[ped] = nil
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
    end
    for ped, ldata in pairs(LootableZombies) do
        if ldata.zoneId == zoneId then
            LootableZombies[ped] = nil
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
    end
    OwnedZones[zoneId] = nil
    IsInZone[zoneId] = nil
end)

local function IsPointInPolygon(px, py, polygon)
    local inside = false
    local j = #polygon
    for i = 1, #polygon do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y
        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function IsPointInZoneFast(zone, px, py)
    if not zone._cx then return false end
    local dx = px - zone._cx
    local dy = py - zone._cy
    if (dx * dx + dy * dy) > zone._radiusSq then
        return false
    end
    return IsPointInPolygon(px, py, zone.polygon)
end

local function FindRandomSpawnInZone(zone, referenceZ)
    local polygon = zone.polygon
    if not polygon or #polygon < 3 or not zone._cx then return nil end

    for attempt = 1, ZombieConfig.SpawnMaxAttempts do
        local angle = math.random() * 2 * math.pi
        local dist = math.sqrt(math.random()) * zone._radius
        local x = zone._cx + math.cos(angle) * dist
        local y = zone._cy + math.sin(angle) * dist

        if IsPointInPolygon(x, y, polygon) then
            if attempt <= 3 then
                local nodeFound, nodePos = GetClosestVehicleNodeWithHeading(x, y, referenceZ, 0, 3.0, 0)
                if nodeFound and nodePos and nodePos.x ~= 0.0 then
                    return vector3(nodePos.x, nodePos.y, nodePos.z)
                end
            end

            local found, groundZ = GetGroundZFor_3dCoord(x, y, referenceZ + 100.0, false)
            if found then
                return vector3(x, y, groundZ)
            end
        end
    end

    return nil
end

local function GetRandomZombieModel()
    return ZombieConfig.Models[math.random(#ZombieConfig.Models)]
end

local function SpawnZombie(spawnPos, zoneId)
    if not ModelsPreloaded or #ZombieConfig.Models == 0 then return nil end

    local modelName = GetRandomZombieModel()
    local hash = GetHashKey(modelName)
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local t = 20
        while not HasModelLoaded(hash) and t > 0 do
            Wait(100)
            t = t - 1
        end
        if not HasModelLoaded(hash) then return nil end
    end

    RequestCollisionAtCoord(spawnPos.x, spawnPos.y, spawnPos.z)

    local heading = math.random(0, 360) + 0.0
    local ped = VFW.OneSync.CreatePed(4, hash, spawnPos, heading)

    if not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    SetEntityMaxHealth(ped, ZombieConfig.Health)
    SetEntityHealth(ped, ZombieConfig.Health)
    SetPedArmour(ped, ZombieConfig.Armor)

    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAttributes(ped, 0, true)
    SetPedCombatAttributes(ped, 2, true)
    SetPedKeepTask(ped, true)
    SetPedCombatMovement(ped, 2)
    SetPedCombatRange(ped, 2)
    SetPedSeeingRange(ped, ZombieConfig.DetectionRange)
    SetPedHearingRange(ped, ZombieConfig.DetectionRange)
    DisablePedPainAudio(ped, true)
    StopPedSpeaking(ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    if NetworkGetEntityIsNetworked(ped) then
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(ped), false)
    end

    if ZombieRelGroup then
        SetPedRelationshipGroupHash(ped, ZombieRelGroup)
    end

    if ZombieConfig.MovementClipSet and HasAnimSetLoaded(ZombieConfig.MovementClipSet) then
        SetPedMovementClipset(ped, ZombieConfig.MovementClipSet, 0.5)
    end

    TaskWanderStandard(ped, 10.0, 10)

    SetModelAsNoLongerNeeded(hash)

    SpawnedZombies[ped] = {
        ped = ped,
        zoneId = zoneId,
    }

    return ped
end

local function DespawnZombie(ped, skipNotify)
    local data = SpawnedZombies[ped]
    if not data then return end

    local zoneId = data.zoneId
    SpawnedZombies[ped] = nil

    if not skipNotify then
        TriggerServerEvent("zombie:zombiesRemovedBatch", { [zoneId] = 1 })
    end

    if DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
end

local function CleanupDeadAndFarZombies(playerPos)
    local toRemove = {}
    local toDefer = {}

    for ped, data in pairs(SpawnedZombies) do
        local exists = DoesEntityExist(ped)
        if not exists then
            toRemove[#toRemove + 1] = ped
        elseif IsEntityDead(ped) then
            toDefer[#toDefer + 1] = ped
        elseif playerPos then
            local dist = #(playerPos - GetEntityCoords(ped))
            if dist > ZombieConfig.DespawnDistance then
                toRemove[#toRemove + 1] = ped
            end
        end
    end

    local removedByZone = {}

    for _, ped in ipairs(toRemove) do
        local data = SpawnedZombies[ped]
        if data then
            removedByZone[data.zoneId] = (removedByZone[data.zoneId] or 0) + 1
            SpawnedZombies[ped] = nil
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
    end

    for _, ped in ipairs(toDefer) do
        local data = SpawnedZombies[ped]
        if data then
            removedByZone[data.zoneId] = (removedByZone[data.zoneId] or 0) + 1

            if DoesEntityExist(ped) then
                LootableZombies[ped] = {
                    zoneId = data.zoneId,
                    pos = GetEntityCoords(ped),
                    looted = false,
                }
            end

            SpawnedZombies[ped] = nil
            local capturedPed = ped
            SetTimeout(30000, function()
                LootableZombies[capturedPed] = nil
                if DoesEntityExist(capturedPed) then
                    DeleteEntity(capturedPed)
                end
            end)
        end
    end

    if next(removedByZone) then
        TriggerServerEvent("zombie:zombiesRemovedBatch", removedByZone)
    end
end

CreateThread(function()
    while true do
        Wait(ZombieConfig.ZoneCheckInterval)

        local playerPos = GetEntityCoords(PlayerPedId())

        local currentZoneIds = {}
        for _, zone in pairs(ZombieZonesById) do
            if zone.active and zone.polygon and #zone.polygon >= 3 then
                if IsPointInZoneFast(zone, playerPos.x, playerPos.y) then
                    currentZoneIds[zone.id] = true
                end
            end
        end

        for zoneId, _ in pairs(IsInZone) do
            if not currentZoneIds[zoneId] then
                IsInZone[zoneId] = nil
                TriggerServerEvent("zombie:exitZone", zoneId)
            end
        end

        for zoneId, _ in pairs(currentZoneIds) do
            if not IsInZone[zoneId] then
                IsInZone[zoneId] = true
                TriggerServerEvent("zombie:enterZone", zoneId)
            end
        end

        CleanupDeadAndFarZombies(playerPos)
    end
end)

CreateThread(function()
    while true do
        Wait(ZombieConfig.SpawnInterval)

        if not ModelsPreloaded then goto continue end

        local zoneIds = {}
        local requestedPerZone = {}
        for zoneId, _ in pairs(OwnedZones) do
            local zone = ZombieZonesById[zoneId]
            if zone and zone.active then
                local count
                if BurstPendingZones[zoneId] then
                    count = ZombieConfig.BurstBatchSize
                else
                    count = math.random(ZombieConfig.HordeMinSize, ZombieConfig.HordeMaxSize)
                end
                requestedPerZone[zoneId] = count
                for i = 1, count do
                    zoneIds[#zoneIds + 1] = zoneId
                end
            end
        end

        if #zoneIds == 0 then goto continue end

        local allowedZones = TriggerServerCallback("zombie:canSpawnBatch", zoneIds)
        if not allowedZones or #allowedZones == 0 then
            for zoneId, _ in pairs(BurstPendingZones) do
                BurstPendingZones[zoneId] = nil
            end
            goto continue
        end

        local hordesByZone = {}
        for _, zoneId in ipairs(allowedZones) do
            hordesByZone[zoneId] = (hordesByZone[zoneId] or 0) + 1
        end

        for zoneId, _ in pairs(BurstPendingZones) do
            if (hordesByZone[zoneId] or 0) < (requestedPerZone[zoneId] or 0) then
                BurstPendingZones[zoneId] = nil
            end
        end

        local playerPos = GetEntityCoords(PlayerPedId())
        local failedZones = {}
        local hordeMax = ZombieConfig.HordeMaxSize

        for zoneId, count in pairs(hordesByZone) do
            local zone = ZombieZonesById[zoneId]
            if not zone then goto nextZone end

            local spawned = 0
            local idx = 0

            while idx < count do
                local batchSize = math.min(count - idx, hordeMax)
                local centerPos = FindRandomSpawnInZone(zone, playerPos.z)
                if centerPos then
                    for i = 1, batchSize do
                        local spawnPos
                        if i == 1 then
                            spawnPos = centerPos
                        else
                            local angle = math.random() * 2 * math.pi
                            local dist = math.random() * ZombieConfig.HordeSpread
                            local x = centerPos.x + math.cos(angle) * dist
                            local y = centerPos.y + math.sin(angle) * dist
                            local found, groundZ = GetGroundZFor_3dCoord(x, y, centerPos.z + 50.0, false)
                            spawnPos = found and vector3(x, y, groundZ) or vector3(x, y, centerPos.z)
                        end

                        if SpawnZombie(spawnPos, zoneId) then
                            spawned = spawned + 1
                        end
                    end
                end
                idx = idx + batchSize
            end

            local failed = count - spawned
            for i = 1, failed do
                failedZones[#failedZones + 1] = zoneId
            end

            ::nextZone::
        end

        if #failedZones > 0 then
            TriggerServerEvent("zombie:spawnFailedBatch", failedZones)
        end

        ::continue::
    end
end)

CreateThread(function()
    local validModels = {}
    for _, modelName in ipairs(ZombieConfig.Models) do
        local hash = GetHashKey(modelName)
        RequestModel(hash)
        local t = 30
        while not HasModelLoaded(hash) and t > 0 do
            Wait(100)
            t = t - 1
        end
        if HasModelLoaded(hash) then
            validModels[#validModels + 1] = modelName
            SetModelAsNoLongerNeeded(hash)
        end
    end

    ZombieConfig.Models = validModels

    if ZombieConfig.MovementClipSet then
        RequestAnimSet(ZombieConfig.MovementClipSet)
        local t = 30
        while not HasAnimSetLoaded(ZombieConfig.MovementClipSet) and t > 0 do
            Wait(100)
            t = t - 1
        end
    end

    local _, groupHash = AddRelationshipGroup("ZOMBIE_HORDE")
    ZombieRelGroup = groupHash
    SetRelationshipBetweenGroups(5, ZombieRelGroup, GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), ZombieRelGroup)

    ModelsPreloaded = true
end)

RegisterNetEvent("zombie:lootResult")
AddEventHandler("zombie:lootResult", function(amount)
    IsLooting = false
    if amount and amount > 0 then
        VFW.ShowNotification({
            type = "INFO",
            variant = "SUCCESS",
            subtitle = "Zombie",
            message = "Vous avez trouvé ~g~" .. VFW.Math.FormatMoney(amount) .. "~w~ d'argent sale"
        })
    end
end)

local NearLootPed = nil
local NearLootData = nil

CreateThread(function()
    while true do
        Wait(200)
        NearLootPed = nil
        NearLootData = nil

        if IsLooting then goto next end

        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then goto next end

        local playerPos = GetEntityCoords(playerPed)
        for ped, ldata in pairs(LootableZombies) do
            if not ldata.looted and DoesEntityExist(ped) then
                if #(playerPos - ldata.pos) <= ZombieConfig.LootRange then
                    NearLootPed = ped
                    NearLootData = ldata
                    break
                end
            end
        end

        ::next::
    end
end)

CreateThread(function()
    while true do
        if NearLootData and not IsLooting then
            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour fouiller le cadavre")

            if VFW.Interact.JustPressed(0, 38) and NearLootPed then
                IsLooting = true
                local lootData = NearLootData
                lootData.looted = true
                local zoneId = lootData.zoneId

                local playerPed = PlayerPedId()
                local startPos = GetEntityCoords(playerPed)

                RequestAnimSet("move_ped_crouched")
                while not HasAnimSetLoaded("move_ped_crouched") do Wait(0) end
                SetPedMovementClipset(playerPed, "move_ped_crouched", 0.3)

                local cancelled = false
                CreateThread(function()
                    local elapsed = 0
                    while IsLooting and elapsed < ZombieConfig.LootDuration do
                        Wait(200)
                        elapsed = elapsed + 200
                        local currentPos = GetEntityCoords(PlayerPedId())
                        if #(startPos - currentPos) > 1.0 then
                            cancelled = true
                            IsLooting = false
                            break
                        end
                    end
                end)

                local success = VFW.Nui.ProgressBar("Fouille du cadavre...", ZombieConfig.LootDuration)

                ResetPedMovementClipset(playerPed, 0.3)

                if success and not cancelled then
                    TriggerServerEvent("zombie:loot", zoneId)
                else
                    lootData.looted = false
                    IsLooting = false
                end
            end
            Wait(0)
        else
            Wait(200)
        end
    end
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    for ped, _ in pairs(SpawnedZombies) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    for ped, _ in pairs(LootableZombies) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    SpawnedZombies = {}
    LootableZombies = {}
end)
