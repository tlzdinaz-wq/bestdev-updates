local VUI                   = exports["VUI"]
local defaultBanner         = VFW.CDN.Get("banners/admin.png")

local main                  = VUI:CreateMenu("Menu métier", defaultBanner, true)

-- Expose the menu globally so the admin menu can integrate it as a submenu
SocietyBuilderMenu = main

local createJob             = VUI:CreateSubMenu(main, "Menu Création", defaultBanner, true)
local createJobGrades       = VUI:CreateSubMenu(createJob, "Menu Grades", defaultBanner, true)
local createJobGradesData   = VUI:CreateSubMenu(createJobGrades, "Données du grade", defaultBanner, true)
local createJobBlip         = VUI:CreateSubMenu(createJob, "Menu Blip", defaultBanner, true)
local createJobDJ           = VUI:CreateSubMenu(createJob, "Menu DJ", defaultBanner, true)
local createJobCustoms      = VUI:CreateSubMenu(createJob, "Menu Customs", defaultBanner, true)
local createJobConcess      = VUI:CreateSubMenu(createJob, "Options personnalisées", defaultBanner, true)
local createJobLTD          = VUI:CreateSubMenu(createJob, "Menu Livraisons LTD", defaultBanner, true)
local createJobCatalog      = VUI:CreateSubMenu(createJob, "Points Catalogue", defaultBanner, true)
local createJobTaxi         = VUI:CreateSubMenu(createJob, "Menu Taxi", defaultBanner, true)
local createJobCraft        = VUI:CreateSubMenu(createJob, "Points de récolte", defaultBanner, true)
local createJobBanner       = VUI:CreateSubMenu(createJob, "Bannière du métier", defaultBanner, true)

local modifyJob             = VUI:CreateSubMenu(main, "Menu Modification", defaultBanner, true)
local modifyJobData         = VUI:CreateSubMenu(modifyJob, "Données du métier", defaultBanner, true)
local modifyJobDoorbells    = VUI:CreateSubMenu(modifyJobData, "Sonnettes", defaultBanner, true)
local modifyJobDoorbellData = VUI:CreateSubMenu(modifyJobDoorbells, "Détails sonnette", defaultBanner, true)
local modifyJobGrades       = VUI:CreateSubMenu(modifyJobData, "Gestion Grades", defaultBanner, true)
local modifyJobProps        = VUI:CreateSubMenu(modifyJobData, "Gestion Props", defaultBanner, true)
local modifyJobPropsData    = VUI:CreateSubMenu(modifyJobProps, "Détails du prop", defaultBanner, true)
local modifyJobGradesData   = VUI:CreateSubMenu(modifyJobGrades, "Données du grade", defaultBanner, true)
local modifyJobBlip         = VUI:CreateSubMenu(modifyJobData, "Gestion Blip", defaultBanner, true)
local modifyJobDJ           = VUI:CreateSubMenu(modifyJobData, "Gestion DJ", defaultBanner, true)
local modifyJobCustoms      = VUI:CreateSubMenu(modifyJobData, "Gestion Customs", defaultBanner, true)
local modifyJobLTD          = VUI:CreateSubMenu(modifyJobData, "Gestion Livraisons LTD", defaultBanner, true)
local modifyJobConcess      = VUI:CreateSubMenu(modifyJobData, "Options personnalisées", defaultBanner, true)
local modifyJobCatalog      = VUI:CreateSubMenu(modifyJobData, "Points Catalogue", defaultBanner, true)
local modifyJobTaxi         = VUI:CreateSubMenu(modifyJobData, "Gestion Taxi", defaultBanner, true)
local modifyJobCraft        = VUI:CreateSubMenu(modifyJobData, "Points de récolte", defaultBanner, true)
local modifyJobBanner       = VUI:CreateSubMenu(modifyJobData, "Bannière du métier", defaultBanner, true)

local function getJobDefaultCreationData()
    return {
        type = 1,
        name = nil,
        label = nil,
        image = nil,
        banner = nil,
        address = nil,
        blip = {},
        management = {},
        custom = {},
        grades = {
            {
                grade = 98,
                name = "copatron",
                label = "Co-Patron",
                salary = 400,
                is_boss = true
            },
            {
                grade = 99,
                name = "boss",
                label = "Boss",
                salary = 500,
                is_boss = true
            }
        }
    }
end

local jobInCreation = getJobDefaultCreationData()

local jobGradeInCreation = {}

local jobInModification = {}
local jobModificationSelection = {}
local modifyJobQuery = nil
local propInEdition = {}
local propsSearchQuery = nil
local propPreviewObj = nil
local doorbellInEdition = {}

local function DeletePropPreview()
    if propPreviewObj and DoesEntityExist(propPreviewObj) then
        DeleteEntity(propPreviewObj)
    end
    propPreviewObj = nil
end

local function SpawnPropPreview(model)
    DeletePropPreview()
    if not model or model == "" then return false end

    local modelHash = type(model) == "number" and model or GetHashKey(model)
    if not IsModelInCdimage(modelHash) then
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'ERROR',
            subtitle = 'JobsProps',
            message = "Modèle introuvable : " .. tostring(model)
        })
        return false
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnPos = coords + forward * 2.0

    VFW.Game.SpawnLocalObject(model, spawnPos, function(obj)
        if obj and DoesEntityExist(obj) then
            propPreviewObj = obj
            SetEntityAlpha(obj, 200, false)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, true)
            PlaceObjectOnGroundProperly(obj)
        end
    end)
end

local jobTypes = {}

local builders <const> = {
    ["manageDJ"] = {
        ["modify"] = modifyJobDJ,
        ["create"] = createJobDJ
    },
    ["manageCustoms"] = {
        ["modify"] = modifyJobCustoms,
        ["create"] = createJobCustoms
    },
    ["manageCraft"] = {
        ["modify"] = modifyJobCraft,
        ["create"] = createJobCraft
    },
    ["manageConcess"] = {
        ["modify"] = modifyJobConcess,
        ["create"] = createJobConcess
    },
    ["manageLTD"] = {
        ["modify"] = modifyJobLTD,
        ["create"] = createJobLTD
    },
    ["manageCatalog"] = {
        ["modify"] = modifyJobCatalog,
        ["create"] = createJobCatalog
    },
    ["manageTaxi"] = {
        ["modify"] = modifyJobTaxi,
        ["create"] = createJobTaxi
    }
}

main.OnOpen(function()
    local jobModels <const> = JobModel.getAll()
    jobTypes = {}

    for jobModel, _ in pairs(jobModels) do
        jobTypes[#jobTypes + 1] = jobModel
    end

    main.Button("Créer un métier", "", nil, "chevron", false, function()
        jobInCreation = getJobDefaultCreationData()
    end, createJob)

    main.Button("Modifier un métier", "", nil, "chevron", false, function()
    end, modifyJob)
end)

modifyJob.OnOpen(function()
    local societes <const> = TriggerServerCallback('core:get:societies')

    -- Barre de recherche
    local firstLabel = modifyJobQuery == nil and "RECHERCHER" or "RECHERCHER:"
    local lastLabel = modifyJobQuery == nil and "UN MÉTIER" or modifyJobQuery

    modifyJob.Button(firstLabel, lastLabel, nil, "search", false, function()
        if modifyJobQuery ~= nil then
            modifyJobQuery = nil
            modifyJob.refresh()
            return
        end

        modifyJobQuery = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label")
        if modifyJobQuery == nil or modifyJobQuery == "" then
            modifyJobQuery = nil
            return
        end

        modifyJob.refresh()
    end)

    -- Trier par ordre alphabétique
    local sorted = {}
    for k, v in pairs(societes) do
        sorted[#sorted + 1] = { name = k, label = v.label or "Inconnu", type = v.type }
    end
    table.sort(sorted, function(a, b)
        return string.lower(a.label) < string.lower(b.label)
    end)

    for _, v in ipairs(sorted) do
        if modifyJobQuery == nil or string.find(string.lower(v.name), string.lower(modifyJobQuery)) or string.find(string.lower(v.label), string.lower(modifyJobQuery)) then
            modifyJob.Button(("%s (%s)"):format(v.label, v.name), ("Type: %s"):format(v.type), nil, "chevron", false,
                function()
                    jobInModification = TriggerServerCallback("core:get:societyData", v.name)
                end, modifyJobData)
        end
    end
end)

modifyJobData.OnOpen(function()
    modifyJobData.Button("Label du métier", "", jobInModification.label or "Non défini", nil, false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrez le label du métier", "")
        if label == "" then
            return
        end

        jobInModification.label = label
        modifyJobData.refresh()
    end)

    modifyJobData.Button("Gestion Grades", "", nil, "chevron", false, function()
    end, modifyJobGrades)

    modifyJobData.Button("Gérer les props", "", nil, "chevron", false, function()
    end, modifyJobProps)

    local modelData <const> = JobModel.get(jobInModification.type)

    if modelData then
        for k, _ in pairs(modelData.activeBuilders) do
            local modelType <const> = JobModel.getType(k)

            if modelType then
                modifyJobData.Button(modelType.label, "", nil, "chevron", false, function()
                end, builders[modelType.submenu].modify)
            end
        end

        for _, v in pairs(modelData.addonFields) do
            if v.type == "position" then
                modifyJobData.Button(v.label, "", jobInModification.custom?[v.name] and "Défini" or "Non défini",
                    "chevron", false, function()
                        local pos <const> = GetEntityCoords(PlayerPedId())
                        jobInModification.custom[v.name] = pos
                        modifyJobData.refresh()
                    end)
            else
                local converter <const> = v.type == "number" and tonumber or tostring

                modifyJobData.Button(v.label, "", converter(jobInModification.custom?[v.name] or "Non défini"), "chevron",
                    false, function()
                        local value <const> = converter(VFW.Nui.KeyboardInput(true,
                            ("Entrez la valeur pour %s"):format(v.label), ""))
                        if not value or value == "" then
                            return
                        end

                        jobInModification.custom[v.name] = value
                        modifyJobData.refresh()
                    end)
            end
        end
    end



    modifyJobData.Button("Emplacement (label)", "", jobInModification.address and #jobInModification.address > 0 and jobInModification.address or "Non défini",
        nil, false, function()
            local address <const> = VFW.Nui.KeyboardInput(true, "Entrez le label de l'emplacement (ex: Vinewood Hills)", "")
            if address == "" then
                return
            end

            jobInModification.address = address
            modifyJobData.refresh()
        end)

    modifyJobData.Button("Position du menu gestion", "", jobInModification.management.x and "Définie" or "Non définie",
        "chevron", false, function()
            local ped <const> = PlayerPedId()
            local pos <const> = GetEntityCoords(ped)

            jobInModification.management = { x = pos.x, y = pos.y, z = pos.z }
            modifyJobData.refresh()
        end)

    modifyJobData.Button("Image du métier", "", jobInModification.image or "Non défini", nil, false, function()
        local image <const> = VFW.Nui.KeyboardInput(true, "Entrez l'URL de l'image du métier", "")
        if image == "" then
            return
        end

        jobInModification.image = image
        modifyJobData.refresh()
    end)

    if jobInModification.image and jobInModification.image ~= "" then
        modifyJobData.Imagebox(jobInModification.image, nil)
    end

    modifyJobData.Button("Bannière du métier", "", jobInModification.banner or "Non définie", "chevron", false, function()
    end, modifyJobBanner)

    if jobInModification.banner and jobInModification.banner ~= "" then
        modifyJobData.Imagebox(jobInModification.banner, nil)
    end

    modifyJobData.Separator(nil)

    -- Sonnettes
    local doorbellCount = jobInModification.doorbells and #jobInModification.doorbells or 0
    modifyJobData.Button("Sonnettes", ("(%d configurée%s)"):format(doorbellCount, doorbellCount > 1 and "s" or ""),
        nil, "chevron", false, function() end, modifyJobDoorbells)

    modifyJobData.Button("Modifier le métier", "", nil, "chevron", false, function()
        if not jobInModification.name or not jobInModification.label or not jobInModification.management.x then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Builder',
                message = "Veuillez définir toutes les informations du métier avant de le modifier."
            })
            return
        end

        if jobInModification.blip.enabled then
            if not jobInModification.blip.name or not jobInModification.blip.sprite or not jobInModification.blip.color or not jobInModification.blip.scale then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Builder',
                    message = "Veuillez définir toutes les informations du blip avant de le modifier."
                })
                return
            end
        end

        TriggerServerEvent("core:modify:society", jobInModification.name, jobInModification)
    end)

    modifyJobData.Button("Supprimer le métier", "", nil, "trash", false, function()
        TriggerServerEvent("core:delete:society", jobInModification.name)
        main.open()
    end)
