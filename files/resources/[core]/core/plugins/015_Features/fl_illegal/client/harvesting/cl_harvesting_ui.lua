-- Variable partagée avec cl_harvesting_spots.lua (globale dans les deux fichiers)
isHarvesting = false

local harvestWatchdogToken = 0

local currentAnimDict = nil
local currentAnimName = nil

function ShowHarvestingNotification(type, message)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({
            type = type,
            content = message
        })
    else
        print(("[%s] %s"):format(type or "INFO", message))
    end
end

RegisterNetEvent('illegalHarvesting:notify', function(type, message)
    ShowHarvestingNotification(type, message)
end)

RegisterNetEvent('illegalHarvesting:startHarvestProgress', function(data)
    if isHarvesting then
        return
    end

    isHarvesting = true

    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true)

    local animDict, animName
    if data.animationType == "table" then
        animDict = "missmechanic"
        animName = "work2_in"
    else -- standing
        animDict = "missmechanic"
        animName = "work2_in"
    end

    RequestAnimDict(animDict)
    local animTimeout = 0
    while not HasAnimDictLoaded(animDict) and animTimeout < 3000 do
        Citizen.Wait(10)
        animTimeout = animTimeout + 10
    end

    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Stocker l'animation courante pour pouvoir l'arrêter
    currentAnimDict = animDict
    currentAnimName = animName

    VFW.Nui.Focus(false)

    SendNUIMessage({
        action = 'illegalHarvesting:startProgress',
        data = data
    })

    ShowHarvestingNotification("JAUNE", "~y~Récolte en cours...")

    -- Watchdog: si le serveur ne renvoie jamais harvestComplete/cancelHarvest,
    -- libère le joueur après harvestTime + marge de sécurité.
    harvestWatchdogToken = harvestWatchdogToken + 1
    local myToken = harvestWatchdogToken
    local harvestTime = tonumber(data.harvestTime) or 10000
    local maxWaitTime = harvestTime + 5000
    Citizen.CreateThread(function()
        local elapsed = 0
        while isHarvesting and harvestWatchdogToken == myToken do
            Citizen.Wait(500)
            elapsed = elapsed + 500
            if elapsed >= maxWaitTime then
                if isHarvesting and harvestWatchdogToken == myToken then
                    StopHarvestingAnimation()
                    isHarvesting = false
                    SendNUIMessage({
                        action = 'illegalHarvesting:hideProgress',
                        data = {}
                    })
                    ShowHarvestingNotification("ROUGE", "~r~Récolte interrompue : le serveur n'a pas répondu")
                end
                return
            end
        end
    end)
end)

RegisterNetEvent('illegalHarvesting:harvestComplete', function()
    harvestWatchdogToken = harvestWatchdogToken + 1
    StopHarvestingAnimation()
    isHarvesting = false

    SendNUIMessage({
        action = 'illegalHarvesting:hideProgress',
        data = {}
    })
end)

RegisterNetEvent('illegalHarvesting:cancelHarvest', function()
    harvestWatchdogToken = harvestWatchdogToken + 1
    StopHarvestingAnimation()
    isHarvesting = false
    ShowHarvestingNotification("JAUNE", "~y~Récolte annulée")

    SendNUIMessage({
        action = 'illegalHarvesting:hideProgress',
        data = {}
    })
end)

function StopHarvestingAnimation()
    local playerPed = PlayerPedId()

    if currentAnimDict and currentAnimName then
        StopAnimTask(playerPed, currentAnimDict, currentAnimName, 1.0)
        RemoveAnimDict(currentAnimDict)
    end

    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)

    -- Reset des variables d'animation
    currentAnimDict = nil
    currentAnimName = nil
end

function CancelHarvesting()
    if isHarvesting then
        harvestWatchdogToken = harvestWatchdogToken + 1
        StopHarvestingAnimation()
        isHarvesting = false

        TriggerServerEvent('illegalHarvesting:cancelHarvest')

        SendNUIMessage({
            action = 'illegalHarvesting:hideProgress',
            data = {}
        })
    end
end

-- Callback NUI pour annulation
RegisterNUICallback('illegalHarvesting:cancel', function(data, cb)
    CancelHarvesting()
    cb('ok')
end)

-- Thread pour la gestion des contrôles
Citizen.CreateThread(function()
    while true do
        if isHarvesting then
            local playerPed = PlayerPedId()

            -- Si le joueur meurt pendant la récolte, on cancel pour éviter
            -- que DisableAllControlActions ne reste actif après respawn.
            if IsEntityDead(playerPed) or IsPedDeadOrDying(playerPed, true) then
                CancelHarvesting()
                Citizen.Wait(500)
            else
                if IsControlJustPressed(0, 73) then -- X key
                    CancelHarvesting()
                end

                DisableJobMovementControls()

                Citizen.Wait(0)
            end
        else
            Citizen.Wait(500)
        end
    end
end)

-- Cleanup si la resource s'arrête pendant une récolte (sinon FreezeEntityPosition
-- persiste au niveau engine GTA même après reload du Lua).
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isHarvesting then
            harvestWatchdogToken = harvestWatchdogToken + 1
            StopHarvestingAnimation()
            isHarvesting = false
        else
            -- Garantir le défreeze même si le flag a été perdu
            FreezeEntityPosition(PlayerPedId(), false)
        end
    end
end)