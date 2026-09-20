--- Farm model

local function ShowJobNotification(content, isError)
    local societyImage = TriggerServerCallback("core:get:societyImage")
    local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or "Information"
    local notifType = isError and 'ROUGE' or 'JOB'
    VFW.ShowNotification({
        type = notifType,
        image = societyImage,
        title = jobLabel,
        subtitle = "Information",
        content = content
    })
end

local model <const> = JobModel.new("farm")
:setLabel("Farm")
:activateBuilder("craft")

RegisterNUICallback("bossPanel:clearFarmingLogs", function(data, cb)
    local deleted = TriggerServerCallback("core:farm:clearFarmingLogs")
    if not deleted then
        ShowJobNotification("Vous n'avez pas les permissions nécessaires.", false)
    end
    cb(deleted)
end)