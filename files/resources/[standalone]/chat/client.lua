-- Chat du serveur — client.
-- Touche T (rebindable : Paramètres > Touches > FiveM > « Ouvrir le chat »).
-- API compatible avec la ressource `chat` de cfx : chat:addMessage, chat:addTemplate,
-- chat:addSuggestion(s), chat:removeSuggestion, chat:clear.

local open = false
-- État conservé côté Lua : la page NUI peut se charger avant ou après les scripts
-- (course au démarrage) ; elle le réclame via chat:loaded et le reçoit d'un bloc.
local suggestions = {}
local templates = {}
local brand = nil

local function nui(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function setOpen(state)
    if open == state then return end
    open = state
    SetNuiFocus(state, state)
    nui(state and "chat:open" or "chat:close")
end

-- ── Ouverture (T) ─────────────────────────────────────────────
RegisterCommand("chatopen", function()
    if open or IsPauseMenuActive() or IsNuiFocused() then return end
    setOpen(true)
end, false)
RegisterKeyMapping("chatopen", "Ouvrir le chat", "keyboard", "T")

RegisterNUICallback("chat:close", function(_, cb)
    cb({ ok = true })
    open = false
    SetNuiFocus(false, false)
end)

RegisterNUICallback("chat:send", function(data, cb)
    cb({ ok = true })
    local message = data and data.message
    if type(message) ~= "string" then return end
    message = message:gsub("^%s+", ""):gsub("%s+$", "")
    if message == "" then return end
    if message:sub(1, 1) == "/" then
        local cmd = message:sub(2)
        if cmd ~= "" then ExecuteCommand(cmd) end
        return
    end
    TriggerServerEvent("_chat:messageEntered", GetPlayerName(PlayerId()), { 255, 255, 255 }, message)
end)

-- ── API (événements locaux + réseau) ───────────────────────────
RegisterNetEvent("chat:addMessage", function(message)
    nui("chat:addMessage", message)
end)

RegisterNetEvent("chat:addTemplate", function(id, template)
    if id == nil then return end
    templates[tostring(id)] = template
    nui("chat:addTemplate", { id = id, template = template })
end)

local function keyOf(name)
    name = tostring(name or "")
    if name:sub(1, 1) ~= "/" then name = "/" .. name end
    return name:lower()
end

RegisterNetEvent("chat:addSuggestion", function(name, help, params)
    if type(name) ~= "string" then return end
    local s = { name = name, help = help, params = params }
    suggestions[keyOf(name)] = s
    nui("chat:addSuggestion", s)
end)

RegisterNetEvent("chat:addSuggestions", function(list)
    if type(list) ~= "table" then return end
    for _, s in ipairs(list) do
        if type(s) == "table" and type(s.name) == "string" then suggestions[keyOf(s.name)] = s end
    end
    nui("chat:addSuggestions", list)
end)

RegisterNetEvent("chat:removeSuggestion", function(name)
    suggestions[keyOf(name)] = nil
    nui("chat:removeSuggestion", { name = name })
end)

RegisterNetEvent("chat:clear", function()
    nui("chat:clear")
end)

-- Couleurs / nom de marque : core les diffuse (branding_nui.lua) à chaque mise à jour.
AddEventHandler("core:vui:setBranding", function(payload)
    if type(payload) ~= "table" then return end
    brand = { primary = payload.primary, primaryLight = payload.primaryLight, name = payload.name, logo = payload.logo }
    nui("chat:brand", brand)
end)

-- Commandes enregistrées côté client : proposées sans aide (comme la ressource cfx).
local function refreshCommands()
    local list = {}
    for _, cmd in ipairs(GetRegisteredCommands()) do
        local n = cmd.name
        -- on ne remplace jamais une suggestion déjà décrite (aide / paramètres du serveur)
        if n and n:sub(1, 1) ~= "+" and n:sub(1, 1) ~= "-" and n:sub(1, 1) ~= "_" and not suggestions[keyOf(n)] then
            local s = { name = "/" .. n, help = "", params = {} }
            suggestions[keyOf(n)] = s
            list[#list + 1] = s
        end
    end
    if #list > 0 then nui("chat:addSuggestions", list) end
end

RegisterNUICallback("chat:loaded", function(_, cb)
    local list = {}
    for _, s in pairs(suggestions) do list[#list + 1] = s end
    cb({ ok = true, open = open, suggestions = list, templates = templates, brand = brand })
    refreshCommands()
    -- redemande le branding à core (s'il tourne, il répond par core:vui:setBranding)
    TriggerServerEvent("core:branding:request")
end)

AddEventHandler("onClientResourceStart", function(res)
    if res == GetCurrentResourceName() then
        -- (re)démarrage du chat après core : on redemande au serveur la liste des commandes
        -- décrites (aide + paramètres) que core nous renvoie via chat:addSuggestions.
        SetTimeout(1000, function()
            refreshCommands()
            TriggerServerEvent("vfw:command:clientReady")
        end)
        return
    end
    SetTimeout(500, refreshCommands)
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    if open then SetNuiFocus(false, false) end
end)
