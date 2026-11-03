-- Prison : les positions, et la mise en cellule.
--
-- La base avait toutes les pièces d'une prison sauf celle qui compte : la tenue
-- de prisonnier, le compte à rebours, la détection d'évasion, le PNJ qui rend
-- les affaires, la liste des détenus côté staff et les boutons « libérer » et
-- « réduire la peine » du panneau police existaient déjà — mais **rien
-- n'envoyait jamais personne en prison**. La table des détenus n'était que lue
-- et vidée, l'évènement qui habille le prisonnier n'était déclenché nulle part,
-- et le MDT du téléphone cherche une douzaine de scripts de prison externes,
-- dont aucun n'est livré avec la base.
--
-- Les seules coordonnées étaient écrites en dur dans le code du métier police :
-- le centre de la zone d'évasion et le PNJ de sortie. Un serveur avec sa propre
-- prison n'avait aucun moyen de les déplacer — d'où « on ne peut pas changer la
-- position des jail ».
--
-- Ici : les quatre positions, réglables depuis Gestion > Builders > POSITIONS
-- PRISON, et le circuit complet d'incarcération (commande, décompte des peines,
-- libération, reprise après reconnexion ou redémarrage).

local STORE <const> = "prison_positions"
local MAX_MINUTES <const> = 20000
local MAX_COORD <const> = 20000.0

-- Les valeurs d'origine du code : un serveur qui n'y touche pas garde
-- exactement le comportement d'avant.
local DEFAULTS <const> = {
    cell    = { x = 1679.04, y = 2513.07, z = 45.56, h = 0.0 },
    release = { x = 1845.96, y = 2585.85, z = 44.67, h = 90.0 },
    guard   = { x = 1845.96, y = 2585.85, z = 44.67, h = 270.0 },
    zone    = { x = 1747.58, y = 2537.37, z = 44.57, radius = 500.0 },
}

local positions = nil

local function num(value, fallback)
    local n = tonumber(value)
    if not n or n ~= n or math.abs(n) > MAX_COORD then return fallback end
    return n + 0.0
end

--- Une position relue depuis le réglage, complétée par la valeur d'origine.
---@param raw any
---@param fallback table
---@param withRadius? boolean
---@return table
local function readPoint(raw, fallback, withRadius)
    local src = type(raw) == "table" and raw or {}
    local out = {
        x = num(src.x, fallback.x),
        y = num(src.y, fallback.y),
        z = num(src.z, fallback.z),
    }
    if withRadius then
        local radius = tonumber(src.radius) or fallback.radius
        if not radius or radius ~= radius then radius = fallback.radius end
        if radius < 20.0 then radius = 20.0 end
        if radius > 2000.0 then radius = 2000.0 end
        out.radius = radius + 0.0
    else
        out.h = num(src.h, fallback.h) % 360.0
    end
    return out
end

local function load()
    if positions then return positions end

    local stored
    if VFW.Variables and VFW.Variables.GetVariable then
        local ok, value = pcall(VFW.Variables.GetVariable, STORE)
        if ok and type(value) == "table" then stored = value end
    end
    stored = stored or {}

    positions = {
        cell    = readPoint(stored.cell, DEFAULTS.cell),
        release = readPoint(stored.release, DEFAULTS.release),
        guard   = readPoint(stored.guard, DEFAULTS.guard),
        zone    = readPoint(stored.zone, DEFAULTS.zone, true),
    }
    return positions
end

local function broadcast(target)
    TriggerClientEvent("prison:positions", target or -1, load())
end

local function isStaff(xPlayer)
    if not xPlayer then return false end
    return xPlayer.hasPermission("manage_police_zones")
        or xPlayer.hasPermission("staff_menu")
        or xPlayer.hasPermission("dev")
end

-- ── Réglage des positions ───────────────────────────────────────

MiscB.Cb("prison:getPositions", function()
    return load()
end)

MiscB.Cb("prison:savePositions", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not isStaff(xPlayer) then
        return { ok = false, error = "Permission refusee." }
    end
    if type(data) ~= "table" then
        return { ok = false, error = "Positions invalides." }
    end

    local current = load()
    local next_ = {
        cell    = readPoint(data.cell or current.cell, DEFAULTS.cell),
        release = readPoint(data.release or current.release, DEFAULTS.release),
        guard   = readPoint(data.guard or current.guard, DEFAULTS.guard),
        zone    = readPoint(data.zone or current.zone, DEFAULTS.zone, true),
    }

    if not (VFW.Variables and VFW.Variables.SetVariable) then
        return { ok = false, error = "Les reglages du serveur sont indisponibles." }
    end

    local ok = pcall(VFW.Variables.SetVariable, STORE, next_)
    if not ok then
        return { ok = false, error = "Enregistrement impossible." }
    end

    positions = next_
    broadcast()
    return { ok = true, positions = next_ }
end)

