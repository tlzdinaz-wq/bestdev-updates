local function refreshStaffMenus(deletedId)
    if not StaffMenu then return end

    if StaffMenu.TeleportList and StaffMenu.TeleportList.opened then
        StaffMenu.TeleportList.refresh()
    end

    if StaffMenu.TeleportManage and StaffMenu.TeleportManage.opened then
        StaffMenu.TeleportManage.refresh()
    end
end

local function applySnapshot(points)
    TeleportBuilder.cache = {}

    if points and next(points) then
        for i = 1, #points do
            TeleportBuilder.cache[#TeleportBuilder.cache + 1] = points[i]
        end
    end

    refreshStaffMenus()
end

RegisterNetEvent("teleportBuilder:client:init", function(points)
    applySnapshot(points)
end)

local function fetchSnapshot()
    if not TriggerServerCallback then
        return
    end
    local points <const> = TriggerServerCallback("teleportBuilder:getAllPoints")
    applySnapshot(points or {})
end

AddEventHandler("onClientResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        fetchSnapshot()
    end)
end)

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    if #TeleportBuilder.cache == 0 then
        fetchSnapshot()
    end
end)

RegisterNetEvent("teleportBuilder:client:sync", function(point, action)
    if not point or not point.id then
        return
    end

    TeleportBuilder:Upsert(point)
    refreshStaffMenus()
end)

RegisterNetEvent("teleportBuilder:client:remove", function(pointId)
    if not pointId then
        return
    end

    TeleportBuilder:Remove(pointId)
    refreshStaffMenus(pointId)
end)
