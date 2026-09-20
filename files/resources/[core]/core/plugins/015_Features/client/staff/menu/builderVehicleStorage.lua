---
--- Builder: Configuration du stockage véhicules
--- Permet de gérer le poids et les slots du coffre et de la boîte à gants par véhicule.
---

-- Variables locales
local vehicleStorageCache = {}
local currentVehicleConfig = nil
local newVehicleData = {
    model = nil,
    vehicle_hash = 0,
    trunk_weight = 60,
    trunk_slots = 30,
    glovebox_weight = 5,
    glovebox_slots = 5,
    can_enter_trunk = true
}
local searchResults = {}

-- Recevoir la synchronisation du serveur
RegisterNetEvent('vehicleStorage:syncConfig')
AddEventHandler('vehicleStorage:syncConfig', function(data)
    vehicleStorageCache = data or {}
end)

-- Reset des données pour nouveau véhicule
local function ResetNewVehicleData()
    newVehicleData = {
        model = nil,
        vehicle_hash = 0,
        trunk_weight = 60,
        trunk_slots = 30,
        glovebox_weight = 5,
        glovebox_slots = 5,
        can_enter_trunk = true
    }
end


-- Compter les véhicules configurés
local function CountConfigs()
    local count = 0
    for _ in pairs(vehicleStorageCache) do
        count = count + 1
    end
    return count
end

-- ============================================
-- Menu principal: Stockage véhicules
-- ============================================
function StaffMenu.BuildVehicleStorageMenu()
    vehicleStorageCache = TriggerServerCallback('vehicleStorage:getAll') or {}

    StaffMenu.builderVehicleStorage.Button(
        "+ AJOUTER UN VÉHICULE",
        "Configurer le stockage d'un nouveau véhicule.",
        nil,
        "chevron",
        false,
        function()
            ResetNewVehicleData()
        end,
        StaffMenu.vehicleStorageCreate
    )

    StaffMenu.builderVehicleStorage.Button(
        "LISTE DES VÉHICULES",
        "Voir et modifier les configurations existantes.",
        nil,
        "chevron",
        false,
        function()
            vehicleStorageCache = TriggerServerCallback('vehicleStorage:getAll') or {}
        end,
        StaffMenu.vehicleStorageList
    )

    StaffMenu.builderVehicleStorage.Button(
        "RECHERCHER",
        "Rechercher un véhicule par nom de modèle.",
        nil,
        "chevron",
        false,
        function()
            searchResults = {}
            vehicleStorageCache = TriggerServerCallback('vehicleStorage:getAll') or {}
        end,
        StaffMenu.vehicleStorageSearch
    )

    StaffMenu.builderVehicleStorage.Separator("INFORMATIONS")

    StaffMenu.builderVehicleStorage.Button(
        "Total configuré",
        tostring(CountConfigs()) .. (CountConfigs() > 1 and " véhicules." or " véhicule."),
        nil,
        nil,
        true,
        function() end
    )
end

