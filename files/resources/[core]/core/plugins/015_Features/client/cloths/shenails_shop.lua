---@meta _
---@diagnostic disable: duplicate-doc-field

local sex = "Homme"
local cams = nil
local lastCategory = nil
local drawableIdSheNails = {
    Maquillage = GetPedHeadOverlayNum(4),
    RougeLevre = GetPedHeadOverlayNum(8),
    Blush = GetNumHeadOverlayValues(5),
    PilositeTorse = GetNumHeadOverlayValues(10),
}
local componentIdData = {}
local componentVarData = {}
local dataId = {}
local indexCategory = 0
local goodAchat = false

--- SheNailsData
local function SheNailsData()
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 1,
            gridType = 2,
            buyType = 0,
            lineColor = "linear-gradient(to right, rgba(139, 106, 34, .6) 0%, rgba(234, 215, 148, .6) 56%, rgba(219, 200, 147, 0) 100%)",
            title = "SHENAILS",
        },
        eventName = "SheNailsShop",
        showStats = false,
        mouseEvents = false,
        color = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        category = { show = false },
        cameras = { show = false },
        color = { show = false },
---@class items
        items = {}
    }

    data.items = {}

    return data
end

---Get ComponentId
---@param category any
local function getComponentId(category)
    componentIdData[category] = {}
    local list = Config.SheNails[sex]
    local name

    if category == "Piercing" then
        name = "piercing"
    elseif category == "Ongles" then
        name = "nails"
    elseif category == "PilositeTorse" then
        name = "PilositeTorse"
    elseif category == "Blush" then
        name = "Blush"
    elseif category == "RougeLevre" then
        name = "RougeLevre"
    elseif category == "Maquillage" then
        name = "Maquillage"
    end

    local shopPrice = TriggerServerCallback("core:getClothesPrice")


    if category == "Piercing" then
        for i = 0, GetNumberOfPedDrawableVariations(PlayerPedId(), 10) - 1 do
            if VFW.Table.TableContains(list.piercingList, i) then
                local tempCatalogue = {
                    label = i,
                    model = i,
                    premium = false,
                    price = VFW.Math.GroupDigits(shopPrice[sex] and shopPrice[sex][name] and shopPrice[sex][name].price or 100),
                    image = "assets/catalogues/shenails/"..sex.."/Piercing/"..i.."_1.webp"
                }

                table.insert(componentIdData[category], tempCatalogue)
            end
        end
    elseif category == "Ongles" then
        for i = 0, GetNumberOfPedDrawableVariations(PlayerPedId(), 10) - 1 do
            if VFW.Table.TableContains(list.ongleList, i) then
                local tempCatalogue = {
                    label = i,
                    model = i,
                    premium = false,
                    price = VFW.Math.GroupDigits(shopPrice[sex] and shopPrice[sex][name] and shopPrice[sex][name].price or 100),
                    image = "assets/catalogues/shenails/"..sex.."/Ongles/"..i.."_1.webp"
                }

                table.insert(componentIdData[category], tempCatalogue)
            end
        end
    else
        if drawableIdSheNails[category] then
            for i = 0, drawableIdSheNails[category] - 1 do
                local tempCatalogue = {
                    label = i,
                    model = i,
                    premium = false,
                    price = VFW.Math.GroupDigits(shopPrice[sex] and shopPrice[sex][name] and shopPrice[sex][name].price or 100),
                    image = "assets/catalogues/shenails/"..sex.."/"..category.."/"..i..".webp"
                }

                table.insert(componentIdData[category], tempCatalogue)
            end
        end
    end

    return componentIdData[category]
end

--- sheNailsComponentId
---@param category any
---@param indexCategory any
local function sheNailsComponentId(category, indexCategory)
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 2,
            gridType = 1,
            buyType = 2,
            bannerImg = "assets/catalogues/headers/header_shenails.webp",
            buyTextType = false,
            buyText = "Selectionner",
        },
        eventName = "SheNailsShopId",
        category = {
            show = false,
            defaultIndex = 0,
            items = {}
        },
        cameras = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        showStats = false,
        mouseEvents = true,
        color = { show = false },
        items = {}
    }

    return data
end

