---@meta _
---@diagnostic disable: duplicate-doc-field

local teleportLocations = {
    {
        category = "RACCOURCIS TELEPORTATION",
        locations = {
            {name = "Parking central LS", coords = vector3(-349.26, -875.02, 30.32)},
            {name = "Parking central Sandy Shore", coords = vector3(1868.56, 3696.73, 33.61)},
            {name = "Parking central Paleto", coords = vector3(-280.45, 6231.23, 31.70)}
        }
    },
    {
        category = "Lieux Importants",
        locations = {
            {name = "Aéroport LS", coords = vector3(-1037.51, -2963.24, 13.95)},
            {name = "Mont Chiliad", coords = vector3(501.76, 5604.28, 797.91)},
            {name = "Maze Bank Tower", coords = vector3(-75.20, -818.95, 326.18)},
            {name = "Hôpital Central", coords = vector3(293.11, -582.52, 43.19)},
            {name = "Commissariat Mission Row", coords = vector3(441.17, -982.23, 30.69)},
            {name = "Prison Bolingbroke", coords = vector3(1679.04, 2513.07, 45.56)},
            {name = "Fort Zancudo", coords = vector3(-2012.85, 2956.56, 32.81)},
            {name = "Observatoire", coords = vector3(-412.31, 1170.66, 325.84)},
            {name = "Vinewood Sign", coords = vector3(711.36, 1198.13, 348.53)},
            {name = "Pier", coords = vector3(-1850.13, -1231.75, 13.02)},
            {name = "Casino", coords = vector3(925.33, 46.68, 81.11)},
            {name = "Golf Club", coords = vector3(-1336.48, 59.53, 55.25)},
            {name = "Hippodrome", coords = vector3(1149.61, 264.47, 81.87)},
            {name = "Playboy Mansion", coords = vector3(-1534.31, 97.76, 56.77)}
        }
    },
    {
        category = "Concessionnaires",
        locations = {
            {name = "Concess Premium Deluxe", coords = vector3(-30.89, -1106.31, 26.42)},
            {name = "Concess Bateau", coords = vector3(-719.05, -1326.40, 1.60)},
            {name = "Concess Avion", coords = vector3(-1652.06, -3142.66, 13.99)},
            {name = "Concess Moto", coords = vector3(280.61, -1156.42, 29.29)},
            {name = "Benny's Custom", coords = vector3(-205.78, -1304.02, 31.24)},
            {name = "LS Customs Burton", coords = vector3(-357.61, -134.29, 38.68)},
            {name = "LS Customs Aéroport", coords = vector3(-1155.02, -1999.37, 13.18)},
            {name = "LS Customs Mesa", coords = vector3(731.82, -1085.68, 22.17)},
            {name = "LS Customs Paleto", coords = vector3(110.84, 6626.50, 31.79)},
            {name = "LS Customs Sandy", coords = vector3(1175.01, 2640.47, 37.75)}
        }
    },
    {
        category = "Zones Illégales",
        locations = {
            {name = "Laboratoire de Meth", coords = vector3(1391.77, 3608.73, 38.94)},
            {name = "Ferme de Weed", coords = vector3(2208.78, 5578.24, 53.74)},
            {name = "Cocaïne Lockup", coords = vector3(387.51, 3584.76, 33.29)},
            {name = "Bunker", coords = vector3(1571.12, 2230.48, 78.71)},
            {name = "Clubhouse Lost MC", coords = vector3(977.14, -104.07, 74.85)},
            {name = "Grove Street", coords = vector3(94.26, -1947.73, 20.74)},
            {name = "Forum Drive", coords = vector3(9.88, -1445.45, 30.51)},
            {name = "Vagos Territory", coords = vector3(324.85, -2033.86, 20.84)},
            {name = "Ballas Territory", coords = vector3(107.59, -1941.57, 20.80)}
        }
    },
    {
        category = "Intérieurs",
        locations = {
            {name = "FIB Building", coords = vector3(136.01, -749.29, 258.15)},
            {name = "IAA Office", coords = vector3(117.22, -620.84, 206.05)},
            {name = "Appartement Luxe", coords = vector3(-35.31, -580.42, 88.71)},
            {name = "Appartement Moyen", coords = vector3(346.52, -1012.86, -99.20)},
            {name = "Motel", coords = vector3(151.25, -1007.74, -99.00)},
            {name = "Bunker Intérieur", coords = vector3(895.37, -3246.04, -98.25)},
            {name = "Facility", coords = vector3(345.00, 4842.00, -59.00)},
            {name = "Nightclub", coords = vector3(-1569.32, -3017.41, -74.41)},
            {name = "Arcade", coords = vector3(2737.92, -374.17, -47.99)},
            {name = "Auto Shop", coords = vector3(1077.28, -2274.88, -50.00)},
            {name = "Agency", coords = vector3(-1003.77, -477.92, 50.03)}
        }
    },
    {
        category = "Paleto Bay",
        locations = {
            {name = "Centre Paleto", coords = vector3(-281.76, 6230.54, 31.70)},
            {name = "Commissariat Paleto", coords = vector3(-447.29, 6013.47, 31.72)},
            {name = "Hôpital Paleto", coords = vector3(-246.95, 6330.33, 32.43)},
            {name = "Bank Paleto", coords = vector3(-112.54, 6469.93, 31.63)},
            {name = "Ammunation Paleto", coords = vector3(-331.42, 6084.76, 31.45)},
            {name = "247 Paleto", coords = vector3(1729.22, 6414.95, 35.04)}
        }
    },
    {
        category = "Sandy Shores",
        locations = {
            {name = "Centre Sandy", coords = vector3(1961.52, 3740.88, 32.34)},
            {name = "Commissariat Sandy", coords = vector3(1853.05, 3687.42, 34.27)},
            {name = "Hôpital Sandy", coords = vector3(1839.53, 3672.90, 34.28)},
            {name = "Airfield Sandy", coords = vector3(1741.31, 3270.25, 41.13)},
            {name = "Ammunation Sandy", coords = vector3(1693.44, 3760.16, 34.71)},
            {name = "247 Sandy", coords = vector3(1961.24, 3740.84, 32.34)},
            {name = "Yellow Jack", coords = vector3(1985.65, 3053.98, 47.22)},
            {name = "Motel Sandy", coords = vector3(320.13, 2623.30, 44.46)}
        }
    },
    {
        category = "Cayo Perico",
        locations = {
            {name = "Aéroport Cayo", coords = vector3(4503.19, -4523.76, 4.42)},
            {name = "Manoir El Rubio", coords = vector3(5010.69, -5749.37, 28.85)},
            {name = "Plage Nord", coords = vector3(5162.49, -4649.89, 2.00)},
            {name = "Docks", coords = vector3(4903.73, -5168.78, 2.47)},
            {name = "Tour de Communication", coords = vector3(5265.76, -5427.84, 139.75)},
            {name = "Fields", coords = vector3(5330.52, -5269.84, 33.19)}
        }
    }
}

