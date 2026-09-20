---@meta _
---@diagnostic disable: duplicate-doc-field

-- ==========================================
--           MENU F5 - Vision V2
-- ==========================================

local VUI = exports["VUI"]

-- Local variables
local cinemaMode = false
local hideHUD = false
-- Mute nouveaux joueurs (streamer)
local _muteNewKvpInit = GetResourceKvpString("mute_new_players")
local muteNewPlayersEnabled = (_muteNewKvpInit == "1")
local mutedPlayerIds = {}
-- Sons VUI : activé par défaut (kvp absent = nil = true, kvp "0" = false, kvp "1" = true)
local _vuiSoundKvp = GetResourceKvpString("vui_sound_enabled")
local vuiSoundEnabled = (_vuiSoundKvp == nil or _vuiSoundKvp == "1")
local hideMinimap = false
local rockstarActivate = false
local rockstarEditorConfirmTime = 0
local minimap = nil
local targetingPlayer = false
local currentAimAnimation = "default"
local _hideVoiceChatKvp = GetResourceKvpString("hide_voice_chat")
local hideVoiceChat = (_hideVoiceChatKvp == "1")
local _hideLogoKvp = GetResourceKvpString("hide_logo")
local hideLogo = (_hideLogoKvp == "1")
local _hideIGInfoKvp = GetResourceKvpString("hide_ig_info")
local hideIGInfo = (_hideIGInfoKvp == "1")
local _compassKvp = GetResourceKvpString("compass_enabled")
local compassEnabled = (_compassKvp == "1")
local _doorlockDetailKvp = GetResourceKvpString("doorlock_detail_enabled")
local doorlockDetailEnabled = (_doorlockDetailKvp == nil or _doorlockDetailKvp == "1")
local radioEmotesClearTimeout = nil

-- Variables de prévisualisation des emotes d'armes
local weaponEmotePreviewActive = false
local weaponPreviewClone = nil
local weaponPreviewThread = nil
local currentWeaponPreviewStyle = nil
local weaponPreviewCurrentIndex = 0

-- ==========================================
--              UTILITY FUNCTIONS
-- ==========================================

--- Load Minimap Scaleform
local function EnsureMinimapScaleformLoaded()
    if minimap and HasScaleformMovieLoaded(minimap) then
        return
    end

    if not minimap then
        minimap = RequestScaleformMovie("minimap")
    end

    while not HasScaleformMovieLoaded(minimap) do
        Wait(0)
    end
end

--- Display Health & Armour on minimap
---@param value number
local function DisplayHealthArmour(value)
    EnsureMinimapScaleformLoaded()
    BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
    ScaleformMovieMethodAddParamInt(value)
    EndScaleformMovieMethod()
end

--- Draw Cinema Bars
local function drawCinemaBars()
    DrawRect(0.0, 0.0, 2.0, 0.2, 0, 0, 0, 255)
    DrawRect(0.0, 1.0, 2.0, 0.2, 0, 0, 0, 255)
end

--- Update HUD Visibility
local function UpdateHudVisibility()
    VFW.Nui.HudVisible(not hideHUD)

    if hideMinimap then
        DisplayRadar(false)
    else
        DisplayRadar(true)
    end
end

--- Public Territories Map state
local isPublicTerritoriesOpen = false

--- Open Public Territories Map (uses the same UI as faction tablet but in public mode)
function OpenPublicTerritoriesMap()
    local territories = TriggerServerCallback("core:factionTerritories:getPublic")

    if not territories or #territories == 0 then
        VFW.ShowNotification({
            type = 'ORANGE',
            content = "Aucun territoire disponible"
       })
        return
    end

    -- Format territories for the tablet UI
    local formattedTerritories = {}
    for _, territory in ipairs(territories) do
        table.insert(formattedTerritories, {
            id = territory.id,
            name = territory.name,
            polygon = territory.polygon,
            display_number = territory.display_number,
            display_color = territory.display_color,
            owner = territory.isOwned and "Occupé" or nil, -- Generic "Occupé" instead of faction name
            sales = {}
        })
    end

    -- Send to NUI with public mode flag
    SendNUIMessage({
        action = "openFactionTerritories",
        data = {
            territories = formattedTerritories,
            myTerritories = {},
            myFaction = "",
            myFactionLabel = "Public",
            myFactionColor = "#6366F1",
            isPublicMode = true, -- Flag for public mode
            settings = {
                salesThreshold = 50,
                ownershipDurationHours = 48,
                ownerBonusPercent = 25
            }
        }
    })

    isPublicTerritoriesOpen = true
    VFW.Nui.Focus(true, false)
end

--- Close Public Territories Map
function ClosePublicTerritoriesMap()
    if not isPublicTerritoriesOpen then return end

    isPublicTerritoriesOpen = false
    SendNUIMessage({
        action = "closeFactionTerritories"
   })
    VFW.Nui.Focus(false, false)
end

--- NUI Callback for closing public territories map
RegisterNUICallback("factionTerritories:close", function(_, cb)
    if isPublicTerritoriesOpen then
        ClosePublicTerritoriesMap()
    end
    cb({})
end)

--- Toggle Cinema Mode
---@param enabled boolean
local function toggleCinemaMode(enabled)
    if enabled == cinemaMode then
        return
    end

    cinemaMode = enabled
    SetRadarBigmapEnabled(false, false)

    if cinemaMode then
        CreateThread(function()
            while cinemaMode do
                Wait(0)
                drawCinemaBars()
            end
        end)
        VFW.ShowNotification({ type = 'JAUNE', content = "Mode cinéma activé" })
    else
        VFW.ShowNotification({ type = 'VERT', content = "Mode cinéma désactivé" })
    end
end

-- Event pour toggle le mode cinéma depuis d'autres scripts
RegisterNetEvent("vfw:toggleCinemaMode", function()
    toggleCinemaMode(not cinemaMode)
end)

--- Toggle HUD Display
---@param enabled boolean
local function toggleHUD(enabled)
    hideHUD = enabled
    UpdateHudVisibility()
end

--- Toggle Minimap Display
---@param enabled boolean
local function toggleMinimap(enabled)
    hideMinimap = enabled
    UpdateHudVisibility()
end

local function toggleVoiceChat(enabled)
    hideVoiceChat = enabled
    SetResourceKvp("hide_voice_chat", enabled and "1" or "0")
    TriggerEvent("pma-voice:toggleUi", not enabled)
end

local function toggleLogo(enabled)
    hideLogo = enabled
    SetResourceKvp("hide_logo", enabled and "1" or "0")
    SendNUIMessage({ action = "nui:logo:visible", data = not enabled })
end

local function toggleIGInfo(enabled)
    hideIGInfo = enabled
    SetResourceKvp("hide_ig_info", enabled and "1" or "0")
    SendNUIMessage({ action = "nui:igInfo:visible", data = not enabled })
end

local function toggleCompass(enabled)
    compassEnabled = enabled
    SetResourceKvp("compass_enabled", enabled and "1" or "0")
    exports["fb_boussole"]:SetCompassEnabled(enabled)
    exports["fb_boussole"]:SetStreetNameEnabled(enabled)
end

RegisterNUICallback("nui:logo:getVisible", function(_, cb)
    cb(not hideLogo)
end)

RegisterNUICallback("nui:igInfo:getVisible", function(_, cb)
    cb(not hideIGInfo)
end)

Citizen.CreateThread(function()
    while true do
        SetPedUsingActionMode(PlayerPedId(), false, -1, "DEFAULT_ACTION")
        Citizen.Wait(100)
    end
end)

local freecamButtonId = generateUniqueID(8)

--- Reset to Default
local function resetToDefault()
    -- Reset visuals
    cinemaMode = false
    hideHUD = false
    hideMinimap = false
    toggleLogo(false)
    UpdateHudVisibility()

    -- Reset animations
    ResetPedMovementClipset(PlayerPedId(), 0)
    ResetPedWeaponMovementClipset(PlayerPedId())
    ResetPedStrafeClipset(PlayerPedId())

    -- Clear any stuck animations
    ClearPedTasks(PlayerPedId())

    VFW.ShowNotification({
        type = 'VERT',
        content = "Paramètres remis par défaut"
   })
end

--- FreeCam Function (global for VIP menu access)
---@param solid boolean? if true, la caméra ne traverse pas les murs (raycast)
function activateFreeCam(solid, vip)
    local playerPed = PlayerPedId()
    local startCoords = GetEntityCoords(playerPed)

    local maxDistance = 20.0
    local camMultiplier = 1.0 -- Default multiplier for camera distance
    local camFov = 50.0
    local minFov, maxFov = 10.0, 90.0

    -- Freeze player in place
    FreezeEntityPosition(playerPed, true)

    -- Create camera at a good distance to see the character
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, startCoords.x - 1.5, startCoords.y - 1.5, startCoords.z + 1.0) -- Start 1.5m back and 1m up to see character
    SetCamRot(cam, -10.0, 0.0, GetEntityHeading(playerPed))
    if vip then
        SetCamFov(cam, camFov)
    end
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    VFW.ShowNotification({
        type = 'JAUNE',
        content = "FreeCam activée - Appuyez sur [X] ou [RETOUR] pour quitter"
   })

    -- FreeCam controls
    CreateThread(function()

        local function updateFreecamButtons()
            local buttons = {
                { control = 32, label = "Avancer" },
                { control = 33, label = "Reculer" },
                { control = 44, label = "Monter" },
                { control = 20, label = "Descendre" },
                { control = 241, label = "Molette - Vitesse (" .. string.format("%.1f", camMultiplier) .. "x)" },
            }
            if vip then
                buttons[#buttons + 1] = { control = 21, label = "MAJ + Molette - Zoom (" .. string.format("%.0f", camFov) .. "°)" }
            end
            buttons[#buttons + 1] = { control = 194, label = "Quitter" }
            instructionalButtons[freecamButtonId] = buttons
        end
        updateFreecamButtons()

        while DoesCamExist(cam) do
            Wait(0)

            -- CRITICAL: Disable ALL player movement controls
            DisableControlAction(0, 30, true)  -- Disable moving left/right (A/D)
            DisableControlAction(0, 31, true)  -- Disable moving back/forth (W/S)
            DisableControlAction(0, 32, true)  -- W
            DisableControlAction(0, 33, true)  -- S
            DisableControlAction(0, 34, true)  -- A
            DisableControlAction(0, 35, true)  -- D
            DisableControlAction(0, 36, true)  -- Duck/Sneak
            DisableControlAction(0, 21, true)  -- Sprint
            DisableControlAction(0, 22, true)  -- Jump
            DisableControlAction(0, 44, true)  -- Q
            DisableControlAction(0, 20, true)  -- Z
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 37, true)  -- Select weapon
            DisableControlAction(0, 47, true)  -- Weapon special
            DisableControlAction(0, 58, true)  -- Weapon special 2
            DisableControlAction(0, 140, true) -- Melee attack light
            DisableControlAction(0, 141, true) -- Melee attack heavy
            DisableControlAction(0, 142, true) -- Melee attack alternate
            DisableControlAction(0, 143, true) -- Melee block
            DisableControlAction(0, 263, true) -- Melee attack 1
            DisableControlAction(0, 264, true) -- Melee attack 2

            -- Disable mouse look for player (but keep it for camera)
            DisableControlAction(0, 1, true)   -- Look left/right
            DisableControlAction(0, 2, true)   -- Look up/down


            --
            local zoomModifier = vip and IsDisabledControlPressed(0, 21) -- LSHIFT held = FOV zoom mode (VIP only)
            if IsDisabledControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 15) then
                if zoomModifier then
                    camFov = math.max(minFov, camFov - 2.0)
                    SetCamFov(cam, camFov)
                else
                    camMultiplier = camMultiplier + 0.5
                    if camMultiplier > 10.0 then
                        camMultiplier = 10.0
                    end
                end
                updateFreecamButtons()
            elseif IsDisabledControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 14) then
                if zoomModifier then
                    camFov = math.min(maxFov, camFov + 2.0)
                    SetCamFov(cam, camFov)
                else
                    camMultiplier = camMultiplier - 0.5
                    if camMultiplier < 0.2 then
                        camMultiplier = 0.2
                    end
                end
                updateFreecamButtons()
            end

            local camCoords = GetCamCoord(cam)
            local camRot = GetCamRot(cam, 2)

            -- Calculate movement speed (increased for better responsiveness)
            local moveSpeed = 0.05 * camMultiplier -- 5cm per frame for faster navigation

            -- Movement controls with distance limitation
            local newCoords = camCoords

            -- Get camera forward and right vectors manually
            local function getCamDirections()
                local heading = GetCamRot(cam, 2).z
                local pitch = GetCamRot(cam, 2).x

                -- Convert to radians
                local headingRad = math.rad(heading)
                local pitchRad = math.rad(pitch)

                -- Calculate forward vector
                local fwdX = -math.sin(headingRad) * math.cos(pitchRad)
                local fwdY = math.cos(headingRad) * math.cos(pitchRad)
                local fwdZ = math.sin(pitchRad)

                -- Calculate right vector
                local rightX = math.cos(headingRad)
                local rightY = math.sin(headingRad)
                local rightZ = 0

                return vector3(fwdX, fwdY, fwdZ), vector3(rightX, rightY, rightZ)
            end

            local forwardVector, rightVector = getCamDirections()

            -- Function to smoothly limit movement at boundaries
            local function applySmoothBoundary(testCoords)
                local distance = #(testCoords - startCoords)

                if distance <= maxDistance then
                    return testCoords
                else
                    -- Calculate how much we're over the limit
                    local overLimit = distance - maxDistance

                    -- Create a vector from start to test position
                    local direction = (testCoords - startCoords) / distance

                    -- Place the camera exactly at the boundary limit
                    local boundaryCoords = startCoords + (direction * maxDistance)

                    -- Smooth interpolation - slightly pull back from exact boundary for smoothness
                    local smoothedCoords = boundaryCoords - (direction * 0.01) -- Pull back 1cm from boundary

                    return smoothedCoords
                end
            end

            -- Accumulate movement inputs
            local moveVector = vector3(0, 0, 0)

            if IsDisabledControlPressed(0, 32) then
                -- W (forward)
                moveVector = moveVector + forwardVector * moveSpeed
            end

            if IsDisabledControlPressed(0, 33) then
                -- S (backward)
                moveVector = moveVector - forwardVector * moveSpeed
            end

            if IsDisabledControlPressed(0, 34) then
                -- A (left)
                moveVector = moveVector - rightVector * moveSpeed
            end

            if IsDisabledControlPressed(0, 35) then
                -- D (right)
                moveVector = moveVector + rightVector * moveSpeed
            end

            -- Up/Down movement with Q and Z
            if IsDisabledControlPressed(0, 44) then
                -- Q (up)
                moveVector = moveVector + vector3(0, 0, moveSpeed)
            end

            if IsDisabledControlPressed(0, 20) then
                -- Z (down)
                moveVector = moveVector - vector3(0, 0, moveSpeed)
            end


            -- Apply movement with smooth boundary
            if #moveVector > 0 then
                local testCoords = camCoords + moveVector
                newCoords = applySmoothBoundary(testCoords)

                -- Add slight easing when near boundary
                local currentDistance = #(newCoords - startCoords)
                local boundaryProximity = currentDistance / maxDistance

                if boundaryProximity > 0.95 then
                    -- Only slow down when VERY close to boundary (last 5%)
                    local slowFactor = 1.0 - ((boundaryProximity - 0.95) * 4.0) -- Less aggressive slowdown
                    slowFactor = math.max(slowFactor, 0.6) -- Minimum 60% speed (faster minimum)

                    local adjustedMove = camCoords + (moveVector * slowFactor)
                    newCoords = applySmoothBoundary(adjustedMove)
                end
            end

            -- Apply new camera position with smooth interpolation
            local lerpFactor = 0.5 -- Increased for more responsive movement while keeping smoothness
            local smoothedPos = camCoords + ((newCoords - camCoords) * lerpFactor)

            if solid then
                -- Raycast contre map/objects/véhicules : si on touche un mur, on s'arrête juste avant.
                local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, smoothedPos.x, smoothedPos.y, smoothedPos.z, 1 | 16 | 32 | 256 | 512, playerPed, 0)
                local _, hit, endCoords = GetShapeTestResult(ray)
                if hit == 1 then
                    local delta = smoothedPos - camCoords
                    local len = #delta
                    if len > 0 then
                        local norm = delta / len
                        smoothedPos = vector3(endCoords.x - norm.x * 0.5, endCoords.y - norm.y * 0.5, endCoords.z - norm.z * 0.5)
                    else
                        smoothedPos = endCoords
                    end
                end
            end

            SetCamCoord(cam, smoothedPos.x, smoothedPos.y, smoothedPos.z)

            -- Rotation controls (mouse) - allow free rotation
            local mouseX = GetDisabledControlNormal(0, 1)
            local mouseY = GetDisabledControlNormal(0, 2)

            -- Scale mouse sensitivity by FOV so zoom-in stays precise (VIP only since FOV stays default for others)
            local rotSpeed = vip and (5.0 * (camFov / 50.0)) or 5.0

            SetCamRot(cam,
                    camRot.x - mouseY * rotSpeed,
                    camRot.y,
                    camRot.z - mouseX * rotSpeed,
                    2
            )

            -- Display distance from player
            ---@TODO remove before push
            --local currentDistance = #(camCoords - startCoords)
            --DrawText2D(0.5, 0.95, string.format("Distance: %.2f m | Max: %.1f m", currentDistance, maxDistance), 0.35)

            -- Exit on BACKSPACE key (more reliable than E)
            if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 202) then
                -- BACKSPACE or ESC alternative
                RenderScriptCams(false, false, 0, false, false)
                DestroyCam(cam, false)
                FreezeEntityPosition(playerPed, false)
                instructionalButtons[freecamButtonId] = nil
                VFW.ShowNotification({
                    type = 'VERT',
                    content = "FreeCam désactivée"
               })
                break
            end

            -- Also check for X key as backup exit
            if IsControlJustPressed(0, 73) or IsDisabledControlJustPressed(0, 73) then
                -- X key
                RenderScriptCams(false, false, 0, false, false)
                DestroyCam(cam, false)
                FreezeEntityPosition(playerPed, false)
                instructionalButtons[freecamButtonId] = nil
                VFW.ShowNotification({
                    type = 'VERT',
                    content = "FreeCam désactivée"
               })
                break
            end
        end
    end)
