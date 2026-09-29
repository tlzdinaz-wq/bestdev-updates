-- Ascenseurs — moitié serveur manquante : persistance + diffusion à tous les joueurs.
-- Le client sait déjà tout faire (client/staff/gestion/gestion_elevators.lua affiche/utilise,
-- client/staff/menu/builderElevators.lua crée/modifie/supprime), mais aucun listener serveur
-- n'existait pour aucun des événements réseau utilisés par les deux : les ascenseurs ne se
-- chargeaient jamais pour personne (bug : monter/descendre ne fonctionnait pas).

local DATA_FILE = 'data/elevators.json'

local function loadElevators()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if not raw then return {} end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= "table" then return {} end

    return data
end

local elevatorsData = loadElevators()

local function saveElevators()
    SaveResourceFile(GetCurrentResourceName(), DATA_FILE, json.encode(elevatorsData), -1)
end

local function canBuildElevators(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    return xPlayer ~= nil and xPlayer.hasPermission("builder_elevator")
end

-- builderElevators.lua envoie tantôt le tableau de floors nu, tantôt {floors=...} : on
-- normalise pour toujours stocker/diffuser la même forme (celle attendue par le client).
local function normalizeElevator(payload)
    if type(payload) ~= "table" then return nil end
    if type(payload.floors) == "table" then return payload end
    return { floors = payload }
end

RegisterNetEvent("core:elevator:requestData", function()
    local source = source
    TriggerClientEvent("core:player:receiveElevatorData", source, elevatorsData)
end)

RegisterNetEvent("core:player:addElevator", function(elevatorId, payload)
    local source = source
    if not canBuildElevators(source) then return end
    if type(elevatorId) ~= "string" or elevatorId == "" then return end

    local elevator = normalizeElevator(payload)
    if not elevator then return end

    elevatorsData[elevatorId] = elevator
    saveElevators()

    TriggerClientEvent("core:player:addElevator", -1, elevatorId, elevator)
end)

RegisterNetEvent("core:player:updateElevatorFloors", function(elevatorId, floors)
    local source = source
    if not canBuildElevators(source) then return end
    if type(elevatorId) ~= "string" or type(floors) ~= "table" then return end
    if not elevatorsData[elevatorId] then return end

    elevatorsData[elevatorId].floors = floors
    saveElevators()

    TriggerClientEvent("core:player:updateElevatorFloors", -1, elevatorId, floors)
end)

-- Le builder envoie "deleteElevator", mais le client qui affiche/utilise les ascenseurs
-- n'écoute que "removeElevator" : le serveur relaie sous le nom que tout le monde attend.
RegisterNetEvent("core:player:deleteElevator", function(elevatorId)
    local source = source
    if not canBuildElevators(source) then return end
    if type(elevatorId) ~= "string" then return end
    if not elevatorsData[elevatorId] then return end

    elevatorsData[elevatorId] = nil
    saveElevators()

    TriggerClientEvent("core:player:removeElevator", -1, elevatorId)
end)
