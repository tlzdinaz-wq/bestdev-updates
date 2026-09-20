-- Builder Concessionnaire
local VUI <const> = exports["VUI"]

local adminBanner <const> = GetVUIBanner("admin")

-- Création des sous-menus
StaffMenu.builderConcess = VUI:CreateSubMenu(StaffMenu.builders, "GESTION CONCESSIONNAIRE", adminBanner, true)

local ConcessCreate = VUI:CreateSubMenu(StaffMenu.builderConcess, "CRÉER UN CONCESSIONNAIRE", adminBanner, true)
local ConcessManage = VUI:CreateSubMenu(StaffMenu.builderConcess, "GÉRER LES CONCESSIONNAIRES", adminBanner, true)
local ConcessEdit = VUI:CreateSubMenu(ConcessManage, "MODIFIER CONCESSIONNAIRE", adminBanner, true)

local ConcessVehicles = VUI:CreateSubMenu(StaffMenu.builderConcess, "GÉRER LES VÉHICULES", adminBanner, true)
local ConcessCategories = VUI:CreateSubMenu(ConcessVehicles, "CATÉGORIES", adminBanner, true)
local ConcessCategoryCreate = VUI:CreateSubMenu(ConcessCategories, "CRÉER CATÉGORIE", adminBanner, true)
local ConcessVehiclesByCategory = VUI:CreateSubMenu(ConcessVehicles, "VÉHICULES PAR CATÉGORIE", adminBanner, true)
local ConcessVehicleEditor = VUI:CreateSubMenu(ConcessVehiclesByCategory, "MODIFIER VÉHICULE", adminBanner, true)
local ConcessVehicleAdd = VUI:CreateSubMenu(ConcessVehicles, "AJOUTER VÉHICULE", adminBanner, true)

-- Variables locales
local concessTypes <const> = { "voiture", "bateau", "avion" }
local tSelectedConcess = nil
local tSelectedCategory = nil
local tSelectedVehicle = nil
local tNewCategory = ""

local tNewConcess = {
    name = "",
    job = "",
    concessType = 1,
    automatic = false,
    pedModel = "a_m_y_business_01",
    catalog = {},
    preview = {},
    spawn = {},
    showcase = {}
}

local tNewVehicle = {
    sModel = "",
    sName = "",
    sCategory = "",
    iPrice = 0
}

local function fcRefresh(Menu)
    if Menu and Menu.opened then
        Menu.refresh()
    end
end

local function fcGetIcon(condition)
    return condition and "check" or "chevron"
end

local function fcResetNewConcess()
    tNewConcess = {
        name = "",
        job = "",
        concessType = 1,
        automatic = false,
        pedModel = "a_m_y_business_01",
        catalog = {},
        preview = {},
        spawn = {},
        showcase = {}
    }
end

-- Menu principal
function StaffMenu.BuildConcessMenu()
    StaffMenu.builderConcess.Separator(":car: GESTION CONCESSIONNAIRE")

    StaffMenu.builderConcess.Button(":plus: CRÉER UN CONCESSIONNAIRE", "Créer un nouveau point de vente", nil, "chevron", false, function()
        fcResetNewConcess()
    end, ConcessCreate)

    StaffMenu.builderConcess.Button(":settings: GÉRER LES CONCESSIONNAIRES", "Modifier ou supprimer des concessionnaires", nil, "chevron", false, function()
    end, ConcessManage)

    StaffMenu.builderConcess.Separator(":box: CATALOGUE VÉHICULES")

    StaffMenu.builderConcess.Button(":car: GÉRER LES VÉHICULES", "Catégories et véhicules du catalogue", nil, "chevron", false, function()
    end, ConcessVehicles)
end

StaffMenu.builderConcess.OnOpen(function()
    StaffMenu.BuildConcessMenu()
end)

-- ==================== CRÉATION CONCESSIONNAIRE ====================

