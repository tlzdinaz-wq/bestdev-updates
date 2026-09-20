local KEY_INTERACT = 38 -- E
local PNJ_INTERACT_RADIUS = 1.6

local blackmarketLocations = {}
local spawnedNPCs = {}
local spawnLocks = {}
local isNearBlackmarket = false
local currentBlackmarket = nil

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

local function spawnBlackmarketNPC(marketId, market)
    if spawnLocks[marketId] then return end
    if spawnedNPCs[marketId] and DoesEntityExist(spawnedNPCs[marketId].ped) then return end
    spawnedNPCs[marketId] = nil

    spawnLocks[marketId] = true

    local model = joaat("s_m_y_dealer_01")
    RequestModel(model)
    local t = GetGameTimer()
    while not HasModelLoaded(model) and (GetGameTimer() - t) < 5000 do
        Wait(0)
    end
    if not HasModelLoaded(model) then
        spawnLocks[marketId] = nil
        return
    end

    local position = market.position
    local heading = position.h or 0.0

    RequestCollisionAtCoord(position.x, position.y, position.z)
    Wait(100)

    local npcEntity = cEntity.Manager:CreatePedLocal(model, vector3(position.x, position.y, position.z), heading)
    if not npcEntity or not npcEntity.id or not DoesEntityExist(npcEntity.id) then
        spawnLocks[marketId] = nil
        return
    end
    local npc = npcEntity.id

    NetworkRequestControlOfEntity(npc)
    SetEntityInvincible(npc, true)
    SetPedCanRagdoll(npc, false)
    SetPedCanRagdollFromPlayerImpact(npc, false)
    SetPedDiesWhenInjured(npc, false)
    DisablePedPainAudio(npc, true)
    SetEntityProofs(npc, true, true, true, true, true, true, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    ClearPedTasksImmediately(npc)
    TaskStandStill(npc, -1)
    SetPedCanBeTargetted(npc, false)
    SetEntityCollision(npc, true, true)
    FreezeEntityPosition(npc, true)

    spawnedNPCs[marketId] = {
        ped = npc,
        position = vector3(position.x, position.y, position.z),
        market = market
    }

    SetModelAsNoLongerNeeded(model)
    spawnLocks[marketId] = nil
end

local function deleteBlackmarketNPC(marketId)
    local npcData = spawnedNPCs[marketId]
    if npcData and DoesEntityExist(npcData.ped) then
        DeletePed(npcData.ped)
    end
    spawnedNPCs[marketId] = nil
end

local function spawnAllBlackmarketNPCs()
    for marketId, market in pairs(blackmarketLocations) do
        if market.active then
            spawnBlackmarketNPC(marketId, market)
        end
    end
end

local function deleteAllBlackmarketNPCs()
    for marketId, _ in pairs(spawnedNPCs) do
        deleteBlackmarketNPC(marketId)
    end
end

local function openBlackmarket(market)
    local blackmarketItems = TriggerServerCallback("core:blackmarket:getItems", market.id) or {}

    local itemsToBuy = {}
    local itemsToSell = {}

    for _, item in ipairs(blackmarketItems) do
        local itemInfo = VFW.Items[item.item_name]
        local maxQty = tonumber(item.max_quantity) or 100
        if maxQty < 1 then maxQty = 1 end

        if item.transaction_type == "buy" or item.transaction_type == "both" then
            table.insert(itemsToBuy, {
                name = item.item_name,
                label = itemInfo and itemInfo.label or item.item_name,
                price = item.price,
                category = item.category or "misc",
                quantity = item.stock_quantity,
                maxQuantity = maxQty
            })
        end

        if item.transaction_type == "sell" or item.transaction_type == "both" then
            local playerItemCount = 0
            for _, invItem in ipairs(VFW.PlayerData.inventory or {}) do
                if invItem.name == item.item_name then
                    playerItemCount = invItem.count or 0
                    break
                end
            end
            table.insert(itemsToSell, {
                name = item.item_name,
                label = itemInfo and itemInfo.label or item.item_name,
                price = item.price,
                category = item.category or "misc",
                quantity = playerItemCount,
                maxQuantity = maxQty
            })
        end
    end

    local shopData = {
        type = "blackmarket",
        name = "blackmarket_" .. market.id,
        label = "Black Market",
        navItems = {},
        itemsToBuy = itemsToBuy,
        itemsToSell = itemsToSell
    }

    SendNUIMessage({
        action = "nui:shops:open",
        data = shopData
    })

    VFW.Nui.Focus(true)
end

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearMarket = false
        local closestMarket = nil
        local closestDistance = math.huge

        for marketId, npcData in pairs(spawnedNPCs) do
            local distance = #(playerCoords - npcData.position)

            if distance <= PNJ_INTERACT_RADIUS and distance < closestDistance then
                nearMarket = true
                closestDistance = distance
                closestMarket = npcData.market
            end
        end

        if nearMarket and closestMarket then
            if not isNearBlackmarket then
                isNearBlackmarket = true
                currentBlackmarket = closestMarket
            end

            ShowHelp("~INPUT_CONTEXT~ Accéder au black market")

            if IsControlJustPressed(0, KEY_INTERACT) then
                openBlackmarket(closestMarket)
                Wait(500)
            end
        else
            if isNearBlackmarket then
                isNearBlackmarket = false
                currentBlackmarket = nil
            end
        end

        Wait(0)
    end
end)

