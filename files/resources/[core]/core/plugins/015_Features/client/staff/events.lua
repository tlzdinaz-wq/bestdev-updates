---@meta _
---@diagnostic disable: duplicate-doc-field

-- Initialize staff mode list
VFW.staffMode = {}

-- Track whether we were in staff mode in the previous sync, so we can detect
-- the transition out and force a local outfit restore. This protects against
-- network event reordering where setStaffClothes(false) is lost or arrives
-- before a stale setStaffClothes(true), which would leave the staff helmet on.
local wasInStaffMode = false

-- Receive staff mode sync from server
RegisterNetEvent("vfw:staff:syncStaffMode", function(staffModeList)
    VFW.staffMode = staffModeList or {}

    local myId = GetPlayerServerId(PlayerId())
    local isInStaffMode = false
    for _, staffId in ipairs(VFW.staffMode) do
        if staffId == myId then
            isInStaffMode = true
            break
        end
    end

    if wasInStaffMode and not isInStaffMode then
        TriggerEvent("vfw:staff:setStaffClothes", false)
    end
    wasInStaffMode = isInStaffMode
end)

RegisterNetEvent("core:staff:noclip", function()
    VFW.ToggleNoclip()
end)

RegisterNetEvent("vfw:staff:rename:openInputs", function(targetId, currentName)
    Citizen.CreateThread(function()
        local firstName = VFW.Nui.KeyboardInput(true, "Prénom RP de " .. (currentName or ""), "")
        if not firstName or firstName == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Rename',
                message = "Prénom requis."
          })
            return
        end

        local lastName = VFW.Nui.KeyboardInput(true, "Nom RP de " .. (currentName or ""), "")
        if not lastName or lastName == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Rename',
                message = "Nom requis."
          })
            return
        end

        TriggerServerEvent("vfw:staff:rename:apply", targetId, firstName, lastName)
    end)
end)

---@param resourceName number Player ID
AddEventHandler("onResourceStop", function(resourceName)
    if (GetCurrentResourceName() ~= "core") then
        return
    end

    if VFW.ToggleNoclip and VFW.IsNoclipActive and VFW.IsNoclipActive() then
        VFW.ToggleNoclip()
    end
end)

---@param coords vector3|table target coords (start) or pre-spectate coords (stop)
---@param id any
---@param isSpectating any
RegisterNetEvent("core:StaffSpectate", function(coords, id, isSpectating)
    local playerPed = PlayerPedId()
    local playerId = PlayerId()
    local myServerId = GetPlayerServerId(playerId)

    if isSpectating then
        if tonumber(id) == myServerId then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Events', message = "Tu ne peux pas te spectate toi-même." })
            return
        end

        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        FreezeEntityPosition(playerPed, true)
        SetEntityInvincible(playerPed, true)
        SetEntityCollision(playerPed, false, false)
        SetEntityVisible(playerPed, false, false)
        SetEveryoneIgnorePlayer(playerId, true)

        if coords then
            SetEntityCoordsNoOffset(playerPed, coords.x, coords.y, coords.z, false, false, false)
        end

        local targetPlayerIndex = GetPlayerFromServerId(id)
        local targetPed = 0
        local timeout = 80
        while timeout > 0 do
            targetPlayerIndex = GetPlayerFromServerId(id)
            if targetPlayerIndex ~= -1 then
                targetPed = GetPlayerPed(targetPlayerIndex)
                -- Inclut un check NetworkGetNetworkIdFromEntity: sans ça
                -- NetworkSetInSpectatorMode crash réseau sur un ped fraichement
                -- streamé (GTA5+1691021).
                if targetPed and targetPed ~= 0
                    and DoesEntityExist(targetPed)
                    and targetPed ~= playerPed
                    and IsPedAPlayer(targetPed)
                    and NetworkGetNetworkIdFromEntity(targetPed) ~= 0 then
                    break
                end
            end
            Wait(100)
            timeout = timeout - 1
        end

        if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed)
            or NetworkGetNetworkIdFromEntity(targetPed) == 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Events', message = "Joueur non trouvé ou hors de portée." })
            -- Route through StopSpectate so the noclip restore + state cleanup
            -- runs and we never appear at the target's last coords.
            if StaffMenu and StaffMenu.StopSpectate then
                StaffMenu.StopSpectate()
            else
                FreezeEntityPosition(playerPed, false)
                SetEntityInvincible(playerPed, false)
                SetEntityCollision(playerPed, true, true)
                SetEntityVisible(playerPed, true, false)
                SetEveryoneIgnorePlayer(playerId, false)
                DoScreenFadeIn(250)
            end
            return
        end

        Wait(100)

        NetworkSetInSpectatorMode(true, targetPed)

        DoScreenFadeIn(250)
    else
        -- Fade out pour cacher la transition
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        -- Désactiver le mode spectateur
        NetworkSetInSpectatorMode(false, playerPed)
        SetEveryoneIgnorePlayer(playerId, false)

        -- Teleport back to the pre-spectate position so the ped no longer
        -- overlaps the target ped. Re-entering noclip while stacked on another
        -- player triggers the GTA5+8EC6A8 crash.
        if coords and coords.x then
            SetEntityCoordsNoOffset(playerPed, coords.x, coords.y, coords.z, false, false, false)
            SetEntityVelocity(playerPed, 0.0, 0.0, 0.0)
        end

        if StaffMenu and StaffMenu._restoreNoclipAfterSpectate then
            StaffMenu._restoreNoclipAfterSpectate = false
            VFW.ToggleNoclip()
        else
            FreezeEntityPosition(playerPed, false)
            SetEntityInvincible(playerPed, false)
            SetEntityCollision(playerPed, true, true)
            SetEntityVisible(playerPed, true, false)
        end

        DoScreenFadeIn(250)
    end
