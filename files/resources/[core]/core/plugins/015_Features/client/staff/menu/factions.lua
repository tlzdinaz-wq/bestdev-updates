---@meta _
---@diagnostic disable: duplicate-doc-field

local factionQuery = nil

-- Event pour rafraîchir la liste des factions quand une nouvelle est créée
RegisterNetEvent("core:gestion-factions:refresh", function()
    if not StaffMenu or not StaffMenu.data then return end
    StaffMenu.data.allFactions = TriggerServerCallback("core:gestion-factions:getAll") or {}
    -- Ne refresh que si le menu manageFactions est réellement affiché.
    -- Sinon on cause une race avec les flows close()+open() en cours (ex: suppression).
    if StaffMenu.manageFactions and StaffMenu.manageFactions.opened then
        StaffMenu.manageFactions.refresh()
    end
end)

--- .BuildFactionsMenu
---@return any
function StaffMenu.BuildFactionsMenu()
    local firstLabel = factionQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = factionQuery == nil and "UNE FACTION" or factionQuery

    -- Bouton refresh pour recharger les données
    StaffMenu.factions.Button(":refresh: ACTUALISER", "Recharger les factions depuis le serveur", nil, "chevron", false, function()
        StaffMenu.data.factionsList = TriggerServerCallback("core:staff:getOrganizations") or {}
        StaffMenu.data.playerInfo = TriggerServerCallback("vfw:staff:getPlayerInfo", StaffMenu.data.selectedPlayer) or {}
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Liste des factions actualisée." })
        StaffMenu.factions.refresh()
    end)

    StaffMenu.factions.Button(firstLabel, lastLabel, nil, "search", false, function()
        if factionQuery ~= nil then
            factionQuery = nil
            StaffMenu.factions.refresh()
            return
        end

        factionQuery = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label")
        if factionQuery == nil or factionQuery == "" then
            return
        end

        StaffMenu.factions.refresh()
    end)

    -- Afficher la faction actuelle du joueur
    if StaffMenu.data.playerInfo then
        local currentFactionLabel = StaffMenu.data.playerInfo.faction or "Aucune"
      local currentFactionName = StaffMenu.data.playerInfo.factionName or nil
        local currentFactionGrade = StaffMenu.data.playerInfo.factionGrade or ""

      StaffMenu.factions.Separator(":report: FACTION ACTUELLE")

        if currentFactionName and currentFactionName ~= "" then
            -- Bouton pour changer le grade de la faction actuelle
            StaffMenu.factions.Button(":edit: " .. currentFactionLabel, "Grade: " .. currentFactionGrade .. " - Cliquer pour changer", nil, "chevron", false, function()
                StaffMenu.data.selectedFaction = currentFactionName
            end, StaffMenu.grades_factions)

            -- Bouton pour retirer de la faction
            StaffMenu.factions.Button(":trash: RETIRER DE LA FACTION", "Quitter la faction", nil, "trash", false, function()
                TriggerServerEvent('vfw:staff:setFaction', StaffMenu.data.playerInfo.id, "nocrew", 0)
                StaffMenu.data.playerInfo.faction = "Aucune"
              StaffMenu.data.playerInfo.factionName = nil
                StaffMenu.data.playerInfo.factionGrade = nil
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions',
                    message = "Faction retirée."
              })
                StaffMenu.factions.refresh()
            end)
        else
            StaffMenu.factions.Button("Aucune faction", "Pas de faction assignée", nil, nil, true, function() end)
        end
    end

    StaffMenu.factions.Separator(":folder: AUTRES FACTIONS")

    if StaffMenu.data.factionsList and next(StaffMenu.data.factionsList) then
        local currentFactionName = StaffMenu.data.playerInfo and StaffMenu.data.playerInfo.factionName or ""

      for _, v in pairs(StaffMenu.data.factionsList) do
            if v.label == nil then
                v.label = "Inconnu"
          end

            if factionQuery == nil or string.find(string.lower(v.name), string.lower(factionQuery)) or string.find(string.lower(v.label), string.lower(factionQuery)) then
                -- Ne pas afficher la faction actuelle dans la liste des autres factions
                if currentFactionName ~= v.name then
                    StaffMenu.factions.Button(v.label, v.name, nil, "chevron", false, function()
                        StaffMenu.data.selectedFaction = v.name
                    end, StaffMenu.grades_factions)
                end
            end
        end
    end
end

--- .BuildFactionMenu
--- Main faction menu with create and manage options
function StaffMenu.BuildFactionMenu()
    StaffMenu.factionMenu.Button(":plus: CRÉER UNE FACTION", "Nouvelle faction illégale", nil, "chevron", false, function()
    end, StaffMenu.createFaction)

    StaffMenu.factionMenu.Button(":report: GÉRER LES FACTIONS", "Modifier, activer, supprimer", nil, "chevron", false, function()
    end, StaffMenu.manageFactions)
