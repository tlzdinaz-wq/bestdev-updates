---@meta _
---@diagnostic disable: duplicate-doc-field

Worlds.Interact = {}
Worlds.Interact.Input = {}

local interactions = {}
local pressedInteractions = {}
local isKeyPressed = false

---Delete Worlds.Interact.
---@param name string
---@return any
function Worlds.Interact.Remove(name)
    if not interactions[name] then
        return
    end

    interactions[name] = nil
end

Worlds.Interact.Create = function(name, onPress, condition)
    interactions[name] = {
        condition = condition or function() return true end,
        onPress = onPress
    }
end

local disabledInteractions = false
--- .Interact.Disable
---@param state any
function Worlds.Interact.Disable(state)
    disabledInteractions = state
end

---Get Worlds.Interact.
---@return any
function Worlds.Interact.Get()
    local hash = joaat('vfw_interact') | 0x80000000
    return GetControlInstructionalButton(0, hash, true):sub(3)
end

if VFW.IsInputRegistered and VFW.IsInputRegistered("vfw_interact") then
    VFW.RemoveInput("vfw_interact")
end

---Register Input
---@param command_name string
---@param label string
---@param input_group any
---@param key any
---@param on_press any
---@param on_release any
local function RegisterInput(command_name, label, input_group, key, on_press, on_release)
    local command = on_release and '+' .. command_name or command_name
    RegisterCommand(command, on_press, false)
    Worlds.Interact.Input[command_name] = joaat(command)
    if on_release then
        RegisterCommand('-' .. command_name, on_release, false)
    end

    RegisterKeyMapping(command, label or '', input_group or 'keyboard', key or '')
end

