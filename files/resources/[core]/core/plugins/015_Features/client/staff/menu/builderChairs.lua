---@meta _
---@diagnostic disable: duplicate-doc-field

---
--- Builder Chaises (Sitting Configuration)
--- Allows staff to visually configure which animations are available per chair model
--- and manage multiple sit positions (slots) for couches/benches.
---

-- Animation keys matching AnimationTypes in object_context_menu.lua
local ChairAnimKeys = {
    { key = "normale",        label = "Normale" },
    { key = "focus",          label = "Focus" },
    { key = "Pensif",         label = "Pensif" },
    { key = "Brasdecôté",     label = "Bras de côté" },
    { key = "Brascroisés",    label = "Bras croisés" },
    { key = "Regardantenbas", label = "Regardant en bas" },
    -- Lying down animations (for couches)
    { key = "allonge",        label = "S'allonger" },
    { key = "allongecote",    label = "Allonge de cote" },
    { key = "allongesurdos",  label = "Sur le dos" },
    { key = "fetale",         label = "Position foetale" },
}

-- Preview animation data for clone ped (TaskPlayAnim dicts)
local PreviewAnims = {
    ["normale"]        = { "amb@prop_human_seat_chair@male@generic@idle_a", "idle_a" },
    ["focus"]          = { "amb@prop_human_seat_strip_watch@bouncy_guy@base", "base" },
    ["Pensif"]         = { "anim@amb@business@cfid@cfid_desk_no_work_bgen_chair_no_work@", "transition_wakeup_lazyworker" },
    ["Brasdecôté"]     = { "veh@truck@barracks@rds@base", "lean_back_idle" },
    ["Brascroisés"]    = { "anim@scripted@charlie_missions@mission_5@ig2_avi_sitting@", "idle_e" },
    ["Regardantenbas"] = { "anim@amb@business@cfm@cfm_machine_no_work@", "sleep_cycle_v2_operator" },
    -- Lying down
    ["allonge"]        = { "savecouch@", "t_sleep_loop_couch" },
    ["allongecote"]    = { "timetable@tracy@sleep@", "idle_c" },
    ["allongesurdos"]  = { "anim@scripted@submarine@special_peds@pavel@hs4_pavel_ig3_sleep_p1", "base_idle" },
    ["fetale"]         = { "anim@amb@nightclub@lazlow@lo_alone@", "lowalone_base_laz" },
}

-- Local state
local ChairConfigOverrides = {} -- synced from server: [modelHash] = { archetype_name, z_adjust, allowed_anims, sit_position }
local selectedEntity = nil
local selectedModel = nil
local selectedArchetype = ""
local editAllowedAnims = nil -- nil = all allowed, table = restricted set
local editSitPositions = {} -- array of {x, y, z, h} local offsets (multi-slot)
local editFrozen = false

local chairScanActive = false
local scanUnconfiguredChairs = {}

local CHAIR_KEYWORDS = {
    "chair", "bench", "couch", "sofa", "seat", "stool",
    "armchair", "easychair", "offchair", "dinechair",
    "lounger", "sun_loung", "barstool", "bar_stool",
    "wheelchair", "toilet", "campbed", "hobo_seat",
    "deck_chair", "waiting_seat", "busstop",
    "chairarm", "chairstrip", "chairstool",
    "leath_chr", "barbchair",
    "bed", "mattress", "hammock", "sunbed",
}

local scanTracerColors = {
    { r = 255, g = 50, b = 50 },
    { r = 255, g = 150, b = 0 },
    { r = 255, g = 255, b = 0 },
    { r = 0, g = 200, b = 255 },
    { r = 200, g = 0, b = 255 },
}

local TRACER_OFFSETS = {
    { 0.0, 0.0, 0.0 },
    { 0.04, 0.0, 0.0 },
    { -0.04, 0.0, 0.0 },
    { 0.0, 0.04, 0.0 },
    { 0.0, -0.04, 0.0 },
    { 0.0, 0.0, 0.04 },
    { 0.0, 0.0, -0.04 },
    { 0.03, 0.03, 0.0 },
    { -0.03, -0.03, 0.0 },
    { 0.03, -0.03, 0.0 },
    { -0.03, 0.03, 0.0 },
}

local function IsChairKeyword(name)
    local lower = string.lower(name)
    for i = 1, #CHAIR_KEYWORDS do
        if string.find(lower, CHAIR_KEYWORDS[i], 1, true) then
            return true
        end
    end
    return false
