VFW = VFW or {}
VFW.Vehicles = VFW.Vehicles or {}

local Vehicles = VFW.Vehicles

local PLATE_LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

function Vehicles.NormalizePlate(plate)
    if type(plate) ~= "string" then return nil end
    local cleaned = plate:gsub("%s+$", "")
    cleaned = cleaned:gsub("^%s+", "")
    if cleaned == "" then return nil end
    return cleaned:upper():sub(1, 12)
end

function Vehicles.PlateExists(plate)
    local row = MySQL.scalar.await("SELECT plate FROM owned_vehicles WHERE plate = ?", { plate })
    return row ~= nil
end

function Vehicles.GeneratePlate(prefix)
    local base = type(prefix) == "string" and prefix:upper():sub(1, 4) or nil

    for _ = 1, 60 do
        local plate
        if base then
            plate = ("%s%04d"):format(base, math.random(0, 9999))
        else
            local letters = ""
            for _ = 1, 3 do
                local i = math.random(1, 26)
                letters = letters .. PLATE_LETTERS:sub(i, i)
            end
            plate = ("%s %03d"):format(letters, math.random(0, 999))
        end

        plate = plate:sub(1, 8)
        if not Vehicles.PlateExists(plate) then
            return plate
        end
    end

    return ("V%07d"):format(math.random(0, 9999999))
end

function Vehicles.Decode(row)
    if not row then return nil end
    row.props = VFW.DB.Decode(row.props, {})
    if type(row.props) ~= "table" then row.props = {} end

    if (row.vehName == nil or row.vehName == "") and type(row.model) == "string" and row.model ~= "" then
        row.vehName = row.model
    end
    if (row.vehName == nil or row.vehName == "") and type(row.props.model) == "number" then
        row.vehName = tostring(row.props.model)
    end
    if row.label == nil or row.label == "" then
        row.label = row.vehName or ""
    end

    row.stored = tonumber(row.stored) or 0
    row.pounded = tonumber(row.pounded) or 0
    row.engineHealth = tonumber(row.engineHealth) or 1000.0
    row.bodyHealth = tonumber(row.bodyHealth) or 1000.0
    row.fuelLevel = tonumber(row.fuelLevel) or 100.0
    row.modTurbo = tonumber(row.modTurbo) == 1
    return row
end

function Vehicles.GetByPlate(plate)
    if type(plate) ~= "string" then return nil end
    local row = MySQL.single.await("SELECT * FROM owned_vehicles WHERE plate = ?", { plate })
    return Vehicles.Decode(row)
end

function Vehicles.Query(query, params)
    local rows = MySQL.query.await(query, params) or {}
    for i = 1, #rows do
        Vehicles.Decode(rows[i])
    end
    return rows
end

function Vehicles.GetFaction(xPlayer)
    if not xPlayer then return "", 0 end
    local faction = xPlayer.faction
    if type(faction) == "table" then
        return tostring(faction.name or ""), tonumber(faction.grade) or 0
    end
    if type(faction) == "string" then
        return faction, -1
    end
    return "", -1
end

function Vehicles.GetJob(xPlayer)
    if not xPlayer or type(xPlayer.job) ~= "table" then return "", 0 end
    return tostring(xPlayer.job.name or ""), tonumber(xPlayer.job.grade) or 0
end

function Vehicles.IsGroupGarage(garage)
    if not garage then return false end
    local t = garage.type
    return t == "society" or t == "gang" or t == "faction"
end

function Vehicles.GarageGroup(garage)
    if not Vehicles.IsGroupGarage(garage) then return nil, nil end
    if type(garage.access) ~= "table" or not garage.access.name or garage.access.name == "" then
        return nil, nil
    end
    if garage.type == "society" then
        return "society", tostring(garage.access.name)
    end
    return "faction", tostring(garage.access.name)
end

function Vehicles.HasGarageAccess(xPlayer, garage)
    if not xPlayer or not garage then return false end
    if not Vehicles.IsGroupGarage(garage) then return true end

    local groupType, groupName = Vehicles.GarageGroup(garage)
    if not groupType then return false end

    if groupType == "society" then
        local jobName = Vehicles.GetJob(xPlayer)
        return jobName == groupName
    end

    local factionName = Vehicles.GetFaction(xPlayer)
    return factionName ~= "" and factionName == groupName
end

function Vehicles.CanManageGarage(xPlayer, garage)
    if not Vehicles.HasGarageAccess(xPlayer, garage) then return false end
    if not Vehicles.IsGroupGarage(garage) then return false end

    local rank = 0
    if type(garage.access) == "table" then
        rank = tonumber(garage.access.rank) or 0
    end

    local groupType = Vehicles.GarageGroup(garage)
    if groupType == "society" then
        local _, grade = Vehicles.GetJob(xPlayer)
        return grade >= rank
    end

    local _, factionGrade = Vehicles.GetFaction(xPlayer)
    if factionGrade < 0 then return true end
    return factionGrade >= rank
end

function Vehicles.OwnsVehicle(xPlayer, row)
    if not xPlayer or not row then return false end
    if row.group_type and row.group_type ~= "" then return false end
    return row.owner == xPlayer.identifier