end)

-- Watch distance after /goto with bucket change, return to original bucket when far enough
RegisterNetEvent("vfw:staff:goto:watchBucket", function(targetServerId, originalBucket)
    CreateThread(function()
        local threshold = 50.0
        while true do
            Wait(1000)
            local targetPlayer = GetPlayerFromServerId(targetServerId)
            if targetPlayer == -1 then
                TriggerServerEvent("vfw:staff:goto:restoreBucket", originalBucket)
                return
            end

            local targetPed = GetPlayerPed(targetPlayer)
            if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
                TriggerServerEvent("vfw:staff:goto:restoreBucket", originalBucket)
                return
            end

            local myCoords = GetEntityCoords(PlayerPedId())
            local targetCoords = GetEntityCoords(targetPed)
            if #(myCoords - targetCoords) > threshold then
                TriggerServerEvent("vfw:staff:goto:restoreBucket", originalBucket)
                return
            end
        end
    end)
end)

---@param staut any
RegisterNetEvent("core:FreezePlayer", function(staut)
    FreezeEntityPosition(VFW.PlayerData.ped, staut)
end)

---@param ped any
RegisterNetEvent("core:client:setped", function(ped)
    -- Validation du model avant tout RequestModel (un hash invalide bloque
    -- HasModelLoaded en boucle infinie et fige le client).
    if not ped or not IsModelInCdimage(ped) or not IsModelValid(ped) then return end

    RequestModel(ped)
    local waited = 0
    while not HasModelLoaded(ped) and waited < 5000 do
        Wait(50)
        waited = waited + 50
    end
    if not HasModelLoaded(ped) then
        SetModelAsNoLongerNeeded(ped)
        return
    end

    -- Freeze + invincibilité pendant le model swap : SetPlayerModel détruit le
    -- net object puis en recrée un autre. Si le ped bouge pendant la fenêtre
    -- (noclip, vitesse, animation), les clients voisins reçoivent un update de
    -- position sur un net object en cours de cleanup → crash GTA5+1691021
    -- (september-ceiling-network).
    local oldPed = PlayerPedId()
    FreezeEntityPosition(oldPed, true)
    SetEntityInvincible(oldPed, true)

    SetPlayerModel(PlayerId(), ped)

    -- SetPlayerModel respawn le ped en async, attendre le nouveau handle valide.
    local newPed = PlayerPedId()
    local pedTimeout = 0
    while (not newPed or newPed == 0 or not DoesEntityExist(newPed)) and pedTimeout < 30 do
        Wait(50)
        newPed = PlayerPedId()
        pedTimeout = pedTimeout + 1
    end

    -- Bug historique : `SetPedDefaultComponentVariation(ped)` recevait le HASH
    -- du modèle au lieu du handle du ped, donc les composants restaient non
    -- initialisés et faisaient crash les clients voisins quand le ped streamait
    -- dans leur range.
    -- On gate aussi sur IsPedHuman : sur un ped animal (a_c_*) cette native peut
    -- corrompre le renderer.
    if newPed and newPed ~= 0 and IsPedHuman(newPed) then
        SetPedDefaultComponentVariation(newPed)
    end
    SetModelAsNoLongerNeeded(ped)

    -- Stabilisation : laisser le net object se sync chez les voisins avant de
    -- libérer la position. Sans ce wait, le crash arrive si le staff noclip ou
    -- bouge dans la fraction de seconde post-swap.
    Wait(500)
    if newPed and newPed ~= 0 then
        FreezeEntityPosition(newPed, false)
        SetEntityInvincible(newPed, false)
    end
end)

