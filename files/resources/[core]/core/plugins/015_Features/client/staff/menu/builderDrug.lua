local pipelineData = {
    name = nil,
    drugItem = nil,
    drugItemLabel = nil,
    drugItemDescription = nil,
    drugItemWeight = 1,
    drugItemExists = false,
    rawItem = nil,
    rawItemLabel = nil,
    rawItemDescription = nil,
    rawItemWeight = 1,
    rawItemExists = false,
    dealPriceMin = 100,
    dealPriceMax = 200,
    dealQtyMin = 1,
    dealQtyMax = 5,
    dealActive = true,
    isUpdate = false,
    id = nil
}

local harvestSpots = {}
local transformSpots = {}
local editingSpot = {}
local editingSpotIndex = nil
local managingSpotIndex = nil

local cachedDrugItems = {}
local cachedDrugFactions = {}
local cachedDrugPresets = {}
local cachedDrugFactionGrades = {}
local cachedDrugPipelines = {}

local drugAnimPreviewPed = nil
local drugAnimPreviewActive = false
local drugPendingAnimation = nil
local drugCurrentAnimDict = nil
local drugCurrentAnimName = nil

local harvestAnimIndexMap = {}
local transformAnimIndexMap = {}

local function vec3ToTable(v)
    if not v then return nil end
    return { x = v.x, y = v.y, z = v.z }
end

local function DeleteDrugAnimPreview()
    if drugAnimPreviewPed and DoesEntityExist(drugAnimPreviewPed) then
        DeleteEntity(drugAnimPreviewPed)
        drugAnimPreviewPed = nil
    end
    drugAnimPreviewActive = false
end

local function CreateDrugAnimPreview()
    DeleteDrugAnimPreview()
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
    drugAnimPreviewPed = CreatePed(4, model, previewCoords.x, previewCoords.y, previewCoords.z, playerHeading + 200.0, false, false)
    if drugAnimPreviewPed and DoesEntityExist(drugAnimPreviewPed) then
        SetEntityAlpha(drugAnimPreviewPed, 180, false)
        SetEntityInvincible(drugAnimPreviewPed, true)
        FreezeEntityPosition(drugAnimPreviewPed, true)
        SetEntityCollision(drugAnimPreviewPed, false, false)
        SetBlockingOfNonTemporaryEvents(drugAnimPreviewPed, true)
        SetPedCanRagdoll(drugAnimPreviewPed, false)
        ClonePedToTarget(playerPed, drugAnimPreviewPed)
        drugAnimPreviewActive = true
    end
    SetModelAsNoLongerNeeded(model)
end

