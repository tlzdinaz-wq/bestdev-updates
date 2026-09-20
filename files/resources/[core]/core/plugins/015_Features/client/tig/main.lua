
-- Positions / tâches : core/config/tig/config.lua
local ALCATRAZ_ZONE <const> = TIGConfig.Zone
local WELCOME_TEXT_POS <const> = TIGConfig.Zone.welcomeText
local TIG_TASKS <const> = TIGConfig.Tasks

local disableAction <const> = {
    245, -- Chat (T)
    249, -- Chat (N)
    311, -- Phone (K)
    73, -- X (Hands up)
    105, -- X (Secondary)
    27, -- Phone Up
    172, -- Phone Up
    173, -- Phone Down
    174, -- Phone Left
    175, -- Phone Right
    176, -- Phone Select
    177, -- Phone Cancel
    178, -- Phone Option
    179, -- Phone Extra Option
    81, -- Radio Wheel (,)
    82 -- Radio Wheel (.)
}







local isInTIG, tigData, currentTask, taskProgress, completedPositions, assignedTask, assignedPosition, taskBlip
local hiddenBlips = {}
local sessionToken = 0

-- Masquer tous les blips sauf le blip TIG en stockant leur display d'origine
local function HideAllBlips()
    -- Parcourir tous les types de sprites (0-900 couvre tous les blips GTA + DLC récents)
    for spriteId = 0, 900 do
        local blip = GetFirstBlipInfoId(spriteId)
        while DoesBlipExist(blip) do
            -- Ne pas masquer le blip TIG, ne pas re-stocker un blip déjà masqué par nous
            if blip ~= taskBlip and hiddenBlips[blip] == nil then
                hiddenBlips[blip] = GetBlipInfoIdDisplay(blip)
                SetBlipDisplay(blip, 0)
            end
            blip = GetNextBlipInfoId(spriteId)
        end
    end
end

-- Restaurer uniquement les blips qu'on a masqués, en remettant leur display d'origine
local function RestoreAllBlips()
    for blip, originalDisplay in pairs(hiddenBlips) do
        if DoesBlipExist(blip) then
            SetBlipDisplay(blip, originalDisplay)
        end
    end
    hiddenBlips = {}
end


function IsPlayerInTIG()
    return isInTIG
end


exports('IsPlayerInTIG', IsPlayerInTIG)
VFW.IsPlayerInTIG = IsPlayerInTIG


local function CreateTaskBlip(position, taskName, sprite, color)
    if taskBlip then
        RemoveBlip(taskBlip)
    end

    taskBlip = AddBlipForCoord(position.x, position.y, position.z)
    SetBlipSprite(taskBlip, sprite or 1)
    SetBlipColour(taskBlip, color or 5)
    SetBlipScale(taskBlip, 0.5)
    SetBlipAsShortRange(taskBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(("Tache: %s"):format(taskName))
    EndTextCommandSetBlipName(taskBlip)
    SetBlipRoute(taskBlip, true)
    SetBlipRouteColour(taskBlip, color or 5)
end

local function RemoveTaskBlip()
    if not taskBlip then return end
    RemoveBlip(taskBlip)
    taskBlip = nil
end


local function AssignRandomTask()
    local availablePositions = {}

    for i = 1, #TIG_TASKS do
        local task = TIG_TASKS[i]
        for j = 1, #task.positions do
            local pos <const> = task.positions[j]
            local posKey <const> = ("%f_%f_%f"):format(pos.x, pos.y, pos.z)
            if not completedPositions[posKey] then
                availablePositions[#availablePositions + 1] = {
                    task = task,
                    position = pos,
                    posKey = posKey
                }
            end
        end
    end

    if #availablePositions == 0 then
        if tigData and tigData.completed < tigData.total then
            completedPositions = {}
            return AssignRandomTask()
        end
        assignedTask = nil
        assignedPosition = nil
        RemoveTaskBlip()
        return
    end

    local selected <const> = availablePositions[math.random(#availablePositions)]
    assignedTask = selected.task
    assignedPosition = selected.position

    CreateTaskBlip(assignedPosition, assignedTask.name, assignedTask.blipSprite, assignedTask.blipColor)
end

local function NotifyOtherSystems(status)
    pcall(function()
        if exports.chat and exports.chat.setIsInTIG then
            exports.chat:setIsInTIG(status)
        end
    end)
    TriggerEvent('vfw:tig:statusChanged', status)
    TriggerServerEvent('vfw:tig:updatePlayerStatus', status)
end

local function DrawOnScreenText(x, y, text)
    SetTextScale(0.45, 0.45)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(x, y)
end

local function StopTask()
    if not currentTask then return end

    ClearPedTasks(PlayerPedId())
    ClearAllHelpMessages()
    TriggerServerEvent("vfw:tig:stopTask")

    currentTask = nil
    taskProgress = 0
end

local function StartTask(task, position)
    currentTask = task
    currentTask.position = position
    taskProgress = 0

    local playerPed <const> = PlayerPedId()
    local animDict <const> = task.animation.dict
    local animName <const> = task.animation.anim

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

    if task.prop then
        TriggerServerEvent("vfw:tig:startTask", {
            prop = task.prop,
            taskName = task.name,
            propAttachment = task.propAttachment
        })
    end

    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 33, 0, false, false, false)

    local progress <const> = VFW.Nui.ProgressBar(task.name, currentTask.duration)

    if progress then
        local posKey <const> = ("%f_%f_%f"):format(currentTask.position.x, currentTask.position.y, currentTask.position.z)
        completedPositions[posKey] = true

        assignedTask = nil
        assignedPosition = nil
        RemoveTaskBlip()

        TriggerServerEvent("vfw:tig:completeTask")

        Wait(500)
        StopTask()

        Wait(1000)
        if tigData and tigData.completed < tigData.total then
            AssignRandomTask()
        end

        return
    end

    CreateThread(function()
        local taskPos <const> = currentTask.position

        while currentTask and taskProgress < currentTask.duration do
            Wait(100)
            taskProgress = taskProgress + 100

            if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) then

                TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 33, 0, false, false, false)
                Wait(500)

                if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) then
                    StopTask()
                    VFW.ShowNotification({
                        type = 'ROUGE',
                        content = "Tâche annulée - Animation interrompue"
                    })
                    return
                end
            end

            local playerCoords <const> = GetEntityCoords(playerPed)
            local distance <const> = #(playerCoords - taskPos)
            if distance > 5.0 then
                StopTask()
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = ("Trop éloigné de la tâche (%.1fm)"):format(distance)
                })
                return
            end
        end
    end)
