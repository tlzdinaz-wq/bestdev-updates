---@meta _
---@diagnostic disable: duplicate-doc-field

local legalStationData = {
    name = nil,
    description = nil,
    propModel = nil,
    coords = nil,
    markerCoords = nil,
    interactionDistance = 2.0,
    jobRestriction = nil,
    jobGradeMin = nil,
    recipes = {},
    blipEnabled = false,
    blipSprite = 1,
    blipColor = 1,
    blipScale = 0.8,
    blipLabel = nil,
    isUpdate = false,
    id = nil
}

local cachedJobs = nil
local cachedJobGrades = {}
local cachedLegalStations = {}
local cachedRecipes = {}
local cachedItems = nil
local cachedPresets = nil
local currentLegalStation = nil
local currentLegalRecipe = nil

local legalStationPreviewProp = nil
local legalAnimPreviewPed = nil
local legalPendingAnimation = nil

local function DeleteLegalAnimPreview()
    if legalAnimPreviewPed and DoesEntityExist(legalAnimPreviewPed) then
        DeleteEntity(legalAnimPreviewPed)
        legalAnimPreviewPed = nil
    end
end

local function CreateLegalAnimPreview()
    DeleteLegalAnimPreview()

    local playerPed = PlayerPedId()
    local playerHeading = GetEntityHeading(playerPed)

    -- Spawner le ped à la station si les coords sont dispo, sinon proche du joueur
    local previewX, previewY, previewZ, previewH
    if legalStationData and legalStationData.coords and legalStationData.coords.x then
        previewX = legalStationData.coords.x
        previewY = legalStationData.coords.y
        previewZ = legalStationData.coords.z
        previewH = (legalStationData.rotationZ or playerHeading) + 180.0
    else
        local offset = GetOffsetFromEntityInWorldCoords(playerPed, 1.0, 1.5, 0.0)
        previewX = offset.x
        previewY = offset.y
        previewZ = offset.z
        previewH = playerHeading + 180.0
    end

    local model = GetEntityModel(playerPed)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 50 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end

    legalAnimPreviewPed = CreatePed(4, model, previewX, previewY, previewZ, previewH, false, false)

    if legalAnimPreviewPed and DoesEntityExist(legalAnimPreviewPed) then
        SetEntityAlpha(legalAnimPreviewPed, 180, false)
        SetEntityInvincible(legalAnimPreviewPed, true)
        FreezeEntityPosition(legalAnimPreviewPed, true)
        SetEntityCollision(legalAnimPreviewPed, false, false)
        SetBlockingOfNonTemporaryEvents(legalAnimPreviewPed, true)
        SetPedCanRagdoll(legalAnimPreviewPed, false)
        ClonePedToTarget(playerPed, legalAnimPreviewPed)
    end

    SetModelAsNoLongerNeeded(model)
end

local legalCurrentAnimDict = nil
local legalCurrentAnimName = nil

local function PlayLegalAnimOnPreview(dict, anim)
    if not dict or dict == "" or not anim or anim == "" then return end
    if dict == legalCurrentAnimDict and anim == legalCurrentAnimName then return end

    legalCurrentAnimDict = dict
    legalCurrentAnimName = anim

    Citizen.CreateThread(function()
        if not legalAnimPreviewPed or not DoesEntityExist(legalAnimPreviewPed) then
            CreateLegalAnimPreview()
            Citizen.Wait(200)
        end

        if not legalAnimPreviewPed or not DoesEntityExist(legalAnimPreviewPed) then return end

        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do
            Citizen.Wait(10)
            timeout = timeout + 1
        end

        if HasAnimDictLoaded(dict) and legalAnimPreviewPed and DoesEntityExist(legalAnimPreviewPed) then
            ClearPedTasksImmediately(legalAnimPreviewPed)
            TaskPlayAnim(legalAnimPreviewPed, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end)
end

local function vec3ToTable(v)
    if not v then return nil end
    return { x = v.x, y = v.y, z = v.z }
end

local function DeleteLegalPreviewProp()
    if legalStationPreviewProp and DoesEntityExist(legalStationPreviewProp) then
        DeleteEntity(legalStationPreviewProp)
        legalStationPreviewProp = nil
    end
end

local function GetLegalDefaultPropPosition()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local propOffset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.4, 0.0)
    local markerOffset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.3, 0.0)
    return {
        coords = vector3(propOffset.x, propOffset.y, playerCoords.z - 1.0),
        markerCoords = vector3(markerOffset.x, markerOffset.y, playerCoords.z)
    }
end

local function SpawnLegalPreviewProp(model, coords)
    DeleteLegalPreviewProp()

    if not model or model == "" then return end
    if not coords then return end

    Citizen.CreateThread(function()
        local hash = GetHashKey(model)
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 100 do
            Citizen.Wait(10)
            timeout = timeout + 1
        end

        if not HasModelLoaded(hash) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Modèle introuvable: " .. model .. "." })
            return
        end

        local prop = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)

        if prop and prop ~= 0 then
            SetEntityHeading(prop, GetEntityHeading(PlayerPedId()))
            SetEntityAlpha(prop, 200, false)
            FreezeEntityPosition(prop, true)
            SetEntityCollision(prop, false, false)
            SetModelAsNoLongerNeeded(hash)
            legalStationPreviewProp = prop
        end
    end)
end

local legalRecipeData = {
    name = nil,
    label = nil,
    category = "general",
    outputItem = nil,
    outputQuantity = 1,
    craftTime = 5000,
    animationType = "predefined",
    animationPreset = nil,
    animationDict = nil,
    animationName = nil,
    animationProp = nil,
    ingredients = {},
    isUpdate = false,
    id = nil
}

local function ResetLegalRecipeData()
    legalRecipeData = {
        name = nil, label = nil, category = "general",
        outputItem = nil, outputQuantity = 1, craftTime = 5000,
        animationType = "predefined", animationPreset = nil,
        animationDict = nil, animationName = nil, animationProp = nil,
        ingredients = {}, isUpdate = false, id = nil
    }
end

local legalStationPendingAnim = nil

