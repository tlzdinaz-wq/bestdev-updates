---@meta _
---@diagnostic disable: duplicate-doc-field

local bagOpen = false
local currentBagUUID = nil

local placedBags = {}

local BAG_MODEL = `prop_cs_heist_bag_01`

-- Valeurs de placement du sac (ajustables via /bagadjust)
local BAG_ROT_X = -14.337
local BAG_ROT_Y = 14.412
local BAG_HEADING_OFFSET = 2.088
local BAG_Z_OFFSET = 0.0

--- Place un objet sac au sol à plat (sans PlaceObjectOnGroundProperly qui tilt le prop)
---@param object number Entity handle
---@param x number
---@param y number
---@param z number
---@param heading number
local function placeBagFlat(object, x, y, z, heading)
    SetEntityHeading(object, heading)
    FreezeEntityPosition(object, false)
    SetEntityDynamic(object, true)
    ActivatePhysics(object)

    -- Laisser la physique faire tomber le sac au sol naturellement
    local timeout = GetGameTimer() + 3000
    Wait(200)
    while GetGameTimer() < timeout do
        local vel = GetEntityVelocity(object)
        local speed = #vel
        if speed < 0.01 then
            break
        end
        Wait(50)
    end

    -- Le sac est posé, on applique la rotation et on freeze
    local coords = GetEntityCoords(object)
    SetEntityCoords(object, coords.x, coords.y, coords.z + BAG_Z_OFFSET, false, false, false, false)
    SetEntityRotation(object, BAG_ROT_X, BAG_ROT_Y, heading + BAG_HEADING_OFFSET, 2, true)
    Wait(50)
    FreezeEntityPosition(object, true)
end

local savedSkinBeforeBag = nil
local loadedOutfits = {}

-- Clothing keys used for preview save/restore (only clothing, not face/body)
local CLOTHING_KEYS = {
    "torso_1", "torso_2", "tshirt_1", "tshirt_2",
    "arms", "arms_2",
    "pants_1", "pants_2", "shoes_1", "shoes_2",
    "chain_1", "chain_2", "bags_1", "bags_2",
    "bproof_1", "bproof_2", "decals_1", "decals_2",
    "mask_1", "mask_2", "helmet_1", "helmet_2",
    "glasses_1", "glasses_2", "ears_1", "ears_2",
    "watches_1", "watches_2", "bracelets_1", "bracelets_2"
}

-- Category -> skinchanger keys mapping
local CATEGORY_MAP = {
    torso      = { "torso_1", "torso_2" },
    torso2     = { "torso_1", "torso_2" },
    undershirt = { "tshirt_1", "tshirt_2" },
    arms       = { "arms", "arms_2" },
    leg        = { "pants_1", "pants_2" },
    shoes      = { "shoes_1", "shoes_2" },
    accessory  = { "chain_1", "chain_2" },
    bag        = { "bags_1", "bags_2" },
    armor      = { "bproof_1", "bproof_2" },
    decal      = { "decals_1", "decals_2" },
    mask       = { "mask_1", "mask_2" },
    hat        = { "helmet_1", "helmet_2" },
    glasses    = { "glasses_1", "glasses_2" },
    ear        = { "ears_1", "ears_2" },
    watch      = { "watches_1", "watches_2" },
    bracelet   = { "bracelets_1", "bracelets_2" },
}

--- Restore clothing from savedSkinBeforeBag (key-by-key, no model reload)
local function restoreClothingFromSaved()
    if not savedSkinBeforeBag then return end
    for _, key in ipairs(CLOTHING_KEYS) do
        if savedSkinBeforeBag[key] ~= nil then
            TriggerEvent("skinchanger:change", key, savedSkinBeforeBag[key])
        end
    end
end

--- Charge un dictionnaire d'animations avec timeout
---@param dict string Nom du dictionnaire
---@param timeout number|nil Timeout en ms (defaut: 5000)
---@return boolean True si le dict a ete charge
local function LoadAnimDictAsync(dict, timeout)
    timeout = timeout or 5000
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local startTime = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        if (GetGameTimer() - startTime) > timeout then return false end
        Wait(10)
    end
    return true
end

local function getBagUUIDFromEntity(object)
    for uuid, data in pairs(placedBags) do
        if data.object == object then
            return uuid
        end
    end
    return nil
end

VFW.ContextAddButton("object", " Ouvrir le sac", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 5.0 and DoesEntityExist(object) and GetEntityModel(object) == BAG_MODEL and getBagUUIDFromEntity(object) ~= nil
end, function(object)
    local bagUUID = getBagUUIDFromEntity(object)
    if bagUUID then
        openPlacedBag(bagUUID, placedBags[bagUUID])
    end
end, {})

