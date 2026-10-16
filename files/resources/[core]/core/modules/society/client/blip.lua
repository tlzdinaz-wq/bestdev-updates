---@meta _
---@diagnostic disable: duplicate-doc-field

-- Blips des entreprises.
--
-- Historiquement, le blip n'était créé qu'à partir de `Society.data`, c'est-à-dire la
-- société du métier du joueur : seuls les employés de l'entreprise voyaient son blip, et
-- personne d'autre. Un commerce posé sur la carte restait donc invisible pour les clients.
--
-- Le serveur diffuse maintenant la liste de tous les blips activés
-- (modules/society/server/223_society_blips.lua) et c'est elle qui fait foi, pour tout le
-- monde. `Society.initBlip` reste en place — appelée par Society.load — mais ne crée plus
-- rien : elle demande simplement la liste, au cas où la société du joueur vient de changer.

local blips = {}

local function removeAll()
    for name, blip in pairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        blips[name] = nil
    end
end

--- (Re)construit tous les blips d'entreprise à partir de la liste du serveur.
---@param list table[] { name, label, x, y, z, sprite, color, scale, shortRange }
local function apply(list)
    removeAll()

    if type(list) ~= "table" then return end

    for i = 1, #list do
        local entry = list[i]

        if type(entry) == "table" and entry.x and entry.y then
            local blip = AddBlipForCoord(entry.x + 0.0, entry.y + 0.0, (entry.z or 0.0) + 0.0)

            SetBlipSprite(blip, math.floor(tonumber(entry.sprite) or 1))
            SetBlipColour(blip, math.floor(tonumber(entry.color) or 0))
            SetBlipScale(blip, (tonumber(entry.scale) or 0.5) + 0.0)
            SetBlipAsShortRange(blip, entry.shortRange ~= false)
            SetBlipDisplay(blip, 4)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(tostring(entry.label or entry.name or "Entreprise"))
            EndTextCommandSetBlipName(blip)

            blips[entry.name or ("blip_" .. i)] = blip
        end
    end
end

RegisterNetEvent("core:society:blips", apply)

--- Demande la liste au serveur (au chargement du joueur et après toute modification).
local function request()
    TriggerServerEvent("core:society:requestBlips")
end

AddEventHandler("vfw:playerLoaded", function()
    CreateThread(function()
        Wait(2000)
        request()
    end)
end)

AddEventHandler("onClientResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(3000)
        request()
    end)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    removeAll()
end)

function Society.initBlip()
    -- La société du joueur a changé : la liste globale peut contenir de nouvelles entrées
    -- (métier fraîchement créé par le staff), on la redemande.
    request()
end

function Society.unloadBlip()
    -- Les blips d'entreprise ne dépendent plus du métier du joueur : rien à retirer ici.
end