end

--- .BuildCreateFactionMenu
function StaffMenu.BuildCreateFactionMenu()
    -- Initialiser les donnees si elles n'existent pas
    if not StaffMenu.data.newFaction then
        StaffMenu.data.newFaction = {
            name = nil,
            label = nil,
            devise = "",
            logo = "",
            banner = "",
            color = "#e53935"
      }
    end

    local data = StaffMenu.data.newFaction

    StaffMenu.createFaction.Button("NOM (ID)", data.name or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom unique (ex: vagos)")
        if input and input ~= "" then
            data.name = string.lower(input:gsub("%s+", "_"))
            StaffMenu.createFaction.refresh()
        end
    end)

    StaffMenu.createFaction.Button("LABEL", data.label or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Label (ex: Los Santos Vagos)")
        if input and input ~= "" then
            data.label = input
            StaffMenu.createFaction.refresh()
        end
    end)

    StaffMenu.createFaction.Button("DEVISE", data.devise ~= "" and data.devise or "Aucune", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Devise (optionnel)")
        data.devise = input or ""
      StaffMenu.createFaction.refresh()
    end)

    StaffMenu.createFaction.Button("LOGO", data.logo ~= "" and "Défini" or "Aucun", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "URL du logo (lien image)")
        data.logo = input or ""
      StaffMenu.createFaction.refresh()
    end)

    StaffMenu.createFaction.Button("BANNIÈRE", data.banner and data.banner ~= "" and "Définie" or "Aucune", nil, "chevron", false, function()
    end, StaffMenu.createFactionBanner)

    StaffMenu.createFaction.Button("COULEUR", data.color or "#e53935", nil, "chevron", false, function()
        local hex = (data.color or "#e53935"):gsub("#", "")
        local r = tonumber(hex:sub(1,2), 16) or 255
        local g = tonumber(hex:sub(3,4), 16) or 255
        local b = tonumber(hex:sub(5,6), 16) or 255
        StaffMenu.createFaction.RoleColorPicker(r, g, b, "COULEUR",
            nil,
            function(finalR, finalG, finalB)
                data.color = string.format("#%02X%02X%02X", finalR, finalG, finalB)
                StaffMenu.createFaction.refresh()
            end,
            nil
        )
    end)

    -- Prévisualisation du logo
    if data.logo and data.logo ~= "" then
        StaffMenu.createFaction.Imagebox(data.logo, nil)
    end

    StaffMenu.createFaction.Separator(nil)

    local canCreate = data.name and data.label
    StaffMenu.createFaction.Button("CRÉER LA FACTION", canCreate and "Cliquez pour créer" or "Remplissez nom et label",
        nil, "chevron", not canCreate, function()
        if canCreate then
            local result = TriggerServerCallback("core:staff:createFaction", data.name, data.label, data.devise, data.logo, data.color, data.banner)
            if result then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Faction '" .. data.label .. "' créée." })
                StaffMenu.data.newFaction = { name = nil, label = nil, devise = "", logo = "", banner = "", color = "#e53935" }
                -- Refresh factions list
                StaffMenu.data.allFactions = TriggerServerCallback("core:gestion-factions:getAll") or {}
                StaffMenu.createFaction.close()
                StaffMenu.createFaction.parent.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Erreur : la faction existe peut-être déjà." })
            end
        end
    end)
end

--- .BuildCreateFactionBannerMenu
--- Banner selection for faction creation
function StaffMenu.BuildCreateFactionBannerMenu()
    local data = StaffMenu.data.newFaction
    local banners = TriggerServerCallback("vfw:server:getBannerTemplatesPublic", "faction")

    -- Option URL personnalisée
    StaffMenu.createFactionBanner.Button("URL PERSONNALISÉE", data.banner ~= "" and data.banner or "Aucune", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "URL de la bannière")
        if input and input ~= "" then
            data.banner = input
        end
        StaffMenu.createFactionBanner.refresh()
    end)

    if data.banner and data.banner ~= "" then
        StaffMenu.createFactionBanner.Imagebox(data.banner, nil)
    end

    StaffMenu.createFactionBanner.Separator("BANNIÈRES DISPONIBLES")

    if banners and #banners > 0 then
        for _, banner in ipairs(banners) do
            StaffMenu.createFactionBanner.Imagebox(banner.url, nil)
            local isSelected = data.banner == banner.url
            StaffMenu.createFactionBanner.Button(
                banner.name,
                isSelected and "Sélectionnée" or "Cliquer pour sélectionner",
                nil,
                isSelected and "check" or "chevron",
                false,
                function()
                    data.banner = banner.url
                    StaffMenu.createFactionBanner.refresh()
                end
            )
        end
    else
        StaffMenu.createFactionBanner.Button("AUCUNE BANNIÈRE", "Ajoutez-en depuis le gestionnaire d'images", nil, nil, true, function() end)
    end
