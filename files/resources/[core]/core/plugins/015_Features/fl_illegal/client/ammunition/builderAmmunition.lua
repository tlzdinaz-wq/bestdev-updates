-- Ammunition Builder for Staff Menu

local currentAmmunitionBuild = {
    name = "",
    position = nil,
    npcPosition = nil,
    blipEnabled = true,
    isValid = false
}

local currentItemBuild = {
    item_name = "",
    price = 0,
    category = "tous",
    active = true
}

local markerThread = nil
local isMarkersActive = false

local AMMUNITION_CATEGORIES = {
    {value = "tous", label = "Tous"},
    {value = "arme_blanche", label = "Arme blanche"},
    {value = "munition", label = "Munition"},
    {value = "arme_legere", label = "Arme légère"},
    {value = "arme_lourde", label = "Arme lourde"}
}

local function getCategoryLabel(category)
    for _, cat in ipairs(AMMUNITION_CATEGORIES) do
        if cat.value == category then
            return cat.label
        end
    end
    return category
end

local function validateAmmunitionBuild()
    currentAmmunitionBuild.isValid = currentAmmunitionBuild.name ~= "" and
            currentAmmunitionBuild.npcPosition ~= nil
    return currentAmmunitionBuild.isValid
end

local function validateItemBuild()
    return currentItemBuild.item_name ~= "" and
            currentItemBuild.price > 0 and
            currentItemBuild.category ~= ""
end

local function getCurrentPlayerPosition()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then
        return nil
    end

    local coords = GetEntityCoords(playerPed)
    if not coords then
        return nil
    end

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = GetEntityHeading(playerPed)
    }
end

local function stopMarkerThread()
    if markerThread then
        isMarkersActive = false
        markerThread = nil
    end
end

local function startMarkerThread()
    if markerThread then
        return
    end

    isMarkersActive = true
    markerThread = CreateThread(function()
        while isMarkersActive do
            if currentAmmunitionBuild.position then
                local blipPos = currentAmmunitionBuild.position
                local coords = vector3(blipPos.x, blipPos.y, blipPos.z)

                DrawMarker(
                    1,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.5, 1.5, 1.0,
                    255, 0, 0, 150,
                    false, true, 2, false, nil, nil, false
                )

                local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 0, 0, 215)
                    SetTextCentre(true)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("BLIP")
                    DrawText(screenX, screenY)
                end
            end

            if currentAmmunitionBuild.npcPosition then
                local npcPos = currentAmmunitionBuild.npcPosition
                local coords = vector3(npcPos.x, npcPos.y, npcPos.z)

                DrawMarker(
                    27,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    255, 0, 0, 150,
                    false, true, 2, false, nil, nil, false
                )

                local text = "VENDEUR\n" .. currentAmmunitionBuild.name

                local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.4, 0.4)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 0, 0, 215)
                    SetTextCentre(true)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString(text)
                    DrawText(screenX, screenY)
                end
            end

            Wait(0)
        end
    end)
end

local function resetAmmunitionBuild()
    stopMarkerThread()
    currentAmmunitionBuild = {
        name = "",
        position = nil,
        npcPosition = nil,
        blipEnabled = true,
        isValid = false
    }
end

local function resetItemBuild()
    currentItemBuild = {
        item_name = "",
        price = 0,
        category = "tous",
        active = true
    }
end

local function setBlipPosition()
    local pos = getCurrentPlayerPosition()
    if pos then
        currentAmmunitionBuild.position = pos
        validateAmmunitionBuild()
        return true
    end
    return false
end

local function setNpcPosition()
    local pos = getCurrentPlayerPosition()
    if pos then
        currentAmmunitionBuild.npcPosition = pos
        validateAmmunitionBuild()
        return true
    end
    return false
end

