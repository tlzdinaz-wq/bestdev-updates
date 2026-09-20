---@meta _
---@diagnostic disable: duplicate-doc-field

--[[
    NOUVELLE UI - Système de Magasin de Vêtements Moderne
]]

local savedSkinBeforeTattoo = nil
local isTattooModeActive = false
local isFreeStaffSkinSession = false
local ProcessClothePurchase

--- Returns player cash from inventory "money" items (not account money)
local function getPlayerCash()
    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return 0
    end
    local total = 0
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.PlayerData.inventory[i].name == "money" then
            total = total + VFW.PlayerData.inventory[i].count
        end
    end
    return total
end

local function ResolvePriceName(categoryId)
    if categoryId == "torso2" or categoryId == "undershirt" or categoryId == "torso" then
        return "top"
    elseif categoryId == "leg" then
        return "bottom"
    elseif categoryId == "shoes" then
        return "shoe"
    end
    return categoryId
end

--- Prix affiché côté client : DB ClothesConfig, repli Config.ClothesPrice, puis défaut 20$.
--- Les bras (torso) restent gratuits.
local function GetCategoryPrice(sex, categoryId, getClothesPrice, priceMultiplier)
    if categoryId == "torso" then
        return 0
    end

    local priceName = ResolvePriceName(categoryId)
    local price

    if getClothesPrice[priceName] and getClothesPrice[priceName].price ~= nil then
        price = tonumber(getClothesPrice[priceName].price)
    end

    if not price or price <= 0 then
        if Config.ClothesPrice and Config.ClothesPrice[sex] and Config.ClothesPrice[sex][priceName] then
            price = Config.ClothesPrice[sex][priceName]
        else
            price = 20
        end
    end

    priceMultiplier = priceMultiplier or 1.0
    return math.floor(price * priceMultiplier)
end

local drawableClothes = {
    torso2 = 11,
    undershirt = 8,
    torso = 3,
    leg = 4,
    shoes = 6,
    bag = 5,
    necklace = 7,
    mask = 1,
    hair = 2,
    kevlar = 9,
    decals = 10
}

local drawableProps = {
    glasses = 1,
    hat = 0,
    watch = 6,
    earring = 2,
    bracelet = 7
}

local overlayComponents = {
    beard = 1
}

local categoryLabels = {
    torso2 = "Haut",
    undershirt = "T-shirt",
    torso = "Bras",
    leg = "Pantalon",
    shoes = "Chaussures",
    bag = "Sac",
    watch = "Montre",
    necklace = "Collier",
    earring = "Boucle d'oreille",
    bracelet = "Bracelet",
    mask = "Masque",
    hair = "Coupe",
    glasses = "Lunettes",
    hat = "Chapeau",
    beard = "Barbe",
    kevlar = "Gilet",
    decals = "Plaque"
}

local banKeys = {
    torso2 = "BanTop",
    undershirt = "BanSous",
    torso = "BanArm",
    leg = "BanLeg",
    shoes = "BanShoes",
    bag = "BanBag",
    watch = "BanWatch",
    necklace = "BanNecklace",
    earring = "BanEarring",
    bracelet = "BanBracelet",
    mask = "BanMasque",
    hair = "CoupesBan",
    glasses = "BanGlases",
    hat = "BanHat",
    kevlar = "BanKevlar"
}

local currentShopData = nil
IsClothingShopOpen = false
local isShopOpen = false
local currentCamera = nil
local currentCamHandle = nil -- native cam handle (stored directly to avoid VFW.Cam reference issues)
local currentCameraView = "full"
local previewTattoo = nil

local camBasePos = nil
local currentFov, targetFov = 60.0, 60.0
local currentCamZ, targetCamZ = 0.0, 0.0
local currentLookZ, targetLookZ = 0.25, 0.25

local CAMERA_VIEWS = {
    full  = { camZ = 0.0,  lookZ = 0.25, fov = 45.0 },
    upper = { camZ = 0.3,  lookZ = 0.55, fov = 32.0 },
    head  = { camZ = 0.6,  lookZ = 0.7,  fov = 28.0 },
    feet  = { camZ = -0.5, lookZ = -0.6, fov = 38.0 },
}


-- ============================================================================
--  NUEVA FUNCIÓN: APLICAR MULTIPLICADOR DE PRECIO
-- ============================================================================
local function ApplyShopPriceMultiplier(items, multiplier)
    multiplier = multiplier or 1.0

    for i, item in ipairs(items) do
        if item.price then
            -- Aplicar multiplicador y redondear
            items[i].price = math.floor(item.price * multiplier)
        end
    end

    return items
end

local function SyncClothingClone()
    if not clothingClonePed or not DoesEntityExist(clothingClonePed) then return end
    local playerPed = VFW.PlayerData.ped or PlayerPedId()

    for componentId = 0, 11 do
        local drawable = GetPedDrawableVariation(playerPed, componentId)
        local texture = GetPedTextureVariation(playerPed, componentId)
        SetPedComponentVariation(clothingClonePed, componentId, drawable, texture, 0)
    end

    local propIds = { 0, 1, 2, 6, 7 }
    for _, propId in ipairs(propIds) do
        local drawable = GetPedPropIndex(playerPed, propId)
        local texture = GetPedPropTextureIndex(playerPed, propId)
        if drawable >= 0 then
            SetPedPropIndex(clothingClonePed, propId, drawable, texture, true)
        else
            ClearPedProp(clothingClonePed, propId)
        end
    end
end

local function UpdateCamera(smooth)
    if not currentCamHandle or not camBasePos then return end

    local playerPed = VFW.PlayerData.ped or PlayerPedId()
    if not playerPed or playerPed == 0 then return end

    local s = smooth and 0.08 or 1.0
    currentCamZ  = currentCamZ + (targetCamZ - currentCamZ) * s
    currentLookZ = currentLookZ + (targetLookZ - currentLookZ) * s
    currentFov   = currentFov + (targetFov - currentFov) * s

    local pedPos = GetEntityCoords(playerPed)
    local camPos  = vector3(camBasePos.x, camBasePos.y, camBasePos.z + currentCamZ)
    local lookPos = vector3(pedPos.x, pedPos.y, pedPos.z + currentLookZ)

    SetCamCoord(currentCamHandle, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(currentCamHandle, lookPos.x, lookPos.y, lookPos.z)
    SetCamFov(currentCamHandle, currentFov)
end

local function GetPlayerCurrentSkin()
    local skin = {}
    TriggerEvent('skinchanger:getSkin', function(skinData)
        skin = skinData
    end)
    return skin
end

function OpenModernClothingShop(shopData, isJob)
    if isShopOpen then return end

    --  NUEVO: OBTENER MULTIPLICADOR SI SE ABRIÓ DESDE UNA TIENDA ESPECÍFICA
    if shopData.shopId then
        local shops = TriggerServerCallback('shops:getAll')
        local fullShopData = shops and shops[shopData.shopId]
        if fullShopData then
            shopData.priceMultiplier = fullShopData.priceMultiplier or 1.0
        end
    end

    TriggerEvent('vfw_interaction:setMenuState', true)
    SendNUIMessage({ action = "nui:helpNotification:hide" })
    isShopOpen = true
    IsClothingShopOpen = true
    currentShopData = shopData

    --  NUEVO: Asegurar que tenga multiplicador
    if not currentShopData.priceMultiplier then
        currentShopData.priceMultiplier = 1.0
    end

    local shopType = shopData.shopType or "clothing"

    if shopType == "mask" then
        currentCameraView = "head"
    elseif shopType == "barber" then
        currentCameraView = "upper"
    elseif shopType == "tattoo" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            savedSkinBeforeTattoo = skin
            isTattooModeActive = true

            local clothes = {
                ['tshirt_1'] = 15, ['tshirt_2'] = 0,
                ['torso_1'] = 15, ['torso_2'] = 0,
                ['arms'] = 15,
                ['pants_1'] = 21, ['pants_2'] = 0,
                ['shoes_1'] = 34, ['shoes_2'] = 0,
            }

            if skin.sex == 1 then
                clothes = {
                    ['tshirt_1'] = 15, ['tshirt_2'] = 0,
                    ['torso_1'] = 15, ['torso_2'] = 0,
                    ['arms'] = 15,
                    ['pants_1'] = 15, ['pants_2'] = 0,
                    ['shoes_1'] = 35, ['shoes_2'] = 0,
                }
            end
            TriggerEvent('skinchanger:loadClothes', skin, clothes)
        end)
        currentCameraView = "full"
    else
        currentCameraView = "full"
    end

    local initialView = CAMERA_VIEWS[currentCameraView]
    currentCamZ  = initialView.camZ
    targetCamZ   = initialView.camZ
    currentLookZ = initialView.lookZ
    targetLookZ  = initialView.lookZ
    currentFov   = initialView.fov
    targetFov    = initialView.fov

    -- Wait a frame so skinchanger:loadClothes (tattoo mode) applies
    Wait(0)

    local playerPed = VFW.PlayerData.ped or PlayerPedId()

    -- Position camera in front of the player ped (no clone)
    local pedPos = GetEntityCoords(playerPed)
    local pedHeading = GetEntityHeading(playerPed)

    -- Camera placed 1.8m in front of the player, at chest height
    local headingRad = math.rad(pedHeading)
    local camDist = 1.8
    local camX = pedPos.x + math.sin(headingRad) * camDist
    local camY = pedPos.y + math.cos(headingRad) * camDist
    camBasePos = vector3(camX, camY, pedPos.z + 0.5)

    -- Calculate rotation to face the player
    local angleToPlayer = math.deg(math.atan(pedPos.x - camX, pedPos.y - camY))

    currentCamHandle = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        camBasePos.x, camBasePos.y, camBasePos.z,
        0.0, 0.0, angleToPlayer,
        initialView.fov, true, 2
    )
    SetCamActive(currentCamHandle, true)
    RenderScriptCams(true, false, 0, true, true)
    currentCamera = 'cam_clothing'

    -- Freeze player in place
    FreezeEntityPosition(playerPed, true)

    UpdateCamera(false)

    CreateThread(function()
        while isShopOpen and currentCamera do
            UpdateCamera(true)
            Wait(0)
        end
    end)

    VFW.Nui.HudVisible(false)
    DisplayHud(false)



    local playerSkin = GetPlayerCurrentSkin()

    local shopType = shopData.shopType or "clothing"
    local isVip = false
    local vipTier = tonumber(VFW.PlayerGlobalData and VFW.PlayerGlobalData.vip_tier) or 0
    if vipTier > 0 then
        isVip = true
    end

    local freshAccounts = TriggerServerCallback("core:server:getClothesPlayerAccounts")
    local playerMoney = freshAccounts and freshAccounts.cash or getPlayerCash()
    local playerBank = freshAccounts and freshAccounts.bank or 0

    local hasClothingBag = TriggerServerCallback("core:server:hasClothingBag")

    SendNUIMessage({
        action = "clothingshop:open",
        data = {
            shopType = shopType,
            shopName = shopData.Title or "BINCO",
            playerMoney = playerMoney,
            playerBank = playerBank,
            playerSkin = playerSkin,
            isVip = isVip,
            hasClothingBag = hasClothingBag == true
        }
    })
    VFW.Nui.Focus(true, false)
