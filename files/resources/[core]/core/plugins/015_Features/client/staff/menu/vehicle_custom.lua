---@meta _
---@diagnostic disable: duplicate-doc-field

local function GetStaffTitle()
    return StaffMenu.menuContext == 'animator' and VFW.AnimatorTitle() or VFW.StaffTitle()
end

local isPermanent = false
local originalProps = nil
local customVehicle = nil

local headlightColors = {
    { name = "Origine", id = -1 },
    { name = "Blanc", id = 0 },
    { name = "Bleu", id = 1 },
    { name = "Bleu electrique", id = 2 },
    { name = "Vert menthe", id = 3 },
    { name = "Vert citron", id = 4 },
    { name = "Jaune", id = 5 },
    { name = "Or jaune", id = 6 },
    { name = "Orange", id = 7 },
    { name = "Rouge", id = 8 },
    { name = "Rose poney", id = 9 },
    { name = "Rose vif", id = 10 },
    { name = "Violet", id = 11 },
    { name = "Lumiere noire", id = 12 }
}

local wheelTypeNames = {
    [0] = "Sport",
    [1] = "Muscle",
    [2] = "Lowrider",
    [3] = "SUV",
    [4] = "Offroad",
    [5] = "Tuner",
    [6] = "Moto",
    [7] = "Haute Gamme",
    [8] = "Bennys Original",
    [9] = "Bennys Bespoke",
    [10] = "Open Wheel",
    [11] = "Street",
    [12] = "Track"
}

local neonPositions = {
    { index = 0, name = "Gauche" },
    { index = 1, name = "Droite" },
    { index = 2, name = "Avant" },
    { index = 3, name = "Arriere" }
}

local aestheticIndices = {
    { index = 0, name = "Spoiler" },
    { index = 1, name = "Pare-chocs avant" },
    { index = 2, name = "Pare-chocs arriere" },
    { index = 3, name = "Jupes laterales" },
    { index = 4, name = "Echappement" },
    { index = 5, name = "Arceau" },
    { index = 6, name = "Grille" },
    { index = 7, name = "Capot" },
    { index = 8, name = "Aile gauche" },
    { index = 9, name = "Aile droite" },
    { index = 10, name = "Toit" },
    { index = 25, name = "Plaque avant" },
    { index = 27, name = "Garniture" },
    { index = 28, name = "Ornements" },
    { index = 29, name = "Tableau de bord" },
    { index = 30, name = "Cadran" },
    { index = 31, name = "Porte" },
    { index = 32, name = "Sieges" },
    { index = 33, name = "Volant" },
    { index = 34, name = "Levier de vitesse" },
    { index = 35, name = "Plaques" },
    { index = 36, name = "Haut-parleurs" },
    { index = 37, name = "Coffre" },
    { index = 38, name = "Hydrauliques" },
    { index = 39, name = "Bloc moteur" },
    { index = 40, name = "Filtre a air" },
    { index = 41, name = "Entretoises" },
    { index = 42, name = "Cache-soupapes" },
    { index = 43, name = "Arceau interieur" },
    { index = 44, name = "Antenne" },
    { index = 45, name = "Garniture ext." },
    { index = 46, name = "Reservoir" },
    { index = 47, name = "Porte gauche" },
}

local performanceIndices = {
    { index = 11, name = "Moteur" },
    { index = 12, name = "Freins" },
    { index = 13, name = "Transmission" },
    { index = 15, name = "Suspension" },
    { index = 16, name = "Blindage" },
}

local plateStyles = {
    { name = "Bleu/Blanc", id = 0 },
    { name = "Jaune/Noir", id = 1 },
    { name = "Jaune/Bleu", id = 2 },
    { name = "Bleu/Blanc 2", id = 3 },
    { name = "Bleu/Blanc 3", id = 4 },
    { name = "Yankton", id = 5 },
}

local windowTints = {
    { name = "Aucune", id = 0 },
    { name = "Noire pure", id = 1 },
    { name = "Sombre", id = 2 },
    { name = "Legere", id = 3 },
    { name = "Securite", id = 4 },
    { name = "Limo noire", id = 5 },
    { name = "Verte", id = 6 },
}

