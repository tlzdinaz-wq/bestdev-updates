---@meta _
---@diagnostic disable: duplicate-doc-field

local tattooZone = {
    ---@class ZONE_HEAD
    ZONE_HEAD = {},
    ---@class ZONE_LEFT_ARM
    ZONE_LEFT_ARM = {},
    ---@class ZONE_RIGHT_ARM
    ZONE_RIGHT_ARM = {},
    ---@class ZONE_LEFT_LEG
    ZONE_LEFT_LEG = {},
    ---@class ZONE_RIGHT_LEG
    ZONE_RIGHT_LEG = {},
    ---@class ZONE_TORSO
    ZONE_TORSO = {},
}
local cams = nil
local currentTattoos
local lastCategory = nil
local componentData = {}
local indexCategory = 0
local sex = "Homme"

--- TattooData
---@return any
--- Génère un label lisible pour un tattoo
--- Utilise LocalizedName si disponible, sinon GetLabelText via le Name GTA
local function getTattooLabel(tattoo)
    if tattoo.LocalizedName and tattoo.LocalizedName ~= "" then
        return tattoo.LocalizedName
    end
    -- Fallback: récupérer le label localisé via le natif GTA
    if tattoo.Name and tattoo.Name ~= "" then
        local label = GetLabelText(tattoo.Name)
        if label and label ~= "NULL" and label ~= "" then
            return label
        end
    end
    return "Tatouage"
end

local function TattooData()
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 1,
            gridType = 2,
            buyType = 0,
            lineColor = "linear-gradient(to right, rgba(139, 106, 34, .6) 0%, rgba(234, 215, 148, .6) 56%, rgba(219, 200, 147, 0) 100%)",
            title = "MAGASIN DE TATOUAGE",
        },
        eventName = "TattooShop",
        showStats = false,
        mouseEvents = false,
        color = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        category = { show = false },
        cameras = { show = false },
        items = {
            {
                label = 'TORSE',
                model = 'Torse',
                image = "assets/catalogues/tattoo/" .. sex .. "/Torse.webp",
                style = "big",
            },
            {
                label = 'DOS',
                model = 'Dos',
                image = "assets/catalogues/tattoo/" .. sex .. "/Dos.webp",
                style = "normal",
            },
            {
                label = 'VISAGE',
                model = 'Visage',
                image = "assets/catalogues/tattoo/" .. sex .. "/Visage.webp",
                style = "normal",
            },
            {
                label = 'BRAS GAUCHE',
                model = 'Bras gauche',
                image = "assets/catalogues/tattoo/" .. sex .. "/Torse.webp",
                style = "semi",
            },
            {
                label = 'BRAS DROIT',
                model = 'Bras droit',
                image = "assets/catalogues/tattoo/" .. sex .. "/BrasDroit.webp",
                style = "semi",
            },
            {
                label = 'JAMBE GAUCHE',
                model = 'Jambe gauche',
                image = "assets/catalogues/tattoo/" .. sex .. "/BrasGauche.webp",
                style = "semi",
            },
            {
                label = 'JAMBE DROITE',
                model = 'Jambe droite',
                image = "assets/catalogues/tattoo/" .. sex .. "/JambeDroite.webp",
                style = "semi",
            },
            {
                label = 'LAZER',
                model = 'Lazer',
                image = "assets/catalogues/tattoo/Lazer.png",
                style = "normal",
            },
        }
    }

    return data
end


local function RefreshPedTattoos()
    local playerPed = VFW.PlayerData.ped
    ClearPedDecorations(playerPed)
    for _, tattoo in ipairs(currentTattoos) do
        AddPedDecorationFromHashes(playerPed, joaat(tattoo.Collection), joaat(tattoo.Hash))
    end
end

