local VUI = exports["VUI"]

-- State
local currentProp, gizmoActive, openedMenu, simplePlacing
local selectedDurationType = 1

-- Menu references (defined in _manager.lua)
local CreatePropsMenu = StaffMenu.CreateProps
local PropsListMenu = StaffMenu.PropsList
local PropManage = StaffMenu.PropManage
local EditProp = StaffMenu.EditProp

-- Category sub-menu caches (avoid recreating on every open)
local cachedCategoryMenus = {}
local cachedStaffCategoryMenus = {}
local cachedCreateCategoryMenus = {}
local cachedVipCategoryMenus = {}

-- ============================================================================
-- Helpers
-- ============================================================================

local function GetDefaultValue()
    return {
        id = 0,
        model = nil,
        label = nil,
        position = {
            coords = nil,
            rotation = nil
        },
        duration = nil,
        durationType = 1,
        createdAt = nil,
        expiresAt = nil,
    }
end

local propsData = GetDefaultValue()

local function CleanupPreview()
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
        currentProp = nil
    end
end

local function SafeRefresh(menu)
    if menu.opened then
        openedMenu = true
        menu.refresh()
        openedMenu = false
    end
end

local function GetGroundZ(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    Wait(50)

    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
    if found then
        return groundZ
    end

    local rayHandle = StartShapeTestRay(x, y, z + 50.0, x, y, z - 50.0, 1, 0, 4)
    Wait(0)
    local _, hit, endCoords = GetShapeTestResult(rayHandle)
    if hit then
        return endCoords.z
    end

    return z
end

local function SpawnPropsPreview(model, position)
    CleanupPreview()

    local modelHash = type(model) == "number" and model or GetHashKey(model)
    if not IsModelInCdimage(modelHash) then
        VFW.ShowNotification({
            type = 'ERROR', subtitle = 'Builder Objets',
            message = "Ce modèle n'est pas valide : " .. tostring(model)
        })
        return false
    end

    local groundZ = GetGroundZ(position.x, position.y, position.z)
    local groundPos = vector3(position.x, position.y, groundZ)

    VFW.Game.SpawnLocalObject(model, groundPos, function(props)
        currentProp = props
        PlaceObjectOnGroundProperly(currentProp)
        SetEntityAlpha(currentProp, 150, false)
        FreezeEntityPosition(currentProp, true)
        SetEntityCollision(currentProp, false, true)
        PlaceObjectOnGroundProperly(currentProp)
    end)

    if not currentProp or not DoesEntityExist(currentProp) then
        VFW.ShowNotification({
            type = 'ERROR', subtitle = 'Builder Objets',
            message = "Echec du spawn de l'objet"
      })
        return false
    end

    return true
end

-- ============================================================================
-- Placement modes
-- ============================================================================

local StartSimplePlacement, StartGizmoMode

StartSimplePlacement = function(model, data, menu)
    if not currentProp or not DoesEntityExist(currentProp) then
        VFW.ShowNotification({
            type = 'ERROR', subtitle = 'Builder Objets',
            message = "Aucun objet a positionner"
      })
        return
    end

    openedMenu = true
    simplePlacing = true
    menu.close()

    local _simplePlaceInstructionalId = VFW.AddInstructionalButtons({
        { label = "Poser l'objet", control = 38 },
        { label = "Tourner", control = 241 },
        { label = "Mode avance", control = 47 },
        { label = "Annuler", control = 200 },
    })

    local currentHeading = GetEntityHeading(currentProp)
    local placing = true
    local useGizmo = false

    while placing do
        Wait(0)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local fwd = GetEntityForwardVector(ped)
        local targetPos = pCoords + fwd * 2.5

        SetEntityCoords(currentProp, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
        PlaceObjectOnGroundProperly(currentProp)
        SetEntityHeading(currentProp, currentHeading)

        DisableControlAction(0, 15, true)
        DisableControlAction(0, 16, true)
        if IsDisabledControlJustPressed(0, 15) then
            currentHeading = currentHeading + 15.0
        end
        if IsDisabledControlJustPressed(0, 16) then
            currentHeading = currentHeading - 15.0
        end

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisablePlayerFiring(ped, true)

        -- E = poser
        if VFW.Interact.JustPressed(0, 38) then
            placing = false
        end

        -- G = mode avance (gizmo)
        if IsControlJustPressed(0, 47) then
            placing = false
            useGizmo = true
        end

        -- Escape = annuler
        if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
            placing = false
            VFW.RemoveInstructionalButtons(_simplePlaceInstructionalId)
            simplePlacing = false
            openedMenu = false
            Wait(100)
            menu.open()
            return
        end
    end

    VFW.RemoveInstructionalButtons(_simplePlaceInstructionalId)

    if useGizmo then
        StartGizmoMode(menu)
        return
    end

    data.position = {
        coords = GetEntityCoords(currentProp),
        rotation = GetEntityRotation(currentProp)
    }

    VFW.ShowNotification({
        type = 'SUCCESS', subtitle = 'Builder Objets',
        message = "Position de l'objet mise a jour"
  })

    simplePlacing = false
    openedMenu = false
    Wait(100)
    menu.open()
end

StartGizmoMode = function(menu)
    if not currentProp or not DoesEntityExist(currentProp) then
        VFW.ShowNotification({
            type = 'ERROR', subtitle = 'Builder Objets',
            message = "Aucun objet a modifier"
      })
        return
    end

    gizmoActive = true

    local data <const> = exports["core"]:useGizmo(currentProp)

    gizmoActive = false

    if data and data.switchedBack then
        StartSimplePlacement(propsData.model, propsData, menu)
    elseif data and data.handle and DoesEntityExist(data.handle) then
        propsData.position = {
            coords = data.position,
            rotation = data.rotation
        }

        VFW.ShowNotification({
            type = 'SUCCESS', subtitle = 'Builder Objets',
            message = "Position de l'objet mise a jour"
      })

        simplePlacing = false
        openedMenu = false
        Wait(100)
        menu.open()
    else
        if not DoesEntityExist(currentProp) then
            currentProp = nil
            propsData.model = nil
        end

        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Builder Objets',
            message = "Modification annulée"
      })

        simplePlacing = false
        openedMenu = false
        Wait(100)
        menu.open()
    end