local function getModLabel(vehicle, modType, modIndex)
    if modIndex < 0 then return "Stock" end
    local label = GetLabelText(GetModTextLabel(vehicle, modType, modIndex))
    if label == "NULL" then
        return "Mod " .. (modIndex + 1)
    end
    return label
end

local function hasPermanentPermission()
    return VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions
        and VFW.PlayerGlobalData.permissions["staff_custom_permanent"]
end

function StaffMenu.OpenVehicleCustomMenu(parentMenu)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if not DoesEntityExist(vehicle) then
        local coords = GetEntityCoords(playerPed)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 10.0, 0, 70)
    end

    if not DoesEntityExist(vehicle) then
        VFW.ShowNotification({
            type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Custom Véhicule',
            message = "Aucun véhicule proche."
      })
        return false
    end

    if not IsPedInVehicle(playerPed, vehicle, false) then
        SetPedIntoVehicle(playerPed, vehicle, -1)
        Wait(100)
    end

    SetVehicleModKit(vehicle, 0)
    originalProps = VFW.Game.GetVehicleProperties(vehicle)
    customVehicle = vehicle
    isPermanent = false

    if parentMenu and parentMenu.close then
        parentMenu.close()
    end

    StaffMenu.vehicleCustom.open()
    return true
end

function StaffMenu.BuildVehicleCustomMenu()
    local vehicle = customVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local plate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
    local modelHash = GetEntityModel(vehicle)
    local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
    if vehicleName == "NULL" then
        vehicleName = GetDisplayNameFromVehicleModel(modelHash)
    end

    StaffMenu.vehicleCustom.Title(vehicleName, plate)

    StaffMenu.vehicleCustom.Checkbox("Changements permanents", "Sauvegarde en base de donnees",
        not hasPermanentPermission(), isPermanent, function(checked)
        isPermanent = checked
    end)

    StaffMenu.vehicleCustom.Separator("CATEGORIES")

    StaffMenu.vehicleCustom.Button(":bolt: PERFORMANCE", "Modifier le moteur, les freins, la transmission et la suspension", nil, "chevron", false, function() end, StaffMenu.vehicleCustomPerf)
    StaffMenu.vehicleCustom.Button(":sparkles: ESTHETIQUE", "Modifier les éléments esthétiques : spoiler, pare-chocs, capot, etc.", nil, "chevron", false, function() end, StaffMenu.vehicleCustomAesthetic)
    StaffMenu.vehicleCustom.Button(":palette: COULEURS", "Changer la couleur primaire, secondaire, perle, jantes et néons", nil, "chevron", false, function() end, StaffMenu.vehicleCustomColors)
    StaffMenu.vehicleCustom.Button(":car: ROUES", "Modifier le type de roues et le style des jantes", nil, "chevron", false, function() end, StaffMenu.vehicleCustomWheels)
    StaffMenu.vehicleCustom.Button(":info: ECLAIRAGE", "Modifier la teinte des vitres, les néons et la couleur des phares", nil, "chevron", false, function() end, StaffMenu.vehicleCustomLights)
    StaffMenu.vehicleCustom.Button(":wrench: EXTRAS & DIVERS", "Activer ou désactiver les extras visuels du véhicule", nil, "chevron", false, function() end, StaffMenu.vehicleCustomExtras)

    StaffMenu.vehicleCustom.Separator("ACTIONS")

    StaffMenu.vehicleCustom.Button(":refresh: REMETTRE D'USINE", "Remettre toutes les modifications du véhicule à leurs valeurs d'origine", nil, "trash", false, function()
        if not vehicle or not DoesEntityExist(vehicle) then return end
        SetVehicleModKit(vehicle, 0)
        for i = 0, 49 do
            SetVehicleMod(vehicle, i, -1, false)
        end
        ToggleVehicleMod(vehicle, 18, false)
        ToggleVehicleMod(vehicle, 20, false)
        ToggleVehicleMod(vehicle, 22, false)
        SetVehicleColours(vehicle, 0, 0)
        ClearVehicleCustomPrimaryColour(vehicle)
        ClearVehicleCustomSecondaryColour(vehicle)
        SetVehicleExtraColours(vehicle, 0, 0)
        SetVehicleInteriorColor(vehicle, 0)
        SetVehicleDashboardColor(vehicle, 0)
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, false)
        end
        SetVehicleWindowTint(vehicle, 0)
        SetVehicleWheelType(vehicle, 0)
        SetVehicleXenonLightsColor(vehicle, -1)
        for i = 0, 20 do
            if DoesExtraExist(vehicle, i) then
                SetVehicleExtra(vehicle, i, true)
            end
        end
        VFW.ShowNotification({
            type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Custom Véhicule',
            message = "Véhicule remis d'usine"
      })
        StaffMenu.vehicleCustom.refresh()
    end)

    StaffMenu.vehicleCustom.Button(":check: VALIDER LES MODIFICATIONS", "Appliquer et sauvegarder les modifications en base de données si permanent", nil, "check", false, function()
        if not vehicle or not DoesEntityExist(vehicle) then return end

        if isPermanent then
            local props = VFW.Game.GetVehicleProperties(vehicle)
            TriggerServerEvent("vfw:staff:saveVehicleCustom", plate, props)
        else
            TriggerServerEvent("vfw:staff:setTempCustom", plate, originalProps)
            VFW.ShowNotification({
                type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Custom Véhicule',
                message = "Modifications temporaires appliquées."
          })
        end

        originalProps = nil
        customVehicle = nil
        StaffMenu.vehicleCustom.close()
    end)

    StaffMenu.vehicleCustom.Button(":x: ANNULER", "Annuler toutes les modifications et restaurer l'état d'origine du véhicule", nil, "trash", false, function()
        if vehicle and DoesEntityExist(vehicle) and originalProps then
            VFW.Game.SetVehicleProperties(vehicle, originalProps)
        end
        originalProps = nil
        customVehicle = nil
        StaffMenu.vehicleCustom.close()
    end)