end

-- Helper function to draw 2D text on screen
function DrawText2D(x, y, text, scale)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(x, y)
end

--- Get Player Documents Data
local function getDocumentsData()
    -- Get real identity data from server
    local identityData = TriggerServerCallback("identity:getData", GetPlayerServerId(PlayerId()))

    -- Parse the name to get first and last name
    local firstname = identityData and identityData.firstName or "John"
   local lastname = identityData and identityData.lastName or "Doe"
   local birthdate = identityData and identityData.date_of_birth or "01/01/1990"
   local sex = identityData and identityData.sex or "m"
   local height = identityData and identityData.height or 180
    local photo = identityData and identityData.photo or nil

    return {
        identity = {
            firstname = firstname,
            lastname = lastname,
            birthdate = birthdate,
            sex = sex,
            height = height,
            photo = photo
        },
        licenses = TriggerServerCallback("vfw:license:checkAllLicense", GetPlayerServerId(PlayerId())) or {},
        job = VFW.PlayerData and VFW.PlayerData.job or {
            name = "unemployed",
            label = "Chômeur",
            grade_name = "unemployed",
            grade_label = "Chômeur"
       },
        job2 = VFW.PlayerData and VFW.PlayerData.job2 or nil,
        faction = VFW.PlayerData and VFW.PlayerData.faction or nil
    }
end

-- Track if document is open
local documentOpen = false

--- Show Document using new playerDocuments UI
---@param documentType string
---@param isShowing boolean
local function showPlayerDocument(documentType, isShowing)
    -- Fetch fresh data every time we show a document
    local docs = getDocumentsData()
    local documentData = {}
    local cardLabel = ""
   local cardType = ""
   local society = nil
    local licenseCategories = nil

    if documentType == "identity" then
        cardType = "citizen"
       cardLabel = "Carte d'identité"
       documentData = {
            ["Nom"] = docs.identity.lastname,
            ["Prénom"] = docs.identity.firstname,
            ["Date de naissance"] = docs.identity.birthdate,
            ["Sexe"] = (docs.identity.sex == "m" or docs.identity.sex == "M") and "Homme" or "Femme",
            ["Taille"] = tostring(docs.identity.height) .. " cm"
       }
    elseif documentType == "driver" then
        cardType = "driver_license"
       cardLabel = "Permis de conduire"

       -- Fetch real DVM licenses (ordered by oldest first, date pre-formatted by server)
        local licenses = TriggerServerCallback("dvm:getPlayerLicensesForDocument")

        -- Build license map for categories
        local dvmLicenseMap = {}
        local oldestDate = nil

        -- Process licenses
        if licenses and #licenses > 0 then
            for _, license in ipairs(licenses) do
                dvmLicenseMap[license.license_type] = true

                -- First license in the list is the oldest (ORDER BY obtained_date ASC)
                if not oldestDate then
                    oldestDate = license.obtained_date_formatted
                end
            end
        end

        -- Build licenseCategories for the card display (like achievement)
        licenseCategories = {
            A = dvmLicenseMap["motorcycle"] or false,
            B = dvmLicenseMap["car"] or false,
            C = dvmLicenseMap["truck"] or false
        }

        -- Use pre-formatted date from server
        local issuedDate = oldestDate or "Non disponible"

       documentData = {
            ["Nom"] = docs.identity.lastname,
            ["Prénom"] = docs.identity.firstname,
            ["Date de naissance"] = docs.identity.birthdate,
            ["Délivré le"] = issuedDate
        }
    elseif documentType == "weapon_leger" or documentType == "weapon_lourd" then
        cardType = "weapon_license"
       local isLeger = documentType == "weapon_leger"
       cardLabel = isLeger and "PPA - Catégorie Légère" or "PPA - Catégorie Lourde"

       -- Fetch real PPA dates from server
        local ppaDates = TriggerServerCallback("vip:ppa:getDates")
        local ppaData = ppaDates and (isLeger and ppaDates.leger or ppaDates.lourd) or nil
        local issuedAt = ppaData and ppaData.issuedAt or "Non renseigné"
       local validUntil = ppaData and ppaData.validUntil or "Non renseigné"

       documentData = {
            ["Nom"] = docs.identity.lastname,
            ["Prénom"] = docs.identity.firstname,
            ["Délivré le"] = issuedAt,
            ["Valide jusqu'au"] = validUntil,
            ["Type"] = isLeger and "Catégorie Légère" or "Catégorie Lourde",
            ["Numéro"] = (isLeger and "PPA-L-" or "PPA-H-") .. math.random(100000, 999999)
        }
    elseif documentType == "job" then
        cardType = "job_card"
       cardLabel = "Carte d'entreprise"
       local jobName = VFW.PlayerData.job and VFW.PlayerData.job.name or nil
        local isUnemployed = not jobName or jobName == "unemployed"
       society = isUnemployed and "demandeur_emploi" or jobName
        documentData = {
            ["Nom"] = docs.identity.lastname,
            ["Prénom"] = docs.identity.firstname,
            ["Entreprise"] = isUnemployed and "Demandeur d'emploi" or docs.job.label,
            ["Grade"] = isUnemployed and "" or docs.job.grade_label,
        }
    elseif documentType == "cayo_visa" then
        cardType = "cayo_visa"
       cardLabel = "Visa de Cayo Perico"

       local visaData = TriggerServerCallback("identity:getData", GetPlayerServerId(PlayerId()), "cayo_visa")
        local issuedAt = visaData and visaData.issued_date or "Non renseigné"
       local visaNumber = visaData and visaData.visa_number or "CAYO-00000"

       documentData = {
            ["Nom"] = docs.identity.lastname,
            ["Prénom"] = docs.identity.firstname,
            ["Date de naissance"] = docs.identity.birthdate,
            ["Délivré le"] = issuedAt,
            ["Numéro"] = visaNumber,
            ["Délivré par"] = "Gouvernement de Cayo"
       }
    end

    -- If showing to another player, select target FIRST and don't show locally
    if isShowing then
        local result = VFW.StartSelect(3.0, true)
        if result then
            local targetId = GetPlayerServerId(result)
            -- Play animation on the showing player
            ExecuteCommand("e idcard")
            -- Trigger server event to show document to target player ONLY
            TriggerServerEvent("vfw:showDocumentToPlayer", targetId, documentType, documentData, cardType, cardLabel, docs.identity.photo, licenseCategories)

            -- Wait for X to stop or auto-stop after 15 seconds
            CreateThread(function()
                SendNUIMessage({ action = "instructionalBar:show", data = { items = {
                    { keys = { "X" }, label = "Ranger le document" }
                } } })
                local timeout = 0
                while timeout < 15000 do
                    Wait(0)
                    DisableControlAction(0, 73, true)
                    if IsDisabledControlJustPressed(0, 73) then
                        break
                    end
                    timeout = timeout + GetFrameTime() * 1000
                end
                SendNUIMessage({ action = "instructionalBar:hide" })
                ExecuteCommand("cancelemote")
                TriggerServerEvent("vfw:stopShowingDocument", targetId)
            end)
        else
            VFW.ShowNotification({
                type = 'ORANGE',
                content = "Aucune personne à proximité"
           })
        end
        return -- Don't show locally when showing to another player
    end

    -- Show locally only if NOT showing to someone else
    SendNUIMessage({
        action = "playerDocuments:toggle",
        data = {
            cardType = cardType,
            cardLabel = cardLabel,
            society = society,
            theme = "light",
            data = documentData,
            photoUrl = docs.identity.photo,
            licenseCategories = licenseCategories
        }
    })

    documentOpen = true

    -- Create thread to handle ESC key
    Citizen.CreateThread(function()
        while documentOpen do
            Wait(0)
            -- Disable pause menu ONLY while document is open
            DisableControlAction(0, 200, true) -- ESC / Pause menu
            DisableControlAction(0, 199, true) -- P / Pause menu

            -- Check if ESC (disabled), Enter, or Backspace/Return is pressed
            if IsDisabledControlJustPressed(0, 200) or -- ESC
               IsControlJustPressed(0, 191) or -- Enter
               IsControlJustPressed(0, 194) or -- Backspace
               IsControlJustPressed(0, 177) then -- KEY_BACK/Return
                documentOpen = false
                SendNUIMessage({
                    action = "playerDocuments:close"
               })
            end
        end
        -- When loop ends (document closed), pause menu will work normally again
    end)
end

-- Event pour afficher un document depuis d'autres scripts (ex: context menu)
RegisterNetEvent("menuf5:showDocument", function(documentType)
    showPlayerDocument(documentType, false)
end)

-- Event pour montrer un document à un joueur proche (ex: menu métier)
RegisterNetEvent("menuf5:showDocumentToPlayer", function(documentType)
    showPlayerDocument(documentType, true)
end)

-- ==========================================
--              MENU CREATION
-- ==========================================

-- Get default banner URL
local defaultBanner = VFW.CDN.Get("banners/f5.png")

