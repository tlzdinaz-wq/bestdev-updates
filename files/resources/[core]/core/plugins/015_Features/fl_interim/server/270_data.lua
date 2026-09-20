Feat27 = Feat27 or {}

Interim = Interim or {}
InterimServer = InterimServer or {}

InterimServer.Positions = {}
InterimServer.Configs = {}
InterimServer.Vehicles = {}
InterimServer.SpotLocks = {}

local function cdn(path)
    if VFW and VFW.CDN and VFW.CDN.Get then
        local ok, url = pcall(VFW.CDN.Get, path)
        if ok and type(url) == "string" and url ~= "" then return url end
    end
    if VFW and VFW.CdnUrl then
        local ok, url = pcall(VFW.CdnUrl, path)
        if ok and type(url) == "string" and url ~= "" then return url end
    end
    if BRANDING and type(BRANDING.cdnBase) == "string" and BRANDING.cdnBase ~= "" then
        return ("%s/%s"):format(BRANDING.cdnBase, path)
    end
    return ""
end

InterimServer.Cdn = cdn

local DEFAULT_POSITIONS = {
    lumberjack = {
        startplace = { x = -547.31, y = 5334.14, z = 73.62 },
        startplacenpc = { x = -549.62, y = 5336.18, z = 73.62 },
        startplace_npcheading = 118.0,
        startplace_radius = 3.0,
        returnPoint = { x = -547.31, y = 5334.14, z = 73.62 },
        returnPoint_radius = 4.0,
        truckSpots = {
            { x = -536.09, y = 5325.15, z = 73.24, w = 174.0 },
            { x = -531.06, y = 5327.05, z = 73.24, w = 174.0 },
            { x = -525.87, y = 5329.31, z = 73.24, w = 174.0 },
            { x = -520.62, y = 5331.46, z = 73.24, w = 174.0 },
        },
        woodSpots = {
            { coords = { x = -589.31, y = 5391.26, z = 69.87 }, radius = 2.0 },
            { coords = { x = -612.75, y = 5410.92, z = 66.28 }, radius = 2.0 },
            { coords = { x = -641.19, y = 5395.71, z = 66.15 }, radius = 2.0 },
            { coords = { x = -570.44, y = 5427.13, z = 68.51 }, radius = 2.0 },
        },
        processSpots = {
            { coords = { x = -516.05, y = 5296.32, z = 79.71 }, radius = 2.0 },
            { coords = { x = -510.81, y = 5290.44, z = 79.71 }, radius = 2.0 },
        },
        buyer = {
            pedBuyer = "s_m_y_construct_01",
            buyerLocation = { x = -481.54, y = 5372.51, z = 78.02 },
            buyerHeading = 258.0,
        },
    },
    mineur = {
        startplace = { x = 2952.06, y = 2779.34, z = 42.31 },
        startplacenpc = { x = 2954.20, y = 2781.05, z = 42.31 },
        startplace_npcheading = 235.0,
        startplace_radius = 3.0,
        returnPoint = { x = 2952.06, y = 2779.34, z = 42.31 },
        returnPoint_radius = 4.0,
        truckSpots = {
            { x = 2942.29, y = 2769.10, z = 42.05, w = 96.0 },
            { x = 2942.63, y = 2764.34, z = 41.92, w = 96.0 },
            { x = 2943.02, y = 2759.55, z = 41.79, w = 96.0 },
            { x = 2943.41, y = 2754.71, z = 41.65, w = 96.0 },
        },
        mineSpots = {
            spot_1 = { x = 2932.31, y = 2795.15, z = 40.62, radius = 2.0 },
            spot_2 = { x = 2913.44, y = 2799.63, z = 41.35, radius = 2.0 },
            spot_3 = { x = 2896.72, y = 2781.20, z = 40.11, radius = 2.0 },
            spot_4 = { x = 2884.05, y = 2809.44, z = 40.90, radius = 2.0 },
            spot_5 = { x = 2967.11, y = 2790.35, z = 41.72, radius = 2.0 },
        },
        cleanArea = { x = 2350.71, y = 3128.06, z = 47.21, radius = 60.0 },
        buyer = {
            model = "s_m_y_dockwork_01",
            x = 2870.13, y = 2795.05, z = 40.72, heading = 175.0,
        },
    },
    pizza = {
        startplace = { x = 804.53, y = -759.54, z = 26.79 },
        startplacenpc = { x = 806.31, y = -757.82, z = 26.79 },
        startplace_npcheading = 180.0,
        startplace_radius = 2.5,
        pickuppoint = { x = 801.42, y = -762.11, z = 26.79 },
        pickuppoint_radius = 1.75,
        returnpoint = { x = 812.65, y = -768.09, z = 26.17 },
        returnpoint_radius = 3.0,
        scooterSpots = {
            { x = 812.65, y = -768.09, z = 26.17, w = 268.0 },
            { x = 812.90, y = -772.15, z = 26.17, w = 268.0 },
            { x = 813.15, y = -776.20, z = 26.17, w = 268.0 },
        },
        deliveryPoints = {
            { x = 265.14, y = -1163.85, z = 29.29, w = 92.0 },
            { x = 337.61, y = -1000.42, z = 29.42, w = 175.0 },
            { x = 168.24, y = -1006.53, z = 29.34, w = 340.0 },
            { x = 917.24, y = -1067.31, z = 34.10, w = 268.0 },
            { x = 1153.75, y = -1526.44, z = 34.85, w = 300.0 },
            { x = -47.52, y = -585.71, z = 37.03, w = 340.0 },
            { x = -262.87, y = -968.28, z = 31.22, w = 210.0 },
            { x = 439.71, y = -804.62, z = 29.13, w = 178.0 },
            { x = -598.14, y = -1049.35, z = 22.34, w = 90.0 },
            { x = 121.35, y = -1298.06, z = 29.27, w = 122.0 },
        },
    },
    routier = {
        startplace = { x = 1204.94, y = -3115.42, z = 5.54 },
        startplace_radius = 3.5,
        returnPoint = { x = 1198.30, y = -3103.16, z = 5.54 },
        returnTruckPoint = { x = 1176.21, y = -3103.60, z = 5.54 },
        returnPoint_radius = 5.0,
        returnpoint_radius = 5.0,
        truckSpots = {
            { x = 1222.09, y = -3117.55, z = 5.54, w = 90.0 },
            { x = 1222.41, y = -3126.13, z = 5.54, w = 90.0 },
            { x = 1222.74, y = -3134.72, z = 5.54, w = 90.0 },
        },
        trailerSpots = {
            { x = 1240.35, y = -3117.42, z = 5.54, w = 90.0 },
            { x = 1240.68, y = -3126.01, z = 5.54, w = 90.0 },
            { x = 1241.02, y = -3134.60, z = 5.54, w = 90.0 },
        },
        deliveryPoints = {
            { x = 152.19, y = 6398.55, z = 31.36, radius = 10.0 },
            { x = 1698.75, y = 3775.14, z = 34.71, radius = 10.0 },
            { x = -84.21, y = 6416.30, z = 31.49, radius = 10.0 },
            { x = 2680.44, y = 3517.06, z = 52.71, radius = 10.0 },
            { x = 1211.15, y = 2661.29, z = 37.90, radius = 10.0 },
            { x = -370.28, y = -1428.72, z = 30.09, radius = 10.0 },
        },
    },
}

