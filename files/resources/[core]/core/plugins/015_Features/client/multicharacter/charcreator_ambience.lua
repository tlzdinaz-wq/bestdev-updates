---@meta _
---@diagnostic disable: duplicate-doc-field

-- Ambiance de l ecran de creation de personnage (musique).
--
-- L ecran de selection et le createur sont deux interfaces distinctes qui se succedent :
-- la musique ne peut donc pas vivre dans l une des deux, elle serait coupee au passage de
-- l une a l autre. Elle est tenue par un petit lecteur pose a cote du bundle NUI
-- (interface/build/skin/char-music.js), que l on allume a l arrivee sur la selection et
-- que l on eteint une fois le joueur en jeu.
--
-- Les reglages viennent du hub Gestion > Serveur > Creation de personnage.

local DEFAULTS <const> = {
    musicEnabled = false,
    musicUrl = "",
    musicVolume = 30,
    slots = 2,
    vipSlotFrom = 2,
}

local cached = nil

-- L ecran est ouvert : de l arrivee sur la selection jusqu a l entree en jeu.
local onScreen = false

local Ambience = {}

--- Reglages recus du serveur.
---
--- Ils arrivent avec la liste des personnages, dans le meme message : l ecran s affiche
--- pendant la connexion, un aller-retour de callback a ce moment-la le retarderait de
--- plusieurs secondes si le serveur est charge.
function Ambience.Put(settings)
    if type(settings) ~= "table" then return end
    cached = settings
end

--- Ce que l on sait, sans jamais attendre.
---
--- Si rien n est encore arrive (rechargement de la ressource seule, par exemple), on rend
--- les valeurs d origine tout de suite et on demande la vraie reponse a cote.
function Ambience.Get()
    if cached then return cached end

    CreateThread(function()
        local ok, res = pcall(TriggerServerCallback, "charCreator:getSettings")
        if ok and type(res) == "table" then cached = res end
    end)

    return DEFAULTS
end

--- Envoie au lecteur ce que disent les reglages du moment.
local function apply()
    local settings = Ambience.Get()

    if settings.musicEnabled ~= true or tostring(settings.musicUrl or "") == "" then
        SendNUIMessage({ action = "nui:charmusic", data = { play = false } })
        return
    end

    SendNUIMessage({
        action = "nui:charmusic",
        data = {
            play = true,
            url = tostring(settings.musicUrl),
            volume = tonumber(settings.musicVolume) or DEFAULTS.musicVolume,
        },
    })
end

function Ambience.Start()
    onScreen = true
    apply()
end

function Ambience.Stop()
    if not onScreen then return end
    onScreen = false
    SendNUIMessage({ action = "nui:charmusic", data = { play = false } })
end

VFW.CharCreatorAmbience = Ambience

-- Le hub pousse les reglages a l enregistrement. Un joueur encore sur l ecran suit le
-- changement tout de suite : volume, morceau, et meme l activation d une musique qui
-- etait coupee quand il est arrive.
RegisterNetEvent("charCreator:settings", function(settings)
    if type(settings) ~= "table" then return end
    cached = settings
    if onScreen then apply() end
end)
