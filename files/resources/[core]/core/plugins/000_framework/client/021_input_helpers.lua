---@diagnostic disable: duplicate-doc-field

-- VFW.Interact - E key (controls 38/51) hold-guard + disable-aware helpers.
--
-- Problem
-- -------
-- ~178 handlers in the codebase read IsControlJustPressed(0, 38|51).
-- When E is HELD, the engine re-fires JustPressed every frame because
-- other scripts toggle DisableControlAction between frames (mining,
-- lumberjack, harvesting, weazel/lifeinvader props, dvm, labo, vehicle_push,
-- inventory...). 178 handlers firing every frame -> server-event storm ->
-- core thread deadloop -> watchdog crash.
--
-- Strategy
-- --------
-- 1. A guard thread disables controls 38/51 across all groups for as long
--    as the key is PHYSICALLY held after the first press. This silences
--    re-fires at the engine level.
-- 2. The helpers below read the DISABLED variants of the natives, so
--    handlers still see the press/release exactly once per physical tap
--    even while the guard is active. This is what was missing in the
--    previous global debouncer (which only exposed an unused IsConsumed
--    API and broke every IsControlJustReleased/IsControlPressed caller).
--
-- Migration
-- ---------
--   IsControlJustPressed(0, 38)  -> VFW.Interact.JustPressed(0, 38)
--   IsControlJustReleased(0, 51) -> VFW.Interact.JustReleased(0, 51)
--   IsControlPressed(0, 38)      -> VFW.Interact.Pressed(0, 38)

VFW = VFW or {}
VFW.Interact = VFW.Interact or {}

local TARGET_CONTROLS = { 38, 51 }
local CONTROL_GROUPS = { 0, 1, 2 }

-- consumed = true after the first physical press of the current hold
-- cycle has been observed. While consumed, the guard thread disables E.
-- Reset on physical release.
local consumed = false

local function physicallyHeld()
    for i = 1, #CONTROL_GROUPS do
        local g = CONTROL_GROUPS[i]
        for j = 1, #TARGET_CONTROLS do
            if IsDisabledControlPressed(g, TARGET_CONTROLS[j]) then
                return true
            end
        end
    end
    return false
end

local function physicallyJustPressed()
    for i = 1, #CONTROL_GROUPS do
        local g = CONTROL_GROUPS[i]
        for j = 1, #TARGET_CONTROLS do
            if IsDisabledControlJustPressed(g, TARGET_CONTROLS[j]) then
                return true
            end
        end
    end
    return false
end

local function disableTargetControls()
    for i = 1, #CONTROL_GROUPS do
        local g = CONTROL_GROUPS[i]
        for j = 1, #TARGET_CONTROLS do
            DisableControlAction(g, TARGET_CONTROLS[j], true)
        end
    end
end

CreateThread(function()
    while true do
        local held = physicallyHeld()
        if consumed then
            disableTargetControls()
            if not held then
                consumed = false
            end
        else
            if physicallyJustPressed() then
                consumed = true
            end
        end
        Wait(0)
    end
end)

--- Rate-limited JustPressed for E. Returns true at most once per physical
--- press cycle, regardless of how many times the engine re-fires.
---@param idx integer Control group (0, 1, 2)
---@param ctrl integer Control id (38 or 51)
---@return boolean
function VFW.Interact.JustPressed(idx, ctrl)
    return IsDisabledControlJustPressed(idx, ctrl)
end

--- JustReleased for E. Reads the disabled variant so it still works while
--- the guard thread is disabling the control.
---@param idx integer
---@param ctrl integer
---@return boolean
function VFW.Interact.JustReleased(idx, ctrl)
    return IsDisabledControlJustReleased(idx, ctrl)
end

--- Pressed for E. Reads the disabled variant so it still reflects the real
--- key state while the guard thread is disabling the control.
---@param idx integer
---@param ctrl integer
---@return boolean
function VFW.Interact.Pressed(idx, ctrl)
    return IsDisabledControlPressed(idx, ctrl)
end

--- Manually clear the consumed flag. Useful for tests.
function VFW.Interact.ResetCooldown()
    consumed = false
end
