-- Hospital Builder for Staff Menu

local currentHospitalBuild = {
    name = "",
    position = nil,
    blipEnabled = true,
    isValid = false
}

local markerThread = nil
local isMarkersActive = false

local function validateHospitalBuild()
    currentHospitalBuild.isValid = currentHospitalBuild.name ~= "" and
            currentHospitalBuild.position ~= nil
    return currentHospitalBuild.isValid
end

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
        h = GetEntityHeading(playerPed)
    }
end

local function stopMarkerThread()
    if isMarkersActive then
        isMarkersActive = false
        markerThread = nil
    end
end

local function startMarkerThread()
    if isMarkersActive then
        return
    end

    isMarkersActive = true
    markerThread = CreateThread(function()
        while isMarkersActive do
            if currentHospitalBuild.position then
                local blipPos = currentHospitalBuild.position
                local coords = vector3(blipPos.x, blipPos.y, blipPos.z)

                DrawMarker(
                    1,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.5, 1.5, 1.0,
                    255, 50, 50, 150,
                    false, true, 2, false, nil, nil, false
                )

                local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 50, 50, 215)
                    SetTextCentre(true)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("HÔPITAL")
                    DrawText(screenX, screenY)
                end
            end

            Wait(0)
        end
    end)
end

local function resetHospitalBuild()
    stopMarkerThread()
    currentHospitalBuild = {
        name = "",
        position = nil,
        blipEnabled = true,
        isValid = false
    }
end

local function setBlipPosition()
    local pos = getCurrentPlayerPosition()
    if pos then
        currentHospitalBuild.position = pos
        validateHospitalBuild()
        return true
    end
    return false
end

local function finalizeHospitalCreation()
    if not validateHospitalBuild() then
        VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette configuration n'est pas valide."})
        return false
    end

    local hospitalData = {
        name = currentHospitalBuild.name,
        pos = currentHospitalBuild.position,
        blipEnabled = currentHospitalBuild.blipEnabled,
        active = true
    }

    TriggerServerEvent('sn_sams:hospital:create', hospitalData)
    resetHospitalBuild()
    return true
end

function StaffMenu.BuildHospitalsMenu()
    if not StaffMenu or not StaffMenu.builderHospital then
        return
    end

    StaffMenu.builderHospital.Button(':plus: CRÉER UN HÔPITAL', 'Créer un nouvel hôpital',
            nil, 'chevron', false, function()
                resetHospitalBuild()
            end, StaffMenu.builderHospitalCreate)

    StaffMenu.builderHospital.Button(':report: GÉRER LES HÔPITAUX', 'Voir et gérer les hôpitaux existants',
            nil, 'chevron', false, function()
                local hospitals = TriggerServerCallback('sn_sams:hospital:getHospitals')
                StaffMenu.currentHospitals = hospitals or {}
            end, StaffMenu.builderHospitalManage)
end

