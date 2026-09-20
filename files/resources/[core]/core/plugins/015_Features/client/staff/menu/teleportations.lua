---@meta _
---@diagnostic disable: duplicate-doc-field

-- Téléporte le joueur (et son véhicule s'il est dedans)
function StaffTeleportToCoords(x, y, z, heading)
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        SetEntityCoords(vehicle, x, y, z, false, false, false, true)
        if heading then
            SetEntityHeading(vehicle, heading)
        end
    else
        SetEntityCoords(ped, x, y, z, false, false, false, true)
        if heading then
            SetEntityHeading(ped, heading)
        end
    end
end

-- Predefined teleport locations
local teleportLocations = {
    { label = "Parking central", coords = vec3(-349.26, -875.02, 30.32) },
    { label = "Fourrière", coords = vec3(412.29, -1625.65, 29.29) },
    { label = "Mécano", coords = vec3(800.0, -823.03, 26.19) },
    { label = "Hôpital", coords = vec3(291.32, -611.53, 43.38) },
    { label = "LSPD", coords = vec3(429.54, -981.86, 30.71) },
    { label = "Concessionnaire", coords = vec3(-38.22, -1100.84, 26.42) },
    { label = "Gouvernement", coords = vec3(-529.814, -228.684, 35.702) },
    { label = "Aéroport", coords = vec3(-1037.52, -2963.29, 13.95) },
    { label = "Mont Chiliad", coords = vec3(501.76, 5604.28, 797.91) },
    { label = "Plage", coords = vec3(-1855.010, -346.030, 48.429) },
    { label = "Prison", coords = vec3(1679.49, 2513.71, 45.56) },
    { label = "Casino", coords = vec3(967.41, 15.80, 71.83) },
    { label = "Maze Bank Arena", coords = vec3(-248.49, -2010.51, 30.15) },
    { label = "Stade", coords = vec3(-721.11, -1326.36, 1.60) },
    { label = "Fort Zancudo", coords = vec3(-2012.85, 2956.54, 32.81) },
}

-- Build Teleportations Menu
function StaffMenu.BuildTeleportationsMenu()
    local perms = VFW.PlayerGlobalData.permissions or {}
    if not perms["alt_teleport"] then return end

    StaffMenu.teleportations.Separator(":globe: TÉLÉPORTATIONS RAPIDES")

    -- List all predefined teleport locations
    for _, location in ipairs(teleportLocations) do
        StaffMenu.teleportations.Button(":pin: " .. location.label, nil, nil, "arrow", false, function()
            -- Teleport the player to the selected location
            StaffTeleportToCoords(location.coords.x, location.coords.y, location.coords.z)

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Téléportations',
                message = "Téléporté à : " .. location.label .. "."
          })
        end)
    end
end