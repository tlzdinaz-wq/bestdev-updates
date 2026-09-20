local TV_MODELS = {
    { model = "prop_tv_flat_01" },
    { model = "prop_tv_flat_01b" },
    { model = "prop_tv_flat_02" },
    { model = "prop_tv_flat_03" },
    { model = "prop_tv_03" },
    { model = "prop_tv_06" },
    { model = "prop_tv_07" },
    { model = "v_res_tre_tv" },
    { model = "v_res_mtv" },
}

MiscB.Cb("television:getModels", function(source)
    return TV_MODELS
end)

local chairSlots = {}

local function chairKey(modelHash, x, y, z)
    return ("%s:%d:%d:%d"):format(tostring(modelHash), math.floor(x * 10), math.floor(y * 10), math.floor(z * 10))
end

MiscB.Cb("chairSlot:claim", function(source, modelHash, x, y, z, count)
    local hash = tonumber(modelHash)
    local px, py, pz = tonumber(x), tonumber(y), tonumber(z)
    local total = MiscB.ToInt(count, 1, 32)
    if not hash or not px or not py or not pz or not total then return nil end

    local key = chairKey(hash, px, py, pz)
    local slots = chairSlots[key]
    if not slots then
        slots = {}
        chairSlots[key] = slots
    end

    for i = 1, total do
        if slots[i] == nil or not VFW.GetPlayerFromId(slots[i]) then
            slots[i] = source
            return i
        end
    end
    return nil
end)

MiscB.Cb("chairSlot:release", function(source, modelHash, x, y, z, slotIdx)
    local hash = tonumber(modelHash)
    local px, py, pz = tonumber(x), tonumber(y), tonumber(z)
    local idx = MiscB.ToInt(slotIdx, 1, 32)
    if not hash or not px or not py or not pz or not idx then return false end

    local key = chairKey(hash, px, py, pz)
    local slots = chairSlots[key]
    if not slots then return false end
    if slots[idx] == source then slots[idx] = nil end

    local empty = true
    for _, v in pairs(slots) do
        if v ~= nil then empty = false break end
    end
    if empty then chairSlots[key] = nil end
    return true
end)

AddEventHandler("vfw:playerDropped", function(source)
    for key, slots in pairs(chairSlots) do
        for idx, src in pairs(slots) do
            if src == source then slots[idx] = nil end
        end
        local empty = true
        for _, v in pairs(slots) do
            if v ~= nil then empty = false break end
        end
        if empty then chairSlots[key] = nil end
    end
end)

local ropes = {}
local nextRopeId = 1

local VALID_ROPE_TYPE = { vehicle = true, prop = true, object = true, ped = true }
local VALID_ROPE_SIDE = { front = true, back = true, center = true, left = true, right = true }

local function broadcastRope(rope, target)
    TriggerClientEvent("vfw:rope:created", target or -1, rope.id, rope.owner,
        rope.net1, rope.type1, rope.side1, rope.net2, rope.type2, rope.side2)
end

RegisterNetEvent("vfw:rope:create", function(net1, type1, side1, net2, type2, side2)
    local source = source
    local n1, n2 = tonumber(net1), tonumber(net2)
    if not n1 or not n2 or n1 == n2 then return end
    if type(type1) ~= "string" or type(type2) ~= "string" then return end
    if type(side1) ~= "string" or type(side2) ~= "string" then return end
    if not VALID_ROPE_TYPE[type1] or not VALID_ROPE_TYPE[type2] then return end
    if not VALID_ROPE_SIDE[side1] or not VALID_ROPE_SIDE[side2] then return end
    if not MiscB.Rate(source, "ropecreate", 700) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    for _, rope in pairs(ropes) do
        if (rope.net1 == n1 and rope.net2 == n2) or (rope.net1 == n2 and rope.net2 == n1) then
            return
        end
    end

    local rope = {
        id = nextRopeId,
        owner = source,
        net1 = n1, type1 = type1, side1 = side1,
        net2 = n2, type2 = type2, side2 = side2,
    }
    nextRopeId = nextRopeId + 1
    ropes[rope.id] = rope

    broadcastRope(rope, -1)
end)

RegisterNetEvent("vfw:rope:remove", function(ropeId)
    local source = source
    local id = tonumber(ropeId)
    if not id then return end
    if not ropes[id] then return end
    ropes[id] = nil
    TriggerClientEvent("vfw:rope:removed", -1, id)
end)