VFW.ContextAddButton("object", " Ramasser le sac", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 5.0 and DoesEntityExist(object) and GetEntityModel(object) == BAG_MODEL and getBagUUIDFromEntity(object) ~= nil
end, function(object)
    local bagUUID = getBagUUIDFromEntity(object)
    if bagUUID then
        pickupPlacedBag(bagUUID)
    end
end, {})

RegisterNetEvent('core:placeClothesBag')
AddEventHandler('core:placeClothesBag', function(metadata)

    -- Marquer le sac comme "pending" AVANT toute création pour éviter le doublon
    -- quand le broadcast syncPlacedBag arrive avant que l'objet soit créé
    placedBags[metadata.bag_uuid] = { pending = true }

    local playerPed = PlayerPedId()

    -- Animation de pose du sac
    if LoadAnimDictAsync("pickup_object") then
        TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 2.0, 2.0, -1, 0, 0, false, false, false)
        Wait(1500)
        ClearPedTasks(playerPed)
    end

    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)

    local forwardVector = GetEntityForwardVector(playerPed)
    local bagCoords = vector3(
            playerCoords.x + forwardVector.x * 0.8,
            playerCoords.y + forwardVector.y * 0.8,
            playerCoords.z - 0.5
    )

    RequestModel(BAG_MODEL)
    while not HasModelLoaded(BAG_MODEL) do
        Wait(10)
    end

    local bagObject = CreateObject(BAG_MODEL, bagCoords.x, bagCoords.y, bagCoords.z, false, true, false)
    placeBagFlat(bagObject, bagCoords.x, bagCoords.y, bagCoords.z, playerHeading)

    if not NetworkGetEntityIsNetworked(bagObject) then
        NetworkRegisterEntityAsNetworked(bagObject)
    end
    if not NetworkGetEntityIsNetworked(bagObject) then
        placedBags[metadata.bag_uuid] = nil
        return
    end
    local netId = NetworkGetNetworkIdFromEntity(bagObject)

    local finalCoords = GetEntityCoords(bagObject)

    local coordsTable = {
        x = finalCoords.x,
        y = finalCoords.y,
        z = finalCoords.z
    }

    TriggerServerEvent('core:server:bagPlacedOnGround', coordsTable, playerHeading, metadata, netId)

    placedBags[metadata.bag_uuid] = {
        object = bagObject,
        coords = finalCoords,
        rotation = playerHeading,
        metadata = metadata,
        netId = netId
    }

end)

RegisterNetEvent('core:client:syncPlacedBag')
AddEventHandler('core:client:syncPlacedBag', function(bagUUID, coords, rotation, metadata, netId)
    if placedBags[bagUUID] then
        return
    end

    -- Essayer de récupérer l'entité réseau existante
    local bagObject = nil
    if netId then
        local tries = 0
        while tries < 20 do
            if NetworkDoesNetworkIdExist(netId) then
                bagObject = NetworkGetEntityFromNetworkId(netId)
                if bagObject and DoesEntityExist(bagObject) then
                    break
                end
            end
            tries = tries + 1
            Wait(100)
        end
    end

    -- Fallback : créer l'objet uniquement si le réseau n'a pas pu le fournir
    if not bagObject or not DoesEntityExist(bagObject) then
        RequestModel(BAG_MODEL)
        while not HasModelLoaded(BAG_MODEL) do
            Wait(10)
        end
        bagObject = CreateObject(BAG_MODEL, coords.x, coords.y, coords.z, false, true, false)
        placeBagFlat(bagObject, coords.x, coords.y, coords.z, rotation)
    end

    placedBags[bagUUID] = {
        object = bagObject,
        coords = coords,
        rotation = rotation,
        metadata = metadata,
        netId = netId
    }
end)

RegisterNetEvent('core:client:removePlacedBag')
AddEventHandler('core:client:removePlacedBag', function(bagUUID)
    local bagData = placedBags[bagUUID]

    if bagData and bagData.object then
        DeleteObject(bagData.object)
        placedBags[bagUUID] = nil
    end
end)

