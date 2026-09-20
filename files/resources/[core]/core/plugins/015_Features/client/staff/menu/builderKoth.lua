-- ========================================================================
-- KOTH Builder - Staff Menu
-- ========================================================================

local kothCreateData = {}

local function ResetCreateData()
    kothCreateData = {
        name = nil,
        coords = nil,
        radius = KOTHConfig.defaultRadius,
        duration = KOTHConfig.defaultDuration,
        scheduleHours = {},
    }
end
ResetCreateData()

-- ========================================================================
-- CREATE ZONE
-- ========================================================================

StaffMenu.builderKothCreate.OnOpen(function()
    StaffMenu.builderKothCreate.ClearItems()
    StaffMenu.builderKothCreate.Separator("CRÉER UNE ZONE KOTH")

    -- Nom
    StaffMenu.builderKothCreate.Button(
        kothCreateData.name and ("Nom: " .. kothCreateData.name) or "Définir le nom",
        "Nom de la zone KOTH", nil, "chevron", false, function()
            local name = VFW.Nui.KeyboardInput(true, "Nom de la zone KOTH")
            if name and name ~= "" then
                kothCreateData.name = name
            end
            StaffMenu.builderKothCreate.refresh()
        end)

    -- Position
    local posLabel = kothCreateData.coords
        and ("Position: %.1f, %.1f, %.1f"):format(kothCreateData.coords.x, kothCreateData.coords.y, kothCreateData.coords.z)
        or "Définir la position"
  StaffMenu.builderKothCreate.Button(posLabel, "Utilise ta position actuelle", nil, "chevron", false, function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        kothCreateData.coords = coords
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = 'Position enregistrée' })
        StaffMenu.builderKothCreate.refresh()
    end)

    -- Rayon
    StaffMenu.builderKothCreate.Button(
        ("Rayon: %.0fm"):format(kothCreateData.radius),
        "Rayon de la zone en mètres", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Rayon (mètres)")
            local val = tonumber(input)
            if val and val > 0 then
                kothCreateData.radius = val
            end
            StaffMenu.builderKothCreate.refresh()
        end)

    -- Durée
    StaffMenu.builderKothCreate.Button(
        ("Durée: %d min"):format(kothCreateData.duration),
        "Durée du KOTH en minutes", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Durée (minutes)")
            local val = tonumber(input)
            if val and val > 0 then
                kothCreateData.duration = math.floor(val)
            end
            StaffMenu.builderKothCreate.refresh()
        end)

    -- Horaires
    local hoursStr = #kothCreateData.scheduleHours > 0
        and table.concat(kothCreateData.scheduleHours, ", ")
        or "Aucun"
  StaffMenu.builderKothCreate.Button(
        "Horaires: " .. hoursStr,
        "Heures de déclenchement auto (ex: 14:30,20:00,2:15)", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Horaires séparés par des virgules (ex: 14:30,20:00,2:15)")
            if input and input ~= "" then
                local times = {}
                for entry in input:gmatch("[^,]+") do
                    entry = entry:match("^%s*(.-)%s*$")
                    local h, m = entry:match("^(%d+):(%d+)$")
                    if not h then
                        h = entry:match("^(%d+)$")
                        m = "0"
                  end
                    h, m = tonumber(h), tonumber(m)
                    if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 then
                        times[#times + 1] = ("%d:%02d"):format(h, m)
                    end
                end
                kothCreateData.scheduleHours = times
            end
            StaffMenu.builderKothCreate.refresh()
        end)

    -- Valider
    StaffMenu.builderKothCreate.Separator("")
    StaffMenu.builderKothCreate.Button("CRÉER LA ZONE", "Valider et enregistrer", nil, "check", false, function()
        if not kothCreateData.name or not kothCreateData.coords then
            VFW.ShowNotification({ type = 'ROUGE', content = "Nom et position obligatoires" })
            return
        end

        local id = TriggerServerCallback("koth:createZone", {
            name = kothCreateData.name,
            x = kothCreateData.coords.x,
            y = kothCreateData.coords.y,
            z = kothCreateData.coords.z,
            radius = kothCreateData.radius,
            duration = kothCreateData.duration,
            scheduleHours = kothCreateData.scheduleHours,
        })

        if id then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = ("Zone '%s' créée (ID: %d)"):format(kothCreateData.name, id) })
            ResetCreateData()
            StaffMenu.builderKothCreate.refresh()
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Erreur lors de la création" })
        end
    end)
end)

-- ========================================================================
-- MANAGE ZONES
-- ========================================================================

