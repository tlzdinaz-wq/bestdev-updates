---@meta _
---@diagnostic disable: duplicate-doc-field

-- =============================================================
-- VFW.PNJ — Client side
-- Applies state-bag-driven options (scenario / freeze / invincible)
-- to every entity tagged "pnj_managed" by the server lib.
-- State bags persist for the entity lifetime, so a player streaming
-- in late will still receive and apply them automatically.
-- =============================================================

VFW.PNJ = VFW.PNJ or {}

local function entityFromBag(bagName)
    local netId = tonumber(bagName:match("entity:(%d+)"))
    if not netId then return nil end
    if not NetworkDoesNetworkIdExist(netId) then return nil end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) then return nil end
    return entity
end

local function applyScenario(entity, scenario)
    if not scenario or scenario == "" then return end
    ClearPedTasks(entity)
    TaskStartScenarioInPlace(entity, scenario, 0, true)
end

AddStateBagChangeHandler("pnj_scenario", nil, function(bagName, _, value)
    local entity = entityFromBag(bagName)
    if not entity then return end
    applyScenario(entity, value)
end)

AddStateBagChangeHandler("pnj_freeze", nil, function(bagName, _, value)
    local entity = entityFromBag(bagName)
    if not entity then return end
    FreezeEntityPosition(entity, value and true or false)
end)

AddStateBagChangeHandler("pnj_invincible", nil, function(bagName, _, value)
    local entity = entityFromBag(bagName)
    if not entity then return end
    SetEntityInvincible(entity, value and true or false)
    SetBlockingOfNonTemporaryEvents(entity, value and true or false)
end)

-- Sidewalk coord finder. Tries N times in a radius around `center` and
-- returns the first hit returned by GetSafeCoordForPed with the
-- GSC_FLAG_ONLY_PAVEMENT (1) flag. Used by the server to ask any nearby
-- client for a guaranteed-sidewalk position before spawning a networked ped.
RegisterClientCallback("vfw:pnj:findSidewalkCoord", function(center, radius, attempts)
    radius = math.max(1.0, tonumber(radius) or 30.0)
    attempts = math.max(1, tonumber(attempts) or 12)
    if not center or not center.x then return nil end

    for _ = 1, attempts do
        local angle = math.random() * math.pi * 2.0
        local dist = math.sqrt(math.random()) * radius
        local tx = center.x + math.cos(angle) * dist
        local ty = center.y + math.sin(angle) * dist
        local tz = center.z

        local ok, coord = GetSafeCoordForPed(tx, ty, tz, true, 1)
        if ok then
            return { x = coord.x, y = coord.y, z = coord.z }
        end
    end
    return nil
end)

-- When the entity is freshly streamed in, state-bag handlers don't
-- always re-fire. Walk the existing state once on stream-in to be safe.
AddEventHandler("entityStreamIn", function(entity)
    if not DoesEntityExist(entity) or not IsEntityAPed(entity) then return end
    local state = Entity(entity).state
    if not state or not state.pnj_managed then return end

    if state.pnj_scenario then applyScenario(entity, state.pnj_scenario) end
    if state.pnj_freeze then FreezeEntityPosition(entity, true) end
    if state.pnj_invincible then
        SetEntityInvincible(entity, true)
        SetBlockingOfNonTemporaryEvents(entity, true)
    end
end)
