local floatingShown = false
local floatingId = nil

local function ShowFloating(point)
    local coords <const> = vector3(point.coords.x, point.coords.y, point.coords.z)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + (point.floatingZ or 0.5))

    if not onScreen then
        if floatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            floatingShown = false
            floatingId = nil
        end
        return
    end

    local data <const> = {
        id = "vehicleTuning_" .. tostring(point.id),
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = {
            { label = "Menu extra véhicule", key = "E", icon = "car" }
        }
    }

    if floatingShown and floatingId == point.id then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        floatingShown = true
        floatingId = point.id
    end
end

local function HideFloating()
    if floatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        floatingShown = false
        floatingId = nil
    end
end

RegisterNetEvent("vehicleTuningBuilder:client:init", function(points)
    VehicleTuningBuilder:Clear()

    if not points or not next(points) then
        return
    end

    for i = 1, #points do
        VehicleTuningBuilder:AddOrUpdate(points[i])
    end
end)

RegisterNetEvent("vehicleTuningBuilder:client:resync", function(points)
    VehicleTuningBuilder:Clear()
    HideFloating()

    if not points or not next(points) then
        return
    end

    for i = 1, #points do
        VehicleTuningBuilder:AddOrUpdate(points[i])
    end
end)

RegisterNetEvent("vehicleTuningBuilder:client:syncPoint", function(point, action)
    if not point then
        return
    end

    if not VFW.PlayerData.job or VFW.PlayerData.job.name ~= point.jobRequired then
        return
    end

    VehicleTuningBuilder:AddOrUpdate(point)
end)

RegisterNetEvent("vehicleTuningBuilder:client:removePoint", function(pointId)
    VehicleTuningBuilder:Remove(pointId)

    if floatingId == pointId then
        HideFloating()
    end
end)

CreateThread(function()
    local sleep = 1000

    while true do
        sleep = 1000

        if IsNuiFocused() then
            HideFloating()
        elseif #VehicleTuningBuilder.cache > 0 then
            local ped <const> = PlayerPedId()
            local playerCoords <const> = GetEntityCoords(ped)
            local found = false

            for i = 1, #VehicleTuningBuilder.cache do
                local point <const> = VehicleTuningBuilder.cache[i]
                local pointCoords <const> = vector3(point.coords.x, point.coords.y, point.coords.z)
                local dist <const> = #(playerCoords - pointCoords)

                if dist <= 2.0 then
                    found = true
                    sleep = 0
                    ShowFloating(point)

                    if VFW.Interact.JustPressed(0, 38) then
                        HideFloating()
                        VehicleTuningBuilder:OpenMenu(point)
                    end
                    break
                end
            end

            if not found then
                HideFloating()
            end
        end

        Wait(sleep)
    end
end)
