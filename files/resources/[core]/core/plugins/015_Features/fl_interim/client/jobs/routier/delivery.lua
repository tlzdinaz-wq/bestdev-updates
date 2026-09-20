local deliveryBlip, returnBlip
local deliveryCircle, returnTruckCircle, returnCircle
local markerThread
local positionsCache = nil
local configData = nil

local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

local function notify(t, msg)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({ type = t or 'JAUNE', subtitle = "Intérim Routier", content = msg })
    end
end

local function removeBlip(b)
    if b then RemoveBlip(b) end
    return nil
end

local function stopMarkers()
    markerThread = nil
end

local function runMarkers(deliveryPos, returnPos, returnTruckPos)
    stopMarkers()
    markerThread = true
    CreateThread(function()
        while markerThread do
            Wait(0)
            local ped = PlayerPedId()
            local p = GetEntityCoords(ped)

            if deliveryPos then
                local d = #(p - deliveryPos)
                if d < 75.0 then
                    DrawMarker(39, deliveryPos.x, deliveryPos.y, deliveryPos.z + 1.0,
                            0,0,0, 0,0,0, 1.0,1.0,1.0, 0,255,0,170, false,true,2,false,nil,nil,false)
                end
            end

            if returnPos then
                local d = #(p - returnPos)
                if d < 55.0 then
                    DrawMarker(39, returnPos.x, returnPos.y, returnPos.z + 1.0,
                            0,0,0, 0,0,0, 1.0,1.0,1.0, 255,255,255,170, false,true,2,false,nil,nil,false)
                end
            end

            if returnTruckPos then
                local d = #(p - returnTruckPos)
                if d < 55.0 then
                    DrawMarker(39, returnTruckPos.x, returnTruckPos.y, returnTruckPos.z + 1.0,
                            0,0,0, 0,0,0, 1.0,1.0,1.0, 0,150,255,170, false,true,2,false,nil,nil,false)
                end
            end
        end
    end)
end

function RoutierStartDelivery()



    TriggerServerEvent("interim:routier:delivery:requestStart")
end

function RoutierCancelDelivery(reason)
    TriggerServerEvent("interim:routier:delivery:cancel", reason or "manuel_client")
end

local function createDeliveryCircle(arrive, radius)
    local circleColor = (configData and configData.interactionCircle and configData.interactionCircle.color)
                      or {r = 0, g = 100, b = 0, a = 200}

    deliveryCircle = CreateInteractionCircle(
        vector3(arrive.x, arrive.y, arrive.z - 1.0),
        radius,
        circleColor,
        "Appuyez sur ~INPUT_CONTEXT~ pour livrer",
        function()
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
                notify("ROUGE", "Tu dois conduire le camion pour livrer.")
                return
            end
            local ok, trailer = GetVehicleTrailerVehicle(veh)
            if not ok or trailer == 0 then
                notify("ROUGE", "Aucune remorque attelée.")
                return
            end

            if not NetworkGetEntityIsNetworked(veh) or not NetworkGetEntityIsNetworked(trailer) then
                notify("ROUGE", "Les véhicules ne sont pas encore synchronisés.")
                return
            end
            local truckNet = NetworkGetNetworkIdFromEntity(veh)
            local trailerNet  = NetworkGetNetworkIdFromEntity(trailer)
            TriggerServerEvent("interim:routier:delivery:tryDeliver", truckNet, trailerNet)
        end
    )
end

RegisterNetEvent("interim:routier:delivery:setPhaseDeliver", function(data)


    if deliveryCircle then RemoveInteractionCircle(deliveryCircle) deliveryCircle = nil end
    if returnTruckCircle then RemoveInteractionCircle(returnTruckCircle) returnTruckCircle = nil end
    if returnCircle then RemoveInteractionCircle(returnCircle) returnCircle = nil end
    if deliveryBlip then deliveryBlip = removeBlip(deliveryBlip) end
    if returnBlip then returnBlip = removeBlip(returnBlip) end
    stopMarkers()

    local arrive = data.arrive
    local radius = data.radius or 8.0

    deliveryBlip = AddBlipForCoord(arrive.x, arrive.y, arrive.z)
    SetBlipRoute(deliveryBlip, true)
    SetBlipScale(deliveryBlip, 0.5)

    -- Récupérer la config si pas déjà fait
    if not configData then
        configData = TriggerServerCallback("interim:routier:getConfig")
    end
    createDeliveryCircle(arrive, radius)

    runMarkers(arrive, nil, nil)
end)


