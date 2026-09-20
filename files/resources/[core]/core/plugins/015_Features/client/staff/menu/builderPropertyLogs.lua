-- Builder Property Logs
-- View activity logs for any property by ID or by browsing

local viewMode = "list" -- "list" = property list, "detail" = logs for a property
local selectedPropertyId = nil
local cachedLogs = {}

local actionLabels = {
    enter = "Entrée",
    leave = "Sortie",
    give_access = "Don d'accès",
    remove_access = "Retrait d'accès",
    vehicle_retrieve = "Sortie véhicule",
    vehicle_exit = "Sortie garage avec véhicule",
    vehicle_store = "Rangement véhicule",
    chest_put = "Dépôt coffre",
    chest_take = "Retrait coffre",
    pay_rent = "Paiement loyer",
    perquisition = "Perquisition",
    transfer = "Transfert",
    edit = "Modification"
}

-- ==================== MENU PRINCIPAL ====================

StaffMenu.builderPropertyLogs.OnOpen(function()
    StaffMenu.builderPropertyLogs.Separator("LOGS PROPRIÉTÉS")

    StaffMenu.builderPropertyLogs.Button("RECHERCHER PAR ID", "Entrez l'ID de la propriété", nil, "search", false, function()
        local input = VFW.Nui.KeyboardInput(true, "ID de la propriété...", "")
        if not input or input == "" then
            StaffMenu.builderPropertyLogs.refresh()
            return
        end

        local propId = tonumber(input)
        if not propId then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Logs', message = 'Cet identifiant n\'est pas valide.' })
            StaffMenu.builderPropertyLogs.refresh()
            return
        end

        selectedPropertyId = propId
        cachedLogs = TriggerServerCallback("staff:getPropertyLogs", propId) or {}
        viewMode = "detail"
      StaffMenu.propertyLogsProperties.refresh()
    end)

    StaffMenu.builderPropertyLogs.Button("LISTER LES PROPRIÉTÉS", "Proprietes ayant un historique d'activite", nil, "chevron", false, function()
        viewMode = "list"
  end, StaffMenu.propertyLogsProperties)
end)

-- ==================== MENU UNIQUE : LISTE PROPRIÉTÉS / DETAIL LOGS ====================

StaffMenu.propertyLogsProperties.OnOpen(function()

    if viewMode == "detail" and selectedPropertyId then
        -- ===== VUE DETAIL : afficher les logs =====
        StaffMenu.propertyLogsProperties.Separator(("LOGS - PROPRIÉTÉ #%d"):format(selectedPropertyId))

        StaffMenu.propertyLogsProperties.Button("RETOUR A LA LISTE", "Revenir a la liste des propriétés", nil, "chevron", false, function()
            viewMode = "list"
          selectedPropertyId = nil
            cachedLogs = {}
            StaffMenu.propertyLogsProperties.refresh()
        end)

        if #cachedLogs == 0 then
            StaffMenu.propertyLogsProperties.Button("Aucun log", "Aucun historique pour cette propriété", nil, "chevron", false, function() end)
            return
        end

        for i, log in ipairs(cachedLogs) do
            local actionLabel = actionLabels[log.action] or log.action
            local label = ("[%s] %s"):format(log.created_at_formatted or "?", actionLabel)
            local desc = ("%s : %s"):format(log.player_name or "Inconnu", log.details or "")


            StaffMenu.propertyLogsProperties.Button(label, desc, nil, "chevron", false, function() end)
        end
    else
        -- ===== VUE LISTE : afficher les propriétés =====
        local properties = TriggerServerCallback("staff:getPropertiesWithLogs") or {}

        StaffMenu.propertyLogsProperties.Separator("PROPRIÉTÉS AVEC LOGS")

        if #properties == 0 then
            StaffMenu.propertyLogsProperties.Button("Aucune propriété", "Aucun historique enregistré", nil, "chevron", false, function() end)
            return
        end

        for i, prop in ipairs(properties) do
            local label = ("#%d %s"):format(prop.property_id, prop.property_name or "Sans nom")
            local desc = ("%d logs, dernière activité le %s"):format(prop.log_count or 0, prop.last_activity_formatted or "?")

            StaffMenu.propertyLogsProperties.Button(label, desc, nil, "chevron", false, function()
                selectedPropertyId = prop.property_id
                cachedLogs = TriggerServerCallback("staff:getPropertyLogs", prop.property_id) or {}
                viewMode = "detail"
              StaffMenu.propertyLogsProperties.refresh()
            end)
        end
    end
end)