end)

modifyJobBlip.OnOpen(function()
    modifyJobBlip.Checkbox("Activer le blip", "", false, jobInModification.blip.enabled or false, function(checked)
        jobInModification.blip.enabled = checked
        modifyJobBlip.refresh()
    end)

    if jobInModification.blip.enabled then
        modifyJobBlip.Button("Position du blip", "", jobInModification.blip.position.x and "Définie" or "Non définie",
            "chevron", false, function()
                local ped <const> = PlayerPedId()
                local pos <const> = GetEntityCoords(ped)

                jobInModification.blip.position = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
                modifyJobBlip.refresh()
            end)

        modifyJobBlip.Button("Nom du blip", "", jobInModification.blip.name or "Non défini", nil, false, function()
            local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du blip", "")
            if name == "" then
                return
            end

            jobInModification.blip.name = name
            modifyJobBlip.refresh()
        end)

        modifyJobBlip.Button("Sprite du blip", "", jobInModification.blip.sprite or "Non défini", nil, false, function()
            local sprite <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrez le sprite du blip", ""))
            if not sprite then
                return
            end

            jobInModification.blip.sprite = sprite
            modifyJobBlip.refresh()
        end)

        modifyJobBlip.Button("Couleur du blip", "", jobInModification.blip.color or "Non défini", nil, false, function()
            local color <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrez la couleur du blip", ""))
            if not color then
                return
            end

            jobInModification.blip.color = color
            modifyJobBlip.refresh()
        end)

        modifyJobBlip.Button("Taille du blip", "", jobInModification.blip.scale or "Non défini", nil, false, function()
            local scale <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrez la taille du blip", ""))
            if not scale then
                return
            end

            jobInModification.blip.scale = scale
            modifyJobBlip.refresh()
        end)
    end
end)

modifyJobBanner.OnOpen(function()
    local banners = TriggerServerCallback("vfw:server:getBannerTemplatesPublic", "metier")

    -- Option URL personnalisée
    modifyJobBanner.Button("URL PERSONNALISÉE", "", jobInModification.banner or "Aucune", "chevron", false, function()
        local url = VFW.Nui.KeyboardInput(true, "Entrez l'URL de la bannière", "")
        if url and url ~= "" then
            jobInModification.banner = url
        end
        modifyJobBanner.refresh()
    end)

    if jobInModification.banner and jobInModification.banner ~= "" then
        modifyJobBanner.Imagebox(jobInModification.banner, nil)
    end

    modifyJobBanner.Separator("BANNIÈRES DISPONIBLES")

    if banners and #banners > 0 then
        for _, banner in ipairs(banners) do
            modifyJobBanner.Imagebox(banner.url, nil)
            local isSelected = jobInModification.banner == banner.url
            modifyJobBanner.Button(
                banner.name,
                isSelected and "Sélectionnée" or "Cliquer pour sélectionner",
                nil,
                isSelected and "check" or "chevron",
                false,
                function()
                    jobInModification.banner = banner.url
                    modifyJobBanner.refresh()
                end
            )
        end
    else
        modifyJobBanner.Button("AUCUNE BANNIÈRE", "Ajoutez-en depuis le gestionnaire d'images", nil, nil, true, function() end)
    end
end)

modifyJobGrades.OnOpen(function()
    modifyJobGrades.Button("Ajouter un grade", "", nil, "chevron", false, function()
        jobGradeInCreation = {}
    end, modifyJobGradesData)

    modifyJobGrades.Separator("Grades existants")
    Wait(100)

    -- Get grades from server
    local jobData = TriggerServerCallback("core:jobs:getJob", jobInModification.name)
    if jobData and jobData.grades then
        -- Trier par grade décroissant (99, 98, 97...)
        local sortedGrades = {}
        for _, grade in pairs(jobData.grades) do
            sortedGrades[#sortedGrades + 1] = grade
        end
        table.sort(sortedGrades, function(a, b)
            return a.grade > b.grade
        end)

        for _, grade in ipairs(sortedGrades) do
            modifyJobGrades.Button(
                grade.label .. " (#" .. grade.grade .. ")",
                ("Nom: %s, Salaire: %s"):format(grade.name, VFW.Math.FormatMoney(grade.salary)),
                nil,
                "edit",
                false,
                function()
                    jobGradeInCreation = {
                        grade = grade.grade,
                        name = grade.name,
                        label = grade.label,
                        salary = grade.salary,
                        is_boss = grade.is_boss == 1 or grade.is_boss == true,
                        isEditing = true
                    }
                end,
                modifyJobGradesData
            )
        end
    end
end)

modifyJobGradesData.OnOpen(function()
    local isEditing = jobGradeInCreation.isEditing or false
    local isBoss = jobGradeInCreation.is_boss or false

    modifyJobGradesData.Button("Nom du grade", "", jobGradeInCreation.name or "Non défini", nil, false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du grade", "")
        if name == "" then
            return
        end

        jobGradeInCreation.name = name
        modifyJobGradesData.refresh()
    end)

    modifyJobGradesData.Button("Label du grade", "", jobGradeInCreation.label or "Non défini", nil, false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrez le label du grade", "")
        if label == "" then
            return
        end

        jobGradeInCreation.label = label
        modifyJobGradesData.refresh()
    end)

    modifyJobGradesData.Button("Salaire du grade", "",
        jobGradeInCreation.salary and tostring(jobGradeInCreation.salary) or "Non défini", nil, false, function()
            local salary <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrez le salaire du grade", ""))
            if not salary then
                return
            end

            jobGradeInCreation.salary = salary
            modifyJobGradesData.refresh()
        end)

    modifyJobGradesData.Checkbox("Grade patron", "Ce grade aura toutes les permissions patron", false, isBoss,
        function(checked)
            jobGradeInCreation.is_boss = checked
            modifyJobGradesData.refresh()
        end)

    if isEditing then
        modifyJobGradesData.Button("Modifier le grade", "", nil, "chevron", false, function()
            if not jobGradeInCreation.grade or not jobGradeInCreation.name or not jobGradeInCreation.label or not jobGradeInCreation.salary then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Builder',
                    message = "Veuillez définir toutes les informations du grade avant de le modifier."
                })
                return
            end

            TriggerServerEvent("core:modify:society:grade", jobInModification.name, jobGradeInCreation)
            modifyJobGrades.open()
        end)

        -- Empêcher la suppression du grade patron
        if not isBoss then
            modifyJobGradesData.Button("Supprimer le grade", "", nil, "trash", false, function()
                TriggerServerEvent("core:delete:society:grade", jobInModification.name, jobGradeInCreation)
                modifyJobGrades.open()
            end)
        end
    else
        modifyJobGradesData.Button("Ajouter le grade", "", nil, "chevron", false, function()
            if not jobGradeInCreation.name or not jobGradeInCreation.label or not jobGradeInCreation.salary then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Builder',
                    message = "Veuillez définir toutes les informations du grade avant de l'ajouter."
                })
                return
            end

            TriggerServerEvent("core:add:society:grade", jobInModification.name, jobGradeInCreation)
            modifyJobGrades.open()
        end)
    end
