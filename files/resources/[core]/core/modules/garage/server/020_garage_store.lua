VFW = VFW or {}
VFW.Garages = VFW.Garages or {}

local Garages = VFW.Garages

Garages.list = {}
Garages.labelOverrides = {}
Garages.loaded = false

local function decodeGarage(row)
    local access = VFW.DB.Decode(row.access, nil)
    if type(access) ~= "table" or not access.name or access.name == "" then
        access = nil
    end

    local spawnPosition = VFW.DB.Decode(row.spawnPosition, {})
    if type(spawnPosition) ~= "table" then spawnPosition = {} end

    local position = VFW.DB.Decode(row.position, {})
    if type(position) ~= "table" then position = {} end

    local deletePosition = VFW.DB.Decode(row.deletePosition, {})
    if type(deletePosition) ~= "table" then deletePosition = position end

    return {
        id = tonumber(row.id),
        name = row.name or "",
        type = row.type or "public",
        vehType = tonumber(row.vehType) or 1,
        position = position,
        spawnPosition = spawnPosition,
        deletePosition = deletePosition,
        secondaryGarage = tonumber(row.secondaryGarage) == 1,
        access = access,
    }
end

function Garages.Get(id)
    id = tonumber(id)
    if not id then return nil end
    return Garages.list[id]
end

function Garages.Serialize(garage)
    return {
        id = garage.id,
        name = garage.name,
        type = garage.type,
        vehType = garage.vehType,
        position = garage.position,
        spawnPosition = garage.spawnPosition,
        deletePosition = garage.deletePosition,
        secondaryGarage = garage.secondaryGarage,
        access = garage.access,
    }
end

