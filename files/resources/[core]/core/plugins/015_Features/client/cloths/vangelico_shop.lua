---@meta _
---@diagnostic disable: duplicate-doc-field

local sex = "Homme"
local sexType = "male"
local cams = nil
local lastCategory = nil
local componentIdData = {}
local componentVarData = {}
local dataId = {}
local indexCategory = 0
local goodAchat = false

--- VangelicoData
---@return any
local function VangelicoData()
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 1,
            gridType = 2,
            buyType = 0,
            lineColor = "linear-gradient(to right, rgba(139, 106, 34, .6) 0%, rgba(234, 215, 148, .6) 56%, rgba(219, 200, 147, 0) 100%)",
            title = "VANGELICO",
        },
        eventName = "VangelicoShop",
        showStats = false,
        mouseEvents = false,
        color = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        category = { show = false },
        cameras = { show = false },
        items = {
            {
                label = 'MONTRES',
                model = 'Montres',
                image = "assets/catalogues/vangelico/montre.png",
                style = "big",
            },
            {
                label = 'COLIERS',
                model = 'Coliers',
                image = "assets/catalogues/vangelico/coliers.png",
                style = "normal",
            },
            {
                label = 'BOUCLE D\'OREILLES',
                model = 'Boucle d\'oreilles',
                image = "assets/catalogues/vangelico/ears.png",
                style = "normal",
            },
            {
                label = 'BRACELETS',
                model = 'Bracelets',
                image = "assets/catalogues/vangelico/slot-11.png",
                style = "normal",
            },
            {
                label = 'BAGUES',
                model = 'Bagues',
                image = "assets/catalogues/vangelico/bague.png",
                style = "normal",
            },
        }
    }

    return data
end

---Get ComponentId
---@param category any
local function getComponentId(category)
    local playerPed = PlayerPedId()
    componentIdData[category] = {}
    local bans = Config.VangelicoBan[sex] or {}
    local name

    if category == "Montres" then
        name = "watch"
    elseif category == "Coliers" then
        name = "necklace"
    elseif category == "Boucle d\'oreilles" then
        name = "earring"
    elseif category == "Bracelets" then
        name = "bracelet"
    elseif category == "Bagues" then
        name = "necklace"
    end

--- addCatalogueItem
---@param i any
---@param imageURL any
    local function addCatalogueItem(i, imageURL)
        local tempCatalogue = {
            label = i,
            model = i,
            premium = false,
            price = VFW.Math.GroupDigits(Config.VangelicoPrice[sex][name]),
            image = imageURL
        }
        table.insert(componentIdData[category], tempCatalogue)
    end

    if category == "Montres" then
        for i = 0, GetNumberOfPedPropDrawableVariations(playerPed, 6) - 1 do
            local imageURL = VFW.OutfitImage(sexType, "props", "watch", i, 0)

            if not VFW.Table.TableContains(bans["BanMontre"], i) then
                addCatalogueItem(i, imageURL)
            end
        end
    elseif category == "Coliers" then
        for i = 0, GetNumberOfPedDrawableVariations(playerPed, 7) - 1 do
            local imageURL = VFW.OutfitImage(sexType, "clothing", "accessory", i, 0)

            if not VFW.Table.TableContains(bans["BanColier"], i) then
                addCatalogueItem(i, imageURL)
            end
        end
    elseif category == "Boucle d\'oreilles" then
        for i = 0, GetNumberOfPedPropDrawableVariations(playerPed, 2) - 1 do
            local imageURL = VFW.OutfitImage(sexType, "props", "ear", i, 0)

            if not VFW.Table.TableContains(bans["BanBouclesOreilles"], i) then
                addCatalogueItem(i, imageURL)
            end
        end
    elseif category == "Bracelets" then
        for i = 0, GetNumberOfPedPropDrawableVariations(playerPed, 7) - 1 do
            local imageURL = VFW.OutfitImage(sexType, "props", "bracelet", i, 0)

            if not VFW.Table.TableContains(bans["BanBracelet"], i) then
                addCatalogueItem(i, imageURL)
            end
        end
    elseif category == "Bagues" then
        for i = 0, GetNumberOfPedDrawableVariations(playerPed, 9) - 1 do
            if not VFW.Table.TableContains(bans["BanBague"], i) then
                addCatalogueItem(i, "")
            end
        end
    end

    return componentIdData[category]
end

