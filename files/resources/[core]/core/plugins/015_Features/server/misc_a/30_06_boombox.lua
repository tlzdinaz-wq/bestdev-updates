local BOOM_ITEM = "boombox"
local BOOM_MODEL = "prop_boombox_01"
local BROADCAST_RADIUS = 80.0
local MAX_URL_LEN = 1024
local MAX_TITLE_LEN = 160
local MAX_TRACKS = 100

local BoomStates = {}
local VehStates = {}
local PlacedBooms = {}

local function now()
    return os.time()
end

local function elapsedOf(state)
    if not state then return 0 end
    local offset = tonumber(state.offset) or 0
    if state.playState ~= "playing" then return math.floor(offset) end
    local started = tonumber(state.startedAt) or now()
    local value = offset + (now() - started)
    if value < 0 then value = 0 end
    return math.floor(value)
end

local function netIdFromMusicId(musicId)
    if type(musicId) ~= "string" then return nil end
    local raw = musicId:match("^id_(%d+)$")
    if not raw then return nil end
    return tonumber(raw)
end

local function setEntityBag(entity, key, value)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    local ok = pcall(function()
        Entity(entity).state:set(key, value, true)
    end)
    if not ok then
        console.warn(("[misc30] statebag '%s' non applique"):format(tostring(key)))
    end
end

local function pushBoomBag(state)
    local entity = Misc30.EntityFromNet(state.netId)
    if not entity then return end

    if state.playState == "stopped" or not state.url then
        setEntityBag(entity, "boombox", nil)
        return
    end

    setEntityBag(entity, "boombox", {
        playState = state.playState,
        url = state.url,
        volume = state.volume,
        startedAtEpoch = now() - elapsedOf(state),
    })
end

local function pushVehBag(state)
    local entity = Misc30.EntityFromNet(state.netId)
    if not entity then return end

    if state.playState == "stopped" or not state.url then
        setEntityBag(entity, "vehicleMusic", nil)
        return
    end

    setEntityBag(entity, "vehicleMusic", {
        playState = state.playState,
        url = state.url,
        volume = state.volume,
        title = state.title,
        startedAtEpoch = now() - elapsedOf(state),
    })
end

local function stateCoords(state)
    local entity = Misc30.EntityFromNet(state.netId)
    if entity then
        local coords = GetEntityCoords(entity)
        if coords then
            state.coords = { x = coords.x, y = coords.y, z = coords.z }
        end
    end
    return state.coords or { x = 0.0, y = 0.0, z = 0.0 }
end

local function broadcast(state, eventName, ...)
    local targets = Misc30.PlayersInRadius(stateCoords(state), BROADCAST_RADIUS)
    for i = 1, #targets do
        TriggerClientEvent(eventName, targets[i], ...)
    end
end

local function boomPayload(state)
    return {
        controllerId = state.controllerId,
        controllerName = state.controllerName,
        currentTrack = state.url and { title = state.title or "Lecture directe", url = state.url } or nil,
        playState = state.playState or "stopped",
        volume = state.volume or 0.7,
    }
end

local function pushBoomState(state)
    broadcast(state, "core:boombox:stateUpdate", state.musicId, boomPayload(state))
end

local function clearBoomState(musicId)
    local state = BoomStates[musicId]
    if not state then return end

    state.playState = "stopped"
    state.url = nil
    state.title = nil
    state.offset = 0

    pushBoomBag(state)
    broadcast(state, "core:boombox:stateCleared", musicId)

    BoomStates[musicId] = nil
end

local function getOrCreateBoom(musicId, netId)
    local state = BoomStates[musicId]
    if state then return state end

    state = {
        musicId = musicId,
        netId = netId,
        controllerId = nil,
        controllerName = nil,
        url = nil,
        title = nil,
        volume = 0.7,
        playState = "stopped",
        startedAt = now(),
        offset = 0,
        queue = {},
        queueIndex = 1,
    }
    BoomStates[musicId] = state
    return state
end

local function getOrCreateVeh(netId)
    local state = VehStates[netId]
    if state then return state end

    state = {
        netId = netId,
        controllerId = nil,
        controllerName = nil,
        url = nil,
        title = nil,
        volume = 0.7,
        playState = "stopped",
        startedAt = now(),
        offset = 0,
    }
    VehStates[netId] = state
    return state
