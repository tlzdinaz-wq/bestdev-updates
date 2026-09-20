-- ==========================================
--   BUILDER VIP - Gestion des vehicules du mois
-- ==========================================

local VIPVehicleCache = { vehicles = {} }
local selectedVehicle = nil
local newVehicle = {}

local tierLabels = {
    [1] = "Bronze",
    [2] = "Silver",
    [3] = "Gold"
}

-- Fetch vehicles from server
local function fetchVehiclesData()
    local result = TriggerServerCallback("vip:admin:getMonthlyVehicles")
    if result and result.success then
        VIPVehicleCache.vehicles = result.vehicles or {}
    end
    return result
end

-- Get vehicle count for a tier
local function getVehicleCountForTier(tier)
    local count = 0
    for _, v in ipairs(VIPVehicleCache.vehicles) do
        if tonumber(v.vip_tier) == tier then
            count = count + 1
        end
    end
    return count
end

-- ==========================================
--         MAIN VIP MENU
-- ==========================================

local vipPlayerData = nil
local selectedAddTier = 1

StaffMenu.builderVIP.OnOpen(function()
    StaffMenu.builderVIP.ClearItems()

    selectedVehicle = nil
    newVehicle = {}
    vipPlayerData = nil
    selectedAddTier = 1

    fetchVehiclesData()

    StaffMenu.builderVIP.Separator("VEHICULES DU MOIS")

    StaffMenu.builderVIP.Button("Vehicules du mois", "Gerer les vehicules mensuels par tier VIP", nil, "chevron", false, function()
    end, StaffMenu.vipMonthlyVehicles)

    StaffMenu.builderVIP.Separator("CONFIGURATION VIP")

    StaffMenu.builderVIP.Button("Valeurs VIP par tier", "Modifier coins, poids, aide, réductions, objets, gain", nil, "chevron", false, function()
    end, StaffMenu.vipAdvantages)

    StaffMenu.builderVIP.Separator("GESTION JOUEURS VIP")

    StaffMenu.builderVIP.Button("Ajouter un VIP", "Attribuer le VIP a un joueur par ID serveur", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "ID serveur du joueur")
        if input and input ~= "" then
            local serverId = tonumber(input)
            if not serverId then
                VFW.ShowNotification({ type = "ROUGE", content = "Cet ID serveur n'est pas valide" })
                return
            end
            local result = TriggerServerCallback("vip:admin:getPlayerVIPStatus", serverId)
            if result and result.success then
                vipPlayerData = result
            else
                VFW.ShowNotification({ type = "ROUGE", content = result and result.message or "Joueur introuvable" })
                vipPlayerData = nil
            end
        end
    end, StaffMenu.vipPlayerAdd)

    StaffMenu.builderVIP.Button("Liste des joueurs VIP", "Voir / modifier / retirer les VIP en ligne", nil, "chevron", false, function()
    end, StaffMenu.vipPlayerList)
end)

-- ==========================================
--      MONTHLY VEHICLES - TIER LIST
-- ==========================================

StaffMenu.vipMonthlyVehicles.OnOpen(function()
    StaffMenu.vipMonthlyVehicles.ClearItems()

    fetchVehiclesData()

    StaffMenu.vipMonthlyVehicles.Separator("TIERS VIP")

    for tier = 1, 3 do
        local count = getVehicleCountForTier(tier)
        StaffMenu.vipMonthlyVehicles.Button(
            "VIP " .. tierLabels[tier],
            count .. (count > 1 and " vehicules configures" or " vehicule configure"),
            nil,
            "chevron",
            false,
            function()
                newVehicle.tier = tier
            end,
            StaffMenu.vipMonthlyTier
        )
    end

    StaffMenu.vipMonthlyVehicles.Separator("ACTIONS")

    StaffMenu.vipMonthlyVehicles.Button("+ Ajouter un vehicule", "Configurer un nouveau vehicule du mois", nil, "chevron", false, function()
        newVehicle = {}
    end, StaffMenu.vipMonthlyAdd)
end)