---Get Component
---@param category any
local function getComponent(category)
    componentData[category] = {}

    local tattoos = GetTattoos()
    local zones = {
        ZONE_HEAD = { label = "Visage" },
        ZONE_LEFT_ARM = { label = "Bras gauche" },
        ZONE_RIGHT_ARM = { label = "Bras droit" },
        ZONE_LEFT_LEG = { label = "Jambe gauche" },
        ZONE_RIGHT_LEG = { label = "Jambe droite" },
        ZONE_TORSO = { label = "Torse", extraLabel = "Dos" }
    }

    local shopPrice = TriggerServerCallback("core:getClothesPrice")

    if category == "Torse" or category == "Dos" or category == "Visage" or category == "Bras gauche" or category == "Bras droit"
            or category == "Jambe gauche" or category == "Jambe droite" then
        for _, tattoo in ipairs(tattoos) do
            local zone = tattoo.Zone
            local hashName = tattoo.HashNameMale

            if hashName and hashName ~= "" and tattooZone[zone] then
                table.insert(tattooZone[zone], tattoo)

                local zoneData = zones[zone]
                local categories = { zoneData.label }

                if zoneData.extraLabel then
                    table.insert(categories, zoneData.extraLabel)
                end

                for _, v in ipairs(categories) do
                    if v == category then
                        local tempCatalogue = {
                            label = getTattooLabel(tattoo),
                            model = tattoo,
                            premium = false,
                            price = VFW.Math.GroupDigits(shopPrice[sex] and shopPrice[sex]["tattoo"] and shopPrice[sex]["tattoo"].price or 100),
                            image = "assets/catalogues/tattoo/tattooList/" .. string.lower(tattoo.Img) .. ".png"
                        }

                        table.insert(componentData[v], tempCatalogue)
                    end
                end
            end
        end
    else
        for _, v in ipairs(currentTattoos) do
            for _, tattoo in ipairs(tattoos) do
                if tattoo.Collection == v.Collection then
                    if v.Hash == tattoo.HashNameMale or v.Hash == tattoo.HashNameFemale then
                        local tempCatalogue = {
                            label = getTattooLabel(tattoo),
                            model = tattoo,
                            premium = false,
                            price = VFW.Math.GroupDigits(shopPrice[sex] and shopPrice[sex]["tattoo"] and shopPrice[sex]["tattoo"].price or 100),
                            image = "assets/catalogues/tattoo/tattooList/" .. string.lower(tattoo.Img) .. ".png"
                        }

                        table.insert(componentData[category], tempCatalogue)
                    end
                end
            end
        end
    end

    return componentData[category]
end

--- tattooComponent
---@param category any
---@param indexCategory any
---@return any
local function tattooComponent(category, indexCategory)
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 2,
            gridType = 1,
            buyType = 2,
            bannerImg = "assets/catalogues/headers/header_tattooshop.webp",
            buyTextType = false,
            buyText = "Selectionner",
        },
        eventName = "TattooShopId",
        category = {
            show = true,
            defaultIndex = indexCategory,
            items = {
                {id = "Jambe droite", label = "Jambe droite", image = "assets/catalogues/tattoo/JAMBE_DROITE.png"},
                {id = "Jambe gauche", label = "Jambe gauche", image = "assets/catalogues/tattoo/JAMBE_GAUCHE.png"},
                {id = "Bras droit", label = "Bras droit", image = "assets/catalogues/tattoo/BRAS_GAUCHE.png"},
                {id = "Bras gauche", label = "Bras gauche", image = "assets/catalogues/tattoo/BRAS_DROIT.png"},
                {id = "Visage", label = "Visage", image = "assets/catalogues/tattoo/VISAGE.png"},
                {id = "Dos", label = "Dos", image = "assets/catalogues/tattoo/DOS.png"},
                {id = "Torse", label = "Torse", image = "assets/catalogues/tattoo/TORSO.png"},
            }
        },
        cameras = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        showStats = false,
        mouseEvents = true,
        color = { show = false },
        items = getComponent(category)
    }

    return data
end