end

--- .BuildManageFactionBannerMenu
--- Banner selection for faction management
function StaffMenu.BuildManageFactionBannerMenu()
    local faction = StaffMenu.data.selectedManagedFaction
    if not faction then return end

    local banners = TriggerServerCallback("vfw:server:getBannerTemplatesPublic", "faction")

    -- Option URL personnalisée
    StaffMenu.manageFactionBanner.Button("URL PERSONNALISÉE", faction.banner and faction.banner ~= "" and faction.banner or "Aucune", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "URL de la bannière")
        faction.banner = input or ""
      TriggerServerCallback("core:gestion-factions:updateField", faction.name, "banner", faction.banner)
        StaffMenu.manageFactionBanner.refresh()
    end)

    if faction.banner and faction.banner ~= "" then
        StaffMenu.manageFactionBanner.Imagebox(faction.banner, nil)
    end

    StaffMenu.manageFactionBanner.Separator("BANNIÈRES DISPONIBLES")

    if banners and #banners > 0 then
        for _, banner in ipairs(banners) do
            StaffMenu.manageFactionBanner.Imagebox(banner.url, nil)
            local isSelected = faction.banner == banner.url
            StaffMenu.manageFactionBanner.Button(
                banner.name,
                isSelected and "Sélectionnée" or "Cliquer pour sélectionner",
                nil,
                isSelected and "check" or "chevron",
                false,
                function()
                    faction.banner = banner.url
                    TriggerServerCallback("core:gestion-factions:updateField", faction.name, "banner", faction.banner)
                    StaffMenu.manageFactionBanner.refresh()
                end
            )
        end
    else
        StaffMenu.manageFactionBanner.Button("AUCUNE BANNIÈRE", "Ajoutez-en depuis le gestionnaire d'images", nil, nil, true, function() end)
    end
end

--- .BuildManageFactionsMenu
--- List all factions for management
function StaffMenu.BuildManageFactionsMenu()
    StaffMenu.manageFactions.ClearItems()
    -- Always fetch fresh data
    StaffMenu.data.allFactions = TriggerServerCallback("core:gestion-factions:getAll") or {}
    local factions = StaffMenu.data.allFactions

    if not factions or #factions == 0 then
        StaffMenu.manageFactions.Button("AUCUNE FACTION", "Créez-en une d'abord", nil, "chevron", true, function() end)
        return
    end

    -- Séparer les factions actives et inactives
    local activeFactions = {}
    local inactiveFactions = {}

    for _, faction in pairs(factions) do
        if faction.active then
            table.insert(activeFactions, faction)
        else
            table.insert(inactiveFactions, faction)
        end
    end

    -- Afficher les factions actives
    if #activeFactions > 0 then
        StaffMenu.manageFactions.Separator("FACTIONS ACTIVES")
        for _, faction in pairs(activeFactions) do
            local memberCount = faction.memberCount or 0
            local gradeCount = faction.gradeCount or 0
            StaffMenu.manageFactions.Button(
                ":check: " .. string.upper(faction.label or faction.name),
                memberCount .. " membres | " .. gradeCount .. " grades",
                nil,
                "chevron",
                false,
                function()
                    StaffMenu.data.selectedManagedFaction = faction
                end,
                StaffMenu.manageFactionDetails
            )
        end
    end

    -- Afficher les factions inactives
    if #inactiveFactions > 0 then
        StaffMenu.manageFactions.Separator("FACTIONS EN ATTENTE")
        for _, faction in pairs(inactiveFactions) do
            local memberCount = faction.memberCount or 0
            local gradeCount = faction.gradeCount or 0
            StaffMenu.manageFactions.Button(
                ":hourglass: " .. string.upper(faction.label or faction.name),
                memberCount .. " membres | " .. gradeCount .. " grades",
                nil,
                "chevron",
                false,
                function()
                    StaffMenu.data.selectedManagedFaction = faction
                end,
                StaffMenu.manageFactionDetails
            )
        end
    end
end