end

local function CloseClothingShop()
    if not isShopOpen then return end

    if isFreeStaffSkinSession then
        isFreeStaffSkinSession = false
        TriggerServerEvent("core:staff:clearFreeSkinSession")
    end

    local wasBarber = (currentShopData and currentShopData.shopType == "barber")
    if isTattooModeActive and savedSkinBeforeTattoo then
        TriggerEvent('skinchanger:loadSkin', savedSkinBeforeTattoo)
        savedSkinBeforeTattoo = nil
        isTattooModeActive = false

        -- Rafraîchir les tatouages depuis le serveur après restauration du skin
        local playerPed = VFW.PlayerData.ped
        if playerPed then
            ClearPedDecorations(playerPed)
            local tattoos = TriggerServerCallback("core:server:getTattoo") or {}
            for _, tattoo in ipairs(tattoos) do
                AddPedDecorationFromHashes(playerPed, tattoo.Collection, tattoo.Hash)
            end
        end
    end
    isShopOpen = false
    IsClothingShopOpen = false
    VFW.Nui.Focus(false)

    SendNUIMessage({
        action = "clothingshop:close",
        data = {}
    })

    VFW.Nui.HudVisible(true)
    DisplayHud(true)

    -- Unfreeze player
    local playerPed = VFW.PlayerData.ped or PlayerPedId()
    FreezeEntityPosition(playerPed, false)

    if currentCamHandle then
        DestroyCam(currentCamHandle, false)
        RenderScriptCams(false, false, 0, true, true)
    end
    currentCamera = nil

    if wasBarber then
        TriggerEvent('vfw_barber:forceExitAnim')
    end

    currentShopData = nil
    currentCameraView = "full"
    currentCamHandle = nil
    camBasePos = nil
    currentFov, targetFov = 50.0, 50.0
    currentCamZ, targetCamZ = 0.0, 0.0
    currentLookZ, targetLookZ = 0.4, 0.4
    TriggerEvent('vfw_interaction:setMenuState', false)
end

local zoneMapping = {
    head = "ZONE_HEAD",
    torso = "ZONE_TORSO",
    leftArm = "ZONE_LEFT_ARM",
    rightArm = "ZONE_RIGHT_ARM",
    leftLeg = "ZONE_LEFT_LEG",
    rightLeg = "ZONE_RIGHT_LEG"
}

local function LoadTattooItems(zoneId)
    local items = {}
    local sex = "Homme"

    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 1 then
            sex = "Femme"
        end
    end)

    local zoneName = zoneMapping[zoneId]
    if not zoneName then
        return {}
    end

    -- Noms lisibles pour les tatouages custom
    local customTattooNames = {
        -- Visage
        customface1 = "Visage Tribal 1", customface2 = "Visage Tribal 2", customface3 = "Visage Tribal 3",
        facefemale1 = "Visage Féminin 1", facefemale2 = "Visage Féminin 2",
        -- Gorge
        customthroat001 = "Gorge 1", customthroat002 = "Gorge 2", customthroat003 = "Gorge 3",
        customthroat004 = "Gorge 4", customthroat005 = "Gorge 5", customthroat006 = "Gorge 6",
        customthroat007 = "Gorge 7", customthroat008 = "Gorge 8",
        throatfemale = "Gorge Féminine",
        -- Bras
        customleftarm = "Manchette Gauche", customrightarm = "Manchette Droite",
        flowersleave1 = "Manchette Fleurs",
        colorful2tonedflowersleave = "Manchette Fleurs Bicolore",
        blackl = "Bras Noir Gauche", blackr = "Bras Noir Droit",
        ghostrider = "Ghost Rider", crushedskull = "Crâne Brisé",
        dimentionalskull = "Crâne Dimensionnel",
        skullsnake = "Crâne Serpent", snake = "Serpent",
        -- Jambes
        customleftleg001 = "Jambe Gauche", customrightleg = "Jambe Droite",
        -- Dos / Vikings
        customback1 = "Dos 1", customback2 = "Dos 2",
        customvikings001 = "Viking 1", customvikings002 = "Viking 2", customvikings003 = "Viking 3",
        customvikings004 = "Viking 4", customvikings005 = "Viking 5", customvikings006 = "Viking 6",
        customvikings007 = "Viking 7", customvikings008 = "Viking 8",
        customvikings010 = "Viking 10", customvikings011 = "Viking 11",
        customvikings012 = "Viking 12", customvikings013 = "Viking 13",
        -- Torse
        customtorso1 = "Torse 1",
        -- Ballas
        ballastattoo_001 = "Ballas 1", ballastattoo_002 = "Ballas 2", ballastattoo_003 = "Ballas 3",
        ballastattoo_004 = "Ballas 4", ballastattoo_005 = "Ballas 5", ballastattoo_006 = "Ballas 6",
        ballastattoo_007 = "Ballas 7", ballastattoo_008 = "Ballas 8", ballastattoo_009 = "Ballas 9",
        ballastattoo_010 = "Ballas 10", ballastattoo_011 = "Ballas 11", ballastattoo_012 = "Ballas 12",
        ballastattoo_013 = "Ballas 13", ballastattoo_014 = "Ballas 14",
        -- Families
        families_001 = "Families 1", families_002 = "Families 2", families_003 = "Families 3",
        families_004 = "Families 4", families_005 = "Families 5", families_006 = "Families 6",
        families_007 = "Families 7", families_008 = "Families 8", families_009 = "Families 9",
        families_010 = "Families 10", families_011 = "Families 11", families_012 = "Families 12",
        families_013 = "Families 13", families_014 = "Families 14",
        -- Féminins
        customfemale_001 = "Féminin 1", customfemale_002 = "Féminin 2", customfemale_003 = "Féminin 3",
        customfemale_004 = "Féminin 4", customfemale_005 = "Féminin 5", customfemale_006 = "Féminin 6",
        customfemale_007 = "Féminin 7", customfemale_008 = "Féminin 8", customfemale_009 = "Féminin 9",
        customfemale_010 = "Féminin 10",
        -- Divers
        custom_swat_tattoo = "SWAT",
        ["50boyz"] = "50 Boyz",
    }

    local function getTattooLabel(tattoo)
        local name = tattoo.Name or ""
        if customTattooNames[name] then
            return customTattooNames[name]
        end
        -- Si le LocalizedName est différent du Name technique, l'utiliser
        if tattoo.LocalizedName and tattoo.LocalizedName ~= name then
            return tattoo.LocalizedName
        end
        -- Fallback: formater le nom technique (retirer underscores, capitaliser)
        local label = name:gsub("_", " "):gsub("(%d+)$", " %1")
        return label:sub(1, 1):upper() .. label:sub(2)
    end

    local tattoos = GetTattoos()
    local getClothesPrice = TriggerServerCallback("core:getClothesPrice", sex)
    for _, tattoo in ipairs(tattoos) do
        if tattoo.Zone == zoneName then
            local hashName = sex == "Femme" and tattoo.HashNameFemale or tattoo.HashNameMale

            if hashName and hashName ~= "" then
                table.insert(items, {
                    id = tattoo.Name,
                    label = getTattooLabel(tattoo),
                    price = getClothesPrice["tattoo"] and getClothesPrice["tattoo"].price or 100,
                    image = "assets/catalogues/tattoo/tattooList/" .. string.lower(tattoo.Img) .. ".png",
                    category = zoneId,
                    drawableId = 0,
                    textureVariations = 1,
                    tattooData = {
                        Collection = tattoo.Collection,
                        HashNameMale = tattoo.HashNameMale,
                        HashNameFemale = tattoo.HashNameFemale,
                        Hash = hashName
                    }
                })
            end
        end
    end

    -- ✨ APLICAR MULTIPLICADOR DE PRECIO
    local priceMultiplier = currentShopData and currentShopData.priceMultiplier or 1.0
    items = ApplyShopPriceMultiplier(items, priceMultiplier)

    return items
