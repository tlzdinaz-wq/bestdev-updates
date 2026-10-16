local zoneData = {
    name = nil,
    label = nil,
    url = nil,
    volume = 50,
    falloff = 1.0,
    sourcePosition = nil,
    points = {},
    height = 10.0,
}

local markerThread = nil
local isMarkersActive = false
local isRefreshing = false
local isNavigating = false

local function resetZoneData()
    zoneData = {
        name = nil,
        label = nil,
        url = nil,
        volume = 50,
        falloff = 1.0,
        sourcePosition = nil,
        points = {},
        height = 10.0,
    }
end

local function checkValidFormat()
    return zoneData.name and zoneData.label and zoneData.url and zoneData.sourcePosition and #zoneData.points >= 3
end

local function safeRefresh(menu)
    isRefreshing = true
    menu.refresh()
    isRefreshing = false
end

local function stopMarkerThread()
    if markerThread then
        isMarkersActive = false
        local timeout = 0
        while markerThread and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        markerThread = nil
    end
end

local function startMarkerThread()
    if markerThread or (not zoneData.points or #zoneData.points == 0) and not zoneData.sourcePosition then
        return
    end

    isMarkersActive = true
    markerThread = true
    CreateThread(function()
        while isMarkersActive do
            local points = zoneData.points
            local height = zoneData.height or 10.0

            for i = 1, #points do
                if not isMarkersActive then break end

                local point = points[i]
                if point and point.x and point.y and point.z then
                    DrawMarker(
                        28,
                        point.x, point.y, point.z - 0.5,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        0.5, 0.5, 0.5,
                        0, 150, 255, 200,
                        false, true, 2, false, nil, nil, false
                    )

                    DrawMarker(
                        28,
                        point.x, point.y, point.z + height - 0.5,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        0.5, 0.5, 0.5,
                        0, 255, 150, 150,
                        false, true, 2, false, nil, nil, false
                    )

                    DrawLine(
                        point.x, point.y, point.z,
                        point.x, point.y, point.z + height,
                        255, 255, 0, 150
                    )

                    local nextPoint = points[i + 1] or points[1]
                    if nextPoint and #points >= 2 then
                        DrawLine(
                            point.x, point.y, point.z,
                            nextPoint.x, nextPoint.y, nextPoint.z,
                            0, 200, 255, 200
                        )

                        DrawLine(
                            point.x, point.y, point.z + height,
                            nextPoint.x, nextPoint.y, nextPoint.z + height,
                            0, 255, 150, 150
                        )
                    end

                    local onScreen, screenX, screenY = World3dToScreen2d(point.x, point.y, point.z + 0.5)
                    if onScreen then
                        SetTextScale(0.35, 0.35)
                        SetTextFont(4)
                        SetTextProportional(1)
                        SetTextColour(255, 255, 255, 215)
                        SetTextCentre(true)
                        SetTextOutline()
                        SetTextEntry("STRING")
                        AddTextComponentString("Point " .. tostring(i))
                        DrawText(screenX, screenY)
                    end
                end
            end

            if zoneData.sourcePosition then
                local sp = zoneData.sourcePosition
                DrawMarker(
                    28,
                    sp.x, sp.y, sp.z - 0.5,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.8, 0.8, 0.8,
                    255, 50, 50, 220,
                    false, true, 2, false, nil, nil, false
                )

                DrawMarker(
                    28,
                    sp.x, sp.y, sp.z + (zoneData.height or 10.0) - 0.5,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.8, 0.8, 0.8,
                    255, 50, 50, 220,
                    false, true, 2, false, nil, nil, false
                )

                DrawLine(
                    sp.x, sp.y, sp.z,
                    sp.x, sp.y, sp.z + (zoneData.height or 10.0),
                    255, 50, 50, 200
                )

                local onScreen, screenX, screenY = World3dToScreen2d(sp.x, sp.y, sp.z + 1.0)
                if onScreen then
                    SetTextScale(0.4, 0.4)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 80, 80, 255)
                    SetTextCentre(true)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("SOURCE SONORE")
                    DrawText(screenX, screenY)
                end
            end

            Wait(0)
        end

        markerThread = nil
        isMarkersActive = false
    end)
end

local function saveIfUpdate()
    if zoneData.isUpdate and zoneData.oldName and zoneData.name then
        local success, err = TriggerServerCallback('core:ambientSound:update', zoneData.oldName, zoneData.name, zoneData.label, zoneData.url, zoneData.volume, zoneData.sourcePosition, zoneData.points, zoneData.height, zoneData.falloff)
        if not success then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = err or "Erreur lors de la sauvegarde"
          })
        end
    end
