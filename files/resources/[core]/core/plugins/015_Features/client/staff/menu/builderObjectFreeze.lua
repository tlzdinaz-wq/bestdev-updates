---@meta _
---@diagnostic disable: duplicate-doc-field

---
--- Builder Object Freeze
--- Allows staff to freeze props by model (all instances) or by position (specific entity)
---

-- Local state
local ObjectFreezeList = {} -- synced from server: array of { id, type, model_hash, archetype_name, position }
local prevFrozenModels = {} -- [modelHash] = true (previous freeze state for unfreeze)
local prevFrozenPositions = {} -- array of { model_hash, x, y, z }
local selectedEntity = nil
local selectedModel = nil
local selectedArchetype = ""
local selectedPosition = nil

-- ── Raycast helpers (same pattern as builderChairs.lua) ──

local function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    return vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = vector3(
        cameraCoord.x + direction.x * distance,
        cameraCoord.y + direction.y * distance,
        cameraCoord.z + direction.z * distance
    )
    local _, hit, coords, _, entity = GetShapeTestResult(StartShapeTestRay(
        cameraCoord.x, cameraCoord.y, cameraCoord.z,
        destination.x, destination.y, destination.z,
        16, PlayerPedId(), 0 -- 16 = objects only
    ))
    return hit, coords, entity
end

local function SelectObjectVisually()
    local selectionActive = true
    local currentEntity = nil
    local result = nil

    CreateThread(function()
        while selectionActive do
            Wait(0)
            VFW.ShowHelpNotification("~INPUT_CONTEXT~ Sélectionner l'objet ~n~~INPUT_FRONTEND_RRIGHT~ Annuler")

            if currentEntity and currentEntity ~= result then SetEntityDrawOutline(currentEntity, false) end

            local hit, coords, entity = RayCastGamePlayCamera(20.0)

            -- Si pas d'entité directe, chercher l'objet le plus proche du point d'impact
            if (not DoesEntityExist(entity) or entity == 0) and hit then
                local objects = GetGamePool('CObject')
                local closestDist = 3.0
                local closestObj = nil

                for i = 1, #objects do
                    local obj = objects[i]
                    local objCoords = GetEntityCoords(obj)
                    local dist = #(coords - objCoords)
                    if dist < closestDist then
                        closestDist = dist
                        closestObj = obj
                    end
                end

                if closestObj then
                    entity = closestObj
                end
            end

            -- Forcer la recherche par GetClosestObjectOfType (objets map statiques)
            if (not DoesEntityExist(entity) or entity == 0) and hit then
                local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, 0, false, false, false)
                if DoesEntityExist(obj) then
                    entity = obj
                end
            end

            -- Visualisation du point de recherche
            if hit then
                DrawMarker(28, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0, 0.1, 0.1, 0.1, 255, 0, 0, 150, false, false, 2, nil, nil, false)
            end

            if DoesEntityExist(entity) then
                currentEntity = entity
                SetEntityDrawOutline(currentEntity, true)
                local entCoords = GetEntityCoords(currentEntity)
                DrawMarker(0, entCoords.x, entCoords.y, entCoords.z + 1.2, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 150, 255, 200, true, true, 2, nil, nil, false)

                if VFW.Interact.JustPressed(0, 51) then -- E
                    result = entity
                    selectionActive = false
                end
            end

            if IsControlJustPressed(0, 194) then -- ESC
                if currentEntity then SetEntityDrawOutline(currentEntity, false) end
                selectionActive = false
            end
        end

        if currentEntity and not result then SetEntityDrawOutline(currentEntity, false) end
        if result then SetEntityDrawOutline(result, false) end
    end)

    while selectionActive do
        Wait(100)
    end

    return result
end

-- Cache des lookups freeze (reconstruit au sync)
local freezeModelSet = {}    -- [modelHash] = true
local freezePositionSet = {} -- [modelHash] = { {x,y,z}, ... }
local freezeAlreadyFrozen = {} -- [entityHandle] = true (évite les appels natifs répétés)