---Get ComponentVar
---@param category any
local function getComponentVar(category)
    componentVarData[category] = {}

    local name

    if category == "Piercing" then
        name = "piercing"
    elseif category == "Ongles" then
        name = "nails"
    elseif category == "PilositeTorse" then
        name = "PilositeTorse"
    elseif category == "Blush" then
        name = "Blush"
    elseif category == "RougeLevre" then
        name = "RougeLevre"
    elseif category == "Maquillage" then
        name = "Maquillage"
    end

    for i = 1, GetNumberOfPedTextureVariations(PlayerPedId(), 10, dataId[category]) do
        local tempCatalogue = {
            label = i,
            model = i,
            premium = false,
            price = VFW.Math.GroupDigits(shopPrice[sex] and shopPrice[sex][name] and shopPrice[sex][name].price or 100),
            image = "assets/catalogues/shenails/"..sex.."/"..category.."/"..dataId[category].."_"..i..".webp"
        }

        table.insert(componentVarData[category], tempCatalogue)
    end

    return componentVarData[category] or {}
end

--- sheNailsComponentVar
---@param category any
---@param indexCategory any
---@return any
local function sheNailsComponentVar(category, indexCategory)
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 2,
            gridType = 1,
            buyType = 2,
            bannerImg = "assets/catalogues/headers/header_shenails.webp",
            buyTextType = false,
            buyText = "Acheter",
        },
        eventName = "SheNailsShopVar",
        category = {
            show = false,
            defaultIndex = 0,
            items = {}
        },
        cameras = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        showStats = false,
        mouseEvents = true,
        color = { show = false },
        items = {}
    }

    return data
end

---Load SheNails
---@param data table
function LoadSheNails(data)
    cams = data


    Wait(250)

    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 1 then
            sex = "Femme"
        end
    end)

    cEntity.Visual.HideAllEntities(true)
    cEntity.Visual.AddEntityToException(VFW.PlayerData.ped)
    cEntity.Visual.DisablePlayerCollisions(true)

    VFW.Cam:Create("cam_manucure", cams[1])

    VFW.Nui.BigMenu(true, SheNailsData())
end

--- closeUI
local function closeUI()
    sex = "Homme"
    cams = nil
    lastCategory = nil
---@class dataId
    dataId = {}
    indexCategory = 0
    cEntity.Visual.HideAllEntities(false)
    VFW.Cam:Destroy('cam_manucure')
    VFW.Nui.BigMenu(false)
    cEntity.Visual.DisablePlayerCollisions(false)

    Wait(250)
    