-- ============================================
-- Menu création: Ajouter un véhicule
-- ============================================
function StaffMenu.BuildVehicleStorageCreateMenu()
    StaffMenu.vehicleStorageCreate.Separator("NOUVEAU VÉHICULE")

    -- Nom du modèle (le hash est calculé automatiquement)
    StaffMenu.vehicleStorageCreate.Button(
        "NOM DU MODÈLE",
        newVehicleData.model and ("Actuel: " .. newVehicleData.model .. " | Hash: " .. newVehicleData.vehicle_hash) or "Cliquez pour définir.",
        newVehicleData.model or "Non défini",
        "chevron",
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom du modèle (technique)")
            if input and input ~= "" then
                local modelLower = string.lower(input)
                newVehicleData.model = modelLower
                newVehicleData.vehicle_hash = joaat(modelLower)
                StaffMenu.vehicleStorageCreate.refresh()
            end
        end
    )

    StaffMenu.vehicleStorageCreate.Separator("COFFRE")

    -- Poids coffre
    StaffMenu.vehicleStorageCreate.Button(
        "POIDS MAX COFFRE",
        "Capacité maximale en poids.",
        tostring(newVehicleData.trunk_weight) .. " kg",
        "chevron",
        false,
        function()
            local input = tonumber(VFW.Nui.KeyboardInput(true, "Poids max coffre (kg)"))
            if input and input > 0 then
                newVehicleData.trunk_weight = input
                StaffMenu.vehicleStorageCreate.refresh()
            end
        end
    )

    -- Slots coffre
    StaffMenu.vehicleStorageCreate.Button(
        "SLOTS COFFRE",
        "Nombre d'emplacements dans le coffre.",
        tostring(newVehicleData.trunk_slots),
        "chevron",
        false,
        function()
            local input = tonumber(VFW.Nui.KeyboardInput(true, "Nombre de slots coffre"))
            if input and input > 0 then
                newVehicleData.trunk_slots = input
                StaffMenu.vehicleStorageCreate.refresh()
            end
        end
    )

    StaffMenu.vehicleStorageCreate.Separator("BOÎTE À GANTS")

    -- Poids boîte à gants
    StaffMenu.vehicleStorageCreate.Button(
        "POIDS MAX BOÎTE À GANTS",
        "Capacité maximale en poids.",
        tostring(newVehicleData.glovebox_weight) .. " kg",
        "chevron",
        false,
        function()
            local input = tonumber(VFW.Nui.KeyboardInput(true, "Poids max boîte à gants (kg)"))
            if input and input > 0 then
                newVehicleData.glovebox_weight = input
                StaffMenu.vehicleStorageCreate.refresh()
            end
        end
    )

    -- Slots boîte à gants
    StaffMenu.vehicleStorageCreate.Button(
        "SLOTS BOÎTE À GANTS",
        "Nombre d'emplacements dans la boîte à gants.",
        tostring(newVehicleData.glovebox_slots),
        "chevron",
        false,
        function()
            local input = tonumber(VFW.Nui.KeyboardInput(true, "Nombre de slots boîte à gants"))
            if input and input > 0 then
                newVehicleData.glovebox_slots = input
                StaffMenu.vehicleStorageCreate.refresh()
            end
        end
    )

    StaffMenu.vehicleStorageCreate.Separator("OPTIONS")

    -- Peut rentrer dans le coffre
    StaffMenu.vehicleStorageCreate.Button(
        "ACCÈS COFFRE",
        "Autoriser les joueurs à rentrer dans le coffre.",
        newVehicleData.can_enter_trunk and "Oui" or "Non",
        "chevron",
        false,
        function()
            newVehicleData.can_enter_trunk = not newVehicleData.can_enter_trunk
            StaffMenu.vehicleStorageCreate.refresh()
        end
    )

    StaffMenu.vehicleStorageCreate.Separator("")

    -- Validation
    local isValid = newVehicleData.model ~= nil and newVehicleData.model ~= ""

  StaffMenu.vehicleStorageCreate.Button(
        "CRÉER LA CONFIGURATION",
        isValid and "Cliquez pour créer." or "Renseignez d'abord le nom du modèle.",
        nil,
        "chevron",
        not isValid,
        function()
            local result = TriggerServerCallback('vehicleStorage:create', newVehicleData)
            if result and result.success then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Configuration créée pour " .. newVehicleData.model .. "."
              })
                ResetNewVehicleData()
                StaffMenu.vehicleStorageCreate.close()
                StaffMenu.vehicleStorageCreate.parent.open()
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                    message = result and result.error or "Erreur lors de la création."
              })
            end
        end
    )
end

-- ============================================
-- Menu liste: Tous les véhicules configurés
-- ============================================
function StaffMenu.BuildVehicleStorageListMenu()
    StaffMenu.vehicleStorageList.Separator("VÉHICULES CONFIGURÉS")

    -- Trier par nom de modèle
    local sortedVehicles = {}
    for model, config in pairs(vehicleStorageCache) do
        table.insert(sortedVehicles, { model = model, config = config })
    end
    table.sort(sortedVehicles, function(a, b) return a.model < b.model end)

    if #sortedVehicles == 0 then
        StaffMenu.vehicleStorageList.Button(
            "AUCUN VÉHICULE",
            "Aucune configuration trouvée.",
            nil,
            nil,
            true,
            function() end
        )
        return
    end

    for _, vehicle in ipairs(sortedVehicles) do
        local config = vehicle.config
        local canEnter = config.can_enter_trunk
        if canEnter == nil then canEnter = true end
        local accessLabel = canEnter and "Accès: Oui" or "Accès: Non"
      local desc = string.format("Coffre: %dkg/%d slots | BAG: %dkg/%d slots | %s.",
            config.trunk_weight, config.trunk_slots,
            config.glovebox_weight, config.glovebox_slots,
            accessLabel)

        StaffMenu.vehicleStorageList.Button(
            string.upper(vehicle.model),
            desc,
            nil,
            "chevron",
            false,
            function()
                -- Copier la config pour édition
                currentVehicleConfig = {
                    model = config.model,
                    vehicle_hash = config.vehicle_hash or 0,
                    trunk_weight = config.trunk_weight,
                    trunk_slots = config.trunk_slots,
                    glovebox_weight = config.glovebox_weight,
                    glovebox_slots = config.glovebox_slots,
                    can_enter_trunk = canEnter
                }
            end,
            StaffMenu.vehicleStorageEdit
        )
    end
