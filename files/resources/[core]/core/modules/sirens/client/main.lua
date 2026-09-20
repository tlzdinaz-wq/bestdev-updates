if MENTA_SERVER ~= 'FR' then return end

VehicleData = {}
NuiShowed = false
NuiLightHouseState = false

CreateThread(function()
    while not RequestScriptAudioBank("dlc_clem/clem", false) do
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        local sleep = 600
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

        DistantCopCarSirens(false)

        if NuiShowed then
            if IsPlayerIsInVehicle(vehicle, true) then
                sleep = 0

                DisableControlAction(0, 85, true)
                DisableControlAction(0, 86, true)
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 600
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

        if not NuiShowed then
            if IsVehicleAllowed(vehicle) then
                if NetworkGetEntityIsNetworked(vehicle) then
                    VehicleData[tostring(VehToNet(vehicle))] = VehicleData[tostring(VehToNet(vehicle))] or {}

                    local _, lightsState = GetVehicleLightsState(vehicle)

                    NuiLightHouseState = lightsState == 1

                    NuiLightHouse(NuiLightHouseState)

                    if VehicleData[tostring(VehToNet(vehicle))].siren then
                        NuiSiren(true)

                        if VehicleData[tostring(VehToNet(vehicle))].siren == "02" then
                            NuiNightSiren(true)
                        else
                            NuiNightSiren(false)
                        end
                    else
                        NuiSiren(false)
                        NuiNightSiren(false)
                    end

                    if VehicleData[tostring(VehToNet(vehicle))].flashingLight then
                        NuiFlashingLight(true)
                    else
                        NuiFlashingLight(false)
                    end

                    if VehicleData[tostring(VehToNet(vehicle))].extra then
                        if VehicleData[tostring(VehToNet(vehicle))].extra == 1 then
                            NuiBanisterLeft(true)
                            NuiBanisterCenter(false)
                            NuiBanisterRight(false)
                        elseif VehicleData[tostring(VehToNet(vehicle))].extra == 2 then
                            NuiBanisterLeft(false)
                            NuiBanisterCenter(true)
                            NuiBanisterRight(false)
                        elseif VehicleData[tostring(VehToNet(vehicle))].extra == 3 then
                            NuiBanisterLeft(false)
                            NuiBanisterCenter(false)
                            NuiBanisterRight(true)
                        end
                    else
                        NuiBanisterLeft(false)
                        NuiBanisterCenter(false)
                        NuiBanisterRight(false)
                    end

                    if VehicleData[tostring(VehToNet(vehicle))].projector then
                        NuiLight(true)
                    else
                        NuiLight(false)
                    end

                    NuiShow(true)

                    NuiShowed = true
                end
            end
        end

        if NuiShowed then
            local _, lightsState = GetVehicleLightsState(vehicle)

            if lightsState == 1 then
                if not NuiLightHouseState then
                    NuiLightHouse(true)

                    NuiLightHouseState = true
                end
            elseif lightsState == 0 then
                if NuiLightHouseState then
                    NuiLightHouse(false)

                    NuiLightHouseState = false
                end
            end

            if vehicle == 0 then
                NuiShow(false)

                NuiShowed = false
            else
                if GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then
                    if GetPedInVehicleSeat(vehicle, 0) ~= PlayerPedId() then
                        NuiShow(false)

                        NuiShowed = false
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterKeyMapping("siren-01", "Siren 01", "keyboard", "1")
RegisterKeyMapping("siren-02", "Siren 02", "keyboard", "2")
RegisterKeyMapping("siren-03", "Siren 03", "keyboard", "3")

RegisterCommand("siren-01", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if IsVehicleAllowed(vehicle) then
        local currentSiren = VehicleData[tostring(VehToNet(vehicle))]
            and VehicleData[tostring(VehToNet(vehicle))].flashingLight
            and VehicleData[tostring(VehToNet(vehicle))].siren
            or nil

        if currentSiren == "01" then
            TriggerServerEvent("broadcast:siren:stop", VehToNet(vehicle))
        else
            TriggerServerEvent("broadcast:siren:start", VehToNet(vehicle), "01")
        end
    end
end, false)

RegisterCommand("siren-02", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if IsVehicleAllowed(vehicle) then
        local currentSiren = VehicleData[tostring(VehToNet(vehicle))]
            and VehicleData[tostring(VehToNet(vehicle))].flashingLight
            and VehicleData[tostring(VehToNet(vehicle))].siren
            or nil

        if currentSiren == "02" then
            TriggerServerEvent("broadcast:siren:stop", VehToNet(vehicle))
        else
            TriggerServerEvent("broadcast:siren:start", VehToNet(vehicle), "02")
        end
    end
end, false)

RegisterCommand("siren-03", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if IsVehicleAllowed(vehicle) then
        local currentSiren = VehicleData[tostring(VehToNet(vehicle))]
            and VehicleData[tostring(VehToNet(vehicle))].flashingLight
            and VehicleData[tostring(VehToNet(vehicle))].siren
            or nil

        if currentSiren == "03" then
            TriggerServerEvent("broadcast:siren:stop", VehToNet(vehicle))
        else
            TriggerServerEvent("broadcast:siren:start", VehToNet(vehicle), "03")
        end
    end
end, false)

RegisterKeyMapping("flashingLight", "Flashing Light", "keyboard", "LMENU")

RegisterCommand("flashingLight", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if IsVehicleAllowed(vehicle) then
        local enabled = VehicleData[tostring(VehToNet(vehicle))]
            and VehicleData[tostring(VehToNet(vehicle))].flashingLight
            or nil

        if enabled then
            TriggerServerEvent("broadcast:flashingLight:stop", VehToNet(vehicle))
        else
            TriggerServerEvent("broadcast:flashingLight:start", VehToNet(vehicle))
        end
    end
end, false)

RegisterKeyMapping("extra-01", "Extra 01", "keyboard", "4")
RegisterKeyMapping("extra-02", "Extra 02", "keyboard", "5")
RegisterKeyMapping("extra-03", "Extra 03", "keyboard", "6")

RegisterCommand("extra-01", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if IsVehicleAllowed(vehicle) then
        local currentExtra = VehicleData[tostring(VehToNet(vehicle))]
            and VehicleData[tostring(VehToNet(vehicle))].flashingLight
            and VehicleData[tostring(VehToNet(vehicle))].extra
            or nil

        if currentExtra == 1 then
            TriggerServerEvent("broadcast:extra:stop", VehToNet(vehicle))
        else
            TriggerServerEvent("broadcast:extra:start", VehToNet(vehicle), 1)
        end
    end
end, false)

RegisterCommand("extra-02", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if IsVehicleAllowed(vehicle) then
        local currentExtra = VehicleData[tostring(VehToNet(vehicle))]
            and VehicleData[tostring(VehToNet(vehicle))].flashingLight
            and VehicleData[tostring(VehToNet(vehicle))].extra
            or nil

        if currentExtra == 2 then
            TriggerServerEvent("broadcast:extra:stop", VehToNet(vehicle))
        else
            TriggerServerEvent("broadcast:extra:start", VehToNet(vehicle), 2)
        end
    end
end, false)

RegisterCommand("extra-03", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if IsVehicleAllowed(vehicle) then
        local currentExtra = VehicleData[tostring(VehToNet(vehicle))]
            and VehicleData[tostring(VehToNet(vehicle))].flashingLight
            and VehicleData[tostring(VehToNet(vehicle))].extra
            or nil

        if currentExtra == 3 then
            TriggerServerEvent("broadcast:extra:stop", VehToNet(vehicle))
        else
            TriggerServerEvent("broadcast:extra:start", VehToNet(vehicle), 3)
        end
    end
end, false)

RegisterKeyMapping("projector", "Projector", "keyboard", "7")

RegisterCommand("projector", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false)) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if IsVehicleAllowed(vehicle) then
        local enabled = VehicleData[tostring(VehToNet(vehicle))]
            and VehicleData[tostring(VehToNet(vehicle))].flashingLight
            and VehicleData[tostring(VehToNet(vehicle))].projector
            or nil

        if enabled then
            TriggerServerEvent("broadcast:projector:stop", VehToNet(vehicle))
        else
            TriggerServerEvent("broadcast:projector:start", VehToNet(vehicle))
        end
    end
