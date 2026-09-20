---@meta _
---@diagnostic disable: duplicate-doc-field

local function GetStaffTitle()
    return StaffMenu.menuContext == 'animator' and VFW.AnimatorTitle() or VFW.StaffTitle()
end

local personalState = {
    shadowTrace = false,
    invincible = false,
    invincibleThread = false,
    invisible = false,
    openAllDoors = false,
    originalPed = nil,
    originalSkin = nil,
    blipsActive = false,
    blipsThread = false,
    playerInfoThread = false,
}

-- État accessible depuis _manager.lua (optionsStaff)
StaffMenu.playerInfoCrosshairActive = false

function StaffMenu.TogglePlayerInfoCrosshair(_checked)
    StaffMenu.playerInfoCrosshairActive = _checked
    if not _checked then
        SendNUIMessage({ action = "staff:crosshair:hide" })
        return
    end
    if not personalState.playerInfoThread then
        personalState.playerInfoThread = true
        CreateThread(function()
            local lastTargetServerId = nil
            local fetchCooldown = 0
            while StaffMenu.playerInfoCrosshairActive do
                if VFW.IsInStaffMode() then
                    local hit, _, entity = GetEntityPlayerIsLookingAt(15.0)
                    if hit and entity ~= 0 and IsPedAPlayer(entity) then
                        local targetServerId = nil
                        for _, playerId in ipairs(GetActivePlayers()) do
                            if GetPlayerPed(playerId) == entity then
                                targetServerId = GetPlayerServerId(playerId)
                                break
                            end
                        end

                        if targetServerId and targetServerId ~= GetPlayerServerId(PlayerId()) then
                            local now = GetGameTimer()
                            if targetServerId ~= lastTargetServerId or now - fetchCooldown > 3000 then
                                lastTargetServerId = targetServerId
                                fetchCooldown = now
                                local info = TriggerServerCallback("vfw:staff:getPlayerInfo", targetServerId)
                                if info and StaffMenu.playerInfoCrosshairActive then
                                    SendNUIMessage({
                                        action = "staff:crosshair:show",
                                        data = {
                                            pseudo      = info.pseudo or "Inconnu",
                                            firstName   = info.firstName,
                                            lastName    = info.lastName,
                                            job         = info.job or "Civil",
                                            jobName     = info.jobName or "unemployed",
                                            grade       = info.grade or "Aucun",
                                            faction     = info.faction or "Aucun",
                                            factionGrade = info.factionGrade,
                                        }
                                    })
                                end
                            end
                        else
                            if lastTargetServerId then
                                lastTargetServerId = nil
                                SendNUIMessage({ action = "staff:crosshair:hide" })
                            end
                        end
                    else
                        if lastTargetServerId then
                            lastTargetServerId = nil
                            SendNUIMessage({ action = "staff:crosshair:hide" })
                        end
                    end
                else
                    -- Sortie du mode staff : désactiver proprement
                    StaffMenu.playerInfoCrosshairActive = false
                    SendNUIMessage({ action = "staff:crosshair:hide" })
                end
                Wait(300)
            end
            SendNUIMessage({ action = "staff:crosshair:hide" })
            personalState.playerInfoThread = false
        end)
    end
end

-- Reset personal toggles when leaving staff/animator mode so godmode/invisibility
-- don't leak after the player closes the menu.
function StaffMenu.CleanupPersonalState()
    if personalState.invincible then
        personalState.invincible = false
        local ped = PlayerPedId()
        SetEntityInvincible(ped, false)
        SetPedCanRagdoll(ped, true)
        SetPedCanRagdollFromPlayerImpact(ped, true)
    end
    if personalState.invisible then
        personalState.invisible = false
        SetEntityVisible(PlayerPedId(), true, false)
        TriggerServerEvent("vfw:stafflogs:invisibleState", false)
    end
    if personalState.blipsActive then
        personalState.blipsActive = false
    end
end

-- Store original ped data when admin mode is activated
RegisterNetEvent("vfw:staff:storeOriginalPed")
AddEventHandler("vfw:staff:storeOriginalPed", function()
    local ped = PlayerPedId()
    personalState.originalPed = GetEntityModel(ped)
    personalState.originalSkin = {}

    for i = 0, 11 do
        personalState.originalSkin["comp_" .. i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
            palette = GetPedPaletteVariation(ped, i)
        }
    end

    for i = 0, 7 do
        personalState.originalSkin["prop_" .. i] = {
            drawable = GetPedPropIndex(ped, i),
            texture = GetPedPropTextureIndex(ped, i)
        }
    end
end)

