NoodleConfig = {
    Recipes = {
        broth = {
            { input = "nouilles_crues", output = "nouilles", label = "Cuire des Nouilles" },
            { input = "riz_cru", output = "riz_sushi", label = "Cuire du Riz a Sushi" },
            { input = "bouillon_cru", output = "bouillon_parfume", label = "Preparer un Bouillon" }
        },
        crafting = {
            {
                id = "ramen", label = "Ramen",
                output = "ramen", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "nouilles", label = "Nouilles", amount = 1 },
                    { name = "bouillon_soja", label = "Bouillon de Soja", amount = 1 },
                    { name = "porc_chashu", label = "Porc Chashu", amount = 1 },
                    { name = "oeuf_marine", label = "Oeuf Marine", amount = 1 },
                    { name = "oignon_vert", label = "Oignon Vert", amount = 1 }
                }
            },
            {
                id = "sushi", label = "Sushi",
                output = "sushi", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "riz_sushi", label = "Riz a Sushi", amount = 1 },
                    { name = "vinaigre_riz", label = "Vinaigre de Riz", amount = 1 },
                    { name = "saumon_cru", label = "Saumon Cru", amount = 1 },
                    { name = "algues_nori", label = "Algues Nori", amount = 1 },
                    { name = "avocat", label = "Avocat", amount = 1 }
                }
            },
            {
                id = "pho", label = "Pho",
                output = "pho", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "bouillon_parfume", label = "Bouillon Parfume", amount = 1 },
                    { name = "nouilles", label = "Nouilles", amount = 1 },
                    { name = "boeuf", label = "Boeuf", amount = 1 },
                    { name = "coriandre", label = "Coriandre", amount = 1 },
                    { name = "pousses_soja", label = "Pousses de Soja", amount = 1 }
                }
            }
        },
        milkshake = {
            {
                id = "milkshake_vanille", label = "Milkshake Vanille",
                output = "milkshake_vanille", outputQuantity = 1, craftTime = 4,
                ingredients = {
                    { name = "lait", label = "Lait", amount = 1 },
                    { name = "glace_vanille", label = "Glace Vanille", amount = 1 }
                }
            },
            {
                id = "milkshake_chocolat", label = "Milkshake Chocolat",
                output = "milkshake_chocolat", outputQuantity = 1, craftTime = 4,
                ingredients = {
                    { name = "lait", label = "Lait", amount = 1 },
                    { name = "glace_chocolat", label = "Glace Chocolat", amount = 1 }
                }
            },
            {
                id = "milkshake_cafe", label = "Milkshake Cafe",
                output = "milkshake_cafe", outputQuantity = 1, craftTime = 4,
                ingredients = {
                    { name = "lait", label = "Lait", amount = 1 },
                    { name = "glace_cafe", label = "Glace Cafe", amount = 1 }
                }
            }
        }
    },

    SharedAnim = {
        broth = { dict = "amb@prop_human_bbq@male@idle_a", name = "idle_b" },
        crafting = { dict = "anim@amb@business@coc@coc_unpack_cut@", name = "fullcut_cycle_v6_cokecutter" },
        milkshake = { dict = "anim@amb@business@coc@coc_unpack_cut@", name = "fullcut_cycle_v6_cokecutter" }
    },

    Machine = {
        serveDecrease = {
            ["25cl"] = 1,
            ["33cl"] = 2,
            ["50cl"] = 3
        },
        minReplaceThreshold = 20,
        drinks = {
            cola = {
                label = "Cola",
                barrel = "fut_cola",
                sizes = {
                    ["25cl"] = "cola_25cl",
                    ["33cl"] = "cola_33cl",
                    ["50cl"] = "cola_50cl"
                }
            },
            sprunk = {
                label = "Sprunk",
                barrel = "fut_sprunk",
                sizes = {
                    ["25cl"] = "sprunk_25cl",
                    ["33cl"] = "sprunk_33cl",
                    ["50cl"] = "sprunk_50cl"
                }
            }
        }
    },

    DeliveryAllowedItems = {
        "ramen", "sushi", "pho",
        "cola_25cl", "cola_33cl", "cola_50cl",
        "sprunk_25cl", "sprunk_33cl", "sprunk_50cl",
        "milkshake_vanille", "milkshake_chocolat", "milkshake_cafe"
    },

    DeliverySocietyPercent = 70,
    DeliveryTipChance = 30,
    DeliveryTipMin = 125,
    DeliveryTipMax = 225,
    DeliveryStartMaxDistance = 50.0,
    DeliveryDefaultModel = "a_m_y_business_01",
    DeliveryNpcSpawnDistance = 50.0,

    Locations = {
        noodle = {
            label = "Noodle",
            markerZOffset = 0.28,
            Machine = { coords = vector3(-326.62, -806.26, 31.45), heading = 113.06, radius = 1.4 },
            BrothStation = {
                center = vector3(-325.03, -802.21, 31.45),
                radius = 1.4,
                duration = 7000,
                slots = {
                    left = { pos = vector3(-325.41, -802.33, 31.45), heading = 13.08 },
                    right = { pos = vector3(-324.59, -802.1, 31.45), heading = 17.47 }
                }
            },
            CraftingTable = {
                radius = 1.4,
                slots = {
                    slot1 = { pos = vector3(-324.13, -799.48, 31.45), heading = 202.73 },
                    slot2 = { pos = vector3(-324.44, -799.62, 31.45), heading = 200.55 },
                    slot3 = { pos = vector3(-324.81, -799.73, 31.45), heading = 202.18 }
                }
            },
            MilkshakeStation = {
                radius = 1.4,
                slots = {
                    slot1 = { pos = vector3(-325.91, -808.0, 31.45), heading = 116.17 }
                }
            }
        }
    }
}
