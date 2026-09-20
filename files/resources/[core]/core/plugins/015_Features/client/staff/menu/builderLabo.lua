local laboData = {
    name = nil, label = nil,
    templateId = nil,
    doorCoords = nil, interiorCoords = nil, chestCoords = nil,
    managementCoords = nil,
    ownerFaction = nil, ownerPlayerName = nil,
    attackSlots = {},
    chestMaxWeight = 50000, chestMaxSlots = 20,
    isUpdate = false, id = nil
}

local harvestData = {
    name = nil, label = nil, propModel = nil, coords = nil, markerCoords = nil,
    itemOutput = nil, minQuantity = 1, maxQuantity = 3,
    harvestTime = 3000, cooldown = 100, radius = 2.0, maxHarvesters = 1,
    animationType = "predefined", animationPreset = nil,
    animationDict = nil, animationName = nil, animationProp = nil,
    blipEnabled = false, blipSprite = 1, blipColor = 1, blipScale = 0.8,
    blipLabel = nil, isUpdate = false, id = nil, laboId = nil, templateId = nil
}

local transformData = {
    name = nil, label = nil, propModel = nil, coords = nil, markerCoords = nil,
    inputs = {}, outputItem = nil, outputQuantity = 1,
    transformTime = 3000, animationType = "predefined",
    animationPreset = nil, animationDict = nil, animationName = nil,
    animationProp = nil,
    blipEnabled = false, blipSprite = 1, blipColor = 1, blipScale = 0.8,
    blipLabel = nil, isUpdate = false, id = nil, laboId = nil, templateId = nil
}

local cachedLabos = nil
local cachedTemplates = nil
local cachedFactions = nil
local cachedItems = nil
local cachedPresets = nil
local harvestPreviewProp = nil
local transformPreviewProp = nil

RegisterNetEvent("core:gestion-factions:refresh", function()
    cachedFactions = nil
end)

local templateEditData = {
    id = nil, name = nil, label = nil,
    interiorCoords = nil, chestCoords = nil, managementCoords = nil,
    blipSprite = 499, blipColor = 1, blipScale = 0.8
}

local function ResetTemplateEditData()
    templateEditData = {
        id = nil, name = nil, label = nil,
        interiorCoords = nil, chestCoords = nil, managementCoords = nil,
        blipSprite = 499, blipColor = 1, blipScale = 0.8
    }
end

local function ResetLaboData()
    laboData = {
        name = nil, label = nil,
        templateId = nil,
        doorCoords = nil, interiorCoords = nil, chestCoords = nil,
        managementCoords = nil,
        ownerFaction = nil, ownerPlayerName = nil,
        attackSlots = {},
        chestMaxWeight = 50000, chestMaxSlots = 20,
        isUpdate = false, id = nil
    }
end

local function ResetHarvestData()
    harvestData = {
        name = nil, label = nil, propModel = nil, coords = nil, markerCoords = nil,
        itemOutput = nil, minQuantity = 1, maxQuantity = 3,
        harvestTime = 3000, cooldown = 100, radius = 2.0, maxHarvesters = 1,
        animationType = "predefined", animationPreset = nil,
        animationDict = nil, animationName = nil, animationProp = nil,
        blipEnabled = false, blipSprite = 1, blipColor = 1, blipScale = 0.8,
        blipLabel = nil, isUpdate = false, id = nil, laboId = nil, templateId = nil
    }
end

local function ResetTransformData()
    transformData = {
        name = nil, label = nil, propModel = nil, coords = nil, markerCoords = nil,
        inputs = {}, outputItem = nil, outputQuantity = 1,
        transformTime = 3000, animationType = "predefined",
        animationPreset = nil, animationDict = nil, animationName = nil,
        animationProp = nil,
        blipEnabled = false, blipSprite = 1, blipColor = 1, blipScale = 0.8,
        blipLabel = nil, isUpdate = false, id = nil, laboId = nil, templateId = nil
    }
end

local function vec3ToTable(v)
    if not v then return nil end
    return { x = v.x, y = v.y, z = v.z }
end

local function DeletePreviewProp(propType)
    if propType == "harvest" and harvestPreviewProp and DoesEntityExist(harvestPreviewProp) then
        DeleteEntity(harvestPreviewProp)
        harvestPreviewProp = nil
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
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Labo', message = "Modele introuvable: " .. model .. "." })
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
            elseif propType == "transform" then
                transformPreviewProp = prop
            end
        end
    end)
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

local function GetPlayerPosition()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    return { x = coords.x, y = coords.y, z = coords.z, heading = heading }
end

local function FormatCoords(c)
    if not c then return "Non défini" end
    return string.format("%.1f, %.1f, %.1f", c.x, c.y, c.z)
end

local function GetItemLabel(itemName)
    if not itemName then return "Inconnu" end
    if not cachedItems then
        cachedItems = TriggerServerCallback("laboBuilder:getItems")
    end
    for _, item in ipairs(cachedItems or {}) do
        if item.name == itemName then return item.label end
    end
    return itemName
end

local function IsPlayerOwner(factionName)
    return factionName and string.sub(factionName, 1, 7) == "player:"
end

local function GetFactionLabel(factionName)
    if not factionName then return "Aucune" end
    if factionName == "no_owner" then return "Independant" end
    if IsPlayerOwner(factionName) then return "Joueur individuel" end
    if not cachedFactions then
        cachedFactions = TriggerServerCallback("laboBuilder:getFactions")
    end
    for _, faction in ipairs(cachedFactions or {}) do
        if faction.name == factionName then return faction.label end
    end
    return factionName
end

local function GetPresetLabel(presetId)
    if not presetId then return "Aucune" end
    if not cachedPresets then
        cachedPresets = TriggerServerCallback("laboBuilder:getPresetAnimations")
    end
    for _, preset in ipairs(cachedPresets or {}) do
        if preset.id == presetId then return preset.label end
    end
    return presetId
end

local function GetTemplateLabel(templateId)
    if not templateId then return "Aucune" end
    if not cachedTemplates then
        cachedTemplates = TriggerServerCallback("laboBuilder:getTemplates")
    end
    for _, t in ipairs(cachedTemplates or {}) do
        if t.id == templateId then return t.label end
    end
    return "Template #" .. templateId
end

