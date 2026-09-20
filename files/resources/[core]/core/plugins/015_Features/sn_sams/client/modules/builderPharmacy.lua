-- Pharmacy Builder for Staff Menu

local currentPharmacyBuild = {
    name = "",
    position = nil,
    npcPosition = nil,
    blipEnabled = true,
    isValid = false
}

local currentPharmacyItemBuild = {
    item_name = "",
    price = 0,
    isSamsItem = false
}

local markerThread = nil
local isMarkersActive = false

local function validatePharmacyBuild()
    currentPharmacyBuild.isValid = currentPharmacyBuild.name ~= "" and
            currentPharmacyBuild.npcPosition ~= nil
    return currentPharmacyBuild.isValid
end

local function validateItemBuild()
    return currentPharmacyItemBuild.item_name ~= "" and
            currentPharmacyItemBuild.price > 0
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
    if isMarkersActive then
        isMarkersActive = false
        markerThread = nil
    end
end

local function startMarkerThread()
    if isMarkersActive then
        return
    end

    isMarkersActive = true
    markerThread = CreateThread(function()
        while isMarkersActive do
            if currentPharmacyBuild.position then
                local blipPos = currentPharmacyBuild.position
                local coords = vector3(blipPos.x, blipPos.y, blipPos.z)

                DrawMarker(
                    1,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.5, 1.5, 1.0,
                    0, 150, 255, 150,
                    false, true, 2, false, nil, nil, false
                )

                local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(0, 150, 255, 215)
                    SetTextCentre(true)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("BLIP")
                    DrawText(screenX, screenY)
                end
            end

            if currentPharmacyBuild.npcPosition then
                local npcPos = currentPharmacyBuild.npcPosition
                local coords = vector3(npcPos.x, npcPos.y, npcPos.z)

                DrawMarker(
                    27,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    0, 150, 255, 150,
                    false, true, 2, false, nil, nil, false
                )

                local text = "PHARMACIEN\n" .. currentPharmacyBuild.name

                local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.4, 0.4)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(0, 150, 255, 215)
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

local function resetPharmacyBuild()
    stopMarkerThread()
    currentPharmacyBuild = {
        name = "",
        position = nil,
        npcPosition = nil,
        blipEnabled = true,
        isValid = false
    }
end

local function resetItemBuild()
    currentPharmacyItemBuild = {
        item_name = "",
        price = 0,
        isSamsItem = false
    }
end

local function setBlipPosition()
    local pos = getCurrentPlayerPosition()
    if pos then
        currentPharmacyBuild.position = pos
        validatePharmacyBuild()
        return true
    end
    return false
end

local function setNpcPosition()
    local pos = getCurrentPlayerPosition()
    if pos then
        currentPharmacyBuild.npcPosition = pos
        validatePharmacyBuild()
        return true
    end
    return false
end

local function finalizePharmacyCreation()
    if not validatePharmacyBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
        return false
    end

    local shopData = {
        name = currentPharmacyBuild.name,
        pos = currentPharmacyBuild.position or currentPharmacyBuild.npcPosition,
        npcPos = currentPharmacyBuild.npcPosition,
        blipEnabled = currentPharmacyBuild.blipEnabled,
        active = true
    }

    TriggerServerEvent('sn_sams:pharmacy:create', shopData)
    resetPharmacyBuild()
    return true
end

local function finalizeItemCreation()
    if not validateItemBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration d'article n'est pas valide."})
        return false
    end

    TriggerServerEvent('sn_sams:pharmacy:addItem', currentPharmacyItemBuild.item_name, currentPharmacyItemBuild.price, currentPharmacyItemBuild.isSamsItem)
    resetItemBuild()
    return true
end

