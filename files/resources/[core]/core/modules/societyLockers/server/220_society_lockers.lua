local lockers = {}
local reported = {}

local function reportError(query, err)
    if reported[query] then return end
    reported[query] = true
    console.error(("[SocietyLockers] SQL: %s"):format(tostring(err)))
end

local function sqlQuery(query, params)
    local ok, res = pcall(MySQL.query.await, query, params)
    if not ok then
        reportError(query, res)
        return nil
    end
    return res
end

local function sqlSingle(query, params)
    local ok, res = pcall(MySQL.single.await, query, params)
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

local ensuredChests = {}

local function ensureChest(chestId, label, maxWeight, maxSlots, owner)
    if type(chestId) ~= "string" or chestId == "" then return false end
    if ensuredChests[chestId] then return true end

    if VFW.Society and VFW.Society.EnsureChest then
        local ok = VFW.Society.EnsureChest(chestId, label, maxWeight, maxSlots, owner)
        if ok then
            ensuredChests[chestId] = true
            return true
        end
    end

    local ok = pcall(MySQL.update.await, [[
        INSERT INTO chests (chest_id, label, max_weight, max_slots, owner)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), max_weight = VALUES(max_weight), max_slots = VALUES(max_slots)
    ]], { chestId, label, maxWeight, maxSlots, owner or "" })

    if ok then
        ensuredChests[chestId] = true
        return true
    end

    return false
end

local function decodePosition(value)
    local pos = VFW.DB.Decode(value, nil)
    if type(pos) ~= "table" then return { x = 0.0, y = 0.0, z = 0.0, h = 0.0 } end
    return {
        x = tonumber(pos.x) or 0.0,
        y = tonumber(pos.y) or 0.0,
        z = tonumber(pos.z) or 0.0,
        h = tonumber(pos.h) or 0.0,
    }
end

local function normalize(row)
    return {
        id = row.id,
        label = row.label or "Casier",
        position = decodePosition(row.position),
        job = row.job or "",
        maxWeight = tonumber(row.max_weight) or 500,
        maxSlots = tonumber(row.max_slots) or 50,
        floatingZ = tonumber(row.floating_z) or 0.5,
        gradeMin = tonumber(row.grade_min) or 0,
    }
end

