---@meta _
---@diagnostic disable: duplicate-doc-field

local harvestData = {
    name = nil,
    propModel = nil,
    coords = nil,
    markerCoords = nil,
    itemOutput = nil,
    minQuantity = 1,
    maxQuantity = 3,
    harvestTime = 3000,
    cooldown = 100,
    radius = 2.0,
    maxHarvesters = 1,
    animationType = "predefined",
    animationPreset = nil,
    animationDict = nil,
    animationName = nil,
    animationProp = nil,
    factionRestriction = nil,
    factionGradeMin = nil,
    blipEnabled = false,
    blipSprite = 1,
    blipColor = 1,
    blipScale = 0.8,
    blipLabel = nil,
    isUpdate = false,
    id = nil
}

local CATEGORY_PROPS = {
    gpb = "gr_prop_gr_bench_04b",
    armes = "gr_prop_gr_bench_03b",
    munitions = "gr_prop_gr_bench_04b"
}

local CATEGORY_LABELS = {
    gpb = ":shield: Gilet Pare-Balles",
    armes = ":gun: Armes",
    munitions = ":target: Munitions"
}

local stationData = {
    name = nil,
    description = nil,
    category = nil,
    propModel = nil,
    coords = nil,
    markerCoords = nil,
    interactionDistance = 2.0,
    factionRestriction = nil,
    factionGradeMin = nil,
    recipes = {},
    blipEnabled = false,
    blipSprite = 566,
    blipColor = 1,
    blipScale = 0.8,
    blipLabel = nil,
    isUpdate = false,
    id = nil
}

local recipeData = {
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
    id = nil,
    gpbType = nil,
    gpbColor = nil
}

local GPB_TYPES = {
    { id = "light", label = "Léger (30 shield)" },
    { id = "medium", label = "Moyen (60 shield)" },
    { id = "lourd", label = "Lourd (100 shield)" }
}

local GPB_COLORS = {
    { id = "green", label = "Vert" },
    { id = "orange", label = "Orange" },
    { id = "purple", label = "Violet" },
    { id = "pink", label = "Rose" },
    { id = "red", label = "Rouge" },
    { id = "blue", label = "Bleu" },
    { id = "grey", label = "Gris" },
    { id = "brown", label = "Marron" },
    { id = "white", label = "Blanc" },
    { id = "black", label = "Noir" }
}

local transformData = {
    name = nil,
    propModel = nil,
    coords = nil,
    markerCoords = nil,
    inputs = {},
    outputItem = nil,
    outputQuantity = 1,
    transformTime = 3000,
    animationType = "predefined",
    animationPreset = nil,
    animationDict = nil,
    animationName = nil,
    animationProp = nil,
    factionRestriction = nil,
    factionGradeMin = nil,
    blipEnabled = false,
    blipSprite = 1,
    blipColor = 1,
    blipScale = 0.8,
    blipLabel = nil,
    isUpdate = false,
    id = nil
}

local cachedItems = nil
local cachedFactions = nil
local cachedPresets = nil
local cachedFactionGrades = {}
local cachedHarvestSpots = {}
local cachedCraftStations = {}
local cachedRecipes = {}
local cachedTransformSpots = {}
local currentHarvestSpot = nil
local currentStation = nil
local currentRecipe = nil
local currentTransformSpot = nil
local pendingFactionSelect = nil

local harvestPreviewProp = nil
local stationPreviewProp = nil
local transformPreviewProp = nil

local function vec3ToTable(v)
    if not v then return nil end
    return { x = v.x, y = v.y, z = v.z }
end

local function DeletePreviewProp(propType)
    if propType == "harvest" and harvestPreviewProp and DoesEntityExist(harvestPreviewProp) then
        DeleteEntity(harvestPreviewProp)
        harvestPreviewProp = nil
    elseif propType == "station" and stationPreviewProp and DoesEntityExist(stationPreviewProp) then
        DeleteEntity(stationPreviewProp)
        stationPreviewProp = nil
    elseif propType == "transform" and transformPreviewProp and DoesEntityExist(transformPreviewProp) then
        DeleteEntity(transformPreviewProp)
        transformPreviewProp = nil
    end
end

local function SpawnPreviewProp(propType, model, coords)
    DeletePreviewProp(propType)

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
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = "Modèle introuvable: " .. model .. "." })
            return
        end

        local prop = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)

        if prop and prop ~= 0 then
            SetEntityHeading(prop, GetEntityHeading(PlayerPedId()))
            SetEntityAlpha(prop, 200, false)
            FreezeEntityPosition(prop, true)
            SetEntityCollision(prop, false, false)
            SetModelAsNoLongerNeeded(hash)

            if propType == "harvest" then
                harvestPreviewProp = prop
            elseif propType == "station" then
                stationPreviewProp = prop
            elseif propType == "transform" then
                transformPreviewProp = prop
            end
        end
    end)
end

local function UpdatePreviewPropPosition(propType, coords)
    local prop = nil
    if propType == "harvest" then prop = harvestPreviewProp
    elseif propType == "station" then prop = stationPreviewProp
    elseif propType == "transform" then prop = transformPreviewProp
    end

    if prop and DoesEntityExist(prop) then
        SetEntityCoords(prop, coords.x, coords.y, coords.z, false, false, false, false)
    end
end

local function GetDefaultPropPosition()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local propOffset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.4, 0.0)
    local markerOffset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.3, 0.0)
    return {
        coords = vector3(propOffset.x, propOffset.y, playerCoords.z - 1.0),
        markerCoords = vector3(markerOffset.x, markerOffset.y, playerCoords.z)
    }
end

local function EnsurePreviewProp(propType, model, coords)
    local prop = nil
    if propType == "harvest" then prop = harvestPreviewProp
    elseif propType == "station" then prop = stationPreviewProp
    elseif propType == "transform" then prop = transformPreviewProp
    end

    if not model or model == "" then
        DeletePreviewProp(propType)
        return nil
    end

    if not coords then
        local defaultPos = GetDefaultPropPosition()
        coords = defaultPos.coords
    end

    if prop and DoesEntityExist(prop) then
        SetEntityCoords(prop, coords.x, coords.y, coords.z, false, false, false, false)
        return prop
    else
        return SpawnPreviewProp(propType, model, coords)
    end
end

local animPreviewPed = nil
local animPreviewActive = false
local pendingAnimation = nil

local function DeleteAnimPreview()
    if animPreviewPed and DoesEntityExist(animPreviewPed) then
        DeleteEntity(animPreviewPed)
        animPreviewPed = nil
    end
    animPreviewActive = false
end

local function CreateAnimPreview()
    DeleteAnimPreview()

    local playerPed = PlayerPedId()
    local playerHeading = GetEntityHeading(playerPed)

    local previewCoords = GetOffsetFromEntityInWorldCoords(playerPed, 1.5, 2.5, 0.0)

    local model = GetEntityModel(playerPed)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 50 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end

    animPreviewPed = CreatePed(4, model, previewCoords.x, previewCoords.y, previewCoords.z, playerHeading + 200.0, false, false)

    if animPreviewPed and DoesEntityExist(animPreviewPed) then
        SetEntityAlpha(animPreviewPed, 180, false)
        SetEntityInvincible(animPreviewPed, true)
        FreezeEntityPosition(animPreviewPed, true)
        SetEntityCollision(animPreviewPed, false, false)
        SetBlockingOfNonTemporaryEvents(animPreviewPed, true)
        SetPedCanRagdoll(animPreviewPed, false)
        ClonePedToTarget(playerPed, animPreviewPed)
        animPreviewActive = true
    end

    SetModelAsNoLongerNeeded(model)
end

local currentAnimDict = nil
local currentAnimName = nil