local main = VUI:CreateMenu("Menu Personnel", defaultBanner, true)
local documentsMenu = VUI:CreateSubMenu(main, "Mes Documents", defaultBanner, true)
local vehiclesMenu = VUI:CreateSubMenu(main, "Mes véhicules", defaultBanner, true)
local giveSelectVehicleMenu = VUI:CreateSubMenu(vehiclesMenu, "Donner un véhicule", defaultBanner, true)
local giveSelectPlayerMenu = VUI:CreateSubMenu(giveSelectVehicleMenu, "Choisir le destinataire", defaultBanner, true)
local sellSelectVehicleMenu = VUI:CreateSubMenu(vehiclesMenu, "Vendre un véhicule", defaultBanner, true)
local sellSelectPlayerMenu = VUI:CreateSubMenu(sellSelectVehicleMenu, "Choisir l'acheteur", defaultBanner, true)
local visualOptionsMenu = VUI:CreateSubMenu(main, "Options Visuelles", defaultBanner, true)
local vuiOptionsMenu = VUI:CreateSubMenu(main, "Options VUI", defaultBanner, true)
local streamerOptionsMenu = VUI:CreateSubMenu(main, "Options Streamer", defaultBanner, true)
local animationsMenu = VUI:CreateSubMenu(main, "Animations", defaultBanner, true)
local styleradioMenu = VUI:CreateSubMenu(main, "Animations", defaultBanner, true)
local radioEmotesMenu = VUI:CreateSubMenu(styleradioMenu, "Emote radio", defaultBanner, true)
local weaponEmotesMenu = VUI:CreateSubMenu(styleradioMenu, "Animation de visée", defaultBanner, true)
local holsterEmotesMenu = VUI:CreateSubMenu(styleradioMenu, "Sortie d'arme", defaultBanner, true)
local invoicesMenu = VUI:CreateSubMenu(main, "Mes Factures", defaultBanner, true)
local paymentsMenu = VUI:CreateSubMenu(invoicesMenu, "Payer Factures", defaultBanner, true)
local weaponComponentsMenu = VUI:CreateSubMenu(main, "Composants d'armes", defaultBanner, true)
local weaponDetailMenu = VUI:CreateSubMenu(weaponComponentsMenu, "Détails de l'arme", defaultBanner, true)
local propsBuilderMenu = VUI:CreateSubMenu(main, "Props Builder", defaultBanner, true)
local createVipPropMenu = VUI:CreateSubMenu(propsBuilderMenu, "Créer un Props", defaultBanner, true)
local categorySelectionMenu = VUI:CreateSubMenu(createVipPropMenu, "CATÉGORIES", defaultBanner, true)
local manageMyPropsMenu = VUI:CreateSubMenu(propsBuilderMenu, "Gérer mes props", defaultBanner, true)
local rockstarEditorMenu = VUI:CreateSubMenu(main, "Rockstar Editor", defaultBanner, true)

-- ==========================================
--      WEAPON EMOTES MENU CALLBACKS
-- ==========================================

-- Convertir aimStyles en table ordonnée pour l'indexation
aimStylesOrdered = {
    {label = "Par défaut", animSet = "Default"},
    {label = "Gangster", animSet = "Gang1H"},
    {label = "Cowboy", animSet = "Hillbilly"},
    {label = "Tactique", animSet = "Franklin"}
}

holsterStylesOrdered = {
    {label = "Par défaut", value = "default"},
    {label = "Flic", value = "SideHolsterAnimation"},
    {label = "Avant", value = "FrontHolsterAnimation"},
    {label = "Jambe", value = "SideLegHolsterAnimation"},
    {label = "Abdomen", value = "AbdomenHolsterAnimation"},
}

local currentHolsterStyle = GetResourceKvpString("holster_style_label") or "Par défaut"

-- Les callbacks OnOpen/OnClose/OnIndexChange sont définis plus bas dans le fichier (lignes ~2304+)
-- car ils doivent être après toutes les définitions de fonctions render*

-- ==========================================
--           MAIN MENU RENDERING
-- ==========================================

local function renderMainMenu()
    local playerData = getDocumentsData()

    -- ========== MES INFORMATIONS ==========
    main.Separator("Mes informations")

    -- Job
    main.Title("Métier : " .. (playerData.job and playerData.job.label or "Aucun"))

    -- Faction
    local hasFaction = playerData.faction and playerData.faction.name ~= "nocrew"
   main.Title("Faction : " .. (hasFaction and playerData.faction.label or "Aucune"))

    -- ========== MES DOCUMENTS & FINANCES ==========
    main.Separator("Documents & Finances")

    -- Documents
    main.Button("Mes Documents", "Carte ID, Permis, PPA", nil, "chevron", false, function()
    end, documentsMenu)

    -- Factures
    main.Button("Mes Factures", "Consulter et payer", nil, "chevron", false, function()
    end, invoicesMenu, nil)

    -- ========== VÉHICULES ==========
    main.Separator("Véhicules")

    main.Button("Mes véhicules", "Donner ou vendre un véhicule", nil, "chevron", false, function()
    end, vehiclesMenu)

    -- ========== PARAMÈTRES ==========
    main.Separator("Paramètres")

    -- Options visuelles
    main.Button("Options Visuelles", "Cinéma, HUD, Minimap", nil, "chevron", false, function()
    end, visualOptionsMenu)

    main.Button("Options VUI (menu)", "Sons, positions des interfaces", nil, "chevron", false, function()
    end, vuiOptionsMenu)

    main.Button("Options Streamer", "Mode streamer, masquer les nouveaux joueurs", nil, "chevron", false, function()
    end, streamerOptionsMenu)

    -- Animations
    main.Button("Animations", "Radio, Armes", nil, "chevron", false, function()
    end, styleradioMenu)

    -- Composants d'armes
    main.Button("Composants d'armes", "Gérer vos armes et composants", nil, "chevron", false, function()
    end, weaponComponentsMenu)

    -- ========== OUTILS ==========
    main.Separator("Outils")

    -- Carte des territoires
    main.Button("Carte des territoires", "Voir les zones de la ville", nil, nil, false, function()
        main.close()
        OpenPublicTerritoriesMap()
    end)

    -- FreeCam (version sans traversée de murs) — la version VIP avec free-fly est dans le menu F3
    main.Button("FreeCam", "Caméra libre autour de votre personnage", nil, nil, false, function()
        main.close()
        activateFreeCam(true)
    end)

    -- Rockstar Editor
    main.Button("Rockstar Editor", "Enregistrer le jeu", nil, "chevron", false, function()
    end, rockstarEditorMenu)

end

-- ==========================================
--         DOCUMENTS MENU RENDERING
-- ==========================================

local function renderDocumentsMenu()
    local docs = getDocumentsData()

    documentsMenu.Separator("Carte d'identité")

    documentsMenu.Button("Regarder ma carte d'identité", "", nil, nil, false, function()
        documentsMenu.close()
        showPlayerDocument("identity", false)
    end)

    documentsMenu.Button("Montrer ma carte d'identité", "À la personne proche", nil, nil, false, function()
        documentsMenu.close()
        showPlayerDocument("identity", true)
    end)

    -- Driver License (single card with categories)
    documentsMenu.Separator("Permis de conduire")

    -- Fetch DVM licenses once for the menu
    local dvmLicenses = TriggerServerCallback("dvm:getPlayerLicensesForDocument")
    local hasAnyLicense = dvmLicenses and #dvmLicenses > 0

    -- Build status string showing which categories are owned
    local statusParts = {}
    if dvmLicenses then
        for _, dvmLicense in ipairs(dvmLicenses) do
            if dvmLicense.license_type == "motorcycle" then table.insert(statusParts, "A")
            elseif dvmLicense.license_type == "car" then table.insert(statusParts, "B")
            elseif dvmLicense.license_type == "truck" then table.insert(statusParts, "C")
            end
        end
    end
    table.sort(statusParts)
    local statusStr = #statusParts > 0 and table.concat(statusParts, ", ") or "Aucun permis"

   documentsMenu.Button("Regarder mon Permis de conduire", statusStr, nil, nil, false, function()
        if hasAnyLicense then
            documentsMenu.close()
            showPlayerDocument("driver", false)
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez aucun permis de conduire" })
        end
    end)

    documentsMenu.Button("Montrer mon Permis de conduire", "À la personne proche", nil, nil, false, function()

        if hasAnyLicense then
            documentsMenu.close()
            showPlayerDocument("driver", true)
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez aucun permis de conduire" })
        end
    end)

    -- PPA Léger (Light Weapon Permit)
    documentsMenu.Separator("Port d'arme - Catégorie Légère")

    local hasPPALeger = docs.licenses and docs.licenses["ppa_leger"]

    documentsMenu.Button("Regarder mon PPA Léger",
            hasPPALeger and "Valide" or "Non possédé",
            nil, nil, false, function()
                if hasPPALeger then
                    documentsMenu.close()
                    showPlayerDocument("weapon_leger", false)
                else
                    VFW.ShowNotification({
                        type = 'ROUGE',
                        content = "Vous n'avez pas de PPA Léger"
                   })
                end
            end)

    if hasPPALeger then
        documentsMenu.Button("Montrer mon PPA Léger", "À la personne proche", nil, nil, false, function()
            documentsMenu.close()
            showPlayerDocument("weapon_leger", true)
        end)
    end

    -- PPA Lourd (Heavy Weapon Permit)
    documentsMenu.Separator("Port d'arme - Catégorie Lourde")

    local hasPPALourd = docs.licenses and docs.licenses["ppa_lourd"]

    documentsMenu.Button("Regarder mon PPA Lourd",
            hasPPALourd and "Valide" or "Non possédé",
            nil, nil, false, function()
                if hasPPALourd then
                    documentsMenu.close()
                    showPlayerDocument("weapon_lourd", false)
                else
                    VFW.ShowNotification({
                        type = 'ROUGE',
                        content = "Vous n'avez pas de PPA Lourd"
                   })
                end
            end)

    if hasPPALourd then
        documentsMenu.Button("Montrer mon PPA Lourd", "À la personne proche", nil, nil, false, function()
            documentsMenu.close()
            showPlayerDocument("weapon_lourd", true)
        end)
    end

    -- Company Card
    documentsMenu.Separator("Carte Entreprise")

    local jobName = docs.job and docs.job.name or nil
    local isUnemployed = not jobName or jobName == "unemployed"
   local jobDisplayLabel = isUnemployed and "Demandeur d'emploi" or docs.job.label
    local gradeDisplayLabel = isUnemployed and "" or docs.job.grade_label
    local cardStatusStr = isUnemployed and "Demandeur d'emploi" or string.format("%s - %s", docs.job.label, docs.job.grade_label)

    documentsMenu.Button("Regarder ma carte entreprise",
            cardStatusStr,
            nil, nil, false, function()
                documentsMenu.close()
                showPlayerDocument("job", false)
            end)

    documentsMenu.Button("Montrer ma carte entreprise",
            "À la personne proche",
            nil, nil, false, function()
                documentsMenu.close()
                showPlayerDocument("job", true)
            end)

    local hasCayoVisa = docs.licenses and docs.licenses["cayo_visa"]
    if hasCayoVisa then
        documentsMenu.Separator("Visa de Cayo Perico")

        documentsMenu.Button("Regarder mon Visa de Cayo", "Valide", nil, nil, false, function()
            documentsMenu.close()
            showPlayerDocument("cayo_visa", false)
        end)

        documentsMenu.Button("Montrer mon Visa de Cayo", "À la personne proche", nil, nil, false, function()
            documentsMenu.close()
            showPlayerDocument("cayo_visa", true)
        end)
    end
end

-- ==========================================
--         VEHICLES MENU RENDERING
-- ==========================================

local function getVehicleDisplayLabel(model)
    if type(model) ~= "string" or model == "" then return "Véhicule" end
    if Garage and type(Garage.GetVehicleLabel) == "function" then
        local label = Garage.GetVehicleLabel(model)
        if label and label ~= "" then return label end
    end
    local make = GetMakeNameFromVehicleModel(model) or ""
   if make == "NULL" then make = "" end
    local name = GetLabelText(model) or model
    if name == "NULL" or name == "" then name = model end
    if make ~= "" then return make .. " " .. name end
    return name
end

local giveContext = { vehicles = nil, selected = nil, selectedLabel = nil }
local sellContext = { vehicles = nil, selected = nil, selectedLabel = nil }

local function fetchPersonalVehicles()
    local vehicles = TriggerServerCallback("garage:getAllPlayerVehicles")
    if not vehicles or #vehicles == 0 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez aucun véhicule" })
        return nil
    end
    return vehicles
end