end

local function LoadCategoryItems(categoryId)
    local playerPed = VFW.PlayerData.ped or PlayerPedId()
    if not playerPed or playerPed == 0 then
        return {}
    end

    local items = {}
    local sex = "Homme"
    local sexType = "male"

    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 1 then
            sex = "Femme"
            sexType = "female"
        end
    end)


    local getClothesPrice = TriggerServerCallback("core:getClothesPrice", sex)

    -- Les sacs (component 5) sont traités comme toutes les autres catégories de
    -- vêtements : une tuile par drawable via la boucle générique plus bas.
    -- (Auparavant, tous les sacs étaient regroupés en un seul item "Sacs", ce
    -- qui n'affichait qu'une seule carte au lieu de tous les sacs disponibles.)

    if categoryId == "beard" then
        local overlayId = overlayComponents[categoryId]

        table.insert(items, {
            id = -1,
            label = "Aucune barbe",
            price = 0,
            image = VFW.OutfitPlaceholderUrl and VFW.OutfitPlaceholderUrl() or "outfits_greenscreener/aucun.svg",
            category = categoryId,
            drawableId = -1,
            textureVariations = 1
        })

        for i = 0, GetNumHeadOverlayValues(overlayId) - 1 do
            local price = getClothesPrice["beard"].price or 20
            local actualBeardId = i + 1
            table.insert(items, {
                id = i,
                label = string.format("Barbe #%d", i),
                price = price,
                image = string.format("assets/catalogues/barber/%s/Barbes/%d.webp", sex, i),
                category = categoryId,
                drawableId = actualBeardId,
                textureVariations = 64
            })
        end

        -- ✨ APLICAR MULTIPLICADOR DE PRECIO
        local priceMultiplier = currentShopData and currentShopData.priceMultiplier or 1.0
        items = ApplyShopPriceMultiplier(items, priceMultiplier)

        return items
    end

    local drawableType = drawableClothes[categoryId] or drawableProps[categoryId]
    if not drawableType then
        return {}
    end

    local getVariations = drawableClothes[categoryId] and
            GetNumberOfPedDrawableVariations or
            GetNumberOfPedPropDrawableVariations

    local priceName
    if categoryId == "torso2" or categoryId == "undershirt" or categoryId == "torso" then
        priceName = "top"
    elseif categoryId == "leg" then
        priceName = "bottom"
    elseif categoryId == "shoes" then
        priceName = "shoe"
    elseif categoryId == "watch" then
        priceName = "watch"
    elseif categoryId == "necklace" then
        priceName = "necklace"
    elseif categoryId == "earring" then
        priceName = "earring"
    elseif categoryId == "bracelet" then
        priceName = "bracelet"
    elseif categoryId == "mask" then
        priceName = "mask"
    elseif categoryId == "hair" then
        priceName = "hair"
    elseif categoryId == "decals" then
        priceName = "decals"
    else
        priceName = categoryId
    end

    for i = 0, getVariations(playerPed, drawableType) - 1 do
        local shouldInclude = true

        if Config.ClothesBan and Config.ClothesBan[sex] then
            local banKey = banKeys[categoryId] or ("Ban" .. priceName:sub(1,1):upper() .. priceName:sub(2))
            local bannedClothes = Config.ClothesBan[sex][banKey] or (Config.BarberBan and Config.BarberBan[sex] and Config.BarberBan[sex][banKey]) or {}
            shouldInclude = not VFW.Table.TableContains(bannedClothes, i)
        end

        -- 🔥 FIX ICI : Bloquer spécifiquement le masque 73
        if categoryId == "mask" and i == 73 then
            shouldInclude = false
        end
        -- FIN DU FIX

        if shouldInclude then
            local priceMultiplier = currentShopData and currentShopData.priceMultiplier or 1.0
            local price = GetCategoryPrice(sex, categoryId, getClothesPrice, priceMultiplier)
            local imagePath

            -- Table de mapping categoryId → nom de dossier GitHub
            local imageFolderMapping = {
                necklace = "accessory",
                earring = "ear",
                bag = "bags",
                kevlar = "armor",
                armor = "armor",
                body_armor = "armor",
            }

            -- Obtenir le nom de dossier correct (ou utiliser categoryId par défaut)
            local folderName = imageFolderMapping[categoryId] or categoryId

            if categoryId == "hair" then
                imagePath = string.format("assets/catalogues/barber/%s/Coupes/%d.webp", sex, i)
            elseif drawableClothes[categoryId] then
                imagePath = VFW.OutfitImage(sexType, "clothing", folderName, i, 0)
            else
                imagePath = VFW.OutfitImage(sexType, "props", folderName, i, 0)
            end

            local getTextureVariations = drawableClothes[categoryId] and
                    GetNumberOfPedTextureVariations or
                    GetNumberOfPedPropTextureVariations
            local textureCount = getTextureVariations(playerPed, drawableType, i)

            if textureCount > 0 then
                local categoryName = categoryLabels[categoryId] or categoryId
                table.insert(items, {
                    id = i,
                    label = string.format("%s #%d", categoryName, i),
                    price = price,
                    image = imagePath,
                    category = categoryId,
                    drawableId = i,
                    textureVariations = textureCount
                })
            end
        end
    end

    -- ✨ APLICAR MULTIPLICADOR DE PRECIO
    local priceMultiplier = currentShopData and currentShopData.priceMultiplier or 1.0
    items = ApplyShopPriceMultiplier(items, priceMultiplier)

    return items
end

-- [RESTO DEL CÓDIGO SIN CAMBIOS - continúa con LoadItemVariants, PreviewClothing, etc...]
local function LoadItemVariants(categoryId, itemId)
    local playerPed = VFW.PlayerData.ped
    if not playerPed then return {} end

    local variants = {}
    local sex = "Homme"
    local sexType = "male"

    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 1 then
            sex = "Femme"
            sexType = "female"
        end
    end)

    local drawableType = drawableClothes[categoryId] or drawableProps[categoryId]
    if not drawableType then return {} end

    local getVariations = drawableClothes[categoryId] and
            GetNumberOfPedTextureVariations or
            GetNumberOfPedPropTextureVariations

    for i = 0, getVariations(playerPed, drawableType, itemId) - 1 do
        local variantFolder = ({ necklace = "accessory", earring = "ear", bag = "bags", kevlar = "armor", armor = "armor" })[categoryId] or categoryId
        local imagePath = VFW.OutfitImage(sexType, drawableClothes[categoryId] and "clothing" or "props", variantFolder, itemId, i)

        table.insert(variants, {
            id = i,
            label = "Couleur " .. (i + 1),
            image = imagePath
        })
    end

    return variants
end

