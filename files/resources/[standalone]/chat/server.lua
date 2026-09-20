-- Chat du serveur — serveur.
-- Un message sans « / » déclenche l'event `chatMessage` (source, auteur, message) ;
-- s'il n'est pas annulé (CancelEvent), il est diffusé à tout le monde quand
-- `chat_global_messages` vaut "true" (server.cfg), sinon l'auteur est invité à
-- utiliser une commande (/me, /report…).

local MAX_LEN = 256

local function clean(text)
    text = tostring(text or ""):gsub("[\r\n\t]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if #text > MAX_LEN then text = text:sub(1, MAX_LEN) end
    return text
end

RegisterNetEvent("_chat:messageEntered", function(author, color, message)
    local src = source
    message = clean(message)
    if message == "" then return end
    author = clean(author ~= "" and author or GetPlayerName(src) or ("Joueur " .. src)):sub(1, 48)

    TriggerEvent("chatMessage", src, author, message)
    if WasEventCanceled() then return end

    if GetConvar("chat_global_messages", "true") == "true" then
        TriggerClientEvent("chat:addMessage", -1, {
            color = type(color) == "table" and color or { 255, 255, 255 },
            multiline = true,
            args = { author, message },
        })
    else
        TriggerClientEvent("chat:addMessage", src, {
            color = { 255, 159, 67 },
            args = { "Chat", "Les messages libres sont désactivés : utilise une commande (^*/^r pour la liste)." },
        })
    end
end)

-- /say <message> : annonce « Serveur » (console ou ace command.say)
RegisterCommand("say", function(source, args, raw)
    local message = clean(raw:sub(5))
    if message == "" then return end
    local author = source == 0 and "Serveur" or GetPlayerName(source)
    TriggerClientEvent("chat:addMessage", -1, {
        color = { 114, 99, 238 },
        multiline = true,
        args = { author, message },
    })
end, true)

-- /clearchat : vide le chat de tout le monde (console ou ace command.clearchat)
RegisterCommand("clearchat", function()
    TriggerClientEvent("chat:clear", -1)
end, true)
