local bIsOpen = false
local eCurrentVehicle = {}

local function fcDeletePreview(iNumber)
    if eCurrentVehicle[iNumber] and DoesEntityExist(eCurrentVehicle[iNumber]) then
        DeleteEntity(eCurrentVehicle[iNumber])
        eCurrentVehicle[iNumber] = nil
    end
end

local function fcSpawnPreview(sModel, tPos, iNumber)
    fcDeletePreview(iNumber)

    local eEntity = VFW.Game.SpawnVehicle(sModel, tPos, tPos.w, nil, false)
    SetVehicleOnGroundProperly(eEntity)
    FreezeEntityPosition(eEntity, true)
    SetEntityAlpha(eEntity, 200, false)
    SetEntityCollision(eEntity, false, true)

    eCurrentVehicle[iNumber] = eEntity

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

local function getPoundDefaultData()
    return {
        label = nil,
        position = {},
        spawnPositions = {},
        useMarker = false,
        pedModel = "a_m_y_business_02",
        price = 500,
        zone = nil
    }
end

local POUND_ZONE_OPTIONS = { "Los Santos", "Cayo Perico" }

local function poundZoneToIndex(zone)
    if zone == "cayo" then return 2 end
    return 1
end

local function poundZoneFromIndex(index)
    if index == 2 then return "cayo" end
    return nil
end

local function fcCloseMenu()
    for i, _ in pairs(eCurrentVehicle) do
        fcDeletePreview(i)
    end
end

local poundSelected = getPoundDefaultData()
local pounds = {}
local iCurrentCategory = 1

local VUI = exports["VUI"]

local adminBanner = exports["core"]:GetVUIBanner("admin")
StaffMenu.createPound = VUI:CreateSubMenu(StaffMenu.builders, "FOURRIÈRE", adminBanner, true)
StaffMenu.createPoundData = VUI:CreateSubMenu(StaffMenu.createPound, "DONNÉES DE FOURRIÈRE", adminBanner, true)
StaffMenu.modifyPound = VUI:CreateSubMenu(StaffMenu.createPound, "APERÇU MODIFICATION DE FOURRIÈRE", adminBanner, true)

StaffMenu.createPound.OnOpen(function()
    StaffMenu.BuildCreatePoundMenu()
end)

function StaffMenu.BuildCreatePoundMenu()
    pounds = TriggerServerCallback("core:getAllPounds") or {}

    StaffMenu.createPound.Button("Ajouter une fourrière", "", nil, "chevron", false, function()
        poundSelected = getPoundDefaultData()
        iCurrentCategory = 1
    end, StaffMenu.createPoundData)

    StaffMenu.createPound.Separator("Fourrières")

    for i, data in pairs(pounds) do
        StaffMenu.createPound.Button("Fourrière #" .. i, ("Position: x: %.2f, y: %.2f, z: %.2f"):format(data.position.x, data.position.y, data.position.z), nil, "trash", false, function()
            poundSelected = data
            if not poundSelected.spawnPositions then
                poundSelected.spawnPositions = {}
            end
            iCurrentCategory = 1
        end, StaffMenu.modifyPound)
    end
end

