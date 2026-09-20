---@meta _
---@diagnostic disable: duplicate-doc-field

local sex = "Homme"
local lastCategory = nil
local componentIdData = {}
local indexCategory = 0
local lastObject = nil
local lastChairData = nil
local open = false
local currentCamGroup = nil

--- BarberData
local function BarberData()
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 1,
            gridType = 2,
            buyType = 0,
            lineColor = "linear-gradient(to right, rgba(139, 106, 34, .6) 0%, rgba(234, 215, 148, .6) 56%, rgba(219, 200, 147, 0) 100%)",
            title = "BARBER",
        },
        eventName = "barberShop",
        showStats = false,
        mouseEvents = false,
        color = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        category = { show = false },
        cameras = { show = false },
        color = { show = false },
        items = {
            {
                label = 'COUPES',
                model = 'Coupe',
                image = "assets/catalogues/barber/cheveux.png",
                style = "big",
            },
            {
                label = 'DEGRADE',
                model = 'Degradé',
                image = "assets/catalogues/barber/degrader.png",
                style = "normal",
            },
            {
                label = 'YEUX',
                model = 'Yeux',
                image = "assets/catalogues/barber/yeux.png",
                style = "normal",
            },
            {
                label = 'SOURCILS',
                model = 'Sourcils',
                image = "assets/catalogues/barber/eyebrow.png",
                style = "normal",
            },
        }
    }

    if sex == "Homme" then
        table.insert(data.items, { label = "Barbe", model = "Barbe", image = "assets/catalogues/barber/barbe.png", style = "normal" })
    end

    return data
end

---Get ComponentId
---@param category any
local function getComponentId(category)
    componentIdData[category] = {}

    if category == "Coupe" then
        table.insert(componentIdData[category], {
            label = "Aucun",
            model = 0,
            premium = false,
            image = VFW.OutfitPlaceholderUrl and VFW.OutfitPlaceholderUrl() or "outfits_greenscreener/aucun.svg"
        })

        for i = 1, GetNumberOfPedDrawableVariations(VFW.PlayerData.ped, 2) - 1 do
            if not VFW.Table.TableContains(Config.BarberBan[sex].CoupesBan, i) then
                local tempCatalogue = {
                    label = i,
                    model = i,
                    premium = false,
                    price = VFW.Math.GroupDigits(20),
                    image = "assets/catalogues/barber/" .. sex .. "/Coupes/" .. i .. ".webp"
                }

                table.insert(componentIdData[category], tempCatalogue)
            end
        end
    elseif category == "Yeux" then
        for i = 0, 31 do
            local tempCatalogue = {
                label = i,
                model = i,
                premium = false,
                price = VFW.Math.GroupDigits(20),
                image = "assets/catalogues/barber/" .. sex .. "/Yeux/" .. i .. ".webp"
            }

            table.insert(componentIdData[category], tempCatalogue)
        end
    elseif category == "Barbe" then
        table.insert(componentIdData[category], {
            label = "Aucun",
            model = -1,
            premium = false,
            image = VFW.OutfitPlaceholderUrl and VFW.OutfitPlaceholderUrl() or "outfits_greenscreener/aucun.svg"
        })

        for i = 0, GetNumHeadOverlayValues(1) do
            local tempCatalogue = {
                label = i,
                model = i,
                premium = false,
                price = VFW.Math.GroupDigits(20),
                image = "assets/catalogues/barber/" .. sex .. "/Barbes/" .. i .. ".webp"
            }

            table.insert(componentIdData[category], tempCatalogue)
        end
    elseif category == "Sourcils" then
        for i = 0, GetPedHeadOverlayNum(2) do
            local tempCatalogue = {
                label = i,
                model = i,
                premium = false,
                price = VFW.Math.GroupDigits(20),
                image = "assets/catalogues/shenails/" .. sex .. "/Sourcils/" .. i .. ".webp"
            }

            table.insert(componentIdData[category], tempCatalogue)
        end
    elseif category == "Degradé" then
        table.insert(componentIdData[category], {
            label = "Aucun",
            model = -1,
            premium = false,
            image = VFW.OutfitPlaceholderUrl and VFW.OutfitPlaceholderUrl() or "outfits_greenscreener/aucun.svg"
        })

        local tattoos = GetDegrader()

        for i = 1, #tattoos do
            local tattoo = tattoos[i]

            if tattoos[i].Zone == "ZONE_HEAD" then
                local tempCatalogue = {
                    label = i,
                    model = i,
                    premium = false,
                    price = VFW.Math.GroupDigits(20),
                    image = "assets/catalogues/tattoo/tattooList/" .. tattoo.HashNameMale:gsub("_[MF]$", ""):lower() .. ".png"
                }

                table.insert(componentIdData[category], tempCatalogue)
            end
        end
    end

    return componentIdData[category]
