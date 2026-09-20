local selected = 1
local selectedNode = {
    [1] = {0, math.random(1, 4)},
    [2] = {0, math.random(1, 4)},
    [3] = {0, math.random(1, 4)},
    [4] = {0, math.random(1, 4)},
}

local RemainingTime = 30
local timeIsUp = false
local minigameLoop = false
local win = false
local time = 3000
local old1 = nil
local old2 = nil

local nodes = {}
local lastHackState = nil

local hackingButtonId = generateUniqueID(8)

local function ResetMinigame()
    selected = 1
    selectedNode = {
        [1] = {0, math.random(1, 4)},
        [2] = {0, math.random(1, 4)},
        [3] = {0, math.random(1, 4)},
        [4] = {0, math.random(1, 4)},
    }
    RemainingTime = 30
    timeIsUp = false
    minigameLoop = false
    time = 3000
    win = false
    old1 = nil
    old2 = nil
    lastHackState = nil
    instructionalButtons[hackingButtonId] = nil

    SendNUIMessage({ action = "hud:hack:hide", data = {} })
end

local function SendHackState()
    local lit = {}

    for row = 1, 4 do
        lit[row] = 0

        for index = 1, 4 do
            if nodes[row] and nodes[row][index] then
                lit[row] = index
            end
        end
    end

    local cursor = selectedNode[selected][1]
    local signature = string.format(
        "%d|%d|%d%d%d%d|%d|%s",
        selected, cursor, lit[1], lit[2], lit[3], lit[4], RemainingTime, tostring(win)
    )

    if signature == lastHackState then return end
    lastHackState = signature

    SendNUIMessage({
        action = "hud:hack:state",
        data = {
            selected = selected,
            cursor = cursor,
            lit = lit,
            remaining = RemainingTime,
            win = win
        }
    })
end

local function Timer()
    CreateThread(function()
        while minigameLoop do
            if RemainingTime <= 0 then
                timeIsUp = true
            end
            RemainingTime = RemainingTime - 1
            Wait(1000)
        end
    end)
end

function StartPacificHacking(cb)
    minigameLoop = true
    time = 3000
    RequestScriptAudioBank('DLC_XM17_IAA_SF_Hack')
    RequestAmbientAudioBank('DLC_XM17_IAA_SF_Hack')

    nodes = {
        [1] = { false, false, false, false },
        [2] = { false, false, false, false },
        [3] = { false, false, false, false },
        [4] = { false, false, false, false },
    }

    instructionalButtons[hackingButtonId] = {
        { control = 174, control2 = 175, label = "Changer de connexion" },
        { control = 172, control2 = 173, label = "Changer de ligne" },
        { control = 194, label = "Quitter" },
    }

    SendNUIMessage({ action = "hud:hack:show", data = {} })

    CreateThread(function()
        Wait(100)
        Timer()
    end)

    SetPlayerControl(PlayerId(), false)

    while minigameLoop do
        SendHackState()

        if IsControlJustPressed(0, 172) or IsDisabledControlJustPressed(0, 172) then
            PlaySoundFrontend(-1, 'Grab_Wire', 'DLC_XM17_IAA_SF_Hack', true)
            if (selected - 1) < 1 then
                selected = 4
            else
                selected = selected - 1
            end
            selectedNode[selected][1] = 0
        elseif IsControlJustPressed(0, 173) or IsDisabledControlJustPressed(0, 173) then
            PlaySoundFrontend(-1, 'Grab_Wire', 'DLC_XM17_IAA_SF_Hack', true)
            if (selected + 1) > 4 then
                selected = 1
            else
                selected = selected + 1
            end
            selectedNode[selected][1] = 0
        elseif IsControlJustPressed(0, 174) or IsDisabledControlJustPressed(0, 174) then
            if (selectedNode[selected][1] - 1) < 1 then
                selectedNode[selected][1] = 4
            else
                selectedNode[selected][1] = selectedNode[selected][1] - 1
            end
            if selectedNode[selected][1] == selectedNode[selected][2] then
                nodes[selected][selectedNode[selected][1]] = true
                old1 = selected
                old2 = selectedNode[selected][1]
                PlaySoundFrontend(-1, 'Test_Circuit', 'DLC_XM17_IAA_SF_Hack', true)
            else
                if old1 and old2 and selected == old1 then
                    nodes[old1][old2] = false
                    old1 = nil
                    old2 = nil
                end
                PlaySoundFrontend(-1, 'Error', 'DLC_XM17_IAA_SF_Hack', true)
            end
        elseif IsControlJustPressed(0, 175) or IsDisabledControlJustPressed(0, 175) then
            if (selectedNode[selected][1] + 1) > 4 then
                selectedNode[selected][1] = 1
            else
                selectedNode[selected][1] = selectedNode[selected][1] + 1
            end
            if selectedNode[selected][1] == selectedNode[selected][2] then
                nodes[selected][selectedNode[selected][1]] = true
                old1 = selected
                old2 = selectedNode[selected][1]
                PlaySoundFrontend(-1, 'Test_Circuit', 'DLC_XM17_IAA_SF_Hack', true)
            else
                if old1 and old2 and selected == old1 then
                    nodes[old1][old2] = false
                    old1 = nil
                    old2 = nil
                end
                PlaySoundFrontend(-1, 'Error', 'DLC_XM17_IAA_SF_Hack', true)
            end
        end

        if IsControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 194) then
            if old1 and old2 and selected == old1 then
                nodes[old1][old2] = false
                old1 = nil
                old2 = nil
            end
            PlaySoundFrontend(-1, 'Error', 'DLC_XM17_IAA_SF_Hack', true)
            ResetMinigame()
            cb(false)
        end

        if timeIsUp then
            if old1 and old2 and selected == old1 then
                nodes[old1][old2] = false
                old1 = nil
                old2 = nil
            end
            PlaySoundFrontend(-1, 'Error', 'DLC_XM17_IAA_SF_Hack', true)
            ResetMinigame()
            cb(false)
        end

        if nodes[1][selectedNode[1][2]] and nodes[2][selectedNode[2][2]] and nodes[3][selectedNode[3][2]] and nodes[4][selectedNode[4][2]] then
            win = true
        end

        if win then
            time = time - 10
            if time <= 0 then
                ResetMinigame()
                cb(true)
            end
        end

        Wait(1)
    end

    SetPlayerControl(PlayerId(), true)
end
