-- ==========================================
--        MENU F3 VIP - Vision V2
-- ==========================================

-- Menu creation
local VUI = exports["VUI"]
local vipBanner = exports["core"]:GetVUIBanner("vip")
local vipMain = VUI:CreateMenu("Menu VIP", vipBanner, true)

-- Submenus
local vipVehicleGpsMenu = VUI:CreateSubMenu(vipMain, "Localiser un véhicule", vipBanner, true)
local vipMonthlyVehicleMenu = VUI:CreateSubMenu(vipMain, "Véhicule du mois", vipBanner, true)
local propsBuilderMenu = VUI:CreateSubMenu(vipMain, "Placer des objets", vipBanner, true)
local createVipPropMenu = VUI:CreateSubMenu(propsBuilderMenu, "Créer un objet", vipBanner, true)
local categorySelectionMenu = VUI:CreateSubMenu(createVipPropMenu, "Catégories", vipBanner, true)
local manageMyPropsMenu = VUI:CreateSubMenu(propsBuilderMenu, "Gérer mes objets", vipBanner, true)
local vipPlateChangeMenu = VUI:CreateSubMenu(vipMain, "Changer de plaque", vipBanner, true)
local vipWeaponCustomMenu = VUI:CreateSubMenu(vipMain, "Personnaliser mes armes", vipBanner, true)

-- Variable for GPS blip
local _vipGpsBlip = nil

-- Drift mode state
local _vipDriftEnabled = false

-- Helper to check if player is VIP (vip_tier is source of truth, permissions as fallback)
local function isPlayerVip()
    if not VFW.PlayerGlobalData then return false end
    if (VFW.PlayerGlobalData.vip_tier or 0) > 0 then return true end
    local perms = VFW.PlayerGlobalData.permissions
    if not perms then return false end
    return perms["vip_bronze"] or perms["vip_silver"] or perms["vip_gold"] or false
end

-- Helper to set VIP banner based on tier
local function setVipBanner(menu)
    menu.ChangeBanner(vipBanner)
end

-- Listen for VIP status updates from server
RegisterNetEvent('vip:updateStatus', function(data)
    if VFW.PlayerGlobalData then
        VFW.PlayerGlobalData.vip_tier = data.tier or 0
    end
end)

-- GPS blip creation function
local function createVipGpsBlip(veh)
    -- Remove previous VIP GPS blip if exists
    if _vipGpsBlip and DoesBlipExist(_vipGpsBlip) then
        RemoveBlip(_vipGpsBlip)
    end

    _vipGpsBlip = AddBlipForCoord(veh.pos.x, veh.pos.y, veh.pos.z)
    SetBlipSprite(_vipGpsBlip, VIPConfig.VehicleTracking.blipSprite)
    SetBlipColour(_vipGpsBlip, VIPConfig.VehicleTracking.blipColor)
    SetBlipScale(_vipGpsBlip, VIPConfig.VehicleTracking.blipScale)
    SetBlipRoute(_vipGpsBlip, VIPConfig.VehicleTracking.showRoute)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(veh.model or "Mon véhicule")
    EndTextCommandSetBlipName(_vipGpsBlip)

    TriggerEvent("vfw:showNotification", {type = 'VERT', content = string.format("GPS activé vers votre %s (%s)", veh.model or "véhicule", veh.plate)})

    SetTimeout(VIPConfig.VehicleTracking.blipDuration or 60000, function()
        if _vipGpsBlip and DoesBlipExist(_vipGpsBlip) then
            RemoveBlip(_vipGpsBlip)
            _vipGpsBlip = nil
        end
    end)
end

-- ==========================================
--         MAIN MENU RENDERING
-- ==========================================

