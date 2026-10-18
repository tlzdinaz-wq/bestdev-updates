-- Budget de population au maximum, une seule fois.
-- Les multiplicateurs (piétons, trafic, garés, scénarios) viennent uniquement
-- de Gestion > Densité du monde (world_density.lua).

CreateThread(function()
    SetPedPopulationBudget(3)
    SetVehiclePopulationBudget(3)
    SetAllVehicleGeneratorsActive()
    SetRandomBoats(false)
    SetGarbageTrucks(false)
    SetRandomTrains(false)
end)