end

-- ============================================================================
-- Props form (shared between Create and Edit)
-- ============================================================================

local function BuildPropsForm(menu, data, vip, categoryMenu)
    vip = vip or false
    menu.Separator("Information")

    menu.Button("Nom de l'objet", data.label or "Aucun nom defini", nil, nil, false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom de l'objet (ex: Carton n1)", data.label or "")

        if not label or label == "" then
            VFW.ShowNotification({
                type = 'ERROR', subtitle = 'Builder Objets',
                message = "Ce nom n'est pas valide"
          })
            return
        end

        data.label = label

        -- Force re-open du menu pour afficher le nouveau label
        openedMenu = true
        menu.close()
        Wait(100)
        menu.open()
    end)

    menu.Button("Modèle de l'objet", data.model or "Aucun modèle sélectionné", nil, nil, false, function()
        if vip then
            if categoryMenu then
                openedMenu = true
                categoryMenu.open()
            end
            return
        end

        local model <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom du modèle (ex: prop_bench_01a)", data.model or "")

        if not model or model == "" then
            VFW.ShowNotification({
                type = 'ERROR', subtitle = 'Builder Objets',
                message = "Ce modèle n'est pas valide"
          })
            return
        end

        local spawnPos = data.position and data.position.coords or (GetEntityCoords(PlayerPedId()) + vector3(0.0, 2.0, 0.0))
        local success <const> = SpawnPropsPreview(model, spawnPos)

        if success then
            data.model = model
            data.position = {
                coords = GetEntityCoords(currentProp),
                rotation = GetEntityRotation(currentProp)
            }
            StartSimplePlacement(model, data, menu)
        end
    end)

    -- Bouton categories pour le staff (en plus de l'entree manuelle)
    if not vip then
        local staffCatMenu = categoryMenu or StaffMenu.CategorySelection
        menu.Button("Parcourir les catégories", "Choisir un modèle depuis les catégories", nil, "chevron", false, function()
            openedMenu = true
        end, staffCatMenu)
    end

    menu.Button("Modifier la position", "", nil, "chevron", not currentProp or not DoesEntityExist(currentProp), function()
        if not currentProp or not DoesEntityExist(currentProp) then
            VFW.ShowNotification({
                type = 'ERROR', subtitle = 'Builder Objets',
                message = "Veuillez d'abord sélectionner un modèle"
          })
            return
        end

        StartSimplePlacement(data.model, data, menu)
    end)

    menu.Button("Reinitialiser la position", nil, nil, "chevron", not currentProp or not DoesEntityExist(currentProp), function()
        if currentProp and DoesEntityExist(currentProp) then
            SetEntityCoords(currentProp, GetEntityCoords(PlayerPedId()) + vector3(0.0, 2.0, 0.0), false, false, false, false)
            PlaceObjectOnGroundProperly(currentProp)
            data.position = {
                coords = GetEntityCoords(currentProp),
                rotation = GetEntityRotation(currentProp)
            }
            SafeRefresh(menu)
        end
    end)

    local typeDuration = {"Temporaire (supprimé au redémarrage)", "À durée limitée (1-15 jours)", "Permanent (jamais supprimé)"}

    if vip then
        typeDuration = {"Temporaire (supprimé au redémarrage)", "À durée limitée (1-15 jours)"}
    end

    menu.List("Type de durée", nil, false, typeDuration, data.durationType, function(Index)
        data.durationType = Index
        if Index ~= 2 then
            data.duration = nil
        end
        SafeRefresh(menu)
    end)

    if data.durationType == 2 then
        local durationLabel = data.duration and (data.duration .. (data.duration > 1 and " jours" or " jour")) or "Non défini"
      menu.Button("Définir la durée", durationLabel, nil, "chevron", false, function()
            local duration <const> = tonumber(VFW.Nui.KeyboardInput(true, "Durée en jours (1-15)", tostring(data.duration or 1)))

            if not duration or type(duration) ~= "number" then
                VFW.ShowNotification({
                    type = 'ERROR', subtitle = 'Builder Objets',
                    message = "Cette durée n'est pas valide."
              })
                return
            end

            local clampedDuration <const> = math.max(1, math.min(15, duration))
            data.duration = clampedDuration

            VFW.ShowNotification({
                type = 'SUCCESS', subtitle = 'Builder Objets',
                message = (clampedDuration > 1 and "Durée définie : %s jours." or "Durée définie : %s jour."):format(clampedDuration)
            })
            SafeRefresh(menu)
        end)
    end

    if data.durationType == 2 and data.duration then
        menu.Title("Durée sélectionnée", data.duration .. (data.duration > 1 and " jours" or " jour"), "", "")
    end
end

-- ============================================================================
-- Category selection menu builder (cached sub-menus)
-- ============================================================================

local function BuildCategorySelectionMenu(catMenu, parentMenu, cacheTable)
    local config <const> = TriggerServerCallback("propsBuilder:getConfig")

    if not config or not config.PropsList then
        catMenu.Separator("Erreur de chargement")
        return
    end

    catMenu.Separator("Sélectionner une catégorie")

    for categoryName, propsInCategory in pairs(config.PropsList) do
        -- Cache sub-menus per category to avoid memory leak
        local cacheKey = categoryName
        if not cacheTable[cacheKey] then
            cacheTable[cacheKey] = VUI:CreateSubMenu(catMenu, categoryName, exports["core"]:GetVUIBanner("admin"), true)

            local categoryPropsMenu = cacheTable[cacheKey]

            categoryPropsMenu.OnOpen(function()
                categoryPropsMenu.ClearItems()
                categoryPropsMenu.Separator("Objets disponibles")

                for propModel, propLabel in pairs(propsInCategory) do
                    categoryPropsMenu.Button(propLabel, propModel, nil, nil, false, function()
                        propsData.model = propModel

                        local spawnPos = propsData.position and propsData.position.coords or (GetEntityCoords(PlayerPedId()) + vector3(0.0, 2.0, 0.0))
                        local success <const> = SpawnPropsPreview(propModel, spawnPos)

                        if success then
                            propsData.position = {
                                coords = GetEntityCoords(currentProp),
                                rotation = GetEntityRotation(currentProp)
                            }
                        end

                        openedMenu = true
                        categoryPropsMenu.close()
                        catMenu.close()

                        if success then
                            StartSimplePlacement(propModel, propsData, parentMenu)
                        else
                            openedMenu = false
                            Wait(100)
                            parentMenu.open()
                        end
                    end)
                end
            end)
        end

        catMenu.Button(categoryName, nil, nil, "chevron", false, function()
            cacheTable[cacheKey].open()
        end)
    end
end

-- ============================================================================
-- Staff Menus
-- ============================================================================

function StaffMenu.BuildPropsMenu()
    StaffMenu.builderProps.Separator("Actions")
    StaffMenu.builderProps.Button("Créer un objet", "Placer un nouvel objet", nil, "chevron", false, nil, StaffMenu.CreateProps)
    StaffMenu.builderProps.Button("Liste des objets", "Gérer tous les objets", nil, "chevron", false, nil, StaffMenu.PropsList)
    StaffMenu.builderProps.Button("Props VIP", "Voir les props posés par les joueurs VIP", nil, "chevron", false, nil, StaffMenu.VipPropsList)
end

-- ============================================================================
-- Create Props Menu
-- ============================================================================

CreatePropsMenu.OnOpen(function()
    openedMenu = false

    BuildPropsForm(CreatePropsMenu, propsData, false, StaffMenu.CreateCategorySelection)

    CreatePropsMenu.Separator("Action")

    local canCreate <const> = propsData.model and propsData.durationType and propsData.position and propsData.position.coords
    local needsDuration = propsData.durationType == 2 and not propsData.duration

    CreatePropsMenu.Button("Créer l'objet", "Placer l'objet à votre position", nil, "check", not canCreate or needsDuration, function()
        if not canCreate or needsDuration then
            return VFW.ShowNotification({
                type = "ERROR", subtitle = 'Builder Objets',
                message = "Veuillez remplir tous les champs obligatoires"
          })
        end

        TriggerServerEvent('core:propsBuilder:createProp', propsData)

        CleanupPreview()
        propsData = GetDefaultValue()
    end, StaffMenu.builderProps)

    CreatePropsMenu.Button("Annuler", nil, nil, "chevron", false, function()
        propsData = GetDefaultValue()
        CreatePropsMenu.close()
    end)
end)

CreatePropsMenu.OnClose(function()
    if openedMenu or gizmoActive or simplePlacing then
        return
    end

    CleanupPreview()
    propsData = GetDefaultValue()
end)

-- ============================================================================
-- Props List Menu
-- ============================================================================

PropsListMenu.OnOpen(function()
    local propsList <const> = TriggerServerCallback("propsBuilder:getPropsList") or {}

    if not next(propsList) then
        PropsListMenu.Separator("LISTE DES OBJETS")
        PropsListMenu.Button("Aucun objet sur le serveur", "Il n'y a actuellement aucun objet pose", nil, nil, false, function() end)
        return
    end

    local categories = {0, 0, 0}

    for _, prop in pairs(propsList) do
        local dt = prop.durationType
        if dt and dt >= 1 and dt <= 3 then
            categories[dt] = categories[dt] + 1
        end
    end

    PropsListMenu.Separator("STATISTIQUES")
    PropsListMenu.Textbox(("Temporaires: %s | À durée limitée: %s | Permanents: %s"):format(
        categories[1],
        categories[2],
        categories[3]
    ), "STATISTIQUES")

    PropsListMenu.Separator("FILTRE")

    local filterOptions <const> = {"Tous les objets", "Temporaires", "À durée limitée", "Permanents" }
    PropsListMenu.List("Filtrer par type", nil, false, filterOptions, selectedDurationType, function(Index)
        selectedDurationType = Index
        SafeRefresh(PropsListMenu)
    end)

    local filteredProps = {}
    for _, prop in pairs(propsList) do
        local shouldShow = false

        if selectedDurationType == 1 then
            shouldShow = true
        elseif selectedDurationType == 2 and prop.durationType == 1 then
            shouldShow = true
        elseif selectedDurationType == 3 and prop.durationType == 2 then
            shouldShow = true
        elseif selectedDurationType == 4 and prop.durationType == 3 then
            shouldShow = true
        end

        if shouldShow then
            filteredProps[#filteredProps + 1] = prop
        end
    end

    PropsListMenu.Separator("LISTE DES OBJETS")

    if #filteredProps == 0 then
        PropsListMenu.Button("AUCUN OBJET CORRESPONDANT", "Aucun objet ne correspond au filtre sélectionné", nil, nil, true, function() end)
        return
    end

    local displayedTypes = {}

    for _, prop in pairs(filteredProps) do
        local durationType <const> = prop.durationType

        if not displayedTypes[durationType] then
            displayedTypes[durationType] = true
            local typeLabel = durationType == 1 and "TEMPORAIRES" or
                    durationType == 2 and "A DUREE LIMITEE" or
                    "PERMANENTS"
          PropsListMenu.Separator(typeLabel)
        end

        local propLabel = prop.label or "Objet sans nom"
      local propModel = prop.model or "Inconnu"

      local typeIcon = durationType == 1 and "[T]" or
                durationType == 2 and "[D]" or
                "[P]"

      local subtitleParts = {}
        table.insert(subtitleParts, propModel)

        if prop.owner then
            table.insert(subtitleParts, "Par: " .. tostring(prop.owner))
        end

        if prop.durationType == 2 and prop.expiresAt then
            table.insert(subtitleParts, "Exp: " .. prop.expiresAt)
        end

        local subtitle = table.concat(subtitleParts, " | ")

        PropsListMenu.Button(typeIcon .. " " .. propLabel, subtitle, nil, "chevron", false, function()
            propsData = prop
        end, PropManage)
    end
end)

-- ============================================================================
-- Prop Manage Menu
-- ============================================================================

PropManage.OnOpen(function()
    if not propsData then
        return
    end

    SpawnPropsPreview(propsData.model, propsData.position.coords or (GetEntityCoords(PlayerPedId()) + vector3(0.0, 2.0, 0.0)))

    local typeName = propsData.durationType == 1 and "Temporaire" or
            propsData.durationType == 2 and "À durée limitée" or
            "Permanent"

  local typeIcon = propsData.durationType == 1 and "[T]" or
            propsData.durationType == 2 and "[D]" or
            "[P]"

  PropManage.Separator("Informations")
    PropManage.Button("Nom", propsData.label or "Sans nom", nil, nil, true, function() end)
    PropManage.Button("Modèle", propsData.model, nil, nil, true, function() end)
    PropManage.Button(typeIcon .. " Type", typeName, nil, nil, true, function() end)

    if propsData.durationType == 2 and propsData.expiresAt then
        PropManage.Button("Expire le", propsData.expiresAt, nil, nil, true, function() end)
    end

    if propsData.createdAt then
        PropManage.Button("Créé le", propsData.createdAt, nil, nil, true, function() end)
    end

    if propsData.owner then
        PropManage.Button("Proprietaire", tostring(propsData.owner), nil, nil, true, function() end)
    end

    PropManage.Button("ID Objet", tostring(propsData.id), nil, nil, true, function() end)

    PropManage.Separator("Actions")

    PropManage.Button("Teleportation", "Se teleporter a l'objet", nil, "chevron", false, function()
        if not propsData.position or not propsData.position.coords then
            return VFW.ShowNotification({
                type = 'ERROR', subtitle = 'Builder Objets',
                message = "Aucune position définie"
          })
        end

        SetEntityCoords(PlayerPedId(), propsData.position.coords.x, propsData.position.coords.y, propsData.position.coords.z + 1.0, false, false, false, false)

        VFW.ShowNotification({
            type = 'SUCCESS', subtitle = 'Builder Objets',
            message = "Téléporté à l'objet"
      })
    end)

    PropManage.Button("Modifier", "Modifier les propriétés de l'objet", nil, "chevron", false, function()
    end, EditProp)

    PropManage.Button("Supprimer", "Supprimer définitivement l'objet", nil, "chevron", false, function()
        local confirmed = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer la suppression", "")
        if confirmed ~= "OUI" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Builder Objets',
                message = "Suppression annulée"
          })
            return
        end

        TriggerServerEvent("propsBuilder:deleteProp", propsData.id)
        CleanupPreview()
        propsData = GetDefaultValue()
    end, PropsListMenu)
end)

