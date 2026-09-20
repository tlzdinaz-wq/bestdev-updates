--[[
    Configuration des items consommables avec animations Rick3D
    Tous les items de bar, food, drinks avec leurs props et animations
]]

ConsumablesConfig = {}

-- Animations disponibles Rick3D
-- drinks1_clip = Canette/soda
-- drinks2_clip = Bouteille (penchée)
-- drinks3_clip = Verre whisky (droit)
-- drinks4_clip = Verre cocktail
-- drinks5_clip = Style mojito
-- drinks6_clip = Soft drink
-- drinks7_clip = Boisson chaude
-- chocolatebar_clip = Manger snack
-- foods1_clip = Snacks/noix
-- foods2_clip = Frites

-- =====================================================
-- UNICORN BAR
-- =====================================================

-- Vodka Bull - Cocktail énergisant dans un verre highball coloré
ConsumablesConfig["vodka_bull"] = {
    label = "Vodka Bull",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_glassdrink_b",  -- Verre cocktail coloré
    propBone = 58869,
    propPlacement = { 0.03, 0.05, 0.01, 0.0, 0.0, -40.0 },
    alcool = true
}

-- Neon Mojito - Bière (malgré le nom)
ConsumablesConfig["neon_mojito"] = {
    label = "Neon Mojito",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",  -- Bouteille de bière
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

-- Champagne VIP - Verre élégant style champagne
ConsumablesConfig["champagne_vip"] = {
    label = "Champagne VIP",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_glassdrink_c",  -- Verre élégant Rick3D
    propBone = 58869,
    propPlacement = { 0.03, 0.06, -0.01, 0.0, 0.0, 20.0 },
    alcool = true
}

-- Shot Inferno - Petit verre à shot
ConsumablesConfig["shot_inferno"] = {
    label = "Shot Inferno",
    type = "drink",
    thirst = 10,
    duration = 3000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks1_clip",
    prop = "rick3d_foods_drink2",  -- Petit verre/shot Rick3D
    propBone = 58869,
    propPlacement = { 0.02, 0.05, 0.01, 0.0, 0.0, 0.0 },
    alcool = true
}

-- Black Label - Whisky dans un verre tumbler
ConsumablesConfig["black_label"] = {
    label = "Black Label",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

-- Electric Long Island - Cocktail long drink
ConsumablesConfig["electric_longisland"] = {
    label = "Electric Long Island",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_drink5",  -- Verre long drink Rick3D
    propBone = 58869,
    propPlacement = { 0.03, 0.04, 0.0, 0.0, 0.0, -65.0 },
    alcool = true
}

-- Cacahuètes - Popcorn/snacks dans un bol
ConsumablesConfig["unicorn_peanuts"] = {
    label = "Cacahuètes",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "rick3d@foodsdrinks",
    animName = "chocolatebar_clip",
    prop = "rick3d_foods_popcorn1",  -- Bol de popcorn/snacks
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, 0.0 }
}

-- Olives - Brochette d'olives/fruits typique des bars
ConsumablesConfig["unicorn_olives"] = {
    label = "Olives",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "rick3d@foodsdrinks",
    animName = "chocolatebar_clip",
    prop = "rick3d_foods_kebabfruit",  -- Brochette fruits/olives
    propBone = 58869,
    propPlacement = { 0.05, 0.02, 0.0, 0.0, 90.0, 0.0 }
}

-- Vodka (farmable - base pour cocktails)
ConsumablesConfig["vodka"] = {
    label = "Vodka",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink4",  -- Bouteille de vodka
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

-- =====================================================
-- YELLOW JACK
-- =====================================================
ConsumablesConfig["whisky"] = {
    label = "Whisky",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["old_western"] = {
    label = "Old Western",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks3_clip",
    prop = "rick3d_foods_glassdrink_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -40.0 },
    alcool = true
}

ConsumablesConfig["tennessee_gold"] = {
    label = "Tennessee Gold",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["biere_sheriff"] = {
    label = "Bière du Sheriff",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["cactus_shot"] = {
    label = "Cactus Shot",
    type = "drink",
    thirst = 10,
    duration = 3000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks1_clip",
    prop = "rick3d_foods_drink2",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, 0.01, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["moonshine"] = {
    label = "Moonshine",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink4",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["cafe_cowboy"] = {
    label = "Café Cowboy",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks7_clip",
    prop = "rick3d_foods_hotchocolate",
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, -30.0 }
}

ConsumablesConfig["yellowjack_peanuts"] = {
    label = "Cacahuètes",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "rick3d@foodsdrinks",
    animName = "chocolatebar_clip",
    prop = "rick3d_foods_popcorn1",  -- Bol snacks
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["yellowjack_chips"] = {
    label = "Chips",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "mp_player_inteat@burger",
    animName = "mp_player_int_eat_burger",
    prop = "prop_crisp_small",
    propBone = 18905,
    propPlacement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 }
}

-- =====================================================
-- IRISH PUB
-- =====================================================
ConsumablesConfig["black_irish"] = {
    label = "Black Irish",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["dublin_red"] = {
    label = "Dublin Red",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["jameson"] = {
    label = "Jameson",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks3_clip",
    prop = "rick3d_foods_glassdrink_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -40.0 },
    alcool = true
}

ConsumablesConfig["irish_coffee"] = {
    label = "Irish Coffee",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks7_clip",
    prop = "rick3d_foods_hotchocolate",
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, -30.0 },
    alcool = true
}

ConsumablesConfig["celtic_cider"] = {
    label = "Celtic Cider",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["baileys_cream"] = {
    label = "Baileys Cream",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_glassdrink_b",
    propBone = 58869,
    propPlacement = { 0.03, 0.05, 0.01, 0.0, 0.0, -40.0 },
    alcool = true
}

ConsumablesConfig["irishpub_peanuts"] = {
    label = "Cacahuètes",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "rick3d@foodsdrinks",
    animName = "chocolatebar_clip",
    prop = "rick3d_foods_popcorn1",  -- Bol snacks
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["irishpub_chips"] = {
    label = "Chips",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "mp_player_inteat@burger",
    animName = "mp_player_int_eat_burger",
    prop = "prop_crisp_small",
    propBone = 18905,
    propPlacement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 }
}

-- =====================================================
-- ASGARD BAR (Plage)
-- =====================================================
ConsumablesConfig["rhum"] = {
    label = "Rhum",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["tropical_mojito"] = {
    label = "Tropical Mojito",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks5_clip",
    prop = "rick3d_foods_mojito",
    propBone = 58869,
    propPlacement = { 0.02, 0.06, -0.03, 0.0, 0.0, -75.0 },
    alcool = true
}

ConsumablesConfig["coco_loco"] = {
    label = "Coco Loco",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_glassdrink_c",
    propBone = 58869,
    propPlacement = { 0.03, 0.06, -0.01, 0.0, 0.0, 20.0 },
    alcool = true
}

ConsumablesConfig["sunset_rum"] = {
    label = "Sunset Rum",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_drink5",
    propBone = 58869,
    propPlacement = { 0.03, 0.04, 0.0, 0.0, 0.0, -65.0 },
    alcool = true
}

ConsumablesConfig["beach_beer"] = {
    label = "Beach Beer",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["paradise_punch"] = {
    label = "Paradise Punch",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_glassdrink_b",
    propBone = 58869,
    propPlacement = { 0.03, 0.05, 0.01, 0.0, 0.0, -40.0 },
    alcool = true
}

ConsumablesConfig["coco_fresh"] = {
    label = "Coco Fresh",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 }
}

ConsumablesConfig["asgard_peanuts"] = {
    label = "Cacahuètes",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "rick3d@foodsdrinks",
    animName = "chocolatebar_clip",
    prop = "rick3d_foods_popcorn1",  -- Bol snacks
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["asgard_chips"] = {
    label = "Chips",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "mp_player_inteat@burger",
    animName = "mp_player_int_eat_burger",
    prop = "prop_crisp_small",
    propBone = 18905,
    propPlacement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 }
}

-- =====================================================
-- HEN HOUSE (Fermier)
-- =====================================================
ConsumablesConfig["cidre"] = {
    label = "Cidre",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink7",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["biere_fermiere"] = {
    label = "Bière Fermière",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["cidre_brut"] = {
    label = "Cidre Brut",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink7",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["vin_patron"] = {
    label = "Vin du Patron",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_glassdrink_b",
    propBone = 58869,
    propPlacement = { 0.03, 0.05, 0.01, 0.0, 0.0, -40.0 },
    alcool = true
}

-- Vins du vigneron (bouteilles)
ConsumablesConfig["wine_red"] = {
    label = "Vin Rosé",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "prop_wine_red",
    propBone = 0x188E,
    propPlacement = { 0.079, -0.319, -0.090, 0.050, 83.024, 93.070 },
    rotOrder = 0,
    alcool = true
}

ConsumablesConfig["wine_white"] = {
    label = "Vin Blanc",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "prop_wine_white",
    propBone = 0x188E,
    propPlacement = { 0.079, -0.319, -0.090, 0.050, 83.024, 93.070 },
    rotOrder = 0,
    alcool = true
}

ConsumablesConfig["wine_yellow"] = {
    label = "Vin Jaune",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "prop_wine_white",
    propBone = 0x188E,
    propPlacement = { 0.079, -0.319, -0.090, 0.050, 83.024, 93.070 },
    rotOrder = 0,
    alcool = true
}

ConsumablesConfig["pastis_maison"] = {
    label = "Pastis Maison",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks3_clip",
    prop = "rick3d_foods_glassdrink_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -40.0 },
    alcool = true
}

ConsumablesConfig["citronnade"] = {
    label = "Citronnade",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 }
}

ConsumablesConfig["cafe_fermier"] = {
    label = "Café Fermier",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks7_clip",
    prop = "rick3d_foods_hotchocolate",
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, -30.0 }
}

ConsumablesConfig["henhouse_peanuts"] = {
    label = "Cacahuètes",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "rick3d@foodsdrinks",
    animName = "chocolatebar_clip",
    prop = "rick3d_foods_popcorn1",  -- Bol snacks
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["henhouse_olives"] = {
    label = "Olives",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "rick3d@foodsdrinks",
    animName = "chocolatebar_clip",
    prop = "rick3d_foods_kebabfruit",  -- Brochette olives
    propBone = 58869,
    propPlacement = { 0.05, 0.02, 0.0, 0.0, 90.0, 0.0 }
}

-- =====================================================
-- BAR BILLARD
-- =====================================================
ConsumablesConfig["biere_blonde"] = {
    label = "Bière Blonde",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["pression_classique"] = {
    label = "Pression Classique",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["bouteille_fraiche"] = {
    label = "Bouteille Fraiche",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink3",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["jack_cola"] = {
    label = "Jack Cola",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks3_clip",
    prop = "rick3d_foods_glassdrink_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -40.0 },
    alcool = true
}

ConsumablesConfig["pastis_51"] = {
    label = "Pastis 51",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks3_clip",
    prop = "rick3d_foods_glassdrink_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -40.0 },
    alcool = true
}

ConsumablesConfig["shot_vodka"] = {
    label = "Shot Vodka",
    type = "drink",
    thirst = 10,
    duration = 3000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks1_clip",
    prop = "rick3d_foods_drink2",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, 0.01, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["cafe_serre"] = {
    label = "Café Serre",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks7_clip",
    prop = "rick3d_foods_hotchocolate",
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, -30.0 }
}

ConsumablesConfig["billiard_peanuts"] = {
    label = "Cacahuètes",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "rick3d@foodsdrinks",
    animName = "chocolatebar_clip",
    prop = "rick3d_foods_popcorn1",  -- Bol snacks
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["billiard_chips"] = {
    label = "Chips",
    type = "food",
    hunger = 5,
    duration = 4000,
    anim = "mp_player_inteat@burger",
    animName = "mp_player_int_eat_burger",
    prop = "prop_crisp_small",
    propBone = 18905,
    propPlacement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 }
}

-- =====================================================
-- ITEMS GENERIQUES BAR (utilisables partout)
-- =====================================================

-- =====================================================
-- ALCOOLS
-- =====================================================

ConsumablesConfig["tequila"] = {
    label = "Tequila",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["whisky_sec"] = {
    label = "Whisky Sec",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["bourbon"] = {
    label = "Bourbon",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["rhum_pur"] = {
    label = "Rhum",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks3_clip",
    prop = "rick3d_foods_drink5",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["punch"] = {
    label = "Punch",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_glassdrink_b",
    propBone = 58869,
    propPlacement = { 0.03, 0.05, 0.01, 0.0, 0.0, -40.0 },
    alcool = true
}

ConsumablesConfig["vodka"] = {
    label = "Vodka",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["cognac"] = {
    label = "Cognac",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["pastis"] = {
    label = "Pastis",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["moonshine_generique"] = {
    label = "Moonshine",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink4",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

ConsumablesConfig["cidre_generique"] = {
    label = "Cidre",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "rick3d_foods_drink7",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 },
    alcool = true
}

-- Bières (props natifs GTA)
ConsumablesConfig["biere_blonde_generique"] = {
    label = "Bière Blonde",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["biere_brune"] = {
    label = "Bière Brune",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["biere_ambree"] = {
    label = "Bière Ambrée",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["biere_blanche"] = {
    label = "Bière Blanche",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["biere_noire"] = {
    label = "Bière Noire",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["champagne"] = {
    label = "Champagne",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_glassdrink_c",
    propBone = 58869,
    propPlacement = { 0.03, 0.06, -0.01, 0.0, 0.0, 20.0 },
    alcool = true
}

-- =====================================================
-- COCKTAILS
-- =====================================================

ConsumablesConfig["mojito"] = {
    label = "Mojito",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks5_clip",
    prop = "rick3d_foods_mojito",
    propBone = 58869,
    propPlacement = { 0.02, 0.06, -0.03, 0.0, 0.0, -75.0 },
    alcool = true
}

ConsumablesConfig["margarita"] = {
    label = "Margarita",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_drink2",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["pina_colada"] = {
    label = "Pina Colada",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_drink4",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["cosmopolitan"] = {
    label = "Cosmopolitan",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_drink2",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

ConsumablesConfig["bloody_mary"] = {
    label = "Bloody Mary",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_drink2",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}

-- =====================================================
-- SANS ALCOOL
-- =====================================================

ConsumablesConfig["jus_orange"] = {
    label = "Jus d'Orange",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 }
}

ConsumablesConfig["jus_pomme"] = {
    label = "Jus de Pomme",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 }
}

ConsumablesConfig["the_glace"] = {
    label = "The Glace",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink5",
    propBone = 58869,
    propPlacement = { 0.03, 0.04, 0.0, 0.0, 0.0, -65.0 }
}

ConsumablesConfig["cola"] = {
    label = "Cola",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_ecola_can",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["sprunk"] = {
    label = "Sprunk",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_ld_can_01b",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["limonade"] = {
    label = "Limonade",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks6_clip",
    prop = "rick3d_foods_drink6",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 }
}

ConsumablesConfig["eau_plate"] = {
    label = "Eau Plate",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "vw_prop_casino_water_bottle_01a",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 }
}

ConsumablesConfig["water"] = {
    label = "Bouteille d'Eau",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks2_clip",
    prop = "vw_prop_casino_water_bottle_01a",
    propBone = 58869,
    propPlacement = { 0.03, 0.03, 0.01, 0.0, -5.0, 120.0 }
}

ConsumablesConfig["bread"] = {
    label = "Pain",
    type = "food",
    hunger = 20,
    duration = 4000,
    anim = "mp_player_inteat@burger",
    animName = "mp_player_int_eat_burger",
    prop = "prop_sandwich_01",
    propBone = 18905,
    propPlacement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 }
}

ConsumablesConfig["cafe"] = {
    label = "Café",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks7_clip",
    prop = "rick3d_foods_hotchocolate",
    propBone = 58869,
    propPlacement = { 0.0, 0.02, 0.0, 0.0, 0.0, -30.0 }
}

-- =====================================================
-- SNACKS BAR (Props natifs GTA V)
-- =====================================================

-- Barre chocolatee - Snack classique de bar
ConsumablesConfig["chocolat_bar"] = {
    label = "Barre Chocolatée",
    type = "food",
    hunger = 20,
    duration = 4000,
    anim = "mp_player_inteat@burger",
    animName = "mp_player_int_eat_burger",
    prop = "rick3d_foods_chocolatebar",
    propBone = 18905,
    propPlacement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 }
}

-- Paquet de chips - Snack classique de bar
ConsumablesConfig["chips_bowl"] = {
    label = "Paquet de Chips",
    type = "food",
    hunger = 20,
    duration = 4000,
    anim = "mp_player_inteat@burger",
    animName = "mp_player_int_eat_burger",
    prop = "prop_crisp_small",
    propBone = 18905,
    propPlacement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 }
}

-- =====================================================
-- BIERES DE JOBS
-- =====================================================

ConsumablesConfig["biere_unicorn"] = {
    label = "Bière Unicorn",
    type = "drink",
    thirst = 5,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["biere_yellowjack"] = {
    label = "Bière Yellow Jack",
    type = "drink",
    thirst = 5,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["biere_asgard"] = {
    label = "Bière Asgard",
    type = "drink",
    thirst = 5,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["biere_irishpub"] = {
    label = "Bière Irish Pub",
    type = "drink",
    thirst = 5,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["biere_henhouse"] = {
    label = "Bière Henhouse",
    type = "drink",
    thirst = 5,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["biere_billard"] = {
    label = "Bière 8Billard",
    type = "drink",
    thirst = 5,
    duration = 5000,
    anim = "amb@world_human_drinking@beer@male@idle_a",
    animName = "idle_c",
    prop = "prop_beer_bottle",
    propBone = 28422,
    propPlacement = { 0.0, 0.0, -0.1, 0.0, 0.0, 0.0 },
    alcool = true
}

ConsumablesConfig["cocktail_cayo_lagoon"] = {
    label = "Cocktail Cayo Lagoon",
    type = "drink",
    thirst = 5,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks4_clip",
    prop = "rick3d_foods_drink4",
    propBone = 58869,
    propPlacement = { 0.02, 0.04, 0.0, 0.0, 0.0, -50.0 },
    alcool = true
}


ConsumablesConfig["burger_classic"] = {
    label = "Burger Classic",
    type = "food",
    hunger = 35,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "2handeat_clip",
    prop = "rick3d_foods_hamburguer",
    propBone = 58869,
    propPlacement = { 0.02, 0.1, 0.05, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["burger_epice"] = {
    label = "Burger Épicé",
    type = "food",
    hunger = 40,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "2handeat_clip",
    prop = "rick3d_foods_hamburguer",
    propBone = 58869,
    propPlacement = { 0.02, 0.1, 0.05, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["burger_veggie"] = {
    label = "Burger Veggie",
    type = "food",
    hunger = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "2handeat_clip",
    prop = "rick3d_foods_hamburguer",
    propBone = 58869,
    propPlacement = { 0.02, 0.1, 0.05, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["frite"] = {
    label = "Frites",
    type = "food",
    hunger = 15,
    duration = 4000,
    anim = "rick3d@foodsdrinks",
    animName = "handholdtoeat1_clip",
    prop = "rick3d_foods_frenchfries_only",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, 0.05, 0.0, 90.0, 0.0 },
    secondProp = "rick3d_foods_frenchfries",
    secondPropBone = 26612,
    secondPropPlacement = { 0.07, -0.07, 0.0, -10.0, -10.0, -15.0 }
}

ConsumablesConfig["cola_25cl"] = {
    label = "Cola 25cl",
    type = "drink",
    thirst = 15,
    duration = 4000,
    anim = "smo@milkshake_idle",
    animName = "milkshake_idle_clip",
    prop = "rpemotesreborn_soda05",
    propBone = 28422,
    propPlacement = { 0.0470, 0.0040, -0.0600, -88.0263, -25.0367, -27.3898 }
}

ConsumablesConfig["cola_33cl"] = {
    label = "Cola 33cl",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "smo@milkshake_idle",
    animName = "milkshake_idle_clip",
    prop = "rpemotesreborn_soda05",
    propBone = 28422,
    propPlacement = { 0.0470, 0.0040, -0.0600, -88.0263, -25.0367, -27.3898 }
}

ConsumablesConfig["cola_50cl"] = {
    label = "Cola 50cl",
    type = "drink",
    thirst = 30,
    duration = 6000,
    anim = "smo@milkshake_idle",
    animName = "milkshake_idle_clip",
    prop = "rpemotesreborn_soda05",
    propBone = 28422,
    propPlacement = { 0.0470, 0.0040, -0.0600, -88.0263, -25.0367, -27.3898 }
}

ConsumablesConfig["sprunk_25cl"] = {
    label = "Sprunk 25cl",
    type = "drink",
    thirst = 15,
    duration = 4000,
    anim = "smo@milkshake_idle",
    animName = "milkshake_idle_clip",
    prop = "rpemotesreborn_soda02",
    propBone = 28422,
    propPlacement = { 0.0470, 0.0040, -0.0600, -88.0263, -25.0367, -27.3898 }
}

ConsumablesConfig["sprunk_33cl"] = {
    label = "Sprunk 33cl",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "smo@milkshake_idle",
    animName = "milkshake_idle_clip",
    prop = "rpemotesreborn_soda02",
    propBone = 28422,
    propPlacement = { 0.0470, 0.0040, -0.0600, -88.0263, -25.0367, -27.3898 }
}

ConsumablesConfig["sprunk_50cl"] = {
    label = "Sprunk 50cl",
    type = "drink",
    thirst = 30,
    duration = 6000,
    anim = "smo@milkshake_idle",
    animName = "milkshake_idle_clip",
    prop = "rpemotesreborn_soda02",
    propBone = 28422,
    propPlacement = { 0.0470, 0.0040, -0.0600, -88.0263, -25.0367, -27.3898 }
}

ConsumablesConfig["pizza_margherita"] = {
    label = "Pizza Margherita",
    type = "food",
    hunger = 40,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "2handeat2_clip",
    prop = "rick3d_foods_pizza",
    propBone = 26612,
    propPlacement = { 0.07, -0.12, -0.012, 0.0, 0.0, 170.0 }
}

ConsumablesConfig["pizza_pepperoni"] = {
    label = "Pizza Pepperoni",
    type = "food",
    hunger = 45,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "2handeat2_clip",
    prop = "rick3d_foods_pizza",
    propBone = 26612,
    propPlacement = { 0.07, -0.12, -0.012, 0.0, 0.0, 170.0 }
}

ConsumablesConfig["pizza_champignon"] = {
    label = "Pizza Champignon",
    type = "food",
    hunger = 35,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "2handeat2_clip",
    prop = "rick3d_foods_pizza",
    propBone = 26612,
    propPlacement = { 0.07, -0.12, -0.012, 0.0, 0.0, 170.0 }
}

ConsumablesConfig["pizza_4fromages"] = {
    label = "Pizza 4 Fromages",
    type = "food",
    hunger = 50,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "2handeat2_clip",
    prop = "rick3d_foods_pizza",
    propBone = 26612,
    propPlacement = { 0.07, -0.12, -0.012, 0.0, 0.0, 170.0 }
}

ConsumablesConfig["milkshake_vanille"] = {
    label = "Milkshake Vanille",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "rick3d_foods_milkshake_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.045, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["milkshake_chocolat"] = {
    label = "Milkshake Chocolat",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "rick3d_foods_milkshake_b",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.045, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["milkshake_cafe"] = {
    label = "Milkshake Cafe",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "rick3d_foods_milkshake_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.045, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["truite_fumee"] = {
    label = "Truite Fumée",
    type = "food",
    hunger = 40,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "plate_clip",
    prop = "rick3d_foods_fork",
    propBone = 58869,
    propPlacement = { 0.09, 0.05, 0.02, 0.0, 25.0, -40.0 },
    secondProp = "rick3d_foods_grilledfish",
    secondPropBone = 26612,
    secondPropPlacement = { 0.03, -0.04, 0.0, 70.0, 70.0, 0.0 }
}

ConsumablesConfig["homard_bleu_cuit"] = {
    label = "Homard Bleu Cuit",
    type = "food",
    hunger = 50,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "1handeat_clip",
    prop = "rick3d_foods_lobster_b",
    propBone = 58869,
    propPlacement = { 0.05, 0.07, 0.07, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["homard_orange_cuit"] = {
    label = "Homard Orange Cuit",
    type = "food",
    hunger = 50,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "1handeat_clip",
    prop = "rick3d_foods_lobster_a",
    propBone = 58869,
    propPlacement = { 0.05, 0.07, 0.07, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["ramen"] = {
    label = "Ramen",
    type = "food",
    hunger = 45,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "plate_clip",
    prop = "rick3d_foods_fork",
    propBone = 58869,
    propPlacement = { 0.09, 0.05, 0.02, 0.0, 25.0, -40.0 },
    secondProp = "rick3d_foods_ramen",
    secondPropBone = 26612,
    secondPropPlacement = { 0.03, -0.04, 0.0, 70.0, 70.0, 0.0 }
}

ConsumablesConfig["sushi"] = {
    label = "Sushi",
    type = "food",
    hunger = 35,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "handholdtoeat2_clip",
    prop = "rick3d_foods_nuggets_b",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, 0.05, 0.0, 90.0, 0.0 },
    secondProp = "rick3d_foods_sushi",
    secondPropBone = 26612,
    secondPropPlacement = { 0.01, -0.025, 0.0, 90.0, 0.0, 15.0 }
}

ConsumablesConfig["pho"] = {
    label = "Pho",
    type = "food",
    hunger = 40,
    duration = 6000,
    anim = "rick3d@foodsdrinks",
    animName = "plate_clip",
    prop = "rick3d_foods_fork",
    propBone = 58869,
    propPlacement = { 0.09, 0.05, 0.02, 0.0, 25.0, -40.0 },
    secondProp = "rick3d_foods_chillibowl",
    secondPropBone = 26612,
    secondPropPlacement = { 0.03, -0.04, 0.0, 70.0, 70.0, 0.0 }
}

ConsumablesConfig["espresso_petit"] = {
    label = "Espresso Petit",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "p_amb_coffeecup_01",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.005, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["espresso_moyen"] = {
    label = "Espresso Moyen",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "p_amb_coffeecup_01",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.005, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["espresso_grand"] = {
    label = "Espresso Grand",
    type = "drink",
    thirst = 35,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "p_amb_coffeecup_01",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.005, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["latte_petit"] = {
    label = "Latte Petit",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "p_amb_coffeecup_01",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.005, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["latte_moyen"] = {
    label = "Latte Moyen",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "p_amb_coffeecup_01",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.005, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["latte_grand"] = {
    label = "Latte Grand",
    type = "drink",
    thirst = 35,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "p_amb_coffeecup_01",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.005, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["cappuccino_petit"] = {
    label = "Cappuccino Petit",
    type = "drink",
    thirst = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "p_amb_coffeecup_01",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.005, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["cappuccino_moyen"] = {
    label = "Cappuccino Moyen",
    type = "drink",
    thirst = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "p_amb_coffeecup_01",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.005, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["cappuccino_grand"] = {
    label = "Cappuccino Grand",
    type = "drink",
    thirst = 35,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "p_amb_coffeecup_01",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.005, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["beignet"] = {
    label = "Beignet",
    type = "food",
    hunger = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "2handeat_clip",
    prop = "rick3d_foods_beignet",
    propBone = 58869,
    propPlacement = { 0.0, 0.15, 0.1, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["croissant"] = {
    label = "Croissant",
    type = "food",
    hunger = 15,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "1handeat_clip",
    prop = "rick3d_foods_croissant",
    propBone = 58869,
    propPlacement = { 0.05, 0.07, 0.07, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["donut"] = {
    label = "Donut",
    type = "food",
    hunger = 25,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "1handeat_clip",
    prop = "rick3d_foods_donut",
    propBone = 58869,
    propPlacement = { 0.05, 0.07, 0.07, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["donut_chocolat"] = {
    label = "Donut Chocolat",
    type = "food",
    hunger = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "1handeat_clip",
    prop = "rick3d_foods_donut",
    propBone = 58869,
    propPlacement = { 0.05, 0.07, 0.07, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["donut_framboise"] = {
    label = "Donut Framboise",
    type = "food",
    hunger = 20,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "1handeat_clip",
    prop = "rick3d_foods_donut",
    propBone = 58869,
    propPlacement = { 0.05, 0.07, 0.07, 50.0, 100.0, 0.0 }
}

ConsumablesConfig["granita_citron"] = {
    label = "Granita Citron",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "rick3d_foods_milkshake_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.045, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["granita_tropical"] = {
    label = "Granita Tropical",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "rick3d_foods_milkshake_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.045, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["granita_menthe"] = {
    label = "Granita Menthe",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "rick3d_foods_milkshake_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.045, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["granita_lagoon"] = {
    label = "Granita Lagoon",
    type = "drink",
    thirst = 30,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "drinks8_clip",
    prop = "rick3d_foods_milkshake_a",
    propBone = 58869,
    propPlacement = { 0.02, 0.05, -0.045, 0.0, 0.0, 0.0 }
}

ConsumablesConfig["fajitas"] = {
    label = "Fajitas",
    type = "food",
    hunger = 40,
    duration = 5000,
    anim = "rick3d@foodsdrinks",
    animName = "2handeat3_clip",
    prop = "rick3d_foods_taco",
    propBone = 26613,
    propPlacement = { -0.03, -0.01, -0.08, 80.0, 25.0, 0.0 }
}

ConsumablesConfig["colombiana"] = {
    label = "Colombiana",
    type = "drink",
    thirst = 20,
    duration = 5000,
    anim = "smo@milkshake_idle",
    animName = "milkshake_idle_clip",
    prop = "rpemotesreborn_soda06",
    propBone = 28422,
    propPlacement = { 0.0470, 0.0040, -0.0600, -88.0263, -25.0367, -27.3898 }
}
