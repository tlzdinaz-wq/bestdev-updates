local VUI = exports["VUI"]

StaffMenu.CreateBlip = VUI:CreateSubMenu(StaffMenu.builderBlips, "CRÉER UN BLIP", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.ManageBlips = VUI:CreateSubMenu(StaffMenu.builderBlips, "GÉRER LES BLIPS", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.EditBlip = VUI:CreateSubMenu(StaffMenu.ManageBlips, "MODIFIER LE BLIP", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.BlipSelectJobs = VUI:CreateSubMenu(StaffMenu.CreateBlip, "SÉLECTION DES JOBS", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.BlipSelectFactions = VUI:CreateSubMenu(StaffMenu.CreateBlip, "SÉLECTION DES FACTIONS", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.BlipEditSelectJobs = VUI:CreateSubMenu(StaffMenu.EditBlip, "SÉLECTION DES JOBS", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.BlipEditSelectFactions = VUI:CreateSubMenu(StaffMenu.EditBlip, "SÉLECTION DES FACTIONS", exports["core"]:GetVUIBanner("admin"), true)

local wlTypes <const> = {"global", "job", "faction"}
local cachedBlipJobs = nil
local cachedBlipFactions = nil

function getBlipDefaultData()
    return {
        label = nil,
        sprite = nil,
        color = nil,
        scale = nil,
        position = nil,
        whitelistType = 1,
        whitelistValues = {},
    }
end

local selectedBlip = getBlipDefaultData()

local function refreshMenu(menu)
    if menu and menu.softRefresh then
        menu.softRefresh()
        return
    end
    if menu and menu.refresh then
        menu.refresh()
    end
end

local function askText(title, current)
    local value = current == nil and "" or tostring(current)
    if StaffMenu.HubTextInput then
        return StaffMenu.HubTextInput(title, value)
    end
    return VFW.Nui.KeyboardInput(true, title, value)
end

local function capturePosition()
    local coords = GetEntityCoords(PlayerPedId())
    selectedBlip.position = { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
end

local function positionLabel()
    local pos = selectedBlip.position
    if not pos then return "Non définie" end
    return ("%.1f, %.1f, %.1f"):format(pos.x, pos.y, pos.z)
end

local function isValueInList(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

local function toggleValueInList(list, value)
    for i, v in ipairs(list) do
        if v == value then
            table.remove(list, i)
            return list
        end
    end
    list[#list + 1] = value
    return list
end

local function getWlTypeIndex(typeName)
    for i, t in ipairs(wlTypes) do
        if t == typeName then return i end
    end
    return 1
end

local function getWlLabel(blip)
    local wlType = blip.whitelistType
    if type(wlType) == "number" then
        wlType = wlTypes[wlType] or "global"
  end
    if wlType == "global" then return "Global" end
    local values = blip.whitelistValues or {}
    local count = #values
    if count == 0 then return wlType:upper() .. " (aucun)" end
    return wlType:upper() .. " (" .. count .. ")"
end

function StaffMenu.BuildBlipsMenu()
    StaffMenu.builderBlips.Button(":plus: CRÉER UN BLIP", "Ajouter un nouveau blip sur la carte", nil, "chevron", false, function()
        selectedBlip = getBlipDefaultData()
    end, StaffMenu.CreateBlip)

    StaffMenu.builderBlips.Button(":settings: GÉRER LES BLIPS", "Modifier ou supprimer des blips existants", nil, "chevron", false, function()
    end, StaffMenu.ManageBlips)
end

local function buildBlipWlSection(menu, jobsSubmenu, factionsSubmenu)
    local wlTypeIndex = selectedBlip.whitelistType
    if type(wlTypeIndex) == "string" then
        wlTypeIndex = getWlTypeIndex(wlTypeIndex)
        selectedBlip.whitelistType = wlTypeIndex
    end

    menu.List('Type de restriction', nil, false, wlTypes, wlTypeIndex, function(Index)
        selectedBlip.whitelistType = Index
        if Index == 1 then
            selectedBlip.whitelistValues = {}
        end
        refreshMenu(menu)
    end)

    if wlTypeIndex == 2 then
        local count = #selectedBlip.whitelistValues
        menu.Button("Jobs autorisés", count > 0 and (count .. " sélectionné" .. (count > 1 and "s" or "")) or "Aucun", nil, "chevron", false, function()
            if not cachedBlipJobs then
                cachedBlipJobs = TriggerServerCallback("core:blips:getAllJobs") or {}
            end
        end, jobsSubmenu)
    elseif wlTypeIndex == 3 then
        local count = #selectedBlip.whitelistValues
        menu.Button("Factions autorisées", count > 0 and (count .. " sélectionnée" .. (count > 1 and "s" or "")) or "Aucune", nil, "chevron", false, function()
            if not cachedBlipFactions then
                cachedBlipFactions = TriggerServerCallback("core:blips:getAllFactions") or {}
            end
        end, factionsSubmenu)
    end
end

local function buildBlipFieldsSection(menu)
    menu.Button("Nom du blip", "", selectedBlip.label or "Non défini", "chevron", false, function()
        local value = askText("Nom du blip", selectedBlip.label or "")
        if value == "" then
            return
        end

        selectedBlip.label = value
        refreshMenu(menu)
    end)

    menu.Button("Sprite du blip", "", selectedBlip.sprite or "Non défini", "chevron", false, function()
        local sprite = tonumber(askText("Sprite du blip", selectedBlip.sprite or ""))
        if not sprite then
            return
        end

        selectedBlip.sprite = sprite
        refreshMenu(menu)
    end)

    menu.Button("Couleur du blip", "", selectedBlip.color or "Non défini", "chevron", false, function()
        local color = tonumber(askText("Couleur du blip", selectedBlip.color or ""))
        if not color then
            return
        end

        selectedBlip.color = color
        refreshMenu(menu)
    end)

    menu.Button("Taille du blip", "", selectedBlip.scale or "Non défini", "chevron", false, function()
        local scale = tonumber(askText("Taille du blip (0.1 - 1.0)", selectedBlip.scale or ""))
        if not scale then
            return
        end

        scale = scale + 0.0

        if scale < 0.1 or scale > 1.0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Blips',
                message = "La taille doit être comprise entre 0.1 et 1.0."
          })
        end

        selectedBlip.scale = scale
        refreshMenu(menu)
    end)

    menu.Button("Position du blip", "Clique pour prendre l'endroit où tu es", positionLabel(), "pin", false, function()
        capturePosition()
        VFW.ShowNotification({
            type = "STAFF",
            variant = "SUCCESS",
            subtitle = "Blips",
            message = "Position prise : " .. positionLabel(),
        })
        refreshMenu(menu)
    end)
end

local function buildJobSelectMenu(menu)
    menu.Separator("SÉLECTION DES JOBS")

    if not cachedBlipJobs or #cachedBlipJobs == 0 then
        menu.Button("Aucun job trouvé", nil, nil, "empty", true, function() end)
        return
    end

    for _, job in ipairs(cachedBlipJobs) do
        local selected = isValueInList(selectedBlip.whitelistValues, job.name)
        menu.Button(
            job.label,
            job.name,
            nil,
            selected and "check" or "empty",
            false,
            function()
                toggleValueInList(selectedBlip.whitelistValues, job.name)
                refreshMenu(menu)
            end
        )
    end
end

local function buildFactionSelectMenu(menu)
    menu.Separator("SÉLECTION DES FACTIONS")

    if not cachedBlipFactions or #cachedBlipFactions == 0 then
        menu.Button("Aucune faction trouvée", nil, nil, "empty", true, function() end)
        return
    end

    for _, faction in ipairs(cachedBlipFactions) do
        local selected = isValueInList(selectedBlip.whitelistValues, faction.name)
        menu.Button(
            faction.label,
            faction.name,
            nil,
            selected and "check" or "empty",
            false,
            function()
                toggleValueInList(selectedBlip.whitelistValues, faction.name)
                refreshMenu(menu)
            end
        )
    end
end

StaffMenu.CreateBlip.OnOpen(function()
    if not selectedBlip.position then
        capturePosition()
    end
    StaffMenu.CreateBlip.ClearItems()

    buildBlipWlSection(StaffMenu.CreateBlip, StaffMenu.BlipSelectJobs, StaffMenu.BlipSelectFactions)
    buildBlipFieldsSection(StaffMenu.CreateBlip)

    StaffMenu.CreateBlip.Button(":check: Créer le blip", "", nil, "check", false, function()
        if not selectedBlip.label or not selectedBlip.sprite or not selectedBlip.color or not selectedBlip.scale or not selectedBlip.position then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Blips',
                message = "Vous devez définir tous les paramètres du blip avant de le créer."
          })
        end

        local wlType = wlTypes[selectedBlip.whitelistType] or "global"

      if wlType ~= "global" and #selectedBlip.whitelistValues == 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Blips',
                message = "Vous devez sélectionner au moins un " .. (wlType == "job" and "job" or "faction") .. "."
          })
        end

        local res = TriggerServerCallback("core:createBlip", {
            label = selectedBlip.label,
            sprite = selectedBlip.sprite,
            color = selectedBlip.color,
            scale = selectedBlip.scale,
            position = selectedBlip.position,
            whitelistType = wlType,
            whitelistValues = selectedBlip.whitelistValues,
        })
        if type(res) ~= "table" or res.ok ~= true or not res.blip then
            return VFW.ShowNotification({
                type = "STAFF",
                variant = "ERROR",
                subtitle = "Blips",
                message = (type(res) == "table" and res.error) or "Le blip n'a pas été enregistré.",
            })
        end
        TriggerEvent("blips:add:list", tostring(res.id), res.blip)
        VFW.ShowNotification({
            type = "STAFF",
            variant = "SUCCESS",
            subtitle = "Blips",
            message = "Blip #" .. tostring(res.id) .. " enregistré et affiché sur la carte.",
        })
        StaffMenu.builderBlips.close()
    end)
end)

StaffMenu.BlipSelectJobs.OnOpen(function()
    StaffMenu.BlipSelectJobs.ClearItems()
    if not cachedBlipJobs then
        cachedBlipJobs = TriggerServerCallback("core:blips:getAllJobs") or {}
    end
    buildJobSelectMenu(StaffMenu.BlipSelectJobs)
end)

StaffMenu.BlipSelectFactions.OnOpen(function()
    StaffMenu.BlipSelectFactions.ClearItems()
    if not cachedBlipFactions then
        cachedBlipFactions = TriggerServerCallback("core:blips:getAllFactions") or {}
    end
    buildFactionSelectMenu(StaffMenu.BlipSelectFactions)
end)

local function rebuildManageBlipsList()
    StaffMenu.ManageBlips.ClearItems()

    local blips = TriggerServerCallback("core:getAllBlips") or {}
    local count = 0

    for _, blip in pairs(blips) do
        if type(blip) == "table" and blip.label then
        count = count + 1
        local wlLabel = getWlLabel(blip)
        local stateLabel = (blip.active and "Actif" or "Inactif") .. " | " .. wlLabel
        StaffMenu.ManageBlips.Button(blip.label, stateLabel, nil, "chevron", false, function()
            selectedBlip = {
                id = blip.id,
                label = blip.label,
                sprite = blip.sprite,
                color = blip.color,
                scale = blip.scale,
                position = blip.position,
                whitelistType = getWlTypeIndex(blip.whitelistType),
                whitelistValues = blip.whitelistValues or {},
                active = blip.active ~= false and blip.active ~= 0,
            }
        end, StaffMenu.EditBlip)
        end
    end

    if count == 0 then
        StaffMenu.ManageBlips.Button("Aucun blip enregistré", "Crée-en un depuis Créer un blip", nil, "empty", true, function() end)
    end
end

StaffMenu.ManageBlips.OnOpen(function()
    rebuildManageBlipsList()
end)

StaffMenu.EditBlip.OnOpen(function()
    StaffMenu.EditBlip.ClearItems()

    local isActive = selectedBlip.active ~= false
    StaffMenu.EditBlip.Button(
        isActive and "Actif" or "Inactif",
        "Activer ou désactiver ce blip pour tous les joueurs",
        nil,
        isActive and "check" or "empty",
        false,
        function()
            selectedBlip.active = not selectedBlip.active
            TriggerServerEvent("core:toggleBlip", selectedBlip.id, selectedBlip.active)
            refreshMenu(StaffMenu.EditBlip)
        end
    )

    buildBlipWlSection(StaffMenu.EditBlip, StaffMenu.BlipEditSelectJobs, StaffMenu.BlipEditSelectFactions)
    buildBlipFieldsSection(StaffMenu.EditBlip)

    StaffMenu.EditBlip.Button(":save: Enregistrer les modifications", "", nil, "check", false, function()
        if not selectedBlip.label or not selectedBlip.sprite or not selectedBlip.color or not selectedBlip.scale or not selectedBlip.position then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Blips',
                message = "Vous devez définir tous les paramètres du blip avant de le modifier."
          })
        end

        local wlType = wlTypes[selectedBlip.whitelistType] or "global"

      if wlType ~= "global" and #selectedBlip.whitelistValues == 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Blips',
                message = "Vous devez sélectionner au moins un " .. (wlType == "job" and "job" or "faction") .. "."
          })
        end

        TriggerServerEvent("core:updateBlip", selectedBlip.id, {
            label = selectedBlip.label,
            sprite = selectedBlip.sprite,
            color = selectedBlip.color,
            scale = selectedBlip.scale,
            position = selectedBlip.position,
            whitelistType = wlType,
            whitelistValues = selectedBlip.whitelistValues,
        })
        StaffMenu.ManageBlips.close()
    end)

    StaffMenu.EditBlip.Button(":trash: Supprimer le blip", "", nil, "trash", false, function()
        TriggerServerEvent("core:deleteBlip", selectedBlip.id)
        StaffMenu.EditBlip.close()
        rebuildManageBlipsList()
        refreshMenu(StaffMenu.ManageBlips)
    end)
end)

StaffMenu.BlipEditSelectJobs.OnOpen(function()
    StaffMenu.BlipEditSelectJobs.ClearItems()
    if not cachedBlipJobs then
        cachedBlipJobs = TriggerServerCallback("core:blips:getAllJobs") or {}
    end
    buildJobSelectMenu(StaffMenu.BlipEditSelectJobs)
end)

StaffMenu.BlipEditSelectFactions.OnOpen(function()
    StaffMenu.BlipEditSelectFactions.ClearItems()
    if not cachedBlipFactions then
        cachedBlipFactions = TriggerServerCallback("core:blips:getAllFactions") or {}
    end
    buildFactionSelectMenu(StaffMenu.BlipEditSelectFactions)
end)
