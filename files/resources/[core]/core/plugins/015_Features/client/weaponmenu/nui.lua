local weaponMenuOpen = false
local weaponMenuWeaponId = nil
local weaponMenuWeaponName = nil

--- Ouvre le menu arme en mode VIP (teintes + skins toujours visibles)
function OpenWeaponMenuVip(weaponItem, weaponData)
    OpenWeaponMenu(weaponItem, weaponData, true)
end

function OpenWeaponMenu(weaponItem, weaponData, forceVip)
    if weaponMenuOpen then return end

    local equippedComponents = weaponItem.meta and weaponItem.meta.components or {}
    local currentTint = weaponItem.meta and weaponItem.meta.tint or 0
    local isMK2 = string.find(weaponData.name:upper(), "_MK2") ~= nil
    local noTint = weaponData.noTint or weaponData.airsoft or false

    -- Tints/skins only visible when opened from VIP menu (forceVip = true)
    local isVip = forceVip == true

    local allComponents = {}
    if weaponData.components then
        for _, comp in ipairs(weaponData.components) do
            local itemName = GetItemFromHash(comp.hash)
            if itemName then
                local isCosmetic = IsCosmeticComponent(comp.hash)
                local isEquipped = IsComponentEquippedOnWeapon(equippedComponents, comp.hash)
                local hasInInventory = false
                if not isCosmetic then
                    hasInInventory = HasComponentInInventory(comp.hash)
                end
                table.insert(allComponents, {
                    name = comp.name or comp.hash,
                    label = GetComponentLabel(comp.hash, comp.label),
                    hash = comp.hash,
                    isCosmetic = isCosmetic,
                    isEquipped = isEquipped,
                    hasInInventory = hasInInventory,
                    itemName = itemName,
                })
            end
        end
    end

    weaponMenuOpen = true
    weaponMenuWeaponId = weaponItem.meta and weaponItem.meta.weaponId or nil
    weaponMenuWeaponName = weaponData.name

    CreateWeaponPreview2D(weaponData.name, weaponData.label, equippedComponents)

    VFW.Nui.Focus(true, false)
    SendNUIMessage({
        action = "openWeaponMenu",
        data = {
            weaponData = {
                name = weaponData.name,
                label = weaponData.label,
                weaponId = weaponMenuWeaponId,
                isMK2 = isMK2,
                noTint = noTint,
                isVip = isVip,
                currentTint = currentTint,
                components = allComponents,
                equippedComponents = equippedComponents,
            },
        }
    })
end

local function CloseWeaponMenu()
    if not weaponMenuOpen then return end
    weaponMenuOpen = false
    CleanupWeaponPreview()
    VFW.Nui.Focus(false, false)
    SendNUIMessage({ action = "closeWeaponMenu" })
    weaponMenuWeaponId = nil
    weaponMenuWeaponName = nil
end

RegisterNUICallback("weaponMenu:close", function(_, cb)
    CloseWeaponMenu()
    cb({ ok = true })
end)

RegisterNUICallback("nui:inventory:open-weapon-menu", function(data, cb)
    cb({ ok = true })

    local clientItem = data and data.item
    if not clientItem or not clientItem.name then return end

    local meta = clientItem.metadatas or clientItem.meta
    if not meta or not meta.weaponId then return end

    local weaponItemFromInventory = nil
    if VFW.PlayerData and VFW.PlayerData.inventory then
        for _, inv in ipairs(VFW.PlayerData.inventory) do
            if inv.name == clientItem.name and inv.meta and inv.meta.weaponId == meta.weaponId then
                weaponItemFromInventory = inv
                break
            end
        end
    end

    local weaponItem = weaponItemFromInventory or { name = clientItem.name, meta = meta }

    local weaponName = clientItem.name:upper()
    local weaponData = nil
    for _, w in ipairs(Config.Weapons or {}) do
        if w.name and w.name:upper() == weaponName then
            weaponData = w
            break
        end
    end

    if not weaponData then return end

    if VFW.StateInventory and VFW.StateInventory() then
        VFW.CloseInventory()
    end

    CreateThread(function()
        Wait(150)
        OpenWeaponMenu(weaponItem, weaponData)
    end)
end)

RegisterNUICallback("weaponMenu:setTint", function(data, cb)
    if weaponPreviewObject and DoesEntityExist(weaponPreviewObject) then
        SetWeaponObjectTintIndex(weaponPreviewObject, data.tintIndex)
    end
    local ped = PlayerPedId()
    local weaponHash = GetSelectedPedWeapon(ped)
    if weaponHash ~= GetHashKey("WEAPON_UNARMED") then
        SetPedWeaponTintIndex(ped, weaponHash, data.tintIndex)
    end
    TriggerServerEvent("vfw:weapon:setTint", data.weaponId, data.tintIndex)
    cb({ ok = true })
end)

RegisterNUICallback("weaponMenu:previewTint", function(data, cb)
    if weaponPreviewObject and DoesEntityExist(weaponPreviewObject) then
        SetWeaponObjectTintIndex(weaponPreviewObject, data.tintIndex)
    end
    cb({ ok = true })
end)

