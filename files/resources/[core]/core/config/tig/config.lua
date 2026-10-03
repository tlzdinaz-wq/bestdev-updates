---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIG - TIG (Travaux d'Intérêt Général)
-- Zone Alcatraz, points de tâches, téléports début / fin
-- ============================================================

TIGConfig = {}

-- Zone de confinement (spawn + anti-sortie)
--
-- Elle était posée en plein centre de Los Santos (238, -888 = Legion Square) alors que les
-- points de sortie, eux, sont à la prison de Bolingbroke : un joueur mis en TIG restait donc
-- en ville et se faisait renvoyer au centre-ville dès qu'il s'éloignait. La zone est
-- maintenant la prison, et le joueur y est téléporté au début de sa peine.
--
-- Pour l'ajuster au mètre près : place-toi à l'endroit voulu en jeu, relève tes coordonnées
-- et remplace `center` ci-dessous (le rayon couvre l'enceinte).
TIGConfig.Zone = {
    center = vector3(1765.0, 2560.0, 45.2),
    radius = 95.0,
    welcomeText = vector3(1765.0, 2560.0, 46.8),
}

-- Téléports de sortie (devant la prison, à l'extérieur de l'enceinte)
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
            vector3(1735.0, 2540.0, 45.2),
            vector3(1760.0, 2520.0, 45.2),
            vector3(1800.0, 2535.0, 45.2),
            vector3(1730.0, 2575.0, 45.2),
            vector3(1790.0, 2590.0, 45.2),
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
            vector3(1720.0, 2555.0, 45.2),
            vector3(1745.0, 2600.0, 45.2),
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
            vector3(1810.0, 2565.0, 45.2),
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
            vector3(1775.0, 2525.0, 45.2),
            vector3(1700.0, 2590.0, 45.2),
            vector3(1820.0, 2600.0, 45.2),
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
            vector3(1750.0, 2570.0, 45.2),
            vector3(1795.0, 2510.0, 45.2),
            vector3(1715.0, 2520.0, 45.2),
        },
    },
}