local teleportData = {
    selectedCategory = 1,
    showCoords = false
}

-- Build Teleport Places Menu
function StaffMenu.BuildTeleportPlacesMenu()
    StaffMenu.teleportPlaces.Separator("LIEUX DE TÉLÉPORTATION")
    
    -- Options
    StaffMenu.teleportPlaces.Checkbox("AFFICHER COORDONNÉES", "Afficher les coordonnées XYZ sous chaque lieu de la liste", false, teleportData.showCoords, function(_checked)
        teleportData.showCoords = _checked
    end)
    
    -- Direct teleport to coords
    StaffMenu.teleportPlaces.Button("TÉLÉPORTER AUX COORDONNÉES", "Saisir manuellement les coordonnées X, Y, Z pour se téléporter", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local xInput = VFW.Nui.KeyboardInput(true, "Coordonnée X", "")
        if not xInput then return end
        xInput = tostring(xInput)
        if xInput == "" or xInput == "KBD_CANCEL" then return end

        local yInput = VFW.Nui.KeyboardInput(true, "Coordonnée Y", "")
        if not yInput then return end
        yInput = tostring(yInput)
        if yInput == "" or yInput == "KBD_CANCEL" then return end

        local zInput = VFW.Nui.KeyboardInput(true, "Coordonnée Z", "")
        if not zInput then return end
        zInput = tostring(zInput)
        if zInput == "" or zInput == "KBD_CANCEL" then return end

        local x = tonumber((xInput:gsub(",", ".")))
        local y = tonumber((yInput:gsub(",", ".")))
        local z = tonumber((zInput:gsub(",", ".")))
        if x and y and z then
            StaffTeleportToCoords(x, y, z)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Lieux Téléport',
                message = string.format("Téléporté à : %.2f, %.2f, %.2f.", x, y, z)
            })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Lieux Téléport',
                message = "Ces coordonnées ne sont pas valides."
          })
        end
    end)
    
    -- Copy current coords
    StaffMenu.teleportPlaces.Button(":report: COPIER POSITION ACTUELLE", "Copier vos coordonnées actuelles au format vector4 dans le presse-papier", nil, "chevron", false, function()
        local coords = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        local text = string.format("vector4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading)
        
        -- This would normally copy to clipboard
        VFW.Clipboard(text)
        
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Lieux Téléport',
            message = "Position copiée : " .. text
        })
    end)
    
    StaffMenu.teleportPlaces.Separator(":folder: CATÉGORIES")
    
    -- Location categories
    for i, category in ipairs(teleportLocations) do
        StaffMenu.teleportPlaces.Button(
            ":pin: " .. category.category, 
            string.format("%d lieux", #category.locations), 
            nil, 
            "chevron", 
            false, 
            function()
                teleportData.selectedCategory = i
            end, 
            StaffMenu.teleportList
        )
    end
end

-- Build Teleport List Menu
function StaffMenu.BuildTeleportListMenu()
    local category = teleportLocations[teleportData.selectedCategory]
    
    if not category then return end
    
    StaffMenu.teleportList.Separator(category.category:upper())
    
    for _, location in ipairs(category.locations) do
        local subtitle = nil
        if teleportData.showCoords then
            subtitle = string.format("X: %.2f Y: %.2f Z: %.2f", location.coords.x, location.coords.y, location.coords.z)
        end
        
        StaffMenu.teleportList.Button(":globe: " .. location.name, subtitle, nil, "arrow", false, function()
            StaffTeleportToCoords(location.coords.x, location.coords.y, location.coords.z)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Lieux Téléport',
                message = "Téléporté à : " .. location.name .. "."
          })
        end)
    end
    
    StaffMenu.teleportList.Separator(nil)
    
    -- Teleport all to category
    StaffMenu.teleportList.Button("VISITER TOUS LES LIEUX", "Se téléporter successivement à chaque lieu de cette catégorie (3 sec entre chaque)", nil, "chevron", false, function()
        CreateThread(function()
            for i, location in ipairs(category.locations) do
                StaffTeleportToCoords(location.coords.x, location.coords.y, location.coords.z)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'INFO', subtitle = 'Lieux Téléport',
                    message = string.format("[%d/%d] %s", i, #category.locations, location.name)
                })
                Wait(3000)
            end
            
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Lieux Téléport',
                message = "Visite terminée."
          })
        end)
    end)
end