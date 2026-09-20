-- Shop Builder for Staff Menu - Separated by Type
-- Types: clothing, barber, tattoo, mask

local currentShopBuild = {
    type = nil,
    position = nil,
    isValid = false
}

-- :fire: FIX: Variable déplacée en haut pour être accessible partout
local addChairToShop = {}

local markerThread = nil
local isMarkersActive = false

--- Shop Types Configuration
local SHOP_TYPES = {
    clothing = {value = "clothing", label = ":cart: VÊTEMENTS", blip = 73, color = 47},
    barber = {value = "barber", label = ":building: BARBER SHOP", blip = 71, color = 0},
    tattoo = {value = "tattoo", label = ":edit: TATOUAGES", blip = 75, color = 1},
    mask = {value = "mask", label = ":mask: MASQUES", blip = 362, color = 27}
}

--- Get shop type label
local function getShopTypeLabel(type)
    if SHOP_TYPES[type] then
        return SHOP_TYPES[type].label
    end
    return ":building: " .. string.upper(type)
end

--- Get shop type config
local function getShopTypeConfig(type)
    return SHOP_TYPES[type]
end

--- Validate current shop build
local function validateShopBuild()
    currentShopBuild.isValid = currentShopBuild.position ~= nil and
            currentShopBuild.type ~= nil and
            currentShopBuild.priceMultiplier ~= nil and
            currentShopBuild.priceMultiplier >= 0.1 and
            currentShopBuild.priceMultiplier <= 5.0
    return currentShopBuild.isValid
end

--- Get current player position
local function getCurrentPlayerPosition()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then
        return nil
    end

    local coords = GetEntityCoords(playerPed)
    if not coords then
        return nil
    end

    local heading = GetEntityHeading(playerPed)

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading -- :sparkles: Siempre incluir heading para NPCs
    }
end

--- Stop marker thread
local function stopMarkerThread()
    if isMarkersActive then
        isMarkersActive = false
        Wait(100)
    end
    markerThread = nil
end

--- Start marker thread for shop position
local function startMarkerThread()
    if markerThread or not currentShopBuild.position then
        return
    end

    isMarkersActive = true
    markerThread = true
    CreateThread(function()
        local pos = currentShopBuild.position

        while isMarkersActive and pos do
            local coords = vector3(pos.x, pos.y, pos.z)

            DrawMarker(27, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0, 255, 255, 0, 150, false, true, 2, false, nil, nil, false)

            local shopTypeLabel = getShopTypeLabel(currentShopBuild.type)
            local text = "NOUVEAU MAGASIN\n" .. shopTypeLabel

            local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
            if onScreen then
                SetTextScale(0.4, 0.4)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextColour(255, 255, 255, 215)
                SetTextCentre(true)
                SetTextOutline()
                SetTextEntry("STRING")
                AddTextComponentString(text)
                DrawText(screenX, screenY)
            end

            Wait(0)
        end
    end)
end

--- Reset shop build
local function resetShopBuild(shopType)
    stopMarkerThread()

    -- :fire: FIX CRITIQUE : On vide la liste des chaises ici pour éviter les doublons entre créations
    addChairToShop = {}

    currentShopBuild = {
        type = shopType or nil,
        position = nil,
        priceMultiplier = 1.0, -- :sparkles: Multiplicador por defecto
        isValid = false
    }
end

--- Set shop position at current player location
local function setShopPosition()
    stopMarkerThread()

    local pos = getCurrentPlayerPosition()
    if pos then
        currentShopBuild.position = pos
        validateShopBuild()
        return true
    end
    return false
end

