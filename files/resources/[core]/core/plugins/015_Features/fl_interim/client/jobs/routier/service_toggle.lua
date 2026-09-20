local truck, trailer
local trailerHintBlip, trailerHintThread

local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

CreateThread(function()
    Citizen.Wait(5000)
    PlayerData = VFW.GetPlayerData()
end)

local function removeTrailerHint()
    if trailerHintBlip then
        RemoveBlip(trailerHintBlip)
        trailerHintBlip = nil
    end
    trailerHintThread = nil
end


local function getTrailerHitchWorldPos(tr)
    local bones = { "tow_attach", "attach_female", "attach_male", "towbar" }
    for _, name in ipairs(bones) do
        local idx = GetEntityBoneIndexByName(tr, name)
        if idx ~= -1 then
            local pos = GetWorldPositionOfEntityBone(tr, idx)
            if pos then return pos end
        end
    end
    local minDim, maxDim = GetModelDimensions(GetEntityModel(tr))
    local yFront = (maxDim.y or 2.5) - 0.6
    local zNearG = (minDim.z or 0.0) + 0.25
    return GetOffsetFromEntityInWorldCoords(tr, 0.0, yFront, zNearG)
end

local function createTrailerHint(tr)


    removeTrailerHint()

    local pos = getTrailerHitchWorldPos(tr)
    trailerHintBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipRoute(trailerHintBlip, true)
    SetBlipScale(trailerHintBlip, 0.5)
    SetBlipSprite(trailerHintBlip, 1)
    SetBlipColour(trailerHintBlip, 5)

    trailerHintThread = true
    CreateThread(function()
        while trailerHintThread do
            Wait(400)
            if not DoesEntityExist(tr) then
                removeTrailerHint()
                break
            end

            local hitchPos = getTrailerHitchWorldPos(tr)
            SetBlipCoords(trailerHintBlip, hitchPos.x, hitchPos.y, hitchPos.z)

            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                local ok, tveh = GetVehicleTrailerVehicle(veh)
                if ok and tveh ~= 0 then
                    removeTrailerHint()
                    RoutierStartDelivery()
                    break
                end
            end
        end
    end)
end



