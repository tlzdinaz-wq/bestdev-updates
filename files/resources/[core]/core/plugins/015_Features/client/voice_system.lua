local VoiceSystem = {
    modes = {
        [1] = { name = "Chuchoter", range = 3.0, color = {150, 150, 150, 100} },
        [2] = { name = "Parler", range = 8.0, color = {200, 200, 200, 100} },
        [3] = { name = "Parler fort", range = 15.0, color = {255, 200, 100, 100} },
        [4] = { name = "Crier", range = 25.0, color = {255, 100, 100, 100} }
    },
    currentMode = 2,
    isTalking = false,
    showRange = false,
    showRangeTimer = 0,
    amplifierZones = {},
    restrictionZones = {},
    isInAmplifierZone = false,
    isInRestrictionZone = false,
    currentRestrictionZone = nil,
    canBypassRestriction = false,
    wasInRestrictionZone = false
}


local function IsPointInPolygon(points, x, y)
    if not points or #points < 3 then
        return false
    end

    local inZone = false
    local j = #points

    for i = 1, #points do
        local pi = points[i]
        local pj = points[j]

        if pi and pj then
            if ((pi.y < y and pj.y >= y) or (pj.y < y and pi.y >= y)) and (pi.x <= x or pj.x <= x) then
                if pi.x + (y - pi.y) / (pj.y - pi.y) * (pj.x - pi.x) < x then
                    inZone = not inZone
                end
            end
        end

        j = i
    end

    return inZone
end

local function GetPolygonCenter(points)
    if not points or #points == 0 then
        return vector3(0, 0, 0)
    end

    local totalX, totalY, totalZ = 0, 0, 0

    for i = 1, #points do
        local point = points[i]
        totalX = totalX + point.x
        totalY = totalY + point.y
        totalZ = totalZ + (point.z or 0)
    end

    return vector3(totalX / #points, totalY / #points, totalZ / #points)
end

local function GetPolygonRadius(points, center)
    if not points or #points == 0 then
        return 0
    end

    local maxDist = 0

    for i = 1, #points do
        local point = points[i]
        local dist = #(vector2(point.x, point.y) - vector2(center.x, center.y))
        if dist > maxDist then
            maxDist = dist
        end
    end

    return maxDist
end


local function canBypassVoiceRestriction(zone)
    local playerData = VFW.GetPlayerData()
    if not playerData or not playerData.job then return false end

    local bypassJobs = zone and zone.bypassJobs or {}

    if #bypassJobs == 0 then
        return false
    end

    for _, job in ipairs(bypassJobs) do
        if playerData.job.name == job then
            return true
        end
    end

    return false
end


local function checkAmplifierZone()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, zone in ipairs(VoiceSystem.amplifierZones) do
        local zc = zone.coords
        local distance = #(coords - vector3(zc.x, zc.y, zc.z))
        if distance <= zone.radius then
            return true, zone.amplification
        end
    end

    return false, 1.0
end


local function checkRestrictionZone()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local px, py, pz = coords.x, coords.y, coords.z

    for _, zone in ipairs(VoiceSystem.restrictionZones) do
        if zone.points and #zone.points >= 3 then
            if not zone._center then
                zone._center = GetPolygonCenter(zone.points)
                zone._radius = GetPolygonRadius(zone.points, zone._center)
            end

            local distToCenter = #(vector2(px, py) - vector2(zone._center.x, zone._center.y))
            if distToCenter <= zone._radius + 10 then
                if IsPointInPolygon(zone.points, px, py) then
                    local baseZ = zone.points[1].z
                    if baseZ then
                        local height = zone.height or 10.0
                        if pz >= (baseZ - 5.0) and pz <= (baseZ + height + 5.0) then
                            return true, zone.maxMode, zone
                        end
                    else
                        return true, zone.maxMode, zone
                    end
                end
            end
        end
    end

    return false, 4, nil
end


local function getEffectiveRange()
    local baseRange = VoiceSystem.modes[VoiceSystem.currentMode].range
    local range = baseRange

    local inAmplifier, amplification = checkAmplifierZone()
    if inAmplifier then
        range = baseRange * amplification
        VoiceSystem.isInAmplifierZone = true
    else
        VoiceSystem.isInAmplifierZone = false
    end

    return range
end

local isApplyingRestriction = false

local function applyRestriction(requestedMode)
    if requestedMode < 1 or requestedMode > 4 then return end
    if isApplyingRestriction then return end

    local inRestriction, maxMode, zone = checkRestrictionZone()
    VoiceSystem.isInRestrictionZone = inRestriction
    VoiceSystem.currentRestrictionZone = zone
    VoiceSystem.canBypassRestriction = canBypassVoiceRestriction(zone)

    local finalMode = requestedMode

    if inRestriction and not VoiceSystem.canBypassRestriction then
        if requestedMode > maxMode then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Ce mode vocal n'est pas autorisé dans cette zone"
            })
            finalMode = maxMode
        end
    end

    VoiceSystem.currentMode = finalMode

    if finalMode ~= requestedMode then
        isApplyingRestriction = true
        TriggerEvent('pma-voice:forceMode', finalMode)
        isApplyingRestriction = false
    end

    SendNUIMessage({
        action = 'updateVoiceMode',
        data = {
            modeIndex = finalMode,
        }
    })

    VoiceSystem.showRangeTimer = 1.5
