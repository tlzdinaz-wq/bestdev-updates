---@meta _
---@diagnostic disable: duplicate-doc-field

-- Initialize animator mode tracking
VFW.animatorMode = VFW.animatorMode or {}

-- Event pour recevoir la sync du mode animateur
RegisterNetEvent("vfw:animator:syncAnimatorMode", function(animatorModeList)
    VFW.animatorMode = animatorModeList or {}
end)

-- Global helper function to check if player is in staff mode (client-side)
-- Inclut aussi le mode animateur pour permettre l'utilisation des commandes staff
function VFW.IsInStaffMode()
    local myServerId = GetPlayerServerId(PlayerId())

    -- Check staff mode classique
    if VFW.staffMode then
        for _, staffId in ipairs(VFW.staffMode) do
            if staffId == myServerId then
                return true
            end
        end
    end

    -- Check animator mode (permet aux animateurs d'utiliser les commandes staff)
    if VFW.animatorMode then
        for _, animatorId in ipairs(VFW.animatorMode) do
            if animatorId == myServerId then
                return true
            end
        end
    end

    return false
end

-- Helper function to check if player is ONLY in animator mode (not staff mode)
function VFW.IsInAnimatorMode()
    if not VFW.animatorMode then
        return false
    end

    local myServerId = GetPlayerServerId(PlayerId())
    for _, animatorId in ipairs(VFW.animatorMode) do
        if animatorId == myServerId then
            return true
        end
    end

    return false
end

-- Helper function for commands that require staff mode
function VFW.RequireStaffMode(commandName, callback)
    RegisterCommand(commandName, function(...)
        if not VFW.IsInStaffMode() then
            return
        end

        callback(...)
    end, false)
end