local function PlayAnimOnPreview(dict, anim)
    if not dict or dict == "" or not anim or anim == "" then return end
    if dict == currentAnimDict and anim == currentAnimName then return end

    currentAnimDict = dict
    currentAnimName = anim

    Citizen.CreateThread(function()
        if not animPreviewPed or not DoesEntityExist(animPreviewPed) then
            CreateAnimPreview()
            Citizen.Wait(200)
        end

        if not animPreviewPed or not DoesEntityExist(animPreviewPed) then return end

        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do
            Citizen.Wait(10)
            timeout = timeout + 1
        end

        if HasAnimDictLoaded(dict) and animPreviewPed and DoesEntityExist(animPreviewPed) then
            ClearPedTasksImmediately(animPreviewPed)
            TaskPlayAnim(animPreviewPed, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end)
end

local function ResetHarvestData()
    DeletePreviewProp("harvest")
    harvestData = {
        name = nil, propModel = nil, coords = nil, markerCoords = nil,
        itemOutput = nil, minQuantity = 1, maxQuantity = 3,
        harvestTime = 3000, cooldown = 100, radius = 2.0, maxHarvesters = 1,
        animationType = "predefined", animationPreset = nil, animationDict = nil,
        animationName = nil, animationProp = nil, factionRestriction = nil,
        factionGradeMin = nil, blipEnabled = false, blipSprite = 1, blipColor = 1,
        blipScale = 0.8, blipLabel = nil, isUpdate = false, id = nil
    }
end

local function ResetStationData()
    DeletePreviewProp("station")
    stationData = {
        name = nil, description = nil, category = nil, propModel = nil, coords = nil, markerCoords = nil,
        interactionDistance = 2.0, factionRestriction = nil, factionGradeMin = nil,
        recipes = {}, blipEnabled = false, blipSprite = 566, blipColor = 1,
        blipScale = 0.8, blipLabel = nil, isUpdate = false, id = nil
    }
end

local function ResetRecipeData()
    recipeData = {
        name = nil, label = nil, category = "general", outputItem = nil, outputQuantity = 1,
        craftTime = 5000, animationType = "predefined", animationPreset = nil,
        animationDict = nil, animationName = nil, animationProp = nil,
        ingredients = {}, isUpdate = false, id = nil,
        gpbType = nil, gpbColor = nil
    }
end

local function ResetTransformData()
    DeletePreviewProp("transform")
    transformData = {
        name = nil, propModel = nil, coords = nil, markerCoords = nil,
        inputs = {}, outputItem = nil, outputQuantity = 1,
        transformTime = 3000, animationType = "predefined", animationPreset = nil,
        animationDict = nil, animationName = nil, animationProp = nil,
        factionRestriction = nil, factionGradeMin = nil, blipEnabled = false, blipSprite = 1,
        blipColor = 1, blipScale = 0.8, blipLabel = nil, isUpdate = false, id = nil
    }
end

local function GetItemLabel(itemName)
    if not itemName then return "Inconnu" end
    if not cachedItems then
        cachedItems = TriggerServerCallback("illegalBuilder:getItems")
    end
    for _, item in ipairs(cachedItems or {}) do
        if item.name == itemName then
            return item.label
        end
    end
    return itemName
end

local function GetFactionLabel(factionName)
    if not factionName then return "Aucune" end
    if not cachedFactions then
        cachedFactions = TriggerServerCallback("illegalBuilder:getFactions")
    end
    for _, faction in ipairs(cachedFactions or {}) do
        if faction.name == factionName then
            return faction.label
        end
    end
    return factionName
end

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

function StaffMenu.BuildIllegalBuilderMenu()
    StaffMenu.builderIllegal.Button(":leaf: SPOTS DE RÉCOLTE", "Points de récolte sur la carte", nil, "chevron", false, function()
    end, StaffMenu.illegalHarvestBuilder)

    StaffMenu.builderIllegal.Button(":building: STATIONS DE CRAFT", "Fabrication avec menu recettes", nil, "chevron", false, function()
    end, StaffMenu.illegalStationBuilder)

    StaffMenu.builderIllegal.Button(":report: RECETTES", "Gérer les recettes de craft", nil, "chevron", false, function()
    end, StaffMenu.illegalRecipeBuilder)

    StaffMenu.builderIllegal.Button(":refresh: SPOTS DE TRANSFORMATION", "Points de transformation d'items", nil, "chevron", false, function()
    end, StaffMenu.illegalTransformBuilder)
end

function StaffMenu.BuildIllegalHarvestBuilderMenu()
    StaffMenu.illegalHarvestBuilder.Button(":plus: CRÉER UN SPOT", "Nouveau point de récolte", nil, "chevron", false, function()
        ResetHarvestData()
    end, StaffMenu.illegalHarvestCreate)

    StaffMenu.illegalHarvestBuilder.Button(":report: LISTE DES SPOTS", "Voir et modifier les spots existants", nil, "chevron", false, function()
        cachedHarvestSpots = TriggerServerCallback("illegalBuilder:getHarvestSpots") or {}
    end, StaffMenu.illegalHarvestList)
end

function StaffMenu.BuildIllegalHarvestListMenu()
    if not cachedHarvestSpots or next(cachedHarvestSpots) == nil then
        StaffMenu.illegalHarvestList.Button(":x: AUCUN SPOT", "Créez-en un d'abord", nil, nil, true, function() end)
        return
    end

    for id, spot in pairs(cachedHarvestSpots) do
        local itemLabel = GetItemLabel(spot.item_output)
        StaffMenu.illegalHarvestList.Button(
            ":leaf: " .. (spot.name or "Sans nom"),
            "Item: " .. itemLabel,
            "#" .. (spot.id or id),
            "chevron", false,
            function()
                currentHarvestSpot = spot
            end,
            StaffMenu.illegalHarvestManage
        )
    end
end

function StaffMenu.BuildIllegalHarvestManageMenu()
    if not currentHarvestSpot then return end

    local spot = currentHarvestSpot

    StaffMenu.illegalHarvestManage.Separator("INFORMATIONS", nil, nil, nil)
    StaffMenu.illegalHarvestManage.Button("Nom", spot.name, nil, nil, true, function() end)
    if spot.prop_model then
        StaffMenu.illegalHarvestManage.Button("Prop", spot.prop_model, nil, nil, true, function() end)
    end
    StaffMenu.illegalHarvestManage.Button("Item", GetItemLabel(spot.item_output), nil, nil, true, function() end)
    StaffMenu.illegalHarvestManage.Button("Quantité", (spot.min_quantity or 1) .. " - " .. (spot.max_quantity or 3), nil, nil, true, function() end)
    StaffMenu.illegalHarvestManage.Button("Temps", ((spot.harvest_time or 3000) / 1000) .. "s", nil, nil, true, function() end)

    if spot.faction_restriction then
        StaffMenu.illegalHarvestManage.Button("Faction", GetFactionLabel(spot.faction_restriction), nil, nil, true, function() end)
    end

    StaffMenu.illegalHarvestManage.Separator("ACTIONS", nil, nil, nil)

    StaffMenu.illegalHarvestManage.Button(":pin: SE TÉLÉPORTER", "Aller au spot", nil, "chevron", false, function()
        SetEntityCoords(PlayerPedId(), spot.coords_x, spot.coords_y, spot.coords_z, false, false, false, false)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Téléporté au spot." })
    end)

    StaffMenu.illegalHarvestManage.Button(":edit: MODIFIER", "Éditer ce spot", nil, "chevron", false, function()
        harvestData = {
            name = spot.name,
            propModel = spot.prop_model,
            coords = vector3(spot.coords_x, spot.coords_y, spot.coords_z),
            markerCoords = (spot.marker_x and spot.marker_y and spot.marker_z) and vector3(spot.marker_x, spot.marker_y, spot.marker_z) or nil,
            itemOutput = spot.item_output,
            minQuantity = spot.min_quantity,
            maxQuantity = spot.max_quantity,
            harvestTime = spot.harvest_time,
            cooldown = spot.cooldown,
            radius = spot.radius or 2.0,
            maxHarvesters = spot.max_harvesters or 1,
            animationType = spot.animation_type,
            animationPreset = spot.animation_preset,
            animationDict = spot.animation_dict,
            animationName = spot.animation_name,
            animationProp = spot.animation_prop,
            factionRestriction = spot.faction_restriction,
            factionGradeMin = spot.faction_grade_min,
            blipEnabled = spot.blip_enabled or false,
            blipSprite = spot.blip_sprite or 1,
            blipColor = spot.blip_color or 1,
            blipScale = spot.blip_scale or 0.8,
            blipLabel = spot.blip_label,
            isUpdate = true,
            id = spot.id
        }
        if harvestData.propModel and harvestData.coords then
            SpawnPreviewProp("harvest", harvestData.propModel, harvestData.coords)
        end
    end, StaffMenu.illegalHarvestCreate)

    StaffMenu.illegalHarvestManage.Button(":trash: SUPPRIMER", "Supprimer ce spot", nil, "chevron", false, function()
        local result = TriggerServerCallback("illegalBuilder:deleteHarvestSpot", spot.id)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Spot supprimé." })
            StaffMenu.illegalHarvestManage.close()
            StaffMenu.illegalHarvestManage.parent.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end

function StaffMenu.BuildIllegalHarvestCreateMenu()
    StaffMenu.illegalHarvestCreate.Separator("INFORMATIONS DU SPOT", nil, nil, nil)

    StaffMenu.illegalHarvestCreate.Button(":edit: NOM DU SPOT", "Nom affiché pour les joueurs", harvestData.name or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom du spot (ex: Champ de Weed)", harvestData.name or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            harvestData.name = input
            StaffMenu.illegalHarvestCreate.refresh()
        end
    end)

    StaffMenu.illegalHarvestCreate.Separator("PLACEMENT DANS LE MONDE", nil, nil, nil)

    StaffMenu.illegalHarvestCreate.Button(":palette: MODÈLE DU PROP", "Objet 3D affiché (optionnel)", harvestData.propModel or "Aucun - marqueur seul", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Modèle du prop (ex: prop_weed_01)", harvestData.propModel or "", 100)
        if input and input ~= "KBD_CANCEL" then
            local newModel = input ~= "" and input or nil
            harvestData.propModel = newModel
            if newModel then
                if not harvestData.coords then
                    local defaultPos = GetDefaultPropPosition()
                    harvestData.coords = defaultPos.coords
                    harvestData.markerCoords = defaultPos.markerCoords
                end
                SpawnPreviewProp("harvest", newModel, harvestData.coords)
            else
                DeletePreviewProp("harvest")
            end
            StaffMenu.illegalHarvestCreate.refresh()
        end
    end)

    local coordsLabel = harvestData.coords and string.format("%.1f, %.1f, %.1f", harvestData.coords.x, harvestData.coords.y, harvestData.coords.z) or "Non défini"
  StaffMenu.illegalHarvestCreate.Button(":pin: POSITION", harvestData.propModel and "Place le prop devant toi" or "Place le spot à ta position", coordsLabel, "chevron", false, function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if harvestData.propModel then
            local defaultPos = GetDefaultPropPosition()
            harvestData.coords = defaultPos.coords
            harvestData.markerCoords = defaultPos.markerCoords
            SpawnPreviewProp("harvest", harvestData.propModel, harvestData.coords)
        else
            harvestData.coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
            harvestData.markerCoords = nil
        end

        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Position définie." })
        StaffMenu.illegalHarvestCreate.refresh()
    end)

    if harvestPreviewProp and DoesEntityExist(harvestPreviewProp) then
        StaffMenu.illegalHarvestCreate.Button(":trash: SUPPRIMER PREVIEW", "Retire le prop et la position", nil, "chevron", false, function()
            DeletePreviewProp("harvest")
            harvestData.propModel = nil
            harvestData.coords = nil
            harvestData.markerCoords = nil
            StaffMenu.illegalHarvestCreate.refresh()
        end)
    end

    StaffMenu.illegalHarvestCreate.Separator("ITEM RÉCOLTÉ (ce que le joueur reçoit)", nil, nil, nil)

    StaffMenu.illegalHarvestCreate.Button(":box: NOM DE L'ITEM", "Item donné après récolte", harvestData.itemOutput or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de l'item (ex: weed_leaf)", harvestData.itemOutput or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            harvestData.itemOutput = input
            StaffMenu.illegalHarvestCreate.refresh()
        end
    end)

    StaffMenu.illegalHarvestCreate.Button(":hash: QUANTITÉ MIN", "Minimum d'items reçus", tostring(harvestData.minQuantity), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité minimum", tostring(harvestData.minQuantity), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            harvestData.minQuantity = tonumber(input) or 1
            StaffMenu.illegalHarvestCreate.refresh()
        end
    end)

    StaffMenu.illegalHarvestCreate.Button(":hash: QUANTITÉ MAX", "Maximum d'items reçus", tostring(harvestData.maxQuantity), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité maximum", tostring(harvestData.maxQuantity), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            harvestData.maxQuantity = tonumber(input) or 3
            StaffMenu.illegalHarvestCreate.refresh()
        end
    end)

    StaffMenu.illegalHarvestCreate.Separator("PARAMÈTRES DE LA RÉCOLTE", nil, nil, nil)

    StaffMenu.illegalHarvestCreate.Button(":clock: DURÉE DE LA RÉCOLTE", "Temps en secondes", tostring(harvestData.harvestTime / 1000) .. "s", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Temps en secondes", tostring(harvestData.harvestTime / 1000), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            harvestData.harvestTime = (tonumber(input) or 3) * 1000
            StaffMenu.illegalHarvestCreate.refresh()
        end
    end)

    local animLabel = harvestData.animationType == "predefined" and (harvestData.animationPreset and GetPresetLabel(harvestData.animationPreset) or "Choisir...") or "Custom"
  StaffMenu.illegalHarvestCreate.Button(":film: ANIMATION", "Animation jouée pendant la récolte", animLabel, "chevron", false, function()
        pendingAnimation = {
            type = harvestData.animationType,
            preset = harvestData.animationPreset,
            dict = harvestData.animationDict,
            anim = harvestData.animationName,
            prop = harvestData.animationProp
        }
    end, StaffMenu.illegalHarvestAnimSelect)

    StaffMenu.illegalHarvestCreate.Separator("ZONE DE RÉCOLTE", nil, nil, nil)

    StaffMenu.illegalHarvestCreate.Button(":ruler: RAYON DE LA ZONE", "Si > 1.5m, pas d'auto-orientation", tostring(harvestData.radius) .. "m", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rayon en mètres", tostring(harvestData.radius), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            harvestData.radius = tonumber(input) or 2.0
            StaffMenu.illegalHarvestCreate.refresh()
        end
    end)

    StaffMenu.illegalHarvestCreate.Button(":users: MAX RÉCOLTEURS", "Joueurs simultanés sur ce spot", tostring(harvestData.maxHarvesters), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre max de récolteurs", tostring(harvestData.maxHarvesters), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            harvestData.maxHarvesters = tonumber(input) or 1
            StaffMenu.illegalHarvestCreate.refresh()
        end
    end)

    StaffMenu.illegalHarvestCreate.Separator("ACCÈS (qui peut récolter)", nil, nil, nil)

    local factionLabel = harvestData.factionRestriction and GetFactionLabel(harvestData.factionRestriction) or "Tout le monde"
  local gradeLabel = harvestData.factionRestriction and ("Grade min: " .. (harvestData.factionGradeMin or 0)) or "Aucune restriction"
  StaffMenu.illegalHarvestCreate.Button(":flag: FACTION REQUISE", gradeLabel, factionLabel, "chevron", false, function()
    end, StaffMenu.illegalHarvestFactionSelect)

    StaffMenu.illegalHarvestCreate.Separator("BLIP SUR LA CARTE", nil, nil, nil)

    StaffMenu.illegalHarvestCreate.Checkbox(":pin: AFFICHER LE BLIP", "Visible sur la map pour les joueurs autorisés", false, harvestData.blipEnabled, function(checked)
        harvestData.blipEnabled = checked
        StaffMenu.illegalHarvestCreate.refresh()
    end)

    if harvestData.blipEnabled then
        StaffMenu.illegalHarvestCreate.Button(":palette: SPRITE", "Icône du blip", tostring(harvestData.blipSprite), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "ID du sprite", tostring(harvestData.blipSprite), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                harvestData.blipSprite = tonumber(input) or 1
                StaffMenu.illegalHarvestCreate.refresh()
            end
        end)

        StaffMenu.illegalHarvestCreate.Button(":palette: COULEUR", "Couleur du blip", tostring(harvestData.blipColor), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "ID couleur", tostring(harvestData.blipColor), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                harvestData.blipColor = tonumber(input) or 1
                StaffMenu.illegalHarvestCreate.refresh()
            end
        end)

        StaffMenu.illegalHarvestCreate.Button(":ruler: TAILLE", "Échelle du blip", tostring(harvestData.blipScale), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Taille", tostring(harvestData.blipScale), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                harvestData.blipScale = tonumber(input) or 0.8
                StaffMenu.illegalHarvestCreate.refresh()
            end
        end)

        StaffMenu.illegalHarvestCreate.Button(":edit: LABEL", "Texte affiché", harvestData.blipLabel or harvestData.name or "Auto", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Label du blip", harvestData.blipLabel or "", 50)
            if input and input ~= "KBD_CANCEL" then
                harvestData.blipLabel = input ~= "" and input or nil
                StaffMenu.illegalHarvestCreate.refresh()
            end
        end)
    end

    StaffMenu.illegalHarvestCreate.Separator("", nil, nil, nil)

    local isValid = harvestData.name and harvestData.coords and harvestData.itemOutput
    local btnLabel = harvestData.isUpdate and ":save: SAUVEGARDER LES MODIFICATIONS" or ":check: CRÉER LE SPOT"
  local btnDesc = not isValid and "Remplis nom, position et item" or nil

    StaffMenu.illegalHarvestCreate.Button(btnLabel, btnDesc, nil, "chevron", not isValid, function()
        local sendData = {
            name = harvestData.name,
            propModel = harvestData.propModel,
            coords = vec3ToTable(harvestData.coords),
            rotationZ = GetEntityHeading(PlayerPedId()),
            markerCoords = vec3ToTable(harvestData.markerCoords),
            itemOutput = harvestData.itemOutput,
            minQuantity = harvestData.minQuantity,
            maxQuantity = harvestData.maxQuantity,
            harvestTime = harvestData.harvestTime,
            cooldown = harvestData.cooldown,
            radius = harvestData.radius,
            maxHarvesters = harvestData.maxHarvesters,
            animationType = harvestData.animationType,
            animationPreset = harvestData.animationPreset,
            animationDict = harvestData.animationDict,
            animationName = harvestData.animationName,
            animationProp = harvestData.animationProp,
            factionRestriction = harvestData.factionRestriction,
            factionGradeMin = harvestData.factionGradeMin,
            blipEnabled = harvestData.blipEnabled,
            blipSprite = harvestData.blipSprite,
            blipColor = harvestData.blipColor,
            blipScale = harvestData.blipScale,
            blipLabel = harvestData.blipLabel
        }
        local result
        if harvestData.isUpdate then
            result = TriggerServerCallback("illegalBuilder:updateHarvestSpot", harvestData.id, sendData)
        else
            result = TriggerServerCallback("illegalBuilder:createHarvestSpot", sendData)
        end

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = harvestData.isUpdate and "Spot mis à jour." or "Spot créé." })
            local wasUpdate = harvestData.isUpdate
            ResetHarvestData()
            cachedHarvestSpots = TriggerServerCallback("illegalBuilder:getHarvestSpots") or {}
            Citizen.SetTimeout(50, function()
                StaffMenu.illegalHarvestCreate.close()
                if wasUpdate then
                    StaffMenu.illegalHarvestList.open()
                else
                    StaffMenu.illegalHarvestBuilder.open()
                end
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end


local harvestAnimIndexMap = {}

function StaffMenu.BuildIllegalHarvestAnimSelectMenu()
    CreateAnimPreview()
    currentAnimDict = nil
    currentAnimName = nil
    harvestAnimIndexMap = {}

    if not pendingAnimation then
        pendingAnimation = {
            type = harvestData.animationType,
            preset = harvestData.animationPreset,
            dict = harvestData.animationDict,
            anim = harvestData.animationName,
            prop = harvestData.animationProp
        }
    end

    local menuIndex = 1

    StaffMenu.illegalHarvestAnimSelect.Separator("ANIMATIONS PRÉDÉFINIES", nil, nil, nil)
    menuIndex = menuIndex + 1

    if not cachedPresets then
        cachedPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations")
    end

    for _, preset in ipairs(cachedPresets or {}) do
        local isSelected = pendingAnimation.type == "predefined" and pendingAnimation.preset == preset.id
        local propInfo = preset.prop and (" + " .. preset.prop) or ""

      harvestAnimIndexMap[menuIndex] = { dict = preset.dict, anim = preset.anim, preset = preset }

        StaffMenu.illegalHarvestAnimSelect.Button(
            preset.label, preset.dict .. " / " .. preset.anim .. propInfo, nil,
            isSelected and "check" or "chevron", false,
            function()
                pendingAnimation = {
                    type = "predefined",
                    preset = preset.id,
                    dict = preset.dict,
                    anim = preset.anim,
                    prop = preset.prop
                }
                StaffMenu.illegalHarvestAnimSelect.refresh()
            end
        )
        menuIndex = menuIndex + 1
    end

    StaffMenu.illegalHarvestAnimSelect.Separator("CUSTOM", nil, nil, nil)
    menuIndex = menuIndex + 1

    StaffMenu.illegalHarvestAnimSelect.Button(":film: ANIMATION CUSTOM", "Entrer dict/anim manuellement", nil, "chevron", false, function()
        local dict = VFW.Nui.KeyboardInput(true, "Animation Dictionary", pendingAnimation.dict or "", 100)
        if not dict or dict == "" or dict == "KBD_CANCEL" then return end

        local anim = VFW.Nui.KeyboardInput(true, "Animation Name", pendingAnimation.anim or "", 100)
        if not anim or anim == "" or anim == "KBD_CANCEL" then return end

        pendingAnimation = {
            type = "custom",
            preset = nil,
            dict = dict,
            anim = anim,
            prop = nil
        }
        PlayAnimOnPreview(dict, anim)
        StaffMenu.illegalHarvestAnimSelect.refresh()
    end)
    menuIndex = menuIndex + 1

    StaffMenu.illegalHarvestAnimSelect.Separator("", nil, nil, nil)
    menuIndex = menuIndex + 1

    StaffMenu.illegalHarvestAnimSelect.Button(":check: VALIDER", "Confirmer l'animation sélectionnée", nil, "chevron", false, function()
        harvestData.animationType = pendingAnimation.type
        harvestData.animationPreset = pendingAnimation.preset
        harvestData.animationDict = pendingAnimation.dict
        harvestData.animationName = pendingAnimation.anim
        harvestData.animationProp = pendingAnimation.prop
        DeleteAnimPreview()
        pendingAnimation = nil
        currentAnimDict = nil
        currentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.illegalHarvestAnimSelect.close()
            StaffMenu.illegalHarvestCreate.open()
        end)
    end)

    StaffMenu.illegalHarvestAnimSelect.Button(":x: ANNULER", "Revenir sans changer", nil, "chevron", false, function()
        DeleteAnimPreview()
        pendingAnimation = nil
        currentAnimDict = nil
        currentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.illegalHarvestAnimSelect.close()
            StaffMenu.illegalHarvestCreate.open()
        end)
    end)
