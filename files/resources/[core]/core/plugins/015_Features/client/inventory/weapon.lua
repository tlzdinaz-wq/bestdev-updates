---@meta _
---@diagnostic disable: duplicate-doc-field

local noAmmoNotifiedWeapon = nil

local petrolCanHash = joaat("weapon_petrolcan")
local fireExtinguisherHash = joaat("weapon_fireextinguisher")

local wasShooting = false
local lastEquippedWeapon = nil
local weaponJustEquipped = false
local skipReserveSync = false
local blockReload = false
local pendingEquipAmmo = nil
local lastKnownAmmo = nil
local forcedRemovalAmmo = nil
local reloadingTo = nil

-- Push périodique de l'ammo : sans ça, une déco brutale perd les balles du dernier clip
-- (le SaveWeaponAmmoState serveur query un client déjà parti).
local lastPeriodicAmmoSave = 0
local lastPeriodicAmmoSaved = nil
local AMMO_PERIODIC_SAVE_MS = 5000

-- Lecture fiable du clip : couvre les zéros transitoires (holster, task change),
-- les reloads en cours, et la désync du chargeur étendu (balles en fausse réserve).
function VFW.GetReliableClipAmmo(ped, hash)
    if reloadingTo and reloadingTo.hash == hash then
        return reloadingTo.ammo
    end
    local _, clip = GetAmmoInClip(ped, hash)
    clip = clip or 0
    if clip == 0 and lastKnownAmmo and lastKnownAmmo.hash == hash and lastKnownAmmo.ammo > 0 then
        return lastKnownAmmo.ammo
    end

    local total = GetAmmoInPedWeapon(ped, hash) or 0
    local maxClip = (VFW.GetReliableMaxClip and VFW.GetReliableMaxClip(ped, hash)) or 0
    local effective = clip
    if maxClip > 0 and total > effective and total <= maxClip then
        effective = total
    end

    -- Filet : si GTA a transitoirement dissous la fausse réserve, lastKnownAmmo a la bonne valeur.
    if lastKnownAmmo and lastKnownAmmo.hash == hash and lastKnownAmmo.ammo > effective then
        if not maxClip or maxClip <= 0 or lastKnownAmmo.ammo <= maxClip then
            effective = lastKnownAmmo.ammo
        end
    end

    return effective
end

-- Cache de la capacité haute par arme : GetMaxAmmoInClip peut retomber à la capacité de base
-- pendant la désync du composant chargeur étendu, on garde le max observé.
local knownMaxClips = {}

-- Liste des composants attachés par arme : GTA détache silencieusement après MakePedReload,
-- il faut pouvoir les ré-attacher pour que SetAmmoInClip(>capacité de base) tienne.
local attachedComponents = {}

-- Ré-attache sans tester HasPedGotWeaponComponent (false-positive après MakePedReload).
local function reattachComponents(ped, weaponHash)
    local list = attachedComponents[weaponHash]
    if not list then return false end
    for _, compHash in ipairs(list) do
        GiveWeaponComponentToPed(ped, weaponHash, compHash)
    end
    return true
end

-- Force le clip = total en ré-attachant les composants. Exposé pour +useAmmo.
function VFW.ResyncExtendedClip(ped, weaponHash)
    if not ped or not weaponHash then return false end
    local total = GetAmmoInPedWeapon(ped, weaponHash) or 0
    local _, clip = GetAmmoInClip(ped, weaponHash)
    clip = clip or 0
    local targetMax = (VFW.GetReliableMaxClip and VFW.GetReliableMaxClip(ped, weaponHash)) or 0
    if targetMax <= 0 or total <= clip or total > targetMax then return false end
    reattachComponents(ped, weaponHash)
    SetAmmoInClip(ped, weaponHash, total)
    SetPedAmmo(ped, weaponHash, total)
    return true
end

local function setKnownMaxClip(hash, value)
    if type(hash) ~= "number" or type(value) ~= "number" or value <= 0 then return end
    local previous = knownMaxClips[hash]
    if not previous or value >= previous then
        knownMaxClips[hash] = value
    end
end

