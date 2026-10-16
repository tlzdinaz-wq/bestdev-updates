local VUI <const> = exports["VUI"]
local bIsOpen = false

local RentalBuilder = StaffMenu.CreateRental
local RentalManager = StaffMenu.ManageRental
local RentalEditor = StaffMenu.EditRental

local eCurrentPed
local eCurrentVehicle = {}
local tLocationTypes <const> = {"normal", "bateau", "cayo"}


local function fcDeletePreview(sType, iNumber)
    if sType == "ped" then
        if DoesEntityExist(eCurrentPed) then
            DeleteEntity(eCurrentPed)
            eCurrentPed = nil
        end
    elseif sType == "vehicle" then
        if eCurrentVehicle[iNumber] and DoesEntityExist(eCurrentVehicle[iNumber]) then
            DeleteEntity(eCurrentVehicle[iNumber])
            eCurrentVehicle[iNumber] = nil
        end
    end
end

local function fcSpawnPreview(sType, sModel, tPos, iNumber)
    local eEntity
    fcDeletePreview(sType, iNumber)
    if not tPos or not tPos.x or not tPos.y or not tPos.z then return nil end

    if sType == "ped" then
        eEntity = VFW.CreatePed(tPos, sModel)
        eCurrentPed = eEntity

    elseif sType == "vehicle" then
        eEntity = VFW.Game.SpawnVehicle(sModel, tPos, tPos.w, nil, false)
        if not eEntity or not DoesEntityExist(eEntity) then return nil end
        SetVehicleOnGroundProperly(eEntity)
        FreezeEntityPosition(eEntity, true)

        eCurrentVehicle[iNumber] = eEntity
    end

    if not eEntity or not DoesEntityExist(eEntity) then return nil end

    SetEntityAlpha(eEntity, 200, false)
    SetEntityCollision(eEntity, false, true)

    return eEntity
end

local function fcRefresh(Menu)
    bIsOpen = true
    Menu.refresh()
    bIsOpen = false
end

local function fcGetIcon(args)
    if args then
        return "check"
  else
        return "chevron"
  end
end

local function fcGetDefaultValue()
    return {
        iType = 1,
        sName = nil,
        tPos = nil,
        sPedModel = "a_m_y_smartcaspat_01",
        tVehiclePos = {},
        bIsValid = false,
    }
end

local tData

local function fcHasCoords(tPos)
    return type(tPos) == "table" and tonumber(tPos.x) and tonumber(tPos.y) and tonumber(tPos.z)
end

local function fcHasVehicleSpawn(iIndex)
    return type(tData.tVehiclePos) == "table" and fcHasCoords(tData.tVehiclePos[iIndex])
end



tData = fcGetDefaultValue()
local adminBanner <const> = GetVUIBanner("admin")
RentalBuilder = VUI:CreateSubMenu(StaffMenu.builderCarRental, "CRÉER UNE LOCATION DE VEHICULE", adminBanner, true)
RentalManager = VUI:CreateSubMenu(StaffMenu.builderCarRental, "GÉRER LES LOCATIONS DE VEHICULE", adminBanner, true)
RentalEditor = VUI:CreateSubMenu(RentalManager, "MODIFIER LES LOCATIONS", adminBanner, true)

local VehicleConfigMenu = VUI:CreateSubMenu(StaffMenu.builderCarRental, "GÉRER LES VÉHICULES", adminBanner, true)
local VehicleConfigType = VUI:CreateSubMenu(VehicleConfigMenu, "VÉHICULES PAR TYPE", adminBanner, true)
local VehicleConfigEditor = VUI:CreateSubMenu(VehicleConfigType, "MODIFIER VÉHICULE", adminBanner, true)
local VehicleConfigAdd = VUI:CreateSubMenu(VehicleConfigMenu, "AJOUTER UN VÉHICULE", adminBanner, true)

local tSelectedVehicle = nil
local iSelectedType = 1
local tTypeLabels <const> = {
    [1] = "Normal",
    [2] = "Bateau",
    [3] = "Cayo"
}

