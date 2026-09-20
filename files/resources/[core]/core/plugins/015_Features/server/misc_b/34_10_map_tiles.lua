local TILE_URL = "https://assets.loaf-scripts.com/map-tiles/gtav/main/render/%d/%d/%d.jpg"
local cache = {}
local inflight = {}
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64Encode(data)
    if type(data) ~= "string" or data == "" then return nil end
    local parts = {}
    for i = 1, #data, 3 do
        local a = data:byte(i)
        local b = data:byte(i + 1) or 0
        local c = data:byte(i + 2) or 0
        local n = a * 65536 + b * 256 + c
        parts[#parts + 1] = b64chars:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
        parts[#parts + 1] = b64chars:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
        if i + 1 <= #data then
            parts[#parts + 1] = b64chars:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
        else
            parts[#parts + 1] = "="
        end
        if i + 2 <= #data then
            parts[#parts + 1] = b64chars:sub(n % 64 + 1, n % 64 + 1)
        else
            parts[#parts + 1] = "="
        end
    end
    return table.concat(parts)
end

local function reply(src, id, ok, b64)
    TriggerLatentClientEvent("gestion:mapTile:res", src, 200000, id, ok == true, b64)
end

RegisterNetEvent("gestion:mapTile:get", function(id, z, x, y)
    local src = source
    id = tonumber(id)
    z, x, y = tonumber(z), tonumber(x), tonumber(y)
    if not id or not z or not x or not y then
        reply(src, id or 0, false)
        return
    end
    z, x, y = math.floor(z), math.floor(x), math.floor(y)
    if z < 0 or z > 6 or x < -2 or y < -2 or x > 80 or y > 120 then
        reply(src, id, false)
        return
    end

    local key = ("%d/%d/%d"):format(z, x, y)
    if cache[key] then
        reply(src, id, true, cache[key])
        return
    end

    inflight[key] = inflight[key] or {}
    inflight[key][#inflight[key] + 1] = { src = src, id = id }
    if #inflight[key] > 1 then return end

    PerformHttpRequest(TILE_URL:format(z, x, y), function(status, body)
        local waiters = inflight[key] or {}
        inflight[key] = nil
        local b64 = nil
        if status == 200 and type(body) == "string" and #body > 200 then
            b64 = base64Encode(body)
        end
        if b64 then cache[key] = b64 end
        for i = 1, #waiters do
            reply(waiters[i].src, waiters[i].id, b64 ~= nil, b64)
        end
    end, "GET", "", {
        ["User-Agent"] = "Mozilla/5.0",
        ["Accept"] = "image/jpeg,image/*;q=0.8",
    })
end)
