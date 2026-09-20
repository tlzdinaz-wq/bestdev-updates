---@meta _
---@diagnostic disable: duplicate-doc-field

LastWeaponId = nil
IsWeaponChanging = false
local _vehicleUnequippedHash = nil

local holsterAnimations = {
    default = {
        equip = { dict = "reaction@intimidation@1h", anim = "intro", blendIn = 8.0, blendOut = 3.0, duration = 1250, flag = 50, advanced = true, startPhase = 0.325 },
        unequip = { dict = "reaction@intimidation@1h", anim = "outro", blendIn = 8.0, blendOut = 3.0, duration = 1500, flag = 50, advanced = true, startPhase = 0.125 },
    },
    SideHolsterAnimation = {
        equip = {
            dict = "rcmjosh4", anim = "josh_leadout_cop2", blendIn = 8.0, blendOut = 2.0, duration = 400, flag = 48,
            pre = { dict = "reaction@intimidation@cop@unarmed", anim = "intro", blendIn = 8.0, blendOut = 2.0, duration = 100, flag = 50 }
        },
        unequip = {
            dict = "reaction@intimidation@cop@unarmed", anim = "outro", blendIn = 8.0, blendOut = 2.0, duration = 60, flag = 50,
            pre = { dict = "rcmjosh4", anim = "josh_leadout_cop2", blendIn = 8.0, blendOut = 2.0, duration = 500, flag = 48 }
        },
    },
    FrontHolsterAnimation = {
        equip = { dict = "combat@combat_reactions@pistol_1h_hillbilly", anim = "0", blendIn = 8.0, blendOut = 3.0, duration = 1000, flag = 50, advanced = true, startPhase = 0.325 },
        unequip = { dict = "combat@combat_reactions@pistol_1h_gang", anim = "0", blendIn = 8.0, blendOut = 3.0, duration = 1000, flag = 50, advanced = true, startPhase = 0.125 },
    },
    SideLegHolsterAnimation = {
        equip = { dict = "reaction@male_stand@big_variations@d", anim = "react_big_variations_m", blendIn = 8.0, blendOut = 3.0, duration = 800, flag = 50, advanced = true, startPhase = 0.325 },
        unequip = { dict = "reaction@male_stand@big_variations@d", anim = "react_big_variations_m", blendIn = 8.0, blendOut = 3.0, duration = 800, flag = 50, advanced = true, startPhase = 0.125 },
    },
    AbdomenHolsterAnimation = {
        equip = { dict = "combat@combat_reactions@pistol_1h_gang", anim = "0", blendIn = 8.0, blendOut = 3.0, duration = 1000, flag = 50, advanced = true, startPhase = 0.325 },
        unequip = { dict = "combat@combat_reactions@pistol_1h_gang", anim = "0", blendIn = 8.0, blendOut = 3.0, duration = 1000, flag = 50, advanced = true, startPhase = 0.125 },
    },
}

local labelToValue = {
    ["Par défaut"] = "default",
    ["Flic"] = "SideHolsterAnimation",
    ["Avant"] = "FrontHolsterAnimation",
    ["Jambe"] = "SideLegHolsterAnimation",
    ["Abdomen"] = "AbdomenHolsterAnimation",
}

local function GetHolsterStyle()
    local saved = GetResourceKvpString("holster_style_value")
    if saved and holsterAnimations[saved] then
        return saved
    end

    local label = GetResourceKvpString("holster_style_label")
    if label and labelToValue[label] and holsterAnimations[labelToValue[label]] then
        return labelToValue[label]
    end

    return "default"
end

