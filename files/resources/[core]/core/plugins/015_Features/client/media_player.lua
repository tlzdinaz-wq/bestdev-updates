---@meta _

-- Lecteur de médias : la porte d'entrée unique.
--
-- Le lecteur maison — platines DJ et autoradio bâtis sur xsound — décalait le son
-- d'un auditeur à l'autre et s'arrêtait sans raison. Il est remplacé par PMMS,
-- qui synchronise la lecture sur l'horloge du serveur et gère lui-même
-- l'atténuation, les pièces, les vidéos et les écrans.
--
-- PMMS vit **dans le core** : son code est dans plugins/015_Features/{client,server}/media/,
-- ses réglages dans shared/media_01_config.lua, son interface dans interface/pmms/
-- (embarquée dans la page du jeu, une ressource n'ayant qu'une seule page NUI).
--
-- Les points d'entrée de la base — platine, véhicule, boombox, télévision —
-- appellent tous `VFW.OpenMediaPlayer` : changer de lecteur un jour ne demandera
-- de toucher qu'ici.

---@type table<any, number> objets invisibles posés aux points déclarés (platines…)
local mediaPoints = {}

--- Ouvre le lecteur de médias.
---
--- PMMS vise l'objet ou le véhicule le plus proche du joueur : il n'y a rien à
--- lui passer, il faut seulement être à côté de ce qu'on veut faire chanter.
---@param context? string ce qu'on allume, pour le message d'erreur
---@return boolean ouvert
function VFW.OpenMediaPlayer(context)
    -- Le menu contextuel garde le curseur : sans cela, l'interface de PMMS
    -- s'ouvre derriere et on ne peut rien y saisir.
    if VFW.CloseContextMenu then VFW.CloseContextMenu() end
    if VFW.Nui and VFW.Nui.Focus then VFW.Nui.Focus(false, false) end
    Wait(100)

    TriggerEvent("pmms:showControls")
    return true
end

--- Déclare un point du monde comme lecteur de médias.
---
--- Une platine DJ n'est qu'un nom et une position : aucun objet, donc rien que le lecteur
--- puisse faire chanter. Il visait l'objet reconnu le plus proche et n'en trouvait aucun —
--- « la platine n'est pas un lecteur ». On pose donc à l'endroit de la platine un objet
--- invisible d'un modèle que le lecteur connaît, et on inscrit le point dans la liste des
--- lecteurs permanents pour qu'il porte le nom de la platine plutôt que « Boombox ».
---
--- L'objet est local (non réseau), invisible et sans collision : il ne se voit pas, ne gêne
--- pas, et n'existe que chez ce joueur.
---@param key string|number identifiant du point, pour pouvoir le retirer
---@param position vector3
---@param label string|nil nom affiché dans le lecteur
---@return boolean
function VFW.RegisterMediaPoint(key, position, label)
    if key == nil or not position then return false end
    if type(MediaConfig) ~= "table" then return false end

    VFW.RemoveMediaPoint(key)

    local model = `prop_boombox_01`
    if not IsModelInCdimage(model) then return false end

    RequestModel(model)
    local waited = 0
    while not HasModelLoaded(model) and waited < 5000 do
        Wait(50)
        waited = waited + 50
    end
    if not HasModelLoaded(model) then return false end

    local entity = CreateObjectNoOffset(model, position.x, position.y, position.z, false, false, false)
    SetModelAsNoLongerNeeded(model)
    if not entity or entity == 0 then return false end

    SetEntityVisible(entity, false, false)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)

    -- La liste des lecteurs permanents est comparée aux coordonnées réelles de l'objet, au
    -- millimètre près : on inscrit donc ce que le jeu a retenu, pas ce qu'on a demandé.
    local coords = GetEntityCoords(entity)

    MediaConfig.defaultMediaPlayers = MediaConfig.defaultMediaPlayers or {}
    MediaConfig.defaultMediaPlayers[#MediaConfig.defaultMediaPlayers + 1] = {
        position = coords,
        label = label or "Platine",
        _mediaPointKey = key,
    }

    mediaPoints[key] = entity
    return true
end

--- Retire un point déclaré par VFW.RegisterMediaPoint.
---@param key string|number
function VFW.RemoveMediaPoint(key)
    local entity = mediaPoints[key]
    if entity then
        if DoesEntityExist(entity) then DeleteEntity(entity) end
        mediaPoints[key] = nil
    end

    local list = type(MediaConfig) == "table" and MediaConfig.defaultMediaPlayers or nil
    if not list then return end
    for i = #list, 1, -1 do
        if list[i]._mediaPointKey == key then table.remove(list, i) end
    end
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, entity in pairs(mediaPoints) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end)

--- Raccourci : /musique ouvre le lecteur, où qu'on soit.
RegisterCommand("musique", function()
    VFW.OpenMediaPlayer("commande")
end, false)

TriggerEvent("chat:addSuggestion", "/musique", "Ouvrir le lecteur de musique (objet ou vehicule le plus proche)")
