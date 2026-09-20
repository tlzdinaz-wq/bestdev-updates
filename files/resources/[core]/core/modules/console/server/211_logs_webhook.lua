local QUEUE_INTERVAL = 300
local QUEUE_MAX = 500

local queue = {}
local queueSize = 0
local worker = false

if type(logs) == "table" and type(logs.config) == "table" then
    for group, value in pairs(logs.config) do
        if logs[group] == nil then
            logs[group] = value
        end
    end
end

local function hexToInt(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("#", ""):gsub("%s", "")
    if #hex ~= 6 then return nil end
    return tonumber(hex, 16)
end

local VARIANT_COLORS = {
    INFO = hexToInt(BASE_COLORS and BASE_COLORS.INFO) or 2414325,
    SUCCESS = hexToInt(BASE_COLORS and BASE_COLORS.SUCCESS) or 3066993,
    WARNING = hexToInt(BASE_COLORS and BASE_COLORS.WARNING) or 15844367,
    ERROR = hexToInt(BASE_COLORS and BASE_COLORS.ERROR) or 15158332,
}

local function resolveNode(root, path)
    if type(root) ~= "table" then return nil end

    local node = root
    for part in path:gmatch("[^%.]+") do
        if type(node) ~= "table" then return nil end
        node = node[part]
    end

    return node
end

function VFW.GetLogWebhook(path)
    if type(path) ~= "string" or path == "" then return nil end
    if type(logs) ~= "table" then return nil end

    local node = resolveNode(logs.config, path)
    if type(node) ~= "string" or node == "" then
        node = resolveNode(logs, path)
    end

    if type(node) == "string" and node ~= "" and node:sub(1, 4) == "http" then
        return node
    end

    return nil
end

local function pump()
    if worker then return end
    worker = true

    CreateThread(function()
        while queueSize > 0 do
            local job = table.remove(queue, 1)
            queueSize = queueSize - 1

            if job then
                PerformHttpRequest(job.url, function(status, body, headers)
                    if type(job.cb) == "function" then
                        local ok, err = pcall(job.cb, status, body, headers)
                        if not ok then
                            console.error(("[Logs] callback webhook en erreur : %s"):format(tostring(err)))
                        end
                    end

                    if status ~= 200 and status ~= 204 and status ~= 0 then
                        console.warn(("[Logs] webhook HTTP %s pour '%s'"):format(tostring(status), tostring(job.label)))
                    end
                end, "POST", job.body, { ["Content-Type"] = "application/json" })
            end

            Wait(QUEUE_INTERVAL)
        end

        worker = false
    end)
end

function VFW.SendWebhook(url, payload, cb, label)
    if type(url) ~= "string" or url == "" then return false end
    if type(payload) ~= "table" then return false end

    if queueSize >= QUEUE_MAX then
        console.warn("[Logs] file d'attente webhook saturée, message abandonné")
        return false
    end

    local ok, encoded = pcall(json.encode, payload)
    if not ok or type(encoded) ~= "string" then
        console.error("[Logs] payload webhook non sérialisable")
        return false
    end

    queueSize = queueSize + 1
    queue[queueSize] = { url = url, body = encoded, cb = cb, label = label or "webhook" }
    pump()

    return true
end

local function appendField(embed, name, value)
    if value == nil or value == "" then return end
    embed.fields[#embed.fields + 1] = {
        name = tostring(name),
        value = tostring(value),
        inline = true,
    }
end

local function buildEmbed(path, data)
    local embed = {
        title = ("%s • %s"):format(VFW.BrandName(), path),
        description = "",
        color = VARIANT_COLORS.INFO,
        fields = {},
    }

    if type(data) ~= "table" then
        embed.description = tostring(data)
        return embed
    end

    if data.title ~= nil then embed.title = tostring(data.title) end

    if data.description ~= nil then
        embed.description = tostring(data.description)
    elseif data.message ~= nil then
        embed.description = tostring(data.message)
    end

    if type(data.color) == "number" then
        embed.color = data.color
    elseif type(data.color) == "string" then
        embed.color = VARIANT_COLORS[data.color:upper()] or hexToInt(data.color) or embed.color
    elseif type(data.variant) == "string" then
        embed.color = VARIANT_COLORS[data.variant:upper()] or embed.color
    end

    if type(data.image) == "string" and data.image ~= "" then
        embed.image = { url = data.image }
    end

    if type(data.thumbnail) == "string" and data.thumbnail ~= "" then
        embed.thumbnail = { url = data.thumbnail }
    end

    if type(data.footer) == "string" and data.footer ~= "" then
        embed.footer = { text = data.footer }
    end

    if type(data.fields) == "table" then
        for i = 1, #data.fields do
            local field = data.fields[i]
            if type(field) == "table" and field.name ~= nil then
                embed.fields[#embed.fields + 1] = {
                    name = tostring(field.name),
                    value = tostring(field.value ~= nil and field.value or "-"),
                    inline = field.inline ~= false,
                }
            end
        end
    end

    local src = tonumber(data.source)

    if src and src > 0 then
        if type(VFW.Logs) == "table" and type(VFW.Logs.Describe) == "function" then
            appendField(embed, "Joueur", VFW.Logs.Describe(src))
        else
            appendField(embed, "Joueur", ("%s [%d]"):format(GetPlayerName(src) or "?", src))
        end
    end

    if data.target ~= nil then
        appendField(embed, "Cible", tostring(data.target))
    end

    if data.identifier ~= nil then
        appendField(embed, "Identifiant", tostring(data.identifier))
    end

    if embed.description == "" then
        embed.description = "-"
    end

    return embed
end

function VFW.SendLog(path, data, cb)
    if type(path) ~= "string" or path == "" then return false end

    local embed = buildEmbed(path, data)

    if type(VFW.Logs) == "table" and type(VFW.Logs.Send) == "function" then
        return VFW.Logs.Send(path, embed) and true or false
    end

    local url = VFW.GetLogWebhook(path)
    if not url then return false end

    embed.footer = embed.footer or { text = os.date("%d/%m/%Y %H:%M:%S") }

    return VFW.SendWebhook(url, {
        username = ("%s Logs"):format(VFW.BrandName()),
        embeds = { embed },
    }, cb, path)
end

local function panelReport(channel, payload)
    local panelUrl = GetConvar("core_panel_ac_url", "")
    if panelUrl == "" then return false end

    local headers = { ["Content-Type"] = "application/json" }
    local token = GetConvar("core_panel_token", "")

    if token ~= "" then
        headers["Authorization"] = ("Bearer %s"):format(token)
    end

    local ok, encoded = pcall(json.encode, {
        server = VFW.BrandName(),
        channel = channel,
        source = payload.source,
        identifier = payload.identifier,
        reason = payload.reason or payload.description or payload.message,
        extra = payload.extra,
        at = os.time(),
    })

    if not ok then return false end

    PerformHttpRequest(panelUrl, function(status)
        if status ~= 200 and status ~= 201 and status ~= 204 then
            console.warn(("[AntiCheat] remontée panel HTTP %s"):format(tostring(status)))
        end
    end, "POST", encoded, headers)

    return true
end

function VFW.SendAntiCheat(a, b, c)
    local payload

    if type(a) == "table" then
        payload = a
    else
        payload = { source = tonumber(a), description = b, extra = c }
    end

    local channel = type(payload.channel) == "string" and payload.channel or "antiAttach"
    local path = ("ac.%s"):format(channel)
    local reason = payload.reason or payload.description or payload.message or "?"
    local sent = false

    if type(payload.webhook) == "string" and payload.webhook ~= "" then
        payload.variant = payload.variant or "ERROR"
        payload.title = payload.title or ("%s AntiCheat • %s"):format(VFW.BrandName(), channel)

        sent = VFW.SendWebhook(payload.webhook, {
            username = ("%s AntiCheat"):format(VFW.BrandName()),
            embeds = { buildEmbed(path, payload) },
        }, nil, path)
    elseif type(VFW.Logs) == "table" and type(VFW.Logs.Send) == "function" then
        local kind = channel == "antiAttach" and "attach_exploit" or channel

        TriggerEvent("vfw:ac:flag", payload.source, kind, {
            reason = reason,
            identifier = payload.identifier,
            target = payload.target,
            extra = payload.extra,
        })

        sent = true
    else
        payload.variant = payload.variant or "ERROR"
        payload.title = payload.title or ("%s AntiCheat • %s"):format(VFW.BrandName(), channel)
        sent = VFW.SendLog(path, payload)
    end

    if panelReport(channel, payload) then
        sent = true
    end

    console.warn(("[AntiCheat][%s] %s"):format(channel, tostring(reason)))

    return sent
end

exports("SendLog", function(path, data)
    return VFW.SendLog(path, data)
end)

exports("SendAntiCheat", function(payload)
    return VFW.SendAntiCheat(payload)
end)

console.init("Logs", "passerelle webhooks / anticheat prête")
