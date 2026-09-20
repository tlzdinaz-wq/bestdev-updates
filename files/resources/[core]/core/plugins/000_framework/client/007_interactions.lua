---@meta _
---@diagnostic disable: duplicate-doc-field

local interactions = {}
local pressedInteractions = {}
local isKeyPressed = false

---Delete VFW.Interaction
---@param name string
---@return any
function VFW.RemoveInteraction(name)
    if not interactions[name] then
        return
    end

    interactions[name] = nil
end

VFW.RegisterInteraction = function(name, onPress, condition)
    interactions[name] = {
        condition = condition or function() return true end,
        onPress = onPress
    }
end

local disabledInteractions = false
--- .DisableInterations
---@param state any
function VFW.DisableInterations(state)
    disabledInteractions = state
end

---Get VFW.InteractKey
---@return any
function VFW.GetInteractKey()
    local hash = joaat('vfw_interact') | 0x80000000
    return GetControlInstructionalButton(0, hash, true):sub(3)
end

if VFW.IsInputRegistered and VFW.IsInputRegistered("vfw_interact") then
    VFW.RemoveInput("vfw_interact")
end

VFW.RegisterInput("vfw_interact", "Interactions", "keyboard", "e", function()
    if not isKeyPressed then
        isKeyPressed = true
        for _, interaction in pairs(interactions) do
            local success, result = pcall(interaction.condition)
            if success and result and (not disabledInteractions) then
                pressedInteractions[#pressedInteractions+1] = interaction
                interaction.onPress()
            end
        end
    end
end, function()
    isKeyPressed = false
end)

RegisterNetEvent("inventory:playGiveAnim")
---@param dict any
---@param anim any
AddEventHandler("inventory:playGiveAnim", function(dict, anim)
    local playerPed = PlayerPedId()

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end

    TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, 48, 0, false, false, false)
end)
