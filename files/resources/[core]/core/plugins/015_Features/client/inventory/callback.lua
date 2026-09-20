---@meta _
---@diagnostic disable: duplicate-doc-field

-- Import reverse mapping function from main.lua
local function reverseMapItemType(clientType)
    local reverseMapping = {
        ["items"] = "items",
        ["weapon"] = "weapons", -- Frontend "weapon" → Server "weapons"
        ["clothes"] = "clothes",
        ["food"] = "food",
        ["drink"] = "drink",
        ["outfit"] = "outfit"
    }
    return reverseMapping[clientType] or clientType
end

-- Deep copy inventory to avoid reference issues
-- When saving oldInventory before a server callback, we need a real copy
-- because VFW.PlayerData.inventory gets modified by vfw:updateInventory event
-- BEFORE the callback returns, making oldInventory and newInventory identical
local function deepCopyInventory(inventory)
    if not inventory then return nil end
    return json.decode(json.encode(inventory))
end

local function isReadOnlyTarget()
    return VFW.PlayerData.target and VFW.PlayerData.target.readOnly == true
end

local function notifyReadOnly()
    VFW.ShowNotification({
        type = 'ROUGE',
        content = "Inventaire en lecture seule"
    })
end

--- DataToInfo
---@param data table
function DataToInfo(data)
    local info = {}
    local rawQuantity = tonumber(data.quantity) or 0
    local quantity = rawQuantity > 0 and rawQuantity or nil

    local isItemPool = VFW.PlayerData.target and VFW.PlayerData.target.type == "item_pool"

    if data.item.id then
        info = {
            slot = data.item.originalSlot and data.item.originalSlot or data.item.slot,
            type = reverseMapItemType(data.item.type),
            quantity = quantity or data.item.count,
            targetSlot = data.to and tonumber(data.to) or nil
        }

        if isItemPool then
            info.name = data.item.name
            info.meta = data.item.metadatas or {}
        end
    else
        for k, v in pairs(data.item) do
            info[k] = {
                slot = v.originalSlot and v.originalSlot or v.slot,
                type = reverseMapItemType(v.type),
                quantity = quantity or v.count
            }

            if isItemPool then
                info[k].name = v.name
                info[k].meta = v.metadatas or {}
            end
        end
    end

    return info
end

local pedModel = {
    ["m"] = 0,
    ["w"] = 1
}

-- Mapping des types vers les composants skin pour déséquiper les vêtements
local translateSkinForUnequip = {
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
    ["top"] = { "torso_1", "torso_2" }
}

--- Helper function to unequip clothing if THIS SPECIFIC item is equipped
--- Called when dropping or giving a clothing item
---@param data table The item data from the NUI callback
local function unequipClothingIfEquipped(data)
    if not data or not data.item then return end

    local itemName = data.item.name
    if not itemName or not VFW.Items[itemName] then return end

    local itemInfo = VFW.Items[itemName]

    -- Check if it's a clothing or outfit item
    if itemInfo.type ~= "clothes" and itemInfo.type ~= "outfit" then
        return
    end

    local meta = data.item.metadatas or data.item.meta or {}

    -- Handle outfit - check if skin matches
    if itemInfo.type == "outfit" then
        if GetClothes["outfit"] and meta.skin then
            local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
            if skin then
                local isThisOutfitEquipped = true
                for k, v in pairs(meta.skin) do
                    if skin[k] ~= v then
                        isThisOutfitEquipped = false
                        break
                    end
                end
                if isThisOutfitEquipped then
                    TriggerEvent("vfw:clothes", "outfit", {
                        action = "off",
                        sex = meta.sex or "m"
                    })
                end
            end
        end
        return
    end

    -- Handle individual clothing - verify THIS specific item is equipped
    local clothingType = meta.type or itemName
    if not GetClothes[clothingType] then return end

    -- Special handling for top with composite skin
    if clothingType == "top" and meta.skin then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
        if skin then
            local isEquipped = true
            for k, v in pairs(meta.skin) do
                if skin[k] ~= v then
                    isEquipped = false
                    break
                end
            end
            if isEquipped then
                TriggerEvent("vfw:clothes", itemName, {
                    type = clothingType,
                    action = "off",
                    sex = meta.sex or "m"
                })
            end
        end
        return
    end

    -- Standard clothing - compare skin components with item metadata
    local components = translateSkinForUnequip[clothingType]
    if not components then return end

    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
    if not skin then return end

    local skinVal1 = tonumber(skin[components[1]]) or 0
    local skinVal2 = tonumber(skin[components[2]]) or 0
    local metaId = tonumber(meta.id) or 0
    local metaVar = tonumber(meta.var) or 0

    -- Check if THIS specific item is equipped
    if skinVal1 == metaId and skinVal2 == metaVar then
        TriggerEvent("vfw:clothes", itemName, {
            type = clothingType,
            action = "off",
            sex = meta.sex or "m"
        })
    end
end

--- Returns true if the user confirms the don of an identifier-bound item.
--- Bound items (meta.identifier set, e.g. weapons bought in boutique) stay
--- usable only by the original buyer. The recipient can carry/store but
--- cannot use them. We warn the giver before letting the transfer proceed.
---@param meta table|nil
---@return boolean
local function confirmGiveBoundItem(meta)
    if not meta or not meta.identifier then
        return true
    end

    local choice = VFW.Nui.ChoiceInput(
        "Objet personnel",
        "Cet objet est lié à un propriétaire. Le destinataire pourra le transporter mais ne pourra pas l'utiliser. Continuer ?",
        {
            { label = "Donner quand même", value = "yes" },
            { label = "Annuler",           value = "no" }
        }
    )
    return choice == "yes"
end

--- Returns true if the user confirms (or no confirmation is needed) for the
--- whole payload sent to `vfw:giveItem`. Handles both single-item (data.item.id)
--- and multi-item (data.item is a map) shapes produced by DataToInfo.
---@param data table
---@return boolean
local function confirmGiveBoundFromData(data)
    if not data or not data.item then
        return true
    end

    if data.item.id then
        return confirmGiveBoundItem(data.item.metadatas)
    end

    for _, v in pairs(data.item) do
        if v and v.metadatas and v.metadatas.identifier then
            return confirmGiveBoundItem(v.metadatas)
        end
    end

    return true
end

