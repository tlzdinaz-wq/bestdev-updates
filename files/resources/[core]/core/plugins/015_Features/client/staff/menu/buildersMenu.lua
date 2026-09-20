-- Journalist Selection Menu
function StaffMenu.BuildJournalisteSelectMenu()
    StaffMenu.journalisteSelect.Button(":monitor: LIFEINVADER", "Gérer les annonces LifeInvader", nil, "chevron", false, function()
        StaffMenu.ResetlifeinvaderCreateData()
    end, StaffMenu.lifeinvaderManage)

    StaffMenu.journalisteSelect.Button(":document: WEAZEL NEWS", "Gérer les annonces Weazel News", nil, "chevron", false, function()
        StaffMenu.ResetWeazelCreateData()
    end, StaffMenu.weazelManage)
end

-- Builders search state
StaffMenu.builderQuery = StaffMenu.builderQuery or nil

function StaffMenu.ResetBuilderSearchState()
    StaffMenu.builderQuery = nil
end

-- Shared noop callback (single allocation, reused for all submenu buttons)
local noop = function() end

-- Builder entries definition (data-driven)
-- Fields: label, desc, submenu (string key), perm (optional), onClick (optional), openFn (optional)
-- Separator entries: { separator = "text" }
local builderEntries = {
    -- CONSTRUCTION & PROPS
    { separator = ":building: CONSTRUCTION & PROPS" },
    { label = ":building: PROPS", desc = "Gérer les props du serveur", submenu = "builderProps", perm = "props_builder" },
    { label = ":sparkles: FREEZE OBJETS", desc = "Figer des props par modèle ou par position", submenu = "builderObjectFreeze", perm = "freeze_objects" },
    { label = ":box: CHAISES ASSISES", desc = "Configurer animations et Z des chaises", submenu = "builderChairs", perm = "manage_chairs" },
    { label = ":users: SPAWN PNJ", desc = "Lignes de spawn PNJ sur les trottoirs, utilisées par les vendeurs de drogue notamment", submenu = "builderPNJ", perm = "pnj_builder" },

    -- BÂTIMENTS & ACCÈS
    { separator = ":building: BÂTIMENTS & ACCÈS" },
    { label = ":building: ASCENSEURS", desc = "Gérer les ascenseurs, les étages et les accès", submenu = "builder_elevators", perm = "builder_elevator" },
    { label = ":compass: TÉLÉPORTATIONS", desc = "Créer des points de téléportation (entrée/sortie, instance)", submenu = "builderTeleport", perm = "teleport_builder" },
    { label = ":lock: DOORLOCK", desc = "Gérer les doorlock", submenu = "builderDoorlock", perm = "doorlock_builder" },
    { label = ":shield: ZONES SAFE", desc = "Créer et gérer les zones safe (builder)", submenu = "builderZoneSafe", perm = "zonesafe_builder" },
    { label = ":briefcase: VESTIAIRES", desc = "Gérer les vestiaires", submenu = "builderLocker", perm = "manage_lockers" },
    { label = ":box: COFFRE", desc = "Gérer les coffres de stockage", submenu = "builderChest", perm = "chest_builder" },
    { label = ":document: DÉPÔTS", desc = "Créer des points de dépôt (consultation police par job)", submenu = "builderDeposit", perm = "staff_menu" },
    { label = ":folder: CASIERS SOCIÉTÉ", desc = "Créer et gérer les casiers de société", submenu = "builderSocietyLocker", perm = "manage_society_lockers" },
    { label = ":building: GESTION BÂTIMENTS", desc = "Gérer les bâtiments du serveur", submenu = "batiment", perm = "perm_batiment" },

    -- IMMOBILIER
    { separator = ":home: IMMOBILIER" },
    { label = ":home: GESTION DYNASTY", desc = "Configurer les prix de vente et location des biens", submenu = "builderDynastyPrices", perm = "manage_dynasty_prices" },
    { label = ":building: MOTELS", desc = "Créer et gérer les motels", submenu = "builderMotel", perm = "motel_builder" },
    { label = ":trash: PROPRIÉTÉS SUPPRIMÉES", desc = "Restaurer ou supprimer définitivement", submenu = "builderDeletedProps", perm = "manage_deleted_properties" },
    { label = ":report: LOGS PROPRIÉTÉS", desc = "Consulter l'historique d'activite des proprietes", submenu = "builderPropertyLogs", perm = "view_property_logs" },

    -- VÉHICULES & TRANSPORT
    { separator = ":car: VÉHICULES & TRANSPORT" },
    { label = ":building: CRÉATION DE GARAGE", desc = "Créer et gérer les garages", submenu = "createGarage", perm = "manage_garages" },
    { label = ":car: SPAWNPOINTS GARAGE", desc = "Placement des points de spawn des garages", perm = "manage_garages", onClick = function()
        if StaffMenu.OpenGarageSpawnPointsBuilder then
            StaffMenu.OpenGarageSpawnPointsBuilder()
        end
    end },
    { label = ":building: CRÉATION DE GARAGE SOCIÉTÉ", desc = "Créer et gérer les garages", submenu = "createGarageSociety", perm = "manage_garages" },
    { label = ":building: GARAGE MÉTIER AVEC RESTRICTION", desc = "Créer et gérer les garages métier avec limitation par grade", submenu = "builderPoliceGarage", perm = "manage_garages" },
    { label = ":car: CRÉATION DE FOURRIÈRE", desc = "Créer et gérer les fourrières", submenu = "createPound", perm = "manage_pounds" },
    { label = ":car: LOCATION DE VÉHICULES", desc = "Gérer les locations de véhicules", submenu = "builderCarRental", perm = "manage_vehicleRental" },
    { label = ":building: GESTION CONCESSIONNAIRE", desc = "Gérer les catégories et véhicules des concessionnaires", submenu = "builderConcess", perm = "manage_concess" },
    { label = ":car: VENTE VÉHICULES", desc = "Configurer le système de vente entre joueurs", submenu = "builderVehicleSell", perm = "builder_vehicle_sell" },
    { label = ":car: STOCKAGE VEHICULES", desc = "Configurer coffre et boîte à gants par véhicule", submenu = "builderVehicleStorage", perm = "manage_trunk" },
    { label = ":tag: LABELS VÉHICULES", desc = "Renommer les véhicules globalement (tous garages)", submenu = "vehicleLabelOverrides", perm = "manage_garages" },
    { label = ":wrench: PRIX CUSTOM", desc = "Configurer les prix des modifications véhicules", submenu = "builderCustomPrices", perm = "manage_custom_prices" },
    { label = ":wrench: EXTRA VÉHICULE", desc = "Points de tuning gratuit temporaire par job", submenu = "builderVehicleTuning", perm = "vehicle_tuning_builder" },
    { label = ":car: GESTION TAXI", desc = "Gérer les zones de spawn et paramètres taxi", submenu = "builderTaxi", perm = "builder_taxi" },

    -- ARMES & COMBAT
    { separator = ":gun: ARMES & COMBAT" },
    { label = ":gun: ARMURERIES", desc = "Créer et gérer les armureries", submenu = "builderGunshops", perm = "builder_ammunition" },
    { label = ":gun: ARMURERIES JOB", desc = "Armureries avec limites de stock par job/grade", submenu = "builderJobArmory", perm = "builder_job_armory" },
    { label = ":gun: ARMES DANS LE DOS", desc = "Choisir quelles armes peuvent être portées dans le dos", submenu = "builderWeaponBack", perm = "builder_weapon_back" },
    { label = " DEGATS DES ARMES", desc = "Configurer balles pour tuer, KO melee, headshot", submenu = "builderWeaponDamage", perm = "builder_weapon_damage" },
    { label = ":gun: CREVER LES PNEUS", desc = "Choisir quelles armes peuvent crever les pneus", submenu = "builderTireSlash", perm = "builder_tire_slash" },
    { label = ":gun: PRISE D'OTAGE", desc = "Choisir quelles armes permettent de prendre en otage", submenu = "builderHostageWeapons", perm = "builder_hostage_weapons" },
    { label = ":car: DRIVE-BY", desc = "Configurer les armes autorisées en drive-by", submenu = "builderDriveby", perm = "builder_driveby" },
    { label = ":target: AIRSOFT", desc = "Configurer les billes pour tomber par arme airsoft", submenu = "builderAirsoft", perm = "builder_airsoft" },

    -- JOBS & SOCIÉTÉS
    { separator = ":briefcase: JOBS & SOCIÉTÉS" },
    { label = ":building: CRÉATION DE SOCIÉTÉ", desc = "Créer et gérer les métiers/sociétés", perm = "manage_jobs", openFn = function()
        if SocietyBuilderMenu then SocietyBuilderMenu.open() end
    end },
    { label = ":box: ÉQUIPEMENTS JOB", desc = "Gérer les points d'équipement par job", submenu = "builderJobEquipment", perm = "builder_job_equipment" },
    { label = ":user::leaf: GESTION DES JOBS FARM", desc = "Gérer les job de farm", submenu = "builderFarm", perm = "builder_farm" },
    { label = ":money: ÉCONOMIE INTÉRIM", desc = "Gérer les gains de base des jobs intérim", submenu = "builderInterim", perm = "builder_interim_economy" },
    { label = ":building: GESTION GOUVERNEMENT", desc = "Accès staff à la tablette gouvernement", submenu = "builderGouv", perm = "builder_gouv" },
    { label = " VOTE", desc = "Créer et gérer les votes et scrutins", submenu = "builderElections", perm = "builder_elections" },

    -- RESTAURANTS & COMMERCES
    { separator = ":cart: RESTAURANTS & COMMERCES" },
    { label = ":cart: GESTION BAR & RESTAURANTS", desc = "Gérer les bars et restaurants (cartes, points, etc.)", submenu = "builderBarsMain", perm = "restaurant_builder" },
    { label = ":building: MAGASINS", desc = "Créer et gérer les magasins (vêtements, tatouages, masques)", submenu = "builderShops", perm = "manage_clothes" },
    { label = ":signal: MARKET", desc = "Créer et gérer les Markets par job", submenu = "builderMarket", perm = "builder_spacemarket" },
    { label = ":box: GESTION ITEMS LTD", desc = "Configurer les prix supérette, spacemarket et catalogue revente", submenu = "builderLTDItems", perm = "manage_ltd_items" },
    { label = ":car: STATIONS ESSENCE", desc = "Créer et gérer les stations d'essence", submenu = "gasStationMain", perm = "builder_gas_station" },
    { label = ":cart: DISTRIBUTEURS", desc = "Gérer les distributeurs automatiques", submenu = "builderVendingMachines", perm = "builder_vending" },
    { label = ":sparkles: GESTION FIREWORK", desc = "Gérer les boutiques de feux d'artifice", submenu = "builderFirework", perm = "builder_firework" },
    { label = ":cart: LIVRAISONS BURGERSHOT", desc = "Configurer les clients de livraison BurgerShot", submenu = "builderBSDelivery", perm = "restaurant_builder" },
    { label = ":cart: LIVRAISONS PIZZERIA", desc = "Configurer les clients de livraison Pizzeria", submenu = "builderPizzeriaDelivery", perm = "restaurant_builder" },
    { label = ":leaf: LIVRAISONS PEARLS", desc = "Configurer les clients de livraison Pearls", submenu = "builderPearlsDelivery", perm = "restaurant_builder" },
    { label = ":cart: LIVRAISONS NOODLE", desc = "Configurer les clients de livraison Noodle", submenu = "builderNoodleDelivery", perm = "restaurant_builder" },
    { label = ":cart: LIVRAISONS BEAN COFFEE", desc = "Configurer les clients de livraison Bean Coffee", submenu = "builderBeanCoffeeDelivery", perm = "restaurant_builder" },
    { label = ":heart: LIVRAISONS UWU CAFE", desc = "Configurer les clients de livraison UwU Cafe", submenu = "builderUwuCafeDelivery", perm = "restaurant_builder" },
    { label = ":compass: POSITIONS STATIONS RESTAURANTS", desc = "Déplacer grill, friteuse, four, table de préparation... de chaque restaurant", submenu = "builderRestaurantStations", perm = "restaurant_builder" },

    -- SANTÉ & MÉDICAL
    { separator = ":hospital: SANTÉ & MÉDICAL" },
    { label = ":hospital: GESTION SAMS", desc = "Gérer les données SAMS (annonces, rapports, factures, permissions)", submenu = "samsManagement", perm = "sams_management" },
    { label = ":flask: PHARMACIES", desc = "Créer et gérer les pharmacies", submenu = "builderPharmacy", perm = "pharmacy_builder" },
    { label = ":hospital: HÔPITAUX", desc = "Créer et gérer les hôpitaux", submenu = "builderHospital", perm = "hospital_builder" },

    -- POLICE & JUSTICE
    { separator = ":shield: POLICE & JUSTICE" },
    { label = ":scales: DOJ PERMISSIONS", desc = "Gérer les permissions du Department of Justice", submenu = "builderDOJ", perm = "manage_doj", opens = "doj" },
    { label = ":money: AMENDES POLICE", desc = "Gérer les types d'amendes et tarifs", submenu = "builderFines", perm = "builder_fines", opens = "fines" },
    { label = ":map: ZONES ALERTES POLICE", desc = "Configurer les zones d'alertes par job police", perm = "manage_police_zones", opens = "policeAlerts" },
    { label = ":music: RADIO 911", desc = "Gérer les jobs autorisés à utiliser la radio 911", submenu = "builderRadio911", perm = "builder_radio911", opens = "radio911" },
    { label = ":film: CAMÉRAS POLICE", desc = "Gérer les caméras de vidéosurveillance", submenu = "builderCameras", perm = "builder_cameras" },

    -- AMBIANCE & MÉDIAS
    { separator = ":music: AMBIANCE & MÉDIAS" },
    { label = ":music: DJ", desc = "Gérer les emplacements DJ", submenu = "builderDJ", perm = "builder_platine" },
    { label = ":megaphone: SONS D'AMBIANCES", desc = "Créer et gérer les zones de sons d'ambiance", submenu = "builderAmbientSound", perm = "ambient_sound_builder" },
    { label = ":bell: RESTRICTION VOCALE", desc = "Zones ou certains modes de voix sont interdits", submenu = "builderVoiceRestriction", perm = "voice_restriction_builder" },
    { label = ":music: STUDIOS D'ENREGISTREMENT", desc = "Créer et gérer les studios d'enregistrement", submenu = "builderStudio", perm = "builder_studio" },
    { label = ":monitor: TELEVISION", desc = "Gérer les modèles TV (ptelevision)", submenu = "builderTelevision", perm = "builder_television" },
    { label = ":map: BLIPS", desc = "Gérer les blips de la carte", submenu = "builderBlips", perm = "manage_blips" },
    { label = ":document: GESTION JOURNALISTE", desc = "Gérer les annonces LifeInvader et Weazel", submenu = "journalisteSelect", perm = "builder_journaliste" },

    -- CRAFT & ACTIVITÉS
    { separator = ":building: CRAFT & ACTIVITÉS" },
    { label = ":building: STATIONS DE CRAFT", desc = "Stations de craft avec restriction job", submenu = "builderLegal", perm = "builder_legal_craft" },
    { label = ":leaf: ACTIVITÉS LÉGALES", desc = "Positions vendeurs et prix (pêche, chasse, plongée)", submenu = "builderLegalActivities", perm = "legal_activities_builder" },
    { label = ":gamepad: TICKETS À GRATTER", desc = "Configurer les probabilités de gain", submenu = "builderScratchCard", perm = "builder_scratch_card" },

    -- BRAQUAGES
    { separator = ":money: CATÉGORIE BRAQUAGES" },
    { label = ":money: ATM", desc = "Gestion des braquages ATM", submenu = "builderATM", perm = "builder_atm" },
    { label = ":building: SUPERETTE", desc = "Gestion des supérettes (braquages)", submenu = "builderSupermarket", perm = "builder_supermarket", opens = "supermarket" },
    { label = ":building: BANQUES FLEECA", desc = "Gestion des banques Fleeca", submenu = "builderFleeca", perm = "builder_fleeca" },
    { label = ":building: BANQUES PACIFIC", desc = "Gestion des banques Pacific", submenu = "builderPacific", perm = "builder_pacific" },
    { label = ":diamond: BIJOUTERIE", desc = "Gestion de la bijouterie", submenu = "builderJewelry", perm = "builder_jewelry" },
    { label = ":home: CAMBRIOLAGES", desc = "Système de cambriolage de maisons", submenu = "builderBurglary", perm = "builder_burglary" },

    -- LABORATOIRES
    { separator = ":flask: LABORATOIRES" },
    { label = ":flask: LABORATOIRES", desc = "Gerer les laboratoires de faction", submenu = "builderLabo", perm = "labo_builder" },

    -- ILLÉGAL
    { separator = ":dot-red: CATÉGORIE ILLÉGAL" },
    { label = ":car: GO FAST", desc = "Système de go fast", submenu = "builderGoFast", perm = "builder_gofast", opens = "gofast" },
    { label = ":flask: DROGUES (PIPELINE)", desc = "Créer et gérer les drogues (récolte, transformation, vente)", submenu = "builderDrug", perm = "builder_drug_pipeline", opens = "drugPipeline" },
    { label = ":flask: VENTE DE DROGUE", desc = "Gestion des zones de vente", submenu = "builderDrugDealing", perm = "builder_drug_dealing", opens = "drugDealing" },
    { label = " BLACK MARKET", desc = "Marché noir", submenu = "builderBlackmarket", perm = "builder_blackmarket", opens = "blackmarket" },
    { label = ":money: BLANCHIMENT", desc = "Système de blanchiment", submenu = "builderWhitening", perm = "builder_whitening", opens = "whitening" },
    { label = ":leaf: ILLEGAL (CRAFT)", desc = "Stations et recettes de craft illégal", submenu = "builderIllegal", perm = "illegal_activities_builder", opens = "illegalCraft" },
    { label = ":flask: POCHON SHOP", desc = "Configurer la boutique de pochons vides", submenu = "builderPochonShop", perm = "pochon_shop_builder", opens = "pochonShop" },

    -- FACTIONS
    { separator = ":flag: FACTIONS" },
    { label = ":flag: GESTION FACTIONS", desc = "Créer et gérer les factions/gangs", submenu = "factionMenu", perm = "gestion_faction", opens = "factions" },
    { label = ":building: CRÉATION DE GARAGE FACTION", desc = "Créer et gérer les garages de faction", submenu = "createGarageFaction", perm = "gestion_faction", opens = "factionGarages" },
    { label = ":wrench: GARAGE ILLÉGAL (PLAQUES)", desc = "Points de changement de plaque pour les factions illégales", submenu = "createGarageIllegal", perm = "gestion_faction", opens = "illegalGarages" },
    { label = ":map: TERRITOIRES FACTIONS", desc = "Zones de contrôle des factions", submenu = "builderFactionTerritories", perm = "gestion_territoires", opens = "territories" },
    { label = ":gun: KING OF THE HILL", desc = "Configurer les zones et horaires KOTH", submenu = "builderKoth", perm = "builder_koth", opens = "koth" },

    -- ZOMBIE
    { separator = ":skull: ZOMBIE" },
    { label = ":skull: ZONES ZOMBIE", desc = "Creer et gerer les zones de spawn zombie", submenu = "builderZombie", perm = "builder_zombie" },

    -- BOUTIQUE
    { separator = ":money: BOUTIQUE", perm = "boutique" },
    { label = ":cart: BOUTIQUE PAYANTE", desc = "Administration des items et Coins", submenu = "builderPaidShop", perm = "boutique", opens = "paidshop" },
    { label = ":star: GESTION VIP", desc = "Gérer les véhicules du mois VIP", submenu = "builderVIP", perm = "boutique", opens = "vip" },
    { label = ":gift: BOUTIQUE AFK", desc = "Gérer les caisses et lots de la boutique AFK", submenu = "builderAFKShop", perm = "boutique", opens = "afk" },
}