local function finalizeAmmunitionCreation()
    if not validateAmmunitionBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
        return false
    end

    local shopData = {
        name = currentAmmunitionBuild.name,
        pos = currentAmmunitionBuild.position or currentAmmunitionBuild.npcPosition,
        npcPos = currentAmmunitionBuild.npcPosition,
        blipEnabled = currentAmmunitionBuild.blipEnabled,
        active = true
    }

    TriggerServerEvent('core:ammunition:createAmmunition', shopData)
    resetAmmunitionBuild()
    return true
end

local function finalizeItemCreation()
    if not validateItemBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration d'article n'est pas valide."})
        return false
    end

    TriggerServerEvent('core:ammunition:addGlobalItem', currentItemBuild.item_name, currentItemBuild.price, currentItemBuild.category)
    resetItemBuild()
    return true
end

function StaffMenu.BuildGunshopsMenu()
    if not StaffMenu or not StaffMenu.builderGunshops then
        return
    end

    StaffMenu.builderGunshops.Button(':plus: CRÉER UNE ARMURERIE', 'Créer une nouvelle armurerie',
            nil, 'chevron', false, function()
                resetAmmunitionBuild()
            end, StaffMenu.builderGunshopCreate)

    StaffMenu.builderGunshops.Button(':report: GÉRER LES ARMURERIES', 'Voir et gérer les armureries existantes',
            nil, 'chevron', false, function()
                local shops = TriggerServerCallback('core:ammunition:getAmmunitions')
                StaffMenu.currentGunshops = shops or {}
            end, StaffMenu.builderGunshopManage)

    StaffMenu.builderGunshops.Button(':gun: GÉRER LES ARTICLES', 'Gérer le catalogue global d\'articles',
            nil, 'chevron', false, function()
                local items = TriggerServerCallback('core:ammunition:getGlobalItemsForBuilder')
                StaffMenu.currentGunshopItems = items or {}
            end, StaffMenu.builderGunshopItems)
end

