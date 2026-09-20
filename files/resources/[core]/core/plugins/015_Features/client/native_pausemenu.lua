---@meta _
---@diagnostic disable: duplicate-doc-field

-- Native Pause Menu Modifications
-- Full implementation with colors and proper header hiding

-- Function to add text entries exactly like Nevylish
function AddTextEntry(k, v)
    Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), k, v)
end

-- Initialize stats to hide money
Citizen.CreateThread(function()
    -- Set wallet and bank to -1 to hide them
    StatSetInt(GetHashKey("MP0_WALLET_BALANCE"), -1, true)
    StatSetInt(GetHashKey("BANK_BALANCE"), -1, true)
    StatSetInt(GetHashKey("MP0_BANK_BALANCE"), -1, true)
end)

-- Main pause menu text modifications
Citizen.CreateThread(function()
    while true do
        Wait(500) -- Update every half second

        -- Branding (panel EVE) : nom de marque + invitation Discord (sans protocole
        -- pour l'affichage). Relu à CHAQUE itération car le branding live du panel
        -- (event core:branding:apply -> BRANDING.discord) arrive souvent APRÈS la
        -- création de ce thread : le lire une seule fois figerait le défaut eve.
        local brandName = VFW.BrandName()
        local discordDisplay = ((BRANDING and BRANDING.discord) or "discord.gg/eve-rp"):gsub("^https?://", "")

        -- Get player data for dynamic header
        if VFW and VFW.PlayerData then
            local serverId = GetPlayerServerId(PlayerId())
            local playerData = VFW.PlayerData
            local playerName = (playerData.firstName or "Unknown") .. " " .. (playerData.lastName or "Name")
            local headerText = string.format("~b~%s ~u~|~g~ ID: %d ~u~|~s~ %s ~u~|~s~ Rejoins nous : ~b~%s",
                    brandName, serverId, playerName, discordDisplay)

            -- Set header
            AddTextEntry('FE_THDR_GTAO', headerText)
        end

        -- Set menu labels WITH COLORS
        AddTextEntry('PM_SCR_MAP', 'SAN ANDREAS')
        AddTextEntry('PM_SCR_GAM', '~y~JEU~s~')
        AddTextEntry('PM_SCR_INF', '~b~INFO~s~')
        AddTextEntry('PM_SCR_STA', '~g~STATISTIQUES~s~')
        AddTextEntry('PM_SCR_SET', '~o~RÉGLAGES~s~')
        AddTextEntry('PM_SCR_GAL', '~r~GALERIE~s~')
        AddTextEntry('PM_SCR_RPL', '~p~ÉDITEUR~s~')

        -- Settings submenu with colors
        AddTextEntry('PM_PANE_LEAVE', '~r~Quitter ' .. brandName .. ' RP~s~')
        AddTextEntry('PM_PANE_QUIT', '~r~Quitter le jeu~s~')
        AddTextEntry('PM_PANE_CFX', '~b~Touches ' .. brandName .. '~s~')
        AddTextEntry('PM_PANE_AUD', 'Audio')
        AddTextEntry('PM_PANE_DIS', 'Affichage')
        AddTextEntry('PM_PANE_VID', '~y~VIDÉO~s~')
        AddTextEntry('PM_PANE_CTL', '~p~CONTRÔLES~s~')

        -- Control categories with colors
        AddTextEntry('PM_UCON_MOVEMENT', '~b~Mouvement~s~')
        AddTextEntry('PM_UCON_COMBAT', '~r~Combat~s~')
        AddTextEntry('PM_UCON_VEHICLE', '~o~Véhicule~s~')
        AddTextEntry('PM_UCON_MELEE', '~y~Mêlée~s~')
        AddTextEntry('PM_UCON_MULTIPLAYER', '~g~Multijoueur~s~')
    end
end)

-- Thread to hide the top-right player info using proper scaleform method
Citizen.CreateThread(function()
    while true do
        if IsPauseMenuActive() then
            BeginScaleformMovieMethodOnFrontendHeader('SHOW_HEADING_DETAILS')
            ScaleformMovieMethodAddParamBool(false)
            EndScaleformMovieMethod()
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

-- Additional thread to ensure stats stay hidden
Citizen.CreateThread(function()
    while true do
        Wait(5000) -- Every 5 seconds

        -- Keep stats at -1 to hide money display
        StatSetInt(GetHashKey("MP0_WALLET_BALANCE"), -1, true)
        StatSetInt(GetHashKey("MP0_BANK_BALANCE"), -1, true)
        StatSetInt(GetHashKey("BANK_BALANCE"), -1, true)

        -- Clear any character stats
        StatSetBool(GetHashKey("MP0_CHAR_SET_RP_GIFT_ADMIN"), false, true)
        StatSetInt(GetHashKey("MP_CHAR_ARMOUR_1_COUNT"), -1, true)
        StatSetInt(GetHashKey("MP_CHAR_ARMOUR_2_COUNT"), -1, true)
        StatSetInt(GetHashKey("MP_CHAR_ARMOUR_3_COUNT"), -1, true)
        StatSetInt(GetHashKey("MP_CHAR_ARMOUR_4_COUNT"), -1, true)
        StatSetInt(GetHashKey("MP_CHAR_ARMOUR_5_COUNT"), -1, true)
    end
end)

-- console.success("[Native Pause Menu] Loaded successfully - All features active")