-- ==========================================
--     TIER VEHICLES LIST
-- ==========================================

StaffMenu.vipMonthlyTier.OnOpen(function()
    StaffMenu.vipMonthlyTier.ClearItems()

    local tier = newVehicle.tier or 1
    StaffMenu.vipMonthlyTier.Separator("VIP " .. tierLabels[tier])

    local tierVehicles = {}
    for _, v in ipairs(VIPVehicleCache.vehicles) do
        if tonumber(v.vip_tier) == tier then
            table.insert(tierVehicles, v)
        end
    end

    if #tierVehicles == 0 then
        StaffMenu.vipMonthlyTier.Button("Aucun véhicule", "Ajoutez un véhicule pour ce tier", nil, nil, true, function() end)
        return
    end

    for _, veh in ipairs(tierVehicles) do
        local subtitle = veh.vehicle_model .. " | " .. (veh.vehicle_category or "Autre")

        StaffMenu.vipMonthlyTier.Button(
            veh.vehicle_label,
            subtitle,
            nil,
            "trash",
            false,
            function()
                local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour supprimer " .. veh.vehicle_label)
                if confirm and string.upper(confirm) == "OUI" then
                    local result = TriggerServerCallback("vip:admin:removeMonthlyVehicleCallback", veh.id)
                    if result and result.success then
                        VFW.ShowNotification({ type = "VERT", content = "Véhicule supprimé: " .. veh.vehicle_label })
                        fetchVehiclesData()
                        StaffMenu.vipMonthlyTier.refresh()
                    else
                        VFW.ShowNotification({ type = "ROUGE", content = "Erreur lors de la suppression" })
                    end
                end
            end
        )
    end
end)

-- ==========================================
--     ADD VEHICLE MENU
-- ==========================================

StaffMenu.vipMonthlyAdd.OnOpen(function()
    StaffMenu.vipMonthlyAdd.ClearItems()

    newVehicle = newVehicle or {}

    StaffMenu.vipMonthlyAdd.Separator("NOUVEAU VEHICULE")

    -- Tier selection
    local tierOptions = { "Bronze", "Silver", "Gold" }
    local currentTierIdx = newVehicle.tier or 1
    StaffMenu.vipMonthlyAdd.List("Tier VIP", "Selectionner le tier", false, tierOptions, currentTierIdx, function(idx)
        newVehicle.tier = idx
    end)

    -- Vehicle model input
    StaffMenu.vipMonthlyAdd.Button(
        "Modele du vehicule",
        newVehicle.model or "Non défini",
        nil,
        "edit",
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom du spawn (ex: adder, zentorno)")
            if input and input ~= "" then
                newVehicle.model = string.lower(input)
                StaffMenu.vipMonthlyAdd.refresh()
            end
        end
    )

    -- Vehicle label input
    StaffMenu.vipMonthlyAdd.Button(
        "Nom d'affichage",
        newVehicle.label or "Non défini",
        nil,
        "edit",
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom affiche (ex: Adder, Zentorno)")
            if input and input ~= "" then
                newVehicle.label = input
                StaffMenu.vipMonthlyAdd.refresh()
            end
        end
    )

    -- Category input
    StaffMenu.vipMonthlyAdd.Button(
        "Categorie",
        newVehicle.category or "Autre",
        nil,
        "edit",
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Sport, SUV, Berline, etc.")
            if input and input ~= "" then
                newVehicle.category = input
                StaffMenu.vipMonthlyAdd.refresh()
            end
        end
    )

    StaffMenu.vipMonthlyAdd.Separator("VALIDER")

    local canSave = newVehicle.model and newVehicle.label and newVehicle.tier
    StaffMenu.vipMonthlyAdd.Button(
        "Sauvegarder",
        canSave and "Ajouter ce vehicule" or "Remplissez tous les champs",
        nil,
        "check",
        not canSave,
        function()
            local result = TriggerServerCallback("vip:admin:addMonthlyVehicleCallback", {
                tier = newVehicle.tier,
                model = newVehicle.model,
                label = newVehicle.label,
                category = newVehicle.category or "Autre"
          })

            if result and result.success then
                VFW.ShowNotification({ type = "VERT", content = "Véhicule ajouté: " .. newVehicle.label .. " (VIP " .. tierLabels[newVehicle.tier] .. ")" })
                newVehicle = {}
                fetchVehiclesData()
                StaffMenu.vipMonthlyAdd.close()
                StaffMenu.vipMonthlyAdd.parent.open()
            else
                VFW.ShowNotification({ type = "ROUGE", content = result and result.message or "Erreur lors de l'ajout" })
            end
        end
    )
end)

