---@meta _
---@diagnostic disable: duplicate-doc-field

local hasWeapon = false
local sendNotif = false
local EXCLUDED_WEAPONS = {
    [joaat("WEAPON_UNARMED")] = true,
    [joaat("weapon_petrolcan")] = true,
    [joaat("weapon_hose")] = true,
    [joaat("weapon_fireextinguisher")] = true,
    [joaat("weapon_fakemachinepistol")] = true,
    [joaat("weapon_stungun")] = true,
    [joaat("weapon_gtaserx")] = true,
    [joaat("weapon_taserx")] = true,
    [joaat("weapon_pepperspray")] = true,
    [joaat("weapon_aspbaton")] = true,
    [joaat("weapon_fakepistol")] = true,
    [joaat("weapon_fakecombatpistol")] = true,
    [joaat("weapon_fakespecialcarbine")] = true,
    [joaat("weapon_fakesmg")] = true,
    [joaat("weapon_fakeshotgun")] = true,
    [joaat("weapon_fakeminismg")] = true,
    [joaat("weapon_fakemicrosmg")] = true,
    [joaat("weapon_fakeak")] = true,
    [joaat("weapon_fakeaku")] = true,
    [joaat("weapon_fakem4")] = true,
    [joaat("weapon_laser")] = true,
    [joaat("weapon_paintball")] = true,
    [joaat("weapon_flare")] = true,
}

VFW.LastFireTime = 0

local weaponHash = {}

for key, value in pairs(Config.Weapons) do
    weaponHash[joaat(value.name)] = value.name:lower()
end

CreateThread(function()
    while true do
        local ped = VFW.PlayerData.ped
        local _, hash = GetCurrentPedWeapon(ped)
        hasWeapon = false

        if hash ~= 0 and hash ~= joaat("WEAPON_UNARMED") then
            hasWeapon = true

            if EXCLUDED_WEAPONS[hash] then
                goto continue
            end

            if VFW.PlayerData.job.type == "faction" and VFW.PlayerData.job.onDuty then
                goto continue
            end

            if IsPedShooting(ped) and not sendNotif then
                local instance = TriggerServerCallback("core:CheckInstance")

                if instance then
                    VFW.LastFireTime = GetGameTimer()
                    sendNotif = true
                    local pos = GetEntityCoords(ped)
                    for jobName in pairs(PoliceJobsList or {}) do
                        TriggerServerEvent('core:alert:makeCall', jobName, vector3(pos.x, pos.y, pos.z), true, "Coup de feu", false, "weapon")
                    end
                    TriggerServerEvent('core:logs:shooting', weaponHash[hash], pos)
                    TriggerServerEvent('core:testPoudre')
                    Wait(30000)
                    sendNotif = false
                end
            end

            ::continue::
        end

        if hasWeapon then
            Wait(30)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    local extinguisherHash = joaat("WEAPON_FIREEXTINGUISHER")
    while true do
        local ped = PlayerPedId()
        local _, hash = GetCurrentPedWeapon(ped)

        if hash == extinguisherHash then
            SetPedInfiniteAmmo(ped, true, extinguisherHash)
            SetPedInfiniteAmmoClip(ped, true)
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