--- .BuildManageFactionDetailsMenu
--- Details and actions for a specific faction
function StaffMenu.BuildManageFactionDetailsMenu()
    local faction = StaffMenu.data.selectedManagedFaction
    if not faction then return end

    -- ID de la faction
    StaffMenu.manageFactionDetails.Button("ID", faction.name, nil, nil, false, function() end)

    -- Statut de la faction
    local statusText = faction.active and ":check: Active" or ":hourglass: En attente d'activation"
  StaffMenu.manageFactionDetails.Button("STATUT", statusText, nil, nil, true, function() end)

    StaffMenu.manageFactionDetails.Separator(nil)

    StaffMenu.manageFactionDetails.Button("NOM", faction.label or faction.name, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau nom")
        if input and input ~= "" then
            faction.label = input
            TriggerServerCallback("core:gestion-factions:updateField", faction.name, "label", input)
            StaffMenu.manageFactionDetails.refresh()
        end
    end)

    StaffMenu.manageFactionDetails.Button("DEVISE", faction.devise or "Aucune", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Devise de la faction")
        faction.devise = input or ""
      TriggerServerCallback("core:gestion-factions:updateField", faction.name, "devise", faction.devise)
        StaffMenu.manageFactionDetails.refresh()
    end)

    StaffMenu.manageFactionDetails.Button("LOGO", faction.image and faction.image ~= "" and "Défini" or "Aucun", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "URL du logo (lien image)")
        faction.image = input or ""
      TriggerServerCallback("core:gestion-factions:updateField", faction.name, "image", faction.image)
        StaffMenu.manageFactionDetails.refresh()
    end)

    -- Prévisualisation du logo
    if faction.image and faction.image ~= "" then
        StaffMenu.manageFactionDetails.Imagebox(faction.image, nil)
    end

    StaffMenu.manageFactionDetails.Button("BANNIÈRE", faction.banner and faction.banner ~= "" and "Définie" or "Aucune", nil, "chevron", false, function()
    end, StaffMenu.manageFactionBanner)

    -- Prévisualisation de la bannière
    if faction.banner and faction.banner ~= "" then
        StaffMenu.manageFactionDetails.Imagebox(faction.banner, nil)
    end

    StaffMenu.manageFactionDetails.Button("COULEUR", faction.color or "#e53935", nil, "chevron", false, function()
        local hex = (faction.color or "#e53935"):gsub("#", "")
        local cr = tonumber(hex:sub(1,2), 16) or 255
        local cg = tonumber(hex:sub(3,4), 16) or 255
        local cb = tonumber(hex:sub(5,6), 16) or 255
        StaffMenu.manageFactionDetails.RoleColorPicker(cr, cg, cb, "COULEUR",
            nil,
            function(finalR, finalG, finalB)
                faction.color = string.format("#%02X%02X%02X", finalR, finalG, finalB)
                TriggerServerCallback("core:gestion-factions:updateField", faction.name, "color", faction.color)
                StaffMenu.manageFactionDetails.refresh()
            end,
            nil
        )
    end)

    StaffMenu.manageFactionDetails.Separator(nil)

    -- Si faction inactive, afficher les positions à configurer et le bouton d'activation
    if not faction.active then
        local posLab = faction.posLaboratory or { x = 0, y = 0, z = 0 }
        local posCraft = faction.posCraft or { x = 0, y = 0, z = 0 }
        local posStock = faction.posStockage or { x = 0, y = 0, z = 0 }
        local posGarage = faction.posGarage or { x = 0, y = 0, z = 0 }

        local labSet = posLab.x ~= 0 or posLab.y ~= 0 or posLab.z ~= 0
        local craftSet = posCraft.x ~= 0 or posCraft.y ~= 0 or posCraft.z ~= 0
        local stockSet = posStock.x ~= 0 or posStock.y ~= 0 or posStock.z ~= 0
        local garageSet = posGarage.x ~= 0 or posGarage.y ~= 0 or posGarage.z ~= 0

        StaffMenu.manageFactionDetails.Button(":pin: POS LABORATOIRE", labSet and "Configuré" or "Non configuré", nil, "chevron", false, function()
            TriggerServerCallback("core:gestion-factions:setPosition", faction.name, "posLaboratory")
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Position laboratoire définie." })
            faction.posLaboratory = { x = 1, y = 1, z = 1 } -- Placeholder, will be set server-side
            StaffMenu.manageFactionDetails.refresh()
        end)

        StaffMenu.manageFactionDetails.Button(":pin: POS CRAFT", craftSet and "Configuré" or "Non configuré", nil, "chevron", false, function()
            TriggerServerCallback("core:gestion-factions:setPosition", faction.name, "posCraft")
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Position craft définie." })
            faction.posCraft = { x = 1, y = 1, z = 1 }
            StaffMenu.manageFactionDetails.refresh()
        end)

        StaffMenu.manageFactionDetails.Button(":pin: POS STOCKAGE", stockSet and "Configuré" or "Non configuré", nil, "chevron", false, function()
            TriggerServerCallback("core:gestion-factions:setPosition", faction.name, "posStockage")
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Position stockage définie." })
            faction.posStockage = { x = 1, y = 1, z = 1 }
            StaffMenu.manageFactionDetails.refresh()
        end)

        StaffMenu.manageFactionDetails.Button(":pin: POS GARAGE", garageSet and "Configuré" or "Non configuré", nil, "chevron", false, function()
            TriggerServerCallback("core:gestion-factions:setPosition", faction.name, "posGarage")
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Position garage définie." })
            faction.posGarage = { x = 1, y = 1, z = 1 }
            StaffMenu.manageFactionDetails.refresh()
        end)

        StaffMenu.manageFactionDetails.Separator(nil)

        StaffMenu.manageFactionDetails.Button(":rocket: ACTIVER LA FACTION", "Démarrer la faction", nil, "check", false, function()
            local result = TriggerServerCallback("core:gestion-factions:activate", faction.name)
            if result then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Faction '" .. faction.label .. "' activée." })
                faction.active = true
                -- Refresh factions list
                StaffMenu.data.allFactions = TriggerServerCallback("core:gestion-factions:getAll") or {}
                StaffMenu.manageFactionDetails.refresh()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Erreur : vérifiez que les positions sont configurées." })
            end
        end)
    else
        -- Faction active - afficher gestion grades et membres
        StaffMenu.manageFactionDetails.Button(":chart: GÉRER LES GRADES", (faction.gradeCount or 0) .. " grades", nil, "arrow", false, function()
            StaffMenu.manageFactionDetails.close()
            StaffMenu.OpenGradesManager(faction.name)
        end)

        StaffMenu.manageFactionDetails.Button(":users: GÉRER LES MEMBRES", (faction.memberCount or 0) .. " membres", nil, "chevron", false, function()
            StaffMenu.data.managedFactionMembers = TriggerServerCallback("core:gestion-factions:getMembers", faction.name) or {}
        end, StaffMenu.manageFactionMembers)
    end

    StaffMenu.manageFactionDetails.Separator(nil)

    StaffMenu.manageFactionDetails.Button(":trash: SUPPRIMER LA FACTION", "Action irréversible", nil, "chevron", false, function()
        VFW.Nui.Focus(true)
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour confirmer")
        VFW.Nui.Focus(false)
        if confirm and string.lower(confirm) == "oui" then
            TriggerServerCallback("core:gestion-factions:delete", faction.name)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Faction '" .. faction.label .. "' supprimée." })
            StaffMenu.data.allFactions = TriggerServerCallback("core:gestion-factions:getAll") or {}
            StaffMenu.manageFactionDetails.close()
            StaffMenu.manageFactions.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Confirmation incorrecte." })
        end
    end)