StaffMenu.builderKothManage.OnOpen(function()
    StaffMenu.builderKothManage.ClearItems()
    StaffMenu.builderKothManage.Separator("ZONES KOTH")

    local zones = TriggerServerCallback("koth:getZones")
    if not zones or #zones == 0 then
        StaffMenu.builderKothManage.Button("Aucune zone", "Créez-en une d'abord", nil, "chevron", false, function() end)
        return
    end

    for _, zone in ipairs(zones) do
        local status = zone.enabled and "Active" or "Désactivée"
      local hoursStr = zone.scheduleHours and #zone.scheduleHours > 0
            and table.concat(zone.scheduleHours, ", ")
            or "Manuel"

      StaffMenu.builderKothManage.Button(
            zone.name,
            ("%s | R: %.0fm | %dmin | %s"):format(status, zone.radius, zone.duration, hoursStr),
            nil, "chevron", false,
            function()
                StaffMenu._kothEditZone = zone
            end,
            StaffMenu.builderKothEdit
        )
    end
end)

-- ========================================================================
-- EDIT ZONE
-- ========================================================================

StaffMenu.builderKothEdit.OnOpen(function()
    StaffMenu.builderKothEdit.ClearItems()
    local zone = StaffMenu._kothEditZone
    if not zone then return end

    StaffMenu.builderKothEdit.Separator("ÉDITER: " .. zone.name)

    -- Toggle enabled
    StaffMenu.builderKothEdit.Button(
        zone.enabled and "Désactiver" or "Activer",
        zone.enabled and "La zone est actuellement active" or "La zone est actuellement désactivée",
        nil, "chevron", false, function()
            zone.enabled = not zone.enabled
            TriggerServerCallback("koth:updateZone", zone.id, "enabled", zone.enabled)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = zone.enabled and "Zone activée" or "Zone désactivée" })
            StaffMenu.builderKothEdit.refresh()
        end)

    -- Rename
    StaffMenu.builderKothEdit.Button("Renommer", "Nom actuel: " .. zone.name, nil, "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nouveau nom")
        if name and name ~= "" then
            TriggerServerCallback("koth:updateZone", zone.id, "name", name)
            zone.name = name
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Renommé en: " .. name })
        end
        StaffMenu.builderKothEdit.refresh()
    end)

    -- Radius
    StaffMenu.builderKothEdit.Button(("Rayon: %.0fm"):format(zone.radius), "Modifier le rayon", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau rayon (mètres)")
        local val = tonumber(input)
        if val and val > 0 then
            TriggerServerCallback("koth:updateZone", zone.id, "radius", val)
            zone.radius = val
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = ("Rayon: %.0fm"):format(val) })
        end
        StaffMenu.builderKothEdit.refresh()
    end)

    -- Duration
    StaffMenu.builderKothEdit.Button(("Durée: %d min"):format(zone.duration), "Modifier la durée", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelle durée (minutes)")
        local val = tonumber(input)
        if val and val > 0 then
            TriggerServerCallback("koth:updateZone", zone.id, "duration", math.floor(val))
            zone.duration = math.floor(val)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = ("Durée: %d min"):format(val) })
        end
        StaffMenu.builderKothEdit.refresh()
    end)

    -- Schedule
    local hoursStr = zone.scheduleHours and #zone.scheduleHours > 0
        and table.concat(zone.scheduleHours, ", ")
        or "Manuel uniquement"
  StaffMenu.builderKothEdit.Button("Horaires: " .. hoursStr, "Heures de déclenchement auto", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Horaires (ex: 14:30,20:00) ou vide pour désactiver")
        local times = {}
        if input and input ~= "" then
            for entry in input:gmatch("[^,]+") do
                entry = entry:match("^%s*(.-)%s*$")
                local h, m = entry:match("^(%d+):(%d+)$")
                if not h then
                    h = entry:match("^(%d+)$")
                    m = "0"
              end
                h, m = tonumber(h), tonumber(m)
                if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 then
                    times[#times + 1] = ("%d:%02d"):format(h, m)
                end
            end
        end
        TriggerServerCallback("koth:updateZone", zone.id, "scheduleHours", times)
        zone.scheduleHours = times
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Horaires mis à jour" })
        StaffMenu.builderKothEdit.refresh()
    end)

    -- Plage horaire aléatoire
    local rangeStr = (zone.scheduleStart and zone.scheduleEnd)
        and (zone.scheduleStart .. " → " .. zone.scheduleEnd)
        or "Non défini"
  StaffMenu.builderKothEdit.Button("Plage aléatoire: " .. rangeStr, "Lancement aléatoire entre 2 horaires", nil, "chevron", false, function()
        local startInput = VFW.Nui.KeyboardInput(true, "Heure de début (ex: 14:00)")
        if not startInput or startInput == "" then
            TriggerServerCallback("koth:updateZone", zone.id, "scheduleRange", { start = nil, finish = nil })
            zone.scheduleStart = nil
            zone.scheduleEnd = nil
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Plage aléatoire désactivée" })
            StaffMenu.builderKothEdit.refresh()
            return
        end
        local endInput = VFW.Nui.KeyboardInput(true, "Heure de fin (ex: 22:00)")
        if not endInput or endInput == "" then return end

        -- Valider le format
        local sh, sm = startInput:match("^(%d+):(%d+)$")
        local eh, em = endInput:match("^(%d+):(%d+)$")
        if not sh or not eh then
            VFW.ShowNotification({ type = 'ROUGE', content = "Ce format n'est pas valide (HH:MM)" })
            return
        end

        local startFormatted = ("%d:%02d"):format(tonumber(sh), tonumber(sm))
        local endFormatted = ("%d:%02d"):format(tonumber(eh), tonumber(em))

        TriggerServerCallback("koth:updateZone", zone.id, "scheduleRange", { start = startFormatted, finish = endFormatted })
        zone.scheduleStart = startFormatted
        zone.scheduleEnd = endFormatted
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Plage aléatoire: " .. startFormatted .. " → " .. endFormatted })
        StaffMenu.builderKothEdit.refresh()
    end)

    -- Teleport
    StaffMenu.builderKothEdit.Separator("")
    StaffMenu.builderKothEdit.Button("Se téléporter", "TP à la zone", nil, "chevron", false, function()
        local ped = PlayerPedId()
        SetEntityCoords(ped, zone.coords.x, zone.coords.y, zone.coords.z, false, false, false, false)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Téléporté" })
    end)

    -- Force start / stop
    local activeKoth = TriggerServerCallback("koth:getActive")
    local isRunningHere = activeKoth and activeKoth.zoneId == zone.id

    if isRunningHere then
        StaffMenu.builderKothEdit.Button("Arrêter sans vainqueur", "Stopper le KOTH, aucun groupe ne gagne", nil, "chevron", false, function()
            local ok = TriggerServerCallback("koth:forceStop")
            if ok then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "KOTH arrêté sans vainqueur" })
            else
                VFW.ShowNotification({ type = 'ROUGE', content = "Aucun KOTH en cours" })
            end
            StaffMenu.builderKothEdit.refresh()
        end)
        StaffMenu.builderKothEdit.Button("Arrêter avec vainqueur", "Stopper le KOTH, le meneur gagne", nil, "chevron", false, function()
            local ok = TriggerServerCallback("koth:forceStopWithWinner")
            if ok then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "KOTH arrêté avec vainqueur" })
            else
                VFW.ShowNotification({ type = 'ROUGE', content = "Aucun KOTH en cours" })
            end
            StaffMenu.builderKothEdit.refresh()
        end)
    else
        StaffMenu.builderKothEdit.Button("Démarrer maintenant", "Lancer le KOTH sur cette zone", nil, "chevron", false, function()
            local ok = TriggerServerCallback("koth:forceStart", zone.id)
            if ok then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "KOTH démarré !" })
            else
                VFW.ShowNotification({ type = 'ROUGE', content = "Impossible (un KOTH est déjà en cours ou zone désactivée)" })
            end
            StaffMenu.builderKothEdit.refresh()
        end)
    end

    -- Delete
    StaffMenu.builderKothEdit.Button("Supprimer la zone", "Suppression définitive", nil, "chevron", false, function()
        TriggerServerCallback("koth:deleteZone", zone.id)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Zone supprimée" })
        StaffMenu.builderKothEdit.refresh()
    end)