RegisterNetEvent("core:client:unsetped", function()
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

    if not skin then
        return
    end

    local ped = "mp_m_freemode_01"

  if skin.sex == 1 then
        ped = "mp_f_freemode_01"
  elseif skin.sex and skin.sex > 1 then
        ped = Config.PedsCharCreator[skin.sex - 1]
    end

    if not IsModelInCdimage(ped) or not IsModelValid(ped) then return end

    RequestModel(ped)
    local loadWait = 0
    while not HasModelLoaded(ped) and loadWait < 5000 do
        Wait(50)
        loadWait = loadWait + 50
    end
    if not HasModelLoaded(ped) then
        SetModelAsNoLongerNeeded(ped)
        return
    end

    -- Même protection qu'au setped : freeze pendant le swap pour éviter le
    -- crash réseau sur les voisins quand le net object est recréé.
    local oldPed = PlayerPedId()
    FreezeEntityPosition(oldPed, true)
    SetEntityInvincible(oldPed, true)

    SetPlayerModel(PlayerId(), ped)
    local newPed = PlayerPedId()
    local pedTimeout = 0
    while (not newPed or newPed == 0 or not DoesEntityExist(newPed)) and pedTimeout < 30 do
        Wait(50)
        newPed = PlayerPedId()
        pedTimeout = pedTimeout + 1
    end
    if newPed and newPed ~= 0 and IsPedHuman(newPed) then
        SetPedDefaultComponentVariation(newPed)
    end
    SetModelAsNoLongerNeeded(ped)

    Wait(500)
    if newPed and newPed ~= 0 then
        FreezeEntityPosition(newPed, false)
        SetEntityInvincible(newPed, false)
    end

    TriggerEvent('skinchanger:loadSkin', skin or {})
end)

-- Recevoir le screenshot et l'afficher au staff
---@param imgUrl string URL de l'image
---@param playerInfo table Infos du joueur (name, visaId)
RegisterNetEvent("vfw:staff:receiveScreen", function(imgUrl, playerInfo)
    SendNUIMessage({
        action = "staff:screenshot:open",
        data = {
            imageUrl = imgUrl,
            name = playerInfo and playerInfo.name or "Inconnu",
            visaId = playerInfo and playerInfo.visaId or 0
        }
    })
    VFW.Nui.Focus(true, false)
end)

-- Callback pour fermer la modale du screenshot
RegisterNUICallback("staff:screenshot:close", function(data, cb)
    VFW.Nui.Focus(false, false)
    cb('ok')
end)

VFW.ListTpIpl = {}
local blipsEnter = {}
local blipsExit = {}

local function createTpIp(name, enterCoords, ipl)
    local enterId = "tpipl_enter_" .. name
    local exitId = "tpipl_exit_" .. name

    FloatingUI.Create(enterId, enterCoords, 3.0, {
        title = name,
        size = "small",
        buttons = {
            {
                label = "Entrer",
                key = "E",
                icon = "map",
                action = function()
                    SetEntityCoords(PlayerPedId(), ipl.tp)
                end
            }
        }
    })

    FloatingUI.Create(exitId, vector3(ipl.tp.x, ipl.tp.y, ipl.tp.z + 1.0), 3.0, {
        title = name,
        size = "small",
        buttons = {
            {
                label = "Sortir",
                key = "E",
                icon = "map",
                action = function()
                    SetEntityCoords(PlayerPedId(), vector3(enterCoords.x, enterCoords.y, enterCoords.z - 1.0))
                end
            }
        }
    })
