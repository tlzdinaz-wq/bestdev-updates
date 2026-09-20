VehicleReseller = {}
VehicleReseller.locations = {}

local function ensureLocation(locationId)
    if not VehicleReseller.locations[locationId] then
        VehicleReseller.locations[locationId] = {
            cache = {},
            spawnedVehicles = {},
            vehicleDataMap = {},
            currentPreview = nil,
            currentPreviewData = nil,
        }
    end
    return VehicleReseller.locations[locationId]
end

local function sellerNotif(locationId, content, subtitle)
    local cfg = VehicleResellerConfigs and VehicleResellerConfigs[locationId]
    local npcImage = cfg and cfg.npc_image or VFW.CDN.Get("others/vehicle_sell_seller.png")
    VFW.ShowNotification({
        type = "JOB",
        title = "Vendeur Véhicule",
        subtitle = subtitle or "Information",
        image = npcImage,
        content = content
    })
end

local COLORS = {
    WHITE = {255, 255, 255},
    GREEN = {100, 220, 100},
    YELLOW = {255, 200, 50},
    ORANGE = {255, 150, 50},
    RED = {255, 80, 80},
    CYAN = {100, 200, 255},
}

local function GetConditionColor(condition)
    if condition >= 90 then return COLORS.GREEN
    elseif condition >= 70 then return COLORS.GREEN
    elseif condition >= 50 then return COLORS.YELLOW
    elseif condition >= 30 then return COLORS.ORANGE
    else return COLORS.RED end
end