end)

modifyJobDoorbells.OnOpen(function()
    local doorbells = jobInModification.doorbells or {}

    modifyJobDoorbells.Button("Ajouter une sonnette à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local msg <const> = VFW.Nui.KeyboardInput(true, "Message affiché aux employés", "Quelqu'un sonne à la porte.")
        if not msg or msg == "" then return end
        local callerMsg <const> = VFW.Nui.KeyboardInput(true, "Message affiché à l'appelant",
            "Votre sonnerie a bien été envoyée.")
        if not callerMsg or callerMsg == "" then return end

        local updated = TriggerServerCallback("society:doorbell:add", jobInModification.name, pos.x, pos.y, pos.z, msg,
            callerMsg)
        if updated then
            jobInModification.doorbells = updated
        end
        modifyJobDoorbells.refresh()
    end)

    modifyJobDoorbells.Separator(("Sonnettes (%d)"):format(#doorbells))

    for _, db in ipairs(doorbells) do
        modifyJobDoorbells.Button(
            db.message,
            ("x:%.1f y:%.1f z:%.1f"):format(db.x, db.y, db.z),
            nil, "edit", false,
            function()
                doorbellInEdition = {
                    id = db.id,
                    message = db.message,
                    callerMessage = db.callerMessage,
                    x = db.x,
                    y =
                        db.y,
                    z = db.z
                }
            end,
            modifyJobDoorbellData
        )
    end
end)

modifyJobDoorbellData.OnOpen(function()
    local db = doorbellInEdition
    if not db or not db.id then
        modifyJobDoorbells.open()
        return
    end

    modifyJobDoorbellData.Button("Message employés", "Texte affiché aux employés en service", db.message, "edit", false,
        function()
            local msg <const> = VFW.Nui.KeyboardInput(true, "Message affiché aux employés", db.message)
            if not msg or msg == "" then return end

            local updated = TriggerServerCallback("society:doorbell:update", jobInModification.name, db.id, msg,
                db.callerMessage)
            if updated then
                jobInModification.doorbells = updated
                doorbellInEdition.message = msg
            end
            modifyJobDoorbellData.refresh()
        end)

    modifyJobDoorbellData.Button("Message appelant", "Texte affiché au joueur qui sonne",
        db.callerMessage or "Votre sonnerie a bien été envoyée.", "edit", false, function()
            local msg <const> = VFW.Nui.KeyboardInput(true, "Message affiché à l'appelant",
                db.callerMessage or "Votre sonnerie a bien été envoyée.")
            if not msg or msg == "" then return end

            local updated = TriggerServerCallback("society:doorbell:update", jobInModification.name, db.id, db.message,
                msg)
            if updated then
                jobInModification.doorbells = updated
                doorbellInEdition.callerMessage = msg
            end
            modifyJobDoorbellData.refresh()
        end)

    modifyJobDoorbellData.Button("Repositionner ici", "Déplacer la sonnette à votre position", nil, "chevron", false,
        function()
            local pos <const> = GetEntityCoords(PlayerPedId())
            TriggerServerCallback("society:doorbell:delete", jobInModification.name, db.id)
            local updated = TriggerServerCallback("society:doorbell:add", jobInModification.name, pos.x, pos.y, pos.z,
                db.message, db.callerMessage)
            if updated then
                jobInModification.doorbells = updated
            end
            modifyJobDoorbells.open()
        end)

    modifyJobDoorbellData.Button("Se TP à la sonnette", "", nil, "chevron", false, function()
        SetEntityCoords(PlayerPedId(), db.x, db.y, db.z, false, false, false, false)
    end)

    modifyJobDoorbellData.Separator("")

    modifyJobDoorbellData.Button("Supprimer cette sonnette", "", nil, "trash", false, function()
        local updated = TriggerServerCallback("society:doorbell:delete", jobInModification.name, db.id)
        if updated then
            jobInModification.doorbells = updated
        end
        modifyJobDoorbells.open()
    end)
end)

modifyJobProps.OnOpen(function()
    if not jobInModification.custom.props then
        jobInModification.custom.props = {}
    end

    local minPlace = jobInModification.custom.propsMinGradePlace or 0
    local minRemove = jobInModification.custom.propsMinGradeRemove or 0
    local maxProps = jobInModification.custom.propsMaxPlayer
    local propsMenuDesc = jobInModification.custom.propsMenuDesc or ""

    modifyJobProps.Button("Description du bouton", "Texte affiché sous le bouton Props dans le menu métier",
        propsMenuDesc ~= "" and propsMenuDesc or "Par défaut", nil, false, function()
            local input = VFW.Nui.KeyboardInput(true, "Description du bouton Props (laisser vide = défaut)",
                propsMenuDesc)
            if input == nil then return end
            jobInModification.custom.propsMenuDesc = input ~= "" and input or nil
            modifyJobProps.refresh()
        end)

    modifyJobProps.Button("Grade min. pour poser", "Grade minimum requis pour placer des props", tostring(minPlace), nil,
        false, function()
            local input = VFW.Nui.KeyboardInput(true, "Grade minimum pour poser (0 = tous)", tostring(minPlace))
            local grade = tonumber(input)
            if grade then
                jobInModification.custom.propsMinGradePlace = grade
                modifyJobProps.refresh()
            end
        end)

    modifyJobProps.Button("Grade min. pour supprimer", "Grade minimum requis pour supprimer des props",
        tostring(minRemove), nil, false, function()
            local input = VFW.Nui.KeyboardInput(true, "Grade minimum pour supprimer (0 = tous)", tostring(minRemove))
            local grade = tonumber(input)
            if grade then
                jobInModification.custom.propsMinGradeRemove = grade
                modifyJobProps.refresh()
            end
        end)

    modifyJobProps.Button("Limite max de props", "Nombre maximum de props par joueur (vide = défaut : 15)",
        maxProps and tostring(maxProps) or "Défaut (15)", nil, false, function()
            local current = maxProps and tostring(maxProps) or ""
            local input = VFW.Nui.KeyboardInput(true, "Limite max de props (laisser vide = défaut : 15)", current)
            if input == nil then return end
            local val = tonumber(input)
            jobInModification.custom.propsMaxPlayer = (val and val > 0) and val or nil
            modifyJobProps.refresh()
        end)

    modifyJobProps.Separator("Props (" .. #jobInModification.custom.props .. ")")

    modifyJobProps.Button("Ajouter un prop", "", nil, "chevron", false, function()
        propInEdition = { isNew = true }
    end, modifyJobPropsData)

    local firstLabel = propsSearchQuery == nil and "RECHERCHER" or "RECHERCHER:"
    local lastLabel = propsSearchQuery == nil and "UN PROP" or propsSearchQuery
    modifyJobProps.Button(firstLabel, lastLabel, nil, nil, false, function()
        if propsSearchQuery ~= nil then
            propsSearchQuery = nil
            modifyJobProps.refresh()
            return
        end

        propsSearchQuery = VFW.Nui.KeyboardInput(true, "Rechercher un prop (nom ou modèle)")
        if propsSearchQuery == nil or propsSearchQuery == "" then
            propsSearchQuery = nil
        end
        modifyJobProps.refresh()
    end)

    for k, v in ipairs(jobInModification.custom.props) do
        local match = true
        if propsSearchQuery then
            local q = string.lower(propsSearchQuery)
            match = string.find(string.lower(v.name), q) or string.find(string.lower(v.model), q)
        end

        if match then
            modifyJobProps.Button(
                v.name,
                v.desc and (v.desc .. " · " .. v.model) or ("Modèle: " .. v.model),
                nil,
                "edit",
                false,
                function()
                    propInEdition = { index = k, model = v.model, name = v.name, desc = v.desc }
                end,
                modifyJobPropsData
            )
        end
    end
end)

modifyJobPropsData.OnOpen(function()
    if propInEdition.model and propInEdition.model ~= "" then
        SpawnPropPreview(propInEdition.model)
    end

    if propInEdition.isNew then
        modifyJobPropsData.Button("Modèle", "Nom technique du prop", propInEdition.model or "Non défini", nil, false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Nom du modèle (ex: prop_mp_cone_02)",
                    propInEdition.model or "")
                if not input or input == "" then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'JobsProps',
                        message =
                        "Ce nom de modèle n'est pas valide"
                    })
                    return
                end
                local ok = SpawnPropPreview(input)
                if ok == false then return end
                propInEdition.model = input
                modifyJobPropsData.refresh()
            end)

        modifyJobPropsData.Button("Nom affiché", "Nom visible dans le menu", propInEdition.name or "Non défini", nil,
            false, function()
                local input = VFW.Nui.KeyboardInput(true, "Nom affiché (ex: Cône de signalisation)",
                    propInEdition.name or "")
                if not input or input == "" then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'JobsProps',
                        message =
                        "Ce nom affiché n'est pas valide"
                    })
                    return
                end
                propInEdition.name = input
                modifyJobPropsData.refresh()
            end)

        modifyJobPropsData.Button("Description", "Description optionnelle sous le bouton", propInEdition.desc or "Aucune",
            nil, false, function()
                local input = VFW.Nui.KeyboardInput(true, "Description (optionnelle, laisser vide pour aucune)",
                    propInEdition.desc or "")
                propInEdition.desc = (input and input ~= "") and input or nil
                modifyJobPropsData.refresh()
            end)

        modifyJobPropsData.Separator("")

        modifyJobPropsData.Button("Ajouter le prop", "", nil, "chevron", false, function()
            if not propInEdition.model or propInEdition.model == "" or not propInEdition.name or propInEdition.name == "" then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Builder',
                    message = "Veuillez définir le modèle et le nom du prop."
                })
                return
            end

            DeletePropPreview()
            table.insert(jobInModification.custom.props,
                { model = propInEdition.model, name = propInEdition.name, desc = propInEdition.desc })
            modifyJobProps.open()
        end)
    else
        modifyJobPropsData.Button("Modèle", "Nom technique du prop", propInEdition.model or "Non défini", nil, false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Nom du modèle", propInEdition.model or "")
                if not input or input == "" then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'JobsProps',
                        message =
                        "Ce nom de modèle n'est pas valide"
                    })
                    return
                end
                local ok = SpawnPropPreview(input)
                if ok == false then return end
                propInEdition.model = input
                jobInModification.custom.props[propInEdition.index].model = input
                modifyJobPropsData.refresh()
            end)

        modifyJobPropsData.Button("Nom affiché", "Nom visible dans le menu", propInEdition.name or "Non défini", nil,
            false, function()
                local input = VFW.Nui.KeyboardInput(true, "Nom affiché", propInEdition.name or "")
                if not input or input == "" then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'JobsProps',
                        message =
                        "Ce nom affiché n'est pas valide"
                    })
                    return
                end
                propInEdition.name = input
                jobInModification.custom.props[propInEdition.index].name = input
                modifyJobPropsData.refresh()
            end)

        modifyJobPropsData.Button("Description", "Description optionnelle sous le bouton", propInEdition.desc or "Aucune",
            nil, false, function()
                local input = VFW.Nui.KeyboardInput(true, "Description (optionnelle, laisser vide pour aucune)",
                    propInEdition.desc or "")
                propInEdition.desc = (input and input ~= "") and input or nil
                jobInModification.custom.props[propInEdition.index].desc = propInEdition.desc
                modifyJobPropsData.refresh()
            end)

        modifyJobPropsData.Separator("")

        modifyJobPropsData.Button("Supprimer ce prop", "", nil, "trash", false, function()
            DeletePropPreview()
            table.remove(jobInModification.custom.props, propInEdition.index)
            modifyJobProps.open()
        end)
    end
