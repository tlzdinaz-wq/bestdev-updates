-- Builder PNJ — admin UI to configure VFW.PNJ spawn lines.

local LinesCache       = nil
local selectedLineId   = nil
local selectedLine     = nil
local drawingLineId    = nil
local lastTestNetId    = nil

local function fcRefresh(menu)
    if menu.opened then menu.refresh() end
end

local function fmtCoord(c)
    if not c then return "?" end
    return string.format("%.1f, %.1f, %.1f", c.x, c.y, c.z)
end

local function lineLength(line)
    local a, b = line.pointA, line.pointB
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

local function LoadLines()
    LinesCache = TriggerServerCallback('vfw:pnj:builder:getLines') or {}
    return LinesCache
end

local function refreshSelectedFromCache()
    if not selectedLineId or not LinesCache then return end
    for _, l in ipairs(LinesCache) do
        if l.id == selectedLineId then
            selectedLine = l
            return
        end
    end
    selectedLine = nil
end

local showAllLines = false

-- ==================== INTELLIGENT CAPTURE MODE ====================
-- Walk, press E to mark A, walk to the end, press E to mark B.
-- Trust the admin: no material check, breadcrumb trail of waypoints.

local captureActive   = false
local capturePointA   = nil
local captureWaypoints = {} -- breadcrumb trail between A and current pos
local captureLastPos  = nil

local WAYPOINT_MIN_DIST = 1.5 -- meters between sampled waypoints

-- Map blips management (one blip per line midpoint, only during capture mode)
local captureBlips = {} ---@type number[]

local function clearCaptureBlips()
    for _, h in ipairs(captureBlips) do
        if DoesBlipExist(h) then RemoveBlip(h) end
    end
    captureBlips = {}
end

local function refreshCaptureBlips()
    clearCaptureBlips()
    if not LinesCache then return end
    for _, line in ipairs(LinesCache) do
        local a, b = line.pointA, line.pointB
        local mx = (a.x + b.x) * 0.5
        local my = (a.y + b.y) * 0.5
        local mz = (a.z + b.z) * 0.5
        local blip = AddBlipForCoord(mx, my, mz)
        SetBlipSprite(blip, 280)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 5) -- yellow
        SetBlipAsShortRange(blip, false) -- visible across the whole map
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("PNJ: " .. (line.id or "?"))
        EndTextCommandSetBlipName(blip)
        captureBlips[#captureBlips + 1] = blip
    end
end

local function drawText3D(x, y, z, text, r, g, b)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.4, 0.4)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(r or 255, g or 255, b or 255, 230)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0, "STRING")
    ClearDrawOrigin()
end

local function stopCapture(silent)
    captureActive = false
    capturePointA = nil
    captureWaypoints = {}
    captureLastPos = nil
    clearCaptureBlips()
    if not silent then
        VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'PNJ Builder', message = "Mode capture désactivé." })
    end
end

local function resetCaptureRound()
    capturePointA = nil
    captureWaypoints = {}
    captureLastPos = nil
end

local function finalizeCapture()
    local pa = capturePointA
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local pb = { x = p.x, y = p.y, z = p.z }

    local dist = #(vector3(pa.x, pa.y, pa.z) - vector3(pb.x, pb.y, pb.z))
    if dist < 1.0 then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'PNJ Builder', message = string.format("Ligne trop courte (%.1fm). Marche plus.", dist) })
        return
    end

    local result = TriggerServerCallback('vfw:pnj:builder:autoCreateLine', pa, pb)
    if result and result.success then
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'PNJ Builder', message = string.format("Ligne '%s' créée (%.1fm).", result.id, dist) })
        LoadLines()
        if captureActive then refreshCaptureBlips() end
        resetCaptureRound()
    else
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'PNJ Builder', message = result and result.error or "Erreur création." })
    end
end

local function onCaptureKey()
    if not captureActive then return end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)

    if not capturePointA then
        capturePointA = { x = pos.x, y = pos.y, z = pos.z }
        captureWaypoints = {}
        captureLastPos = { x = pos.x, y = pos.y, z = pos.z }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'PNJ Builder', message = ":pin: Point A posé. Marche jusqu'au bout puis [E]." })
    else
        finalizeCapture()
    end
end

RegisterCommand("+pnjCapture", function()
    onCaptureKey()
end, false)
RegisterCommand("-pnjCapture", function() end, false)
RegisterKeyMapping("+pnjCapture", "PNJ Builder: poser point capture", "keyboard", "E")

