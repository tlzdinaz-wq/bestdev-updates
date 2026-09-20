VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Farm = VFW.Farm or {}

local JC = VFW.JobsCommon
local Farm = VFW.Farm

local BUILDER_PERMISSIONS = { "builder_farm", "builder_menu", "builder", "manage_jobs", "staff_menu" }

local function canBuild(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    for i = 1, #BUILDER_PERMISSIONS do
        if xPlayer.hasPermission(BUILDER_PERMISSIONS[i]) then return xPlayer end
    end
    return nil
end

Farm.CanBuild = canBuild

JC.Cb("core:farm:getConfigs", function(source)
    if not canBuild(source) then return {} end

    local out = {}
    for societyName, config in pairs(Farm.GetAll()) do
        out[societyName] = {
            is_bar = config.is_bar,
            ped_coords = config.ped_coords,
            harvest = config.harvest,
            harvestIsDefault = config.harvestIsDefault,
            processing_points = config.processing_points,
            processingIsDefault = config.processingIsDefault,
            animations = config.animations,
            items = config.items,
            society_percent = config.society_percent,
        }
    end

    return out
end)

RegisterNetEvent("core:farm:updatePedPosition", function(societyName, coords)
    local source = source
    if not canBuild(source) then return end

    local name = JC.Str(societyName, 64)
    if not name or not Farm.Get(name) then return end

    local point = JC.Vec(coords)
    if not point then return end
    point.heading = JC.Num(coords.heading) or JC.Num(coords.h) or 0.0

    Farm.Save(name, "ped_coords", JC.Encode(point))
    Farm.Load()
    Farm.PushSociety(name, -1)
end)

local function updatePoints(source, societyName, points, column)
    if not canBuild(source) then return end

    local name = JC.Str(societyName, 64)
    if not name or not Farm.Get(name) then return end
    if type(points) ~= "table" then return end

    local clean = {}
    for i = 1, #points do
        local point = JC.Vec(points[i])
        if point then clean[#clean + 1] = point end
        if #clean >= 250 then break end
    end

    Farm.Save(name, column, #clean > 0 and JC.Encode(clean) or nil)
    Farm.Load()
    Farm.PushSociety(name, -1)
end

RegisterNetEvent("core:farm:updateHarvestPoints", function(societyName, points)
    local source = source
    updatePoints(source, societyName, points, "harvest")
end)

RegisterNetEvent("core:farm:updateProcessingPoints", function(societyName, points)
    local source = source
    updatePoints(source, societyName, points, "processing_points")
end)

local ANIM_COLUMNS = {
    harvest_anim = true,
    processing_anim = true,
    selling_anim = true,
}

RegisterNetEvent("core:farm:updateAnimation", function(societyName, dbKey, animData)
    local source = source
    if not canBuild(source) then return end

    local name = JC.Str(societyName, 64)
    if not name or not Farm.Get(name) then return end

    local column = JC.Str(dbKey, 32)
    if not column or not ANIM_COLUMNS[column] then return end

    if animData == nil then
        Farm.Save(name, column, nil)
    else
        if type(animData) ~= "table" then return end
        local dict = JC.Str(animData.dict, 96)
        local animName = JC.Str(animData.name, 96)
        if not dict or not animName then return end
        Farm.Save(name, column, JC.Encode({ dict = dict, name = animName }))
    end

    Farm.Load()
    Farm.PushSociety(name, -1)
end)

RegisterNetEvent("core:farm:updateItemPrice", function(societyName, itemName, price)
    local source = source
    if not canBuild(source) then return end

    local name = JC.Str(societyName, 64)
    if not name then return end

    local config = Farm.Get(name)
    if not config then return end

    local item = JC.Str(itemName, 60)
    if not item then return end

    local value = JC.Int(price, 0, 10000000)
    if not value then return end

    local items = JC.Copy(config.items) or {}
    local found = false

    for _, list in pairs(items) do
        if type(list) == "table" then
            for i = 1, #list do
                if list[i].name == item then
                    list[i].price = value
                    found = true
                end
            end
        end
    end

    if not found then
        local def = Farm.Definitions[name]
        local key = def and def.processKey or "process"
        items[key] = items[key] or {}
        items[key][#items[key] + 1] = { name = item, label = JC.ItemLabel(item), price = value }
    end

    Farm.Save(name, "items", JC.Encode(items))
    Farm.Load()
end)

RegisterNetEvent("core:farm:updateSocietyPercent", function(societyName, percent)
    local source = source
    if not canBuild(source) then return end

    local name = JC.Str(societyName, 64)
    if not name or not Farm.Get(name) then return end

    local value = JC.Int(percent, 0, 100)
    if not value then return end

    Farm.Save(name, "society_percent", value)
    Farm.Load()
end)

JC.Cb("core:farm:clearFarmingLogs", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return false end

    local societyName = xPlayer.job.name
    if not Farm.Get(societyName) then return false end
    if not JC.IsBoss(xPlayer) and not JC.IsStaff(xPlayer) then return false end

    Farm.ClearLogs(societyName)

    if VFW.Logs and VFW.Logs.Simple then
        VFW.Logs.Simple("society", "Logs farm purges",
            ("%s a purge les logs de %s"):format(JC.PlayerName(xPlayer), societyName))
    end

    return true
end)