-- ==========================================
--     ADD VIP - SELECT TIER + DURATION
-- ==========================================

StaffMenu.vipPlayerAdd.OnOpen(function()
    StaffMenu.vipPlayerAdd.ClearItems()

    if not vipPlayerData then
        StaffMenu.vipPlayerAdd.Button("Erreur", "Aucun joueur sélectionné", nil, nil, true, function() end)
        return
    end

    local currentDesc = vipPlayerData.tier > 0
        and ("Actuellement VIP " .. vipPlayerData.tierLabel .. " | Restant: " .. (vipPlayerData.remaining or "N/A"))
        or "Aucun VIP actuellement"

  StaffMenu.vipPlayerAdd.Separator("AJOUTER VIP A " .. vipPlayerData.playerName .. " (ID: " .. vipPlayerData.serverId .. ")")
    StaffMenu.vipPlayerAdd.Button("Statut actuel", currentDesc, nil, nil, true, function() end)

    local tierOptions = { "Bronze", "Silver", "Gold" }
    selectedAddTier = selectedAddTier or 1

    StaffMenu.vipPlayerAdd.List("Tier VIP", "Selectionner le tier a attribuer", false, tierOptions, selectedAddTier, function(idx)
        selectedAddTier = idx
    end)

    StaffMenu.vipPlayerAdd.Separator("CHOISIR LA DUREE")

    StaffMenu.vipPlayerAdd.Button("Choisir la durée", "Selectionner une durée pour le VIP " .. tierOptions[selectedAddTier], nil, "chevron", false, function()
    end, StaffMenu.vipPlayerAddActions)
end)

-- ==========================================
--     ADD VIP - DURATION SELECTION
-- ==========================================