end

local function canControlVehicle(source, netId)
    local entity = Misc30.EntityFromNet(netId)
    if not entity then return false end
    if GetEntityType(entity) ~= 2 then return false end

    local coords = Misc30.PlayerCoords(source)
    if not coords then return false end
    return #(coords - GetEntityCoords(entity)) <= 15.0
end

local function canControlBoombox(source, musicId)
    local netId = netIdFromMusicId(musicId)
    if not netId then return false end

    local entity = Misc30.EntityFromNet(netId)
    if not entity then return true end

    local coords = Misc30.PlayerCoords(source)
    if not coords then return false end
    return #(coords - GetEntityCoords(entity)) <= 25.0
end

RegisterNetEvent("core:vehicleMusic:play", function(netId, url, volume, coords, title)
    local source = source

    local id = Misc30.ToInt(netId, 1)
    if not id then return end
    if not Misc30.IsUrl(url, MAX_URL_LEN) then return end

    local vol = Misc30.ToFloat(volume, 0.0, 1.0) or 0.5
    local trackTitle = Misc30.Clean(title, MAX_TITLE_LEN, "Lecture directe")

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "vehMusicPlay", 600) then return end
    if not canControlVehicle(source, id) then return end

    local state = getOrCreateVeh(id)
    state.controllerId = source
    state.controllerName = Misc30.PlayerName(xPlayer)
    state.url = url
    state.title = trackTitle
    state.volume = vol
    state.playState = "playing"
    state.startedAt = now()
    state.offset = 0
    state.coords = Misc30.Plain(coords, state.coords)

    pushVehBag(state)
    broadcast(state, "core:vehicleMusic:playC", id, url, vol, stateCoords(state), trackTitle)
end)

RegisterNetEvent("core:vehicleMusic:pause", function(netId, action, currentTime)
    local source = source

    local id = Misc30.ToInt(netId, 1)
    if not id then return end
    if action ~= "pause" and action ~= "resume" then return end

    local state = VehStates[id]
    if not state then return end
    if not Misc30.RateLimit(source, "vehMusicPause", 300) then return end
    if not canControlVehicle(source, id) then return end

    if action == "pause" then
        local at = Misc30.ToFloat(currentTime, 0.0, 86400.0)
        state.offset = at or elapsedOf(state)
        state.playState = "paused"
        pushVehBag(state)
        broadcast(state, "core:vehicleMusic:pauseC", id, "pause", nil)
    else
        state.playState = "playing"
        state.startedAt = now()
        pushVehBag(state)
        broadcast(state, "core:vehicleMusic:pauseC", id, "resume", state.offset or 0)
    end
end)

RegisterNetEvent("core:vehicleMusic:stop", function(netId)
    local source = source

    local id = Misc30.ToInt(netId, 1)
    if not id then return end

    local state = VehStates[id]
    if not state then return end
    if not canControlVehicle(source, id) then return end

    state.playState = "stopped"
    state.url = nil
    state.title = nil
    state.offset = 0

    pushVehBag(state)
    broadcast(state, "core:vehicleMusic:stopC", id)

    VehStates[id] = nil
end)

RegisterNetEvent("core:vehicleMusic:volume", function(netId, volume)
    local source = source

    local id = Misc30.ToInt(netId, 1)
    if not id then return end

    local vol = Misc30.ToFloat(volume, 0.0, 1.0)
    if not vol then return end

    local state = VehStates[id]
    if not state then return end
    if not Misc30.RateLimit(source, "vehMusicVolume", 200) then return end
    if not canControlVehicle(source, id) then return end

    state.volume = vol
    pushVehBag(state)
    broadcast(state, "core:vehicleMusic:volumeC", id, vol)
end)

RegisterNetEvent("core:vehicleMusic:seek", function(netId, time)
    local source = source

    local id = Misc30.ToInt(netId, 1)
    if not id then return end

    local at = Misc30.ToFloat(time, 0.0, 86400.0)
    if not at then return end

    local state = VehStates[id]
    if not state then return end
    if not canControlVehicle(source, id) then return end

    state.offset = at
    state.startedAt = now()
    pushVehBag(state)
end)