local function PlayDrugAnimOnPreview(dict, anim)
    if not dict or dict == "" or not anim or anim == "" then return end
    if dict == drugCurrentAnimDict and anim == drugCurrentAnimName then return end
    drugCurrentAnimDict = dict
    drugCurrentAnimName = anim
    Citizen.CreateThread(function()
        if not drugAnimPreviewPed or not DoesEntityExist(drugAnimPreviewPed) then
            CreateDrugAnimPreview()
            Citizen.Wait(200)
        end
        if not drugAnimPreviewPed or not DoesEntityExist(drugAnimPreviewPed) then return end
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do
            Citizen.Wait(10)
            timeout = timeout + 1
        end
        if HasAnimDictLoaded(dict) and drugAnimPreviewPed and DoesEntityExist(drugAnimPreviewPed) then
            ClearPedTasksImmediately(drugAnimPreviewPed)
            TaskPlayAnim(drugAnimPreviewPed, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end)
end

local function ResetPipelineData()
    DeleteDrugAnimPreview()
    pipelineData = {
        name = nil,
        drugItem = nil, drugItemLabel = nil, drugItemDescription = nil,
        drugItemWeight = 1, drugItemExists = false,
        rawItem = nil, rawItemLabel = nil, rawItemDescription = nil,
        rawItemWeight = 1, rawItemExists = false,
        dealPriceMin = 100, dealPriceMax = 200,
        dealQtyMin = 1, dealQtyMax = 5, dealActive = true,
        isUpdate = false, id = nil
    }
    harvestSpots = {}
    transformSpots = {}
    editingSpot = {}
    editingSpotIndex = nil
    managingSpotIndex = nil
end

local function ResetEditingSpot()
    editingSpot = {
        coords = nil,
        rotationZ = 0.0,
        minQty = 1,
        maxQty = 3,
        inputQty = 1,
        outputQty = 1,
        time = 3000,
        animType = "predefined",
        animPreset = nil,
        animDict = nil,
        animName = nil,
        animProp = nil,
        faction = nil,
        factionGrade = nil,
        spotId = nil
    }
    editingSpotIndex = nil
end

local function GetDrugItemLabel(itemName)
    if not itemName then return "Inconnu" end
    local vfwItem = VFW.Items[itemName]
    if vfwItem and vfwItem.label then
        return vfwItem.label
    end
    return itemName
end

local function GetDrugFactionLabel(factionName)
    if not factionName then return "Aucune" end
    if not cachedDrugFactions or #cachedDrugFactions == 0 then
        cachedDrugFactions = TriggerServerCallback("illegalBuilder:getFactions") or {}
    end
    for _, faction in ipairs(cachedDrugFactions) do
        if faction.name == factionName then
            return faction.label
        end
    end
    return factionName
end

local function GetDrugPresetLabel(presetId)
    if not presetId then return "Aucune" end
    if not cachedDrugPresets or #cachedDrugPresets == 0 then
        cachedDrugPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations") or {}
    end
    for _, preset in ipairs(cachedDrugPresets) do
        if preset.id == presetId then
            return preset.label
        end
    end
    return presetId
end

function StaffMenu.BuildDrugBuilderMenu()
    StaffMenu.builderDrug.Button(":plus: CRÉER UNE DROGUE", "Nouveau pipeline drogue complet", nil, "chevron", false, function()
        ResetPipelineData()
    end, StaffMenu.drugCreate)

    StaffMenu.builderDrug.Button(":report: LISTE DES DROGUES", "Voir et modifier les pipelines", nil, "chevron", false, function()
        cachedDrugPipelines = TriggerServerCallback("drugBuilder:getDrugPipelines") or {}
    end, StaffMenu.drugList)
end

function StaffMenu.BuildDrugCreateMenu()
    StaffMenu.drugCreate.Separator(":tag: CONFIGURATION", nil, nil, nil)

    StaffMenu.drugCreate.Button(":edit: NOM", "Identifiant unique de la drogue", pipelineData.name or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom du pipeline (ex: Weed, Cocaine...)", pipelineData.name or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            pipelineData.name = input
            StaffMenu.drugCreate.refresh()
        end
    end)

    local drugItemDisplay = pipelineData.drugItem or "Non défini"
  local rawItemDisplay = pipelineData.rawItem or "Aucun"
  local itemsDesc = "Drogue: " .. drugItemDisplay .. " | Récolte: " .. rawItemDisplay
    StaffMenu.drugCreate.Button(":box: ITEMS", itemsDesc, nil, "chevron", false, function() end, StaffMenu.drugItems)

    local harvestCount = #harvestSpots
    StaffMenu.drugCreate.Button(":leaf: RÉCOLTE", harvestCount .. (harvestCount > 1 and " points configurés" or " point configuré"), nil, "chevron", false, function() end, StaffMenu.drugHarvestList)

    local transformCount = #transformSpots
    StaffMenu.drugCreate.Button(":refresh: TRANSFORMATION", transformCount .. (transformCount > 1 and " points configurés" or " point configuré"), nil, "chevron", false, function() end, StaffMenu.drugTransformList)

    StaffMenu.drugCreate.Separator(":money: VENTE NPC", nil, nil, nil)

    StaffMenu.drugCreate.Button(":money: VENTE NPC " .. (pipelineData.dealActive and "ACTIVÉE" or "DÉSACTIVÉE"), "Activer/désactiver la vente aux NPC", nil, "chevron", false, function()
        pipelineData.dealActive = not pipelineData.dealActive
        StaffMenu.drugCreate.refresh()
    end)

    if pipelineData.dealActive then
        StaffMenu.drugCreate.Button(":money: PRIX MIN", "Prix minimum par unité", VFW.Math.FormatMoney(pipelineData.dealPriceMin), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Prix minimum", tostring(pipelineData.dealPriceMin), 10)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.dealPriceMin = tonumber(input) or 100
                StaffMenu.drugCreate.refresh()
            end
        end)

        StaffMenu.drugCreate.Button(":money: PRIX MAX", "Prix maximum par unité", VFW.Math.FormatMoney(pipelineData.dealPriceMax), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Prix maximum", tostring(pipelineData.dealPriceMax), 10)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.dealPriceMax = tonumber(input) or 200
                StaffMenu.drugCreate.refresh()
            end
        end)

        StaffMenu.drugCreate.Button(":arrow: QTÉ MIN VENTE", "Quantité min achetée par NPC", tostring(pipelineData.dealQtyMin), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Quantité min", tostring(pipelineData.dealQtyMin), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.dealQtyMin = tonumber(input) or 1
                StaffMenu.drugCreate.refresh()
            end
        end)

        StaffMenu.drugCreate.Button(":arrow: QTÉ MAX VENTE", "Quantité max achetée par NPC", tostring(pipelineData.dealQtyMax), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Quantité max", tostring(pipelineData.dealQtyMax), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.dealQtyMax = tonumber(input) or 5
                StaffMenu.drugCreate.refresh()
            end
        end)
    end

    StaffMenu.drugCreate.Separator(":check: VALIDATION", nil, nil, nil)

    local isValid = pipelineData.name and pipelineData.drugItem
    local btnLabel = pipelineData.isUpdate and ":save: SAUVEGARDER LES MODIFICATIONS" or ":check: CRÉER LA DROGUE"
  local btnDesc = not isValid and "Remplis au moins le nom et l'item drogue" or nil

    StaffMenu.drugCreate.Button(btnLabel, btnDesc, nil, "chevron", not isValid, function()
        if pipelineData.isUpdate then
            local sendData = {
                name = pipelineData.name,
                drugItem = pipelineData.drugItem,
                drugItemLabel = pipelineData.drugItemLabel,
                drugItemDescription = pipelineData.drugItemDescription,
                drugItemWeight = pipelineData.drugItemWeight,
                rawItem = pipelineData.rawItem,
                rawItemLabel = pipelineData.rawItemLabel,
                rawItemDescription = pipelineData.rawItemDescription,
                rawItemWeight = pipelineData.rawItemWeight,
                dealPriceMin = pipelineData.dealPriceMin,
                dealPriceMax = pipelineData.dealPriceMax,
                dealQtyMin = pipelineData.dealQtyMin,
                dealQtyMax = pipelineData.dealQtyMax,
                dealActive = pipelineData.dealActive and 1 or 0
            }
            local result = TriggerServerCallback("drugBuilder:updateDrug", pipelineData.id, sendData)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Pipeline modifié." })
                ResetPipelineData()
                cachedDrugPipelines = TriggerServerCallback("drugBuilder:getDrugPipelines") or {}
                exports["VUI"]:HandleBack()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = (result and result.error or "Erreur") .. "." })
            end
        else
            local harvestSpotsData = {}
            for _, spot in ipairs(harvestSpots) do
                table.insert(harvestSpotsData, {
                    coords = vec3ToTable(spot.coords),
                    markerCoords = vec3ToTable(spot.markerCoords),
                    rotationZ = spot.rotationZ or GetEntityHeading(PlayerPedId()),
                    minQty = spot.minQty,
                    maxQty = spot.maxQty,
                    time = spot.time,
                    animType = spot.animType,
                    animPreset = spot.animPreset,
                    animDict = spot.animDict,
                    animName = spot.animName,
                    animProp = spot.animProp,
                    faction = spot.faction,
                    factionGrade = spot.factionGrade
                })
            end

            local transformSpotsData = {}
            for _, spot in ipairs(transformSpots) do
                table.insert(transformSpotsData, {
                    coords = vec3ToTable(spot.coords),
                    markerCoords = vec3ToTable(spot.markerCoords),
                    rotationZ = spot.rotationZ or GetEntityHeading(PlayerPedId()),
                    inputQty = spot.inputQty,
                    outputQty = spot.outputQty,
                    time = spot.time,
                    animType = spot.animType,
                    animPreset = spot.animPreset,
                    animDict = spot.animDict,
                    animName = spot.animName,
                    animProp = spot.animProp,
                    faction = spot.faction,
                    factionGrade = spot.factionGrade
                })
            end

            local sendData = {
                name = pipelineData.name,
                drugItem = pipelineData.drugItem,
                drugItemLabel = pipelineData.drugItemLabel,
                drugItemDescription = pipelineData.drugItemDescription,
                drugItemWeight = pipelineData.drugItemWeight,
                rawItem = pipelineData.rawItem,
                rawItemLabel = pipelineData.rawItemLabel,
                rawItemDescription = pipelineData.rawItemDescription,
                rawItemWeight = pipelineData.rawItemWeight,
                dealPriceMin = pipelineData.dealPriceMin,
                dealPriceMax = pipelineData.dealPriceMax,
                dealQtyMin = pipelineData.dealQtyMin,
                dealQtyMax = pipelineData.dealQtyMax,
                dealActive = pipelineData.dealActive and 1 or 0,
                harvestSpots = harvestSpotsData,
                transformSpots = transformSpotsData
            }

            local result = TriggerServerCallback("drugBuilder:createDrug", sendData)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Pipeline créé." })
                ResetPipelineData()
                cachedDrugPipelines = TriggerServerCallback("drugBuilder:getDrugPipelines") or {}
                exports["VUI"]:HandleBack()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = (result and result.error or "Erreur") .. "." })
            end
        end
    end)

    if pipelineData.isUpdate then
        StaffMenu.drugCreate.Separator(":warning: ZONE DANGEREUSE", nil, nil, nil)

        StaffMenu.drugCreate.Button(":trash: SUPPRIMER LE PIPELINE", "Supprime la drogue et tous ses spots", nil, "trash", false, function()
            local confirm = VFW.Nui.ChoiceInput(
                "Supprimer " .. (pipelineData.name or "ce pipeline") .. " ?",
                "Cette action supprimera le pipeline, tous les points de récolte, transformation et vente associés. Irréversible.",
                {
                    { label = "Oui, supprimer", value = "yes" },
                    { label = "Annuler", value = "no" }
                }
            )
            if confirm == "yes" then
                local result = TriggerServerCallback("drugBuilder:deleteDrug", pipelineData.id)
                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Pipeline \"" .. (pipelineData.name or "") .. "\" supprimé." })
                    ResetPipelineData()
                    cachedDrugPipelines = TriggerServerCallback("drugBuilder:getDrugPipelines") or {}
                    StaffMenu.drugCreate.close()
                    StaffMenu.drugCreate.parent.open()
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = (result and result.error or "Erreur") .. "." })
                end
            end
        end)
    end
