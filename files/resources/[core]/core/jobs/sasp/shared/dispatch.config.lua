Config = Config or {}

Config.ESXExport = "es_extended"

Config.OpenKey = "F9"

Config.AllowedJobs = {
    police = true,
    sheriff = true
}

Config.JobLabels = {
    police   = "SASP SUD",
    sheriff  = "SASP NORD",
}

Config.GroupCodes = {
    {
        code  = "N/A",
        color = "#00000083"
    },
    {
        code  = "10-6",
        color = "#ff0101ff"
    },
    {
        code  = "CODE 7",
        color = "#7dc990ff"
    },
}

Config.JobBlips = {
    police = {
        color = 3,
        sprites = {
            car  = 56,
            moto = 226,
            bike = 38,
            heli = 43,
            boat = 427,
        }
    },

    sheriff = {
        color = 29,
        sprites = {
            car  = 56,
            moto = 226,
            bike = 38,
            heli = 43,
            boat = 427,
        }
    },
}

Config.TrackedVehicles = {
    
    default = {
    },

    police = {
        { model = "polbuffalop",  sprite = 56, color = 3 },
        { model = "polbuffalop2", sprite = 56, color = 3 },
        { model = "bcpd10",       sprite = 56, color = 3 },
        { model = "policejpheli", sprite = 43, color = 3 },
        { model = "bufsxtrafpol", sprite = 56, color = 3 },
        { model = "coach2", sprite = 56, color = 3 },
        { model = "command", sprite = 56, color = 3 },
        { model = "gwarden7", sprite = 427, color = 3 },
        { model = "gwarden8", sprite = 427, color = 3 },
        { model = "halfback2", sprite = 56, color = 3 },
        { model = "hazard2", sprite = 56, color = 3 },
        { model = "maverick2", sprite = 43, color = 3 },
        { model = "nscouttrafpol", sprite = 56, color = 3 },
        { model = "polalamop2", sprite = 56, color = 3 },
        { model = "polcarap", sprite = 56, color = 3 },
        { model = "polfugitivep", sprite = 56, color = 3 },
        { model = "policebretro", sprite = 226, color = 3 },
        { model = "polscoutp", sprite = 56, color = 3 },
        { model = "polspeedop", sprite = 56, color = 3 },
        { model = "polstalkerp", sprite = 56, color = 3 },
        { model = "polstanierp", sprite = 56, color = 3 },
        { model = "poltorencep", sprite = 56, color = 3 },
        { model = "swatinsur", sprite = 56, color = 3 },
        { model = "swatstoc", sprite = 56, color = 3 },
        { model = "swatvanr2", sprite = 56, color = 3 },
        { model = "trualamo3", sprite = 56, color = 3 },
        { model = "umkalamo", sprite = 56, color = 3 },
    },

    sheriff = {
        { model = "saspbuffalop",  sprite = 56, color = 29 },
        { model = "saspbuffalop2", sprite = 56, color = 29 },
        { model = "swatinsur", sprite = 56, color = 29 },
        { model = "swatstoc", sprite = 56, color = 29 },
        { model = "swatvanr2", sprite = 56, color = 29 },
        { model = "trualamo3", sprite = 56, color = 29 },
        { model = "umkalamo", sprite = 56, color = 29 },
        { model = "saspfelon10", sprite = 56, color = 29 },
        { model = "bufsxtrafpol", sprite = 56, color = 29 },
        { model = "saspcoach2", sprite = 56, color = 29 },
        { model = "saspcommand", sprite = 56, color = 29 },
        { model = "saspgwarden7", sprite = 427, color = 29 },
        { model = "saspgwarden8", sprite = 427, color = 29 },
        { model = "halfback2", sprite = 56, color = 29 },
        { model = "hazard2", sprite = 56, color = 29 },
        { model = "saspmaverick2", sprite = 43, color = 29 },
        { model = "nscouttrafpol", sprite = 56, color = 29 },
        { model = "saspalamop2", sprite = 56, color = 29 },
        { model = "saspbretro", sprite = 226, color = 29 },
        { model = "saspcarap", sprite = 56, color = 29 },
        { model = "saspfugitivep", sprite = 56, color = 29 },
        { model = "saspjpheli", sprite = 43, color = 29 },
        { model = "saspscoutp", sprite = 56, color = 29 },
        { model = "saspspeedop", sprite = 56, color = 29 },
        { model = "saspstalkerp", sprite = 56, color = 29 },
        { model = "saspstanierp", sprite = 56, color = 29 },
        { model = "sasptorencep", sprite = 56, color = 29 },
        { model = "saspswatstoc", sprite = 56, color = 29 },
    },
}

Config.AdvancedSearchPalettes = {
    {
        color1 = "rgba(0, 0, 0, 0.51)",
        color2 = "#00000083",
    },
    {
        color1 = "#00000083",
        color2 = "rgba(194, 115, 12, 0.75)",
    },
    {
        color1 = "#00000083",
        color2 = "rgba(170, 22, 22, 0.75)",
    },
    {
         color1 = "#00000083",
         color2 = "rgba(50, 122, 17, 0.75)",
    },
}

Config.Bracelet = {
    Mode = "clothes",

    Clothes = {
        male = {
            componentKey = "accessories",
            drawable     = 11,
            texture      = 0,
        },
        female = {
            componentKey = "accessories",
            drawable     = 8,
            texture      = 0,
        },
        Clear = {
            componentKey = "accessories",
            drawable     = 0,
            texture      = 0,
        }
    },

    Prop = {
        model = "prop_el_monitor",
        bone  = 14201,
        pos   = vector3(0.03, 0.0, -0.02),
        rot   = vector3(0.0, 90.0, 0.0),
    }
}

Config.BraceletPingBlip = {
    sprite = 161,
    color  = 1,
    scale  = 0.5,
    label  = "Bracelet électronique"
}