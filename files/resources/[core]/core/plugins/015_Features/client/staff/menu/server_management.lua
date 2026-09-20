---@meta _
---@diagnostic disable: duplicate-doc-field


local serverData = {
    weatherIndex = 1,
    weatherList = {
        {label = "Clair", value = "CLEAR"},
        {label = "Très ensoleillé", value = "EXTRASUNNY"},
        {label = "Nuageux", value = "CLOUDS"},
        {label = "Couvert", value = "OVERCAST"},
        {label = "Pluie", value = "RAIN"},
        {label = "Éclaircie", value = "CLEARING"},
        {label = "Orage", value = "THUNDER"},
        {label = "Brouillard épais", value = "SMOG"},
        {label = "Brumeux", value = "FOGGY"},
        {label = "Noël", value = "XMAS"},
        {label = "Neige légère", value = "SNOWLIGHT"},
        {label = "Blizzard", value = "BLIZZARD"}
    },
    timeHour = 12,
    timeMinute = 0,
    freezeTime = false,
    freezeWeather = false,
    announceText = ""
}

StaffMenu.selectedWeatherIndex = 1
StaffMenu.weatherPreviewActive = false

-- Build Server Management Menu
function StaffMenu.BuildServerManagementMenu()
    StaffMenu.serverManagement.ClearItems()

    StaffMenu.serverManagement.Separator(":globe: GESTION MÉTÉO")


    StaffMenu.serverManagement.Button(":globe: TABLETTE MÉTÉO AVANCÉE", "Ouvrir la tablette de gestion météo par zone avec carte interactive", nil, "chevron", false, function()
        StaffMenu.serverManagement.close()
        SetTimeout(300, function()
            OpenWeatherManagerTablet()
        end)
    end)


    -- Weather control
    local weatherLabels = {}
    for _, weather in ipairs(serverData.weatherList) do
        table.insert(weatherLabels, weather.label)
    end

    StaffMenu.serverManagement.List2(":globe: Météo", "Choisir avec :back::arrow: puis confirmer avec Entrée", false, weatherLabels, StaffMenu.selectedWeatherIndex, function(index, item)
        StaffMenu.selectedWeatherIndex = index
        local selectedWeather = serverData.weatherList[index]
        SetWeatherTypeNow(selectedWeather.value)
        SetWeatherTypeOvertimePersist(selectedWeather.value, 5.0)
        StaffMenu.weatherPreviewActive = true
    end, function(index, item)
        local selectedWeather = serverData.weatherList[index]
        StaffMenu.weatherPreviewActive = false
        TriggerServerEvent("vfw:staff:setWeather", selectedWeather.value)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Serveur',
            message = "Météo appliquée: " .. selectedWeather.label .. "."
      })
    end)

    StaffMenu.serverManagement.Checkbox(":sparkles: GELER LA MÉTÉO", "Figer la météo actuelle pour qu'elle ne change plus automatiquement", false, serverData.freezeWeather, function(_checked)
        serverData.freezeWeather = _checked
        TriggerServerEvent("vfw:staff:freezeWeather", _checked)
    end)
    
    StaffMenu.serverManagement.Separator(":clock: GESTION DU TEMPS")
    
    -- Time control - Create hour list (0-23)
    local hoursList = {}
    for i = 0, 23 do
        table.insert(hoursList, string.format("%02d", i))
    end
    
    -- Create minutes list (0-59, by 5)
    local minutesList = {}
    for i = 0, 59, 5 do
        table.insert(minutesList, string.format("%02d", i))
    end
    
    StaffMenu.serverManagement.List(":clock: Heure", "Choisir l'heure à appliquer sur le serveur (0-23)", false, hoursList, serverData.timeHour + 1, function(index, item)
        serverData.timeHour = index - 1
    end)
    
    StaffMenu.serverManagement.List(":clock: Minutes", "Choisir les minutes à appliquer (par tranches de 5 minutes)", false, minutesList, math.floor(serverData.timeMinute / 5) + 1, function(index, item)
        serverData.timeMinute = (index - 1) * 5
    end)
    
    StaffMenu.serverManagement.Button(":check: APPLIQUER LE TEMPS", "Appliquer l'heure et les minutes sélectionnées à tous les joueurs", nil, "chevron", false, function()
        TriggerServerEvent("vfw:staff:setTime", serverData.timeHour, serverData.timeMinute)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Serveur',
            message = string.format("Temps changé: %02d:%02d.", serverData.timeHour, serverData.timeMinute)
        })
    end)
    
    StaffMenu.serverManagement.Checkbox("⏸ GELER LE TEMPS", "Figer l'heure actuelle pour que le temps ne s'écoule plus", false, serverData.freezeTime, function(_checked)
        serverData.freezeTime = _checked
        TriggerServerEvent("vfw:staff:freezeTime", _checked)
    end)
    
    -- Clear area
    local perms = VFW.PlayerGlobalData.permissions or {}
    if perms["clean_zone"] then
        StaffMenu.serverManagement.Button(":trash: NETTOYER LA ZONE", "Supprimer véhicules, peds et objets dans un rayon autour de vous", nil, "chevron", false, function()
            local radius = VFW.Nui.KeyboardInput(true, "Radius (mètres)", "100")
            radius = tonumber(radius)

            if radius and radius > 0 then
                TriggerServerEvent("vfw:staff:clearZone", radius)
            end
        end)
    end

    
    -- Refresh server data
    StaffMenu.serverManagement.Button(":refresh: RAFRAÎCHIR LES DONNÉES", "Recharger les données et statistiques serveur en temps réel", nil, "chevron", false, function()
        TriggerServerEvent("vfw:staff:refreshServerData")
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Gestion Serveur',
            message = "Données serveur rafraîchies."
      })
    end)
    
    -- Server statistics
    StaffMenu.serverManagement.Separator(":chart: STATISTIQUES SERVEUR")

    -- Utiliser le cache pre-fetched si disponible, sinon afficher placeholder
    local stats = StaffMenu.cachedServerStats or {
        players = "...",
        staff = "...",
        resources = "...",
        uptime = "..."
  }

    StaffMenu.serverManagement.Button(":users: Joueurs en ligne", tostring(stats.players), nil, nil, true, function() end)
    StaffMenu.serverManagement.Button(":police: Staff en ligne", tostring(stats.staff), nil, nil, true, function() end)
    StaffMenu.serverManagement.Button(":box: Ressources actives", tostring(stats.resources), nil, nil, true, function() end)
    StaffMenu.serverManagement.Button(":clock: Uptime", tostring(stats.uptime), nil, nil, true, function() end)

    -- Si le cache n'est pas encore prêt, le charger en arrière-plan
    if not StaffMenu.cachedServerStats then
        Citizen.CreateThread(function()
            StaffMenu.cachedServerStats = TriggerServerCallback("vfw:staff:getServerStats") or {}
            -- Rebuild le menu quand les données arrivent
            if StaffMenu.cachedServerStats.players then
                StaffMenu.BuildServerManagementMenu()
            end
        end)
    end
end


