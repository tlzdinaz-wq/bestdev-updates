VFW.Logs = VFW.Logs or {}

local COLORS = {
    default = 3447003,
    success = 3066993,
    warning = 16776960,
    error = 15158332,
    death = 10038562,
    staff = 10181046,
}

local function resolveWebhook(path)
    if type(path) ~= "string" or path == "" then return nil end

    -- Surcharge depuis Gestion > Développeurs > Webhooks logs ("" = désactivé)
    if VFW.GetWebhookOverride then
        local override = VFW.GetWebhookOverride(path)
        if override == "" then return nil end
        if type(override) == "string" then return override end
    end

    if type(logs) ~= "table" or type(logs.config) ~= "table" then return nil end

    local node = logs.config
    for part in path:gmatch("[^%.]+") do
        if type(node) ~= "table" then return nil end
        node = node[part]
    end

    if type(node) == "string" and node ~= "" then return node end
    return nil
end

-- ── Historique (Gestion > Développeurs > Staff logs) ──
local RECENT_MAX = 100
local QUEUE_MAX = 200
local recent = {}       -- derniers logs envoyés (plus récent en premier)
local failed = {}       -- envois en échec, retentés toutes les 60 s
local lastError = nil   -- { statusCode, errorCount }

local function describeLog(path, embed)
    local category, kind = path:match("^([^%.]+)%.(.+)$")
    return {
        category = category or path,
        type = kind or path,
        message = tostring(embed.title or "") .. (embed.description and (" — " .. tostring(embed.description):sub(1, 300)) or ""),
        source = VFW.BrandName(),
        timestamp = os.date("%d/%m/%Y %H:%M:%S"),
    }
end

local function pushRecent(entry)
    table.insert(recent, 1, entry)
    if #recent > RECENT_MAX then table.remove(recent) end
end

local function postWebhook(webhook, body, onDone)
    PerformHttpRequest(webhook, function(status)
        if onDone then onDone(status) end
    end, "POST", body, { ["Content-Type"] = "application/json" })
end

function VFW.Logs.Recent() return recent end
function VFW.Logs.ClearRecent() recent = {} end
function VFW.Logs.ClearQueue() failed = {} lastError = nil end
function VFW.Logs.DeleteQueued(index)
    index = tonumber(index)
    if index and failed[index] then table.remove(failed, index) end
    if #failed == 0 then lastError = nil end