local function PreviewClothing(categoryId, itemId, variant, color, opacity)
    local sex = "Homme"
    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 1 then
            sex = "Femme"
        end
    end)

    if categoryId == "torso2" then
        TriggerEvent("skinchanger:change", "torso_1", itemId)
        TriggerEvent("skinchanger:change", "torso_2", variant or 0)
        if Config.ClothsList and Config.ClothsList[sex] and Config.ClothsList[sex]["Haut"][tostring(itemId)] then
            TriggerEvent("skinchanger:change", "arms", Config.ClothsList[sex]["Haut"][tostring(itemId)])
            TriggerEvent("skinchanger:change", "arms_2", 0)
        end
    elseif categoryId == "undershirt" then
        TriggerEvent("skinchanger:change", "tshirt_1", itemId)
        TriggerEvent("skinchanger:change", "tshirt_2", variant or 0)
    elseif categoryId == "torso" then
        TriggerEvent("skinchanger:change", "arms", itemId)
        TriggerEvent("skinchanger:change", "arms_2", variant or 0)
    elseif categoryId == "leg" then
        TriggerEvent("skinchanger:change", "pants_1", itemId)
        TriggerEvent("skinchanger:change", "pants_2", variant or 0)
    elseif categoryId == "shoes" then
        TriggerEvent("skinchanger:change", "shoes_1", itemId)
        TriggerEvent("skinchanger:change", "shoes_2", variant or 0)
    elseif categoryId == "hat" then
        TriggerEvent("skinchanger:change", "helmet_1", itemId)
        TriggerEvent("skinchanger:change", "helmet_2", variant or 0)
    elseif categoryId == "glasses" then
        TriggerEvent("skinchanger:change", "glasses_1", itemId)
        TriggerEvent("skinchanger:change", "glasses_2", variant or 0)
    elseif categoryId == "bag" then
        TriggerEvent("skinchanger:change", "bags_1", itemId)
        TriggerEvent("skinchanger:change", "bags_2", variant or 0)
    elseif categoryId == "watch" then
        TriggerEvent("skinchanger:change", "watches_1", itemId)
        TriggerEvent("skinchanger:change", "watches_2", variant or 0)
    elseif categoryId == "necklace" then
        TriggerEvent("skinchanger:change", "chain_1", itemId)
        TriggerEvent("skinchanger:change", "chain_2", variant or 0)
    elseif categoryId == "earring" then
        TriggerEvent("skinchanger:change", "ears_1", itemId)
        TriggerEvent("skinchanger:change", "ears_2", variant or 0)
    elseif categoryId == "bracelet" then
        TriggerEvent("skinchanger:change", "bracelets_1", itemId)
        TriggerEvent("skinchanger:change", "bracelets_2", variant or 0)
    elseif categoryId == "mask" then
        TriggerEvent("skinchanger:change", "mask_1", itemId)
        TriggerEvent("skinchanger:change", "mask_2", variant or 0)
    elseif categoryId == "hair" then
        TriggerEvent("skinchanger:change", "hair_1", itemId)
        TriggerEvent("skinchanger:change", "hair_2", variant or 0)
        if color then
            TriggerEvent("skinchanger:change", "hair_color_1", color)
            TriggerEvent("skinchanger:change", "hair_color_2", color)
        end
    elseif categoryId == "beard" then
        if itemId == -1 then
            TriggerEvent("skinchanger:change", "beard_1", -1)
        else
            -- Mettre à jour tous les champs barbe d'un coup via getSkin pour éviter
            -- un ApplySkin intermédiaire avec l'ancienne opacité (qui cause le reset visuel)
            TriggerEvent('skinchanger:getSkin', function(skin)
                skin["beard_1"] = itemId
                skin["beard_2"] = opacity or 10
                skin["beard_3"] = color or 0
                skin["beard_4"] = color or 0
                TriggerEvent('skinchanger:loadSkin', skin)
            end)
        end
    elseif categoryId == "kevlar" or categoryId == "armor" then
        TriggerEvent("skinchanger:change", "bproof_1", itemId)
        TriggerEvent("skinchanger:change", "bproof_2", variant or 0)
    elseif categoryId == "decals" or categoryId == "decal" then
        TriggerEvent("skinchanger:change", "decals_1", itemId)
        TriggerEvent("skinchanger:change", "decals_2", variant or 0)
    elseif categoryId == "arms" then
        TriggerEvent("skinchanger:change", "arms", itemId)
        TriggerEvent("skinchanger:change", "arms_2", variant or 0)
    elseif categoryId == "accessory" then
        TriggerEvent("skinchanger:change", "chain_1", itemId)
        TriggerEvent("skinchanger:change", "chain_2", variant or 0)
    elseif categoryId == "ear" then
        TriggerEvent("skinchanger:change", "ears_1", itemId)
        TriggerEvent("skinchanger:change", "ears_2", variant or 0)
    end
end

-- ============================================================================
-- SLIDER CALLBACKS - Nouveau système de navigation par sliders
-- ============================================================================

-- Retourne les infos d'une catégorie pour les sliders (max drawable, textures, bans)
RegisterNUICallback("clothingshop:getCategoryInfo", function(data, cb)
    local categoryId = data.category
    local playerPed = VFW.PlayerData.ped or PlayerPedId()
    if not playerPed or playerPed == 0 then
        cb({ maxDrawableId = 0, currentDrawableId = 0, currentTextureId = 0, maxTextureId = 0, bannedDrawables = {}, price = 0 })
        return
    end

    local sex = "Homme"
    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 1 then sex = "Femme" end
    end)

    local getClothesPrice = TriggerServerCallback("core:getClothesPrice", sex)
    local priceMultiplier = currentShopData and currentShopData.priceMultiplier or 1.0

    -- Cas spécial: beard est un overlay, pas un drawable/prop
    if categoryId == "beard" then
        local maxBeardId = GetNumHeadOverlayValues(1) - 1
        local currentBeardId = 0
        TriggerEvent('skinchanger:getSkin', function(skin)
            local b = skin and skin.beard_1 or 0
            currentBeardId = b == -1 and 0 or b
        end)
        local beardPrice = math.floor((getClothesPrice["beard"] and getClothesPrice["beard"].price or 20) * priceMultiplier)
        cb({
            maxDrawableId = maxBeardId,
            currentDrawableId = currentBeardId,
            currentTextureId = 0,
            maxTextureId = 0,
            bannedDrawables = {},
            price = beardPrice
        })
        return
    end

    -- Déterminer le type (drawable ou prop)
    local isDrawable = drawableClothes[categoryId] ~= nil
    local componentId = drawableClothes[categoryId] or drawableProps[categoryId]

    if not componentId then
        cb({ maxDrawableId = 0, currentDrawableId = 0, currentTextureId = 0, maxTextureId = 0, bannedDrawables = {}, price = 0 })
        return
    end

    local getVariations = isDrawable and GetNumberOfPedDrawableVariations or GetNumberOfPedPropDrawableVariations
    local getTextures = isDrawable and GetNumberOfPedTextureVariations or GetNumberOfPedPropTextureVariations
    local getCurrent = isDrawable and GetPedDrawableVariation or GetPedPropIndex
    local getCurrentTexture = isDrawable and GetPedTextureVariation or GetPedPropTextureIndex

    local maxDrawable = getVariations(playerPed, componentId) - 1
    local currentDrawable = getCurrent(playerPed, componentId)
    local currentTexture = getCurrentTexture(playerPed, componentId)
    local maxTexture = getTextures(playerPed, componentId, currentDrawable) - 1

    -- Construire la liste des drawables bannis
    local bannedDrawables = {}
    if Config.ClothesBan and Config.ClothesBan[sex] then
        local banPriceName
        if categoryId == "torso2" or categoryId == "undershirt" or categoryId == "torso" then
            banPriceName = "top"
        elseif categoryId == "leg" then
            banPriceName = "bottom"
        elseif categoryId == "shoes" then
            banPriceName = "shoe"
        else
            banPriceName = categoryId
        end
        local banKey = banKeys[categoryId] or ("Ban" .. banPriceName:sub(1,1):upper() .. banPriceName:sub(2))
        local bannedList = Config.ClothesBan[sex][banKey] or (Config.BarberBan and Config.BarberBan[sex] and Config.BarberBan[sex][banKey]) or {}
        for _, v in ipairs(bannedList) do
            bannedDrawables[#bannedDrawables + 1] = v
        end
    end
    -- Masque 73 toujours banni
    if categoryId == "mask" then
        bannedDrawables[#bannedDrawables + 1] = 73
    end

    -- Tronquer maxDrawable au dernier drawable non-banni :
    -- évite l'affichage "X / 143" alors que 111-143 sont tous bannis (le slider loop à 0).
    local bannedSet = {}
    for _, v in ipairs(bannedDrawables) do bannedSet[v] = true end
    while maxDrawable >= 0 and bannedSet[maxDrawable] do
        maxDrawable = maxDrawable - 1
    end

    local price = GetCategoryPrice(sex, categoryId, getClothesPrice, priceMultiplier)

    -- Poids du sac (si catégorie bag)
    local bagWeight = nil
    if categoryId == "bag" then
        local bagSex = sex == "Femme" and "f" or "m"
        local serverWeight = TriggerServerCallback("bagweight:getWeightForDrawable", bagSex, currentDrawable)
        bagWeight = serverWeight or 10
    end

    cb({
        maxDrawableId = maxDrawable,
        currentDrawableId = currentDrawable,
        currentTextureId = currentTexture,
        maxTextureId = math.max(maxTexture, 0),
        bannedDrawables = bannedDrawables,
        price = price,
        bagWeight = bagWeight
    })
end)

-- Retourne le nombre de textures pour un drawable donné
RegisterNUICallback("clothingshop:getTextureCount", function(data, cb)
    local categoryId = data.category
    local drawableId = data.drawableId
    local playerPed = VFW.PlayerData.ped or PlayerPedId()
    if not playerPed or playerPed == 0 then
        cb({ maxTextureId = 0 })
        return
    end

    local sex = "Homme"
    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 1 then sex = "Femme" end
    end)
    local getClothesPrice = TriggerServerCallback("core:getClothesPrice", sex)
    local priceMultiplier = currentShopData and currentShopData.priceMultiplier or 1.0
    local price = GetCategoryPrice(sex, categoryId, getClothesPrice, priceMultiplier)

    -- Beard et hair n'ont pas de variantes de texture
    if categoryId == "beard" or categoryId == "hair" then
        cb({ maxTextureId = 0, price = price })
        return
    end

    local isDrawable = drawableClothes[categoryId] ~= nil
    local componentId = drawableClothes[categoryId] or drawableProps[categoryId]

    if not componentId then
        cb({ maxTextureId = 0 })
        return
    end

    local getTextures = isDrawable and GetNumberOfPedTextureVariations or GetNumberOfPedPropTextureVariations
    local count = getTextures(playerPed, componentId, drawableId)

    -- Poids du sac si catégorie bag
    local bagWeight = nil
    if categoryId == "bag" then
        local sex = "Homme"
        TriggerEvent('skinchanger:getSkin', function(skin)
            if skin.sex == 1 then sex = "Femme" end
        end)
        local bagSex = sex == "Femme" and "f" or "m"
        local serverWeight = TriggerServerCallback("bagweight:getWeightForDrawable", bagSex, drawableId)
        bagWeight = serverWeight or 10
    end

    cb({ maxTextureId = math.max(count - 1, 0), bagWeight = bagWeight, price = price })
end)