CreateThread(function()
    Wait(5000)

    local allBags = TriggerServerCallback('core:server:getAllPlacedBags')

    if allBags then
        for bagUUID, bagData in pairs(allBags) do
            RequestModel(BAG_MODEL)
            while not HasModelLoaded(BAG_MODEL) do
                Wait(10)
            end

            local bagObject = CreateObject(BAG_MODEL, bagData.coords.x, bagData.coords.y, bagData.coords.z, false, true, false)
            placeBagFlat(bagObject, bagData.coords.x, bagData.coords.y, bagData.coords.z, bagData.rotation)

            placedBags[bagUUID] = {
                object = bagObject,
                coords = bagData.coords,
                rotation = bagData.rotation,
                metadata = bagData.metadata,
                netId = bagData.netId
            }

        end

    end
end)


function openPlacedBag(bagUUID, bagData)

    local success, metadata = TriggerServerCallback('core:server:openPlacedBag', bagUUID)

    if not success then
        return
    end

    currentBagUUID = bagUUID

    -- Animation d'ouverture du sac (loop tant que le sac est ouvert)
    local playerPed = PlayerPedId()
    if LoadAnimDictAsync("amb@prop_human_bum_bin@base") then
        TaskPlayAnim(playerPed, "amb@prop_human_bum_bin@base", "base", 2.0, 2.0, -1, 1, 0, false, false, false)
    end

    -- Save current skin before opening bag (for preview restore)
    TriggerEvent('skinchanger:getSkin', function(skin)
        savedSkinBeforeBag = {}
        for k, v in pairs(skin) do
            savedSkinBeforeBag[k] = v
        end
    end)

    SendNUIMessage({
        action = "nui:inventory:visible",
        data = false
    })
    VFW.Nui.Focus(false)

    Wait(100)

    local outfits, isOwnBag = TriggerServerCallback("core:server:loadBagOutfits", bagUUID)

    if outfits then
        -- Cache outfit data for preview
        loadedOutfits = {}
        for _, outfit in ipairs(outfits) do
            if outfit.outfitData then
                loadedOutfits[outfit.id] = outfit.outfitData
            end
        end

        SendNUIMessage({
            action = "clothesbag:open",
            data = {
                outfits = outfits,
                isOwnBag = isOwnBag
            }
        })

        VFW.Nui.Focus(true)
        bagOpen = true

    else
    end
end

function pickupPlacedBag(bagUUID)
    local playerPed = PlayerPedId()

    -- Animation de ramassage (même que boombox)
    if LoadAnimDictAsync("pickup_object") then
        TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 2.0, 2.0, 1500, 0, 0, false, false, false)
        Wait(1500)
        ClearPedTasks(playerPed)
        RemoveAnimDict("pickup_object")
    end

    local success, message = TriggerServerCallback('core:server:pickupPlacedBag', bagUUID)

end

RegisterNUICallback("clothesbag:equipOutfit", function(data, cb)
    local outfitId = data.outfitId

    local success, outfitData, newQuantity = TriggerServerCallback("core:server:equipBagOutfit", outfitId)

    if success then
        VFW.LoadInventories()
    end

    cb({ success = success == true, newQuantity = newQuantity or 0 })
end)

RegisterNUICallback("clothesbag:removeOutfit", function(data, cb)
    local outfitId = data.outfitId

    local success, message = TriggerServerCallback("core:server:removeOutfitFromBag", outfitId)

    cb({ success = success == true })
end)

RegisterNUICallback("clothesbag:previewOutfit", function(data, cb)
    local outfitId = data.outfitId
    local outfitData = loadedOutfits[outfitId]

    if not outfitData then
        cb(false)
        return
    end

    for _, item in ipairs(outfitData) do
        local keys = CATEGORY_MAP[item.category]
        if keys then
            TriggerEvent("skinchanger:change", keys[1], item.drawableId)
            TriggerEvent("skinchanger:change", keys[2], item.variantId)
        end
    end

    cb(true)
end)

RegisterNUICallback("clothesbag:restorePreview", function(data, cb)
    restoreClothingFromSaved()
    cb(true)
end)

RegisterNUICallback("clothesbag:close", function(data, cb)
    restoreClothingFromSaved()

    -- Arrêter l'animation de fouille
    ClearPedTasks(PlayerPedId())

    VFW.Nui.Focus(false)
    bagOpen = false
    currentBagUUID = nil
    savedSkinBeforeBag = nil
    loadedOutfits = {}

    cb(true)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if bagOpen then
        restoreClothingFromSaved()
        VFW.Nui.Focus(false)
        bagOpen = false
        currentBagUUID = nil
        savedSkinBeforeBag = nil
        loadedOutfits = {}
    end
    for uuid, bagData in pairs(placedBags) do
        if bagData.object and DoesEntityExist(bagData.object) then
                DeleteEntity(bagData.object)
        end
    end
    placedBags = {}
end)
