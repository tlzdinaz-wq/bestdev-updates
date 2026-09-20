local active = false

local function getPlayerUwuCafeJob()
    if not VFW.PlayerData or not VFW.PlayerData.job or not VFW.PlayerData.job.onDuty then
        return nil
    end
    local jobName = VFW.PlayerData.job.name
    if UwuCafeConfig.Locations[jobName] then
        return jobName
    end
    return nil
end

local stations = {}

local function buildStations()
    stations = {}
    for jobName, loc in pairs(UwuCafeConfig.Locations) do
        if loc.Machine then
            for _, slotData in pairs(loc.Machine.slots) do
                table.insert(stations, { coords = slotData.pos, radius = loc.Machine.radius, label = "Appuyez sur ~INPUT_CONTEXT~ pour utiliser la ~b~Machine", jobName = jobName, action = function() UwuCafe_OpenMachine(jobName) end })
            end
        end
        if loc.CraftingTable then
            for _, slotData in pairs(loc.CraftingTable.slots) do
                table.insert(stations, { coords = slotData.pos, radius = loc.CraftingTable.radius, label = "Appuyez sur ~INPUT_CONTEXT~ pour utiliser le ~b~Plan de travail", jobName = jobName, action = function() UwuCafe_OpenCrafting(jobName) end })
            end
        end
        if loc.GranitaStation then
            for _, slotData in pairs(loc.GranitaStation.slots) do
                table.insert(stations, { coords = slotData.pos, radius = loc.GranitaStation.radius, label = "Appuyez sur ~INPUT_CONTEXT~ pour utiliser la ~b~Station Granita", jobName = jobName, action = function() UwuCafe_OpenGranita(jobName) end })
            end
        end
    end
end

local function startLoop()
    if active then return end
    active = true

    CreateThread(function()
        buildStations()

        while active do
            local sleep = 500
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local playerJob = getPlayerUwuCafeJob()

            for _, st in ipairs(stations) do
                if st.coords and st.jobName == playerJob and #(pos - st.coords) <= st.radius then
                    sleep = 0
                    VFW.ShowHelpNotification(st.label)

                    if VFW.Interact.JustPressed(0, 38) then
                        st.action()
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

local function stopLoop()
    active = false
end

RegisterNetEvent("vfw:setJob", function()
    Wait(500)
    if getPlayerUwuCafeJob() then
        startLoop()
    else
        stopLoop()
    end
end)

RegisterNetEvent("vfw:playerLoaded", function()
    while not VFW.PlayerData do
        Wait(1000)
    end
    while not VFW.PlayerData.job do
        Wait(1000)
    end

    if getPlayerUwuCafeJob() then
        startLoop()
    end
end)

RegisterNetEvent("vfw:client:changeDuty", function()
    Wait(200)
    if getPlayerUwuCafeJob() then
        startLoop()
    else
        stopLoop()
    end
end)

-- Reconstruit les stations après déplacement depuis le builder F10
AddEventHandler("restaurant_stations:rebuild", function()
    if active then buildStations() end
end)