end)

-- ========================================================================
-- MAIN KOTH MENU
-- ========================================================================

StaffMenu.builderKoth.OnOpen(function()
    StaffMenu.builderKoth.ClearItems()
    StaffMenu.builderKoth.Separator("KING OF THE HILL")

    StaffMenu.builderKoth.Button("Créer une zone", "Configurer une nouvelle zone KOTH", nil, "chevron", false, function()
        ResetCreateData()
    end, StaffMenu.builderKothCreate)

    StaffMenu.builderKoth.Button("Gérer les zones", "Modifier, activer/désactiver, supprimer", nil, "chevron", false, function()
    end, StaffMenu.builderKothManage)

    StaffMenu.builderKoth.Button("Historique", "Résultats des 30 derniers jours", nil, "chevron", false, function()
    end, StaffMenu.builderKothHistory)

    StaffMenu.builderKoth.Separator("")

    -- Force stop
    StaffMenu.builderKoth.Button("Arrêter sans vainqueur", "Stopper le KOTH, aucun groupe ne gagne", nil, "chevron", false, function()
        local ok = TriggerServerCallback("koth:forceStop")
        if ok then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "KOTH arrêté sans vainqueur" })
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Aucun KOTH en cours" })
        end
    end)
    StaffMenu.builderKoth.Button("Arrêter avec vainqueur", "Stopper le KOTH, le meneur gagne", nil, "chevron", false, function()
        local ok = TriggerServerCallback("koth:forceStopWithWinner")
        if ok then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "KOTH arrêté avec vainqueur" })
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Aucun KOTH en cours" })
        end
    end)
