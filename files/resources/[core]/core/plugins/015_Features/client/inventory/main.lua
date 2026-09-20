--- Flag to prevent double bag weight bonus restoration on reconnection
local bagBonusRestored = false
local tooHeavyThread = false

--- Initialize GetClothes state based on player's current skin and inventory
local function initializeEquippedClothes()
    CreateThread(function()
        -- Wait for player data to be fully loaded
        while not VFW.PlayerData or not VFW.PlayerData.inventory or not VFW.Items do
            Wait(100)
        end

        -- Wait a bit more to ensure skin is applied
        Wait(500)

        -- Define translateSkin mapping (same as in clothes.lua)
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
            ["piercing"] = { "bproof_1", "bproof_2" },
            ["gpb"] = { "bproof_1", "bproof_2" },
            ["top"] = { "torso_1", "torso_2", "tshirt_1", "tshirt_2", "arms", "arms_2" },
            ["arms"] = { "arms", "arms_2" }
        }

        -- Get current player skin
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
        if not skin then
            return
        end

        -- Pré-check: Y a-t-il un sac visible sur le joueur?
        local bagVisibleOnModel = tonumber(skin["bags_1"]) and tonumber(skin["bags_1"]) > 0

        -- Check each item in inventory to see if it's equipped
        for _, item in ipairs(VFW.PlayerData.inventory) do
            if VFW.Items[item.name] and (VFW.Items[item.name].type == "clothes" or VFW.Items[item.name].type == "outfit") then
                local itemName = item.name

                if VFW.Items[item.name].type == "outfit" then
                    -- For outfits, check if the current skin matches the outfit skin.
                    -- IMPORTANT: ignorer les composants "vides" (-1 props, 0/-1 pour mask/bags/chain/bproof)
                    -- car l'équipement (clothes.lua) ne les applique pas non plus afin de préserver
                    -- les vêtements individuels portés en dessous. Sans ce filtre, un chapeau/sac
                    -- individuel porté en plus de la tenue fait échouer la comparaison et la tenue
                    -- apparaît "non équipée" dans l'inventaire alors qu'elle est sur le ped.
                    if item.meta and item.meta.skin then
                        local isEquipped = true
                        local matched = 0
                        for component, value in pairs(item.meta.skin) do
                            local isEmpty = false
                            if component:match("helmet_") or component:match("glasses_") or
                                    component:match("watches_") or component:match("bracelets_") or
                                    component:match("ears_") then
                                isEmpty = (value == -1)
                            elseif component:match("mask_") or component:match("bags_") or
                                    component:match("chain_") or component:match("bproof_") then
                                isEmpty = (value == 0 or value == -1)
                            end

                            if not isEmpty then
                                if skin[component] ~= value then
                                    isEquipped = false
                                    break
                                end
                                matched = matched + 1
                            end
                        end
                        if isEquipped and matched > 0 then
                            GetClothes["outfit"] = true
                            if VFW.SetCurrentOutfitSkin then
                                VFW.SetCurrentOutfitSkin(item.meta.skin)
                            end
                        end
                    end
                elseif VFW.Items[item.name].type == "clothes" then
                    -- For clothes, check if the skin components match
                    if item.meta then
                        local typeItem = item.meta.type or itemName
                        local clothesKey = typeItem

                        if itemName == "top" then
                            -- Special handling for top items
                            if item.meta.skin then
                                local isEquipped = true
                                for k, v in pairs(item.meta.skin) do
                                    if skin[k] ~= v then
                                        isEquipped = false
                                        break
                                    end
                                end
                                if isEquipped then
                                    GetClothes["top"] = true
                                end
                            end
                        elseif typeItem == "bag" then
                            -- DÉTECTION SPÉCIALE POUR LES SACS
                            -- Méthode 1: Si un sac est visible ET cet item est un sac avec bag_uuid
                            if bagVisibleOnModel and item.meta.bag_uuid then
                                GetClothes["bag"] = true
                                VFW.SetEquippedBag(item.meta.bag_uuid, item.meta)
                                -- Restore bag weight bonus on reconnection (only once)
                                if item.meta.bag_capacity and not bagBonusRestored then
                                    bagBonusRestored = true
                                    TriggerServerEvent("vfw:bag:addWeightBonus", item.meta.bag_capacity, item.meta.id or 0, item.meta.sex or "m")
                                end
                                -- Méthode 2: Comparaison exacte id/var
                            elseif bagVisibleOnModel then
                                local metaId = tonumber(item.meta.id) or 0
                                local skinBagId = tonumber(skin["bags_1"]) or 0
                                if metaId > 0 and metaId == skinBagId then
                                    GetClothes["bag"] = true
                                    VFW.SetEquippedBag(item.meta.bag_uuid, item.meta)
                                    -- Restore bag weight bonus on reconnection (only once)
                                    if item.meta.bag_capacity and not bagBonusRestored then
                                        bagBonusRestored = true
                                        TriggerServerEvent("vfw:bag:addWeightBonus", item.meta.bag_capacity, item.meta.id or 0, item.meta.sex or "m")
                                    end
                                end
                            end
                        elseif itemName == "accessory" and item.meta.bag_uuid then
                            -- C'est un sac stocké comme "accessory"
                            if bagVisibleOnModel then
                                GetClothes["bag"] = true
                                VFW.SetEquippedBag(item.meta.bag_uuid, item.meta)
                                -- Restore bag weight bonus on reconnection (only once)
                                if item.meta.bag_capacity and not bagBonusRestored then
                                    bagBonusRestored = true
                                    TriggerServerEvent("vfw:bag:addWeightBonus", item.meta.bag_capacity, item.meta.id or 0, item.meta.sex or "m")
                                end
                            end
                        elseif typeItem == "gpb" or typeItem == "kevlar" then
                            -- GPB: l'id est un UUID, on compare juste si bproof est visible
                            local bproofDrawable = tonumber(skin["bproof_1"]) or 0
                            if bproofDrawable > 0 then
                                GetClothes["gpb"] = true
                                item.meta.equipped_bproof = true
                                TriggerServerEvent("vfw:gpb:markEquipped", true)
                            end
                        elseif translateSkin[typeItem] then
                            -- Regular clothes with id/var
                            local component1 = translateSkin[typeItem][1]
                            local component2 = translateSkin[typeItem][2]

                            -- Conversion en nombres pour comparaison robuste
                            local skinVal1 = tonumber(skin[component1]) or 0
                            local skinVal2 = tonumber(skin[component2]) or 0
                            local metaId = tonumber(item.meta.id) or 0
                            local metaVar = tonumber(item.meta.var) or 0

                            -- Vérifier si équipé (valeurs correspondantes ET non-zéro pour le composant principal)
                            if skinVal1 > 0 and skinVal1 == metaId and skinVal2 == metaVar then
                                GetClothes[clothesKey] = true
                            end
                        end
                    end
                end
            end
        end
    end)
end

