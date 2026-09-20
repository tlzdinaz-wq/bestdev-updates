---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- SYSTEME DE VALIDATION TROTTOIR INTELLIGENT
-- Pipeline: Ped Node -> Densite -> Route -> Espace lateral
-- ============================================

local SidewalkValidator = {}

-- Configuration des filtres
local ValidatorConfig = {
    -- Filtre densite: nombre minimum de nodes dans un rayon
    densityRadius = 10.0,       -- Rayon pour compter les nodes
    minNodeDensity = 3,         -- Minimum de nodes pour valider (réduit de 4 à 3)

    -- Filtre proximite route
    maxRoadDistance = 20.0,     -- Distance max a une route vehicule (augmenté)

    -- Filtre largeur (raycast lateral)
    lateralCheckDistance = 3.0, -- Distance du raycast lateral (augmenté)
    minClearance = 1.5,         -- Espace minimum requis des 2 cotes (réduit)

    -- Filtre hauteur
    maxHeightDiff = 5.0,        -- Difference de hauteur max avec le joueur (augmenté)

    -- Filtre pente
    maxSlopeAngle = 15.0,       -- Angle max de pente en degrés

    -- Filtre véhicules
    vehicleCheckRadius = 2.0,   -- Rayon pour vérifier les véhicules

    -- Filtre visibilité
    checkVisibility = true,     -- Vérifier ligne de vue avec joueur

    -- Debug
    debug = false
}

-- ============================================
-- FILTRE 1: DENSITE DE NODES
-- Les trottoirs principaux ont beaucoup de nodes
-- Les ruelles en ont tres peu
-- ============================================
local function CheckNodeDensity(x, y, z)
    local nodeCount = 0
    local checkRadius = ValidatorConfig.densityRadius

    -- Compter les nodes pietons dans un rayon
    -- On utilise GetSafeCoordForPed dans plusieurs directions
    for angle = 0, 315, 45 do -- 8 directions
        local rad = math.rad(angle)
        local testX = x + math.cos(rad) * (checkRadius * 0.7)
        local testY = y + math.sin(rad) * (checkRadius * 0.7)

        local found, _ = GetSafeCoordForPed(testX, testY, z, true, 0)
        if found then
            nodeCount = nodeCount + 1
        end
    end

    local isValid = nodeCount >= ValidatorConfig.minNodeDensity

    --if ValidatorConfig.debug then
        --print(string.format("[SIDEWALK] Density check at %.1f,%.1f: %d nodes (min: %d) -> %s",
            --x, y, nodeCount, ValidatorConfig.minNodeDensity, isValid and "OK" or "FAIL"))
    --end

    return isValid, nodeCount
end

-- ============================================
-- FILTRE 2: PROXIMITE D'UNE ROUTE
-- Un trottoir principal longe une vraie route
-- Une ruelle non
-- ============================================
local function CheckRoadProximity(x, y, z)
    -- Trouver le node vehicule le plus proche
    local found, roadCoords = GetNthClosestVehicleNode(x, y, z, 1, 1, 0, 0)

    if not found or not roadCoords then
        --if ValidatorConfig.debug then
            --print(string.format("[SIDEWALK] Road proximity at %.1f,%.1f: NO ROAD FOUND -> FAIL", x, y))
        --end
        return false, 999
    end

    local distance = #(vector3(x, y, z) - roadCoords)
    local isValid = distance <= ValidatorConfig.maxRoadDistance

    --if ValidatorConfig.debug then
        --print(string.format("[SIDEWALK] Road proximity at %.1f,%.1f: %.1fm (max: %.1f) -> %s",
            --x, y, distance, ValidatorConfig.maxRoadDistance, isValid and "OK" or "FAIL"))
    --end

    return isValid, distance
end

