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

local UPSERT_STATE <const> = "INSERT INTO interim_player_state (`identifier`, `job`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `job` = VALUES(`job`)"

--- Prend le métier d'intérim `jobId` (en quittant l'éventuel autre métier d'intérim).
local function takeJob(source, xPlayer, jobId, label)
    local previous = InterimServer.GetInterimJob(xPlayer)
    if previous and previous ~= jobId then
        InterimServer.StopService(source, previous)
        InterimServer.ReleaseSpots(previous, source)
    end

    InterimServer.SetInterimJob(xPlayer, jobId)
    MySQL.query.await(UPSERT_STATE, { xPlayer.identifier, jobId })

    InterimServer.StartService(source, jobId)
    InterimServer.Notify(source, "VERT", ("Vous êtes désormais intérimaire : %s."):format(label or jobId))
end

--- Le centre d'intérim ne fait que présenter les offres (et marquer leur lieu sur la carte) : rien n'y enregistre le
--- métier choisi. Le métier se prend donc en commençant à travailler, au garage du métier (« Sortir le véhicule ») :
--- si le joueur n'a pas ce métier d'intérim, il le prend, à la place de celui qu'il avait. Renvoie false si le métier
--- n'existe pas ou est désactivé.
function InterimServer.EnsureJob(source, xPlayer, jobId)
    if InterimServer.HasJob(xPlayer, jobId) then return true end

    local row = MySQL.single.await("SELECT `label` FROM interim_jobs WHERE `id` = ? AND `enabled` = 1", { jobId })
    if not row then
        InterimServer.Notify(source, "ROUGE", "Ce métier d'intérim n'est pas disponible.")
        return false
    end

    takeJob(source, xPlayer, jobId, row.label)
    return true
end

RegisterNetEvent("interim:chooseJob", function(jobId)
    local source = source
    if type(jobId) ~= "string" or jobId == "" or #jobId > 40 then return end
    if not Feat27.RateLimit(source, "interim:choose", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = MySQL.single.await("SELECT `id`, `label` FROM interim_jobs WHERE `id` = ? AND `enabled` = 1", { jobId })
    if not row then
        InterimServer.Notify(source, "ROUGE", "Ce métier d'intérim n'existe pas.")
        return
    end

    takeJob(source, xPlayer, jobId, row.label)
    InterimServer.SendFirstWaypoint(source, jobId)
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    local jobId = InterimServer.GetInterimJob(xPlayer)
    if not jobId then return end

    SetTimeout(6000, function()
        if VFW.GetPlayerFromId(source) then
            InterimServer.StartService(source, jobId)
        end
    end)
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
    local nearby = {}

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) then
            local dist = #(coords - GetEntityCoords(vehicle))
            if dist < 6.0 then nearby[#nearby + 1] = { vehicle = vehicle, dist = dist } end
        end
    end

    if #nearby == 0 then
        Feat27.NotifyError(source, "Aucun véhicule à proximité.")
        return
    end

    -- Le plus proche des véhicules dont le joueur a la clé : une voiture de PNJ garée contre la
    -- sienne ne doit pas l'empêcher de verrouiller la sienne.
    table.sort(nearby, function(a, b) return a.dist < b.dist end)

    local closest
    for i = 1, #nearby do
        local plate = GetVehicleNumberPlateText(nearby[i].vehicle)
        if VFW.PlayerHasVehicleKey and VFW.PlayerHasVehicleKey(source, plate) then
            closest = nearby[i].vehicle
            break
        end
    end

    if not closest then
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
