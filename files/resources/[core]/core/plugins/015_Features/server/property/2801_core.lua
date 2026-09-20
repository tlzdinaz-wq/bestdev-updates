VFW.PropertyServer = VFW.PropertyServer or {}

local PS = VFW.PropertyServer

PS.BucketBase = 40000
PS.Properties = {}
PS.Access = {}
PS.Occupants = {}
PS.PlayerProperty = {}
PS.GarageEntities = {}
PS.GarageVehicles = {}
PS.ManageCache = {}
PS.PreparedBuckets = {}
PS.Ready = false

local CATEGORY_TO_TYPE = {
    ["Appartement"] = "Habitation",
    ["Garage"] = "Garage",
    ["Entrepot"] = "Stockage",
}

local TYPE_TO_CATEGORY = {
    ["Habitation"] = "Appartement",
    ["Habitations"] = "Appartement",
    ["Appartement"] = "Appartement",
    ["Garage"] = "Garage",
    ["Stockage"] = "Entrepot",
    ["Entrepot"] = "Entrepot",
}

local ACCESS_MODES = {
    ["ouvert"] = true,
    ["sonnette"] = true,
    ["fermer"] = true,
}

local BOSS_GRADE = 98

function PS.Now()
    return os.time()
end

function PS.FormatDate(unix)
    if type(unix) ~= "number" or unix <= 0 then return "" end
    return os.date("%d/%m/%Y", unix)
end

function PS.FormatDateTime(unix)
    if type(unix) ~= "number" or unix <= 0 then return "" end
    return os.date("%d/%m/%Y %H:%M", unix)
end

function PS.Decode(value, fallback)
    return VFW.DB.Decode(value, fallback)
end

function PS.Encode(value)
    return VFW.DB.Encode(value)
end

function PS.NormalizeCategory(value)
    if type(value) ~= "string" then return nil end
    return TYPE_TO_CATEGORY[value]
end

function PS.CategoryToType(category)
    return CATEGORY_TO_TYPE[category or ""] or "Habitation"
end

function PS.NormalizeType(value)
    local category = PS.NormalizeCategory(value)
    if not category then return "Habitation" end
    return CATEGORY_TO_TYPE[category]
end

function PS.IsAccessMode(value)
    return type(value) == "string" and ACCESS_MODES[value] == true
end

function PS.ToNumber(value)
    local n = tonumber(value)
    if not n then return nil end
    if n ~= n then return nil end
    return n
end

function PS.ToInt(value)
    local n = PS.ToNumber(value)
    if not n then return nil end
    return math.floor(n)
end

function PS.SafeString(value, maxLen)
    if type(value) ~= "string" then return nil end
    local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then return nil end
    return trimmed:sub(1, maxLen or 64)
end

function PS.IsVec3(value)
    return type(value) == "table" and PS.ToNumber(value.x) and PS.ToNumber(value.y) and PS.ToNumber(value.z)
end

function PS.ReadVec3(value)
    if not PS.IsVec3(value) then return nil end
    return { x = PS.ToNumber(value.x), y = PS.ToNumber(value.y), z = PS.ToNumber(value.z) }
end

function PS.ReadVec4(value)
    local v = PS.ReadVec3(value)
    if not v then return nil end
    v.w = PS.ToNumber(value.w) or PS.ToNumber(value.h) or PS.ToNumber(value.heading) or 0.0
    return v
end

function PS.MakeOwner(kind, value)
    return ("%s:%s"):format(kind, tostring(value))
end

function PS.ParseOwner(owner)
    if type(owner) ~= "string" then return "citizen", "" end
    local sep = owner:find(":", 1, true)
    if not sep then return "citizen", owner end
    return owner:sub(1, sep - 1), owner:sub(sep + 1)
end

function PS.GetProperty(id)
    local pid = PS.ToInt(id)
    if not pid then return nil end
    return PS.Properties[pid]
end

