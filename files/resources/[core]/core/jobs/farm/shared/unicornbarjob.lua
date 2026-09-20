---
--- Job: Unicorn Bar
--- Type: Farm Job (Harvest → Process → Sell)
---

UnicornBarConfig = {
    -- Points de récolte
    harvest = {
        vector3(2599.07, 4433.61, 39.33),
    },

    -- Zones de transformation (par type d'item)
    processing = {
        ["barley"] = vec3(942.19, -2161.63, 30.19)
    },

    -- Items du job
    items = {
        harvest = {
            "barley"        -- Orge (1 seul type pour unicorn)
        },
        process = {
            ["barley"] = "biere_unicorn"  -- Orge → Biere Unicorn
        }
    }
}
