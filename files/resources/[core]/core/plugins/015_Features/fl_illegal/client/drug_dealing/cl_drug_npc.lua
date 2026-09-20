
local DrugNPC = {}
local NPCPool = {}
local NPCBehaviors = {}

local NPCConfig = {
    drawDistance = 50.0,
    interactionDistance = Config.DrugDealing.NPCInteractionDistance,
    walkSpeed = Config.DrugDealing.NPCWalkSpeed,
    maxWanderDistance = 20.0,
    updateInterval = 1000, -- ms
    behaviourUpdateInterval = 5000, -- ms
}

local BehaviorStates = {
    SPAWNING = "spawning",
    WALKING_TO_PLAYER = "walking_to_player",
    WAITING = "waiting",
    INTERACTING = "interacting",
    LEAVING = "leaving",
    DESPAWNING = "despawning"
}

local function GetPlayerCoords()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return vector3(coords.x, coords.y, coords.z)
end

local function GetRandomWalkCoord(centerCoord, radius)
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius
    return vector3(
        centerCoord.x + math.cos(angle) * distance,
        centerCoord.y + math.sin(angle) * distance,
        centerCoord.z
    )
end

function NPCBehaviors.Initialize(npcId, entity, spawnCoords)
    NPCBehaviors[npcId] = {
        entity = entity,
        state = BehaviorStates.SPAWNING,
        spawnCoords = spawnCoords,
        targetCoords = nil,
        lastUpdate = GetGameTimer(),
        lastBehaviorUpdate = GetGameTimer(),
        playerDistance = 999.0,
        hasReachedPlayer = false,
        interactionCount = 0,
        maxInteractions = 1
    }

    NPCBehaviors.SetState(npcId, BehaviorStates.WALKING_TO_PLAYER)
end

function NPCBehaviors.SetState(npcId, newState)
    local behavior = NPCBehaviors[npcId]
    if not behavior then return end

    local entity = behavior.entity
    if not DoesEntityExist(entity) then return end

    behavior.state = newState
    behavior.lastBehaviorUpdate = GetGameTimer()


    if newState == BehaviorStates.WALKING_TO_PLAYER then
        local playerCoords = GetPlayerCoords()
        behavior.targetCoords = playerCoords
        TaskGoStraightToCoord(entity, playerCoords.x, playerCoords.y, playerCoords.z,
            NPCConfig.walkSpeed, -1, 0.0, 0.0)

    elseif newState == BehaviorStates.WAITING then
        ClearPedTasks(entity)
        TaskStandStill(entity, -1)

    elseif newState == BehaviorStates.INTERACTING then
        ClearPedTasks(entity)
        local playerPed = PlayerPedId()
        TaskTurnPedToFaceEntity(entity, playerPed, -1)

    elseif newState == BehaviorStates.LEAVING then
        ClearPedTasks(entity)

        -- Choisir une direction aléatoire pour partir (loin du joueur)
        local playerCoords = GetPlayerCoords()
        local npcCoords = GetEntityCoords(entity)

        -- Direction opposée au joueur + un peu de random
        local awayAngle = math.atan2(npcCoords.y - playerCoords.y, npcCoords.x - playerCoords.x)
        awayAngle = awayAngle + (math.random() - 0.5) * 1.0 -- Variation de ±30°

        local walkDistance = 30.0 + math.random() * 20.0 -- 30-50m
        local targetX = npcCoords.x + math.cos(awayAngle) * walkDistance
        local targetY = npcCoords.y + math.sin(awayAngle) * walkDistance

        -- Trouver le sol à cette position
        local foundGround, targetZ = GetGroundZFor_3dCoord(targetX, targetY, npcCoords.z + 50.0, false)
        if not foundGround or targetZ <= 0.0 then
            targetZ = npcCoords.z
        end

        -- Faire MARCHER le NPC (vitesse 1.0 = marche lente)
        TaskGoStraightToCoord(entity, targetX, targetY, targetZ, 1.0, 30000, 0.0, 0.0)

        -- Despawn après 30 secondes
        SetTimeout(30000, function()
            if NPCBehaviors[npcId] then
                NPCBehaviors.SetState(npcId, BehaviorStates.DESPAWNING)
            end
        end)

    elseif newState == BehaviorStates.DESPAWNING then
    end