local function startBoombox(source, musicId, url, title, volume, coords)
    local netId = netIdFromMusicId(musicId)
    if not netId then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not canControlBoombox(source, musicId) then return end

    local state = getOrCreateBoom(musicId, netId)
    state.controllerId = source
    state.controllerName = Misc30.PlayerName(xPlayer)
    state.url = url
    state.title = title
    state.volume = volume
    state.playState = "playing"
    state.startedAt = now()
    state.offset = 0
    state.coords = Misc30.Plain(coords, state.coords)

    pushBoomBag(state)
    broadcast(state, "core:plyBoomSongC", musicId, url, volume, stateCoords(state))
    pushBoomState(state)
end

RegisterNetEvent("core:boombox:playTrack", function(musicId, url, title, volume, coords)
    local source = source

    if not Misc30.IsString(musicId, 48) then return end
    if not Misc30.IsUrl(url, MAX_URL_LEN) then return end
    if not Misc30.RateLimit(source, "boomPlay", 600) then return end

    startBoombox(source, musicId, url,
        Misc30.Clean(title, MAX_TITLE_LEN, "Lecture directe"),
        Misc30.ToFloat(volume, 0.0, 1.0) or 0.5,
        coords)
end)

RegisterNetEvent("core:plyBoomSong", function(musicId, url, volume, coords)
    local source = source

    if not Misc30.IsString(musicId, 48) then return end
    if not Misc30.IsUrl(url, MAX_URL_LEN) then return end
    if not Misc30.RateLimit(source, "boomPlay", 600) then return end

    startBoombox(source, musicId, url, "Lecture directe",
        Misc30.ToFloat(volume, 0.0, 1.0) or 0.5, coords)
end)

RegisterNetEvent("core:PauseBoomSong", function(musicId, action, currentTime)
    local source = source

    if not Misc30.IsString(musicId, 48) then return end
    if action ~= "pause" and action ~= "resume" and action ~= "stop" then return end

    local state = BoomStates[musicId]
    if not state then return end
    if not Misc30.RateLimit(source, "boomPause", 250) then return end
    if not canControlBoombox(source, musicId) then return end

    if action == "stop" then
        broadcast(state, "core:PauseBoomSongC", musicId, "stop", nil)
        clearBoomState(musicId)
        return
    end

    if action == "pause" then
        local at = Misc30.ToFloat(currentTime, 0.0, 86400.0)
        state.offset = at or elapsedOf(state)
        state.playState = "paused"
        pushBoomBag(state)
        broadcast(state, "core:PauseBoomSongC", musicId, "pause", nil)
    else
        state.playState = "playing"
        state.startedAt = now()
        pushBoomBag(state)
        broadcast(state, "core:PauseBoomSongC", musicId, "resume", state.offset or 0)
    end

    pushBoomState(state)
end)

RegisterNetEvent("core:BoomSongVolume", function(musicId, volume)
    local source = source

    if not Misc30.IsString(musicId, 48) then return end

    local vol = Misc30.ToFloat(volume, 0.0, 1.0)
    if not vol then return end

    local state = BoomStates[musicId]
    if not state then return end
    if not Misc30.RateLimit(source, "boomVolume", 200) then return end
    if not canControlBoombox(source, musicId) then return end

    state.volume = vol
    pushBoomBag(state)
    broadcast(state, "core:BoomSongVolumeC", musicId, vol)
    pushBoomState(state)
end)

RegisterNetEvent("core:updateSongPos", function(_plys, musicid, coords)
    local source = source

    if not Misc30.IsString(musicid, 48) then return end

    local state = BoomStates[musicid]
    if not state then return end
    if not Misc30.RateLimit(source, "songPos", 1000) then return end

    local pos = Misc30.Plain(coords)
    if not pos then return end

    local playerCoords = Misc30.PlayerCoords(source)
    if playerCoords and #(playerCoords - vector3(pos.x, pos.y, pos.z)) > 25.0 then return end

    state.coords = pos

    local targets = Misc30.PlayersInRadius(pos, BROADCAST_RADIUS)
    for i = 1, #targets do
        TriggerClientEvent("core:updateSongPosC", targets[i], musicid, pos)
    end
end)

RegisterNetEvent("core:boombox:takeControl", function(musicId)
    local source = source

    if not Misc30.IsString(musicId, 48) then return end

    local state = BoomStates[musicId]
    if not state then return end
    if not canControlBoombox(source, musicId) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    state.controllerId = source
    state.controllerName = Misc30.PlayerName(xPlayer)

    pushBoomState(state)
end)

