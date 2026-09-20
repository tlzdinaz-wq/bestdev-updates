-- Firework Shop Builder for Staff Menu

local currentFireworkBuild = {
    name = "",
    npcPosition = nil,
    npcModel = "mp_m_shopkeep_01",
    active = true,
    isValid = false
}

local currentFireworkItemBuild = {
    item_name = "",
    price = 0,
    category = "tous",
    stock = 0
}

local markerThread = nil
local isMarkersActive = false

local FIREWORK_CATEGORIES = {
    {value = "tous", label = "Tous"},
    {value = "boites", label = "Boîtes de Feux"},
    {value = "fusees", label = "Fusées"},
    {value = "petits", label = "Petits Feux"},
    {value = "moyens", label = "Feux Moyens"},
    {value = "grands", label = "Grands Feux"},
    {value = "eclats", label = "Éclats & Flares"},
    {value = "tapis", label = "Tapis de Feu"}
}

local function getCategoryLabel(category)
    for _, cat in ipairs(FIREWORK_CATEGORIES) do
        if cat.value == category then
            return cat.label
        end
    end
    return category
end

local function validateFireworkBuild()
    currentFireworkBuild.isValid = currentFireworkBuild.name ~= "" and
            currentFireworkBuild.npcPosition ~= nil
    return currentFireworkBuild.isValid
end

local function validateItemBuild()
    return currentFireworkItemBuild.item_name ~= "" and
            currentFireworkItemBuild.price > 0 and
            currentFireworkItemBuild.category ~= ""
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
            if currentFireworkBuild.npcPosition then
                local npcPos = currentFireworkBuild.npcPosition
                local coords = vector3(npcPos.x, npcPos.y, npcPos.z)

                DrawMarker(
                    27,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    255, 165, 0, 150,
                    false, true, 2, false, nil, nil, false
                )

                local text = "VENDEUR\n" .. currentFireworkBuild.name

                local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.4, 0.4)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 165, 0, 215)
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

local function resetFireworkBuild()
    stopMarkerThread()
    currentFireworkBuild = {
        name = "",
        npcPosition = nil,
        npcModel = "mp_m_shopkeep_01",
        active = true,
        isValid = false
    }
end

local function resetItemBuild()
    currentFireworkItemBuild = {
        item_name = "",
        price = 0,
        category = "tous",
        stock = 0
    }
end

local function setNpcPosition()
    local pos = getCurrentPlayerPosition()
    if pos then
        currentFireworkBuild.npcPosition = pos
        validateFireworkBuild()
        return true
    end
    return false
end

local function finalizeFireworkCreation()
    if not validateFireworkBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
        return false
    end

    local shopData = {
        name = currentFireworkBuild.name,
        pos = currentFireworkBuild.npcPosition,
        npcPos = currentFireworkBuild.npcPosition,
        npcModel = currentFireworkBuild.npcModel,
        active = currentFireworkBuild.active
    }

    TriggerServerEvent('core:firework:createShop', shopData)
    resetFireworkBuild()
    return true
end

local function finalizeItemCreation()
    if not validateItemBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration d'article n'est pas valide."})
        return false
    end

    TriggerServerEvent('core:firework:addGlobalItem', currentFireworkItemBuild.item_name, currentFireworkItemBuild.price, currentFireworkItemBuild.category, currentFireworkItemBuild.stock)
    resetItemBuild()
    return true
end

