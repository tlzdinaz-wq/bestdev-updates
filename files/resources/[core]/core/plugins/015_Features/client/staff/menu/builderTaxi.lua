---
--- Builder: Gestion Taxi
--- Permet de gerer les zones de spawn taxi et les parametres
--- depuis le menu builders (sans passer par la gestion des societes)
---

local selectedTaxiJob = nil
local selectedTaxiLabel = nil
local taxiJobData = nil

local function isBaseZoneEnabled(key)
    if not taxiJobData or not taxiJobData.custom or not taxiJobData.custom.enabledBaseZones then
        return false
    end
    for _, k in ipairs(taxiJobData.custom.enabledBaseZones) do
        if k == key then return true end
    end
    return false
end

-- ============================================
-- NUI: Taxi Zone Editor (React)
-- ============================================
local function openTaxiZoneEditor()
    -- Fermer le menu VUI
    if StaffMenu.builderTaxiEdit.close then
        StaffMenu.builderTaxiEdit.close()
    end

    -- Preparer les zones custom avec un id si absent
    local customZones = taxiJobData.custom.taxiSpawnZones or {}
    for i, zone in ipairs(customZones) do
        if not zone.id then
            zone.id = "custom_" .. i .. "_" .. GetGameTimer()
        end
    end

    -- Envoyer les donnees au React
    SendNUIMessage({
        action = "nui:taxi:openZoneEditor",
        data = {
            baseZones = TaxiJob.Config.BaseZones or {},
            enabledBaseZones = taxiJobData.custom.enabledBaseZones or {},
            customZones = customZones,
            societyLabel = selectedTaxiLabel,
        }
    })
    VFW.Nui.Focus(true)
end

RegisterNUICallback("nui:taxi:closeZoneEditor", function(data, cb)
    VFW.Nui.Focus(false)
    -- Mettre a jour les donnees en memoire
    if data.enabledBaseZones then
        taxiJobData.custom.enabledBaseZones = data.enabledBaseZones
    end
    if data.customZones then
        taxiJobData.custom.taxiSpawnZones = data.customZones
    end
    cb("ok")
    -- Rouvrir le menu VUI
    Wait(200)
    StaffMenu.builderTaxiEdit.open()
end)

-- Callback: position du joueur
RegisterNUICallback("nui:taxi:getPlayerPos", function(_, cb)
    local pos = GetEntityCoords(PlayerPedId())
    cb({ x = pos.x, y = pos.y, z = pos.z })
end)

-- Callbacks focus input (NUI garde toujours le focus complet tant que la tablette est ouverte)
RegisterNUICallback("nui:taxi:inputFocus", function(_, cb)
    cb("ok")
end)
RegisterNUICallback("nui:taxi:inputBlur", function(_, cb)
    cb("ok")
end)