end

CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(1) end

    VFW.ListTpIpl = TriggerServerCallback('core:events:getListTpIpl')

    while VFW.ListTpIpl == nil or next(VFW.ListTpIpl) == nil do Wait(100) end

    for tpIplName,tpIplData in pairs(VFW.ListTpIpl) do
        createTpIp(tpIplName, tpIplData.enter, tpIplData.ipl)
    end
end)

---@param name string
---@param enterCoords vector3|table
---@param ipl any
RegisterNetEvent('core:events:createTpIpl', function(name, enterCoords, ipl)
    VFW.ListTpIpl[name] = {
        enter = enterCoords,
        ipl = ipl
    }

    createTpIp(name, enterCoords, ipl)
end)

---@param name string
RegisterNetEvent('core:events:deleteTpIpl', function(name)
    VFW.ListTpIpl[name] = nil

    FloatingUI.Remove("tpipl_enter_" .. name)
    FloatingUI.Remove("tpipl_exit_" .. name)
end)

---@param playerName string
---@param message string
---@param role string
RegisterNetEvent('vfw:staff:chatMessage', function(playerName, message, role)
    local displayRole = role or "Staff"
  TriggerEvent('chat:addMessage', {
        template = '<div style="background-color: rgba(255, 193, 7, 0.15); padding: 8px 12px; border-left: 3px solid #FFC107; margin: 2px 0;">(<strong style="color: #FFC107;"> {0} | {1} </strong>) : <span style="color: #FFF;">{2}</span></div>',
        args = { playerName, displayRole, message }
    })
end)

-- Time Management Client Events
RegisterNetEvent("vfw:staff:updateTime", function(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end)

-- Variables globales pour le freeze time (évite le bug de closure)
local isTimeFrozen = false
local frozenHour, frozenMinute, frozenSecond = 0, 0, 0

RegisterNetEvent("vfw:staff:freezeTime", function(freeze)
    isTimeFrozen = freeze
    if freeze then
        frozenHour, frozenMinute, frozenSecond = GetClockHours(), GetClockMinutes(), GetClockSeconds()
    end
end)

-- Thread unique qui gère le freeze time
CreateThread(function()
    while true do
        if isTimeFrozen then
            NetworkOverrideClockTime(frozenHour, frozenMinute, frozenSecond)
        end
        Wait(100)  -- 100ms suffit, pas besoin de Wait(0)
    end
end)

RegisterNetEvent("vfw:staff:setBlackout", function(state)
    SetBlackout(state)

    local xSound = exports.xsound

    if state then
        SetArtificialLightsState(true)
        SetArtificialLightsStateAffectsVehicles(false)

        xSound:PlayUrl('blackout_sound', 'nui://xsound/html/sounds/no_power.mp3', 0.5)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Gestion Events',
            message = "Blackout activé - Coupure électrique générale."
      })
    else
        SetArtificialLightsState(false)

        xSound:PlayUrl('blackout_restore_sound', 'nui://xsound/html/sounds/restored_power.mp3', 0.5)

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Events',
            message = "Blackout désactivé - Électricité rétablie."
      })
    end
end)

RegisterNetEvent("vfw:staff:fireNotification", function()
    SendNUIMessage({ action = "fireAlarm:show", data = { type = "alarm", duration = 6000 } })
end)

RegisterNetEvent("vfw:staff:fireAlarmClient", function()
    SendNUIMessage({ action = "fireAlarm:show", data = { type = "alarm", duration = 8000 } })
    SendNUIMessage({ action = "nui:alarm", data = { action = "start", volume = 0.5 } })
    CreateThread(function()
        Wait(8000)
        SendNUIMessage({ action = "nui:alarm", data = { action = "stop" } })
    end)
end)

RegisterNetEvent("vfw:staff:fireAlarmEnd", function()
    SendNUIMessage({ action = "fireAlarm:show", data = { type = "falseAlarm", duration = 6000 } })
end)

-- Player Management Client Events
RegisterNetEvent("vfw:staff:reviveClient", function()
    TriggerEvent("vfw:revivePlayer")
end)

RegisterNetEvent("vfw:staff:freezePlayer", function(freeze)
    FreezeEntityPosition(PlayerPedId(), freeze)
end)

