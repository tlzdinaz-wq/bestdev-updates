local doorlockData = {
    label = nil,
    maxInteractDistance = nil,
    coords = nil,
    doorsData = nil,
    access = nil,
    pincode = nil
}

local function checkAlreadyExistsJob(name)
    if not doorlockData.access then
        return
    end

    for i = 1, #doorlockData.access do
        local job <const> = doorlockData.access[i]

        if job.name == name then
            return true
        end
    end
end

function checkValidDoorlockData()
    if not doorlockData.label or not doorlockData.maxInteractDistance or not doorlockData.coords or not doorlockData.doorsData then
        return false
    end

    if not next(doorlockData.doorsData) then
        return false
    end

    return true
end

function StaffMenu.BuildCreateDoorlockMenu()
    if not doorlockData.access or not next(doorlockData.access) then
        doorlockData.access = nil
    end
    
    StaffMenu.CreateDoorlock.Button("LABEL DU DOORLOCK", "Définir le nom du doorlock affiché dans l'interface", doorlockData.label, "chevron", false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrer le label du doorlock")

        if not label or label == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Portes',
                message = "Ce label n'est pas valide."
          })
        end

        doorlockData.label = label
        StaffMenu.CreateDoorlock.refresh()
    end)

    StaffMenu.CreateDoorlock.Button("DISTANCE D'INTERACTION", "Distance en mètres à partir de laquelle le joueur peut interagir avec la porte", doorlockData.maxInteractDistance, "chevron", false, function()
        local maxInteractDistance <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer la distance d'interaction (en mètres)"))

        if not maxInteractDistance or maxInteractDistance <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Portes',
                message = "Cette distance n'est pas valide."
          })
        end

        doorlockData.maxInteractDistance = maxInteractDistance
        StaffMenu.CreateDoorlock.refresh()
    end)

    if not doorlockData.isUpdate then
        StaffMenu.CreateDoorlock.Button("DÉFINIR LES PORTES", "Sélectionner les portes à inclure dans ce doorlock", nil, doorlockData.coords and "check" or "chevron", false, function()
            StaffMenu.CreateDoorlock.close()

            local selectedDoors <const>, midCoords <const> = Doorlock:SelectDoorlock(doorlockData.doorsData)
            local newCoords <const> = midCoords and midCoords or selectedDoors[1].coords

            doorlockData.coords = newCoords
            doorlockData.doorsData = selectedDoors

            StaffMenu.CreateDoorlock.refresh()
        end)
    end

    StaffMenu.CreateDoorlock.Separator("GESTION DES ACCÈS")

    StaffMenu.CreateDoorlock.Button("AJOUTER UN PINCODE", "Définir un code PIN à 4 chiffres pour accéder à cette porte", doorlockData.pincode, doorlockData.pincode and "check" or "chevron", false, function()
        local pincode <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le pincode (4 chiffres)"))

        if not pincode then
            doorlockData.pincode = nil
            StaffMenu.CreateDoorlock.refresh()
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Portes',
                message = "Ce code PIN n'est pas valide : il doit compter 4 chiffres."
          })
        end

        doorlockData.pincode = pincode
        StaffMenu.CreateDoorlock.refresh()
    end)

    StaffMenu.CreateDoorlock.Button("AJOUTER / GÉRER LES ACCÈS", "Gérer les jobs et factions autorisés à déverrouiller cette porte", doorlockData.access and #doorlockData.access .. " accès" or "Aucun accès", "chevron", false, function()
    end, StaffMenu.DoorlockManageAccess)

    StaffMenu.CreateDoorlock.Separator()

    StaffMenu.CreateDoorlock.Button(":check: CRÉER / MODIFIER LE DOORLOCK", nil, nil, "chevron", false, function()
        local isValid <const> = checkValidDoorlockData()

        if not isValid then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Portes',
                message = "Ces données ne sont pas valides, veuillez vérifier que vous avez bien rempli tous les champs."
          })
        end

        if doorlockData.isUpdate then
            TriggerServerEvent("doorlock:server:update", doorlockData.id, doorlockData.label, doorlockData.maxInteractDistance, doorlockData.coords, doorlockData.doorsData, doorlockData.access, doorlockData.pincode)
        else
            TriggerServerEvent("doorlock:server:create", doorlockData.label, doorlockData.maxInteractDistance, doorlockData.coords, doorlockData.doorsData, doorlockData.access, doorlockData.pincode)
        end

        doorlockData = {}
        StaffMenu.CreateDoorlock.close()
    end)


    StaffMenu.CreateDoorlock.Button(":x: Annuler", nil, nil, "chevron", false, function()
        doorlockData = {}
        StaffMenu.CreateDoorlock.close()
    end)
end

function StaffMenu.BuildDoorlockManageAccess()
    StaffMenu.DoorlockManageAccess.Button("AJOUTER UN JOB / FACTION", "Accorder l'accès à ce doorlock à un job ou une faction avec un grade minimum", nil, "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom du job / faction")

        if not name or name == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Portes',
                message = "Ce nom n'est pas valide."
          })
        end

        local grade <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le grade minimum (0 si tous les grades)"))

        if not grade or grade < 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Portes',
                message = "Ce grade n'est pas valide."
          })
        end

        if not doorlockData.access then
            doorlockData.access = {}
        end

        doorlockData.access[#doorlockData.access + 1] = {
            name = name,
            grade = grade
        }

        StaffMenu.DoorlockManageAccess.refresh()
    end)

    StaffMenu.DoorlockManageAccess.Separator("JOB ET FACTION AYANT ACCÈS AU DOORLOCK")

    if not doorlockData.access or not next(doorlockData.access) then
        StaffMenu.DoorlockManageAccess.Button(":x: AUCUN ACCÈS ATTRIBUTÉ", nil, nil, "chevron", false, function()end)
        goto skip
    end

    for i = 1, #doorlockData.access do
        local access <const> = doorlockData.access[i]

        StaffMenu.DoorlockManageAccess.Button(access.name .. " (Grade min: " .. access.grade .. ")", nil, nil, "chevron", false, function()
            table.remove(doorlockData.access, i)
            StaffMenu.DoorlockManageAccess.refresh()
        end)
    end

    ::skip::
