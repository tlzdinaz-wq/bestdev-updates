-- /goto, /bring, /return — et la position d'un joueur.
--
-- La permission `goto` est declaree dans la configuration depuis toujours, decrite
-- comme « Commandes /goto, /bring et /return ». Les trois commandes n'ont jamais ete
-- ecrites. Le menu staff les appelle par `ExecuteCommand("goto 4")`, qui ne trouve
-- rien et ne fait rien : les boutons GOTO, BRING et RETURN etaient muets, et taper
-- la commande dans le chat ne donnait rien non plus.
--
-- Meme histoire pour `core:CoordsOfPlayer`, appele par le bouton GPS POSITION et
-- enregistre nulle part : le callback attendait son delai d'expiration puis rendait
-- nil, et aucun waypoint n'etait pose.
--
-- Le retour s'appuie sur `vfw:teleportTo`, deja ecoute cote client.

local PERMISSION <const> = "goto"

-- Position d'origine avant un /bring, pour pouvoir y renvoyer le joueur.
-- Indexee par identifiant de personnage et non par id serveur : un joueur qui se
-- reconnecte change d'id, et on renverrait quelqu'un d'autre a sa place.
local broughtFrom = {}

---@param xPlayer table
---@return string|nil
local function keyOf(xPlayer)
    local key = xPlayer and (xPlayer.identifier or xPlayer.charId)
    return key and tostring(key) or nil
end

---@param source number
---@return vector3|nil
local function coordsOf(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

--- Le joueur vise par la commande.
---@param source number
---@param raw any
---@return table|nil xTarget, number|nil targetId
local function target(source, raw)
    local id = Staff29.ToInt(raw, 1)
    if not id then
        Staff29.Notify(source, "ERROR", "Teleportation", "Indiquez l'identifiant du joueur.")
        return nil
    end

    local xTarget = VFW.GetPlayerFromId(id)
    if not xTarget then
        Staff29.Notify(source, "ERROR", "Teleportation", ("Aucun joueur connecte sous l'identifiant %d."):format(id))
        return nil
    end

    return xTarget, id
end

local function doGoto(source, args)
    if not Staff29.RateLimit(source, "staff:goto", 500) then return end

    local xTarget, id = target(source, args and args[1])
    if not xTarget then return end

    if id == source then
        Staff29.Notify(source, "ERROR", "Teleportation", "Vous etes deja a cet endroit.")
        return
    end

    local coords = coordsOf(id)
    if not coords then
        Staff29.Notify(source, "ERROR", "Teleportation", "Ce joueur n'est pas encore apparu en jeu.")
        return
    end

    -- Legerement a cote, pour ne pas apparaitre dans le joueur vise.
    TriggerClientEvent("vfw:teleportTo", source, coords.x + 1.5, coords.y, coords.z)
    Staff29.Notify(source, "SUCCESS", "Teleportation", ("Vous avez rejoint %s."):format(xTarget.name or id))
end

local function doBring(source, args)
    if not Staff29.RateLimit(source, "staff:bring", 500) then return end

    local xTarget, id = target(source, args and args[1])
    if not xTarget then return end

    if id == source then
        Staff29.Notify(source, "ERROR", "Teleportation", "Vous ne pouvez pas vous ramener a vous-meme.")
        return
    end

    local here = coordsOf(source)
    local there = coordsOf(id)
    if not here or not there then
        Staff29.Notify(source, "ERROR", "Teleportation", "Position introuvable.")
        return
    end

    local key = keyOf(xTarget)
    if key then
        broughtFrom[key] = { x = there.x, y = there.y, z = there.z }
    end

    TriggerClientEvent("vfw:teleportTo", id, here.x + 1.5, here.y, here.z)
    Staff29.Notify(source, "SUCCESS", "Teleportation", ("%s a ete ramene aupres de vous."):format(xTarget.name or id))
end

local function doReturn(source, args)
    if not Staff29.RateLimit(source, "staff:return", 500) then return end

    local xTarget, id = target(source, args and args[1])
    if not xTarget then return end

    local key = keyOf(xTarget)
    local origin = key and broughtFrom[key] or nil

    if not origin then
        Staff29.Notify(source, "ERROR", "Teleportation", "Ce joueur n'a pas ete ramene : aucune position d'origine connue.")
        return
    end

    broughtFrom[key] = nil
    TriggerClientEvent("vfw:teleportTo", id, origin.x, origin.y, origin.z)
    Staff29.Notify(source, "SUCCESS", "Teleportation", ("%s a ete renvoye a sa position."):format(xTarget.name or id))
end

-- Les commandes, pour le chat.
VFW.RegisterCommand("goto", PERMISSION, function(source, _, args) doGoto(source, args) end, {
    help = "Se teleporter sur un joueur",
    params = { { name = "id", help = "Identifiant serveur du joueur" } },
})

VFW.RegisterCommand("bring", PERMISSION, function(source, _, args) doBring(source, args) end, {
    help = "Ramener un joueur jusqu'a vous",
    params = { { name = "id", help = "Identifiant serveur du joueur" } },
})

VFW.RegisterCommand("return", PERMISSION, function(source, _, args) doReturn(source, args) end, {
    help = "Renvoyer un joueur la ou il etait avant le bring",
    params = { { name = "id", help = "Identifiant serveur du joueur" } },
})

-- Les evenements, pour le menu staff. `ExecuteCommand` cote client n'atteint pas une
-- commande serveur : les boutons passaient dans le vide meme quand la commande existe.
local function guarded(handler)
    return function(playerId)
        local source = source
        if not Staff29.Require(source, PERMISSION) then return end
        handler(source, { playerId })
    end
end

RegisterNetEvent("vfw:staff:goto", guarded(doGoto))
RegisterNetEvent("vfw:staff:bring", guarded(doBring))
RegisterNetEvent("vfw:staff:return", guarded(doReturn))

--- La position d'un joueur, pour le bouton GPS du menu staff.
Staff29.Cb("core:CoordsOfPlayer", function(source, playerId)
    if not Staff29.Require(source, PERMISSION) then return nil end

    local id = Staff29.ToInt(playerId, 1)
    if not id or not VFW.GetPlayerFromId(id) then return nil end

    local coords = coordsOf(id)
    if not coords then return nil end

    return { x = coords.x, y = coords.y, z = coords.z }
end)

AddEventHandler("vfw:playerDropped", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    local key = keyOf(xPlayer)
    if key then broughtFrom[key] = nil end
end)
