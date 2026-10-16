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
local tNewCategoryType = 1
local concessTypeLabels = { [1] = "Voiture", [2] = "Bateau", [3] = "Avion" }
local concessTypeList = { "Voiture", "Bateau", "Avion" }

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

-- Jobs / catégories en cache : OnOpen / softRefresh ne doit JAMAIS yield (sinon UI bloquée).
local societiesCache = nil
local categoriesCache = nil
local categoriesWithTypeCache = nil

--- `.opened` d'un menu VUI est une copie figée (export FiveM) : ne jamais s'en servir.
local function fcRefresh(Menu)
    if not Menu then return end
    if Menu.softRefresh then
        Menu.softRefresh()
    elseif Menu.refresh then
        Menu.refresh()
    end
end

local function fcLoadSocieties()
    CreateThread(function()
        societiesCache = TriggerServerCallback("core:get:societies") or {}
        fcRefresh(ConcessCreate)
        fcRefresh(ConcessEdit)
    end)
end

local function fcLoadCategories()
    CreateThread(function()
        categoriesCache = TriggerServerCallback("core:concess:getCategories") or {}
        categoriesWithTypeCache = TriggerServerCallback("core:concess:getCategoriesWithType") or {}
        fcRefresh(ConcessCategories)
        fcRefresh(ConcessCategoryCreate)
        fcRefresh(ConcessVehicleEditor)
        fcRefresh(ConcessVehicleAdd)
    end)
end

local function fcGetSocieties()
    return societiesCache or {}
end

local function fcGetCategories()
    return categoriesCache or {}
end

local function fcGetCategoriesWithType()
    return categoriesWithTypeCache or {}
end

local function fcGetIcon(condition)
    return condition and "check" or "chevron"
end

local function fcPointLabel(n)
    return tostring(n) .. (n ~= 1 and " points" or " point")
end

local function fcCoords(offsetZ)
    local pos = GetEntityCoords(PlayerPedId())
    local h = GetEntityHeading(PlayerPedId())
    return { x = pos.x, y = pos.y, z = pos.z - (offsetZ or 0.0), h = h }
end

--- Ancien clavier NUI : le hub se masque le temps de la saisie (cover/uncover).
local function fcAskText(title, defaultValue, onDone)
    CreateThread(function()
        local sInput = VFW.Nui.KeyboardInput(true, title, defaultValue or "")
        if type(sInput) == "string" then
            sInput = sInput:match("^%s*(.-)%s*$") or ""
        end
        if sInput and sInput ~= "" then
            onDone(sInput)
        end
    end)
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

--- isAuto() / getJob() / onPick : évitent les valeurs figées au build du menu.
local function fcAddJobList(Menu, getJob, isAuto, onPick)
    local societies = fcGetSocieties()
    local jobNames = {}
    local jobIndex = 1
    local i = 1
    local currentJob = getJob and getJob() or ""
    for jobName in pairs(societies) do
        jobNames[i] = jobName
        if jobName == currentJob then jobIndex = i end
        i = i + 1
    end
    if #jobNames > 0 then
        Menu.List(":briefcase: JOB ACCÈS", "Ignoré si mode auto activé", false, jobNames, jobIndex, function(index)
            if isAuto and isAuto() then return end
            onPick(jobNames[index])
        end)
    else
        Menu.Button(":briefcase: JOB ACCÈS", societiesCache and "Aucun job disponible" or "Chargement…", nil, "lock", true, function() end)
    end
end

-- Menu principal
function StaffMenu.BuildConcessMenu()
    StaffMenu.builderConcess.Separator(":car: GESTION CONCESSIONNAIRE")

    StaffMenu.builderConcess.Button(":plus: CRÉER UN CONCESSIONNAIRE", "Créer un nouveau point de vente", nil, "chevron", false, function()
        fcResetNewConcess()
        fcLoadSocieties()
    end, ConcessCreate)

    StaffMenu.builderConcess.Button(":settings: GÉRER LES CONCESSIONNAIRES", "Modifier ou supprimer des concessionnaires", nil, "chevron", false, function()
    end, ConcessManage)

    StaffMenu.builderConcess.Separator(":box: CATALOGUE VÉHICULES")

    StaffMenu.builderConcess.Button(":car: GÉRER LES VÉHICULES", "Catégories et véhicules du catalogue", nil, "chevron", false, function()
    end, ConcessVehicles)