-- Exposé pour le hub de gestion NUI (gestion_hub.lua) : séparateurs = catégories, boutons = outils
StaffMenu.builderEntries = builderEntries

-- Pre-compute lowercase for search + set onClick fallback (all done once at load)
local sfind = string.find
local slower = string.lower
local entryCount = #builderEntries

for i = 1, entryCount do
    local e = builderEntries[i]
    if e.label then
        e._ll = slower(e.label)
        e._ld = slower(e.desc)
        e._cb = e.onClick or noop
    end
end

-- Resolve submenu references (lazy, first open only)
local _resolved = false
local function resolveRefs()
    for i = 1, entryCount do
        local e = builderEntries[i]
        if e.submenu and not e._ref then
            e._ref = StaffMenu[e.submenu]
        end
    end
    _resolved = true
end

-- Builders Menu
function StaffMenu.BuildBuildersMenu()
    resolveRefs()
    StaffMenu.builders.ClearItems()

    local query = StaffMenu.builderQuery
    local Button = StaffMenu.builders.Button
    local Separator = StaffMenu.builders.Separator

    Button(query and "RECHERCHER:" or "RECHERCHER", query or "UN BUILDER", nil, "search", false, function()
        if query then
            StaffMenu.builderQuery = nil
            StaffMenu.builders.refresh()
            return
        end
        StaffMenu.builderQuery = VFW.Nui.KeyboardInput(true, "Rechercher un builder...")
        if StaffMenu.builderQuery == nil or StaffMenu.builderQuery == "" then
            StaffMenu.builderQuery = nil
            return
        end
        StaffMenu.builders.refresh()
    end)

    local lq = query and slower(query) or nil
    local perms = VFW.StaffPerms()

    -- Defer separator rendering until we know at least one button under it is visible
    local pendingSeparator = nil

    for i = 1, entryCount do
        local e = builderEntries[i]
        if e.separator then
            if not lq and (not e.perm or perms[e.perm]) then
                pendingSeparator = e.separator
            else
                pendingSeparator = nil
            end
        elseif not lq or sfind(e._ll, lq, 1, true) or sfind(e._ld, lq, 1, true) then
            if not e.perm or perms[e.perm] or (e.altPerm and perms[e.altPerm]) then
                if pendingSeparator then
                    Separator(pendingSeparator)
                    pendingSeparator = nil
                end
                Button(e.label, e.desc, nil, "chevron", false, e._cb, e._ref)
            end
        end
    end
