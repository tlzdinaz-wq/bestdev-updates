Garage = Garage or {}
Garage.LabelOverrides = Garage.LabelOverrides or {}

local function fetch()
    local all = TriggerServerCallback("garage:labelOverride:getAll")
    if type(all) == "table" then
        Garage.LabelOverrides = all
    end
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    Wait(1000)
    fetch()
end)

RegisterNetEvent("garage:labelOverride:sync", function(overrides)
    if type(overrides) == "table" then
        Garage.LabelOverrides = overrides
    end
end)

RegisterNetEvent("garage:labelOverride:set", function(model, label)
    if type(model) ~= "string" or type(label) ~= "string" then return end
    Garage.LabelOverrides[model] = label
end)

RegisterNetEvent("garage:labelOverride:delete", function(model)
    if type(model) ~= "string" then return end
    Garage.LabelOverrides[model] = nil
end)

local function isBadLabel(value)
    return value == nil or value == "" or value == "NULL" or value == "CARNOTFOUND"
end

function Garage.GetVehicleLabel(model)
    if type(model) ~= "string" or model == "" then return "" end
    local key = model:lower()
    local override = Garage.LabelOverrides[key]
    if override and override ~= "" then return override end
    local make = GetMakeNameFromVehicleModel(model) or ""
    if isBadLabel(make) then make = "" end
    local name = GetLabelText(model) or model
    if isBadLabel(name) then name = model end
    if make ~= "" then
        return make .. " " .. name
    end
    return name
end
