---@meta _
---@diagnostic disable: duplicate-doc-field

local speconmod = false
local targetped
local targetServerId = nil
local spectateReturnPos = nil
local inNoClip = false
local noclipVehicle = nil -- Véhicule en noclip

-- Debug noclip: activable à chaud via `setr noclipDebug 1` côté client console
-- (F8) ou via convar. Évite le spam quand désactivé (relu chaque seconde).
local NOCLIP_DEBUG = false
local lastDebugCheck = 0
local function nclog(fmt, ...)
    local now = GetGameTimer()
    if (now - lastDebugCheck) > 1000 then
        NOCLIP_DEBUG = GetConvarInt("noclipDebug", 0) == 1
        lastDebugCheck = now
    end
    if not NOCLIP_DEBUG then return end
    local ok, msg = pcall(string.format, fmt, ...)
    print("[NOCLIP] " .. (ok and msg or fmt))
end
-- Charger la préférence du crosshair depuis le KVP (par défaut: activé)
local savedCrosshair = GetResourceKvpString("noclip_crosshair")
local toggleCrosshair = savedCrosshair ~= "false"
local INPUT_LOOK_LR = 1
local INPUT_LOOK_UD = 2


local function GetServerIdFromPed(ped)
    local playerId = NetworkGetPlayerIndexFromPed(ped)
    if playerId ~= -1 then
        local serverId = GetPlayerServerId(playerId)
        if serverId > 0 then return serverId end
    end
    for _, pid in ipairs(GetActivePlayers()) do
        if GetPlayerPed(pid) == ped then
            return GetPlayerServerId(pid)
        end
    end
    return 0
end

local settings = {
    mouseSensitivityX = 5,
    mouseSensitivityY = 5,
}

-- Sync véhicule noclip: les autres clients cachent le véhicule
AddStateBagChangeHandler('noclipHidden', nil, function(bagName, key, value)
    local netIdStr = bagName:gsub('entity:', '')
    local netId = tonumber(netIdStr)
    if not netId then return end

    CreateThread(function()
        Wait(0)
        local veh = NetworkGetEntityFromNetworkId(netId)
        if not veh or veh == 0 or not DoesEntityExist(veh) then return end

        -- Ne pas appliquer sur notre propre véhicule en noclip
        if inNoClip and noclipVehicle == veh then return end

        if value then
            SetEntityAlpha(veh, 0, false)
        else
            ResetEntityAlpha(veh)
        end
    end)
end)

-- Sync ped noclip : SetEntityVisible/Alpha sur le ped local ne fiabilise pas le
-- rendu de l'arme dans le dos côté autres clients (rendu hors entité). On force
-- alpha 0 sur le ped via state bag → cache TOUT (ped + arme rendue dessus).
AddStateBagChangeHandler('noclipPed', nil, function(bagName, key, value)
    local netIdStr = bagName:gsub('entity:', '')
    local netId = tonumber(netIdStr)
    if not netId then return end

    CreateThread(function()
        Wait(0)
        local ped = NetworkGetEntityFromNetworkId(netId)
        if not ped or ped == 0 or not DoesEntityExist(ped) then return end

        -- Ne pas appliquer sur soi-même : on garde SetEntityLocallyVisible
        if ped == PlayerPedId() then return end

        if value then
            SetEntityAlpha(ped, 0, false)
        else
            ResetEntityAlpha(ped)
        end
    end)
end)


-- Sync ped spectate (statebag): un staff en spectate a son ped déplacé/invisible
-- côté serveur, mais il reste "présent" pour VFW.GetPlayersInArea. On expose un
-- statebag `spectatePed` pour que les sélecteurs (VFW.StartSelect, etc.) puissent
-- l'exclure. Polling 500ms suffit (transitions de spectate sont rares).
CreateThread(function()
    local lastState = false
    while true do
        Wait(500)
        local current = NetworkIsInSpectatorMode()
        if current ~= lastState then
            local ped = PlayerPedId()
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                Entity(ped).state:set('spectatePed', current or nil, true)
            end
            lastState = current
        end
    end
end)


local idInstructionalButtons = {
    [1] = generateUniqueID(),
    [2] = generateUniqueID(),
    [3] = generateUniqueID()
}

local crosshairOverlayShown = false

local function SetCrosshairOverlay(state)
    if crosshairOverlayShown == state then return end
    crosshairOverlayShown = state
    SendNUIMessage({ action = state and "hud:crosshair:show" or "hud:crosshair:hide", data = {} })
end