end

function StaffMenu.BuildBatimentMenu()
    StaffMenu.batiment.ClearItems()

    StaffMenu.batiment.Separator(":building: GESTION BÂTIMENTS")

    StaffMenu.batiment.Button(" ÉGLISES", "Gérer les styles des églises (Los Santos / Paleto / Sandy)", nil, "chevron", false, function()
    end, StaffMenu.batimentEglises)

    StaffMenu.batiment.Button(":building: MAZE BANK ARENA", "Changer le type d'événement de l'arène", nil, "chevron", false, function()
    end, StaffMenu.batimentMBA)
end

function StaffMenu.BuildEglisesMenu()
    local VUI <const> = exports["VUI"]
    local adminBanner <const> = exports["core"]:GetVUIBanner("admin")

    StaffMenu.batimentEglises.ClearItems()

    local churchStyles = {
        { key = "n_church", name = "Classique" },
        { key = "m_church", name = "Mariage" },
        { key = "f_church", name = "Funéraire" },
        { key = "d_church", name = "Délabré" }
    }

    local ChurchLS = VUI:CreateSubMenu(StaffMenu.batimentEglises, "ÉGLISE LOS SANTOS", adminBanner, true)
    ChurchLS.OnOpen(function()
        ChurchLS.ClearItems()
        ChurchLS.Separator("ÉGLISE LOS SANTOS - Styles")
        for _, s in ipairs(churchStyles) do
            ChurchLS.Button(s.name, "Appliquer le style : "..s.name, nil, "chevron", false, function()
                TriggerServerEvent("Church1:ChangeEntitySet", s.key)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Église', message = 'Style appliqué : ' .. s.name })
            end)
        end
    end)

    local ChurchPaleto = VUI:CreateSubMenu(StaffMenu.batimentEglises, "ÉGLISE PALETO", adminBanner, true)
    ChurchPaleto.OnOpen(function()
        ChurchPaleto.ClearItems()
        ChurchPaleto.Separator("ÉGLISE PALETO - Styles")
        for _, s in ipairs(churchStyles) do
            ChurchPaleto.Button(s.name, "Appliquer le style : "..s.name, nil, "chevron", false, function()
                TriggerServerEvent("Church2:ChangeEntitySet", s.key)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Église', message = 'Style appliqué : ' .. s.name })
            end)
        end
    end)

    local ChurchSandy = VUI:CreateSubMenu(StaffMenu.batimentEglises, "ÉGLISE SANDY SHORES", adminBanner, true)
    ChurchSandy.OnOpen(function()
        ChurchSandy.ClearItems()
        ChurchSandy.Separator("ÉGLISE SANDY SHORES - Styles")
        for _, s in ipairs(churchStyles) do
            ChurchSandy.Button(s.name, "Appliquer le style : "..s.name, nil, "chevron", false, function()
                TriggerServerEvent("Church3:ChangeEntitySet", s.key)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Église', message = 'Style appliqué : ' .. s.name })
            end)
        end
    end)

    StaffMenu.batimentEglises.Separator(" ÉGLISES")
    StaffMenu.batimentEglises.Button(" LOS SANTOS", "Gérer les styles de Los Santos", nil, "chevron", false, function() end, ChurchLS)
    StaffMenu.batimentEglises.Button(" PALETO BAY", "Gérer les styles de Paleto", nil, "chevron", false, function() end, ChurchPaleto)
    StaffMenu.batimentEglises.Button(" SANDY SHORES", "Gérer les styles de Sandy Shores", nil, "chevron", false, function() end, ChurchSandy)
