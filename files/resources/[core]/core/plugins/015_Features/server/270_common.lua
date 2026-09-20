Feat27 = Feat27 or {}

Feat27.Ready = false

local rateBuckets = {}

function Feat27.RateLimit(source, key, delay)
    local src = tonumber(source) or 0
    local bucket = rateBuckets[src]
    if not bucket then
        bucket = {}
        rateBuckets[src] = bucket
    end
    local now = GetGameTimer()
    local last = bucket[key]
    if last and (now - last) < (delay or 250) then
        return false
    end
    bucket[key] = now
    return true
end

function Feat27.ClearRate(source)
    rateBuckets[tonumber(source) or 0] = nil
end

AddEventHandler("vfw:playerDropped", function(source)
    Feat27.ClearRate(source)
end)

function Feat27.IsNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Feat27.ToNumber(value, fallback)
    local n = tonumber(value)
    if not n or n ~= n then return fallback end
    return n
end

function Feat27.IsVec(value)
    if type(value) == "vector3" or type(value) == "vector4" then return true end
    if type(value) ~= "table" then return false end
    return Feat27.IsNumber(tonumber(value.x)) and Feat27.IsNumber(tonumber(value.y)) and Feat27.IsNumber(tonumber(value.z))
end

function Feat27.Vec3(value, fallback)
    if type(value) == "vector3" then return value end
    if type(value) == "vector4" then return vector3(value.x, value.y, value.z) end
    if type(value) == "table" and value.x and value.y and value.z then
        return vector3(tonumber(value.x) + 0.0, tonumber(value.y) + 0.0, tonumber(value.z) + 0.0)
    end
    return fallback
end

function Feat27.Plain(value, fallback)
    local v = Feat27.Vec3(value)
    if not v then return fallback end
    return { x = v.x, y = v.y, z = v.z }
end

function Feat27.Dist(a, b)
    local va, vb = Feat27.Vec3(a), Feat27.Vec3(b)
    if not va or not vb then return 999999.0 end
    return #(va - vb)
end

function Feat27.PlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function Feat27.Uuid()
    if VFW and VFW.GenerateUUID then
        local ok, id = pcall(VFW.GenerateUUID)
        if ok and id then return tostring(id) end
    end
    return ("%d-%d-%d"):format(os.time(), GetGameTimer(), math.random(100000, 999999))
end

function Feat27.Notify(source, data)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification(source, data)
    end
end

function Feat27.NotifyError(source, message)
    Feat27.Notify(source, { type = "ROUGE", content = message })
end

function Feat27.NotifyOk(source, message)
    Feat27.Notify(source, { type = "VERT", content = message })
end

function Feat27.HasStaff(xPlayer, permission)
    if not xPlayer then return false end
    if xPlayer.hasPermission(permission) then return true end
    if xPlayer.hasPermission("gestion") then return true end
    return false
end

function Feat27.WaitEntity(entity)
    local tries = 0
    while not DoesEntityExist(entity) and tries < 100 do
        Wait(10)
        tries = tries + 1
    end
    return DoesEntityExist(entity)
end

function Feat27.EntityFromNet(netId)
    local id = tonumber(netId)
    if not id or id <= 0 then return nil end
    local entity = NetworkGetEntityFromNetworkId(id)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    return entity
end

function Feat27.DeleteNet(netId)
    local entity = Feat27.EntityFromNet(netId)
    if not entity then return false end
    DeleteEntity(entity)
    return true
end

function Feat27.SpawnPed(model, coords, heading)
    local hash = type(model) == "string" and joaat(model) or tonumber(model)
    local pos = Feat27.Vec3(coords)
    if not hash or not pos then return nil end
    local ped = CreatePed(4, hash, pos.x, pos.y, pos.z, tonumber(heading) or 0.0, true, true)
    if not Feat27.WaitEntity(ped) then return nil end
    SetEntityOrphanMode(ped, 2)
    return NetworkGetNetworkIdFromEntity(ped), ped
end

function Feat27.SpawnObject(model, coords, heading)
    local hash = type(model) == "string" and joaat(model) or tonumber(model)
    local pos = Feat27.Vec3(coords)
    if not hash or not pos then return nil end
    local object = CreateObject(hash, pos.x, pos.y, pos.z, true, true, false)
    if not Feat27.WaitEntity(object) then return nil end
    SetEntityHeading(object, tonumber(heading) or 0.0)
    SetEntityOrphanMode(object, 2)
    return NetworkGetNetworkIdFromEntity(object), object
end

function Feat27.SpawnVehicle(model, coords, heading, vehicleType)
    local hash = type(model) == "string" and joaat(model) or tonumber(model)
    local pos = Feat27.Vec3(coords)
    if not hash or not pos then return nil end

    local kind = vehicleType
    if not kind and VFW and VFW.GetVehicleType then
        local ok, res = pcall(VFW.GetVehicleType, hash)
        if ok and res then kind = res end
    end

    local vehicle = CreateVehicleServerSetter(hash, kind or "automobile", pos.x, pos.y, pos.z, tonumber(heading) or 0.0)
    if not Feat27.WaitEntity(vehicle) then return nil end
    SetEntityOrphanMode(vehicle, 2)
    return NetworkGetNetworkIdFromEntity(vehicle), vehicle
