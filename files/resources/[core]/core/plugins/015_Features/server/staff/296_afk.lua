local sessions = {}
local usedBuckets = {}

local function bucketRange()
    local cfg = AFKConfig and AFKConfig.Instances or {}
    return cfg.bucketStart or 10000, cfg.bucketEnd or 10999
end

local function allocateBucket()
    local first, last = bucketRange()
    for bucket = first, last do
        if not usedBuckets[bucket] then
            usedBuckets[bucket] = true
            return bucket
        end
    end
    return nil
end

local function releaseBucket(bucket)
    if bucket then usedBuckets[bucket] = nil end
end

local function getPoints(identifier)
    local value = Staff29.Scalar("SELECT points FROM afk_points WHERE identifier = ?", { identifier }, 0)
    return math.floor(tonumber(value) or 0)
end

local function setPoints(identifier, points, addedMinutes)
    points = math.floor(points)
    if points < 0 then points = 0 end
    Staff29.Update([[
        INSERT INTO afk_points (identifier, points, total_minutes, updated_at) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE points = VALUES(points),
                                total_minutes = total_minutes + ?,
                                updated_at = VALUES(updated_at)
    ]], { identifier, points, addedMinutes or 0, Staff29.Now(), addedMinutes or 0 })
    return points
end

local function topLeaderboard(limit)
    local rows = Staff29.Query([[
        SELECT p.identifier, p.points, p.total_minutes, c.firstname, c.lastname
        FROM afk_points p
        LEFT JOIN characters c ON c.identifier = p.identifier
        ORDER BY p.points DESC LIMIT ?
    ]], { limit })

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        n = n + 1
        out[n] = {
            identifier = row.identifier,
            rank = n,
            name = ("%s %s"):format(row.firstname or "Joueur", row.lastname or "Inconnu"),
            points = math.floor(tonumber(row.points) or 0),
            total_time = math.floor((tonumber(row.total_minutes) or 0) * 60),
        }
    end
    return out
end

local function shopCases()
    local cases = {}
    local configCases = (AFKConfig and AFKConfig.Shop and AFKConfig.Shop.cases) or {}

    for id, data in pairs(configCases) do
        cases[id] = {
            itemName = data.itemName,
            name = data.name,
            description = data.description,
            price = math.floor(tonumber(data.price) or 0),
            image = data.image,
            prizes = data.prizes or {},
        }
    end

    local rows = Staff29.Query("SELECT case_id, item_name, name, description, price, image, prizes FROM afk_shop_cases")
    for i = 1, #rows do
        local row = rows[i]
        local prizes = Staff29.Decode(row.prizes, nil)
        cases[row.case_id] = {
            itemName = row.item_name,
            name = row.name,
            description = row.description,
            price = math.floor(tonumber(row.price) or 0),
            image = row.image,
            prizes = type(prizes) == "table" and prizes or {},
        }
    end

    return cases
end

