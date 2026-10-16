-- Shadow Tracer — moitié serveur manquante.
-- Le client (client/staff/shadow_clone.lua) sait déjà tout faire : spawner un ped fantôme à
-- l'emplacement de déconnexion, avec son skin, et le nom/UUID/heure. Mais rien côté serveur ne
-- capturait ces données à la déconnexion ni ne les diffusait aux staffs abonnés (bug : le clone
-- n'apparaissait jamais). Note : cette moitié serveur ne fournissait pas non plus de raison de
-- déconnexion au client — ajoutée ici (ghost.reason), et affichée par shadow_clone.lua.

local GHOST_LIFETIME_MS = 30 * 60 * 1000 -- 30 minutes, comme annoncé dans le texte du menu staff

local subscribedStaff = {} -- [source] = true
local ghostRegistry = {}   -- [playerServerId] = dernière donnée de déconnexion connue

local function canShadowTrace(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.hasPermission("spectate") or xPlayer.hasPermission("staff_menu")
end

-- Le client n'a pas l'horloge du serveur : on envoie l'ancienneté en secondes au moment de
-- l'envoi, il la fait avancer de son côté pour afficher « déconnecté il y a X ».
local function withAge(ghost)
    local copy = {}
    for key, value in pairs(ghost) do copy[key] = value end
    copy.ageSeconds = math.max(0, os.time() - (tonumber(ghost.at) or os.time()))
    return copy
end

local function snapshotGhosts()
    local list = {}
    for _, ghost in pairs(ghostRegistry) do
        list[#list + 1] = withAge(ghost)
    end
    return list
end

local function broadcastToSubscribers(event, ...)
    for staffSource in pairs(subscribedStaff) do
        TriggerClientEvent(event, staffSource, ...)
    end
end

-- Appelé sans argument par le menu staff (bascule pure, pas d'état transmis).
RegisterNetEvent("vfw:shadowClone:toggle", function()
    local source = source
    if not canShadowTrace(source) then return end

    local enabled = not subscribedStaff[source]
    subscribedStaff[source] = enabled or nil

    TriggerClientEvent("vfw:shadowClone:toggle", source, enabled, enabled and snapshotGhosts() or nil)
end)

AddEventHandler("playerDropped", function(reason)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    subscribedStaff[source] = nil

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local ghost = {
        playerServerId = source,
        permId = xPlayer.identifier,
        name = xPlayer.name or GetPlayerName(source) or "?",
        reason = (type(reason) == "string" and reason ~= "") and reason or "Raison inconnue",
        position = { x = coords.x, y = coords.y, z = coords.z },
        heading = heading,
        skin = xPlayer.skin,
        timeStr = os.date("%H:%M:%S"),
        at = os.time(),
        ageSeconds = 0,
    }

    ghostRegistry[source] = ghost
    broadcastToSubscribers("vfw:shadowClone:add", withAge(ghost))

    SetTimeout(GHOST_LIFETIME_MS, function()
        if ghostRegistry[source] ~= ghost then return end
        ghostRegistry[source] = nil
        broadcastToSubscribers("vfw:shadowClone:remove", { source })
    end)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    subscribedStaff = {}
    ghostRegistry = {}
end)