end
function VFW.Logs.Queue()
    local out = {}
    for i, job in ipairs(failed) do
        local e = job.entry
        out[i] = { index = i, category = e.category, type = e.type, message = e.message, source = e.source, timestamp = e.timestamp }
    end
    local info = lastError and { statusCode = lastError.statusCode, errorCount = lastError.errorCount, count = #failed } or nil
    return out, info
end

-- Nouvelle tentative périodique des logs en échec
CreateThread(function()
    while true do
        Wait(60000)
        if #failed > 0 then
            local job = table.remove(failed, 1)
            local webhook = resolveWebhook(job.path)
            if webhook then
                postWebhook(webhook, job.body, function(status)
                    if status ~= 200 and status ~= 204 then
                        job.entry.errorCount = (job.entry.errorCount or 0) + 1
                        if #failed < QUEUE_MAX then table.insert(failed, job) end
                        lastError = { statusCode = status, errorCount = (lastError and lastError.errorCount or 0) + 1 }
                    elseif #failed == 0 then
                        lastError = nil
                    end
                end)
            end
        end
    end
end)

function VFW.Logs.Send(path, embed)
    local webhook = resolveWebhook(path)
    if not webhook then return false end
    if type(embed) ~= "table" then return false end

    embed.color = embed.color or COLORS.default
    embed.footer = embed.footer or { text = VFW.BrandName() }
    embed.timestamp = embed.timestamp or os.date("!%Y-%m-%dT%H:%M:%SZ")

    local body = json.encode({
        username = VFW.BrandName(),
        embeds = { embed },
    })
    local entry = describeLog(path, embed)
    pushRecent(entry)

    postWebhook(webhook, body, function(status)
        if status ~= 200 and status ~= 204 then
            lastError = { statusCode = status, errorCount = (lastError and lastError.errorCount or 0) + 1 }
            if #failed < QUEUE_MAX then
                failed[#failed + 1] = { path = path, body = body, entry = entry }
            end
        end
    end)

    return true
end

function VFW.Logs.Simple(path, title, description, color)
    return VFW.Logs.Send(path, {
        title = tostring(title),
        description = tostring(description),
        color = COLORS[color] or color or COLORS.default,
    })
end

function VFW.Logs.Describe(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer then
        return ("%s %s (#%d | %s)"):format(xPlayer.firstName or "?", xPlayer.lastName or "?", xPlayer.source, xPlayer.identifier or "?")
    end
    if tonumber(source) and GetPlayerName(source) then
        return ("%s (#%s)"):format(GetPlayerName(source), tostring(source))
    end
    return ("#%s"):format(tostring(source))
end

local function charIdOf(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    return xPlayer and xPlayer.charId or 0
end

local function encode(value)
    if value == nil then return nil end
    local ok, encoded = pcall(json.encode, value)
    if ok then return encoded end
    return nil
end

local function text(value, limit)
    if type(value) ~= "string" then return "" end
    return value:sub(1, limit)
end

function VFW.Logs.Staff(source, action, payload)
    if type(action) ~= "string" then return end

    MySQL.insert("INSERT INTO logs_staff (source_id, char_id, action, payload) VALUES (?, ?, ?, ?)", {
        tonumber(source) or 0,
        charIdOf(source),
        action:sub(1, 64),
        encode(payload) or "{}",
    })
end

AddEventHandler("vfw:logs:staff", function(source, action, payload)
    VFW.Logs.Staff(source, action, payload)

    if action == "tpm" and type(payload) == "table" then
        VFW.Logs.Send("staff.teleport", {
            title = "Teleportation au marqueur",
            description = ("%s\nDe : `%s`\nVers : `%s`"):format(
                VFW.Logs.Describe(source), encode(payload.from) or "?", encode(payload.to) or "?"),
            color = COLORS.staff,
        })
    elseif action == "antiattach" and type(payload) == "table" then
        VFW.Logs.Send("ac.antiAttach", {
            title = "AntiAttach",
            description = ("%s a %s le scan anti-attach."):format(
                VFW.Logs.Describe(source), payload.enabled and "active" or "desactive"),
            color = COLORS.warning,
        })
    end
end)

AddEventHandler("vfw:logs:death", function(source, data)
    if type(data) ~= "table" then return end

    local killedByPlayer = data.killedByPlayer and true or false

    MySQL.insert([[
        INSERT INTO logs_death
            (char_id, source_id, victim_coords, killer_coords, killer_server_id, death_cause,
             computed_cause, bone_part, is_headshot, distance, status_damage_source,
             death_override, killed_by_player, victim_context, killer_context)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        charIdOf(source),
        tonumber(source) or 0,
        encode(data.victimCoords) or "",
        encode(data.killerCoords) or "",
        tonumber(data.killerServerId) or 0,
        tonumber(data.deathCause) or 0,
        text(data.computedCause, 64),
        text(data.bonePart, 32),
        data.isHeadshot and 1 or 0,
        tonumber(data.distance) or 0.0,
        text(data.statusDamageSource, 16),
        text(data.deathOverride, 32),
        killedByPlayer and 1 or 0,
        encode(data.victimContext) or "",
        encode(data.killerContext) or "",
    })

    local channel = killedByPlayer and "general.killPlayer" or "general.killSuicide"
    local lines = {
        ("Victime : %s"):format(VFW.Logs.Describe(source)),
    }

    if killedByPlayer then
        lines[#lines + 1] = ("Tueur : %s"):format(VFW.Logs.Describe(data.killerServerId))
        lines[#lines + 1] = ("Distance : %.1f m"):format(tonumber(data.distance) or 0.0)
    end

    if data.computedCause then
        lines[#lines + 1] = ("Cause : %s"):format(tostring(data.computedCause))
    end
    if data.bonePart then
        lines[#lines + 1] = ("Zone : %s%s"):format(tostring(data.bonePart), data.isHeadshot and " (headshot)" or "")
    end
    if data.statusDamageSource then
        lines[#lines + 1] = ("Statut : %s"):format(tostring(data.statusDamageSource))
    end
    if data.deathOverride then
        lines[#lines + 1] = ("Override : %s"):format(tostring(data.deathOverride))
    end

    VFW.Logs.Send(channel, {
        title = killedByPlayer and "Mort par joueur" or "Mort",
        description = table.concat(lines, "\n"),
        color = COLORS.death,
    })
end)

AddEventHandler("vfw:ac:flag", function(source, kind, details)
    if type(kind) ~= "string" then return end

    VFW.Logs.Staff(source, "ac:" .. kind, details)

    local channel = kind == "attach_exploit" and "ac.antiAttach" or "ac.entityCreated"
    VFW.Logs.Send(channel, {
        title = "Anticheat",
        description = ("%s\nType : `%s`%s"):format(
            VFW.Logs.Describe(source), kind,
            details and ("\n```" .. (encode(details) or "") .. "```") or ""),
        color = COLORS.error,
    })

    console.warn(("[AC] %s -> %s"):format(VFW.Logs.Describe(source), kind))
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    VFW.Logs.Send("general.connect", {
        title = "Connexion",
        description = ("%s %s (#%d)\nLicence : `%s`"):format(
            xPlayer.firstName or "?", xPlayer.lastName or "?", source, xPlayer.identifier or "?"),
        color = COLORS.success,
    })
end)

AddEventHandler("vfw:playerDropped", function(source, xPlayer)
    VFW.Logs.Send("general.disconnect", {
        title = "Deconnexion",
        description = ("%s %s (#%d)"):format(xPlayer.firstName or "?", xPlayer.lastName or "?", source),
        color = COLORS.warning,
    })
end)
