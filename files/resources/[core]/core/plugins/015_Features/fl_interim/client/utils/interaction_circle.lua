local interactionCircles = {}
local uniqueIdCounter = 0

function CreateInteractionCircle(coords, radius, color, interactLabel, onInteract, options)
    options = options or {}
    uniqueIdCounter = uniqueIdCounter + 1

    local circleData = {
        id = uniqueIdCounter,
        coords = coords,
        radius = radius or 1.5,
        color = color or {r = 255, g = 255, b = 255, a = 100},
        label = interactLabel,
        action = onInteract,
        enabled = true,
        showHelp = options.showHelp ~= false,
        inputKey = options.inputKey or 38,
        height = options.height or 0.0,
        heightRange = options.heightRange or nil
    }

    table.insert(interactionCircles, circleData)
    return circleData.id
end

function RemoveInteractionCircle(circleId)
    for i = #interactionCircles, 1, -1 do
        if interactionCircles[i].id == circleId then
            table.remove(interactionCircles, i)
            return true
        end
    end
    return false
end

function SetInteractionCircleEnabled(circleId, enabled)
    for i, circle in pairs(interactionCircles) do
        if circle.id == circleId then
            circle.enabled = enabled
            return true
        end
    end
    return false
end

local function DrawCircle3D(x, y, z, radius, color)
    DrawMarker(
            1, -- Type 1 = Cylindre
            x, y, z,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            radius * 2.0, radius * 2.0, 0.5, -- Scale X, Y, Z
            color.r, color.g, color.b, color.a,
            false, true, 2, false, nil, nil, false
    )
end

local lastHelpNotif = 0
local lastCircleId = nil
local keyMustBeReleased = false

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        local closestCircle = nil
        local minDistance = 9999.0

        for i = 1, #interactionCircles do
            local circle = interactionCircles[i]

            if circle.enabled then
                local dist
                local isInRange = false

                if circle.heightRange then
                    local dist2D = #(vector2(pCoords.x, pCoords.y) - vector2(circle.coords.x, circle.coords.y))
                    local heightDiff = math.abs(pCoords.z - circle.coords.z)
                    dist = dist2D
                    isInRange = dist2D <= circle.radius and heightDiff <= circle.heightRange
                else
                    dist = #(pCoords - vector3(circle.coords.x, circle.coords.y, circle.coords.z))
                    isInRange = dist <= circle.radius
                end

                --if dist < circle.radius + 30.0 then
                --    sleep = 0
                --    DrawCircle3D(circle.coords.x, circle.coords.y, circle.coords.z + circle.height, circle.radius, circle.color)
                --end

                if isInRange and dist < minDistance then
                    minDistance = dist
                    closestCircle = circle
                end
            end
        end

        if closestCircle then
            sleep = 0

            local isNewCircle = lastCircleId ~= closestCircle.id
            if isNewCircle then
                lastCircleId = closestCircle.id
                lastHelpNotif = 0
                if IsControlPressed(0, closestCircle.inputKey) then
                    keyMustBeReleased = true
                end
            end

            if closestCircle.showHelp and closestCircle.label then
                local now = GetGameTimer()
                if isNewCircle or now - lastHelpNotif > 800 then
                    VFW.ShowHelpNotification(closestCircle.label)
                    lastHelpNotif = now
                end
            end

            if keyMustBeReleased then
                if not IsControlPressed(0, closestCircle.inputKey) then
                    keyMustBeReleased = false
                end
            elseif IsControlJustPressed(0, closestCircle.inputKey) and closestCircle.action then
                keyMustBeReleased = true
                closestCircle.action()
            end
        elseif lastCircleId then
            lastCircleId = nil
            lastHelpNotif = 0
            keyMustBeReleased = false
        end

        Wait(sleep)
    end
end)

function GetAllInteractionCircles()
    return interactionCircles
end

function ClearAllInteractionCircles()
    interactionCircles = {}
end