--- RefreshInventory
---@param data table
--- RefreshInventory
---@param data table
local function RefreshInventory(data)
    local info = {}

    if not data or not data.item then
        return
    end

    -- 🚨 IMPORTANTE: Si venimos de un desequipado (action == "off"),
    -- NO queremos que el refresh vuelva a equipar la prenda.
    if data.action == "off" then
        return
    end

    if data.item.id then
        info = {
            type = data.item.type,
            name = data.item.name,
            meta = data.item.metadatas or {}
        }
    else
        -- Caso de lista de items, no hacemos nada para evitar bucles
        return
    end

    if not info.name or not VFW.Items[info.name] then
        return
    end

    -- Lógica para Ropa
    if VFW.Items[info.name].type == "clothes" then
        -- 🚨 SOLO refrescamos si el item está explícitamente marcado como equipado
        -- Si no tiene el flag 'isEquipped', ignoramos el refresh para que no se ponga sola
        if info.meta.isEquipped then
            if GetClothes[info.name] then
                TriggerEvent("skinchanger:getSkin", function(skin)
                    local playerSex = skin.sex == 0 and "m" or "f"
                    if info.meta.sex == playerSex then
                        if data.item.metadatas and info.meta.id == data.item.metadatas.id then
                            TriggerEvent("vfw:clothes", info.name, info.meta)
                        end
                    end
                end)
            end
        else
        end
    end
end

local isDragging = false
RegisterNUICallback("nui:inventory:drag-item", function(data)
    isDragging = data.isDragging

    local SCREEN_X <const>, SCREEN_Y <const> = GetActiveScreenResolution()

    while isDragging do
        local x, y = GetNuiCursorPosition()
        local hit, worldPosition, normalDirection, entity = RaycastScreen(vector2(x / SCREEN_X, y / SCREEN_Y), 100.0,
                VFW.PlayerData.ped)

        local change = false
        if entity and IsEntityAPed(entity) and IsPedAPlayer(entity) then
            change = true
            SetEntityAlpha(entity, 200, false)
        end

        Wait(100)
        if change then
            ResetEntityAlpha(entity)
        end
    end
end)

RegisterNUICallback("nui:inventory:move-item", function(data)
    local slotStart = data.item.slot
    local slotEnd = tonumber(data.to)

    if not slotEnd then
        console.error("Invalid slot destination:", data.to)
        return
    end

    local inventory, weight = TriggerServerCallback("vfw:moveItem", slotStart, slotEnd, data.item.type)
    VFW.PlayerData.inventory = inventory
    VFW.PlayerData.weight = weight
    VFW.LoadInventories()
end)

RegisterNUICallback("nui:inventory:updateSlot", function(data, cb)
    local fromSlot = tonumber(data.fromSlot)
    local toSlot = tonumber(data.toSlot)

    if not fromSlot or not toSlot then
        if cb then cb("ok") end
        return
    end

    if data.containerId == "user-inventory" then
        local inventory, weight = TriggerServerCallback("vfw:moveItem", fromSlot, toSlot)
        VFW.PlayerData.inventory = inventory
        VFW.PlayerData.weight = weight
        VFW.LoadInventories()
    elseif data.containerId == "secondary-inventory" then
        if isReadOnlyTarget() then
            notifyReadOnly()
            if cb then cb("ok") end
            return
        end
        if VFW.PlayerData.target and VFW.PlayerData.target.chestId then
            TriggerServerEvent("vfw:chest:moveItem", VFW.PlayerData.target.chestId, fromSlot, toSlot)
        elseif VFW.PlayerData.target and VFW.PlayerData.target.pickupId then
            TriggerServerEvent("vfw:pickup:moveItem", VFW.PlayerData.target.pickupId, fromSlot, toSlot)
        end
    end

    if cb then cb("ok") end
end)

RegisterNUICallback("nui:inventory:toggle-shortcuts", function()
    VFW.PlayerData.shortcutsActive = not VFW.PlayerData.shortcutsActive
    SetResourceKvpInt("vfw:ShorcutActive", VFW.PlayerData.shortcutsActive and 1 or 0)
    VFW.LoadInventories()
end)

local ArmorPlateItems = {
    ["armor_plate_light"] = true,
    ["armor_plate_medium"] = true,
    ["armor_plate_heavy"] = true
}

RegisterNUICallback("nui:inventory:use-item", function(data)
    if LocalPlayer.state.isCuffed then
        SendNUIMessage({
            action = "nui:inventory:error",
            data = { message = "Vous ne pouvez pas faire cette action en étant menotté" }
        })
        return
    end

    if meta and meta.prison and meta.prison.isPrisoned then
        SendNUIMessage({
            action = "nui:inventory:error",
            data = { message = "Vous ne pouvez pas faire cette action en prison" }
        })
        return
    end

    if IsWeaponChanging then
        return
    end

    if ArmorPlateItems[data.item.name] then
        -- Vérifier si un gilet est équipé (flag OU drawable visible)
        local bproofDrawable = GetPedDrawableVariation(PlayerPedId(), 9)
        if not GetClothes["gpb"] and (not bproofDrawable or bproofDrawable <= 0) then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Tu dois porter un gilet par balles"
            })
            return
        end
        -- Animation d'équipement
        local ped = PlayerPedId()
        local animDict = "missmic4"
        RequestAnimDict(animDict)
        local t = 0
        while not HasAnimDictLoaded(animDict) and t < 50 do Wait(0) t = t + 1 end
        if HasAnimDictLoaded(animDict) then
            TaskPlayAnim(ped, animDict, "michael_tux_fidget", 3.0, 3.0, 2000, 51, 0, false, false, false)
        end

        local ped = PlayerPedId()
        TriggerServerEvent("vfw:armor:equipPlate", data.item.slot, data.item.name,
            GetPedDrawableVariation(ped, 9), GetEntityModel(ped) == GetHashKey("mp_f_freemode_01") and "f" or "m")
        Wait(100)
        VFW.LoadInventories()
        return
    end

    if weaponOnBackName == data.item.name then
        PlayBackToHandAnim()
        RemoveWeaponProp()
    end

    if data.item.name ~= "radio" then
        TriggerEvent("radio:deactivate")
    end

    -- Outfits : équiper via le système d'inventaire NUI (slot outfit)
    if data.item.name == "outfit" and data.item.metadatas and data.item.metadatas.skin then
        SendNUIMessage({
            action = "nui:inventory:equipOutfitFromUse",
            data = {
                slot = data.item.slot,
                itemId = data.item.id,
                outfitId = data.item.metadatas.outfitId,
                metaId = data.item.metadatas.id
            }
        })
        return
    end

    local inventory, weight, notUsable = TriggerServerCallback("vfw:useItem", data.item.name, data.item.metadatas, data.item.slot)
    VFW.PlayerData.inventory = inventory
    VFW.PlayerData.weight = weight
    VFW.LoadInventories()

    if notUsable then
        SendNUIMessage({
            action = "nui:inventory:error",
            data = { message = "Cet objet n'est pas utilisable." }
        })
    end
