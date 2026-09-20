---@meta _
---@diagnostic disable: duplicate-doc-field

local c = {
    language = 'fr',
    color = { r = 230, g = 230, b = 230, a = 255 }, -- Text color
    font = 0, -- Text font
    time = 5000, -- Duration to display the text (in ms)
    scale = 0.5, -- Text scale
    dist = 250, -- Min. distance to draw
    stackSpacing = 0.15,
}
local lang = {
    commandName = 'me',
    commandDescription = 'Affiche une action au dessus de votre tête.',
    commandSuggestion = {{ name = 'action', help = '"se gratte le nez" par exemple.'}},
    prefix = 'l\'individu '
}
local peds = {}

-- Localization
local GetGameTimer = GetGameTimer

-- @desc Draw text in 3d
-- @param coords world coordinates to where you want to draw the text
-- @param text the text to display
--- draw3dText
---@param coords vector3|table Coordinates
---@param text string
local function draw3dText(coords, text)
    local camCoords = GetGameplayCamCoord()
    local dist = #(coords - camCoords)

    -- Experimental math to scale the text down
    local scale = 200 / (GetGameplayCamFov() * dist)

    -- Format the text
    SetTextColour(c.color.r, c.color.g, c.color.b, c.color.a)
    SetTextScale(0.0, c.scale * scale)
    SetTextFont(c.font)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)

    -- Diplay the text
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- @desc Display the text above the head of a ped
-- @param ped the target ped
-- @param text the text to display
--- displayText
---@param ped number Ped handle
---@param text string
local function displayText(ped, text)
    local playerPed <const> = PlayerPedId()
    local playerPos <const> = GetEntityCoords(playerPed)
    local targetPos <const> = GetEntityCoords(ped)
    local dist <const> = #(playerPos - targetPos)
    local los <const> = HasEntityClearLosToEntity(playerPed, ped, 17)

    if dist <= c.dist and los then

        if not peds[ped] then
            peds[ped] = {
                message = {},
                isDisplaying = false
            }
        end

        local data <const> = peds[ped]

        data.message[#data.message + 1] = {
            time = GetGameTimer() + c.time,
            text = text
        }

        if not data.isDisplaying then
            data.isDisplaying = true

            CreateThread(function()
                while #data.message > 0 do
                    local currentTime <const> = GetGameTimer()
                    local activemessage = {}

                    for i = 1, #data.message do
                        if data.message[i].time > currentTime then
                            activemessage[#activemessage + 1] = data.message[i]
                        end
                    end

                    data.message = activemessage

                    for i = #data.message, 1, -1 do
                        local step = (#data.message - i)
                        local offset = 1.0 + (step * c.stackSpacing)
                        local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, offset)
                        draw3dText(pos, "~f~" .. data.message[i].text)
                    end

                    Wait(0)
                end

                data.isDisplaying = false

                if peds[ped] == data then
                    peds[ped] = nil
                end
            end)
        end
    end
end

-- @desc Trigger the display of teh text for a player
-- @param text text to display
-- @param target the target server id
---Event handler for ShareDisplay
---@param text string
---@param target any
local function onShareDisplay(text, target)
    local player = GetPlayerFromServerId(target)
    if player ~= -1 or target == GetPlayerServerId(PlayerId()) then
        local ped = GetPlayerPed(player)
        displayText(ped, text)
    end
end

-- Register the event
RegisterNetEvent('3dme:shareDisplay', onShareDisplay)

-- Add the chat suggestion
VFW.AddChatSuggestion('/' .. lang.commandName, lang.commandDescription, lang.commandSuggestion)

local antispam = false

RegisterCommand("me", function(source, args)
    if antispam then
        return
    end

    antispam = true

    local text = "La personne " .. table.concat(args, " ") .. " "

    -- Server now calculates nearby players for security
    TriggerServerEvent("core:sendtext", text)

    Wait(1000)

    antispam = false
end)
