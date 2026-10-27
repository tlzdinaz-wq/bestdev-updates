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

-- Appui E « réservé » : image de jeu où il a été rendu (tous les handlers de cette image le voient),
-- -1 = appui ignoré, nil = pas d'appui en cours. Remis à nil au relâchement physique.
-- Bug corrigé : un menu s'ouvre sur E et prend le focus NUI ; le jeu ne voit plus la touche, l'état
-- « tenu » retombait, et au retour du focus le même appui (touche encore enfoncée) était relu comme
-- un nouveau → le menu se rouvrait aussitôt, sans curseur, et le joueur restait bloqué.
local pressFrame = nil
local FOCUS_COOLDOWN_MS = 400

--- Vrai si E doit être ignoré : une interface NUI a le focus, ou vient de le rendre.
local function blockedByNui()
    local nui = VFW.Nui
    if not nui then return false end
    if nui._hasFocus then return true end
    return GetGameTimer() - (nui._focusReleasedAt or 0) < FOCUS_COOLDOWN_MS
end

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
        -- pendant un focus NUI le jeu ne voit pas la touche : on ne relâche pas l'appui en cours
        if not held and not (VFW.Nui and VFW.Nui._hasFocus) then
            pressFrame = nil
        end
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
    if not IsDisabledControlJustPressed(idx, ctrl) then return false end
    local frame = GetFrameCount()
    if pressFrame == nil then
        -- un appui qui arrive pendant / juste après un focus NUI est ignoré jusqu'au relâchement
        pressFrame = blockedByNui() and -1 or frame
    end
    return pressFrame == frame
end

--- JustReleased for E. Reads the disabled variant so it still works while
--- the guard thread is disabling the control.
---@param idx integer
---@param ctrl integer
---@return boolean
function VFW.Interact.JustReleased(idx, ctrl)
    -- relâcher la touche qui a ouvert un menu ne doit pas déclencher une seconde action
    return IsDisabledControlJustReleased(idx, ctrl) and not blockedByNui()
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
    pressFrame = nil
end
