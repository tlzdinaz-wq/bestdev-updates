---@meta _
---@diagnostic disable: duplicate-doc-field

---@return boolean
function VFW.IsPlayerLoaded()
    return VFW.PlayerLoaded
end

---@return table
function VFW.GetPlayerData()
    return VFW.PlayerData
end

---@param items string | table The item(s) to search for
---@param count? boolean Whether to return the count of the item as well
---@return table | number
function VFW.SearchInventory(items, count)
    local item
    if type(items) == 'string' then
        item, items = items, { items }
    end

    local data = {}

    for i = 1, #VFW.PlayerData.inventory do
        local e = VFW.PlayerData.inventory[i]

        for ii = 1, #items do
            if e.name == items[ii] then
                data[table.remove(items, ii)] = count and e.count or e
                break
            end
        end

        if #items == 0 then
            break
        end
    end

    return not item and data or data[item]
end

---@param key string Table key to set
---@param val any Value to set
---@return nil
function VFW.SetPlayerData(key, val)
    local current = VFW.PlayerData[key]
    VFW.PlayerData[key] = val
    if key ~= "inventory" and key ~= "loadout" then
        if type(val) == "table" or val ~= current then
            TriggerEvent("vfw:setPlayerData", key, val, current)
        end
    end
end

---@param freeze boolean Whether to freeze the player
---@return nil
function Core.FreezePlayer(freeze)
    local ped = PlayerPedId()
    SetPlayerControl(VFW.playerId, not freeze, 0)

    -- This prevents players from falling through ground during freeze
    FreezeEntityPosition(ped, freeze)
end

---@param skin table Skin data to set
---@param coords table Coords to spawn the player at
---@param cb function Callback function
---@return nil
function VFW.SpawnPlayer(skin, coords, cb)
    local p = promise.new()

    TriggerEvent("skinchanger:loadSkin", skin, function()
        p:resolve()
    end)

    Citizen.Await(p)

    local playerPed = PlayerPedId()

    -- Freeze player and disable controls
    Core.FreezePlayer(true)

    -- Make player invisible and invincible during spawn
    SetEntityVisible(playerPed, false, false)
    SetEntityInvincible(playerPed, true)

    -- Remove all weapons before spawn (prevent weapon duplication)
    RemoveAllPedWeapons(playerPed, false)

    -- Initial spawn coordinates (ground detection will happen AFTER collision loads)
    local spawnCoords = vector3(coords.x, coords.y, coords.z)

    -- Teleport the player while frozen and invisible
    SetEntityCoordsNoOffset(playerPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, true)
    SetEntityHeading(playerPed, coords.heading)

    RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    NewLoadSceneStart(spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.x, spawnCoords.y, spawnCoords.z, 50.0, 0)

    local sceneTimer = GetGameTimer()
    while not IsNewLoadSceneLoaded() and (GetGameTimer() - sceneTimer) < 2000 do
        Wait(0)
    end

    NewLoadSceneStop()

    -- Wait for collision to load around entity, keep resetting position
    local collisionTimer = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(playerPed) and (GetGameTimer() - collisionTimer) < 2000 do
        RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
        SetEntityCoordsNoOffset(playerPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, true)
        Wait(0)
    end

    -- Preserve camera angles before resurrection
    local gameplayCamHeading = GetGameplayCamRelativeHeading()
    local gameplayCamPitch = GetGameplayCamRelativePitch()

    -- Resurrect player (keep invincible during this)
    NetworkResurrectLocalPlayer(spawnCoords.x, spawnCoords.y, spawnCoords.z, coords.heading, 0, true)

    -- Restore camera angles to prevent camera snap
    SetGameplayCamRelativeHeading(gameplayCamHeading)
    SetGameplayCamRelativePitch(gameplayCamPitch, 1.0)

    -- Clear all tasks to prevent animation state carryover
    ClearPedTasksImmediately(playerPed)

    -- Set health to max
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))

    -- Now make player visible and vulnerable after everything is complete
    SetEntityVisible(playerPed, true, false)
    SetEntityInvincible(playerPed, false)

    -- Clear focus to release streaming priority
    ClearFocus()

    -- Trigger spawn event
    TriggerEvent('playerSpawned', spawnCoords)

    cb()
end

---@param message string
---@param length? number Timeout in milliseconds
---@param options? ProgressBarOptions
---@return boolean Success Whether the progress bar was successfully created or not
function VFW.Progressbar(message, length, options)
    --todo progressbar
end

--- Annule la barre de progression en cours.
function VFW.CancelProgressbar()
    --todo progressbar
end