-- Weapon Management Client Events
RegisterNetEvent("vfw:staff:receiveWeapon", function(weaponModel, ammo, infinite)
    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(weaponModel)

    GiveWeaponToPed(playerPed, weaponHash, ammo, false, false)

    if infinite then
        SetPedInfiniteAmmo(playerPed, true, weaponHash)
    end
end)

RegisterNetEvent("vfw:staff:removeWeapons", function()
    RemoveAllPedWeapons(PlayerPedId(), true)
end)

-- Ped Management Client Events
RegisterNetEvent("vfw:staff:restorePed", function(model)
    -- Use the existing unsetped event which properly handles model + skin restoration
    TriggerEvent("core:client:unsetped")
end)

-- Role Selection (triggered by /setrank command)
RegisterNetEvent("vfw:staff:openRoleSelection", function(targetId, targetName)
    local roles = {
        { id = "user", label = "Utilisateur" },
        { id = "animator", label = "Animateur" },
        { id = "niveau_1", label = "Niveau 1" },
        { id = "niveau_2", label = "Niveau 2" },
        { id = "niveau_3", label = "Niveau 3" },
        { id = "niveau_4", label = "Niveau 4" },
        { id = "niveau_5", label = "Niveau 5" },
    }

    local promptText = "Rôle pour " .. (targetName or "?") .. ":\n"
  for i, role in ipairs(roles) do
        promptText = promptText .. i .. "=" .. role.label .. " "
  end

    local input = VFW.Nui.KeyboardInput(true, promptText, "")
    local choice = tonumber(input)
    if choice and choice >= 1 and choice <= #roles then
        TriggerServerEvent("vfw:staff:setPlayerRole", targetId, roles[choice].id)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Commandes',
            message = "Rôle " .. roles[choice].label .. " attribué à " .. (targetName or "?") .. "."
      })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Commandes',
            message = "Ce choix n'est pas valide."
      })
    end
end)

RegisterNetEvent("vfw:staff:releaseFromJail", function()
    local ped = PlayerPedId()
    local release = (TIGConfig and TIGConfig.Release and TIGConfig.Release.admin)
        or vector4(1846.62, 2585.87, 44.67, 267.99)
    SetEntityCoords(ped, release.x, release.y, release.z, false, false, false, false)
    SetEntityHeading(ped, release.w)

    VFW.ShowNotification({
        type = 'ROUGE',
        message = "Vous avez été libéré de prison."
  })
end)

-- Clear all trains (Roxwood train job cleanup)
RegisterNetEvent("vfw:staff:clearTrains", function()
    DeleteAllTrains()
    SetRandomTrains(false)
    Wait(100)
    SetRandomTrains(true)
end)

RegisterNetEvent('vfw:staff:explodeVehicleClient')
AddEventHandler('vfw:staff:explodeVehicleClient', function(x, y, z)
    AddExplosion(x, y, z, 7, 1.0, true, false, 1.0)
end)

-- Set vehicle livery (client-side only)
RegisterNetEvent("staff:setVehicleLivery", function(networkId, liveryId)
    local vehicle = NetworkGetEntityFromNetworkId(networkId)
    if vehicle and DoesEntityExist(vehicle) then
        local nativeLivCount = GetVehicleLiveryCount(vehicle)
        if nativeLivCount > 0 then
            SetVehicleLivery(vehicle, liveryId)
        else
            SetVehicleModKit(vehicle, 0)
            SetVehicleMod(vehicle, 48, liveryId, false)
        end
    end
end)

