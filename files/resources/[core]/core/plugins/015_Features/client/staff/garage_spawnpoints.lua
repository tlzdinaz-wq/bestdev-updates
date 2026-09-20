---@meta _
---@diagnostic disable: duplicate-doc-field

-- Garage SpawnPoints Builder Tool
-- Place, mirror, and array vehicle spawn points for garage configs
-- Accessible from Staff Menu > Dev > Gérer les images > SpawnPoints Builder

local GSP = {
    active = false,
    points = {},           -- { vector4, ... }
    previewVehicles = {},  -- entity handles for preview
    model = "adder",       -- default preview vehicle model
    moveSpeed = 0.02,      -- movement speed
    rotSpeed = 1.0,        -- rotation speed
    currentIndex = 0,      -- currently selected point (0 = none, placing new)
    placingNew = false,
    placingEntity = nil,
}

-- ── Helpers ──

local function v4(x, y, z, w)
    return vector4(x, y, z, w)
end

local function formatVec4(v)
    return string.format("vector4(%.2f, %.2f, %.2f, %.2f)", v.x, v.y, v.z, v.w)
end

local function spawnPreviewVehicle(pos, model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 50
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 1
    end
    if not HasModelLoaded(hash) then return nil end

    local veh = CreateVehicle(hash, pos.x, pos.y, pos.z, pos.w or 0.0, false, false)
    SetEntityAlpha(veh, 200, false)
    SetEntityCollision(veh, false, false)
    FreezeEntityPosition(veh, true)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleOnGroundProperly(veh)
    SetModelAsNoLongerNeeded(hash)
    return veh
end

local function deletePreviewVehicles()
    for _, veh in pairs(GSP.previewVehicles) do
        if DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
    end
    GSP.previewVehicles = {}
end

local function refreshPreviews()
    deletePreviewVehicles()
    for i, pt in ipairs(GSP.points) do
        local veh = spawnPreviewVehicle(pt, GSP.model)
        if veh then
            GSP.previewVehicles[i] = veh
            -- Highlight selected
            if i == GSP.currentIndex then
                SetEntityAlpha(veh, 255, false)
            else
                SetEntityAlpha(veh, 150, false)
            end
        end
    end
end

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z + 1.2)
    if onScreen then
        SetTextScale(0.0, 0.30)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