local function DrawText3D(coords, texts)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not onScreen then return end

    local lineHeight = 0.018
    local startY = screenY - (#texts * lineHeight / 2)

    for i, textData in ipairs(texts) do
        local text = textData.text
        local color = textData.color or COLORS.WHITE

        SetTextScale(0.30, 0.30)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(color[1], color[2], color[3], 255)
        SetTextOutline()
        SetTextCentre(true)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(screenX, startY + ((i - 1) * lineHeight))
    end
end

local function GetParkingSpots(locationId)
    local cfg = VehicleResellerConfigs and VehicleResellerConfigs[locationId]
    if not cfg or not cfg.parking_spots then
        return {}
    end
    return cfg.parking_spots
end

local function GetParkingSpotAsVector4(locationId, index)
    local spots = GetParkingSpots(locationId)
    local spot = spots[index]
    if not spot then return nil end
    return vector4(spot.x, spot.y, spot.z, spot.w)
end

function VehicleReseller:ReformatData(locationId, data)
    if not data or type(data) ~= "table" then
        return
    end

    local loc = ensureLocation(locationId)

    local newPlates = {}
    local newDataByPlate = {}
    for ownerId, owner in pairs(data) do
        for plate, vehicleData in pairs(owner) do
            vehicleData.ownerId = ownerId
            newPlates[plate] = true
            newDataByPlate[plate] = vehicleData
        end
    end

    local existingPlateToIndex = {}
    for i, vehData in pairs(loc.cache) do
        if vehData and vehData.plate then
            existingPlateToIndex[vehData.plate] = i
        end
    end

    for index, vehicle in pairs(loc.spawnedVehicles) do
        local vehData = loc.cache[index]
        if vehData and vehData.plate and not newPlates[vehData.plate] then
            if vehicle and DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
            loc.spawnedVehicles[index] = nil
            loc.vehicleDataMap[vehicle] = nil
            loc.cache[index] = nil
        end
    end

    for index, vehicle in pairs(loc.spawnedVehicles) do
        local vehData = loc.cache[index]
        if vehData and vehData.plate and newDataByPlate[vehData.plate] then
            local newData = newDataByPlate[vehData.plate]
            loc.cache[index] = newData
            loc.vehicleDataMap[vehicle] = newData
            newDataByPlate[vehData.plate] = nil
        end
    end

    local usedIndices = {}
    for index, _ in pairs(loc.spawnedVehicles) do
        usedIndices[index] = true
    end
    for index, _ in pairs(loc.cache) do
        usedIndices[index] = true
    end

    local nextFreeIndex = 1
    for plate, vehicleData in pairs(newDataByPlate) do
        while usedIndices[nextFreeIndex] do
            nextFreeIndex = nextFreeIndex + 1
        end
        loc.cache[nextFreeIndex] = vehicleData
        usedIndices[nextFreeIndex] = true
    end

    self:HidePreview(locationId)
end

function VehicleReseller:SpawnVehicles(locationId, model, pos, index)
    if not model or not pos then
        return
    end

    local loc = ensureLocation(locationId)

    local posVec = vector3(pos.x, pos.y, pos.z)
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            if #(vehCoords - posVec) < 2.0 then
                DeleteEntity(veh)
            end
        end
    end

    local vehicle <const> = VFW.Game.SpawnVehicle(model, pos, pos.w, nil, false)

    if not vehicle or vehicle == 0 then
        return
    end

    SetVehicleOnGroundProperly(vehicle)
    FreezeEntityPosition(vehicle, true)
    SetVehicleModKit(vehicle, 0)

    local vehicleData = loc.cache[index]

    if vehicleData and vehicleData.props then
        local propsData = type(vehicleData.props) == "string" and json.decode(vehicleData.props) or vehicleData.props
        if propsData then
            VFW.Game.SetVehicleProperties(vehicle, propsData)
        end
    end

    if vehicleData and vehicleData.plate then
        SetVehicleNumberPlateText(vehicle, vehicleData.plate)
    end

    SetEntityInvincible(vehicle, true)
    SetEntityCanBeDamaged(vehicle, false)
    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleTyresCanBurst(vehicle, false)
    SetVehicleWheelsCanBreak(vehicle, false)
    SetDisableVehiclePetrolTankDamage(vehicle, true)
    SetDisableVehiclePetrolTankFires(vehicle, true)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleDoorsLocked(vehicle, 2)

    loc.spawnedVehicles[index] = vehicle
    loc.vehicleDataMap[vehicle] = vehicleData
end

local function CalculateModPercent(veh, modIndex, modType)
    if not veh or not DoesEntityExist(veh) or not modIndex then
        return 0
    end

    local adjustedIndex <const> = modIndex - 1
    if adjustedIndex < 0 then
        return 0
    end

    local maxMods <const> = GetNumVehicleMods(veh, modType)
    if maxMods <= 0 then
        return 0
    end

    local percentage = (adjustedIndex / maxMods) * 100.0
    percentage = VFW.Math.Clamp(percentage, 0, 100)

    return math.floor(percentage)
end

local function GetVehicleCondition(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return 100
    end

    local health = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local avgHealth = (health + engineHealth) / 2

    return math.floor((avgHealth / 1000) * 100)
end

local function GetClosestParkingVehicle(locationId, playerCoords, maxDistance)
    local loc = VehicleReseller.locations[locationId]
    if not loc then return nil, nil, maxDistance end

    local closestVehicle = nil
    local closestDistance = maxDistance
    local closestData = nil

    for i, vehicle in pairs(loc.spawnedVehicles) do
        if vehicle and DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local dist = #(playerCoords - vehCoords)

            if dist < closestDistance then
                closestDistance = dist
                closestVehicle = vehicle
                closestData = loc.vehicleDataMap[vehicle]
            end
        end
    end

    return closestVehicle, closestData, closestDistance
end

function VehicleReseller:DrawPreview(locationId)
    local loc = self.locations[locationId]
    if not loc then return end

    if not loc.currentPreview or not DoesEntityExist(loc.currentPreview) then
        return
    end

    local vehicle = loc.currentPreview
    local vehicleData = loc.currentPreviewData
    if not vehicleData or not vehicleData.model then return end

    local vehCoords = GetEntityCoords(vehicle)
    local condition = GetVehicleCondition(vehicle)
    local conditionColor = GetConditionColor(condition)

    local texts = {
        { text = (vehicleData.model):upper() .. " | " .. (vehicleData.plate or "???"), color = COLORS.CYAN },
        { text = "Prix: " .. VFW.Math.FormatMoney(vehicleData.price or 0), color = COLORS.GREEN },
        { text = "Vendeur: " .. (vehicleData.sellerName or "Inconnu"), color = COLORS.WHITE },
        { text = "Etat: " .. condition .. "%", color = conditionColor },
    }

    DrawText3D(vector3(vehCoords.x, vehCoords.y, vehCoords.z + 1.8), texts)
end

function VehicleReseller:ShowPreview(locationId, vehicle, vehicleData)
    local loc = ensureLocation(locationId)
    loc.currentPreview = vehicle
    loc.currentPreviewData = vehicleData
end

function VehicleReseller:HidePreview(locationId)
    local loc = self.locations[locationId]
    if not loc then return end
    loc.currentPreview = nil
    loc.currentPreviewData = nil
end

local playerPed, playerCoords

function VehicleReseller:DrawVehicles(locationId)
    playerPed = VFW.PlayerData.ped

    if not playerPed or not DoesEntityExist(playerPed) then
        return
    end

    playerCoords = GetEntityCoords(playerPed)

    local loc = ensureLocation(locationId)

    for i = 1, #loc.cache do
        local vehData <const> = loc.cache[i]
        local pos <const> = GetParkingSpotAsVector4(locationId, i)
        if not vehData or not pos then
            goto continue
        end

        if not loc.spawnedVehicles[i] or not DoesEntityExist(loc.spawnedVehicles[i]) then
            self:SpawnVehicles(locationId, vehData.model, pos, i)
        end

        ::continue::
    end

    for i, vehicle in pairs(loc.spawnedVehicles) do
        if vehicle and DoesEntityExist(vehicle) then
            SetEntityInvincible(vehicle, true)
            SetEntityCanBeDamaged(vehicle, false)

            local vehCoords = GetEntityCoords(vehicle)
            local dist = #(playerCoords - vehCoords)

            if dist < 5.0 then
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 75, true)
            end
        end
    end

    local closestVehicle, closestData, distance = GetClosestParkingVehicle(locationId, playerCoords, 8.0)

    if closestVehicle and closestData then
        self:ShowPreview(locationId, closestVehicle, closestData)
    else
        self:HidePreview(locationId)
    end

    self:DrawPreview(locationId)
end

function VehicleReseller:Cleanup(locationId)
    local loc = self.locations[locationId]
    if not loc then return end

    self:HidePreview(locationId)

    for i, vehicle in pairs(loc.spawnedVehicles) do
        if vehicle and DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end

    loc.spawnedVehicles = {}
    loc.vehicleDataMap = {}
    loc.currentPreview = nil
end

function VehicleReseller:CleanupAll()
    for locationId, _ in pairs(self.locations) do
        self:Cleanup(locationId)
    end
    self.locations = {}
end

-- ========== ANIMATION DE VENTE ==========

local function GetNpcCoords(locationId)
    local cfg = VehicleResellerConfigs and VehicleResellerConfigs[locationId]
    if not cfg or not cfg.npc_coords then
        return vector4(0, 0, 0, 0)
    end
    return cfg.npc_coords
end

function VehicleReseller:GetNpcPed(locationId)
    local npc = VehicleResellerNPCs and VehicleResellerNPCs[locationId]
    if npc and DoesEntityExist(npc) then
        return npc
    end
    return nil
end

function VehicleReseller:GetAvailableParkingSpot(locationId)
    local loc = ensureLocation(locationId)
    local usedSpots = {}

    for i, _ in pairs(loc.spawnedVehicles) do
        usedSpots[i] = true
    end

    local spots = GetParkingSpots(locationId)
    for i, pos in ipairs(spots) do
        if not usedSpots[i] then
            return i, pos
        end
    end

    return nil, nil
end

local pendingSale = nil
VehicleReseller.animationInProgress = false
VehicleReseller.animationLocationId = nil

RegisterNetEvent("vfw:vehicle:npcBusyState", function(locationId, isBusy)
    if locationId == VehicleReseller.animationLocationId or not VehicleReseller.animationLocationId then
        VehicleReseller.animationInProgress = isBusy
        if not isBusy then
            VehicleReseller.animationLocationId = nil
        end
    end

    if isSellMenuOpen then
        SendNUIMessage({
            action = "updateNpcStatus",
            data = {
                npcBusy = isBusy
            }
        })
    end
end)

function VehicleReseller:PlaySellAnimation(locationId, vehicle, vehicleData, price, onComplete)
    if VehicleReseller.animationInProgress then
        sellerNotif(locationId, "Une animation est déjà en cours.")
        if onComplete then onComplete(false) end
        return
    end

    local npc = self:GetNpcPed(locationId)

    if not npc then
        sellerNotif(locationId, "Impossible de trouver le vendeur.")
        if onComplete then onComplete(false) end
        return
    end

    local spotIndex, parkingSpot = self:GetAvailableParkingSpot(locationId)

    if not parkingSpot then
        sellerNotif(locationId, "Aucune place de parking disponible.")
        if onComplete then onComplete(false) end
        return
    end

    SetEntityAsMissionEntity(vehicle, true, true)

    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
        Wait(100)
    end

    local timeout = 0
    while not NetworkHasControlOfEntity(vehicle) and timeout < 2000 do
        NetworkRequestControlOfEntity(vehicle)
        Wait(100)
        timeout = timeout + 100
    end

    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)

    if not vehicleNetId or vehicleNetId == 0 then
        sellerNotif(locationId, "Impossible de synchroniser le véhicule. Réessayez ou sortez puis remontez dans le véhicule.")
        if onComplete then onComplete(false) end
        return
    end

    local vehicleProps = VFW.Game.GetVehicleProperties(vehicle)

    pendingSale = {
        locationId = locationId,
        vehicle = vehicle,
        vehicleData = vehicleData,
        price = price,
        spotIndex = spotIndex,
        parkingSpot = parkingSpot,
        onComplete = onComplete,
        vehicleProps = vehicleProps
    }

    TriggerServerEvent("vfw:vehicle:requestSellAnimation", locationId, vehicleNetId, spotIndex, vehicleData, price)
