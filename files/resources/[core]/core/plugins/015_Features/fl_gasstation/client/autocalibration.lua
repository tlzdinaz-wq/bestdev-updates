---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Auto-calibrage des pompes — cote client
-- ============================================================
-- Les stations sont seedees en base, leurs pompes non : ce sont des props de
-- la carte. Quand le joueur passe pres d'une station qui n'a encore aucune
-- pompe, on releve les props autour d'elle et on les remonte au serveur, qui
-- valide et inscrit une fois pour toutes (server/271_autocalibration.lua).
--
-- Discret par construction : aucun message, aucune interaction. Le thread
-- s'arrete de lui-meme des qu'il ne reste plus rien a calibrer.
-- ============================================================

local SCAN_DISTANCE <const> = 70.0    -- distance joueur -> station pour tenter un releve
local PUMP_RADIUS <const> = 35.0      -- rayon de collecte des props autour de la station
local POLL_INTERVAL <const> = 15000   -- ms entre deux verifications de proximite
local REFRESH_INTERVAL <const> = 120000 -- ms entre deux relectures de la liste serveur

local pending = nil       -- stations restant a calibrer
local lastRefresh = -1
local sent = {}           -- stations deja remontees pendant cette session

--- Releve les props de pompe autour d'une position.
---@param center vector3
---@return table[] { coords = {x,y,z}, model = hash, heading = number }
local function CollectPumps(center)
    local models = {}
    local list = (GasStationConfig and GasStationConfig.GasPumpModels) or {}
    for i = 1, #list do
        models[list[i]] = true
    end

    local found = {}
    for _, obj in ipairs(GetGamePool('CObject')) do
        if models[GetEntityModel(obj)] then
            local coords = GetEntityCoords(obj)
            if #(center - coords) <= PUMP_RADIUS then
                found[#found + 1] = {
                    coords = { x = coords.x, y = coords.y, z = coords.z },
                    model = GetEntityModel(obj),
                    heading = GetEntityHeading(obj),
                }
            end
        end
    end
    return found
end

CreateThread(function()
    -- Laisse le joueur apparaitre et les props se streamer avant le premier scan.
    Wait(20000)

    while true do
        local now = GetGameTimer()

        if pending == nil or (now - lastRefresh) > REFRESH_INTERVAL then
            local list = TriggerServerCallback("fl_gasstation:getStationsToCalibrate")
            pending = type(list) == "table" and list or {}
            lastRefresh = now

            -- Plus rien a calibrer : le thread n'a plus de raison de tourner.
            if #pending == 0 then return end
        end

        local playerCoords = GetEntityCoords(PlayerPedId())

        for i = 1, #pending do
            local station = pending[i]
            if station and not sent[station.id] then
                local center = vector3(station.x, station.y, station.z)
                if #(playerCoords - center) <= SCAN_DISTANCE then
                    local pumps = CollectPumps(center)
                    if #pumps > 0 then
                        sent[station.id] = true
                        TriggerServerEvent("fl_gasstation:calibrateStation", station.id, pumps)
                    end
                end
            end
        end

        Wait(POLL_INTERVAL)
    end
end)
