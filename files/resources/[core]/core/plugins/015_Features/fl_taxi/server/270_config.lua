Feat27 = Feat27 or {}

TaxiServer = TaxiServer or {}

local function config()
    return (TaxiJob and TaxiJob.Config) or {}
end

function TaxiServer.IsTaxi(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    local job = VFW.Jobs and VFW.Jobs[xPlayer.job.name]
    if not job then return false end
    return job.type == "taxi"
end

function TaxiServer.IsOnDuty(xPlayer)
    if not TaxiServer.IsTaxi(xPlayer) then return false end
    return xPlayer.job.onDuty == true
end

function TaxiServer.GetPhone(source)
    local ok, number = pcall(function()
        return exports["lb-phone"]:GetEquippedPhoneNumber(source)
    end)
    if ok and type(number) == "string" and number ~= "" then return number end
    return nil
end

function TaxiServer.SocietyConfig(jobName)
    local job = VFW.Jobs and VFW.Jobs[jobName]
    if not job or job.type ~= "taxi" then return nil end

    local defaults = config()

    local allowed = Feat27.Society.GetAddonTable(jobName, "allowedVehicles", nil)
    if type(allowed) ~= "table" or #allowed == 0 then
        allowed = defaults.AllowedVehicles or {}
    end

    local zoneRows = MySQL.query.await("SELECT `zone_key` FROM taxi_enabled_base_zones WHERE `society` = ?", { jobName }) or {}
    local enabledBaseZones = {}
    for i = 1, #zoneRows do
        enabledBaseZones[#enabledBaseZones + 1] = zoneRows[i].zone_key
    end
    if #enabledBaseZones == 0 then
        for _, zone in ipairs(defaults.BaseZones or {}) do
            enabledBaseZones[#enabledBaseZones + 1] = zone.key
        end
    end

    local spawnRows = MySQL.query.await("SELECT `x`, `y`, `z`, `radius` FROM taxi_spawn_zones WHERE `society` = ?", { jobName }) or {}
    local taxiSpawnZones = {}
    for i = 1, #spawnRows do
        local row = spawnRows[i]
        taxiSpawnZones[i] = {
            x = row.x + 0.0,
            y = row.y + 0.0,
            z = row.z + 0.0,
            radius = (row.radius or defaults.DefaultZoneRadius or 1000.0) + 0.0,
        }
    end

    return {
        label = job.label or jobName,
        tarifPerMeter = Feat27.Society.GetAddonNumber(jobName, "tarifPerMeter", defaults.DefaultTarifPerMeter or 0.50),
        playerPercent = Feat27.Society.GetAddonNumber(jobName, "playerPercent", defaults.DefaultPlayerPercent or 80),
        commandTimeout = Feat27.Society.GetAddonNumber(jobName, "commandTimeout", defaults.DefaultCommandTimeout or 10),
        allowedVehicles = allowed,
        enabledBaseZones = enabledBaseZones,
        taxiSpawnZones = taxiSpawnZones,
    }
end

RegisterServerCallback("taxi:isJobTaxi", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    return TaxiServer.IsTaxi(xPlayer) == true
end)

RegisterServerCallback("taxi:getSocietyConfig", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    return TaxiServer.SocietyConfig(xPlayer.job.name)
end)

function Feat27.TaxiSetSpawnZone(society, coords, radius)
    local pos = Feat27.Vec3(coords)
    if type(society) ~= "string" or not pos then return false end
    MySQL.insert.await("INSERT INTO taxi_spawn_zones (`society`, `x`, `y`, `z`, `radius`) VALUES (?, ?, ?, ?, ?)", {
        society, pos.x, pos.y, pos.z, tonumber(radius) or 500.0,
    })
    return true
end

function Feat27.TaxiSetBaseZone(society, zoneKey, enabled)
    if type(society) ~= "string" or type(zoneKey) ~= "string" then return false end
    if enabled then
        MySQL.query.await("INSERT IGNORE INTO taxi_enabled_base_zones (`society`, `zone_key`) VALUES (?, ?)", { society, zoneKey })
    else
        MySQL.query.await("DELETE FROM taxi_enabled_base_zones WHERE `society` = ? AND `zone_key` = ?", { society, zoneKey })
    end
    return true
end
