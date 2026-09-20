local BUILDER_PERM = "builder_drug_pipeline"

local PRESETS = {
    { id = "ramasser_sol", label = "Ramasser au sol" },
    { id = "recolter_plante", label = "Récolter plante" },
    { id = "melanger", label = "Mélanger" },
    { id = "emballer", label = "Emballer" },
    { id = "couper", label = "Couper" },
    { id = "presser_cocaine", label = "Presser/Transformer" },
    { id = "cuisiner", label = "Cuisiner" },
}

local HARVEST_INSERT = [[
    INSERT INTO illegal_harvest_spots
        (name, coords_x, coords_y, coords_z, rotation_z, marker_x, marker_y, marker_z, prop_model,
         item_output, output_quantity, harvest_time, cooldown_seconds, animation_type, animation_dict,
         animation_name, animation_preset, animation_prop, blip_enabled, blip_sprite, blip_color,
         blip_scale, blip_label, faction_restriction, faction_grade_min)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]]

local HARVEST_UPDATE = [[
    UPDATE illegal_harvest_spots SET
        name = ?, coords_x = ?, coords_y = ?, coords_z = ?, rotation_z = ?, marker_x = ?, marker_y = ?, marker_z = ?,
        prop_model = ?, item_output = ?, output_quantity = ?, harvest_time = ?, cooldown_seconds = ?,
        animation_type = ?, animation_dict = ?, animation_name = ?, animation_preset = ?, animation_prop = ?,
        blip_enabled = ?, blip_sprite = ?, blip_color = ?, blip_scale = ?, blip_label = ?,
        faction_restriction = ?, faction_grade_min = ?
    WHERE id = ?
]]

local TRANSFORM_INSERT = [[
    INSERT INTO illegal_transform_spots
        (name, coords_x, coords_y, coords_z, rotation_z, marker_x, marker_y, marker_z, prop_model,
         input_item, input_quantity, output_item, output_quantity, transform_time, cooldown_seconds,
         animation_type, animation_dict, animation_name, animation_preset, animation_prop,
         blip_enabled, blip_sprite, blip_color, blip_scale, blip_label, faction_restriction, faction_grade_min)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]]

local TRANSFORM_UPDATE = [[
    UPDATE illegal_transform_spots SET
        name = ?, coords_x = ?, coords_y = ?, coords_z = ?, rotation_z = ?, marker_x = ?, marker_y = ?, marker_z = ?,
        prop_model = ?, input_item = ?, input_quantity = ?, output_item = ?, output_quantity = ?, transform_time = ?,
        cooldown_seconds = ?, animation_type = ?, animation_dict = ?, animation_name = ?, animation_preset = ?,
        animation_prop = ?, blip_enabled = ?, blip_sprite = ?, blip_color = ?, blip_scale = ?, blip_label = ?,
        faction_restriction = ?, faction_grade_min = ?
    WHERE id = ?
]]