end

function StaffMenu.BuildDrugItemsMenu()
    StaffMenu.drugItems.Separator(":box: ITEM DROGUE (produit final)", nil, nil, nil)

    local drugItemDisplay = pipelineData.drugItem or "Non défini"
  local drugItemStatus = pipelineData.drugItem and (pipelineData.drugItemExists and ":check: Existe déjà" or ":plus: Sera créé") or nil
    StaffMenu.drugItems.Button(":box: ITEM DROGUE", drugItemStatus, drugItemDisplay, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de l'item (ex: pochon_weed)", pipelineData.drugItem or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            local exists = TriggerServerCallback("drugBuilder:checkItemExists", input)
            pipelineData.drugItem = input
            pipelineData.drugItemExists = exists
            if exists then
                pipelineData.drugItemLabel = GetDrugItemLabel(input)
            end
            StaffMenu.drugItems.refresh()
        end
    end)

    if pipelineData.drugItem and not pipelineData.drugItemExists then
        StaffMenu.drugItems.Button(":tag: LABEL DROGUE", "Nom affiché en jeu", pipelineData.drugItemLabel or pipelineData.drugItem, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Label de l'item (ex: Pochon de Weed)", pipelineData.drugItemLabel or "", 100)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.drugItemLabel = input
                StaffMenu.drugItems.refresh()
            end
        end)
        StaffMenu.drugItems.Button(":edit: DESCRIPTION", "Description de l'item", pipelineData.drugItemDescription or "Aucune", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Description de l'item", pipelineData.drugItemDescription or "", 200)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.drugItemDescription = input
                StaffMenu.drugItems.refresh()
            end
        end)
        StaffMenu.drugItems.Button(":scales: POIDS", "Poids de l'item", tostring(pipelineData.drugItemWeight), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Poids (nombre)", tostring(pipelineData.drugItemWeight), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.drugItemWeight = tonumber(input) or 1
                StaffMenu.drugItems.refresh()
            end
        end)
    end

    StaffMenu.drugItems.Separator(":flask: ITEM DE RÉCOLTE (optionnel)", nil, nil, nil)

    local rawItemDisplay = pipelineData.rawItem or "Aucun"
  local rawItemStatus = pipelineData.rawItem and (pipelineData.rawItemExists and ":check: Existe déjà" or ":plus: Sera créé") or nil
    StaffMenu.drugItems.Button(":flask: ITEM DE RÉCOLTE", rawItemStatus, rawItemDisplay, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de l'item (ex: feuille_weed)", pipelineData.rawItem or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            local exists = TriggerServerCallback("drugBuilder:checkItemExists", input)
            pipelineData.rawItem = input
            pipelineData.rawItemExists = exists
            if exists then
                pipelineData.rawItemLabel = GetDrugItemLabel(input)
            end
            StaffMenu.drugItems.refresh()
        end
    end)

    if pipelineData.rawItem and not pipelineData.rawItemExists then
        StaffMenu.drugItems.Button(":tag: LABEL RÉCOLTE", "Nom affiché en jeu", pipelineData.rawItemLabel or pipelineData.rawItem, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Label (ex: Feuille de Weed)", pipelineData.rawItemLabel or "", 100)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.rawItemLabel = input
                StaffMenu.drugItems.refresh()
            end
        end)
        StaffMenu.drugItems.Button(":edit: DESCRIPTION RÉCOLTE", "Description de la matière première", pipelineData.rawItemDescription or "Aucune", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Description de la matière première", pipelineData.rawItemDescription or "", 200)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.rawItemDescription = input
                StaffMenu.drugItems.refresh()
            end
        end)
        StaffMenu.drugItems.Button(":scales: POIDS RÉCOLTE", "Poids de l'item", tostring(pipelineData.rawItemWeight), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Poids (nombre)", tostring(pipelineData.rawItemWeight), 5)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                pipelineData.rawItemWeight = tonumber(input) or 1
                StaffMenu.drugItems.refresh()
            end
        end)
    end

    if pipelineData.rawItem then
        StaffMenu.drugItems.Button(":x: RETIRER ITEM DE RÉCOLTE", "Supprimer la matière première", nil, "chevron", false, function()
            pipelineData.rawItem = nil
            pipelineData.rawItemLabel = nil
            pipelineData.rawItemDescription = nil
            pipelineData.rawItemWeight = 1
            pipelineData.rawItemExists = false
            StaffMenu.drugItems.refresh()
        end)
    end
end

function StaffMenu.BuildDrugHarvestListMenu()
    StaffMenu.drugHarvestList.Button(":plus: AJOUTER UN POINT", "Configurer un nouveau point de récolte", nil, "chevron", false, function()
        ResetEditingSpot()
    end, StaffMenu.drugHarvestSpotEdit)

    if #harvestSpots > 0 then
        StaffMenu.drugHarvestList.Separator(":report: SPOTS EXISTANTS", nil, nil, nil)
        for i, spot in ipairs(harvestSpots) do
            local coordsLabel = spot.coords and string.format("%.1f, %.1f, %.1f", spot.coords.x, spot.coords.y, spot.coords.z) or "Non positionné"
          StaffMenu.drugHarvestList.Button(
                ":pin: Spot #" .. i,
                coordsLabel,
                nil,
                "chevron", false,
                function()
                    managingSpotIndex = i
                end,
                StaffMenu.drugHarvestSpotManage
            )
        end
    end
end