function PS.GetPropertyConfig(row)
    if not row or not Property then return nil end
    for _, group in pairs(Property) do
        if type(group) == "table" and type(group.data) == "table" then
            for i = 1, #group.data do
                if group.data[i].name == row.property_name then
                    return group.data[i]
                end
            end
        end
    end
    return nil
end

function PS.Bucket(id)
    return PS.BucketBase + (PS.ToInt(id) or 0)
end

function PS.PrepareBucket(id)
    local bucket = PS.Bucket(id)
    if PS.PreparedBuckets[bucket] then return bucket end
    PS.PreparedBuckets[bucket] = true
    SetRoutingBucketPopulationEnabled(bucket, false)
    SetRoutingBucketEntityLockdownMode(bucket, "relaxed")
    return bucket
end

function PS.SetOccupant(source, id)
    PS.ClearOccupant(source)
    local pid = PS.ToInt(id)
    if not pid then return end
    PS.Occupants[pid] = PS.Occupants[pid] or {}
    PS.Occupants[pid][source] = true
    PS.PlayerProperty[source] = pid
end

function PS.ClearOccupant(source)
    local previous = PS.PlayerProperty[source]
    if previous and PS.Occupants[previous] then
        PS.Occupants[previous][source] = nil
        if not next(PS.Occupants[previous]) then
            PS.Occupants[previous] = nil
        end
    end
    PS.PlayerProperty[source] = nil
end

