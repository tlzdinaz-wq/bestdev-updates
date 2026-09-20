local Config = LTDDelivery.Config

local mission = {
    active = false,
    jobName = nil,
    label = nil,
    phase = nil,
    pickup = nil,
    delivery = nil,
    delivered = 0,
    vehicle = nil,
    image = nil
}

local function IsInJobVehicle(configVehicle)
    local vehicleModel = mission.vehicle or configVehicle or Config.DefaultVehicle
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return false end
    return GetEntityModel(veh) == joaat(string.lower(vehicleModel))
end

function LTDDelivery.StartMission()
    local success, data = TriggerServerCallback("fl_ltd:startMission")
    if success then
        mission.active = true
        mission.jobName = data.jobName
        mission.label = data.label
        mission.phase = "pickup"
        mission.pickup = data.pickup
        mission.delivery = data.delivery
        mission.delivered = 0
        mission.vehicle = data.vehicle
        mission.image = data.image

        TriggerEvent("fl_ltd:missionStarted", data)

        VFW.ShowNotification({
            type = "JOB",
            title = data.label or "LTD",
            subtitle = "Information Livraison",
            content = "Une nouvelle position a été transmise sur votre GPS. Rendez-vous au point indiqué pour récupérer la livraison.",
            image = data.image
        })
    else
        VFW.ShowNotification({
            type = "ROUGE",
            content = data or "Impossible de démarrer la mission."
        })
    end
end

function LTDDelivery.EndMission()
    local currentLabel = mission.label
    local currentImage = mission.image
    local success, delivered = TriggerServerCallback("fl_ltd:endMission")
    if success then
        VFW.ShowNotification({
            type = "JOB",
            title = currentLabel or "LTD",
            subtitle = "Information Livraison",
            content = "Mission terminée. " .. delivered .. (delivered > 1 and " livraisons effectuées." or " livraison effectuée."),
            image = currentImage
        })

        TriggerEvent("fl_ltd:missionEnded")
        mission.active = false
        mission.jobName = nil
        mission.label = nil
        mission.phase = nil
        mission.pickup = nil
        mission.delivery = nil
        mission.delivered = 0
        mission.vehicle = nil
        mission.image = nil
    else
        VFW.ShowNotification({
            type = "ROUGE",
            content = delivered or "Erreur lors de la fin de mission."
        })
    end
end

function LTDDelivery.GetMission()
    return mission
end

function LTDDelivery.UpdateMission(phase, pickup, delivery, delivered)
    if phase then mission.phase = phase end
    if pickup then mission.pickup = pickup end
    if delivery then mission.delivery = delivery end
    if delivered then mission.delivered = delivered end
end

function LTDDelivery.GetImage()
    return mission.image
end

function LTDDelivery.ClearMission()
    mission.active = false
    mission.jobName = nil
    mission.label = nil
    mission.phase = nil
    mission.pickup = nil
    mission.delivery = nil
    mission.delivered = 0
    mission.vehicle = nil
    mission.image = nil
end

CreateThread(function()
    Wait(1500)

    local registry = exports["core"]:getJobMenuRegistry()
    if not registry then return end

    registry.registerByType("ltd", function(menu)
        local state = TriggerServerCallback("fl_ltd:getMissionState")
        local societyConfig = TriggerServerCallback("fl_ltd:getSocietyConfig")

        if not societyConfig then
            menu.Button("Configuration manquante", "La société n'est pas configurée correctement", nil, nil, true)
            return
        end

        if not state.active then
            local inVehicle = IsInJobVehicle(societyConfig.vehicle)

            menu.Button(
                "Lancer une livraison",
                inVehicle and "Démarrer une mission de livraison" or "Vous devez être dans un véhicule de service",
                nil,
                "arrow",
                not inVehicle,
                function()
                    LTDDelivery.StartMission()
                    menu.close()
                end
            )
        else
            menu.Separator("Mission en cours")
            menu.Button("Livraisons effectuées : " .. state.delivered)

            menu.Separator()
            menu.Button(
                "Terminer la mission",
                "Arrêter les livraisons",
                nil,
                "arrow",
                false,
                function()
                    LTDDelivery.EndMission()
                    menu.refresh()
                end
            )
        end
    end, 50)
end)

AddEventHandler("fl_ltd:missionStarted", function(data)
    mission.active = true
    mission.jobName = data.jobName
    mission.label = data.label
    mission.phase = "pickup"
    mission.pickup = data.pickup
    mission.delivery = data.delivery
    mission.vehicle = data.vehicle
    mission.image = data.image
end)

AddEventHandler("fl_ltd:missionEnded", function()
    mission.active = false
    mission.jobName = nil
    mission.label = nil
    mission.phase = nil
    mission.pickup = nil
    mission.delivery = nil
    mission.delivered = 0
    mission.vehicle = nil
    mission.image = nil
end)

exports("GetMission", LTDDelivery.GetMission)
exports("UpdateMission", LTDDelivery.UpdateMission)
exports("StartMission", LTDDelivery.StartMission)
exports("EndMission", LTDDelivery.EndMission)
exports("GetImage", LTDDelivery.GetImage)
exports("ClearMission", LTDDelivery.ClearMission)

RegisterNUICallback("bossPanel:clearLTDLogs", function(data, cb)
    local deleted = TriggerServerCallback("fl_ltd:clearLogs")
    if not deleted then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous n'avez pas les permissions nécessaires."
        })
        cb(false)
        return
    end
    VFW.ShowNotification({
        type = "VERT",
        content = "Logs supprimés."
    })
    cb(true)
end)
