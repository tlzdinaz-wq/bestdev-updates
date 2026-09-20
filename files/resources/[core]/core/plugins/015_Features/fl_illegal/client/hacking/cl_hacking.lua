--[[
    Hacking Mini-Games System

    Available games:
    - memory: Memory Breach (memorize sequence)
    - numbers: Code Cracker (remember numbers)
    - word: Decrypt Word (unscramble password)
    - circuit: Circuit Breach (rotate tiles to connect)
    - frequency: Frequency Tuner (match wave with sliders)
    - terminal: Terminal Hack (type commands fast)
    - firewall: Firewall Breach (click nodes, avoid scans)
    - slot: Decode Slot (stop reels to spell word)
    - reaction: Reaction Test (click when signal appears)

    Difficulties: easy, medium, hard
]]

local isHacking = false
local hackingStartTime = 0
local disableControlsThread = nil

-- Désactive tous les contrôles du jeu pendant le hack
local function StartDisableControlsThread()
    if disableControlsThread then return end

    disableControlsThread = Citizen.CreateThread(function()
        while isHacking do
            -- Désactiver tous les contrôles sauf la souris
            DisableAllControlActions(0)
            -- Réactiver les contrôles de la souris pour le NUI
            EnableControlAction(0, 1, true) -- LookLeftRight
            EnableControlAction(0, 2, true) -- LookUpDown
            EnableControlAction(0, 24, true) -- Attack (clic gauche)
            EnableControlAction(0, 25, true) -- Aim (clic droit)
            EnableControlAction(0, 237, true) -- Cursor X
            EnableControlAction(0, 238, true) -- Cursor Y
            EnableControlAction(0, 239, true) -- Cursor On
            EnableControlAction(0, 240, true) -- Cursor Off
            EnableControlAction(0, 330, true) -- Mouse1 for NUI
            EnableControlAction(0, 331, true) -- Mouse2 for NUI
            Citizen.Wait(0)
        end
        disableControlsThread = nil
    end)
end

local function StopDisableControlsThread()
    isHacking = false
    disableControlsThread = nil
end

-- Start a hacking mini-game
---@param game string The game type
---@param difficulty string The difficulty (easy/medium/hard)
---@param timeLimit number|nil Optional time limit in seconds
---@param callback function Callback with success boolean
function StartHacking(game, difficulty, timeLimit, callback)

    if isHacking then
        -- Si ça fait plus de 5 secondes qu'on hack, c'est probablement un bug - reset
        if hackingStartTime > 0 and (GetGameTimer() - hackingStartTime) > 5000 then
            isHacking = false
            StopDisableControlsThread()
            VFW.Nui.Focus(false)
        else
            return callback(false)
        end
    end

    isHacking = true
    hackingStartTime = GetGameTimer()

    VFW.Nui.Focus(true, false)
    StartDisableControlsThread()

    SendNUIMessage({
        action = 'nui:hacking:start',
        data = {
            game = game,
            difficulty = difficulty or 'medium',
            timeLimit = timeLimit
        }
    })

    -- Store callback for NUI response
    _hackingCallback = callback
end

-- NUI Callback for hacking result
RegisterNUICallback('hacking:result', function(data, cb)

    isHacking = false
    hackingStartTime = 0
    StopDisableControlsThread()
    VFW.Nui.Focus(false)

    if _hackingCallback then
        local tempCallback = _hackingCallback
        _hackingCallback = nil
        tempCallback(data.success, data.timeElapsed, data.attempts)
    else
    end

    cb('ok')
end)

-- Export for other resources
exports('StartHacking', StartHacking)

-- ==========================================
--          TEST COMMANDS
-- ==========================================

-- Test Memory Breach
--RegisterCommand('hack:memory', function(source, args)
--    local difficulty = args[1] or 'medium'
--    StartHacking('memory', difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)

--RegisterCommand('hack:numbers', function(source, args)
--    local difficulty = args[1] or 'medium'
--    StartHacking('numbers', difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)
--
--RegisterCommand('hack:word', function(source, args)
--    local difficulty = args[1] or 'medium'
--    StartHacking('word', difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)
--
--RegisterCommand('hack:circuit', function(source, args)
--    local difficulty = args[1] or 'medium'
--    StartHacking('circuit', difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)
--
--RegisterCommand('hack:frequency', function(source, args)
--    local difficulty = args[1] or 'medium'
--    StartHacking('frequency', difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)
--
--RegisterCommand('hack:terminal', function(source, args)
--    local difficulty = args[1] or 'medium'
--    StartHacking('terminal', difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)
--
--RegisterCommand('hack:firewall', function(source, args)
--    local difficulty = args[1] or 'medium'
--    StartHacking('firewall', difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)
--
--RegisterCommand('hack:slot', function(source, args)
--    local difficulty = args[1] or 'medium'
--    StartHacking('slot', difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)
--
--RegisterCommand('hack:reaction', function(source, args)
--    local difficulty = args[1] or 'medium'
--    StartHacking('reaction', difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)
--
--RegisterCommand('hack:random', function(source, args)
--    local games = {'memory', 'numbers', 'word', 'circuit', 'frequency', 'terminal', 'firewall', 'slot', 'reaction'}
--    local game = games[math.random(#games)]
--    local difficulty = args[1] or 'medium'
--
--
--    StartHacking(game, difficulty, nil, function(success)
--        if success then
--        else
--        end
--    end)
--end, false)
--
--RegisterCommand('hack:help', function()
--    print('^3=== HACKING TEST COMMANDS ===^0')
--    print('^7/hack:memory [easy/medium/hard]^0 - Memory Breach')
--    print('^7/hack:numbers [easy/medium/hard]^0 - Code Cracker')
--    print('^7/hack:word [easy/medium/hard]^0 - Decrypt Word')
--    print('^7/hack:circuit [easy/medium/hard]^0 - Circuit Breach')
--    print('^7/hack:frequency [easy/medium/hard]^0 - Frequency Tuner')
--    print('^7/hack:terminal [easy/medium/hard]^0 - Terminal Hack')
--    print('^7/hack:firewall [easy/medium/hard]^0 - Firewall Breach')
--    print('^7/hack:slot [easy/medium/hard]^0 - Decode Slot')
--    print('^7/hack:reaction [easy/medium/hard]^0 - Reaction Test')
--    print('^7/hack:random [easy/medium/hard]^0 - Random game')
--end, false)

TriggerEvent('chat:removeSuggestion', '/hack:memory')
TriggerEvent('chat:removeSuggestion', '/hack:numbers')
TriggerEvent('chat:removeSuggestion', '/hack:word')
TriggerEvent('chat:removeSuggestion', '/hack:circuit')
TriggerEvent('chat:removeSuggestion', '/hack:frequency')
TriggerEvent('chat:removeSuggestion', '/hack:terminal')
TriggerEvent('chat:removeSuggestion', '/hack:firewall')
TriggerEvent('chat:removeSuggestion', '/hack:slot')
TriggerEvent('chat:removeSuggestion', '/hack:reaction')
TriggerEvent('chat:removeSuggestion', '/hack:random')
TriggerEvent('chat:removeSuggestion', '/hack:help')