function StaffMenu.BuildPharmaciesMenu()
    if not StaffMenu or not StaffMenu.builderPharmacy then
        return
    end

    StaffMenu.builderPharmacy.Button(':plus: CRÉER UNE PHARMACIE', 'Créer une nouvelle pharmacie',
            nil, 'chevron', false, function()
                resetPharmacyBuild()
            end, StaffMenu.builderPharmacyCreate)

    StaffMenu.builderPharmacy.Button(':report: GÉRER LES PHARMACIES', 'Voir et gérer les pharmacies existantes',
            nil, 'chevron', false, function()
                local shops = TriggerServerCallback('sn_sams:pharmacy:getPharmacies')
                StaffMenu.currentPharmacies = shops or {}
            end, StaffMenu.builderPharmacyManage)

    StaffMenu.builderPharmacy.Button(':flask: GÉRER LES ARTICLES', 'Gérer le catalogue des articles',
            nil, 'chevron', false, function()
                local items = TriggerServerCallback('sn_sams:pharmacy:getItems')
                StaffMenu.currentPharmacyItems = items or {}
            end, StaffMenu.builderPharmacyItems)
end

function StaffMenu.BuildCreatePharmacyMenu()
    if not StaffMenu or not StaffMenu.builderPharmacyCreate then
        return
    end

    StaffMenu.builderPharmacyCreate.Button(":edit: NOM: " .. (currentPharmacyBuild.name ~= "" and currentPharmacyBuild.name or "NON DÉFINI"),
            "Définir le nom de la pharmacie", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Nom de la pharmacie", currentPharmacyBuild.name)
                if result and result ~= "" then
                    currentPharmacyBuild.name = result
                    validatePharmacyBuild()
                    if StaffMenu.builderPharmacyCreate.refresh then
                        StaffMenu.builderPharmacyCreate.refresh()
                    end
                end
            end)

    local blipPositionText = currentPharmacyBuild.position and
            string.format("X: %.2f Y: %.2f Z: %.2f", currentPharmacyBuild.position.x,
                    currentPharmacyBuild.position.y, currentPharmacyBuild.position.z) or "NON DÉFINI"

   StaffMenu.builderPharmacyCreate.Button(":pin: POSITION BLIP: " .. blipPositionText,
            "Définir la position du blip sur la carte", nil, "arrow", false,
            function()
                if setBlipPosition() then
                    if StaffMenu.builderPharmacyCreate.refresh then
                        StaffMenu.builderPharmacyCreate.refresh()
                    end
                    startMarkerThread()
                end
            end)

    local npcPositionText = currentPharmacyBuild.npcPosition and
            string.format("X: %.2f Y: %.2f Z: %.2f", currentPharmacyBuild.npcPosition.x,
                    currentPharmacyBuild.npcPosition.y, currentPharmacyBuild.npcPosition.z) or "NON DÉFINI"

   StaffMenu.builderPharmacyCreate.Button(":user: POSITION PHARMACIEN: " .. npcPositionText,
            "Définir la position du pharmacien (NPC)", nil, "arrow", false,
            function()
                if setNpcPosition() then
                    if StaffMenu.builderPharmacyCreate.refresh then
                        StaffMenu.builderPharmacyCreate.refresh()
                    end
                    startMarkerThread()
                end
            end)

    StaffMenu.builderPharmacyCreate.Checkbox(
            "Blip sur la carte",
            "Afficher un blip sur la carte pour cette pharmacie",
            false,
            currentPharmacyBuild.blipEnabled,
            function(checked)
                currentPharmacyBuild.blipEnabled = checked
                if StaffMenu.builderPharmacyCreate.refresh then
                    StaffMenu.builderPharmacyCreate.refresh()
                end
            end)

    StaffMenu.builderPharmacyCreate.Separator(nil)

    local statusMessage = ""
   if not currentPharmacyBuild.name or currentPharmacyBuild.name == "" then
        statusMessage = "Nom de la pharmacie requis"
   elseif not currentPharmacyBuild.npcPosition then
        statusMessage = "Position du pharmacien requise"
   else
        statusMessage = "Configuration terminée"
   end

    StaffMenu.builderPharmacyCreate.Button(":check: CRÉER LA PHARMACIE", statusMessage,
            nil, "chevron", not currentPharmacyBuild.isValid,
            function()
                if finalizePharmacyCreation() and StaffMenu.builderPharmacyCreate.close then
                    StaffMenu.builderPharmacyCreate.close()
                end
            end)
end

