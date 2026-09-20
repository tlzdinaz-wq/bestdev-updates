local PS = VFW.PropertyServer

local VALID_MAX_PLACES = { [2] = true, [6] = true, [10] = true, [14] = true, [20] = true, [25] = true, [35] = true }

PS.VehicleTypeCache = PS.VehicleTypeCache or {}

function PS.IsValidMaxPlaces(value)
    local n = PS.ToInt(value)
    return n ~= nil and VALID_MAX_PLACES[n] == true
end

function PS.ResolveVehicleType(model, source)
    local hash = PS.ToInt(model)
    if not hash then return "automobile" end
    if PS.VehicleTypeCache[hash] then return PS.VehicleTypeCache[hash] end

    local ok, result = pcall(function()
        return VFW.GetVehicleType and VFW.GetVehicleType(hash, source) or nil
    end)
    local vehType = (ok and type(result) == "string" and result ~= "") and result or "automobile"
    PS.VehicleTypeCache[hash] = vehType
    return vehType
end

local function waitForEntity(entity)
    local tries = 0
    while not DoesEntityExist(entity) and tries < 60 do
        Wait(10)
        tries = tries + 1
    end
    return DoesEntityExist(entity)
end

function PS.DespawnGarageVehicle(propertyId, plate)
    local pid = PS.ToInt(propertyId)
    if not pid or not PS.GarageEntities[pid] then return end
    local entity = PS.GarageEntities[pid][plate]
    PS.GarageEntities[pid][plate] = nil
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

function PS.DespawnAllGarageVehicles(propertyId)
    local pid = PS.ToInt(propertyId)
    if not pid or not PS.GarageEntities[pid] then return end
    for plate, entity in pairs(PS.GarageEntities[pid]) do
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        PS.GarageEntities[pid][plate] = nil
    end
    PS.GarageEntities[pid] = nil
end

