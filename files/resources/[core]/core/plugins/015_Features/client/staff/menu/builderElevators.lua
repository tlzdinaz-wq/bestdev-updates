local currentElevatorBuild = {
    floors = {},
    label = "",
    isValid = false
}

local markerThread = nil
local isMarkersActive = false
local markerGeneration = 0
local currentFloorIndex = nil
local currentCreationFloorIndex = nil

--- Valide si l'ascenseur en construction est valide
--- @return boolean isValid
local function validateElevatorBuild()
    currentElevatorBuild.isValid = #currentElevatorBuild.floors >= 2 and
            currentElevatorBuild.label ~= ""
  return currentElevatorBuild.isValid
end

--- Obtient la position actuelle du joueur
--- @return table|nil position Coordonnées et orientation du joueur
local function getCurrentPlayerPosition()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then
        return nil
    end

    local coords = GetEntityCoords(playerPed)
    if not coords then
        return nil
    end

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = GetEntityHeading(playerPed)
    }
end

--- Arrête le thread des marqueurs de manière sécurisée
local function stopMarkerThread()
    isMarkersActive = false
    markerGeneration = markerGeneration + 1
    markerThread = nil
end

--- Réinitialise la construction de l'ascenseur
local function resetElevatorBuild()
    stopMarkerThread()

    currentElevatorBuild = {
        floors = {},
        label = "",
        isValid = false
    }
    currentCreationFloorIndex = nil
end

--- Formate les informations de whitelist pour l'affichage
--- @param whitelist table|nil Données de whitelist
--- @return string formattedText
local function formatWhitelistInfo(whitelist)
    if not whitelist or type(whitelist) ~= "table" then
        return "Accès libre"
  end

    local jobs = {}
    for job, jobData in pairs(whitelist) do
        if type(jobData) == "table" and jobData.grades and #jobData.grades > 0 then
            local gradesStr = table.concat(jobData.grades, ", ")
            table.insert(jobs, job .. " (grade " .. gradesStr .. ")")
        else
            table.insert(jobs, job)
        end
    end

    return #jobs > 0 and table.concat(jobs, " | ") or "Accès restreint"
end

--- Démarre l'affichage des marqueurs pour les étages
local function startMarkerThread()
    if isMarkersActive or not currentElevatorBuild.floors or #currentElevatorBuild.floors == 0 then
        return
    end

    isMarkersActive = true
    markerGeneration = markerGeneration + 1
    local generation = markerGeneration
    markerThread = CreateThread(function()
        while isMarkersActive and generation == markerGeneration and #currentElevatorBuild.floors > 0 do
            for i, floorData in ipairs(currentElevatorBuild.floors) do
                if not isMarkersActive then break end

                if floorData and floorData.coords then
                    local coords = floorData.coords

                    DrawMarker(
                            27,
                            coords.x, coords.y, coords.z - 1.0,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            2.0, 2.0, 1.0,
                            255, 255, 255, 150,
                            false, true, 2, false, nil, nil, false
                    )

                    local whitelistInfo = formatWhitelistInfo(floorData.whitelist)
                    local text = floorData.label .. "\n" .. whitelistInfo

                    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
                    if onScreen then
                        SetTextScale(0.4, 0.4)
                        SetTextFont(4)
                        SetTextProportional(1)
                        SetTextColour(255, 255, 255, 215)
                        SetTextCentre(true)
                        SetTextOutline()
                        SetTextEntry("STRING")
                        AddTextComponentString(text)
                        DrawText(screenX, screenY)
                    end
                end
            end
            Wait(0)
        end
        if generation == markerGeneration then
            markerThread = nil
            isMarkersActive = false
        end
    end)
end

--- Supprime un étage par index
--- @param floorIndex number Index de l'étage à supprimer
--- @return boolean success
local function removeFloor(floorIndex)
    if not floorIndex or not currentElevatorBuild.floors[floorIndex] then
        return false
    end

    table.remove(currentElevatorBuild.floors, floorIndex)
    validateElevatorBuild()

    if #currentElevatorBuild.floors > 0 then
        startMarkerThread()
    else
        stopMarkerThread()
    end

    return true
end

