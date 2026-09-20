-- ========================================================================
-- VIP PPA (Port d'Armes) CLIENT HANDLER
-- Handles NUI callbacks and events for PPA claim system
-- ========================================================================

local VIPPPA_Client = {}

-- State variables
local isOverlayOpen = false
local currentPermitData = nil

-- ========================================================================
-- NUI CALLBACKS
-- ========================================================================

-- Request PPA status from server
RegisterNUICallback("vip:ppa:requestStatus", function(data, cb)
    local status = TriggerServerCallback("vip:ppa:getStatus")
    cb(status or { canClaim = false, reason = "error", message = "Action impossible pour le moment" })
end)

-- Request PPA claim by type from PaidShop VIP menu (no overlay, just claim + notif)
RegisterNUICallback("vip:ppa:requestClaimByType", function(data, cb)
    local ppaType = data.ppaType or "leger"
    if ppaType ~= "leger" and ppaType ~= "lourd" then
        cb({ success = false, message = "Ce type de PPA n'est pas valide" })
        return
    end

    local callbackName = ppaType == "leger" and "vip:ppa:claimLeger" or "vip:ppa:claimLourd"
    local result = TriggerServerCallback(callbackName)

    if not result then
        cb({ success = false, message = "Action impossible pour le moment" })
        return
    end

    if result.success then
        -- Update client-side license cache
        local licenseType = ppaType == "leger" and "ppa_leger" or "ppa_lourd"
        if VFW.PlayerData then
            if not VFW.PlayerData.licenses then
                VFW.PlayerData.licenses = {}
            end
            VFW.PlayerData.licenses[licenseType] = true
        end

        VFW.ShowNotification({ type = "VERT", content = result.message })
    else
        VFW.ShowNotification({ type = "ROUGE", content = result.message })
    end

    cb({ success = result.success, message = result.message })
end)

-- Request PPA claim from server
RegisterNUICallback("vip:ppa:requestClaim", function(data, cb)
    local result = TriggerServerCallback("vip:ppa:requestClaim")

    if not result then
        cb({ success = false, message = "Action impossible pour le moment" })
        return
    end

    if result.success then
        currentPermitData = result.permitData
    end

    cb(result)
end)

-- Card clicked - confirm claim and close overlay
RegisterNUICallback("vip:ppa:cardClicked", function(data, cb)
    if currentPermitData and not currentPermitData.isRefusal then
        -- Notify server that card was claimed
        TriggerServerEvent("vip:ppa:confirmCardClaim")
    end

    VFW.Nui.Focus(false)

    isOverlayOpen = false
    currentPermitData = nil

    cb({ success = true })
end)

-- Close overlay without claiming
RegisterNUICallback("vip:ppa:closeOverlay", function(data, cb)
    VFW.Nui.Focus(false)

    isOverlayOpen = false
    currentPermitData = nil
    cb({ success = true })
end)

-- ========================================================================
-- PPA CLAIM FROM F5 MENU
-- ========================================================================

-- Claim PPA Léger from F5 menu
function VIPPPA_Client.ClaimPPAFromMenu(ppaType)
    -- Prevent double-click / re-entry
    if isOverlayOpen then return end

    local callbackName = ppaType == "leger" and "vip:ppa:claimLeger" or "vip:ppa:claimLourd"
    local result = TriggerServerCallback(callbackName)

    if not result or not result.permitData then
        VFW.ShowNotification({
            type = 'ERROR',
            mainMessage = "Erreur lors de la demande de PPA",
            duration = 5
        })
        return
    end

    -- Update client-side license cache so F5 documents menu sees the new license
    if result.success then
        local licenseType = ppaType == "leger" and "ppa_leger" or "ppa_lourd"
        if VFW.PlayerData then
            if not VFW.PlayerData.licenses then
                VFW.PlayerData.licenses = {}
            end
            VFW.PlayerData.licenses[licenseType] = true
        end
    end

    -- Get player photo for the card
    local identityData = TriggerServerCallback("identity:getData", GetPlayerServerId(PlayerId()))
    local photo = identityData and identityData.photo or nil

    local permitData = result.permitData
    permitData.photoUrl = photo

    -- Enable NUI focus (cursor)

    VFW.Nui.Focus(true, false)

    -- Send NUI message to show overlay (obtention or refusal)
    SendNUIMessage({
        action = "vip:ppa:showOverlay",
        data = permitData
    })

    isOverlayOpen = true
    currentPermitData = permitData
end

-- Expose for menuf5.lua
_G.VIPPPA_ClaimFromMenu = function(ppaType)
    VIPPPA_Client.ClaimPPAFromMenu(ppaType)
end

-- ========================================================================
-- CLIENT EVENTS
-- ========================================================================

-- Close PPA claim overlay
RegisterNetEvent("vip:ppa:closeOverlay")
AddEventHandler("vip:ppa:closeOverlay", function()
    VFW.Nui.Focus(false)

    isOverlayOpen = false
    currentPermitData = nil

    SendNUIMessage({
        action = "vip:ppa:hide"
    })
end)

-- ========================================================================
-- EXPORTS
-- ========================================================================

-- Check if overlay is currently open
exports("IsPPAOverlayOpen", function()
    return isOverlayOpen
end)

-- ========================================================================
-- CLEANUP
-- ========================================================================

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if isOverlayOpen then
        VFW.Nui.Focus(false)
        SendNUIMessage({ action = "vip:ppa:hide" })
        isOverlayOpen = false
        currentPermitData = nil
    end
end)

