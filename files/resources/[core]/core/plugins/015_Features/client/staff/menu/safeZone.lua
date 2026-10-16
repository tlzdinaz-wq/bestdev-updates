local zoneData = {
    name = nil,
    label = nil,
    points = {},
    height = 10.0,
    actionDisabled = nil,
    bypassJob = nil
}

local markerThread = nil
local isMarkersActive = false
local isRefreshing = false
local isNavigating = false

local controlDisabled <const> = {
    { label = "Sauter", control = 22},
    { label = "Accroupi", control = 36},
    { label = "Bagarre", control = {24, 25, 140, 141, 142, 257, 263, 264, 331}},
    { label = "Sortir une arme", control = 45},
    { label = "Courir (Sprint)", control = 21 },
    { label = "Degats", control = "degats" },
    { label = "Carkill", control = "carkill" }
}

local function getIsDisableControl(control)
    if not zoneData.actionDisabled then
        return false, nil
    end

    if type(control) == "table" then
        local foundIndices = {}
        for _, ctrl in ipairs(control) do
            for i = 1, #zoneData.actionDisabled do
                if zoneData.actionDisabled[i] == ctrl then
                    foundIndices[#foundIndices + 1] = i
                end
            end
        end
        return #foundIndices == #control, foundIndices
    else
        for i = 1, #zoneData.actionDisabled do
            if zoneData.actionDisabled[i] == control then
                return true, {i}
            end
        end
    end

    return false, nil
end

local function resetZoneData()
    zoneData = {
        name = nil,
        label = nil,
        points = {},
        height = 10.0,
        actionDisabled = nil,
        bypassJob = nil
    }
end

local function checkValidFormatZoneData()
    if zoneData.name and zoneData.label and zoneData.points and #zoneData.points >= 3 and zoneData.actionDisabled then
        return true
    end
    return false
end

local function saveZoneIfUpdate()
    if zoneData.isUpdate and zoneData.oldName then
        TriggerServerEvent('zonesafe:server:update', zoneData.oldName, zoneData.name, zoneData.label, zoneData.points, zoneData.height, zoneData.actionDisabled, zoneData.bypassJob)
    end
end

local function checkAlreadyExistsJob(jobName)
    if not zoneData.bypassJob then
        return nil
    end

    for i = 1, #zoneData.bypassJob do
        if zoneData.bypassJob[i] == jobName then
            return true
        end
    end
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

local function safeRefresh(menu)
    isRefreshing = true
    menu.refresh()
    isRefreshing = false
end

local function startMarkerThread()
    if markerThread or not zoneData.points or #zoneData.points == 0 then
        return
    end

    isMarkersActive = true
    markerThread = true
    CreateThread(function()
        while isMarkersActive and zoneData.points and #zoneData.points > 0 do
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

            Wait(0)
        end

        markerThread = nil
        isMarkersActive = false
    end)
end

function StaffMenu.BuildCreateZoneSafeMenu()
    StaffMenu.CreateZoneSafe.Button("NOM DE LA ZONE", zoneData.name or "Non défini", nil, zoneData.name and "check" or "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom de zone (identifiant unique)")

        if not name or name == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Zones Sécurisées',
                message = "Ce nom n'est pas valide"
          })
        end

        zoneData.name = name
        safeRefresh(StaffMenu.CreateZoneSafe)
    end)

    StaffMenu.CreateZoneSafe.Button("LABEL DE LA ZONE", zoneData.label or "Non défini", nil, zoneData.label and "check" or "chevron", false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrer le label de la zone (nom affiché)")

        if not label or label == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Zones Sécurisées',
                message = "Ce label n'est pas valide"
          })
        end

        zoneData.label = label
        safeRefresh(StaffMenu.CreateZoneSafe)
    end)

    StaffMenu.CreateZoneSafe.Separator("POINTS DU CONTOUR (" .. #zoneData.points .. "/3 min)")

    StaffMenu.CreateZoneSafe.Button(" ZONE CIRCULAIRE (RAYON)", "Crée un cercle autour de toi", nil, "chevron", false, function()
        local rangeInput <const> = VFW.Nui.KeyboardInput(true, "Entrer le rayon de la zone (ex: 10)")
        local radius <const> = tonumber(rangeInput)

        if not radius or radius <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Zones Sécurisées',
                message = "Ce rayon n'est pas valide"
          })
        end

        local playerCoords <const> = GetEntityCoords(PlayerPedId())
        local numPoints <const> = 24

        zoneData.points = {}

        for i = 0, numPoints - 1 do
            local angle <const> = (i / numPoints) * 2 * math.pi
            zoneData.points[#zoneData.points + 1] = {
                x = playerCoords.x + math.cos(angle) * radius,
                y = playerCoords.y + math.sin(angle) * radius,
                z = playerCoords.z
            }
        end

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Zones Sécurisées',
            message = "Zone circulaire de " .. radius .. "m créée"
      })

        if not isMarkersActive then
            startMarkerThread()
        end

        safeRefresh(StaffMenu.CreateZoneSafe)
    end)

    StaffMenu.CreateZoneSafe.Button(":plus: AJOUTER UN POINT", "Mode custom - point par point", nil, "chevron", false, function()
        local playerCoords <const> = GetEntityCoords(PlayerPedId())

        zoneData.points[#zoneData.points + 1] = {
            x = playerCoords.x,
            y = playerCoords.y,
            z = playerCoords.z
        }

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Zones Sécurisées',
            message = "Point " .. #zoneData.points .. " ajouté"
      })

        if not isMarkersActive then
            startMarkerThread()
        end

        safeRefresh(StaffMenu.CreateZoneSafe)
    end)

    if #zoneData.points > 0 then
        StaffMenu.CreateZoneSafe.Button(":back: SUPPRIMER DERNIER POINT", "Retire le point " .. #zoneData.points, nil, "trash", false, function()
            table.remove(zoneData.points)

            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Zones Sécurisées',
                message = "Dernier point supprimé"
          })

            if #zoneData.points == 0 then
                stopMarkerThread()
            end

            safeRefresh(StaffMenu.CreateZoneSafe)
        end)

        StaffMenu.CreateZoneSafe.Button(":trash: EFFACER TOUS LES POINTS", "Supprime les " .. #zoneData.points .. " points", nil, "trash", false, function()
            zoneData.points = {}
            stopMarkerThread()

            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Zones Sécurisées',
                message = "Tous les points supprimés"
          })

            safeRefresh(StaffMenu.CreateZoneSafe)
        end)
    end

    StaffMenu.CreateZoneSafe.Separator("CONFIGURATION")

    StaffMenu.CreateZoneSafe.Button(":ruler: HAUTEUR", tostring(zoneData.height) .. "m", nil, "check", false, function()
        local heightInput <const> = VFW.Nui.KeyboardInput(true, "Entrer la hauteur de la zone (ex: 10)")
        local height <const> = tonumber(heightInput)

        if not height or height <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Zones Sécurisées',
                message = "Cette hauteur n'est pas valide"
          })
        end

        zoneData.height = height

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Zones Sécurisées',
            message = "Hauteur définie à " .. height .. "m"
      })

        safeRefresh(StaffMenu.CreateZoneSafe)
    end)

    StaffMenu.CreateZoneSafe.Button("DÉSACTIVER DES ACTIONS", "Choisir les actions interdites dans cette zone (saut, sprint, bagarre...)", nil, zoneData.actionDisabled and #zoneData.actionDisabled > 0 and "check" or "chevron", false, function()
        isNavigating = true
    end, StaffMenu.DisableActionsZoneSafe)

    StaffMenu.CreateZoneSafe.Button("JOBS BYPASS", "Définir les jobs autorisés à effectuer des actions malgré la zone safe", nil, zoneData.bypassJob and #zoneData.bypassJob > 0 and "check" or "chevron", false, function()
        isNavigating = true
    end, StaffMenu.ByPassJobZoneSafe)

    StaffMenu.CreateZoneSafe.Separator(nil)

    if not zoneData.isUpdate then
        local isValid = checkValidFormatZoneData()
        local statusText = ""
      if not zoneData.name then
            statusText = "Nom requis"
      elseif not zoneData.label then
            statusText = "Label requis"
      elseif #zoneData.points < 3 then
            statusText = "Minimum 3 points (" .. #zoneData.points .. "/3)"
      elseif not zoneData.actionDisabled or #zoneData.actionDisabled == 0 then
            statusText = "Actions désactivées requises"
      else
            statusText = "Prêt à créer"
      end

        StaffMenu.CreateZoneSafe.Button(":check: CRÉER LA ZONE", statusText, nil, isValid and "check" or "chevron", not isValid, function()
            TriggerServerEvent('zonesafe:server:create', zoneData.name, zoneData.label, zoneData.points, zoneData.height, zoneData.actionDisabled, zoneData.bypassJob)
            stopMarkerThread()
            resetZoneData()
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Zones Sécurisées',
                message = "Zone safe créée"
          })
            isNavigating = true
            StaffMenu.CreateZoneSafe.close()
            StaffMenu.CreateZoneSafe.parent.open()
        end)

        StaffMenu.CreateZoneSafe.Button(":x: ANNULER", nil, nil, "chevron", false, function()
            stopMarkerThread()
            resetZoneData()
            StaffMenu.CreateZoneSafe.close()
        end)
    end