end

--- .BuildManageFactionGradesMenu
--- Manage grades for a faction
function StaffMenu.BuildManageFactionGradesMenu()
    local faction = StaffMenu.data.selectedManagedFaction
    local grades = StaffMenu.data.managedFactionGrades or {}

    if not faction then return end

    -- Add grade button
    StaffMenu.manageFactionGrades.Button("AJOUTER UN GRADE", "Ajouter un nouveau grade hiérarchique à cette faction", nil, "chevron", false, function()
        local gradeName = VFW.Nui.KeyboardInput(true, "Nom du grade (ex: soldat)")
        if not gradeName or gradeName == "" then return end

        local gradeLabel = VFW.Nui.KeyboardInput(true, "Label du grade (ex: Soldat)")
        if not gradeLabel or gradeLabel == "" then return end

        -- Le niveau est automatiquement calculé côté serveur (prochain niveau disponible)
        local result = TriggerServerCallback("core:gestion-factions:addGrade", faction.name, gradeName, gradeLabel)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Grade '" .. gradeLabel .. "' ajouté." })
            StaffMenu.data.managedFactionGrades = TriggerServerCallback("core:gestion-factions:getGrades", faction.name) or {}
            StaffMenu.manageFactionGrades.refresh()
        else
            local errorMsg = (result and result.error) or "Erreur lors de l'ajout du grade"
          VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = errorMsg .. "." })
        end
    end)

    StaffMenu.manageFactionGrades.Separator(nil)

    -- List existing grades (sorted by level descending - highest first)
    if #grades == 0 then
        StaffMenu.manageFactionGrades.Button("AUCUN GRADE", "Ajoutez-en un", nil, "chevron", true, function() end)
    else
        -- Sort grades by level descending
        table.sort(grades, function(a, b)
            return (a.grade or a.level or 0) > (b.grade or b.level or 0)
        end)

        -- Find min and max levels
        local minLevel, maxLevel = grades[#grades].grade or grades[#grades].level or 0, grades[1].grade or grades[1].level or 0

        for i, grade in ipairs(grades) do
            local gradeLevel = grade.grade or grade.level or 0
            local canMoveUp = gradeLevel < maxLevel and gradeLevel < 97
            local canMoveDown = gradeLevel > minLevel and gradeLevel < 98

            -- Grade button with actions submenu
            StaffMenu.manageFactionGrades.Button(
                grade.label or grade.name,
                "Niveau: " .. gradeLevel,
                nil,
                "chevron",
                false,
                function()
                    StaffMenu.data.selectedGrade = grade
                end,
                StaffMenu.manageGradeActions
            )

            -- Move up button (only if not at max)
            if canMoveUp then
                StaffMenu.manageFactionGrades.Button(
                    " ^ MONTER " .. (grade.label or grade.name),
                    "Échanger avec le grade au-dessus",
                    nil,
                    "arrow",
                    false,
                    function()
                        local result = TriggerServerCallback("core:gestion-factions:moveGrade", faction.name, gradeLevel, "up")
                        if result and result.success then
                            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Grade monté." })
                            StaffMenu.data.managedFactionGrades = TriggerServerCallback("core:gestion-factions:getGrades", faction.name) or {}
                            StaffMenu.manageFactionGrades.refresh()
                        else
                            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = (result and result.error or "Erreur") .. "." })
                        end
                    end
                )
            end

            -- Move down button (only if not at min)
            if canMoveDown then
                StaffMenu.manageFactionGrades.Button(
                    " v DESCENDRE " .. (grade.label or grade.name),
                    "Échanger avec le grade en-dessous",
                    nil,
                    "arrow",
                    false,
                    function()
                        local result = TriggerServerCallback("core:gestion-factions:moveGrade", faction.name, gradeLevel, "down")
                        if result and result.success then
                            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Grade descendu." })
                            StaffMenu.data.managedFactionGrades = TriggerServerCallback("core:gestion-factions:getGrades", faction.name) or {}
                            StaffMenu.manageFactionGrades.refresh()
                        else
                            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = (result and result.error or "Erreur") .. "." })
                        end
                    end
                )
            end

            -- Add separator between grades
            if i < #grades then
                StaffMenu.manageFactionGrades.Separator(nil)
            end
        end
    end
