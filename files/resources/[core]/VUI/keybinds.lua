--- Enregistre une touche clavier liée à une commande VUI.
---@param key string Touche GTA (ex: "left", "right", "return", "back")
---@param command string Nom de la commande (préfixé par "+vui_")
---@param name string Label affiché dans les paramètres de touches
---@param callback fun() Fonction appelée quand la touche est pressée
local function Keybind(key, command, name, callback)
    Wait(150)
    RegisterCommand("+vui_" .. command, callback, false)
    RegisterKeyMapping("+vui_" .. command, name, "keyboard", key)
end

-- Navigation événementielle : aucun polling Wait(0) tant qu'une touche n'est pas tenue.
-- Cela retire un thread par-frame de tous les menus VUI ouverts.
local navHeld = { up = false, down = false }

local function RegisterNavigationKey(direction, key, label)
    local pressCommand = "+vui_menu_" .. direction
    local releaseCommand = "-vui_menu_" .. direction

    RegisterCommand(pressCommand, function()
        if not VUI_CurrentMenu or VUI_HubMode or navHeld[direction] then return end

        navHeld[direction] = true
        SendNUIMessage({ action = "vui:menu:" .. direction })

        CreateThread(function()
            Wait(350)
            local repeatCount = 0
            while navHeld[direction] and VUI_CurrentMenu and not VUI_HubMode do
                SendNUIMessage({ action = "vui:menu:" .. direction })
                repeatCount = repeatCount + 1
                Wait(repeatCount > 12 and 75 or 125)
            end
            navHeld[direction] = false
        end)
    end, false)

    RegisterCommand(releaseCommand, function()
        navHeld[direction] = false
    end, false)

    RegisterKeyMapping(pressCommand, label, "keyboard", key)
end

RegisterNavigationKey("up", "up", "Menu haut")
RegisterNavigationKey("down", "down", "Menu bas")

-- Flèche gauche → ◀ sur List/List2/Slider
Keybind("left", "menu_left", "Menu gauche", function()
    if not VUI_CurrentMenu or VUI_HubMode then return end
    SendNUIMessage({
        action = "vui:menu:left"
    })
end)

-- Flèche droite → ▶ sur List/List2/Slider
Keybind("right", "menu_right", "Menu droite", function()
    if not VUI_CurrentMenu or VUI_HubMode then return end
    SendNUIMessage({
        action = "vui:menu:right"
    })
end)

-- Entrée → sélection de l'item courant
Keybind("return", "menu_click_item", "Sélectionner", function()
    if not VUI_CurrentMenu or VUI_HubMode then return end
    SendNUIMessage({
        action = "vui:menu:click"
    })
end)

-- Retour arrière → remonte d'un niveau dans la navigation (via VUI_HandleBack)
Keybind("back", "menu_back", "Retour", function()
    -- Modale screenshot (NUI core) ouverte : Escape ferme la capture, pas le menu staff.
    if LocalPlayer.state.staffScreenshotOpen then
        TriggerEvent("vfw:staff:closeScreenshot")
        return
    end
    if not VUI_CurrentMenu or VUI_HubMode then return end
    VUI_HandleBack()
end)

-- Remet le curseur NUI seulement si un SearchInput VUI était actif (focusState).
-- Ne force PAS SetNuiFocus(true,true) pour un menu RageUI classique.
AddEventHandler("vui:restoreFocus", function()
    if VUI_HubMode or not VUI_CurrentMenu or not VUI_CurrentMenu.opened then return end
    -- Les menus VUI standards n'utilisent pas le focus NUI ; ne rien faire.
end)