end

function StaffMenu.BuildListDisableActionsZoneSafe()
    if not zoneData.actionDisabled then
        zoneData.actionDisabled = {}
    end

    for i = 1, #controlDisabled do
        local currentControl <const> = controlDisabled[i]
        local isDisabled <const>, indices <const> = getIsDisableControl(currentControl.control)

        StaffMenu.DisableActionsZoneSafe.Button(currentControl.label, nil, nil, isDisabled and "check" or "chevron", false, function()
            if isDisabled and indices then
                table.sort(indices, function(a, b) return a > b end)
                for _, idx in ipairs(indices) do
                    table.remove(zoneData.actionDisabled, idx)
                end
            else
                if type(currentControl.control) == "table" then
                    for _, ctrl in ipairs(currentControl.control) do
                        zoneData.actionDisabled[#zoneData.actionDisabled + 1] = ctrl
                    end
                else
                    zoneData.actionDisabled[#zoneData.actionDisabled + 1] = currentControl.control
                end
            end

            saveZoneIfUpdate()
            safeRefresh(StaffMenu.DisableActionsZoneSafe)
        end)
    end

    StaffMenu.DisableActionsZoneSafe.Separator(nil)
end

function StaffMenu.BuildListZoneSafeMenu()
    if not ZoneSafe.cache or #ZoneSafe.cache == 0 then
        StaffMenu.ListZoneSafe.Separator("AUCUNE ZONE SAFE")
        return
    end

    for i = 1, #ZoneSafe.cache do
        local safeZone <const> = ZoneSafe.cache[i]
        local pointsCount = safeZone.points and #safeZone.points or 0

        StaffMenu.ListZoneSafe.Button(safeZone.label, safeZone.name .. " | " .. pointsCount .. " points", nil, "chevron", false, function()
            isNavigating = true
            zoneData = {
                name = safeZone.name,
                label = safeZone.label,
                points = safeZone.points or {},
                height = safeZone.height or 10.0,
                actionDisabled = safeZone.actionDisabled or {},
                bypassJob = safeZone.bypassJob or {},
                isUpdate = true,
                oldName = safeZone.name
            }
            startMarkerThread()
        end, StaffMenu.ManageZoneSafe)
    end
end

function StaffMenu.BuildManageZoneSafeMenu()
    StaffMenu.ManageZoneSafe.Button(":target: TELEPORTATION", "Se téléporter au centre de la zone", nil, "chevron", false, function()
        if not zoneData.points or #zoneData.points == 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Zones Sécurisées',
                message = "Aucun point défini"
          })
        end

        local center = ZoneSafe:GetPolygonCenter(zoneData.points)
        SetEntityCoords(PlayerPedId(), center.x, center.y, center.z + 1.0, false, false, false, false)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Zones Sécurisées',
            message = "Téléporté au centre de la zone"
      })
    end)

    StaffMenu.ManageZoneSafe.Button(":monitor: MODIFIER LA ZONE", "Éditer les paramètres, les points et les accès de cette zone safe", nil, "chevron", false, function()
        isNavigating = true
        zoneData.oldName = zoneData.name
        zoneData.isUpdate = true
        startMarkerThread()
    end, StaffMenu.CreateZoneSafe)

    StaffMenu.ManageZoneSafe.Button(":trash: SUPPRIMER LA ZONE", "Supprimer définitivement cette zone safe du serveur", nil, "trash", false, function()
        TriggerServerEvent('zonesafe:server:delete', zoneData.name)
        stopMarkerThread()
        resetZoneData()

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Zones Sécurisées',
            message = "Zone safe supprimée"
      })

        isNavigating = true
        StaffMenu.ManageZoneSafe.close()
        StaffMenu.ManageZoneSafe.parent.open()
    end)
