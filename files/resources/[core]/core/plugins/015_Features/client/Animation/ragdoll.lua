---@meta _
---@diagnostic disable: duplicate-doc-field

local isRagdoll = false

RegisterCommand('ragdoll', function()
    if IsPlayerInMugshot() then return end
    if VFW.isEscorting then return end

    local ped = VFW.PlayerData.ped
    if not DoesEntityExist(ped) then return end
    if IsEntityDead(ped) or (Death and Death.isDead) or isKnockedOut then return end
    if IsPedInAnyVehicle(ped, false) then return end
    if not IsPedOnFoot(ped) then return end
    if isRagdoll then return end

    isRagdoll = true

    CreateThread(function()
        while isRagdoll do
            local curPed = VFW.PlayerData.ped
            if not DoesEntityExist(curPed) or IsEntityDead(curPed) or (Death and Death.isDead) or isKnockedOut or IsPedInAnyVehicle(curPed, false) then
                isRagdoll = false
                break
            end

            if not IsPedRagdoll(curPed) then
                SetPedToRagdoll(curPed, 2000, 2000, 0, false, false, false)
            end

            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vous relever")

            if VFW.Interact.JustPressed(0, 38) then
                isRagdoll = false
                break
            end

            Wait(0)
        end
    end)
end, false)
RegisterKeyMapping('ragdoll', "Tomber au sol", 'keyboard', 'J')
VFW.AddChatSuggestion('/ragdoll', "Tomber au sol (appuyez sur E pour vous relever)")
