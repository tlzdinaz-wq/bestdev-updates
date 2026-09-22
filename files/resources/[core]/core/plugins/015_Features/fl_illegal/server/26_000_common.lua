IL = IL or {}

IL.Callbacks = IL.Callbacks or {}

function IL.RegisterCallback(name, fn)
    if type(name) ~= "string" or type(fn) ~= "function" then return false end
    if IL.Callbacks[name] then
        console.warn(("[illegal] callback deja enregistre localement: %s"):format(name))
        return false
    end
    local ok, err = pcall(RegisterServerCallback, name, fn)
    if not ok then
        console.warn(("[illegal] impossible d'enregistrer le callback '%s': %s"):format(name, tostring(err)))
        return false
    end
    IL.Callbacks[name] = true
    return true
end

function IL.Num(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

function IL.Int(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return math.floor(n)
end

function IL.Str(value, fallback)
    if type(value) == "string" then return value end
    return fallback
end

function IL.IsTable(value)
    return type(value) == "table"
end

function IL.Bool(value)
    if value == nil then return false end
    if type(value) == "boolean" then return value end
    if type(value) == "number" then return value ~= 0 end
    if type(value) == "string" then return value == "1" or value == "true" end
    return false
end

function IL.Now()
    return os.time()
end

function IL.Clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function IL.Decode(value, fallback)
    if value == nil then return fallback end
    if type(value) == "table" then return value end
    if VFW and VFW.DB and VFW.DB.Decode then
        local decoded = VFW.DB.Decode(value, fallback)
        if decoded ~= nil then return decoded end
        return fallback
    end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

function IL.Encode(value)
    if VFW and VFW.DB and VFW.DB.Encode then
        return VFW.DB.Encode(value)
    end
    return json.encode(value)
end

function IL.Player(source)
    if not VFW or not VFW.GetPlayerFromId then return nil end
    return VFW.GetPlayerFromId(source)
end

function IL.FactionName(xPlayer)
    if not xPlayer then return "" end
    local faction = xPlayer.faction
    if type(faction) == "table" then
        return faction.name or ""
    end
    if type(faction) == "string" then return faction end
    return ""
end

function IL.FactionGrade(xPlayer)
    if not xPlayer then return 0 end
    local faction = xPlayer.faction
    if type(faction) == "table" then
        return tonumber(faction.grade) or 0
    end
    if xPlayer.job2 and type(xPlayer.job2) == "table" then
        return tonumber(xPlayer.job2.grade) or 0
    end
    return 0
end

function IL.FactionLabel(xPlayer)
    if not xPlayer then return "" end
    local faction = xPlayer.faction
    if type(faction) == "table" then
        return faction.label or faction.name or ""
    end
    if type(faction) == "string" then return faction end
    return ""
end

function IL.HasFactionAccess(xPlayer, restriction, minGrade)
    if restriction == nil or restriction == "" then return true end
    if not xPlayer then return false end
    if IL.FactionName(xPlayer) ~= restriction then return false end
    local required = tonumber(minGrade) or 0
    if required > 0 and IL.FactionGrade(xPlayer) < required then return false end
    return true
end

function IL.Coords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function IL.DistanceTo(source, x, y, z)
    local coords = IL.Coords(source)
    if not coords then return 9999.0 end
    local dx, dy, dz = coords.x - (x or 0.0), coords.y - (y or 0.0), coords.z - (z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function IL.Notify(source, kind, message)
    if not source or not message then return end
    TriggerClientEvent("vfw:showNotification", source, {
        type = kind or "ILLEGAL",
        message = message,
        content = message,
    })
end

function IL.PoliceSources()
    local out, n = {}, 0
    if not VFW or not VFW.Players then return out end
    for src, xPlayer in pairs(VFW.Players) do
        local jobName = xPlayer.job and xPlayer.job.name or nil
        local isCop = false
        if jobName then
            if PoliceJobsList and PoliceJobsList[jobName] then isCop = true end
            if not isCop and LawEnforcementJobsList and LawEnforcementJobsList[jobName] then isCop = true end
            if not isCop and xPlayer.job and xPlayer.job.type == "police" then isCop = true end
        end
        if isCop then
            n = n + 1
            out[n] = src
        end
    end
    return out
end

function IL.PoliceOnDutyCount()
    local count = 0
    if not VFW or not VFW.Players then return 0 end
    local sources = IL.PoliceSources()
    for i = 1, #sources do
        local xPlayer = VFW.GetPlayerFromId(sources[i])
        if xPlayer and xPlayer.job and xPlayer.job.onDuty then
            count = count + 1
        end
    end
    return count
end

function IL.AlertPolice(eventName, ...)
    local sources = IL.PoliceSources()
    for i = 1, #sources do
        TriggerClientEvent(eventName, sources[i], ...)
    end
end

function IL.Query(query, params)
    local ok, result = pcall(function()
        return MySQL.query.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return {}
    end
    return result or {}
end

function IL.Single(query, params)
    local ok, result = pcall(function()
        return MySQL.single.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function IL.Scalar(query, params)
    local ok, result = pcall(function()
        return MySQL.scalar.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function IL.Insert(query, params)
    local ok, result = pcall(function()
        return MySQL.insert.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function IL.Execute(query, params)
    local ok, result = pcall(function()
        return MySQL.update.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return 0
    end
    return result or 0
end

function IL.LoadSettings(tableName, defaults)
    local out = {}
    for key, value in pairs(defaults or {}) do out[key] = value end
    local rows = IL.Query(("SELECT setting_key, setting_value FROM %s"):format(tableName))
    for i = 1, #rows do
        local key = rows[i].setting_key
        local raw = rows[i].setting_value
        local current = out[key]
        if type(current) == "number" then
            out[key] = tonumber(raw) or current
        elseif type(current) == "boolean" then
            out[key] = (raw == "1" or raw == "true")
        else
            out[key] = raw
        end
    end
    return out
end

function IL.SaveSetting(tableName, key, value)
    if type(key) ~= "string" then return false end
    local stored
    if type(value) == "boolean" then
        stored = value and "1" or "0"
    elseif type(value) == "table" then
        stored = IL.Encode(value)
    else
        stored = tostring(value)
    end
    IL.Execute(("INSERT INTO %s (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)"):format(tableName), { key, stored })
    return true
end

function IL.EnsureSettingsTable(tableName)
    if type(tableName) ~= "string" or not tableName:match("^[%w_]+$") then return false end
    IL.Query(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `setting_key` VARCHAR(60) NOT NULL,
            `setting_value` TEXT DEFAULT NULL,
            PRIMARY KEY (`setting_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]]):format(tableName))
    return true
end

function IL.GiveMoney(xPlayer, account, amount, reason)
    if not xPlayer or not amount or amount <= 0 then return false end
    xPlayer.addAccountMoney(account, math.floor(amount), reason or "illegal")
    local acc = xPlayer.getAccount(account)
    return acc ~= nil
end

function IL.TakeMoney(xPlayer, account, amount, reason)
    if not xPlayer or not amount or amount <= 0 then return false end
    local acc = xPlayer.getAccount(account)
    if not acc or acc.money < amount then return false end
    xPlayer.removeAccountMoney(account, math.floor(amount), reason or "illegal")
    return true
end

function IL.AccountMoney(xPlayer, account)
    if not xPlayer then return 0 end
    local acc = xPlayer.getAccount(account)
    return acc and acc.money or 0
end

function IL.ItemLabel(itemName)
    if VFW and VFW.Items and VFW.Items[itemName] and VFW.Items[itemName].label then
        return VFW.Items[itemName].label
    end
    return itemName
end

function IL.ItemExists(itemName)
    return VFW ~= nil and VFW.Items ~= nil and VFW.Items[itemName] ~= nil
end

function IL.GiveItem(xPlayer, itemName, count, notify)
    if not xPlayer or type(itemName) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end
    if not IL.ItemExists(itemName) then return false end
    if not xPlayer.canCarryItem(itemName, count) then return false end
    return xPlayer.addInventoryItem(itemName, count, nil, notify ~= false)
end

function IL.TakeItem(xPlayer, itemName, count)
    if not xPlayer or type(itemName) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end
    if not xPlayer.haveItem(itemName, count) then return false end
    return xPlayer.removeInventoryItem(itemName, count, nil, true)
end

IL.readyListeners = IL.readyListeners or {}

function IL.OnReady(fn)
    if type(fn) ~= "function" then return end
    IL.readyListeners[#IL.readyListeners + 1] = fn
end

CreateThread(function()
    local attempts = 0
    while not (VFW and VFW.Ready) and attempts < 200 do
        Wait(250)
        attempts = attempts + 1
    end
    Wait(500)
    for i = 1, #IL.readyListeners do
        local ok, err = pcall(IL.readyListeners[i])
        if not ok then
            console.warn(("[illegal] erreur d'initialisation: %s"):format(tostring(err)))
        end
    end
    IL.Ready = true
end)

IL.playerLoadedListeners = IL.playerLoadedListeners or {}

function IL.OnPlayerLoaded(fn)
    if type(fn) ~= "function" then return end
    IL.playerLoadedListeners[#IL.playerLoadedListeners + 1] = fn
end

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    local src = source
    CreateThread(function()
        Wait(2500)
        for i = 1, #IL.playerLoadedListeners do
            local ok, err = pcall(IL.playerLoadedListeners[i], src, xPlayer)
            if not ok then
                console.warn(("[illegal] erreur de resync joueur: %s"):format(tostring(err)))
            end
        end
    end)
end)

IL.playerDroppedListeners = IL.playerDroppedListeners or {}

function IL.OnPlayerDropped(fn)
    if type(fn) ~= "function" then return end
    IL.playerDroppedListeners[#IL.playerDroppedListeners + 1] = fn
end

AddEventHandler("vfw:playerDropped", function(source, xPlayer)
    local src = source
    for i = 1, #IL.playerDroppedListeners do
        pcall(IL.playerDroppedListeners[i], src, xPlayer)
    end
end)