-- Appliquer un item gratuit (bras) directement sur le skin sans achat
RegisterNUICallback("clothingshop:applyFreeItem", function(data, cb)
    local categoryId = data.category
    local drawableId = data.drawableId
    local variantId = data.variantId or 0

    -- Session staff /skin : tout est gratuit côté serveur, on route à travers le flow
    -- d'achat complet pour que l'item soit ajouté à l'inventaire et que le skin soit sauvegardé.
    if isFreeStaffSkinSession then
        ProcessClothePurchase({
            category = categoryId,
            drawableId = drawableId,
            variantId = variantId,
            label = categoryId,
            price = 0,
        }, 'cash', cb)
        return
    end

    -- Appliquer visuellement
    PreviewClothing(categoryId, drawableId, variantId)

    -- Sauvegarder sur le skin du joueur + ajouter l'item "arms" gratuit en inventaire
    if categoryId == "torso" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            skin["arms"] = drawableId
            skin["arms_2"] = variantId
            TriggerServerEvent("vfw:skin:save", skin)

            TriggerServerEvent("core:server:applyFreeArms", {
                id = drawableId,
                var = variantId,
                sex = (skin.sex == 1) and "w" or "m",
                renamed = "Bras",
                type = "arms",
                clothesSlotType = "arms",
            })
        end)
    end

    if clothingClonePed then
        SyncClothingClone()
    end

    cb({ success = true })
end)

-- ============================================================================
-- LEGACY CALLBACKS (grille pour tattoo/mask/barber)
-- ============================================================================
RegisterNUICallback("clothingshop:selectCategory", function(data, cb)
    local categoryId = data.category
    local items = {}
    local ownedTattoos = {}
    local shopType = currentShopData and currentShopData.shopType or "clothing"

    if shopType == "tattoo" and zoneMapping[categoryId] then
        -- Adjust camera per tattoo zone
        local tattooZoneCam = {
            head     = "head",
            torso    = "upper",
            leftArm  = "upper",
            rightArm = "upper",
            leftLeg  = "feet",
            rightLeg = "feet",
        }
        local view = tattooZoneCam[categoryId] or "full"
        local viewData = CAMERA_VIEWS[view]
        if viewData then
            currentCameraView = view
            targetCamZ  = viewData.camZ
            targetLookZ = viewData.lookZ
            targetFov   = viewData.fov
        end

        items = LoadTattooItems(categoryId)

        local allTattoos = TriggerServerCallback("core:server:getTattoo") or {}
        local zoneName = zoneMapping[categoryId]

        for _, tattoo in ipairs(allTattoos) do
            for _, item in ipairs(items) do
                if item.tattooData and item.tattooData.Collection == tattoo.Collection and item.tattooData.Hash == tattoo.Hash then
                    table.insert(ownedTattoos, {
                        id = item.id,
                        label = item.label,
                        category = categoryId,
                        tattooData = tattoo,
                        image = item.image  -- ✨ AGREGAR CAMPO IMAGE PARA QUE APAREZCAN LAS IMÁGENES
                    })
                    break
                end
            end
        end
    else
        items = LoadCategoryItems(categoryId)
    end

    SendNUIMessage({
        action = "clothingshop:loadItems",
        data = {
            category = categoryId,
            items = items,
            ownedTattoos = ownedTattoos
        }
    })

    cb("ok")
end)

-- Fonction helper pour convertir un index global en drawable+texture pour les items groupés
local function GetDrawableAndTextureFromGlobalIndex(drawableList, globalIndex)
    local currentIndex = 0
    for _, entry in ipairs(drawableList) do
        if globalIndex < currentIndex + entry.textureCount then
            return entry.drawableId, globalIndex - currentIndex
        end
        currentIndex = currentIndex + entry.textureCount
    end
    -- Fallback: retourner le premier drawable avec texture 0
    if drawableList[1] then
        return drawableList[1].drawableId, 0
    end
    return 0, 0
end

RegisterNUICallback("clothingshop:previewItem", function(data, cb)
    local shopType = currentShopData and currentShopData.shopType or "clothing"

    if shopType == "tattoo" and zoneMapping[data.category] then
        local playerPed = VFW.PlayerData.ped
        if not playerPed then
            cb({ textureVariations = 0 })
            return
        end

        ClearPedDecorations(playerPed)

        local currentTattoos = TriggerServerCallback("core:server:getTattoo") or {}
        for _, tattoo in ipairs(currentTattoos) do
            ApplyPedOverlay(playerPed, joaat(tattoo.Collection), joaat(tattoo.Hash))
        end

        if data.tattooData then
            previewTattoo = data.tattooData
            ApplyPedOverlay(playerPed, joaat(data.tattooData.Collection), joaat(data.tattooData.Hash))
        else
            previewTattoo = nil
        end

        -- Sync tattoos to clone
        if clothingClonePed and DoesEntityExist(clothingClonePed) then
            ClearPedDecorations(clothingClonePed)
            for _, tattoo in ipairs(currentTattoos) do
                ApplyPedOverlay(clothingClonePed, joaat(tattoo.Collection), joaat(tattoo.Hash))
            end
            if previewTattoo then
                ApplyPedOverlay(clothingClonePed, joaat(previewTattoo.Collection), joaat(previewTattoo.Hash))
            end
        end
        cb({ textureVariations = 0 })
    else
        -- Gérer les items groupés (avec drawableList)
        local itemId = data.itemId
        local variant = data.variant or 0

        if data.drawableList and #data.drawableList > 0 then
            -- Convertir l'index global en drawable+texture
            itemId, variant = GetDrawableAndTextureFromGlobalIndex(data.drawableList, data.variant or 0)
        end

        PreviewClothing(data.category, itemId, variant, data.color, data.opacity)

        -- Attendre 1 tick pour que skinchanger applique le changement
        Citizen.Wait(0)

        -- Sync to clone
        SyncClothingClone()

        -- Récupérer le vrai nombre de textures maintenant que le drawable est appliqué
        local playerPed = VFW.PlayerData.ped
        local drawableType = drawableClothes[data.category]
        local textureVariations = 1

        if playerPed and drawableType then
            textureVariations = GetNumberOfPedTextureVariations(playerPed, drawableType, itemId)
        end

        cb({ textureVariations = textureVariations })
    end
end)

-- ============================================================================
-- TOP WIZARD - Chargement des items pour le wizard (undershirt, arms)
-- ============================================================================
RegisterNUICallback("clothingshop:loadWizardItems", function(data, cb)
    local category = data.category

    if category ~= "undershirt" and category ~= "torso" then
        cb({ items = {} })
        return
    end

    local items = LoadCategoryItems(category)

    cb({ items = items })
end)

-- ============================================================================
-- TOP WIZARD - Preview composite (top + undershirt + arms)
-- ============================================================================
RegisterNUICallback("clothingshop:previewCompositeTop", function(data, cb)
    -- data = { topId, topVariant, undershirtId, undershirtVariant, armsId, armsVariant }

    -- Preview Top (torso)
    if data.topId then
        TriggerEvent("skinchanger:change", "torso_1", data.topId)
        TriggerEvent("skinchanger:change", "torso_2", data.topVariant or 0)
    end

    -- Preview Undershirt
    if data.undershirtId then
        TriggerEvent("skinchanger:change", "tshirt_1", data.undershirtId)
        TriggerEvent("skinchanger:change", "tshirt_2", data.undershirtVariant or 0)
    end

    -- Preview Arms
    if data.armsId then
        TriggerEvent("skinchanger:change", "arms", data.armsId)
        TriggerEvent("skinchanger:change", "arms_2", data.armsVariant or 0)
    end

    cb("ok")
end)