-- Observe GetMaxAmmoInClip plusieurs fois et garde le max ; attend la valeur cible si fournie.
-- Sans ça, une lecture trop précoce après l'attache du composant retourne la capacité de base.
local function observeMaxClipReliably(ped, weaponHash, target)
    local observed = 0
    local attempts = target and 30 or 5
    for attempt = 1, attempts do
        local v = GetMaxAmmoInClip(ped, weaponHash, true) or 0
        if v > observed then observed = v end
        if target and observed >= target then break end
        if attempt < attempts then Wait(50) end
    end
    return observed
end

-- Restart core : nos caches sont vidés, on demande au serveur de rejouer applyEquipComponents
-- pour ré-attacher les composants et reposer le clip avec la vraie capacité.
AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        local timeout = 0
        while (not VFW or not VFW.PlayerData or not VFW.PlayerData.ped) and timeout < 100 do
            Wait(100)
            timeout = timeout + 1
        end
        if VFW and VFW.PlayerData then
            TriggerServerEvent("vfw:weapon:requestEquippedSync")
        end
    end)
end)

-- Bloque INPUT_RELOAD (45) quand le clip effectif est plein : sinon l'anim
-- fantôme se joue pendant la désync du chargeur étendu (engine voit clip<max).
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        if weapon and weapon ~= `weapon_unarmed` and IsPedArmed(ped, 4) then
            local _, clip = GetAmmoInClip(ped, weapon)
            clip = clip or 0
            local total = GetAmmoInPedWeapon(ped, weapon) or 0
            local maxClip = (VFW.GetReliableMaxClip and VFW.GetReliableMaxClip(ped, weapon)) or 0
            if maxClip > 0 then
                local effective = math.max(clip, math.min(total, maxClip))
                if effective >= maxClip then
                    DisableControlAction(0, 45, true)
                end
            end
        end
        Wait(0)
    end
end)

function VFW.GetReliableMaxClip(ped, hash)
    local engine = GetMaxAmmoInClip(ped, hash, true) or 0
    local cached = knownMaxClips[hash]
    if cached and (engine <= 0 or engine < cached) then
        return cached
    end
    if engine > 0 then
        knownMaxClips[hash] = engine
    end
    return engine
end

