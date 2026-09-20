---@meta _
---@diagnostic disable: duplicate-doc-field

-- Builder pour les stations d'essence
local currentGasStationBuild = {
    name = "",
    coords = nil,
    blipCoords = nil,
    usePlayerPosition = true,
    pumps = {},
    pricePerLiter = (GasStationConfig.PriceRange.min + GasStationConfig.PriceRange.max) / 2,
    isValid = false
}

local markerThread = nil
local isMarkersActive = false

--- Valide si la station en construction est valide
---@return boolean isValid
local function validateGasStationBuild()
    currentGasStationBuild.isValid = currentGasStationBuild.name ~= "" and
                                   currentGasStationBuild.coords ~= nil and
                                   #currentGasStationBuild.pumps > 0
    return currentGasStationBuild.isValid
end

--- Obtient la position actuelle du joueur
---@return table|nil position
local function getCurrentPlayerPosition()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then
        return nil
    end

    local coords = GetEntityCoords(playerPed)
    if not coords then
        return nil
    end

    return vector3(coords.x, coords.y, coords.z)
end

--- Scanner les pompes à essence autour d'une position
---@param center vector3
---@param radius number
---@return table pumps
local function scanGasPumpsAround(center, radius)
    local foundPumps = {}
    local objects = GetGamePool('CObject')

    for _, obj in ipairs(objects) do
        local model = GetEntityModel(obj)
        for _, pumpModel in ipairs(GasStationConfig.GasPumpModels) do
            if model == pumpModel then
                local objCoords = GetEntityCoords(obj)
                local distance = #(center - objCoords)
                if distance <= radius then
                    table.insert(foundPumps, {
                        entity = obj,
                        coords = objCoords,
                        model = model,
                        heading = GetEntityHeading(obj)
                    })
                end
                break
            end
        end
    end

    return foundPumps
end

--- Arrête le thread des marqueurs
local function stopMarkerThread()
    isMarkersActive = false
    markerThread = nil
end

--- Démarre l'affichage des marqueurs pour les pompes
local function startPumpMarkers()
    if isMarkersActive then
        return
    end

    isMarkersActive = true
    markerThread = CreateThread(function()
        while isMarkersActive do
            Wait(0)
            for i, pump in ipairs(currentGasStationBuild.pumps) do
                -- Marqueur vert pour les pompes détectées
                DrawMarker(1, pump.coords.x, pump.coords.y, pump.coords.z - 1.0,
                          0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                          2.0, 2.0, 1.0,
                          0, 255, 0, 150,
                          false, true, 2, false, nil, nil, false)

                -- Texte avec le numéro de la pompe
                local onScreen, screenX, screenY = World3dToScreen2d(pump.coords.x, pump.coords.y, pump.coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 255, 255, 215)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(2, 0, 0, 0, 150)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextCentre(true)
                    BeginTextCommandDisplayText("STRING")
                    AddTextComponentSubstringPlayerName("Pompe " .. i)
                    EndTextCommandDisplayText(screenX, screenY)
                end
            end

            -- Marqueur bleu pour le centre de la station si défini
            if currentGasStationBuild.coords then
                DrawMarker(1, currentGasStationBuild.coords.x, currentGasStationBuild.coords.y, currentGasStationBuild.coords.z - 1.0,
                          0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                          3.0, 3.0, 1.0,
                          0, 100, 255, 150,
                          false, true, 2, false, nil, nil, false)
            end
        end
        markerThread = nil
    end)
end

--- Réinitialise la construction de la station
local function resetGasStationBuild()
    stopMarkerThread()

    currentGasStationBuild = {
        name = "",
        coords = nil,
        blipCoords = nil,
        usePlayerPosition = true,
        pumps = {},
        pricePerLiter = (GasStationConfig.PriceRange.min + GasStationConfig.PriceRange.max) / 2,
        isValid = false
    }
end