end

--- barberComponentId
---@param category any
---@param indexCategory any
local function barberComponentId(category, indexCategory)
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 2,
            gridType = 1,
            buyType = 2,
            bannerImg = "assets/catalogues/headers/header_barbershop.webp",
            buyTextType = false,
            buyText = "Acheter",
        },
        eventName = "barberShopId",
        category = {
            show = true,
            defaultIndex = indexCategory,
            items = {
                { id = "Sourcils", label = "Sourcils", image = "assets/catalogues/barber/eyebrow2.png" },
                { id = "Yeux", label = "Yeux", image = "assets/catalogues/barber/yeux2.png" },
                { id = "Degradé", label = "Degradé", image = "assets/catalogues/barber/degrader2.png" },
                { id = "Coupe", label = "Coupes", image = "assets/catalogues/barber/cheveux2.png" },
            }
        },
        cameras = {
            show = true,
            label = "Caméras",
            items = {
                { id = "profil", image = "assets/icons/eyee.svg" },
                { id = "face", image = "assets/icons/eyee.svg" },
                { id = "dos", image = "assets/icons/eyee.svg" }
            }
        },
        nameContainer = { show = false },
        headCategory = { show = false },
        showStats = false,
        mouseEvents = false,
        color = { show = false },
        items = getComponentId(category)
    }

    if category == "Sourcils" or category == "Barbe" then
        data.color = {
            show = true,
            primary = true,
            primary_color = 0,
            secondary = true,
            secondary_color = 0,
            opacity = true,
            opacity_percent = 0
        }
    elseif category == "Coupe" then
        data.color = {
            show = true,
            primary = true,
            primary_color = 0,
            secondary = true,
            secondary_color = 0,
            opacity = false,
            opacity_percent = 0
        }
    end

    if sex == "Homme" then
        table.insert(data.category.items, { id = "Barbe", label = "Barbe", image = "assets/catalogues/barber/barbe2.png" })
    end

    if category == "Yeux" then
        data.cameras = { show = false }
    end

    return data
end

---Load BarberAnimIn
local function loadBarberAnimIn()
    local playerPed = VFW.PlayerData.ped
    local anim = "misshair_shop@hair_dressers"

    VFW.Streaming.RequestAnimDict(anim)

    local px, py, pz, chairHeading

    -- 1. Priorité à l'entité physique si elle existe
    if DoesEntityExist(lastObject) then
        px, py, pz = table.unpack(GetEntityCoords(lastObject))
        chairHeading = GetEntityHeading(lastObject)
        -- 2. Sinon, on utilise les données sauvegardées (Fallback)
    elseif lastChairData then
        px, py, pz = lastChairData.x, lastChairData.y, lastChairData.z
        chairHeading = lastChairData.w or 0.0 -- 'w' contient le heading si sauvegardé par le nouveau builder
    end

    if px and py and pz then
        local followCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        local camOffset = vector3(0.0, -1.5, 1.0)
        local camPos = GetOffsetFromEntityInWorldCoords(playerPed, camOffset.x, camOffset.y, camOffset.z)

        SetCamCoord(followCam, camPos.x, camPos.y, camPos.z)
        PointCamAtEntity(followCam, playerPed, 0.0, 0.0, 0.6, true)
        SetCamActive(followCam, true)
        RenderScriptCams(true, false, 0, true, true)

        local targetHeading = chairHeading - 90.0

        TaskPlayAnimAdvanced(playerPed, anim, "player_enterchair", vector3(px, py, pz + 0.2), vector3(0.0, 0.0, targetHeading), 8.0, -8.0, -1, 5642, 0.0, 2, 1)

        while not HasEntityAnimFinished(playerPed, anim, "player_enterchair", 3) do
            local camPos = GetOffsetFromEntityInWorldCoords(playerPed, camOffset.x, camOffset.y, camOffset.z)
            SetCamCoord(followCam, camPos.x, camPos.y, camPos.z)
            Wait(0)
        end

        TaskPlayAnimAdvanced(playerPed, anim, "player_base", vector3(px, py, pz + 0.2), vector3(0.0, 0.0, targetHeading), 8.0, -8.0, -1, 5641, 0.0, 2, 1)

        DestroyCam(followCam)
        RenderScriptCams(false, false, 0, true, true)
        Wait(150)
        VFW.Cam:Create('cam_barber', Config.Features.Barber.Cam[1])
    end