MiscB.Cb("prison:resetPositions", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not isStaff(xPlayer) then
        return { ok = false, error = "Permission refusee." }
    end

    -- On réécrit les valeurs d'origine plutôt que d'effacer le réglage : un
    -- enregistrement vide se relirait en « null » et laisserait une ligne sans
    -- contenu en base.
    local origin = {
        cell    = readPoint(nil, DEFAULTS.cell),
        release = readPoint(nil, DEFAULTS.release),
        guard   = readPoint(nil, DEFAULTS.guard),
        zone    = readPoint(nil, DEFAULTS.zone, true),
    }

    if not (VFW.Variables and VFW.Variables.SetVariable) then
        return { ok = false, error = "Les reglages du serveur sont indisponibles." }
    end

    local ok = pcall(VFW.Variables.SetVariable, STORE, origin)
    if not ok then
        return { ok = false, error = "Enregistrement impossible." }
    end

    positions = origin
    broadcast()
    return { ok = true, positions = origin }
end)

-- ── Incarcération ───────────────────────────────────────────────

local Prison = {}
VFW.Prison = Prison

--- Combien de minutes il reste à purger.
---@param xPlayer table
---@return integer
local function remaining(xPlayer)
    local value = xPlayer.getMeta and xPlayer.getMeta("jail") or 0
    local minutes = tonumber(value) or 0
    if minutes < 0 then minutes = 0 end
    return math.floor(minutes)
end

--- Envoie un joueur en cellule.
---
--- `fresh` distingue la première incarcération d'une reprise (reconnexion,
--- redémarrage) : la tenue civile n'est sauvegardée qu'une fois, sinon on
--- enregistrerait la tenue de prisonnier par-dessus et le joueur ressortirait
--- en orange.
---@param xTarget table
---@param minutes integer
---@param fresh boolean
local function sendToCell(xTarget, minutes, fresh)
    local point = load().cell
    xTarget.setMeta("jail", minutes)

    TriggerClientEvent("prison:positions", xTarget.source, load())
    TriggerClientEvent("prison:teleport", xTarget.source, point)
    TriggerClientEvent("police:prison:resetEscape", xTarget.source)
    TriggerClientEvent("police:prison:apply", xTarget.source, minutes, fresh)
end

--- Met un joueur en prison.
---@param xTarget table
---@param minutes integer
---@param reason? string
---@return boolean
function Prison.Jail(xTarget, minutes, reason)
    if not xTarget then return false end

    local duration = math.floor(tonumber(minutes) or 0)
    if duration < 1 then return false end
    if duration > MAX_MINUTES then duration = MAX_MINUTES end

    VFW.Prison.Register(xTarget, duration, reason)
    sendToCell(xTarget, duration, true)
    return true
end

--- Sort un joueur de prison.
---@param xTarget table
---@param escaped? boolean
function Prison.Release(xTarget, escaped)
    if not xTarget then return end

    VFW.Prison.Unregister(xTarget)
    xTarget.setMeta("jail", 0)

    if not escaped then
        TriggerClientEvent("prison:teleport", xTarget.source, load().release)
    end
    TriggerClientEvent("police:prison:release", xTarget.source, nil, escaped == true)
end

-- Le registre des détenus vit dans 34_13_police.lua (liste staff, panneau
-- police). On s'y branche par évènement plutôt que de tenir une seconde liste
-- qui finirait par dire le contraire de la première.
function Prison.Register(xTarget, minutes, reason)
    TriggerEvent("vfw:prison:register", xTarget.identifier, {
        name = MiscB.CharName(xTarget),
        minutes = minutes,
        reason = reason or "",
        startedAt = os.time(),
    })
end

function Prison.Unregister(xTarget)
    TriggerEvent("vfw:prison:unregister", xTarget.identifier)
end

-- ── Décompte des peines ─────────────────────────────────────────
--
-- Une minute de peine = une minute réelle passée en jeu. Déconnecté, le temps
-- ne défile pas : sinon il suffirait de quitter le serveur pour purger.

