---@meta _
---@diagnostic disable: duplicate-doc-field

-- Menu de configuration des stations d'essence

--- Menu pour changer le prix global de l'essence
function StaffMenu.BuildGasStationConfigMenu()
    local settings = TriggerServerCallback("fl_gasstation:getSettings") or {}
    local currentPrice = settings.global_price or 150
    local priceMin = settings.price_min or 100
    local priceMax = settings.price_max or 250
    local timePerLiter = settings.time_per_liter or 0.5

    StaffMenu.gasStationConfig.Separator(":money: PRIX")

    StaffMenu.gasStationConfig.Button(":money: PRIX ACTUEL", VFW.Math.FormatMoney(currentPrice, { decimals = 0 }) .. " /L", nil, nil, false, function()
        local result = VFW.Nui.KeyboardInput(true, "Nouveau prix par litre", tostring(currentPrice))
        if result and tonumber(result) then
            local newPrice = tonumber(result)
            if newPrice > 0 then
                TriggerServerEvent("fl_gasstation:setGlobalPrice", newPrice)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = "Stations d'essence", message = "Prix mis à jour : " .. VFW.Math.FormatMoney(newPrice, { decimals = 0 }) .. "." })
                StaffMenu.gasStationConfig.refresh()
            end
        end
    end)

    StaffMenu.gasStationConfig.Button(":chart: PRIX MINIMUM", VFW.Math.FormatMoney(priceMin, { decimals = 0 }) .. " /L", nil, nil, false, function()
        local result = VFW.Nui.KeyboardInput(true, "Prix minimum", tostring(priceMin))
        if result and tonumber(result) then
            local newVal = tonumber(result)
            if newVal > 0 then
                TriggerServerEvent("fl_gasstation:setSetting", "price_min", newVal)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = "Stations d'essence", message = "Prix minimum : " .. VFW.Math.FormatMoney(newVal, { decimals = 0 }) .. "." })
                StaffMenu.gasStationConfig.refresh()
            end
        end
    end)

    StaffMenu.gasStationConfig.Button(":chart: PRIX MAXIMUM", VFW.Math.FormatMoney(priceMax, { decimals = 0 }) .. " /L", nil, nil, false, function()
        local result = VFW.Nui.KeyboardInput(true, "Prix maximum", tostring(priceMax))
        if result and tonumber(result) then
            local newVal = tonumber(result)
            if newVal > 0 then
                TriggerServerEvent("fl_gasstation:setSetting", "price_max", newVal)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = "Stations d'essence", message = "Prix maximum : " .. VFW.Math.FormatMoney(newVal, { decimals = 0 }) .. "." })
                StaffMenu.gasStationConfig.refresh()
            end
        end
    end)

    StaffMenu.gasStationConfig.Button(":gamepad: PRIX ALÉATOIRE", "Générer entre min/max", nil, "chevron", false, function()
        TriggerServerEvent("fl_gasstation:generateRandomPrice")
        Wait(500)
        StaffMenu.gasStationConfig.refresh()
    end)

    StaffMenu.gasStationConfig.Separator(":clock: TEMPS")

    StaffMenu.gasStationConfig.Button(":car: TEMPS PAR LITRE", string.format("%.2f", timePerLiter) .. " secondes", nil, nil, false, function()
        local result = VFW.Nui.KeyboardInput(true, "Secondes par litre", tostring(timePerLiter))
        if result and tonumber(result) then
            local newVal = tonumber(result)
            if newVal > 0 then
                TriggerServerEvent("fl_gasstation:setSetting", "time_per_liter", newVal)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = "Stations d'essence", message = "Temps par litre : " .. string.format("%.2f", newVal) .. "s." })
                StaffMenu.gasStationConfig.refresh()
            end
        end
    end)

    StaffMenu.gasStationConfig.Separator(":chart: STATISTIQUES")

    -- Charger le nombre de stations directement
    local stationCount = TriggerServerCallback("fl_gasstation:getStationCount")
    local countLabel = stationCount .. (stationCount > 1 and " stations créées" or " station créée")

   StaffMenu.gasStationConfig.Button(":chart: STATIONS CRÉÉES", countLabel, nil, nil, false, function()
        -- Peut être étendu pour afficher plus de détails
    end)

    StaffMenu.gasStationConfig.Separator(":folder: GESTION DES STATIONS")

    StaffMenu.gasStationConfig.Button(":report: LISTE DES STATIONS", "Voir toutes les stations", nil, "chevron", false, function()
        -- Juste ouvrir le menu, le OnOpen callback se chargera de le construire
        if StaffMenu.gasStationList and StaffMenu.gasStationList.open then
            StaffMenu.gasStationList.open()
        end
    end)

    StaffMenu.gasStationConfig.Button(":trash: SUPPRIMER UNE STATION", "Supprimer par ID", nil, "trash", false, function()
        local result = VFW.Nui.KeyboardInput(true, "ID de la station à supprimer", "")
        if result and result ~= "" then
            TriggerServerEvent("fl_gasstation:deleteStation", result)
        end
    end)
end