local function PlayHolsterAnim(ped, animData)
    if animData.pre then
        VFW.Streaming.RequestAnimDict(animData.pre.dict)
        TaskPlayAnim(ped, animData.pre.dict, animData.pre.anim, animData.pre.blendIn, animData.pre.blendOut, -1, animData.pre.flag or 50, 2.0, 0, 0, 0)
        Wait(animData.pre.duration)
    end

    VFW.Streaming.RequestAnimDict(animData.dict)

    if animData.advanced then
        local coords = GetEntityCoords(ped, true)
        local rot = GetEntityHeading(ped)
        TaskPlayAnimAdvanced(ped, animData.dict, animData.anim, coords.x, coords.y, coords.z, 0.0, 0.0, rot, animData.blendIn, animData.blendOut, -1, animData.flag or 50, animData.startPhase or 0.0, 0, 0)
    else
        TaskPlayAnim(ped, animData.dict, animData.anim, animData.blendIn, animData.blendOut, -1, animData.flag or 48, 10, 0, 0, 0)
    end

    Wait(animData.duration)
    ClearPedTasks(ped)

    if animData.pre then
        RemoveAnimDict(animData.pre.dict)
    end
    RemoveAnimDict(animData.dict)
end

local function GetWeaponNotifData(weaponHash)
    local weaponData = VFW.GetWeaponFromHash(weaponHash)
    if weaponData and weaponData.name then
        local weaponName = string.lower(weaponData.name)
        if VFW.Items[weaponName] then
            weaponData.label = VFW.Items[weaponName].label
        end
        return weaponData
    end
    return { name = "unknown", label = "Arme" }
end

function VFW.WeaponAnim(id, ghost)
    if IsWeaponRestricted() then
        SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
        return
    end

    local ped = VFW.PlayerData.ped
    local inVehicle = IsPedSittingInAnyVehicle(ped, false)

    -- En véhicule : pas d'animation holster, notif directe
    if inVehicle then
        local isUnequip = (LastWeaponId ~= nil and LastWeaponId == id)

        if isUnequip then
            -- On range l'arme qu'on avait déjà en main
            for _, item in ipairs(VFW.PlayerData.inventory) do
                if item.meta and item.meta.weaponId == id then
                    local weaponName = string.lower(item.name)
                    local label = VFW.Items[weaponName] and VFW.Items[weaponName].label or item.name
                    _vehicleUnequippedHash = GetHashKey(item.name:upper())
                    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                    RemoveWeaponFromPed(ped, _vehicleUnequippedHash)
                    VFW.Nui.WeaponNotification(true, {
                        action = "unequip",
                        data = { name = weaponName, label = label },
                    })
                    break
                end
            end
            LastWeaponId = nil
        else
            -- On équipe une nouvelle arme
            if id then
                local found = false
                for _, item in ipairs(VFW.PlayerData.inventory) do
                    if item.meta and item.meta.weaponId == id then
                        local weaponName = string.lower(item.name)
                        local upperName = item.name:upper()
                        local label = VFW.Items[weaponName] and VFW.Items[weaponName].label or item.name

                        -- Vérifier si l'arme est autorisée en drive-by (pilote/passager)
                        local vehicle = GetVehiclePedIsIn(ped, false)
                        local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped
                        local drivebyAllowed = isDriver and (GlobalState.DrivebyAllowedDriver or {}) or (GlobalState.DrivebyAllowedPassenger or {})
                        if not drivebyAllowed[upperName] then
                            VFW.ShowNotification({ type = 'ROUGE', message = "Cette arme n'est pas autorisée en drive-by." })
                            local blockHash = GetHashKey(upperName)
                            -- Attendre que le serveur ait donné l'arme puis la retirer
                            local timeout = GetGameTimer() + 3000
                            while not HasPedGotWeapon(ped, blockHash, false) and GetGameTimer() < timeout do
                                Wait(50)
                            end
                            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                            RemoveWeaponFromPed(ped, blockHash)
                            return
                        end

                        local hash = GetHashKey(upperName)
                        -- Attendre que le serveur ait donné l'arme au ped
                        local timeout = GetGameTimer() + 3000
                        while not HasPedGotWeapon(ped, hash, false) and GetGameTimer() < timeout do
                            Wait(50)
                        end
                        SetCurrentPedWeapon(ped, hash, true)
                        Wait(100)
                        VFW.Nui.WeaponNotification(true, {
                            action = "equip",
                            data = { name = weaponName, label = label },
                        })
                        LastWeaponId = id
                        _vehicleUnequippedHash = nil
                        found = true
                        break
                    end
                end
            end
        end
        return
    end

    local weapon = GetSelectedPedWeapon(ped)
    local timer = GetGameTimer() + 10000
    CreateThread(function()
        IsWeaponChanging = true
        while GetGameTimer() < timer do
            DisablePlayerFiring(ped, true)
            Wait(0)
        end
        IsWeaponChanging = false
    end)

    local style = GetHolsterStyle()
    local anims = holsterAnimations[style]

    if weapon ~= `weapon_unarmed` then
        local oldWeapon = weapon

        PlayHolsterAnim(ped, anims.unequip)

        local newWeapon = GetSelectedPedWeapon(ped)

        if newWeapon ~= `weapon_unarmed` then
            PlayHolsterAnim(ped, anims.equip)

            VFW.Nui.WeaponNotification(true, {
                action = "unequip",
                data = GetWeaponNotifData(oldWeapon),
            })
            VFW.Nui.WeaponNotification(true, {
                action = "equip",
                data = GetWeaponNotifData(newWeapon),
            })
        else
            VFW.Nui.WeaponNotification(true, {
                action = "unequip",
                data = GetWeaponNotifData(oldWeapon),
            })
        end
    else
        PlayHolsterAnim(ped, anims.equip)

        weapon = GetSelectedPedWeapon(ped)
        VFW.Nui.WeaponNotification(true, {
            action = "equip",
            data = GetWeaponNotifData(weapon),
        })
    end

    timer = GetGameTimer() + 1250

    if IsPedArmed(ped, 4) then
        LastWeaponId = id
        if not ghost then
            VFW.CloseInventory()
        end
    else
        LastWeaponId = nil
    end
