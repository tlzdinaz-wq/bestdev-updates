-- ============================================================
-- POLICE ALERT ZONES - Client Tablet
-- Opens the NUI tablet for managing police alert zones
-- ============================================================

local isTabletOpen = false
local isDrawingPolygon = false
local drawingPoints = {}

-- ============================================================
-- TABLET OPEN / CLOSE
-- ============================================================

local function OpenPoliceAlertZonesTablet()
    if isTabletOpen then return end

    local pg = VFW.PlayerGlobalData
    if not pg or not pg.permissions then return end
    if not pg.permissions["manage_police_zones"] then
        VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Zones Police", message = "Pas la permission" })
        return
    end

    isTabletOpen = true

    local zones = TriggerServerCallback("policeAlertZones:getAll") or {}
    local policeJobs = TriggerServerCallback("policeAlertZones:getPoliceJobs") or {}

    SendNUIMessage({
        action = "nui:policeAlertZones:open",
        data = {
            zones = zones,
            policeJobs = policeJobs,
        }
    })

    VFW.Nui.Focus(true)
end

local function ClosePoliceAlertZonesTablet()
    if not isTabletOpen then return end
    isTabletOpen = false

    SendNUIMessage({ action = "nui:policeAlertZones:close" })
    VFW.Nui.Focus(false)
end

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback("policeAlertZones:close", function(_, cb)
    ClosePoliceAlertZonesTablet()
    cb({})
end)

RegisterNUICallback("policeAlertZones:refreshData", function(_, cb)
    local zones = TriggerServerCallback("policeAlertZones:getAll") or {}
    local policeJobs = TriggerServerCallback("policeAlertZones:getPoliceJobs") or {}
    cb({ zones = zones, policeJobs = policeJobs })
end)

RegisterNUICallback("policeAlertZones:startDrawing", function(_, cb)
    cb({})
    ClosePoliceAlertZonesTablet()

    VFW.ShowNotification({ type = "STAFF", variant = "INFO", subtitle = "Zone", message = "[E] point, [Backspace] annuler, [Entrée] valider, [ESC] quitter" })

    drawingPoints = {}
    isDrawingPolygon = true

    CreateThread(function()
        while isDrawingPolygon do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Draw points and lines
            for i, pt in ipairs(drawingPoints) do
                DrawMarker(28, pt.x, pt.y, pt.z + 0.5, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 114, 99, 238, 200, false, false, 2, false, nil, nil, false)
                if i > 1 then
                    local prev = drawingPoints[i - 1]
                    DrawLine(prev.x, prev.y, prev.z + 0.3, pt.x, pt.y, pt.z + 0.3, 114, 99, 238, 200)
                end
            end

            if #drawingPoints >= 3 then
                local first = drawingPoints[1]
                local last = drawingPoints[#drawingPoints]
                DrawLine(last.x, last.y, last.z + 0.3, first.x, first.y, first.z + 0.3, 114, 99, 238, 100)
            end

            VFW.ShowHelpNotification("~INPUT_CONTEXT~ Point | ~INPUT_CELLPHONE_CANCEL~ Annuler | ~INPUT_FRONTEND_ACCEPT~ Valider | ~INPUT_FRONTEND_CANCEL~ Quitter")

            -- E = add point
            if VFW.Interact.JustPressed(0, 38) then
                drawingPoints[#drawingPoints + 1] = { x = coords.x, y = coords.y, z = coords.z }
                VFW.ShowNotification({ type = "STAFF", variant = "INFO", subtitle = "Zone", message = "Point " .. #drawingPoints .. " ajouté" })
            end

            -- Backspace = undo
            if IsControlJustPressed(0, 177) then
                if #drawingPoints > 0 then
                    drawingPoints[#drawingPoints] = nil
                    VFW.ShowNotification({ type = "STAFF", variant = "INFO", subtitle = "Zone", message = "Point supprimé" })
                end
            end

            -- Enter = confirm
            if IsControlJustPressed(0, 201) then
                if #drawingPoints >= 3 then
                    isDrawingPolygon = false
                else
                    VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Zone", message = "Minimum 3 points" })
                end
            end

            -- ESC = cancel
            if IsControlJustPressed(0, 200) then
                drawingPoints = {}
                isDrawingPolygon = false
            end

            Wait(0)
        end

        -- After drawing
        if #drawingPoints >= 3 then
            local name = VFW.Nui.KeyboardInput(true, "Nom de la zone")
            if name and name ~= "" then
                local polygon = {}
                for _, pt in ipairs(drawingPoints) do
                    polygon[#polygon + 1] = { x = pt.x, y = pt.y }
                end

                local result = TriggerServerCallback("policeAlertZones:create", {
                    name = name,
                    polygon = polygon,
                    assigned_jobs = {},
                })

                if result and result.success then
                    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Zone", message = "Zone '" .. name .. "' créée" })
                else
                    VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Zone", message = result and result.message or "Erreur" })
                end
            end
        end

        drawingPoints = {}
        Wait(300)
        OpenPoliceAlertZonesTablet()
    end)
end)

RegisterNUICallback("policeAlertZones:createFromMap", function(data, cb)
    if not data or not data.name or not data.polygon or #data.polygon < 3 then
        cb({ success = false })
        return
    end
    local result = TriggerServerCallback("policeAlertZones:create", {
        name = data.name,
        polygon = data.polygon,
        assigned_jobs = data.assigned_jobs or {},
    })
    cb(result or { success = false })
end)

RegisterNUICallback("policeAlertZones:deleteZone", function(data, cb)
    local result = TriggerServerCallback("policeAlertZones:delete", data)
    cb(result or {})
end)

RegisterNUICallback("policeAlertZones:updateZone", function(data, cb)
    local result = TriggerServerCallback("policeAlertZones:update", data)
    cb(result or {})
end)

RegisterNUICallback("policeAlertZones:teleport", function(data, cb)
    cb({})
    if not data or not data.id then return end

    local zones = TriggerServerCallback("policeAlertZones:getAll") or {}
    for _, zone in ipairs(zones) do
        if zone.id == data.id and zone.polygon and #zone.polygon >= 1 then
            -- Use first point of the polygon
            local tx, ty = zone.polygon[1].x, zone.polygon[1].y

            -- Find ground Z
            local ped = PlayerPedId()
            SetEntityCoords(ped, tx, ty, 300.0, false, false, false, false)
            Wait(500)
            local found, groundZ = GetGroundZFor_3dCoord(tx, ty, 300.0, false)
            if found then
                SetEntityCoords(ped, tx, ty, groundZ + 1.0, false, false, false, false)
            else
                SetEntityCoords(ped, tx, ty, 30.0, false, false, false, false)
            end
            VFW.ShowNotification({ type = "STAFF", variant = "INFO", subtitle = "Zone", message = "Téléporté au centre de " .. zone.name })
            break
        end
    end
end)

RegisterNUICallback("policeAlertZones:getAlertTypes", function(_, cb)
    local types = TriggerServerCallback("policeAlertZones:getAlertTypes") or {}
    cb(types)
end)

RegisterNUICallback("policeAlertZones:simulateAlert", function(data, cb)
    cb({})
    if not data or not data.alertTypeId then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent("policeAlertZones:simulateAlert", data.alertTypeId, coords.x, coords.y, coords.z)
end)

-- ============================================================
-- EXPORT
-- ============================================================

exports('OpenPoliceAlertZonesTablet', function()
    OpenPoliceAlertZonesTablet()
end)