--- Ajoute une whitelist à un étage
--- @param floorIndex number Index de l'étage
--- @param job string Nom du job
--- @param grade number|string Grade minimum
--- @return boolean success
local function addWhitelistToFloor(floorIndex, job, grade)
    if not floorIndex or not currentElevatorBuild.floors[floorIndex] then
        return false
    end

    if not job or job == "" then
        return false
    end

    local gradeValue = tonumber(grade)
    if not gradeValue and grade ~= "" then
        gradeValue = tostring(grade)
    end

    if not gradeValue then
        return false
    end

    local floor = currentElevatorBuild.floors[floorIndex]

    if not floor.whitelist then
        floor.whitelist = {
            jobs = {},
            gradesByJob = {}
        }
    end

    if not floor.whitelist.gradesByJob[job] then
        table.insert(floor.whitelist.jobs, job)
        floor.whitelist.gradesByJob[job] = {}
    end

    for _, existingGrade in ipairs(floor.whitelist.gradesByJob[job]) do
        if existingGrade == gradeValue then
            return true
        end
    end

    table.insert(floor.whitelist.gradesByJob[job], gradeValue)
    return true
end

--- Ajoute un étage à la position actuelle
--- @param floorLabel string Nom de l'étage
--- @return boolean success
local function addFloorAtCurrentPosition(floorLabel)
    if not floorLabel or floorLabel == "" then
        return false
    end

    local position = getCurrentPlayerPosition()
    if not position then
        return false
    end

    table.insert(currentElevatorBuild.floors, {
        label = floorLabel,
        coords = {
            x = position.x,
            y = position.y,
            z = position.z
        },
        whitelist = nil
    })

    validateElevatorBuild()

    if not isMarkersActive then
        startMarkerThread()
    end

    return true
end

--- Finalise la création de l'ascenseur
--- @return boolean success
local function finalizeElevatorCreation()
    if not validateElevatorBuild() then
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'ERROR',
            subtitle = 'Builder',
            message = "Cette configuration d'ascenseur n'est pas valide."
      })
        return false
    end

    if #currentElevatorBuild.floors < 2 then
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'ERROR',
            subtitle = 'Builder',
            message = "Au moins 2 étages sont requis pour créer un ascenseur."
      })
        return false
    end

    local elevatorId = currentElevatorBuild.label:gsub("%s+", "_"):gsub("[^%w_]", ""):lower()
    ElevatorsData[elevatorId] = { floors = currentElevatorBuild.floors }
    TriggerServerEvent("core:player:addElevator", elevatorId, currentElevatorBuild.floors)

    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'SUCCESS',
        subtitle = 'Builder',
        message = "Ascenseur '" .. currentElevatorBuild.label .. "' créé."
  })

    resetElevatorBuild()
    return true
end

--- Formate les infos de whitelist (nouveau format)
local function formatWhitelistInfoNew(whitelist)
    if not whitelist or not whitelist.jobs or #whitelist.jobs == 0 then
        return "Accès libre"
  end

    local parts = {}
    for _, job in ipairs(whitelist.jobs) do
        local grades = whitelist.gradesByJob and whitelist.gradesByJob[job]
        if grades and #grades > 0 then
            table.insert(parts, job .. " (grade " .. table.concat(grades, ", ") .. ")")
        else
            table.insert(parts, job)
        end
    end

    return #parts > 0 and table.concat(parts, " | ") or "Accès restreint"
end

--- Menu principal des ascenseurs
function StaffMenu.BuildElevatorsMenu()
    if not StaffMenu or not StaffMenu.builder_elevators then
        return
    end

    StaffMenu.builder_elevators.Button(':plus: CRÉER UN ASCENSEUR', 'Créer un nouvel ascenseur',
            nil, 'chevron', false, function()
                resetElevatorBuild()
            end, StaffMenu.CreateElevator)

    local hasElevators = ElevatorsData and next(ElevatorsData) ~= nil
    local separatorText = hasElevators and 'ASCENSEURS DISPONIBLES' or 'AUCUN ASCENSEUR DISPONIBLE'
    StaffMenu.builder_elevators.Separator(separatorText)

    if hasElevators then
        for elevatorId, elevatorData in pairs(ElevatorsData) do
            if elevatorData and elevatorData.floors then
                local floorCount = #elevatorData.floors
                local displayName = elevatorId:gsub("_", " "):upper()

                StaffMenu.builder_elevators.Button(displayName,
                        floorCount .. (floorCount > 1 and ' étages' or ' étage'), nil, 'chevron', false,
                        function()
                            StaffMenu.currentElevator = elevatorId
                        end, StaffMenu.ManageElevator)
            end
        end
    end
