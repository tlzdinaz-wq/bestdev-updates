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
        label  = interactLabel,
        action = onInteract
    })

    return npc
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