local DEFAULT_CONFIGS = {
    lumberjack = {
        pedService = "s_m_y_construct_02",
        vehicle = "rebel2",
        item = "rawwood",
        plank = "wooden_plank",
        maxDeposit = 5,
        planksPerLog = 2,
        processDelay = 5000,
        chopDelay = 5000,
        animDict = "amb@world_human_hammering@male@base",
        animName = "base",
        animFlag = 49,
        sellPrice = 250,
        interactionCircle = {
            color = { r = 0, g = 0, b = 255, a = 255 },
            processColor = { r = 139, g = 69, b = 19, a = 120 },
        },
    },
    mineur = {
        pedService = "s_m_y_dockwork_01",
        vehicle = "bison",
        miningDelay = 5000,
        cleaningDelay = 5000,
        animDict = "amb@world_human_hammering@male@base",
        animName = "base",
        animFlag = 49,
        interactionCircle = {
            color = { r = 255, g = 200, b = 0, a = 180 },
            processColor = { r = 120, g = 120, b = 120, a = 120 },
        },
        ores = {
            { dirty = "charcoal_dirty", clean = "charcoal", price = 150, weight = 50 },
            { dirty = "cuivre_dirty", clean = "cuivre", price = 250, weight = 35 },
            { dirty = "gold_dirty", clean = "gold", price = 350, weight = 15 },
        },
    },
    pizza = {
        main = { pedService = "a_m_m_indian_01" },
        vehicle = "faggio2",
        maxStock = 10,
        payPerDelivery = 180,
        cancelCooldown = 60000,
        possibleNPCS = {
            "a_f_y_hipster_01", "a_m_y_business_01", "a_f_m_bevhills_01",
            "a_m_m_business_01", "a_f_y_business_01", "a_m_y_vinewood_01",
        },
        PositionsPizza = {
            startplace = { x = 804.53, y = -759.54 },
        },
        interactionCircle = {
            doorColor = { r = 255, g = 140, b = 0, a = 120 },
            trunkColor = { r = 255, g = 200, b = 60, a = 120 },
        },
    },
    routier = {
        pedService = "s_m_m_dockwork_01",
        truckVehicle = "phantom",
        trailerVehicle = "trailers",
        reward = 950,
        startplacenpc = { x = 1207.11, y = -3113.36, z = 5.54 },
        startplace_npcheading = 88.0,
        interactionCircle = {
            color = { r = 0, g = 100, b = 0, a = 200 },
            deliveryColor = { r = 70, g = 130, b = 180, a = 120 },
        },
    },
}

