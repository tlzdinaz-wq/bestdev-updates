-- Gestion > Zones de circulation : le staff voit, crée, modifie et supprime les zones de limitation de
-- vitesse. Le stockage et la diffusion aux joueurs sont ceux des zones de la police (MiscB.Traffic, dans
-- misc_b/34_11_jobs_common.lua) : une zone posée depuis le MDT apparaît ici, et inversement.

local function Allowed(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("gestion") or xPlayer.hasPermission("server_management") or xPlayer.hasPermission("dev") then
        return xPlayer
    end
    return nil
end

local DENIED = { ok = false, error = "Permission gestion serveur requise." }

RegisterServerCallback("gestion:traffic:list", function(source)
    if not Allowed(source) then return DENIED end
    return { ok = true, zones = MiscB.Traffic.List() }
end)

--- Crée une zone (sans `id`) ou modifie celle dont on donne l'`id`.
RegisterServerCallback("gestion:traffic:save", function(source, data)
    if not Allowed(source) then return DENIED end
    if type(data) ~= "table" then return { ok = false, error = "Zone invalide." } end

    local clean, reason = MiscB.Traffic.Clean(data)
    if not clean then return { ok = false, error = reason } end

    local id = MiscB.ToInt(data.id, 1)
    local zone, err
    if id then
        zone, err = MiscB.Traffic.Update(id, clean)
    else
        zone, err = MiscB.Traffic.Add(clean, "staff")
    end
    if not zone then return { ok = false, error = err or "Enregistrement impossible." } end

    return { ok = true, zone = zone, zones = MiscB.Traffic.List() }
end)

RegisterServerCallback("gestion:traffic:delete", function(source, zoneId)
    if not Allowed(source) then return DENIED end

    local id = MiscB.ToInt(zoneId, 1)
    if not id then return { ok = false, error = "Zone invalide." } end

    MiscB.Traffic.Remove(id)
    return { ok = true, zones = MiscB.Traffic.List() }
end)
