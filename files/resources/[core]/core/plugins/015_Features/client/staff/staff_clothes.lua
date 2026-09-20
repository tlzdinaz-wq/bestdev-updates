---@meta _
---@diagnostic disable: duplicate-doc-field

-- Tenue staff désactivée pour l'instant (remettre à true pour la réactiver).
VFW.StaffOutfitEnabled = false

-- Store original clothing before applying staff clothes
local savedClothes = nil
-- Store the staff clothes color to keep it consistent (global for ped_display.lua access)
staffClothesColor = nil
-- Track active outfit modes
local isStaffOutfitActive = false
local isAnimatorOutfitActive = false

-- Helper function to check if ped is male (IsPedMale doesn't work well with freemode peds)
local function IsPedMaleModel(ped)
    local model = GetEntityModel(ped)
    return model == `mp_m_freemode_01`
end

-- Check if ped is a freemode model (custom peds don't support component variations)
local function IsFreemodeModel(ped)
    local model = GetEntityModel(ped)
    return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

-- Staff clothing configurations (using skinchanger naming convention)
-- IMPORTANT: For females, arms + tshirt + torso must be compatible or body parts become invisible
staffClothes = {
    male = {
        shoes_1 = 55,       -- Component 6: Shoes
        pants_1 = 77,       -- Component 4: Pants
        arms = 31,          -- Component 3: Arms/Torso base
        tshirt_1 = 15,      -- Component 8: Undershirt
        torso_1 = 178,      -- Component 11: Top/Jacket
        chain_1 = 0,        -- Component 7: Accessory
        bags_1 = 0,         -- Component 5: Bag
        helmet_1 = 91,      -- Prop 0: Head/Hat
    },
    female = {
        -- Female neon suit
        shoes_1 = 58,       -- Component 6: Shoes
        pants_1 = 79,       -- Component 4: Pants
        arms = 31,          -- Component 3: Arms/Torso base
        tshirt_1 = 15,      -- Component 8: Undershirt
        torso_1 = 180,      -- Component 11: Top/Jacket
        chain_1 = 0,        -- Component 7: Accessory
        bags_1 = 0,         -- Component 5: Bag
        helmet_1 = 90,      -- Prop 0: Head/Hat
    }
}

-- Function to save current clothing (only if not already in a special outfit mode)
local function SaveCurrentClothes()
    -- Don't overwrite saved clothes if we already have them saved
    if savedClothes then
        return
    end

    local playerPed = PlayerPedId()
    if not IsFreemodeModel(playerPed) then return end
    savedClothes = {
        -- Components
        shoes = GetPedDrawableVariation(playerPed, 6),
        shoesTexture = GetPedTextureVariation(playerPed, 6),
        legs = GetPedDrawableVariation(playerPed, 4),
        legsTexture = GetPedTextureVariation(playerPed, 4),
        torso = GetPedDrawableVariation(playerPed, 3),
        torsoTexture = GetPedTextureVariation(playerPed, 3),
        head = GetPedPropIndex(playerPed, 0),
        headTexture = GetPedPropTextureIndex(playerPed, 0),
        undershirt = GetPedDrawableVariation(playerPed, 8),
        undershirtTexture = GetPedTextureVariation(playerPed, 8),
        accessory = GetPedDrawableVariation(playerPed, 7),
        accessoryTexture = GetPedTextureVariation(playerPed, 7),
        bag = GetPedDrawableVariation(playerPed, 5),
        bagTexture = GetPedTextureVariation(playerPed, 5),
        torso2 = GetPedDrawableVariation(playerPed, 11),
        torso2Texture = GetPedTextureVariation(playerPed, 11),
    }
end

-- Function to apply staff clothing
local function ApplyStaffClothes(forceNewColor)
    local playerPed = PlayerPedId()
    if not IsFreemodeModel(playerPed) then return end
    local isMale = IsPedMaleModel(playerPed)
    local clothes = isMale and staffClothes.male or staffClothes.female

    -- Generate random color only if we don't have one saved or force new color
    -- Note: Les couleurs sont multipliées par 2 pour le casque afin d'avoir la visière fermée
    if not staffClothesColor or forceNewColor then
        local availableColors = {0, 1, 2, 3, 4} -- Couleurs de base (multipliées par 2 pour le casque)
        staffClothesColor = availableColors[math.random(1, #availableColors)]
    end

    -- IMPORTANT: Apply in correct order for compatibility
    -- 1. First apply undershirt (component 8)
    SetPedComponentVariation(playerPed, 8, clothes.tshirt_1, 0, 2)

    -- 2. Then apply arms/torso base (component 3)
    SetPedComponentVariation(playerPed, 3, clothes.arms, 0, 2)

    -- 3. Then apply top/jacket (component 11) - this depends on arms being set correctly
    SetPedComponentVariation(playerPed, 11, clothes.torso_1, staffClothesColor, 2)

    -- 4. Apply other components (order doesn't matter for these)
    SetPedComponentVariation(playerPed, 4, clothes.pants_1, staffClothesColor, 2)  -- Pants
    SetPedComponentVariation(playerPed, 6, clothes.shoes_1, staffClothesColor, 2)  -- Shoes
    SetPedComponentVariation(playerPed, 7, clothes.chain_1, 0, 2)            -- Accessory
    SetPedComponentVariation(playerPed, 5, clothes.bags_1, 0, 2)             -- Bag

    -- 5. Apply head prop (hat/helmet)
    SetPedPropIndex(playerPed, 0, clothes.helmet_1, staffClothesColor, 2)


end

-- Function to restore original clothing
local function RestoreOriginalClothes()
    if not savedClothes then
        return
    end

    local playerPed = PlayerPedId()
    if not IsFreemodeModel(playerPed) then
        savedClothes = nil
        staffClothesColor = nil
        return
    end

    -- Restore components
    SetPedComponentVariation(playerPed, 6, savedClothes.shoes, savedClothes.shoesTexture, 2)
    SetPedComponentVariation(playerPed, 4, savedClothes.legs, savedClothes.legsTexture, 2)
    SetPedComponentVariation(playerPed, 3, savedClothes.torso, savedClothes.torsoTexture, 2)
    SetPedComponentVariation(playerPed, 8, savedClothes.undershirt, savedClothes.undershirtTexture, 2)
    SetPedComponentVariation(playerPed, 7, savedClothes.accessory, savedClothes.accessoryTexture, 2)
    SetPedComponentVariation(playerPed, 5, savedClothes.bag, savedClothes.bagTexture, 2)
    SetPedComponentVariation(playerPed, 11, savedClothes.torso2, savedClothes.torso2Texture, 2)

    -- Restore props
    if savedClothes.head >= 0 then
        SetPedPropIndex(playerPed, 0, savedClothes.head, savedClothes.headTexture, 2)
    else
        ClearPedProp(playerPed, 0)
    end

    savedClothes = nil
    staffClothesColor = nil -- Reset color for next staff mode session
end

-- Function to apply animator clothing (pink color only)
local function ApplyAnimatorClothes()
    local playerPed = PlayerPedId()
    if not IsFreemodeModel(playerPed) then return end
    local isMale = IsPedMaleModel(playerPed)
    local clothes = isMale and staffClothes.male or staffClothes.female
    local pinkColor = 7 -- Fixed pink color for animators

    -- IMPORTANT: Apply in correct order for compatibility
    -- 1. First apply undershirt (component 8)
    SetPedComponentVariation(playerPed, 8, clothes.tshirt_1, 0, 2)

    -- 2. Then apply arms/torso base (component 3)
    SetPedComponentVariation(playerPed, 3, clothes.arms, 0, 2)

    -- 3. Then apply top/jacket (component 11)
    SetPedComponentVariation(playerPed, 11, clothes.torso_1, pinkColor, 2)

    -- 4. Apply other components
    SetPedComponentVariation(playerPed, 4, clothes.pants_1, pinkColor, 2)  -- Pants
    SetPedComponentVariation(playerPed, 6, clothes.shoes_1, pinkColor, 2)  -- Shoes
    SetPedComponentVariation(playerPed, 7, clothes.chain_1, 0, 2)          -- Accessory
    SetPedComponentVariation(playerPed, 5, clothes.bags_1, 0, 2)           -- Bag

    -- 5. Apply head prop (hat/helmet)
    SetPedPropIndex(playerPed, 0, clothes.helmet_1, pinkColor, 2)
end

-- Event handler for staff clothes
RegisterNetEvent("vfw:staff:setStaffClothes", function(enable)
    if not VFW.StaffOutfitEnabled then
        isStaffOutfitActive = false
        if not enable and not isAnimatorOutfitActive then
            RestoreOriginalClothes()
        end
        return
    end

    if enable then
        -- Defensive: ignore late "enable" event if the player is no longer in staff mode
        -- (can happen with rapid toggles when network events get reordered)
        local myId = GetPlayerServerId(PlayerId())
        local isInStaffMode = false
        for _, staffId in ipairs(VFW.staffMode or {}) do
            if staffId == myId then
                isInStaffMode = true
                break
            end
        end
        if not isInStaffMode then return end

        SaveCurrentClothes()
        ApplyStaffClothes(true) -- Force new random color when entering staff mode
        isStaffOutfitActive = true
    else
        isStaffOutfitActive = false
        -- Only restore original clothes if animator mode is also not active
        if not isAnimatorOutfitActive then
            RestoreOriginalClothes()
        end
    end
end)

-- Event handler for animator clothes
RegisterNetEvent("vfw:staff:setAnimatorClothes", function(enable)
    if enable then
        SaveCurrentClothes()
        ApplyAnimatorClothes()
        isAnimatorOutfitActive = true
    else
        isAnimatorOutfitActive = false
        -- If staff mode is still active, reapply staff clothes instead of restoring original
        if VFW.StaffOutfitEnabled and isStaffOutfitActive then
            ApplyStaffClothes(false) -- Keep the same color
        else
            RestoreOriginalClothes()
        end
    end
end)

-- Continuously enforce staff clothes while in staff mode
CreateThread(function()
    local lastCheckTime = 0
    local checkInterval = 1000 -- Check every second

    while true do
        Wait(100)

        -- Check if player is in staff mode
        local isStaffMode = false
        for _, staffId in ipairs(VFW.staffMode or {}) do
            if staffId == GetPlayerServerId(PlayerId()) then
                isStaffMode = true
                break
            end
        end

        -- Check if player has bypass outfit permission and preference
        local bypassOutfit = false
        if VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["bypass_staff_outfit"] then
            bypassOutfit = GetResourceKvpString("staff_bypass_outfit") == "true"
      end

        -- Only enforce staff clothes if in staff mode, has saved clothes, doesn't have bypass, and not in animator mode
        if VFW.StaffOutfitEnabled and isStaffMode and savedClothes and not bypassOutfit and not isAnimatorOutfitActive then
            local currentTime = GetGameTimer()

            -- Only check every second to reduce performance impact
            if currentTime - lastCheckTime >= checkInterval then
                lastCheckTime = currentTime

                local playerPed = PlayerPedId()
                if not IsFreemodeModel(playerPed) then goto continueLoop end
                local isMale = IsPedMaleModel(playerPed)
                local clothes = isMale and staffClothes.male or staffClothes.female

                -- Check if staff clothes are still applied
                local currentTorso = GetPedDrawableVariation(playerPed, 11)
                local currentHelmet = GetPedPropIndex(playerPed, 0)

                if currentTorso ~= clothes.torso_1 then
                    -- Reapply staff clothes if they were changed (keep same color)
                    ApplyStaffClothes(false)
                elseif currentHelmet ~= clothes.helmet_1 then
                    -- Reapply just the helmet if only it was removed (e.g., entering vehicle)
                    if staffClothesColor then
                        SetPedPropIndex(playerPed, 0, clothes.helmet_1, staffClothesColor, 2)
                    end
                end
                ::continueLoop::
            end
        end
    end
end)

-- Clean up on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    -- Restore original clothes if resource stops while in staff/animator mode
    if savedClothes then
        RestoreOriginalClothes()
    end
    isStaffOutfitActive = false
    isAnimatorOutfitActive = false
end)