function StaffMenu.BuildFireworkBuilderMenu()
    if not StaffMenu or not StaffMenu.builderFirework then
        return
    end

    StaffMenu.builderFirework.Button(':plus: CRÉER UNE BOUTIQUE', 'Créer une nouvelle boutique de feux d\'artifice',
            nil, 'chevron', false, function()
                resetFireworkBuild()
            end, StaffMenu.builderFireworkCreate)

    StaffMenu.builderFirework.Button(':report: GÉRER LES BOUTIQUES', 'Voir et gérer les boutiques existantes',
            nil, 'chevron', false, function()
                local shops = TriggerServerCallback('core:firework:getShops')
                StaffMenu.currentFireworkShops = shops or {}
            end, StaffMenu.builderFireworkManage)

    StaffMenu.builderFirework.Button(':sparkles: GÉRER LES ARTICLES', 'Gérer le catalogue global d\'articles',
            nil, 'chevron', false, function()
                local items = TriggerServerCallback('core:firework:getGlobalItemsForBuilder')
                StaffMenu.currentFireworkItems = items or {}
            end, StaffMenu.builderFireworkItems)

    StaffMenu.builderFirework.Button(':settings: PARAMÈTRES ÉCONOMIE', 'Multiplicateur prix, limites d\'achats',
            nil, 'chevron', false, function()
            end, StaffMenu.builderFireworkSettings)

    StaffMenu.builderFirework.Separator("ACTIONS")

    StaffMenu.builderFirework.Button(':refresh: RECHARGER DEPUIS BDD', 'Recharge depuis la base de données',
            nil, 'arrow', false, function()
                TriggerServerEvent('core:firework:reloadFromDatabase')
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'INFO', subtitle = 'Builder',
                    message = "Rechargement en cours."
               })
            end)
end