RegisterNetEvent("vfw:playerReady", function()
    local shortcuts = GetResourceKvpString("vfw:Shorcut")
    VFW.PlayerData.shortcuts = json.decode(shortcuts or "[]") or {}

    -- Clean corrupted shortcuts data on startup
    local cleanedShortcuts = {}
    for i = 1, 5 do
        if VFW.PlayerData.shortcuts[i] and type(VFW.PlayerData.shortcuts[i]) == "table" then
            cleanedShortcuts[i] = VFW.PlayerData.shortcuts[i]
        end
    end
    VFW.PlayerData.shortcuts = cleanedShortcuts
    SetResourceKvp("vfw:Shorcut", json.encode(VFW.PlayerData.shortcuts))

    local active = GetResourceKvpInt("vfw:ShorcutActive")
    VFW.PlayerData.shortcutsActive = ((active and active or 1) == 1)

    if not VFW.PlayerGlobalData.permissions["dev"] then
        if VFW.PlayerData.weight > VFW.PlayerData.maxWeight then
            VFW.tooHeavy()
        elseif tooHeavyThread then
            tooHeavyThread = false
        end
    end

    -- Initialize equipped clothes state
    initializeEquippedClothes()
end)

RegisterNetEvent("vfw:inventoryGive", function(target)
    VFW.OpenInventory(target)
end)

local open = false
VFW._inventoryIgnoreNuiCloseUntil = 0

function VFW.IsInventoryOpen()
    return open
end

function VFW.OpenInventory(target)
    if not VFW.Items then
        if VFW.ShowNotification then
            VFW.ShowNotification({ type = "ROUGE", content = "Inventaire indisponible (items non chargés)" })
        end
        return
    end

    if not open and VFW.Nui and VFW.Nui.IsProgressActive and VFW.Nui.IsProgressActive() then
        if VFW.ShowNotification then
            VFW.ShowNotification({ type = "ROUGE", content = "Action en cours, terminez d'abord" })
        end
        return
    end

    open = not open

    if not open then
        VFW._inventoryIgnoreNuiCloseUntil = 0
        --Close the inventory and delete the cloned ped
        VFW.SetInventoryPedState(false)

        --VFW.Screen.Delete()

        SendNUIMessage({
            action = "nui:inventory:visible",
            data = false
        })

        VFW.Nui.Focus(false, false)

        CreateThread(function()
            local endTime = GetGameTimer() + 500
            while GetGameTimer() < endTime do
                DisableControlAction(0, 199, true)
                DisableControlAction(0, 200, true)
                Wait(0)
            end
        end)

        if VFW.IsRadioOpen and VFW.IsRadioOpen() then
            VFW.Nui.Focus(true, true)
        elseif VFW.IsGasStationOpen and VFW.IsGasStationOpen() then
            VFW.Nui.Focus(true, true)
        end

        VFW.DisableEscapeMenu(false)
        VFW.Nui.HudVisible(true, true)

        -- Close effects
        ClearTimecycleModifier()
        SetTimecycleModifierStrength(0.0)

        if VFW.PlayerData.target then
            if VFW.PlayerData.target.bagUUID then
                TriggerServerEvent("vfw:bag:close", VFW.PlayerData.target.bagUUID)
            elseif VFW.PlayerData.target.chestId then
                TriggerServerEvent("vfw:chest:close", VFW.PlayerData.target.chestId)
            elseif VFW.PlayerData.target.pickupId then
                TriggerServerEvent("vfw:pickup:close", VFW.PlayerData.target.pickupId)
            elseif VFW.PlayerData.target.targetId then
                TriggerServerEvent("vfw:search:close", VFW.PlayerData.target.targetId)

                ExecuteCommand("+clearAnim")
                local ped = PlayerPedId()
                ClearPedTasks(ped)
                FreezeEntityPosition(ped, false)
            end

            VFW.PlayerData.target = nil
        end

        return
    end

    VFW.Nui.HudVisible(false, true)
    VFW.DisableEscapeMenu(true)
    -- Ignore le Tab/Escape NUI de la même frappe qui vient d'ouvrir l'inventaire
    VFW._inventoryIgnoreNuiCloseUntil = GetGameTimer() + 400
    TriggerEvent("core:inventory:opened")

    -- Open effects
    SetTimecycleModifier("hud_def_blur")
    SetTimecycleModifierStrength(0.1)

    -- Create the cloned ped
    VFW.SetInventoryPedState(true)
    --
    --VFW.Screen.Create()

    SendNUIMessage({
        action = "nui:inventory:visible",
        data = true
    })
    VFW.Nui.Focus(true, true)
    SetCursorLocation(0.5, 0.5)

    -- keepInput=true laisse passer les inputs au jeu (nécessaire pour la voix /
    -- la radio), donc on bloque manuellement les controls de combat pour que
    -- les clics dans l'UI ne fassent pas taper le ped.
    CreateThread(function()
        while open do
            DisableControlAction(0, 24, true)  -- Attack (clic gauche)
            DisableControlAction(0, 25, true)  -- Aim (clic droit)
            DisableControlAction(0, 257, true) -- Attack2
            DisableControlAction(0, 263, true) -- MeleeAttack1
            DisableControlAction(0, 264, true) -- MeleeAttack2
            DisableControlAction(0, 140, true) -- MeleeAttackLight
            DisableControlAction(0, 141, true) -- MeleeAttackHeavy
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 143, true) -- MeleeBlock
            DisableControlAction(0, 99, true)  -- VehicleAttack
            DisableControlAction(0, 100, true) -- VehicleAttack2
            DisableControlAction(0, 114, true) -- VehicleFlyAttackCamera
            DisableControlAction(0, 331, true) -- VehiclePassengerAttack
            Wait(0)
        end
    end)

    local change = false

    local ped = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(ped)
    if currentWeapon and currentWeapon ~= `weapon_unarmed` then
        local clip = VFW.GetReliableClipAmmo(ped, currentWeapon)
        TriggerServerEvent("vfw:weapon:saveAmmoState", currentWeapon, clip)
        local weaponInfo = VFW.GetWeaponFromHash(currentWeapon)
        if weaponInfo and VFW.PlayerData.inventory then
            local weaponName = string.lower(weaponInfo.name)
            for i = 1, #VFW.PlayerData.inventory do
                local item = VFW.PlayerData.inventory[i]
                if item and item.name == weaponName and item.meta then
                    item.meta.ammo = clip
                    break
                end
            end
        end
    end

    VFW.PlayerData.target = target
    VFW.LoadInventories(target and target.maxSlots or nil, target and target.infiniteItems or false)

    CreateThread(function()
        while open do
            -- Camera/Look controls
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown

            -- Attack/Aim controls (mouse clicks)
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 36, true) -- Duck
            DisableControlAction(0, 37, true) -- SelectWeapon
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 47, true) -- DetectiveMode (alt weapon)

            -- Vehicle attack controls
            DisableControlAction(0, 68, true)  -- VehicleAim
            DisableControlAction(0, 69, true)  -- VehicleAttack
            DisableControlAction(0, 70, true)  -- VehicleAttack2
            DisableControlAction(0, 91, true)  -- VehiclePassengerAttack
            DisableControlAction(0, 92, true)  -- VehiclePassengerAim
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride

            -- Melee controls
            DisableControlAction(0, 140, true) -- MeleeAttackLight
            DisableControlAction(0, 141, true) -- MeleeAttackHeavy
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 143, true) -- MeleeBlock

            DisablePlayerFiring(VFW.playerId, true)

            -- Fermer avec ESC uniquement
            if IsDisabledControlJustPressed(0, 200) and not IsDisabledControlPressed(0, 25) then
                VFW.OpenInventory()
            end

            Wait(0)
        end
    end)

