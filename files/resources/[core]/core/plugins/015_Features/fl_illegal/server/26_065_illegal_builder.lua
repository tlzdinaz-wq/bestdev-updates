local BUILDER_PERM = "illegal_activities_builder"

local PRESETS = {
    { id = "ramasser_sol", label = "Ramasser au sol" },
    { id = "fouiller_sac", label = "Fouiller un sac" },
    { id = "cuisiner", label = "Cuisiner" },
    { id = "melanger", label = "Mélanger" },
    { id = "emballer", label = "Emballer" },
    { id = "couper", label = "Couper" },
    { id = "recolter_plante", label = "Récolter plante" },
    { id = "forger", label = "Forger/Réparer" },
    { id = "assembler", label = "Assembler" },
    { id = "injecter", label = "Remplir/Verser" },
    { id = "piocher", label = "Piocher/Miner" },
    { id = "scier", label = "Scier/Couper bois" },
    { id = "presser_cocaine", label = "Presser/Transformer" },
    { id = "fabriquer", label = "Fabriquer (table)" },
}

local function staffOk(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission(BUILDER_PERM)
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function fail(message)
    return { success = false, ok = false, error = message or "Action impossible." }
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

local function FactionGrades(name)
    if type(name) ~= "string" or name == "" then return {} end
    local rows = IL.Query("SELECT name, level FROM faction_grades WHERE faction_name = ? ORDER BY level DESC", { name })
    local out = {}
    for i = 1, #rows do
        out[#out + 1] = {
            name = rows[i].name,
            level = IL.Int(rows[i].level, 0),
            label = rows[i].name,
        }
    end
    return out
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

local function ReadMarker(data, fallback)
    local src = type(data) == "table" and (data.markerCoords or data.marker) or nil
    if type(src) ~= "table" or src.x == nil then
        return fallback
    end
    return {
        x = IL.Num(src.x, fallback and fallback.x or 0.0),
        y = IL.Num(src.y, fallback and fallback.y or 0.0),
        z = IL.Num(src.z, fallback and fallback.z or 0.0),
    }
end

local function DurationMs(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    if n > 0 and n < 200 then
        return math.floor(n * 1000)
    end
    return math.max(0, math.floor(n))
end

local function CleanName(value, fallback, maxLen)
    local name = IL.Str(value, fallback or "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return fallback end
    return name:sub(1, maxLen or 100)
end

local function CleanItem(value)
    local name = IL.Str(value, "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return name:sub(1, 64)
end

local function CleanFaction(value)
    local name = IL.Str(value, "")
    if name == "" or name == "none" then return "" end
    return name:sub(1, 60)
end

local function EncodeIngredients(raw)
    local out = {}
    if type(raw) ~= "table" then return out end
    for i = 1, #raw do
        local entry = raw[i]
        if type(entry) == "table" then
            local name = CleanItem(entry.item or entry.name)
            local count = math.max(1, IL.Int(entry.count or entry.amount or entry.quantity, 1))
            if name then
                out[#out + 1] = { item = name, count = count, name = name, amount = count }
            end
        end
    end
    return out
end

local function ArrayFromMap(map)
    local out = {}
    if type(map) ~= "table" then return out end
    for _, row in pairs(map) do
        out[#out + 1] = row
    end
    table.sort(out, function(a, b) return (tonumber(a.id) or 0) < (tonumber(b.id) or 0) end)
    return out
end

local function HarvestRows()
    return IL.Query("SELECT * FROM illegal_harvest_spots ORDER BY id")
end

local function TransformRows()
    return IL.Query("SELECT * FROM illegal_transform_spots ORDER BY id")
end

local function StationRows()
    return IL.Query("SELECT * FROM illegal_craft_stations ORDER BY id")
end

local function RecipeRows()
    local rows = IL.Query("SELECT * FROM illegal_craft_recipes ORDER BY station_id, slot_index, id")
    for i = 1, #rows do
        rows[i].ingredients = IL.Decode(rows[i].ingredients, {})
        rows[i].name = rows[i].recipe_name
    end
    return rows
end

local function RecipesMap()
    local out = {}
    local rows = RecipeRows()
    for i = 1, #rows do
        out[rows[i].id] = rows[i]
    end
    return out
end

local function HubPanel()
    return {
        ok = true,
        success = true,
        harvest = HarvestRows(),
        stations = StationRows(),
        recipes = RecipeRows(),
        transform = TransformRows(),
        items = ItemsCatalog(),
        factions = FactionsCatalog(),
        presets = PRESETS,
    }
end

local function HarvestPayload(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local coords = ReadVec(data)
    if not coords then return nil, "Définissez la position." end
    local name = CleanName(data.name, nil, 100)
    local item = CleanItem(data.itemOutput or data.item_output)
    if not name then return nil, "Nom obligatoire." end
    if not item then return nil, "Item récolté obligatoire." end
    local marker = ReadMarker(data, coords)
    local outputQty = IL.Int(data.outputQuantity or data.output_quantity or data.maxQuantity or data.max_quantity, 1)
    return {
        name = name,
        coords = coords,
        marker = marker,
        prop = CleanItem(data.propModel or data.prop_model),
        item = item,
        output = math.max(1, outputQty),
        harvestTime = DurationMs(data.harvestTime or data.harvest_time, 5000),
        cooldown = math.max(0, IL.Int(data.cooldown_seconds or data.cooldown, 0)),
        animationType = IL.Str(data.animationType or data.animation_type, "predefined"),
        animationPreset = IL.Str(data.animationPreset or data.animation_preset, nil),
        animationDict = IL.Str(data.animationDict or data.animation_dict, nil),
        animationName = IL.Str(data.animationName or data.animation_name, nil),
        animationProp = IL.Str(data.animationProp or data.animation_prop, nil),
        blipEnabled = IL.Bool(data.blipEnabled or data.blip_enabled),
        blipSprite = IL.Int(data.blipSprite or data.blip_sprite, 1),
        blipColor = IL.Int(data.blipColor or data.blip_color, 1),
        blipScale = IL.Num(data.blipScale or data.blip_scale, 0.8),
        blipLabel = CleanName(data.blipLabel or data.blip_label, name, 100),
        faction = CleanFaction(data.factionRestriction or data.faction_restriction),
        grade = math.max(0, IL.Int(data.factionGradeMin or data.faction_grade_min, 0)),
    }
end

local function TransformPayload(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local coords = ReadVec(data)
    if not coords then return nil, "Définissez la position." end
    local name = CleanName(data.name, nil, 100)
    local output = CleanItem(data.outputItem or data.output_item)
    local input = CleanItem(data.inputItem or data.input_item)
    if not input and type(data.inputs) == "table" and data.inputs[1] then
        input = CleanItem(data.inputs[1].item or data.inputs[1].name)
        data.inputQuantity = data.inputQuantity or data.inputs[1].amount or data.inputs[1].count
    end
    if not name then return nil, "Nom obligatoire." end
    if not input then return nil, "Item d'entrée obligatoire." end
    if not output then return nil, "Item de sortie obligatoire." end
    local marker = ReadMarker(data, coords)
    return {
        name = name,
        coords = coords,
        marker = marker,
        prop = CleanItem(data.propModel or data.prop_model),
        input = input,
        inputQty = math.max(1, IL.Int(data.inputQuantity or data.input_quantity, 1)),
        output = output,
        outputQty = math.max(1, IL.Int(data.outputQuantity or data.output_quantity, 1)),
        transformTime = DurationMs(data.transformTime or data.transform_time, 5000),
        cooldown = math.max(0, IL.Int(data.cooldown_seconds or data.cooldown, 0)),
        animationType = IL.Str(data.animationType or data.animation_type, "predefined"),
        animationPreset = IL.Str(data.animationPreset or data.animation_preset, nil),
        animationDict = IL.Str(data.animationDict or data.animation_dict, nil),
        animationName = IL.Str(data.animationName or data.animation_name, nil),
        animationProp = IL.Str(data.animationProp or data.animation_prop, nil),
        blipEnabled = IL.Bool(data.blipEnabled or data.blip_enabled),
        blipSprite = IL.Int(data.blipSprite or data.blip_sprite, 1),
        blipColor = IL.Int(data.blipColor or data.blip_color, 1),
        blipScale = IL.Num(data.blipScale or data.blip_scale, 0.8),
        blipLabel = CleanName(data.blipLabel or data.blip_label, name, 100),
        faction = CleanFaction(data.factionRestriction or data.faction_restriction),
        grade = math.max(0, IL.Int(data.factionGradeMin or data.faction_grade_min, 0)),
    }
end

local function StationPayload(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local coords = ReadVec(data)
    if not coords then return nil, "Définissez la position." end
    local name = CleanName(data.name, nil, 100)
    if not name then return nil, "Nom obligatoire." end
    local kind = IL.Str(data.stationType or data.station_type or data.category, "armes")
    if kind ~= "armes" and kind ~= "gpb" and kind ~= "munitions" then kind = "armes" end
    local marker = ReadMarker(data, coords)
    return {
        name = name,
        kind = kind,
        coords = coords,
        marker = marker,
        prop = CleanItem(data.propModel or data.prop_model),
        blipEnabled = IL.Bool(data.blipEnabled or data.blip_enabled),
        blipSprite = IL.Int(data.blipSprite or data.blip_sprite, 566),
        blipColor = IL.Int(data.blipColor or data.blip_color, 1),
        blipScale = IL.Num(data.blipScale or data.blip_scale, 0.8),
        blipLabel = CleanName(data.blipLabel or data.blip_label, name, 100),
        faction = CleanFaction(data.factionRestriction or data.faction_restriction),
        grade = math.max(0, IL.Int(data.factionGradeMin or data.faction_grade_min, 0)),
    }
end

local function RecipePayload(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local stationId = IL.Int(data.stationId or data.station_id, nil)
    if not stationId then return nil, "Choisissez une station." end
    local name = CleanName(data.name or data.recipe_name or data.recipeName, nil, 100)
    local label = CleanName(data.label, name, 100)
    local output = CleanItem(data.outputItem or data.output_item)
    local ingredients = EncodeIngredients(data.ingredients)
    if not name then return nil, "Identifiant de recette obligatoire." end
    if not output then return nil, "Item produit obligatoire." end
    if #ingredients == 0 then return nil, "Ajoutez au moins un ingrédient." end
    return {
        stationId = stationId,
        name = name,
        label = label or name,
        output = output,
        outputQty = math.max(1, IL.Int(data.outputQuantity or data.output_quantity, 1)),
        ingredients = ingredients,
        craftTime = DurationMs(data.craftTime or data.craft_time, 5000),
        slot = math.max(0, IL.Int(data.slot_index or data.slotIndex or data.slot, 0)),
        faction = CleanFaction(data.factionRestriction or data.faction_restriction),
        grade = math.max(0, IL.Int(data.factionGradeMin or data.faction_grade_min, 0)),
    }
end

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

local function HarvestParams(p)
    return {
        p.name, p.coords.x, p.coords.y, p.coords.z, p.coords.w,
        p.marker.x, p.marker.y, p.marker.z, p.prop,
        p.item, p.output, p.harvestTime, p.cooldown, p.animationType, p.animationDict,
        p.animationName, p.animationPreset, p.animationProp,
        p.blipEnabled and 1 or 0, p.blipSprite, p.blipColor, p.blipScale, p.blipLabel,
        p.faction, p.grade,
    }
end

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

local function TransformParams(p)
    return {
        p.name, p.coords.x, p.coords.y, p.coords.z, p.coords.w,
        p.marker.x, p.marker.y, p.marker.z, p.prop,
        p.input, p.inputQty, p.output, p.outputQty, p.transformTime, p.cooldown,
        p.animationType, p.animationDict, p.animationName, p.animationPreset, p.animationProp,
        p.blipEnabled and 1 or 0, p.blipSprite, p.blipColor, p.blipScale, p.blipLabel,
        p.faction, p.grade,
    }
end

local STATION_INSERT = [[
    INSERT INTO illegal_craft_stations
        (name, station_type, coords_x, coords_y, coords_z, rotation_z, marker_x, marker_y, marker_z, prop_model,
         blip_enabled, blip_sprite, blip_color, blip_scale, blip_label, faction_restriction, faction_grade_min)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]]

local STATION_UPDATE = [[
    UPDATE illegal_craft_stations SET
        name = ?, station_type = ?, coords_x = ?, coords_y = ?, coords_z = ?, rotation_z = ?,
        marker_x = ?, marker_y = ?, marker_z = ?, prop_model = ?, blip_enabled = ?, blip_sprite = ?,
        blip_color = ?, blip_scale = ?, blip_label = ?, faction_restriction = ?, faction_grade_min = ?
    WHERE id = ?
]]

local function StationParams(p)
    return {
        p.name, p.kind, p.coords.x, p.coords.y, p.coords.z, p.coords.w,
        p.marker.x, p.marker.y, p.marker.z, p.prop,
        p.blipEnabled and 1 or 0, p.blipSprite, p.blipColor, p.blipScale, p.blipLabel,
        p.faction, p.grade,
    }
end

IL.RegisterCallback("illegalBuilder:getItems", function(source)
    if not staffOk(source) then return {} end
    return ItemsCatalog()
end)

IL.RegisterCallback("illegalBuilder:getFactions", function(source)
    if not staffOk(source) then return {} end
    return FactionsCatalog()
end)

IL.RegisterCallback("illegalBuilder:getFactionGrades", function(source, name)
    if not staffOk(source) then return {} end
    return FactionGrades(name)
end)

IL.RegisterCallback("illegalBuilder:getPresetAnimations", function(source)
    if not staffOk(source) then return {} end
    return PRESETS
end)

IL.RegisterCallback("illegalBuilder:getRecipes", function(source)
    if not staffOk(source) then return {} end
    return RecipesMap()
end)

IL.RegisterCallback("gestionIllegalCraft:hubPanel", function(source)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer le craft illégal." }
    end
    return HubPanel()
end)

IL.RegisterCallback("illegalBuilder:createHarvestSpot", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    local payload, err = HarvestPayload(data)
    if not payload then return fail(err) end
    local id = IL.Insert(HARVEST_INSERT, HarvestParams(payload))
    if not id then return fail("Création impossible.") end
    TriggerEvent("illegal:internal:reloadSpots")
    local panel = HubPanel()
    panel.success = true
    panel.selectedId = id
    panel.kind = "harvest"
    return panel
end)

IL.RegisterCallback("illegalBuilder:updateHarvestSpot", function(source, id, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    local payload, err = HarvestPayload(type(id) == "table" and id or data)
    if not payload then return fail(err) end
    local spotId = IL.Int(type(id) == "table" and id.id or id, nil)
    if not spotId then return fail("Spot introuvable.") end
    local params = HarvestParams(payload)
    params[#params + 1] = spotId
    IL.Execute(HARVEST_UPDATE, params)
    TriggerEvent("illegal:internal:reloadSpots")
    local panel = HubPanel()
    panel.success = true
    panel.selectedId = spotId
    panel.kind = "harvest"
    return panel
end)

IL.RegisterCallback("illegalBuilder:deleteHarvestSpot", function(source, id)
    if not staffOk(source) then return fail("Permission refusée.") end
    local spotId = IL.Int(type(id) == "table" and id.id or id, nil)
    if not spotId then return fail("Spot introuvable.") end
    IL.Execute("DELETE FROM illegal_harvest_spots WHERE id = ?", { spotId })
    TriggerEvent("illegal:internal:reloadSpots")
    local panel = HubPanel()
    panel.success = true
    panel.kind = "harvest"
    return panel
end)

IL.RegisterCallback("illegalBuilder:createTransformSpot", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    local payload, err = TransformPayload(data)
    if not payload then return fail(err) end
    local id = IL.Insert(TRANSFORM_INSERT, TransformParams(payload))
    if not id then return fail("Création impossible.") end
    TriggerEvent("illegal:internal:reloadSpots")
    local panel = HubPanel()
    panel.success = true
    panel.selectedId = id
    panel.kind = "transform"
    return panel
end)

IL.RegisterCallback("illegalBuilder:updateTransformSpot", function(source, id, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    local payload, err = TransformPayload(type(id) == "table" and id or data)
    if not payload then return fail(err) end
    local spotId = IL.Int(type(id) == "table" and id.id or id, nil)
    if not spotId then return fail("Spot introuvable.") end
    local params = TransformParams(payload)
    params[#params + 1] = spotId
    IL.Execute(TRANSFORM_UPDATE, params)
    TriggerEvent("illegal:internal:reloadSpots")
    local panel = HubPanel()
    panel.success = true
    panel.selectedId = spotId
    panel.kind = "transform"
    return panel
end)

IL.RegisterCallback("illegalBuilder:deleteTransformSpot", function(source, id)
    if not staffOk(source) then return fail("Permission refusée.") end
    local spotId = IL.Int(type(id) == "table" and id.id or id, nil)
    if not spotId then return fail("Spot introuvable.") end
    IL.Execute("DELETE FROM illegal_transform_spots WHERE id = ?", { spotId })
    TriggerEvent("illegal:internal:reloadSpots")
    local panel = HubPanel()
    panel.success = true
    panel.kind = "transform"
    return panel
end)

IL.RegisterCallback("illegalBuilder:createCraftStation", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    local payload, err = StationPayload(data)
    if not payload then return fail(err) end
    local id = IL.Insert(STATION_INSERT, StationParams(payload))
    if not id then return fail("Création impossible.") end
    TriggerEvent("illegal:internal:reloadCraft")
    local panel = HubPanel()
    panel.success = true
    panel.selectedId = id
    panel.kind = "station"
    return panel
end)

IL.RegisterCallback("illegalBuilder:updateCraftStation", function(source, id, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    local payload, err = StationPayload(type(id) == "table" and id or data)
    if not payload then return fail(err) end
    local stationId = IL.Int(type(id) == "table" and id.id or id, nil)
    if not stationId then return fail("Station introuvable.") end
    local params = StationParams(payload)
    params[#params + 1] = stationId
    IL.Execute(STATION_UPDATE, params)
    TriggerEvent("illegal:internal:reloadCraft")
    local panel = HubPanel()
    panel.success = true
    panel.selectedId = stationId
    panel.kind = "station"
    return panel
end)

IL.RegisterCallback("illegalBuilder:deleteCraftStation", function(source, id)
    if not staffOk(source) then return fail("Permission refusée.") end
    local stationId = IL.Int(type(id) == "table" and id.id or id, nil)
    if not stationId then return fail("Station introuvable.") end
    IL.Execute("DELETE FROM illegal_craft_recipes WHERE station_id = ?", { stationId })
    IL.Execute("DELETE FROM illegal_craft_stations WHERE id = ?", { stationId })
    TriggerEvent("illegal:internal:reloadCraft")
    local panel = HubPanel()
    panel.success = true
    panel.kind = "station"
    return panel
end)

IL.RegisterCallback("illegalBuilder:createRecipe", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    local payload, err = RecipePayload(data)
    if not payload then return fail(err) end
    local id = IL.Insert([[
        INSERT INTO illegal_craft_recipes
            (station_id, recipe_name, label, output_item, output_quantity, ingredients, craft_time, slot_index,
             faction_restriction, faction_grade_min)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.stationId, payload.name, payload.label, payload.output, payload.outputQty,
        IL.Encode(payload.ingredients), payload.craftTime, payload.slot, payload.faction, payload.grade,
    })
    if not id then return fail("Création impossible.") end
    TriggerEvent("illegal:internal:reloadCraft")
    local panel = HubPanel()
    panel.success = true
    panel.selectedId = id
    panel.kind = "recipe"
    return panel
end)

IL.RegisterCallback("illegalBuilder:updateRecipe", function(source, id, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    local payload, err = RecipePayload(type(id) == "table" and id or data)
    if not payload then return fail(err) end
    local recipeId = IL.Int(type(id) == "table" and id.id or id, nil)
    if not recipeId then return fail("Recette introuvable.") end
    IL.Execute([[
        UPDATE illegal_craft_recipes SET
            station_id = ?, recipe_name = ?, label = ?, output_item = ?, output_quantity = ?,
            ingredients = ?, craft_time = ?, slot_index = ?, faction_restriction = ?, faction_grade_min = ?
        WHERE id = ?
    ]], {
        payload.stationId, payload.name, payload.label, payload.output, payload.outputQty,
        IL.Encode(payload.ingredients), payload.craftTime, payload.slot, payload.faction, payload.grade, recipeId,
    })
    TriggerEvent("illegal:internal:reloadCraft")
    local panel = HubPanel()
    panel.success = true
    panel.selectedId = recipeId
    panel.kind = "recipe"
    return panel
end)

IL.RegisterCallback("illegalBuilder:deleteRecipe", function(source, id)
    if not staffOk(source) then return fail("Permission refusée.") end
    local recipeId = IL.Int(type(id) == "table" and id.id or id, nil)
    if not recipeId then return fail("Recette introuvable.") end
    IL.Execute("DELETE FROM illegal_craft_recipes WHERE id = ?", { recipeId })
    TriggerEvent("illegal:internal:reloadCraft")
    local panel = HubPanel()
    panel.success = true
    panel.kind = "recipe"
    return panel
end)

IL.RegisterCallback("illegalBuilder:assignRecipes", function(source, stationId, assignments)
    if not staffOk(source) then return fail("Permission refusée.") end
    local id = IL.Int(stationId, nil)
    if not id or type(assignments) ~= "table" then return fail("Assignation invalide.") end
    for i = 1, #assignments do
        local row = assignments[i]
        if type(row) == "table" then
            local recipeId = IL.Int(row.recipeId or row.id, nil)
            if recipeId then
                local nextStation = row.category == nil and 0 or id
                if row.stationId ~= nil then nextStation = IL.Int(row.stationId, id) end
                IL.Execute("UPDATE illegal_craft_recipes SET station_id = ? WHERE id = ?", { nextStation, recipeId })
            end
        end
    end
    TriggerEvent("illegal:internal:reloadCraft")
    local panel = HubPanel()
    panel.success = true
    panel.selectedId = id
    panel.kind = "station"
    return panel
end)