end

--- .BuildManageGradeActionsMenu
--- Actions for a specific grade (rename, delete)
function StaffMenu.BuildManageGradeActionsMenu()
    local faction = StaffMenu.data.selectedManagedFaction
    local grade = StaffMenu.data.selectedGrade

    if not faction or not grade then return end

    local gradeLevel = grade.grade or grade.level or 0

    -- Display grade info
    StaffMenu.manageGradeActions.Button((grade.label or grade.name), "Niveau " .. gradeLevel, nil, nil, true, function() end)

    StaffMenu.manageGradeActions.Separator(nil)

    -- Rename grade
    StaffMenu.manageGradeActions.Button("RENOMMER LE GRADE", "Modifier le nom", nil, "chevron", false, function()
        local newLabel = VFW.Nui.KeyboardInput(true, "Nouveau nom du grade")
        if newLabel and newLabel ~= "" then
            local result = TriggerServerCallback("core:gestion-factions:updateGradeLabel", faction.name, gradeLevel, newLabel)
            if result then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Grade renommé en '" .. newLabel .. "'." })
                grade.label = newLabel
                StaffMenu.data.managedFactionGrades = TriggerServerCallback("core:gestion-factions:getGrades", faction.name) or {}
                StaffMenu.manageGradeActions.close()
                StaffMenu.manageGradeActions.parent.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Erreur lors du renommage." })
            end
        end
    end)

    StaffMenu.manageGradeActions.Separator(nil)

    -- Delete grade
    StaffMenu.manageGradeActions.Button("SUPPRIMER LE GRADE", "Action irréversible", nil, "delete", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'supprimer' pour confirmer")
        if confirm == "supprimer" then
            TriggerServerCallback("core:gestion-factions:deleteGrade", faction.name, gradeLevel)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Grade supprimé." })
            StaffMenu.data.managedFactionGrades = TriggerServerCallback("core:gestion-factions:getGrades", faction.name) or {}
            StaffMenu.manageGradeActions.close()
            StaffMenu.manageGradeActions.parent.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Confirmation incorrecte." })
        end
    end)
end