local function fetchNearbyPlayerOptions()
    local nearbyPlayers = VFW.Game.GetPlayersInArea(GetEntityCoords(VFW.PlayerData.ped), 5.0, true)
    if not nearbyPlayers or #nearbyPlayers == 0 then return nil end
    local serverIds = {}
    for i = 1, #nearbyPlayers do
        serverIds[#serverIds + 1] = GetPlayerServerId(nearbyPlayers[i])
    end
    local names = TriggerServerCallback("vfw:vehicle:resolvePlayerNames", serverIds) or {}
    local options = {}
    for i = 1, #serverIds do
        local sid = serverIds[i]
        local firstName = names[tostring(sid)]
        if firstName then
            options[#options + 1] = { label = firstName, serverId = sid }
        end
    end
    if #options == 0 then return nil end
    return options
end

local function renderGiveSelectVehicleMenu()
    giveContext.vehicles = fetchPersonalVehicles()
    if not giveContext.vehicles then
        giveSelectVehicleMenu.Separator("Aucun véhicule")
        return
    end
    giveSelectVehicleMenu.Separator("Sélectionnez un véhicule")
    for i = 1, #giveContext.vehicles do
        local v = giveContext.vehicles[i]
        local label = getVehicleDisplayLabel(v.vehName or v.model)
        giveSelectVehicleMenu.Button(label, "Plaque : " .. v.plate, nil, "chevron", false, function()
            giveContext.selected = v
            giveContext.selectedLabel = label
        end, giveSelectPlayerMenu)
    end
end

local function renderGiveSelectPlayerMenu()
    if not giveContext.selected then
        giveSelectPlayerMenu.Separator("Aucun véhicule sélectionné")
        return
    end
    local options = fetchNearbyPlayerOptions()
    if not options then
        giveSelectPlayerMenu.Separator("Aucun joueur à proximité")
        return
    end
    giveSelectPlayerMenu.Separator("Sélectionnez le destinataire")
    for i = 1, #options do
        local opt = options[i]
        giveSelectPlayerMenu.Button(opt.label, "Donner le véhicule à ce joueur", nil, nil, false, function()
            local confirmed = VFW.Nui.ConfirmPopup(
                "Donner le véhicule",
                string.format("Voulez-vous vraiment donner %s (%s) à %s ? Cette action est définitive.", giveContext.selectedLabel or "ce véhicule", giveContext.selected.plate, opt.label),
                "Confirmer",
                "Annuler"
           )
            if not confirmed then return end
            TriggerServerEvent("garage:changeVehicleOwner", giveContext.selected.plate, opt.serverId)
            VFW.ShowNotification({ type = 'VERT', content = "Véhicule donné à " .. opt.label })
            giveContext.selected = nil
            giveContext.selectedLabel = nil
            vehiclesMenu.close()
        end)
    end
end

local function renderSellSelectVehicleMenu()
    sellContext.vehicles = fetchPersonalVehicles()
    if not sellContext.vehicles then
        sellSelectVehicleMenu.Separator("Aucun véhicule")
        return
    end
    sellSelectVehicleMenu.Separator("Sélectionnez un véhicule")
    for i = 1, #sellContext.vehicles do
        local v = sellContext.vehicles[i]
        local label = getVehicleDisplayLabel(v.vehName or v.model)
        sellSelectVehicleMenu.Button(label, "Plaque : " .. v.plate, nil, "chevron", false, function()
            sellContext.selected = v
            sellContext.selectedLabel = label
        end, sellSelectPlayerMenu)
    end
end

local function renderSellSelectPlayerMenu()
    if not sellContext.selected then
        sellSelectPlayerMenu.Separator("Aucun véhicule sélectionné")
        return
    end
    local options = fetchNearbyPlayerOptions()
    if not options then
        sellSelectPlayerMenu.Separator("Aucun joueur à proximité")
        return
    end
    sellSelectPlayerMenu.Separator("Sélectionnez l'acheteur")
    for i = 1, #options do
        local opt = options[i]
        sellSelectPlayerMenu.Button(opt.label, "Proposer la vente à ce joueur", nil, nil, false, function()
            local priceStr = VFW.Nui.KeyboardInput(true, "Prix de vente en " .. LOCALE.currencySymbol)
            if not priceStr or priceStr == "" then return end
            local price = tonumber(priceStr)
            if not price or price <= 0 or price > 9999999 then
                VFW.ShowNotification({ type = 'ROUGE', content = "Ce prix n'est pas valide" })
                return
            end
            price = math.floor(price)
            local confirmed = VFW.Nui.ConfirmPopup(
                "Proposer la vente",
                string.format("Voulez-vous proposer %s (%s) à %s pour %s ?", sellContext.selectedLabel or "ce véhicule", sellContext.selected.plate, opt.label, VFW.Math.FormatMoney(price)),
                "Envoyer",
                "Annuler"
           )
            if not confirmed then return end
            TriggerServerEvent("vfw:vehicle:proposeSale", opt.serverId, sellContext.selected.plate, price, sellContext.selectedLabel)
            VFW.ShowNotification({ type = 'JAUNE', content = "Offre envoyée à " .. opt.label })
            sellContext.selected = nil
            sellContext.selectedLabel = nil
            vehiclesMenu.close()
        end)
    end
end

local function renderVehiclesMenu()
    vehiclesMenu.Separator("Actions")

    vehiclesMenu.Button("Donner un véhicule", "Transférer la propriété à un joueur proche", nil, "chevron", false, function()
        giveContext.selected = nil
        giveContext.selectedLabel = nil
    end, giveSelectVehicleMenu)

    vehiclesMenu.Button("Vendre un véhicule", "Proposer la vente à un joueur proche", nil, "chevron", false, function()
        sellContext.selected = nil
        sellContext.selectedLabel = nil
    end, sellSelectVehicleMenu)
end

local saleOfferActive = false
local saleOfferResolver = nil

RegisterNUICallback("vehicleSaleOffer:response", function(data, cb)
    cb({})
    if saleOfferResolver then
        saleOfferResolver(data and data.choice or "refuse")
        saleOfferResolver = nil
    end
end)

RegisterNetEvent("vfw:vehicle:receiveSaleOffer", function(offer)
    if not offer then return end
    if saleOfferActive then
        TriggerServerEvent("vfw:vehicle:respondSale", false, nil)
        return
    end
    saleOfferActive = true

    local sellerName <const> = offer.sellerName or "Un joueur"
   local vehicleLabel <const> = offer.vehicleLabel or "un véhicule"
   local plate <const> = offer.plate or ""
   local price <const> = tonumber(offer.price) or 0

    VFW.Nui.Focus(true, true)
    SendNUIMessage({
        action = "nui:vehicleSaleOffer:open",
        data = {
            sellerName = sellerName,
            vehicleLabel = vehicleLabel,
            plate = plate,
            price = price,
        }
    })

    local p = promise.new()
    saleOfferResolver = function(result) p:resolve(result) end
    local choice = Citizen.Await(p)

    VFW.Nui.Focus(false, false)
    saleOfferActive = false

    if choice == "cash" or choice == "bank" then
        TriggerServerEvent("vfw:vehicle:respondSale", true, choice)
    else
        TriggerServerEvent("vfw:vehicle:respondSale", false, nil)
    end
end)

RegisterNetEvent("vfw:vehicle:saleResult", function(success, message)
    VFW.ShowNotification({
        type = success and 'VERT' or 'ROUGE',
        content = message or (success and "Transaction effectuée" or "Transaction échouée")
    })
end)

-- ==========================================
--      VISUAL OPTIONS MENU RENDERING
-- ==========================================

local function renderVuiOptionsMenu()
    vuiOptionsMenu.Separator("Interface VUI")

    vuiOptionsMenu.Checkbox("Sons du menu", "Activer/désactiver les sons VUI", false, vuiSoundEnabled, function(checked)
        vuiSoundEnabled = checked
        SetResourceKvp("vui_sound_enabled", checked and "1" or "0")
        exports["VUI"]:SetSoundEnabled(checked)
    end)

    vuiOptionsMenu.Button("Déplacer les interfaces", "Tes positions perso. Tant que tu n'as pas validé, tu suis le layout serveur", nil, "chevron", false, function()
        CreateThread(function()
            Wait(40)
            pcall(function()
                exports["VUI"]:CloseAll()
            end)
            Wait(80)
            if VFW.HudLayout and VFW.HudLayout.StartEditor then
                VFW.HudLayout.StartEditor()
            end
        end)
    end)

    vuiOptionsMenu.Button("Réinitialiser les positions", "Effacer tes positions perso et suivre le layout serveur", nil, "chevron", false, function()
        if VFW.HudLayout and VFW.HudLayout.Reset then
            VFW.HudLayout.Reset()
        end
    end)

    local currentMaxItems = VUI:GetMaxItems()
    vuiOptionsMenu.Slider("Nombre de boutons visibles", currentMaxItems, 4, 15, 1, "Items affichés simultanément dans les menus", false, function(value)
        VUI:SetMaxItems(value)
    end)

    vuiOptionsMenu.Separator("Volume Médias")

    local savedXVol = GetResourceKvpFloat("xsound_master_volume")
    if not savedXVol or savedXVol <= 0 then savedXVol = 1.0 end
    local xVolPercent = math.floor(savedXVol * 100 + 0.5)

    vuiOptionsMenu.Slider("Volume xSound", xVolPercent, 0, 100, 5, "Boombox, radios et médias", false, function(value)
        local clamped = math.max(0, math.min(100, value))
        local normalized = clamped / 100
        SetResourceKvpFloat("xsound_master_volume", normalized)
        exports.xsound:setMasterVolume(normalized)
    end)
end

local function renderVisualOptionsMenu()
    visualOptionsMenu.Separator("Thème HUD")

    local themeNames = { "Neon", "Minimal", "Cercles", "Cercles Vertical" }
    local themeValues = { "neon", "minimal", "circles", "circles-v" }
    local currentThemeIndex = 1
    local savedTheme = GetResourceKvpString("hud_theme") or "neon"
   for i, v in ipairs(themeValues) do
        if v == savedTheme then currentThemeIndex = i break end
    end

    visualOptionsMenu.List("Style du HUD", "Choisir l'apparence des barres de statut", false, themeNames, currentThemeIndex, function(index, value)
        local theme = themeValues[index]
        TriggerEvent("vfw:statusHUD:setTheme", theme)
    end)

    local hudColorDefs = {
        { key = "hunger", label = "Couleur Faim",    icon = "", default = { 224, 184, 75 } },
        { key = "thirst", label = "Couleur Soif",    icon = "", default = { 90,  167, 230 } },
        { key = "oxygen", label = "Couleur Oxygène", icon = "", default = { 79,  195, 247 } },
    }

    for _, def in ipairs(hudColorDefs) do
        local stored = GetResourceKvpString("hud_color_" .. def.key)
        local r, g, b = def.default[1], def.default[2], def.default[3]
        if stored then
            local sr, sg, sb = stored:match("^(%d+),(%d+),(%d+)$")
            if sr then r, g, b = tonumber(sr), tonumber(sg), tonumber(sb) end
        end
        local origR, origG, origB = r, g, b
        local title = ("%s %s"):format(def.icon, def.label)
        local subtitle = ("Choisir la couleur (%d, %d, %d)"):format(r, g, b)
        visualOptionsMenu.Button(title, subtitle, nil, "chevron", false, function()
            visualOptionsMenu.RoleColorPicker(r, g, b, def.label:upper(),
                function(nr, ng, nb)
                    TriggerEvent("vfw:statusHUD:setColor", def.key, nr, ng, nb)
                end,
                function(nr, ng, nb)
                    TriggerEvent("vfw:statusHUD:setColor", def.key, nr, ng, nb)
                    visualOptionsMenu.refresh()
                end,
                function()
                    TriggerEvent("vfw:statusHUD:setColor", def.key, origR, origG, origB)
                end
            )
        end)
    end

    visualOptionsMenu.Button(":refresh: Remettre les couleurs par défaut", "Réinitialise faim, soif et oxygène", nil, "chevron", false, function()
        TriggerEvent("vfw:statusHUD:resetColors")
        visualOptionsMenu.refresh()
    end)

    -- Style des barres de vie / armure
    local hpStyleNames  = { "Standard", "Large" }
    local hpStyleValues = { "default", "wide" }
    local savedHpStyle  = GetResourceKvpString("hud_hp_style") or "default"
   local hpStyleIndex  = 1
    for i, v in ipairs(hpStyleValues) do
        if v == savedHpStyle then hpStyleIndex = i break end
    end

    visualOptionsMenu.List("Style barres vie/armure", "Standard ou large (toute la minimap)", false, hpStyleNames, hpStyleIndex, function(index)
        TriggerEvent("vfw:statusHUD:setHPStyle", hpStyleValues[index])
    end)

    visualOptionsMenu.Separator("Options d'affichage")

    visualOptionsMenu.Checkbox("Mode Cinéma", "Bandes noires", false, cinemaMode, function(checked)
        toggleCinemaMode(checked)
    end)

    visualOptionsMenu.Button("Déplacer les interfaces", "Tes positions perso. Tant que tu n'as pas validé, tu suis le layout serveur", nil, "chevron", false, function()
        CreateThread(function()
            Wait(40)
            pcall(function()
                exports["VUI"]:CloseAll()
            end)
            Wait(80)
            if VFW.HudLayout and VFW.HudLayout.StartEditor then
                VFW.HudLayout.StartEditor()
            end
        end)
    end)

    visualOptionsMenu.Checkbox("Masquer Minimap", "Cache la minimap (carte)", false, hideMinimap, function(checked)
        toggleMinimap(checked)
    end)

    visualOptionsMenu.Checkbox("Masquer HUD", "Soif, faim, vie et infos", false, hideHUD, function(checked)
        toggleHUD(checked)
    end)

    visualOptionsMenu.Checkbox("Masquer Logo Serveur", "Cache le logo " .. VFW.BrandName() .. " en haut", false, hideLogo, function(checked)
        toggleLogo(checked)
    end)

    visualOptionsMenu.Checkbox("Masquer Informations IG", "Cache nom/prénom et ID en haut", false, hideIGInfo, function(checked)
        toggleIGInfo(checked)
    end)

    visualOptionsMenu.Checkbox("Masquer Chat Vocal", "Cache l'indicateur de voix", false, hideVoiceChat, function(checked)
        toggleVoiceChat(checked)
    end)

    visualOptionsMenu.Checkbox("Boussole", "Afficher une boussole en haut de l'écran", false, compassEnabled, function(checked)
        toggleCompass(checked)
    end)

    visualOptionsMenu.Checkbox("Détails portes", "Afficher le texte 'Verrouillée - Appuyez sur E'", false, doorlockDetailEnabled, function(checked)
        doorlockDetailEnabled = checked
        SetResourceKvp("doorlock_detail_enabled", checked and "1" or "0")
        TriggerEvent("core:doorlock:setDetailMode", checked)
    end)

    if VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["staff_menu"] then
        visualOptionsMenu.Checkbox("Masquer Déconnexions", "Cache les messages de déconnexion des joueurs", false, VFW.HidePlayerDroppedText, function(checked)
            VFW.HidePlayerDroppedText = checked
            if checked then
                VFW.ShowNotification({ type = 'VERT', content = "Affichage des déconnexions désactivé." })
            else
                VFW.ShowNotification({ type = 'VERT', content = "Affichage des déconnexions activé." })
            end
        end)
    end
end

-- ==========================================
--      RADIO STYLE MENU RENDERING
-- ==========================================
-- Diccionario de animaciones de radio
local radioAnimations = {
    ["Radio - Épaule"] = {
        dict = "random@arrests",
        anim = "generic_radio_chatter"
   },
    ["Radio - Poitrine"] = {
        dict = "anim@cop_mic_pose_002",
        anim = "chest_mic"
   },
    ["Radio - Frontal"] = {
        dict = "anim@male@holding_radio",
        anim = "holding_radio_clip"
   },
    ["Radio - Oreille"] = {
        dict = "cellphone@",
        anim = "cellphone_call_listen_base"
   },
    -- Custom Radio Animations Pack (Pazeee_NewRadioEmotes)
    ["Radio - Front Droit"] = {
        dict = "pazeee@radioa@animations",
        anim = "pazeee@radioa@clip"
   },
    ["Radio - Front Gauche"] = {
        dict = "pazeee@radiob@animations",
        anim = "pazeee@radiob@clip"
   },
    ["Radio - Côté Droit"] = {
        dict = "pazeee@radioc@animations",
        anim = "pazeee@radioc@clip"
   },
    ["Radio - Côté Gauche"] = {
        dict = "pazeee@radiod@animations",
        anim = "pazeee@radiod@clip"
   },
    ["Radio - Couvert Droit"] = {
        dict = "pazeee@radioe@animations",
        anim = "pazeee@radioe@clip"
   },
    ["Radio - Couvert Gauche"] = {
        dict = "pazeee@radiof@animations",
        anim = "pazeee@radiof@clip"
   },
    ["Radio - Épaule Droite"] = {
        dict = "pazeee@radiog@animations",
        anim = "pazeee@radiog@clip"
   },
    ["Radio - Épaule Gauche"] = {
        dict = "pazeee@radioh@animations",
        anim = "pazeee@radioh@clip"
   },
    ["Radio - Mauvais Signal Droit"] = {
        dict = "pazeee@radioi@animations",
        anim = "pazeee@radioi@clip"
   },
    ["Radio - Cassé Droit"] = {
        dict = "pazeee@radioj@animations",
        anim = "pazeee@radioj@clip"
   },
    ["Radio - Poitrine Droite"] = {
        dict = "pazeee@radiok@animations",
        anim = "pazeee@radiok@clip"
   },
    ["Radio - Poitrine Gauche"] = {
        dict = "pazeee@radiol@animations",
        anim = "pazeee@radiol@clip"
   },
    ["Radio - Oreillette Droite"] = {
        dict = "pazeee@radiom@animations",
        anim = "pazeee@radiom@clip"
   },
    ["Radio - Oreillette Gauche"] = {
        dict = "pazeee@radion@animations",
        anim = "pazeee@radion@clip"
   },
    ["Radio - Montre Gauche"] = {
        dict = "pazeee@radioo@animations",
        anim = "pazeee@radioo@clip"
   },
    ["Radio - Flottante Gauche"] = {
        dict = "pazeee@radiop@animations",
        anim = "pazeee@radiop@clip"
   }
}

local function renderStyleradioMenu()
    styleradioMenu.Separator("Choisir type d'animation")

    styleradioMenu.Button("Emote radio", "Changer le style radio", nil, "chevron", false, function()
    end, radioEmotesMenu)

    styleradioMenu.Button("Animation de visée", "Changer le style de tir", nil, "chevron", false, function()
    end, weaponEmotesMenu)

    styleradioMenu.Button("Sortie d'arme", "Changer l'animation de dégainé", nil, "chevron", false, function()
    end, holsterEmotesMenu)
end

local function renderRadioEmotesMenu()
    radioEmotesMenu.Separator("Style d'animation radio")

    local savedDict = GetResourceKvpString("radioAnimDict")
    local savedAnim = GetResourceKvpString("radioAnimName")
    local currentRadioStyle = "Radio - Épaule"

   if savedDict and savedAnim then
        for style, data in pairs(radioAnimations) do
            if data.dict == savedDict and data.anim == savedAnim then
                currentRadioStyle = style
                break
            end
        end
    else
        SetResourceKvp("radioAnimDict", "random@arrests")
        SetResourceKvp("radioAnimName", "generic_radio_chatter")
    end

    for style, animData in pairs(radioAnimations) do
        local isSelected = (currentRadioStyle == style)

        radioEmotesMenu.Button(style,
                isSelected and "Sélectionné" or "Survolez pour prévisualiser",
                nil, isSelected and "play" or nil, false, function()
                    currentRadioStyle = style

                    if style == "Radio - Oreille" then
                        SetResourceKvp("radioAnimDict", animData.dict)
                        SetResourceKvp("radioAnimName", animData.anim)

                        VFW.ShowNotification({
                            type = 'VERT',
                            content = "Style radio changé : Oreille (sans animation)"
                       })
                        radioEmotesMenu.refresh()
                        return
                    end

                    RequestAnimDict(animData.dict)
                    local timeout = 0
                    while not HasAnimDictLoaded(animData.dict) do
                        Wait(50)
                        timeout = timeout + 1
                        if timeout > 200 then
                            VFW.ShowNotification({
                                type = 'ROUGE',
                                content = "Erreur lors du chargement de l'animation."
                           })
                            return
                        end
                    end

                    TaskPlayAnim(PlayerPedId(), animData.dict, animData.anim, 8.0, -8.0, -1, 49, 0, false, false, false)

                    SetResourceKvp("radioAnimDict", animData.dict)
                    SetResourceKvp("radioAnimName", animData.anim)

                    VFW.ShowNotification({
                        type = 'VERT',
                        content = "Style radio changé : " .. style
                    })

                    radioEmotesMenu.refresh()
                end)
    end
end

-- ==========================================
--      WEAPON EMOTE PREVIEW FUNCTIONS
-- ==========================================

local function CleanupWeaponEmotePreview()
    weaponEmotePreviewActive = false

    if weaponPreviewThread then
        weaponPreviewThread = nil
    end

    if weaponPreviewClone and DoesEntityExist(weaponPreviewClone) then
        DeletePed(weaponPreviewClone)
        weaponPreviewClone = nil
    end

    currentWeaponPreviewStyle = nil
end

local function CreateWeaponEmotePreview(animSet)
    -- Cleanup d'une éventuelle preview existante
    if weaponPreviewClone and DoesEntityExist(weaponPreviewClone) then
        DeletePed(weaponPreviewClone)
        weaponPreviewClone = nil
    end

    local playerPed = VFW.PlayerData.ped
    if not playerPed or not DoesEntityExist(playerPed) then
        return
    end

    -- Créer le clone du joueur
    weaponPreviewClone = ClonePed(playerPed, false, true, true)

    if not weaponPreviewClone or not DoesEntityExist(weaponPreviewClone) then
        return
    end

    -- Configuration du clone
    SetPedConfigFlag(weaponPreviewClone, 35, false) -- Disable audio steps
    SetBlockingOfNonTemporaryEvents(weaponPreviewClone, true)
    SetEntityInvincible(weaponPreviewClone, true)
    SetEntityCollision(weaponPreviewClone, true, false)
    SetPedConfigFlag(weaponPreviewClone, 60, true) -- No collision with player ped
    SetEntityAlpha(weaponPreviewClone, 204, false)
    SetPedCanRagdoll(weaponPreviewClone, false)
    SetPedCanBeTargetted(weaponPreviewClone, false)

    -- Position initiale : 1.5m devant, posé sur le sol, orienté face au joueur (180°)
    local initHeading = GetEntityHeading(playerPed)
    local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.5, 0.0)
    local groundZ = spawnPos.z
    local found, gz = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, groundZ + 2.0, false)
    if found then groundZ = gz end
    SetEntityCoords(weaponPreviewClone, spawnPos.x, spawnPos.y, groundZ, false, false, false, true)
    SetEntityHeading(weaponPreviewClone, initHeading + 180.0)
    SetEntityVisible(weaponPreviewClone, true)

    -- Le repositionnement parallèle est géré par le thread (offset 1.5m droite)

    -- Donner une arme au clone AVANT d'appliquer le style (sinon l'arme reset le style)
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    if currentWeapon == joaat("WEAPON_UNARMED") then
        currentWeapon = joaat("WEAPON_PISTOL")
    end

    GiveWeaponToPed(weaponPreviewClone, currentWeapon, 999, false, true)
    SetCurrentPedWeapon(weaponPreviewClone, currentWeapon, true)

    -- Appliquer le style d'animation APRÈS avoir donné l'arme
    SetWeaponAnimationOverride(weaponPreviewClone, animSet)

    -- Faire viser le clone dans la même direction que le joueur
    local clone = weaponPreviewClone
    CreateThread(function()
        Wait(300)
        if clone and DoesEntityExist(clone) then
            local camRot = GetGameplayCamRot(2)
            local heading = camRot.z + 180.0
            local aimRad = math.rad(heading)
            local clonePos = GetEntityCoords(clone)
            TaskAimGunAtCoord(clone, clonePos.x + math.sin(aimRad) * 3.0, clonePos.y + math.cos(aimRad) * 3.0, clonePos.z + 0.1, -1, false, false)
        end
    end)