end

---Load BarberAnimOut
local function loadBarberAnimOut()
    local playerPed = VFW.PlayerData.ped
    local animDict = "misshair_shop@hair_dressers"

    VFW.Streaming.RequestAnimDict(animDict)

    local px, py, pz, chairHeading

    if DoesEntityExist(lastObject) then
        px, py, pz = table.unpack(GetEntityCoords(lastObject))
        chairHeading = GetEntityHeading(lastObject)
    elseif lastChairData then
        px, py, pz = lastChairData.x, lastChairData.y, lastChairData.z
        chairHeading = lastChairData.w or 0.0
    end

    if px and py and pz then
        local targetHeading = chairHeading - 90.0

        TaskPlayAnimAdvanced(playerPed, animDict, "exitchair_female", vector3(px, py, pz + 0.2), vector3(0.0, 0.0, targetHeading), 8.0, -8.0, -1, 5642, 0.2, 2, 1)

        local animDuration = (GetAnimDuration(animDict, "exitchair_female") * 1000) - 3000
        Wait(animDuration)

        RemoveAnimDict("misshair_shop@barbers")
        RemoveAnimDict(animDict)

        Wait(1500)
        ClearPedTasks(playerPed)
        Wait(1000)
    end
end

local function LoadBarber()
    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin.sex == 0 or skin.sex == 1 then
            isShopOpen = true -- Usamos la variable de tu sistema moderno
            open = true       -- Mantenemos tu variable local para el bucle de la silla

            if skin.sex == 1 then
                sex = "Femme"
            end


            Wait(250)

            -- Escondemos entidades (lógica de tu script moderno)
            cEntity.Visual.HideAllEntities(true)
            cEntity.Visual.AddEntityToException(VFW.PlayerData.ped)

            -- Ejecutamos la animación de sentarse que ya tenías
            loadBarberAnimIn()

            -- LLAMADA AL NUEVO MENÚ EN LUGAR DEL BIGMENU
            OpenModernClothingShop({
                Title = "Barbier",
                shopType = "barber"
            }, false)

        else
            VFW.ShowNotification({
                type = "ROUGE",
                content = "Les peds ne peuvent pas utiliser le barber shop.",
            })
        end
    end)
end

-- Escuchamos el evento que viene desde el script de ropa
AddEventHandler('vfw_barber:forceExitAnim', function()
    -- Ejecutamos tu función de limpieza y animación de salida
    closeUI()
end)

-- Asegúrate de que tu función closeUI esté lista para limpiar todo
function closeUI()
    if not open then return end
    isShopOpen = false

    -- La animación de levantarse que ya tenías programada
    loadBarberAnimOut()

    -- Reset de variables de barbería
    sex = "Homme"
    lastCategory = nil
    indexCategory = 0
    componentIdData = {}
    lastObject = nil
    lastChairData = nil -- Reset des données fallback
    currentCamGroup = nil

    open = false
end