ConcessCreate.OnOpen(function()
    ConcessCreate.Separator(":edit: INFORMATIONS")

    ConcessCreate.Button(":tag: NOM", tNewConcess.name ~= "" and tNewConcess.name or "Non défini", nil, fcGetIcon(tNewConcess.name ~= ""), false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nom du concessionnaire", "")
        if sInput and sInput ~= "" then
            tNewConcess.name = sInput
            fcRefresh(ConcessCreate)
        end
    end)

    ConcessCreate.List(":car: TYPE VÉHICULES", nil, false, concessTypes, tNewConcess.concessType, function(index)
        tNewConcess.concessType = index
    end)

    ConcessCreate.Checkbox(":robot: MODE AUTO PERMANENT", "PED toujours présent (pas besoin d'employés)", false, tNewConcess.automatic, function(checked)
        tNewConcess.automatic = checked == true
        if tNewConcess.automatic then
            tNewConcess.job = ""
        end
        -- Pas de fcRefresh : le rebuild close/open annulait la coche dans le hub.
    end)

    -- Job toujours listé (ignoré à la création si mode auto) — évite un refresh à chaque coche
    do
        local societies = TriggerServerCallback("core:get:societies") or {}
        local jobNames = {}
        local jobIndex = 1
        local i = 1
        for jobName, jobData in pairs(societies) do
            jobNames[i] = jobName
            if jobName == tNewConcess.job then
                jobIndex = i
            end
            i = i + 1
        end

        if #jobNames > 0 then
            ConcessCreate.List(":briefcase: JOB ACCÈS", "Ignoré si mode auto activé", false, jobNames, jobIndex, function(index)
                if not tNewConcess.automatic then
                    tNewConcess.job = jobNames[index]
                end
            end)
        else
            ConcessCreate.Button(":briefcase: JOB ACCÈS", "Aucun job disponible", nil, "lock", true, function() end)
        end
    end

    -- Modèle PED (toujours visible car utilisé dans les deux modes)
    ConcessCreate.Button(":user: MODÈLE PED", tNewConcess.pedModel, nil, "chevron", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Modèle du PED", tNewConcess.pedModel)
        if sInput and sInput ~= "" then
            tNewConcess.pedModel = sInput
            fcRefresh(ConcessCreate)
        end
    end)

    ConcessCreate.Separator(":pin: POINTS CATALOGUE")

    ConcessCreate.Button(":plus: Ajouter point catalogue", #tNewConcess.catalog .. (#tNewConcess.catalog > 1 and " points" or " point"), nil, "chevron", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        tNewConcess.catalog[#tNewConcess.catalog + 1] = { x = pos.x, y = pos.y, z = pos.z - 0.99, h = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point catalogue ajouté." })
        fcRefresh(ConcessCreate)
    end)

    for i, point in ipairs(tNewConcess.catalog) do
        ConcessCreate.Button("Point #" .. i, ("%.2f, %.2f, %.2f, h: %.2f"):format(point.x, point.y, point.z, point.h or 0.0), nil, "trash", false, function()
            table.remove(tNewConcess.catalog, i)
            fcRefresh(ConcessCreate)
        end)
    end

    ConcessCreate.Separator(":eye: POINTS PREVIEW")

    ConcessCreate.Button(":plus: Ajouter point preview", #tNewConcess.preview .. (#tNewConcess.preview > 1 and " points" or " point"), nil, "chevron", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        tNewConcess.preview[#tNewConcess.preview + 1] = { x = pos.x, y = pos.y, z = pos.z - 0.99, h = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point preview ajouté." })
        fcRefresh(ConcessCreate)
    end)

    for i, point in ipairs(tNewConcess.preview) do
        ConcessCreate.Button("Point #" .. i, ("%.2f, %.2f, %.2f, h: %.2f"):format(point.x, point.y, point.z, point.h), nil, "trash", false, function()
            table.remove(tNewConcess.preview, i)
            fcRefresh(ConcessCreate)
        end)
    end

    ConcessCreate.Separator(":car: POINTS SPAWN")

    ConcessCreate.Button(":plus: Ajouter point spawn", #tNewConcess.spawn .. (#tNewConcess.spawn > 1 and " points" or " point"), nil, "chevron", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        tNewConcess.spawn[#tNewConcess.spawn + 1] = { x = pos.x, y = pos.y, z = pos.z, h = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point spawn ajouté." })
        fcRefresh(ConcessCreate)
    end)

    for i, point in ipairs(tNewConcess.spawn) do
        ConcessCreate.Button("Point #" .. i, ("%.2f, %.2f, %.2f, h: %.2f"):format(point.x, point.y, point.z, point.h), nil, "trash", false, function()
            table.remove(tNewConcess.spawn, i)
            fcRefresh(ConcessCreate)
        end)
    end

    ConcessCreate.Separator(":trophy: POINTS SHOWCASE")

    ConcessCreate.Button(":plus: Ajouter point showcase", #tNewConcess.showcase .. (#tNewConcess.showcase > 1 and " points" or " point"), nil, "chevron", false, function()
        local sModel = VFW.Nui.KeyboardInput(true, "Modèle du véhicule (ex: adder)", "")
        if sModel and sModel ~= "" then
            local pos = GetEntityCoords(PlayerPedId())
            local heading = GetEntityHeading(PlayerPedId())
            tNewConcess.showcase[#tNewConcess.showcase + 1] = {
                x = pos.x,
                y = pos.y,
                z = pos.z - 0.99,
                h = heading,
                model = sModel:lower()
            }
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point showcase ajouté avec le modèle : " .. sModel .. "." })
            fcRefresh(ConcessCreate)
        end
    end)

    for i, point in ipairs(tNewConcess.showcase) do
        ConcessCreate.Button("Point #" .. i .. " - " .. (point.model or "?"), ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tNewConcess.showcase, i)
            fcRefresh(ConcessCreate)
        end)
    end

    ConcessCreate.Separator(":wrench: ACTIONS")

    -- Job requis seulement si mode non-auto
    local bJobOk = tNewConcess.automatic or tNewConcess.job ~= ""
  local bCanCreate = tNewConcess.name ~= "" and bJobOk and #tNewConcess.catalog > 0
    local sStatus = bCanCreate and "Prêt à créer" or (tNewConcess.automatic and "Nom et 1 point catalogue requis" or "Nom, Job et 1 point catalogue requis")

    ConcessCreate.Button(":check: CRÉER LE CONCESSIONNAIRE", sStatus, nil, bCanCreate and "check" or "lock", not bCanCreate, function()
        if not bCanCreate then return end

        TriggerServerEvent("core:concess:create", tNewConcess)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Concessionnaire '" .. tNewConcess.name .. "' créé." })
        fcResetNewConcess()
        ConcessCreate.close()
        SetTimeout(300, function()
            StaffMenu.builderConcess.open()
        end)
    end)