end

function StaffMenu.BuildVehicleCustomPerfMenu()
    local vehicle = customVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    StaffMenu.vehicleCustomPerf.Button(":rocket: TOUT AU MAXIMUM", nil, nil, "arrow", false, function()
        SetVehicleModKit(vehicle, 0)
        for _, perf in ipairs(performanceIndices) do
            local max = GetNumVehicleMods(vehicle, perf.index) - 1
            if max >= 0 then
                SetVehicleMod(vehicle, perf.index, max, false)
            end
        end
        ToggleVehicleMod(vehicle, 18, true)
        VFW.ShowNotification({
            type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Custom Véhicule',
            message = "Performance au maximum"
      })
        StaffMenu.vehicleCustomPerf.refresh()
    end)

    StaffMenu.vehicleCustomPerf.Separator("COMPOSANTS")

    for _, perf in ipairs(performanceIndices) do
        local numMods = GetNumVehicleMods(vehicle, perf.index)
        if numMods > 0 then
            local currentMod = GetVehicleMod(vehicle, perf.index)
            local items = { "Stock" }
            for i = 0, numMods - 1 do
                local label = getModLabel(vehicle, perf.index, i)
                table.insert(items, label)
            end
            local currentIdx = currentMod + 2
            StaffMenu.vehicleCustomPerf.List(perf.name, nil, false, items, currentIdx, function(idx)
                if idx == 1 then
                    SetVehicleMod(vehicle, perf.index, -1, false)
                else
                    SetVehicleMod(vehicle, perf.index, idx - 2, false)
                end
            end)
        end
    end

    local hasTurbo = IsToggleModOn(vehicle, 18)
    StaffMenu.vehicleCustomPerf.Checkbox("Turbo", nil, false, hasTurbo, function(checked)
        ToggleVehicleMod(vehicle, 18, checked)
    end)