end

local mbaTypes = {
    { separator = ":target: SPORTS" },
    { key = "BASKETBALL",   label = ":target: Basketball" },
    { key = "FOOTBALL",     label = ":target: Football" },
    { key = "ICEHOCKEY",    label = ":target: Hockey sur Glace" },
    { key = "CURLING",      label = ":target: Curling" },
    { key = "PAINTBALL",    label = ":target: Paintball" },
    { separator = ":target: COMBAT" },
    { key = "BOXING",       label = ":target: Boxe" },
    { key = "MMA",          label = ":shield: MMA" },
    { key = "WRESTLING",    label = ":shield: Wrestling" },
    { separator = ":music: SPECTACLES" },
    { key = "CONCERT",      label = ":music: Concert" },
    { key = "FAMEorSHAME",  label = ":star: Fame or Shame" },
    { key = "FASHION",      label = ":user: Défilé de Mode" },
    { separator = ":car: COURSES" },
    { key = "DERBY",        label = ":car: Derby" },
    { key = "GOKARTA",      label = ":flag: Go-Kart (Circuit A)" },
    { key = "GOKARTB",      label = ":flag: Go-Kart (Circuit B)" },
    { key = "ROCKETLEAGUE", label = ":rocket: Rocket League" },
    { key = "TRACKMANIAA",  label = " Trackmania (Piste 1)" },
    { key = "TRACKMANIAB",  label = " Trackmania (Piste 2)" },
    { key = "TRACKMANIAC",  label = " Trackmania (Piste 3)" },
    { key = "TRACKMANIAD",  label = " Trackmania (Piste 4)" },
    { separator = ":settings: AUTRE" },
    { key = "EMPTY",        label = ":building: Vide (par défaut)" },
}

