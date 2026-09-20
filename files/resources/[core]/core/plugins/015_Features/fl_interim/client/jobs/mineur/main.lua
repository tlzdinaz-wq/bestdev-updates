local MinerConfig = {}
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
    local t = TriggerServerCallback("interim:miner:getPositionsAll")
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
    local netId = TriggerServerCallback("interim:miner:getVehicleNetId")
    return netId ~= false and netId ~= nil
end

local function requestVehicle()


    local netId = TriggerServerCallback("interim:miner:requestvehicle", {})
    if not netId then
        return false
    end
    return true
end

local function storeVehicle()
    local netId = TriggerServerCallback("interim:miner:getVehicleNetId")
    if not netId then
        return false
    end
    TriggerServerEvent("interim:miner:unregisterVehicle", netId)
    return true
end

local outfits = {
    {
        ['helmet_1']  = 2,    ['helmet_2'] = 0,  -- Bonnet (ou -1 pour rien)
        ['tshirt_1']  = 15,   ['tshirt_2'] = 0,  -- T-shirt sous la chemise
        ['torso_1']   = 50,   ['torso_2'] = 0,   -- Chemise à carreaux
        ['arms']      = 50,                      -- Bras
        ['pants_1']   = 10,   ['pants_2'] = 1,   -- Pantalon Cargo / Travail
        ['shoes_1']   = 25,   ['shoes_2'] = 0,   -- Bottes de chantier
        ['chain_1']   = 0,    ['chain_2'] = 0,
        ['mask_1']    = 0,    ['mask_2'] = 0
    },
    {
        ['helmet_1']  = 119,    ['helmet_2'] = 0,  -- Bonnet
        ['tshirt_1']  = 14,   ['tshirt_2'] = 0,  -- T-shirt sous la chemise (ID à vérifier)
        ['torso_1']   = 9,   ['torso_2'] = 0,   -- Chemise à carreaux (ou veste flanelle)
        ['arms']      = 33,                      -- Bras
        ['pants_1']   = 47,   ['pants_2'] = 0,   -- Jean ou Cargo femme
        ['shoes_1']   = 26,   ['shoes_2'] = 0,   -- Bottes de travail femme
        ['chain_1']   = 0,    ['chain_2'] = 0,
        ['mask_1']    = 0,    ['mask_2'] = 0
    }
}

local function ensureVehicleMenu()
    if vehicleMenu then return vehicleMenu end

    vehicleMenu = InterimVehicleMenu.new("minerGarage", {
        title  = "Véhicule de mineur",
        banner = GetVUIBanner("miner"),
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
    local cfg = TriggerServerCallback("interim:miner:getConfig")
    if cfg then MinerConfig = cfg end

    local p = fetchPositions()
    if not p or not p.startplace then
        SetTimeout(500, SetupStart)
        return
    end

    local blip = AddBlipForCoord(p.startplace.x, p.startplace.y, p.startplace.z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 46)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("~HUD_COLOUR_BLUE~[Intérim]~HUD_COLOUR_PURE_WHITE~ Mineur • Garage")
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