RegisterNUICallback("clothingshop:purchase", function(data, cb)
    local success = false

    TriggerEvent('skinchanger:getSkin', function(skin)
        local itemName
        local metadata

        if data.category == "torso2" then
            itemName = "top"
            metadata = {
                renamed = "Haut",
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "shirt",
                skin = {
                    ["tshirt_1"] = skin.tshirt_1,
                    ["tshirt_2"] = skin.tshirt_2,
                    ["torso_1"] = skin.torso_1,
                    ["torso_2"] = skin.torso_2,
                    ["arms"] = skin.arms,
                    ["arms_2"] = skin.arms_2,
                }
            }
        elseif data.category == "undershirt" then
            itemName = "top"
            metadata = {
                renamed = "Tshirt",
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "shirt",
                type = "undershirt",
                skin = {
                    ["tshirt_1"] = skin.tshirt_1,
                    ["tshirt_2"] = skin.tshirt_2,
                }
            }
        elseif data.category == "torso" then
            -- Bras = changement permanent du skin, sauvegarder directement
            TriggerServerEvent("vfw:skin:save", skin)
            success = true
            TriggerEvent("nui:bigmenu:notify", "vert", "Bras appliqués", "")
        end

        if data.category == "leg" then
            itemName = "bottom"
            metadata = {
                renamed = skin.pants_1,
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "pants",
                id = skin.pants_1,
                var = skin.pants_2,
            }
        elseif data.category == "shoes" then
            itemName = "shoe"
            metadata = {
                renamed = skin.shoes_1,
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "shoes",
                id = skin.shoes_1,
                var = skin.shoes_2,
            }
        elseif data.category == "hat" then
            itemName = "hat"
            metadata = {
                renamed = skin.helmet_1,
                type = "hat",
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "hat",
                id = data.itemId,
                var = data.variantId,
            }
        elseif data.category == "glasses" then
            itemName = "accessory"
            metadata = {
                renamed = skin.glasses_1,
                type = "glasses",
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "glasses",
                id = data.itemId,
                var = data.variantId,
            }
        elseif data.category == "bag" then
            itemName = "accessory"
            metadata = {
                renamed = skin.bags_1,
                type = "bag",
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "bag",
                id = data.itemId,
                var = data.variantId,
            }
        elseif data.category == "watch" then
            itemName = "accessory"
            metadata = {
                renamed = skin.watches_1,
                type = "watch",
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "watch",
                id = skin.watches_1,
                var = skin.watches_2,
            }
        elseif data.category == "necklace" then
            itemName = "accessory"
            metadata = {
                renamed = skin.chain_1,
                type = "necklace",
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "necklace",
                id = skin.chain_1,
                var = skin.chain_2,
            }
        elseif data.category == "earring" then
            itemName = "accessory"
            metadata = {
                renamed = skin.ears_1,
                type = "earring",
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "earring",
                id = skin.ears_1,
                var = skin.ears_2,
            }
        elseif data.category == "bracelet" then
            itemName = "accessory"
            metadata = {
                renamed = skin.bracelets_1,
                type = "bracelet",
                sex = skin.sex == 1 and "w" or "m",
                clothesSlotType = "bracelet",
                id = skin.bracelets_1,
                var = skin.bracelets_2,
            }
        end

        if itemName then
            success = TriggerServerCallback("core:server:buyClothe", itemName, metadata, false, false)

            if success then
                SendNUIMessage({
                    action = "clothingshop:updateMoney",
                    data = {
                        money = getPlayerCash()
                    }
                })
            end
        end
    end)

    cb(success)
end)

