---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIG - TIG (Travaux d'Intérêt Général)
-- Zone Alcatraz, points de tâches, téléports début / fin
-- ============================================================

TIGConfig = {}

-- Zone de confinement (spawn + anti-sortie)
TIGConfig.Zone = {
    center = vector3(238.06, -888.70, 29.49),
    radius = 65.0,
    welcomeText = vector3(238.06, -888.70, 31.10),
}

-- Téléports de sortie
TIGConfig.Release = {
    -- Fin des TIG (complétion)
    completed = vector3(1847.85, 2608.33, 44.59),
    -- Retrait admin
    admin = vector4(1846.62, 2585.87, 44.67, 267.99),
}

-- Points de travail
TIGConfig.Tasks = {
    {
        name = "Balayer le sol",
        blipSprite = 318,
        blipColor = 5,
        animation = { dict = "anim@amb@drug_field_workers@rake@male_a@base", anim = "base" },
        prop = "prop_tool_broom",
        propAttachment = {
            boneTag = 28422,
            offset = vec3(-0.01, 0.04, -0.03),
            rotation = vec3(0.0, 0.0, 0.0),
        },
        duration = 10000,
        positions = {
            vector3(231.80, -887.10, 29.49),
            vector3(242.10, -892.20, 29.49),
            vector3(249.30, -884.60, 29.49),
            vector3(235.20, -876.80, 29.49),
            vector3(225.70, -896.40, 29.49),
        },
    },
    {
        name = "Ramasser des déchets",
        blipSprite = 318,
        blipColor = 2,
        animation = { dict = "anim@move_m@trash", anim = "pickup" },
        prop = "prop_cs_rub_binbag_01",
        propAttachment = {
            boneTag = 28422,
            offset = vec3(0.0, 0.0, 0.0),
            rotation = vec3(0.0, 0.0, 0.0),
        },
        duration = 8000,
        positions = {
            vector3(251.20, -898.60, 29.49),
            vector3(220.80, -883.30, 29.49),
        },
    },
    {
        name = "Nettoyer le sol avec serpillière",
        blipSprite = 478,
        blipColor = 27,
        animation = { dict = "anim@amb@drug_field_workers@rake@male_a@base", anim = "base" },
        prop = "prop_cs_mop_s",
        propAttachment = {
            boneTag = 28422,
            offset = vec3(-0.02, -0.06, -0.2),
            rotation = vec3(0.0, 0.0, 0.0),
        },
        duration = 12000,
        positions = {
            vector3(238.60, -904.80, 29.49),
            vector3(256.40, -878.90, 29.49),
        },
    },
    {
        name = "Cassage de cailloux",
        blipSprite = 618,
        blipColor = 17,
        animation = { dict = "melee@large_wpn@streamed_core", anim = "ground_attack_on_spot" },
        prop = "prop_tool_pickaxe",
        propAttachment = {
            boneTag = 57005,
            offset = vec3(0.09, -0.02, -0.02),
            rotation = vec3(-78.0, 13.0, 28.0),
        },
        duration = 15000,
        positions = {
            vector3(213.90, -890.70, 29.49),
            vector3(245.60, -869.50, 29.49),
            vector3(260.10, -894.20, 29.49),
        },
    },
    {
        name = "Ratisser le sol",
        blipSprite = 469,
        blipColor = 52,
        animation = { dict = "anim@amb@drug_field_workers@rake@male_a@base", anim = "base" },
        prop = "prop_tool_rake",
        propAttachment = {
            boneTag = 28422,
            offset = vec3(0.0, 0.0, -0.03),
            rotation = vec3(0.0, 0.0, 0.0),
        },
        duration = 11000,
        positions = {
            vector3(227.30, -870.40, 29.49),
            vector3(267.80, -884.70, 29.49),
            vector3(240.70, -862.90, 29.49),
        },
    },
}
