local megaphoneVolume = 100
local rangeDisplayUntil = 0
local megaphoneRange = 40.0
local displayedRange = megaphoneRange
local usingMegaphone = false
local megaphoneProp = nil
local showRangeSelector = false
local wasTalking = false

local megaphoneHudShown = false
local megaphoneHudVolume = nil
local megaphoneHudRange = nil

local function SendMegaphoneHud()
    if not megaphoneHudShown then
        megaphoneHudShown = true
        megaphoneHudVolume = megaphoneVolume
        megaphoneHudRange = displayedRange

        SendNUIMessage({
            action = "hud:megaphone:show",
            data = { volume = megaphoneVolume, range = displayedRange }
        })
        return
    end

    if megaphoneHudVolume ~= megaphoneVolume or megaphoneHudRange ~= displayedRange then
        megaphoneHudVolume = megaphoneVolume
        megaphoneHudRange = displayedRange

        SendNUIMessage({
            action = "hud:megaphone:update",
            data = { volume = megaphoneVolume, range = displayedRange }
        })
    end
end

local function HideMegaphoneHud()
    if not megaphoneHudShown then return end
    megaphoneHudShown = false
    SendNUIMessage({ action = "hud:megaphone:hide", data = {} })
end

local function PromptMegaphoneVolume()
    local input = VFW.Nui.KeyboardInput(true, "Volume (1-100)")
    if input then
        local val = tonumber(input)
        if val and val >= 1 and val <= 100 then
            megaphoneVolume = val
            TriggerServerEvent('megaphone:setVolume', megaphoneVolume)
        end
    end
end


local rangeOptions = {
    { label = "40m", value = 40.0 },
    { label = "55m", value = 55.0 },
    { label = "70m", value = 70.0 }
}

local selectorShown = false
local selectorHovered = 0

local function SendSelectorState(visible, hovered)
    if selectorShown == visible and selectorHovered == hovered then return end
    selectorShown = visible
    selectorHovered = hovered

    if not visible then
        SendNUIMessage({
            action = "hud:megaphone:selector",
            data = { visible = false, hovered = 0, options = {} }
        })
        return
    end

    local labels = {}
    for i, option in ipairs(rangeOptions) do
        labels[i] = option.label
    end

    SendNUIMessage({
        action = "hud:megaphone:selector",
        data = { visible = true, hovered = hovered, options = labels }
    })
end

local function IsMouseInRect(x, y, width, height)
    local mouseX = GetControlNormal(0, 239)
    local mouseY = GetControlNormal(0, 240)
    return mouseX >= x - width / 2 and mouseX <= x + width / 2 and
            mouseY >= y - height / 2 and mouseY <= y + height / 2
end

local function UpdateRangeSelector()
    local screenCenterX = 0.5
    local startY = 0.55
    local boxWidth = 0.12
    local boxHeight = 0.035
    local spacingY = 0.045

    DisableControlAction(0, 24, true)
    DisableControlAction(0, 1, true)
    DisableControlAction(0, 2, true)
    DisableControlAction(0, 3, true)

    ShowCursorThisFrame()

    local hovered = 0
    local clicked = IsDisabledControlJustReleased(0, 24)

    for i, option in ipairs(rangeOptions) do
        local y = startY + (i - 1) * spacingY

        if IsMouseInRect(screenCenterX, y, boxWidth, boxHeight) then
            hovered = i

            if clicked then
                megaphoneRange = option.value
                displayedRange = megaphoneRange
                rangeDisplayUntil = GetGameTimer() + 3000
                showRangeSelector = false
            end
        end
    end

    if IsControlJustPressed(0, 202) then
        showRangeSelector = false
    end

    SendSelectorState(showRangeSelector, hovered)
end

local function DrawMegaphoneRangeCircle()
    if GetGameTimer() > rangeDisplayUntil or not displayedRange then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    DrawMarker(
            1, coords.x, coords.y, coords.z - 1.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            displayedRange * 2.0, displayedRange * 2.0, 0.2,
            0, 153, 255, 100, false, true, 2, false, nil, nil, false
    )
end


function DeleteMegaphoneProp()
    if megaphoneProp and DoesEntityExist(megaphoneProp) then
        DeleteEntity(megaphoneProp)
        megaphoneProp = nil
    end
end

local function DisableSubmix()
    local ped = PlayerPedId()

    HideMegaphoneHud()
    SendSelectorState(false, 0)

    TriggerServerEvent('megaphone:applySubmix', false)

    if IsEntityPlayingAnim(ped, "molly@megaphone", "megaphone_clip", 3) then
        StopAnimTask(ped, "molly@megaphone", "megaphone_clip", -1.0)
    end
    StopAnimation(ped)

    CreateThread(function()
        Wait(500)
        DeleteMegaphoneProp()
    end)
end

