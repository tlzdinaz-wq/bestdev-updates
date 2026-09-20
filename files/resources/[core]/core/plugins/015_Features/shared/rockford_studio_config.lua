--[[
    Rockford Studio - Configuration
    Studio musical avec DAW, enregistrement et création d'items USB/CD

    Pour ajouter un nouveau studio:
    1. Ajouter une entrée dans Config.Studios avec les coordonnées
    2. (Optionnel) Restreindre l'accès avec requiredJob
]]

Config = Config or {}

Config.RockfordStudio = {
    -- Liste des studios (ajouter autant que nécessaire)
    Studios = {
        {
            id = "rockford_main",
            name = "Rockford Recording Studio",
            coords = vector3(-1048.45, -220.57, 36.92),
            -- Table de mixage pour l'ingenieur son (mode STUDIO)
            mixingTable = {
                coords = vector3(-1045.80, -222.10, 36.92),
            },
            blip = {
                enabled = true,
                sprite = 614,  -- Music icon
                color = 5,     -- Yellow
                scale = 0.5
            },
            -- Laisser nil pour accès public, ou spécifier un job
            requiredJob = nil,  -- ex: "musician" ou { "musician", "producer" }
            -- Zone d'écoute live (rayon autour du studio)
            liveZoneRadius = 15.0
        },
        -- Exemple d'un second studio réservé
        -- {
        --     id = "vinewood_studio",
        --     name = "Vinewood Sound Studio",
        --     coords = vector3(123.45, -456.78, 30.0),
        --     heading = 90.0,
        --     blip = {
        --         enabled = true,
        --         sprite = 614,
        --         color = 2,
        --         scale = 0.8
        --     },
        --     requiredJob = "musician",
        --     liveZoneRadius = 20.0
        -- }
    },

    -- Paramètres de l'interaction
    Interaction = {
        distance = 2.0,  -- Distance pour interagir avec le point
        key = 38,        -- E key
        helpText = "Appuyer sur ~INPUT_CONTEXT~ pour ouvrir le studio"
    },

    -- Paramètres live streaming
    LiveStream = {
        enabled = true,
        -- Intervalle de sync des joueurs dans la zone (ms)
        syncInterval = 2000,
        -- Volume par défaut pour les auditeurs
        defaultVolume = 0.7
    },

    -- URLs autorisées (patterns Lua)
    AllowedUrlPatterns = {
        "^https?://[%w%-]+%.youtube%.com/",
        "^https?://youtu%.be/",
        "^https?://music%.youtube%.com/",
        "^https?://[%w%-]+%.soundcloud%.com/",
        "^https?://soundcloud%.com/",
        -- Liens audio directs (domaines populaires seulement)
        "^https?://cdn%.discordapp%.com/.+%.mp3",
        "^https?://cdn%.discordapp%.com/.+%.wav",
        "^https?://cdn%.discordapp%.com/.+%.ogg",
        "^https?://media%.discordapp%.net/.+%.mp3",
        "^https?://i%.scdn%.co/",
        "^https?://files%.catbox%.moe/.+%.mp3",
        "^https?://files%.catbox%.moe/.+%.wav",
        "^https?://files%.catbox%.moe/.+%.ogg"
    }
}

-- Helper: Vérifier si une URL est valide
function Config.RockfordStudio.IsValidUrl(url)
    if not url or type(url) ~= "string" or url == "" then
        return false
    end

    if #url > 500 then
        return false
    end

    for _, pattern in ipairs(Config.RockfordStudio.AllowedUrlPatterns) do
        if url:match(pattern) then
            return true
        end
    end

    return false
end

-- Helper: Vérifier si un joueur peut accéder à un studio
function Config.RockfordStudio.CanAccessStudio(xPlayer, studio)
    if not studio.requiredJob then
        return true
    end

    local playerJob = xPlayer.getJob()
    if not playerJob then
        return false
    end

    if type(studio.requiredJob) == "table" then
        for _, job in ipairs(studio.requiredJob) do
            if playerJob.name == job then
                return true
            end
        end
        return false
    else
        return playerJob.name == studio.requiredJob
    end
end