--- Finalize shop creation
local function finalizeShopCreation()
    if not validateShopBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
        return false
    end

    local shopConfig = getShopTypeConfig(currentShopBuild.type)
    if not shopConfig then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Ce type de magasin n'est pas valide."})
        return false
    end

    local shopData = {
        type = currentShopBuild.type,
        position = currentShopBuild.position,
        blip = shopConfig.blip,
        blipColor = shopConfig.color,
        priceMultiplier = currentShopBuild.priceMultiplier or 1.0,
        chairs = addChairToShop or {}
    }

    local success = TriggerServerCallback('staff:createShop', shopData)

    if success then
        local shopTypeLabel = getShopTypeLabel(currentShopBuild.type)
        local percentage = math.floor(currentShopBuild.priceMultiplier * 100)
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Builder',
            message = string.format("%s créé (Prix: %.0f%%).", shopTypeLabel, percentage)
        })
        resetShopBuild(currentShopBuild.type)
        return true
    else
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Erreur lors de la création du magasin."})
        return false
    end
end

--- Filter shops by type
local function filterShopsByType(shops, shopType)
    if not shops then return {} end
    local filtered = {}
    for shopId, shopData in pairs(shops) do
        if shopData and shopData.type == shopType then
            filtered[shopId] = shopData
        end
    end
    return filtered
end

--- Build main shops menu
function StaffMenu.BuildShopsMenu()
    if not StaffMenu or not StaffMenu.builderShops then return end

    StaffMenu.builderShops.Separator("TYPES DE MAGASINS")

    StaffMenu.builderShops.Button(" Gérer les prix", "Modifier les prix des articles", nil, "chevron", false, function() end, StaffMenu.manageClothesPrice)
    StaffMenu.builderShops.Button(':cart: BUILDER VÊTEMENTS', 'Créer et gérer les magasins de vêtements', nil, 'chevron', false, function() end, StaffMenu.builderClothing)
    StaffMenu.builderShops.Button(':ban: BLACKLIST VETEMENTS', 'Gérer les vêtements bannis par catégorie', nil, 'chevron', false, function() end, StaffMenu.clothesBlacklist)
    StaffMenu.builderShops.Button(':building: BUILDER BARBER', 'Créer et gérer les salons de coiffure', nil, 'chevron', false, function()
        local shops = TriggerServerCallback('staff:getShops')
        StaffMenu.currentShops = filterShopsByType(shops, "barber")
    end, StaffMenu.builderBarber)
    StaffMenu.builderShops.Button(':edit: BUILDER TATOUAGES', 'Créer et gérer les salons de tatouage', nil, 'chevron', false, function()
        local shops = TriggerServerCallback('staff:getShops')
        StaffMenu.currentShops = filterShopsByType(shops, "tattoo")
    end, StaffMenu.builderTattoo)
    StaffMenu.builderShops.Button(':mask: BUILDER MASQUES', 'Créer et gérer les magasins de masques', nil, 'chevron', false, function()
        local shops = TriggerServerCallback('staff:getShops')
        StaffMenu.currentShops = filterShopsByType(shops, "mask")
    end, StaffMenu.builderMask)
end

--- Build specific shop type menu
local function buildShopTypeMenu(menu, shopType, createMenu, manageMenu)
    if not menu then return end
    menu.Button(':plus: CRÉER UN MAGASIN', 'Créer un nouveau magasin', nil, 'chevron', false, function()
        resetShopBuild(shopType)
    end, createMenu)
    menu.Button(':report: GÉRER LES MAGASINS', 'Voir et gérer les magasins existants', nil, 'chevron', false, function()
        local shops = TriggerServerCallback('staff:getShops')
        StaffMenu.currentShops = filterShopsByType(shops, shopType)
    end, manageMenu)
end

-- Clothes Price Management
local editedClothesPrice = {}
function StaffMenu.BuildManageClothesPriceMenu()
    local clothesPrice = TriggerServerCallback('core:getClothesPrice')
    editedClothesPrice = {}
    for sex, categories in pairs(clothesPrice) do
        StaffMenu.manageClothesPrice.Button(("%s"):format(sex == "Homme" and ":user: Homme" or ":user: Femme"), nil, nil, 'chevron', false, function()
            StaffMenu.currentManageClothesList = {sex = sex, categories = categories}
        end, StaffMenu.manageClothesPriceList)
    end
