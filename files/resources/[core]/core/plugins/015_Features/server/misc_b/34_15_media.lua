local MEDIA = {
    weazel = { job = "weazelnews", table = "media_announcements", brand = "weazel" },
    lifeinvader = { job = "lifeinvader", table = "media_announcements", brand = "lifeinvader" },
}

local liveCameras = {}
local mediaProps = {}
local broadcastTargets = {}

local function mediaPlayer(source, brand)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if MiscB.JobName(xPlayer) ~= MEDIA[brand].job then return nil end
    return xPlayer
end

local function registerMedia(brand)
    local cfg = MEDIA[brand]
    local prefix = brand .. ":"
    local appPrefix = brand .. "-app:"
    local clientPrefix = brand .. "-app:client:"

    MiscB.Cb(prefix .. "getAnnouncements", function(source)
        local xPlayer = mediaPlayer(source, brand)
        if not xPlayer then return {} end

        return MiscB.Query([[
            SELECT id, brand, title, content, format, image, author_name, broadcasted, created_at
            FROM media_announcements WHERE brand = ? ORDER BY id DESC LIMIT 100
        ]], { cfg.brand })
    end)

    MiscB.Cb(prefix .. "createAnnouncement", function(source, data)
        local xPlayer = mediaPlayer(source, brand)
        if not xPlayer then return { success = false } end
        if type(data) ~= "table" then return { success = false } end

        local title = MiscB.Str(data.title, 190)
        if not title then return { success = false } end

        local id = MiscB.Insert([[
            INSERT INTO media_announcements (brand, title, content, format, image, author_identifier, author_name, broadcasted, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, 0, NOW())
        ]], {
            cfg.brand, title,
            MiscB.Str(data.content, 4000) or "",
            MiscB.Str(data.format, 32) or "news",
            MiscB.Str(data.image, 512),
            xPlayer.identifier, MiscB.CharName(xPlayer),
        })

        return { success = id ~= nil, id = id }
    end)

    MiscB.Cb(prefix .. "updateAnnouncement", function(source, announcementId, data)
        local xPlayer = mediaPlayer(source, brand)
        if not xPlayer then return { success = false } end

        local id = MiscB.ToInt(announcementId, 1)
        if not id or type(data) ~= "table" then return { success = false } end

        MiscB.Update([[
            UPDATE media_announcements SET title = ?, content = ?, format = ?, image = ?
            WHERE id = ? AND brand = ?
        ]], {
            MiscB.Str(data.title, 190) or "",
            MiscB.Str(data.content, 4000) or "",
            MiscB.Str(data.format, 32) or "news",
            MiscB.Str(data.image, 512),
            id, cfg.brand,
        })

        return { success = true }
    end)

    MiscB.Cb(prefix .. "deleteAnnouncement", function(source, announcementId)
        local xPlayer = mediaPlayer(source, brand)
        if not xPlayer then return { success = false } end

        local id = MiscB.ToInt(announcementId, 1)
        if not id then return { success = false } end

        MiscB.Update("DELETE FROM media_announcements WHERE id = ? AND brand = ?", { id, cfg.brand })
        return { success = true }
    end)

    MiscB.Cb(prefix .. "markBroadcasted", function(source, announcementId)
        local xPlayer = mediaPlayer(source, brand)
        if not xPlayer then return { success = false } end

        local id = MiscB.ToInt(announcementId, 1)
        if not id then return { success = false } end

        MiscB.Update("UPDATE media_announcements SET broadcasted = 1 WHERE id = ? AND brand = ?", { id, cfg.brand })
        return { success = true }
    end)

    MiscB.Cb(prefix .. "getSocietyImage", function(source)
        local xPlayer = mediaPlayer(source, brand)
        if not xPlayer then return nil end

        local row = MiscB.Single("SELECT image FROM society_custom WHERE job_name = ? LIMIT 1", { cfg.job })
        if row and row.image then return row.image end
        if VFW.CdnUrl then
            local ok, url = pcall(VFW.CdnUrl, ("job/%s/logo.png"):format(cfg.job))
            if ok then return url end
        end
        return nil
    end)

    MiscB.Cb(prefix .. "getSocietyCustom", function(source)
        local xPlayer = mediaPlayer(source, brand)
        if not xPlayer then return {} end

        local row = MiscB.Single("SELECT * FROM society_custom WHERE job_name = ? LIMIT 1", { cfg.job })
        return row or {}
    end)

    RegisterNetEvent("core:" .. brand .. ":sendAnnounce", function(data)
        local source = source
        if type(data) ~= "table" then return end
        if not MiscB.Rate(source, "mediaannounce", 10000) then return end

        local xPlayer = mediaPlayer(source, brand)
        if not xPlayer then return end

        local payload = {
            title = MiscB.Str(data.title, 190) or "",
            content = MiscB.Str(data.content, 4000) or "",
            format = MiscB.Str(data.format, 32) or "news",
            image = MiscB.Str(data.image, 512),
            author = MiscB.CharName(xPlayer),
            position = MiscB.Plain(data.position),
            at = os.time(),
        }

        MiscB.Insert([[
            INSERT INTO media_announcements (brand, title, content, format, image, author_identifier, author_name, broadcasted, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1, NOW())
        ]], {
            cfg.brand, payload.title, payload.content, payload.format, payload.image,
            xPlayer.identifier, payload.author,
        })

        TriggerClientEvent("core:" .. brand .. ":sendAnnounceAll", -1, payload)
        TriggerClientEvent(clientPrefix .. "newNews", -1, payload)
    end)

    MiscB.Cb(appPrefix .. "getRecentNews", function(source)
        return MiscB.Query([[
            SELECT id, brand, title, content, format, image, author_name, created_at
            FROM media_announcements WHERE brand = ? AND broadcasted = 1
            ORDER BY id DESC LIMIT 30
        ]], { cfg.brand })
    end)

    MiscB.Cb(appPrefix .. "getActiveCamera", function(source)
        local live = liveCameras[brand]
        if not live then return nil end
        if not VFW.GetPlayerFromId(live.source) then
            liveCameras[brand] = nil
            return nil
        end
        return {
            source = live.source,
            name = live.name,
            coords = live.coords,
            rotation = live.rotation,
            fov = live.fov,
            startedAt = live.startedAt,
        }
    end)

    MiscB.Cb(appPrefix .. "tryStartCamera", function(source, data)
        local xPlayer = mediaPlayer(source, brand)
        if not xPlayer then return { ok = false, reason = "not_allowed" } end
        if MiscB.GradeLevel(xPlayer) < 1 and not MiscB.IsBoss(xPlayer) then
            return { ok = false, reason = "not_allowed" }
        end

        local live = liveCameras[brand]
        if live and VFW.GetPlayerFromId(live.source) and live.source ~= source then
            return { ok = false, reason = "already_live" }
        end

        liveCameras[brand] = {
            source = source,
            name = (type(data) == "table" and MiscB.Str(data.name, 96)) or MiscB.CharName(xPlayer),
            startedAt = os.time(),
        }
        broadcastTargets[brand] = {}

        TriggerClientEvent(clientPrefix .. "cameraStart", -1, liveCameras[brand])
        return { ok = true }
    end)

    RegisterNetEvent(appPrefix .. "cameraState", function(data)
        local source = source
        if type(data) ~= "table" then return end

        local live = liveCameras[brand]
        if not live or live.source ~= source then return end

        live.coords = MiscB.Plain(data.coords)
        live.rotation = MiscB.Plain(data.rotation)
        live.fov = MiscB.ToNum(data.fov, 50.0)

        TriggerClientEvent(clientPrefix .. "cameraUpdate", -1, {
            source = source,
            coords = live.coords,
            rotation = live.rotation,
            fov = live.fov,
        })
    end)

    RegisterNetEvent(appPrefix .. "cameraStop", function()
        local source = source
        local live = liveCameras[brand]
        if not live or live.source ~= source then return end

        liveCameras[brand] = nil
        broadcastTargets[brand] = nil

        TriggerClientEvent(clientPrefix .. "cameraStop", -1)
        TriggerClientEvent(clientPrefix .. "stopCapture", source)
        TriggerClientEvent(clientPrefix .. "clearBroadcastViewers", source)
    end)

    RegisterNetEvent(appPrefix .. "broadcast:nearbyPlayers", function(nearbyIds)
        local source = source
        if type(nearbyIds) ~= "table" then return end

        local live = liveCameras[brand]
        if not live or live.source ~= source then return end

        local clean = {}
        for i = 1, math.min(#nearbyIds, 64) do
            local id = tonumber(nearbyIds[i])
            if id and VFW.GetPlayerFromId(id) then clean[#clean + 1] = id end
        end

        local viewers = broadcastTargets[brand] or {}
        for viewer in pairs(viewers) do
            TriggerClientEvent(clientPrefix .. "updateBroadcastVoices", viewer, clean)
        end
    end)

    RegisterNetEvent(appPrefix .. "webrtc:requestStream", function()
        local source = source
        local live = liveCameras[brand]
        if not live then return end
        if not VFW.GetPlayerFromId(live.source) then
            liveCameras[brand] = nil
            return
        end

        broadcastTargets[brand] = broadcastTargets[brand] or {}
        broadcastTargets[brand][source] = true

        TriggerClientEvent(clientPrefix .. "viewerRequest", live.source, { viewerId = source })
        TriggerClientEvent(clientPrefix .. "addBroadcastViewer", live.source, source)
        TriggerClientEvent(clientPrefix .. "listenBroadcast", source, live.source)
    end)

    RegisterNetEvent(appPrefix .. "webrtc:signal", function(data)
        local source = source
        if type(data) ~= "table" then return end

        local live = liveCameras[brand]
        if not live then return end

        local targetId = tonumber(data.target or data.viewerId)
        data.from = source

        if live.source == source then
            if targetId and VFW.GetPlayerFromId(targetId) then
                TriggerClientEvent(clientPrefix .. "webrtcSignal", targetId, data)
            end
            return
        end

        if VFW.GetPlayerFromId(live.source) then
            TriggerClientEvent(clientPrefix .. "webrtcSignal", live.source, data)
        end
    end)

    RegisterNetEvent(appPrefix .. "webrtc:stopWatching", function()
        local source = source
        local viewers = broadcastTargets[brand]
        if not viewers or not viewers[source] then return end

        viewers[source] = nil
        local live = liveCameras[brand]
        if live and VFW.GetPlayerFromId(live.source) then
            TriggerClientEvent(clientPrefix .. "removeBroadcastViewer", live.source, source)
        end
        TriggerClientEvent(clientPrefix .. "stopListenBroadcast", source)
    end)

    RegisterNetEvent(brand .. ":registerProp", function(networkId)
        local source = source
        local net = tonumber(networkId)
        if not net then return end
        if not mediaPlayer(source, brand) then return end

        mediaProps[brand] = mediaProps[brand] or {}
        mediaProps[brand][net] = source
    end)

    RegisterNetEvent(brand .. ":unregisterProp", function(networkId)
        local source = source
        local net = tonumber(networkId)
        if not net then return end

        local list = mediaProps[brand]
        if not list or list[net] ~= source then return end
        list[net] = nil

        local entity = NetworkGetEntityFromNetworkId(net)
        if entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 3 then
            DeleteEntity(entity)
        end
    end)
end

for brand in pairs(MEDIA) do
    registerMedia(brand)
end

AddEventHandler("vfw:playerDropped", function(source)
    for brand, live in pairs(liveCameras) do
        if live.source == source then
            liveCameras[brand] = nil
            broadcastTargets[brand] = nil
            TriggerClientEvent(brand .. "-app:client:cameraStop", -1)
        end
    end

    for brand, viewers in pairs(broadcastTargets) do
        if viewers and viewers[source] then
            viewers[source] = nil
            local live = liveCameras[brand]
            if live and VFW.GetPlayerFromId(live.source) then
                TriggerClientEvent(brand .. "-app:client:removeBroadcastViewer", live.source, source)
            end
        end
    end

    for brand, list in pairs(mediaProps) do
        for net, owner in pairs(list) do
            if owner == source then
                local entity = NetworkGetEntityFromNetworkId(net)
                if entity and entity ~= 0 and DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
                list[net] = nil
            end
        end
    end
end)

local function usss(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if MiscB.JobName(xPlayer) ~= "usss" and not MiscB.IsLawEnforcement(xPlayer) then return nil end
    return xPlayer
end

local function usssCitizenRow(row)
    return {
        identifier = row.identifier,
        firstname = row.firstname,
        lastname = row.lastname,
        name = ("%s %s"):format(row.firstname or "", row.lastname or ""),
        dateofbirth = row.dateofbirth,
        sex = row.sex,
        phone = row.phone,
        address = row.address,
        mugshot = row.mugshot,
        job = row.job,
    }
end

MiscB.Cb("usss:getAllCitizens", function(source, data)
    local xPlayer = usss(source)
    if not xPlayer then return {} end

    local rows = MiscB.Query([[
        SELECT c.identifier, c.firstname, c.lastname, c.dateofbirth, c.sex, p.phone, c.address, c.mugshot, c.job
        FROM characters c LEFT JOIN character_phones p ON p.identifier = c.identifier
        ORDER BY c.lastname ASC LIMIT 300
    ]], {})

    local out = {}
    for i = 1, #rows do out[#out + 1] = usssCitizenRow(rows[i]) end
    return out
end)

MiscB.Cb("usss:searchCitizens", function(source, data)
    local xPlayer = usss(source)
    if not xPlayer then return {} end

    local term = type(data) == "table" and MiscB.Str(data.search or data.query or data.name, 64) or MiscB.Str(data, 64)
    if not term or term == "" then return {} end

    local like = "%" .. term .. "%"
    local rows = MiscB.Query([[
        SELECT c.identifier, c.firstname, c.lastname, c.dateofbirth, c.sex, p.phone, c.address, c.mugshot, c.job
        FROM characters c LEFT JOIN character_phones p ON p.identifier = c.identifier
        WHERE c.firstname LIKE ? OR c.lastname LIKE ? OR CONCAT(c.firstname, ' ', c.lastname) LIKE ?
        ORDER BY c.lastname ASC LIMIT 100
    ]], { like, like, like })

    local out = {}
    for i = 1, #rows do out[#out + 1] = usssCitizenRow(rows[i]) end
    return out
end)

MiscB.Cb("usss:getCitizenProfile", function(source, data)
    local xPlayer = usss(source)
    if not xPlayer then return {} end

    local identifier = type(data) == "table" and MiscB.Str(data.identifier, 80) or MiscB.Str(data, 80)
    if not identifier then return {} end

    local row = MiscB.Single([[
        SELECT c.identifier, c.firstname, c.lastname, c.dateofbirth, c.sex, p.phone, c.address, c.mugshot, c.job
        FROM characters c LEFT JOIN character_phones p ON p.identifier = c.identifier
        WHERE c.identifier = ? LIMIT 1
    ]], { identifier })
    if not row then return {} end

    local profile = usssCitizenRow(row)
    profile.vehicles = MiscB.Query(
        "SELECT plate, vehName AS model FROM owned_vehicles WHERE owner = ? LIMIT 100",
        { identifier }
    )
    profile.records = MiscB.Query([[
        SELECT id, record_type, title, author_name, created_at FROM police_records
        WHERE citizen_identifier = ? ORDER BY id DESC LIMIT 100
    ]], { identifier })
    return profile
end)

MiscB.Cb("usss:getOfficers", function(source)
    local xPlayer = usss(source)
    if not xPlayer then return {} end

    local rows = MiscB.Query([[
        SELECT identifier, firstname, lastname, job_grade FROM characters
        WHERE job = 'usss' ORDER BY job_grade DESC LIMIT 200
    ]], {})

    for i = 1, #rows do
        rows[i].name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or "")
        rows[i].online = VFW.GetPlayerFromIdentifier(rows[i].identifier) ~= nil
    end
    return rows
end)

MiscB.Cb("usss:getWantedNotices", function(source)
    local xPlayer = usss(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT id, citizen_identifier, citizen_name, reason, author_name, created_at
        FROM police_wanted_notices ORDER BY id DESC LIMIT 200
    ]], {})
end)

