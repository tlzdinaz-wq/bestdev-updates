VFW = exports["core"]:getSharedObject()

local RES = GetCurrentResourceName() -- cache resource name for reuse

local pedSpawned = false
local pedEntity = nil
local showMenu = false
local lastSocietyMoney = 0
local isChestOpen = false -- Flag: true si le joueur a ouvert un coffre/inventaire

-- Global toggle (controlled from server/builder): when false, disable all Market PNJ + interactions
local spacemarketEnabled = true

-- Blips Market
local spacemarketBlips = {}
local function removeMarketBlips()
    if spacemarketBlips then
        for _, blipId in ipairs(spacemarketBlips) do
            if Blips and Blips.remove then
                Blips.remove(blipId)
            elseif blipId and DoesBlipExist(blipId) then
                RemoveBlip(blipId)
            end
        end
        spacemarketBlips = {}
    end
end

local function createMarketBlips()
    removeMarketBlips()
    if not spacemarketEnabled or not Config or not Config.Locations then return end
    for i, location in ipairs(Config.Locations) do
        if location.pedCoords then
            local blipData = {
                position = { x = location.pedCoords.x, y = location.pedCoords.y, z = location.pedCoords.z },
                label = "Market - Fourniture Job",
                sprite = 59, -- icône magasin
                color = 1,   -- violet
                scale = 0.5
            }
            local blipId = nil
            if Blips and Blips.create then
                blipId = Blips.create(blipData)
                if blipId then
                    Blips.list[blipId] = blipData
                end
            else
                blipId = AddBlipForCoord(blipData.position.x, blipData.position.y, blipData.position.z)
                SetBlipSprite(blipId, blipData.sprite)
                SetBlipColour(blipId, blipData.color)
                SetBlipScale(blipId, blipData.scale)
                SetBlipAsShortRange(blipId, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(blipData.label)
                EndTextCommandSetBlipName(blipId)
            end
            if blipId then table.insert(spacemarketBlips, blipId) end
        end
    end
end

-- Variables pour stocker les données d'argent du serveur
local _spacemarket_playerCash = 0
local _spacemarket_playerSociety = 0
local _spacemarket_gotMoneyData = false

-- Tracking des 3 PEDs pour chaque location
local pedsData = {}
for i, location in ipairs(Config.Locations) do
    pedsData[i] = {
        location = location,
        entity = nil,
        spawned = false
    }
end

local currentActivePedIndex = nil

-- help notification utility (same behaviour as firework shop)
local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

-- legacy alias for backwards compatibility
function ShowHelpText(text)
    ShowHelp(text)
end

-- Écouter la réponse du serveur avec l'argent de la société
RegisterNetEvent(RES .. ":societyMoneyResponse")
AddEventHandler(RES .. ":societyMoneyResponse", function(money)
    lastSocietyMoney = money or 0
end)

-- Écouter les données d'argent du joueur depuis le serveur
RegisterNetEvent(RES .. ":moneyDataResponse")
AddEventHandler(RES .. ":moneyDataResponse", function(playerCash, societyMoney)
    _spacemarket_playerCash = playerCash or 0
    _spacemarket_playerSociety = societyMoney or 0
    _spacemarket_gotMoneyData = true
end)

-- Créer le PED (modèle calculé une fois, mais peut être mis à jour dynamiquement)
local pedModelHash = GetHashKey(Config.PedModel)

-- preload model at startup to avoid waiting inside the main loop
Citizen.CreateThread(function()
    if not HasModelLoaded(pedModelHash) then
        RequestModel(pedModelHash)
        while not HasModelLoaded(pedModelHash) do
            Citizen.Wait(0)
        end
    end
end)

-- Sync global enabled flag at startup
Citizen.CreateThread(function()
    -- Ask server for current global enabled state + locations/ped model
    TriggerServerEvent('spacemarket:requestGlobalEnabled')
    TriggerServerEvent('spacemarket:requestLocations')
end)

RegisterNetEvent('spacemarket:setGlobalEnabled', function(enabled)
    spacemarketEnabled = enabled and true or false

    if not spacemarketEnabled then
        if showMenu then CloseShopMenu() end
        if isInInteraction then ClosePedInteraction() end
        -- Despawn all PNJ immédiatement
        for _, pedData in ipairs(pedsData) do
            if pedData.spawned and pedData.entity and DoesEntityExist(pedData.entity) then
                DeleteEntity(pedData.entity)
            end
            pedData.spawned = false
            pedData.entity = nil
        end
        removeMarketBlips()
    else
        createMarketBlips()
    end
end)

-- Sync Market locations + ped model (called at join and when builder modifies config)
RegisterNetEvent('spacemarket:syncLocations', function(locations, pedModel)
    if type(locations) == "table" and #locations > 0 then
        -- Update local Config.Locations
        Config.Locations = locations

        -- Reset all existing PNJ
        for _, pedData in ipairs(pedsData) do
            if pedData.spawned and pedData.entity and DoesEntityExist(pedData.entity) then
                DeleteEntity(pedData.entity)
            end
        end

        -- Rebuild pedsData table with new locations
        pedsData = {}
        for i, location in ipairs(Config.Locations) do
            pedsData[i] = {
                location = location,
                entity = nil,
                spawned = false
            }
        end
        currentActivePedIndex = nil
        -- (Re)créer les blips si activé
        if spacemarketEnabled then
            createMarketBlips()
        else
            removeMarketBlips()
        end
    end

    if type(pedModel) == "string" and pedModel ~= "" then
        Config.PedModel = pedModel
        pedModelHash = GetHashKey(Config.PedModel)
    end
end)

-- Thread pour gérer l'apparition/disparition des 3 PEDs
Citizen.CreateThread(function()
    while true do
        if spacemarketEnabled then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, pedData in ipairs(pedsData) do
                local distance = #(playerCoords - vector3(pedData.location.pedCoords.x, pedData.location.pedCoords.y, pedData.location.pedCoords.z))
                
                if distance < 50.0 and not pedData.spawned then
                    -- Spawn du PED
                    pedData.entity = CreatePed(4, pedModelHash, pedData.location.pedCoords.x, pedData.location.pedCoords.y, pedData.location.pedCoords.z - 1.0, pedData.location.pedCoords.w, false, true)
                    
                    SetEntityAsMissionEntity(pedData.entity, true, true)
                    SetPedFleeAttributes(pedData.entity, 0, 0)
                    SetPedCombatAttributes(pedData.entity, 17, 1)
                    SetBlockingOfNonTemporaryEvents(pedData.entity, true)
                    FreezeEntityPosition(pedData.entity, true)
                    SetEntityInvincible(pedData.entity, true)
                    
                    if Config.PedScenario then
                        TaskStartScenarioInPlace(pedData.entity, Config.PedScenario, 0, true)
                    end
                    
                    pedData.spawned = true
                elseif distance >= 50.0 and pedData.spawned then
                    if DoesEntityExist(pedData.entity) then
                        DeleteEntity(pedData.entity)
                    end
                    pedData.spawned = false
                    pedData.entity = nil
                end
            end
        end
        
        Wait(2000)
    end
end)

-- Authorization cache system
local authCache = {
    lastCheck = 0,
    result = nil,
    error = nil,
    isInRange = false,
    isPending = false
}

-- Register global event handler for authorization results (once only)
RegisterNetEvent(RES .. ":authorizationResult")
AddEventHandler(RES .. ":authorizationResult", function(authorized, errorMsg)
    authCache.result = authorized
    authCache.error = errorMsg
    authCache.lastCheck = GetGameTimer()
    authCache.isPending = false
end)

-- Vérifier l'autorisation avec cache basé sur la distance
local function checkAuthorization(callback)
    -- If already pending, don't send another request
    if authCache.isPending then
        return
    end
    
    authCache.isPending = true
    authCache.result = nil
    authCache.error = nil
    
    TriggerServerEvent(RES .. ":checkAuthorization")
    
    -- Wait for response with timeout (max 3 seconds)
    local waitStart = GetGameTimer()
    local timeout = 3000
    
    while authCache.isPending and (GetGameTimer() - waitStart) < timeout do
        Wait(20)
    end
    
    if authCache.isPending then
        authCache.isPending = false
        authCache.result = false
        authCache.error = "Timeout"
    end
    
    callback(authCache.result, authCache.error)
end

Citizen.CreateThread(function()
    local isAuthorized = false
    local lastCheckResult = nil
    
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local closestPedIndex = nil
        local closestDistance = math.huge
        
        -- Désactiver toute interaction si le Market global est désactivé
        if spacemarketEnabled then
            -- Trouver le PED le plus proche
            for i, pedData in ipairs(pedsData) do
                if pedData.spawned and pedData.entity then
                    local pedCoords = GetEntityCoords(pedData.entity)
                    local distance = #(playerCoords - pedCoords)
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPedIndex = i
                    end
                end
            end
        else
            closestPedIndex = nil
            closestDistance = math.huge
        end
        
        -- Gestion de l'interaction avec le PED le plus proche
        if spacemarketEnabled and closestPedIndex and closestDistance < Config.InteractionDistance then
            currentActivePedIndex = closestPedIndex
            
            -- Vérification du job une seule fois quand le DrawText3D s'affiche
            if not authCache.isInRange then
                authCache.isInRange = true
                checkAuthorization(function(authorized, errorMsg)
                    isAuthorized = authorized
                    lastCheckResult = { authorized = authorized, errorMsg = errorMsg }
                end)
            end
            
            -- Always show interaction text (help notification)
            sleep = 0
            if not isInInteraction and not showMenu then
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour discuter avec le vendeur")
            end
            if VFW.Interact.JustReleased(0, 38) then
                StartPedInteraction()
            end
        elseif closestDistance >= Config.InteractionDistance + 1.0 then
            -- Réinitialiser le cache de distance
            if authCache.isInRange then
                authCache.isInRange = false
                isAuthorized = false
                if showMenu then
                    CloseShopMenu()
                end
            end
            currentActivePedIndex = nil
        end
        
        Wait(sleep)
    end
end)

local interactionCamera = nil
local isInInteraction = false

-- Fonction pour démarrer l'interaction avec le ped
function StartPedInteraction()
    if isInInteraction or showMenu or not currentActivePedIndex then return end
    
    checkAuthorization(function(authorized, errorMsg)
        isInInteraction = true
        local activePed = pedsData[currentActivePedIndex].entity
        local pedCoords = GetEntityCoords(activePed)
        
        -- Faire regarder le ped vers le joueur
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        TaskLookAtEntity(activePed, playerPed, -1, 0, 0)
        
        -- Désactiver les contrôles du joueur (garder le curseur visible mais permettre de voir le jeu)
        VFW.Nui.Focus(true)
        DisableControlAction(0, 1, true)  -- LookLeftRight
        DisableControlAction(0, 2, true)  -- LookUpDown
        DisableControlAction(0, 24, true) -- Attack
        DisablePlayerFiring(PlayerPedId(), true)
        DisableControlAction(0, 142, true) -- MeleeAttackAlternate
        DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
        
        -- Ouvrir le modal d'interaction avec le statut d'autorisation, message d'erreur et infos du shop
        SendNUIMessage({
            action = "openPedInteraction",
            authorized = authorized,
            errorMsg = errorMsg,
            shopName = "THIERRY - MARKET",
            shopLogo = VFW.CDN.Get("others/spacemarket_pnj.png"),
        })
    end)
end

-- Open the shop menu and request server-driven data
function OpenShopMenu()
    if showMenu then return end

    -- Fermer l'interaction d'abord
    ClosePedInteraction()

    showMenu = true
    VFW.Nui.Focus(true)

    -- Demander les données d'argent au serveur via callback
    TriggerServerEvent(RES .. ":getPlayerMoneyData")
    
    -- Attendre la réponse (max 2 secondes)
    local waitStart = GetGameTimer()
    while not _spacemarket_gotMoneyData and (GetGameTimer() - waitStart) < 2000 do
        Wait(20)
    end

    -- store money snapshot to include when server responds
    _spacemarket_playerMoney = _spacemarket_playerCash or 0
    _spacemarket_playerBank = _spacemarket_playerSociety or 0

    -- Request shop data from server (server will trigger back the sendShopData event)
    TriggerServerEvent(RES .. ":requestShopData")
end

-- Fonction pour fermer l'interaction
function ClosePedInteraction()
    if not isInInteraction then return end
    
    isInInteraction = false
    
    -- Réinitialiser le ped
    if currentActivePedIndex and pedsData[currentActivePedIndex] then
        local activePed = pedsData[currentActivePedIndex].entity
        if activePed and DoesEntityExist(activePed) then
            ClearPedTasks(activePed)
            if Config.PedScenario then
                TaskStartScenarioInPlace(activePed, Config.PedScenario, 0, true)
            end
        end
    end
    
    VFW.Nui.Focus(false)

    SendNUIMessage({
        action = "closePedInteraction"
    })
end

-- Duplicate OpenShopMenu removed: shop opening now requests server-driven data (see above)

-- Fonction pour fermer le menu
function CloseShopMenu()
    showMenu = false
    VFW.Nui.Focus(false)
    _spacemarket_playerMoney = nil
    _spacemarket_playerBank = nil
    SendNUIMessage({
        action = "closeShop"
    })
end

-- Callback NUI pour fermer l'interaction du ped
RegisterNUICallback('closePedInteraction', function(data, cb)
    ClosePedInteraction()
    cb('ok')
end)

-- Callback NUI pour fermer le menu
RegisterNUICallback('closeShop', function(data, cb)
    showMenu = false
    VFW.Nui.Focus(false)
    cb('ok')
end)

-- Callback NUI pour gérer le choix dans l'interaction
RegisterNUICallback('pedInteractionChoice', function(data, cb)
    local choice = data.choice
    
    if choice == "order" then
        -- Ouvrir le shop
        OpenShopMenu()
        cb('ok')
    elseif choice == "cancel" then
        -- Faire dire au ped "Ok pas de soucis à bientot"
        SendNUIMessage({
            action = "pedResponse",
            text = "Ok pas de soucis à bientôt"
        })
        
        -- Masquer les boutons de choix
        SendNUIMessage({
            action = "hidePedChoices"
        })
        
        -- Attendre un peu avant de fermer pour que le joueur voie la réponse
        Citizen.SetTimeout(2500, function()
            ClosePedInteraction()
        end)
        
        cb('ok')
    else
        cb('ok')
    end
end)

-- Setup fallback listener table for net-event responses
local pendingMarketRequests = {}
local responseEvent = RES .. ":buyItems:response"
RegisterNetEvent(responseEvent)
AddEventHandler(responseEvent, function(requestId, ok, err, deliveryTime)
    if pendingMarketRequests[requestId] then
        pendingMarketRequests[requestId](ok, err, deliveryTime)
        pendingMarketRequests[requestId] = nil
    end
end)

-- Callback NUI pour acheter
RegisterNUICallback('buyItems', function(data, cb)
    local cart = data.cart
    local total = data.total or 0
    local paymentType = data.paymentType or 'cash'

    if not cart or #cart == 0 then
        cb({ success = false, error = "Panier vide" })
        return
    end

    -- Use direct net event (avoid TriggerServerCallback to prevent framework callback handler errors)
    -- Fallback via net event
    local netEvent = RES .. ":buyItems:net"
    local reqId = tostring(GetGameTimer()) .. ":" .. tostring(math.random(1000, 9999))
    local finished, rOk, rErr, rDeliveryTime = false, false, nil, nil

    pendingMarketRequests[reqId] = function(okResp, errResp, deliveryTime)
        finished = true
        rOk = okResp
        rErr = errResp
        rDeliveryTime = deliveryTime
    end

    TriggerServerEvent(netEvent, cart, total, reqId, paymentType, currentActivePedIndex)

    local start = GetGameTimer()
    local timeout = 5000
    while not finished and (GetGameTimer() - start) < timeout do
        Wait(20)
    end

    if finished then
        if rOk then
            cb({ success = true, deliveryTime = rDeliveryTime })
        else
            cb({ success = false, error = rErr or "Erreur lors de l'achat (fallback)" })
        end
    else
        pendingMarketRequests[reqId] = nil
        cb({ success = false, error = "Timeout du serveur" })
    end
end)

-- Listener for server-driven shop data
RegisterNetEvent(RES .. ":sendShopData")
AddEventHandler(RES .. ":sendShopData", function(shopData, errorMsg)
    if not showMenu then return end
    local pm = _spacemarket_playerMoney or 0
    local pb = _spacemarket_playerBank or 0
    _spacemarket_playerMoney = nil
    _spacemarket_playerBank = nil

    -- If server indicates no shop (nil) or shop has no items/categories -> deny access
    local hasData = false
    if shopData and ( (shopData.items and next(shopData.items)) or (shopData.categories and next(shopData.categories)) ) then
        hasData = true
    end

    if not shopData or not hasData then
        CloseShopMenu()
        if errorMsg then
            VFW.ShowNotification({ type = "ROUGE", content = errorMsg })
        end
        return
    end

    SendNUIMessage({
        action = "openShop",
        shopData = shopData,
        playerMoney = pm,
        playerBank = pb
    })
end)

-- Spawn / Remove temp prop handlers
local spawnedTempProps = {}

RegisterNetEvent('spacemarket:client:spawnProp', function(propId, model, coords)
    if not propId or not model or not coords then return end

    local hash = type(model) == 'number' and model or GetHashKey(model)

    RequestModel(hash)
    local tick = 0
    while not HasModelLoaded(hash) and tick < 200 do
        Wait(0)
        tick = tick + 1
    end

    local obj = CreateObject(hash, coords.x, coords.y, coords.z, false, true, true)
    SetEntityHeading(obj, coords.w or 0)
    PlaceObjectOnGroundProperly(obj)
    SetEntityAsMissionEntity(obj, true, true)

    -- Wait for a valid network id (prevent NETWORK_GET_NETWORK_ID_FROM_ENTITY warnings)
    local netId = nil
    if NetworkGetEntityIsNetworked(obj) then
        netId = NetworkGetNetworkIdFromEntity(obj)
        local waitTick = 0
        while (not netId or netId == 0) and waitTick < 200 do
            Wait(0)
            netId = NetworkGetNetworkIdFromEntity(obj)
            waitTick = waitTick + 1
        end

        if netId and netId ~= 0 then
            -- ensure the network id exists on all machines (best-effort)
            pcall(function() SetNetworkIdExistsOnAllMachines(netId, true) end)
        else
            -- fallback to ObjToNet (may still be 0 if networking failed)
            netId = ObjToNet(obj)
        end
    end

    spawnedTempProps[propId] = {entity = obj, netId = netId}

    -- visual prop only — no server registration required
end)

RegisterNetEvent('spacemarket:client:removeProp', function(propId, netId)
    if not propId then return end
    local data = spawnedTempProps[propId]
    if data then
        local ent = data.entity
        if ent and DoesEntityExist(ent) then
            DeleteObject(ent)
        end
        spawnedTempProps[propId] = nil
        return
    end

    if netId then
        local ent = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(ent) then
            DeleteObject(ent)
        end
    end
end)





-- Callback pour obtenir l'argent du joueur et la société
RegisterNUICallback('getPlayerMoney', function(data, cb)
    -- Demander les données d'argent au serveur
    _spacemarket_playerCash = 0
    _spacemarket_playerSociety = 0
    _spacemarket_gotMoneyData = false
    
    TriggerServerEvent(RES .. ":getPlayerMoneyData")
    
    -- Attendre la réponse (max 500ms)
    local waitStart = GetGameTimer()
    while not _spacemarket_gotMoneyData and (GetGameTimer() - waitStart) < 500 do
        Wait(20)
    end
    
    cb({ money = _spacemarket_playerCash or 0, society = _spacemarket_playerSociety or 0 })
end)

-- Fonction pour dessiner du texte 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoord()
    local distance = #(camCoords - vector3(x, y, z))
    
    local scaleFactor = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scaleFactor * fov
    
    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end



-- Gérer la fermeture avec ESC
Citizen.CreateThread(function()
    local sleep = 200
    while true do
        if showMenu or isInInteraction then
            sleep = 0
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisablePlayerFiring(PlayerPedId(), true)

            if IsControlJustReleased(0, 322) then
                if showMenu then
                    CloseShopMenu()
                else
                    ClosePedInteraction()
                end
            end
        else
            sleep = 200
        end
        Wait(sleep)
    end
end)

RegisterCommand('closeshop', function()
    showMenu = false
    VFW.Nui.Focus(false)
    SendNUIMessage({
        action = "closeShop"
    })
end, false)
TriggerEvent('chat:removeSuggestion', '/closeshop')

-- Blip pour la livraison
local deliveryBlip = nil
local currentOrderItems = {}
local orderDropped = false

-- ==================== SYSTÈME DE COFFRE AVEC PROP ====================
local spawnedProps = {} -- Table pour tracker les props spawnés
local targetProp = nil -- Le prop actuellement ciblé
local targetChestId = nil -- L'ID du coffre associé au prop
local PROP_SPAWN_DISTANCE = 50.0 -- Distance à partir de laquelle on (re)spawn le prop localement

local function spawnPropEntityForChest(propData)
    if not propData or not propData.coords then return end
    if propData.entity and DoesEntityExist(propData.entity) then return end

    local model = propData.propModel or "prop_boxpile_06b"
    local modelHash = GetHashKey(model)

    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 50 do
        Wait(0)
        attempts = attempts + 1
    end
    if not HasModelLoaded(modelHash) then return end

    local propEntity = CreateObject(modelHash, propData.coords.x, propData.coords.y, propData.coords.z, false, false, false)
    if not DoesEntityExist(propEntity) then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    SetEntityHeading(propEntity, propData.heading or 0.0)
    SetEntityAsMissionEntity(propEntity, true, true)
    PlaceObjectOnGroundProperly(propEntity)
    FreezeEntityPosition(propEntity, true)
    SetModelAsNoLongerNeeded(modelHash)

    propData.entity = propEntity
end

-- Écouter l'événement de confirmation de commande (depuis le serveur)
RegisterNetEvent(RES .. ":orderDelivered")
AddEventHandler(RES .. ":orderDelivered", function(items)
    currentOrderItems = items or {}
    orderDropped = true
end)

-- Nettoyer quand tous les items sont pris
-- ==================== SYSTÈME DE COFFRE AVEC PROP ====================

-- Événement depuis le serveur : le chest est vide, supprimer le prop
RegisterNetEvent(RES .. ":chestEmpty")
AddEventHandler(RES .. ":chestEmpty", function(chestId)
    if spawnedProps[chestId] then
        if spawnedProps[chestId].entity and DoesEntityExist(spawnedProps[chestId].entity) then
            DeleteEntity(spawnedProps[chestId].entity)
        end
        spawnedProps[chestId] = nil
    end
    
    -- Si plus aucun prop, supprimer aussi le blip
    if not next(spawnedProps) then
        if deliveryBlip then
            RemoveBlip(deliveryBlip)
            deliveryBlip = nil
        end
        orderDropped = false
    end
end)

-- Événement pour spawner le prop et créer l'interaction
RegisterNetEvent(RES .. ":spawnChestProp")
AddEventHandler(RES .. ":spawnChestProp", function(chestId, coords, propModel, requiredJob)
    local propCoords = vector3(coords.x, coords.y, coords.z)
    local propHeading = coords.w or 0.0

    -- Stocker les informations du prop (avec le job requis)
    spawnedProps[chestId] = {
        entity = nil,
        coords = propCoords,
        heading = propHeading,
        chestId = chestId,
        requiredJob = requiredJob,
        propModel = propModel or "prop_boxpile_06b"
    }

    -- Spawn immédiat si le joueur est déjà à portée; sinon le thread de gestion s'en chargera
    local playerCoords = GetEntityCoords(PlayerPedId())
    if #(playerCoords - propCoords) < PROP_SPAWN_DISTANCE then
        spawnPropEntityForChest(spawnedProps[chestId])
    end

    -- Créer le blip
    if not deliveryBlip then
        deliveryBlip = AddBlipForCoord(propCoords.x, propCoords.y, propCoords.z)
        SetBlipRoute(deliveryBlip, true)
        SetBlipColour(deliveryBlip, 5) -- Jaune
        SetBlipScale(deliveryBlip, 0.5)
        SetBlipAsShortRange(deliveryBlip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Livraison Market")
        EndTextCommandSetBlipName(deliveryBlip)
    end
    
    orderDropped = true
end)

-- Listeners pour détecter la fermeture d'inventaire (réponse aux inventaires / huds courants)
local function onInventoryClose()
    isChestOpen = false
end

RegisterNetEvent('inventory:close')
AddEventHandler('inventory:close', onInventoryClose)
RegisterNetEvent('esx_inventoryhud:closeInventory')
AddEventHandler('esx_inventoryhud:closeInventory', onInventoryClose)
RegisterNetEvent('ox_inventory:close')
AddEventHandler('ox_inventory:close', onInventoryClose)
RegisterNetEvent('vfw:closeInventory')
AddEventHandler('vfw:closeInventory', onInventoryClose)
RegisterNetEvent('vfw:closeTestChest')
AddEventHandler('vfw:closeTestChest', onInventoryClose)

-- Thread pour gérer l'interaction au prop et afficher "E"
Citizen.CreateThread(function()
    local interactionDist = Config.InteractionDistance or 2.5
    local interactionDistSq = interactionDist * interactionDist -- Distance au carré pour éviter sqrt

    while true do
        local sleep = 300
        local playerCoords = GetEntityCoords(PlayerPedId())

        local closestProp = nil
        local closestDistSq = interactionDistSq
        local closestChestId = nil
        local hasAccess = false

        -- Chercher le prop le plus proche (et gérer le (re)spawn local du prop)
        for chestId, propData in pairs(spawnedProps) do
            if propData and propData.coords then
                local diff = playerCoords - propData.coords
                local distSq = diff.x * diff.x + diff.y * diff.y + diff.z * diff.z

                -- (Re)spawn ou despawn de l'entité locale en fonction de la distance.
                -- L'entrée n'est PAS supprimée tant que le serveur n'a pas confirmé que le coffre est vide.
                if distSq < (PROP_SPAWN_DISTANCE * PROP_SPAWN_DISTANCE) then
                    if not propData.entity or not DoesEntityExist(propData.entity) then
                        spawnPropEntityForChest(propData)
                    end
                else
                    if propData.entity and DoesEntityExist(propData.entity) then
                        DeleteEntity(propData.entity)
                    end
                    propData.entity = nil
                end

                if distSq < closestDistSq and propData.entity and DoesEntityExist(propData.entity) then
                    closestDistSq = distSq
                    closestProp = propData.entity
                    closestChestId = chestId

                    -- Vérifier si le joueur a accès (job requis)
                    if propData.requiredJob then
                        local playerJobName = VFW.PlayerData.job and VFW.PlayerData.job.name
                        hasAccess = playerJobName and (string.lower(playerJobName) == string.lower(propData.requiredJob)) or false
                    else
                        hasAccess = true
                    end
                end
            end
        end

        -- Si on est proche d'un prop ET qu'on a le bon job, afficher le message E
        if closestProp and hasAccess then
            sleep = 0
            targetProp = closestProp
            targetChestId = closestChestId

            -- show help every time we are near the prop (ignore isChestOpen state)
            if not isInInteraction and not showMenu then
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le coffre")
            end

            if VFW.Interact.JustReleased(0, 38) then
                isChestOpen = true
                TriggerEvent("vfw:openTestChest", closestChestId)
            end
        else
            targetProp = nil
            targetChestId = nil
            -- reset flag when leaving area so help reappears later
            isChestOpen = false
        end

        Citizen.Wait(sleep)
    end
end)