end)

RegisterNUICallback("nui:inventory:throw-item", function(data)
    -- Unequip clothing if this specific item is equipped
    unequipClothingIfEquipped(data)

    local info = DataToInfo(data)
    local SCREEN_X <const>, SCREEN_Y <const> = GetActiveScreenResolution()
    local x, y = GetNuiCursorPosition()
    local hit, worldPosition, normalDirection, entity = RaycastScreen(vector2(x / SCREEN_X, y / SCREEN_Y), 100.0,
            VFW.PlayerData.ped)

    if entity and IsEntityAPed(entity) and IsPedAPlayer(entity) then
        local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))

        if not confirmGiveBoundFromData(data) then
            return
        end

        -- Security is now automatically handled by callback override!
        local inventory, weight = TriggerServerCallback("vfw:giveItem", id, info)
        VFW.PlayerData.inventory = inventory
        VFW.PlayerData.weight = weight
        VFW.LoadInventories()
        RefreshInventory(data)
    else
        local inventory, weight = TriggerServerCallback("vfw:dropItem", info)
        VFW.PlayerData.inventory = inventory
        VFW.PlayerData.weight = weight
        VFW.LoadInventories()
        RefreshInventory(data)
    end
end)

--TODO: Handle more than weapon type
-- Function to clean corrupted shortcuts data
local function cleanShortcutsData()
    local cleanedShortcuts = {}

    -- Only keep valid slots 1-5 and remove duplicates/invalid indices
    for i = 1, 5 do
        if VFW.PlayerData.shortcuts[i] and type(VFW.PlayerData.shortcuts[i]) == "table" then
            cleanedShortcuts[i] = VFW.PlayerData.shortcuts[i]
        end
    end

    VFW.PlayerData.shortcuts = cleanedShortcuts
    SetResourceKvp("vfw:Shorcut", json.encode(VFW.PlayerData.shortcuts))
end

RegisterNUICallback("nui:inventory:assignShortcut", function(data)
    -- Clean corrupted data first
    cleanShortcutsData()

    -- Convert from 0-based to 1-based index
    local shortcutIndex = data.index + 1

    local shortcutData = { name = data.item.name, metadatas = data.item.metadatas }
    VFW.PlayerData.shortcuts[shortcutIndex] = shortcutData
    SetResourceKvp("vfw:Shorcut", json.encode(VFW.PlayerData.shortcuts))
end)

RegisterNUICallback("nui:inventory:reorderShortcut", function(data)
    -- Swap shortcuts positions
    local fromIndex = data.from + 1 -- Convert from 0-based to 1-based
    local toIndex = data.to + 1     -- Convert from 0-based to 1-based

    local fromShortcut = VFW.PlayerData.shortcuts[fromIndex]
    local toShortcut = VFW.PlayerData.shortcuts[toIndex]

    VFW.PlayerData.shortcuts[fromIndex] = toShortcut
    VFW.PlayerData.shortcuts[toIndex] = fromShortcut

    SetResourceKvp("vfw:Shorcut", json.encode(VFW.PlayerData.shortcuts))
end)

RegisterNUICallback("nui:inventory:removeShortcut", function(data)
    -- Clean corrupted data first
    cleanShortcutsData()

    -- Convert from 0-based to 1-based index
    local shortcutIndex = data.index + 1

    -- Remove the shortcut
    VFW.PlayerData.shortcuts[shortcutIndex] = nil
    SetResourceKvp("vfw:Shorcut", json.encode(VFW.PlayerData.shortcuts))

end)

RegisterNUICallback("nui:inventory:split", function(data)
    if (data.split <= 0) and (data.split >= data.item.count) then
        return
    end

    local inventory, weight = TriggerServerCallback("vfw:splitItem", data.item.position, data.item.type, data.split)
    VFW.PlayerData.inventory = inventory
    VFW.PlayerData.weight = weight
    VFW.LoadInventories()
end)

RegisterNUICallback("nui:inventory:rename", function(data)
    if data.item.name == "money" then
        return
    end

    local inventory, weight = TriggerServerCallback("vfw:renameItem", data.item.position, data.item.type, data.name)
    VFW.PlayerData.inventory = inventory
    VFW.PlayerData.weight = weight
    VFW.LoadInventories()
end)

RegisterNUICallback("nui:inventory:focus", function()
    SetNuiFocusKeepInput(true)
end)

RegisterNUICallback("nui:inventory:unfocus", function()
    SetNuiFocusKeepInput(false)
end)

RegisterNUICallback("nui:inventory:close", function(_, cb)
    cb("ok")
    VFW.CloseInventory()
end)

RegisterNUICallback("nui:inventory:put-item", function(data)
    if isReadOnlyTarget() then
        notifyReadOnly()
        return
    end

    -- Bloquer si c'est un inventaire infini
    if VFW.PlayerData.target and VFW.PlayerData.target.infiniteItems then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous ne pouvez pas déposer d'items dans cet inventaire"
        })
        return
    end

    -- Unequip clothing if this specific item is equipped
    unequipClothingIfEquipped(data)

    local inventory, weight
    local info = DataToInfo(data)
    if VFW.PlayerData.target.chestId then
        inventory, weight = TriggerServerCallback("vfw:chest:put-item", VFW.PlayerData.target.chestId, info,
                VFW.PlayerData.target.type)
    elseif VFW.PlayerData.target.pickupId then
        inventory, weight = TriggerServerCallback("vfw:pickup:put-item", VFW.PlayerData.target.pickupId, info,
                VFW.PlayerData.target.type)
    end

    VFW.PlayerData.inventory = inventory
    VFW.PlayerData.weight = weight
    VFW.LoadInventories()
    RefreshInventory(data)
end)

