local PS = VFW.PropertyServer

local ZONE_CELL = 150.0
local ZONE_RADIUS = 160.0
local PERMANENT_EXPIRE = 4102444800

PS.BuilderProps = {}
PS.Zones = {}
PS.ZoneByCell = {}
PS.ZoneOccupants = {}

PS.PropsCatalog = {
    ["Chantier"] = {
        ["prop_barrier_work05"] = "Barriere de chantier",
        ["prop_barier_conc_01a"] = "Bloc de beton",
        ["prop_mp_barrier_02b"] = "Barriere mobile",
        ["prop_consign_01a"] = "Panneau de signalisation",
        ["prop_worklight_03b"] = "Projecteur de chantier",
        ["prop_toolchest_01"] = "Caisse a outils",
    },
    ["Mobilier"] = {
        ["prop_table_03b"] = "Table",
        ["prop_chair_01a"] = "Chaise",
        ["prop_bench_01a"] = "Banc",
        ["prop_parasol_01a"] = "Parasol",
        ["prop_beach_fire"] = "Feu de camp",
        ["prop_ld_farm_chair01"] = "Chaise de ferme",
    },
    ["Evenement"] = {
        ["prop_speaker_01"] = "Enceinte",
        ["prop_dj_deck_01"] = "Platine DJ",
        ["prop_ven_market_stall2"] = "Stand de marche",
        ["prop_gazebo_02"] = "Tonnelle",
        ["prop_flag_ls"] = "Drapeau",
        ["prop_bandstand_01"] = "Estrade",
    },
    ["Securite"] = {
        ["prop_barrier_wat_03a"] = "Barriere anti-emeute",
        ["prop_roadcone02a"] = "Cone de signalisation",
        ["prop_boxpile_07d"] = "Pile de caisses",
        ["prop_fncconc_02a"] = "Mur de beton",
        ["prop_ld_ferris_wheel"] = "Grande roue",
    },
    ["Nature"] = {
        ["prop_tree_birch_01"] = "Bouleau",
        ["prop_bush_lrg_04b"] = "Buisson",
        ["prop_plant_01a"] = "Plante",
        ["prop_rock_4_c"] = "Rocher",
        ["prop_log_01"] = "Tronc d'arbre",
    },
}

local function cellKey(coords)
    local cx = math.floor(coords.x / ZONE_CELL)
    local cy = math.floor(coords.y / ZONE_CELL)
    return ("%d:%d"):format(cx, cy)
end

local function propPayload(prop)
    local rotation = nil
    if prop.position and prop.position.rotation then
        rotation = {
            x = prop.position.rotation.x,
            y = prop.position.rotation.y,
            z = prop.position.rotation.z,
        }
    end
    return {
        id = prop.id,
        model = prop.model,
        label = prop.label,
        position = {
            coords = vector3(prop.position.coords.x, prop.position.coords.y, prop.position.coords.z),
            rotation = rotation,
        },
    }
end

local function zonePayload(zone)
    local props = {}
    for i = 1, #zone.props do
        props[i] = zone.props[i]
    end
    return {
        id = zone.id,
        version = zone.version,
        center = vector3(zone.center.x, zone.center.y, zone.center.z),
        radius = zone.radius,
        props = props,
    }
end

function PS.BuildZoneData()
    local out = {}
    for i = 1, #PS.Zones do
        out[i] = zonePayload(PS.Zones[i])
    end
    return out
end

function PS.BuildPropsData()
    local out = {}
    for id, prop in pairs(PS.BuilderProps) do
        out[id] = propPayload(prop)
    end
    return out
end