local ICONS <const> = {
    ["VERT"] = '<svg xmlns="http://www.w3.org/2000/svg" width="9" height="7" viewBox="0 0 9 7" fill="none"><path d="M3.0568 6.86252L0.131797 3.81174C-0.0439322 3.62846 -0.0439322 3.33128 0.131797 3.14798L0.768178 2.48422C0.943907 2.30091 1.22885 2.30091 1.40458 2.48422L3.375 4.53935L7.59542 0.137464C7.77115 -0.0458212 8.05609 -0.0458212 8.23182 0.137464L8.8682 0.801228C9.04393 0.984513 9.04393 1.28169 8.8682 1.46499L3.6932 6.86254C3.51745 7.04582 3.23253 7.04582 3.0568 6.86252Z" fill="white"/></svg>',
    ["ROUGE"] = '<svg xmlns="http://www.w3.org/2000/svg" width="7" height="7" viewBox="0 0 7 7" fill="none"><path d="M1.25732 0L0 1.25732L0.642038 1.89936L2.2293 3.51338L0.642038 5.10064L0 5.71592L1.25732 7L1.89936 6.35796L3.51338 4.74395L5.10064 6.35796L5.71592 7L7 5.71592L6.35796 5.10064L4.74395 3.51338L6.35796 1.89936L7 1.25732L5.71592 0L5.10064 0.642038L3.51338 2.2293L1.89936 0.642038L1.25732 0Z" fill="white"/></svg>',
    ["VIOLET"] = '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="7" viewBox="0 0 8 7" fill="none"><path d="M4.65583 0L4.25453 0.367883L4.84905 0.912895C4.93079 0.998054 4.97167 1.09684 4.97167 1.20925C4.97167 1.32165 4.93079 1.42725 4.84905 1.50219L3.52996 2.73187L3.90153 3.09976L5.25035 1.87007C5.44728 1.6691 5.54389 1.44769 5.54389 1.20925C5.54389 0.970803 5.44728 0.745985 5.25035 0.545012L4.65583 0ZM3.17696 0.688078L2.77566 1.05596L3.00232 1.24672C3.08407 1.32165 3.12494 1.42384 3.12494 1.54988C3.12494 1.67591 3.08407 1.7781 3.00232 1.85304L2.77566 2.0438L3.17696 2.41168L3.38504 2.20389C3.58198 2.00292 3.6823 1.78491 3.6823 1.54988C3.6823 1.30462 3.58198 1.08321 3.38504 0.878832L3.17696 0.688078ZM7.05992 1.22968C6.80353 1.22968 6.56572 1.32165 6.34649 1.50219L4.25453 3.42336L4.65583 3.76399L6.72921 1.87007C6.82211 1.78491 6.93358 1.74063 7.05992 1.74063C7.18625 1.74063 7.29772 1.78491 7.39062 1.87007L7.61728 2.07786L8 1.70998L7.79192 1.50219C7.57269 1.32165 7.32745 1.22968 7.05992 1.22968ZM1.85787 2.23114L0 7L5.20204 5.29684L1.85787 2.23114ZM6.31677 3.27348C6.05666 3.27348 5.81886 3.36545 5.59591 3.54599L5.00511 4.08759L5.40641 4.45547L5.99721 3.91387C6.09011 3.82871 6.19415 3.78443 6.31677 3.78443C6.43939 3.78443 6.55086 3.82871 6.64375 3.91387L7.2457 4.45547L7.63586 4.10462L7.04134 3.54599C6.82211 3.36545 6.57687 3.27348 6.31677 3.27348Z" fill="white"/></svg>',
    ["BLEU"] = '<svg xmlns="http://www.w3.org/2000/svg" width="7" height="9" viewBox="0 0 7 9" fill="none"><path d="M6 5.58464C6 7.11884 5.0342 8.08464 3.5 8.08464C1.9658 8.08464 1 7.11884 1 5.58464C1 3.93828 2.79219 1.71571 3.34184 1.07283C3.3614 1.04999 3.38567 1.03165 3.41299 1.01908C3.4403 1.00651 3.47002 1 3.50009 1C3.53016 1 3.55987 1.00651 3.58719 1.01908C3.6145 1.03165 3.63878 1.04999 3.65833 1.07283C4.20781 1.71571 6 3.93828 6 5.58464Z" stroke="white" stroke-width="1.2" stroke-miterlimit="10"/><path d="M5.02832 5.72314C5.02832 6.05467 4.89662 6.37261 4.6622 6.60703C4.42778 6.84145 4.10984 6.97314 3.77832 6.97314" stroke="white" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    ["JAUNE"] = '<svg xmlns="http://www.w3.org/2000/svg" width="5" height="16" viewBox="0 0 5 16" fill="none"><path d="M4.27532 5.43359L0.246235 5.93855L0.101963 6.60713L0.893703 6.75316C1.41097 6.87632 1.51302 7.06282 1.40042 7.57833L0.101963 13.68C-0.239366 15.2582 0.286702 16.0007 1.52358 16.0007C2.48246 16.0007 3.59618 15.5573 4.10113 14.9486L4.25596 14.2166C3.90408 14.5263 3.39033 14.6495 3.049 14.6495C2.56516 14.6495 2.38921 14.3099 2.51413 13.7117L4.27532 5.43359Z" fill="white"/><path d="M2.64224 3.51885C3.61394 3.51885 4.40166 2.73113 4.40166 1.75942C4.40166 0.787721 3.61394 0 2.64224 0C1.67053 0 0.882812 0.787721 0.882812 1.75942C0.882812 2.73113 1.67053 3.51885 2.64224 3.51885Z" fill="white"/></svg>',
    ["BLANC"] = '<svg xmlns="http://www.w3.org/2000/svg" width="9" height="8" viewBox="0 0 9 8" fill="none"><path d="M6.21592 2.09998C5.73186 1.64673 5.10368 1.39828 4.43726 1.39887C3.23791 1.39992 2.2025 2.22227 1.91662 3.363C1.89581 3.44604 1.82183 3.50467 1.73622 3.50467H0.848946C0.732848 3.50467 0.644652 3.39927 0.666128 3.28517C1.00115 1.50608 2.56317 0.160156 4.43961 0.160156C5.46848 0.160156 6.40283 0.564843 7.09223 1.22367L7.64524 0.67066C7.87934 0.436559 8.27961 0.60236 8.27961 0.933436V3.00919C8.27961 3.21443 8.11324 3.3808 7.908 3.3808H5.83224C5.50117 3.3808 5.33537 2.98053 5.56947 2.74641L6.21592 2.09998ZM0.971222 4.61951H3.04697C3.37805 4.61951 3.54385 5.01979 3.30975 5.2539L2.6633 5.90035C3.14736 6.35361 3.77558 6.60207 4.44203 6.60146C5.64076 6.60038 6.67658 5.77859 6.9626 4.63735C6.98341 4.55431 7.05739 4.49567 7.143 4.49567H8.03029C8.14639 4.49567 8.23458 4.60107 8.21311 4.71517C7.87807 6.49424 6.31605 7.84016 4.43961 7.84016C3.41074 7.84016 2.47639 7.43547 1.78699 6.77665L1.23398 7.32965C0.999883 7.56375 0.599609 7.39795 0.599609 7.06688V4.99112C0.599609 4.78589 0.765984 4.61951 0.971222 4.61951Z" fill="white"/></svg>',
    ["CLOCHE"] = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M9.9812 7.77558L9.1652 6.95504V4.93318C9.17605 4.18238 8.91489 3.453 8.42995 2.87973C7.945 2.30645 7.26901 1.928 6.5268 1.81424C6.09604 1.75752 5.65815 1.7933 5.24232 1.91922C4.8265 2.04514 4.44231 2.25829 4.11539 2.54445C3.78847 2.83062 3.52634 3.18321 3.34649 3.5787C3.16663 3.9742 3.07319 4.4035 3.0724 4.83798V6.95504L2.2564 7.77558C2.1539 7.87978 2.08439 8.01189 2.05657 8.15538C2.02874 8.29887 2.04383 8.44738 2.09994 8.58235C2.15605 8.71731 2.25071 8.83274 2.37206 8.9142C2.49342 8.99567 2.6361 9.03956 2.78226 9.04038H4.30546V9.19451C4.32664 9.65473 4.52939 10.0878 4.86928 10.3988C5.20918 10.7098 5.65851 10.8734 6.1188 10.8537C6.57909 10.8734 7.02841 10.7098 7.36831 10.3988C7.7082 10.0878 7.91095 9.65473 7.93213 9.19451V9.04038H9.45533C9.60149 9.03956 9.74417 8.99567 9.86553 8.9142C9.98688 8.83274 10.0815 8.71731 10.1377 8.58235C10.1938 8.44738 10.2089 8.29887 10.181 8.15538C10.1532 8.01189 10.0837 7.87978 9.9812 7.77558ZM7.02546 9.19451C7.00032 9.41256 6.89202 9.61251 6.72312 9.75269C6.55422 9.89288 6.33775 9.9625 6.1188 9.94704C5.89984 9.9625 5.68337 9.89288 5.51447 9.75269C5.34557 9.61251 5.23727 9.41256 5.21213 9.19451V9.04038H7.02546V9.19451ZM3.17666 8.13371L3.7116 7.59878C3.79645 7.51443 3.86376 7.41412 3.90967 7.30364C3.95557 7.19316 3.97916 7.07468 3.97906 6.95504V4.83798C3.97931 4.53216 4.04497 4.22993 4.17164 3.95158C4.2983 3.67322 4.48304 3.42519 4.71346 3.22411C4.94077 3.01815 5.21012 2.86405 5.50287 2.77247C5.79562 2.68089 6.10477 2.65401 6.40893 2.69371C6.9332 2.77883 7.40907 3.05049 7.74893 3.45865C8.0888 3.86682 8.26977 4.38402 8.25853 4.91504V6.95504C8.25784 7.07437 8.28071 7.19265 8.32583 7.30312C8.37095 7.41358 8.43743 7.51406 8.52146 7.59878L9.06093 8.13371H3.17666Z" fill="white"/></svg>',
    ["DOLLAR"] = '<svg xmlns="http://www.w3.org/2000/svg" width="5" height="8" viewBox="0 0 5 8" fill="none"><path d="M3.63209 3.64687L1.75669 3.15313C1.53963 3.09688 1.38855 2.91406 1.38855 2.71094C1.38855 2.45625 1.61777 2.25 1.90082 2.25H3.05211C3.26396 2.25 3.47234 2.30781 3.64598 2.41406C3.75191 2.47812 3.8943 2.4625 3.9846 2.38281L4.58889 1.85156C4.71218 1.74375 4.69482 1.56406 4.55764 1.46875C4.1322 1.16875 3.60084 1.00156 3.05558 1V0.25C3.05558 0.1125 2.93055 0 2.77774 0H2.22207C2.06926 0 1.94423 0.1125 1.94423 0.25V1H1.90082C0.794677 1 -0.0944028 1.85469 0.00804979 2.86875C0.0809821 3.58906 0.692225 4.175 1.46322 4.37813L3.24312 4.84688C3.46018 4.90469 3.61125 5.08594 3.61125 5.28906C3.61125 5.54375 3.38204 5.75 3.09899 5.75H1.9477C1.73585 5.75 1.52747 5.69219 1.35382 5.58594C1.2479 5.52188 1.10551 5.5375 1.01521 5.61719L0.410914 6.14844C0.287624 6.25625 0.304989 6.43594 0.442171 6.53125C0.867609 6.83125 1.39897 6.99844 1.94423 7V7.75C1.94423 7.8875 2.06926 8 2.22207 8H2.77774C2.93055 8 3.05558 7.8875 3.05558 7.75V6.99687C3.86478 6.98281 4.62362 6.55 4.89104 5.86094C5.26439 4.89844 4.63752 3.91094 3.63209 3.64687Z" fill="white"/></svg>',
    ["SYNC"] = '<svg xmlns="http://www.w3.org/2000/svg" width="9" height="8" viewBox="0 0 9 8" fill="none"><path d="M6.21592 2.09998C5.73186 1.64673 5.10368 1.39828 4.43726 1.39887C3.23791 1.39992 2.2025 2.22227 1.91662 3.363C1.89581 3.44604 1.82183 3.50467 1.73622 3.50467H0.848946C0.732848 3.50467 0.644652 3.39927 0.666128 3.28517C1.00115 1.50608 2.56317 0.160156 4.43961 0.160156C5.46848 0.160156 6.40283 0.564843 7.09223 1.22367L7.64524 0.67066C7.87934 0.436559 8.27961 0.60236 8.27961 0.933436V3.00919C8.27961 3.21443 8.11324 3.3808 7.908 3.3808H5.83224C5.50117 3.3808 5.33537 2.98053 5.56947 2.74641L6.21592 2.09998ZM0.971222 4.61951H3.04697C3.37805 4.61951 3.54385 5.01978 3.30975 5.2539L2.6633 5.90035C3.14736 6.35361 3.77558 6.60207 4.44203 6.60146C5.64076 6.60038 6.67658 5.77859 6.9626 4.63735C6.98341 4.55431 7.05739 4.49567 7.143 4.49567H8.03029C8.14639 4.49567 8.23458 4.60107 8.21311 4.71517C7.87807 6.49424 6.31605 7.84016 4.43961 7.84016C3.41074 7.84016 2.47639 7.43547 1.78699 6.77665L1.23398 7.32965C0.999883 7.56375 0.599609 7.39795 0.599609 7.06688V4.99112C0.599609 4.78589 0.765984 4.61951 0.971222 4.61951Z" fill="white"/></svg>',
    ["BURGER"] = '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="7" viewBox="0 0 8 7" fill="none"><path d="M7.25 3.5H0.75C0.551088 3.5 0.360322 3.57902 0.21967 3.71967C0.0790176 3.86032 0 4.05109 0 4.25C0 4.44891 0.0790176 4.63968 0.21967 4.78033C0.360322 4.92098 0.551088 5 0.75 5H7.25C7.44891 5 7.63968 4.92098 7.78033 4.78033C7.92098 4.63968 8 4.44891 8 4.25C8 4.05109 7.92098 3.86032 7.78033 3.71967C7.63968 3.57902 7.44891 3.5 7.25 3.5ZM7.5 5.5H0.5C0.433696 5.5 0.370107 5.52634 0.323223 5.57322C0.276339 5.62011 0.25 5.6837 0.25 5.75V6C0.25 6.26522 0.355357 6.51957 0.542893 6.70711C0.73043 6.89464 0.984784 7 1.25 7H6.75C7.01522 7 7.26957 6.89464 7.45711 6.70711C7.64464 6.51957 7.75 6.26522 7.75 6V5.75C7.75 5.6837 7.72366 5.62011 7.67678 5.57322C7.62989 5.52634 7.5663 5.5 7.5 5.5ZM0.91625 3H7.08375C7.62391 3 7.93719 2.31406 7.62781 1.81437C7 0.8 5.61797 0.0015625 4 0C2.38219 0.0015625 1 0.8 0.372187 1.81422C0.0625 2.31391 0.376094 3 0.91625 3ZM6 1.25C6.04945 1.25 6.09778 1.26466 6.13889 1.29213C6.18 1.3196 6.21205 1.35865 6.23097 1.40433C6.24989 1.45001 6.25484 1.50028 6.2452 1.54877C6.23555 1.59727 6.21174 1.64181 6.17678 1.67678C6.14181 1.71174 6.09727 1.73555 6.04877 1.7452C6.00028 1.75484 5.95001 1.74989 5.90433 1.73097C5.85865 1.71205 5.8196 1.68 5.79213 1.63889C5.76466 1.59778 5.75 1.54945 5.75 1.5C5.75 1.4337 5.77634 1.37011 5.82322 1.32322C5.87011 1.27634 5.9337 1.25 6 1.25ZM4 0.75C4.04945 0.75 4.09778 0.764662 4.13889 0.792133C4.18 0.819603 4.21205 0.858648 4.23097 0.904329C4.24989 0.950011 4.25484 1.00028 4.2452 1.04877C4.23555 1.09727 4.21174 1.14181 4.17678 1.17678C4.14181 1.21174 4.09727 1.23555 4.04877 1.2452C4.00028 1.25484 3.95001 1.24989 3.90433 1.23097C3.85865 1.21205 3.8196 1.18 3.79213 1.13889C3.76466 1.09778 3.75 1.04945 3.75 1C3.75 0.933696 3.77634 0.870107 3.82322 0.823223C3.87011 0.776339 3.9337 0.75 4 0.75ZM2 1.25C2.04945 1.25 2.09778 1.26466 2.13889 1.29213C2.18 1.3196 2.21205 1.35865 2.23097 1.40433C2.24989 1.45001 2.25484 1.50028 2.2452 1.54877C2.23555 1.59727 2.21174 1.64181 2.17678 1.67678C2.14181 1.71174 2.09727 1.73555 2.04877 1.7452C2.00028 1.75484 1.95001 1.74989 1.90433 1.73097C1.85865 1.71205 1.8196 1.68 1.79213 1.63889C1.76466 1.59778 1.75 1.54945 1.75 1.5C1.75 1.4337 1.77634 1.37011 1.82322 1.32322C1.87011 1.27634 1.9337 1.25 2 1.25Z" fill="white"/></svg>',
    ["RMIC"] = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M9.9812 7.77558L9.1652 6.95504V4.93318C9.17605 4.18238 8.91489 3.453 8.42995 2.87973C7.945 2.30645 7.26901 1.928 6.5268 1.81424C6.09604 1.75752 5.65815 1.7933 5.24232 1.91922C4.8265 2.04514 4.44231 2.25829 4.11539 2.54445C3.78847 2.83062 3.52634 3.18321 3.34649 3.5787C3.16663 3.9742 3.07319 4.4035 3.0724 4.83798V6.95504L2.2564 7.77558C2.1539 7.87978 2.08439 8.01189 2.05657 8.15538C2.02874 8.29887 2.04383 8.44738 2.09994 8.58235C2.15605 8.71731 2.25071 8.83274 2.37206 8.9142C2.49342 8.99567 2.6361 9.03956 2.78226 9.04038H4.30546V9.19451C4.32664 9.65473 4.52939 10.0878 4.86928 10.3988C5.20918 10.7098 5.65851 10.8734 6.1188 10.8537C6.57909 10.8734 7.02841 10.7098 7.36831 10.3988C7.7082 10.0878 7.91095 9.65473 7.93213 9.19451V9.04038H9.45533C9.60149 9.03956 9.74417 8.99567 9.86553 8.9142C9.98688 8.83274 10.0815 8.71731 10.1377 8.58235C10.1938 8.44738 10.2089 8.29887 10.181 8.15538C10.1532 8.01189 10.0837 7.87978 9.9812 7.77558ZM7.02546 9.19451C7.00032 9.41256 6.89202 9.61251 6.72312 9.75269C6.55422 9.89288 6.33775 9.9625 6.1188 9.94704C5.89984 9.9625 5.68337 9.89288 5.51447 9.75269C5.34557 9.61251 5.23727 9.41256 5.21213 9.19451V9.04038H7.02546V9.19451ZM3.17666 8.13371L3.7116 7.59878C3.79645 7.51443 3.86376 7.41412 3.90967 7.30364C3.95557 7.19316 3.97916 7.07468 3.97906 6.95504V4.83798C3.97931 4.53216 4.04497 4.22993 4.17164 3.95158C4.2983 3.67322 4.48304 3.42519 4.71346 3.22411C4.94077 3.01815 5.21012 2.86405 5.50287 2.77247C5.79562 2.68089 6.10477 2.65401 6.40893 2.69371C6.9332 2.77883 7.40907 3.05049 7.74893 3.45865C8.0888 3.86682 8.26977 4.38402 8.25853 4.91504V6.95504C8.25784 7.07437 8.28071 7.19265 8.32583 7.30312C8.37095 7.41358 8.43743 7.51406 8.52146 7.59878L9.06093 8.13371H3.17666Z" fill="white"/></svg>',
    ["VMIC"] = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M9.9812 7.77558L9.1652 6.95504V4.93318C9.17605 4.18238 8.91489 3.453 8.42995 2.87973C7.945 2.30645 7.26901 1.928 6.5268 1.81424C6.09604 1.75752 5.65815 1.7933 5.24232 1.91922C4.8265 2.04514 4.44231 2.25829 4.11539 2.54445C3.78847 2.83062 3.52634 3.18321 3.34649 3.5787C3.16663 3.9742 3.07319 4.4035 3.0724 4.83798V6.95504L2.2564 7.77558C2.1539 7.87978 2.08439 8.01189 2.05657 8.15538C2.02874 8.29887 2.04383 8.44738 2.09994 8.58235C2.15605 8.71731 2.25071 8.83274 2.37206 8.9142C2.49342 8.99567 2.6361 9.03956 2.78226 9.04038H4.30546V9.19451C4.32664 9.65473 4.52939 10.0878 4.86928 10.3988C5.20918 10.7098 5.65851 10.8734 6.1188 10.8537C6.57909 10.8734 7.02841 10.7098 7.36831 10.3988C7.7082 10.0878 7.91095 9.65473 7.93213 9.19451V9.04038H9.45533C9.60149 9.03956 9.74417 8.99567 9.86553 8.9142C9.98688 8.83274 10.0815 8.71731 10.1377 8.58235C10.1938 8.44738 10.2089 8.29887 10.181 8.15538C10.1532 8.01189 10.0837 7.87978 9.9812 7.77558ZM7.02546 9.19451C7.00032 9.41256 6.89202 9.61251 6.72312 9.75269C6.55422 9.89288 6.33775 9.9625 6.1188 9.94704C5.89984 9.9625 5.68337 9.89288 5.51447 9.75269C5.34557 9.61251 5.23727 9.41256 5.21213 9.19451V9.04038H7.02546V9.19451ZM3.17666 8.13371L3.7116 7.59878C3.79645 7.51443 3.86376 7.41412 3.90967 7.30364C3.95557 7.19316 3.97916 7.07468 3.97906 6.95504V4.83798C3.97931 4.53216 4.04497 4.22993 4.17164 3.95158C4.2983 3.67322 4.48304 3.42519 4.71346 3.22411C4.94077 3.01815 5.21012 2.86405 5.50287 2.77247C5.79562 2.68089 6.10477 2.65401 6.40893 2.69371C6.9332 2.77883 7.40907 3.05049 7.74893 3.45865C8.0888 3.86682 8.26977 4.38402 8.25853 4.91504V6.95504C8.25784 7.07437 8.28071 7.19265 8.32583 7.30312C8.37095 7.41358 8.43743 7.51406 8.52146 7.59878L9.06093 8.13371H3.17666Z" fill="white"/></svg>',
    ["DEFAULT"] = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M9.9812 7.77558L9.1652 6.95504V4.93318C9.17605 4.18238 8.91489 3.453 8.42995 2.87973C7.945 2.30645 7.26901 1.928 6.5268 1.81424C6.09604 1.75752 5.65815 1.7933 5.24232 1.91922C4.8265 2.04514 4.44231 2.25829 4.11539 2.54445C3.78847 2.83062 3.52634 3.18321 3.34649 3.5787C3.16663 3.9742 3.07319 4.4035 3.0724 4.83798V6.95504L2.2564 7.77558C2.1539 7.87978 2.08439 8.01189 2.05657 8.15538C2.02874 8.29887 2.04383 8.44738 2.09994 8.58235C2.15605 8.71731 2.25071 8.83274 2.37206 8.9142C2.49342 8.99567 2.6361 9.03956 2.78226 9.04038H4.30546V9.19451C4.32664 9.65473 4.52939 10.0878 4.86928 10.3988C5.20918 10.7098 5.65851 10.8734 6.1188 10.8537C6.57909 10.8734 7.02841 10.7098 7.36831 10.3988C7.7082 10.0878 7.91095 9.65473 7.93213 9.19451V9.04038H9.45533C9.60149 9.03956 9.74417 8.99567 9.86553 8.9142C9.98688 8.83274 10.0815 8.71731 10.1377 8.58235C10.1938 8.44738 10.2089 8.29887 10.181 8.15538C10.1532 8.01189 10.0837 7.87978 9.9812 7.77558ZM7.02546 9.19451C7.00032 9.41256 6.89202 9.61251 6.72312 9.75269C6.55422 9.89288 6.33775 9.9625 6.1188 9.94704C5.89984 9.9625 5.68337 9.89288 5.51447 9.75269C5.34557 9.61251 5.23727 9.41256 5.21213 9.19451V9.04038H7.02546V9.19451ZM3.17666 8.13371L3.7116 7.59878C3.79645 7.51443 3.86376 7.41412 3.90967 7.30364C3.95557 7.19316 3.97916 7.07468 3.97906 6.95504V4.83798C3.97931 4.53216 4.04497 4.22993 4.17164 3.95158C4.2983 3.67322 4.48304 3.42519 4.71346 3.22411C4.94077 3.01815 5.21012 2.86405 5.50287 2.77247C5.79562 2.68089 6.10477 2.65401 6.40893 2.69371C6.9332 2.77883 7.40907 3.05049 7.74893 3.45865C8.0888 3.86682 8.26977 4.38402 8.25853 4.91504V6.95504C8.25784 7.07437 8.28071 7.19265 8.32583 7.30312C8.37095 7.41358 8.43743 7.51406 8.52146 7.59878L9.06093 8.13371H3.17666Z" fill="white"/></svg>',
    ["ILLEGAL"] = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M6 0L7.545 4.635H12L8.7275 7.365L10.2725 12L6 9.27L1.7275 12L3.2725 7.365L0 4.635H4.455L6 0Z" fill="white"/></svg>',
    ["LEGAL"] = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M6 1L7.5 4.5H11L8.25 7.25L9.75 11L6 8.75L2.25 11L3.75 7.25L1 4.5H4.5L6 1Z" fill="white"/></svg>',
    ["SYSTEM"] = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M6 0.5C7.0625 0.5 8.125 0.9375 8.9375 1.8125C9.8125 2.625 10.25 3.6875 10.25 4.75C10.25 5.8125 9.8125 6.875 8.9375 7.75C8.125 8.5625 7.0625 9 6 9C4.9375 9 3.875 8.5625 3.0625 7.75C2.1875 6.875 1.75 5.8125 1.75 4.75C1.75 3.6875 2.1875 2.625 3.0625 1.8125C3.875 0.9375 4.9375 0.5 6 0.5ZM6 11.5C8.5 11.5 11 10.5 11 9.5V11C11 11.5 8.5 12.5 6 12.5C3.5 12.5 1 11.5 1 11V9.5C1 10.5 3.5 11.5 6 11.5Z" fill="white"/></svg>'
}
local queuedNotifications = {}
local pendingActions = {}