RegisterNUICallback("nui:inventory:take-item", function(data)
    if isReadOnlyTarget() then
        notifyReadOnly()
        return
    end

    local inventory, weight
    local info = DataToInfo(data)

    -- Si c'est un inventaire infini, on utilise un callback spécial
    if VFW.PlayerData.target and VFW.PlayerData.target.infiniteItems then
        -- Récupérer le nom de l'item depuis le slot
        local itemName = VFW.GetInfiniteItemNameFromSlot(info.slot)
        if not itemName then
            console.error("Failed to get item name from infinite items inventory for slot: " .. tostring(info.slot))
            return
        end
        inventory, weight = TriggerServerCallback("vfw:infiniteItems:take-item", itemName, info.quantity or 1)
    elseif VFW.PlayerData.target then
        if VFW.PlayerData.target.chestId then
            inventory, weight = TriggerServerCallback("vfw:chest:take-item", VFW.PlayerData.target.chestId, info,
                    VFW.PlayerData.target.type)
        elseif VFW.PlayerData.target.pickupId then
            inventory, weight = TriggerServerCallback("vfw:pickup:take-item", VFW.PlayerData.target.pickupId, info,
                    VFW.PlayerData.target.type)
        elseif VFW.PlayerData.target and VFW.PlayerData.target.type == "item_pool" then
            inventory, weight = TriggerServerCallback("vfw:itemPool:take-item", info)
        elseif VFW.PlayerData.target.targetId then
            inventory, weight = TriggerServerCallback("vfw:search:take-item", VFW.PlayerData.target.targetId, info)
        end
    else
        -- Taking from "Nearby" inventory
        inventory, weight = TriggerServerCallback("vfw:pickup:takeFromNearby", info)
    end

    if not inventory then
        console.error("Failed to get inventory response from server for take-item operation")
        return
    end

    VFW.PlayerData.inventory = inventory
    if weight then
        VFW.PlayerData.weight = weight
    end

    -- Delay VFW.LoadInventories() slightly to avoid target state conflicts
    CreateThread(function()
        Wait(100) -- Small delay to ensure transaction is complete
        VFW.LoadInventories()
    end)
    RefreshInventory(data)
end)

-- Callback pour récupérer un item depuis le menu contextuel
-- Utilise la même logique que take-item
RegisterNUICallback("nui:inventory:retrieve", function(data)
    if isReadOnlyTarget() then
        notifyReadOnly()
        return
    end

    local inventory, weight
    local info = DataToInfo(data)

    -- Si c'est un inventaire infini, on utilise un callback spécial
    if data.infiniteItems then
        -- Récupérer le nom de l'item depuis le slot
        local itemName = data.item.name
        if not itemName then
            console.error("Failed to get item name from infinite items inventory for slot: " .. tostring(info.slot))
            return
        end

        inventory, weight = TriggerServerCallback("vfw:infiniteItems:take-item", itemName, info.quantity or 1)
    elseif VFW.PlayerData.target then
        if VFW.PlayerData.target.chestId then
            inventory, weight = TriggerServerCallback("vfw:chest:take-item", VFW.PlayerData.target.chestId, info,
                    VFW.PlayerData.target.type)
        elseif VFW.PlayerData.target.pickupId then
            inventory, weight = TriggerServerCallback("vfw:pickup:take-item", VFW.PlayerData.target.pickupId, info,
                    VFW.PlayerData.target.type)
        elseif VFW.PlayerData.target.targetId then
            inventory, weight = TriggerServerCallback("vfw:search:take-item", VFW.PlayerData.target.targetId, info)
        end
    else
        -- Taking from "Nearby" inventory
        inventory, weight = TriggerServerCallback("vfw:pickup:takeFromNearby", info)
    end

    if not inventory then
        console.error("Failed to get inventory response from server for retrieve operation")
        return
    end

    VFW.PlayerData.inventory = inventory
    if weight then
        VFW.PlayerData.weight = weight
    end

    -- Delay VFW.LoadInventories() slightly to avoid target state conflicts
    CreateThread(function()
        Wait(100) -- Small delay to ensure transaction is complete
        VFW.LoadInventories()
    end)
    RefreshInventory(data)
end)

local lastDropTime = 0
local DROP_DEBOUNCE_MS = 500

-- Callback pour déposer un item depuis le menu contextuel
-- Utilise la même logique que put-item
-- Fallback vers drop au sol si aucun conteneur à proximité
RegisterNUICallback("nui:inventory:deposit", function(data)
    if isReadOnlyTarget() then
        notifyReadOnly()
        return
    end

    -- Bloquer si c'est un inventaire infini
    if VFW.PlayerData.target and VFW.PlayerData.target.infiniteItems then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous ne pouvez pas déposer d'items dans cet inventaire"
        })
        return
    end

    -- Unequip clothing if this specific item is equipped
    unequipClothingIfEquipped(data)

    local info = DataToInfo(data)
    local hasTarget = VFW.PlayerData.target and
        (VFW.PlayerData.target.chestId or VFW.PlayerData.target.pickupId)

    if not hasTarget then
        -- Aucun conteneur à proximité → drop au sol (réutilise la logique de drop)
        if LocalPlayer.state.isCuffed then
            SendNUIMessage({
                action = "nui:inventory:error",
                data = { message = "Vous ne pouvez pas faire cette action en étant menotté" }
            })
            return
        end

        if meta and meta.prison and meta.prison.isPrisoned then
            SendNUIMessage({
                action = "nui:inventory:error",
                data = { message = "Vous ne pouvez pas faire cette action en prison" }
            })
            return
        end

        local currentTime = GetGameTimer()
        if currentTime < lastDropTime + DROP_DEBOUNCE_MS then
            return
        end
        lastDropTime = currentTime

        local itemName = data.item and data.item.label or "un objet"
        local quantity = info.quantity or 1
        ExecuteCommand("me jette " .. quantity .. "x " .. itemName .. " au sol")

        local inventory, weight = TriggerServerCallback("vfw:dropItem", info)
        VFW.PlayerData.inventory = inventory
        VFW.PlayerData.weight = weight
        VFW.LoadInventories()
        RefreshInventory(data)
        return
    end

    local inventory, weight
    if VFW.PlayerData.target.chestId then
        inventory, weight = TriggerServerCallback("vfw:chest:put-item", VFW.PlayerData.target.chestId, info,
                VFW.PlayerData.target.type)
    elseif VFW.PlayerData.target.pickupId then
        inventory, weight = TriggerServerCallback("vfw:pickup:put-item", VFW.PlayerData.target.pickupId, info,
                VFW.PlayerData.target.type)
    end

    if not inventory then
        console.error("Failed to get inventory response from server for deposit operation")
        return
    end

    VFW.PlayerData.inventory = inventory
    VFW.PlayerData.weight = weight
    VFW.LoadInventories()
    RefreshInventory(data)
end)

