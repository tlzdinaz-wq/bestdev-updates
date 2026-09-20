local zombieZonesCache = {}
local selectedZombieZone = nil

function StaffMenu.BuildZombieMenu()
    StaffMenu.builderZombie.Separator("CREATION")

    StaffMenu.builderZombie.Button("DESSINER UNE ZONE", "Ouvrir la carte interactive pour dessiner un polygone", nil, "chevron", false, function()
        StaffMenu.builderZombie.close()
        SetTimeout(200, function()
            exports['core']:OpenZombieZoneDrawer()
        end)
    end)

    StaffMenu.builderZombie.Separator("GESTION")

    StaffMenu.builderZombie.Button("LISTE DES ZONES", "Voir et gérer toutes les zones zombie", nil, "chevron", false, function()
        zombieZonesCache = TriggerServerCallback("zombie:getZones") or {}
    end, StaffMenu.builderZombieList)
end

function StaffMenu.BuildZombieListMenu()
    if #zombieZonesCache == 0 then
        StaffMenu.builderZombieList.Separator("AUCUNE ZONE ZOMBIE")
        StaffMenu.builderZombieList.Button("~c~Aucune zone configurée", "Retournez au menu précédent et utilisez 'Dessiner une zone' pour en créer une", nil, nil, true, function() end)
        return
    end

    for _, zone in ipairs(zombieZonesCache) do
        local dot = zone.active and ":dot-green:" or ":dot-red:"
      local lootInfo = VFW.Math.FormatMoney(zone.loot_min or 50) .. "-" .. VFW.Math.FormatMoney(zone.loot_max or 150)
        local subtitle = zone.max_zombies .. " zombies | " .. lootInfo .. " | " .. (zone.active and "Active" or "Inactive")

        StaffMenu.builderZombieList.Button(
            zone.name,
            subtitle,
            dot,
            "chevron",
            false,
            function()
                selectedZombieZone = zone
            end,
            StaffMenu.builderZombieEdit
        )
    end
end

local function GetPolygonCenter(polygon)
    if not polygon or #polygon == 0 then return nil end
    local sumX, sumY = 0, 0
    for i = 1, #polygon do
        sumX = sumX + (polygon[i].x or 0)
        sumY = sumY + (polygon[i].y or 0)
    end
    return { x = sumX / #polygon, y = sumY / #polygon }
end

function StaffMenu.BuildZombieEditMenu()
    if not selectedZombieZone then
        StaffMenu.builderZombieEdit.Button("AUCUNE ZONE SÉLECTIONNÉE", nil, nil, nil, true, function() end)
        return
    end

    local zone = selectedZombieZone

    StaffMenu.builderZombieEdit.Checkbox(
        "Zone active",
        "Activer/désactiver le spawn de zombies dans cette zone",
        false,
        zone.active,
        function(checked)
            zone.active = not zone.active
        end
    )

    StaffMenu.builderZombieEdit.Slider(
        "Zombies max",
        zone.max_zombies,
        1,
        999,
        5,
        "Nombre maximum de zombies spawnés simultanément dans cette zone",
        false,
        function(value)
            zone.max_zombies = value
        end
    )

    StaffMenu.builderZombieEdit.Separator("LOOT")

    local lootMin = zone.loot_min or ZombieConfig.LootDefaultMin
    local lootMax = zone.loot_max or ZombieConfig.LootDefaultMax

    StaffMenu.builderZombieEdit.Slider(
        "Argent sale min",
        lootMin,
        0,
        5000,
        10,
        "Montant minimum d'argent sale en fouillant un zombie",
        false,
        function(value)
            zone.loot_min = value
            if value > (zone.loot_max or lootMax) then
                zone.loot_max = value
            end
        end
    )

    StaffMenu.builderZombieEdit.Slider(
        "Argent sale max",
        lootMax,
        0,
        5000,
        10,
        "Montant maximum d'argent sale en fouillant un zombie",
        false,
        function(value)
            zone.loot_max = value
            if value < (zone.loot_min or lootMin) then
                zone.loot_min = value
            end
        end
    )

    StaffMenu.builderZombieEdit.Separator("ACTIONS")

    StaffMenu.builderZombieEdit.Button(
        "SAUVEGARDER",
        "Enregistrer toutes les modifications en base de données",
        nil, "check", false,
        function()
            local result = TriggerServerCallback("zombie:saveZone", zone.id, {
                active = zone.active,
                max_zombies = zone.max_zombies,
                loot_min = zone.loot_min or lootMin,
                loot_max = zone.loot_max or lootMax,
            })
            if result and result.success then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Zombie',
                    message = zone.name .. " sauvegardée"
              })
                zombieZonesCache = TriggerServerCallback("zombie:getZones") or {}
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Zombie',
                    message = (result and result.error or "Erreur sauvegarde")
                })
            end
        end
    )

    StaffMenu.builderZombieEdit.Button(
        "SE TELEPORTER",
        "Téléportation au centre de la zone",
        nil, "arrow", false,
        function()
            local center = GetPolygonCenter(zone.polygon)
            if center then
                local ped = PlayerPedId()
                SetEntityCoords(ped, center.x, center.y, 300.0, false, false, false, false)
                Wait(500)
                local found, groundZ = GetGroundZFor_3dCoord(center.x, center.y, 300.0, false)
                if found then
                    SetEntityCoords(ped, center.x, center.y, groundZ + 1.0, false, false, false, false)
                else
                    SetEntityCoords(ped, center.x, center.y, 30.0, false, false, false, false)
                end
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'INFO', subtitle = 'Zombie',
                    message = "Téléporté au centre de " .. zone.name
                })
            end
        end
    )

    StaffMenu.builderZombieEdit.Button(
        "SUPPRIMER LA ZONE",
        "Supprime définitivement cette zone zombie",
        nil, "trash", false,
        function()
            local zoneName = zone.name
            local result = TriggerServerCallback("zombie:deleteZone", zone.id)
            if result and result.success then
                selectedZombieZone = nil
                zombieZonesCache = TriggerServerCallback("zombie:getZones") or {}
                StaffMenu.builderZombieEdit.close()
                SetTimeout(100, function()
                    if StaffMenu.builderZombieList.opened then
                        StaffMenu.builderZombieList.refresh()
                    end
                end)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Zombie',
                    message = zoneName .. " supprimée"
              })
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Zombie',
                    message = (result and result.error or "Erreur suppression")
                })
            end
        end
    )
end

StaffMenu.builderZombie.OnOpen(function()
    StaffMenu.BuildZombieMenu()
end)

StaffMenu.builderZombieList.OnOpen(function()
    StaffMenu.BuildZombieListMenu()
end)

StaffMenu.builderZombieEdit.OnOpen(function()
    StaffMenu.BuildZombieEditMenu()
end)

StaffMenu.builderZombieEdit.OnClose(function()
    if StaffMenu.builderZombieList.opened then
        StaffMenu.builderZombieList.refresh()
    end
end)
