Feat27 = Feat27 or {}

InterimServer.Services = InterimServer.Services or {}

function InterimServer.RegisterService(jobId, handlers)
    InterimServer.Services[jobId] = handlers
end

function InterimServer.StartService(source, jobId)
    local service = InterimServer.Services[jobId]
    if service and service.start then
        pcall(service.start, source)
    end
end

function InterimServer.StopService(source, jobId)
    local service = InterimServer.Services[jobId]
    if service and service.stop then
        pcall(service.stop, source)
    end
end

function InterimServer.StopAllServices(source)
    for jobId in pairs(InterimServer.Services) do
        InterimServer.StopService(source, jobId)
    end
end

RegisterNetEvent("interim:chooseJob", function(jobId)
    local source = source
    if type(jobId) ~= "string" or jobId == "" or #jobId > 40 then return end
    if not Feat27.RateLimit(source, "interim:choose", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if not InterimServer.IsUnemployed(xPlayer) then
        InterimServer.Notify(source, "ROUGE", "Vous devez être sans emploi pour prendre un métier d'intérim.")
        return
    end

    local row = MySQL.single.await("SELECT `id`, `label` FROM interim_jobs WHERE `id` = ? AND `enabled` = 1", { jobId })
    if not row then
        InterimServer.Notify(source, "ROUGE", "Ce métier d'intérim n'existe pas.")
        return
    end

    local previous = InterimServer.GetInterimJob(xPlayer)
    if previous and previous ~= jobId then
        InterimServer.StopService(source, previous)
        InterimServer.ReleaseSpots(previous, source)
    end

    InterimServer.SetInterimJob(xPlayer, jobId)

    MySQL.query.await(
        "INSERT INTO interim_player_state (`identifier`, `job`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `job` = VALUES(`job`)",
        { xPlayer.identifier, jobId }
    )

    InterimServer.StartService(source, jobId)
    InterimServer.SendFirstWaypoint(source, jobId)
    InterimServer.Notify(source, "VERT", ("Vous êtes désormais intérimaire : %s."):format(row.label or jobId))
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    local jobId = InterimServer.GetInterimJob(xPlayer)
    if not jobId then return end
    if not InterimServer.IsUnemployed(xPlayer) then return end

    SetTimeout(6000, function()
        if VFW.GetPlayerFromId(source) then
            InterimServer.StartService(source, jobId)
        end
    end)
end)

AddEventHandler("vfw:setJob", function(source, job)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local jobId = InterimServer.GetInterimJob(xPlayer)
    if not jobId then return end

    if job and job.name ~= "unemployed" then
        InterimServer.StopService(source, jobId)
        InterimServer.ReleaseAll(source)
        InterimServer.SetInterimJob(xPlayer, "")
        InterimServer.Notify(source, "JAUNE", "Votre contrat d'intérim a pris fin.")
    end
end)

AddEventHandler("vfw:playerDropped", function(source)
    InterimServer.StopAllServices(source)
end)

local vehicleOpenDebounce = {}

-- Les clés d'un véhicule sont vérifiées à un seul endroit : Staff29.PlayerHasVehicleKey
-- (alias VFW.PlayerHasVehicleKey, plugins/015_Features/server/staff/301_vehicles.lua), qui
-- couvre propriétaire, véhicule de job / faction, objet « keys », clé temporaire et double
-- de concession. Cette logique était recopiée ici, elle divergeait du menu contextuel et du
-- menu staff : on appelle désormais la source unique.

RegisterNetEvent("vfw:vehicle:open", function()
    local source = source

    local now = GetGameTimer()
    if vehicleOpenDebounce[source] and (now - vehicleOpenDebounce[source]) < 500 then return end
    vehicleOpenDebounce[source] = now

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local coords = Feat27.PlayerCoords(source)
    if not coords then return end

    local vehicles = GetAllVehicles and GetAllVehicles() or {}
    local closest, closestDist = nil, 6.0

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) then
            local dist = #(coords - GetEntityCoords(vehicle))
            if dist < closestDist then
                closest, closestDist = vehicle, dist
            end
        end
    end

    if not closest then
        Feat27.NotifyError(source, "Aucun véhicule à proximité.")
        return
    end

    local plate = GetVehicleNumberPlateText(closest)
    if not VFW.PlayerHasVehicleKey or not VFW.PlayerHasVehicleKey(source, plate) then
        Feat27.NotifyError(source, "Vous n'avez pas les clés de ce véhicule.")
        return
    end

    local newState = not (Entity(closest).state.doorsLocked == true)

    -- VFW.SetVehicleLocked pose le state bag, applique le natif serveur en garde-fou et
    -- déclenche l'animation de clé (vfw:vehicle:lockToggled).
    if VFW.SetVehicleLocked then
        VFW.SetVehicleLocked(closest, newState, source)
    else
        Entity(closest).state:set("doorsLocked", newState, true)
        TriggerEvent("vfw:vehicle:lockToggled", source, NetworkGetNetworkIdFromEntity(closest), newState)
    end

    Feat27.Notify(source, {
        type = "VERT",
        content = newState and "Véhicule verrouillé." or "Véhicule déverrouillé.",
    })
end)
