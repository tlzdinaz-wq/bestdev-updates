local STANCE_STANDING = 0
local STANCE_CROUCHING = 1
local STANCE_PRONE = 2

local currentStance = STANCE_STANDING
local inAction = false
local isProne = false
local isCrawling = false
local proneType = "onfront"

local HOLD_TIME = 400
local stanceDisabled = false

local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
    end
end

local function loadAnimSet(set)
    if not HasAnimSetLoaded(set) then
        RequestAnimSet(set)
        while not HasAnimSetLoaded(set) do
            Wait(0)
        end
    end
end

local function changeHeadingSmooth(ped, amount, time)
    local times = math.abs(amount)
    local step = amount / times
    local waitTime = time / times

    CreateThread(function()
        for i = 1, times do
            Wait(waitTime)
            SetEntityHeading(ped, GetEntityHeading(ped) + step)
        end
    end)
end

CreateThread(function()
    while true do
        DisableControlAction(0, 36, true)
        Wait(0)
    end
end)

local function playIdleCrawlAnim(ped, heading, blendInSpeed)
    local coords = GetEntityCoords(ped)
    TaskPlayAnimAdvanced(ped, "move_crawl", proneType .. "_fwd", coords.x, coords.y, coords.z, 0.0, 0.0, heading or GetEntityHeading(ped), blendInSpeed or 2.0, 2.0, -1, 2, 1.0, false, false)
end

local function setStanding()
    local ped = PlayerPedId()
    currentStance = STANCE_STANDING
    isProne = false
    isCrawling = false

    ClearPedTasks(ped)
    SetPedStealthMovement(ped, false, "DEFAULT_ACTION")
    ResetPedMovementClipset(ped, 0.3)
    SetPedConfigFlag(ped, 48, false)
end

local function setCrouching()
    local ped = PlayerPedId()
    currentStance = STANCE_CROUCHING
    isProne = false
    isCrawling = false

    ClearPedTasks(ped)
    SetPedStealthMovement(ped, false, "DEFAULT_ACTION")
    loadAnimSet("move_ped_crouched")
    SetPedMovementClipset(ped, "move_ped_crouched", 0.3)
end

local function crawl(ped, direction)
    isCrawling = true

    TaskPlayAnim(ped, "move_crawl", proneType .. "_" .. direction, 8.0, -8.0, -1, 2, 0.0, false, false, false)

    local times = {
        fwd = 820,
        bwd = 990
    }

    SetTimeout(times[direction], function()
        isCrawling = false
    end)
end

local function crawlLoop()
    loadAnimDict("move_crawl")
    loadAnimDict("move_crawlprone2crawlfront")

    playIdleCrawlAnim(PlayerPedId(), nil, 3.0)

    while isProne do
        local ped = PlayerPedId()

        if not IsPedOnFoot(ped) or IsPedInAnyVehicle(ped, false) or IsPedDeadOrDying(ped, true) or IsEntityInWater(ped) or IsPedRagdoll(ped) then
            isProne = false
            break
        end

        local forward = IsControlPressed(0, 32)
        local backward = IsControlPressed(0, 33)
        local left = IsControlPressed(0, 34)
        local right = IsControlPressed(0, 35)

        if not isCrawling and not inAction then
            if forward then
                crawl(ped, "fwd")
            elseif backward then
                crawl(ped, "bwd")
            end
        end

        if left then
            if isCrawling then
                local headingDiff = forward and 1.0 or -1.0
                SetEntityHeading(ped, GetEntityHeading(ped) + headingDiff)
            elseif not inAction then
                inAction = true
                local coords = GetEntityCoords(ped)
                TaskPlayAnimAdvanced(ped, "move_crawlprone2crawlfront", "left", coords.x, coords.y, coords.z, 0.0, 0.0, GetEntityHeading(ped), 2.0, 2.0, -1, 2, 0.1, false, false)
                changeHeadingSmooth(ped, -10.0, 300)
                Wait(700)
                playIdleCrawlAnim(ped)
                inAction = false
            end
        elseif right then
            if isCrawling then
                local headingDiff = backward and 1.0 or -1.0
                SetEntityHeading(ped, GetEntityHeading(ped) + headingDiff)
            elseif not inAction then
                inAction = true
                local coords = GetEntityCoords(ped)
                TaskPlayAnimAdvanced(ped, "move_crawlprone2crawlfront", "right", coords.x, coords.y, coords.z, 0.0, 0.0, GetEntityHeading(ped), 2.0, 2.0, -1, 2, 0.1, false, false)
                changeHeadingSmooth(ped, 10.0, 300)
                Wait(700)
                playIdleCrawlAnim(ped)
                inAction = false
            end
        end

        Wait(0)
    end

    isCrawling = false
    inAction = false
    RemoveAnimDict("move_crawl")
    RemoveAnimDict("move_crawlprone2crawlfront")