function StaffMenu.BuildVehicleRentalMenu()
    StaffMenu.builderCarRental.Button(":plus: CRÉER UNE LOCATION DE VEHICULE", "Ajouter un nouveau point de location de véhicule", nil, "chevron", false, function()
        selectedBlip = getBlipDefaultData()
    end, RentalBuilder)

    StaffMenu.builderCarRental.Button(":settings: GÉRER LES LOCATION DE VEHICULE", "Modifier ou supprimer des points de location de véhicule", nil, "chevron", false, function()
    end, RentalManager)

    StaffMenu.builderCarRental.Button(":car: GÉRER LES VÉHICULES", "Configurer les véhicules et leurs prix", nil, "chevron", false, function()
    end, VehicleConfigMenu)
end

local iCurrentCategory = 1

local function fcBuildRentalMenu(Menu)
    Menu.List('Catégory', nil, false, { "Information Générales", "Emplacement des véhicules" }, iCurrentCategory, function(Index)
        iCurrentCategory = Index
        fcRefresh(Menu)
    end)

    if iCurrentCategory == 1 then

        Menu.Separator("INFORMATIONS GENERALES")

        Menu.List('Type de Location', nil, false, tLocationTypes, tData.iType, function(Index)
            tData.iType = Index
            fcRefresh(Menu)
        end)

        Menu.Button("NOM DE LA LOCATION", tData.sName or "Non défini", nil, fcGetIcon(tData.sName), false, function()
            local sInput <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom de la Location", "")
            if sInput == "" then return end

            tData.sName = sInput

            bIsOpen = true
            fcRefresh(Menu)
        end)

        Menu.Button("POSITION", fcHasCoords(tData.tPos) and "Définie" or "Non définie", nil, fcGetIcon(fcHasCoords(tData.tPos)), false, function()
            local tPos = GetEntityCoords(PlayerPedId()) - vector3(0.0, 0.0, 1.0)
            tData.tPos = {x = tPos.x, y = tPos.y, z = tPos.z, w = GetEntityHeading(PlayerPedId())}

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Location Véhicules',
                message = "Position du point PED enregistrée"
          })

            fcSpawnPreview("ped", tData.sPedModel, tData.tPos)

            fcRefresh(Menu)
        end)

        Menu.Button("ORIENTATION DU PED", tostring(tData.tPos and tData.tPos.w or 0) .. "°", nil, fcGetIcon(fcHasCoords(tData.tPos)), false, function()
            local sInput = VFW.Nui.KeyboardInput(true, "Entrer l'orientation du ped (0-360)")
            if sInput == "" or not tonumber(sInput) or not fcHasCoords(tData.tPos) then return end

            tData.tPos.w = math.max(0, math.min(360, tonumber(sInput)))

            if DoesEntityExist(eCurrentPed) then
                SetEntityHeading(eCurrentPed, tData.tPos.w + 0.0)
            end

            fcRefresh(Menu)
        end)

        Menu.Button("MODEL DU PED", tData.sPedModel or "Non défini", nil, "check", false, function()
            local sInput = VFW.Nui.KeyboardInput(true, "Entrer le nom du modèle", "")
            if sInput == "" or not IsModelValid(sInput) then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Location Véhicules',
                    message = "Ce modèle n'est pas valide"
              })
                return
            end

            tData.sPedModel = sInput

            if tData.tPos then
                fcSpawnPreview("ped", tData.sPedModel, tData.tPos)
            end

            fcRefresh(Menu)
        end)
    elseif iCurrentCategory == 2 then
        Menu.Separator("EMPLACEMENTS DES VEHICULES")

        for i=1,2 do

            Menu.Button("Définir Spawn "..i, fcHasVehicleSpawn(i) and "Définie" or "Non définie", nil, fcGetIcon(fcHasVehicleSpawn(i)), false, function()
                local tPos = GetEntityCoords(PlayerPedId()) - vector3(0.0, 0.0, 1.0)
                tData.tVehiclePos[i] = {x = tPos.x, y = tPos.y, z = tPos.z, w = GetEntityHeading(PlayerPedId())}
                fcSpawnPreview("vehicle", "cog55", tData.tVehiclePos[i], i)
                fcRefresh(Menu)
            end)

            Menu.Button("Orientation Spawn "..i, tostring(tData.tVehiclePos[i] and tData.tVehiclePos[i].w or 0) .. "°", nil, fcGetIcon(fcHasVehicleSpawn(i)), false, function()
                if not fcHasVehicleSpawn(i) then return end

                local sInput = VFW.Nui.KeyboardInput(true, "Entrer l'orientation de la voiture (0-360)")
                if sInput == "" or not tonumber(sInput) then return end

                tData.tVehiclePos[i].w = math.max(0, math.min(360, tonumber(sInput)))
                if DoesEntityExist(eCurrentVehicle[i]) then
                    SetEntityHeading(eCurrentVehicle[i], tData.tVehiclePos[i].w + 0.0)
                end

                fcRefresh(Menu)
            end)
        end
    end
