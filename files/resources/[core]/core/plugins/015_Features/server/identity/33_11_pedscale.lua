local Cl = VFW.Cloths

VFW.PedScale = VFW.PedScale or {}

local Ps = VFW.PedScale

local MIN_SCALE = 0.1
local MAX_SCALE = 2.0

local active = {}
local tableReady = false

local function ensureTable()
    if tableReady then return true end
    local ok = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS ped_scales (
                char_id INT(11) NOT NULL,
                scale   FLOAT NOT NULL DEFAULT 1,
                PRIMARY KEY (char_id)
            )
        ]])
    end)
    if ok then tableReady = true end
    return ok
end

local function snapshot()
    local out = {}
    for source, scale in pairs(active) do
        out[tostring(source)] = scale
    end
    return out
end

function Ps.Get(source)
    return active[tonumber(source)]
end

function Ps.Set(source, scale)
    source = tonumber(source)
    if not source then return false end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.charId then return false end
    ensureTable()

    local value = tonumber(scale)
    if value then
        if value < MIN_SCALE then value = MIN_SCALE end
        if value > MAX_SCALE then value = MAX_SCALE end
        if math.abs(value - 1.0) < 0.001 then value = nil end
    end

    if value then
        active[source] = value
        pcall(MySQL.query.await, [[
            INSERT INTO ped_scales (char_id, scale) VALUES (?, ?)
            ON DUPLICATE KEY UPDATE scale = VALUES(scale)
        ]], { xPlayer.charId, value })
        TriggerClientEvent("pedscale:sync", -1, source, value)
    else
        active[source] = nil
        pcall(MySQL.query.await, "DELETE FROM ped_scales WHERE char_id = ?", { xPlayer.charId })
        TriggerClientEvent("pedscale:sync", -1, source)
    end

    return true
end

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    ensureTable()

    local okRow, row = pcall(MySQL.single.await, "SELECT scale FROM ped_scales WHERE char_id = ?", { xPlayer.charId })
    if not okRow then row = nil end
    local scale = row and tonumber(row.scale) or nil

    if scale and math.abs(scale - 1.0) >= 0.001 then
        if scale < MIN_SCALE then scale = MIN_SCALE end
        if scale > MAX_SCALE then scale = MAX_SCALE end
        active[source] = scale
        TriggerClientEvent("pedscale:sync", -1, source, scale)
    end

    if next(active) ~= nil then
        TriggerClientEvent("pedscale:syncAll", source, snapshot())
    end
end)

AddEventHandler("vfw:sync:playerJoined", function(source)
    if next(active) ~= nil then
        TriggerClientEvent("pedscale:syncAll", source, snapshot())
    end
end)

AddEventHandler("playerDropped", function()
    local source = source
    if active[source] then
        active[source] = nil
        TriggerClientEvent("pedscale:sync", -1, source)
    end
end)

VFW.RegisterCommand("setscale", "setped", function(source, xPlayer, args)
    local first = tonumber(args and args[1])
    local second = tonumber(args and args[2])

    local targetId, scale
    if second then
        targetId = math.floor(first or source)
        scale = second
    else
        targetId = source
        scale = first
    end

    if not scale then
        Cl.Notify(source, "Usage : /setscale [id] <echelle 0.1-2.0>")
        return
    end

    if not VFW.GetPlayerFromId(targetId) then
        Cl.Notify(source, "Joueur introuvable.")
        return
    end

    Ps.Set(targetId, scale)
    Cl.Notify(source, ("Echelle appliquee : %.2f"):format(scale), "VERT")
end, {
    help = "Modifier la taille du ped d'un joueur",
    params = {
        { name = "id", help = "ID du joueur (soi-meme par defaut)" },
        { name = "echelle", help = "Entre 0.1 et 2.0" },
    },
})

VFW.RegisterCommand("resetscale", "setped", function(source, xPlayer, args)
    local targetId = math.floor(tonumber(args and args[1]) or source)

    if not VFW.GetPlayerFromId(targetId) then
        Cl.Notify(source, "Joueur introuvable.")
        return
    end

    Ps.Set(targetId, nil)
    Cl.Notify(source, "Echelle reinitialisee.", "VERT")
end, {
    help = "Reinitialiser la taille du ped d'un joueur",
    params = { { name = "id", help = "ID du joueur (soi-meme par defaut)" } },
})