-- ============================================
-- FILTRE 3: ESPACE LATERAL (LARGEUR) - AMELIORE
-- Multi-angle pour meilleure detection des ruelles
-- ============================================
local function CheckLateralSpace(x, y, z, heading)
    local checkDist = ValidatorConfig.lateralCheckDistance
    local checkHeight = z + 1.0 -- Hauteur de verification (niveau poitrine)

    -- Tester plusieurs angles (pas juste perpendiculaire)
    local angles = {0, 45, 90, 135} -- 4 directions
    local clearances = {}
    local blockedCount = 0

    for _, angleOffset in ipairs(angles) do
        local rad = math.rad((heading or 0) + angleOffset)

        local testX = x + math.cos(rad) * checkDist
        local testY = y + math.sin(rad) * checkDist

        -- Raycast avec attente pour résultat fiable
        local handle = StartShapeTestRay(x, y, checkHeight, testX, testY, checkHeight, 1 + 16, 0, 0) -- 1=world, 16=objects
        Citizen.Wait(0) -- Laisser le temps au raycast de se compléter
        local _, hit, endCoords, _, _ = GetShapeTestResult(handle)

        local clearance = checkDist
        if hit then
            clearance = #(vector3(x, y, checkHeight) - endCoords)
            if clearance < ValidatorConfig.minClearance then
                blockedCount = blockedCount + 1
            end
        end
        table.insert(clearances, clearance)
    end

    -- Au moins 3 directions sur 4 doivent être dégagées
    local minSpace = math.min(table.unpack(clearances))
    local isValid = blockedCount <= 1

    --if ValidatorConfig.debug then
        --print(string.format("[SIDEWALK] Lateral space at %.1f,%.1f: min=%.1f blocked=%d/4 -> %s",
            --x, y, minSpace, blockedCount, isValid and "OK" or "FAIL"))
    --end

    return isValid, minSpace
end

-- ============================================
-- FILTRE 6: VERIFICATION DE PENTE
-- Eviter les surfaces trop inclinées
-- ============================================
local function CheckSlope(x, y, z)
    -- Tester plusieurs points autour pour calculer la pente
    local testRadius = 1.0
    local heights = {}

    for angle = 0, 270, 90 do
        local rad = math.rad(angle)
        local testX = x + math.cos(rad) * testRadius
        local testY = y + math.sin(rad) * testRadius
        local found, groundZ = GetGroundZFor_3dCoord(testX, testY, z + 5.0, false)
        if found and groundZ > 0.0 then
            table.insert(heights, groundZ)
        end
    end

    if #heights < 3 then
        return true, 0 -- Pas assez de données, on accepte
    end

    -- Calculer la différence max de hauteur
    local maxH = math.max(table.unpack(heights))
    local minH = math.min(table.unpack(heights))
    local heightDiff = maxH - minH

    -- Convertir en angle approximatif (arctan)
    local slopeAngle = math.deg(math.atan(heightDiff / (testRadius * 2)))
    local isValid = slopeAngle <= ValidatorConfig.maxSlopeAngle

    --if ValidatorConfig.debug and not isValid then
        --print(string.format("[SIDEWALK] Slope check at %.1f,%.1f: %.1f° (max: %.1f°) -> FAIL",
            --x, y, slopeAngle, ValidatorConfig.maxSlopeAngle))
    --end

    return isValid, slopeAngle
end

-- ============================================
-- FILTRE 7: PAS DE VEHICULES GARES
-- ============================================
local function CheckNoVehiclesNearby(x, y, z)
    local radius = ValidatorConfig.vehicleCheckRadius
    local vehicle = GetClosestVehicle(x, y, z, radius, 0, 71) -- 71 = tous types

    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        --if ValidatorConfig.debug then
            --print(string.format("[SIDEWALK] Vehicle check at %.1f,%.1f: VEHICLE FOUND -> FAIL", x, y))
        --end
        return false
    end

    return true
end

