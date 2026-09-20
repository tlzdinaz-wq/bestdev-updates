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

local function plateVariants(vehicle)
    local raw = GetVehicleNumberPlateText(vehicle)
    if type(raw) ~= "string" then return nil, nil end

    local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then return nil, nil end

    local normalized = VFW.Vehicles and VFW.Vehicles.NormalizePlate
        and VFW.Vehicles.NormalizePlate(trimmed) or trimmed

    return trimmed, normalized
end

local function ownedVehicleAllows(xPlayer, row)
    if VFW.Vehicles.OwnsVehicle(xPlayer, row) then return true end

    local groupType = row.group_type
    if type(groupType) ~= "string" or groupType == "" then return false end

    local groupName = tostring(row.group_name or "")
    if groupName == "" then return false end

    if groupType == "society" then
        local jobName = VFW.Vehicles.GetJob(xPlayer)
        return jobName == groupName
    end

    local factionName = VFW.Vehicles.GetFaction(xPlayer)
    return factionName ~= "" and factionName == groupName
end

local function hasKeyItem(xPlayer, trimmed, normalized)
    local inventory = xPlayer.inventory
    if type(inventory) ~= "table" then return false end

    for i = 1, #inventory do
        local entry = inventory[i]
        if entry.name == "keys" and type(entry.meta) == "table" then
            local owned = entry.meta.plate
            if owned == trimmed or owned == normalized then return true end
        end
    end

    return false
end

local function hasTemporaryKey(source, xPlayer, trimmed, normalized)
    local state = Player(source).state
    if state["tempVehicleKey:" .. trimmed] ~= nil then return true end
    if state["tempVehicleKey:" .. normalized] ~= nil then return true end

    if Staff29 and Staff29.HasTemporaryVehicleKey then
        if Staff29.HasTemporaryVehicleKey(trimmed, xPlayer.identifier) then return true end
        if Staff29.HasTemporaryVehicleKey(normalized, xPlayer.identifier) then return true end
    end

    return false
end

local function hasKeyDuplicate(xPlayer, trimmed, normalized)
    local concess = VFW.Concess
    if not concess or not concess.HasKeyDuplicate then return false end

    if concess.HasKeyDuplicate(trimmed, xPlayer.identifier) then return true end
    return concess.HasKeyDuplicate(normalized, xPlayer.identifier) == true
end

local function canOpenVehicle(source, xPlayer, vehicle)
    if not VFW.Vehicles then return false end

    local trimmed, normalized = plateVariants(vehicle)
    if not trimmed then return true end

    local row = VFW.Vehicles.GetByPlate(normalized) or VFW.Vehicles.GetByPlate(trimmed)
    if not row then return true end

    if ownedVehicleAllows(xPlayer, row) then return true end
    if hasKeyItem(xPlayer, trimmed, normalized) then return true end
    if hasTemporaryKey(source, xPlayer, trimmed, normalized) then return true end
    if hasKeyDuplicate(xPlayer, trimmed, normalized) then return true end

    return false
end

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

    if not canOpenVehicle(source, xPlayer, closest) then
        Feat27.NotifyError(source, "Vous n'avez pas les clés de ce véhicule.")
        return
    end

    local state = Entity(closest).state
    local locked = state.doorsLocked == true
    local newState = not locked

    state:set("doorsLocked", newState, true)
    TriggerEvent("vfw:vehicle:lockToggled", source, NetworkGetNetworkIdFromEntity(closest), newState)

    Feat27.Notify(source, {
        type = "VERT",
        content = newState and "Véhicule verrouillé." or "Véhicule déverrouillé.",
    })
end)
