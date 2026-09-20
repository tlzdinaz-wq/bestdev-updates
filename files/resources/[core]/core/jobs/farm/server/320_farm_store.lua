VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Farm = VFW.Farm or {}

local JC = VFW.JobsCommon
local Farm = VFW.Farm

Farm.Definitions = {
    asgard = {
        isBar = true,
        pedModel = "a_m_y_business_02",
        harvestItem = "barley",
        harvestAction = "harvest",
        processKey = "process",
        processThreshold = 3,
        recipes = { barley = { output = "biere_asgard", cost = 3 } },
        sellItems = { "biere_asgard" },
        defaultHarvest = { { x = 2599.07, y = 4433.61, z = 39.33 } },
        defaultProcessing = { { x = 939.74, y = -2173.66, z = 29.53 } },
        argOrder = "action_first",
    },
    billard = {
        isBar = true,
        pedModel = "a_m_y_business_02",
        harvestItem = "barley",
        processKey = "process",
        processThreshold = 3,
        recipes = { barley = { output = "biere_billard", cost = 3 } },
        sellItems = { "biere_billard" },
        defaultHarvest = { { x = 2599.07, y = 4433.61, z = 39.33 } },
        defaultProcessing = { { x = 939.74, y = -2173.66, z = 29.53 } },
        argOrder = "action_first",
    },
    henhouse = {
        isBar = true,
        pedModel = "a_m_y_business_02",
        harvestItem = "barley",
        processKey = "process",
        processThreshold = 3,
        recipes = { barley = { output = "biere_henhouse", cost = 3 } },
        sellItems = { "biere_henhouse" },
        defaultHarvest = { { x = 2599.07, y = 4433.61, z = 39.33 } },
        defaultProcessing = { { x = 939.74, y = -2173.66, z = 29.53 } },
        argOrder = "action_first",
    },
    irishpub = {
        isBar = true,
        pedModel = "a_m_y_business_02",
        harvestItem = "barley",
        processKey = "process",
        processThreshold = 3,
        recipes = { barley = { output = "biere_irishpub", cost = 3 } },
        sellItems = { "biere_irishpub" },
        defaultHarvest = { { x = 2599.07, y = 4433.61, z = 39.33 } },
        defaultProcessing = { { x = 939.74, y = -2173.66, z = 29.53 } },
        argOrder = "action_first",
    },
    unicorn = {
        isBar = true,
        pedModel = "a_m_y_business_02",
        harvestItem = "barley",
        processKey = "process",
        processThreshold = 3,
        recipes = { barley = { output = "biere_unicorn", cost = 3 } },
        sellItems = { "biere_unicorn" },
        defaultHarvest = { { x = 2599.07, y = 4433.61, z = 39.33 } },
        defaultProcessing = { { x = 942.19, y = -2161.63, z = 30.19 } },
        argOrder = "action_first",
    },
    yellowjack = {
        isBar = true,
        pedModel = "a_m_y_business_02",
        harvestItem = "barley",
        processKey = "process",
        processThreshold = 3,
        recipes = { barley = { output = "biere_yellowjack", cost = 3 } },
        sellItems = { "biere_yellowjack" },
        defaultHarvest = { { x = 2599.07, y = 4433.61, z = 39.33 } },
        defaultProcessing = { { x = 939.74, y = -2173.66, z = 29.53 } },
        argOrder = "action_first",
    },
    cayo_lagoon = {
        isBar = true,
        pedModel = "a_m_y_beachvesp_01",
        harvestItem = "pineapple",
        processKey = "process",
        processThreshold = 3,
        recipes = { pineapple = { output = "cocktail_cayo_lagoon", cost = 3 } },
        sellItems = { "cocktail_cayo_lagoon" },
        defaultHarvest = { { x = 5206.92, y = -5172.37, z = 11.86 } },
        defaultProcessing = { { x = 5064.44, y = -4590.38, z = 2.86 } },
        argOrder = "action_first",
    },
    cayofarm = {
        isBar = false,
        pedModel = "a_m_y_beach_01",
        harvestItem = "mango",
        processKey = "process",
        processThreshold = 5,
        recipes = { mango = { output = "juice_mango", cost = 5 } },
        sellItems = { "juice_mango" },
        defaultHarvest = {
            { x = 5343.12, y = -5193.8, z = 30.21 },
            { x = 5353.34, y = -5183.25, z = 28.57 },
            { x = 5360.31, y = -5175.88, z = 28.56 },
            { x = 5337.07, y = -5180.37, z = 29.38 },
            { x = 5345.14, y = -5170.92, z = 28.18 },
            { x = 5355.96, y = -5158.75, z = 27.73 },
            { x = 5339.15, y = -5148.18, z = 24.72 },
            { x = 5319.89, y = -5172.08, z = 27.89 },
        },
        defaultProcessing = { { x = 5330.02, y = -5272.0, z = 32.19 } },
        argOrder = "index_first",
    },
    vigneron = {
        isBar = false,
        pedModel = "a_m_y_business_02",
        harvestItem = nil,
        harvestPool = { "white_grapes", "red_grapes", "yellow_grapes" },
        processKey = "process",
        processThreshold = 5,
        recipes = {
            white_grapes = { output = "wine_white", cost = 5 },
            red_grapes = { output = "wine_red", cost = 5 },
            yellow_grapes = { output = "wine_yellow", cost = 5 },
        },
        sellItems = { "wine_white", "wine_red", "wine_yellow" },
        defaultHarvest = {
            { x = -1859.4, y = 2097.59, z = 137.81 },
            { x = -1876.34, y = 2098.12, z = 138.76 },
            { x = -1881.76, y = 2098.67, z = 138.74 },
            { x = -1890.62, y = 2099.63, z = 137.82 },
            { x = -1900.81, y = 2100.2, z = 135.71 },
            { x = -1903.96, y = 2100.99, z = 134.56 },
            { x = -1909.98, y = 2101.23, z = 132.75 },
            { x = -1850.87, y = 2101.61, z = 137.59 },
            { x = -1842.91, y = 2105.22, z = 137.54 },
            { x = -1833.54, y = 2109.36, z = 136.16 },
        },
        defaultProcessing = {
            { x = -1931.32, y = 2058.18, z = 139.77 },
            { x = -1931.92, y = 2055.43, z = 139.75 },
            { x = -1932.47, y = 2052.63, z = 139.77 },
        },
        argOrder = "index_first",
    },
    tabac = {
        isBar = false,
        pedModel = "a_m_y_business_02",
        harvestItem = "paper_tabacco",
        processKey = "process",
        processThreshold = 3,
        packagingThreshold = 5,
        transformItem = "cigarette",
        packagedItem = "cigarette_paquet",
        recipes = { paper_tabacco = { output = "cigarette", cost = 3 } },
        sellItems = { "cigarette_paquet" },
        argOrder = "index_first",
    },
    globeoil = {
        isBar = false,
        pedModel = "a_m_y_business_02",
        harvestItem = "empty_barrel",
        processKey = "processing",
        processThreshold = 1,
        recipes = { empty_barrel = { output = "petrol_barrel", cost = 1 } },
        sellItems = { "petrol_barrel" },
        defaultHarvest = {
            { x = 1230.22, y = -3014.96, z = 8.32 },
            { x = 1231.95, y = -3029.35, z = 8.36 },
            { x = 1250.63, y = -3013.56, z = 8.32 },
            { x = 1244.68, y = -3002.66, z = 8.32 },
            { x = 1245.04, y = -3039.09, z = 13.3 },
            { x = 1240.29, y = -3054.07, z = 13.3 },
            { x = 1228.4, y = -2991.38, z = 8.32 },
            { x = 1237.43, y = -2985.67, z = 8.32 },
        },
        defaultProcessing = {
            { x = 700.86, y = 2883.46, z = 49.3 },
            { x = 647.0, y = 2928.24, z = 41.01 },
            { x = 616.281189, y = 2854.168701, z = 39.850788 },
            { x = 587.461243, y = 2926.659912, z = 40.775749 },
        },
        argOrder = "index_first",
    },
    cbdshop = {
        isBar = false,
        pedModel = "a_m_y_business_02",
        harvestItem = "cbd_leaf",
        processKey = "processing",
        processThreshold = 1,
        recipes = {
            cbd_oil = { output = "cbd_oil", cost = 1, from = "cbd_leaf" },
            cannabis_flower = { output = "cannabis_flower", cost = 1, from = "cbd_leaf" },
        },
        sellItems = { "cbd_oil", "cannabis_flower" },
        defaultHarvest = { { x = 166.53, y = -242.42, z = 49.06 } },
        defaultProcessing = {
            { x = 165.23, y = -233.35, z = 49.06 },
            { x = 165.63, y = -234.94, z = 49.06 },
        },
        argOrder = "index_first",
    },
}