---Load Tattoo
---@param data table
function LoadTattoo(data)

    Wait(250)

    cams = data
    currentTattoos = TriggerServerCallback("core:server:getTattoo")

    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 1 then
            sex = "Femme"
            TriggerEvent('skinchanger:loadSkin', {
                sex       = 1,
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
        else
            TriggerEvent('skinchanger:loadSkin', {
                sex       = 0,
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
        end

        Wait(100)
        SetPedComponentVariation(VFW.PlayerData.ped, 5, 0, 0, 2)
    end)

    cEntity.Visual.HideAllEntities(true)
    cEntity.Visual.AddEntityToException(VFW.PlayerData.ped)
    cEntity.Visual.DisablePlayerCollisions(true)
    VFW.Cam:Create("cam_tattoo", cams[1])

    VFW.Nui.BigMenu(true, TattooData())
end

--- closeUI
local function closeUI()
    tattooZone = {
        ---@class ZONE_HEAD
        ZONE_HEAD = {},
        ---@class ZONE_LEFT_ARM
        ZONE_LEFT_ARM = {},
        ---@class ZONE_RIGHT_ARM
        ZONE_RIGHT_ARM = {},
        ---@class ZONE_LEFT_LEG
        ZONE_LEFT_LEG = {},
        ---@class ZONE_RIGHT_LEG
        ZONE_RIGHT_LEG = {},
        ---@class ZONE_TORSO
        ZONE_TORSO = {},
    }
    cams = nil
    lastCategory = nil
    ---@class componentData
    componentData = {}
    indexCategory = 0
    cEntity.Visual.HideAllEntities(false)
    VFW.Nui.BigMenu(false)
    VFW.Cam:Destroy("cam_tattoo")
    cEntity.Visual.DisablePlayerCollisions(false)

    Wait(250)

end

RegisterNuiCallback("nui:newgrandcatalogue:TattooShop:selectGridType2", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Torse" or lastCategory == "Bras gauche" or lastCategory == "Bras droit" then
        if lastCategory == "Torse" then
            indexCategory = 6
            VFW.Cam:Update("cam_tattoo", cams[1])
        elseif lastCategory == "Bras gauche" then
            indexCategory = 3
            VFW.Cam:Update("cam_tattoo", cams[4])
        elseif lastCategory == "Bras droit" then
            indexCategory = 2
            VFW.Cam:Update("cam_tattoo", cams[6])
        end
    elseif lastCategory == "Jambe gauche" or lastCategory == "Jambe droite" then
        if lastCategory == "Jambe gauche" then
            indexCategory = 1
            VFW.Cam:Update("cam_tattoo", cams[5])
        elseif lastCategory == "Jambe droite" then
            indexCategory = 0
            VFW.Cam:Update("cam_tattoo", cams[7])
        end
    elseif lastCategory == "Visage" then
        VFW.Cam:Update("cam_tattoo", cams[3])
        indexCategory = 4
    elseif lastCategory == "Dos" then
        VFW.Cam:Update("cam_tattoo", cams[2])
        indexCategory = 5
    elseif lastCategory == "Lazer" then
        VFW.Cam:Update("cam_tattoo", cams[1])
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(tattooComponent(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:TattooShopId:selectCategory", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Torse" or lastCategory == "Bras gauche" or lastCategory == "Bras droit" then
        if lastCategory == "Torse" then
            indexCategory = 6
            VFW.Cam:Update("cam_tattoo", cams[1])
        elseif lastCategory == "Bras gauche" then
            indexCategory = 3
            VFW.Cam:Update("cam_tattoo", cams[4])
        elseif lastCategory == "Bras droit" then
            indexCategory = 2
            VFW.Cam:Update("cam_tattoo", cams[6])
        end
    elseif lastCategory == "Jambe gauche" or lastCategory == "Jambe droite" then
        if lastCategory == "Jambe gauche" then
            indexCategory = 1
            VFW.Cam:Update("cam_tattoo", cams[5])
        elseif lastCategory == "Jambe droite" then
            indexCategory = 0
            VFW.Cam:Update("cam_tattoo", cams[7])
        end
    elseif lastCategory == "Visage" then
        VFW.Cam:Update("cam_tattoo", cams[3])
        indexCategory = 4
    elseif lastCategory == "Dos" then
        VFW.Cam:Update("cam_tattoo", cams[2])
        indexCategory = 5
    elseif lastCategory == "Lazer" then
        VFW.Cam:Update("cam_tattoo", cams[1])
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(tattooComponent(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:TattooShopId:mouseEvents", function(data)
    SetEntityHeading(VFW.PlayerData.ped, GetEntityHeading(VFW.PlayerData.ped) + (0.5 * data.x))
end)

RegisterNUICallback("nui:newgrandcatalogue:TattooShopId:selectGridType", function(data)
    if not data then return end

    local playerPed = VFW.PlayerData.ped

    if lastCategory ~= "Lazer" then
        ClearPedDecorations(playerPed)

        -- 1. Aplicar tatuajes que ya tiene el jugador
        for _, tattoo in ipairs(currentTattoos) do
            AddPedDecorationFromHashes(playerPed, tattoo.Collection, tattoo.Hash)
        end

        -- 2. Verificar si ya existe este tatuaje
        local Hash = data.HashNameMale
        if sex == "Femme" then
            Hash = data.HashNameFemale
        end

        for _, existingTattoo in ipairs(currentTattoos) do
            if existingTattoo.Collection == data.Collection and existingTattoo.Hash == data.Hash then
                return
            end
        end

        -- 3. Aplicar el nuevo tatuaje en preview
        AddPedDecorationFromHashes(playerPed, data.Collection, Hash)
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:TattooShopId:selectBuy", function(data)
    if not data then
        return
    end

    if lastCategory ~= "Lazer" and data and data.Collection then
        local Hash = data.HashNameMale
        if sex == "Femme" then
            Hash = data.HashNameFemale
        end

        local dataTattoo = { Collection = data.Collection, Hash = Hash }

        for _, existingTattoo in ipairs(currentTattoos) do
            if existingTattoo.Collection == data.Collection and existingTattoo.Hash == Hash then
                return
            end
        end

        TriggerServerEvent("core:server:setTattoo", dataTattoo, data.Price)

        table.insert(currentTattoos, dataTattoo)
    elseif lastCategory == "Lazer" then
        if data and data and data.Collection then
            local Hash = data.HashNameMale
            if sex == "Femme" then
                Hash = data.HashNameFemale
            end

            for i, existingTattoo in ipairs(currentTattoos) do
                if existingTattoo.Collection == data.Collection and existingTattoo.Hash == Hash then
                    table.remove(currentTattoos, i)
                    TriggerServerEvent("core:server:removeTattoo", data.Collection, Hash)
                    break
                end
            end
        end
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:TattooShopId:enter", function(data)
    if not data then
        return
    end

    if lastCategory ~= "Lazer" and data and data.Collection then
        local Hash = data.HashNameMale
        if sex == "Femme" then
            Hash = data.HashNameFemale
        end

        local dataTattoo = { Collection = data.Collection, Hash = Hash }

        for _, existingTattoo in ipairs(currentTattoos) do
            if existingTattoo.Collection == data.Collection and existingTattoo.Hash == Hash then
                return
            end
        end

        TriggerServerEvent("core:server:setTattoo", dataTattoo, data.Price)

        table.insert(currentTattoos, dataTattoo)
    elseif lastCategory == "Lazer" then
        if data and data and data.Collection then
            local Hash = data.HashNameMale
            if sex == "Femme" then
                Hash = data.HashNameFemale
            end

            for i, existingTattoo in ipairs(currentTattoos) do
                if existingTattoo.Collection == data.Collection and existingTattoo.Hash == Hash then
                    table.remove(currentTattoos, i)
                    TriggerServerEvent("core:server:removeTattoo", data.Collection, Hash)
                    break
                end
            end
        end
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:TattooShopId:backspace", function()
    ClearPedDecorations(VFW.PlayerData.ped)

    local tattoos = TriggerServerCallback("core:server:getTattoo")

    for _, tattoo in pairs(tattoos) do
        ApplyPedOverlay(VFW.PlayerData.ped, joaat(tattoo.Collection), joaat(tattoo.Hash))
    end

    VFW.Cam:Update("cam_tattoo", cams[1])
    VFW.Nui.UpdateBigMenu(TattooData())
end)

-- ✅ CORREGIDO: Usar currentTattoos en lugar de consultar servidor
RegisterNuiCallback("nui:newgrandcatalogue:TattooShopId:close", function()
    closeUI()

    local playerPed = VFW.PlayerData.ped
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
    TriggerEvent('skinchanger:loadSkin', skin or {})

    ClearPedDecorations(playerPed)

    if currentTattoos and #currentTattoos > 0 then
        for _, tattoo in pairs(currentTattoos) do
            AddPedDecorationFromHashes(playerPed, joaat(tattoo.Collection), joaat(tattoo.Hash))
        end
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:TattooShop:close", function()
    closeUI()

    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

    TriggerEvent('skinchanger:loadSkin', skin or {})
    ClearPedDecorations(VFW.PlayerData.ped)

    if currentTattoos and #currentTattoos > 0 then
        for _, tattoo in pairs(currentTattoos) do
            ApplyPedOverlay(VFW.PlayerData.ped, joaat(tattoo.Collection), joaat(tattoo.Hash))
        end
    end
end)

---@param tattoos any
RegisterNetEvent("core:client:setTattoo", function(tattoos)
    currentTattoos = tattoos

    local ped = PlayerPedId()
    ClearPedDecorations(ped)

    for _, tattoo in pairs(tattoos) do
        AddPedDecorationFromHashes(ped, joaat(tattoo.Collection), joaat(tattoo.Hash))
    end
end)

AddEventHandler('skinchanger:modelLoaded', function()
    local tattoos = TriggerServerCallback("core:server:getTattoo")

    if tattoos then
        currentTattoos = tattoos

        local ped = PlayerPedId()
        ClearPedDecorations(ped)
        for _, v in pairs(tattoos) do
            AddPedDecorationFromHashes(ped, joaat(v.Collection), joaat(v.Hash))
        end
    end
end)

-- ============================================
-- ✅ CALLBACK PRINCIPAL: Aplicar cambios del TattooManager
-- ============================================

RegisterNUICallback('clothingshop:applyTattooChanges', function(data, cb)
    if not data or not data.activeTattoos then
        --print("[TattooManager] Error: data.activeTattoos es nil")
        cb(false)
        return
    end

    -- ✅ Validar que activeTattoos es una tabla
    if type(data.activeTattoos) ~= "table" then
        --print("[TattooManager] Error: activeTattoos no es una tabla")
        cb(false)
        return
    end

    -- ✅ Construir la lista formateada
    -- data.activeTattoos viene de useClothingShop con estructura: { Collection, Hash }
    local formattedTattoos = {}

    for i, tattoo in ipairs(data.activeTattoos) do
        -- ✅ Verificar que el tattoo tenga Collection y Hash directamente
        if tattoo.Collection and tattoo.Hash then
            table.insert(formattedTattoos, {
                Collection = tattoo.Collection,
                Hash = tattoo.Hash
            })
        else
            --print(string.format("[TattooManager] Warning: Tattoo #%d no tiene Collection/Hash", i))
        end
    end

    --print(string.format("[TattooManager] Aplicando %d tatuajes activos", #formattedTattoos))

    -- Envoyer au serveur et attendre la validation (fonds suffisants)
    local paymentMethod = data.paymentMethod or 'cash'
    local success = TriggerServerCallback("core:server:applyTattooChanges", formattedTattoos, paymentMethod)

    if success then
        -- Actualizar variable local
        currentTattoos = formattedTattoos

        -- Aplicar visualmente
        local playerPed = VFW.PlayerData.ped or PlayerPedId()
        ClearPedDecorations(playerPed)
        for _, tattoo in ipairs(formattedTattoos) do
            ApplyPedOverlay(playerPed, joaat(tattoo.Collection), joaat(tattoo.Hash))
        end
    end

    cb(success == true)
end)

-- ============================================
-- CALLBACKS PARA CARGAR TATUAJES OWNED
-- ============================================

RegisterNUICallback('clothingshop:getOwnedTattoos', function(data, cb)
    local tattoos = TriggerServerCallback("core:server:getTattoo")

    if not tattoos then
        cb({ ownedTattoos = {} })
        return
    end

    currentTattoos = tattoos

    local ownedTattoos = {}

    for i, tattoo in ipairs(tattoos) do
        local tattooInfo = findTattooInfo(tattoo.Collection, tattoo.Hash)

        table.insert(ownedTattoos, {
            id = i,
            label = tattooInfo and getTattooLabel(tattooInfo) or ("Tattoo #" .. i),
            category = tattooInfo and getCategoryFromZone(tattooInfo.Zone) or "torso",
            tattooData = {
                Collection = tattoo.Collection,
                Hash = tattoo.Hash
            }
        })
    end

    cb({ ownedTattoos = ownedTattoos })
end)

RegisterNUICallback('clothingshop:loadOwnedTattoos', function(data, cb)
    local tattoos = TriggerServerCallback("core:server:getTattoo")

    if not tattoos then
        SendNUIMessage({
            action = "clothingshop:loadOwnedTattoos",
            data = {
                ownedTattoos = {}
            }
        })
        cb(true)
        return
    end

    currentTattoos = tattoos

    local allTattoos = GetTattoos()
    local ownedTattoos = {}

    for i, playerTattoo in ipairs(tattoos) do
        local tattooInfo = nil

        -- Buscar el tatuaje en el catálogo completo
        for _, catalogTattoo in ipairs(allTattoos) do
            if catalogTattoo.Collection == playerTattoo.Collection and
                    (catalogTattoo.HashNameMale == playerTattoo.Hash or catalogTattoo.HashNameFemale == playerTattoo.Hash) then
                tattooInfo = catalogTattoo
                break
            end
        end

        -- Determinar categoría
        local category = "torso"
        if tattooInfo and tattooInfo.Zone then
            local zoneMap = {
                ZONE_HEAD = "head",
                ZONE_TORSO = "torso",
                ZONE_LEFT_ARM = "leftArm",
                ZONE_RIGHT_ARM = "rightArm",
                ZONE_LEFT_LEG = "leftLeg",
                ZONE_RIGHT_LEG = "rightLeg"
            }
            category = zoneMap[tattooInfo.Zone] or "torso"
        end

        -- ✨ AGREGAR CAMPO IMAGE
        table.insert(ownedTattoos, {
            id = i,
            label = tattooInfo and getTattooLabel(tattooInfo) or ("Tattoo #" .. i),
            category = category,
            image = tattooInfo and ("assets/catalogues/tattoo/tattooList/" .. string.lower(tattooInfo.Img) .. ".png") or nil, -- ✨ CAMPO IMAGE
            tattooData = {
                Collection = playerTattoo.Collection,
                Hash = playerTattoo.Hash
            }
        })
    end

    SendNUIMessage({
        action = "clothingshop:loadOwnedTattoos",
        data = {
            ownedTattoos = ownedTattoos
        }
    })

    cb(true)

    console.debug(string.format("[TattooManager] Loaded %d owned tattoos with images", #ownedTattoos))
end)

RegisterNUICallback('clothingshop:previewTattoos', function(data, cb)
    if not data or not data.tattoos then
        cb(false)
        return
    end

    local playerPed = VFW.PlayerData.ped or PlayerPedId()

    ClearPedDecorations(playerPed)

    for _, tattoo in ipairs(data.tattoos) do
        ApplyPedOverlay(playerPed, joaat(tattoo.Collection), joaat(tattoo.Hash))
    end

    cb(true)
end)

RegisterNUICallback('clothingshop:previewAllTattoos', function(data, cb)
    if not data or not data.tattoos then
        cb(false)
        return
    end

    local playerPed = VFW.PlayerData.ped or PlayerPedId()

    ClearPedDecorations(playerPed)

    local appliedCount = 0
    local tattooSet = {}

    for _, tattoo in ipairs(data.tattoos) do
        local key = tattoo.Collection .. "_" .. tattoo.Hash

        if not tattooSet[key] then
            ApplyPedOverlay(playerPed, joaat(tattoo.Collection), joaat(tattoo.Hash))
            tattooSet[key] = true
            appliedCount = appliedCount + 1
        end
    end

    cb(true)

    --print(string.format("[TattooShop] Preview aplicado: %d tatuajes totales", appliedCount))
end)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

---@param collection string
---@param hash string
---@return table|nil
function findTattooInfo(collection, hash)
    local tattoos = GetTattoos()

    for _, tattoo in ipairs(tattoos) do
        if tattoo.Collection == collection and (tattoo.HashNameMale == hash or tattoo.HashNameFemale == hash) then
            return tattoo
        end
    end

    return nil
end

---@param zone string
---@return string
function getCategoryFromZone(zone)
    local zoneMap = {
        ZONE_HEAD = "head",
        ZONE_TORSO = "torso",
        ZONE_LEFT_ARM = "leftArm",
        ZONE_RIGHT_ARM = "rightArm",
        ZONE_LEFT_LEG = "leftLeg",
        ZONE_RIGHT_LEG = "rightLeg"
    }

    return zoneMap[zone] or "torso"
end