RegisterNUICallback("nui:vehicleStorage:selectVehicle", function(data, cb)
    cb(true)

    -- Preview du véhicule sélectionné au spawn point
    Garage:DeletePreview()

    local vehicleName = data and data.vehicle and (data.vehicle.name or data.vehicle.vehName)
    if not vehicleName then
        return
    end

    if not Garage.isOpen then
        return
    end

    local spawnCoords <const> = Garage:GetAvailableSpawnPosition(Garage.currentGarage.spawnPosition)
    if not spawnCoords then
        return
    end

    Garage.previewGeneration = (Garage.previewGeneration or 0) + 1
    local myGeneration <const> = Garage.previewGeneration

    local modelHash <const> = GetHashKey(vehicleName)
    RequestModel(modelHash)

    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(0)
        timeout = timeout + 1
    end

    if not HasModelLoaded(modelHash) then
        return
    end

    -- Le menu a été fermé ou une autre preview a été demandée pendant le chargement
    if not Garage.isOpen or Garage.previewGeneration ~= myGeneration then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    local heading = spawnCoords.w or 0.0
    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, false, false)
    SetModelAsNoLongerNeeded(modelHash)

    if not DoesEntityExist(vehicle) then
        return
    end

    -- Double-check après CreateVehicle au cas où fermeture pendant la frame
    if not Garage.isOpen or Garage.previewGeneration ~= myGeneration then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteEntity(vehicle)
        return
    end

    SetVehicleOnGroundProperly(vehicle)
    FreezeEntityPosition(vehicle, true)
    SetEntityCollision(vehicle, false, false)
    SetEntityCompletelyDisableCollision(vehicle, false, false)
    SetEntityAlpha(vehicle, 120, false)
    SetEntityInvincible(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 2)

    local props = data.vehicle.prop or data.vehicle.props
    if props and VFW.Game and VFW.Game.SetVehicleProperties then
        VFW.Game.SetVehicleProperties(vehicle, props)
    end

    Garage.previewVehicle = vehicle
end)

RegisterNUICallback("nui:vehicleStorage:takeOutVehicle", function(data, cb)
    -- Garage métier : spawn illimité sans plate/possession
    if Garage.currentGarage and Garage.currentGarage.type == "jobGarage" then
        local spawnCoords <const> = Garage:GetAvailableSpawnPosition(Garage.currentGarage.spawnPosition)
        if not spawnCoords then
            VFW.ShowNotification({ type = 'ROUGE', title = 'Garage', message = "Aucune place de spawn disponible." })
            return cb(false)
        end

        local vehicleModel = data.vehicle and (data.vehicle.name or data.vehicle.vehName)
        if not vehicleModel then
            return cb(false)
        end

        local vehicleType = VFW.GetVehicleTypeClient(joaat(vehicleModel))
        TriggerServerEvent("policeGarage:spawnVehicle", vehicleModel, Garage.currentGarage.id, spawnCoords, vehicleType or "automobile")
        Garage:Close()
        TriggerEvent("policeGarage:menuClosed")
        return cb(true)
    end

    local spawnCoords <const> = Garage:GetAvailableSpawnPosition(Garage.currentGarage.spawnPosition)

    if not spawnCoords then
        VFW.ShowNotification({
            type = 'ROUGE',
            title = 'Garage',
            message = "Aucune place de spawn disponible, veuillez dégager les emplacements."
        })
        return cb(false)
    end

    TriggerServerEvent("garage:exitVehicle", Garage.currentGarage.id, data.vehicle.plate, spawnCoords, data.repair or false)
    Garage:Close()
    cb(true)
end)

RegisterNUICallback("nui:vehicleStorage:close", function(data, cb)
    Garage:Close()
    TriggerEvent("policeGarage:menuClosed")
    cb(true)
end)

RegisterNUICallback("nui:vehicleStorage:getAddableVehicles", function(_, cb)
    local vehicles <const> = TriggerServerCallback("garage:getAllPlayerVehicles", Garage.currentGarage.id)

    local data = {
        addVehicles = formatVehiclesLabel(vehicles)
    }

    cb(data)
end)