end

RegisterNetEvent("vfw:vehicle:sellAnimationResponse", function(success, errorMsg, spotIndex)
    if not success then
        local locId = pendingSale and pendingSale.locationId
        sellerNotif(locId, errorMsg or "Erreur lors de la mise en vente.")
        if pendingSale and pendingSale.onComplete then
            pendingSale.onComplete(false)
        end
        pendingSale = nil
        return
    end
end)

RegisterNetEvent("vfw:vehicle:playSellAnimation", function(locationId, sellerServerId, vehicleNetId, spotIndex, sellerName)
    local isLocalSeller = GetPlayerServerId(PlayerId()) == sellerServerId
    local vehicle = nil

    if isLocalSeller and pendingSale and pendingSale.vehicle and DoesEntityExist(pendingSale.vehicle) then
        vehicle = pendingSale.vehicle
    else
        vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    end

    local parkingSpot = GetParkingSpotAsVector4(locationId, spotIndex)

    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end

    if not parkingSpot then
        return
    end

    VehicleReseller.animationInProgress = true
    VehicleReseller.animationLocationId = locationId

    SetEntityCoords(vehicle, parkingSpot.x, parkingSpot.y, parkingSpot.z, false, false, false, false)
    SetEntityHeading(vehicle, parkingSpot.w)
    SetVehicleOnGroundProperly(vehicle)
    FreezeEntityPosition(vehicle, true)
    SetEntityInvincible(vehicle, true)
    SetEntityCanBeDamaged(vehicle, false)
    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleDirtLevel(vehicle, 0.0)

    if isLocalSeller and pendingSale then
        TriggerServerEvent("vfw:vehicle:finalizeSale", locationId, pendingSale.vehicleData, pendingSale.price, pendingSale.vehicleProps)

        local loc = ensureLocation(locationId)
        local vehicleCacheData = {
            model = pendingSale.vehicleData.model,
            plate = pendingSale.vehicleData.plate,
            price = pendingSale.price,
            sellerName = sellerName or "Vous"
        }
        loc.cache[spotIndex] = vehicleCacheData
        loc.spawnedVehicles[spotIndex] = vehicle
        loc.vehicleDataMap[vehicle] = vehicleCacheData
    end

    VehicleReseller.animationInProgress = false
    VehicleReseller.animationLocationId = nil

    if isLocalSeller then
        if pendingSale and pendingSale.onComplete then
            pendingSale.onComplete(true)
        end
        pendingSale = nil
    end
end)