end

function StaffMenu.BuildAmbientSoundMenu()
    StaffMenu.builderAmbientSound.Button("CRÉER UNE ZONE SONORE", nil, nil, "chevron", false, function()
        resetZoneData()
    end, StaffMenu.builderAmbientSoundCreate)

    StaffMenu.builderAmbientSound.Button("LISTE DES ZONES SONORES", nil, nil, "chevron", false, function()
    end, StaffMenu.builderAmbientSoundList)
end

function StaffMenu.BuildAmbientSoundCreateMenu()
    StaffMenu.builderAmbientSoundCreate.Button("NOM DE LA ZONE", zoneData.name or "Non défini", nil, zoneData.name and "check" or "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Entrer le nom de la zone (identifiant unique)")

        if not name or name == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = "Ce nom n'est pas valide"
          })
        end

        zoneData.name = name
        safeRefresh(StaffMenu.builderAmbientSoundCreate)
    end)

    StaffMenu.builderAmbientSoundCreate.Button("LABEL", zoneData.label or "Non défini", nil, zoneData.label and "check" or "chevron", false, function()
        local label = VFW.Nui.KeyboardInput(true, "Entrer le label (nom affiché)")

        if not label or label == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = "Ce label n'est pas valide"
          })
        end

        zoneData.label = label
        safeRefresh(StaffMenu.builderAmbientSoundCreate)
    end)

    StaffMenu.builderAmbientSoundCreate.Button("URL YOUTUBE", zoneData.url and "Défini" or "Non défini", nil, zoneData.url and "check" or "chevron", false, function()
        local url = VFW.Nui.KeyboardInput(true, "Entrer l'URL YouTube de la vidéo/musique")

        if not url or url == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = "Cette URL n'est pas valide"
          })
        end

        zoneData.url = url
        safeRefresh(StaffMenu.builderAmbientSoundCreate)
    end)

    StaffMenu.builderAmbientSoundCreate.Button("VOLUME", tostring(zoneData.volume) .. "%", nil, "check", false, function()
        local volumeInput = VFW.Nui.KeyboardInput(true, "Entrer le volume (0-100)")
        local vol = tonumber(volumeInput)

        if not vol or vol < 0 or vol > 100 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = "Ce volume n'est pas valide (0-100)"
          })
        end

        zoneData.volume = math.floor(vol)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
            message = "Volume défini à " .. zoneData.volume .. "%"
      })

        safeRefresh(StaffMenu.builderAmbientSoundCreate)
    end)

    StaffMenu.builderAmbientSoundCreate.Button("FALLOFF", tostring(zoneData.falloff) .. "x | Vitesse de diminution du son en s'éloignant de la source", nil, "check", false, function()
        local falloffInput = VFW.Nui.KeyboardInput(true, "Exposant de falloff (0.1-5.0) | 0.5=lent 1.0=linéaire 2.0=rapide")
        local val = tonumber(falloffInput)

        if not val or val < 0.1 or val > 5.0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = "Cette atténuation n'est pas valide (0.1 à 5.0)"
          })
        end

        zoneData.falloff = math.floor(val * 10) / 10

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
            message = "Falloff défini à " .. zoneData.falloff .. "x"
      })

        safeRefresh(StaffMenu.builderAmbientSoundCreate)
    end)

    StaffMenu.builderAmbientSoundCreate.Separator("SOURCE SONORE")

    local sourceText = "Non défini"
  if zoneData.sourcePosition then
        sourceText = string.format("%.1f, %.1f, %.1f", zoneData.sourcePosition.x, zoneData.sourcePosition.y, zoneData.sourcePosition.z)
    end

    StaffMenu.builderAmbientSoundCreate.Button("POSITION SOURCE", sourceText, nil, zoneData.sourcePosition and "check" or "chevron", false, function()
        local playerCoords = GetEntityCoords(PlayerPedId())

        zoneData.sourcePosition = {
            x = playerCoords.x,
            y = playerCoords.y,
            z = playerCoords.z
        }

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
            message = "Position source définie"
      })

        if not isMarkersActive then
            startMarkerThread()
        end

        safeRefresh(StaffMenu.builderAmbientSoundCreate)
    end)

    StaffMenu.builderAmbientSoundCreate.Separator("POINTS DU CONTOUR (" .. #zoneData.points .. "/3 min)")

    StaffMenu.builderAmbientSoundCreate.Button("ZONE CIRCULAIRE (RAYON)", "Crée un cercle autour de toi", nil, "chevron", false, function()
        local rangeInput = VFW.Nui.KeyboardInput(true, "Entrer le rayon de la zone (ex: 10)")
        local radius = tonumber(rangeInput)

        if not radius or radius <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = "Ce rayon n'est pas valide"
          })
        end

        local playerCoords = GetEntityCoords(PlayerPedId())
        local numPoints = 24

        zoneData.points = {}

        for i = 0, numPoints - 1 do
            local angle = (i / numPoints) * 2 * math.pi
            zoneData.points[#zoneData.points + 1] = {
                x = playerCoords.x + math.cos(angle) * radius,
                y = playerCoords.y + math.sin(angle) * radius,
                z = playerCoords.z
            }
        end

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
            message = "Zone circulaire de " .. radius .. "m créée"
      })

        if not isMarkersActive then
            startMarkerThread()
        end

        safeRefresh(StaffMenu.builderAmbientSoundCreate)
    end)

    StaffMenu.builderAmbientSoundCreate.Button("AJOUTER UN POINT", "Mode custom - point par point", nil, "chevron", false, function()
        local playerCoords = GetEntityCoords(PlayerPedId())

        zoneData.points[#zoneData.points + 1] = {
            x = playerCoords.x,
            y = playerCoords.y,
            z = playerCoords.z
        }

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
            message = "Point " .. #zoneData.points .. " ajouté"
      })

        if not isMarkersActive then
            startMarkerThread()
        end

        safeRefresh(StaffMenu.builderAmbientSoundCreate)
    end)

    if #zoneData.points > 0 then
        StaffMenu.builderAmbientSoundCreate.Button("SUPPRIMER DERNIER POINT", "Retire le point " .. #zoneData.points, nil, "trash", false, function()
            table.remove(zoneData.points)

            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Sons d\'Ambiances',
                message = "Dernier point supprimé"
          })

            if #zoneData.points == 0 and not zoneData.sourcePosition then
                stopMarkerThread()
            end

            safeRefresh(StaffMenu.builderAmbientSoundCreate)
        end)

        StaffMenu.builderAmbientSoundCreate.Button("EFFACER TOUS LES POINTS", "Supprime les " .. #zoneData.points .. " points", nil, "trash", false, function()
            zoneData.points = {}

            if not zoneData.sourcePosition then
                stopMarkerThread()
            end

            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Sons d\'Ambiances',
                message = "Tous les points supprimés"
          })

            safeRefresh(StaffMenu.builderAmbientSoundCreate)
        end)
    end

    StaffMenu.builderAmbientSoundCreate.Separator("CONFIGURATION")

    StaffMenu.builderAmbientSoundCreate.Button("HAUTEUR", tostring(zoneData.height) .. "m", nil, "check", false, function()
        local heightInput = VFW.Nui.KeyboardInput(true, "Entrer la hauteur de la zone (ex: 10)")
        local height = tonumber(heightInput)

        if not height or height <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = "Cette hauteur n'est pas valide"
          })
        end

        zoneData.height = height

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
            message = "Hauteur définie à " .. height .. "m"
      })

        safeRefresh(StaffMenu.builderAmbientSoundCreate)
    end)

    StaffMenu.builderAmbientSoundCreate.Separator(nil)

    if not zoneData.isUpdate then
        local isValid = checkValidFormat()
        local statusText = ""
      if not zoneData.name then
            statusText = "Nom requis"
      elseif not zoneData.label then
            statusText = "Label requis"
      elseif not zoneData.url then
            statusText = "URL YouTube requise"
      elseif not zoneData.sourcePosition then
            statusText = "Position source requise"
      elseif #zoneData.points < 3 then
            statusText = "Minimum 3 points (" .. #zoneData.points .. "/3)"
      else
            statusText = "Prêt à créer"
      end

        StaffMenu.builderAmbientSoundCreate.Button("CRÉER LA ZONE", statusText, nil, isValid and "check" or "chevron", not isValid, function()
            local success, err = TriggerServerCallback('core:ambientSound:create', zoneData.name, zoneData.label, zoneData.url, zoneData.volume, zoneData.sourcePosition, zoneData.points, zoneData.height, zoneData.falloff)
            stopMarkerThread()
            resetZoneData()
            StaffMenu.builderAmbientSoundCreate.close()
            StaffMenu.builderAmbientSoundCreate.parent.open()

            if success then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
                    message = "Zone sonore créée"
              })
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                    message = err or "Erreur lors de la création"
              })
            end
        end)

        StaffMenu.builderAmbientSoundCreate.Button("ANNULER", nil, nil, "chevron", false, function()
            stopMarkerThread()
            resetZoneData()
            StaffMenu.builderAmbientSoundCreate.close()
            StaffMenu.builderAmbientSoundCreate.parent.open()
        end)
    end
