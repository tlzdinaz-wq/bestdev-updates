local airsoftImmune = false

RegisterNetEvent("airsoft:hit", function()
    if airsoftImmune or isKnockedOut or Death.isDead then return end

    local ped = PlayerPedId()
    SetPedToRagdoll(ped, 0, 0, 0, true, true, false)
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
end)

RegisterNetEvent("airsoft:stun", function()
    if airsoftImmune or isKnockedOut or Death.isDead then return end

    local ped = PlayerPedId()
    local duration = 5000

    airsoftImmune = true

    SetPedToRagdoll(ped, duration, duration, 0, true, true, false)
    ClearPedBloodDamage(ped)

    VFW.ShowNotification({ type = "JAUNE", content = "Vous avez été neutralisé par des billes d'airsoft !" })

    local endTime = GetGameTimer() + duration
    CreateThread(function()
        while GetGameTimer() < endTime do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)
            EnableControlAction(0, 245, true)
            Wait(0)
        end
    end)

    SetTimeout(duration + 3000, function()
        airsoftImmune = false
    end)
end)
