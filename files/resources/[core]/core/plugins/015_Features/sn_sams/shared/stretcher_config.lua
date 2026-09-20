---@meta _
---@diagnostic disable: duplicate-doc-field

SN_SAMS.Config.Stretcher = {
    Keys = {
        doors = 38, -- [E] (hold)
        take = 73,  -- [X]
        load = 47,  -- [G]
    },

    modelHashes = { "strykerpro" },

    Vehicles = {
        -- BASE VEHICLES

        -- TRUCK
        { modelHash = "ambulance",   dist = 4.5,  xOffset = 0.0,    yOffset = -2.6,   zOffset = -0.165, rotOffset = 0.0,    doors = {"BLD", "BRD"}, powerload = false },
        { modelHash = "brigham",     dist = 4.5,  xOffset = 0.34,   yOffset = -1.9,   zOffset = 0.0,    rotOffset = 0.0,    doors = {"TRUNK"},      powerload = false },

        -- BOAT
        { modelHash = "dinghy2",     dist = 8.0,  xOffset = 0.0,    yOffset = -1.7,   zOffset = 0.23,   rotOffset = -135.0, doors = {},             powerload = false },
        { modelHash = "predator",    dist = 8.0,  xOffset = 0.35,   yOffset = -2.4,   zOffset = -0.3,   rotOffset = 0.0,    doors = {},             powerload = false },

        -- AIRCRAFT
        { modelHash = "annihilator",  dist = 8.0,  xOffset = 0.0,   yOffset = 0.35,   zOffset = -0.1,   rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "annihilator2", dist = 8.0,  xOffset = 0.0,   yOffset = -0.15,  zOffset = -0.1,   rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "buzzard",      dist = 8.0,  xOffset = 0.0,   yOffset = 0.085,  zOffset = 0.0,    rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "buzzard2",     dist = 8.0,  xOffset = 0.0,   yOffset = 0.085,  zOffset = 0.0,    rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "cargobob",     dist = 8.0,  xOffset = 0.65,  yOffset = 0.085,  zOffset = -0.8,   rotOffset = 0.0,    doors = {"BLD"},                  powerload = false },
        { modelHash = "cargobob2",    dist = 8.0,  xOffset = 0.65,  yOffset = 0.085,  zOffset = -0.8,   rotOffset = 0.0,    doors = {"BLD"},                  powerload = false },
        { modelHash = "cargobob3",    dist = 8.0,  xOffset = 0.65,  yOffset = 0.085,  zOffset = -0.8,   rotOffset = 0.0,    doors = {"BLD"},                  powerload = false },
        { modelHash = "cargobob4",    dist = 8.0,  xOffset = 0.65,  yOffset = 0.085,  zOffset = -0.8,   rotOffset = 0.0,    doors = {"BLD"},                  powerload = false },
        { modelHash = "conada",       dist = 8.0,  xOffset = -0.05, yOffset = -0.2,   zOffset = -0.175, rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "maverick",     dist = 8.0,  xOffset = 0.0,   yOffset = 0.1,    zOffset = -0.28,  rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "polmav",       dist = 8.0,  xOffset = 0.0,   yOffset = 1.2,    zOffset = -0.7,   rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "savage",       dist = 8.0,  xOffset = 0.0,   yOffset = 1.5,    zOffset = -0.06,  rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "swift",        dist = 8.0,  xOffset = 0.0,   yOffset = 1.85,   zOffset = -0.27,  rotOffset = -90.0,  doors = {"BLD", "BRD"},           powerload = false },
        { modelHash = "valkyrie",     dist = 8.0,  xOffset = 0.0,   yOffset = 1.075,  zOffset = -0.65,  rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "valkyrie2",    dist = 8.0,  xOffset = 0.0,   yOffset = 1.075,  zOffset = -0.65,  rotOffset = -90.0,  doors = {},                       powerload = false },
        { modelHash = "avenger",      dist = 8.0,  xOffset = 1.0,   yOffset = 2.2,    zOffset = -1.67,  rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "avenger2",     dist = 8.0,  xOffset = 1.0,   yOffset = 2.2,    zOffset = -1.67,  rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "avenger3",     dist = 8.0,  xOffset = 1.0,   yOffset = 2.2,    zOffset = -1.67,  rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "avenger4",     dist = 8.0,  xOffset = 1.0,   yOffset = 2.2,    zOffset = -1.67,  rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "bombushka",    dist = 13.0, xOffset = 1.3,   yOffset = -2.2,   zOffset = -0.58,  rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "streamer216",  dist = 8.0,  xOffset = 0.0,   yOffset = -1.8,   zOffset = -1.24,  rotOffset = -180.0, doors = {"BLD"},                  powerload = false },
        { modelHash = "titan",        dist = 13.0, xOffset = 0.0,   yOffset = -2.2,   zOffset = -0.58,  rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },

        -- ADDON VEHICLES

        -- AIRCRAFT
        { modelHash = "ec145med",     dist = 8.0,  xOffset = -0.27, yOffset = -0.85,  zOffset = -0.829, rotOffset = 0.0,    doors = {"BLD", "BRD"},           powerload = false },
        { modelHash = "aw109",        dist = 8.0,  xOffset = -0.27, yOffset = 0.65,   zOffset = 0.0,    rotOffset = 0.0,    doors = {"BLD", "BRD"},           powerload = false },
        { modelHash = "c3aw139",      dist = 8.0,  xOffset = 0.0,   yOffset = 0.13,   zOffset = -0.215, rotOffset = -90.0,  doors = {"BLD", "BRD"},           powerload = false },
        { modelHash = "gsd11bell",    dist = 8.0,  xOffset = -0.27, yOffset = 0.47,   zOffset = -0.70,  rotOffset = 0.0,    doors = {"BLD", "BRD"},           powerload = false },
        { modelHash = "as365",        dist = 8.0,  xOffset = 0.0,   yOffset = 0.65,   zOffset = -0.9,   rotOffset = -90.0,  doors = {"BLD", "BRD"},           powerload = false },

        -- REDNECK MODIFICATIONS
        { modelHash = "f450ambo",     dist = 4.5,  xOffset = 0.0,   yOffset = -1.5,   zOffset = -0.025, rotOffset = 0.0,    doors = {"TRUNK", "HOOD"},        powerload = true },
        { modelHash = "e450ambo",     dist = 4.5,  xOffset = 0.0,   yOffset = -1.5,   zOffset = -0.025, rotOffset = 0.0,    doors = {"TRUNK", "HOOD"},        powerload = true },
        { modelHash = "20ramambo",    dist = 4.5,  xOffset = 0.0,   yOffset = -1.5,   zOffset = -0.025, rotOffset = 0.0,    doors = {"TRUNK", "HOOD"},        powerload = true },

        -- RIPPLE MODIFICATIONS
        { modelHash = "fordambo",     dist = 4.5,  xOffset = 0.0,   yOffset = -3.85,  zOffset = 0.34,   rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "rambulance",   dist = 4.5,  xOffset = 0.0,   yOffset = -2.8,   zOffset = 0.135,  rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },

        -- PAUL MODIFICATIONS
        { modelHash = "amrexpress",   dist = 4.5,  xOffset = -0.15, yOffset = -1.7,   zOffset = -0.3,   rotOffset = 0.0,    doors = {"BLD", "BRD", "TRUNK"}, powerload = false },
        { modelHash = "cambo",        dist = 4.5,  xOffset = -0.062,yOffset = -2.5,   zOffset = 0.08,   rotOffset = 0.0,    doors = {"TRUNK", "BRD"},         powerload = false },

        -- POKEY DEVELOPMENT
        { modelHash = "f550ambo",     dist = 4.5,  xOffset = 0.0,   yOffset = -3.175, zOffset = 0.445,  rotOffset = 0.0,    doors = {"BLD", "BRD"},           powerload = false },
        { modelHash = "f550ambocc",   dist = 4.5,  xOffset = 0.0,   yOffset = -4.085, zOffset = 0.445,  rotOffset = 0.0,    doors = {"TRUNK", "HOOD"},        powerload = false },

        -- FREEMODE DESIGNS
        { modelHash = "medic12",      dist = 4.5,  xOffset = 0.0,   yOffset = -3.10,  zOffset = 0.22,   rotOffset = 0.0,    doors = {"BRD", "BLD", "HOOD"},   powerload = false },
        { modelHash = "medic22",      dist = 4.5,  xOffset = 0.0,   yOffset = -3.3,   zOffset = -0.15,  rotOffset = 0.0,    doors = {"BRD", "BLD"},           powerload = false },

        -- SHADOW MODIFICATIONS
        { modelHash = "shadowf450ambo", dist = 4.5, xOffset = 0.0,  yOffset = -2.8,   zOffset = 0.382,  rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },

        -- REDSAINT MODIFICATIONS
        { modelHash = "redsaintfordambo", dist = 4.5, xOffset = 0.0, yOffset = -3.10, zOffset = 0.46,   rotOffset = 0.0,    doors = {"BRD", "BLD"},           powerload = false },

        -- ZEAKOR MODIFICATIONS
        { modelHash = "f450",         dist = 4.5,  xOffset = 0.0,   yOffset = -2.5,   zOffset = 0.465,  rotOffset = 0.0,    doors = {"BRD", "BLD"},           powerload = false },

        -- H-VEHICLES SAMS PACK
        { modelHash = "hvsandbulance", dist = 4.5,  xOffset = 0.0,   yOffset = -2.6,   zOffset = -0.165, rotOffset = 0.0,    doors = {"BLD", "BRD"},           powerload = false, stretcherExtra = 2, patientOffset = { x = 0.0, y = -1.3, z = 1.3, rx = 0.0, ry = 0.0, rz = 180.0 } },
        { modelHash = "hvemsnspeedo",  dist = 4.5,  xOffset = 0.0,   yOffset = -2.6,   zOffset = -0.165, rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "hvsamsalamo",   dist = 4.5,  xOffset = 0.0,   yOffset = -2.0,   zOffset = 0.0,    rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "hvsamsaleutian",dist = 4.5,  xOffset = 0.0,   yOffset = -2.0,   zOffset = 0.0,    rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "hvsamsboat",    dist = 8.0,  xOffset = 0.0,   yOffset = -1.7,   zOffset = 0.23,   rotOffset = -135.0, doors = {},                       powerload = false },
        { modelHash = "hvsamsbuff4",   dist = 4.5,  xOffset = 0.0,   yOffset = -2.0,   zOffset = 0.0,    rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "hvsamsterminus",dist = 4.5,  xOffset = 0.0,   yOffset = -2.0,   zOffset = 0.0,    rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "hvsamsscout",   dist = 4.5,  xOffset = 0.0,   yOffset = -2.0,   zOffset = 0.0,    rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "hvsamscara",    dist = 4.5,  xOffset = 0.0,   yOffset = -2.0,   zOffset = 0.0,    rotOffset = 0.0,    doors = {"TRUNK"},                powerload = false },
        { modelHash = "hvconada",      dist = 8.0,  xOffset = -0.05, yOffset = -0.2,   zOffset = -0.175, rotOffset = -90.0,  doors = {},                       powerload = false },
    },
}
