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

--- Raccourci : /musique ouvre le lecteur, où qu'on soit.
RegisterCommand("musique", function()
    VFW.OpenMediaPlayer("commande")
end, false)

TriggerEvent("chat:addSuggestion", "/musique", "Ouvrir le lecteur de musique (objet ou vehicule le plus proche)")
