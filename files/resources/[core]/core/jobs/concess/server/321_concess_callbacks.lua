VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Concess = VFW.Concess or {}

local JC = VFW.JobsCommon
local Concess = VFW.Concess

JC.Cb("core:get:societyInfo", function(source, jobName)
    local name = JC.Str(jobName, 64)
    if not name then
        local xPlayer = VFW.GetPlayerFromId(source)
        if xPlayer and xPlayer.job then name = xPlayer.job.name end
    end

    if not name then
        return { image = "", label = "Information", jobLabel = "Information" }
    end

    return JC.SocietyInfo(name)
end)

Concess.DefaultTrunkWeight = 40

JC.Cb("vehicleStorage:getStorageValues", function(source, model, hash)
    if type(model) ~= "string" and type(model) ~= "number" then return {} end
    if hash ~= nil and type(hash) ~= "number" then return {} end

    local modelName = JC.Str(tostring(model), 64)
    if not modelName then return {} end

    local row = JC.Single(
        "SELECT trunk_weight FROM vehicle_storage_config WHERE model = ?", { modelName:lower() })

    if row and row.trunk_weight ~= nil then
        return { trunk_weight = JC.Int(row.trunk_weight, 0) or 0 }
    end

    return { trunk_weight = Concess.DefaultTrunkWeight }
end)

JC.Cb("core:concess:getAll", function()
    local out = {}
    for _, entry in pairs(Concess.GetAll()) do
        local hasCatalog = entry.catalog and #entry.catalog > 0
        local hasShowcase = entry.showcase and #entry.showcase > 0
        if hasCatalog or hasShowcase then
            out[#out + 1] = Concess.Payload(entry)
        end
    end

    table.sort(out, function(a, b) return (a.id or 0) < (b.id or 0) end)
    return out
end)

JC.Cb("core:concess:getMine", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return nil end
    local entry = Concess.Ensure(xPlayer.job.name)
    if not entry then
        entry = Concess.GetByJob(xPlayer.job.name)
    end
    return Concess.Payload(entry)
end)

JC.Cb("core:concess:areEmployeesOnDuty", function(source, jobName)
    local name = JC.Str(jobName, 64)
    if not name then return false end
    return Concess.EmployeesOnDuty(name)
end)

JC.Cb("core:concess:getCategories", function(source, concessType)
    return Concess.Categories(concessType)
end)

JC.Cb("core:concess:getCategoriesWithType", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Concess.CanBuild(xPlayer) then return {} end
    return Concess.CategoriesWithType()
end)

JC.Cb("core:concess:getVehicles", function(source, category, concessType)
    return Concess.VehiclesByCategory(category, concessType)
end)

JC.Cb("core:concess:getStock", function(source, concessId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local entry = Concess.Get(concessId)
    if not entry then return {} end

    return Concess.Stock(entry.id)
end)

JC.Cb("core:concess:getLogs", function(source, concessId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local entry = Concess.Get(concessId)
    if not entry then return {} end

    if not Concess.IsEmployee(xPlayer, entry) and not Concess.CanBuild(xPlayer) then return {} end

    return Concess.Logs(entry.id, 60)
end)

JC.Cb("core:concess:getNearbyPlayersNames", function(source, serverIds)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if type(serverIds) ~= "table" then return {} end

    local out = {}
    local seen = {}

    for i = 1, #serverIds do
        local targetId = JC.Int(serverIds[i], 1)
        if targetId and targetId ~= source and not seen[targetId] then
            seen[targetId] = true
            local target = VFW.GetPlayerFromId(targetId)
            if target and JC.DistPlayers(source, targetId) <= 12.0 then
                out[#out + 1] = { id = targetId, name = JC.PlayerName(target) }
            end
        end
        if #out >= 32 then break end
    end

    return out
end)

JC.Cb("core:concess:getNearbyPlayersForKeys", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return {} end
    if not Concess.Ensure(xPlayer.job.name) then return {} end

    local out = {}
    local players = VFW.GetPlayers()

    for i = 1, #players do
        local targetId = players[i]
        if targetId ~= source then
            local target = VFW.GetPlayerFromId(targetId)
            if target and JC.DistPlayers(source, targetId) <= 12.0 then
                out[#out + 1] = { id = targetId, name = JC.PlayerName(target) }
            end
        end
        if #out >= 32 then break end
    end

    return out
end)

JC.Cb("core:concess:getPlayerVehicles", function(source, targetServerId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return {} end
    if not Concess.Ensure(xPlayer.job.name) then return {} end

    local targetId = JC.Int(targetServerId, 1)
    if not targetId then return {} end

    local target = VFW.GetPlayerFromId(targetId)
    if not target then return {} end
    if JC.DistPlayers(source, targetId) > 12.0 then return {} end

    local rows = JC.Query(
        "SELECT plate, vehName, model, label FROM owned_vehicles WHERE owner = ? ORDER BY plate ASC LIMIT 100",
        { target.identifier })

    local out = {}
    for i = 1, #rows do
        out[i] = {
            plate = rows[i].plate,
            model = rows[i].vehName ~= "" and rows[i].vehName or rows[i].model,
            name = rows[i].label ~= "" and rows[i].label or nil,
        }
    end

    return out
end)