PropManage.OnClose(function()
    if openedMenu or gizmoActive or simplePlacing then
        return
    end

    CleanupPreview()
end)

-- ============================================================================
-- Edit Prop Menu
-- ============================================================================

EditProp.OnOpen(function()
    openedMenu = false

    if not propsData or not propsData.id then
        return
    end

    SpawnPropsPreview(propsData.model, propsData.position.coords or (GetEntityCoords(PlayerPedId()) + vector3(0.0, 2.0, 0.0)))

    BuildPropsForm(EditProp, propsData, false)

    EditProp.Separator("Actions")

    EditProp.Button("Sauvegarder", "Enregistrer les modifications", nil, "check", false, function()
        TriggerServerEvent('propsBuilder:updateProp', propsData.id, propsData)
        CleanupPreview()
        propsData = GetDefaultValue()
    end, PropsListMenu)

    EditProp.Button("Annuler", "Annuler les modifications", nil, nil, false, function()
        CleanupPreview()
        propsData = GetDefaultValue()
        EditProp.close()
    end)
end)

EditProp.OnClose(function()
    if openedMenu or gizmoActive or simplePlacing then
        return
    end

    CleanupPreview()
    propsData = GetDefaultValue()
end)

-- ============================================================================
-- Category Selection Menus (staff)
-- ============================================================================