RegisterNUICallback("nui:inventory:move-item-in-target", function(data)
    if isReadOnlyTarget() then
        notifyReadOnly()
        return
    end

    local slotStart = data.item.slot
    local slotEnd = tonumber(data.newSlot)

    if VFW.PlayerData.target.chestId then
        TriggerServerEvent("vfw:chest:moveItem", VFW.PlayerData.target.chestId, slotStart, slotEnd)
    elseif VFW.PlayerData.target.pickupId then
        TriggerServerEvent("vfw:pickup:moveItem", VFW.PlayerData.target.pickupId, slotStart, slotEnd)
    end
end)

RegisterNUICallback("nui:inventory:lockKeyboard", function(data, cb)
    cb("ok")
    SetNuiFocusKeepInput(not data)
end)

RegisterNUICallback("nui:inventory:focusLock", function(data, cb)
    cb("ok")

    VFW.Nui.Focus(data, not data)
end)



RegisterNUICallback("nui:inventory:drop", function(data, cb)
    cb("ok")

    if LocalPlayer.state.isCuffed then
        SendNUIMessage({
            action = "nui:inventory:error",
            data = { message = "Vous ne pouvez pas faire cette action en étant menotté" }
        })
        return
    end

    if meta and meta.prison and meta.prison.isPrisoned then
        SendNUIMessage({
            action = "nui:inventory:error",
            data = { message = "Vous ne pouvez pas faire cette action en prison" }
        })
        return
    end

    -- Debounce pour éviter les doublons
    local currentTime = GetGameTimer()
    if currentTime < lastDropTime + DROP_DEBOUNCE_MS then
        return
    end
    lastDropTime = currentTime

    -- Unequip clothing if this specific item is equipped
    unequipClothingIfEquipped(data)

    local info = DataToInfo(data)
    local itemName = data.item and data.item.label or "un objet"
    local quantity = info.quantity or 1

    ExecuteCommand("me jette " .. quantity .. "x " .. itemName .. " au sol")

    local inventory, weight = TriggerServerCallback("vfw:dropItem", info)
    VFW.PlayerData.inventory = inventory
    VFW.PlayerData.weight = weight
    VFW.LoadInventories()
    RefreshInventory(data)
end)

-- Debounce for trade operations to prevent double calls
local lastTradeTime = 0
local lastTradeHash = ""
local TRADE_DEBOUNCE_MS = 500

RegisterNUICallback("nui:inventory:trade", function(data)
    local currentTime = GetGameTimer()
    local info = DataToInfo(data)
    local tradeHash = string.format("%s_%s_%s_%s", data.source or "nil", info.slot or "nil", info.type or "nil", info.quantity or "nil")

    if currentTime < lastTradeTime + TRADE_DEBOUNCE_MS and tradeHash == lastTradeHash then
        return
    end

    lastTradeTime = currentTime
    lastTradeHash = tradeHash

    local inventory, weight
    if data.source == "target" then
        -- Prendre depuis l'inventaire target
        if not VFW.PlayerData.target then
            inventory, weight = TriggerServerCallback("vfw:pickup:takeFromNearby", info)
        elseif VFW.PlayerData.target.infiniteItems then
            -- Taking from infinite items inventory
            local itemName = VFW.GetInfiniteItemNameFromSlot(info.slot)
            if not itemName then
                console.error("Failed to get item name from infinite items inventory for slot: " .. tostring(info.slot))
                return
            end
            inventory, weight = TriggerServerCallback("vfw:infiniteItems:take-item", itemName, info.quantity or 1)
        elseif VFW.PlayerData.target.chestId then
            inventory, weight = TriggerServerCallback("vfw:chest:take-item", VFW.PlayerData.target.chestId, info)
        elseif VFW.PlayerData.target.pickupId then
            inventory, weight = TriggerServerCallback("vfw:pickup:take-item", VFW.PlayerData.target.pickupId, info)
        elseif VFW.PlayerData.target.type == "item_pool" then
            inventory, weight = TriggerServerCallback("vfw:itemPool:take-item", info)
        elseif VFW.PlayerData.target.targetId then
            inventory, weight = TriggerServerCallback("vfw:search:take-item", VFW.PlayerData.target.targetId, info)
        end

    else
        -- Mettre dans l'inventaire target (bloquer si inventaire infini)
        -- Unequip clothing if this specific item is equipped (only when putting, not taking)
        unequipClothingIfEquipped(data)

        if VFW.PlayerData.target then
            if VFW.PlayerData.target.infiniteItems then
                -- Bloquer l'action de mettre des items dans l'inventaire infini
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Vous ne pouvez pas déposer d'items dans cet inventaire"
                })
                return
            elseif VFW.PlayerData.target.chestId then
                inventory, weight = TriggerServerCallback("vfw:chest:put-item", VFW.PlayerData.target.chestId, info)
            elseif VFW.PlayerData.target.pickupId then
                inventory, weight = TriggerServerCallback("vfw:pickup:put-item", VFW.PlayerData.target.pickupId, info)
            elseif VFW.PlayerData.target.targetId then
                inventory, weight = TriggerServerCallback("vfw:search:put-item", VFW.PlayerData.target.targetId, info)
            end
        else
            -- Dropping item to "Nearby" (ground)
            inventory, weight = TriggerServerCallback("vfw:dropItem", info)
        end
    end

    if not inventory then
        console.error("Failed to get inventory response from server for trade operation")
        return
    end

    VFW.PlayerData.inventory = inventory
    if weight then
        VFW.PlayerData.weight = weight
    end

    -- Delay VFW.LoadInventories() slightly to avoid target state conflicts
    CreateThread(function()
        Wait(100) -- Small delay to ensure transaction is complete
        VFW.LoadInventories()
    end)
    RefreshInventory(data)
end)

RegisterNUICallback("nui:inventory:give", function(data, cb)
    cb("ok")

    if LocalPlayer.state.isCuffed then
        SendNUIMessage({
            action = "nui:inventory:error",
            data = { message = "Vous ne pouvez pas faire cette action en étant menotté" }
        })
        return
    end

    if meta and meta.prison and meta.prison.isPrisoned then
        SendNUIMessage({
            action = "nui:inventory:error",
            data = { message = "Vous ne pouvez pas faire cette action en prison" }
        })
        return
    end

    VFW.CloseInventory()

    CreateThread(function()
        local waitSelect = true
        CreateThread(function()
            while waitSelect do
                if VFW.StateInventory() then
                    VFW.ForceStopSelect()
                    waitSelect = false
                end

                Wait(5)
            end
        end)
        local playerId = VFW.StartSelect(5.0, true)
        waitSelect = false
        if not playerId then
            return
        end

        if not confirmGiveBoundFromData(data) then
            return
        end

        -- Unequip clothing if this specific item is equipped
        unequipClothingIfEquipped(data)

        local info = DataToInfo(data)
        local id = GetPlayerServerId(playerId)

        -- Animation is handled server-side by giveItem (triggers on both players only on success)
        local inventory, weight = TriggerServerCallback("vfw:giveItem", id, info)
        VFW.PlayerData.inventory = inventory
        VFW.PlayerData.weight = weight
        VFW.LoadInventories()
        RefreshInventory(data)
    end)
end)

