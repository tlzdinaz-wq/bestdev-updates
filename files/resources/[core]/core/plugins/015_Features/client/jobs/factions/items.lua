---@meta _
---@diagnostic disable: duplicate-doc-field

local lastMedKitUse = 0

--- checkMedicUse
---@return boolean
local function checkMedicUse()
    if (VFW.LastFireTime ~= 0 and (GetGameTimer() - VFW.LastFireTime) < 600000) or (lastMedKitUse ~= 0 and (GetGameTimer() - lastMedKitUse) < 300000) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous ne pouvez pas utiliser ce soin pour le moment."
        })
        return false
    else
        return true
    end
end

--- PlayAnim
---@param dict any
---@param anim any
---@param flag any
local function PlayAnim(dict, anim, flag)
    TaskPlayAnim(VFW.PlayerData.ped, dict, anim, 2.0, 2.0, -1, flag, 0, false, false, false)
    RemoveAnimDict(dict)
end


---@param health any
RegisterNetEvent("core:UseItemsMedic2", function(health)
    if not checkMedicUse() then
        return
    end

    RequestAnimDict('amb@medic@standing@kneel@base')
    while not HasAnimDictLoaded('amb@medic@standing@kneel@base') do
        Wait(0)
    end

    PlayAnim('amb@medic@standing@kneel@base', 'base', 1)

    Wait(10 * 1000)

    ClearPedTasks(VFW.PlayerData.ped)

    lastMedKitUse = GetGameTimer()

    SetEntityHealth(VFW.PlayerData.ped, GetEntityHealth(VFW.PlayerData.ped) + health)

    TriggerServerEvent("core:removeItems", "pad", 1)
end)

---@param health any
RegisterNetEvent("core:UseItemsMedic3", function(health)
    if not checkMedicUse() then
        return
    end

    RequestAnimDict('amb@medic@standing@kneel@base')
    while not HasAnimDictLoaded('amb@medic@standing@kneel@base') do
        Wait(0)
    end

    PlayAnim('amb@medic@standing@kneel@base', 'base', 1)

    Wait(20 * 1000)

    ClearPedTasks(VFW.PlayerData.ped)

    lastMedKitUse = GetGameTimer()

    SetEntityHealth(VFW.PlayerData.ped, GetEntityHealth(VFW.PlayerData.ped) + health)

    TriggerServerEvent("core:removeItems", "medikit", 1)
end)

---@param health any
RegisterNetEvent("core:UseItemsMedic4", function(health)
    if not checkMedicUse() then
        return
    end

    RequestAnimDict('mp_suicide')
    while not HasAnimDictLoaded('mp_suicide') do
        Wait(0)
    end

    PlayAnim('mp_suicide', 'pill', 1)

    Wait(6 * 1000)

    ClearPedTasks(VFW.PlayerData.ped)

    lastMedKitUse = GetGameTimer()

    SetEntityHealth(VFW.PlayerData.ped, GetEntityHealth(VFW.PlayerData.ped) + health)

    TriggerServerEvent("core:removeItems", "medic", 1)
end)

---@param health any
RegisterNetEvent("core:UseItemsMedic5", function(health)
    if not checkMedicUse() then
        return
    end

    RequestAnimDict('mp_suicide')
    while not HasAnimDictLoaded('mp_suicide') do
        Wait(0)
    end

    PlayAnim('mp_suicide', 'pill', 1)

    Wait(6 * 1000)

    ClearPedTasks(VFW.PlayerData.ped)

    lastMedKitUse = GetGameTimer()

    SetEntityHealth(VFW.PlayerData.ped, GetEntityHealth(VFW.PlayerData.ped) + health)

    TriggerServerEvent("core:removeItems", "pad2", 1)
end)

---@param health any
RegisterNetEvent("core:UseItemsMedic6", function(health)
    if not checkMedicUse() then
        return
    end

    RequestAnimDict('mp_suicide')
    while not HasAnimDictLoaded('mp_suicide') do
        Wait(0)
    end

    PlayAnim('mp_suicide', 'pill', 1)

    Wait(6 * 1000)

    ClearPedTasks(VFW.PlayerData.ped)

    lastMedKitUse = GetGameTimer()

    SetEntityHealth(VFW.PlayerData.ped, GetEntityHealth(VFW.PlayerData.ped) + health)

    TriggerServerEvent("core:removeItems", "pad3", 1)
end)

RegisterNetEvent("core:useBadge", function()
    local matricule = tostring(Player(GetPlayerServerId(NetworkGetPlayerIndexFromPed(VFW.PlayerData.ped))).state.id)

    while #matricule < 6 do
        matricule = tostring(0)..matricule
    end

    VFW.CloseInventory()

    local data = {
        service = VFW.PlayerData.job.name,
        name = VFW.PlayerData.name,
        matricule = matricule,
        grade = VFW.PlayerData.job.grade_label,
        photo = VFW.PlayerData.mugshot,
        disisions = ""
    }

    local playerId = VFW.StartSelect(5.0, true)

    if playerId then
        TriggerServerEvent("core:useBadge", GetPlayerServerId(playerId), data)
        ExecuteCommand("e idcard")

        SetTimeout(10 * 1000, function()
            ExecuteCommand("+clearAnim")
        end)
    end
end)

---@param data table
RegisterNetEvent("core:useBadgeTarget", function(data)
    VFW.DisableEscapeMenu(true)

    VFW.Nui.PoliceID(true, data)

    SetTimeout(10 * 1000, function()
        VFW.Nui.PoliceID(false)
        VFW.DisableEscapeMenu(false)
    end)
end)
