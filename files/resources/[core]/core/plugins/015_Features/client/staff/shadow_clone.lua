---@meta _
---@diagnostic disable: duplicate-doc-field

-- Shadow Clone System - Client Side
-- Renders ghost NPCs at disconnect locations for subscribed staff members

local RENDER_DISTANCE = 100.0 -- Distance in meters to spawn/despawn ghosts
local GHOST_ALPHA = 150 -- Semi-transparent (0-255)
local GHOST_MODEL_MALE = "mp_m_freemode_01"
local GHOST_MODEL_FEMALE = "mp_f_freemode_01"

local ghosts = {} -- Dictionary of ghost data indexed by playerServerId
local isActive = false -- Is shadow clone feature active for this client
ShadowCloneActive = false -- Global variable accessible by staff menu

---Load saved preference from KVP storage
local function loadPreference()
    local saved = GetResourceKvpString("staff_shadow_clone")
    return saved == "true"
end

---Save preference to KVP storage
---@param enabled boolean
local function savePreference(enabled)
    SetResourceKvp("staff_shadow_clone", tostring(enabled))
end

---Apply skin data to a ped
---@param ped number Ped handle
---@param skin table Skin data
local function applySkinToPed(ped, skin)
    if not skin then return end

    -- Apply ped components (clothing)
    if skin.tshirt_1 then SetPedComponentVariation(ped, 8, skin.tshirt_1, skin.tshirt_2 or 0, 0) end -- Undershirt
    if skin.torso_1 then SetPedComponentVariation(ped, 11, skin.torso_1, skin.torso_2 or 0, 0) end -- Torso
    if skin.decals_1 then SetPedComponentVariation(ped, 10, skin.decals_1, skin.decals_2 or 0, 0) end -- Decals
    if skin.arms then SetPedComponentVariation(ped, 3, skin.arms, 0, 0) end -- Arms
    if skin.pants_1 then SetPedComponentVariation(ped, 4, skin.pants_1, skin.pants_2 or 0, 0) end -- Legs
    if skin.shoes_1 then SetPedComponentVariation(ped, 6, skin.shoes_1, skin.shoes_2 or 0, 0) end -- Shoes
    if skin.chain_1 then SetPedComponentVariation(ped, 7, skin.chain_1, skin.chain_2 or 0, 0) end -- Accessories
    if skin.bags_1 then SetPedComponentVariation(ped, 5, skin.bags_1, skin.bags_2 or 0, 0) end -- Bags
    if skin.bproof_1 then SetPedComponentVariation(ped, 9, skin.bproof_1, skin.bproof_2 or 0, 0) end -- Body armor

    -- Apply props (accessories)
    if skin.helmet_1 and skin.helmet_1 > 0 then
        SetPedPropIndex(ped, 0, skin.helmet_1, skin.helmet_2 or 0, true) -- Hats/Helmets
    else
        ClearPedProp(ped, 0)
    end

    if skin.glasses_1 and skin.glasses_1 > 0 then
        SetPedPropIndex(ped, 1, skin.glasses_1, skin.glasses_2 or 0, true) -- Glasses
    else
        ClearPedProp(ped, 1)
    end

    if skin.ears_1 and skin.ears_1 > 0 then
        SetPedPropIndex(ped, 2, skin.ears_1, skin.ears_2 or 0, true) -- Ears
    else
        ClearPedProp(ped, 2)
    end

    if skin.watches_1 and skin.watches_1 > 0 then
        SetPedPropIndex(ped, 6, skin.watches_1, skin.watches_2 or 0, true) -- Watches
    else
        ClearPedProp(ped, 6)
    end

    if skin.bracelets_1 and skin.bracelets_1 > 0 then
        SetPedPropIndex(ped, 7, skin.bracelets_1, skin.bracelets_2 or 0, true) -- Bracelets
    else
        ClearPedProp(ped, 7)
    end

    -- Apply face features (heritage, face shape, etc.)
    if skin.face then
        SetPedHeadBlendData(ped, skin.face, skin.face, 0, skin.face, skin.face, 0, 0.5, 0.5, 0.0, false)
    end

    -- Apply hair
    if skin.hair_1 then SetPedComponentVariation(ped, 2, skin.hair_1, skin.hair_2 or 0, 0) end -- Hair
    if skin.hair_color_1 then SetPedHairColor(ped, skin.hair_color_1, skin.hair_color_2 or 0) end

    -- Apply beard
    if skin.beard_1 and skin.beard_1 > 0 then
        SetPedHeadOverlay(ped, 1, skin.beard_1, (skin.beard_2 or 10) / 10.0)
        SetPedHeadOverlayColor(ped, 1, 1, skin.beard_3 or 0, skin.beard_4 or 0)
    end

    -- Apply eyebrows
    if skin.eyebrows_1 and skin.eyebrows_1 > 0 then
        SetPedHeadOverlay(ped, 2, skin.eyebrows_1, (skin.eyebrows_2 or 10) / 10.0)
        SetPedHeadOverlayColor(ped, 2, 1, skin.eyebrows_3 or 0, skin.eyebrows_4 or 0)
    end

    -- Apply makeup
    if skin.makeup_1 and skin.makeup_1 > 0 then
        SetPedHeadOverlay(ped, 4, skin.makeup_1, (skin.makeup_2 or 10) / 10.0)
    end

    -- Apply lipstick
    if skin.lipstick_1 and skin.lipstick_1 > 0 then
        SetPedHeadOverlay(ped, 8, skin.lipstick_1, (skin.lipstick_2 or 10) / 10.0)
        SetPedHeadOverlayColor(ped, 8, 2, skin.lipstick_3 or 0, skin.lipstick_4 or 0)
    end

    -- Apply blemishes
    if skin.blemishes_1 and skin.blemishes_1 > 0 then
        SetPedHeadOverlay(ped, 0, skin.blemishes_1, (skin.blemishes_2 or 10) / 10.0)
    end

    -- Apply ageing
    if skin.age_1 and skin.age_1 > 0 then
        SetPedHeadOverlay(ped, 3, skin.age_1, (skin.age_2 or 10) / 10.0)
    end

    -- Apply complexion
    if skin.complexion_1 and skin.complexion_1 > 0 then
        SetPedHeadOverlay(ped, 6, skin.complexion_1, (skin.complexion_2 or 10) / 10.0)
    end

    -- Apply sun damage
    if skin.sun_1 and skin.sun_1 > 0 then
        SetPedHeadOverlay(ped, 7, skin.sun_1, (skin.sun_2 or 10) / 10.0)
    end

    -- Apply chest hair
    if skin.chest_1 and skin.chest_1 > 0 then
        SetPedHeadOverlay(ped, 10, skin.chest_1, (skin.chest_2 or 10) / 10.0)
        SetPedHeadOverlayColor(ped, 10, 1, skin.chest_3 or 0, skin.chest_4 or 0)
    end

    -- Apply body blemishes
    if skin.bodyb_1 and skin.bodyb_1 > 0 then
        SetPedHeadOverlay(ped, 11, skin.bodyb_1, (skin.bodyb_2 or 10) / 10.0)
    end

    -- Apply eye color
    if skin.eye_color then
        SetPedEyeColor(ped, skin.eye_color)
    end
