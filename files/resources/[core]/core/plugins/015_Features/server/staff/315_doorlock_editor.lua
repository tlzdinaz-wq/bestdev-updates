---@meta _
---@diagnostic disable: duplicate-doc-field

-- Ouverture de l'éditeur ox_doorlock depuis le menu staff.
--
-- Le menu (Builders > DOORLOCK) déclenche `ox_doorlock:openEditor`, un événement qui
-- n'existe nulle part : ni dans la base, ni dans ox_doorlock. Les deux boutons d'ouverture
-- de l'éditeur ne faisaient donc rien.
--
-- Et même en passant par la commande `/doorlock` de la ressource, rien n'aboutissait : son
-- éditeur et son enregistrement sont protégés par l'ace FiveM `command.doorlock`
-- (Config.CommandPrincipal = group.admin), que le staff de la base n'a pas — ses droits
-- vivent dans le système de permissions du serveur, pas dans les aces.
--
-- On fait donc le pont : le staff qui possède `doorlock_builder` reçoit l'ace le temps de sa
-- session, puis l'éditeur est ouvert chez lui. L'ace est retiré à la déconnexion pour qu'il
-- ne reste pas attaché à un identifiant de session réutilisé par un autre joueur.

local PERM = "doorlock_builder"
local granted = {}

local function grantAce(source)
    if granted[source] then return end
    granted[source] = true
    ExecuteCommand(("add_ace player.%d command.doorlock allow"):format(source))
end

local function revokeAce(source)
    if not granted[source] then return end
    granted[source] = nil
    ExecuteCommand(("remove_ace player.%d command.doorlock allow"):format(source))
end

RegisterNetEvent("ox_doorlock:openEditor", function(closest)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if not xPlayer.hasPermission(PERM) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Doorlock",
            message = "Vous n'avez pas la permission de gérer les portes.",
        })
        return
    end

    grantAce(source)

    -- L'ace est appliqué de façon asynchrone par le serveur : on laisse passer un instant
    -- avant d'ouvrir, sinon l'enregistrement de la porte serait refusé.
    SetTimeout(250, function()
        if not GetPlayerName(source) then return end
        TriggerClientEvent("ox_doorlock:triggeredCommand", source, closest and true or nil)
    end)
end)

AddEventHandler("playerDropped", function()
    revokeAce(source)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for source in pairs(granted) do
        ExecuteCommand(("remove_ace player.%d command.doorlock allow"):format(source))
    end
    granted = {}
end)