end)

-- ========================================================================
-- HISTORY
-- ========================================================================

local selectedKothHistory = nil

StaffMenu.builderKothHistory.OnOpen(function()
    StaffMenu.builderKothHistory.ClearItems()
    StaffMenu.builderKothHistory.Separator("HISTORIQUE KOTH (30 JOURS)")

    local history = TriggerServerCallback("koth:getHistory")

    if not history or #history == 0 then
        StaffMenu.builderKothHistory.Button("Aucun résultat", nil, nil, nil, true, function() end)
        return
    end

    StaffMenu.builderKothHistory.Button(":trash: Vider l'historique", "Supprimer tous les résultats", nil, nil, false, function()
        local ok = TriggerServerCallback("koth:clearHistory")
        if ok then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Historique vidé" })
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Erreur" })
        end
        StaffMenu.builderKothHistory.refresh()
    end)

    StaffMenu.builderKothHistory.Separator("")

    for _, entry in ipairs(history) do
        local winner = tostring(entry.winner_faction or "Aucun")
        local date = tostring(entry.ended_at or "?")
        local zoneName = tostring(entry.zone_name or "Zone inconnue")
        local label = zoneName .. " - " .. winner
        local desc = date .. " · " .. tostring(entry.winner_score or 0) .. " pts"

      local capturedEntry = entry
        StaffMenu.builderKothHistory.Button(label, desc, nil, "chevron", false, function()
            selectedKothHistory = capturedEntry
        end, StaffMenu.builderKothHistoryDetail)
    end
end)

StaffMenu.builderKothHistoryDetail.OnOpen(function()
    StaffMenu.builderKothHistoryDetail.ClearItems()

    if not selectedKothHistory then
        StaffMenu.builderKothHistoryDetail.Button("Aucune donnée", nil, nil, nil, false, function() end)
        return
    end

    local entry = selectedKothHistory

    StaffMenu.builderKothHistoryDetail.Separator("RÉSULTAT")
    StaffMenu.builderKothHistoryDetail.Button("Zone", tostring(entry.zone_name), nil, nil, false, function() end)
    StaffMenu.builderKothHistoryDetail.Button("Début", tostring(entry.started_at), nil, nil, false, function() end)
    StaffMenu.builderKothHistoryDetail.Button("Fin", tostring(entry.ended_at), nil, nil, false, function() end)

    StaffMenu.builderKothHistoryDetail.Separator("VAINQUEUR")
    StaffMenu.builderKothHistoryDetail.Button(":trophy: " .. tostring(entry.winner_faction), tostring(entry.winner_score) .. " points", nil, nil, false, function() end)

    StaffMenu.builderKothHistoryDetail.Separator("CLASSEMENT COMPLET")

    local scores = entry.scores or {}

    if type(scores) == "table" and next(scores) then
        local sorted = {}
        for faction, score in pairs(scores) do
            table.insert(sorted, { faction = tostring(faction), score = tonumber(score) or 0 })
        end
        table.sort(sorted, function(a, b) return a.score > b.score end)

        for i, s in ipairs(sorted) do
            local isWinner = s.faction == tostring(entry.winner_faction)
            local prefix = isWinner and ":trophy: " or (i .. ". ")
            StaffMenu.builderKothHistoryDetail.Button(
                prefix .. s.faction,
                s.score .. " points",
                nil, nil, false, function() end
            )
        end
    else
        StaffMenu.builderKothHistoryDetail.Button("Aucun score enregistré", nil, nil, nil, false, function() end)
    end
end)
