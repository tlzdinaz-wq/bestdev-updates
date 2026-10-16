---@meta _
---@diagnostic disable: duplicate-doc-field

---@class cEntity
cEntity = {}



-- Densité : pilotée par plugins/015_Features/client/world_density.lua depuis
-- Gestion > Serveur > Densité du monde. Le convar `entity_disable_density` sert encore de
-- valeur par défaut au premier démarrage (true = monde vide), ensuite c'est le réglage
-- enregistré qui fait foi.