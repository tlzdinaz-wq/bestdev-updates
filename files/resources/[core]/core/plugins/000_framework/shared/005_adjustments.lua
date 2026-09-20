---@meta _
---@diagnostic disable: duplicate-doc-field

Config.RemoveHudComponents = {
    [1] = false, --WANTED_STARS,
    [2] = true, --WEAPON_ICON
    [3] = true, --CASH
    [4] = true, --MP_CASH
    [5] = true, --MP_MESSAGE
    [6] = true, --VEHICLE_NAME
    [7] = true, -- AREA_NAME
    [8] = true, -- VEHICLE_CLASS
    [9] = true, --STREET_NAME
    [10] = false, --HELP_TEXT
    [11] = false, --FLOATING_HELP_TEXT_1
    [12] = false, --FLOATING_HELP_TEXT_2
    [13] = false, --CASH_CHANGE
    [14] = false, --RETICLE
    [15] = false, --SUBTITLE_TEXT
    [16] = false, --RADIO_STATIONS
    [17] = false, --SAVING_GAME,
    [18] = false, --GAME_STREAM
    [19] = false, --WEAPON_WHEEL
    [20] = false, --WEAPON_WHEEL_STATS
    [21] = false, --HUD_COMPONENTS
    [22] = true, --HUD_WEAPONS
}

-- Pattern string format
--1 will lead to a random number from 0-9.
--A will lead to a random letter from A-Z.
-- . will lead to a random letter or number, with a 50% probability of being either.
--^1 will lead to a literal 1 being emitted.
--^A will lead to a literal A being emitted.
--Any other character will lead to said character being emitted.
-- A string shorter than 8 characters will be padded on the right.
Config.CustomAIPlates = "........" -- Custom plates for AI vehicles

--[[
    PlaceHolders:
    {server_name} - Server Display Name
    {server_endpoint} - Server IP:Server Port
    {server_players} - Current Player Count
    {server_maxplayers} - Max Player Count

    {player_name} - Player Name
    {player_rp_name} - Player RP Name
    {player_id} - Player ID
    {player_street} - Player Street Name
]]

if (GetConvar('core_type', 'FA') == 'WL') then
    Config.DiscordActivity = {
        appId = tonumber(GetConvar('core_discord_app_id', '0')) or 0, -- Discord Application ID
        assetName = "logoavre", -- image name for the "large" icon
        assetText = (BRANDING and BRANDING.name) or "EVE", -- Branding (ConVar core_brand_name)
        assetSmall = "", -- clé d'asset Discord (petite icône). Surchargé par le panel.
        assetSmallText = (BRANDING and BRANDING.name) or "EVE",
        buttons = {
            { label = "🎮 Discord", url = (BRANDING and BRANDING.discord) or "https://discord.gg/eve-rp" },
            { label = "🛩️ Se connecter", url = "soon" },
        },
        presence = "{player_rp_name} [{player_id}] - {server_players}/ {server_maxplayers}",
        refresh = 1 * 60 * 1000, -- 1 minute
    }
else
    Config.DiscordActivity = {
        appId = tonumber(GetConvar('core_discord_app_id', '0')) or 0, -- Discord Application ID
        assetName = "logoavre", -- image name for the "large" icon
        assetText = (BRANDING and BRANDING.name) or "EVE", -- Branding (ConVar core_brand_name)
        assetSmall = "", -- clé d'asset Discord (petite icône). Surchargé par le panel.
        assetSmallText = (BRANDING and BRANDING.name) or "EVE",
        buttons = {
            { label = "🎮 Discord", url = (BRANDING and BRANDING.discord) or "https://discord.gg/eve-rp" },
            { label = "🛩️ Se connecter", url = "soon" },
        },
        presence = "{player_rp_name} [{player_id}] - {server_players}/ {server_maxplayers}",
        refresh = 1 * 60 * 1000, -- 1 minute
    }
end
