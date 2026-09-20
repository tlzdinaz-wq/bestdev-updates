local PS = VFW.PropertyServer

PS.Doorlocks = {}

local function sanitizeDoorsData(doorsData)
    if type(doorsData) ~= "table" then return nil end
    local out = {}
    for i = 1, #doorsData do
        local door = doorsData[i]
        local coords = PS.ReadVec3(door and door.coords)
        local model = PS.ToInt(door and door.model)
        if coords and model then
            out[#out + 1] = {
                model = model,
                coords = coords,
                heading = PS.ToNumber(door.heading) or 0.0,
            }
        end
        if #out >= 2 then break end
    end
    if #out == 0 then return nil end
    return out
end

local function sanitizeAccess(access)
    if type(access) ~= "table" then return nil end
    local out = {}
    for i = 1, #access do
        local entry = access[i]
        local name = PS.SafeString(entry and entry.name, 60)
        local grade = PS.ToInt(entry and entry.grade) or 0
        if name then
            out[#out + 1] = { name = name, grade = grade }
        end
    end
    if #out == 0 then return nil end
    return out
end

local function doorlockRow(row)
    return {
        id = row.id,
        label = row.label,
        maxInteractDistance = row.max_interact_distance or 2.0,
        coords = PS.Decode(row.coords, { x = 0.0, y = 0.0, z = 0.0 }),
        doorsData = PS.Decode(row.doors_data, {}) or {},
        access = PS.Decode(row.access, nil),
        pincode = row.pincode,
        state = row.state or 1,
    }
end

function PS.LoadDoorlocks()
    local rows = MySQL.query.await("SELECT * FROM doorlocks") or {}
    PS.Doorlocks = {}
    for i = 1, #rows do
        local dl = doorlockRow(rows[i])
        PS.Doorlocks[dl.id] = dl
    end
end

function PS.BuildDoorlockPayload(dl)
    return {
        id = dl.id,
        label = dl.label,
        coords = dl.coords,
        maxInteractDistance = dl.maxInteractDistance,
        doorsData = VFW.DeepCopy and VFW.DeepCopy(dl.doorsData) or dl.doorsData,
        access = dl.access,
        pincode = dl.pincode,
    }
end

function PS.IsMotelDoorlock(doorlockId)
    for _, room in pairs(PS.Rooms or {}) do
        for i = 1, #room.doorlockIds do
            if room.doorlockIds[i] == doorlockId then
                return room
            end
        end
    end
    return nil
end

function PS.CreateDoorlock(label, maxInteractDistance, coords, doorsData, access, pincode)
    local cleanLabel = PS.SafeString(label, 64) or "Porte"
    local dist = PS.ToNumber(maxInteractDistance) or 2.0
    if dist <= 0 or dist > 25.0 then dist = 2.0 end

    local cleanCoords = PS.ReadVec3(coords)
    local cleanDoors = sanitizeDoorsData(doorsData)
    if not cleanDoors then return nil end
    if not cleanCoords then
        cleanCoords = cleanDoors[1].coords
    end

    local cleanAccess = sanitizeAccess(access)
    local cleanPincode = PS.ToInt(pincode)
    if cleanPincode and (cleanPincode <= 0 or cleanPincode > 999999999) then
        cleanPincode = nil
    end

    local id = MySQL.insert.await("INSERT INTO doorlocks (label, max_interact_distance, coords, doors_data, access, pincode, state) VALUES (?, ?, ?, ?, ?, ?, 1)", {
        cleanLabel, dist, PS.Encode(cleanCoords), PS.Encode(cleanDoors),
        cleanAccess and PS.Encode(cleanAccess) or nil, cleanPincode,
    })

    if not id then return nil end

    PS.Doorlocks[id] = {
        id = id,
        label = cleanLabel,
        maxInteractDistance = dist,
        coords = cleanCoords,
        doorsData = cleanDoors,
        access = cleanAccess,
        pincode = cleanPincode,
        state = 1,
    }

    TriggerClientEvent("doorlock:client:create", -1, PS.BuildDoorlockPayload(PS.Doorlocks[id]))
    return id
end

local function requireDoorlockAdmin(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission("doorlock_builder") and not xPlayer.hasPermission("doorlock") and not PS.IsStaff(xPlayer) then
        return nil
    end
    return xPlayer
end

RegisterServerCallback("doorlock:getAllDoorlock", function(source)
    local out = {}
    for _, dl in pairs(PS.Doorlocks) do
        out[#out + 1] = PS.BuildDoorlockPayload(dl)
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end)

RegisterServerCallback("doorlock:server:createCallback", function(source, label, maxInteractDistance, coords, doorsData, access, pincode)
    if not requireDoorlockAdmin(source) then return nil end
    return PS.CreateDoorlock(label, maxInteractDistance, coords, doorsData, access, pincode)
end)

RegisterNetEvent("doorlock:server:create", function(label, maxInteractDistance, coords, doorsData, access, pincode)
    local source = source
    if not requireDoorlockAdmin(source) then return end
    PS.CreateDoorlock(label, maxInteractDistance, coords, doorsData, access, pincode)
end)

RegisterNetEvent("doorlock:server:update", function(doorlockId, label, maxInteractDistance, coords, doorsData, access, pincode)
    local source = source
    if not requireDoorlockAdmin(source) then return end

    local id = PS.ToInt(doorlockId)
    if not id then return end

    local dl = PS.Doorlocks[id]
    if not dl then return end

    dl.label = PS.SafeString(label, 64) or dl.label

    local dist = PS.ToNumber(maxInteractDistance)
    if dist and dist > 0 and dist <= 25.0 then
        dl.maxInteractDistance = dist
    end

    local cleanDoors = sanitizeDoorsData(doorsData)
    if cleanDoors then dl.doorsData = cleanDoors end

    local cleanCoords = PS.ReadVec3(coords)
    if cleanCoords then dl.coords = cleanCoords end

    dl.access = sanitizeAccess(access)

    local cleanPincode = PS.ToInt(pincode)
    if cleanPincode and cleanPincode > 0 and cleanPincode <= 999999999 then
        dl.pincode = cleanPincode
    else
        dl.pincode = nil
    end

    MySQL.update.await("UPDATE doorlocks SET label = ?, max_interact_distance = ?, coords = ?, doors_data = ?, access = ?, pincode = ? WHERE id = ?", {
        dl.label, dl.maxInteractDistance, PS.Encode(dl.coords), PS.Encode(dl.doorsData),
        dl.access and PS.Encode(dl.access) or nil, dl.pincode, id,
    })

    TriggerClientEvent("doorlock:client:update", -1, PS.BuildDoorlockPayload(dl))
end)

RegisterNetEvent("doorlock:server:delete", function(doorlockId)
    local source = source
    if not requireDoorlockAdmin(source) then return end

    local id = PS.ToInt(doorlockId)
    if not id or not PS.Doorlocks[id] then return end

    PS.Doorlocks[id] = nil
    MySQL.update.await("DELETE FROM doorlocks WHERE id = ?", { id })
    TriggerClientEvent("doorlock:client:delete", -1, id)
end)

RegisterNetEvent("doorlock:server:toggleDoor", function(newState, doorlockId, access, pincode)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local state = PS.ToInt(newState)
    if state ~= 0 and state ~= 1 then return end

    local id = PS.ToInt(doorlockId)
    if not id then return end

    local dl = PS.Doorlocks[id]
    if not dl then return end

    local playerCoords = xPlayer.getCoords()
    local dx = playerCoords.x - (dl.coords.x or 0.0)
    local dy = playerCoords.y - (dl.coords.y or 0.0)
    local dz = playerCoords.z - (dl.coords.z or 0.0)
    local limit = (dl.maxInteractDistance or 2.0) + 3.0
    if (dx * dx + dy * dy + dz * dz) > (limit * limit) then return end

    if dl.access then
        local allowed = false
        local job = xPlayer.job
        for i = 1, #dl.access do
            local entry = dl.access[i]
            if job and job.name == entry.name and (job.grade or 0) >= (entry.grade or 0) then
                allowed = true
                break
            end
            if xPlayer.faction and xPlayer.faction ~= "" and xPlayer.faction == entry.name then
                allowed = true
                break
            end
        end
        if not allowed and not PS.IsStaff(xPlayer) then
            return
        end
    end

    if dl.pincode then
        local hasKey = false
        if xPlayer.inventory then
            for i = 1, #xPlayer.inventory do
                local item = xPlayer.inventory[i]
                if item.name == "key_motel" and type(item.metadata) == "table" then
                    if item.metadata.pincode == dl.pincode then
                        hasKey = true
                        break
                    end
                    if type(item.metadata.doorlockIds) == "table" then
                        for j = 1, #item.metadata.doorlockIds do
                            if item.metadata.doorlockIds[j] == id then
                                hasKey = true
                                break
                            end
                        end
                    end
                end
                if hasKey then break end
            end
        end

        if not hasKey then
            if PS.IsMotelDoorlock(id) and not PS.IsStaff(xPlayer) then
                return
            end
            if PS.ToInt(pincode) ~= dl.pincode and not PS.IsStaff(xPlayer) then
                return
            end
        end
    end

    dl.state = state
    MySQL.update("UPDATE doorlocks SET state = ? WHERE id = ?", { state, id })
    TriggerClientEvent("doorlock:client:toggleDoor", -1, id, state)
end)

RegisterNetEvent("motel:server:useKey", function(doorlockId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = PS.ToInt(doorlockId)
    if not id then return end

    local dl = PS.Doorlocks[id]
    if not dl or not dl.pincode then return end

    TriggerClientEvent("motel:client:useKey", source, id, dl.pincode)
end)

AddEventHandler("vfw:playerLoaded", function(source)
    SetTimeout(6000, function()
        if not VFW.GetPlayerFromId(source) then return end
        for id, dl in pairs(PS.Doorlocks) do
            if dl.state == 0 then
                TriggerClientEvent("doorlock:client:toggleDoor", source, id, 0)
            end
        end
    end)
end)

MySQL.ready(function()
    PS.LoadDoorlocks()
end)