RegisterNetEvent("core:boombox:seek", function(musicId, time)
    local source = source

    if not Misc30.IsString(musicId, 48) then return end

    local at = Misc30.ToFloat(time, 0.0, 86400.0)
    if not at then return end

    local state = BoomStates[musicId]
    if not state then return end
    if not Misc30.RateLimit(source, "boomSeek", 300) then return end
    if not canControlBoombox(source, musicId) then return end

    state.offset = at
    state.startedAt = now()
    pushBoomBag(state)

    local targets = Misc30.PlayersInRadius(stateCoords(state), BROADCAST_RADIUS)
    for i = 1, #targets do
        if targets[i] ~= source then
            TriggerClientEvent("core:boombox:seekC", targets[i], musicId, at)
        end
    end
end)

RegisterNetEvent("core:boombox:setQueue", function(musicId, tracks, index)
    local source = source

    if not Misc30.IsString(musicId, 48) then return end
    if type(tracks) ~= "table" then return end

    local state = BoomStates[musicId]
    if not state then return end
    if not canControlBoombox(source, musicId) then return end

    local clean = {}
    for i = 1, math.min(#tracks, MAX_TRACKS) do
        local track = tracks[i]
        if type(track) == "table" and Misc30.IsUrl(track.url, MAX_URL_LEN) then
            clean[#clean + 1] = {
                id = track.id,
                title = Misc30.Clean(track.title, MAX_TITLE_LEN, "Piste"),
                url = track.url,
            }
        end
    end

    state.queue = clean
    state.queueIndex = Misc30.ToInt(index, 1, MAX_TRACKS) or 1
end)

RegisterNetEvent("core:boombox:clearQueue", function(musicId)
    local source = source

    if not Misc30.IsString(musicId, 48) then return end

    local state = BoomStates[musicId]
    if not state then return end
    if not canControlBoombox(source, musicId) then return end

    state.queue = {}
    state.queueIndex = 1
end)

RegisterNetEvent("core:boombox:pickup", function(musicId)
    local source = source

    if not Misc30.IsString(musicId, 48) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "boomPickup", 1500) then return end
    if not canControlBoombox(source, musicId) then return end

    local netId = netIdFromMusicId(musicId)
    if not netId or not PlacedBooms[netId] then return end
    PlacedBooms[netId] = nil

    clearBoomState(musicId)

    local entity = Misc30.EntityFromNet(netId)
    if entity and GetEntityModel(entity) == joaat(BOOM_MODEL) then
        DeleteEntity(entity)
    end

    if Misc30.ItemExists(BOOM_ITEM) then
        Misc30.GiveItem(xPlayer, BOOM_ITEM, 1)
    end
end)

Misc30.Cb("core:boombox:requestPlacement", function(source, dropPos)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not Misc30.RateLimit(source, "boomPlace", 3000) then return nil end

    local pos = Misc30.Vec3(dropPos)
    if not pos then return nil end

    local playerCoords = Misc30.PlayerCoords(source)
    if not playerCoords or #(playerCoords - pos) > 6.0 then return nil end

    if Misc30.ItemExists(BOOM_ITEM) then
        if Misc30.CountItem(xPlayer, BOOM_ITEM) < 1 then return nil end
        if not Misc30.TakeItem(xPlayer, BOOM_ITEM, 1) then return nil end
    end

    local object = CreateObject(joaat(BOOM_MODEL), pos.x, pos.y, pos.z, true, true, false)

    local tries = 0
    while not DoesEntityExist(object) and tries < 100 do
        Wait(10)
        tries = tries + 1
    end

    if not DoesEntityExist(object) then
        if Misc30.ItemExists(BOOM_ITEM) then
            Misc30.GiveItem(xPlayer, BOOM_ITEM, 1)
        end
        return nil
    end

    pcall(SetEntityOrphanMode, object, 2)
    pcall(SetEntityDistanceCullingRadius, object, 1000.0)

    local netId = NetworkGetNetworkIdFromEntity(object)
    PlacedBooms[netId] = true
    getOrCreateBoom("id_" .. netId, netId)

    return netId
end)

