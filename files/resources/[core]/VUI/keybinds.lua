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

-- Single thread handling both up/down navigation (avoids two Wait(0) threads running simultaneously)
CreateThread(function()
    local timerUp = 0
    local timerDown = 0
    local holdUp = 0
    local holdDown = 0
    while true do
        if not VUI_CurrentMenu or VUI_HubMode then
            Wait(300)
        else
            Wait(0)

            -- UP
            if IsControlJustPressed(0, 172) or IsDisabledControlJustPressed(0, 172) then
                SendNUIMessage({ action = "vui:menu:up" })
            end
            if IsControlPressed(0, 172) or IsDisabledControlPressed(0, 172) then
                timerUp = timerUp + 1
                if timerUp > 35 then
                    holdUp = holdUp + 1
                    SendNUIMessage({ action = "vui:menu:up" })
                    local delay = 200
                    if holdUp > 120 then
                        delay = math.max(75, 200 - math.floor((holdUp - 120) / 30) * 25)
                    end
                    Wait(delay)
                end
            else
                timerUp = 0
                holdUp = 0
            end

            -- DOWN
            if IsControlJustPressed(0, 173) or IsDisabledControlJustPressed(0, 173) then
                SendNUIMessage({ action = "vui:menu:down" })
            end
            if IsControlPressed(0, 173) or IsDisabledControlPressed(0, 173) then
                timerDown = timerDown + 1
                if timerDown > 35 then
                    holdDown = holdDown + 1
                    SendNUIMessage({ action = "vui:menu:down" })
                    local delay = 200
                    if holdDown > 120 then
                        delay = math.max(75, 200 - math.floor((holdDown - 120) / 30) * 25)
                    end
                    Wait(delay)
                end
            else
                timerDown = 0
                holdDown = 0
            end
        end
    end
end)

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

-- Remet le curseur VUI après fermeture d'une UI core (screenshot, etc.)
AddEventHandler("vui:restoreFocus", function()
    if VUI_HubMode or not VUI_CurrentMenu or not VUI_CurrentMenu.opened then return end
    SetNuiFocus(true, true)
end)