---@param notification table
---@return nil
function VFW.ShowNotification(notification)
    -- Check for blocked notification types
    if type(notification) == "table" and notification.type then
        -- Block ANIMATOR_NEW_REPORT if user has disabled them
        if notification.type == "ANIMATOR_NEW_REPORT" then
            if GetResourceKvpString("animator_disable_notifications") == "true" then
                return -- Don't show the notification
            end
        end
    end

    if type(notification) == "table" and notification.type == "STAFF" and not notification.title then
        local perms = VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions
        if perms and perms["menu_anim"] and not perms["staff_menu"] then
            notification.title = VFW.AnimatorTitle()
        end
    end

    -- Enhanced notification structure support
    if type(notification) == "table" then
        notification.title = VFW.NormalizeBrandText(notification.title)
        notification.subtitle = VFW.NormalizeBrandText(notification.subtitle)
        notification.label = VFW.NormalizeBrandText(notification.label)
        notification.message = VFW.NormalizeBrandText(notification.message)
        notification.content = VFW.NormalizeBrandText(notification.content)
        -- Support both old and new formats

        -- If using old format with just 'content', convert it
        if notification.content and not notification.message then
            notification.message = notification.content
        end

        -- Auto-format: capitalize first letter and add period if missing punctuation (skip JOB notifications)
        local validPunctuation = {
            ["."] = true, ["!"] = true, ["?"] = true, [":"] = true, [";"] = true,
            [","] = true, [")"] = true, ["]"] = true, ["}"] = true, ["…"] = true,
            ['"'] = true, ["'"] = true, ["»"] = true, ["$"] = true,
        }

        local function autoFormatMsg(msg)
            if not msg or type(msg) ~= "string" or #msg == 0 then return msg end
            local firstChar = msg:sub(1, 1)
            local rest = msg:sub(2)
            msg = firstChar:upper() .. rest
            local stripped = msg:gsub("~[a-zA-Z]~", "")
            local lastChar = stripped:sub(-1)
            if not validPunctuation[lastChar] then
                msg = msg .. "."
            end
            return msg
        end

        if notification.message then
            notification.message = autoFormatMsg(notification.message)
            notification.content = notification.message
        end

        if notification.content and not notification.message then
            notification.content = autoFormatMsg(notification.content)
        end

        if notification.mainMessage then
            notification.mainMessage = autoFormatMsg(notification.mainMessage)
        end

        -- Parse message content to support HTML-like formatting
        if notification.message then
            -- Replace FiveM color codes with HTML spans
            notification.parsedMessage = notification.message
                                                     :gsub("~r~", "<span style='color: #ff4444'>")
                                                     :gsub("~g~", "<span style='color: #44ff44'>")
                                                     :gsub("~b~", "<span style='color: #4444ff'>")
                                                     :gsub("~y~", "<span style='color: #ffff44'>")
                                                     :gsub("~p~", "<span style='color: #ff44ff'>")
                                                     :gsub("~c~", "<span style='color: #44ffff'>")
                                                     :gsub("~m~", "<span style='color: #555555'>")
                                                     :gsub("~u~", "<span style='color: #000000'>")
                                                     :gsub("~o~", "<span style='color: #ff8800'>")
                                                     :gsub("~s~", "</span>")
                                                     :gsub("~w~", "</span>")
                                                     :gsub("~h~", "<strong>")
                                                     :gsub("~bold~", "<strong>")
                                                     :gsub("~/h~", "</strong>")
                                                     :gsub("~/bold~", "</strong>")
                                                     :gsub("~italic~", "<em>")
                                                     :gsub("~/italic~", "</em>")
                                                     :gsub("~n~", "<br/>")
        end

        -- Set default duration if not specified
        notification.duration = notification.duration or 5

        -- Auto-generate a unique ID if not provided
        notification.id = notification.id or tostring(GetGameTimer() .. "_" .. math.random(1000, 9999))

        -- Action support: store callback and assign actionId
        if notification.action and type(notification.action) == "function" then
            local actionId = "action_" .. GetGameTimer() .. "_" .. math.random(1000, 9999)
            local callback = notification.action
            notification.action = nil -- Don't send function to NUI
            notification.actionId = actionId

            pendingActions[actionId] = {
                callback = callback,
                notificationId = notification.id,
            }

            -- Auto-cleanup when notification expires
            local dur = (notification.duration or 5) * 1000
            SetTimeout(dur, function()
                pendingActions[actionId] = nil
            end)
        end
    end

    table.insert(queuedNotifications, notification)
end

CreateThread(function()
    while true do
        Wait(100)
        if #queuedNotifications > 0 then
            local notification = queuedNotifications[1]
            table.remove(queuedNotifications, 1)
            SendNUIMessage({
                action = "nui:hud:create-notifications",
                data = notification
            })
        end
    end
end)

-- Action notification: handle response from NUI (button click)
RegisterNUICallback("nui:notification:actionResponse", function(data, cb)
    local actionId = data.actionId
    local accepted = data.accepted
    if actionId and pendingActions[actionId] then
        local action = pendingActions[actionId]
        pendingActions[actionId] = nil
        SendNUIMessage({ action = "nui:hud:remove-notifications", data = action.notificationId })
        action.callback(accepted == true)
    end
    cb("ok")
end)

-- Action notification: global keybinds Y/N for the most recent pending action
local function handleActionKeybind(accepted)
    -- Find the most recent pending action
    local latestId = nil
    local latestTime = 0
    for id, _ in pairs(pendingActions) do
        local timestamp = tonumber(id:match("action_(%d+)_")) or 0
        if timestamp > latestTime then
            latestTime = timestamp
            latestId = id
        end
    end
    if latestId and pendingActions[latestId] then
        local action = pendingActions[latestId]
        pendingActions[latestId] = nil
        SendNUIMessage({ action = "nui:hud:remove-notifications", data = action.notificationId })
        action.callback(accepted)
    end
end

RegisterCommand("+notif_accept", function() handleActionKeybind(true) end, false)
RegisterCommand("+notif_decline", function() handleActionKeybind(false) end, false)
RegisterKeyMapping("+notif_accept", "Accepter notification", "keyboard", "y")
RegisterKeyMapping("+notif_decline", "Refuser notification", "keyboard", "n")

---@param visibility boolean
---@return nil
function VFW.ToggleNotificationsVisibility(visibility)
    SendNUIMessage({
        action = "nui:hud:update-hud-state",
        data = visibility
    })
end

---@param alert table
---@return nil
function VFW.CreateAlert(content, image)
    SendNUIMessage({
        action = "nui:hud:create-alert",
        data = {
            content = content,
            image = image
        }
    })
end

---@param content any
---@param image any
RegisterNetEvent("core:vnotif:createAlert", function(content, image)
    VFW.CreateAlert(content, image)
end)

---@param data table
---@return nil
function VFW.PreviewNotificaions(data)
    SendNUIMessage({
        action = "nui:hud:preview-notifications",
        data = data
    })
end

--- .ClearPreview
function VFW.ClearPreview()
    SendNUIMessage({
        action = "nui:hud:clear-preview"
    })
end

---Delete VFW.Notification
--- Supprime toutes les notifications visibles dans le HUD.
function VFW.RemoveNotification()
    SendNUIMessage({
        action = "nui:hud:remove-notifications"
    })
end

--- .TextUI
---@param ... any Varargs
function VFW.TextUI(...)
    --todo textui
end

---@return nil
function VFW.HideUI()
    --todo textui
end

---@param msg string The message to show
---@param thisFrame? boolean Whether to show the message this frame
---@param beep? boolean Whether to beep
---@param duration? number The duration of the message
---@return nil
function VFW.ShowHelpNotification(msg, thisFrame, beep, duration)
    SendNUIMessage({
        action = "nui:helpNotification",
        data = {
            text = msg,
            duration = duration and (duration > 0) and duration or nil
        }
    })
end

---@param msg string The message to show
---@param coords table The coords to show the message at
---@return nil
function VFW.ShowFloatingHelpNotification(msg, coords)
    AddTextEntry("vfwFloatingHelpNotification", msg)
    SetFloatingHelpTextWorldPosition(1, coords.x, coords.y, coords.z)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp("vfwFloatingHelpNotification")
    EndTextCommandDisplayHelp(2, false, false, -1)
end

---@param msg string The message to show
---@param time number The duration of the message
---@return nil
function VFW.DrawMissionText(msg, time)
    ClearPrints()
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandPrint(time, true)
end

---@param str string The string to hash
---@return string The hashed string
function VFW.HashString(str)
    return ('~INPUT_%s~'):format(('%x'):format(joaat(str) & 0x7fffffff + 2 ^ 31):upper())
end

---@param command_name string The command name
---@param label string The label to show
---@param input_group string The input group
---@param key string The key to bind
---@param on_press function The function to call on press
---@param on_release? function The function to call on release
function VFW.RegisterInput(command_name, label, input_group, key, on_press, on_release)
    local command = on_release and '+' .. command_name or command_name
    RegisterCommand(command, on_press, false)
    Core.Input[command_name] = VFW.HashString(command)
    if on_release then
        RegisterCommand('-' .. command_name, on_release, false)
    end

    RegisterKeyMapping(command, label or '', input_group or 'keyboard', key or '')
end

---@param ped integer The ped to get the mugshot of
---@param transparent? boolean Whether the mugshot should be transparent
---@return integer mugshot, string txdString
function VFW.Game.GetPedMugshot(ped, transparent)
    if not DoesEntityExist(ped) then
        return
    end

    local mugshot = transparent and RegisterPedheadshotTransparent(ped) or RegisterPedheadshot(ped)

    while not IsPedheadshotReady(mugshot) do
        Wait(0)
    end

    return mugshot, GetPedheadshotTxdString(mugshot)
end

---@param entity integer The entity to get the coords of
---@param coords table | vector3 | vector4 The coords to teleport the entity to
---@param cb? function The callback function
function VFW.Game.Teleport(entity, coords, cb)

    if DoesEntityExist(entity) then
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        while not HasCollisionLoadedAroundEntity(entity) do
            Wait(0)
        end

        SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(entity, coords.w or coords.heading or 0.0)
    end

    if cb then
        cb()
    end
end

---@param object integer | string The object to spawn
---@param coords table | vector3 The coords to spawn the object at
---@param cb? function The callback function
---@param networked? boolean Whether the object should be networked
---@return integer | nil
function VFW.Game.SpawnObject(object, coords, cb, networked)
    local isNetworked = networked == nil or networked
    local obj

    if isNetworked then
        -- Lockdown "strict" : la création networked doit se faire server-side.
        obj = VFW.OneSync.CreateObject(object, vector3(coords.x, coords.y, coords.z))
    else
        local model = type(object) == "number" and object or joaat(object)
        VFW.Streaming.RequestModel(model)
        obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, true)
    end

    return cb and cb(obj) or obj
end

---@param object integer | string The object to spawn
---@param coords table | vector3 The coords to spawn the object at
---@param cb? function The callback function
---@return nil
function VFW.Game.SpawnLocalObject(object, coords, cb)
    VFW.Game.SpawnObject(object, coords, cb, false)
end

---@param vehicle integer The vehicle to delete
---@return nil
function VFW.Game.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

---@param object integer The object to delete
---@return nil
function VFW.Game.DeleteObject(object)
    SetEntityAsMissionEntity(object, false, true)
    DeleteObject(object)
end

