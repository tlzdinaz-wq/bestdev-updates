local managementBlip = nil
local managementGeneration = 0

local function hasBossPermissions()
    local playerJob = VFW.PlayerData.job
    if not playerJob then
        return false
    end
    if playerJob.grade_is_boss == true or playerJob.grade_is_boss == 1 then
        return true
    end
    return playerJob.grade == 99 or playerJob.grade == 98
end

local function removeBlipIfAny()
    if managementBlip then
        RemoveBlip(managementBlip)
        managementBlip = nil
    end
end

function Society.initManagement()
    if not Society?.data?.management then return true end

    local position = Society.data.management
    if not position.x then return true end

    managementGeneration = managementGeneration + 1
    local myGeneration = managementGeneration

    local function ensureBlip()
        if managementBlip then return end
        managementBlip = AddBlipForCoord(position.x, position.y, position.z)
        SetBlipSprite(managementBlip, 590)
        SetBlipColour(managementBlip, 3)
        SetBlipScale(managementBlip, 0.5)
        SetBlipAsShortRange(managementBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(("%s • Gestion"):format(Society.data.label or "Entreprise"))
        EndTextCommandSetBlipName(managementBlip)
    end

    CreateThread(function()
        while managementGeneration == myGeneration and Society?.data?.management do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(position.x, position.y, position.z))
            local hasPerms = hasBossPermissions()

            if hasPerms then
                ensureBlip()
            else
                removeBlipIfAny()
            end

            if hasPerms and distance < 5.0 then
                DrawMarker(
                    25,
                    position.x, position.y, position.z - 0.98,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.5, 0.5, 0.5,
                    0, 0, 255, 255,
                    false, true, 2, false,
                    nil, nil, false
                )

                if distance < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le Panneau Patron")
                    if VFW.Interact.JustPressed(0, 38) then
                        VFW.BossPanel.openBossPanel()
                    end
                end

                Wait(0)
            else
                Wait(500)
            end
        end

        if managementGeneration == myGeneration then
            removeBlipIfAny()
        end
    end)

    return true
end

function Society.unloadManagement()
    managementGeneration = managementGeneration + 1
    removeBlipIfAny()
end