RegisterNetEvent("vfw:vehicle:saleFinalized", function(success, message)
    local locId = pendingSale and pendingSale.locationId or nil
    if success then
        sellerNotif(locId, message or "Véhicule mis en vente.", "Mise en vente")
    else
        sellerNotif(locId, message or "Erreur lors de la finalisation.")
    end
end)

local pendingBuy = nil

function VehicleReseller:GetVehicleSpotIndex(locationId, vehicle)
    local loc = self.locations[locationId]
    if not loc then return nil end
    for index, spawnedVeh in pairs(loc.spawnedVehicles) do
        if spawnedVeh == vehicle then
            return index
        end
    end
    return nil
end

function VehicleReseller:PlayBuyAnimation(locationId, vehicleData, paymentMethod, onComplete)
    if VehicleReseller.animationInProgress then
        sellerNotif(locationId, "Une animation est déjà en cours.")
        if onComplete then onComplete(false) end
        return
    end

    local loc = self.locations[locationId]
    if not loc then
        sellerNotif(locationId, "Location introuvable.")
        if onComplete then onComplete(false) end
        return
    end

    local vehicle = nil
    local spotIndex = nil

    for index, spawnedVeh in pairs(loc.spawnedVehicles) do
        if spawnedVeh and DoesEntityExist(spawnedVeh) then
            local plate = GetVehicleNumberPlateText(spawnedVeh)
            if plate then
                plate = plate:gsub("%s+", "")
                if plate == vehicleData.plate then
                    vehicle = spawnedVeh
                    spotIndex = index
                    break
                end
            end
        end
    end

    if not vehicle or not spotIndex then
        sellerNotif(locationId, "Véhicule introuvable dans le parking.")
        if onComplete then onComplete(false) end
        return
    end

    pendingBuy = {
        locationId = locationId,
        vehicleData = vehicleData,
        paymentMethod = paymentMethod,
        vehicle = vehicle,
        spotIndex = spotIndex,
        onComplete = onComplete
    }

    TriggerServerEvent("vfw:vehicle:requestBuyAnimation", locationId, vehicleData, paymentMethod, spotIndex)