function StaffMenu.BuildDrugHarvestSpotEditMenu()
    StaffMenu.drugHarvestSpotEdit.Separator(":pin: POSITION", nil, nil, nil)

    local hCoordsLabel = editingSpot.coords and string.format("%.1f, %.1f, %.1f", editingSpot.coords.x, editingSpot.coords.y, editingSpot.coords.z) or "Non défini"
  StaffMenu.drugHarvestSpotEdit.Button(":pin: POSITION", "Place le spot à ta position", hCoordsLabel, "chevron", false, function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        editingSpot.coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
        editingSpot.markerCoords = nil
        editingSpot.rotationZ = GetEntityHeading(playerPed)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Position récolte définie." })
        StaffMenu.drugHarvestSpotEdit.refresh()
    end)

    StaffMenu.drugHarvestSpotEdit.Separator(":chart: QUANTITÉS & TEMPS", nil, nil, nil)

    StaffMenu.drugHarvestSpotEdit.Button(":arrow: QTÉ MIN", "Minimum d'items reçus", tostring(editingSpot.minQty or 1), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité minimum", tostring(editingSpot.minQty or 1), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            editingSpot.minQty = tonumber(input) or 1
            StaffMenu.drugHarvestSpotEdit.refresh()
        end
    end)

    StaffMenu.drugHarvestSpotEdit.Button(":arrow: QTÉ MAX", "Maximum d'items reçus", tostring(editingSpot.maxQty or 3), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité maximum", tostring(editingSpot.maxQty or 3), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            editingSpot.maxQty = tonumber(input) or 3
            StaffMenu.drugHarvestSpotEdit.refresh()
        end
    end)

    StaffMenu.drugHarvestSpotEdit.Button(":clock: DURÉE", "Temps en secondes", tostring((editingSpot.time or 3000) / 1000) .. "s", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Temps en secondes", tostring((editingSpot.time or 3000) / 1000), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            editingSpot.time = (tonumber(input) or 3) * 1000
            StaffMenu.drugHarvestSpotEdit.refresh()
        end
    end)

    StaffMenu.drugHarvestSpotEdit.Separator(":mask: ANIMATION & FACTION", nil, nil, nil)

    local hAnimLabel = editingSpot.animType == "predefined" and (editingSpot.animPreset and GetDrugPresetLabel(editingSpot.animPreset) or "Choisir...") or "Custom"
  StaffMenu.drugHarvestSpotEdit.Button(":mask: ANIMATION", "Animation jouée pendant la récolte", hAnimLabel, "chevron", false, function() end, StaffMenu.drugHarvestAnim)

    local hFactionLabel = editingSpot.faction and GetDrugFactionLabel(editingSpot.faction) or "Tout le monde"
  StaffMenu.drugHarvestSpotEdit.Button(":flag: FACTION", "Restriction d'accès", hFactionLabel, "chevron", false, function() end, StaffMenu.drugHarvestFaction)

    StaffMenu.drugHarvestSpotEdit.Separator(":check: VALIDATION", nil, nil, nil)

    local spotValid = editingSpot.coords ~= nil
    StaffMenu.drugHarvestSpotEdit.Button(":check: VALIDER LE POINT", not spotValid and "Définis au moins la position" or nil, nil, "chevron", not spotValid, function()
        DeleteDrugAnimPreview()

        local spotData = {
            coords = editingSpot.coords,
            markerCoords = editingSpot.markerCoords,
            rotationZ = editingSpot.rotationZ or GetEntityHeading(PlayerPedId()),
            minQty = editingSpot.minQty or 1,
            maxQty = editingSpot.maxQty or 3,
            time = editingSpot.time or 3000,
            animType = editingSpot.animType or "predefined",
            animPreset = editingSpot.animPreset,
            animDict = editingSpot.animDict,
            animName = editingSpot.animName,
            animProp = editingSpot.animProp,
            faction = editingSpot.faction,
            factionGrade = editingSpot.factionGrade,
            spotId = editingSpot.spotId
        }

        if pipelineData.isUpdate then
            if editingSpot.spotId then
                local result = TriggerServerCallback("drugBuilder:updateHarvestSpot", editingSpot.spotId, {
                    coords = vec3ToTable(spotData.coords),
                    markerCoords = vec3ToTable(spotData.markerCoords),
                    rotationZ = spotData.rotationZ,
                    minQty = spotData.minQty,
                    maxQty = spotData.maxQty,
                    time = spotData.time,
                    animType = spotData.animType,
                    animPreset = spotData.animPreset,
                    animDict = spotData.animDict,
                    animName = spotData.animName,
                    animProp = spotData.animProp,
                    faction = spotData.faction,
                    factionGrade = spotData.factionGrade
                })
                if result and result.success then
                    if editingSpotIndex then
                        harvestSpots[editingSpotIndex] = spotData
                    end
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de récolte modifié." })
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = (result and result.error or "Erreur") .. "." })
                end
            else
                local result = TriggerServerCallback("drugBuilder:addHarvestSpot", pipelineData.id, {
                    coords = vec3ToTable(spotData.coords),
                    markerCoords = vec3ToTable(spotData.markerCoords),
                    rotationZ = spotData.rotationZ,
                    minQty = spotData.minQty,
                    maxQty = spotData.maxQty,
                    time = spotData.time,
                    animType = spotData.animType,
                    animPreset = spotData.animPreset,
                    animDict = spotData.animDict,
                    animName = spotData.animName,
                    animProp = spotData.animProp,
                    faction = spotData.faction,
                    factionGrade = spotData.factionGrade
                })
                if result and result.success then
                    spotData.spotId = result.spotId
                    table.insert(harvestSpots, spotData)
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de récolte ajouté." })
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = (result and result.error or "Erreur") .. "." })
                end
            end
        else
            if editingSpotIndex then
                harvestSpots[editingSpotIndex] = spotData
            else
                table.insert(harvestSpots, spotData)
            end
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de récolte " .. (editingSpotIndex and "modifié" or "ajouté") .. "." })
        end

        ResetEditingSpot()
        StaffMenu.drugHarvestSpotEdit.close()
        Wait(100)
        StaffMenu.drugHarvestList.open()
    end)
end