StaffMenu.CategorySelection.OnOpen(function()
    StaffMenu.CategorySelection.ClearItems()
    BuildCategorySelectionMenu(StaffMenu.CategorySelection, EditProp, cachedStaffCategoryMenus)
end)

StaffMenu.CreateCategorySelection.OnOpen(function()
    StaffMenu.CreateCategorySelection.ClearItems()
    BuildCategorySelectionMenu(StaffMenu.CreateCategorySelection, CreatePropsMenu, cachedCreateCategoryMenus)
end)

-- ============================================================================
-- VIP exported functions
-- ============================================================================

function renderPropsBuilderMenu(menu, createMenu, manageMenu)
    local config = TriggerServerCallback("propsBuilder:getConfig")
    local stats = TriggerServerCallback("propsBuilder:getPlayerStats")

    if not config or not stats then
        menu.Separator("Erreur de chargement")
        return
    end

    local currentCount = {temporary = stats.temporary or 0, permanent = stats.permanent or 0}
    local limits = stats.limits or {temporary = 0, permanent = 0}

    local tier = tonumber(VFW.PlayerGlobalData.vip_tier) or 0
    local tierLabel = VIPConfig.GetTierLabel(tier)

    menu.Separator("Actions")

    menu.Button("Créer un objet", "Placer un nouvel objet", nil, "chevron", false, function()
    end, createMenu)

    if manageMenu then
        menu.Button("Gérer mes objets", "Voir et supprimer mes objets", nil, "chevron", false, function()
        end, manageMenu)
    end

    menu.Separator("Vos statistiques")
    menu.Button(
            string.format("Objets temporaires: %d/%d", currentCount.temporary, limits.temporary),
            tierLabel,
            nil, nil, false, function() end
    )
    menu.Button(
            string.format("Objets permanents: %d/%d", currentCount.permanent, limits.permanent),
            tierLabel,
            nil, nil, false, function() end
    )