end

local function fcCloseMenu()
    fcDeletePreview("ped")
    fcDeletePreview("vehicle", 1)
    fcDeletePreview("vehicle", 2)
    tData = fcGetDefaultValue()
end

RentalBuilder.OnOpen(function()

    fcBuildRentalMenu(RentalBuilder)

    RentalBuilder.Separator("ACTIONS")

    local sStatusMessage = ""
    tData.bIsValid = false
  if not tData.sName or tostring(tData.sName):gsub("%s+", "") == "" then
        sStatusMessage = "Nom manquant"
  elseif not tData.iType then
        sStatusMessage = "Type de location manquant"
  elseif not fcHasCoords(tData.tPos) then
        sStatusMessage = "Position du ped manquante"
  elseif not fcHasVehicleSpawn(1) then
        sStatusMessage = "Position du spawn 1 manquante"
  else
        tData.bIsValid = true
        sStatusMessage = "Tous les champs sont remplis"
  end

    local sIcon = tData.bIsValid and "check" or "lock"

  RentalBuilder.Button(":check: Créer la location", sStatusMessage, nil, sIcon, false, function()
        if not tData.bIsValid then
            if sStatusMessage == "Position du spawn 1 manquante" then
                iCurrentCategory = 2
                fcRefresh(RentalBuilder)
            end
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Location Véhicules',
                message = "~r~" .. sStatusMessage .. ".~s~"
          })
            return
        end

        TriggerServerEvent("core:createVehicleRental", tData)
        RentalBuilder.close()

        StaffMenu.builderCarRental.open()
    end)


end)

RentalBuilder.OnClose(function()
    if bIsOpen then return end

    fcCloseMenu()
end)

RentalManager.OnOpen(function()
    local tVehicleRental = TriggerServerCallback("core:getAllVehicleRental") or {}

    for _, tRental in pairs(tVehicleRental) do
        RentalManager.Button(tRental.sName, "Type: " .. tLocationTypes[tRental.iType] .. "\nID: " .. tRental.iId, nil, "chevron", false, function()
            tData = tRental
        end, RentalEditor)
    end
end)

RentalEditor.OnOpen(function()

    local iDist = #(GetEntityCoords(PlayerPedId()) - vec3(tData.tPos.x, tData.tPos.y, tData.tPos.z))
    if iDist > 200 then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Location Véhicules',
            message = "~r~Vous êtes trop loin du point de location pour voir l'aperçu, rouvrez le menu une fois sur place.~s~"
      })
    else
        fcSpawnPreview("ped", tData.sPedModel, tData.tPos)

        for i=1,2 do
            fcSpawnPreview("vehicle", "cog55", tData.tVehiclePos[i], i)
        end
    end



    RentalEditor.Button("Se Téleporter au point", "", nil, "chevron", false, function()
        if not tData.tPos then return end

        SetEntityCoordsNoOffset(PlayerPedId(), tData.tPos.x, tData.tPos.y, tData.tPos.z, false, false, true)
    end)

    RentalEditor.Separator("")

    fcBuildRentalMenu(RentalEditor)

    RentalEditor.Separator("ACTIONS")

    RentalEditor.Button(":save: Sauvegarder les modifications", "Enregistrer les modifications apportées à la location", nil, "check", false, function()
        if not tData.iId then return end

        local bResponse <const> = VFW.Nui.ValideInput(true, "Êtes-vous sûr de vouloir modifier cette location ?")

        if bResponse then
            TriggerServerEvent("core:editVehicleRental", tData)
            RentalEditor.close()

            StaffMenu.builderCarRental.open()
        end
    end)

    RentalEditor.Button(":trash: Supprimer la location", "Supprimer définitivement cette location de véhicule", nil, "trash", false, function()
        if not tData.iId then return end

        local confirmResult = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour supprimer", "")
        if confirmResult and confirmResult:upper() == "CONFIRMER" then
            TriggerServerEvent("core:deleteVehicleRental", tData.iId)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Location Véhicules',
                message = "Location '" .. (tData.sName or "Inconnue") .. "' supprimée"
          })
            RentalEditor.close()
            SetTimeout(500, function()
                StaffMenu.builderCarRental.open()
            end)
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'INFO',
                subtitle = 'Location Véhicules',
                message = "Suppression annulée."
          })
        end
    end)