local function RebuildFreezeCache()
    freezeModelSet = {}
    freezePositionSet = {}
    freezeAlreadyFrozen = {}
    for _, entry in ipairs(ObjectFreezeList) do
        local hash = tonumber(entry.model_hash) or entry.model_hash
        if entry.type == "model" then
            freezeModelSet[hash] = true
        elseif entry.type == "position" and entry.position then
            if not freezePositionSet[hash] then freezePositionSet[hash] = {} end
            table.insert(freezePositionSet[hash], vector3(entry.position.x, entry.position.y, entry.position.z))
        end
    end
end

-- ── Sync from server ──

RegisterNetEvent('objectFreeze:sync')
AddEventHandler('objectFreeze:sync', function(data)
    ObjectFreezeList = data or {}
    RebuildFreezeCache()
    ApplyObjectFreezes()
end)

--- Check if an object matches a freeze config
local function ShouldBeFrozen(model, objCoords, frozenModels, frozenPositions)
    if frozenModels[model] then return true end
    for _, pos in ipairs(frozenPositions) do
        if model == pos.model_hash then
            local dist = #(objCoords - vector3(pos.x, pos.y, pos.z))
            if dist < 1.0 then return true end
        end
    end
    return false
end

--- Apply freezes to all matching props in the world (and unfreeze removed ones)
function ApplyObjectFreezes()
    -- Build NEW lookup tables
    local newFrozenModels = {}
    local newFrozenPositions = {}

    for _, entry in ipairs(ObjectFreezeList) do
        local hash = tonumber(entry.model_hash) or entry.model_hash
        if entry.type == "model" then
            newFrozenModels[hash] = true
        elseif entry.type == "position" and entry.position then
            table.insert(newFrozenPositions, {
                model_hash = hash,
                x = entry.position.x,
                y = entry.position.y,
                z = entry.position.z,
            })
        end
    end

    local objects = GetGamePool('CObject')
    for i = 1, #objects do
        local obj = objects[i]
        local model = GetEntityModel(obj)
        local objCoords = GetEntityCoords(obj)

        local shouldFreeze = ShouldBeFrozen(model, objCoords, newFrozenModels, newFrozenPositions)
        local wasFrozen = ShouldBeFrozen(model, objCoords, prevFrozenModels, prevFrozenPositions)

        if shouldFreeze then
            FreezeEntityPosition(obj, true)
        elseif wasFrozen and not shouldFreeze then
            FreezeEntityPosition(obj, false)
        end
    end

    -- Save current state as previous for next sync
    prevFrozenModels = newFrozenModels
    prevFrozenPositions = newFrozenPositions
end

-- Request initial sync on resource start
CreateThread(function()
    Wait(3000)
    local data = TriggerServerCallback('objectFreeze:getAll')
    if data then
        ObjectFreezeList = data
        RebuildFreezeCache()
        ApplyObjectFreezes()
    end
end)