end

function renderPropsCreateProps(menu, categoryMenu, parentMenu)
    BuildPropsForm(menu, propsData, true, categoryMenu)

    menu.Separator("Action")

    local canCreate <const> = propsData.model and propsData.durationType and propsData.position and propsData.position.coords
    local needsDuration = propsData.durationType == 2 and not propsData.duration

    menu.Button("Créer l'objet", "Placer l'objet à votre position", nil, "check", not canCreate or needsDuration, function()
        if not canCreate or needsDuration then
            return VFW.ShowNotification({
                type = 'ERROR', subtitle = 'Builder Objets',
                message = "Veuillez remplir tous les champs obligatoires"
          })
        end

        TriggerServerEvent('core:propsBuilder:createProp', propsData)

        CleanupPreview()
        propsData = GetDefaultValue()

        if parentMenu then
            menu.close()
            Wait(100)
            parentMenu.open()
        else
            menu.close()
        end
    end)

    menu.Button("Annuler", nil, nil, "chevron", false, function()
        propsData = GetDefaultValue()
        menu.close()
    end)

    menu.OnClose(function()
        if openedMenu or gizmoActive or simplePlacing then
            return
        end

        CleanupPreview()
    end)
end

function renderCategorySelectionMenu(menu, parentMenu)
    local config <const> = TriggerServerCallback("propsBuilder:getConfig")

    if not config or not config.PropsList then
        menu.Separator("Erreur de chargement")
        return
    end

    local returnMenu = parentMenu or menu
    local previewProp = nil

    local function cleanPreview()
        if previewProp and DoesEntityExist(previewProp) then
            DeleteEntity(previewProp)
            previewProp = nil
        end
    end

    local function spawnPreview(model)
        cleanPreview()
        local modelHash = type(model) == "number" and model or GetHashKey(model)
        if not IsModelInCdimage(modelHash) then return end

        local playerPos = GetEntityCoords(PlayerPedId())
        local forward = GetEntityForwardVector(PlayerPedId())
        local spawnPos = playerPos + forward * 2.0

        VFW.Game.SpawnLocalObject(model, spawnPos, function(obj)
            cleanPreview()
            previewProp = obj
            PlaceObjectOnGroundProperly(previewProp)
            SetEntityAlpha(previewProp, 150, false)
            FreezeEntityPosition(previewProp, true)
            SetEntityCollision(previewProp, false, true)
        end)
    end

    menu.Separator("Sélectionner une catégorie")

    for categoryName, propsInCategory in pairs(config.PropsList) do
        -- Cache VIP category sub-menus
        local cacheKey = categoryName
        if not cachedVipCategoryMenus[cacheKey] then
            cachedVipCategoryMenus[cacheKey] = VUI:CreateSubMenu(menu, categoryName, exports["core"]:GetVUIBanner("admin"), true)

            local categoryPropsMenu = cachedVipCategoryMenus[cacheKey]

            categoryPropsMenu.OnOpen(function()
                categoryPropsMenu.ClearItems()
                categoryPropsMenu.Separator("Objets disponibles")

                local modelsByIndex = {}
                local idx = 2

                for propModel, propLabel in pairs(propsInCategory) do
                    modelsByIndex[idx] = propModel
                    idx = idx + 1

                    categoryPropsMenu.Button(propLabel, propModel, nil, nil, false, function()
                        cleanPreview()
                        propsData.model = propModel

                        local spawnPos = propsData.position and propsData.position.coords or (GetEntityCoords(PlayerPedId()) + vector3(0.0, 2.0, 0.0))
                        local success <const> = SpawnPropsPreview(propModel, spawnPos)

                        if success then
                            propsData.position = {
                                coords = GetEntityCoords(currentProp),
                                rotation = GetEntityRotation(currentProp)
                            }
                        end

                        openedMenu = true
                        categoryPropsMenu.close()
                        menu.close()

                        if success then
                            StartSimplePlacement(propModel, propsData, returnMenu)
                        else
                            openedMenu = false
                            Wait(100)
                            returnMenu.open()
                        end
                    end)
                end

                if modelsByIndex[2] then
                    spawnPreview(modelsByIndex[2])
                end

                categoryPropsMenu.OnIndexChange(function(index, item)
                    local model = modelsByIndex[index]
                    if model then
                        spawnPreview(model)
                    end
                end)

                categoryPropsMenu.OnClose(function()
                    cleanPreview()
                end)
            end)
        end

        menu.Button(categoryName, nil, nil, "chevron", false, function()
            cachedVipCategoryMenus[cacheKey].open()
        end)
    end

    menu.OnClose(function()
        cleanPreview()
    end)
