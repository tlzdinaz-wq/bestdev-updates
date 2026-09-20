-- ══════════════════════════════════════════════════════════════════
-- Restaurant Stations — sync client (positions des stations)
-- ══════════════════════════════════════════════════════════════════
-- Reçoit l'état effectif des stations, reconstruit la config live
-- (création / suppression / déplacement) puis déclenche un rebuild des
-- zones/markers pour un effet sans reboot.
--
-- À la connexion on fait un PULL (le client demande au serveur dès
-- qu'il est prêt, avec retry) : plus fiable qu'un push qui peut arriver
-- avant que le client/serveur soit prêt.
-- ══════════════════════════════════════════════════════════════════

local Util = RestaurantStations

local function applyPayload(payload)
    if type(payload) ~= "table" then return end

    for key, locs in pairs(payload) do
        local cfg = Util.GetConfig(key)
        if cfg and cfg.Locations then
            for locKey, stations in pairs(locs) do
                local loc = cfg.Locations[locKey]
                if type(loc) == "table" then
                    -- purge les stations actuelles puis reconstruit l'état effectif
                    for k, v in pairs(loc) do
                        if Util.IsStation(v) then loc[k] = nil end
                    end
                    for stKey, def in pairs(stations) do
                        loc[stKey] = Util.BuildStation(def)
                    end
                end
            end
        end
    end

    -- rebuild local (zones + markers écoutent cet event)
    TriggerEvent("restaurant_stations:rebuild")
end

-- Push serveur (après une modification dans le builder)
RegisterNetEvent("restaurant_stations:sync", function(payload)
    applyPayload(payload)
end)

-- Pull à la connexion (fiable) : on récupère l'état effectif dès que
-- le serveur est prêt, avec retry tant que rien n'est renvoyé.
RegisterNetEvent("vfw:playerLoaded", function()
    for _ = 1, 30 do
        local payload = TriggerServerCallback("restaurant_stations:getAll")
        if type(payload) == "table" and next(payload) ~= nil then
            applyPayload(payload)
            return
        end
        Wait(1000)
    end
end)
