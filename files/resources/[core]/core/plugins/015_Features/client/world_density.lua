---@meta _
---@diagnostic disable: duplicate-doc-field

-- Densité du monde (PNJ, trafic, véhicules garés, scénarios).
--
-- Les multiplicateurs de densité sont des natifs « this frame » : ils doivent être posés à
-- chaque frame sur chaque client. L'état de référence vit côté serveur (variable
-- `world_density`, réglée depuis Gestion > Serveur > Densité du monde) et est diffusé par
-- `vfw:density:apply`. À la connexion, le client va chercher la valeur courante.
--
-- 1.0 = densité normale de GTA, 0.0 = personne. Rien n'est appliqué tant que tout vaut 1.0,
-- pour ne pas tourner une boucle par frame sans raison.

local density = { peds = 1.0, vehicles = 1.0, parked = 1.0, scenarios = 1.0 }
local active = false

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

    active = density.peds < 1.0 or density.vehicles < 1.0
        or density.parked < 1.0 or density.scenarios < 1.0
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
        if active then
            SetPedDensityMultiplierThisFrame(density.peds)
            SetScenarioPedDensityMultiplierThisFrame(density.scenarios, density.scenarios)
            SetVehicleDensityMultiplierThisFrame(density.vehicles)
            SetRandomVehicleDensityMultiplierThisFrame(density.vehicles)
            SetParkedVehicleDensityMultiplierThisFrame(density.parked)
            Wait(0)
        else
            Wait(500)
        end
    end
end)
