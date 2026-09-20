StaffMenu = StaffMenu or {}
StaffMenu.firePreview = { active = false, radius = 0 }

CreateThread(function()
    while true do
        if StaffMenu.firePreview.active and StaffMenu.firePreview.radius > 0 then
            local coords = GetEntityCoords(PlayerPedId())
            local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
            local z = groundZ or (coords.z - 0.5)
            DrawMarker(1, coords.x, coords.y, z, 0, 0, 0, 0, 0, 0, StaffMenu.firePreview.radius * 2.0, StaffMenu.firePreview.radius * 2.0, 1.0, 255, 80, 20, 120, false, false, 2, false, nil, nil, false)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

local function StartRangePreview(radius)
    StaffMenu.firePreview.radius = radius
    StaffMenu.firePreview.active = true
end

local function StopRangePreview()
    StaffMenu.firePreview.active = false
    StaffMenu.firePreview.radius = 0
end

function StaffMenu.StopFireRangePreview()
    StopRangePreview()
end

local fireData = {
    blackout = false,
    fireTypeIndex = 1,
    fireTypeList = {
        {label = "Normal", value = "normal"},
        {label = "Chimique", value = "chemical"},
        {label = "Électrique", value = "electrical"},
        {label = "Feu de camp", value = "bonfire"}
    },
    fireDuration = 10,
    fireRange = 15,
    fireIntensity = 5,
    fireNotify = false,
    fireAlarm = false,
    fireAlarmDelay = 30,
    notifyRange = 30
}

function StaffMenu.BuildSpecialEventMenu()

    StaffMenu.specialEffects.Separator("EFFETS ENVIRONNEMENT")

    StaffMenu.specialEffects.Checkbox(":bolt: BLACKOUT (Coupure électrique)", "Éteindre tous les éclairages publics de la ville", false, fireData.blackout, function(_checked)
        fireData.blackout = _checked
        TriggerServerEvent("vfw:staff:setBlackout", _checked)
    end)

    StaffMenu.specialEffects.Separator("ÉVÈNEMENTS")

    StaffMenu.specialEffects.Button(":fire: Incendie", "Créer et gérer des incendies", nil, "chevron", false, function()
    end, StaffMenu.fireMenu)

    StaffMenu.specialEffects.Button(":sparkles: Feu d'artifice", "Lancer un spectacle pyrotechnique", nil, "chevron", false, function()
    end, StaffMenu.fireworkMenu)

    StaffMenu.specialEffects.Button(":globe: Séisme", "Déclencher un séisme", nil, "chevron", false, function()
    end, StaffMenu.earthquakeMenu)

end

function StaffMenu.BuildFireMenu()
    StartRangePreview(fireData.fireRange)

    local fireTypeLabels = {}
    for _, ft in ipairs(fireData.fireTypeList) do
        table.insert(fireTypeLabels, ft.label)
    end

    StaffMenu.fireMenu.Separator("CONFIGURATION")

    StaffMenu.fireMenu.List("Type de feu", "Sélectionner le type d'incendie", false, fireTypeLabels, fireData.fireTypeIndex, function(index)
        fireData.fireTypeIndex = index
    end)

    StaffMenu.fireMenu.Button("Durée", "Durée avant extinction automatique", tostring(fireData.fireDuration) .. " min", "chevron", false, function()
        local input = tonumber(VFW.Nui.KeyboardInput(true, "Durée en minutes (1-30)", tostring(fireData.fireDuration)))
        if input and input >= 1 and input <= 30 then
            fireData.fireDuration = input
            StaffMenu.fireMenu.refresh()
        end
    end)

    StaffMenu.fireMenu.Button("Portée", "Rayon de l'incendie en mètres", tostring(fireData.fireRange) .. " m", "chevron", false, function()
        local input = tonumber(VFW.Nui.KeyboardInput(true, "Portée en mètres (1-100)", tostring(fireData.fireRange)))
        if input and input >= 1 and input <= 100 then
            fireData.fireRange = input
            StartRangePreview(input)
            StaffMenu.fireMenu.refresh()
        end
    end)

    StaffMenu.fireMenu.Button("Intensité", "Puissance du feu (1 = faible, 10 = extrême)", tostring(fireData.fireIntensity), "chevron", false, function()
        local input = tonumber(VFW.Nui.KeyboardInput(true, "Intensité (1-10)", tostring(fireData.fireIntensity)))
        if input and input >= 1 and input <= 10 then
            fireData.fireIntensity = input
            StaffMenu.fireMenu.refresh()
        end
    end)

    StaffMenu.fireMenu.Separator("OPTIONS")

    StaffMenu.fireMenu.Checkbox("Notifier les joueurs", "Prévenir les joueurs proches de la zone", false, fireData.fireNotify, function(_checked)
        fireData.fireNotify = _checked
    end)

    StaffMenu.fireMenu.Checkbox("Alarme avant le feu", "Déclencher une alarme avant l'incendie", false, fireData.fireAlarm, function(_checked)
        fireData.fireAlarm = _checked
    end)

    StaffMenu.fireMenu.Button("Délai alarme", "Temps entre l'alarme et le départ du feu", tostring(fireData.fireAlarmDelay) .. " sec", "chevron", fireData.fireAlarm == false, function()
        local input = tonumber(VFW.Nui.KeyboardInput(true, "Délai en secondes (10-120)", tostring(fireData.fireAlarmDelay)))
        if input and input >= 10 and input <= 120 then
            fireData.fireAlarmDelay = input
            StaffMenu.fireMenu.refresh()
        end
    end)

    StaffMenu.fireMenu.Button("Portée notification", "Rayon de la notification en mètres", tostring(fireData.notifyRange) .. " m", "chevron", fireData.fireNotify == false and fireData.fireAlarm == false, function()
        local input = tonumber(VFW.Nui.KeyboardInput(true, "Portée notification en mètres", tostring(fireData.notifyRange)))
        if input and input >= 1 then
            fireData.notifyRange = input
            StaffMenu.fireMenu.refresh()
        end
    end)

    StaffMenu.fireMenu.Separator("ACTIONS")

    StaffMenu.fireMenu.Button("LANCER L'INCENDIE", "Créer un incendie à votre position", nil, "chevron", false, function()
        local coords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent("vfw:staff:startFire", {
            coords = { x = coords.x, y = coords.y, z = coords.z },
            fireType = fireData.fireTypeList[fireData.fireTypeIndex].value,
            duration = fireData.fireDuration,
            flames = fireData.fireIntensity * 2,
            spread = fireData.fireRange,
            notify = fireData.fireNotify,
            alarm = fireData.fireAlarm,
            alarmDelay = fireData.fireAlarmDelay,
            notifyRange = fireData.notifyRange
        })
        if fireData.fireAlarm then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Incendie',
                message = string.format("Alarme lancée, incendie dans %ds.", fireData.fireAlarmDelay)
            })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Incendie',
                message = "Incendie lancé à votre position."
          })
        end
    end)

    StaffMenu.fireMenu.Button("FAUSSE ALERTE", "Déclencher uniquement l'alarme sans feu réel", nil, "chevron", false, function()
        local coords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent("vfw:staff:fireAlarm", {
            coords = { x = coords.x, y = coords.y, z = coords.z },
            duration = fireData.fireDuration,
            notifyRange = fireData.notifyRange
        })
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Incendie',
            message = "Fausse alerte incendie lancée."
      })
    end)

    StaffMenu.fireMenu.Button("ARRÊTER TOUS LES INCENDIES", "Éteindre tous les incendies actifs", nil, "trash", false, function()
        TriggerServerEvent("vfw:staff:stopAllFires")
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Incendie',
            message = "Tous les incendies ont été éteints."
      })
    end)
