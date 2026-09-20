local CONFIG = AntiAttachConfig or {}
local BAN = CONFIG.serverBan or {}

local blacklisted = {}

for _, hash in ipairs(CONFIG.blacklistedModels or {}) do
    local value = tonumber(hash)
    if value then
        local h = math.floor(value)
        blacklisted[h] = true
        if h < 0 then
            blacklisted[h + 0x100000000] = true
        elseif h > 0x7FFFFFFF then
            blacklisted[h - 0x100000000] = true
        end
    end
end

local function isBlacklistedModel(model)
    if not model or model == 0 then return false end
    return blacklisted[math.floor(model)] == true
end

local reportRateLimit = {}
local attackerReports = {}
local handledNetIds = {}
local bannedLicenses = {}

local function sqlInsert(query, params)
    local ok, res = pcall(MySQL.insert.await, query, params)
    if not ok then
        console.error(("[AntiAttach] SQL: %s"):format(tostring(res)))
        return nil
    end
    return res
end

local function sqlUpdate(query, params)
    local ok, res = pcall(MySQL.update.await, query, params)
    if not ok then
        console.error(("[AntiAttach] SQL: %s"):format(tostring(res)))
        return nil
    end
    return res
end

local function licenseOf(playerSource)
    local ok, identifier = pcall(VFW.GetIdentifier, playerSource)
    if ok and type(identifier) == "string" then return identifier end
    return nil
end

local function coordsOf(playerSource)
    local ped = GetPlayerPed(playerSource)
    if not ped or ped == 0 then return nil end
    local coords = GetEntityCoords(ped)
    if not coords then return nil end
    return coords
end

local function distanceBetween(a, b)
    if not a or not b then return nil end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function isAttachedToVictim(entity, victimSource)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end

    local victimPed = GetPlayerPed(victimSource)
    if not victimPed or victimPed == 0 then return false end

    local ok, parent = pcall(GetEntityAttachedTo, entity)
    if ok and tonumber(parent) and math.floor(tonumber(parent)) == victimPed then return true end

    local okPed, pedParent = pcall(GetEntityAttachedTo, victimPed)
    if okPed and tonumber(pedParent) and math.floor(tonumber(pedParent)) == entity then return true end

    return false
end

local function isProtected(attackerSource)
    local xPlayer = VFW.GetPlayerFromId(attackerSource)
    if not xPlayer then return false end

    local list = BAN.bypassPermissions or {}
    for i = 1, #list do
        if xPlayer.hasPermission(list[i]) then return true end
    end

    return false
end

local function purge(now)
    local window = tonumber(BAN.reportWindowMs) or 20000

    for key, entry in pairs(attackerReports) do
        if (now - entry.last) > window then
            attackerReports[key] = nil
        end
    end

    for key, expires in pairs(reportRateLimit) do
        if now > expires then
            reportRateLimit[key] = nil
        end
    end

    for netId, expires in pairs(handledNetIds) do
        if now > expires then
            handledNetIds[netId] = nil
        end
    end
end