end

function StaffMenu.BuildVehicleCustomAestheticMenu()
    local vehicle = customVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    for _, mod in ipairs(aestheticIndices) do
        local numMods = GetNumVehicleMods(vehicle, mod.index)
        if numMods > 0 then
            local currentMod = GetVehicleMod(vehicle, mod.index)
            local items = { "Stock" }
            for i = 0, numMods - 1 do
                local label = getModLabel(vehicle, mod.index, i)
                table.insert(items, label)
            end
            local currentIdx = currentMod + 2
            StaffMenu.vehicleCustomAesthetic.List(mod.name, nil, false, items, currentIdx, function(idx)
                if idx == 1 then
                    SetVehicleMod(vehicle, mod.index, -1, false)
                else
                    SetVehicleMod(vehicle, mod.index, idx - 2, false)
                end
            end)
        end
    end

end

function StaffMenu.BuildVehicleCustomColorsMenu()
    local vehicle = customVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local pR, pG, pB = GetVehicleCustomPrimaryColour(vehicle)
    local sR, sG, sB = GetVehicleCustomSecondaryColour(vehicle)

    StaffMenu.vehicleCustomColors.Button(":palette: COULEURS CARROSSERIE", pR .. "," .. pG .. "," .. pB .. " | " .. sR .. "," .. sG .. "," .. sB, nil, "chevron", false, function()
        StaffMenu.vehicleCustomColors.ColorPicker(pR, pG, pB, sR, sG, sB,
            function(r, g, b)
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleCustomPrimaryColour(vehicle, r, g, b)
                end
            end,
            function(r, g, b)
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleCustomSecondaryColour(vehicle, r, g, b)
                end
            end
        )
    end)

    StaffMenu.vehicleCustomColors.Separator("NACRE")

    local pearl = GetVehicleExtraColours(vehicle)
    local pearlItems = {}
    for i = 0, 161 do
        table.insert(pearlItems, "Couleur " .. i)
    end
    StaffMenu.vehicleCustomColors.List("Nacre", nil, false, pearlItems, pearl + 1, function(idx)
        local primary, _ = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, idx - 1, _)
    end)

    StaffMenu.vehicleCustomColors.Separator("INTERIEUR")

    local intColor = GetVehicleInteriorColor(vehicle) or 0
    local intItems = {}
    for i = 0, 160 do
        table.insert(intItems, "Couleur " .. i)
    end
    StaffMenu.vehicleCustomColors.List("Couleur interieur", nil, false, intItems, intColor + 1, function(idx)
        SetVehicleInteriorColor(vehicle, idx - 1)
    end)

    local dashColor = GetVehicleDashboardColor(vehicle) or 0
    local dashItems = {}
    for i = 0, 160 do
        table.insert(dashItems, "Couleur " .. i)
    end
    StaffMenu.vehicleCustomColors.List("Couleur tableau de bord", nil, false, dashItems, dashColor + 1, function(idx)
        SetVehicleDashboardColor(vehicle, idx - 1)
    end)
end