local function staffOk(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission(BUILDER_PERM)
        or xPlayer.hasPermission("illegal_activities_builder")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function fail(message)
    return { success = false, ok = false, error = message or "Action impossible." }
end

local function DurationMs(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    if n > 0 and n < 200 then return math.floor(n * 1000) end
    return math.max(0, math.floor(n))
end

local function CleanItem(value)
    local name = IL.Str(value, "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return name:sub(1, 64)
end

local function ReadVec(data)
    if type(data) ~= "table" then return nil end
    local src = type(data.coords) == "table" and data.coords or data
    if src.x == nil and src.coords_x == nil then return nil end
    return {
        x = IL.Num(src.x or src.coords_x, 0.0),
        y = IL.Num(src.y or src.coords_y, 0.0),
        z = IL.Num(src.z or src.coords_z, 0.0),
        w = IL.Num(src.heading or src.w or src.rotationZ or src.rotation_z, 0.0),
    }
end

local function ItemsCatalog()
    local out = {}
    for name, def in pairs(VFW.Items or {}) do
        if type(name) == "string" and name ~= "" then
            out[#out + 1] = {
                name = name,
                label = (type(def) == "table" and (def.label or name)) or name,
            }
        end
    end
    table.sort(out, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return out
end

local function FactionsCatalog()
    local rows = IL.Query([[
        SELECT name, label FROM crews
        WHERE name NOT IN ('nocrew', 'nofaction')
        ORDER BY label ASC
    ]])
    local out = {}
    for i = 1, #rows do
        local name = tostring(rows[i].name or "")
        if name ~= "" then
            out[#out + 1] = { name = name, label = tostring(rows[i].label or name) }
        end
    end
    return out
end

local function HarvestRows()
    return IL.Query("SELECT * FROM illegal_harvest_spots ORDER BY id")
end

local function TransformRows()
    return IL.Query("SELECT * FROM illegal_transform_spots ORDER BY id")
end

local function PriceRows()
    local rows = IL.Query("SELECT * FROM drugdealing_prices ORDER BY item_name")
    for i = 1, #rows do
        rows[i].label = IL.ItemLabel(rows[i].item_name)
        rows[i].deal_active = true
    end
    return rows
end

local function HubPanel()
    return {
        ok = true,
        success = true,
        harvest = HarvestRows(),
        transform = TransformRows(),
        prices = PriceRows(),
        items = ItemsCatalog(),
        factions = FactionsCatalog(),
        presets = PRESETS,
    }
end

local function ReloadSpots()
    TriggerEvent("illegal:internal:reloadSpots")
end

local function HarvestParams(data, itemFallback, nameFallback)
    local coords = ReadVec(data)
    if not coords then return nil, "Définissez la position." end
    local item = CleanItem(data.itemOutput or data.item_output or data.item or itemFallback)
    if not item then return nil, "Item récolté obligatoire." end
    local name = IL.Str(data.name, nameFallback or ("Récolte " .. item))
    local qty = math.max(1, IL.Int(data.outputQuantity or data.output_quantity or data.maxQty or data.max_quantity, 1))
    local faction = IL.Str(data.factionRestriction or data.faction_restriction or data.faction, "")
    if faction == "none" then faction = "" end
    return {
        name, coords.x, coords.y, coords.z, coords.w,
        coords.x, coords.y, coords.z, CleanItem(data.propModel or data.prop_model),
        item, qty, DurationMs(data.harvestTime or data.harvest_time or data.time, 5000),
        math.max(0, IL.Int(data.cooldown_seconds or data.cooldown, 0)),
        IL.Str(data.animationType or data.animation_type or data.animType, "predefined"),
        IL.Str(data.animationDict or data.animation_dict or data.animDict, nil),
        IL.Str(data.animationName or data.animation_name or data.animName, nil),
        IL.Str(data.animationPreset or data.animation_preset or data.animPreset, "recolter_plante"),
        IL.Str(data.animationProp or data.animation_prop or data.animProp, nil),
        IL.Bool(data.blipEnabled or data.blip_enabled) and 1 or 0,
        IL.Int(data.blipSprite or data.blip_sprite, 1),
        IL.Int(data.blipColor or data.blip_color, 1),
        IL.Num(data.blipScale or data.blip_scale, 0.8),
        IL.Str(data.blipLabel or data.blip_label, name),
        faction, math.max(0, IL.Int(data.factionGradeMin or data.faction_grade_min or data.factionGrade, 0)),
    }, nil, item
end

local function TransformParams(data, inputFallback, outputFallback, nameFallback)
    local coords = ReadVec(data)
    if not coords then return nil, "Définissez la position." end
    local input = CleanItem(data.inputItem or data.input_item or inputFallback)
    local output = CleanItem(data.outputItem or data.output_item or outputFallback)
    if not input then return nil, "Item d'entrée obligatoire." end
    if not output then return nil, "Item de sortie obligatoire." end
    local name = IL.Str(data.name, nameFallback or ("Transfo " .. output))
    local faction = IL.Str(data.factionRestriction or data.faction_restriction or data.faction, "")
    if faction == "none" then faction = "" end
    return {
        name, coords.x, coords.y, coords.z, coords.w,
        coords.x, coords.y, coords.z, CleanItem(data.propModel or data.prop_model),
        input, math.max(1, IL.Int(data.inputQuantity or data.input_quantity or data.inputQty, 1)),
        output, math.max(1, IL.Int(data.outputQuantity or data.output_quantity or data.outputQty, 1)),
        DurationMs(data.transformTime or data.transform_time or data.time, 5000),
        math.max(0, IL.Int(data.cooldown_seconds or data.cooldown, 0)),
        IL.Str(data.animationType or data.animation_type or data.animType, "predefined"),
        IL.Str(data.animationDict or data.animation_dict or data.animDict, nil),
        IL.Str(data.animationName or data.animation_name or data.animName, nil),
        IL.Str(data.animationPreset or data.animation_preset or data.animPreset, "melanger"),
        IL.Str(data.animationProp or data.animation_prop or data.animProp, nil),
        IL.Bool(data.blipEnabled or data.blip_enabled) and 1 or 0,
        IL.Int(data.blipSprite or data.blip_sprite, 1),
        IL.Int(data.blipColor or data.blip_color, 1),
        IL.Num(data.blipScale or data.blip_scale, 0.8),
        IL.Str(data.blipLabel or data.blip_label, name),
        faction, math.max(0, IL.Int(data.factionGradeMin or data.faction_grade_min or data.factionGrade, 0)),
    }
end

local function UpsertPrice(itemName, minP, maxP, active)
    itemName = CleanItem(itemName)
    if not itemName then return nil, "Item drogue obligatoire." end
    if active == false then
        IL.Execute("DELETE FROM drugdealing_prices WHERE item_name = ?", { itemName })
        TriggerEvent("illegal:internal:reloadDrugPrices")
        return true
    end
    minP = math.max(0, IL.Int(minP, 100))
    maxP = math.max(minP, IL.Int(maxP, 200))
    IL.Execute([[
        INSERT INTO drugdealing_prices (item_name, min_price, max_price)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE min_price = VALUES(min_price), max_price = VALUES(max_price)
    ]], { itemName, minP, maxP })
    TriggerEvent("illegal:internal:reloadDrugPrices")
    return true
end

local function CreateHarvest(data, itemFallback, nameFallback)
    local params, err = HarvestParams(data, itemFallback, nameFallback)
    if not params then return nil, err end
    local id = IL.Insert(HARVEST_INSERT, params)
    if not id then return nil, "Création impossible." end
    ReloadSpots()
    return id
end

local function UpdateHarvest(id, data)
    local params, err = HarvestParams(data)
    if not params then return nil, err end
    params[#params + 1] = id
    IL.Execute(HARVEST_UPDATE, params)
    ReloadSpots()
    return id
end

local function CreateTransform(data, inputFallback, outputFallback, nameFallback)
    local params, err = TransformParams(data, inputFallback, outputFallback, nameFallback)
    if not params then return nil, err end
    local id = IL.Insert(TRANSFORM_INSERT, params)
    if not id then return nil, "Création impossible." end
    ReloadSpots()
    return id
end

local function UpdateTransform(id, data)
    local params, err = TransformParams(data)
    if not params then return nil, err end
    params[#params + 1] = id
    IL.Execute(TRANSFORM_UPDATE, params)
    ReloadSpots()
    return id
end

local function PipelinesList()
    local prices = PriceRows()
    local harvest = HarvestRows()
    local transform = TransformRows()
    local out = {}
    for i = 1, #prices do
        local drug = prices[i].item_name
        local harvestCount, transformCount = 0, 0
        local rawItem = nil
        for t = 1, #transform do
            if transform[t].output_item == drug then
                transformCount = transformCount + 1
                rawItem = rawItem or transform[t].input_item
            end
        end
        for h = 1, #harvest do
            if harvest[h].item_output == rawItem or harvest[h].item_output == drug then
                harvestCount = harvestCount + 1
            end
        end
        out[#out + 1] = {
            id = prices[i].id,
            name = prices[i].label or drug,
            drug_item = drug,
            drug_item_label = prices[i].label,
            raw_item = rawItem,
            deal_price_min = prices[i].min_price,
            deal_price_max = prices[i].max_price,
            deal_active = 1,
            harvest_count = harvestCount,
            transform_count = transformCount,
        }
    end
    return out
end

IL.RegisterCallback("drugBuilder:checkItemExists", function(source, name)
    if not staffOk(source) then return false end
    name = CleanItem(name)
    return name ~= nil and VFW.Items ~= nil and VFW.Items[name] ~= nil
end)

IL.RegisterCallback("drugBuilder:getDrugPipelines", function(source)
    if not staffOk(source) then return {} end
    return PipelinesList()
end)

IL.RegisterCallback("drugBuilder:getPipelineDetails", function(source, id)
    if not staffOk(source) then return nil end
    local row = IL.Single("SELECT * FROM drugdealing_prices WHERE id = ?", { IL.Int(id, 0) })
    if not row then return nil end
    local drug = row.item_name
    local transforms = IL.Query("SELECT * FROM illegal_transform_spots WHERE output_item = ? ORDER BY id", { drug })
    local raws = {}
    for i = 1, #transforms do
        raws[transforms[i].input_item] = true
    end
    local harvest = {}
    local allHarvest = HarvestRows()
    for i = 1, #allHarvest do
        if allHarvest[i].item_output == drug or raws[allHarvest[i].item_output] then
            harvest[#harvest + 1] = allHarvest[i]
        end
    end
    return {
        pipeline = row,
        harvest = harvest,
        transform = transforms,
    }
end)

IL.RegisterCallback("drugBuilder:createDrug", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) ~= "table" then return fail("Données invalides.") end
    local drug = CleanItem(data.drugItem or data.drug_item)
    local raw = CleanItem(data.rawItem or data.raw_item)
    if not drug then return fail("Item drogue obligatoire.") end
    local active = data.dealActive
    if active == nil then active = true end
    if IL.Bool(active) or active == 1 then
        UpsertPrice(drug, data.dealPriceMin, data.dealPriceMax, true)
    end
    local name = IL.Str(data.name, IL.ItemLabel(drug))
    if type(data.harvestSpots) == "table" and raw then
        for i = 1, #data.harvestSpots do
            CreateHarvest(data.harvestSpots[i], raw, name .. " récolte")
        end
    end
    if type(data.transformSpots) == "table" and raw then
        for i = 1, #data.transformSpots do
            CreateTransform(data.transformSpots[i], raw, drug, name .. " transfo")
        end
    end
    ReloadSpots()
    local panel = HubPanel()
    panel.success = true
    return panel
end)

IL.RegisterCallback("drugBuilder:updateDrug", function(source, id, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    data = type(id) == "table" and id or data
    if type(data) ~= "table" then return fail("Données invalides.") end
    local drug = CleanItem(data.drugItem or data.drug_item)
    if not drug then return fail("Item drogue obligatoire.") end
    local active = data.dealActive
    if active == 0 then active = false end
    UpsertPrice(drug, data.dealPriceMin, data.dealPriceMax, active ~= false)
    local panel = HubPanel()
    panel.success = true
    return panel
end)

IL.RegisterCallback("drugBuilder:deleteDrug", function(source, id)
    if not staffOk(source) then return fail("Permission refusée.") end
    local priceId = IL.Int(type(id) == "table" and id.id or id, nil)
    if priceId then
        IL.Execute("DELETE FROM drugdealing_prices WHERE id = ?", { priceId })
        TriggerEvent("illegal:internal:reloadDrugPrices")
    end
    local panel = HubPanel()
    panel.success = true
    return panel
end)

IL.RegisterCallback("gestionDrugPipeline:hubPanel", function(source)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les pipelines drogue." }
    end
    return HubPanel()
end)

IL.RegisterCallback("gestionDrugPipeline:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) ~= "table" then return fail("Données invalides.") end
    local action = tostring(data.action or "")
    local err, id

    if action == "price:save" then
        local active = data.deal_active
        if active == nil then active = true end
        id, err = UpsertPrice(data.item_name or data.drug_item, data.min_price, data.max_price, active ~= false)
        if not id then return fail(err) end
    elseif action == "price:delete" then
        if data.id then
            IL.Execute("DELETE FROM drugdealing_prices WHERE id = ?", { IL.Int(data.id, 0) })
        else
            IL.Execute("DELETE FROM drugdealing_prices WHERE item_name = ?", { CleanItem(data.item_name) })
        end
        TriggerEvent("illegal:internal:reloadDrugPrices")
    elseif action == "harvest:create" then
        id, err = CreateHarvest(data, data.item_output, data.name)
        if not id then return fail(err) end
    elseif action == "harvest:update" then
        id, err = UpdateHarvest(IL.Int(data.id, nil), data)
        if not id then return fail(err) end
    elseif action == "harvest:delete" then
        IL.Execute("DELETE FROM illegal_harvest_spots WHERE id = ?", { IL.Int(data.id, 0) })
        ReloadSpots()
    elseif action == "transform:create" then
        id, err = CreateTransform(data, data.input_item, data.output_item, data.name)
        if not id then return fail(err) end
    elseif action == "transform:update" then
        id, err = UpdateTransform(IL.Int(data.id, nil), data)
        if not id then return fail(err) end
    elseif action == "transform:delete" then
        IL.Execute("DELETE FROM illegal_transform_spots WHERE id = ?", { IL.Int(data.id, 0) })
        ReloadSpots()
    else
        return fail("Action inconnue.")
    end

    local panel = HubPanel()
    panel.success = true
    return panel
end)
