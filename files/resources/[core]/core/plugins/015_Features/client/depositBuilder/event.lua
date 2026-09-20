local function applySnapshot(points)
    DepositBuilder.cache = {}
    if not points then return end
    for i = 1, #points do
        DepositBuilder.cache[#DepositBuilder.cache + 1] = points[i]
    end
end

RegisterNetEvent("depositBuilder:client:init", function(points)
    applySnapshot(points)
end)

RegisterNetEvent("depositBuilder:client:sync", function(point)
    if not point or not point.id then return end
    DepositBuilder:Upsert(point)
end)

RegisterNetEvent("depositBuilder:client:remove", function(pointId)
    if not pointId then return end
    DepositBuilder:Remove(pointId)
end)

RegisterNetEvent("depositBuilder:client:openMenu", function(pointId, label)
    if DepositMenu then DepositMenu:Open(pointId, label) end
end)

RegisterNetEvent("depositBuilder:client:openConsult", function(pointId, label)
    if DepositConsultMenu then DepositConsultMenu:Open(pointId, label) end
end)

RegisterNetEvent("depositBuilder:client:openReadOnly", function(chestId)
    VFW.OpenChest(chestId, "stockage", 100)
end)

AddEventHandler("onClientResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(500)
        applySnapshot(TriggerServerCallback("depositBuilder:getAllPoints") or {})
    end)
end)
