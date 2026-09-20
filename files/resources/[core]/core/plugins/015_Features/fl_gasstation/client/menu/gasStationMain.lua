---@meta _
---@diagnostic disable: duplicate-doc-field

-- Menu principal pour la gestion des stations d'essence

--- Menu principal de gestion des stations d'essence
function StaffMenu.BuildGasStationMainMenu()
    StaffMenu.gasStationMain.Separator(":car: GESTION DES STATIONS D'ESSENCE")

    StaffMenu.gasStationMain.Button(":building: CRÉER UNE STATION", "Construire une nouvelle station essence", nil, "chevron", false, function()
        StaffMenu.gasStationBuilder.open()
    end)

    StaffMenu.gasStationMain.Button(":settings: GÉRER LES STATIONS CRÉÉES", "Configuration et liste des stations", nil, "chevron", false, function()
        StaffMenu.gasStationConfig.open()
    end)

end

-- Enregistrer le menu principal avec délai pour s'assurer que VUI est prêt
CreateThread(function()
    Wait(1000) -- Attendre que tout soit chargé

    if StaffMenu and StaffMenu.gasStationMain then
        StaffMenu.BuildGasStationMainMenu = StaffMenu.BuildGasStationMainMenu

        -- Enregistrer l'événement OnOpen pour le menu principal
        if StaffMenu.gasStationMain.OnOpen then
            StaffMenu.gasStationMain.OnOpen(function()
                StaffMenu.BuildGasStationMainMenu()
            end)
        end
    end
end)