end

function StaffMenu.BuildEarThquakeMenuMenu()
    StaffMenu.earthquakeMenu.Button(":globe: DÉCLENCHER UN SÉISME", nil, nil, "chevron", false, function()
        local duration = VFW.Nui.KeyboardInput(true, "Durée du séisme (secondes)", "30")
        duration = tonumber(duration)

        if duration and duration > 0 then
            TriggerServerEvent("vfw:staff:triggerEarthquake", duration * 1000)
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Événement Spécial',
                message = "Cette durée n'est pas valide."
          })
        end
    end)

    StaffMenu.earthquakeMenu.Button(":ban: ARRÊTER LE SÉISME", nil, nil, "chevron", false, function()
        TriggerServerEvent("vfw:staff:stopEarthquakeManual")
    end)
end


--- .BuildFireworkMenu
function StaffMenu.BuildFireworkMenu()
    local isActive = VFW.isFireworkActive and VFW.isFireworkActive() or false

    if not isActive then
        -- Quick launch section
        StaffMenu.fireworkMenu.Separator(":rocket: LANCEMENT RAPIDE")

        StaffMenu.fireworkMenu.Button(":bolt: Instant (2 min)", "Lancement immédiat sans musique", nil, "chevron", false, function()
            TriggerServerEvent("vfw:staff:triggerFirework", 120000)
            StaffMenu.fireworkMenu.close()
        end)

        StaffMenu.fireworkMenu.Button(":music: Spectacle Musical", "Presets avec musique", nil, "chevron", false, function()
        end, StaffMenu.fireworkPresetsMenu)

        StaffMenu.fireworkMenu.Separator(" ")
        StaffMenu.fireworkMenu.Separator(":settings: OPTIONS PERSONNALISÉES")

        StaffMenu.fireworkMenu.Button(":palette: Configuration complète", nil, nil, "chevron", false, function()
        end, StaffMenu.fireworkCustomMenu)

        StaffMenu.fireworkMenu.Button(":music: Musique YouTube", "Ajouter votre propre musique", nil, "chevron", false, function()
        end, StaffMenu.fireworkYoutubeMenu)

        StaffMenu.fireworkMenu.Separator(" ")
        StaffMenu.fireworkMenu.Separator(":clock: DURÉES PRÉDÉFINIES")

        local durations = {
            { label = "30 secondes", time = 30000, icon = ":clock:" },
            { label = "1 minute", time = 60000, icon = ":clock:" },
            { label = "2 minutes", time = 120000, icon = ":clock:" },
            { label = "3 minutes", time = 180000, icon = ":clock:" },
            { label = "5 minutes", time = 300000, icon = ":clock:" }
        }

        for _, duration in ipairs(durations) do
            StaffMenu.fireworkMenu.Button(duration.icon .. " " .. duration.label, nil, nil, "chevron", false, function()
                TriggerServerEvent("vfw:staff:triggerFirework", duration.time)
                StaffMenu.fireworkMenu.close()
            end)
        end

    else
        StaffMenu.fireworkMenu.Separator(":sparkles: FEU D'ARTIFICE ACTIF")
        StaffMenu.fireworkMenu.Separator(" ")

        StaffMenu.fireworkMenu.Button("⏸ Arrêt d'urgence", "Stopper immédiatement", nil, "chevron", false, function()
            TriggerServerEvent("vfw:staff:stopFirework")
            StaffMenu.fireworkMenu.close()
        end)

        StaffMenu.fireworkMenu.Separator(" ")
        StaffMenu.fireworkMenu.Separator(":info: Le spectacle est en cours...")
    end
