PizzeriaConfig = {
    Recipes = {
        oven = {
            { input = "pizza_margherita_crue", output = "pizza_margherita", label = "Cuire une Pizza Margherita" },
            { input = "pizza_pepperoni_crue", output = "pizza_pepperoni", label = "Cuire une Pizza Pepperoni" },
            { input = "pizza_champignon_crue", output = "pizza_champignon", label = "Cuire une Pizza Champignon" },
            { input = "pizza_4fromages_crue", output = "pizza_4fromages", label = "Cuire une Pizza 4 Fromages" }
        },
        fryer = {
            { input = "frite_crue", output = "frite", label = "Frire des Frites" }
        },
        crafting = {
            {
                id = "pizza_margherita", label = "Pizza Margherita",
                output = "pizza_margherita_crue", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pate_pizza", label = "Pate a Pizza", amount = 1 },
                    { name = "sauce_tomate", label = "Sauce Tomate", amount = 1 },
                    { name = "mozzarella", label = "Mozzarella", amount = 1 },
                    { name = "basilic", label = "Basilic", amount = 1 },
                    { name = "huile_olive", label = "Huile d'Olive", amount = 1 }
                }
            },
            {
                id = "pizza_pepperoni", label = "Pizza Pepperoni",
                output = "pizza_pepperoni_crue", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pate_pizza", label = "Pate a Pizza", amount = 1 },
                    { name = "sauce_tomate", label = "Sauce Tomate", amount = 1 },
                    { name = "mozzarella", label = "Mozzarella", amount = 1 },
                    { name = "pepperoni", label = "Pepperoni", amount = 1 },
                    { name = "origan", label = "Origan", amount = 1 }
                }
            },
            {
                id = "pizza_champignon", label = "Pizza Champignon",
                output = "pizza_champignon_crue", outputQuantity = 1, craftTime = 5,
                ingredients = {
                    { name = "pate_pizza", label = "Pate a Pizza", amount = 1 },
                    { name = "sauce_tomate", label = "Sauce Tomate", amount = 1 },
                    { name = "mozzarella", label = "Mozzarella", amount = 1 },
                    { name = "champignons", label = "Champignons", amount = 1 },
                    { name = "huile_olive", label = "Huile d'Olive", amount = 1 }
                }
            },
            {
                id = "pizza_4fromages", label = "Pizza 4 Fromages",
                output = "pizza_4fromages_crue", outputQuantity = 1, craftTime = 7,
                ingredients = {
                    { name = "pate_pizza", label = "Pate a Pizza", amount = 1 },
                    { name = "mozzarella", label = "Mozzarella", amount = 1, visual = "mozzarella_layer" },
                    { name = "parmesan", label = "Parmesan", amount = 1, visual = "parmesan_layer" },
                    { name = "gorgonzola", label = "Gorgonzola", amount = 1, visual = "gorgonzola_chunk" },
                    { name = "chevre", label = "Chevre", amount = 1, visual = "chevre_round" }
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
        oven = { dict = "amb@prop_human_bbq@male@idle_a", name = "idle_b" },
        fryer = { dict = "amb@prop_human_bbq@male@idle_a", name = "idle_b" },
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
        "pizza_margherita", "pizza_pepperoni", "pizza_champignon", "pizza_4fromages",
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
        pizzeria = {
            label = "Pizzeria",
            Machine = { coords = vector3(810.61, -764.49, 26.78), heading = 242.56, radius = 1.0 },
            OvenStation = {
                center = vector3(813.25, -752.97, 26.78),
                radius = 0.9,
                duration = 7000,
                slots = {
                    left = { pos = vector3(813.34, -752.54, 26.78), heading = 265.74 },
                    right = { pos = vector3(813.33, -753.33, 26.78), heading = 268.96 }
                }
            },
            FryerStation = {
                center = vector3(807.65, -761.34, 26.78),
                radius = 0.9,
                duration = 5000,
                slots = {
                    left = { pos = vector3(807.62, -760.97, 26.78), heading = 270.12 },
                    right = { pos = vector3(807.68, -761.70, 26.78), heading = 264.69 }
                }
            },
            CraftingTable = {
                radius = 0.7,
                slots = {
                    slot1 = { pos = vector3(807.20, -757.49, 26.78), heading = 357.20 },
                    slot2 = { pos = vector3(808.16, -757.50, 26.78), heading = 3.19 }
                }
            },
            MilkshakeStation = {
                radius = 0.7,
                slots = {
                    slot1 = { pos = vector3(808.64, -764.53, 26.78), heading = 185.78 }
                }
            }
        }
    }
}
