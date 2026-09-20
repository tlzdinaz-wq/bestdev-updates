Config = {}

Config.From             = 0     -- Starting progress percentage
Config.To               = 100   -- Ending progress percentage

Config.Async            = true  -- Whether to run the progress bar asyncronously

Config.Duration         = 5000
Config.Label            = "Loading..."
Config.LabelPosition    = "bottom"

Config.Color            = "rgba(114, 99, 238, 0.95)"    -- Progress bar colour (violet EVE #7263EE)
Config.BGColor          = "rgba(0, 0, 0, 0.3)"          -- Progress background colour
Config.ZoneColor        = "rgba(114, 99, 238, 0.8)"     -- Minigame Zone colour

Config.x            = 0.5 -- Horizontal position
Config.y            = 0.5 -- Vertical position

Config.Rotation     = 0         -- Rotation angle of dial
Config.MaxAngle     = 360       -- Max arc in degrees - 360 will be a full circle, 90 will be a quarter of a circle, etc
Config.Radius       = 40        -- Radius of the radial dial (reduced from 60)
Config.Stroke       = 7         -- stroke width of the radial dial (reduced from 10)
Config.Width        = 250       -- Width of the linear bar (reduced from 300)
Config.Height       = 30        -- Height of the linear bar (reduced from 40)
Config.Cap          = 'butt'    -- or 'round'
Config.Padding      = 0         -- Backgound bar padding
Config.CancelKey    = 178       -- Key used for cancelling progress

Config.ShowTimer    = true  -- Shows the timer countdown withing the dial
Config.ShowProgress = false -- Shows the progress within the dial

Config.Easing       = "easeLinear" -- The easing used for the dial animation - see rprogress/ui/js/easings.js

Config.DisableControls = {
    Mouse           = false,    -- Disable mouse controls until progress is complete
    Player          = false,    -- Disable player movement until progress is complete
    Vehicle         = false     -- Disable vehicle control until progress is complete
}

Config.onStart      = function()end
Config.onComplete   = function()end

Config.MiniGameOptions = {
    MaxAngle = 240,
    Rotation = -120,
    Radius = 100,
    Stroke = 30,    
    Difficulty = {
        Custom = {
            Zone = 40,         -- The percentage of the dial that is the trigger zone (lower = harder)
            Duration = 1000    -- Time in milliseconds for the dial to fill in one direction (lower = harder)
        },
        Easy = {
            Zone = 30,
            Duration = 500
        },
        Medium = {
            Zone = 20,
            Duration = 500
        },
        Hard = {
            Zone = 10,
            Duration = 500
        }      
    }      
}