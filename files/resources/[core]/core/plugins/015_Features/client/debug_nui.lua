RegisterCommand('debug', function()
    -- Reset NUI focus
    VFW.Nui.Focus(false)

    -- Close all major UIs
    local closeActions = {
        -- Core menus
        "chat:hide",
        "phone:hide",
        "inventory:close",
        "menu:close",
        "emotes:close",
        "nui:escape-menu:close",
        "nui:radial-menu:visible",

        -- Shops
        "closeWeaponMenu",
        "closeBarMenu",
        "closeShopLTD",
        "closeAmmunition",
        "closeJobEquipment",
        "closeJobArmory",
        "closeFireworkShop",
        "closeVehicleSell",
        "clothingshop:close",
        "maskshop:close",
        "paidshop:hide",
        "afkshop:hide",
        "concessCatalog:close",

        -- Vehicle
        "nui:vehicleInfo:close",
        "nui:vehicleDiagnostic:close",
        "nui:vehicleCustoms:close",
        "nui:vehicleMenu:visible",

        -- Jobs / delivery
        "bossPanel:close",
        "nui:interimjobscenter:close",
        "delivery:hideOrder",
        "burgershot:progress:hide",
        "burgershot:delivery:closeConversation",
        "bean_coffee:progress:hide",
        "bean_coffee:delivery:closeConversation",
        "noodle:progress:hide",
        "noodle:delivery:closeConversation",
        "pizzeria:progress:hide",
        "pizzeria:delivery:closeConversation",
        "pearls:progress:hide",
        "pearls:delivery:closeConversation",
        "uwu_cafe:progress:hide",
        "uwu_cafe:delivery:closeConversation",
        "fl_ltd:hideMissionPopup",
        "fl_ltd:closeConversation",

        -- Property / Dynasty
        "dynastyTablet:close",
        "dynastyTablet:hidePreviewOverlay",
        "dynastyContract:close",
        "contract:close",

        -- Staff / Admin
        "staff:sanctions:close",
        "staff:grades:close",
        "staff:crosshair:hide",
        "nui:effectifs:close",

        -- Faction / Orga
        "closeFactionTerritories",
        "closeAdminFactionTerritories",
        "nui:faction-tablet:hideInvitation",

        -- Minigames / Activities
        "safeCracking:close",
        "nui:scratchcard:close",
        "nui:rockfordstudio:close",
        "nui:pacific:closeCodeInput",
        "illegalHarvesting:hideProgress",

        -- Dialogs / Forms
        "nui:npcDialogue:close",
        "nui:npcDialogue:hideForm",
        "nui:searchConsent:hide",
        "playerDocuments:close",
        "chestHistory:close",

        -- Overlays / Misc
        "floatingInteraction:hide",
        "instructionalBar:hide",
        "nui:helpNotification:hide",
        "fireAlarm:hide",
        "hideOverlay",
        "lifeinvader:hideOverlay",
        "nui:musicradio:close",
        "vip:ppa:hide",
        "nui:blackScreen:toggle",

        -- Framework UIs (visibility = false)
        "nui:keyboardinput:visible",
        "nui:choiceinput:visible",
        "nui:colorpicker:visible",
        "nui:colortexteditor:visible",
        "nui:valideinput:visible",
    }

    for _, action in ipairs(closeActions) do
        SendNUIMessage({ action = action, data = false })
    end

    SendNUIMessage({ action = "nui:close" })

    -- Show HUD + radar + notifications
    VFW.Nui.HudVisible(true)
    VFW.Nui.NotificationsVisible(true)
    VFW.DisableEscapeMenu(false)
    DisplayRadar(true)

    -- Clear screen blur
    TriggerScreenblurFadeOut(0)

    VFW.ShowNotification({ type = 'VERT', content = 'Debug: toutes les UI ont été reset' })
end, false)

VFW.AddChatSuggestion('/debug', 'Reset toutes les UI, le focus NUI et réaffiche le HUD')