---@param vehicleModel integer | string The vehicle to spawn
---@param coords table | vector3 The coords to spawn the vehicle at
---@param heading number The heading of the vehicle
---@param cb? fun(vehicle: number) The callback function
---@param networked? boolean Whether the vehicle should be networked
---@return number? vehicle
function VFW.Game.SpawnVehicle(vehicleModel, coords, heading, cb, networked)
    if cb and not VFW.IsFunctionReference(cb) then
        error("Invalid callback function")
    end

    local model = type(vehicleModel) == "number" and vehicleModel or joaat(vehicleModel)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    local isNetworked = networked == nil or networked

    local playerCoords = GetEntityCoords(VFW.PlayerData.ped)
    if not vector or not playerCoords then
        return
    end

    local dist = #(playerCoords - vector)
    if dist > 424 then
        -- Onesync infinity Range (https://docs.fivem.net/docs/scripting-reference/onesync/)
        local executingResource = GetInvokingResource() or "Unknown"
        return error(("Resource ^3%s^1 Tried to spawn vehicle on the client but the position is too far away (Out of onesync range)."):format(executingResource))
    end

    local promise = not cb and promise.new()
    CreateThread(function()
        local modelHash = VFW.Streaming.RequestModel(model)
        if not modelHash then
            if promise then
                return promise:reject(("Tried to spawn invalid vehicle - ^3%s^7!"):format(model))
            end

            error(("Tried to spawn invalid vehicle - ^3%s^7!"):format(model))
        end

        local vehicle
        if isNetworked then
            -- Lockdown "strict" : la création networked doit se faire server-side.
            vehicle = VFW.OneSync.CreateVehicleRaw(model, vector, heading)
        else
            vehicle = CreateVehicle(model, vector.x, vector.y, vector.z, heading, false, true)
        end

        if isNetworked and NetworkGetEntityIsNetworked(vehicle) then
            local id = NetworkGetNetworkIdFromEntity(vehicle)
            SetNetworkIdCanMigrate(id, true)
            SetEntityAsMissionEntity(vehicle, true, true)
        end

        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetModelAsNoLongerNeeded(model)
        SetVehRadioStation(vehicle, "OFF")

        RequestCollisionAtCoord(vector.x, vector.y, vector.z)
        while not HasCollisionLoadedAroundEntity(vehicle) do
            Wait(0)
        end

        if promise then
            promise:resolve(vehicle)
        elseif cb then
            cb(vehicle)
        end
    end)

    if promise then
        return Citizen.Await(promise)
    end
end

---@param vehicle integer The vehicle to spawn
---@param coords table | vector3 The coords to spawn the vehicle at
---@param heading number The heading of the vehicle
---@param cb? function The callback function
---@return nil
function VFW.Game.SpawnLocalVehicle(vehicle, coords, heading, cb)
    VFW.Game.SpawnVehicle(vehicle, coords, heading, cb, false)
end

---@param vehicle integer The vehicle to check
---@return boolean
function VFW.Game.IsVehicleEmpty(vehicle)
    return GetVehicleNumberOfPassengers(vehicle) == 0 and IsVehicleSeatFree(vehicle, -1)
end

---@return table
function VFW.Game.GetObjects()
    -- Leave the function for compatibility
    return GetGamePool("CObject")
end

---@param onlyOtherPeds? boolean Whether to exlude the player ped
---@return table
function VFW.Game.GetPeds(onlyOtherPeds)
    local pool = GetGamePool("CPed")

    if onlyOtherPeds then
        local myPed = VFW.PlayerData.ped

        for i = 1, #pool do
            if pool[i] == myPed then
                table.remove(pool, i)
                break
            end
        end
    end

    return pool
end

---@return table
function VFW.Game.GetVehicles()
    -- Leave the function for compatibility
    return GetGamePool("CVehicle")
end

---@param onlyOtherPlayers? boolean Whether to exclude the player
---@param returnKeyValue? boolean Whether to return the key value pair
---@param returnPeds? boolean Whether to return the peds
---@return table
function VFW.Game.GetPlayers(onlyOtherPlayers, returnKeyValue, returnPeds)
    local players = {}
    local active = GetActivePlayers()

    for i = 1, #active do
        local currentPlayer = active[i]
        local ped = GetPlayerPed(currentPlayer)

        if DoesEntityExist(ped) and ((onlyOtherPlayers and currentPlayer ~= VFW.playerId) or not onlyOtherPlayers) then
            if returnKeyValue then
                players[currentPlayer] = ped
            else
                players[#players + 1] = returnPeds and ped or currentPlayer
            end
        end
    end

    return players
end

---@param coords? table | vector3 The coords to get the closest object to
---@param modelFilter? table The model filter
---@return integer, integer
function VFW.Game.GetClosestObject(coords, modelFilter)
    return VFW.Game.GetClosestEntity(VFW.Game.GetObjects(), false, coords, modelFilter)
end

---@param coords? table | vector3 The coords to get the closest ped to
---@param modelFilter? table The model filter
---@return integer, integer
function VFW.Game.GetClosestPed(coords, modelFilter)
    return VFW.Game.GetClosestEntity(VFW.Game.GetPeds(true), false, coords, modelFilter)
end

---@param coords? table | vector3 The coords to get the closest player to
---@return integer, integer
function VFW.Game.GetClosestPlayer(coords, maxDistance, includePlayer)
    local players = GetActivePlayers()
    local closestId, closestPed, closestCoords
    maxDistance = maxDistance or 2.0

    for i = 1, #players do
        local playerId = players[i]

        if playerId ~= PlayerId() or includePlayer then
            local playerPed = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(coords - playerCoords)

            if distance < maxDistance then
                maxDistance = distance
                closestId = playerId
                closestPed = playerPed
                closestCoords = playerCoords
            end
        end
    end

    return closestId, closestPed, closestCoords
end

---@param coords? table | vector3 The coords to get the closest vehicle to
---@param modelFilter? table The model filter
---@return integer, integer
function VFW.Game.GetClosestVehicle(coords, modelFilter)
    return VFW.Game.GetClosestEntity(VFW.Game.GetVehicles(), false, coords, modelFilter)
end

---@param entities table The entities to search through
---@param isPlayerEntities boolean Whether the entities are players
---@param coords table | vector3 The coords to search from
---@param maxDistance number The max distance to search within
---@return table
local function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance, excludeSelf)
    local nearbyEntities = {}
    local count = 0

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = VFW.PlayerData.ped
        coords = GetEntityCoords(playerPed)
    end

    for k, entity in pairs(entities) do
        if excludeSelf and entity == PlayerPedId() then
            goto continue
        end

        local distance = #(coords - GetEntityCoords(entity))

        if distance <= maxDistance then
            nearbyEntities[#nearbyEntities + 1] = isPlayerEntities and k or entity
            count = count + 1
        end

        :: continue ::
    end

    return nearbyEntities, count
end

---@param coords table | vector3 The coords to search from
---@param maxDistance number The max distance to search within
---@return table
function VFW.Game.GetPlayersInArea(coords, maxDistance, excludeSelf)
    return EnumerateEntitiesWithinDistance(VFW.Game.GetPlayers(false, true), true, coords, maxDistance, excludeSelf)
end

---@param coords table | vector3 The coords to search from
---@param maxDistance number The max distance to search within
---@return table
function VFW.Game.GetVehiclesInArea(coords, maxDistance)
    return EnumerateEntitiesWithinDistance(VFW.Game.GetVehicles(), false, coords, maxDistance)
end

---@param coords table | vector3 The coords to search from
---@param maxDistance number The max distance to search within
---@return boolean
function VFW.Game.IsSpawnPointClear(coords, maxDistance)
    return #VFW.Game.GetVehiclesInArea(coords, maxDistance) == 0
end

---@param shape integer The shape to get the test result from
---@return boolean, table, table, integer, integer
function VFW.Game.GetShapeTestResultSync(shape)
    local handle, hit, coords, normal, material, entity
    repeat
        handle, hit, coords, normal, material, entity = GetShapeTestResultIncludingMaterial(shape)
        Wait(0)
    until handle ~= 1
    return hit, coords, normal, material, entity
end

---@param depth number The depth to raycast
---@vararg any The arguments to pass to the shape test
---@return table, boolean, table, table, integer, integer
function VFW.Game.RaycastScreen(depth, ...)
    local world, normal = GetWorldCoordFromScreenCoord(.5, .5)
    local origin = world + normal
    local target = world + normal * depth
    return target, VFW.Game.GetShapeTestResultSync(StartShapeTestLosProbe(origin.x, origin.y, origin.z, target.x, target.y, target.z, ...))
end

---@param entities table The entities to search through
---@param isPlayerEntities boolean Whether the entities are players
---@param coords? table | vector3 The coords to search from
---@param modelFilter? table The model filter
---@return integer, integer
function VFW.Game.GetClosestEntity(entities, isPlayerEntities, coords, modelFilter)
    local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = VFW.PlayerData.ped
        coords = GetEntityCoords(playerPed)
    end

    if modelFilter then
        ---@class filteredEntities
        filteredEntities = {}

        for currentEntityIndex = 1, #entities do
            if modelFilter[GetEntityModel(entities[currentEntityIndex])] then
                filteredEntities[#filteredEntities + 1] = entities[currentEntityIndex]
            end
        end
    end

    for k, entity in pairs(filteredEntities or entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if closestEntityDistance == -1 or distance < closestEntityDistance then
            closestEntity, closestEntityDistance = isPlayerEntities and k or entity, distance
        end
    end

    return closestEntity, closestEntityDistance
end

---@return integer | nil, vector3 | nil
function VFW.Game.GetVehicleInDirection()
    local _, hit, coords, _, _, entity = VFW.Game.RaycastScreen(5, 10, VFW.PlayerData.ped)
    if hit and IsEntityAVehicle(entity) then
        return entity, coords
    end
end

---@param s string The string to trim
---@return string The trimmed string
local function all_trim(s)
    return s:match("^%s*(.-)%s*$")
end

---@param vehicle integer The vehicle to get the plate of
---@return string
function VFW.Game.GetPlate(vehicle)
    return all_trim(GetVehicleNumberPlateText(vehicle))
end

---@param vehicle integer The vehicle to get the properties of
---@return table | nil
function VFW.Game.GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local hasCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(vehicle)
    local dashboardColor = GetVehicleDashboardColor(vehicle)
    local interiorColor = GetVehicleInteriorColour(vehicle)
    local customPrimaryColor = nil
    if hasCustomPrimaryColor then
        customPrimaryColor = { GetVehicleCustomPrimaryColour(vehicle) }
    end

    local hasCustomXenonColor, customXenonColorR, customXenonColorG, customXenonColorB = GetVehicleXenonLightsCustomColor(vehicle)
    local customXenonColor = nil
    if hasCustomXenonColor then
        customXenonColor = { customXenonColorR, customXenonColorG, customXenonColorB }
    end

    local hasCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(vehicle)
    local customSecondaryColor = nil
    if hasCustomSecondaryColor then
        customSecondaryColor = { GetVehicleCustomSecondaryColour(vehicle) }
    end

    local extras = {}

    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then
            extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId)
        end
    end

    local doorsBroken, windowsBroken, tyreBurst = {}, {}, {}
    local numWheels = tostring(GetVehicleNumberOfWheels(vehicle))

    local TyresIndex = { -- Wheel index list according to the number of vehicle wheels.
        ["2"] = { 0, 4 }, -- Bike and cycle.
        ["3"] = { 0, 1, 4, 5 }, -- Vehicle with 3 wheels (get for wheels because some 3 wheels vehicles have 2 wheels on front and one rear or the reverse).
        ["4"] = { 0, 1, 4, 5 }, -- Vehicle with 4 wheels.
        ["6"] = { 0, 1, 2, 3, 4, 5 }, -- Vehicle with 6 wheels.
    }

    if TyresIndex[numWheels] then
        for _, idx in pairs(TyresIndex[numWheels]) do
            tyreBurst[tostring(idx)] = IsVehicleTyreBurst(vehicle, idx, false)
        end
    end

    for windowId = 0, 7 do
        -- 13
        RollUpWindow(vehicle, windowId) --fix when you put the car away with the window down
        windowsBroken[tostring(windowId)] = not IsVehicleWindowIntact(vehicle, windowId)
    end

    local numDoors = GetNumberOfVehicleDoors(vehicle)
    if numDoors and numDoors > 0 then
        for doorsId = 0, numDoors do
            doorsBroken[tostring(doorsId)] = IsVehicleDoorDamaged(vehicle, doorsId)
        end
    end


    return {
        model = GetEntityModel(vehicle),
        doorsBroken = doorsBroken,
        windowsBroken = windowsBroken,
        tyreBurst = tyreBurst,
        tyresCanBurst = GetVehicleTyresCanBurst(vehicle),
        plate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle)),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),

        bodyHealth = VFW.Math.Round(GetVehicleBodyHealth(vehicle), 1),
        engineHealth = VFW.Math.Round(GetVehicleEngineHealth(vehicle), 1),
        tankHealth = VFW.Math.Round(GetVehiclePetrolTankHealth(vehicle), 1),

        fuelLevel = VFW.Math.Round(GetVehicleFuelLevel(vehicle), 1),
        dirtLevel = VFW.Math.Round(GetVehicleDirtLevel(vehicle), 1),
        color1 = colorPrimary,
        color2 = colorSecondary,
        customPrimaryColor = customPrimaryColor,
        customSecondaryColor = customSecondaryColor,

        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,

        dashboardColor = dashboardColor,
        interiorColor = interiorColor,

        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        xenonColor = GetVehicleXenonLightsColor(vehicle),
        customXenonColor = customXenonColor,

        neonEnabled = { IsVehicleNeonLightEnabled(vehicle, 0), IsVehicleNeonLightEnabled(vehicle, 1), IsVehicleNeonLightEnabled(vehicle, 2), IsVehicleNeonLightEnabled(vehicle, 3) },

        neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
        extras = extras,
        tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),

        modSpoilers = GetVehicleMod(vehicle, 0),
        modFrontBumper = GetVehicleMod(vehicle, 1),
        modRearBumper = GetVehicleMod(vehicle, 2),
        modSideSkirt = GetVehicleMod(vehicle, 3),
        modExhaust = GetVehicleMod(vehicle, 4),
        modFrame = GetVehicleMod(vehicle, 5),
        modGrille = GetVehicleMod(vehicle, 6),
        modHood = GetVehicleMod(vehicle, 7),
        modFender = GetVehicleMod(vehicle, 8),
        modRightFender = GetVehicleMod(vehicle, 9),
        modRoof = GetVehicleMod(vehicle, 10),
        modRoofLivery = GetVehicleRoofLivery(vehicle),

        modEngine = GetVehicleMod(vehicle, 11),
        modBrakes = GetVehicleMod(vehicle, 12),
        modTransmission = GetVehicleMod(vehicle, 13),
        modHorns = GetVehicleMod(vehicle, 14),
        modSuspension = GetVehicleMod(vehicle, 15),
        modArmor = GetVehicleMod(vehicle, 16),

        modTurbo = IsToggleModOn(vehicle, 18),
        modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),

        modFrontWheels = GetVehicleMod(vehicle, 23),
        modCustomFrontWheels = GetVehicleModVariation(vehicle, 23),
        modBackWheels = GetVehicleMod(vehicle, 24),
        modCustomBackWheels = GetVehicleModVariation(vehicle, 24),

        modPlateHolder = GetVehicleMod(vehicle, 25),
        modVanityPlate = GetVehicleMod(vehicle, 26),
        modTrimA = GetVehicleMod(vehicle, 27),
        modOrnaments = GetVehicleMod(vehicle, 28),
        modDashboard = GetVehicleMod(vehicle, 29),
        modDial = GetVehicleMod(vehicle, 30),
        modDoorSpeaker = GetVehicleMod(vehicle, 31),
        modSeats = GetVehicleMod(vehicle, 32),
        modSteeringWheel = GetVehicleMod(vehicle, 33),
        modShifterLeavers = GetVehicleMod(vehicle, 34),
        modAPlate = GetVehicleMod(vehicle, 35),
        modSpeakers = GetVehicleMod(vehicle, 36),
        modTrunk = GetVehicleMod(vehicle, 37),
        modHydrolic = GetVehicleMod(vehicle, 38),
        modEngineBlock = GetVehicleMod(vehicle, 39),
        modAirFilter = GetVehicleMod(vehicle, 40),
        modStruts = GetVehicleMod(vehicle, 41),
        modArchCover = GetVehicleMod(vehicle, 42),
        modAerials = GetVehicleMod(vehicle, 43),
        modTrimB = GetVehicleMod(vehicle, 44),
        modTank = GetVehicleMod(vehicle, 45),
        modWindows = GetVehicleMod(vehicle, 46),
        modLivery = GetVehicleMod(vehicle, 48),
        livery = GetVehicleLivery(vehicle),
        modLightbar = GetVehicleMod(vehicle, 49),
    }
end

