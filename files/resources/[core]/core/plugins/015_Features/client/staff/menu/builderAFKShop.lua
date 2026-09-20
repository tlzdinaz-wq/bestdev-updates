-- ========================================================================
-- AFK Shop Builder for Staff Menu
-- VUI-based administration for AFK cases and prizes
-- ========================================================================

local AFKShopCache = { cases = {} }
local selectedCase = nil
local selectedPrize = nil
local newCase = {}
local newPrize = {}
local isSaving = false

local rarityLabels = { "Commun", "Peu commun", "Rare", "Légendaire" }
local typeLabels = { money = "Argent", item = "Objet", weapon = "Arme", vehicle = "Véhicule", case = "Caisse" }
local typeOptions = { "money", "item", "weapon", "vehicle", "case" }

-- Fetch cases data from server
local function fetchCasesData()
    local result = TriggerServerCallback('core:afkshop:getCases')
    if result and result.success then
        AFKShopCache.cases = result.cases or {}
    end
    return result
end

-- ==========================================
--          MAIN MENU
-- ==========================================

StaffMenu.builderAFKShop.OnOpen(function()
    StaffMenu.builderAFKShop.ClearItems()

    -- Reset state
    selectedCase = nil
    selectedPrize = nil
    newCase = {}
    newPrize = {}

    -- Sync data
    fetchCasesData()

    StaffMenu.builderAFKShop.Separator("GESTION")

    StaffMenu.builderAFKShop.Button("Gérer les caisses", "Modifier ou supprimer des caisses existantes", nil, "chevron", false, function()
    end, StaffMenu.afkShopCaseList)

    StaffMenu.builderAFKShop.Button("Créer une caisse", "Ajouter une nouvelle caisse à la boutique", nil, "chevron", false, function()
        newCase = {}
    end, StaffMenu.afkShopAddCase)

    StaffMenu.builderAFKShop.Separator("POINTS & LOGS")

    StaffMenu.builderAFKShop.Button("Gérer les points AFK", "Voir et ajuster les points des joueurs", nil, "chevron", false, function()
    end, StaffMenu.afkShopPointsList)

    StaffMenu.builderAFKShop.Button("Logs achats caisses", "Historique des caisses ouvertes par les joueurs", nil, "chevron", false, function()
    end, StaffMenu.afkShopLogs)

end)

-- ==========================================
--   POINTS AFK : LISTE JOUEURS
-- ==========================================

local pointsCache = { players = {} }
local selectedPointsPlayer = nil
local pointsSearch = ""

local function fetchPlayersPoints(search)
    local result = TriggerServerCallback('core:afkshop:getPlayersPoints', search or "", 100)
    if result and result.success then
        pointsCache.players = result.players or {}
    else
        pointsCache.players = {}
    end
    return result
end

local function formatAfkTime(seconds)
    seconds = tonumber(seconds) or 0
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then return string.format("%dh %dm", hours, minutes) end
    return string.format("%dm", minutes)
end

