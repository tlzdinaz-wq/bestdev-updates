---@meta _
---@diagnostic disable: duplicate-doc-field

-- IMPORTANT : certaines valeurs DOIVENT être des flottants (ex. 10.0 au lieu de 10)

---@class RealisticVeh
RealisticVeh = {
    -- =========================================================
    -- DÉFORMATION VISUELLE
    -- =========================================================

    -- Multiplicateur de déformation visuelle lors d'une collision.
    -- Plage : 0.0 (aucune) à 10.0 (×10). -1 = ne pas toucher.
    -- Note : la déformation visuelle ne se synchronise pas bien aux autres joueurs.
    deformationMultiplier = -1,

    -- Compression de la déformation vers 1.0. 1 = pas de changement.
    -- Valeurs < 1 : cars plus similaires ; valeurs > 1 : écart amplifié.
    deformationExponent = 0.4,

    -- Compression des dégâts de collision vers 1.0. Même logique.
    collisionDamageExponent = 0.6,

    -- =========================================================
    -- DÉGÂTS MÉCANIQUES
    -- =========================================================

    -- Dégâts moteur (valeurs saines : 1 – 100, point de départ recommandé : 10)
    damageFactorEngine = 1.0,

    -- Dégâts carrosserie (valeurs saines : 1 – 100)
    damageFactorBody = 1.5,

    -- Dégâts réservoir d'essence (valeurs saines : 1 – 200, point de départ recommandé : 64)
    damageFactorPetrolTank = 32.0,

    -- Compression des dégâts moteur (fichier handling) vers 1.0.
    engineDamageExponent = 0.6,

    -- Multiplicateur de dégâts par arme. Plage : 0.0 à 10.0 (-1 = ne pas toucher)
    weaponsDamageMultiplier = 1.0,

    -- =========================================================
    -- DÉGRADATION MOTEUR
    -- =========================================================

    -- Vitesse de dégradation lente. 10 = ~0,25 s par point de vie.
    -- La chute de 800 à 305 prend ~2 min de conduite propre.
    degradingHealthSpeedFactor = 5,

    -- Vitesse de défaillance en cascade (valeurs saines : 1 – 100).
    -- En dessous du seuil, la santé chute rapidement jusqu'à la panne.
    cascadingFailureSpeedFactor = 8.0,

    -- =========================================================
    -- SEUILS DE SANTÉ
    -- =========================================================

    -- En dessous de cette valeur → dégradation lente commence
    degradingFailureThreshold = 500.0,

    -- En dessous de cette valeur → défaillance en cascade
    cascadingFailureThreshold = 360.0,

    -- Valeur de santé finale. Trop haut : la voiture ne fume pas en panne.
    -- Trop bas : un seul tir dans le moteur déclenche un incendie.
    engineSafeGuard = 100.0,

    -- =========================================================
    -- MODE LIMPING & RETOURNEMENT
    -- =========================================================

    -- Si true, le moteur ne cède jamais complètement (toujours au moins du torque)
    limpMode = false,

    -- Multiplicateur de couple en mode limp (valeurs saines : 0.05 – 0.25)
    limpModeMultiplier = 0.19,

    -- Si true, impossible de redresser un véhicule retourné
    preventVehicleFlip = true,

    -- Empêche d'autres scripts de modifier la santé du réservoir
    -- (désactive la prévention d'explosion, compatibilité BVA 2.01)
    compatibilityMode = false,

    -- =========================================================
    -- CREVAISON ALÉATOIRE
    -- =========================================================

    -- Minutes de conduite > 22 mph avant une crevaison statistique. 0 = désactivé
    randomTireBurstInterval = 0,

    -- =========================================================
    -- MULTIPLICATEURS PAR CLASSE
    -- =========================================================

    classDamageMultiplier = {
        [0]  = 1.0,  -- Compacts
        [1]  = 1.0,  -- Sedans
        [2]  = 1.0,  -- SUVs
        [3]  = 1.0,  -- Coupes
        [4]  = 1.0,  -- Muscle
        [5]  = 1.0,  -- Sports Classics
        [6]  = 1.0,  -- Sports
        [7]  = 1.0,  -- Supersport
        [8]  = 0.05, -- Motorcycles
        [9]  = 0.7,  -- Off-road
        [10] = 0.25, -- Industrial
        [11] = 1.0,  -- Utility
        [12] = 1.0,  -- Vans
        [13] = 1.0,  -- Cycles
        [14] = 0.5,  -- Boats
        [15] = 1.0,  -- Helicopters
        [16] = 1.0,  -- Planes
        [17] = 1.0,  -- Service
        [18] = 1.0,  -- Emergency
        [19] = 1.0,  -- Military
        [20] = 1.0,  -- Commercial
        [21] = 1.0,  -- Trains
        [22] = 1.0,  -- Open Wheel
    }
}
