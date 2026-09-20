local ATM = {
    positions = {},
    sessions = {},
    atmCooldown = {},
    playerCooldown = {},
    settings = {},
}

local BUILDER_PERM = "builder_atm"
local SESSION_TTL = 300

local DEFAULT_SETTINGS = {
    dirtyMin = 1200,
    dirtyMax = 1800,
    globalCooldown = 600,
    playerCooldown = 900,
    minPoliceRequired = 0,
    alertChance = 100,
    jackpotChance = 5,
    jackpotMultiplier = 3,
}

local function LoadSettings()
    ATM.settings = IL.LoadSettings("atm_settings", DEFAULT_SETTINGS)
    if Config then
        ATM.settings.dirtyMin = IL.Int(ATM.settings.dirtyMin, Config.ATM_DirtyMin or 1200)
        ATM.settings.dirtyMax = IL.Int(ATM.settings.dirtyMax, Config.ATM_DirtyMax or 1800)
    end
    if ATM.settings.dirtyMax < ATM.settings.dirtyMin then
        ATM.settings.dirtyMax = ATM.settings.dirtyMin
    end
end

local function LoadPositions()
    ATM.positions = {}
    local rows = IL.Query("SELECT * FROM atm_custom_positions ORDER BY id")
    for i = 1, #rows do
        local row = rows[i]
        ATM.positions[#ATM.positions + 1] = {
            id = row.id,
            name = row.name or ("ATM #" .. tostring(row.id)),
            x = IL.Num(row.x, 0.0),
            y = IL.Num(row.y, 0.0),
            z = IL.Num(row.z, 0.0),
            heading = IL.Num(row.heading, 0.0),
            active = IL.Bool(row.active),
        }
    end
end

local function Broadcast()
    TriggerClientEvent("core:atm:syncCustomPositions", -1, ATM.positions)
end

local function HackItem(xPlayer)
    if not xPlayer then return nil end
    local usb = (Config and Config.ATM_USB_ITEM) or "usb_piratage_atm"
    local drill = (Config and Config.ATM_DRILL_ITEM) or "foreuse"
    if xPlayer.haveItem(usb, 1) then return usb, "usb" end
    if xPlayer.haveItem(drill, 1) then return drill, "drill" end
    return nil
end

local function PurgeSessions()
    local now = IL.Now()
    for id, session in pairs(ATM.sessions) do
        if now - session.startedAt > SESSION_TTL then
            ATM.sessions[id] = nil
        end
    end
end

IL.OnReady(function()
    LoadSettings()
    LoadPositions()
    Broadcast()
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("core:atm:syncCustomPositions", source, ATM.positions)
end)

IL.OnPlayerDropped(function(source)
    for id, session in pairs(ATM.sessions) do
        if session.source == source then
            ATM.sessions[id] = nil
        end
    end
end)

CreateThread(function()
    while true do
        Wait(60000)
        PurgeSessions()
    end
end)

IL.RegisterCallback("core:atm:hasHackItem", function(source)
    local xPlayer = IL.Player(source)
    local itemName, method = HackItem(xPlayer)
    if not itemName then return false, nil end
    return true, method
end)

IL.RegisterCallback("core:atm:getCustomPositions", function(source)
    return ATM.positions
end)

IL.RegisterCallback("core:atm:getSettings", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return {} end
    return ATM.settings
end)

IL.RegisterCallback("core:atm:StartHack", function(source, atmNetId, atmCoords)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable", nil, nil end

    if atmNetId ~= nil and type(atmNetId) ~= "string" and type(atmNetId) ~= "number" then
        return false, "Ce distributeur n'est pas valide", nil, nil
    end

    local atmKey = tostring(atmNetId or "unknown")
    local now = IL.Now()

    local itemName, method = HackItem(xPlayer)
    if not itemName then
        return false, "Vous n'avez pas le materiel necessaire", nil, nil
    end

    local minPolice = IL.Int(ATM.settings.minPoliceRequired, 0)
    if minPolice > 0 and IL.PoliceOnDutyCount() < minPolice then
        return false, "Trop peu de policiers en service", nil, nil
    end

    local atmLast = ATM.atmCooldown[atmKey]
    if atmLast and (now - atmLast) < IL.Int(ATM.settings.globalCooldown, 600) then
        return false, "Ce distributeur a ete pirate recemment", nil, nil
    end

    local playerLast = ATM.playerCooldown[xPlayer.identifier]
    if playerLast and (now - playerLast) < IL.Int(ATM.settings.playerCooldown, 900) then
        return false, "Vous devez attendre avant de recommencer", nil, nil
    end

    for _, session in pairs(ATM.sessions) do
        if session.source == source and not session.closed then
            return false, "Vous avez deja un piratage en cours", nil, nil
        end
    end

    local coords = nil
    if IL.IsTable(atmCoords) then
        coords = { x = IL.Num(atmCoords.x, 0.0), y = IL.Num(atmCoords.y, 0.0), z = IL.Num(atmCoords.z, 0.0) }
    elseif type(atmCoords) == "vector3" then
        coords = { x = atmCoords.x, y = atmCoords.y, z = atmCoords.z }
    end

    if coords then
        local maxDist = (Config and Config.ATM_MaxDistance or 2.5) + 3.0
        if IL.DistanceTo(source, coords.x, coords.y, coords.z) > maxDist then
            return false, "Vous etes trop loin du distributeur", nil, nil
        end
    end

    local jackpotChance = IL.Int(ATM.settings.jackpotChance, 5)
    local jackpot = jackpotChance > 0 and math.random(1, 100) <= jackpotChance

    local sessionId = ("atm:%d:%d:%d"):format(source, now, math.random(100000, 999999))
    ATM.sessions[sessionId] = {
        source = source,
        identifier = xPlayer.identifier,
        atmKey = atmKey,
        coords = coords,
        method = method,
        item = itemName,
        jackpot = jackpot,
        startedAt = now,
        closed = false,
    }

    ATM.atmCooldown[atmKey] = now

    local alertChance = IL.Int(ATM.settings.alertChance, 100)
    if coords and (alertChance >= 100 or math.random(1, 100) <= alertChance) then
        IL.AlertPolice("core:atm:policeAlert", coords)
    end

    return true, nil, sessionId, { method = method, jackpot = jackpot }
end)