end

RegisterNetEvent("vfw:weaponChange", VFW.WeaponAnim)

-- Surveiller la sortie de véhicule pour retirer l'arme rangée en véhicule
-- + vérifier le drive-by quand on entre avec une arme en main
CreateThread(function()
    local wasInVehicle = false
    while true do
        local ped = PlayerPedId()
        local inVehicle = IsPedSittingInAnyVehicle(ped, false)

        if wasInVehicle and not inVehicle and _vehicleUnequippedHash then
            Wait(200)
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
            RemoveWeaponFromPed(ped, _vehicleUnequippedHash)
            _vehicleUnequippedHash = nil
        end

        -- Entré en véhicule avec une arme en main : vérifier drive-by (pilote/passager)
        if not wasInVehicle and inVehicle then
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= `WEAPON_UNARMED` then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped
                local drivebyAllowed = isDriver and (GlobalState.DrivebyAllowedDriver or {}) or (GlobalState.DrivebyAllowedPassenger or {})
                local weaponName = nil
                for _, item in ipairs(VFW.PlayerData.inventory) do
                    if item.meta and item.meta.weaponId and GetHashKey(item.name:upper()) == weapon then
                        weaponName = item.name:upper()
                        break
                    end
                end
                if weaponName and not drivebyAllowed[weaponName] then
                    VFW.ShowNotification({ type = 'ROUGE', message = "Cette arme n'est pas autorisée en drive-by." })
                    local clip = VFW.GetReliableClipAmmo(ped, weapon)
                    TriggerServerEvent("vfw:weapon:saveAmmoState", weapon, clip)
                    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                    RemoveWeaponFromPed(ped, weapon)
                    LastWeaponId = nil
                end
            end
        end

        wasInVehicle = inVehicle
        Wait(inVehicle and 200 or 1000)
    end
end)
