local selectedTvModel = nil
local currentFormMenu = nil -- reference to the parent form menu (add or edit)

local tvDefaults = {
    target = "tvscreen",
    scale = 0.085,
    offset_x = -1.02,
    offset_y = -0.055,
    offset_z = 1.04,
    range = 20.0,
    default_volume = 0.5,
    dui_width = 1280,
    dui_height = 720
}

local KNOWN_TARGETS = {
    "tvscreen",
    "script_rt_ex_tvscreen",
    "cinscreen",
    "Big_Disp",
    "ECG",
}

-- ══════════════════════════════════════════════════════════════════
-- Raycast helpers (same pattern as builderMotel door selector)
-- ══════════════════════════════════════════════════════════════════

local function RotationToDirection(rotation)
    local adjusted = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    return vector3(
        -math.sin(adjusted.z) * math.abs(math.cos(adjusted.x)),
        math.cos(adjusted.z) * math.abs(math.cos(adjusted.x)),
        math.sin(adjusted.x)
    )
end

local function RayCastGamePlayCamera(distance)
    local rot <const> = GetGameplayCamRot()
    local coord <const> = GetGameplayCamCoord()
    local dir <const> = RotationToDirection(rot)
    local dest <const> = coord + dir * distance
    local _, hit, coords, _, entity = GetShapeTestResult(
        StartShapeTestRay(coord.x, coord.y, coord.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    )
    return hit, coords, entity
end

-- ══════════════════════════════════════════════════════════════════
-- TV visual selector
-- ══════════════════════════════════════════════════════════════════

local function SelectTvVisually()
    local selectionActive = true
    local currentEntity = nil
    local selectedEntity = nil

    CreateThread(function()
        while selectionActive do
            Wait(0)
            VFW.ShowHelpNotification("~INPUT_CONTEXT~ Sélectionner la TV ~n~~INPUT_FRONTEND_RRIGHT~ Annuler")

            if currentEntity and currentEntity ~= selectedEntity then
                SetEntityDrawOutline(currentEntity, false)
            end

            local hit, coords, entity = RayCastGamePlayCamera(15.0)

            if DoesEntityExist(entity) and GetEntityType(entity) ~= 0 then
                local success, model = pcall(GetEntityModel, entity)
                if success and model ~= 0 then
                    currentEntity = entity
                    SetEntityDrawOutline(currentEntity, true)

                    if VFW.Interact.JustPressed(0, 51) then -- E
                        selectedEntity = entity
                        selectionActive = false
                    end
                end
            end

            if IsControlJustPressed(0, 194) then -- Backspace
                if currentEntity then
                    SetEntityDrawOutline(currentEntity, false)
                end
                selectionActive = false
            end
        end

        if currentEntity then
            SetEntityDrawOutline(currentEntity, false)
        end
    end)

    while selectionActive do
        Wait(100)
    end

    return selectedEntity
end

-- ══════════════════════════════════════════════════════════════════
-- Auto-detect render target
-- ══════════════════════════════════════════════════════════════════

local function DetectRenderTarget(modelHash)
    for _, name in ipairs(KNOWN_TARGETS) do
        if not IsNamedRendertargetRegistered(name) then
            RegisterNamedRendertarget(name, false)
        end
        LinkNamedRendertarget(modelHash)
        if IsNamedRendertargetLinked(modelHash) then
            ReleaseNamedRendertarget(name)
            return name
        end
        ReleaseNamedRendertarget(name)
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════
-- Target selector submenu
-- ══════════════════════════════════════════════════════════════════

StaffMenu.builderTelevisionTarget.OnOpen(function()
    local menu = StaffMenu.builderTelevisionTarget
    menu.ClearItems()

    if not selectedTvModel then return end

    local currentTarget = selectedTvModel.target or tvDefaults.target

    menu.Separator(":target: RENDER TARGETS CONNUS")

    for _, name in ipairs(KNOWN_TARGETS) do
        local isCurrent = (currentTarget == name)
        menu.Button(
            (isCurrent and ":check: " or "") .. name,
            isCurrent and "Actuellement sélectionné" or nil,
            nil, "chevron", false,
            function()
                selectedTvModel.target = name
                VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Television", message = "Target: " .. name })
                -- Return to form
                if currentFormMenu then
                    currentFormMenu.open()
                end
            end
        )
    end

    menu.Separator(":edit: PERSONNALISÉ")

    -- Show current custom value if not in known list
    local isCustom = true
    for _, name in ipairs(KNOWN_TARGETS) do
        if currentTarget == name then isCustom = false break end
    end

    if isCustom and currentTarget ~= "À définir" then
        menu.Button(
            ":check: " .. currentTarget,
            "Valeur personnalisée actuelle",
            nil, "chevron", false,
            function()
                -- Already selected, just go back
                if currentFormMenu then
                    currentFormMenu.open()
                end
            end
        )
    end

    menu.Button(
        "Saisir un nom personnalisé...",
        "Entrer manuellement le render target",
        nil, "arrow", false,
        function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Render target", currentTarget)
            if input and input ~= "" then
                selectedTvModel.target = input
                VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Television", message = "Target: " .. input })
            end
            if currentFormMenu then
                currentFormMenu.open()
            end
        end
    )
end)

-- ══════════════════════════════════════════════════════════════════
-- Build add/edit form
-- ══════════════════════════════════════════════════════════════════

local function BuildTvModelForm(menu, data, isEdit)
    menu.ClearItems()
    currentFormMenu = menu

    menu.Separator(":monitor: " .. (isEdit and data.model or "NOUVEAU MODELE"))

    -- Model name (read-only, filled by selector or from DB)
    menu.Button("Modèle: " .. (data.model or "Non défini"), isEdit and "Non modifiable" or "Sélectionné via le viseur", nil, nil, true, function() end)

    -- Target (Button → opens target submenu)
    local currentTarget = data.target or tvDefaults.target
    menu.Button(
        "Target: " .. currentTarget,
        "Cliquez pour changer le render target",
        nil, "chevron", false,
        function() end,
        StaffMenu.builderTelevisionTarget
    )

    -- Scale
    menu.Button(
        "Scale: " .. tostring(data.scale or tvDefaults.scale),
        "Échelle de rendu",
        nil, "arrow", false,
        function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Scale", tostring(data.scale or tvDefaults.scale))
            local num <const> = tonumber(input)
            if num and num > 0 then
                data.scale = num
                if menu.opened then menu.refresh() end
            end
        end
    )

    menu.Separator(":ruler: OFFSET")

    -- Offset X
    menu.Button(
        "Offset X: " .. tostring(data.offset_x or tvDefaults.offset_x),
        nil, nil, "arrow", false,
        function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Offset X", tostring(data.offset_x or tvDefaults.offset_x))
            local num <const> = tonumber(input)
            if num then
                data.offset_x = num
                if menu.opened then menu.refresh() end
            end
        end
    )

    -- Offset Y
    menu.Button(
        "Offset Y: " .. tostring(data.offset_y or tvDefaults.offset_y),
        nil, nil, "arrow", false,
        function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Offset Y", tostring(data.offset_y or tvDefaults.offset_y))
            local num <const> = tonumber(input)
            if num then
                data.offset_y = num
                if menu.opened then menu.refresh() end
            end
        end
    )

    -- Offset Z
    menu.Button(
        "Offset Z: " .. tostring(data.offset_z or tvDefaults.offset_z),
        nil, nil, "arrow", false,
        function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Offset Z", tostring(data.offset_z or tvDefaults.offset_z))
            local num <const> = tonumber(input)
            if num then
                data.offset_z = num
                if menu.opened then menu.refresh() end
            end
        end
    )

    menu.Separator(":megaphone: AUDIO & PORTÉE")

    -- Range (audio only — visual activation is global Config.VisualRange in ptelevision/config.lua)
    menu.Button(
        "Portée son: " .. tostring(data.range or tvDefaults.range) .. "m",
        "Distance d'atténuation du son (le visuel est fixe à 60m)",
        nil, "arrow", false,
        function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Portée son (m)", tostring(data.range or tvDefaults.range))
            local num <const> = tonumber(input)
            if num and num > 0 then
                data.range = num
                if menu.opened then menu.refresh() end
            end
        end
    )

    -- Default Volume
    menu.Button(
        "Volume: " .. tostring(data.default_volume or tvDefaults.default_volume),
        "Volume par défaut (0.0 - 1.0)",
        nil, "arrow", false,
        function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Volume (0.0 - 1.0)", tostring(data.default_volume or tvDefaults.default_volume))
            local num <const> = tonumber(input)
            if num and num >= 0 and num <= 1 then
                data.default_volume = num
                if menu.opened then menu.refresh() end
            end
        end
    )

    menu.Separator(":monitor: RÉSOLUTION DUI")

    -- DUI Width (pixels)
    menu.Button(
        "Largeur DUI: " .. tostring(data.dui_width or tvDefaults.dui_width) .. "px",
        "Résolution horizontale du DUI (défaut 1280)",
        nil, "arrow", false,
        function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Largeur DUI (px)", tostring(data.dui_width or tvDefaults.dui_width))
            local num <const> = tonumber(input)
            if num and num >= 64 and num <= 4096 then
                data.dui_width = math.floor(num)
                if menu.opened then menu.refresh() end
            end
        end
    )

    -- DUI Height (pixels)
    menu.Button(
        "Hauteur DUI: " .. tostring(data.dui_height or tvDefaults.dui_height) .. "px",
        "Résolution verticale du DUI (défaut 720)",
        nil, "arrow", false,
        function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Hauteur DUI (px)", tostring(data.dui_height or tvDefaults.dui_height))
            local num <const> = tonumber(input)
            if num and num >= 64 and num <= 4096 then
                data.dui_height = math.floor(num)
                if menu.opened then menu.refresh() end
            end
        end
    )

    menu.Separator(":save: ACTIONS")

    -- Save button
    menu.Button(
        ":save: SAUVEGARDER", nil, nil, "chevron", false,
        function()
            if not data.model or data.model == "" then
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Television", message = "Aucun modèle sélectionné." })
                return
            end

            local payload <const> = {
                model = data.model,
                target = data.target or tvDefaults.target,
                scale = data.scale or tvDefaults.scale,
                offset_x = data.offset_x or tvDefaults.offset_x,
                offset_y = data.offset_y or tvDefaults.offset_y,
                offset_z = data.offset_z or tvDefaults.offset_z,
                range = data.range or tvDefaults.range,
                default_volume = data.default_volume or tvDefaults.default_volume,
                dui_width = data.dui_width or tvDefaults.dui_width,
                dui_height = data.dui_height or tvDefaults.dui_height
            }

            if isEdit then
                TriggerServerEvent("television:updateModel", payload)
            else
                TriggerServerEvent("television:addModel", payload)
            end

            VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Television", message = isEdit and "Modèle mis à jour." or "Modèle ajouté." })

            Wait(200)
            StaffMenu.builderTelevision.open()
        end
    )

    -- Delete button (edit only)
    if isEdit then
        menu.Button(
            ":trash: SUPPRIMER", "Supprimer ce modèle définitivement", nil, "chevron", false,
            function()
                local confirm <const> = VFW.Nui.KeyboardInput(true, "Tapez CONFIRMER pour supprimer")
                if confirm == "CONFIRMER" then
                    TriggerServerEvent("television:deleteModel", data.model)
                    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Television", message = "Modèle supprimé." })
                    Wait(200)
                    StaffMenu.builderTelevision.open()
                end
            end
        )
    end
end

-- ══════════════════════════════════════════════════════════════════
-- Main TV builder menu
-- ══════════════════════════════════════════════════════════════════

StaffMenu.builderTelevision.OnOpen(function()
    StaffMenu.builderTelevision.ClearItems()

    StaffMenu.builderTelevision.Button(
        ":plus: AJOUTER UN MODELE", "Visez une TV et appuyez sur E",
        nil, "chevron", false,
        function()
            StaffMenu.builderTelevision.close()

            VFW.ShowNotification({ type = "STAFF", variant = "INFO", subtitle = "Television", message = "Visez une TV et appuyez sur E" })

            local entity = SelectTvVisually()

            if not entity then
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Television", message = "Sélection annulée" })
                StaffMenu.builderTelevision.open()
                return
            end

            local modelHash <const> = GetEntityModel(entity)
            local modelName <const> = GetEntityArchetypeName(entity)

            -- Auto-detect render target
            local detectedTarget = DetectRenderTarget(modelHash) or "tvscreen"

          selectedTvModel = {
                model = modelName,
                target = detectedTarget,
            }

            StaffMenu.builderTelevisionAdd.open()
        end
    )

    StaffMenu.builderTelevision.Separator(":monitor: MODELES EXISTANTS")

    local models <const> = TriggerServerCallback("television:getModels")

    if not models or #models == 0 then
        StaffMenu.builderTelevision.Button("Aucun modèle", "Ajoutez-en un avec le bouton ci-dessus", nil, nil, true, function() end)
        return
    end

    for _, model in ipairs(models) do
        StaffMenu.builderTelevision.Button(
            ":monitor: " .. model.model,
            ("Target: %s | Scale: %.3f | Range: %.1f"):format(model.target or tvDefaults.target, model.scale or tvDefaults.scale, model.range or tvDefaults.range),
            nil, "chevron", false,
            function()
                selectedTvModel = {
                    model = model.model,
                    target = model.target,
                    scale = model.scale,
                    offset_x = model.offset_x,
                    offset_y = model.offset_y,
                    offset_z = model.offset_z,
                    range = model.range,
                    default_volume = model.default_volume,
                    dui_width = model.dui_width,
                    dui_height = model.dui_height
                }
            end,
            StaffMenu.builderTelevisionEdit
        )
    end
end)

-- Add TV model submenu
StaffMenu.builderTelevisionAdd.OnOpen(function()
    if not selectedTvModel then
        selectedTvModel = {}
    end
    BuildTvModelForm(StaffMenu.builderTelevisionAdd, selectedTvModel, false)
end)

-- Edit TV model submenu
StaffMenu.builderTelevisionEdit.OnOpen(function()
    if not selectedTvModel then
        return
    end
    BuildTvModelForm(StaffMenu.builderTelevisionEdit, selectedTvModel, true)
end)