end

StaffMenu.illegalHarvestAnimSelect.OnIndexChange(function(index, item)
    local animData = harvestAnimIndexMap[index]
    if animData and animData.dict and animData.anim then
        PlayAnimOnPreview(animData.dict, animData.anim)
    end
end)

function StaffMenu.BuildIllegalHarvestFactionSelectMenu()
    if not cachedFactions then
        cachedFactions = TriggerServerCallback("illegalBuilder:getFactions")
    end

    StaffMenu.illegalHarvestFactionSelect.Button(":x: AUCUNE RESTRICTION", "Accessible à tous", nil,
        not harvestData.factionRestriction and "check" or "chevron", false,
        function()
            harvestData.factionRestriction = nil
            harvestData.factionGradeMin = nil
            StaffMenu.illegalHarvestFactionSelect.close()
            StaffMenu.illegalHarvestFactionSelect.parent.open()
        end
    )

    StaffMenu.illegalHarvestFactionSelect.Separator("FACTIONS", nil, nil, nil)

    for _, faction in ipairs(cachedFactions or {}) do
        local isSelected = harvestData.factionRestriction == faction.name
        StaffMenu.illegalHarvestFactionSelect.Button(
            faction.label, faction.name, nil,
            "chevron", false,
            function()
                pendingFactionSelect = "harvest"
              harvestData.factionRestriction = faction.name
                cachedFactionGrades = TriggerServerCallback("illegalBuilder:getFactionGrades", faction.name) or {}
            end,
            StaffMenu.illegalHarvestGradeSelect
        )
    end
end

function StaffMenu.BuildIllegalHarvestGradeSelectMenu()
    if not harvestData.factionRestriction then
        StaffMenu.illegalHarvestGradeSelect.close()
        StaffMenu.illegalHarvestGradeSelect.parent.open()
        return
    end

    local factionLabel = GetFactionLabel(harvestData.factionRestriction)
    StaffMenu.illegalHarvestGradeSelect.Separator("Grades de " .. factionLabel, nil, nil, nil)

    StaffMenu.illegalHarvestGradeSelect.Button("Grade 0", "Tous les membres", nil,
        harvestData.factionGradeMin == 0 and "check" or "chevron", false,
        function()
            harvestData.factionGradeMin = 0
            StaffMenu.illegalHarvestGradeSelect.close()
            StaffMenu.illegalHarvestCreate.open()
        end
    )

    for _, grade in ipairs(cachedFactionGrades or {}) do
        local isSelected = harvestData.factionGradeMin == grade.grade
        StaffMenu.illegalHarvestGradeSelect.Button(
            grade.label or ("Grade " .. grade.grade),
            "Grade " .. grade.grade,
            nil,
            isSelected and "check" or "chevron", false,
            function()
                harvestData.factionGradeMin = grade.grade
                StaffMenu.illegalHarvestGradeSelect.close()
                StaffMenu.illegalHarvestCreate.open()
            end
        )
    end
end

function StaffMenu.BuildIllegalStationBuilderMenu()
    StaffMenu.illegalStationBuilder.Button(":plus: CRÉER UNE STATION", "Nouvelle station de craft", nil, "chevron", false, function()
        ResetStationData()
    end, StaffMenu.illegalStationCreate)

    StaffMenu.illegalStationBuilder.Button(":report: LISTE DES STATIONS", "Voir et modifier les stations", nil, "chevron", false, function()
        cachedCraftStations = TriggerServerCallback("illegalBuilder:getCraftStations") or {}
    end, StaffMenu.illegalStationList)
end

function StaffMenu.BuildIllegalStationListMenu()
    if not cachedCraftStations or next(cachedCraftStations) == nil then
        StaffMenu.illegalStationList.Button(":x: AUCUNE STATION", "Créez-en une d'abord", nil, nil, true, function() end)
        return
    end

    for id, station in pairs(cachedCraftStations) do
        local recipeCount = station.recipes and #station.recipes or 0
        StaffMenu.illegalStationList.Button(
            ":building: " .. station.name,
            recipeCount .. " recettes",
            "#" .. id,
            "chevron", false,
            function()
                currentStation = station
            end,
            StaffMenu.illegalStationManage
        )
    end
end