local function fcBuildPoundMenu(Menu)
    Menu.List('Catégorie', nil, false, { "Informations Générales", "Emplacements des véhicules" }, iCurrentCategory, function(Index)
        iCurrentCategory = Index
        fcRefresh(Menu)
    end)

    if iCurrentCategory == 1 then
        Menu.Separator("INFORMATIONS GENERALES")

        Menu.Button("Label de la fourrière", "Exemple: Fourrière centrale", poundSelected.label or "Non défini", fcGetIcon(poundSelected.label), false, function()
            local label <const> = VFW.Nui.KeyboardInput(true, "Entrez le label de la fourrière", "")
            if label == "" then
                return
            end

            poundSelected.label = label
            fcRefresh(Menu)
        end)

        Menu.Button("Position de la fourrière", "", poundSelected.position.x and "Définie" or "Non définie", fcGetIcon(poundSelected.position.x), false, function()
            local ped <const> = PlayerPedId()
            local pos <const> = GetEntityCoords(ped)

            poundSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
            fcRefresh(Menu)
        end)

        Menu.Button("Type d'interaction", "PNJ ou Marqueur au sol", poundSelected.useMarker and "Marqueur" or "PNJ", "chevron", false, function()
            poundSelected.useMarker = not poundSelected.useMarker
            fcRefresh(Menu)
        end)

        Menu.List("Zone de la fourrière", "LS = visible toutes police, CAYO = milice Cayo uniquement", false, POUND_ZONE_OPTIONS, poundZoneToIndex(poundSelected.zone), function(Index)
            poundSelected.zone = poundZoneFromIndex(Index)
            fcRefresh(Menu)
        end)

        if not poundSelected.useMarker then
            Menu.Button("Modèle du PNJ", "Nom du ped model", poundSelected.pedModel or "a_m_y_business_02", fcGetIcon(poundSelected.pedModel), false, function()
                local model <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du modèle (ex: a_m_y_business_02)")
                if model == "" then
                    return
                end

                if not IsModelInCdimage(GetHashKey(model)) then
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Fourrière',
                        message = "Ce modèle n'existe pas."
                  })
                    return
                end

                poundSelected.pedModel = model
                fcRefresh(Menu)
            end)
        end

        Menu.Button(":money: Prix de sortie", "Prix pour récupérer un véhicule", VFW.Math.FormatMoney(poundSelected.price or 500), fcGetIcon(poundSelected.price), false, function()
            local input <const> = VFW.Nui.KeyboardInput(true, "Entrez le prix de sortie (" .. LOCALE.currencySymbol .. ")", tostring(poundSelected.price or 500))
            if input == "" then return end

            local price = tonumber(input)
            if not price or price < 0 then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Fourrière',
                    message = "Veuillez entrer un prix valide."
              })
                return
            end

            poundSelected.price = math.floor(price)
            fcRefresh(Menu)
        end)

    elseif iCurrentCategory == 2 then
        Menu.Separator("EMPLACEMENTS DES VEHICULES (" .. #poundSelected.spawnPositions .. ")")

        for i = 1, #poundSelected.spawnPositions do
            Menu.Button("Spawn " .. i, DoesEntityExist(eCurrentVehicle[i]) and "Définie" or "Non définie", nil, fcGetIcon(eCurrentVehicle[i]), false, function()
                local ped <const> = PlayerPedId()
                local pos <const> = GetEntityCoords(ped)

                poundSelected.spawnPositions[i] = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
                fcSpawnPreview("sultan", poundSelected.spawnPositions[i], i)
                fcRefresh(Menu)
            end)

            Menu.Button("Orientation Spawn " .. i, tostring(poundSelected.spawnPositions[i] and poundSelected.spawnPositions[i].w or 0) .. "°", nil, fcGetIcon(DoesEntityExist(eCurrentVehicle[i])), false, function()
                if not poundSelected.spawnPositions[i] or not DoesEntityExist(eCurrentVehicle[i]) then return end

                local sInput = VFW.Nui.KeyboardInput(true, "Entrer l'orientation du véhicule (0-360)")
                if sInput == "" or not tonumber(sInput) then return end

                poundSelected.spawnPositions[i].w = math.max(0, math.min(360, tonumber(sInput)))
                SetEntityHeading(eCurrentVehicle[i], poundSelected.spawnPositions[i].w + 0.0)

                fcRefresh(Menu)
            end)

            Menu.Button("Supprimer Spawn " .. i, "", nil, "trash", false, function()
                fcDeletePreview(i)
                table.remove(poundSelected.spawnPositions, i)

                local newVehicles = {}
                for j, v in pairs(eCurrentVehicle) do
                    if j > i then
                        newVehicles[j - 1] = v
                    elseif j < i then
                        newVehicles[j] = v
                    end
                end
                eCurrentVehicle = newVehicles

                fcRefresh(Menu)
            end)
        end

        Menu.Separator("")

        Menu.Button("Ajouter un point de spawn", "Se placer à l'emplacement voulu", nil, "arrow", false, function()
            local ped <const> = PlayerPedId()
            local pos <const> = GetEntityCoords(ped)
            local idx = #poundSelected.spawnPositions + 1

            poundSelected.spawnPositions[idx] = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
            fcSpawnPreview("sultan", poundSelected.spawnPositions[idx], idx)
            fcRefresh(Menu)
        end)
    end
end

StaffMenu.createPoundData.OnOpen(function()
    fcBuildPoundMenu(StaffMenu.createPoundData)

    StaffMenu.createPoundData.Separator("ACTIONS")

    local sStatusMessage = ""
  if not poundSelected.label then
        sStatusMessage = "Label manquant"
  elseif not poundSelected.position.x then
        sStatusMessage = "Position manquante"
  elseif #poundSelected.spawnPositions == 0 then
        sStatusMessage = "Aucun point de spawn"
  else
        sStatusMessage = "Prêt à créer (" .. #poundSelected.spawnPositions .. (#poundSelected.spawnPositions > 1 and " spawns)" or " spawn)")
  end

    local bIsValid = poundSelected.label and poundSelected.position.x and #poundSelected.spawnPositions > 0
    local sIcon = bIsValid and "check" or "lock"

  StaffMenu.createPoundData.Button("Créer la fourrière", sStatusMessage, nil, sIcon, not bIsValid, function()
        if not bIsValid then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Fourrière',
                message = "Veuillez définir tous les paramètres avant de créer la fourrière."
          })
            return
        end

        TriggerServerCallback("core:createPound", poundSelected)
        fcCloseMenu()
        poundSelected = getPoundDefaultData()
        iCurrentCategory = 1
        if VUI_MenuStack then table.remove(VUI_MenuStack) end
        StaffMenu.createPoundData.close()
        StaffMenu.createPound.open()
    end)