---Set NoClipAttributes
---@param ped number Ped handle
---@param veh any
---@param status any
local function GetAttachedEntities(ped)
    local result = {}
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        nclog("GetAttachedEntities: ped invalide (%s)", tostring(ped))
        return result
    end
    local objPool = GetGamePool('CObject')
    local pedPool = GetGamePool('CPed')
    nclog("GetAttachedEntities: scan CObject=%d CPed=%d (ped=%s)", #objPool, #pedPool, tostring(ped))
    for i, obj in ipairs(objPool) do
        if obj ~= 0 and DoesEntityExist(obj) then
            local ok, attached = pcall(IsEntityAttachedToEntity, obj, ped)
            if not ok then
                nclog("GetAttachedEntities: pcall FAIL on CObject[%d]=%s err=%s", i, tostring(obj), tostring(attached))
            elseif attached then
                result[#result + 1] = obj
            end
        end
    end
    for i, p in ipairs(pedPool) do
        if p ~= ped and p ~= 0 and DoesEntityExist(p) then
            local ok, attached = pcall(IsEntityAttachedToEntity, p, ped)
            if not ok then
                nclog("GetAttachedEntities: pcall FAIL on CPed[%d]=%s err=%s", i, tostring(p), tostring(attached))
            elseif attached then
                result[#result + 1] = p
            end
        end
    end
    nclog("GetAttachedEntities: %d entités attachées", #result)
    return result
end

-- Debounce: GetGamePool + IsEntityAttachedToEntity sur des entités en cours de
-- streaming (approche rapide en noclip d'un autre joueur) cause des crashs natifs.
local lastAttachedScan = 0
local cachedAttachedEntities = {}

-- Throttle re-apply des natives de visu (alpha/visible) : pas besoin chaque frame,
-- une fois caché l'entité le reste tant qu'aucune task ne reset.
local NOCLIP_VISUALS_INTERVAL = 250
local lastVisualsMaintain = 0

-- Track persistant (par netId) de toutes les entités qu'on a cachées pendant
-- le noclip. Sans ça, une entité détachée du staff avant le toggle off
-- (joueur porté lâché, véhicule quitté, etc.) restait invisible pour les
-- autres clients parce que RestoreNoclipVisuals ne re-scan que ce qui est
-- ENCORE attaché. On garde l'historique pour pouvoir tout restaurer.
local noclipHiddenNetIds = {}

local function TrackHiddenEntity(ent)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return end
    if not NetworkGetEntityIsNetworked(ent) then return end
    local netId = NetworkGetNetworkIdFromEntity(ent)
    if netId and netId ~= 0 then
        noclipHiddenNetIds[netId] = true
    end
end

local function RestoreTrackedHiddenEntities()
    for netId, _ in pairs(noclipHiddenNetIds) do
        local ent = NetworkGetEntityFromNetworkId(netId)
        if ent and ent ~= 0 and DoesEntityExist(ent) then
            ResetEntityAlpha(ent)
            SetEntityVisible(ent, true, true)
        end
    end
    noclipHiddenNetIds = {}
end

local function RestoreNoclipVisuals(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        RestoreTrackedHiddenEntities()
        return
    end

    ResetEntityAlpha(ped)
    SetEntityVisible(ped, true, true)

    for _, ent in ipairs(GetAttachedEntities(ped)) do
        if ent ~= 0 and ent ~= targetped and DoesEntityExist(ent) then
            ResetEntityAlpha(ent)
            SetEntityVisible(ent, true, true)
        end
    end

    -- Restaure aussi les entités précédemment cachées même si elles ne sont
    -- plus attachées (porté lâché, véhicule quitté pendant le noclip, etc.).
    RestoreTrackedHiddenEntities()

    lastAttachedScan = 0
    cachedAttachedEntities = {}
    lastVisualsMaintain = 0
end

local function MaintainNoclipVisuals(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        nclog("MaintainNoclipVisuals: ped invalide (%s)", tostring(ped))
        return
    end

    -- Ped local : re-apply chaque frame (cheap + le game peut reset à tout moment via tasks → clignotement).
    SetEntityVisible(ped, false, false)
    SetEntityAlpha(ped, 155, false)
    SetEntityLocallyVisible(ped)

    local now = GetGameTimer()
    local refreshAttached = (now - lastAttachedScan) > NOCLIP_VISUALS_INTERVAL
    if refreshAttached then
        nclog("MaintainNoclipVisuals: déclenche scan attachés (ped=%s)", tostring(ped))
        cachedAttachedEntities = GetAttachedEntities(ped)
        lastAttachedScan = now
    end

    -- Re-apply visibilité des entités attachées uniquement quand le cache se rafraîchit.
    if refreshAttached then
        for i, ent in ipairs(cachedAttachedEntities) do
            if ent ~= 0 and ent ~= targetped and DoesEntityExist(ent) then
                nclog("MaintainNoclipVisuals: hide attached[%d]=%s", i, tostring(ent))
                SetEntityVisible(ent, false, false)
                SetEntityAlpha(ent, 155, false)
                SetEntityLocallyVisible(ent)
                TrackHiddenEntity(ent)
            end
        end

        if noclipVehicle and noclipVehicle ~= 0 and DoesEntityExist(noclipVehicle) then
            SetEntityAlpha(noclipVehicle, 155, false)
            TrackHiddenEntity(noclipVehicle)
        end
    end

    -- Ped spectaté : rester opaque (apparaît comme entité liée dans GetAttachedEntities).
    if speconmod and targetped and targetped ~= 0 and DoesEntityExist(targetped) then
        ResetEntityAlpha(targetped)
        SetEntityVisible(targetped, true, true)
    end
end

-- L'arme dans le dos est un weapon component du ped (pas une entité attachée),
-- donc SetEntityVisible ne la cache pas pour les autres clients. Le simple
-- RemoveWeaponFromPed sync mal quand le ped passe en invisible au même moment.
-- Approche fiable : switch UNARMED (force network state "no weapon equipped")
-- PUIS RemoveAllPedWeapons (vide l'inventaire d'armes). Les deux sync proprement.
local stashedWeapons = nil

local function StashPedWeapons(ped)
    if stashedWeapons then return end
    stashedWeapons = {}

    -- Sauvegarde de toutes les armes possédées avec leurs munitions
    if Config and Config.Weapons then
        for _, w in pairs(Config.Weapons) do
            local hash = joaat(w.name)
            if HasPedGotWeapon(ped, hash, false) then
                local ammo = GetAmmoInPedWeapon(ped, hash) or 0
                table.insert(stashedWeapons, { hash = hash, ammo = ammo })
            end
        end
    end

    -- Force la sync de l'état "no weapon equipped" à tous les clients
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    -- Vide complètement l'inventaire d'armes
    RemoveAllPedWeapons(ped, true)
end

local function RestorePedWeapons(ped)
    if not stashedWeapons then return end
    for _, w in ipairs(stashedWeapons) do
        GiveWeaponToPed(ped, w.hash, w.ammo or 0, false, false)
    end
    stashedWeapons = nil
end

local function SetNoClipAttributes(ped, veh, status)
    nclog("SetNoClipAttributes: ped=%s veh=%s status=%s", tostring(ped), tostring(veh), tostring(status))
    if status then
        SetEveryoneIgnorePlayer(PlayerId(), true)
        SetPoliceIgnorePlayer(PlayerId(), true)

        StashPedWeapons(ped)

        if DoesEntityExist(veh) and veh ~= 0 then
            SetEntityInvincible(veh, true)
            SetEntityCollision(veh, false, false)
            SetEntityAlpha(veh, 155, false)
            SetEntityVelocity(veh, 0.0, 0.0, 0.0)

            SetEntityInvincible(ped, true)
            SetEntityVisible(ped, false, false)
            SetEntityAlpha(ped, 155, false)
            SetEntityLocallyVisible(ped)
        else
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetEntityCollision(ped, false, false)
            SetEntityVisible(ped, false, false)
            SetEntityAlpha(ped, 155, false)
            SetEntityLocallyVisible(ped)

            SetPedCanPlayGestureAnims(ped, false)
            SetPedCanPlayAmbientAnims(ped, false)
            SetPedCanPlayVisemeAnims(ped, false, false)
            TaskSetBlockingOfNonTemporaryEvents(ped, true)
        end
    else
        SetEveryoneIgnorePlayer(PlayerId(), false)
        SetPoliceIgnorePlayer(PlayerId(), false)

        SetEntityInvincible(ped, false)
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        SetPedCanPlayGestureAnims(ped, true)
        SetPedCanPlayAmbientAnims(ped, true)
        SetPedCanPlayVisemeAnims(ped, true, true)
        TaskSetBlockingOfNonTemporaryEvents(ped, false)

        RestoreNoclipVisuals(ped)
        RestorePedWeapons(ped)

        if DoesEntityExist(veh) and veh ~= 0 then
            SetEntityInvincible(veh, false)
            SetEntityCollision(veh, true, true)
            ResetEntityAlpha(veh)
            SetEntityVisible(veh, true, true)
        end
    end
end

--- RotationToDirection
---@param rotation any
---@return any
local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local currententity
local lookedAt = { kind = nil, entity = nil, driver = nil, isPlayer = false }

-- Détection joueur basée sur GetActivePlayers() au lieu d'un raycast.
-- Les peds joueurs sont des entités networked stables: pas de streaming
-- handle mid-init → pas de crash sur les natives (contrairement aux NPCs
-- et objets que touchait l'ancien raycast 3000m).
local LOOK_MAX_DISTANCE = 100.0
local LOOK_MIN_DISTANCE = 0.5
local LOOK_CONE_DOT = 0.95 -- ~18° autour du crosshair

local function ClearLookedAt()
    if currententity and DoesEntityExist(currententity) then
        nclog("ClearLookedAt: remove outline on %s", tostring(currententity))
        SetEntityDrawOutline(currententity, false)
    end
    currententity = nil
    lookedAt.kind = nil
    lookedAt.entity = nil
    lookedAt.driver = nil
    lookedAt.isPlayer = false
    instructionalButtons[idInstructionalButtons[2]] = {}
end

---Update EntityLooking — détecte le joueur visé via cone caméra (rate-limité)
local function UpdateEntityLooking()
    if speconmod then
        if currententity then ClearLookedAt() end
        return
    end

    local myPed = VFW.PlayerData.ped
    local myPlayerId = PlayerId()
    local camCoord = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local camForward = RotationToDirection(camRot)

    local bestPed = nil
    local bestDot = LOOK_CONE_DOT
    local bestDist = LOOK_MAX_DISTANCE

    local activePlayers = GetActivePlayers()
    nclog("UpdateEntityLooking: scan %d joueurs actifs", #activePlayers)

    for _, playerId in ipairs(activePlayers) do
        if playerId ~= myPlayerId then
            local ped = GetPlayerPed(playerId)
            if ped and ped ~= 0 and ped ~= myPed and DoesEntityExist(ped) then
                local pedCoord = GetEntityCoords(ped)
                local dx = pedCoord.x - camCoord.x
                local dy = pedCoord.y - camCoord.y
                local dz = pedCoord.z - camCoord.z
                local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

                if dist >= LOOK_MIN_DISTANCE and dist <= bestDist then
                    local dot = (dx * camForward.x + dy * camForward.y + dz * camForward.z) / dist
                    if dot >= bestDot then
                        bestPed = ped
                        bestDot = dot
                        bestDist = dist
                    end
                end
            end
        end
    end

    -- Fallback véhicule vide: raycast court depuis la caméra (100m). Pas de
     -- risque de crash streaming comme l'ancien 3000m, et ça permet de cibler
     -- les véhicules sans conducteur que la boucle GetActivePlayers ne voit pas.
    if not bestPed then
        local destination = {
            x = camCoord.x + camForward.x * LOOK_MAX_DISTANCE,
            y = camCoord.y + camForward.y * LOOK_MAX_DISTANCE,
            z = camCoord.z + camForward.z * LOOK_MAX_DISTANCE
        }
        local rayHandle = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z,
            destination.x, destination.y, destination.z, 10, myPed, 0)
        local _, hit, _, _, hitEntity = GetShapeTestResult(rayHandle)

        if hit == 1 and hitEntity and hitEntity ~= 0 and DoesEntityExist(hitEntity)
            and IsEntityAVehicle(hitEntity) then
            nclog("UpdateEntityLooking: empty vehicle via raycast=%s", tostring(hitEntity))

            if currententity and currententity ~= hitEntity and DoesEntityExist(currententity) then
                SetEntityDrawOutline(currententity, false)
            end

            currententity = hitEntity
            SetEntityDrawOutline(hitEntity, true)

            lookedAt.kind = "vehicle"
          lookedAt.entity = hitEntity
            lookedAt.driver = nil
            lookedAt.isPlayer = false
            instructionalButtons[idInstructionalButtons[2]] = {
                { control = 47, label = "Supprimer le véhicule" }
            }
            return
        end

        if currententity then ClearLookedAt() end
        return
    end

    nclog("UpdateEntityLooking: bestPed=%s dist=%.2f", tostring(bestPed), bestDist)

    -- Si le joueur est dans un véhicule, cibler le véhicule pour les options
    -- "Spectate conducteur / Supprimer véhicule".
    local vehicle = GetVehiclePedIsIn(bestPed, false)
    local hasVehicle = vehicle and vehicle ~= 0 and DoesEntityExist(vehicle)
    local target = hasVehicle and vehicle or bestPed

    if currententity and currententity ~= target and DoesEntityExist(currententity) then
        nclog("UpdateEntityLooking: clear outline previous=%s", tostring(currententity))
        SetEntityDrawOutline(currententity, false)
    end

    nclog("UpdateEntityLooking: set outline target=%s hasVehicle=%s", tostring(target), tostring(hasVehicle))
    currententity = target
    SetEntityDrawOutline(target, true)

    if hasVehicle then
        lookedAt.kind = "vehicle"
      lookedAt.entity = vehicle
        lookedAt.driver = bestPed
        lookedAt.isPlayer = true
        instructionalButtons[idInstructionalButtons[2]] = {
            { control = 73, label = "Spectate le conducteur" },
            { control = 47, label = "Supprimer le véhicule" }
        }
    else
        lookedAt.kind = "ped"
      lookedAt.entity = bestPed
        lookedAt.driver = nil
        lookedAt.isPlayer = true
        instructionalButtons[idInstructionalButtons[2]] = {
            { control = 73, label = "Spectate le joueur" },
            { control = 38, label = "Ouvrir le profil du joueur" }
        }
    end
end

--- Inputs sur l'entité visée — appelé chaque frame pour ne pas rater les pressions
local function HandleLookedEntityInputs()
    if not lookedAt.kind then return end
    local entity = lookedAt.entity
    if not entity or not DoesEntityExist(entity) then return end

    if lookedAt.kind == "vehicle" then
        local driver = lookedAt.driver
        local hasPlayerDriver = driver and DoesEntityExist(driver) and IsPedAPlayer(driver)

        -- E = Spectate conducteur (si présent)
        if IsControlJustReleased(0, 73) and hasPlayerDriver then
            print("[NOCLIP DEBUG] X press → vehicle branch, hasPlayerDriver=true")
            if driver ~= VFW.PlayerData.ped then
                if speconmod and targetped and targetped ~= driver then
                    NetworkSetInSpectatorMode(false, targetped)
                    if IsEntityAttached(VFW.PlayerData.ped) then
                        DetachEntity(VFW.PlayerData.ped, true, true)
                    end
                end
                if not speconmod then
                    spectateReturnPos = GetEntityCoords(VFW.PlayerData.ped)
                end
                local capturedPed = driver
                targetServerId = GetServerIdFromPed(driver)
                speconmod = true

                -- Attendre que le net object soit stable avant les natives réseau.
                -- Sans cette guard, NetworkSetInSpectatorMode sur un ped en cours
                -- de streaming (typiquement après /goto) crash GTA5+1691021
                -- (september-ceiling-network).
                local waited = 0
                while waited < 3000 do
                    if DoesEntityExist(capturedPed)
                        and IsPedAPlayer(capturedPed)
                        and NetworkGetNetworkIdFromEntity(capturedPed) ~= 0 then
                        break
                    end
                    Wait(50)
                    waited = waited + 50
                end

                if not DoesEntityExist(capturedPed) or not IsPedAPlayer(capturedPed)
                    or NetworkGetNetworkIdFromEntity(capturedPed) == 0 then
                    speconmod = false
                    targetServerId = nil
                    spectateReturnPos = nil
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR',
                        subtitle = StaffMenu.animatorModeEnabled and 'Noclip Animateur' or 'Mode Noclip',
                        title = StaffMenu.animatorModeEnabled and VFW.AnimatorTitle() or nil,
                        message = "Impossible de spectate le conducteur (joueur hors de portée réseau)."
                  })
                    return
                end

                targetped = capturedPed
                print("[NOCLIP DEBUG] vehicle spectate OK, calling NetworkSetInSpectatorMode on ped="..tostring(targetped))
                NetworkSetInSpectatorMode(true, targetped)
            end
        end

        -- G = Supprimer véhicule (toujours)
        if IsControlJustReleased(0, 47) then
            local plate = VFW.Math.Trim(GetVehicleNumberPlateText(entity))
            local netId = VehToNet(entity)

            NetworkRequestControlOfEntity(entity)
            SetEntityAsMissionEntity(entity, true, true)

            if currententity == entity then
                SetEntityDrawOutline(entity, false)
                currententity = nil
            end
            DeleteEntity(entity)

            TriggerServerEvent("vfw:deleteEntity", { netId })
            TriggerServerEvent("vfw:vehicle:keyTemporarly:remove", nil, plate)
            TriggerServerEvent("vfw:mechanic:impound", plate)

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS',
                subtitle = StaffMenu.animatorModeEnabled and 'Noclip Animateur' or 'Mode Noclip',
                title = StaffMenu.animatorModeEnabled and VFW.AnimatorTitle() or nil,
                message = "Le véhicule a été supprimé."
          })

            lookedAt.kind = nil
            lookedAt.entity = nil
        end

    elseif lookedAt.kind == "ped" then
        local isPlayer = lookedAt.isPlayer

        if VFW.Interact.JustReleased(0, 38) and isPlayer then
            local targetPlayerId = GetServerIdFromPed(entity)
            if targetPlayerId > 0 then
                if StaffMenu.animatorModeEnabled then
                    StaffMenu.OpenPlayerMenu(targetPlayerId, true)
                else
                    ExecuteCommand("openplayer "..targetPlayerId)
                end
            end
        end

        if IsControlJustReleased(0, 73) and isPlayer then
            print("[NOCLIP DEBUG] X press → ped branch, isPlayer=true")
            if entity ~= VFW.PlayerData.ped then
                if speconmod and targetped and targetped ~= entity then
                    NetworkSetInSpectatorMode(false, targetped)
                    if IsEntityAttached(VFW.PlayerData.ped) then
                        DetachEntity(VFW.PlayerData.ped, true, true)
                    end
                end
                if not speconmod then
                    spectateReturnPos = GetEntityCoords(VFW.PlayerData.ped)
                end
                local capturedPed = entity
                targetServerId = GetServerIdFromPed(entity)
                speconmod = true

                local waited = 0
                while waited < 3000 do
                    if DoesEntityExist(capturedPed)
                        and IsPedAPlayer(capturedPed)
                        and NetworkGetNetworkIdFromEntity(capturedPed) ~= 0 then
                        break
                    end
                    Wait(50)
                    waited = waited + 50
                end

                if not DoesEntityExist(capturedPed) or not IsPedAPlayer(capturedPed)
                    or NetworkGetNetworkIdFromEntity(capturedPed) == 0 then
                    speconmod = false
                    targetServerId = nil
                    spectateReturnPos = nil
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR',
                        subtitle = StaffMenu.animatorModeEnabled and 'Noclip Animateur' or 'Mode Noclip',
                        title = StaffMenu.animatorModeEnabled and VFW.AnimatorTitle() or nil,
                        message = "Impossible de spectate le joueur (hors de portée réseau)."
                  })
                    return
                end

                targetped = capturedPed
                print("[NOCLIP DEBUG] ped spectate OK, calling NetworkSetInSpectatorMode on ped="..tostring(targetped))
                NetworkSetInSpectatorMode(true, targetped)
            end
        end
    end
end





local controls = { 12, 13, 14, 15, 16, 17, 18, 19, 50, 85, 96, 97, 99, 115, 180, 181, 198, 261, 262, 25, 24, 30, 31, 32, 33, 34, 35, 44, 20, 21 }

--- LockControls
local function LockControls()
    for _, v in pairs(controls) do
        DisableControlAction(0, v, true)
    end
    DisablePlayerFiring(VFW.PlayerData.ped, true)
    EnableControlAction(0, 166, true)
end


local NoClipSpeedCount = 1.0
local NoClipSpeed = 1.0
local NoclipMultipactor

local raycastTimer = 0

local function HandleSpectateMode(ped)
    if not speconmod then
        instructionalButtons[idInstructionalButtons[3]] = nil
        return false
    end

    if not DoesEntityExist(targetped) or not IsPedAPlayer(targetped) then
        if targetped and DoesEntityExist(targetped) then
            NetworkSetInSpectatorMode(false, targetped)
            SetEntityNoCollisionEntity(VFW.PlayerData.ped, targetped, true)
        else
            NetworkSetInSpectatorMode(false, VFW.PlayerData.ped)
        end
        if IsEntityAttached(VFW.PlayerData.ped) then
            DetachEntity(VFW.PlayerData.ped, true, true)
        end
        if spectateReturnPos then
            SetEntityCoords(VFW.PlayerData.ped, spectateReturnPos.x, spectateReturnPos.y, spectateReturnPos.z)
        end
        spectateReturnPos = nil
        targetped = nil
        targetServerId = nil
        speconmod = false
        instructionalButtons[idInstructionalButtons[3]] = nil
        VFW.ShowNotification({
            type = 'STAFF', variant = 'WARNING',
            subtitle = StaffMenu.animatorModeEnabled and 'Noclip Animateur' or 'Mode Noclip',
            title = StaffMenu.animatorModeEnabled and VFW.AnimatorTitle() or nil,
            message = "Le joueur spectaté n'est plus disponible (déconnecté ou hors de portée)."
      })
        return true
    end

    instructionalButtons[idInstructionalButtons[3]] = {
        { control = 73, label = "Ne plus spectate le joueur" },
        { control = 38, label = "Ouvrir le profil du joueur" }
    }

    if IsDisabledControlJustReleased(0, 38) and targetServerId then
        if StaffMenu.animatorModeEnabled then
            StaffMenu.OpenPlayerMenu(targetServerId, true)
        else
            ExecuteCommand("openplayer "..targetServerId)
        end
    end

    if IsDisabledControlJustReleased(0, 73) or IsControlJustReleased(0, 73) then
        print("[NOCLIP DEBUG] X released → STOP spectate via HandleSpectateMode")
        NetworkSetInSpectatorMode(false, targetped)
        if IsEntityAttached(VFW.PlayerData.ped) then
            SetEntityNoCollisionEntity(VFW.PlayerData.ped, targetped, true)
            DetachEntity(VFW.PlayerData.ped, true, true)
        end
        if spectateReturnPos then
            SetEntityCoords(VFW.PlayerData.ped, spectateReturnPos.x, spectateReturnPos.y, spectateReturnPos.z)
        end
        spectateReturnPos = nil
        targetped = nil
        targetServerId = nil
        speconmod = false
        instructionalButtons[idInstructionalButtons[3]] = nil
    end

    return true
end

local function ControlLoop(ped)
    if not inNoClip then return end

    if not DoesEntityExist(ped) then return end

    if HandleSpectateMode(ped) then
        return
    end

    local entityToMove = ped
    if noclipVehicle then
        if DoesEntityExist(noclipVehicle) then
            entityToMove = noclipVehicle
        else
            noclipVehicle = nil
        end
    end

    local pos = GetEntityCoords(entityToMove)
    local camRot = GetGameplayCamRot(2)

    local mouseX = GetDisabledControlNormal(0, INPUT_LOOK_LR)
    local mouseY = GetDisabledControlNormal(0, INPUT_LOOK_UD)

    local rotX = camRot.x + (-mouseY * settings.mouseSensitivityY)
    local rotZ = camRot.z + (-mouseX * settings.mouseSensitivityX)

    SetEntityHeading(entityToMove, rotZ)

    local radZ = math.rad(rotZ)
    local radX = math.rad(rotX)

    local vecY = vector3(
            -math.sin(radZ) * math.cos(radX),
            math.cos(radZ) * math.cos(radX),
            math.sin(radX)
    )

    local vecX = vector3(
            math.cos(radZ),
            math.sin(radZ),
            0.0
    )

    local vecZ = vector3(0, 0, 1)

    NoclipMultipactor = IsDisabledControlPressed(1, 21)

    if IsDisabledControlPressed(1, 241) then
        if NoclipMultipactor then
            NoClipSpeed = math.min(NoClipSpeed + 10, 10)
        else
            if NoClipSpeed < 1 then
                NoClipSpeed = math.min(NoClipSpeed + 0.1, 1)
            elseif NoClipSpeed < 5 then
                NoClipSpeed = math.min(NoClipSpeed + 0.5, 5)
            else
                NoClipSpeed = math.min(NoClipSpeed + 0.75, 10)
            end
        end

        NoClipSpeedCount = NoClipSpeed
    end

    if IsDisabledControlPressed(1, 242) then
        if NoclipMultipactor then
            NoClipSpeed = math.max(NoClipSpeed - 10, 0.1)
        else
            if NoClipSpeed > 5 then
                NoClipSpeed = math.max(NoClipSpeed - 0.75, 1)
            elseif NoClipSpeed > 1 then
                NoClipSpeed = math.max(NoClipSpeed - 0.5, 0.5)
            else
                NoClipSpeed = math.max(NoClipSpeed - 0.1, 0.1)
            end
        end

        NoClipSpeedCount = NoClipSpeed
    end

    local isMoving = false

    if IsDisabledControlPressed(1, 32) then
        pos = pos + (vecY * NoClipSpeed)
        isMoving = true
    end

    if IsDisabledControlPressed(1, 31) then
        pos = pos - (vecY * NoClipSpeed)
        isMoving = true
    end

    if IsDisabledControlPressed(1, 34) then
        pos = pos - (vecX * NoClipSpeed)
        isMoving = true
    end

    if IsDisabledControlPressed(1, 35) then
        pos = pos + (vecX * NoClipSpeed)
        isMoving = true
    end

    if IsDisabledControlPressed(1, 44) then
        pos = pos + (vecZ * NoClipSpeed)
        isMoving = true
    end

    if IsDisabledControlPressed(1, 20) then
        pos = pos - (vecZ * NoClipSpeed)
        isMoving = true
    end

    if isMoving then
        SetEntityCoordsNoOffset(entityToMove, pos.x, pos.y, pos.z, true, true, true)
    end

    if noclipVehicle and DoesEntityExist(noclipVehicle) then
        if not IsPedInVehicle(ped, noclipVehicle, false) then
            SetPedIntoVehicle(ped, noclipVehicle, -1)
        end
    end

    -- Détection joueur visé: rate-limité 5 frames. Pas de raycast → pas
    -- de touch sur entités streaming, on itère uniquement GetActivePlayers().
    raycastTimer = raycastTimer + 1
    if raycastTimer >= 5 then
        raycastTimer = 0
        UpdateEntityLooking()
    end

    HandleLookedEntityInputs()

    LockControls()
end



--- .ToggleNoclip
---@return any
local isTogglingNoclip = false -- Prevent concurrent toggles
function VFW.ToggleNoclip()
    -- Prevent concurrent noclip toggles
    if isTogglingNoclip then
        nclog("ToggleNoclip: ignoré (toggle déjà en cours)")
        return
    end
    nclog("ToggleNoclip: appel (inNoClip=%s)", tostring(inNoClip))

    if not StaffMenu.adminChecked and not StaffMenu.animatorModeEnabled then
        return
    end


    isTogglingNoclip = true

    if inNoClip then
        inNoClip = false
        TriggerServerEvent("vfw:stafflogs:noclipState", false)

        local pPed = VFW.PlayerData.ped
        local pVeh = noclipVehicle or GetVehiclePedIsIn(pPed, false)

        -- Détermine les coords selon si on est en véhicule ou pas
        local pCoords
        if noclipVehicle and DoesEntityExist(noclipVehicle) then
            pCoords = GetEntityCoords(noclipVehicle)
        else
            pCoords = GetEntityCoords(pPed)
        end

        if IsEntityAttached(pPed) and speconmod then
            NetworkSetInSpectatorMode(false, targetped)
            SetEntityNoCollisionEntity(pPed, targetped, true)
            DetachEntity(pPed, true, true)
            if spectateReturnPos then
                SetEntityCoords(pPed, spectateReturnPos.x, spectateReturnPos.y, spectateReturnPos.z)
            end
            spectateReturnPos = nil
            speconmod, targetped, targetServerId, targetid = false, nil, nil, nil
        end


        SetNoClipAttributes(pPed, pVeh, false)
        instructionalButtons[idInstructionalButtons[1]] = {}
        instructionalButtons[idInstructionalButtons[2]] = {}

        -- Essayer de trouver le sol depuis la position actuelle
        local get, z = GetGroundZFor_3dCoord(pCoords.x, pCoords.y, pCoords.z, true, 0)

        -- Si on est sous la map (sol non trouvé), chercher depuis plus haut
        if not get then
            -- Téléporter temporairement en hauteur pour charger le terrain et trouver le sol
            local entityToMove = (noclipVehicle and DoesEntityExist(noclipVehicle)) and noclipVehicle or pPed
            SetEntityCoordsNoOffset(entityToMove, pCoords.x, pCoords.y, 800.0, true, true, true)
            Wait(100) -- Attendre que le terrain se charge

            -- Réessayer de trouver le sol depuis cette hauteur
            get, z = GetGroundZFor_3dCoord(pCoords.x, pCoords.y, 850.0, true, 0)

            -- Si toujours pas trouvé, essayer avec un raycast
            if not get then
                local rayHandle = StartShapeTestRay(pCoords.x, pCoords.y, 1000.0, pCoords.x, pCoords.y, -100.0, 1, entityToMove, 0)
                local _, hit, endCoords = GetShapeTestResult(rayHandle)
                if hit then
                    z = endCoords.z
                    get = true
                end
            end

            -- Si toujours rien, utiliser une hauteur par défaut sécurisée
            if not get then
                z = 50.0 -- Hauteur par défaut
                get = true
            end
        end

        if get then
            if noclipVehicle and DoesEntityExist(noclipVehicle) then
                -- Si on était en véhicule, replacer le véhicule au sol
                SetEntityCoordsNoOffset(noclipVehicle, pCoords.x, pCoords.y, z + 1.0, 0.0, 0.0, 0.0)
                -- S'assurer que le joueur est toujours dans le véhicule
                if not IsPedInVehicle(pPed, noclipVehicle, false) then
                    SetPedIntoVehicle(pPed, noclipVehicle, -1)
                end
            elseif pVeh ~= 0 then
                SetEntityCoordsNoOffset(pVeh, pCoords.x, pCoords.y, z + 1.0, 0.0, 0.0, 0.0)
            else
                SetEntityCoordsNoOffset(pPed, pCoords.x, pCoords.y, z + 1.0, 0.0, 0.0, 0.0)
            end
        end

        -- Restaurer visibilité véhicule pour tous les clients
        if noclipVehicle and DoesEntityExist(noclipVehicle) then
            Entity(noclipVehicle).state:set('noclipHidden', nil, true)
        end

        -- Restaurer visibilité ped pour tous les clients
        local restorePed = VFW.PlayerData and VFW.PlayerData.ped or PlayerPedId()
        if restorePed and DoesEntityExist(restorePed) then
            Entity(restorePed).state:set('noclipPed', nil, true)
        end

        -- Le prop "arme dans le dos" est attaché localement chez chaque client,
        -- pas synchronisé en tant qu'entité. SetEntityAsMissionEntity/alpha ne
        -- le cache pas. Lever la suppression : la boucle weapon_back va recréer
        -- le prop localement et broadcast la sync aux autres clients.
        if VFW.SetBackWeaponSuppressed then
            VFW.SetBackWeaponSuppressed(false)
        end

        -- Réinitialiser le véhicule en noclip
        noclipVehicle = nil

        if currententity then
            SetEntityDrawOutline(currententity, false)
        end

        Wait(100)

        isTogglingNoclip = false
        instructionalButtons[idInstructionalButtons[1]] = nil
        return
    else
        inNoClip = true
        TriggerServerEvent("vfw:stafflogs:noclipState", true)

        -- Détecter si le joueur est dans un véhicule
        local pPed = VFW.PlayerData.ped
        local pVeh = GetVehiclePedIsIn(pPed, false)

        if pVeh ~= 0 then
            -- Stocker le véhicule pour le noclip
            noclipVehicle = pVeh
            NetworkRequestControlOfEntity(noclipVehicle)
            -- Sync invisibilité véhicule à tous les clients
            Entity(noclipVehicle).state:set('noclipHidden', true, true)
        else
            noclipVehicle = nil
        end

        -- Sync invisibilité ped à tous les clients (cache aussi l'arme rendue
        -- dans le dos qui n'est pas une entité attachée).
        if pPed and DoesEntityExist(pPed) then
            Entity(pPed).state:set('noclipPed', true, true)
        end

        -- Le prop "arme dans le dos" est attaché localement chez chaque client.
        -- Couper l'alpha du ped ne le cache pas. On suppress proprement : la
        -- boucle de weapon_back va arrêter de re-créer le prop ET broadcast
        -- un remove aux autres clients.
        if VFW.SetBackWeaponSuppressed then
            VFW.SetBackWeaponSuppressed(true)
        end

        ClearPedTasksImmediately(pPed)

        SetNoClipAttributes(pPed, pVeh, true)

        CreateThread(function()
            local lastSpeedCount = nil
            local lastSpeconmod = nil
            local lastFreezeApply = 0
            local lastVehicleVelocity = 0

            local function updateInstructionalButtons()
                if speconmod then
                    instructionalButtons[idInstructionalButtons[1]] = {}
                else
                    instructionalButtons[idInstructionalButtons[1]] = {
                        { control = 32, control2 = 33, label = "Avancer/Reculer" },
                        { control = 34, control2 = 35, label = "Gauche/Droite" },
                        { control = 44, control2 = 20, label = "Haut/Bas" },
                        { control = 241, label = "Molette - Vitesse ("..NoClipSpeedCount.."x)" },
                        { control = 29, label = "Activer/Désactiver le viseur" }
                    }
                end
            end

            updateInstructionalButtons()

            while inNoClip do
                local ped = VFW.PlayerData.ped

                if not DoesEntityExist(ped) then
                    Wait(100)
                    goto continue
                end

                if lastSpeedCount ~= NoClipSpeedCount or lastSpeconmod ~= speconmod then
                    lastSpeedCount = NoClipSpeedCount
                    lastSpeconmod = speconmod
                    updateInstructionalButtons()
                end

                SetCrosshairOverlay(toggleCrosshair and not speconmod)

                if IsControlJustPressed(0, 29) then
                    toggleCrosshair = not toggleCrosshair
                    SetResourceKvp("noclip_crosshair", toggleCrosshair and "true" or "false")
                end

                ControlLoop(ped)
                MaintainNoclipVisuals(ped)

                local now = GetGameTimer()

                if noclipVehicle and DoesEntityExist(noclipVehicle) and (now - lastVehicleVelocity) >= 100 then
                    lastVehicleVelocity = now
                    SetEntityVelocity(noclipVehicle, 0.0, 0.0, 0.0)
                end

                -- FreezeEntityPosition est déjà posée dans SetNoClipAttributes ; on re-confirme
                -- juste périodiquement au cas où une task la lèverait (ragdoll, animation).
                if (now - lastFreezeApply) >= 500 then
                    lastFreezeApply = now
                    FreezeEntityPosition(ped, not noclipVehicle)
                end

                Wait(0)
                ::continue::
            end

            SetCrosshairOverlay(false)
        end)

        Wait(100)
        isTogglingNoclip = false
    end
end

--- .IsNoclipActive
---@return any
function VFW.IsNoclipActive()
    return inNoClip
end

function VFW.StopNoclipSilent()
    if not inNoClip then return end
    inNoClip = false

    SetEveryoneIgnorePlayer(PlayerId(), false)
    SetPoliceIgnorePlayer(PlayerId(), false)

    if speconmod then
        NetworkSetInSpectatorMode(false, targetped)
        if IsEntityAttached(VFW.PlayerData.ped) then
            DetachEntity(VFW.PlayerData.ped, true, true)
        end
        speconmod = false
        targetped = nil
        targetServerId = nil
        spectateReturnPos = nil
        instructionalButtons[idInstructionalButtons[3]] = nil
    end

    RestoreNoclipVisuals(VFW.PlayerData.ped)

    -- Restaurer visibilité ped pour les autres clients
    local silentPed = VFW.PlayerData and VFW.PlayerData.ped or PlayerPedId()
    if silentPed and DoesEntityExist(silentPed) then
        Entity(silentPed).state:set('noclipPed', nil, true)
    end

    -- Lever la suppression du prop "arme dans le dos"
  if VFW.SetBackWeaponSuppressed then
        VFW.SetBackWeaponSuppressed(false)
    end

    if noclipVehicle and DoesEntityExist(noclipVehicle) then
        Entity(noclipVehicle).state:set('noclipHidden', nil, true)
        ResetEntityAlpha(noclipVehicle)
        SetEntityVisible(noclipVehicle, true, true)
    end
    noclipVehicle = nil

    instructionalButtons[idInstructionalButtons[1]] = nil
    instructionalButtons[idInstructionalButtons[2]] = nil

    if currententity then
        SetEntityDrawOutline(currententity, false)
        currententity = nil
    end
end

--- Toggle le crosshair du noclip
function VFW.ToggleNoclipCrosshair()
    toggleCrosshair = not toggleCrosshair
    SetResourceKvp("noclip_crosshair", toggleCrosshair and "true" or "false")
end

--- Retourne l'état du crosshair noclip
---@return boolean
function VFW.IsNoclipCrosshairActive()
    return toggleCrosshair
end
