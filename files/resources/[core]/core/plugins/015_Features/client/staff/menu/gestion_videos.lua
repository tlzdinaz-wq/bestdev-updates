---@meta _
---@diagnostic disable: duplicate-doc-field

-- Panneau natif "Vidéos" du hub Gestion (sans VUI ni clavier overlay).

local TARGET_PLAYER, TARGET_ZONE, TARGET_SERVER = 1, 2, 3
local PLACE_FULLSCREEN, PLACE_TOPRIGHT = 1, 2

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["video_management"] == true
end

local function IsYoutube(url)
    if type(url) ~= "string" or url == "" then return false end
    local lower = url:lower()
    return lower:find("youtube.com", 1, true) ~= nil or lower:find("youtu.be", 1, true) ~= nil
end

RegisterNuiCallback("gestion:videos:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les vidéos." })
        return
    end
    cb({ ok = true })
end)

RegisterNuiCallback("gestion:videos:play", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local url = data and data.url
    if not IsYoutube(url) then
        cb({ ok = false, error = "Lien YouTube uniquement (youtube.com ou youtu.be)." })
        return
    end
    local placement = math.floor(tonumber(data.placement) or PLACE_TOPRIGHT)
    if placement ~= PLACE_FULLSCREEN then placement = PLACE_TOPRIGHT end
    local kind = math.floor(tonumber(data.targetType) or TARGET_SERVER)
    if kind < TARGET_PLAYER or kind > TARGET_SERVER then kind = TARGET_SERVER end
    local info
    if kind == TARGET_PLAYER then
        info = math.floor(tonumber(data.targetInfo) or 0)
        if info < 1 then
            cb({ ok = false, error = "Indique l’ID du joueur." })
            return
        end
    elseif kind == TARGET_ZONE then
        info = math.floor(tonumber(data.targetInfo) or 0)
        if info < 1 then
            cb({ ok = false, error = "Indique un rayon en mètres." })
            return
        end
    else
        info = -1
    end
    TriggerServerEvent("vfw:staff:playVideo", url, placement, kind, info)
    cb({ ok = true })
end)

RegisterNuiCallback("gestion:videos:stop", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    TriggerServerEvent("vfw:staff:stopVideo")
    cb({ ok = true })
end)

RegisterNuiCallback("gestion:videos:stopAll", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    TriggerServerEvent("vfw:staff:stopVideoForAll")
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Vidéos',
        message = "Toutes les vidéos arrêtées.",
    })
    cb({ ok = true })
end)