RegisterNUICallback("weaponMenu:rotateWeapon", function(data, cb)
    if weaponPreviewObject and DoesEntityExist(weaponPreviewObject) then
        local dx = tonumber(data.deltaX) or 0
        local dy = tonumber(data.deltaY) or 0
        weaponPreviewRotation = weaponPreviewRotation + dx * 0.5
        weaponPreviewRotationY = math.max(-30.0, math.min(30.0, weaponPreviewRotationY + dy * 0.3))
        SetEntityRotation(weaponPreviewObject, weaponPreviewRotationY, 0.0, currentBaseRotZ + weaponPreviewRotation, 2, true)
    end
    cb({ ok = true })
end)

RegisterNUICallback("weaponMenu:addComponent", function(data, cb)
    TriggerServerEvent("vfw:weapon:addComponent", data.weaponId, data.componentHash)
    cb({ ok = true })
end)

RegisterNUICallback("weaponMenu:removeComponent", function(data, cb)
    TriggerServerEvent("vfw:weapon:removeComponent", data.weaponId, data.componentHash)
    cb({ ok = true })
end)

RegisterNUICallback("weaponMenu:applyCosmetic", function(data, cb)
    TriggerServerEvent("vfw:weapon:applyCosmeticComponent", data.weaponId, data.componentHash)
    if weaponPreviewObject and DoesEntityExist(weaponPreviewObject) then
        local hash = data.componentHash
        if type(hash) == "string" then hash = GetHashKey(hash) end
        local compModel = GetWeaponComponentTypeModel(hash)
        if compModel and compModel ~= 0 then
            RequestModel(compModel)
            local loadTimeout = 0
            while not HasModelLoaded(compModel) and loadTimeout < 50 do
                Wait(0)
                loadTimeout = loadTimeout + 1
            end
        end
        GiveWeaponComponentToWeaponObject(weaponPreviewObject, hash)
    end
    cb({ ok = true })
end)

RegisterNUICallback("weaponMenu:removeCosmetic", function(data, cb)
    TriggerServerEvent("vfw:weapon:removeCosmeticComponent", data.weaponId, data.componentHash)
    if weaponMenuWeaponName then
        local equippedComponents = {}
        for _, item in ipairs(VFW.PlayerData.inventory) do
            if item.meta and item.meta.weaponId == data.weaponId then
                equippedComponents = item.meta.components or {}
                break
            end
        end
        local newComps = {}
        for _, c in ipairs(equippedComponents) do
            if c ~= data.componentHash then
                table.insert(newComps, c)
            end
        end
        UpdateWeaponPreviewObject(weaponMenuWeaponName, newComps)
    end
    cb({ ok = true })
end)

RegisterNUICallback("weaponMenu:previewComponent", function(data, cb)
    if weaponPreviewObject and DoesEntityExist(weaponPreviewObject) then
        local hash = data.componentHash
        if type(hash) == "string" then hash = GetHashKey(hash) end
        local compModel = GetWeaponComponentTypeModel(hash)
        if compModel and compModel ~= 0 then
            RequestModel(compModel)
            local loadTimeout = 0
            while not HasModelLoaded(compModel) and loadTimeout < 50 do
                Wait(0)
                loadTimeout = loadTimeout + 1
            end
        end
        GiveWeaponComponentToWeaponObject(weaponPreviewObject, hash)
    end
    cb({ ok = true })
end)

RegisterNetEvent("vfw:weapon:componentUpdated", function(weaponId, components)
    if not weaponMenuOpen then return end
    if weaponMenuWeaponName then
        UpdateWeaponPreviewObject(weaponMenuWeaponName, components)
    end

    local updatedComps = {}
    local weaponData = nil
    for _, item in ipairs(VFW.PlayerData.inventory) do
        if item.meta and item.meta.weaponId == weaponId then
            weaponData = item
            break
        end
    end

    if weaponData then
        local allWeapons = Config.Weapons or {}
        local weaponCfg = nil
        for _, w in ipairs(allWeapons) do
            if GetHashKey(w.name:upper()) == GetHashKey(weaponMenuWeaponName) then
                weaponCfg = w
                break
            end
        end

        if weaponCfg and weaponCfg.components then
            for _, comp in ipairs(weaponCfg.components) do
                local itemName = GetItemFromHash(comp.hash)
                if itemName then
                    local isCosmetic = IsCosmeticComponent(comp.hash)
                    local isEquipped = IsComponentEquippedOnWeapon(components, comp.hash)
                    local hasInInventory = false
                    if not isCosmetic then
                        hasInInventory = HasComponentInInventory(comp.hash)
                    end
                    table.insert(updatedComps, {
                        name = comp.name or comp.hash,
                        label = GetComponentLabel(comp.hash, comp.label),
                        hash = comp.hash,
                        isCosmetic = isCosmetic,
                        isEquipped = isEquipped,
                        hasInInventory = hasInInventory,
                        itemName = itemName,
                    })
                end
            end
        end
    end

    SendNUIMessage({
        action = "weaponMenu:componentUpdated",
        data = {
            weaponId = weaponId,
            components = updatedComps,
            equippedComponents = components,
        }
    })
end)

RegisterNetEvent("vfw:weapon:tintUpdated", function(weaponId, tintIndex)
    if not weaponMenuOpen then return end
    SendNUIMessage({
        action = "weaponMenu:tintUpdated",
        data = { weaponId = weaponId, tintIndex = tintIndex }
    })
end)
