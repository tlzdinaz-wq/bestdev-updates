BurgerShotConfig = {
    Recipes = {
        steak = {
            { input = "steak_boeuf_cru", output = "steak_boeuf_cuit", label = "Cuire un Steak Boeuf" },
            { input = "steak_vegetarien_cru", output = "steak_vegetarien", label = "Cuire un Steak Vegetarien" }
        },
        fryer = {
            { input = "frite_crue", output = "frite", label = "Frire des Frites Surgelees" }
        },
        crafting = {
            {
                id = "burger_classic", label = "Burger Classic",
                output = "burger_classic", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pain_burger", label = "Pain Burger", amount = 1 },
                    { name = "steak_boeuf_cuit", label = "Steak Cuit", amount = 1 },
                    { name = "fromage", label = "Fromage", amount = 1 },
                    { name = "salade", label = "Salade", amount = 1 },
                    { name = "sauce_burgershot", label = "Sauce BurgerShot", amount = 1 }
                }
            },
            {
                id = "burger_epice", label = "Burger Épicé",
                output = "burger_epice", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pain_burger", label = "Pain Burger", amount = 1 },
                    { name = "steak_boeuf_cuit", label = "Steak Cuit", amount = 1 },
                    { name = "fromage", label = "Fromage", amount = 1 },
                    { name = "salade", label = "Salade", amount = 1 },
                    { name = "sauce_epice", label = "Sauce Épicée", amount = 1 }
                }
            },
            {
                id = "burger_veggie", label = "Burger Veggie",
                output = "burger_veggie", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pain_burger", label = "Pain Burger", amount = 1 },
                    { name = "steak_vegetarien", label = "Steak Végétarien", amount = 1 },
                    { name = "fromage", label = "Fromage", amount = 1 },
                    { name = "salade", label = "Salade", amount = 1 },
                    { name = "sauce_burgershot", label = "Sauce BurgerShot", amount = 1 }
                }
            }
        }
    },

    SharedAnim = {
        steak = { dict = "amb@prop_human_bbq@male@idle_a", name = "idle_b", prop = { model = "prop_fish_slice_01", bone = 28422, placement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } } },
        fryer = { dict = "amb@prop_human_bbq@male@idle_a", name = "idle_b" },
        crafting = { dict = "anim@amb@business@coc@coc_unpack_cut@", name = "fullcut_cycle_v6_cokecutter" }
    },

    BagMaxItems = 10,

    BagAllowedItems = {
        "burger_classic", "burger_epice", "burger_veggie",
        "frite",
        "cola_25cl", "cola_33cl", "cola_50cl",
        "sprunk_25cl", "sprunk_33cl", "sprunk_50cl"
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
        "burger_classic", "burger_epice", "burger_veggie",
        "frite",
        "cola_25cl", "cola_33cl", "cola_50cl",
        "sprunk_25cl", "sprunk_33cl", "sprunk_50cl"
    },

    DeliverySocietyPercent = 70,

    DeliveryTipChance = 30,
    DeliveryTipMin = 125,
    DeliveryTipMax = 225,

    DeliveryStartMaxDistance = 50.0,

    DeliveryDefaultModel = "a_m_y_business_01",
    DeliveryNpcSpawnDistance = 50.0,

    Locations = {
        burgershot_mirrorpark = {
            label = "BurgerShot Mirror Park",
            Machine = { coords = vector3(1244.52, -353.79, 69.21), heading = 345.81, radius = 1.0 },
            SteakStation = {
                center = vector3(1252.85, -355.03, 69.21),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(1252.89, -354.75, 69.21), heading = 261.62 },
                    right = { pos = vector3(1252.79, -355.42, 69.21), heading = 256.92 }
                }
            },
            FryerStation = {
                center = vector3(1253.76, -352.07, 69.21),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(1253.82, -351.55, 69.21), heading = 253.95 },
                    right = { pos = vector3(1253.63, -352.52, 69.21), heading = 261.97 }
                }
            },
            CraftingTable = {
                radius = 0.7,
                slots = {
                    slot1 = { pos = vector3(1250.05, -352.73, 69.21), heading = 74.93 },
                    slot2 = { pos = vector3(1247.51, -351.96, 69.21), heading = 253.70 }
                }
            }
        },
        burgershot_muriettaheights = {
            label = "BurgerShot Murietta Heights",
            Machine = { coords = vector3(1115.97, -878.68, 52.34), heading = 343.15, radius = 1.0 },
            SteakStation = {
                center = vector3(1109.85, -881.83, 52.34),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(1109.86, -882.23, 52.34), heading = 88.04 },
                    right = { pos = vector3(1109.85, -881.30, 52.34), heading = 88.46 }
                }
            },
            FryerStation = {
                center = vector3(1109.85, -880.15, 52.34),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(1109.85, -880.50, 52.34), heading = 91.14 },
                    right = { pos = vector3(1109.85, -879.72, 52.34), heading = 91.92 }
                }
            },
            CraftingTable = {
                radius = 0.7,
                slots = {
                    slot1 = { pos = vector3(1112.60, -881.27, 52.34), heading = 78.54 },
                    slot2 = { pos = vector3(1110.98, -881.42, 52.34), heading = 272.87 }
                }
            }
        },
        burgershot_paletobay = {
            label = "BurgerShot Paleto Bay",
            Machine = { coords = vector3(-298.42, 6119.58, 31.54), heading = 311.52, radius = 1.0 },
            SteakStation = {
                center = vector3(-305.03, 6121.76, 31.54),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(-305.32, 6121.50, 31.54), heading = 51.82 },
                    right = { pos = vector3(-304.77, 6122.07, 31.54), heading = 48.91 }
                }
            },
            FryerStation = {
                center = vector3(-303.84, 6122.88, 31.54),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(-304.18, 6122.62, 31.54), heading = 45.36 },
                    right = { pos = vector3(-303.52, 6123.19, 31.54), heading = 47.55 }
                }
            },
            CraftingTable = {
                radius = 0.7,
                slots = {
                    slot1 = { pos = vector3(-302.45, 6120.23, 31.54), heading = 48.34 },
                    slot2 = { pos = vector3(-303.82, 6121.30, 31.54), heading = 229.76 }
                }
            }
        },
        burgershot_vespucci = {
            label = "BurgerShot Vespucci",
            Machine = { coords = vector3(-1196.29, -894.48, 13.97), heading = 129.39, radius = 1.0 },
            SteakStation = {
                center = vector3(-1197.84, -895.68, 13.97),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(-1198.17, -895.88, 13.97), heading = 36.29 },
                    right = { pos = vector3(-1197.53, -895.49, 13.97), heading = 32.73 }
                }
            },
            FryerStation = {
                center = vector3(-1200.48, -897.30, 13.97),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(-1200.87, -897.53, 13.97), heading = 34.88 },
                    right = { pos = vector3(-1200.15, -897.10, 13.97), heading = 20.76 }
                }
            },
            CraftingTable = {
                radius = 0.7,
                slots = {
                    slot1 = { pos = vector3(-1197.48, -897.53, 13.97), heading = 213.40 },
                    slot2 = { pos = vector3(-1195.93, -899.61, 13.97), heading = 34.00 }
                }
            }
        }
    }
}
