---@meta _
---@diagnostic disable: duplicate-doc-field

-- =============================================================
-- VFW.OneSync (client) — server-side entity creation wrappers.
--
-- Required for routing-bucket "strict" lockdown: in that mode a
-- client is NOT allowed to create networked entities, the server
-- rejects them. These helpers ask the server to spawn the entity
-- (via the vfw:onesync:create* callbacks) and return the resolved
-- LOCAL handle, with control already requested, so they can be used
-- as drop-in replacements for the CreateObject / CreatePed /
-- CreateVehicle / CreatePedInsideVehicle natives.
--
-- IMPORTANT: only use these when you need a NETWORKED entity
-- (isNetwork = true). Purely local, non-networked entities
-- (isNetwork = false) are always allowed under strict lockdown and
-- should keep calling the natives directly.
--
-- Available cross-resource through exports['core']:getSharedObject().
-- =============================================================

VFW.OneSync = VFW.OneSync or {}

---@param coords vector3|table
---@return table plain {x,y,z} — safe to send over the callback wire
local function packCoords(coords)
    return { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
end

---Resolve a server network id to a local entity handle and request
---control so the caller can attach / task / delete the entity.
---@param netId number|nil
---@return number handle 0 on failure
local function resolveNetId(netId)
    if not netId then return 0 end

    local timeout = GetGameTimer() + 7000
    local entity = 0
    while GetGameTimer() < timeout do
        if NetworkDoesNetworkIdExist(netId) then
            entity = NetworkGetEntityFromNetworkId(netId)
            if entity ~= 0 and DoesEntityExist(entity) then break end
        end
        Wait(0)
    end

    if entity == 0 or not DoesEntityExist(entity) then
        return 0
    end

    NetworkRequestControlOfEntity(entity)
    local ctrlTimeout = GetGameTimer() + 1500
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < ctrlTimeout do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end

    SetEntityAsMissionEntity(entity, true, true)
    return entity
end

---Drop-in for CreateObject(model, x, y, z, true, ...): spawns a NETWORKED
---object server-side and returns the local handle (blocking).
---@param model number|string
---@param coords vector3|table
---@param heading? number
---@return number handle 0 on failure
function VFW.OneSync.CreateObject(model, coords, heading)
    if type(model) == "string" then model = joaat(model) end
    local netId = TriggerServerCallback("vfw:onesync:createObject", model, packCoords(coords), heading or 0.0)
    return resolveNetId(netId)
end

---Drop-in for CreatePed(pedType, model, x, y, z, heading, true, ...).
---@param pedType number
---@param model number|string
---@param coords vector3|table
---@param heading? number
---@return number handle 0 on failure
function VFW.OneSync.CreatePed(pedType, model, coords, heading)
    if type(model) == "string" then model = joaat(model) end
    local netId = TriggerServerCallback("vfw:onesync:createPed", pedType or 0, model, packCoords(coords), heading or 0.0)
    return resolveNetId(netId)
end

---Drop-in for CreateVehicle(model, x, y, z, heading, true, ...).
---@param model number|string
---@param coords vector3|table
---@param heading? number
---@param properties? table optional vehicle properties applied server-side
---@return number handle 0 on failure
function VFW.OneSync.CreateVehicle(model, coords, heading, properties)
    if type(model) == "string" then model = joaat(model) end
    local netId = TriggerServerCallback("vfw:onesync:createVehicle", model, packCoords(coords), heading or 0.0, properties)
    return resolveNetId(netId)
end

---Drop-in for CreateVehicle for NON-OWNED prop vehicles (e.g. lightbars):
---networked, but without the OwnedVehicle / persistence / trunk state that
---CreateVehicle applies. Use CreateVehicle for real player vehicles.
---@param model number|string
---@param coords vector3|table
---@param heading? number
---@return number handle 0 on failure
function VFW.OneSync.CreateVehicleRaw(model, coords, heading)
    if type(model) == "string" then model = joaat(model) end
    local netId = TriggerServerCallback("vfw:onesync:createVehicleRaw", model, packCoords(coords), heading or 0.0)
    return resolveNetId(netId)
end

---Drop-in for CreatePedInsideVehicle(vehicle, pedType, model, seat, true, ...).
---The vehicle MUST already be a networked entity (server-spawned).
---@param model number|string
---@param vehicle number local vehicle handle (networked)
---@param seat number
---@param pedType? number
---@return number handle 0 on failure
function VFW.OneSync.CreatePedInsideVehicle(model, vehicle, seat, pedType)
    if type(model) == "string" then model = joaat(model) end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return 0 end

    local vehicleNetId = VehToNet(vehicle)
    if not vehicleNetId or vehicleNetId == 0 then return 0 end

    local netId = TriggerServerCallback("vfw:onesync:createPedInVehicle", model, vehicleNetId, seat or -1, pedType or 0)
    return resolveNetId(netId)
end
