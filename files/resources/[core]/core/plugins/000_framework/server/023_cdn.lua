VFW.CDN = VFW.CDN or {}

local API_URL = GetConvar("core_cdn_api_url", "")
local API_TOKEN = GetConvar("core_cdn_token", "")
local API_TIMEOUT = 15000

local function apiBase()
    if API_URL ~= "" then
        return (API_URL:gsub("/+$", ""))
    end
    return (VFW.CDN_BASE:gsub("/+$", "")) .. "/api"
end

local function isConfigured()
    return API_TOKEN ~= "" or API_URL ~= ""
end

local function headers(extra)
    local out = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
        ["User-Agent"] = "VFW-CDN/1.0",
    }
    if API_TOKEN ~= "" then
        out["Authorization"] = "Bearer " .. API_TOKEN
    end
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            out[k] = v
        end
    end
    return out
end

local function normalizePath(path)
    if type(path) ~= "string" then return nil end
    path = path:gsub("\\", "/"):gsub("^/+", ""):gsub("%.%./", "")
    if path == "" then return nil end
    return path
end

local function decodeBody(body)
    if type(body) ~= "string" or body == "" then return nil end
    local ok, decoded = pcall(json.decode, body)
    if ok and type(decoded) == "table" then return decoded end
    return nil
end

local function request(method, endpoint, payload, cb)
    local url = ("%s/%s"):format(apiBase(), endpoint)
    local body = payload and json.encode(payload) or ""

    if not isConfigured() then
        console.warn("[CDN] core_cdn_api_url / core_cdn_token non configures : requete ignoree.")
        if cb then cb(false, nil, 0) end
        return
    end

    local answered = false
    local function answer(ok, data, status)
        if answered then return end
        answered = true
        if cb then cb(ok, data, status) end
    end

    PerformHttpRequest(url, function(status, responseBody)
        answer(status >= 200 and status < 300, decodeBody(responseBody) or responseBody, status)
    end, method, body, headers())

    SetTimeout(API_TIMEOUT, function()
        if not answered then
            console.error(("[CDN] timeout sur %s %s"):format(method, url))
            answer(false, nil, 0)
        end
    end)
end

local function await(fn)
    local p = promise.new()
    fn(function(...)
        p:resolve(table.pack(...))
    end)
    local packed = Citizen.Await(p)
    return table.unpack(packed, 1, packed.n)
end

function VFW.CDN.Upload(path, data, cb)
    path = normalizePath(path)
    if not path then
        if cb then cb(false, "invalid_path") end
        return false, "invalid_path"
    end

    local payload = { path = path }

    if type(data) == "table" then
        payload.data = data.base64 or data.data
        payload.contentType = data.contentType or data.mime
        payload.url = data.url
    elseif type(data) == "string" then
        if data:sub(1, 5) == "http:" or data:sub(1, 6) == "https:" then
            payload.url = data
        else
            payload.data = data
        end
    end

    if not payload.data and not payload.url then
        if cb then cb(false, "no_payload") end
        return false, "no_payload"
    end

    local function run(done)
        request("POST", "upload", payload, function(ok, body)
            local url = nil
            if ok then
                url = (type(body) == "table" and (body.url or body.location)) or VFW.CdnUrl(path)
            end
            done(ok, url or (type(body) == "table" and body.error) or nil)
        end)
    end

    if cb then
        run(cb)
        return true
    end

    return await(run)
end

function VFW.CDN.Delete(path, cb)
    path = normalizePath(path)
    if not path then
        if cb then cb(false, "invalid_path") end
        return false, "invalid_path"
    end

    local function run(done)
        request("POST", "delete", { path = path }, function(ok, body)
            done(ok, ok and path or (type(body) == "table" and body.error) or nil)
        end)
    end

    if cb then
        run(cb)
        return true
    end

    return await(run)
end

function VFW.CDN.List(prefix, cb)
    if type(prefix) ~= "string" then prefix = "" end
    prefix = prefix:gsub("\\", "/"):gsub("^/+", ""):gsub("%.%./", "")

    local function run(done)
        request("POST", "list", { prefix = prefix }, function(ok, body)
            if not ok then
                done(false, {})
                return
            end

            local files = {}
            if type(body) == "table" then
                local source = body.files or body.items or body
                if type(source) == "table" then
                    for i = 1, #source do
                        local entry = source[i]
                        if type(entry) == "string" then
                            files[#files + 1] = { path = entry, url = VFW.CdnUrl(entry) }
                        elseif type(entry) == "table" then
                            local p = entry.path or entry.name or entry.key
                            files[#files + 1] = {
                                path = p,
                                url = entry.url or (p and VFW.CdnUrl(p)) or nil,
                                size = tonumber(entry.size) or 0,
                                modified = entry.modified or entry.lastModified,
                            }
                        end
                    end
                end
            end
            done(true, files)
        end)
    end

    if cb then
        run(cb)
        return true
    end

    return await(run)
end

function VFW.CDN.IsConfigured()
    return isConfigured()
end

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not isConfigured() then
        console.warn("[CDN] Upload/Delete/List desactives : definissez core_cdn_api_url et core_cdn_token.")
    else
        console.init("CDN", ("API %s"):format(apiBase()))
    end
end)
