---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIGURATION KING OF THE HILL (KOTH)
-- ============================================================

KOTHConfig = {
    -- Durée d'un KOTH en minutes
    defaultDuration = 15,

    -- Points gagnés par tick (intervalle = tickInterval secondes)
    pointsPerTick = 1,

    -- Intervalle entre chaque tick (secondes)
    tickInterval = 10,

    -- Rayon par défaut de la zone de capture (mètres)
    defaultRadius = 50.0,

    -- =========================================================
    -- BLIP CARTE
    -- =========================================================
    blipSprite = 439,
    blipColor  = 46,
    blipScale  = 1.2,

    -- =========================================================
    -- COULEUR DE LA ZONE (RGBA)
    -- =========================================================
    zoneColor = { r = 255, g = 0, b = 0, a = 80 },
}