end

AddEventHandler("pma-voice:setTalkingMode", function(newMode)
    applyRestriction(newMode)
end)


local function drawRangeCircle()
    if VoiceSystem.showRangeTimer <= 0 and not VoiceSystem.showRange then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local range = getEffectiveRange()

    DrawMarker(
        1,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        range * 2.0, range * 2.0, 0.4,
        0, 120, 255, 150,
        false, false, 2, false, nil, nil, false
    )
end

-- Talking state detection (low frequency, only sends NUI on change)
CreateThread(function()
    local wasTalking = false
    while true do
        Wait(100)
        local talking = NetworkIsPlayerTalking(PlayerId()) == 1
        VoiceSystem.isTalking = talking

        if talking ~= wasTalking then
            wasTalking = talking
            SendNUIMessage({
                action = 'updateVoiceMode',
                data = {
                    isTalking = talking,
                    modeIndex = VoiceSystem.currentMode,
                }
            })
        end
    end
end)

-- Range circle drawing & H key hold (only frame-rate when needed)
CreateThread(function()
    while true do
        local needsDraw = VoiceSystem.showRangeTimer > 0 or VoiceSystem.showRange

        if needsDraw then
            Wait(0)
            if VoiceSystem.showRangeTimer > 0 then
                VoiceSystem.showRangeTimer = VoiceSystem.showRangeTimer - GetFrameTime()
            end
            drawRangeCircle()
        else
            Wait(200)
        end

        local holding = IsControlPressed(0, 74) or IsDisabledControlPressed(0, 74)
        if holding ~= VoiceSystem.showRange then
            VoiceSystem.showRange = holding
        end
    end
end)

CreateThread(function()
    while true do
        Wait(200)

        local inRestriction, maxMode, zone = checkRestrictionZone()
        local bypass = canBypassVoiceRestriction(zone)

        if inRestriction then
            VoiceSystem.isInRestrictionZone = true
            VoiceSystem.currentRestrictionZone = zone

            if not VoiceSystem.wasInRestrictionZone then
                VoiceSystem.wasInRestrictionZone = true

                if not bypass then
                    local modeNamesList = {}
                    for i = 1, maxMode do
                        modeNamesList[#modeNamesList + 1] = VoiceSystem.modes[i].name
                    end

                    VFW.ShowNotification({
                        type = 'ROUGE',
                        content = "Zone restreinte - Modes autorisés: " .. table.concat(modeNamesList, ", ")
                    })
                end
            end

            if not bypass and VoiceSystem.currentMode > maxMode then
                VoiceSystem.currentMode = maxMode
                isApplyingRestriction = true
                TriggerEvent('pma-voice:forceMode', maxMode)
                isApplyingRestriction = false

                SendNUIMessage({
                    action = 'updateVoiceMode',
                    data = {
                        modeIndex = maxMode,
                    }
                })
            end
        else
            if VoiceSystem.wasInRestrictionZone then
                local wasBypassed = VoiceSystem.canBypassRestriction
                VoiceSystem.wasInRestrictionZone = false
                VoiceSystem.isInRestrictionZone = false
                VoiceSystem.currentRestrictionZone = nil
                VoiceSystem.canBypassRestriction = false

                if not wasBypassed then
                    VFW.ShowNotification({
                        type = 'VERT',
                        content = "Zone restreinte quittée, tous les modes vocaux sont disponibles"
                    })
                end
            end
        end
    end
end)


RegisterCommand('voiceAmplifierAdd', function(source, args)
    local perms = VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions
    if not perms or not (perms["staff"] == true or perms["admin"] == true) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'avez pas la permission"
        })
        return
    end

    local radius = tonumber(args[1]) or 10.0
    local amplification = tonumber(args[2]) or 2.0
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    TriggerServerEvent('voiceSystem:addAmplifierZone', coords, radius, amplification)

    VFW.ShowNotification({
        type = 'VERT',
        content = string.format("Zone amplificatrice ajoutée (rayon: %.1fm, amplification: x%.1f)", radius, amplification)
    })
end, false)


RegisterNetEvent('voiceSystem:syncZones')
AddEventHandler('voiceSystem:syncZones', function(amplifierZones, restrictionZones)
    VoiceSystem.amplifierZones = amplifierZones or {}
    VoiceSystem.restrictionZones = restrictionZones or {}

    for _, zone in ipairs(VoiceSystem.restrictionZones) do
        zone._center = nil
        zone._radius = nil
    end
end)


function GetVoiceSystemData()
    return {
        mode = VoiceSystem.modes[VoiceSystem.currentMode].name,
        modeIndex = VoiceSystem.currentMode,
        range = getEffectiveRange(),
        isTalking = VoiceSystem.isTalking,
        isAmplified = VoiceSystem.isInAmplifierZone,
        isRestricted = VoiceSystem.isInRestrictionZone
    }
end

exports('GetVoiceSystemData', GetVoiceSystemData)

function GetVoiceMode()
    return VoiceSystem.currentMode
end

exports('GetVoiceMode', GetVoiceMode)

function GetVoiceRestrictionZones()
    return VoiceSystem.restrictionZones
end

exports('GetVoiceRestrictionZones', GetVoiceRestrictionZones)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('voiceSystem:requestZones')
end)
