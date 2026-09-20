---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIG - Points Auto-école / Permis (DVM)
-- Centres d'examen (PNJ, blips, spawns véhicules)
-- ============================================================

DVMConfig = {}

DVMConfig.ExamCenters = {
    {
        name = "Centre d'examen principal",
        coords = vector3(214.42, -1400.50, 29.58),
        heading = 320.51,
        blip = {
            sprite = 408,
            color = 3,
            scale = 0.5,
            label = "Auto-école Los Santos",
        },
        npc = {
            model = "csb_popov",
            coords = vector4(214.42, -1400.50, 29.58, 320.51),
            scenario = "WORLD_HUMAN_STAND_IMPATIENT",
        },
        examAreas = {
            car = {
                spawn = vector4(217.11, -1381.12, 29.57, 92.05),
                instructor = vector4(217.11, -1381.12, 29.57, 92.05),
            },
            motorcycle = {
                spawn = vector4(217.11, -1381.12, 29.57, 92.05),
                instructor = vector4(217.11, -1381.12, 29.57, 92.05),
            },
            truck = {
                spawn = vector4(217.11, -1381.12, 29.57, 92.05),
                instructor = vector4(217.11, -1381.12, 29.57, 92.05),
            },
        },
    },
    {
        name = "Centre d'examen Paleto",
        coords = vector3(-274.39, 6283.08, 30.54),
        heading = 303.87,
        blip = {
            sprite = 408,
            color = 3,
            scale = 0.5,
            label = "Auto-école Paleto",
        },
        npc = {
            model = "csb_popov",
            coords = vector4(-274.39, 6283.08, 30.54, 303.87),
            scenario = "WORLD_HUMAN_STAND_IMPATIENT",
        },
        examAreas = {
            car = {
                spawn = vector4(-268.71, 6280.48, 31.54, 130.89),
                instructor = vector4(-268.71, 6280.48, 31.54, 130.89),
            },
            motorcycle = {
                spawn = vector4(-268.71, 6280.48, 31.54, 130.89),
                instructor = vector4(-268.71, 6280.48, 31.54, 130.89),
            },
            truck = {
                spawn = vector4(-268.71, 6280.48, 31.54, 130.89),
                instructor = vector4(-268.71, 6280.48, 31.54, 130.89),
            },
        },
    },
}