end)

RentalEditor.OnClose(function()
    if bIsOpen then return end
    fcCloseMenu()
end)

VehicleConfigMenu.OnOpen(function()
    local tVehicleConfig = TriggerServerCallback("core:vehicleRental:getVehicleConfig") or {}

    VehicleConfigMenu.Separator(":chart: STATISTIQUES")

    local iTotalVehicles = 0
    for iType = 1, 3 do
        if tVehicleConfig[iType] then
            iTotalVehicles = iTotalVehicles + #tVehicleConfig[iType]
        end
    end

    VehicleConfigMenu.Button(":chart: TOTAL VÉHICULES", tostring(iTotalVehicles) .. (iTotalVehicles > 1 and " véhicules" or " véhicule"), nil, nil, true, function() end)

    VehicleConfigMenu.Separator(":report: PAR TYPE")

    for iType = 1, 3 do
        local tVehicles = tVehicleConfig[iType] or {}
        local iCount = #tVehicles

        VehicleConfigMenu.Button(":car: " .. tTypeLabels[iType]:upper(), iCount .. (iCount > 1 and " véhicules" or " véhicule"), nil, "chevron", false, function()
            iSelectedType = iType
        end, VehicleConfigType)
    end

    VehicleConfigMenu.Separator(":plus: ACTIONS")

    VehicleConfigMenu.Button(":plus: AJOUTER UN VÉHICULE", "Ajouter un nouveau véhicule à la location", nil, "chevron", false, function()
    end, VehicleConfigAdd)
end)

VehicleConfigType.OnOpen(function()
    local tVehicleConfig = TriggerServerCallback("core:vehicleRental:getVehicleConfig") or {}
    local tVehicles = tVehicleConfig[iSelectedType] or {}

    VehicleConfigType.Separator(":car: VÉHICULES - " .. tTypeLabels[iSelectedType]:upper())

    if #tVehicles == 0 then
        VehicleConfigType.Button(":document: AUCUN VÉHICULE", "Aucun véhicule configuré", nil, nil, true, function() end)
    else
        for _, tVehicle in ipairs(tVehicles) do
            VehicleConfigType.Button(":car: " .. tVehicle.label, "Model: " .. tVehicle.name .. "\nPrix: " .. VFW.Math.FormatMoney(tVehicle.price), nil, "chevron", false, function()
                tSelectedVehicle = tVehicle
            end, VehicleConfigEditor)
        end
    end

    VehicleConfigType.Separator("")
    VehicleConfigType.Button(":refresh: ACTUALISER", "Recharger la liste", nil, "chevron", false, function()
        bIsOpen = true
        VehicleConfigType.refresh()
        bIsOpen = false
    end)
end)

VehicleConfigEditor.OnOpen(function()
    if not tSelectedVehicle then return end

    VehicleConfigEditor.Separator(":car: " .. tSelectedVehicle.label)

    VehicleConfigEditor.Button(":id: ID", tostring(tSelectedVehicle.id), nil, nil, true, function() end)
    VehicleConfigEditor.Button(":edit: MODEL", tSelectedVehicle.name, nil, nil, true, function() end)

    VehicleConfigEditor.Button(":tag: LABEL", tSelectedVehicle.label, nil, "chevron", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nouveau label", tSelectedVehicle.label)
        if sInput and sInput ~= "" then
            tSelectedVehicle.label = sInput
            bIsOpen = true
            VehicleConfigEditor.refresh()
            bIsOpen = false
        end
    end)

    VehicleConfigEditor.Button(":money: PRIX", VFW.Math.FormatMoney(tSelectedVehicle.price), nil, "chevron", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nouveau prix", tostring(tSelectedVehicle.price))
        if sInput and tonumber(sInput) then
            tSelectedVehicle.price = tonumber(sInput)
            bIsOpen = true
            VehicleConfigEditor.refresh()
            bIsOpen = false
        end
    end)

    VehicleConfigEditor.Separator(":wrench: ACTIONS")

    VehicleConfigEditor.Button(":save: SAUVEGARDER", "Enregistrer les modifications", nil, "check", false, function()
        TriggerServerEvent("core:vehicleRental:updateVehicle", tSelectedVehicle.id, tSelectedVehicle.label, tSelectedVehicle.price)
        VehicleConfigEditor.close()
        SetTimeout(500, function()
            VehicleConfigType.open()
        end)
    end)

    VehicleConfigEditor.Button(":trash: SUPPRIMER", "Supprimer ce véhicule", nil, "trash", false, function()
        local confirmResult = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour supprimer", "")
        if confirmResult and confirmResult:upper() == "CONFIRMER" then
            TriggerServerEvent("core:vehicleRental:deleteVehicle", tSelectedVehicle.id)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Location Véhicules',
                message = "Véhicule '" .. tSelectedVehicle.label .. "' supprimé"
          })
            VehicleConfigEditor.close()
            SetTimeout(500, function()
                VehicleConfigType.open()
            end)
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'INFO',
                subtitle = 'Location Véhicules',
                message = "Suppression annulée."
          })
        end
    end)