end)

StaffMenu.createPoundData.OnClose(function()
    if bIsOpen then return end
    fcCloseMenu()
    poundSelected = getPoundDefaultData()
    iCurrentCategory = 1
end)

StaffMenu.modifyPound.OnOpen(function()
    local iDist = #(GetEntityCoords(PlayerPedId()) - vec3(poundSelected.position.x, poundSelected.position.y, poundSelected.position.z))
    if iDist > 200 then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Fourrière',
            message = "Vous êtes trop loin de la fourrière pour voir l'aperçu. (Réouvrez le menu une fois sur place)"
      })
    else
        for i = 1, #poundSelected.spawnPositions do
            if poundSelected.spawnPositions[i] then
                fcSpawnPreview("sultan", poundSelected.spawnPositions[i], i)
            end
        end
    end

    StaffMenu.modifyPound.Button("Se téléporter au point", "", nil, "chevron", false, function()
        if not poundSelected.position then return end
        SetEntityCoordsNoOffset(PlayerPedId(), poundSelected.position.x, poundSelected.position.y, poundSelected.position.z, false, false, true)
    end)

    StaffMenu.modifyPound.Separator("")

    fcBuildPoundMenu(StaffMenu.modifyPound)

    StaffMenu.modifyPound.Separator("ACTIONS")

    StaffMenu.modifyPound.Button("Modifier la fourrière", "", nil, "chevron", false, function()
        if not poundSelected.position.x or #poundSelected.spawnPositions == 0 then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Fourrière',
                message = "Veuillez définir toutes les positions avant de modifier la fourrière."
          })
            return
        end

        TriggerServerCallback("core:updatePound", poundSelected.id, poundSelected)
        fcCloseMenu()
        poundSelected = getPoundDefaultData()
        iCurrentCategory = 1
        if VUI_MenuStack then table.remove(VUI_MenuStack) end
        StaffMenu.modifyPound.close()
        StaffMenu.createPound.open()
    end)

    StaffMenu.modifyPound.Button("Supprimer la fourrière", "", nil, "trash", false, function()
        TriggerServerCallback("core:deletePound", poundSelected.id)
        fcCloseMenu()
        poundSelected = getPoundDefaultData()
        iCurrentCategory = 1
        if VUI_MenuStack then table.remove(VUI_MenuStack) end
        StaffMenu.modifyPound.close()
        StaffMenu.createPound.open()
    end)
end)

StaffMenu.modifyPound.OnClose(function()
    if bIsOpen then return end
    fcCloseMenu()
    poundSelected = getPoundDefaultData()
    iCurrentCategory = 1
end)