end

--- .BuildFireworkCustomMenu
function StaffMenu.BuildFireworkCustomMenu()
    StaffMenu.fireworkCustomMenu.Separator(":palette: CONFIGURATION PERSONNALISÉE")
    StaffMenu.fireworkCustomMenu.Separator(" ")

    StaffMenu.fireworkCustomMenu.Button(":target: Définir tous les paramètres", nil, nil, "chevron", false, function()
        -- Duration
        local duration = VFW.Nui.KeyboardInput(true, "Durée en secondes (30-600)", "120")
        if not tonumber(duration) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Événement Spécial', message = 'Cette durée n\'est pas valide.' })
            return
        end

        local durationMs = tonumber(duration) * 1000
        if durationMs < 30000 or durationMs > 600000 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Événement Spécial', message = 'La durée doit être entre 30 et 600 secondes.' })
            return
        end

        -- Music option
        local wantMusic = VFW.Nui.KeyboardInput(true, "Ajouter de la musique? (oui/non)", "non")
        local musicUrl = nil
        local volumeFloat = 0.5

        if wantMusic == "oui" or wantMusic == "OUI" then
            musicUrl = VFW.Nui.KeyboardInput(true, "URL de la musique (YouTube/Direct)", "")
            if musicUrl and musicUrl ~= "" then
                local volume = VFW.Nui.KeyboardInput(true, "Volume (0-100)", "50")
                volumeFloat = (tonumber(volume) or 50) / 100
                volumeFloat = math.max(0, math.min(1, volumeFloat))
            end
        end

        TriggerServerEvent("vfw:staff:triggerFirework", durationMs, musicUrl, volumeFloat)
        StaffMenu.fireworkCustomMenu.close()
    end)
end