function StaffMenu.BuildCreateFireworkShopMenu()
    if not StaffMenu or not StaffMenu.builderFireworkCreate then
        return
    end

    StaffMenu.builderFireworkCreate.Button(":edit: NOM: " .. (currentFireworkBuild.name ~= "" and currentFireworkBuild.name or "NON DÉFINI"),
            "Définir le nom de la boutique", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Nom de la boutique", currentFireworkBuild.name)
                if result and result ~= "" then
                    currentFireworkBuild.name = result
                    validateFireworkBuild()
                    if StaffMenu.builderFireworkCreate.refresh then
                        StaffMenu.builderFireworkCreate.refresh()
                    end
                end
            end)

    local npcPositionText = currentFireworkBuild.npcPosition and
            string.format("X: %.2f Y: %.2f Z: %.2f", currentFireworkBuild.npcPosition.x,
                    currentFireworkBuild.npcPosition.y, currentFireworkBuild.npcPosition.z) or "NON DÉFINI"

   StaffMenu.builderFireworkCreate.Button(":user: POSITION VENDEUR: " .. npcPositionText,
            "Définir la position du vendeur (NPC)", nil, "arrow", false,
            function()
                if setNpcPosition() then
                    if StaffMenu.builderFireworkCreate.refresh then
                        StaffMenu.builderFireworkCreate.refresh()
                    end
                    startMarkerThread()
                end
            end)

    StaffMenu.builderFireworkCreate.Button(":mask: MODÈLE PNJ: " .. currentFireworkBuild.npcModel,
            "Définir le modèle du PNJ vendeur", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Modèle du PNJ (ex: mp_m_shopkeep_01)", currentFireworkBuild.npcModel)
                if result and result ~= "" then
                    currentFireworkBuild.npcModel = result
                    if StaffMenu.builderFireworkCreate.refresh then
                        StaffMenu.builderFireworkCreate.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkCreate.Separator(nil)

    local statusMessage = ""
   if not currentFireworkBuild.name or currentFireworkBuild.name == "" then
        statusMessage = "Nom de la boutique requis"
   elseif not currentFireworkBuild.npcPosition then
        statusMessage = "Position du vendeur requise"
   else
        statusMessage = "Configuration terminée"
   end

    StaffMenu.builderFireworkCreate.Button(":check: CRÉER LA BOUTIQUE", statusMessage,
            nil, "chevron", not currentFireworkBuild.isValid,
            function()
                if finalizeFireworkCreation() and StaffMenu.builderFireworkCreate.close then
                    StaffMenu.builderFireworkCreate.close()
                end
            end)
end

function StaffMenu.BuildManageFireworkShopsMenu()
    if not StaffMenu or not StaffMenu.builderFireworkManage then
        return
    end

    local shops = StaffMenu.currentFireworkShops or {}
    local hasShops = #shops > 0

    local separatorText = hasShops and 'BOUTIQUES EXISTANTES' or 'AUCUNE BOUTIQUE'
    StaffMenu.builderFireworkManage.Separator(separatorText)

    if hasShops then
        for _, shopData in ipairs(shops) do
            if shopData and shopData.name then
                local posText = shopData.pos and string.format("X: %.0f Y: %.0f Z: %.0f",
                        shopData.pos.x, shopData.pos.y, shopData.pos.z) or "Position inconnue"

               StaffMenu.builderFireworkManage.Button(":sparkles: " .. shopData.name .. " #" .. shopData.id,
                        posText, nil, 'chevron', false,
                        function()
                            StaffMenu.currentFireworkShopId = shopData.id
                            StaffMenu.currentFireworkShopData = shopData
                        end, StaffMenu.builderFireworkEdit)
            end
        end
    end
end

function StaffMenu.BuildEditFireworkShopMenu()
    if not StaffMenu or not StaffMenu.builderFireworkEdit then
        return
    end

    local shopId = StaffMenu.currentFireworkShopId
    local shopData = StaffMenu.currentFireworkShopData

    if not shopId or not shopData then
        return
    end

    StaffMenu.builderFireworkEdit.Separator("BOUTIQUE #" .. shopId)
    StaffMenu.builderFireworkEdit.Button(":sparkles: NOM: " .. shopData.name,
            "Nom de la boutique", nil, "check", true, function() end)

    local npcPosText = shopData.npcPos and string.format("X: %.2f Y: %.2f Z: %.2f",
            shopData.npcPos.x, shopData.npcPos.y, shopData.npcPos.z) or "NON DÉFINI"

   StaffMenu.builderFireworkEdit.Button(":user: POSITION VENDEUR: " .. npcPosText,
            "Modifier la position du vendeur", nil, "arrow", false,
            function()
                local pos = getCurrentPlayerPosition()
                if pos then
                    TriggerServerEvent('core:firework:updateShop', shopId, 'npcPos', pos)
                    shopData.npcPos = pos
                    if StaffMenu.builderFireworkEdit.refresh then
                        StaffMenu.builderFireworkEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkEdit.Button(":mask: MODÈLE PNJ: " .. (shopData.npcModel or "mp_m_shopkeep_01"),
            "Modifier le modèle du PNJ", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Modèle du PNJ", shopData.npcModel or "mp_m_shopkeep_01")
                if result and result ~= "" then
                    TriggerServerEvent('core:firework:updateShop', shopId, 'npcModel', result)
                    shopData.npcModel = result
                    if StaffMenu.builderFireworkEdit.refresh then
                        StaffMenu.builderFireworkEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkEdit.Button(":check: ACTIVE: " .. (shopData.active and "OUI" or "NON"),
            "Activer ou désactiver la boutique", nil, "arrow", false,
            function()
                local newValue = not shopData.active
                TriggerServerEvent('core:firework:updateShop', shopId, 'active', newValue)
                shopData.active = newValue
                if StaffMenu.builderFireworkEdit.refresh then
                    StaffMenu.builderFireworkEdit.refresh()
                end
            end)

    StaffMenu.builderFireworkEdit.Separator("ACTIONS")

    StaffMenu.builderFireworkEdit.Button(":pin: TÉLÉPORTER AU VENDEUR",
            "Se téléporter à la position du vendeur", nil, "arrow", false,
            function()
                local npcPos = shopData.npcPos or shopData.pos
                if npcPos then
                    SetEntityCoords(PlayerPedId(), npcPos.x, npcPos.y, npcPos.z, false, false, false, true)
                end
            end)

    StaffMenu.builderFireworkEdit.Button(":trash: SUPPRIMER LA BOUTIQUE",
            "Supprimer définitivement cette boutique", nil, "chevron", false,
            function()
                TriggerServerEvent('core:firework:deleteShop', shopId)
                if StaffMenu.builderFireworkEdit.close then
                    StaffMenu.builderFireworkEdit.close()
                end
                local shops = TriggerServerCallback('core:firework:getShops')
                StaffMenu.currentFireworkShops = shops or {}
            end)
end

function StaffMenu.BuildFireworkItemsMenu()
    if not StaffMenu or not StaffMenu.builderFireworkItems then
        return
    end

    StaffMenu.builderFireworkItems.Button(':plus: AJOUTER UN ARTICLE', 'Ajouter un nouvel article au catalogue',
            nil, 'chevron', false, function()
                resetItemBuild()
            end, StaffMenu.builderFireworkItemCreate)

    local items = StaffMenu.currentFireworkItems or {}
    local hasItems = #items > 0

    local separatorText = hasItems and 'ARTICLES EXISTANTS' or 'AUCUN ARTICLE'
    StaffMenu.builderFireworkItems.Separator(separatorText)

    if hasItems then
        for _, item in ipairs(items) do
            if item then
                local categoryLabel = getCategoryLabel(item.category)
                local priceText = string.format("%s | Stock: %d | %s", VFW.Math.FormatMoney(item.price), item.stock or 0, categoryLabel)
                local itemLabel = item.label or item.name
                -- make sure we treat enabled field as boolean even if it came from the server as a string/number
                local enabled = item.enabled == true or item.enabled == 1
                local statusIcon = enabled and ":check:" or ":ban:"
               local statusText = enabled and "" or " (DÉSACTIVÉ)"

               StaffMenu.builderFireworkItems.Button(statusIcon .. " " .. itemLabel .. statusText,
                        priceText, nil, 'chevron', false,
                        function()
                            StaffMenu.currentFireworkItemId = item.id
                            StaffMenu.currentFireworkItemData = item
                        end, StaffMenu.builderFireworkItemEdit)
            end
        end
    end
end

function StaffMenu.BuildCreateFireworkItemMenu()
    if not StaffMenu or not StaffMenu.builderFireworkItemCreate then
        return
    end

    local itemLabel = currentFireworkItemBuild.item_name ~= "" and (VFW.Items[currentFireworkItemBuild.item_name] and VFW.Items[currentFireworkItemBuild.item_name].label or currentFireworkItemBuild.item_name) or "NON DÉFINI"

   StaffMenu.builderFireworkItemCreate.Button(":edit: ITEM: " .. itemLabel,
            "Nom technique de l'item", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Nom de l'item", currentFireworkItemBuild.item_name)
                if result and result ~= "" then
                    currentFireworkItemBuild.item_name = result
                    if StaffMenu.builderFireworkItemCreate.refresh then
                        StaffMenu.builderFireworkItemCreate.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkItemCreate.Button(":money: PRIX: " .. VFW.Math.FormatMoney(currentFireworkItemBuild.price),
            "Définir le prix de l'article", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Prix", tostring(currentFireworkItemBuild.price))
                if result and result ~= "" then
                    currentFireworkItemBuild.price = tonumber(result) or 0
                    if StaffMenu.builderFireworkItemCreate.refresh then
                        StaffMenu.builderFireworkItemCreate.refresh()
                    end
                end
            end)

    local categoryLabels = {}
    for _, cat in ipairs(FIREWORK_CATEGORIES) do
        table.insert(categoryLabels, cat.label)
    end

    local currentIndex = 1
    for i, cat in ipairs(FIREWORK_CATEGORIES) do
        if cat.value == currentFireworkItemBuild.category then
            currentIndex = i
            break
        end
    end

    StaffMenu.builderFireworkItemCreate.List("CATÉGORIE",
            "Sélectionner la catégorie de l'article", false, categoryLabels, currentIndex,
            function(index, item)
                currentFireworkItemBuild.category = FIREWORK_CATEGORIES[index].value
                if StaffMenu.builderFireworkItemCreate.refresh then
                    StaffMenu.builderFireworkItemCreate.refresh()
                end
            end)

    StaffMenu.builderFireworkItemCreate.Button(":box: STOCK INITIAL: " .. currentFireworkItemBuild.stock,
            "Définir le stock initial", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Stock initial", tostring(currentFireworkItemBuild.stock))
                if result and result ~= "" then
                    currentFireworkItemBuild.stock = tonumber(result) or 0
                    if StaffMenu.builderFireworkItemCreate.refresh then
                        StaffMenu.builderFireworkItemCreate.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkItemCreate.Separator(nil)

    local statusMessage = ""
   if not currentFireworkItemBuild.item_name or currentFireworkItemBuild.item_name == "" then
        statusMessage = "Nom de l'article requis"
   elseif currentFireworkItemBuild.price <= 0 then
        statusMessage = "Prix valide requis"
   else
        statusMessage = "Configuration terminée"
   end

    StaffMenu.builderFireworkItemCreate.Button(":check: AJOUTER L'ARTICLE", statusMessage,
            nil, "chevron", not validateItemBuild(),
            function()
                if finalizeItemCreation() then
                    local items = TriggerServerCallback('core:firework:getGlobalItemsForBuilder')
                    StaffMenu.currentFireworkItems = items or {}
                    if StaffMenu.builderFireworkItemCreate.close then
                        StaffMenu.builderFireworkItemCreate.close()
                    end
                    if StaffMenu.builderFireworkItems and StaffMenu.builderFireworkItems.open then
                        StaffMenu.builderFireworkItems.open()
                    end
                end
            end)
end

function StaffMenu.BuildEditFireworkItemMenu()
    if not StaffMenu or not StaffMenu.builderFireworkItemEdit then
        return
    end

    local itemId = StaffMenu.currentFireworkItemId
    local itemData = StaffMenu.currentFireworkItemData

    if not itemId or not itemData then
        return
    end

    local itemLabel = itemData.label or itemData.name

    StaffMenu.builderFireworkItemEdit.Separator("ARTICLE #" .. itemId)
    StaffMenu.builderFireworkItemEdit.Button(":sparkles: NOM: " .. itemLabel,
            itemData.name, nil, "check", true, function() end)

    StaffMenu.builderFireworkItemEdit.Button(":money: PRIX: " .. VFW.Math.FormatMoney(itemData.price),
            "Modifier le prix de l'article", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Prix", tostring(itemData.price))
                if result and result ~= "" then
                    local newPrice = tonumber(result) or itemData.price
                    TriggerServerEvent('core:firework:updateGlobalItem', itemData.name, newPrice, nil, nil, nil)
                    itemData.price = newPrice
                    if StaffMenu.builderFireworkItemEdit.refresh then
                        StaffMenu.builderFireworkItemEdit.refresh()
                    end
                end
            end)

    local categoryLabel = getCategoryLabel(itemData.category)
    StaffMenu.builderFireworkItemEdit.Button(":folder: CATÉGORIE: " .. categoryLabel,
            "Catégorie de l'article", nil, "check", true, function() end)

    StaffMenu.builderFireworkItemEdit.Button(":box: STOCK: " .. (itemData.stock or 0),
            "Modifier le stock", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Stock", tostring(itemData.stock or 0))
                if result and result ~= "" then
                    local newStock = tonumber(result) or 0
                    TriggerServerEvent('core:firework:updateGlobalItem', itemData.name, nil, nil, nil, newStock)
                    itemData.stock = newStock
                    if StaffMenu.builderFireworkItemEdit.refresh then
                        StaffMenu.builderFireworkItemEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkItemEdit.Separator("ACTIONS")

    if itemData.enabled then
        StaffMenu.builderFireworkItemEdit.Button(":ban: DÉSACTIVER L'ARTICLE",
                "Masquer cet article du catalogue (il ne sera plus visible en boutique)", nil, "chevron", false,
                function()
                    TriggerServerEvent('core:firework:removeGlobalItem', itemData.name)
                    itemData.enabled = false
                    if StaffMenu.builderFireworkItemEdit.refresh then
                        StaffMenu.builderFireworkItemEdit.refresh()
                    end
                    -- refresh list
                    local items = TriggerServerCallback('core:firework:getGlobalItemsForBuilder')
                    StaffMenu.currentFireworkItems = items or {}
                end)
    else
        StaffMenu.builderFireworkItemEdit.Button(":check: ACTIVER L'ARTICLE",
                "Remettre cet article visible dans le catalogue", nil, "chevron", false,
                function()
                    TriggerServerEvent('core:firework:enableGlobalItem', itemData.name)
                    itemData.enabled = true
                    if StaffMenu.builderFireworkItemEdit.refresh then
                        StaffMenu.builderFireworkItemEdit.refresh()
                    end
                    -- refresh list
                    local items = TriggerServerCallback('core:firework:getGlobalItemsForBuilder')
                    StaffMenu.currentFireworkItems = items or {}
                end)
    end
end

function StaffMenu.BuildFireworkSettingsMenu()
    if not StaffMenu or not StaffMenu.builderFireworkSettings then
        return
    end

    local settings = TriggerServerCallback('core:firework:getSettings') or {}

    StaffMenu.builderFireworkSettings.Separator("PARAMÈTRES ÉCONOMIE")

    StaffMenu.builderFireworkSettings.Button(":money: MULTIPLICATEUR PRIX: " .. (settings.basePriceMultiplier or 1.0),
            "Multiplicateur global appliqué aux prix", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Multiplicateur prix (ex: 1.0, 1.2)", tostring(settings.basePriceMultiplier or 1.0))
                if result and result ~= "" then
                    local multiplier = tonumber(result) or 1.0
                    TriggerServerEvent('core:firework:updateSettings', 'basePriceMultiplier', multiplier)
                    settings.basePriceMultiplier = multiplier
                    if StaffMenu.builderFireworkSettings.refresh then
                        StaffMenu.builderFireworkSettings.refresh()
                    end
                end
            end)

    StaffMenu.builderFireworkSettings.Button(":chart: LIMITE ACHATS/JOUR: " .. (settings.maxDailyPurchases or 0) .. (settings.maxDailyPurchases == 0 and " (illimité)" or ""),
            "Limite d'achats par joueur par 24h (0 = illimité)", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Limite d'achats/jour (0 = illimité)", tostring(settings.maxDailyPurchases or 0))
                if result and result ~= "" then
                    local limit = tonumber(result) or 0
                    TriggerServerEvent('core:firework:updateSettings', 'maxDailyPurchases', limit)
                    settings.maxDailyPurchases = limit
                    if StaffMenu.builderFireworkSettings.refresh then
                        StaffMenu.builderFireworkSettings.refresh()
                    end
                end
            end)
end

-- OnOpen hooks - COMMENTED OUT because code moved to builders.lua
-- if StaffMenu and StaffMenu.builderFirework and StaffMenu.builderFirework.OnOpen then
--     StaffMenu.builderFirework.OnOpen(function()
--         StaffMenu.BuildFireworkMenu()
--     end)
-- end

-- if StaffMenu and StaffMenu.builderFireworkCreate then
--     if StaffMenu.builderFireworkCreate.OnOpen then
--         StaffMenu.builderFireworkCreate.OnOpen(function()
--             StaffMenu.BuildCreateFireworkShopMenu()
--             if currentFireworkBuild.position then
--                 startMarkerThread()
--             end
--         end)
--     end

--     if StaffMenu.builderFireworkCreate.OnClose then
--         StaffMenu.builderFireworkCreate.OnClose(function()
--             stopMarkerThread()
--         end)
--     end
-- end

-- if StaffMenu and StaffMenu.builderFireworkManage and StaffMenu.builderFireworkManage.OnOpen then
--     StaffMenu.builderFireworkManage.OnOpen(function()
--         local shops = TriggerServerCallback('core:firework:getShops')
--         StaffMenu.currentFireworkShops = shops or {}
--         StaffMenu.BuildManageFireworkShopsMenu()
--     end)
-- end

-- if StaffMenu and StaffMenu.builderFireworkEdit and StaffMenu.builderFireworkEdit.OnOpen then
--     StaffMenu.builderFireworkEdit.OnOpen(function()
--         StaffMenu.BuildEditFireworkShopMenu()
--     end)
-- end

-- if StaffMenu and StaffMenu.builderFireworkItems and StaffMenu.builderFireworkItems.OnOpen then
--     StaffMenu.builderFireworkItems.OnOpen(function()
--         local items = TriggerServerCallback('core:firework:getGlobalItemsForBuilder')
--         StaffMenu.currentFireworkItems = items or {}
--         StaffMenu.BuildFireworkItemsMenu()
--     end)
-- end

-- if StaffMenu and StaffMenu.builderFireworkItemCreate and StaffMenu.builderFireworkItemCreate.OnOpen then
--     StaffMenu.builderFireworkItemCreate.OnOpen(function()
--         StaffMenu.BuildCreateFireworkItemMenu()
--     end)
-- end

-- if StaffMenu and StaffMenu.builderFireworkItemEdit and StaffMenu.builderFireworkItemEdit.OnOpen then
--     StaffMenu.builderFireworkItemEdit.OnOpen(function()
--         StaffMenu.BuildEditFireworkItemMenu()
--     end)
-- end

-- if StaffMenu and StaffMenu.builderFireworkSettings and StaffMenu.builderFireworkSettings.OnOpen then
--     StaffMenu.builderFireworkSettings.OnOpen(function()
--         StaffMenu.BuildFireworkSettingsMenu()
--     end)
-- end
