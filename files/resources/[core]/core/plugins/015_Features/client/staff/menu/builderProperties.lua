---@meta _
---@diagnostic disable: duplicate-doc-field

local staffBlips = {}

local typeLabels = {
    ["Habitation"] = "Habitation",
    ["Garage"] = "Garage",
    ["Stockage"] = "Entrepot",
    [1] = "Habitation",
    [2] = "Garage",
    [3] = "Entrepot"
}

--- Remove all staff blips
local function RemoveStaffBlips()
    for _, blip in pairs(staffBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    staffBlips = {}
end

--- Properties menu
StaffMenu.builderProperties.OnOpen(function()
    StaffMenu.builderProperties.ClearItems()

    StaffMenu.builderProperties.Separator("GESTION PROPRIETES")

    StaffMenu.builderProperties.Button("Afficher TOUS les blips", "Crée des blips rouges pour toutes les propriétés", nil, "chevron", false, function()
        local properties = TriggerServerCallback("staff:showAllPropertyBlips")
        if not properties or next(properties) == nil then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Propriétés', message = 'Aucune propriété trouvée.' })
            return
        end

        -- Remove existing staff blips first
        RemoveStaffBlips()

        local count = 0
        for id, prop in pairs(properties) do
            if prop.pos then
                local blip = AddBlipForCoord(prop.pos.x, prop.pos.y, prop.pos.z)
                SetBlipSprite(blip, 40)
                SetBlipScale(blip, 0.5)
                SetBlipColour(blip, 1) -- Red
                SetBlipAsShortRange(blip, false)
                BeginTextCommandSetBlipName("STRING")
                local label = (typeLabels[prop.type] or "?") .. " #" .. tostring(id) .. " - " .. (prop.name or "")
                AddTextComponentString(label)
                EndTextCommandSetBlipName(blip)
                staffBlips[id] = blip
                count = count + 1
            end
        end

        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Propriétés', message = count .. ' blips affichés sur la carte.' })
    end)

    StaffMenu.builderProperties.Button("Masquer les blips staff", "Supprime les blips staff de la carte", nil, "chevron", false, function()
        local count = 0
        for _ in pairs(staffBlips) do count = count + 1 end
        RemoveStaffBlips()
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Propriétés', message = count .. ' blips supprimés.' })
    end)

    StaffMenu.builderProperties.Button("Liste des propriétés", "Voir toutes les propriétés du serveur", nil, "chevron", false, function()
    end, StaffMenu.builderPropertiesList)
end)

--- Properties list submenu
local propertiesSearchQuery = nil

StaffMenu.builderPropertiesList.OnOpen(function()
    StaffMenu.builderPropertiesList.ClearItems()

    StaffMenu.builderPropertiesList.Separator("LISTE DES PROPRIETES")

    -- Search button
    StaffMenu.builderPropertiesList.Button(
        propertiesSearchQuery and ("RECHERCHER: " .. propertiesSearchQuery) or "RECHERCHER",
        propertiesSearchQuery and "Cliquer pour réinitialiser" or "Filtrer par nom, ID ou type",
        nil, "search", false,
        function()
            if propertiesSearchQuery then
                propertiesSearchQuery = nil
                StaffMenu.builderPropertiesList.refresh()
                return
            end
            propertiesSearchQuery = VFW.Nui.KeyboardInput(true, "Rechercher une propriété...")
            if propertiesSearchQuery == nil or propertiesSearchQuery == "" then
                propertiesSearchQuery = nil
                return
            end
            StaffMenu.builderPropertiesList.refresh()
        end
    )

    -- Fetch all properties
    local properties = TriggerServerCallback("staff:getAllProperties", propertiesSearchQuery)
    if not properties or #properties == 0 then
        StaffMenu.builderPropertiesList.Button("Aucune propriété trouvée", "", nil, "chevron", false, function() end)
        return
    end

    StaffMenu.builderPropertiesList.Separator(#properties .. (#properties > 1 and " résultats" or " résultat"))

    for _, prop in ipairs(properties) do
        local typeLabel = typeLabels[prop.type] or "?"
      local label = ("[%s] #%d - %s"):format(typeLabel, prop.id, prop.name or "Sans nom")
        local desc = "Proprio: " .. (prop.ownerName or "Inconnu")

        StaffMenu.builderPropertiesList.Button(label, desc, nil, "chevron", false, function()
            if prop.pos then
                -- Remove previous single property blip if exists
                if staffBlips["single"] and DoesBlipExist(staffBlips["single"]) then
                    RemoveBlip(staffBlips["single"])
                end

                local blip = AddBlipForCoord(prop.pos.x, prop.pos.y, prop.pos.z)
                SetBlipSprite(blip, 40)
                SetBlipScale(blip, 0.5)
                SetBlipColour(blip, 2) -- Green
                SetBlipAsShortRange(blip, false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(("[%s] #%d - %s"):format(typeLabel, prop.id, prop.name or ""))
                EndTextCommandSetBlipName(blip)
                staffBlips["single"] = blip

                SetNewWaypoint(prop.pos.x, prop.pos.y)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Propriété', message = 'GPS défini vers ' .. (prop.name or "#" .. prop.id) })
            end
        end)
    end
end)