function LoadBlackmarketLocations()
    blackmarketLocations = TriggerServerCallback("core:blackmarket:getLocations") or {}

    spawnAllBlackmarketNPCs()
end

function table_length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

RegisterNetEvent('core:blackmarket:locationAdded', function(marketId, market)
    blackmarketLocations[marketId] = market
    if market.active then
        spawnBlackmarketNPC(marketId, market)
    end
end)

RegisterNetEvent('core:blackmarket:locationUpdated', function(marketId, position)
    if blackmarketLocations[marketId] then
        deleteBlackmarketNPC(marketId)

        blackmarketLocations[marketId].position = position

        if blackmarketLocations[marketId].active then
            spawnBlackmarketNPC(marketId, blackmarketLocations[marketId])
        end
    end
end)

RegisterNetEvent('core:blackmarket:locationDeleted', function(marketId)
    deleteBlackmarketNPC(marketId)
    blackmarketLocations[marketId] = nil
end)

RegisterNetEvent('core:blackmarket:statusChanged', function(marketId, active)
    if blackmarketLocations[marketId] then
        blackmarketLocations[marketId].active = active

        if active then
            spawnBlackmarketNPC(marketId, blackmarketLocations[marketId])
        else
            deleteBlackmarketNPC(marketId)
        end
    end
end)

CreateThread(function()
    Wait(2000)
    LoadBlackmarketLocations()
end)

CreateThread(function()
    while true do
        Wait(30000)
        for marketId, market in pairs(blackmarketLocations) do
            if market.active then
                local existing = spawnedNPCs[marketId]
                if not existing or not DoesEntityExist(existing.ped) then
                    spawnBlackmarketNPC(marketId, market)
                end
            end
        end
    end
end)

RegisterNUICallback("shops:close", function(data, cb)
    VFW.Nui.Focus(false)
    cb("ok")
end)