Farm.DefaultPrices = {
    biere_asgard = 220,
    biere_billard = 220,
    biere_henhouse = 220,
    biere_irishpub = 220,
    biere_unicorn = 220,
    biere_yellowjack = 220,
    cocktail_cayo_lagoon = 320,
    juice_mango = 260,
    wine_white = 300,
    wine_red = 320,
    wine_yellow = 300,
    cigarette_paquet = 240,
    petrol_barrel = 420,
    cbd_oil = 300,
    cannabis_flower = 260,
}

Farm.DefaultSocietyPercent = 30

Farm.DefaultAnimations = {
    harvest = { dict = "amb@world_human_gardener_plant@male@enter", name = "enter" },
    processing = { dict = "mini@repair", name = "fixing_a_player" },
    selling = { dict = "mp_common", name = "givetake1_a" },
}

local configs = {}

local function buildDefaultItems(societyName)
    local def = Farm.Definitions[societyName]
    if not def then return {} end

    local key = def.processKey or "process"
    local list = {}
    local seen = {}

    for i = 1, #(def.sellItems or {}) do
        local name = def.sellItems[i]
        if not seen[name] then
            seen[name] = true
            list[#list + 1] = {
                name = name,
                label = JC.ItemLabel(name),
                price = Farm.DefaultPrices[name] or 200,
            }
        end
    end

    return { [key] = list }