local DEFAULT_JOBS_CENTER = {
    npcs = {
        {
            model = "s_f_y_scrubs_01",
            coords = { x = -269.19, y = -957.42, z = 31.22 },
            heading = 205.0,
            label = "Appuyez sur ~INPUT_CONTEXT~ pour consulter les offres d'intérim",
            blip = { enabled = true, sprite = 351, scale = 0.5, color = 5, name = "Centre d'intérim" },
        },
    },
}

local DEFAULT_INTERIM_JOBS = {
    { id = "lumberjack", label = "Bûcheron", order = 1, desc = "Abattez du bois, transformez-le en planches et revendez-les.",
      meta = { hours = "Libres", zone = "Paleto Bay", vehicle = "Camionnette", requirements = "Aucun" } },
    { id = "mineur", label = "Mineur", order = 2, desc = "Extrayez du minerai brut, nettoyez-le puis revendez-le.",
      meta = { hours = "Libres", zone = "Carrière de Davis", vehicle = "Camionnette", requirements = "Aucun" } },
    { id = "pizza", label = "Livreur de Pizza", order = 3, desc = "Livrez des pizzas dans tout Los Santos avec votre scooter.",
      meta = { hours = "Libres", zone = "Los Santos", vehicle = "Scooter", requirements = "Aucun" } },
    { id = "routier", label = "Routier", order = 4, desc = "Convoyez des remorques entre le port et les entrepôts de l'État.",
      meta = { hours = "Libres", zone = "Port de Los Santos", vehicle = "Semi-remorque", requirements = "Aucun" } },
}

local function decode(value, fallback)
    if VFW and VFW.DB and VFW.DB.Decode then
        return VFW.DB.Decode(value, fallback)
    end
    if type(value) == "table" then return value end
    if value == nil or value == "" then return fallback end
    local ok, res = pcall(json.decode, value)
    if ok and res ~= nil then return res end
    return fallback
end

function InterimServer.GetPositions(job)
    local data = InterimServer.Positions[job]
    if data then return data end
    return DEFAULT_POSITIONS[job]
end

function InterimServer.GetConfig(job)
    local data = InterimServer.Configs[job]
    if data then return data end
    return DEFAULT_CONFIGS[job]
end

function InterimServer.SavePositions(job, data)
    if type(job) ~= "string" or type(data) ~= "table" then return false end
    MySQL.query.await(
        "INSERT INTO interim_job_positions (`job`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)",
        { job, json.encode(data) }
    )
    InterimServer.Positions[job] = data
    return true
end

function InterimServer.SaveConfig(job, data)
    if type(job) ~= "string" or type(data) ~= "table" then return false end
    MySQL.query.await(
        "INSERT INTO interim_job_config (`job`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)",
        { job, json.encode(data) }
    )
    InterimServer.Configs[job] = data
    return true
end

