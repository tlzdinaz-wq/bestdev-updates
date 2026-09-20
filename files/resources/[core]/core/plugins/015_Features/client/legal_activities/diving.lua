---@class Diving
local Diving <const> = {}

Diving.zone = nil
Diving.isDiving = false
Diving.maskRemaining = 0
Diving.currentBlip = nil
Diving.maskEntity = nil
Diving.tankEntity = nil
Diving.currentObject = nil

local maxMaskDuration <const> = Config.diving.maskDuration * 60 * 10
local notifiedPercents = {}

--- @param networkId number
--- @return boolean
local function awaitObject(networkId)
    -- Re-evaluate the existence check inside the loop; previously the value
    -- was captured once and the loop would just spin until the timeout.
    for _ = 1, 100 do
        if NetworkDoesEntityExistWithNetworkId(networkId) then
            return true
        end
        Wait(50)
    end
    return NetworkDoesEntityExistWithNetworkId(networkId)
end

-- start prend maintenant oxygenLevel en paramètre
function Diving.start(oxygenLevel)
    if Diving.isDiving then return end

    local lastOxygenPercent = nil
    Diving.isDiving = true

    -- Calcul du temps restant basé sur le meta oxygène (défaut 100%)
    local startPercent = oxygenLevel or 100
    Diving.maskRemaining = math.floor((startPercent / 100) * maxMaskDuration)

    notifiedPercents = {}

    -- BOUCLE 1 : GESTION OXYGÈNE
    CreateThread(function()
        local ped <const> = PlayerPedId()

        while Diving.isDiving do
            if IsPedSwimmingUnderWater(ped) then
                Diving.maskRemaining = Diving.maskRemaining - 1
                local maskPercent = (Diving.maskRemaining / maxMaskDuration) * 100
                local roundedPercent = math.floor(maskPercent)

                if maskPercent <= 50 and maskPercent > 5 then
                    if (roundedPercent == 50 or roundedPercent == 40 or roundedPercent == 30 or roundedPercent == 20 or roundedPercent == 10) and not notifiedPercents[roundedPercent] then
                        notifiedPercents[roundedPercent] = true
                        VFW.ShowNotification({
                            type = "JAUNE",
                            content = ("Oxygène restant : %i%%"):format(roundedPercent)
                        })
                    end
                elseif maskPercent <= 5 and maskPercent > 0 then
                    if not notifiedPercents[5] then
                        notifiedPercents[5] = true
                        VFW.ShowNotification({
                            type = "ROUGE",
                            content = "Oxygène restant : 5% - Attention !"
                        })
                    end
                end

                if Diving.maskRemaining <= 0 then
                    VFW.ShowNotification({
                        type = "ROUGE",
                        content = "Votre masque de plongée est vide, vous ne pouvez plus respirer sous l'eau !",
                    })
                    Diving.brokeMask()
                    break
                end
            end
            Wait(1000)
        end

        if Diving.currentBlip then
            VFW.RemoveBlipInternal(Diving.currentBlip)
            Diving.currentBlip = nil
        end
    end)

    -- BOUCLE 2 : UI
    CreateThread(function()
        while Diving.isDiving do
            local maskPercent = (Diving.maskRemaining / maxMaskDuration) * 100

            if lastOxygenPercent == nil then
                lastOxygenPercent = maskPercent
            end

            if math.floor(lastOxygenPercent) ~= math.floor(maskPercent) then
                SendNUIMessage({
                    action = "nui:oxygenBar:update",
                    data = {
                        visible = true,
                        percent = math.floor(maskPercent)
                    }
                })
                Wait(100)
                lastOxygenPercent = maskPercent
            end
            Wait(100)
        end

        SendNUIMessage({
            action = "nui:oxygenBar:update",
            data = {
                visible = false,
                percent = 0
            }
        })
    end)

    -- BOUCLE 3 : MISSION (Uniquement si une zone est définie)
    if Diving.zone then
        CreateThread(function()
            while Diving.isDiving and Diving.zone do
                if Diving.currentObject and DoesEntityExist(Diving.currentObject) then
                    local ped <const> = PlayerPedId()
                    local coords <const> = GetEntityCoords(ped)
                    local objectCoords <const> = GetEntityCoords(Diving.currentObject)
                    local distance <const> = #(coords - objectCoords)

                    DrawGlowSphere(objectCoords.x, objectCoords.y, objectCoords.z, 1.0, 255, 255, 255, 0.3, false, true)
                    DrawSpotLight(objectCoords.x, objectCoords.y, objectCoords.z + 5.0, 0.0, 0.0, objectCoords.z, 255,
                        255, 255, 40.0, 20.0, 0.0, 10.0, 1.0)

                    if distance <= 3.0 then
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour récupérer l'objet")

                        if VFW.Interact.JustPressed(0, 38) then
                            VFW.Streaming.RequestAnimDict("pickup_object")
                            TaskPlayAnim(ped, "pickup_object", "pickup_low", 1.0, 0.3, 100, 0, 0.0, false, false, false)
                            Wait(1000)
                            ClearPedTasks(ped)

                            if NetworkGetEntityIsNetworked(Diving.currentObject) then
                                local objectNetId = NetworkGetNetworkIdFromEntity(Diving.currentObject)
                                if objectNetId > 0 then
                                    local success <const> = TriggerServerCallback("core:diving:server:collect", Diving.zone,
                                        objectNetId)
                                    if success then
                                        if Diving.currentBlip then
                                            VFW.RemoveBlipInternal(Diving.currentBlip)
                                            Diving.currentBlip = nil
                                        end
                                        Diving.currentObject = nil
                                    else
                                        VFW.ShowNotification({
                                            type = "ROUGE",
                                            content = "Vous ne pouvez pas récupérer cet objet.",
                                        })
                                    end
                                end
                            end
                        end
                    end
                    VFW.DrawMissionText("Un objet a été repéré ! Rends-toi sur place.")
                else
                    VFW.DrawMissionText("Recherche d'objets dans les alentours ...")
                end
                Wait(0)
            end
        end)

        VFW.ShowNotification({
            type = "VERT",
            content = ("Activité de plongée démarrée. Recherchez des objets sous l'eau ! (Oxygène: %i%%)."):format(math
                .floor(startPercent)),
        })
    else
        VFW.ShowNotification({
            type = "VERT",
            content = ("Masque équipé (Oxygène: %i%%)."):format(math.floor(startPercent)),
        })
    end