---@param vehicle integer The vehicle to set the properties of
---@param props table The properties to set
---@return nil
function VFW.Game.SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) then
        return
    end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    SetVehicleModKit(vehicle, 0)

    if props.tyresCanBurst ~= nil then
        SetVehicleTyresCanBurst(vehicle, props.tyresCanBurst)
    end

    if props.plate ~= nil then
        SetVehicleNumberPlateText(vehicle, props.plate)
    end

    if props.plateIndex ~= nil then
        SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
    end

    if props.bodyHealth ~= nil then
        SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
    end

    if props.engineHealth ~= nil then
        SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
    end

    if props.tankHealth ~= nil then
        SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
    end

    if props.fuelLevel ~= nil then
        SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
        Entity(vehicle).state:set("fuel", props.fuelLevel, true)
    end

    if props.dirtLevel ~= nil then
        SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
    end

    if props.customPrimaryColor ~= nil then
        SetVehicleCustomPrimaryColour(vehicle, props.customPrimaryColor[1], props.customPrimaryColor[2], props.customPrimaryColor[3])
    end

    if props.customSecondaryColor ~= nil then
        SetVehicleCustomSecondaryColour(vehicle, props.customSecondaryColor[1], props.customSecondaryColor[2], props.customSecondaryColor[3])
    end

    if props.color1 ~= nil then
        SetVehicleColours(vehicle, props.color1, colorSecondary)
    end

    if props.color2 ~= nil then
        SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2)
    end

    if props.pearlescentColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor)
    end

    if props.interiorColor ~= nil then
        SetVehicleInteriorColor(vehicle, props.interiorColor)
    end

    if props.dashboardColor ~= nil then
        SetVehicleDashboardColor(vehicle, props.dashboardColor)
    end

    if props.wheelColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor)
    end

    if props.wheels ~= nil then
        SetVehicleWheelType(vehicle, props.wheels)
    end

    if props.windowTint ~= nil then
        SetVehicleWindowTint(vehicle, props.windowTint)
    end

    if props.neonEnabled ~= nil then
        SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
        SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
        SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
        SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
    end

    if props.extras ~= nil then
        for extraId, enabled in pairs(props.extras) do
            extraId = tonumber(extraId)
            if extraId then
                SetVehicleExtra(vehicle, extraId, not enabled)
            end
        end
    end

    if props.neonColor ~= nil then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end

    if props.xenonColor ~= nil then
        SetVehicleXenonLightsColor(vehicle, props.xenonColor)
    end

    if props.customXenonColor ~= nil then
        SetVehicleXenonLightsCustomColor(vehicle, props.customXenonColor[1], props.customXenonColor[2], props.customXenonColor[3])
    end

    if props.modSmokeEnabled ~= nil then
        ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled)
    end

    if props.tyreSmokeColor ~= nil then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end

    if props.modSpoilers ~= nil then
        SetVehicleMod(vehicle, 0, props.modSpoilers, false)
    end

    if props.modFrontBumper ~= nil then
        SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
    end

    if props.modRearBumper ~= nil then
        SetVehicleMod(vehicle, 2, props.modRearBumper, false)
    end

    if props.modSideSkirt ~= nil then
        SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
    end

    if props.modExhaust ~= nil then
        SetVehicleMod(vehicle, 4, props.modExhaust, false)
    end

    if props.modFrame ~= nil then
        SetVehicleMod(vehicle, 5, props.modFrame, false)
    end

    if props.modGrille ~= nil then
        SetVehicleMod(vehicle, 6, props.modGrille, false)
    end

    if props.modHood ~= nil then
        SetVehicleMod(vehicle, 7, props.modHood, false)
    end

    if props.modFender ~= nil then
        SetVehicleMod(vehicle, 8, props.modFender, false)
    end

    if props.modRightFender ~= nil then
        SetVehicleMod(vehicle, 9, props.modRightFender, false)
    end

    if props.modRoof ~= nil then
        SetVehicleMod(vehicle, 10, props.modRoof, false)
    end

    if props.modRoofLivery ~= nil then
        SetVehicleRoofLivery(vehicle, props.modRoofLivery)
    end

    if props.modEngine ~= nil then
        SetVehicleMod(vehicle, 11, props.modEngine, false)
    end

    if props.modBrakes ~= nil then
        SetVehicleMod(vehicle, 12, props.modBrakes, false)
    end

    if props.modTransmission ~= nil then
        SetVehicleMod(vehicle, 13, props.modTransmission, false)
    end

    if props.modHorns ~= nil then
        SetVehicleMod(vehicle, 14, props.modHorns, false)
    end

    if props.modSuspension ~= nil then
        SetVehicleMod(vehicle, 15, props.modSuspension, false)
    end

    if props.modArmor ~= nil then
        SetVehicleMod(vehicle, 16, props.modArmor, false)
    end

    if props.modTurbo ~= nil then
        ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end

    if props.modXenon ~= nil then
        ToggleVehicleMod(vehicle, 22, props.modXenon)
    end

    if props.modFrontWheels ~= nil then
        SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomFrontWheels)
    end

    if props.modBackWheels ~= nil then
        SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomBackWheels)
    end

    if props.modPlateHolder ~= nil then
        SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
    end

    if props.modVanityPlate ~= nil then
        SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
    end

    if props.modTrimA ~= nil then
        SetVehicleMod(vehicle, 27, props.modTrimA, false)
    end

    if props.modOrnaments ~= nil then
        SetVehicleMod(vehicle, 28, props.modOrnaments, false)
    end

    if props.modDashboard ~= nil then
        SetVehicleMod(vehicle, 29, props.modDashboard, false)
    end

    if props.modDial ~= nil then
        SetVehicleMod(vehicle, 30, props.modDial, false)
    end

    if props.modDoorSpeaker ~= nil then
        SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
    end

    if props.modSeats ~= nil then
        SetVehicleMod(vehicle, 32, props.modSeats, false)
    end

    if props.modSteeringWheel ~= nil then
        SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
    end

    if props.modShifterLeavers ~= nil then
        SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
    end

    if props.modAPlate ~= nil then
        SetVehicleMod(vehicle, 35, props.modAPlate, false)
    end

    if props.modSpeakers ~= nil then
        SetVehicleMod(vehicle, 36, props.modSpeakers, false)
    end

    if props.modTrunk ~= nil then
        SetVehicleMod(vehicle, 37, props.modTrunk, false)
    end

    if props.modHydrolic ~= nil then
        SetVehicleMod(vehicle, 38, props.modHydrolic, false)
    end

    if props.modEngineBlock ~= nil then
        SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
    end

    if props.modAirFilter ~= nil then
        SetVehicleMod(vehicle, 40, props.modAirFilter, false)
    end

    if props.modStruts ~= nil then
        SetVehicleMod(vehicle, 41, props.modStruts, false)
    end

    if props.modArchCover ~= nil then
        SetVehicleMod(vehicle, 42, props.modArchCover, false)
    end

    if props.modAerials ~= nil then
        SetVehicleMod(vehicle, 43, props.modAerials, false)
    end

    if props.modTrimB ~= nil then
        SetVehicleMod(vehicle, 44, props.modTrimB, false)
    end

    if props.modTank ~= nil then
        SetVehicleMod(vehicle, 45, props.modTank, false)
    end

    if props.modWindows ~= nil then
        SetVehicleMod(vehicle, 46, props.modWindows, false)
    end

    if props.modLivery ~= nil and props.modLivery ~= -1 then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
    end

    if props.livery ~= nil and props.livery ~= -1 then
        SetVehicleLivery(vehicle, props.livery)
    end

    if props.modLightbar ~= nil then
        SetVehicleMod(vehicle, 49, props.modLightbar, false)
    end

    if props.windowsBroken ~= nil then
        for k, v in pairs(props.windowsBroken) do
            if v then
                k = tonumber(k)
                if k then
                    RemoveVehicleWindow(vehicle, k)
                end
            end
        end
    end

    if props.doorsBroken ~= nil then
        for k, v in pairs(props.doorsBroken) do
            if v then
                k = tonumber(k)
                if k then
                    SetVehicleDoorBroken(vehicle, k, true)
                end
            end
        end
    end

    if props.tyreBurst ~= nil then
        for k, v in pairs(props.tyreBurst) do
            if v then
                k = tonumber(k)
                if k then
                    SetVehicleTyreBurst(vehicle, k, true, 1000.0)
                end
            end
        end
    end
end

---@param coords vector3 | table coords to get the closest pickup to
---@param text string The text to display
---@param size? number The size of the text
---@param font? number The font of the text
---@return nil
function VFW.Game.Utils.DrawText3D(coords, text, size, font)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)

    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(vector - camCoords)

    size = size or 1
    font = font or 0

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0, 0.55 * scale)
    SetTextFont(font)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(vector.x, vector.y, vector.z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

--- showText
---@param args table Arguments
local function showText(args)
    args.shadow = args.shadow or true;
    args.font = args.font or 6;
    args.size = args.size or 0.50;
    args.posx = args.posx or 0.5;
    args.posy = args.posy or 0.4;
    args.msg = args.msg or "";

    SetTextFont(args.font)
    SetTextProportional(0)
    SetTextScale(args.size, args.size)
    if args.shadow == true then
        SetTextDropShadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
    end

    SetTextEntry("STRING")
    AddTextComponentString(args.msg);
    DrawText(args.posx, args.posy);
end

---@param title string The title of the menu
---@param barPosition number The position of the bar
---@param addLeft? number The left position of the text
function VFW.DrawTimeBars(title, barPosition, addLeft)
    if not addLeft then
        addLeft = 0;
    end

    RequestStreamedTextureDict("timerbars");
    if not HasStreamedTextureDictLoaded("timerbars") then
        return ;
    end

    local safezone = GetSafeZoneSize();
    local x = 1.0 - (1.0 - safezone) * 0.5 - 0.180 / 2;
    local y = 1.0 - (1.0 - safezone) * 0.5 - 0.045 / 2 - (barPosition - 1) * (0.045 + 0);
    DrawSprite("timerbars", "all_black_bg", x, y, 0.180, 0.045, 0.0, 255, 255, 255, 160);
    showText({ msg = title, font = 0, size = 0.36, posx = 0.840, posy = y / 1.014, shadow = false });
end

---@param account string Account name (money/bank/black_money)
---@return table|nil
function VFW.GetAccount(account)
    for i = 1, #VFW.PlayerData.accounts, 1 do
        if VFW.PlayerData.accounts[i].name == account then
            return VFW.PlayerData.accounts[i]
        end
    end

    return nil
end

---@param data table Notification data
RegisterNetEvent('vfw:showNotification', function(data)
    if data.type == "ADMIN_NEW_REPORT" and GetResourceKvpInt("staff_report_notif_hidden") == 1 then
        return
    end
    VFW.ShowNotification(data)
end)

RegisterNetEvent('vfw:showHelpNotification', VFW.ShowHelpNotification)

-- Credits to txAdmin for the list.
local mismatchedTypes = {}
do
    local raw = {
        ['guiztow'] = "automobile", -- trailer (towtruck guizoo)
        ['airtug'] = "automobile", -- trailer
        ['avisa'] = "submarine", -- boat
        ['blimp'] = "heli", -- plane
        ['blimp2'] = "heli", -- plane
        ['blimp3'] = "heli", -- plane
        ['caddy'] = "automobile", -- trailer
        ['caddy2'] = "automobile", -- trailer
        ['caddy3'] = "automobile", -- trailer
        ['chimera'] = "automobile", -- bike
        ['docktug'] = "automobile", -- trailer
        ['forklift'] = "automobile", -- trailer
        ['kosatka'] = "submarine", -- boat
        ['mower'] = "automobile", -- trailer
        ['policeb'] = "bike", -- automobile
        ['ripley'] = "automobile", -- trailer
        ['rrocket'] = "automobile", -- bike
        ['sadler'] = "automobile", -- trailer
        ['sadler2'] = "automobile", -- trailer
        ['scrap'] = "automobile", -- trailer
        ['slamtruck'] = "automobile", -- trailer
        ['Stryder'] = "automobile", -- bike
        ['submersible'] = "submarine", -- boat
        ['submersible2'] = "submarine", -- boat
        ['thruster'] = "heli", -- automobile
        ['towtruck'] = "automobile", -- trailer
        ['towtruck2'] = "automobile", -- trailer
        ['tractor'] = "automobile", -- trailer
        ['tractor2'] = "automobile", -- trailer
        ['tractor3'] = "automobile", -- trailer
        ['trailersmall2'] = "trailer", -- automobile
        ['utillitruck'] = "automobile", -- trailer
        ['utillitruck2'] = "automobile", -- trailer
        ['utillitruck3'] = "automobile", -- trailer
    }
    for name, vType in pairs(raw) do
        mismatchedTypes[joaat(name)] = vType
    end
end

---@param model number|string
---@return string | boolean
function VFW.GetVehicleTypeClient(model)
    model = type(model) == "string" and joaat(model) or model

    -- Certains addons répondent false à IsModelInCdimage tant que le modèle
    -- n'a pas été RequestModel. On tente un chargement court avant d'abandonner.
    if not IsModelInCdimage(model) then
        if not IsModelValid(model) then
            return false
        end
        RequestModel(model)
        local tries = 0
        while not HasModelLoaded(model) and tries < 40 do
            Wait(25)
            tries = tries + 1
        end
        if not HasModelLoaded(model) then
            return false
        end
        SetModelAsNoLongerNeeded(model)
    end

    if not IsModelAVehicle(model) then
        return false
    end

    if mismatchedTypes[model] then
        return mismatchedTypes[model]
    end

    local vehicleType = GetVehicleClassFromName(model)
    local types = {
        [8] = "bike",
        [11] = "trailer",
        [13] = "bike",
        [14] = "boat",
        [15] = "heli",
        [16] = "plane",
        [21] = "train",
    }

    return types[vehicleType] or "automobile"
end

VFW.GetVehicleType = VFW.GetVehicleTypeClient

--- .KeybindToggle
---@param key any
---@param command any
---@param name string
---@param callback function Callback function
---@param callbackUnpressed function Callback function
function VFW.KeybindToggle(key, command, name, callback, callbackUnpressed)
    RegisterCommand(('+vfw_%s'):format(command), function()
        if callback then
            callback()
        end

    end, false)

    RegisterCommand(('-vfw_%s'):format(command), function()
        if callbackUnpressed then
            callbackUnpressed()
        end

    end, false)

    RegisterKeyMapping(('+vfw_%s'):format(command), name, 'keyboard', key)
end

---Create VFW.Ped
---@param coords vector3|table Coordinates
---@param pedData number Ped handle
---@return any
function VFW.CreatePed(coords, pedData)
    if not coords or not pedData then
        return
    end

    local ped
    local model = joaat(pedData)

    VFW.Streaming.RequestModel(model)

    ped = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)

    SetModelAsNoLongerNeeded(model)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    return ped
end

--- RequestWalking
---@param set any
function RequestWalking(set)
    local timeout = GetGameTimer() + 5000

    while not HasAnimSetLoaded(set) and GetGameTimer() < timeout do
        RequestAnimSet(set)
        Wait(5)
    end
end

