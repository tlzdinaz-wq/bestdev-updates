local Cl = VFW.Cloths

local bans = nil

local function normalizeKey(value)
    if type(value) ~= "string" then return nil end
    if value == "" or #value > 48 then return nil end
    if not value:match("^[A-Za-z:_]+$") then return nil end
    return value
end

function Cl.LoadBlacklist()
    local out = {}
    local rows = MySQL.query.await("SELECT gender, db_key, drawable_id FROM clothes_blacklist") or {}

    for i = 1, #rows do
        local row = rows[i]
        local gender = Cl.NormalizeGender(row.gender)
        local key = row.db_key
        if type(key) == "string" and key ~= "" then
            if not out[gender] then out[gender] = {} end
            if not out[gender][key] then out[gender][key] = {} end
            out[gender][key][#out[gender][key] + 1] = tonumber(row.drawable_id) or 0
        end
    end

    bans = out
    return bans
end

function Cl.Blacklist()
    if not bans then
        Cl.LoadBlacklist()
    end
    return bans
end

function Cl.IsBanned(gender, dbKey, drawableId)
    gender = Cl.NormalizeGender(gender)
    drawableId = Cl.Int(drawableId, -1)

    local dynamic = Cl.Blacklist()
    if dynamic[gender] and dynamic[gender][dbKey] then
        local list = dynamic[gender][dbKey]
        for i = 1, #list do
            if list[i] == drawableId then return true end
        end
    end

    local static = Config.ClothesBan and Config.ClothesBan[gender] and Config.ClothesBan[gender][dbKey]
    if static then
        for i = 1, #static do
            if static[i] == drawableId then return true end
        end
    end

    local barber = Config.BarberBan and Config.BarberBan[gender] and Config.BarberBan[gender][dbKey]
    if barber then
        for i = 1, #barber do
            if barber[i] == drawableId then return true end
        end
    end

    return false
end

function Cl.IsVangelicoBanned(gender, dbKey, drawableId)
    gender = Cl.NormalizeGender(gender)
    drawableId = Cl.Int(drawableId, -1)

    local dynamic = Cl.Blacklist()
    local prefixed = "v:" .. dbKey
    if dynamic[gender] and dynamic[gender][prefixed] then
        local list = dynamic[gender][prefixed]
        for i = 1, #list do
            if list[i] == drawableId then return true end
        end
    end

    local static = Config.VangelicoBan and Config.VangelicoBan[gender] and Config.VangelicoBan[gender][dbKey]
    if static then
        for i = 1, #static do
            if static[i] == drawableId then return true end
        end
    end

    return false
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 400 do
        Wait(250)
        tries = tries + 1
    end
    Cl.LoadBlacklist()
end)

RegisterServerCallback("clothesBlacklist:getAll", function(source)
    return Cl.Blacklist()
end)

RegisterServerCallback("clothesBlacklist:getStats", function(source, gender)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local normalized = Cl.NormalizeGender(gender)
    local dynamic = Cl.Blacklist()[normalized] or {}

    local stats = {}
    for key, list in pairs(dynamic) do
        stats[key] = #list
    end
    return stats
end)

RegisterServerCallback("clothesBlacklist:toggleBan", function(source, gender, dbKey, drawableId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { success = false, message = "Joueur introuvable" }
    end

    if not (xPlayer.hasPermission("manage_clothes") or xPlayer.hasPermission("staff_menu")) then
        return { success = false, message = "Permission refusee" }
    end

    local key = normalizeKey(dbKey)
    if not key then
        return { success = false, message = "Cette categorie n'est pas valide" }
    end

    local normalized = Cl.NormalizeGender(gender)
    local drawable = Cl.Int(drawableId, nil)
    if not drawable or drawable < -1 or drawable > 5000 then
        return { success = false, message = "Cet identifiant n'est pas valide" }
    end

    local existing = MySQL.single.await(
        "SELECT id FROM clothes_blacklist WHERE gender = ? AND db_key = ? AND drawable_id = ?",
        { normalized, key, drawable }
    )

    local action
    if existing then
        MySQL.query.await("DELETE FROM clothes_blacklist WHERE id = ?", { existing.id })
        action = "unbanned"
    else
        MySQL.insert.await(
            "INSERT IGNORE INTO clothes_blacklist (gender, db_key, drawable_id) VALUES (?, ?, ?)",
            { normalized, key, drawable }
        )
        action = "banned"
    end

    Cl.LoadBlacklist()
    TriggerClientEvent("clothesBlacklist:reload", -1)

    return { success = true, action = action }
end)