local function createReturnCircles(depot, depotTruck, radius)
    local circleColor = (configData and configData.interactionCircle and configData.interactionCircle.color)
                      or {r = 0, g = 100, b = 0, a = 120} -- Fallback vert foncé
    local deliveryColor = (configData and configData.interactionCircle and configData.interactionCircle.deliveryColor)
                        or {r = 70, g = 130, b = 180, a = 120} -- Fallback bleu acier

    local circleBlip = AddBlipForCoord(depot.x, depot.y, depot.z)
    SetBlipSprite(circleBlip, 318)
    SetBlipColour(circleBlip, 0)
    SetBlipScale(circleBlip, 0.5)
    SetBlipDisplay(circleBlip, 4)
    SetBlipAsShortRange(circleBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Récupérer sa paye et continuer le travail")
    EndTextCommandSetBlipName(circleBlip)

    local removeBlipTruck = AddBlipForCoord(depotTruck.x, depotTruck.y, depotTruck.z)
    SetBlipSprite(removeBlipTruck, 153)
    SetBlipColour(removeBlipTruck, 59)
    SetBlipScale(removeBlipTruck, 0.5)
    SetBlipDisplay(removeBlipTruck, 4)
    SetBlipAsShortRange(removeBlipTruck, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Rendre le camion et arrêt du travail")
    EndTextCommandSetBlipName(removeBlipTruck)


   returnCircle = CreateInteractionCircle(
        vector3(depot.x, depot.y, depot.z - 1.0),
        radius,
        circleColor,
        "Appuyez sur ~INPUT_CONTEXT~ pour encaisser & nouvelle mission",
        function()
            TriggerServerEvent("interim:routier:delivery:tryReturn", true)
            RemoveBlip(circleBlip)
            RemoveBlip(removeBlipTruck)
        end
    )

    returnTruckCircle = CreateInteractionCircle(
        vector3(depotTruck.x, depotTruck.y, depotTruck.z - 1.0),
        radius,
        deliveryColor,
        "Appuyez sur ~INPUT_CONTEXT~ pour rendre le camion",
        function()
            TriggerServerEvent("interim:routier:delivery:tryReturn", false)
            RemoveBlip(circleBlip)
            RemoveBlip(removeBlipTruck)
        end
    )
end

RegisterNetEvent("interim:routier:delivery:setPhaseReturn", function(data)



    if deliveryCircle then RemoveInteractionCircle(deliveryCircle) deliveryCircle = nil end
    if deliveryBlip then deliveryBlip = removeBlip(deliveryBlip) end
    stopMarkers()

    if not positionsCache then
        positionsCache = TriggerServerCallback("interim:routier:getPositionsAll")
    end
    local depot      = positionsCache.returnPoint
    local depotTruck = positionsCache.returnTruckPoint
    local radius     = positionsCache.returnPoint_radius or 5.0

    -- Récupérer la config si pas déjà fait
    if not configData then
        configData = TriggerServerCallback("interim:routier:getConfig")
    end
    createReturnCircles(depot, depotTruck, radius)

    returnBlip = AddBlipForCoord(depot.x, depot.y, depot.z)
    SetBlipRoute(returnBlip, true)
    SetBlipScale(returnBlip, 0.5)

    runMarkers(nil, depot, depotTruck)
    notify("JAUNE", "Vous avez livré la marchandise, vous pouvez retourner au port pour vous faire payer. Vous avez deux choix : soit relancer une mission, soit vous arrêter là.")
end)

RegisterNetEvent("interim:routier:delivery:finished", function(payload)


    if deliveryCircle then RemoveInteractionCircle(deliveryCircle) deliveryCircle = nil end
    if returnTruckCircle then RemoveInteractionCircle(returnTruckCircle) returnTruckCircle = nil end
    if returnCircle then RemoveInteractionCircle(returnCircle) returnCircle = nil end
    if deliveryBlip then deliveryBlip = removeBlip(deliveryBlip) end
    if returnBlip then returnBlip = removeBlip(returnBlip) end
    stopMarkers()

    local reward = tonumber(payload and payload.reward or 0) or 0
    if reward > 0 then
        notify("VERT", ("Paiement reçu : +%s"):format(VFW.Math.FormatMoney(reward)))
    end
end)

RegisterNetEvent("interim:routier:delivery:prepareNewMission", function()


    if RoutierSpawnTrailerForNewMission then
        RoutierSpawnTrailerForNewMission()
    end
end)

RegisterNetEvent("interim:routier:delivery:cleanup", function(payload)
    if deliveryCircle then RemoveInteractionCircle(deliveryCircle) deliveryCircle = nil end
    if returnTruckCircle then RemoveInteractionCircle(returnTruckCircle) returnTruckCircle = nil end
    if returnCircle then RemoveInteractionCircle(returnCircle) returnCircle = nil end
    if deliveryBlip then deliveryBlip = removeBlip(deliveryBlip) end
    if returnBlip then returnBlip = removeBlip(returnBlip) end
    stopMarkers()
    notify("ROUGE", ("Livraison annulée. %s"):format(payload.reason))
end)

RegisterNetEvent("interim:routier:notify", function(t, msg)
    notify(t, msg)
end)
