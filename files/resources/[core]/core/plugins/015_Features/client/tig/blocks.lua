---@meta _
---@diagnostic disable: duplicate-doc-field

-- TIG System - Command & Feature Blocking
-- Note: Individual commands have TIG guard clauses in their respective files
-- This file only handles event-based blocking (chat, inventory, phone, UI)

-- Block chat messages
RegisterNetEvent('chat:addMessage')
AddEventHandler('chat:addMessage', function(message)
    if IsPlayerInTIG() then
        -- Cancel the event to prevent the message from showing
        CancelEvent()
    end
end)

-- Block chat suggestions
RegisterNetEvent('chat:addSuggestion')
AddEventHandler('chat:addSuggestion', function(name, help, params)
    if IsPlayerInTIG() then
        CancelEvent()
    end
end)

-- Block chat input
RegisterNetEvent('__cfx_internal:serverPrint')
AddEventHandler('__cfx_internal:serverPrint', function(msg)
    if IsPlayerInTIG() then
        CancelEvent()
    end
end)

-- Block player trying to send chat messages
RegisterNetEvent('_chat:messageEntered')
AddEventHandler('_chat:messageEntered', function(author, color, message)
    if IsPlayerInTIG() then
        CancelEvent()
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Le chat est désactivé pendant les TIG"
        })
    end
end)

-- Block inventory opening attempts
RegisterNetEvent('vfw:inventory:open')
AddEventHandler('vfw:inventory:open', function()
    if IsPlayerInTIG() then
        CancelEvent()
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "L'inventaire est désactivé pendant les TIG"
        })
    end
end)

-- Block phone opening attempts
RegisterNetEvent('vfw:phone:open')
AddEventHandler('vfw:phone:open', function()
    if IsPlayerInTIG() then
        CancelEvent()
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Le téléphone est désactivé pendant les TIG"
        })
    end
end)

-- Block emote menu
RegisterNetEvent('vfw:emotes:open')
AddEventHandler('vfw:emotes:open', function()
    if IsPlayerInTIG() then
        CancelEvent()
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les emotes sont désactivées pendant les TIG"
        })
    end
end)

-- Listen for TIG status changes to update UI elements
RegisterNetEvent('vfw:tig:statusChanged')
AddEventHandler('vfw:tig:statusChanged', function(inTIG)
    if inTIG then
        -- Hide UI elements
        SendNUIMessage({
            action = "hideElements",
            data = {
                chat = true,
                phone = true,
                inventory = true
            }
        })
    else
        -- Restore UI elements
        SendNUIMessage({
            action = "showElements",
            data = {
                chat = true,
                phone = true,
                inventory = true
            }
        })
    end
end)

-- Block VUI menu opening
RegisterNetEvent('VUI:Open')
AddEventHandler('VUI:Open', function()
    if IsPlayerInTIG() then
        -- Allow staff menu for players with staff_menu permission
        if VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["staff_menu"] then
            return
        end
        CancelEvent()
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les menus sont désactivés pendant les TIG"
        })
    end
end)

-- Le téléphone (sd-phone) s'ouvre par une commande FiveM (F1 par défaut) : DisableControlAction ne
-- l'atteint pas, contrairement à l'ancienne touche K. On passe donc par son interrupteur
-- d'activation (exports["sd-phone"]:setDisabled), n'agissant qu'aux entrées et sorties de TIG.
do
    local phoneDisabled = false

    AddEventHandler("onClientResourceStart", function(resourceName)
        -- Un redémarrage de sd-phone remet l'interrupteur à zéro.
        if resourceName == "sd-phone" then phoneDisabled = false end
    end)

    CreateThread(function()
        while true do
            local inTig = IsPlayerInTIG() == true

            if inTig ~= phoneDisabled and GetResourceState("sd-phone") == "started" then
                local ok = pcall(function() exports["sd-phone"]:setDisabled(inTig) end)
                if ok then phoneDisabled = inTig end
            end

            Wait(inTig and 500 or 1500)
        end
    end)
end