local function ResetLegalStationData()
    DeleteLegalPreviewProp()
    legalStationData = {
        name = nil, description = nil, propModel = nil, coords = nil, markerCoords = nil,
        interactionDistance = 2.0, jobRestriction = nil, jobGradeMin = nil,
        recipes = {},
        blipEnabled = false, blipSprite = 1, blipColor = 1, blipScale = 0.8, blipLabel = nil,
        animationDict = nil, animationName = nil,
        animOffsetX = nil, animOffsetY = nil, animOffsetZ = nil, animOffsetH = nil,
        isUpdate = false, id = nil
    }
end

local function GetJobLabel(jobName)
    if not jobName then return "Aucun" end
    if not cachedJobs then
        cachedJobs = TriggerServerCallback("legalBuilder:getJobs")
    end
    for _, job in ipairs(cachedJobs or {}) do
        if job.name == jobName then
            return job.label
        end
    end
    return jobName
end

local function GetItemLabel(itemName)
    if not itemName then return "Inconnu" end
    local cachedItems = TriggerServerCallback("illegalBuilder:getItems")
    for _, item in ipairs(cachedItems or {}) do
        if item.name == itemName then
            return item.label
        end
    end
    return itemName
end

function StaffMenu.BuildLegalBuilderMenu()
    StaffMenu.builderLegal.Button(":plus: CRÉER UNE STATION", "Nouvelle station de craft légale", nil, "chevron", false, function()
        ResetLegalStationData()
    end, StaffMenu.legalStationCreate)

    StaffMenu.builderLegal.Button(":report: LISTE DES STATIONS", "Voir et modifier les stations", nil, "chevron", false, function()
        cachedLegalStations = TriggerServerCallback("legalBuilder:getStations") or {}
    end, StaffMenu.legalStationList)

    StaffMenu.builderLegal.Button(":report: RECETTES", "Gérer les recettes légales", nil, "chevron", false, function()
        cachedRecipes = TriggerServerCallback("legalBuilder:getRecipes") or {}
    end, StaffMenu.legalRecipeList)
end

function StaffMenu.BuildLegalStationBuilderMenu()
    StaffMenu.legalStationBuilder.Button(":plus: CRÉER UNE STATION", "Nouvelle station de craft légale", nil, "chevron", false, function()
        ResetLegalStationData()
    end, StaffMenu.legalStationCreate)

    StaffMenu.legalStationBuilder.Button(":report: LISTE DES STATIONS", "Voir et modifier les stations", nil, "chevron", false, function()
        cachedLegalStations = TriggerServerCallback("legalBuilder:getStations") or {}
    end, StaffMenu.legalStationList)
end

function StaffMenu.BuildLegalStationListMenu()
    if not cachedLegalStations or next(cachedLegalStations) == nil then
        StaffMenu.legalStationList.Button(":x: AUCUNE STATION", "Créez-en une d'abord", nil, nil, true, function() end)
        return
    end

    for id, station in pairs(cachedLegalStations) do
        local recipeCount = station.recipes and #station.recipes or 0
        StaffMenu.legalStationList.Button(
            ":building: " .. station.name,
            recipeCount .. " recettes",
            "#" .. id,
            "chevron", false,
            function()
                currentLegalStation = station
            end,
            StaffMenu.legalStationManage
        )
    end
end

function StaffMenu.BuildLegalStationManageMenu()
    if not currentLegalStation then return end

    local station = currentLegalStation

    StaffMenu.legalStationManage.Separator("INFORMATIONS", nil, nil, nil)
    StaffMenu.legalStationManage.Button("Nom", station.name, nil, nil, true, function() end)
    if station.prop_model then
        StaffMenu.legalStationManage.Button("Prop", station.prop_model, nil, nil, true, function() end)
    end
    StaffMenu.legalStationManage.Button("Distance", (station.interaction_distance or 2.0) .. "m", nil, nil, true, function() end)

    if station.job_restriction then
        StaffMenu.legalStationManage.Button("Job", GetJobLabel(station.job_restriction), nil, nil, true, function() end)
    end

    local recipeCount = station.recipes and #station.recipes or 0
    StaffMenu.legalStationManage.Button("Recettes", recipeCount .. " assignées", nil, nil, true, function() end)

    StaffMenu.legalStationManage.Separator("ACTIONS", nil, nil, nil)

    StaffMenu.legalStationManage.Button(":pin: SE TÉLÉPORTER", nil, nil, "chevron", false, function()
        SetEntityCoords(PlayerPedId(), station.coords_x, station.coords_y, station.coords_z, false, false, false, false)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Téléporté à la station." })
    end)

    StaffMenu.legalStationManage.Button(":report: GÉRER RECETTES", "Assigner des recettes", nil, "chevron", false, function()
        cachedRecipes = TriggerServerCallback("legalBuilder:getRecipes") or {}
    end, StaffMenu.legalStationRecipes)

    StaffMenu.legalStationManage.Button(":edit: MODIFIER", nil, nil, "chevron", false, function()
        legalStationData = {
            name = station.name,
            description = station.description,
            propModel = station.prop_model,
            coords = vector3(station.coords_x, station.coords_y, station.coords_z),
            rotationZ = station.rotation_z or 0,
            markerCoords = (station.marker_x and station.marker_y and station.marker_z) and vector3(station.marker_x, station.marker_y, station.marker_z) or nil,
            interactionDistance = station.interaction_distance or 2.0,
            jobRestriction = station.job_restriction,
            jobGradeMin = station.job_grade_min,
            recipes = station.recipes or {},
            blipEnabled = station.blip_enabled or false,
            blipSprite = station.blip_sprite or 1,
            blipColor = station.blip_color or 1,
            blipScale = station.blip_scale or 0.8,
            blipLabel = station.blip_label,
            animationDict = station.animation_dict,
            animationName = station.animation_name,
            animOffsetX = station.anim_offset_x,
            animOffsetY = station.anim_offset_y,
            animOffsetZ = station.anim_offset_z,
            animOffsetH = station.anim_offset_h,
            isUpdate = true,
            id = station.id
        }
        if legalStationData.propModel and legalStationData.coords then
            SpawnLegalPreviewProp(legalStationData.propModel, legalStationData.coords)
        end
    end, StaffMenu.legalStationCreate)

    StaffMenu.legalStationManage.Button(":trash: SUPPRIMER", nil, nil, "chevron", false, function()
        local result = TriggerServerCallback("legalBuilder:deleteStation", station.id)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Station supprimée." })
            StaffMenu.legalStationManage.close()
            StaffMenu.legalStationManage.parent.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = result and result.error or "Erreur." })
        end
    end)
