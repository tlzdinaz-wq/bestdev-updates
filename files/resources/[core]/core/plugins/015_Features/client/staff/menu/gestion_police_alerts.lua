---@meta _
---@diagnostic disable: duplicate-doc-field

local drawing = false

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["manage_police_zones"] == true
end

local function CirclePolygon(cx, cy, radius, steps)
    local poly = {}
    local n = steps or 16
    for i = 0, n - 1 do
        local a = (i / n) * math.pi * 2
        poly[#poly + 1] = { x = cx + math.cos(a) * radius, y = cy + math.sin(a) * radius }
    end
    return poly
end

local function Centroid(polygon)
    if type(polygon) ~= "table" or #polygon == 0 then return nil end
    local sx, sy = 0.0, 0.0
    for i = 1, #polygon do
        sx = sx + (tonumber(polygon[i].x) or 0.0)
        sy = sy + (tonumber(polygon[i].y) or 0.0)
    end
    return sx / #polygon, sy / #polygon
end

local function Payload()
    local res = TriggerServerCallback("policeAlertZones:getPanel")
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger les zones d'alertes police." }
    end
    local coords = GetEntityCoords(PlayerPedId())
    res.player = { x = coords.x + 0.0, y = coords.y + 0.0 }
    return res
end

local function SyncPanel()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return end
    SendNUIMessage({ action = "gestion:policeAlerts:sync", data = Payload() })
end

local function TeleportTo(x, y)
    local ped = PlayerPedId()
    SetEntityCoords(ped, x, y, 300.0, false, false, false, false)
    Wait(400)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, 300.0, false)
    if found then
        SetEntityCoords(ped, x, y, groundZ + 1.0, false, false, false, false)
    else
        SetEntityCoords(ped, x, y, 30.0, false, false, false, false)
    end
end

local function DrawWorldPolygon()
    local points = {}
    drawing = true
    VFW.ShowNotification({
        type = "STAFF", variant = "INFO", subtitle = "Zones police",
        message = "[E] point · [Backspace] annuler · [Entrée] valider · [ESC] quitter",
    })

    while drawing do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        DisableControlAction(0, 199, true)
        DisableControlAction(0, 200, true)

        for i, pt in ipairs(points) do
            DrawMarker(28, pt.x, pt.y, pt.z + 0.5, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 114, 99, 238, 200, false, false, 2, false, nil, nil, false)
            if i > 1 then
                local prev = points[i - 1]
                DrawLine(prev.x, prev.y, prev.z + 0.3, pt.x, pt.y, pt.z + 0.3, 114, 99, 238, 200)
            end
        end
        if #points >= 3 then
            local first, last = points[1], points[#points]
            DrawLine(last.x, last.y, last.z + 0.3, first.x, first.y, first.z + 0.3, 114, 99, 238, 100)
        end

        VFW.ShowHelpNotification("~INPUT_CONTEXT~ Point | ~INPUT_CELLPHONE_CANCEL~ Annuler | ~INPUT_FRONTEND_ACCEPT~ Valider | ~INPUT_FRONTEND_CANCEL~ Quitter")

        if (VFW.Interact and VFW.Interact.JustPressed(0, 38)) or IsControlJustPressed(0, 38) then
            points[#points + 1] = { x = coords.x, y = coords.y, z = coords.z }
            VFW.ShowNotification({ type = "STAFF", variant = "INFO", subtitle = "Zones police", message = "Point " .. #points .. " ajouté." })
        end
        if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) then
            if #points > 0 then
                points[#points] = nil
                VFW.ShowNotification({ type = "STAFF", variant = "INFO", subtitle = "Zones police", message = "Point retiré." })
            end
        end
        if IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
            if #points >= 3 then
                drawing = false
            else
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Zones police", message = "Minimum 3 points." })
            end
        end
        if IsControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 200) or IsControlJustPressed(0, 322) then
            points = {}
            drawing = false
        end
        Wait(0)
    end

    if #points < 3 then return nil end
    local polygon = {}
    for i = 1, #points do
        polygon[i] = { x = points[i].x, y = points[i].y }
    end
    return polygon
end

RegisterNuiCallback("gestion:policeAlerts:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les zones d'alertes police." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:policeAlerts:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Payload())
end)

RegisterNuiCallback("gestion:policeAlerts:create", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if type(data) ~= "table" then cb({ ok = false, error = "Données invalides." }) return end
    local name = type(data.name) == "string" and data.name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if name == "" then
        cb({ ok = false, error = "Indique un nom de zone." })
        return
    end
    local polygon = data.polygon
    if type(polygon) ~= "table" or #polygon < 3 then
        local radius = tonumber(data.radius)
        if not radius or radius < 20 or radius > 8000 then
            cb({ ok = false, error = "Dessine un polygone (3 points) ou indique un rayon entre 20 et 8000 m." })
            return
        end
        local coords = GetEntityCoords(PlayerPedId())
        polygon = CirclePolygon(coords.x, coords.y, radius, 24)
    end
    local result = TriggerServerCallback("policeAlertZones:create", {
        name = name,
        polygon = polygon,
        assigned_jobs = data.assigned_jobs or {},
    })
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and (result.error or result.message)) or "Impossible de créer la zone." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Zones police", message = "Zone '" .. name .. "' créée." })
    cb(Payload())
end)

RegisterNuiCallback("gestion:policeAlerts:update", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if type(data) ~= "table" or data.zoneId == nil then
        cb({ ok = false, error = "Zone invalide." })
        return
    end
    local result = TriggerServerCallback("policeAlertZones:update", {
        id = data.zoneId,
        name = data.name,
        assigned_jobs = data.assigned_jobs,
        polygon = data.polygon,
    })
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and (result.error or result.message)) or "Mise à jour impossible." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:policeAlerts:delete", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if not data or data.zoneId == nil then
        cb({ ok = false, error = "Zone invalide." })
        return
    end
    local result = TriggerServerCallback("policeAlertZones:delete", { id = data.zoneId })
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and (result.error or result.message)) or "Suppression impossible." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Zones police", message = "Zone supprimée." })
    cb(Payload())