function PS.ZonePropsPayload(zone)
    local out = {}
    for i = 1, #zone.props do
        local prop = PS.BuilderProps[zone.props[i]]
        if prop then
            out[#out + 1] = propPayload(prop)
        end
    end
    return out
end

function PS.RebuildZones(bumpChanged)
    local buckets = {}
    for id, prop in pairs(PS.BuilderProps) do
        local key = cellKey(prop.position.coords)
        buckets[key] = buckets[key] or {}
        buckets[key][#buckets[key] + 1] = id
    end

    local total = #PS.Zones
    for key in pairs(buckets) do
        if not PS.ZoneByCell[key] then
            total = total + 1
            PS.ZoneByCell[key] = total
        end
    end

    local cellByIndex = {}
    for key, index in pairs(PS.ZoneByCell) do
        cellByIndex[index] = key
    end

    local changed = {}
    local created = {}

    for index = 1, total do
        local existing = PS.Zones[index]
        local cell = cellByIndex[index] or (existing and existing.cell) or ("empty:" .. index)
        local propIds = buckets[cell] or {}
        table.sort(propIds)

        local sumX, sumY, sumZ = 0.0, 0.0, 0.0
        for i = 1, #propIds do
            local prop = PS.BuilderProps[propIds[i]]
            sumX = sumX + prop.position.coords.x
            sumY = sumY + prop.position.coords.y
            sumZ = sumZ + prop.position.coords.z
        end

        local center
        if #propIds > 0 then
            center = { x = sumX / #propIds, y = sumY / #propIds, z = sumZ / #propIds }
        else
            center = existing and existing.center or { x = 0.0, y = 0.0, z = 0.0 }
        end

        local zone = {
            id = index,
            cell = cell,
            version = existing and existing.version or 1,
            center = center,
            radius = ZONE_RADIUS,
            props = propIds,
        }

        if not existing then
            created[#created + 1] = index
        elseif bumpChanged then
            local same = #existing.props == #zone.props
            if same then
                for i = 1, #zone.props do
                    if existing.props[i] ~= zone.props[i] then
                        same = false
                        break
                    end
                end
            end
            if not same then
                zone.version = existing.version + 1
                changed[#changed + 1] = index
            end
        end

        PS.Zones[index] = zone
        PS.ZoneByCell[cell] = index
    end

    return changed, created
end

function PS.BumpZoneForProp(propId)
    for i = 1, #PS.Zones do
        local zone = PS.Zones[i]
        for j = 1, #zone.props do
            if zone.props[j] == propId then
                zone.version = zone.version + 1
                return zone
            end
        end
    end
    return nil
end

function PS.BroadcastZone(zone)
    TriggerClientEvent("propsBuilder:updateZoneProps", -1, zone.id, zonePayload(zone), PS.ZonePropsPayload(zone))
end

function PS.LoadBuilderProps()
    local now = PS.Now()
    MySQL.update.await("DELETE FROM propsbuilder_props WHERE duration_type = 1")
    MySQL.update.await("DELETE FROM propsbuilder_props WHERE duration_type = 2 AND expires_at > 0 AND expires_at < ?", { now })

    local rows = MySQL.query.await("SELECT * FROM propsbuilder_props") or {}
    PS.BuilderProps = {}

    for i = 1, #rows do
        local position = PS.Decode(rows[i].position, nil)
        if type(position) == "table" and PS.IsVec3(position.coords) then
            PS.BuilderProps[rows[i].id] = {
                id = rows[i].id,
                model = rows[i].model,
                label = rows[i].label,
                position = {
                    coords = PS.ReadVec3(position.coords),
                    rotation = PS.ReadVec3(position.rotation),
                },
                owner_identifier = rows[i].owner_identifier,
                owner_name = rows[i].owner_name,
                durationType = rows[i].duration_type or 3,
                duration = rows[i].duration,
                createdAt = rows[i].created_at or 0,
                expiresAt = rows[i].expires_at or 0,
            }
        end
    end

    PS.Zones = {}
    PS.ZoneByCell = {}
    PS.RebuildZones(false)
end

local function propsLimits(xPlayer)
    local tier = PS.ToInt(xPlayer.vipTier) or 0
    if VIPConfig and VIPConfig.GetPropsLimits then
        local limits = VIPConfig.GetPropsLimits(tier)
        return { temporary = limits.temporary or 0, permanent = limits.permanent or 0 }
    end
    return { temporary = 0, permanent = 0 }
end

local function countPlayerProps(identifier)
    local temporary, permanent = 0, 0
    for _, prop in pairs(PS.BuilderProps) do
        if prop.owner_identifier == identifier then
            if prop.durationType == 3 then
                permanent = permanent + 1
            else
                temporary = temporary + 1
            end
        end
    end
    return temporary, permanent
end

local function staffProps(xPlayer)
    return xPlayer.hasPermission("props_builder") or PS.IsStaff(xPlayer)
end

RegisterServerCallback("propsBuilder:getConfig", function(source)
    return { PropsList = PS.PropsCatalog }
end)

RegisterServerCallback("propsBuilder:getPlayerStats", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { temporary = 0, permanent = 0, limits = { temporary = 0, permanent = 0 } } end
    local temporary, permanent = countPlayerProps(xPlayer.identifier)
    return { temporary = temporary, permanent = permanent, limits = propsLimits(xPlayer) }
end)

local function propListEntry(prop)
    return {
        id = prop.id,
        model = prop.model,
        label = prop.label,
        position = {
            coords = { x = prop.position.coords.x, y = prop.position.coords.y, z = prop.position.coords.z },
            rotation = prop.position.rotation,
        },
        durationType = prop.durationType,
        duration = prop.duration,
        owner = prop.owner_name,
        createdAt = PS.FormatDateTime(prop.createdAt),
        expiresAt = prop.expiresAt > 0 and PS.FormatDateTime(prop.expiresAt) or nil,
        expiresAtRaw = prop.expiresAt > 0 and (prop.expiresAt * 1000) or nil,
        isTemporary = prop.durationType == 1,
    }
end

RegisterServerCallback("propsBuilder:getPropsList", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not staffProps(xPlayer) then return {} end

    local out = {}
    for _, prop in pairs(PS.BuilderProps) do
        out[#out + 1] = propListEntry(prop)
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end)

RegisterServerCallback("propsBuilder:getPlayerProps", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local out = {}
    for id, prop in pairs(PS.BuilderProps) do
        if prop.owner_identifier == xPlayer.identifier then
            out[id] = propListEntry(prop)
        end
    end
    return out
end)

local function parsePropsData(data)
    if type(data) ~= "table" then return nil end

    local model = PS.SafeString(data.model, 64)
    if not model then return nil end

    local position = data.position
    if type(position) ~= "table" then return nil end

    local coords = PS.ReadVec3(position.coords)
    if not coords then return nil end

    local durationType = PS.ToInt(data.durationType) or 1
    if durationType < 1 or durationType > 3 then durationType = 1 end

    local duration = PS.ToInt(data.duration)
    if durationType == 2 then
        if not duration or duration < 1 then duration = 1 end
        if duration > 30 then duration = 30 end
    else
        duration = nil
    end

    return {
        model = model,
        label = PS.SafeString(data.label, 64) or model,
        coords = coords,
        rotation = PS.ReadVec3(position.rotation),
        durationType = durationType,
        duration = duration,
    }
end

RegisterNetEvent("core:propsBuilder:createProp", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local parsed = parsePropsData(data)
    if not parsed then return end

    local isStaff = staffProps(xPlayer)
    if not isStaff then
        local limits = propsLimits(xPlayer)
        local temporary, permanent = countPlayerProps(xPlayer.identifier)
        if parsed.durationType == 3 then
            if permanent >= limits.permanent then
                xPlayer.showNotification({ type = "ROUGE", content = "Limite d'objets permanents atteinte." })
                return
            end
        else
            if temporary >= limits.temporary then
                xPlayer.showNotification({ type = "ROUGE", content = "Limite d'objets temporaires atteinte." })
                return
            end
        end
    end

    local now = PS.Now()
    local expiresAt = 0
    if parsed.durationType == 2 then
        expiresAt = now + (parsed.duration * 86400)
    elseif parsed.durationType == 3 then
        expiresAt = PERMANENT_EXPIRE
    end

    local position = { coords = parsed.coords, rotation = parsed.rotation }

    local id = MySQL.insert.await([[
        INSERT INTO propsbuilder_props (model, label, position, owner_identifier, owner_name, duration_type, duration, created_at, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        parsed.model, parsed.label, PS.Encode(position),
        xPlayer.identifier, xPlayer.name,
        parsed.durationType, parsed.duration, now, expiresAt,
    })

    if not id then return end

    PS.BuilderProps[id] = {
        id = id,
        model = parsed.model,
        label = parsed.label,
        position = position,
        owner_identifier = xPlayer.identifier,
        owner_name = xPlayer.name,
        durationType = parsed.durationType,
        duration = parsed.duration,
        createdAt = now,
        expiresAt = expiresAt,
    }

    local changed, created = PS.RebuildZones(true)

    for i = 1, #created do
        local zone = PS.Zones[created[i]]
        TriggerClientEvent("propsBuilder:CreateZone", -1, zone.id, zonePayload(zone), propPayload(PS.BuilderProps[id]))
    end
    for i = 1, #changed do
        PS.BroadcastZone(PS.Zones[changed[i]])
    end

    xPlayer.showNotification({ type = "VERT", content = "Objet cree." })
end)

RegisterNetEvent("propsBuilder:updateProp", function(propId, data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = PS.ToInt(propId)
    if not id then return end

    local prop = PS.BuilderProps[id]
    if not prop then return end

    if prop.owner_identifier ~= xPlayer.identifier and not staffProps(xPlayer) then return end

    local parsed = parsePropsData(data)
    if not parsed then return end

    local now = PS.Now()
    local expiresAt = 0
    if parsed.durationType == 2 then
        expiresAt = now + (parsed.duration * 86400)
    elseif parsed.durationType == 3 then
        expiresAt = PERMANENT_EXPIRE
    end

    prop.model = parsed.model
    prop.label = parsed.label
    prop.position = { coords = parsed.coords, rotation = parsed.rotation }
    prop.durationType = parsed.durationType
    prop.duration = parsed.duration
    prop.expiresAt = expiresAt

    MySQL.update.await([[
        UPDATE propsbuilder_props SET model = ?, label = ?, position = ?, duration_type = ?, duration = ?, expires_at = ? WHERE id = ?
    ]], {
        prop.model, prop.label, PS.Encode(prop.position), prop.durationType, prop.duration, prop.expiresAt, id,
    })

    local changed, created = PS.RebuildZones(true)
    for i = 1, #created do
        local zone = PS.Zones[created[i]]
        TriggerClientEvent("propsBuilder:CreateZone", -1, zone.id, zonePayload(zone), propPayload(prop))
    end
    for i = 1, #changed do
        PS.BroadcastZone(PS.Zones[changed[i]])
    end

    local zone = PS.BumpZoneForProp(id)
    if zone then
        PS.BroadcastZone(zone)
    end
end)

RegisterNetEvent("propsBuilder:deleteProp", function(propId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = PS.ToInt(propId)
    if not id then return end

    local prop = PS.BuilderProps[id]
    if not prop then return end

    if prop.owner_identifier ~= xPlayer.identifier and not staffProps(xPlayer) then return end

    PS.BuilderProps[id] = nil
    MySQL.update.await("DELETE FROM propsbuilder_props WHERE id = ?", { id })

    local changed = PS.RebuildZones(true)
    for i = 1, #changed do
        PS.BroadcastZone(PS.Zones[changed[i]])
    end

    xPlayer.showNotification({ type = "VERT", content = "Objet supprime." })
end)

RegisterNetEvent("propsBuilder:checkVersion", function(zoneId, version)
    local source = source
    if not VFW.GetPlayerFromId(source) then return end

    local id = PS.ToInt(zoneId)
    local clientVersion = PS.ToInt(version)
    if not id or not clientVersion then return end

    local zone = PS.Zones[id]
    if not zone then return end

    PS.ZoneOccupants[id] = PS.ZoneOccupants[id] or {}
    PS.ZoneOccupants[id][source] = true

    if clientVersion < zone.version then
        TriggerClientEvent("propsBuilder:updateZoneProps", source, zone.id, zonePayload(zone), PS.ZonePropsPayload(zone))
    end
end)

RegisterNetEvent("propsBuilder:playerExitZone", function(zoneId)
    local source = source
    local id = PS.ToInt(zoneId)
    if not id then return end
    if PS.ZoneOccupants[id] then
        PS.ZoneOccupants[id][source] = nil
    end
end)

AddEventHandler("vfw:playerDropped", function(source)
    for _, occupants in pairs(PS.ZoneOccupants) do
        occupants[source] = nil
    end
end)

AddEventHandler("vfw:playerLoaded", function(source)
    TriggerClientEvent("core:propsBuilder:Init", source, PS.BuildPropsData(), PS.BuildZoneData())
end)

CreateThread(function()
    while true do
        Wait(300000)
        local now = PS.Now()
        local removed = false
        for id, prop in pairs(PS.BuilderProps) do
            if prop.durationType == 2 and prop.expiresAt > 0 and prop.expiresAt < now then
                PS.BuilderProps[id] = nil
                MySQL.update("DELETE FROM propsbuilder_props WHERE id = ?", { id })
                removed = true
            end
        end
        if removed then
            local changed = PS.RebuildZones(true)
            for i = 1, #changed do
                PS.BroadcastZone(PS.Zones[changed[i]])
            end
        end
    end
end)

MySQL.ready(function()
    PS.LoadBuilderProps()
end)