local function loadStore()
    local positionRows = MySQL.query.await("SELECT `job`, `data` FROM interim_job_positions") or {}
    for i = 1, #positionRows do
        local row = positionRows[i]
        local data = decode(row.data, nil)
        if type(data) == "table" then
            InterimServer.Positions[row.job] = data
        end
    end

    for job, data in pairs(DEFAULT_POSITIONS) do
        if not InterimServer.Positions[job] then
            InterimServer.SavePositions(job, data)
        end
    end

    local configRows = MySQL.query.await("SELECT `job`, `data` FROM interim_job_config") or {}
    for i = 1, #configRows do
        local row = configRows[i]
        local data = decode(row.data, nil)
        if type(data) == "table" then
            InterimServer.Configs[row.job] = data
        end
    end

    for job, data in pairs(DEFAULT_CONFIGS) do
        if not InterimServer.Configs[job] then
            InterimServer.SaveConfig(job, data)
        end
    end

    local jobRows = MySQL.query.await("SELECT id FROM interim_jobs") or {}
    if #jobRows == 0 then
        for i = 1, #DEFAULT_INTERIM_JOBS do
            local entry = DEFAULT_INTERIM_JOBS[i]
            MySQL.query.await(
                "INSERT IGNORE INTO interim_jobs (`id`, `label`, `image`, `description`, `meta`, `sort_order`, `enabled`) VALUES (?, ?, ?, ?, ?, ?, 1)",
                { entry.id, entry.label, ("interim/%s.png"):format(entry.id), entry.desc, json.encode(entry.meta or {}), entry.order }
            )
        end
    end

    local centerRows = MySQL.query.await("SELECT id FROM interim_jobs_center") or {}
    if #centerRows == 0 then
        for i = 1, #DEFAULT_JOBS_CENTER.npcs do
            local npc = DEFAULT_JOBS_CENTER.npcs[i]
            MySQL.query.await([[
                INSERT INTO interim_jobs_center (`model`, `x`, `y`, `z`, `heading`, `label`, `blip_enabled`, `blip_sprite`, `blip_scale`, `blip_color`, `blip_name`)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                npc.model, npc.coords.x, npc.coords.y, npc.coords.z, npc.heading, npc.label,
                npc.blip.enabled and 1 or 0, npc.blip.sprite, npc.blip.scale, npc.blip.color, npc.blip.name,
            })
        end
    end
end

function InterimServer.BuildClientConfig()
    local rows = MySQL.query.await("SELECT * FROM interim_jobs WHERE `enabled` = 1 ORDER BY `sort_order` ASC, `id` ASC") or {}

    local jobs = {}
    local order = {}
    local indexToJob = {}

    for i = 1, #rows do
        local row = rows[i]
        local image = row.image or ""
        if image ~= "" and not image:match("^https?://") and not image:match("^nui://") then
            local resolved = cdn(image)
            if resolved ~= "" then image = resolved end
        end
        jobs[row.id] = {
            label = row.label or row.id,
            image = image,
            desc = row.description or "",
            meta = decode(row.meta, {}),
        }
        order[#order + 1] = row.id
        indexToJob[tostring(i + 1)] = row.id
    end

    return {
        jobs = jobs,
        order = order,
        indexToJob = indexToJob,
        ui = {
            menus = {
                main = { title = "CENTRE D'INTÉRIM", banner = "interim" },
                choose = { title = "CHOISIR UN MÉTIER D'INTÉRIM", banner = "interim" },
            },
        },
    }
end

function InterimServer.BuildJobsCenterConfig()
    local rows = MySQL.query.await("SELECT * FROM interim_jobs_center") or {}
    local npcs = {}
    for i = 1, #rows do
        local row = rows[i]
        npcs[#npcs + 1] = {
            model = row.model,
            coords = { x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0 },
            heading = (row.heading or 0.0) + 0.0,
            label = row.label or "Appuyez sur ~INPUT_CONTEXT~ pour parler",
            blip = {
                enabled = row.blip_enabled == 1,
                sprite = row.blip_sprite or 351,
                scale = (row.blip_scale or 0.5) + 0.0,
                color = row.blip_color or 5,
                name = row.blip_name or "Centre d'intérim",
            },
        }
    end
    return { npcs = npcs }
end

function InterimServer.GetInterimJob(xPlayer)
    if not xPlayer then return nil end
    local job = xPlayer.getMeta("interimJob")
    if type(job) == "string" and job ~= "" then return job end
    return nil
end

function InterimServer.SetInterimJob(xPlayer, jobId)
    if not xPlayer then return end
    xPlayer.setMeta("interimJob", jobId or "")
end

function InterimServer.IsUnemployed(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    return xPlayer.job.name == "unemployed"
end

function InterimServer.HasJob(xPlayer, jobId)
    if not InterimServer.IsUnemployed(xPlayer) then return false end
    return InterimServer.GetInterimJob(xPlayer) == jobId
end

function InterimServer.Vehicle(source)
    local bag = InterimServer.Vehicles[source]
    if not bag then
        bag = {}
        InterimServer.Vehicles[source] = bag
    end
    return bag
end

function InterimServer.LockSpot(job, index, source)
    InterimServer.SpotLocks[job] = InterimServer.SpotLocks[job] or {}
    local locks = InterimServer.SpotLocks[job]
    if locks[index] and locks[index] ~= source then return false end
    locks[index] = source
    return true
end

function InterimServer.ReleaseSpots(job, source)
    local locks = InterimServer.SpotLocks[job]
    if not locks then return end
    for index, owner in pairs(locks) do
        if owner == source then locks[index] = nil end
    end
end

function InterimServer.ReleaseAll(source)
    for job in pairs(InterimServer.SpotLocks) do
        InterimServer.ReleaseSpots(job, source)
    end

    local bag = InterimServer.Vehicles[source]
    if bag then
        for _, value in pairs(bag) do
            if type(value) == "number" then
                Feat27.DeleteNet(value)
            elseif type(value) == "table" then
                for _, netId in pairs(value) do
                    if type(netId) == "number" then Feat27.DeleteNet(netId) end
                end
            end
        end
    end
    InterimServer.Vehicles[source] = nil
end

function InterimServer.Notify(source, notifType, message)
    TriggerClientEvent("interim:jobs:notification", source, {
        type = notifType or "JAUNE",
        subtitle = "Intérim",
        content = message,
    })
end

function InterimServer.SendFirstWaypoint(source, job)
    local positions = InterimServer.GetPositions(job)
    if not positions or not positions.startplace then return end
    TriggerClientEvent("interim:firstwp:set", source,
        positions.startplace.x + 0.0, positions.startplace.y + 0.0, os.time())
end

RegisterNetEvent("interim:requestConfig", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:cfg", 1000) then return end
    TriggerClientEvent("interim:receiveConfig", source, InterimServer.BuildClientConfig())
end)

RegisterNetEvent("interim:requestJobsCenterConfig", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:centerCfg", 1000) then return end
    TriggerClientEvent("interim:receiveJobsCenterConfig", source, InterimServer.BuildJobsCenterConfig())
end)

RegisterServerCallback("interim:getJobCenterConfig", function(source)
    return InterimServer.BuildJobsCenterConfig()
end)

RegisterNetEvent("interimjobscenter:requestData", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:centerData", 800) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local config = InterimServer.BuildClientConfig()
    local jobs = {}
    for _, id in ipairs(config.order) do
        local entry = config.jobs[id]
        jobs[#jobs + 1] = {
            id = id,
            label = entry.label,
            image = entry.image,
            description = entry.desc,
            meta = entry.meta,
        }
    end

    TriggerClientEvent("nui:interimjobscenter:open", source, {
        jobs = jobs,
        currentJob = InterimServer.GetInterimJob(xPlayer),
        playerName = xPlayer.name or xPlayer.playerName,
    })
end)

RegisterNetEvent("interimjobscenter:markLocation", function(data)
    local source = source
    if type(data) ~= "table" then return end
    if not Feat27.RateLimit(source, "interim:mark", 500) then return end

    local jobId = data.id or data.jobId or data.job
    if type(jobId) ~= "string" then return end

    local positions = InterimServer.GetPositions(jobId)
    if not positions or not positions.startplace then return end

    TriggerClientEvent("interim:firstwp:set", source,
        positions.startplace.x + 0.0, positions.startplace.y + 0.0, os.time())
end)

RegisterNetEvent("interim:firstwp:request", function()
    local source = source
    if not Feat27.RateLimit(source, "interim:wp", 500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local job = InterimServer.GetInterimJob(xPlayer)
    if not job then return end

    InterimServer.SendFirstWaypoint(source, job)
end)

AddEventHandler("vfw:playerDropped", function(source)
    InterimServer.ReleaseAll(source)
end)

CreateThread(function()
    while not VFW or not VFW.Ready do Wait(200) end
    local ok, err = pcall(loadStore)
    if not ok then
        console.warn(("fl_interim: initialisation impossible (%s)"):format(tostring(err)))
        return
    end
    console.init("fl_interim", "Configuration des métiers d'intérim chargée")
end)