RegisterNetEvent("core:atm:FinishHack", function(success, sessionId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    if type(sessionId) ~= "string" then return end

    local session = ATM.sessions[sessionId]
    if not session or session.closed then return end
    if session.source ~= source then return end

    session.closed = true
    ATM.sessions[sessionId] = nil

    local ok = success == true
    local amount = 0

    if ok then
        local minValue = IL.Int(ATM.settings.dirtyMin, 1200)
        local maxValue = IL.Int(ATM.settings.dirtyMax, 1800)
        if maxValue < minValue then maxValue = minValue end
        amount = math.random(minValue, maxValue)
        if session.jackpot then
            amount = math.floor(amount * IL.Num(ATM.settings.jackpotMultiplier, 3))
        end

        IL.TakeItem(xPlayer, session.item, 1)
        IL.GiveMoney(xPlayer, "black_money", amount, "atm-hack")
        ATM.playerCooldown[xPlayer.identifier] = IL.Now()

        if session.jackpot and session.coords then
            TriggerClientEvent("core:atm:jackpotAlert", -1, session.coords)
        end
    else
        IL.TakeItem(xPlayer, session.item, 1)
    end

    IL.Execute([[
        INSERT INTO atm_hack_log (atm_key, identifier, method, jackpot, success, amount)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        session.atmKey, xPlayer.identifier, session.method,
        session.jackpot and 1 or 0, ok and 1 or 0, amount,
    })
end)

RegisterNetEvent("core:atm:addCustomPosition", function(data)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if not IL.IsTable(data) then return end

    IL.Insert([[
        INSERT INTO atm_custom_positions (name, x, y, z, heading, active)
        VALUES (?, ?, ?, ?, ?, 1)
    ]], {
        IL.Str(data.name, "ATM Custom"),
        IL.Num(data.x, 0.0), IL.Num(data.y, 0.0), IL.Num(data.z, 0.0), IL.Num(data.heading, 0.0),
    })

    LoadPositions()
    Broadcast()
    TriggerClientEvent("core:atm:syncComplete", source)
end)

RegisterNetEvent("core:atm:updateCustomPosition", function(atmId, field, value)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    atmId = IL.Int(atmId, nil)
    if not atmId or type(field) ~= "string" then return end

    if field == "name" then
        if type(value) ~= "string" then return end
        IL.Execute("UPDATE atm_custom_positions SET name = ? WHERE id = ?", { value, atmId })
    elseif field == "x" or field == "y" or field == "z" or field == "heading" then
        local number = tonumber(value)
        if not number then return end
        IL.Execute(("UPDATE atm_custom_positions SET %s = ? WHERE id = ?"):format(field), { number, atmId })
    elseif field == "active" then
        IL.Execute("UPDATE atm_custom_positions SET active = ? WHERE id = ?", { IL.Bool(value) and 1 or 0, atmId })
    else
        return
    end

    LoadPositions()
    Broadcast()
    TriggerClientEvent("core:atm:syncComplete", source)
end)

RegisterNetEvent("core:atm:deleteCustomPosition", function(atmId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    atmId = IL.Int(atmId, nil)
    if not atmId then return end

    IL.Execute("DELETE FROM atm_custom_positions WHERE id = ?", { atmId })
    LoadPositions()
    Broadcast()
    TriggerClientEvent("core:atm:syncComplete", source)
end)

RegisterNetEvent("core:atm:teleportToATM", function(atmId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    atmId = IL.Int(atmId, nil)
    if not atmId then return end

    for i = 1, #ATM.positions do
        local atm = ATM.positions[i]
        if atm.id == atmId then
            xPlayer.setCoords({ x = atm.x, y = atm.y, z = atm.z + 1.0, heading = atm.heading })
            return
        end
    end
end)

RegisterNetEvent("core:atm:updateSettings", function(key, value)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(key) ~= "string" or DEFAULT_SETTINGS[key] == nil then return end

    local number = tonumber(value)
    if not number then return end

    IL.SaveSetting("atm_settings", key, number)
    ATM.settings[key] = number
end)

RegisterNetEvent("core:atm:resetCooldowns", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    ATM.atmCooldown = {}
    ATM.playerCooldown = {}
    IL.Notify(source, "STAFF", "Cooldowns ATM reinitialises.")
end)

RegisterNetEvent("core:atm:reloadSettings", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    LoadSettings()
    LoadPositions()
    Broadcast()
    TriggerClientEvent("core:atm:syncComplete", source)
end)
