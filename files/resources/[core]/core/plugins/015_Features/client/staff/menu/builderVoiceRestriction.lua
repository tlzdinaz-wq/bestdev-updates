local sfind = string.find
local slower = string.lower

local modeNames = {
    [1] = "Chuchoter",
    [2] = "Parler",
    [3] = "Parler fort",
    [4] = "Crier"
}

local bypassSearchText = ""

local zoneData = {
    points = {},
    height = 10.0,
    maxMode = 2,
    bypassJobs = {},
}

local markerThread = nil
local isMarkersActive = false
local isRefreshing = false
local isNavigating = false

local function resetZoneData()
    zoneData = {
        points = {},
        height = 10.0,
        maxMode = 2,
        bypassJobs = {},
    }
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
    if markerThread or not zoneData.points or #zoneData.points == 0 then
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
                        255, 80, 80, 200,
                        false, true, 2, false, nil, nil, false
                    )

                    DrawMarker(
                        28,
                        point.x, point.y, point.z + height - 0.5,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        0.5, 0.5, 0.5,
                        255, 150, 80, 150,
                        false, true, 2, false, nil, nil, false
                    )

                    DrawLine(
                        point.x, point.y, point.z,
                        point.x, point.y, point.z + height,
                        255, 100, 100, 150
                    )

                    local nextPoint = points[i + 1] or points[1]
                    if nextPoint and #points >= 2 then
                        DrawLine(
                            point.x, point.y, point.z,
                            nextPoint.x, nextPoint.y, nextPoint.z,
                            255, 80, 80, 200
                        )

                        DrawLine(
                            point.x, point.y, point.z + height,
                            nextPoint.x, nextPoint.y, nextPoint.z + height,
                            255, 150, 80, 150
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

local function getModesLabel(maxMode)
    local names = {}
    for i = 1, maxMode do
        names[#names + 1] = modeNames[i]
    end
    return table.concat(names, ", ")
end

local function getBypassJobsLabel()
    if #zoneData.bypassJobs == 0 then
        return "Aucun"
  end
    return table.concat(zoneData.bypassJobs, ", ")
end

local function getZoneCenter(points)
    if not points or #points == 0 then return nil end
    local sumX, sumY, sumZ = 0, 0, 0
    for _, p in ipairs(points) do
        sumX = sumX + p.x
        sumY = sumY + p.y
        sumZ = sumZ + p.z
    end
    local count = #points
    return { x = sumX / count, y = sumY / count, z = sumZ / count }
end

function StaffMenu.BuildVoiceRestrictionMenu()
    StaffMenu.builderVoiceRestriction.Button("CRÉER UNE ZONE", nil, nil, "chevron", false, function()
        resetZoneData()
    end, StaffMenu.builderVoiceRestrictionCreate)

    StaffMenu.builderVoiceRestriction.Button("LISTE DES ZONES", nil, nil, "chevron", false, function()
    end, StaffMenu.builderVoiceRestrictionList)
end

function StaffMenu.BuildVoiceRestrictionCreateMenu()
    StaffMenu.builderVoiceRestrictionCreate.Button("MODE VOCAL MAXIMUM", modeNames[zoneData.maxMode], nil, "check", false, function()
        local choices = {}
        for i = 1, 4 do
            choices[#choices + 1] = { label = modeNames[i], value = tostring(i) }
        end

        local result = VFW.Nui.ChoiceInput("Mode vocal maximum", "Les joueurs ne pourront pas dépasser ce mode dans la zone", choices)

        if not result then return end

        local mode = tonumber(result)
        if not mode or mode < 1 or mode > 4 then return end

        zoneData.maxMode = mode

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
            message = "Mode maximum: " .. modeNames[mode]
        })

        safeRefresh(StaffMenu.builderVoiceRestrictionCreate)
    end)

    StaffMenu.builderVoiceRestrictionCreate.Separator("MODES AUTORISÉS: " .. getModesLabel(zoneData.maxMode))

    StaffMenu.builderVoiceRestrictionCreate.Separator("POINTS DU CONTOUR (" .. #zoneData.points .. "/3 min)")

    StaffMenu.builderVoiceRestrictionCreate.Button("ZONE CIRCULAIRE (RAYON)", "Crée un cercle autour de toi", nil, "chevron", false, function()
        local rangeInput = VFW.Nui.KeyboardInput(true, "Entrer le rayon de la zone (ex: 10)")
        local radius = tonumber(rangeInput)

        if not radius or radius <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Restriction Vocale',
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
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
            message = "Zone circulaire de " .. radius .. "m créée"
      })

        if not isMarkersActive then
            startMarkerThread()
        end

        safeRefresh(StaffMenu.builderVoiceRestrictionCreate)
    end)

    StaffMenu.builderVoiceRestrictionCreate.Button("AJOUTER UN POINT", "Mode custom - point par point", nil, "chevron", false, function()
        local playerCoords = GetEntityCoords(PlayerPedId())

        zoneData.points[#zoneData.points + 1] = {
            x = playerCoords.x,
            y = playerCoords.y,
            z = playerCoords.z
        }

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
            message = "Point " .. #zoneData.points .. " ajouté"
      })

        if not isMarkersActive then
            startMarkerThread()
        end

        safeRefresh(StaffMenu.builderVoiceRestrictionCreate)
    end)

    if #zoneData.points > 0 then
        StaffMenu.builderVoiceRestrictionCreate.Button("SUPPRIMER DERNIER POINT", "Retire le point " .. #zoneData.points, nil, "trash", false, function()
            table.remove(zoneData.points)

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
                message = "Dernier point supprimé"
          })

            if #zoneData.points == 0 then
                stopMarkerThread()
            end

            safeRefresh(StaffMenu.builderVoiceRestrictionCreate)
        end)

        StaffMenu.builderVoiceRestrictionCreate.Button("EFFACER TOUS LES POINTS", "Supprime les " .. #zoneData.points .. " points", nil, "trash", false, function()
            zoneData.points = {}
            stopMarkerThread()

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
                message = "Tous les points supprimés"
          })

            safeRefresh(StaffMenu.builderVoiceRestrictionCreate)
        end)
    end

    StaffMenu.builderVoiceRestrictionCreate.Separator("CONFIGURATION")

    StaffMenu.builderVoiceRestrictionCreate.Button("HAUTEUR", tostring(zoneData.height) .. "m", nil, "check", false, function()
        local heightInput = VFW.Nui.KeyboardInput(true, "Entrer la hauteur de la zone (ex: 10)")
        local height = tonumber(heightInput)

        if not height or height <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Restriction Vocale',
                message = "Cette hauteur n'est pas valide"
          })
        end

        zoneData.height = height

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
            message = "Hauteur définie à " .. height .. "m"
      })

        safeRefresh(StaffMenu.builderVoiceRestrictionCreate)
    end)

    StaffMenu.builderVoiceRestrictionCreate.Button("BY-PASS JOBS", #zoneData.bypassJobs .. (#zoneData.bypassJobs > 1 and " jobs - " or " job - ") .. getBypassJobsLabel(), nil, "chevron", false, function()
        isNavigating = true
    end, StaffMenu.builderVoiceRestrictionBypass)

    StaffMenu.builderVoiceRestrictionCreate.Separator(nil)

    if not zoneData.isUpdate then
        local isValid = #zoneData.points >= 3
        local statusText = ""
      if #zoneData.points < 3 then
            statusText = "Minimum 3 points (" .. #zoneData.points .. "/3)"
      else
            statusText = "Prêt à créer (" .. #zoneData.points .. " points)"
      end

        StaffMenu.builderVoiceRestrictionCreate.Button("CRÉER LA ZONE", statusText, nil, isValid and "check" or "chevron", not isValid, function()
            TriggerServerEvent('voiceSystem:addRestrictionZone', zoneData.points, zoneData.height, zoneData.maxMode, zoneData.bypassJobs)
            stopMarkerThread()

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
                message = string.format("Zone créée (%d points, max: %s)", #zoneData.points, modeNames[zoneData.maxMode])
            })

            resetZoneData()
            StaffMenu.builderVoiceRestrictionCreate.close()
            StaffMenu.builderVoiceRestrictionCreate.parent.open()
        end)

        StaffMenu.builderVoiceRestrictionCreate.Button("ANNULER", nil, nil, "chevron", false, function()
            stopMarkerThread()
            resetZoneData()
            StaffMenu.builderVoiceRestrictionCreate.close()
            StaffMenu.builderVoiceRestrictionCreate.parent.open()
        end)
    else
        StaffMenu.builderVoiceRestrictionCreate.Button("SAUVEGARDER", nil, nil, "check", false, function()
            TriggerServerEvent('voiceSystem:updateRestrictionZone', zoneData.id, zoneData.points, zoneData.height, zoneData.maxMode, zoneData.bypassJobs)
            stopMarkerThread()

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
                message = "Zone mise à jour"
          })

            resetZoneData()
            StaffMenu.builderVoiceRestrictionCreate.close()
        end)
    end
