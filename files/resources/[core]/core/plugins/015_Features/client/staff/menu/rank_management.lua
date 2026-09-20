---@meta _
---@diagnostic disable: duplicate-doc-field

local rankData = {
    ranksList = {},
    selectedRank = nil,
    createMode = false,
    editMode = false,
    newRank = {
        name = "",
        label = "",
        power = 1,
        color = "white",
        permissions = {}
    },
    colorIndex = 1,
    colors = {
        {name = "Blanc", value = "white"},
        {name = "Rouge", value = "red"},
        {name = "Vert", value = "green"},
        {name = "Bleu", value = "blue"},
        {name = "Jaune", value = "yellow"},
        {name = "Orange", value = "orange"},
        {name = "Violet", value = "purple"},
        {name = "Rose", value = "pink"},
        {name = "Gris", value = "grey"}
    }
}

-- Build Rank Management Menu
function StaffMenu.BuildRankManagementMenu()
    StaffMenu.rankManagement.Separator("GESTION DES RANGS")
    
    -- Create new rank
    StaffMenu.rankManagement.Button("CRÉER UN NOUVEAU RANG", "Créer un nouveau rang avec ses permissions et sa couleur", nil, "chevron", false, function()
        rankData.createMode = true
        rankData.editMode = false
        rankData.newRank = {
            name = "",
            label = "",
            power = 1,
            color = "white",
            permissions = {}
        }
    end, StaffMenu.rankCreate)
    
    StaffMenu.rankManagement.Separator("RANGS EXISTANTS")
    
    -- List existing ranks
    rankData.ranksList = TriggerServerCallback("vfw:staff:getRanksList") or {}
    
    if #rankData.ranksList > 0 then
        for _, rank in ipairs(rankData.ranksList) do
            local color = "Blanc"
            for _, c in ipairs(rankData.colors) do
                if c.value == rank.color then
                    color = c.name
                    break
                end
            end
          local subtitle = string.format("Power: %d | Couleur: %s", rank.power, color)
            
            StaffMenu.rankManagement.Button(
                rank.label, 
                subtitle,
                nil, 
                "chevron",
                rank.name == "owner", -- Disable owner rank editing
                function()
                    rankData.selectedRank = rank
                    rankData.editMode = true
                    rankData.createMode = false
                    rankData.newRank = {
                        name = rank.name,
                        label = rank.label,
                        power = rank.power,
                        color = rank.color,
                        permissions = rank.permissions or {}
                    }
                end, 
                StaffMenu.rankEdit
            )
        end
    else
        StaffMenu.rankManagement.Separator("Aucun rang trouvé")
    end
end