end)

ConcessCreate.OnClose(function()
    -- Ne pas reset ici : Menu.refresh() ferme/rouvre en CreateThread et
    -- OnClose tournait APRÈS la saisie → name / type / points effacés.
    -- Reset uniquement à l'ouverture « CRÉER » et après création réussie.
end)

-- ==================== GESTION CONCESSIONNAIRES ====================

ConcessManage.OnOpen(function()
    local concessList = TriggerServerCallback("core:concess:getAll")

    ConcessManage.Separator(":report: CONCESSIONNAIRES")

    if not concessList or #concessList == 0 then
        ConcessManage.Button(":document: AUCUN CONCESSIONNAIRE", "Créez-en un d'abord", nil, nil, true, function() end)
    else
        for _, concess in ipairs(concessList) do
            ConcessManage.Button(":building: " .. concess.name, "Job: " .. concess.job .. " | Type: " .. concessTypes[concess.concessType or 1], nil, "chevron", false, function()
                tSelectedConcess = concess
            end, ConcessEdit)
        end
    end
end)

ConcessEdit.OnOpen(function()
    if not tSelectedConcess then return end

    ConcessEdit.Separator(":edit: " .. tSelectedConcess.name)

    ConcessEdit.Button(":tag: NOM", tSelectedConcess.name, nil, "chevron", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nouveau nom", tSelectedConcess.name)
        if sInput and sInput ~= "" then
            tSelectedConcess.name = sInput
            fcRefresh(ConcessEdit)
        end
    end)

    ConcessEdit.List(":car: TYPE VÉHICULES", nil, false, concessTypes, tSelectedConcess.concessType or 1, function(index)
        tSelectedConcess.concessType = index
    end)

    ConcessEdit.Checkbox(":robot: MODE AUTO PERMANENT", "PED toujours présent (pas besoin d'employés)", false, tSelectedConcess.automatic or false, function(checked)
        tSelectedConcess.automatic = checked == true
        if tSelectedConcess.automatic then
            tSelectedConcess.job = ""
        end
        -- Pas de fcRefresh : le rebuild close/open annulait la coche dans le hub.
    end)

    do
        local societies = TriggerServerCallback("core:get:societies") or {}
        local jobNames = {}
        local jobIndex = 1
        local i = 1
        for jobName, jobData in pairs(societies) do
            jobNames[i] = jobName
            if jobName == tSelectedConcess.job then
                jobIndex = i
            end
            i = i + 1
        end

        if #jobNames > 0 then
            ConcessEdit.List(":briefcase: JOB ACCÈS", "Ignoré si mode auto activé", false, jobNames, jobIndex, function(index)
                if not tSelectedConcess.automatic then
                    tSelectedConcess.job = jobNames[index]
                end
            end)
        end
    end

    -- Modèle PED (toujours visible car utilisé dans les deux modes)
    ConcessEdit.Button(":user: MODÈLE PED", tSelectedConcess.pedModel or "a_m_y_business_01", nil, "chevron", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Modèle du PED", tSelectedConcess.pedModel or "")
        if sInput and sInput ~= "" then
            tSelectedConcess.pedModel = sInput
            fcRefresh(ConcessEdit)
        end
    end)

    ConcessEdit.Separator(":pin: POINTS CATALOGUE (" .. #(tSelectedConcess.catalog or {}) .. ")")

    ConcessEdit.Button(":plus: Ajouter point catalogue", "", nil, "chevron", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        if not tSelectedConcess.catalog then tSelectedConcess.catalog = {} end
        tSelectedConcess.catalog[#tSelectedConcess.catalog + 1] = { x = pos.x, y = pos.y, z = pos.z - 0.99, h = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point catalogue ajouté." })
        fcRefresh(ConcessEdit)
    end)

    for i, point in ipairs(tSelectedConcess.catalog or {}) do
        ConcessEdit.Button("Point #" .. i, ("%.2f, %.2f, %.2f, h: %.2f"):format(point.x, point.y, point.z, point.h or 0.0), nil, "trash", false, function()
            table.remove(tSelectedConcess.catalog, i)
            fcRefresh(ConcessEdit)
        end)
    end

    ConcessEdit.Separator(":eye: POINTS PREVIEW (" .. #(tSelectedConcess.preview or {}) .. ")")

    ConcessEdit.Button(":plus: Ajouter point preview", "", nil, "chevron", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        if not tSelectedConcess.preview then tSelectedConcess.preview = {} end
        tSelectedConcess.preview[#tSelectedConcess.preview + 1] = { x = pos.x, y = pos.y, z = pos.z - 0.99, h = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point preview ajouté." })
        fcRefresh(ConcessEdit)
    end)

    for i, point in ipairs(tSelectedConcess.preview or {}) do
        ConcessEdit.Button("Point #" .. i, ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tSelectedConcess.preview, i)
            fcRefresh(ConcessEdit)
        end)
    end

    ConcessEdit.Separator(":car: POINTS SPAWN (" .. #(tSelectedConcess.spawn or {}) .. ")")

    ConcessEdit.Button(":plus: Ajouter point spawn", "", nil, "chevron", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        if not tSelectedConcess.spawn then tSelectedConcess.spawn = {} end
        tSelectedConcess.spawn[#tSelectedConcess.spawn + 1] = { x = pos.x, y = pos.y, z = pos.z, h = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point spawn ajouté." })
        fcRefresh(ConcessEdit)
    end)

    for i, point in ipairs(tSelectedConcess.spawn or {}) do
        ConcessEdit.Button("Point #" .. i, ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tSelectedConcess.spawn, i)
            fcRefresh(ConcessEdit)
        end)
    end

    ConcessEdit.Separator(":trophy: POINTS SHOWCASE (" .. #(tSelectedConcess.showcase or {}) .. ")")

    ConcessEdit.Button(":plus: Ajouter point showcase", "", nil, "chevron", false, function()
        local sModel = VFW.Nui.KeyboardInput(true, "Modèle du véhicule (ex: adder)", "")
        if sModel and sModel ~= "" then
            local pos = GetEntityCoords(PlayerPedId())
            local heading = GetEntityHeading(PlayerPedId())
            if not tSelectedConcess.showcase then tSelectedConcess.showcase = {} end
            tSelectedConcess.showcase[#tSelectedConcess.showcase + 1] = {
                x = pos.x,
                y = pos.y,
                z = pos.z - 0.99,
                h = heading,
                model = sModel:lower()
            }
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point showcase ajouté avec le modèle : " .. sModel .. "." })
            fcRefresh(ConcessEdit)
        end
    end)

    for i, point in ipairs(tSelectedConcess.showcase or {}) do
        ConcessEdit.Button("Point #" .. i .. " - " .. (point.model or "?"), ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tSelectedConcess.showcase, i)
            fcRefresh(ConcessEdit)
        end)
    end

    ConcessEdit.Separator(":wrench: ACTIONS")

    ConcessEdit.Button(":save: SAUVEGARDER", "Enregistrer les modifications", nil, "check", false, function()
        TriggerServerEvent("core:concess:update", tSelectedConcess.id, tSelectedConcess)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Concessionnaire modifié." })
        ConcessEdit.close()
        SetTimeout(300, function()
            ConcessManage.open()
        end)
    end)

    ConcessEdit.Button(":trash: SUPPRIMER", "Supprimer ce concessionnaire", nil, "trash", false, function()
        local confirmResult = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour supprimer", "")
        if confirmResult and confirmResult:upper() == "CONFIRMER" then
            TriggerServerEvent("core:concess:delete", tSelectedConcess.id)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Concessionnaire supprimé." })
            ConcessEdit.close()
            SetTimeout(300, function()
                ConcessManage.open()
            end)
        end
    end)
end)

-- ==================== GESTION VÉHICULES ====================

ConcessVehicles.OnOpen(function()
    local tCategories = TriggerServerCallback("core:concess:getCategories")
    local tAllVehicles = TriggerServerCallback("core:concess:getVehicles")

    ConcessVehicles.Separator(":chart: STATISTIQUES")

    local iTotalVehicles = 0
    if tAllVehicles then
        for _, tCatVehicles in pairs(tAllVehicles) do
            for _ in pairs(tCatVehicles) do
                iTotalVehicles = iTotalVehicles + 1
            end
        end
    end

    ConcessVehicles.Button(":chart: TOTAL", tostring(iTotalVehicles) .. (iTotalVehicles > 1 and " véhicules" or " véhicule"), nil, nil, true, function() end)

    ConcessVehicles.Separator(":folder: CATÉGORIES")

    ConcessVehicles.Button(":settings: GÉRER LES CATÉGORIES", "Créer ou supprimer des catégories", nil, "chevron", false, function()
    end, ConcessCategories)

    ConcessVehicles.Separator(":car: PAR CATÉGORIE")

    if not tCategories or #tCategories == 0 then
        ConcessVehicles.Button(":document: AUCUNE CATÉGORIE", "Créez-en une d'abord", nil, nil, true, function() end)
    else
        for _, sCategory in ipairs(tCategories) do
            local tVehicles = tAllVehicles and tAllVehicles[sCategory] or {}
            local iCount = 0
            for _ in pairs(tVehicles) do iCount = iCount + 1 end

            ConcessVehicles.Button(":folder: " .. sCategory:upper(), iCount .. (iCount > 1 and " véhicules" or " véhicule"), nil, "chevron", false, function()
                tSelectedCategory = sCategory
            end, ConcessVehiclesByCategory)
        end
    end

    ConcessVehicles.Separator(":plus: ACTIONS")

    local bHasCategories = tCategories and #tCategories > 0
    ConcessVehicles.Button(":plus: AJOUTER UN VÉHICULE", bHasCategories and "" or "Créez une catégorie d'abord", nil, bHasCategories and "chevron" or "lock", not bHasCategories, function()
        tNewVehicle = { sModel = "", sName = "", sCategory = tCategories[1] or "", iPrice = 0 }
    end, ConcessVehicleAdd)
end)

-- Catégories
ConcessCategories.OnOpen(function()
    local tCategories = TriggerServerCallback("core:concess:getCategoriesWithType")

    ConcessCategories.Button(":plus: CRÉER UNE CATÉGORIE", "", nil, "chevron", false, function()
        tNewCategory = ""
      tNewCategoryType = 1
    end, ConcessCategoryCreate)

    ConcessCategories.Separator(":report: CATÉGORIES")

    if not tCategories or #tCategories == 0 then
        ConcessCategories.Button(":document: AUCUNE CATÉGORIE", "", nil, nil, true, function() end)
    else
        local typeIcons = { [1] = ":car:", [2] = ":car:", [3] = ":rocket:" }
        local typeNames = { [1] = "Voiture", [2] = "Bateau", [3] = "Avion" }
        for _, cat in ipairs(tCategories) do
            local catName = cat.name
            local catType = cat.concess_type or 1
            local icon = typeIcons[catType] or ":car:"
          local typeName = typeNames[catType] or "Voiture"
          ConcessCategories.Button(icon .. " " .. catName:upper(), typeName, nil, "trash", false, function()
                local confirmResult = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour supprimer '" .. catName .. "'", "")
                if confirmResult and confirmResult:upper() == "CONFIRMER" then
                    TriggerServerEvent("core:concess:deleteCategory", catName)
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Catégorie supprimée." })
                    fcRefresh(ConcessCategories)
                end
            end)
        end
    end
end)

local tNewCategoryType = 1
local concessTypeLabels = { [1] = "Voiture", [2] = "Bateau", [3] = "Avion" }
local concessTypeList = { "Voiture", "Bateau", "Avion" }

ConcessCategoryCreate.OnOpen(function()
    ConcessCategoryCreate.Button(":edit: NOM", tNewCategory ~= "" and tNewCategory or "Non défini", nil, fcGetIcon(tNewCategory ~= ""), false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nom de la catégorie", "")
        if sInput and sInput ~= "" then
            tNewCategory = sInput:lower()
            fcRefresh(ConcessCategoryCreate)
        end
    end)

    ConcessCategoryCreate.List(":tag: TYPE", nil, false, concessTypeList, tNewCategoryType, function(index, value)
        tNewCategoryType = index
    end)

    local bCanCreate = tNewCategory ~= ""
  ConcessCategoryCreate.Button(":check: CRÉER", bCanCreate and ("Prêt à créer : " .. concessTypeLabels[tNewCategoryType]) or "Nom requis", nil, bCanCreate and "check" or "lock", not bCanCreate, function()
        if not bCanCreate then return end
        TriggerServerEvent("core:concess:createCategory", tNewCategory, tNewCategoryType)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Catégorie '" .. tNewCategory .. "' créée (" .. concessTypeLabels[tNewCategoryType] .. ")." })
        tNewCategory = ""
      tNewCategoryType = 1
        ConcessCategoryCreate.refresh()
    end)
end)

-- Véhicules par catégorie
ConcessVehiclesByCategory.OnOpen(function()
    if not tSelectedCategory then return end

    local tVehicles = TriggerServerCallback("core:concess:getVehicles", tSelectedCategory)

    ConcessVehiclesByCategory.Separator(":car: " .. tSelectedCategory:upper())

    if not tVehicles or not next(tVehicles) then
        ConcessVehiclesByCategory.Button(":document: AUCUN VÉHICULE", "", nil, nil, true, function() end)
    else
        for sModel, tVehicle in pairs(tVehicles) do
            ConcessVehiclesByCategory.Button(":car: " .. tVehicle.name, "Model: " .. tVehicle.model .. " | " .. VFW.Math.FormatMoney(tVehicle.price), nil, "chevron", false, function()
                tSelectedVehicle = tVehicle
            end, ConcessVehicleEditor)
        end
    end
end)

-- Éditeur véhicule
ConcessVehicleEditor.OnOpen(function()
    if not tSelectedVehicle then return end

    ConcessVehicleEditor.Separator(":car: " .. tSelectedVehicle.name)

    ConcessVehicleEditor.Button(":id: MODEL", tSelectedVehicle.model, nil, nil, true, function() end)

    ConcessVehicleEditor.Button(":tag: NOM", tSelectedVehicle.name, nil, "chevron", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nouveau nom", tSelectedVehicle.name)
        if sInput and sInput ~= "" then
            tSelectedVehicle.name = sInput
            fcRefresh(ConcessVehicleEditor)
        end
    end)

    ConcessVehicleEditor.Button(":money: PRIX DE VENTE", VFW.Math.FormatMoney(tSelectedVehicle.price) .. " (achat usine auto: /2)", nil, "chevron", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Prix de vente (achat usine = prix/2)", tostring(tSelectedVehicle.price))
        if sInput and tonumber(sInput) then
            tSelectedVehicle.price = tonumber(sInput)
            fcRefresh(ConcessVehicleEditor)
        end
    end)

    local tCategories = TriggerServerCallback("core:concess:getCategories")
    local iCatIndex = 1
    for i, sCat in ipairs(tCategories) do
        if sCat == tSelectedVehicle.category then iCatIndex = i break end
    end

    ConcessVehicleEditor.List(":folder: CATÉGORIE", nil, false, tCategories, iCatIndex, function(index)
        tSelectedVehicle.category = tCategories[index]
    end)

    ConcessVehicleEditor.Separator(":wrench: ACTIONS")

    ConcessVehicleEditor.Button(":save: SAUVEGARDER", "", nil, "check", false, function()
        TriggerServerEvent("core:concess:updateVehicle", tSelectedVehicle.model, tSelectedVehicle.name, tSelectedVehicle.price, tSelectedVehicle.category)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Véhicule modifié." })
        ConcessVehicleEditor.close()
        SetTimeout(300, function() ConcessVehiclesByCategory.open() end)
    end)

    ConcessVehicleEditor.Button(":trash: SUPPRIMER", "", nil, "trash", false, function()
        local confirmResult = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER'", "")
        if confirmResult and confirmResult:upper() == "CONFIRMER" then
            TriggerServerEvent("core:concess:deleteVehicle", tSelectedVehicle.model)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Véhicule supprimé." })
            ConcessVehicleEditor.close()
            SetTimeout(300, function() ConcessVehiclesByCategory.open() end)
        end
    end)
end)

-- Ajouter véhicule
ConcessVehicleAdd.OnOpen(function()
    local tCategories = TriggerServerCallback("core:concess:getCategories")

    ConcessVehicleAdd.Separator(":plus: NOUVEAU VÉHICULE")

    local iCatIndex = 1
    for i, sCat in ipairs(tCategories) do
        if sCat == tNewVehicle.sCategory then iCatIndex = i break end
    end

    ConcessVehicleAdd.List(":folder: CATÉGORIE", nil, false, tCategories, iCatIndex, function(index)
        tNewVehicle.sCategory = tCategories[index]
    end)

    ConcessVehicleAdd.Button(":edit: MODEL", tNewVehicle.sModel ~= "" and tNewVehicle.sModel or "Non défini", nil, fcGetIcon(tNewVehicle.sModel ~= ""), false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nom du modèle (ex: adder)", "")
        if sInput and sInput ~= "" then
            tNewVehicle.sModel = sInput:lower()
            if tNewVehicle.sName == "" then
                tNewVehicle.sName = sInput:sub(1,1):upper() .. sInput:sub(2)
            end
            fcRefresh(ConcessVehicleAdd)
        end
    end)

    ConcessVehicleAdd.Button(":tag: NOM", tNewVehicle.sName ~= "" and tNewVehicle.sName or "Non défini", nil, fcGetIcon(tNewVehicle.sName ~= ""), false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nom affiché", tNewVehicle.sName)
        if sInput and sInput ~= "" then
            tNewVehicle.sName = sInput
            fcRefresh(ConcessVehicleAdd)
        end
    end)

    ConcessVehicleAdd.Button(":money: PRIX DE VENTE", VFW.Math.FormatMoney(tNewVehicle.iPrice) .. " (achat usine auto: /2)", nil, "check", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Prix de vente (achat usine = prix/2)", tostring(tNewVehicle.iPrice))
        if sInput and tonumber(sInput) then
            tNewVehicle.iPrice = tonumber(sInput)
            fcRefresh(ConcessVehicleAdd)
        end
    end)

    local bCanCreate = tNewVehicle.sModel ~= "" and tNewVehicle.sName ~= "" and tNewVehicle.sCategory ~= ""

  ConcessVehicleAdd.Button(":check: CRÉER", bCanCreate and "Prêt" or "Model, Nom et Catégorie requis", nil, bCanCreate and "check" or "lock", not bCanCreate, function()
        if not bCanCreate then return end
        TriggerServerEvent("core:concess:addVehicle", tNewVehicle.sModel, tNewVehicle.sName, tNewVehicle.sCategory, tNewVehicle.iPrice)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Véhicule ajouté." })
        tNewVehicle = { sModel = "", sName = "", sCategory = tNewVehicle.sCategory, iPrice = 0 }
        ConcessVehicleAdd.close()
        SetTimeout(300, function() ConcessVehicles.open() end)
    end)
end)
