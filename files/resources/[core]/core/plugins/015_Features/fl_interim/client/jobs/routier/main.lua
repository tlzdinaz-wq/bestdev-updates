local RoutierConfig = {}
local POS


local function v3(p)
    if not p then return nil end
    if type(p) == "vector3" then return p end
    if type(p) == "table" and p.x and p.y and p.z then
        return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0)
    end
    return nil
end


local function hasVehicleOut()
    local nets = TriggerServerCallback("interim:routier:getVehicleNetId")
    if type(nets) ~= "table" then
        return false
    end
    return nets.truck ~= nil and nets.trailer ~= nil
end


local vehicleMenu

local function ensureVehicleMenu()
    if vehicleMenu then return vehicleMenu end

    vehicleMenu = InterimVehicleMenu.new("routier", {
        title  = "Véhicule de routier",
        banner = GetVUIBanner("routier"),

        getVehicleOut = function()
            local out = hasVehicleOut()
            return out
        end,

        onSpawn = function()
            return ToggleRoutierGarage(RoutierConfig)
        end,

        onStore = function()
            return ToggleRoutierGarage(RoutierConfig)
        end,
    })

    return vehicleMenu
end




local function fetchPositions()
    if POS then return POS end

    local t = TriggerServerCallback("interim:routier:getPositionsAll")
    if not t or type(t) ~= "table" then return nil end

    local out = {}
    out.startplace         = v3(t.startplace)
    out.startplace_radius  = tonumber(t.startplace_radius) or 2.0
    out.returnpoint        = v3(t.returnPoint)
    out.returnpoint_radius = tonumber(t.returnpoint_radius) or 3.0
    out.truckSpots         = t.truckSpots
    out.trailerSpots       = t.trailerSpots

    POS = out
    return POS
end

local function SetupStart()
    local cfg = TriggerServerCallback("interim:routier:getConfig")
    if cfg then RoutierConfig = cfg end

    local p = fetchPositions()
    if not p or not p.startplace then
        SetTimeout(500, SetupStart)
        return
    end

    local blip = AddBlipForCoord(p.startplace.x, p.startplace.y, p.startplace.z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("~HUD_COLOUR_BLUE~[Intérim]~HUD_COLOUR_PURE_WHITE~ Routier • Garage")
    EndTextCommandSetBlipName(blip)

    SpawnNpcsInterimJobs(
            cfg.pedService,
            cfg.startplacenpc,
            cfg.startplace_npcheading,
            "Appuyez sur ~INPUT_CONTEXT~ pour parler",
            function()
                ensureVehicleMenu():toggle()
            end
    )
end

CreateThread(function()
    SetupStart()
end)