end


RegisterNetEvent("vfw:tig:start", function(data)
    if not data?.total or not data?.completed then
        return
    end

    -- Re-entry guard: when the server re-fires vfw:tig:start (admin adding TIG
    -- to a player already in TIG, reconnection, etc.), do NOT respawn threads
    -- nor wipe local completion progress. Just refresh tigData and ensure a
    -- task is assigned.
    if isInTIG then
        if tigData then
            tigData.total = data.total
            tigData.completed = data.completed
            if data.reason then tigData.reason = data.reason end
        else
            tigData = data
        end
        if not currentTask and not assignedTask and tigData.completed < tigData.total then
            completedPositions = {}
            AssignRandomTask()
            HideAllBlips()
        end
        return
    end

    isInTIG = true
    tigData = data
    completedPositions = {}
    sessionToken = sessionToken + 1
    local mySession = sessionToken

    NotifyOtherSystems(true)
    AssignRandomTask()
    HideAllBlips()

    -- Thread de maintenance pour masquer les nouveaux blips créés pendant le TIG
    CreateThread(function()
        while isInTIG and sessionToken == mySession do
            Wait(5000) -- Vérifier toutes les 5 secondes
            if isInTIG and sessionToken == mySession then
                HideAllBlips()
            end
        end
    end)

    CreateThread(function()
        while isInTIG and sessionToken == mySession do
            Wait(0)

            if not tigData then
                break
            end

            local text <const> = ("Vous avez encore ~g~%s~s~ tâches à faire avant d'être libre. Allez à la ~o~prochaine tâche"):format(tigData.total - tigData.completed)
            DrawOnScreenText(0.5, 0.95, text)

            local playerCoords <const> = GetEntityCoords(PlayerPedId())
            local distance <const> = #(playerCoords - ALCATRAZ_ZONE.center)

            if distance > ALCATRAZ_ZONE.radius then
                SetEntityCoords(PlayerPedId(), ALCATRAZ_ZONE.center.x, ALCATRAZ_ZONE.center.y, ALCATRAZ_ZONE.center.z, false, false, false, false)
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Vous ne pouvez pas quitter la zone de TIG!"
                })
            end

            -- Affichage du texte 3D de bienvenue
            local distToText <const> = #(playerCoords - WELCOME_TEXT_POS)
            if distToText < 15.0 then
                VFW.Game.Utils.DrawText3D(WELCOME_TEXT_POS, "~r~Bienvenue à Alcatraz~s~", 1.2, 4)
                VFW.Game.Utils.DrawText3D(vector3(WELCOME_TEXT_POS.x, WELCOME_TEXT_POS.y, WELCOME_TEXT_POS.z - 0.12),
                    "Vous êtes ici car vous n'avez pas respecté", 0.8, 4)
                VFW.Game.Utils.DrawText3D(vector3(WELCOME_TEXT_POS.x, WELCOME_TEXT_POS.y, WELCOME_TEXT_POS.z - 0.24),
                    "les règles du serveur.", 0.8, 4)
                VFW.Game.Utils.DrawText3D(vector3(WELCOME_TEXT_POS.x, WELCOME_TEXT_POS.y, WELCOME_TEXT_POS.z - 0.40),
                    "~g~Bonne nouvelle, vous avez une chance~s~", 0.8, 4)
                VFW.Game.Utils.DrawText3D(vector3(WELCOME_TEXT_POS.x, WELCOME_TEXT_POS.y, WELCOME_TEXT_POS.z - 0.52),
                    "de revenir parmi nous mais pour cela", 0.8, 4)
                VFW.Game.Utils.DrawText3D(vector3(WELCOME_TEXT_POS.x, WELCOME_TEXT_POS.y, WELCOME_TEXT_POS.z - 0.64),
                    "vous devrez vous repentir.", 0.8, 4)

                -- Afficher la raison si disponible
                if tigData.reason then
                    VFW.Game.Utils.DrawText3D(vector3(WELCOME_TEXT_POS.x, WELCOME_TEXT_POS.y, WELCOME_TEXT_POS.z - 0.84),
                        "~y~Raison: " .. tigData.reason, 0.7, 4)
                end
            end

            for i = 1, #disableAction do
                DisableControlAction(0, disableAction[i], true)
            end
            DisablePlayerFiring(PlayerPedId(), true)

            if not currentTask and assignedTask and assignedPosition then
                local taskDist <const> = #(playerCoords - assignedPosition)

                if taskDist < 2.0 then
                    -- Pas de marker quand on est sur le point, seulement le texte d'aide
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour commencer la tâche: ~y~" .. assignedTask.name)

                    if VFW.Interact.JustPressed(0, 38) then
                        StartTask(assignedTask, assignedPosition)
                    end

                elseif taskDist < 50.0 then
                    -- Flèche jaune/orange animée pour moyenne distance
                    DrawMarker(2, assignedPosition.x, assignedPosition.y, assignedPosition.z + 1.5, 0.0, 180.0, 0.0, 0.0, 0.0, 0.0, 0.6, 0.6, 0.6, 255, 200, 0, 150, true, true, 2, false, nil, nil, false)
                end

                if taskDist > 10.0 then
                    -- Pilier de lumière fin et élégant pour longue distance
                    DrawMarker(1, assignedPosition.x, assignedPosition.y, assignedPosition.z + 10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 25.0, 255, 200, 0, 80, false, true, 2, false, nil, nil, false)
                end
            end
        end
    end)

    CreateThread(function()
        while isInTIG and sessionToken == mySession do
            Wait(5000)
            SetEntityHealth(PlayerPedId(), 200)
            SetPedArmour(PlayerPedId(), 100)

            TriggerServerEvent("vfw:status:set", "hunger", 100)
            TriggerServerEvent("vfw:status:set", "thirst", 100)
        end
    end)

    -- Stamina illimitée pendant le TIG
    CreateThread(function()
        while isInTIG and sessionToken == mySession do
            Wait(0)
            RestorePlayerStamina(PlayerId(), 1.0)
        end
    end)
