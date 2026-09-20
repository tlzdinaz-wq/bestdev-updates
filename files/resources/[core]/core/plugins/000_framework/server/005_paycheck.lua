local lastActivity = {}

RegisterNetEvent("vfw:paycheck:activity", function()
    local source = source
    lastActivity[source] = os.time()
end)

AddEventHandler("vfw:characterLoaded", function(source)
    lastActivity[source] = os.time()
end)

AddEventHandler("playerDropped", function()
    local source = source
    lastActivity[source] = nil
end)

local function payPlayer(xPlayer)
    local salary = xPlayer.job.grade_salary or 0
    if salary <= 0 then return end

    if not xPlayer.job.onDuty then
        salary = math.floor(salary * (Config.OffDutyPaycheckMultiplier or 0.5))
    end

    if salary <= 0 then return end

    xPlayer.addAccountMoney("bank", salary, "paycheck")
    xPlayer.showNotification({
        type = "VERT",
        content = ("Vous avez reçu votre salaire : $%d"):format(salary),
    })
end

CreateThread(function()
    local interval = Config.PaycheckInterval or (15 * 60000)
    while true do
        Wait(interval)
        for source, xPlayer in pairs(VFW.Players) do
            local last = lastActivity[source]
            if last and (os.time() - last) < (interval / 1000) * 2 then
                payPlayer(xPlayer)
            end
        end
    end
end)

RegisterNetEvent("core:playerTimer:start", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    xPlayer.sessionStart = os.time()
end)

AddEventHandler("vfw:playerDropped", function(source, xPlayer)
    if not xPlayer.sessionStart then return end
    local elapsed = os.time() - xPlayer.sessionStart
    if elapsed <= 0 then return end
    MySQL.update("UPDATE users SET playtime = playtime + ?, last_seen = NOW() WHERE id = ?", { elapsed, xPlayer.accountId })
end)
