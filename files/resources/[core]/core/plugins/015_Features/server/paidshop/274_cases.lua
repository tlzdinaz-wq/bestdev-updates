Feat27 = Feat27 or {}

local pendingDraws = {}

local function casePool(caseItem)
    local pool = nil
    if caseItem then
        pool = caseItem.possible_items or caseItem.possibleItems or caseItem.content
    end
    if type(pool) ~= "table" or #pool == 0 then return nil end
    return pool
end

local function normalizePrize(entry)
    if type(entry) == "string" then
        return { spawnName = entry, name = Feat27.Inv.Label(entry), rarity = "common", weight = 10, category = "consommables" }
    end
    if type(entry) ~= "table" then return nil end

    local spawnName = entry.spawnName or entry.spawn_name or entry.item or entry.name
    if type(spawnName) ~= "string" then return nil end

    return {
        spawnName = spawnName,
        name = entry.name or spawnName,
        image = entry.image,
        rarity = entry.rarity or "common",
        weight = tonumber(entry.weight) or 10,
        count = math.floor(tonumber(entry.count) or 1),
        category = entry.category or "consommables",
    }
end

local function drawPrize(pool)
    local list = {}
    for i = 1, #pool do
        local prize = normalizePrize(pool[i])
        if prize then list[#list + 1] = prize end
    end
    if #list == 0 then return nil end

    local total = 0
    for i = 1, #list do total = total + list[i].weight end

    local roll = math.random(1, total)
    local acc = 0
    for i = 1, #list do
        acc = acc + list[i].weight
        if roll <= acc then return list[i] end
    end
    return list[#list]
end

RegisterServerCallback("paidshop:getBoxWinningItem", function(source, caseId)
    if caseId == nil then return { error = true, message = "Cette caisse n'est pas valide" } end
    if not Feat27.RateLimit(source, "paidshop:box", 1200) then
        return { error = true, message = "Veuillez patienter" }
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { error = true, message = "Joueur introuvable" } end

    local spawnName = tostring(caseId)
    local caseItem = PaidShop.FindItem("caisses", spawnName)
    if not caseItem then return { error = true, message = "Caisse introuvable" } end

    local pool = casePool(caseItem)
    if not pool then return { error = true, message = "Cette caisse est vide" } end

    local owned = MySQL.single.await([[
        SELECT `id` FROM paidshop_pending_items
        WHERE `identifier` = ? AND `spawn_name` = ? AND `status` = 'pending'
        ORDER BY `id` ASC LIMIT 1
    ]], { xPlayer.identifier, spawnName })
    if not owned then return { error = true, message = "Vous ne possedez pas cette caisse" } end

    local consumed = MySQL.update.await(
        "UPDATE paidshop_pending_items SET `status` = 'claimed', `claimed_at` = NOW() WHERE `id` = ? AND `status` = 'pending'",
        { owned.id }
    )
    if (tonumber(consumed) or 0) <= 0 then return { error = true, message = "Vous ne possedez pas cette caisse" } end

    local prize = drawPrize(pool)
    if not prize then
        MySQL.update.await("UPDATE paidshop_pending_items SET `status` = 'pending', `claimed_at` = NULL WHERE `id` = ?", { owned.id })
        return { error = true, message = "Tirage impossible" }
    end

    pendingDraws[source] = { caseId = spawnName, prize = prize, at = GetGameTimer() }

    return {
        error = false,
        caseId = spawnName,
        item = prize,
        spawnName = prize.spawnName,
        name = prize.name,
        image = prize.image,
        rarity = prize.rarity,
    }
end)

RegisterServerCallback("paidshop:casePrizeWon", function(source, caseId, prizeItem)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local draw = pendingDraws[source]
    if not draw then return false, "Aucun tirage en attente" end
    if caseId ~= nil and tostring(caseId) ~= draw.caseId then return false, "Cette caisse n'est pas valide" end

    pendingDraws[source] = nil

    local prize = draw.prize
    local pendingId = PaidShop.AddPending(xPlayer.identifier, prize.category or "consommables", {
        spawnName = prize.spawnName,
        name = prize.name,
        image = prize.image,
    }, prize.count or 1, 0)

    if not pendingId then return false, "Attribution impossible" end

    PaidShop.PushPendingCount(xPlayer)
    PaidShop.Broadcast({
        player = xPlayer.name or xPlayer.playerName,
        item = prize.name,
        category = "caisses",
        rarity = prize.rarity,
    })

    return true, ("Vous avez gagné %s"):format(prize.name)
end)

RegisterServerCallback("paidshop:getDisplayedCases", function(source)
    local rows = MySQL.query.await("SELECT * FROM paidshop_cases WHERE `sold` = 0 ORDER BY `id` DESC LIMIT 30") or {}

    local cases, reveals = {}, {}
    for i = 1, #rows do
        local row = rows[i]
        local entry = {
            caseId = row.case_id,
            id = row.case_id,
            itemName = row.item_name,
            category = row.category,
            price = row.price,
            revealed = row.revealed == 1,
        }
        cases[#cases + 1] = entry
        if row.revealed == 1 then
            reveals[#reveals + 1] = entry
        end
    end

    return { cases = cases, reveals = reveals }
end)

RegisterServerCallback("paidshop:scanCase", function(source, caseId)
    if caseId == nil then return { success = false, error = "Cette caisse n'est pas valide" } end
    if not Feat27.RateLimit(source, "paidshop:scan", 1500) then
        return { success = false, error = "Veuillez patienter" }
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, error = "Joueur introuvable" } end

    local row = MySQL.single.await("SELECT * FROM paidshop_cases WHERE `case_id` = ? AND `sold` = 0", { tostring(caseId) })
    if not row then return { success = false, error = "Caisse introuvable" } end

    if row.revealed ~= 1 then
        MySQL.update.await("UPDATE paidshop_cases SET `revealed` = 1, `revealed_by` = ? WHERE `id` = ?", {
            xPlayer.identifier, row.id,
        })
    end

    return {
        success = true,
        caseId = row.case_id,
        itemName = row.item_name,
        category = row.category,
        price = row.price,
        revealed = true,
    }
end)

RegisterServerCallback("paidshop:buyRevealedCase", function(source, caseId)
    if caseId == nil then return { success = false, error = "Cette caisse n'est pas valide" } end
    if not Feat27.RateLimit(source, "paidshop:buyCase", 1200) then
        return { success = false, error = "Veuillez patienter" }
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, error = "Joueur introuvable" } end

    local row = MySQL.single.await("SELECT * FROM paidshop_cases WHERE `case_id` = ? AND `sold` = 0 AND `revealed` = 1", { tostring(caseId) })
    if not row then return { success = false, error = "Caisse indisponible" } end

    local price = math.floor(tonumber(row.price) or 0)

    local claimed = MySQL.update.await("UPDATE paidshop_cases SET `sold` = 1 WHERE `id` = ? AND `sold` = 0", { row.id })
    if (tonumber(claimed) or 0) <= 0 then
        return { success = false, error = "Caisse indisponible" }
    end

    local paid, newCoins = PaidShop.TakeCoins(xPlayer, price)
    if not paid then
        MySQL.update.await("UPDATE paidshop_cases SET `sold` = 0 WHERE `id` = ?", { row.id })
        return { success = false, error = "Solde de Coins insuffisant", newCoins = newCoins }
    end

    PaidShop.AddPending(xPlayer.identifier, row.category or "caisses", {
        spawnName = row.item_name,
        name = row.item_name,
        image = "",
    }, 1, price)

    PaidShop.LogPurchase(xPlayer.identifier, row.category or "caisses", row.item_name, 1, price, nil)
    PaidShop.PushPendingCount(xPlayer)

    return { success = true, newCoins = newCoins, caseId = row.case_id }
end)

AddEventHandler("vfw:playerDropped", function(source)
    pendingDraws[source] = nil
end)