end

function StaffMenu.BuildVoiceRestrictionListMenu()
    local zones = TriggerServerCallback("voiceSystem:getRestrictionZones") or {}

    if #zones == 0 then
        StaffMenu.builderVoiceRestrictionList.Separator("AUCUNE ZONE DE RESTRICTION")
        return
    end

    for i = 1, #zones do
        local zone = zones[i]
        local bypassCount = zone.bypassJobs and #zone.bypassJobs or 0
        local pointsCount = zone.points and #zone.points or 0
        local desc = string.format(bypassCount > 1 and "%d points | Max: %s | By-pass: %d jobs" or "%d points | Max: %s | By-pass: %d job", pointsCount, modeNames[zone.maxMode] or "?", bypassCount)

        StaffMenu.builderVoiceRestrictionList.Button("ZONE #" .. zone.id, desc, nil, "chevron", false, function()
            isNavigating = true
            zoneData = {
                id = zone.id,
                points = zone.points or {},
                height = zone.height or 10.0,
                maxMode = zone.maxMode,
                bypassJobs = zone.bypassJobs or {},
                isUpdate = true,
                createdBy = zone.createdBy,
                createdAt = zone.createdAt,
            }
            startMarkerThread()
        end, StaffMenu.builderVoiceRestrictionManage)
    end