StaffMenu.vipPlayerAddActions.OnOpen(function()
    StaffMenu.vipPlayerAddActions.ClearItems()

    if not vipPlayerData then
        StaffMenu.vipPlayerAddActions.Button("Erreur", "Aucun joueur sélectionné", nil, nil, true, function() end)
        return
    end

    local tierOptions = { "Bronze", "Silver", "Gold" }
    local tierName = tierOptions[selectedAddTier] or "Bronze"

  StaffMenu.vipPlayerAddActions.Separator("VIP " .. tierName .. " - DUREE")

    local durations = {
        { label = "7 jours", days = 7 },
        { label = "15 jours", days = 15 },
        { label = "30 jours", days = 30 },
        { label = "90 jours", days = 90 },
        { label = "Illimite", days = 0 }
    }

    for _, dur in ipairs(durations) do
        StaffMenu.vipPlayerAddActions.Button(
            dur.label,
            "VIP " .. tierName .. " " .. dur.label .. " a " .. vipPlayerData.playerName,
            nil,
            "check",
            false,
            function()
                local confirmText = "VIP " .. tierName .. " " .. dur.label .. " a " .. vipPlayerData.playerName
                local confirm = VFW.Nui.KeyboardInput(true, "OUI pour confirmer: " .. confirmText)
                if confirm and string.upper(confirm) == "OUI" then
                    local result = TriggerServerCallback("vip:admin:setPlayerVIP", {
                        serverId = vipPlayerData.serverId,
                        tier = selectedAddTier,
                        days = dur.days > 0 and dur.days or nil
                    })
                    if result and result.success then
                        VFW.ShowNotification({ type = "VERT", content = result.message })
                        vipPlayerData = nil
                        StaffMenu.vipPlayerAddActions.close()
                        Wait(100)
                        StaffMenu.vipPlayerList.open()
                    else
                        VFW.ShowNotification({ type = "ROUGE", content = result and result.message or "Erreur" })
                    end
                end
            end
        )
    end

    StaffMenu.vipPlayerAddActions.Button(
        "Durée personnalisée",
        "Entrer un nombre de jours",
        nil,
        "edit",
        false,
        function()
            local daysInput = VFW.Nui.KeyboardInput(true, "Nombre de jours (ex: 45)")
            local days = tonumber(daysInput)
            if not days or days <= 0 then
                VFW.ShowNotification({ type = "ROUGE", content = "Ce nombre de jours n'est pas valide" })
                return
            end
            local confirmText = "VIP " .. tierName .. " " .. days .. "j a " .. vipPlayerData.playerName
            local confirm = VFW.Nui.KeyboardInput(true, "OUI pour confirmer: " .. confirmText)
            if confirm and string.upper(confirm) == "OUI" then
                local result = TriggerServerCallback("vip:admin:setPlayerVIP", {
                    serverId = vipPlayerData.serverId,
                    tier = selectedAddTier,
                    days = days
                })
                if result and result.success then
                    VFW.ShowNotification({ type = "VERT", content = result.message })
                    vipPlayerData = nil
                    StaffMenu.vipPlayerAddActions.close()
                    Wait(100)
                    StaffMenu.vipPlayerList.open()
                else
                    VFW.ShowNotification({ type = "ROUGE", content = result and result.message or "Erreur" })
                end
            end
        end
    )
end)

-- ==========================================
--     LIST VIP PLAYERS
-- ==========================================