end

function StaffMenu.BuildByPassJobZoneSafeMenu()
    if not zoneData.bypassJob then
        zoneData.bypassJob = {}
    end

    if #zoneData.bypassJob > 0 then
        StaffMenu.ByPassJobZoneSafe.Separator("JOBS ACTUELS")

        for i = 1, #zoneData.bypassJob do
            local job <const> = zoneData.bypassJob[i]

            StaffMenu.ByPassJobZoneSafe.Button(job, "Cliquer pour retirer", nil, "trash", false, function()
                table.remove(zoneData.bypassJob, i)
                saveZoneIfUpdate()
                safeRefresh(StaffMenu.ByPassJobZoneSafe)
            end)
        end
    end

    StaffMenu.ByPassJobZoneSafe.Separator("AJOUTER UN JOB")

    local jobsList = TriggerServerCallback("vfw:staff:getJobs") or {}

    for _, v in pairs(jobsList) do
        local jobName = v.name
        local jobLabel = v.label or "Inconnu"

      if not checkAlreadyExistsJob(jobName) then
            StaffMenu.ByPassJobZoneSafe.Button(jobLabel, jobName, nil, "chevron", false, function()
                zoneData.bypassJob[#zoneData.bypassJob + 1] = jobName
                saveZoneIfUpdate()
                safeRefresh(StaffMenu.ByPassJobZoneSafe)
            end)
        end
    end
end

local function autoSaveZone()
    if zoneData.isUpdate and zoneData.oldName and zoneData.name then
        TriggerServerEvent('zonesafe:server:update', zoneData.oldName, zoneData.name, zoneData.label, zoneData.points, zoneData.height, zoneData.actionDisabled, zoneData.bypassJob)
    end
end

StaffMenu.CreateZoneSafe.OnClose(function()
    if not isRefreshing and not isNavigating then
        stopMarkerThread()
        resetZoneData()
    elseif zoneData.isUpdate then
        autoSaveZone()
    end
    isNavigating = false
end)

StaffMenu.ManageZoneSafe.OnClose(function()
    if not isRefreshing and not isNavigating then
        autoSaveZone()
        stopMarkerThread()
        resetZoneData()
    end
    isNavigating = false
end)

StaffMenu.DisableActionsZoneSafe.OnClose(function()
    isNavigating = false
end)

StaffMenu.ByPassJobZoneSafe.OnClose(function()
    isNavigating = false
end)

StaffMenu.ListZoneSafe.OnClose(function()
    isNavigating = false
end)
