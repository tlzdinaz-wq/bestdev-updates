-- Raison de mort visible pour le staff — moitié serveur manquante.
-- Le client (client/staff/death_reasons.lua) sait déjà tout afficher, et la cause réelle de
-- mort (pas juste "killed") est déjà calculée côté client et envoyée au serveur via
-- vfw:logs:onPlayerDeath / vfw:logs:death (utilisé pour les logs SQL) : on réutilise cette même
-- donnée plutôt que d'en redemander une nouvelle. Rien ne redistribuait cette raison au staff
-- qui active l'option (bug : jamais rien ne s'affichait, ni la cause ni le moment de la mort).

local subscribedStaff = {} -- [source] = true
local deathRegistry = {}   -- [victimServerId] = { coords, deathReason, timestamp }

local function canSeeDeathReasons(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.hasPermission("show_death_reasons") or xPlayer.hasPermission("staff_menu")
end

local function broadcastToSubscribers(event, ...)
    for staffSource in pairs(subscribedStaff) do
        TriggerClientEvent(event, staffSource, ...)
    end
end

RegisterNetEvent("staff:toggleDeathReasons", function(enabled)
    local source = source
    if not canSeeDeathReasons(source) then return end

    if enabled then
        subscribedStaff[source] = true
        for victimId, deathData in pairs(deathRegistry) do
            TriggerClientEvent("staff:updateDeathReason", source, victimId, deathData)
        end
    else
        subscribedStaff[source] = nil
    end
end)

RegisterNetEvent("staff:requestAllDeathData", function()
    local source = source
    if not canSeeDeathReasons(source) then return end

    for victimId, deathData in pairs(deathRegistry) do
        TriggerClientEvent("staff:updateDeathReason", source, victimId, deathData)
    end
end)

-- Déclenché après vfw:logs:onPlayerDeath (000_framework/server/004_death.lua), qui porte déjà
-- la cause réelle calculée (computedCause) — on ne demande rien de nouveau au client.
AddEventHandler("vfw:logs:death", function(source, data)
    if type(data) ~= "table" then return end

    local coords = data.victimCoords
    if type(coords) ~= "table" then return end

    local reason = (type(data.computedCause) == "string" and data.computedCause ~= "")
        and data.computedCause or "Cause inconnue"
    if data.isHeadshot then
        reason = reason .. " (tir à la tête)"
    end

    local deathData = {
        coords = coords,
        deathReason = reason,
        timestamp = os.time(),
    }

    deathRegistry[source] = deathData
    broadcastToSubscribers("staff:updateDeathReason", source, deathData)
end)

AddEventHandler("vfw:playerRevived", function(source)
    if not deathRegistry[source] then return end
    deathRegistry[source] = nil
    broadcastToSubscribers("staff:removeDeathReason", source)
end)

AddEventHandler("playerDropped", function()
    local source = source
    subscribedStaff[source] = nil

    if deathRegistry[source] then
        deathRegistry[source] = nil
        broadcastToSubscribers("staff:removeDeathReason", source)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    subscribedStaff = {}
    deathRegistry = {}
end)