end)

local tNewVehicle = {
    iType = 1,
    sName = "",
    sLabel = "",
    iPrice = 100
}

VehicleConfigAdd.OnOpen(function()
    VehicleConfigAdd.Separator(":plus: AJOUTER UN VÉHICULE")

    VehicleConfigAdd.List('TYPE', nil, false, {"Normal", "Bateau", "Cayo"}, tNewVehicle.iType, function(Index)
        tNewVehicle.iType = Index
        bIsOpen = true
        VehicleConfigAdd.refresh()
        bIsOpen = false
    end)

    VehicleConfigAdd.Button(":edit: MODEL", tNewVehicle.sName ~= "" and tNewVehicle.sName or "Non défini", nil, fcGetIcon(tNewVehicle.sName ~= ""), false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nom du modèle (ex: adder, sultan)", "")
        if sInput and sInput ~= "" then
            tNewVehicle.sName = sInput
            if tNewVehicle.sLabel == "" then
                tNewVehicle.sLabel = sInput:sub(1,1):upper() .. sInput:sub(2)
            end
            bIsOpen = true
            VehicleConfigAdd.refresh()
            bIsOpen = false
        end
    end)

    VehicleConfigAdd.Button(":tag: LABEL", tNewVehicle.sLabel ~= "" and tNewVehicle.sLabel or "Non défini", nil, fcGetIcon(tNewVehicle.sLabel ~= ""), false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Label affiché", tNewVehicle.sLabel)
        if sInput and sInput ~= "" then
            tNewVehicle.sLabel = sInput
            bIsOpen = true
            VehicleConfigAdd.refresh()
            bIsOpen = false
        end
    end)

    VehicleConfigAdd.Button(":money: PRIX", VFW.Math.FormatMoney(tNewVehicle.iPrice), nil, "check", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Prix de location", tostring(tNewVehicle.iPrice))
        if sInput and tonumber(sInput) then
            tNewVehicle.iPrice = tonumber(sInput)
            bIsOpen = true
            VehicleConfigAdd.refresh()
            bIsOpen = false
        end
    end)

    VehicleConfigAdd.Separator(":wrench: ACTIONS")

    local bCanCreate = tNewVehicle.sName ~= "" and tNewVehicle.sLabel ~= ""
  local sStatus = bCanCreate and "Prêt à créer" or "Model et Label requis"

  VehicleConfigAdd.Button(":check: CRÉER", sStatus, nil, bCanCreate and "check" or "lock", not bCanCreate, function()
        if not bCanCreate then return end

        TriggerServerEvent("core:vehicleRental:addVehicle", tNewVehicle.iType, tNewVehicle.sName, tNewVehicle.sLabel, tNewVehicle.iPrice)

        tNewVehicle = {
            iType = 1,
            sName = "",
            sLabel = "",
            iPrice = 100
        }

        VehicleConfigAdd.close()
        SetTimeout(500, function()
            VehicleConfigMenu.open()
        end)
    end)
end)

VehicleConfigAdd.OnClose(function()
    if bIsOpen then return end
    tNewVehicle = {
        iType = 1,
        sName = "",
        sLabel = "",
        iPrice = 100
    }
end)