--- .BuildManageFactionMembersMenu
--- Manage members for a faction
function StaffMenu.BuildManageFactionMembersMenu()
    local faction = StaffMenu.data.selectedManagedFaction
    local members = StaffMenu.data.managedFactionMembers or {}
    local grades = StaffMenu.data.managedFactionGrades or {}

    if not faction then return end

    StaffMenu.manageFactionMembers.ClearItems()

    -- Add member by server ID (connected players)
    StaffMenu.manageFactionMembers.Button(":plus: AJOUTER PAR ID SERVEUR", "Joueur connecté", nil, "chevron", false, function()
        local serverId = VFW.Nui.KeyboardInput(true, "ID du joueur (ex: 1, 2, 3...)")
        if not serverId or serverId == "" then return end

        local serverIdNum = tonumber(serverId)
        if not serverIdNum then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Cet identifiant n'est pas valide." })
            return
        end

        local result = TriggerServerCallback("core:gestion-factions:addMemberById", { faction = faction.name, serverId = serverIdNum })
        if result and result.state then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Membre ajouté: " .. (result.name or "Inconnu") .. "." })
            StaffMenu.data.managedFactionMembers = TriggerServerCallback("core:gestion-factions:getMembers", faction.name) or {}
            StaffMenu.manageFactionMembers.refresh()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = (result and result.error or "Joueur non trouvé") .. "." })
        end
    end)

    -- Add member by global ID (offline players) — opens character picker
    StaffMenu.manageFactionMembers.Button(":plus: AJOUTER PAR UUID", "Joueur hors-ligne", nil, "chevron", false, function()
        local globalId = VFW.Nui.KeyboardInput(true, "ID Global du joueur (UUID)")
        if not globalId or globalId == "" then return end

        local globalIdNum = tonumber(globalId)
        if not globalIdNum then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Cet identifiant n'est pas valide." })
            return
        end

        local charsResult = TriggerServerCallback("core:gestion-factions:getCharsByGlobalId", globalIdNum)
        if not charsResult or not charsResult.state then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = charsResult and charsResult.error or "Aucun personnage trouvé." })
            return
        end

        StaffMenu.data.charPickerUUID = globalIdNum
        StaffMenu.data.charPickerList = charsResult.chars
        StaffMenu.manageFactionCharSelect.open()
    end)

    StaffMenu.manageFactionMembers.Separator(nil)

    -- List existing members
    if #members == 0 then
        StaffMenu.manageFactionMembers.Button("AUCUN MEMBRE", "Ajoutez-en un", nil, nil, true, function() end)
    else
        for _, member in ipairs(members) do
            local memberName = (member.firstname or member.fname or "") .. " " .. (member.lastname or member.lname or "")
            local memberGrade = member.faction_grade or member.grade or 0
            local gradeName = "Grade " .. memberGrade
            local isOnline = member.isOnline == true

            -- Find grade label
            for _, g in ipairs(grades) do
                if (g.grade or g.level) == memberGrade then
                    gradeName = g.label or g.name
                    break
                end
            end

            -- Ajouter indicateur de connexion
            local statusIcon = isOnline and ":dot-green: " or ":dot-red: "
          local statusText = isOnline and " (ID: " .. (member.serverId or "?") .. ")" or ""

          StaffMenu.manageFactionMembers.Button(
                statusIcon .. memberName,
                gradeName .. statusText,
                nil,
                "chevron",
                false,
                function()
                    StaffMenu.data.selectedMember = member
                    StaffMenu.data.selectedMemberGrade = memberGrade
                end,
                StaffMenu.manageMemberActions
            )
        end
    end
end

--- .BuildManageFactionCharSelectMenu
--- Character picker shown after entering a UUID — lets staff choose which character to add
function StaffMenu.BuildManageFactionCharSelectMenu()
    local faction = StaffMenu.data.selectedManagedFaction
    local uuid = StaffMenu.data.charPickerUUID
    local chars = StaffMenu.data.charPickerList or {}

    if not faction or not uuid then return end

    StaffMenu.manageFactionCharSelect.ClearItems()
    StaffMenu.manageFactionCharSelect.Button("UUID: " .. uuid, "Sélectionnez le personnage à ajouter", nil, nil, true, function() end)
    StaffMenu.manageFactionCharSelect.Separator(nil)

    if #chars == 0 then
        StaffMenu.manageFactionCharSelect.Button("AUCUN PERSONNAGE", "Cet UUID n'a pas de personnage", nil, nil, true, function() end)
        return
    end

    for _, char in ipairs(chars) do
        local firstName = char.firstname or ""
      local lastName = char.lastname or ""
      local charName = (firstName .. " " .. lastName):match("^%s*(.-)%s*$")
        if charName == "" then charName = char.identifier end
        local charSlot = char.identifier:match("^(%d+):")
        local sublabel = "Personnage " .. (charSlot or "?")

        StaffMenu.manageFactionCharSelect.Button(charName, sublabel, nil, "chevron", false, function()
            local result = TriggerServerCallback("core:gestion-factions:addMember", { faction = faction.name, identifier = char.identifier })
            if result and result.state then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Membre ajouté: " .. (result.name or charName) .. "." })
                StaffMenu.data.managedFactionMembers = TriggerServerCallback("core:gestion-factions:getMembers", faction.name) or {}
                StaffMenu.manageFactionCharSelect.close()
                StaffMenu.manageFactionMembers.refresh()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = result and result.error or "Erreur lors de l'ajout." })
            end
        end)
    end