ProcessClothePurchase = function(item, paymentMethod, cb)
    if not item then
        cb(false)
        return
    end

    paymentMethod = paymentMethod or 'cash'

    local category = item.category

    -- ============================================================================
    -- COMPOSITE TOP ITEM (from wizard: top + undershirt + arms)
    -- ============================================================================
    if item.isComposite and item.components then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
        local components = item.components

        local metadata = {
            renamed = components.top and components.top.label or "Haut",
            sex = (skin and skin.sex == 1) and "w" or "m",
            clothesSlotType = "shirt",
            skin = {
                ["torso_1"] = components.top and components.top.drawableId or 0,
                ["torso_2"] = components.top and components.top.variantId or 0,
                ["tshirt_1"] = components.undershirt and components.undershirt.drawableId or 0,
                ["tshirt_2"] = components.undershirt and components.undershirt.variantId or 0,
                ["arms"] = components.arms and components.arms.drawableId or 0,
                ["arms_2"] = components.arms and components.arms.variantId or 0,
            }
        }

        local success = TriggerServerCallback("core:server:buyClothe", "top", metadata, false, paymentMethod)
        cb(success)
        return
    end

    if zoneMapping[category] then
        if item.tattooData then
            local success = TriggerServerCallback("core:server:buyTattoo", {
                collection = item.tattooData.Collection,
                overlay = item.tattooData.Hash,
                zone = category,
                action = "on"
            }, paymentMethod)
            cb({ success = success == true })
            return
        end
    end

    if category == "hair" or category == "beard" or category == "decals" then
        local getMoney = TriggerServerCallback("core:server:getClothesMoney", category, paymentMethod)
        if getMoney then
            TriggerEvent("skinchanger:getSkin", function(currentSkin)
                TriggerServerEvent("vfw:skin:save", currentSkin)
                TriggerEvent('skinchanger:loadSkin', currentSkin or {})
            end)
        end
        cb({ success = getMoney == true })
        return
    end

    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

    -- Résoudre le drawable et texture pour les items groupés (ex: sacs)
    local resolvedDrawableId = item.drawableId
    local resolvedVariantId = item.variantId or 0

    if item.drawableList and #item.drawableList > 0 then
        local globalIndex = item.variantId or 0
        resolvedDrawableId, resolvedVariantId = GetDrawableAndTextureFromGlobalIndex(item.drawableList, globalIndex)
    end

    local itemName = nil
    local metadata = {
        id = resolvedDrawableId,
        var = resolvedVariantId,
        sex = (skin and skin.sex == 1) and "w" or "m",
        renamed = item.label or "Accesorio"
    }

    if category == "torso2" then
        itemName = "top"
        metadata.renamed = "Haut"
        metadata.clothesSlotType = "shirt"
        -- Utiliser les valeurs achetées pour torso, garder tshirt/arms du skin actuel
        local armsId = skin.arms or 15
        local armsVar = skin.arms_2 or 0
        if Config.ClothsList then
            local sexName = (skin and skin.sex == 1) and "Femme" or "Homme"
            if Config.ClothsList[sexName] and Config.ClothsList[sexName]["Haut"] and Config.ClothsList[sexName]["Haut"][tostring(resolvedDrawableId)] then
                armsId = Config.ClothsList[sexName]["Haut"][tostring(resolvedDrawableId)]
                armsVar = 0
            end
        end
        metadata.skin = {
            ["torso_1"] = resolvedDrawableId,
            ["torso_2"] = resolvedVariantId,
            ["tshirt_1"] = skin.tshirt_1 or 15,
            ["tshirt_2"] = skin.tshirt_2 or 0,
            ["arms"] = armsId,
            ["arms_2"] = armsVar,
        }
        metadata.id = nil
        metadata.var = nil
    elseif category == "undershirt" then
        itemName = "top"
        metadata.renamed = "Tshirt"
        metadata.clothesSlotType = "shirt"
        metadata.type = "undershirt"
        metadata.skin = {
            ["tshirt_1"] = resolvedDrawableId,
            ["tshirt_2"] = resolvedVariantId,
        }
        metadata.id = nil
        metadata.var = nil
    elseif category == "torso" then
        -- Bras = appliqué gratuitement via applyFreeItem (pas d'achat)
        local getMoney = TriggerServerCallback("core:server:getClothesMoney", "top", paymentMethod)
        if getMoney then
            TriggerEvent("skinchanger:change", "arms", resolvedDrawableId)
            TriggerEvent("skinchanger:change", "arms_2", resolvedVariantId)
            TriggerEvent('skinchanger:getSkin', function(currentSkin)
                currentSkin["arms"] = resolvedDrawableId
                currentSkin["arms_2"] = resolvedVariantId
                TriggerServerEvent("vfw:skin:save", currentSkin)
            end)
        end
        cb({ success = getMoney == true })
        return
    elseif category == "leg" then
        itemName = "bottom"
        metadata.clothesSlotType = "pants"
    elseif category == "shoes" then
        itemName = "shoe"
        metadata.clothesSlotType = "shoes"
    elseif category == "mask" then
        itemName = "accessory"
        metadata.type = "mask"
        metadata.clothesSlotType = "mask"
    elseif category == "hat" then
        itemName = "hat"
        metadata.type = "hat"
    elseif category == "glasses" then
        itemName = "accessory"
        metadata.type = "glasses"
    elseif category == "bag" then
        itemName = "accessory"
        metadata.type = "bag"
    elseif category == "watch" then
        itemName = "accessory"
        metadata.type = "watch"
        metadata.clothesSlotType = "watch"
    elseif category == "necklace" then
        itemName = "accessory"
        metadata.type = "necklace"
        metadata.clothesSlotType = "necklace"
    elseif category == "earring" then
        itemName = "accessory"
        metadata.type = "earring"
        metadata.clothesSlotType = "earring"
    elseif category == "bracelet" then
        itemName = "accessory"
        metadata.type = "bracelet"
        metadata.clothesSlotType = "bracelet"
    elseif category == "kevlar" then
        itemName = "accessory"
        metadata.type = "kevlar"
        metadata.clothesSlotType = "body_armor"
    end

    local result = { success = false, error = "Article non reconnu" }
    if itemName then
        result = TriggerServerCallback("core:server:buyClothe", itemName, metadata, false, paymentMethod) or { success = false, error = "Action impossible pour le moment" }
    end

    cb(result)
end

RegisterNUICallback("clothingshop:purchaseSingleItem", function(data, cb)
    ProcessClothePurchase(data.item, data.paymentMethod, cb)
end)

RegisterNUICallback("clothingshop:removeTattoo", function(data, cb)
    local success = false
    local tattooData = data.tattooData

    if not tattooData or not tattooData.Collection or not tattooData.Hash then
        cb(false)
        return
    end

    local currentTattoos = TriggerServerCallback("core:server:getTattoo") or {}

    local found = false
    for i, existingTattoo in ipairs(currentTattoos) do
        if existingTattoo.Collection == tattooData.Collection and existingTattoo.Hash == tattooData.Hash then
            found = true
            break
        end
    end

    if not found then
        cb(false)
        return
    end

    TriggerServerEvent("core:server:removeTattoo", tattooData.Collection, tattooData.Hash)

    success = true

    cb(success)
end)

RegisterNUICallback("clothingshop:purchaseOutfit", function(data, cb)
    local success = false
    local outfit = data.outfit
    local totalPrice = data.totalPrice
    local paymentMethod = data.paymentMethod or 'cash'

    if currentShopData and currentShopData.shopType == "tattoo" then
        for _, item in ipairs(outfit) do
            if item.tattooData then
                local ok = TriggerServerCallback("core:server:buyTattoo", {
                    collection = item.tattooData.Collection,
                    overlay   = item.tattooData.Hash,
                    zone      = item.category,
                    action    = "on"
                }, paymentMethod)

                if ok then
                    success = true
                else
                    success = false
                    break
                end
            end
        end

        if success then
            SendNUIMessage({
                action = "clothingshop:updateMoney",
                data = {
                    money = getPlayerCash()
                }
            })
        end

        cb(success)
        return
    end

    local playerFunds = paymentMethod == 'cash' and getPlayerCash()
    if paymentMethod == 'bank' and VFW.PlayerData.accounts then
        for _, account in ipairs(VFW.PlayerData.accounts) do
            if account.name == 'bank' then
                playerFunds = account.money
                break
            end
        end
    end

    if playerFunds < totalPrice then
        cb(false)
        return
    end

    TriggerEvent('skinchanger:getSkin', function(skin)
        local metadata = {
            renamed = "Tenue",
            sex = skin.sex == 1 and "w" or "m",
            clothesSlotType = "outfit",
            skin = {
                ["tshirt_1"]    = skin.tshirt_1,
                ["tshirt_2"]    = skin.tshirt_2,
                ["torso_1"]     = skin.torso_1,
                ["torso_2"]     = skin.torso_2,
                ["arms"]        = skin.arms,
                ["arms_2"]      = skin.arms_2,
                ["pants_1"]     = skin.pants_1,
                ["pants_2"]     = skin.pants_2,
                ["shoes_1"]     = skin.shoes_1,
                ["shoes_2"]     = skin.shoes_2,
                ["helmet_1"]    = skin.helmet_1,
                ["helmet_2"]    = skin.helmet_2,
                ["glasses_1"]   = skin.glasses_1,
                ["glasses_2"]   = skin.glasses_2,
                ["bags_1"]      = skin.bags_1,
                ["bags_2"]      = skin.bags_2,
                ["chain_1"]     = skin.chain_1,
                ["chain_2"]     = skin.chain_2,
                ["decals_1"]    = skin.decals_1,
                ["decals_2"]    = skin.decals_2,
                ["bracelets_1"] = skin.bracelets_1,
                ["bracelets_2"] = skin.bracelets_2,
                ["watches_1"]   = skin.watches_1,
                ["watches_2"]   = skin.watches_2,
                ["ears_1"]      = skin.ears_1,
                ["ears_2"]      = skin.ears_2,
                ["mask_1"]      = skin.mask_1,
                ["mask_2"]      = skin.mask_2,
                ["bproof_1"]    = skin.bproof_1,
                ["bproof_2"]    = skin.bproof_2,
            }
        }

        success = TriggerServerCallback("core:server:buyOutfit", metadata, paymentMethod)

        if success then
            SendNUIMessage({
                action = "clothingshop:updateMoney",
                data = {
                    money = getPlayerCash()
                }
            })
        end

        cb(success)
    end)
end)


RegisterNUICallback("clothingshop:saveOutfit", function(data, cb)
    local outfitName = data.outfitName or "Ma Tenue"
    local outfitItems = data.outfit or {}
    local totalPrice = data.totalPrice or 0

    if #outfitItems == 0 then
        cb(false)
        return
    end

    local success, outfitId = TriggerServerCallback("core:server:saveOutfit", outfitName, outfitItems, totalPrice)

    cb(success)
end)

RegisterNUICallback("clothingshop:loadOutfits", function(data, cb)
    local outfitType = data.type or "private"

    local outfits = TriggerServerCallback("core:server:loadOutfits", outfitType)

    if not outfits then
        outfits = {}
    end

    SendNUIMessage({
        action = "clothingshop:loadOutfits",
        data = {
            outfits = outfits
        }
    })

    cb("ok")
end)

RegisterNUICallback("clothingshop:equipOutfit", function(data, cb)
    local outfitId = data.outfitId

    local success, outfitData = TriggerServerCallback("core:server:equipOutfit", outfitId)

    if success and outfitData then
        local bagItem
        for _, item in ipairs(outfitData) do
            PreviewClothing(item.category, item.drawableId, item.variantId)
            if item.category == "bag" and item.drawableId and item.drawableId > 0 then
                bagItem = item
            end
        end

        TriggerServerEvent("vfw:bag:removeWeightBonus")
        if bagItem then
            local skin = GetPlayerCurrentSkin()
            local sex = (skin and skin.sex == 1) and "w" or "m"
            TriggerServerEvent("vfw:bag:addWeightBonus", 0, bagItem.drawableId, sex)
        end

        cb(true)
    else
        cb(false)
    end
end)

RegisterNUICallback("clothingshop:deleteOutfit", function(data, cb)
    local outfitId = data.outfitId

    local success = TriggerServerCallback("core:server:deleteOutfit", outfitId)

    cb(success)
end)

RegisterNUICallback("clothingshop:checkOutfitName", function(data, cb)
    local exists = TriggerServerCallback("core:server:checkOutfitName", data.name)
    cb(exists == true)
end)

RegisterNUICallback("clothingshop:getOutfitPrice", function(data, cb)
    local skin = GetPlayerCurrentSkin()
    if not skin then
        cb(0)
        return
    end

    local skinToShop = {
        { skinKey = "torso_1", skinTexture = "torso_2", category = "torso2" },
        { skinKey = "tshirt_1", skinTexture = "tshirt_2", category = "undershirt" },
        { skinKey = "arms", skinTexture = "arms_2", category = "arms" },
        { skinKey = "pants_1", skinTexture = "pants_2", category = "leg" },
        { skinKey = "shoes_1", skinTexture = "shoes_2", category = "shoes" },
        { skinKey = "chain_1", skinTexture = "chain_2", category = "accessory" },
        { skinKey = "bags_1", skinTexture = "bags_2", category = "bag" },
        { skinKey = "bproof_1", skinTexture = "bproof_2", category = "armor" },
        { skinKey = "decals_1", skinTexture = "decals_2", category = "decal" },
        { skinKey = "mask_1", skinTexture = "mask_2", category = "mask" },
        { skinKey = "helmet_1", skinTexture = "helmet_2", category = "hat" },
        { skinKey = "glasses_1", skinTexture = "glasses_2", category = "glasses" },
        { skinKey = "ears_1", skinTexture = "ears_2", category = "ear" },
        { skinKey = "watches_1", skinTexture = "watches_2", category = "watch" },
        { skinKey = "bracelets_1", skinTexture = "bracelets_2", category = "bracelet" },
    }

    local outfitItems = {}
    for _, mapping in ipairs(skinToShop) do
        if skin[mapping.skinKey] then
            table.insert(outfitItems, {
                category = mapping.category,
                drawableId = skin[mapping.skinKey],
                variantId = skin[mapping.skinTexture] or 0
            })
        end
    end

    local price = TriggerServerCallback('core:server:getOutfitPrice', outfitItems)
    cb(price or 0)
end)

RegisterNUICallback("clothingshop:saveCurrentOutfit", function(data, cb)
    local outfitName = data.outfitName or "Ma Tenue"
    local paymentMethod = data.paymentMethod or 'cash'

    -- Récupérer le skin actuel du joueur
    local skin = GetPlayerCurrentSkin()
    if not skin then
        cb(false)
        return
    end

    -- Mapper le skin vers outfitItems (format shop)
    local skinToShop = {
        { skinKey = "torso_1", skinTexture = "torso_2", category = "torso2" },
        { skinKey = "tshirt_1", skinTexture = "tshirt_2", category = "undershirt" },
        { skinKey = "arms", skinTexture = "arms_2", category = "arms" },
        { skinKey = "pants_1", skinTexture = "pants_2", category = "leg" },
        { skinKey = "shoes_1", skinTexture = "shoes_2", category = "shoes" },
        { skinKey = "chain_1", skinTexture = "chain_2", category = "accessory" },
        { skinKey = "bags_1", skinTexture = "bags_2", category = "bag" },
        { skinKey = "bproof_1", skinTexture = "bproof_2", category = "armor" },
        { skinKey = "decals_1", skinTexture = "decals_2", category = "decal" },
        { skinKey = "mask_1", skinTexture = "mask_2", category = "mask" },
        { skinKey = "helmet_1", skinTexture = "helmet_2", category = "hat" },
        { skinKey = "glasses_1", skinTexture = "glasses_2", category = "glasses" },
        { skinKey = "ears_1", skinTexture = "ears_2", category = "ear" },
        { skinKey = "watches_1", skinTexture = "watches_2", category = "watch" },
        { skinKey = "bracelets_1", skinTexture = "bracelets_2", category = "bracelet" },
    }

    local outfitItems = {}
    for _, mapping in ipairs(skinToShop) do
        if skin[mapping.skinKey] then
            table.insert(outfitItems, {
                category = mapping.category,
                drawableId = skin[mapping.skinKey],
                variantId = skin[mapping.skinTexture] or 0
            })
        end
    end

    if #outfitItems == 0 then
        cb(false)
        return
    end

    -- Skin brut complet (30 clés) pour fiabilité lors du roundtrip DB → bag → item.
    -- Le round-trip outfitItems → buildSkinFromOutfitItems perdait des composants
    -- (helmet/glasses/mask/bproof... à -1/0) que vfw:clothes interprète comme "vide".
    local rawSkin = {
        ["tshirt_1"]    = skin.tshirt_1,    ["tshirt_2"]    = skin.tshirt_2,
        ["torso_1"]     = skin.torso_1,     ["torso_2"]     = skin.torso_2,
        ["arms"]        = skin.arms,        ["arms_2"]      = skin.arms_2,
        ["pants_1"]     = skin.pants_1,     ["pants_2"]     = skin.pants_2,
        ["shoes_1"]     = skin.shoes_1,     ["shoes_2"]     = skin.shoes_2,
        ["helmet_1"]    = skin.helmet_1,    ["helmet_2"]    = skin.helmet_2,
        ["glasses_1"]   = skin.glasses_1,   ["glasses_2"]   = skin.glasses_2,
        ["bags_1"]      = skin.bags_1,      ["bags_2"]      = skin.bags_2,
        ["chain_1"]     = skin.chain_1,     ["chain_2"]     = skin.chain_2,
        ["decals_1"]    = skin.decals_1,    ["decals_2"]    = skin.decals_2,
        ["bracelets_1"] = skin.bracelets_1, ["bracelets_2"] = skin.bracelets_2,
        ["watches_1"]   = skin.watches_1,   ["watches_2"]   = skin.watches_2,
        ["ears_1"]      = skin.ears_1,      ["ears_2"]      = skin.ears_2,
        ["mask_1"]      = skin.mask_1,      ["mask_2"]      = skin.mask_2,
        ["bproof_1"]    = skin.bproof_1,    ["bproof_2"]    = skin.bproof_2,
    }

    -- Calculer le prix total (utiliser le prix envoyé par le front ou 0)
    local totalPrice = data.totalPrice or 0

    local success, insertId = TriggerServerCallback("core:server:saveCurrentOutfit", outfitName, outfitItems, totalPrice, paymentMethod, rawSkin)

    if success then
        SendNUIMessage({
            action = "clothingshop:updateMoney",
            data = {
                money = getPlayerCash()
            }
        })
    end

    cb(success)
end)

RegisterNUICallback("clothingshop:purchasePrivateOutfit", function(data, cb)
    local outfitId = data.outfitId
    local paymentMethod = data.paymentMethod or 'cash'

    local success = TriggerServerCallback("core:server:purchasePrivateOutfit", outfitId, paymentMethod)

    if success then
        SendNUIMessage({
            action = "clothingshop:updateMoney",
            data = {
                money = getPlayerCash()
            }
        })
    end

    cb(success)
end)

RegisterNUICallback("clothingshop:purchaseItem", function(data, cb)
    local outfitId = data.outfitId
    local item = data.item
    local paymentMethod = data.paymentMethod or 'cash'

    local success = TriggerServerCallback("core:server:purchaseOutfitItem", outfitId, item, paymentMethod)

    if success then
        SendNUIMessage({
            action = "clothingshop:updateMoney",
            data = {
                money = getPlayerCash()
            }
        })
    end

    cb(success)
end)

RegisterNUICallback("clothingshop:resetPreview", function(data, cb)
    if currentShopData and currentShopData.shopType == "tattoo" then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
        local skinSex = (skin and skin.sex) or 0
        TriggerEvent('skinchanger:loadSkin', {
            sex       = skinSex,
            tshirt_1  = 15, tshirt_2  = 0,
            torso_1   = 15, torso_2   = 0,
            arms      = 15, arms_2    = 0,
            pants_1   = 21, pants_2   = 0,
            shoes_1   = 34, shoes_2   = 0,
            chain_1   = 0, chain_2   = 0,
            helmet_1  = -1, helmet_2  = 0,
            ears_1    = -1, ears_2    = 0,
            glasses_1 = 0, glasses_2 = 0,
            mask_1    = 0, mask_2    = 0,
            bproof_1  = 0, bproof_2  = 0,
            bags_1    = 0, bags_2    = 0,
            decals_1  = 0, decals_2  = 0,
            watches_1 = -1, watches_2 = 0,
            bracelets_1 = -1, bracelets_2 = 0,
        })
        Wait(100)
        SetPedComponentVariation(VFW.PlayerData.ped, 5, 0, 0, 2)
    else
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
        if skin then
            TriggerEvent('skinchanger:loadSkin', skin)
        end
    end

    local playerPed = VFW.PlayerData.ped
    if playerPed then
        ClearPedDecorations(playerPed)
        local tattoos = TriggerServerCallback("core:server:getTattoo") or {}
        for _, tattoo in ipairs(tattoos) do
            AddPedDecorationFromHashes(playerPed, tattoo.Collection, tattoo.Hash)
        end
    end

    -- Sync reset to clone
    Wait(0)
    SyncClothingClone()
    if clothingClonePed and DoesEntityExist(clothingClonePed) then
        ClearPedDecorations(clothingClonePed)
        local tattoos = VFW.PlayerData.tattoos or {}
        for _, tattoo in ipairs(tattoos) do
            ApplyPedOverlay(clothingClonePed, joaat(tattoo.Collection), joaat(tattoo.Hash))
        end
    end

    cb("ok")
end)

RegisterNUICallback("clothingshop:rotateCharacter", function(data, cb)
    local ped = VFW.PlayerData.ped or PlayerPedId()
    FreezeEntityPosition(ped, false)
    local heading = GetEntityHeading(ped)
    SetEntityHeading(ped, heading - (data.delta * 0.8))
    FreezeEntityPosition(ped, true)
    cb("ok")
end)

RegisterNUICallback("clothingshop:zoomCamera", function(data, cb)
    local zoom = data.zoom or 0
    targetFov = math.max(30.0, math.min(60.0, targetFov - (zoom * 2.0)))
    cb("ok")
end)

RegisterNUICallback("clothingshop:changeCameraView", function(data, cb)
    local view = data.view or "full"
    local viewData = CAMERA_VIEWS[view]

    if viewData then
        currentCameraView = view
        targetCamZ  = viewData.camZ
        targetLookZ = viewData.lookZ
        targetFov   = viewData.fov
    end

    cb({ view = currentCameraView })
end)

RegisterNUICallback("clothingshop:getBagPrice", function(data, cb)
    local shopId = currentShopData and currentShopData.shopId or nil
    local price = TriggerServerCallback("core:server:getBagPrice", shopId)
    cb(price or 500)
end)

RegisterNUICallback("clothingshop:buyClothingBag", function(data, cb)
    local shopId = currentShopData and currentShopData.shopId or nil
    local result = TriggerServerCallback("core:server:buyClothingBag", data.paymentMethod, shopId)
    cb(result)
end)

RegisterNUICallback("clothingshop:close", function(data, cb)
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
    if skin then
        TriggerEvent('skinchanger:loadSkin', skin)
    end

    local playerPed = VFW.PlayerData.ped
    if playerPed then
        ClearPedDecorations(playerPed)
        local tattoos = TriggerServerCallback("core:server:getTattoo") or {}
        for _, tattoo in ipairs(tattoos) do
            AddPedDecorationFromHashes(playerPed, tattoo.Collection, tattoo.Hash)
        end
    end

    CloseClothingShop()
    cb("ok")
end)

function LoadPreBinco(data, job)
    OpenModernClothingShop(data, job)
end

exports('OpenClothingShop', OpenModernClothingShop)
exports('CloseClothingShop', CloseClothingShop)

RegisterNetEvent("core:staff:openFreeSkin", function()
    if isShopOpen then
        TriggerServerEvent("core:staff:clearFreeSkinSession")
        return
    end
    isFreeStaffSkinSession = true
    OpenModernClothingShop({
        Title = "Magasin de Vêtements (Staff)",
        shopType = "clothing",
        priceMultiplier = 0.0,
    }, false)
end)

AddEventHandler("vfw:onPlayerDeath", function()
    CloseClothingShop()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CloseClothingShop()
end)