CreateThread(function()
    while true do
        if captureActive then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)

            if capturePointA then
                local last = captureLastPos or capturePointA
                local d = #(vector3(pos.x, pos.y, pos.z) - vector3(last.x, last.y, last.z))
                if d >= WAYPOINT_MIN_DIST then
                    captureWaypoints[#captureWaypoints + 1] = { x = pos.x, y = pos.y, z = pos.z }
                    captureLastPos = { x = pos.x, y = pos.y, z = pos.z }
                end

                -- Draw A marker
                DrawMarker(28, capturePointA.x, capturePointA.y, capturePointA.z, 0,0,0, 0,0,0, 0.45,0.45,0.45, 0, 255, 100, 220, false, true, 2, false, nil, nil, false)

                -- Breadcrumb trail (small orange markers + connecting lines)
                local prev = capturePointA
                for _, wp in ipairs(captureWaypoints) do
                    DrawLine(prev.x, prev.y, prev.z + 0.4, wp.x, wp.y, wp.z + 0.4, 255, 200, 0, 220)
                    DrawMarker(28, wp.x, wp.y, wp.z, 0,0,0, 0,0,0, 0.18,0.18,0.18, 255, 200, 0, 180, false, true, 2, false, nil, nil, false)
                    prev = wp
                end
                -- Last segment to current player pos (live)
                DrawLine(prev.x, prev.y, prev.z + 0.4, pos.x, pos.y, pos.z + 0.4, 0, 255, 100, 220)

                local totalDist = #(vector3(capturePointA.x, capturePointA.y, capturePointA.z) - vector3(pos.x, pos.y, pos.z))
                drawText3D(pos.x, pos.y, pos.z + 1.2, string.format(" [E] POSER POINT B  (%.1fm)", totalDist), 0, 255, 100)
            else
                drawText3D(pos.x, pos.y, pos.z + 1.2, " [E] POSER POINT A", 0, 255, 100)
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

local function drawSingleLine(line, rA, gA, bA, rB, gB, bB)
    local a, b = line.pointA, line.pointB
    DrawLine(a.x, a.y, a.z + 0.5, b.x, b.y, b.z + 0.5, rA, gA, bA, 200)
    DrawMarker(28, a.x, a.y, a.z, 0,0,0, 0,0,0, 0.35,0.35,0.35, rA, gA, bA, 180, false, true, 2, false, nil, nil, false)
    DrawMarker(28, b.x, b.y, b.z, 0,0,0, 0,0,0, 0.35,0.35,0.35, rB, gB, bB, 180, false, true, 2, false, nil, nil, false)
end

-- Visualisation 3D : ligne sélectionnée (vert) + toutes les lignes si toggle global ou capture active (jaune)
CreateThread(function()
    while true do
        local forceAll = showAllLines or captureActive
        if (forceAll or drawingLineId) and LinesCache then
            if forceAll then
                for _, line in ipairs(LinesCache) do
                    if line.id == drawingLineId then
                        drawSingleLine(line, 0, 255, 100, 255, 120, 0)
                    else
                        drawSingleLine(line, 255, 220, 0, 255, 160, 0)
                    end
                end
            elseif drawingLineId then
                for _, line in ipairs(LinesCache) do
                    if line.id == drawingLineId then
                        drawSingleLine(line, 0, 255, 100, 255, 120, 0)
                        break
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ==================== MAIN MENU ====================

function StaffMenu.BuildPNJMenu()
    StaffMenu.builderPNJ.ClearItems()
    if not LinesCache then LoadLines() end

    StaffMenu.builderPNJ.Separator("LIGNES DE SPAWN PNJ")

    StaffMenu.builderPNJ.Checkbox(
        ":eye: VOIR LES TRACÉS",
        showAllLines and "Toutes les lignes sont affichées (jaune)" or "Affiche toutes les lignes simultanément",
        false, showAllLines,
        function(checked)
            showAllLines = checked and true or false
        end
    )

    StaffMenu.builderPNJ.Separator("CAPTURE INTELLIGENTE")

    StaffMenu.builderPNJ.Button(
        captureActive and "⏹ ARRÊTER LA CAPTURE" or " MODE CAPTURE MARCHE",
        captureActive
            and "Capture active. [E] = poser un point. Bouton = arrêter."
          or "Marche sur le trottoir, [E] pour poser A puis B. ID auto.",
        nil, captureActive and "stop" or "play", false,
        function()
            if captureActive then
                stopCapture(false)
            else
                captureActive = true
                capturePointA = nil
                captureLastPos = nil
                captureWaypoints = {}
                LoadLines()
                refreshCaptureBlips()
                VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'PNJ Builder', message = "Mode capture activé. Appuie sur [E] sur un trottoir." })
                StaffMenu.builderPNJ.close()
            end
            fcRefresh(StaffMenu.builderPNJ)
        end
    )

    StaffMenu.builderPNJ.Separator("MANUEL")

    StaffMenu.builderPNJ.Button(
        "+ CRÉER UNE LIGNE",
        "Crée une ligne à ta position (A et B au même endroit, à éditer ensuite)",
        nil, "plus", false,
        function()
            local id = VFW.Nui.KeyboardInput(true, "ID de la ligne (ex: trottoir_grove_01)")
            if not id or id == "" then return end

            local coords = GetEntityCoords(PlayerPedId())
            local pos = { x = coords.x, y = coords.y, z = coords.z }

            local result = TriggerServerCallback('vfw:pnj:builder:createLine', id, pos, pos)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'PNJ Builder', message = "Ligne '" .. id .. "' créée. Pense à déplacer le point B." })
                LoadLines()
                fcRefresh(StaffMenu.builderPNJ)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'PNJ Builder', message = result and result.error or "Erreur." })
            end
        end
    )

    if LinesCache and #LinesCache > 0 then
        StaffMenu.builderPNJ.Separator("LIGNES EXISTANTES (" .. #LinesCache .. ")")
        for _, line in ipairs(LinesCache) do
            local dist = lineLength(line)
            local desc = string.format("Longueur: %.1fm", dist)
            StaffMenu.builderPNJ.Button(
                line.id, desc, nil, "chevron", false,
                function()
                    selectedLineId = line.id
                    selectedLine = line
                end,
                StaffMenu.builderPNJManage
            )
        end
    end
end

-- ==================== MANAGE MENU ====================

function StaffMenu.BuildPNJManageMenu()
    StaffMenu.builderPNJManage.ClearItems()
    if not selectedLine then return end
    local line = selectedLine

    StaffMenu.builderPNJManage.Separator(line.id)

    local isShown = drawingLineId == line.id
    StaffMenu.builderPNJManage.Checkbox(
        ":eye: AFFICHER LA LIGNE",
        isShown and "Cette ligne est actuellement affichée (vert/orange)" or "Affiche cette ligne en 3D dans le monde",
        false, isShown,
        function(checked)
            if checked then
                drawingLineId = line.id
            elseif drawingLineId == line.id then
                drawingLineId = nil
            end
        end
    )

    StaffMenu.builderPNJManage.Button(
        ":dot-green: POINT A",
        fmtCoord(line.pointA) .. " (clic = définir à ta position)",
        nil, "edit", false,
        function()
            local pc = GetEntityCoords(PlayerPedId())
            local result = TriggerServerCallback('vfw:pnj:builder:updatePoint', line.id, "a", { x = pc.x, y = pc.y, z = pc.z })
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'PNJ Builder', message = "Point A mis à jour." })
                LoadLines()
                refreshSelectedFromCache()
                fcRefresh(StaffMenu.builderPNJManage)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'PNJ Builder', message = result and result.error or "Erreur." })
            end
        end
    )

    StaffMenu.builderPNJManage.Button(
        ":dot-orange: POINT B",
        fmtCoord(line.pointB) .. " (clic = définir à ta position)",
        nil, "edit", false,
        function()
            local pc = GetEntityCoords(PlayerPedId())
            local result = TriggerServerCallback('vfw:pnj:builder:updatePoint', line.id, "b", { x = pc.x, y = pc.y, z = pc.z })
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'PNJ Builder', message = "Point B mis à jour." })
                LoadLines()
                refreshSelectedFromCache()
                fcRefresh(StaffMenu.builderPNJManage)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'PNJ Builder', message = result and result.error or "Erreur." })
            end
        end
    )

    StaffMenu.builderPNJManage.Separator("TEST")

    StaffMenu.builderPNJManage.Button(
        ":flask: SPAWN UN PNJ TEST",
        "Spawn un PNJ statique sur la ligne (despawn auto du précédent)",
        nil, "play", false,
        function()
            local model = VFW.Nui.KeyboardInput(true, "Modèle (ex: a_m_y_business_01)")
            if not model or model == "" then model = "a_m_y_business_01" end
            local result = TriggerServerCallback('vfw:pnj:builder:testSpawn', line.id, model)
            if result and result.success then
                lastTestNetId = result.netId
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'PNJ Builder', message = "PNJ test spawné (netId " .. tostring(result.netId) .. ")." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'PNJ Builder', message = result and result.error or "Erreur." })
            end
        end
    )

    StaffMenu.builderPNJManage.Button(
        ":x: DESPAWN PNJ TEST",
        "Supprime le PNJ test en cours",
        nil, "trash", false,
        function()
            TriggerServerCallback('vfw:pnj:builder:despawnTest')
            lastTestNetId = nil
            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'PNJ Builder', message = "PNJ test despawné." })
        end
    )

    StaffMenu.builderPNJManage.Separator("DANGER")

    StaffMenu.builderPNJManage.Button(
        ":trash: SUPPRIMER LA LIGNE",
        "Suppression définitive (irréversible)",
        nil, "trash", false,
        function()
            local result = TriggerServerCallback('vfw:pnj:builder:deleteLine', line.id)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'PNJ Builder', message = "Ligne supprimée." })
                LoadLines()
                if drawingLineId == selectedLineId then drawingLineId = nil end
                selectedLineId = nil
                selectedLine = nil
                Citizen.SetTimeout(50, function()
                    StaffMenu.builderPNJManage.close()
                    StaffMenu.builderPNJ.open()
                end)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'PNJ Builder', message = result and result.error or "Erreur." })
            end
        end
    )
end

-- ==================== HOOKS ====================

StaffMenu.builderPNJ.OnOpen(function()
    LoadLines()
    StaffMenu.BuildPNJMenu()
end)

StaffMenu.builderPNJManage.OnOpen(function()
    refreshSelectedFromCache()
    StaffMenu.BuildPNJManageMenu()
end)