--- vangelicoComponentId
---@param category any
---@param indexCategory any
---@return any
local function vangelicoComponentId(category, indexCategory)
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 2,
            gridType = 1,
            buyType = 2,
            bannerImg = "assets/catalogues/headers/header_vangelico.webp",
            buyTextType = false,
            buyText = "Selectionner",
        },
        eventName = "VangelicoShopId",
        category = {
            show = true,
            defaultIndex = indexCategory,
            items = {
                {id = "Montres", label = "Montres", image = "assets/catalogues/vangelico/montre2.png"},
                {id = "Coliers", label = "Coliers", image = "assets/catalogues/vangelico/coliers2.png"},
                {id = "Boucle d\'oreilles", label = "Boucle d\'oreilles", image = "assets/catalogues/vangelico/ears2.png"},
                {id = "Bracelets", label = "Bracelets", image = "assets/catalogues/vangelico/bracelet2.png"},
                {id = "Bagues", label = "Bagues", image = "assets/catalogues/vangelico/bague2.png"},
            }
        },
        cameras = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        showStats = false,
        mouseEvents = true,
        color = { show = false },
        items = getComponentId(category)
    }

    return data
end

---Get ComponentVar
---@param category any
local function getComponentVar(category)
    local playerPed = PlayerPedId()
    componentVarData[category] = {}

    local name

    if category == "Montres" then
        name = "watch"
    elseif category == "Coliers" then
        name = "necklace"
    elseif category == "Boucle d\'oreilles" then
        name = "earring"
    elseif category == "Bracelets" then
        name = "bracelet"
    elseif category == "Bagues" then
        name = "necklace"
    end

--- addCatalogueItem
---@param i any
---@param imageURL any
    local function addCatalogueItem(i, imageURL)
        local tempCatalogue = {
            label = i,
            model = i,
            premium = false,
            price = VFW.Math.GroupDigits(Config.VangelicoPrice[sex][name]),
            image = imageURL
        }
        table.insert(componentVarData[category], tempCatalogue)
    end

    local imageURL

    if category == "Montres" then
        for z = 0, GetNumberOfPedPropTextureVariations(playerPed, 6, dataId[category]) do
            imageURL = VFW.OutfitImage(sexType, "props", "watch", dataId[category], z)

            addCatalogueItem(z, imageURL)
        end
    elseif category == "Coliers" then
        for z = 0, GetNumberOfPedTextureVariations(playerPed, 7, dataId[category]) do
            imageURL = VFW.OutfitImage(sexType, "clothing", "accessory", dataId[category], z)

            addCatalogueItem(z, imageURL)
        end
    elseif category == "Boucle d\'oreilles" then
        for z = 0, GetNumberOfPedPropTextureVariations(playerPed, 2, dataId[category]) do
            imageURL = VFW.OutfitImage(sexType, "props", "ear", dataId[category], z)

            addCatalogueItem(z, imageURL)
        end
    elseif category == "Bracelets" then
        for z = 0, GetNumberOfPedPropTextureVariations(playerPed, 7, dataId[category]) do
            imageURL = VFW.OutfitImage(sexType, "props", "bracelet", dataId[category], z)

            addCatalogueItem(z, imageURL)
        end
    elseif category == "Bagues" then
        for z = 0, GetNumberOfPedTextureVariations(playerPed, 7, dataId[category]) do
            addCatalogueItem(z, "")
        end
    end

    return componentVarData[category]
end

--- vangelicoComponentVar
---@param category any
---@param indexCategory any
---@return any
local function vangelicoComponentVar(category, indexCategory)
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 2,
            gridType = 1,
            buyType = 2,
            bannerImg = "assets/catalogues/headers/header_vangelico.webp",
            buyTextType = false,
            buyText = "Acheter",
        },
        eventName = "VangelicoShopVar",
        category = {
            show = true,
            defaultIndex = indexCategory,
            items = {
                {id = "Montres", label = "Montres", image = "assets/catalogues/vangelico/montre2.png"},
                {id = "Coliers", label = "Coliers", image = "assets/catalogues/vangelico/coliers2.png"},
                {id = "Boucle d\'oreilles", label = "Boucle d\'oreilles", image = "assets/catalogues/vangelico/ears2.png"},
                {id = "Bracelets", label = "Bracelets", image = "assets/catalogues/vangelico/bracelet2.png"},
                {id = "Bagues", label = "Bagues", image = "assets/catalogues/vangelico/bague2.png"},
            }
        },
        cameras = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        showStats = false,
        mouseEvents = true,
        color = { show = false },
        items = getComponentVar(category)
    }

    return data
end

---Load Vangelico
---@param data table
function LoadVangelico(data)

    Wait(250)

    cams = data

    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 1 then
            sex = "Femme"
            sexType = "female"
        end
    end)

    cEntity.Visual.HideAllEntities(true)
    cEntity.Visual.AddEntityToException(VFW.PlayerData.ped)
    cEntity.Visual.DisablePlayerCollisions(true)

    VFW.Cam:Create("cam_vangelico", cams[1])

    VFW.Nui.BigMenu(true, VangelicoData())
