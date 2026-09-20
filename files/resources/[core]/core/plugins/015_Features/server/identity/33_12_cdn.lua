local apiUrl = GetConvar("core_cdn_api_url", "")
local apiKey = GetConvar("core_cdn_api_key", "")

local function cdnBase()
    local base = GetConvar("core_cdn_public_base", "")
    if base ~= "" then return base end
    if BRANDING and BRANDING.cdnBase then return BRANDING.cdnBase end
    return ""
end

local function isConnected(source)
    if VFW.GetPlayerFromId(source) then return true end
    if VFW.GetPendingAccount and VFW.GetPendingAccount(source) then return true end
    return false
end

RegisterServerCallback("vfw:server:getCdnConfig", function(source)
    if not isConnected(source) then return {} end
    if apiUrl == "" or apiKey == "" then return {} end

    return {
        apiUrl = apiUrl,
        apiKey = apiKey,
        cdnBase = cdnBase(),
    }
end)

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if apiUrl == "" or apiKey == "" then
        console.warn("[identity] convars core_cdn_api_url / core_cdn_api_key absentes : l'upload CDN (vêtements, véhicules) est desactive")
    end
end)

VFW.FiveManage = VFW.FiveManage or {}

local warnedMissingKey = false
local lastMugshotUploadAt = {}
local MUGSHOT_MAX_B64 = 2500000
local MUGSHOT_RATE_SECONDS = 2

function VFW.FiveManage.ApiKey()
    local keys = {
        GetConvar("FIVEMANAGE_MEDIA_API_KEY", ""),
        GetConvar("fivemanage:key", ""),
        GetConvar("core_fivemanage_media_key", ""),
    }
    for i = 1, #keys do
        if type(keys[i]) == "string" and keys[i] ~= "" then
            return keys[i]
        end
    end
    return nil
end

local function mugshotFolder()
    local folder = GetConvar("core_fivemanage_mugshot_path", "")
    if type(folder) == "string" and folder ~= "" then
        return folder:gsub("^/+", ""):gsub("/+$", "")
    end
    local root = GetConvar("core_fivemanage_path", "")
    if type(root) == "string" and root ~= "" then
        return (root:gsub("^/+", ""):gsub("/+$", "")) .. "/mugshots"
    end
    return "mugshots"
end

local function extractFiveManageUrl(decoded)
    if type(decoded) ~= "table" then return nil end
    local data = decoded.data
    if type(data) == "table" and type(data.url) == "string" and data.url:match("^https://") then
        return data.url
    end
    if type(decoded.url) == "string" and decoded.url:match("^https://") then
        return decoded.url
    end
    if type(data) == "string" and data:match("^https://") then
        return data
    end
    return nil
end

function VFW.FiveManage.UploadBase64(base64, filename, folder)
    local key = VFW.FiveManage.ApiKey()
    if not key then
        if not warnedMissingKey then
            warnedMissingKey = true
            console.error("[FiveManage] Clé absente : définis FIVEMANAGE_MEDIA_API_KEY, fivemanage:key ou core_fivemanage_media_key pour uploader les mugshots.")
        end
        return nil
    end

    if type(base64) ~= "string" or base64 == "" then
        return nil
    end
    if not base64:match("^data:") then
        base64 = "data:image/png;base64," .. base64
    end

    local payload = json.encode({
        base64 = base64,
        filename = filename or ("mugshot_" .. os.time() .. ".png"),
        path = folder or mugshotFolder(),
    })

    local p = promise.new()
    local done = false
    PerformHttpRequest("https://api.fivemanage.com/api/v3/file/base64", function(status, body)
        if done then return end
        done = true
        if status ~= 200 and status ~= 201 then
            console.error(("[FiveManage] Upload mugshot HTTP %s: %s"):format(tostring(status), tostring(body)))
            p:resolve(nil)
            return
        end
        local ok, decoded = pcall(json.decode, body or "")
        p:resolve(ok and extractFiveManageUrl(decoded) or nil)
    end, "POST", payload, {
        ["Content-Type"] = "application/json",
        ["Authorization"] = key,
        ["Accept"] = "application/json",
    })

    SetTimeout(20000, function()
        if done then return end
        done = true
        console.error("[FiveManage] Upload mugshot timeout (20s).")
        p:resolve(nil)
    end)

    return Citizen.Await(p)
end

RegisterNetEvent("vfw:server:uploadMugshot", function(reqId, data)
    local src = source
    reqId = tonumber(reqId)

    local function reply(url)
        if not reqId then return end
        TriggerClientEvent("vfw:client:mugshotUploaded", src, reqId, url or "")
    end

    if not reqId then return end
    if type(data) ~= "string" or #data < 32 or #data > MUGSHOT_MAX_B64 then
        reply("")
        return
    end
    if not data:find("data:image/", 1, true) then
        reply("")
        return
    end

    local now = os.time()
    if lastMugshotUploadAt[src] and (now - lastMugshotUploadAt[src]) < MUGSHOT_RATE_SECONDS then
        reply("")
        return
    end
    lastMugshotUploadAt[src] = now

    local filename = ("mugshot_%d_%d.png"):format(src, now)
    reply(VFW.FiveManage.UploadBase64(data, filename, mugshotFolder()) or "")
end)

AddEventHandler("playerDropped", function()
    lastMugshotUploadAt[source] = nil
end)