end

function StaffMenu.BuildVoiceRestrictionManageMenu()
    StaffMenu.builderVoiceRestrictionManage.Separator("ZONE #" .. (zoneData.id or "?"))

    local pointsCount = zoneData.points and #zoneData.points or 0
    StaffMenu.builderVoiceRestrictionManage.Button("POINTS", pointsCount .. " points", nil, "check", true, function() end)
    StaffMenu.builderVoiceRestrictionManage.Button("HAUTEUR", string.format("%.1fm", zoneData.height or 10.0), nil, "check", true, function() end)
    StaffMenu.builderVoiceRestrictionManage.Button("MODE MAX", modeNames[zoneData.maxMode] or "?", nil, "check", true, function() end)
    StaffMenu.builderVoiceRestrictionManage.Button("BY-PASS", getBypassJobsLabel(), nil, "check", true, function() end)

    if zoneData.createdBy then
        StaffMenu.builderVoiceRestrictionManage.Button("CRÉÉ PAR", zoneData.createdBy .. " | " .. (zoneData.createdAt or ""), nil, nil, true, function() end)
    end

    StaffMenu.builderVoiceRestrictionManage.Separator(nil)

    StaffMenu.builderVoiceRestrictionManage.Button("TÉLÉPORTATION", "Se téléporter au centre de la zone", nil, "chevron", false, function()
        if not zoneData.points or #zoneData.points == 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Restriction Vocale',
                message = "Aucun point défini"
          })
        end

        local center = getZoneCenter(zoneData.points)
        SetEntityCoords(PlayerPedId(), center.x, center.y, center.z + 1.0, false, false, false, false)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
            message = "Téléporté au centre de la zone"
      })
    end)

    StaffMenu.builderVoiceRestrictionManage.Button("MODIFIER LA ZONE", nil, nil, "chevron", false, function()
        isNavigating = true
        zoneData.isUpdate = true
        startMarkerThread()
    end, StaffMenu.builderVoiceRestrictionCreate)

    StaffMenu.builderVoiceRestrictionManage.Button("SUPPRIMER LA ZONE", nil, nil, "trash", false, function()
        TriggerServerEvent('voiceSystem:removeRestrictionZone', zoneData.id)
        stopMarkerThread()

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restriction Vocale',
            message = "Zone supprimée"
      })

        resetZoneData()
        StaffMenu.builderVoiceRestrictionManage.close()
        StaffMenu.builderVoiceRestrictionManage.parent.open()
    end)