end)

modifyJobPropsData.OnClose(function()
    DeletePropPreview()
end)

modifyJobDJ.OnOpen(function()
    modifyJobDJ.Button("Ajouter un point DJ à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        if not jobInModification.custom.dj then
            jobInModification.custom.dj = {}
        end

        jobInModification.custom.dj[#jobInModification.custom.dj + 1] = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        modifyJobDJ.refresh()
    end)

    modifyJobDJ.Separator("Points DJ")

    for k, v in pairs(jobInModification.custom.dj or {}) do
        modifyJobDJ.Button("Point DJ #" .. k, ("Position: x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z), nil, "trash",
            false, function()
                jobInModification.custom.dj[k] = nil
                modifyJobDJ.refresh()
            end)
    end
end)

modifyJobCustoms.OnOpen(function()
    modifyJobCustoms.Button("Ajouter un point custom à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())

        if not jobInModification.custom.customs then
            jobInModification.custom.customs = {}
        end

        jobInModification.custom.customs[#jobInModification.custom.customs + 1] = { x = pos.x, y = pos.y, z = pos.z }
        modifyJobCustoms.refresh()
    end)

    modifyJobCustoms.Separator("Points Customs")

    for k, v in pairs(jobInModification.custom.customs or {}) do
        modifyJobCustoms.Button("Point Custom #" .. k, ("Position: x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z), nil,
            "trash", false, function()
                jobInModification.custom.customs[k] = nil
                modifyJobCustoms.refresh()
            end)
    end
end)

createJob.OnOpen(function()
    createJob.List('Type de métier', nil, false, jobTypes, jobInCreation.type, function(Index)
        jobInCreation = getJobDefaultCreationData()

        jobInCreation.type = Index
        createJob.refresh()
    end)

    createJob.Button("Nom du métier", "", jobInCreation.name or "Non défini", nil, false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du métier", "")
        if name == "" then
            return
        end

        jobInCreation.name = name
        createJob.refresh()
    end)

    createJob.Button("Label du métier", "", jobInCreation.label or "Non défini", nil, false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrez le label du métier", "")
        if label == "" then
            return
        end

        jobInCreation.label = label
        createJob.refresh()
    end)

    createJob.Button("Image du métier", "", jobInCreation.image or "Non défini", nil, false, function()
        local image <const> = VFW.Nui.KeyboardInput(true, "Entrez l'URL de l'image du métier", "")
        if image == "" then
            return
        end

        jobInCreation.image = image
        createJob.refresh()
    end)

    createJob.Button("Bannière du métier", "", jobInCreation.banner or "Non définie", "chevron", false, function()
    end, createJobBanner)

    createJob.Button("Emplacement (label)", "", jobInCreation.address and #jobInCreation.address > 0 and jobInCreation.address or "Non défini",
        nil, false, function()
            local address <const> = VFW.Nui.KeyboardInput(true, "Entrez le label de l'emplacement (ex: Vinewood Hills)", "")
            if address == "" then
                return
            end

            jobInCreation.address = address
            createJob.refresh()
        end)

    if jobInCreation.image and jobInCreation.image ~= "" then
        createJob.Imagebox(jobInCreation.image, nil)
    end

    createJob.Separator(nil)

    local modelName <const> = jobTypes[jobInCreation.type]
    local modelData <const> = JobModel.get(modelName)

    if modelData then
        for k, _ in pairs(modelData.activeBuilders) do
            local modelType <const> = JobModel.getType(k)

            if modelType then
                createJob.Button(modelType.label, "", nil, "chevron", false, function()
                end, builders[modelType.submenu].create)
            end
        end

        for _, v in pairs(modelData.addonFields) do
            if v.type == "position" then
                createJob.Button(v.label, "", jobInCreation.custom?[v.name] and "Défini" or "Non défini", "chevron",
                    false, function()
                        local pos <const> = GetEntityCoords(PlayerPedId())
                        jobInCreation.custom[v.name] = pos
                        createJob.refresh()
                    end)
            else
                local converter <const> = v.type == "number" and tonumber or tostring

                createJob.Button(v.label, "", converter(jobInCreation.custom?[v.name] or "Non défini"), "chevron", false,
                    function()
                        local value <const> = converter(VFW.Nui.KeyboardInput(true,
                            ("Entrez la valeur pour %s"):format(v.label), ""))
                        if not value or value == "" then
                            return
                        end

                        jobInCreation.custom[v.name] = value
                        createJob.refresh()
                    end)
            end
        end
    end

    createJob.Button("Position du menu gestion", "", jobInCreation.management.x and "Définie" or "Non définie", "chevron",
        false, function()
            local ped <const> = PlayerPedId()
            local pos <const> = GetEntityCoords(ped)

            jobInCreation.management = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
            createJob.refresh()
        end)

    createJob.Button("Créer le métier", "", nil, "chevron", false, function()
        if not jobInCreation.name or not jobInCreation.label or not jobInCreation.management.x then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Builder',
                message = "Veuillez définir toutes les informations du métier avant de le créer."
            })
            return
        end

        if jobInCreation.blip.enabled then
            if not jobInCreation.blip.name or not jobInCreation.blip.sprite or not jobInCreation.blip.color or not jobInCreation.blip.scale then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Builder',
                    message = "Veuillez définir toutes les informations du blip avant de le créer."
                })
                return
            end
        end

        if not jobInCreation.grades or not next(jobInCreation.grades) then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Builder',
                message = "Veuillez définir au moins un grade avant de créer le métier."
            })
            return
        end

        jobInCreation.type = jobTypes[jobInCreation.type]
        TriggerServerEvent("core:create:society", jobInCreation.name, jobInCreation)

        jobInCreation = getJobDefaultCreationData()

        main.open()
    end)
end)

createJobBanner.OnOpen(function()
    local banners = TriggerServerCallback("vfw:server:getBannerTemplatesPublic", "metier")

    -- Option URL personnalisée
    createJobBanner.Button("URL PERSONNALISÉE", "", jobInCreation.banner or "Aucune", "chevron", false, function()
        local url = VFW.Nui.KeyboardInput(true, "Entrez l'URL de la bannière", "")
        if url and url ~= "" then
            jobInCreation.banner = url
        end
        createJobBanner.refresh()
    end)

    if jobInCreation.banner and jobInCreation.banner ~= "" then
        createJobBanner.Imagebox(jobInCreation.banner, nil)
    end

    createJobBanner.Separator("BANNIÈRES DISPONIBLES")

    if banners and #banners > 0 then
        for _, banner in ipairs(banners) do
            createJobBanner.Imagebox(banner.url, nil)
            local isSelected = jobInCreation.banner == banner.url
            createJobBanner.Button(
                banner.name,
                isSelected and "Sélectionnée" or "Cliquer pour sélectionner",
                nil,
                isSelected and "check" or "chevron",
                false,
                function()
                    jobInCreation.banner = banner.url
                    createJobBanner.refresh()
                end
            )
        end
    else
        createJobBanner.Button("AUCUNE BANNIÈRE", "Ajoutez-en depuis le gestionnaire d'images", nil, nil, true, function() end)
    end
end)

createJobGrades.OnOpen(function()
    createJobGrades.Button("Ajouter un grade", "", nil, "chevron", false, function()
        jobGradeInCreation = {}
    end, createJobGradesData)

    createJobGrades.Separator("Grades")

    for k, v in pairs(jobInCreation.grades) do
        createJobGrades.Button("Grade #" .. k, ("Nom: %s, Salaire: %d"):format(v.name, v.salary), nil, "trash", false,
            function()
                jobInCreation.grades[k] = nil
                createJobGrades.refresh()
            end)
    end
end)