end

-- ============================================
-- Menu recherche
-- ============================================
function StaffMenu.BuildVehicleStorageSearchMenu()
    StaffMenu.vehicleStorageSearch.Button(
        "RECHERCHER UN VÉHICULE",
        #searchResults > 0 and (#searchResults .. (#searchResults > 1 and " résultats." or " résultat.")) or "Tapez le nom du modèle à rechercher.",
        nil,
        "search",
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom du véhicule à rechercher")
            if input and input ~= "" then
                local searchTerm = string.lower(input)
                searchResults = {}

                for model, config in pairs(vehicleStorageCache) do
                    if string.find(model, searchTerm) then
                        table.insert(searchResults, { model = model, config = config })
                    end
                end

                table.sort(searchResults, function(a, b) return a.model < b.model end)
                StaffMenu.vehicleStorageSearch.refresh()
            end
        end
    )

    StaffMenu.vehicleStorageSearch.Separator("RÉSULTATS (" .. #searchResults .. ")")

    if #searchResults == 0 then
        StaffMenu.vehicleStorageSearch.Button(
            "Aucun résultat",
            "Utilisez le bouton de recherche ci-dessus.",
            nil,
            nil,
            true,
            function() end
        )
    else
        for _, vehicle in ipairs(searchResults) do
            local config = vehicle.config
            local canEnter = config.can_enter_trunk
            if canEnter == nil then canEnter = true end
            local accessLabel = canEnter and "Accès: Oui" or "Accès: Non"
          local desc = string.format("Coffre: %dkg/%d slots | BAG: %dkg/%d slots | %s.",
                config.trunk_weight, config.trunk_slots,
                config.glovebox_weight, config.glovebox_slots,
                accessLabel)

            StaffMenu.vehicleStorageSearch.Button(
                string.upper(vehicle.model),
                desc,
                nil,
                "chevron",
                false,
                function()
                    currentVehicleConfig = {
                        model = config.model,
                        vehicle_hash = config.vehicle_hash or 0,
                        trunk_weight = config.trunk_weight,
                        trunk_slots = config.trunk_slots,
                        glovebox_weight = config.glovebox_weight,
                        glovebox_slots = config.glovebox_slots,
                        can_enter_trunk = canEnter
                    }
                end,
                StaffMenu.vehicleStorageEdit
            )
        end
    end
end

-- ============================================
-- Menu édition: Modifier un véhicule
-- ============================================
function StaffMenu.BuildVehicleStorageEditMenu()
    if not currentVehicleConfig then
        StaffMenu.vehicleStorageEdit.Button(
            "Erreur",
            "Aucun véhicule sélectionné.",
            nil,
            nil,
            true,
            function() end
        )
        return
    end

    local config = currentVehicleConfig

    -- Recalculer le hash depuis le model name si pas défini
    if not config.vehicle_hash or config.vehicle_hash == 0 then
        config.vehicle_hash = joaat(config.model)
    end

    StaffMenu.vehicleStorageEdit.Separator("VÉHICULE: " .. string.upper(config.model) .. " | Hash: " .. config.vehicle_hash)

    StaffMenu.vehicleStorageEdit.Separator("COFFRE")

    -- Poids coffre
    StaffMenu.vehicleStorageEdit.Button(
        "POIDS MAX COFFRE",
        "Modifier la capacité.",
        tostring(config.trunk_weight) .. " kg",
        "chevron",
        false,
        function()
            local input = tonumber(VFW.Nui.KeyboardInput(true, "Nouveau poids coffre (kg)"))
            if input and input > 0 then
                config.trunk_weight = input
                StaffMenu.vehicleStorageEdit.refresh()
            end
        end
    )

    -- Slots coffre
    StaffMenu.vehicleStorageEdit.Button(
        "SLOTS COFFRE",
        "Modifier le nombre d'emplacements.",
        tostring(config.trunk_slots),
        "chevron",
        false,
        function()
            local input = tonumber(VFW.Nui.KeyboardInput(true, "Nouveau nombre de slots coffre"))
            if input and input > 0 then
                config.trunk_slots = input
                StaffMenu.vehicleStorageEdit.refresh()
            end
        end
    )

    StaffMenu.vehicleStorageEdit.Separator("BOÎTE À GANTS")

    -- Poids boîte à gants
    StaffMenu.vehicleStorageEdit.Button(
        "POIDS MAX BOÎTE À GANTS",
        "Modifier la capacité.",
        tostring(config.glovebox_weight) .. " kg",
        "chevron",
        false,
        function()
            local input = tonumber(VFW.Nui.KeyboardInput(true, "Nouveau poids boîte à gants (kg)"))
            if input and input > 0 then
                config.glovebox_weight = input
                StaffMenu.vehicleStorageEdit.refresh()
            end
        end
    )

    -- Slots boîte à gants
    StaffMenu.vehicleStorageEdit.Button(
        "SLOTS BOÎTE À GANTS",
        "Modifier le nombre d'emplacements.",
        tostring(config.glovebox_slots),
        "chevron",
        false,
        function()
            local input = tonumber(VFW.Nui.KeyboardInput(true, "Nouveau nombre de slots boîte à gants"))
            if input and input > 0 then
                config.glovebox_slots = input
                StaffMenu.vehicleStorageEdit.refresh()
            end
        end
    )

    StaffMenu.vehicleStorageEdit.Separator("OPTIONS")

    -- Peut rentrer dans le coffre
    local canEnter = config.can_enter_trunk
    if canEnter == nil then canEnter = true end
    StaffMenu.vehicleStorageEdit.Button(
        "ACCÈS COFFRE",
        "Autoriser les joueurs à rentrer dans le coffre.",
        canEnter and "Oui" or "Non",
        "chevron",
        false,
        function()
            config.can_enter_trunk = not canEnter
            StaffMenu.vehicleStorageEdit.refresh()
        end
    )

    StaffMenu.vehicleStorageEdit.Separator("ACTIONS")

    -- Sauvegarder
    StaffMenu.vehicleStorageEdit.Button(
        "SAUVEGARDER",
        "Enregistrer les modifications.",
        nil,
        "chevron",
        false,
        function()
            local result = TriggerServerCallback('vehicleStorage:update', config.model, config)
            if result and result.success then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                    message = "Configuration mise à jour."
              })
                StaffMenu.vehicleStorageEdit.close()
                StaffMenu.vehicleStorageEdit.parent.open()
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                    message = result and result.error or "Erreur lors de la sauvegarde."
              })
            end
        end
    )

    -- Réinitialiser aux valeurs par défaut
    StaffMenu.vehicleStorageEdit.Button(
        "RÉINITIALISER",
        "Remettre les valeurs par défaut (60/30/5/5, accès: oui).",
        nil,
        "chevron",
        false,
        function()
            config.trunk_weight = 60
            config.trunk_slots = 30
            config.glovebox_weight = 5
            config.glovebox_slots = 5
            config.can_enter_trunk = true
            StaffMenu.vehicleStorageEdit.refresh()
        end
    )

    -- Supprimer
    StaffMenu.vehicleStorageEdit.Button(
        "SUPPRIMER",
        "Supprimer cette configuration.",
        nil,
        "chevron",
        false,
        function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour confirmer")
            if confirm and confirm:lower() == "oui" then
                local result = TriggerServerCallback('vehicleStorage:delete', config.model)
                if result and result.success then
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder',
                        message = "Configuration supprimée."
                  })
                    currentVehicleConfig = nil
                    vehicleStorageCache = TriggerServerCallback('vehicleStorage:getAll') or {}
                    StaffMenu.vehicleStorageEdit.close()
                    StaffMenu.vehicleStorageEdit.parent.open()
                else
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Builder',
                        message = result and result.error or "Erreur lors de la suppression."
                  })
                end
            end
        end
    )
end

-- ============================================
-- Enregistrement des callbacks OnOpen
-- ============================================
StaffMenu.builderVehicleStorage.OnOpen(function()
    StaffMenu.BuildVehicleStorageMenu()
end)

StaffMenu.vehicleStorageCreate.OnOpen(function()
    StaffMenu.BuildVehicleStorageCreateMenu()
end)

StaffMenu.vehicleStorageList.OnOpen(function()
    StaffMenu.BuildVehicleStorageListMenu()
end)

StaffMenu.vehicleStorageSearch.OnOpen(function()
    StaffMenu.BuildVehicleStorageSearchMenu()
end)

StaffMenu.vehicleStorageEdit.OnOpen(function()
    StaffMenu.BuildVehicleStorageEditMenu()
end)
