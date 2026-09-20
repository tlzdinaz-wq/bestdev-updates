local ringCooldown = {}

RegisterNetEvent("society:doorbell:ring", function(jobName, doorbellId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if type(jobName) ~= "string" or jobName == "" then return end

    local id = tonumber(doorbellId)
    if not id then return end
    id = math.floor(id)

    local now = GetGameTimer()
    local last = ringCooldown[source]
    if last and (now - last) < 25000 then return end

    local doorbell = VFW.Society.GetDoorbell(jobName, id)
    if not doorbell then return end

    local coords = xPlayer.getCoords()
    local dx = coords.x - doorbell.x
    local dy = coords.y - doorbell.y
    local dz = coords.z - doorbell.z
    if (dx * dx + dy * dy + dz * dz) > 100.0 then return end

    ringCooldown[source] = now

    local society = VFW.Society.Get(jobName)
    local label = VFW.Society.GetLabel(jobName)
    local image = society and society.image or ""

    local notified = 0
    for target, other in pairs(VFW.Players) do
        if other.job and other.job.name == jobName and other.job.onDuty then
            TriggerClientEvent("vfw:showNotification", target, {
                type = "JOB",
                logo = image,
                image = image,
                title = label,
                subtitle = "Sonnette",
                content = doorbell.message,
                duration = 10,
            })
            notified = notified + 1
        end
    end

    TriggerClientEvent("society:doorbell:callerNotif", source, {
        image = image,
        label = label,
        message = doorbell.callerMessage,
    })

    console.debug(("[Society] Sonnette %d (%s) — %d employés notifiés"):format(id, jobName, notified))
end)

AddEventHandler("playerDropped", function()
    local source = source
    ringCooldown[source] = nil
end)