RegisterNetEvent("inventory:transferTooHeavy", function()
    SendNUIMessage({
        action = "nui:inventory:error",
        data = { message = "Cette personne ne peut pas porter autant." }
    })
end)

RegisterNetEvent("inventory:chestFull", function()
    SendNUIMessage({
        action = "nui:inventory:error",
        data = { message = "Le coffre n'a plus assez de place" }
    })
end)

RegisterNUICallback("nui:inventory:giveMoney", function(_, cb)
    cb("ok")
    VFW.CloseInventory()

    CreateThread(function()
        local waitSelect = true
        CreateThread(function()
            while waitSelect do
                if VFW.StateInventory() then
                    VFW.ForceStopSelect()
                    waitSelect = false
                end

                Wait(5)
            end
        end)
        local playerId = VFW.StartSelect(5.0, true)
        waitSelect = false
        if not playerId then
            return
        end

        local count = VFW.Nui.KeyboardInput(true, "Montant à donner")
        local numericCount = tonumber(count)
        if (not count) or (not numericCount) then
            return
        end

        local id = GetPlayerServerId(playerId)
        local inventory, weight = TriggerServerCallback("vfw:giveMoney", id, numericCount)
        VFW.PlayerData.inventory = inventory
        VFW.PlayerData.weight = weight
        VFW.LoadInventories()
    end)
end)

-- Handle setTyping callback for input focus management
RegisterNUICallback("setTyping", function(data, cb)
    local isTyping = data.value or false

    if isTyping then
        -- Disable movement controls when typing in search bar
        CreateThread(function()
            while VFW.PlayerData and VFW.PlayerData.isTyping do
                -- Disable movement controls
                DisableControlAction(0, 30, true) -- A/D
                DisableControlAction(0, 31, true) -- S/W
                DisableControlAction(0, 32, true) -- W
                DisableControlAction(0, 33, true) -- S
                DisableControlAction(0, 34, true) -- A
                DisableControlAction(0, 35, true) -- D
                DisableControlAction(0, 36, true) -- LEFT CTRL

                -- Disable other movement controls
                DisableControlAction(0, 21, true) -- SHIFT (sprint)
                DisableControlAction(0, 22, true) -- SPACE (jump)
                DisableControlAction(0, 44, true) -- Q (cover)
                DisableControlAction(0, 38, true) -- E (context)

                Wait(0)
            end
        end)
    end

    -- Store typing state
    VFW.PlayerData = VFW.PlayerData or {}
    VFW.PlayerData.isTyping = isTyping

    cb({ success = true })
end)

-- Handle clothes equipping
RegisterNUICallback("nui:inventory:equipClothes", function(data, cb)

    local itemName = data.item.name
    local itemMeta = data.item.metadatas or data.item.meta or {}

    local model = itemMeta.model or itemMeta.id
    local variation = itemMeta.variation or itemMeta.var or 0
    local sex = itemMeta.sex or "m"
    local typeToUse = itemMeta.type or itemName

    -- Forcer le type "bag" si c'est un sac (détection par bag_uuid ou slotType)
    if data.slotType == "bag" or itemMeta.bag_uuid then
        typeToUse = "bag"

        -- Si c'est un sac avec bag_uuid mais sans drawable ID, chercher dans la DB
        if (not model or model == 0) and itemMeta.bag_uuid then
            -- Chercher le drawable ID dans bag_categories basé sur la catégorie ou utiliser un défaut
            local bagDrawable = TriggerServerCallback("vfw:bag:getDrawableId", itemMeta.bag_uuid)
            if bagDrawable and bagDrawable > 0 then
                model = bagDrawable
            else
                -- Fallback: utiliser un sac par défaut (45 = sac à dos commun)
                model = 45
            end
        end
    end


    -- Les hauts composites n'ont pas de model/id, mais ont meta.skin
    if not model and not itemMeta.skin then
        --print("❌ Error: Item sin modelo")
        cb({ success = false })
        return
    end

    -- Aplicar visualmente
    TriggerEvent("vfw:clothes", itemName, {
        type = typeToUse,
        id = model,
        var = variation,
        sex = sex,
        action = "on",
        skin = itemMeta.skin,
        bag_uuid = itemMeta.bag_uuid,
        bag_capacity = itemMeta.bag_capacity,
        plates = itemMeta.plates
    })

    local dragSlot = data.item and data.item.slot
    if dragSlot then
        local inventory, weight = TriggerServerCallback("vfw:clothes:markEquipped", itemName, typeToUse, dragSlot)
        if inventory then
            VFW.PlayerData.inventory = inventory
            VFW.PlayerData.weight = weight
        end
    end

    Wait(100)
    VFW.LoadInventories()

    --print("✅ Item individual equipado")
    --print("==========================================")
    cb({ success = true })
end)

-- Handle clothes unequipping
RegisterNUICallback("nui:inventory:unequipClothes", function(data, cb)
    local slotType = data.slotType

    TriggerEvent("skinchanger:getSkin", function(skin)
        local slotToSkinKey = {
            ["pants"] = { "pants_1", "pants_2" },
            ["shoes"] = { "shoes_1", "shoes_2" },
            ["shirt"] = { "torso_1", "torso_2" },
            ["hat"] = { "helmet_1", "helmet_2" },
            ["glasses"] = { "glasses_1", "glasses_2" },
            ["bag"] = { "bags_1", "bags_2" },
            ["necklace"] = { "chain_1", "chain_2" },
            ["watch"] = { "watches_1", "watches_2" },
            ["mask"] = { "mask_1", "mask_2" },
            ["bracelet"] = { "bracelets_1", "bracelets_2" },
            ["earrings"] = { "ears_1", "ears_2" },
            ["body_armor"] = { "bproof_1", "bproof_2" },
            ["arms"] = { "arms", "arms_2" },
        }

        local slotToItemName = {
            ["pants"] = "bottom",
            ["shoes"] = "shoe",
            ["shirt"] = "top",
            ["hat"] = "hat",
            ["glasses"] = "glasses",
            ["bag"] = "bag",
            ["necklace"] = "necklace",
            ["watch"] = "watch",
            ["mask"] = "mask",
            ["bracelet"] = "bracelet",
            ["earrings"] = "earring",
            ["body_armor"] = "gpb",
            ["arms"] = "arms",
        }

        local itemName = slotToItemName[slotType]

        if not itemName then
            --print("❌ SlotType no reconocido:", slotType)
            cb({ success = false })
            return
        end

        local sex = skin.sex == 0 and "m" or "f"

        -- 🚨 LA CORRECCIÓN:
        -- Para desequipar (off), el ID debe ser 0.
        -- No necesitamos leer el ID actual de la skin porque queremos quitarlo.

        --print("🔴 Desequipando visualmente:", itemName, "ID: 0")

        TriggerEvent("vfw:clothes", itemName, {
            type = itemName,
            id = 0,
            var = 0,
            sex = sex,
            action = "off"
        })

        local inventory, weight = TriggerServerCallback("vfw:clothes:markEquipped", itemName, itemName, nil)
        if inventory then
            VFW.PlayerData.inventory = inventory
            VFW.PlayerData.weight = weight
        end

        -- Attendre que le skin soit sauvegardé côté serveur avant de recharger
        Wait(500)
        VFW.LoadInventories()

        cb({ success = true })
    end)
end)

