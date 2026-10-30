-- Images des véhicules générées depuis Gestion > Images > Véhicules (serveur : staff/322_vehicle_images.lua).
-- VFW.VehicleImage(model) : l'adresse FiveManage de l'image générée, sinon nil (l'appelant garde son image habituelle).

local images = {}

---@param model string
---@return string|nil
function VFW.VehicleImage(model)
    if type(model) ~= "string" then return nil end
    return images[model:lower()]
end

local function apply(changes)
    if type(changes) ~= "table" then return end
    for model, url in pairs(changes) do
        if type(model) == "string" then
            images[model:lower()] = (type(url) == "string" and url ~= "") and url or nil
        end
    end
end

RegisterNetEvent("core:vehicleImages:changed", apply)

CreateThread(function()
    while not (VFW.IsPlayerLoaded and VFW.IsPlayerLoaded()) do Wait(1000) end
    apply(TriggerServerCallback("vfw:server:getVehicleImages"))
end)