function StaffMenu.BuildVehicleCustomWheelsMenu()
    local vehicle = customVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local currentWheelType = GetVehicleWheelType(vehicle)
    local wheelItems = {}
    local currentWheelIdx = 1
    local wheelOrder = {}
    for id, name in pairs(wheelTypeNames) do
        table.insert(wheelOrder, { id = id, name = name })
    end
    table.sort(wheelOrder, function(a, b) return a.id < b.id end)
    for i, wt in ipairs(wheelOrder) do
        table.insert(wheelItems, wt.name)
        if wt.id == currentWheelType then currentWheelIdx = i end
    end

    StaffMenu.vehicleCustomWheels.List("Type de roues", nil, false, wheelItems, currentWheelIdx, function(idx)
        local selectedType = wheelOrder[idx].id
        SetVehicleWheelType(vehicle, selectedType)
        StaffMenu.vehicleCustomWheels.refresh()
    end)

    local numWheelMods = GetNumVehicleMods(vehicle, 23)
    if numWheelMods > 0 then
        local currentWheel = GetVehicleMod(vehicle, 23)
        local wheelModelItems = { "Stock" }
        for i = 0, numWheelMods - 1 do
            local label = getModLabel(vehicle, 23, i)
            table.insert(wheelModelItems, label)
        end
        StaffMenu.vehicleCustomWheels.List("Modele de jantes", nil, false, wheelModelItems, currentWheel + 2, function(idx)
            if idx == 1 then
                SetVehicleMod(vehicle, 23, -1, false)
            else
                SetVehicleMod(vehicle, 23, idx - 2, false)
            end
        end)
    end

    local numBackWheelMods = GetNumVehicleMods(vehicle, 24)
    if numBackWheelMods > 0 then
        local currentBackWheel = GetVehicleMod(vehicle, 24)
        local backWheelItems = { "Stock" }
        for i = 0, numBackWheelMods - 1 do
            local label = getModLabel(vehicle, 24, i)
            table.insert(backWheelItems, label)
        end
        StaffMenu.vehicleCustomWheels.List("Jantes arriere", nil, false, backWheelItems, currentBackWheel + 2, function(idx)
            if idx == 1 then
                SetVehicleMod(vehicle, 24, -1, false)
            else
                SetVehicleMod(vehicle, 24, idx - 2, false)
            end
        end)
    end

    StaffMenu.vehicleCustomWheels.Separator("COULEUR ROUES")

    local _, wheelColor = GetVehicleExtraColours(vehicle)
    local wheelColorItems = {}
    for i = 0, 161 do
        table.insert(wheelColorItems, "Couleur " .. i)
    end
    StaffMenu.vehicleCustomWheels.List("Couleur des jantes", nil, false, wheelColorItems, wheelColor + 1, function(idx)
        local pearl, _ = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, pearl, idx - 1)
    end)

    StaffMenu.vehicleCustomWheels.Separator("FUMEE DE PNEUS")

    local hasTireSmoke = IsToggleModOn(vehicle, 20)
    StaffMenu.vehicleCustomWheels.Checkbox("Fumee de pneus", nil, false, hasTireSmoke, function(checked)
        ToggleVehicleMod(vehicle, 20, checked)
        if checked then
            StaffMenu.vehicleCustomWheels.refresh()
        end
    end)

    if hasTireSmoke then
        local smokeR, smokeG, smokeB = GetVehicleTyreSmokeColor(vehicle)
        StaffMenu.vehicleCustomWheels.Button(" Couleur fumee", ("(%d, %d, %d)"):format(smokeR, smokeG, smokeB), nil, "chevron", false, function()
            StaffMenu.vehicleCustomWheels.RoleColorPicker(smokeR, smokeG, smokeB, "COULEUR FUMEE",
                function(r, g, b)
                    if vehicle and DoesEntityExist(vehicle) then
                        SetVehicleTyreSmokeColor(vehicle, r, g, b)
                    end
                end,
                function(r, g, b)
                    if vehicle and DoesEntityExist(vehicle) then
                        SetVehicleTyreSmokeColor(vehicle, r, g, b)
                    end
                    StaffMenu.vehicleCustomWheels.refresh()
                end,
                function()
                    if vehicle and DoesEntityExist(vehicle) then
                        SetVehicleTyreSmokeColor(vehicle, smokeR, smokeG, smokeB)
                    end
                end
            )
        end)
    end
end