local function drawHUD()
    local lines = {
        "~b~[SpawnPoints Builder]",
        "",
        "~w~E ~s~= Placer un point",
        "~w~BACKSPACE ~s~= Supprimer sélectionné",
        "~w~LEFT/RIGHT ~s~= Naviguer points",
        "",
        "~y~Fleches ~s~= Déplacer (+ SHIFT = rapide)",
        "~y~SCROLL ~s~= Tourner le véhicule",
        "",
        "~g~M ~s~= Mirror latéral (côté)",
        "~g~N ~s~= Mirror longitudinal (avant/arrière)",
        "~g~G ~s~= Array (répéter sur le côté)",
        "",
        "~o~TAB ~s~= Changer modèle véhicule",
        "~r~ENTER ~s~= Exporter config",
        "~r~F5 ~s~= Quitter",
        "",
        string.format("~w~Points: ~b~%d ~w~| Sélectionné: ~b~%s", #GSP.points, GSP.currentIndex > 0 and tostring(GSP.currentIndex) or "aucun"),
    }

    local y = 0.02
    for _, line in ipairs(lines) do
        SetTextFont(4)
        SetTextProportional(true)
        SetTextScale(0.0, 0.28)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(line)
        DrawText(0.01, y)
        y = y + 0.018
    end
end

-- ── Core functions ──

local function addPoint(pos)
    GSP.points[#GSP.points + 1] = v4(pos.x, pos.y, pos.z, pos.w or 0.0)
    GSP.currentIndex = #GSP.points
    refreshPreviews()
end

local function removePoint(index)
    if index < 1 or index > #GSP.points then return end
    table.remove(GSP.points, index)
    if GSP.currentIndex > #GSP.points then
        GSP.currentIndex = #GSP.points
    end
    refreshPreviews()
end

local function movePoint(index, dx, dy, dz)
    if index < 1 or index > #GSP.points then return end
    local pt = GSP.points[index]
    GSP.points[index] = v4(pt.x + dx, pt.y + dy, pt.z + dz, pt.w)

    local veh = GSP.previewVehicles[index]
    if veh and DoesEntityExist(veh) then
        SetEntityCoords(veh, GSP.points[index].x, GSP.points[index].y, GSP.points[index].z)
    end
end

local function rotatePoint(index, delta)
    if index < 1 or index > #GSP.points then return end
    local pt = GSP.points[index]
    local newW = (pt.w + delta) % 360.0
    GSP.points[index] = v4(pt.x, pt.y, pt.z, newW)

    local veh = GSP.previewVehicles[index]
    if veh and DoesEntityExist(veh) then
        SetEntityHeading(veh, newW)
    end
end

-- ── Mirror ──
-- Duplique tous les points en les décalant sur un axe relatif au heading
-- lateral = true  → décalage sur le côté (perpendiculaire au heading)
-- lateral = false → décalage en avant/arrière (dans le sens du heading)

local function mirrorPoints(lateral)
    local existing = #GSP.points
    if existing == 0 then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'SpawnPoints', message = "Aucun point à mirorer." })
        return
    end

    local axeLabel = lateral and "latéral (côté)" or "longitudinal (avant/arrière)"
  local distInput = VFW.Nui.KeyboardInput(true, "Distance mirror " .. axeLabel .. " (metres)", "8.0")
    if not distInput or distInput == "" then return end
    local dist = tonumber(distInput)
    if not dist or dist == 0 then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'SpawnPoints', message = "Cette distance n'est pas valide." })
        return
    end

    local newPoints = {}
    for _, pt in ipairs(GSP.points) do
        local headingRad = math.rad(pt.w)
        local mx, my, mw

        if lateral then
            -- Décalage perpendiculaire au heading (côté)
            local rightX = -math.cos(headingRad)
            local rightY = math.sin(headingRad)
            mx = pt.x + rightX * dist
            my = pt.y + rightY * dist
            -- Heading inversé (véhicule fait face à l'opposé)
            mw = (pt.w + 180.0) % 360.0
        else
            -- Décalage dans le sens du heading (avant/arrière)
            local fwdX = -math.sin(headingRad)
            local fwdY = math.cos(headingRad)
            mx = pt.x + fwdX * dist
            my = pt.y + fwdY * dist
            -- Même heading
            mw = pt.w
        end

        newPoints[#newPoints + 1] = v4(mx, my, pt.z, mw)
    end

    for _, np in ipairs(newPoints) do
        GSP.points[#GSP.points + 1] = np
    end

    GSP.currentIndex = #GSP.points
    refreshPreviews()

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'SpawnPoints',
        message = string.format("Mirror %s (%.1fm) : %d points ajoutés (%d total).", axeLabel, dist, #newPoints, #GSP.points)
    })
end

-- ── Array ──
-- Duplicate selected point N times with consistent offset

local function arrayPoints()
    if GSP.currentIndex < 1 or GSP.currentIndex > #GSP.points then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'SpawnPoints', message = "Sélectionnez d'abord un point." })
        return
    end

    local countInput = VFW.Nui.KeyboardInput(true, "Nombre de copies", "3")
    if not countInput or countInput == "" then return end
    local count = tonumber(countInput)
    if not count or count < 1 or count > 50 then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'SpawnPoints', message = "Ce nombre n'est pas valide (1-50)." })
        return
    end

    local spacingInput = VFW.Nui.KeyboardInput(true, "Espacement lateral (metres)", "4.0")
    local spacing = tonumber(spacingInput) or 4.0

    local base = GSP.points[GSP.currentIndex]

    -- Calculer la direction "côté droit" du véhicule (perpendiculaire au heading)
    local headingRad = math.rad(base.w)
    -- Heading FiveM : 0 = nord, 90 = ouest → côté droit = heading + 90°
    local rightX = -math.cos(headingRad)
    local rightY = math.sin(headingRad)

    for i = 1, count do
        GSP.points[#GSP.points + 1] = v4(
            base.x + rightX * spacing * i,
            base.y + rightY * spacing * i,
            base.z,
            base.w
        )
    end

    GSP.currentIndex = #GSP.points
    refreshPreviews()

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'SpawnPoints',
        message = string.format("Array : %d points ajoutés (%d total).", count, #GSP.points)
    })
end

-- ── Export ──

