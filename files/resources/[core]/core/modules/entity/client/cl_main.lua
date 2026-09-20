---@meta _
---@diagnostic disable: duplicate-doc-field

---@class cEntity
cEntity = {}



local disableDensity = GetConvar('entity_disable_density', 'true') == 'true'

if disableDensity then
    Citizen.CreateThread(function()
        while true do
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            Wait(0)
        end
    end)
end