RegisterNUICallback("garage:giveVehicle", function(data, cb)
    Garage:Close()

    local playerSelect <const> = VFW.StartSelect(3.0, true)

    if not playerSelect then
        return
    end

    local playerServerId <const> = GetPlayerServerId(playerSelect)

    TriggerServerEvent("garage:changeVehicleOwner", data.vehicle.plate, playerServerId)

    cb(true)
end)

RegisterNUICallback("nui:vehicleStorage:addVehicleToSociety", function(data, cb)
    TriggerServerEvent("garage:attributeVehicleToSociety", data.plate, Garage.currentGarage.id)

    cb(true)
end)

RegisterNUICallback("nui:vehicleStorage:addVehicleToGang", function(data, cb)
    TriggerServerEvent("garage:attributeVehicleToSociety", data.plate, Garage.currentGarage.id)

    -- Attendre que le serveur traite le transfert puis rafraîchir les données
    Wait(500)
    local garageData = TriggerServerCallback("garage:getGarageData", Garage.currentGarage.id)
    if garageData and garageData.groupVehicles then
        SendNUIMessage({
            action = "nui:vehicleStorage:refreshGangVehicles",
            data = { gangVehicles = formatVehiclesLabel(garageData.groupVehicles) }
        })
    end

    cb(true)
end)

RegisterNUICallback("garage:removeVehicleFromSociety", function(data, cb)
    if not data.plate then
        return cb(false)
    end

    TriggerServerEvent("garage:removeVehicleFromGroup", data.plate, Garage.currentGarage.id)
    Garage:Close()

    cb(true)
end)

RegisterNUICallback("garage:removeVehicleFromGang", function(data, cb)
    if not data.plate then
        return cb(false)
    end

    TriggerServerEvent("garage:removeVehicleFromGroup", data.plate, Garage.currentGarage.id)
    Garage:Close()

    cb(true)
end)

RegisterNetEvent("garage:retrieve:list", function(garages)
    Garage:RemoveAll()

    while not VFW?.PlayerData?.job do
        Wait(0)
    end

    local playerJob <const> = VFW.PlayerData.job.name
    local playerFaction <const> = VFW.PlayerData.faction.name

    for _, garage in pairs(garages.public or {}) do
        Garage:init(garage)
    end

    for _, garage in pairs(garages.society or {}) do
        if garage.access and garage.access.name == playerJob then
            Garage:init(garage)
        end
    end

    for _, garage in pairs(garages.gang or {}) do
        if garage.access and garage.access.name == playerFaction then
            Garage:init(garage)
        end
    end
end)

RegisterNetEvent("garage:modify:list", function(id, garage)
    Garage:Remove(id)
    Garage:init(garage)
end)

RegisterNetEvent("garage:retrieve:loadGarage", function(garages)
    if not garages or not next(garages) then
        return
    end

    for type, garagesByType in pairs(garages) do
        for id, garage in pairs(garagesByType) do
            Garage:init(garage)
        end
    end
end)

RegisterNetEvent("garage:delete:list", function(id)

    Garage:Remove(id)
end)

RegisterNetEvent("garage:add:list", function(id, garage)
    Garage:init(garage)
end)

RegisterNetEvent("vfw:repairVehicle", function(netId)
    local vehicle <const> = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then
        return
    end

    SetVehicleEngineHealth(vehicle, 1000)
    SetVehicleBodyHealth(vehicle, 1000)
    SetVehicleFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    Entity(vehicle).state:set("engineDestroyed", nil, true)
end)

RegisterNetEvent("garage:placeVehicleOnGround", function(netId)
    if not netId then return end

    local deadline <const> = GetGameTimer() + 2000
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    while (not DoesEntityExist(vehicle)) and GetGameTimer() < deadline do
        Wait(50)
        vehicle = NetworkGetEntityFromNetworkId(netId)
    end

    if not DoesEntityExist(vehicle) then return end

    if not NetworkHasControlOfEntity(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        local tries = 0
        while not NetworkHasControlOfEntity(vehicle) and tries < 20 do
            Wait(50)
            tries = tries + 1
        end
    end

    SetVehicleOnGroundProperly(vehicle)
end)

RegisterNetEvent("garage:onGroupChange", function(garages, oldGroup)
    if not oldGroup then
        return
    end

    Garage:DeleteGarageByGroupe(oldGroup)

    for id, garage in pairs(garages or {}) do
        Garage:init(garage)
    end
end)