local function exportConfig()
    if #GSP.points == 0 then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'SpawnPoints', message = "Aucun point à exporter." })
        return
    end

    local lines = { "spawnPoints = {" }
    for _, pt in ipairs(GSP.points) do
        lines[#lines + 1] = "  " .. formatVec4(pt) .. ","
  end
    lines[#lines + 1] = "},"

  local output = table.concat(lines, "\n")
    VFW.Clipboard(output)

    -- Also print to F8
    print("^2[SpawnPoints Builder] Config exportée:^0")
    print(output)

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'SpawnPoints',
        message = string.format("%d points copiés dans le presse-papier.", #GSP.points)
    })
end

-- ── Main loop ──

local function startBuilder()
    if GSP.active then return end
    GSP.active = true
    GSP.points = {}
    GSP.previewVehicles = {}
    GSP.currentIndex = 0

    -- Charger l'intérieur à la position du joueur
    local playerCoords = GetEntityCoords(PlayerPedId())
    local interiorId = GetInteriorAtCoords(playerCoords.x, playerCoords.y, playerCoords.z)
    if interiorId ~= 0 then
        PinInteriorInMemory(interiorId)
        Wait(500)
    end

    -- Forcer le chargement de la collision
    RequestCollisionAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
    Wait(200)

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'SpawnPoints',
        message = "Builder activé. Appuyez sur E pour placer un point."
  })

    CreateThread(function()
        while GSP.active do
            Wait(0)
            drawHUD()

            -- Draw markers on all points
            for i, pt in ipairs(GSP.points) do
                local r, g, b = 100, 100, 255
                if i == GSP.currentIndex then r, g, b = 0, 255, 100 end
                DrawMarker(25, pt.x, pt.y, pt.z - 0.5, 0, 0, 0, 0, 0, 0, 0.6, 0.6, 0.3, r, g, b, 120, false, true, 2, false, nil, nil, false)
                drawText3D(vector3(pt.x, pt.y, pt.z), string.format("#%d  %.0f°", i, pt.w))
            end


            local fast = IsControlPressed(0, 21) -- SHIFT
            local speed = fast and GSP.moveSpeed * 4 or GSP.moveSpeed

            -- E = Place new point at player pos
            if VFW.Interact.JustPressed(0, 38) then
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                addPoint(v4(coords.x, coords.y, coords.z, heading))
                VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'SpawnPoints', message = "Point #" .. #GSP.points .. " placé." })
            end

            -- BACKSPACE = Delete selected
            if IsControlJustPressed(0, 177) and GSP.currentIndex > 0 then
                removePoint(GSP.currentIndex)
                VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'SpawnPoints', message = "Point supprimé." })
            end

            -- LEFT/RIGHT = Navigate
            if IsControlJustPressed(0, 174) then -- LEFT
                if GSP.currentIndex > 1 then
                    GSP.currentIndex = GSP.currentIndex - 1
                    refreshPreviews()
                end
            end
            if IsControlJustPressed(0, 175) then -- RIGHT
                if GSP.currentIndex < #GSP.points then
                    GSP.currentIndex = GSP.currentIndex + 1
                    refreshPreviews()
                end
            end

            -- Arrow keys = Move selected point
            if GSP.currentIndex > 0 then
                local camHeading = GetGameplayCamRelativeHeading()
                local camRot = math.rad(camHeading)

                if IsControlPressed(0, 172) then -- UP
                    movePoint(GSP.currentIndex, -math.sin(camRot) * speed, math.cos(camRot) * speed, 0)
                end
                if IsControlPressed(0, 173) then -- DOWN
                    movePoint(GSP.currentIndex, math.sin(camRot) * speed, -math.cos(camRot) * speed, 0)
                end
                if IsControlPressed(0, 174) and IsControlPressed(0, 21) then -- SHIFT+LEFT
                    movePoint(GSP.currentIndex, math.cos(camRot) * speed, math.sin(camRot) * speed, 0)
                end
                if IsControlPressed(0, 175) and IsControlPressed(0, 21) then -- SHIFT+RIGHT
                    movePoint(GSP.currentIndex, -math.cos(camRot) * speed, -math.sin(camRot) * speed, 0)
                end

                -- SCROLL = Rotate
                if IsControlPressed(0, 241) then -- SCROLL UP
                    rotatePoint(GSP.currentIndex, GSP.rotSpeed)
                end
                if IsControlPressed(0, 242) then -- SCROLL DOWN
                    rotatePoint(GSP.currentIndex, -GSP.rotSpeed)
                end
            end

            -- M = Mirror Y
            if IsControlJustPressed(0, 244) then
                mirrorPoints(true)
            end

            -- N = Mirror X
            if IsControlJustPressed(0, 249) then
                mirrorPoints(false)
            end

            -- G = Array
            if IsControlJustPressed(0, 47) then
                arrayPoints()
            end

            -- TAB = Change model
            if IsControlJustPressed(0, 37) then
                local input = VFW.Nui.KeyboardInput(true, "Modèle du véhicule", GSP.model)
                if input and input ~= "" then
                    local hash = GetHashKey(input)
                    if IsModelAVehicle(hash) then
                        GSP.model = input
                        refreshPreviews()
                        VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'SpawnPoints', message = "Modèle changé : " .. input })
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'SpawnPoints', message = "Ce modèle n'est pas valide." })
                    end
                end
            end

            -- ENTER = Export
            if IsControlJustPressed(0, 191) then
                exportConfig()
            end

            -- F5 = Quit
            if IsControlJustPressed(0, 166) then
                GSP.active = false
            end

            -- Disable conflicting controls
            DisableControlAction(0, 44, true) -- Q (cover)
        end

        -- Cleanup
        deletePreviewVehicles()
        GSP.points = {}
        GSP.currentIndex = 0

        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'SpawnPoints',
            message = "Builder fermé."
      })
    end)
end

-- ── Expose to staff menu ──

function StaffMenu.OpenGarageSpawnPointsBuilder()
    if GSP.active then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'SpawnPoints', message = "Le builder est déjà actif." })
        return
    end

    StaffMenu.main.close()
    Wait(200)
    startBuilder()
end