end)

RegisterNuiCallback("gestion:policeAlerts:teleport", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = Payload()
    local id = data and tonumber(data.zoneId)
    for i = 1, #(payload.zones or {}) do
        local z = payload.zones[i]
        if tonumber(z.id) == id then
            local x, y = Centroid(z.polygon)
            if x and y then
                TeleportTo(x, y)
                VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Zones police", message = "Téléporté sur " .. tostring(z.name) .. "." })
                payload.player = { x = x, y = y }
            end
            cb(payload)
            return
        end
    end
    cb({ ok = false, error = "Zone introuvable." })
end)

RegisterNuiCallback("gestion:policeAlerts:simulate", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local alertTypeId = data and data.alertTypeId
    if type(alertTypeId) ~= "string" or alertTypeId == "" then
        cb({ ok = false, error = "Choisis un type d'alerte." })
        return
    end
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent("policeAlertZones:simulateAlert", alertTypeId, coords.x, coords.y, coords.z)
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Zones police", message = "Alerte simulée à ta position." })
    cb(Payload())
end)

RegisterNuiCallback("gestion:policeAlerts:drawWorld", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if drawing then
        cb({ ok = false, error = "Un dessin est déjà en cours." })
        return
    end
    cb({ ok = true, drawing = true })
    CreateThread(function()
        StaffMenu.CoverGestionHub()
        VFW.Nui.Focus(false)
        local polygon = DrawWorldPolygon()
        if polygon then
            local name = type(data) == "table" and type(data.name) == "string" and data.name:gsub("^%s+", ""):gsub("%s+$", "") or ""
            if name == "" then
                name = VFW.Nui.KeyboardInput(true, "Nom de la zone") or ""
                name = name:gsub("^%s+", ""):gsub("%s+$", "")
            end
            if name ~= "" then
                local result = TriggerServerCallback("policeAlertZones:create", {
                    name = name,
                    polygon = polygon,
                    assigned_jobs = (type(data) == "table" and data.assigned_jobs) or {},
                })
                if type(result) == "table" and result.ok == true then
                    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Zones police", message = "Zone '" .. name .. "' créée." })
                else
                    VFW.ShowNotification({
                        type = "STAFF", variant = "ERROR", subtitle = "Zones police",
                        message = (type(result) == "table" and (result.message or result.error)) or "Création impossible.",
                    })
                end
            end
        end
        StaffMenu.UncoverGestionHub()
        SyncPanel()
    end)
end)