end

Feat27.Inv = {}

local function inventoryModule()
    local Inv = VFW and VFW.Inventory
    if Inv and Inv.GivePlayerItem and Inv.TakePlayerItem and Inv.HasItem then return Inv end
    return nil
end

function Feat27.Inv.Give(xPlayer, name, count, meta, notify)
    if not xPlayer or type(name) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end

    local Inv = inventoryModule()
    if Inv then
        return Inv.GivePlayerItem(xPlayer, name, count, meta, notify) >= count
    end
    return xPlayer.addInventoryItem(name, count, meta, notify) == true
end

function Feat27.Inv.Take(xPlayer, name, count, notify)
    if not xPlayer or type(name) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end

    local Inv = inventoryModule()
    if Inv then
        return Inv.TakePlayerItem(xPlayer, name, count, notify) >= count
    end
    return xPlayer.removeInventoryItem(name, count, nil, notify) == true
end

function Feat27.Inv.Has(xPlayer, name, count)
    if not xPlayer or type(name) ~= "string" then return false end
    local Inv = inventoryModule()
    if Inv then
        return Inv.HasItem(xPlayer, name, count or 1)
    end
    return xPlayer.haveItem(name, count or 1) == true
end

function Feat27.Inv.Count(xPlayer, name)
    if not xPlayer or type(name) ~= "string" then return 0 end
    local Inv = VFW and VFW.Inventory
    if Inv and Inv.CountByName and Inv.PlayerList then
        return Inv.CountByName(Inv.PlayerList(xPlayer), name)
    end
    local entry = xPlayer.getInventoryItem(name)
    return entry and entry.count or 0
end

function Feat27.Inv.CanCarry(xPlayer, name, count)
    if not xPlayer or type(name) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    local Inv = VFW and VFW.Inventory
    if Inv and Inv.CanCarry then
        return Inv.CanCarry(xPlayer, name, count) == true
    end
    return xPlayer.canCarryItem(name, count) == true
end

function Feat27.Inv.Entry(xPlayer, name)
    if not xPlayer or type(name) ~= "string" then return nil end
    local Inv = VFW and VFW.Inventory
    if Inv and Inv.PlayerList then
        local list = Inv.PlayerList(xPlayer)
        for i = 1, #list do
            if list[i].name == name then return list[i] end
        end
        return nil
    end
    return xPlayer.getInventoryItem(name)
end

function Feat27.Inv.Meta(xPlayer, name)
    local entry = Feat27.Inv.Entry(xPlayer, name)
    if not entry then return nil end
    if type(entry.meta) == "table" then return entry.meta end
    if type(entry.metadata) == "table" then return entry.metadata end
    return nil
end

function Feat27.Inv.SetMeta(xPlayer, name, key, value)
    local entry = Feat27.Inv.Entry(xPlayer, name)
    if not entry then return false end

    if type(entry.meta) ~= "table" then entry.meta = {} end
    entry.meta[key] = value
    entry.metadata = entry.meta

    local Inv = VFW and VFW.Inventory
    if Inv and Inv.PushPlayer then
        Inv.PushPlayer(xPlayer)
    else
        xPlayer.setPlayerData("inventory", xPlayer.inventory)
    end
    return true
end

function Feat27.Inv.Exists(name)
    if type(name) ~= "string" then return false end
    local Inv = VFW and VFW.Inventory
    if Inv and Inv.Exists then return Inv.Exists(name) end
    return VFW.Items ~= nil and VFW.Items[name] ~= nil
end

function Feat27.Inv.Label(name)
    local def = VFW and VFW.Items and VFW.Items[name]
    if def and type(def.label) == "string" and def.label ~= "" then return def.label end
    return name
end

function Feat27.Inv.Image(name)
    local def = VFW and VFW.Items and VFW.Items[name]
    if def and type(def.image) == "string" then return def.image end
    return ""
end

Feat27.Society = {}

local addonCache = {}

function Feat27.Society.LoadAddons()
    local rows = MySQL.query.await("SELECT `society`, `field`, `value` FROM society_addon_fields") or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[row.society] = out[row.society] or {}
        out[row.society][row.field] = row.value
    end
    addonCache = out
    return out
end

function Feat27.Society.GetAddonRaw(society, field)
    if not society or not field then return nil end
    local bag = addonCache[society]
    if not bag then return nil end
    return bag[field]
end

function Feat27.Society.GetAddonNumber(society, field, fallback)
    local raw = Feat27.Society.GetAddonRaw(society, field)
    local n = tonumber(raw)
    if not n then return fallback end
    return n