end

function Vehicles.CanUseVehicle(xPlayer, row, garage)
    if not xPlayer or not row then return false end

    if row.group_type and row.group_type ~= "" then
        if not garage then return false end
        local groupType, groupName = Vehicles.GarageGroup(garage)
        if not groupType then return false end
        if row.group_type ~= groupType or row.group_name ~= groupName then return false end
        return Vehicles.HasGarageAccess(xPlayer, garage)
    end

    return row.owner == xPlayer.identifier
end

function Vehicles.ExtractHealth(props, row)
    local engine = tonumber(props and props.engineHealth) or (row and row.engineHealth) or 1000.0
    local body = tonumber(props and props.bodyHealth) or (row and row.bodyHealth) or 1000.0
    local fuel = tonumber(props and props.fuelLevel) or (row and row.fuelLevel) or 100.0

    if engine < 0.0 then engine = 0.0 end
    if engine > 1000.0 then engine = 1000.0 end
    if body < 0.0 then body = 0.0 end
    if body > 1000.0 then body = 1000.0 end
    if fuel < 0.0 then fuel = 0.0 end
    if fuel > 100.0 then fuel = 100.0 end

    local turbo = false
    if type(props) == "table" and props.modTurbo then
        turbo = props.modTurbo ~= false and props.modTurbo ~= 0
    elseif row then
        turbo = row.modTurbo == true or tonumber(row.modTurbo) == 1
    end

    return engine, body, fuel, turbo
end

function Vehicles.BuildProps(row)
    local props = type(row.props) == "table" and VFW.DeepCopy and VFW.DeepCopy(row.props) or row.props
    if type(props) ~= "table" then props = {} end

    props.plate = row.plate
    if not props.model and row.vehName and row.vehName ~= "" then
        props.model = joaat(row.vehName)
    end
    props.engineHealth = row.engineHealth
    props.bodyHealth = row.bodyHealth
    props.fuelLevel = row.fuelLevel

    return props
end

function Vehicles.GetVehicleTypeFor(hash, source)
    if VFW.GetVehicleType then
        local ok, result = pcall(VFW.GetVehicleType, hash, source)
        if ok and type(result) == "string" and result ~= "" then
            return result
        end
    end
    return "automobile"
end

function Vehicles.Spawn(source, model, coords, heading, props)
    local hash = model
    if type(model) == "string" then hash = joaat(model) end
    if type(hash) ~= "number" or type(coords) ~= "table" then return nil, nil end

    local vehType = Vehicles.GetVehicleTypeFor(hash, source)
    local vehicle = CreateVehicleServerSetter(
        hash,
        vehType,
        (tonumber(coords.x) or 0.0) + 0.0,
        (tonumber(coords.y) or 0.0) + 0.0,
        (tonumber(coords.z) or 0.0) + 0.0,
        (tonumber(heading) or 0.0) + 0.0
    )

    local tries = 0
    while not DoesEntityExist(vehicle) and tries < 100 do
        Wait(10)
        tries = tries + 1
    end

    if not DoesEntityExist(vehicle) then return nil, nil end

    SetEntityOrphanMode(vehicle, 2)

    local state = Entity(vehicle).state
    state:set("OwnedVehicle", true, true)
    if type(props) == "table" and next(props) ~= nil then
        state:set("VehicleProperties", props, true)
    end

    return vehicle, NetworkGetNetworkIdFromEntity(vehicle)
end

function Vehicles.FindEntityByPlate(plate)
    if type(plate) ~= "string" then return nil end
    local target = Vehicles.NormalizePlate(plate)
    if not target then return nil end

    local all = GetAllVehicles() or {}
    for i = 1, #all do
        local veh = all[i]
        if DoesEntityExist(veh) then
            local current = Vehicles.NormalizePlate(GetVehicleNumberPlateText(veh) or "")
            if current == target then
                return veh
            end
        end
    end
end

function Vehicles.DeleteByPlate(plate)
    local veh = Vehicles.FindEntityByPlate(plate)
    if veh and DoesEntityExist(veh) then
        DeleteEntity(veh)
        return true
    end
    return false
end

function Vehicles.Distance(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return math.huge end
    local ax, ay, az = tonumber(a.x) or 0.0, tonumber(a.y) or 0.0, tonumber(a.z) or 0.0
    local bx, by, bz = tonumber(b.x) or 0.0, tonumber(b.y) or 0.0, tonumber(b.z) or 0.0
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Vehicles.PlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    return { x = c.x, y = c.y, z = c.z }
end

function Vehicles.Notify(source, type_, title, message)
    TriggerClientEvent("vfw:showNotification", source, {
        type = type_,
        title = title,
        subtitle = title,
        message = message,
        content = message,
    })
end

function Vehicles.Charge(xPlayer, method, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    local accountName = "bank"
    if method == "cash" or method == "money" or method == "especes" then
        accountName = "money"
    end

    local account = xPlayer.getAccount(accountName)
    if not account or (tonumber(account.money) or 0) < amount then
        return false, accountName
    end

    xPlayer.removeAccountMoney(accountName, amount, reason or "vehicules")
    return true, accountName
end