function StaffMenu.BuildVehicleCustomLightsMenu()
    local vehicle = customVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    StaffMenu.vehicleCustomLights.Separator("XENON")

    local hasXenon = IsToggleModOn(vehicle, 22)
    StaffMenu.vehicleCustomLights.Checkbox("Phares Xenon", nil, false, hasXenon, function(checked)
        ToggleVehicleMod(vehicle, 22, checked)
        StaffMenu.vehicleCustomLights.refresh()
    end)

    if hasXenon then
        local currentXenonColor = GetVehicleXenonLightsColor(vehicle)
        local xenonItems = {}
        local currentXenonIdx = 1
        for i, color in ipairs(headlightColors) do
            table.insert(xenonItems, color.name)
            if color.id == currentXenonColor then currentXenonIdx = i end
        end
        StaffMenu.vehicleCustomLights.List("Couleur Xenon", nil, false, xenonItems, currentXenonIdx, function(idx)
            SetVehicleXenonLightsColor(vehicle, headlightColors[idx].id)
        end)
    end

    StaffMenu.vehicleCustomLights.Separator("NEON")

    for _, pos in ipairs(neonPositions) do
        local enabled = IsVehicleNeonLightEnabled(vehicle, pos.index)
        StaffMenu.vehicleCustomLights.Checkbox("Neon " .. pos.name, nil, false, enabled, function(checked)
            SetVehicleNeonLightEnabled(vehicle, pos.index, checked)
        end)
    end

    local nR, nG, nB = GetVehicleNeonLightsColour(vehicle)
    StaffMenu.vehicleCustomLights.Button(":sparkles: Couleur neon", ("(%d, %d, %d)"):format(nR, nG, nB), nil, "chevron", false, function()
        StaffMenu.vehicleCustomLights.RoleColorPicker(nR, nG, nB, "COULEUR NEON",
            function(r, g, b)
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleNeonLightsColour(vehicle, r, g, b)
                end
            end,
            function(r, g, b)
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleNeonLightsColour(vehicle, r, g, b)
                end
                StaffMenu.vehicleCustomLights.refresh()
            end,
            function()
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleNeonLightsColour(vehicle, nR, nG, nB)
                end
            end
        )
    end)

    StaffMenu.vehicleCustomLights.Button(":check: TOUT ACTIVER", nil, nil, "check", false, function()
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, true)
        end
        StaffMenu.vehicleCustomLights.refresh()
    end)

    StaffMenu.vehicleCustomLights.Button(":x: TOUT DESACTIVER", nil, nil, "trash", false, function()
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, false)
        end
        StaffMenu.vehicleCustomLights.refresh()
    end)
end