local function drawPrize(prizes)
    local total = 0
    for i = 1, #prizes do
        total = total + (tonumber(prizes[i].chance) or 0)
    end
    if total <= 0 then return prizes[1] end

    local roll = math.random() * total
    local acc = 0
    for i = 1, #prizes do
        acc = acc + (tonumber(prizes[i].chance) or 0)
        if roll <= acc then return prizes[i] end
    end
    return prizes[#prizes]
end

local function awardPrize(xPlayer, prize)
    local kind = prize.type

    if kind == "money" then
        xPlayer.addAccountMoney("money", math.floor(tonumber(prize.amount) or 0), "afk-case")
    elseif kind == "item" or kind == "case" then
        local count = math.floor(tonumber(prize.count or prize.itemCount) or 1)
        if prize.itemName then xPlayer.addInventoryItem(prize.itemName, count, nil, true) end
    elseif kind == "weapon" then
        if prize.itemName then
            if VFW.Items and VFW.Items[prize.itemName] then
                xPlayer.addInventoryItem(prize.itemName, 1, { weaponId = VFW.GenerateUUID(), ammo = 0, components = {} }, true)
            else
                xPlayer.addWeapon(prize.itemName, 0)
            end
        end
    elseif kind == "vehicle" and prize.vehicleModel then
        local plate = ("AFK%05d"):format(math.random(0, 99999))
        while (Staff29.Scalar("SELECT COUNT(*) FROM owned_vehicles WHERE plate = ?", { plate }, 0) or 0) > 0 do
            plate = ("AFK%05d"):format(math.random(0, 99999))
        end
        Staff29.Insert([[
            INSERT INTO owned_vehicles (plate, owner, vehName, label, props, stored, pounded)
            VALUES (?, ?, ?, ?, ?, 1, 0)
        ]], { plate, xPlayer.identifier, prize.vehicleModel, prize.name or prize.vehicleModel,
              Staff29.Encode({ model = joaat(prize.vehicleModel), plate = plate }) })
    end
end

local function exitAFK(source, forced)
    local session = sessions[source]
    if not session then return end

    sessions[source] = nil
    releaseBucket(session.bucket)

    local xPlayer = VFW.GetPlayerFromId(source)
    pcall(SetPlayerRoutingBucket, source, 0)

    if not xPlayer then return end

    local total = getPoints(xPlayer.identifier)

    xPlayer.triggerEvent("core:afk:exited", {
        previousCoords = session.coords,
        previousHeading = session.heading,
        totalPoints = total,
        forcedExit = forced and true or false,
    })
end

Staff29.AFK = {
    GetPoints = getPoints,
    SetPoints = setPoints,
    IsInAFK = function(source) return sessions[source] ~= nil end,
}

RegisterNetEvent("core:afk:enterWithPosition", function(coords, heading)
    local source = source

    local position = Staff29.Vec(coords)
    local h = tonumber(heading) or 0.0
    if not position then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if sessions[source] then return end
    if not Staff29.RateLimit(source, "afkEnter", 3000) then return end

    local bucket = allocateBucket()
    if not bucket then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Zone AFK",
            message = "La zone AFK est pleine, réessayez plus tard.",
        })
        return
    end

    sessions[source] = {
        bucket = bucket,
        coords = position,
        heading = h,
        identifier = xPlayer.identifier,
        enteredAt = os.time(),
        lastTick = GetGameTimer(),
    }

    pcall(SetPlayerRoutingBucket, source, bucket)

    Staff29.Insert([[
        INSERT INTO afk_sessions (identifier, bucket, entered_at, prev_x, prev_y, prev_z, prev_heading)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { xPlayer.identifier, bucket, Staff29.Now(), position.x, position.y, position.z, h })

    local afkPos = AFKConfig.Position.coords
    local topCount = (AFKConfig.Leaderboard and AFKConfig.Leaderboard.topCount) or 3

    xPlayer.triggerEvent("core:afk:entered", {
        points = getPoints(xPlayer.identifier),
        position = { x = afkPos.x, y = afkPos.y, z = afkPos.z },
        heading = AFKConfig.Position.heading,
        leaderboard = topLeaderboard(topCount),
    })
end)

RegisterNetEvent("core:afk:exit", function()
    local source = source
    if not VFW.GetPlayerFromId(source) then return end
    exitAFK(source, false)
end)

Staff29.Cb("core:afk:getPoints", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    return getPoints(xPlayer.identifier)
end)

Staff29.Cb("core:afkshop:getShopCases", function(source)
    return shopCases()
end)

Staff29.Cb("core:afkshop:buyCase", function(source, caseId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { success = false, error = "Erreur interne", newPoints = 0 }
    end

    if not Staff29.IsString(caseId, 40) then
        return { success = false, error = "Cette caisse n'est pas valide", newPoints = getPoints(xPlayer.identifier) }
    end

    if not Staff29.RateLimit(source, "afkBuyCase", 1500) then
        return { success = false, error = "Veuillez patienter", newPoints = getPoints(xPlayer.identifier) }
    end

    local cases = shopCases()
    local caseData = cases[caseId]
    if not caseData or #caseData.prizes == 0 then
        return { success = false, error = "Caisse introuvable", newPoints = getPoints(xPlayer.identifier) }
    end

    local points = getPoints(xPlayer.identifier)
    if points < caseData.price then
        return { success = false, error = "Points insuffisants", newPoints = points }
    end

    local newPoints = setPoints(xPlayer.identifier, points - caseData.price, 0)
    local prize = drawPrize(caseData.prizes)

    awardPrize(xPlayer, prize)

    Staff29.Insert([[
        INSERT INTO afk_shop_purchases (identifier, case_id, prize, created_at) VALUES (?, ?, ?, ?)
    ]], { xPlayer.identifier, caseId, Staff29.Encode(prize), Staff29.Now() })

    return {
        success = true,
        error = "",
        newPoints = newPoints,
        prize = {
            name = prize.name,
            type = prize.type,
            rarity = prize.rarity,
            chance = prize.chance,
            amount = prize.amount,
            itemName = prize.itemName,
            itemCount = prize.count or prize.itemCount,
            vehicleModel = prize.vehicleModel,
        },
    }
end)

Staff29.Cb("core:afk:getFullLeaderboard", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    local maxEntries = (AFKConfig.RankingNPC and AFKConfig.RankingNPC.maxEntries) or 50
    local entries = topLeaderboard(maxEntries)

    local viewer = { rank = nil, points = 0 }
    if xPlayer then
        viewer.points = getPoints(xPlayer.identifier)
        for i = 1, #entries do
            if entries[i].identifier == xPlayer.identifier then
                entries[i].isViewer = true
                viewer.rank = entries[i].rank
            else
                entries[i].isViewer = false
            end
        end
        if not viewer.rank then
            local better = Staff29.Scalar(
                "SELECT COUNT(*) FROM afk_points WHERE points > ?", { viewer.points }, 0) or 0
            viewer.rank = (tonumber(better) or 0) + 1
        end
    end

    return { entries = entries, viewer = viewer }
end)

CreateThread(function()
    local interval = (AFKConfig and AFKConfig.Points and AFKConfig.Points.intervalMs) or 60000
    local perMinute = (AFKConfig and AFKConfig.Points and AFKConfig.Points.pointsPerMinute) or 1

    while true do
        Wait(interval)

        local pending, count = {}, 0
        for src in pairs(sessions) do
            count = count + 1
            pending[count] = src
        end

        for i = 1, count do
            local src = pending[i]
            local session = sessions[src]
            if session then
                local xPlayer = VFW.GetPlayerFromId(src)
                if not xPlayer then
                    releaseBucket(session.bucket)
                    sessions[src] = nil
                else
                    local total = setPoints(xPlayer.identifier, getPoints(xPlayer.identifier) + perMinute, 1)
                    xPlayer.triggerEvent("core:afk:updatePoints", total, perMinute)
                end
            end
        end
    end
end)

VFW.RegisterCommand("afkstatus", "", function(source, xPlayer)
    local count = 0
    for _ in pairs(sessions) do count = count + 1 end

    if source == 0 then
        console.info(("[AFK] %d joueur(s) en zone AFK"):format(count))
        return
    end

    Staff29.Notify(source, "INFO", "Zone AFK", (count > 1 and "%d joueurs actuellement en zone AFK." or "%d joueur actuellement en zone AFK."):format(count))
end, {
    help = "Voir le nombre de joueurs en zone AFK.",
    allowConsole = true,
})

VFW.RegisterCommand("afkremove", "gestion", function(source, xPlayer, args)
    local targetId = tonumber(args and args[1])
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil

    if not target then
        Staff29.Notify(source, "ERROR", "Zone AFK", "Joueur introuvable.")
        return
    end

    if not sessions[target.source] then
        Staff29.Notify(source, "WARNING", "Zone AFK", "Ce joueur n'est pas en zone AFK.")
        return
    end

    target.triggerEvent("core:afk:triggerExit")
    VFW.SetTimeout(3000, function()
        if sessions[target.source] then exitAFK(target.source, true) end
    end)

    Staff29.Notify(source, "SUCCESS", "Zone AFK", ("%s a été retiré de la zone AFK."):format(target.name))
end, {
    help = "Retirer un joueur de la zone AFK.",
    params = { { name = "id", help = "ID serveur du joueur" } },
})

VFW.RegisterCommand("afkforce", "gestion", function(source, xPlayer, args)
    local targetId = tonumber(args and args[1])
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil

    if not target then
        Staff29.Notify(source, "ERROR", "Zone AFK", "Joueur introuvable.")
        return
    end

    target.triggerEvent("core:afk:triggerEnter")
    Staff29.Notify(source, "SUCCESS", "Zone AFK", ("%s a été envoyé en zone AFK."):format(target.name))
end, {
    help = "Forcer un joueur à rejoindre la zone AFK.",
    params = { { name = "id", help = "ID serveur du joueur" } },
})

VFW.RegisterCommand("giveafkpoints", "gestion", function(source, xPlayer, args)
    local targetId = tonumber(args and args[1])
    local amount = Staff29.ToInt(args and args[2], -1000000, 1000000)
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil

    if not target or not amount then
        Staff29.Notify(source, "ERROR", "Zone AFK", "Usage : /giveafkpoints [id] [montant]")
        return
    end

    local total = setPoints(target.identifier, getPoints(target.identifier) + amount, 0)
    target.triggerEvent("core:afk:updatePoints", total, amount)

    Staff29.Notify(source, "SUCCESS", "Zone AFK",
        ("%d points AFK donnés à %s (total %d)."):format(amount, target.name, total))
end, {
    help = "Donner des points AFK à un joueur.",
    params = {
        { name = "id", help = "ID serveur du joueur" },
        { name = "montant", help = "Nombre de points" },
    },
})

AddEventHandler("vfw:playerDropped", function(source)
    local session = sessions[source]
    if not session then return end

    Staff29.Update([[
        UPDATE afk_sessions SET exited_at = ? WHERE identifier = ? AND exited_at IS NULL
    ]], { Staff29.Now(), session.identifier })

    releaseBucket(session.bucket)
    sessions[source] = nil
end)

local function requireBoutique(source)
    return Staff29.Require(source, "boutique")
end

local function withPrizeIds(caseId, prizes)
    local out = {}
    for i = 1, #(prizes or {}) do
        local p = prizes[i]
        if type(p) == "table" then
            out[i] = {
                id = p.id or (tostring(caseId) .. "_" .. i),
                type = p.type or "money",
                name = p.name or "Lot",
                amount = tonumber(p.amount) or 0,
                itemName = p.itemName or "",
                vehicleModel = p.vehicleModel or "",
                count = math.floor(tonumber(p.count) or 1),
                rarity = math.floor(tonumber(p.rarity) or 1),
                chance = tonumber(p.chance) or 10,
            }
        end
    end
    return out
end

local function listAdminCases()
    local dict = shopCases()
    local out = {}
    for id, data in pairs(dict) do
        out[#out + 1] = {
            id = id,
            name = data.name,
            description = data.description or "",
            price = data.price or 0,
            itemName = data.itemName or "",
            image = data.image or "",
            enabled = true,
            sortOrder = 0,
            prizes = withPrizeIds(id, data.prizes),
        }
    end
    table.sort(out, function(a, b) return tostring(a.name or a.id) < tostring(b.name or b.id) end)
    return out
end

local function writeCase(caseId, name, description, price, itemName, image, prizes)
    Staff29.Update([[
        INSERT INTO afk_shop_cases (case_id, item_name, name, description, price, image, prizes)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            item_name = VALUES(item_name),
            name = VALUES(name),
            description = VALUES(description),
            price = VALUES(price),
            image = VALUES(image),
            prizes = VALUES(prizes)
    ]], {
        caseId, itemName or "", name or caseId, description or "",
        math.floor(tonumber(price) or 0), image or "", Staff29.Encode(prizes or {}),
    })
end

local function findCasePrizes(caseId)
    local dict = shopCases()
    local data = dict[caseId]
    if not data then return nil end
    return withPrizeIds(caseId, data.prizes), data
end

Staff29.Cb("core:afkshop:getCases", function(source)
    if not requireBoutique(source) then return { success = false, cases = {} } end
    return { success = true, cases = listAdminCases() }
end)

Staff29.Cb("core:afkshop:createCase", function(source, data)
    if not requireBoutique(source) then return { success = false, error = "Non autorisé" } end
    if type(data) ~= "table" then return { success = false, error = "Données invalides" } end
    local caseId = Staff29.Clean(data.id, 60)
    local name = Staff29.Clean(data.name, 150)
    if not caseId or not name then return { success = false, error = "Identifiant et nom requis" } end
    local existing = shopCases()
    if existing[caseId] then return { success = false, error = "Cette caisse existe déjà" } end
    writeCase(caseId, name, data.description, data.price, data.itemName, data.image, {})
    return { success = true }
end)

Staff29.Cb("core:afkshop:editCase", function(source, data)
    if not requireBoutique(source) then return { success = false, error = "Non autorisé" } end
    if type(data) ~= "table" then return { success = false, error = "Données invalides" } end
    local caseId = type(data.id) == "string" and data.id or nil
    if not caseId then return { success = false, error = "Caisse introuvable" } end
    local prizes, current = findCasePrizes(caseId)
    if not current then return { success = false, error = "Caisse introuvable" } end
    writeCase(
        caseId,
        data.name or current.name,
        data.description ~= nil and data.description or current.description,
        data.price ~= nil and data.price or current.price,
        data.itemName ~= nil and data.itemName or current.itemName,
        data.image ~= nil and data.image or current.image,
        prizes
    )
    return { success = true }
end)

Staff29.Cb("core:afkshop:deleteCase", function(source, caseId)
    if not requireBoutique(source) then return { success = false, error = "Non autorisé" } end
    if type(caseId) ~= "string" then return { success = false, error = "Caisse introuvable" } end
    Staff29.Update("DELETE FROM afk_shop_cases WHERE case_id = ?", { caseId })
    return { success = true }
end)

Staff29.Cb("core:afkshop:addPrize", function(source, caseId, prize)
    if not requireBoutique(source) then return { success = false, error = "Non autorisé" } end
    if type(caseId) ~= "string" or type(prize) ~= "table" then return { success = false, error = "Données invalides" } end
    local prizes, current = findCasePrizes(caseId)
    if not current then return { success = false, error = "Caisse introuvable" } end
    prizes[#prizes + 1] = {
        id = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
        type = prize.type or "money",
        name = prize.name or "Lot",
        amount = tonumber(prize.amount) or 0,
        itemName = prize.itemName or "",
        vehicleModel = prize.vehicleModel or "",
        count = math.floor(tonumber(prize.count) or 1),
        rarity = math.floor(tonumber(prize.rarity) or 1),
        chance = tonumber(prize.chance) or 10,
    }
    writeCase(caseId, current.name, current.description, current.price, current.itemName, current.image, prizes)
    return { success = true }
end)

Staff29.Cb("core:afkshop:editPrize", function(source, prizeId, prize)
    if not requireBoutique(source) then return { success = false, error = "Non autorisé" } end
    if prizeId == nil or type(prize) ~= "table" then return { success = false, error = "Lot introuvable" } end
    prizeId = tostring(prizeId)
    for _, caseData in ipairs(listAdminCases()) do
        for i, p in ipairs(caseData.prizes or {}) do
            if tostring(p.id) == prizeId then
                caseData.prizes[i] = {
                    id = p.id,
                    type = prize.type or p.type,
                    name = prize.name or p.name,
                    amount = tonumber(prize.amount) or p.amount,
                    itemName = prize.itemName or p.itemName,
                    vehicleModel = prize.vehicleModel or p.vehicleModel,
                    count = math.floor(tonumber(prize.count) or p.count or 1),
                    rarity = math.floor(tonumber(prize.rarity) or p.rarity or 1),
                    chance = tonumber(prize.chance) or p.chance,
                }
                writeCase(caseData.id, caseData.name, caseData.description, caseData.price, caseData.itemName, caseData.image, caseData.prizes)
                return { success = true }
            end
        end
    end
    return { success = false, error = "Lot introuvable" }
end)

Staff29.Cb("core:afkshop:deletePrize", function(source, prizeId)
    if not requireBoutique(source) then return { success = false, error = "Non autorisé" } end
    prizeId = tostring(prizeId or "")
    for _, caseData in ipairs(listAdminCases()) do
        local nextPrizes = {}
        local found = false
        for _, p in ipairs(caseData.prizes or {}) do
            if tostring(p.id) == prizeId then
                found = true
            else
                nextPrizes[#nextPrizes + 1] = p
            end
        end
        if found then
            writeCase(caseData.id, caseData.name, caseData.description, caseData.price, caseData.itemName, caseData.image, nextPrizes)
            return { success = true }
        end
    end
    return { success = false, error = "Lot introuvable" }
end)

Staff29.Cb("core:afkshop:getPlayersPoints", function(source, search, limit)
    if not requireBoutique(source) then return { success = false, players = {} } end
    limit = math.min(math.max(math.floor(tonumber(limit) or 100), 1), 200)
    search = type(search) == "string" and search:gsub("%%", "") or ""
    local rows
    if search ~= "" then
        local like = "%" .. search .. "%"
        rows = Staff29.Query([[
            SELECT p.identifier, p.points, p.total_minutes, c.firstname, c.lastname
            FROM afk_points p
            LEFT JOIN characters c ON c.identifier = p.identifier
            WHERE p.identifier LIKE ? OR c.firstname LIKE ? OR c.lastname LIKE ?
            ORDER BY p.points DESC LIMIT ?
        ]], { like, like, like, limit })
    else
        rows = Staff29.Query([[
            SELECT p.identifier, p.points, p.total_minutes, c.firstname, c.lastname
            FROM afk_points p
            LEFT JOIN characters c ON c.identifier = p.identifier
            ORDER BY p.points DESC LIMIT ?
        ]], { limit })
    end
    local players = {}
    for i = 1, #(rows or {}) do
        local row = rows[i]
        players[i] = {
            identifier = row.identifier,
            name = (("%s %s"):format(row.firstname or "Joueur", row.lastname or "Inconnu")):gsub("%s+", " "),
            points = math.floor(tonumber(row.points) or 0),
            total_time = math.floor((tonumber(row.total_minutes) or 0) * 60),
        }
    end
    return { success = true, players = players }
end)

Staff29.Cb("core:afkshop:adjustPoints", function(source, identifier, delta)
    if not requireBoutique(source) then return { success = false, error = "Non autorisé" } end
    if type(identifier) ~= "string" then return { success = false, error = "Joueur introuvable" } end
    delta = math.floor(tonumber(delta) or 0)
    if delta == 0 then return { success = false, error = "Cette quantité n'est pas valide" } end
    local total = setPoints(identifier, getPoints(identifier) + delta, 0)
    local online = VFW.GetPlayerFromIdentifier(identifier)
    if online then online.triggerEvent("core:afk:updatePoints", total, delta) end
    return { success = true, newPoints = total }
end)

Staff29.Cb("core:afkshop:getPurchaseLogs", function(source, limit)
    if not requireBoutique(source) then return { success = false, logs = {} } end
    limit = math.min(math.max(math.floor(tonumber(limit) or 100), 1), 200)
    local rows = Staff29.Query([[
        SELECT p.id, p.identifier, p.case_id, p.prize, p.created_at, c.firstname, c.lastname
        FROM afk_shop_purchases p
        LEFT JOIN characters c ON c.identifier = p.identifier
        ORDER BY p.id DESC LIMIT ?
    ]], { limit }) or {}
    local cases = shopCases()
    local logs = {}
    for i = 1, #rows do
        local row = rows[i]
        local prize = Staff29.Decode(row.prize, {}) or {}
        local caseData = cases[row.case_id]
        logs[i] = {
            id = row.id,
            identifier = row.identifier,
            player_name = (("%s %s"):format(row.firstname or "Joueur", row.lastname or "Inconnu")):gsub("%s+", " "),
            case_id = row.case_id,
            case_name = caseData and caseData.name or row.case_id,
            price = caseData and caseData.price or 0,
            prize_name = prize.name or "?",
            created_at = tostring(row.created_at or ""),
        }
    end
    return { success = true, logs = logs }
end)