end

function renderManageMyPropsMenu(menu)
    local playerProps = TriggerServerCallback("propsBuilder:getPlayerProps")

    if not playerProps or next(playerProps) == nil then
        menu.Separator("Aucun objet")
        menu.Button("Vous n'avez créé aucun objet", "Créez-en un via le menu principal", nil, nil, true, function() end)
        return
    end

    local propsCount = 0
    for _ in pairs(playerProps) do
        propsCount = propsCount + 1
    end

    menu.Separator("Mes objets (" .. propsCount .. ")")

    -- Cache detail menus per prop
    local detailMenuCache = {}

    for propId, propInstance in pairs(playerProps) do
        local propLabel = propInstance.label or "Objet sans nom"
      local propModel = propInstance.model or "Inconnu"
      local durationType = propInstance.durationType or 1
        local durationText = ""

      if durationType == 1 or propInstance.isTemporary then
            durationText = "[T] Temporaire"
      elseif propInstance.expiresAtRaw and propInstance.expiresAtRaw >= 4102444799000 then
            durationText = "[P] Permanent"
      else
            local expirationDate = propInstance.expiresAt or "N/A"
          durationText = "[D] Expire: " .. expirationDate
        end

        menu.Button(
            propLabel,
            durationText,
            nil,
            nil,
            false,
            function()
                if not detailMenuCache[propId] then
                    detailMenuCache[propId] = VUI:CreateSubMenu(menu, propLabel, exports["core"]:GetVUIBanner("admin"), true)

                    local propDetailMenu = detailMenuCache[propId]

                    propDetailMenu.OnOpen(function()
                        propDetailMenu.ClearItems()
                        propDetailMenu.Separator("Informations")
                        propDetailMenu.Button("Nom", propLabel, nil, nil, true, function() end)
                        propDetailMenu.Button("Modèle", propModel, nil, nil, true, function() end)
                        propDetailMenu.Button("Type", durationText, nil, nil, true, function() end)
                        propDetailMenu.Button("Créé le", propInstance.createdAt or "N/A", nil, nil, true, function() end)

                        propDetailMenu.Separator("Actions")

                        propDetailMenu.Button("Supprimer cet objet", "Action irréversible", nil, nil, false, function()
                            local confirmed = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer", "")
                            if confirmed ~= "OUI" then
                                VFW.ShowNotification({
                                    type = 'STAFF', variant = 'INFO', subtitle = 'Builder Objets',
                                    message = "Suppression annulée"
                              })
                                return
                            end

                            TriggerServerEvent("propsBuilder:deleteProp", propId)
                            Wait(100)
                            propDetailMenu.close()
                            SafeRefresh(menu)
                        end)

                        propDetailMenu.Button("Retour", nil, nil, "chevron", false, function()
                            propDetailMenu.close()
                        end)
                    end)
                end

                detailMenuCache[propId].open()
            end
        )
    end