StaffMenu.builderLabo.OnOpen(function()
    StaffMenu.builderLabo.ClearItems()
    cachedTemplates = TriggerServerCallback("laboBuilder:getTemplates")
    cachedLabos = TriggerServerCallback("laboBuilder:getLabos")

    StaffMenu.builderLabo.Separator("LABORATOIRES (" .. #(cachedLabos or {}) .. ")")

    if not cachedLabos or #cachedLabos == 0 then
        StaffMenu.builderLabo.Button("Aucun laboratoire", nil, nil, nil, false, function() end)
    else
        for _, labo in ipairs(cachedLabos) do
            local fLabel = GetFactionLabel(labo.owner_faction)
            if IsPlayerOwner(labo.owner_faction) and labo.owner_player_name then
                fLabel = "Joueur: " .. labo.owner_player_name
            end
            local tLabel = labo.template_label or "Sans template"
          StaffMenu.builderLabo.Button(
                labo.label,
                tLabel .. " | " .. fLabel,
                "#" .. labo.id,
                "chevron", false,
                function()
                    laboData.id = labo.id
                    laboData.name = labo.name
                    laboData.label = labo.label
                    laboData.templateId = labo.template_id
                    laboData.doorCoords = { x = labo.door_x, y = labo.door_y, z = labo.door_z, heading = labo.door_heading }
                    if labo.interior_x then
                        laboData.interiorCoords = { x = labo.interior_x, y = labo.interior_y, z = labo.interior_z, heading = labo.interior_heading }
                    end
                    if labo.chest_x then
                        laboData.chestCoords = { x = labo.chest_x, y = labo.chest_y, z = labo.chest_z }
                    end
                    if labo.management_x then
                        laboData.managementCoords = { x = labo.management_x, y = labo.management_y, z = labo.management_z }
                    end
                    laboData.ownerFaction = labo.owner_faction
                    laboData.ownerPlayerName = labo.owner_player_name
                    laboData.attackSlots = labo.attack_slots or {}
                    laboData.chestMaxWeight = labo.chest_max_weight or 50000
                    laboData.chestMaxSlots = labo.chest_max_slots or 20
                    laboData.isUpdate = true
                end,
                StaffMenu.builderLaboManage
            )
        end
    end

    StaffMenu.builderLabo.Separator("")

    StaffMenu.builderLabo.Button(":plus: CRÉER UN LABORATOIRE", "Nouveau labo depuis une template", nil, "chevron", false, function()
        ResetLaboData()
    end, StaffMenu.builderLaboCreate)

    StaffMenu.builderLabo.Separator("")

    StaffMenu.builderLabo.Button(":report: GÉRER LES TEMPLATES", "Modifier les templates d'intérieur", #(cachedTemplates or {}) .. (#(cachedTemplates or {}) > 1 and " templates" or " template"), "chevron", false, function()
    end, StaffMenu.builderLaboTemplateList)

    StaffMenu.builderLabo.Separator("")

    StaffMenu.builderLabo.Button(":gun: CONFIG ATTAQUE", "Timers, cooldown, membres requis", nil, "chevron", false, function()
    end, StaffMenu.builderLaboAttackConfig)
end)

local attackConfigData = {}

StaffMenu.builderLaboAttackConfig.OnOpen(function()
    StaffMenu.builderLaboAttackConfig.ClearItems()
    local config = TriggerServerCallback("laboBuilder:getAttackConfig")
    if not config then return end
    attackConfigData = config

    StaffMenu.builderLaboAttackConfig.Separator("TRANCHES HORAIRES")

    local slots = attackConfigData.attackSlots or {}
    if #slots == 0 then
        StaffMenu.builderLaboAttackConfig.Button("Aucun créneau", "Les attaques sont impossibles sans créneau", nil, nil, false, function() end)
    else
        for i, slot in ipairs(slots) do
            local label = string.format("%02dh%02d - %02dh%02d", slot.startHour, slot.startMin, slot.endHour, slot.endMin)
            StaffMenu.builderLaboAttackConfig.Button(
                label, "Cliquer pour supprimer",
                nil, "trash", false,
                function()
                    table.remove(slots, i)
                    attackConfigData.attackSlots = slots
                    TriggerServerCallback("laboBuilder:updateAttackConfig", attackConfigData)
                    VFW.ShowNotification({ type = "VERT", content = "Créneau supprimé." })
                    StaffMenu.builderLaboAttackConfig.refresh()
                end
            )
        end
    end

    StaffMenu.builderLaboAttackConfig.Button(":plus: AJOUTER UN CRÉNEAU", "Définir heure de début et de fin", nil, "chevron", false, function()
        local startStr = VFW.Nui.KeyboardInput(true, "Heure de début (ex: 20:00)", "", 5)
        if not startStr or startStr == "" or startStr == "KBD_CANCEL" then return end

        local endStr = VFW.Nui.KeyboardInput(true, "Heure de fin (ex: 22:00)", "", 5)
        if not endStr or endStr == "" or endStr == "KBD_CANCEL" then return end

        local sh, sm = startStr:match("^(%d+):(%d+)$")
        local eh, em = endStr:match("^(%d+):(%d+)$")

        if not sh or not eh then
            sh, sm = startStr:match("^(%d+)h(%d+)$")
            eh, em = endStr:match("^(%d+)h(%d+)$")
        end

        if not sh or not eh then
            sh = startStr:match("^(%d+)$")
            sm = "0"
          eh = endStr:match("^(%d+)$")
            em = "0"
      end

        sh, sm, eh, em = tonumber(sh), tonumber(sm or 0), tonumber(eh), tonumber(em or 0)

        if not sh or not eh or sh < 0 or sh > 23 or eh < 0 or eh > 23 then
            VFW.ShowNotification({ type = "ROUGE", content = "Ce format n'est pas valide. Utilisez HH:MM." })
            return
        end

        table.insert(slots, { startHour = sh, startMin = sm, endHour = eh, endMin = em })
        attackConfigData.attackSlots = slots
        TriggerServerCallback("laboBuilder:updateAttackConfig", attackConfigData)
        VFW.ShowNotification({ type = "VERT", content = "Créneau ajouté." })
        StaffMenu.builderLaboAttackConfig.refresh()
    end)

    StaffMenu.builderLaboAttackConfig.Separator("PROTECTION")

    StaffMenu.builderLaboAttackConfig.Button(":shield: COOLDOWN IMMUNITÉ", "Temps d'immunité après capture (en minutes)", tostring(attackConfigData.attackCooldownMinutes) .. " min", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Durée en minutes", tostring(attackConfigData.attackCooldownMinutes), 10)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            local val = tonumber(input)
            if val and val >= 0 then
                attackConfigData.attackCooldownMinutes = val
                local result = TriggerServerCallback("laboBuilder:updateAttackConfig", attackConfigData)
                if result and result.success then
                    VFW.ShowNotification({ type = "VERT", content = "Cooldown immunité mis à jour : " .. val .. " min" })
                end
                StaffMenu.builderLaboAttackConfig.refresh()
            end
        end
    end)

    StaffMenu.builderLaboAttackConfig.Button(":users: MINIMUM CONNECTÉS", "Membres de la faction propriétaire requis en ligne", tostring(attackConfigData.minFactionOnline), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nombre minimum", tostring(attackConfigData.minFactionOnline), 5)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            local val = tonumber(input)
            if val and val >= 0 then
                attackConfigData.minFactionOnline = val
                local result = TriggerServerCallback("laboBuilder:updateAttackConfig", attackConfigData)
                if result and result.success then
                    VFW.ShowNotification({ type = "VERT", content = "Minimum connectés mis à jour : " .. val })
                end
                StaffMenu.builderLaboAttackConfig.refresh()
            end
        end
    end)
end)

StaffMenu.builderLaboManage.OnOpen(function()
    StaffMenu.builderLaboManage.ClearItems()

    if not laboData.id then return end

    StaffMenu.builderLaboManage.Separator("LABO: " .. (laboData.label or laboData.name or "?"))

    StaffMenu.builderLaboManage.Button(":edit: MODIFIER", "Modifier la configuration du labo", nil, "chevron", false, function()
    end, StaffMenu.builderLaboCreate)

    StaffMenu.builderLaboManage.Button(":door: TP PORTE", "Se téléporter à l'entrée", nil, nil, false, function()
        if laboData.doorCoords then
            SetEntityCoords(PlayerPedId(), laboData.doorCoords.x, laboData.doorCoords.y, laboData.doorCoords.z, false, false, false, true)
            SetEntityHeading(PlayerPedId(), laboData.doorCoords.heading or 0)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Téléporté à la porte." })
        end
    end)

    StaffMenu.builderLaboManage.Button(":home: TP INTÉRIEUR", "Se téléporter dans le labo", nil, nil, false, function()
        if laboData.interiorCoords then
            SetEntityCoords(PlayerPedId(), laboData.interiorCoords.x, laboData.interiorCoords.y, laboData.interiorCoords.z, false, false, false, true)
            SetEntityHeading(PlayerPedId(), laboData.interiorCoords.heading or 0)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Téléporté à l'intérieur." })
        end
    end)

    StaffMenu.builderLaboManage.Separator("DANGER")

    StaffMenu.builderLaboManage.Button(":trash: SUPPRIMER", "Supprime le labo et tous ses accès", nil, "trash", false, function()
        local confirm = VFW.Nui.ChoiceInput("Supprimer le labo ?", "Cette action est irréversible.", {
            { label = "Confirmer la suppression", value = "yes" },
            { label = "Annuler", value = "no" }
        })
        if confirm == "yes" then
            local result = TriggerServerCallback("laboBuilder:deleteLabo", laboData.id)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Labo supprimé." })
                ResetLaboData()
                cachedLabos = nil
                Citizen.SetTimeout(50, function()
                    StaffMenu.builderLaboManage.close()
                    StaffMenu.builderLabo.open()
                end)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Labo', message = (result and result.error or "Erreur") .. "." })
            end
        end
    end)
end)

StaffMenu.builderLaboCreate.OnOpen(function()
    StaffMenu.builderLaboCreate.ClearItems()

    StaffMenu.builderLaboCreate.Separator("INFORMATIONS")

    StaffMenu.builderLaboCreate.Button(":edit: LABEL", "Nom affiché aux joueurs", laboData.label or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Label (ex: Laboratoire Cocaine)", laboData.label or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            laboData.label = input
            laboData.name = string.lower(input):gsub("[%s]+", "_"):gsub("[^%w_]", "")
            StaffMenu.builderLaboCreate.refresh()
        end
    end)

    StaffMenu.builderLaboCreate.Separator("TEMPLATE")

    StaffMenu.builderLaboCreate.Button(":building: TEMPLATE", "Template d'intérieur utilisée", GetTemplateLabel(laboData.templateId), "chevron", false, function()
        cachedTemplates = TriggerServerCallback("laboBuilder:getTemplates")
    end, StaffMenu.builderLaboTemplatePicker)

    StaffMenu.builderLaboCreate.Separator("POSITION EXTÉRIEURE")

    StaffMenu.builderLaboCreate.Button(":door: PORTE", "Point d'entrée devant le labo", FormatCoords(laboData.doorCoords), "chevron", false, function()
        laboData.doorCoords = GetPlayerPosition()
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Position porte définie." })
        StaffMenu.builderLaboCreate.refresh()
    end)

    StaffMenu.builderLaboCreate.Separator("FACTION PROPRIÉTAIRE")

    StaffMenu.builderLaboCreate.Button(":users: FACTION", "Sélectionner la faction propriétaire", GetFactionLabel(laboData.ownerFaction), "chevron", false, function()
        if not cachedFactions then
            cachedFactions = TriggerServerCallback("laboBuilder:getFactions")
        end
    end, StaffMenu.builderLaboFaction)

    local isIndependent = laboData.ownerFaction == "no_owner"

  StaffMenu.builderLaboCreate.Separator("COFFRE")

    StaffMenu.builderLaboCreate.Button(":scales: POIDS MAX", isIndependent and "Desactive pour les labos independants" or "Capacite maximale du coffre", tostring(laboData.chestMaxWeight), "chevron", isIndependent, function()
        if isIndependent then return end
        local input = VFW.Nui.KeyboardInput(true, "Poids max du coffre", tostring(laboData.chestMaxWeight), 10)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            local val = tonumber(input)
            if val and val > 0 then
                laboData.chestMaxWeight = val
                StaffMenu.builderLaboCreate.refresh()
            end
        end
    end)

    StaffMenu.builderLaboCreate.Slider(":box: SLOTS MAX", laboData.chestMaxSlots, 5, 100, 5, isIndependent and "Desactive pour les labos independants" or "Nombre de slots du coffre", isIndependent, function(value)
        if isIndependent then return end
        laboData.chestMaxSlots = value
    end)

    if laboData.isUpdate and laboData.id and not laboData.templateId then
        StaffMenu.builderLaboCreate.Separator("POSITIONS (SANS TEMPLATE)")

        StaffMenu.builderLaboCreate.Button(":pin: INTÉRIEUR", "Spawn à l'intérieur du labo", FormatCoords(laboData.interiorCoords), "chevron", false, function()
            laboData.interiorCoords = GetPlayerPosition()
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Position intérieur définie." })
            StaffMenu.builderLaboCreate.refresh()
        end)

        StaffMenu.builderLaboCreate.Button(":box: COFFRE", "Position du coffre dans le labo", FormatCoords(laboData.chestCoords), "chevron", false, function()
            laboData.chestCoords = GetPlayerPosition()
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Position coffre définie." })
            StaffMenu.builderLaboCreate.refresh()
        end)

        StaffMenu.builderLaboCreate.Button(":settings: POINT DE GESTION", "Position du point de gestion", FormatCoords(laboData.managementCoords), "chevron", false, function()
            laboData.managementCoords = GetPlayerPosition()
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Position gestion définie." })
            StaffMenu.builderLaboCreate.refresh()
        end)

        StaffMenu.builderLaboCreate.Separator("POINTS DU LABO")

        local harvestPoints = TriggerServerCallback("laboBuilder:getHarvestPoints", laboData.id) or {}
        local transformPoints = TriggerServerCallback("laboBuilder:getTransformPoints", laboData.id) or {}

        StaffMenu.builderLaboCreate.Button(":leaf: POINTS DE RÉCOLTE", "Gérer les spots de récolte", #harvestPoints .. (#harvestPoints > 1 and " points" or " point"), "chevron", false, function()
            harvestData.laboId = laboData.id
            harvestData.templateId = nil
        end, StaffMenu.builderLaboHarvestList)

        StaffMenu.builderLaboCreate.Button(":flask: POINTS DE TRANSFORMATION", "Gérer les spots de transfo", #transformPoints .. (#transformPoints > 1 and " points" or " point"), "chevron", false, function()
            transformData.laboId = laboData.id
            transformData.templateId = nil
        end, StaffMenu.builderLaboTransformList)
    end

    StaffMenu.builderLaboCreate.Separator("VALIDATION")

    local isValid = laboData.label and laboData.doorCoords and (laboData.templateId or laboData.interiorCoords)

    StaffMenu.builderLaboCreate.Button(laboData.isUpdate and ":save: SAUVEGARDER" or ":check: CRÉER LE LABO", not isValid and "Remplis label, porte et template/intérieur" or nil, nil, "check", false, function()
        if not isValid then
            VFW.ShowNotification({ type = "ROUGE", content = "Remplis label, porte et template/intérieur." })
            return
        end
        local sendData = {
            name = laboData.name,
            label = laboData.label,
            templateId = laboData.templateId,
            doorCoords = laboData.doorCoords,
            interiorCoords = laboData.interiorCoords,
            chestCoords = laboData.chestCoords,
            managementCoords = laboData.managementCoords,
            ownerFaction = laboData.ownerFaction,
            ownerPlayerName = laboData.ownerPlayerName,
            chestMaxWeight = laboData.chestMaxWeight,
            chestMaxSlots = laboData.chestMaxSlots
        }

        local result
        if laboData.isUpdate then
            result = TriggerServerCallback("laboBuilder:updateLabo", laboData.id, sendData)
        else
            result = TriggerServerCallback("laboBuilder:createLabo", sendData)
        end

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = laboData.isUpdate and "Labo mis à jour." or "Labo créé." })
            if not laboData.isUpdate and result.id then
                laboData.id = result.id
                laboData.isUpdate = true
            end
            cachedLabos = nil
            Citizen.SetTimeout(50, function()
                StaffMenu.builderLaboCreate.refresh()
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Labo', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end)

StaffMenu.builderLaboTemplatePicker.OnOpen(function()
    StaffMenu.builderLaboTemplatePicker.ClearItems()

    StaffMenu.builderLaboTemplatePicker.Button(":x: AUCUNE TEMPLATE", "Mode legacy (positions manuelles)", nil, nil, false, function()
        laboData.templateId = nil
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Template retirée." })
        exports["VUI"]:HandleBack()
    end)

    StaffMenu.builderLaboTemplatePicker.Separator("TEMPLATES")

    for _, t in ipairs(cachedTemplates or {}) do
        local isCurrent = laboData.templateId == t.id
        StaffMenu.builderLaboTemplatePicker.Button(
            t.label,
            t.name,
            isCurrent and "Actuelle" or nil,
            isCurrent and "check" or nil,
            false,
            function()
                laboData.templateId = t.id
                laboData.interiorCoords = nil
                laboData.chestCoords = nil
                laboData.managementCoords = nil
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Template: " .. t.label })
                exports["VUI"]:HandleBack()
            end
        )
    end
end)

StaffMenu.builderLaboFaction.OnOpen(function()
    StaffMenu.builderLaboFaction.ClearItems()

    StaffMenu.builderLaboFaction.SearchInput("Rechercher une faction")

    StaffMenu.builderLaboFaction.Button(":x: AUCUNE (LIBRE)", "Retirer la faction propriétaire", nil, nil, false, function()
        laboData.ownerFaction = nil
        laboData.ownerPlayerName = nil
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Faction retirée." })
        exports["VUI"]:HandleBack()
    end)

    local isIndep = laboData.ownerFaction == "no_owner"
  StaffMenu.builderLaboFaction.Button(":globe: INDEPENDANT", "Accessible a tous, sans coffre ni gestion", isIndep and "Actuelle" or nil, isIndep and "check" or nil, false, function()
        laboData.ownerFaction = "no_owner"
      laboData.ownerPlayerName = nil
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Labo independant (accessible a tous)." })
        exports["VUI"]:HandleBack()
    end)

    local isPlayerOwned = IsPlayerOwner(laboData.ownerFaction)
    local playerLabel = isPlayerOwned and laboData.ownerPlayerName or nil
    StaffMenu.builderLaboFaction.Button(":user: JOUEUR INDIVIDUEL", "Coffre uniquement, pas de gestion ni attaque", isPlayerOwned and (playerLabel or "Actuelle") or nil, isPlayerOwned and "check" or nil, false, function()
    end, StaffMenu.builderLaboPlayerSelect)

    StaffMenu.builderLaboFaction.Separator("FACTIONS")

    for _, f in ipairs(cachedFactions or {}) do
        local isCurrent = laboData.ownerFaction == f.name
        StaffMenu.builderLaboFaction.Button(
            f.label,
            f.name,
            isCurrent and "Actuelle" or nil,
            isCurrent and "check" or nil,
            false,
            function()
                laboData.ownerFaction = f.name
                laboData.ownerPlayerName = nil
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Faction définie : " .. f.label })
                exports["VUI"]:HandleBack()
            end
        )
    end
end)

local playerSearchQuery = nil
local playerList = {}

StaffMenu.builderLaboPlayerSelect.OnOpen(function()
    StaffMenu.builderLaboPlayerSelect.ClearItems()

    if #playerList == 0 and not playerSearchQuery then
        playerList = TriggerServerCallback("laboBuilder:getAllPlayers") or {}
    end

    local searchLabel = playerSearchQuery and "RECHERCHER:" or "RECHERCHER"
  local searchValue = playerSearchQuery or "UUID, pseudo ou nom RP"

  StaffMenu.builderLaboPlayerSelect.Button(searchLabel, searchValue, nil, "search", false, function()
        if playerSearchQuery then
            playerSearchQuery = nil
            playerList = TriggerServerCallback("laboBuilder:getAllPlayers") or {}
            StaffMenu.builderLaboPlayerSelect.refresh()
            return
        end

        local query = VFW.Nui.KeyboardInput(true, "Recherche : UUID, pseudo ou nom RP")
        if not query or query == "" or query == "KBD_CANCEL" then return end

        playerSearchQuery = query
        playerList = TriggerServerCallback("laboBuilder:searchPlayers", query) or {}
        StaffMenu.builderLaboPlayerSelect.refresh()
    end)

    StaffMenu.builderLaboPlayerSelect.Separator("")

    local listTitle = playerSearchQuery and ("~ Résultats (" .. #playerList .. ") ~") or ("~ Joueurs (" .. #playerList .. ") ~")

    if #playerList == 0 then
        StaffMenu.builderLaboPlayerSelect.Separator(playerSearchQuery and "~ Aucun résultat ~" or "~ Aucun joueur ~")
    else
        StaffMenu.builderLaboPlayerSelect.Separator(listTitle)

        for _, p in ipairs(playerList) do
            local statusLabel = p.isOnline and "(En ligne)" or ""
          local subtitle = p.name .. " " .. statusLabel
            StaffMenu.builderLaboPlayerSelect.Button(
                "#" .. p.id .. " " .. p.pseudo,
                subtitle,
                nil, "arrow", false,
                function()
                    laboData.ownerFaction = "player:" .. p.id
                    laboData.ownerPlayerName = p.pseudo
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Joueur défini : " .. p.pseudo })
                    playerSearchQuery = nil
                    playerList = {}
                    exports["VUI"]:HandleBack()
                    exports["VUI"]:HandleBack()
                end
            )
        end
    end
end)

StaffMenu.builderLaboAttackSlots.OnOpen(function()
    StaffMenu.builderLaboAttackSlots.ClearItems()

    StaffMenu.builderLaboAttackSlots.Separator("TRANCHES HORAIRES D'ATTAQUE")

    if #laboData.attackSlots == 0 then
        StaffMenu.builderLaboAttackSlots.Button("Aucun créneau", "Ajoutez des créneaux ci-dessous", nil, nil, false, function() end)
    else
        for i, slot in ipairs(laboData.attackSlots) do
            local label = string.format("%02dh%02d - %02dh%02d", slot.startHour, slot.startMin, slot.endHour, slot.endMin)
            StaffMenu.builderLaboAttackSlots.Button(
                label, "Cliquer pour supprimer",
                nil, "trash", false,
                function()
                    table.remove(laboData.attackSlots, i)
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Créneau supprimé." })
                    StaffMenu.builderLaboAttackSlots.refresh()
                end
            )
        end
    end

    StaffMenu.builderLaboAttackSlots.Separator("AJOUTER")

    StaffMenu.builderLaboAttackSlots.Button(":plus: AJOUTER UN CRÉNEAU", "Définir heure début et fin", nil, "chevron", false, function()
        local startStr = VFW.Nui.KeyboardInput(true, "Heure de début (ex: 20:00)", "", 5)
        if not startStr or startStr == "" or startStr == "KBD_CANCEL" then return end

        local endStr = VFW.Nui.KeyboardInput(true, "Heure de fin (ex: 22:00)", "", 5)
        if not endStr or endStr == "" or endStr == "KBD_CANCEL" then return end

        local sh, sm = startStr:match("^(%d+):(%d+)$")
        local eh, em = endStr:match("^(%d+):(%d+)$")

        if not sh or not eh then
            sh, sm = startStr:match("^(%d+)h(%d+)$")
            eh, em = endStr:match("^(%d+)h(%d+)$")
        end

        if not sh or not eh then
            sh = startStr:match("^(%d+)$")
            sm = "0"
          eh = endStr:match("^(%d+)$")
            em = "0"
      end

        sh, sm, eh, em = tonumber(sh), tonumber(sm or 0), tonumber(eh), tonumber(em or 0)

        if not sh or not eh or sh < 0 or sh > 23 or eh < 0 or eh > 23 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Labo', message = "Ce format n'est pas valide. Utilisez HH:MM." })
            return
        end

        table.insert(laboData.attackSlots, {
            startHour = sh, startMin = sm,
            endHour = eh, endMin = em
        })
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Créneau ajouté." })
        StaffMenu.builderLaboAttackSlots.refresh()
    end)
end)

local function BuildHarvestCreateMenu(menuRef)
    menuRef.ClearItems()

    menuRef.Separator("INFORMATIONS DU SPOT")

    menuRef.Button(":tag: NOM DU SPOT", "Identifiant interne du spot", harvestData.name or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom du spot (ex: Table de Meth)", harvestData.name or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            harvestData.name = input
            menuRef.refresh()
        end
    end)

    menuRef.Button(":edit: LABEL", "Texte affiché aux joueurs (optionnel)", harvestData.label or "Auto (nom de l'item)", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Label affiché (vide = nom de l'item)", harvestData.label or "", 100)
        if input and input ~= "KBD_CANCEL" then
            harvestData.label = input ~= "" and input or nil
            menuRef.refresh()
        end
    end)

    menuRef.Button(":palette: MODÈLE DU PROP", "Objet 3D affiché (optionnel)", harvestData.propModel or "Aucun", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Modele du prop (ex: prop_weed_01)", harvestData.propModel or "", 100)
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
            menuRef.refresh()
        end
    end)

    menuRef.Button(":pin: POSITION", harvestData.propModel and "Place le prop devant toi" or "Place le spot à ta position", FormatCoords(harvestData.coords), "chevron", false, function()
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        if harvestData.propModel then
            local defaultPos = GetDefaultPropPosition()
            harvestData.coords = defaultPos.coords
            harvestData.markerCoords = defaultPos.markerCoords
            SpawnPreviewProp("harvest", harvestData.propModel, harvestData.coords)
        else
            harvestData.coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
            harvestData.markerCoords = nil
        end
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Position définie." })
        menuRef.refresh()
    end)

    menuRef.Separator("ITEM & QUANTITES")

    menuRef.Button(":flask: ITEM PRODUIT", "Item donné après récolte", harvestData.itemOutput and GetItemLabel(harvestData.itemOutput) or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de l'item (ex: meth_raw)", harvestData.itemOutput or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            harvestData.itemOutput = input
            menuRef.refresh()
        end
    end)

    menuRef.Slider(":chart: QUANTITÉ MIN", harvestData.minQuantity, 1, 50, 1, "Minimum reçu", false, function(value)
        harvestData.minQuantity = value
    end)

    menuRef.Slider(":chart: QUANTITÉ MAX", harvestData.maxQuantity, 1, 50, 1, "Maximum reçu", false, function(value)
        harvestData.maxQuantity = value
    end)

    menuRef.Separator("TEMPS & MECANIQUE")

    menuRef.Slider(":clock: DURÉE RÉCOLTE (s)", math.floor(harvestData.harvestTime / 1000), 1, 60, 1, "Temps en secondes", false, function(value)
        harvestData.harvestTime = value * 1000
    end)

    menuRef.Slider(":dot-grey: RAYON", math.floor(harvestData.radius * 10), 5, 100, 5, "Rayon d'interaction (x10)", false, function(value)
        harvestData.radius = value / 10
    end)

    menuRef.Slider(":users: MAX JOUEURS", harvestData.maxHarvesters, 1, 10, 1, "Joueurs simultanés", false, function(value)
        harvestData.maxHarvesters = value
    end)

    menuRef.Separator("ANIMATION")

    local animLabels = { "Prédéfinie", "Custom" }
    local animIndex = harvestData.animationType == "custom" and 2 or 1

    menuRef.List(":mask: TYPE ANIMATION", "Prédéfinies ou custom", false, animLabels, animIndex, function(index)
        harvestData.animationType = index == 2 and "custom" or "predefined"
      menuRef.refresh()
    end)

    if harvestData.animationType == "predefined" then
        menuRef.Button(":mask: PRESET", "Animation prédéfinie", GetPresetLabel(harvestData.animationPreset), "chevron", false, function()
            if not cachedPresets then
                cachedPresets = TriggerServerCallback("laboBuilder:getPresetAnimations")
            end
            local options = {}
            for _, p in ipairs(cachedPresets or {}) do
                table.insert(options, { label = p.label, value = p.id })
            end
            local choice = VFW.Nui.ChoiceInput("Animation", "Choisir un preset", options)
            if choice and choice ~= "KBD_CANCEL" then
                harvestData.animationPreset = choice
                for _, p in ipairs(cachedPresets or {}) do
                    if p.id == choice then
                        harvestData.animationDict = p.dict
                        harvestData.animationName = p.anim
                        break
                    end
                end
                menuRef.refresh()
            end
        end)
    else
        menuRef.Button(":document: DICT", "Animation dictionary", harvestData.animationDict or "Non défini", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Animation dict", harvestData.animationDict or "", 100)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                harvestData.animationDict = input
                menuRef.refresh()
            end
        end)

        menuRef.Button(":film: ANIM NAME", "Nom de l'animation", harvestData.animationName or "Non défini", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Animation name", harvestData.animationName or "", 100)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                harvestData.animationName = input
                menuRef.refresh()
            end
        end)
    end

    if harvestData.isUpdate then
        menuRef.Separator("DANGER")
        menuRef.Button(":trash: SUPPRIMER CE POINT", nil, nil, "trash", false, function()
            local choice = VFW.Nui.ChoiceInput("Confirmer", "Supprimer le point " .. (harvestData.name or "?") .. " ?", {{ label = "Oui, supprimer", value = "yes" }, { label = "Annuler", value = "no" }})
            if choice == "yes" then
                local callbackName = harvestData.templateId and "laboBuilder:deleteTemplateHarvestPoint" or "laboBuilder:deleteHarvestPoint"
              local result = TriggerServerCallback(callbackName, harvestData.id)
                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Point de récolte supprimé." })
                    DeletePreviewProp("harvest")
                    local savedTemplateId = harvestData.templateId
                    local savedLaboId = harvestData.laboId
                    ResetHarvestData()
                    harvestData.templateId = savedTemplateId
                    harvestData.laboId = savedLaboId
                    Citizen.SetTimeout(50, function()
                        menuRef.close()
                    end)
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Labo', message = (result and result.error or "Erreur") .. "." })
                end
            end
        end)
    end

    menuRef.Separator("VALIDATION")

    local isValid = harvestData.name and harvestData.coords and harvestData.itemOutput
    local btnLabel = harvestData.isUpdate and ":save: SAUVEGARDER LES MODIFICATIONS" or ":check: CRÉER LE SPOT"

  menuRef.Button(btnLabel, not isValid and "Remplis nom, position et item" or nil, nil, "check", false, function()
        if not isValid then
            VFW.ShowNotification({ type = "ROUGE", content = "Remplis nom, position et item." })
            return
        end
        local sendData = {
            name = harvestData.name,
            label = harvestData.label,
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
            blipEnabled = harvestData.blipEnabled,
            blipSprite = harvestData.blipSprite,
            blipColor = harvestData.blipColor,
            blipScale = harvestData.blipScale,
            blipLabel = harvestData.blipLabel
        }

        local result
        if harvestData.isUpdate then
            local callbackName = harvestData.templateId and "laboBuilder:updateTemplateHarvestPoint" or "laboBuilder:updateHarvestPoint"
          result = TriggerServerCallback(callbackName, harvestData.id, sendData)
        else
            if harvestData.templateId then
                result = TriggerServerCallback("laboBuilder:createTemplateHarvestPoint", harvestData.templateId, sendData)
            else
                result = TriggerServerCallback("laboBuilder:createHarvestPoint", harvestData.laboId, sendData)
            end
        end

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = harvestData.isUpdate and "Spot mis à jour." or "Spot créé." })
            DeletePreviewProp("harvest")
            local savedTemplateId = harvestData.templateId
            local savedLaboId = harvestData.laboId
            ResetHarvestData()
            harvestData.templateId = savedTemplateId
            harvestData.laboId = savedLaboId
            Citizen.SetTimeout(50, function()
                menuRef.close()
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Labo', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end

local function BuildHarvestListMenu(menuRef, createMenuRef)
    menuRef.ClearItems()

    local parentId = harvestData.templateId or harvestData.laboId or laboData.id
    if not parentId then return end

    local callbackName = harvestData.templateId and "laboBuilder:getTemplateHarvestPoints" or "laboBuilder:getHarvestPoints"
  local points = TriggerServerCallback(callbackName, parentId) or {}

    menuRef.Button(":plus: CRÉER UN POINT", "Ajouter un spot de récolte", nil, "chevron", false, function()
        local savedTemplateId = harvestData.templateId
        local savedLaboId = harvestData.laboId
        ResetHarvestData()
        harvestData.templateId = savedTemplateId
        harvestData.laboId = savedLaboId
    end, createMenuRef)

    menuRef.Separator("POINTS EXISTANTS (" .. #points .. ")")

    if #points == 0 then
        menuRef.Button("Aucun point de récolte", nil, nil, nil, false, function() end)
    else
        for _, point in ipairs(points) do
            menuRef.Button(
                point.name,
                "Item: " .. GetItemLabel(point.item_output) .. " | x" .. point.min_quantity .. "-" .. point.max_quantity,
                "#" .. point.id,
                "chevron", false,
                function()
                    harvestData.id = point.id
                    harvestData.name = point.name
                    harvestData.label = point.label
                    harvestData.propModel = point.prop_model
                    harvestData.coords = point.coords_x and vector3(point.coords_x, point.coords_y, point.coords_z) or nil
                    harvestData.markerCoords = point.marker_x and vector3(point.marker_x, point.marker_y, point.marker_z) or nil
                    harvestData.itemOutput = point.item_output
                    harvestData.minQuantity = point.min_quantity or 1
                    harvestData.maxQuantity = point.max_quantity or 3
                    harvestData.harvestTime = point.harvest_time or 3000
                    harvestData.cooldown = point.cooldown or 100
                    harvestData.radius = point.radius or 2.0
                    harvestData.maxHarvesters = point.max_harvesters or 1
                    harvestData.animationType = point.animation_type or "predefined"
                  harvestData.animationPreset = point.animation_preset
                    harvestData.animationDict = point.animation_dict
                    harvestData.animationName = point.animation_name
                    harvestData.animationProp = point.animation_prop
                    harvestData.blipEnabled = point.blip_enabled or false
                    harvestData.blipSprite = point.blip_sprite or 1
                    harvestData.blipColor = point.blip_color or 1
                    harvestData.blipScale = point.blip_scale or 0.8
                    harvestData.blipLabel = point.blip_label
                    harvestData.isUpdate = true
                end,
                createMenuRef
            )
        end
    end
end

local function BuildTransformCreateMenu(menuRef)
    menuRef.ClearItems()

    menuRef.Separator("INFORMATIONS DU SPOT")

    menuRef.Button(":tag: NOM DU SPOT", "Identifiant interne du spot", transformData.name or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom du spot (ex: Table de séchage)", transformData.name or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            transformData.name = input
            menuRef.refresh()
        end
    end)

    menuRef.Button(":edit: LABEL", "Texte affiché aux joueurs (optionnel)", transformData.label or "Auto (nom de l'item)", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Label affiché (vide = nom de l'item)", transformData.label or "", 100)
        if input and input ~= "KBD_CANCEL" then
            transformData.label = input ~= "" and input or nil
            menuRef.refresh()
        end
    end)

    menuRef.Button(":palette: MODÈLE DU PROP", "Objet 3D affiché (optionnel)", transformData.propModel or "Aucun", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Modele du prop", transformData.propModel or "", 100)
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
            menuRef.refresh()
        end
    end)

    menuRef.Button(":pin: POSITION", "Place le spot à ta position", FormatCoords(transformData.coords), "chevron", false, function()
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        if transformData.propModel then
            local defaultPos = GetDefaultPropPosition()
            transformData.coords = defaultPos.coords
            transformData.markerCoords = defaultPos.markerCoords
            SpawnPreviewProp("transform", transformData.propModel, transformData.coords)
        else
            transformData.coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
            transformData.markerCoords = nil
        end
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Position définie." })
        menuRef.refresh()
    end)

    menuRef.Separator("ITEMS REQUIS (" .. #transformData.inputs .. ")")

    if #transformData.inputs == 0 then
        menuRef.Button("Aucun composant", "Ajoute des items requis ci-dessous", nil, nil, false, function() end)
    else
        for i, inp in ipairs(transformData.inputs) do
            menuRef.Button(
                GetItemLabel(inp.name),
                "Cliquer pour retirer",
                "x" .. inp.quantity,
                "trash", false,
                function()
                    table.remove(transformData.inputs, i)
                    menuRef.refresh()
                end
            )
        end
    end

    menuRef.Button(":plus: AJOUTER UN COMPOSANT", "Item consommé pour la transformation", nil, "chevron", false, function()
        local itemName = VFW.Nui.KeyboardInput(true, "Nom de l'item requis (ex: meth_raw)", "", 50)
        if not itemName or itemName == "" or itemName == "KBD_CANCEL" then return end

        local amountStr = VFW.Nui.KeyboardInput(true, "Quantité nécessaire", "1", 5)
        local amount = tonumber(amountStr) or 1

        table.insert(transformData.inputs, { name = itemName, quantity = amount })
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Composant ajouté: " .. itemName .. "." })
        menuRef.refresh()
    end)

    menuRef.Separator("PRODUIT FINAL")

    menuRef.Button(":flask: ITEM PRODUIT", "Item donné après transformation", transformData.outputItem and GetItemLabel(transformData.outputItem) or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom de l'item produit (ex: meth_pure)", transformData.outputItem or "", 50)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            transformData.outputItem = input
            menuRef.refresh()
        end
    end)

    menuRef.Slider(":chart: QUANTITÉ PRODUITE", transformData.outputQuantity, 1, 50, 1, "Nombre d'items produits", false, function(value)
        transformData.outputQuantity = value
    end)

    menuRef.Separator("TEMPS & ANIMATION")

    menuRef.Slider(":clock: DURÉE TRANSFO (s)", math.floor(transformData.transformTime / 1000), 1, 60, 1, "Temps en secondes", false, function(value)
        transformData.transformTime = value * 1000
    end)

    local animLabels = { "Prédéfinie", "Custom" }
    local animIndex = transformData.animationType == "custom" and 2 or 1

    menuRef.List(":mask: TYPE ANIMATION", "Prédéfinies ou custom", false, animLabels, animIndex, function(index)
        transformData.animationType = index == 2 and "custom" or "predefined"
      menuRef.refresh()
    end)

    if transformData.animationType == "predefined" then
        menuRef.Button(":mask: PRESET", "Animation prédéfinie", GetPresetLabel(transformData.animationPreset), "chevron", false, function()
            if not cachedPresets then
                cachedPresets = TriggerServerCallback("laboBuilder:getPresetAnimations")
            end
            local options = {}
            for _, p in ipairs(cachedPresets or {}) do
                table.insert(options, { label = p.label, value = p.id })
            end
            local choice = VFW.Nui.ChoiceInput("Animation", "Choisir un preset", options)
            if choice and choice ~= "KBD_CANCEL" then
                transformData.animationPreset = choice
                for _, p in ipairs(cachedPresets or {}) do
                    if p.id == choice then
                        transformData.animationDict = p.dict
                        transformData.animationName = p.anim
                        break
                    end
                end
                menuRef.refresh()
            end
        end)
    else
        menuRef.Button(":document: DICT", "Animation dictionary", transformData.animationDict or "Non défini", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Animation dict", transformData.animationDict or "", 100)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                transformData.animationDict = input
                menuRef.refresh()
            end
        end)

        menuRef.Button(":film: ANIM NAME", "Nom de l'animation", transformData.animationName or "Non défini", "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Animation name", transformData.animationName or "", 100)
            if input and input ~= "" and input ~= "KBD_CANCEL" then
                transformData.animationName = input
                menuRef.refresh()
            end
        end)
    end

    if transformData.isUpdate then
        menuRef.Separator("DANGER")
        menuRef.Button(":trash: SUPPRIMER CE POINT", nil, nil, "trash", false, function()
            local choice = VFW.Nui.ChoiceInput("Confirmer", "Supprimer le point " .. (transformData.name or "?") .. " ?", {{ label = "Oui, supprimer", value = "yes" }, { label = "Annuler", value = "no" }})
            if choice == "yes" then
                local callbackName = transformData.templateId and "laboBuilder:deleteTemplateTransformPoint" or "laboBuilder:deleteTransformPoint"
              local result = TriggerServerCallback(callbackName, transformData.id)
                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = "Point de transformation supprimé." })
                    DeletePreviewProp("transform")
                    local savedTemplateId = transformData.templateId
                    local savedLaboId = transformData.laboId
                    ResetTransformData()
                    transformData.templateId = savedTemplateId
                    transformData.laboId = savedLaboId
                    Citizen.SetTimeout(50, function()
                        menuRef.close()
                    end)
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Labo', message = (result and result.error or "Erreur") .. "." })
                end
            end
        end)
    end

    menuRef.Separator("VALIDATION")

    local isValid = transformData.name and transformData.coords and #transformData.inputs > 0 and transformData.outputItem
    local btnLabel = transformData.isUpdate and ":save: SAUVEGARDER LES MODIFICATIONS" or ":check: CRÉER LE SPOT"

  menuRef.Button(btnLabel, not isValid and "Remplis nom, position, items requis et produit" or nil, nil, "check", false, function()
        if not isValid then
            VFW.ShowNotification({ type = "ROUGE", content = "Remplis nom, position, items requis et produit." })
            return
        end
        local sendData = {
            name = transformData.name,
            label = transformData.label,
            propModel = transformData.propModel,
            coords = vec3ToTable(transformData.coords),
            rotationZ = GetEntityHeading(PlayerPedId()),
            markerCoords = vec3ToTable(transformData.markerCoords),
            inputs = transformData.inputs,
            outputItem = transformData.outputItem,
            outputQuantity = transformData.outputQuantity,
            transformTime = transformData.transformTime,
            animationType = transformData.animationType,
            animationPreset = transformData.animationPreset,
            animationDict = transformData.animationDict,
            animationName = transformData.animationName,
            animationProp = transformData.animationProp,
            blipEnabled = transformData.blipEnabled,
            blipSprite = transformData.blipSprite,
            blipColor = transformData.blipColor,
            blipScale = transformData.blipScale,
            blipLabel = transformData.blipLabel
        }

        local result
        if transformData.isUpdate then
            local callbackName = transformData.templateId and "laboBuilder:updateTemplateTransformPoint" or "laboBuilder:updateTransformPoint"
          result = TriggerServerCallback(callbackName, transformData.id, sendData)
        else
            if transformData.templateId then
                result = TriggerServerCallback("laboBuilder:createTemplateTransformPoint", transformData.templateId, sendData)
            else
                result = TriggerServerCallback("laboBuilder:createTransformPoint", transformData.laboId, sendData)
            end
        end

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Labo', message = transformData.isUpdate and "Spot mis à jour." or "Spot créé." })
            DeletePreviewProp("transform")
            local savedTemplateId = transformData.templateId
            local savedLaboId = transformData.laboId
            ResetTransformData()
            transformData.templateId = savedTemplateId
            transformData.laboId = savedLaboId
            Citizen.SetTimeout(50, function()
                menuRef.close()
            end)
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Labo', message = (result and result.error or "Erreur") .. "." })
        end
    end)
end

local function BuildTransformListMenu(menuRef, createMenuRef)
    menuRef.ClearItems()

    local parentId = transformData.templateId or transformData.laboId or laboData.id
    if not parentId then return end

    local callbackName = transformData.templateId and "laboBuilder:getTemplateTransformPoints" or "laboBuilder:getTransformPoints"
  local points = TriggerServerCallback(callbackName, parentId) or {}

    menuRef.Button(":plus: CRÉER UN POINT", "Ajouter un spot de transformation", nil, "chevron", false, function()
        local savedTemplateId = transformData.templateId
        local savedLaboId = transformData.laboId
        ResetTransformData()
        transformData.templateId = savedTemplateId
        transformData.laboId = savedLaboId
    end, createMenuRef)

    menuRef.Separator("POINTS EXISTANTS (" .. #points .. ")")

    if #points == 0 then
        menuRef.Button("Aucun point de transformation", nil, nil, nil, false, function() end)
    else
        for _, point in ipairs(points) do
            local inputsLabel = #(point.inputs or {}) .. (#(point.inputs or {}) > 1 and " inputs" or " input")
          menuRef.Button(
                point.name,
                inputsLabel .. " -> " .. GetItemLabel(point.output_item) .. " x" .. point.output_quantity,
                "#" .. point.id,
                "chevron", false,
                function()
                    transformData.id = point.id
                    transformData.name = point.name
                    transformData.label = point.label
                    transformData.propModel = point.prop_model
                    transformData.coords = point.coords_x and vector3(point.coords_x, point.coords_y, point.coords_z) or nil
                    transformData.markerCoords = point.marker_x and vector3(point.marker_x, point.marker_y, point.marker_z) or nil
                    transformData.inputs = point.inputs or {}
                    transformData.outputItem = point.output_item
                    transformData.outputQuantity = point.output_quantity or 1
                    transformData.transformTime = point.transform_time or 3000
                    transformData.animationType = point.animation_type or "predefined"
                  transformData.animationPreset = point.animation_preset
                    transformData.animationDict = point.animation_dict
                    transformData.animationName = point.animation_name
                    transformData.animationProp = point.animation_prop
                    transformData.blipEnabled = point.blip_enabled or false
                    transformData.blipSprite = point.blip_sprite or 1
                    transformData.blipColor = point.blip_color or 1
                    transformData.blipScale = point.blip_scale or 0.8
                    transformData.blipLabel = point.blip_label
                    transformData.isUpdate = true
                end,
                createMenuRef
            )
        end
    end
end

StaffMenu.builderLaboHarvestCreate.OnOpen(function()
    BuildHarvestCreateMenu(StaffMenu.builderLaboHarvestCreate)
end)

StaffMenu.builderLaboHarvestList.OnOpen(function()
    BuildHarvestListMenu(StaffMenu.builderLaboHarvestList, StaffMenu.builderLaboHarvestCreate)
end)

StaffMenu.builderLaboTransformCreate.OnOpen(function()
    BuildTransformCreateMenu(StaffMenu.builderLaboTransformCreate)
end)

StaffMenu.builderLaboTransformList.OnOpen(function()
    BuildTransformListMenu(StaffMenu.builderLaboTransformList, StaffMenu.builderLaboTransformCreate)
end)

StaffMenu.builderLaboHarvestList.OnClose(function()
    DeletePreviewProp("harvest")
end)

StaffMenu.builderLaboTransformList.OnClose(function()
    DeletePreviewProp("transform")
end)

StaffMenu.builderLaboHarvestCreate.OnClose(function()
    DeletePreviewProp("harvest")
end)

StaffMenu.builderLaboTransformCreate.OnClose(function()
    DeletePreviewProp("transform")
end)

StaffMenu.builderLaboTemplateList.OnOpen(function()
    StaffMenu.builderLaboTemplateList.ClearItems()
    cachedTemplates = TriggerServerCallback("laboBuilder:getTemplates") or {}

    StaffMenu.builderLaboTemplateList.Separator("TEMPLATES (" .. #cachedTemplates .. ")")

    if #cachedTemplates == 0 then
        StaffMenu.builderLaboTemplateList.Button("Aucune template", nil, nil, nil, false, function() end)
    else
        for _, t in ipairs(cachedTemplates) do
            StaffMenu.builderLaboTemplateList.Button(
                t.label,
                t.name,
                "#" .. t.id,
                "chevron", false,
                function()
                    templateEditData.id = t.id
                    templateEditData.name = t.name
                    templateEditData.label = t.label
                    if t.interior_x then
                        templateEditData.interiorCoords = { x = t.interior_x, y = t.interior_y, z = t.interior_z, heading = t.interior_heading }
                    end
                    if t.chest_x then
                        templateEditData.chestCoords = { x = t.chest_x, y = t.chest_y, z = t.chest_z }
                    end
                    if t.management_x then
                        templateEditData.managementCoords = { x = t.management_x, y = t.management_y, z = t.management_z }
                    end
                    templateEditData.blipSprite = t.blip_sprite or 499
                    templateEditData.blipColor = t.blip_color or 1
                    templateEditData.blipScale = t.blip_scale or 0.8
                end,
                StaffMenu.builderLaboTemplateManage
            )
        end
    end
end)

StaffMenu.builderLaboTemplateManage.OnOpen(function()
    StaffMenu.builderLaboTemplateManage.ClearItems()

    if not templateEditData.id then return end

    StaffMenu.builderLaboTemplateManage.Separator("TEMPLATE: " .. (templateEditData.label or "?"))

    StaffMenu.builderLaboTemplateManage.Button(":tag: NOM", "Identifiant unique", templateEditData.name or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom technique", templateEditData.name or "", 50)
        if input and input ~= "" then
            templateEditData.name = input
            StaffMenu.builderLaboTemplateManage.refresh()
        end
    end)

    StaffMenu.builderLaboTemplateManage.Button(":edit: LABEL", "Nom affiché", templateEditData.label or "Non défini", "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Label affiché", templateEditData.label or "", 50)
        if input and input ~= "" then
            templateEditData.label = input
            StaffMenu.builderLaboTemplateManage.refresh()
        end
    end)

    StaffMenu.builderLaboTemplateManage.Separator("POSITIONS INTÉRIEURES")

    StaffMenu.builderLaboTemplateManage.Button(":pin: SPAWN INTÉRIEUR", "Spawn à l'intérieur du labo", FormatCoords(templateEditData.interiorCoords), "chevron", false, function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        templateEditData.interiorCoords = { x = coords.x, y = coords.y, z = coords.z, heading = heading }
        VFW.ShowNotification({ type = "VERT", content = "Position intérieur définie." })
        StaffMenu.builderLaboTemplateManage.refresh()
    end)

    StaffMenu.builderLaboTemplateManage.Button(":box: COFFRE", "Position du coffre", FormatCoords(templateEditData.chestCoords), "chevron", false, function()
        local coords = GetEntityCoords(PlayerPedId())
        templateEditData.chestCoords = { x = coords.x, y = coords.y, z = coords.z }
        VFW.ShowNotification({ type = "VERT", content = "Position coffre définie." })
        StaffMenu.builderLaboTemplateManage.refresh()
    end)

    StaffMenu.builderLaboTemplateManage.Button(":settings: GESTION", "Position du menu gestion", FormatCoords(templateEditData.managementCoords), "chevron", false, function()
        local coords = GetEntityCoords(PlayerPedId())
        templateEditData.managementCoords = { x = coords.x, y = coords.y, z = coords.z }
        VFW.ShowNotification({ type = "VERT", content = "Position gestion définie." })
        StaffMenu.builderLaboTemplateManage.refresh()
    end)

    StaffMenu.builderLaboTemplateManage.Separator("POINTS")

    StaffMenu.builderLaboTemplateManage.Button(":leaf: POINTS DE RÉCOLTE", "Gérer les spots de récolte", nil, "chevron", false, function()
        harvestData.templateId = templateEditData.id
        harvestData.laboId = nil
    end, StaffMenu.builderLaboTemplateHarvestList)

    StaffMenu.builderLaboTemplateManage.Button(":flask: POINTS DE TRANSFORMATION", "Gérer les spots de transfo", nil, "chevron", false, function()
        transformData.templateId = templateEditData.id
        transformData.laboId = nil
    end, StaffMenu.builderLaboTemplateTransformList)

    StaffMenu.builderLaboTemplateManage.Separator("")

    StaffMenu.builderLaboTemplateManage.Button(":save: SAUVEGARDER", "Enregistrer les modifications", nil, "check", false, function()
        local result = TriggerServerCallback("laboBuilder:updateTemplate", templateEditData.id, {
            name = templateEditData.name,
            label = templateEditData.label,
            interiorCoords = templateEditData.interiorCoords,
            chestCoords = templateEditData.chestCoords,
            managementCoords = templateEditData.managementCoords,
            blipSprite = templateEditData.blipSprite,
            blipColor = templateEditData.blipColor,
            blipScale = templateEditData.blipScale
        })
        if result and result.success then
            VFW.ShowNotification({ type = "VERT", content = "Template mise à jour." })
        else
            VFW.ShowNotification({ type = "ROUGE", content = result and result.error or "Erreur" })
        end
    end)

    StaffMenu.builderLaboTemplateManage.Button(":home: SE TÉLÉPORTER", "Se téléporter à l'intérieur", nil, "chevron", false, function()
        if templateEditData.interiorCoords then
            local ped = PlayerPedId()
            DoScreenFadeOut(500)
            Wait(500)
            SetEntityCoords(ped, templateEditData.interiorCoords.x, templateEditData.interiorCoords.y, templateEditData.interiorCoords.z, false, false, false, false)
            SetEntityHeading(ped, templateEditData.interiorCoords.heading or 0)
            Wait(200)
            DoScreenFadeIn(500)
            VFW.ShowNotification({ type = "VERT", content = "Téléporté à l'intérieur." })
        else
            VFW.ShowNotification({ type = "ROUGE", content = "Position intérieur non définie." })
        end
    end)
end)

StaffMenu.builderLaboTemplateHarvestList.OnOpen(function()
    harvestData.templateId = templateEditData.id
    harvestData.laboId = nil
    BuildHarvestListMenu(StaffMenu.builderLaboTemplateHarvestList, StaffMenu.builderLaboTemplateHarvestCreate)
end)

StaffMenu.builderLaboTemplateHarvestCreate.OnOpen(function()
    BuildHarvestCreateMenu(StaffMenu.builderLaboTemplateHarvestCreate)
end)

StaffMenu.builderLaboTemplateTransformList.OnOpen(function()
    transformData.templateId = templateEditData.id
    transformData.laboId = nil
    BuildTransformListMenu(StaffMenu.builderLaboTemplateTransformList, StaffMenu.builderLaboTemplateTransformCreate)
end)

StaffMenu.builderLaboTemplateTransformCreate.OnOpen(function()
    BuildTransformCreateMenu(StaffMenu.builderLaboTemplateTransformCreate)
end)

StaffMenu.builderLaboTemplateHarvestList.OnClose(function()
    DeletePreviewProp("harvest")
end)

StaffMenu.builderLaboTemplateHarvestCreate.OnClose(function()
    DeletePreviewProp("harvest")
end)

StaffMenu.builderLaboTemplateTransformList.OnClose(function()
    DeletePreviewProp("transform")
end)

StaffMenu.builderLaboTemplateTransformCreate.OnClose(function()
    DeletePreviewProp("transform")
end)