end

--- Menu de création d'ascenseur
function StaffMenu.BuildCreateElevatorMenu()
    if not StaffMenu or not StaffMenu.CreateElevator then
        return
    end

    local labelDisplay = currentElevatorBuild.label ~= "" and
            string.upper(currentElevatorBuild.label) or "NON DÉFINI"

  StaffMenu.CreateElevator.Button(":tag: NOM: " .. labelDisplay,
            "Définir le nom de l'ascenseur", nil, "chevron", false,
            function()
                if VFW and VFW.Nui and VFW.Nui.KeyboardInput then
                    local newLabel = VFW.Nui.KeyboardInput(true, "Nom de l'ascenseur")
                    currentElevatorBuild.label = (newLabel and newLabel ~= "") and
                            tostring(newLabel) or ""
                  validateElevatorBuild()
                    if StaffMenu.CreateElevator.refresh then
                        StaffMenu.CreateElevator.refresh()
                    end
                end
            end)

    StaffMenu.CreateElevator.Button(":plus: AJOUTER UN ÉTAGE", "Ajouter un nouvel étage à votre position",
            nil, "chevron", false,
            function()
                if not VFW or not VFW.Nui or not VFW.Nui.KeyboardInput then return end

                local floorLabel = VFW.Nui.KeyboardInput(true, "Nom de l'étage (ex: RDC, Étage 1, Parking)")
                if not floorLabel or floorLabel == "" then return end

                if addFloorAtCurrentPosition(floorLabel) then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'SUCCESS',
                        subtitle = 'Builder',
                        message = "Étage '" .. floorLabel .. "' ajouté."
                  })
                    if StaffMenu.CreateElevator.refresh then
                        StaffMenu.CreateElevator.refresh()
                    end
                end
            end)

    if #currentElevatorBuild.floors > 0 then
        StaffMenu.CreateElevator.Separator("ÉTAGES CONFIGURÉS")

        for floorIndex, floorData in ipairs(currentElevatorBuild.floors) do
            local accessStatus = floorData.whitelist and "RESTREINT" or "LIBRE"
          local whitelistInfo = formatWhitelistInfoNew(floorData.whitelist)

            StaffMenu.CreateElevator.Button(":building: " .. floorData.label .. " - " .. accessStatus,
                    whitelistInfo, nil, "chevron", false,
                    function()
                        currentCreationFloorIndex = floorIndex
                    end, StaffMenu.ManageCreationFloor)
        end
    else
        StaffMenu.CreateElevator.Separator("AUCUN ÉTAGE CONFIGURÉ")
    end

    StaffMenu.CreateElevator.Separator(nil)

    local floorCount = #currentElevatorBuild.floors
    local statusMessage = ""
  if currentElevatorBuild.label == "" then
        statusMessage = "Nom de l'ascenseur requis"
  elseif floorCount < 2 then
        statusMessage = "Minimum 2 étages requis (" .. floorCount .. "/2)"
  else
        statusMessage = "Configuration terminée"
  end

    StaffMenu.CreateElevator.Button(":check: FINALISER LA CRÉATION", statusMessage,
            nil, "check", not currentElevatorBuild.isValid,
            function()
                if finalizeElevatorCreation() then
                    StaffMenu.CreateElevator.close()
                    StaffMenu.CreateElevator.parent.open()
                end
            end)
end