-- Thread pour ré-appliquer les freezes sur les props qui reviennent dans le pool
CreateThread(function()
    while true do
        Wait(5000)
        if #ObjectFreezeList > 0 then
            local objects = GetGamePool('CObject')
            for i = 1, #objects do
                local obj = objects[i]
                if not freezeAlreadyFrozen[obj] then
                    local model = GetEntityModel(obj)
                    -- Skip rapide : le modèle n'est dans aucune config
                    if freezeModelSet[model] then
                        FreezeEntityPosition(obj, true)
                        freezeAlreadyFrozen[obj] = true
                    elseif freezePositionSet[model] then
                        local objCoords = GetEntityCoords(obj)
                        for _, pos in ipairs(freezePositionSet[model]) do
                            if #(objCoords - pos) < 1.0 then
                                FreezeEntityPosition(obj, true)
                                freezeAlreadyFrozen[obj] = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ── Helper: get type label ──

local function GetTypeLabel(t)
    if t == "model" then return "Modèle (tous)" end
    if t == "position" then return "Position (unique)" end
    return t
end

-- ── Main menu: BUILDER OBJECT FREEZE ──

StaffMenu.builderObjectFreeze.OnOpen(function()
    StaffMenu.builderObjectFreeze.ClearItems()
    local Button = StaffMenu.builderObjectFreeze.Button
    local Separator = StaffMenu.builderObjectFreeze.Separator

    Separator("FREEZE OBJETS")

    -- Select an object via raycast
    Button("SÉLECTIONNER UN OBJET", "Viser un objet et appuyer sur E", nil, "chevron", false, function()
        StaffMenu.builderObjectFreeze.close()
        Wait(200)

        local entity = SelectObjectVisually()

        if entity and DoesEntityExist(entity) then
            selectedEntity = entity
            selectedModel = GetEntityModel(entity)
            selectedArchetype = GetEntityArchetypeName(entity) or ""
          selectedPosition = GetEntityCoords(entity)

            Wait(200)
            StaffMenu.builderObjectFreeze.open()
        else
            selectedEntity = nil
            selectedModel = nil
            selectedArchetype = ""
          selectedPosition = nil
            Wait(200)
            StaffMenu.builderObjectFreeze.open()
        end
    end)

    -- Show selected entity info
    if selectedEntity and DoesEntityExist(selectedEntity) and selectedModel then
        Separator("SÉLECTION ACTIVE")
        Button(
            "Model: " .. tostring(selectedModel),
            selectedArchetype ~= "" and selectedArchetype or "Archetype inconnu",
            nil, "info", true, function() end
        )

        local pos = selectedPosition
        if pos then
            Button(
                "Pos: " .. string.format("%.1f, %.1f, %.1f", pos.x, pos.y, pos.z),
                "Position de l'objet sélectionné",
                nil, "info", true, function() end
            )
        end

        Separator("ACTIONS")

        -- Freeze this specific prop at this position
        Button(":sparkles: FREEZE CE PROPS (position)", "Figer uniquement cet objet à cette position", nil, "chevron", false, function()
            if not selectedModel or not selectedPosition then return end

            local result = TriggerServerCallback('objectFreeze:add', {
                type = "position",
                model_hash = selectedModel,
                archetype_name = selectedArchetype,
                position = { x = selectedPosition.x, y = selectedPosition.y, z = selectedPosition.z }
            })

            if result and result.success then
                VFW.ShowNotification({ type = 'VERT', content = "Objet freeze à cette position" })
                selectedEntity = nil
                selectedModel = nil
                selectedArchetype = ""
              selectedPosition = nil
            else
                VFW.ShowNotification({ type = 'ROUGE', content = "Erreur: " .. (result and result.error or "inconnue") })
            end

            StaffMenu.builderObjectFreeze.refresh()
        end)

        -- Freeze all props of this model
        Button(":sparkles: FREEZE TOUS CE MODÈLE", "Figer tous les objets de ce modèle", nil, "chevron", false, function()
            if not selectedModel then return end

            local result = TriggerServerCallback('objectFreeze:add', {
                type = "model",
                model_hash = selectedModel,
                archetype_name = selectedArchetype
            })

            if result and result.success then
                VFW.ShowNotification({ type = 'VERT', content = "Tous les props de ce modèle sont freeze" })
                selectedEntity = nil
                selectedModel = nil
                selectedArchetype = ""
              selectedPosition = nil
            else
                VFW.ShowNotification({ type = 'ROUGE', content = "Erreur: " .. (result and result.error or "inconnue") })
            end

            StaffMenu.builderObjectFreeze.refresh()
        end)
    end

    -- List existing freeze configurations
    Separator("OBJETS FREEZE (" .. #ObjectFreezeList .. ")")

    if #ObjectFreezeList > 0 then
        for _, entry in ipairs(ObjectFreezeList) do
            local label = entry.archetype_name ~= "" and entry.archetype_name or tostring(entry.model_hash)
            local desc = GetTypeLabel(entry.type)
            if entry.type == "position" and entry.position then
                desc = desc .. string.format(" (%.0f, %.0f, %.0f)", entry.position.x, entry.position.y, entry.position.z)
            end

            Button(":sparkles: " .. label, desc, nil, "trash", false, function()
                local result = TriggerServerCallback('objectFreeze:delete', entry.id)
                if result and result.success then
                    VFW.ShowNotification({ type = 'VERT', content = "Freeze supprimé" })
                else
                    VFW.ShowNotification({ type = 'ROUGE', content = "Erreur: " .. (result and result.error or "inconnue") })
                end
                StaffMenu.builderObjectFreeze.refresh()
            end)
        end
    else
        Button("Aucun objet freeze", "Sélectionnez un objet pour commencer", nil, "info", true, function() end)
    end
end)
