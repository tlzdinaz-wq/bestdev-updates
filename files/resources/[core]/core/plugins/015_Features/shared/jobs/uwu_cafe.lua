UwuCafeConfig = {
    Recipes = {
        crafting = {
            {
                id = "beignet", label = "Beignet",
                output = "beignet", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pate_a_beignet", label = "Pate a Beignet", amount = 1 },
                    { name = "sucre_glace", label = "Sucre Glace", amount = 1 },
                    { name = "huile_friture", label = "Huile de Friture", amount = 1 }
                }
            },
            {
                id = "croissant", label = "Croissant",
                output = "croissant", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pate_feuilletee", label = "Pate Feuilletee", amount = 1 },
                    { name = "beurre", label = "Beurre", amount = 1 },
                    { name = "oeuf", label = "Oeuf", amount = 1 }
                }
            },
            {
                id = "donut_chocolat", label = "Donut Chocolat",
                output = "donut_chocolat", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pate_a_donut", label = "Pate a Donut", amount = 1 },
                    { name = "glacage_chocolat", label = "Glacage Chocolat", amount = 1 }
                }
            },
            {
                id = "donut_framboise", label = "Donut Framboise",
                output = "donut_framboise", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pate_a_donut", label = "Pate a Donut", amount = 1 },
                    { name = "glacage_framboise", label = "Glacage Framboise", amount = 1 }
                }
            }
        },
        granita = {
            {
                id = "granita_citron", label = "Granita Citron",
                output = "granita_citron", outputQuantity = 1, craftTime = 4,
                ingredients = {
                    { name = "glace_pilee", label = "Glace Pilee", amount = 1 },
                    { name = "sirop_citron", label = "Sirop Citron", amount = 1 }
                }
            },
            {
                id = "granita_tropical", label = "Granita Tropical",
                output = "granita_tropical", outputQuantity = 1, craftTime = 4,
                ingredients = {
                    { name = "glace_pilee", label = "Glace Pilee", amount = 1 },
                    { name = "sirop_tropical", label = "Sirop Tropical", amount = 1 }
                }
            },
            {
                id = "granita_menthe", label = "Granita Menthe",
                output = "granita_menthe", outputQuantity = 1, craftTime = 4,
                ingredients = {
                    { name = "glace_pilee", label = "Glace Pilee", amount = 1 },
                    { name = "sirop_menthe", label = "Sirop Menthe", amount = 1 }
                }
            },
            {
                id = "granita_lagoon", label = "Granita Lagoon",
                output = "granita_lagoon", outputQuantity = 1, craftTime = 4,
                ingredients = {
                    { name = "glace_pilee", label = "Glace Pilee", amount = 1 },
                    { name = "sirop_lagoon", label = "Sirop Lagoon", amount = 1 }
                }
            }
        }
    },

    SharedAnim = {
        crafting = { dict = "anim@amb@business@coc@coc_unpack_cut@", name = "fullcut_cycle_v6_cokecutter" },
        granita = { dict = "anim@amb@business@coc@coc_unpack_cut@", name = "fullcut_cycle_v6_cokecutter" }
    },

    Machine = {
        serveDecrease = {
            petit = 1,
            moyen = 2,
            grand = 3
        },
        minReplaceThreshold = 20,
        drinks = {
            espresso = {
                label = "Espresso",
                barrel = "sac_grain_espresso",
                sizes = {
                    petit = "espresso_petit",
                    moyen = "espresso_moyen",
                    grand = "espresso_grand"
                }
            },
            latte = {
                label = "Latte",
                barrel = "sac_grain_latte",
                sizes = {
                    petit = "latte_petit",
                    moyen = "latte_moyen",
                    grand = "latte_grand"
                }
            },
            cappuccino = {
                label = "Cappuccino",
                barrel = "sac_grain_cappuccino",
                sizes = {
                    petit = "cappuccino_petit",
                    moyen = "cappuccino_moyen",
                    grand = "cappuccino_grand"
                }
            }
        }
    },

    DeliveryAllowedItems = {
        "espresso_petit", "espresso_moyen", "espresso_grand",
        "latte_petit", "latte_moyen", "latte_grand",
        "cappuccino_petit", "cappuccino_moyen", "cappuccino_grand",
        "beignet", "croissant", "donut_chocolat", "donut_framboise",
        "granita_citron", "granita_tropical", "granita_menthe", "granita_lagoon"
    },

    DeliverySocietyPercent = 70,
    DeliveryTipChance = 30,
    DeliveryTipMin = 125,
    DeliveryTipMax = 225,
    DeliveryStartMaxDistance = 50.0,
    DeliveryDefaultModel = "a_m_y_business_01",
    DeliveryNpcSpawnDistance = 50.0,

    Locations = {
        uwu_cafe = {
            label = "UwU Cafe",
            markerZOffset = 0.28,
            Machine = {
                radius = 1.4,
                slots = {
                    slot1 = { pos = vector3(-586.21, -1061.87, 21.34), heading = 93.31 }
                }
            },
            CraftingTable = {
                radius = 1.2,
                slots = {
                    slot1 = { pos = vector3(-588.58, -1059.0, 21.36), heading = 272.8 },
                    slot2 = { pos = vector3(-590.41, -1063.05, 21.36), heading = 92.79 }
                }
            },
            GranitaStation = {
                radius = 1.2,
                slots = {
                    slot1 = { pos = vector3(-590.41, -1064.18, 21.34), heading = 92.21 }
                }
            }
        }
    }
}
