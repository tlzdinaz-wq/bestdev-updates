local BOOT_TIMEOUT = 120000
local BOOT_INTERVAL = 500
local WATCH_INTERVAL = 30000

local lastSignature = nil
local built = false

local function buildSignature()
    if type(Society) ~= "table" or type(Society.minifiedList) ~= "table" then
        return nil
    end

    local parts, n = {}, 0
    for name, soc in pairs(Society.minifiedList) do
        if type(soc) == "table" and (soc.type == "police" or soc.type == "milice") then
            n = n + 1
            parts[n] = ("%s=%s"):format(tostring(name), tostring(soc.type))
        end
    end

    table.sort(parts)
    return table.concat(parts, ";")
end

function VFW.RebuildPoliceJobsList(force)
    if type(BuildPoliceJobsList) ~= "function" then return false end
    if type(Society) ~= "table" or type(Society.minifiedList) ~= "table" then return false end

    local signature = buildSignature()
    if not force and built and signature == lastSignature then
        return true
    end

    local ok, err = pcall(BuildPoliceJobsList)
    if not ok then
        console.error(("[PoliceJobs] BuildPoliceJobsList a échoué : %s"):format(tostring(err)))
        return false
    end

    lastSignature = signature
    built = true

    return true
end

function VFW.ArePoliceJobsReady()
    return built
end

local function countList(list)
    local n = 0
    if type(list) == "table" then
        for _ in pairs(list) do n = n + 1 end
    end
    return n
end

AddEventHandler("core:society:jobsListDirty", function()
    VFW.RebuildPoliceJobsList(true)
end)

AddEventHandler("vfw:society:loaded", function()
    VFW.RebuildPoliceJobsList(true)
end)

AddEventHandler("vfw:society:updated", function()
    VFW.RebuildPoliceJobsList(true)
end)

AddEventHandler("core:playerloaded", function(playerId)
    local src = tonumber(playerId)
    if not src or not built then return end

    SetTimeout(2500, function()
        if not GetPlayerName(src) then return end
        TriggerClientEvent("police:receivePoliceJobsList", src, PoliceJobsList, MiliceJobsList, LawEnforcementJobsList)
    end)
end)

CreateThread(function()
    local waited = 0

    while waited < BOOT_TIMEOUT do
        if VFW.RebuildPoliceJobsList(true) then
            console.init("PoliceJobs", ("%d police / %d milice reconnus"):format(countList(PoliceJobsList), countList(MiliceJobsList)))
            break
        end

        Wait(BOOT_INTERVAL)
        waited = waited + BOOT_INTERVAL
    end

    if not built then
        console.warn("[PoliceJobs] 'Society.minifiedList' indisponible après 120 s : aucun job n'est reconnu comme police/milice")
    end

    while true do
        Wait(WATCH_INTERVAL)
        VFW.RebuildPoliceJobsList(false)
    end
end)