--- Menu principal du builder de stations d'essence
function StaffMenu.BuildGasStationBuilderMenu()
    -- Titre et informations
    StaffMenu.gasStationBuilder.Separator(":building: CONSTRUCTION DE STATION D'ESSENCE")

    -- Nom de la station
    local nameLabel = currentGasStationBuild.name == "" and "Aucun nom défini" or currentGasStationBuild.name
    StaffMenu.gasStationBuilder.Button(":edit: NOM DE LA STATION", nameLabel, nil, nil, false, function()
        local result = VFW.Nui.KeyboardInput(true, "Nom de la station d'essence", currentGasStationBuild.name)
        if result and result ~= "" then
            currentGasStationBuild.name = result
            -- Délai pour éviter les conflits de callbacks
            SetTimeout(50, function()
                StaffMenu.gasStationBuilder.refresh()
            end)
        end
    end)

    -- Position du centre de la station
    StaffMenu.gasStationBuilder.Separator(":pin: POSITION DU CENTRE")

    local coordsLabel = currentGasStationBuild.coords and
        string.format("%.1f, %.1f, %.1f", currentGasStationBuild.coords.x, currentGasStationBuild.coords.y, currentGasStationBuild.coords.z) or
        "Position non définie"

   StaffMenu.gasStationBuilder.Button(":pin: DÉFINIR POSITION", coordsLabel, nil, nil, false, function()
        currentGasStationBuild.coords = getCurrentPlayerPosition()
        if currentGasStationBuild.coords then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = "Stations d'essence",
                message = "Position définie. Scan automatique des pompes en cours..."
           })

            -- Arrêter les marqueurs existants au cas où
            stopMarkerThread()

            -- Réinitialiser la liste des pompes avant le scan
            currentGasStationBuild.pumps = {}

            -- Scanner les pompes
            currentGasStationBuild.pumps = scanGasPumpsAround(currentGasStationBuild.coords, GasStationConfig.ScanRadius)

            if #currentGasStationBuild.pumps == 0 then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'INFO',
                    subtitle = "Stations d'essence",
                    message = "Aucune pompe détectée. Utilisez 'Scanner les pompes' pour réessayer."
               })
            else
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = "Stations d'essence",
                    message = #currentGasStationBuild.pumps .. (#currentGasStationBuild.pumps > 1 and " pompes détectées automatiquement." or " pompe détectée automatiquement.")
               })

                -- Afficher les marqueurs pendant 5 secondes
                startPumpMarkers()
                SetTimeout(5000, function()
                    stopMarkerThread()
                end)
            end

            SetTimeout(50, function()
                StaffMenu.gasStationBuilder.refresh()
            end)
        end
    end)

    -- Gestion du blip
    StaffMenu.gasStationBuilder.Separator(":map: BLIP SUR LA CARTE")

    StaffMenu.gasStationBuilder.Checkbox("UTILISER POSITION DU JOUEUR", nil, false, currentGasStationBuild.usePlayerPosition, function(checked)
        currentGasStationBuild.usePlayerPosition = checked
        if checked then
            currentGasStationBuild.blipCoords = nil
        end
        SetTimeout(50, function()
            StaffMenu.gasStationBuilder.refresh()
        end)
    end)

    if not currentGasStationBuild.usePlayerPosition then
        local blipLabel = currentGasStationBuild.blipCoords and
            string.format("%.1f, %.1f, %.1f", currentGasStationBuild.blipCoords.x, currentGasStationBuild.blipCoords.y, currentGasStationBuild.blipCoords.z) or
            "Position du blip non définie"

       StaffMenu.gasStationBuilder.Button(":pin: POSITION DU BLIP", blipLabel, nil, nil, false, function()
            currentGasStationBuild.blipCoords = getCurrentPlayerPosition()
            SetTimeout(50, function()
                StaffMenu.gasStationBuilder.refresh()
            end)
        end)
    end

    -- Gestion des pompes
    StaffMenu.gasStationBuilder.Separator(":car: POMPES DÉTECTÉES (" .. #currentGasStationBuild.pumps .. ")")

    StaffMenu.gasStationBuilder.Button(":search: RESCAN MANUEL", "Relancer le scan des pompes (distance custom)", nil, "chevron", false, function()
        if currentGasStationBuild.coords then
            local radiusInput = VFW.Nui.KeyboardInput(true, "Distance de scan (metres)", tostring(GasStationConfig.ScanRadius))

            local scanRadius = tonumber(radiusInput)
            if not scanRadius or scanRadius <= 0 then
                scanRadius = GasStationConfig.ScanRadius
            end

            if scanRadius > 500 then
                scanRadius = 500
            end

            stopMarkerThread()

            currentGasStationBuild.pumps = {}

            currentGasStationBuild.pumps = scanGasPumpsAround(currentGasStationBuild.coords, scanRadius)

            if #currentGasStationBuild.pumps == 0 then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'INFO',
                    subtitle = "Stations d'essence",
                    message = "Rescan : aucune pompe détectée dans un rayon de " .. scanRadius .. "m."
               })
            else
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = "Stations d'essence",
                    message = "Rescan : " .. #currentGasStationBuild.pumps .. (#currentGasStationBuild.pumps > 1 and " pompes détectées (" or " pompe détectée (") .. scanRadius .. "m)."
               })

                startPumpMarkers()
                SetTimeout(5000, function()
                    stopMarkerThread()
                end)
            end

            SetTimeout(50, function()
                StaffMenu.gasStationBuilder.refresh()
            end)
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = "Stations d'essence",
                message = "Définissez d'abord la position du centre de la station."
           })
        end
    end)

    -- Actions
    StaffMenu.gasStationBuilder.Separator(":wrench: ACTIONS")

    -- Validation et état dynamique du bouton
    validateGasStationBuild()
    local createLabel = currentGasStationBuild.isValid and ":check: CRÉER LA STATION" or ":x: DONNÉES INCOMPLÈTES"
   local createEnabled = not currentGasStationBuild.isValid  -- false = cliquable, true = non cliquable dans VUI

    StaffMenu.gasStationBuilder.Button(createLabel, nil, nil, "check", createEnabled, function()
        -- Re-valider au moment du clic pour être sûr
        validateGasStationBuild()

        if not currentGasStationBuild.isValid then
            local message = ":x: Données manquantes :"
           if currentGasStationBuild.name == "" then
                message = message .. "\n• Définissez un nom pour la station"
           end
            if not currentGasStationBuild.coords then
                message = message .. "\n• Définissez la position de la station"
           end
            if #currentGasStationBuild.pumps == 0 then
                message = message .. "\n• Aucune pompe détectée (scanner requis)"
           end

            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = "Stations d'essence",
                message = message
            })
            return
        end

        -- Envoyer au serveur
        local stationData = {
            name = currentGasStationBuild.name,
            coords = currentGasStationBuild.coords,
            blipCoords = currentGasStationBuild.usePlayerPosition and currentGasStationBuild.coords or currentGasStationBuild.blipCoords,
            pumps = currentGasStationBuild.pumps
        }

        TriggerServerEvent("fl_gasstation:createStation", stationData)

        -- Réinitialiser
        resetGasStationBuild()
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = "Stations d'essence",
            message = "Station d'essence créée."
       })

        -- Retourner au menu principal des stations d'essence
        SetTimeout(500, function()
            if StaffMenu.gasStationMain and StaffMenu.gasStationMain.open then
                StaffMenu.gasStationMain.open()
            end
        end)

    end)

    StaffMenu.gasStationBuilder.Button(":refresh: RÉINITIALISER", "Effacer toutes les données", nil, "chevron", false, function()
        resetGasStationBuild()
        SetTimeout(50, function()
            StaffMenu.gasStationBuilder.refresh()
        end)
    end)
end

-- Enregistrer le menu et l'OnOpen avec délai pour s'assurer que VUI est prêt
CreateThread(function()
    Wait(1000) -- Attendre que tout soit chargé

    if StaffMenu and StaffMenu.gasStationBuilder then
        StaffMenu.BuildGasStationBuilderMenu = StaffMenu.BuildGasStationBuilderMenu

        -- Enregistrer l'événement OnOpen seulement si le menu existe
        if StaffMenu.gasStationBuilder.OnOpen then
            StaffMenu.gasStationBuilder.OnOpen(function()
                StaffMenu.BuildGasStationBuilderMenu()
            end)
        end
    end
end)