---@meta _
---@diagnostic disable: duplicate-doc-field

Config.Multicharacter = {}

-- Autoriser les joueurs à supprimer leurs personnages
Config.Multicharacter.CanDelete = true

if IsDuplicityVersion() then
    -- =========================================================
    -- CÔTÉ SERVEUR
    -- =========================================================

    -- Nombre de slots de personnages par défaut pour chaque joueur.
    -- Pour gérer des slots supplémentaires, utilisez /setslots et /remslots
    Config.Multicharacter.Slots = 4

    -- Préfixe ajouté à chaque personnage (char#:identifier) — à garder court
    Config.Multicharacter.Prefix = "char"

else
    -- =========================================================
    -- CÔTÉ CLIENT
    -- =========================================================

    -- Lieu de la scène de sélection des personnages.
    -- Pour changer le spawn des nouveaux personnages, modifier la valeur par défaut dans la table SQL `users`.
    --
    -- La caméra est fixe (CamCoords / CamRot) et le personnage survolé est cloné
    -- puis placé PAR RAPPORT à la caméra, face à elle :
    --   PedDistance : distance devant la caméra (m)
    --   PedSide     : décalage latéral (m, positif = vers la droite de l'écran, pour laisser la place au panneau)
    --   PedDrop     : hauteur des pieds sous la caméra (m)
    --   PedTurn     : rotation du personnage par rapport à la caméra (degrés, 0 = face caméra)
    --   SnapToGround: true pour recaler les pieds sur le sol (scène au niveau du sol uniquement)
    --   Light       : éclairage d'appoint sur le personnage (la scène se joue de nuit)
    Config.Multicharacter.Spawn = {
        {
            -- Vue en hauteur sur le panneau Vinewood
            CamCoords    = { x = 725.0, y = 1100.0, z = 351.0 },
            CamRot       = { x = 5.0,   y = 0.0,    z = 0.0   },
            Fov          = 45.0,
            PedDistance  = 3.2,
            PedSide      = 0.8,
            PedDrop      = 0.7,
            PedTurn      = -12.0,
            SnapToGround = false,
            Dof          = true,
            DofStrength  = 0.35,
            Freeze       = true,
            Animation    = { dict = "anim@mp_corona_idles@male_c@idle_a", anim = "idle_a" },
            Light        = { r = 255, g = 236, b = 214, range = 7.0, intensity = 1.6 }
        }
    }

    -- Activer le re-log sans recharger la page (ajustez vos ressources en conséquence)
    -- Voir : https://github.com/thelindat/vfw:multicharacter#relogging
    Config.Multicharacter.Relog = true

    -- Apparence par défaut pour les nouveaux personnages
    Config.Multicharacter.Default = {
        ["m"] = {
            mom = 43, dad = 29, grandparents = 0,
            face_md_weight = 61, skin_md_weight = 27, face_g_weight = 0,
            nose_1 = -5, nose_2 = 6, nose_3 = 5, nose_4 = 8, nose_5 = 10, nose_6 = 0,
            cheeks_1 = 2, cheeks_2 = -10, cheeks_3 = 6,
            lip_thickness = -2,
            jaw_1 = 0, jaw_2 = 0,
            chin_1 = 0, chin_2 = 0, chin_13 = 0, chin_4 = 0,
            neck_thickness = 0,
            hair_1 = 76, hair_2 = 0, hair_color_1 = 61, hair_color_2 = 29,
            tshirt_1 = 4, tshirt_2 = 2,
            torso_1 = 23, torso_2 = 2,
            decals_1 = 0, decals_2 = 0,
            arms = 1, arms_2 = 0,
            pants_1 = 28, pants_2 = 3,
            shoes_1 = 70, shoes_2 = 2,
            mask_1 = 0, mask_2 = 0,
            bproof_1 = 0, bproof_2 = 0,
            chain_1 = 22, chain_2 = 2,
            helmet_1 = -1, helmet_2 = 0,
            glasses_1 = 0, glasses_2 = 0,
            watches_1 = -1, watches_2 = 0,
            bracelets_1 = -1, bracelets_2 = 0,
            bags_1 = 0, bags_2 = 0,
            eye_color = 0, eye_squint = 0,
            eyebrows_1 = 0, eyebrows_2 = 0, eyebrows_3 = 0,
            eyebrows_4 = 0, eyebrows_5 = 0, eyebrows_6 = 0,
            makeup_1 = 0, makeup_2 = 0, makeup_3 = 0, makeup_4 = 0,
            lipstick_1 = 0, lipstick_2 = 0, lipstick_3 = 0, lipstick_4 = 0,
            ears_1 = -1, ears_2 = 0,
            chest_1 = 0, chest_2 = 0, chest_3 = 0,
            bodyb_1 = -1, bodyb_2 = 0, bodyb_3 = -1, bodyb_4 = 0,
            age_1 = 0, age_2 = 0,
            blemishes_1 = 0, blemishes_2 = 0,
            blush_1 = 0, blush_2 = 0, blush_3 = 0,
            complexion_1 = 0, complexion_2 = 0,
            sun_1 = 0, sun_2 = 0,
            moles_1 = 0, moles_2 = 0,
            beard_1 = 11, beard_2 = 10, beard_3 = 0, beard_4 = 0,
        },
        ["f"] = {
            mom = 28, dad = 6, grandparents = 0,
            face_md_weight = 63, skin_md_weight = 60, face_g_weight = 0,
            nose_1 = -10, nose_2 = 4, nose_3 = 5, nose_4 = 0, nose_5 = 0, nose_6 = 0,
            cheeks_1 = 0, cheeks_2 = 0, cheeks_3 = 0,
            lip_thickness = 0,
            jaw_1 = 0, jaw_2 = 0,
            chin_1 = -10, chin_2 = 10, chin_13 = -10, chin_4 = 0,
            neck_thickness = -5,
            hair_1 = 43, hair_2 = 0, hair_color_1 = 29, hair_color_2 = 35,
            tshirt_1 = 111, tshirt_2 = 5,
            torso_1 = 25, torso_2 = 2,
            decals_1 = 0, decals_2 = 0,
            arms = 3, arms_2 = 0,
            pants_1 = 12, pants_2 = 2,
            shoes_1 = 20, shoes_2 = 10,
            mask_1 = 0, mask_2 = 0,
            bproof_1 = 0, bproof_2 = 0,
            chain_1 = 85, chain_2 = 0,
            helmet_1 = -1, helmet_2 = 0,
            glasses_1 = 33, glasses_2 = 12,
            watches_1 = -1, watches_2 = 0,
            bracelets_1 = -1, bracelets_2 = 0,
            bags_1 = 0, bags_2 = 0,
            eye_color = 8, eye_squint = -6,
            eyebrows_1 = 32, eyebrows_2 = 7, eyebrows_3 = 52,
            eyebrows_4 = 9, eyebrows_5 = -5, eyebrows_6 = -8,
            makeup_1 = 0, makeup_2 = 0, makeup_3 = 0, makeup_4 = 0,
            lipstick_1 = 0, lipstick_2 = 0, lipstick_3 = 0, lipstick_4 = 0,
            ears_1 = -1, ears_2 = 0,
            chest_1 = 0, chest_2 = 0, chest_3 = 0,
            bodyb_1 = -1, bodyb_2 = 0, bodyb_3 = -1, bodyb_4 = 0,
            age_1 = 0, age_2 = 0,
            blemishes_1 = 0, blemishes_2 = 0,
            blush_1 = 0, blush_2 = 0, blush_3 = 0,
            complexion_1 = 0, complexion_2 = 0,
            sun_1 = 0, sun_2 = 0,
            moles_1 = 12, moles_2 = 8,
            beard_1 = 0, beard_2 = 0, beard_3 = 0, beard_4 = 0,
        },
    }
end