function StaffMenu.BuildCreateGunshopMenu()
    if not StaffMenu or not StaffMenu.builderGunshopCreate then
        return
    end

    StaffMenu.builderGunshopCreate.Button(":edit: NOM: " .. (currentAmmunitionBuild.name ~= "" and currentAmmunitionBuild.name or "NON DÉFINI"),
            "Définir le nom de l'armurerie", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Nom de l'armurerie", currentAmmunitionBuild.name)
                if result and result ~= "" then
                    currentAmmunitionBuild.name = result
                    validateAmmunitionBuild()
                    if StaffMenu.builderGunshopCreate.refresh then
                        StaffMenu.builderGunshopCreate.refresh()
                    end
                end
            end)

    local blipPositionText = currentAmmunitionBuild.position and
            string.format("X: %.2f Y: %.2f Z: %.2f", currentAmmunitionBuild.position.x,
                    currentAmmunitionBuild.position.y, currentAmmunitionBuild.position.z) or "NON DÉFINI"

   StaffMenu.builderGunshopCreate.Button(":pin: POSITION BLIP: " .. blipPositionText,
            "Définir la position du blip sur la carte", nil, "arrow", false,
            function()
                if setBlipPosition() then
                    if StaffMenu.builderGunshopCreate.refresh then
                        StaffMenu.builderGunshopCreate.refresh()
                    end
                    startMarkerThread()
                end
            end)

    local npcPositionText = currentAmmunitionBuild.npcPosition and
            string.format("X: %.2f Y: %.2f Z: %.2f", currentAmmunitionBuild.npcPosition.x,
                    currentAmmunitionBuild.npcPosition.y, currentAmmunitionBuild.npcPosition.z) or "NON DÉFINI"

   StaffMenu.builderGunshopCreate.Button(":user: POSITION VENDEUR: " .. npcPositionText,
            "Définir la position du vendeur (NPC)", nil, "arrow", false,
            function()
                if setNpcPosition() then
                    if StaffMenu.builderGunshopCreate.refresh then
                        StaffMenu.builderGunshopCreate.refresh()
                    end
                    startMarkerThread()
                end
            end)

    StaffMenu.builderGunshopCreate.Button(":pin: BLIP: " .. (currentAmmunitionBuild.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
            "Activer ou désactiver le blip sur la carte", nil, "arrow", false,
            function()
                currentAmmunitionBuild.blipEnabled = not currentAmmunitionBuild.blipEnabled
                if StaffMenu.builderGunshopCreate.refresh then
                    StaffMenu.builderGunshopCreate.refresh()
                end
            end)

    StaffMenu.builderGunshopCreate.Separator(nil)

    local statusMessage = ""
   if not currentAmmunitionBuild.name or currentAmmunitionBuild.name == "" then
        statusMessage = "Nom de l'armurerie requis"
   elseif not currentAmmunitionBuild.npcPosition then
        statusMessage = "Position du vendeur requise"
   else
        statusMessage = "Configuration terminée"
   end

    StaffMenu.builderGunshopCreate.Button(":check: CRÉER L'ARMURERIE", statusMessage,
            nil, "chevron", not currentAmmunitionBuild.isValid,
            function()
                if finalizeAmmunitionCreation() and StaffMenu.builderGunshopCreate.close then
                    StaffMenu.builderGunshopCreate.close()
                end
            end)
end

function StaffMenu.BuildManageGunshopsMenu()
    if not StaffMenu or not StaffMenu.builderGunshopManage then
        return
    end

    local shops = StaffMenu.currentGunshops or {}
    local hasShops = #shops > 0

    local separatorText = hasShops and 'ARMURERIES EXISTANTES' or 'AUCUNE ARMURERIE'
    StaffMenu.builderGunshopManage.Separator(separatorText)

    if hasShops then
        for _, shopData in ipairs(shops) do
            if shopData and shopData.name then
                local posText = shopData.pos and string.format("X: %.0f Y: %.0f Z: %.0f",
                        shopData.pos.x, shopData.pos.y, shopData.pos.z) or "Position inconnue"

               StaffMenu.builderGunshopManage.Button(":gun: " .. shopData.name .. " #" .. shopData.id,
                        posText, nil, 'chevron', false,
                        function()
                            StaffMenu.currentGunshopId = shopData.id
                            StaffMenu.currentGunshopData = shopData
                        end, StaffMenu.builderGunshopEdit)
            end
        end
    end
end

function StaffMenu.BuildEditGunshopMenu()
    if not StaffMenu or not StaffMenu.builderGunshopEdit then
        return
    end

    local shopId = StaffMenu.currentGunshopId
    local shopData = StaffMenu.currentGunshopData

    if not shopId or not shopData then
        return
    end

    StaffMenu.builderGunshopEdit.Separator("ARMURERIE #" .. shopId)
    StaffMenu.builderGunshopEdit.Button(":gun: NOM: " .. shopData.name,
            "Nom de l'armurerie", nil, "check", true, function() end)

    local blipPosText = shopData.pos and string.format("X: %.2f Y: %.2f Z: %.2f",
            shopData.pos.x, shopData.pos.y, shopData.pos.z) or "NON DÉFINI"

   StaffMenu.builderGunshopEdit.Button(":pin: POSITION BLIP: " .. blipPosText,
            "Modifier la position du blip", nil, "arrow", false,
            function()
                local pos = getCurrentPlayerPosition()
                if pos then
                    TriggerServerEvent('core:ammunition:updateAmmunition', shopId, 'pos', pos)
                    shopData.pos = pos
                    if StaffMenu.builderGunshopEdit.refresh then
                        StaffMenu.builderGunshopEdit.refresh()
                    end
                end
            end)

    local npcPosText = shopData.npcPos and string.format("X: %.2f Y: %.2f Z: %.2f",
            shopData.npcPos.x, shopData.npcPos.y, shopData.npcPos.z) or "NON DÉFINI"

   StaffMenu.builderGunshopEdit.Button(":user: POSITION VENDEUR: " .. npcPosText,
            "Modifier la position du vendeur", nil, "arrow", false,
            function()
                local pos = getCurrentPlayerPosition()
                if pos then
                    TriggerServerEvent('core:ammunition:updateAmmunition', shopId, 'npcPos', pos)
                    shopData.npcPos = pos
                    if StaffMenu.builderGunshopEdit.refresh then
                        StaffMenu.builderGunshopEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderGunshopEdit.Button(":check: ACTIVE: " .. (shopData.active and "OUI" or "NON"),
            "Activer ou désactiver l'armurerie", nil, "arrow", false,
            function()
                local newValue = not shopData.active
                TriggerServerEvent('core:ammunition:updateAmmunition', shopId, 'active', newValue)
                shopData.active = newValue
                if StaffMenu.builderGunshopEdit.refresh then
                    StaffMenu.builderGunshopEdit.refresh()
                end
            end)

    StaffMenu.builderGunshopEdit.Button(":pin: BLIP: " .. (shopData.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
            "Activer ou désactiver le blip", nil, "arrow", false,
            function()
                local newValue = not shopData.blipEnabled
                TriggerServerEvent('core:ammunition:updateAmmunition', shopId, 'blipEnabled', newValue)
                shopData.blipEnabled = newValue
                if StaffMenu.builderGunshopEdit.refresh then
                    StaffMenu.builderGunshopEdit.refresh()
                end
            end)

    StaffMenu.builderGunshopEdit.Separator("ACTIONS")

    StaffMenu.builderGunshopEdit.Button(":pin: TÉLÉPORTER AU VENDEUR",
            "Se téléporter à la position du vendeur", nil, "arrow", false,
            function()
                local npcPos = shopData.npcPos or shopData.pos
                if npcPos then
                    SetEntityCoords(PlayerPedId(), npcPos.x, npcPos.y, npcPos.z, false, false, false, true)
                end
            end)

    StaffMenu.builderGunshopEdit.Button(":trash: SUPPRIMER L'ARMURERIE",
            "Supprimer définitivement cette armurerie", nil, "chevron", false,
            function()
                TriggerServerEvent('core:ammunition:deleteAmmunition', shopId)
                if StaffMenu.builderGunshopEdit.close then
                    StaffMenu.builderGunshopEdit.close()
                end
                local shops = TriggerServerCallback('core:ammunition:getAmmunitions')
                StaffMenu.currentGunshops = shops or {}
            end)
end

function StaffMenu.BuildGunshopItemsMenu()
    if not StaffMenu or not StaffMenu.builderGunshopItems then
        return
    end

    StaffMenu.builderGunshopItems.Button(':plus: AJOUTER UN ARTICLE', 'Ajouter un nouvel article au catalogue',
            nil, 'chevron', false, function()
                resetItemBuild()
            end, StaffMenu.builderGunshopItemCreate)

    local items = StaffMenu.currentGunshopItems or {}
    local hasItems = #items > 0

    local separatorText = hasItems and 'ARTICLES EXISTANTS' or 'AUCUN ARTICLE'
    StaffMenu.builderGunshopItems.Separator(separatorText)

    if hasItems then
        for _, item in ipairs(items) do
            if item then
                local categoryLabel = getCategoryLabel(item.category)
                local priceText = string.format("%s | %s", VFW.Math.FormatMoney(item.price), categoryLabel)
                local itemLabel = item.label or item.name

                StaffMenu.builderGunshopItems.Button(":gun: " .. itemLabel,
                        priceText, nil, 'chevron', false,
                        function()
                            StaffMenu.currentGunshopItemId = item.id
                            StaffMenu.currentGunshopItemData = item
                        end, StaffMenu.builderGunshopItemEdit)
            end
        end
    end
end

function StaffMenu.BuildGunshopItemCreateMenu()
    if not StaffMenu or not StaffMenu.builderGunshopItemCreate then
        return
    end

    local itemLabel = currentItemBuild.item_name ~= "" and (VFW.Items[currentItemBuild.item_name] and VFW.Items[currentItemBuild.item_name].label or currentItemBuild.item_name) or "NON DÉFINI"

   StaffMenu.builderGunshopItemCreate.Button(":edit: ITEM: " .. itemLabel,
            "Nom technique de l'item", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Nom de l'item", currentItemBuild.item_name)
                if result and result ~= "" then
                    currentItemBuild.item_name = result
                    if StaffMenu.builderGunshopItemCreate.refresh then
                        StaffMenu.builderGunshopItemCreate.refresh()
                    end
                end
            end)

    StaffMenu.builderGunshopItemCreate.Button(":money: PRIX: " .. VFW.Math.FormatMoney(currentItemBuild.price),
            "Définir le prix de l'article", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Prix", tostring(currentItemBuild.price))
                if result and result ~= "" then
                    currentItemBuild.price = tonumber(result) or 0
                    if StaffMenu.builderGunshopItemCreate.refresh then
                        StaffMenu.builderGunshopItemCreate.refresh()
                    end
                end
            end)

    local categoryLabels = {}
    for _, cat in ipairs(AMMUNITION_CATEGORIES) do
        table.insert(categoryLabels, cat.label)
    end

    local currentIndex = 1
    for i, cat in ipairs(AMMUNITION_CATEGORIES) do
        if cat.value == currentItemBuild.category then
            currentIndex = i
            break
        end
    end

    StaffMenu.builderGunshopItemCreate.List("CATÉGORIE",
            "Sélectionner la catégorie de l'article", false, categoryLabels, currentIndex,
            function(index, item)
                currentItemBuild.category = AMMUNITION_CATEGORIES[index].value
                if StaffMenu.builderGunshopItemCreate.refresh then
                    StaffMenu.builderGunshopItemCreate.refresh()
                end
            end)

    StaffMenu.builderGunshopItemCreate.Separator(nil)

    local statusMessage = ""
   if not currentItemBuild.item_name or currentItemBuild.item_name == "" then
        statusMessage = "Nom de l'article requis"
   elseif currentItemBuild.price <= 0 then
        statusMessage = "Prix valide requis"
   else
        statusMessage = "Configuration terminée"
   end

    StaffMenu.builderGunshopItemCreate.Button(":check: AJOUTER L'ARTICLE", statusMessage,
            nil, "chevron", not validateItemBuild(),
            function()
                if finalizeItemCreation() then
                    local items = TriggerServerCallback('core:ammunition:getGlobalItemsForBuilder')
                    StaffMenu.currentGunshopItems = items or {}
                    if StaffMenu.builderGunshopItemCreate.close then
                        StaffMenu.builderGunshopItemCreate.close()
                    end
                    if StaffMenu.builderGunshopItems and StaffMenu.builderGunshopItems.open then
                        StaffMenu.builderGunshopItems.open()
                    end
                end
            end)
end

function StaffMenu.BuildEditItemMenu()
    if not StaffMenu or not StaffMenu.builderGunshopItemEdit then
        return
    end

    local itemId = StaffMenu.currentGunshopItemId
    local itemData = StaffMenu.currentGunshopItemData

    if not itemId or not itemData then
        return
    end

    local itemLabel = itemData.label or itemData.name

    StaffMenu.builderGunshopItemEdit.Separator("ARTICLE #" .. itemId)
    StaffMenu.builderGunshopItemEdit.Button(":gun: NOM: " .. itemLabel,
            itemData.name, nil, "check", true, function() end)

    StaffMenu.builderGunshopItemEdit.Button(":money: PRIX: " .. VFW.Math.FormatMoney(itemData.price),
            "Modifier le prix de l'article", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Prix", tostring(itemData.price))
                if result and result ~= "" then
                    local newPrice = tonumber(result) or itemData.price
                    TriggerServerEvent('core:ammunition:updateGlobalItem', itemData.name, newPrice, itemData.category, itemData.description)
                    itemData.price = newPrice
                    if StaffMenu.builderGunshopItemEdit.refresh then
                        StaffMenu.builderGunshopItemEdit.refresh()
                    end
                end
            end)

    local categoryLabel = getCategoryLabel(itemData.category)
    StaffMenu.builderGunshopItemEdit.Button(":folder: CATÉGORIE: " .. categoryLabel,
            "Catégorie de l'article", nil, "check", true, function() end)

    StaffMenu.builderGunshopItemEdit.Separator("ACTIONS")

    StaffMenu.builderGunshopItemEdit.Button(":trash: SUPPRIMER L'ARTICLE",
            "Supprimer définitivement cet article", nil, "chevron", false,
            function()
                TriggerServerEvent('core:ammunition:removeGlobalItem', itemData.name)
                local items = TriggerServerCallback('core:ammunition:getGlobalItemsForBuilder')
                StaffMenu.currentGunshopItems = items or {}
                if StaffMenu.builderGunshopItemEdit.close then
                    StaffMenu.builderGunshopItemEdit.close()
                end
                if StaffMenu.builderGunshopItems and StaffMenu.builderGunshopItems.open then
                    StaffMenu.builderGunshopItems.open()
                end
            end)
end

if StaffMenu and StaffMenu.builderGunshops and StaffMenu.builderGunshops.OnOpen then
    StaffMenu.builderGunshops.OnOpen(function()
        StaffMenu.BuildGunshopsMenu()
    end)
end

if StaffMenu and StaffMenu.builderGunshopCreate then
    if StaffMenu.builderGunshopCreate.OnOpen then
        StaffMenu.builderGunshopCreate.OnOpen(function()
            StaffMenu.BuildCreateGunshopMenu()
            if currentAmmunitionBuild.position then
                startMarkerThread()
            end
        end)
    end

    if StaffMenu.builderGunshopCreate.OnClose then
        StaffMenu.builderGunshopCreate.OnClose(function()
            stopMarkerThread()
        end)
    end
end

if StaffMenu and StaffMenu.builderGunshopManage and StaffMenu.builderGunshopManage.OnOpen then
    StaffMenu.builderGunshopManage.OnOpen(function()
        local shops = TriggerServerCallback('core:ammunition:getAmmunitions')
        StaffMenu.currentGunshops = shops or {}
        StaffMenu.BuildManageGunshopsMenu()
    end)
end

if StaffMenu and StaffMenu.builderGunshopEdit and StaffMenu.builderGunshopEdit.OnOpen then
    StaffMenu.builderGunshopEdit.OnOpen(function()
        StaffMenu.BuildEditGunshopMenu()
    end)
end

if StaffMenu and StaffMenu.builderGunshopItems and StaffMenu.builderGunshopItems.OnOpen then
    StaffMenu.builderGunshopItems.OnOpen(function()
        local items = TriggerServerCallback('core:ammunition:getGlobalItemsForBuilder')
        StaffMenu.currentGunshopItems = items or {}
        StaffMenu.BuildGunshopItemsMenu()
    end)
end

if StaffMenu and StaffMenu.builderGunshopItemCreate and StaffMenu.builderGunshopItemCreate.OnOpen then
    StaffMenu.builderGunshopItemCreate.OnOpen(function()
        StaffMenu.BuildGunshopItemCreateMenu()
    end)
end

if StaffMenu and StaffMenu.builderGunshopItemEdit and StaffMenu.builderGunshopItemEdit.OnOpen then
    StaffMenu.builderGunshopItemEdit.OnOpen(function()
        StaffMenu.BuildEditItemMenu()
    end)
end
