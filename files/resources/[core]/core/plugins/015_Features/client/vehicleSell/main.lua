VehicleResellerConfigs = {}
VehicleResellerNPCs = {}

local currentVersions = {}
local activeZones = {}
local currentLocationId = nil
isSellMenuOpen = false
local playerVehicleToSell = nil

local vehiclePoolCache = {}
local vehiclePoolCacheTime = 0
local VEHICLE_POOL_CACHE_TTL <const> = 500

local function GetPlayerVehicleNearby(playerPed, npcCoords, maxDistance, locationId)
    local playerCoords = GetEntityCoords(playerPed)
    local closestVehicle = nil
    local closestDistance = maxDistance

    local now = GetGameTimer()
    if now - vehiclePoolCacheTime > VEHICLE_POOL_CACHE_TTL then
        vehiclePoolCache = GetGamePool('CVehicle')
        vehiclePoolCacheTime = now
    end
    local vehicles = vehiclePoolCache

    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local distToNpc = #(vehCoords - vector3(npcCoords.x, npcCoords.y, npcCoords.z))

            if distToNpc < closestDistance then
                local isResellerVehicle = false
                for locId, loc in pairs(VehicleReseller.locations) do
                    for _, resellerVeh in pairs(loc.spawnedVehicles or {}) do
                        if resellerVeh == vehicle then
                            isResellerVehicle = true
                            break
                        end
                    end
                    if isResellerVehicle then break end
                end

                if not isResellerVehicle then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    if plate then
                        plate = plate:gsub("%s+", "")
                        closestVehicle = vehicle
                        closestDistance = distToNpc
                    end
                end
            end
        end
    end

    return closestVehicle
end

local function CalculateModPercent(vehicle, modType)
    if not vehicle or not DoesEntityExist(vehicle) then
        return 0
    end

    local currentMod = GetVehicleMod(vehicle, modType)
    local maxMods = GetNumVehicleMods(vehicle, modType)

    if maxMods <= 0 then
        return 100
    end

    local percentage = ((currentMod + 1) / maxMods) * 100
    return math.floor(VFW.Math.Clamp(percentage, 0, 100))
end

