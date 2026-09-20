---@meta _
---@diagnostic disable: duplicate-doc-field

-- Local variables for the cloned ped system
local clonedPed = nil
local isInventoryOpen = false
local isCreatingClone = false

-- Naked states for the character models
local NAKED_STATES = {
    male = {
        [0] = { 0, 0 },  -- face
        [1] = { 0, 0 },  -- mask
        [2] = { 0, 0 },  -- hair
        [3] = { 15, 0 }, -- torso
        [4] = { 61, 0 }, -- leg
        [5] = { 0, 0 },  -- bag
        [6] = { 34, 0 }, -- shoes
        [7] = { 0, 0 },  -- accessory
        [8] = { 15, 0 }, -- undershirt
        [9] = { 0, 0 },  -- armor
        [10] = { 0, 0 }, -- decal
        [11] = { 15, 0 } -- top
    },
    female = {
        [0] = { 0, 0 },  -- face
        [1] = { 0, 0 },  -- mask
        [2] = { 0, 0 },  -- hair
        [3] = { 15, 0 }, -- torso
        [4] = { 15, 0 }, -- leg
        [5] = { 0, 0 },  -- bag
        [6] = { 35, 0 }, -- shoes
        [7] = { 0, 0 },  -- accessory
        [8] = { 15, 0 }, -- undershirt
        [9] = { 0, 0 },  -- armor
        [10] = { 0, 0 }, -- decal
        [11] = { 15, 0 } -- top
    }
}

-- Character models
local CHARACTER_MODELS = {
    male = `mp_m_freemode_01`,
    female = `mp_f_freemode_01`
}

-- Mapping of props
local PROP_SLOTS = {
    [0] = "helmet",   -- helmet
    [1] = "glasses",  -- glasses
    [2] = "ears",     -- ears
    [6] = "watches",  -- watches
    [7] = "bracelets" -- bracelets
}

-- Camera smoothing buffer
local rotationBuffer = {}
local bufferSize = 5

--- Get a fixed position relative to the camera at a given depth
local function getFixedCamRelativePosition(distance)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local pitch = math.rad(camRot.x)
    local yaw = math.rad(camRot.z)
    local dir = vector3(
        -math.sin(yaw) * math.cos(pitch),
        math.cos(yaw) * math.cos(pitch),
        math.sin(pitch)
    )
    local offset = dir * distance
    return camCoords + offset, camRot
end

--- Create the ped screen for the inventory (clone ped method - world space)
function VFW.CreatePedScreen()
    if isCreatingClone then return end
    if clonedPed and DoesEntityExist(clonedPed) then return end

    isCreatingClone = true

    CreateThread(function()
        local playerPed = VFW.PlayerData.ped or PlayerPedId()
        local pedModel = GetEntityModel(playerPed)

        RequestModel(pedModel)
        local waited = 0
        while not HasModelLoaded(pedModel) and waited < 1000 do Wait(10) waited = waited + 10 end

        -- Spawn the clone ped in front of the camera
        local screenX, screenY = 0.503, 0.45
        local worldCoords, forwardDir = GetWorldCoordFromScreenCoord(screenX, screenY)
        local spawnCoords = worldCoords + forwardDir * 1.5
        local camRotation = GetGameplayCamRot(2)

        local createdPed = CreatePed(4, pedModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, camRotation.z + 180.0, false, true)

        if not DoesEntityExist(createdPed) then
            isCreatingClone = false
            return
        end

        -- Inventaire déjà refermé pendant le chargement du modèle → supprimer le clone.
        if not isInventoryOpen then
            SetEntityAsNoLongerNeeded(createdPed)
            DeleteEntity(createdPed)
            isCreatingClone = false
            return
        end

        clonedPed = createdPed

        SetEntityCollision(clonedPed, false, false)
        SetEntityInvincible(clonedPed, true)
        SetEntityVisible(clonedPed, true)
        SetEntityAlpha(clonedPed, 0, false) -- Invisible via alpha until ready
        FreezeEntityPosition(clonedPed, true)
        SetBlockingOfNonTemporaryEvents(clonedPed, true)
        NetworkSetEntityInvisibleToNetwork(clonedPed, true)
        SetEntityCanBeDamaged(clonedPed, false)
        FinalizeHeadBlend(clonedPed)

        -- Clone the player's appearance onto the ped
        ClonePedToTarget(playerPed, clonedPed)

        Wait(150)
        if not isInventoryOpen or clonedPed ~= createdPed then
            if DoesEntityExist(createdPed) then
                SetEntityAsNoLongerNeeded(createdPed)
                DeleteEntity(createdPed)
            end
            if clonedPed == createdPed then clonedPed = nil end
            isCreatingClone = false
            return
        end
        VFW.SyncPedAppearance(true)
        Wait(50)

        if not isInventoryOpen or clonedPed ~= createdPed then
            if DoesEntityExist(createdPed) then
                SetEntityAsNoLongerNeeded(createdPed)
                DeleteEntity(createdPed)
            end
            if clonedPed == createdPed then clonedPed = nil end
            isCreatingClone = false
            return
        end

        -- Reveal the ped now that appearance is applied
        ResetEntityAlpha(clonedPed)

        isCreatingClone = false
        rotationBuffer = {}

        -- Camera tracking thread: keeps the ped in front of the camera
        local fixedDepth = 3.0
        CreateThread(function()
            while isInventoryOpen and clonedPed and DoesEntityExist(clonedPed) do
                local targetPos, camRot = getFixedCamRelativePosition(fixedDepth)

                table.insert(rotationBuffer, camRot)
                if #rotationBuffer > bufferSize then
                    table.remove(rotationBuffer, 1)
                end

                local averagedRotation = vector3(0, 0, 0)
                for _, rotation in ipairs(rotationBuffer) do
                    averagedRotation = averagedRotation + rotation
                end
                averagedRotation = averagedRotation / #rotationBuffer

                SetEntityCoordsNoOffset(clonedPed, targetPos.x, targetPos.y, targetPos.z, false, false, false)
                SetEntityRotation(clonedPed, averagedRotation.x * (-1), 0.0, averagedRotation.z + 180.0, 2, true)

                Wait(0)
            end
        end)
    end)
