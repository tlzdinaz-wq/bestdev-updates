---@meta _
---@diagnostic disable: duplicate-doc-field

---@class JobInfo
JobInfo = {}

---@param name string
---@param label string
---@param grades any
---@param typeJob any
-- RegisterNetEvent("core:jobs:newJob", function(name, label, grades, typeJob)
--     -- Event handler code here
-- end)

--- .ChangeDuty
---@param state any
function VFW.ChangeDuty(state)
    VFW.PlayerData.job.onDuty = state
    TriggerServerEvent("vfw:changeDuty", state)
end

---Load VFW.MyJob
function VFW.LoadMyJob()
    TriggerEvent(("core:loadjob:%s"):format(VFW.PlayerData.job.name))
end

RegisterNetEvent("vfw:playerReady", function()
    VFW.LoadMyJob()
end)

---@param Job table Job data
RegisterNetEvent("vfw:setJob", function(Job)
    VFW.SetPlayerData("job", Job)
    VFW.LoadMyJob()
end)
