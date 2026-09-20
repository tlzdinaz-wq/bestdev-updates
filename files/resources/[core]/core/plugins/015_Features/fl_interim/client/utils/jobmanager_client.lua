
RegisterNetEvent("interim:firstwp:set", function(x, y, timestamp)
    if type(x) ~= "number" or type(y) ~= "number" then return end
    SetNewWaypoint(x, y)
    VFW.ShowNotification({ type = "VERT", content = "Un point vers votre poste de travail a été placé sur votre GPS." })
end)

RegisterNetEvent("interim:jobs:notification", function(data)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification(data)
    end
end)