end)


RegisterNetEvent("vfw:tig:stop", function()
    isInTIG = false
    sessionToken = sessionToken + 1
    tigData = nil
    completedPositions = {}
    assignedTask = nil
    assignedPosition = nil

    RestoreAllBlips()
    RemoveTaskBlip()

    if currentTask then
        StopTask()
    end

    NotifyOtherSystems(false)

    --VFW.ShowNotification({
    --    type = 'VERT',
    --    content = "Vos travaux d'intérêt général ont été annulés"
    --})
end)


RegisterNetEvent("vfw:tig:completed", function()
    isInTIG = false
    sessionToken = sessionToken + 1
    tigData = nil
    completedPositions = {}
    assignedTask = nil
    assignedPosition = nil

    RestoreAllBlips()
    RemoveTaskBlip()

    if currentTask then
        StopTask()
    end

    NotifyOtherSystems(false)
end)


RegisterNetEvent("vfw:tig:updateProgress", function(completed, total)
    if not tigData then return end

    tigData.completed = completed
    tigData.total = total

    if not currentTask and not assignedTask and completed < total then
        AssignRandomTask()
    end
end)


RegisterNetEvent("vfw:tig:taskObjectCreated", function(objectId)
end)

RegisterNetEvent("vfw:tig:statusResponse", function(tigStatus)
    if tigStatus and not isInTIG then
        TriggerEvent("vfw:tig:start", tigStatus)
    end
end)

