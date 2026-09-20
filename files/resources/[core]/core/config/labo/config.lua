---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIGURATION LABORATOIRES DE FACTION
-- ============================================================

LaboConfig = {
    -- Cooldown (en minutes) entre deux attaques d'un même labo
    attackCooldownMinutes = 2880,

    -- Nombre minimum de membres de la faction en ligne pour lancer une attaque
    minFactionOnline = 1,

    -- Slots d'attaque actifs (géré dynamiquement — ne pas modifier manuellement)
    attackSlots = {},

    -- =========================================================
    -- ROUTING BUCKETS
    -- =========================================================
    -- Offset de base pour les instances (bucket final = bucketOffset + laboId).
    -- NE DOIT PAS chevaucher AFKConfig.Instances.bucketStart/bucketEnd (10000–10999).
    bucketOffset = 20000,

    -- =========================================================
    -- BLIPS CARTE
    -- =========================================================
    blipSprite = 499,
    blipScale  = 0.8,

    -- Couleurs de blip par type de drogue
    blipColors = {
        weed    = 2,  -- Vert
        meth    = 3,  -- Bleu
        cocaine = 0,  -- Blanc
    },

    -- Couleur de blip par défaut si le type n'est pas dans blipColors
    defaultBlipColor = 1,
}
