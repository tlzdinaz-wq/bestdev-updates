Misc30 = Misc30 or {}

local registeredCallbacks = {}

function Misc30.Cb(name, handler)
    if type(name) ~= "string" or type(handler) ~= "function" then return false end
    if registeredCallbacks[name] then
        console.warn(("[misc30] callback deja enregistre localement: %s"):format(name))
        return false
    end
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[misc30] RegisterServerCallback('%s') refuse: %s"):format(name, tostring(err)))
        return false
    end
    registeredCallbacks[name] = true
    return true
end

local function safeSql(fn, sql, params, fallback)
    if not fn then return fallback end
    local ok, res = pcall(fn, sql, params)
    if not ok then
        console.warn(("[misc30] SQL: %s | %s"):format(tostring(res), tostring(sql)))
        return fallback
    end
    if res == nil then return fallback end
    return res
end

function Misc30.Query(sql, params)
    return safeSql(MySQL and MySQL.query and MySQL.query.await, sql, params, {})
end

function Misc30.Single(sql, params)
    return safeSql(MySQL and MySQL.single and MySQL.single.await, sql, params, nil)
end

function Misc30.Scalar(sql, params, fallback)
    local value = safeSql(MySQL and MySQL.scalar and MySQL.scalar.await, sql, params, fallback)
    if value == nil then return fallback end
    return value
end

function Misc30.Insert(sql, params)
    return safeSql(MySQL and MySQL.insert and MySQL.insert.await, sql, params, nil)
end

function Misc30.Update(sql, params)
    return safeSql(MySQL and MySQL.update and MySQL.update.await, sql, params, 0)
end

function Misc30.IsNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Misc30.ToInt(value, min, max)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
    n = math.floor(n)
    if min and n < min then return nil end
    if max and n > max then return nil end
    return n
end

function Misc30.ToFloat(value, min, max)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
    if min and n < min then return min end
    if max and n > max then return max end
    return n + 0.0
end

function Misc30.IsString(value, maxLen)
    if type(value) ~= "string" then return false end
    if value == "" then return false end
    if maxLen and #value > maxLen then return false end
    return true
end

function Misc30.Clean(value, maxLen, fallback)
    if type(value) ~= "string" then return fallback end
    local out = value:gsub("[%z\1-\8\11\12\14-\31]", "")
    if maxLen and #out > maxLen then out = out:sub(1, maxLen) end
    if out == "" then return fallback end
    return out
end

function Misc30.IsUrl(value, maxLen)
    if not Misc30.IsString(value, maxLen or 1024) then return false end
    local lower = value:lower()
    return lower:sub(1, 7) == "http://" or lower:sub(1, 8) == "https://"
end

function Misc30.Vec3(value, fallback)
    if type(value) == "vector3" then return value end
    if type(value) == "vector4" then return vector3(value.x, value.y, value.z) end
    if type(value) == "table" then
        local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
        if x and y and z then return vector3(x + 0.0, y + 0.0, z + 0.0) end
        x, y, z = tonumber(value[1]), tonumber(value[2]), tonumber(value[3])
        if x and y and z then return vector3(x + 0.0, y + 0.0, z + 0.0) end
    end
    return fallback
end

function Misc30.Plain(value, fallback)
    local v = Misc30.Vec3(value)
    if not v then return fallback end
    return { x = v.x, y = v.y, z = v.z }
end

function Misc30.PlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    local coords = GetEntityCoords(ped)
    if not coords then return nil end
    return coords
end

function Misc30.Dist(a, b)
    local va, vb = Misc30.Vec3(a), Misc30.Vec3(b)
    if not va or not vb then return 999999.0 end
    return #(va - vb)
end

function Misc30.NearPlayers(source, target, maxDistance)
    local a, b = Misc30.PlayerCoords(source), Misc30.PlayerCoords(target)
    if not a or not b then return false end
    return #(a - b) <= (maxDistance or 5.0)