end

---Spawn a ghost ped at the disconnect location
---@param ghost table Ghost data
local function spawnGhost(ghost)
    if ghost.handle and DoesEntityExist(ghost.handle) then
        return -- Already spawned
    end

    -- Determine model based on sex
    local modelName = GHOST_MODEL_MALE
    if ghost.skin and ghost.skin.sex == 1 then
        modelName = GHOST_MODEL_FEMALE
    end

    local model = GetHashKey(modelName)
    RequestModel(model)

    -- Wait for model to load
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(model) then
        return
    end

    -- Create the ped
    local ped = CreatePed(4, model, ghost.position.x, ghost.position.y, ghost.position.z - 1.0, ghost.heading, false, true)

    if not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(model)
        return
    end

    -- Apply skin/appearance
    applySkinToPed(ped, ghost.skin)

    -- Set ghost properties
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityCollision(ped, false, true)

    -- Make semi-transparent AFTER applying skin (important!)
    SetEntityAlpha(ped, GHOST_ALPHA, false)

    -- Create gamer tag showing player info
    local tagText = ("UUID : %s %s (%s)"):format(ghost.permId, ghost.name, ghost.timeStr)
    local gamerTag = CreateFakeMpGamerTag(ped, tagText, false, false, "", false)
    SetMpGamerTagAlpha(gamerTag, 0, GHOST_ALPHA)
    SetMpGamerTagColour(gamerTag, 0, 4) -- Color 4 (orangish)

    -- Store references
    ghost.handle = ped
    ghost.gamerTag = gamerTag

    SetModelAsNoLongerNeeded(model)