--- Build Personal Actions Menu
function StaffMenu.BuildPersonalActionsMenu()
    StaffMenu.personalActions.ClearItems()
    local perms = VFW.StaffPerms()
    -- Menu déjà ouvert via F10 : les actions sur soi doivent apparaître.
    if VFW.HasStaffPerm("staff_menu") or VFW.HasStaffPerm("menu_anim") then
        perms = VFW.BuildFullPermissions()
    end

    -- ══ DÉPLACEMENT & MODES ══
    if perms["noclip"] or perms["menu_anim"] then
        StaffMenu.personalActions.Checkbox(":rocket: NOCLIP", "Voler librement à travers les murs et le décor. Raccourci : F2", false, VFW.IsNoclipActive(), function(_checked)
            VFW.ToggleNoclip()
            if StaffMenu.animatorSettings then
                Wait(100)
                StaffMenu.animatorSettings.noclipActive = VFW.IsNoclipActive()
            end
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Actions Personnelles', message = _checked and "Noclip activé." or "Noclip désactivé." })
        end)
    end

    if perms["godmod_invisible"] or perms["menu_anim"] then
        StaffMenu.personalActions.Checkbox(":shield: INVINCIBILITÉ", "Rendre votre personnage invulnérable aux dégâts", false, personalState.invincible, function(_checked)
            personalState.invincible = _checked
            if _checked then
                local ped = PlayerPedId()
                SetEntityInvincible(ped, true)
                SetPedCanRagdoll(ped, false)
                SetPedCanRagdollFromPlayerImpact(ped, false)
                if not personalState.invincibleThread then
                    personalState.invincibleThread = true
                    CreateThread(function()
                        while personalState.invincible do
                            local p = PlayerPedId()
                            -- Ne pas écraser l'état pendant un KO : laisser le système death gérer
                            -- la santé / l'invincibilité et la transition de sortie.
                            local koActive = LocalPlayer.state and LocalPlayer.state.isKnockedOut
                            if not koActive then
                                SetEntityInvincible(p, true)
                                SetPedCanRagdoll(p, false)
                                SetPedCanRagdollFromPlayerImpact(p, false)
                                local maxHp = GetEntityMaxHealth(p)
                                if GetEntityHealth(p) < maxHp then
                                    SetEntityHealth(p, maxHp)
                                end
                            end
                            Wait(50)
                        end
                        -- Restaurer l'état normal à la désactivation
                        local p = PlayerPedId()
                        SetEntityInvincible(p, false)
                        SetPedCanRagdoll(p, true)
                        SetPedCanRagdollFromPlayerImpact(p, true)
                        personalState.invincibleThread = false
                    end)
                end
            else
                -- Le thread se chargera de restaurer l'état
                local ped = PlayerPedId()
                SetEntityInvincible(ped, false)
                SetPedCanRagdoll(ped, true)
                SetPedCanRagdollFromPlayerImpact(ped, true)
            end
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Actions Personnelles', message = _checked and "Invincibilité activée." or "Invincibilité désactivée." })
        end)

        StaffMenu.personalActions.Checkbox(":eye: INVISIBILITÉ", "Rendre votre personnage invisible aux autres joueurs", false, personalState.invisible, function(_checked)
            personalState.invisible = _checked
            SetEntityVisible(PlayerPedId(), not _checked, false)
            TriggerServerEvent("vfw:stafflogs:invisibleState", _checked)
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Actions Personnelles', message = _checked and "Invisibilité activée." or "Invisibilité désactivée." })
        end)
    end

    if perms["alt_teleport"] or perms["menu_anim"] then
        StaffMenu.personalActions.Button(":flag: TÉLÉPORTATION MARKER", "Se téléporter instantanément sur votre point GPS actif", nil, "arrow", false, function()
            TriggerEvent("vfw:tpm")
        end)

        StaffMenu.personalActions.Button(":pin: TÉLÉPORTATION", "Accéder aux options de téléportation (marker, plaque, coords, lieux)", nil, "chevron", false, function()
        end, StaffMenu.personalTeleport)
    end

    if perms["goto_vehicle"] or perms["menu_anim"] then
        StaffMenu.personalActions.Button(":car: ALLER AU VÉHICULE", "Se téléporter vers un véhicule par sa plaque d'immatriculation", nil, "arrow", false, function()
            VFW.Nui.Focus(true)
            local plate = VFW.Nui.KeyboardInput(true, "Plaque d'immatriculation", "", 8)
            if plate == nil or plate == "" or plate == "KBD_CANCEL" then return end
            plate = string.upper(VFW.Math.Trim(plate))
            TriggerServerEvent("vfw:staff:gotoVehicle", plate)
        end)
    end

    if perms["bring_vehicle"] or perms["menu_anim"] then
        StaffMenu.personalActions.Button(":bolt: RAMENER UN VÉHICULE", "Téléporter un véhicule vers soi par sa plaque d'immatriculation", nil, "arrow", false, function()
            VFW.Nui.Focus(true)
            local plate = VFW.Nui.KeyboardInput(true, "Plaque d'immatriculation", "", 8)
            if plate == nil or plate == "" or plate == "KBD_CANCEL" then return end
            plate = string.upper(VFW.Math.Trim(plate))
            TriggerServerEvent("vfw:staff:bringVehicle", plate)
        end)
    end

    StaffMenu.personalActions.Separator(nil)

    -- ══ AFFICHAGE ══
    if perms["show_gamertag"] or perms["menu_anim"] then
        StaffMenu.personalActions.Checkbox(":tag: GAMERTAGS", "Afficher les tags des joueurs avec leur ID au-dessus de leur tête", false, VFW.IsGamerTagsActive(), function(_checked)
            SetResourceKvp("staff_gamer_tags", _checked and "true" or "false")
            TriggerServerEvent("Admin:activeBlips", _checked)
            TriggerServerEvent("Admin:gamerTag", _checked)
            if StaffMenu.animatorSettings then StaffMenu.animatorSettings.showNameTags = _checked end
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Actions Personnelles', message = _checked and "Gamertags activés." or "Gamertags désactivés." })
        end)
    end

    if perms["show_nametag"] or perms["menu_anim"] then
        StaffMenu.personalActions.Checkbox(" NAMETAGS", "Afficher les noms RP des joueurs au-dessus de leur tête", false, StaffMenu.showRPNamesOnPlayerTags, function(_checked)
            StaffMenu.showRPNamesOnPlayerTags = _checked
            SetResourceKvp("staff_name_tags", _checked and "true" or "false")
            VFW.UpdateAllGamerTags()
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Actions Personnelles', message = _checked and "Nametags activés." or "Nametags désactivés." })
        end)
    end

    if perms["spectate"] or perms["menu_anim"] then
        local randomSpectateActive = StaffMenu.outilsState and StaffMenu.outilsState.Spectate or false
        StaffMenu.personalActions.Checkbox(":gamepad: SPECTATE ALÉATOIRE", "Observer un joueur aléatoire (les AFK sont exclus automatiquement, noclip requis)", false, randomSpectateActive, function(_checked)
            if _checked and not VFW.IsNoclipActive() then
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Actions Personnelles', message = "Vous devez être en noclip pour spectate." })
                if StaffMenu.outilsState then StaffMenu.outilsState.Spectate = false end
                StaffMenu.personalActions.refresh()
                return
            end
            if StaffMenu.outilsState then StaffMenu.outilsState.Spectate = _checked end
            if _checked then
                local players = StaffMenu.FetchPlayerList(false) or {}
                local validPlayers = {}
                local selfId = GetPlayerServerId(PlayerId())
                for _, p in pairs(players) do
                    -- Skip self et joueurs AFK (instance != 0)
                    if p and p.source and p.source ~= selfId and (not p.instance or p.instance == 0) then
                        table.insert(validPlayers, p)
                    end
                end
                if #validPlayers == 0 then
                    VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Actions Personnelles', message = "Aucun joueur disponible (hors AFK)." })
                    if StaffMenu.outilsState then StaffMenu.outilsState.Spectate = false end
                    StaffMenu.personalActions.refresh()
                    return
                end
                local randomPlayer = validPlayers[math.random(1, #validPlayers)].source
                StaffMenu.LastPlayerSource = randomPlayer
                if StaffMenu.SpectatePlayer then StaffMenu.SpectatePlayer(randomPlayer, true)
                else TriggerServerEvent("core:StaffSpectate", randomPlayer, true) end
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Actions Personnelles', message = "Spectate aléatoire activé sur le joueur " .. randomPlayer .. "." })
            else
                if StaffMenu.StopSpectate then StaffMenu.StopSpectate()
                elseif StaffMenu.LastPlayerSource then TriggerServerEvent("core:StaffSpectate", StaffMenu.LastPlayerSource, false) end
                StaffMenu.LastPlayerSource = nil
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'INFO', subtitle = 'Actions Personnelles', message = "Spectate aléatoire désactivé." })
            end
        end)
    end

    if perms["show_coords"] or perms["menu_anim"] then
        StaffMenu.personalActions.Checkbox(":pin: AFFICHER COORDONNÉES", "Afficher vos coordonnées X Y Z en temps réel à l'écran", false, StaffMenu.outilsState and StaffMenu.outilsState.showCoords or false, function(_checked)
            if StaffMenu.outilsState then StaffMenu.outilsState.showCoords = _checked end
            StaffMenu.EnableCoords(_checked)
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Actions Personnelles', message = _checked and "Coordonnées activées." or "Coordonnées désactivées." })
        end)
    end

    -- Blips joueurs sur la minimap (rayon 1km)
    if perms["show_gamertag"] or perms["blips_joueurs"] or perms["menu_anim"] then
        StaffMenu.personalActions.Checkbox(":signal: BLIPS JOUEURS", "Afficher les blips des joueurs sur la minimap dans un rayon de 1km", false, personalState.blipsActive, function(_checked)
            personalState.blipsActive = _checked
            if _checked then
                if not personalState.blipsThread then
                    personalState.blipsThread = true
                    personalState.playerBlips = {}
                    CreateThread(function()
                        while personalState.blipsActive do
                            local myCoords = GetEntityCoords(PlayerPedId())
                            local activePlayers = GetActivePlayers()
                            local newBlips = {}

                            for _, playerId in ipairs(activePlayers) do
                                if playerId ~= PlayerId() then
                                    local targetPed = GetPlayerPed(playerId)
                                    if DoesEntityExist(targetPed) then
                                        local targetCoords = GetEntityCoords(targetPed)
                                        local dist = #(myCoords - targetCoords)
                                        if dist <= 1000.0 then
                                            local serverId = GetPlayerServerId(playerId)
                                            local blip = personalState.playerBlips[serverId]
                                            if not blip or not DoesBlipExist(blip) then
                                                blip = AddBlipForEntity(targetPed)
                                                SetBlipSprite(blip, 1)
                                                SetBlipScale(blip, 0.5)
                                                SetBlipColour(blip, 0)
                                                SetBlipAsShortRange(blip, true)
                                                BeginTextCommandSetBlipName("STRING")
                                                AddTextComponentString(GetPlayerName(playerId) .. " [" .. serverId .. "]")
                                                EndTextCommandSetBlipName(blip)
                                            end
                                            newBlips[serverId] = blip
                                        end
                                    end
                                end
                            end

                            -- Remove blips for players no longer in range
                            for serverId, blip in pairs(personalState.playerBlips) do
                                if not newBlips[serverId] and DoesBlipExist(blip) then
                                    RemoveBlip(blip)
                                end
                            end
                            personalState.playerBlips = newBlips
                            Wait(2000)
                        end

                        -- Cleanup all blips when disabled
                        for _, blip in pairs(personalState.playerBlips or {}) do
                            if DoesBlipExist(blip) then RemoveBlip(blip) end
                        end
                        personalState.playerBlips = {}
                        personalState.blipsThread = false
                    end)
                end
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Actions Personnelles', message = "Blips joueurs activés (rayon 1km)." })
            else
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'INFO', subtitle = 'Actions Personnelles', message = "Blips joueurs désactivés." })
            end
        end)
    end

    StaffMenu.personalActions.Separator(nil)

    -- ══ SANTÉ & SURVIE ══
    if perms["heal"] or perms["menu_anim"] then
        StaffMenu.personalActions.List2(":cart: REMPLIR", "Remplir votre faim, votre soif ou les deux en une action", false, { "Faim", "Soif", "Les deux" }, 3, nil, function(index, item)
            if item == "Faim" then
                TriggerServerEvent("vfw:staff:selfFillNeeds", "hunger")
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Actions Personnelles', message = "Faim remplie." })
            elseif item == "Soif" then
                TriggerServerEvent("vfw:staff:selfFillNeeds", "thirst")
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Actions Personnelles', message = "Soif remplie." })
            elseif item == "Les deux" then
                TriggerServerEvent("vfw:staff:selfFillNeeds", "both")
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Actions Personnelles', message = "Faim et soif remplies." })
            end
        end)

        StaffMenu.personalActions.Button(":heart: SE HEAL", "Restaurer votre santé au maximum", nil, "heart", false, function()
            SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Actions Personnelles', message = "Santé régénérée." })
        end)
    end

    if perms["revive"] or perms["menu_anim"] then
        StaffMenu.personalActions.Button(":dot-green: SE REVIVE", "Se ranimer si vous êtes mort ou KO", nil, "heart", false, function()
            local myId = GetPlayerServerId(PlayerId())
            TriggerServerEvent("vfw:staff:revivePlayer", myId)
        end)
    end

    if perms["kill"] or perms["menu_anim"] then
        StaffMenu.personalActions.Button(":skull: SE KILL", "Se suicider immédiatement (utile pour reset une situation)", nil, "arrow", false, function()
            VFW.DeathOverrideCause = "suicide"
          SetEntityHealth(PlayerPedId(), 0)
            TriggerServerEvent("vfw:stafflogs:selfKill")
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'INFO', subtitle = 'Actions Personnelles', message = "Vous vous êtes tué." })
        end)
    end

    if perms["godmod_invisible"] or perms["menu_anim"] then
        local ped = PlayerPedId()
        local hasArmor = GetPedArmour(ped) > 0
        local label = hasArmor and ":shield: RETIRER LE BOUCLIER" or ":shield: SE METTRE DU BOUCLIER"
      local subtitle = hasArmor and "Retirer votre armure" or "Remplir votre armure a 100%"
      StaffMenu.personalActions.Button(label, subtitle, nil, "chevron", false, function()
            local p = PlayerPedId()
            if GetPedArmour(p) > 0 then
                SetPedArmour(p, 0)
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'INFO', subtitle = 'Actions Personnelles', message = "Armure retirée." })
            else
                SetPedArmour(p, 100)
                VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Actions Personnelles', message = "Armure complète." })
            end
            StaffMenu.personalActions.refresh()
        end)
    end
