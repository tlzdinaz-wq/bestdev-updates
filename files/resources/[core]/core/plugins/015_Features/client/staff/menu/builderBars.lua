---
--- Builder: Gestion Bar & Restaurants (menu parent)
--- Regroupe les outils de gestion des bars et restaurants:
--- - Cartes de bars (items autorises)
--- - Points de bars (recolte, transformation, PNJ de vente)
---

-- ============================================
-- Menu principal: Gestion Bar & Restaurants
-- ============================================
function StaffMenu.BuildBarsMainMenu()
    StaffMenu.builderBarsMain.Button(
        "CARTES BARS ET RESTAURANTS",
        "Gérer les items autorisés par bar et restaurant",
        nil, "chevron", false,
        function() end,
        StaffMenu.builderBarCards
    )

    StaffMenu.builderBarsMain.Button(
        "POINTS DE BARS",
        "Gérer les zones de récolte, transformation et PNJ de vente",
        nil, "chevron", false,
        function() end,
        StaffMenu.builderBarsPoints
    )
end

-- ============================================
-- Menu liste des bars (points)
-- ============================================
function StaffMenu.BuildBarsPointsMenu()
    local farmConfigs = TriggerServerCallback("core:farm:getConfigs") or {}

    local bars = {}
    for societyName, config in pairs(farmConfigs) do
        if config.is_bar then
            bars[#bars + 1] = { name = societyName, config = config }
        end
    end

    table.sort(bars, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    if #bars == 0 then
        StaffMenu.builderBarsPoints.Button(
            "Aucun bar configuré",
            "Aucun bar trouvé dans les configs farm",
            nil, nil, true, function() end
        )
        return
    end

    for _, bar in ipairs(bars) do
        StaffMenu.builderBarsPoints.Button(
            bar.name,
            "Gérer les points de " .. bar.name,
            nil, "chevron", false,
            function()
                StaffMenu.builderBarsPointsOptions.currentConfig = {
                    societyName = bar.name,
                    config = bar.config,
                }
            end,
            StaffMenu.builderBarsPointsOptions
        )
    end
end

-- ============================================
-- Menu options d'un bar (recolte, transfo, PNJ)
-- ============================================
function StaffMenu.BuildBarsPointsOptionsMenu()
    local societyName = StaffMenu.builderBarsPointsOptions.currentConfig.societyName
    local config = StaffMenu.builderBarsPointsOptions.currentConfig.config

    -- === PNJ DE VENTE ===
    StaffMenu.builderBarsPointsOptions.Separator(":user::briefcase: PNJ de vente")

    if config.ped_coords and tonumber(config.ped_coords.x) ~= 0.0 then
        StaffMenu.builderBarsPointsOptions.Button(
            ("Position: %.1f, %.1f, %.1f"):format(config.ped_coords.x, config.ped_coords.y, config.ped_coords.z),
            nil, nil, nil, true, function() end
        )
    end

    StaffMenu.builderBarsPointsOptions.Button("Se TP au PNJ", nil, nil, "chevron", false, function()
        if config.ped_coords and tonumber(config.ped_coords.x) ~= 0.0 then
            SetEntityCoords(PlayerPedId(), config.ped_coords.x, config.ped_coords.y, config.ped_coords.z)
        end
    end)

    StaffMenu.builderBarsPointsOptions.Button("Définir la position du PNJ ici", nil, nil, "chevron", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        -- GetEntityCoords returns position at ped center (waist), subtract 1.0 to get ground level
        local newPedPos = { x = coords.x, y = coords.y, z = coords.z - 1.0, heading = heading }
        TriggerServerEvent("core:farm:updatePedPosition", societyName, newPedPos)
        config.ped_coords = newPedPos
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Bars', message = "Position du PNJ mise à jour." })
        StaffMenu.builderBarsPointsOptions.refresh()
    end)

    -- === POINTS DE RÉCOLTE ===
    StaffMenu.builderBarsPointsOptions.Separator(":pin: Points de récolte")

    local harvestPoints = config.harvest or {}
    local isDefault = config.harvestIsDefault
    local defaultTag = isDefault and " (défaut)" or " (custom)"

  StaffMenu.builderBarsPointsOptions.Button(
        (#harvestPoints > 1 and "%d points de récolte%s" or "%d point de récolte%s"):format(#harvestPoints, defaultTag),
        nil, nil, nil, true, function() end
    )

    for i, pt in ipairs(harvestPoints) do
        StaffMenu.builderBarsPointsOptions.Button(
            ("#%d: %.1f, %.1f, %.1f"):format(i, pt.x, pt.y, pt.z),
            "Cliquer pour se TP",
            nil, "chevron", false,
            function()
                SetEntityCoords(PlayerPedId(), pt.x, pt.y, pt.z)
            end
        )
        StaffMenu.builderBarsPointsOptions.Button(
            ("Supprimer le point #%d"):format(i),
            nil, nil, "chevron", false,
            function()
                table.remove(harvestPoints, i)
                TriggerServerEvent("core:farm:updateHarvestPoints", societyName, harvestPoints)
                config.harvest = harvestPoints
                config.harvestIsDefault = false
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Bars', message = ("Point #%d supprimé."):format(i) })
                StaffMenu.builderBarsPointsOptions.refresh()
            end
        )
    end

    StaffMenu.builderBarsPointsOptions.Button("Ajouter un point de récolte ici", nil, nil, "chevron", false, function()
        local coords = GetEntityCoords(PlayerPedId())
        local newPoint = { x = coords.x, y = coords.y, z = coords.z }
        harvestPoints[#harvestPoints + 1] = newPoint
        TriggerServerEvent("core:farm:updateHarvestPoints", societyName, harvestPoints)
        config.harvest = harvestPoints
        config.harvestIsDefault = false
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Bars', message = ("Point de récolte #%d ajouté."):format(#harvestPoints) })
        StaffMenu.builderBarsPointsOptions.refresh()
    end)

    if #harvestPoints > 0 then
        StaffMenu.builderBarsPointsOptions.Button("Se TP au premier point", nil, nil, "chevron", false, function()
            local pt = harvestPoints[1]
            SetEntityCoords(PlayerPedId(), pt.x, pt.y, pt.z)
        end)
    end

    -- === POINTS DE TRANSFORMATION ===
    StaffMenu.builderBarsPointsOptions.Separator(":wrench: Points de transformation")

    local processingPoints = config.processing_points or {}
    local isDefaultProc = config.processingIsDefault

    StaffMenu.builderBarsPointsOptions.Button(
        (#processingPoints > 1 and "%d points de transformation%s" or "%d point de transformation%s"):format(#processingPoints, isDefaultProc and " (défaut)" or " (custom)"),
        nil, nil, nil, true, function() end
    )

    for i, pt in ipairs(processingPoints) do
        StaffMenu.builderBarsPointsOptions.Button(
            ("#%d: %.1f, %.1f, %.1f"):format(i, pt.x, pt.y, pt.z),
            "Cliquer pour se TP",
            nil, "chevron", false,
            function()
                SetEntityCoords(PlayerPedId(), pt.x, pt.y, pt.z)
            end
        )
        StaffMenu.builderBarsPointsOptions.Button(
            ("Supprimer le point #%d"):format(i),
            nil, nil, "chevron", false,
            function()
                table.remove(processingPoints, i)
                TriggerServerEvent("core:farm:updateProcessingPoints", societyName, processingPoints)
                config.processing_points = processingPoints
                config.processingIsDefault = false
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Bars', message = ("Point #%d supprimé."):format(i) })
                StaffMenu.builderBarsPointsOptions.refresh()
            end
        )
    end

    StaffMenu.builderBarsPointsOptions.Button("Ajouter un point de transformation ici", nil, nil, "chevron", false, function()
        local coords = GetEntityCoords(PlayerPedId())
        local newPoint = { x = coords.x, y = coords.y, z = coords.z }
        processingPoints[#processingPoints + 1] = newPoint
        TriggerServerEvent("core:farm:updateProcessingPoints", societyName, processingPoints)
        config.processing_points = processingPoints
        config.processingIsDefault = false
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Bars', message = ("Point de transformation #%d ajouté."):format(#processingPoints) })
        StaffMenu.builderBarsPointsOptions.refresh()
    end)

    if #processingPoints > 0 then
        StaffMenu.builderBarsPointsOptions.Button("Se TP au premier point", nil, nil, "chevron", false, function()
            local pt = processingPoints[1]
            SetEntityCoords(PlayerPedId(), pt.x, pt.y, pt.z)
        end)
    end

    -- === ANIMATIONS ===
    StaffMenu.builderBarsPointsOptions.Separator(":film: Animations")

    local animTypes = {
        { key = "harvest", label = "Récolte", dbKey = "harvest_anim", defaultDict = "amb@world_human_gardener_plant@male@enter", defaultName = "enter" },
        { key = "processing", label = "Transformation", dbKey = "processing_anim", defaultDict = "mini@repair", defaultName = "fixing_a_player" },
        { key = "selling", label = "Vente", dbKey = "selling_anim", defaultDict = "mp_common", defaultName = "givetake1_a" },
    }

    local anims = config.animations or {}

    for _, animType in ipairs(animTypes) do
        local currentAnim = anims[animType.key]
        local displayText = currentAnim
            and ("%s: %s / %s"):format(animType.label, currentAnim.dict, currentAnim.name)
            or ("%s: Par défaut"):format(animType.label)

        StaffMenu.builderBarsPointsOptions.Button(
            displayText,
            currentAnim
                and ("Défaut: %s / %s"):format(animType.defaultDict, animType.defaultName)
                or ("Défaut: %s / %s"):format(animType.defaultDict, animType.defaultName),
            nil, "chevron", false,
            function()
                local newDict = VFW.Nui.KeyboardInput(true, ("Dict animation %s"):format(animType.label), currentAnim and currentAnim.dict or animType.defaultDict)
                if newDict == nil then return end
                if newDict == "" then
                    -- Reset to default
                    TriggerServerEvent("core:farm:updateAnimation", societyName, animType.dbKey, nil)
                    anims[animType.key] = nil
                    config.animations = anims
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Bars', message = ("%s: réinitialisé par défaut"):format(animType.label) })
                    StaffMenu.builderBarsPointsOptions.refresh()
                    return
                end

                local newName = VFW.Nui.KeyboardInput(true, ("Nom animation %s"):format(animType.label), currentAnim and currentAnim.name or animType.defaultName)
                if newName == nil or newName == "" then return end

                local newAnimData = { dict = newDict, name = newName }
                TriggerServerEvent("core:farm:updateAnimation", societyName, animType.dbKey, newAnimData)
                anims[animType.key] = newAnimData
                config.animations = anims
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Bars', message = ("%s: %s / %s"):format(animType.label, newDict, newName) })
                StaffMenu.builderBarsPointsOptions.refresh()
            end
        )
    end

    -- === PRIX & GAINS ===
    StaffMenu.builderBarsPointsOptions.Separator(":money: Prix des items")

    if config.items and next(config.items) then
        for action, itemsArray in pairs(config.items) do
            if action == "process" or action == "processing" then
                for _, itemData in ipairs(itemsArray) do
                    StaffMenu.builderBarsPointsOptions.Button(
                        ("%s: %s"):format(itemData.label, VFW.Math.FormatMoney(itemData.price)),
                        "Cliquer pour modifier le prix",
                        nil, "chevron", false,
                        function()
                            local newPriceInput = VFW.Nui.KeyboardInput(true, ("Nouveau prix pour %s"):format(itemData.label), tostring(itemData.price))
                            local newPrice = tonumber(newPriceInput)
                            if newPrice and newPrice >= 0 then
                                TriggerServerEvent("core:farm:updateItemPrice", societyName, itemData.name, newPrice)
                                itemData.price = newPrice
                                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Bars', message = ("Prix de %s: %s"):format(itemData.label, VFW.Math.FormatMoney(newPrice)) })
                                StaffMenu.builderBarsPointsOptions.refresh()
                            elseif newPriceInput ~= nil then
                                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Bars', message = "Ce prix n'est pas valide." })
                            end
                        end
                    )
                end
            end
        end
    else
        StaffMenu.builderBarsPointsOptions.Button("Aucun item à configurer", nil, nil, nil, true, function() end)
    end

    StaffMenu.builderBarsPointsOptions.Separator(":money: Gains de la société")
    StaffMenu.builderBarsPointsOptions.Button(
        "Gain restant pour l'entreprise",
        "Gain pour l'entreprise en pourcentage",
        config.society_percent or 0,
        "chevron", false,
        function()
            local percent = VFW.Nui.KeyboardInput(true, ("Gain restant pour %s"):format(societyName), tostring(config.society_percent or 0))
            percent = tonumber(percent)
            if percent and percent >= 0 then
                TriggerServerEvent("core:farm:updateSocietyPercent", societyName, percent)
                config.society_percent = percent
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Bars', message = ("Gain: %s%%"):format(percent) })
                StaffMenu.builderBarsPointsOptions.refresh()
            end
        end
    )
end

-- ============================================
-- Enregistrement des callbacks OnOpen
-- ============================================
StaffMenu.builderBarsMain.OnOpen(function()
    StaffMenu.BuildBarsMainMenu()
end)

StaffMenu.builderBarsPoints.OnOpen(function()
    StaffMenu.BuildBarsPointsMenu()
end)

StaffMenu.builderBarsPointsOptions.OnOpen(function()
    StaffMenu.BuildBarsPointsOptionsMenu()
end)
