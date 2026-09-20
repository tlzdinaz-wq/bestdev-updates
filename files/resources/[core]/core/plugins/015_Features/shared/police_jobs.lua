-- ============================================================
-- POLICE / MILICE / LAW ENFORCEMENT JOBS
-- A job is "police" if Society.type == "police"
-- A job is "milice" if Society.type == "milice"
-- A job is "law enforcement" if it is police OR milice
-- ============================================================

PoliceJobsList = {}
MiliceJobsList = {}
LawEnforcementJobsList = {}

local listeners = {}

---@param cb fun(police: table<string, boolean>, milice: table<string, boolean>, lawEnforcement: table<string, boolean>)
function OnPoliceJobsListChange(cb)
    if type(cb) ~= "function" then return end
    listeners[#listeners + 1] = cb
    if next(PoliceJobsList) or next(MiliceJobsList) then
        local ok, err = pcall(cb, PoliceJobsList, MiliceJobsList, LawEnforcementJobsList)
        if not ok then console.error("[Core:PoliceJobs] listener error: " .. tostring(err)) end
    end
end

local function NotifyListeners()
    for i = 1, #listeners do
        local ok, err = pcall(listeners[i], PoliceJobsList, MiliceJobsList, LawEnforcementJobsList)
        if not ok then console.error("[Core:PoliceJobs] listener error: " .. tostring(err)) end
    end
end

---@return string[]
function GetPoliceJobsArray()
    local out = {}
    for jobName in pairs(PoliceJobsList) do out[#out + 1] = jobName end
    return out
end

---@return string[]
function GetMiliceJobsArray()
    local out = {}
    for jobName in pairs(MiliceJobsList) do out[#out + 1] = jobName end
    return out
end

---@return string[]
function GetLawEnforcementJobsArray()
    local out = {}
    for jobName in pairs(LawEnforcementJobsList) do out[#out + 1] = jobName end
    return out
end

---@param jobName string
---@return boolean
function IsPoliceJob(jobName)
    if not jobName then return false end
    if PoliceJobsList[jobName] == true then return true end
    if VFW and VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name == jobName then
        if Society and Society.data and Society.data.type == "police" then return true end
        if VFW.PlayerData.job.type == "police" then return true end
    end
    return false
end

---@param jobName string
---@return boolean
function IsMiliceJob(jobName)
    if not jobName then return false end
    if MiliceJobsList[jobName] == true then return true end
    if VFW and VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name == jobName then
        if Society and Society.data and Society.data.type == "milice" then return true end
        if VFW.PlayerData.job.type == "milice" then return true end
    end
    return false
end

---@param jobName string
---@return boolean
function IsLawEnforcementJob(jobName)
    if not jobName then return false end
    if LawEnforcementJobsList[jobName] == true then return true end
    return IsPoliceJob(jobName) or IsMiliceJob(jobName)
end

if IsDuplicityVersion() then
    -- ========== SERVER ==========

    function BuildPoliceJobsList()
        for k in pairs(PoliceJobsList) do PoliceJobsList[k] = nil end
        for k in pairs(MiliceJobsList) do MiliceJobsList[k] = nil end
        for k in pairs(LawEnforcementJobsList) do LawEnforcementJobsList[k] = nil end

        if not Society or not Society.minifiedList then return end

        for name, soc in pairs(Society.minifiedList) do
            if type(soc) == "table" then
                if soc.type == "police" then
                    PoliceJobsList[name] = true
                    LawEnforcementJobsList[name] = true
                elseif soc.type == "milice" then
                    MiliceJobsList[name] = true
                    LawEnforcementJobsList[name] = true
                end
            end
        end

        NotifyListeners()
        TriggerClientEvent("police:receivePoliceJobsList", -1, PoliceJobsList, MiliceJobsList, LawEnforcementJobsList)
    end

    RegisterNetEvent("police:requestPoliceJobsList", function()
        TriggerClientEvent("police:receivePoliceJobsList", source, PoliceJobsList, MiliceJobsList, LawEnforcementJobsList)
    end)

else
    -- ========== CLIENT ==========

    RegisterNetEvent("police:receivePoliceJobsList", function(police, milice, lawEnforcement)
        if police then
            for k in pairs(PoliceJobsList) do PoliceJobsList[k] = nil end
            for k, v in pairs(police) do PoliceJobsList[k] = v end
        end
        if milice then
            for k in pairs(MiliceJobsList) do MiliceJobsList[k] = nil end
            for k, v in pairs(milice) do MiliceJobsList[k] = v end
        end
        if lawEnforcement then
            for k in pairs(LawEnforcementJobsList) do LawEnforcementJobsList[k] = nil end
            for k, v in pairs(lawEnforcement) do LawEnforcementJobsList[k] = v end
        else
            for k in pairs(LawEnforcementJobsList) do LawEnforcementJobsList[k] = nil end
            for k, v in pairs(PoliceJobsList) do LawEnforcementJobsList[k] = v end
            for k, v in pairs(MiliceJobsList) do LawEnforcementJobsList[k] = v end
        end
        NotifyListeners()
    end)

    RegisterNetEvent("vfw:playerReady", function()
        CreateThread(function()
            Wait(2000)
            TriggerServerEvent("police:requestPoliceJobsList")
        end)
    end)

    RegisterNetEvent("core:retrieve:societyData", function()
        CreateThread(function()
            Wait(500)
            TriggerServerEvent("police:requestPoliceJobsList")
        end)
    end)
end
