-- Utilitaires pour détection automatique du sol et gestion des cercles

local function GetGroundZ(x, y, z)
    -- Méthode 1: GetGroundZFor_3dCoord
    local found1, groundZ1 = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 500.0, false)

    -- Méthode 2: Raycast vers le bas
    local startCoord = vector3(x, y, z + 50.0)
    local endCoord = vector3(x, y, z - 50.0)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        startCoord.x, startCoord.y, startCoord.z,
        endCoord.x, endCoord.y, endCoord.z,
        1, -- Geometry (sol)
        0, false
    )
    local retval, hit, endCoords = GetShapeTestResult(rayHandle)

    -- Méthode 3: Essayer plusieurs points autour
    local samples = {}
    if found1 then table.insert(samples, groundZ1) end
    if hit then table.insert(samples, endCoords.z) end

    -- Test quelques points autour pour avoir une moyenne
    for i = 1, 4 do
        local angle = (i - 1) * 90
        local offsetX = math.cos(math.rad(angle)) * 0.5
        local offsetY = math.sin(math.rad(angle)) * 0.5
        local found, gz = GetGroundZFor_3dCoord(x + offsetX, y + offsetY, z + 500.0, false)
        if found then
            table.insert(samples, gz)
        end
    end

    if #samples > 0 then
        -- Calculer la médiane pour éviter les valeurs aberrantes
        table.sort(samples)
        local median = samples[math.ceil(#samples / 2)]
        return median
    else
        -- Fallback: utiliser Z original
        return z
    end
end

-- Fonction pour créer un cercle avec Z automatique corrigé
function CreateInteractionCircleWithGroundZ(coords, radius, color, label, action, options)
    local bestZ = coords.z
    local candidates = {}

    -- Méthode 1: GetGroundZFor_3dCoord à différentes hauteurs
    for heightOffset = 0, 50, 10 do
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + heightOffset, false)
        if found then
            table.insert(candidates, groundZ)
        end
    end

    -- Méthode 2: Raycast vers le bas depuis plus haut
    local rayStart = vector3(coords.x, coords.y, coords.z + 100.0)
    local rayEnd = vector3(coords.x, coords.y, coords.z - 20.0)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        rayStart.x, rayStart.y, rayStart.z,
        rayEnd.x, rayEnd.y, rayEnd.z,
        1, -- Geometry (sol)
        0, false
    )
    local retval, hit, hitCoords = GetShapeTestResult(rayHandle)
    if hit then
        table.insert(candidates, hitCoords.z)
    end

    -- Méthode 3: Raycast vers le haut depuis plus bas
    local rayStart2 = vector3(coords.x, coords.y, coords.z - 20.0)
    local rayEnd2 = vector3(coords.x, coords.y, coords.z + 100.0)
    local rayHandle2 = StartExpensiveSynchronousShapeTestLosProbe(
        rayStart2.x, rayStart2.y, rayStart2.z,
        rayEnd2.x, rayEnd2.y, rayEnd2.z,
        1, -- Geometry (sol)
        0, false
    )
    local retval2, hit2, hitCoords2 = GetShapeTestResult(rayHandle2)
    if hit2 then
        table.insert(candidates, hitCoords2.z)
    end

    if #candidates > 0 then
        -- Trier pour trouver le plus proche du Z original mais pas trop loin
        table.sort(candidates, function(a, b)
            return math.abs(a - coords.z) < math.abs(b - coords.z)
        end)

        local bestCandidate = candidates[1]

        -- Si trop loin, utiliser Z original
        if math.abs(bestCandidate - coords.z) > 10.0 then
            bestZ = coords.z
        else
            bestZ = bestCandidate
        end
    else
    end

    -- Ajouter un petit offset pour être au-dessus
    local finalZ = bestZ + 0.5

    local correctedCoords = vector3(coords.x, coords.y, finalZ)
    return CreateInteractionCircle(correctedCoords, radius, color, label, action, options)
end

-- Fonction pour auto-cleanup des cercles qui ne marchent pas
local cleanupTimers = {}

function CreateManagedInteractionCircle(coords, radius, color, label, action, options)
    local circleId = CreateInteractionCircle(coords, radius, color, label, action, options)

    -- Auto-cleanup après 5 minutes si pas utilisé
    if circleId then
        cleanupTimers[circleId] = GetGameTimer()
    end

    return circleId
end

function RemoveManagedInteractionCircle(circleId)
    if circleId then
        cleanupTimers[circleId] = nil
        RemoveInteractionCircle(circleId)
    end
end

-- Thread pour auto-cleanup
CreateThread(function()
    while true do
        Wait(30000) -- Check toutes les 30s
        local now = GetGameTimer()

        for circleId, createdAt in pairs(cleanupTimers) do
            if now - createdAt > 300000 then
                RemoveInteractionCircle(circleId)
                cleanupTimers[circleId] = nil
            end
        end
    end
end)