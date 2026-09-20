---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIGURATION ZOMBIES
-- ============================================================

ZombieConfig = {
    -- =========================================================
    -- MODÈLES PED
    -- =========================================================
    Models = {
        "u_m_y_zombie_01",
    },

    -- =========================================================
    -- DÉTECTION & AGGRO
    -- =========================================================

    -- Rayon de détection du joueur par un zombie (en mètres)
    DetectionRange = 50.0,

    -- =========================================================
    -- HORDE
    -- =========================================================
    HordeMinSize    = 2,
    HordeMaxSize    = 5,
    HordeSpread     = 8.0,   -- Rayon de dispersion de la horde autour du point de spawn
    BurstBatchSize  = 15,    -- Nombre max de zombies spawnés en un seul burst

    -- =========================================================
    -- SPAWN / DESPAWN
    -- =========================================================
    RespawnDelay    = 30000, -- Délai avant réapparition d'un zombie tué (ms)
    SpawnInterval   = 3000,  -- Délai entre chaque spawn individuel (ms)
    DespawnDistance = 250.0, -- Distance à laquelle les zombies sont supprimés (m)
    SpawnMaxAttempts = 20,   -- Tentatives max pour trouver un point de spawn valide

    -- Intervalle de vérification de la zone active (ms)
    ZoneCheckInterval = 1000,

    -- =========================================================
    -- STATISTIQUES
    -- =========================================================
    Health = 200,
    Armor  = 0,

    -- Animation de déplacement (clipset GTA)
    MovementClipSet = "move_m@drunk@verydrunk",

    -- =========================================================
    -- LOOT
    -- =========================================================
    LootRange       = 2.0,    -- Rayon d'interaction pour le loot (m)
    LootDefaultMin  = 50,     -- Argent minimum lâché
    LootDefaultMax  = 150,    -- Argent maximum lâché
    LootDuration    = 3000,   -- Durée d'animation de loot (ms)
}
