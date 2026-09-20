---@meta _
---@diagnostic disable: duplicate-doc-field

local VUI = exports["VUI"]

-- Prop Placer Menu Integration

local function BuildPropPlacerMenu()
    if not PropPlacer or not PropPlacer.active then
        return
    end

    -- Header
    StaffMenu.propPlacer.Separator(":ruler: PROP PLACER - CONTRÔLES")

    -- Instructions
    StaffMenu.propPlacer.Button(":info: INSTRUCTIONS", "G: Sélection d'os | H: Mode Gizmo", nil, nil, false, function()
    end)

    StaffMenu.propPlacer.Separator(":mask: CONFIGURATION")

    -- Change ped model
    StaffMenu.propPlacer.Button(":user: CHANGER LE PED", nil, nil, nil, false, function()
        local result = VFW.Nui.KeyboardInput(true, "Modèle de ped", "mp_m_freemode_01")
        if result and result ~= "" then
            PropPlacer.ChangePedModel(result)
        end
    end)

    -- Change object model
    StaffMenu.propPlacer.Button(":box: CHANGER L'OBJET", nil, nil, nil, false, function()
        local result = VFW.Nui.KeyboardInput(true, "Modèle d'objet", "ba_prop_club_tonic_bottle")
        if result and result ~= "" then
            PropPlacer.ChangeObjectModel(result)
        end
    end)

    -- Play animation
    StaffMenu.propPlacer.Button(":film: JOUER UNE ANIMATION", nil, nil, nil, false, function()
        local dict = VFW.Nui.KeyboardInput(true, "Dict d'animation", "mp_player_intdrink")
        if dict and dict ~= "" then
            local anim = VFW.Nui.KeyboardInput(true, "Nom de l'animation", "loop_bottle")
            if anim and anim ~= "" then
                PropPlacer.PlayAnimation(dict, anim)
            end
        end
    end)

    StaffMenu.propPlacer.Separator(":save: IMPORT/EXPORT")

    -- Copy result
    StaffMenu.propPlacer.Button(":report: COPIER LE RÉSULTAT", "Copie la configuration actuelle", nil, nil, false, function()
        PropPlacer.CopyResult()
    end)

    -- Import configuration
    StaffMenu.propPlacer.Button(":document: IMPORTER UNE CONFIG", nil, nil, nil, false, function()
        local result = VFW.Nui.KeyboardInput(true, "Configuration (format lua)", "")
        if result and result ~= "" then
            PropPlacer.ImportResult(result)
        end
    end)

    StaffMenu.propPlacer.Separator()

    -- Exit prop placer
    StaffMenu.propPlacer.Button(":door: QUITTER", "Ferme le Prop Placer", nil, nil, false, function()
        PropPlacer.Toggle()
        VUI:HandleBack()
    end)
end

-- Register the build function
if StaffMenu and StaffMenu.propPlacer then
    StaffMenu.BuildPropPlacerMenu = BuildPropPlacerMenu
end