function Garages.Load()
    local rows = MySQL.query.await("SELECT * FROM garages") or {}
    local list = {}
    for i = 1, #rows do
        local garage = decodeGarage(rows[i])
        if garage.id then
            list[garage.id] = garage
        end
    end
    Garages.list = list
    Garages.loaded = true
    console.init("Garages", ("%d garages chargés"):format(#rows))
    return list
end

function Garages.LoadLabelOverrides()
    local rows = MySQL.query.await("SELECT * FROM vehicle_label_overrides") or {}
    local overrides = {}
    for i = 1, #rows do
        local model = tostring(rows[i].model or ""):lower()
        if model ~= "" then
            overrides[model] = tostring(rows[i].label or "")
        end
    end
    Garages.labelOverrides = overrides
    return overrides
end

function Garages.BucketKey(garage)
    if garage.type == "public" then return "public" end
    if garage.type == "society" then return "society" end
    if garage.type == "gang" or garage.type == "faction" then return "gang" end
    return "public"
end

function Garages.BuildRetrievePayload()
    local payload = { public = {}, society = {}, gang = {} }
    for id, garage in pairs(Garages.list) do
        local key = Garages.BucketKey(garage)
        payload[key][id] = Garages.Serialize(garage)
    end
    return payload
end

function Garages.BuildGroupPayload(groupName)
    local out = {}
    if not groupName or groupName == "" then return out end
    for id, garage in pairs(Garages.list) do
        if VFW.Vehicles.IsGroupGarage(garage) and garage.access and garage.access.name == groupName then
            out[id] = Garages.Serialize(garage)
        end
    end
    return out
end

function Garages.Broadcast(event, ...)
    TriggerClientEvent(event, -1, ...)
end

function Garages.GetGroupMembers(garage)
    local out = {}
    if not VFW.Vehicles.IsGroupGarage(garage) then return nil end

    local groupType, groupName = VFW.Vehicles.GarageGroup(garage)
    if not groupType then return out end

    for _, xPlayer in pairs(VFW.Players) do
        if groupType == "society" then
            local jobName = VFW.Vehicles.GetJob(xPlayer)
            if jobName == groupName then
                out[#out + 1] = xPlayer.source
            end
        else
            local factionName = VFW.Vehicles.GetFaction(xPlayer)
            if factionName ~= "" and factionName == groupName then
                out[#out + 1] = xPlayer.source
            end
        end
    end

    return out
end

function Garages.SendGarageEvent(event, id, garage)
    local members = Garages.GetGroupMembers(garage)
    if not members then
        TriggerClientEvent(event, -1, id, Garages.Serialize(garage))
        return
    end

    for i = 1, #members do
        TriggerClientEvent(event, members[i], id, Garages.Serialize(garage))
    end
end

function Garages.SendToPlayer(source)
    TriggerClientEvent("garage:retrieve:list", source, Garages.BuildRetrievePayload())
end

function Garages.Insert(data)
    local id = MySQL.insert.await([[
        INSERT INTO garages (name, type, vehType, position, spawnPosition, deletePosition, secondaryGarage, access)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.name,
        data.type,
        data.vehType,
        VFW.DB.Encode(data.position),
        VFW.DB.Encode(data.spawnPosition),
        VFW.DB.Encode(data.deletePosition),
        data.secondaryGarage and 1 or 0,
        data.access and VFW.DB.Encode(data.access) or "",
    })

    if not id then return nil end

    data.id = tonumber(id)
    Garages.list[data.id] = data
    return data.id
end

function Garages.Update(id, data)
    id = tonumber(id)
    if not id then return false end

    MySQL.update.await([[
        UPDATE garages SET name = ?, type = ?, vehType = ?, position = ?, spawnPosition = ?,
        deletePosition = ?, secondaryGarage = ?, access = ? WHERE id = ?
    ]], {
        data.name,
        data.type,
        data.vehType,
        VFW.DB.Encode(data.position),
        VFW.DB.Encode(data.spawnPosition),
        VFW.DB.Encode(data.deletePosition),
        data.secondaryGarage and 1 or 0,
        data.access and VFW.DB.Encode(data.access) or "",
        id,
    })

    data.id = id
    Garages.list[id] = data
    return true
end

function Garages.Delete(id)
    id = tonumber(id)
    if not id then return false end

    MySQL.update.await("UPDATE owned_vehicles SET garage_id = NULL WHERE garage_id = ?", { id })
    MySQL.update.await("DELETE FROM garages WHERE id = ?", { id })
    Garages.list[id] = nil
    return true
end

function Garages.Sanitize(payload, fallbackType)
    if type(payload) ~= "table" then return nil end

    local position = type(payload.position) == "table" and payload.position or nil
    if not position or tonumber(position.x) == nil then return nil end

    local spawnPosition = {}
    if type(payload.spawnPosition) == "table" then
        for i = 1, #payload.spawnPosition do
            local sp = payload.spawnPosition[i]
            if type(sp) == "table" and tonumber(sp.x) then
                spawnPosition[#spawnPosition + 1] = {
                    x = tonumber(sp.x) + 0.0,
                    y = tonumber(sp.y) + 0.0,
                    z = tonumber(sp.z) + 0.0,
                    w = tonumber(sp.w) or 0.0,
                }
            end
        end
    end
    if #spawnPosition == 0 then return nil end

    local deletePosition = type(payload.deletePosition) == "table" and payload.deletePosition or nil
    if not deletePosition or tonumber(deletePosition.x) == nil then return nil end

    local garageType = tostring(payload.type or fallbackType or "public")
    if garageType ~= "public" and garageType ~= "society" and garageType ~= "gang" and garageType ~= "faction" then
        garageType = "public"
    end

    local access = nil
    if type(payload.access) == "table" and payload.access.name and payload.access.name ~= "" then
        access = {
            name = tostring(payload.access.name),
            label = payload.access.label and tostring(payload.access.label) or tostring(payload.access.name),
            rank = tonumber(payload.access.rank) or 0,
        }
    end

    if garageType ~= "public" and not access then return nil end

    local vehType = tonumber(payload.vehType) or 1
    if vehType < 1 or vehType > 3 then vehType = 1 end

    return {
        id = tonumber(payload.id),
        name = tostring(payload.name or "Garage"):sub(1, 64),
        type = garageType,
        vehType = math.floor(vehType),
        position = {
            x = tonumber(position.x) + 0.0,
            y = tonumber(position.y) + 0.0,
            z = tonumber(position.z) + 0.0,
            w = tonumber(position.w) or 0.0,
        },
        spawnPosition = spawnPosition,
        deletePosition = {
            x = tonumber(deletePosition.x) + 0.0,
            y = tonumber(deletePosition.y) + 0.0,
            z = tonumber(deletePosition.z) + 0.0,
        },
        secondaryGarage = payload.secondaryGarage == true or tonumber(payload.secondaryGarage) == 1,
        access = access,
    }
end

function Garages.CanEdit(xPlayer, garageType)
    if not xPlayer then return false end
    if garageType == "faction" or garageType == "gang" then
        return xPlayer.hasPermission("gestion_faction") or xPlayer.hasPermission("manage_garages")
    end
    return xPlayer.hasPermission("manage_garages")
end

CreateThread(function()
    while not VFW.Ready do
        Wait(250)
    end

    Garages.Load()
    Garages.LoadLabelOverrides()
end)
