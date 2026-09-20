---
--- Job: Bar Billard
--- Type: Farm Job (Harvest → Process → Sell)
---

BillardBarConfig = {
    -- Points de récolte
    harvest = {
        vector3(2599.07, 4433.61, 39.33),
    },

    -- Zone de transformation
    processing = {
        ["barley"] = vec3(939.74, -2173.66, 29.53)
    },

    -- Items du job
    items = {
        harvest = {
            "barley"
        },
        process = {
            ["barley"] = "biere_billard"  -- Orge → Biere Billard
        }
    }
}