end

Farm.BuildDefaultItems = buildDefaultItems

local function normalizePoints(value)
    local decoded = JC.Decode(value, nil)
    if type(decoded) ~= "table" then return nil end

    local out = {}
    for i = 1, #decoded do
        local point = JC.Vec(decoded[i])
        if point then out[#out + 1] = point end
    end

    if #out == 0 then return nil end
    return out
end

local function normalizeAnim(value)
    local decoded = JC.Decode(value, nil)
    if type(decoded) ~= "table" then return nil end
    local dict = JC.Str(decoded.dict, 96)
    local name = JC.Str(decoded.name, 96)
    if not dict or not name then return nil end
    return { dict = dict, name = name }
end

local function normalizeItems(value, societyName)
    local decoded = JC.Decode(value, nil)
    if type(decoded) ~= "table" then return buildDefaultItems(societyName) end

    local def = Farm.Definitions[societyName]
    local key = def and def.processKey or "process"
    local source = decoded[key] or decoded.process or decoded.processing
    if type(source) ~= "table" then return buildDefaultItems(societyName) end

    local list = {}
    for i = 1, #source do
        local entry = source[i]
        if type(entry) == "table" then
            local name = JC.Str(entry.name, 60)
            if name then
                list[#list + 1] = {
                    name = name,
                    label = JC.Str(entry.label, 96) or JC.ItemLabel(name),
                    price = JC.Int(entry.price, 0) or Farm.DefaultPrices[name] or 200,
                }
            end
        end
    end

    if #list == 0 then return buildDefaultItems(societyName) end
    return { [key] = list }
end

local function normalizeRow(row)
    local societyName = row.society_name
    local def = Farm.Definitions[societyName]

    local harvest = normalizePoints(row.harvest)
    local processing = normalizePoints(row.processing_points)

    local pedCoords = JC.Decode(row.ped_coords, nil)
    if type(pedCoords) == "table" then
        local vec = JC.Vec(pedCoords)
        if vec then
            vec.heading = JC.Num(pedCoords.heading) or JC.Num(pedCoords.h) or 0.0
            pedCoords = vec
        else
            pedCoords = nil
        end
    else
        pedCoords = nil
    end

    return {
        societyName = societyName,
        is_bar = row.is_bar == 1 or row.is_bar == true,
        ped_coords = pedCoords,
        harvest = harvest or (def and JC.Copy(def.defaultHarvest)) or {},
        harvestIsDefault = harvest == nil,
        processing_points = processing or (def and JC.Copy(def.defaultProcessing)) or {},
        processingIsDefault = processing == nil,
        animations = {
            harvest = normalizeAnim(row.harvest_anim),
            processing = normalizeAnim(row.processing_anim),
            selling = normalizeAnim(row.selling_anim),
        },
        items = normalizeItems(row.items, societyName),
        society_percent = JC.Int(row.society_percent, 0, 100) or Farm.DefaultSocietyPercent,
    }
end

function Farm.Load()
    local rows = JC.Query("SELECT * FROM farm_configs")
    local next_configs = {}

    for i = 1, #rows do
        local row = rows[i]
        if type(row.society_name) == "string" then
            next_configs[row.society_name] = normalizeRow(row)
        end
    end

    for societyName, def in pairs(Farm.Definitions) do
        if not next_configs[societyName] then
            next_configs[societyName] = {
                societyName = societyName,
                is_bar = def.isBar == true,
                ped_coords = nil,
                harvest = JC.Copy(def.defaultHarvest) or {},
                harvestIsDefault = true,
                processing_points = JC.Copy(def.defaultProcessing) or {},
                processingIsDefault = true,
                animations = { harvest = nil, processing = nil, selling = nil },
                items = buildDefaultItems(societyName),
                society_percent = Farm.DefaultSocietyPercent,
            }

            JC.Exec([[
                INSERT IGNORE INTO farm_configs (society_name, is_bar, society_percent, items)
                VALUES (?, ?, ?, ?)
            ]], {
                societyName,
                def.isBar and 1 or 0,
                Farm.DefaultSocietyPercent,
                JC.Encode(buildDefaultItems(societyName)),
            })
        end
    end

    configs = next_configs
    return configs
end

function Farm.Get(societyName)
    if type(societyName) ~= "string" then return nil end
    return configs[societyName]
end

function Farm.GetAll()
    return configs
end

function Farm.HarvestPoints(societyName)
    local config = configs[societyName]
    if not config then return {} end
    return config.harvest or {}
end

function Farm.ProcessingPoints(societyName)
    local config = configs[societyName]
    if not config then return {} end
    return config.processing_points or {}
end

function Farm.Price(societyName, itemName)
    local config = configs[societyName]
    if not config or type(config.items) ~= "table" then
        return Farm.DefaultPrices[itemName] or 200
    end

    for _, list in pairs(config.items) do
        if type(list) == "table" then
            for i = 1, #list do
                if list[i].name == itemName then
                    return JC.Int(list[i].price, 0) or 0
                end
            end
        end
    end

    return Farm.DefaultPrices[itemName] or 200
end

function Farm.SocietyPercent(societyName)
    local config = configs[societyName]
    if not config then return Farm.DefaultSocietyPercent end
    return JC.Int(config.society_percent, 0, 100) or Farm.DefaultSocietyPercent
end

function Farm.Save(societyName, column, value)
    local allowed = {
        is_bar = true,
        ped_coords = true,
        harvest = true,
        processing_points = true,
        harvest_anim = true,
        processing_anim = true,
        selling_anim = true,
        items = true,
        society_percent = true,
    }
    if not allowed[column] then return false end

    JC.Exec("INSERT IGNORE INTO farm_configs (society_name) VALUES (?)", { societyName })
    JC.Exec(("UPDATE farm_configs SET `%s` = ? WHERE society_name = ?"):format(column), { value, societyName })
    return true
end

function Farm.Log(xPlayer, societyName, action, itemName, quantity, amount)
    if not xPlayer then return end
    JC.Exec([[
        INSERT INTO farm_logs (society, identifier, player_name, action, item, quantity, amount)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        societyName,
        xPlayer.identifier,
        JC.PlayerName(xPlayer),
        action,
        itemName or "",
        JC.Int(quantity, 0) or 0,
        JC.Int(amount, 0) or 0,
    })
end

function Farm.GetLogs(societyName, limit)
    if type(societyName) ~= "string" or societyName == "" then return {} end
    limit = JC.Int(limit, 1, 500) or 100

    local rows = JC.Query([[
        SELECT id, society, identifier, player_name, action, item, quantity, amount, created_at
        FROM farm_logs WHERE society = ? ORDER BY id DESC LIMIT ?
    ]], { societyName, limit })

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[i] = {
            id = row.id,
            player = row.player_name or row.identifier,
            identifier = row.identifier,
            action = row.action,
            item = row.item,
            label = JC.ItemLabel(row.item or ""),
            quantity = row.quantity,
            amount = row.amount,
            date = tostring(row.created_at or ""),
        }
    end

    return out
end

function Farm.ClearLogs(societyName)
    if type(societyName) ~= "string" or societyName == "" then return false end
    JC.Exec("DELETE FROM farm_logs WHERE society = ?", { societyName })
    return true
end

function Farm.ZonesPayload(societyName)
    local config = configs[societyName]
    if not config then return nil end

    local animations = nil
    local anims = config.animations or {}
    if anims.harvest or anims.processing or anims.selling then
        animations = {
            harvest = anims.harvest,
            processing = anims.processing,
            selling = anims.selling,
        }
    end

    return {
        harvestPoints = (not config.harvestIsDefault) and config.harvest or nil,
        processingPoints = (not config.processingIsDefault) and config.processing_points or nil,
        animations = animations,
    }
end

function Farm.PedPayload(societyName)
    local config = configs[societyName]
    if not config or not config.ped_coords then
        return { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 }
    end
    return {
        x = config.ped_coords.x,
        y = config.ped_coords.y,
        z = config.ped_coords.z,
        heading = config.ped_coords.heading or 0.0,
    }
end

function Farm.PushDecor(target)
    local dest = target or -1
    for societyName in pairs(Farm.Definitions) do
        TriggerClientEvent(("farm:%s:sellingPed"):format(societyName), dest, Farm.PedPayload(societyName))
        TriggerClientEvent(("farm:%s:syncZones"):format(societyName), dest, Farm.ZonesPayload(societyName))
    end
end

function Farm.PushSociety(societyName, target)
    if not Farm.Definitions[societyName] then return end
    local dest = target or -1
    TriggerClientEvent(("farm:%s:sellingPed"):format(societyName), dest, Farm.PedPayload(societyName))
    TriggerClientEvent(("farm:%s:syncZones"):format(societyName), dest, Farm.ZonesPayload(societyName))
end

Farm.Labels = {
    cayofarm = "Ferme de Cayo",
    vigneron = "Domaine viticole",
    tabac = "Plantation de tabac",
    globeoil = "Globe Oil",
    cbdshop = "CBD Shop",
}

if type(BarsConfig) == "table" then
    for i = 1, #BarsConfig do
        local bar = BarsConfig[i]
        if type(bar) == "table" and type(bar.jobName) == "string" then
            Farm.Labels[bar.jobName] = bar.label or bar.jobName
        end
    end
end

function Farm.Label(societyName)
    return Farm.Labels[societyName] or societyName
end

for societyName, def in pairs(Farm.Definitions) do
    JC.EnsureJob(societyName, Farm.Labels[societyName] or societyName, "farm", def.isBar and {
        { grade = 0, name = "serveur", label = "Serveur", salary = 250, is_boss = 0 },
        { grade = 1, name = "barman", label = "Barman", salary = 400, is_boss = 0 },
        { grade = 2, name = "responsable", label = "Responsable", salary = 600, is_boss = 0 },
        { grade = 3, name = "boss", label = "Patron", salary = 900, is_boss = 1 },
    } or nil)
end

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    Wait(2500)
    Farm.Load()

    local missing = {}
    for societyName, config in pairs(configs) do
        if not config.ped_coords then missing[#missing + 1] = societyName end
    end

    if #missing > 0 then
        table.sort(missing)
        console.warn(("[Farm] PNJ de vente non positionne pour : %s (menu staff > Gestion Bar > Points de bars)")
            :format(table.concat(missing, ", ")))
    end

    Farm.PushDecor(-1)
end)

AddEventHandler("vfw:playerLoaded", function(playerSource)
    local src = playerSource
    CreateThread(function()
        Wait(3000)
        if not VFW.GetPlayerFromId(src) then return end
        Farm.PushDecor(src)
    end)
end)
