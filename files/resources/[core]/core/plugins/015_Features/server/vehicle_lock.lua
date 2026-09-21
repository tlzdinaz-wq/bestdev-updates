--[[
    Verrouillage des véhicules — état de référence côté serveur.

    L'état verrouillé / déverrouillé vit dans le state bag `doorsLocked` de l'entité (répliqué),
    et chaque client l'applique localement (000_framework/client/005_events.lua). Un client seul
    ne peut pas fiabiliser SetVehicleDoorsLocked : sans le contrôle réseau de l'entité, son
    changement est écrasé par le propriétaire réseau, et il est perdu quand le véhicule sort
    puis revient dans la zone de streaming.

    - vfw:vehicle:setLock (netId, locked) : joueur avec les clés (objet keys, propriétaire,
      job / faction, clé temporaire, double concession) → Staff29.PlayerHasVehicleKey.
    - VFW.SetVehicleLocked(entity, locked) : utilisable par les autres scripts serveur.
    - VFW.MarkStaffVehicle(entity) : véhicule apparu via le staff → déverrouillé et ignoré par
      l'anti-vol des véhicules PNJ (000_framework/client/004_adjustments.lua).
]]

local function trimPlate(plate)
    return (tostring(plate or "")):gsub("^%s+", ""):gsub("%s+$", "")
end

---@param entity number
---@param locked boolean
---@param source number|nil joueur à l'origine du changement (0 = système)
function VFW.SetVehicleLocked(entity, locked, source)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    locked = locked == true

    Entity(entity).state:set("doorsLocked", locked, true)
    -- natif serveur (builds OneSync récents) : garde-fou si un client applique en retard
    if SetVehicleDoorsLocked then pcall(SetVehicleDoorsLocked, entity, locked and 2 or 1) end

    TriggerEvent("vfw:vehicle:lockToggled", source or 0, NetworkGetNetworkIdFromEntity(entity), locked)
    return true
end

---@param entity number
function VFW.MarkStaffVehicle(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    local state = Entity(entity).state
    state:set("staffVehicle", true, true)
    state:set("doorsLocked", false, true)
    if SetVehicleDoorsLocked then pcall(SetVehicleDoorsLocked, entity, 1) end
end

local lastToggle = {}

RegisterNetEvent("vfw:vehicle:setLock", function(netId, locked)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local now = GetGameTimer()
    if lastToggle[source] and now - lastToggle[source] < 400 then return end
    lastToggle[source] = now

    local id = tonumber(netId)
    if not id then return end
    local entity = NetworkGetEntityFromNetworkId(id)
    if not entity or entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then return end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(entity)) > 15.0 then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous êtes trop loin du véhicule." })
        return
    end

    local plate = trimPlate(GetVehicleNumberPlateText(entity))
    local hasKey = Staff29 and Staff29.PlayerHasVehicleKey and Staff29.PlayerHasVehicleKey(source, plate)
    if not hasKey then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous n'avez pas les clés de ce véhicule." })
        return
    end

    locked = locked == true
    VFW.SetVehicleLocked(entity, locked, source)
    VFW.ShowNotification(source, { type = "VERT", content = locked and "Véhicule verrouillé." or "Véhicule déverrouillé." })
end)

-- Animation clé + clignotants côté joueur à chaque bascule (touche U, menu contextuel, staff)
AddEventHandler("vfw:vehicle:lockToggled", function(source)
    local src = tonumber(source)
    if src and src > 0 and VFW.GetPlayerFromId(src) then
        TriggerClientEvent("vfw:vehicle:anim", src)
    end
end)

AddEventHandler("playerDropped", function()
    lastToggle[source] = nil
end)