function PS.StoreVehicle(propertyId, plate, model, props)
    local pid = PS.ToInt(propertyId)
    if not pid then return false end

    MySQL.update.await("DELETE FROM property_garage_vehicles WHERE plate = ?", { plate })

    for otherId, cached in pairs(PS.GarageVehicles) do
        if otherId ~= pid then
            for i = #cached, 1, -1 do
                if cached[i].plate == plate then
                    table.remove(cached, i)
                end
            end
        end
    end

    local insertId = MySQL.insert.await("INSERT INTO property_garage_vehicles (property_id, plate, model, props, stored_at) VALUES (?, ?, ?, ?, ?)", {
        pid, plate, model, PS.Encode(props or {}), PS.Now(),
    })

    local list = PS.GetGarageVehicles(pid)
    list[#list + 1] = { id = insertId, plate = plate, model = model, props = props or {} }
    return true
end

function PS.RemoveStoredVehicle(propertyId, plate)
    local pid = PS.ToInt(propertyId)
    if not pid then return nil end

    local list = PS.GetGarageVehicles(pid)
    local entry
    for i = 1, #list do
        if list[i].plate == plate then
            entry = list[i]
            table.remove(list, i)
            break
        end
    end

    MySQL.update("DELETE FROM property_garage_vehicles WHERE property_id = ? AND plate = ?", { pid, plate })
    return entry
end

RegisterServerCallback("vfw:enterVehicle", function(source, propertyId, plate, makeName, props)
    local row = PS.GetProperty(propertyId)
    if not row then return false, nil end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, nil end

    if row.type ~= "Garage" then return false, nil end
    if not PS.CanUseProperty(source, row.id) then return false, nil end

    local cleanPlate = PS.SafeString(plate, 16)
    if not cleanPlate then return false, nil end
    if props ~= nil and type(props) ~= "table" then return false, nil end

    local maxPlaces = PS.ToInt(row.max_places) or 0
    local stored = PS.GetGarageVehicles(row.id)
    local alreadyStored = false
    for i = 1, #stored do
        if stored[i].plate == cleanPlate then
            alreadyStored = true
            break
        end
    end

    if not alreadyStored and #stored >= maxPlaces then
        xPlayer.showNotification({ type = "ROUGE", content = "Le garage est plein." })
        return false, nil
    end

    local ped = GetPlayerPed(source)
    local vehicle = ped and GetVehiclePedIsIn(ped, false) or 0
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false, nil end

    local model = GetEntityModel(vehicle)
    PS.ResolveVehicleType(model, source)
    DeleteEntity(vehicle)

    if not alreadyStored then
        local vehProps = props or {}
        vehProps.model = model
        PS.StoreVehicle(row.id, cleanPlate, PS.SafeString(makeName, 64) or "", vehProps)
    end

    PS.Log(row.id, "vehicle_store", xPlayer, cleanPlate)

    local payload = PS.EnterProperty(source, row)
    return true, payload
end)

RegisterServerCallback("vfw:property:spawnGarageVehicles", function(source, propertyId, spawnPoints)
    local row = PS.GetProperty(propertyId)
    if not row then return nil end
    if type(spawnPoints) ~= "table" then return nil end
    if not PS.CanUseProperty(source, row.id) then return nil end

    local bucket = PS.PrepareBucket(row.id)
    local pid = row.id

    PS.GarageEntities[pid] = PS.GarageEntities[pid] or {}

    local points = {}
    for i = 1, #spawnPoints do
        local p = PS.ReadVec4(spawnPoints[i])
        if p then
            points[#points + 1] = p
        end
    end
    if #points == 0 then return nil end

    local stored = PS.GetGarageVehicles(pid)
    local result = {}
    local used = 0

    for i = 1, #stored do
        local entry = stored[i]
        local existing = PS.GarageEntities[pid][entry.plate]
        if existing and DoesEntityExist(existing) then
            result[entry.plate] = NetworkGetNetworkIdFromEntity(existing)
            used = used + 1
        else
            used = used + 1
            local point = points[used]
            if not point then break end

            local model = PS.ToInt(entry.props and entry.props.model) or PS.ToInt(entry.model)
            if model then
                local vehType = PS.ResolveVehicleType(model, source)
                local vehicle = CreateVehicleServerSetter(model, vehType, point.x, point.y, point.z, point.w or 0.0)
                if waitForEntity(vehicle) then
                    SetEntityRoutingBucket(vehicle, bucket)
                    SetEntityOrphanMode(vehicle, 2)
                    local state = Entity(vehicle).state
                    state:set("OwnedVehicle", true, true)
                    state:set("VehicleProperties", entry.props or {}, true)
                    PS.GarageEntities[pid][entry.plate] = vehicle
                    result[entry.plate] = NetworkGetNetworkIdFromEntity(vehicle)
                else
                    used = used - 1
                end
            else
                used = used - 1
            end
        end
    end

    return result
end)

RegisterNetEvent("vfw:property:despawnGarageVehicles", function(plates, propertyId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(plates) ~= "table" then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end
    if not PS.CanUseProperty(source, row.id) then return end

    local occupants = PS.GetOccupants(row.id)
    if #occupants > 1 then return end

    for i = 1, #plates do
        if type(plates[i]) == "string" then
            PS.DespawnGarageVehicle(row.id, plates[i])
        end
    end
end)

RegisterNetEvent("vfw:property:exitGarageWithVehicle", function(propertyId, plate)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end
    if not PS.CanUseProperty(source, row.id) then return end

    local cleanPlate = PS.SafeString(plate, 16)
    if not cleanPlate then return end

    local stored = PS.GetGarageVehicles(row.id)
    local entry
    for i = 1, #stored do
        if stored[i].plate == cleanPlate then
            entry = stored[i]
            break
        end
    end
    if not entry then return end

    PS.DespawnGarageVehicle(row.id, cleanPlate)
    PS.RemoveStoredVehicle(row.id, cleanPlate)
    PS.BroadcastToProperty(row.id, source, "vfw:property:garageVehicleRemoved", cleanPlate)

    local out = PS.ReadVec4(row.vehicle_pos) or PS.PropertyPos(row)
    out.w = out.w or 0.0

    PS.ClearOccupant(source)
    SetPlayerRoutingBucket(source, 0)
    xPlayer.setCoords({ x = out.x, y = out.y, z = out.z + 0.5, heading = out.w })

    local model = PS.ToInt(entry.props and entry.props.model)
    if model then
        local vehType = PS.ResolveVehicleType(model, source)
        local vehicle = CreateVehicleServerSetter(model, vehType, out.x, out.y, out.z, out.w)
        if waitForEntity(vehicle) then
            SetEntityRoutingBucket(vehicle, 0)
            SetEntityOrphanMode(vehicle, 2)
            local state = Entity(vehicle).state
            state:set("OwnedVehicle", true, true)
            state:set("VehicleProperties", entry.props or {}, true)

            local ped = GetPlayerPed(source)
            if ped and ped ~= 0 then
                SetPedIntoVehicle(ped, vehicle, -1)
            end
        end
    end

    if not next(PS.Occupants[row.id] or {}) then
        PS.DespawnAllGarageVehicles(row.id)
    end

    PS.Log(row.id, "vehicle_exit", xPlayer, cleanPlate)
end)