RegisterNetEvent("vfw:rope:requestAll", function()
    local source = source
    for _, rope in pairs(ropes) do
        broadcastRope(rope, source)
    end
end)

local function nearestPound(coords)
    if not VFW.Pounds or not VFW.Pounds.BuildPayload then return nil end
    local ok, payload = pcall(VFW.Pounds.BuildPayload)
    if not ok or type(payload) ~= "table" then return nil end

    local pos = MiscB.Vec3(coords)
    local best, bestDist = nil, 999999.0
    for _, pound in pairs(payload) do
        local p = MiscB.Vec3(pound.coords or pound.pos or pound.position)
        if p and pos then
            local d = #(pos - p)
            if d < bestDist then
                best, bestDist = pound, d
            end
        elseif not best then
            best = pound
        end
    end
    return best
end

MiscB.Cb("vfw:getPound", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local rows = MiscB.Query([[
        SELECT plate, vehName, label, props, engineHealth, bodyHealth, fuelLevel
        FROM owned_vehicles WHERE owner = ? AND pounded = 1 ORDER BY vehName ASC
    ]], { xPlayer.identifier })

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = row.plate,
            plate = row.plate,
            model = row.vehName,
            label = row.label or row.vehName,
            prop = VFW.DB.Decode(row.props, {}),
            engineHealth = row.engineHealth,
            bodyHealth = row.bodyHealth,
        }
    end

    return { vehicles = out }
end)

MiscB.Cb("vfw:garagePublic:get", function(source, plate)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if type(plate) ~= "string" or #plate > 12 then return nil end

    local row = MiscB.Single(
        "SELECT vehName, props FROM owned_vehicles WHERE plate = ? AND owner = ? LIMIT 1",
        { plate, xPlayer.identifier }
    )
    if not row then return nil end
    return row.vehName, VFW.DB.Decode(row.props, {})
end)

MiscB.Cb("vfw:vehicleGaragePublic", function(source, plate, props)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if type(plate) ~= "string" or #plate > 12 then return false end
    if type(props) ~= "table" then return false end

    local row = MiscB.Single(
        "SELECT plate FROM owned_vehicles WHERE plate = ? AND owner = ? LIMIT 1",
        { plate, xPlayer.identifier }
    )
    if not row then return false end

    MiscB.Update("UPDATE owned_vehicles SET props = ?, stored = 1 WHERE plate = ?", { VFW.DB.Encode(props), plate })
    return true
end)

