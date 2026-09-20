local ShopBlips = {}
local ActiveShops = {}
local ShopNPCs = {} -- ✨ NUEVO: Tabla para almacenar los NPCs

local markerColors = {
    clothing = {r = 0,   g = 191, b = 255},
    mask     = {r = 128, g = 0,   b = 128}, -- Morado para máscaras
    barber   = {r = 0,   g = 191, b = 255},
    tattoo   = {r = 0,   g = 191, b = 255},
    default  = {r = 0,   g = 191, b = 255}
}
local menuEstaAbierto = false

RegisterNetEvent('vfw_interaction:setMenuState', function(state)
    menuEstaAbierto = state
end)

-- ✨ NUEVO: Función para crear NPC
local function createShopNPC(shopId, shopData)
    -- Solo crear NPC para tiendas de máscaras
    if shopData.type ~= "mask" then
        return
    end

    -- Si ya existe un NPC, eliminarlo primero
    if ShopNPCs[shopId] then
        if DoesEntityExist(ShopNPCs[shopId]) then
            DeleteEntity(ShopNPCs[shopId])
        end
        ShopNPCs[shopId] = nil
    end

    local model = `s_m_m_autoshop_01`
    RequestModel(model)

    -- Timeout de 10 segundos para cargar el modelo
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(model) then
        console.error(("Failed to load NPC model for shop %d"):format(shopId))
        return
    end

    local npc = CreatePed(
            4,
            model,
            shopData.position.x,
            shopData.position.y,
            shopData.position.z - 1.0,
            shopData.position.heading or 0.0,
            false,
            true
    )

    if not DoesEntityExist(npc) then
        console.error(("Failed to create NPC for shop %d"):format(shopId))
        SetModelAsNoLongerNeeded(model)
        return
    end

    SetEntityHeading(npc, shopData.position.heading or 0.0)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedCanRagdoll(npc, false)
    SetPedCanRagdollFromPlayerImpact(npc, false)
    SetPedCanBeTargetted(npc, false)
    SetPedFleeAttributes(npc, 0, false)
    SetPedCombatAttributes(npc, 17, true)

    ShopNPCs[shopId] = npc
    SetModelAsNoLongerNeeded(model)

end

-- ✨ NUEVO: Función para eliminar NPC
local function deleteShopNPC(shopId)
    if ShopNPCs[shopId] then
        if DoesEntityExist(ShopNPCs[shopId]) then
            DeleteEntity(ShopNPCs[shopId])
        end
        ShopNPCs[shopId] = nil
    end
end

local SHOP_BLIP_CONFIG = {
    clothing = {blip = 73, color = 47},
    barber   = {blip = 71, color = 47},
    tattoo   = {blip = 75, color = 1},
    mask     = {blip = 362, color = 17}
}

local function createShopBlip(shopId, shopData)
    if not shopData or not shopData.position then
        return
    end

    if ShopBlips[shopId] then
        RemoveBlip(ShopBlips[shopId])
        ShopBlips[shopId] = nil
    end

    local blip = AddBlipForCoord(shopData.position.x, shopData.position.y, shopData.position.z)

    local typeConfig = SHOP_BLIP_CONFIG[shopData.type]
    SetBlipSprite(blip, typeConfig and typeConfig.blip or shopData.blip or 52)
    SetBlipColour(blip, typeConfig and typeConfig.color or shopData.blipColor or 0)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, true)
    SetBlipDisplay(blip, 4)
    local blipNames = {
        clothing = "Magasin de Vêtements",
        barber = "Barber Shop",
        tattoo = "Magasin de Tatouage",
        mask = "Magasin de Masque"
    }

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipNames[shopData.type] or "Magasin")
    EndTextCommandSetBlipName(blip)

    ShopBlips[shopId] = blip

    ActiveShops[shopId] = {
        position = vector3(shopData.position.x, shopData.position.y, shopData.position.z),
        type = shopData.type,
        heading = shopData.position.heading or 0.0
    }

    if shopData.type == "barber" then
        TriggerEvent("vfw:barber:add", shopData)
    end

    -- ✨ Crear NPC si es tienda de máscaras
    createShopNPC(shopId, shopData)
end