function ToggleRoutierGarage(pos)

    if not PlayerData or not PlayerData.job then
        DebugPlayerData()
        return false
    end

    if DoesEntityExist(truck) then
        if DoesEntityExist(truck) then
            if NetworkGetEntityIsNetworked(truck) then
                local netIdTruck = NetworkGetNetworkIdFromEntity(truck)
                TriggerServerEvent("interim:routier:unregisterVehicle", netIdTruck)
            end
            DeleteVehicle(truck)
            truck = nil
        end

        if DoesEntityExist(trailer) then
            if NetworkGetEntityIsNetworked(trailer) then
                local netIdTrailer = NetworkGetNetworkIdFromEntity(trailer)
                TriggerServerEvent("interim:routier:unregisterVehicle", netIdTrailer)
            end
            DeleteVehicle(trailer)
            trailer = nil
        end

        removeTrailerHint()
        VFW.ShowNotification({ type = "VERT", subtitle = "Intérim Routier", content = "Camion et remorque rangés." })
        return true
    end

    -- Récupérer toutes les places physiquement libres puis tenter le spawn sur chacune
    -- (le serveur peut refuser si un autre joueur vient juste de réserver le même spot)
    local availableTruckSpots = {}
    for _, v in pairs(pos.truckSpots or {}) do
        if VFW.Game.IsSpawnPointClear(vector3(v.x, v.y, v.z), 3.0) then
            availableTruckSpots[#availableTruckSpots + 1] = v
        end
    end

    if #availableTruckSpots == 0 then
        VFW.ShowNotification({ type = 'ROUGE', subtitle = "Intérim Routier", content = "Aucune place libre pour le camion." })
        return false
    end

    local netIdTruck = nil
    for _, v in ipairs(availableTruckSpots) do
        local tcoords = vector3(v.x, v.y, v.z)
        local theading = v.w
        netIdTruck = TriggerServerCallback("interim:routier:requestvehicle", tcoords, theading, { type = "truck" })
        if netIdTruck then break end
        Wait(50)
    end

    if not netIdTruck then
        VFW.ShowNotification({ type="ROUGE", subtitle = "Intérim Routier", content="Impossible de récupérer un camion, réessaie dans un instant." })
        return false
    end

    truck = NetToVeh(netIdTruck)

    local timeout = GetGameTimer() + 5000
    while not DoesEntityExist(truck) and GetGameTimer() < timeout do
        Wait(50)
        truck = NetToVeh(netIdTruck)
    end

    if not DoesEntityExist(truck) then
        VFW.ShowNotification({ type="ROUGE", subtitle = "Intérim Routier", content="Erreur lors du spawn du camion." })
        return false
    end

    Entity(truck).state:set("VehicleProperties", VFW.Game.GetVehicleProperties(truck), true)
    TaskWarpPedIntoVehicle(PlayerPedId(), truck, -1)

    RoutierSpawnTrailerForNewMission()


    return true
end

function RoutierSpawnTrailerForNewMission()



    local t = TriggerServerCallback("interim:routier:getPositionsAll")
    if not t then
        VFW.ShowNotification({ type="ROUGE", subtitle = "Intérim Routier", content="Configuration indisponible." })
        return
    end

    if not DoesEntityExist(truck) then
        VFW.ShowNotification({ type="ROUGE", subtitle = "Intérim Routier", content="Aucun camion sorti." })
        return
    end

    if DoesEntityExist(trailer) then
        if NetworkGetEntityIsNetworked(trailer) then
            local oldt = NetworkGetNetworkIdFromEntity(trailer)
            TriggerServerEvent("interim:routier:unregisterVehicle", oldt)
        end
        DeleteVehicle(trailer)
        trailer = nil
    end

    -- Récupérer toutes les places libres, puis tenter le spawn sur chacune
    -- jusqu'à en trouver une où le serveur réussit (le premier IsSpawnPointClear=true
    -- n'est pas suffisant : un véhicule peut arriver entre-temps, ou le spawn serveur
    -- peut échouer pour d'autres raisons réseau)
    local availableSpots = {}
    for _, v in pairs(t.trailerSpots or {}) do
        -- Rayon 3.0 car certains spots sont à seulement ~4m l'un de l'autre
        if VFW.Game.IsSpawnPointClear(vector3(v.x, v.y, v.z), 3.0) then
            availableSpots[#availableSpots + 1] = v
        end
    end

    if #availableSpots == 0 then
        VFW.ShowNotification({ type = 'ROUGE', subtitle = "Intérim Routier", content = "Aucune place libre pour la remorque." })
        return
    end

    local netIdTrailer = nil
    for _, v in ipairs(availableSpots) do
        local tcoords = vector3(v.x, v.y, v.z)
        local theading = v.w
        netIdTrailer = TriggerServerCallback("interim:routier:requestvehicle", tcoords, theading, { type = "trailer" })
        if netIdTrailer then break end
        Wait(50)
    end

    if not netIdTrailer then
        VFW.ShowNotification({ type="ROUGE", subtitle = "Intérim Routier", content="Impossible de récupérer une remorque, réessaie dans un instant." })
        return
    end

    trailer = NetToVeh(netIdTrailer)

    local timeout = GetGameTimer() + 5000
    while not DoesEntityExist(trailer) and GetGameTimer() < timeout do
        Wait(50)
        trailer = NetToVeh(netIdTrailer)
    end

    if not DoesEntityExist(trailer) then
        VFW.ShowNotification({ type="ROUGE", subtitle = "Intérim Routier", content="Erreur lors du spawn de la remorque." })
        return
    end

    Entity(trailer).state:set("VehicleProperties", VFW.Game.GetVehicleProperties(trailer), true)
    createTrailerHint(trailer)
end

function RoutierCleanup()


    if DoesEntityExist(truck) then
        if NetworkGetEntityIsNetworked(truck) then
            TriggerServerEvent("interim:routier:unregisterVehicle", NetworkGetNetworkIdFromEntity(truck))
        end
        DeleteVehicle(truck)
        truck = nil
    end
    if DoesEntityExist(trailer) then
        if NetworkGetEntityIsNetworked(trailer) then
            TriggerServerEvent("interim:routier:unregisterVehicle", NetworkGetNetworkIdFromEntity(trailer))
        end
        DeleteVehicle(trailer)
        trailer = nil
    end
    removeTrailerHint()
    TriggerServerEvent("interim:routier:delivery:cancel", "cleanup")
end