-- Helper to show VIP preview panel
local function showVipPreview(menu)
    local tier = tonumber(VFW.PlayerGlobalData.vip_tier) or 0

    -- Fallback: derive tier from permissions if vip_tier is 0 but player has VIP permissions
    if tier == 0 and VFW.PlayerGlobalData.permissions then
        if VFW.PlayerGlobalData.permissions["vip_gold"] then
            tier = 3
        elseif VFW.PlayerGlobalData.permissions["vip_silver"] then
            tier = 2
        elseif VFW.PlayerGlobalData.permissions["vip_bronze"] then
            tier = 1
        end
    end

    local tierInfo = VIPConfig.Tiers[tier] or VIPConfig.Tiers[0]
    local tierLabel = tierInfo and tierInfo.label or "N/A"
    local tierColor = tierInfo and tierInfo.color or "#808080"
    local spacecoins = VFW.PlayerGlobalData.spacecoins or 0

    -- Fetch dynamic values from server (DB-overridden)
    local serverCfg = TriggerServerCallback("vip:getTierValues", tier)

    local weight, slots, stateAid, hourlyCoins, monthlyCoins, impoundDiscount, propsLimits, interimMult, gofastMult, drugMult, trunkBonus, dynastyBonus, ppaLeger, ppaLourd, plateChanges, emergencyVehicle, driftMode

    -- Helper to format multiplier without unnecessary decimals
    local function formatMult(v)
        if v == math.floor(v) then
            return tostring(math.floor(v))
        else
            return string.format("%.1f", v)
        end
    end

    if serverCfg and serverCfg.success then
        local cfg = serverCfg.config
        weight = cfg.inventoryWeight or 30
        stateAid = cfg.stateAid or 0
        hourlyCoins = cfg.hourlyCoins or 0
        monthlyCoins = cfg.monthlyCoins or 0
        impoundDiscount = cfg.impoundDiscount or 0
        trunkBonus = cfg.trunkBonus or 0
        dynastyBonus = cfg.dynastyBonus or 0
        propsLimits = { permanent = cfg.propsPermanent or 0, temporary = cfg.propsTemporary or 0 }
        interimMult = cfg.interimMultiplier or 1
        gofastMult = cfg.gofastMultiplier or 1
        drugMult = cfg.drugDealingMultiplier or 1
        ppaLeger = (cfg.ppaLeger or 0) == 1
        ppaLourd = (cfg.ppaLourd or 0) == 1
        plateChanges = cfg.plate_changes_per_month or 0
        emergencyVehicle = cfg.emergency_vehicle_label or ""
        driftMode = (cfg.driftMode or 0) == 1
        weaponCustom = (cfg.weaponCustomization or 0) == 1
        freecam = (cfg.freecam or 0) == 1
    else
        weight = VIPConfig.InventoryWeight[tier] or VIPConfig.InventoryWeight[0] or 30
        stateAid = tier == 0 and (VIPConfig.StateAid and VIPConfig.StateAid.base and VIPConfig.StateAid.base.amount or 0)
            or (VIPConfig.StateAid and VIPConfig.StateAid.vip and VIPConfig.StateAid.vip.amounts and VIPConfig.StateAid.vip.amounts[tier] or 0)
        monthlyCoins = VIPConfig.MonthlyCoins[tier] or 0
        hourlyCoins = VIPConfig.HourlyCoins and VIPConfig.HourlyCoins.amounts and VIPConfig.HourlyCoins.amounts[tier] or 0
        impoundDiscount = VIPConfig.ImpoundDiscount[tier] or 0
        trunkBonus = VIPConfig.TrunkBonus[tier] or 0
        dynastyBonus = VIPConfig.DynastyBonus[tier] or 0
        propsLimits = VIPConfig.PropsLimits[tier] or VIPConfig.PropsLimits[0] or {temporary = 0, permanent = 0}
        interimMult = VIPConfig.JobBonuses.interim.speedMultiplier[tier] or 1
        gofastMult = VIPConfig.JobBonuses.gofast.speedMultiplier[tier] or 1
        drugMult = VIPConfig.JobBonuses.drugDealing.speedMultiplier[tier] or 1
        ppaLeger = tier >= (VIPConfig.WeaponPermit.minVipTier or 1)
        ppaLourd = tier >= (VIPConfig.WeaponPermit.minVipTier or 1)
        plateChanges = VIPConfig.PlateChangesPerMonth and VIPConfig.PlateChangesPerMonth[tier] or 0
        emergencyVehicle = VIPConfig.EmergencyVehicle and VIPConfig.EmergencyVehicle[tier] and VIPConfig.EmergencyVehicle[tier].label or ""
        driftMode = false
        weaponCustom = VIPConfig.WeaponCustomization and VIPConfig.WeaponCustomization.enabled and tier >= (VIPConfig.WeaponCustomization.minVipTier or 1)
        freecam = VIPConfig.Freecam and VIPConfig.Freecam.enabled and tier >= (VIPConfig.Freecam.minVipTier or 1)
    end

    slots = VIPConfig.CharacterSlots[tier] or VIPConfig.CharacterSlots[0] or 4

    local discordRole = tier > 0 and tierLabel or "Aucun"

    local previewData = {
        { label = "Poids inventaire", value = tostring(math.floor(weight)) .. " kg" },
        { label = "Personnages max", value = tostring(math.floor(slots)) .. " slots" },
        { label = "Aide d'état", value = VFW.Math.FormatMoney(math.floor(stateAid)) .. " / 30min" },
        { label = "Coins horaires", value = tostring(math.floor(hourlyCoins)) .. "/h" },
        { label = "Coins mensuels", value = tostring(math.floor(monthlyCoins)) .. "/mois" },
        { label = "Réduction fourrière", value = tostring(math.floor(impoundDiscount)) .. "%" },
        { label = "Coffre véhicule", value = "+" .. tostring(math.floor(trunkBonus)) .. "%" },
        { label = "Stockage Dynasty", value = "+" .. tostring(math.floor(dynastyBonus)) .. "%" },
        { label = "Objets temporaires", value = tostring(math.floor(propsLimits.temporary)) .. " max" },
        { label = "Objets permanents", value = tostring(math.floor(propsLimits.permanent)) .. " max" },
        { label = "Interim", value = "x" .. formatMult(interimMult) },
        { label = "Go Fast", value = "x" .. formatMult(gofastMult) },
        { label = "Vente de drogue", value = "x" .. formatMult(drugMult) },
        { label = "PPA Léger", value = ppaLeger and "Disponible" or "Non disponible" },
        { label = "PPA Lourd", value = ppaLourd and "Disponible" or "Non disponible" },
        { label = "Changements de plaque", value = tostring(math.floor(plateChanges or 0)) .. " / mois" },
        { label = "Véhicule d'urgence", value = (emergencyVehicle and emergencyVehicle ~= "" and emergencyVehicle ~= "0") and emergencyVehicle or "Non disponible" },
        { label = "Mode Drift", value = driftMode and "Disponible" or "Non disponible" },
        { label = "Perso. armes", value = weaponCustom and "Teintes & Skins" or "Non disponible" },
        { label = "FreeCam", value = freecam and "Disponible" or "Non disponible" },
        { label = "Role Discord", value = discordRole },
    }

    menu.VipPreview(tierLabel, tierColor, spacecoins, previewData)

    return { ppaLeger = ppaLeger, ppaLourd = ppaLourd, driftMode = driftMode, weaponCustom = weaponCustom, freecam = freecam }