-- Equip outfit callback
-- Callback para EQUIPAR con Print de Meta
RegisterNUICallback("nui:inventory:equipOutfit", function(data, cb)
    if not data.item or not data.item.name then
        cb({ success = false, error = "Missing outfit item data" })
        return
    end

    local meta = data.item.metadatas or {}
    meta.action = "on"

    TriggerEvent("vfw:clothes", "outfit", meta)

    cb({ success = true })
end)

-- Callback para DESEQUIPAR con Print de Meta
RegisterNUICallback("nui:inventory:unequipOutfit", function(data, cb)
    --print("========== [unequipOutfit COMPLETO] ==========")

    if not data.outfitName and not data.item then
        --print("❌ Falta outfitName o item")
        cb({ success = false, error = "Missing outfit data" })
        return
    end

    -- Buscar outfit en inventario
    local equippedOutfit = nil
    for _, item in ipairs(VFW.PlayerData.inventory) do
        if VFW.Items[item.name] and VFW.Items[item.name].type == "outfit" then
            -- Intentamos comparar por el contenido de la skin si viene en data.item
            if data.item and data.item.metadatas and data.item.metadatas.skin then
                local same = true
                local itemMeta = item.metadatas or item.meta or {}
                for k, v in pairs(data.item.metadatas.skin) do
                    if itemMeta.skin and itemMeta.skin[k] ~= v then
                        same = false
                        break
                    end
                end
                if same then
                    equippedOutfit = item
                    break
                end
            elseif data.outfitName and item.name == data.outfitName then
                equippedOutfit = item
                break
            end
        end
    end

    if not equippedOutfit then
        --print("❌ No se encontró outfit equipado en el inventario")
        cb({ success = false, error = "No equipped outfit found" })
        return
    end

    -- Construir meta con action=off
    local meta = equippedOutfit.metadatas or equippedOutfit.meta or {}
    meta.action = "off"
    meta.clothesSlotType = "outfit"
    meta.sex = meta.sex or "m"
    meta.skin = meta.skin or {}

    -- Print detallado del meta que se va a procesar para el desequipado
    --print("Desequipando outfit completo")
    --print("Meta Data (Unequip):", json.encode(meta, {indent = true}))

    TriggerEvent("vfw:clothes", "outfit", meta)

    Wait(200)
    VFW.LoadInventories()

    --print("✅ Outfit completo desequipado")
    --print("==========================================")
    cb({ success = true })
end)




-- View chest history callback
RegisterNUICallback("nui:inventory:viewChestHistory", function(data, cb)
    if not data.chestId then
        console.error("Missing chestId for viewChestHistory")
        cb({ success = false, error = "Missing chestId" })
        return
    end

    -- Execute the viewchesthistory command with the chestId
    ExecuteCommand(string.format("viewchesthistory %s", data.chestId))
    cb({ success = true })
end)

RegisterNUICallback("nui:inventory:addOutfitToBag", function(data, cb)
    local itemMetadata = data.item.metadatas

    local success, message = TriggerServerCallback("core:server:addOutfitToBag", itemMetadata)

    if success then
        VFW.LoadInventories()
    end

    cb({ success = success, message = message })
end)

local function mapSlotToItemName(slotType)
    if slotType == "pants" then
        return "bottom"
    end
    if slotType == "shoes" then
        return "shoe"
    end
    if slotType == "hat" then
        return "hat"
    end
    if slotType == "glasses" then
        return "glasses"
    end
    if slotType == "bag" then
        return "bag"
    end
    if slotType == "necklace" then
        return "necklace"
    end
    if slotType == "watch" then
        return "watch"
    end
    if slotType == "mask" then
        return "mask"
    end
    if slotType == "bracelet" then
        return "bracelet"
    end
    if slotType == "earrings" then
        return "earring"
    end
    if slotType == "body_armor" then
        return "gpb"
    end
    if slotType == "shirt" then
        return "top"
    end
    return "top"
end

