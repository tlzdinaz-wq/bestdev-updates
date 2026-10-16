---@meta _
---@diagnostic disable: duplicate-doc-field

-- Diffusion des blips d'entreprise.
--
-- Chaque société peut définir un blip (Builder > Modifier un métier > Gestion Blip). Côté
-- client, il n'était créé qu'à partir de la société du métier du joueur : seuls les employés
-- voyaient le blip de leur propre entreprise, jamais celui des autres. Un commerce posé sur
-- la carte était donc invisible pour ses clients.
--
-- On envoie ici la liste de tous les blips activés à tout le monde, au chargement et à
-- chaque modification d'une société.

--- Liste des blips à afficher, lue dans les sociétés chargées.
---@return table[]
local function blipList()
    local out = {}

    for name, society in pairs(VFW.Society.GetAll()) do
        local blip = society.blip

        if type(blip) == "table" and blip.enabled then
            local position = blip.position

            if type(position) == "table" and tonumber(position.x) and tonumber(position.y) then
                out[#out + 1] = {
                    name = name,
                    label = (blip.name ~= nil and blip.name ~= "" and blip.name) or society.label or name,
                    x = tonumber(position.x) + 0.0,
                    y = tonumber(position.y) + 0.0,
                    z = tonumber(position.z) or 0.0,
                    sprite = tonumber(blip.sprite) or 1,
                    color = tonumber(blip.color) or 0,
                    scale = tonumber(blip.scale) or 0.5,
                }
            end
        end
    end

    return out
end

--- Envoie la liste à un joueur, ou à tout le monde si `target` est absent.
---@param target number|nil
function VFW.Society.SendBlips(target)
    TriggerClientEvent("core:society:blips", target or -1, blipList())
end

RegisterNetEvent("core:society:requestBlips", function()
    VFW.Society.SendBlips(source)
end)

-- Création, modification ou suppression d'un métier : tout le monde met sa carte à jour.
AddEventHandler("vfw:society:updated", function()
    VFW.Society.SendBlips()
end)

AddEventHandler("vfw:society:loaded", function()
    VFW.Society.SendBlips()
end)

--- Rafraîchissement manuel (console) après une modification directe en base.
---
--- Les modules sont chargés AVANT le registre de commandes
--- (plugins/000_framework/server/001_command_sync.lua) : `VFW.RegisterCommand` n'existe pas
--- encore à ce moment-là. On attend donc qu'il soit disponible, comme le fait la garde des
--- callbacks (modules/event/server/210_callback_guard.lua).
CreateThread(function()
    while type(VFW.RegisterCommand) ~= "function" do Wait(100) end

    VFW.RegisterCommand("refreshblips", "server_management", function(source)
        VFW.Society.SendBlips()

        if source and source > 0 then
            local xPlayer = VFW.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF", variant = "SUCCESS", subtitle = "Entreprises",
                    message = ("%d blip(s) d'entreprise renvoyé(s)."):format(#blipList()),
                })
            end
        end
    end, {
        help = "Renvoyer les blips d'entreprise à tous les joueurs",
        allowConsole = true,
    })
end)
