local megaphoneVolume = {}
local megaphoneSubmix = {}

RegisterNetEvent("megaphone:setVolume", function(volume)
    local source = source
    local vol = MiscB.ToInt(volume, 1, 100)
    if not vol then return end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    megaphoneVolume[source] = vol
    xPlayer.setMeta("megaphoneVolume", vol)
end)

RegisterNetEvent("megaphone:applySubmix", function(state)
    local source = source
    if type(state) ~= "boolean" then return end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    megaphoneSubmix[source] = state
    Player(source).state:set("megaphoneSubmix", state, true)
end)

RegisterNetEvent("megaphone:setTalking", function(state, volume)
    local source = source
    if type(state) ~= "boolean" then return end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local vol = MiscB.ToInt(volume, 1, 100) or megaphoneVolume[source] or 100
    if state then megaphoneVolume[source] = vol end

    Player(source).state:set("megaphoneTalking", state, true)

    local nearby = VFW.GetPlayersInRadius(xPlayer.getCoords(), 120.0)
    for i = 1, #nearby do
        TriggerClientEvent("megaphone:updateTalkingStatus", nearby[i].source, state, source, vol)
    end
end)

local radioSessions = {}
local radioPlayers = {}
local radioNicknames = {}

local function radioKey(radioType, frequency)
    return ("%s:%s"):format(radioType, frequency)
end

local function radioOffset(radioType)
    if RadioConfig and RadioConfig.GetOffset then
        local ok, off = pcall(RadioConfig.GetOffset, radioType)
        if ok and type(off) == "number" then return off end
    end
    return radioType == "job" and 100000 or 0
end

local function radioDisplayName(src)
    local nick = radioNicknames[src]
    if nick and nick.useNickname and type(nick.nickname) == "string" and nick.nickname ~= "" then
        return nick.nickname
    end
    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return ("Joueur %d"):format(src) end
    return MiscB.CharName(xPlayer)
end

local function radioMembers(key)
    local session = radioSessions[key]
    if not session then return {} end
    local out = {}
    for src in pairs(session.members) do
        out[#out + 1] = {
            id = src,
            playerId = src,
            name = radioDisplayName(src),
            talking = session.talking[src] == true,
        }
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function radioPush(key)
    local session = radioSessions[key]
    if not session then return end
    local members = radioMembers(key)
    for src in pairs(session.members) do
        TriggerClientEvent("radio:updateMembers", src, members)
    end
end

local function radioLeave(src, silent)
    local current = radioPlayers[src]
    if not current then return end
    radioPlayers[src] = nil

    local session = radioSessions[current]
    if not session then return end
    session.members[src] = nil
    session.talking[src] = nil

    if next(session.members) == nil then
        radioSessions[current] = nil
        return
    end
    if not silent then radioPush(current) end
end

local function radioJoin(src, radioType, frequency)
    radioLeave(src, true)
    local key = radioKey(radioType, frequency)
    local session = radioSessions[key]
    if not session then
        session = { members = {}, talking = {}, radioType = radioType, frequency = frequency }
        radioSessions[key] = session
    end
    session.members[src] = true
    radioPlayers[src] = key
    return key, session
end

local function radioItemFor(radioType)
    if radioType == "job" then return "radio_job" end
    return "radio_public"
end

RegisterNetEvent("radio:checkItemForRadio", function(radioType)
    local source = source
    local rType = (radioType == "job") and "job" or "public"
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "radiocheck", 400) then return end

    local item = radioItemFor(rType)
    if not xPlayer.haveItem(item, 1) then
        TriggerClientEvent("vfw:radio:notify", source, "Vous n'avez pas de radio.")
        return
    end

    if rType == "job" then
        local job = MiscB.JobName(xPlayer)
        if not job or job == "" or job == "unemployed" or job == "chomeur" then
            TriggerClientEvent("vfw:radio:notify", source, "Vous n'avez pas de service actif.")
            return
        end
    end

    TriggerClientEvent("vfw:radio:openWithConfig", source, {
        radioType = rType,
        offset = radioOffset(rType),
        shell = rType,
    })
end)

RegisterNetEvent("radio:connectToFrequency", function(frequency, radioType)
    local source = source
    local freq = tonumber(frequency)
    local rType = (radioType == "job") and "job" or "public"
    if not freq or freq ~= freq then
        TriggerClientEvent("radio:connectionDenied", source, "Cette frequence n'est pas valide.")
        return
    end
    freq = math.floor(freq * 10) / 10
    if freq <= 0 or freq > 999999 then
        TriggerClientEvent("radio:connectionDenied", source, "Cette frequence n'est pas valide.")
        return
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "radioconnect", 400) then return end

    if not xPlayer.haveItem(radioItemFor(rType), 1) then
        TriggerClientEvent("radio:connectionDenied", source, "Vous n'avez plus de radio.")
        return
    end

    if Radio911 and Radio911.CanJoin then
        local allowed, reason = Radio911.CanJoin(xPlayer, freq, rType)
        if not allowed then
            TriggerClientEvent("radio:connectionDenied", source, reason or "Accès refusé à cette fréquence.")
            return
        end
    end

    local key = radioJoin(source, rType, freq)
    TriggerClientEvent("radio:connectionSuccess", source, freq, rType, radioOffset(rType), radioMembers(key))
    radioPush(key)
end)