end

local currentDoorlock = nil
local DOORLOCKS_PER_PAGE = 25
StaffMenu.doorlockListPage = StaffMenu.doorlockListPage or 1
StaffMenu.doorlockListSearch = StaffMenu.doorlockListSearch or nil

function StaffMenu.BuildDoorlockListMenu()
    local searchLabel = StaffMenu.doorlockListSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.doorlockListSearch == nil and "Label / ID / job d'accès" or StaffMenu.doorlockListSearch
    StaffMenu.DoorlockList.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.doorlockListSearch ~= nil then
            StaffMenu.doorlockListSearch = nil
            StaffMenu.doorlockListPage = 1
            StaffMenu.DoorlockList.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : label / ID / job d'accès")
        if query == nil or query == "" then return end
        StaffMenu.doorlockListSearch = query
        StaffMenu.doorlockListPage = 1
        StaffMenu.DoorlockList.refresh()
    end)

    if #Doorlock.cache == 0 then
        StaffMenu.DoorlockList.Separator(nil)
        StaffMenu.DoorlockList.Button(":x: AUCUN DOORLOCK", nil, nil, nil, false, function()end)
        return
    end

    local flat = {}
    for i = 1, #Doorlock.cache do flat[#flat + 1] = Doorlock.cache[i] end
    table.sort(flat, function(a, b) return (a.label or ""):lower() < (b.label or ""):lower() end)

    local filtered = flat
    if StaffMenu.doorlockListSearch and StaffMenu.doorlockListSearch ~= "" then
        local q = StaffMenu.doorlockListSearch:lower()
        filtered = {}
        for _, d in ipairs(flat) do
            local match = (d.label or ""):lower():find(q, 1, true)
                or tostring(d.id or ""):lower():find(q, 1, true)
            if not match and d.access then
                for _, a in ipairs(d.access) do
                    if (a.name or ""):lower():find(q, 1, true) then
                        match = true
                        break
                    end
                end
            end
            if match then table.insert(filtered, d) end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / DOORLOCKS_PER_PAGE), 1)
    if StaffMenu.doorlockListPage > totalPages then StaffMenu.doorlockListPage = totalPages end
    if StaffMenu.doorlockListPage < 1 then StaffMenu.doorlockListPage = 1 end
    local startIdx = (StaffMenu.doorlockListPage - 1) * DOORLOCKS_PER_PAGE + 1
    local endIdx = math.min(startIdx + DOORLOCKS_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.doorlockListSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d doorlocks, page %d sur %d", totalItems, StaffMenu.doorlockListPage, totalPages)
    end
    StaffMenu.DoorlockList.Separator(header)

    if totalItems == 0 then
        StaffMenu.DoorlockList.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function()end)
        return
    end

    for idx = startIdx, endIdx do
        local doorlock = filtered[idx]
        local doorLabel = ("%s #%s"):format(doorlock.label, doorlock.id)
        local accessSub = doorlock.access and (#doorlock.access .. " accès") or "Public"
      StaffMenu.DoorlockList.Button(doorLabel, accessSub, nil, "chevron", false, function()
            currentDoorlock = doorlock
        end, StaffMenu.DoorlockManage)
    end

    if totalPages > 1 then
        StaffMenu.DoorlockList.Separator(nil)
        if StaffMenu.doorlockListPage > 1 then
            StaffMenu.DoorlockList.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.doorlockListPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.doorlockListPage = StaffMenu.doorlockListPage - 1
                StaffMenu.DoorlockList.refresh()
            end)
        end
        if StaffMenu.doorlockListPage < totalPages then
            StaffMenu.DoorlockList.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.doorlockListPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.doorlockListPage = StaffMenu.doorlockListPage + 1
                StaffMenu.DoorlockList.refresh()
            end)
        end
    end
end

function StaffMenu.BuildManageDoorlockMenu()
    StaffMenu.DoorlockManage.Button(":target:​ TELEPORTATION A LA POSITION", nil, nil, "chevron", false, function()
        if not currentDoorlock.coords then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Portes',
                message = "Aucune position définie."
          })
        end

        SetEntityCoords(PlayerPedId(), currentDoorlock.coords.x, currentDoorlock.coords.y, currentDoorlock.coords.z + 1.0, false, false, false, false)
    end)

    StaffMenu.DoorlockManage.Button(":monitor:​​ MODIFIER LE DOORLOCK", nil, nil, "chevron", false, function()
        doorlockData = currentDoorlock
        doorlockData.isUpdate = true
    end, StaffMenu.CreateDoorlock)

    StaffMenu.DoorlockManage.Button(":trash: SUPPRIMER LE DOORLOCK", nil, nil, "chevron", false, function()
        TriggerServerEvent("doorlock:server:delete", currentDoorlock.id)
        StaffMenu.DoorlockManage.close()
    end)
end