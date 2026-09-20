local MAX_DEPTH = 8
local SNAPSHOT_TTL = 30

ConfigManager = ConfigManager or {}
ConfigManager.Loaded = false
ConfigManager.Exposed = {}
ConfigManager.Overrides = {}

local snapshot = {}
local dirty = true

local function sanitize(value, depth, seen)
    depth = depth or 0

    local kind = type(value)

    if kind == "string" or kind == "number" or kind == "boolean" then
        return value
    end

    if kind == "vector2" or kind == "vector3" or kind == "vector4" then
        return value
    end

    if kind ~= "table" then
        return nil
    end

    if depth >= MAX_DEPTH then
        return nil
    end

    seen = seen or {}
    if seen[value] then
        return nil
    end
    seen[value] = true

    local out = {}
    for key, entry in pairs(value) do
        local keyKind = type(key)
        if keyKind == "string" or keyKind == "number" then
            local clean = sanitize(entry, depth + 1, seen)
            if clean ~= nil then
                out[key] = clean
            end
        end
    end

    seen[value] = nil

    return out
end

ConfigManager.Sanitize = function(value)
    return sanitize(value, 0, nil)
end

local function buildBase()
    local base = {
        branding = sanitize(BRANDING, 0, nil) or {},
        locale = sanitize(LOCALE, 0, nil) or {},
        colors = sanitize(BASE_COLORS, 0, nil) or {},
        mentaServer = type(MENTA_SERVER) == "string" and MENTA_SERVER or "US",
        server = {
            resource = GetCurrentResourceName(),
            type = GetConvar("core_type", "FA"),
            dev = IS_DEV == true,
            testserver = (TestServer and TestServer.enabled) == true,
            maxPlayers = GetConvarInt("sv_maxclients", 48),
            playerCount = VFW.GetPlayerCount(),
        },
        framework = {},
        sirens = sanitize(SirensConfig, 0, nil) or {},
        generatedAt = os.time(),
    }

    if type(Config) == "table" then
        base.framework = {
            customInventory = Config.CustomInventory,
            accounts = sanitize(Config.Accounts, 0, nil) or {},
            startingAccountMoney = sanitize(Config.StartingAccountMoney, 0, nil) or {},
            maxWeight = Config.MaxWeight,
            paycheckInterval = Config.PaycheckInterval,
            saveDeathStatus = Config.SaveDeathStatus,
            enableDebug = Config.EnableDebug,
            defaultJobDuty = Config.DefaultJobDuty,
            offDutyPaycheckMultiplier = Config.OffDutyPaycheckMultiplier,
            multichar = Config.Multichar,
            distanceGive = Config.DistanceGive,
            enableSocietyPayouts = Config.EnableSocietyPayouts,
            defaultSpawns = sanitize(Config.DefaultSpawns, 0, nil) or {},
        }
    end

    return base
end

local function rebuild()
    local base = buildBase()

    for key, value in pairs(ConfigManager.Exposed) do
        base[key] = value
    end

    for key, value in pairs(ConfigManager.Overrides) do
        base[key] = value
    end

    snapshot = base
    dirty = false

    return snapshot
end

function ConfigManager.Refresh()
    dirty = true
    return rebuild()
end

function ConfigManager.Get()
    if not dirty and type(snapshot) == "table" and (os.time() - (snapshot.generatedAt or 0)) > SNAPSHOT_TTL then
        dirty = true
    end

    if dirty or type(snapshot) ~= "table" then
        rebuild()
    end

    if type(snapshot) ~= "table" then
        snapshot = {}
    end

    if type(snapshot.server) == "table" then
        snapshot.server.playerCount = VFW.GetPlayerCount()
    end

    return snapshot
end

function ConfigManager.Expose(key, value)
    if type(key) ~= "string" or key == "" then return false end

    local clean = sanitize(value, 0, nil)
    if clean == nil then
        ConfigManager.Exposed[key] = nil
    else
        ConfigManager.Exposed[key] = clean
    end

    dirty = true
    return true
end

function ConfigManager.GetOverride(key)
    if type(key) ~= "string" then return nil end
    return ConfigManager.Overrides[key]
end

local function persist(key, value)
    if type(MySQL) ~= "table" or type(MySQL.Async) ~= "table" then return end

    if value == nil then
        MySQL.Async.execute("DELETE FROM vfw_config WHERE `key` = @key", { ["@key"] = key }, function() end)
        return
    end

    local ok, encoded = pcall(json.encode, value)
    if not ok or type(encoded) ~= "string" then
        console.error(("[ConfigManager] override '%s' non sérialisable"):format(key))
        return
    end

    MySQL.Async.execute(
        "INSERT INTO vfw_config (`key`, `value`) VALUES (@key, @value) ON DUPLICATE KEY UPDATE `value` = @value",
        { ["@key"] = key, ["@value"] = encoded },
        function() end
    )
end

function ConfigManager.Set(key, value, skipPersist)
    if type(key) ~= "string" or key == "" then return false end

    local clean = sanitize(value, 0, nil)
    ConfigManager.Overrides[key] = clean
    dirty = true

    if not skipPersist then
        persist(key, clean)
    end

    TriggerEvent("core:configManager:changed", key, clean)

    return true
end

function ConfigManager.Unset(key)
    if type(key) ~= "string" or key == "" then return false end

    ConfigManager.Overrides[key] = nil
    dirty = true
    persist(key, nil)

    TriggerEvent("core:configManager:changed", key, nil)

    return true
end

local function loadOverrides()
    if type(MySQL) ~= "table" or type(MySQL.ready) ~= "function" then
        ConfigManager.Loaded = true
        rebuild()
        return
    end

    SetTimeout(15000, function()
        if ConfigManager.Loaded then return end
        ConfigManager.Loaded = true
        rebuild()
        console.warn("[ConfigManager] table 'vfw_config' illisible ou absente : aucun override chargé")
    end)

    MySQL.ready(function()
        MySQL.Async.fetchAll("SELECT `key`, `value` FROM vfw_config", {}, function(rows)
            if type(rows) == "table" then
                for i = 1, #rows do
                    local row = rows[i]
                    if type(row) == "table" and type(row.key) == "string" then
                        local ok, decoded = pcall(json.decode, row.value)
                        if ok and decoded ~= nil then
                            ConfigManager.Overrides[row.key] = sanitize(decoded, 0, nil)
                        end
                    end
                end
            end

            ConfigManager.Loaded = true
            rebuild()

            console.init("ConfigManager", ("%d override(s) chargé(s)"):format(#(rows or {})))
        end)
    end)
end

CreateThread(function()
    Wait(0)

    RegisterServerCallback("ConfigManager:getConfig", function()
        return ConfigManager.Get()
    end)

    loadOverrides()

    while type(VFW.RegisterCommand) ~= "function" do Wait(100) end

    VFW.RegisterCommand("configreload", "dev_tools", function(_, xPlayer)
        ConfigManager.Refresh()
        console.info("[ConfigManager] instantané reconstruit")

        if xPlayer then
            xPlayer.showNotification({
                type = "STAFF",
                variant = "SUCCESS",
                subtitle = "ConfigManager",
                message = "Configuration serveur rechargée.",
            })
        end
    end, {
        help = "Reconstruire l'instantané de configuration envoyé aux clients",
        params = {},
        allowConsole = true,
    })
end)

AddEventHandler("core:configManager:invalidate", function()
    dirty = true
end)
