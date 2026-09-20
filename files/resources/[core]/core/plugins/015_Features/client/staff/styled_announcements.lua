---@meta _
---@diagnostic disable: duplicate-doc-field

-- Modern announcement system using the UI notification system
-- Uses the regular notification system which appears in the UI

-- Server announcement handler (RED)
RegisterNetEvent("vfw:staff:serverAnnouncement", function(title, message, duration, senderName)
    -- Afficher uniquement le message
    local displayMessage = message

    -- Send as announcement UI (top center)
    SendNUIMessage({
        action = "nui:hud:create-announcement",
        data = {
            title = "ANNONCE SERVEUR",
            name = senderName or "",
            label = senderName or "",
            labelColor = "#FFFFFF",
            mainColor = "red",
            logo = VFW.CDN.Get("hud/notifications/sirenLights.png"),
            mainMessage = displayMessage,
            duration = duration or 12
        }
    })

    -- Play sound effect
    PlaySoundFrontend(-1, "Boss_Blipped", "GTAO_Magnate_Hunt_Boss_SoundSet", 1)
end)


RegisterNetEvent("vfw:seisme:announcement", function(title, message, duration)
    SendNUIMessage({
        action = "nui:hud:create-announcement",
        data = {
            title = "ANNONCE SÉISME",
            name = "",
            label = "",
            labelColor = "#FFFFFF",
            mainColor = "gold",
            logo = VFW.CDN.Get("hud/notifications/sirenLights.png"),
            mainMessage = message,
            duration = duration or 10
        }
    })
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
end)

RegisterNetEvent("vfw:seisme:announcement:end", function(title, message, duration)
    SendNUIMessage({
        action = "nui:hud:create-announcement",
        data = {
            title = "FIN DE SÉISME",
            name = "",
            label = "",
            labelColor = "#FFFFFF",
            mainColor = "blue",
            logo = VFW.CDN.Get("hud/notifications/sirenLights.png"),
            mainMessage = message,
            duration = duration or 8
        }
    })
    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", 1)
end)

-- Staff announcement handler (GOLD)
RegisterNetEvent("vfw:staff:staffAnnouncement", function(title, message, duration, senderName)
    -- Afficher uniquement le message
    local displayMessage = message

    -- Send as announcement UI (top center)
    SendNUIMessage({
        action = "nui:hud:create-announcement",
        data = {
            title = "ANNONCE MODÉRATION",
            name = senderName or "",
            label = senderName or "",
            labelColor = "#FFFFFF",
            mainColor = "gold",
            logo = VFW.CDN.Get("hud/notifications/sirenLights.png"),
            mainMessage = displayMessage,
            duration = duration or 10
        }
    })

    -- Play sound effect
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
end)

-- Zone announcement handler (BLUE)
RegisterNetEvent("vfw:staff:zoneAnnouncement", function(title, message, duration, senderName)
    local displayMessage = message

    SendNUIMessage({
        action = "nui:hud:create-announcement",
        data = {
            title = "ANNONCE SERVEUR",
            name = senderName or "",
            label = senderName or "",
            labelColor = "#FFFFFF",
            mainColor = "red",
            logo = VFW.CDN.Get("hud/notifications/sirenLights.png"),
            mainMessage = displayMessage,
            duration = duration or 8
        }
    })

    -- Play sound effect
    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", 1)
end)

-- Direct handlers for big announcements
RegisterNetEvent("vfw:staff:bigServerAnnouncement", function(message, senderName)
    TriggerEvent("vfw:staff:serverAnnouncement", "ANNONCE SERVEUR", message, 12, senderName)
end)

RegisterNetEvent("vfw:staff:bigStaffAnnouncement", function(message, senderName)
    TriggerEvent("vfw:staff:staffAnnouncement", "ANNONCE STAFF", message, 10, senderName)
end)

RegisterNetEvent("vfw:staff:bigZoneAnnouncement", function(message, senderName)
    TriggerEvent("vfw:staff:zoneAnnouncement", "ANNONCE SERVEUR", message, 8, senderName)
end)

RegisterNetEvent("vfw:staff:zoneAnnouncementConfirm", function(radius, count)
    VFW.ShowNotification({
        type = "VERT",
        content = "Annonce de zone envoyée (rayon: " .. radius .. "m, " .. count .. (count > 1 and " joueurs touchés)" or " joueur touché)")
  })
end)

RegisterNetEvent("vfw:staff:chatAnnouncementSound", function()
    PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", 1)
end)

RegisterNetEvent("vfw:staff:playerMessage", function(message, duration, senderType, senderName)
    local title = senderType == "animator" and "MESSAGE D'UN ANIMATEUR" or "MESSAGE D'UN STAFF"

  SendNUIMessage({
        action = "nui:hud:create-announcement",
        data = {
            title = title,
            name = senderName or "",
            label = senderName or "",
            labelColor = "#FFFFFF",
            mainColor = "red",
            logo = VFW.CDN.Get("hud/notifications/sirenLights.png"),
            mainMessage = message,
            duration = duration or 8
        }
    })

    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", 1)
end)