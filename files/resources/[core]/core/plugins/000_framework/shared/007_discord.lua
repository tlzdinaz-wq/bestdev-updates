---@meta _
---@diagnostic disable: duplicate-doc-field

Config.Discord = {
    apiVersion = "v10",
    guildId = GetConvar('core_discord_guild', ''),
    token = GetConvar('core_bot_token', nil),
    boutique = GetConvar("core_boutique_token", nil)
}