function StaffMenu.BuildVehicleCustomExtrasMenu()
    local vehicle = customVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    StaffMenu.vehicleCustomExtras.Separator("EXTRAS")

    local hasExtras = false
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            hasExtras = true
            local enabled = IsVehicleExtraTurnedOn(vehicle, i)
            StaffMenu.vehicleCustomExtras.Checkbox("Extra " .. i, nil, false, enabled, function(checked)
                SetVehicleExtra(vehicle, i, not checked)
            end)
        end
    end

    if not hasExtras then
        StaffMenu.vehicleCustomExtras.Separator("Aucun extra disponible")
    end

    StaffMenu.vehicleCustomExtras.Separator("LIVREES")

    local liveryCount = GetVehicleLiveryCount(vehicle)
    local modLiveryCount = GetNumVehicleMods(vehicle, 48)

    if liveryCount > 0 then
        local currentLivery = GetVehicleLivery(vehicle)
        local liveryItems = { "Aucune" }
        for i = 0, liveryCount - 1 do
            local name = GetLabelText(GetLiveryName(vehicle, i))
            if name == "NULL" then name = "Motif " .. (i + 1) end
            table.insert(liveryItems, name)
        end
        StaffMenu.vehicleCustomExtras.List("Livree", nil, false, liveryItems, (currentLivery or -1) + 2, function(idx)
            if idx == 1 then
                SetVehicleLivery(vehicle, -1)
            else
                SetVehicleLivery(vehicle, idx - 2)
            end
        end)
    elseif modLiveryCount > 0 then
        local currentModLivery = GetVehicleMod(vehicle, 48)
        local modLiveryItems = { "Aucune" }
        for i = 0, modLiveryCount - 1 do
            local name = GetLabelText(GetModTextLabel(vehicle, 48, i))
            if name == "NULL" then name = "Motif " .. (i + 1) end
            table.insert(modLiveryItems, name)
        end
        StaffMenu.vehicleCustomExtras.List("Livree (mod)", nil, false, modLiveryItems, (currentModLivery or -1) + 2, function(idx)
            if idx == 1 then
                SetVehicleMod(vehicle, 48, -1, false)
            else
                SetVehicleMod(vehicle, 48, idx - 2, false)
            end
        end)
    else
        StaffMenu.vehicleCustomExtras.Separator("Aucune livree disponible")
    end

    StaffMenu.vehicleCustomExtras.Separator("DIVERS")

    local currentPlateStyle = GetVehicleNumberPlateTextIndex(vehicle)
    local plateItems = {}
    local currentPlateIdx = 1
    for i, style in ipairs(plateStyles) do
        table.insert(plateItems, style.name)
        if style.id == currentPlateStyle then currentPlateIdx = i end
    end
    StaffMenu.vehicleCustomExtras.List("Style de plaque", nil, false, plateItems, currentPlateIdx, function(idx)
        SetVehicleNumberPlateTextIndex(vehicle, plateStyles[idx].id)
    end)

    local currentTint = GetVehicleWindowTint(vehicle)
    local tintItems = {}
    local currentTintIdx = 1
    for i, tint in ipairs(windowTints) do
        table.insert(tintItems, tint.name)
        if tint.id == currentTint then currentTintIdx = i end
    end
    StaffMenu.vehicleCustomExtras.List("Vitres teintees", nil, false, tintItems, currentTintIdx, function(idx)
        SetVehicleWindowTint(vehicle, windowTints[idx].id)
    end)

    StaffMenu.vehicleCustomExtras.Button(" CHANGER LA PLAQUE", nil, nil, "chevron", not VFW.PlayerGlobalData.permissions["change_plate"], function()
        StaffMenu.vehicleCustomExtras.close()
        VFW.Nui.Focus(true)
        local newPlate = VFW.Nui.KeyboardInput(true, "Nouvelle plaque (8 car. max)")
        if not newPlate or newPlate == "" or newPlate == "KBD_CANCEL" then
            StaffMenu.vehicleCustomExtras.open()
            return
        end
        if #newPlate > 8 then
            VFW.ShowNotification({
                type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Custom Véhicule',
                message = "Cette plaque n'est pas valide (8 caracteres max)"
          })
            StaffMenu.vehicleCustomExtras.open()
            return
        end
        local oldPlate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
        local success = TriggerServerCallback("vfw:vehicle:changePlate", oldPlate, newPlate)
        if success then
            SetVehicleNumberPlateText(vehicle, newPlate)
            VFW.ShowNotification({
                type = 'STAFF', title = GetStaffTitle(), variant = 'SUCCESS', subtitle = 'Custom Véhicule',
                message = "Plaque changée: " .. newPlate
            })
        else
            VFW.ShowNotification({
                type = 'STAFF', title = GetStaffTitle(), variant = 'ERROR', subtitle = 'Custom Véhicule',
                message = "Plaque déjà utilisée ou véhicule non enregistré"
          })
        end
        StaffMenu.vehicleCustomExtras.open()
    end)
end

StaffMenu.vehicleCustom.OnOpen(function()
    StaffMenu.BuildVehicleCustomMenu()
end)

StaffMenu.vehicleCustomPerf.OnOpen(function()
    StaffMenu.BuildVehicleCustomPerfMenu()
end)

StaffMenu.vehicleCustomAesthetic.OnOpen(function()
    StaffMenu.BuildVehicleCustomAestheticMenu()
end)

StaffMenu.vehicleCustomColors.OnOpen(function()
    StaffMenu.BuildVehicleCustomColorsMenu()
end)

StaffMenu.vehicleCustomWheels.OnOpen(function()
    StaffMenu.BuildVehicleCustomWheelsMenu()
end)

StaffMenu.vehicleCustomLights.OnOpen(function()
    StaffMenu.BuildVehicleCustomLightsMenu()
end)

StaffMenu.vehicleCustomExtras.OnOpen(function()
    StaffMenu.BuildVehicleCustomExtrasMenu()
end)