end

function StaffMenu.BuildLegalStationCreateMenu()
    StaffMenu.legalStationCreate.Separator("INFORMATIONS DE LA STATION", nil, nil, nil)

    StaffMenu.legalStationCreate.Button(":edit: NOM DE LA STATION", "Nom affiché pour les joueurs", legalStationData.name or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la station (ex: Four de boulangerie)", legalStationData.name or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            legalStationData.name = input
            StaffMenu.legalStationCreate.refresh()
        end
    end)

    StaffMenu.legalStationCreate.Button(":document: DESCRIPTION", "Texte affiché à l'interaction", legalStationData.description and "Définie" or "Non définie", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Description (optionnel)", legalStationData.description or "", 200)
        if input and input ~= "KBD_CANCEL" then
            legalStationData.description = input ~= "" and input or nil
            StaffMenu.legalStationCreate.refresh()
        end
    end)

    StaffMenu.legalStationCreate.Separator("PLACEMENT DANS LE MONDE", nil, nil, nil)

    StaffMenu.legalStationCreate.Button(":palette: MODÈLE DU PROP", "Objet 3D affiché (optionnel)", legalStationData.propModel or "Aucun - marqueur seul", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Modèle du prop (laisser vide = sans prop)", legalStationData.propModel or "", 100)
        if input and input ~= "KBD_CANCEL" then
            local newModel = input ~= "" and input or nil
            legalStationData.propModel = newModel
            if newModel then
                if not legalStationData.coords then
                    local defaultPos = GetLegalDefaultPropPosition()
                    legalStationData.coords = defaultPos.coords
                    legalStationData.markerCoords = defaultPos.markerCoords
                end
                SpawnLegalPreviewProp(newModel, legalStationData.coords)
            else
                DeleteLegalPreviewProp()
            end
            StaffMenu.legalStationCreate.refresh()
        end
    end)

    local coordsLabel = legalStationData.coords and string.format("%.1f, %.1f, %.1f", legalStationData.coords.x, legalStationData.coords.y, legalStationData.coords.z) or "Non défini"
  StaffMenu.legalStationCreate.Button(":pin: POSITION", legalStationData.propModel and "Place le prop devant toi" or "Place la station à ta position", coordsLabel, "chevron", false, function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if legalStationData.propModel then
            local defaultPos = GetLegalDefaultPropPosition()
            legalStationData.coords = defaultPos.coords
            legalStationData.markerCoords = defaultPos.markerCoords
            SpawnLegalPreviewProp(legalStationData.propModel, legalStationData.coords)
        else
            legalStationData.coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
            legalStationData.markerCoords = nil
        end
        legalStationData.rotationZ = GetEntityHeading(playerPed)

        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Position définie." })
        StaffMenu.legalStationCreate.refresh()
    end)

    if legalStationPreviewProp and DoesEntityExist(legalStationPreviewProp) then
        StaffMenu.legalStationCreate.Button(":trash: SUPPRIMER PREVIEW", "Retire le prop et la position", nil, "chevron", false, function()
            DeleteLegalPreviewProp()
            legalStationData.propModel = nil
            legalStationData.coords = nil
            legalStationData.markerCoords = nil
            StaffMenu.legalStationCreate.refresh()
        end)
    end

    StaffMenu.legalStationCreate.Button(":ruler: DISTANCE D'INTERACTION", "Portée pour accéder à la station", tostring(legalStationData.interactionDistance) .. "m", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Distance en mètres", tostring(legalStationData.interactionDistance), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            legalStationData.interactionDistance = tonumber(input) or 2.0
            StaffMenu.legalStationCreate.refresh()
        end
    end)

    StaffMenu.legalStationCreate.Separator("ACCÈS (qui peut utiliser)", nil, nil, nil)

    local jobLabel = legalStationData.jobRestriction and GetJobLabel(legalStationData.jobRestriction) or "Tout le monde"
  local gradeLabel = legalStationData.jobRestriction and ("Grade min: " .. (legalStationData.jobGradeMin or 0)) or "Aucune restriction"
  StaffMenu.legalStationCreate.Button(":briefcase: JOB REQUIS", gradeLabel, jobLabel, "chevron", false, function()
    end, StaffMenu.legalStationJobSelect)

    StaffMenu.legalStationCreate.Separator("ANIMATION", nil, nil, nil)

    local animLabel = (legalStationData.animationDict and legalStationData.animationName)
        and (legalStationData.animationDict .. " / " .. legalStationData.animationName)
        or "Aucune"

  StaffMenu.legalStationCreate.Button(":film: ANIMATION DE CRAFT", "Animation jouée pendant le craft", animLabel, "chevron", false, function()
        legalStationPendingAnim = {
            dict = legalStationData.animationDict,
            anim = legalStationData.animationName
        }
    end, StaffMenu.legalStationAnimSelect)

    if legalStationData.animationDict then
        StaffMenu.legalStationCreate.Button(":x: RETIRER L'ANIMATION", nil, nil, "chevron", false, function()
            legalStationData.animationDict = nil
            legalStationData.animationName = nil
            legalStationData.animOffsetX = nil
            legalStationData.animOffsetY = nil
            legalStationData.animOffsetZ = nil
            legalStationData.animOffsetH = nil
            StaffMenu.legalStationCreate.refresh()
        end)
    end

    StaffMenu.legalStationCreate.Separator("BLIP SUR LA CARTE", nil, nil, nil)

    StaffMenu.legalStationCreate.Checkbox(":pin: AFFICHER LE BLIP", "Visible sur la map pour les joueurs autorisés", false, legalStationData.blipEnabled, function(checked)
        legalStationData.blipEnabled = checked
        StaffMenu.legalStationCreate.refresh()
    end)

    if legalStationData.blipEnabled then
        StaffMenu.legalStationCreate.Button(":palette: SPRITE", "Icône du blip", tostring(legalStationData.blipSprite), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "ID du sprite (voir wiki FiveM)", tostring(legalStationData.blipSprite), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                legalStationData.blipSprite = tonumber(input) or 1
                StaffMenu.legalStationCreate.refresh()
            end
        end)

        StaffMenu.legalStationCreate.Button(":palette: COULEUR", "Couleur du blip", tostring(legalStationData.blipColor), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "ID de la couleur (voir wiki FiveM)", tostring(legalStationData.blipColor), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                legalStationData.blipColor = tonumber(input) or 1
                StaffMenu.legalStationCreate.refresh()
            end
        end)

        StaffMenu.legalStationCreate.Button(":ruler: ÉCHELLE", "Taille du blip", tostring(legalStationData.blipScale), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Échelle (ex: 0.8)", tostring(legalStationData.blipScale), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                legalStationData.blipScale = tonumber(input) or 0.8
                StaffMenu.legalStationCreate.refresh()
            end
        end)

        StaffMenu.legalStationCreate.Button(":edit: LABEL", "Texte affiché sur la map", legalStationData.blipLabel or legalStationData.name or "Non défini", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Label du blip", legalStationData.blipLabel or legalStationData.name or "", 50)
            if input and input ~= "KBD_CANCEL" then
                legalStationData.blipLabel = input ~= "" and input or nil
                StaffMenu.legalStationCreate.refresh()
            end
        end)
    end

    local isValid = legalStationData.name and legalStationData.coords
    local btnLabel = legalStationData.isUpdate and ":save: SAUVEGARDER LES MODIFICATIONS" or ":check: CRÉER LA STATION"
  local btnDesc = not isValid and "Remplis le nom et la position" or nil

    StaffMenu.legalStationCreate.Button(btnLabel, btnDesc, nil, "chevron", not isValid, function()
        local sendData = {
            name = legalStationData.name,
            description = legalStationData.description,
            propModel = legalStationData.propModel,
            coords = vec3ToTable(legalStationData.coords),
            rotationZ = legalStationData.rotationZ or GetEntityHeading(PlayerPedId()),
            markerCoords = vec3ToTable(legalStationData.markerCoords),
            interactionDistance = legalStationData.interactionDistance,
            jobRestriction = legalStationData.jobRestriction,
            jobGradeMin = legalStationData.jobGradeMin,
            recipes = legalStationData.recipes,
            animationDict = legalStationData.animationDict,
            animationName = legalStationData.animationName,
            animOffsetX = legalStationData.animOffsetX,
            animOffsetY = legalStationData.animOffsetY,
            animOffsetZ = legalStationData.animOffsetZ,
            animOffsetH = legalStationData.animOffsetH,
            blipEnabled = legalStationData.blipEnabled,
            blipSprite = legalStationData.blipSprite,
            blipColor = legalStationData.blipColor,
            blipScale = legalStationData.blipScale,
            blipLabel = legalStationData.blipLabel
        }
        local result
        if legalStationData.isUpdate then
            result = TriggerServerCallback("legalBuilder:updateStation", legalStationData.id, sendData)
        else
            result = TriggerServerCallback("legalBuilder:createStation", sendData)
        end

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = legalStationData.isUpdate and "Station mise à jour." or "Station créée." })
            local wasUpdate = legalStationData.isUpdate
            ResetLegalStationData()
            cachedLegalStations = TriggerServerCallback("legalBuilder:getStations") or {}
            Citizen.SetTimeout(50, function()
                StaffMenu.legalStationCreate.close()
                if wasUpdate then
                    StaffMenu.legalStationList.open()
                else
                    StaffMenu.builderLegal.open()
                end
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = result and result.error or "Erreur." })
        end
    end)