--- Menu pour lister les stations existantes
function StaffMenu.BuildGasStationListMenu()
    -- Vider le menu existant
    if StaffMenu.gasStationList and StaffMenu.gasStationList.clear then
        StaffMenu.gasStationList.clear()
    end

    -- Récupérer les stations
    local stations = TriggerServerCallback("fl_gasstation:getStationList")
    stations = stations or {}

    -- Header du menu
    StaffMenu.gasStationList.Separator(":car: STATIONS D'ESSENCE (" .. #stations .. ")")

    if #stations == 0 then
        StaffMenu.gasStationList.Button(":document: AUCUNE STATION", "Aucune station créée", nil, nil, false, function() end)
    else
        for i, station in ipairs(stations) do
            if station and type(station) == "table" then
                local stationName = station.name or "Station sans nom"
               local distance = 0
                local pumpCount = 0

                -- Calcul sécurisé de la distance
                if station.coords and type(station.coords) == "table" and station.coords.x and station.coords.y and station.coords.z then
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    distance = #(playerCoords - vector3(station.coords.x, station.coords.y, station.coords.z))
                end

                -- Comptage sécurisé des pompes
                if station.pumps and type(station.pumps) == "table" then
                    pumpCount = #station.pumps
                end

                local label = string.format("%.0fm | %d pompes", distance, pumpCount)

                StaffMenu.gasStationList.Button(":car: " .. stationName, label, nil, "chevron", false, function()
                    -- Stocker les données de la station sélectionnée
                    StaffMenu.selectedStation = station
                end, StaffMenu.gasStationDetails)
            end
        end
    end

    StaffMenu.gasStationList.Separator()
    StaffMenu.gasStationList.Button(":refresh: ACTUALISER", "Recharger la liste", nil, "chevron", false, function()
        StaffMenu.BuildGasStationListMenu()
        if StaffMenu.gasStationList and StaffMenu.gasStationList.open then
            StaffMenu.gasStationList.open()
        end
    end)
end

--- Menu de détails pour une station sélectionnée
function StaffMenu.BuildGasStationDetailsMenu()
    local station = StaffMenu.selectedStation
    if not station then
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'ERROR',
            subtitle = "Stations d'essence",
            message = "Aucune station sélectionnée."
       })
        return
    end

    -- Informations de la station
    StaffMenu.gasStationDetails.Separator(":car: " .. (station.name or "Station"))

    -- Distance du joueur
    local distance = 0
    if station.coords and station.coords.x and station.coords.y and station.coords.z then
        local playerCoords = GetEntityCoords(PlayerPedId())
        distance = #(playerCoords - vector3(station.coords.x, station.coords.y, station.coords.z))
    end

    StaffMenu.gasStationDetails.Button(":pin: DISTANCE", string.format("%.0f mètres", distance), nil, nil, true, function() end)

    -- Nombre de pompes
    local pumpCount = 0
    if station.pumps and type(station.pumps) == "table" then
        pumpCount = #station.pumps
    end
    StaffMenu.gasStationDetails.Button(":car: POMPES", pumpCount .. (pumpCount > 1 and " pompes détectées" or " pompe détectée"), nil, nil, true, function() end)

    -- Prix global (affiché pour info)
    local globalPrice = TriggerServerCallback("fl_gasstation:getGlobalPrice") or 0
    StaffMenu.gasStationDetails.Button(":money: PRIX GLOBAL", VFW.Math.FormatMoney(globalPrice, { decimals = 0 }) .. " par litre", nil, nil, true, function() end)

    -- ID de la station
    StaffMenu.gasStationDetails.Button(":id: ID STATION", station.id or "Inconnu", nil, nil, true, function() end)

    -- Coordonnées
    if station.coords then
        local coordsText = string.format("%.1f, %.1f, %.1f", station.coords.x, station.coords.y, station.coords.z)
        StaffMenu.gasStationDetails.Button(":map: COORDONNÉES", coordsText, nil, nil, true, function() end)
    end

    StaffMenu.gasStationDetails.Separator(":wrench: ACTIONS")

    -- Téléportation
    StaffMenu.gasStationDetails.Button(":pin: SE TÉLÉPORTER", "Aller à cette station", nil, "chevron", false, function()
        if station.coords and station.coords.x and station.coords.y and station.coords.z then
            SetEntityCoords(PlayerPedId(), station.coords.x, station.coords.y, station.coords.z + 1.0)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = "Stations d'essence",
                message = "Téléporté à " .. (station.name or "la station") .. "."
           })
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = "Stations d'essence",
                message = "Cette position de la station n'est pas valide."
           })
        end
    end)

    -- Suppression
    StaffMenu.gasStationDetails.Button(":trash: SUPPRIMER", "Supprimer cette station", nil, "trash", false, function()
        local confirmResult = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour supprimer", "")
        if confirmResult and confirmResult:upper() == "CONFIRMER" then
            TriggerServerEvent("fl_gasstation:deleteStation", station.id)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = "Stations d'essence",
                message = "Station '" .. (station.name or "Inconnue") .. "' supprimée."
           })
            -- Retourner au menu précédent
            SetTimeout(500, function()
                if StaffMenu.gasStationList and StaffMenu.gasStationList.open then
                    StaffMenu.gasStationList.open()
                end
            end)
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'INFO',
                subtitle = "Stations d'essence",
                message = "Suppression annulée."
           })
        end
    end)
end

-- Enregistrer les menus et les OnOpen avec délai pour s'assurer que VUI est prêt
CreateThread(function()
    Wait(1000) -- Attendre que tout soit chargé

    if StaffMenu and StaffMenu.gasStationConfig and StaffMenu.gasStationList and StaffMenu.gasStationDetails then
        -- Enregistrer les événements OnOpen seulement si les menus existent
        if StaffMenu.gasStationConfig.OnOpen then
            StaffMenu.gasStationConfig.OnOpen(function()
                StaffMenu.BuildGasStationConfigMenu()
            end)
        end

        if StaffMenu.gasStationList.OnOpen then
            StaffMenu.gasStationList.OnOpen(function()
                StaffMenu.BuildGasStationListMenu()
            end)
        end

        if StaffMenu.gasStationDetails.OnOpen then
            StaffMenu.gasStationDetails.OnOpen(function()
                StaffMenu.BuildGasStationDetailsMenu()
            end)
        end
    end
end)