-- Builder Deleted Properties
-- View, restore, or permanently delete archived properties

local selectedDeletedProp = nil
local deletedPropertiesList = {}
local selectedChestItems = {}

local typeNames = {
    [1] = "Habitation",
    [2] = "Garage",
    [3] = "Stockage"
}

-- Date formatting is done server-side (os.date not available client-side)

-- ==================== MENU LISTE ====================

StaffMenu.builderDeletedProps.OnOpen(function()
    deletedPropertiesList = TriggerServerCallback("staff:getDeletedProperties") or {}

    StaffMenu.builderDeletedProps.Separator("PROPRIETES SUPPRIMEES")

    if #deletedPropertiesList == 0 then
        StaffMenu.builderDeletedProps.Button("Aucune propriété", "Aucune propriété supprimée trouvée", nil, "info", true, function()
        end)
        return
    end

    for i, prop in ipairs(deletedPropertiesList) do
        local typeName = typeNames[prop.type] or "Inconnu"
      local label = ("[%s] %s"):format(typeName, prop.name)
        local desc = ("Supprime le %s - %s"):format(prop.deleted_at_formatted or "Inconnue", prop.delete_reason or "manual")

        StaffMenu.builderDeletedProps.Button(label, desc, nil, "chevron", false, function()
            selectedDeletedProp = prop
        end, StaffMenu.deletedPropDetails)
    end
end)

-- ==================== MENU DETAILS ====================

StaffMenu.deletedPropDetails.OnOpen(function()
    if not selectedDeletedProp then
        return
    end

    local prop = selectedDeletedProp

    -- Chest info
    if prop.chest_data and prop.chest_data ~= "" and prop.chest_data ~= "[]" then
        local items = json.decode(prop.chest_data) or {}
        local itemCount = #items
        -- Use server-computed totalWeight (enriched with VFW.Items weights)
        local totalWeight = prop.chest_totalWeight or 0

        StaffMenu.deletedPropDetails.Separator("COFFRE")
        StaffMenu.deletedPropDetails.Button("Items", tostring(itemCount) .. (itemCount > 1 and " items" or " item"), nil, "chevron", false, function()
            selectedChestItems = items
        end, StaffMenu.deletedPropChestItems)
        StaffMenu.deletedPropDetails.Button("Poids", ("%.1f / %.1f kg"):format(totalWeight, prop.chest_maxWeight or 0), nil, "info", true, function()
        end)
    end

    StaffMenu.deletedPropDetails.Separator("ACTIONS")

    -- Restore button
    StaffMenu.deletedPropDetails.Button("RESTAURER", "Restaurer la propriété et son coffre", nil, "chevron", false, function()
        local result = TriggerServerCallback("staff:restoreProperty", prop.id)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Proprietes', message = result.message })
            StaffMenu.builderDeletedProps.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Proprietes', message = result and result.message or "Erreur inconnue" })
        end
    end)

    -- Permanent delete button
    StaffMenu.deletedPropDetails.Button("SUPPRIMER DÉFINITIVEMENT", "Suppression irréversible", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour confirmer la suppression définitive", "")
        if input and string.lower(input) == "oui" then
            local result = TriggerServerCallback("staff:permanentDeleteProperty", prop.id)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Proprietes', message = result.message })
                StaffMenu.builderDeletedProps.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Proprietes', message = result and result.message or "Erreur inconnue" })
            end
        end
    end)
end)

-- ==================== MENU CONTENU COFFRE ====================

StaffMenu.deletedPropChestItems.OnOpen(function()
    StaffMenu.deletedPropChestItems.Separator("CONTENU DU COFFRE")

    if not selectedChestItems or #selectedChestItems == 0 then
        StaffMenu.deletedPropChestItems.Button("Coffre vide", "Aucun item dans le coffre", nil, "info", true, function() end)
        return
    end

    for _, item in ipairs(selectedChestItems) do
        local label = item.label or item.name or "Inconnu"
      local count = item.count or 1
        local weight = item.weight or 0
        local totalW = weight * count
        local desc = ("x%d - %.1f kg"):format(count, totalW)

        StaffMenu.deletedPropChestItems.Button(label, desc, nil, "info", false, function() end)
    end
end)