RegisterNUICallback("shops:buy", function(data, cb)
    local items = data.items
    local shopType = data.shopType
    local shopName = data.shopName or ""

    -- Ignorer les shops qui ne sont pas des blackmarkets (gérés par d'autres modules)
    if shopType ~= "blackmarket" then
        return
    end

    -- Si c'est un blackmarket, utiliser notre système spécifique
    local marketId = tonumber(shopName:match("blackmarket_(%d+)"))
    if marketId then
        TriggerServerEvent("core:blackmarket:buyItems", marketId, items)
        cb({ success = true })
    else
        cb({ success = false, message = "Erreur: Market ID non trouvé" })
    end
end)

RegisterNUICallback("shops:sell:blackmarket", function(data, cb)
    local items = data.items
    local shopType = data.shopType

    if currentBlackmarket and currentBlackmarket.id then
        TriggerServerEvent("core:blackmarket:sellItems", currentBlackmarket.id, items)
    end

    cb({ success = true })
end)

local activeDelivery = nil
local deliveryBlip = nil
local deliveryVehicle = nil
local deliveryPed = nil
local deliveryBox = nil
local deliverySpawned = false
local pickingUp = false
local deliveryPhase = 0
local pedOriginalPos = nil
local completedDeliveryId = nil
local completedDeliveryPos = nil
local DELIVERY_SPAWN_RANGE = 280.0
local DELIVERY_INTERACT_RANGE = 2.5

local function RemoveDeliveryBlip()
    if deliveryBlip and DoesBlipExist(deliveryBlip) then
        RemoveBlip(deliveryBlip)
    end
    deliveryBlip = nil
end

local function CleanupDeliveryEntities()
    if deliveryBox and DoesEntityExist(deliveryBox) then
        DeleteEntity(deliveryBox)
    end
    deliveryBox = nil

    if deliveryPed and DoesEntityExist(deliveryPed) then
        DeletePed(deliveryPed)
    end
    deliveryPed = nil

    deliveryVehicle = nil
    deliverySpawned = false
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        deleteAllBlackmarketNPCs()
        RemoveDeliveryBlip()
        if deliveryVehicle and DoesEntityExist(deliveryVehicle) then
            NetworkRequestControlOfEntity(deliveryVehicle)
            DeleteEntity(deliveryVehicle)
        end
        CleanupDeliveryEntities()
    end
end)

local function SpawnDeliveryEntities()
    if deliverySpawned or not activeDelivery then return end
    deliverySpawned = true

    local pos = activeDelivery.position
    local heading = pos.h or 0.0

    if not activeDelivery.vehicleNetId then
        local netId = TriggerServerCallback("core:blackmarket:requestDeliveryVehicleSpawn", activeDelivery.id)
        if netId then
            activeDelivery.vehicleNetId = netId
        end
    end

    if activeDelivery.vehicleNetId then
        local timeout = GetGameTimer()
        while not NetworkDoesNetworkIdExist(activeDelivery.vehicleNetId) and (GetGameTimer() - timeout) < 5000 do
            Wait(100)
        end
        if NetworkDoesNetworkIdExist(activeDelivery.vehicleNetId) then
            deliveryVehicle = NetworkGetEntityFromNetworkId(activeDelivery.vehicleNetId)
            if deliveryVehicle and DoesEntityExist(deliveryVehicle) then
                NetworkRequestControlOfEntity(deliveryVehicle)
                local ctrl = GetGameTimer()
                while not NetworkHasControlOfEntity(deliveryVehicle) and (GetGameTimer() - ctrl) < 2000 do
                    Wait(100)
                end
                SetVehicleColours(deliveryVehicle, 0, 0)
                SetVehicleDoorsLocked(deliveryVehicle, 2)
                SetEntityInvincible(deliveryVehicle, true)
                SetVehicleDoorOpen(deliveryVehicle, 2, false, false)
                SetVehicleDoorOpen(deliveryVehicle, 3, false, false)
            end
        end
    end

    local pedModel = joaat("s_m_y_dealer_01")
    RequestModel(pedModel)
    local t = GetGameTimer()
    while not HasModelLoaded(pedModel) and (GetGameTimer() - t) < 3000 do Wait(10) end
    if not HasModelLoaded(pedModel) then
        deliverySpawned = false
        return
    end

    local pedX, pedY = pos.x, pos.y
    local pedHeading = heading + 180.0
    if deliveryVehicle and DoesEntityExist(deliveryVehicle) then
        local vehPos = GetEntityCoords(deliveryVehicle)
        local vehHeading = GetEntityHeading(deliveryVehicle)
        local rad = math.rad(vehHeading)
        pedX = vehPos.x + math.sin(rad) * 3.5
        pedY = vehPos.y - math.cos(rad) * 3.5
        pedHeading = vehHeading + 180.0
    end

    RequestCollisionAtCoord(pedX, pedY, pos.z)
    Wait(100)

    local pedEntity = cEntity.Manager:CreatePedLocal(pedModel, vector3(pedX, pedY, pos.z), pedHeading)
    if not pedEntity or not pedEntity.id then
        deliverySpawned = false
        return
    end
    deliveryPed = pedEntity.id

    SetEntityInvincible(deliveryPed, true)
    SetPedCanRagdoll(deliveryPed, false)
    SetPedCanRagdollFromPlayerImpact(deliveryPed, false)
    SetBlockingOfNonTemporaryEvents(deliveryPed, true)
    SetPedCanBeTargetted(deliveryPed, false)
    SetEntityCollision(deliveryPed, true, true)
    FreezeEntityPosition(deliveryPed, true)
    SetModelAsNoLongerNeeded(pedModel)

    pedOriginalPos = vector3(pedX, pedY, pos.z)
    deliveryPhase = 0