createJobGradesData.OnOpen(function()
    -- we stringify it here to show it because if the user types 0, the right label doesn't show
    createJobGradesData.Button("Numéro du grade", "",
        jobGradeInCreation.grade and tostring(jobGradeInCreation.grade) or "Non défini", nil, false, function()
            local grade <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrez le numéro du grade (hiérarchie)", ""))
            if not grade then
                return
            end

            jobGradeInCreation.grade = grade
            createJobGradesData.refresh()
        end)

    createJobGradesData.Button("Nom du grade", "", jobGradeInCreation.name or "Non défini", nil, false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du grade", "")
        if name == "" then
            return
        end

        jobGradeInCreation.name = name
        createJobGradesData.refresh()
    end)

    createJobGradesData.Button("Label du grade", "", jobGradeInCreation.label or "Non défini", nil, false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrez le label du grade", "")
        if label == "" then
            return
        end

        jobGradeInCreation.label = label
        createJobGradesData.refresh()
    end)

    -- we stringify it here to show it because if the user types 0, the right label doesn't show
    createJobGradesData.Button("Salaire du grade", "",
        jobGradeInCreation.salary and tostring(jobGradeInCreation.salary) or "Non défini", nil, false, function()
            local salary <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrez le salaire du grade", ""))
            if not salary then
                return
            end

            jobGradeInCreation.salary = salary
            createJobGradesData.refresh()
        end)

    createJobGradesData.Checkbox("Grade patron", "Ce grade aura toutes les permissions patron", false,
        jobGradeInCreation.is_boss or false, function(checked)
            jobGradeInCreation.is_boss = checked
            createJobGradesData.refresh()
        end)

    createJobGradesData.Button("Ajouter le grade", "", nil, "chevron", false, function()
        if not jobGradeInCreation.grade or not jobGradeInCreation.name or not jobGradeInCreation.label or not jobGradeInCreation.salary then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Builder',
                message = "Veuillez définir toutes les informations du grade avant de l'ajouter."
            })
            return
        end

        jobInCreation.grades[jobGradeInCreation.grade] = {
            grade = jobGradeInCreation.grade,
            name = jobGradeInCreation.name,
            label = jobGradeInCreation.label,
            salary = jobGradeInCreation.salary,
            is_boss = jobGradeInCreation.is_boss or false
        }

        createJobGrades.open()
    end)
end)

createJobBlip.OnOpen(function()
    createJobBlip.Checkbox("Afficher le blip", "", false, jobInCreation.blip.enabled or false, function(checked)
        jobInCreation.blip.enabled = checked
        createJobBlip.refresh()
    end)

    if jobInCreation.blip.enabled then
        createJobBlip.Button("Position du blip", "", jobInCreation.blip.position and "Défini" or "Non défini", nil, false,
            function()
                local pos = GetEntityCoords(PlayerPedId())
                jobInCreation.blip.position = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
                createJobBlip.refresh()
            end)

        createJobBlip.Button("Nom du blip", "", jobInCreation.blip.name or "Non défini", nil, false, function()
            local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du blip", "")
            if name == "" then
                return
            end

            jobInCreation.blip.name = name
            createJobBlip.refresh()
        end)

        createJobBlip.Button("Sprite du blip", "", jobInCreation.blip.sprite or "Non défini", nil, false, function()
            local sprite <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrez le sprite du blip", ""))
            if not sprite then
                return
            end

            jobInCreation.blip.sprite = sprite
            createJobBlip.refresh()
        end)

        createJobBlip.Button("Couleur du blip", "", jobInCreation.blip.color or "Non défini", nil, false, function()
            local color <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrez la couleur du blip", ""))
            if not color then
                return
            end

            jobInCreation.blip.color = color
            createJobBlip.refresh()
        end)

        createJobBlip.Button("Taille du blip", "", jobInCreation.blip.scale or "Non défini", nil, false, function()
            local scale <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrez la taille du blip", ""))
            if not scale then
                return
            end

            jobInCreation.blip.scale = scale
            createJobBlip.refresh()
        end)
    end
end)