function StaffMenu.BuildIllegalStationManageMenu()
    if not currentStation then return end

    local station = currentStation

    StaffMenu.illegalStationManage.Separator("INFORMATIONS", nil, nil, nil)
    StaffMenu.illegalStationManage.Button("Nom", station.name, nil, nil, true, function() end)
    if station.prop_model then
        StaffMenu.illegalStationManage.Button("Prop", station.prop_model, nil, nil, true, function() end)
    end
    StaffMenu.illegalStationManage.Button("Distance", (station.interaction_distance or 2.0) .. "m", nil, nil, true, function() end)

    if station.faction_restriction then
        StaffMenu.illegalStationManage.Button("Faction", GetFactionLabel(station.faction_restriction), nil, nil, true, function() end)
    end

    local recipeCount = station.recipes and #station.recipes or 0
    StaffMenu.illegalStationManage.Button("Recettes", recipeCount .. " assignées", nil, nil, true, function() end)

    StaffMenu.illegalStationManage.Separator("ACTIONS", nil, nil, nil)

    StaffMenu.illegalStationManage.Button(":pin: SE TÉLÉPORTER", nil, nil, "chevron", false, function()
        SetEntityCoords(PlayerPedId(), station.coords_x, station.coords_y, station.coords_z, false, false, false, false)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Téléporté à la station." })
    end)

    StaffMenu.illegalStationManage.Button(":report: GÉRER RECETTES", "Assigner des recettes", nil, "chevron", false, function()
        cachedRecipes = TriggerServerCallback("illegalBuilder:getRecipes") or {}
    end, StaffMenu.illegalStationRecipes)

    StaffMenu.illegalStationManage.Button(":edit: MODIFIER", nil, nil, "chevron", false, function()
        stationData = {
            name = station.name,
            description = station.description,
            category = station.station_type or station.category,
            propModel = station.prop_model,
            coords = vector3(station.coords_x, station.coords_y, station.coords_z),
            markerCoords = (station.marker_x and station.marker_y and station.marker_z) and vector3(station.marker_x, station.marker_y, station.marker_z) or nil,
            interactionDistance = station.interaction_distance or 2.0,
            factionRestriction = station.faction_restriction,
            factionGradeMin = station.faction_grade_min,
            recipes = station.recipes or {},
            blipEnabled = station.blip_enabled or false,
            blipSprite = station.blip_sprite or 566,
            blipColor = station.blip_color or 1,
            blipScale = station.blip_scale or 0.8,
            blipLabel = station.blip_label,
            isUpdate = true,
            id = station.id
        }
        if stationData.propModel and stationData.coords then
            SpawnPreviewProp("station", stationData.propModel, stationData.coords)
        end
    end, StaffMenu.illegalStationCreate)

    StaffMenu.illegalStationManage.Button(":trash: SUPPRIMER", nil, nil, "chevron", false, function()
        local result = TriggerServerCallback("illegalBuilder:deleteCraftStation", station.id)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Station supprimée." })
            StaffMenu.illegalStationManage.close()
            StaffMenu.illegalStationManage.parent.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end

function StaffMenu.BuildIllegalStationCreateMenu()
    StaffMenu.illegalStationCreate.Separator("TYPE D'ÉTABLI", nil, nil, nil)

    local categoryKeys = { "gpb", "armes", "munitions" }
    local categoryLabels = { ":shield: Gilet Pare-Balles", ":gun: Armes", ":target: Munitions" }
    local currentCatIndex = 1
    for i, cat in ipairs(categoryKeys) do
        if stationData.category == cat then
            currentCatIndex = i
            break
        end
    end

    StaffMenu.illegalStationCreate.List(":folder: CATÉGORIE", "Détermine le prop et les recettes dispo", false, categoryLabels, currentCatIndex, function(index)
        stationData.category = categoryKeys[index]
        stationData.propModel = CATEGORY_PROPS[categoryKeys[index]]

        if stationData.propModel then
            local defaultPos = GetDefaultPropPosition()
            stationData.coords = defaultPos.coords
            stationData.markerCoords = defaultPos.markerCoords
            SpawnPreviewProp("station", stationData.propModel, stationData.coords)
        end
        StaffMenu.illegalStationCreate.refresh()
    end)

    StaffMenu.illegalStationCreate.Separator("INFORMATIONS DE LA STATION", nil, nil, nil)

    StaffMenu.illegalStationCreate.Button(":edit: NOM DE LA STATION", "Nom affiché pour les joueurs", stationData.name or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la station (ex: Établi des Ballas)", stationData.name or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            stationData.name = input
            StaffMenu.illegalStationCreate.refresh()
        end
    end)

    StaffMenu.illegalStationCreate.Separator("PLACEMENT DANS LE MONDE", nil, nil, nil)

    StaffMenu.illegalStationCreate.Button(":palette: MODÈLE DU PROP", "Objet 3D affiché (optionnel)", stationData.propModel or "Aucun - marqueur seul", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Modèle du prop (laisser vide = sans prop)", stationData.propModel or "", 100)
        if input and input ~= "KBD_CANCEL" then
            local newModel = input ~= "" and input or nil
            stationData.propModel = newModel
            if newModel then
                if not stationData.coords then
                    local defaultPos = GetDefaultPropPosition()
                    stationData.coords = defaultPos.coords
                    stationData.markerCoords = defaultPos.markerCoords
                end
                SpawnPreviewProp("station", newModel, stationData.coords)
            else
                DeletePreviewProp("station")
            end
            StaffMenu.illegalStationCreate.refresh()
        end
    end)

    local coordsLabel = stationData.coords and string.format("%.1f, %.1f, %.1f", stationData.coords.x, stationData.coords.y, stationData.coords.z) or "Non défini"
  StaffMenu.illegalStationCreate.Button(":pin: POSITION", stationData.propModel and "Place le prop devant toi" or "Place la station à ta position", coordsLabel, "chevron", false, function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if stationData.propModel then
            local defaultPos = GetDefaultPropPosition()
            stationData.coords = defaultPos.coords
            stationData.markerCoords = defaultPos.markerCoords
            SpawnPreviewProp("station", stationData.propModel, stationData.coords)
        else
            stationData.coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
            stationData.markerCoords = nil
        end

        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Position définie." })
        StaffMenu.illegalStationCreate.refresh()
    end)

    if stationPreviewProp and DoesEntityExist(stationPreviewProp) then
        StaffMenu.illegalStationCreate.Button(":trash: SUPPRIMER PREVIEW", "Retire le prop et la position", nil, "chevron", false, function()
            DeletePreviewProp("station")
            stationData.propModel = nil
            stationData.coords = nil
            stationData.markerCoords = nil
            StaffMenu.illegalStationCreate.refresh()
        end)
    end

    StaffMenu.illegalStationCreate.Button(":ruler: DISTANCE D'INTERACTION", "Portée pour accéder à l'établi", tostring(stationData.interactionDistance) .. "m", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Distance en mètres", tostring(stationData.interactionDistance), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            stationData.interactionDistance = tonumber(input) or 2.0
            StaffMenu.illegalStationCreate.refresh()
        end
    end)

    StaffMenu.illegalStationCreate.Separator("ACCÈS (qui peut utiliser)", nil, nil, nil)

    local factionLabel = stationData.factionRestriction and GetFactionLabel(stationData.factionRestriction) or "Tout le monde"
  local gradeLabel = stationData.factionRestriction and ("Grade min: " .. (stationData.factionGradeMin or 0)) or "Aucune restriction"
  StaffMenu.illegalStationCreate.Button(":flag: FACTION REQUISE", gradeLabel, factionLabel, "chevron", false, function()
    end, StaffMenu.illegalStationFactionSelect)

    StaffMenu.illegalStationCreate.Separator("BLIP SUR LA CARTE", nil, nil, nil)

    StaffMenu.illegalStationCreate.Checkbox(":pin: AFFICHER LE BLIP", "Visible sur la map pour les joueurs autorisés", false, stationData.blipEnabled, function(checked)
        stationData.blipEnabled = checked
        StaffMenu.illegalStationCreate.refresh()
    end)

    if stationData.blipEnabled then
        StaffMenu.illegalStationCreate.Button(":palette: SPRITE", "Icône du blip (voir wiki GTA)", tostring(stationData.blipSprite), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "ID du sprite (ex: 566)", tostring(stationData.blipSprite), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                stationData.blipSprite = tonumber(input) or 566
                StaffMenu.illegalStationCreate.refresh()
            end
        end)

        StaffMenu.illegalStationCreate.Button(":palette: COULEUR", "Couleur du blip", tostring(stationData.blipColor), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "ID couleur (ex: 1=rouge, 2=vert)", tostring(stationData.blipColor), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                stationData.blipColor = tonumber(input) or 1
                StaffMenu.illegalStationCreate.refresh()
            end
        end)

        StaffMenu.illegalStationCreate.Button(":ruler: TAILLE", "Échelle du blip (0.5-1.5)", tostring(stationData.blipScale), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Taille (ex: 0.8)", tostring(stationData.blipScale), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                stationData.blipScale = tonumber(input) or 0.8
                StaffMenu.illegalStationCreate.refresh()
            end
        end)

        StaffMenu.illegalStationCreate.Button(":edit: LABEL", "Texte affiché sur la map", stationData.blipLabel or stationData.name or "Auto", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Label du blip (vide = nom de la station)", stationData.blipLabel or "", 50)
            if input and input ~= "KBD_CANCEL" then
                stationData.blipLabel = input ~= "" and input or nil
                StaffMenu.illegalStationCreate.refresh()
            end
        end)
    end

    StaffMenu.illegalStationCreate.Separator("", nil, nil, nil)

    local isValid = stationData.name and stationData.coords
    local btnLabel = stationData.isUpdate and ":save: SAUVEGARDER LES MODIFICATIONS" or ":check: CRÉER LA STATION"
  local btnDesc = not isValid and "Remplis le nom et la position" or nil

    StaffMenu.illegalStationCreate.Button(btnLabel, btnDesc, nil, "chevron", not isValid, function()
        local sendData = {
            name = stationData.name,
            description = stationData.description,
            stationType = stationData.category,
            propModel = stationData.propModel,
            coords = vec3ToTable(stationData.coords),
            rotationZ = GetEntityHeading(PlayerPedId()),
            markerCoords = vec3ToTable(stationData.markerCoords),
            interactionDistance = stationData.interactionDistance,
            factionRestriction = stationData.factionRestriction,
            factionGradeMin = stationData.factionGradeMin,
            recipes = stationData.recipes,
            blipEnabled = stationData.blipEnabled,
            blipSprite = stationData.blipSprite,
            blipColor = stationData.blipColor,
            blipScale = stationData.blipScale,
            blipLabel = stationData.blipLabel
        }
        local result
        if stationData.isUpdate then
            result = TriggerServerCallback("illegalBuilder:updateCraftStation", stationData.id, sendData)
        else
            result = TriggerServerCallback("illegalBuilder:createCraftStation", sendData)
        end

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = stationData.isUpdate and "Station mise à jour." or "Station créée." })
            local wasUpdate = stationData.isUpdate
            ResetStationData()
            cachedCraftStations = TriggerServerCallback("illegalBuilder:getCraftStations") or {}
            Citizen.SetTimeout(50, function()
                StaffMenu.illegalStationCreate.close()
                if wasUpdate then
                    StaffMenu.illegalStationList.open()
                else
                    StaffMenu.illegalStationBuilder.open()
                end
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end

function StaffMenu.BuildIllegalStationFactionSelectMenu()
    if not cachedFactions then
        cachedFactions = TriggerServerCallback("illegalBuilder:getFactions")
    end

    StaffMenu.illegalStationFactionSelect.Button(":x: AUCUNE RESTRICTION", nil, nil,
        not stationData.factionRestriction and "check" or "chevron", false,
        function()
            stationData.factionRestriction = nil
            stationData.factionGradeMin = nil
            StaffMenu.illegalStationFactionSelect.close()
            StaffMenu.illegalStationFactionSelect.parent.open()
        end
    )

    for _, faction in ipairs(cachedFactions or {}) do
        local isSelected = stationData.factionRestriction == faction.name
        StaffMenu.illegalStationFactionSelect.Button(
            faction.label, faction.name, nil,
            "chevron", false,
            function()
                pendingFactionSelect = "station"
              stationData.factionRestriction = faction.name
                cachedFactionGrades = TriggerServerCallback("illegalBuilder:getFactionGrades", faction.name) or {}
            end,
            StaffMenu.illegalStationGradeSelect
        )
    end
end

function StaffMenu.BuildIllegalStationGradeSelectMenu()
    if not stationData.factionRestriction then
        StaffMenu.illegalStationGradeSelect.close()
        StaffMenu.illegalStationGradeSelect.parent.open()
        return
    end

    local factionLabel = GetFactionLabel(stationData.factionRestriction)
    StaffMenu.illegalStationGradeSelect.Separator("Grades de " .. factionLabel, nil, nil, nil)

    StaffMenu.illegalStationGradeSelect.Button("Grade 0", "Tous les membres", nil,
        stationData.factionGradeMin == 0 and "check" or "chevron", false,
        function()
            stationData.factionGradeMin = 0
            StaffMenu.illegalStationGradeSelect.close()
            StaffMenu.illegalStationCreate.open()
        end
    )

    for _, grade in ipairs(cachedFactionGrades or {}) do
        local isSelected = stationData.factionGradeMin == grade.grade
        StaffMenu.illegalStationGradeSelect.Button(
            grade.label or ("Grade " .. grade.grade),
            "Grade " .. grade.grade,
            nil,
            isSelected and "check" or "chevron", false,
            function()
                stationData.factionGradeMin = grade.grade
                StaffMenu.illegalStationGradeSelect.close()
                StaffMenu.illegalStationCreate.open()
            end
        )
    end
end

local _recipeCats = {}
local _recipeAssign = {}
local _recipeCatsInit = false
local _recipeCatsStationId = nil
local _selectedCatIdx = nil

local function _initRecipeCats()
    local stationId = currentStation and currentStation.id or nil
    if _recipeCatsInit and _recipeCatsStationId == stationId then return end
    _recipeCats = {}
    _recipeAssign = {}
    for _, entry in ipairs((currentStation and currentStation.recipes) or {}) do
        local rid = type(entry) == "table" and entry.id or entry
        local cat = type(entry) == "table" and entry.category or nil
        _recipeAssign[rid] = cat
        if cat and cat ~= "" then
            local found = false
            for _, c in ipairs(_recipeCats) do
                if c == cat then found = true break end
            end
            if not found then
                table.insert(_recipeCats, cat)
            end
        end
    end
    _recipeCatsInit = true
    _recipeCatsStationId = stationId
end

local function _resetRecipeCats()
    _recipeCats = {}
    _recipeAssign = {}
    _recipeCatsInit = false
    _recipeCatsStationId = nil
end

function StaffMenu.BuildIllegalStationRecipesMenu()
    if not currentStation then return end

    _initRecipeCats()

    if not cachedRecipes or next(cachedRecipes) == nil then
        StaffMenu.illegalStationRecipes.Button("Aucune recette", "Créez des recettes d'abord", nil, nil, true, function() end)
        return
    end

    StaffMenu.illegalStationRecipes.Button("Créer une catégorie", nil, #_recipeCats .. (#_recipeCats > 1 and " existantes" or " existante"), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de la catégorie", "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            local exists = false
            for _, c in ipairs(_recipeCats) do
                if c == input then exists = true break end
            end
            if exists then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = "Cette catégorie existe déjà." })
            else
                table.insert(_recipeCats, input)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Catégorie ajoutée." })
                StaffMenu.illegalStationRecipes.refresh()
            end
        end
    end)

    StaffMenu.illegalStationRecipes.Separator("CATÉGORIES", nil, nil, nil)

    for catIdx, category in ipairs(_recipeCats) do
        local count = 0
        for _, cat in pairs(_recipeAssign) do
            if cat == category then count = count + 1 end
        end
        StaffMenu.illegalStationRecipes.Button(category, count .. (count > 1 and " recettes" or " recette"), nil, "chevron", false, function()
            _selectedCatIdx = catIdx
        end, StaffMenu.illegalStationCatDetail)
    end

    if #_recipeCats == 0 then
        StaffMenu.illegalStationRecipes.Button("Aucune catégorie", "Créez-en une ci-dessus", nil, nil, true, function() end)
    end

    local hasUncategorized = false
    for id, _ in pairs(cachedRecipes) do
        if _recipeAssign[id] == nil then
            hasUncategorized = true
            break
        end
    end

    if hasUncategorized and #_recipeCats > 0 then
        StaffMenu.illegalStationRecipes.Separator("NON CATÉGORISÉ", nil, nil, nil)
        for id, recipe in pairs(cachedRecipes) do
            if _recipeAssign[id] == nil then
                StaffMenu.illegalStationRecipes.Button(
                    recipe.label,
                    recipe.name,
                    nil, nil, true, function() end
                )
            end
        end
    end

    StaffMenu.illegalStationRecipes.Separator("", nil, nil, nil)

    StaffMenu.illegalStationRecipes.Button("SAUVEGARDER", nil, nil, "check", false, function()
        local assignments = {}
        for rid, cat in pairs(_recipeAssign) do
            table.insert(assignments, { recipeId = rid, category = cat })
        end
        local assignedIds = {}
        for _, a in ipairs(assignments) do assignedIds[a.recipeId] = true end
        for _, entry in ipairs(currentStation.recipes or {}) do
            local rid = type(entry) == "table" and entry.id or entry
            if not assignedIds[rid] then
                table.insert(assignments, { recipeId = rid, category = nil })
            end
        end

        currentStation.recipes = {}
        for _, a in ipairs(assignments) do
            table.insert(currentStation.recipes, { id = a.recipeId, category = a.category })
        end

        local result = TriggerServerCallback("illegalBuilder:assignRecipes", currentStation.id, assignments)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Recettes mises à jour." })
            _resetRecipeCats()
            Citizen.SetTimeout(50, function()
                StaffMenu.illegalStationRecipes.close()
                StaffMenu.illegalStationManage.open()
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end

function StaffMenu.BuildIllegalStationCatDetailMenu()
    if not _selectedCatIdx or not _recipeCats[_selectedCatIdx] then return end
    local category = _recipeCats[_selectedCatIdx]

    StaffMenu.illegalStationCatDetail.Separator("RECETTES", nil, nil, nil)

    for id, recipe in pairs(cachedRecipes) do
        local isInThisCat = _recipeAssign[id] == category
        StaffMenu.illegalStationCatDetail.Checkbox(
            recipe.label,
            recipe.name,
            false,
            isInThisCat,
            function(checked)
                if checked then
                    _recipeAssign[id] = category
                else
                    if _recipeAssign[id] == category then
                        _recipeAssign[id] = nil
                    end
                end
                StaffMenu.illegalStationCatDetail.refresh()
            end
        )
    end

    StaffMenu.illegalStationCatDetail.Separator("", nil, nil, nil)

    StaffMenu.illegalStationCatDetail.Button("Renommer", nil, category, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau nom", category, 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" and input ~= category then
            local oldName = category
            _recipeCats[_selectedCatIdx] = input
            for rid, cat in pairs(_recipeAssign) do
                if cat == oldName then
                    _recipeAssign[rid] = input
                end
            end
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Catégorie renommée." })
            StaffMenu.illegalStationCatDetail.refresh()
        end
    end)

    StaffMenu.illegalStationCatDetail.Button("Supprimer la catégorie", nil, nil, "trash", false, function()
        for rid, cat in pairs(_recipeAssign) do
            if cat == category then
                _recipeAssign[rid] = nil
            end
        end
        table.remove(_recipeCats, _selectedCatIdx)
        _selectedCatIdx = nil
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Catégorie supprimée." })
        StaffMenu.illegalStationCatDetail.close()
        StaffMenu.illegalStationRecipes.open()
    end)
end

function StaffMenu.BuildIllegalRecipeBuilderMenu()
    StaffMenu.illegalRecipeBuilder.Button(":plus: CRÉER UNE RECETTE", "Nouvelle recette de craft", nil, "chevron", false, function()
        ResetRecipeData()
    end, StaffMenu.illegalRecipeCreate)

    StaffMenu.illegalRecipeBuilder.Button(":report: LISTE DES RECETTES", "Voir et modifier les recettes", nil, "chevron", false, function()
        cachedRecipes = TriggerServerCallback("illegalBuilder:getRecipes") or {}
    end, StaffMenu.illegalRecipeList)
end

function StaffMenu.BuildIllegalRecipeListMenu()
    if not cachedRecipes or next(cachedRecipes) == nil then
        StaffMenu.illegalRecipeList.Button(":x: AUCUNE RECETTE", "Créez-en une d'abord", nil, nil, true, function() end)
        return
    end

    for id, recipe in pairs(cachedRecipes) do
        local ingredientCount = recipe.requirements and #recipe.requirements or 0
        StaffMenu.illegalRecipeList.Button(
            ":report: " .. recipe.label,
            ingredientCount .. " composants",
            "#" .. id,
            "chevron", false,
            function()
                currentRecipe = recipe
            end,
            StaffMenu.illegalRecipeManage
        )
    end
end

function StaffMenu.BuildIllegalRecipeManageMenu()
    if not currentRecipe then return end

    local recipe = currentRecipe

    StaffMenu.illegalRecipeManage.Separator("INFORMATIONS", nil, nil, nil)
    StaffMenu.illegalRecipeManage.Button("Nom", recipe.name, nil, nil, true, function() end)
    StaffMenu.illegalRecipeManage.Button("Label", recipe.label, nil, nil, true, function() end)
    StaffMenu.illegalRecipeManage.Button("Résultat", GetItemLabel(recipe.outputItem) .. " x" .. recipe.outputQuantity, nil, nil, true, function() end)
    StaffMenu.illegalRecipeManage.Button("Temps", (recipe.craftTime / 1000) .. "s", nil, nil, true, function() end)

    StaffMenu.illegalRecipeManage.Separator("COMPOSANTS", nil, nil, nil)
    for _, ing in ipairs(recipe.requirements or {}) do
        StaffMenu.illegalRecipeManage.Button(GetItemLabel(ing.name), "x" .. ing.amount, nil, nil, true, function() end)
    end

    StaffMenu.illegalRecipeManage.Separator("ACTIONS", nil, nil, nil)

    StaffMenu.illegalRecipeManage.Button(":edit: MODIFIER", nil, nil, "chevron", false, function()
        recipeData = {
            name = recipe.name,
            label = recipe.label,
            category = recipe.category,
            outputItem = recipe.outputItem,
            outputQuantity = recipe.outputQuantity,
            craftTime = recipe.craftTime,
            animationType = recipe.animationType,
            animationPreset = recipe.animationPreset,
            animationDict = recipe.animationDict,
            animationName = recipe.animationName,
            animationProp = recipe.animationProp,
            ingredients = {},
            isUpdate = true,
            id = recipe.id,
            gpbType = recipe.gpbType,
            gpbColor = recipe.gpbColor
        }
        for _, ing in ipairs(recipe.requirements or {}) do
            table.insert(recipeData.ingredients, { name = ing.name, amount = ing.amount })
        end
    end, StaffMenu.illegalRecipeCreate)

    StaffMenu.illegalRecipeManage.Button(":trash: SUPPRIMER", nil, nil, "chevron", false, function()
        local result = TriggerServerCallback("illegalBuilder:deleteRecipe", recipe.id)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Recette supprimée." })
            StaffMenu.illegalRecipeManage.close()
            StaffMenu.illegalRecipeManage.parent.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end

local function GenerateIllegalRecipeId(label)
    if not label or label == "" then return nil end
    local id = string.lower(label)
    id = id:gsub("[éèêë]", "e"):gsub("[àâä]", "a"):gsub("[ùûü]", "u"):gsub("[îï]", "i"):gsub("[ôö]", "o"):gsub("ç", "c")
    id = id:gsub("%s+", "_"):gsub("[^a-z0-9_]", "")
    return id
end

function StaffMenu.BuildIllegalRecipeCreateMenu()
    StaffMenu.illegalRecipeCreate.Separator("INFORMATIONS DE LA RECETTE", nil, nil, nil)

    StaffMenu.illegalRecipeCreate.Button(":edit: NOM DE LA RECETTE", "Nom affiché dans le menu", recipeData.label or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom affiché (ex: Pochon de Meth)", recipeData.label or "", 100)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            recipeData.label = input
            if not recipeData.isUpdate then
                recipeData.name = GenerateIllegalRecipeId(input)
            end
            StaffMenu.illegalRecipeCreate.refresh()
        end
    end)

    if recipeData.name then
        StaffMenu.illegalRecipeCreate.Button(":key: IDENTIFIANT", "Généré automatiquement", recipeData.name, nil, true, function() end)
    end

    StaffMenu.illegalRecipeCreate.Separator("ITEM FINAL (ce que le joueur reçoit)", nil, nil, nil)

    StaffMenu.illegalRecipeCreate.Button(":box: NOM DE L'ITEM", "Item donné après le craft", recipeData.outputItem or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de l'item (ex: weapon_pistol)", recipeData.outputItem or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            recipeData.outputItem = input
            if input == "gpb" then
                recipeData.gpbType = recipeData.gpbType or "light"
              recipeData.gpbColor = recipeData.gpbColor or "black"
          else
                recipeData.gpbType = nil
                recipeData.gpbColor = nil
            end
            StaffMenu.illegalRecipeCreate.refresh()
        end
    end)

    if recipeData.outputItem == "gpb" then
        local typeLabels = {}
        local typeIndex = 1
        for i, t in ipairs(GPB_TYPES) do
            table.insert(typeLabels, t.label)
            if recipeData.gpbType == t.id then typeIndex = i end
        end
        StaffMenu.illegalRecipeCreate.List(":shield: TYPE KEVLAR", "Protection du gilet", false, typeLabels, typeIndex, function(index, value)
            recipeData.gpbType = GPB_TYPES[index].id
        end)

        local colorLabels = {}
        local colorIndex = 1
        for i, c in ipairs(GPB_COLORS) do
            table.insert(colorLabels, c.label)
            if recipeData.gpbColor == c.id then colorIndex = i end
        end
        StaffMenu.illegalRecipeCreate.List(":palette: COULEUR", "Couleur du gilet", false, colorLabels, colorIndex, function(index, value)
            recipeData.gpbColor = GPB_COLORS[index].id
        end)
    end

    StaffMenu.illegalRecipeCreate.Button(":hash: QUANTITÉ", "Nombre d'items reçus", tostring(recipeData.outputQuantity), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité produite", tostring(recipeData.outputQuantity), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            recipeData.outputQuantity = tonumber(input) or 1
            StaffMenu.illegalRecipeCreate.refresh()
        end
    end)

    StaffMenu.illegalRecipeCreate.Separator("PARAMÈTRES DU CRAFT", nil, nil, nil)

    StaffMenu.illegalRecipeCreate.Button(":clock: DURÉE DU CRAFT", "Temps en secondes", tostring(recipeData.craftTime / 1000) .. "s", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Temps en secondes", tostring(recipeData.craftTime / 1000), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            recipeData.craftTime = (tonumber(input) or 5) * 1000
            StaffMenu.illegalRecipeCreate.refresh()
        end
    end)

    local animLabel = recipeData.animationType == "predefined" and (recipeData.animationPreset and GetPresetLabel(recipeData.animationPreset) or "Choisir...") or "Custom"
  StaffMenu.illegalRecipeCreate.Button(":film: ANIMATION", "Animation jouée pendant le craft", animLabel, "chevron", false, function()
        pendingAnimation = {
            type = recipeData.animationType,
            preset = recipeData.animationPreset,
            dict = recipeData.animationDict,
            anim = recipeData.animationName,
            prop = recipeData.animationProp
        }
    end, StaffMenu.illegalRecipeAnimSelect)

    StaffMenu.illegalRecipeCreate.Separator("COMPOSANTS REQUIS (" .. #recipeData.ingredients .. ")", nil, nil, nil)

    if #recipeData.ingredients == 0 then
        StaffMenu.illegalRecipeCreate.Button(":report: Aucun composant", "Ajoute des items requis ci-dessous", nil, nil, true, function() end)
    else
        for i, ing in ipairs(recipeData.ingredients) do
            StaffMenu.illegalRecipeCreate.Button(
                GetItemLabel(ing.name),
                "Cliquer pour retirer",
                "x" .. ing.amount,
                "cross", false,
                function()
                    table.remove(recipeData.ingredients, i)
                    StaffMenu.illegalRecipeCreate.refresh()
                end
            )
        end
    end

    StaffMenu.illegalRecipeCreate.Button(":plus: AJOUTER UN COMPOSANT", "Item consommé pour le craft", nil, "chevron", false, function()
        local itemName = VFW.Nui.KeyboardInput(true, "Nom de l'item requis (ex: plastic)", "", 50)
        if not itemName or itemName == "" or itemName == "KBD_CANCEL" then return end

        local amountStr = VFW.Nui.KeyboardInput(true, "Quantité nécessaire", "1", 5)
        local amount = tonumber(amountStr) or 1

        table.insert(recipeData.ingredients, { name = itemName, amount = amount })
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Composant ajouté: " .. itemName .. "." })
        StaffMenu.illegalRecipeCreate.refresh()
    end)

    StaffMenu.illegalRecipeCreate.Separator("", nil, nil, nil)

    local isValid = recipeData.name and recipeData.label and recipeData.outputItem and #recipeData.ingredients > 0
    local btnLabel = recipeData.isUpdate and ":save: SAUVEGARDER LES MODIFICATIONS" or ":check: CRÉER LA RECETTE"
  local btnDesc = not isValid and "Remplis tous les champs requis" or nil

    StaffMenu.illegalRecipeCreate.Button(btnLabel, btnDesc, nil, "chevron", not isValid, function()
        local result
        if recipeData.isUpdate then
            result = TriggerServerCallback("illegalBuilder:updateRecipe", recipeData.id, recipeData)
        else
            result = TriggerServerCallback("illegalBuilder:createRecipe", recipeData)
        end

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = recipeData.isUpdate and "Recette mise à jour." or "Recette créée." })
            local wasUpdate = recipeData.isUpdate
            ResetRecipeData()
            cachedRecipes = TriggerServerCallback("illegalBuilder:getRecipes") or {}
            Citizen.SetTimeout(50, function()
                StaffMenu.illegalRecipeCreate.close()
                if wasUpdate then
                    StaffMenu.illegalRecipeList.open()
                else
                    StaffMenu.illegalRecipeBuilder.open()
                end
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end


local recipeAnimIndexMap = {}

function StaffMenu.BuildIllegalRecipeAnimSelectMenu()
    CreateAnimPreview()
    currentAnimDict = nil
    currentAnimName = nil
    recipeAnimIndexMap = {}

    if not pendingAnimation then
        pendingAnimation = {
            type = recipeData.animationType,
            preset = recipeData.animationPreset,
            dict = recipeData.animationDict,
            anim = recipeData.animationName,
            prop = recipeData.animationProp
        }
    end

    local menuIndex = 1

    StaffMenu.illegalRecipeAnimSelect.Separator("ANIMATIONS PRÉDÉFINIES", nil, nil, nil)
    menuIndex = menuIndex + 1

    if not cachedPresets then
        cachedPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations")
    end

    for _, preset in ipairs(cachedPresets or {}) do
        local isSelected = pendingAnimation.type == "predefined" and pendingAnimation.preset == preset.id
        local propInfo = preset.prop and (" + " .. preset.prop) or ""

      recipeAnimIndexMap[menuIndex] = { dict = preset.dict, anim = preset.anim, preset = preset }

        StaffMenu.illegalRecipeAnimSelect.Button(
            preset.label, preset.dict .. " / " .. preset.anim .. propInfo, nil,
            isSelected and "check" or "chevron", false,
            function()
                pendingAnimation = {
                    type = "predefined",
                    preset = preset.id,
                    dict = preset.dict,
                    anim = preset.anim,
                    prop = preset.prop
                }
                StaffMenu.illegalRecipeAnimSelect.refresh()
            end
        )
        menuIndex = menuIndex + 1
    end

    StaffMenu.illegalRecipeAnimSelect.Separator("CUSTOM", nil, nil, nil)
    menuIndex = menuIndex + 1

    StaffMenu.illegalRecipeAnimSelect.Button(":film: ANIMATION CUSTOM", "Entrer dict/anim manuellement", nil, "chevron", false, function()
        local dict = VFW.Nui.KeyboardInput(true, "Animation Dictionary", pendingAnimation.dict or "", 100)
        if not dict or dict == "" or dict == "KBD_CANCEL" then return end

        local anim = VFW.Nui.KeyboardInput(true, "Animation Name", pendingAnimation.anim or "", 100)
        if not anim or anim == "" or anim == "KBD_CANCEL" then return end

        pendingAnimation = {
            type = "custom",
            preset = nil,
            dict = dict,
            anim = anim,
            prop = nil
        }
        PlayAnimOnPreview(dict, anim)
        StaffMenu.illegalRecipeAnimSelect.refresh()
    end)
    menuIndex = menuIndex + 1

    StaffMenu.illegalRecipeAnimSelect.Separator("", nil, nil, nil)
    menuIndex = menuIndex + 1

    StaffMenu.illegalRecipeAnimSelect.Button(":check: VALIDER", "Confirmer l'animation sélectionnée", nil, "chevron", false, function()
        recipeData.animationType = pendingAnimation.type
        recipeData.animationPreset = pendingAnimation.preset
        recipeData.animationDict = pendingAnimation.dict
        recipeData.animationName = pendingAnimation.anim
        recipeData.animationProp = pendingAnimation.prop
        DeleteAnimPreview()
        pendingAnimation = nil
        currentAnimDict = nil
        currentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.illegalRecipeAnimSelect.close()
            StaffMenu.illegalRecipeCreate.open()
        end)
    end)

    StaffMenu.illegalRecipeAnimSelect.Button(":x: ANNULER", "Revenir sans changer", nil, "chevron", false, function()
        DeleteAnimPreview()
        pendingAnimation = nil
        currentAnimDict = nil
        currentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.illegalRecipeAnimSelect.close()
            StaffMenu.illegalRecipeCreate.open()
        end)
    end)
end

StaffMenu.illegalRecipeAnimSelect.OnIndexChange(function(index, item)
    local animData = recipeAnimIndexMap[index]
    if animData and animData.dict and animData.anim then
        PlayAnimOnPreview(animData.dict, animData.anim)
    end
end)


function StaffMenu.BuildIllegalTransformBuilderMenu()
    StaffMenu.illegalTransformBuilder.Button(":plus: CRÉER UN SPOT", "Nouveau spot de transformation", nil, "chevron", false, function()
        ResetTransformData()
    end, StaffMenu.illegalTransformCreate)

    StaffMenu.illegalTransformBuilder.Button(":report: LISTE DES SPOTS", "Voir et modifier les spots", nil, "chevron", false, function()
        cachedTransformSpots = TriggerServerCallback("illegalBuilder:getTransformSpots") or {}
    end, StaffMenu.illegalTransformList)
end

function StaffMenu.BuildIllegalTransformListMenu()
    if not cachedTransformSpots or next(cachedTransformSpots) == nil then
        StaffMenu.illegalTransformList.Button(":x: AUCUN SPOT", "Créez-en un d'abord", nil, nil, true, function() end)
        return
    end

    for id, spot in pairs(cachedTransformSpots) do
        local inputCount = spot.inputs and #spot.inputs or 0
        local inputDesc = inputCount .. (inputCount > 1 and " items" or " item")
      local outputLabel = GetItemLabel(spot.output_item)
        StaffMenu.illegalTransformList.Button(
            ":refresh: " .. (spot.name or "Sans nom"),
            inputDesc .. " → " .. outputLabel,
            "#" .. (spot.id or id),
            "chevron", false,
            function()
                currentTransformSpot = spot
            end,
            StaffMenu.illegalTransformManage
        )
    end
end

function StaffMenu.BuildIllegalTransformManageMenu()
    if not currentTransformSpot then return end

    local spot = currentTransformSpot

    StaffMenu.illegalTransformManage.Separator("INFORMATIONS", nil, nil, nil)
    StaffMenu.illegalTransformManage.Button("Nom", spot.name, nil, nil, true, function() end)
    if spot.prop_model then
        StaffMenu.illegalTransformManage.Button("Prop", spot.prop_model, nil, nil, true, function() end)
    end

    StaffMenu.illegalTransformManage.Separator("ITEMS REQUIS", nil, nil, nil)
    if spot.inputs and #spot.inputs > 0 then
        for _, inp in ipairs(spot.inputs) do
            StaffMenu.illegalTransformManage.Button(GetItemLabel(inp.name), "x" .. (inp.quantity or 1), nil, nil, true, function() end)
        end
    else
        StaffMenu.illegalTransformManage.Button("Aucun item requis", nil, nil, nil, true, function() end)
    end

    StaffMenu.illegalTransformManage.Separator("RÉSULTAT", nil, nil, nil)
    StaffMenu.illegalTransformManage.Button("Sortie", GetItemLabel(spot.output_item) .. " x" .. (spot.output_quantity or 1), nil, nil, true, function() end)
    StaffMenu.illegalTransformManage.Button("Temps", ((spot.transform_time or 3000) / 1000) .. "s", nil, nil, true, function() end)

    if spot.faction_restriction then
        StaffMenu.illegalTransformManage.Button("Faction", GetFactionLabel(spot.faction_restriction), nil, nil, true, function() end)
    end

    StaffMenu.illegalTransformManage.Separator("ACTIONS", nil, nil, nil)

    StaffMenu.illegalTransformManage.Button(":pin: SE TÉLÉPORTER", nil, nil, "chevron", false, function()
        SetEntityCoords(PlayerPedId(), spot.coords_x, spot.coords_y, spot.coords_z, false, false, false, false)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Téléporté au spot." })
    end)

    StaffMenu.illegalTransformManage.Button(":edit: MODIFIER", nil, nil, "chevron", false, function()
        local inputsCopy = {}
        if spot.inputs then
            for _, inp in ipairs(spot.inputs) do
                table.insert(inputsCopy, { name = inp.name, quantity = inp.quantity })
            end
        end
        transformData = {
            name = spot.name,
            propModel = spot.prop_model,
            coords = vector3(spot.coords_x, spot.coords_y, spot.coords_z),
            markerCoords = (spot.marker_x and spot.marker_y and spot.marker_z) and vector3(spot.marker_x, spot.marker_y, spot.marker_z) or nil,
            inputs = inputsCopy,
            outputItem = spot.output_item,
            outputQuantity = spot.output_quantity,
            transformTime = spot.transform_time,
            animationType = spot.animation_type,
            animationPreset = spot.animation_preset,
            animationDict = spot.animation_dict,
            animationName = spot.animation_name,
            animationProp = spot.animation_prop,
            factionRestriction = spot.faction_restriction,
            factionGradeMin = spot.faction_grade_min,
            blipEnabled = spot.blip_enabled or false,
            blipSprite = spot.blip_sprite or 1,
            blipColor = spot.blip_color or 1,
            blipScale = spot.blip_scale or 0.8,
            blipLabel = spot.blip_label,
            isUpdate = true,
            id = spot.id
        }
        if transformData.propModel and transformData.coords then
            SpawnPreviewProp("transform", transformData.propModel, transformData.coords)
        end
    end, StaffMenu.illegalTransformCreate)

    StaffMenu.illegalTransformManage.Button(":trash: SUPPRIMER", nil, nil, "chevron", false, function()
        local result = TriggerServerCallback("illegalBuilder:deleteTransformSpot", spot.id)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Spot supprimé." })
            StaffMenu.illegalTransformManage.close()
            StaffMenu.illegalTransformManage.parent.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end

function StaffMenu.BuildIllegalTransformCreateMenu()
    StaffMenu.illegalTransformCreate.Separator("INFORMATIONS DU SPOT", nil, nil, nil)

    StaffMenu.illegalTransformCreate.Button(":edit: NOM DU SPOT", "Nom affiché pour les joueurs", transformData.name or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom du spot (ex: Table de séchage)", transformData.name or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            transformData.name = input
            StaffMenu.illegalTransformCreate.refresh()
        end
    end)

    StaffMenu.illegalTransformCreate.Separator("PLACEMENT DANS LE MONDE", nil, nil, nil)

    StaffMenu.illegalTransformCreate.Button(":palette: MODÈLE DU PROP", "Objet 3D affiché (optionnel)", transformData.propModel or "Aucun - marqueur seul", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Modèle du prop (ex: prop_table_01)", transformData.propModel or "", 100)
        if input and input ~= "KBD_CANCEL" then
            local newModel = input ~= "" and input or nil
            transformData.propModel = newModel
            if newModel then
                if not transformData.coords then
                    local defaultPos = GetDefaultPropPosition()
                    transformData.coords = defaultPos.coords
                    transformData.markerCoords = defaultPos.markerCoords
                end
                SpawnPreviewProp("transform", newModel, transformData.coords)
            else
                DeletePreviewProp("transform")
            end
            StaffMenu.illegalTransformCreate.refresh()
        end
    end)

    local coordsLabel = transformData.coords and string.format("%.1f, %.1f, %.1f", transformData.coords.x, transformData.coords.y, transformData.coords.z) or "Non défini"
  StaffMenu.illegalTransformCreate.Button(":pin: POSITION", transformData.propModel and "Place le prop devant toi" or "Place le spot à ta position", coordsLabel, "chevron", false, function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if transformData.propModel then
            local defaultPos = GetDefaultPropPosition()
            transformData.coords = defaultPos.coords
            transformData.markerCoords = defaultPos.markerCoords
            SpawnPreviewProp("transform", transformData.propModel, transformData.coords)
        else
            transformData.coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
            transformData.markerCoords = nil
        end

        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Position définie." })
        StaffMenu.illegalTransformCreate.refresh()
    end)

    if transformPreviewProp and DoesEntityExist(transformPreviewProp) then
        StaffMenu.illegalTransformCreate.Button(":trash: SUPPRIMER PREVIEW", "Retire le prop et la position", nil, "chevron", false, function()
            DeletePreviewProp("transform")
            transformData.propModel = nil
            transformData.coords = nil
            transformData.markerCoords = nil
            StaffMenu.illegalTransformCreate.refresh()
        end)
    end

    StaffMenu.illegalTransformCreate.Separator("ITEMS REQUIS (" .. #transformData.inputs .. ")", nil, nil, nil)

    if #transformData.inputs == 0 then
        StaffMenu.illegalTransformCreate.Button(":report: Aucun item requis", "Ajoute des items ci-dessous", nil, nil, true, function() end)
    else
        for i, inp in ipairs(transformData.inputs) do
            StaffMenu.illegalTransformCreate.Button(
                GetItemLabel(inp.name),
                "Cliquer pour retirer",
                "x" .. inp.quantity,
                "cross", false,
                function()
                    table.remove(transformData.inputs, i)
                    StaffMenu.illegalTransformCreate.refresh()
                end
            )
        end
    end

    StaffMenu.illegalTransformCreate.Button(":plus: AJOUTER UN ITEM REQUIS", "Item consommé pour la transformation", nil, "chevron", false, function()
        local itemName = VFW.Nui.KeyboardInput(true, "Nom de l'item requis (ex: weed_leaf)", "", 50)
        if not itemName or itemName == "" or itemName == "KBD_CANCEL" then return end

        local quantityStr = VFW.Nui.KeyboardInput(true, "Quantité nécessaire", "1", 5)
        local quantity = tonumber(quantityStr) or 1

        table.insert(transformData.inputs, { name = itemName, quantity = quantity })
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Item ajouté: " .. itemName .. "." })
        StaffMenu.illegalTransformCreate.refresh()
    end)

    StaffMenu.illegalTransformCreate.Separator("ITEM PRODUIT (ce que le joueur reçoit)", nil, nil, nil)

    StaffMenu.illegalTransformCreate.Button(":box: NOM DE L'ITEM", "Item donné après transformation", transformData.outputItem or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Item produit (ex: weed_dried)", transformData.outputItem or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            transformData.outputItem = input
            StaffMenu.illegalTransformCreate.refresh()
        end
    end)

    StaffMenu.illegalTransformCreate.Button(":hash: QUANTITÉ", "Nombre d'items reçus", tostring(transformData.outputQuantity), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité produite", tostring(transformData.outputQuantity), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            transformData.outputQuantity = tonumber(input) or 1
            StaffMenu.illegalTransformCreate.refresh()
        end
    end)

    StaffMenu.illegalTransformCreate.Separator("PARAMÈTRES DE LA TRANSFORMATION", nil, nil, nil)

    StaffMenu.illegalTransformCreate.Button(":clock: DURÉE", "Temps en secondes", tostring(transformData.transformTime / 1000) .. "s", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Temps en secondes", tostring(transformData.transformTime / 1000), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            transformData.transformTime = (tonumber(input) or 3) * 1000
            StaffMenu.illegalTransformCreate.refresh()
        end
    end)

    local animLabel = transformData.animationType == "predefined" and (transformData.animationPreset and GetPresetLabel(transformData.animationPreset) or "Choisir...") or "Custom"
  StaffMenu.illegalTransformCreate.Button(":film: ANIMATION", "Animation jouée pendant la transformation", animLabel, "chevron", false, function()
        pendingAnimation = {
            type = transformData.animationType,
            preset = transformData.animationPreset,
            dict = transformData.animationDict,
            anim = transformData.animationName,
            prop = transformData.animationProp
        }
    end, StaffMenu.illegalTransformAnimSelect)

    StaffMenu.illegalTransformCreate.Separator("ACCÈS (qui peut transformer)", nil, nil, nil)

    local factionLabel = transformData.factionRestriction and GetFactionLabel(transformData.factionRestriction) or "Tout le monde"
  local gradeLabel = transformData.factionRestriction and ("Grade min: " .. (transformData.factionGradeMin or 0)) or "Aucune restriction"
  StaffMenu.illegalTransformCreate.Button(":flag: FACTION REQUISE", gradeLabel, factionLabel, "chevron", false, function()
    end, StaffMenu.illegalTransformFactionSelect)

    StaffMenu.illegalTransformCreate.Separator("BLIP SUR LA CARTE", nil, nil, nil)

    StaffMenu.illegalTransformCreate.Checkbox(":pin: AFFICHER LE BLIP", "Visible sur la map pour les joueurs autorisés", false, transformData.blipEnabled, function(checked)
        transformData.blipEnabled = checked
        StaffMenu.illegalTransformCreate.refresh()
    end)

    if transformData.blipEnabled then
        StaffMenu.illegalTransformCreate.Button(":palette: SPRITE", "Icône du blip", tostring(transformData.blipSprite), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "ID du sprite", tostring(transformData.blipSprite), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                transformData.blipSprite = tonumber(input) or 1
                StaffMenu.illegalTransformCreate.refresh()
            end
        end)

        StaffMenu.illegalTransformCreate.Button(":palette: COULEUR", "Couleur du blip", tostring(transformData.blipColor), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "ID couleur", tostring(transformData.blipColor), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                transformData.blipColor = tonumber(input) or 1
                StaffMenu.illegalTransformCreate.refresh()
            end
        end)

        StaffMenu.illegalTransformCreate.Button(":ruler: TAILLE", "Échelle du blip", tostring(transformData.blipScale), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Taille", tostring(transformData.blipScale), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                transformData.blipScale = tonumber(input) or 0.8
                StaffMenu.illegalTransformCreate.refresh()
            end
        end)

        StaffMenu.illegalTransformCreate.Button(":edit: LABEL", "Texte affiché", transformData.blipLabel or transformData.name or "Auto", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Label du blip", transformData.blipLabel or "", 50)
            if input and input ~= "KBD_CANCEL" then
                transformData.blipLabel = input ~= "" and input or nil
                StaffMenu.illegalTransformCreate.refresh()
            end
        end)
    end

    StaffMenu.illegalTransformCreate.Separator("", nil, nil, nil)

    local isValid = transformData.name and transformData.coords and #transformData.inputs > 0 and transformData.outputItem
    local btnLabel = transformData.isUpdate and ":save: SAUVEGARDER LES MODIFICATIONS" or ":check: CRÉER LE SPOT"
  local btnDesc = not isValid and "Remplis nom, position, items requis et produit" or nil

    StaffMenu.illegalTransformCreate.Button(btnLabel, btnDesc, nil, "chevron", not isValid, function()
        local sendData = {
            name = transformData.name,
            propModel = transformData.propModel,
            coords = vec3ToTable(transformData.coords),
            rotationZ = GetEntityHeading(PlayerPedId()),
            markerCoords = vec3ToTable(transformData.markerCoords),
            inputs = transformData.inputs,
            outputItem = transformData.outputItem,
            outputQuantity = transformData.outputQuantity,
            transformTime = transformData.transformTime,
            cooldown = transformData.cooldown,
            radius = transformData.radius,
            animationType = transformData.animationType,
            animationPreset = transformData.animationPreset,
            animationDict = transformData.animationDict,
            animationName = transformData.animationName,
            animationProp = transformData.animationProp,
            factionRestriction = transformData.factionRestriction,
            factionGradeMin = transformData.factionGradeMin,
            blipEnabled = transformData.blipEnabled,
            blipSprite = transformData.blipSprite,
            blipColor = transformData.blipColor,
            blipScale = transformData.blipScale,
            blipLabel = transformData.blipLabel
        }
        local result
        if transformData.isUpdate then
            result = TriggerServerCallback("illegalBuilder:updateTransformSpot", transformData.id, sendData)
        else
            result = TriggerServerCallback("illegalBuilder:createTransformSpot", sendData)
        end

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = transformData.isUpdate and "Spot mis à jour." or "Spot créé." })
            local wasUpdate = transformData.isUpdate
            ResetTransformData()
            cachedTransformSpots = TriggerServerCallback("illegalBuilder:getTransformSpots") or {}
            Citizen.SetTimeout(50, function()
                StaffMenu.illegalTransformCreate.close()
                if wasUpdate then
                    StaffMenu.illegalTransformList.open()
                else
                    StaffMenu.illegalTransformBuilder.open()
                end
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Craft', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end


local transformAnimIndexMap = {}

function StaffMenu.BuildIllegalTransformAnimSelectMenu()
    CreateAnimPreview()
    currentAnimDict = nil
    currentAnimName = nil
    transformAnimIndexMap = {}

    if not pendingAnimation then
        pendingAnimation = {
            type = transformData.animationType,
            preset = transformData.animationPreset,
            dict = transformData.animationDict,
            anim = transformData.animationName,
            prop = transformData.animationProp
        }
    end

    local menuIndex = 1

    StaffMenu.illegalTransformAnimSelect.Separator("ANIMATIONS PRÉDÉFINIES", nil, nil, nil)
    menuIndex = menuIndex + 1

    if not cachedPresets then
        cachedPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations")
    end

    for _, preset in ipairs(cachedPresets or {}) do
        local isSelected = pendingAnimation.type == "predefined" and pendingAnimation.preset == preset.id
        local propInfo = preset.prop and (" + " .. preset.prop) or ""

      transformAnimIndexMap[menuIndex] = { dict = preset.dict, anim = preset.anim, preset = preset }

        StaffMenu.illegalTransformAnimSelect.Button(
            preset.label, preset.dict .. " / " .. preset.anim .. propInfo, nil,
            isSelected and "check" or "chevron", false,
            function()
                pendingAnimation = {
                    type = "predefined",
                    preset = preset.id,
                    dict = preset.dict,
                    anim = preset.anim,
                    prop = preset.prop
                }
                StaffMenu.illegalTransformAnimSelect.refresh()
            end
        )
        menuIndex = menuIndex + 1
    end

    StaffMenu.illegalTransformAnimSelect.Separator("CUSTOM", nil, nil, nil)
    menuIndex = menuIndex + 1

    StaffMenu.illegalTransformAnimSelect.Button(":film: ANIMATION CUSTOM", "Entrer dict/anim manuellement", nil, "chevron", false, function()
        local dict = VFW.Nui.KeyboardInput(true, "Animation Dictionary", pendingAnimation.dict or "", 100)
        if not dict or dict == "" or dict == "KBD_CANCEL" then return end

        local anim = VFW.Nui.KeyboardInput(true, "Animation Name", pendingAnimation.anim or "", 100)
        if not anim or anim == "" or anim == "KBD_CANCEL" then return end

        pendingAnimation = {
            type = "custom",
            preset = nil,
            dict = dict,
            anim = anim,
            prop = nil
        }
        PlayAnimOnPreview(dict, anim)
        StaffMenu.illegalTransformAnimSelect.refresh()
    end)
    menuIndex = menuIndex + 1

    StaffMenu.illegalTransformAnimSelect.Separator("", nil, nil, nil)
    menuIndex = menuIndex + 1

    StaffMenu.illegalTransformAnimSelect.Button(":check: VALIDER", "Confirmer l'animation sélectionnée", nil, "chevron", false, function()
        transformData.animationType = pendingAnimation.type
        transformData.animationPreset = pendingAnimation.preset
        transformData.animationDict = pendingAnimation.dict
        transformData.animationName = pendingAnimation.anim
        transformData.animationProp = pendingAnimation.prop
        DeleteAnimPreview()
        pendingAnimation = nil
        currentAnimDict = nil
        currentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.illegalTransformAnimSelect.close()
            StaffMenu.illegalTransformCreate.open()
        end)
    end)

    StaffMenu.illegalTransformAnimSelect.Button(":x: ANNULER", "Revenir sans changer", nil, "chevron", false, function()
        DeleteAnimPreview()
        pendingAnimation = nil
        currentAnimDict = nil
        currentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.illegalTransformAnimSelect.close()
            StaffMenu.illegalTransformCreate.open()
        end)
    end)
end

StaffMenu.illegalTransformAnimSelect.OnIndexChange(function(index, item)
    local animData = transformAnimIndexMap[index]
    if animData and animData.dict and animData.anim then
        PlayAnimOnPreview(animData.dict, animData.anim)
    end
end)

function StaffMenu.BuildIllegalTransformFactionSelectMenu()
    if not cachedFactions then
        cachedFactions = TriggerServerCallback("illegalBuilder:getFactions")
    end

    StaffMenu.illegalTransformFactionSelect.Button(":x: AUCUNE RESTRICTION", nil, nil,
        not transformData.factionRestriction and "check" or "chevron", false,
        function()
            transformData.factionRestriction = nil
            transformData.factionGradeMin = nil
            StaffMenu.illegalTransformFactionSelect.close()
            StaffMenu.illegalTransformFactionSelect.parent.open()
        end
    )

    for _, faction in ipairs(cachedFactions or {}) do
        local isSelected = transformData.factionRestriction == faction.name
        StaffMenu.illegalTransformFactionSelect.Button(
            faction.label, faction.name, nil,
            "chevron", false,
            function()
                pendingFactionSelect = "transform"
              transformData.factionRestriction = faction.name
                cachedFactionGrades = TriggerServerCallback("illegalBuilder:getFactionGrades", faction.name) or {}
            end,
            StaffMenu.illegalTransformGradeSelect
        )
    end
end

function StaffMenu.BuildIllegalTransformGradeSelectMenu()
    if not transformData.factionRestriction then
        StaffMenu.illegalTransformGradeSelect.close()
        StaffMenu.illegalTransformGradeSelect.parent.open()
        return
    end

    local factionLabel = GetFactionLabel(transformData.factionRestriction)
    StaffMenu.illegalTransformGradeSelect.Separator("Grades de " .. factionLabel, nil, nil, nil)

    StaffMenu.illegalTransformGradeSelect.Button("Grade 0", "Tous les membres", nil,
        transformData.factionGradeMin == 0 and "check" or "chevron", false,
        function()
            transformData.factionGradeMin = 0
            StaffMenu.illegalTransformGradeSelect.close()
            StaffMenu.illegalTransformCreate.open()
        end
    )

    for _, grade in ipairs(cachedFactionGrades or {}) do
        local isSelected = transformData.factionGradeMin == grade.grade
        StaffMenu.illegalTransformGradeSelect.Button(
            grade.label or ("Grade " .. grade.grade),
            "Grade " .. grade.grade,
            nil,
            isSelected and "check" or "chevron", false,
            function()
                transformData.factionGradeMin = grade.grade
                StaffMenu.illegalTransformGradeSelect.close()
                StaffMenu.illegalTransformCreate.open()
            end
        )
    end
end

function StaffMenu.BuildIllegalRecipeIngredientAddMenu()
    local items = TriggerServerCallback("illegalBuilder:getItems") or {}

    StaffMenu.illegalRecipeIngredientSelect.Separator("SÉLECTIONNER UN ITEM", nil, nil, nil)

    for _, item in ipairs(items) do
        StaffMenu.illegalRecipeIngredientSelect.Button(
            item.label, item.name, nil, "chevron", false,
            function()
                local amountStr = VFW.Nui.KeyboardInput(true, "Quantité requise", "1", 5)
                local amount = tonumber(amountStr) or 1
                if amount > 0 then
                    table.insert(recipeData.ingredients, { name = item.name, amount = amount })
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Craft', message = "Composant ajouté: " .. item.label .. "." })
                end
                StaffMenu.illegalRecipeIngredientSelect.close()
                StaffMenu.illegalRecipeIngredientSelect.parent.open()
            end
        )
    end
end

RegisterNetEvent("illegalBuilder:refreshHarvestSpots", function(spots)
    cachedHarvestSpots = spots
end)

RegisterNetEvent("illegalBuilder:refreshCraftStations", function(stations)
    cachedCraftStations = stations
end)

RegisterNetEvent("illegalBuilder:refreshRecipes", function(recipes)
    cachedRecipes = recipes
end)

RegisterNetEvent("illegalBuilder:refreshTransformSpots", function(spots)
    cachedTransformSpots = spots
end)

RegisterNetEvent("illegalBuilder:refreshAll", function(data)
    cachedHarvestSpots = data.harvestSpots
    cachedCraftStations = data.craftStations
    cachedRecipes = data.recipes
    cachedTransformSpots = data.transformSpots
end)

StaffMenu.illegalHarvestCreate.OnClose(function()
    DeletePreviewProp("harvest")
    DeleteAnimPreview()
end)

StaffMenu.illegalStationCreate.OnClose(function()
    DeletePreviewProp("station")
end)

StaffMenu.illegalTransformCreate.OnClose(function()
    DeletePreviewProp("transform")
    DeleteAnimPreview()
end)
