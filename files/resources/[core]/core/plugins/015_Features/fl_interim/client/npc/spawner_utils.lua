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
    SetEntityCollision(npc, true, true)
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

-- Les points peuvent venir d'anciennes configurations (Z du sol) ou avoir été posés à la
-- position d'un joueur (Z de son centre). On recherche systématiquement le sol et on laisse
-- SetEntityCoords appliquer l'offset propre au modèle du ped, au lieu de le recalculer avec
-- des dimensions de modèle qui diffèrent selon les skins.
local MAX_TRIES <const> = 300
local GROUND_RANGE <const> = 120.0

local function groundNpc(npc)
    npc.tries = npc.tries + 1
    local entity = npc.entity
    local c = npc.coords

    RequestCollisionAtCoord(c.x, c.y, c.z)
    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        c.x, c.y, c.z + 2.5,
        c.x, c.y, c.z - 8.0,
        1, entity, 4
    )
    local _, hit, hitCoords = GetShapeTestResult(ray)
    local groundZ = (hit == true or hit == 1) and hitCoords.z or nil
    if not groundZ then
        local found, fallbackZ = GetGroundZFor_3dCoord(c.x, c.y, c.z + 50.0, false)
        if not found then return false end
        groundZ = fallbackZ
    end

    FreezeEntityPosition(entity, false)
    SetEntityCollision(entity, true, true)
    SetEntityCoords(entity, c.x, c.y, groundZ, false, false, false, false)
    SetEntityHeading(entity, npc.heading)
    FreezeEntityPosition(entity, true)

    npc.coords = GetEntityCoords(entity)
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
                if dist < 2.0 and npc.action then
                    sleep = 0
                    isNear = true

                    if npc.label then
                        VFW.ShowHelpNotification(npc.label)
                    end

                    if VFW.Interact.JustPressed(0, 38) then
                        npc.action()
                    end
                    break
                end
            end
        end

        Wait(sleep)
    end
end)