function PS.GetOccupants(id)
    local pid = PS.ToInt(id)
    if not pid or not PS.Occupants[pid] then return {} end
    local out = {}
    for src in pairs(PS.Occupants[pid]) do
        out[#out + 1] = src
    end
    return out
end

function PS.BroadcastToProperty(id, exceptSource, event, ...)
    local occupants = PS.GetOccupants(id)
    for i = 1, #occupants do
        if occupants[i] ~= exceptSource then
            TriggerClientEvent(event, occupants[i], ...)
        end
    end
end

function PS.GetCharacterName(identifier)
    if type(identifier) ~= "string" or identifier == "" then return nil end
    local online = VFW.GetPlayerFromIdentifier(identifier)
    if online then return online.name end
    local row = MySQL.single.await("SELECT firstname, lastname FROM characters WHERE identifier = ?", { identifier })
    if not row then return nil end
    return ("%s %s"):format(row.firstname or "", row.lastname or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function PS.GetCharacterFace(identifier)
    if type(identifier) ~= "string" or identifier == "" then return "" end
    local online = VFW.GetPlayerFromIdentifier(identifier)
    if online then return online.mugshot or "" end
    local row = MySQL.single.await("SELECT mugshot FROM characters WHERE identifier = ?", { identifier })
    return row and row.mugshot or ""
end

function PS.GetJobLabel(name)
    local job = VFW.Jobs and VFW.Jobs[name]
    if type(job) == "table" then
        return job.label or name
    end
    return name
end

function PS.OwnerDisplay(row)
    if not row then return "Inconnu" end
    local kind, value = PS.ParseOwner(row.owner)
    if kind == "job" then
        return PS.GetJobLabel(value)
    elseif kind == "crew" then
        return value
    end
    return PS.GetCharacterName(value) or "Inconnu"
end

function PS.LoadAccess(propertyId)
    local pid = PS.ToInt(propertyId)
    if not pid then return {} end
    local rows = MySQL.query.await("SELECT * FROM property_access WHERE property_id = ? ORDER BY id", { pid }) or {}
    local list = {}
    for i = 1, #rows do
        list[#list + 1] = {
            id = rows[i].id,
            identifier = rows[i].identifier,
            hide = rows[i].hide_identity == 1,
        }
    end
    PS.Access[pid] = list
    return list
end

function PS.GetAccess(propertyId)
    local pid = PS.ToInt(propertyId)
    if not pid then return {} end
    if not PS.Access[pid] then
        return PS.LoadAccess(pid)
    end
    return PS.Access[pid]
end

function PS.HasKey(xPlayer, row)
    if not xPlayer or not row then return false end
    local list = PS.GetAccess(row.id)
    for i = 1, #list do
        if list[i].identifier == xPlayer.identifier then
            return true
        end
    end
    return false
end

function PS.IsOwner(xPlayer, row)
    if not xPlayer or not row then return false end
    local kind, value = PS.ParseOwner(row.owner)
    if kind == "job" then
        return xPlayer.job and xPlayer.job.name == value
    elseif kind == "crew" then
        return xPlayer.faction ~= nil and xPlayer.faction ~= "" and xPlayer.faction == value
    end
    return xPlayer.identifier == value
end

function PS.IsStaff(xPlayer)
    if not xPlayer then return false end
    return xPlayer.hasPermission("manage_property") or xPlayer.hasPermission("staff_menu")
end

function PS.CanManage(source, id)
    local xPlayer = VFW.GetPlayerFromId(source)
    local row = PS.GetProperty(id)
    if not xPlayer or not row then return false end
    if PS.IsOwner(xPlayer, row) then return true end
    if PS.HasKey(xPlayer, row) then return true end
    if PS.IsStaff(xPlayer) then return true end
    return false
end

function PS.CanManageCached(source, id)
    local pid = PS.ToInt(id)
    if not pid then return false end
    local key = ("%d:%d"):format(source, pid)
    local entry = PS.ManageCache[key]
    local now = GetGameTimer()
    if entry and (now - entry.at) < 8000 then
        return entry.value
    end
    local value = PS.CanManage(source, pid)
    PS.ManageCache[key] = { at = now, value = value }
    return value
end

function PS.InvalidateManageCache(id)
    local pid = PS.ToInt(id)
    if not pid then
        PS.ManageCache = {}
        return
    end
    local suffix = (":%d"):format(pid)
    for key in pairs(PS.ManageCache) do
        if key:sub(-#suffix) == suffix then
            PS.ManageCache[key] = nil
        end
    end
end

function PS.CanUseProperty(source, id)
    local pid = PS.ToInt(id)
    if not pid then return false end
    if PS.PlayerProperty[source] == pid then return true end
    return PS.CanManageCached(source, pid)
end

function PS.CanAdmin(source, id)
    local xPlayer = VFW.GetPlayerFromId(source)
    local row = PS.GetProperty(id)
    if not xPlayer or not row then return false end
    if PS.IsStaff(xPlayer) then return true end
    local kind, value = PS.ParseOwner(row.owner)
    if kind == "job" then
        return xPlayer.job and xPlayer.job.name == value and (xPlayer.job.grade or 0) >= BOSS_GRADE
    elseif kind == "crew" then
        return xPlayer.faction == value
    end
    return xPlayer.identifier == value
end

function PS.GetBalance(xPlayer, accountName)
    local account = xPlayer.getAccount(accountName)
    return account and account.money or 0
end

function PS.TakeMoney(xPlayer, amount, method)
    if not xPlayer then return false end
    local total = PS.ToInt(amount) or 0
    if total <= 0 then return true end

    if method == "cash" then
        if PS.GetBalance(xPlayer, "money") < total then return false end
        xPlayer.removeAccountMoney("money", total, "property")
        return true
    end

    if method == "bank" or method == "card" then
        if PS.GetBalance(xPlayer, "bank") < total then return false end
        xPlayer.removeAccountMoney("bank", total, "property")
        return true
    end

    local bank = PS.GetBalance(xPlayer, "bank")
    local cash = PS.GetBalance(xPlayer, "money")
    if (bank + cash) < total then return false end

    local fromBank = math.min(bank, total)
    if fromBank > 0 then
        xPlayer.removeAccountMoney("bank", fromBank, "property")
    end
    local rest = total - fromBank
    if rest > 0 then
        xPlayer.removeAccountMoney("money", rest, "property")
    end
    return true
end

function PS.GiveMoney(xPlayer, amount, accountName)
    if not xPlayer then return end
    local total = PS.ToInt(amount) or 0
    if total <= 0 then return end
    xPlayer.addAccountMoney(accountName or "bank", total, "property")
end

function PS.Log(propertyId, action, xPlayer, details)
    local pid = PS.ToInt(propertyId)
    if not pid then return end
    local row = PS.Properties[pid]
    MySQL.insert("INSERT INTO property_logs (property_id, property_name, action, identifier, player_name, details, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)", {
        pid,
        row and row.name or nil,
        tostring(action):sub(1, 32),
        xPlayer and xPlayer.identifier or nil,
        xPlayer and xPlayer.name or nil,
        details and tostring(details):sub(1, 400) or nil,
        PS.Now(),
    })
end

function PS.BuildEnterTable(row)
    if not row then return nil end
    local payload = {
        name = row.property_name,
        deco = row.deco or nil,
        access = row.access,
        garageId = row.property_key,
        advancedPerm = false,
    }
    if row.type == "Garage" then
        payload.garageList = PS.GetGarageVehicles(row.id)
        payload.maxPlaces = row.max_places
        if type(payload.garageList) ~= "table" then
            payload.garageList = {}
        end
    end
    return payload
end

function PS.GetGarageVehicles(propertyId)
    local pid = PS.ToInt(propertyId)
    if not pid then return {} end
    if PS.GarageVehicles[pid] then return PS.GarageVehicles[pid] end
    local rows = MySQL.query.await("SELECT * FROM property_garage_vehicles WHERE property_id = ?", { pid }) or {}
    local list = {}
    for i = 1, #rows do
        list[#list + 1] = {
            id = rows[i].id,
            plate = rows[i].plate,
            model = rows[i].model,
            props = PS.Decode(rows[i].props, {}),
        }
    end
    PS.GarageVehicles[pid] = list
    return list
end

function PS.PropertyPos(row)
    local pos = row and row.pos
    if PS.IsVec3(pos) then
        return { x = pos.x, y = pos.y, z = pos.z, w = pos.w or 0.0 }
    end
    return { x = 0.0, y = 0.0, z = 0.0, w = 0.0 }
end

function PS.BuildPropertiesPayload()
    local payload = {}
    for id, row in pairs(PS.Properties) do
        payload[id] = {
            pos = PS.PropertyPos(row),
            type = row.type,
            vehiclePos = row.vehicle_pos,
        }
    end
    return payload
end

function PS.PushProperties(source)
    TriggerClientEvent("vfw:loadProperties", source, PS.BuildPropertiesPayload())
end

function PS.BuildBlipsPayload(xPlayer)
    local payload = {}
    if not xPlayer then return payload end
    for id, row in pairs(PS.Properties) do
        local isOwner = PS.IsOwner(xPlayer, row)
        local hasKey = isOwner or PS.HasKey(xPlayer, row)
        if hasKey then
            local kind, value = PS.ParseOwner(row.owner)
            payload[id] = {
                pos = PS.PropertyPos(row),
                type = row.type,
                name = row.name,
                isOwner = isOwner,
                ownerKind = (kind == "job" or kind == "crew") and kind or nil,
                ownerLabel = (kind == "job" and PS.GetJobLabel(value)) or (kind == "crew" and value) or nil,
            }
        end
    end
    return payload
end

function PS.PushBlips(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    TriggerClientEvent("vfw:loadPropertiesBlips", source, PS.BuildBlipsPayload(xPlayer))
end

function PS.PushBlipsForIdentifier(identifier)
    local xPlayer = VFW.GetPlayerFromIdentifier(identifier)
    if not xPlayer then return end
    PS.PushBlips(xPlayer.source)
end

function PS.RefreshAllBlips()
    for _, xPlayer in pairs(VFW.Players) do
        PS.PushBlips(xPlayer.source)
    end
end

function PS.RowFromSql(row)
    return {
        id = row.id,
        name = row.name,
        property_name = row.property_name,
        property_key = row.property_key,
        type = row.type,
        category = row.category,
        owner = row.owner,
        access = row.access,
        pos = PS.Decode(row.pos, { x = 0.0, y = 0.0, z = 0.0, w = 0.0 }),
        vehicle_pos = row.vehicle_pos and PS.Decode(row.vehicle_pos, nil) or nil,
        max_places = row.max_places,
        deco = PS.Decode(row.deco, nil),
        is_perquisitioned = row.is_perquisitioned == 1,
        contract_type = row.contract_type,
        total_price = row.total_price or 0,
        rent_price = row.rent_price or 0,
        rental_expire = row.rental_expire or 0,
        dynasty_society = row.dynasty_society,
        created_at = row.created_at or 0,
    }
end

function PS.LoadProperties()
    local rows = MySQL.query.await("SELECT * FROM properties") or {}
    PS.Properties = {}
    for i = 1, #rows do
        local row = PS.RowFromSql(rows[i])
        PS.Properties[row.id] = row
    end
    PS.Access = {}
    PS.GarageVehicles = {}

    local accessRows = MySQL.query.await("SELECT * FROM property_access ORDER BY id") or {}
    for i = 1, #accessRows do
        local pid = accessRows[i].property_id
        PS.Access[pid] = PS.Access[pid] or {}
        PS.Access[pid][#PS.Access[pid] + 1] = {
            id = accessRows[i].id,
            identifier = accessRows[i].identifier,
            hide = accessRows[i].hide_identity == 1,
        }
    end

    for id in pairs(PS.Properties) do
        PS.Access[id] = PS.Access[id] or {}
    end

    console.info(("[property] %d propriete(s) chargee(s)"):format(#rows))
end

function PS.DeleteProperty(id, reason, deletedBy)
    local pid = PS.ToInt(id)
    local row = PS.Properties[pid]
    if not row then return false end

    local chestItems = {}
    local ok, result = pcall(function()
        return MySQL.query.await("SELECT name, count, meta FROM chest_items WHERE chest_id = ?", { ("property:%d"):format(pid) })
    end)
    if ok and type(result) == "table" then
        for i = 1, #result do
            local def = VFW.Items[result[i].name]
            chestItems[#chestItems + 1] = {
                name = result[i].name,
                count = result[i].count,
                label = def and def.label or result[i].name,
                weight = def and def.weight or 0,
            }
        end
    end

    MySQL.insert("INSERT INTO properties_deleted (property_id, name, type, payload, chest_data, chest_max_weight, delete_reason, deleted_by, deleted_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", {
        pid,
        row.name,
        row.type,
        PS.Encode(row),
        PS.Encode(chestItems),
        200,
        tostring(reason or "manual"):sub(1, 64),
        deletedBy,
        PS.Now(),
    })

    for _, src in ipairs(PS.GetOccupants(pid)) do
        PS.KickOccupant(src, pid)
    end

    MySQL.update("DELETE FROM properties WHERE id = ?", { pid })
    MySQL.update("DELETE FROM property_access WHERE property_id = ?", { pid })
    MySQL.update("DELETE FROM property_garage_vehicles WHERE property_id = ?", { pid })

    PS.Properties[pid] = nil
    PS.Access[pid] = nil
    PS.GarageVehicles[pid] = nil
    PS.InvalidateManageCache(pid)

    TriggerClientEvent("vfw:deleteProperty", -1, pid)
    PS.RefreshAllBlips()
    return true
end

function PS.KickOccupant(source, propertyId)
    local row = PS.Properties[PS.ToInt(propertyId) or 0]
    PS.ClearOccupant(source)
    SetPlayerRoutingBucket(source, 0)
    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer and row then
        local pos = PS.PropertyPos(row)
        xPlayer.setCoords({ x = pos.x, y = pos.y, z = pos.z, heading = pos.w or 0.0 })
    end
end

AddEventHandler("vfw:playerDropped", function(source)
    PS.ClearOccupant(source)
    for key in pairs(PS.ManageCache) do
        if key:sub(1, #tostring(source) + 1) == tostring(source) .. ":" then
            PS.ManageCache[key] = nil
        end
    end
end)

MySQL.ready(function()
    PS.LoadProperties()
    PS.Ready = true
end)
