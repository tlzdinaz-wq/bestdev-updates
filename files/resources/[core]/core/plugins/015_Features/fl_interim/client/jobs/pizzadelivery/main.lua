local PizzaConfig = {}
local POS

local function v3(p)
    if not p then return nil end
    if type(p) == "vector3" then return p end
    if type(p) == "table" and p.x and p.y and p.z then
        return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0)
    end
    return nil
end

local function fetchPositions()
    if POS then return POS end

    local t = TriggerServerCallback("interim:pizza:getPositionsAll")
    if not t or type(t) ~= "table" then return nil end

    local out = {}
    out.startplace         = v3(t.startplace)
    out.startplacenpc      = v3(t.startplacenpc)
    out.startplace_npcheading = t.startplace_npcheading or 180.0
    out.startplace_radius  = tonumber(t.startplace_radius) or 2.0
    out.pickuppoint        = v3(t.pickuppoint)
    out.pickuppoint_radius = tonumber(t.pickuppoint_radius) or 1.75
    out.returnpoint        = v3(t.returnpoint)
    out.returnpoint_radius = tonumber(t.returnpoint_radius) or 3.0

    POS = out
    return POS
end

local function SetupStart()
    local cfg = TriggerServerCallback("interim:pizza:getConfig")
    if cfg then PizzaConfig = cfg end

    local p = fetchPositions()
    if not p or not p.startplace then
        SetTimeout(500, SetupStart)
        return
    end

    local blip = AddBlipForCoord(p.startplace.x, p.startplace.y, p.startplace.z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 6)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("~HUD_COLOUR_BLUE~[Intérim]~HUD_COLOUR_PURE_WHITE~ Pizza • Garage")
    EndTextCommandSetBlipName(blip)

    SpawnNpcsInterimJobs(
            cfg.main.pedService,
            p.startplacenpc,
            p.startplace_npcheading,
            "Appuyez sur ~INPUT_CONTEXT~ pour parler",
            function()
                if OpenPizzaMenu then
                    OpenPizzaMenu()
                end
            end
    )
end

CreateThread(function()
    SetupStart()
end)
