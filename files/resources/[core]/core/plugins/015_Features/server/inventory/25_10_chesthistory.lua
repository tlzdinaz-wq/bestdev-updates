local Inv = VFW.Inventory

local PAGE_SIZE = 25

local function canViewHistory(xPlayer, chestId)
    if xPlayer.hasPermission("inventaire") then return true end
    if xPlayer.hasPermission("staff_logs") then return true end
    if xPlayer.hasPermission("chest_builder") then return true end

    local job = xPlayer.job
    if job and job.grade_is_boss then
        if type(chestId) == "string" and chestId:find(job.name, 1, true) then
            return true
        end

        local builderId = type(chestId) == "string" and chestId:match("^chestbuilder:(%d+)$") or nil
        if builderId and ChestBuilderServer then
            local chest = ChestBuilderServer.Find(tonumber(builderId))
            if chest and chest.accessName == job.name then return true end
        end
    end

    return false
end

local function fetchHistory(chestId, page, search)
    page = math.floor(tonumber(page) or 1)
    if page < 1 then page = 1 end

    local offset = (page - 1) * PAGE_SIZE
    local like = "%" .. tostring(search or "") .. "%"

    local rows, countRow

    if search and search ~= "" then
        rows = MySQL.query.await([[
            SELECT * FROM chest_history
            WHERE chest_id = ? AND (player_name LIKE ? OR item_name LIKE ? OR citizenid LIKE ?)
            ORDER BY id DESC LIMIT ? OFFSET ?
        ]], { chestId, like, like, like, PAGE_SIZE, offset }) or {}

        countRow = MySQL.single.await([[
            SELECT COUNT(*) AS total FROM chest_history
            WHERE chest_id = ? AND (player_name LIKE ? OR item_name LIKE ? OR citizenid LIKE ?)
        ]], { chestId, like, like, like })
    else
        rows = MySQL.query.await([[
            SELECT * FROM chest_history WHERE chest_id = ? ORDER BY id DESC LIMIT ? OFFSET ?
        ]], { chestId, PAGE_SIZE, offset }) or {}

        countRow = MySQL.single.await("SELECT COUNT(*) AS total FROM chest_history WHERE chest_id = ?", { chestId })
    end

    local entries = {}
    for i = 1, #rows do
        local row = rows[i]
        local def = Inv.Def(row.item_name)
        entries[i] = {
            id = row.id,
            chestId = row.chest_id,
            citizenid = row.citizenid,
            playerName = row.player_name,
            name = row.player_name,
            action = row.action,
            itemName = row.item_name,
            itemLabel = def and def.label or row.item_name,
            count = tonumber(row.count) or 0,
            meta = VFW.DB.Decode(row.meta, {}),
            createdAt = tostring(row.created_at),
            date = tostring(row.created_at),
        }
    end

    local total = countRow and tonumber(countRow.total) or #entries
    local pages = math.max(1, math.ceil(total / PAGE_SIZE))

    return {
        chestId = chestId,
        page = page,
        pages = pages,
        total = total,
        pageSize = PAGE_SIZE,
        search = search or "",
        entries = entries,
        items = entries,
    }
end

Inv.RegisterNet("chestHistory:requestData", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if type(data) ~= "table" then data = {} end

    local chestId = data.chestId or data.chest_id
    if type(chestId) ~= "string" or chestId == "" then return end
    if not canViewHistory(xPlayer, chestId) then return end

    local search = data.search or data.query
    if type(search) ~= "string" then search = "" end
    search = search:gsub("[%%_]", ""):sub(1, 40)

    TriggerClientEvent("chestHistory:receiveData", source, fetchHistory(chestId, data.page, search))
end)

Inv.RegisterNet("chestHistory:requestOpen", function(chestId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if type(chestId) ~= "string" or chestId == "" then return end

    if not canViewHistory(xPlayer, chestId) then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous n'avez pas acces a cet historique." })
        return
    end

    TriggerClientEvent("chestHistory:open", source, fetchHistory(chestId, 1, ""))
end)

VFW.RegisterCommand("viewchesthistory", nil, function(source, xPlayer, args)
    local chestId = args[1]
    if type(chestId) ~= "string" or chestId == "" then
        xPlayer.showNotification({ type = "ROUGE", content = "Usage: /viewchesthistory <chestId>" })
        return
    end

    if not canViewHistory(xPlayer, chestId) then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous n'avez pas acces a cet historique." })
        return
    end

    TriggerClientEvent("chestHistory:open", source, fetchHistory(chestId, 1, ""))
end, {
    help = "Affiche l'historique d'un coffre",
    params = { { name = "chestId", help = "identifiant du coffre" } },
})