RegisterNetEvent("vfw:pound:use", function(camPos, vehicleId, makeName)
    local source = source
    if type(vehicleId) ~= "string" or #vehicleId > 12 then return end
    if not MiscB.Rate(source, "pounduse", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local pound = nearestPound(camPos)
    local poundId = pound and (pound.id or pound.poundId) or nil

    TriggerEvent("pound:restoreVehicle", vehicleId, poundId, "bank")
end)

MiscB.Cb("core:roxwood:check", function(source, price)
    local amount = MiscB.ToInt(price, 0, 10000000) or 0
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local money = xPlayer.getAccount("money")
    local cash = type(money) == "table" and (money.money or money.amount or 0) or (tonumber(money) or 0)
    if cash >= amount then return true end

    local bank = xPlayer.getAccount("bank")
    local bankAmount = type(bank) == "table" and (bank.money or bank.amount or 0) or (tonumber(bank) or 0)
    return bankAmount >= amount
end)

local safeZones = nil

local function loadSafeZones()
    if safeZones then return safeZones end
    safeZones = {}
    if not VFW.Variables or not VFW.Variables.GetVariable then return safeZones end
    local ok, saved = pcall(VFW.Variables.GetVariable, "safe_zones")
    if ok and type(saved) == "table" then safeZones = saved end
    return safeZones
end

local function persistSafeZones()
    if not VFW.Variables or not VFW.Variables.SetVariable then return end
    pcall(VFW.Variables.SetVariable, "safe_zones", safeZones or {})
end

MiscB.Cb("core:admin:getAllZoneSafe", function(source)
    return loadSafeZones()
end)

RegisterNetEvent("core:createZoneSafe", function(name, pos)
    local source = source
    local zoneName = MiscB.Str(name, 64)
    local coords = MiscB.Plain(pos)
    if not zoneName or not coords then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.hasPermission("staff") and not xPlayer.hasPermission("admin") then return end

    loadSafeZones()
    safeZones[zoneName] = { pos = coords }
    persistSafeZones()
    TriggerClientEvent("core:createZoneSafe", -1, zoneName, coords)
end)

RegisterNetEvent("core:deleteZoneSafe", function(name)
    local source = source
    local zoneName = MiscB.Str(name, 64)
    if not zoneName then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.hasPermission("staff") and not xPlayer.hasPermission("admin") then return end

    loadSafeZones()
    safeZones[zoneName] = nil
    persistSafeZones()
    TriggerClientEvent("core:deleteZoneSafe", -1, zoneName)
end)

local function liaisonSociety(xPlayer)
    local job = MiscB.JobName(xPlayer)
    if not job or job == "" then return nil end
    return job
end

MiscB.Cb("liaison:getConversation", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    local society = liaisonSociety(xPlayer)
    if not society then return {} end

    return MiscB.Query([[
        SELECT id, society, sender_name, sender_identifier, message, from_gouv, is_read, created_at
        FROM gouv_liaison_messages WHERE society = ? ORDER BY id ASC LIMIT 200
    ]], { society })
end)

MiscB.Cb("liaison:sendMessage", function(source, payload)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if type(payload) ~= "table" then return false end

    local message = MiscB.Str(payload.message, 1000)
    if not message or message == "" then return false end

    local society = liaisonSociety(xPlayer)
    if not society then return false end
    if not MiscB.Rate(source, "liaison_send", 1500) then return false end

    local id = MiscB.Insert([[
        INSERT INTO gouv_liaison_messages (society, sender_identifier, sender_name, message, from_gouv, is_read)
        VALUES (?, ?, ?, ?, 0, 0)
    ]], { society, xPlayer.identifier, MiscB.CharName(xPlayer), message })

    local data = {
        id = id,
        society = society,
        sender_name = MiscB.CharName(xPlayer),
        message = message,
        from_gouv = 0,
    }

    local gouv = MiscB.PlayersWithJobs({ "gouvernement", "gouv", "mairie" })
    for i = 1, #gouv do
        TriggerClientEvent("liaison:newMessage", gouv[i].source, data)
    end

    return id ~= nil
end)

MiscB.Cb("liaison:deleteMessage", function(source, payload)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(payload) ~= "table" then return false end
    local id = MiscB.ToInt(payload.messageId, 1)
    if not id then return false end
    local society = liaisonSociety(xPlayer)
    if not society then return false end

    MiscB.Update("DELETE FROM gouv_liaison_messages WHERE id = ? AND society = ?", { id, society })
    return true
end)

MiscB.Cb("liaison:clearConversation", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    local society = liaisonSociety(xPlayer)
    if not society then return false end
    if not MiscB.IsBoss(xPlayer) then return false end

    MiscB.Update("DELETE FROM gouv_liaison_messages WHERE society = ?", { society })
    return true
end)

MiscB.Cb("liaison:getUnreadCount", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return 0 end
    local society = liaisonSociety(xPlayer)
    if not society then return 0 end

    return MiscB.Scalar(
        "SELECT COUNT(*) FROM gouv_liaison_messages WHERE society = ? AND from_gouv = 1 AND is_read = 0",
        { society }, 0
    )
end)

MiscB.Cb("liaison:markAsRead", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    local society = liaisonSociety(xPlayer)
    if not society then return false end

    MiscB.Update("UPDATE gouv_liaison_messages SET is_read = 1 WHERE society = ? AND from_gouv = 1", { society })
    return true
end)

MiscB.Cb("liaison:getCompanyTaxes", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    local society = liaisonSociety(xPlayer)
    if not society then return {} end

    return MiscB.Query([[
        SELECT id, society, label, amount, period, active, created_at
        FROM gouv_company_taxes WHERE society = ? ORDER BY id DESC
    ]], { society })
end)

MiscB.Cb("liaison:getTaxLogs", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    local society = liaisonSociety(xPlayer)
    if not society then return {} end

    return MiscB.Query([[
        SELECT id, society, label, amount, collected_by, created_at
        FROM gouv_tax_logs WHERE society = ? ORDER BY id DESC LIMIT 100
    ]], { society })
end)