local function loadShops()
    local shops = TriggerServerCallback('shops:getAll')

    -- Limpiar blips existentes
    for shopId, blip in pairs(ShopBlips) do
        RemoveBlip(blip)
    end
    ShopBlips = {}

    -- ✨ Limpiar NPCs existentes
    for shopId, npc in pairs(ShopNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    ShopNPCs = {}

    ActiveShops = {}

    if shops and type(shops) == "table" and next(shops) then
        local count = 0
        for shopId, shopData in pairs(shops) do
            createShopBlip(shopId, shopData)
            count = count + 1
        end
    end
end

RegisterNetEvent('shops:create', function(shopId, shopData)
    createShopBlip(shopId, shopData)
end)

RegisterNetEvent('shops:delete', function(shopId)
    if ShopBlips[shopId] then
        RemoveBlip(ShopBlips[shopId])
        ShopBlips[shopId] = nil
    end

    -- ✨ Eliminar NPC si existe
    deleteShopNPC(shopId)

    if ActiveShops[shopId] then

        if ActiveShops[shopId].type == "barber" then
            TriggerEvent("vfw:barber:remove", shopId)
        end

        ActiveShops[shopId] = nil
    end
end)

RegisterNetEvent('shops:updatePosition', function(shopId, newPosition)
    if not shopId or not newPosition then
        return
    end

    if not ActiveShops[shopId] then
        console.warn(("Attempted to update non-existent shop %d"):format(shopId))
        return
    end

    local shopType = ActiveShops[shopId].type

    -- Actualizar la posición en ActiveShops
    ActiveShops[shopId].position = vector3(newPosition.x, newPosition.y, newPosition.z)
    ActiveShops[shopId].heading = newPosition.heading or 0.0

    -- Actualizar el blip
    if ShopBlips[shopId] then
        RemoveBlip(ShopBlips[shopId])

        local blip = AddBlipForCoord(newPosition.x, newPosition.y, newPosition.z)

        local shops = TriggerServerCallback('shops:getAll')
        local shopData = shops and shops[shopId]

        local typeConfig = SHOP_BLIP_CONFIG[shopType]
        if typeConfig then
            SetBlipSprite(blip, typeConfig.blip)
            SetBlipColour(blip, typeConfig.color)
        elseif shopData then
            SetBlipSprite(blip, shopData.blip or 52)
            SetBlipColour(blip, shopData.blipColor or 0)
        else
            SetBlipSprite(blip, 52)
            SetBlipColour(blip, 0)
        end

        SetBlipScale(blip, 0.5)
        SetBlipAsShortRange(blip, true)
        SetBlipDisplay(blip, 4)
        local blipNames = {
            clothing = "Magasin de Vêtements",
            barber = "Barber Shop",
            tattoo = "Magasin de Tatouage",
            mask = "Magasin de Masque"
        }

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipNames[shopType] or "Magasin")
        EndTextCommandSetBlipName(blip)

        ShopBlips[shopId] = blip
    end

    -- ✨ Si es tienda de máscaras, actualizar el NPC
    if shopType == "mask" then
        deleteShopNPC(shopId)


        local shopData = {
            type = shopType,
            position = {
                x = newPosition.x,
                y = newPosition.y,
                z = newPosition.z,
                heading = newPosition.heading or 0.0
            }
        }
        createShopNPC(shopId, shopData)
    end

    console.success(("Shop %d position updated to X:%.2f Y:%.2f Z:%.2f"):format(
            shopId, newPosition.x, newPosition.y, newPosition.z))
end)

RegisterNetEvent("vfw:playerLoaded", function()
    loadShops()
end)

RegisterNetEvent('shops:forceReload', function()
    loadShops()
end)


AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- ✨ Limpiar todos los NPCs al detener el recurso
        for shopId, npc in pairs(ShopNPCs) do
            if DoesEntityExist(npc) then
                DeleteEntity(npc)
            end
        end
        ShopNPCs = {}
    end
end)

exports('ReloadShops', function()
    loadShops()
end)

CreateThread(function()
    while true do
        local wait = 1000

        if not menuEstaAbierto then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for shopId, shop in pairs(ActiveShops) do
                if shop.type == "barber" then
                    goto next
                end
                local dist = #(playerCoords - shop.position)

                if dist < 15.0 then
                    wait = 0

                    -- ✨ Solo dibujar marker si NO es tienda de máscaras (porque tiene NPC)
                    if shop.type ~= "mask" then
                        local color = markerColors[shop.type] or markerColors.default
                        --
                        --DrawMarker(
                        --        1,
                        --        shop.position.x, shop.position.y, shop.position.z - 1.0,
                        --        0.0, 0.0, 0.0,
                        --        0.0, 0.0, 0.0,
                        --        1.5, 1.5, 0.5,
                        --        color.r, color.g, color.b, 150,
                        --        false, true, 2, false, nil, nil, false
                        --)
                    end

                    if dist < 2.5 then
                        local shopLabels = {
                            clothing = "le magasin de vêtements",
                            barber = "le barber shop",
                            tattoo = "le salon de tatouage",
                            mask = "le magasin de masques"
                        }

                        local label = shopLabels[shop.type] or "le magasin"

                        -- ✨ Texto diferente para tiendas con NPC
                        if shop.type == "mask" then
                            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour parler au vendeur de masques")
                        else
                            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir " .. label)
                        end

                        if VFW.Interact.JustReleased(0, 38) then
                            if shop.type == "mask" then
                                -- Para máscaras, verificar el skin del jugador
                                TriggerEvent('skinchanger:getSkin', function(skin)
                                    if skin.sex == 0 or skin.sex == 1 then
                                        exports.core:OpenClothingShop({
                                            Title = "MAGASIN DE MASQUE",
                                            shopType = "mask",
                                            shopId = shopId  -- ✨ PASAR EL ID
                                        }, false)
                                    else
                                        VFW.ShowNotification({
                                            type = "ROUGE",
                                            content = "Les peds ne peuvent pas utiliser le magasin de masque."
                                        })
                                    end
                                end)
                            else
                                exports.core:OpenClothingShop({
                                    Title = (shop.type:upper() .. " SHOP"),
                                    shopType = shop.type,
                                    shopId = shopId  -- ✨ PASAR EL ID
                                }, false)
                            end
                        end
                    end
                end
                ::next::
            end
        end

        Wait(wait)
    end
end)