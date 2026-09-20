---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIG - Carte d'identité & PNJ associés
-- ============================================================

IdentityConfig = {}

-- PNJ pour récupérer sa carte d'identité (si perdue / jamais reçue)
IdentityConfig.IdentityCardNpc = {
    enabled = true,
    model = "a_f_y_business_01",
    scenario = "WORLD_HUMAN_CLIPBOARD",
    positions = {
        vector4(-560.12, -190.85, 37.22, 28.0), -- Gouvernement de LS
    },
    interactionDistance = 2.0,
    helpText = "Appuyez sur ~INPUT_CONTEXT~ pour récupérer votre carte d'identité",
    blip = {
        enabled = true,
        sprite = 498,
        scale = 0.5,
        color = 3,
        name = "Gouvernement - Carte d'identité",
    },
}

-- PNJ PPA (permis de port d'arme) — réservé pour usage futur
IdentityConfig.PPANpc = {
    enabled = false,
    model = "a_f_y_business_01",
    coords = vector4(-563.72, -196.12, 37.22, 296.6),
}
