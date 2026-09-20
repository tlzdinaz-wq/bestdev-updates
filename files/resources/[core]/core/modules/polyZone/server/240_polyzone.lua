local BUILDER_PERMISSIONS = { "dev_tools", "builder", "builder_menu", "zone_actions" }

local function isBuilder(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    for i = 1, #BUILDER_PERMISSIONS do
        if xPlayer.hasPermission(BUILDER_PERMISSIONS[i]) then
            return xPlayer
        end
    end

    return nil
end

local function num(value, fallback)
    local n = tonumber(value)
    if not n then return fallback end
    return n
end

local function readVector(value)
    if type(value) == "table" then
        local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
        if x and y then return x, y, z end
        return nil
    end

    if type(value) == "vector3" then
        return value.x, value.y, value.z
    end

    if type(value) == "vector2" then
        return value.x, value.y, nil
    end

    return nil
end

local function emit(source, name, snippet)
    console.info(("[PolyZone] snippet '%s' genere par %d"):format(name, source))
    print(snippet)
    TriggerClientEvent("log:debugLine", source, snippet)
end

RegisterNetEvent("polyzone:printBox", function(data)
    local source = source

    local xPlayer = isBuilder(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end

    local x, y, z = readVector(data.center)
    if not x or not y then return end

    local name = type(data.name) == "string" and data.name:sub(1, 48) or "boxZone"
    local length = num(data.length, 2.0)
    local width = num(data.width, 2.0)
    local heading = num(data.heading, 0.0)
    local minZ = num(data.minZ, (z or 0.0) - 1.0)
    local maxZ = num(data.maxZ, (z or 0.0) + 1.0)

    emit(source, name, ([[
BoxZone:Create(vector3(%.2f, %.2f, %.2f), %.2f, %.2f, {
    name = "%s",
    heading = %.2f,
    minZ = %.2f,
    maxZ = %.2f,
})]]):format(x, y, z or 0.0, length, width, name, heading, minZ, maxZ))
end)

RegisterNetEvent("polyzone:printCircle", function(data)
    local source = source

    local xPlayer = isBuilder(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end

    local x, y, z = readVector(data.center)
    if not x or not y then return end

    local name = type(data.name) == "string" and data.name:sub(1, 48) or "circleZone"
    local radius = num(data.radius, 2.0)
    local useZ = data.useZ and true or false

    emit(source, name, ([[
CircleZone:Create(vector3(%.2f, %.2f, %.2f), %.2f, {
    name = "%s",
    useZ = %s,
})]]):format(x, y, z or 0.0, radius, name, tostring(useZ)))
end)

RegisterNetEvent("polyzone:printPoly", function(data)
    local source = source

    local xPlayer = isBuilder(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end
    if type(data.points) ~= "table" or #data.points < 3 then return end

    local name = type(data.name) == "string" and data.name:sub(1, 48) or "polyZone"
    local minZ = num(data.minZ, 0.0)
    local maxZ = num(data.maxZ, 0.0)

    local lines, count = {}, 0
    for i = 1, #data.points do
        local px, py = readVector(data.points[i])
        if px and py then
            count = count + 1
            lines[count] = ("    vector2(%.2f, %.2f),"):format(px, py)
        end
    end

    if count < 3 then return end

    emit(source, name, ([[
PolyZone:Create({
%s
}, {
    name = "%s",
    minZ = %.2f,
    maxZ = %.2f,
})]]):format(table.concat(lines, "\n"), name, minZ, maxZ))
end)