end

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShop:selectGridType2", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Ongles" then
        SetEntityCoords(VFW.PlayerData.ped, cams[3].COH.x, cams[3].COH.y, cams[3].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[3].COH.w)
        VFW.Cam:Update('cam_manucure', cams[3])
        indexCategory = 5
    elseif lastCategory == "PilositeTorse" then
        indexCategory = 0
    elseif lastCategory == "Maquillage" or lastCategory == "RougeLevre" or lastCategory == "Blush" or lastCategory == "Piercing" then
        SetEntityCoords(VFW.PlayerData.ped, cams[2].COH.x, cams[2].COH.y, cams[2].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[2].COH.w)
        VFW.Cam:Update('cam_manucure', cams[2])
        if lastCategory == "Maquillage" then
            indexCategory = 4
        elseif lastCategory == "RougeLevre" then
            indexCategory = 3
        elseif lastCategory == "Blush" then
            indexCategory = 2
        elseif lastCategory == "Piercing" then
            indexCategory = 1
            SetEntityCoords(VFW.PlayerData.ped, cams[4].COH.x, cams[4].COH.y, cams[4].COH.z - 1)
            SetEntityHeading(VFW.PlayerData.ped, cams[4].COH.w)
            VFW.Cam:Update('cam_manucure', cams[4])
        end
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(sheNailsComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:selectGridType", function(data)
    if not data then
        return
    end

    if lastCategory == "Ongles" or lastCategory == "Piercing" then
        TriggerEvent("skinchanger:change", "decals_1", data)
        TriggerEvent("skinchanger:change", "decals_2", 0)
    elseif lastCategory == "PilositeTorse" then
        TriggerEvent("skinchanger:change", "chest_1", data)
        TriggerEvent("skinchanger:change", "chest_2", 10)
    elseif lastCategory == "Blush" then
        TriggerEvent("skinchanger:change", "blush_1", data)
        TriggerEvent("skinchanger:change", "blush_2", 10)
    elseif lastCategory == "RougeLevre" then
        TriggerEvent("skinchanger:change", "lipstick_1", data)
        TriggerEvent("skinchanger:change", "lipstick_2", 10)
    elseif lastCategory == "Maquillage" then
        TriggerEvent("skinchanger:change", "makeup_1", data)
        TriggerEvent("skinchanger:change", "makeup_2", 10)
    end

    dataId[lastCategory] = data
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:selectBuy", function()
    if lastCategory == "Ongles" or lastCategory == "Piercing" then
        VFW.Nui.UpdateBigMenu(sheNailsComponentVar(lastCategory, indexCategory))
    else
        local getMoney = TriggerServerCallback("core:server:getClothesMoney", "sheNails")

        if getMoney then
            TriggerEvent("skinchanger:getSkin", function(skin)
                TriggerServerEvent("vfw:skin:save", skin)
                TriggerEvent('skinchanger:loadSkin', skin or {})
            end)
        else
            local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
            TriggerEvent('skinchanger:loadSkin', skin or {})
        end
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:enter", function()
    if lastCategory == "Ongles" or lastCategory == "Piercing" then
        VFW.Nui.UpdateBigMenu(sheNailsComponentVar(lastCategory, indexCategory))
    else
        local getMoney = TriggerServerCallback("core:server:getClothesMoney", "sheNails")

        if getMoney then
            TriggerEvent("skinchanger:getSkin", function(skin)
                TriggerServerEvent("vfw:skin:save", skin)
                TriggerEvent('skinchanger:loadSkin', skin or {})
            end)
        else
            local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
            TriggerEvent('skinchanger:loadSkin', skin or {})
        end
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:changeColor1", function(data)
    if not data then
        return
    end

    if lastCategory == "PilositeTorse" then
        TriggerEvent("skinchanger:change", "chest_3", data)
    elseif lastCategory == "Blush" then
        TriggerEvent("skinchanger:change", "blush_3", data)
    elseif lastCategory == "RougeLevre" then
        TriggerEvent("skinchanger:change", "lipstick_3", data)
    elseif lastCategory == "Maquillage" then
        TriggerEvent("skinchanger:change", "makeup_3", data)
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:changeColor2", function(data)
    if not data then
        return
    end

    if lastCategory == "PilositeTorse" then
        TriggerEvent("skinchanger:change", "chest_4", data)
    elseif lastCategory == "Blush" then
        TriggerEvent("skinchanger:change", "blush_4", data)
    elseif lastCategory == "RougeLevre" then
        TriggerEvent("skinchanger:change", "lipstick_4", data)
    elseif lastCategory == "Maquillage" then
        TriggerEvent("skinchanger:change", "makeup_4", data)
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:changeOpacity", function(data)
    if not data then
        return
    end

    if lastCategory == "PilositeTorse" then
        TriggerEvent("skinchanger:change", "chest_2", data / 10)
    elseif lastCategory == "Blush" then
        TriggerEvent("skinchanger:change", "blush_2", data / 10)
    elseif lastCategory == "RougeLevre" then
        TriggerEvent("skinchanger:change", "lipstick_2", data / 10)
    elseif lastCategory == "Maquillage" then
        TriggerEvent("skinchanger:change", "makeup_2", data / 10)
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:selectCategory", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Ongles" then
        SetEntityCoords(VFW.PlayerData.ped, cams[3].COH.x, cams[3].COH.y, cams[3].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[3].COH.w)
        VFW.Cam:Update('cam_manucure', cams[3])
        indexCategory = 5
    elseif lastCategory == "PilositeTorse" then
        indexCategory = 0
    elseif lastCategory == "Maquillage" or lastCategory == "RougeLevre" or lastCategory == "Blush" or lastCategory == "Piercing" then
        SetEntityCoords(VFW.PlayerData.ped, cams[2].COH.x, cams[2].COH.y, cams[2].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[2].COH.w)
        VFW.Cam:Update('cam_manucure', cams[2])
        if lastCategory == "Maquillage" then
            indexCategory = 4
        elseif lastCategory == "RougeLevre" then
            indexCategory = 3
        elseif lastCategory == "Blush" then
            indexCategory = 2
        elseif lastCategory == "Piercing" then
            indexCategory = 1
            SetEntityCoords(VFW.PlayerData.ped, cams[4].COH.x, cams[4].COH.y, cams[4].COH.z - 1)
            SetEntityHeading(VFW.PlayerData.ped, cams[4].COH.w)
            VFW.Cam:Update('cam_manucure', cams[4])
        end
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(sheNailsComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:mouseEvents", function(data)
    SetEntityHeading(VFW.PlayerData.ped, GetEntityHeading(VFW.PlayerData.ped) + (0.5 * data.x))
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopVar:selectGridType", function(data)
    if not data then
        return
    end

    if lastCategory == "Ongles" or lastCategory == "Piercing" then
        TriggerEvent("skinchanger:change", "decals_1", dataId[lastCategory])
        TriggerEvent("skinchanger:change", "decals_2", data)
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopVar:selectBuy", function()
    if lastCategory == "Ongles" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local check = TriggerServerCallback("core:server:buyClothe", "accessory", {
                renamed = skin.chain_1,
                type = "nails",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.decals_1,
                var = skin.decals_2
            })
            goodAchat = check
        end)
    elseif lastCategory == "Piercing" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local check = TriggerServerCallback("core:server:buyClothe", "accessory", {
                renamed = skin.chain_1,
                type = "piercing",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.decals_1,
                var = skin.decals_2
            })
            goodAchat = check
        end)
    end

    VFW.Nui.UpdateBigMenu(sheNailsComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopVar:enter", function()
    if lastCategory == "Ongles" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local check = TriggerServerCallback("core:server:buyClothe", "accessory", {
                renamed = skin.chain_1,
                type = "nails",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.decals_1,
                var = skin.decals_2
            })
            goodAchat = check
        end)
    elseif lastCategory == "Piercing" then
        TriggerEvent('skinchanger:getSkin', function(skin)
            local check = TriggerServerCallback("core:server:buyClothe", "accessory", {
                renamed = skin.chain_1,
                type = "piercing",
                sex = skin.sex == 1 and "w" or "m",
                id = skin.decals_1,
                var = skin.decals_2
            })
            goodAchat = check
        end)
    end

    VFW.Nui.UpdateBigMenu(sheNailsComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopVar:selectCategory", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Ongles" then
        SetEntityCoords(VFW.PlayerData.ped, cams[3].COH.x, cams[3].COH.y, cams[3].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[3].COH.w)
        VFW.Cam:Update('cam_manucure', cams[3])
        indexCategory = 5
    elseif lastCategory == "PilositeTorse" then
        indexCategory = 0
    elseif lastCategory == "Maquillage" or lastCategory == "RougeLevre" or lastCategory == "Blush" or lastCategory == "Piercing" then
        SetEntityCoords(VFW.PlayerData.ped, cams[2].COH.x, cams[2].COH.y, cams[2].COH.z - 1)
        SetEntityHeading(VFW.PlayerData.ped, cams[2].COH.w)
        VFW.Cam:Update('cam_manucure', cams[2])
        if lastCategory == "Maquillage" then
            indexCategory = 4
        elseif lastCategory == "RougeLevre" then
            indexCategory = 3
        elseif lastCategory == "Blush" then
            indexCategory = 2
        elseif lastCategory == "Piercing" then
            indexCategory = 1
        end
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(sheNailsComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopVar:mouseEvents", function(data)
    SetEntityHeading(VFW.PlayerData.ped, GetEntityHeading(VFW.PlayerData.ped) + (0.5 * data.x))
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopVar:backspace", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    VFW.Nui.UpdateBigMenu(sheNailsComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:backspace", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    VFW.Nui.UpdateBigMenu(SheNailsData())
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopVar:close", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    closeUI()
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShopId:close", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    closeUI()
end)

RegisterNuiCallback("nui:newgrandcatalogue:SheNailsShop:close", function()
    if not goodAchat then
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

        TriggerEvent('skinchanger:loadSkin', skin or {})
    end

    closeUI()
end)
