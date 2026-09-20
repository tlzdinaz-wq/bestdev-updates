---@meta _
---@diagnostic disable: duplicate-doc-field

-- Mode développement des interfaces (client local, aucune donnée serveur).
--   /uidev http://localhost:5173  -> les pages NUI (hub gestion, boutique, pause menu,
--                                   HUD, annonces) et les menus VUI sont chargés depuis le
--                                   serveur Vite (rechargement à chaud, sans build)
--   /uidev off                    -> retour aux builds livrés
--   /uidev                        -> affiche l'état
--   /uireload                     -> recharge les pages (après un build, sans restart)
-- Le choix est mémorisé (KVP) et réappliqué au démarrage de la ressource.

local KVP = "core_ui_dev_url"

local function apply(url)
    SendNUIMessage({ action = "core:uidev", data = { url = url or "" } })
    TriggerEvent("core:uidev", url or "")
end

local function allowed()
    local perms = VFW and VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions
    return perms and (perms["staff_menu"] or perms["dev"] or perms["gestion"]) or false
end

RegisterCommand("uidev", function(_, args)
    if not allowed() then return end
    local url = args[1]
    local current = GetResourceKvpString(KVP) or ""
    if not url or url == "" then
        VFW.ShowNotification({
            type = "STAFF",
            variant = "INFO",
            subtitle = "Interfaces",
            message = current ~= "" and ("Mode dev : " .. current) or "Mode dev désactivé (builds livrés).",
        })
        return
    end
    if url == "off" or url == "stop" or url == "0" then
        url = ""
    elseif not url:match("^https?://") then
        url = "http://" .. url
    end
    SetResourceKvp(KVP, url)
    apply(url)
    VFW.ShowNotification({
        type = "STAFF",
        variant = "SUCCESS",
        subtitle = "Interfaces",
        message = url ~= "" and ("Pages chargées depuis " .. url) or "Retour aux builds livrés.",
    })
end, false)

RegisterCommand("uireload", function()
    if not allowed() then return end
    SendNUIMessage({ action = "core:uireload" })
    TriggerEvent("core:uireload")
end, false)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    local url = GetResourceKvpString(KVP)
    if url and url ~= "" then
        CreateThread(function()
            Wait(2000)
            apply(url)
        end)
    end
end)

-- Complétion de commande
TriggerEvent("chat:addSuggestion", "/uidev", "Interfaces depuis un serveur de dev (HMR)", {
    { name = "url", help = "http://localhost:5173, ou off" },
})
TriggerEvent("chat:addSuggestion", "/uireload", "Recharger les pages NUI sans restart")
