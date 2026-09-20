local LB = {}

function LB.Num(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

function LB.Int(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return math.floor(n)
end

function LB.Str(value, fallback)
    if type(value) == "string" then return value end
    return fallback
end

function LB.IsTable(value)
    return type(value) == "table"
end

function LB.Bool(value)
    if value == nil then return false end
    if type(value) == "boolean" then return value end
    if type(value) == "number" then return value ~= 0 end
    if type(value) == "string" then return value == "1" or value == "true" end
    return false
end

function LB.Now()
    return os.time()
end

function LB.Clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function LB.Decode(value, fallback)
    if value == nil then return fallback end
    if type(value) == "table" then return value end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

function LB.Encode(value)
    return json.encode(value)
end

function LB.Query(query, params)
    local ok, result = pcall(function()
        return MySQL.query.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return {}
    end
    return result or {}
end

function LB.Single(query, params)
    local ok, result = pcall(function()
        return MySQL.single.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function LB.Scalar(query, params)
    local ok, result = pcall(function()
        return MySQL.scalar.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function LB.Insert(query, params)
    local ok, result = pcall(function()
        return MySQL.insert.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function LB.Execute(query, params)
    local ok, result = pcall(function()
        return MySQL.update.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return 0
    end
    return result or 0
end

function LB.Player(source)
    if not VFW or not VFW.GetPlayerFromId then return nil end
    return VFW.GetPlayerFromId(source)
end

function LB.Coords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function LB.DistanceTo(source, x, y, z)
    local coords = LB.Coords(source)
    if not coords then return 9999.0 end
    local dx, dy, dz = coords.x - (x or 0.0), coords.y - (y or 0.0), coords.z - (z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function LB.Notify(source, kind, message)
    if not source or not message then return end
    TriggerClientEvent("vfw:showNotification", source, {
        type = kind or "ILLEGAL",
        message = message,
        content = message,
    })
end

function LB.ItemLabel(itemName)
    if VFW and VFW.Items and VFW.Items[itemName] and VFW.Items[itemName].label then
        return VFW.Items[itemName].label
    end
    return itemName
end

function LB.ItemExists(itemName)
    return VFW ~= nil and VFW.Items ~= nil and VFW.Items[itemName] ~= nil
end

function LB.GiveItem(xPlayer, itemName, count, notify)
    if not xPlayer or type(itemName) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end
    if not LB.ItemExists(itemName) then return false end
    if not xPlayer.canCarryItem(itemName, count) then return false end
    return xPlayer.addInventoryItem(itemName, count, nil, notify ~= false)
end

function LB.TakeItem(xPlayer, itemName, count)
    if not xPlayer or type(itemName) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end
    if not xPlayer.haveItem(itemName, count) then return false end
    return xPlayer.removeInventoryItem(itemName, count, nil, true)
end

function LB.AccountMoney(xPlayer, account)
    if not xPlayer then return 0 end
    local acc = xPlayer.getAccount(account)
    return acc and acc.money or 0
end

function LB.GiveMoney(xPlayer, account, amount, reason)
    if not xPlayer or not amount or amount <= 0 then return false end
    xPlayer.addAccountMoney(account, math.floor(amount), reason or "illegal")
    return true
end

function LB.TakeMoney(xPlayer, account, amount, reason)
    if not xPlayer or not amount or amount <= 0 then return false end
    local acc = xPlayer.getAccount(account)
    if not acc or acc.money < amount then return false end
    xPlayer.removeAccountMoney(account, math.floor(amount), reason or "illegal")
    return true
end

function LB.RegisterCallback(name, fn)
    if type(name) ~= "string" or type(fn) ~= "function" then return false end
    local ok, err = pcall(RegisterServerCallback, name, fn)
    if not ok then
        console.warn(("[illegal] impossible d'enregistrer le callback '%s': %s"):format(name, tostring(err)))
        return false
    end
    return true
end

function LB.OnReady(fn)
    if type(fn) ~= "function" then return end
    CreateThread(function()
        local attempts = 0
        while not (VFW and VFW.Ready) and attempts < 200 do
            Wait(250)
            attempts = attempts + 1
        end
        Wait(800)
        local ok, err = pcall(fn)
        if not ok then
            console.warn(("[illegal] erreur d'initialisation: %s"):format(tostring(err)))
        end
    end)
end

function LB.OnPlayerLoaded(fn)
    if type(fn) ~= "function" then return end
    AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
        local src = source
        CreateThread(function()
            Wait(2500)
            pcall(fn, src, xPlayer)
        end)
    end)
end

function LB.OnPlayerDropped(fn)
    if type(fn) ~= "function" then return end
    AddEventHandler("vfw:playerDropped", function(source, xPlayer)
        pcall(fn, source, xPlayer)
    end)
end

local GarageIllegal = {
    points = {},
}

local BUILDER_PERM = "manage_garages"
local PLATE_MAX = 8
local PLATE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local schemaReady = false

local function CanStaff(xPlayer)
    if not xPlayer then return false end
    return xPlayer.hasPermission(BUILDER_PERM)
        or xPlayer.hasPermission("gestion_faction")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin")
end

local function NameList(raw)
    local decoded = LB.Decode(raw, {})
    if type(decoded) ~= "table" then return {} end
    local out, seen = {}, {}
    local function push(value)
        local name = tostring(value or "")
        if name == "" or seen[name] then return end
        seen[name] = true
        out[#out + 1] = name
    end
    for i = 1, #decoded do
        push(decoded[i])
    end
    if #out == 0 then
        for key, value in pairs(decoded) do
            if type(value) == "string" then
                push(value)
            elseif type(key) == "string" and value then
                push(key)
            end
        end
    end
    return out
end

local function CleanNames(raw)
    local out, seen = {}, {}
    if type(raw) ~= "table" then return out end
    for i = 1, #raw do
        local name = tostring(raw[i] or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if name ~= "" and #name <= 64 and not seen[name] then
            seen[name] = true
            out[#out + 1] = name
        end
    end
    return out
end

local function PlayerJob(xPlayer)
    if not xPlayer or type(xPlayer.job) ~= "table" then return "" end
    return tostring(xPlayer.job.name or "")
end

local function PlayerFaction(xPlayer)
    if not xPlayer then return "" end
    if type(xPlayer.faction) == "table" then
        return tostring(xPlayer.faction.name or "")
    end
    if type(xPlayer.faction) == "string" then
        return xPlayer.faction
    end
    return ""
end

local function InList(list, name)
    if type(list) ~= "table" or name == nil or name == "" then return false end
    for i = 1, #list do
        if list[i] == name then return true end
    end
    return false
end

local function CanUsePoint(xPlayer, point)
    if not point then return false end
    local jobs = point.allowedJobs or {}
    local factions = point.allowedFactions or {}
    if #jobs == 0 and #factions == 0 then return true end
    return InList(jobs, PlayerJob(xPlayer)) or InList(factions, PlayerFaction(xPlayer))
end

local function ReadCoords(data)
    if not LB.IsTable(data) then
        return 0.0, 0.0, 0.0, 0.0
    end
    local c = LB.IsTable(data.coords) and data.coords or data
    return LB.Num(c.x, 0.0), LB.Num(c.y, 0.0), LB.Num(c.z, 0.0), LB.Num(c.heading or c.w, 0.0)
end

local function PlateMode(value)
    local mode = LB.Str(value, "both")
    if mode ~= "random" and mode ~= "manual" and mode ~= "both" then
        return "both"
    end
    return mode
end

local function EnsureSchema()
    if schemaReady then return end
    LB.Query("ALTER TABLE garage_illegal_points ADD COLUMN coords_h DOUBLE NOT NULL DEFAULT 0")
    LB.Query("ALTER TABLE garage_illegal_points ADD COLUMN allowed_jobs LONGTEXT NULL")
    LB.Query("ALTER TABLE garage_illegal_points ADD COLUMN allowed_factions LONGTEXT NULL")
    schemaReady = true
end

local function PointPayload(row)
    return {
        id = row.id,
        name = row.name or "Garage Illegal",
        coords = {
            x = LB.Num(row.coords_x, 0.0),
            y = LB.Num(row.coords_y, 0.0),
            z = LB.Num(row.coords_z, 0.0),
            heading = LB.Num(row.coords_h, 0.0),
        },
        isPaid = LB.Bool(row.is_paid),
        price = LB.Int(row.price, 0),
        plateMode = row.plate_mode or "both",
        allowedJobs = NameList(row.allowed_jobs),
        allowedFactions = NameList(row.allowed_factions),
    }
end

local function LoadPoints()
    EnsureSchema()
    GarageIllegal.points = {}
    local rows = LB.Query("SELECT * FROM garage_illegal_points ORDER BY id")
    for i = 1, #rows do
        GarageIllegal.points[#GarageIllegal.points + 1] = PointPayload(rows[i])
    end
end

local function FindPoint(pointId)
    for i = 1, #GarageIllegal.points do
        if GarageIllegal.points[i].id == pointId then return GarageIllegal.points[i] end
    end
    return nil
end

local function SanitizePlate(input)
    local plate = tostring(input or ""):upper()
    plate = plate:gsub("[^A-Z0-9 ]", "")
    plate = plate:gsub("^%s+", "")
    plate = plate:gsub("%s+$", "")
    if #plate > PLATE_MAX then plate = plate:sub(1, PLATE_MAX) end
    return plate
end

local function PlateTaken(plate)
    local row = LB.Single("SELECT plate FROM owned_vehicles WHERE plate = ?", { plate })
    return row ~= nil
end

local function GeneratePlate()
    for _ = 1, 40 do
        local plate = ""
        for _ = 1, PLATE_MAX do
            local index = math.random(1, #PLATE_CHARS)
            plate = plate .. PLATE_CHARS:sub(index, index)
        end
        if not PlateTaken(plate) then return plate end
    end
    return nil
end

LB.OnReady(function()
    LoadPoints()
    TriggerClientEvent("garageIllegal:client:syncAll", -1, GarageIllegal.points)
end)

LB.OnPlayerLoaded(function(source)
    TriggerClientEvent("garageIllegal:client:syncAll", source, GarageIllegal.points)
end)

LB.RegisterCallback("garageIllegal:changePlate", function(source, pointId, manualPlate, oldPlate, useRandom)
    local xPlayer = LB.Player(source)
    if not xPlayer then
        return { success = false, message = "Joueur introuvable", newPlate = "", charged = 0 }
    end

    local id = LB.Int(pointId, nil)
    local point = id and FindPoint(id) or nil
    if not point then
        return { success = false, message = "Point introuvable", newPlate = "", charged = 0 }
    end

    if not CanUsePoint(xPlayer, point) then
        return { success = false, message = "Vous n'avez pas acces a ce point", newPlate = "", charged = 0 }
    end

    if LB.DistanceTo(source, point.coords.x, point.coords.y, point.coords.z) > 10.0 then
        return { success = false, message = "Vous etes trop loin du point", newPlate = "", charged = 0 }
    end

    if type(oldPlate) ~= "string" or oldPlate == "" then
        return { success = false, message = "Cette plaque actuelle n'est pas valide", newPlate = "", charged = 0 }
    end

    local currentPlate = SanitizePlate(oldPlate)
    if currentPlate == "" then
        return { success = false, message = "Cette plaque actuelle n'est pas valide", newPlate = "", charged = 0 }
    end

    local owned = LB.Single("SELECT plate, owner FROM owned_vehicles WHERE plate = ?", { currentPlate })
    if not owned then
        owned = LB.Single("SELECT plate, owner FROM owned_vehicles WHERE TRIM(plate) = ?", { currentPlate })
    end
    if not owned then
        return { success = false, message = "Ce vehicule n'est pas immatricule", newPlate = "", charged = 0 }
    end
    if owned.owner ~= xPlayer.identifier then
        return { success = false, message = "Ce vehicule ne vous appartient pas", newPlate = "", charged = 0 }
    end

    local wantsRandom = useRandom == true
    if not wantsRandom and point.plateMode == "random" then
        wantsRandom = true
    end
    if wantsRandom and point.plateMode == "manual" then
        return { success = false, message = "Ce point ne permet que la saisie manuelle", newPlate = "", charged = 0 }
    end
    if not wantsRandom and point.plateMode == "random" then
        return { success = false, message = "Ce point ne permet que les plaques aleatoires", newPlate = "", charged = 0 }
    end

    local newPlate
    if wantsRandom then
        newPlate = GeneratePlate()
        if not newPlate then
            return { success = false, message = "Impossible de generer une plaque", newPlate = "", charged = 0 }
        end
    else
        if type(manualPlate) ~= "string" then
            return { success = false, message = "Cette plaque n'est pas valide", newPlate = "", charged = 0 }
        end
        newPlate = SanitizePlate(manualPlate)
        if newPlate == "" then
            return { success = false, message = "Cette plaque n'est pas valide", newPlate = "", charged = 0 }
        end
        if #newPlate > PLATE_MAX then
            return { success = false, message = "La plaque doit faire 8 caracteres maximum", newPlate = "", charged = 0 }
        end
        if newPlate == currentPlate then
            return { success = false, message = "Cette plaque est deja celle du vehicule", newPlate = "", charged = 0 }
        end
        if PlateTaken(newPlate) then
            return { success = false, message = "Cette plaque est deja utilisee", newPlate = "", charged = 0 }
        end
    end

    local charged = 0
    if point.isPaid and point.price > 0 then
        charged = point.price
        if not LB.TakeMoney(xPlayer, "black_money", charged, "garage-illegal") then
            return { success = false, message = "Vous n'avez pas assez d'argent sale", newPlate = "", charged = 0 }
        end
    end

    local affected = LB.Execute("UPDATE owned_vehicles SET plate = ? WHERE plate = ?", { newPlate, owned.plate })
    if not affected or affected == 0 then
        if charged > 0 then
            LB.GiveMoney(xPlayer, "black_money", charged, "garage-illegal-refund")
        end
        return { success = false, message = "Impossible de modifier la plaque", newPlate = "", charged = 0 }
    end

    LB.Execute([[
        INSERT INTO garage_illegal_log (point_id, identifier, old_plate, new_plate, charged)
        VALUES (?, ?, ?, ?, ?)
    ]], { point.id, xPlayer.identifier, owned.plate, newPlate, charged })

    return { success = true, newPlate = newPlate, charged = charged }
end)

local function JobsCatalog()
    local out = {}
    for name, def in pairs(VFW.Jobs or {}) do
        if type(name) == "string" and name ~= "" then
            out[#out + 1] = {
                name = name,
                label = (type(def) == "table" and def.label) or name,
            }
        end
    end
    table.sort(out, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return out
end

local function FactionsCatalog()
    local rows = LB.Query([[
        SELECT name, label FROM crews
        WHERE name NOT IN ('nocrew', 'nofaction')
        ORDER BY label ASC
    ]])
    local out = {}
    for i = 1, #rows do
        local name = tostring(rows[i].name or "")
        if name ~= "" then
            out[#out + 1] = { name = name, label = tostring(rows[i].label or name) }
        end
    end
    return out
end

local function HubPanel(selectedId)
    LoadPoints()
    local selected = nil
    local sid = LB.Int(selectedId, nil)
    if sid then
        selected = FindPoint(sid)
    end
    return {
        ok = true,
        points = GarageIllegal.points,
        jobs = JobsCatalog(),
        factions = FactionsCatalog(),
        selected = selected,
    }
end

local function InsertPoint(data)
    EnsureSchema()
    local x, y, z, heading = ReadCoords(data)
    local mode = PlateMode(data.plateMode)
    local jobs = CleanNames(data.allowedJobs)
    local factions = CleanNames(data.allowedFactions)
    return LB.Insert([[
        INSERT INTO garage_illegal_points
            (name, coords_x, coords_y, coords_z, coords_h, is_paid, price, plate_mode, allowed_jobs, allowed_factions)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        LB.Str(data.name, "Garage Illegal"):sub(1, 100),
        x, y, z, heading,
        LB.Bool(data.isPaid) and 1 or 0,
        math.max(0, LB.Int(data.price, 0)),
        mode,
        LB.Encode(jobs),
        LB.Encode(factions),
    })
end

local function UpdatePoint(id, data)
    EnsureSchema()
    if data.name ~= nil and type(data.name) == "string" then
        LB.Execute("UPDATE garage_illegal_points SET name = ? WHERE id = ?", { data.name:sub(1, 100), id })
    end
    if data.price ~= nil and tonumber(data.price) then
        LB.Execute("UPDATE garage_illegal_points SET price = ? WHERE id = ?", { math.max(0, LB.Int(data.price, 0)), id })
    end
    if data.isPaid ~= nil then
        LB.Execute("UPDATE garage_illegal_points SET is_paid = ? WHERE id = ?", { LB.Bool(data.isPaid) and 1 or 0, id })
    end
    if type(data.plateMode) == "string" then
        LB.Execute("UPDATE garage_illegal_points SET plate_mode = ? WHERE id = ?", { PlateMode(data.plateMode), id })
    end
    if LB.IsTable(data.coords) or data.x ~= nil then
        local x, y, z, heading = ReadCoords(data)
        LB.Execute("UPDATE garage_illegal_points SET coords_x = ?, coords_y = ?, coords_z = ?, coords_h = ? WHERE id = ?", {
            x, y, z, heading, id,
        })
    end
    if data.allowedJobs ~= nil then
        LB.Execute("UPDATE garage_illegal_points SET allowed_jobs = ? WHERE id = ?", { LB.Encode(CleanNames(data.allowedJobs)), id })
    end
    if data.allowedFactions ~= nil then
        LB.Execute("UPDATE garage_illegal_points SET allowed_factions = ? WHERE id = ?", { LB.Encode(CleanNames(data.allowedFactions)), id })
    end
end

RegisterNetEvent("garageIllegal:server:create", function(data)
    local source = source
    local xPlayer = LB.Player(source)
    if not CanStaff(xPlayer) or not LB.IsTable(data) then return end

    local id = InsertPoint(data)
    if not id then return end

    LoadPoints()
    local point = FindPoint(id)
    if point then
        TriggerClientEvent("garageIllegal:client:syncNew", -1, point)
    end
end)

RegisterNetEvent("garageIllegal:server:update", function(pointId, data)
    local source = source
    local xPlayer = LB.Player(source)
    if not CanStaff(xPlayer) then return end

    local payload = data
    local id = LB.Int(pointId, nil)
    if LB.IsTable(pointId) and not LB.IsTable(data) then
        payload = pointId
        id = LB.Int(pointId.id, nil)
    elseif not id and LB.IsTable(data) then
        id = LB.Int(data.id, nil)
    end
    if not id or not LB.IsTable(payload) then return end

    UpdatePoint(id, payload)
    LoadPoints()
    local point = FindPoint(id)
    if point then
        TriggerClientEvent("garageIllegal:client:syncUpdate", -1, point)
    end
end)

RegisterNetEvent("garageIllegal:server:delete", function(pointId)
    local source = source
    local xPlayer = LB.Player(source)
    if not CanStaff(xPlayer) then return end

    local id = LB.Int(pointId, nil)
    if LB.IsTable(pointId) then
        id = LB.Int(pointId.id, nil)
    end
    if not id then return end

    LB.Execute("DELETE FROM garage_illegal_points WHERE id = ?", { id })
    LoadPoints()
    TriggerClientEvent("garageIllegal:client:syncDelete", -1, id)
end)

RegisterNetEvent("garageIllegal:server:requestSync", function()
    local source = source
    if not LB.Player(source) then return end
    TriggerClientEvent("garageIllegal:client:syncAll", source, GarageIllegal.points)
end)

LB.RegisterCallback("garageIllegal:listAll", function(source)
    if not CanStaff(LB.Player(source)) then return {} end
    LoadPoints()
    return GarageIllegal.points
end)

LB.RegisterCallback("garageIllegal:getJobsAndFactions", function(source)
    if not CanStaff(LB.Player(source)) then return { jobs = {}, factions = {} } end
    return { jobs = JobsCatalog(), factions = FactionsCatalog() }
end)

LB.RegisterCallback("gestionIllegalGarages:hubPanel", function(source, selectedId)
    if not CanStaff(LB.Player(source)) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages illégaux." }
    end
    return HubPanel(selectedId)
end)

LB.RegisterCallback("gestionIllegalGarages:create", function(source, data)
    if not CanStaff(LB.Player(source)) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages illégaux." }
    end
    if not LB.IsTable(data) then
        return { ok = false, error = "Données invalides." }
    end
    local x, y, z = ReadCoords(data)
    if x == 0.0 and y == 0.0 and z == 0.0 then
        return { ok = false, error = "Définissez la position du point." }
    end
    if data.isPaid and LB.Int(data.price, 0) <= 0 then
        return { ok = false, error = "Ce prix n'est pas valide." }
    end
    local id = InsertPoint(data)
    if not id then
        return { ok = false, error = "Création impossible." }
    end
    LoadPoints()
    local point = FindPoint(id)
    if point then
        TriggerClientEvent("garageIllegal:client:syncNew", -1, point)
    end
    return HubPanel(id)
end)

LB.RegisterCallback("gestionIllegalGarages:update", function(source, data)
    if not CanStaff(LB.Player(source)) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages illégaux." }
    end
    if not LB.IsTable(data) then
        return { ok = false, error = "Données invalides." }
    end
    local id = LB.Int(data.id, nil)
    if not id then
        return { ok = false, error = "Point introuvable." }
    end
    if data.isPaid and LB.Int(data.price, 0) <= 0 then
        return { ok = false, error = "Ce prix n'est pas valide." }
    end
    UpdatePoint(id, data)
    LoadPoints()
    local point = FindPoint(id)
    if point then
        TriggerClientEvent("garageIllegal:client:syncUpdate", -1, point)
    end
    return HubPanel(id)
end)

LB.RegisterCallback("gestionIllegalGarages:delete", function(source, data)
    if not CanStaff(LB.Player(source)) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages illégaux." }
    end
    local id = LB.Int(type(data) == "table" and data.id or data, nil)
    if not id then
        return { ok = false, error = "Point introuvable." }
    end
    LB.Execute("DELETE FROM garage_illegal_points WHERE id = ?", { id })
    LoadPoints()
    TriggerClientEvent("garageIllegal:client:syncDelete", -1, id)
    return HubPanel()
end)