end

---Remove a ghost ped
---@param ghost table Ghost data
local function removeGhost(ghost)
    -- Remove gamer tag FIRST (before ped) to ensure synchronized disappearance
    if ghost.gamerTag then
        RemoveMpGamerTag(ghost.gamerTag)
        ghost.gamerTag = nil
    end

    if ghost.handle and DoesEntityExist(ghost.handle) then
        DeleteEntity(ghost.handle)
        ghost.handle = nil
    end
end

---Spawn all ghosts that are within render distance (for immediate activation)
local function spawnNearbyGhosts()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    for _, ghost in pairs(ghosts) do
        local dist = #(playerPos - ghost.position)
        if dist < RENDER_DISTANCE then
            if not ghost.handle or not DoesEntityExist(ghost.handle) then
                spawnGhost(ghost)
            end
        end
    end
end

---Add a new ghost to the registry
---@param ghostData table Ghost data from server
local function addGhost(ghostData)
    -- Store ghost data
    ghosts[ghostData.playerServerId] = ghostData
end

---Remove ghosts by server IDs
---@param serverIds table Array of server IDs to remove
local function removeGhosts(serverIds)
    for i = 1, #serverIds do
        local serverId = serverIds[i]
        local ghost = ghosts[serverId]

        if ghost then
            removeGhost(ghost)
            ghosts[serverId] = nil
        end
    end
end

---Distance-based rendering thread
CreateThread(function()
    while true do
        Wait(500)

        if not isActive then
            Wait(500) -- Reduced from 2000ms for faster reactivation
        else
            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)

            for _, ghost in pairs(ghosts) do
                local dist = #(playerPos - ghost.position)

                if dist < RENDER_DISTANCE then
                    -- Spawn if not already spawned
                    if not ghost.handle or not DoesEntityExist(ghost.handle) then
                        spawnGhost(ghost)
                    end
                else
                    -- Despawn if out of range
                    if ghost.handle and DoesEntityExist(ghost.handle) then
                        removeGhost(ghost)
                    end
                end
            end
        end
    end
end)

-- Event Handlers

---Handle shadow clone toggle from server
RegisterNetEvent("vfw:shadowClone:toggle", function(enabled, incomingGhosts)
    isActive = enabled
    ShadowCloneActive = enabled

    -- Save preference
    savePreference(enabled)

    if enabled then

        -- Add all existing ghosts from server
        if incomingGhosts then
            for i = 1, #incomingGhosts do
                addGhost(incomingGhosts[i])
            end
        end

        -- Immediately spawn nearby ghosts (no delay)
        spawnNearbyGhosts()
    else

        -- Remove all ghosts
        for _, ghost in pairs(ghosts) do
            removeGhost(ghost)
        end
        ghosts = {}
    end
end)

---Handle new ghost added
RegisterNetEvent("vfw:shadowClone:add", function(ghostData)
    if not isActive then return end
    addGhost(ghostData)
end)

---Handle ghosts removed (expired)
RegisterNetEvent("vfw:shadowClone:remove", function(serverIds)
    if not isActive then return end
    removeGhosts(serverIds)
end)

-- Auto-enable on resource start if preference was saved
CreateThread(function()
    Wait(2000) -- Wait for player to be fully loaded

    local savedPreference = loadPreference()
    if savedPreference then
        TriggerServerEvent("vfw:shadowClone:toggle")
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Clean up all spawned ghosts
    for _, ghost in pairs(ghosts) do
        removeGhost(ghost)
    end
    ghosts = {}
end)