end

local legalStationAnimIndexMap = {}

function StaffMenu.BuildLegalStationAnimSelectMenu()
    CreateLegalAnimPreview()
    legalCurrentAnimDict = nil
    legalCurrentAnimName = nil
    legalStationAnimIndexMap = {}

    if not legalStationPendingAnim then
        legalStationPendingAnim = {
            dict = legalStationData.animationDict,
            anim = legalStationData.animationName
        }
    end

    local menuIndex = 1

    if not cachedPresets then
        cachedPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations")
    end

    StaffMenu.legalStationAnimSelect.Separator("ANIMATIONS PRÉDÉFINIES", nil, nil, nil)
    menuIndex = menuIndex + 1

    for _, preset in ipairs(cachedPresets or {}) do
        local isSelected = legalStationPendingAnim.dict == preset.dict and legalStationPendingAnim.anim == preset.anim

        legalStationAnimIndexMap[menuIndex] = { dict = preset.dict, anim = preset.anim }

        StaffMenu.legalStationAnimSelect.Button(
            preset.label, preset.dict .. " / " .. preset.anim, nil,
            isSelected and "check" or "chevron", false,
            function()
                legalStationPendingAnim = { dict = preset.dict, anim = preset.anim }
                StaffMenu.legalStationAnimSelect.refresh()
            end
        )
        menuIndex = menuIndex + 1
    end

    StaffMenu.legalStationAnimSelect.Separator("CUSTOM", nil, nil, nil)
    menuIndex = menuIndex + 1

    StaffMenu.legalStationAnimSelect.Button(":film: ANIMATION CUSTOM", "Entrer dict/anim manuellement", nil, "chevron", false, function()
        local dict = VFW.Nui.KeyboardInput(true, "Animation Dictionary", legalStationPendingAnim.dict or "", 100)
        if not dict or dict == "" or dict == "KBD_CANCEL" then return end

        local anim = VFW.Nui.KeyboardInput(true, "Animation Name", legalStationPendingAnim.anim or "", 100)
        if not anim or anim == "" or anim == "KBD_CANCEL" then return end

        legalStationPendingAnim = { dict = dict, anim = anim }
        PlayLegalAnimOnPreview(dict, anim)
        StaffMenu.legalStationAnimSelect.refresh()
    end)
    menuIndex = menuIndex + 1

    StaffMenu.legalStationAnimSelect.Separator("", nil, nil, nil)

    StaffMenu.legalStationAnimSelect.Button(":check: VALIDER + POSITIONNER", "Confirmer l'animation et positionner avec le gizmo", nil, "chevron", false, function()
        local pendingDict = legalStationPendingAnim.dict
        local pendingAnim = legalStationPendingAnim.anim

        if not pendingDict or pendingDict == "" or not pendingAnim or pendingAnim == "" then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Station', message = "Aucune animation sélectionnée." })
            return
        end

        legalStationData.animationDict = pendingDict
        legalStationData.animationName = pendingAnim
        DeleteLegalAnimPreview()
        legalStationPendingAnim = nil

        StaffMenu.legalStationAnimSelect.close()
        Citizen.Wait(200)

        -- Déterminer la position de spawn du ped gizmo
        local stationX, stationY, stationZ, stationH
        if legalStationData.coords and legalStationData.coords.x then
            stationX = legalStationData.coords.x
            stationY = legalStationData.coords.y
            stationZ = legalStationData.coords.z
            stationH = legalStationData.rotationZ or 0
        else
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            stationX = pos.x
            stationY = pos.y
            stationZ = pos.z
            stationH = GetEntityHeading(ped)
        end

        -- Créer un ped clone pour le gizmo
        local pedModel = joaat("a_m_y_business_01")
        VFW.Streaming.RequestModel(pedModel)
        local clonePed = CreatePed(4, pedModel, stationX, stationY, stationZ, (stationH + 180.0) % 360.0, false, true)
        SetModelAsNoLongerNeeded(pedModel)

        if not clonePed or not DoesEntityExist(clonePed) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Station', message = "Erreur création du ped." })
            Citizen.SetTimeout(200, function() StaffMenu.legalStationCreate.open() end)
            return
        end

        SetEntityInvincible(clonePed, true)
        SetEntityAsMissionEntity(clonePed, true, true)
        SetBlockingOfNonTemporaryEvents(clonePed, true)
        SetPedCanRagdoll(clonePed, false)
        FreezeEntityPosition(clonePed, true)

        -- Jouer l'animation sur le ped
        RequestAnimDict(pendingDict)
        local animTimeout = GetGameTimer() + 5000
        while not HasAnimDictLoaded(pendingDict) and GetGameTimer() < animTimeout do Citizen.Wait(10) end
        if HasAnimDictLoaded(pendingDict) then
            TaskPlayAnim(clonePed, pendingDict, pendingAnim, 8.0, -4.0, -1, 1, 0, false, false, false)
        end

        Citizen.Wait(500)

        -- Lancer le gizmo
        VFW.ShowNotification({ type = 'VERT', content = "Gizmo: positionnez le ped pour l'animation. Entrée = valider, Échap = annuler" })
        local gizmoResult = exports["core"]:useGizmo(clonePed)

        if gizmoResult and gizmoResult.position then
            local clonePos = gizmoResult.position
            local cloneH = GetEntityHeading(clonePed)

            -- Convertir world → offset local relatif à la station
            local rad = math.rad(stationH)
            local cosH, sinH = math.cos(rad), math.sin(rad)
            local dx = clonePos.x - stationX
            local dy = clonePos.y - stationY

            local localX =  dx * cosH + dy * sinH
            local localY = -dx * sinH + dy * cosH
            local localZ = clonePos.z - stationZ
            local localH = (cloneH - stationH) % 360.0

            legalStationData.animOffsetX = math.floor(localX * 100 + 0.5) / 100
            legalStationData.animOffsetY = math.floor(localY * 100 + 0.5) / 100
            legalStationData.animOffsetZ = math.floor(localZ * 100 + 0.5) / 100
            legalStationData.animOffsetH = math.floor(localH * 10 + 0.5) / 10

            VFW.ShowNotification({ type = 'VERT', content = "Position de l'animation sauvegardée !" })
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Positionnement annulé" })
        end

        -- Cleanup
        if DoesEntityExist(clonePed) then
            DeleteEntity(clonePed)
        end

        Citizen.Wait(300)
        StaffMenu.legalStationCreate.open()
    end)

    StaffMenu.legalStationAnimSelect.Button(":x: ANNULER", nil, nil, "chevron", false, function()
        DeleteLegalAnimPreview()
        legalStationPendingAnim = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.legalStationAnimSelect.close()
            StaffMenu.legalStationCreate.open()
        end)
    end)