end

vipMain.OnOpen(function()
    setVipBanner(vipMain)

    -- Show VIP info side panel (returns PPA config)
    local vipCfg = showVipPreview(vipMain)

    -- Changer de personnage
    vipMain.Button("Changer de personnage", "Retourner à la sélection", nil, nil, false, function()
        vipMain.close()
        ExecuteCommand('relog')
    end)

    -- GPS Vehicle Tracking
    if VIPConfig.VehicleTracking.enabled then
        vipMain.Button("Localiser mon véhicule", "Disponible via le téléphone (Garage)", nil, "chevron", false, function()
            vipMain.close()
            VFW.ShowNotification({ type = 'BLEU', content = "Utilisez l'application Garage de votre téléphone pour localiser vos véhicules." })
        end)
    end

    -- Vehicule du mois
    vipMain.Button("Véhicule du mois", "Recuperer votre véhicule mensuel VIP", nil, "chevron", false, function()
    end, vipMonthlyVehicleMenu)

    -- Props Builder
    vipMain.Button("Placer des objets", "Placer des objets dans le monde", nil, "chevron", false, function()
    end, propsBuilderMenu)

    -- Changer de plaque (VIP tier >= 1)
    local tier = tonumber(VFW.PlayerGlobalData.vip_tier) or 0
    if tier == 0 and VFW.PlayerGlobalData.permissions then
        if VFW.PlayerGlobalData.permissions["vip_gold"] then
            tier = 3
        elseif VFW.PlayerGlobalData.permissions["vip_silver"] then
            tier = 2
        elseif VFW.PlayerGlobalData.permissions["vip_bronze"] then
            tier = 1
        end
    end

    if tier >= 1 then
        vipMain.Button("Changer de plaque", "Changez la plaque d'immatriculation d'un de vos véhicules", nil, "chevron", false, function()
        end, vipPlateChangeMenu)
    end

    -- Véhicule d'urgence
    if tier >= 1 then
        vipMain.Button("Véhicule d'urgence", "Faites apparaître votre véhicule d'urgence VIP", nil, "chevron", false, function()
            local info = TriggerServerCallback("vip:getEmergencyVehicleModel")
            if not info or not info.success then
                VFW.ShowNotification({ type = "ROUGE", content = info and info.message or "Erreur" })
                return
            end

            if info.hasActive then
                VFW.ShowNotification({ type = "ROUGE", content = "Vous avez déjà un véhicule d'urgence en circulation." })
                return
            end

            VFW.Nui.Focus(true)
            local confirm = VFW.Nui.ConfirmPopup(
                "Véhicule d'urgence",
                "Tu as vraiment besoin de sortir ton véhicule d'urgence ? Cache-toi pour le faire afin de ne pas sortir un véhicule de nulle part devant d'autres personnes.",
                "Sortir le véhicule",
                "Annuler la sortie"
            )
            VFW.Nui.Focus(false)
            if not confirm then return end

            vipMain.close()

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            TriggerServerEvent("vip:spawnEmergencyVehicle", coords.x, coords.y, coords.z, heading)
            VFW.ShowNotification({ type = "VERT", content = "Véhicule d'urgence (" .. (info.label ~= "" and info.label or info.model) .. ") en cours d'apparition." })
        end)
    end

    -- PPA Léger (only if enabled for this tier)
    if vipCfg and vipCfg.ppaLeger then
        vipMain.Button("Récupérer PPA Léger", "Permis de port d'armes légères", nil, "chevron", false, function()
            vipMain.close()
            VIPPPA_ClaimFromMenu("leger")
        end)
    end

    -- PPA Lourd (only if enabled for this tier)
    if vipCfg and vipCfg.ppaLourd then
        vipMain.Button("Récupérer PPA Lourd", "Permis de port d'armes lourdes", nil, "chevron", false, function()
            vipMain.close()
            VIPPPA_ClaimFromMenu("lourd")
        end)
    end

    -- FreeCam
    if vipCfg and vipCfg.freecam then
        vipMain.Button("FreeCam", "Caméra libre autour de votre personnage", nil, nil, false, function()
            vipMain.close()
            activateFreeCam(false, true)
        end)
    end

    -- Personnalisation d'armes (teintes / skins)
    if vipCfg and vipCfg.weaponCustom then
        vipMain.Button("Personnaliser mes armes", "Teintes et skins cosmétiques", nil, "chevron", false, function()
        end, vipWeaponCustomMenu)
    end

    -- Mode Drift
    if vipCfg and vipCfg.driftMode then
        local driftLabel = _vipDriftEnabled and "Mode Drift (ON)" or "Mode Drift (OFF)"
        vipMain.Button(driftLabel, "Activer/désactiver le mode drift (maintenir SHIFT)", nil, "chevron", false, function()
            _vipDriftEnabled = not _vipDriftEnabled
            VFW.ShowNotification({ type = "VERT", content = "Mode drift " .. (_vipDriftEnabled and "activé" or "désactivé") })
            vipMain.refresh()
        end)
    end
end)