-- ============================================
-- FILTRE 8: VISIBILITE DEPUIS LE JOUEUR (optionnel)
-- Eviter spawns derrière des murs
-- ============================================
local function CheckVisibilityFromPlayer(x, y, z, playerCoords)
    if not ValidatorConfig.checkVisibility or not playerCoords then
        return true
    end

    local playerX, playerY, playerZ = playerCoords.x, playerCoords.y, playerCoords.z + 1.0
    local targetZ = z + 1.0

    local handle = StartShapeTestRay(playerX, playerY, playerZ, x, y, targetZ, 1, PlayerPedId(), 0)
    Citizen.Wait(0)
    local _, hit, _, _, _ = GetShapeTestResult(handle)

    if hit then
        --if ValidatorConfig.debug then
            --print(string.format("[SIDEWALK] Visibility check at %.1f,%.1f: BLOCKED -> FAIL", x, y))
        --end
        return false
    end

    return true
end

-- ============================================
-- FILTRE 4: PAS SUR LA ROUTE
-- ============================================
local function CheckNotOnRoad(x, y, z)
    local onRoad = IsPointOnRoad(x, y, z, 0)

    --if ValidatorConfig.debug and onRoad then
        --print(string.format("[SIDEWALK] On road check at %.1f,%.1f: ON ROAD -> FAIL", x, y))
    --end

    return not onRoad
end

-- ============================================
-- FILTRE 5: PAS DANS UN INTERIEUR
-- ============================================
local function CheckNotInInterior(x, y, z)
    local interior = GetInteriorAtCoords(x, y, z)
    local isOutside = interior == 0

    --if ValidatorConfig.debug and not isOutside then
        --print(string.format("[SIDEWALK] Interior check at %.1f,%.1f: IN INTERIOR -> FAIL", x, y))
    --end

    return isOutside
end

-- ============================================
-- PIPELINE COMPLET DE VALIDATION (AMELIORE)
-- 8 filtres pour une fiabilité maximale
-- ============================================
function SidewalkValidator.ValidatePosition(x, y, z, playerZ, heading, playerCoords)
    -- Verifier la hauteur par rapport au joueur
    local heightDiff = math.abs(z - (playerZ or z))
    if heightDiff > ValidatorConfig.maxHeightDiff then
        --if ValidatorConfig.debug then
            --print(string.format("[SIDEWALK] Height diff %.1f > %.1f -> REJECTED", heightDiff, ValidatorConfig.maxHeightDiff))
        --end
        return false, 0, "height"
    end

    -- FILTRE 1: Pas dans un interieur
    if not CheckNotInInterior(x, y, z) then
        return false, 0, "interior"
    end

    -- FILTRE 2: Pas sur la route
    if not CheckNotOnRoad(x, y, z) then
        return false, 0, "on_road"
    end

    -- FILTRE 3: Proximite d'une route
    local roadOk, roadDist = CheckRoadProximity(x, y, z)
    if not roadOk then
        return false, 0, "road_far"
    end

    -- FILTRE 4: Densite de nodes (trottoir principal)
    local densityOk, nodeCount = CheckNodeDensity(x, y, z)
    if not densityOk then
        return false, 0, "low_density"
    end

    -- FILTRE 5: Espace lateral (pas une ruelle) - Amélioré multi-angle
    local lateralOk, clearance = CheckLateralSpace(x, y, z, heading)
    if not lateralOk then
        return false, 0, "narrow"
    end

    -- FILTRE 6: Verification de pente
    local slopeOk, slopeAngle = CheckSlope(x, y, z)
    if not slopeOk then
        return false, 0, "slope"
    end

    -- FILTRE 7: Pas de vehicules gares
    if not CheckNoVehiclesNearby(x, y, z) then
        return false, 0, "vehicle"
    end

    -- FILTRE 8: Visibilité depuis le joueur (optionnel, désactivé si trop restrictif)
    -- Note: On le garde optionnel car parfois on veut spawn hors de vue
    -- if playerCoords and not CheckVisibilityFromPlayer(x, y, z, playerCoords) then
    --     return false, 0, "visibility"
    -- end

    -- Calcul du score (plus bas = meilleur)
    -- Favorise: proche de la route, bonne densite, bon degagement, terrain plat
    local score = heightDiff + (roadDist / 10) + (8 - nodeCount) + (3 - clearance) + (slopeAngle / 5)

    --if ValidatorConfig.debug then
        --print(string.format("[SIDEWALK] VALIDATED at %.1f,%.1f,%.1f - score: %.2f (nodes:%d, road:%.1f, clear:%.1f, slope:%.1f°)",
            --x, y, z, score, nodeCount, roadDist, clearance, slopeAngle))
    --end

    return true, score, "valid"