StaffMenu.afkShopPointsList.OnOpen(function()
    StaffMenu.afkShopPointsList.ClearItems()

    selectedPointsPlayer = nil
    fetchPlayersPoints(pointsSearch)

    StaffMenu.afkShopPointsList.Separator("RECHERCHE")

    local searchLabel = pointsSearch ~= "" and pointsSearch or "(aucun filtre)"
  StaffMenu.afkShopPointsList.Button("Recherche: " .. searchLabel, "Filtrer par nom ou identifiant", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Recherche (laisser vide pour tout afficher)", pointsSearch)
        if input ~= nil then
            pointsSearch = input
            StaffMenu.afkShopPointsList.refresh()
        end
    end)

    StaffMenu.afkShopPointsList.Separator("JOUEURS (" .. #pointsCache.players .. ")")

    if #pointsCache.players == 0 then
        StaffMenu.afkShopPointsList.Button("Aucun joueur", "Aucun résultat", nil, nil, true, function() end)
        return
    end

    for _, p in ipairs(pointsCache.players) do
        local subtitle = p.points .. " pts | " .. formatAfkTime(p.total_time)
        StaffMenu.afkShopPointsList.Button(
            p.name,
            subtitle,
            nil,
            "chevron",
            false,
            function()
                selectedPointsPlayer = p
            end,
            StaffMenu.afkShopPointsEdit
        )
    end
end)

-- ==========================================
--   POINTS AFK : EDITION JOUEUR
-- ==========================================

StaffMenu.afkShopPointsEdit.OnOpen(function()
    StaffMenu.afkShopPointsEdit.ClearItems()

    if not selectedPointsPlayer then
        StaffMenu.afkShopPointsEdit.Button("Erreur", "Aucun joueur sélectionné", nil, nil, true, function() end)
        return
    end

    StaffMenu.afkShopPointsEdit.Separator(selectedPointsPlayer.name)

    StaffMenu.afkShopPointsEdit.Button("Points actuels: " .. selectedPointsPlayer.points, selectedPointsPlayer.identifier, nil, nil, true, function() end)
    StaffMenu.afkShopPointsEdit.Button("Temps AFK: " .. formatAfkTime(selectedPointsPlayer.total_time), "Cumul total", nil, nil, true, function() end)

    StaffMenu.afkShopPointsEdit.Separator("ACTIONS")

    StaffMenu.afkShopPointsEdit.Button("+ Ajouter des points", "Donner des points à ce joueur", nil, "chevron", false, function()
        if isSaving then return end
        local input = VFW.Nui.KeyboardInput(true, "Nombre de points à ajouter", "")
        local n = tonumber(input)
        if not n or n <= 0 then
            VFW.ShowNotification({ type = 'ROUGE', content = "Cette quantité n'est pas valide" })
            return
        end
        isSaving = true
        local result = TriggerServerCallback('core:afkshop:adjustPoints', selectedPointsPlayer.identifier, math.floor(n))
        isSaving = false
        if result and result.success then
            selectedPointsPlayer.points = result.newPoints
            VFW.ShowNotification({ type = 'VERT', content = "Points ajoutés (nouveau total: " .. result.newPoints .. ")" })
            StaffMenu.afkShopPointsEdit.refresh()
        else
            VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Erreur" })
        end
    end)

    StaffMenu.afkShopPointsEdit.Button("- Retirer des points", "Retirer des points à ce joueur", nil, "chevron", false, function()
        if isSaving then return end
        local input = VFW.Nui.KeyboardInput(true, "Nombre de points à retirer", "")
        local n = tonumber(input)
        if not n or n <= 0 then
            VFW.ShowNotification({ type = 'ROUGE', content = "Cette quantité n'est pas valide" })
            return
        end
        isSaving = true
        local result = TriggerServerCallback('core:afkshop:adjustPoints', selectedPointsPlayer.identifier, -math.floor(n))
        isSaving = false
        if result and result.success then
            selectedPointsPlayer.points = result.newPoints
            VFW.ShowNotification({ type = 'VERT', content = "Points retirés (nouveau total: " .. result.newPoints .. ")" })
            StaffMenu.afkShopPointsEdit.refresh()
        else
            VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Erreur" })
        end
    end)
end)

-- ==========================================
--   LOGS ACHATS CAISSES
-- ==========================================

local logsCache = {}

StaffMenu.afkShopLogs.OnOpen(function()
    StaffMenu.afkShopLogs.ClearItems()

    local result = TriggerServerCallback('core:afkshop:getPurchaseLogs', 100)
    logsCache = (result and result.success and result.logs) or {}

    StaffMenu.afkShopLogs.Separator("DERNIERS ACHATS (" .. #logsCache .. ")")

    if #logsCache == 0 then
        StaffMenu.afkShopLogs.Button("Aucun achat", "L'historique est vide", nil, nil, true, function() end)
        return
    end

    for _, log in ipairs(logsCache) do
        local title = (log.player_name or log.identifier or "?") .. " - " .. (log.case_name or log.case_id or "?")
        local subtitle = (log.created_at or "") .. " | " .. (log.price or 0) .. " pts | Lot: " .. (log.prize_name or "?")
        StaffMenu.afkShopLogs.Button(title, subtitle, nil, nil, true, function() end)
    end
end)

-- ==========================================
--          CASE LIST
-- ==========================================

StaffMenu.afkShopCaseList.OnOpen(function()
    StaffMenu.afkShopCaseList.ClearItems()

    fetchCasesData()

    StaffMenu.afkShopCaseList.Separator("CAISSES")

    if #AFKShopCache.cases == 0 then
        StaffMenu.afkShopCaseList.Button("Aucune caisse", "Créez votre première caisse", nil, nil, true, function() end)
        return
    end

    for _, caseData in ipairs(AFKShopCache.cases) do
        local prizeCount = caseData.prizes and #caseData.prizes or 0
        local statusLabel = caseData.enabled and "Actif" or "Désactivé"
      local subtitle = caseData.price .. " pts | " .. prizeCount .. " lots | " .. statusLabel

        StaffMenu.afkShopCaseList.Button(
            caseData.name,
            subtitle,
            nil,
            "chevron",
            false,
            function()
                selectedCase = caseData
            end,
            StaffMenu.afkShopCaseEdit
        )
    end
end)

-- ==========================================
--          EDIT CASE
-- ==========================================

StaffMenu.afkShopCaseEdit.OnOpen(function()
    StaffMenu.afkShopCaseEdit.ClearItems()

    if not selectedCase then
        StaffMenu.afkShopCaseEdit.Button("Erreur", "Aucune caisse sélectionnée", nil, nil, true, function() end)
        return
    end

    StaffMenu.afkShopCaseEdit.Separator("PROPRIETES")

    -- Nom
    StaffMenu.afkShopCaseEdit.Button("Nom: " .. (selectedCase.name or "N/A"), "Cliquez pour modifier", nil, "chevron", false, function()
        local newName = VFW.Nui.KeyboardInput(true, "Nom de la caisse", selectedCase.name or "")
        if newName and string.len(string.gsub(newName, "%s+", "")) > 0 then
            selectedCase.name = newName
            StaffMenu.afkShopCaseEdit.refresh()
        end
    end)

    -- Description
    local descDisplay = selectedCase.description and string.len(selectedCase.description) > 0 and selectedCase.description or "Non définie"
  StaffMenu.afkShopCaseEdit.Button("Description: " .. descDisplay, "Cliquez pour modifier", nil, "chevron", false, function()
        local newDesc = VFW.Nui.KeyboardInput(true, "Description", selectedCase.description or "")
        if newDesc then
            selectedCase.description = newDesc
            StaffMenu.afkShopCaseEdit.refresh()
        end
    end)

    -- Prix
    StaffMenu.afkShopCaseEdit.Button("Prix: " .. (selectedCase.price or 0) .. " pts", "Cliquez pour modifier", nil, "chevron", false, function()
        local newPrice = VFW.Nui.KeyboardInput(true, "Prix en points AFK", tostring(selectedCase.price or 0))
        if newPrice and tonumber(newPrice) then
            local priceNum = tonumber(newPrice)
            if priceNum < 0 then
                VFW.ShowNotification({ type = 'ROUGE', content = "Le prix doit être positif" })
                return
            end
            selectedCase.price = priceNum
            StaffMenu.afkShopCaseEdit.refresh()
        end
    end)

    -- Image URL
    local imageDisplay = selectedCase.image and string.len(selectedCase.image) > 0 and "Définie" or "Non définie"
  StaffMenu.afkShopCaseEdit.Button("Image URL: " .. imageDisplay, "Cliquez pour modifier", nil, "chevron", false, function()
        local newImage = VFW.Nui.KeyboardInput(true, "URL de l'image", selectedCase.image or "")
        if newImage then
            selectedCase.image = newImage
            StaffMenu.afkShopCaseEdit.refresh()
        end
    end)

    -- Etat (enabled toggle)
    local enabledOptions = { "Actif", "Désactivé" }
    local enabledIndex = selectedCase.enabled and 1 or 2
    StaffMenu.afkShopCaseEdit.List(
        "Etat",
        "Fleches gauche/droite pour changer",
        false,
        enabledOptions,
        enabledIndex,
        function(index)
            selectedCase.enabled = (index == 1)
        end
    )

    StaffMenu.afkShopCaseEdit.Separator("CONTENU")

    -- Prizes
    local prizeCount = selectedCase.prizes and #selectedCase.prizes or 0
    StaffMenu.afkShopCaseEdit.Button("Lots (" .. prizeCount .. " configures)", "Gerer les lots de cette caisse", nil, "chevron", false, function()
    end, StaffMenu.afkShopCasePrizes)

    StaffMenu.afkShopCaseEdit.Separator("ACTIONS")

    -- Sauvegarder
    StaffMenu.afkShopCaseEdit.Button("SAUVEGARDER", "Enregistrer les modifications", nil, "check", false, function()
        if isSaving then return end
        isSaving = true
        local result = TriggerServerCallback('core:afkshop:editCase', {
            id = selectedCase.id,
            name = selectedCase.name,
            description = selectedCase.description,
            price = selectedCase.price,
            itemName = selectedCase.itemName,
            image = selectedCase.image,
            enabled = selectedCase.enabled,
            sortOrder = selectedCase.sortOrder,
        })
        isSaving = false
        if result and result.success then
            VFW.ShowNotification({ type = 'VERT', content = "Caisse modifiée" })
            fetchCasesData()
        else
            VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Erreur lors de la modification" })
        end
    end)

    -- Supprimer
    StaffMenu.afkShopCaseEdit.Button("SUPPRIMER", "Supprimer cette caisse", nil, "trash", false, function()
        if isSaving then return end
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer la suppression")
        if confirm and string.upper(confirm) == "OUI" then
            isSaving = true
            local result = TriggerServerCallback('core:afkshop:deleteCase', selectedCase.id)
            isSaving = false
            if result and result.success then
                VFW.ShowNotification({ type = 'VERT', content = "Caisse supprimée" })
                selectedCase = nil
                fetchCasesData()
                StaffMenu.afkShopCaseList.open()
            else
                VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Erreur lors de la suppression" })
            end
        end
    end)
end)

-- ==========================================
--          CASE PRIZES LIST
-- ==========================================

StaffMenu.afkShopCasePrizes.OnOpen(function()
    StaffMenu.afkShopCasePrizes.ClearItems()

    if not selectedCase then
        StaffMenu.afkShopCasePrizes.Button("Erreur", "Aucune caisse sélectionnée", nil, nil, true, function() end)
        return
    end

    StaffMenu.afkShopCasePrizes.Separator("LOTS - " .. selectedCase.name)

    local prizes = selectedCase.prizes or {}

    if #prizes == 0 then
        StaffMenu.afkShopCasePrizes.Button("Aucun lot", "Ajoutez des lots à cette caisse", nil, nil, true, function() end)
    else
        for _, prize in ipairs(prizes) do
            local tLabel = typeLabels[prize.type] or prize.type
            local rLabel = rarityLabels[prize.rarity] or ("Rarete " .. (prize.rarity or "?"))
            local subtitle = tLabel .. " | " .. rLabel .. " | Chance: " .. (prize.chance or 0)

            StaffMenu.afkShopCasePrizes.Button(
                prize.name,
                subtitle,
                nil,
                "chevron",
                false,
                function()
                    selectedPrize = prize
                end,
                StaffMenu.afkShopEditPrize
            )
        end
    end

    StaffMenu.afkShopCasePrizes.Separator("ACTIONS")

    StaffMenu.afkShopCasePrizes.Button("+ Ajouter un lot", "Créer un nouveau lot", nil, "chevron", false, function()
        newPrize = { type = "money", rarity = 1, chance = 10, count = 1, amount = 0 }
    end, StaffMenu.afkShopAddPrize)
end)

-- ==========================================
--          ADD PRIZE
-- ==========================================

StaffMenu.afkShopAddPrize.OnOpen(function()
    StaffMenu.afkShopAddPrize.ClearItems()

    if not selectedCase then
        StaffMenu.afkShopAddPrize.Button("Erreur", "Aucune caisse sélectionnée", nil, nil, true, function() end)
        return
    end

    -- Initialize newPrize if empty
    if not newPrize.type then
        newPrize = { type = "money", rarity = 1, chance = 10, count = 1, amount = 0 }
    end

    StaffMenu.afkShopAddPrize.Separator("NOUVEAU LOT")

    -- Type selection
    local typeDisplayOptions = {}
    for _, t in ipairs(typeOptions) do
        table.insert(typeDisplayOptions, typeLabels[t])
    end
    local currentTypeIndex = 1
    for i, t in ipairs(typeOptions) do
        if t == newPrize.type then
            currentTypeIndex = i
            break
        end
    end
    StaffMenu.afkShopAddPrize.List(
        "Type",
        "Fleches gauche/droite pour changer",
        false,
        typeDisplayOptions,
        currentTypeIndex,
        function(index)
            newPrize.type = typeOptions[index]
            StaffMenu.afkShopAddPrize.refresh()
        end
    )

    -- Nom
    StaffMenu.afkShopAddPrize.Button("Nom: " .. (newPrize.name or "Non défini"), "Cliquez pour définir", nil, "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom du lot", newPrize.name or "")
        if name and string.len(string.gsub(name, "%s+", "")) > 0 then
            newPrize.name = name
            StaffMenu.afkShopAddPrize.refresh()
        end
    end)

    -- Fields based on type
    if newPrize.type == "money" then
        StaffMenu.afkShopAddPrize.Button("Montant: " .. VFW.Math.FormatMoney(newPrize.amount or 0), "Cliquez pour définir", nil, "chevron", false, function()
            local amount = VFW.Nui.KeyboardInput(true, "Montant d'argent", tostring(newPrize.amount or 0))
            if amount and tonumber(amount) then
                newPrize.amount = tonumber(amount)
                StaffMenu.afkShopAddPrize.refresh()
            end
        end)
    elseif newPrize.type == "item" then
        StaffMenu.afkShopAddPrize.Button("Item name: " .. (newPrize.itemName or "Non défini"), "Spawn name de l'item", nil, "chevron", false, function()
            local itemName = VFW.Nui.KeyboardInput(true, "Spawn name de l'item", newPrize.itemName or "")
            if itemName and string.len(string.gsub(itemName, "%s+", "")) > 0 then
                newPrize.itemName = itemName
                StaffMenu.afkShopAddPrize.refresh()
            end
        end)
        StaffMenu.afkShopAddPrize.Button("Quantité: " .. (newPrize.count or 1), "Cliquez pour définir", nil, "chevron", false, function()
            local count = VFW.Nui.KeyboardInput(true, "Quantité", tostring(newPrize.count or 1))
            if count and tonumber(count) then
                newPrize.count = tonumber(count)
                StaffMenu.afkShopAddPrize.refresh()
            end
        end)
    elseif newPrize.type == "weapon" then
        StaffMenu.afkShopAddPrize.Button("Arme: " .. (newPrize.itemName or "Non défini"), "Spawn name de l'arme", nil, "chevron", false, function()
            local itemName = VFW.Nui.KeyboardInput(true, "Spawn name de l'arme (ex: weapon_pistol)", newPrize.itemName or "")
            if itemName and string.len(string.gsub(itemName, "%s+", "")) > 0 then
                newPrize.itemName = itemName
                StaffMenu.afkShopAddPrize.refresh()
            end
        end)
    elseif newPrize.type == "vehicle" then
        StaffMenu.afkShopAddPrize.Button("Modèle: " .. (newPrize.vehicleModel or "Non défini"), "Modèle du véhicule", nil, "chevron", false, function()
            local model = VFW.Nui.KeyboardInput(true, "Modele du vehicule (ex: elegy2)", newPrize.vehicleModel or "")
            if model and string.len(string.gsub(model, "%s+", "")) > 0 then
                newPrize.vehicleModel = model
                StaffMenu.afkShopAddPrize.refresh()
            end
        end)
    elseif newPrize.type == "case" then
        StaffMenu.afkShopAddPrize.Button("Item caisse: " .. (newPrize.itemName or "Non défini"), "Spawn name de la caisse", nil, "chevron", false, function()
            local itemName = VFW.Nui.KeyboardInput(true, "Spawn name de la caisse", newPrize.itemName or "")
            if itemName and string.len(string.gsub(itemName, "%s+", "")) > 0 then
                newPrize.itemName = itemName
                StaffMenu.afkShopAddPrize.refresh()
            end
        end)
    end

    -- Rarity
    local currentRarityIndex = newPrize.rarity or 1
    StaffMenu.afkShopAddPrize.List(
        "Rareté",
        "Fleches gauche/droite pour changer",
        false,
        rarityLabels,
        currentRarityIndex,
        function(index)
            newPrize.rarity = index
        end
    )

    -- Chance
    StaffMenu.afkShopAddPrize.Button("Chance (poids): " .. (newPrize.chance or 10), "Poids pour le tirage aleatoire", nil, "chevron", false, function()
        local chance = VFW.Nui.KeyboardInput(true, "Poids de chance (ex: 10)", tostring(newPrize.chance or 10))
        if chance and tonumber(chance) then
            local chanceNum = tonumber(chance)
            if chanceNum <= 0 then
                VFW.ShowNotification({ type = 'ROUGE', content = "La chance doit être supérieure à 0" })
                return
            end
            newPrize.chance = chanceNum
            StaffMenu.afkShopAddPrize.refresh()
        end
    end)

    StaffMenu.afkShopAddPrize.Separator("")

    -- Validation
    local canCreate = newPrize.name and string.len(string.gsub(newPrize.name or "", "%s+", "")) > 0
    local statusText = canCreate and "Prêt à créer" or "Nom manquant"

  StaffMenu.afkShopAddPrize.Button("CREER LE LOT", statusText, nil, "check", not canCreate, function()
        if not canCreate then return end
        if isSaving then return end
        isSaving = true

        local result = TriggerServerCallback('core:afkshop:addPrize', selectedCase.id, {
            type = newPrize.type,
            name = newPrize.name,
            amount = newPrize.amount or 0,
            itemName = newPrize.itemName or '',
            vehicleModel = newPrize.vehicleModel or '',
            count = newPrize.count or 1,
            rarity = newPrize.rarity or 1,
            chance = newPrize.chance or 10,
        })
        isSaving = false

        if result and result.success then
            VFW.ShowNotification({ type = 'VERT', content = "Lot créé" })
            -- Refresh case data
            local refreshResult = fetchCasesData()
            if refreshResult and refreshResult.success then
                for _, c in ipairs(AFKShopCache.cases) do
                    if c.id == selectedCase.id then
                        selectedCase = c
                        break
                    end
                end
            end
            newPrize = { type = "money", rarity = 1, chance = 10, count = 1, amount = 0 }
            StaffMenu.afkShopAddPrize.refresh()
        else
            VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Erreur lors de la creation" })
        end
    end)
end)

-- ==========================================
--          EDIT PRIZE
-- ==========================================

StaffMenu.afkShopEditPrize.OnOpen(function()
    StaffMenu.afkShopEditPrize.ClearItems()

    if not selectedPrize then
        StaffMenu.afkShopEditPrize.Button("Erreur", "Aucun lot sélectionné", nil, nil, true, function() end)
        return
    end

    StaffMenu.afkShopEditPrize.Separator("LOT: " .. (selectedPrize.name or "?"))

    -- Type selection
    local typeDisplayOptions = {}
    for _, t in ipairs(typeOptions) do
        table.insert(typeDisplayOptions, typeLabels[t])
    end
    local currentTypeIndex = 1
    for i, t in ipairs(typeOptions) do
        if t == selectedPrize.type then
            currentTypeIndex = i
            break
        end
    end
    StaffMenu.afkShopEditPrize.List(
        "Type",
        "Fleches gauche/droite pour changer",
        false,
        typeDisplayOptions,
        currentTypeIndex,
        function(index)
            selectedPrize.type = typeOptions[index]
            StaffMenu.afkShopEditPrize.refresh()
        end
    )

    -- Nom
    StaffMenu.afkShopEditPrize.Button("Nom: " .. (selectedPrize.name or "N/A"), "Cliquez pour modifier", nil, "chevron", false, function()
        local newName = VFW.Nui.KeyboardInput(true, "Nom du lot", selectedPrize.name or "")
        if newName and string.len(string.gsub(newName, "%s+", "")) > 0 then
            selectedPrize.name = newName
            StaffMenu.afkShopEditPrize.refresh()
        end
    end)

    -- Fields based on type
    if selectedPrize.type == "money" then
        StaffMenu.afkShopEditPrize.Button("Montant: " .. VFW.Math.FormatMoney(selectedPrize.amount or 0), "Cliquez pour modifier", nil, "chevron", false, function()
            local amount = VFW.Nui.KeyboardInput(true, "Montant d'argent", tostring(selectedPrize.amount or 0))
            if amount and tonumber(amount) then
                selectedPrize.amount = tonumber(amount)
                StaffMenu.afkShopEditPrize.refresh()
            end
        end)
    elseif selectedPrize.type == "item" then
        StaffMenu.afkShopEditPrize.Button("Item name: " .. (selectedPrize.itemName or "N/A"), "Spawn name de l'item", nil, "chevron", false, function()
            local itemName = VFW.Nui.KeyboardInput(true, "Spawn name de l'item", selectedPrize.itemName or "")
            if itemName and string.len(string.gsub(itemName, "%s+", "")) > 0 then
                selectedPrize.itemName = itemName
                StaffMenu.afkShopEditPrize.refresh()
            end
        end)
        StaffMenu.afkShopEditPrize.Button("Quantité: " .. (selectedPrize.count or 1), "Cliquez pour modifier", nil, "chevron", false, function()
            local count = VFW.Nui.KeyboardInput(true, "Quantité", tostring(selectedPrize.count or 1))
            if count and tonumber(count) then
                selectedPrize.count = tonumber(count)
                StaffMenu.afkShopEditPrize.refresh()
            end
        end)
    elseif selectedPrize.type == "weapon" then
        StaffMenu.afkShopEditPrize.Button("Arme: " .. (selectedPrize.itemName or "N/A"), "Spawn name de l'arme", nil, "chevron", false, function()
            local itemName = VFW.Nui.KeyboardInput(true, "Spawn name de l'arme", selectedPrize.itemName or "")
            if itemName and string.len(string.gsub(itemName, "%s+", "")) > 0 then
                selectedPrize.itemName = itemName
                StaffMenu.afkShopEditPrize.refresh()
            end
        end)
    elseif selectedPrize.type == "vehicle" then
        StaffMenu.afkShopEditPrize.Button("Modèle: " .. (selectedPrize.vehicleModel or "N/A"), "Modèle du véhicule", nil, "chevron", false, function()
            local model = VFW.Nui.KeyboardInput(true, "Modèle du véhicule", selectedPrize.vehicleModel or "")
            if model and string.len(string.gsub(model, "%s+", "")) > 0 then
                selectedPrize.vehicleModel = model
                StaffMenu.afkShopEditPrize.refresh()
            end
        end)
    elseif selectedPrize.type == "case" then
        StaffMenu.afkShopEditPrize.Button("Item caisse: " .. (selectedPrize.itemName or "N/A"), "Spawn name de la caisse", nil, "chevron", false, function()
            local itemName = VFW.Nui.KeyboardInput(true, "Spawn name de la caisse", selectedPrize.itemName or "")
            if itemName and string.len(string.gsub(itemName, "%s+", "")) > 0 then
                selectedPrize.itemName = itemName
                StaffMenu.afkShopEditPrize.refresh()
            end
        end)
    end

    -- Rarity
    local currentRarityIndex = selectedPrize.rarity or 1
    StaffMenu.afkShopEditPrize.List(
        "Rareté",
        "Fleches gauche/droite pour changer",
        false,
        rarityLabels,
        currentRarityIndex,
        function(index)
            selectedPrize.rarity = index
        end
    )

    -- Chance
    StaffMenu.afkShopEditPrize.Button("Chance (poids): " .. (selectedPrize.chance or 10), "Poids pour le tirage aleatoire", nil, "chevron", false, function()
        local chance = VFW.Nui.KeyboardInput(true, "Poids de chance (ex: 10)", tostring(selectedPrize.chance or 10))
        if chance and tonumber(chance) then
            local chanceNum = tonumber(chance)
            if chanceNum <= 0 then
                VFW.ShowNotification({ type = 'ROUGE', content = "La chance doit être supérieure à 0" })
                return
            end
            selectedPrize.chance = chanceNum
            StaffMenu.afkShopEditPrize.refresh()
        end
    end)

    StaffMenu.afkShopEditPrize.Separator("ACTIONS")

    -- Sauvegarder
    StaffMenu.afkShopEditPrize.Button("SAUVEGARDER", "Enregistrer les modifications", nil, "check", false, function()
        if isSaving then return end
        if not selectedPrize.id then
            VFW.ShowNotification({ type = 'ROUGE', content = "ID du lot introuvable" })
            return
        end
        isSaving = true
        local result = TriggerServerCallback('core:afkshop:editPrize', selectedPrize.id, {
            type = selectedPrize.type,
            name = selectedPrize.name,
            amount = selectedPrize.amount or 0,
            itemName = selectedPrize.itemName or '',
            vehicleModel = selectedPrize.vehicleModel or '',
            count = selectedPrize.count or 1,
            rarity = selectedPrize.rarity or 1,
            chance = selectedPrize.chance or 10,
        })
        isSaving = false
        if result and result.success then
            VFW.ShowNotification({ type = 'VERT', content = "Lot modifié" })
            -- Refresh case data
            local refreshResult = fetchCasesData()
            if refreshResult and refreshResult.success then
                for _, c in ipairs(AFKShopCache.cases) do
                    if c.id == selectedCase.id then
                        selectedCase = c
                        break
                    end
                end
            end
        else
            VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Erreur lors de la modification" })
        end
    end)

    -- Supprimer
    StaffMenu.afkShopEditPrize.Button("SUPPRIMER", "Supprimer ce lot", nil, "trash", false, function()
        if isSaving then return end
        if not selectedPrize.id then
            VFW.ShowNotification({ type = 'ROUGE', content = "ID du lot introuvable" })
            return
        end
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer la suppression")
        if confirm and string.upper(confirm) == "OUI" then
            isSaving = true
            local result = TriggerServerCallback('core:afkshop:deletePrize', selectedPrize.id)
            isSaving = false
            if result and result.success then
                VFW.ShowNotification({ type = 'VERT', content = "Lot supprimé" })
                -- Refresh case data
                local refreshResult = fetchCasesData()
                if refreshResult and refreshResult.success then
                    for _, c in ipairs(AFKShopCache.cases) do
                        if c.id == selectedCase.id then
                            selectedCase = c
                            break
                        end
                    end
                end
                selectedPrize = nil
                StaffMenu.afkShopCasePrizes.open()
            else
                VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Erreur lors de la suppression" })
            end
        end
    end)
end)

-- ==========================================
--    CREATE CASE: PRIZES LIST SUB-MENU
-- ==========================================

StaffMenu.afkShopAddCasePrizes.OnOpen(function()
    StaffMenu.afkShopAddCasePrizes.ClearItems()

    if not newCase.prizes then newCase.prizes = {} end
    local prizes = newCase.prizes

    StaffMenu.afkShopAddCasePrizes.Separator("LOTS (" .. #prizes .. ")")

    if #prizes == 0 then
        StaffMenu.afkShopAddCasePrizes.Button("Aucun lot", "Ajoutez des lots à cette caisse", nil, nil, true, function() end)
    else
        for i, prize in ipairs(prizes) do
            local tLabel = typeLabels[prize.type] or prize.type
            local rLabel = rarityLabels[prize.rarity] or ("Rarete " .. (prize.rarity or "?"))
            local subtitle = tLabel .. " | " .. rLabel .. " | Chance: " .. (prize.chance or 0)

            StaffMenu.afkShopAddCasePrizes.Button(
                prize.name or "Lot " .. i,
                subtitle,
                nil,
                "trash",
                false,
                function()
                    table.remove(prizes, i)
                    VFW.ShowNotification({ type = 'VERT', content = "Lot retiré" })
                    StaffMenu.afkShopAddCasePrizes.refresh()
                end
            )
        end
    end

    StaffMenu.afkShopAddCasePrizes.Separator("ACTIONS")

    StaffMenu.afkShopAddCasePrizes.Button("+ Ajouter un lot", "Créer un nouveau lot", nil, "chevron", false, function()
        newPrize = { type = "money", rarity = 1, chance = 10, count = 1, amount = 0 }
    end, StaffMenu.afkShopAddCaseAddPrize)
end)

-- ==========================================
--    CREATE CASE: ADD PRIZE SUB-MENU
-- ==========================================

StaffMenu.afkShopAddCaseAddPrize.OnOpen(function()
    StaffMenu.afkShopAddCaseAddPrize.ClearItems()

    if not newPrize.type then
        newPrize = { type = "money", rarity = 1, chance = 10, count = 1, amount = 0 }
    end

    StaffMenu.afkShopAddCaseAddPrize.Separator("NOUVEAU LOT")

    -- Type selection
    local typeDisplayOptions = {}
    for _, t in ipairs(typeOptions) do
        table.insert(typeDisplayOptions, typeLabels[t])
    end
    local currentTypeIndex = 1
    for i, t in ipairs(typeOptions) do
        if t == newPrize.type then
            currentTypeIndex = i
            break
        end
    end
    StaffMenu.afkShopAddCaseAddPrize.List(
        "Type",
        "Fleches gauche/droite pour changer",
        false,
        typeDisplayOptions,
        currentTypeIndex,
        function(index)
            newPrize.type = typeOptions[index]
            StaffMenu.afkShopAddCaseAddPrize.refresh()
        end
    )

    -- Nom
    StaffMenu.afkShopAddCaseAddPrize.Button("Nom: " .. (newPrize.name or "Non défini"), "Cliquez pour définir", nil, "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom du lot", newPrize.name or "")
        if name and string.len(string.gsub(name, "%s+", "")) > 0 then
            newPrize.name = name
            StaffMenu.afkShopAddCaseAddPrize.refresh()
        end
    end)

    -- Fields based on type
    if newPrize.type == "money" then
        StaffMenu.afkShopAddCaseAddPrize.Button("Montant: " .. VFW.Math.FormatMoney(newPrize.amount or 0), "Cliquez pour définir", nil, "chevron", false, function()
            local amount = VFW.Nui.KeyboardInput(true, "Montant d'argent", tostring(newPrize.amount or 0))
            if amount and tonumber(amount) then
                newPrize.amount = tonumber(amount)
                StaffMenu.afkShopAddCaseAddPrize.refresh()
            end
        end)
    elseif newPrize.type == "item" then
        StaffMenu.afkShopAddCaseAddPrize.Button("Item name: " .. (newPrize.itemName or "Non défini"), "Spawn name de l'item", nil, "chevron", false, function()
            local itemName = VFW.Nui.KeyboardInput(true, "Spawn name de l'item", newPrize.itemName or "")
            if itemName and string.len(string.gsub(itemName, "%s+", "")) > 0 then
                newPrize.itemName = itemName
                StaffMenu.afkShopAddCaseAddPrize.refresh()
            end
        end)
        StaffMenu.afkShopAddCaseAddPrize.Button("Quantité: " .. (newPrize.count or 1), "Cliquez pour définir", nil, "chevron", false, function()
            local count = VFW.Nui.KeyboardInput(true, "Quantité", tostring(newPrize.count or 1))
            if count and tonumber(count) then
                newPrize.count = tonumber(count)
                StaffMenu.afkShopAddCaseAddPrize.refresh()
            end
        end)
    elseif newPrize.type == "weapon" then
        StaffMenu.afkShopAddCaseAddPrize.Button("Arme: " .. (newPrize.itemName or "Non défini"), "Spawn name de l'arme", nil, "chevron", false, function()
            local itemName = VFW.Nui.KeyboardInput(true, "Spawn name de l'arme (ex: weapon_pistol)", newPrize.itemName or "")
            if itemName and string.len(string.gsub(itemName, "%s+", "")) > 0 then
                newPrize.itemName = itemName
                StaffMenu.afkShopAddCaseAddPrize.refresh()
            end
        end)
    elseif newPrize.type == "vehicle" then
        StaffMenu.afkShopAddCaseAddPrize.Button("Modèle: " .. (newPrize.vehicleModel or "Non défini"), "Modèle du véhicule", nil, "chevron", false, function()
            local model = VFW.Nui.KeyboardInput(true, "Modele du vehicule (ex: elegy2)", newPrize.vehicleModel or "")
            if model and string.len(string.gsub(model, "%s+", "")) > 0 then
                newPrize.vehicleModel = model
                StaffMenu.afkShopAddCaseAddPrize.refresh()
            end
        end)
    elseif newPrize.type == "case" then
        StaffMenu.afkShopAddCaseAddPrize.Button("Item caisse: " .. (newPrize.itemName or "Non défini"), "Spawn name de la caisse", nil, "chevron", false, function()
            local itemName = VFW.Nui.KeyboardInput(true, "Spawn name de la caisse", newPrize.itemName or "")
            if itemName and string.len(string.gsub(itemName, "%s+", "")) > 0 then
                newPrize.itemName = itemName
                StaffMenu.afkShopAddCaseAddPrize.refresh()
            end
        end)
    end

    -- Rarity
    local currentRarityIndex = newPrize.rarity or 1
    StaffMenu.afkShopAddCaseAddPrize.List(
        "Rareté",
        "Fleches gauche/droite pour changer",
        false,
        rarityLabels,
        currentRarityIndex,
        function(index)
            newPrize.rarity = index
        end
    )

    -- Chance
    StaffMenu.afkShopAddCaseAddPrize.Button("Chance (poids): " .. (newPrize.chance or 10), "Poids pour le tirage aleatoire", nil, "chevron", false, function()
        local chance = VFW.Nui.KeyboardInput(true, "Poids de chance (ex: 10)", tostring(newPrize.chance or 10))
        if chance and tonumber(chance) then
            local chanceNum = tonumber(chance)
            if chanceNum <= 0 then
                VFW.ShowNotification({ type = 'ROUGE', content = "La chance doit être supérieure à 0" })
                return
            end
            newPrize.chance = chanceNum
            StaffMenu.afkShopAddCaseAddPrize.refresh()
        end
    end)

    StaffMenu.afkShopAddCaseAddPrize.Separator("VALIDER")

    StaffMenu.afkShopAddCaseAddPrize.Button("AJOUTER LE LOT", "Cliquez pour ajouter", nil, "check", false, function()
        if not newPrize.name or string.len(string.gsub(newPrize.name or "", "%s+", "")) == 0 then
            VFW.ShowNotification({ type = 'ROUGE', content = "Veuillez définir le nom du lot" })
            return
        end

        -- Add to local prizes list
        if not newCase.prizes then newCase.prizes = {} end
        table.insert(newCase.prizes, {
            type = newPrize.type,
            name = newPrize.name,
            amount = newPrize.amount or 0,
            itemName = newPrize.itemName or '',
            vehicleModel = newPrize.vehicleModel or '',
            count = newPrize.count or 1,
            rarity = newPrize.rarity or 1,
            chance = newPrize.chance or 10,
        })

        VFW.ShowNotification({ type = 'VERT', content = "Lot ajouté: " .. newPrize.name })
        newPrize = { type = "money", rarity = 1, chance = 10, count = 1, amount = 0 }
        StaffMenu.afkShopAddCasePrizes.open()
    end)
end)

-- ==========================================
--          CREATE CASE
-- ==========================================

StaffMenu.afkShopAddCase.OnOpen(function()
    StaffMenu.afkShopAddCase.ClearItems()

    StaffMenu.afkShopAddCase.Separator("NOUVELLE CAISSE")

    -- Identifiant
    StaffMenu.afkShopAddCase.Button("Identifiant: " .. (newCase.id or "Non défini"), "Slug unique (ex: diamond)", nil, "chevron", false, function()
        local id = VFW.Nui.KeyboardInput(true, "Identifiant unique (slug, ex: diamond)", newCase.id or "")
        if id and string.len(string.gsub(id, "%s+", "")) > 0 then
            -- Sanitize: lowercase, no spaces
            id = string.lower(string.gsub(id, "%s+", "_"))
            newCase.id = id
            StaffMenu.afkShopAddCase.refresh()
        end
    end)

    -- Nom
    StaffMenu.afkShopAddCase.Button("Nom: " .. (newCase.name or "Non défini"), "Nom affiche de la caisse", nil, "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom de la caisse", newCase.name or "")
        if name and string.len(string.gsub(name, "%s+", "")) > 0 then
            newCase.name = name
            StaffMenu.afkShopAddCase.refresh()
        end
    end)

    -- Description
    local descDisplay = newCase.description and string.len(newCase.description) > 0 and newCase.description or "Non définie"
  StaffMenu.afkShopAddCase.Button("Description: " .. descDisplay, "Cliquez pour définir", nil, "chevron", false, function()
        local desc = VFW.Nui.KeyboardInput(true, "Description", newCase.description or "")
        if desc then
            newCase.description = desc
            StaffMenu.afkShopAddCase.refresh()
        end
    end)

    -- Prix
    StaffMenu.afkShopAddCase.Button("Prix: " .. (newCase.price and (newCase.price .. " pts") or "Non défini"), "Cliquez pour définir", nil, "chevron", false, function()
        local price = VFW.Nui.KeyboardInput(true, "Prix en points AFK", newCase.price and tostring(newCase.price) or "")
        if price and tonumber(price) then
            local priceNum = tonumber(price)
            if priceNum < 0 then
                VFW.ShowNotification({ type = 'ROUGE', content = "Le prix doit être positif" })
                return
            end
            newCase.price = priceNum
            StaffMenu.afkShopAddCase.refresh()
        end
    end)

    -- Image URL
    local imageDisplay = newCase.image and string.len(newCase.image) > 0 and "Définie" or "Non définie"
  StaffMenu.afkShopAddCase.Button("Image URL: " .. imageDisplay, "Cliquez pour définir", nil, "chevron", false, function()
        local image = VFW.Nui.KeyboardInput(true, "URL de l'image", newCase.image or "")
        if image then
            newCase.image = image
            StaffMenu.afkShopAddCase.refresh()
        end
    end)

    -- Lots section
    if not newCase.prizes then newCase.prizes = {} end
    local prizeCount = #newCase.prizes
    StaffMenu.afkShopAddCase.Separator("CONTENU")

    StaffMenu.afkShopAddCase.Button("Lots (" .. prizeCount .. " configures)", "Gerer les lots de cette caisse", nil, "chevron", false, function()
    end, StaffMenu.afkShopAddCasePrizes)

    StaffMenu.afkShopAddCase.Separator("VALIDER")

    StaffMenu.afkShopAddCase.Button("CRÉER LA CAISSE", "Cliquez pour créer", nil, "check", false, function()
        -- Validate required fields
        if not newCase.id or string.len(string.gsub(newCase.id or "", "%s+", "")) == 0 then
            VFW.ShowNotification({ type = 'ROUGE', content = "Veuillez définir l'identifiant" })
            return
        end
        if not newCase.name or string.len(string.gsub(newCase.name or "", "%s+", "")) == 0 then
            VFW.ShowNotification({ type = 'ROUGE', content = "Veuillez définir le nom" })
            return
        end
        if not newCase.price or newCase.price < 0 then
            VFW.ShowNotification({ type = 'ROUGE', content = "Veuillez définir un prix valide" })
            return
        end

        if isSaving then return end
        isSaving = true

        local result = TriggerServerCallback('core:afkshop:createCase', {
            id = newCase.id,
            name = newCase.name,
            description = newCase.description or '',
            price = newCase.price,
            itemName = newCase.itemName or '',
            image = newCase.image or '',
            sortOrder = 0,
        })

        if not result or not result.success then
            isSaving = false
            VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Erreur lors de la creation" })
            return
        end

        -- Add prizes if any were configured
        local prizesAdded = 0
        if newCase.prizes and #newCase.prizes > 0 then
            -- Find the created case ID from the refreshed data
            local refreshResult = fetchCasesData()
            local createdCaseDbId = nil
            if refreshResult and refreshResult.success then
                for _, c in ipairs(AFKShopCache.cases) do
                    if c.id == newCase.id then
                        createdCaseDbId = c.id
                        break
                    end
                end
            end

            if createdCaseDbId then
                for _, prize in ipairs(newCase.prizes) do
                    local prizeResult = TriggerServerCallback('core:afkshop:addPrize', createdCaseDbId, {
                        type = prize.type,
                        name = prize.name,
                        amount = prize.amount or 0,
                        itemName = prize.itemName or '',
                        vehicleModel = prize.vehicleModel or '',
                        count = prize.count or 1,
                        rarity = prize.rarity or 1,
                        chance = prize.chance or 10,
                    })
                    if prizeResult and prizeResult.success then
                        prizesAdded = prizesAdded + 1
                    end
                end
            end
        end

        isSaving = false

        local msg = "Caisse créée"
      if prizesAdded > 0 then
            msg = msg .. " (" .. prizesAdded .. " lots ajoutés)"
      end
        VFW.ShowNotification({ type = 'VERT', content = msg })
        newCase = {}
        fetchCasesData()
        StaffMenu.afkShopAddCase.refresh()
    end)
end)