end

StaffMenu.legalStationAnimSelect.OnIndexChange(function(index, item)
    local animData = legalStationAnimIndexMap[index]
    if animData and animData.dict and animData.anim then
        PlayLegalAnimOnPreview(animData.dict, animData.anim)
    end
end)

function StaffMenu.BuildLegalStationJobSelectMenu()
    if not cachedJobs then
        cachedJobs = TriggerServerCallback("legalBuilder:getJobs")
    end

    StaffMenu.legalStationJobSelect.Button(":x: AUCUNE RESTRICTION", nil, nil,
        not legalStationData.jobRestriction and "check" or "chevron", false,
        function()
            legalStationData.jobRestriction = nil
            legalStationData.jobGradeMin = nil
            StaffMenu.legalStationJobSelect.close()
            StaffMenu.legalStationJobSelect.parent.open()
        end
    )

    StaffMenu.legalStationJobSelect.Separator("JOBS", nil, nil, nil)

    for _, job in ipairs(cachedJobs or {}) do
        StaffMenu.legalStationJobSelect.Button(
            job.label, job.name, nil,
            "chevron", false,
            function()
                legalStationData.jobRestriction = job.name
                cachedJobGrades = TriggerServerCallback("legalBuilder:getJobGrades", job.name) or {}
            end,
            StaffMenu.legalStationGradeSelect
        )
    end
end