end

function VFW.CloseInventory()
    if open then
        VFW.OpenInventory()
    end
end

function VFW.StateInventory()
    return open
end

RegisterNetEvent("vfw:loadInventory", function(inventory, weight)
    VFW.PlayerData.inventory = inventory
    VFW.PlayerData.weight = weight

    -- Re-initialiser les vêtements équipés après le chargement de l'inventaire
    initializeEquippedClothes()
end)

RegisterKeyMapping('+inventory', 'Inventaire', 'keyboard', 'TAB')
RegisterCommand('+inventory', function()
    if IsPauseMenuActive() then
        return
    end

    if LocalPlayer.state.staffScreenshotOpen then
        return
    end

    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "L'inventaire est désactivé pendant les TIG"
        })
        return
    end

    local prisonMeta = VFW.PlayerData.metadata and VFW.PlayerData.metadata.prison
    if prisonMeta and prisonMeta.isPrisoned then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "L'inventaire est désactivé en prison"
        })
        return
    end

    if (Death and Death.isDead) or (VFW.PlayerData and VFW.PlayerData.dead) then
        return
    end

    if VFW.StateInventory() then
        VFW.CloseInventory()
        return
    end

    local currentVehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
    if currentVehicle ~= 0 then
        VFW.OpenGloveBox(Entity(currentVehicle).state.OwnedVehicle, GetVehicleNumberPlateText(currentVehicle), VehToNet(currentVehicle))

        CreateThread(function()
            while VFW.StateInventory() do
                if not IsPedInVehicle(VFW.PlayerData.ped, currentVehicle, false) then
                    VFW.CloseInventory()
                    break
                end
                Wait(100)
            end
        end)

        return
    end
    VFW.OpenInventory()
end)

RegisterCommand('inv', function()
    if VFW.StateInventory() then
        VFW.CloseInventory()
    else
        VFW.OpenInventory()
    end
end, false)

local function haveItem(itemCompare)
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.SameItem(VFW.PlayerData.inventory[i], itemCompare) then
            return i
        end
    end

    return false
end

local sex = {
    ["m"] = "male",
    ["w"] = "female"
}
local imgType = {
    ["top"] = "torso2",
    ["bottom"] = "leg",
    ["shoe"] = "shoes",
    ["hat"] = "hat",
    ["glasses"] = "glasses",
    ["bag"] = "bag",
    ["ring"] = "ring",
    ["bracelet"] = "bracelet",
    ["earring"] = "ear",
    ["watch"] = "watch",
    ["necklace"] = "accessory",
    ["mask"] = "mask",
    ["outfit"] = "torso2",
    ["kevlar"] = "kevlar"
}

local function buildImageUrl(sex, category, itemType, id, variant)
    local filename = variant and variant > 0 and (id .. "_" .. variant) or tostring(id)
    return VFW.CDN.Get(string.format("outfits_greenscreener/%s/%s/%s/%s.webp", sex, category, itemType, filename))
end

local function isAccessoryProp(accessoryType)
    local propTypes = { bracelet = true, earring = true, glasses = true, hat = true, watch = true }
    return propTypes[accessoryType] == true
end

-- Mapping from clothes item names to frontend ClothesSlotType (defined before processClothingItem)
local clothesSlotMapping = {
    ["hat"] = "hat",
    ["glasses"] = "glasses",
    ["accessory"] = function(meta)
        local accessoryType = meta.type
        if accessoryType == "bag" then
            return "bag"
        elseif accessoryType == "bracelet" then
            return "bracelet"
        elseif accessoryType == "earring" then
            return "earrings"
        elseif accessoryType == "watch" then
            return "watch"
        elseif accessoryType == "necklace" then
            return "necklace"
        elseif accessoryType == "mask" then
            return "mask"
        elseif accessoryType == "piercing" then
            return "body_armor"
        elseif accessoryType == "kevlar" then
            return "body_armor"
        elseif accessoryType == "glasses" then
            return "glasses"
        elseif accessoryType == "hat" then
            return "hat"
        end
        return nil
    end,
    ["top"] = "shirt",
    ["bottom"] = "pants",
    ["shoe"] = "shoes",
    ["mask"] = "mask",
    ["bag"] = "bag",
    ["bracelet"] = "bracelet",
    ["earring"] = "earrings",
    ["watch"] = "watch",
    ["necklace"] = "necklace",
    ["piercing"] = "body_armor",
    ["gpb"] = "body_armor",
    ["arms"] = "arms",
}

-- French labels for clothing types
local clothesLabels = {
    ["hat"] = "Chapeau",
    ["mask"] = "Masque",
    ["shirt"] = "Haut",
    ["body_armor"] = "Gilet",
    ["pants"] = "Pantalon",
    ["shoes"] = "Chaussures",
    ["earrings"] = "Boucles d'oreilles",
    ["glasses"] = "Lunettes",
    ["arms"] = "Bras",
    ["watch"] = "Montre",
    ["bracelet"] = "Bracelet",
    ["bag"] = "Sac",
    ["necklace"] = "Collier",
}


local function processClothingItem(item, index, inventory)
    if not item.meta then
        return
    end

    local itemSex = sex[item.meta.sex]
    local itemName = item.name

    local slotType = nil
    if itemName == "accessory" then
        local mapping = clothesSlotMapping["accessory"]
        if type(mapping) == "function" then
            slotType = mapping(item.meta)
        end
    else
        slotType = clothesSlotMapping[itemName]
    end

    if slotType then
        if not inventory[index].metadatas then
            inventory[index].metadatas = {}
        end
        inventory[index].metadatas.clothesSlotType = slotType

        local isKevlar = itemName == "gpb" or (item.meta and item.meta.type == "gpb")
        local hasRenamed = item.meta and item.meta.renamed
        if not isKevlar and not hasRenamed then
            -- Labels custom pour types spécifiques (Tshirt, Bras)
            local customLabels = { undershirt = "Tshirt", arms = "Bras" }
            local metaType = item.meta and item.meta.type
            if customLabels[metaType] then
                inventory[index].label = customLabels[metaType]
            elseif clothesLabels[slotType] then
                inventory[index].label = clothesLabels[slotType]
            end
        end

        if slotType == "body_armor" and item.meta.plates and #item.meta.plates > 0 then
            local totalDurability = 0
            for _, plate in ipairs(item.meta.plates) do
                totalDurability = totalDurability + (plate.durability or 0)
            end
            inventory[index].durability = math.min(totalDurability, 100)
        end
    end

    if not itemSex then
        return
    end

    if itemName == "accessory" then
        local category = isAccessoryProp(item.meta.type) and "props" or "clothing"
        inventory[index].url = buildImageUrl(itemSex, category, imgType[item.meta.type], item.meta.id, item.meta.var)
    elseif itemName == "top" or itemName == "outfit" then
        local torsoId = item.meta.skin and item.meta.skin["torso_1"]
        local torsoVar = item.meta.skin and item.meta.skin["torso_2"]

        if torsoId then
            inventory[index].url = buildImageUrl(itemSex, "clothing", imgType[itemName], torsoId, torsoVar)
        end
    else
        inventory[index].url = buildImageUrl(itemSex, "clothing", imgType[itemName], item.meta.id, item.meta.var or 0)
    end