-- 🆕 Toggle visuel pur d'un slot d'outfit (oeil dans l'UI)
-- Ne modifie que la skin du ped, sans toucher à l'inventaire ni à GetClothes
-- Slots simples : { comp1, comp2, emptyVal }
-- Slot composite (SHIRT) traité séparément : tshirt + torso + arms
local outfitSlotMap = {
    ["hat"]      = {"helmet_1","helmet_2", -1},
    ["mask"]     = {"mask_1","mask_2", 0},
    ["pants"]    = {"pants_1","pants_2", nil},
    ["bottom"]   = {"pants_1","pants_2", nil},
    ["shoes"]    = {"shoes_1","shoes_2", nil},
    ["shoe"]     = {"shoes_1","shoes_2", nil},
    ["glasses"]  = {"glasses_1","glasses_2", -1},
    ["bag"]      = {"bags_1","bags_2", -1},
    ["necklace"] = {"chain_1","chain_2", -1},
    ["watch"]    = {"watches_1","watches_2", -1},
    ["bracelet"] = {"bracelets_1","bracelets_2", -1},
    ["earring"]  = {"ears_1","ears_2", -1},
    ["gpb"]      = {"bproof_1","bproof_2", 0},
}

-- Pieds nus pour les slots qui dépendent du sexe
local nakedFallback = {
    ["m"] = { pants_1 = 61, shoes_1 = 34, torso_1 = 15, tshirt_1 = 15, arms = 15 },
    ["w"] = { pants_1 = 15, shoes_1 = 35, torso_1 = 15, tshirt_1 = 15, arms = 15 },
}

local function applyChange(skin, key, value)
    skin[key] = value
    TriggerEvent("skinchanger:change", key, value)
end

RegisterNUICallback("nui:inventory:toggleOutfitSlot", function(data, cb)
    local itemName = mapSlotToItemName(data.slotType)
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
    if not skin then
        cb({ success = false })
        return
    end

    local sex = (data.meta and data.meta.sex) or "m"
    if sex == "f" or sex == "female" then sex = "w" end
    local naked = nakedFallback[sex] or nakedFallback["m"]
    local outfitSkin = data.meta and data.meta.outfitSkin or {}

    -- Slot composite : SHIRT (tshirt + torso uniquement, pas arms pour préserver les bracelets/montres)
    if itemName == "top" or itemName == "shirt" then
        if data.action == "off" then
            applyChange(skin, "tshirt_1", naked.tshirt_1)
            applyChange(skin, "tshirt_2", 0)
            applyChange(skin, "torso_1", naked.torso_1)
            applyChange(skin, "torso_2", 0)
        else
            for _, k in ipairs({"tshirt_1","tshirt_2","torso_1","torso_2"}) do
                if outfitSkin[k] ~= nil then
                    applyChange(skin, k, outfitSkin[k])
                end
            end
        end
    else
        local map = outfitSlotMap[itemName]
        if not map then
            cb({ success = false })
            return
        end
        local comp1, comp2, emptyVal = map[1], map[2], map[3]
        if emptyVal == nil then
            -- valeur "nu" dépend du sexe (pants / shoes)
            emptyVal = naked[comp1] or 0
        end

        if data.action == "off" then
            applyChange(skin, comp1, emptyVal)
            applyChange(skin, comp2, 0)
        else
            -- Restaurer depuis l'outfit complet (plus fiable que data.meta.id/var
            -- qui peut être 0 ou nil pour certains accessoires)
            local id = outfitSkin[comp1]
            local var = outfitSkin[comp2]
            if id == nil then
                id = data.meta and tonumber(data.meta.id) or emptyVal
            end
            if var == nil then
                var = data.meta and tonumber(data.meta.var) or 0
            end
            applyChange(skin, comp1, tonumber(id) or emptyVal)
            applyChange(skin, comp2, tonumber(var) or 0)
        end
    end

    TriggerServerEvent("vfw:skin:save", skin)

    if VFW.HasClonedPed and VFW.HasClonedPed() then
        SetTimeout(150, function()
            if VFW.SyncPedAppearance then VFW.SyncPedAppearance() end
        end)
    end

    cb({ success = true })
end)

RegisterNUICallback("nui:inventory:toggleClothes", function(data, cb)
    --print("========== [NUI toggleClothes] ==========")
    --print("slotType:", data.slotType, "action:", data.action)

    --if data.meta then
    --    print("meta.type:", data.meta.type,
    --            "meta.id:", data.meta.id,
    --            "meta.var:", data.meta.var,
    --            "meta.sex:", data.meta.sex)
    --else
    --    print("meta vacío")
    --end

    local itemName = mapSlotToItemName(data.slotType)
    local rawId = data.meta and data.meta.id
    local rawVar = data.meta and data.meta.var

    local meta = {
        type = itemName,
        id = rawId ~= nil and tonumber(rawId) or -1,
        var = rawVar ~= nil and tonumber(rawVar) or 0,
        sex = (data.meta and data.meta.sex) or "m",
        action = data.action,
        fromOutfit = data.meta and data.meta.fromOutfit or false,
    }

    --print("[NUI toggleClothes] itemName:", itemName, "meta final:", json.encode(meta))
    --print("========================================")

    TriggerEvent("vfw:clothes", itemName, meta)
    VFW.LoadInventories()
    cb({ success = true })
end)


-- Callback para poner el arma en la espalda
RegisterNUICallback("nui:inventory:putOnBack", function(data, cb)
    cb("ok")

    if not data or not data.item then
        return
    end

    local info = DataToInfo(data)
    local itemName = data.item.name or "unknown"
    local itemMeta = data.item.metadatas or data.item.meta or {}

    if info.type == "weapons" then
        local ped = PlayerPedId()

        -- 1. COMPROBACIÓN: ¿YA ESTÁ EN LA ESPALDA?
        -- weaponOnBackName es la variable global que definimos en main.lua
        if weaponOnBackName == itemName then
            -- Si el usuario vuelve a dar click al arma que ya tiene atrás, la quitamos
            RemoveWeaponProp()
            VFW.ShowNotification({ type = 'JAUNE', content = "Arme retirée du dos." })
            return -- Cortamos la ejecución aquí (Toggle OFF)
        end

        -- 2. COMPROBACIÓN: ¿ESTÁ EN LA MANO?
        if GetSelectedPedWeapon(ped) == GetHashKey(itemName) then
            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
            Wait(500)
        end

        TriggerEvent("vfw:weapon:back", itemName, itemMeta)

        VFW.LoadInventories()
    else
        VFW.ShowNotification({ type = 'ROUGE', content = "Ceci n'est pas une arme." })
    end
end)

-- Callback pour retirer le sac (déséquiper vers l'inventaire)
RegisterNUICallback("nui:inventory:dropBag", function(data, cb)
    cb("ok")

    local bagItem = data.item
    if not bagItem then return end

    local bagMeta = bagItem.metadatas or bagItem.meta or {}

    -- Retirer visuellement le sac
    TriggerEvent("vfw:clothes", "bag", {
        type = "bag",
        id = 0,
        var = 0,
        sex = bagMeta.sex or "m",
        action = "off"
    })

    Wait(100)
    VFW.LoadInventories()
end)

-- Callback pour retirer l'arme du dos
RegisterNUICallback("nui:inventory:removeFromBack", function(data, cb)
    cb("ok")

    if not data or not data.item then
        return
    end

    local itemName = data.item.name or data.name or "unknown"

    -- Vérifier que c'est bien l'arme qui est dans le dos
    if weaponOnBackName == itemName then
        RemoveWeaponProp()
        VFW.ShowNotification({ type = 'JAUNE', content = "Arme retirée du dos." })
        VFW.LoadInventories()
    else
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette arme n'est pas dans votre dos." })
    end
end)

--- Server-triggered inventory toast (for drop errors, etc.)
RegisterNetEvent("vfw:inventory:toast", function(message)
    SendNUIMessage({
        action = "nui:inventory:error",
        data = { message = message }
    })
end)