function StaffMenu.BuildLegalStationGradeSelectMenu()
    if not legalStationData.jobRestriction then
        StaffMenu.legalStationGradeSelect.close()
        StaffMenu.legalStationGradeSelect.parent.open()
        return
    end

    local jobLabel = GetJobLabel(legalStationData.jobRestriction)
    StaffMenu.legalStationGradeSelect.Separator("Grades de " .. jobLabel, nil, nil, nil)

    StaffMenu.legalStationGradeSelect.Button("Grade 0", "Tous les membres", nil,
        legalStationData.jobGradeMin == 0 and "check" or "chevron", false,
        function()
            legalStationData.jobGradeMin = 0
            StaffMenu.legalStationGradeSelect.close()
            StaffMenu.legalStationCreate.open()
        end
    )

    for _, grade in ipairs(cachedJobGrades or {}) do
        local isSelected = legalStationData.jobGradeMin == grade.grade
        StaffMenu.legalStationGradeSelect.Button(
            grade.label or ("Grade " .. grade.grade),
            "Grade " .. grade.grade,
            nil,
            isSelected and "check" or "chevron", false,
            function()
                legalStationData.jobGradeMin = grade.grade
                StaffMenu.legalStationGradeSelect.close()
                StaffMenu.legalStationCreate.open()
            end
        )
    end
end

function StaffMenu.BuildLegalStationRecipesMenu()
    if not currentLegalStation then return end

    cachedRecipes = TriggerServerCallback("legalBuilder:getRecipes") or {}

    currentLegalStation.recipes = currentLegalStation.recipes or {}

    local assignedRecipes = {}
    for _, recipeId in ipairs(currentLegalStation.recipes) do
        assignedRecipes[recipeId] = true
    end

    StaffMenu.legalStationRecipes.Separator("RECETTES DISPONIBLES", nil, nil, nil)

    if not cachedRecipes or next(cachedRecipes) == nil then
        StaffMenu.legalStationRecipes.Button(":x: AUCUNE RECETTE", "Créez des recettes légales d'abord", nil, nil, true, function() end)
        return
    end

    for id, recipe in pairs(cachedRecipes) do
        local isAssigned = assignedRecipes[id]
        StaffMenu.legalStationRecipes.Checkbox(
            recipe.label,
            recipe.name .. " - " .. recipe.category,
            false,
            isAssigned,
            function(checked)
                if checked then
                    table.insert(currentLegalStation.recipes, id)
                else
                    for i, rid in ipairs(currentLegalStation.recipes) do
                        if rid == id then
                            table.remove(currentLegalStation.recipes, i)
                            break
                        end
                    end
                end
            end
        )
    end

    StaffMenu.legalStationRecipes.Separator("", nil, nil, nil)

    StaffMenu.legalStationRecipes.Button(":save: SAUVEGARDER", nil, nil, "chevron", false, function()
        local result = TriggerServerCallback("legalBuilder:assignRecipes", currentLegalStation.id, currentLegalStation.recipes)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Recettes mises à jour." })
            Citizen.SetTimeout(50, function()
                StaffMenu.legalStationRecipes.close()
                StaffMenu.legalStationManage.open()
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = result and result.error or "Erreur." })
        end
    end)
end

RegisterNetEvent("legalBuilder:refreshStations", function(stations)
    cachedLegalStations = stations
end)

local function GetPresetLabel(presetId)
    if not presetId then return "Aucune" end
    if not cachedPresets then
        cachedPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations")
    end
    for _, preset in ipairs(cachedPresets or {}) do
        if preset.id == presetId then
            return preset.label
        end
    end
    return presetId
end

function StaffMenu.BuildLegalRecipeListMenu()
    StaffMenu.legalRecipeList.Button(":plus: CRÉER UNE RECETTE", "Nouvelle recette légale", nil, "chevron", false, function()
        ResetLegalRecipeData()
    end, StaffMenu.legalRecipeCreate)

    StaffMenu.legalRecipeList.Separator("RECETTES EXISTANTES", nil, nil, nil)

    if not cachedRecipes or next(cachedRecipes) == nil then
        StaffMenu.legalRecipeList.Button(":x: AUCUNE RECETTE", "Créez-en une d'abord", nil, nil, true, function() end)
        return
    end

    for id, recipe in pairs(cachedRecipes) do
        local ingCount = recipe.requirements and #recipe.requirements or 0
        StaffMenu.legalRecipeList.Button(
            ":report: " .. (recipe.label or recipe.name),
            ingCount .. " composants",
            "#" .. id,
            "chevron", false,
            function()
                currentLegalRecipe = recipe
                currentLegalRecipe.id = id
            end,
            StaffMenu.legalRecipeManage
        )
    end
end

function StaffMenu.BuildLegalRecipeManageMenu()
    if not currentLegalRecipe then return end

    local recipe = currentLegalRecipe

    StaffMenu.legalRecipeManage.Separator("INFORMATIONS", nil, nil, nil)
    StaffMenu.legalRecipeManage.Button("Nom", recipe.label or recipe.name, nil, nil, true, function() end)
    StaffMenu.legalRecipeManage.Button("Identifiant", recipe.name, nil, nil, true, function() end)
    StaffMenu.legalRecipeManage.Button("Résultat", GetItemLabel(recipe.outputItem) .. " x" .. (recipe.outputQuantity or 1), nil, nil, true, function() end)
    StaffMenu.legalRecipeManage.Button("Temps", ((recipe.craftTime or 5000) / 1000) .. "s", nil, nil, true, function() end)

    if recipe.requirements and #recipe.requirements > 0 then
        StaffMenu.legalRecipeManage.Separator("COMPOSANTS", nil, nil, nil)
        for _, ing in ipairs(recipe.requirements) do
            StaffMenu.legalRecipeManage.Button(GetItemLabel(ing.name), "x" .. (ing.amount or 1), nil, nil, true, function() end)
        end
    end

    StaffMenu.legalRecipeManage.Separator("ACTIONS", nil, nil, nil)

    StaffMenu.legalRecipeManage.Button(":edit: MODIFIER", nil, nil, "chevron", false, function()
        legalRecipeData = {
            name = recipe.name,
            label = recipe.label,
            category = "general",
            outputItem = recipe.outputItem,
            outputQuantity = recipe.outputQuantity,
            craftTime = recipe.craftTime,
            animationType = recipe.animationType,
            animationPreset = recipe.animationPreset,
            animationDict = recipe.animationDict,
            animationName = recipe.animationName,
            animationProp = recipe.animationProp,
            ingredients = recipe.requirements or {},
            isUpdate = true,
            id = recipe.id
        }
    end, StaffMenu.legalRecipeCreate)

    StaffMenu.legalRecipeManage.Button(":trash: SUPPRIMER", nil, nil, "chevron", false, function()
        local result = TriggerServerCallback("legalBuilder:deleteRecipe", recipe.id)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Recette supprimée." })
            cachedRecipes = TriggerServerCallback("legalBuilder:getRecipes") or {}
            StaffMenu.legalRecipeManage.close()
            StaffMenu.legalRecipeManage.parent.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = result and result.error or "Erreur." })
        end
    end)