end

function Diving.stop()
    if not Diving.isDiving then return end

    local ped <const> = PlayerPedId()

    -- 1. Sauvegarde de l'oxygène
    local currentPercent = math.floor((Diving.maskRemaining / maxMaskDuration) * 100)
    if currentPercent < 0 then currentPercent = 0 end
    if currentPercent > 100 then currentPercent = 100 end

    TriggerServerEvent("core:diving:server:updateOxygen", currentPercent)

    -- 2. Animation Retrait Masque
    if not IsEntityDead(ped) then
        VFW.Streaming.RequestAnimDict("missfbi4")
        TaskPlayAnim(ped, "missfbi4", "takeoff_mask", 8.0, -8.0, -1, 50, 0, false, false, false)
        Wait(800) -- Délai pour synchro l'animation avec la disparition
    end

    Diving.isDiving = false
    Diving.maskRemaining = 0

    if Diving.currentBlip then
        VFW.RemoveBlipInternal(Diving.currentBlip)
        Diving.currentBlip = nil
    end

    Diving.currentObject = nil

    if DoesEntityExist(Diving.maskEntity) then
        DeleteEntity(Diving.maskEntity)
        Diving.maskEntity = nil
    end

    if DoesEntityExist(Diving.tankEntity) then
        DeleteEntity(Diving.tankEntity)
        Diving.tankEntity = nil
    end

    TriggerServerEvent("core:diving:server:stop")

    VFW.ShowNotification({
        type = "VERT",
        content = "Vous avez arrêté la plongée.",
    })

    if not IsEntityDead(ped) then
        Wait(400) -- Fin animation
        ClearPedTasks(ped)
    end
end

function Diving.brokeMask()
    if not Diving.isDiving then return end

    local ped <const> = PlayerPedId()

    SetPedDiesInWater(ped, true)
    SetEnableScuba(ped, false)
    SetEnableScubaGearLight(ped, false)

    if Diving.currentBlip then
        VFW.RemoveBlipInternal(Diving.currentBlip)
        Diving.currentBlip = nil
    end

    Diving.currentObject = nil

    if DoesEntityExist(Diving.maskEntity) then
        DeleteEntity(Diving.maskEntity)
        Diving.maskEntity = nil
    end

    if DoesEntityExist(Diving.tankEntity) then
        DeleteEntity(Diving.tankEntity)
        Diving.tankEntity = nil
    end

    TriggerServerEvent("core:diving:server:scubaMaskBroken")

    Diving.isDiving = false
end

function Diving.equip()
    local ped <const> = PlayerPedId()

    -- Animation : Mettre le masque
    VFW.Streaming.RequestAnimDict("mp_masks@on_foot")
    TaskPlayAnim(ped, "mp_masks@on_foot", "put_on_mask", 8.0, -8.0, -1, 50, 0, false, false, false)
    Wait(600) -- Délai pour que la main arrive au visage

    local maskModel <const> = GetHashKey("p_d_scuba_mask_s")
    local tankModel <const> = GetHashKey("p_s_scuba_tank_s")
    VFW.Streaming.RequestModel(maskModel)
    VFW.Streaming.RequestModel(tankModel)

    Diving.tankEntity = CreateObject(tankModel, 1.0, 1.0, 1.0, false, false, true)
    AttachEntityToEntity(Diving.tankEntity, ped, GetPedBoneIndex(ped, 24818), -0.25, -0.25, 0.0, 180.0, 90.0, 0.0, 1, 1,
        0, 0, 2, 1)

    Diving.maskEntity = CreateObject(maskModel, 1.0, 1.0, 1.0, false, false, true)
    AttachEntityToEntity(Diving.maskEntity, ped, GetPedBoneIndex(ped, 12844), 0.0, 0.0, 0.0, 180.0, 90.0, 0.0, 1, 1, 0, 0,
        2, 1)

    SetPedDiesInWater(ped, false)
    SetEnableScuba(ped, true)
    SetEnableScubaGearLight(ped, true)

    Wait(600)
    ClearPedTasks(ped)
