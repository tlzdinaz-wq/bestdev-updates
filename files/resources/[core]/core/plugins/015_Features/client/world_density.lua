---@meta _
---@diagnostic disable: duplicate-doc-field

-- Densité du monde (PNJ, trafic, véhicules garés, scénarios).
--
-- Les multiplicateurs de densité sont des natifs « this frame » : ils doivent être posés à
-- chaque frame sur chaque client. L'état de référence vit côté serveur (variable
-- `world_density`, réglée depuis Gestion > Serveur > Densité du monde) et est diffusé par
-- `vfw:density:apply`. À la connexion, le client va chercher la valeur courante.
--
-- 1.0 = densité normale de GTA, 0.0 = personne.
-- Les valeurs du menu sont posées à chaque frame, y compris à 1.0, pour rester
-- la seule source : aucun autre script ne doit réécrire ces multiplicateurs.

local density = { peds = 1.0, vehicles = 1.0, parked = 1.0, scenarios = 1.0 }

local DRIVE_SCENARIOS = {
    "WORLD_VEHICLE_DRIVE_SOLO",
    "WORLD_VEHICLE_DRIVE_PASSENGERS",
    "WORLD_VEHICLE_DRIVE_PASSENGERS_LIMITED",
    "WORLD_VEHICLE_BUSINESSMEN",
}

local PARK_SCENARIOS = {
    "WORLD_VEHICLE_PARK_PARALLEL",
    "WORLD_VEHICLE_PARK_PERPENDICULAR_NOSE_IN",
}

local function budgetFor(value)
    if value <= 0.0 then return 0 end
    if value < 0.34 then return 1 end
    if value < 0.67 then return 2 end
    return 3
end

local function syncPopulation()
    local vehiclesOn = density.vehicles > 0.0
    local parkedOn = density.parked > 0.0

    SetVehiclePopulationBudget(budgetFor(density.vehicles))
    SetPedPopulationBudget(budgetFor(math.max(density.peds, density.scenarios)))
    SetDistantCarsEnabled(vehiclesOn)
    SetAllVehicleGeneratorsActive(vehiclesOn)

    for i = 1, #DRIVE_SCENARIOS do
        SetScenarioTypeEnabled(DRIVE_SCENARIOS[i], vehiclesOn)
    end
    for i = 1, #PARK_SCENARIOS do
        SetScenarioTypeEnabled(PARK_SCENARIOS[i], parkedOn)
    end
end

local function hasPlayer(veh)
    local seats = GetVehicleMaxNumberOfPassengers(veh)
    for seat = -1, seats - 1 do
        local ped = GetPedInVehicleSeat(veh, seat)
        if ped ~= 0 and IsPedAPlayer(ped) then
            return true
        end
    end
    return false
end

local function removeAmbient(veh)
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    if DoesEntityExist(veh) then
        DeleteEntity(veh)
    end
end

-- À 0, les voitures déjà lancées continuent sinon : on retire seulement le trafic ambiant.
local function clearAmbientVehicles()
    if density.vehicles > 0.0 and density.parked > 0.0 then return end

    local pool = GetGamePool("CVehicle")
    for i = 1, #pool do
        local veh = pool[i]
        if DoesEntityExist(veh) and not hasPlayer(veh) and not IsEntityAMissionEntity(veh) then
            local pop = GetEntityPopulationType(veh)
            local driver = GetPedInVehicleSeat(veh, -1)
            local npcDriver = driver ~= 0 and not IsPedAPlayer(driver)
            if density.vehicles <= 0.0 and npcDriver and (pop == 1 or pop == 3 or not IsEntityAMissionEntity(veh)) and pop ~= 5 then
                removeAmbient(veh)
            elseif density.parked <= 0.0 and pop == 2 then
                removeAmbient(veh)
            end
        end
    end
end

local function clamp01(value, fallback)
    local n = tonumber(value)
    if not n then return fallback end
    if n < 0.0 then return 0.0 end
    if n > 1.0 then return 1.0 end
    return n + 0.0
end

local function apply(cfg)
    if type(cfg) ~= "table" then return end

    density.peds = clamp01(cfg.peds, density.peds)
    density.vehicles = clamp01(cfg.vehicles, density.vehicles)
    density.parked = clamp01(cfg.parked, density.parked)
    density.scenarios = clamp01(cfg.scenarios, density.scenarios)
    syncPopulation()
    if density.vehicles <= 0.0 or density.parked <= 0.0 then
        clearAmbientVehicles()
    end
end

RegisterNetEvent("vfw:density:apply", apply)

--- Valeurs courantes appliquées sur ce client.
---@return table
function VFW.GetWorldDensity()
    return { peds = density.peds, vehicles = density.vehicles, parked = density.parked, scenarios = density.scenarios }
end

CreateThread(function()
    Wait(2500)
    apply(TriggerServerCallback("vfw:density:get"))
end)

RegisterNetEvent("vfw:onPlayerLoaded", function()
    CreateThread(function()
        Wait(1000)
        apply(TriggerServerCallback("vfw:density:get"))
    end)
end)

CreateThread(function()
    while true do
        SetPedDensityMultiplierThisFrame(density.peds)
        SetScenarioPedDensityMultiplierThisFrame(density.scenarios, density.scenarios)
        SetVehicleDensityMultiplierThisFrame(density.vehicles)
        SetRandomVehicleDensityMultiplierThisFrame(density.vehicles)
        SetParkedVehicleDensityMultiplierThisFrame(density.parked)
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if density.vehicles <= 0.0 or density.parked <= 0.0 or density.peds <= 0.0 then
            syncPopulation()
            clearAmbientVehicles()
            Wait(1000)
        else
            Wait(2000)
        end
    end
end)