end

local function GoFetchBox()
    if not deliveryPed or not DoesEntityExist(deliveryPed) then return end
    pickingUp = true

    local canCarry = TriggerServerCallback("core:blackmarket:canPickupDelivery", activeDelivery.id)
    if not canCarry then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Yo man tes poches sont pleines, tu peux pas porter la marchandise"
        })
        pickingUp = false
        return
    end

    local pedHead = GetEntityHeading(deliveryPed)
    local behindRad = math.rad(pedHead + 180.0)
    local pedCoords = GetEntityCoords(deliveryPed)
    local targetX = pedCoords.x - math.sin(behindRad) * 0.5
    local targetY = pedCoords.y + math.cos(behindRad) * 0.5

    FreezeEntityPosition(deliveryPed, false)
    TaskGoStraightToCoord(deliveryPed, targetX, targetY, pedCoords.z, 1.0, 2000, pedHead + 180.0, 0.1)
    Wait(1500)

    local boxModel = GetHashKey("prop_cs_cardbox_01")
    RequestModel(boxModel)
    local t = GetGameTimer()
    while not HasModelLoaded(boxModel) and (GetGameTimer() - t) < 3000 do Wait(10) end
    if HasModelLoaded(boxModel) then
        deliveryBox = CreateObject(boxModel, 0.0, 0.0, 0.0, false, false, false)
        AttachEntityToEntity(deliveryBox, deliveryPed, GetPedBoneIndex(deliveryPed, 28422),
            -0.05, 0.0, -0.10, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(boxModel)
    end

    RequestAnimDict("anim@heists@box_carry@")
    t = GetGameTimer()
    while not HasAnimDictLoaded("anim@heists@box_carry@") and (GetGameTimer() - t) < 3000 do Wait(10) end
    if HasAnimDictLoaded("anim@heists@box_carry@") then
        TaskPlayAnim(deliveryPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    TaskGoStraightToCoord(deliveryPed, pedOriginalPos.x, pedOriginalPos.y, pedOriginalPos.z, 1.0, 2000, pedHead, 0.1)
    Wait(1500)

    ClearPedTasks(deliveryPed)
    SetEntityCoords(deliveryPed, pedOriginalPos.x, pedOriginalPos.y, pedOriginalPos.z, false, false, false, false)
    SetEntityHeading(deliveryPed, pedHead)
    FreezeEntityPosition(deliveryPed, true)

    RequestAnimDict("anim@heists@box_carry@")
    t = GetGameTimer()
    while not HasAnimDictLoaded("anim@heists@box_carry@") and (GetGameTimer() - t) < 3000 do Wait(10) end
    if HasAnimDictLoaded("anim@heists@box_carry@") then
        TaskPlayAnim(deliveryPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    deliveryPhase = 1
    pickingUp = false
end

local function GiveBoxToPlayer()
    if not deliveryPed or not DoesEntityExist(deliveryPed) then return end
    pickingUp = true

    local result = TriggerServerCallback("core:blackmarket:pickupDelivery", activeDelivery.id)

    if result and result.success then
        if deliveryBox and DoesEntityExist(deliveryBox) then
            DetachEntity(deliveryBox, true, true)
            DeleteEntity(deliveryBox)
            deliveryBox = nil
        end

        ClearPedTasks(deliveryPed)

        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Yo merci man pour ta commande, mais décale d'ici fast au cas où les keufs nous ont pistés"
        })

        RemoveDeliveryBlip()
        completedDeliveryId = activeDelivery.id
        completedDeliveryPos = pedOriginalPos
        deliveryPhase = 2
        activeDelivery = nil
    else
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = result and result.message or "Impossible de récupérer la livraison"
        })
    end

    pickingUp = false