--- .BuildFireworkYoutubeMenu
function StaffMenu.BuildFireworkYoutubeMenu()
    StaffMenu.fireworkYoutubeMenu.Separator(":music: MUSIQUE YOUTUBE")
    StaffMenu.fireworkYoutubeMenu.Separator(" ")

    StaffMenu.fireworkYoutubeMenu.Button(":chat: Ajouter un lien YouTube", nil, nil, "chevron", false, function()
        local musicUrl = VFW.Nui.KeyboardInput(true, "URL YouTube (ex: youtube.com/watch?v=...)", "")
        if not musicUrl or musicUrl == "" then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Événement Spécial', message = 'URL requise.' })
            return
        end

        local duration = VFW.Nui.KeyboardInput(true, "Durée en secondes", "180")
        local durationMs = (tonumber(duration) or 180) * 1000
        durationMs = math.max(30000, math.min(600000, durationMs))

        local volume = VFW.Nui.KeyboardInput(true, "Volume (0-100)", "60")
        local volumeFloat = (tonumber(volume) or 60) / 100
        volumeFloat = math.max(0, math.min(1, volumeFloat))

        TriggerServerEvent("vfw:staff:triggerFirework", durationMs, musicUrl, volumeFloat)
        StaffMenu.fireworkYoutubeMenu.close()
    end)

    StaffMenu.fireworkYoutubeMenu.Separator(" ")
    StaffMenu.fireworkYoutubeMenu.Separator(":info: SUGGESTIONS")

    local suggestions = {
        { name = "Epic Orchestra", url = "https://www.youtube.com/watch?v=hHW1oY26kxQ" },
        { name = "Celebration", url = "https://www.youtube.com/watch?v=3GwjfUFyY6M" },
        { name = "New Year", url = "https://www.youtube.com/watch?v=a2GujJZfXpg" }
    }

    for _, suggestion in ipairs(suggestions) do
        StaffMenu.fireworkYoutubeMenu.Button(":arrow: " .. suggestion.name, nil, nil, "chevron", false, function()
            local duration = VFW.Nui.KeyboardInput(true, "Durée en secondes", "180")
            local durationMs = (tonumber(duration) or 180) * 1000
            durationMs = math.max(30000, math.min(600000, durationMs))

            TriggerServerEvent("vfw:staff:triggerFirework", durationMs, suggestion.url, 0.6)
            StaffMenu.fireworkYoutubeMenu.close()
        end)
    end
end

--- .BuildFireworkPresetsMenu
function StaffMenu.BuildFireworkPresetsMenu()
    StaffMenu.fireworkPresetsMenu.Separator(":music: SPECTACLES MUSICAUX")
    StaffMenu.fireworkPresetsMenu.Separator(" ")

    local categories = {
        {
            name = ":sparkles: CÉLÉBRATIONS",
            presets = {
                {
                    name = ":sparkles: Nouvel An",
                    desc = "Spectacle grandiose • 3 min",
                    duration = 180000,
                    url = "https://www.youtube.com/watch?v=a2GujJZfXpg",
                    volume = 0.7
                },
                {
                    name = ":gift: Anniversaire",
                    desc = "Festif et joyeux • 2 min",
                    duration = 120000,
                    url = "https://www.youtube.com/watch?v=3GwjfUFyY6M",
                    volume = 0.6
                },
                {
                    name = ":trophy: Victoire",
                    desc = "Triomphal • 2.5 min",
                    duration = 150000,
                    url = "https://www.youtube.com/watch?v=04854XqcfCY",
                    volume = 0.7
                }
            }
        },
        {
            name = ":mask: ÉPIQUES",
            presets = {
                {
                    name = ":gun: Bataille épique",
                    desc = "Orchestral intense • 4 min",
                    duration = 240000,
                    url = "https://www.youtube.com/watch?v=hHW1oY26kxQ",
                    volume = 0.8
                },
                {
                    name = ":flag: Dragons",
                    desc = "Fantastique • 3 min",
                    duration = 180000,
                    url = "https://www.youtube.com/watch?v=vVeWbqIDhXM",
                    volume = 0.7
                },
                {
                    name = ":globe: Spatial",
                    desc = "Science-fiction • 3 min",
                    duration = 180000,
                    url = "https://www.youtube.com/watch?v=60ItHLz5WEA",
                    volume = 0.6
                }
            }
        },
        {
            name = ":star: ROMANTIQUES",
            presets = {
                {
                    name = " Mariage",
                    desc = "Doux et élégant • 3 min",
                    duration = 180000,
                    url = "https://www.youtube.com/watch?v=Y4nEEZwckuU",
                    volume = 0.5
                },
                {
                    name = ":sparkles: Féerique",
                    desc = "Magique • 2.5 min",
                    duration = 150000,
                    url = "https://www.youtube.com/watch?v=60ItHLz5WEA",
                    volume = 0.5
                }
            }
        }
    }

    for _, category in ipairs(categories) do
        StaffMenu.fireworkPresetsMenu.Separator(category.name)

        for _, preset in ipairs(category.presets) do
            StaffMenu.fireworkPresetsMenu.Button(preset.name, preset.desc, nil, "chevron", false, function()
                -- Show confirmation with details
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Événement Spécial',
                    message = string.format('Lancement: %s (%s)', preset.name, preset.desc)
                })
                TriggerServerEvent("vfw:staff:triggerFirework", preset.duration, preset.url, preset.volume)
                StaffMenu.fireworkPresetsMenu.close()
            end)
        end

        StaffMenu.fireworkPresetsMenu.Separator(" ")
    end
end