vipMain.OnClose(function()
    vipMain.CloseVipPreview()
end)

-- ==========================================
--    WEAPON CUSTOMIZATION (TINTS & SKINS)
-- ==========================================

vipWeaponCustomMenu.OnOpen(function()
    vipWeaponCustomMenu.ClearItems()

    -- Récupérer les armes de l'inventaire
    local weapons = {}
    if VFW.PlayerData and VFW.PlayerData.inventory then
        for _, item in ipairs(VFW.PlayerData.inventory) do
            if item.name and item.count > 0 then
                local weaponName = item.name:upper()
                if string.find(weaponName, "WEAPON_") then
                    for _, w in ipairs(Config.Weapons) do
                        if w.name:upper() == weaponName and item.meta and item.meta.weaponId then
                            table.insert(weapons, { item = item, data = w })
                            break
                        end
                    end
                end
            end
        end
    end

    if #weapons == 0 then
        vipWeaponCustomMenu.Button("Aucune arme sur vous", nil, nil, "lock", false, function() end)
        return
    end

    vipWeaponCustomMenu.Separator("Vos armes")

    for _, weapon in ipairs(weapons) do
        local itemData = VFW.Items and VFW.Items[weapon.item.name]
        local label = itemData and itemData.label or weapon.data.label

        vipWeaponCustomMenu.Button(label, "Personnaliser", nil, "chevron", false, function()
            vipWeaponCustomMenu.close()
            Wait(200)
            OpenWeaponMenuVip(weapon.item, weapon.data)
        end)
    end
end)

-- ==========================================
--       MONTHLY VEHICLE SUBMENU
-- ==========================================