end

function Feat27.Society.GetAddonString(society, field, fallback)
    local raw = Feat27.Society.GetAddonRaw(society, field)
    if type(raw) ~= "string" or raw == "" then return fallback end
    return raw
end

function Feat27.Society.GetAddonTable(society, field, fallback)
    local raw = Feat27.Society.GetAddonRaw(society, field)
    if type(raw) ~= "string" or raw == "" then return fallback end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then return decoded end
    return fallback
end

function Feat27.Society.SetAddon(society, field, value)
    if type(society) ~= "string" or type(field) ~= "string" then return false end
    local stored = value
    if type(value) == "table" then stored = json.encode(value) end
    if stored ~= nil then stored = tostring(stored) end

    MySQL.query.await(
        "INSERT INTO society_addon_fields (`society`, `field`, `value`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)",
        { society, field, stored }
    )
    addonCache[society] = addonCache[society] or {}
    addonCache[society][field] = stored
    return true
end

function Feat27.Society.AddMoney(society, amount, reason)
    local value = math.floor(tonumber(amount) or 0)
    if value <= 0 or type(society) ~= "string" or society == "" then return false end
    TriggerEvent("vfw:society:addMoney", society, value, reason or "feature")
    return true
end

function Feat27.Society.GetLabel(society)
    local job = VFW and VFW.Jobs and VFW.Jobs[society]
    if job and type(job.label) == "string" and job.label ~= "" then
        return job.label
    end
    return society or ""
end

function Feat27.Society.ListByType(jobType)
    local out = {}
    if not VFW or not VFW.Jobs then return out end
    for name, job in pairs(VFW.Jobs) do
        if job.type == jobType then
            out[#out + 1] = name
        end
    end
    table.sort(out)
    return out
end

function Feat27.Society.IsType(xPlayer, jobType)
    if not xPlayer or not xPlayer.job then return false end
    if xPlayer.job.type == jobType then return true end
    local job = VFW and VFW.Jobs and VFW.Jobs[xPlayer.job.name]
    return job ~= nil and job.type == jobType
end

function Feat27.Society.IsBoss(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    return xPlayer.job.grade_is_boss == true or xPlayer.job.grade_is_boss == 1
end

Feat27.Vehicles = {}

local ownedVehicleColumns = nil

local function loadOwnedVehicleColumns()
    if ownedVehicleColumns ~= nil then return ownedVehicleColumns end
    local rows = MySQL.query.await(
        "SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'owned_vehicles'"
    ) or {}
    local set = {}
    for i = 1, #rows do
        set[tostring(rows[i].name)] = true
    end
    ownedVehicleColumns = set
    return set
end

function Feat27.Vehicles.GeneratePlate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local plate = ""
    for _ = 1, 3 do
        local i = math.random(1, #chars)
        plate = plate .. chars:sub(i, i)
    end
    plate = plate .. tostring(math.random(100, 999))
    for _ = 1, 2 do
        local i = math.random(1, #chars)
        plate = plate .. chars:sub(i, i)
    end
    return plate
end

function Feat27.Vehicles.Store(identifier, model, properties, plate, extra)
    local columns = loadOwnedVehicleColumns()
    if not next(columns) then return false, "table_missing" end

    plate = plate or Feat27.Vehicles.GeneratePlate()
    properties = properties or {}
    properties.plate = plate
    properties.model = properties.model or joaat(model)

    extra = extra or {}

    local encoded = json.encode(properties)
    local values = {
        owner = identifier,
        identifier = identifier,
        citizenid = identifier,
        plate = plate,
        vehicle = encoded,
        props = encoded,
        mods = encoded,
        vehicle_props = encoded,
        model = model,
        spawn_name = model,
        hash = joaat(model),
        type = extra.kind or "car",
        job = extra.job or "",
        garage = extra.garage or "airport",
        parking = extra.garage or "airport",
        state = 1,
        stored = 1,
        fuel = 100,
        engine = 1000.0,
        body = 1000.0,
    }

    local names, marks, params = {}, {}, {}
    for column, value in pairs(values) do
        if columns[column] then
            names[#names + 1] = ("`%s`"):format(column)
            marks[#marks + 1] = "?"
            params[#params + 1] = value
        end
    end

    if #names == 0 then return false, "columns_missing" end

    local ok = pcall(MySQL.insert.await,
        ("INSERT INTO owned_vehicles (%s) VALUES (%s)"):format(table.concat(names, ", "), table.concat(marks, ", ")),
        params
    )
    if not ok then return false, "insert_failed" end
    return true, plate
end

CreateThread(function()
    while not MySQL or not MySQL.query do Wait(100) end
    Wait(1500)
    local ok = pcall(Feat27.Society.LoadAddons)
    if not ok then
        console.warn("Feat27: impossible de charger society_addon_fields")
    end
    Feat27.Ready = true
end)