Misc30.Cb("boombox:getState", function(source, musicId)
    if not Misc30.IsString(musicId, 48) then return nil end

    local state = BoomStates[musicId]
    if not state then return nil end

    return boomPayload(state)
end)

Misc30.Cb("vehicleMusic:getState", function(source, netId)
    local id = Misc30.ToInt(netId, 1)
    if not id then return nil end

    local state = VehStates[id]
    if not state then return nil end

    return {
        controllerId = state.controllerId,
        controllerName = state.controllerName,
        title = state.title,
        url = state.url,
        playState = state.playState or "stopped",
        volume = state.volume or 0.7,
    }
end)

Misc30.Cb("core:audio:getActiveSounds", function(source)
    local result = { boomboxes = {}, vehicles = {} }

    local playerCoords = Misc30.PlayerCoords(source)
    if not playerCoords then return result end

    for musicId, state in pairs(BoomStates) do
        if state.playState == "playing" and state.url then
            local coords = stateCoords(state)
            if #(playerCoords - vector3(coords.x, coords.y, coords.z)) <= BROADCAST_RADIUS then
                result.boomboxes[#result.boomboxes + 1] = {
                    musicId = musicId,
                    url = state.url,
                    volume = state.volume or 0.7,
                    coords = coords,
                    currentTime = elapsedOf(state),
                }
            end
        end
    end

    for netId, state in pairs(VehStates) do
        if state.playState == "playing" and state.url then
            local coords = stateCoords(state)
            if #(playerCoords - vector3(coords.x, coords.y, coords.z)) <= BROADCAST_RADIUS then
                result.vehicles[#result.vehicles + 1] = {
                    netId = netId,
                    url = state.url,
                    volume = state.volume or 0.7,
                    coords = coords,
                    title = state.title or "Lecture directe",
                    currentTime = elapsedOf(state),
                }
            end
        end
    end

    return result
end)

local function playlistOwner(xPlayer)
    return xPlayer.identifier
end

local function loadPlaylists(xPlayer)
    local playlists = Misc30.Query(
        "SELECT `id`, `name` FROM `music_playlists` WHERE `owner` = ? ORDER BY `id` ASC",
        { playlistOwner(xPlayer) }
    )

    local byId = {}
    local out = {}

    for i = 1, #playlists do
        local row = playlists[i]
        local entry = { id = row.id, name = row.name, tracks = {} }
        byId[row.id] = entry
        out[#out + 1] = entry
    end

    if #out == 0 then return out end

    local tracks = Misc30.Query([[
        SELECT t.`id`, t.`playlist_id`, t.`title`, t.`url`
        FROM `music_playlist_tracks` t
        INNER JOIN `music_playlists` p ON p.`id` = t.`playlist_id`
        WHERE p.`owner` = ?
        ORDER BY t.`position` ASC, t.`id` ASC
    ]], { playlistOwner(xPlayer) })

    for i = 1, #tracks do
        local row = tracks[i]
        local entry = byId[row.playlist_id]
        if entry then
            entry.tracks[#entry.tracks + 1] = { id = row.id, title = row.title, url = row.url }
        end
    end

    return out
end

Misc30.Cb("musicradio:getPlaylists", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    return loadPlaylists(xPlayer)
end)

local function ownsPlaylist(xPlayer, playlistId)
    local id = Misc30.ToInt(playlistId, 1)
    if not id then return nil end

    local owner = Misc30.Scalar("SELECT `owner` FROM `music_playlists` WHERE `id` = ?", { id })
    if owner ~= playlistOwner(xPlayer) then return nil end

    return id
end

RegisterNetEvent("musicradio:playlist:create", function(data)
    local source = source

    if type(data) ~= "table" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "playlistCreate", 1000) then return end

    local name = Misc30.Clean(data.name, 64)
    if not name then
        TriggerClientEvent("musicradio:notify", source, "ROUGE", "Ce nom de playlist n'est pas valide.")
        return
    end

    local count = Misc30.Scalar("SELECT COUNT(*) FROM `music_playlists` WHERE `owner` = ?",
        { playlistOwner(xPlayer) }, 0)
    if tonumber(count) and tonumber(count) >= 30 then
        TriggerClientEvent("musicradio:notify", source, "ROUGE", "Trop de playlists.")
        return
    end

    local id = Misc30.Insert(
        "INSERT INTO `music_playlists` (`owner`, `name`) VALUES (?, ?)",
        { playlistOwner(xPlayer), name }
    )
    if not id then
        TriggerClientEvent("musicradio:notify", source, "ROUGE", "Creation impossible.")
        return
    end

    TriggerClientEvent("musicradio:playlist:created", source, { id = id, name = name, tracks = {} })
end)

RegisterNetEvent("musicradio:playlist:delete", function(data)
    local source = source

    if type(data) ~= "table" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "playlistDelete", 500) then return end

    local id = ownsPlaylist(xPlayer, data.playlistId)
    if not id then return end

    Misc30.Update("DELETE FROM `music_playlist_tracks` WHERE `playlist_id` = ?", { id })
    Misc30.Update("DELETE FROM `music_playlists` WHERE `id` = ?", { id })

    TriggerClientEvent("musicradio:playlist:deleted", source, id)
end)

