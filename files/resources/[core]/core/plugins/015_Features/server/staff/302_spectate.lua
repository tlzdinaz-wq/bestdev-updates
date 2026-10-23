-- Spectate : le relais serveur.
--
-- Le client assombrit l'ecran, masque son personnage, puis demande au serveur de le
-- placer sur la cible — c'est le serveur qui connait la position des autres joueurs.
-- Il attend ensuite `core:StaffSpectate` en retour pour se teleporter et enclencher
-- le mode spectateur.
--
-- Ce handler n'existait pas. L'evenement partait dans le vide, la reponse n'arrivait
-- jamais, et l'ecran restait noir : c'est le « chargement infini » signale.
--
-- Contrat avec le client (client/staff/events.lua) :
--   TriggerClientEvent("core:StaffSpectate", staff, coords, cibleId, actif)
--     actif = true  -> `coords` est la position de la CIBLE, pour l'y amener
--     actif = false -> `coords` est la position d'AVANT le spectate, pour l'y ramener

local PERMISSIONS <const> = { "spectate", "staff_menu", "menu_anim" }

-- Position et instance du staff avant son spectate, pour tout restaurer en sortant.
local origins = {}

---@param source number
---@return table|nil xPlayer
local function allowed(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    for i = 1, #PERMISSIONS do
        if xPlayer.hasPermission(PERMISSIONS[i]) then return xPlayer end
    end

    Staff29.Notify(source, "ERROR", "Spectate", "Vous n'avez pas la permission requise.")
    return nil
end

---@param playerId number
---@return table|nil
local function coordsOf(playerId)
    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then return nil end

    local coords = GetEntityCoords(ped)
    return { x = coords.x, y = coords.y, z = coords.z }
end

--- Renvoie le staff a sa place et eteint son mode spectateur.
---
--- Sert aussi de sortie de secours : sans reponse, son ecran resterait noir.
---@param source number
---@param targetId number|nil
local function stop(source, targetId)
    local origin = origins[source]
    local back = origin and origin.coords or coordsOf(source)
    local bucket = origin and origin.bucket
    origins[source] = nil

    if bucket ~= nil then
        SetPlayerRoutingBucket(source, bucket)
    end
    TriggerClientEvent("core:StaffSpectate", source, back, targetId, false)
end

RegisterNetEvent("core:StaffSpectate", function(targetId, enable)
    local source = source
    local id = Staff29.ToInt(targetId, 1)

    if not allowed(source) then
        -- Refuser sans repondre laisserait l'ecran au noir.
        stop(source, id)
        return
    end

    if not enable then
        stop(source, id)
        return
    end

    if not id or id == source then
        Staff29.Notify(source, "ERROR", "Spectate", "Cette cible n'est pas valide.")
        stop(source, id)
        return
    end

    if not VFW.GetPlayerFromId(id) then
        Staff29.Notify(source, "ERROR", "Spectate", "Ce joueur n'est plus connecte.")
        stop(source, id)
        return
    end

    local target = coordsOf(id)
    if not target then
        Staff29.Notify(source, "ERROR", "Spectate", "Ce joueur n'est pas encore apparu en jeu.")
        stop(source, id)
        return
    end

    -- Le client a masque son personnage mais ne l'a pas encore deplace : sa position
    -- est donc encore celle d'avant le spectate. C'est le moment de la retenir.
    if not origins[source] then
        origins[source] = {
            coords = coordsOf(source),
            bucket = GetPlayerRoutingBucket(source),
        }
    end

    -- Un joueur situé dans une autre instance n'est jamais streamé chez le staff,
    -- même après une téléportation aux mêmes coordonnées. Aligner temporairement le
    -- routing bucket évite donc le chargement infini du ped cible.
    SetPlayerRoutingBucket(source, GetPlayerRoutingBucket(id))

    TriggerClientEvent("core:StaffSpectate", source, target, id, true)
end)

AddEventHandler("vfw:playerDropped", function(source)
    origins[source] = nil
end)
