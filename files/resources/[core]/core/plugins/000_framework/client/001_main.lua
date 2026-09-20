---@meta _
---@diagnostic disable: duplicate-doc-field

-- Core table to hold core functionalities
---@class Core
---@field Input table
---@field Events table
Core = {}

-- Core.Input table to hold input related functionalities
Core.Input = {}

-- Core.Events table to hold event related functionalities
Core.Events = {}

-- VFW.PlayerData table to hold player data
VFW.PlayerData = {}
VFW.PlayerData.inventory = {}

-- VFW.PlayerLoaded boolean to check if player is loaded
VFW.PlayerLoaded = false

-- VFW.PlayerGlobalData table to hold player global data
VFW.PlayerGlobalData = nil

-- VFW.playerId stores the player's ID
-- @param VFW.playerId: integer
VFW.playerId = PlayerId()

-- VFW.serverId stores the player's server ID
-- @param VFW.serverId: integer
VFW.serverId = GetPlayerServerId(VFW.playerId)

-- VFW.Game table to hold game related functionalities
VFW.Game = {}

-- VFW.Game.Utils table to hold game utility functions
VFW.Game.Utils = {}

-- Thread to handle player connection
CreateThread(function()
    while not Config.Multichar do
        Wait(100)
        if NetworkIsPlayerActive(VFW.playerId) then
            DoScreenFadeOut(0)
            Wait(500)
            TriggerServerEvent("vfw:onPlayerConnect")
            break
        end
    end

    VFW.Streaming.RequestAnimDict('anim@mp_player_intmenu@key_fob@')
    VFW.Streaming.RequestModel('lr_prop_carkey_fob')
end)

