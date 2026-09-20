local lockers = {}
local reported = {}

local function reportError(query, err)
    if reported[query] then return end
    reported[query] = true
    console.error(("[Lockers] SQL: %s"):format(tostring(err)))
end

local function sqlQuery(query, params)
    local ok, res = pcall(MySQL.query.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

local function sqlInsert(query, params)
    local ok, res = pcall(MySQL.insert.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

local function sqlUpdate(query, params)
    local ok, res = pcall(MySQL.update.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

local function decodePosition(value)
    local pos = VFW.DB.Decode(value, nil)
    if type(pos) ~= "table" then return { x = 0.0, y = 0.0, z = 0.0 } end
    return {
        x = tonumber(pos.x) or 0.0,
        y = tonumber(pos.y) or 0.0,
        z = tonumber(pos.z) or 0.0,
    }
end

local function decodeOutfits(value)
    local outfits = VFW.DB.Decode(value, nil)
    if type(outfits) ~= "table" then return {} end

    local dense = {}
    for _, outfit in pairs(outfits) do
        if type(outfit) == "table" and type(outfit.clothes) == "table" then
            dense[#dense + 1] = {
                label = tostring(outfit.label or "Tenue"),
                clothes = outfit.clothes,
            }
        end
    end

    return dense
end

local function normalize(row)
    local whitelistType = row.whitelist_type
    if whitelistType ~= "faction" then whitelistType = "job" end

    return {
        id = row.id,
        label = row.label or "Vestiaire",
        position = decodePosition(row.position),
        whitelistType = whitelistType,
        whitelistValue = row.whitelist_value or "",
        showBlip = row.show_blip == 1 or row.show_blip == true,
        floatingZ = tonumber(row.floating_z) or 0.5,
        outfits = decodeOutfits(row.outfits),
    }
end

local function loadLockers()
    local rows = sqlQuery("SELECT * FROM lockers") or {}
    local out = {}

    for i = 1, #rows do
        local locker = normalize(rows[i])
        out[locker.id] = locker
    end

    lockers = out
    console.init("Lockers", ("%d vestiaires chargés"):format(#rows))
    return out
end

local function playerGroups(xPlayer)
    local groups = {}
    if not xPlayer then return groups end

    if xPlayer.job and type(xPlayer.job.name) == "string" then
        groups[xPlayer.job.name] = true
    end
    if xPlayer.job2 and type(xPlayer.job2.name) == "string" then
        groups[xPlayer.job2.name] = true
    end
    if type(xPlayer.faction) == "string" and xPlayer.faction ~= "" then
        groups[xPlayer.faction] = true
    end
    if type(xPlayer.faction) == "table" and type(xPlayer.faction.name) == "string" then
        groups[xPlayer.faction.name] = true
    end

    return groups
end

local function lockersForPlayer(xPlayer)
    local groups = playerGroups(xPlayer)
    local out = {}

    for id, locker in pairs(lockers) do
        if locker.whitelistValue ~= "" and groups[locker.whitelistValue] then
            out[id] = locker
        end
    end

    return out
end

local function sendLockers(source, xPlayer)
    TriggerClientEvent("core:lockers:retrieve", source, lockersForPlayer(xPlayer))
end

local function isGroupBoss(xPlayer, locker)
    if not xPlayer then return false end

    if locker.whitelistType == "faction" then
        local job2 = xPlayer.job2
        if job2 and job2.name == locker.whitelistValue then
            if job2.grade_is_boss == true or job2.grade_is_boss == 1 then return true end
            return job2.grade == 98 or job2.grade == 99
        end
        return false
    end

    local job = xPlayer.job
    if not job or job.name ~= locker.whitelistValue then return false end
    if job.grade_is_boss == true or job.grade_is_boss == 1 then return true end
    return job.grade == 98 or job.grade == 99
end

local function canManageOutfits(xPlayer, locker)
    if not xPlayer or not locker then return false end
    if locker.whitelistValue == "" then return false end
    if xPlayer.hasPermission("manage_lockers") then return true end
    return isGroupBoss(xPlayer, locker)
end

local function isNear(xPlayer, locker)
    local coords = xPlayer.getCoords()
    local dx = coords.x - locker.position.x
    local dy = coords.y - locker.position.y
    local dz = coords.z - locker.position.z
    return (dx * dx + dy * dy + dz * dz) <= 100.0
end

local function persistOutfits(locker)
    sqlUpdate("UPDATE lockers SET outfits = ? WHERE id = ?", { VFW.DB.Encode(locker.outfits), locker.id })
end

local function broadcastLocker(locker, eventName)
    for src, other in pairs(VFW.Players) do
        local groups = playerGroups(other)
        if groups[locker.whitelistValue] then
            TriggerClientEvent(eventName, src, locker)
        end
    end
end

RegisterNetEvent("core:lockers:addOutfit", function(lockerId, outfit)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(lockerId)
    if not id then return end

    local locker = lockers[id]
    if not locker then return end

    if type(outfit) ~= "table" then return end
    if type(outfit.clothes) ~= "table" or not next(outfit.clothes) then return end

    local label = type(outfit.label) == "string" and outfit.label or ""
    label = label:gsub("^%s+", ""):gsub("%s+$", "")
    if label == "" then return end

    if not canManageOutfits(xPlayer, locker) then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous n'avez pas la permission." })
        return
    end

    if not isNear(xPlayer, locker) and not xPlayer.hasPermission("manage_lockers") then return end

    if #locker.outfits >= 100 then
        xPlayer.showNotification({ type = "ROUGE", content = "Ce vestiaire est plein." })
        return
    end

    local clothes = {}
    local count = 0
    for key, value in pairs(outfit.clothes) do
        if type(key) == "string" and (type(value) == "number" or type(value) == "string") then
            clothes[key] = value
            count = count + 1
        end
    end

    if count == 0 then return end

    locker.outfits[#locker.outfits + 1] = { label = label:sub(1, 60), clothes = clothes }
    persistOutfits(locker)

    broadcastLocker(locker, "core:lockers:update")

    xPlayer.showNotification({ type = "VERT", content = "Tenue enregistrée." })
end)

RegisterNetEvent("core:lockers:removeOutfit", function(lockerId, index)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(lockerId)
    if not id then return end

    local locker = lockers[id]
    if not locker then return end

    if not canManageOutfits(xPlayer, locker) then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous n'avez pas la permission." })
        return
    end

    local position = tonumber(index)
    if position then
        position = math.floor(position)
        if not locker.outfits[position] then return end
        table.remove(locker.outfits, position)
    else
        if type(index) ~= "string" then return end
        local found = nil
        for i = 1, #locker.outfits do
            if locker.outfits[i].label == index then
                found = i
                break
            end
        end
        if not found then return end
        table.remove(locker.outfits, found)
    end

    persistOutfits(locker)
    broadcastLocker(locker, "core:lockers:update")

    xPlayer.showNotification({ type = "VERT", content = "Tenue supprimée." })
end)

RegisterNetEvent("core:lockers:create", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_lockers") then return end
    if type(data) ~= "table" then return end
    if type(data.label) ~= "string" or data.label == "" then return end
    if type(data.position) ~= "table" then return end
    if type(data.whitelistValue) ~= "string" or data.whitelistValue == "" then return end

    local whitelistType = data.whitelistType
    if whitelistType ~= "faction" then whitelistType = "job" end

    local position = decodePosition(VFW.DB.Encode(data.position))

    local id = sqlInsert([[
        INSERT INTO lockers (label, position, whitelist_type, whitelist_value, show_blip, floating_z, outfits)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.label:sub(1, 120), VFW.DB.Encode(position), whitelistType,
        data.whitelistValue:sub(1, 60),
        data.showBlip == false and 0 or 1,
        tonumber(data.floatingZ) or 0.5,
        VFW.DB.Encode({}),
    })

    if not id then return end

    lockers[id] = {
        id = id,
        label = data.label:sub(1, 120),
        position = position,
        whitelistType = whitelistType,
        whitelistValue = data.whitelistValue:sub(1, 60),
        showBlip = data.showBlip == false and false or true,
        floatingZ = tonumber(data.floatingZ) or 0.5,
        outfits = {},
    }

    broadcastLocker(lockers[id], "core:lockers:create")
end)

RegisterNetEvent("core:lockers:update", function(lockerId, data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_lockers") then return end

    local id = tonumber(lockerId)
    if not id then return end
    if type(data) ~= "table" then return end

    local existing = lockers[id]
    if not existing then return end

    local label = type(data.label) == "string" and data.label ~= "" and data.label:sub(1, 120) or existing.label
    local whitelistType = data.whitelistType
    if whitelistType ~= "faction" and whitelistType ~= "job" then whitelistType = existing.whitelistType end
    local whitelistValue = type(data.whitelistValue) == "string" and data.whitelistValue ~= ""
        and data.whitelistValue:sub(1, 60) or existing.whitelistValue
    local position = type(data.position) == "table" and decodePosition(VFW.DB.Encode(data.position)) or existing.position
    local showBlip = data.showBlip
    if type(showBlip) ~= "boolean" then showBlip = existing.showBlip end

    sqlUpdate([[
        UPDATE lockers SET label = ?, position = ?, whitelist_type = ?, whitelist_value = ?, show_blip = ?, floating_z = ?
        WHERE id = ?
    ]], {
        label, VFW.DB.Encode(position), whitelistType, whitelistValue,
        showBlip and 1 or 0, tonumber(data.floatingZ) or existing.floatingZ, id,
    })

    local previousValue = existing.whitelistValue

    lockers[id] = {
        id = id,
        label = label,
        position = position,
        whitelistType = whitelistType,
        whitelistValue = whitelistValue,
        showBlip = showBlip,
        floatingZ = tonumber(data.floatingZ) or existing.floatingZ,
        outfits = existing.outfits,
    }

    for src, other in pairs(VFW.Players) do
        local groups = playerGroups(other)
        if groups[whitelistValue] then
            TriggerClientEvent("core:lockers:update", src, lockers[id])
        elseif groups[previousValue] then
            TriggerClientEvent("core:lockers:remove", src, id)
        end
    end
end)

RegisterNetEvent("core:lockers:remove", function(lockerId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_lockers") then return end

    local id = tonumber(lockerId)
    if not id then return end
    if not lockers[id] then return end

    sqlUpdate("DELETE FROM lockers WHERE id = ?", { id })
    lockers[id] = nil

    TriggerClientEvent("core:lockers:remove", -1, id)
end)

local function registerCallback(name, handler)
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[Lockers] Callback '%s' déjà enregistré ailleurs: %s"):format(name, tostring(err)))
    end
end

registerCallback("core:lockers:getAll", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_lockers") then return {} end
    return lockers
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    local target = source

    SetTimeout(2500, function()
        local player = VFW.GetPlayerFromId(target)
        if not player then return end
        sendLockers(target, player)
    end)
end)

AddEventHandler("vfw:setJob", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    sendLockers(source, xPlayer)
end)

AddEventHandler("vfw:setJob2", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    sendLockers(source, xPlayer)
end)

MySQL.ready(function()
    loadLockers()
end)