end

-- ============================================
-- RECHERCHE DE SPAWN INTELLIGENT
-- Utilise le pipeline complet
-- ============================================
function SidewalkValidator.FindValidSpawnPosition(originX, originY, originZ, minDist, maxDist, maxAttempts)
    maxAttempts = maxAttempts or 40
    local validPositions = {}
    local rejectionStats = {
        height = 0,
        interior = 0,
        on_road = 0,
        road_far = 0,
        low_density = 0,
        narrow = 0,
        slope = 0,
        vehicle = 0,
        visibility = 0,
        no_ground = 0
    }

    for attempt = 1, maxAttempts do
        local angle = math.random() * 2 * math.pi
        local distance = minDist + math.random() * (maxDist - minDist)
        local testX = originX + (math.cos(angle) * distance)
        local testY = originY + (math.sin(angle) * distance)

        -- Trouver le sol au niveau du joueur (évite de hit un pont au-dessus)
        -- On part juste au-dessus du joueur pour récupérer le ground le plus proche de son niveau
        local foundGround, groundZ = GetGroundZFor_3dCoord(testX, testY, originZ + 1.0, false)

        -- Vérifier que le sol trouvé est proche du joueur (sinon c'est un pont/étage différent)
        if foundGround and groundZ and math.abs(groundZ - originZ) > ValidatorConfig.maxHeightDiff then
            foundGround = false
        end

        if not foundGround or not groundZ or groundZ <= 0.0 then
            -- Fallback: essayer plus haut au cas où le raycast initial a échoué
            foundGround, groundZ = GetGroundZFor_3dCoord(testX, testY, originZ + 50.0, false)
            if foundGround and groundZ and math.abs(groundZ - originZ) > ValidatorConfig.maxHeightDiff then
                foundGround = false
            end
        end

        if foundGround and groundZ and groundZ > 0.0 then
            -- Obtenir le heading vers le joueur (pour le check lateral)
            local heading = math.deg(math.atan2(originY - testY, originX - testX))

            -- Valider avec le pipeline complet
            local isValid, score, reason = SidewalkValidator.ValidatePosition(testX, testY, groundZ, originZ, heading)

            if isValid then
                table.insert(validPositions, {
                    coords = vector3(testX, testY, groundZ),
                    distance = distance,
                    score = score
                })

                -- Arreter si on a assez de bonnes positions
                if #validPositions >= 10 then
                    break
                end
            else
                if rejectionStats[reason] then
                    rejectionStats[reason] = rejectionStats[reason] + 1
                end
            end
        else
            rejectionStats.no_ground = rejectionStats.no_ground + 1
        end
    end

    -- Log des stats de rejet
    --if ValidatorConfig.debug or #validPositions == 0 then
        --print("[SIDEWALK] Rejection stats:")
        --for reason, count in pairs(rejectionStats) do
            --if count > 0 then
                --print(string.format("  - %s: %d", reason, count))
            --end
        --end
    --end

    -- Trier par score et retourner
    if #validPositions > 0 then
        table.sort(validPositions, function(a, b) return a.score < b.score end)

        --print(string.format("[SIDEWALK] Found %d valid positions, best score: %.2f",
            --#validPositions, validPositions[1].score))

        return validPositions
    end

    --print("[SIDEWALK] No valid positions found!")
    return {}
end

-- ============================================
-- METHODE ALTERNATIVE: Utiliser GetSafeCoordForPed + validation
-- Amélioration: Distribution spirale + multi-distance
-- ============================================
function SidewalkValidator.FindValidSpawnWithPedNodes(originX, originY, originZ, minDist, maxDist, maxAttempts)
    maxAttempts = maxAttempts or 30
    local validPositions = {}
    local testedPositions = {} -- Éviter les doublons

    -- Stratégie 1: Distribution spirale (couvre mieux la zone)
    local numRings = 4
    local anglesPerRing = 8

    for ring = 1, numRings do
        local ringDist = minDist + ((maxDist - minDist) * (ring / numRings))

        for a = 1, anglesPerRing do
            local angle = ((a - 1) / anglesPerRing) * 2 * math.pi + (ring * 0.3) -- Décalage par anneau
            local testX = originX + (math.cos(angle) * ringDist)
            local testY = originY + (math.sin(angle) * ringDist)

            local found, safeCoords = GetSafeCoordForPed(testX, testY, originZ, true, 0)

            if found and safeCoords then
                local x, y, z = safeCoords.x, safeCoords.y, safeCoords.z

                -- Vérifier si on a déjà testé une position proche
                local posKey = string.format("%.0f_%.0f", x / 5, y / 5)
                if not testedPositions[posKey] then
                    testedPositions[posKey] = true

                    local heading = math.deg(math.atan2(originY - y, originX - x))
                    local isValid, score, _ = SidewalkValidator.ValidatePosition(x, y, z, originZ, heading)

                    if isValid then
                        table.insert(validPositions, {
                            coords = vector3(x, y, z),
                            distance = #(vector3(originX, originY, originZ) - safeCoords),
                            score = score
                        })
                    end
                end
            end

            -- Petite pause pour les raycasts
            if a % 4 == 0 then
                Citizen.Wait(0)
            end
        end
    end

    -- Stratégie 2: Recherches aléatoires complémentaires
    local remainingAttempts = math.max(0, maxAttempts - (numRings * anglesPerRing))
    for attempt = 1, remainingAttempts do
        local angle = math.random() * 2 * math.pi
        local distance = minDist + math.random() * (maxDist - minDist)
        local testX = originX + (math.cos(angle) * distance)
        local testY = originY + (math.sin(angle) * distance)

        local found, safeCoords = GetSafeCoordForPed(testX, testY, originZ, true, 0)

        if found and safeCoords then
            local x, y, z = safeCoords.x, safeCoords.y, safeCoords.z
            local posKey = string.format("%.0f_%.0f", x / 5, y / 5)

            if not testedPositions[posKey] then
                testedPositions[posKey] = true
                local heading = math.deg(math.atan2(originY - y, originX - x))
                local isValid, score, _ = SidewalkValidator.ValidatePosition(x, y, z, originZ, heading)

                if isValid then
                    table.insert(validPositions, {
                        coords = vector3(x, y, z),
                        distance = #(vector3(originX, originY, originZ) - safeCoords),
                        score = score
                    })
                end
            end
        end
    end

    if #validPositions > 0 then
        table.sort(validPositions, function(a, b) return a.score < b.score end)
        --print(string.format("[SIDEWALK] PedNodes method found %d valid positions", #validPositions))
        return validPositions
    end

    --print("[SIDEWALK] PedNodes method found no valid positions")
    return {}
end

-- ============================================
-- CONFIGURATION
-- ============================================
function SidewalkValidator.SetDebug(enabled)
    ValidatorConfig.debug = enabled
end

function SidewalkValidator.GetConfig()
    return ValidatorConfig
end

function SidewalkValidator.UpdateConfig(key, value)
    if ValidatorConfig[key] ~= nil then
        ValidatorConfig[key] = value
    end
end


-- Export du module
exports("ValidateSidewalkPosition", SidewalkValidator.ValidatePosition)
exports("FindValidSpawnPosition", SidewalkValidator.FindValidSpawnPosition)
exports("FindValidSpawnWithPedNodes", SidewalkValidator.FindValidSpawnWithPedNodes)

return SidewalkValidator