end

--- Build Personal Teleport Menu
function StaffMenu.BuildPersonalTeleportMenu()
    StaffMenu.personalTeleport.Separator(":pin: TÉLÉPORTATION")

    StaffMenu.personalTeleport.Button(":flag: TP SUR LE MARQUEUR", "Se téléporter sur le point GPS", nil, "arrow", false, function()
        TriggerEvent("vfw:tpm")
    end)

    StaffMenu.personalTeleport.Button(":car: TP SUR UN VÉHICULE", "Par plaque d'immatriculation", nil, "arrow", false, function()
        VFW.Nui.Focus(true)
        local plate = VFW.Nui.KeyboardInput(true, "Plaque d'immatriculation", "", 8)
        if plate == nil or plate == "" or plate == "KBD_CANCEL" then return end
        plate = string.upper(VFW.Math.Trim(plate))
        TriggerServerEvent("vfw:staff:tpToVehicle", plate)
    end)


    StaffMenu.personalTeleport.Button(":globe: TP AUX COORDONNÉES", "Entrer des coordonnées X, Y, Z", nil, "arrow", false, function()
        VFW.Nui.Focus(true)
        local xInput = VFW.Nui.KeyboardInput(true, "Coordonnée X", "")
        if not xInput then return end
        xInput = tostring(xInput)
        if xInput == "" or xInput == "KBD_CANCEL" then return end

        local yInput = VFW.Nui.KeyboardInput(true, "Coordonnée Y", "")
        if not yInput then return end
        yInput = tostring(yInput)
        if yInput == "" or yInput == "KBD_CANCEL" then return end

        local zInput = VFW.Nui.KeyboardInput(true, "Coordonnée Z", "")
        if not zInput then return end
        zInput = tostring(zInput)
        if zInput == "" or zInput == "KBD_CANCEL" then return end

        local x = tonumber((xInput:gsub(",", ".")))
        local y = tonumber((yInput:gsub(",", ".")))
        local z = tonumber((zInput:gsub(",", ".")))
        if x and y and z then
            SetEntityCoords(PlayerPedId(), x, y, z, false, false, false, false)
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Téléportation', message = string.format("Téléporté : %.2f, %.2f, %.2f", x, y, z) })
        else
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Téléportation', message = "Ces coordonnées ne sont pas valides." })
        end
    end)

    StaffMenu.personalTeleport.Separator(nil)

    StaffMenu.personalTeleport.Button(":plus: AJOUTER UN POINT DE TP", "Enregistrer votre position actuelle comme point de téléportation personnalisé", nil, nil, false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom du point", "")
        if not name or name == "" then return end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        local data = GetResourceKvpString("staff_custom_teleports")
        local teleports = (data and data ~= "") and json.decode(data) or {}
        table.insert(teleports, {
            name = name,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            heading = heading,
        })
        SetResourceKvp("staff_custom_teleports", json.encode(teleports))

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Téléportation',
            message = 'Point "' .. name .. '" sauvegardé.'
        })

        StaffMenu.personalTeleport.refresh()
    end)

    if StaffMenu.BuildCustomTeleportLocations then
        StaffMenu.BuildCustomTeleportLocations()
    end
