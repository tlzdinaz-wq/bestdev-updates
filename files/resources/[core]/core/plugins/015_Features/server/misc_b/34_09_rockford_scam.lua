local sessions = {}
local liveStreams = {}
local exportBuffers = {}

local function studios()
    if type(Config) == "table" and type(Config.RockfordStudio) == "table" and type(Config.RockfordStudio.Studios) == "table" then
        return Config.RockfordStudio.Studios
    end
    return {}
end

local function findStudio(studioId)
    local list = studios()
    for i = 1, #list do
        if tostring(list[i].id) == tostring(studioId) then return list[i] end
    end
    return nil
end

local function canAccessStudio(xPlayer, studio)
    if not studio then return false end
    local required = studio.requiredJob
    if required == nil then return true end

    local job = MiscB.JobName(xPlayer)
    if not job then return false end
    if type(required) == "string" then return job == required end
    if type(required) == "table" then
        for i = 1, #required do
            if required[i] == job then return true end
        end
    end
    return false
end

MiscB.Cb("rockfordstudio:canAccess", function(source, studioId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    local studio = findStudio(studioId)
    if not studio then return false end
    return canAccessStudio(xPlayer, studio)
end)

MiscB.Cb("rockfordstudio:hasSession", function(source, studioId)
    local id = studioId ~= nil and tostring(studioId) or nil
    if not id then return false end
    local session = sessions[id]
    return session ~= nil and session.singer ~= nil
end)

MiscB.Cb("vfw:staff:getAllStudios", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local out = {}
    local list = studios()
    for i = 1, #list do
        local studio = list[i]
        out[#out + 1] = {
            id = studio.id,
            name = studio.name,
            coords = MiscB.Plain(studio.coords),
            mixingTable = studio.mixingTable and MiscB.Plain(studio.mixingTable.coords) or nil,
            blip = studio.blip,
            requiredJob = studio.requiredJob,
            liveZoneRadius = studio.liveZoneRadius,
            hasSession = sessions[tostring(studio.id)] ~= nil,
        }
    end
    return out
end)

RegisterNetEvent("rockfordstudio:createSession", function(studioId)
    local source = source
    if studioId == nil then return end
    local id = tostring(studioId)

    local xPlayer = VFW.GetPlayerFromId(source)
    local studio = findStudio(id)
    if not xPlayer or not studio then return end
    if not canAccessStudio(xPlayer, studio) then return end

    local session = sessions[id]
    if session and session.singer and session.singer ~= source then
        TriggerClientEvent("rockfordstudio:sessionEnded", source, id, "Un artiste occupe deja ce studio.")
        return
    end

    sessions[id] = sessions[id] or { engineers = {} }
    sessions[id].singer = source
    sessions[id].singerName = MiscB.CharName(xPlayer)

    TriggerClientEvent("rockfordstudio:sessionCreated", source, id)
end)

RegisterNetEvent("rockfordstudio:joinSession", function(studioId)
    local source = source
    if studioId == nil then return end
    local id = tostring(studioId)

    local xPlayer = VFW.GetPlayerFromId(source)
    local studio = findStudio(id)
    if not xPlayer or not studio then return end

    local session = sessions[id]
    if not session or not session.singer then
        TriggerClientEvent("rockfordstudio:sessionEnded", source, id, "Aucune session en cours.")
        return
    end

    session.engineers[source] = MiscB.CharName(xPlayer)

    TriggerClientEvent("rockfordstudio:sessionJoined", source, id, session.singerName or "Artiste")
    TriggerClientEvent("rockfordstudio:engineerJoined", session.singer, id, MiscB.CharName(xPlayer))
end)

local function leaveSession(source, studioId, reason)
    local id = studioId ~= nil and tostring(studioId) or nil
    if not id then
        for key, session in pairs(sessions) do
            if session.singer == source or session.engineers[source] then
                leaveSession(source, key, reason)
            end
        end
        return
    end

    local session = sessions[id]
    if not session then return end

    if session.singer == source then
        for engineer in pairs(session.engineers) do
            TriggerClientEvent("rockfordstudio:sessionEnded", engineer, id, reason or "L'artiste a quitte la session.")
        end
        sessions[id] = nil
        return
    end

    if session.engineers[source] then
        session.engineers[source] = nil
        if session.singer then
            TriggerClientEvent("rockfordstudio:sessionEnded", session.singer, id, reason or "L'ingenieur a quitte la session.")
        end
    end
end

RegisterNetEvent("rockfordstudio:leaveSession", function(sessionStudioId)
    local source = source
    leaveSession(source, sessionStudioId)
end)

RegisterNetEvent("rockfordstudio:studioTransport", function(sessionStudioId, action, data)
    local source = source
    if sessionStudioId == nil or type(action) ~= "string" or #action > 32 then return end
    local id = tostring(sessionStudioId)

    local session = sessions[id]
    if not session or not session.singer then return end
    if not session.engineers[source] then return end

    local payload = type(data) == "table" and data or {}
    payload.engineerName = session.engineers[source]

    TriggerClientEvent("rockfordstudio:singerTransport", session.singer, action, payload)
end)

RegisterNetEvent("rockfordstudio:recordingComplete", function(sessionStudioId, data)
    local source = source
    if sessionStudioId == nil or type(data) ~= "table" then return end
    local id = tostring(sessionStudioId)

    local session = sessions[id]
    if not session or session.singer ~= source then return end

    for engineer in pairs(session.engineers) do
        TriggerClientEvent("rockfordstudio:recordingReady", engineer, data)
    end
end)

RegisterNetEvent("rockfordstudio:playLive", function(studioId, url, volume)
    local source = source
    if studioId == nil then return end
    local id = tostring(studioId)
    local link = MiscB.Str(url, 512)
    if not link or link == "" then return end
    if not link:match("^https?://") then return end

    local studio = findStudio(id)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not studio or not xPlayer then return end
    if not canAccessStudio(xPlayer, studio) then return end
    if not MiscB.Rate(source, "rockfordlive", 1000) then return end

    local vol = MiscB.ToNum(volume, 0.5)
    if vol < 0.0 then vol = 0.0 end
    if vol > 1.0 then vol = 1.0 end

    liveStreams[id] = { url = link, volume = vol, owner = source }

    local radius = tonumber(studio.liveZoneRadius) or 15.0
    local center = MiscB.Vec3(studio.coords)
    local nearby = center and VFW.GetPlayersInRadius(center, radius + 30.0) or {}
    for i = 1, #nearby do
        TriggerClientEvent("rockfordstudio:playLive", nearby[i].source, id, link, vol)
    end
end)

RegisterNetEvent("rockfordstudio:stopLive", function(studioId)
    local source = source
    if studioId == nil then return end
    local id = tostring(studioId)

    local stream = liveStreams[id]
    if not stream then return end
    liveStreams[id] = nil

    TriggerClientEvent("rockfordstudio:stopLive", -1, id)
end)

local MAX_EXPORT_CHUNKS = 400
local MAX_CHUNK_SIZE = 600000

RegisterNetEvent("rockfordstudio:exportStart", function(exportId, filename, totalChunks)
    local source = source
    local id = MiscB.Str(exportId, 64)
    local name = MiscB.Str(filename, 128)
    local total = MiscB.ToInt(totalChunks, 1, MAX_EXPORT_CHUNKS)
    if not id or not name or not total then return end

    exportBuffers[source] = exportBuffers[source] or {}
    exportBuffers[source][id] = { filename = name, total = total, chunks = {}, received = 0 }
end)

RegisterNetEvent("rockfordstudio:exportChunk", function(exportId, chunkIndex, chunk)
    local source = source
    local id = MiscB.Str(exportId, 64)
    local index = MiscB.ToInt(chunkIndex, 1, MAX_EXPORT_CHUNKS)
    if not id or not index or type(chunk) ~= "string" then return end
    if #chunk > MAX_CHUNK_SIZE then return end

    local buffers = exportBuffers[source]
    if not buffers or not buffers[id] then return end
    local buffer = buffers[id]
    if index > buffer.total then return end
    if buffer.chunks[index] ~= nil then return end

    buffer.chunks[index] = chunk
    buffer.received = buffer.received + 1
end)

RegisterNetEvent("rockfordstudio:exportFinish", function(exportId)
    local source = source
    local id = MiscB.Str(exportId, 64)
    if not id then return end

    local buffers = exportBuffers[source]
    if not buffers or not buffers[id] then
        TriggerClientEvent("rockfordstudio:exportResult", source, { success = false, error = "Export introuvable." })
        return
    end

    local buffer = buffers[id]
    buffers[id] = nil

    if buffer.received < buffer.total then
        TriggerClientEvent("rockfordstudio:exportResult", source, { success = false, error = "Transfert incomplet." })
        return
    end

    local parts = {}
    for i = 1, buffer.total do
        parts[#parts + 1] = buffer.chunks[i] or ""
    end
    local base64 = table.concat(parts)

    local xPlayer = VFW.GetPlayerFromId(source)
    local recordingId = MiscB.Insert([[
        INSERT INTO rockford_recordings (identifier, char_id, filename, payload, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ]], { xPlayer and xPlayer.identifier or "", xPlayer and xPlayer.charId or nil, buffer.filename, base64 })

    local endpoint = GetConvar("rockford_upload_url", "")
    if endpoint == "" then
        TriggerClientEvent("rockfordstudio:exportResult", source, {
            success = false,
            recordingId = recordingId,
            error = "Aucun hebergeur audio configure (convar rockford_upload_url).",
        })
        return
    end

    PerformHttpRequest(endpoint, function(status, body)
        if status ~= 200 and status ~= 201 then
            TriggerClientEvent("rockfordstudio:exportResult", source, { success = false, error = "Upload refuse (" .. tostring(status) .. ")." })
            return
        end

        local decoded = VFW.DB.Decode(body, nil)
        local url = type(decoded) == "table" and (decoded.url or decoded.link) or body

        MiscB.Update("UPDATE rockford_recordings SET url = ? WHERE id = ?", { url, recordingId })
        TriggerClientEvent("rockfordstudio:exportResult", source, { success = true, url = url, recordingId = recordingId })
    end, "POST", VFW.DB.Encode({ filename = buffer.filename, base64 = base64 }), { ["Content-Type"] = "application/json" })
end)

MiscB.Cb("rockfordstudio:resolveAudioUrl", function(source, url)
    local link = MiscB.Str(url, 512)
    if not link or not link:match("^https?://") then return nil end

    local proxy = GetConvar("rockford_resolver_url", "")
    if proxy == "" then return link end

    local promiseDone, resolved = false, nil
    PerformHttpRequest(proxy, function(status, body)
        if status == 200 then
            local decoded = VFW.DB.Decode(body, nil)
            if type(decoded) == "table" then
                resolved = decoded.url or decoded.link
            end
        end
        promiseDone = true
    end, "POST", VFW.DB.Encode({ url = link }), { ["Content-Type"] = "application/json" })

    local waited = 0
    while not promiseDone and waited < 10000 do
        Wait(100)
        waited = waited + 100
    end

    return resolved or link
end)

AddEventHandler("vfw:playerDropped", function(source)
    leaveSession(source, nil, "Le joueur s'est deconnecte.")
    exportBuffers[source] = nil
    for id, stream in pairs(liveStreams) do
        if stream.owner == source then
            liveStreams[id] = nil
            TriggerClientEvent("rockfordstudio:stopLive", -1, id)
        end
    end
end)

local function scamDefaults()
    return {
        balance = 0,
        activeScams = {},
        transactions = {},
        currentLeads = {},
        usedLeadIds = {},
        lastLeadsGenerationTime = 0,
    }
end

local function loadScam(xPlayer)
    local row = MiscB.Single(
        "SELECT data FROM scam_computer_data WHERE identifier = ? LIMIT 1",
        { xPlayer.identifier }
    )
    if not row then return scamDefaults() end

    local decoded = VFW.DB.Decode(row.data, nil)
    if type(decoded) ~= "table" then return scamDefaults() end

    local defaults = scamDefaults()
    for key, value in pairs(defaults) do
        if decoded[key] == nil then decoded[key] = value end
    end
    return decoded
end

local function saveScam(xPlayer, data)
    MiscB.Update([[
        INSERT INTO scam_computer_data (identifier, data, updated_at) VALUES (?, ?, NOW())
        ON DUPLICATE KEY UPDATE data = VALUES(data), updated_at = NOW()
    ]], { xPlayer.identifier, VFW.DB.Encode(data) })
end

local function scamHolder(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    local item = (type(ScamConfig) == "table" and ScamConfig.Item) or "scam_tablet"
    if not xPlayer.haveItem(item, 1) then return nil end
    return xPlayer
end

RegisterNetEvent("scamComputer:loadData", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "scamload", 500) then return end

    TriggerClientEvent("scamComputer:receiveData", source, loadScam(xPlayer))
end)

RegisterNetEvent("scamComputer:saveData", function(data)
    local source = source
    if type(data) ~= "table" then return end

    local xPlayer = scamHolder(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "scamsave", 400) then return end

    local current = loadScam(xPlayer)

    local balance = MiscB.ToNum(data.balance, nil)
    if balance and balance >= 0 and balance <= 100000000 then
        current.balance = math.floor(balance)
    end

    if type(data.scams) == "table" then current.activeScams = data.scams end
    if type(data.activeScams) == "table" then current.activeScams = data.activeScams end
    if type(data.transactions) == "table" then current.transactions = data.transactions end
    if type(data.currentLeads) == "table" then current.currentLeads = data.currentLeads end
    if type(data.usedLeadIds) == "table" then current.usedLeadIds = data.usedLeadIds end
    if tonumber(data.lastLeadsGenerationTime) then
        current.lastLeadsGenerationTime = math.floor(tonumber(data.lastLeadsGenerationTime))
    end

    saveScam(xPlayer, current)
end)

RegisterNetEvent("scamComputer:withdraw", function(amount)
    local source = source
    local xPlayer = scamHolder(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "scamwithdraw", 1000) then return end

    local maxWithdraw = (type(ScamConfig) == "table" and tonumber(ScamConfig.MaxWithdraw)) or 1000000
    local value = MiscB.ToInt(amount, 1, maxWithdraw)
    if not value then return end

    local current = loadScam(xPlayer)
    if (current.balance or 0) < value then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Solde insuffisant." })
        return
    end

    local multiplier = (type(ScamConfig) == "table" and tonumber(ScamConfig.RewardMultiplier)) or 1.0
    local payout = math.floor(value * multiplier)

    current.balance = current.balance - value
    current.transactions = type(current.transactions) == "table" and current.transactions or {}
    current.transactions[#current.transactions + 1] = {
        type = "withdraw",
        amount = payout,
        at = os.time(),
    }
    saveScam(xPlayer, current)

    xPlayer.addAccountMoney("black_money", payout, "scam-computer")
    TriggerClientEvent("scamComputer:receiveData", source, current)
    VFW.ShowNotification(source, { type = "VERT", content = "Retrait effectue." })
end)