end

local function StartWeaponPreviewThread()
    if weaponPreviewThread then
        return
    end

    weaponPreviewThread = CreateThread(function()
        while weaponEmotePreviewActive do
            Wait(0)

            -- Vérifier si le joueur est mort
            if Death and (Death.isDead or VFW.PlayerData.dead) then
                CleanupWeaponEmotePreview()
                break
            end

            -- Désactiver certains contrôles pendant la preview
            DisableControlAction(0, 24, true) -- attack
            DisableControlAction(0, 25, true) -- aim
            DisableControlAction(0, 47, true) -- weapon wheel
            DisableControlAction(0, 263, true) -- melee attack

            -- Maintenir le clone devant le joueur avec GetOffsetFromEntityInWorldCoords
            if weaponPreviewClone and DoesEntityExist(weaponPreviewClone) then
                local playerPed = VFW.PlayerData.ped
                if playerPed and DoesEntityExist(playerPed) then
                    local heading = GetEntityHeading(playerPed)
                    local targetPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.5, 0.0)
                    local clonePos = GetEntityCoords(weaponPreviewClone)
                    -- Repositionner si dérive XY trop grande (désynchronisation)
                    local dist2D = #(vector2(targetPos.x, targetPos.y) - vector2(clonePos.x, clonePos.y))
                    if dist2D > 0.5 then
                        SetEntityCoords(weaponPreviewClone, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
                    end
                    SetEntityHeading(weaponPreviewClone, heading + 180.0)
                    -- Copier la vélocité pour que le clone suive les mouvements (marche, saut)
                    local vel = GetEntityVelocity(playerPed)
                    SetEntityVelocity(weaponPreviewClone, vel.x, vel.y, vel.z)
                end
            end
        end
    end)
end

-- aimStyles maintenant défini dans aimStylesOrdered (ligne ~781)
local currentAimStyle = GetResourceKvpString("aim_style_label") or "Par défaut"

local function renderWeaponEmotesMenu()
    weaponEmotesMenu.Separator(":eye: Prévisualisation active - Naviguez pour voir")

    for _, style in ipairs(aimStylesOrdered) do
        local isSelected = (currentAimStyle == style.label)

        weaponEmotesMenu.Button(style.label,
                isSelected and ":check: Sélectionné" or "Survolez pour prévisualiser",
                nil, nil, false, function()
                    currentAimStyle = style.label

                    local playerPed = PlayerPedId()
                    local currentWeapon = GetSelectedPedWeapon(playerPed)
                    local animSetToApply = style.animSet

                    -- Sauvegarder en KVP locale (pour re-application après changement d'arme)
                    SetResourceKvp("aim_style_animset", animSetToApply)
                    SetResourceKvp("aim_style_label", style.label)

                    -- Cycler l'arme PUIS appliquer le style (le cycle reset l'override sinon)
                    if currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
                        CreateThread(function()
                            SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
                            Wait(50)
                            SetCurrentPedWeapon(playerPed, currentWeapon, true)
                            Wait(50)
                            SetWeaponAnimationOverride(playerPed, animSetToApply)
                        end)
                    else
                        SetWeaponAnimationOverride(playerPed, animSetToApply)
                    end

                    -- Sync avec le serveur (persistance + broadcast aux autres joueurs)
                    TriggerServerEvent("vfw:weaponStyle:set", animSetToApply)

                    VFW.ShowNotification({
                        type = 'VERT',
                        content = "Style de visée changé : " .. style.label
                    })

                    weaponEmotesMenu.refresh()
                end)
    end
end

local function renderHolsterEmotesMenu()
    holsterEmotesMenu.Separator("Style de sortie d'arme")

    for _, style in ipairs(holsterStylesOrdered) do
        local isSelected = (currentHolsterStyle == style.label)

        holsterEmotesMenu.Button(style.label,
                isSelected and "Sélectionné" or nil,
                nil, isSelected and "check" or nil, false, function()
                    currentHolsterStyle = style.label

                    local value = style.value == "default" and nil or style.value
                    TriggerServerEvent('fb:character:setHolsterAnim', value)

                    SetResourceKvp("holster_style_label", style.label)
                    SetResourceKvp("holster_style_value", style.value)

                    VFW.ShowNotification({
                        type = 'VERT',
                        content = "Animation de sortie changée : " .. style.label
                    })

                    holsterEmotesMenu.refresh()
                end)
    end
end

-- ==========================================
--      ROCKSTAR EDITOR MENU RENDERING
-- ==========================================