function StaffMenu.BuildDrugHarvestSpotManageMenu()
    if not managingSpotIndex or not harvestSpots[managingSpotIndex] then return end
    local spot = harvestSpots[managingSpotIndex]

    StaffMenu.drugHarvestSpotManage.Separator(":report: INFORMATIONS", nil, nil, nil)

    if spot.coords then
        StaffMenu.drugHarvestSpotManage.Button(":pin: Coordonnées", string.format("%.1f, %.1f, %.1f", spot.coords.x, spot.coords.y, spot.coords.z), nil, nil, true, function() end)
    end
    StaffMenu.drugHarvestSpotManage.Button(":chart: Quantités", (spot.minQty or 1) .. " - " .. (spot.maxQty or 3), nil, nil, true, function() end)
    StaffMenu.drugHarvestSpotManage.Button(":clock: Durée", tostring((spot.time or 3000) / 1000) .. "s", nil, nil, true, function() end)

    if spot.faction then
        StaffMenu.drugHarvestSpotManage.Button(":flag: Faction", GetDrugFactionLabel(spot.faction) .. " (grade " .. (spot.factionGrade or 0) .. "+)", nil, nil, true, function() end)
    end

    StaffMenu.drugHarvestSpotManage.Separator(":bolt: ACTIONS", nil, nil, nil)

    StaffMenu.drugHarvestSpotManage.Button(":edit: MODIFIER", "Éditer ce point de récolte", nil, "chevron", false, function()
        editingSpot = {
            coords = spot.coords,
            markerCoords = spot.markerCoords,
            rotationZ = spot.rotationZ,
            minQty = spot.minQty or 1,
            maxQty = spot.maxQty or 3,
            time = spot.time or 3000,
            animType = spot.animType or "predefined",
            animPreset = spot.animPreset,
            animDict = spot.animDict,
            animName = spot.animName,
            animProp = spot.animProp,
            faction = spot.faction,
            factionGrade = spot.factionGrade,
            spotId = spot.spotId
        }
        editingSpotIndex = managingSpotIndex
    end, StaffMenu.drugHarvestSpotEdit)

    if spot.coords then
        StaffMenu.drugHarvestSpotManage.Button(":pin: TÉLÉPORTER", "Se téléporter au point", nil, "chevron", false, function()
            SetEntityCoords(PlayerPedId(), spot.coords.x, spot.coords.y, spot.coords.z, false, false, false, false)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Téléporté au point de récolte." })
        end)
    end

    StaffMenu.drugHarvestSpotManage.Button(":trash: SUPPRIMER", "Supprimer ce point de récolte", nil, "chevron", false, function()
        if pipelineData.isUpdate and spot.spotId then
            local result = TriggerServerCallback("drugBuilder:deleteHarvestSpot", pipelineData.id, spot.spotId)
            if result and result.success then
                table.remove(harvestSpots, managingSpotIndex)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de récolte supprimé." })
                StaffMenu.drugHarvestSpotManage.close()
                Wait(100)
                StaffMenu.drugHarvestList.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = (result and result.error or "Erreur") .. "." })
            end
        else
            table.remove(harvestSpots, managingSpotIndex)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de récolte supprimé." })
            StaffMenu.drugHarvestSpotManage.close()
            Wait(100)
            StaffMenu.drugHarvestList.open()
        end
    end)
end

function StaffMenu.BuildDrugTransformListMenu()
    StaffMenu.drugTransformList.Button(":plus: AJOUTER UN POINT", "Configurer un nouveau point de transformation", nil, "chevron", false, function()
        ResetEditingSpot()
    end, StaffMenu.drugTransformSpotEdit)

    if #transformSpots > 0 then
        StaffMenu.drugTransformList.Separator(":report: SPOTS EXISTANTS", nil, nil, nil)
        for i, spot in ipairs(transformSpots) do
            local coordsLabel = spot.coords and string.format("%.1f, %.1f, %.1f", spot.coords.x, spot.coords.y, spot.coords.z) or "Non positionné"
          StaffMenu.drugTransformList.Button(
                ":pin: Spot #" .. i,
                coordsLabel,
                nil,
                "chevron", false,
                function()
                    managingSpotIndex = i
                end,
                StaffMenu.drugTransformSpotManage
            )
        end
    end
end

function StaffMenu.BuildDrugTransformSpotEditMenu()
    StaffMenu.drugTransformSpotEdit.Separator(":pin: POSITION", nil, nil, nil)

    local tCoordsLabel = editingSpot.coords and string.format("%.1f, %.1f, %.1f", editingSpot.coords.x, editingSpot.coords.y, editingSpot.coords.z) or "Non défini"
  StaffMenu.drugTransformSpotEdit.Button(":pin: POSITION", "Place le spot à ta position", tCoordsLabel, "chevron", false, function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        editingSpot.coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
        editingSpot.markerCoords = nil
        editingSpot.rotationZ = GetEntityHeading(playerPed)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Position transformation définie." })
        StaffMenu.drugTransformSpotEdit.refresh()
    end)

    StaffMenu.drugTransformSpotEdit.Separator(":chart: QUANTITÉS & TEMPS", nil, nil, nil)

    StaffMenu.drugTransformSpotEdit.Button(":arrow: QTÉ INPUT", "Quantité de matière première requise", tostring(editingSpot.inputQty or 1), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité de matière première", tostring(editingSpot.inputQty or 1), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            editingSpot.inputQty = tonumber(input) or 1
            StaffMenu.drugTransformSpotEdit.refresh()
        end
    end)

    StaffMenu.drugTransformSpotEdit.Button(":arrow: QTÉ OUTPUT", "Quantité de drogue produite", tostring(editingSpot.outputQty or 1), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité produite", tostring(editingSpot.outputQty or 1), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            editingSpot.outputQty = tonumber(input) or 1
            StaffMenu.drugTransformSpotEdit.refresh()
        end
    end)

    StaffMenu.drugTransformSpotEdit.Button(":clock: DURÉE", "Temps en secondes", tostring((editingSpot.time or 3000) / 1000) .. "s", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Temps en secondes", tostring((editingSpot.time or 3000) / 1000), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            editingSpot.time = (tonumber(input) or 3) * 1000
            StaffMenu.drugTransformSpotEdit.refresh()
        end
    end)

    StaffMenu.drugTransformSpotEdit.Separator(":mask: ANIMATION & FACTION", nil, nil, nil)

    local tAnimLabel = editingSpot.animType == "predefined" and (editingSpot.animPreset and GetDrugPresetLabel(editingSpot.animPreset) or "Choisir...") or "Custom"
  StaffMenu.drugTransformSpotEdit.Button(":mask: ANIMATION", "Animation jouée pendant la transformation", tAnimLabel, "chevron", false, function() end, StaffMenu.drugTransformAnim)

    local tFactionLabel = editingSpot.faction and GetDrugFactionLabel(editingSpot.faction) or "Tout le monde"
  StaffMenu.drugTransformSpotEdit.Button(":flag: FACTION", "Restriction d'accès", tFactionLabel, "chevron", false, function() end, StaffMenu.drugTransformFaction)

    StaffMenu.drugTransformSpotEdit.Separator(":check: VALIDATION", nil, nil, nil)

    local spotValid = editingSpot.coords ~= nil
    StaffMenu.drugTransformSpotEdit.Button(":check: VALIDER LE POINT", not spotValid and "Définis au moins la position" or nil, nil, "chevron", not spotValid, function()
        DeleteDrugAnimPreview()

        local spotData = {
            coords = editingSpot.coords,
            markerCoords = editingSpot.markerCoords,
            rotationZ = editingSpot.rotationZ or GetEntityHeading(PlayerPedId()),
            inputQty = editingSpot.inputQty or 1,
            outputQty = editingSpot.outputQty or 1,
            time = editingSpot.time or 3000,
            animType = editingSpot.animType or "predefined",
            animPreset = editingSpot.animPreset,
            animDict = editingSpot.animDict,
            animName = editingSpot.animName,
            animProp = editingSpot.animProp,
            faction = editingSpot.faction,
            factionGrade = editingSpot.factionGrade,
            spotId = editingSpot.spotId
        }

        if pipelineData.isUpdate then
            if editingSpot.spotId then
                local result = TriggerServerCallback("drugBuilder:updateTransformSpot", editingSpot.spotId, {
                    coords = vec3ToTable(spotData.coords),
                    markerCoords = vec3ToTable(spotData.markerCoords),
                    rotationZ = spotData.rotationZ,
                    inputQty = spotData.inputQty,
                    outputQty = spotData.outputQty,
                    time = spotData.time,
                    animType = spotData.animType,
                    animPreset = spotData.animPreset,
                    animDict = spotData.animDict,
                    animName = spotData.animName,
                    animProp = spotData.animProp,
                    faction = spotData.faction,
                    factionGrade = spotData.factionGrade
                })
                if result and result.success then
                    if editingSpotIndex then
                        transformSpots[editingSpotIndex] = spotData
                    end
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de transformation modifié." })
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = (result and result.error or "Erreur") .. "." })
                end
            else
                local result = TriggerServerCallback("drugBuilder:addTransformSpot", pipelineData.id, {
                    coords = vec3ToTable(spotData.coords),
                    markerCoords = vec3ToTable(spotData.markerCoords),
                    rotationZ = spotData.rotationZ,
                    inputQty = spotData.inputQty,
                    outputQty = spotData.outputQty,
                    time = spotData.time,
                    animType = spotData.animType,
                    animPreset = spotData.animPreset,
                    animDict = spotData.animDict,
                    animName = spotData.animName,
                    animProp = spotData.animProp,
                    faction = spotData.faction,
                    factionGrade = spotData.factionGrade
                })
                if result and result.success then
                    spotData.spotId = result.spotId
                    table.insert(transformSpots, spotData)
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de transformation ajouté." })
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = (result and result.error or "Erreur") .. "." })
                end
            end
        else
            if editingSpotIndex then
                transformSpots[editingSpotIndex] = spotData
            else
                table.insert(transformSpots, spotData)
            end
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de transformation " .. (editingSpotIndex and "modifié" or "ajouté") .. "." })
        end

        ResetEditingSpot()
        StaffMenu.drugTransformSpotEdit.close()
        Wait(100)
        StaffMenu.drugTransformList.open()
    end)