function StaffMenu.BuildCreateHospitalMenu()
    if not StaffMenu or not StaffMenu.builderHospitalCreate then
        return
    end

    StaffMenu.builderHospitalCreate.Button(":edit: NOM: " .. (currentHospitalBuild.name ~= "" and currentHospitalBuild.name or "NON DÉFINI"),
            "Définir le nom de l'hôpital", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Nom de l'hôpital", currentHospitalBuild.name)
                if result and result ~= "" then
                    currentHospitalBuild.name = result
                    validateHospitalBuild()
                    if StaffMenu.builderHospitalCreate.refresh then
                        StaffMenu.builderHospitalCreate.refresh()
                    end
                end
            end)

    local blipPositionText = currentHospitalBuild.position and
            string.format("X: %.2f Y: %.2f Z: %.2f", currentHospitalBuild.position.x,
                    currentHospitalBuild.position.y, currentHospitalBuild.position.z) or "NON DÉFINI"

   StaffMenu.builderHospitalCreate.Button(":pin: POSITION BLIP: " .. blipPositionText,
            "Définir la position du blip sur la carte", nil, "arrow", false,
            function()
                if setBlipPosition() then
                    if StaffMenu.builderHospitalCreate.refresh then
                        StaffMenu.builderHospitalCreate.refresh()
                    end
                    startMarkerThread()
                end
            end)

    StaffMenu.builderHospitalCreate.Button(":pin: BLIP: " .. (currentHospitalBuild.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
            "Activer ou désactiver le blip sur la carte", nil, "arrow", false,
            function()
                currentHospitalBuild.blipEnabled = not currentHospitalBuild.blipEnabled
                if StaffMenu.builderHospitalCreate.refresh then
                    StaffMenu.builderHospitalCreate.refresh()
                end
            end)

    StaffMenu.builderHospitalCreate.Separator(nil)

    local statusMessage = ""
   if not currentHospitalBuild.name or currentHospitalBuild.name == "" then
        statusMessage = "Nom de l'hôpital requis"
   elseif not currentHospitalBuild.position then
        statusMessage = "Position du blip requise"
   else
        statusMessage = "Configuration terminée"
   end

    StaffMenu.builderHospitalCreate.Button(":check: CRÉER L'HÔPITAL", statusMessage,
            nil, "chevron", not currentHospitalBuild.isValid,
            function()
                if finalizeHospitalCreation() and StaffMenu.builderHospitalCreate.close then
                    StaffMenu.builderHospitalCreate.close()
                end
            end)
end

function StaffMenu.BuildManageHospitalsMenu()
    if not StaffMenu or not StaffMenu.builderHospitalManage then
        return
    end

    local hospitals = StaffMenu.currentHospitals or {}
    local hasHospitals = #hospitals > 0

    local separatorText = hasHospitals and 'HÔPITAUX EXISTANTS' or 'AUCUN HÔPITAL'
    StaffMenu.builderHospitalManage.Separator(separatorText)

    if hasHospitals then
        for _, hospitalData in ipairs(hospitals) do
            if hospitalData and hospitalData.name then
                local posText = hospitalData.pos and string.format("X: %.0f Y: %.0f Z: %.0f",
                        hospitalData.pos.x, hospitalData.pos.y, hospitalData.pos.z) or "Position inconnue"

               StaffMenu.builderHospitalManage.Button(":hospital: " .. hospitalData.name .. " #" .. hospitalData.id,
                        posText, nil, 'chevron', false,
                        function()
                            StaffMenu.currentHospitalId = hospitalData.id
                            StaffMenu.currentHospitalData = hospitalData
                        end, StaffMenu.builderHospitalEdit)
            end
        end
    end
end

function StaffMenu.BuildEditHospitalMenu()
    if not StaffMenu or not StaffMenu.builderHospitalEdit then
        return
    end

    local hospitalId = StaffMenu.currentHospitalId
    local hospitalData = StaffMenu.currentHospitalData

    if not hospitalId or not hospitalData then
        return
    end

    StaffMenu.builderHospitalEdit.Separator("HÔPITAL #" .. hospitalId)
    StaffMenu.builderHospitalEdit.Button(":hospital: NOM: " .. hospitalData.name,
            "Modifier le nom de l'hôpital", nil, "arrow", false,
            function()
                local result = VFW.Nui.KeyboardInput(true, "Nom de l'hôpital", hospitalData.name)
                if result and result ~= "" then
                    TriggerServerEvent('sn_sams:hospital:update', hospitalId, 'name', result)
                    hospitalData.name = result
                    if StaffMenu.builderHospitalEdit.refresh then
                        StaffMenu.builderHospitalEdit.refresh()
                    end
                end
            end)

    local blipPosText = hospitalData.pos and string.format("X: %.2f Y: %.2f Z: %.2f",
            hospitalData.pos.x, hospitalData.pos.y, hospitalData.pos.z) or "NON DÉFINI"

   StaffMenu.builderHospitalEdit.Button(":pin: POSITION BLIP: " .. blipPosText,
            "Modifier la position du blip", nil, "arrow", false,
            function()
                local pos = getCurrentPlayerPosition()
                if pos then
                    TriggerServerEvent('sn_sams:hospital:update', hospitalId, 'pos', pos)
                    hospitalData.pos = pos
                    if StaffMenu.builderHospitalEdit.refresh then
                        StaffMenu.builderHospitalEdit.refresh()
                    end
                end
            end)

    StaffMenu.builderHospitalEdit.Button(":check: ACTIF: " .. (hospitalData.active and "OUI" or "NON"),
            "Activer ou désactiver l'hôpital", nil, "arrow", false,
            function()
                local newValue = not hospitalData.active
                TriggerServerEvent('sn_sams:hospital:update', hospitalId, 'active', newValue)
                hospitalData.active = newValue
                if StaffMenu.builderHospitalEdit.refresh then
                    StaffMenu.builderHospitalEdit.refresh()
                end
            end)

    StaffMenu.builderHospitalEdit.Button(":pin: BLIP: " .. (hospitalData.blipEnabled and "ACTIVÉ" or "DÉSACTIVÉ"),
            "Activer ou désactiver le blip", nil, "arrow", false,
            function()
                local newValue = not hospitalData.blipEnabled
                TriggerServerEvent('sn_sams:hospital:update', hospitalId, 'blipEnabled', newValue)
                hospitalData.blipEnabled = newValue
                if StaffMenu.builderHospitalEdit.refresh then
                    StaffMenu.builderHospitalEdit.refresh()
                end
            end)

    StaffMenu.builderHospitalEdit.Separator("POINTS DE SPAWN")

    StaffMenu.builderHospitalEdit.Button(":map: GÉRER LES SPAWNS", "Ajouter ou supprimer des points de spawn",
            nil, "chevron", false,
            function()
                local spawns = TriggerServerCallback('sn_sams:hospital:getSpawns', hospitalId)
                StaffMenu.currentHospitalSpawns = spawns or {}
            end, StaffMenu.builderHospitalSpawns)

    StaffMenu.builderHospitalEdit.Separator("ACTIONS")

    StaffMenu.builderHospitalEdit.Button(":pin: TÉLÉPORTER AU BLIP",
            "Se téléporter à la position du blip", nil, "arrow", false,
            function()
                local pos = hospitalData.pos
                if pos then
                    SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false, true)
                end
            end)

    StaffMenu.builderHospitalEdit.Button(":trash: SUPPRIMER L'HÔPITAL",
            "Supprimer définitivement cet hôpital", nil, "chevron", false,
            function()
                TriggerServerEvent('sn_sams:hospital:delete', hospitalId)
                if StaffMenu.builderHospitalEdit.close then
                    StaffMenu.builderHospitalEdit.close()
                end
                local hospitals = TriggerServerCallback('sn_sams:hospital:getHospitals')
                StaffMenu.currentHospitals = hospitals or {}
            end)