RegisterNetEvent("radio:disconnect", function(frequency, radioType)
    local source = source
    radioLeave(source, false)
end)

RegisterNetEvent("radio:requestStatus", function()
    local source = source
    local key = radioPlayers[source]
    if not key then return end
    local session = radioSessions[key]
    if not session then
        radioPlayers[source] = nil
        return
    end
    TriggerClientEvent("radio:connectionSuccess", source, session.frequency, session.radioType, radioOffset(session.radioType), radioMembers(key))
end)

RegisterNetEvent("radio:resyncSession", function(frequency, radioType)
    local source = source
    local freq = tonumber(frequency)
    local rType = (radioType == "job") and "job" or "public"
    if not freq then return end

    local key = radioKey(rType, freq)
    local session = radioSessions[key]
    if session and session.members[source] then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if Radio911 and Radio911.CanJoin then
        local allowed, reason = Radio911.CanJoin(xPlayer, freq, rType)
        if not allowed then
            TriggerClientEvent("radio:connectionDenied", source, reason or "Accès refusé à cette fréquence.")
            return
        end
    end

    key = radioJoin(source, rType, freq)
    TriggerClientEvent("radio:connectionSuccess", source, freq, rType, radioOffset(rType), radioMembers(key))
    radioPush(key)
end)

local function radioTalking(source, frequency, radioType, talking)
    local key = radioPlayers[source]
    if not key then return end
    local session = radioSessions[key]
    if not session or not session.members[source] then return end

    session.talking[source] = talking or nil
    local name = radioDisplayName(source)
    for src in pairs(session.members) do
        TriggerClientEvent("radio:playerTalking", src, source, name, talking)
    end
end

RegisterNetEvent("radio:startTalking", function(frequency, radioType)
    local source = source
    radioTalking(source, frequency, radioType, true)
end)

RegisterNetEvent("radio:stopTalking", function(frequency, radioType)
    local source = source
    radioTalking(source, frequency, radioType, false)
end)

RegisterNetEvent("radio:setNickname", function(nickname, useNickname)
    local source = source
    local nick = MiscB.Str(nickname, 32)
    if nickname ~= nil and not nick then return end
    radioNicknames[source] = { nickname = nick, useNickname = useNickname == true }
    Player(source).state:set("radioNickname", radioNicknames[source], true)

    local key = radioPlayers[source]
    if key then radioPush(key) end
end)

AddEventHandler("vfw:playerDropped", function(source)
    radioLeave(source, false)
    radioNicknames[source] = nil
    megaphoneVolume[source] = nil
    megaphoneSubmix[source] = nil
end)

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(5000)
        TriggerClientEvent("radio:serverRestarted", -1)
    end)
end)

local amplifierZones = {}
local restrictionZones = {}
local voiceLoaded = false
local voiceLoading = false

local function loadVoiceZones()
    if voiceLoaded then return end
    if voiceLoading then
        local waited = 0
        while not voiceLoaded and waited < 5000 do
            Wait(10)
            waited = waited + 10
        end
        return
    end
    voiceLoading = true
    local rows = MiscB.Query("SELECT id, kind, x, y, z, radius, amplification FROM voice_zones", {})
    for i = 1, #rows do
        local row = rows[i]
        local zone = {
            id = row.id,
            coords = { x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0 },
            radius = row.radius + 0.0,
            amplification = row.amplification + 0.0,
        }
        if row.kind == "restriction" then
            restrictionZones[#restrictionZones + 1] = zone
        else
            amplifierZones[#amplifierZones + 1] = zone
        end
    end
    voiceLoaded = true
    voiceLoading = false
end

local function pushVoiceZones(target)
    loadVoiceZones()
    TriggerClientEvent("voiceSystem:syncZones", target or -1, amplifierZones, restrictionZones)
end

RegisterNetEvent("voiceSystem:requestZones", function()
    local source = source
    loadVoiceZones()
    TriggerClientEvent("voiceSystem:syncZones", source, amplifierZones, restrictionZones)
    TriggerClientEvent("voiceSystem:drawZones", source, amplifierZones, restrictionZones)
end)

RegisterNetEvent("voiceSystem:addAmplifierZone", function(coords, radius, amplification)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.hasPermission("staff") and not xPlayer.hasPermission("admin") then return end

    local pos = MiscB.Vec3(coords)
    local rad = MiscB.ToNum(radius, 0.0)
    local amp = MiscB.ToNum(amplification, 1.0)
    if not pos or rad <= 0.0 or rad > 500.0 then return end
    if amp < 0.1 or amp > 20.0 then return end

    loadVoiceZones()
    local id = MiscB.Insert(
        "INSERT INTO voice_zones (kind, x, y, z, radius, amplification) VALUES (?, ?, ?, ?, ?, ?)",
        { "amplifier", pos.x, pos.y, pos.z, rad, amp }
    )

    amplifierZones[#amplifierZones + 1] = {
        id = id or (#amplifierZones + 1),
        coords = { x = pos.x, y = pos.y, z = pos.z },
        radius = rad,
        amplification = amp,
    }

    pushVoiceZones(-1)
end)

AddEventHandler("vfw:playerLoaded", function(source)
    CreateThread(function()
        Wait(2000)
        loadVoiceZones()
        TriggerClientEvent("voiceSystem:syncZones", source, amplifierZones, restrictionZones)
    end)
end)