RegisterCommand("staff", function()
    if not VFW.PlayerData or not VFW.HasStaffPerm("staff_menu") then
        return
    end

    local newState = not StaffMenu.adminChecked

    if not newState and VFW.IsNoclipActive() then
        VFW.ToggleNoclip()
    end

    StaffMenu.adminChecked = newState
    -- Tenue staff coupée : toujours signaler le bypass au serveur.
    local bypassOutfit = (VFW.StaffOutfitEnabled ~= true) or GetResourceKvpString("staff_bypass_outfit") == "true"
  TriggerServerEvent("vfw:staff:mode", newState, bypassOutfit)

    if newState then
        TriggerServerEvent("Admin:activeBlips", true)
        TriggerServerEvent("Admin:gamerTag", true)
        local savedNametagState = GetResourceKvpString("staff_name_tags")
        if savedNametagState == "true" then
            StaffMenu.showRPNamesOnPlayerTags = true
        end
        VFW.AdminOverley()
        -- Désinscrit du push off-duty puisqu'on est désormais en staff mode
        TriggerServerEvent("vfw:staff:setHudOffDuty", false)
        local hideHudPreference = GetResourceKvpString("staff_hide_web_hud") == "true"
      if not hideHudPreference then
            if ToggleStaffHUD then
                ToggleStaffHUD(true)
            end
            if initStaffHud then
                initStaffHud()
            end
        end
    else
        TriggerServerEvent("Admin:activeBlips", false)
        TriggerServerEvent("Admin:gamerTag", false)
        if ApplyHudOffDutyPreference then
            ApplyHudOffDutyPreference()
        elseif ToggleStaffHUD then
            ToggleStaffHUD(false)
        end
        if StaffMenu.ToggleVehicleSpeedTags then
            StaffMenu.ToggleVehicleSpeedTags(false)
        end
        if StaffMenu.CleanupPersonalState then
            StaffMenu.CleanupPersonalState()
        end
        StaffMenu.animatorSettings.noclipActive = false
    end

    VFW.ShowNotification({
        type = 'STAFF',
        variant = newState and 'SUCCESS' or 'INFO',
        subtitle = 'Mode Staff',
        message = newState and "Mode administration activé." or "Mode administration désactivé."
  })
end, false)

TriggerEvent("chat:addSuggestion", "/hud", "Permet de voir les informations au viseur (Staff)")
TriggerEvent("chat:addSuggestion", "/voir", "Voir l'écran d'un joueur en direct (Staff)", { { name = "id", help = "ID du joueur" } })
TriggerEvent("chat:addSuggestion", "/screenshot", "Prendre une capture d'écran d'un joueur (Staff)", { { name = "id", help = "ID du joueur" } })
TriggerEvent("chat:addSuggestion", "/blips", "Toggle les blips des joueurs à moins d'1km (Staff)")
TriggerEvent("chat:addSuggestion", "/wash", "Nettoyer le véhicule (dans/à proximité) (Staff)")
TriggerEvent("chat:addSuggestion", "/fuel", "Faire le plein du véhicule (dans/à proximité) (Staff)")

local function _getStaffTargetVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        veh = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
    end
    return veh
end

local function _runVehicleStaffAction(action, perm, subtitle)
    if not StaffMenu.adminChecked then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = subtitle, message = "Vous devez être en mode staff." })
        return
    end
    if not VFW.HasStaffPerm(perm) then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = subtitle, message = "Permission insuffisante." })
        return
    end

    local veh = _getStaffTargetVehicle()
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = subtitle, message = "Aucun véhicule à proximité." })
        return
    end
    if not NetworkGetEntityIsNetworked(veh) then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = subtitle, message = "Véhicule non networked." })
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local result = TriggerServerCallback("vfw:action:run", {
        action = action,
        ent = { netId = netId, entType = 2 },
        permission = perm
    })

    if result and result.ok then
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = subtitle, message = (result.msg or "OK") .. "." })
    elseif result and result.err then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = subtitle, message = "Erreur: " .. result.err .. "." })
    end
end

RegisterCommand("wash", function()
    _runVehicleStaffAction("vehicle:clean", "alt_repair_vehicle", "Gestion Véhicules")
end, false)

RegisterCommand("fuel", function()
    _runVehicleStaffAction("vehicle:refuel", "alt_repair_vehicle", "Gestion Véhicules")
end, false)

local _blipsActive = false
local _blipsList = {}

local function _clearStaffBlips()
    for serverId, blip in pairs(_blipsList) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        _blipsList[serverId] = nil
    end
end