end

local function DrawThickTracer(fromCoords, toCoords, color, alpha)
    for i = 1, #TRACER_OFFSETS do
        local o = TRACER_OFFSETS[i]
        DrawLine(
            fromCoords.x + o[1], fromCoords.y + o[2], fromCoords.z + o[3],
            toCoords.x + o[1], toCoords.y + o[2], toCoords.z + o[3],
            color.r, color.g, color.b, alpha
        )
    end
end

local function DrawScan3DText(coords, text)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z + 1.8)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 240)
        SetTextDropshadow(2, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 200)
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(screenX, screenY)

        SetTextScale(0.28, 0.28)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(255, 100, 100, 220)
        SetTextDropshadow(2, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 200)
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("NON CONFIGURE")
        DrawText(screenX, screenY + 0.022)
    end
end

local function ScanNearbyChairs()
    scanUnconfiguredChairs = {}
    local playerCoords = GetEntityCoords(PlayerPedId())
    local objects = GetGamePool('CObject')
    local seen = {}
    local sitTypes = exports['core']:getChairSitTypes()
    local overrides = exports['core']:getChairAnimOverrides()

    for i = 1, #objects do
        local obj = objects[i]
        local objCoords = GetEntityCoords(obj)
        local dist = #(playerCoords - objCoords)

        if dist <= 200.0 then
            local model = GetEntityModel(obj)

            if not seen[model] then
                local name = GetEntityArchetypeName(obj) or ""

              if IsChairKeyword(name) then
                    local inHardcode = sitTypes and sitTypes[model]
                    local inDB = overrides and overrides[model]
                    local inConfig = ChairConfigOverrides[model] ~= nil

                    if not inHardcode and not inDB and not inConfig then
                        seen[model] = true
                        scanUnconfiguredChairs[#scanUnconfiguredChairs + 1] = {
                            entity = obj,
                            model = model,
                            name = name,
                            coords = objCoords,
                        }
                    end
                end
            else
                for j = 1, #scanUnconfiguredChairs do
                    if scanUnconfiguredChairs[j].model == model then
                        local existingDist = #(playerCoords - scanUnconfiguredChairs[j].coords)
                        if dist < existingDist then
                            scanUnconfiguredChairs[j].entity = obj
                            scanUnconfiguredChairs[j].coords = objCoords
                        end
                        break
                    end
                end
            end
        end
    end

    return #scanUnconfiguredChairs
end