end

function NPCBehaviors.Update(npcId)
    local behavior = NPCBehaviors[npcId]
    if not behavior then return end

    local entity = behavior.entity
    if not DoesEntityExist(entity) then
        NPCBehaviors.Cleanup(npcId)
        return
    end

    local currentTime = GetGameTimer()
    local playerCoords = GetPlayerCoords()
    local npcCoords = GetEntityCoords(entity)
    local distance = #(playerCoords - npcCoords)

    behavior.playerDistance = distance

    if behavior.state == BehaviorStates.WALKING_TO_PLAYER then
        if distance <= NPCConfig.interactionDistance * 2 then
            behavior.hasReachedPlayer = true
            NPCBehaviors.SetState(npcId, BehaviorStates.WAITING)
        elseif currentTime - behavior.lastBehaviorUpdate > 10000 then
            local targetDistance = behavior.targetCoords and #(playerCoords - behavior.targetCoords) or 999
            if targetDistance > 10.0 then
                behavior.targetCoords = playerCoords
                TaskGoStraightToCoord(entity, playerCoords.x, playerCoords.y, playerCoords.z,
                    NPCConfig.walkSpeed, -1, 0.0, 0.0)
                behavior.lastBehaviorUpdate = currentTime
            end
        end

    elseif behavior.state == BehaviorStates.WAITING then
        if distance > NPCConfig.interactionDistance * 3 and behavior.hasReachedPlayer then
            NPCBehaviors.SetState(npcId, BehaviorStates.WALKING_TO_PLAYER)
        end

        if currentTime - behavior.lastBehaviorUpdate > 8000 and math.random(1, 100) <= 20 then
            local idleAnims = {
                {dict = "amb@world_human_smoking@male@male_a@base", anim = "base"},
                {dict = "amb@world_human_stand_mobile@male@text@base", anim = "base"},
                {dict = "amb@lo_res_idles@", anim = "world_human_lean_male_foot_up_lo_res_base"}
            }
            local randomAnim = idleAnims[math.random(#idleAnims)]

            RequestAnimDict(randomAnim.dict)
            while not HasAnimDictLoaded(randomAnim.dict) do
                Wait(1)
            end

            TaskPlayAnim(entity, randomAnim.dict, randomAnim.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
            behavior.lastBehaviorUpdate = currentTime
        end

    elseif behavior.state == BehaviorStates.INTERACTING then
        if distance > NPCConfig.interactionDistance * 2 then
            NPCBehaviors.SetState(npcId, BehaviorStates.WAITING)
        end

    elseif behavior.state == BehaviorStates.LEAVING then
        if behavior.targetCoords then
            local targetDistance = #(npcCoords - behavior.targetCoords)
            if targetDistance <= 2.0 then
                NPCBehaviors.SetState(npcId, BehaviorStates.DESPAWNING)
            end
        end
    end
end

function NPCBehaviors.StartInteraction(npcId)
    local behavior = NPCBehaviors[npcId]
    if not behavior then return false end

    if behavior.state ~= BehaviorStates.WAITING then
        return false
    end

    NPCBehaviors.SetState(npcId, BehaviorStates.INTERACTING)
    behavior.interactionCount = behavior.interactionCount + 1
    return true
end

function NPCBehaviors.EndInteraction(npcId, successful)
    local behavior = NPCBehaviors[npcId]
    if not behavior then return end

    if successful then
        -- After successful interaction, NPC should leave
        NPCBehaviors.SetState(npcId, BehaviorStates.LEAVING)
    else
        -- Failed interaction, go back to waiting
        NPCBehaviors.SetState(npcId, BehaviorStates.WAITING)
    end
end

function NPCBehaviors.Cleanup(npcId)
    NPCBehaviors[npcId] = nil
end

function DrugNPC.Create(npcId, coords, model)
    if NPCPool[npcId] then
        DrugNPC.Remove(npcId)
    end

    local modelHash = GetHashKey(model)
    RequestModel(modelHash)

    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do
        Wait(1)
    end

    if not HasModelLoaded(modelHash) then
        return false
    end

    -- Re-vérifier le ground Z juste avant le spawn (collision parfois pas encore chargée
    -- au moment de la validation, ce qui faisait spawn les NPC dans le sol)
    -- Important: on raycast depuis le Z attendu + 1.0 pour rester au niveau du joueur
    -- et éviter de hit un pont/étage supérieur (ex: trottoir sous un pont)
    local spawnX, spawnY, spawnZ = coords.x, coords.y, coords.z
    local expectedZ = spawnZ
    local groundZ = nil
    for attempt = 1, 5 do
        local found, gz = GetGroundZFor_3dCoord(spawnX, spawnY, expectedZ + 1.0, false)
        if found and gz and gz > 0.0 and math.abs(gz - expectedZ) <= 3.0 then
            groundZ = gz
            break
        end
        Wait(50)
    end

    if groundZ then
        spawnZ = groundZ
    end

    local entity = CreatePed(4, modelHash, spawnX, spawnY, spawnZ, 0.0, false, true)

    -- Petit ajustement: re-snap au sol pour corriger les rares cas où le ped reste enfoncé
    if DoesEntityExist(entity) then
        SetPedResetFlag(entity, 35, true)
        local _, finalGroundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 1.0, false)
        if finalGroundZ and finalGroundZ > 0.0 and math.abs(finalGroundZ - spawnZ) <= 3.0 then
            SetEntityCoordsNoOffset(entity, spawnX, spawnY, finalGroundZ, false, false, false)
        end
    end

    if not DoesEntityExist(entity) then
        SetModelAsNoLongerNeeded(modelHash)
        return false
    end

    SetEntityAsMissionEntity(entity, true, true)
    SetPedFleeAttributes(entity, 0, 0)
    SetPedDiesWhenInjured(entity, true) -- Le NPC peut mourir
    SetPedCanPlayAmbientAnims(entity, true)
    SetPedCanRagdollFromPlayerImpact(entity, true)
    SetEntityInvincible(entity, false) -- NPC vulnérable
    FreezeEntityPosition(entity, false)
    SetPedKeepTask(entity, true)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetPedCanBeTargetted(entity, true) -- NPC peut être ciblé
    SetPedConfigFlag(entity, 208, true) -- Disable auto-conversation
    SetPedConfigFlag(entity, 281, true) -- Disable ambient speech

    NPCPool[npcId] = {
        entity = entity,
        model = modelHash,
        spawnCoords = coords,
        spawnTime = GetGameTimer()
    }

    NPCBehaviors.Initialize(npcId, entity, coords)

    SetModelAsNoLongerNeeded(modelHash)

    return true
end

function DrugNPC.Remove(npcId)
    local npcData = NPCPool[npcId]
    if not npcData then return false end

    if DoesEntityExist(npcData.entity) then
        DeleteEntity(npcData.entity)
    end

    NPCBehaviors.Cleanup(npcId)
    NPCPool[npcId] = nil

    return true
end

function DrugNPC.GetEntity(npcId)
    local npcData = NPCPool[npcId]
    return npcData and npcData.entity or nil
end

function DrugNPC.Exists(npcId)
    local npcData = NPCPool[npcId]
    return npcData and DoesEntityExist(npcData.entity) or false
end

function DrugNPC.GetDistance(npcId)
    local npcData = NPCPool[npcId]
    if not npcData or not DoesEntityExist(npcData.entity) then
        return 999.0
    end

    local playerCoords = GetPlayerCoords()
    local npcCoords = GetEntityCoords(npcData.entity)
    return #(playerCoords - npcCoords)
end

function DrugNPC.StartInteraction(npcId)
    return NPCBehaviors.StartInteraction(npcId)
end

function DrugNPC.EndInteraction(npcId, successful)
    NPCBehaviors.EndInteraction(npcId, successful)
end

function DrugNPC.GetClosest()
    local playerCoords = GetPlayerCoords()
    local closestNPC = nil
    local closestDistance = NPCConfig.interactionDistance

    for npcId, npcData in pairs(NPCPool) do
        if DoesEntityExist(npcData.entity) then
            local npcCoords = GetEntityCoords(npcData.entity)
            local distance = #(playerCoords - npcCoords)

            if distance < closestDistance then
                closestDistance = distance
                closestNPC = {id = npcId, distance = distance, entity = npcData.entity}
            end
        end
    end

    return closestNPC
end

function DrugNPC.GetAllInRange(maxDistance)
    local playerCoords = GetPlayerCoords()
    local npcsInRange = {}

    for npcId, npcData in pairs(NPCPool) do
        if DoesEntityExist(npcData.entity) then
            local npcCoords = GetEntityCoords(npcData.entity)
            local distance = #(playerCoords - npcCoords)

            if distance <= maxDistance then
                table.insert(npcsInRange, {
                    id = npcId,
                    distance = distance,
                    entity = npcData.entity,
                    coords = npcCoords
                })
            end
        end
    end

    table.sort(npcsInRange, function(a, b) return a.distance < b.distance end)
    return npcsInRange
end

CreateThread(function()
    while true do
        local sleep = NPCConfig.updateInterval

        for npcId, npcData in pairs(NPCPool) do
            if DoesEntityExist(npcData.entity) then
                -- Vérifier si le NPC est mort
                if IsPedDeadOrDying(npcData.entity, true) then
                    TriggerServerEvent("core:drugdealing:npcKilled", npcId)
                    DrugNPC.Remove(npcId)
                else
                    NPCBehaviors.Update(npcId)
                end
            else
                NPCBehaviors.Update(npcId)
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 100

        if Config.DrugDealing.Debug then
            for npcId, npcData in pairs(NPCPool) do
                if DoesEntityExist(npcData.entity) then
                    local coords = GetEntityCoords(npcData.entity)
                    local behavior = NPCBehaviors[npcId]
                    local stateText = behavior and behavior.state or "unknown"
                    local distanceText = behavior and string.format("%.1fm", behavior.playerDistance) or "N/A"

                    DrawText3D(coords.x, coords.y, coords.z + 1.2,
                        string.format("NPC: %s\nState: %s\nDist: %s", npcId, stateText, distanceText))
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for npcId, _ in pairs(NPCPool) do
        DrugNPC.Remove(npcId)
    end
end)

if not DrawText3D then
    function DrawText3D(x, y, z, text)
        local onScreen, _x, _y = World3dToScreen2d(x, y, z)
        local px, py, pz = table.unpack(GetGameplayCamCoords())
        local dist = #(vector3(px, py, pz) - vector3(x, y, z))
        local scale = (1 / dist) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        local scaleX = scale * fov
        local scaleY = scale * fov

        if onScreen then
            SetTextScale(0.25 * scaleX, 0.25 * scaleY)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextDropshadow(1, 1, 1, 1, 255)
            SetTextEdge(2, 0, 0, 0, 150)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(1)
            AddTextComponentString(text)
            DrawText(_x, _y)
        end
    end
end

exports("CreateDrugNPC", DrugNPC.Create)
exports("RemoveDrugNPC", DrugNPC.Remove)
exports("GetClosestDrugNPC", DrugNPC.GetClosest)
exports("StartDrugNPCInteraction", DrugNPC.StartInteraction)
exports("EndDrugNPCInteraction", DrugNPC.EndInteraction)

return DrugNPC