local function GetVehicleData(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return nil
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if plate then
        plate = plate:gsub("%s+", "")
    end

    local model = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(model)
    if modelName then
        modelName = modelName:lower()
    end

    local health = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local condition = math.floor(((health + engineHealth) / 2) / 10)

    local primaryColor, secondaryColor = GetVehicleColours(vehicle)

    SetVehicleModKit(vehicle, 0)
    local mods = {
        modEngine = CalculateModPercent(vehicle, 11),
        modBrakes = CalculateModPercent(vehicle, 12),
        modTransmission = CalculateModPercent(vehicle, 13),
        modSuspension = CalculateModPercent(vehicle, 15),
    }

    return {
        vehicle = vehicle,
        plate = plate,
        model = modelName,
        displayName = GetLabelText(GetDisplayNameFromVehicleModel(model)),
        condition = condition,
        primaryColor = primaryColor,
        secondaryColor = secondaryColor,
        mods = mods,
        health = health,
        engineHealth = engineHealth
    }
end

local function SetupNpcProtection(ped)
    SetEntityInvincible(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetRagdollBlockingFlags(ped, 1)
    SetRagdollBlockingFlags(ped, 2)
    SetRagdollBlockingFlags(ped, 4)
    SetPedSuffersCriticalHits(ped, false)
    SetPedDiesWhenInjured(ped, false)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
    SetPedConfigFlag(ped, 32, true)
    SetPedConfigFlag(ped, 281, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
end

local function SpawnNpc(locationId, npcCoords, npcModel)
    if VehicleResellerNPCs[locationId] and DoesEntityExist(VehicleResellerNPCs[locationId]) then
        DeleteEntity(VehicleResellerNPCs[locationId])
        VehicleResellerNPCs[locationId] = nil
    end

    local modelHash = GetHashKey(npcModel)
    local peds = GetGamePool('CPed')
    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local pedModel = GetEntityModel(ped)
            if pedModel == modelHash then
                local pedCoords = GetEntityCoords(ped)
                local dist = #(pedCoords - vector3(npcCoords.x, npcCoords.y, npcCoords.z))
                if dist < 3.0 then
                    DeleteEntity(ped)
                end
            end
        end
    end

    VFW.CreatePed(npcCoords, npcModel)
    Wait(1000)

    peds = GetGamePool('CPed')
    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local pedCoords = GetEntityCoords(ped)
            local dist = #(pedCoords - vector3(npcCoords.x, npcCoords.y, npcCoords.z))
            if dist < 3.0 then
                local pedModel = GetEntityModel(ped)
                if pedModel == modelHash then
                    VehicleResellerNPCs[locationId] = ped
                    SetupNpcProtection(ped)
                    return
                end
            end
        end
    end
end

local function DespawnNpc(locationId)
    if VehicleResellerNPCs[locationId] and DoesEntityExist(VehicleResellerNPCs[locationId]) then
        DeleteEntity(VehicleResellerNPCs[locationId])
    end
    VehicleResellerNPCs[locationId] = nil
end

local vehicleSellReady = false

local function CleanupAll()
    for locationId, _ in pairs(VehicleResellerNPCs) do
        DespawnNpc(locationId)
    end
    VehicleReseller:CleanupAll()
    activeZones = {}
    currentVersions = {}
    VehicleResellerConfigs = {}
    vehicleSellReady = false
end

local function InitVehicleSell()
    CleanupAll()

    VehicleResellerConfigs = TriggerServerCallback("vehicleSell:getAllConfigs") or {}

    for locationId, cfg in pairs(VehicleResellerConfigs) do
        SpawnNpc(locationId, cfg.npc_coords, cfg.npc_model)
    end

    vehicleSellReady = true
end

RegisterNetEvent("vfw:playerLoaded", function()
    InitVehicleSell()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CleanupAll()
end)

RegisterNetEvent("vehicleSell:syncConfig", function(locationId, config)
    locationId = tonumber(locationId)
    if not locationId then return end

    local oldConfig = VehicleResellerConfigs[locationId]
    VehicleResellerConfigs[locationId] = config

    if not oldConfig then return end

    local coordsChanged = oldConfig.npc_coords.x ~= config.npc_coords.x
        or oldConfig.npc_coords.y ~= config.npc_coords.y
        or oldConfig.npc_coords.z ~= config.npc_coords.z
    local modelChanged = oldConfig.npc_model ~= config.npc_model

    if coordsChanged or modelChanged then
        DespawnNpc(locationId)
        SpawnNpc(locationId, config.npc_coords, config.npc_model)
    end
end)

RegisterNetEvent("vehicleSell:locationCreated", function(locationId, config)
    locationId = tonumber(locationId)
    if not locationId or not config then return end

    VehicleResellerConfigs[locationId] = config
    SpawnNpc(locationId, config.npc_coords, config.npc_model)
end)

RegisterNetEvent("vehicleSell:locationDeleted", function(locationId)
    locationId = tonumber(locationId)
    if not locationId then return end

    DespawnNpc(locationId)
    VehicleReseller:Cleanup(locationId)
    VehicleResellerConfigs[locationId] = nil
    activeZones[locationId] = nil
    currentVersions[locationId] = nil
end)

CreateThread(function()
    local sleep = 750

    while not vehicleSellReady do
        Wait(500)
    end

    while true do
        sleep = 750
        local playerCoords = nil
        local closestLocId = nil
        local closestNpcDist = math.huge

        if not VFW.PlayerData.ped then
            goto mainContinue
        end

        playerCoords = GetEntityCoords(VFW.PlayerData.ped)

        for locationId, cfg in pairs(VehicleResellerConfigs) do
            if not cfg then goto locContinue end

            local npcPos = cfg.npc_coords
            local distance = #(playerCoords - vector3(npcPos.x, npcPos.y, npcPos.z))

            if distance <= cfg.interaction_distance and not isSellMenuOpen then
                if distance < closestNpcDist then
                    closestNpcDist = distance
                    closestLocId = locationId
                end
            end

            if distance <= cfg.zone_distance and not activeZones[locationId] then
                TriggerServerEvent("core:vehicleSell:checkVersion", locationId, currentVersions[locationId] or 0)
                activeZones[locationId] = true
            elseif distance <= cfg.zone_distance and activeZones[locationId] then
                VehicleReseller:DrawVehicles(locationId)
                sleep = 0
            elseif distance > cfg.zone_distance and activeZones[locationId] then
                activeZones[locationId] = nil
                VehicleReseller:Cleanup(locationId)
                TriggerServerEvent("core:vehicleSell:sortedZones", locationId)
            end

            ::locContinue::
        end

        if closestLocId and not isSellMenuOpen then
            sleep = 0
            currentLocationId = closestLocId

            if not VehicleReseller.animationInProgress then
                local cfg = VehicleResellerConfigs[closestLocId]
                local nearbyVehicle = GetPlayerVehicleNearby(VFW.PlayerData.ped, cfg.npc_coords, cfg.vehicle_detection_distance, closestLocId)

                if nearbyVehicle then
                    playerVehicleToSell = GetVehicleData(nearbyVehicle)
                else
                    playerVehicleToSell = nil
                end

                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour parler au revendeur de véhicule", false, false, -1)

                if VFW.Interact.JustPressed(0, 38) then
                    VFW.OpenSellMenu(closestLocId, playerVehicleToSell)
                end
            end
        end

        if isSellMenuOpen and currentLocationId then
            local cfg = VehicleResellerConfigs[currentLocationId]
            if cfg then
                local npcPos = cfg.npc_coords
                local dist = #(playerCoords - vector3(npcPos.x, npcPos.y, npcPos.z))
                if dist > 5.0 then
                    isSellMenuOpen = false
                    VFW.CloseSellMenu()
                end
            end
        end

        ::mainContinue::
        Wait(sleep)
    end
end)

RegisterNetEvent("core:vehicleSell:UpdateData", function(locationId, version, data)
    locationId = tonumber(locationId)
    if not locationId then return end
    currentVersions[locationId] = version
    VehicleReseller:ReformatData(locationId, data)
end)

RegisterNetEvent("vfw:vehicleSell:unlockVehicleOnParking", function(locationId, plate)
    if not plate then return end
    locationId = tonumber(locationId)
    if not locationId then return end

    plate = plate:gsub("%s+", "")

    local loc = VehicleReseller.locations[locationId]
    if not loc then return end

    for index, vehicle in pairs(loc.spawnedVehicles) do
        if vehicle and DoesEntityExist(vehicle) then
            local vehPlate = GetVehicleNumberPlateText(vehicle)
            if vehPlate then
                vehPlate = vehPlate:gsub("%s+", "")
                if vehPlate == plate then
                    FreezeEntityPosition(vehicle, false)
                    SetVehicleDoorsLocked(vehicle, 0)
                    SetEntityInvincible(vehicle, false)
                    SetEntityCanBeDamaged(vehicle, true)
                    SetVehicleCanBeVisiblyDamaged(vehicle, true)

                    loc.spawnedVehicles[index] = nil
                    loc.vehicleDataMap[vehicle] = nil
                    loc.cache[index] = nil

                    return
                end
            end
        end
    end
end)

local pendingBuyPlate = nil
local buyTimeRemaining = 0
local buyVehicleBlip = nil

local function sellerNotif(content, subtitle)
    local locId = currentLocationId
    local cfg = VehicleResellerConfigs and locId and VehicleResellerConfigs[locId]
    local npcImage = cfg and cfg.npc_image or VFW.CDN.Get("others/vehicle_sell_seller.png")
    VFW.ShowNotification({
        type = "JOB",
        title = "Vendeur Véhicule",
        subtitle = subtitle or "Information",
        image = npcImage,
        content = content
    })
end

RegisterNetEvent("vfw:vehicleSell:startBuyTimer", function(plate, duration, vehicleCoords)
    pendingBuyPlate = plate
    buyTimeRemaining = duration

    if buyVehicleBlip and DoesBlipExist(buyVehicleBlip) then
        RemoveBlip(buyVehicleBlip)
    end

    buyVehicleBlip = AddBlipForCoord(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)
    SetBlipSprite(buyVehicleBlip, 326)
    SetBlipColour(buyVehicleBlip, 2)
    SetBlipScale(buyVehicleBlip, 0.5)
    SetBlipRoute(buyVehicleBlip, true)
    SetBlipRouteColour(buyVehicleBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Votre véhicule")
    EndTextCommandSetBlipName(buyVehicleBlip)

    sellerNotif(("Votre véhicule vous attend. Vous avez %d minutes pour le récupérer."):format(math.floor(duration / 60)), "Récupération")

    CreateThread(function()
        local checkInterval = 1000

        while pendingBuyPlate == plate and buyTimeRemaining > 0 do
            Wait(checkInterval)

            local playerPed = PlayerPedId()

            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local vehiclePlate = GetVehicleNumberPlateText(vehicle)

                if vehiclePlate then
                    vehiclePlate = vehiclePlate:gsub("%s+", "")

                    if vehiclePlate == plate then
                        TriggerServerEvent("vfw:vehicleSell:buyVehicleEntered", plate)
                        pendingBuyPlate = nil
                        buyTimeRemaining = 0

                        if buyVehicleBlip and DoesBlipExist(buyVehicleBlip) then
                            RemoveBlip(buyVehicleBlip)
                            buyVehicleBlip = nil
                        end

                        sellerNotif("Félicitations. Profitez bien de votre nouveau véhicule.", "Achat finalisé")
                        return
                    end
                end
            end

            buyTimeRemaining = buyTimeRemaining - 1

            if buyTimeRemaining > 0 and (buyTimeRemaining % 60 == 0 or buyTimeRemaining <= 30) then
                local minutes = math.floor(buyTimeRemaining / 60)
                local seconds = buyTimeRemaining % 60

                if minutes > 0 then
                    sellerNotif(("Récupérez votre véhicule. Temps restant : %d min %02d sec."):format(minutes, seconds), "Récupération")
                else
                    sellerNotif(("Attention. Plus que %d secondes pour récupérer votre véhicule."):format(seconds), "Récupération")
                end
            end
        end

        if buyVehicleBlip and DoesBlipExist(buyVehicleBlip) then
            RemoveBlip(buyVehicleBlip)
            buyVehicleBlip = nil
        end
    end)
end)

local pendingRecoveryPlate = nil
local recoveryTimeRemaining = 0

RegisterNetEvent("vfw:vehicleSell:startRecoveryTimer", function(plate, duration)
    pendingRecoveryPlate = plate
    recoveryTimeRemaining = duration

    CreateThread(function()
        local checkInterval = 1000

        while pendingRecoveryPlate == plate and recoveryTimeRemaining > 0 do
            Wait(checkInterval)

            local playerPed = PlayerPedId()

            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local vehiclePlate = GetVehicleNumberPlateText(vehicle)

                if vehiclePlate then
                    vehiclePlate = vehiclePlate:gsub("%s+", "")

                    if vehiclePlate == plate then
                        TriggerServerEvent("vfw:vehicleSell:vehicleEntered", plate)
                        pendingRecoveryPlate = nil
                        recoveryTimeRemaining = 0
                        return
                    end
                end
            end

            recoveryTimeRemaining = recoveryTimeRemaining - 1

            if recoveryTimeRemaining > 0 and (recoveryTimeRemaining % 30 == 0 or recoveryTimeRemaining <= 10) then
                local minutes = math.floor(recoveryTimeRemaining / 60)
                local seconds = recoveryTimeRemaining % 60

                if minutes > 0 then
                    sellerNotif(("Récupérez votre véhicule. Temps restant : %d min %02d sec."):format(minutes, seconds), "Récupération")
                else
                    sellerNotif(("Attention. Plus que %d secondes pour récupérer votre véhicule."):format(seconds), "Récupération")
                end
            end
        end
    end)
end)

function VFW.GetCurrentSellLocationId()
    return currentLocationId
end
