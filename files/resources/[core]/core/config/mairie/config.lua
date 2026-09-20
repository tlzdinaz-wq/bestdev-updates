---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIG - Points Mairie / Gouvernement
-- Positions PNJ & interactions (photo, rendez-vous, identité via IdentityConfig)
-- ============================================================

MairieConfig = {}

-- PNJ photo d'identité
MairieConfig.Photo = {
    price = 500,
    npc = {
        model = "a_f_y_business_01",
        coords = vector4(-554.97, -185.23, 37.22, 203.57),
        name = "Marie",
        avatar = "https://docs.fivem.net/peds/a_f_y_business_01.webp",
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },
    blip = {
        enabled = true,
        sprite = 498,
        scale = 0.5,
        color = 3,
        name = "Gouvernement - Photo d'identité",
    },
}

-- PNJ secrétaire (prise de rendez-vous)
MairieConfig.GovernmentPeds = {
    {
        model = "s_m_m_highsec_01",
        coords = vector4(-556.66, -186.19, 37.22, 208.64),
        scope = "gouvernement",
        title = "Gouvernement",
        npcName = "Secretaire du Gouvernement",
    },
    {
        model = "s_m_m_highsec_01",
        coords = vector4(4972.18, -5598.34, 22.85, 240.27),
        scope = "gouvernement_cayo",
        title = "Gouvernement de Cayo",
        npcName = "Secretaire du Gouvernement de Cayo",
    },
}

-- Compat : ancien Config.MairiePhoto (shared/mairie_photo.lua)
Config = Config or {}
Config.MairiePhoto = MairieConfig.Photo