local function renderRockstarEditorMenu()
    rockstarEditorMenu.Separator("Enregistrement")

    rockstarEditorMenu.Button("Lancer l'enregistrement", "Commencer à capturer", nil, nil, false, function()
        if rockstarActivate then
            VFW.ShowNotification({
                type = 'ORANGE',
                content = "L'enregistrement est déjà en cours"
           })
            return
        end
        rockstarActivate = true
        StartRecording(1)
        VFW.ShowNotification({
            type = 'VERT',
            content = "Enregistrement lancé"
       })
    end)

    rockstarEditorMenu.Button("Arrêter l'enregistrement", "Sauvegarder le clip", nil, nil, false, function()
        if not rockstarActivate then
            VFW.ShowNotification({
                type = 'ORANGE',
                content = "Aucun enregistrement en cours"
           })
            return
        end
        rockstarActivate = false
        StopRecordingAndSaveClip()
        VFW.ShowNotification({
            type = 'VERT',
            content = "Enregistrement sauvegardé"
       })
    end)

    rockstarEditorMenu.Separator("Gestion")

    rockstarEditorMenu.Button("Gérer les enregistrements", "Ouvrir l'éditeur Rockstar (vous serez déconnecté en quittant)", nil, nil, false, function()
        local currentTime = GetGameTimer()
        if currentTime - rockstarEditorConfirmTime < 5000 then
            rockstarEditorMenu.close()
            ActivateRockstarEditor()
        else
            rockstarEditorConfirmTime = currentTime
            VFW.ShowNotification({
                type = 'ORANGE',
                content = "Attention : quitter l'éditeur vous déconnectera du serveur. Cliquez à nouveau pour confirmer."
           })
        end
    end)
end

-- ==========================================
--       ANIMATIONS MENU RENDERING
-- ==========================================

local function renderAnimationsMenu()
    animationsMenu.Separator("Changement d'animations")

    -- Aim animations
    animationsMenu.List("Animation de visée", {
        "Par défaut",
        "Gangster",
        "Cowboy",
        "Tactique"
   }, 1, nil, function(index, value)
        currentAimAnimation = value

        -- Apply aim animation change
        if value == "Gangster" then
            SetWeaponAnimationOverride(PlayerPedId(), joaat("Gang1H"))
        elseif value == "Cowboy" then
            SetWeaponAnimationOverride(PlayerPedId(), joaat("Hillbilly"))
        elseif value == "Tactique" then
            SetWeaponAnimationOverride(PlayerPedId(), joaat("Default"))
        else
            SetWeaponAnimationOverride(PlayerPedId(), joaat("Default"))
        end

        VFW.ShowNotification({
            type = 'VERT',
            content = "Animation de visée changée : " .. value
        })
    end)
end

-- ==========================================
--        INVOICES MENU RENDERING
-- ==========================================


local formattedInvoiceFields = function(invoice)
    local invoicedItem = json.decode(invoice.items)
    if #invoicedItem == 0 then
        return {}
    end

    local formattedFields = {}
    for _, item in ipairs(invoicedItem) do
        table.insert(formattedFields, {
            icon = "fa-solid fa-box",
            text = item.quantity and string.format("%sx %s", item.quantity, item.name) or item.name
        })
    end

    table.insert(formattedFields, {
        icon = "fa-solid fa-dollar-sign",
        text = string.format("Total : %s", VFW.Math.FormatMoney(invoice.total))
    })

    table.insert(formattedFields, {
        icon = "fa-solid fa-calendar",
        text = string.format("Reçu le %s", invoice.date)
    })

    return formattedFields

end

local lastInvoiceSelected = nil
local lastInvoiceType = nil -- "bill" or "sams"

local function formattedSamsInvoiceFields(invoice)
    local invoicedItems = json.decode(invoice.items)
    if not invoicedItems or #invoicedItems == 0 then
        return {}
    end

    local formattedFields = {}
    for _, item in ipairs(invoicedItems) do
        table.insert(formattedFields, {
            icon = "fa-solid fa-kit-medical",
            text = item.quantity and string.format("%sx %s", item.quantity, item.name) or item.name
        })
    end

    table.insert(formattedFields, {
        icon = "fa-solid fa-dollar-sign",
        text = string.format("Total : %s", VFW.Math.FormatMoney(invoice.total))
    })

    table.insert(formattedFields, {
        icon = "fa-solid fa-hospital",
        text = string.format("Hôpital : %s", invoice.hospital == "pillbox" and "Pillbox Hill" or "Paleto Bay")
    })

    table.insert(formattedFields, {
        icon = "fa-solid fa-calendar",
        text = string.format("Reçu le %s", invoice.date)
    })

    return formattedFields
end

