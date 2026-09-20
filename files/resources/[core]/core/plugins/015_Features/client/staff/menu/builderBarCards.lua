---
--- Builder: Gestion des cartes de bars
--- Permet de gerer les items autorises a la vente pour chaque bar
---

-- Variables locales pour stocker l'etat
local selectedBarJob = nil
local selectedBarLabel = nil
local cachedBars = {}
local cachedItems = {}
local searchResults = {}
local selectedSection = "BOISSONS"

-- ============================================
-- Menu principal: Liste des bars
-- ============================================
function StaffMenu.BuildBarCardsMenu()
    cachedBars = TriggerServerCallback("barcards:getAllBars") or {}

    for _, bar in ipairs(cachedBars) do
        StaffMenu.builderBarCards.Button(
            bar.label,
            "Gérer les items de " .. bar.label,
            nil,
            "chevron",
            false,
            function()
                selectedBarJob = bar.jobName
                selectedBarLabel = bar.label
            end,
            StaffMenu.builderBarCardsList
        )
    end

    if #cachedBars == 0 then
        StaffMenu.builderBarCards.Button(
            "Aucun bar/restaurant configuré",
            "Ajoutez des entrées dans BarsConfig",
            nil,
            nil,
            true,
            function() end
        )
    end
end

-- ============================================
-- Menu liste items d'un bar
-- ============================================
function StaffMenu.BuildBarCardsListMenu()
    if not selectedBarJob then
        StaffMenu.builderBarCardsList.Button(
            "Erreur",
            "Aucun bar sélectionné",
            nil,
            nil,
            true,
            function() end
        )
        return
    end

    -- Bouton pour ajouter un item
    StaffMenu.builderBarCardsList.Button(
        "+ AJOUTER UN ITEM",
        "Rechercher et ajouter un item à la carte",
        nil,
        "chevron",
        false,
        function()
            searchResults = {}
            selectedSection = "BOISSONS"
      end,
        StaffMenu.builderBarCardsItems
    )

    -- Bouton pour gérer les points CARTE (interactions flottantes)
    StaffMenu.builderBarCardsList.Button(
        ":pin: POINTS CARTE",
        "Définir des points où les joueurs peuvent ouvrir la carte",
        nil,
        "chevron",
        false,
        function() end,
        StaffMenu.builderBarCardsPoints
    )

    StaffMenu.builderBarCardsList.Separator("ITEMS AUTORISES")

    cachedItems = TriggerServerCallback("barcards:getAllowedItems", selectedBarJob) or {}

    if #cachedItems == 0 then
        StaffMenu.builderBarCardsList.Button(
            "Aucun item",
            "Ajoutez des items avec le bouton ci-dessus",
            nil,
            nil,
            true,
            function() end
        )
        return
    end

    -- Grouper par section
    local sections = {}
    for _, item in ipairs(cachedItems) do
        local section = item.section or "BOISSONS"
      if not sections[section] then
            sections[section] = {}
        end
        table.insert(sections[section], item)
    end

    -- Afficher par section
    for sectionName, sectionItems in pairs(sections) do
        StaffMenu.builderBarCardsList.Separator(sectionName)

        for _, item in ipairs(sectionItems) do
            StaffMenu.builderBarCardsList.Button(
                item.label,
                item.name .. " - Cliquez pour retirer",
                nil,
                nil,
                false,
                function()
                    local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour confirmer la suppression", "")
                    if confirm and confirm:lower() == "oui" then
                        local success, message = TriggerServerCallback("barcards:removeItem", selectedBarJob, item.name)
                        if success then
                            VFW.ShowNotification({
                                type = "JOB",
                                title = selectedBarLabel,
                                subtitle = "Information Carte",
                                subtitleColor = "#FF9800",
                                content = "L'item " .. item.label .. " a été retiré de la carte."
                          })
                            StaffMenu.builderBarCardsList.close()
                            Wait(100)
                            StaffMenu.builderBarCardsList.open()
                        else
                            VFW.ShowNotification({
                                type = "JOB",
                                title = selectedBarLabel,
                                subtitle = "Erreur",
                                subtitleColor = "#e03030",
                                content = message or "Erreur lors du retrait de l'item"
                          })
                        end
                    end
                end
            )
        end
    end
end