-- Build Rank Create/Edit Menu
function StaffMenu.BuildRankCreateMenu()
    local title = rankData.editMode and "ÉDITION DU RANG" or "CRÉATION D'UN RANG"
  StaffMenu.rankCreate.Separator(title)
    
    -- Rank name (disabled in edit mode)
    if rankData.editMode then
        StaffMenu.rankCreate.Button("Nom du rang", rankData.newRank.name, nil, nil, true, function() end)
    else
        StaffMenu.rankCreate.Button("Nom du rang", rankData.newRank.name ~= "" and rankData.newRank.name or "Cliquez pour définir", nil, "chevron", false, function()
            local name = VFW.Nui.KeyboardInput(true, "Nom du rang (sans espaces, minuscules)", rankData.newRank.name)
            if name and name ~= "" then
                rankData.newRank.name = name:lower():gsub("%s+", "")
            end
        end)
    end
    
    -- Rank label
    StaffMenu.rankCreate.Button("Label du rang", rankData.newRank.label ~= "" and rankData.newRank.label or "Cliquez pour définir", nil, "chevron", false, function()
        local label = VFW.Nui.KeyboardInput(true, "Label du rang", rankData.newRank.label)
        if label and label ~= "" then
            rankData.newRank.label = label
        end
    end)
    
    -- Rank power
    StaffMenu.rankCreate.Slider("Power du rang", rankData.newRank.power, 1, 99, 1, nil, nil, function(value)
        rankData.newRank.power = value
    end)
    
    -- Rank color
    local colorNames = {}
    for _, c in ipairs(rankData.colors) do
        table.insert(colorNames, c.name)
    end
    StaffMenu.rankCreate.List("Couleur du rang", "Sélectionner la couleur d'affichage du rang dans le menu staff", false,
        colorNames,
        rankData.colorIndex,
        function(index, item)
            rankData.colorIndex = index
            rankData.newRank.color = rankData.colors[index].value
        end
    )
    
    StaffMenu.rankCreate.Separator("PERMISSIONS")
    
    -- Permission toggles
    StaffMenu.rankCreate.Button("TOUTES LES PERMISSIONS", "Activer toutes les permissions disponibles pour ce rang d'un seul coup", nil, "check", false, function()
        for perm, _ in pairs(Config.Permissions or {}) do
            rankData.newRank.permissions[perm] = true
        end
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Rangs',
            message = "Toutes les permissions accordées"
      })
    end)
    
    StaffMenu.rankCreate.Button("AUCUNE PERMISSION", "Retirer toutes les permissions de ce rang d'un seul coup", nil, "chevron", false, function()
        rankData.newRank.permissions = {}
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Rangs',
            message = "Toutes les permissions retirées"
      })
    end)
    
    -- Individual permissions
    for perm, data in pairs(Config.Permissions or {}) do
        StaffMenu.rankCreate.Checkbox(
            data.label, 
            nil, 
            false, 
            rankData.newRank.permissions[perm] or false,
            function(_checked)
                rankData.newRank.permissions[perm] = _checked
            end
        )
    end
    
    StaffMenu.rankCreate.Separator(nil)
    
    -- Save/Create button
    if rankData.editMode then
        StaffMenu.rankCreate.Button("SAUVEGARDER LES MODIFICATIONS", "Enregistrer les changements de ce rang en base de données", nil, "check", false, function()
            if rankData.newRank.label ~= "" and rankData.newRank.power > 0 then
                TriggerServerEvent("vfw:staff:updateRank", rankData.newRank)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Rangs',
                    message = "Rang mis à jour: " .. rankData.newRank.label
                })
                StaffMenu.rankCreate.close()
            end
        end)
        
        -- Delete rank (not for owner)
        if rankData.newRank.name ~= "owner" then
            StaffMenu.rankCreate.Button("SUPPRIMER LE RANG", "Supprimer définitivement ce rang et retirer ses accès à tous les membres", nil, "chevron", false, function()
                local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour supprimer ce rang", "")
                if confirm == "CONFIRMER" then
                    TriggerServerEvent("vfw:staff:deleteRank", rankData.newRank.name)
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Rangs',
                        message = "Rang supprimé: " .. rankData.newRank.label
                    })
                    StaffMenu.rankCreate.close()
                end
            end)
        end
    else
        StaffMenu.rankCreate.Button("CRÉER LE RANG", "Valider et créer le nouveau rang avec les paramètres définis", nil, "check", false, function()
            if rankData.newRank.name ~= "" and rankData.newRank.label ~= "" and rankData.newRank.power > 0 then
                TriggerServerEvent("vfw:staff:createRank", rankData.newRank)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Rangs',
                    message = "Rang créé: " .. rankData.newRank.label
                })
                StaffMenu.rankCreate.close()
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Rangs',
                    message = "Veuillez remplir tous les champs"
              })
            end
        end)
    end
end

-- Staff performance tracking
function StaffMenu.BuildStaffPerformanceMenu()
    StaffMenu.staffPerformance.Separator("PERFORMANCE DU STAFF")
    
    local staffList = TriggerServerCallback("vfw:staff:getStaffPerformance") or {}
    
    if #staffList > 0 then
        for _, staff in ipairs(staffList) do
            local avgRating = staff.report_count > 0 and (staff.report_rating / staff.report_count) or 0
            local stars = string.rep(":star:", math.floor(avgRating))
            
            StaffMenu.staffPerformance.Button(
                staff.name .. " (" .. staff.rank .. ")",
                string.format("Reports: %d | Note: %.1f/5 %s", staff.report_count, avgRating, stars),
                nil,
                "chevron",
                false,
                function()
                    -- Show detailed stats
                end
            )
        end
    else
        StaffMenu.staffPerformance.Separator("Aucune donnée de performance")
    end
    
    StaffMenu.staffPerformance.Separator("STATISTIQUES GLOBALES")
    
    local globalStats = TriggerServerCallback("vfw:staff:getGlobalStats") or {}
    
    StaffMenu.staffPerformance.Button("Total Reports Traités", tostring(globalStats.totalReports or 0), nil, nil, true, function() end)
    StaffMenu.staffPerformance.Button("Temps Moyen de Réponse", globalStats.avgResponseTime or "N/A", nil, nil, true, function() end)
    StaffMenu.staffPerformance.Button("Satisfaction Moyenne", string.format("%.1f/5", globalStats.avgSatisfaction or 0), nil, nil, true, function() end)
end