end

function StaffMenu.BuildManageClothesPriceListMenu()
    for category, data in pairs(StaffMenu.currentManageClothesList.categories) do
        StaffMenu.manageClothesPriceList.Button(data.label, nil, VFW.Math.FormatMoney(editedClothesPrice[StaffMenu.currentManageClothesList.sex] and editedClothesPrice[StaffMenu.currentManageClothesList.sex][category] or data.price), 'chevron', false, function()
            local newPrice = tonumber(VFW.Nui.KeyboardInput(true, "Entrez le nouveau prix"))
            if newPrice then
                TriggerServerCallback('core:setClothesPrice', StaffMenu.currentManageClothesList.sex, category, newPrice)
                editedClothesPrice[StaffMenu.currentManageClothesList.sex] = editedClothesPrice[StaffMenu.currentManageClothesList.sex] or {}
                editedClothesPrice[StaffMenu.currentManageClothesList.sex][category] = newPrice
                StaffMenu.manageClothesPriceList.refresh()
            end
        end )
    end
end

if StaffMenu.manageClothesPriceList then
    StaffMenu.manageClothesPriceList.OnOpen(function() StaffMenu.BuildManageClothesPriceListMenu() end)
end

--- Shop Menus Builders
function StaffMenu.BuildClothingMenu() buildShopTypeMenu(StaffMenu.builderClothing, "clothing", StaffMenu.builderClothingCreate, StaffMenu.builderClothingManage) end
function StaffMenu.BuildBarberMenu() buildShopTypeMenu(StaffMenu.builderBarber, "barber", StaffMenu.builderBarberCreate, StaffMenu.builderBarberManage) end
function StaffMenu.BuildTattooMenu() buildShopTypeMenu(StaffMenu.builderTattoo, "tattoo", StaffMenu.builderTattooCreate, StaffMenu.builderTattooManage) end
function StaffMenu.BuildMaskMenu() buildShopTypeMenu(StaffMenu.builderMask, "mask", StaffMenu.builderMaskCreate, StaffMenu.builderMaskManage) end

