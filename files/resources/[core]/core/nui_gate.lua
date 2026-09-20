---@meta _
---@diagnostic disable: duplicate-doc-field

-- Filet de sécurité : le cadre NUI n'existe pas encore pendant
-- « Creating script environments ». On retient les messages et on
-- les envoie dès que la page signale qu'elle est montée.

local nativeSend = SendNUIMessage
local frameReady = false
local queue = {}
local QUEUE_MAX = 256

SendNUIMessage = function(payload)
    if frameReady then
        return nativeSend(payload)
    end
    if #queue < QUEUE_MAX then
        queue[#queue + 1] = payload
    end
end

local function flush()
    if frameReady then return end
    frameReady = true
    for i = 1, #queue do
        nativeSend(queue[i])
    end
    queue = {}
end

RegisterNUICallback("nui:frameReady", function(_, cb)
    cb({ ok = true })
    CreateThread(function()
        Wait(400)
        flush()
    end)
end)

CreateThread(function()
    Wait(8000)
    flush()
end)