local hud_colors = {
    { id = 0, name = "HUD_COLOUR_PURE_WHITE", r = 255, g = 255, b = 255, a = 255 },
    { id = 1, name = "HUD_COLOUR_WHITE", r = 240, g = 240, b = 240, a = 255 },
    { id = 2, name = "HUD_COLOUR_BLACK", r = 0, g = 0, b = 0, a = 255 },
    { id = 3, name = "HUD_COLOUR_GREY", r = 155, g = 155, b = 155, a = 255 },
    { id = 4, name = "HUD_COLOUR_GREYLIGHT", r = 205, g = 205, b = 205, a = 255 },
    { id = 5, name = "HUD_COLOUR_GREYDARK", r = 77, g = 77, b = 77, a = 255 },
    { id = 6, name = "HUD_COLOUR_RED", r = 224, g = 50, b = 50, a = 255 },
    { id = 7, name = "HUD_COLOUR_REDLIGHT", r = 240, g = 153, b = 153, a = 255 },
    { id = 8, name = "HUD_COLOUR_REDDARK", r = 112, g = 25, b = 25, a = 255 },
    { id = 9, name = "HUD_COLOUR_BLUE", r = 93, g = 182, b = 229, a = 255 },
    { id = 10, name = "HUD_COLOUR_BLUELIGHT", r = 174, g = 219, b = 242, a = 255 },
    { id = 11, name = "HUD_COLOUR_BLUEDARK", r = 47, g = 92, b = 115, a = 255 },
    { id = 12, name = "HUD_COLOUR_YELLOW", r = 240, g = 200, b = 80, a = 255 },
    { id = 13, name = "HUD_COLOUR_YELLOWLIGHT", r = 254, g = 235, b = 169, a = 255 },
    { id = 14, name = "HUD_COLOUR_YELLOWDARK", r = 126, g = 107, b = 41, a = 255 },
    { id = 15, name = "HUD_COLOUR_ORANGE", r = 255, g = 133, b = 85, a = 255 },
    { id = 16, name = "HUD_COLOUR_ORANGELIGHT", r = 255, g = 194, b = 170, a = 255 },
    { id = 17, name = "HUD_COLOUR_ORANGEDARK", r = 127, g = 66, b = 42, a = 255 },
    { id = 18, name = "HUD_COLOUR_GREEN", r = 114, g = 204, b = 114, a = 255 },
    { id = 19, name = "HUD_COLOUR_GREENLIGHT", r = 185, g = 230, b = 185, a = 255 },
    { id = 20, name = "HUD_COLOUR_GREENDARK", r = 57, g = 102, b = 57, a = 255 },
    { id = 21, name = "HUD_COLOUR_PURPLE", r = 132, g = 102, b = 226, a = 255 },
    { id = 22, name = "HUD_COLOUR_PURPLELIGHT", r = 192, g = 179, b = 239, a = 255 },
    { id = 23, name = "HUD_COLOUR_PURPLEDARK", r = 67, g = 57, b = 111, a = 255 },
    { id = 24, name = "HUD_COLOUR_PINK", r = 203, g = 54, b = 148, a = 255 },
    { id = 25, name = "HUD_COLOUR_RADAR_HEALTH", r = 53, g = 154, b = 71, a = 255 },
    { id = 26, name = "HUD_COLOUR_RADAR_ARMOUR", r = 93, g = 182, b = 229, a = 255 },
    { id = 27, name = "HUD_COLOUR_RADAR_DAMAGE", r = 235, g = 36, b = 39, a = 255 },
    { id = 28, name = "HUD_COLOUR_NET_PLAYER1", r = 194, g = 80, b = 80, a = 255 },
    { id = 29, name = "HUD_COLOUR_NET_PLAYER2", r = 156, g = 110, b = 175, a = 255 },
    { id = 30, name = "HUD_COLOUR_NET_PLAYER3", r = 255, g = 123, b = 196, a = 255 },
    { id = 31, name = "HUD_COLOUR_NET_PLAYER4", r = 247, g = 159, b = 123, a = 255 },
    { id = 32, name = "HUD_COLOUR_NET_PLAYER5", r = 178, g = 144, b = 132, a = 255 },
    { id = 33, name = "HUD_COLOUR_NET_PLAYER6", r = 141, g = 206, b = 167, a = 255 },
    { id = 34, name = "HUD_COLOUR_NET_PLAYER7", r = 113, g = 169, b = 175, a = 255 },
    { id = 35, name = "HUD_COLOUR_NET_PLAYER8", r = 211, g = 209, b = 231, a = 255 },
    { id = 36, name = "HUD_COLOUR_NET_PLAYER9", r = 144, g = 127, b = 153, a = 255 },
    { id = 37, name = "HUD_COLOUR_NET_PLAYER10", r = 106, g = 196, b = 191, a = 255 },
    { id = 38, name = "HUD_COLOUR_NET_PLAYER11", r = 214, g = 196, b = 153, a = 255 },
    { id = 39, name = "HUD_COLOUR_NET_PLAYER12", r = 234, g = 142, b = 80, a = 255 },
    { id = 40, name = "HUD_COLOUR_NET_PLAYER13", r = 152, g = 203, b = 234, a = 255 },
    { id = 41, name = "HUD_COLOUR_NET_PLAYER14", r = 178, g = 98, b = 135, a = 255 },
    { id = 42, name = "HUD_COLOUR_NET_PLAYER15", r = 144, g = 142, b = 122, a = 255 },
    { id = 43, name = "HUD_COLOUR_NET_PLAYER16", r = 166, g = 117, b = 94, a = 255 },
    { id = 44, name = "HUD_COLOUR_NET_PLAYER17", r = 175, g = 168, b = 168, a = 255 },
    { id = 45, name = "HUD_COLOUR_NET_PLAYER18", r = 232, g = 142, b = 155, a = 255 },
    { id = 46, name = "HUD_COLOUR_NET_PLAYER19", r = 187, g = 214, b = 91, a = 255 },
    { id = 47, name = "HUD_COLOUR_NET_PLAYER20", r = 12, g = 123, b = 86, a = 255 },
    { id = 48, name = "HUD_COLOUR_NET_PLAYER21", r = 123, g = 196, b = 255, a = 255 },
    { id = 49, name = "HUD_COLOUR_NET_PLAYER22", r = 171, g = 60, b = 230, a = 255 },
    { id = 50, name = "HUD_COLOUR_NET_PLAYER23", r = 206, g = 169, b = 13, a = 255 },
    { id = 51, name = "HUD_COLOUR_NET_PLAYER24", r = 71, g = 99, b = 173, a = 255 },
    { id = 52, name = "HUD_COLOUR_NET_PLAYER25", r = 42, g = 166, b = 185, a = 255 },
    { id = 53, name = "HUD_COLOUR_NET_PLAYER26", r = 186, g = 157, b = 125, a = 255 },
    { id = 54, name = "HUD_COLOUR_NET_PLAYER27", r = 201, g = 225, b = 255, a = 255 },
    { id = 55, name = "HUD_COLOUR_NET_PLAYER28", r = 240, g = 240, b = 150, a = 255 },
    { id = 56, name = "HUD_COLOUR_NET_PLAYER29", r = 237, g = 140, b = 161, a = 255 },
    { id = 57, name = "HUD_COLOUR_NET_PLAYER30", r = 249, g = 138, b = 138, a = 255 },
    { id = 58, name = "HUD_COLOUR_NET_PLAYER31", r = 252, g = 239, b = 166, a = 255 },
    { id = 60, name = "HUD_COLOUR_SIMPLEBLIP_DEFAULT", r = 159, g = 201, b = 166, a = 255 },
    { id = 63, name = "HUD_COLOUR_MENU_BLUE_EXTRA_DARK", r = 40, g = 40, b = 40, a = 255 },
    { id = 64, name = "HUD_COLOUR_MENU_YELLOW", r = 240, g = 160, b = 0, a = 255 },
    { id = 65, name = "HUD_COLOUR_MENU_YELLOW_DARK", r = 240, g = 160, b = 0, a = 255 },
    { id = 66, name = "HUD_COLOUR_MENU_GREEN", r = 240, g = 160, b = 0, a = 255 },
    { id = 68, name = "HUD_COLOUR_MENU_GREY_DARK", r = 60, g = 60, b = 60, a = 255 },
    { id = 69, name = "HUD_COLOUR_MENU_HIGHLIGHT", r = 30, g = 30, b = 30, a = 255 },
    { id = 71, name = "HUD_COLOUR_MENU_DIMMED", r = 75, g = 75, b = 75, a = 255 },
    { id = 72, name = "HUD_COLOUR_MENU_EXTRA_DIMMED", r = 50, g = 50, b = 50, a = 255 },
    { id = 73, name = "HUD_COLOUR_BRIEF_TITLE", r = 95, g = 95, b = 95, a = 255 },
    { id = 74, name = "HUD_COLOUR_MID_GREY_MP", r = 100, g = 100, b = 100, a = 255 },
    { id = 75, name = "HUD_COLOUR_NET_PLAYER1_DARK", r = 93, g = 39, b = 39, a = 255 },
    { id = 76, name = "HUD_COLOUR_NET_PLAYER2_DARK", r = 77, g = 55, b = 89, a = 255 },
    { id = 77, name = "HUD_COLOUR_NET_PLAYER3_DARK", r = 124, g = 62, b = 99, a = 255 },
    { id = 78, name = "HUD_COLOUR_NET_PLAYER4_DARK", r = 120, g = 80, b = 80, a = 255 },
    { id = 79, name = "HUD_COLOUR_NET_PLAYER5_DARK", r = 87, g = 72, b = 66, a = 255 },
    { id = 80, name = "HUD_COLOUR_NET_PLAYER6_DARK", r = 74, g = 103, b = 83, a = 255 },
    { id = 81, name = "HUD_COLOUR_NET_PLAYER7_DARK", r = 60, g = 85, b = 88, a = 255 },
    { id = 82, name = "HUD_COLOUR_NET_PLAYER8_DARK", r = 105, g = 105, b = 64, a = 255 },
    { id = 83, name = "HUD_COLOUR_NET_PLAYER9_DARK", r = 72, g = 63, b = 76, a = 255 },
    { id = 84, name = "HUD_COLOUR_NET_PLAYER10_DARK", r = 53, g = 98, b = 95, a = 255 },
    { id = 85, name = "HUD_COLOUR_NET_PLAYER11_DARK", r = 107, g = 98, b = 76, a = 255 },
    { id = 86, name = "HUD_COLOUR_NET_PLAYER12_DARK", r = 117, g = 71, b = 40, a = 255 },
    { id = 87, name = "HUD_COLOUR_NET_PLAYER13_DARK", r = 76, g = 101, b = 117, a = 255 },
    { id = 88, name = "HUD_COLOUR_NET_PLAYER14_DARK", r = 65, g = 35, b = 47, a = 255 },
    { id = 89, name = "HUD_COLOUR_NET_PLAYER15_DARK", r = 72, g = 71, b = 61, a = 255 },
    { id = 90, name = "HUD_COLOUR_NET_PLAYER16_DARK", r = 85, g = 58, b = 47, a = 255 },
    { id = 91, name = "HUD_COLOUR_NET_PLAYER17_DARK", r = 87, g = 84, b = 84, a = 255 },
    { id = 92, name = "HUD_COLOUR_NET_PLAYER18_DARK", r = 116, g = 71, b = 77, a = 255 },
    { id = 93, name = "HUD_COLOUR_NET_PLAYER19_DARK", r = 93, g = 107, b = 45, a = 255 },
    { id = 94, name = "HUD_COLOUR_NET_PLAYER20_DARK", r = 6, g = 61, b = 43, a = 255 },
    { id = 95, name = "HUD_COLOUR_NET_PLAYER21_DARK", r = 61, g = 98, b = 127, a = 255 },
    { id = 96, name = "HUD_COLOUR_NET_PLAYER22_DARK", r = 85, g = 30, b = 115, a = 255 },
    { id = 97, name = "HUD_COLOUR_NET_PLAYER23_DARK", r = 103, g = 84, b = 6, a = 255 },
    { id = 98, name = "HUD_COLOUR_NET_PLAYER24_DARK", r = 35, g = 49, b = 86, a = 255 },
    { id = 99, name = "HUD_COLOUR_NET_PLAYER25_DARK", r = 21, g = 83, b = 92, a = 255 },
    { id = 100, name = "HUD_COLOUR_NET_PLAYER26_DARK", r = 93, g = 98, b = 62, a = 255 },
    { id = 101, name = "HUD_COLOUR_NET_PLAYER27_DARK", r = 100, g = 112, b = 127, a = 255 },
    { id = 102, name = "HUD_COLOUR_NET_PLAYER28_DARK", r = 120, g = 120, b = 75, a = 255 },
    { id = 103, name = "HUD_COLOUR_NET_PLAYER29_DARK", r = 152, g = 76, b = 93, a = 255 },
    { id = 104, name = "HUD_COLOUR_NET_PLAYER30_DARK", r = 124, g = 69, b = 69, a = 255 },
    { id = 105, name = "HUD_COLOUR_NET_PLAYER31_DARK", r = 10, g = 43, b = 50, a = 255 },
    { id = 106, name = "HUD_COLOUR_NET_PLAYER32_DARK", r = 95, g = 95, b = 10, a = 255 },
    { id = 107, name = "HUD_COLOUR_BRONZE", r = 180, g = 130, b = 97, a = 255 },
    { id = 108, name = "HUD_COLOUR_SILVER", r = 150, g = 153, b = 161, a = 255 },
    { id = 109, name = "HUD_COLOUR_GOLD", r = 214, g = 181, b = 99, a = 255 },
    { id = 110, name = "HUD_COLOUR_PLATINUM", r = 166, g = 221, b = 190, a = 255 },
    { id = 111, name = "HUD_COLOUR_GANG1", r = 29, g = 100, b = 153, a = 255 },
    { id = 112, name = "HUD_COLOUR_GANG2", r = 214, g = 116, b = 15, a = 255 },
    { id = 113, name = "HUD_COLOUR_GANG3", r = 135, g = 125, b = 142, a = 255 },
    { id = 114, name = "HUD_COLOUR_GANG4", r = 229, g = 119, b = 185, a = 255 },
    { id = 115, name = "HUD_COLOUR_SAME_CREW", r = 252, g = 239, b = 166, a = 255 },
    { id = 116, name = "HUD_COLOUR_FREEMODE", r = 45, g = 110, b = 185, a = 255 },
    { id = 117, name = "HUD_COLOUR_PAUSE_BG", r = 0, g = 0, b = 0, a = 186 },
    { id = 118, name = "HUD_COLOUR_FRIENDLY", r = 93, g = 182, b = 229, a = 255 },
    { id = 119, name = "HUD_COLOUR_ENEMY", r = 194, g = 80, b = 80, a = 255 },
    { id = 123, name = "HUD_COLOUR_FREEMODE_DARK", r = 22, g = 55, b = 92, a = 255 },
    { id = 124, name = "HUD_COLOUR_INACTIVE_MISSION", r = 154, g = 154, b = 154, a = 255 },
    { id = 125, name = "HUD_COLOUR_DAMAGE", r = 194, g = 80, b = 80, a = 255 },
    { id = 126, name = "HUD_COLOUR_PINKLIGHT", r = 252, g = 115, b = 201, a = 255 },
    { id = 127, name = "HUD_COLOUR_PM_MITEM_HIGHLIGHT", r = 252, g = 177, b = 49, a = 255 },
    { id = 128, name = "HUD_COLOUR_SCRIPT_VARIABLE", r = 0, g = 0, b = 0, a = 255 },
    { id = 129, name = "HUD_COLOUR_YOGA", r = 109, g = 247, b = 204, a = 255 },
    { id = 130, name = "HUD_COLOUR_TENNIS", r = 241, g = 101, b = 34, a = 255 },
    { id = 131, name = "HUD_COLOUR_GOLF", r = 214, g = 189, b = 97, a = 255 },
    { id = 135, name = "HUD_COLOUR_SOCIAL_CLUB", r = 234, g = 153, b = 28, a = 255 },
    { id = 136, name = "HUD_COLOUR_PLATFORM_BLUE", r = 11, g = 55, b = 123, a = 255 },
    { id = 137, name = "HUD_COLOUR_PLATFORM_GREEN", r = 146, g = 200, b = 62, a = 255 },
    { id = 138, name = "HUD_COLOUR_PLATFORM_GREY", r = 234, g = 153, b = 28, a = 255 },
    { id = 139, name = "HUD_COLOUR_FACEBOOK_BLUE", r = 66, g = 89, b = 148, a = 255 },
    { id = 140, name = "HUD_COLOUR_INGAME_BG", r = 0, g = 0, b = 0, a = 186 },
    { id = 142, name = "HUD_COLOUR_WAYPOINT", r = 164, g = 76, b = 242, a = 255 },
    { id = 143, name = "HUD_COLOUR_MICHAEL", r = 101, g = 180, b = 212, a = 255 },
    { id = 144, name = "HUD_COLOUR_FRANKLIN", r = 171, g = 237, b = 171, a = 255 },
    { id = 145, name = "HUD_COLOUR_TREVOR", r = 255, g = 163, b = 87, a = 255 },
    { id = 147, name = "HUD_COLOUR_GOLF_P2", r = 235, g = 239, b = 30, a = 255 },
    { id = 148, name = "HUD_COLOUR_GOLF_P3", r = 255, g = 149, b = 14, a = 255 },
    { id = 149, name = "HUD_COLOUR_GOLF_P4", r = 246, g = 60, b = 161, a = 255 },
    { id = 150, name = "HUD_COLOUR_WAYPOINTLIGHT", r = 210, g = 166, b = 249, a = 255 },
    { id = 151, name = "HUD_COLOUR_WAYPOINTDARK", r = 82, g = 38, b = 121, a = 255 },
    { id = 152, name = "HUD_COLOUR_PANEL_LIGHT", r = 0, g = 0, b = 0, a = 77 },
    { id = 153, name = "HUD_COLOUR_MICHAEL_DARK", r = 72, g = 103, b = 116, a = 255 },
    { id = 154, name = "HUD_COLOUR_FRANKLIN_DARK", r = 85, g = 118, b = 85, a = 255 },
    { id = 155, name = "HUD_COLOUR_TREVOR_DARK", r = 127, g = 81, b = 43, a = 255 },
    { id = 157, name = "HUD_COLOUR_PAUSEMAP_TINT", r = 0, g = 0, b = 0, a = 215 },
    { id = 158, name = "HUD_COLOUR_PAUSE_DESELECT", r = 100, g = 100, b = 100, a = 127 },
    { id = 160, name = "HUD_COLOUR_PM_WEAPONS_LOCKED", r = 240, g = 240, b = 240, a = 191 },
    { id = 163, name = "HUD_COLOUR_PAUSEMAP_TINT_HALF", r = 0, g = 0, b = 0, a = 215 },
    { id = 164, name = "HUD_COLOUR_NORTH_BLUE_OFFICIAL", r = 0, g = 71, b = 133, a = 255 },
    { id = 165, name = "HUD_COLOUR_SCRIPT_VARIABLE_2", r = 0, g = 0, b = 0, a = 255 },
    { id = 166, name = "HUD_COLOUR_H", r = 33, g = 118, b = 37, a = 255 },
    { id = 167, name = "HUD_COLOUR_HDARK", r = 37, g = 102, b = 40, a = 255 },
    { id = 168, name = "HUD_COLOUR_T", r = 234, g = 153, b = 28, a = 255 },
    { id = 169, name = "HUD_COLOUR_TDARK", r = 225, g = 140, b = 8, a = 255 },
    { id = 170, name = "HUD_COLOUR_HSHARD", r = 20, g = 40, b = 0, a = 255 },
    { id = 171, name = "HUD_COLOUR_CONTROLLER_MICHAEL", r = 48, g = 255, b = 255, a = 255 },
    { id = 172, name = "HUD_COLOUR_CONTROLLER_FRANKLIN", r = 48, g = 255, b = 0, a = 255 },
    { id = 173, name = "HUD_COLOUR_CONTROLLER_TREVOR", r = 176, g = 80, b = 0, a = 255 },
    { id = 174, name = "HUD_COLOUR_CONTROLLER_CHOP", r = 127, g = 0, b = 0, a = 255 },
    { id = 175, name = "HUD_COLOUR_VIDEO_EDITOR_VIDEO", r = 53, g = 166, b = 224, a = 255 },
    { id = 176, name = "HUD_COLOUR_VIDEO_EDITOR_AUDIO", r = 162, g = 79, b = 157, a = 255 },
    { id = 177, name = "HUD_COLOUR_VIDEO_EDITOR_TEXT", r = 104, g = 192, b = 141, a = 255 },
    { id = 178, name = "HUD_COLOUR_HB_BLUE", r = 29, g = 100, b = 153, a = 255 },
    { id = 179, name = "HUD_COLOUR_HB_YELLOW", r = 234, g = 153, b = 28, a = 255 },
    { id = 180, name = "HUD_COLOUR_VIDEO_EDITOR_SCORE", r = 240, g = 160, b = 1, a = 255 },
    { id = 181, name = "HUD_COLOUR_VIDEO_EDITOR_AUDIO_FADEOUT", r = 59, g = 34, b = 57, a = 255 },
    { id = 182, name = "HUD_COLOUR_VIDEO_EDITOR_TEXT_FADEOUT", r = 41, g = 68, b = 53, a = 255 },
    { id = 183, name = "HUD_COLOUR_VIDEO_EDITOR_SCORE_FADEOUT", r = 82, g = 58, b = 10, a = 255 },
    { id = 184, name = "HUD_COLOUR_HEIST_BACKGROUND", r = 37, g = 102, b = 40, a = 186 },
    { id = 186, name = "HUD_COLOUR_VIDEO_EDITOR_AMBIENT_FADEOUT", r = 80, g = 70, b = 34, a = 255 },
    { id = 192, name = "HUD_COLOUR_G1", r = 247, g = 159, b = 123, a = 255 },
    { id = 193, name = "HUD_COLOUR_G2", r = 226, g = 134, b = 187, a = 255 },
    { id = 194, name = "HUD_COLOUR_G3", r = 239, g = 238, b = 151, a = 255 },
    { id = 195, name = "HUD_COLOUR_G4", r = 113, g = 169, b = 175, a = 255 },
    { id = 196, name = "HUD_COLOUR_G5", r = 160, g = 140, b = 193, a = 255 },
    { id = 197, name = "HUD_COLOUR_G6", r = 141, g = 206, b = 167, a = 255 },
    { id = 198, name = "HUD_COLOUR_G7", r = 181, g = 214, b = 234, a = 255 },
    { id = 199, name = "HUD_COLOUR_G8", r = 178, g = 144, b = 132, a = 255 },
    { id = 200, name = "HUD_COLOUR_G9", r = 0, g = 132, b = 114, a = 255 },
    { id = 201, name = "HUD_COLOUR_G10", r = 216, g = 85, b = 117, a = 255 },
    { id = 202, name = "HUD_COLOUR_G11", r = 30, g = 100, b = 152, a = 255 },
    { id = 203, name = "HUD_COLOUR_G12", r = 43, g = 181, b = 117, a = 255 },
    { id = 204, name = "HUD_COLOUR_G13", r = 233, g = 141, b = 79, a = 255 },
    { id = 205, name = "HUD_COLOUR_G14", r = 137, g = 210, b = 215, a = 255 },
    { id = 206, name = "HUD_COLOUR_G15", r = 134, g = 125, b = 141, a = 255 },
    { id = 207, name = "HUD_COLOUR_ADVERSARY", r = 109, g = 34, b = 33, a = 255 },
    { id = 208, name = "HUD_COLOUR_DEGEN_RED", r = 255, g = 0, b = 0, a = 255 },
    { id = 209, name = "HUD_COLOUR_DEGEN_YELLOW", r = 255, g = 255, b = 0, a = 255 },
    { id = 210, name = "HUD_COLOUR_DEGEN_GREEN", r = 0, g = 255, b = 0, a = 255 },
    { id = 211, name = "HUD_COLOUR_DEGEN_CYAN", r = 0, g = 255, b = 255, a = 255 },
    { id = 212, name = "HUD_COLOUR_DEGEN_BLUE", r = 0, g = 0, b = 255, a = 255 },
    { id = 213, name = "HUD_COLOUR_DEGEN_MAGENTA", r = 255, g = 0, b = 255, a = 255 },
    { id = 214, name = "HUD_COLOUR_STUNT_1", r = 38, g = 136, b = 234, a = 255 },
    { id = 216, name = "HUD_COLOUR_SPECIAL_RACE_SERIES", r = 154, g = 178, b = 54, a = 255 },
    { id = 217, name = "HUD_COLOUR_SPECIAL_RACE_SERIES_DARK", r = 93, g = 107, b = 45, a = 255 },
    { id = 218, name = "HUD_COLOUR_CS", r = 206, g = 169, b = 13, a = 255 },
    { id = 219, name = "HUD_COLOUR_CS_DARK", r = 103, g = 84, b = 6, a = 255 },
    { id = 220, name = "HUD_COLOUR_TECH_GREEN", r = 0, g = 151, b = 151, a = 255 },
    { id = 221, name = "HUD_COLOUR_TECH_GREEN_DARK", r = 5, g = 119, b = 113, a = 255 },
    { id = 222, name = "HUD_COLOUR_TECH_RED", r = 151, g = 0, b = 0, a = 255 },
    { id = 223, name = "HUD_COLOUR_TECH_GREEN_VERY_DARK", r = 0, g = 40, b = 40, a = 255 },
    { id = 234, name = "HUD_COLOUR_JUNK_ENERGY", r = 29, g = 237, b = 195, a = 255 }
}

