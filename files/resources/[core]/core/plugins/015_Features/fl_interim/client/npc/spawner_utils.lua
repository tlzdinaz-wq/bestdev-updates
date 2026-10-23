local spawnedNpcs = {}

local function v3(p)
    if not p then return nil end
    if type(p) == "vector3" then return p end
    if type(p) == "vector4" then return vector3(p.x, p.y, p.z) end
    if type(p) == "table" and p.x and p.y and p.z then
        return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0)
    end
    return nil
end

function SpawnNpcsInterimJobs(model, position, heading, interactLabel, onInteract)
    position = v3(position)
    if not position then return nil end

    heading = tonumber(heading) or 0.0

    local npcEntity = cEntity.Manager:CreatePedLocal(model, position, heading)
    if not npcEntity or not npcEntity.id then return nil end

    local npc = npcEntity.id
    local netId = nil
    if NetworkGetEntityIsNetworked(npc) then
        netId = NetworkGetNetworkIdFromEntity(npc)
    end

    NetworkRequestControlOfEntity(npc)
    SetEntityInvincible(npc, true)
    SetPedCanRagdoll(npc, false)
    SetPedCanRagdollFromPlayerImpact(npc, false)
    SetPedDiesWhenInjured(npc, false)
    DisablePedPainAudio(npc, true)
    SetEntityProofs(npc, true, true, true, true, true, true, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    ClearPedTasksImmediately(npc)
    TaskStandStill(npc, -1)
    SetPedCanBeTargetted(npc, false)
    SetEntityCollision(npc, false, false)
    FreezeEntityPosition(npc, true)
    SetEntityHeading(npc, heading)

    table.insert(spawnedNpcs, {
        entity = npc,
        coords = position,
        heading = heading,
        label  = interactLabel,
        action = onInteract,
        grounded = false,
        tries = 0,
    })

    return npc
end

-- Le PNJ apparaît à la hauteur enregistrée, qui est celle d'un joueur debout (hauteur de ceinture) : il flottait.
-- On cherche le sol sous ce point (un rayon vers le bas, sur la carte seulement : ni objets ni véhicules) et on pose
-- le PNJ dessus, ses pieds au sol d'après les dimensions de son modèle. Sans sol chargé, le rayon ne touche rien :
-- on réessaie tant que le joueur est à portée.
local MAX_TRIES <const> = 300
local GROUND_RANGE <const> = 120.0

local function groundNpc(npc)
    npc.tries = npc.tries + 1
    local entity = npc.entity
    local c = npc.coords

    RequestCollisionAtCoord(c.x, c.y, c.z)
    local ray = StartExpensiveSynchronousShapeTestLosProbe(c.x, c.y, c.z + 1.5, c.x, c.y, c.z - 6.0, 1, entity, 4)
    local _, hit, hitCoords = GetShapeTestResult(ray)
    if hit ~= true and hit ~= 1 then return false end

    local minimum = GetModelDimensions(GetEntityModel(entity))
    local feet = (minimum and minimum.z) or -1.0
    local rootZ = hitCoords.z - feet

    FreezeEntityPosition(entity, false)
    SetEntityCoordsNoOffset(entity, c.x, c.y, rootZ, false, false, false)
    SetEntityHeading(entity, npc.heading)
    FreezeEntityPosition(entity, true)

    npc.coords = vector3(c.x, c.y, rootZ)
    npc.grounded = true
    return true
end

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local isNear = false

        for i = #spawnedNpcs, 1, -1 do
            local npc = spawnedNpcs[i]

            if not npc.entity or not DoesEntityExist(npc.entity) then
                table.remove(spawnedNpcs, i)
            else
                local dist = #(pCoords - npc.coords)
                if not npc.grounded and npc.tries < MAX_TRIES and dist < GROUND_RANGE then
                    groundNpc(npc)
                    sleep = math.min(sleep, 100)
                    dist = #(pCoords - npc.coords)
                end
                if dist < 2.0 then
                    sleep = 0
                    isNear = true

                    VFW.ShowHelpNotification(npc.label or "Interagir")

                    if VFW.Interact.JustPressed(0, 38) and npc.action then
                        npc.action()
                    end
                    break
                end
            end
        end

        Wait(sleep)
    end
end)
