RegisterNetEvent("garageIllegal:client:syncAll", function(points)
    GarageIllegal:SetPoints(points or {})
end)

RegisterNetEvent("garageIllegal:client:clearAll", function()
    GarageIllegal:ClearAll()
end)

RegisterNetEvent("garageIllegal:client:syncNew", function(point)
    if not point then return end
    GarageIllegal:AddPoint(point)
end)

RegisterNetEvent("garageIllegal:client:syncUpdate", function(point)
    if not point then return end
    GarageIllegal:UpdatePoint(point)
end)

RegisterNetEvent("garageIllegal:client:syncDelete", function(id)
    if not id then return end
    GarageIllegal:DeletePoint(id)
end)