local function logReport(payload)
    sqlInsert([[
        INSERT INTO anticheat_attach_reports
            (net_id, model, victim_identifier, victim_source, attacker_identifier, attacker_source,
             attacker_name, distance, outcome, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.netId or 0,
        payload.model or 0,
        payload.victimIdentifier or "",
        payload.victimSource or 0,
        payload.attackerIdentifier or "",
        payload.attackerSource or 0,
        payload.attackerName or "",
        payload.distance or 0.0,
        payload.outcome or "report",
        os.date("%Y-%m-%d %H:%M:%S"),
    })
end

local function banAttacker(attackerSource, license, reason, extra)
    if license and bannedLicenses[license] then return false end
    if license then bannedLicenses[license] = true end

    local xPlayer = VFW.GetPlayerFromId(attackerSource)
    local playerName = GetPlayerName(attackerSource) or "unknown"

    if xPlayer and xPlayer.accountId then
        sqlUpdate("UPDATE users SET banned = 1 WHERE id = ?", { xPlayer.accountId })
    elseif license then
        sqlUpdate("UPDATE users SET banned = 1 WHERE identifier = ?", { license })
    end

    sqlInsert([[
        INSERT INTO anticheat_bans (identifier, license, player_name, reason, kind, created_at)
        VALUES (?, ?, ?, ?, 'anti_attach', ?)
    ]], {
        xPlayer and xPlayer.identifier or "",
        license or "",
        playerName,
        reason,
        os.date("%Y-%m-%d %H:%M:%S"),
    })

    if VFW.SendAntiCheat then
        VFW.SendAntiCheat({
            channel = "antiAttach",
            source = attackerSource,
            identifier = license or "",
            reason = reason,
            webhook = type(BAN.webhook) == "string" and BAN.webhook or "",
            extra = extra,
        })
    end

    DropPlayer(attackerSource, reason)

    console.warn(("[AntiAttach] %s (#%d) banni : %s"):format(playerName, attackerSource, reason))

    return true
end

RegisterNetEvent("eve:antiAttach:report", function(netId, victimServerId)
    local source = source

    if type(netId) ~= "number" or type(victimServerId) ~= "number" then return end
    if netId ~= netId or victimServerId ~= victimServerId then return end

    netId = math.floor(netId)
    victimServerId = math.floor(victimServerId)

    if netId <= 0 or victimServerId <= 0 then return end
    if CONFIG.enabled == false then return end
    if GlobalState.AntiAttachEnabled == false then return end

    local now = GetGameTimer()
    purge(now)

    local reporterKey = ("r:%d"):format(source)
    if reportRateLimit[reporterKey] and now < reportRateLimit[reporterKey] then return end
    reportRateLimit[reporterKey] = now + math.max(500, tonumber(BAN.rateLimitMs) or 3000)

    local entity = NetworkGetEntityFromNetworkId(netId)
    local model = 0

    if entity and entity ~= 0 and DoesEntityExist(entity) then
        model = GetEntityModel(entity) or 0
        if model ~= 0 and not isBlacklistedModel(model) then return end
    end

    local victim = VFW.GetPlayerFromId(victimServerId)
    local victimIdentifier = victim and victim.identifier or (licenseOf(victimServerId) or "")

    local attachProven = isAttachedToVictim(entity, victimServerId)

    local attackerSource = 0
    if entity and entity ~= 0 then
        local ok, owner = pcall(NetworkGetFirstEntityOwner, entity)
        if ok and tonumber(owner) then attackerSource = math.floor(tonumber(owner)) end

        if attackerSource <= 0 then
            local okOwner, current = pcall(NetworkGetEntityOwner, entity)
            if okOwner and tonumber(current) then attackerSource = math.floor(tonumber(current)) end
        end
    end

    if entity and entity ~= 0 and DoesEntityExist(entity) then
        pcall(DeleteEntity, entity)
    end

    if attackerSource <= 0 or attackerSource == victimServerId then
        if not handledNetIds[netId] then
            handledNetIds[netId] = now + 60000
            logReport({
                netId = netId,
                model = model,
                victimIdentifier = victimIdentifier,
                victimSource = victimServerId,
                outcome = "unresolved",
            })
        end
        return
    end

    local attackerLicense = licenseOf(attackerSource)
    if not attackerLicense then return end

    local pairKey = ("%d>%d"):format(victimServerId, attackerSource)
    if reportRateLimit[pairKey] and now < reportRateLimit[pairKey] then return end
    reportRateLimit[pairKey] = now + math.max(500, tonumber(BAN.rateLimitMs) or 3000)

    local distance = distanceBetween(coordsOf(attackerSource), coordsOf(victimServerId)) or 0.0
    local maxDistance = tonumber(BAN.maxAttackDistance) or 0.0

    if maxDistance > 0.0 and distance > maxDistance then
        logReport({
            netId = netId,
            model = model,
            victimIdentifier = victimIdentifier,
            victimSource = victimServerId,
            attackerIdentifier = attackerLicense,
            attackerSource = attackerSource,
            attackerName = GetPlayerName(attackerSource) or "",
            distance = distance,
            outcome = "too_far",
        })
        return
    end

    if isProtected(attackerSource) then
        logReport({
            netId = netId,
            model = model,
            victimIdentifier = victimIdentifier,
            victimSource = victimServerId,
            attackerIdentifier = attackerLicense,
            attackerSource = attackerSource,
            attackerName = GetPlayerName(attackerSource) or "",
            distance = distance,
            outcome = "bypass",
        })
        return
    end

    local entry = attackerReports[attackerLicense]
    if not entry then
        entry = { victims = {}, count = 0, last = now }
        attackerReports[attackerLicense] = entry
    end

    entry.last = now

    local victimKey = victimIdentifier ~= "" and victimIdentifier or tostring(victimServerId)
    if not entry.victims[victimKey] then
        entry.victims[victimKey] = now
        entry.count = entry.count + 1
    end

    local minVictims = math.max(1, tonumber(BAN.minUniqueVictims) or 1)
    local shouldBan = BAN.banAttacker == true and entry.count >= minVictims and attachProven

    logReport({
        netId = netId,
        model = model,
        victimIdentifier = victimIdentifier,
        victimSource = victimServerId,
        attackerIdentifier = attackerLicense,
        attackerSource = attackerSource,
        attackerName = GetPlayerName(attackerSource) or "",
        distance = distance,
        outcome = shouldBan and "ban" or (attachProven and "report" or "unproven"),
    })

    TriggerEvent("vfw:ac:flag", attackerSource, "attach_exploit", {
        reason = "Attache d'objet sur un joueur",
        netId = netId,
        victim = victimServerId,
        distance = distance,
        victims = entry.count,
    })

    handledNetIds[netId] = now + 60000

    if not shouldBan then return end

    attackerReports[attackerLicense] = nil

    local reason = type(BAN.banReason) == "string" and BAN.banReason ~= ""
        and BAN.banReason
        or "EVE AC | Exploit d'attache d'objet (propulsion joueur)"

    banAttacker(attackerSource, attackerLicense, reason, {
        netId = netId,
        model = model,
        victims = entry.count,
        distance = distance,
    })
end)

AddEventHandler("playerDropped", function()
    local source = source
    reportRateLimit[("r:%d"):format(source)] = nil
end)