end

--- Delete the ped's screen
function VFW.DeletePedScreen()
    isCreatingClone = false
    rotationBuffer = {}

    if clonedPed and DoesEntityExist(clonedPed) then
        SetEntityAsNoLongerNeeded(clonedPed)
        DeleteEntity(clonedPed)
    end
    clonedPed = nil
end

--- Sync the player's appearance with the cloned ped using the current skin system
---@param sync boolean? Si true, exécute de manière synchrone (sans créer de thread)
function VFW.SyncPedAppearance(sync)
    if not clonedPed or not DoesEntityExist(clonedPed) then
        return
    end

    local function applyAppearance()
        local playerPed = VFW.PlayerData.ped or PlayerPedId()

        -- Copier directement les composants du ped joueur (prend en compte les tenues staff, etc.)
        for componentId = 0, 11 do
            local drawable = GetPedDrawableVariation(playerPed, componentId)
            local texture = GetPedTextureVariation(playerPed, componentId)
            SetPedComponentVariation(clonedPed, componentId, drawable, texture, 0)
        end

        -- Copier les props (chapeaux, lunettes, montres, etc.)
        local propIds = { 0, 1, 2, 6, 7 } -- helmet, glasses, ears, watches, bracelets
        for _, propId in ipairs(propIds) do
            local drawable = GetPedPropIndex(playerPed, propId)
            local texture = GetPedPropTextureIndex(playerPed, propId)
            if drawable >= 0 then
                SetPedPropIndex(clonedPed, propId, drawable, texture, true)
            else
                ClearPedProp(clonedPed, propId)
            end
        end
    end

    if sync then
        applyAppearance()
    else
        CreateThread(applyAppearance)
    end
end


--- Apply clothing changes to the cloned ped based on the current clothing system
---@param itemName string Item name
---@param metadata table Item metadata
function VFW.ApplyClothingToClonedPed(itemName, metadata)
    if not clonedPed or not DoesEntityExist(clonedPed) then
        return
    end

    if not metadata then return end

    -- Get the current skin first to apply changes correctly
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
    if not skin then return end

    -- Use the translateSkin mapping from clothes.lua
    local translateSkin = {
        ["bottom"] = { "pants_1", "pants_2" },
        ["shoe"] = { "shoes_1", "shoes_2" },
        ["hat"] = { "helmet_1", "helmet_2" },
        ["glasses"] = { "glasses_1", "glasses_2" },
        ["bag"] = { "bags_1", "bags_2" },
        ["necklace"] = { "chain_1", "chain_2" },
        ["watch"] = { "watches_1", "watches_2" },
        ["mask"] = { "mask_1", "mask_2" },
        ["bracelet"] = { "bracelets_1", "bracelets_2" },
        ["earring"] = { "ears_1", "ears_2" },
        ["piercing"] = { "decals_1", "decals_2" },
        ["nails"] = { "decals_1", "decals_2" },
        ["gpb"] = { "bproof_1", "decals_2" }
    }

    local componentMapping = {
        mask = 1,
        helmet = 0,
        pants = 4,
        shoes = 6,
        bags = 5,
        chain = 7,
        glasses = 1,
        watches = 6,
        bracelets = 7,
        ears = 2,
        decals = 10,
        bproof = 9
    }

    local propMapping = {
        helmet = 0,
        glasses = 1,
        ears = 2,
        watches = 6,
        bracelets = 7
    }

    if itemName ~= "outfit" and itemName ~= "top" then
        local typeItem = metadata.type and metadata.type or itemName
        local skinKeys = translateSkin[typeItem]

        if skinKeys then
            local drawable = metadata.id or 0
            local texture = metadata.var or 0

            -- Determine if it's a prop or component
            local isProp = propMapping[typeItem:gsub("_.*", "")] ~= nil

            if isProp then
                local propId = propMapping[typeItem:gsub("_.*", "")]
                if propId then
                    SetPedPropIndex(clonedPed, propId, drawable, texture, true)
                end
            else
                local componentName = skinKeys[1]:gsub("_1", "")
                local componentId = componentMapping[componentName]
                if componentId then
                    SetPedComponentVariation(clonedPed, componentId, drawable, texture, 0)
                end
            end
        end
    else
        -- Handle outfit or top items
        if metadata.skin then
            for k, v in pairs(metadata.skin) do
                -- Apply the skin values directly
                if skin[k] then
                    local componentMatch = k:match("^(.+)_1$")
                    if componentMatch then
                        local componentName = componentMatch
                        local componentId = componentMapping[componentName]

                        if componentId then
                            local texture = metadata.skin[componentName .. "_2"] or 0
                            SetPedComponentVariation(clonedPed, componentId, v, texture, 0)
                        end
                    end
                end
            end
        end
    end
end

--- Set the inventory open state
---@param open boolean Open state
function VFW.SetInventoryPedState(open)
    isInventoryOpen = open

    if open then
        VFW.CreatePedScreen()
    else
        VFW.DeletePedScreen()
    end
end

--- Check if the cloned ped exists
---@return boolean
function VFW.HasClonedPed()
    return clonedPed ~= nil and DoesEntityExist(clonedPed)
end

--- Get the cloned ped
---@return number|nil
function VFW.GetClonedPed()
    return clonedPed
end

-- Clean up on resource restart
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        VFW.DeletePedScreen()
    end
end)
