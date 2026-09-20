local active = false

local function getPlayerPizzeriaJob()
    if not VFW.PlayerData or not VFW.PlayerData.job or not VFW.PlayerData.job.onDuty then
        return nil
    end
    local jobName = VFW.PlayerData.job.name
    if PizzeriaConfig.Locations[jobName] then
        return jobName
    end
    return nil
end

local stations = {}

local function buildStations()
    stations = {}
    for jobName, loc in pairs(PizzeriaConfig.Locations) do
        if loc.OvenStation then
            table.insert(stations, { coords = loc.OvenStation.center, radius = loc.OvenStation.radius, label = "Appuyez sur ~INPUT_CONTEXT~ pour utiliser le ~b~Four", jobName = jobName, action = function() Pizzeria_StartCooking("oven", jobName) end })
        end
        if loc.FryerStation then
            table.insert(stations, { coords = loc.FryerStation.center, radius = loc.FryerStation.radius, label = "Appuyez sur ~INPUT_CONTEXT~ pour utiliser la ~b~Friteuse", jobName = jobName, action = function() Pizzeria_StartCooking("fryer", jobName) end })
        end
        if loc.Machine then
            table.insert(stations, { coords = loc.Machine.coords, radius = loc.Machine.radius, label = "Appuyez sur ~INPUT_CONTEXT~ pour utiliser la ~b~Machine à boissons", jobName = jobName, action = function() Pizzeria_OpenMachine(jobName) end })
        end
        if loc.CraftingTable then
            for _, slotData in pairs(loc.CraftingTable.slots) do
                table.insert(stations, { coords = slotData.pos, radius = loc.CraftingTable.radius, label = "Appuyez sur ~INPUT_CONTEXT~ pour utiliser la ~b~Table de préparation", jobName = jobName, action = function() Pizzeria_OpenCrafting(jobName) end })
            end
        end
        if loc.MilkshakeStation then
            for _, slotData in pairs(loc.MilkshakeStation.slots) do
                table.insert(stations, { coords = slotData.pos, radius = loc.MilkshakeStation.radius, label = "Appuyez sur ~INPUT_CONTEXT~ pour utiliser la ~b~Station Milkshake", jobName = jobName, action = function() Pizzeria_OpenMilkshake(jobName) end })
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
            local playerJob = getPlayerPizzeriaJob()

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
    if getPlayerPizzeriaJob() then
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

    if getPlayerPizzeriaJob() then
        startLoop()
    end
end)

RegisterNetEvent("vfw:client:changeDuty", function()
    Wait(200)
    if getPlayerPizzeriaJob() then
        startLoop()
    else
        stopLoop()
    end
end)

-- Reconstruit les stations après déplacement depuis le builder F10
AddEventHandler("restaurant_stations:rebuild", function()
    if active then buildStations() end
end)
