local Whitening = {
    points = {},
    settings = {},
    sessions = {},
    starting = {},
}

local BUILDER_PERM = "builder_whitening"
local DEFAULT_SETTINGS = {
    maxDirtyMoney = 50000,
    feePercent = 20,
    timerSeconds = 600,
    periodHours = 24,
    factionQuota = 0,
}

local function LoadSettings()
    Whitening.settings = IL.LoadSettings("whitening_settings", DEFAULT_SETTINGS)
end

local function LoadPoints()
    Whitening.points = {}
    local rows = IL.Query("SELECT * FROM whitening_points")
    for i = 1, #rows do
        local row = rows[i]
        Whitening.points[row.id] = {
            id = row.id,
            name = row.name or ("Point #" .. tostring(row.id)),
            pos = { x = IL.Num(row.pos_x, 0.0), y = IL.Num(row.pos_y, 0.0), z = IL.Num(row.pos_z, 0.0) },
            active = IL.Bool(row.active),
            groupRestriction = row.group_restriction or "",
            overrides = {
                maxDirtyMoney = row.override_max_dirty_money and IL.Int(row.override_max_dirty_money, nil) or nil,
                feePercent = row.override_fee_percent and IL.Num(row.override_fee_percent, nil) or nil,
            },
        }
    end
end

local function PeriodStart()
    local hours = IL.Int(Whitening.settings.periodHours, 24)
    if hours <= 0 then hours = 24 end
    local seconds = hours * 3600
    local now = IL.Now()
    return now - (now % seconds)
end

local function QuotaUsed(scope, key)
    local amount = IL.Scalar([[
        SELECT COALESCE(SUM(amount), 0) FROM whitening_quota
        WHERE scope = ? AND scope_key = ? AND period_start = ?
    ]], { scope, key, PeriodStart() })
    return IL.Int(amount, 0)
end

local function AddQuota(scope, key, amount)
    if key == nil or key == "" then return end
    IL.Execute("INSERT INTO whitening_quota (scope, scope_key, amount, period_start) VALUES (?, ?, ?, ?)", {
        scope, key, amount, PeriodStart(),
    })
end

local function PointLimits(point)
    local maxDirty = IL.Int(Whitening.settings.maxDirtyMoney, 50000)
    local feePercent = IL.Num(Whitening.settings.feePercent, 20)
    if point and point.overrides then
        if point.overrides.maxDirtyMoney then maxDirty = point.overrides.maxDirtyMoney end
        if point.overrides.feePercent then feePercent = point.overrides.feePercent end
    end
    return maxDirty, feePercent
end

local function PointsPayload()
    local out = {}
    for id, point in pairs(Whitening.points) do
        out[id] = {
            id = id,
            name = point.name,
            pos = point.pos,
            active = point.active,
            groupRestriction = point.groupRestriction,
            overrides = point.overrides,
        }
    end
    return out
end

local function SettingsPayload()
    return {
        maxDirtyMoney = IL.Int(Whitening.settings.maxDirtyMoney, 50000),
        feePercent = IL.Num(Whitening.settings.feePercent, 20),
        timerSeconds = IL.Int(Whitening.settings.timerSeconds, 600),
        periodHours = IL.Int(Whitening.settings.periodHours, 24),
        factionQuota = IL.Int(Whitening.settings.factionQuota, 0),
    }
end

IL.OnReady(function()
    LoadSettings()
    LoadPoints()
    IL.Execute("UPDATE whitening_sessions SET status = 'cancelled' WHERE status = 'running'")
    TriggerClientEvent("core:whitening:pointsUpdated", -1, PointsPayload())
    TriggerClientEvent("core:whitening:settingsUpdated", -1, SettingsPayload())
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("core:whitening:pointsUpdated", source, PointsPayload())
    TriggerClientEvent("core:whitening:settingsUpdated", source, SettingsPayload())
end)

IL.OnPlayerDropped(function(source)
    Whitening.starting[source] = nil
    local session = Whitening.sessions[source]
    if not session then return end
    Whitening.sessions[source] = nil
    IL.Execute("UPDATE whitening_sessions SET status = 'cancelled' WHERE id = ?", { session.dbId })
end)

IL.RegisterCallback("core:whitening:getPoints", function(source)
    return PointsPayload()
end)

IL.RegisterCallback("core:whitening:getSettings", function(source)
    return SettingsPayload()
end)

IL.RegisterCallback("core:whitening:checkSession", function(source)
    local session = Whitening.sessions[source]
    if not session then
        return { active = false, ready = false, timeLeft = 0 }
    end
    local timeLeft = math.max(0, session.readyAt - IL.Now())
    return { active = true, ready = timeLeft <= 0, timeLeft = timeLeft }
end)