-- Raycast Logic
local function RotationToDirection(rotation)
    local adjustedRotation = vector3((math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
    local direction = vector3(-math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.sin(adjustedRotation.x))
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = vector3(cameraCoord.x + direction.x * distance, cameraCoord.y + direction.y * distance, cameraCoord.z + direction.z * distance)
    local _, hit, coords, _, entity = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return hit, coords, entity
end

local function SelectChair()
    local selectionActive = true
    local currentEntity = nil
    local selectedEntity = nil
    local selectedCoords = nil

    -- Liste des modèles de chaises connus (Barber & Tattoo) pour détection forcée des objets map
    local knownChairModels = {
        GetHashKey("v_club_tattoo_chair"),
        GetHashKey("bkr_prop_clubhouse_tattoo_chair"),
        GetHashKey("v_serv_bs_chair"), -- Barber
        GetHashKey("miss_hair_shop_chair_01"), -- Barber
        GetHashKey("prop_chair_01a"),
        GetHashKey("prop_chair_02"),
        -- Ajoutez d'autres modèles ici si nécessaire
    }

    CreateThread(function()
        while selectionActive do
            Wait(0)
            VFW.ShowHelpNotification("~INPUT_CONTEXT~ Sélectionner la chaise ~n~~INPUT_FRONTEND_RRIGHT~ Annuler")

            if currentEntity and currentEntity ~= selectedEntity then SetEntityDrawOutline(currentEntity, false) end

            local hit, coords, entity = RayCastGamePlayCamera(20.0)

            -- 1. Si pas d'entité directe, on cherche l'objet script le plus proche du point d'impact
            if (not DoesEntityExist(entity) or entity == 0) and hit then
                local objects = GetGamePool('CObject')
                local closestDist = 3.0 -- Rayon augmenté
                local closestObj = nil
                
                for i = 1, #objects do
                    local obj = objects[i]
                    local objCoords = GetEntityCoords(obj)
                    local dist = #(coords - objCoords)
                    if dist < closestDist then
                        closestDist = dist
                        closestObj = obj
                    end
                end
                
                if closestObj then
                    entity = closestObj
                end
            end

            -- 2. Si toujours rien, on force la recherche par modèle (pour les objets map statiques)
            if (not DoesEntityExist(entity) or entity == 0) and hit then
                local closestDist = 3.0
                for _, modelHash in ipairs(knownChairModels) do
                    local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, modelHash, false, false, false)
                    if DoesEntityExist(obj) then
                        local objCoords = GetEntityCoords(obj)
                        local dist = #(coords - objCoords)
                        if dist < closestDist then
                            closestDist = dist
                            entity = obj
                        end
                    end
                end
            end

            -- Visualisation du point de recherche
            if hit then
                DrawMarker(28, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0, 0.1, 0.1, 0.1, 255, 0, 0, 150, false, false, 2, nil, nil, false)
            end

            if DoesEntityExist(entity) then
                currentEntity = entity
                
                -- Si c'est un objet map statique sans collision gérée par le script, DrawOutline peut ne pas marcher,
                -- on ajoute donc un Box visuel ou une ligne.
                SetEntityDrawOutline(currentEntity, true)
                local entCoords = GetEntityCoords(currentEntity)
                DrawMarker(0, entCoords.x, entCoords.y, entCoords.z + 1.2, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 200, true, true, 2, nil, nil, false)

                if VFW.Interact.JustPressed(0, 51) then
                    selectedEntity = entity
                    selectedCoords = GetEntityCoords(entity)
                    selectionActive = false
                end
            end

            if IsControlJustPressed(0, 194) then
                if currentEntity then SetEntityDrawOutline(currentEntity, false) end
                selectionActive = false
            end
        end

        if currentEntity and not selectedEntity then SetEntityDrawOutline(currentEntity, false) end
        if selectedEntity then SetEntityDrawOutline(selectedEntity, false) end
    end)

    while selectionActive do Wait(100) end
    return selectedEntity, selectedCoords
end

--- Build create shop menu (generic function)
local function buildCreateShopMenu(menu)
    if not menu or not currentShopBuild.type then return end

    -- 1. GESTION DE LA POSITION
    local positionText
    if currentShopBuild.position then
        if currentShopBuild.type == "mask" then
            positionText = string.format("X: %.2f Y: %.2f Z: %.2f H: %.1f°", currentShopBuild.position.x, currentShopBuild.position.y, currentShopBuild.position.z, currentShopBuild.position.heading or 0.0)
        else
            positionText = string.format("X: %.2f Y: %.2f Z: %.2f", currentShopBuild.position.x, currentShopBuild.position.y, currentShopBuild.position.z)
        end
    else
        positionText = "NON DÉFINI"
  end

    local positionDesc = currentShopBuild.type == "mask" and "Définir la position et l'orientation du NPC à votre emplacement actuel" or "Définir la position du magasin à votre emplacement actuel"

  menu.Button(":pin: POSITION: " .. positionText, positionDesc, nil, "arrow", false, function()
        if setShopPosition() then
            if menu.refresh then menu.refresh() end
            startMarkerThread()
        end
    end)

    -- 2. MULTIPLICATEUR DE PRIX
    local multiplierText = currentShopBuild.priceMultiplier and string.format("%.2f (%.0f%%)", currentShopBuild.priceMultiplier, currentShopBuild.priceMultiplier * 100) or "1.00 (100%)"

  menu.Button(":money: MULTIPLICATEUR DE PRIX: " .. multiplierText, "Modifier le multiplicateur de prix (1.0 = 100%, 1.5 = +50%, 0.8 = -20%)", nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Multiplicateur de prix (0.1 à 5.0, ex: 1.5 pour +50%)", tostring(currentShopBuild.priceMultiplier or 1.0))
        local value = tonumber(input)
        if value and value >= 0.1 and value <= 5.0 then
            currentShopBuild.priceMultiplier = value
            validateShopBuild()
            if menu.refresh then menu.refresh() end
        elseif input and input ~= "" then
            VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette valeur n'est pas valide. Entrez un nombre entre 0.1 et 5.0."})
        end
    end)

    -- 3. GESTION DES CHAISES (Barbier & Tatoueur)
    if currentShopBuild.type == "barber" then
        menu.Button(":plus: AJOUTER DES CHAISES", "Ajouter des chaises au salon", nil, "chevron", false, function()
            menu.close()
            Citizen.CreateThread(function()
                local chairEntity, chairCoords = SelectChair()

                if chairEntity and chairCoords then
                    -- :fire: MODIF ICI: Utilisation de GetEntityModel pour récupérer le HASH du modèle
                    local modelHash = GetEntityModel(chairEntity)
                    local heading = GetEntityHeading(chairEntity) -- :fire: ON RECUPERE LE HEADING

                    -- On s'assure que la table existe
                    addChairToShop = addChairToShop or {}


                    table.insert(addChairToShop, {
                        x = chairCoords.x,
                        y = chairCoords.y,
                        z = chairCoords.z,
                        w = heading, -- :fire: STOCKAGE DU HEADING
                        model = modelHash 
                    })

                    VFW.ShowNotification({type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Chaise ajoutée."})
                else
                    VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Aucune chaise sélectionnée."})
                end
                menu.open()
            end)
        end)

        if addChairToShop and #addChairToShop > 0 then
            menu.Separator("Liste des chaises (" .. #addChairToShop .. ")")
            for i, chair in ipairs(addChairToShop) do
                menu.Button(" CHAISE #" .. i, string.format("Supprimer (X: %.1f Y: %.1f)", chair.x, chair.y), nil, "trash", false, function()
                    table.remove(addChairToShop, i)
                    VFW.ShowNotification({type = 'STAFF', variant = 'INFO', subtitle = 'Builder', message = "Chaise #" .. i .. " supprimée."})
                    if menu.refresh then menu.refresh() end
                end)
            end
        end
    end

    menu.Separator(nil)

    -- 4. VALIDATION ET FINALISATION
    local statusMessage = ""
  if not currentShopBuild.position then
        statusMessage = "Position du magasin requise"
  elseif not currentShopBuild.priceMultiplier or currentShopBuild.priceMultiplier < 0.1 or currentShopBuild.priceMultiplier > 5.0 then
        statusMessage = "Ce multiplicateur de prix n'est pas valide (0.1 - 5.0)"
  else
        statusMessage = "Configuration terminée"
  end

    menu.Button(":check: CRÉER LE MAGASIN", statusMessage, nil, "chevron", not currentShopBuild.isValid, function()
        if finalizeShopCreation() then
            -- Retourner au menu parent (builderClothing/Barber/Tattoo/Mask) au lieu de fermer
            if menu._closeInternal then
                menu._closeInternal()
            end
            if menu.parent then
                menu.parent.open()
            end
        end
    end)
end

-- Hook up menus
function StaffMenu.BuildCreateClothingMenu() buildCreateShopMenu(StaffMenu.builderClothingCreate) end
function StaffMenu.BuildCreateBarberMenu() buildCreateShopMenu(StaffMenu.builderBarberCreate) end
function StaffMenu.BuildCreateTattooMenu() buildCreateShopMenu(StaffMenu.builderTattooCreate) end
function StaffMenu.BuildCreateMaskMenu() buildCreateShopMenu(StaffMenu.builderMaskCreate) end

--- Build manage shops menu
local function buildManageShopsMenu(menu, editMenu)
    if not menu then return end
    local shops = StaffMenu.currentShops or {}
    local hasShops = next(shops) ~= nil
    local separatorText = hasShops and 'MAGASINS EXISTANTS' or 'AUCUN MAGASIN'
    menu.Separator(separatorText)

    if hasShops then
        for shopId, shopData in pairs(shops) do
            if shopData and shopData.type then
                local shopTypeLabel = getShopTypeLabel(shopData.type)
                local posText = string.format("X: %.0f Y: %.0f Z: %.0f", shopData.position.x, shopData.position.y, shopData.position.z)
                menu.Button(shopTypeLabel .. " #" .. shopId, posText, nil, 'chevron', false, function()
                    StaffMenu.currentShopId = shopId
                    StaffMenu.currentShopData = shopData
                end, editMenu)
            end
        end
    end
end

function StaffMenu.BuildManageClothingMenu() buildManageShopsMenu(StaffMenu.builderClothingManage, StaffMenu.builderShopEdit) end
function StaffMenu.BuildManageBarberMenu() buildManageShopsMenu(StaffMenu.builderBarberManage, StaffMenu.builderShopEdit) end
function StaffMenu.BuildManageTattooMenu() buildManageShopsMenu(StaffMenu.builderTattooManage, StaffMenu.builderShopEdit) end
function StaffMenu.BuildManageMaskMenu() buildManageShopsMenu(StaffMenu.builderMaskManage, StaffMenu.builderShopEdit) end

--- Build edit shop menu
function StaffMenu.BuildEditShopMenu()
    if not StaffMenu or not StaffMenu.builderShopEdit then return end
    local shopId = StaffMenu.currentShopId
    local shopData = StaffMenu.currentShopData
    if not shopId or not shopData then return end

    local shopTypeLabel = getShopTypeLabel(shopData.type)
    StaffMenu.builderShopEdit.Separator("MAGASIN #" .. shopId)
    StaffMenu.builderShopEdit.Button(":building: TYPE: " .. shopTypeLabel, "Type de magasin", nil, "check", true, function() end)

    local posText
    if shopData.type == "mask" then
        posText = string.format("X: %.2f Y: %.2f Z: %.2f H: %.1f°", shopData.position.x, shopData.position.y, shopData.position.z, shopData.position.heading or 0.0)
    else
        posText = string.format("X: %.2f Y: %.2f Z: %.2f", shopData.position.x, shopData.position.y, shopData.position.z)
    end
    local posDesc = shopData.type == "mask" and "Position et orientation du NPC" or "Position du magasin"

  StaffMenu.builderShopEdit.Button(":pin: POSITION: " .. posText, posDesc, nil, "check", true, function() end)
    local multiplier = shopData.priceMultiplier or 1.0
    local multiplierText = string.format("%.2f (%.0f%%)", multiplier, multiplier * 100)
    StaffMenu.builderShopEdit.Button(":money: MULTIPLICATEUR: " .. multiplierText, "Multiplicateur de prix appliqué aux articles", nil, "check", true, function() end)

    StaffMenu.builderShopEdit.Separator("ACTIONS")
    StaffMenu.builderShopEdit.Button(":pin: TÉLÉPORTER AU MAGASIN", "Se téléporter à la position du magasin", nil, "arrow", false, function()
        SetEntityCoords(PlayerPedId(), shopData.position.x, shopData.position.y, shopData.position.z, false, false, false, true)
    end)

    local modifyPosDesc = shopData.type == "mask" and "Redéfinir la position et l'orientation du NPC à votre emplacement actuel" or "Redéfinir la position du magasin à votre emplacement actuel"
  StaffMenu.builderShopEdit.Button(":edit: MODIFIER LA POSITION", modifyPosDesc, nil, "arrow", false, function()
        local newPos = getCurrentPlayerPosition()
        if newPos then
            local success = TriggerServerCallback('staff:updateShopPosition', shopId, newPos)
            if success then
                VFW.ShowNotification({type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Position du magasin modifiée."})
                shopData.position = newPos
                StaffMenu.currentShopData.position = newPos
                local shops = TriggerServerCallback('staff:getShops')
                StaffMenu.currentShops = filterShopsByType(shops, shopData.type)
                if StaffMenu.builderShopEdit.refresh then StaffMenu.builderShopEdit.refresh() end
            else
                VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Erreur lors de la modification de la position."})
            end
        else
            VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Impossible d'obtenir la position actuelle."})
        end
    end)

    StaffMenu.builderShopEdit.Button(":money: MODIFIER LE PRIX", "Modifier le multiplicateur de prix du magasin", nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Multiplicateur de prix (0.1 à 5.0, ex: 1.5 pour +50%)", tostring(shopData.priceMultiplier or 1.0))
        local newMultiplier = tonumber(input)
        if newMultiplier and newMultiplier >= 0.1 and newMultiplier <= 5.0 then
            local success = TriggerServerCallback('staff:updateShopPriceMultiplier', shopId, newMultiplier)
            if success then
                local percentage = math.floor(newMultiplier * 100)
                VFW.ShowNotification({type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = string.format("Multiplicateur de prix modifié: %.2f (%.0f%%).", newMultiplier, percentage)})
                shopData.priceMultiplier = newMultiplier
                StaffMenu.currentShopData.priceMultiplier = newMultiplier
                local shops = TriggerServerCallback('staff:getShops')
                StaffMenu.currentShops = filterShopsByType(shops, shopData.type)
                if StaffMenu.builderShopEdit.refresh then StaffMenu.builderShopEdit.refresh() end
            else
                VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Erreur lors de la modification du multiplicateur."})
            end
        elseif input and input ~= "" then
            VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette valeur n'est pas valide. Entrez un nombre entre 0.1 et 5.0."})
        end
    end)

    StaffMenu.builderShopEdit.Button(":trash: SUPPRIMER LE MAGASIN", "Supprimer définitivement ce magasin", nil, "chevron", false, function()
        local success = TriggerServerCallback('staff:deleteShop', shopId)
        if success then
            VFW.ShowNotification({type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Magasin supprimé."})
            -- Rafraîchir la liste des magasins
            local shops = TriggerServerCallback('staff:getShops')
            StaffMenu.currentShops = filterShopsByType(shops, shopData.type)
            -- Retourner au menu de gestion correspondant au type de magasin
            local manageMenus = {
                clothing = StaffMenu.builderClothingManage,
                barber = StaffMenu.builderBarberManage,
                tattoo = StaffMenu.builderTattooManage,
                mask = StaffMenu.builderMaskManage
            }
            local manageMenu = manageMenus[shopData.type]
            if manageMenu then
                if StaffMenu.builderShopEdit._closeInternal then
                    StaffMenu.builderShopEdit._closeInternal()
                end
                manageMenu.open()
            end
        else
            VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Erreur lors de la suppression du magasin."})
        end
    end)
end

-- Init Events
if StaffMenu then
    if StaffMenu.manageClothesPrice and StaffMenu.manageClothesPrice.OnOpen then StaffMenu.manageClothesPrice.OnOpen(function() StaffMenu.BuildManageClothesPriceMenu() end) end
    if StaffMenu.builderShops and StaffMenu.builderShops.OnOpen then StaffMenu.builderShops.OnOpen(function() StaffMenu.BuildShopsMenu() end) end
    if StaffMenu.builderClothing and StaffMenu.builderClothing.OnOpen then StaffMenu.builderClothing.OnOpen(function() StaffMenu.BuildClothingMenu() end) end
    if StaffMenu.builderClothingCreate and StaffMenu.builderClothingCreate.OnOpen then StaffMenu.builderClothingCreate.OnOpen(function() StaffMenu.BuildCreateClothingMenu(); if currentShopBuild.position then startMarkerThread() end end) end
    if StaffMenu.builderClothingCreate and StaffMenu.builderClothingCreate.OnClose then StaffMenu.builderClothingCreate.OnClose(function() stopMarkerThread() end) end
    if StaffMenu.builderClothingManage and StaffMenu.builderClothingManage.OnOpen then StaffMenu.builderClothingManage.OnOpen(function() StaffMenu.BuildManageClothingMenu() end) end
    if StaffMenu.builderBarber and StaffMenu.builderBarber.OnOpen then StaffMenu.builderBarber.OnOpen(function() StaffMenu.BuildBarberMenu() end) end
    if StaffMenu.builderBarberCreate and StaffMenu.builderBarberCreate.OnOpen then StaffMenu.builderBarberCreate.OnOpen(function() StaffMenu.BuildCreateBarberMenu(); if currentShopBuild.position then startMarkerThread() end end) end
    if StaffMenu.builderBarberCreate and StaffMenu.builderBarberCreate.OnClose then StaffMenu.builderBarberCreate.OnClose(function() stopMarkerThread() end) end
    if StaffMenu.builderBarberManage and StaffMenu.builderBarberManage.OnOpen then StaffMenu.builderBarberManage.OnOpen(function() StaffMenu.BuildManageBarberMenu() end) end
    if StaffMenu.builderTattoo and StaffMenu.builderTattoo.OnOpen then StaffMenu.builderTattoo.OnOpen(function() StaffMenu.BuildTattooMenu() end) end
    if StaffMenu.builderTattooCreate and StaffMenu.builderTattooCreate.OnOpen then StaffMenu.builderTattooCreate.OnOpen(function() StaffMenu.BuildCreateTattooMenu(); if currentShopBuild.position then startMarkerThread() end end) end
    if StaffMenu.builderTattooCreate and StaffMenu.builderTattooCreate.OnClose then StaffMenu.builderTattooCreate.OnClose(function() stopMarkerThread() end) end
    if StaffMenu.builderTattooManage and StaffMenu.builderTattooManage.OnOpen then StaffMenu.builderTattooManage.OnOpen(function() StaffMenu.BuildManageTattooMenu() end) end
    if StaffMenu.builderMask and StaffMenu.builderMask.OnOpen then StaffMenu.builderMask.OnOpen(function() StaffMenu.BuildMaskMenu() end) end
    if StaffMenu.builderMaskCreate and StaffMenu.builderMaskCreate.OnOpen then StaffMenu.builderMaskCreate.OnOpen(function() StaffMenu.BuildCreateMaskMenu(); if currentShopBuild.position then startMarkerThread() end end) end
    if StaffMenu.builderMaskCreate and StaffMenu.builderMaskCreate.OnClose then StaffMenu.builderMaskCreate.OnClose(function() stopMarkerThread() end) end
    if StaffMenu.builderMaskManage and StaffMenu.builderMaskManage.OnOpen then StaffMenu.builderMaskManage.OnOpen(function() StaffMenu.BuildManageMaskMenu() end) end
    if StaffMenu.builderShopEdit and StaffMenu.builderShopEdit.OnOpen then StaffMenu.builderShopEdit.OnOpen(function() StaffMenu.BuildEditShopMenu() end) end
    if StaffMenu.clothesBlacklist and StaffMenu.clothesBlacklist.OnOpen then StaffMenu.clothesBlacklist.OnOpen(function() StaffMenu.BuildClothesBlacklistMenu() end) end
    if StaffMenu.clothesBlacklistGender and StaffMenu.clothesBlacklistGender.OnOpen then StaffMenu.clothesBlacklistGender.OnOpen(function() StaffMenu.BuildClothesBlacklistGenderMenu() end) end
    if StaffMenu.clothesBlacklistCategory and StaffMenu.clothesBlacklistCategory.OnOpen then StaffMenu.clothesBlacklistCategory.OnOpen(function() StaffMenu.BuildClothesBlacklistCategoryMenu() end) end
    if StaffMenu.clothesBlacklistCategory and StaffMenu.clothesBlacklistCategory.OnClose then StaffMenu.clothesBlacklistCategory.OnClose(function() TriggerEvent("clothesBlacklistCategory:onClose") end) end
end