---@meta _
---@diagnostic disable: duplicate-doc-field

-- Les images HTTPS sont bloquées dans le NUI. Les tuiles arrivent via event serveur.

local pending = {}
local nextId = 0
local cache = {}

local function validCoords(z, x, y)
    z, x, y = tonumber(z), tonumber(x), tonumber(y)
    if not z or not x or not y then return nil end
    z, x, y = math.floor(z + 0.0), math.floor(x + 0.0), math.floor(y + 0.0)
    if z < 0 or z > 6 or x < -2 or y < -2 then return nil end
    if x > 80 or y > 120 then return nil end
    return z, x, y
end

RegisterNetEvent("gestion:mapTile:res", function(id, ok, b64)
    local cb = pending[id]
    pending[id] = nil
    if type(cb) ~= "function" then return end
    if ok and type(b64) == "string" and b64 ~= "" then
        cb({ ok = true, b64 = b64 })
        return
    end
    cb({ ok = false })
end)

RegisterNuiCallback("gestion:mapTile", function(data, cb)
    if type(data) ~= "table" then
        cb({ ok = false })
        return
    end
    local z, x, y = validCoords(data.z, data.x, data.y)
    if not z then
        cb({ ok = false })
        return
    end
    local key = ("%d/%d/%d"):format(z, x, y)
    if cache[key] then
        cb({ ok = true, b64 = cache[key] })
        return
    end
    nextId = nextId + 1
    local id = nextId
    pending[id] = function(res)
        if res and res.ok and res.b64 then
            cache[key] = res.b64
        end
        cb(res)
    end
    TriggerServerEvent("gestion:mapTile:get", id, z, x, y)
    SetTimeout(18000, function()
        local leftover = pending[id]
        if leftover then
            pending[id] = nil
            leftover({ ok = false })
        end
    end)
end)