RegisterCommand("blips", function()
    if not StaffMenu.adminChecked then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Blips Joueur', message = "Vous devez être en mode staff." })
        return
    end
    if not VFW.HasStaffPerm("staff_menu") then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Blips Joueur', message = "Permission insuffisante." })
        return
    end

    _blipsActive = not _blipsActive
    if not _blipsActive then
        _clearStaffBlips()
        VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Blips Joueur', message = "Blips désactivés." })
        return
    end

    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Blips Joueur', message = "Blips activés (1km)." })

    CreateThread(function()
        while _blipsActive do
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            local seen = {}
            for _, playerId in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(playerId)
                if ped ~= 0 and ped ~= myPed then
                    local serverId = GetPlayerServerId(playerId)
                    local dist = #(GetEntityCoords(ped) - myCoords)
                    if dist <= 1000.0 then
                        seen[serverId] = true
                        if not _blipsList[serverId] or not DoesBlipExist(_blipsList[serverId]) then
                            local blip = AddBlipForEntity(ped)
                            SetBlipSprite(blip, 1)
                            SetBlipColour(blip, 0)
                            SetBlipScale(blip, 0.85)
                            ShowHeadingIndicatorOnBlip(blip, true)
                            BeginTextCommandSetBlipName("STRING")
                            AddTextComponentString("Joueur " .. serverId)
                            EndTextCommandSetBlipName(blip)
                            _blipsList[serverId] = blip
                        end
                    end
                end
            end
            for serverId, blip in pairs(_blipsList) do
                if not seen[serverId] then
                    if DoesBlipExist(blip) then RemoveBlip(blip) end
                    _blipsList[serverId] = nil
                end
            end
            Wait(2000)
        end
        _clearStaffBlips()
    end)
end, false)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then
        _blipsActive = false
        _clearStaffBlips()
    end
end)

RegisterCommand("screenshot", function(_, args)
    if not StaffMenu.adminChecked then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Screenshot', message = "Vous devez être en mode staff." })
        return
    end
    if not VFW.HasStaffPerm("staff_menu") then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Screenshot', message = "Permission insuffisante." })
        return
    end

    local targetId = tonumber(args and args[1])
    if not targetId then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Screenshot', message = "Utilisation: /screenshot [id]" })
        return
    end

    local info = TriggerServerCallback("vfw:staff:getPlayerInfo", targetId)
    if not info or not info.source or info.source == 0 then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Screenshot', message = "Joueur introuvable." })
        return
    end

    TriggerServerEvent("vfw:staff:takeScreenshot", targetId, {
        name = info.name,
        visaId = info.id
    })
end, false)

RegisterCommand("hud", function()
    if not VFW.HasStaffPerm("staff_menu") then return end
    if not VFW.IsInStaffMode() then
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'ERROR',
            subtitle = 'Info Joueur',
            message = "Vous devez être en mode staff pour utiliser cette commande."
      })
        return
    end

    local newState = not (StaffMenu.playerInfoCrosshairActive or false)
    if StaffMenu.TogglePlayerInfoCrosshair then
        StaffMenu.TogglePlayerInfoCrosshair(newState)
    end
end, false)

RegisterNetEvent("vfw:staff:forceDisableStaffMode", function()
    if not StaffMenu.adminChecked then return end

    if VFW.IsNoclipActive() then
        VFW.ToggleNoclip()
    end

    StaffMenu.adminChecked = false

    if ToggleStaffHUD then
        ToggleStaffHUD(false)
    end
    if StaffMenu.ToggleVehicleSpeedTags then
        StaffMenu.ToggleVehicleSpeedTags(false)
    end
    if StaffMenu.TogglePlayerInfoCrosshair then
        StaffMenu.TogglePlayerInfoCrosshair(false)
    end
    if StaffMenu.CleanupPersonalState then
        StaffMenu.CleanupPersonalState()
    end
    StaffMenu.animatorSettings.noclipActive = false

    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'ERROR',
        subtitle = 'Mode Staff',
        message = "Mode staff désactivé : permissions insuffisantes."
  })
end)

RegisterNetEvent("vfw:animator:forceDisableAnimatorMode", function()
    if not StaffMenu.animatorModeEnabled then return end

    if VFW.IsNoclipActive() and not StaffMenu.adminChecked then
        VFW.ToggleNoclip()
    end

    StaffMenu.animatorModeEnabled = false

    if ToggleAnimatorHUD then
        ToggleAnimatorHUD(false)
    end

    if StaffMenu.animatorSettings and StaffMenu.animatorSettings.animatorOutfit then
        StaffMenu.animatorSettings.animatorOutfit = false
        TriggerServerEvent("vfw:staff:setAnimatorOutfit", false)
    end

    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'ERROR',
        subtitle = 'Mode Animateur',
        message = "Mode animateur désactivé : permissions insuffisantes."
  })
end)