createJobDJ.OnOpen(function()
    createJobDJ.Button("Ajouter un point DJ à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        if not jobInCreation.custom.dj then
            jobInCreation.custom.dj = {}
        end

        jobInCreation.custom.dj[#jobInCreation.custom.dj + 1] = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        createJobDJ.refresh()
    end)

    createJobDJ.Separator("Points DJ")

    for k, v in pairs(jobInCreation.custom.dj or {}) do
        createJobDJ.Button("Point DJ #" .. k, ("Position: x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z), nil, "trash",
            false, function()
                jobInCreation.custom.dj[k] = nil
                createJobDJ.refresh()
            end)
    end
end)

createJobCustoms.OnOpen(function()
    createJobCustoms.Button("Ajouter un point Customs à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        if not jobInCreation.custom.customs then
            jobInCreation.custom.customs = {}
        end

        jobInCreation.custom.customs[#jobInCreation.custom.customs + 1] = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        createJobCustoms.refresh()
    end)

    createJobCustoms.Separator("Points Customs")

    for k, v in pairs(jobInCreation.custom.customs or {}) do
        createJobCustoms.Button("Point Customs #" .. k, ("Position: x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z),
            nil, "trash", false, function()
                jobInCreation.custom.customs[k] = nil
                createJobCustoms.refresh()
            end)
    end
end)

local createJobLTDPoint = VUI:CreateSubMenu(createJobLTD, "Point de livraison", defaultBanner, true)
local createJobLTDPointIndex = nil
local createJobLTDPrices = VUI:CreateSubMenu(createJobLTD, "Prix Catalogue", defaultBanner, true)
local modifyJobLTDPrices = VUI:CreateSubMenu(modifyJobLTD, "Prix Catalogue", defaultBanner, true)

local function KeyboardInput(TextEntry, ExampleText, MaxStringLength)
    local result = VFW.Nui.KeyboardInput(true, TextEntry, ExampleText)
    if result == "" or result == "KBD_CANCEL" then
        return nil
    end
    return result
end

local createJobLTDPickupPoint = VUI:CreateSubMenu(createJobLTD, "Point de récupération", defaultBanner, true)
local createJobLTDPickupPointIndex = nil

local ltdPreviewEntities = {}
local ltdSinglePreview = nil

local function ClearAllLTDPreviews()
    for _, entity in ipairs(ltdPreviewEntities) do
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    ltdPreviewEntities = {}
    if ltdSinglePreview and DoesEntityExist(ltdSinglePreview) then
        DeleteEntity(ltdSinglePreview)
    end
    ltdSinglePreview = nil
end

local function ClearLTDPreview()
    if ltdSinglePreview and DoesEntityExist(ltdSinglePreview) then
        DeleteEntity(ltdSinglePreview)
    end
    ltdSinglePreview = nil
end

local function CreateLTDBoxPreviewEntity(coords)
    local model = GetHashKey("prop_cs_cardbox_01")
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(model) then return nil end
    local entity = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    PlaceObjectOnGroundProperly(entity)
    SetEntityAlpha(entity, 200, false)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(model)
    return entity
end

local function CreateLTDNpcPreviewEntity(coords, heading, npcModel)
    local model = GetHashKey(npcModel or "a_m_m_indian_01")
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(model) then return nil end
    local entity = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, heading or 0.0, false, false)
    SetEntityAlpha(entity, 200, false)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)
    SetEntityInvincible(entity, true)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetModelAsNoLongerNeeded(model)
    return entity
end

local function CreateLTDBoxPreview(coords)
    ClearLTDPreview()
    ltdSinglePreview = CreateLTDBoxPreviewEntity(coords)
end

local function CreateLTDNpcPreview(coords, heading, npcModel)
    ClearLTDPreview()
    ltdSinglePreview = CreateLTDNpcPreviewEntity(coords, heading, npcModel)
end

local function CreateAllLTDPreviews(pickupPoints, deliveryPoints)
    ClearAllLTDPreviews()
    for _, point in ipairs(pickupPoints or {}) do
        local entity = CreateLTDBoxPreviewEntity(point)
        if entity then
            table.insert(ltdPreviewEntities, entity)
        end
    end
    for _, point in ipairs(deliveryPoints or {}) do
        local entity = CreateLTDNpcPreviewEntity(point, point.w, point.npcModel)
        if entity then
            table.insert(ltdPreviewEntities, entity)
        end
    end
end

createJobLTD.OnOpen(function()
    CreateAllLTDPreviews(jobInCreation.custom.ltdPickupPoints, jobInCreation.custom.ltdDeliveryPoints)

    createJobLTD.Button("Prix Catalogue", "Configurer le prix de revente des items", nil, "chevron", false, function() end, createJobLTDPrices)

    createJobLTD.Separator("Points de récupération")

    createJobLTD.Button("Ajouter un point de récupération", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        if not jobInCreation.custom.ltdPickupPoints then
            jobInCreation.custom.ltdPickupPoints = {}
        end

        jobInCreation.custom.ltdPickupPoints[#jobInCreation.custom.ltdPickupPoints + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos.z,
            w = heading
        }
        CreateAllLTDPreviews(jobInCreation.custom.ltdPickupPoints, jobInCreation.custom.ltdDeliveryPoints)
        createJobLTD.refresh()
    end)

    for k, v in pairs(jobInCreation.custom.ltdPickupPoints or {}) do
        createJobLTD.Button("Point de récupération #" .. k, "", nil, "chevron", false, function()
            createJobLTDPickupPointIndex = k
        end, createJobLTDPickupPoint)
    end

    createJobLTD.Separator("Points de livraison")

    createJobLTD.Button("Ajouter un point de livraison", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        if not jobInCreation.custom.ltdDeliveryPoints then
            jobInCreation.custom.ltdDeliveryPoints = {}
        end

        jobInCreation.custom.ltdDeliveryPoints[#jobInCreation.custom.ltdDeliveryPoints + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos.z,
            w = heading,
            npcModel = "a_m_m_indian_01",
            npcName = "Client"
        }
        CreateAllLTDPreviews(jobInCreation.custom.ltdPickupPoints, jobInCreation.custom.ltdDeliveryPoints)
        createJobLTD.refresh()
    end)

    for k, v in pairs(jobInCreation.custom.ltdDeliveryPoints or {}) do
        createJobLTD.Button("Point #" .. k .. " - " .. (v.npcName or "Client"),
            ("Modèle: %s"):format(v.npcModel or "a_m_m_indian_01"), nil, "chevron", false, function()
                createJobLTDPointIndex = k
            end, createJobLTDPoint)
    end

    createJobLTD.Separator("Pourboire")

    createJobLTD.Button("Chance de pourboire (%)", tostring(jobInCreation.custom.tipChance or 0) .. "%", nil, "chevron",
        false, function()
            local input = KeyboardInput("Chance de pourboire (0-100)", tostring(jobInCreation.custom.tipChance or 0), 3)
            if input then
                local value = tonumber(input)
                if value and value >= 0 and value <= 100 then
                    jobInCreation.custom.tipChance = value
                    createJobLTD.refresh()
                end
            end
        end)

    createJobLTD.Button("Pourboire minimum (" .. LOCALE.currencySymbol .. ")", VFW.Math.FormatMoney(jobInCreation.custom.tipMin or 0), nil, "chevron", false,
        function()
            local input = KeyboardInput("Pourboire minimum", tostring(jobInCreation.custom.tipMin or 0), 6)
            if input then
                local value = tonumber(input)
                if value and value >= 0 then
                    jobInCreation.custom.tipMin = value
                    createJobLTD.refresh()
                end
            end
        end)

    createJobLTD.Button("Pourboire maximum (" .. LOCALE.currencySymbol .. ")", VFW.Math.FormatMoney(jobInCreation.custom.tipMax or 0), nil, "chevron", false,
        function()
            local input = KeyboardInput("Pourboire maximum", tostring(jobInCreation.custom.tipMax or 0), 6)
            if input then
                local value = tonumber(input)
                if value and value >= 0 then
                    jobInCreation.custom.tipMax = value
                    createJobLTD.refresh()
                end
            end
        end)
end)

createJobLTD.OnClose(function()
    ClearAllLTDPreviews()
end)

createJobLTDPickupPoint.OnOpen(function()
    local k = createJobLTDPickupPointIndex
    if not k or not jobInCreation.custom.ltdPickupPoints or not jobInCreation.custom.ltdPickupPoints[k] then
        createJobLTD.open()
        return
    end

    ClearAllLTDPreviews()
    local v = jobInCreation.custom.ltdPickupPoints[k]
    CreateLTDBoxPreview(v)

    createJobLTDPickupPoint.Button("Repositionner ici", "Déplacer le point à votre position", nil, "chevron", false,
        function()
            local pos <const> = GetEntityCoords(PlayerPedId())
            local heading <const> = GetEntityHeading(PlayerPedId())
            v.x = pos.x
            v.y = pos.y
            v.z = pos.z
            v.w = heading
            CreateLTDBoxPreview(v)
            createJobLTDPickupPoint.refresh()
        end)

    createJobLTDPickupPoint.Separator()

    createJobLTDPickupPoint.Button("Supprimer ce point", "", nil, "trash", false, function()
        ClearLTDPreview()
        table.remove(jobInCreation.custom.ltdPickupPoints, k)
        createJobLTD.open()
    end)

    createJobLTDPickupPoint.Button("Retour", "", nil, "arrow", false, function()
        createJobLTD.open()
    end)
end)

createJobLTDPickupPoint.OnClose(function()
    ClearLTDPreview()
end)

createJobLTDPoint.OnOpen(function()
    local k = createJobLTDPointIndex
    if not k or not jobInCreation.custom.ltdDeliveryPoints or not jobInCreation.custom.ltdDeliveryPoints[k] then
        createJobLTD.open()
        return
    end

    ClearAllLTDPreviews()
    local v = jobInCreation.custom.ltdDeliveryPoints[k]
    CreateLTDNpcPreview(v, v.w, v.npcModel)

    createJobLTDPoint.Button("Repositionner ici", "Déplacer le point à votre position", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        v.x = pos.x
        v.y = pos.y
        v.z = pos.z
        v.w = heading
        CreateLTDNpcPreview(v, v.w, v.npcModel)
        createJobLTDPoint.refresh()
    end)

    createJobLTDPoint.Button("Nom du PNJ", v.npcName or "Client", nil, "chevron", false, function()
        local input = KeyboardInput("Nom du PNJ", v.npcName or "Client", 32)
        if input and input ~= "" then
            v.npcName = input
            createJobLTDPoint.refresh()
        end
    end)

    createJobLTDPoint.Button("Modèle du PNJ", v.npcModel or "a_m_m_indian_01", nil, "chevron", false, function()
        local input = KeyboardInput("Modèle du PNJ", v.npcModel or "a_m_m_indian_01", 64)
        if input and input ~= "" then
            v.npcModel = input
            CreateLTDNpcPreview(v, v.w, v.npcModel)
            createJobLTDPoint.refresh()
        end
    end)

    createJobLTDPoint.Separator()

    createJobLTDPoint.Button("Supprimer ce point", "", nil, "trash", false, function()
        ClearLTDPreview()
        table.remove(jobInCreation.custom.ltdDeliveryPoints, k)
        createJobLTD.open()
    end)

    createJobLTDPoint.Button("Retour", "", nil, "arrow", false, function()
        createJobLTD.open()
    end)
end)

createJobLTDPoint.OnClose(function()
    ClearLTDPreview()
end)

local modifyJobLTDPoint = VUI:CreateSubMenu(modifyJobLTD, "Point de livraison", defaultBanner, true)
local modifyJobLTDPointIndex = nil
local modifyJobLTDPickupPoint = VUI:CreateSubMenu(modifyJobLTD, "Point de récupération", defaultBanner, true)
local modifyJobLTDPickupPointIndex = nil

modifyJobLTD.OnOpen(function()
    CreateAllLTDPreviews(jobInModification.custom.ltdPickupPoints, jobInModification.custom.ltdDeliveryPoints)

    modifyJobLTD.Button("Prix Catalogue", "Configurer le prix de revente des items", nil, "chevron", false, function() end, modifyJobLTDPrices)

    modifyJobLTD.Separator("Points de récupération")

    modifyJobLTD.Button("Ajouter un point de récupération", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        if not jobInModification.custom.ltdPickupPoints then
            jobInModification.custom.ltdPickupPoints = {}
        end

        jobInModification.custom.ltdPickupPoints[#jobInModification.custom.ltdPickupPoints + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos.z,
            w = heading
        }
        CreateAllLTDPreviews(jobInModification.custom.ltdPickupPoints, jobInModification.custom.ltdDeliveryPoints)
        modifyJobLTD.refresh()
    end)

    for k, v in pairs(jobInModification.custom.ltdPickupPoints or {}) do
        modifyJobLTD.Button("Point de récupération #" .. k, "", nil, "chevron", false, function()
            modifyJobLTDPickupPointIndex = k
        end, modifyJobLTDPickupPoint)
    end

    modifyJobLTD.Separator("Points de livraison")

    modifyJobLTD.Button("Ajouter un point de livraison", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        if not jobInModification.custom.ltdDeliveryPoints then
            jobInModification.custom.ltdDeliveryPoints = {}
        end

        jobInModification.custom.ltdDeliveryPoints[#jobInModification.custom.ltdDeliveryPoints + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos.z,
            w = heading,
            npcModel = "a_m_m_indian_01",
            npcName = "Client"
        }
        CreateAllLTDPreviews(jobInModification.custom.ltdPickupPoints, jobInModification.custom.ltdDeliveryPoints)
        modifyJobLTD.refresh()
    end)

    for k, v in pairs(jobInModification.custom.ltdDeliveryPoints or {}) do
        modifyJobLTD.Button("Point #" .. k .. " - " .. (v.npcName or "Client"),
            ("Modèle: %s"):format(v.npcModel or "a_m_m_indian_01"), nil, "chevron", false, function()
                modifyJobLTDPointIndex = k
            end, modifyJobLTDPoint)
    end

    modifyJobLTD.Separator("Pourboire")

    modifyJobLTD.Button("Chance de pourboire (%)", tostring(jobInModification.custom.tipChance or 0) .. "%", nil,
        "chevron", false, function()
            local input = KeyboardInput("Chance de pourboire (0-100)", tostring(jobInModification.custom.tipChance or 0),
                3)
            if input then
                local value = tonumber(input)
                if value and value >= 0 and value <= 100 then
                    jobInModification.custom.tipChance = value
                    modifyJobLTD.refresh()
                end
            end
        end)

    modifyJobLTD.Button("Pourboire minimum (" .. LOCALE.currencySymbol .. ")", VFW.Math.FormatMoney(jobInModification.custom.tipMin or 0), nil, "chevron",
        false, function()
            local input = KeyboardInput("Pourboire minimum", tostring(jobInModification.custom.tipMin or 0), 6)
            if input then
                local value = tonumber(input)
                if value and value >= 0 then
                    jobInModification.custom.tipMin = value
                    modifyJobLTD.refresh()
                end
            end
        end)

    modifyJobLTD.Button("Pourboire maximum (" .. LOCALE.currencySymbol .. ")", VFW.Math.FormatMoney(jobInModification.custom.tipMax or 0), nil, "chevron",
        false, function()
            local input = KeyboardInput("Pourboire maximum", tostring(jobInModification.custom.tipMax or 0), 6)
            if input then
                local value = tonumber(input)
                if value and value >= 0 then
                    jobInModification.custom.tipMax = value
                    modifyJobLTD.refresh()
                end
            end
        end)
end)

modifyJobLTD.OnClose(function()
    ClearAllLTDPreviews()
end)

modifyJobLTDPickupPoint.OnOpen(function()
    local k = modifyJobLTDPickupPointIndex
    if not k or not jobInModification.custom.ltdPickupPoints or not jobInModification.custom.ltdPickupPoints[k] then
        modifyJobLTD.open()
        return
    end

    ClearAllLTDPreviews()
    local v = jobInModification.custom.ltdPickupPoints[k]
    CreateLTDBoxPreview(v)

    modifyJobLTDPickupPoint.Button("Repositionner ici", "Déplacer le point à votre position", nil, "chevron", false,
        function()
            local pos <const> = GetEntityCoords(PlayerPedId())
            local heading <const> = GetEntityHeading(PlayerPedId())
            v.x = pos.x
            v.y = pos.y
            v.z = pos.z
            v.w = heading
            CreateLTDBoxPreview(v)
            modifyJobLTDPickupPoint.refresh()
        end)

    modifyJobLTDPickupPoint.Separator()

    modifyJobLTDPickupPoint.Button("Supprimer ce point", "", nil, "trash", false, function()
        ClearLTDPreview()
        table.remove(jobInModification.custom.ltdPickupPoints, k)
        modifyJobLTD.open()
    end)

    modifyJobLTDPickupPoint.Button("Retour", "", nil, "arrow", false, function()
        modifyJobLTD.open()
    end)
end)

modifyJobLTDPickupPoint.OnClose(function()
    ClearLTDPreview()
end)

modifyJobLTDPoint.OnOpen(function()
    local k = modifyJobLTDPointIndex
    if not k or not jobInModification.custom.ltdDeliveryPoints or not jobInModification.custom.ltdDeliveryPoints[k] then
        modifyJobLTD.open()
        return
    end

    ClearAllLTDPreviews()
    local v = jobInModification.custom.ltdDeliveryPoints[k]
    CreateLTDNpcPreview(v, v.w, v.npcModel)

    modifyJobLTDPoint.Button("Repositionner ici", "Déplacer le point à votre position", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        v.x = pos.x
        v.y = pos.y
        v.z = pos.z
        v.w = heading
        CreateLTDNpcPreview(v, v.w, v.npcModel)
        modifyJobLTDPoint.refresh()
    end)

    modifyJobLTDPoint.Button("Nom du PNJ", v.npcName or "Client", nil, "chevron", false, function()
        local input = KeyboardInput("Nom du PNJ", v.npcName or "Client", 32)
        if input and input ~= "" then
            v.npcName = input
            modifyJobLTDPoint.refresh()
        end
    end)

    modifyJobLTDPoint.Button("Modèle du PNJ", v.npcModel or "a_m_m_indian_01", nil, "chevron", false, function()
        local input = KeyboardInput("Modèle du PNJ", v.npcModel or "a_m_m_indian_01", 64)
        if input and input ~= "" then
            v.npcModel = input
            CreateLTDNpcPreview(v, v.w, v.npcModel)
            modifyJobLTDPoint.refresh()
        end
    end)

    modifyJobLTDPoint.Separator()

    modifyJobLTDPoint.Button("Supprimer ce point", "", nil, "trash", false, function()
        ClearLTDPreview()
        table.remove(jobInModification.custom.ltdDeliveryPoints, k)
        modifyJobLTD.open()
    end)

    modifyJobLTDPoint.Button("Retour", "", nil, "arrow", false, function()
        modifyJobLTD.open()
    end)
end)

modifyJobLTDPoint.OnClose(function()
    ClearLTDPreview()
end)

local function buildLTDPricesMenu(menu, customRef)
    customRef.ltdCatalogPrices = customRef.ltdCatalogPrices or {}
    menu.Separator("Prix de revente catalogue LTD")
    menu.Button("Réinitialiser aux valeurs par défaut", "Restaure tous les prix par défaut", nil, "trash", false,
        function()
            customRef.ltdCatalogPrices = {}
            for _, entry in ipairs(LTDItems.List) do
                customRef.ltdCatalogPrices[entry.item] = entry.sellPrice
            end
            menu.refresh()
        end)
    for _, entry in ipairs(LTDItems.List) do
        local current = customRef.ltdCatalogPrices[entry.item] or entry.sellPrice
        menu.Button(entry.label, VFW.Math.FormatMoney(current), nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Prix de revente pour " .. entry.label, tostring(current))
            local newPrice = tonumber(input)
            if newPrice and newPrice >= 0 then
                customRef.ltdCatalogPrices[entry.item] = math.floor(newPrice)
                menu.refresh()
            end
        end)
    end
end

createJobLTDPrices.OnOpen(function()
    buildLTDPricesMenu(createJobLTDPrices, jobInCreation.custom)
end)

modifyJobLTDPrices.OnOpen(function()
    buildLTDPricesMenu(modifyJobLTDPrices, jobInModification.custom)
end)

local concessTypes <const> = { "voiture", "bateau", "avion" }
local concessTypesLabels <const> = { ["voiture"] = "Voiture", ["bateau"] = "Bateau", ["avion"] = "Avion" }

createJobConcess.OnOpen(function()
    local currentType = jobInCreation.custom.concessType or 1
    createJobConcess.List("Type de concessionnaire", "", false, concessTypes, currentType, function(index)
        jobInCreation.custom.concessType = index
        createJobConcess.refresh()
    end)

    createJobConcess.Checkbox("Mode automatique", "Activer le mode automatique pour ce concessionnaire", false,
        jobInCreation.custom.automatic or false, function(checked)
            jobInCreation.custom.automatic = checked
            createJobConcess.refresh()
        end)

    createJobConcess.Separator("Points Catalogue")

    createJobConcess.Button("Ajouter un point Catalogue à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        if not jobInCreation.custom.catalog then
            jobInCreation.custom.catalog = {}
        end

        jobInCreation.custom.catalog[#jobInCreation.custom.catalog + 1] = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        createJobConcess.refresh()
    end)

    for k, v in pairs(jobInCreation.custom.catalog or {}) do
        createJobConcess.Button("Point Catalogue #" .. k, ("Position: x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z),
            nil, "trash", false, function()
                jobInCreation.custom.catalog[k] = nil
                createJobConcess.refresh()
            end)
    end

    createJobConcess.Separator("Points Preview")

    createJobConcess.Button("Ajouter un point Preview à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        if not jobInCreation.custom.preview then
            jobInCreation.custom.preview = {}
        end

        jobInCreation.custom.preview[#jobInCreation.custom.preview + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos.z - 0.99,
            h =
                heading
        }
        createJobConcess.refresh()
    end)

    for k, v in pairs(jobInCreation.custom.preview or {}) do
        createJobConcess.Button("Point Preview #" .. k,
            ("Position: x: %.2f, y: %.2f, z: %.2f, h: %.2f"):format(v.x, v.y, v.z, v.h or 0),
            nil, "trash", false, function()
                jobInCreation.custom.preview[k] = nil
                createJobConcess.refresh()
            end)
    end
end)

modifyJobConcess.OnOpen(function()
    local currentType = jobInModification.custom.concessType or 1
    modifyJobConcess.List("Type de concessionnaire", "", false, concessTypes, currentType, function(index)
        jobInModification.custom.concessType = index
        modifyJobConcess.refresh()
    end)

    modifyJobConcess.Checkbox("Mode automatique", "Activer le mode automatique pour ce concessionnaire", false,
        jobInModification.custom.automatic or false, function(checked)
            jobInModification.custom.automatic = checked
            modifyJobConcess.refresh()
        end)

    modifyJobConcess.Separator("Points Catalogue")

    modifyJobConcess.Button("Ajouter un point Catalogue à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        if not jobInModification.custom.catalog then
            jobInModification.custom.catalog = {}
        end

        jobInModification.custom.catalog[#jobInModification.custom.catalog + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos.z -
                0.99
        }
        modifyJobConcess.refresh()
    end)

    for k, v in pairs(jobInModification.custom.catalog or {}) do
        modifyJobConcess.Button("Point Catalogue #" .. k, ("Position: x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z),
            nil, "trash", false, function()
                jobInModification.custom.catalog[k] = nil
                modifyJobConcess.refresh()
            end)
    end

    modifyJobConcess.Separator("Points Preview")

    modifyJobConcess.Button("Ajouter un point Preview à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        if not jobInModification.custom.preview then
            jobInModification.custom.preview = {}
        end

        jobInModification.custom.preview[#jobInModification.custom.preview + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos.z -
                0.99,
            h = heading
        }
        modifyJobConcess.refresh()
    end)

    for k, v in pairs(jobInModification.custom.preview or {}) do
        modifyJobConcess.Button("Point Preview #" .. k,
            ("Position: x: %.2f, y: %.2f, z: %.2f, h: %.2f"):format(v.x, v.y, v.z, v.h or 0),
            nil, "trash", false, function()
                jobInModification.custom.preview[k] = nil
                modifyJobConcess.refresh()
            end)
    end
end)

-- ==================== POINTS CATALOGUE (DYNASTY, ETC.) ====================

createJobCatalog.OnOpen(function()
    createJobCatalog.Button("Ajouter un point Catalogue à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        if not jobInCreation.custom.catalog then
            jobInCreation.custom.catalog = {}
        end

        jobInCreation.custom.catalog[#jobInCreation.custom.catalog + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos.z - 0.99,
            h =
                heading
        }
        createJobCatalog.refresh()
    end)

    createJobCatalog.Separator("Points Catalogue")

    for k, v in pairs(jobInCreation.custom.catalog or {}) do
        createJobCatalog.Button("Point Catalogue #" .. k, ("Position: x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z),
            nil, "trash", false, function()
                jobInCreation.custom.catalog[k] = nil
                createJobCatalog.refresh()
            end)
    end
end)

modifyJobCatalog.OnOpen(function()
    modifyJobCatalog.Button("Ajouter un point Catalogue à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local heading <const> = GetEntityHeading(PlayerPedId())
        if not jobInModification.custom.catalog then
            jobInModification.custom.catalog = {}
        end

        jobInModification.custom.catalog[#jobInModification.custom.catalog + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos.z -
                0.99,
            h = heading
        }
        modifyJobCatalog.refresh()
    end)

    modifyJobCatalog.Separator("Points Catalogue")

    for k, v in pairs(jobInModification.custom.catalog or {}) do
        modifyJobCatalog.Button("Point Catalogue #" .. k, ("Position: x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z),
            nil, "trash", false, function()
                jobInModification.custom.catalog[k] = nil
                modifyJobCatalog.refresh()
            end)
    end
end)

-- ==================== GESTION TAXI ====================

createJobTaxi.OnOpen(function()
    if not jobInCreation.custom.enabledBaseZones then
        jobInCreation.custom.enabledBaseZones = {}
    end

    createJobTaxi.Separator("Zones de base")
    for _, zone in ipairs(TaxiJob.Config.BaseZones or {}) do
        createJobTaxi.Checkbox(
            zone.label, zone.desc, false,
            jobInCreation.custom.enabledBaseZones[zone.key] or false,
            function(checked)
                jobInCreation.custom.enabledBaseZones[zone.key] = checked
                createJobTaxi.refresh()
            end
        )
    end

    createJobTaxi.Separator("Zones custom")
    createJobTaxi.Button("Ajouter une zone de spawn PNJ à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local radiusInput = VFW.Nui.KeyboardInput(true, "Radius de la zone (défaut: 500)", "500")
        local radius = tonumber(radiusInput) or 500.0
        if radius <= 0 then radius = 500.0 end
        if not jobInCreation.custom.taxiSpawnZones then
            jobInCreation.custom.taxiSpawnZones = {}
        end

        jobInCreation.custom.taxiSpawnZones[#jobInCreation.custom.taxiSpawnZones + 1] = {
            x = pos.x,
            y = pos.y,
            z = pos
                .z,
            radius = radius
        }
        createJobTaxi.refresh()
    end)

    createJobTaxi.Separator("Zones de spawn PNJ")

    for k, v in pairs(jobInCreation.custom.taxiSpawnZones or {}) do
        local zoneRadius = v.radius or 500.0
        createJobTaxi.Button("Zone #" .. k,
            ("x: %.2f, y: %.2f, z: %.2f | Radius: %.0fm"):format(v.x, v.y, v.z, zoneRadius), nil, "edit",
            false, function()
                local radiusInput = VFW.Nui.KeyboardInput(true, "Nouveau radius de la zone",
                    tostring(math.floor(zoneRadius)))
                local newRadius = tonumber(radiusInput)
                if newRadius and newRadius > 0 then
                    v.radius = newRadius
                    createJobTaxi.refresh()
                end
            end)
        createJobTaxi.Button("Supprimer zone #" .. k, "", nil, "trash",
            false, function()
                table.remove(jobInCreation.custom.taxiSpawnZones, k)
                createJobTaxi.refresh()
            end)
    end

    createJobTaxi.Separator("Véhicules autorisés")

    createJobTaxi.Button("+ Ajouter un véhicule", "Nom du modèle spawn (ex: dlrhinetaxi)", nil, "chevron", false,
        function()
            local modelName = VFW.Nui.KeyboardInput(true, "Nom du modèle véhicule (spawn name)", "")
            if not modelName or modelName == "" then return end
            if not jobInCreation.custom.allowedVehicles then
                jobInCreation.custom.allowedVehicles = {}
            end
            jobInCreation.custom.allowedVehicles[#jobInCreation.custom.allowedVehicles + 1] = modelName
            createJobTaxi.refresh()
        end)

    for k, v in pairs(jobInCreation.custom.allowedVehicles or {}) do
        createJobTaxi.Button(v, "Véhicule autorisé #" .. k, nil, "trash",
            false, function()
                table.remove(jobInCreation.custom.allowedVehicles, k)
                createJobTaxi.refresh()
            end)
    end
end)

modifyJobTaxi.OnOpen(function()
    if not jobInModification.custom.enabledBaseZones then
        jobInModification.custom.enabledBaseZones = {}
    end

    modifyJobTaxi.Separator("Zones de base")
    for _, zone in ipairs(TaxiJob.Config.BaseZones or {}) do
        modifyJobTaxi.Checkbox(
            zone.label, zone.desc, false,
            jobInModification.custom.enabledBaseZones[zone.key] or false,
            function(checked)
                jobInModification.custom.enabledBaseZones[zone.key] = checked
                modifyJobTaxi.refresh()
            end
        )
    end

    modifyJobTaxi.Separator("Zones custom")
    modifyJobTaxi.Button("Ajouter une zone de spawn PNJ à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        local radiusInput = VFW.Nui.KeyboardInput(true, "Radius de la zone (défaut: 500)", "500")
        local radius = tonumber(radiusInput) or 500.0
        if radius <= 0 then radius = 500.0 end
        if not jobInModification.custom.taxiSpawnZones then
            jobInModification.custom.taxiSpawnZones = {}
        end

        jobInModification.custom.taxiSpawnZones[#jobInModification.custom.taxiSpawnZones + 1] = {
            x = pos.x,
            y = pos.y,
            z =
                pos.z,
            radius = radius
        }
        modifyJobTaxi.refresh()
    end)

    modifyJobTaxi.Separator("Zones de spawn PNJ")

    for k, v in pairs(jobInModification.custom.taxiSpawnZones or {}) do
        local zoneRadius = v.radius or 500.0
        modifyJobTaxi.Button("Zone #" .. k,
            ("x: %.2f, y: %.2f, z: %.2f | Radius: %.0fm"):format(v.x, v.y, v.z, zoneRadius), nil, "edit",
            false, function()
                local radiusInput = VFW.Nui.KeyboardInput(true, "Nouveau radius de la zone",
                    tostring(math.floor(zoneRadius)))
                local newRadius = tonumber(radiusInput)
                if newRadius and newRadius > 0 then
                    v.radius = newRadius
                    modifyJobTaxi.refresh()
                end
            end)
        modifyJobTaxi.Button("Supprimer zone #" .. k, "", nil, "trash",
            false, function()
                table.remove(jobInModification.custom.taxiSpawnZones, k)
                modifyJobTaxi.refresh()
            end)
    end

    modifyJobTaxi.Separator("Véhicules autorisés")

    modifyJobTaxi.Button("+ Ajouter un véhicule", "Nom du modèle spawn (ex: dlrhinetaxi)", nil, "chevron", false,
        function()
            local modelName = VFW.Nui.KeyboardInput(true, "Nom du modèle véhicule (spawn name)", "")
            if not modelName or modelName == "" then return end
            if not jobInModification.custom.allowedVehicles then
                jobInModification.custom.allowedVehicles = {}
            end
            jobInModification.custom.allowedVehicles[#jobInModification.custom.allowedVehicles + 1] = modelName
            modifyJobTaxi.refresh()
        end)

    for k, v in pairs(jobInModification.custom.allowedVehicles or {}) do
        modifyJobTaxi.Button(v, "Véhicule autorisé #" .. k, nil, "trash",
            false, function()
                table.remove(jobInModification.custom.allowedVehicles, k)
                modifyJobTaxi.refresh()
            end)
    end
end)

-- ==================== POINTS DE RÉCOLTE (BARS) ====================

createJobCraft.OnOpen(function()
    createJobCraft.Button("Ajouter un point de récolte à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        if not jobInCreation.custom.harvestPoints then
            jobInCreation.custom.harvestPoints = {}
        end

        jobInCreation.custom.harvestPoints[#jobInCreation.custom.harvestPoints + 1] = { x = pos.x, y = pos.y, z = pos.z }
        createJobCraft.refresh()
    end)

    createJobCraft.Separator("Points de récolte")

    for k, v in pairs(jobInCreation.custom.harvestPoints or {}) do
        createJobCraft.Button("Point #" .. k, ("x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z), nil, "trash",
            false, function()
                table.remove(jobInCreation.custom.harvestPoints, k)
                createJobCraft.refresh()
            end)
    end
end)

modifyJobCraft.OnOpen(function()
    modifyJobCraft.Button("Ajouter un point de récolte à ma position", "", nil, "chevron", false, function()
        local pos <const> = GetEntityCoords(PlayerPedId())
        if not jobInModification.custom.harvestPoints then
            jobInModification.custom.harvestPoints = {}
        end

        jobInModification.custom.harvestPoints[#jobInModification.custom.harvestPoints + 1] = {
            x = pos.x,
            y = pos.y,
            z =
                pos.z
        }
        modifyJobCraft.refresh()
    end)

    modifyJobCraft.Separator("Points de récolte")

    for k, v in pairs(jobInModification.custom.harvestPoints or {}) do
        modifyJobCraft.Button("Point #" .. k, ("x: %.2f, y: %.2f, z: %.2f"):format(v.x, v.y, v.z), nil, "trash",
            false, function()
                table.remove(jobInModification.custom.harvestPoints, k)
                modifyJobCraft.refresh()
            end)
    end
end)

