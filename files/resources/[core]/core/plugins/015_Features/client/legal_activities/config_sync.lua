---@meta _
---@diagnostic disable: duplicate-doc-field

---
--- Legal Activities Config Sync (Client)
--- Registry for seller NPCs/blips + position/visibility update handlers
---

-- Global registry: { ["fishing_1"] = { entityId, blip, pedObj }, ... }
LegalActivitySellers = LegalActivitySellers or {}

--- Delete an existing seller NPC and its blip
---@param key string Registry key (e.g. "fishing_1")
local function DeleteSeller(key)
    local entry = LegalActivitySellers[key]
    if not entry then return end

    if entry.pedObj and entry.pedObj.delete then
        pcall(function() entry.pedObj:delete() end)
    elseif entry.entityId and DoesEntityExist(entry.entityId) then
        DeleteEntity(entry.entityId)
    end

    if entry.blip and DoesBlipExist(entry.blip) then
        RemoveBlip(entry.blip)
    end

    LegalActivitySellers[key] = nil
end

--- Ensure collision is loaded at a position
---@param x number
---@param y number
---@param z number
local function EnsureCollisionLoaded(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    local attempts = 0
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and attempts < 20 do
        RequestCollisionAtCoord(x, y, z)
        Wait(50)
        attempts = attempts + 1
    end
end

--- Create a seller NPC at a given position
---@param key string Registry key
---@param model string Ped model name
---@param position table {x, y, z, w}
---@param blipData table|nil {sprite, color, scale, label, radius?}
---@return number|nil entityId
local function CreateSeller(key, model, position, blipData)
    -- Ensure collision is loaded so the ped doesn't float in the air
    EnsureCollisionLoaded(position.x, position.y, position.z)

    local ped = cEntity.Manager:CreatePedLocal(model,
        vector3(position.x, position.y, position.z), position.w)
    local pedId = ped:getEntityId()

    -- Place on ground properly after creation
    PlaceObjectOnGroundProperly(pedId)

    ped:setFreeze(true)
    SetEntityInvincible(pedId, true)
    SetBlockingOfNonTemporaryEvents(pedId, true)
    TaskStartScenarioInPlace(pedId, "WORLD_HUMAN_CLIPBOARD", 0, true)

    local blip = nil
    if blipData then
        blip = VFW.CreateBlipInternal(
            vector4(position.x, position.y, position.z, position.w),
            blipData.sprite, blipData.color, blipData.scale, blipData.label,
            blipData.alpha, blipData.secondaryColor
        )
        if blip then
            SetBlipDisplay(blip, 4)
            SetBlipAsShortRange(blip, true)
        end
    end

    LegalActivitySellers[key] = {
        entityId = pedId,
        pedObj = ped,
        blip = blip
    }

    return pedId
end

--- Blip config per activity
local BlipConfig = {
    fishing = function()
        return { sprite = 356, color = 3, scale = 0.5, label = "Acheteur de poissons" }
    end,
    hunting = function()
        return { sprite = 463, color = 24, scale = 0.6, label = "Acheteur de viande", alpha = 100, secondaryColor = 24 }
    end,
    diving = function()
        return { sprite = 729, color = 32, scale = 0.5, label = "Acheteur d'objets plongée", alpha = 100, secondaryColor = 32 }
    end
}

--- Get model for a seller by activity and key
local function GetSellerModel(activity, sellerKey, posData)
    -- Use model from posData if available (DB-stored sellers)
    if posData and posData.model then
        return posData.model
    end
    -- Fallback to Config
    if activity == "fishing" then
        local idx = tonumber(sellerKey)
        return idx and Config.fishing.resell[idx] and Config.fishing.resell[idx].model or nil
    elseif activity == "hunting" then
        local idx = tonumber(sellerKey)
        return idx and Config.hunting.sellers[idx] and Config.hunting.sellers[idx].ped or nil
    elseif activity == "diving" then
        local idx = tonumber(sellerKey)
        return idx and Config.diving.sellers[idx] and Config.diving.sellers[idx].ped or nil
    end
    return nil
end

--- Patch client-side Config with new position
local function PatchConfig(activity, sellerKey, posData)
    if activity == "fishing" then
        local idx = tonumber(sellerKey)
        if not idx then return end
        if Config.fishing.resell[idx] then
            Config.fishing.resell[idx].coords = vector4(posData.x, posData.y, posData.z, posData.w)
        else
            Config.fishing.resell[idx] = {
                coords = vector4(posData.x, posData.y, posData.z, posData.w),
                model = posData.model or "ig_cletus"
            }
        end
    elseif activity == "hunting" then
        local idx = tonumber(sellerKey)
        if not idx then return end
        if Config.hunting.sellers[idx] then
            Config.hunting.sellers[idx].position = vec4(posData.x, posData.y, posData.z, posData.w)
        else
            Config.hunting.sellers[idx] = {
                position = vec4(posData.x, posData.y, posData.z, posData.w),
                ped = posData.model or "s_m_m_lathandy_01"
            }
        end
    elseif activity == "diving" then
        local idx = tonumber(sellerKey)
        if not idx then return end
        if Config.diving.sellers[idx] then
            Config.diving.sellers[idx].position = vec4(posData.x, posData.y, posData.z, posData.w)
        else
            Config.diving.sellers[idx] = {
                position = vec4(posData.x, posData.y, posData.z, posData.w),
                ped = posData.model or "s_m_m_highsec_01"
            }
        end
    end
end

--- Initial load: request all sellers from server once player is fully loaded
CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(100) end
    Wait(2000)

    local config = TriggerServerCallback('legalActivities:getConfig')
    if not config then return end

    for activity, data in pairs(config) do
        if data.sellers then
            for _, seller in ipairs(data.sellers) do
                if seller.visible ~= false and seller.model and seller.coords then
                    local key = activity .. "_" .. seller.index
                    if not LegalActivitySellers[key] then
                        PatchConfig(activity, tostring(seller.index), {
                            x = seller.coords.x, y = seller.coords.y, z = seller.coords.z, w = seller.coords.w,
                            model = seller.model
                        })
                        local blipCfg = BlipConfig[activity] and BlipConfig[activity]() or nil
                        CreateSeller(key, seller.model, seller.coords, blipCfg)
                    end
                end
            end
        end
    end
end)