local blip_colors = {
    { id = 0, name = "White", r = 255, g = 255, b = 255, a = 255 },
    { id = 1, name = "Red", r = 255, g = 0, b = 0, a = 255 },
    { id = 2, name = "Green", r = 0, g = 255, b = 0, a = 255 },
    { id = 3, name = "Blue", r = 0, g = 0, b = 255, a = 255 },
    { id = 4, name = "PlayerBlue", r = 0, g = 162, b = 255, a = 255 },
    { id = 5, name = "Yellow", r = 255, g = 255, b = 0, a = 255 },
    { id = 6, name = "Orange", r = 255, g = 165, b = 0, a = 255 },
    { id = 7, name = "Purple", r = 128, g = 0, b = 128, a = 255 },
    { id = 8, name = "Pink", r = 255, g = 192, b = 203, a = 255 },
    { id = 9, name = "Grey", r = 128, g = 128, b = 128, a = 255 },
    { id = 10, name = "DarkBrown", r = 92, g = 64, b = 51, a = 255 },
    { id = 11, name = "LightBrown", r = 205, g = 133, b = 63, a = 255 },
    { id = 12, name = "LightBlue", r = 173, g = 216, b = 230, a = 255 },
    { id = 13, name = "VeryLightGreen", r = 144, g = 238, b = 144, a = 255 },
    { id = 14, name = "LightGreen", r = 50, g = 205, b = 50, a = 255 },
    { id = 15, name = "DarkGreen", r = 0, g = 100, b = 0, a = 255 },
    { id = 16, name = "LightRed", r = 255, g = 99, b = 71, a = 255 },
    { id = 17, name = "VeryLightRed", r = 255, g = 153, b = 153, a = 255 },
    { id = 18, name = "DarkRed", r = 139, g = 0, b = 0, a = 255 },
    { id = 19, name = "Black", r = 0, g = 0, b = 0, a = 255 },
    { id = 20, name = "DarkGrey", r = 169, g = 169, b = 169, a = 255 },
    { id = 21, name = "LightYellow", r = 255, g = 255, b = 224, a = 255 },
    { id = 22, name = "LightPink", r = 255, g = 182, b = 193, a = 255 },
    { id = 23, name = "LightPurple", r = 216, g = 191, b = 216, a = 255 },
    { id = 24, name = "DarkPurple", r = 75, g = 0, b = 130, a = 255 },
    { id = 25, name = "Cyan", r = 0, g = 255, b = 255, a = 255 },
    { id = 26, name = "LightOrange", r = 255, g = 215, b = 0, a = 255 },
    { id = 27, name = "DarkOrange", r = 255, g = 140, b = 0, a = 255 },
    { id = 28, name = "Gold", r = 255, g = 215, b = 0, a = 255 },
    { id = 29, name = "Bronze", r = 205, g = 127, b = 50, a = 255 },
    { id = 30, name = "Silver", r = 192, g = 192, b = 192, a = 255 },
    { id = 31, name = "Platinum", r = 229, g = 228, b = 226, a = 255 },
    { id = 38, name = "PoliceBlue", r = 63, g = 81, b = 181, a = 255 },
    { id = 40, name = "MidnightBlue", r = 25, g = 25, b = 112, a = 255 },
    { id = 42, name = "DarkBlue", r = 0, g = 0, b = 139, a = 255 },
    { id = 46, name = "HighlighterYellow", r = 255, g = 255, b = 153, a = 255 },
    { id = 48, name = "HighlighterPink", r = 255, g = 153, b = 255, a = 255 }
}

--- decimalToRGB
---@param decimal any
---@return any
local function decimalToRGB(decimal)
    -- Handle nil or invalid values
    if not decimal or type(decimal) ~= "number" then
        return 255, 255, 255  -- Return white as default
    end

    local r = math.floor(decimal / 65536) % 256
    local g = math.floor(decimal / 256) % 256
    local b = decimal % 256

    return r, g, b
end

--- colorDistance
---@param r1 any
---@param g1 any
---@param b1 any
---@param r2 any
---@param g2 any
---@param b2 any
---@return any
local function colorDistance(r1, g1, b1, r2, g2, b2)
    return math.sqrt((r2 - r1) ^ 2 + (g2 - g1) ^ 2 + (b2 - b1) ^ 2)
end

--- .DecimalColorToHUDColor
---@param decimalColor any
function VFW.DecimalColorToHUDColor(decimalColor)
    -- Return default white color object if input is nil
    if not decimalColor then
        return { id = 0, name = "HUD_COLOUR_PURE_WHITE", r = 255, g = 255, b = 255, a = 255 }
    end

    local r, g, b = decimalToRGB(decimalColor)
    local closestColor = nil
    local minDistance = 1000

    for _, color in ipairs(hud_colors) do
        local dist = colorDistance(r, g, b, color.r, color.g, color.b)

        if dist < minDistance then
            minDistance = dist
            closestColor = color
        end
    end

    -- Return default white if no color found
    return closestColor or { id = 0, name = "HUD_COLOUR_PURE_WHITE", r = 255, g = 255, b = 255, a = 255 }
end

--- .DecimalColorToBlipColor
---@param decimalColor any
function VFW.DecimalColorToBlipColor(decimalColor)
    -- Return default white color object if input is nil
    if not decimalColor then
        return { id = 0, name = "White", r = 255, g = 255, b = 255, a = 255 }
    end

    local r, g, b = decimalToRGB(decimalColor)
    local closestColor = nil
    local minDistance = 1000

    for _, color in ipairs(blip_colors) do
        local dist = colorDistance(r, g, b, color.r, color.g, color.b)

        if dist < minDistance then
            minDistance = dist
            closestColor = color
        end
    end

    -- Return default white if no color found
    return closestColor or { id = 0, name = "White", r = 255, g = 255, b = 255, a = 255 }
end

