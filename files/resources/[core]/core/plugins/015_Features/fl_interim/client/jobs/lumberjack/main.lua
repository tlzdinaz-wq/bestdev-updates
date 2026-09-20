local LumberjackConfig = {}
local POS
local vehicleMenu

local function v3(p)
    if not p then return nil end
    if type(p) == "vector3" then return p end
    if type(p) == "table" and p.x and p.y and p.z then
        return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0)
    end
    return nil
end

local function v4(p)
    if not p then return nil end
    if type(p) == "vector4" then return p end
    if type(p) == "table" and p.x and p.y and p.z and p.w then
        return vector4(p.x + 0.0, p.y + 0.0, p.z + 0.0, p.w + 0.0)
    end
    return nil
end

local function fetchPositions()
    if POS then return POS end
    local t = TriggerServerCallback("interim:lumberjack:getPositionsAll")
    if not t or type(t) ~= "table" then return nil end

    local out = {}
    out.startplace         = v3(t.startplace)
    out.startplacenpc      = v3(t.startplacenpc)
    out.startplace_npcheading = tonumber(t.startplace_npcheading) or 0.0
    out.startplace_radius  = tonumber(t.startplace_radius) or 2.0
    out.returnpoint        = v3(t.returnPoint)
    out.returnpoint_radius = tonumber(t.returnPoint_radius) or 3.0
    if type(t.truckSpots) == "table" then
        out.spawnPlaces = {}
        for i, p in ipairs(t.truckSpots) do
            out.spawnPlaces[i] = v4(p)
        end
    end
    POS = out
    return POS
end

local function hasVehicleOut()
    local netId = TriggerServerCallback("interim:lumberjack:getVehicleNetId")
    return netId ~= false and netId ~= nil
end

local function requestVehicle()

    local netId = TriggerServerCallback("interim:lumberjack:requestvehicle", {})
    if not netId then
        return false
    end
    local veh = NetToVeh(netId)
    local timeout = GetGameTimer() + 5000
    while (not veh or veh == 0 or not DoesEntityExist(veh)) and GetGameTimer() < timeout do
        Wait(50)
        veh = NetToVeh(netId)
    end
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        return true
    end

    local ped = PlayerPedId()

    DoScreenFadeOut(800)
    Wait(850)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    DoScreenFadeIn(800)

    if vehicleMenu then
        vehicleMenu.menu.close()
    end



    return true
end

local function storeVehicle()
    local netId = TriggerServerCallback("interim:lumberjack:getVehicleNetId")
    if not netId then
        return false
    end
    TriggerServerEvent("interim:lumberjack:unregisterVehicle", netId)
    return true
end

local outfits = {
    {
        ["tshirt_1"] = 15,  ["tshirt_2"] = 0,
        ["torso_1"] = 126,  ["torso_2"] = 10,
        ["decals_1"] = 0,  ["decals_2"] = 0,
        ["arms"] = 0,
        ["pants_1"] = 26,  ["pants_2"] = 0,
        ["shoes_1"] = 70,  ["shoes_2"] = 23,
        ["helmet_1"] = 6,  ["helmet_2"] = 1,
        ["chain_1"] = 0,  ["chain_2"] = 0,
        ["ears_1"] = -1,  ["ears_2"] = 0
    },
    {
        ["tshirt_1"] = 15,  ["tshirt_2"] = 0,
        ["torso_1"] = 121,  ["torso_2"] = 12,
        ["decals_1"] = 0,  ["decals_2"] = 0,
        ["arms"] = 0,
        ["pants_1"] = 47,  ["pants_2"] = 0,
        ["shoes_1"] = 74,  ["shoes_2"] = 1,
        ["helmet_1"] = 106,  ["helmet_2"] = 20,
        ["chain_1"] = 0,  ["chain_2"] = 0,
        ["ears_1"] = -1,  ["ears_2"] = 0
    }
}

local function ensureVehicleMenu()
    if vehicleMenu then return vehicleMenu end

    vehicleMenu = InterimVehicleMenu.new("lumberjackdelivery", {
        title  = "Véhicule de bûcheron",
        banner = GetVUIBanner("lumberjack"),
        getVehicleOut = function()
            return hasVehicleOut()
        end,
        onSpawn = function()
            return requestVehicle()
        end,
        onStore = function()
            return storeVehicle()
        end,
    }, outfits)

    return vehicleMenu
end

local function SetupStart()
    local cfg = TriggerServerCallback("interim:lumberjack:getConfig")
    if cfg then LumberjackConfig = cfg end

    local p = fetchPositions()
    if not p or not p.startplace then
        SetTimeout(500, SetupStart)
        return
    end

    local blip = AddBlipForCoord(p.startplace.x, p.startplace.y, p.startplace.z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.5)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("~HUD_COLOUR_BLUE~[Intérim]~HUD_COLOUR_PURE_WHITE~ Bucheron • Garage")
    EndTextCommandSetBlipName(blip)

    SpawnNpcsInterimJobs(
            cfg.pedService,
            p.startplacenpc,
            p.startplace_npcheading,
            "Appuyez sur ~INPUT_CONTEXT~ pour parler",
            function()
                ensureVehicleMenu():toggle()
            end
    )

end

CreateThread(function()
    SetupStart()
end)