end

function Misc30.PlayersInRadius(coords, radius)
    local center = Misc30.Vec3(coords)
    local out = {}
    if not center then return out end
    local max = tonumber(radius) or 60.0
    local players = GetPlayers()
    for i = 1, #players do
        local src = tonumber(players[i])
        if src then
            local pos = Misc30.PlayerCoords(src)
            if pos and #(pos - center) <= max then
                out[#out + 1] = src
            end
        end
    end
    return out
end

function Misc30.EntityFromNet(netId)
    local id = tonumber(netId)
    if not id or id <= 0 then return nil end
    local ok, entity = pcall(NetworkGetEntityFromNetworkId, id)
    if not ok or not entity or entity == 0 then return nil end
    if not DoesEntityExist(entity) then return nil end
    return entity
end

local rateBuckets = {}

function Misc30.RateLimit(source, key, delay)
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

function Misc30.ClearRate(source)
    rateBuckets[tonumber(source) or 0] = nil
end

function Misc30.Notify(source, kind, message)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification(source, { type = kind or "ROUGE", content = message or "" })
    end
end

function Misc30.HasPerm(xPlayer, permission)
    if not xPlayer then return false end
    if permission == nil or permission == "" then return true end
    if xPlayer.hasPermission(permission) then return true end
    if xPlayer.hasPermission("gestion") then return true end
    return false
end

function Misc30.Inv()
    return VFW and VFW.Inventory or nil
end

function Misc30.ItemExists(name)
    local inv = Misc30.Inv()
    if inv and inv.Exists then
        local ok, res = pcall(inv.Exists, name)
        if ok then return res == true end
    end
    if VFW and VFW.Items and VFW.Items[name] then return true end
    return false
end

function Misc30.FirstExistingItem(candidates)
    for i = 1, #candidates do
        if Misc30.ItemExists(candidates[i]) then return candidates[i] end
    end
    return nil
end

function Misc30.CountItem(xPlayer, name)
    local inv = Misc30.Inv()
    if not inv or not xPlayer then return 0 end
    local ok, count = pcall(function()
        return inv.CountByName(inv.PlayerList(xPlayer), name)
    end)
    if ok and type(count) == "number" then return count end
    return 0
end

function Misc30.GiveItem(xPlayer, name, count, meta)
    local inv = Misc30.Inv()
    if not inv or not xPlayer or not name then return false end
    local qty = math.floor(tonumber(count) or 1)
    if qty <= 0 then return false end
    local added = 0
    local ok = pcall(function()
        added = inv.AddToList(inv.PlayerList(xPlayer), name, qty, meta, inv.PlayerMaxSlots)
        inv.PushPlayer(xPlayer)
    end)
    return ok and added >= qty
end

function Misc30.TakeItem(xPlayer, name, count)
    local inv = Misc30.Inv()
    if not inv or not xPlayer or not name then return false end
    local qty = math.floor(tonumber(count) or 1)
    if qty <= 0 then return false end
    local removed = 0
    local ok = pcall(function()
        removed = inv.RemoveByName(inv.PlayerList(xPlayer), name, qty)
        inv.PushPlayer(xPlayer)
    end)
    return ok and removed >= qty
end

function Misc30.UsableItem(name, handler)
    local inv = Misc30.Inv()
    if not inv or not inv.RegisterUsableItem then return false end
    if not Misc30.ItemExists(name) then return false end
    local ok = pcall(inv.RegisterUsableItem, name, handler)
    return ok
end

function Misc30.PlayerName(xPlayer)
    if not xPlayer then return "Inconnu" end
    if type(xPlayer.firstName) == "string" and xPlayer.firstName ~= "" then
        return ("%s %s"):format(xPlayer.firstName, xPlayer.lastName or "")
    end
    return xPlayer.playerName or "Inconnu"
end

AddEventHandler("vfw:playerDropped", function(source)
    Misc30.ClearRate(source)
end)