end

--- .BuildManageMemberActionsMenu
--- Actions for a specific member (change grade, remove)
function StaffMenu.BuildManageMemberActionsMenu()
    local faction = StaffMenu.data.selectedManagedFaction
    local member = StaffMenu.data.selectedMember

    if not faction or not member then return end

    -- Always load grades to ensure they're for the current faction
    local grades = TriggerServerCallback("core:gestion-factions:getGrades", faction.name) or {}

    local memberName = (member.firstname or member.fname or "") .. " " .. (member.lastname or member.lname or "")
    local currentGrade = member.faction_grade or member.grade or 0

    -- Display member info
    StaffMenu.manageMemberActions.Button(":user: " .. memberName, "Membre sélectionné", nil, nil, true, function() end)

    StaffMenu.manageMemberActions.Separator("ACTIONS RAPIDES")

    -- Vérifier si le joueur est connecté
    local isOnline = member.isOnline == true
    local serverId = member.serverId

    -- Téléportation vers le membre
    StaffMenu.manageMemberActions.Button(":rocket: SE TÉLÉPORTER À LUI", isOnline and "Joueur connecté" or "Joueur hors-ligne", nil, "arrow", not isOnline, function()
        if serverId then
            local targetPed = GetPlayerPed(GetPlayerFromServerId(serverId))
            if targetPed and DoesEntityExist(targetPed) then
                local coords = GetEntityCoords(targetPed)
                SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Téléporté vers " .. memberName .. "." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Impossible de localiser le joueur." })
            end
        end
    end)

    -- Téléporter le membre vers soi
    StaffMenu.manageMemberActions.Button(":pin: LE TÉLÉPORTER À MOI", isOnline and "Joueur connecté" or "Joueur hors-ligne", nil, "arrow", not isOnline, function()
        if serverId then
            local myCoords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent("core:staff:teleportPlayer", serverId, myCoords.x, myCoords.y, myCoords.z)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = memberName .. " téléporté vers vous." })
        end
    end)

    -- Spectate le membre
    StaffMenu.manageMemberActions.Button(":eye: SPECTATE", isOnline and "Observer le joueur" or "Joueur hors-ligne", nil, "arrow", not isOnline, function()
        if serverId and StaffMenu.SpectatePlayer then
            StaffMenu.SpectatePlayer(serverId)
        end
    end)

    StaffMenu.manageMemberActions.Separator("CHANGER LE GRADE")

    -- Show message if no grades
    if #grades == 0 then
        StaffMenu.manageMemberActions.Button(":warning: AUCUN GRADE", "Créez des grades d'abord", nil, nil, true, function() end)
    end

    -- List all grades to select
    for _, grade in ipairs(grades) do
        local gradeLevel = grade.grade or grade.level or 0
        local isCurrentGrade = gradeLevel == currentGrade
        local icon = isCurrentGrade and "check" or nil

        StaffMenu.manageMemberActions.Button(
            grade.label or grade.name,
            isCurrentGrade and "Grade actuel" or "Niveau " .. gradeLevel,
            nil,
            icon,
            isCurrentGrade,
            function()
                if not isCurrentGrade then
                    local result = TriggerServerCallback("core:gestion-factions:updateMemberGrade", faction.name, member.identifier, gradeLevel)
                    if result then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Grade modifié: " .. (grade.label or grade.name) .. "." })
                        member.faction_grade = gradeLevel
                        member.grade = gradeLevel
                        StaffMenu.data.managedFactionMembers = TriggerServerCallback("core:gestion-factions:getMembers", faction.name) or {}
                        StaffMenu.manageMemberActions.close()
                        StaffMenu.manageMemberActions.parent.open()
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Erreur lors du changement de grade." })
                    end
                end
            end
        )
    end

    StaffMenu.manageMemberActions.Separator(nil)

    -- Remove member button
    StaffMenu.manageMemberActions.Button(":trash: RETIRER DE LA FACTION", "Action irréversible", nil, "chevron", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'virer' pour confirmer")
        if confirm == "virer" then
            TriggerServerCallback("core:gestion-factions:removeMember", faction.name, member.identifier)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Factions', message = "Membre retiré." })
            StaffMenu.data.managedFactionMembers = TriggerServerCallback("core:gestion-factions:getMembers", faction.name) or {}
            StaffMenu.manageMemberActions.close()
            StaffMenu.manageMemberActions.parent.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Factions', message = "Confirmation incorrecte." })
        end
    end)
end