end

RegisterNetEvent('core:blackmarket:deliveryCreated', function(data)
    RemoveDeliveryBlip()
    CleanupDeliveryEntities()
    deliveryPhase = 0
    pedOriginalPos = nil
    completedDeliveryId = nil
    completedDeliveryPos = nil
    pickingUp = false

    activeDelivery = {
        id = data.deliveryId,
        position = data.position,
        items = data.items,
        vehicleNetId = data.vehicleNetId
    }

    RemoveDeliveryBlip()
    deliveryBlip = AddBlipForCoord(data.position.x, data.position.y, data.position.z)
    SetBlipSprite(deliveryBlip, 478)
    SetBlipColour(deliveryBlip, 1)
    SetBlipScale(deliveryBlip, 0.5)
    SetBlipAsShortRange(deliveryBlip, false)
    SetBlipRoute(deliveryBlip, true)
    SetBlipRouteColour(deliveryBlip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Livraison Black Market")
    EndTextCommandSetBlipName(deliveryBlip)

    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = "Commande validée ! Un point de livraison a été marqué sur ta carte"
    })
end)

RegisterNetEvent('core:blackmarket:deliveryExpired', function(deliveryId)
    if activeDelivery and activeDelivery.id == deliveryId then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Ta livraison a expiré, l'argent est perdu"
        })
        RemoveDeliveryBlip()
        CleanupDeliveryEntities()
        activeDelivery = nil
    end
end)

CreateThread(function()
    while true do
        Wait(2000)

        if activeDelivery and not deliverySpawned then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local deliveryPos = vector3(activeDelivery.position.x, activeDelivery.position.y, activeDelivery.position.z)
            local dist = #(playerCoords - deliveryPos)

            if dist < DELIVERY_SPAWN_RANGE then
                SpawnDeliveryEntities()
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        if deliveryVehicle and DoesEntityExist(deliveryVehicle) then
            SetVehicleColours(deliveryVehicle, 0, 0)
            SetVehicleDoorsLocked(deliveryVehicle, 2)
            SetEntityInvincible(deliveryVehicle, true)
            FreezeEntityPosition(deliveryVehicle, true)
            SetVehicleDoorOpen(deliveryVehicle, 2, false, false)
            SetVehicleDoorOpen(deliveryVehicle, 3, false, false)
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000

        local showInteract = (activeDelivery and deliveryPhase == 0) or (deliveryPhase == 1)

        if showInteract and deliverySpawned and deliveryPed and DoesEntityExist(deliveryPed) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local pedCoords = GetEntityCoords(deliveryPed)
            local dist = #(playerCoords - pedCoords)

            if dist < 25.0 then
                sleep = 0

                if dist < DELIVERY_INTERACT_RANGE and not pickingUp then
                    if deliveryPhase == 0 then
                        VFW.ShowHelpNotification("~INPUT_CONTEXT~ Récupérer la livraison")
                        if VFW.Interact.JustPressed(0, 38) then
                            GoFetchBox()
                        end
                    elseif deliveryPhase == 1 then
                        VFW.ShowHelpNotification("~INPUT_CONTEXT~ Prendre le colis")
                        if VFW.Interact.JustPressed(0, 38) then
                            GiveBoxToPlayer()
                        end
                    end
                end
            elseif dist < 100.0 then
                sleep = 200
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if deliveryPhase == 2 and deliverySpawned and completedDeliveryPos then
            local anyoneNear = false
            for _, playerId in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(playerId)
                if DoesEntityExist(ped) then
                    local pCoords = GetEntityCoords(ped)
                    if #(pCoords - completedDeliveryPos) < 200.0 then
                        anyoneNear = true
                        break
                    end
                end
            end
            if not anyoneNear then
                CleanupDeliveryEntities()
                if completedDeliveryId then
                    TriggerServerEvent('core:blackmarket:cleanupDeliveryVehicle', completedDeliveryId)
                end
                deliveryPhase = 0
                pedOriginalPos = nil
                completedDeliveryId = nil
                completedDeliveryPos = nil
            end
        end
    end
end)