local function renderInvoicesMenu()
    local invoices = TriggerServerCallback("vfw:getInvoices")
    local samsInvoices = TriggerServerCallback("vfw:getSamsInvoices")

    local totalCount = (invoices and #invoices or 0) + (samsInvoices and #samsInvoices or 0)

    if totalCount == 0 then
        invoicesMenu.Separator("Aucune facture à payer")
        VFW.ShowNotification({
            type = 'JAUNE',
            content = "Vous n'avez aucune facture à payer."
       })
        return
    end

    -- Factures classiques
    if invoices and #invoices > 0 then
        invoicesMenu.Separator(string.format("Factures (%d)", #invoices))

        for _, invoice in ipairs(invoices) do
            invoicesMenu.Button(
                    string.format("Facture de %s", invoice.societyLabel or invoice.society),
                    string.format("%s - Par : %s", VFW.Math.FormatMoney(invoice.total), invoice.sender),
                    nil, nil, false,
                    function()
                        lastInvoiceSelected = invoice
                        lastInvoiceType = "bill"
                   end, paymentsMenu, nil, {
                        title = "Détails de la facture",
                        items = formattedInvoiceFields(invoice)
                    }
            )
        end
    end

    -- Factures SAMS
    if samsInvoices and #samsInvoices > 0 then
        invoicesMenu.Separator(string.format("Factures médicales (%d)", #samsInvoices))

        for _, invoice in ipairs(samsInvoices) do
            invoicesMenu.Button(
                    string.format("Facture SAMS - %s", invoice.hospital == "pillbox" and "Pillbox" or "Paleto"),
                    string.format("%s - Par : %s", VFW.Math.FormatMoney(invoice.total), invoice.createdBy),
                    nil, nil, false,
                    function()
                        lastInvoiceSelected = invoice
                        lastInvoiceType = "sams"
                   end, paymentsMenu, nil, {
                        title = "Détails de la facture médicale",
                        items = formattedSamsInvoiceFields(invoice)
                    }
            )
        end
    end
end

local function renderPaymentsMenu()
    if not lastInvoiceSelected then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Aucune facture sélectionnée."
       })
        return
    end

    paymentsMenu.Separator("Total : " .. VFW.Math.FormatMoney(lastInvoiceSelected.total))

    paymentsMenu.Button("Payer par carte bancaire", "", nil, nil, false, function()
        if lastInvoiceType == "sams" then
            TriggerServerEvent("vfw:samsInvoice:pay", lastInvoiceSelected.id, "bank")
        else
            TriggerServerEvent("vfw:invoice:pay", lastInvoiceSelected.id, "bank")
        end
        lastInvoiceSelected = nil
        lastInvoiceType = nil
        paymentsMenu.close()
    end)

    paymentsMenu.Button("Payer en cash", "", nil, nil, false, function()
        if lastInvoiceType == "sams" then
            TriggerServerEvent("vfw:samsInvoice:pay", lastInvoiceSelected.id, "cash")
        else
            TriggerServerEvent("vfw:invoice:pay", lastInvoiceSelected.id, "cash")
        end
        lastInvoiceSelected = nil
        lastInvoiceType = nil
        paymentsMenu.close()
    end)

end




-- ==========================================
--      WEAPON COMPONENTS MENU RENDERING
-- ==========================================

local weaponPreviewActive = false
weaponPreviewObject = nil
local weaponPreviewCam = nil
weaponPreviewRotation = 0.0
weaponPreviewRotationY = 0.0
local selectedWeaponForDetail = nil
local selectedWeaponItemForDetail = nil
local savedCamCoords = nil
local savedCamRot = nil

local function GetPlayerWeaponsFromInventory()
    local weapons = {}
    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return weapons
    end

    for _, item in ipairs(VFW.PlayerData.inventory) do
        if item.name and item.count > 0 then
            local weaponName = item.name:upper()
            if string.find(weaponName, "WEAPON_") then
                local weaponData = nil
                for _, w in ipairs(Config.Weapons) do
                    if w.name:upper() == weaponName then
                        weaponData = w
                        break
                    end
                end

                if weaponData and item.meta and item.meta.weaponId then
                    local itemData = VFW.Items and VFW.Items[item.name]
                    local label = itemData and itemData.label or weaponData.label

                    table.insert(weapons, {
                        item = item,
                        data = weaponData,
                        label = label,
                        equippedComponents = item.meta and item.meta.components or {}
                    })
                end
            end
        end
    end

    return weapons
end

function GetComponentLabel(componentHash, configLabel)
    local itemName = GetItemFromHash(componentHash)
    if itemName then
        local itemData = VFW.Items and VFW.Items[itemName]
        if itemData and itemData.label then
            return itemData.label
        end
        return itemName
    end
    return configLabel or componentHash
end

function CleanupWeaponPreview()
    weaponPreviewActive = false

    if weaponPreviewCam and DoesCamExist(weaponPreviewCam) then
        RenderScriptCams(false, true, 500, true, false)
        SetCamActive(weaponPreviewCam, false)
        DestroyCam(weaponPreviewCam, false)
        weaponPreviewCam = nil
    end

    if weaponPreviewObject and DoesEntityExist(weaponPreviewObject) then
        DeleteEntity(weaponPreviewObject)
        weaponPreviewObject = nil
    end

    weaponPreviewRotation = 0.0
    weaponPreviewRotationY = 0.0
    savedCamCoords = nil
    savedCamRot = nil
    currentWeaponName = nil
    currentWeaponPos = nil
    currentBaseRotZ = 0.0

    ClearPedTasks(PlayerPedId())
    EnableAllControlActions(0)
end

local currentWeaponName = nil
currentBaseRotZ = 0.0
local currentWeaponPos = nil
local isRefreshingWeaponMenu = false
local isUpdatingPreviewObject = false

function UpdateWeaponPreviewObject(weaponName, equippedComponents)
    if not weaponPreviewActive or not weaponPreviewCam then return false end

    isUpdatingPreviewObject = true

    local weaponHash = joaat(weaponName)
    RequestWeaponAsset(weaponHash, 31, 0)
    local timeout = 0
    while not HasWeaponAssetLoaded(weaponHash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if weaponPreviewObject and DoesEntityExist(weaponPreviewObject) then
        DeleteEntity(weaponPreviewObject)
        weaponPreviewObject = nil
    end

    if not currentWeaponPos then return false end

    weaponPreviewObject = CreateWeaponObject(weaponHash, 0, currentWeaponPos.x, currentWeaponPos.y, currentWeaponPos.z, false, 1.0, 0)

    if not weaponPreviewObject or weaponPreviewObject == 0 then
        local model = GetWeapontypeModel(weaponHash)
        if model ~= 0 then
            RequestModel(model)
            while not HasModelLoaded(model) and timeout < 100 do
                Wait(10)
                timeout = timeout + 1
            end
            weaponPreviewObject = CreateObject(model, currentWeaponPos.x, currentWeaponPos.y, currentWeaponPos.z, false, false, false)
            SetModelAsNoLongerNeeded(model)
        end
    end

    if not weaponPreviewObject or not DoesEntityExist(weaponPreviewObject) then
        isUpdatingPreviewObject = false
        return false
    end

    SetEntityCollision(weaponPreviewObject, false, false)
    FreezeEntityPosition(weaponPreviewObject, true)
    SetEntityAlpha(weaponPreviewObject, 255, false)
    SetEntityInvincible(weaponPreviewObject, true)

    Wait(0)

    if equippedComponents and #equippedComponents > 0 then
        for _, compHash in ipairs(equippedComponents) do
            local hash = compHash
            if type(compHash) == "string" then
                hash = GetHashKey(compHash)
            end
            local compModel = GetWeaponComponentTypeModel(hash)
            if compModel and compModel ~= 0 then
                RequestModel(compModel)
                local loadTimeout = 0
                while not HasModelLoaded(compModel) and loadTimeout < 50 do
                    Wait(0)
                    loadTimeout = loadTimeout + 1
                end
            end
            GiveWeaponComponentToWeaponObject(weaponPreviewObject, hash)
        end
    end

    SetEntityRotation(weaponPreviewObject, weaponPreviewRotationY, 0.0, currentBaseRotZ + weaponPreviewRotation, 2, true)

    isUpdatingPreviewObject = false
    return true
end

function CreateWeaponPreview2D(weaponName, weaponLabel, equippedComponents)
    CleanupWeaponPreview()

    currentWeaponName = weaponName
    local weaponHash = joaat(weaponName)

    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    TaskStandStill(ped, -1)
    Wait(300)

    RequestWeaponAsset(weaponHash, 31, 0)
    local timeout = 0
    while not HasWeaponAssetLoaded(weaponHash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)

    savedCamCoords = GetGameplayCamCoord()
    savedCamRot = GetGameplayCamRot(2)

    weaponPreviewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local camPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.8, 0.5)
    SetCamCoord(weaponPreviewCam, camPos.x, camPos.y, camPos.z)
    SetCamRot(weaponPreviewCam, 0.0, 0.0, pedHeading, 2)
    SetCamFov(weaponPreviewCam, 50.0)
    SetCamActive(weaponPreviewCam, true)
    RenderScriptCams(true, true, 500, true, false)

    local weaponNameUpper = weaponName:upper()
    local distance = 1.8
    if string.find(weaponNameUpper, "RIFLE") or string.find(weaponNameUpper, "SHOTGUN") or string.find(weaponNameUpper, "SNIPER") or string.find(weaponNameUpper, "MG") or string.find(weaponNameUpper, "MUSKET") or string.find(weaponNameUpper, "MINIGUN") then
        distance = 2.4
    end

    local weaponPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, distance, 0.5)
    currentWeaponPos = weaponPos

    weaponPreviewObject = CreateWeaponObject(weaponHash, 0, weaponPos.x, weaponPos.y, weaponPos.z, false, 1.0, 0)

    if not weaponPreviewObject or weaponPreviewObject == 0 then
        local model = GetWeapontypeModel(weaponHash)
        if model ~= 0 then
            RequestModel(model)
            while not HasModelLoaded(model) and timeout < 100 do
                Wait(10)
                timeout = timeout + 1
            end
            weaponPreviewObject = CreateObject(model, weaponPos.x, weaponPos.y, weaponPos.z, false, false, false)
            SetModelAsNoLongerNeeded(model)
        end
    end

    if not weaponPreviewObject or not DoesEntityExist(weaponPreviewObject) then
        CleanupWeaponPreview()
        return false
    end

    SetEntityCollision(weaponPreviewObject, false, false)
    FreezeEntityPosition(weaponPreviewObject, true)
    SetEntityAlpha(weaponPreviewObject, 255, false)
    SetEntityInvincible(weaponPreviewObject, true)

    if equippedComponents and #equippedComponents > 0 then
        for _, compHash in ipairs(equippedComponents) do
            local hash = compHash
            if type(compHash) == "string" then
                hash = GetHashKey(compHash)
            end
            local compModel = GetWeaponComponentTypeModel(hash)
            if compModel and compModel ~= 0 then
                RequestModel(compModel)
                local loadTimeout = 0
                while not HasModelLoaded(compModel) and loadTimeout < 50 do
                    Wait(0)
                    loadTimeout = loadTimeout + 1
                end
            end
            GiveWeaponComponentToWeaponObject(weaponPreviewObject, hash)
        end
    end

    local baseRotZ = pedHeading - 90.0
    currentBaseRotZ = baseRotZ
    SetEntityRotation(weaponPreviewObject, 0.0, 0.0, baseRotZ, 2, true)

    weaponPreviewActive = true
    weaponPreviewRotation = 0.0
    weaponPreviewRotationY = 0.0

    CreateThread(function()
        while weaponPreviewActive do
            Wait(0)

            if not isUpdatingPreviewObject then
                if not weaponPreviewObject or not DoesEntityExist(weaponPreviewObject) then
                    break
                end
            end

            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 24, true)
            EnableControlAction(0, 25, true)
            EnableControlAction(0, 172, true)
            EnableControlAction(0, 173, true)
            EnableControlAction(0, 174, true)
            EnableControlAction(0, 175, true)

            local mouseX = GetDisabledControlNormal(0, 1)
            local mouseY = GetDisabledControlNormal(0, 2)

            if math.abs(mouseX) > math.abs(mouseY) then
                if math.abs(mouseX) > 0.005 then
                    weaponPreviewRotation = weaponPreviewRotation + mouseX * 3.0
                end
            else
                if math.abs(mouseY) > 0.005 then
                    weaponPreviewRotationY = math.max(-30.0, math.min(30.0, weaponPreviewRotationY + mouseY * 2.0))
                end
            end

            if weaponPreviewObject and DoesEntityExist(weaponPreviewObject) then
                SetEntityRotation(weaponPreviewObject, weaponPreviewRotationY, 0.0, baseRotZ + weaponPreviewRotation, 2, true)
            end
        end
    end)

    return true
end

function HasComponentInInventory(componentHash)
    local itemName = GetItemFromHash(componentHash)
    if not itemName then return false end
    if not VFW.PlayerData or not VFW.PlayerData.inventory then return false end

    for _, item in ipairs(VFW.PlayerData.inventory) do
        if item.name == itemName and item.count > 0 then
            return true
        end
    end

    return false
end

local function RenderWeaponDetailMenuContent()
    if not selectedWeaponForDetail or not selectedWeaponItemForDetail then return end

    local weaponData = selectedWeaponForDetail
    local weaponItem = selectedWeaponItemForDetail
    local equippedComponents = weaponItem.meta and weaponItem.meta.components or {}

    local weaponLabel = VFW.Items and VFW.Items[weaponItem.name] and VFW.Items[weaponItem.name].label or weaponData.label

    if isRefreshingWeaponMenu then
        isRefreshingWeaponMenu = false
    else
        local previewExists = weaponPreviewActive and weaponPreviewObject and DoesEntityExist(weaponPreviewObject)
        if not previewExists then
            CreateWeaponPreview2D(weaponData.name, weaponLabel, equippedComponents)
        end
    end

    weaponDetailMenu.Separator("Informations")

    if weaponLabel or (weaponItem.meta and weaponItem.meta.ammo) then
        weaponDetailMenu.Button("Arme : " .. weaponLabel, "", nil, nil, false, function() end)

        if weaponItem.meta and weaponItem.meta.ammo then
            weaponDetailMenu.Button("Munitions : " .. tostring(weaponItem.meta.ammo), "", nil, nil, false, function() end)
        end
    else
        weaponDetailMenu.Button("Aucune information disponible", "", nil, "lock", false, function() end)
    end

    if weaponData.components and #weaponData.components > 0 then
        local availableComponents = {}
        for _, component in ipairs(weaponData.components) do
            if not IsCosmeticComponent(component.hash) then
                local isEquipped = IsComponentEquippedOnWeapon(equippedComponents, component.hash)
                local hasInInventory = HasComponentInInventory(component.hash)
                if isEquipped or hasInInventory then
                    table.insert(availableComponents, {
                        component = component,
                        isEquipped = isEquipped,
                        hasInInventory = hasInInventory,
                    })
                end
            end
        end

        if #availableComponents == 0 then
            weaponDetailMenu.Separator("Composants")
            weaponDetailMenu.Button("Aucun composant disponible", "", nil, "lock", false, function() end)
        else
            weaponDetailMenu.Separator("Composants disponibles")

            for _, entry in ipairs(availableComponents) do
                local componentLabel = GetComponentLabel(entry.component.hash, entry.component.label)
                local statusText = entry.isEquipped and "Équipé" or "Possédé"
               local currentWeaponId = weaponItem.meta and weaponItem.meta.weaponId or nil
                local currentComponentHash = entry.component.hash
                local isEquipped = entry.isEquipped
                local hasInInventory = entry.hasInInventory

                weaponDetailMenu.Button(
                    componentLabel,
                    statusText,
                    nil,
                    nil,
                    false,
                    function()
                        if not currentWeaponId then return end

                        if isEquipped then
                            TriggerServerEvent("vfw:weapon:removeComponent", currentWeaponId, currentComponentHash)
                        elseif hasInInventory then
                            TriggerServerEvent("vfw:weapon:addComponent", currentWeaponId, currentComponentHash)
                        end
                    end
                )
            end
        end
    else
        weaponDetailMenu.Separator("Composants")
        weaponDetailMenu.Button("Aucun composant disponible", "", nil, "lock", false, function() end)
    end

end

local function RenderWeaponComponentsMenuContent()
    local weapons = GetPlayerWeaponsFromInventory()

    if #weapons == 0 then
        weaponComponentsMenu.Button("Aucune arme sur vous", nil, nil, "lock", false, function() end)
        return
    end

    weaponComponentsMenu.Separator("Vos armes (" .. #weapons .. ")")

    for _, weapon in ipairs(weapons) do
        local componentCount = weapon.data.components and #weapon.data.components or 0
        local equippedCount = weapon.equippedComponents and #weapon.equippedComponents or 0
        local statusText = componentCount > 0 and (equippedCount .. "/" .. componentCount .. " équipés") or "Pas de composants"

       weaponComponentsMenu.Button(
            weapon.label,
            statusText,
            nil,
            "chevron",
            false,
            function()
                weaponComponentsMenu.close()
                OpenWeaponMenu(weapon.item, weapon.data)
            end
        )
    end
end


-- ==========================================
--           MENU EVENT HANDLERS
-- ==========================================

main.OnOpen(function()
    renderMainMenu()
end)

documentsMenu.OnOpen(function()
    renderDocumentsMenu()
end)

vehiclesMenu.OnOpen(function()
    renderVehiclesMenu()
end)

giveSelectVehicleMenu.OnOpen(function()
    renderGiveSelectVehicleMenu()
end)

giveSelectPlayerMenu.OnOpen(function()
    renderGiveSelectPlayerMenu()
end)

sellSelectVehicleMenu.OnOpen(function()
    renderSellSelectVehicleMenu()
end)

sellSelectPlayerMenu.OnOpen(function()
    renderSellSelectPlayerMenu()
end)

visualOptionsMenu.OnOpen(function()
    renderVisualOptionsMenu()
end)

local function setHudPreview(key, visible)
    SendNUIMessage({
        action = "nui:StatusHUD:preview",
        data = { key = key, visible = visible, percent = 75 }
    })
end

visualOptionsMenu.OnIndexChange(function(_, item)
    local title = item and item.props and item.props.title or ""
   if title:find("Couleur Faim", 1, true) then
        setHudPreview("hunger", true)
    elseif title:find("Couleur Soif", 1, true) then
        setHudPreview("thirst", true)
    elseif title:find("Couleur Oxygène", 1, true) then
        setHudPreview("oxygen", true)
    else
        setHudPreview(nil, false)
    end
end)

visualOptionsMenu.OnClose(function()
    setHudPreview(nil, false)
end)

vuiOptionsMenu.OnOpen(function()
    renderVuiOptionsMenu()
end)

streamerOptionsMenu.OnOpen(function()
    streamerOptionsMenu.Checkbox(
        "Mode Streamer",
        "Coupe les sons des boombox, radios, télés et médias",
        false,
        StreamerModeEnabled,
        function(checked)
            SetStreamerMode(checked)
            VFW.ShowNotification({
                type = checked and 'VERT' or 'ORANGE',
                content = checked and "Mode streamer activé" or "Mode streamer désactivé"
           })
        end
    )

    -- Charger le KVP pour le mute nouveaux joueurs
    local _muteNewKvp = GetResourceKvpString("mute_new_players")
    local muteNewPlayers = (_muteNewKvp == "1")

    streamerOptionsMenu.Checkbox(
        "Masquer les nouveaux joueurs",
        "Ne pas entendre les joueurs avec moins d'une heure de temps de jeu",
        false,
        muteNewPlayers,
        function(checked)
            SetResourceKvp("mute_new_players", checked and "1" or "0")
            TriggerServerEvent("vfw:streamer:muteNewPlayers", checked)
            VFW.ShowNotification({
                type = checked and 'VERT' or 'ORANGE',
                content = checked and "Nouveaux joueurs masqués (voix)" or "Nouveaux joueurs audibles"
           })
        end
    )
end)

animationsMenu.OnOpen(function()
    renderAnimationsMenu()
end)

styleradioMenu.OnOpen(function()
    renderStyleradioMenu()
end)

radioEmotesMenu.OnOpen(function()
    -- Annuler le clear si on revient dans le menu (cas du refresh)
    if radioEmotesClearTimeout then
        radioEmotesClearTimeout = nil
    end
    renderRadioEmotesMenu()
end)

radioEmotesMenu.OnClose(function()
    -- Délai pour distinguer refresh (close→open rapide) vs vraie sortie
    radioEmotesClearTimeout = true
    SetTimeout(100, function()
        if radioEmotesClearTimeout then
            ClearPedTasks(PlayerPedId())
            radioEmotesClearTimeout = nil
        end
    end)
end)

local radioStylesOrdered = {}
for style, _ in pairs(radioAnimations) do
    radioStylesOrdered[#radioStylesOrdered + 1] = style
end

radioEmotesMenu.OnIndexChange(function(newIndex, item)
    -- 1 séparateur avant les boutons → les boutons commencent à l'index 2
    local styleIndex = newIndex - 1
    local style = radioStylesOrdered[styleIndex]
    if not style then return end
    local animData = radioAnimations[style]
    if not animData then return end

    -- Annuler le clear pending si on navigue
    radioEmotesClearTimeout = nil

    local ped = PlayerPedId()
    if style == "Radio - Oreille" then
        ClearPedTasks(ped)
        return
    end

    RequestAnimDict(animData.dict)
    CreateThread(function()
        local timeout = 0
        while not HasAnimDictLoaded(animData.dict) do
            Wait(50)
            timeout = timeout + 1
            if timeout > 40 then return end
        end
        -- Vérifier qu'on est toujours sur ce style (navigation rapide)
        if radioStylesOrdered[newIndex - 1] == style then
            TaskPlayAnim(ped, animData.dict, animData.anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end)
end)

weaponEmotesMenu.OnOpen(function()
    renderWeaponEmotesMenu()

    -- Activer la preview quand le menu s'ouvre
    weaponEmotePreviewActive = true
    StartWeaponPreviewThread()

    -- Créer la preview du premier item (après un court délai pour que le menu soit rendu)
    CreateThread(function()
        Wait(100)
        if weaponEmotePreviewActive and aimStylesOrdered[1] then
            currentWeaponPreviewStyle = aimStylesOrdered[1].label
            CreateWeaponEmotePreview(aimStylesOrdered[1].animSet)
        end
    end)
end)

weaponEmotesMenu.OnClose(function()
    -- Cleanup quand le menu se ferme
    CleanupWeaponEmotePreview()
end)

weaponEmotesMenu.OnIndexChange(function(newIndex, item)
    -- Activer la preview quand on survole un item
    -- newIndex commence à 1, et on a 1 séparateur avant les boutons
    -- Donc les boutons sont aux index 2, 3, 4, 5...
    if weaponEmotePreviewActive and newIndex > 1 then
        local styleIndex = newIndex - 1 -- Ajuster pour le séparateur
        if aimStylesOrdered[styleIndex] then
            local style = aimStylesOrdered[styleIndex]
            if currentWeaponPreviewStyle ~= style.label then
                currentWeaponPreviewStyle = style.label
                CreateWeaponEmotePreview(style.animSet)
            end
        end
    end
end)

holsterEmotesMenu.OnOpen(function()
    renderHolsterEmotesMenu()
end)

rockstarEditorMenu.OnOpen(function()
    renderRockstarEditorMenu()
end)

invoicesMenu.OnOpen(function()
    renderInvoicesMenu()
end)

paymentsMenu.OnOpen(function()
    renderPaymentsMenu()
end)

weaponComponentsMenu.OnOpen(function()
    RenderWeaponComponentsMenuContent()
end)

weaponComponentsMenu.OnClose(function()
    CleanupWeaponPreview()
end)

weaponDetailMenu.OnOpen(function()
    RenderWeaponDetailMenuContent()
end)

weaponDetailMenu.OnClose(function()
    if not isRefreshingWeaponMenu then
        CleanupWeaponPreview()
    end
end)


propsBuilderMenu.OnOpen(function()
    renderPropsBuilderMenu(propsBuilderMenu, createVipPropMenu, manageMyPropsMenu)

    if VFW.PlayerGlobalData.permissions["vip_gold"] then
        propsBuilderMenu.ChangeBanner("premiumvip")
    elseif VFW.PlayerGlobalData.permissions["vip_silver"] then
        propsBuilderMenu.ChangeBanner("vip_plus")
    else
        propsBuilderMenu.ChangeBanner("vip")
    end
end)

createVipPropMenu.OnOpen(function()
    renderPropsCreateProps(createVipPropMenu, categorySelectionMenu, propsBuilderMenu)

    if VFW.PlayerGlobalData.permissions["vip_gold"] then
        createVipPropMenu.ChangeBanner("premiumvip")
    elseif VFW.PlayerGlobalData.permissions["vip_silver"] then
        createVipPropMenu.ChangeBanner("vip_plus")
    else
        createVipPropMenu.ChangeBanner("vip")
    end
end)

categorySelectionMenu.OnOpen(function()

    renderCategorySelectionMenu(categorySelectionMenu, createVipPropMenu)

    if VFW.PlayerGlobalData.permissions["vip_gold"] then
        categorySelectionMenu.ChangeBanner("premiumvip")
    elseif VFW.PlayerGlobalData.permissions["vip_silver"] then
        categorySelectionMenu.ChangeBanner("vip_plus")
    else
        categorySelectionMenu.ChangeBanner("vip")
    end
end)

manageMyPropsMenu.OnOpen(function()
    renderManageMyPropsMenu(manageMyPropsMenu)

    if VFW.PlayerGlobalData.permissions["vip_gold"] then
        manageMyPropsMenu.ChangeBanner("premiumvip")
    elseif VFW.PlayerGlobalData.permissions["vip_silver"] then
        manageMyPropsMenu.ChangeBanner("vip_plus")
    else
        manageMyPropsMenu.ChangeBanner("vip")
    end
end)


-- ==========================================
--           REGISTER KEYBINDINGS
-- ==========================================

-- Register F5 keybinding for personal menu
VFW.RegisterInput("OpenPersonnelMenu", "Menu Personnel", "keyboard", "F5", function()
    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Le menu personnel est désactivé pendant les TIG"
       })
        return
    end

    if Death.isDead or VFW.PlayerData.dead then
        return
    end

    main.open()
end)

-- Event handler for the personal menu
RegisterNetEvent("vfw:openPersonalMenu", function()
    main.open()
end)

RegisterNetEvent("vfw:openVisualOptions", function()
    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Les réglages sont désactivés pendant les TIG"
        })
        return
    end
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return
    end
    visualOptionsMenu.open()
end)