end, false)

RegisterKeyMapping("+horn", "Horn", "keyboard", "E")

RegisterCommand("+horn", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false), true) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    TriggerServerEvent("broadcast:horn:start", VehToNet(vehicle))
end, false)

RegisterCommand("-horn", function()
    if not IsPlayerIsInVehicle(GetVehiclePedIsIn(PlayerPedId(), false), true) then
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    TriggerServerEvent("broadcast:horn:stop", VehToNet(vehicle))
end, false)

function splitString(inputString, separator)
    separator = separator or "%s"

    local parts = {}
    local index = 1

    for token in string.gmatch(inputString, "([^" .. separator .. "]+)") do
        parts[index] = token
        index = index + 1
    end

    return parts
end

local function startsWith(text, prefix)
    return text:sub(1, #prefix) == prefix
end

Citizen.CreateThread(function()
    local resourceName = GetCurrentResourceName()
    local fileContent = LoadResourceFile(resourceName, "modules/sirens/visualsettings.dat")
    local lines = splitString(fileContent, "\n")

    for _, line in ipairs(lines) do
        line = line:gsub("%s+", " ")

        if not startsWith(line, "#") and not startsWith(line, "//") and line:match("%S") then
            local parts = splitString(line, " ")
            local settingName = parts[1]
            local settingValue = tonumber(parts[2])

            if settingName and settingValue and settingName ~= "weather.CycleDuration" then
                Citizen.InvokeNative(GetHashKey("SET_VISUAL_SETTING_FLOAT") & 4294967295, settingName, settingValue + 0.0)
            end
        end
    end
end)