--- Handle position update from server
RegisterNetEvent('legalActivities:sellerPositionUpdated')
AddEventHandler('legalActivities:sellerPositionUpdated', function(activity, sellerKey, posData)
    local registryKey = activity .. "_" .. sellerKey

    -- Delete existing NPC/blip
    DeleteSeller(registryKey)

    -- Patch client-side Config
    PatchConfig(activity, sellerKey, posData)

    -- Only create if visible
    local visible = posData.visible
    if visible == false then return end

    -- Recreate NPC + blip at new position
    local model = GetSellerModel(activity, sellerKey, posData)
    if not model then return end

    local blipCfg = BlipConfig[activity] and BlipConfig[activity]() or nil
    CreateSeller(registryKey, model, posData, blipCfg)
end)

--- Handle visibility toggle from server
RegisterNetEvent('legalActivities:sellerVisibilityChanged')
AddEventHandler('legalActivities:sellerVisibilityChanged', function(activity, sellerKey, visible, posData)
    local registryKey = activity .. "_" .. sellerKey

    if visible then
        -- Show: create NPC if not already present
        if LegalActivitySellers[registryKey] then return end
        if not posData then return end

        PatchConfig(activity, sellerKey, posData)

        local model = GetSellerModel(activity, sellerKey, posData)
        if not model then return end

        local blipCfg = BlipConfig[activity] and BlipConfig[activity]() or nil
        CreateSeller(registryKey, model, posData, blipCfg)
    else
        -- Hide: delete NPC + blip
        DeleteSeller(registryKey)
    end
end)

--- Handle seller deletion from server
RegisterNetEvent('legalActivities:sellerDeleted')
AddEventHandler('legalActivities:sellerDeleted', function(activity, sellerKey)
    local registryKey = activity .. "_" .. sellerKey
    DeleteSeller(registryKey)
end)
