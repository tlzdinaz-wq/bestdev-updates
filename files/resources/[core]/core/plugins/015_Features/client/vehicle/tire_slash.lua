local SLASH_DISTANCE = 1.5
local SLASH_DURATION = 3000
local isSlashing = false

local wheelBones = {
    { bone = "wheel_lf", index = 0 },
    { bone = "wheel_rf", index = 1 },
    { bone = "wheel_lr", index = 4 },
    { bone = "wheel_rr", index = 5 },
    { bone = "wheel_lm1", index = 2 },
    { bone = "wheel_rm1", index = 3 },
}

local function GetClosestWheel(ped, vehicle)
    local playerCoords = GetEntityCoords(ped)
    local closestDist = SLASH_DISTANCE
    local closestWheel = nil

    for _, wheel in ipairs(wheelBones) do
        local boneIndex = GetEntityBoneIndexByName(vehicle, wheel.bone)
        if boneIndex ~= -1 then
            local bonePos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
            local dist = #(playerCoords - bonePos)
            if dist < closestDist and not IsVehicleTyreBurst(vehicle, wheel.index, false) then
                closestDist = dist
                closestWheel = wheel
            end
        end
    end

    return closestWheel
end

local function GetClosestVehicleInRange(ped, range)
    local playerCoords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local closestVeh = nil
    local closestDist = range

    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            local dist = #(playerCoords - vehCoords)
            if dist < closestDist then
                closestDist = dist
                closestVeh = veh
            end
        end
    end

    return closestVeh
end

local function CanSlashTire(weaponHash)
    local allowed = GlobalState.TireSlashAllowed
    if not allowed then return false end

    local weaponData = VFW.GetWeaponFromHash(weaponHash)
    if not weaponData then return false end

    return allowed[weaponData.name:upper()] == true
end

local function SlashTire(vehicle, wheel)
    if isSlashing then return end
    isSlashing = true

    local ped = PlayerPedId()
    local boneIndex = GetEntityBoneIndexByName(vehicle, wheel.bone)
    local bonePos = GetWorldPositionOfEntityBone(vehicle, boneIndex)

    TaskTurnPedToFaceCoord(ped, bonePos.x, bonePos.y, bonePos.z, 1000)
    Wait(800)

    local dict = "melee@knife@streamed_core_fps"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(1) end
    TaskPlayAnim(ped, dict, "ground_attack_on_spot", 8.0, -8.0, -1, 1, 0, false, false, false)

    local completed = VFW.Nui.ProgressBar("Crevaison du pneu en cours...", SLASH_DURATION)

    ClearPedTasks(ped)
    RemoveAnimDict(dict)

    if completed then
        SetVehicleTyreBurst(vehicle, wheel.index, false, 1000.0)
        VFW.ShowNotification({ type = "VERT", content = "Pneu crevé." })
    end

    isSlashing = false
end

local showingPrompt = false

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)

        if weapon ~= `weapon_unarmed` and not IsPedInAnyVehicle(ped, false) and not isSlashing and CanSlashTire(weapon) then
            local vehicle = GetClosestVehicleInRange(ped, 5.0)

            if vehicle then
                local wheel = GetClosestWheel(ped, vehicle)

                if wheel then
                    if not showingPrompt then
                        showingPrompt = true
                    end
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour crever le pneu")

                    if VFW.Interact.JustPressed(0, 38) then
                        SlashTire(vehicle, wheel)
                    end

                    Wait(0)
                else
                    showingPrompt = false
                    Wait(500)
                end
            else
                showingPrompt = false
                Wait(1000)
            end
        else
            showingPrompt = false
            Wait(1000)
        end
    end
end)