local function loadLockers()
    local rows = sqlQuery("SELECT * FROM society_lockers") or {}
    local out = {}

    for i = 1, #rows do
        local locker = normalize(rows[i])
        out[locker.id] = locker
    end

    lockers = out
    console.init("SocietyLockers", ("%d casiers chargés"):format(#rows))
    return out
end

local function lockersForJob(jobName)
    local out = {}
    if type(jobName) ~= "string" then return out end

    for id, locker in pairs(lockers) do
        if locker.job == jobName then
            out[id] = locker
        end
    end

    return out
end

local function sendLockers(source, jobName)
    TriggerClientEvent("core:societyLockers:retrieve", source, lockersForJob(jobName))
end

local function isManager(xPlayer, locker)
    if not xPlayer or not xPlayer.job then return false end
    if xPlayer.job.name ~= locker.job then return false end
    if xPlayer.job.grade_is_boss == true or xPlayer.job.grade_is_boss == 1 then return true end
    return xPlayer.job.grade == 98 or xPlayer.job.grade == 99
end

local function canAccess(xPlayer, locker)
    if not xPlayer or not xPlayer.job then return false end
    if xPlayer.job.name ~= locker.job then return false end
    if locker.gradeMin and locker.gradeMin > 0 and (xPlayer.job.grade or 0) < locker.gradeMin then return false end
    return true
end

local function isNear(xPlayer, locker)
    local coords = xPlayer.getCoords()
    local dx = coords.x - locker.position.x
    local dy = coords.y - locker.position.y
    local dz = coords.z - locker.position.z
    return (dx * dx + dy * dy + dz * dz) <= 100.0
end

local function chestIdFor(locker, identifier)
    return ("societylocker:%d:%s"):format(locker.id, identifier)
end

local function getChestRow(lockerId, identifier)
    return sqlSingle("SELECT * FROM society_locker_chests WHERE locker_id = ? AND identifier = ?", { lockerId, identifier })
end

local function ensurePersonalChest(locker, xPlayer)
    local identifier = xPlayer.identifier
    if type(identifier) ~= "string" or identifier == "" then return nil end

    local chestId = chestIdFor(locker, identifier)
    local row = getChestRow(locker.id, identifier)

    if not row then
        sqlInsert([[
            INSERT INTO society_locker_chests (locker_id, identifier, chest_id, player_name, job)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE chest_id = VALUES(chest_id), player_name = VALUES(player_name), job = VALUES(job)
        ]], { locker.id, identifier, chestId, xPlayer.name or "Inconnu", locker.job })
    else
        chestId = row.chest_id or chestId
        sqlUpdate("UPDATE society_locker_chests SET player_name = ?, job = ? WHERE id = ?", {
            xPlayer.name or row.player_name or "Inconnu", locker.job, row.id,
        })
    end

    ensureChest(chestId, ("%s - %s"):format(locker.label, xPlayer.name or "Casier"), locker.maxWeight, locker.maxSlots, locker.job)

    return chestId
end

local function chestContent(chestId)
    local cached = VFW.Inventory and VFW.Inventory.Chests and VFW.Inventory.Chests[chestId]
    if cached and type(cached.items) == "table" then return cached.items end

    local row = sqlSingle("SELECT items FROM chests WHERE chest_id = ?", { chestId })
    if not row then return {} end

    local decoded = VFW.DB.Decode(row.items, {})
    if type(decoded) ~= "table" then return {} end
    return decoded
end

local function chestWeight(chestId)
    local rows = chestContent(chestId)

    local weight, count, items = 0, 0, {}
    for i = 1, #rows do
        local row = rows[i]
        local def = VFW.Items[row.name]
        local amount = tonumber(row.count) or 0
        weight = weight + ((def and def.weight or 0) * amount)
        count = count + amount
        items[#items + 1] = { name = row.name, label = def and def.label or row.name, count = amount }
    end

    return math.floor(weight), count, items
end

local function employeeLockers(lockerId)
    local locker = lockers[lockerId]
    if not locker then return {} end

    local rows = sqlQuery("SELECT * FROM society_locker_chests WHERE locker_id = ?", { lockerId }) or {}
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        local weight = chestWeight(row.chest_id)
        out[#out + 1] = {
            playerName = tostring(row.player_name or "Inconnu"),
            chestId = row.chest_id,
            identifier = row.identifier,
            weight = weight,
            maxWeight = locker.maxWeight,
        }
    end

    table.sort(out, function(a, b) return a.playerName < b.playerName end)

    return out
end

local function archiveChest(lockerId, identifier)
    local locker = lockers[lockerId]
    local row = getChestRow(lockerId, identifier)
    if not row then return end

    local weight, count, items = chestWeight(row.chest_id)

    if count > 0 then
        sqlInsert([[
            INSERT INTO society_lockers_archived
                (locker_id, job, identifier, player_name, chest_id, items, item_count, total_weight)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            lockerId, locker and locker.job or (row.job or ""), identifier,
            row.player_name or "Inconnu", row.chest_id,
            VFW.DB.Encode(items), count, weight,
        })
    end

    sqlUpdate("DELETE FROM society_locker_chests WHERE id = ?", { row.id })
end

local function archiveJobLockers(identifier, jobName)
    if type(identifier) ~= "string" or type(jobName) ~= "string" then return end

    for id, locker in pairs(lockers) do
        if locker.job == jobName then
            archiveChest(id, identifier)
        end
    end
end

RegisterNetEvent("core:societyLockers:open", function(lockerId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(lockerId)
    if not id then return end

    local locker = lockers[id]
    if not locker then
        TriggerClientEvent("core:societyLockers:openInventory", source, nil)
        return
    end

    if not canAccess(xPlayer, locker) or not isNear(xPlayer, locker) then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous n'avez pas accès à ce casier." })
        TriggerClientEvent("core:societyLockers:openInventory", source, nil)
        return
    end

    if isManager(xPlayer, locker) then
        TriggerClientEvent("core:societyLockers:openManageMenu", source, locker.id, locker.label, employeeLockers(locker.id))
        return
    end

    local chestId = ensurePersonalChest(locker, xPlayer)
    if not chestId then
        TriggerClientEvent("core:societyLockers:openInventory", source, nil)
        return
    end

    TriggerClientEvent("core:societyLockers:openInventory", source, chestId, locker.label, locker.maxSlots)
end)

RegisterNetEvent("core:societyLockers:openOwnLocker", function(lockerId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(lockerId)
    if not id then return end

    local locker = lockers[id]
    if not locker or not canAccess(xPlayer, locker) or not isNear(xPlayer, locker) then
        TriggerClientEvent("core:societyLockers:openInventory", source, nil)
        return
    end

    local chestId = ensurePersonalChest(locker, xPlayer)
    if not chestId then
        TriggerClientEvent("core:societyLockers:openInventory", source, nil)
        return
    end

    TriggerClientEvent("core:societyLockers:openInventory", source, chestId, locker.label, locker.maxSlots)
end)

RegisterNetEvent("core:societyLockers:openEmployeeLocker", function(lockerId, chestId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(lockerId)
    if not id then return end
    if type(chestId) ~= "string" and type(chestId) ~= "number" then return end

    local locker = lockers[id]
    if not locker or not isManager(xPlayer, locker) or not isNear(xPlayer, locker) then
        xPlayer.showNotification({ type = "ROUGE", content = "Accès refusé." })
        TriggerClientEvent("core:societyLockers:openInventory", source, nil)
        return
    end

    local row = sqlSingle("SELECT * FROM society_locker_chests WHERE locker_id = ? AND chest_id = ?", {
        id, tostring(chestId),
    })

    if not row then
        TriggerClientEvent("core:societyLockers:openInventory", source, nil)
        return
    end

    ensureChest(row.chest_id, ("%s - %s"):format(locker.label, row.player_name or "Casier"), locker.maxWeight, locker.maxSlots, locker.job)

    TriggerClientEvent("core:societyLockers:openInventory", source, row.chest_id,
        ("%s (%s)"):format(locker.label, row.player_name or "Employé"), locker.maxSlots)
end)

RegisterNetEvent("core:societyLockers:create", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_society_lockers") then return end
    if type(data) ~= "table" then return end
    if type(data.label) ~= "string" or data.label == "" then return end
    if type(data.job) ~= "string" or data.job == "" then return end
    if type(data.position) ~= "table" then return end

    local position = decodePosition(VFW.DB.Encode(data.position))

    local id = sqlInsert([[
        INSERT INTO society_lockers (label, position, job, max_weight, max_slots, floating_z, grade_min)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.label:sub(1, 120), VFW.DB.Encode(position), data.job:sub(1, 60),
        math.floor(tonumber(data.maxWeight) or 500),
        math.floor(tonumber(data.maxSlots) or 50),
        tonumber(data.floatingZ) or 0.5,
        math.floor(tonumber(data.gradeMin) or 0),
    })

    if not id then return end

    local locker = normalize({
        id = id, label = data.label:sub(1, 120), position = VFW.DB.Encode(position), job = data.job:sub(1, 60),
        max_weight = tonumber(data.maxWeight) or 500, max_slots = tonumber(data.maxSlots) or 50,
        floating_z = tonumber(data.floatingZ) or 0.5, grade_min = tonumber(data.gradeMin) or 0,
    })

    lockers[id] = locker

    for src, other in pairs(VFW.Players) do
        if other.job and other.job.name == locker.job then
            TriggerClientEvent("core:societyLockers:create", src, locker)
        end
    end
end)

RegisterNetEvent("core:societyLockers:update", function(lockerId, data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_society_lockers") then return end

    local id = tonumber(lockerId)
    if not id then return end
    if type(data) ~= "table" then return end

    local existing = lockers[id]
    if not existing then return end

    local label = type(data.label) == "string" and data.label ~= "" and data.label:sub(1, 120) or existing.label
    local job = type(data.job) == "string" and data.job ~= "" and data.job:sub(1, 60) or existing.job
    local position = type(data.position) == "table" and decodePosition(VFW.DB.Encode(data.position)) or existing.position

    sqlUpdate([[
        UPDATE society_lockers SET label = ?, position = ?, job = ?, max_weight = ?, max_slots = ?, floating_z = ?, grade_min = ?
        WHERE id = ?
    ]], {
        label, VFW.DB.Encode(position), job,
        math.floor(tonumber(data.maxWeight) or existing.maxWeight),
        math.floor(tonumber(data.maxSlots) or existing.maxSlots),
        tonumber(data.floatingZ) or existing.floatingZ,
        math.floor(tonumber(data.gradeMin) or existing.gradeMin),
        id,
    })

    local locker = {
        id = id,
        label = label,
        position = position,
        job = job,
        maxWeight = math.floor(tonumber(data.maxWeight) or existing.maxWeight),
        maxSlots = math.floor(tonumber(data.maxSlots) or existing.maxSlots),
        floatingZ = tonumber(data.floatingZ) or existing.floatingZ,
        gradeMin = math.floor(tonumber(data.gradeMin) or existing.gradeMin),
    }

    lockers[id] = locker

    for src, other in pairs(VFW.Players) do
        if other.job and other.job.name == locker.job then
            TriggerClientEvent("core:societyLockers:update", src, locker)
        elseif other.job and other.job.name == existing.job then
            TriggerClientEvent("core:societyLockers:remove", src, id)
        end
    end
end)

RegisterNetEvent("core:societyLockers:remove", function(lockerId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_society_lockers") then return end

    local id = tonumber(lockerId)
    if not id then return end
    if not lockers[id] then return end

    sqlUpdate("DELETE FROM society_lockers WHERE id = ?", { id })
    sqlUpdate("DELETE FROM society_locker_chests WHERE locker_id = ?", { id })

    lockers[id] = nil

    TriggerClientEvent("core:societyLockers:remove", -1, id)
end)

local function registerCallback(name, handler)
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[SocietyLockers] Callback '%s' déjà enregistré ailleurs: %s"):format(name, tostring(err)))
    end
end

registerCallback("core:societyLockers:getAll", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_society_lockers") then return {} end
    return lockers
end)

registerCallback("core:societyLockers:getByJob", function(source, jobName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if type(jobName) ~= "string" then return {} end
    if not xPlayer.hasPermission("manage_society_lockers") and (not xPlayer.job or xPlayer.job.name ~= jobName) then
        return {}
    end

    local out = {}
    for _, locker in pairs(lockers) do
        if locker.job == jobName then
            out[#out + 1] = locker
        end
    end

    table.sort(out, function(a, b) return a.id < b.id end)

    return out
end)

registerCallback("core:societyLockers:getEmployeeLockers", function(source, lockerId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local id = tonumber(lockerId)
    if not id then return {} end

    local locker = lockers[id]
    if not locker then return {} end
    if not isManager(xPlayer, locker) and not xPlayer.hasPermission("manage_society_lockers") then return {} end

    return employeeLockers(id)
end)

registerCallback("core:societyLockers:getArchivedLockers", function(source, jobName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if type(jobName) ~= "string" then return {} end
    if not xPlayer.hasPermission("manage_society_lockers") then
        if not xPlayer.job or xPlayer.job.name ~= jobName then return {} end
        if not (xPlayer.job.grade == 98 or xPlayer.job.grade == 99 or xPlayer.job.grade_is_boss) then return {} end
    end

    local rows = sqlQuery("SELECT * FROM society_lockers_archived WHERE job = ? ORDER BY archived_at DESC", { jobName }) or {}
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        local items = VFW.DB.Decode(row.items, {})
        if type(items) ~= "table" then items = {} end

        out[#out + 1] = {
            id = row.id,
            lockerId = row.locker_id,
            job = row.job,
            playerName = tostring(row.player_name or "Inconnu"),
            itemCount = tonumber(row.item_count) or 0,
            totalWeight = tonumber(row.total_weight) or 0,
            archivedAtFormatted = tostring(row.archived_at or ""),
            items = items,
        }
    end

    return out
end)

registerCallback("core:societyLockers:getArchivedByLocker", function(source, lockerId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local id = tonumber(lockerId)
    if not id then return {} end

    local locker = lockers[id]
    if not xPlayer.hasPermission("manage_society_lockers") then
        if not locker or not isManager(xPlayer, locker) then return {} end
    end

    local rows = sqlQuery("SELECT * FROM society_lockers_archived WHERE locker_id = ? ORDER BY archived_at DESC", { id }) or {}
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        local items = VFW.DB.Decode(row.items, {})
        if type(items) ~= "table" then items = {} end

        out[#out + 1] = {
            id = row.id,
            lockerId = row.locker_id,
            playerName = tostring(row.player_name or "Inconnu"),
            itemCount = tonumber(row.item_count) or 0,
            totalWeight = tonumber(row.total_weight) or 0,
            archivedAtFormatted = tostring(row.archived_at or ""),
            items = items,
        }
    end

    return out
end)

registerCallback("core:societyLockers:deleteArchivedLocker", function(source, archivedId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local id = tonumber(archivedId)
    if not id then return false, "Cet identifiant n'est pas valide" end

    local row = sqlSingle("SELECT * FROM society_lockers_archived WHERE id = ?", { id })
    if not row then return false, "Archive introuvable" end

    if not xPlayer.hasPermission("manage_society_lockers") then
        if not xPlayer.job or xPlayer.job.name ~= row.job then return false, "Accès refusé" end
        if not (xPlayer.job.grade == 98 or xPlayer.job.grade == 99 or xPlayer.job.grade_is_boss) then
            return false, "Accès refusé"
        end
    end

    sqlUpdate("DELETE FROM society_lockers_archived WHERE id = ?", { id })
    sqlUpdate("UPDATE chests SET items = ? WHERE chest_id = ?", { VFW.DB.Encode({}), row.chest_id })

    local cached = VFW.Inventory and VFW.Inventory.Chests and VFW.Inventory.Chests[row.chest_id]
    if cached then
        cached.items = {}
        if VFW.Inventory.MarkChestDirty then VFW.Inventory.MarkChestDirty(row.chest_id) end
    end

    return true, "Archive supprimée"
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    local target = source

    SetTimeout(2500, function()
        local player = VFW.GetPlayerFromId(target)
        if not player then return end
        sendLockers(target, player.job and player.job.name or "unemployed")
    end)
end)

AddEventHandler("vfw:setJob", function(source, job, previous)
    if not job then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer and previous and previous.name and previous.name ~= job.name then
        archiveJobLockers(xPlayer.identifier, previous.name)
    end

    sendLockers(source, job.name)
end)

MySQL.ready(function()
    loadLockers()
end)
