VFW = VFW or {}
VFW.Vehicles = VFW.Vehicles or {}
VFW.Rental = VFW.Rental or {}

local Rental = VFW.Rental

Rental.points = {}
Rental.catalog = { {}, {}, {} }
Rental.active = {}
Rental.loaded = false
Rental.DurationMs = 60 * 60 * 1000

local function decodePoint(row)
    local tPos = VFW.DB.Decode(row.tPos, {})
    if type(tPos) ~= "table" then tPos = {} end

    local tVehiclePos = VFW.DB.Decode(row.tVehiclePos, {})
    if type(tVehiclePos) ~= "table" then tVehiclePos = {} end

    local iType = tonumber(row.iType) or 1
    if iType < 1 or iType > 3 then iType = 1 end

    return {
        iId = tonumber(row.iId),
        iType = math.floor(iType),
        sName = row.sName or "",
        tPos = tPos,
        sPedModel = row.sPedModel or "a_m_y_business_02",
        tVehiclePos = tVehiclePos,
    }
end

function Rental.Get(iId)
    iId = tonumber(iId)
    if not iId then return nil end
    return Rental.points[iId]
end

function Rental.Serialize(point)
    return {
        iId = point.iId,
        iType = point.iType,
        sName = point.sName,
        tPos = point.tPos,
        sPedModel = point.sPedModel,
        tVehiclePos = point.tVehiclePos,
    }
end

function Rental.BuildPointsPayload()
    local out = {}
    for iId, point in pairs(Rental.points) do
        out[iId] = Rental.Serialize(point)
    end
    return out
end

function Rental.BuildCatalogPayload()
    local out = { {}, {}, {} }
    for iType = 1, 3 do
        local source = Rental.catalog[iType] or {}
        for i = 1, #source do
            local vehicle = source[i]
            out[iType][#out[iType] + 1] = {
                id = vehicle.id,
                name = vehicle.name,
                label = vehicle.label,
                price = vehicle.price,
            }
        end
    end
    return out
end

function Rental.LoadPoints()
    local rows = MySQL.query.await("SELECT * FROM vehicle_rental_points") or {}
    local points = {}
    for i = 1, #rows do
        local point = decodePoint(rows[i])
        if point.iId then
            points[point.iId] = point
        end
    end
    Rental.points = points
    return points
end

function Rental.LoadCatalog()
    local rows = MySQL.query.await("SELECT * FROM vehicle_rental_catalog ORDER BY iType ASC, id ASC") or {}
    local catalog = { {}, {}, {} }
    for i = 1, #rows do
        local row = rows[i]
        local iType = tonumber(row.iType) or 1
        if iType < 1 or iType > 3 then iType = 1 end
        catalog[iType][#catalog[iType] + 1] = {
            id = tonumber(row.id),
            name = row.name,
            label = row.label,
            price = tonumber(row.price) or 0,
        }
    end
    Rental.catalog = catalog
    return catalog
end

function Rental.LoadActive()
    local rows = MySQL.query.await("SELECT * FROM vehicle_rental_active") or {}
    local active = {}
    for i = 1, #rows do
        local row = rows[i]
        active[#active + 1] = {
            id = tonumber(row.id),
            owner = row.owner,
            iType = tonumber(row.iType) or 1,
            iPointId = tonumber(row.iPointId),
            sVehicleName = row.sVehicleName,
            sLabel = row.sLabel,
            sPlate = row.sPlate,
            iPrice = tonumber(row.iPrice) or 0,
            expiresAt = row.expires_at,
        }
    end
    Rental.active = active
    return active
end

function Rental.FindActive(owner, iType)
    for i = 1, #Rental.active do
        local entry = Rental.active[i]
        if entry.owner == owner and entry.iType == iType then
            return entry, i
        end
    end
end

function Rental.RemoveActiveByIndex(index)
    local entry = Rental.active[index]
    if not entry then return end
    MySQL.update.await("DELETE FROM vehicle_rental_active WHERE id = ?", { entry.id })
    table.remove(Rental.active, index)
end

function Rental.FindCatalogVehicle(iType, name)
    local list = Rental.catalog[iType]
    if type(list) ~= "table" then return nil end
    for i = 1, #list do
        if list[i].name == name then
            return list[i]
        end
    end
end

function Rental.SanitizePoint(payload)
    if type(payload) ~= "table" then return nil end

    local tPos = type(payload.tPos) == "table" and payload.tPos or nil
    if not tPos or tonumber(tPos.x) == nil or tonumber(tPos.y) == nil or tonumber(tPos.z) == nil then return nil end

    local iType = tonumber(payload.iType) or 1
    if iType < 1 or iType > 3 then iType = 1 end

    local vehiclePos = {}
    if type(payload.tVehiclePos) == "table" then
        for i = 1, #payload.tVehiclePos do
            local vp = payload.tVehiclePos[i]
            if type(vp) == "table" and tonumber(vp.x) and tonumber(vp.y) and tonumber(vp.z) then
                vehiclePos[#vehiclePos + 1] = {
                    x = tonumber(vp.x) + 0.0,
                    y = tonumber(vp.y) + 0.0,
                    z = tonumber(vp.z) + 0.0,
                    w = tonumber(vp.w) or 0.0,
                }
            end
        end
    end
    if #vehiclePos == 0 then return nil end

    return {
        iId = tonumber(payload.iId),
        iType = math.floor(iType),
        sName = tostring(payload.sName or "Location"):sub(1, 64),
        tPos = {
            x = tonumber(tPos.x) + 0.0,
            y = tonumber(tPos.y) + 0.0,
            z = tonumber(tPos.z) + 0.0,
            w = tonumber(tPos.w) or 0.0,
        },
        sPedModel = tostring(payload.sPedModel or "a_m_y_business_02"):sub(1, 48),
        tVehiclePos = vehiclePos,
    }
end

function Rental.InsertPoint(data)
    local iId = MySQL.insert.await([[
        INSERT INTO vehicle_rental_points (iType, sName, tPos, sPedModel, tVehiclePos)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        data.iType,
        data.sName,
        VFW.DB.Encode(data.tPos),
        data.sPedModel,
        VFW.DB.Encode(data.tVehiclePos),
    })

    if not iId then return nil end

    data.iId = tonumber(iId)
    Rental.points[data.iId] = data
    return data.iId
end

function Rental.UpdatePoint(iId, data)
    iId = tonumber(iId)
    if not iId then return false end

    MySQL.update.await([[
        UPDATE vehicle_rental_points SET iType = ?, sName = ?, tPos = ?, sPedModel = ?, tVehiclePos = ?
        WHERE iId = ?
    ]], {
        data.iType,
        data.sName,
        VFW.DB.Encode(data.tPos),
        data.sPedModel,
        VFW.DB.Encode(data.tVehiclePos),
        iId,
    })

    data.iId = iId
    Rental.points[iId] = data
    return true
end

function Rental.DeletePoint(iId)
    iId = tonumber(iId)
    if not iId then return false end

    MySQL.update.await("DELETE FROM vehicle_rental_points WHERE iId = ?", { iId })
    Rental.points[iId] = nil
    return true
end

function Rental.BroadcastConfig()
    TriggerClientEvent("core:vehicleRental:UpdateConfig", -1, Rental.BuildCatalogPayload())
end

CreateThread(function()
    while not VFW.Ready do
        Wait(250)
    end

    Rental.LoadPoints()
    Rental.LoadCatalog()
    Rental.LoadActive()
    Rental.loaded = true

    local total = 0
    for _ in pairs(Rental.points) do
        total = total + 1
    end

    console.init("Location", ("%d points de location chargés"):format(total))
end)