local function StartChairScanThread()
    CreateThread(function()
        ScanNearbyChairs()
        local rescanTimer = GetGameTimer()

        while chairScanActive do
            Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local pedHeadCoords = GetPedBoneCoords(PlayerPedId(), 31086, 0.0, 0.0, 0.2)

            if GetGameTimer() - rescanTimer > 1000 then
                rescanTimer = GetGameTimer()
                ScanNearbyChairs()
            end

            for i = 1, #scanUnconfiguredChairs do
                local chair = scanUnconfiguredChairs[i]
                if chair and chair.coords then
                    local dist = #(playerCoords - chair.coords)
                    local color = scanTracerColors[((i - 1) % #scanTracerColors) + 1]
                    local alpha = math.max(50, math.min(200, 200 - math.floor(dist * 2)))

                    DrawThickTracer(pedHeadCoords, chair.coords, color, alpha)

                    DrawMarker(2,
                        chair.coords.x, chair.coords.y, chair.coords.z + 2.0,
                        0, 0, 0, 0, 180.0, 0,
                        0.5, 0.5, 0.5,
                        color.r, color.g, color.b, alpha,
                        true, true, 2, nil, nil, false
                    )

                    DrawMarker(1,
                        chair.coords.x, chair.coords.y, chair.coords.z - 0.5,
                        0, 0, 0, 0, 0, 0,
                        1.5, 1.5, 3.0,
                        color.r, color.g, color.b, math.floor(alpha * 0.3),
                        false, true, 2, nil, nil, false
                    )

                    if dist < 15.0 then
                        DrawScan3DText(chair.coords, chair.name)
                    end
                end
            end

        end
    end)
end

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

local function SelectChairVisually()
    local selectionActive = true
    local currentEntity = nil
    local selectedEntity = nil

    CreateThread(function()
        while selectionActive do
            Wait(0)
            VFW.ShowHelpNotification("~INPUT_CONTEXT~ Sélectionner la chaise ~n~~INPUT_FRONTEND_RRIGHT~ Annuler")

            if currentEntity and currentEntity ~= selectedEntity then SetEntityDrawOutline(currentEntity, false) end

            local hit, coords, entity = RayCastGamePlayCamera(20.0)

            -- 1. Si pas d'entité directe, chercher l'objet script le plus proche du point d'impact
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

            -- 2. Si toujours rien, forcer la recherche par GetClosestObjectOfType (objets map statiques)
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
                DrawMarker(0, entCoords.x, entCoords.y, entCoords.z + 1.2, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 200, true, true, 2, nil, nil, false)

                if VFW.Interact.JustPressed(0, 51) then -- E
                    selectedEntity = entity
                    selectionActive = false
                end
            end

            if IsControlJustPressed(0, 194) then -- ESC
                if currentEntity then SetEntityDrawOutline(currentEntity, false) end
                selectionActive = false
            end
        end

        if currentEntity and not selectedEntity then SetEntityDrawOutline(currentEntity, false) end
        if selectedEntity then SetEntityDrawOutline(selectedEntity, false) end
    end)

    while selectionActive do
        Wait(100)
    end

    return selectedEntity
end

-- ── Sync from server ──

RegisterNetEvent('chairConfig:sync')
AddEventHandler('chairConfig:sync', function(data)
    ChairConfigOverrides = data or {}
    ApplyChairOverrides()
end)

--- Apply overrides to runtime tables via exports
function ApplyChairOverrides()
    -- Build overrides tables for object_context_menu
    local animOverrides = {}
    local sitPositions = {}

    for hash, cfg in pairs(ChairConfigOverrides) do
        -- Force numeric key to match GetEntityModel() return type
        local numHash = tonumber(hash) or hash

        -- Convert string keys ("normale") to joaat hashes (`normale`) for runtime
        local animTable = {}
        if cfg.allowed_anims then
            for k, v in pairs(cfg.allowed_anims) do
                animTable[joaat(k)] = v
            end
        else
            -- nil = all anims allowed, build full table so ChairAnimOverrides[hash] exists
            for _, entry in ipairs(ChairAnimKeys) do
                animTable[joaat(entry.key)] = true
            end
        end
        animOverrides[numHash] = animTable

        -- sit_position is now an array of slots (server normalizes legacy single→array)
        if cfg.sit_position then
            sitPositions[numHash] = cfg.sit_position
        end
    end

    -- Push to object_context_menu via exports
    pcall(exports['core'].applyChairAnimOverrides, exports['core'], animOverrides)
    pcall(exports['core'].applyChairSitPositions, exports['core'], sitPositions)

    -- Apply freeze to all matching props in the world
    local frozenHashes = {}
    for hash, cfg in pairs(ChairConfigOverrides) do
        if cfg.frozen then
            frozenHashes[tonumber(hash) or hash] = true
        end
    end

    if next(frozenHashes) then
        local objects = GetGamePool('CObject')
        for i = 1, #objects do
            local obj = objects[i]
            local model = GetEntityModel(obj)
            if frozenHashes[model] then
                FreezeEntityPosition(obj, true)
            end
        end
    end
end

-- Request initial sync on resource start
CreateThread(function()
    Wait(3000)
    local data = TriggerServerCallback('chairConfig:getAll')
    if data then
        ChairConfigOverrides = data
        ApplyChairOverrides()
    end
end)

-- ── Helper: load edit state from a config or defaults ──

local function LoadEditState(modelHash, archetype)
    selectedModel = modelHash
    selectedArchetype = archetype or ""

  local cfg = ChairConfigOverrides[modelHash]
    if cfg then
        -- Allowed anims
        if cfg.allowed_anims then
            editAllowedAnims = {}
            for k, v in pairs(cfg.allowed_anims) do editAllowedAnims[k] = v end
            -- If all anims are enabled, treat as "all allowed" (nil)
            local allOn = true
            for _, entry in ipairs(ChairAnimKeys) do
                if not editAllowedAnims[entry.key] then
                    allOn = false
                    break
                end
            end
            if allOn then
                editAllowedAnims = nil
            end
        else
            editAllowedAnims = nil
        end

        -- Sit positions (array)
        if cfg.sit_position and type(cfg.sit_position) == "table" then
            editSitPositions = {}
            if cfg.sit_position.x then
                -- Legacy single object (shouldn't happen after server normalization, but just in case)
                editSitPositions = { { x = cfg.sit_position.x, y = cfg.sit_position.y, z = cfg.sit_position.z, h = cfg.sit_position.h } }
            else
                for i, pos in ipairs(cfg.sit_position) do
                    editSitPositions[i] = { x = pos.x, y = pos.y, z = pos.z, h = pos.h }
                end
            end
        else
            editSitPositions = {}
        end

        editFrozen = cfg.frozen == true
    else
        editAllowedAnims = {} -- new config: nothing selected, user picks specific anims
        editSitPositions = {}
        editFrozen = false
    end
end

-- table.clone utility (shallow)
if not table.clone then
    function table.clone(t)
        local out = {}
        for k, v in pairs(t) do out[k] = v end
        return out
    end
end

-- ── Main menu: BUILDER CHAISES ──

StaffMenu.builderChairs.OnOpen(function()
    StaffMenu.builderChairs.ClearItems()
    local Button = StaffMenu.builderChairs.Button
    local Separator = StaffMenu.builderChairs.Separator
    local Checkbox = StaffMenu.builderChairs.Checkbox

    Separator("BUILDER CHAISES")

    local scanDesc = chairScanActive and (tostring(#scanUnconfiguredChairs) .. (#scanUnconfiguredChairs > 1 and " non configurees dans 200m" or " non configuree dans 200m")) or "Detecter les chaises non configurees dans 200m"
  Checkbox("SCANNER CHAISES", scanDesc, false, chairScanActive, function(checked)
        chairScanActive = checked
        if chairScanActive then
            StartChairScanThread()
        else
            scanUnconfiguredChairs = {}
        end
        StaffMenu.builderChairs.refresh()
    end)

    Button("SELECTIONNER UNE CHAISE", "Viser une chaise et appuyer sur E", nil, "chevron", false, function()
        StaffMenu.builderChairs.close()
        Wait(200)

        local entity = SelectChairVisually()

        if entity and DoesEntityExist(entity) then
            selectedEntity = entity
            selectedModel = GetEntityModel(entity)
            selectedArchetype = GetEntityArchetypeName(entity) or ""
          LoadEditState(selectedModel, selectedArchetype)

            Wait(200)
            StaffMenu.builderChairs.open()
        else
            selectedEntity = nil
            selectedModel = nil
            selectedArchetype = ""
          Wait(200)
            StaffMenu.builderChairs.open()
        end
    end)

    -- Show selected entity info
    if selectedEntity and DoesEntityExist(selectedEntity) and selectedModel then
        Separator("SELECTION ACTIVE")
        Button(
            "Model: " .. tostring(selectedModel),
            selectedArchetype ~= "" and selectedArchetype or "Archetype inconnu",
            nil, "info", true, function() end
        )
        Button("CONFIGURER", "Positions et animations", nil, "chevron", false, function()
            LoadEditState(selectedModel, selectedArchetype)
        end, StaffMenu.builderChairsEdit)
    end

    -- List existing configurations
    Separator("CHAISES CONFIGUREES")

    local count = 0
    for hash, cfg in pairs(ChairConfigOverrides) do
        count = count + 1
        local label = tostring(hash)
        local posCount = cfg.sit_position and #cfg.sit_position or 0
        local desc = cfg.archetype_name ~= "" and cfg.archetype_name or (posCount .. (posCount > 1 and " positions" or " position"))
        Button(label, desc, nil, "chevron", false, function()
            selectedEntity = nil -- no entity selected when editing from list
            selectedModel = hash
            selectedArchetype = cfg.archetype_name or ""
          LoadEditState(hash, cfg.archetype_name)
        end, StaffMenu.builderChairsEdit)
    end

    if count == 0 then
        Button("Aucune configuration", "Sélectionnez une chaise pour commencer", nil, "info", true, function() end)
    end
end)

-- ── Edit menu: CONFIGURER CHAISE ──

StaffMenu.builderChairsEdit.OnOpen(function()
    StaffMenu.builderChairsEdit.ClearItems()
    local Button = StaffMenu.builderChairsEdit.Button
    local Separator = StaffMenu.builderChairsEdit.Separator
    local Checkbox = StaffMenu.builderChairsEdit.Checkbox

    local title = selectedArchetype ~= "" and selectedArchetype or tostring(selectedModel)
    Separator("CONFIGURER: " .. title)

    -- Multi-slot positions
    Separator("POSITIONS (" .. #editSitPositions .. ")")

    if #editSitPositions > 0 then
        for i, pos in ipairs(editSitPositions) do
            Button(
                "Position #" .. i,
                string.format("X: %.2f  Y: %.2f  Z: %.2f  H: %.1f", pos.x, pos.y, pos.z, pos.h),
                nil, "info", true, function() end
            )
        end
        Button("SUPPRIMER DERNIERE", "Retirer la position #" .. #editSitPositions, nil, "trash", false, function()
            table.remove(editSitPositions)
            StaffMenu.builderChairsEdit.refresh()
        end)
        Button("RESET TOUTES LES POSITIONS", "Supprimer toutes les positions", nil, "trash", false, function()
            editSitPositions = {}
            StaffMenu.builderChairsEdit.refresh()
        end)
    else
        Button("AUCUNE POSITION", "Utilisez le Preview pour ajouter des positions", nil, "info", true, function() end)
    end

    -- Animation toggles
    Separator("ANIMATIONS")

    -- Check if all anims are allowed (nil = all)
    local allAllowed = editAllowedAnims == nil

    Checkbox("TOUTES LES ANIMATIONS", "Autoriser toutes les animations", false, allAllowed, function(checked)
        if checked then
            editAllowedAnims = nil
        else
            -- Initialize with all UNCHECKED so user picks specific ones
            editAllowedAnims = {}
        end
        StaffMenu.builderChairsEdit.refresh()
    end)

    if not allAllowed then
        for _, entry in ipairs(ChairAnimKeys) do
            local isChecked = editAllowedAnims[entry.key] == true
            Checkbox(entry.label, nil, false, isChecked, function(checked)
                editAllowedAnims[entry.key] = checked or nil
                -- If all are re-enabled, switch back to nil
                local allOn = true
                for _, e in ipairs(ChairAnimKeys) do
                    if not editAllowedAnims[e.key] then
                        allOn = false
                        break
                    end
                end
                if allOn then
                    editAllowedAnims = nil
                end
            end)
        end
    end

    -- Preview / Add position
    Separator("ACTIONS")

    Checkbox("FREEZE LES PROPS", "Figer tous les props de ce modèle pour tout le monde", false, editFrozen, function(checked)
        editFrozen = checked
    end)

    Button("AJOUTER UNE POSITION", "Preview animation + Gizmo pour placer un slot", nil, "chevron", false, function() end, StaffMenu.builderChairsPreview)

    -- Save
    Button("SAUVEGARDER", "Enregistrer la configuration en base", nil, "chevron", false, function()
        -- Always save explicit table (nil = all allowed, convert to full table so DB never stores NULL)
        local animsToSave = editAllowedAnims
        if not animsToSave then
            animsToSave = {}
            for _, entry in ipairs(ChairAnimKeys) do
                animsToSave[entry.key] = true
            end
        end

        local data = {
            model_hash = selectedModel,
            archetype_name = selectedArchetype or "",
            z_adjust = 0.0,
            allowed_anims = animsToSave,
            sit_position = #editSitPositions > 0 and editSitPositions or nil,
            frozen = editFrozen
        }

        local result = TriggerServerCallback('chairConfig:save', data)
        if result and result.success then
            VFW.ShowNotification({ type = 'VERT', content = "Configuration sauvegardée (" .. #editSitPositions .. " positions)" })
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Erreur: " .. (result and result.error or "inconnue") })
        end
    end)

    -- Delete
    if ChairConfigOverrides[selectedModel] then
        Button("SUPPRIMER CONFIG", "Revenir au comportement par defaut", nil, "trash", false, function()
            local result = TriggerServerCallback('chairConfig:delete', selectedModel)
            if result and result.success then
                VFW.ShowNotification({ type = 'VERT', content = "Configuration supprimée" })
                editAllowedAnims = nil
                editSitPositions = {}
                StaffMenu.builderChairsEdit.close()
                StaffMenu.builderChairsEdit.parent.open()
            else
                VFW.ShowNotification({ type = 'ROUGE', content = "Erreur: " .. (result and result.error or "inconnue") })
            end
        end)
    end
end)

-- ── Preview menu (add position via gizmo) ──

StaffMenu.builderChairsPreview.OnOpen(function()
    StaffMenu.builderChairsPreview.ClearItems()
    local Button = StaffMenu.builderChairsPreview.Button
    local Separator = StaffMenu.builderChairsPreview.Separator

    Separator("AJOUTER POSITION #" .. (#editSitPositions + 1))

    -- Show only currently enabled animations for preview
    for _, entry in ipairs(ChairAnimKeys) do
        -- Skip animations that are not enabled (editAllowedAnims == nil means all allowed)
        if editAllowedAnims and not editAllowedAnims[entry.key] then
            goto continueAnim
        end
        local animData = PreviewAnims[entry.key]
        if animData then
            Button(entry.label, "Positionner avec cette animation", nil, "play", false, function()
                StaffMenu.builderChairsPreview.close()
                Wait(200)

                if not selectedEntity or not DoesEntityExist(selectedEntity) then
                    VFW.ShowNotification({ type = 'ROUGE', content = "Aucune chaise sélectionnée" })
                    Wait(300)
                    StaffMenu.builderChairsPreview.open()
                    return
                end

                local objPos = GetEntityCoords(selectedEntity)
                local objHeading = GetEntityHeading(selectedEntity)

                -- Start position: at the object, default heading
                local sitX = objPos.x
                local sitY = objPos.y
                local sitZ = objPos.z
                local sitH = (objHeading + 180.0) % 360.0

                -- Create a local ped for preview
                local pedModel = joaat("a_m_y_business_01")
                VFW.Streaming.RequestModel(pedModel)
                local clonePed = CreatePed(4, pedModel, sitX, sitY, sitZ, sitH, false, true)
                SetModelAsNoLongerNeeded(pedModel)

                if not clonePed or not DoesEntityExist(clonePed) then
                    VFW.ShowNotification({ type = 'ROUGE', content = "Erreur creation du ped" })
                    Wait(300)
                    StaffMenu.builderChairsPreview.open()
                    return
                end

                SetEntityInvincible(clonePed, true)
                SetEntityAsMissionEntity(clonePed, true, true)
                SetBlockingOfNonTemporaryEvents(clonePed, true)
                SetPedCanRagdoll(clonePed, false)
                FreezeEntityPosition(clonePed, true)
                SetEntityHeading(clonePed, sitH)

                -- Play preview animation
                local animDict = animData[1]
                local animName = animData[2]
                RequestAnimDict(animDict)
                local animTimeout = GetGameTimer() + 5000
                while not HasAnimDictLoaded(animDict) and GetGameTimer() < animTimeout do Wait(10) end
                if HasAnimDictLoaded(animDict) then
                    TaskPlayAnim(clonePed, animDict, animName, 8.0, -4.0, -1, 1, 0, false, false, false)
                end

                Wait(1000)

                -- Launch gizmo on clone (keep frozen — gizmo sets position directly)
                VFW.ShowNotification({ type = 'VERT', content = "Gizmo: positionnez le ped pour la position #" .. (#editSitPositions + 1) .. ". Entree = valider, Echap = annuler" })
                local gizmoResult = exports["core"]:useGizmo(clonePed)

                if gizmoResult and gizmoResult.position then
                    local clonePos = gizmoResult.position
                    local cloneH = GetEntityHeading(clonePed)

                    local rad = math.rad(objHeading)
                    local cosH, sinH = math.cos(rad), math.sin(rad)
                    local dx = clonePos.x - objPos.x
                    local dy = clonePos.y - objPos.y

                    local localX =  dx * cosH + dy * sinH
                    local localY = -dx * sinH + dy * cosH
                    local localZ = clonePos.z - objPos.z
                    local localH = (cloneH - objHeading) % 360.0

                    editSitPositions[#editSitPositions + 1] = {
                        x = math.floor(localX * 100 + 0.5) / 100,
                        y = math.floor(localY * 100 + 0.5) / 100,
                        z = math.floor(localZ * 100 + 0.5) / 100,
                        h = math.floor(localH * 10 + 0.5) / 10
                    }

                    VFW.ShowNotification({ type = 'VERT', content = "Position #" .. #editSitPositions .. " ajoutée! N'oubliez pas de SAUVEGARDER." })
                else
                    VFW.ShowNotification({ type = 'ROUGE', content = "Positionnement annule" })
                end

                -- Cleanup clone
                if DoesEntityExist(clonePed) then
                    DeleteEntity(clonePed)
                end

                Wait(300)
                StaffMenu.builderChairsPreview.open()
            end)
        end
        ::continueAnim::
    end
end)