-- ==========================================
--       DOCUMENT DISPLAY HANDLER
-- ==========================================

-- NUI Callback to close player documents
RegisterNUICallback("nui:playerDocuments:close", function(data, cb)
    documentOpen = false
    cb('ok')
end)

-- Receive document from another player
RegisterNetEvent("vfw:displayDocument", function(documentType, documentData, cardType, cardLabel, photoUrl, licenseCategories)
    SendNUIMessage({
        action = "playerDocuments:toggle",
        data = {
            cardType = cardType,
            cardLabel = cardLabel,
            theme = "light",
            data = documentData,
            photoUrl = photoUrl,
            licenseCategories = licenseCategories
        }
    })

    documentOpen = true

    Citizen.CreateThread(function()
        SendNUIMessage({ action = "instructionalBar:show", data = { items = {
            { keys = { "←" }, label = "Fermer le document" }
        } } })

        while documentOpen do
            Wait(0)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 199, true)

            if IsDisabledControlJustPressed(0, 200) or
                    IsControlJustPressed(0, 191) or
                    IsControlJustPressed(0, 194) or
                    IsControlJustPressed(0, 177) then
                documentOpen = false
                SendNUIMessage({ action = "playerDocuments:close" })
                SendNUIMessage({ action = "instructionalBar:hide" })
            end
        end
    end)
end)

-- Dismiss document remotely (when the shower stops showing)
RegisterNetEvent("vfw:dismissDocument", function()
    if documentOpen then
        documentOpen = false
        SendNUIMessage({ action = "playerDocuments:close" })
        SendNUIMessage({ action = "instructionalBar:hide" })
    end
end)

-- ==========================================
--    INITIALIZE DEFAULT HUD SETTINGS
-- ==========================================

-- Initialize HUD settings when player is loaded
RegisterNetEvent("vfw:onPlayerLoaded", function()
    -- Restaurer l'état des sons VUI (Lua + NUI JS via export)
    exports["VUI"]:SetSoundEnabled(vuiSoundEnabled)

    -- Apply default hide states to UI (name and street hidden by default)

    if hideVoiceChat then
        Citizen.SetTimeout(3000, function()
            TriggerEvent("pma-voice:toggleUi", false)
        end)
    end

    -- Restaurer le style de visée sauvegardé
    Citizen.SetTimeout(2000, function()
        local savedStyle = VFW.PlayerData and VFW.PlayerData.metadata and VFW.PlayerData.metadata.weaponAimStyle
        if savedStyle and savedStyle ~= "Default" then
            SetWeaponAnimationOverride(PlayerPedId(), savedStyle)
            -- Mettre à jour le label local
            for _, style in ipairs(aimStylesOrdered) do
                if style.animSet == savedStyle then
                    currentAimStyle = style.label
                    break
                end
            end
        end
    end)
end)

-- Re-appliquer le style après mort/respawn (le ped est recréé, le style est perdu)
AddEventHandler("playerSpawned", function()
    Citizen.SetTimeout(1000, function()
        local savedStyle = VFW.PlayerData and VFW.PlayerData.metadata and VFW.PlayerData.metadata.weaponAimStyle
        if savedStyle and savedStyle ~= "Default" then
            SetWeaponAnimationOverride(PlayerPedId(), savedStyle)
        end
    end)
end)

-- Re-appliquer le style après changement de skin (le ped est recréé)
AddEventHandler("skinchanger:modelLoaded", function()
    Citizen.SetTimeout(500, function()
        local savedStyle = VFW.PlayerData and VFW.PlayerData.metadata and VFW.PlayerData.metadata.weaponAimStyle
        if savedStyle and savedStyle ~= "Default" then
            SetWeaponAnimationOverride(PlayerPedId(), savedStyle)
        end
    end)
end)

-- Cache des styles de visée des autres joueurs (pour réappliquer au streaming)
local otherPlayersWeaponStyles = {}

-- Recevoir le style de visée d'un autre joueur (synchro multi-client)
RegisterNetEvent("vfw:weaponStyle:sync", function(targetServerId, animSet)
    otherPlayersWeaponStyles[targetServerId] = animSet
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetServerId))
    if targetPed and DoesEntityExist(targetPed) and targetPed ~= PlayerPedId() then
        SetWeaponAnimationOverride(targetPed, animSet)
    end
end)

-- Recevoir les styles de tous les joueurs connectés (quand on rejoint)
RegisterNetEvent("vfw:weaponStyle:syncAll", function(allStyles)
    for serverId, animSet in pairs(allStyles) do
        local sid = tonumber(serverId) or serverId
        otherPlayersWeaponStyles[sid] = animSet
        local targetPed = GetPlayerPed(GetPlayerFromServerId(sid))
        if targetPed and DoesEntityExist(targetPed) and targetPed ~= PlayerPedId() then
            SetWeaponAnimationOverride(targetPed, animSet)
        end
    end
end)

-- Thread pour réappliquer les styles de visée des autres joueurs (streaming range)
CreateThread(function()
    while true do
        Wait(2000)
        local myPed = PlayerPedId()
        for serverId, animSet in pairs(otherPlayersWeaponStyles) do
            if animSet ~= "Default" then
                local playerId = GetPlayerFromServerId(serverId)
                if playerId ~= -1 then
                    local targetPed = GetPlayerPed(playerId)
                    if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) and targetPed ~= myPed then
                        SetWeaponAnimationOverride(targetPed, animSet)
                    end
                else
                    otherPlayersWeaponStyles[serverId] = nil
                end
            end
        end
    end
end)

-- ==========================================
--    WEAPON COMPONENTS EVENT HANDLERS
-- ==========================================

-- NOTE: Ne pas mettre à jour VFW.PlayerData.inventory ici,
-- c'est déjà fait dans inventory/main.lua (avec la notification ItemTrade).
-- Un double handler causerait une race condition qui empêche les notifications.

RegisterNetEvent("vfw:weapon:componentUpdated", function(weaponId, components)
    if selectedWeaponItemForDetail and selectedWeaponItemForDetail.meta and selectedWeaponItemForDetail.meta.weaponId == weaponId then
        selectedWeaponItemForDetail.meta.components = components
        CreateThread(function()
            if selectedWeaponForDetail and currentWeaponName then
                UpdateWeaponPreviewObject(currentWeaponName, components)
            end
            Wait(100)
            isRefreshingWeaponMenu = true
            weaponDetailMenu.refresh()
        end)
    end
end)

RegisterNetEvent("vfw:weapon:tintUpdated", function(weaponId, tint)
    if selectedWeaponItemForDetail and selectedWeaponItemForDetail.meta and selectedWeaponItemForDetail.meta.weaponId == weaponId then
        selectedWeaponItemForDetail.meta.tint = tint
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupWeaponPreview()
    end
end)

-- Parachute auto-regive system
local parachuteHash = `gadget_parachute`
local parachuteThreadRunning = false
local savedBagDrawable = nil
local savedBagTexture = nil

local function GiveParachute()
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, parachuteHash, 1, false, true)
end

local function RemoveParachute()
    local ped = PlayerPedId()
    RemoveWeaponFromPed(ped, parachuteHash)
end

local parachuteBagDrawable = 50

local function EquipParachuteBag()
    local ped = PlayerPedId()
    local currentDrawable = GetPedDrawableVariation(ped, 5)
    if currentDrawable ~= parachuteBagDrawable then
        savedBagDrawable = currentDrawable
        savedBagTexture = GetPedTextureVariation(ped, 5)
    end
    SetPedComponentVariation(ped, 5, parachuteBagDrawable, 0, 0)
end

local function UnequipParachuteBag()
    local ped = PlayerPedId()
    if savedBagDrawable ~= nil then
        SetPedComponentVariation(ped, 5, savedBagDrawable, savedBagTexture or 0, 0)
        savedBagDrawable = nil
        savedBagTexture = nil
    end
end

local function StartParachuteThread()
    if parachuteThreadRunning then return end
    parachuteThreadRunning = true
    CreateThread(function()
        while parachuteThreadRunning do
            Wait(1000)
            if not parachuteThreadRunning then break end
            local ped = PlayerPedId()
            if not HasPedGotWeapon(ped, parachuteHash, false) then
                TriggerServerEvent("vfw:parachute:regive")
            end
            local currentDrawable = GetPedDrawableVariation(ped, 5)
            if currentDrawable ~= parachuteBagDrawable then
                if savedBagDrawable == nil then
                    savedBagDrawable = currentDrawable
                    savedBagTexture = GetPedTextureVariation(ped, 5)
                end
                SetPedComponentVariation(ped, 5, parachuteBagDrawable, 0, 0)
            end
        end
    end)
end

RegisterNetEvent("vfw:parachute:setState", function(state)
    if state then
        GiveParachute()
        EquipParachuteBag()
        StartParachuteThread()
    else
        RemoveParachute()
        UnequipParachuteBag()
        parachuteThreadRunning = false
    end
end)

RegisterNetEvent("vfw:parachute:give", function()
    GiveParachute()
end)

-- Thread pour réappliquer le style de visée lors des changements d'arme
CreateThread(function()
    local lastWeapon = GetSelectedPedWeapon(PlayerPedId(), true)

    while true do
        Wait(500)  -- Check toutes les 500ms

        local ped = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(ped, true)

        -- Si l'arme a changé
        if currentWeapon ~= lastWeapon then
            lastWeapon = currentWeapon

            -- Réappliquer le style sauvegardé
            local savedAimStyle = GetResourceKvpString("aim_style_animset")
            if savedAimStyle ~= nil then
                SetWeaponAnimationOverride(ped, savedAimStyle)
            end
        end
    end
end)

-- ==========================================
--         STREAMER - MUTE NEW PLAYERS
-- ==========================================

RegisterNetEvent("vfw:streamer:newPlayersList")
AddEventHandler("vfw:streamer:newPlayersList", function(playerIds)
    -- Unmute les anciens
    for _, id in ipairs(mutedPlayerIds) do
        MumbleSetVolumeOverrideByServerId(id, -1.0)
    end

    mutedPlayerIds = playerIds or {}

    -- Mute les nouveaux
    for _, id in ipairs(mutedPlayerIds) do
        MumbleSetVolumeOverrideByServerId(id, 0.0)
    end
end)

-- Au chargement, activer si sauvegardé
AddEventHandler("vfw:playerLoaded", function()
    if muteNewPlayersEnabled then
        TriggerServerEvent("vfw:streamer:muteNewPlayers", true)
    end
    if compassEnabled then
        exports["fb_boussole"]:SetCompassEnabled(true)
        exports["fb_boussole"]:SetStreetNameEnabled(true)
    end
end)