end

--- closeUI
local function closeUI()
    sex = "Homme"
    sexType = "male"
    cams = nil
    lastCategory = nil
---@class dataId
    dataId = {}
    indexCategory = 0
    cEntity.Visual.HideAllEntities(false)
    VFW.Cam:Destroy('cam_vangelico')
    VFW.Nui.BigMenu(false)
    cEntity.Visual.DisablePlayerCollisions(false)

    Wait(250)
    
end

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShop:selectGridType2", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Montres" then
        SetEntityCoords(VFW.PlayerData.ped, cams[2].COH.x, cams[2].COH.y, cams[2].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[2].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[2])
        indexCategory = 0
    elseif lastCategory == "Coliers" then
        SetEntityCoords(VFW.PlayerData.ped, cams[3].COH.x, cams[3].COH.y, cams[3].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[3].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[3])
        indexCategory = 1
    elseif lastCategory == "Bracelets" then
        SetEntityCoords(VFW.PlayerData.ped, cams[4].COH.x, cams[4].COH.y, cams[4].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[4].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[4])
        indexCategory = 3
    elseif lastCategory == "Boucle d\'oreilles" then
        SetEntityCoords(VFW.PlayerData.ped, cams[5].COH.x, cams[5].COH.y, cams[5].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[5].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[5])
        indexCategory = 2
    elseif lastCategory == "Bagues" then
        SetEntityCoords(VFW.PlayerData.ped, cams[6].COH.x, cams[6].COH.y, cams[6].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[6].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[6])
        indexCategory = 4
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(vangelicoComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopId:selectGridType", function(data)
    if not data then
        return
    end

    if lastCategory == "Montres" then
        TriggerEvent("skinchanger:change", "watches_1", data)
        TriggerEvent("skinchanger:change", "watches_2", 0)
    end

    if lastCategory == "Coliers" then
        TriggerEvent("skinchanger:change", "chain_1", data)
        TriggerEvent("skinchanger:change", "chain_2", 0)
    end

    if lastCategory == "Boucle d\'oreilles" then
        TriggerEvent("skinchanger:change", "ears_1", data)
        TriggerEvent("skinchanger:change", "ears_2", 0)
    end

    if lastCategory == "Bracelets" then
        TriggerEvent("skinchanger:change", "bracelets_1", data)
        TriggerEvent("skinchanger:change", "bracelets_2", 0)
    end

    if lastCategory == "Bagues" then
        TriggerEvent("skinchanger:change", "chain_1", data)
        TriggerEvent("skinchanger:change", "chain_2", 0)
    end

    dataId[lastCategory] = data
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopId:selectBuy", function()
    VFW.Nui.UpdateBigMenu(vangelicoComponentVar(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopId:enter", function()
    VFW.Nui.UpdateBigMenu(vangelicoComponentVar(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopId:selectCategory", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Montres" then
        SetEntityCoords(VFW.PlayerData.ped, cams[2].COH.x, cams[2].COH.y, cams[2].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[2].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[2])
        indexCategory = 0
    elseif lastCategory == "Coliers" then
        SetEntityCoords(VFW.PlayerData.ped, cams[3].COH.x, cams[3].COH.y, cams[3].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[3].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[3])
        indexCategory = 1
    elseif lastCategory == "Bracelets" then
        SetEntityCoords(VFW.PlayerData.ped, cams[4].COH.x, cams[4].COH.y, cams[4].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[4].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[4])
        indexCategory = 3
    elseif lastCategory == "Boucle d\'oreilles" then
        SetEntityCoords(VFW.PlayerData.ped, cams[5].COH.x, cams[5].COH.y, cams[5].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[5].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[5])
        indexCategory = 2
    elseif lastCategory == "Bagues" then
        SetEntityCoords(VFW.PlayerData.ped, cams[6].COH.x, cams[6].COH.y, cams[6].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[6].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[6])
        indexCategory = 4
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(vangelicoComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopId:mouseEvents", function(data)
    SetEntityHeading(VFW.PlayerData.ped, GetEntityHeading(VFW.PlayerData.ped) + (0.5 * data.x))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopVar:selectGridType", function(data)
    if not data then
        return
    end

    if lastCategory == "Montres" then
        TriggerEvent("skinchanger:change", "watches_1", dataId[lastCategory])
        TriggerEvent("skinchanger:change", "watches_2", data)
    end

    if lastCategory == "Coliers" then
        TriggerEvent("skinchanger:change", "chain_1", dataId[lastCategory])
        TriggerEvent("skinchanger:change", "chain_2", data)
    end

    if lastCategory == "Boucle d\'oreilles" then
        TriggerEvent("skinchanger:change", "ears_1", dataId[lastCategory])
        TriggerEvent("skinchanger:change", "ears_2", data)
    end

    if lastCategory == "Bracelets" then
        TriggerEvent("skinchanger:change", "bracelets_1", dataId[lastCategory])
        TriggerEvent("skinchanger:change", "bracelets_2", data)
    end

    if lastCategory == "Bagues" then
        TriggerEvent("skinchanger:change", "chain_1", dataId[lastCategory])
        TriggerEvent("skinchanger:change", "chain_2", data)
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopVar:selectCategory", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Montres" then
        SetEntityCoords(VFW.PlayerData.ped, cams[2].COH.x, cams[2].COH.y, cams[2].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[2].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[2])
        indexCategory = 0
    elseif lastCategory == "Coliers" then
        SetEntityCoords(VFW.PlayerData.ped, cams[3].COH.x, cams[3].COH.y, cams[3].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[3].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[3])
        indexCategory = 1
    elseif lastCategory == "Bracelets" then
        SetEntityCoords(VFW.PlayerData.ped, cams[4].COH.x, cams[4].COH.y, cams[4].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[4].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[4])
        indexCategory = 3
    elseif lastCategory == "Boucle d\'oreilles" then
        SetEntityCoords(VFW.PlayerData.ped, cams[5].COH.x, cams[5].COH.y, cams[5].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[5].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[5])
        indexCategory = 2
    elseif lastCategory == "Bagues" then
        SetEntityCoords(VFW.PlayerData.ped, cams[6].COH.x, cams[6].COH.y, cams[6].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[6].COH.w)
        VFW.Cam:Update('cam_vangelico', cams[6])
        indexCategory = 4
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(vangelicoComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopVar:selectBuy", function()
    if lastCategory == "Montres" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.watches_1,
                type = "watch",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.watches_1,
                var = skin.watches_2
            })
            goodAchat = chack
        end)
    elseif lastCategory == "Coliers" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.chain_1,
                type = "necklace",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.chain_1,
                var = skin.chain_2
            })
            goodAchat = chack
        end)
    elseif lastCategory == "Bracelets" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.bracelets_1,
                type = "bracelet",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.bracelets_1,
                var = skin.bracelets_2
            })
            goodAchat = chack
        end)
    elseif lastCategory == "Boucle d\'oreilles" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.ears_1,
                type = "earring",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.ears_1,
                var = skin.ears_2
            })
            goodAchat = chack
        end)
    elseif lastCategory == "Bagues" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.chain_1,
                type = "necklace",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.chain_1,
                var = skin.chain_2
            })
            goodAchat = chack
        end)
    end

    VFW.Nui.UpdateBigMenu(vangelicoComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopVar:enter", function()
    if lastCategory == "Montres" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.watches_1,
                type = "watch",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.watches_1,
                var = skin.watches_2
            })
            goodAchat = chack
        end)
    elseif lastCategory == "Coliers" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.chain_1,
                type = "necklace",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.chain_1,
                var = skin.chain_2
            })
            goodAchat = chack
        end)
    elseif lastCategory == "Bracelets" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.bracelets_1,
                type = "bracelet",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.bracelets_1,
                var = skin.bracelets_2
            })
            goodAchat = chack
        end)
    elseif lastCategory == "Boucle d\'oreilles" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.ears_1,
                type = "earring",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.ears_1,
                var = skin.ears_2
            })
            goodAchat = chack
        end)
    elseif lastCategory == "Bagues" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local chack = TriggerServerCallback("core:server:buyVangelico", "accessory", {
                renamed = skin.chain_1,
                type = "necklace",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.chain_1,
                var = skin.chain_2
            })
            goodAchat = chack
        end)
    end

    VFW.Nui.UpdateBigMenu(vangelicoComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopVar:mouseEvents", function(data)
    SetEntityHeading(VFW.PlayerData.ped, GetEntityHeading(VFW.PlayerData.ped) + (0.5 * data.x))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopVar:backspace", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    VFW.Nui.UpdateBigMenu(vangelicoComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopId:backspace", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    VFW.Nui.UpdateBigMenu(VangelicoData())
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopVar:close", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    closeUI()
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShopId:close", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    closeUI()
end)

RegisterNuiCallback("nui:newgrandcatalogue:VangelicoShop:close", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    closeUI()
end)