vipPlateChangeMenu.OnOpen(function()
    vipPlateChangeMenu.ClearItems()

    local info = TriggerServerCallback("vip:getPlateChangeInfo")
    if not info or not info.success then
        vipPlateChangeMenu.Button("Erreur", info and info.message or "Impossible de charger les données", nil, nil, false, function() end)
        return
    end

    local remaining = info.remainingChanges or 0
    local max = info.maxChanges or 0

    vipPlateChangeMenu.Separator(string.format("Changements restants : %d/%d", remaining, max))

    if remaining <= 0 then
        vipPlateChangeMenu.Separator("Plus de changement disponible")
        return
    end

    vipPlateChangeMenu.Separator("Véhicules au garage")

    local vehicles = info.vehicles or {}
    if #vehicles == 0 then
        vipPlateChangeMenu.Button("Aucun véhicule disponible", "Vos véhicules doivent être au garage", nil, nil, false, function() end)
        return
    end

    for _, veh in ipairs(vehicles) do
        local labelText
        if Garage and Garage.GetVehicleLabel then
            labelText = Garage.GetVehicleLabel(veh.model or "")
        end
        if not labelText or labelText == "" then
            local modelHash = GetHashKey(veh.model or "")
            local makeName = GetMakeNameFromVehicleModel(modelHash) or ""
            local displayName = GetDisplayNameFromVehicleModel(modelHash) or ""
            labelText = GetLabelText(displayName)
            if not labelText or labelText == "NULL" or labelText == "" then labelText = veh.model end
            if makeName and makeName ~= "" and makeName ~= "NULL" then
                local makeLabel = GetLabelText(makeName)
                if makeLabel and makeLabel ~= "NULL" and makeLabel ~= "" then
                    labelText = makeLabel .. " " .. labelText
                end
            end
        end
        local displayLabel = labelText .. "  [" .. veh.plate .. "]"
        vipPlateChangeMenu.Button(displayLabel, "Changer la plaque de ce véhicule", nil, "chevron", false, function()
            vipPlateChangeMenu.close()
            Wait(200)

            local newPlate = VFW.Nui.KeyboardInput(true, "Nouvelle plaque (max 8 caractères)")
            if not newPlate or newPlate == "" then return end

            newPlate = string.upper(newPlate)

            if #newPlate > 8 then
                VFW.ShowNotification({ type = "ROUGE", content = "La plaque ne peut pas dépasser 8 caractères." })
                return
            end

            local checkResult = TriggerServerCallback("vip:checkPlateAvailable", { newPlate = newPlate })
            if not checkResult or not checkResult.available then
                VFW.ShowNotification({ type = "ROUGE", content = checkResult and checkResult.message or "Cette plaque est déjà utilisée." })
                return
            end

            local confirm = VFW.Nui.KeyboardInput(true, veh.plate .. " → " .. newPlate .. "  Tapez CONFIRMER")
            if not confirm or string.upper(confirm) ~= "CONFIRMER" then
                VFW.ShowNotification({ type = "ROUGE", content = "Changement annulé." })
                return
            end

            local result = TriggerServerCallback("vip:changePlate", { oldPlate = veh.plate, newPlate = newPlate })
            if not result or not result.success then
                VFW.ShowNotification({ type = "ROUGE", content = result and result.message or "Erreur lors du changement." })
            end
        end)
    end
end)

vipMonthlyVehicleMenu.OnOpen(function()
    setVipBanner(vipMonthlyVehicleMenu)

    local result = TriggerServerCallback("vip:getMonthlyVehiclesCallback")

    if not result or not result.success then
        vipMonthlyVehicleMenu.Button("Erreur", "Impossible de charger les vehicules", nil, nil, false, function() end)
        return
    end

    local vehicles = result.vehicles or {}
    local hasClaimed = result.hasClaimed

    if #vehicles == 0 then
        vipMonthlyVehicleMenu.Button("Aucun véhicule", "Aucun véhicule disponible pour votre tier", nil, nil, false, function() end)
        return
    end

    vipMonthlyVehicleMenu.Separator("VEHICULE DU MOIS")

    for _, veh in ipairs(vehicles) do
        local label = veh.vehicle_label or veh.vehicle_model
        local desc = (veh.vehicle_category or "Véhicule") .. " - " .. veh.vehicle_model

        vipMonthlyVehicleMenu.Button(label, desc, nil, "chevron", false, function()
            if hasClaimed then
                VFW.ShowNotification({ type = "ROUGE", content = "Vous avez déjà récupéré votre véhicule du mois" })
                return
            end
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour récupérer " .. label)
            if confirm and string.upper(confirm) == "OUI" then
                local claimResult = TriggerServerCallback("vip:claimMonthlyVehicleCallback", veh.vehicle_model)
                if claimResult and claimResult.success then
                    hasClaimed = true
                    VFW.ShowNotification({ type = "VERT", content = claimResult.message })
                    vipMonthlyVehicleMenu.close()
                else
                    VFW.ShowNotification({ type = "ROUGE", content = claimResult and claimResult.message or "Erreur" })
                end
            end
        end)
    end
end)

