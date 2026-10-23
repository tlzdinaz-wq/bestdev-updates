-- Coffre de véhicule et boîte à gants.
--
-- Le client (client/vehicle/trunk.lua : VFW.OpenTrunk, VFW.OpenTrunkStaff, VFW.OpenGloveBox) appelle ces trois
-- callbacks pour ouvrir le coffre, le coffre en lecture staff et la boîte à gants. Ils n'avaient aucun
-- récepteur côté serveur : le client attendait une réponse qui ne venait jamais, et l'inventaire « avait du mal
-- à s'ouvrir » dans un véhicule (touche I) comme à l'arrière (touche L).
--
-- Chaque coffre est un coffre ordinaire de la table `chests`, identifié par la plaque : `veh:<PLAQUE>` pour le coffre
-- (l'inventaire affiche alors l'icône de voiture) et `glovebox:<PLAQUE>` pour la boîte à gants. Les prises et dépôts
-- passent par les callbacks génériques de 25_03_chest.lua (vfw:chest:take-item / put-item).

local Inv = VFW.Inventory

-- Les capacités de véhicule sont données en kg (vehicle_storage_config.trunk_weight, client/vehicle/vehicle_weights.lua),
-- l'inventaire compte en unités de 5 g (config/item_weights.lua) : 1 kg = 200 unités.
local UNITS_PER_KG = 200
local DEFAULT_TRUNK_KG = 60
local DEFAULT_GLOVEBOX_KG = 5
local TRUNK_SLOTS = 30
local GLOVEBOX_SLOTS = 5
local REACH = 10.0
local STAFF_REACH = 30.0

local function squash(raw)
    if type(raw) ~= "string" then return nil end
    local key = raw:gsub("%s+", ""):upper()
    if key == "" or #key > 12 then return nil end
    return key
end

local function distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Le véhicule désigné par le client : il existe, c'est bien celui de cette plaque, et le joueur est assez près.
---@return number|nil entity, string|nil key
local function resolve(source, plate, netId, reach)
    local key = squash(plate)
    local id = tonumber(netId)
    if not key or not id or id <= 0 then return nil end

    local entity = NetworkGetEntityFromNetworkId(id)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    if GetEntityType(entity) ~= 2 then return nil end
    if squash(GetVehicleNumberPlateText(entity)) ~= key then return nil end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    if distance(GetEntityCoords(ped), GetEntityCoords(entity)) > reach then return nil end

    return entity, key
end

--- Capacité du coffre d'un modèle, en kg : la config du modèle si elle existe, sinon la valeur par défaut.
local function trunkKg(model)
    local name = type(model) == "string" and model:lower():gsub("%s+", "") or nil
    if name and name ~= "" and #name <= 60 then
        local ok, row = pcall(MySQL.single.await, "SELECT trunk_weight FROM vehicle_storage_config WHERE model = ?", { name })
        local kg = ok and row and tonumber(row.trunk_weight) or nil
        if kg and kg > 0 then return kg end
    end
    return DEFAULT_TRUNK_KG
end

--- Ouvre le coffre `chestId` pour `source` avec la capacité voulue (rappliquée à chaque ouverture : un changement
--- de config ou de palier VIP se voit tout de suite) et rend ce que le client attend.
---@return string|nil chestId, table|nil items, number|nil weight, number|nil maxWeight, string|nil label
local function openChest(source, chestId, label, maxWeight, maxSlots)
    local chest = Inv.GetChest(chestId)
    if not chest then return nil end

    if chest.label ~= label or chest.maxWeight ~= maxWeight or chest.maxSlots ~= maxSlots then
        chest.label, chest.maxWeight, chest.maxSlots = label, maxWeight, maxSlots
        Inv.MarkChestDirty(chestId)
    end

    Inv.SetViewer(source, "chest", chestId)

    local items, weight = Inv.ChestPayload(chest)
    return chestId, items, weight, chest.maxWeight, chest.label
end

Inv.RegisterCallback("vfw:trunk:get", function(source, ownedVehicle, plate, netId, model, hash)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local entity, key = resolve(source, plate, netId, REACH)
    if not entity then
        Inv.Toast(source, "Ce véhicule est introuvable ou trop loin.")
        return nil
    end

    local bonus = 0
    if VIPConfig and VIPConfig.GetTrunkBonus then
        bonus = tonumber(VIPConfig.GetTrunkBonus(tonumber(xPlayer.vipTier) or 0)) or 0
    end
    local maxWeight = math.floor(trunkKg(model) * UNITS_PER_KG * (1 + bonus / 100))

    return openChest(source, "veh:" .. key, "Coffre du véhicule", maxWeight, TRUNK_SLOTS)
end)

Inv.RegisterCallback("vfw:glovebox:get", function(source, ownedVehicle, plate, netId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local entity, key = resolve(source, plate, netId, REACH)
    if not entity then
        Inv.Toast(source, "Ce véhicule est introuvable ou trop loin.")
        return nil
    end

    return openChest(source, "glovebox:" .. key, "Boîte à gants", DEFAULT_GLOVEBOX_KG * UNITS_PER_KG, GLOVEBOX_SLOTS)
end)

-- Coffre ouvert par le staff depuis le menu contextuel du véhicule (lecture seule côté client).
Inv.RegisterCallback("vfw:trunk:get-staff", function(source, plate, netId, model, hash)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not (xPlayer.hasPermission("alt_vehicle_management") or xPlayer.hasPermission("gestion")) then return nil end

    local entity, key = resolve(source, plate, netId, STAFF_REACH)
    if not entity then
        Inv.Toast(source, "Ce véhicule est introuvable ou trop loin.")
        return nil
    end

    local maxWeight = math.floor(trunkKg(model) * UNITS_PER_KG)
    return openChest(source, "veh:" .. key, "Coffre du véhicule", maxWeight, TRUNK_SLOTS)
end)