exports("GetPlayerPhonesClient", function()
    if not VFW.PlayerData.inventory then
        return nil
    end

    local phones = {}

    for _, item in ipairs(VFW.PlayerData.inventory) do
        if item.name == "phone" then
            phones[#phones + 1] = item
        end
    end

    return phones
end)

---Get VFW.AllPlayersInArea
---@param coords vector3|table Coordinates
---@param zone any
function VFW.GetAllPlayersInArea(coords, zone)
    local playersInArea = {}
    if zone == nil then
        zone = 150.0
    end

    for playerId, player in pairs(GetActivePlayers()) do
        local pPed = GetPlayerPed(player)
        local pCoords = GetEntityCoords(pPed)
        if #(vector3(pCoords.x, pCoords.y, pCoords.z) - vector3(coords.x, coords.y, coords.z)) <= zone then
            table.insert(playersInArea, player)
        end
    end

    return playersInArea
end

--- .TreatZone
---@param radius any
---@param coords vector3|table Coordinates
---@return any
function VFW.TreatZone(radius, coords)
    local zoneCoords = coords or GetEntityCoords(VFW.PlayerData.ped)
    local radius = tonumber(radius) or 100

    if not radius then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce rayon n'est pas valide !"
        })
        return
    end

    if radius > 750 then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Rayon trop grand !"
        })
        return
    end

    local reviveList = {}
    local healList = {}
    local players = VFW.GetAllPlayersInArea(zoneCoords, radius)
    local localPlayerId = PlayerId()
    local processedPlayers = {}

    -- Traiter d'abord le joueur local s'il est dans la zone
    local localPed = PlayerPedId()
    local localCoords = GetEntityCoords(localPed)
    if #(localCoords - zoneCoords) <= radius then
        local myServerId = GetPlayerServerId(localPlayerId)
        local myHealth = GetEntityHealth(localPed)
        local myIsDead = IsEntityDead(localPed)
        processedPlayers[localPlayerId] = true

        if myIsDead then
            table.insert(reviveList, myServerId)
        elseif myHealth < 200 then
            table.insert(healList, myServerId)
        end
    end

    -- Collecter les autres joueurs
    for _, player in pairs(players) do
        if not processedPlayers[player] then
            local targetID = GetPlayerServerId(player)
            local targetPed = GetPlayerPed(player)
            local health = GetEntityHealth(targetPed)
            local isDead = IsEntityDead(targetPed)

            if isDead then
                table.insert(reviveList, targetID)
            elseif health < 200 then
                table.insert(healList, targetID)
            end
        end
    end

    -- Envoyer au serveur pour traitement
    TriggerServerEvent("core:staff:treatZone", reviveList, healList)

    VFW.ShowNotification({
        type = 'VERT',
        content = "Joueurs soignés dans un rayon de " .. radius .. "m, " .. (#reviveList + #healList) .. " au total"
    })
end

---Create VFW.PlayerClone
---@param data table
---@param tattoos any
---@param coords vector3|table Coordinates
---@param heading any
function VFW.CreatePlayerClone(data, tattoos, coords, heading)
    local modelPlayer

    if data['sex'] == 0 then
        modelPlayer = `mp_m_freemode_01`
    elseif data['sex'] > 1 then
        modelPlayer = Config.PedsCharCreator[data.sex - 1]
    else
        modelPlayer = `mp_f_freemode_01`
    end

    VFW.Streaming.RequestModel(modelPlayer)

    local clone = CreatePed(4, modelPlayer, coords.x, coords.y, coords.z, heading, false, true)

    local face_weight = (data["face_md_weight"] / 100) + 0.0
    local skin_weight = (data["skin_md_weight"] / 100) + 0.0
    SetPedHeadBlendData(clone, data["mom"], data["dad"], 0, data["mom"], data["dad"], 0, face_weight, skin_weight, 0.0, false)

    SetPedFaceFeature(clone, 0, (data["nose_1"] / 10) + 0.0) -- Nose Width
    SetPedFaceFeature(clone, 1, (data["nose_2"] / 10) + 0.0) -- Nose Peak Height
    SetPedFaceFeature(clone, 2, (data["nose_3"] / 10) + 0.0) -- Nose Peak Length
    SetPedFaceFeature(clone, 3, (data["nose_4"] / 10) + 0.0) -- Nose Bone Height
    SetPedFaceFeature(clone, 4, (data["nose_5"] / 10) + 0.0) -- Nose Peak Lowering
    SetPedFaceFeature(clone, 5, (data["nose_6"] / 10) + 0.0) -- Nose Bone Twist
    SetPedFaceFeature(clone, 6, (data["eyebrows_5"] / 10) + 0.0) -- Eyebrow height
    SetPedFaceFeature(clone, 7, (data["eyebrows_6"] / 10) + 0.0) -- Eyebrow depth
    SetPedFaceFeature(clone, 8, (data["cheeks_1"] / 10) + 0.0) -- Cheekbones Height
    SetPedFaceFeature(clone, 9, (data["cheeks_2"] / 10) + 0.0) -- Cheekbones Width
    SetPedFaceFeature(clone, 10, (data["cheeks_3"] / 10) + 0.0) -- Cheeks Width
    SetPedFaceFeature(clone, 11, (data["eye_squint"] / 10) + 0.0) -- Eyes squint
    SetPedFaceFeature(clone, 12, (data["lip_thickness"] / 10) + 0.0) -- Lip Fullness
    SetPedFaceFeature(clone, 13, (data["jaw_1"] / 10) + 0.0) -- Jaw Bone Width
    SetPedFaceFeature(clone, 14, (data["jaw_2"] / 10) + 0.0) -- Jaw Bone Length
    SetPedFaceFeature(clone, 15, (data["chin_1"] / 10) + 0.0) -- Chin Height
    SetPedFaceFeature(clone, 16, (data["chin_2"] / 10) + 0.0) -- Chin Length
    SetPedFaceFeature(clone, 17, (data["chin_3"] / 10) + 0.0) -- Chin Width
    SetPedFaceFeature(clone, 18, (data["chin_4"] / 10) + 0.0) -- Chin Hole Size
    SetPedFaceFeature(clone, 19, (data["neck_thickness"] / 10) + 0.0) -- Neck Thickness

    SetPedHairColor(clone, data["hair_color_1"], data["hair_color_2"])
    SetPedComponentVariation(clone, 2, data["hair_1"], data["hair_2"], 2)

    SetPedHeadOverlay(clone, 3, data["age_1"], (data["age_2"] / 10) + 0.0) -- Age
    SetPedHeadOverlay(clone, 0, data["blemishes_1"], (data["blemishes_2"] / 10) + 0.0) -- Blemishes
    SetPedHeadOverlay(clone, 1, data["beard_1"], (data["beard_2"] / 10) + 0.0) -- Beard
    SetPedEyeColor(clone, data["eye_color"]) -- Eyes color
    SetPedHeadOverlay(clone, 2, data["eyebrows_1"], (data["eyebrows_2"] / 10) + 0.0) -- Eyebrows
    SetPedHeadOverlay(clone, 4, data["makeup_1"], (data["makeup_2"] / 10) + 0.0) -- Makeup
    SetPedHeadOverlay(clone, 8, data["lipstick_1"], (data["lipstick_2"] / 10) + 0.0) -- Lipstick
    SetPedHeadOverlay(clone, 5, data["blush_1"], (data["blush_2"] / 10) + 0.0) -- Blush
    SetPedHeadOverlay(clone, 6, data["complexion_1"], (data["complexion_2"] / 10) + 0.0) -- Complexion
    SetPedHeadOverlay(clone, 7, data["sun_1"], (data["sun_2"] / 10) + 0.0) -- Sun Damage
    SetPedHeadOverlay(clone, 9, data["moles_1"], (data["moles_2"] / 10) + 0.0) -- Moles/Freckles
    SetPedHeadOverlay(clone, 10, data["chest_1"], (data["chest_2"] / 10) + 0.0) -- Chest Hair

    SetPedHeadOverlayColor(clone, 1, 1, data["beard_3"], data["beard_4"]) -- Beard Color
    SetPedHeadOverlayColor(clone, 2, 1, data["eyebrows_3"], data["eyebrows_4"]) -- Eyebrows Color
    SetPedHeadOverlayColor(clone, 4, 1, data["makeup_3"], data["makeup_4"]) -- Makeup Color
    SetPedHeadOverlayColor(clone, 8, 1, data["lipstick_3"], data["lipstick_4"]) -- Lipstick Color
    SetPedHeadOverlayColor(clone, 5, 1, data["blush_3"]) -- Blush Color
    SetPedHeadOverlayColor(clone, 10, 1, data["chest_3"]) -- Torso Color

    if data["bodyb_1"] == -1 then
        SetPedHeadOverlay(clone, 11, 255, (data["bodyb_2"] / 10) + 0.0)
    else
        SetPedHeadOverlay(clone, 11, data["bodyb_1"], (data["bodyb_2"] / 10) + 0.0)
    end

    if data["bodyb_3"] == -1 then
        SetPedHeadOverlay(clone, 12, 255, (data["bodyb_4"] / 10) + 0.0)
    else
        SetPedHeadOverlay(clone, 12, data["bodyb_3"], (data["bodyb_4"] / 10) + 0.0)
    end

    SetPedComponentVariation(clone, 8, data["tshirt_1"], data["tshirt_2"], 2) -- Tshirt
    SetPedComponentVariation(clone, 11, data["torso_1"], data["torso_2"], 2) -- torso parts
    SetPedComponentVariation(clone, 3, data["arms"], data["arms_2"], 2) -- Arms
    SetPedComponentVariation(clone, 10, data["decals_1"], data["decals_2"], 2) -- decals
    SetPedComponentVariation(clone, 4, data["pants_1"], data["pants_2"], 2) -- pants
    SetPedComponentVariation(clone, 6, data["shoes_1"], data["shoes_2"], 2) -- shoes
    SetPedComponentVariation(clone, 1, data["mask_1"], data["mask_2"], 2) -- mask
    SetPedComponentVariation(clone, 9, data["bproof_1"], data["bproof_2"], 2) -- bulletproof
    SetPedComponentVariation(clone, 7, data["chain_1"], data["chain_2"], 2) -- chain
    SetPedComponentVariation(clone, 5, data["bags_1"], data["bags_2"], 2) -- Bag

    if data["ears_1"] == -1 then
        ClearPedProp(clone, 2)
    else
        SetPedPropIndex(clone, 2, data["ears_1"], data["ears_2"], 2) -- Ears
    end

    if data["helmet_1"] == -1 then
        ClearPedProp(clone, 0)
    else
        SetPedPropIndex(clone, 0, data["helmet_1"], data["helmet_2"], 2) -- Helmet
    end

    if data["glasses_1"] == -1 then
        ClearPedProp(clone, 1)
    else
        SetPedPropIndex(clone, 1, data["glasses_1"], data["glasses_2"], 2) -- Glasses
    end

    if data["watches_1"] == -1 then
        ClearPedProp(clone, 6)
    else
        SetPedPropIndex(clone, 6, data["watches_1"], data["watches_2"], 2) -- Watches
    end

    if data["bracelets_1"] == -1 then
        ClearPedProp(clone, 7)
    else
        SetPedPropIndex(clone, 7, data["bracelets_1"], data["bracelets_2"], 2) -- Bracelets
    end

    if data['degrade_collection'] and data['degrade_hashname'] then
        AddPedDecorationFromHashes(clone, data['degrade_collection'], data['degrade_hashname'])
    end

    if tattoos then
        for _, tattoo in pairs(tattoos) do
            ApplyPedOverlay(clone, joaat(tattoo.Collection), joaat(tattoo.Hash))
        end
    end

    return clone
end

--- .RealWait
---@param ms any
---@param cb function Callback function
---@return any
function VFW.RealWait(ms, cb)
    local timer = GetGameTimer() + ms

    while GetGameTimer() < timer do
        if cb ~= nil then
            cb(function(stop)
                if stop then
                    timer = 0
                    return
                end
            end)
        end

        Wait(0)
    end
end

--- .Subtitle
---@param text string
---@param time any
function VFW.Subtitle(text, time)
    ClearPrints()
    AddTextEntry('vfw:Subtitle', text)
    BeginTextCommandPrint('vfw:subtitle')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(time and math.ceil(time) or 0, true)
end

---@param entity Entity
---@return table
local function GetEntityBoundingBox(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    local pad = 0.001

    local retval = {
        -- Bottom
        GetOffsetFromEntityInWorldCoords(entity, min.x - pad, min.y - pad, min.z - pad),
        GetOffsetFromEntityInWorldCoords(entity, max.x + pad, min.y - pad, min.z - pad),
        GetOffsetFromEntityInWorldCoords(entity, max.x + pad, max.y + pad, min.z - pad),
        GetOffsetFromEntityInWorldCoords(entity, min.x - pad, max.y + pad, min.z - pad),

        -- Top
        GetOffsetFromEntityInWorldCoords(entity, min.x - pad, min.y - pad, max.z + pad),
        GetOffsetFromEntityInWorldCoords(entity, max.x + pad, min.y - pad, max.z + pad),
        GetOffsetFromEntityInWorldCoords(entity, max.x + pad, max.y + pad, max.z + pad),
        GetOffsetFromEntityInWorldCoords(entity, min.x - pad, max.y + pad, max.z + pad)
    }

    return retval
end

---@param point1 vector3
---@param point2 vector3
local function Line(point1, point2)
    local color = { r = 255, g = 255, b = 255, a = 255 }
    DrawLine(point1.x, point1.y, point1.z, point2.x, point2.y, point2.z, color.r, color.g, color.b, color.a)
end

---@param box table
local function DrawEdges(box)
    -- Bottom
    Line(box[1], box[2])
    Line(box[2], box[3])
    Line(box[3], box[4])
    Line(box[4], box[1])

    -- Top
    Line(box[5], box[6])
    Line(box[6], box[7])
    Line(box[7], box[8])
    Line(box[8], box[5])

    -- Connectors
    Line(box[1], box[5])
    Line(box[2], box[6])
    Line(box[3], box[7])
    Line(box[4], box[8])
end

---@param entity Entity
function VFW.DrawEntityBoundingBox(entity)
    local box = GetEntityBoundingBox(entity)
    DrawEdges(box)
end

---Get VFW.CursorScreenPosition
function VFW.GetCursorScreenPosition()
    if (not IsControlEnabled(0, 239)) then
        EnableControlAction(0, 239, true)
    end

    if (not IsControlEnabled(0, 240)) then
        EnableControlAction(0, 240, true)
    end

    return vector2(GetControlNormal(0, 239), GetControlNormal(0, 240))
end

---Get VFW.PlayerGlobalData
---@return any
function VFW.GetPlayerGlobalData()
    return TriggerServerCallback("vfw:getPlayerGlobalData")
end

--- .Clipboard
---@param value any
function VFW.Clipboard(value)
    SendNUIMessage({
        action = "nui:clipboard",
        data = value,
    })
end

--- .IsPermission
---@return boolean
function VFW.IsPermission()
    if VFW.PlayerData.job and VFW.PlayerData.job.type == "faction" and VFW.PlayerData.job.grade >= 3 then
        return true
    end

    return false
end

--- .AnnonceZone
---@param radius any
---@param message string
---@param coords vector3|table Coordinates
---@return any
function VFW.AnnonceZone(radius, message, coords)
    local zoneCoords = coords or GetEntityCoords(VFW.PlayerData.ped)
    radius = tonumber(radius) or 100

    if not radius then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce rayon n'est pas valide !"
        })
        return
    end

    if radius > 750 then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Rayon trop grand !"
        })
        return
    end

    if not message or message == "" then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce message n'est pas valide !"
        })
        return
    end

    local players = VFW.GetAllPlayersInArea(zoneCoords, radius)

    for _, player in pairs(players) do
        local targetID = GetPlayerServerId(player)

        TriggerServerEvent("core:vnotif:createAlert:zone", tonumber(targetID), message)
    end

    VFW.ShowNotification({
        type = 'VERT',
        content = "Annonce envoyée à tous les joueurs dans un rayon de ~s" .. radius .. "~c mètres."
    })
end

-- Command to display player UUID and server ID
RegisterCommand('id', function(source, args, showError)
    TriggerServerEvent('vfw:showPlayerID')
end)

-- Client event to receive and display player ID
RegisterNetEvent('vfw:receivePlayerID')
AddEventHandler('vfw:receivePlayerID', function(uuid, serverId)
    if uuid and serverId then
        VFW.ShowNotification({
            type = 'BLEU',
            content = "UUID: " .. tostring(uuid) .. "\nID Serveur: " .. tostring(serverId)
        })
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Erreur lors de la récupération de vos informations"
        })
    end
end)