end

--- Build Personal Appearance Menu
function StaffMenu.BuildPersonalAppearanceMenu()
    StaffMenu.personalAppearance.Separator(":user: APPARENCE")

    local quickPeds = {
        {name = "MP Male", model = "mp_m_freemode_01"},
        {name = "MP Female", model = "mp_f_freemode_01"},
        {name = "Policier", model = "s_m_y_cop_01"},
        {name = "SWAT", model = "s_m_y_swat_01"},
        {name = "Pompier", model = "s_m_y_fireman_01"},
        {name = "Médecin", model = "s_m_m_doctor_01"},
        {name = "Clown", model = "s_m_y_clown_01"},
        {name = "Zombie", model = "u_m_y_zombie_01"}
    }

    for _, ped in ipairs(quickPeds) do
        StaffMenu.personalAppearance.Button(":user: " .. ped.name, ped.model, nil, nil, false, function()
            ChangePedModel(ped.model)
        end)
    end

    StaffMenu.personalAppearance.Separator(":palette: OPTIONS")

    StaffMenu.personalAppearance.Button(":gamepad: PED ALÉATOIRE", "Changer votre apparence avec un ped sélectionné aléatoirement", nil, "chevron", false, function()
        local randomPeds = {
            "a_m_y_hipster_01", "a_f_y_hipster_01", "s_m_y_cop_01", "s_f_y_cop_01",
            "g_m_y_ballaorig_01", "a_m_y_beach_01", "s_m_y_clown_01", "u_m_y_zombie_01",
            "a_m_y_business_01", "s_m_y_fireman_01", "s_m_m_doctor_01", "s_m_y_swat_01"
      }
        ChangePedModel(randomPeds[math.random(1, #randomPeds)])
    end)

    StaffMenu.personalAppearance.Button(":trash: NETTOYER LE PED", "Supprimer le sang, la saleté et les dégâts visuels de votre ped", nil, "chevron", false, function()
        local playerPed = PlayerPedId()
        ClearPedBloodDamage(playerPed)
        ClearPedWetness(playerPed)
        ClearPedEnvDirt(playerPed)
        ResetPedVisibleDamage(playerPed)
        VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Apparence', message = "Ped nettoyé." })
    end)
end

-- Helper function to change ped model
function ChangePedModel(modelName)
    local model = GetHashKey(modelName)
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Apparence', message = "Ce modèle n'est pas valide : " .. modelName })
        return
    end
    -- SetPlayerModel détruit l'ancien ped et recrée un net object: tout handle
    -- capturé par le noclip/spectate (targetped) devient stale et provoque un
    -- crash réseau au prochain Attach/NetworkSet*.
    if VFW.IsNoclipActive and VFW.IsNoclipActive() then
        if VFW.StopNoclipSilent then VFW.StopNoclipSilent() end
    end
    if not personalState.originalPed then
        TriggerEvent("vfw:staff:storeOriginalPed")
    end
    RequestModel(model)
    local loadWait = 0
    while not HasModelLoaded(model) and loadWait < 5000 do
        Wait(50)
        loadWait = loadWait + 50
    end
    if not HasModelLoaded(model) then
        SetModelAsNoLongerNeeded(model)
        VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Apparence', message = "Le modèle n'a pas pu être chargé à temps : " .. modelName })
        return
    end

    -- Freeze pendant le swap : sans ça le ped continue d'émettre des updates de
    -- position pendant la destruction/recréation du net object → crash réseau
    -- côté voisins (GTA5+1691021 / september-ceiling-network).
    local oldPed = PlayerPedId()
    FreezeEntityPosition(oldPed, true)
    SetEntityInvincible(oldPed, true)

    SetPlayerModel(PlayerId(), model)

    local newPed = PlayerPedId()
    local timeout = 0
    while (not newPed or newPed == 0 or not DoesEntityExist(newPed)) and timeout < 30 do
        Wait(50)
        newPed = PlayerPedId()
        timeout = timeout + 1
    end
    if newPed and newPed ~= 0 and IsPedHuman(newPed) then
        SetPedDefaultComponentVariation(newPed)
    end
    SetModelAsNoLongerNeeded(model)

    Wait(500)
    if newPed and newPed ~= 0 then
        FreezeEntityPosition(newPed, false)
        SetEntityInvincible(newPed, false)
        SetEntityHealth(newPed, GetEntityMaxHealth(newPed))
    end
    VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Apparence', message = "Ped changé : " .. modelName })
end

-- Helper function to restore original ped
function RestoreOriginalPed()
    if personalState.originalPed then
        local model = personalState.originalPed
        if not IsModelInCdimage(model) or not IsModelValid(model) then
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Apparence', message = "Ce modèle d'origine n'est pas valide." })
            return
        end
        if VFW.IsNoclipActive and VFW.IsNoclipActive() then
            if VFW.StopNoclipSilent then VFW.StopNoclipSilent() end
        end
        RequestModel(model)
        local loadWait = 0
        while not HasModelLoaded(model) and loadWait < 5000 do
            Wait(50)
            loadWait = loadWait + 50
        end
        if not HasModelLoaded(model) then
            SetModelAsNoLongerNeeded(model)
            VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Apparence', message = "Le modèle d'origine n'a pas pu être chargé à temps." })
            return
        end

        local oldPed = PlayerPedId()
        FreezeEntityPosition(oldPed, true)
        SetEntityInvincible(oldPed, true)

        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)

        local ped = PlayerPedId()
        local timeout = 0
        while (not ped or ped == 0 or not DoesEntityExist(ped)) and timeout < 30 do
            Wait(50)
            ped = PlayerPedId()
            timeout = timeout + 1
        end

        if personalState.originalSkin then
            for i = 0, 11 do
                local comp = personalState.originalSkin["comp_" .. i]
                if comp then SetPedComponentVariation(ped, i, comp.drawable, comp.texture, comp.palette) end
            end
            for i = 0, 7 do
                local prop = personalState.originalSkin["prop_" .. i]
                if prop then
                    if prop.drawable == -1 then ClearPedProp(ped, i)
                    else SetPedPropIndex(ped, i, prop.drawable, prop.texture, true) end
                end
            end
        end

        Wait(500)
        if ped and ped ~= 0 then
            FreezeEntityPosition(ped, false)
            SetEntityInvincible(ped, false)
            SetEntityHealth(ped, GetEntityMaxHealth(ped))
        end
        VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Apparence', message = "Ped restauré." })
    else
        TriggerServerEvent("vfw:staff:resetPed")
        VFW.ShowNotification({ type = 'STAFF', title = GetStaffTitle(), variant = 'INFO', subtitle = 'Apparence', message = "Ped réinitialisé via le serveur." })
    end
end

-- Helper function to get entity player is looking at
function GetEntityPlayerIsLookingAt(distance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local endCoords = coords + forward * distance
    local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z, endCoords.x, endCoords.y, endCoords.z, -1, ped, 0)
    local _, hit, hitCoords, _, entityHit = GetShapeTestResult(rayHandle)
    return hit == 1, hitCoords, entityHit
end
