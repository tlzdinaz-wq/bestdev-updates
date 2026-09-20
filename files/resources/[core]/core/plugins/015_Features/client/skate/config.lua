--------------------------------------
-- <!>--    BODHIX | STUDIO     --<!>--
--------------------------------------
--------------------------------------
-- <!>--     SKATE | CAREER     --<!>--
--------------------------------------
-- Support & Feedback: https://discord.gg/PjN7AWqkpF
-- How to: 
-- Use E to Pickup the Skateboard or put in your back 
-- Use G to Ride the Skateboard or put it in you Hand
-- For Tricks, set the Keys in Settings / Key Binding / FiveM
-- You need a the Trigger Event for custom inventory? Use this one: TriggerClientEvent('bodhix-skating:client:start', source, item)

 ConfigNewSkate = {}

 ConfigNewSkate.Debug = false -- True / False for Debug System

 ConfigNewSkate.Framework = "esx" -- Write your Framework: "qb" or "esx" or "vrp" or "custom". 

-- Settings
 ConfigNewSkate.ItemName = 'skateboard'
 ConfigNewSkate.Target = "ox" -- Write your Target System: "qb" or "ox" or "none".
 ConfigNewSkate.TextFont = 4
 ConfigNewSkate.FrameworkResourceName = nil
 ConfigNewSkate.MaxSpeedKmh = 140 -- This does not really change that much unless you get a boost somehow.
 ConfigNewSkate.maxJumpHeigh = 7.0 -- We suggest not to mess to much with this (And yes, you can jump very high).
 ConfigNewSkate.maxFallSurvival = 45.0
 ConfigNewSkate.LoseConnectionDistance = 5.0 -- This is the distance from you to the skateboard (Don't mess with this, unless you know, what you are doing).
 ConfigNewSkate.MinimumSkateSpeed = 1.0
 ConfigNewSkate.MinGroundHeight = 1.0
 ConfigNewSkate.ShowScore = false

 ConfigNewSkate.EnablePeds = true
 ConfigNewSkate.PickupKey = 38
 ConfigNewSkate.ConnectPlayer = 113
 ConfigNewSkate.DesignCount = 18
 ConfigNewSkate.DeckPrice = 1500
 ConfigNewSkate.TrucksPrice = 1000
 ConfigNewSkate.WheelsPrice = 500

 ConfigNewSkate.ModernBack = -0.25 -- Adjust if the Modern Skateboard doesn't fit when you put it in your back.
 ConfigNewSkate.ClassicBack = -0.32 -- Adjust if the Classic Skateboard doesn't fit when you put it in your back (DLC Only).

 ConfigNewSkate.Language = {
    Info = {
        ['controls'] = 'Press E to Pickup | Press G to Ride',
        ['warning'] = 'The Workshop is currently in use by another player.',
        ['purchase'] = 'You have successfully purchased this item!',
        ['failed'] = 'You dont have enough money.',
        ['error'] = 'You already own this Item.'
    },
    Store = {
        ['target'] = 'Open Skate Shop.',
        ['text'] = '[E] Open Skate Shop.'
    },
    Menu = {
        ["equipment"] = "Equipment",
        ["gear"] = "GEAR",
        ["whats_new"] = "WHAT'S NEW",
        ["skateboard"] = "Skateboard",
        ["deck"] = "Deck",
        ["trucks"] = "Trucks",
        ["wheels"] = "Wheels",
        ["purchase"] = "Purchase"
    }
}
 ConfigNewSkate.Coords = {}
 ConfigNewSkate.Shops = { ShopPeds = {} }

Games = {}

Games.EnablePeds = true

-- Coords of Spawning when Minigame Starts
Games.Spawnlocations = {
    BeachPark = {
        x = -1368.0792,
        y = -1396.2998,
        z = 3.4674
    },
    Park = {
        x = -947.6646,
        y = -782.7368,
        z = 15.9212
    }
}

-- NPC For Minigames Spawn Location
Games.skate = {
    BeachParkCoords = {
        x = -1365.0873,
        y = -1417.0070,
        z = 3.6691,
        heading = 97.1605
    },
    ParkCoords = {
        x = -931.6293,
        y = -789.1327,
        z = 15.9210,
        heading = 209.3628
    }
}

Games.SkateSpawn = {
    SkatePeds = {{
        Position = vector4(Games.skate.BeachParkCoords.x, Games.skate.BeachParkCoords.y, Games.skate.BeachParkCoords.z,
            Games.skate.BeachParkCoords.heading),
        Model = 'a_m_m_skater_01',
        Scenario = 'WORLD_HUMAN_YOGA'
    }, {
        Position = vector4(Games.skate.ParkCoords.x, Games.skate.ParkCoords.y, Games.skate.ParkCoords.z,
            Games.skate.ParkCoords.heading),
        Model = 'a_m_m_skater_01',
        Scenario = 'WORLD_HUMAN_MUSCLE_FLEX'
    }}
}

ConfigNewSkate.Skates = {
    {
        id= 1,
        label= VFW.BrandName() .. " Blue",
        model= "board_1",
        price= 500,
        category= 'season',
        image= VFW.CDN.Get("others/board_1.png"),
        levelRequired= 5
    },
    {
        id= 2,
        label= VFW.BrandName() .. " Yellow",
        model= "board_2",
        price= 500,
        category= 'season',
        image= VFW.CDN.Get("others/board_2.png"),
    },
    {
        id= 3,
        label= VFW.BrandName() .. " Red",
        model= "board_3",
        price= 500,
        category= 'season',
        image= VFW.CDN.Get("others/board_3.png"),
    },
}