function StaffMenu.BuildMBAMenu()
    StaffMenu.batimentMBA.ClearItems()
    StaffMenu.batimentMBA.Separator(":building: MAZE BANK ARENA")

    for _, entry in ipairs(mbaTypes) do
        if entry.separator then
            StaffMenu.batimentMBA.Separator(entry.separator)
        else
            StaffMenu.batimentMBA.Button(entry.label, "Appliquer : " .. entry.label, nil, nil, false, function()
                TriggerServerEvent("MBA:ChangeEntitySet", entry.key)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Maze Bank Arena', message = 'Type appliqué : ' .. entry.label })
            end)
        end
    end
end

-- Register the builders menu
-- Items cached after first build; only rebuilt when search query or permissions change
local _buildersCachedQuery = false -- false = never built
local _buildersCacheValid = false

-- Invalidate cache when permissions are updated
AddEventHandler('vfw:updatePlayerGlobalData', function()
    _buildersCacheValid = false
end)

StaffMenu.builders.OnOpen(function()
    local query = StaffMenu.builderQuery
    if _buildersCachedQuery ~= query or not _buildersCacheValid then
        StaffMenu.BuildBuildersMenu()
        _buildersCachedQuery = query
        _buildersCacheValid = true
    end
end)

StaffMenu.batiment.OnOpen(function()
    StaffMenu.BuildBatimentMenu()
end)

StaffMenu.batimentEglises.OnOpen(function()
    StaffMenu.BuildEglisesMenu()
end)

StaffMenu.batimentMBA.OnOpen(function()
    StaffMenu.BuildMBAMenu()
end)
