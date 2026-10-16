local managementBlip = nil
local managementGeneration = 0

local function hasBossPermissions()
    local playerJob = VFW.PlayerData and VFW.PlayerData.job
    if not playerJob then
        return false
    end
    if playerJob.grade_is_boss == true or playerJob.grade_is_boss == 1 or playerJob.grade_is_boss == "1"
        or playerJob.isBoss == true or playerJob.is_boss == true or playerJob.is_boss == 1
        or playerJob.is_boss == "1" then
        return true
    end

    local grade = tonumber(playerJob.grade)
    if grade == 99 or grade == 98 then return true end

    local gradeName = string.lower(tostring(playerJob.grade_name or ""))
    local gradeLabel = string.lower(tostring(playerJob.grade_label or ""))
    if gradeName == "boss" or gradeName == "patron" or gradeName == "owner" or gradeName == "pdg" then
        return true
    end
    if gradeLabel:find("patron", 1, true) or gradeLabel:find("boss", 1, true) or gradeLabel == "pdg" then
        return true
    end

    local definition = VFW.Jobs and VFW.Jobs[playerJob.name]
    local grades = definition and definition.grades
    if type(grades) == "table" then
        for _, gradeData in pairs(grades) do
            if tonumber(gradeData.grade) == grade then
                return gradeData.isBoss == true or gradeData.is_boss == true
                    or gradeData.is_boss == 1 or gradeData.is_boss == "1"
            end
        end
    end

    return false
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