RegisterNuiCallback("nui:newgrandcatalogue:barberShop:selectGridType2", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Yeux" or lastCategory == "Sourcils" then
        if lastCategory == "Yeux" then
            indexCategory = 1
        else
            indexCategory = 0
        end

        VFW.Cam:Update('cam_barber', Config.Features.Barber.Cam[4])
        currentCamGroup = "face"
    else
        if lastCategory == "Coupe" then
            indexCategory = 3
        elseif lastCategory == "Barbe" then
            indexCategory = 4
        elseif lastCategory == "Degradé" then
            indexCategory = 2
        end

        VFW.Cam:Update('cam_barber', Config.Features.Barber.Cam[1])
        currentCamGroup = "head"
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(barberComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:selectGridType", function(data)
    if not data then
        return
    end

    if lastCategory == "Degradé" then
        local tattoos = GetDegrader()
        ClearPedDecorations(VFW.PlayerData.ped)
        if data ~= -1 then
            TriggerEvent("skinchanger:change", "degrade_collection", joaat(tattoos[data].Collection))
            TriggerEvent("skinchanger:change", "degrade_hashname", joaat(tattoos[data].HashNameMale))
        else
            TriggerEvent("skinchanger:change", "degrade_collection", data)
            TriggerEvent("skinchanger:change", "degrade_hashname", data)
        end
    elseif lastCategory == "Barbe" then
        TriggerEvent("skinchanger:change", "beard_1", data)
        TriggerEvent("skinchanger:change", "beard_2", 10)
    elseif lastCategory == "Sourcils" then
        TriggerEvent("skinchanger:change", "eyebrows_1", data)
        TriggerEvent("skinchanger:change", "eyebrows_2", 10)
    elseif lastCategory == "Coupe" then
        TriggerEvent("skinchanger:change", "hair_1", data)
    elseif lastCategory == "Yeux" then
        TriggerEvent("skinchanger:change", "eye_color", data)
    end

    for _, tattoo in ipairs(VFW.PlayerData.tattoos) do
        AddPedDecorationFromHashes(VFW.PlayerData.ped, tattoo.Collection, tattoo.Hash)
    end

    ClearPedProp(VFW.PlayerData.ped, 0)
    ClearPedProp(VFW.PlayerData.ped, 1)
    SetPedComponentVariation(VFW.PlayerData.ped, 1, 0, 0, 2)
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:selectBuy", function()
    local paymentType = (lastCategory == "Barbe") and "beard" or "hair"
    local getMoney = TriggerServerCallback("core:server:getClothesMoney", paymentType)

    if getMoney then
        TriggerEvent("skinchanger:getSkin", function(skin)
            TriggerServerEvent("vfw:skin:save", skin)
            TriggerEvent('skinchanger:loadSkin', skin or {})
        end)
    else
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
        TriggerEvent('skinchanger:loadSkin', skin or {})
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:enter", function()
    local paymentType = (lastCategory == "Barbe") and "beard" or "hair"
    local getMoney = TriggerServerCallback("core:server:getClothesMoney", paymentType)

    if getMoney then
        TriggerEvent("skinchanger:getSkin", function(skin)
            TriggerServerEvent("vfw:skin:save", skin)
            TriggerEvent('skinchanger:loadSkin', skin or {})
        end)
    else
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
        TriggerEvent('skinchanger:loadSkin', skin or {})
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:changeColor1", function(data)
    if not data then
        return
    end


    if lastCategory == "Coupe" then
        TriggerEvent("skinchanger:change", "hair_color_1", data)
    elseif lastCategory == "Barbe" then
        TriggerEvent("skinchanger:change", "beard_3", data)
    elseif lastCategory == "Sourcils" then
        TriggerEvent("skinchanger:change", "eyebrows_3", data)
    end

    ClearPedProp(VFW.PlayerData.ped, 0)
    ClearPedProp(VFW.PlayerData.ped, 1)
    SetPedComponentVariation(VFW.PlayerData.ped, 1, 0, 0, 2)
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:changeColor2", function(data)
    if not data then
        return
    end

    if lastCategory == "Coupe" then
        TriggerEvent("skinchanger:change", "hair_color_2", data)
    elseif lastCategory == "Barbe" then
        TriggerEvent("skinchanger:change", "beard_4", data)
    elseif lastCategory == "Sourcils" then
        TriggerEvent("skinchanger:change", "eyebrows_4", data)
    end

    ClearPedProp(VFW.PlayerData.ped, 0)
    ClearPedProp(VFW.PlayerData.ped, 1)
    SetPedComponentVariation(VFW.PlayerData.ped, 1, 0, 0, 2)
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:changeOpacity", function(data)
    if not data then
        return
    end

    if lastCategory == "Sourcils" then
        TriggerEvent("skinchanger:change", "eyebrows_2", data / 10)
    elseif lastCategory == "Barbe" then
        TriggerEvent("skinchanger:change", "beard_2", data / 10)
    end

    ClearPedProp(VFW.PlayerData.ped, 0)
    ClearPedProp(VFW.PlayerData.ped, 1)
    SetPedComponentVariation(VFW.PlayerData.ped, 1, 0, 0, 2)
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:selectCategory", function(data)
    if not data then
        return
    end

    lastCategory = data
    if lastCategory == "Yeux" or lastCategory == "Sourcils" then
        if lastCategory == "Yeux" then
            indexCategory = 1
        else
            indexCategory = 0
        end

        if currentCamGroup ~= "face" then
            VFW.Cam:Update('cam_barber', Config.Features.Barber.Cam[4])
            currentCamGroup = "face"
        end
    else
        if lastCategory == "Coupe" then
            indexCategory = 3
        elseif lastCategory == "Barbe" then
            indexCategory = 4
        elseif lastCategory == "Degradé" then
            indexCategory = 2
        end

        if currentCamGroup ~= "head" then
            VFW.Cam:Update('cam_barber', Config.Features.Barber.Cam[1])
            currentCamGroup = "head"
        end
    end

    Wait(50)
    VFW.Nui.UpdateBigMenu(barberComponentId(lastCategory, indexCategory))
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:selectCamera", function(data)
    if data == "profil" then
        VFW.Cam:Update('cam_barber', Config.Features.Barber.Cam[1])
    elseif data == "face" then
        VFW.Cam:Update('cam_barber', Config.Features.Barber.Cam[2])
    elseif data == "dos" then
        VFW.Cam:Update('cam_barber', Config.Features.Barber.Cam[3])
    end
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:backspace", function()
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

    TriggerEvent('skinchanger:loadSkin', skin or {})
    VFW.Cam:Update('cam_barber', Config.Features.Barber.Cam[1])
    VFW.Nui.UpdateBigMenu(BarberData())
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShopId:close", function()
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

    TriggerEvent('skinchanger:loadSkin', skin or {})
    closeUI()
end)

RegisterNuiCallback("nui:newgrandcatalogue:barberShop:close", function()
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

    TriggerEvent('skinchanger:loadSkin', skin or {})
    closeUI()
end)

local barberShop = {}

RegisterNetEvent("vfw:barber:add", function(shopData)
    barberShop[shopData.id] = shopData
end)

RegisterNetEvent("vfw:barber:remove", function(shopId)
    if barberShop[shopId] then
        barberShop[shopId] = nil
    end
end)

Citizen.CreateThread(function()

    while not VFW.IsPlayerLoaded() do
        Wait(100)
    end

    while true do

        local wait = 1000

        if not open then

            local playerPed = PlayerPedId()

            local playerCoords = GetEntityCoords(playerPed)

            for shopId, shop in pairs(barberShop) do

                local shopPos = vector3(shop.position.x, shop.position.y, shop.position.z)

                local distToShop = #(playerCoords - shopPos)

                if distToShop < 30.0 then

                    wait = 0

                    local hasValidChairs = false

                    if shop.chairs and #shop.chairs > 0 then
                        for _, chairData in ipairs(shop.chairs) do
                            local chairPos = vector3(chairData.x, chairData.y, chairData.z)
                            local distToChairPos = #(playerCoords - chairPos)

                            if distToChairPos < 5.0 then

                                hasValidChairs = true

                                local markerZ = chairPos.z

                                DrawMarker(25, chairPos.x, chairPos.y, markerZ,
                                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                        0.8, 0.8, 0.8,
                                        0, 150, 255, 150, false, false, 2, false, nil, nil, false
                                )

                                if distToChairPos < 1.5 then
                                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour utiliser le barber shop.")
                                    if VFW.Interact.JustPressed(1, 38) then
                                        open = true
                                        lastChairData = chairData
                                        lastObject = nil
                                        -- Tentative optionnelle de trouver l'objet juste pour être sûr
                                        local chairEntity = GetClosestObjectOfType(chairPos.x, chairPos.y, chairPos.z, 1.0, chairData.model, false, false, false)
                                        if DoesEntityExist(chairEntity) then
                                            lastObject = chairEntity
                                        end

                                        ClearPedProp(playerPed, 0)
                                        ClearPedProp(playerPed, 1)
                                        SetPedComponentVariation(playerPed, 1, 0, 0, 2)
                                        LoadBarber()
                                    end
                                end
                            end
                        end
                    end

                    if not hasValidChairs then

                        DrawMarker(25, shopPos.x, shopPos.y, shopPos.z - 1.0,
                                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                1.5, 1.5, 0.5,
                                0, 150, 255, 150, false, true, 2, false, nil, nil, false
                        )
                        if distToShop < 2.5 then

                            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le barber shop")

                            if VFW.Interact.JustReleased(0, 38) then
                                open = true
                                exports.core:OpenClothingShop({
                                    Title = "BARBER SHOP",
                                    shopType = "barber",
                                    shopId = shopId
                                }, false)

                            end
                        end
                    end
                end
            end
        end
        Wait(wait)
    end
end)