end

-- ============================================================================
-- Staff: Props VIP - Liste par joueur
-- ============================================================================

StaffMenu.VipPropsList.OnOpen(function()
    StaffMenu.VipPropsList.ClearItems()

    local allProps = TriggerServerCallback("propsBuilder:getPropsList")

    if not allProps or #allProps == 0 then
        StaffMenu.VipPropsList.Separator("Aucun prop")
        StaffMenu.VipPropsList.Button("Aucun prop posé", nil, nil, nil, true, function() end)
        return
    end

    -- Grouper par owner
    local byOwner = {}
    local ownerOrder = {}

    for _, prop in ipairs(allProps) do
        local owner = prop.owner or "Inconnu"
      if not byOwner[owner] then
            byOwner[owner] = {}
            ownerOrder[#ownerOrder + 1] = owner
        end
        byOwner[owner][#byOwner[owner] + 1] = prop
    end

    table.sort(ownerOrder)

    StaffMenu.VipPropsList.Separator(("Total : %d props"):format(#allProps))

    for _, owner in ipairs(ownerOrder) do
        local props = byOwner[owner]
        StaffMenu.VipPropsList.Button(
            owner,
            (#props > 1 and "%d objets" or "%d objet"):format(#props),
            nil, "chevron", false,
            function()
                StaffMenu._vipPropsPlayerData = props
                StaffMenu._vipPropsPlayerName = owner
            end,
            StaffMenu.VipPropsPlayer
        )
    end
end)

StaffMenu.VipPropsPlayer.OnOpen(function()
    StaffMenu.VipPropsPlayer.ClearItems()

    local props = StaffMenu._vipPropsPlayerData or {}
    local playerName = StaffMenu._vipPropsPlayerName or "Joueur"

  StaffMenu.VipPropsPlayer.Separator((#props > 1 and "%s - %d objets" or "%s - %d objet"):format(playerName, #props))

    for _, prop in ipairs(props) do
        local label = prop.label or prop.model or "Sans nom"
      local durationType = tonumber(prop.durationType) or 0
        local durationText = durationType == 1 and "[T]" or durationType == 2 and "[D]" or "[P]"

      StaffMenu.VipPropsPlayer.Button(
            durationText .. " " .. label,
            prop.model or "",
            nil, "chevron", false,
            function()
                StaffMenu._vipPropDetailData = prop
            end,
            StaffMenu.VipPropDetail
        )
    end
end)

StaffMenu.VipPropDetail.OnOpen(function()
    StaffMenu.VipPropDetail.ClearItems()

    local prop = StaffMenu._vipPropDetailData
    if not prop then return end

    local durationType = tonumber(prop.durationType) or 0
    local typeLabel = durationType == 1 and "Temporaire" or durationType == 2 and "À durée limitée" or "Permanent"

  StaffMenu.VipPropDetail.Separator("Informations")
    StaffMenu.VipPropDetail.Button("Nom", prop.label or "Sans nom", nil, nil, true, function() end)
    StaffMenu.VipPropDetail.Button("Modèle", prop.model or "Inconnu", nil, nil, true, function() end)
    StaffMenu.VipPropDetail.Button("Type", typeLabel, nil, nil, true, function() end)
    StaffMenu.VipPropDetail.Button("Propriétaire", prop.owner or "Inconnu", nil, nil, true, function() end)

    if prop.createdAt then
        local createdDate = type(prop.createdAt) == "number"
          and os.date("%d/%m/%Y %H:%M", prop.createdAt / 1000)
            or tostring(prop.createdAt)
        StaffMenu.VipPropDetail.Button("Créé le", createdDate, nil, nil, true, function() end)
    end

    StaffMenu.VipPropDetail.Separator("Actions")

    -- Téléportation
    if prop.position then
        StaffMenu.VipPropDetail.Button("Se téléporter", "Aller à l'objet", nil, "chevron", false, function()
            local coords = prop.position.coords
            if not coords then
                VFW.ShowNotification({ type = 'ERROR', subtitle = 'Props VIP', message = "Cette position n'est pas valide" })
                return
            end
            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0, false, false, false, false)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Props VIP', message = "Téléporté à l'objet" })
        end)
    end

    -- Supprimer
    StaffMenu.VipPropDetail.Button("Supprimer", "Supprimer pour tout le monde", nil, "chevron", false, function()
        local confirmed = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer la suppression", "")
        if not confirmed or string.upper(confirmed) ~= "OUI" then
            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Props VIP', message = "Suppression annulée" })
            return
        end

        TriggerServerEvent("propsBuilder:deleteProp", prop.id)

        Wait(200)
        StaffMenu.VipPropDetail.close()
        Wait(100)
        -- Refresh la liste du joueur
        StaffMenu.VipPropsPlayer.close()
        Wait(100)
        StaffMenu.VipPropsList.close()
    end)
end)
