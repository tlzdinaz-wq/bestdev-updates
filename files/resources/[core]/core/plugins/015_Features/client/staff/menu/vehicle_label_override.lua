local currentEdit = { model = nil, label = nil, existing = false }

local function resetEdit()
    currentEdit.model = nil
    currentEdit.label = nil
    currentEdit.existing = false
end

local function getDefaultLabelFor(model)
    if type(model) ~= "string" or model == "" then return "" end
    local hash <const> = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return ""
  end
    local make = GetMakeNameFromVehicleModel(model) or ""
  local name = GetLabelText(model) or model
    if name == "NULL" then name = model end
    if make ~= "" then
        return make .. " " .. name
    end
    return name
end

function StaffMenu.BuildVehicleLabelOverridesMenu()
    StaffMenu.vehicleLabelOverrides.ClearItems()

    StaffMenu.vehicleLabelOverrides.Button("Ajouter une personnalisation", "Définir un nouveau label personnalisé", nil, "chevron", false, function()
        resetEdit()
    end, StaffMenu.vehicleLabelOverridesEdit)

    StaffMenu.vehicleLabelOverrides.Separator("Personnalisations existantes")

    local overrides = TriggerServerCallback("garage:labelOverride:getAll") or {}

    local sorted = {}
    for model, label in pairs(overrides) do
        sorted[#sorted + 1] = { model = model, label = label }
    end
    table.sort(sorted, function(a, b) return a.model < b.model end)

    if #sorted == 0 then
        StaffMenu.vehicleLabelOverrides.Button("Aucun override", "La liste est vide", nil, "empty", true, function() end)
        return
    end

    for i = 1, #sorted do
        local entry = sorted[i]
        StaffMenu.vehicleLabelOverrides.Button(entry.label, entry.model, nil, "chevron", false, function()
            currentEdit.model = entry.model
            currentEdit.label = entry.label
            currentEdit.existing = true
        end, StaffMenu.vehicleLabelOverridesEdit)
    end
end

function StaffMenu.BuildVehicleLabelOverrideEditMenu()
    StaffMenu.vehicleLabelOverridesEdit.ClearItems()

    local modelSubtitle = currentEdit.model and currentEdit.model ~= "" and currentEdit.model or "Non défini"
  local modelLocked = currentEdit.existing == true

    StaffMenu.vehicleLabelOverridesEdit.Button("Nom technique", modelSubtitle, nil, "chevron", modelLocked, function()
        local input = VFW.Nui.KeyboardInput(true, "Entrez le nom technique (ex: adder)")
        if not input or input == "" then return end
        local cleaned = input:lower():gsub("%s+", "")
        if cleaned == "" then return end
        currentEdit.model = cleaned
        if not currentEdit.label or currentEdit.label == "" then
            currentEdit.label = getDefaultLabelFor(cleaned)
        end
        StaffMenu.vehicleLabelOverridesEdit.refresh()
    end)

    local hasModel = currentEdit.model and currentEdit.model ~= ""
  local labelDisabled = not hasModel
    local labelSubtitle = (currentEdit.label and currentEdit.label ~= "") and currentEdit.label or "Sans nom"

  StaffMenu.vehicleLabelOverridesEdit.Button("Label", labelSubtitle, nil, "chevron", labelDisabled, function()
        local input = VFW.Nui.KeyboardInput(true, "Entrez le nouveau label")
        if not input or input == "" then return end
        currentEdit.label = input
        StaffMenu.vehicleLabelOverridesEdit.refresh()
    end)

    StaffMenu.vehicleLabelOverridesEdit.Separator("Actions")

    local saveDisabled = not hasModel or not currentEdit.label or currentEdit.label == ""
  StaffMenu.vehicleLabelOverridesEdit.Button("Sauvegarder", "", nil, "check", saveDisabled, function()
        local ok = TriggerServerCallback("garage:labelOverride:set", currentEdit.model, currentEdit.label)
        if ok then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Label véhicule', content = "Label enregistré pour " .. currentEdit.model .. "." })
            resetEdit()
            StaffMenu.vehicleLabelOverridesEdit.close()
            StaffMenu.vehicleLabelOverrides.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Label véhicule', content = "Échec de la sauvegarde." })
        end
    end)

    if currentEdit.existing then
        StaffMenu.vehicleLabelOverridesEdit.Button("Supprimer la personnalisation", "", nil, "trash", false, function()
            local ok = TriggerServerCallback("garage:labelOverride:delete", currentEdit.model)
            if ok then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Label véhicule', content = "Personnalisation supprimée." })
                resetEdit()
                StaffMenu.vehicleLabelOverridesEdit.close()
                StaffMenu.vehicleLabelOverrides.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Label véhicule', content = "Échec de la suppression." })
            end
        end)
    end
end