end

function StaffMenu.BuildDrugTransformSpotManageMenu()
    if not managingSpotIndex or not transformSpots[managingSpotIndex] then return end
    local spot = transformSpots[managingSpotIndex]

    StaffMenu.drugTransformSpotManage.Separator(":report: INFORMATIONS", nil, nil, nil)

    if spot.coords then
        StaffMenu.drugTransformSpotManage.Button(":pin: Coordonnées", string.format("%.1f, %.1f, %.1f", spot.coords.x, spot.coords.y, spot.coords.z), nil, nil, true, function() end)
    end
    StaffMenu.drugTransformSpotManage.Button(":chart: Input/Output", (spot.inputQty or 1) .. " → " .. (spot.outputQty or 1), nil, nil, true, function() end)
    StaffMenu.drugTransformSpotManage.Button(":clock: Durée", tostring((spot.time or 3000) / 1000) .. "s", nil, nil, true, function() end)

    if spot.faction then
        StaffMenu.drugTransformSpotManage.Button(":flag: Faction", GetDrugFactionLabel(spot.faction) .. " (grade " .. (spot.factionGrade or 0) .. "+)", nil, nil, true, function() end)
    end

    StaffMenu.drugTransformSpotManage.Separator(":bolt: ACTIONS", nil, nil, nil)

    StaffMenu.drugTransformSpotManage.Button(":edit: MODIFIER", "Éditer ce point de transformation", nil, "chevron", false, function()
        editingSpot = {
            coords = spot.coords,
            markerCoords = spot.markerCoords,
            rotationZ = spot.rotationZ,
            inputQty = spot.inputQty or 1,
            outputQty = spot.outputQty or 1,
            time = spot.time or 3000,
            animType = spot.animType or "predefined",
            animPreset = spot.animPreset,
            animDict = spot.animDict,
            animName = spot.animName,
            animProp = spot.animProp,
            faction = spot.faction,
            factionGrade = spot.factionGrade,
            spotId = spot.spotId
        }
        editingSpotIndex = managingSpotIndex
    end, StaffMenu.drugTransformSpotEdit)

    if spot.coords then
        StaffMenu.drugTransformSpotManage.Button(":pin: TÉLÉPORTER", "Se téléporter au point", nil, "chevron", false, function()
            SetEntityCoords(PlayerPedId(), spot.coords.x, spot.coords.y, spot.coords.z, false, false, false, false)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Téléporté au point de transformation." })
        end)
    end

    StaffMenu.drugTransformSpotManage.Button(":trash: SUPPRIMER", "Supprimer ce point de transformation", nil, "chevron", false, function()
        if pipelineData.isUpdate and spot.spotId then
            local result = TriggerServerCallback("drugBuilder:deleteTransformSpot", pipelineData.id, spot.spotId)
            if result and result.success then
                table.remove(transformSpots, managingSpotIndex)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de transformation supprimé." })
                StaffMenu.drugTransformSpotManage.close()
                Wait(100)
                StaffMenu.drugTransformList.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = (result and result.error or "Erreur") .. "." })
            end
        else
            table.remove(transformSpots, managingSpotIndex)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Point de transformation supprimé." })
            StaffMenu.drugTransformSpotManage.close()
            Wait(100)
            StaffMenu.drugTransformList.open()
        end
    end)
end

function StaffMenu.BuildDrugHarvestAnimMenu()
    if not cachedDrugPresets or #cachedDrugPresets == 0 then
        cachedDrugPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations") or {}
    end

    drugPendingAnimation = {
        type = editingSpot.animType or "predefined",
        preset = editingSpot.animPreset,
        dict = editingSpot.animDict,
        anim = editingSpot.animName,
        prop = editingSpot.animProp
    }

    harvestAnimIndexMap = {}
    local idx = 1

    StaffMenu.drugHarvestAnim.Separator(":mask: ANIMATIONS PRÉDÉFINIES", nil, nil, nil)
    idx = idx + 1

    for _, preset in ipairs(cachedDrugPresets) do
        harvestAnimIndexMap[idx] = { type = "predefined", preset = preset.id, dict = preset.dict, anim = preset.anim, prop = preset.prop }
        idx = idx + 1
        local isSelected = editingSpot.animType == "predefined" and editingSpot.animPreset == preset.id
        StaffMenu.drugHarvestAnim.Button(
            (isSelected and "> " or "") .. preset.label,
            preset.dict .. "/" .. preset.anim,
            nil, "chevron", false,
            function()
                drugPendingAnimation = { type = "predefined", preset = preset.id, dict = preset.dict, anim = preset.anim, prop = preset.prop }
                PlayDrugAnimOnPreview(preset.dict, preset.anim)
            end
        )
    end

    StaffMenu.drugHarvestAnim.Separator(":mask: ANIMATION CUSTOM", nil, nil, nil)

    StaffMenu.drugHarvestAnim.Button(":film: DICT CUSTOM", "Entrer le dict manuellement", nil, "chevron", false, function()
        local dict = VFW.Nui.KeyboardInput(true, "Animation dict", "", 100)
        if dict and dict ~= "" and dict ~= "KBD_CANCEL" then
            local anim = VFW.Nui.KeyboardInput(true, "Animation name", "", 100)
            if anim and anim ~= "" and anim ~= "KBD_CANCEL" then
                drugPendingAnimation = { type = "custom", preset = nil, dict = dict, anim = anim, prop = nil }
                PlayDrugAnimOnPreview(dict, anim)
            end
        end
    end)

    StaffMenu.drugHarvestAnim.Separator("", nil, nil, nil)

    StaffMenu.drugHarvestAnim.Button(":check: VALIDER", "Confirmer l'animation", nil, "chevron", false, function()
        if drugPendingAnimation then
            editingSpot.animType = drugPendingAnimation.type
            editingSpot.animPreset = drugPendingAnimation.preset
            editingSpot.animDict = drugPendingAnimation.dict
            editingSpot.animName = drugPendingAnimation.anim
            editingSpot.animProp = drugPendingAnimation.prop
        end
        DeleteDrugAnimPreview()
        drugPendingAnimation = nil
        drugCurrentAnimDict = nil
        drugCurrentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.drugHarvestAnim.close()
            Wait(100)
            StaffMenu.drugHarvestSpotEdit.open()
        end)
    end)

    StaffMenu.drugHarvestAnim.Button(":x: ANNULER", "Revenir sans changer", nil, "chevron", false, function()
        DeleteDrugAnimPreview()
        drugPendingAnimation = nil
        drugCurrentAnimDict = nil
        drugCurrentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.drugHarvestAnim.close()
            Wait(100)
            StaffMenu.drugHarvestSpotEdit.open()
        end)
    end)