MiscB.Cb("usss:createWantedNotice", function(source, data)
    local xPlayer = usss(source)
    if not xPlayer then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local identifier = MiscB.Str(data.identifier or data.citizenIdentifier, 80)
    if not identifier then return { success = false } end

    local citizen = MiscB.Single("SELECT firstname, lastname FROM characters WHERE identifier = ? LIMIT 1", { identifier })
    local id = MiscB.Insert([[
        INSERT INTO police_wanted_notices (citizen_identifier, citizen_name, reason, author_identifier, author_name, created_at)
        VALUES (?, ?, ?, ?, ?, NOW())
    ]], {
        identifier,
        citizen and ("%s %s"):format(citizen.firstname or "", citizen.lastname or "") or "",
        MiscB.Str(data.reason, 500) or "",
        xPlayer.identifier, MiscB.CharName(xPlayer),
    })

    return { success = id ~= nil, id = id }
end)

MiscB.Cb("usss:removeWantedNotice", function(source, data)
    local xPlayer = usss(source)
    if not xPlayer then return { success = false } end

    local id = type(data) == "table" and MiscB.ToInt(data.id, 1) or MiscB.ToInt(data, 1)
    if not id then return { success = false } end

    MiscB.Update("DELETE FROM police_wanted_notices WHERE id = ?", { id })
    return { success = true }
end)

MiscB.Cb("usss:getWantedVehicles", function(source)
    local xPlayer = usss(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT id, plate, reason, author_name, created_at FROM police_wanted_vehicles
        ORDER BY id DESC LIMIT 200
    ]], {})
end)

MiscB.Cb("usss:getActiveAlerts", function(source)
    local xPlayer = usss(source)
    if not xPlayer then return {} end

    return MiscB.Query([[
        SELECT id, title, message, code, x, y, z, district, author_name, created_at
        FROM police_dispatch_alerts WHERE job_name = 'usss' ORDER BY id DESC LIMIT 50
    ]], {})
end)