-- ==========================================
--       GPS SUBMENU RENDERING
-- ==========================================

vipVehicleGpsMenu.OnOpen(function()
    setVipBanner(vipVehicleGpsMenu)

    local vehicles = TriggerServerCallback('vip:getSpawnedVehicles')

    if not vehicles or #vehicles == 0 then
        vipVehicleGpsMenu.Button("Aucun véhicule sorti", "", nil, nil, false, function() end)
        return
    end

    -- Sort by distance
    local playerPos = GetEntityCoords(PlayerPedId())
    for _, veh in ipairs(vehicles) do
        if veh.pos then
            veh._dist = #(playerPos - vector3(veh.pos.x, veh.pos.y, veh.pos.z))
        else
            veh._dist = math.huge
        end
    end
    table.sort(vehicles, function(a, b) return a._dist < b._dist end)

    for _, veh in ipairs(vehicles) do
        if veh.pos then
            local distLabel = veh._dist < 1000
                and string.format("%.0fm", veh._dist)
                or string.format("%.1fkm", veh._dist / 1000)
            local label = string.format("%s [%s]", veh.model or "Véhicule", veh.plate or "???")
            local desc = string.format("Distance: %s", distLabel)

            vipVehicleGpsMenu.Button(label, desc, nil, nil, false, function()
                vipVehicleGpsMenu.close()
                createVipGpsBlip(veh)
            end)
        end
    end
end)

-- ==========================================
--       PROPS BUILDER SUBMENUS
-- ==========================================

propsBuilderMenu.OnOpen(function()
    setVipBanner(propsBuilderMenu)
    renderPropsBuilderMenu(propsBuilderMenu, createVipPropMenu, manageMyPropsMenu)
end)

createVipPropMenu.OnOpen(function()
    setVipBanner(createVipPropMenu)
    renderPropsCreateProps(createVipPropMenu, categorySelectionMenu, propsBuilderMenu)
end)

categorySelectionMenu.OnOpen(function()
    setVipBanner(categorySelectionMenu)
    renderCategorySelectionMenu(categorySelectionMenu, createVipPropMenu)
end)

manageMyPropsMenu.OnOpen(function()
    setVipBanner(manageMyPropsMenu)
    renderManageMyPropsMenu(manageMyPropsMenu)
end)

-- ==========================================
--         REGISTER KEYBINDINGS
-- ==========================================

VFW.RegisterInput("OpenVIPMenu", "Menu VIP", "keyboard", "F3", function()
    if Death.isDead or VFW.PlayerData.dead or VFW.IsPlayerInTIG() then
        return
    end

    if not isPlayerVip() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être VIP pour accéder à ce menu"
        })
        return
    end

    vipMain.open()
end)

-- ==========================================
--         VIP DRIFT MODE
-- ==========================================

CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(100) end
    while true do
        Wait(150)
        if _vipDriftEnabled then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(veh, -1) == ped then
                    SetVehicleReduceGrip(veh, IsControlPressed(0, 21))
                end
            end
        end
    end
end)

-- ==========================================
--     EMERGENCY VEHICLE WARP
-- ==========================================

RegisterNetEvent("vip:emergencyVehicleSpawned", function(netId)
    CreateThread(function()
        local timeout = 10000
        local elapsed = 0
        while elapsed < timeout do
            if NetworkDoesNetworkIdExist(netId) then
                local vehicle = NetworkGetEntityFromNetworkId(netId)
                if vehicle and DoesEntityExist(vehicle) then
                    local plate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
                    TriggerServerEvent("vfw:vehicle:keyTemporarly:add", "auther", plate)
                    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                    return
                end
            end
            Wait(100)
            elapsed = elapsed + 100
        end
    end)
end)

-- ==========================================
--            CLEANUP
-- ==========================================

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if _vipGpsBlip and DoesBlipExist(_vipGpsBlip) then
            RemoveBlip(_vipGpsBlip)
            _vipGpsBlip = nil
        end
    end
end)