StaffMenu.vipPlayerList.OnOpen(function()
    StaffMenu.vipPlayerList.ClearItems()

    local result = TriggerServerCallback("vip:admin:listVIPPlayers")

    if not result or not result.success then
        StaffMenu.vipPlayerList.Button("Erreur", "Impossible de charger la liste", nil, nil, true, function() end)
        return
    end

    local players = result.players or {}

    if #players == 0 then
        StaffMenu.vipPlayerList.Button("Aucun VIP", "Aucun joueur VIP en ligne actuellement", nil, nil, true, function() end)
        return
    end

    StaffMenu.vipPlayerList.Separator("JOUEURS VIP EN LIGNE (" .. #players .. ")")

    for _, p in ipairs(players) do
        local desc = "VIP " .. p.tierLabel .. " | Restant: " .. p.remaining
        StaffMenu.vipPlayerList.Button(
            p.playerName .. " (ID: " .. p.serverId .. ")",
            desc,
            nil,
            "chevron",
            false,
            function()
                vipPlayerData = p
            end,
            StaffMenu.vipPlayerDetail
        )
    end
end)

-- ==========================================
--     VIP PLAYER DETAIL (from list)
-- ==========================================

StaffMenu.vipPlayerDetail.OnOpen(function()
    StaffMenu.vipPlayerDetail.ClearItems()

    if not vipPlayerData then
        StaffMenu.vipPlayerDetail.Button("Erreur", "Aucun joueur sélectionné", nil, nil, true, function() end)
        return
    end

    -- Refresh data
    local refreshed = TriggerServerCallback("vip:admin:getPlayerVIPStatus", vipPlayerData.serverId)
    if refreshed and refreshed.success then
        vipPlayerData = refreshed
    end

    StaffMenu.vipPlayerDetail.Separator("JOUEUR: " .. vipPlayerData.playerName .. " (ID: " .. vipPlayerData.serverId .. ")")

    local statusDesc = "Tier: " .. vipPlayerData.tierLabel
    if vipPlayerData.tier > 0 then
        statusDesc = statusDesc .. " | Expire: " .. (vipPlayerData.expiryFormatted or "Illimite")
        statusDesc = statusDesc .. " | Restant: " .. (vipPlayerData.remaining or "N/A")
    end
    StaffMenu.vipPlayerDetail.Button("Statut VIP", statusDesc, nil, nil, true, function() end)

    StaffMenu.vipPlayerDetail.Separator("ACTIONS")

    -- Modify VIP
    StaffMenu.vipPlayerDetail.Button("Modifier le VIP", "Changer le tier ou la durée", nil, "chevron", false, function()
        selectedAddTier = vipPlayerData.tier > 0 and vipPlayerData.tier or 1
    end, StaffMenu.vipPlayerModify)

    -- Remove VIP
    StaffMenu.vipPlayerDetail.Button("Retirer le VIP", "Supprimer le VIP du joueur", nil, "trash", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour retirer le VIP de " .. vipPlayerData.playerName)
        if confirm and string.upper(confirm) == "OUI" then
            local result = TriggerServerCallback("vip:admin:removePlayerVIP", vipPlayerData.serverId)
            if result and result.success then
                VFW.ShowNotification({ type = "VERT", content = result.message })
                vipPlayerData = nil
                StaffMenu.vipPlayerDetail.close()
                StaffMenu.vipPlayerDetail.parent.open()
            else
                VFW.ShowNotification({ type = "ROUGE", content = result and result.message or "Erreur" })
            end
        end
    end)
end)

-- ==========================================
--     MODIFY VIP (from detail)
-- ==========================================

StaffMenu.vipPlayerModify.OnOpen(function()
    StaffMenu.vipPlayerModify.ClearItems()

    if not vipPlayerData then
        StaffMenu.vipPlayerModify.Button("Erreur", "Aucun joueur sélectionné", nil, nil, true, function() end)
        return
    end

    local tierOptions = { "Bronze", "Silver", "Gold" }
    selectedAddTier = selectedAddTier or 1

    StaffMenu.vipPlayerModify.Separator("MODIFIER VIP DE " .. vipPlayerData.playerName)

    StaffMenu.vipPlayerModify.List("Nouveau tier", "Selectionner le nouveau tier", false, tierOptions, selectedAddTier, function(idx)
        selectedAddTier = idx
    end)

    StaffMenu.vipPlayerModify.Separator("NOUVELLE DUREE")

    local durations = {
        { label = "7 jours", days = 7 },
        { label = "15 jours", days = 15 },
        { label = "30 jours", days = 30 },
        { label = "90 jours", days = 90 },
        { label = "Illimite", days = 0 }
    }

    for _, dur in ipairs(durations) do
        local tierName = tierOptions[selectedAddTier] or "Bronze"
      StaffMenu.vipPlayerModify.Button(
            dur.label,
            "Passer en VIP " .. tierName .. " " .. dur.label,
            nil,
            "check",
            false,
            function()
                local confirmText = "Modifier en VIP " .. tierName .. " " .. dur.label
                local confirm = VFW.Nui.KeyboardInput(true, "OUI pour confirmer: " .. confirmText)
                if confirm and string.upper(confirm) == "OUI" then
                    local result = TriggerServerCallback("vip:admin:setPlayerVIP", {
                        serverId = vipPlayerData.serverId,
                        tier = selectedAddTier,
                        days = dur.days > 0 and dur.days or nil
                    })
                    if result and result.success then
                        VFW.ShowNotification({ type = "VERT", content = result.message })
                        vipPlayerData = nil
                        StaffMenu.vipPlayerModify.close()
                        Wait(100)
                        StaffMenu.vipPlayerList.refresh()
                    else
                        VFW.ShowNotification({ type = "ROUGE", content = result and result.message or "Erreur" })
                    end
                end
            end
        )
    end

    StaffMenu.vipPlayerModify.Button(
        "Durée personnalisée",
        "Entrer un nombre de jours",
        nil,
        "edit",
        false,
        function()
            local tierName = tierOptions[selectedAddTier] or "Bronze"
          local daysInput = VFW.Nui.KeyboardInput(true, "Nombre de jours (ex: 45)")
            local days = tonumber(daysInput)
            if not days or days <= 0 then
                VFW.ShowNotification({ type = "ROUGE", content = "Ce nombre de jours n'est pas valide" })
                return
            end
            local confirmText = "Modifier en VIP " .. tierName .. " " .. days .. "j"
          local confirm = VFW.Nui.KeyboardInput(true, "OUI pour confirmer: " .. confirmText)
            if confirm and string.upper(confirm) == "OUI" then
                local result = TriggerServerCallback("vip:admin:setPlayerVIP", {
                    serverId = vipPlayerData.serverId,
                    tier = selectedAddTier,
                    days = days
                })
                if result and result.success then
                    VFW.ShowNotification({ type = "VERT", content = result.message })
                    vipPlayerData = nil
                    StaffMenu.vipPlayerModify.close()
                    Wait(100)
                    StaffMenu.vipPlayerList.refresh()
                else
                    VFW.ShowNotification({ type = "ROUGE", content = result and result.message or "Erreur" })
                end
            end
        end
    )
end)

-- ==========================================
--     VIP CONFIG VALUES MANAGEMENT
-- ==========================================

local selectedConfigTier = 1

local configKeyLabels = {
    monthlyCoins    = "Coins / mois",
    hourlyCoins     = "Coins / heure",
    inventoryWeight = "Poids inventaire (kg)",
    stateAid        = "Aide de l'état (" .. LOCALE.currencySymbol .. ")",
    impoundDiscount = "Réduction fourrière (%)",
    trunkBonus      = "Coffre véhicule (%)",
    dynastyBonus    = "Stockage Dynasty (%)",
    propsPermanent  = "Objets permanents",
    propsTemporary  = "Objets temporaires",
    respawnTime     = "Temps respawn hôpital (sec)",
    interimMultiplier     = "Multiplicateur Interim",
    gofastMultiplier      = "Multiplicateur Go Fast",
    drugDealingMultiplier = "Multiplicateur Vente drogue",
    ppaLeger        = "PPA Léger",
    ppaLourd        = "PPA Lourd",
    plate_changes_per_month = "Changements de plaque / mois",
    driftMode       = "Mode Drift",
    weaponCustomization = "Perso. armes (Teintes & Skins)",
    freecam = "FreeCam (Caméra libre)",
}

local configKeyOrder = {
    "monthlyCoins", "hourlyCoins", "inventoryWeight", "stateAid", "impoundDiscount",
    "trunkBonus", "dynastyBonus",
    "propsPermanent", "propsTemporary", "respawnTime", "interimMultiplier", "gofastMultiplier", "drugDealingMultiplier", "ppaLeger", "ppaLourd",
    "plate_changes_per_month", "driftMode", "weaponCustomization", "freecam"
}

-- Keys that are toggle (0/1) instead of numeric input
local configKeyToggle = {
    ppaLeger = true,
    ppaLourd = true,
    driftMode = true,
    weaponCustomization = true,
    freecam = true,
}


StaffMenu.vipAdvantages.OnOpen(function()
    StaffMenu.vipAdvantages.ClearItems()

    StaffMenu.vipAdvantages.Separator("VALEURS VIP PAR TIER")

    for tier = 1, 3 do
        StaffMenu.vipAdvantages.Button(
            "VIP " .. tierLabels[tier],
            "Modifier les valeurs VIP " .. tierLabels[tier],
            nil,
            "chevron",
            false,
            function()
                selectedConfigTier = tier
            end,
            StaffMenu.vipAdvantagesTier
        )
    end
end)

StaffMenu.vipAdvantagesTier.OnOpen(function()
    StaffMenu.vipAdvantagesTier.ClearItems()

    local tier = selectedConfigTier or 1
    local result = TriggerServerCallback("vip:admin:getTierConfig", tier)
    local cfg = result and result.config or {}

    StaffMenu.vipAdvantagesTier.Separator("VALEURS VIP " .. tierLabels[tier])

    for _, key in ipairs(configKeyOrder) do
        local label = configKeyLabels[key] or key
        local currentVal = cfg[key]

        if configKeyToggle[key] then
            -- Toggle button (0/1)
            local isEnabled = (tonumber(currentVal) or 0) == 1
            local statusText = isEnabled and "Activé" or "Désactivé"

          StaffMenu.vipAdvantagesTier.Button(
                label,
                statusText,
                nil,
                isEnabled and "check" or "chevron",
                false,
                function()
                    local newVal = isEnabled and 0 or 1
                    local res = TriggerServerCallback("vip:admin:setTierConfigValue", {
                        tier = tier,
                        key = key,
                        value = newVal
                    })

                    if res and res.success then
                        VFW.ShowNotification({ type = "VERT", content = label .. (newVal == 1 and " activé" or " désactivé") })
                        StaffMenu.vipAdvantagesTier.refresh()
                    else
                        VFW.ShowNotification({ type = "ROUGE", content = res and res.message or "Erreur" })
                    end
                end
            )
        else
            -- Numeric input
            local displayVal = tostring(currentVal or "N/A")

            StaffMenu.vipAdvantagesTier.Button(
                label,
                "Actuel: " .. displayVal,
                nil,
                "edit",
                false,
                function()
                    local input = VFW.Nui.KeyboardInput(true, label .. " (actuel: " .. displayVal .. ")")
                    if not input or input == "" then return end

                    local numVal = tonumber(input)
                    if not numVal then
                        VFW.ShowNotification({ type = "ROUGE", content = "Cette valeur n'est pas valide : entrez un nombre" })
                        return
                    end

                    local res = TriggerServerCallback("vip:admin:setTierConfigValue", {
                        tier = tier,
                        key = key,
                        value = numVal
                    })

                    if res and res.success then
                        VFW.ShowNotification({ type = "VERT", content = label .. " mis à jour: " .. tostring(numVal) })
                        StaffMenu.vipAdvantagesTier.refresh()
                    else
                        VFW.ShowNotification({ type = "ROUGE", content = res and res.message or "Erreur" })
                    end
                end
            )
        end
    end

    -- Single button for emergency vehicle (label + model)
    StaffMenu.vipAdvantagesTier.Separator("VEHICULE D'URGENCE")

    local eLabel = tostring(cfg.emergency_vehicle_label or "")
    local eModel = tostring(cfg.emergency_vehicle_model or "")
    if eLabel == "0" then eLabel = "" end
    if eModel == "0" then eModel = "" end
    local eDisplay = (eLabel ~= "" and eModel ~= "") and (eLabel .. " (" .. eModel .. ")") or "Non défini"

  StaffMenu.vipAdvantagesTier.Button(
        "Véhicule d'urgence",
        eDisplay,
        nil,
        "edit",
        false,
        function()
            local labelInput = VFW.Nui.KeyboardInput(true, "Nom d'affichage (ex: Faggio, Bati 801)")
            if not labelInput or labelInput == "" then return end

            local modelInput = VFW.Nui.KeyboardInput(true, "Modèle spawn (ex: faggio, bati)")
            if not modelInput or modelInput == "" then return end

            modelInput = string.lower(modelInput)

            local res1 = TriggerServerCallback("vip:admin:setTierConfigValue", {
                tier = tier,
                key = "emergency_vehicle_label",
                value = labelInput
            })
            local res2 = TriggerServerCallback("vip:admin:setTierConfigValue", {
                tier = tier,
                key = "emergency_vehicle_model",
                value = modelInput
            })

            if res1 and res1.success and res2 and res2.success then
                VFW.ShowNotification({ type = "VERT", content = "Véhicule d'urgence → " .. labelInput .. " (" .. modelInput .. ")" })
                StaffMenu.vipAdvantagesTier.refresh()
            else
                VFW.ShowNotification({ type = "ROUGE", content = "Erreur lors de la mise à jour" })
            end
        end
    )
end)
