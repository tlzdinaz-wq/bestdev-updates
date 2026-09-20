---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Auto-calibrage des pompes a essence
-- ============================================================
-- `gas_stations` est seede (sql/91_seed_monde.sql) mais `gas_station_pumps`
-- ne peut pas l'etre : les pompes sont des props de la carte, leurs positions
-- exactes ne sont connues que du jeu. Plutot que de les recopier a la main,
-- le premier joueur qui passe pres d'une station sans pompe releve les props
-- autour de lui et les remonte ici. Le serveur valide et inscrit une seule
-- fois, puis la station est calibree pour de bon.
--
-- Le builder staff (menu « Stations essence ») reste la reference pour
-- corriger ou completer a la main : il ecrit dans la meme table.
--
-- Garde-fous, parce que la donnee vient du client :
--   * la station doit exister et n'avoir AUCUNE pompe ;
--   * chaque modele doit etre dans GasStationConfig.GasPumpModels ;
--   * chaque pompe doit etre a moins de CALIBRATION_RADIUS de la station ;
--   * 24 pompes maximum par station ;
--   * une seule calibration acceptee par station et par demarrage.
-- ============================================================

local CALIBRATION_RADIUS <const> = 40.0
local MAX_PUMPS_PER_STATION <const> = 24

-- Stations deja traitees pendant cette session (evite deux clients simultanes).
local calibrating = {}

--- Table de recherche des modeles de pompe autorises.
local allowedModels
local function AllowedModels()
    if allowedModels then return allowedModels end
    allowedModels = {}
    local list = (GasStationConfig and GasStationConfig.GasPumpModels) or {}
    for i = 1, #list do
        allowedModels[math.floor(list[i])] = true
    end
    return allowedModels
end

--- Stations sans aucune pompe en base.
---@return table[] liste de { id, x, y, z }
local function StationsWithoutPumps()
    local rows = MySQL.query.await([[
        SELECT s.`id`, s.`coords_x`, s.`coords_y`, s.`coords_z`
        FROM `gas_stations` s
        LEFT JOIN `gas_station_pumps` p ON p.`station_id` = s.`id`
        WHERE p.`id` IS NULL
    ]]) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        if not calibrating[row.id] then
            out[#out + 1] = {
                id = row.id,
                x = row.coords_x + 0.0,
                y = row.coords_y + 0.0,
                z = row.coords_z + 0.0,
            }
        end
    end
    return out
end

RegisterServerCallback("fl_gasstation:getStationsToCalibrate", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    return StationsWithoutPumps()
end)

RegisterNetEvent("fl_gasstation:calibrateStation", function(stationId, pumps)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(stationId)
    if not id or type(pumps) ~= "table" or #pumps == 0 then return end
    if calibrating[id] then return end
    if not Feat27.RateLimit(source, "gas:calibrate", 2000) then return end

    calibrating[id] = true

    local station = MySQL.single.await(
        "SELECT `id`, `coords_x`, `coords_y`, `coords_z` FROM `gas_stations` WHERE `id` = ?", { id })
    if not station then
        calibrating[id] = nil
        return
    end

    -- Une station deja pourvue n'est jamais recalibree automatiquement.
    local existing = MySQL.scalar.await(
        "SELECT COUNT(*) FROM `gas_station_pumps` WHERE `station_id` = ?", { id }) or 0
    if tonumber(existing) > 0 then
        calibrating[id] = nil
        return
    end

    local center = vector3(station.coords_x + 0.0, station.coords_y + 0.0, station.coords_z + 0.0)
    local models = AllowedModels()
    local inserted = 0

    for i = 1, #pumps do
        if inserted >= MAX_PUMPS_PER_STATION then break end

        local pump = pumps[i]
        local coords = type(pump) == "table" and Feat27.Vec3(pump.coords) or nil
        local model = type(pump) == "table" and math.floor(tonumber(pump.model) or 0) or 0

        if coords and models[model] then
            local pos = vector3(coords.x, coords.y, coords.z)
            if #(pos - center) <= CALIBRATION_RADIUS then
                MySQL.insert.await([[
                    INSERT INTO `gas_station_pumps` (`station_id`, `coords_x`, `coords_y`, `coords_z`, `model`, `heading`)
                    VALUES (?, ?, ?, ?, ?, ?)
                ]], { id, coords.x, coords.y, coords.z, model, tonumber(pump.heading) or 0.0 })
                inserted = inserted + 1
            end
        end
    end

    if inserted == 0 then
        -- Rien de valable : on rouvre la station a une prochaine tentative.
        calibrating[id] = nil
        return
    end

    GasStationServer.Reload()
    TriggerClientEvent("fl_gasstation:forceRefreshPumps", -1)
    console.init("fl_gasstation", ("station #%d calibree : %d pompe(s)"):format(id, inserted))
end)
