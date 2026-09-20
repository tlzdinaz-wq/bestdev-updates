---@meta _
---@diagnostic disable: duplicate-doc-field

-- TIG Weapon Restriction System
-- Empêche les joueurs d'utiliser des armes pendant un certain temps

local isWeaponRestricted = false
local restrictionEndTime = 0
local restrictionReason = ""

-- Liste des armes de mêlée autorisées (poings)
local allowedWeapons = {
    [`WEAPON_UNARMED`] = true,
}

-- Appliquer la restriction d'armes
RegisterNetEvent("vfw:tigweapon:apply", function(durationSeconds, reason)
    isWeaponRestricted = true
    restrictionEndTime = GetGameTimer() + (durationSeconds * 1000)
    restrictionReason = reason or "Restriction d'armes"

    -- Retirer toutes les armes actuelles et forcer le désarmement
    local playerPed = PlayerPedId()
    SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)

    -- Thread principal pour la restriction
    CreateThread(function()
        local lastNotifTime = 0

        while isWeaponRestricted do
            Wait(0)

            local currentTime = GetGameTimer()

            -- Vérifier si la restriction a expiré
            if currentTime >= restrictionEndTime then
                isWeaponRestricted = false
                VFW.ShowNotification({
                    type = 'VERT',
                    content = "Votre restriction d'armes est terminée"
                })
                break
            end

            local playerPed = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(playerPed)

            -- Si le joueur essaie de sortir une arme non autorisée
            if not allowedWeapons[currentWeapon] then
                -- Forcer le retour aux poings
                SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)

                -- Notification cooldown (toutes les 5 secondes max)
                if currentTime - lastNotifTime > 5000 then
                    lastNotifTime = currentTime
                    local remainingMinutes = math.ceil((restrictionEndTime - currentTime) / 60000)
                    VFW.ShowNotification({
                        type = 'ROUGE',
                        content = string.format("Vous ne pouvez pas utiliser d'armes. Temps restant: %d min", remainingMinutes)
                    })
                end
            end

            -- Désactiver les touches de changement d'arme
            DisableControlAction(0, 37, true)  -- Sélection d'arme (Tab)
            DisableControlAction(0, 157, true) -- Arme suivante
            DisableControlAction(0, 158, true) -- Arme précédente
            DisableControlAction(0, 160, true) -- Désarmer
            DisableControlAction(0, 164, true) -- Arme précédente
            DisableControlAction(0, 165, true) -- Arme suivante

            -- Empêcher de tirer
            DisablePlayerFiring(PlayerId(), true)
        end
    end)
end)

-- Retirer la restriction d'armes
RegisterNetEvent("vfw:tigweapon:remove", function()
    isWeaponRestricted = false
    restrictionEndTime = 0
    restrictionReason = ""
end)

-- Export pour vérifier si le joueur a une restriction
function IsWeaponRestricted()
    return isWeaponRestricted
end
exports('IsWeaponRestricted', IsWeaponRestricted)

-- Nettoyage à l'arrêt de la ressource
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    isWeaponRestricted = false
end)
