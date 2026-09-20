CbdShopConfig = {
    entityPlant = {
        "870605061",
        "8270083",
        "716763602"
    },
    plants  = {
        vec3(166.53, -242.42, 49.06)
    },
    processing = {
        ["cbd_oil"] = vec3(165.23, -233.35, 49.06),
        ["cannabis_flower"] = vec3(165.63, -234.94, 49.06)
    },
    items = {
        harvest = "cbd_leaf",
        processing = {
            "cbd_oil",
            "cannabis_flower"
        }
    },
    crafting = {
        coords = vector4(186.2, -241.66, 53.07, 68.89),
        recipes = {
            {
                name = "bang",
                label = "Bang",
                output = "bang",
                outputQuantity = 1,
                craftTime = 10000,
                ingredients = {
                    { name = "empty_bang", quantity = 1 },
                    { name = "cbd_oil", quantity = 5 },
                }
            },
            {
                name = "bonbon_de_cbd",
                label = "Bonbon de CBD",
                output = "cbd_candy",
                outputQuantity = 1,
                craftTime = 5000,
                ingredients = {
                    { name = "cannabis_flower", quantity = 1 },
                }
            },
            {
                name = "cigarette_electronique_cbd_1ml",
                label = "C-E CBD 1Ml",
                output = "e_cigarette_cbd",
                outputQuantity = 1,
                craftTime = 5000,
                ingredients = {
                    { name = "e_cigarette", quantity = 1 },
                    { name = "cbd_oil", quantity = 1 },
                }
            },
            {
                name = "cigarette_electronique_cbd_2ml",
                label = "C-E CBD 2Ml",
                output = "e_cigarette_cbd_1",
                outputQuantity = 1,
                craftTime = 6000,
                ingredients = {
                    { name = "e_cigarette", quantity = 1 },
                    { name = "cbd_oil", quantity = 2 },
                }
            },
            {
                name = "cigarette_electronique_cbd_5ml",
                label = "C-E CBD 5Ml",
                output = "e_cigarette_cbd_2",
                outputQuantity = 1,
                craftTime = 8000,
                ingredients = {
                    { name = "e_cigarette", quantity = 1 },
                    { name = "cbd_oil", quantity = 5 },
                }
            },
            {
                name = "joint_de_cbd",
                label = "Petit joint de CBD",
                output = "cbd_joint",
                outputQuantity = 1,
                craftTime = 5000,
                ingredients = {
                    { name = "cannabis_flower", quantity = 1 },
                    { name = "paper_joint", quantity = 1 },
                }
            },
            {
                name = "joint_de_cbd_1",
                label = "Joint de CBD",
                output = "cbd_joint_1",
                outputQuantity = 1,
                craftTime = 6000,
                ingredients = {
                    { name = "cannabis_flower", quantity = 2 },
                    { name = "paper_joint", quantity = 1 },
                }
            },
            {
                name = "joint_de_cbd_2",
                label = "Grand joint de CBD",
                output = "cbd_joint_2",
                outputQuantity = 1,
                craftTime = 8000,
                ingredients = {
                    { name = "cannabis_flower", quantity = 5 },
                    { name = "paper_joint", quantity = 1 },
                }
            },
        }
    },
}