end

StaffMenu.builderConcess.OnOpen(function()
    if not societiesCache then fcLoadSocieties() end
    StaffMenu.BuildConcessMenu()
end)

-- ==================== CRÉATION CONCESSIONNAIRE ====================

ConcessCreate.OnOpen(function()
    if not societiesCache then fcLoadSocieties() end

    ConcessCreate.Separator(":edit: INFORMATIONS")

    ConcessCreate.Button(":tag: NOM", tNewConcess.name ~= "" and tNewConcess.name or "Non défini", nil, fcGetIcon(tNewConcess.name ~= ""), false, function()
        fcAskText("Nom du concessionnaire", tNewConcess.name, function(sInput)
            tNewConcess.name = sInput
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Nom : " .. sInput })
            fcRefresh(ConcessCreate)
        end)
    end)

    ConcessCreate.List(":car: TYPE VÉHICULES", nil, false, concessTypes, tNewConcess.concessType, function(index)
        tNewConcess.concessType = index
    end)

    ConcessCreate.Checkbox(":robot: MODE AUTO PERMANENT", "PED toujours présent (pas besoin d'employés)", false, tNewConcess.automatic, function(checked)
        tNewConcess.automatic = checked == true
        if tNewConcess.automatic then tNewConcess.job = "" end
        fcRefresh(ConcessCreate)
    end)

    fcAddJobList(ConcessCreate,
        function() return tNewConcess.job end,
        function() return tNewConcess.automatic end,
        function(job) tNewConcess.job = job end
    )

    ConcessCreate.Button(":user: MODÈLE PED", tNewConcess.pedModel, nil, "chevron", false, function()
        fcAskText("Modèle du PED", tNewConcess.pedModel, function(sInput)
            tNewConcess.pedModel = sInput
            fcRefresh(ConcessCreate)
        end)
    end)

    ConcessCreate.Separator(":pin: POINTS CATALOGUE")

    ConcessCreate.Button(":plus: Ajouter point catalogue", fcPointLabel(#tNewConcess.catalog), nil, "chevron", false, function()
        tNewConcess.catalog[#tNewConcess.catalog + 1] = fcCoords(0.99)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point catalogue : " .. #tNewConcess.catalog })
        fcRefresh(ConcessCreate)
    end)

    for i, point in ipairs(tNewConcess.catalog) do
        ConcessCreate.Button("Point #" .. i, ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tNewConcess.catalog, i)
            fcRefresh(ConcessCreate)
        end)
    end

    ConcessCreate.Separator(":eye: POINTS PREVIEW")

    ConcessCreate.Button(":plus: Ajouter point preview", fcPointLabel(#tNewConcess.preview), nil, "chevron", false, function()
        tNewConcess.preview[#tNewConcess.preview + 1] = fcCoords(0.99)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point preview : " .. #tNewConcess.preview })
        fcRefresh(ConcessCreate)
    end)

    for i, point in ipairs(tNewConcess.preview) do
        ConcessCreate.Button("Point #" .. i, ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tNewConcess.preview, i)
            fcRefresh(ConcessCreate)
        end)
    end

    ConcessCreate.Separator(":car: POINTS SPAWN")

    ConcessCreate.Button(":plus: Ajouter point spawn", fcPointLabel(#tNewConcess.spawn), nil, "chevron", false, function()
        tNewConcess.spawn[#tNewConcess.spawn + 1] = fcCoords(0)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point spawn : " .. #tNewConcess.spawn })
        fcRefresh(ConcessCreate)
    end)

    for i, point in ipairs(tNewConcess.spawn) do
        ConcessCreate.Button("Point #" .. i, ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tNewConcess.spawn, i)
            fcRefresh(ConcessCreate)
        end)
    end

    ConcessCreate.Separator(":trophy: POINTS SHOWCASE")

    ConcessCreate.Button(":plus: Ajouter point showcase", fcPointLabel(#tNewConcess.showcase), nil, "chevron", false, function()
        fcAskText("Modèle du véhicule (ex: adder)", "", function(sModel)
            local p = fcCoords(0.99)
            p.model = sModel:lower()
            tNewConcess.showcase[#tNewConcess.showcase + 1] = p
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Showcase : " .. sModel })
            fcRefresh(ConcessCreate)
        end)
    end)

    for i, point in ipairs(tNewConcess.showcase) do
        ConcessCreate.Button("Point #" .. i .. " - " .. (point.model or "?"), ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tNewConcess.showcase, i)
            fcRefresh(ConcessCreate)
        end)
    end

    ConcessCreate.Separator(":wrench: ACTIONS")

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
    -- Ne jamais reset ici (refresh / softRefresh).
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
    if not societiesCache then fcLoadSocieties() end

    if not tSelectedConcess.catalog then tSelectedConcess.catalog = {} end
    if not tSelectedConcess.preview then tSelectedConcess.preview = {} end
    if not tSelectedConcess.spawn then tSelectedConcess.spawn = {} end
    if not tSelectedConcess.showcase then tSelectedConcess.showcase = {} end

    ConcessEdit.Separator(":edit: " .. (tSelectedConcess.name or "?"))

    ConcessEdit.Button(":tag: NOM", tSelectedConcess.name or "Non défini", nil, "chevron", false, function()
        fcAskText("Nouveau nom", tSelectedConcess.name or "", function(sInput)
            tSelectedConcess.name = sInput
            fcRefresh(ConcessEdit)
        end)
    end)

    ConcessEdit.List(":car: TYPE VÉHICULES", nil, false, concessTypes, tSelectedConcess.concessType or 1, function(index)
        tSelectedConcess.concessType = index
    end)

    ConcessEdit.Checkbox(":robot: MODE AUTO PERMANENT", "PED toujours présent (pas besoin d'employés)", false, tSelectedConcess.automatic or false, function(checked)
        tSelectedConcess.automatic = checked == true
        if tSelectedConcess.automatic then tSelectedConcess.job = "" end
        fcRefresh(ConcessEdit)
    end)

    fcAddJobList(ConcessEdit,
        function() return tSelectedConcess.job end,
        function() return tSelectedConcess.automatic end,
        function(job) tSelectedConcess.job = job end
    )

    ConcessEdit.Button(":user: MODÈLE PED", tSelectedConcess.pedModel or "a_m_y_business_01", nil, "chevron", false, function()
        fcAskText("Modèle du PED", tSelectedConcess.pedModel or "", function(sInput)
            tSelectedConcess.pedModel = sInput
            fcRefresh(ConcessEdit)
        end)
    end)

    ConcessEdit.Separator(":pin: POINTS CATALOGUE")

    ConcessEdit.Button(":plus: Ajouter point catalogue", fcPointLabel(#tSelectedConcess.catalog), nil, "chevron", false, function()
        tSelectedConcess.catalog[#tSelectedConcess.catalog + 1] = fcCoords(0.99)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point catalogue : " .. #tSelectedConcess.catalog })
        fcRefresh(ConcessEdit)
    end)

    for i, point in ipairs(tSelectedConcess.catalog) do
        ConcessEdit.Button("Point #" .. i, ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tSelectedConcess.catalog, i)
            fcRefresh(ConcessEdit)
        end)
    end

    ConcessEdit.Separator(":eye: POINTS PREVIEW")

    ConcessEdit.Button(":plus: Ajouter point preview", fcPointLabel(#tSelectedConcess.preview), nil, "chevron", false, function()
        tSelectedConcess.preview[#tSelectedConcess.preview + 1] = fcCoords(0.99)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point preview : " .. #tSelectedConcess.preview })
        fcRefresh(ConcessEdit)
    end)

    for i, point in ipairs(tSelectedConcess.preview) do
        ConcessEdit.Button("Point #" .. i, ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tSelectedConcess.preview, i)
            fcRefresh(ConcessEdit)
        end)
    end

    ConcessEdit.Separator(":car: POINTS SPAWN")

    ConcessEdit.Button(":plus: Ajouter point spawn", fcPointLabel(#tSelectedConcess.spawn), nil, "chevron", false, function()
        tSelectedConcess.spawn[#tSelectedConcess.spawn + 1] = fcCoords(0)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Point spawn : " .. #tSelectedConcess.spawn })
        fcRefresh(ConcessEdit)
    end)

    for i, point in ipairs(tSelectedConcess.spawn) do
        ConcessEdit.Button("Point #" .. i, ("%.2f, %.2f, %.2f"):format(point.x, point.y, point.z), nil, "trash", false, function()
            table.remove(tSelectedConcess.spawn, i)
            fcRefresh(ConcessEdit)
        end)
    end

    ConcessEdit.Separator(":trophy: POINTS SHOWCASE")

    ConcessEdit.Button(":plus: Ajouter point showcase", fcPointLabel(#tSelectedConcess.showcase), nil, "chevron", false, function()
        fcAskText("Modèle du véhicule (ex: adder)", "", function(sModel)
            local p = fcCoords(0.99)
            p.model = sModel:lower()
            tSelectedConcess.showcase[#tSelectedConcess.showcase + 1] = p
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Showcase : " .. sModel })
            fcRefresh(ConcessEdit)
        end)
    end)

    for i, point in ipairs(tSelectedConcess.showcase) do
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
        fcAskText("Tapez 'CONFIRMER' pour supprimer", "", function(confirmResult)
            if confirmResult:upper() == "CONFIRMER" then
                TriggerServerEvent("core:concess:delete", tSelectedConcess.id)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Concessionnaire supprimé." })
                ConcessEdit.close()
                SetTimeout(300, function()
                    ConcessManage.open()
                end)
            end
        end)
    end)
end)

-- ==================== GESTION VÉHICULES ====================

ConcessVehicles.OnOpen(function()
    if not categoriesCache then fcLoadCategories() end
    local tCategories = TriggerServerCallback("core:concess:getCategories")
    local tAllVehicles = TriggerServerCallback("core:concess:getVehicles")
    categoriesCache = tCategories or categoriesCache

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
    if not categoriesWithTypeCache then fcLoadCategories() end
    local tCategories = fcGetCategoriesWithType()

    ConcessCategories.Button(":plus: CRÉER UNE CATÉGORIE", "", nil, "chevron", false, function()
        tNewCategory = ""
        tNewCategoryType = 1
    end, ConcessCategoryCreate)

    ConcessCategories.Separator(":report: CATÉGORIES")

    if not tCategories or #tCategories == 0 then
        ConcessCategories.Button(":document: AUCUNE CATÉGORIE", categoriesWithTypeCache and "" or "Chargement…", nil, nil, true, function() end)
    else
        local typeIcons = { [1] = ":car:", [2] = ":car:", [3] = ":rocket:" }
        local typeNames = { [1] = "Voiture", [2] = "Bateau", [3] = "Avion" }
        for _, cat in ipairs(tCategories) do
            local catName = cat.name
            local catType = cat.concess_type or 1
            local icon = typeIcons[catType] or ":car:"
            local typeName = typeNames[catType] or "Voiture"
            ConcessCategories.Button(icon .. " " .. catName:upper(), typeName, nil, "trash", false, function()
                fcAskText("Tapez 'CONFIRMER' pour supprimer '" .. catName .. "'", "", function(confirmResult)
                    if confirmResult:upper() == "CONFIRMER" then
                        TriggerServerEvent("core:concess:deleteCategory", catName)
                        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Catégorie supprimée." })
                        categoriesCache = nil
                        categoriesWithTypeCache = nil
                        fcLoadCategories()
                    end
                end)
            end)
        end
    end
end)

ConcessCategoryCreate.OnOpen(function()
    ConcessCategoryCreate.Button(":edit: NOM", tNewCategory ~= "" and tNewCategory or "Non défini", nil, fcGetIcon(tNewCategory ~= ""), false, function()
        fcAskText("Nom de la catégorie", tNewCategory, function(sInput)
            tNewCategory = sInput:lower()
            fcRefresh(ConcessCategoryCreate)
        end)
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
        categoriesCache = nil
        categoriesWithTypeCache = nil
        fcLoadCategories()
        ConcessCategoryCreate.close()
        SetTimeout(200, function() ConcessCategories.open() end)
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
    if not categoriesCache then fcLoadCategories() end

    ConcessVehicleEditor.Separator(":car: " .. tSelectedVehicle.name)

    ConcessVehicleEditor.Button(":id: MODEL", tSelectedVehicle.model, nil, nil, true, function() end)

    ConcessVehicleEditor.Button(":tag: NOM", tSelectedVehicle.name, nil, "chevron", false, function()
        fcAskText("Nouveau nom", tSelectedVehicle.name, function(sInput)
            tSelectedVehicle.name = sInput
            fcRefresh(ConcessVehicleEditor)
        end)
    end)

    ConcessVehicleEditor.Button(":money: PRIX DE VENTE", VFW.Math.FormatMoney(tSelectedVehicle.price) .. " (achat usine auto: /2)", nil, "chevron", false, function()
        fcAskText("Prix de vente (achat usine = prix/2)", tostring(tSelectedVehicle.price), function(sInput)
            if tonumber(sInput) then
                tSelectedVehicle.price = tonumber(sInput)
                fcRefresh(ConcessVehicleEditor)
            end
        end)
    end)

    local tCategories = fcGetCategories()
    local iCatIndex = 1
    for i, sCat in ipairs(tCategories) do
        if sCat == tSelectedVehicle.category then iCatIndex = i break end
    end

    if #tCategories > 0 then
        ConcessVehicleEditor.List(":folder: CATÉGORIE", nil, false, tCategories, iCatIndex, function(index)
            tSelectedVehicle.category = tCategories[index]
        end)
    else
        ConcessVehicleEditor.Button(":folder: CATÉGORIE", "Chargement…", nil, "lock", true, function() end)
    end

    ConcessVehicleEditor.Separator(":wrench: ACTIONS")

    ConcessVehicleEditor.Button(":save: SAUVEGARDER", "", nil, "check", false, function()
        TriggerServerEvent("core:concess:updateVehicle", tSelectedVehicle.model, tSelectedVehicle.name, tSelectedVehicle.price, tSelectedVehicle.category)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Véhicule modifié." })
        ConcessVehicleEditor.close()
        SetTimeout(300, function() ConcessVehiclesByCategory.open() end)
    end)

    ConcessVehicleEditor.Button(":trash: SUPPRIMER", "", nil, "trash", false, function()
        fcAskText("Tapez 'CONFIRMER'", "", function(confirmResult)
            if confirmResult:upper() == "CONFIRMER" then
                TriggerServerEvent("core:concess:deleteVehicle", tSelectedVehicle.model)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Concessionnaires', message = "Véhicule supprimé." })
                ConcessVehicleEditor.close()
                SetTimeout(300, function() ConcessVehiclesByCategory.open() end)
            end
        end)
    end)
end)

-- Ajouter véhicule
ConcessVehicleAdd.OnOpen(function()
    if not categoriesCache then fcLoadCategories() end
    local tCategories = fcGetCategories()

    ConcessVehicleAdd.Separator(":plus: NOUVEAU VÉHICULE")

    local iCatIndex = 1
    for i, sCat in ipairs(tCategories) do
        if sCat == tNewVehicle.sCategory then iCatIndex = i break end
    end

    if #tCategories > 0 then
        ConcessVehicleAdd.List(":folder: CATÉGORIE", nil, false, tCategories, iCatIndex, function(index)
            tNewVehicle.sCategory = tCategories[index]
        end)
    else
        ConcessVehicleAdd.Button(":folder: CATÉGORIE", categoriesCache and "Aucune catégorie" or "Chargement…", nil, "lock", true, function() end)
    end

    ConcessVehicleAdd.Button(":edit: MODEL", tNewVehicle.sModel ~= "" and tNewVehicle.sModel or "Non défini", nil, fcGetIcon(tNewVehicle.sModel ~= ""), false, function()
        fcAskText("Nom du modèle (ex: adder)", "", function(sInput)
            tNewVehicle.sModel = sInput:lower()
            if tNewVehicle.sName == "" then
                tNewVehicle.sName = sInput:sub(1,1):upper() .. sInput:sub(2)
            end
            fcRefresh(ConcessVehicleAdd)
        end)
    end)

    ConcessVehicleAdd.Button(":tag: NOM", tNewVehicle.sName ~= "" and tNewVehicle.sName or "Non défini", nil, fcGetIcon(tNewVehicle.sName ~= ""), false, function()
        fcAskText("Nom affiché", tNewVehicle.sName, function(sInput)
            tNewVehicle.sName = sInput
            fcRefresh(ConcessVehicleAdd)
        end)
    end)

    ConcessVehicleAdd.Button(":money: PRIX DE VENTE", VFW.Math.FormatMoney(tNewVehicle.iPrice) .. " (achat usine auto: /2)", nil, "check", false, function()
        fcAskText("Prix de vente (achat usine = prix/2)", tostring(tNewVehicle.iPrice), function(sInput)
            if tonumber(sInput) then
                tNewVehicle.iPrice = tonumber(sInput)
                fcRefresh(ConcessVehicleAdd)
            end
        end)
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