CreateThread(function()
    while true do
        local weapon = GetSelectedPedWeapon(VFW.PlayerData.ped)

        if weapon ~= `weapon_unarmed` then
            local ped = PlayerPedId()

            local restoredAmmo = nil

            if weapon ~= lastEquippedWeapon then
                lastEquippedWeapon = weapon
                weaponJustEquipped = true

                if forcedRemovalAmmo and weapon == forcedRemovalAmmo.hash then
                    SetPedAmmo(ped, weapon, forcedRemovalAmmo.ammo)
                    SetAmmoInClip(ped, weapon, forcedRemovalAmmo.ammo)
                    restoredAmmo = forcedRemovalAmmo.ammo
                end
                forcedRemovalAmmo = nil

                SetTimeout(1000, function()
                    weaponJustEquipped = false
                end)
            end

            local isShooting = IsPedShooting(ped) and weapon ~= petrolCanHash and weapon ~= fireExtinguisherHash

            if isShooting and not wasShooting then
                local weaponData = VFW.GetWeaponFromHash(weapon)

                if weaponData and weaponData.throwable then
                    TriggerServerEvent("vfw:weapon:used", weapon)
                end

                if IsPedArmed(ped, 4) then
                    VFW.TriggerDouille(weapon)
                end
            end

            if not blockReload and not isShooting and IsControlJustPressed(0, 24) and IsPedArmed(ped, 4) then
                local _, clip = GetAmmoInClip(ped, weapon)
                if clip <= 0 then
                    TriggerServerEvent("vfw:weapon:reload", weapon)
                end
            end

            -- Filet de sécurité R (control 45) : si le keymapping +useAmmo échoue
            -- (ammoType manquant, focus NUI, etc.), on tente le reload serveur
            -- dès que le clip engine n'est pas plein (toutes armes, pas seulement lanceurs).
            if not blockReload and not isShooting and (IsControlJustPressed(0, 45) or IsDisabledControlJustPressed(0, 45)) and IsPedArmed(ped, 4) then
                local maxClip = (VFW.GetReliableMaxClip and VFW.GetReliableMaxClip(ped, weapon))
                    or GetMaxAmmoInClip(ped, weapon, true)
                    or 0
                local _, clip = GetAmmoInClip(ped, weapon)
                clip = clip or 0
                if maxClip <= 1 then
                    if clip <= 0 then
                        TriggerServerEvent("vfw:weapon:reload", weapon)
                    end
                elseif clip < maxClip then
                    TriggerServerEvent("vfw:weapon:reload", weapon)
                end
            end

            wasShooting = isShooting

            local _, currentClip = GetAmmoInClip(ped, weapon)

            if restoredAmmo then
                currentClip = restoredAmmo
            elseif pendingEquipAmmo and weapon == pendingEquipAmmo.hash then
                SetPedAmmo(ped, weapon, pendingEquipAmmo.ammo)
                SetAmmoInClip(ped, weapon, pendingEquipAmmo.ammo)
                currentClip = pendingEquipAmmo.ammo
                pendingEquipAmmo = nil
            elseif not skipReserveSync and not blockReload and not weaponJustEquipped and weapon ~= petrolCanHash and weapon ~= fireExtinguisherHash then
                local total = GetAmmoInPedWeapon(ped, weapon)
                local targetMax = (VFW.GetReliableMaxClip and VFW.GetReliableMaxClip(ped, weapon)) or 0
                if targetMax > 0 and total > currentClip and total <= targetMax then
                    -- Chargeur étendu désynchronisé (GTA a déplacé l'excédent en fausse réserve) : ré-attache + repose tout dans le clip.
                    reattachComponents(ped, weapon)
                    SetAmmoInClip(ped, weapon, total)
                    SetPedAmmo(ped, weapon, total)
                    currentClip = total
                elseif total > currentClip and currentClip > 0 and (targetMax <= 0 or total > targetMax) then
                    SetPedAmmo(ped, weapon, currentClip)
                end
            end

            if not blockReload and weapon ~= petrolCanHash and weapon ~= fireExtinguisherHash then
                if reloadingTo and reloadingTo.hash == weapon then
                    lastKnownAmmo = { hash = weapon, ammo = reloadingTo.ammo }
                else
                    -- Toujours sauver l'effectif (clip + fausse réserve), sinon le save périodique persiste la valeur truncate.
                    local effectiveClip = currentClip or 0
                    local totalForEff = GetAmmoInPedWeapon(ped, weapon) or 0
                    local maxForEff = (VFW.GetReliableMaxClip and VFW.GetReliableMaxClip(ped, weapon)) or 0
                    if maxForEff > 0 and totalForEff > effectiveClip and totalForEff <= maxForEff then
                        effectiveClip = totalForEff
                    end

                    local prevAmmo = lastKnownAmmo and lastKnownAmmo.hash == weapon and lastKnownAmmo.ammo or nil
                    local transientDrop = effectiveClip == 0 and prevAmmo and prevAmmo > 0 and not isShooting
                    if not transientDrop then
                        lastKnownAmmo = { hash = weapon, ammo = effectiveClip }
                    end
                end
            end

            -- Push périodique throttled à 5s : protège contre déco inattendue (kick, crash, alt-F4).
            if lastKnownAmmo then
                local now = GetGameTimer()
                if (now - lastPeriodicAmmoSave) >= AMMO_PERIODIC_SAVE_MS then
                    local changed = not lastPeriodicAmmoSaved
                        or lastPeriodicAmmoSaved.hash ~= lastKnownAmmo.hash
                        or lastPeriodicAmmoSaved.ammo ~= lastKnownAmmo.ammo
                    if changed then
                        TriggerServerEvent("vfw:weapon:saveAmmoState", lastKnownAmmo.hash, lastKnownAmmo.ammo)
                        lastPeriodicAmmoSaved = { hash = lastKnownAmmo.hash, ammo = lastKnownAmmo.ammo }
                    end
                    lastPeriodicAmmoSave = now
                end
            end

            Wait(0)
        else
            if lastKnownAmmo and not IsWeaponChanging then
                TriggerServerEvent("vfw:weapon:saveAmmoState", lastKnownAmmo.hash, lastKnownAmmo.ammo)
                forcedRemovalAmmo = lastKnownAmmo
            end
            lastKnownAmmo = nil
            lastEquippedWeapon = nil
            weaponJustEquipped = false
            wasShooting = false
            noAmmoNotifiedWeapon = nil
            Wait(200)
        end
    end
end)

RegisterNetEvent("vfw:weapon:setEquipAmmo", function(weaponHash, ammo)
    pendingEquipAmmo = { hash = weaponHash, ammo = ammo }
    if ammo and ammo > 0 then
        -- Verrouille la cible pendant la fenêtre d'équipement (sinon le clip de base écrase lastKnownAmmo).
        reloadingTo = { hash = weaponHash, ammo = ammo }
        lastKnownAmmo = { hash = weaponHash, ammo = ammo }
    end
end)

RegisterNetEvent("vfw:weapon:applyEquipComponents", function(weaponHash, components, tint, ammo)
    CreateThread(function()
        local ped = PlayerPedId()
        local timeout = 0
        while not HasPedGotWeapon(ped, weaponHash, false) and timeout < 100 do
            Wait(50)
            timeout = timeout + 1
        end

        local hashedComponents = {}
        if components then
            for _, component in ipairs(components) do
                local compHash = type(component) == "string" and GetHashKey(component) or component
                local compModel = GetWeaponComponentTypeModel(compHash)
                if compModel and compModel ~= 0 then
                    RequestModel(compModel)
                    local loadTimeout = 0
                    while not HasModelLoaded(compModel) and loadTimeout < 100 do
                        Wait(50)
                        loadTimeout = loadTimeout + 1
                    end
                end
                GiveWeaponComponentToPed(ped, weaponHash, compHash)
                hashedComponents[#hashedComponents + 1] = compHash
            end
        end
        attachedComponents[weaponHash] = hashedComponents

        if tint then
            SetPedWeaponTintIndex(ped, weaponHash, tint)
        end

        if ammo and ammo > 0 then
            -- Attend que l'engine reconnaisse la capacité du chargeur étendu avant le SetAmmoInClip.
            local maxClip = observeMaxClipReliably(ped, weaponHash, ammo)
            if maxClip <= 0 then maxClip = ammo end
            if ammo > maxClip then
                maxClip = ammo
            end
            local clipAmmo = math.min(ammo, maxClip)
            SetPedAmmo(ped, weaponHash, ammo)
            SetAmmoInClip(ped, weaponHash, clipAmmo)
            -- Verify + retry : race interne GTA peut clamp le clip à la frame suivante.
            Wait(0)
            local _, postSetClip = GetAmmoInClip(ped, weaponHash)
            if (postSetClip or 0) < clipAmmo then
                reattachComponents(ped, weaponHash)
                Wait(50)
                SetAmmoInClip(ped, weaponHash, clipAmmo)
                SetPedAmmo(ped, weaponHash, ammo)
            end
            lastKnownAmmo = { hash = weaponHash, ammo = clipAmmo }

            -- Remonte la vraie capacité au serveur (source de vérité pour le reload).
            if maxClip and maxClip > 0 then
                setKnownMaxClip(weaponHash, maxClip)
                TriggerServerEvent("vfw:weapon:reportMaxClip", weaponHash, maxClip)
            end

            -- Watchdog : couvre la fenêtre où GTA peut re-clamp le clip après l'attache.
            CreateThread(function()
                for _ = 1, 10 do
                    Wait(150)
                    local currentPed = PlayerPedId()
                    if GetSelectedPedWeapon(currentPed) ~= weaponHash then return end
                    local _, curClip = GetAmmoInClip(currentPed, weaponHash)
                    local curTotal = GetAmmoInPedWeapon(currentPed, weaponHash) or 0
                    if curTotal > (curClip or 0) and curTotal <= clipAmmo then
                        reattachComponents(currentPed, weaponHash)
                        SetAmmoInClip(currentPed, weaponHash, curTotal)
                        SetPedAmmo(currentPed, weaponHash, curTotal)
                    end
                end
            end)

            if reloadingTo and reloadingTo.hash == weaponHash then
                reloadingTo = nil
            end
        else
            -- Arme équipée vide : remonte quand même le maxClip.
            local maxClip = observeMaxClipReliably(ped, weaponHash)
            if maxClip > 0 then
                setKnownMaxClip(weaponHash, maxClip)
                TriggerServerEvent("vfw:weapon:reportMaxClip", weaponHash, maxClip)
            end

            if reloadingTo and reloadingTo.hash == weaponHash then
                reloadingTo = nil
            end
        end
    end)
end)

-- Resync du maxClip serveur quand un composant change (extended ↔ standard).
RegisterNetEvent("vfw:weapon:componentUpdated", function(_, components)
    CreateThread(function()
        Wait(150)
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        if weapon and weapon ~= `weapon_unarmed` then
            -- Le maxClip peut descendre (extended → standard) : on reset le cache avant de relire.
            knownMaxClips[weapon] = nil

            -- Maj la liste des composants cachés pour ré-attacher après MakePedReload.
            if components then
                local hashed = {}
                for _, component in ipairs(components) do
                    hashed[#hashed + 1] = type(component) == "string" and GetHashKey(component) or component
                end
                attachedComponents[weapon] = hashed
            end

            -- Plusieurs lectures pour capturer la vraie capacité avant de la remonter au serveur.
            local maxClip = observeMaxClipReliably(ped, weapon)
            if maxClip > 0 then
                setKnownMaxClip(weapon, maxClip)
                TriggerServerEvent("vfw:weapon:reportMaxClip", weapon, maxClip)
            end
        end
    end)
end)

RegisterNetEvent("vfw:weapon:addAmmo", function(weaponHash, amount, serverMaxClip)
    skipReserveSync = true
    local ped = PlayerPedId()
    local _, currentClip = GetAmmoInClip(ped, weaponHash)
    -- serverMaxClip est la source de vérité (meta.maxClip), plus fiable que GetMaxAmmoInClip.
    local engineMaxClip = GetMaxAmmoInClip(ped, weaponHash, true) or 0
    local maxClip = (type(serverMaxClip) == "number" and serverMaxClip > 0 and serverMaxClip)
                    or (engineMaxClip > 0 and engineMaxClip)
                    or 30
    setKnownMaxClip(weaponHash, maxClip)
    local newClip = math.min(currentClip + amount, maxClip)

    -- Verrouille la cible : range/change d'arme pendant l'anim ne doit pas sauver le clip transitoire.
    reloadingTo = { hash = weaponHash, ammo = newClip }
    lastKnownAmmo = { hash = weaponHash, ammo = newClip }

    if maxClip <= 1 then
        -- Single-shot (RPG, Homing, Railgun, Firework, 40mm, etc.)
        -- On donne des munitions en réserve pour que MakePedReload joue l'animation
        SetPedAmmo(ped, weaponHash, newClip + 1)
        MakePedReload(ped)
        Wait(2500)
        reattachComponents(ped, weaponHash)
        Wait(50)
        SetAmmoInClip(ped, weaponHash, newClip)
        SetPedAmmo(ped, weaponHash, newClip)
    else
        SetPedAmmo(ped, weaponHash, newClip)
        MakePedReload(ped)
        Wait(2500)
        reattachComponents(ped, weaponHash)
        -- Frame d'attente pour que les composants ré-attachés soient pris en compte avant le SetAmmoInClip.
        Wait(50)
        SetAmmoInClip(ped, weaponHash, newClip)
        SetPedAmmo(ped, weaponHash, newClip)

        -- Verify + retry : couvre le cas où GiveWeaponComponentToPed n'a pas été enregistré à temps.
        local _, verifyClip = GetAmmoInClip(ped, weaponHash)
        if verifyClip < newClip then
            for _, compHash in ipairs(attachedComponents[weaponHash] or {}) do
                GiveWeaponComponentToPed(ped, weaponHash, compHash)
            end
            Wait(100)
            SetAmmoInClip(ped, weaponHash, newClip)
            SetPedAmmo(ped, weaponHash, newClip)
        end
    end

    lastKnownAmmo = { hash = weaponHash, ammo = newClip }
    reloadingTo = nil
    skipReserveSync = false
end)

RegisterNetEvent("vfw:weapon:reloadDenied", function(reason)
    if reason == "no_ammo" then
        local weapon = GetSelectedPedWeapon(VFW.PlayerData.ped)
        if noAmmoNotifiedWeapon ~= weapon then
            noAmmoNotifiedWeapon = weapon
            VFW.ShowNotification({ type = "ROUGE", content = "Vous n'avez plus de munitions." })
        end
    end
end)

CreateThread(function()
    local wasClimbing = false
    local climbAmmo = nil
    local restoreTicks = 0
    local restoreSaved = nil
    while true do
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        local armed = weapon ~= `weapon_unarmed`

        if armed then
            local visuallyHolstered = (not IsPedArmed(ped, 7)) and not IsWeaponChanging
            local isClimbing = IsPedClimbing(ped) or IsPedVaulting(ped) or GetIsTaskActive(ped, 47) or GetIsTaskActive(ped, 160) or visuallyHolstered

            if isClimbing and not wasClimbing then
                restoreTicks = 0
                restoreSaved = nil

                local _, clip = GetAmmoInClip(ped, weapon)
                if clip == 0 and lastKnownAmmo and lastKnownAmmo.hash == weapon and lastKnownAmmo.ammo > 0 then
                    clip = lastKnownAmmo.ammo
                end
                climbAmmo = { hash = weapon, ammo = clip }
                blockReload = true
            elseif not isClimbing and wasClimbing and climbAmmo then
                restoreSaved = climbAmmo
                restoreTicks = 60
                climbAmmo = nil
            end

            if restoreTicks > 0 and restoreSaved then
                if weapon == restoreSaved.hash then
                    SetPedAmmo(ped, restoreSaved.hash, restoreSaved.ammo)
                    SetAmmoInClip(ped, restoreSaved.hash, restoreSaved.ammo)
                end
                restoreTicks = restoreTicks - 1
                if restoreTicks == 0 then
                    lastKnownAmmo = { hash = restoreSaved.hash, ammo = restoreSaved.ammo }
                    restoreSaved = nil
                    blockReload = false
                end
            end

            if blockReload then
                DisableControlAction(0, 45, true)
                local _, clip = GetAmmoInClip(ped, weapon)
                if clip <= 0 then
                    DisableControlAction(0, 24, true)
                end
            end

            wasClimbing = isClimbing
            Wait(0)
        else
            if wasClimbing and climbAmmo then
                forcedRemovalAmmo = climbAmmo
                climbAmmo = nil
            end
            wasClimbing = false
            blockReload = false
            restoreTicks = 0
            restoreSaved = nil
            Wait(500)
        end
    end
end)

AddEventHandler("vfw:onPlayerDeath", function()
    local ped = VFW.PlayerData.ped
    local weapon = GetSelectedPedWeapon(ped)
    if weapon and weapon ~= `weapon_unarmed` then
        local ammo = VFW.GetReliableClipAmmo(ped, weapon)
        TriggerServerEvent("vfw:weapon:saveAmmoState", weapon, ammo)
    end
    lastKnownAmmo = nil
end)

-- KO : snapshot avant que le ragdoll fasse retomber le clip à la capacité de base,
-- puis neutralise lastKnownAmmo pour empêcher les saves suivants de corrompre la valeur.
AddEventHandler("vfw:startko", function()
    local ped = VFW.PlayerData.ped or PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon and weapon ~= `weapon_unarmed` then
        local ammo = VFW.GetReliableClipAmmo(ped, weapon)
        TriggerServerEvent("vfw:weapon:saveAmmoState", weapon, ammo)
        forcedRemovalAmmo = { hash = weapon, ammo = ammo }
    end
    lastKnownAmmo = nil
    reloadingTo = nil
    pendingEquipAmmo = nil
end)

-- Sync périodique : sur déco brutale le serveur ne peut plus interroger le client.
CreateThread(function()
    local lastSynced = nil
    while true do
        Wait(3000)
        if lastKnownAmmo and lastKnownAmmo.ammo and lastKnownAmmo.ammo >= 0 then
            local changed = not lastSynced or lastSynced.hash ~= lastKnownAmmo.hash or lastSynced.ammo ~= lastKnownAmmo.ammo
            if changed then
                TriggerServerEvent("vfw:weapon:saveAmmoState", lastKnownAmmo.hash, lastKnownAmmo.ammo)
                lastSynced = { hash = lastKnownAmmo.hash, ammo = lastKnownAmmo.ammo }
            end
        end
    end
end)
