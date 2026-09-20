---@meta _
---@diagnostic disable: duplicate-doc-field

--- PlayAnim
---@param dict any
---@param anim any
---@param flag any
local function PlayAnim(dict, anim, flag)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(1) end
    TaskPlayAnim(VFW.PlayerData.ped, dict, anim, 2.0, 2.0, -1, flag, 0, false, false, false)
    RemoveAnimDict(dict)
end

---@param health any
RegisterNetEvent("core:jobs:client:HealthPlayer", function(health)
    SetEntityHealth(VFW.PlayerData.ped, health)
end)

---@param playerheading number|table Player ID or object
---@param coords vector3|table
---@param playerlocation number|table Player ID or object
---@param players number|table Player ID or object
RegisterNetEvent("core:jobs:client:reviveanimrevived", function(playerheading, coords, playerlocation , players)
    FreezeEntityPosition(VFW.PlayerData.ped, true)
    local origin = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    local forward = vector3(playerlocation.x + 0.0, playerlocation.y + 0.0, playerlocation.z + 0.0)
    local target = origin + forward * 1.0
    SetEntityCoords(VFW.PlayerData.ped, target.x, target.y, target.z - 1.0)
    SetEntityHeading(VFW.PlayerData.ped, playerheading - 270.0)
    while not IsEntityPlayingAnim(VFW.PlayerData.ped, "mini@cpr@char_b@cpr_def", "cpr_intro", 1) do
        PlayAnim("mini@cpr@char_b@cpr_def", "cpr_intro", 1)
        Wait(100)
    end

    TriggerServerEvent("core:jobs:server:reviveanimreviver", players)
    Wait(15800 - 900)
    for i = 1, 15, 1 do
        Wait(900)
        PlayAnim("mini@cpr@char_b@cpr_str", "cpr_pumpchest", 1)
    end

    PlayAnim("mini@cpr@char_b@cpr_str", "cpr_success", 1)
    Wait(30590)
    ClearPedTasks(VFW.PlayerData.ped)
    FreezeEntityPosition(VFW.PlayerData.ped, false)
end)

---@param players number|table Player ID or object
RegisterNetEvent("core:jobs:client:reviveanimreviver", function(players)
    TriggerServerEvent('core:jobs:server:RevivePlayer', players)
    Wait(150)
    PlayAnim("mini@cpr@char_a@cpr_def", "cpr_intro", 1)
    Wait(15800 - 900)
    for i = 1, 15, 1 do
        Wait(900)
        PlayAnim("mini@cpr@char_a@cpr_str", "cpr_pumpchest", 1)
    end

    PlayAnim("mini@cpr@char_a@cpr_str", "cpr_success", 1)
    Wait(30590)
    ClearPedTasks(VFW.PlayerData.ped)
end)