IL.RegisterCallback("core:whitening:checkCooldown", function(source, pointId)
    local xPlayer = IL.Player(source)
    if not xPlayer then
        return { hasError = true, onCooldown = false, message = "Joueur introuvable" }
    end

    local id = IL.Int(pointId, nil)
    local point = id and Whitening.points[id] or nil
    if not point then
        return { hasError = true, onCooldown = false, message = "Ce point n'est pas valide" }
    end

    local maxDirty = PointLimits(point)

    local playerUsed = QuotaUsed("player", xPlayer.identifier)
    local playerRemaining = math.max(0, maxDirty - playerUsed)

    local factionName = IL.FactionName(xPlayer)
    local factionQuota = IL.Int(Whitening.settings.factionQuota, 0)
    local factionRemaining = nil
    if factionQuota > 0 and factionName ~= "" then
        local used = QuotaUsed("faction", factionName)
        factionRemaining = math.max(0, factionQuota - used)
    end

    if factionRemaining ~= nil and factionRemaining <= 0 then
        return {
            hasError = false,
            onCooldown = true,
            message = "Votre organisation a atteint sa limite de blanchiment.",
            factionRemaining = 0,
        }
    end

    if playerRemaining <= 0 then
        return {
            hasError = false,
            onCooldown = true,
            message = "Vous avez atteint votre limite de blanchiment.",
            playerRemaining = 0,
        }
    end

    return {
        hasError = false,
        onCooldown = false,
        message = "",
        factionRemaining = factionRemaining,
        playerRemaining = playerRemaining,
    }
end)

IL.RegisterCallback("core:whitening:canAccessPoint", function(source, pointId)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local id = IL.Int(pointId, nil)
    local point = id and Whitening.points[id] or nil
    if not point then return false, "Ce point n'est pas valide" end
    if not point.active then return false, "Point indisponible" end

    if point.groupRestriction ~= "" then
        if IL.FactionName(xPlayer) ~= point.groupRestriction then
            return false, "Vous n'avez pas acces a ce point"
        end
    end

    if Whitening.sessions[source] then
        return false, "Vous avez deja un blanchiment en cours"
    end

    if IL.DistanceTo(source, point.pos.x, point.pos.y, point.pos.z) > 15.0 then
        return false, "Vous etes trop loin"
    end

    return true, nil
end)

IL.RegisterCallback("vfw:illegal:whitening:hasEnoughDirtyMoney", function(source, amount)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false end

    local value = IL.Int(amount, nil)
    if not value or value <= 0 then return false end

    return IL.AccountMoney(xPlayer, "black_money") >= value
end)

RegisterNetEvent("core:whitening:startSession", function(pointId, amount)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(pointId, nil)
    local value = IL.Int(amount, nil)
    if not id or not value or value <= 0 then return end

    local point = Whitening.points[id]
    if not point or not point.active then return end
    if Whitening.sessions[source] then return end

    local pending = Whitening.starting[source]
    if pending and (IL.Now() - pending) < 15 then return end

    if point.groupRestriction ~= "" and IL.FactionName(xPlayer) ~= point.groupRestriction then
        return
    end

    if IL.DistanceTo(source, point.pos.x, point.pos.y, point.pos.z) > 15.0 then
        IL.Notify(source, "ILLEGAL", "Vous etes trop loin du point.")
        return
    end

    Whitening.starting[source] = IL.Now()

    local maxDirty, feePercent = PointLimits(point)

    local playerRemaining = math.max(0, maxDirty - QuotaUsed("player", xPlayer.identifier))
    if value > playerRemaining then
        Whitening.starting[source] = nil
        IL.Notify(source, "ILLEGAL", "Montant superieur a votre limite.")
        return
    end

    local factionName = IL.FactionName(xPlayer)
    local factionQuota = IL.Int(Whitening.settings.factionQuota, 0)
    if factionQuota > 0 and factionName ~= "" then
        local factionRemaining = math.max(0, factionQuota - QuotaUsed("faction", factionName))
        if value > factionRemaining then
            Whitening.starting[source] = nil
            IL.Notify(source, "ILLEGAL", "Montant superieur a la limite de votre organisation.")
            return
        end
    end

    if not IL.TakeMoney(xPlayer, "black_money", value, "whitening") then
        Whitening.starting[source] = nil
        IL.Notify(source, "ILLEGAL", "Vous n'avez pas assez d'argent sale.")
        return
    end

    local fee = math.floor(value * (feePercent / 100))
    local cleanAmount = value - fee
    local timerSeconds = IL.Int(Whitening.settings.timerSeconds, 600)
    local now = IL.Now()

    local dbId = IL.Insert([[
        INSERT INTO whitening_sessions (identifier, point_id, dirty_amount, clean_amount, fee, fee_percent, timer_seconds, started_at, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'running')
    ]], { xPlayer.identifier, id, value, cleanAmount, fee, feePercent, timerSeconds, now })

    Whitening.sessions[source] = {
        dbId = dbId,
        pointId = id,
        identifier = xPlayer.identifier,
        dirtyAmount = value,
        cleanAmount = cleanAmount,
        fee = fee,
        feePercent = feePercent,
        readyAt = now + timerSeconds,
    }
    Whitening.starting[source] = nil

    AddQuota("player", xPlayer.identifier, value)
    if factionQuota > 0 and factionName ~= "" then
        AddQuota("faction", factionName, value)
    end

    TriggerClientEvent("core:whitening:sessionStarted", source, {
        pointId = id,
        timerSeconds = timerSeconds,
        cleanAmount = cleanAmount,
        fee = fee,
        feePercent = feePercent,
    })
end)

