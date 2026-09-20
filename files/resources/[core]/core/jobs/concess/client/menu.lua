---
--- Concess Job Menu
--- Registers concess-specific items to the job menu
---

local resourceName = "core"

-- Fonction helper pour les notifications de type JOB
local function ShowConcessNotification(content, isError)
    local societyInfo = TriggerServerCallback("core:get:societyInfo")
    local notifType = isError and 'ROUGE' or 'JOB'

    VFW.ShowNotification({
        type = notifType,
        image = societyInfo.image,
        title = societyInfo.label,
        subtitle = "Information",
        content = content
    })
end

-- Récupérer le concessionnaire du joueur (même sans point catalogue)
local function GetPlayerConcess()
    local xPlayer = VFW.GetPlayerData()
    if not xPlayer or not xPlayer.job then return nil end

    local mine = TriggerServerCallback("core:concess:getMine")
    if mine and mine.id then return mine end

    local concessList = TriggerServerCallback("core:concess:getAll")
    if not concessList then return nil end

    local jobName = string.lower(tostring(xPlayer.job.name or ""))
    for _, concess in ipairs(concessList) do
        if concess.job == xPlayer.job.name or string.lower(tostring(concess.job or "")) == jobName then
            return concess
        end
    end
    return nil
end

-- Enregistrer le menu au chargement
CreateThread(function()
    Wait(1000)

    local registry = exports[resourceName]:getJobMenuRegistry()

    if not registry then
        print("^1[Concess] Failed to get job menu registry^0")
        return
    end

    local showcaseSubMenu = registry.createSubMenuByType("concess", "showcase", "Gestion Exposition")
    local showcasePointMenu = registry.createSubMenuByType("concess", "showcasePoint", "Point Exposition")

    -- Variable pour stocker le point sélectionné
    local selectedShowcaseIndex = nil
    local selectedShowcaseConcess = nil

    -- Setup showcase point submenu (edit/delete options)
    showcasePointMenu.OnOpen(function()
        if not selectedShowcaseConcess or not selectedShowcaseIndex then
            showcasePointMenu.close()
            return
        end

        local point = selectedShowcaseConcess.showcase[selectedShowcaseIndex]
        if not point then
            showcasePointMenu.close()
            return
        end

        local modelName = point.model or "Aucun"
        local displayName = GetLabelText(GetDisplayNameFromVehicleModel(joaat(modelName)))
        if displayName == "NULL" then displayName = modelName end

        showcasePointMenu.Separator("Point #" .. selectedShowcaseIndex .. " - " .. displayName)

        showcasePointMenu.Button(
            "Changer le véhicule",
            "Modèle actuel : " .. modelName,
            nil,
            "chevron",
            false,
            function()
                local sNewModel = VFW.Nui.KeyboardInput(true, "Nouveau modèle (ex: adder)", point.model or "")
                if sNewModel and sNewModel ~= "" then
                    sNewModel = sNewModel:lower()

                    -- Verifier si le modele est valide
                    local modelHash = joaat(sNewModel)
                    if not IsModelValid(modelHash) or not IsModelAVehicle(modelHash) then
                        ShowConcessNotification("Ce modèle de véhicule n'est pas valide : " .. sNewModel, true)
                        return
                    end

                    -- Mettre à jour côté serveur (le serveur notifiera tous les clients)
                    TriggerServerEvent("core:concess:updateShowcase", selectedShowcaseConcess.id, selectedShowcaseIndex, sNewModel)

                    ShowConcessNotification("Véhicule d'exposition mis à jour : " .. sNewModel, false)

                    -- Retour au menu principal
                    showcasePointMenu.close()
                    SetTimeout(500, function()
                        showcaseSubMenu.open()
                    end)
                end
            end
        )

        -- Couleur du véhicule d'exposition
        local currentColor = point.color
        local colorLabel = currentColor
            and string.format("(%d, %d, %d)", currentColor.r, currentColor.g, currentColor.b)
            or "Par défaut"

        showcasePointMenu.Button(
            "Couleur du véhicule",
            "Couleur actuelle : " .. colorLabel,
            nil,
            "chevron",
            false,
            function()
                local initR = currentColor and currentColor.r or 255
                local initG = currentColor and currentColor.g or 255
                local initB = currentColor and currentColor.b or 255

                showcasePointMenu.RoleColorPicker(initR, initG, initB, "COULEUR EXPOSITION",
                    nil,
                    function(finalR, finalG, finalB)
                        TriggerServerEvent("core:concess:updateShowcaseColor", selectedShowcaseConcess.id, selectedShowcaseIndex, {
                            r = finalR, g = finalG, b = finalB
                        })

                        ShowConcessNotification("Couleur du véhicule mise à jour", false)

                        showcasePointMenu.close()
                        SetTimeout(500, function()
                            showcaseSubMenu.open()
                        end)
                    end
                )
            end
        )

        showcasePointMenu.Checkbox(
            "Faire tourner le véhicule",
            point.rotate and "Le véhicule tourne sur lui-même" or "Le véhicule reste fixe",
            false,
            point.rotate == true,
            function(checked)
                point.rotate = checked == true
                selectedShowcaseConcess.showcase[selectedShowcaseIndex].rotate = point.rotate
                TriggerServerEvent(
                    "core:concess:updateShowcaseRotate",
                    selectedShowcaseConcess.id,
                    selectedShowcaseIndex,
                    point.rotate
                )
                showcasePointMenu.refresh()
            end
        )

        showcasePointMenu.Button(
            "Supprimer ce point",
            "Supprimer le point d'exposition",
            nil,
            "trash",
            false,
            function()
                -- Supprimer cote serveur (le serveur notifiera tous les clients)
                TriggerServerEvent("core:concess:removeShowcasePoint", selectedShowcaseConcess.id, selectedShowcaseIndex)

                ShowConcessNotification("Point d'exposition supprimé.", false)

                -- Retour au menu principal
                showcasePointMenu.close()
                SetTimeout(500, function()
                    showcaseSubMenu.open()
                end)
            end
        )

        showcasePointMenu.Button(
            "Voir le point",
            "Afficher un marqueur pendant 10 sec.",
            nil,
            "chevron",
            false,
            function()
                local markerPoint = { x = point.x, y = point.y, z = point.z }

                showcasePointMenu.close()

                ShowConcessNotification("Point visible pendant 10 sec.", false)

                -- Afficher le marker pendant 10 secondes
                CreateThread(function()
                    local endTime = GetGameTimer() + 10000 -- 10 secondes

                    while GetGameTimer() < endTime do
                        DrawMarker(
                            1, -- Type: cylindre
                            markerPoint.x, markerPoint.y, markerPoint.z - 0.5,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            1.5, 1.5, 2.0,
                            0, 255, 100, 150,
                            false, true, 2, false,
                            nil, nil, false
                        )
                        Wait(0)
                    end
                end)
            end
        )
    end)

    -- Setup showcase submenu
    showcaseSubMenu.OnOpen(function()
        local concess = GetPlayerConcess()

        if not concess then
            showcaseSubMenu.Button("Erreur", "Concessionnaire non trouvé", nil, nil, true, function() end)
            return
        end

        showcaseSubMenu.Separator("VEHICULES EN EXPOSITION")

        if not concess.showcase or #concess.showcase == 0 then
            showcaseSubMenu.Button("Aucun point", "Aucun point d'exposition configuré", nil, nil, true, function() end)
        else
            for i, point in ipairs(concess.showcase) do
                local modelName = point.model or "Aucun"
                local displayName = GetLabelText(GetDisplayNameFromVehicleModel(joaat(modelName)))
                if displayName == "NULL" then displayName = modelName end

                showcaseSubMenu.Button(
                    "Point #" .. i .. " - " .. displayName,
                    (point.rotate and "Rotation activée · " or "") .. "Modèle : " .. modelName,
                    nil,
                    "chevron",
                    false,
                    function()
                        selectedShowcaseIndex = i
                        selectedShowcaseConcess = concess
                    end,
                    showcasePointMenu
                )
            end
        end

        showcaseSubMenu.Separator("AJOUTER UN POINT")

        showcaseSubMenu.Button(
            "Ajouter un point ici",
            "Position actuelle du joueur",
            nil,
            "chevron",
            false,
            function()
                local sModel = VFW.Nui.KeyboardInput(true, "Modèle du véhicule (ex: adder)", "")
                if sModel and sModel ~= "" then
                    sModel = sModel:lower()

                    -- Verifier si le modele est valide
                    local modelHash = joaat(sModel)
                    if not IsModelValid(modelHash) or not IsModelAVehicle(modelHash) then
                        ShowConcessNotification("Ce modèle de véhicule n'est pas valide : " .. sModel, true)
                        return
                    end

                    local pos = GetEntityCoords(PlayerPedId())
                    local heading = GetEntityHeading(PlayerPedId())

                    TriggerServerEvent("core:concess:addShowcasePoint", concess.id, {
                        x = pos.x,
                        y = pos.y,
                        z = pos.z,
                        h = heading,
                        model = sModel
                    })

                    showcaseSubMenu.close()
                end
            end
        )
    end)

    -- ==================== MENU DOUBLE DE CLÉS ====================

    local keysSubMenu = registry.createSubMenuByType("concess", "keys", "Double de clés")
    local playerVehiclesMenu = registry.createSubMenuByType("concess", "playerVehicles", "Véhicules du client")

    -- Variables pour stocker la selection
    local selectedPlayer = nil
    local selectedPlayerName = nil

    -- Menu des vehicules du joueur selectionne
    playerVehiclesMenu.OnOpen(function()
        if not selectedPlayer then
            playerVehiclesMenu.close()
            return
        end

        local vehicles = TriggerServerCallback("core:concess:getPlayerVehicles", selectedPlayer)

        playerVehiclesMenu.Separator("Véhicules de " .. (selectedPlayerName or "Client"))

        if not vehicles or #vehicles == 0 then
            playerVehiclesMenu.Button("Aucun véhicule", "Ce joueur n'a pas de véhicule", nil, nil, true, function() end)
        else
            for _, veh in ipairs(vehicles) do
                local model = veh.model or veh.name or ""
                local label
                if Garage and Garage.GetVehicleLabel then
                    label = Garage.GetVehicleLabel(model)
                end
                if not label or label == "" then
                    local make = GetMakeNameFromVehicleModel(model) or ""
                    if make == "NULL" then make = "" end
                    local name = GetLabelText(model) or model
                    if name == "NULL" or name == "" then name = model end
                    label = (make ~= "" and (make .. " " .. name)) or name
                end
                if not label or label == "" then label = "Véhicule" end

                playerVehiclesMenu.Button(
                    label,
                    "Plaque: " .. veh.plate,
                    nil,
                    "chevron",
                    false,
                    function()
                        -- Confirmation
                        local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer le double de clé", "")
                        if confirm and confirm:upper() == "OUI" then
                            TriggerServerEvent("core:concess:giveKeyDuplicate", selectedPlayer, veh.plate)
                            playerVehiclesMenu.close()
                        end
                    end
                )
            end
        end
    end)

    -- Menu principal des joueurs proches
    keysSubMenu.OnOpen(function()
        local nearbyPlayers = TriggerServerCallback("core:concess:getNearbyPlayersForKeys")

        keysSubMenu.Separator("PERSONNES À PROXIMITÉ")

        if not nearbyPlayers or #nearbyPlayers == 0 then
            keysSubMenu.Button("Aucune personne", "Aucune personne à proximité", nil, nil, true, function() end)
        else
            for _, player in ipairs(nearbyPlayers) do
                keysSubMenu.Button(
                    player.name,
                    "ID: " .. player.id,
                    nil,
                    "chevron",
                    false,
                    function()
                        selectedPlayer = player.id
                        selectedPlayerName = player.name
                    end,
                    playerVehiclesMenu
                )
            end
        end
    end)

    -- Fonction pour vérifier si le concess est en mode manuel (employés en service)
    local function IsConcessInManualMode(concess)
        if not concess then return false end
        if concess.automatic then return false end -- Mode auto forcé = pas manuel

        -- Vérifier si des employés sont en service
        local hasEmployeesOnDuty = TriggerServerCallback("core:concess:areEmployeesOnDuty", concess.job)
        return hasEmployeesOnDuty
    end

    -- Register concess menu builder
    registry.registerByType("concess", function(menu, subMenus)
        -- Vérifier si on est en mode manuel pour afficher le bouton catalogue
        local concess = GetPlayerConcess()
        local isManualMode = IsConcessInManualMode(concess)

        if isManualMode then
            menu.Button("Ouvrir le catalogue", "Accéder au catalogue des véhicules", nil, "chevron", false, function()
                TriggerEvent("concess:openCatalogFromMenu")
            end)
        end

        menu.Button("Gestion Exposition", "Gérer les véhicules en vitrine", nil, "chevron", false, function()
        end, subMenus.showcase)

        menu.Button("Gestion des clés", "Créer un double de clés pour un client", nil, "chevron", false, function()
        end, subMenus.keys)
    end, 10)

end)
