Config.diving = {
    maskDuration = 20,
    zones = {
        ["diving_1"] = {
            position = vec3(-1287.45, 5782.33, -8.5),
            spawns = {
                vec3(-1382.23, 5813.55, -32.77),
                vec3(-1432.24, 5794.28, -34.43),
                vec3(-1350.34, 5763.18, -29.89),
                vec3(-1296.06, 5745.92, -9.97),
                vec3(-1070.65, 5860.41, -11.25),
                vec3(-1177.66, 6029.50, -8.47),
                vec3(-1590.29, 5926.93, -146.97),
                vec3(-1829.29, 5651.89, -69.20),
                vec3(-1407.64, 5514.29, -5.25),
                vec3(-1271.64, 5981.32, -27.53)
            },
            objectsModels = {
                `h4_prop_h4_gold_coin_01a`,
                `gr_prop_gr_adv_case`,
                `prop_ld_gold_chest`
            },
            rewards = {
                [`gr_prop_gr_adv_case`] = "sunken_crate",
                [`h4_prop_h4_gold_coin_01a`] = "rusty_gold_coin",
                [`prop_ld_gold_chest`] = "ancient_relic"
            },
            maxObjects = 10
        },
        ["diving_2"] = {
            position = vec3(2196.35, -2793.75, 5.93),
            spawns = {
                vec3(2241.65, -3057.84, -151.41),
                vec3(2221.97, -2525.17, -22.50),
                vec3(2452.79, -2651.37, -141.26),
                vec3(2429.50, -2890.64, -67.95),
                vec3(2148.78, -2958.18, -90.63),
                vec3(2167.41, -3054.00, -136.07),
                vec3(2023.14, -2919.43, -35.96),
                vec3(1929.80, -2724.90, -26.73),
                vec3(2142.66, -2404.47, -4.56),
                vec3(2378.97, -2654.13, -72.31),
                vec3(2083.44, -2773.97, -44.03)
            },
            objectsModels = {
                `h4_prop_h4_gold_coin_01a`,
                `gr_prop_gr_adv_case`,
                `prop_ld_gold_chest`
            },
            rewards = {
                [`gr_prop_gr_adv_case`] = "sunken_crate",
                [`h4_prop_h4_gold_coin_01a`] = "rusty_gold_coin",
                [`prop_ld_gold_chest`] = "ancient_relic"
            },
            maxObjects = 10
        }
    },
    sellers = {},
    items = {
        {
            name = "ancient_relic",
            price = 300
        },
        {
            name = "rusty_gold_coin",
            price = 150
        },
        {
            name = "sunken_crate",
            price = 100
        }
    }
}

CreateThread(function()
    if IsDuplicityVersion() then
        return
    end

    while not PolyZone do
        Wait(100)
    end

    Config.diving.zones["diving_1"]["zone"] = CircleZone:Create(vector3(-1247.33, 5746.09, -3.86), 400.0, {
        name = "diving_1",
        useZ = false,
    })

    Config.diving.zones["diving_2"]["zone"] = CircleZone:Create(vector3(2196.35, -2793.75, 5.93), 400.0, {
        name = "diving_2",
        useZ = false,
    })
end)