end

local function GenerateRecipeId(label)
    if not label or label == "" then return nil end
    local id = string.lower(label)
    id = id:gsub("[éèêë]", "e"):gsub("[àâä]", "a"):gsub("[ùûü]", "u"):gsub("[îï]", "i"):gsub("[ôö]", "o"):gsub("ç", "c")
    id = id:gsub("%s+", "_"):gsub("[^a-z0-9_]", "")
    return id
end

function StaffMenu.BuildLegalRecipeCreateMenu()
    StaffMenu.legalRecipeCreate.Separator("INFORMATIONS DE LA RECETTE", nil, nil, nil)

    StaffMenu.legalRecipeCreate.Button(":edit: NOM DE LA RECETTE", "Nom affiché dans le menu", legalRecipeData.label or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom affiché (ex: Pain Complet)", legalRecipeData.label or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            legalRecipeData.label = input
            if not legalRecipeData.isUpdate then
                legalRecipeData.name = GenerateRecipeId(input)
            end
            StaffMenu.legalRecipeCreate.refresh()
        end
    end)

    if legalRecipeData.name then
        StaffMenu.legalRecipeCreate.Button(":key: IDENTIFIANT", "Généré automatiquement", legalRecipeData.name, nil, true, function() end)
    end

    StaffMenu.legalRecipeCreate.Separator("ITEM FINAL (ce que le joueur reçoit)", nil, nil, nil)

    StaffMenu.legalRecipeCreate.Button(":box: NOM DE L'ITEM", "Item donné après le craft", legalRecipeData.outputItem or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de l'item produit", legalRecipeData.outputItem or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            legalRecipeData.outputItem = input
            StaffMenu.legalRecipeCreate.refresh()
        end
    end)

    StaffMenu.legalRecipeCreate.Button(":hash: QUANTITÉ", "Nombre d'items reçus", tostring(legalRecipeData.outputQuantity or 1), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité produite", tostring(legalRecipeData.outputQuantity or 1), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            legalRecipeData.outputQuantity = tonumber(input) or 1
            StaffMenu.legalRecipeCreate.refresh()
        end
    end)

    StaffMenu.legalRecipeCreate.Separator("PARAMÈTRES DU CRAFT", nil, nil, nil)

    StaffMenu.legalRecipeCreate.Button(":clock: DURÉE DU CRAFT", "Temps en secondes", ((legalRecipeData.craftTime or 5000) / 1000) .. "s", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Temps en secondes", tostring((legalRecipeData.craftTime or 5000) / 1000), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            legalRecipeData.craftTime = (tonumber(input) or 5) * 1000
            StaffMenu.legalRecipeCreate.refresh()
        end
    end)

    local animLabel = legalRecipeData.animationType == "predefined" and GetPresetLabel(legalRecipeData.animationPreset) or "Custom"
  StaffMenu.legalRecipeCreate.Button(":film: ANIMATION", "Animation jouée pendant le craft", animLabel, "chevron", false, function()
        cachedPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations")
        legalPendingAnimation = {
            type = legalRecipeData.animationType,
            preset = legalRecipeData.animationPreset,
            dict = legalRecipeData.animationDict,
            anim = legalRecipeData.animationName,
            prop = legalRecipeData.animationProp
        }
    end, StaffMenu.legalRecipeAnimSelect)

    StaffMenu.legalRecipeCreate.Separator("COMPOSANTS REQUIS (" .. #legalRecipeData.ingredients .. ")", nil, nil, nil)

    if #legalRecipeData.ingredients == 0 then
        StaffMenu.legalRecipeCreate.Button(":report: Aucun composant", "Ajoute des items requis ci-dessous", nil, nil, true, function() end)
    else
        for i, ing in ipairs(legalRecipeData.ingredients) do
            StaffMenu.legalRecipeCreate.Button(
                GetItemLabel(ing.name),
                "Cliquer pour retirer",
                "x" .. (ing.amount or 1),
                "cross", false,
                function()
                    table.remove(legalRecipeData.ingredients, i)
                    StaffMenu.legalRecipeCreate.refresh()
                end
            )
        end
    end

    StaffMenu.legalRecipeCreate.Button(":plus: AJOUTER UN COMPOSANT", "Item consommé pour le craft", nil, "chevron", false, function()
        local itemName = VFW.Nui.KeyboardInput(true, "Nom de l'item requis (ex: bread)", "", 50)
        if not itemName or itemName == "" or itemName == "KBD_CANCEL" then return end

        local amountStr = VFW.Nui.KeyboardInput(true, "Quantité nécessaire", "1", 5)
        local amount = tonumber(amountStr) or 1

        table.insert(legalRecipeData.ingredients, { name = itemName, amount = amount })
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Composant ajouté: " .. itemName .. "." })
        StaffMenu.legalRecipeCreate.refresh()
    end)

    StaffMenu.legalRecipeCreate.Separator("", nil, nil, nil)

    local isValid = legalRecipeData.name and legalRecipeData.outputItem and #legalRecipeData.ingredients > 0
    local btnLabel = legalRecipeData.isUpdate and ":save: SAUVEGARDER LES MODIFICATIONS" or ":check: CRÉER LA RECETTE"
  local btnDesc = not isValid and "Remplis tous les champs requis" or nil

    StaffMenu.legalRecipeCreate.Button(btnLabel, btnDesc, nil, "chevron", not isValid, function()
        local result
        if legalRecipeData.isUpdate then
            result = TriggerServerCallback("legalBuilder:updateRecipe", legalRecipeData.id, legalRecipeData)
        else
            result = TriggerServerCallback("legalBuilder:createRecipe", legalRecipeData)
        end

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = legalRecipeData.isUpdate and "Recette mise à jour." or "Recette créée." })
            local wasUpdate = legalRecipeData.isUpdate
            ResetLegalRecipeData()
            cachedRecipes = TriggerServerCallback("legalBuilder:getRecipes") or {}
            Citizen.SetTimeout(50, function()
                StaffMenu.legalRecipeCreate.close()
                StaffMenu.legalRecipeList.open()
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = result and result.error or "Erreur." })
        end
    end)