end

function StaffMenu.BuildHospitalSpawnsMenu()
    if not StaffMenu or not StaffMenu.builderHospitalSpawns then
        return
    end

    local hospitalId = StaffMenu.currentHospitalId
    local spawns = StaffMenu.currentHospitalSpawns or {}
    local hasSpawns = #spawns > 0

    StaffMenu.builderHospitalSpawns.Button(":plus: AJOUTER UN SPAWN", "Ajouter votre position actuelle comme point de spawn",
            nil, "arrow", false,
            function()
                local pos = getCurrentPlayerPosition()
                if pos and hospitalId then
                    TriggerServerEvent('sn_sams:hospital:addSpawn', hospitalId, pos)
                    Wait(500)
                    local updatedSpawns = TriggerServerCallback('sn_sams:hospital:getSpawns', hospitalId)
                    StaffMenu.currentHospitalSpawns = updatedSpawns or {}
                    if StaffMenu.builderHospitalSpawns.refresh then
                        StaffMenu.builderHospitalSpawns.refresh()
                    end
                end
            end)

    local separatorText = hasSpawns and ('SPAWNS (' .. #spawns .. ')') or 'AUCUN SPAWN'
    StaffMenu.builderHospitalSpawns.Separator(separatorText)

    if hasSpawns then
        for i, spawn in ipairs(spawns) do
            local posText = string.format("X: %.2f Y: %.2f Z: %.2f", spawn.pos.x, spawn.pos.y, spawn.pos.z)

            StaffMenu.builderHospitalSpawns.Button(":pin: Spawn #" .. i,
                    posText, nil, 'chevron', false,
                    function()
                        StaffMenu.currentSpawnIndex = i
                        StaffMenu.currentSpawnData = spawn
                    end, StaffMenu.builderHospitalSpawnEdit)
        end
    end
end

function StaffMenu.BuildHospitalSpawnEditMenu()
    if not StaffMenu or not StaffMenu.builderHospitalSpawnEdit then
        return
    end

    local hospitalId = StaffMenu.currentHospitalId
    local spawnIndex = StaffMenu.currentSpawnIndex
    local spawn = StaffMenu.currentSpawnData

    if not spawn then return end

    local posText = string.format("X: %.2f Y: %.2f Z: %.2f", spawn.pos.x, spawn.pos.y, spawn.pos.z)

    StaffMenu.builderHospitalSpawnEdit.Separator("SPAWN #" .. spawnIndex)

    StaffMenu.builderHospitalSpawnEdit.Button(":pin: " .. posText,
            "Coordonnées du point de spawn", nil, "check", true, function() end)

    StaffMenu.builderHospitalSpawnEdit.Separator("ACTIONS")

    StaffMenu.builderHospitalSpawnEdit.Button(":pin: SE TÉLÉPORTER",
            "Se téléporter à ce point de spawn", nil, "arrow", false,
            function()
                SetEntityCoords(PlayerPedId(), spawn.pos.x, spawn.pos.y, spawn.pos.z, false, false, false, true)
                if spawn.pos.h then
                    SetEntityHeading(PlayerPedId(), spawn.pos.h)
                end
            end)

    StaffMenu.builderHospitalSpawnEdit.Button(":trash: SUPPRIMER",
            "Supprimer définitivement ce point de spawn", nil, "arrow", false,
            function()
                TriggerServerEvent('sn_sams:hospital:removeSpawn', spawn.id)
                if StaffMenu.builderHospitalSpawnEdit.close then
                    StaffMenu.builderHospitalSpawnEdit.close()
                end
                Wait(500)
                local updatedSpawns = TriggerServerCallback('sn_sams:hospital:getSpawns', hospitalId)
                StaffMenu.currentHospitalSpawns = updatedSpawns or {}
            end)
end

-- OnOpen hooks
if StaffMenu and StaffMenu.builderHospital and StaffMenu.builderHospital.OnOpen then
    StaffMenu.builderHospital.OnOpen(function()
        StaffMenu.BuildHospitalsMenu()
    end)
end

if StaffMenu and StaffMenu.builderHospitalCreate then
    if StaffMenu.builderHospitalCreate.OnOpen then
        StaffMenu.builderHospitalCreate.OnOpen(function()
            StaffMenu.BuildCreateHospitalMenu()
            if currentHospitalBuild.position then
                startMarkerThread()
            end
        end)
    end

    if StaffMenu.builderHospitalCreate.OnClose then
        StaffMenu.builderHospitalCreate.OnClose(function()
            stopMarkerThread()
        end)
    end
end

if StaffMenu and StaffMenu.builderHospitalManage and StaffMenu.builderHospitalManage.OnOpen then
    StaffMenu.builderHospitalManage.OnOpen(function()
        local hospitals = TriggerServerCallback('sn_sams:hospital:getHospitals')
        StaffMenu.currentHospitals = hospitals or {}
        StaffMenu.BuildManageHospitalsMenu()
    end)
end

if StaffMenu and StaffMenu.builderHospitalEdit and StaffMenu.builderHospitalEdit.OnOpen then
    StaffMenu.builderHospitalEdit.OnOpen(function()
        StaffMenu.BuildEditHospitalMenu()
    end)
end

if StaffMenu and StaffMenu.builderHospitalSpawns and StaffMenu.builderHospitalSpawns.OnOpen then
    StaffMenu.builderHospitalSpawns.OnOpen(function()
        local hospitalId = StaffMenu.currentHospitalId
        if hospitalId then
            local spawns = TriggerServerCallback('sn_sams:hospital:getSpawns', hospitalId)
            StaffMenu.currentHospitalSpawns = spawns or {}
        end
        StaffMenu.BuildHospitalSpawnsMenu()
    end)
end

if StaffMenu and StaffMenu.builderHospitalSpawnEdit and StaffMenu.builderHospitalSpawnEdit.OnOpen then
    StaffMenu.builderHospitalSpawnEdit.OnOpen(function()
        StaffMenu.BuildHospitalSpawnEditMenu()
    end)
end