function SpawnMegaphoneProp()
    local ped = PlayerPedId()
    local model = `prop_megaphone_01`
    local bone = 28422

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    megaphoneProp = CreateObject(model, 0.0, 0.0, 0.0, false, true, false)

    local pos = vec3(0.050000, 0.354000, 0.5460)
    local rot = vec3(-71.885498, 0.088900, -16.0242)

    AttachEntityToEntity(
            megaphoneProp, ped, bone,
            pos.x, pos.y, pos.z,
            rot.x, rot.y, rot.z,
            true, true, false, true, 2, true
    )

    SetEntityAsMissionEntity(megaphoneProp, true, true)
    SetModelAsNoLongerNeeded(model)
end


local megaphoneAnim = {
    "molly@megaphone",
    "megaphone_clip",
    "Megaphone",
    AnimationOptions = {
        Prop = "prop_megaphone_01",
        PropBone = 28422,
        PropPlacement = {
            0.0500,
            0.0540,
            -0.0060,
            -71.8855,
            -13.0889,
            -16.0242
        },
        EmoteLoop = true,
        EmoteMoving = true
    }
}


function UseMegaphone()
    if usingMegaphone then
        DisableSubmix()
    else
        TriggerServerEvent('megaphone:applySubmix', true)
        PlayAnimation(PlayerPedId(), megaphoneAnim)
        showRangeSelector = false
    end

    usingMegaphone = not usingMegaphone
end


exports('UseMegaphone', UseMegaphone)
exports('IsUsingMegaphone', function() return usingMegaphone end)

RegisterNetEvent('megaphone:use')
AddEventHandler('megaphone:use', function()
    UseMegaphone()
end)

-- Proximity-based volume relies on pma-voice's `overrideProximityRange` set on
-- the speaker side. Do NOT use MumbleSetVolumeOverrideByServerId here: that
-- override bypasses Mumble's positional 3D mixing and would make the talker
-- audible across the entire map at full volume.
RegisterNetEvent('megaphone:updateTalkingStatus')
AddEventHandler('megaphone:updateTalkingStatus', function(state, playerId, volume)
    -- Intentionally no-op on listener side. The range extension is handled by
    -- the speaker via exports['pma-voice']:overrideProximityRange below.
end)

RegisterCommand('megaphone_close', function()
    if usingMegaphone then
        usingMegaphone = false
        DisableSubmix()
        if wasTalking then
            exports['pma-voice']:clearProximityOverride()
            wasTalking = false
        end
    end
end, false)
RegisterKeyMapping('megaphone_close', 'Ranger le mégaphone', 'keyboard', 'x')

RegisterCommand('+megaphone_volume', function()
    if usingMegaphone then
        PromptMegaphoneVolume()
    end
end, false)
RegisterKeyMapping('+megaphone_volume', 'Modifier le volume du mégaphone', 'keyboard', 'j')

RegisterCommand('+megaphone_range', function()
    if usingMegaphone then
        showRangeSelector = true
    end
end, false)
RegisterKeyMapping('+megaphone_range', 'Portée mégaphone', 'keyboard', 'i')


CreateThread(function()
    while true do
        Wait(20000)
        if usingMegaphone then
            local ped = PlayerPedId()
            if IsEntityPlayingAnim(ped, "molly@megaphone", "megaphone_clip", 3) then
                local opts = megaphoneAnim.AnimationOptions
                local pp = opts.PropPlacement
                TriggerServerEvent(
                    "vfw:newanim:spawnProp",
                    joaat(opts.Prop),
                    opts.PropBone,
                    vector3(pp[1], pp[2], pp[3]),
                    vector3(pp[4], pp[5], pp[6]),
                    1,
                    1
                )
            end
        end
    end
end)

CreateThread(function()
    while true do
        if usingMegaphone then
            Wait(0)
            DisablePlayerFiring(PlayerPedId(), true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 73, true)
            DisableControlAction(0, 36, true)
            DisableControlAction(0, 26, true)

            if showRangeSelector then
                UpdateRangeSelector()
            else
                SendSelectorState(false, 0)
            end

            SendMegaphoneHud()
            DrawMegaphoneRangeCircle()

            local isTalking = MumbleIsPlayerTalking(PlayerId())
            if isTalking and not wasTalking then
                exports['pma-voice']:overrideProximityRange(megaphoneRange / 3, true, "Mégaphone")
                TriggerServerEvent('megaphone:setTalking', true, megaphoneVolume)
                wasTalking = true
            elseif not isTalking and wasTalking then
                exports['pma-voice']:clearProximityOverride()
                TriggerServerEvent('megaphone:setTalking', false)
                wasTalking = false
            end
        else
            HideMegaphoneHud()
            SendSelectorState(false, 0)

            if wasTalking then
                exports['pma-voice']:clearProximityOverride()
                TriggerServerEvent('megaphone:setTalking', false)
                wasTalking = false
            end
            Wait(250)
        end
    end
end)