--- Menu de gestion d'un étage en création
function StaffMenu.BuildManageCreationFloorMenu()
    if not StaffMenu or not StaffMenu.ManageCreationFloor or not currentCreationFloorIndex then
        return
    end

    local floorData = currentElevatorBuild.floors[currentCreationFloorIndex]
    if not floorData then
        StaffMenu.ManageCreationFloor.Separator("ÉTAGE INTROUVABLE")
        return
    end

    local totalFloors = #currentElevatorBuild.floors

    StaffMenu.ManageCreationFloor.Separator(floorData.label:upper())

    StaffMenu.ManageCreationFloor.Button(":edit: RENOMMER", "Modifier le nom de l'étage",
            nil, "chevron", false,
            function()
                if not VFW or not VFW.Nui or not VFW.Nui.KeyboardInput then return end

                local newLabel = VFW.Nui.KeyboardInput(true, "Nouveau nom de l'étage", floorData.label)
                if not newLabel or newLabel == "" then return end

                floorData.label = newLabel

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Étage renommé en '" .. newLabel .. "'."
              })

                if StaffMenu.ManageCreationFloor.refresh then
                    StaffMenu.ManageCreationFloor.refresh()
                end
            end)

    StaffMenu.ManageCreationFloor.Button(":arrow: MONTER", "Déplacer l'étage vers le haut dans la liste",
            nil, "chevron", currentCreationFloorIndex <= 1,
            function()
                if currentCreationFloorIndex <= 1 then return end

                local temp = currentElevatorBuild.floors[currentCreationFloorIndex - 1]
                currentElevatorBuild.floors[currentCreationFloorIndex - 1] = currentElevatorBuild.floors[currentCreationFloorIndex]
                currentElevatorBuild.floors[currentCreationFloorIndex] = temp

                currentCreationFloorIndex = currentCreationFloorIndex - 1

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Étage déplacé vers le haut."
              })

                if StaffMenu.ManageCreationFloor.refresh then
                    StaffMenu.ManageCreationFloor.refresh()
                end
            end)

    StaffMenu.ManageCreationFloor.Button(":arrow: DESCENDRE", "Déplacer l'étage vers le bas dans la liste",
            nil, "chevron", currentCreationFloorIndex >= totalFloors,
            function()
                if currentCreationFloorIndex >= totalFloors then return end

                local temp = currentElevatorBuild.floors[currentCreationFloorIndex + 1]
                currentElevatorBuild.floors[currentCreationFloorIndex + 1] = currentElevatorBuild.floors[currentCreationFloorIndex]
                currentElevatorBuild.floors[currentCreationFloorIndex] = temp

                currentCreationFloorIndex = currentCreationFloorIndex + 1

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Étage déplacé vers le bas."
              })

                if StaffMenu.ManageCreationFloor.refresh then
                    StaffMenu.ManageCreationFloor.refresh()
                end
            end)

    StaffMenu.ManageCreationFloor.Button(":pin: REPOSITIONNER", "Déplacer l'étage à votre position actuelle",
            nil, "chevron", false,
            function()
                local position = getCurrentPlayerPosition()
                if not position then return end

                floorData.coords = { x = position.x, y = position.y, z = position.z }

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Position de l'étage mise à jour."
              })
            end)

    StaffMenu.ManageCreationFloor.Separator(nil)

    StaffMenu.ManageCreationFloor.Button(":trash: SUPPRIMER L'ÉTAGE", "Supprimer cet étage",
            nil, "trash", false,
            function()
                removeFloor(currentCreationFloorIndex)

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Étage supprimé."
              })

                StaffMenu.ManageCreationFloor.close()
                StaffMenu.ManageCreationFloor.parent.open()
            end)
end

local function getFloorClosestToZero(floors)
    if not floors or #floors == 0 then return nil end

    local closestFloor = floors[1]
    local closestIndex = 1
    local closestDistance = math.huge

    for i, floor in ipairs(floors) do
        local floorNum = tonumber(floor.label and floor.label:match("%d+") or i) or i
        local distance = math.abs(floorNum)
        if distance < closestDistance then
            closestDistance = distance
            closestFloor = floor
            closestIndex = i
        end
    end

    return closestFloor, closestIndex
end