-- ============================================
-- Menu principal: Liste des societes taxi
-- ============================================
function StaffMenu.BuildTaxiMenu()
    local societies = TriggerServerCallback('core:get:societies') or {}

    local taxiSocieties = {}
    for name, data in pairs(societies) do
        if data.type == "taxi" then
            taxiSocieties[#taxiSocieties + 1] = { name = name, label = data.label or name }
        end
    end

    table.sort(taxiSocieties, function(a, b)
        return string.lower(a.label) < string.lower(b.label)
    end)

    if #taxiSocieties == 0 then
        StaffMenu.builderTaxi.Button(
            "Aucune société taxi",
            "Créez une société de type taxi d'abord",
            nil, nil, true, function() end
        )
        return
    end

    for _, taxi in ipairs(taxiSocieties) do
        StaffMenu.builderTaxi.Button(
            taxi.label,
            "Gérer les paramètres de " .. taxi.label,
            nil, "chevron", false,
            function()
                selectedTaxiJob = taxi.name
                selectedTaxiLabel = taxi.label
                taxiJobData = TriggerServerCallback("core:get:societyData", taxi.name)
            end,
            StaffMenu.builderTaxiEdit
        )
    end
end

-- ============================================
-- Menu edition: Parametres d'une societe taxi
-- ============================================
function StaffMenu.BuildTaxiEditMenu()
    if not taxiJobData then
        StaffMenu.builderTaxiEdit.Button(
            "Erreur", "Aucune société sélectionnée",
            nil, nil, true, function() end
        )
        return
    end

    if not taxiJobData.custom then
        taxiJobData.custom = {}
    end

    StaffMenu.builderTaxiEdit.Separator("PARAMÈTRES")

    -- Tarif par metre
    StaffMenu.builderTaxiEdit.Button(
        "Tarif par mètre (" .. LOCALE.currencySymbol .. ")",
        "Prix par mètre de course",
        tostring(taxiJobData.custom.tarifPerMeter or "Non défini"),
        "edit", false,
        function()
            local value = VFW.Nui.KeyboardInput(true, "Tarif par mètre (" .. LOCALE.currencySymbol .. ")", tostring(taxiJobData.custom.tarifPerMeter or ""))
            value = tonumber(value)
            if value then
                taxiJobData.custom.tarifPerMeter = value
                StaffMenu.builderTaxiEdit.refresh()
            end
        end
    )

    -- Pourcentage joueur
    StaffMenu.builderTaxiEdit.Button(
        "Pourcentage joueur (%)",
        "Part du chauffeur sur la course",
        tostring(taxiJobData.custom.playerPercent or "Non défini"),
        "edit", false,
        function()
            local value = VFW.Nui.KeyboardInput(true, "Pourcentage joueur (%)", tostring(taxiJobData.custom.playerPercent or ""))
            value = tonumber(value)
            if value then
                taxiJobData.custom.playerPercent = value
                StaffMenu.builderTaxiEdit.refresh()
            end
        end
    )

    -- Timeout commande
    StaffMenu.builderTaxiEdit.Button(
        "Délai de commande (min)",
        "Temps avant expiration d'une commande",
        tostring(taxiJobData.custom.commandTimeout or "Non défini"),
        "edit", false,
        function()
            local value = VFW.Nui.KeyboardInput(true, "Délai de commande (minutes)", tostring(taxiJobData.custom.commandTimeout or ""))
            value = tonumber(value)
            if value then
                taxiJobData.custom.commandTimeout = value
                StaffMenu.builderTaxiEdit.refresh()
            end
        end
    )

    -- Zones de spawn → ouvre React
    StaffMenu.builderTaxiEdit.Separator("")

    local baseZones = TaxiJob.Config.BaseZones or {}
    local enabledCount = 0
    for _, zone in ipairs(baseZones) do
        if isBaseZoneEnabled(zone.key) then enabledCount = enabledCount + 1 end
    end
    local customCount = #(taxiJobData.custom.taxiSpawnZones or {})
    local totalZones = enabledCount + customCount

    StaffMenu.builderTaxiEdit.Button(
        "ZONES DE SPAWN",
        ("Gérer les zones de spawn (%d active%s)"):format(totalZones, totalZones > 1 and "s" or ""),
        tostring(totalZones),
        "chevron", false,
        function()
            openTaxiZoneEditor()
        end
    )

    -- Vehicules autorises
    if not taxiJobData.custom.allowedVehicles or #taxiJobData.custom.allowedVehicles == 0 then
        taxiJobData.custom.allowedVehicles = {}
        for _, v in ipairs(TaxiJob.Config.AllowedVehicles or {}) do
            taxiJobData.custom.allowedVehicles[#taxiJobData.custom.allowedVehicles + 1] = v
        end
    end

    StaffMenu.builderTaxiEdit.Separator("VÉHICULES AUTORISÉS")

    StaffMenu.builderTaxiEdit.Button(
        "+ Ajouter un véhicule",
        "Nom du modèle spawn (ex: dlrhinetaxi)",
        nil, "chevron", false,
        function()
            local modelName = VFW.Nui.KeyboardInput(true, "Nom du modèle véhicule (spawn name)", "")
            if not modelName or modelName == "" then return end
            if not taxiJobData.custom.allowedVehicles then
                taxiJobData.custom.allowedVehicles = {}
            end
            taxiJobData.custom.allowedVehicles[#taxiJobData.custom.allowedVehicles + 1] = modelName
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Taxi',
                message = ("Véhicule '%s' ajouté"):format(modelName)
            })
            StaffMenu.builderTaxiEdit.refresh()
        end
    )

    for k, v in pairs(taxiJobData.custom.allowedVehicles or {}) do
        StaffMenu.builderTaxiEdit.Button(
            v,
            "Véhicule autorisé #" .. k,
            nil, "trash", false,
            function()
                table.remove(taxiJobData.custom.allowedVehicles, k)
                StaffMenu.builderTaxiEdit.refresh()
            end
        )
    end

    StaffMenu.builderTaxiEdit.Separator("")

    -- Sauvegarder
    StaffMenu.builderTaxiEdit.Button(
        "SAUVEGARDER",
        "Enregistrer les modifications pour " .. selectedTaxiLabel,
        nil, "chevron", false,
        function()
            TriggerServerEvent("core:modify:society", selectedTaxiJob, taxiJobData)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Taxi',
                message = selectedTaxiLabel .. " mis à jour."
          })
        end
    )
end

-- ============================================
-- Enregistrement des callbacks OnOpen / OnClose
-- ============================================
StaffMenu.builderTaxi.OnOpen(function()
    StaffMenu.BuildTaxiMenu()
end)

StaffMenu.builderTaxiEdit.OnOpen(function()
    StaffMenu.BuildTaxiEditMenu()
end)
