PearlsConfig = {
    Recipes = {
        grill = {
            { input = "truite_emballee", output = "truite_fumee", label = "Griller une Truite" },
            { input = "homard_bleu_emballe", output = "homard_bleu_cuit", label = "Cuire un Homard Bleu" },
            { input = "homard_orange_emballe", output = "homard_orange_cuit", label = "Cuire un Homard Orange" }
        },
        fryer = {
            { input = "frite_crue", output = "frite", label = "Frire des Frites" }
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
        grill = { dict = "amb@prop_human_bbq@male@idle_a", name = "idle_b", prop = { model = "prop_fish_slice_01", bone = 28422, placement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } } },
        fryer = { dict = "amb@prop_human_bbq@male@idle_a", name = "idle_b" },
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
        "truite_fumee", "homard_bleu_cuit", "homard_orange_cuit",
        "frite",
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
        pearls = {
            label = "Pearls",
            Machine = { coords = vector3(-1837.43, -1190.48, 14.31), heading = 56.24, radius = 1.0 },
            GrillStation = {
                center = vector3(-1846.56, -1194.25, 14.31),
                radius = 0.9,
                duration = 7000,
                slots = {
                    left = { pos = vector3(-1846.75, -1194.61, 14.31), heading = 61.70 },
                    right = { pos = vector3(-1846.35, -1193.83, 14.31), heading = 64.51 }
                }
            },
            FryerStation = {
                center = vector3(-1847.39, -1195.94, 14.31),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(-1847.54, -1196.23, 14.31), heading = 56.97 },
                    right = { pos = vector3(-1847.20, -1195.64, 14.31), heading = 56.50 }
                }
            },
            MilkshakeStation = {
                radius = 0.7,
                slots = {
                    slot1 = { pos = vector3(-1848.37, -1197.5, 14.31), heading = 62.02 }
                }
            }
        }
    }
}