RegisterNetEvent("musicradio:playlist:rename", function(data)
    local source = source

    if type(data) ~= "table" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "playlistRename", 500) then return end

    local id = ownsPlaylist(xPlayer, data.playlistId)
    if not id then return end

    local name = Misc30.Clean(data.name, 64)
    if not name then return end

    Misc30.Update("UPDATE `music_playlists` SET `name` = ? WHERE `id` = ?", { name, id })

    TriggerClientEvent("musicradio:playlist:renamed", source, id, name)
end)

RegisterNetEvent("musicradio:track:add", function(data)
    local source = source

    if type(data) ~= "table" or type(data.track) ~= "table" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "trackAdd", 400) then return end

    local id = ownsPlaylist(xPlayer, data.playlistId)
    if not id then return end

    local url = data.track.url
    if not Misc30.IsUrl(url, MAX_URL_LEN) then
        TriggerClientEvent("musicradio:notify", source, "ROUGE", "Ce lien n'est pas valide.")
        return
    end

    local title = Misc30.Clean(data.track.title, MAX_TITLE_LEN, "Piste")

    local count = Misc30.Scalar("SELECT COUNT(*) FROM `music_playlist_tracks` WHERE `playlist_id` = ?",
        { id }, 0)
    if tonumber(count) and tonumber(count) >= MAX_TRACKS then
        TriggerClientEvent("musicradio:notify", source, "ROUGE", "Playlist pleine.")
        return
    end

    local trackId = Misc30.Insert(
        "INSERT INTO `music_playlist_tracks` (`playlist_id`, `title`, `url`, `position`) VALUES (?, ?, ?, ?)",
        { id, title, url, (tonumber(count) or 0) + 1 }
    )
    if not trackId then return end

    TriggerClientEvent("musicradio:track:added", source, id, { id = trackId, title = title, url = url })
end)

RegisterNetEvent("musicradio:track:remove", function(data)
    local source = source

    if type(data) ~= "table" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "trackRemove", 400) then return end

    local id = ownsPlaylist(xPlayer, data.playlistId)
    if not id then return end

    local trackId = Misc30.ToInt(data.trackId, 1)
    if not trackId then return end

    Misc30.Update("DELETE FROM `music_playlist_tracks` WHERE `id` = ? AND `playlist_id` = ?",
        { trackId, id })

    TriggerClientEvent("musicradio:track:removed", source, id, trackId)
end)

CreateThread(function()
    Wait(4000)
    Misc30.UsableItem(BOOM_ITEM, function(xPlayer)
        if not xPlayer then return end
        TriggerClientEvent("core:UseBoombox", xPlayer.source)
    end)
end)

CreateThread(function()
    while true do
        Wait(60000)

        for musicId, state in pairs(BoomStates) do
            if not Misc30.EntityFromNet(state.netId) then
                BoomStates[musicId] = nil
            end
        end

        for netId, _ in pairs(VehStates) do
            if not Misc30.EntityFromNet(netId) then
                VehStates[netId] = nil
            end
        end
    end
end)

AddEventHandler("vfw:playerDropped", function(source)
    for _, state in pairs(BoomStates) do
        if state.controllerId == source then
            state.controllerId = nil
            state.controllerName = nil
        end
    end

    for _, state in pairs(VehStates) do
        if state.controllerId == source then
            state.controllerId = nil
            state.controllerName = nil
        end
    end
end)
