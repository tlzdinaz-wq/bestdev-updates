VFW = VFW or {}
VFW.Pounds = VFW.Pounds or {}

local Pounds = VFW.Pounds

Pounds.list = {}
Pounds.loaded = false

local function defaultPrice()
    return (GarageConfig and GarageConfig.PoundRestoreCost) or 500
end

Pounds.DefaultPrice = defaultPrice

local function decodePound(row)
    local position = VFW.DB.Decode(row.position, {})
    if type(position) ~= "table" then position = {} end

    local spawnPositions = VFW.DB.Decode(row.spawnPositions, {})
    if type(spawnPositions) ~= "table" then spawnPositions = {} end

    return {
        id = tonumber(row.id),
        label = row.label or "Fourriere",
        position = position,
        spawnPositions = spawnPositions,
        useMarker = tonumber(row.useMarker) == 1,
        pedModel = row.pedModel or "a_m_y_business_02",
        price = tonumber(row.price) or defaultPrice(),
        zone = (row.zone ~= nil and row.zone ~= "") and row.zone or nil,
    }
end

function Pounds.Get(id)
    id = tonumber(id)
    if not id then return nil end
    return Pounds.list[id]
end

function Pounds.Serialize(pound)
    return {
        id = pound.id,
        label = pound.label,
        position = pound.position,
        spawnPositions = pound.spawnPositions,
        useMarker = pound.useMarker,
        pedModel = pound.pedModel,
        price = pound.price,
        zone = pound.zone,
    }
end

function Pounds.BuildPayload()
    local out = {}
    for id, pound in pairs(Pounds.list) do
        out[id] = Pounds.Serialize(pound)
    end
    return out
end

function Pounds.Load()
    local rows = MySQL.query.await("SELECT * FROM pounds") or {}
    local list = {}
    for i = 1, #rows do
        local pound = decodePound(rows[i])
        if pound.id then
            list[pound.id] = pound
        end
    end
    Pounds.list = list
    Pounds.loaded = true
    console.init("Fourrieres", ("%d fourrières chargées"):format(#rows))
    return list
end

function Pounds.Sanitize(payload)
    if type(payload) ~= "table" then return nil end

    local position = type(payload.position) == "table" and payload.position or nil
    if not position or tonumber(position.x) == nil then return nil end

    local spawnPositions = {}
    if type(payload.spawnPositions) == "table" then
        for i = 1, #payload.spawnPositions do
            local sp = payload.spawnPositions[i]
            if type(sp) == "table" and tonumber(sp.x) then
                spawnPositions[#spawnPositions + 1] = {
                    x = tonumber(sp.x) + 0.0,
                    y = tonumber(sp.y) + 0.0,
                    z = tonumber(sp.z) + 0.0,
                    w = tonumber(sp.w) or 0.0,
                }
            end
        end
    end
    if #spawnPositions == 0 then return nil end

    local price = math.floor(tonumber(payload.price) or defaultPrice())
    if price < 0 then price = 0 end
    if price > 10000000 then price = 10000000 end

    local zone = nil
    if type(payload.zone) == "string" and payload.zone ~= "" then
        zone = payload.zone:sub(1, 16)
    end

    return {
        id = tonumber(payload.id),
        label = tostring(payload.label or "Fourriere"):sub(1, 64),
        position = {
            x = tonumber(position.x) + 0.0,
            y = tonumber(position.y) + 0.0,
            z = tonumber(position.z) + 0.0,
            w = tonumber(position.w) or 0.0,
        },
        spawnPositions = spawnPositions,
        useMarker = payload.useMarker == true or tonumber(payload.useMarker) == 1,
        pedModel = tostring(payload.pedModel or "a_m_y_business_02"):sub(1, 48),
        price = price,
        zone = zone,
    }
end

function Pounds.Insert(data)
    local id = MySQL.insert.await([[
        INSERT INTO pounds (label, position, spawnPositions, useMarker, pedModel, price, zone)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.label,
        VFW.DB.Encode(data.position),
        VFW.DB.Encode(data.spawnPositions),
        data.useMarker and 1 or 0,
        data.pedModel,
        data.price,
        data.zone or "",
    })

    if not id then return nil end

    data.id = tonumber(id)
    Pounds.list[data.id] = data
    return data.id
end

function Pounds.Update(id, data)
    id = tonumber(id)
    if not id then return false end

    MySQL.update.await([[
        UPDATE pounds SET label = ?, position = ?, spawnPositions = ?, useMarker = ?, pedModel = ?,
        price = ?, zone = ? WHERE id = ?
    ]], {
        data.label,
        VFW.DB.Encode(data.position),
        VFW.DB.Encode(data.spawnPositions),
        data.useMarker and 1 or 0,
        data.pedModel,
        data.price,
        data.zone or "",
        id,
    })

    data.id = id
    Pounds.list[id] = data
    return true
end

function Pounds.Delete(id)
    id = tonumber(id)
    if not id then return false end

    MySQL.update.await("UPDATE owned_vehicles SET pound_id = NULL WHERE pound_id = ?", { id })
    MySQL.update.await("DELETE FROM pounds WHERE id = ?", { id })
    Pounds.list[id] = nil
    return true
end

function Pounds.PickSpawn(pound)
    if not pound or type(pound.spawnPositions) ~= "table" then return nil end
    local first = pound.spawnPositions[1]
    if type(first) ~= "table" or not tonumber(first.x) then return nil end
    return {
        x = tonumber(first.x) + 0.0,
        y = tonumber(first.y) + 0.0,
        z = tonumber(first.z) + 0.0,
        w = tonumber(first.w) or 0.0,
    }
end

CreateThread(function()
    while not VFW.Ready do
        Wait(250)
    end

    Pounds.Load()
end)
