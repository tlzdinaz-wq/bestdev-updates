---@meta _
---@diagnostic disable: duplicate-doc-field

if not Config.Multichar then
    return
end

RegisterNuiCallback("nui:webLoaded", function()
    CreateThread(function()
        while not VFW.PlayerLoaded do
            if NetworkIsPlayerActive(VFW.playerId) then
                DoScreenFadeOut(0)
                VFW.Nui.Visible(true)
                TriggerServerEvent("core:server:loadPlayerGlobal")
                Wait(1000)
                Multicharacter:SetupCharacters()
                break
            end
        end
    end)
end)

---@param data table
---@param slots any
RegisterNetEvent("vfw:multicharacter:SetupUI", function(data, slots)
    Multicharacter:SetupUI(data, slots)
end)

-- This is needed to update the player data before the player is fully loaded
RegisterNetEvent("vfw:loadPlayerData", function(playerData) 
    VFW.PlayerData = playerData
end)

---@param playerData number|table Player ID or object
---@param isNew any
---@param skin any
RegisterNetEvent('vfw:playerLoaded', function(playerData, isNew, skin)
    Multicharacter:PlayerLoaded(playerData, isNew, skin)
end)

RegisterNetEvent('vfw:onPlayerLogout', function()
    Multicharacter:HideHud(true)
    DoScreenFadeOut(100)
    Wait(500)

    Multicharacter.spawned = false

    Multicharacter:SetupCharacters()
end)

RegisterCommand("relog", function()
    if Multicharacter.inSelection then return end
    if IsPedInAnyVehicle(VFW.PlayerData.ped, false) or IsPedRunning(VFW.PlayerData.ped) or
            LocalPlayer.state.isCuffed or VFW.GetSafeZone() then
        return
    end


    DoScreenFadeOut(0)

    Wait(250)

    TriggerServerEvent("vfw:multicharacter:relog")
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= 'core' then return end
    if Multicharacter.characterClone then
        DeleteEntity(Multicharacter.characterClone)
    end
    VFW.Cam:Destroy("multichar")
    ClearFocus()
end)
