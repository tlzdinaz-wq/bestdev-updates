---@meta _
---@diagnostic disable: duplicate-doc-field

-- Configuration de la Pacific Standard Bank (unique)
Pacific = {
    -- Position principale de la banque
    Position = vector3(255.001, 225.855, 101.005),

    -- Position pour entrer le code d'accès
    DoorCodePosition = vector3(262.329, 222.712, 106.429),

    -- Positions des coffres à percer
    SafePositions = {
        vector3(263.916, 213.012, 101.683),
        vector3(257.348, 213.712, 101.683),
        vector3(265.012, 216.480, 101.683),
        vector3(258.548, 217.180, 101.683)
    },

    -- Positions d'accès aux comptes bancaires (pour les civils)
    AccountAccessPositions = {
        vector3(241.727, 227.641, 106.287),
        vector3(243.540, 224.737, 106.287)
    },

    -- Paramètres client
    InteractDistance = 2.0,
    SafeInteractDistance = 1.5,
    PoliceBlipDuration = 480000, -- 8 minutes en ms

    -- Modèle de porte du coffre-fort
    VaultDoorModel = "v_ilev_bk_vaultdoor",

    -- Blip
    Blip = {
        Sprite = 108,
        Color = 2,
        Scale = 0.8,
        Name = "Pacific Standard Bank"
    }
}