CreateThread(function()
    while true do
        Wait(60000)

        local players = VFW.GetPlayers and VFW.GetPlayers() or {}
        for i = 1, #players do
            local xPlayer = VFW.GetPlayerFromId(players[i])
            if xPlayer then
                local left = remaining(xPlayer)
                if left > 0 then
                    left = left - 1
                    if left <= 0 then
                        Prison.Release(xPlayer, false)
                        MiscB.Notify(xPlayer.source, "Vous avez purge votre peine.", "VERT")
                    else
                        xPlayer.setMeta("jail", left)
                        TriggerClientEvent("police:prison:updateTimer", xPlayer.source, left)
                    end
                end
            end
        end
    end
end)

-- ── Reprise après reconnexion ───────────────────────────────────
--
-- Le client demande `jail:load` à chaque arrivée en jeu. L'évènement n'avait
-- aucun destinataire : un joueur déconnecté en prison revenait libre, en civil,
-- où il voulait.

MiscB.Event("jail:load", function()
    -- MiscB.Event pose un RegisterNetEvent nu : la source arrive par la variable
    -- globale, pas en parametre. La nommer en parametre la rendrait nil.
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local left = remaining(xPlayer)
    if left <= 0 then
        TriggerClientEvent("prison:positions", source, load())
        return
    end

    VFW.Prison.Register(xPlayer, left, "Peine en cours")
    sendToCell(xPlayer, left, false)
end)

AddEventHandler("vfw:playerLoaded", function(playerSource)
    TriggerClientEvent("prison:positions", playerSource, load())
end)

-- ── Commandes ───────────────────────────────────────────────────

local function lawEnforcement(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if MiscB.IsLawEnforcement(xPlayer) then return xPlayer end
    if MiscB.HasJob(xPlayer, { "justice", "doj", "gouvernement" }) then return xPlayer end
    if isStaff(xPlayer) then return xPlayer end
    return nil
end

VFW.RegisterCommand("prison", "", function(source, _, args)
    local xPlayer = lawEnforcement(source)
    if not xPlayer then
        MiscB.Notify(source, "Vous n'avez pas le droit d'incarcerer.", "ROUGE")
        return
    end

    local targetId = MiscB.ToInt(args and args[1], 1, 65535)
    local minutes = MiscB.ToInt(args and args[2], 1, MAX_MINUTES)
    if not targetId or not minutes then
        MiscB.Notify(source, "Utilisation : /prison [ID] [minutes] [motif]", "ROUGE")
        return
    end

    local xTarget = VFW.GetPlayerFromId(targetId)
    if not xTarget then
        MiscB.Notify(source, "Ce joueur n'est pas connecte.", "ROUGE")
        return
    end

    local reason = ""
    if args then
        for i = 3, #args do reason = reason .. (i > 3 and " " or "") .. tostring(args[i]) end
    end

    if not Prison.Jail(xTarget, minutes, reason) then
        MiscB.Notify(source, "Incarceration impossible.", "ROUGE")
        return
    end

    MiscB.Notify(source, ("%s est incarcere pour %d minute(s)."):format(MiscB.CharName(xTarget), minutes), "VERT")
    MiscB.Notify(xTarget.source, ("Vous etes incarcere pour %d minute(s). %s"):format(minutes, reason), "ROUGE")
    TriggerEvent("vfw:logs:staff", source, "prison_jail", {
        target = xTarget.identifier, minutes = minutes, reason = reason,
    })
end, {
    help = "Incarcerer un joueur (police, justice, staff).",
    params = {
        { name = "id", help = "ID du joueur" },
        { name = "minutes", help = "Duree de la peine" },
        { name = "motif", help = "Motif (optionnel)" },
    },
})

VFW.RegisterCommand("liberer", "", function(source, _, args)
    local xPlayer = lawEnforcement(source)
    if not xPlayer then
        MiscB.Notify(source, "Vous n'avez pas le droit de liberer.", "ROUGE")
        return
    end

    local targetId = MiscB.ToInt(args and args[1], 1, 65535)
    local xTarget = targetId and VFW.GetPlayerFromId(targetId) or nil
    if not xTarget then
        MiscB.Notify(source, "Utilisation : /liberer [ID]", "ROUGE")
        return
    end

    if remaining(xTarget) <= 0 then
        MiscB.Notify(source, "Ce joueur n'est pas en prison.", "ROUGE")
        return
    end

    Prison.Release(xTarget, false)
    MiscB.Notify(source, ("%s a ete libere."):format(MiscB.CharName(xTarget)), "VERT")
    MiscB.Notify(xTarget.source, "Vous avez ete libere.", "VERT")
end, {
    help = "Liberer un joueur de prison (police, justice, staff).",
    params = { { name = "id", help = "ID du joueur" } },
})