end

StaffMenu.drugHarvestAnim.OnIndexChange(function(index, item)
    local animData = harvestAnimIndexMap[index]
    if animData and animData.dict and animData.anim then
        PlayDrugAnimOnPreview(animData.dict, animData.anim)
    end
end)

function StaffMenu.BuildDrugTransformAnimMenu()
    if not cachedDrugPresets or #cachedDrugPresets == 0 then
        cachedDrugPresets = TriggerServerCallback("illegalBuilder:getPresetAnimations") or {}
    end

    drugPendingAnimation = {
        type = editingSpot.animType or "predefined",
        preset = editingSpot.animPreset,
        dict = editingSpot.animDict,
        anim = editingSpot.animName,
        prop = editingSpot.animProp
    }

    transformAnimIndexMap = {}
    local idx = 1

    StaffMenu.drugTransformAnim.Separator(":mask: ANIMATIONS PRÉDÉFINIES", nil, nil, nil)
    idx = idx + 1

    for _, preset in ipairs(cachedDrugPresets) do
        transformAnimIndexMap[idx] = { type = "predefined", preset = preset.id, dict = preset.dict, anim = preset.anim, prop = preset.prop }
        idx = idx + 1
        local isSelected = editingSpot.animType == "predefined" and editingSpot.animPreset == preset.id
        StaffMenu.drugTransformAnim.Button(
            (isSelected and "> " or "") .. preset.label,
            preset.dict .. "/" .. preset.anim,
            nil, "chevron", false,
            function()
                drugPendingAnimation = { type = "predefined", preset = preset.id, dict = preset.dict, anim = preset.anim, prop = preset.prop }
                PlayDrugAnimOnPreview(preset.dict, preset.anim)
            end
        )
    end

    StaffMenu.drugTransformAnim.Separator(":mask: ANIMATION CUSTOM", nil, nil, nil)

    StaffMenu.drugTransformAnim.Button(":film: DICT CUSTOM", "Entrer le dict manuellement", nil, "chevron", false, function()
        local dict = VFW.Nui.KeyboardInput(true, "Animation dict", "", 100)
        if dict and dict ~= "" and dict ~= "KBD_CANCEL" then
            local anim = VFW.Nui.KeyboardInput(true, "Animation name", "", 100)
            if anim and anim ~= "" and anim ~= "KBD_CANCEL" then
                drugPendingAnimation = { type = "custom", preset = nil, dict = dict, anim = anim, prop = nil }
                PlayDrugAnimOnPreview(dict, anim)
            end
        end
    end)

    StaffMenu.drugTransformAnim.Separator("", nil, nil, nil)

    StaffMenu.drugTransformAnim.Button(":check: VALIDER", "Confirmer l'animation", nil, "chevron", false, function()
        if drugPendingAnimation then
            editingSpot.animType = drugPendingAnimation.type
            editingSpot.animPreset = drugPendingAnimation.preset
            editingSpot.animDict = drugPendingAnimation.dict
            editingSpot.animName = drugPendingAnimation.anim
            editingSpot.animProp = drugPendingAnimation.prop
        end
        DeleteDrugAnimPreview()
        drugPendingAnimation = nil
        drugCurrentAnimDict = nil
        drugCurrentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.drugTransformAnim.close()
            Wait(100)
            StaffMenu.drugTransformSpotEdit.open()
        end)
    end)

    StaffMenu.drugTransformAnim.Button(":x: ANNULER", "Revenir sans changer", nil, "chevron", false, function()
        DeleteDrugAnimPreview()
        drugPendingAnimation = nil
        drugCurrentAnimDict = nil
        drugCurrentAnimName = nil
        Citizen.SetTimeout(50, function()
            StaffMenu.drugTransformAnim.close()
            Wait(100)
            StaffMenu.drugTransformSpotEdit.open()
        end)
    end)
end

StaffMenu.drugTransformAnim.OnIndexChange(function(index, item)
    local animData = transformAnimIndexMap[index]
    if animData and animData.dict and animData.anim then
        PlayDrugAnimOnPreview(animData.dict, animData.anim)
    end
end)

function StaffMenu.BuildDrugHarvestFactionMenu()
    if not cachedDrugFactions or #cachedDrugFactions == 0 then
        cachedDrugFactions = TriggerServerCallback("illegalBuilder:getFactions") or {}
    end

    StaffMenu.drugHarvestFaction.Button(":ban: AUCUNE RESTRICTION", "Tous les joueurs peuvent récolter", nil, "chevron", false, function()
        editingSpot.faction = nil
        editingSpot.factionGrade = nil
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Restriction faction retirée." })
        StaffMenu.drugHarvestFaction.close()
        StaffMenu.drugHarvestFaction.parent.open()
    end)

    for _, faction in ipairs(cachedDrugFactions) do
        StaffMenu.drugHarvestFaction.Button(
            faction.label, faction.name, nil, "chevron", false,
            function()
                editingSpot.faction = faction.name
                cachedDrugFactionGrades[faction.name] = TriggerServerCallback("illegalBuilder:getFactionGrades", faction.name) or {}
            end,
            StaffMenu.drugHarvestGrade
        )
    end
end

function StaffMenu.BuildDrugHarvestGradeMenu()
    if not editingSpot.faction then return end

    local grades = cachedDrugFactionGrades[editingSpot.faction] or {}

    StaffMenu.drugHarvestGrade.Button(":unlock: GRADE 0 (Tous)", "Pas de grade minimum", nil, "chevron", false, function()
        editingSpot.factionGrade = 0
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Faction: " .. GetDrugFactionLabel(editingSpot.faction) .. " (grade 0+)." })
        StaffMenu.drugHarvestGrade.close()
        StaffMenu.drugHarvestGrade.parent.parent.open()
    end)

    for _, grade in ipairs(grades) do
        StaffMenu.drugHarvestGrade.Button(
            ":lock: Grade " .. grade.grade, grade.label or grade.name, nil, "chevron", false,
            function()
                editingSpot.factionGrade = grade.grade
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Faction: " .. GetDrugFactionLabel(editingSpot.faction) .. " (grade " .. grade.grade .. "+)." })
                StaffMenu.drugHarvestGrade.close()
                StaffMenu.drugHarvestGrade.parent.parent.open()
            end
        )
    end