function StaffMenu.BuildManagePharmaciesMenu()
    if not StaffMenu or not StaffMenu.builderPharmacyManage then
        return
    end

    local shops = StaffMenu.currentPharmacies or {}
    local hasShops = #shops > 0

    local separatorText = hasShops and 'PHARMACIES EXISTANTES' or 'AUCUNE PHARMACIE'
    StaffMenu.builderPharmacyManage.Separator(separatorText)

    if hasShops then
        for _, shopData in ipairs(shops) do
            if shopData and shopData.name then
                local posText = shopData.pos and string.format("X: %.0f Y: %.0f Z: %.0f",
                        shopData.pos.x, shopData.pos.y, shopData.pos.z) or "Position inconnue"

               StaffMenu.builderPharmacyManage.Button(":flask: " .. shopData.name .. " #" .. shopData.id,
                        posText, nil, 'chevron', false,
                        function()
                            StaffMenu.currentPharmacyId = shopData.id
                            StaffMenu.currentPharmacyData = shopData
                        end, StaffMenu.builderPharmacyEdit)
            end
        end
    end
end

function StaffMenu.BuildEditPharmacyMenu()
    if not StaffMenu or not StaffMenu.builderPharmacyEdit then
        return
    end

    local shopId = StaffMenu.currentPharmacyId
    local shopData = StaffMenu.currentPharmacyData

    if not shopId or not shopData then
        return
    end

    StaffMenu.builderPharmacyEdit.Separator("PHARMACIE #" .. shopId)
    StaffMenu.builderPharmacyEdit.Button(":flask: NOM: " .. shopData.name,
            "Nom de la pharmacie", nil, "check", true, function() end)

    local blipPosText = shopData.pos and string.format("X: %.2f Y: %.2f Z: %.2f",
            shopData.pos.x, shopData.pos.y, shopData.pos.z) or "NON DÉFINI"

   StaffMenu.builderPharmacyEdit.Button(":pin: POSITION BLIP: " .. blipPosText,
            "Modifier la position du blip", nil, "arrow", false,
            function()
                local pos = getCurrentPlayerPosition()
                if pos then
                    TriggerServerEvent('sn_sams:pharmacy:update', shopId, 'pos', pos)
                    shopData.pos = pos
                    if StaffMenu.builderPharmacyEdit.refresh then
                        StaffMenu.builderPharmacyEdit.refresh()
                    end
                end
            end)

    local npcPosText = shopData.npcPos and string.format("X: %.2f Y: %.2f Z: %.2f",
            shopData.npcPos.x, shopData.npcPos.y, shopData.npcPos.z) or "NON DÉFINI"

   StaffMenu.builderPharmacyEdit.Button(":user: POSITION PHARMACIEN: " .. npcPosText,
            "Modifier la position du pharmacien", nil, "arrow", false,
            function()
                local pos = getCurrentPlayerPosition()
                if pos then
                    TriggerServerEvent('sn_sams:pharmacy:update', shopId, 'npcPos', pos)
                    shopData.npcPos = pos
                    if StaffMenu.builderPharmacyEdit.refresh then
                        StaffMenu.builderPharmacyEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderPharmacyEdit.Checkbox(
            "Pharmacie active",
            "Activer ou désactiver la pharmacie",
            false,
            shopData.active,
            function(checked)
                TriggerServerEvent('sn_sams:pharmacy:update', shopId, 'active', checked)
                shopData.active = checked
                if StaffMenu.builderPharmacyEdit.refresh then
                    StaffMenu.builderPharmacyEdit.refresh()
                end
            end)

    StaffMenu.builderPharmacyEdit.Checkbox(
            "Blip sur la carte",
            "Afficher un blip sur la carte pour cette pharmacie",
            false,
            shopData.blipEnabled,
            function(checked)
                TriggerServerEvent('sn_sams:pharmacy:update', shopId, 'blipEnabled', checked)
                shopData.blipEnabled = checked
                if StaffMenu.builderPharmacyEdit.refresh then
                    StaffMenu.builderPharmacyEdit.refresh()
                end
            end)

    StaffMenu.builderPharmacyEdit.Separator("ACTIONS")

    StaffMenu.builderPharmacyEdit.Button(":pin: TÉLÉPORTER AU PHARMACIEN",
            "Se téléporter à la position du pharmacien", nil, "arrow", false,
            function()
                local npcPos = shopData.npcPos or shopData.pos
                if npcPos then
                    SetEntityCoords(PlayerPedId(), npcPos.x, npcPos.y, npcPos.z, false, false, false, true)
                end
            end)

    StaffMenu.builderPharmacyEdit.Button(":trash: SUPPRIMER LA PHARMACIE",
            "Supprimer définitivement cette pharmacie", nil, "chevron", false,
            function()
                TriggerServerEvent('sn_sams:pharmacy:delete', shopId)
                if StaffMenu.builderPharmacyEdit.close then
                    StaffMenu.builderPharmacyEdit.close()
                end
                local shops = TriggerServerCallback('sn_sams:pharmacy:getPharmacies')
                StaffMenu.currentPharmacies = shops or {}
            end)
end

function StaffMenu.BuildPharmacyItemsMenu()
    if not StaffMenu or not StaffMenu.builderPharmacyItems then
        return
    end

    StaffMenu.builderPharmacyItems.Button(':plus: AJOUTER UN ARTICLE', 'Ajouter un nouvel article au catalogue',
            nil, 'chevron', false, function()
                resetItemBuild()
            end, StaffMenu.builderPharmacyItemCreate)

    local items = StaffMenu.currentPharmacyItems or {}
    local hasItems = #items > 0

    local separatorText = hasItems and 'ARTICLES EXISTANTS' or 'AUCUN ARTICLE'
    StaffMenu.builderPharmacyItems.Separator(separatorText)

    if hasItems then
        for _, item in ipairs(items) do
            if item then
                local priceText = VFW.Math.FormatMoney(item.price)
                local itemLabel = item.label or item.name

                StaffMenu.builderPharmacyItems.Button(":flask: " .. itemLabel,
                        priceText, nil, 'chevron', false,
                        function()
                            StaffMenu.currentPharmacyItemId = item.id
                            StaffMenu.currentPharmacyItemData = item
                        end, StaffMenu.builderPharmacyItemEdit)
            end
        end
    end
end

function StaffMenu.BuildCreatePharmacyItemMenu()
    if not StaffMenu or not StaffMenu.builderPharmacyItemCreate then
        return
    end

    local itemLabel = currentPharmacyItemBuild.item_name ~= "" and (VFW.Items[currentPharmacyItemBuild.item_name] and VFW.Items[currentPharmacyItemBuild.item_name].label or currentPharmacyItemBuild.item_name) or "NON DÉFINI"

   StaffMenu.builderPharmacyItemCreate.Button(":edit: ITEM: " .. itemLabel,
            "Cliquez pour choisir un item dans la liste", nil, "chevron", false,
            function()
                StaffMenu.pharmacyItemSearchQuery = ""
           end, StaffMenu.builderPharmacyItemSelect)

    StaffMenu.builderPharmacyItemCreate.Button(":money: PRIX: " .. VFW.Math.FormatMoney(currentPharmacyItemBuild.price),
            "Définir le prix de l'article", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Prix", tostring(currentPharmacyItemBuild.price))
                if result and result ~= "" then
                    currentPharmacyItemBuild.price = tonumber(result) or 0
                    if StaffMenu.builderPharmacyItemCreate.refresh then
                        StaffMenu.builderPharmacyItemCreate.refresh()
                    end
                end
            end)

    StaffMenu.builderPharmacyItemCreate.Checkbox(
            "Item SAMS uniquement",
            "Réservé aux SAMS uniquement (invisible pour les civils)",
            false,
            currentPharmacyItemBuild.isSamsItem,
            function(checked)
                currentPharmacyItemBuild.isSamsItem = checked
                if StaffMenu.builderPharmacyItemCreate.refresh then
                    StaffMenu.builderPharmacyItemCreate.refresh()
                end
            end)

    StaffMenu.builderPharmacyItemCreate.Separator(nil)

    local statusMessage = ""
   if not currentPharmacyItemBuild.item_name or currentPharmacyItemBuild.item_name == "" then
        statusMessage = "Nom de l'article requis"
   elseif currentPharmacyItemBuild.price <= 0 then
        statusMessage = "Prix valide requis"
   else
        statusMessage = "Configuration terminée"
   end

    StaffMenu.builderPharmacyItemCreate.Button(":check: AJOUTER L'ARTICLE", statusMessage,
            nil, "chevron", not validateItemBuild(),
            function()
                if finalizeItemCreation() then
                    local items = TriggerServerCallback('sn_sams:pharmacy:getItems')
                    StaffMenu.currentPharmacyItems = items or {}
                    if StaffMenu.builderPharmacyItemCreate.close then
                        StaffMenu.builderPharmacyItemCreate.close()
                    end
                    if StaffMenu.builderPharmacyItems and StaffMenu.builderPharmacyItems.open then
                        StaffMenu.builderPharmacyItems.open()
                    end
                end
            end)
end

function StaffMenu.BuildEditPharmacyItemMenu()
    if not StaffMenu or not StaffMenu.builderPharmacyItemEdit then
        return
    end

    local itemId = StaffMenu.currentPharmacyItemId
    local itemData = StaffMenu.currentPharmacyItemData

    if not itemId or not itemData then
        return
    end

    local itemLabel = itemData.label or itemData.name

    StaffMenu.builderPharmacyItemEdit.Separator("ARTICLE #" .. itemId)
    StaffMenu.builderPharmacyItemEdit.Button(":flask: NOM: " .. itemLabel,
            itemData.name, nil, "check", true, function() end)

    StaffMenu.builderPharmacyItemEdit.Button(":money: PRIX: " .. VFW.Math.FormatMoney(itemData.price),
            "Modifier le prix de l'article", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Prix", tostring(itemData.price))
                if result and result ~= "" then
                    local newPrice = tonumber(result) or itemData.price
                    TriggerServerEvent('sn_sams:pharmacy:updateItem', itemData.name, newPrice, itemData.isSamsItem)
                    itemData.price = newPrice
                    if StaffMenu.builderPharmacyItemEdit.refresh then
                        StaffMenu.builderPharmacyItemEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderPharmacyItemEdit.Checkbox(
            "Item SAMS uniquement",
            "Réservé aux SAMS uniquement (invisible pour les civils)",
            false,
            itemData.isSamsItem,
            function(checked)
                local newValue = checked
                TriggerServerEvent('sn_sams:pharmacy:updateItem', itemData.name, itemData.price, newValue)
                itemData.isSamsItem = newValue
                if StaffMenu.builderPharmacyItemEdit.refresh then
                    StaffMenu.builderPharmacyItemEdit.refresh()
                end
            end)

    StaffMenu.builderPharmacyItemEdit.Separator("ACTIONS")

    StaffMenu.builderPharmacyItemEdit.Button(":trash: SUPPRIMER L'ARTICLE",
            "Supprimer définitivement cet article", nil, "chevron", false,
            function()
                TriggerServerEvent('sn_sams:pharmacy:removeItem', itemData.name)
                if StaffMenu.builderPharmacyItemEdit.close then
                    StaffMenu.builderPharmacyItemEdit.close()
                end
                local items = TriggerServerCallback('sn_sams:pharmacy:getItems')
                StaffMenu.currentPharmacyItems = items or {}
            end)
end

-- OnOpen hooks
if StaffMenu and StaffMenu.builderPharmacy and StaffMenu.builderPharmacy.OnOpen then
    StaffMenu.builderPharmacy.OnOpen(function()
        StaffMenu.BuildPharmaciesMenu()
    end)
end

if StaffMenu and StaffMenu.builderPharmacyCreate then
    if StaffMenu.builderPharmacyCreate.OnOpen then
        StaffMenu.builderPharmacyCreate.OnOpen(function()
            StaffMenu.BuildCreatePharmacyMenu()
            if currentPharmacyBuild.position then
                startMarkerThread()
            end
        end)
    end

    if StaffMenu.builderPharmacyCreate.OnClose then
        StaffMenu.builderPharmacyCreate.OnClose(function()
            stopMarkerThread()
        end)
    end
end

if StaffMenu and StaffMenu.builderPharmacyManage and StaffMenu.builderPharmacyManage.OnOpen then
    StaffMenu.builderPharmacyManage.OnOpen(function()
        local shops = TriggerServerCallback('sn_sams:pharmacy:getPharmacies')
        StaffMenu.currentPharmacies = shops or {}
        StaffMenu.BuildManagePharmaciesMenu()
    end)
end

if StaffMenu and StaffMenu.builderPharmacyEdit and StaffMenu.builderPharmacyEdit.OnOpen then
    StaffMenu.builderPharmacyEdit.OnOpen(function()
        StaffMenu.BuildEditPharmacyMenu()
    end)
end

if StaffMenu and StaffMenu.builderPharmacyItems and StaffMenu.builderPharmacyItems.OnOpen then
    StaffMenu.builderPharmacyItems.OnOpen(function()
        local items = TriggerServerCallback('sn_sams:pharmacy:getItems')
        StaffMenu.currentPharmacyItems = items or {}
        StaffMenu.BuildPharmacyItemsMenu()
    end)
end

if StaffMenu and StaffMenu.builderPharmacyItemCreate and StaffMenu.builderPharmacyItemCreate.OnOpen then
    StaffMenu.builderPharmacyItemCreate.OnOpen(function()
        StaffMenu.BuildCreatePharmacyItemMenu()
    end)
end

if StaffMenu and StaffMenu.builderPharmacyItemEdit and StaffMenu.builderPharmacyItemEdit.OnOpen then
    StaffMenu.builderPharmacyItemEdit.OnOpen(function()
        StaffMenu.BuildEditPharmacyItemMenu()
    end)
end

-- Item selection menu with search
StaffMenu.pharmacyItemSearchQuery = ""

function StaffMenu.BuildSelectPharmacyItemMenu()
    if not StaffMenu or not StaffMenu.builderPharmacyItemSelect then
        return
    end

    StaffMenu.builderPharmacyItemSelect.Button(":search: RECHERCHER: " .. (StaffMenu.pharmacyItemSearchQuery ~= "" and StaffMenu.pharmacyItemSearchQuery or "Tous les items"),
            "Tapez pour filtrer les items", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Rechercher un item...", StaffMenu.pharmacyItemSearchQuery)
                if result then
                    StaffMenu.pharmacyItemSearchQuery = result
                    if StaffMenu.builderPharmacyItemSelect.refresh then
                        StaffMenu.builderPharmacyItemSelect.refresh()
                    end
                end
            end)

    StaffMenu.builderPharmacyItemSelect.Separator("ITEMS DISPONIBLES")

    local query = StaffMenu.pharmacyItemSearchQuery:lower()
    local count = 0
    local maxItems = 50

    local sortedItems = {}
    for itemName, itemData in pairs(VFW.Items) do
        if itemData and itemData.label then
            table.insert(sortedItems, { name = itemName, label = itemData.label })
        end
    end
    table.sort(sortedItems, function(a, b) return a.label < b.label end)

    for _, item in ipairs(sortedItems) do
        if count >= maxItems then
            StaffMenu.builderPharmacyItemSelect.Separator("+" .. (#sortedItems - count) .. " items - Affinez votre recherche")
            break
        end

        local matchesSearch = query == "" or item.label:lower():find(query, 1, true) or item.name:lower():find(query, 1, true)

        if matchesSearch then
            count = count + 1
            StaffMenu.builderPharmacyItemSelect.Button(":flask: " .. item.label,
                    item.name, nil, "arrow", false,
                    function()
                        currentPharmacyItemBuild.item_name = item.name
                        if StaffMenu.builderPharmacyItemSelect.close then
                            StaffMenu.builderPharmacyItemSelect.close()
                        end
                        if StaffMenu.builderPharmacyItemCreate.refresh then
                            StaffMenu.builderPharmacyItemCreate.refresh()
                        end
                    end)
        end
    end

    if count == 0 then
        StaffMenu.builderPharmacyItemSelect.Separator("Aucun item trouvé")
    end
end

if StaffMenu and StaffMenu.builderPharmacyItemSelect and StaffMenu.builderPharmacyItemSelect.OnOpen then
    StaffMenu.builderPharmacyItemSelect.OnOpen(function()
        StaffMenu.BuildSelectPharmacyItemMenu()
    end)
end