end

StaffMenu.builderVoiceRestriction.OnOpen(function()
    StaffMenu.BuildVoiceRestrictionMenu()
end)

StaffMenu.builderVoiceRestrictionCreate.OnOpen(function()
    StaffMenu.BuildVoiceRestrictionCreateMenu()
end)

StaffMenu.builderVoiceRestrictionCreate.OnClose(function()
    if not isRefreshing and not isNavigating then
        if not zoneData.isUpdate then
            stopMarkerThread()
            resetZoneData()
        end
    end
    isNavigating = false
end)

StaffMenu.builderVoiceRestrictionList.OnOpen(function()
    StaffMenu.BuildVoiceRestrictionListMenu()
end)

StaffMenu.builderVoiceRestrictionList.OnClose(function()
    if not isRefreshing and not isNavigating then
        stopMarkerThread()
        resetZoneData()
    end
    isNavigating = false
end)

StaffMenu.builderVoiceRestrictionManage.OnOpen(function()
    StaffMenu.BuildVoiceRestrictionManageMenu()
end)

StaffMenu.builderVoiceRestrictionManage.OnClose(function()
    if not isRefreshing and not isNavigating then
        stopMarkerThread()
        resetZoneData()
    end
    isNavigating = false
end)

function StaffMenu.BuildVoiceRestrictionBypassMenu()
    local jobs = TriggerServerCallback("vfw:staff:getJobs")
    if not jobs then
        StaffMenu.builderVoiceRestrictionBypass.Separator("IMPOSSIBLE DE CHARGER LES JOBS")
        return
    end

    StaffMenu.builderVoiceRestrictionBypass.Button("RECHERCHER UN JOB", bypassSearchText ~= "" and ("Recherche : " .. bypassSearchText) or nil, nil, "search", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rechercher un job", bypassSearchText)
        if input then
            bypassSearchText = input
            safeRefresh(StaffMenu.builderVoiceRestrictionBypass)
        end
    end)

    if bypassSearchText ~= "" then
        StaffMenu.builderVoiceRestrictionBypass.Button("EFFACER LA RECHERCHE", nil, nil, "trash", false, function()
            bypassSearchText = ""
          safeRefresh(StaffMenu.builderVoiceRestrictionBypass)
        end)
    end

    local bypassMap = {}
    for _, bj in ipairs(zoneData.bypassJobs) do
        bypassMap[bj] = true
    end

    local sorted = {}
    for jobName, jobData in pairs(jobs) do
        sorted[#sorted + 1] = { name = jobName, label = jobData.label or jobName }
    end
    table.sort(sorted, function(a, b) return a.label < b.label end)

    local searchLower = bypassSearchText ~= "" and slower(bypassSearchText) or nil

    for _, job in ipairs(sorted) do
        if not searchLower or sfind(slower(job.label), searchLower, 1, true) or sfind(slower(job.name), searchLower, 1, true) then
            local isEnabled = bypassMap[job.name] == true
            local icon = isEnabled and "check" or "empty"
          local desc = isEnabled and "Peut utiliser tous les modes" or "Soumis aux restrictions"

          StaffMenu.builderVoiceRestrictionBypass.Button(job.label, desc, nil, icon, false, function()
                if isEnabled then
                    for i, bj in ipairs(zoneData.bypassJobs) do
                        if bj == job.name then
                            table.remove(zoneData.bypassJobs, i)
                            break
                        end
                    end
                else
                    zoneData.bypassJobs[#zoneData.bypassJobs + 1] = job.name
                end

                safeRefresh(StaffMenu.builderVoiceRestrictionBypass)
            end)
        end
    end
end

StaffMenu.builderVoiceRestrictionBypass.OnOpen(function()
    StaffMenu.BuildVoiceRestrictionBypassMenu()
end)

StaffMenu.builderVoiceRestrictionBypass.OnClose(function()
    if not isRefreshing and not isNavigating then
        bypassSearchText = ""
    end
    isNavigating = false
end)
