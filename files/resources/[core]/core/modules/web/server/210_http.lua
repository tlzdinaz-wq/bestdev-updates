local DEFAULT_TIMEOUT = 10000

Web = Web or {}

local function normalizeHeaders(headers)
    local out = {}

    if type(headers) == "table" then
        for key, value in pairs(headers) do
            if type(key) == "string" then
                out[key] = tostring(value)
            end
        end
    end

    return out
end

local function normalizeBody(body, headers)
    if body == nil then return "" end

    if type(body) == "string" then
        return body
    end

    if type(body) == "table" then
        local ok, encoded = pcall(json.encode, body)
        if not ok or type(encoded) ~= "string" then
            return ""
        end

        if not headers["Content-Type"] and not headers["content-type"] then
            headers["Content-Type"] = "application/json"
        end

        return encoded
    end

    return tostring(body)
end

function Web.Request(method, url, body, headers, cb)
    if type(url) ~= "string" or url == "" then
        if type(cb) == "function" then cb(0, nil, {}) end
        return false
    end

    if url:sub(1, 4) ~= "http" then
        console.warn(("[Web] URL rejetée (schéma non http) : %s"):format(url))
        if type(cb) == "function" then cb(0, nil, {}) end
        return false
    end

    method = type(method) == "string" and method:upper() or "GET"

    local finalHeaders = normalizeHeaders(headers)
    local finalBody = normalizeBody(body, finalHeaders)

    PerformHttpRequest(url, function(status, text, responseHeaders)
        if type(cb) ~= "function" then return end

        local ok, err = pcall(cb, status, text, responseHeaders or {})
        if not ok then
            console.error(("[Web] callback HTTP en erreur (%s) : %s"):format(url, tostring(err)))
        end
    end, method, finalBody, finalHeaders)

    return true
end

function Web.Get(url, cb, headers)
    return Web.Request("GET", url, nil, headers, cb)
end

function Web.Post(url, body, cb, headers)
    return Web.Request("POST", url, body, headers, cb)
end

function Web.Await(method, url, body, headers, timeout)
    timeout = tonumber(timeout) or DEFAULT_TIMEOUT

    local p = promise.new()
    local resolved = false

    local started = Web.Request(method, url, body, headers, function(status, text, responseHeaders)
        if resolved then return end
        resolved = true
        p:resolve({ status = status, body = text, headers = responseHeaders })
    end)

    if not started then
        return { status = 0, body = nil, headers = {} }
    end

    SetTimeout(timeout, function()
        if resolved then return end
        resolved = true
        console.warn(("[Web] timeout HTTP après %d ms : %s"):format(timeout, tostring(url)))
        p:resolve({ status = 0, body = nil, headers = {} })
    end)

    return Citizen.Await(p)
end

function Web.GetJson(url, headers, timeout)
    local response = Web.Await("GET", url, nil, headers, timeout)

    if response.status ~= 200 or type(response.body) ~= "string" then
        return nil, response.status
    end

    local ok, decoded = pcall(json.decode, response.body)
    if not ok then
        return nil, response.status
    end

    return decoded, response.status
end

function Web.PostJson(url, body, headers, timeout)
    local response = Web.Await("POST", url, body, headers, timeout)

    if type(response.body) ~= "string" or response.body == "" then
        return nil, response.status
    end

    local ok, decoded = pcall(json.decode, response.body)
    if not ok then
        return nil, response.status
    end

    return decoded, response.status
end

VFW.Web = Web

exports("httpRequest", function(method, url, body, headers)
    return Web.Await(method, url, body, headers)
end)
