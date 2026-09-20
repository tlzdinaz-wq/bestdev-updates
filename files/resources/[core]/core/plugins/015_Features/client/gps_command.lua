RegisterCommand("gps", function(_, args)
    local x = tonumber(args[1])
    local y = tonumber(args[2])

    if not x or not y then
        VFW.ShowNotification({
            type = 'DEFAULT',
            name = "GPS",
            label = "Ces coordonnées ne sont pas valides",
            labelColor = "#ff4141",
            mainColor = 'rouge',
            mainMessage = "Utilisation : /gps <x> <y>",
            duration = 5,
        })
        return
    end

    SetNewWaypoint(x + 0.0, y + 0.0)

    VFW.ShowNotification({
        type = 'DEFAULT',
        name = "GPS",
        label = "Itinéraire défini",
        labelColor = "#10A8D1",
        mainMessage = ("Marqueur placé à %.1f, %.1f"):format(x, y),
        duration = 4,
    })
end, false)

TriggerEvent('chat:addSuggestion', '/gps', 'Placer un marqueur GPS aux coordonnées indiquées', {
    { name = 'x', help = 'Coordonnée X' },
    { name = 'y', help = 'Coordonnée Y' },
})