end

local function exitProne()
    if inAction or not isProne then return end
    inAction = true

    local ped = PlayerPedId()
    isProne = false

    Wait(100)

    loadAnimDict("get_up@directional@transition@prone_to_knees@crawl")
    TaskPlayAnim(ped, "get_up@directional@transition@prone_to_knees@crawl", "front", 2.0, 2.0, 780, 0, 0.0, false, false, false)
    Wait(780)

    loadAnimDict("get_up@directional@movement@from_knees@standard")
    TaskPlayAnim(ped, "get_up@directional@movement@from_knees@standard", "getup_l_0", 2.0, 2.0, 1300, 0, 0.0, false, false, false)
    Wait(1300)

    setStanding()
    inAction = false
end

local function enterProne()
    if inAction then return end
    inAction = true

    local ped = PlayerPedId()

    if currentStance == STANCE_CROUCHING then
        ResetPedMovementClipset(ped, 0.0)
    end

    currentStance = STANCE_PRONE
    proneType = "onfront"
    isProne = true

    SetPedConfigFlag(ped, 48, true)

    loadAnimDict("amb@world_human_sunbathe@male@front@enter")
    TaskPlayAnim(ped, "amb@world_human_sunbathe@male@front@enter", "enter", 2.0, 2.0, -1, 0, 0.0, false, false, false)

    Wait(3000)

    loadAnimDict("move_crawl")

    if IsPedOnFoot(ped) and not IsEntityInWater(ped) then
        playIdleCrawlAnim(ped, nil, 3.0)
    end

    inAction = false
    CreateThread(crawlLoop)
end

local keyPressStart = 0
local keyPressed = false

local function isLocalPlayerCuffed()
    if LocalPlayer.state.isCuffed == true then return true end
    return IsPedCuffed(PlayerPedId())
end

RegisterCommand('+stance', function()
    if stanceDisabled then return end
    if SN_SAMS and SN_SAMS.cprActive then return end
    if IsPauseMenuActive() or VFW.Nui.HasFocus() then return end
    if inAction then return end
    if IsPlayerInMugshot() then return end
    if exports[GetCurrentResourceName()]:IsUsingMegaphone() then return end
    if isLocalPlayerCuffed() then return end

    keyPressStart = GetGameTimer()
    keyPressed = true

    CreateThread(function()
        while keyPressed do
            Wait(0)
            local holdDuration = GetGameTimer() - keyPressStart

            if holdDuration >= HOLD_TIME and currentStance ~= STANCE_PRONE and not inAction then
                keyPressed = false
                local ped = PlayerPedId()
                if IsPedOnFoot(ped) and not IsPedInAnyVehicle(ped, false) then
                    enterProne()
                end
                return
            end
        end
    end)
end, false)

RegisterCommand('-stance', function()
    if stanceDisabled then return end
    if IsPauseMenuActive() or VFW.Nui.HasFocus() then return end
    if not keyPressed then return end
    keyPressed = false
    if isLocalPlayerCuffed() then return end

    local holdDuration = GetGameTimer() - keyPressStart

    if holdDuration < HOLD_TIME then
        local ped = PlayerPedId()
        if not IsPedOnFoot(ped) or IsPedInAnyVehicle(ped, false) or inAction then
            return
        end

        if currentStance == STANCE_PRONE then
            exitProne()
        elseif currentStance == STANCE_STANDING then
            setCrouching()
        else
            setStanding()
        end
    end
end, false)

RegisterKeyMapping('+stance', "Changer de position (Accroupi/Rampant)", 'keyboard', 'LCONTROL')

function SetStanceDisabled(disabled)
    stanceDisabled = disabled
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        setStanding()
    end
end)