function StaffMenu.BuildManageElevatorMenu()
    if not StaffMenu or not StaffMenu.ManageElevator or not StaffMenu.currentElevator then
        return
    end

    local elevatorId = StaffMenu.currentElevator
    local elevatorData = ElevatorsData[elevatorId]

    if not elevatorData or not elevatorData.floors then
        StaffMenu.ManageElevator.Separator("ASCENSEUR INTROUVABLE")
        return
    end

    local displayName = elevatorId:gsub("_", " "):upper()
    StaffMenu.ManageElevator.Separator(displayName)

    local closestFloor = getFloorClosestToZero(elevatorData.floors)

    StaffMenu.ManageElevator.Button("SE TELEPORTER", "",
            nil, "chevron", false,
            function()
                if closestFloor and closestFloor.coords then
                    local coords = closestFloor.coords
                    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'SUCCESS',
                        subtitle = 'Builder',
                        message = "Téléporté à l'ascenseur '" .. displayName .. "'."
                  })
                end
            end)

    StaffMenu.ManageElevator.Separator("ÉTAGES")

    StaffMenu.ManageElevator.Button(":plus: AJOUTER UN ÉTAGE", "Ajouter un nouvel étage à votre position",
            nil, "chevron", false,
            function()
                if not VFW or not VFW.Nui or not VFW.Nui.KeyboardInput then return end

                local floorLabel = VFW.Nui.KeyboardInput(true, "Nom de l'étage (ex: RDC, Étage 1)")
                if not floorLabel or floorLabel == "" then return end

                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)

                local newFloor = {
                    label = floorLabel,
                    coords = { x = coords.x, y = coords.y, z = coords.z }
                }

                table.insert(elevatorData.floors, newFloor)
                TriggerServerEvent("core:player:updateElevatorFloors", elevatorId, elevatorData.floors)

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Étage '" .. floorLabel .. "' ajouté."
              })

                if StaffMenu.ManageElevator.refresh then
                    StaffMenu.ManageElevator.refresh()
                end
            end)

    for floorIndex, floor in ipairs(elevatorData.floors) do
        local floorLabel = floor.label or ("Étage " .. floorIndex)
        local accessInfo = "Accès libre"

      if floor.whitelist then
            if floor.whitelist.jobs and #floor.whitelist.jobs > 0 then
                accessInfo = "Jobs: " .. table.concat(floor.whitelist.jobs, ", ")
            else
                accessInfo = "Accès restreint"
          end
        end

        StaffMenu.ManageElevator.Button(floorLabel, accessInfo, nil, 'chevron', false,
            function()
                currentFloorIndex = floorIndex
            end, StaffMenu.ManageFloor)
    end

    StaffMenu.ManageElevator.Separator(nil)

    StaffMenu.ManageElevator.Button("SUPPRIMER L'ASCENSEUR", "Supprimer définitivement cet ascenseur",
            nil, "trash", false,
            function()
                local idToDelete = elevatorId
                local nameToDelete = displayName

                TriggerServerEvent("core:player:deleteElevator", idToDelete)

                ElevatorsData[idToDelete] = nil

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Ascenseur '" .. nameToDelete .. "' supprimé."
              })

                StaffMenu.ManageElevator.close()
                StaffMenu.ManageElevator.parent.open()
            end)
end

