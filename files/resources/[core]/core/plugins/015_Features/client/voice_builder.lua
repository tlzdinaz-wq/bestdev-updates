local VoiceBuilder = {
    active = false,
    mode = nil,
    previewZone = nil,
    markers = {}
}

local function drawZonePreview(coords, radius, zoneType)
    local color
    if zoneType == "amplifier" then
        color = {100, 255, 100, 100}
    else
        color = {255, 100, 100, 100}
    end

    DrawMarker(
        28,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        radius * 2, radius * 2, radius * 2,
        color[1], color[2], color[3], color[4],
        false, true, 2, false, nil, nil, false
    )

    local points = 32
    for i = 0, points do
        local angle = (i / points) * 2 * math.pi
        local nextAngle = ((i + 1) / points) * 2 * math.pi

        local x1 = coords.x + math.cos(angle) * radius
        local y1 = coords.y + math.sin(angle) * radius

        local x2 = coords.x + math.cos(nextAngle) * radius
        local y2 = coords.y + math.sin(nextAngle) * radius

        DrawLine(
            x1, y1, coords.z,
            x2, y2, coords.z,
            color[1], color[2], color[3], 255
        )
    end
end

local function draw3DText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function HasVoiceBuilderPermission()
    local perms = VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions
    if not perms then
        return false
    end

    return perms["staff"] == true or perms["admin"] == true
end

local function startBuilder(builderType)
    VoiceBuilder.active = true
    VoiceBuilder.mode = builderType

    VFW.ShowNotification({
        type = 'JAUNE',
        content = string.format("Mode builder %s active", builderType == "amplifier" and "amplificateur" or "restriction")
    })

    VFW.ShowNotification({
        type = 'JAUNE',
        content = "Utilisez [E] pour placer, [RETOUR] pour annuler"
    })

    CreateThread(function()
        local radius = 10.0
        local amplification = 2.0

        while VoiceBuilder.active do
            Wait(0)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            drawZonePreview(coords, radius, "amplifier")

            local instructions = string.format("Zone Amplificatrice\nRayon: %.1fm | Amplification: x%.1f\n[up/down] Rayon | [left/right] Amplification\n[E] Placer | [RETOUR] Annuler",
                radius, amplification)

            draw3DText(coords, instructions)

            if IsControlPressed(0, 172) then
                radius = math.min(radius + 0.5, 100.0)
                Wait(100)
            elseif IsControlPressed(0, 173) then
                radius = math.max(radius - 0.5, 1.0)
                Wait(100)
            end

            if IsControlPressed(0, 174) then
                amplification = math.max(amplification - 0.1, 1.0)
                Wait(100)
            elseif IsControlPressed(0, 175) then
                amplification = math.min(amplification + 0.1, 5.0)
                Wait(100)
            end

            if VFW.Interact.JustPressed(0, 51) then
                TriggerServerEvent('voiceSystem:addAmplifierZone', coords, radius, amplification)
                VFW.ShowNotification({
                    type = 'VERT',
                    content = string.format("Zone amplificatrice créée (%.1fm, x%.1f)", radius, amplification)
                })

                VoiceBuilder.active = false
                VoiceBuilder.mode = nil
            end

            if IsControlJustPressed(0, 177) then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Mode builder annule"
                })
                VoiceBuilder.active = false
                VoiceBuilder.mode = nil
            end
        end
    end)
end

RegisterCommand('voiceBuilderAmplifier', function()
    if not HasVoiceBuilderPermission() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'avez pas la permission"
        })
        return
    end

    if VoiceBuilder.active then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Un builder est déjà actif"
        })
        return
    end

    startBuilder("amplifier")
end, false)

RegisterCommand('voiceShowZones', function()
    if not HasVoiceBuilderPermission() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'avez pas la permission"
        })
        return
    end

    CreateThread(function()
        local showZones = true
        local lastRequest = 0

        VFW.ShowNotification({
            type = 'JAUNE',
            content = "Affichage des zones vocales active [RETOUR pour fermer]"
        })

        while showZones do
            Wait(0)

            if GetGameTimer() - lastRequest >= 5000 then
                lastRequest = GetGameTimer()
                TriggerServerEvent('voiceSystem:requestZones')
            end

            if IsControlJustPressed(0, 177) then
                showZones = false
                VFW.ShowNotification({
                    type = 'JAUNE',
                    content = "Affichage des zones désactivé"
                })
            end
        end
    end)
end, false)

RegisterNetEvent('voiceSystem:drawZones')
AddEventHandler('voiceSystem:drawZones', function(amplifierZones, restrictionZones)
    CreateThread(function()
        local startTime = GetGameTimer()

        while GetGameTimer() - startTime < 10000 do
            Wait(0)

            for _, zone in ipairs(amplifierZones or {}) do
                drawZonePreview(zone.coords, zone.radius, "amplifier")

                local text = string.format("Amplificateur #%d\nx%.1f", zone.id, zone.amplification)
                draw3DText(zone.coords, text)
            end
        end
    end)
end)

RegisterCommand('voiceHelp', function()
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {
            "Systeme Vocal",
            "F11 - Changer de mode vocal\n" ..
            "\nAdmin:\n" ..
            "/voiceBuilderAmplifier - Creer zone amplificatrice\n" ..
            "/voiceShowZones - Afficher toutes les zones"
        }
    })
end, false)
