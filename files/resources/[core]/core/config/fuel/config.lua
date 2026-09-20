---@meta _
---@diagnostic disable: duplicate-doc-field

---@class Fuel
---@field ProgressTime number  Durée d'animation de remplissage (secondes)
---@field FuelDecor  string   Nom du décorateur de niveau carburant
---@field Classes    table    Multiplicateurs par classe de véhicule
---@field FuelUsage  table    Multiplicateurs par régime moteur (RPM)
Fuel = {}

-- Durée de l'animation de plein (secondes)
Fuel.ProgressTime = 5

-- Nom du décorateur réseau utilisé pour synchroniser le niveau de carburant
Fuel.FuelDecor = "_FUEL_LEVEL"

-- Consommation = FuelUsage[RPM] * Classes[class] / 10 par seconde
-- Un plein de 100 dure environ 50 minutes de conduite continue à régime normal

-- Multiplicateur de consommation par classe de véhicule
Fuel.Classes = {
    [0]  = 0.7,  -- Compacts
    [1]  = 0.7,  -- Sedans
    [2]  = 0.8,  -- SUVs (consomment plus)
    [3]  = 0.7,  -- Coupes
    [4]  = 0.85, -- Muscle (consomment plus)
    [5]  = 0.75, -- Sports Classics
    [6]  = 0.6,  -- Sports (économiques)
    [7]  = 0.65, -- Super
    [8]  = 0.5,  -- Motorcycles (économiques)
    [9]  = 0.9,  -- Off-road (consomment plus)
    [10] = 1.0,  -- Industrial (consomment beaucoup)
    [11] = 0.8,  -- Utility
    [12] = 0.85, -- Vans
    [13] = 0.0,  -- Cycles (pas de carburant)
    [17] = 0.6,  -- Service
    [18] = 0.65, -- Emergency
    [19] = 1.0,  -- Military (consomment beaucoup)
    [20] = 1.0,  -- Commercial (consomment beaucoup)
    [21] = 1.0,  -- Trains
}

-- Multiplicateur de consommation par régime moteur (RPM normalisé 0.0–1.0)
Fuel.FuelUsage = {
    [1.0] = 1.0,  -- Régime maximum — consommation élevée
    [0.9] = 0.9,
    [0.8] = 0.8,
    [0.7] = 0.7,
    [0.6] = 0.6,
    [0.5] = 0.5,
    [0.4] = 0.4,
    [0.3] = 0.3,
    [0.2] = 0.2,
    [0.1] = 0.1,  -- Ralenti — très peu de consommation
    [0.0] = 0.0,
}