-- ============================================
-- Menu ajout d'item (recherche)
-- ============================================
function StaffMenu.BuildBarCardsItemsMenu()
    if not selectedBarJob then
        StaffMenu.builderBarCardsItems.Button(
            "Erreur",
            "Aucun bar sélectionné",
            nil,
            nil,
            true,
            function() end
        )
        return
    end

    -- Bouton de recherche
    StaffMenu.builderBarCardsItems.Button(
        "RECHERCHER UN ITEM",
        "Tapez le nom de l'item a rechercher",
        nil,
        "search",
        false,
        function()
            local query = VFW.Nui.KeyboardInput(true, "Rechercher un item...", "")
            if query and query ~= "" then
                searchResults = TriggerServerCallback("barcards:searchItems", query) or {}
                StaffMenu.builderBarCardsItems.close()
                Wait(100)
                StaffMenu.builderBarCardsItems.open()
            end
        end
    )

    -- Selecteur de section
    StaffMenu.builderBarCardsItems.Button(
        "SECTION: " .. selectedSection,
        "Changer la section de l'item",
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom de la section (BOISSONS, SNACKS, etc.)", selectedSection)
            if input and input ~= "" then
                selectedSection = input:upper()
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'INFO', subtitle = 'Builder Cartes',
                    message = "Section: " .. selectedSection
                })
                StaffMenu.builderBarCardsItems.close()
                Wait(100)
                StaffMenu.builderBarCardsItems.open()
            end
        end
    )

    StaffMenu.builderBarCardsItems.Separator("RÉSULTATS DE RECHERCHE")

    if #searchResults == 0 then
        StaffMenu.builderBarCardsItems.Button(
            "Aucun résultat",
            "Utilisez le bouton de recherche ci-dessus",
            nil,
            nil,
            true,
            function() end
        )
    else
        for _, item in ipairs(searchResults) do
            StaffMenu.builderBarCardsItems.Button(
                item.label,
                item.name .. " - Cliquez pour ajouter",
                nil,
                nil,
                false,
                function()
                    local success, message = TriggerServerCallback("barcards:addItem", selectedBarJob, item.name, selectedSection)
                    if success then
                        VFW.ShowNotification({
                            type = "JOB",
                            title = selectedBarLabel,
                            subtitle = "Information Carte",
                            subtitleColor = "#4CAF50",
                            content = "L'item " .. item.label .. " a été ajouté à la carte."
                      })
                    else
                        VFW.ShowNotification({
                            type = "JOB",
                            title = selectedBarLabel,
                            subtitle = "Erreur",
                            subtitleColor = "#e03030",
                            content = message or "Erreur lors de l'ajout de l'item"
                      })
                    end
                end
            )
        end
    end
end

-- ============================================
-- Menu: Points CARTE (interactions flottantes)
-- ============================================
function StaffMenu.BuildBarCardsPointsMenu()
    if not selectedBarJob then
        StaffMenu.builderBarCardsPoints.Button(
            "Erreur", "Aucun bar sélectionné", nil, nil, true, function() end
        )
        return
    end

    local points = TriggerServerCallback("bar:cartePoints:get", selectedBarJob) or {}

    StaffMenu.builderBarCardsPoints.Button(
        (#points > 1 and "%d points configurés" or "%d point configuré"):format(#points),
        "Position actuelle des interactions CARTE",
        nil, nil, true, function() end
    )

    StaffMenu.builderBarCardsPoints.Button(
        "+ AJOUTER UN POINT ICI",
        "Crée une interaction CARTE à votre position actuelle",
        nil, "chevron", false,
        function()
            local coords = GetEntityCoords(PlayerPedId())
            local newPoints = {}
            for _, pt in ipairs(points) do
                newPoints[#newPoints + 1] = { x = pt.x, y = pt.y, z = pt.z }
            end
            newPoints[#newPoints + 1] = { x = coords.x, y = coords.y, z = coords.z }

            local success, message = TriggerServerCallback("bar:cartePoints:set", selectedBarJob, newPoints)
            if success then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS',
                    subtitle = 'Builder Cartes',
                    message = ("Point #%d ajouté."):format(#newPoints)
                })
                StaffMenu.builderBarCardsPoints.close()
                Wait(100)
                StaffMenu.builderBarCardsPoints.open()
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR',
                    subtitle = 'Builder Cartes',
                    message = message or "Erreur"
              })
            end
        end
    )

    if #points > 0 then
        StaffMenu.builderBarCardsPoints.Separator("POINTS EXISTANTS")
    end

    for i, pt in ipairs(points) do
        StaffMenu.builderBarCardsPoints.Button(
            ("#%d: %.1f, %.1f, %.1f"):format(i, pt.x, pt.y, pt.z),
            "Cliquer pour se TP",
            nil, "chevron", false,
            function()
                SetEntityCoords(PlayerPedId(), pt.x, pt.y, pt.z)
            end
        )
        StaffMenu.builderBarCardsPoints.Button(
            ("Supprimer le point #%d"):format(i),
            nil, nil, "chevron", false,
            function()
                local newPoints = {}
                for j, p in ipairs(points) do
                    if j ~= i then
                        newPoints[#newPoints + 1] = { x = p.x, y = p.y, z = p.z }
                    end
                end
                local success, message = TriggerServerCallback("bar:cartePoints:set", selectedBarJob, newPoints)
                if success then
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS',
                        subtitle = 'Builder Cartes',
                        message = ("Point #%d supprimé."):format(i)
                    })
                    StaffMenu.builderBarCardsPoints.close()
                    Wait(100)
                    StaffMenu.builderBarCardsPoints.open()
                else
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR',
                        subtitle = 'Builder Cartes',
                        message = message or "Erreur"
                  })
                end
            end
        )
    end
end

-- ============================================
-- Enregistrement des callbacks OnOpen
-- ============================================
StaffMenu.builderBarCards.OnOpen(function()
    StaffMenu.BuildBarCardsMenu()
end)

StaffMenu.builderBarCardsList.OnOpen(function()
    StaffMenu.BuildBarCardsListMenu()
end)

StaffMenu.builderBarCardsItems.OnOpen(function()
    StaffMenu.BuildBarCardsItemsMenu()
end)

StaffMenu.builderBarCardsPoints.OnOpen(function()
    StaffMenu.BuildBarCardsPointsMenu()
end)
