---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIG - TIG (Travaux d'Intérêt Général)
-- Zone Alcatraz, points de tâches, téléports début / fin
-- ============================================================

TIGConfig = {}

-- Zone de confinement (spawn + anti-sortie)
TIGConfig.Zone = {
    center = vector3(3948.42, 36.24, 23.88),
    radius = 110.0,
    welcomeText = vector3(3948.42, 40.0, 25.5),
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
            vector3(3978.30, 42.08, 22.36),
            vector3(3951.19, 48.21, 22.35),
            vector3(3963.50, 54.55, 22.34),
            vector3(3989.72, 30.78, 22.34),
            vector3(3990.91, 52.58, 22.34),
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
            vector3(3978.13, 19.93, 20.48),
            vector3(4017.54, 27.30, 22.94),
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
            vector3(3903.76, 3.32, 17.73),
            vector3(3907.64, 38.02, 23.89),
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
            vector3(4006.68, 33.17, 19.87),
            vector3(4003.16, 28.41, 20.04),
            vector3(3967.49, 24.53, 21.08),
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
            vector3(4010.31, 9.11, 20.89),
            vector3(4034.72, 16.08, 21.07),
            vector3(4049.36, 24.06, 20.28),
        },
    },
}