end

function StaffMenu.BuildAmbientSoundListMenu()
    local zones = TriggerServerCallback("core:ambientSound:getAll") or {}

    if #zones == 0 then
        StaffMenu.builderAmbientSoundList.Separator("AUCUNE ZONE SONORE")
        return
    end

    for i = 1, #zones do
        local zone = zones[i]
        local pointsCount = zone.points and #zone.points or 0
        local statusLabel = zone.active and "Active" or "Inactive"

      StaffMenu.builderAmbientSoundList.Button(zone.label, zone.name .. " | " .. pointsCount .. " points | " .. statusLabel, nil, "chevron", false, function()
            isNavigating = true
            zoneData = {
                id = zone.id,
                name = zone.name,
                label = zone.label,
                url = zone.url,
                volume = zone.volume,
                falloff = zone.falloff or 1.0,
                sourcePosition = zone.sourcePosition,
                points = zone.points or {},
                height = zone.height or 10.0,
                isUpdate = true,
                oldName = zone.name,
                active = zone.active
            }
            startMarkerThread()
        end, StaffMenu.builderAmbientSoundManage)
    end
end

function StaffMenu.BuildAmbientSoundManageMenu()
    StaffMenu.builderAmbientSoundManage.Button("TÉLÉPORTATION", "Se téléporter au centre de la zone", nil, "chevron", false, function()
        if not zoneData.points or #zoneData.points == 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = "Aucun point défini"
          })
        end

        local sumX, sumY, sumZ = 0, 0, 0
        for _, p in ipairs(zoneData.points) do
            sumX = sumX + p.x
            sumY = sumY + p.y
            sumZ = sumZ + p.z
        end
        local count = #zoneData.points
        SetEntityCoords(PlayerPedId(), sumX / count, sumY / count, (sumZ / count) + 1.0, false, false, false, false)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
            message = "Téléporté au centre de la zone"
      })
    end)

    StaffMenu.builderAmbientSoundManage.Button("MODIFIER LA ZONE", nil, nil, "chevron", false, function()
        isNavigating = true
        zoneData.oldName = zoneData.name
        zoneData.isUpdate = true
        startMarkerThread()
    end, StaffMenu.builderAmbientSoundCreate)

    local toggleLabel = zoneData.active and "DÉSACTIVER" or "ACTIVER"
  StaffMenu.builderAmbientSoundManage.Button(toggleLabel, zoneData.active and "Couper le son de cette zone" or "Réactiver le son de cette zone", nil, zoneData.active and "check" or "chevron", false, function()
        local success, result = TriggerServerCallback('core:ambientSound:toggle', zoneData.id)

        if success then
            zoneData.active = result
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
                message = zoneData.active and "Zone activée" or "Zone désactivée"
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = result or "Erreur lors du toggle"
          })
        end

        safeRefresh(StaffMenu.builderAmbientSoundManage)
    end)

    StaffMenu.builderAmbientSoundManage.Button("SUPPRIMER LA ZONE", nil, nil, "trash", false, function()
        local success, err = TriggerServerCallback('core:ambientSound:delete', zoneData.id)
        stopMarkerThread()
        resetZoneData()
        StaffMenu.builderAmbientSoundManage.close()
        StaffMenu.builderAmbientSoundManage.parent.open()

        if success then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sons d\'Ambiances',
                message = "Zone sonore supprimée"
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sons d\'Ambiances',
                message = err or "Erreur lors de la suppression"
          })
        end
    end)
end

StaffMenu.builderAmbientSoundCreate.OnOpen(function()
    StaffMenu.BuildAmbientSoundCreateMenu()
end)

StaffMenu.builderAmbientSoundCreate.OnClose(function()
    if not isRefreshing and not isNavigating then
        if zoneData.isUpdate then
            saveIfUpdate()
        else
            stopMarkerThread()
            resetZoneData()
        end
    elseif zoneData.isUpdate and not isNavigating then
        saveIfUpdate()
    end
    isNavigating = false
end)

StaffMenu.builderAmbientSoundList.OnOpen(function()
    StaffMenu.BuildAmbientSoundListMenu()
end)

StaffMenu.builderAmbientSoundList.OnClose(function()
    if not isRefreshing and not isNavigating then
        stopMarkerThread()
        resetZoneData()
    end
    isNavigating = false
end)

StaffMenu.builderAmbientSoundManage.OnOpen(function()
    StaffMenu.BuildAmbientSoundManageMenu()
end)

StaffMenu.builderAmbientSoundManage.OnClose(function()
    if not isRefreshing and not isNavigating then
        stopMarkerThread()
        resetZoneData()
    end
    isNavigating = false
end)