end

function StaffMenu.BuildDrugTransformFactionMenu()
    if not cachedDrugFactions or #cachedDrugFactions == 0 then
        cachedDrugFactions = TriggerServerCallback("illegalBuilder:getFactions") or {}
    end

    StaffMenu.drugTransformFaction.Button(":ban: AUCUNE RESTRICTION", "Tous les joueurs peuvent transformer", nil, "chevron", false, function()
        editingSpot.faction = nil
        editingSpot.factionGrade = nil
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Restriction faction retirée." })
        StaffMenu.drugTransformFaction.close()
        StaffMenu.drugTransformFaction.parent.open()
    end)

    for _, faction in ipairs(cachedDrugFactions) do
        StaffMenu.drugTransformFaction.Button(
            faction.label, faction.name, nil, "chevron", false,
            function()
                editingSpot.faction = faction.name
                cachedDrugFactionGrades[faction.name] = TriggerServerCallback("illegalBuilder:getFactionGrades", faction.name) or {}
            end,
            StaffMenu.drugTransformGrade
        )
    end
end

function StaffMenu.BuildDrugTransformGradeMenu()
    if not editingSpot.faction then return end

    local grades = cachedDrugFactionGrades[editingSpot.faction] or {}

    StaffMenu.drugTransformGrade.Button(":unlock: GRADE 0 (Tous)", "Pas de grade minimum", nil, "chevron", false, function()
        editingSpot.factionGrade = 0
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Faction: " .. GetDrugFactionLabel(editingSpot.faction) .. " (grade 0+)." })
        StaffMenu.drugTransformGrade.close()
        StaffMenu.drugTransformGrade.parent.parent.open()
    end)

    for _, grade in ipairs(grades) do
        StaffMenu.drugTransformGrade.Button(
            ":lock: Grade " .. grade.grade, grade.label or grade.name, nil, "chevron", false,
            function()
                editingSpot.factionGrade = grade.grade
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Drug Builder', message = "Faction: " .. GetDrugFactionLabel(editingSpot.faction) .. " (grade " .. grade.grade .. "+)." })
                StaffMenu.drugTransformGrade.close()
                StaffMenu.drugTransformGrade.parent.parent.open()
            end
        )
    end
end

function StaffMenu.BuildDrugListMenu()
    if not cachedDrugPipelines or #cachedDrugPipelines == 0 then
        StaffMenu.drugList.Button(":x: AUCUNE DROGUE", "Créez-en une d'abord", nil, nil, true, function() end)
        return
    end

    for _, pipeline in ipairs(cachedDrugPipelines) do
        local statusParts = {}
        if pipeline.harvest_count and pipeline.harvest_count > 0 then table.insert(statusParts, pipeline.harvest_count .. (pipeline.harvest_count > 1 and " récoltes" or " récolte")) end
        if pipeline.transform_count and pipeline.transform_count > 0 then table.insert(statusParts, pipeline.transform_count .. (pipeline.transform_count > 1 and " transfos" or " transfo")) end
        if pipeline.deal_active == 1 or pipeline.deal_active == true then table.insert(statusParts, "Vente") end
        local statusText = #statusParts > 0 and table.concat(statusParts, " + ") or "Aucun module"

      StaffMenu.drugList.Button(
            ":flask: " .. pipeline.name,
            "Item: " .. (pipeline.drug_item_label or pipeline.drug_item),
            statusText,
            "chevron", false,
            function()
                ResetPipelineData()
                local details = TriggerServerCallback("drugBuilder:getPipelineDetails", pipeline.id)
                if not details then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Drug Builder', message = "Impossible de charger les détails." })
                    return
                end

                pipelineData.isUpdate = true
                pipelineData.id = pipeline.id
                pipelineData.name = pipeline.name
                pipelineData.drugItem = pipeline.drug_item
                pipelineData.drugItemLabel = pipeline.drug_item_label or pipeline.drug_item
                pipelineData.drugItemExists = true
                pipelineData.rawItem = pipeline.raw_item
                pipelineData.rawItemLabel = pipeline.raw_item_label or pipeline.raw_item
                pipelineData.rawItemExists = pipeline.raw_item ~= nil
                pipelineData.dealPriceMin = pipeline.deal_price_min or 100
                pipelineData.dealPriceMax = pipeline.deal_price_max or 200
                pipelineData.dealQtyMin = pipeline.deal_qty_min or 1
                pipelineData.dealQtyMax = pipeline.deal_qty_max or 5
                pipelineData.dealActive = pipeline.deal_active == true or pipeline.deal_active == 1

                harvestSpots = {}
                if details.harvestSpots then
                    for _, hs in ipairs(details.harvestSpots) do
                        table.insert(harvestSpots, {
                            coords = vector3(hs.coords_x, hs.coords_y, hs.coords_z),
                            markerCoords = (hs.marker_x and hs.marker_y and hs.marker_z) and vector3(hs.marker_x, hs.marker_y, hs.marker_z) or nil,
                            rotationZ = hs.rotation_z,
                            minQty = hs.min_quantity or 1,
                            maxQty = hs.max_quantity or 3,
                            time = hs.harvest_time or 3000,
                            animType = hs.animation_type or "predefined",
                            animPreset = hs.animation_preset,
                            animDict = hs.animation_dict,
                            animName = hs.animation_name,
                            animProp = hs.animation_prop,
                            faction = hs.faction_restriction,
                            factionGrade = hs.faction_grade_min,
                            spotId = hs.id
                        })
                    end
                end

                transformSpots = {}
                if details.transformSpots then
                    for _, ts in ipairs(details.transformSpots) do
                        local inputQty = 1
                        if ts.inputs and #ts.inputs > 0 then
                            inputQty = ts.inputs[1].quantity or 1
                        end
                        table.insert(transformSpots, {
                            coords = vector3(ts.coords_x, ts.coords_y, ts.coords_z),
                            markerCoords = (ts.marker_x and ts.marker_y and ts.marker_z) and vector3(ts.marker_x, ts.marker_y, ts.marker_z) or nil,
                            rotationZ = ts.rotation_z,
                            inputQty = inputQty,
                            outputQty = ts.output_quantity or 1,
                            time = ts.transform_time or 3000,
                            animType = ts.animation_type or "predefined",
                            animPreset = ts.animation_preset,
                            animDict = ts.animation_dict,
                            animName = ts.animation_name,
                            animProp = ts.animation_prop,
                            faction = ts.faction_restriction,
                            factionGrade = ts.faction_grade_min,
                            spotId = ts.id
                        })
                    end
                end
            end,
            StaffMenu.drugCreate
        )
    end
end