function StaffMenu.BuildManageFloorMenu()
    if not StaffMenu or not StaffMenu.ManageFloor or not StaffMenu.currentElevator or not currentFloorIndex then
        return
    end

    local elevatorId = StaffMenu.currentElevator
    local elevatorData = ElevatorsData[elevatorId]

    if not elevatorData or not elevatorData.floors or not elevatorData.floors[currentFloorIndex] then
        StaffMenu.ManageFloor.Separator("ÉTAGE INTROUVABLE")
        return
    end

    local floor = elevatorData.floors[currentFloorIndex]
    local floorLabel = floor.label or ("Étage " .. currentFloorIndex)
    local totalFloors = #elevatorData.floors

    StaffMenu.ManageFloor.Separator(floorLabel:upper())

    StaffMenu.ManageFloor.Button(":edit: RENOMMER", "Modifier le nom de l'étage",
            nil, "chevron", false,
            function()
                if not VFW or not VFW.Nui or not VFW.Nui.KeyboardInput then return end

                local newLabel = VFW.Nui.KeyboardInput(true, "Nouveau nom de l'étage", floor.label)
                if not newLabel or newLabel == "" then return end

                floor.label = newLabel
                TriggerServerEvent("core:player:updateElevatorFloors", elevatorId, elevatorData.floors)

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Étage renommé en '" .. newLabel .. "'."
              })

                if StaffMenu.ManageFloor.refresh then
                    StaffMenu.ManageFloor.refresh()
                end
            end)

    StaffMenu.ManageFloor.Button(":arrow: MONTER", "Déplacer l'étage vers le haut dans la liste",
            nil, "chevron", currentFloorIndex <= 1,
            function()
                if currentFloorIndex <= 1 then return end

                local temp = elevatorData.floors[currentFloorIndex - 1]
                elevatorData.floors[currentFloorIndex - 1] = elevatorData.floors[currentFloorIndex]
                elevatorData.floors[currentFloorIndex] = temp

                currentFloorIndex = currentFloorIndex - 1

                TriggerServerEvent("core:player:updateElevatorFloors", elevatorId, elevatorData.floors)

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Étage déplacé vers le haut."
              })

                if StaffMenu.ManageFloor.refresh then
                    StaffMenu.ManageFloor.refresh()
                end
            end)

    StaffMenu.ManageFloor.Button(":arrow: DESCENDRE", "Déplacer l'étage vers le bas dans la liste",
            nil, "chevron", currentFloorIndex >= totalFloors,
            function()
                if currentFloorIndex >= totalFloors then return end

                local temp = elevatorData.floors[currentFloorIndex + 1]
                elevatorData.floors[currentFloorIndex + 1] = elevatorData.floors[currentFloorIndex]
                elevatorData.floors[currentFloorIndex] = temp

                currentFloorIndex = currentFloorIndex + 1

                TriggerServerEvent("core:player:updateElevatorFloors", elevatorId, elevatorData.floors)

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Étage déplacé vers le bas."
              })

                if StaffMenu.ManageFloor.refresh then
                    StaffMenu.ManageFloor.refresh()
                end
            end)

    StaffMenu.ManageFloor.Button(":pin: REPOSITIONNER", "Déplacer l'étage à votre position actuelle",
            nil, "chevron", false,
            function()
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)

                floor.coords = { x = coords.x, y = coords.y, z = coords.z }

                TriggerServerEvent("core:player:updateElevatorFloors", elevatorId, elevatorData.floors)

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Position de l'étage mise à jour."
              })
            end)

    StaffMenu.ManageFloor.Separator(nil)

    StaffMenu.ManageFloor.Button(":trash: SUPPRIMER L'ÉTAGE", "Supprimer définitivement cet étage",
            nil, "trash", totalFloors <= 2,
            function()
                if totalFloors <= 2 then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Builder',
                        message = "Un ascenseur doit avoir au moins 2 étages."
                  })
                    return
                end

                table.remove(elevatorData.floors, currentFloorIndex)
                TriggerServerEvent("core:player:updateElevatorFloors", elevatorId, elevatorData.floors)

                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Builder',
                    message = "Étage supprimé."
              })

                StaffMenu.ManageFloor.close()
                StaffMenu.ManageFloor.parent.open()
            end)
end

-- Gestion des événements avec vérifications de sécurité
if StaffMenu and StaffMenu.builder_elevators and StaffMenu.builder_elevators.OnOpen then
    StaffMenu.builder_elevators.OnOpen(function()
        StaffMenu.BuildElevatorsMenu()
    end)
end

if StaffMenu and StaffMenu.CreateElevator then
    if StaffMenu.CreateElevator.OnOpen then
        StaffMenu.CreateElevator.OnOpen(function()
            StaffMenu.BuildCreateElevatorMenu()
            startMarkerThread()
        end)
    end

    if StaffMenu.CreateElevator.OnClose then
        StaffMenu.CreateElevator.OnClose(function()
            stopMarkerThread()
        end)
    end
end

if StaffMenu and StaffMenu.ManageElevator and StaffMenu.ManageElevator.OnOpen then
    StaffMenu.ManageElevator.OnOpen(function()
        StaffMenu.BuildManageElevatorMenu()
    end)
end

if StaffMenu and StaffMenu.ManageFloor and StaffMenu.ManageFloor.OnOpen then
    StaffMenu.ManageFloor.OnOpen(function()
        StaffMenu.BuildManageFloorMenu()
    end)
end

if StaffMenu and StaffMenu.ManageCreationFloor and StaffMenu.ManageCreationFloor.OnOpen then
    StaffMenu.ManageCreationFloor.OnOpen(function()
        StaffMenu.BuildManageCreationFloorMenu()
    end)
end