end

RegisterNetEvent("vfw:vehicle:buyAnimationResponse", function(success, errorMsg, spotIndex, price)
    if not success then
        local locId = pendingBuy and pendingBuy.locationId
        sellerNotif(locId, errorMsg or "Erreur lors de l'achat.")
        if pendingBuy and pendingBuy.onComplete then
            pendingBuy.onComplete(false)
        end
        pendingBuy = nil
        return
    end
end)

RegisterNetEvent("vfw:vehicle:playBuyAnimation", function(locationId, buyerServerId, vehicleSpotIndex, buyerName, vehicleModel)
    local loc = VehicleReseller.locations[locationId]
    if not loc then return end

    local vehicle = loc.spawnedVehicles[vehicleSpotIndex]

    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end

    local isLocalBuyer = GetPlayerServerId(PlayerId()) == buyerServerId

    VehicleReseller.animationInProgress = true
    VehicleReseller.animationLocationId = locationId

    local vehicleCoords = GetEntityCoords(vehicle)
    local vehicleHeading = GetEntityHeading(vehicle)

    DeleteEntity(vehicle)

    loc.spawnedVehicles[vehicleSpotIndex] = nil
    loc.vehicleDataMap[vehicle] = nil
    loc.cache[vehicleSpotIndex] = nil

    if isLocalBuyer and pendingBuy then
        local newVehicle = VFW.Game.SpawnVehicle(vehicleModel, vector3(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z), vehicleHeading, nil, true)

        if newVehicle and newVehicle ~= 0 then
            SetVehicleOnGroundProperly(newVehicle)

            local props = pendingBuy.vehicleData and pendingBuy.vehicleData.props
            if props then
                local propsData = type(props) == "string" and json.decode(props) or props
                if propsData then
                    VFW.Game.SetVehicleProperties(newVehicle, propsData)
                end
            end

            if pendingBuy.vehicleData and pendingBuy.vehicleData.plate then
                SetVehicleNumberPlateText(newVehicle, pendingBuy.vehicleData.plate)
            end

            SetVehicleDoorsLocked(newVehicle, 0)
            SetVehicleDirtLevel(newVehicle, 0.0)
        end

        TriggerServerEvent("vfw:vehicle:finalizeBuy", locationId, pendingBuy.vehicleData, pendingBuy.paymentMethod, vehicleCoords)
    end

    VehicleReseller.animationInProgress = false
    VehicleReseller.animationLocationId = nil

    if isLocalBuyer then
        if pendingBuy and pendingBuy.onComplete then
            pendingBuy.onComplete(true)
        end
        pendingBuy = nil
    end
end)

RegisterNetEvent("vfw:vehicle:buyFinalized", function(success, message)
    local locId = pendingBuy and pendingBuy.locationId or nil
    if success then
        sellerNotif(locId, message or "Véhicule acheté. Bonne route.", "Achat finalisé")
    else
        sellerNotif(locId, message or "Erreur lors de la finalisation de l'achat.")
    end
end)