end

---@description Get the equipped clothes
---@return table
function VFW.GetEquippedClothes()
    local equippedClothes = {}
    local equippedOutfit = nil

    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return equippedClothes, equippedOutfit
    end

    -- Obtenir la skin actuelle pour détecter les vêtements équipés directement (bypass timing issues)
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
    local bagVisibleOnModel = skin and tonumber(skin["bags_1"]) and tonumber(skin["bags_1"]) > 0
    local playerSexForDetection = (skin and skin.sex == 1) and "w" or "m"

    -- Mapping pour détection directe par skin
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
        ["gpb"] = { "bproof_1", "bproof_2" },
    }

    -- Go through player inventory to find equipped clothes and outfits
    for _, item in ipairs(VFW.PlayerData.inventory) do
        if VFW.Items[item.name] and (VFW.Items[item.name].type == "clothes" or VFW.Items[item.name].type == "outfit") then
            local itemName = item.name

            -- Handle outfits separately
            if VFW.Items[item.name].type == "outfit" then
                -- Détection directe pour outfits: comparer meta.skin avec skin actuelle
                local isOutfitEquipped = GetClothes["outfit"]
                if not isOutfitEquipped and item.meta and item.meta.skin and skin then
                    isOutfitEquipped = true
                    for k, v in pairs(item.meta.skin) do
                        if skin[k] ~= v then
                            isOutfitEquipped = false
                            break
                        end
                    end
                    if isOutfitEquipped then
                        GetClothes["outfit"] = true
                    end
                end

                if isOutfitEquipped then
                    -- Create the equipped outfit data structure
                    equippedOutfit = {
                        id = item.name .. "_equipped_outfit",
                        name = item.name,
                        count = item.count,
                        label = VFW.Items[item.name].label or item.name,
                        url = VFW.Items[item.name].image,
                        weight = VFW.Items[item.name].weight,
                        type = "outfit",
                        premium = item.premium,
                        slot = item.slot,
                        metadatas = item.meta,
                    }

                    -- Process clothing item to get correct image URL
                    local tempInventory = { equippedOutfit }
                    processClothingItem(item, 1, tempInventory)
                    equippedOutfit.url = tempInventory[1].url
                end
                -- Handle regular clothes
            elseif VFW.Items[item.name].type == "clothes" then
                -- Pour les accessoires, utiliser typeItem (bag, bracelet...) comme clé
                local typeItem = item.meta and item.meta.type or itemName

                -- Normaliser kevlar → gpb (cohérent avec clothes.lua)
                if typeItem == "kevlar" then
                    typeItem = "gpb"
                end

                -- DÉTECTION DIRECTE (bypass GetClothes timing issues)
                local isEquipped = false

                -- Pour les items avec meta.skin (tops), vérifier par matching exact
                -- Priorité à GetClothes pour éviter les faux positifs après unequip
                if itemName == "top" and item.meta and item.meta.skin then
                    if GetClothes["top"] == false then
                        -- Explicitement déséquipé, ne pas re-détecter par skin matching
                    elseif not equippedClothes["shirt"] and not IsClothingShopOpen and skin then
                        local topMatches = true
                        -- Vérifier que TOUS les composants du meta.skin matchent le skin
                        for k, v in pairs(item.meta.skin) do
                            if skin[k] ~= v then
                                topMatches = false
                                break
                            end
                        end
                        -- Vérifier aussi l'inverse : si c'est un undershirt (2 clés), s'assurer
                        -- que les composants torso/arms du skin correspondent à "nu" ou à un autre item
                        -- Sinon un haut complet est équipé et le undershirt matche faussement
                        if topMatches and item.meta.type == "undershirt" then
                            -- Un undershirt ne devrait matcher que si torso_1 est en position "nue"
                            local nakedTorso = (playerSexForDetection == "w") and 15 or 15
                            if skin["torso_1"] and tonumber(skin["torso_1"]) ~= nakedTorso then
                                -- Un haut est porté par-dessus → c'est le haut qui est "équipé", pas le undershirt
                                topMatches = false
                            end
                        elseif topMatches and item.meta.type == "arms" then
                            local nakedArms = 15
                            if skin["torso_1"] and tonumber(skin["torso_1"]) ~= nakedArms then
                                topMatches = false
                            end
                        end
                        if topMatches then
                            isEquipped = true
                        end
                    end
                else
                    -- Items simples : utiliser GetClothes
                    isEquipped = GetClothes[typeItem]
                end

                -- Si pas encore détecté, essayer la détection directe par skin
                -- Ne pas auto-détecter quand le magasin est ouvert (preview fausse la détection)
                -- Ne pas re-détecter si GetClothes dit explicitement false (vient d'être déséquipé)
                if not isEquipped and GetClothes[typeItem] ~= false and item.meta and skin and not IsClothingShopOpen then
                    -- SACS: via bag_uuid ou id
                    if (typeItem == "bag" or (itemName == "accessory" and item.meta.bag_uuid)) and bagVisibleOnModel then
                        if item.meta.bag_uuid then
                            isEquipped = true
                            GetClothes["bag"] = true
                        elseif item.meta.id and tonumber(item.meta.id) == tonumber(skin["bags_1"]) then
                            isEquipped = true
                            GetClothes["bag"] = true
                        end
                        -- AUTRES VÊTEMENTS: comparaison id/var avec skin
                    elseif translateSkin[typeItem] and item.meta.id then
                        local comp1 = translateSkin[typeItem][1]
                        local comp2 = translateSkin[typeItem][2]
                        local skinVal1 = tonumber(skin[comp1]) or 0
                        local skinVal2 = tonumber(skin[comp2]) or 0
                        local metaId = tonumber(item.meta.id) or 0
                        local metaVar = tonumber(item.meta.var) or 0

                        if skinVal1 > 0 and skinVal1 == metaId and skinVal2 == metaVar then
                            isEquipped = true
                            GetClothes[typeItem] = true
                        end
                    end
                end

                if isEquipped then
                    local slotType = nil

                    if type(clothesSlotMapping[itemName]) == "function" then
                        slotType = clothesSlotMapping[itemName](item.meta)
                    else
                        slotType = clothesSlotMapping[itemName]
                    end

                    -- Override le premier matché si cet item est explicitement marqué équipé
                    -- (cas 2 items identiques en stock: skin seul ne suffit pas à distinguer).
                    local explicitMatch = item.meta and item.meta._equippedSlot == item.slot
                    local currentEquipped = slotType and equippedClothes[slotType]
                    local currentIsExplicit = currentEquipped and currentEquipped.metadatas
                        and currentEquipped.metadatas._equippedSlot == currentEquipped.slot

                    if slotType and (not currentEquipped or (explicitMatch and not currentIsExplicit)) then
                        -- Create the equipped item data structure (toujours count = 1 pour le slot équipé)
                        local equippedItem = {
                            id = item.name .. "_equipped",
                            name = item.name,
                            count = 1,
                            label = (item.meta and item.meta.renamed) or VFW.Items[item.name].label or item.name,
                            url = VFW.Items[item.name].image,
                            weight = VFW.Items[item.name].weight,
                            type = "clothes",
                            premium = item.premium,
                            slot = item.slot,
                            metadatas = item.meta,
                            _originalCount = item.count,
                        }

                        -- Process clothing item to get correct image URL
                        local tempInventory = { equippedItem }
                        processClothingItem(item, 1, tempInventory)
                        equippedItem.url = tempInventory[1].url

                        -- Add clothesSlotType to metadatas
                        if not equippedItem.metadatas then
                            equippedItem.metadatas = {}
                        end
                        equippedItem.metadatas.clothesSlotType = slotType

                        equippedClothes[slotType] = equippedItem
                    end
                end
            end
        end
    end

    return equippedClothes, equippedOutfit
end

function VFW.LoadInventories(maxSlots, infiniteItems)
    local maxSlot = maxSlots and maxSlots or 100

    while not VFW.PlayerData do
        VFW.PlayerData = VFW.GetPlayerData()
        Wait(100)
    end

    local playerData = VFW.PlayerData
    local targetData
    if playerData.target then
        targetData = VFW.LoadInventory(playerData.target)
    else
        -- Load "Autour de moi" inventory with nearby pickups
        local inventory, weight, maxWeight, name = TriggerServerCallback("vfw:pickup:getNearby")
        -- Always create targetData for "Autour de moi", even if empty

        targetData = {
            items = inventory and #inventory > 0 and VFW.LoadInventory({ inventory = inventory }).items or {},
            label = name or "Autour de moi",
            iconName = "archive", -- Icon for nearby items
            weight = {
                max = maxWeight or 0,
                current = weight or 0
            },
            maxSlots = maxSlot,
            search = false
        }
    end

    local inventoryResult = VFW.LoadInventory(playerData)
    local money = inventoryResult and inventoryResult.money
    local inventoryData = inventoryResult and inventoryResult.items or {}

    local shortcuts = {}

    if not VFW.PlayerData.shortcuts then
        VFW.PlayerData.shortcuts = {}
    end

    if not VFW.PlayerData.inventory then
        VFW.PlayerData.inventory = {}
    end

    for i = 1, 5 do
        if not VFW.PlayerData.shortcuts[i] then
            goto continue
        end

        -- For shortcuts, search by name only (ignore metadata differences for stacked items)
        local itemId = nil
        local shortcutItemName = playerData.shortcuts[i].name

        for j = 1, #VFW.PlayerData.inventory do
            if VFW.PlayerData.inventory[j].name == shortcutItemName then
                itemId = j
                break
            end
        end

        if itemId and inventoryData[itemId] then
            shortcuts[i + 1] = inventoryData[itemId]
        end

        :: continue ::
    end

    -- Get equipped clothes and outfit
    local equippedClothes, equippedOutfit = VFW.GetEquippedClothes()

    -- Masquer les items équipés de l'inventaire (ils sont affichés dans les slots vêtements)
    local equippedSlots = {}
    for _, clothItem in pairs(equippedClothes) do
        if clothItem and clothItem.slot then
            equippedSlots[clothItem.slot] = true
        end
    end
    if equippedOutfit and equippedOutfit.slot then
        equippedSlots[equippedOutfit.slot] = true
    end
    -- Récupérer les counts originaux des items équipés pour gérer les stacks
    local equippedOriginalCounts = {}
    for _, clothItem in pairs(equippedClothes) do
        if clothItem and clothItem.slot and clothItem._originalCount and clothItem._originalCount > 1 then
            equippedOriginalCounts[clothItem.slot] = clothItem._originalCount
        end
    end

    for idx, item in pairs(inventoryData) do
        if item and equippedSlots[item.slot] then
            if equippedOriginalCounts[item.slot] and equippedOriginalCounts[item.slot] > 1 then
                -- Stack : garder l'item dans l'inventaire avec count - 1
                item.count = equippedOriginalCounts[item.slot] - 1
            else
                inventoryData[idx] = nil
            end
        end
    end

    SendNUIMessage({
        action = "nui:inventory:data",
        data = {
            toggleInventory = open,
            shortcuts = shortcuts,
            showShortcut = playerData.shortcutsActive,
            weight = {
                max = VFW.PlayerData.maxWeight,
                current = playerData.weight
            },
            maxSlots = playerData.maxSlots or 100,
            items = inventoryData,
            secondaryInventory = targetData,
            clothes = equippedClothes,
            outfit = equippedOutfit,
            playerInfo = {
                money = money,
                lastname = playerData.lastName or "",
                firstname = playerData.firstName or "",
            }
        }
    })
end

---@description Type mapping from server to frontend item type
---@param serverType string
---@return string
local function mapItemType(serverType)
    local typeMapping = {
        ["items"] = "items", -- ItemType.OBJECT = "items"
        ["weapons"] = "weapon", -- ItemType.WEAPON = "weapon"
        ["clothes"] = "clothes", -- ItemType.CLOTHES = "clothes"
        ["food"] = "food", -- ItemType.FOOD = "food"
        ["drink"] = "drink",
        ["outfit"] = "outfit", -- ItemType.OUTFIT = "outfit"
        ["document"] = "document",
        ["keys"] = "keys"
    }
    return typeMapping[serverType] or "items"
end

function VFW.LoadInventory(targetData)
    local money = nil
    local isPlayerInventory = false
    local VFWItems = VFW.Items

    if targetData == VFW.PlayerData then
        isPlayerInventory = true
    end

    local inventoryData = {}
    if not targetData.inventory then return inventoryData end
    local skipped = 0
    for i = 1, #targetData.inventory do
        local v = targetData.inventory[i]

        if not VFWItems[v.name] then
            print(("[LoadInventory] Item inconnu skippé: %s (chest=%s)"):format(tostring(v.name), tostring(targetData.chestId)))
            skipped = skipped + 1
            goto continue
        end

        -- Use slot system only - force items to have slot
        local slot = v.slot
        if not slot then
            print(("[LoadInventory] Item %s sans slot - skip (chest=%s)"):format(tostring(v.name), tostring(targetData.chestId)))
            skipped = skipped + 1
            goto continue
        end

        -- Fusionner les metadatas de l'instance avec manufacture depuis les données de l'item
        local itemMetadatas = {}
        if v.meta then
            for k, val in pairs(v.meta) do
                itemMetadatas[k] = val
            end
        end
        if VFWItems[v.name].data and VFWItems[v.name].data.manufacture then
            itemMetadatas.manufacture = VFWItems[v.name].data.manufacture
        end

        inventoryData[i] = {
            id = i,
            name = v.name,
            count = v.count,
            label = v.meta and v.meta.renamed or VFWItems[v.name].label or v.name,
            url = VFW.ItemImageUrl(v.name, VFWItems[v.name]),
            weight = VFWItems[v.name].weight,
            type = mapItemType(VFWItems[v.name].type),
            premium = VFWItems[v.name].premium,
            description = v.meta and v.meta.description or VFWItems[v.name].data and VFWItems[v.name].data.description or VFWItems[v.name].description,
            -- durability = 75,
            position = v.position, -- Keep for backward compatibility
            slot = slot,
            metadatas = itemMetadatas,
        }

        if VFWItems[v.name].type == "clothes" then
            processClothingItem(v, i, inventoryData)
        elseif isPlayerInventory and inventoryData[i].name == "money" then
            money = inventoryData[i].count
        end

        :: continue ::
    end

    if skipped > 0 then
        print(("[LoadInventory] %d items filtrés sur le coffre %s (total reçu: %d)"):format(skipped, tostring(targetData.chestId), #targetData.inventory))
    end

    -- Determine icon based on chest type
    local iconName = "archive" -- Default icon for chests
    if targetData.chestId then
        if string.find(targetData.chestId, "veh:") then
            iconName = "car"
        elseif string.find(targetData.chestId, "property:") then
            iconName = "home"
        else
            iconName = "box" -- Use "box" icon for regular chests instead of "archive"
        end
    elseif targetData.search then
        iconName = "user"
    end

    return {
        items = inventoryData,
        label = targetData.name or targetData.label or "Inventaire",
        iconName = iconName,
        weight = {
            max = targetData.maxWeight or Config.MaxWeight,
            current = targetData.weight or 0
        },
        maxSlots = targetData.maxSlots or 100,
        search = targetData.search,
        infiniteItems = targetData.infiniteItems or false,
        money = money,
        canViewHistory = targetData.chestId ~= nil,
        chestId = targetData.chestId,
    }
end

function VFW.tooHeavy()
    if tooHeavyThread then
        return
    end

    tooHeavyThread = true

    VFW.ShowNotification({
        type = 'ROUGE',
        content = "Vous ne pouvez plus courir, vous avez trop d'objets sur vous.",
        duration = 10
    })

    CreateThread(function()
        while tooHeavyThread do
            DisableControlAction(0, 21, true) -- Disable sprint
            DisableControlAction(0, 22, true) -- Disable jump
            Wait(0)
        end
    end)
end

local id = 1

function VFW.NotifyInventoryChange(inventory, weight, oldInventoryOverride)
    local oldInventory = oldInventoryOverride or VFW.PlayerData.inventory

    local itemTracker = {} -- Table principale
    local newItemsSignatures = {} -- Pour stocker les signatures des items présents

    -- Fonction utilitaire pour comparer les metadatas
    local function getMetaSignature(meta)
        return meta and json.encode(meta) or "nil"
    end

    -- 1. Analyser le NOUVEL inventaire
    for i = 1, #inventory do
        local item = inventory[i]
        local name = item.name
        local signature = getMetaSignature(item.meta)

        -- On enregistre que cette signature existe dans le nouvel inventaire
        if not newItemsSignatures[name] then
            newItemsSignatures[name] = {}
        end
        newItemsSignatures[name][signature] = true

        if not itemTracker[name] then
            itemTracker[name] = {
                current = 0,
                old = 0,
                meta = item.meta, -- Par défaut pour les ajouts
                label = item.label,
                droppedMeta = nil
            }
        end
        itemTracker[name].current = itemTracker[name].current + item.count
        -- Pour un AJOUT, on veut les meta actuelles
        itemTracker[name].meta = item.meta
    end

    -- 2. Analyser l'ANCIEN inventaire
    if oldInventory and next(oldInventory) then
        for i = 1, #oldInventory do
            local item = oldInventory[i]
            local name = item.name
            local signature = getMetaSignature(item.meta)

            if not itemTracker[name] then
                itemTracker[name] = { current = 0, old = 0, meta = item.meta, label = item.label, droppedMeta = nil }
            end
            itemTracker[name].old = itemTracker[name].old + item.count

            -- FIX ICI : Si cette signature (meta) n'existe PAS dans le nouvel inventaire,
            -- c'est que c'est précisément CET item qui a été jeté. On sauvegarde sa meta.
            if not newItemsSignatures[name] or not newItemsSignatures[name][signature] then
                itemTracker[name].droppedMeta = item.meta
            end
        end
    end

    for itemName, data in pairs(itemTracker) do
        local diff = data.current - data.old

        if diff ~= 0 then
            local itemDef = VFW.Items[itemName]

            id = id + 1

            local finalLabel = (itemDef and itemDef.label) or data.label or itemName
            local typeDiff = (diff > 0) and 1 or 0

            -- LOGIQUE DES METAS :
            -- Si c'est un ajout (type 1), on prend data.meta (le nouveau)
            -- Si c'est un retrait (type 0), on regarde si on a trouvé une droppedMeta spécifique
            local metaToSend = data.meta
            if diff < 0 and data.droppedMeta then
                metaToSend = data.droppedMeta
            end

            -- Pour les vêtements, enrichir les metadata avec clothesSlotType et corriger le label
            if itemDef and itemDef.type == "clothes" and metaToSend then
                -- Copier les meta pour ne pas modifier l'original
                local metaCopy = {}
                for k, v in pairs(metaToSend) do
                    metaCopy[k] = v
                end
                metaToSend = metaCopy

                -- Déterminer le clothesSlotType
                local slotType = nil
                local mapping = clothesSlotMapping[itemName]
                if type(mapping) == "function" then
                    slotType = mapping(metaToSend)
                else
                    slotType = mapping
                end

                -- Ajouter clothesSlotType aux metadata
                if slotType then
                    metaToSend.clothesSlotType = slotType
                    local isKevlar = itemName == "gpb" or (metaToSend and metaToSend.type == "gpb")
                    if clothesLabels[slotType] and not isKevlar then
                        finalLabel = clothesLabels[slotType]
                    end
                end
            end

            SendNUIMessage({
                action = "nui:itemTrade:data",
                data = {
                    id = id,
                    type = typeDiff,
                    item_number = math.abs(diff),
                    item_image = itemName .. '.webp',
                    item_label = finalLabel,
                    metadata = metaToSend
                }
            })
        end
    end

    -- 4. Poids
    if not VFW.PlayerGlobalData.permissions["dev"] then
        if weight > VFW.PlayerData.maxWeight then
            VFW.tooHeavy()
        elseif tooHeavyThread then
            tooHeavyThread = false
        end
    end
end

-- Event pour afficher une notification d'item (utilisé par /giveitem)
RegisterNetEvent("vfw:showItemNotification", function(itemName, amount, itemType)
    local itemDef = VFW.Items[itemName]
    if not itemDef then
        return
    end

    id = id + 1
    SendNUIMessage({
        action = "nui:itemTrade:data",
        data = {
            id = id,
            type = itemType or 1, -- 1 = ajout, 0 = retrait
            item_number = amount,
            item_image = itemName .. '.webp',
            item_label = itemDef.label or itemName,
            metadata = nil
        }
    })
end)

RegisterNetEvent("vfw:updateInventory", function(inventory, weight)
    -- Sauvegarder l'ancien inventaire avant la mise à jour pour les notifications
    local oldInventory = VFW.PlayerData.inventory

    VFW.PlayerData.inventory = inventory
    VFW.PlayerData.weight = weight

    -- Déclencher les notifications pour les changements d'inventaire
    VFW.NotifyInventoryChange(inventory, weight, oldInventory)

    -- NOTE: L'auto-équipement du sac a été désactivé car il causait des équipements
    -- non désirés à chaque mise à jour d'inventaire. Le sac s'équipe maintenant uniquement:
    -- 1. Via le callback equipClothes (quand le joueur équipe manuellement)
    -- 2. Via l'achat dans le shop (cloths_shop.lua)

    if open then
        VFW.LoadInventories()
    end
end)

RegisterNetEvent("vfw:chest:update", function(inventory, weight)
    if not VFW.PlayerData.target then
        VFW.PlayerData.target = {}
    end
    VFW.PlayerData.target.inventory = inventory
    VFW.PlayerData.target.weight = weight

    if open then
        VFW.LoadInventories()
    end
end)

RegisterNetEvent("vfw:search:update", function(inventory, weight)
    if not VFW.PlayerData.target then return end
    VFW.PlayerData.target.inventory = inventory
    VFW.PlayerData.target.weight = weight

    if open then
        VFW.LoadInventories()
    end
end)

RegisterNetEvent("vfw:nearbyPickups:refresh", function()
    -- Refresh "Nearby" inventory only if no specific target
    if open and not VFW.PlayerData.target then
        VFW.LoadInventories()
    end
end)

for i = 1, 5 do
    RegisterCommand(('+shortcut%s'):format(tostring(i)), function()
        if open then
            return
        end

        if not VFW.PlayerData.shortcuts[i] then
            return
        end

        if IsPedSittingInAnyVehicle(VFW.PlayerData.ped, false) then
            local itemName = VFW.PlayerData.shortcuts[i].name
            local itemData = VFW.Items[itemName]
            if not itemData or itemData.type ~= "weapons" then
                return
            end
        end

        if IsWeaponChanging then
            return
        end

        local inventory, weight = TriggerServerCallback("vfw:useItem", VFW.PlayerData.shortcuts[i].name,
                VFW.PlayerData.shortcuts[i].metadatas)
        if inventory then
            VFW.PlayerData.inventory = inventory
            VFW.PlayerData.weight = weight
            if not IsPedSittingInAnyVehicle(VFW.PlayerData.ped, false) then
                VFW.LoadInventories()
            end
        end
    end)

    RegisterKeyMapping(('+shortcut%s'):format(tostring(i)), ('Raccourci inventaire %s'):format(tostring(i)), 'keyboard',
            tostring(i))
end

local disableUseAmmo = false
local RELOAD_COOLDOWN_CLIENT = 2000 -- 2 secondes

-- Aligné sur serveur (gestion/inventory/weapon.lua) + HUD : sans ammoType configuré
-- (ou avec une valeur invalide), on détecte l'item munition d'après le nom d'arme.
local reloadCustomWeaponAmmo = {
    ["WEAPON_AR15"] = "ammo_rifle",
    ["WEAPON_HK416"] = "ammo_rifle",
    ["WEAPON_KS1"] = "ammo_rifle",
    ["WEAPON_M4A1CD"] = "ammo_rifle",
    ["WEAPON_GLOCK20"] = "ammo_pistol",
    ["WEAPON_PDGLOCK17"] = "ammo_pistol",
    ["WEAPON_SIG_SAUCER"] = "ammo_pistol",
    ["WEAPON_SWMP9L"] = "ammo_pistol",
    ["WEAPON_PDPT700"] = "ammo_heavy",
}

local reloadValidAmmoTypes = {
    ["ammo_pistol"] = true,
    ["ammo_rifle"] = true,
    ["ammo_shotgun"] = true,
    ["ammo_snip"] = true,
    ["ammo_heavy"] = true,
    ["ammo_airsoft"] = true,
    ["ammo_beanbag"] = true,
    ["ammo_launcher"] = true,
    ["ammo_musquet"] = true,
    ["ammo_flare"] = true,
    ["ammo_rocket"] = true,
}

local function GetAmmoItemForWeaponReload(weaponName)
    if type(weaponName) ~= "string" then return nil end
    weaponName = weaponName:upper()

    if reloadCustomWeaponAmmo[weaponName] then return reloadCustomWeaponAmmo[weaponName] end
    if string.find(weaponName, "AIRSOFT") then return "ammo_airsoft" end
    if string.find(weaponName, "BEANBAG") then return "ammo_beanbag" end
    if string.find(weaponName, "MUSKET") then return "ammo_musquet" end
    if string.find(weaponName, "FLAREGUN") then return "ammo_flare" end
    if string.find(weaponName, "COMPACTLAUNCHER") or string.find(weaponName, "HOMINGLAUNCHER") then return "ammo_rocket" end
    if string.find(weaponName, "LAUNCHER") or string.find(weaponName, "RPG") or string.find(weaponName, "FIREWORK") then return "ammo_launcher" end
    if string.find(weaponName, "COMBATMG") or weaponName == "WEAPON_MG" or string.find(weaponName, "MINIGUN") or string.find(weaponName, "RAILGUN") or string.find(weaponName, "HEAVYSNIPER") then return "ammo_heavy" end
    if string.find(weaponName, "MARKSMANRIFLE") or string.find(weaponName, "PRECISIONRIFLE") or string.find(weaponName, "SNIPERRIFLE") then return "ammo_snip" end
    if string.find(weaponName, "PISTOL") or string.find(weaponName, "REVOLVER") then return "ammo_pistol" end
    if string.find(weaponName, "SMG") or string.find(weaponName, "PDW") or string.find(weaponName, "GUSENBERG") or string.find(weaponName, "RAYCARBINE") then return "ammo_rifle" end
    if string.find(weaponName, "RIFLE") then return "ammo_rifle" end
    if string.find(weaponName, "SHOTGUN") then return "ammo_shotgun" end
    return nil
end

RegisterCommand('+useAmmo', function()
    if open or disableUseAmmo then
        return
    end
    if IsPedSittingInAnyVehicle(VFW.PlayerData.ped, false) then
        return
    end
    if not VFW.PlayerData.inventory then
        return
    end

    local ped = VFW.PlayerData.ped
    local weapon = GetSelectedPedWeapon(ped)
    local weaponData = VFW.GetWeaponFromHash(weapon)
    if not weaponData then
        return
    end

    local itemData = VFW.Items[string.lower(weaponData.name)]
    local configuredAmmo = itemData and itemData.data and itemData.data.ammoType
    -- Avant : return silencieux si ammoType absent → R ne faisait rien, seul le clic
    -- gauche à chargeur vide (weapon.lua) passait par le serveur (qui a le fallback).
    local ammoType = (configuredAmmo and reloadValidAmmoTypes[configuredAmmo] and configuredAmmo)
        or GetAmmoItemForWeaponReload(weaponData.name)
    if not ammoType or not reloadValidAmmoTypes[ammoType] then
        return
    end

    local engineClip = select(2, GetAmmoInClip(ped, weapon)) or 0
    local bulletsInClip = (VFW.GetReliableClipAmmo and VFW.GetReliableClipAmmo(ped, weapon)) or engineClip
    local maxBullets = (VFW.GetReliableMaxClip and VFW.GetReliableMaxClip(ped, weapon))
                        or GetMaxAmmoInClip(ped, weapon, true)
                        or 0

    -- Cache "reliable" stale : engine voit clip non plein → on autorise le reload.
    if maxBullets > 0 and bulletsInClip >= maxBullets and engineClip < maxBullets then
        bulletsInClip = engineClip
        if VFW.ResyncExtendedClip then
            VFW.ResyncExtendedClip(ped, weapon)
        end
    end

    if maxBullets > 0 and bulletsInClip >= maxBullets then
        -- Resync l'engine quand des balles sont planquées dans la fausse réserve étendue.
        if VFW.ResyncExtendedClip then
            VFW.ResyncExtendedClip(ped, weapon)
        end
        disableUseAmmo = true
        SetTimeout(500, function()
            disableUseAmmo = false
        end)
        return
    end

    local available = 0
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.PlayerData.inventory[i].name == ammoType then
            available = available + VFW.PlayerData.inventory[i].count
        end
    end

    if available == 0 then
        VFW.ShowNotification({ type = "ROUGE", content = "Vous n'avez plus de munitions" })
        return
    end

    disableUseAmmo = true

    TriggerServerEvent("vfw:weapon:reload", weapon)

    SetTimeout(RELOAD_COOLDOWN_CLIENT, function()
        disableUseAmmo = false
    end)
end)

RegisterKeyMapping("+useAmmo", "Recharger l'arme", "keyboard", "R")

RegisterClientCallback("vfw:getAmmoInPedWeapon", function(hash)
    return VFW.GetReliableClipAmmo(VFW.PlayerData.ped, hash)
end)

RegisterClientCallback("vfw:getWeaponClipInfo", function(hash)
    local ped = VFW.PlayerData.ped
    return {
        ammo = VFW.GetReliableClipAmmo(ped, hash) or 0,
        maxClip = (VFW.GetReliableMaxClip and VFW.GetReliableMaxClip(ped, hash))
                  or GetMaxAmmoInClip(ped, hash, true)
                  or 0,
    }
end)

function VFW.OpenChest(chestId, type, maxSlots)
    local pos = GetEntityCoords(VFW.PlayerData.ped)
    local inventory, weight, maxWeight, name, maxSlotsInDb = TriggerServerCallback("vfw:chest:get", chestId)

    VFW.OpenInventory({
        chestId = chestId,
        inventory = inventory,
        name = name,
        maxWeight = maxWeight,
        weight = weight,
        search = false,
        type = type,
        maxSlots = maxSlotsInDb or maxSlots or 100,
    })

    CreateThread(function()
        VFW.DisableInterations(true)

        while VFW.StateInventory() do
            if #(GetEntityCoords(VFW.PlayerData.ped) - pos) > 2 then
                VFW.CloseInventory()
                break
            end

            Wait(0)
        end

        VFW.DisableInterations(false)
    end)
end

function VFW.OpenShearch(targetId)
    if targetId == GetPlayerServerId(NetworkGetPlayerIndexFromPed(VFW.PlayerData.ped)) then
        return
    end

    ExecuteCommand("me fouille la personne en face")

    ExecuteCommand("e psixzzq")

    local inventory = TriggerServerCallback("vfw:search:get", targetId)

    VFW.OpenInventory({
        targetId = targetId,
        inventory = inventory or {},
        name = "Inventaire fouillé",
        maxWeight = 0,
        weight = 0,
        search = true,
    })
end

function VFW.OpenShearchGouv(targetId)
    if targetId == GetPlayerServerId(NetworkGetPlayerIndexFromPed(VFW.PlayerData.ped)) then
        return
    end

    local inventory = TriggerServerCallback("vfw:search:get", targetId)

    VFW.OpenInventory({
        targetId = targetId,
        inventory = inventory or {},
        name = "Inventaire fouillé",
        maxWeight = 0,
        weight = 0,
        search = true,
    })
end

function VFW.OpenShearchStaff(targetId)
    local inventory = TriggerServerCallback("vfw:search:get", targetId)

    VFW.OpenInventory({
        targetId = targetId,
        inventory = inventory or {},
        name = "Inventaire fouillé",
        maxWeight = 0,
        weight = 0,
        search = true,
    })
end

RegisterNetEvent("lb-phone:usePhoneItem", function()
    VFW.CloseInventory()
end)

-- Test chest system
RegisterNetEvent("vfw:openTestChest", function(chestId)
    console.debug("Received vfw:openTestChest event with chestId: " .. chestId)

    if not VFW.OpenChest then
        console.error("VFW.OpenChest function not found!")
        return
    end

    console.debug("Calling VFW.OpenChest with chestId: " .. chestId)
    VFW.OpenChest(chestId, "test")
    console.debug("VFW.OpenChest call completed")
end)

function VFW.HaveTablet()
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.PlayerData.inventory[i].name == "tablet" then
            return true
        end
    end

    return false
end

-- Table pour stocker les items infinis (slot -> itemName mapping)
local infiniteItemsMap = {}

---Open infinite inventory with all items
RegisterNetEvent("vfw:openInfiniteItemsInventory", function(allItems)

    -- Créer le mapping slot -> itemName
    infiniteItemsMap = {}
    for _, item in ipairs(allItems) do
        infiniteItemsMap[item.slot] = item.name
    end

    local infiniteTarget = {
        inventory = allItems,
        name = "Tous les items",
        maxWeight = 999999,
        weight = 0,
        search = false,
        infiniteItems = true, -- Flag pour indiquer que c'est un inventaire infini
        maxSlots = #allItems,
    }

    VFW.OpenInventory(infiniteTarget)
end)

function VFW.GetInfiniteItemNameFromSlot(slot)
    return infiniteItemsMap[slot]
end