RegisterNetEvent("core:whitening:collect", function(pointId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(pointId, nil)
    if not id then return end

    local session = Whitening.sessions[source]
    if not session or session.pointId ~= id then return end
    if IL.Now() < session.readyAt then return end

    local point = Whitening.points[id]
    if point and IL.DistanceTo(source, point.pos.x, point.pos.y, point.pos.z) > 15.0 then
        IL.Notify(source, "ILLEGAL", "Vous etes trop loin du point.")
        return
    end

    Whitening.sessions[source] = nil
    IL.Execute("UPDATE whitening_sessions SET status = 'collected' WHERE id = ?", { session.dbId })

    IL.GiveMoney(xPlayer, "money", session.cleanAmount, "whitening")
    TriggerClientEvent("core:whitening:sessionComplete", source)
end)

RegisterNetEvent("core:whitening:cancelSession", function()
    local source = source
    local session = Whitening.sessions[source]
    if not session then return end

    Whitening.sessions[source] = nil
    IL.Execute("UPDATE whitening_sessions SET status = 'cancelled' WHERE id = ?", { session.dbId })
end)

RegisterNetEvent("core:whitening:createPoint", function(data)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if not IL.IsTable(data) then return end

    local pos = type(data.pos) == "table" and data.pos or data
    IL.Insert([[
        INSERT INTO whitening_points (name, pos_x, pos_y, pos_z, active, group_restriction, override_max_dirty_money, override_fee_percent)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        IL.Str(data.name, "Blanchiment"),
        IL.Num(pos.x or data.x, 0.0), IL.Num(pos.y or data.y, 0.0), IL.Num(pos.z or data.z, 0.0),
        (data.active == nil or IL.Bool(data.active)) and 1 or 0,
        IL.Str(data.groupRestriction or data.group_restriction, ""),
        (data.maxDirtyMoney or (data.overrides and data.overrides.maxDirtyMoney)) and IL.Int(data.maxDirtyMoney or data.overrides.maxDirtyMoney, nil) or nil,
        (data.feePercent or (data.overrides and data.overrides.feePercent)) and IL.Num(data.feePercent or data.overrides.feePercent, nil) or nil,
    })

    LoadPoints()
    TriggerClientEvent("core:whitening:pointsUpdated", -1, PointsPayload())
end)

RegisterNetEvent("core:whitening:deletePoint", function(pointId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    local id = IL.Int(pointId, nil)
    if not id then return end

    IL.Execute("DELETE FROM whitening_points WHERE id = ?", { id })
    LoadPoints()
    TriggerClientEvent("core:whitening:pointsUpdated", -1, PointsPayload())
end)

RegisterNetEvent("core:whitening:updateSettings", function(key, value)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(key) ~= "string" then return end
    if key == "playerCooldownHours" then key = "periodHours" end
    if DEFAULT_SETTINGS[key] == nil then return end

    local number = tonumber(value)
    if not number then return end

    IL.SaveSetting("whitening_settings", key, number)
    Whitening.settings[key] = number
    TriggerClientEvent("core:whitening:settingsUpdated", -1, SettingsPayload())
end)

local function staffOk(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission(BUILDER_PERM)
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function fail(message)
    return { success = false, ok = false, error = message or "Action impossible." }
end

local function FactionsCatalog()
    local rows = IL.Query([[
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

local function PointRows()
    local rows = IL.Query("SELECT * FROM whitening_points ORDER BY id")
    for i = 1, #rows do
        local row = rows[i]
        row.active = IL.Bool(row.active)
        row.coords = {
            x = IL.Num(row.pos_x, 0.0),
            y = IL.Num(row.pos_y, 0.0),
            z = IL.Num(row.pos_z, 0.0),
        }
        row.groupRestriction = row.group_restriction or ""
        row.overrides = {
            maxDirtyMoney = row.override_max_dirty_money and IL.Int(row.override_max_dirty_money, nil) or nil,
            feePercent = row.override_fee_percent and IL.Num(row.override_fee_percent, nil) or nil,
        }
    end
    return rows
end

local function HubPanel()
    return {
        ok = true,
        success = true,
        points = PointRows(),
        settings = SettingsPayload(),
        factions = FactionsCatalog(),
    }
end

local function BroadcastWhitening()
    LoadPoints()
    TriggerClientEvent("core:whitening:pointsUpdated", -1, PointsPayload())
    TriggerClientEvent("core:whitening:settingsUpdated", -1, SettingsPayload())
end

local function OverrideOrNil(value)
    if value == nil or value == "" then return nil end
    local n = tonumber(value)
    if n == nil then return nil end
    return n
end

local function SavePoint(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local pos = type(data.coords) == "table" and data.coords or (type(data.pos) == "table" and data.pos or data)
    if pos.x == nil and pos.pos_x == nil then return nil, "Définissez la position." end
    local name = IL.Str(data.name, "Blanchiment")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "Blanchiment" end
    local faction = IL.Str(data.groupRestriction or data.group_restriction, "")
    if faction == "none" then faction = "" end
    local overrides = type(data.overrides) == "table" and data.overrides or {}
    local maxDirty = OverrideOrNil(data.maxDirtyMoney or data.override_max_dirty_money or overrides.maxDirtyMoney)
    local fee = OverrideOrNil(data.feePercent or data.override_fee_percent or overrides.feePercent)
    local active = data.active
    if active == nil then active = true end
    local id = IL.Int(data.id, nil)
    local x = IL.Num(pos.x or pos.pos_x, 0.0)
    local y = IL.Num(pos.y or pos.pos_y, 0.0)
    local z = IL.Num(pos.z or pos.pos_z, 0.0)
    if id then
        IL.Execute([[
            UPDATE whitening_points SET name = ?, pos_x = ?, pos_y = ?, pos_z = ?, active = ?,
                group_restriction = ?, override_max_dirty_money = ?, override_fee_percent = ?
            WHERE id = ?
        ]], { name, x, y, z, IL.Bool(active) and 1 or 0, faction, maxDirty, fee, id })
        BroadcastWhitening()
        return id
    end
    id = IL.Insert([[
        INSERT INTO whitening_points (name, pos_x, pos_y, pos_z, active, group_restriction, override_max_dirty_money, override_fee_percent)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], { name, x, y, z, IL.Bool(active) and 1 or 0, faction, maxDirty, fee })
    if not id then return nil, "Création impossible." end
    BroadcastWhitening()
    return id
end

local function SaveSettings(data)
    if type(data) ~= "table" then return false end
    local map = {
        maxDirtyMoney = data.maxDirtyMoney,
        feePercent = data.feePercent,
        timerSeconds = data.timerSeconds,
        periodHours = data.periodHours or data.playerCooldownHours,
        factionQuota = data.factionQuota,
    }
    for key, value in pairs(map) do
        if value ~= nil and DEFAULT_SETTINGS[key] ~= nil then
            local number = tonumber(value)
            if number then
                if key == "feePercent" then
                    number = math.max(0, math.min(100, number))
                elseif key == "timerSeconds" or key == "periodHours" then
                    number = math.max(1, math.floor(number))
                else
                    number = math.max(0, number)
                end
                IL.SaveSetting("whitening_settings", key, number)
                Whitening.settings[key] = number
            end
        end
    end
    TriggerClientEvent("core:whitening:settingsUpdated", -1, SettingsPayload())
    return true
end

RegisterNetEvent("core:whitening:updatePoint", function(point)
    local source = source
    if not staffOk(source) then return end
    SavePoint(point)
end)

RegisterNetEvent("core:whitening:reloadFromDatabase", function()
    local source = source
    if not staffOk(source) then return end
    LoadSettings()
    BroadcastWhitening()
end)

RegisterNetEvent("core:whitening:resetCooldowns", function()
    local source = source
    if not staffOk(source) then return end
    IL.Execute("DELETE FROM whitening_quota")
end)

IL.RegisterCallback("gestionWhitening:hubPanel", function(source)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer le blanchiment." }
    end
    return HubPanel()
end)

IL.RegisterCallback("gestionWhitening:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) ~= "table" then return fail("Données invalides.") end
    local action = tostring(data.action or "")
    local err

    if action == "point:create" or action == "point:update" then
        local id
        id, err = SavePoint(data)
        if not id then return fail(err) end
    elseif action == "point:delete" then
        local id = IL.Int(data.id, nil)
        if not id then return fail("Point introuvable.") end
        IL.Execute("DELETE FROM whitening_points WHERE id = ?", { id })
        BroadcastWhitening()
    elseif action == "settings:save" then
        SaveSettings(data)
    elseif action == "quotas:reset" then
        IL.Execute("DELETE FROM whitening_quota")
    else
        return fail("Action inconnue.")
    end

    local panel = HubPanel()
    panel.success = true
    return panel
end)