end


local legalAnimIndexMap = {}

function StaffMenu.BuildLegalRecipeAnimSelectMenu()
    CreateLegalAnimPreview()
    legalCurrentAnimDict = nil
    legalCurrentAnimName = nil
    legalAnimIndexMap = {}

    if not legalPendingAnimation then
        legalPendingAnimation = {
            type = legalRecipeData.animationType,
            preset = legalRecipeData.animationPreset,
            dict = legalRecipeData.animationDict,
            anim = legalRecipeData.animationName,
            prop = legalRecipeData.animationProp
        }
    end

    local menuIndex = 1

    if not cachedPresets then
        cachedPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations")
    end

    StaffMenu.legalRecipeAnimSelect.Separator("ANIMATIONS PRÉDÉFINIES", nil, nil, nil)
    menuIndex = menuIndex + 1

    for _, preset in ipairs(cachedPresets or {}) do
        local isSelected = legalPendingAnimation.type == "predefined" and legalPendingAnimation.preset == preset.id
        local propInfo = preset.prop and (" + " .. preset.prop) or ""

      legalAnimIndexMap[menuIndex] = { dict = preset.dict, anim = preset.anim, preset = preset }

        StaffMenu.legalRecipeAnimSelect.Button(
            preset.label, preset.dict .. " / " .. preset.anim .. propInfo, nil,
            isSelected and "check" or "chevron", false,
            function()
                legalPendingAnimation = {
                    type = "predefined",
                    preset = preset.id,
                    dict = preset.dict,
                    anim = preset.anim,
                    prop = preset.prop
                }
                StaffMenu.legalRecipeAnimSelect.refresh()
            end
        )
        menuIndex = menuIndex + 1
    end

    StaffMenu.legalRecipeAnimSelect.Separator("CUSTOM", nil, nil, nil)
    menuIndex = menuIndex + 1

    StaffMenu.legalRecipeAnimSelect.Button(":film: ANIMATION CUSTOM", "Entrer dict/anim manuellement", nil, "chevron", false, function()
        local dict = VFW.Nui.KeyboardInput(true, "Animation Dictionary", legalPendingAnimation.dict or "", 100)
        if not dict or dict == "" or dict == "KBD_CANCEL" then return end

        local anim = VFW.Nui.KeyboardInput(true, "Animation Name", legalPendingAnimation.anim or "", 100)
        if not anim or anim == "" or anim == "KBD_CANCEL" then return end

        legalPendingAnimation = {
            type = "custom",
            preset = nil,
            dict = dict,
            anim = anim,
            prop = nil
        }
        PlayLegalAnimOnPreview(dict, anim)
        StaffMenu.legalRecipeAnimSelect.refresh()
    end)
    menuIndex = menuIndex + 1

    StaffMenu.legalRecipeAnimSelect.Separator("", nil, nil, nil)
    menuIndex = menuIndex + 1

    StaffMenu.legalRecipeAnimSelect.Button(":check: VALIDER", "Confirmer l'animation sélectionnée", nil, "chevron", false, function()
        legalRecipeData.animationType = legalPendingAnimation.type
        legalRecipeData.animationPreset = legalPendingAnimation.preset
        legalRecipeData.animationDict = legalPendingAnimation.dict
        legalRecipeData.animationName = legalPendingAnimation.anim
        legalRecipeData.animationProp = legalPendingAnimation.prop
        DeleteLegalAnimPreview()
        legalPendingAnimation = nil
        legalCurrentAnimDict = nil
        legalCurrentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.legalRecipeAnimSelect.close()
            StaffMenu.legalRecipeCreate.open()
        end)
    end)

    StaffMenu.legalRecipeAnimSelect.Button(":x: ANNULER", "Revenir sans changer", nil, "chevron", false, function()
        DeleteLegalAnimPreview()
        legalPendingAnimation = nil
        legalCurrentAnimDict = nil
        legalCurrentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.legalRecipeAnimSelect.close()
            StaffMenu.legalRecipeCreate.open()
        end)
    end)
end

StaffMenu.legalRecipeAnimSelect.OnIndexChange(function(index, item)
    local animData = legalAnimIndexMap[index]
    if animData and animData.dict and animData.anim then
        PlayLegalAnimOnPreview(animData.dict, animData.anim)
    end
end)


function StaffMenu.BuildLegalRecipeIngredientAddMenu()
    local items = TriggerServerCallback("illegalBuilder:getItems") or {}

    StaffMenu.legalRecipeIngredientSelect.Separator("SÉLECTIONNER UN ITEM", nil, nil, nil)

    for _, item in ipairs(items) do
        StaffMenu.legalRecipeIngredientSelect.Button(
            item.label, item.name, nil, "chevron", false,
            function()
                local amountStr = VFW.Nui.KeyboardInput(true, "Quantité requise", "1", 5)
                local amount = tonumber(amountStr) or 1
                if amount > 0 then
                    table.insert(legalRecipeData.ingredients, { name = item.name, amount = amount })
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder', message = "Composant ajouté: " .. item.label .. "." })
                end
                StaffMenu.legalRecipeIngredientSelect.close()
                StaffMenu.legalRecipeIngredientSelect.parent.open()
            end
        )
    end
end

RegisterNetEvent("legalBuilder:refreshRecipes", function(recipes)
    cachedRecipes = recipes
end)

StaffMenu.legalStationCreate.OnClose(function()
    DeleteLegalPreviewProp()
end)