end

-- Callback pour vérifier si on peut équiper ou si on déséquipe
RegisterClientCallback("core:diving:client:equip", function()
    local ped <const> = PlayerPedId()
    local isInWater <const> = IsEntityInWater(ped)

    if Diving.isDiving then
        Diving.stop()
        SetPedDiesInWater(ped, true)
        SetEnableScuba(ped, false)
        SetEnableScubaGearLight(ped, false)
        return true -- Signale au serveur qu'on a déséquipé
    end

    if isInWater then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous ne pouvez pas équiper votre masque de plongée dans l'eau.",
        })
        return false -- Signale blocage
    end
    -- Retourne nil implicitement si tout est OK pour équiper
end)

-- Callback pour démarrer la plongée avec l'oxygène sauvegardé
RegisterClientCallback("core:diving:client:start", function(oxygen)
    Diving.equip()
    Diving.start(oxygen)

    if Diving.zone then
        return Diving.zone
    end
    return -1 -- Retourne -1 pour le Freeroam
end)

RegisterNetEvent("core:diving:client:deleteObject", function(netId)
    if not netId or netId == 0 then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) then return end

    -- Take control before deleting; otherwise DeleteEntity is a no-op when
    -- the local client isn't the network owner.
    local tries = 0
    while not NetworkHasControlOfEntity(entity) and tries < 20 do
        NetworkRequestControlOfEntity(entity)
        Wait(50)
        tries = tries + 1
    end

    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
end)

RegisterNetEvent("core:diving:client:new", function(netId)
    math.randomseed(GetGameTimer())
    if not Diving.isDiving then return end

    local waitTime <const> = math.random(7500, 15000)
    Wait(waitTime)

    if Diving.currentObject then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous devez ramasser l'objet actuel avant d'en chercher un nouveau.",
        })
        return
    end

    awaitObject(netId)

    local entity <const> = NetworkGetEntityFromNetworkId(netId)
    if not entity or not DoesEntityExist(entity) then return end

    Diving.currentObject = entity

    Diving.currentBlip = AddBlipForEntity(entity)
    SetBlipSprite(Diving.currentBlip, 66)
    SetBlipColour(Diving.currentBlip, 1)
    SetBlipScale(Diving.currentBlip, 0.5)
    SetBlipDisplay(Diving.currentBlip, 4)
    SetBlipAsShortRange(Diving.currentBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Objet inconnu")
    EndTextCommandSetBlipName(Diving.currentBlip)

    VFW.ShowNotification({
        type = "VERT",
        content = "Un objet a été repéré dans les alentours !",
    })
end)

CreateThread(function()
    RegisterNuiCallback("legal_activities:resell:close:diving", function(data, cb)
        VFW.Nui.Focus(false)
        FreezeEntityPosition(PlayerPedId(), false)
        cb("ok")
    end)

    RegisterNuiCallback("legal_activities:resell:sell:diving", function(data, cb)
        TriggerServerEvent("core:legal_activities:diving:resell", data.name, data.count, data.paymentType)

        cb("ok")
    end)

    local sleep = 1000
    for zone, data in pairs(Config.diving.zones) do
        VFW.CreateBlipRadius(data.position, 3000.0, 729, 32, 0.6, "Zone de plongée", 100, 32)
        if data.zone then
            data.zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then
                    Diving.zone = zone
                else
                    Diving.zone = nil
                end
            end)
        end
    end


    while true do
        sleep = 1000

        local playerPed <const> = PlayerPedId()
        local playerCoords <const> = GetEntityCoords(playerPed)

        for _, seller in pairs(Config.diving.sellers) do
            if seller.position then
                local distance <const> = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(seller.position.x, seller.position.y, seller.position.z))

                if distance < 2.5 then
                    sleep = 0
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre")

                    if VFW.Interact.JustPressed(0, 38) then
                        local itemsToSell = TriggerServerCallback("core:legal_activities:diving:getMyItems")
                        SendNUIMessage({
                            action = "legal_activities:resell:open",
                            data = {
                                type = "diving",
                                items = itemsToSell
                            }
                        })
                        VFW.Nui.Focus(true, false)
                        FreezeEntityPosition(PlayerPedId(), true)
                    end
                    break
                end
            end
        end

        Wait(sleep)
    end
end)

VFW.PlayerIsDiving = function()
    return Diving.isDiving
end
