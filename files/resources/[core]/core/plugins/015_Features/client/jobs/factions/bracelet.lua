---@meta _
---@diagnostic disable: duplicate-doc-field

local BLIP_MANAGER = {
---@class LIST
    LIST = {};
};

---Get BLIP_MANAGER.FromId
---@param PLAYER_ID number|table Player ID or player object
---@return any
function BLIP_MANAGER.getFromId(PLAYER_ID)
    PLAYER_ID = tonumber(PLAYER_ID)
    local SELECT_BLIP = BLIP_MANAGER["LIST"][PLAYER_ID]

    return (SELECT_BLIP ~= nil and DoesBlipExist(SELECT_BLIP) and SELECT_BLIP) or false
end

--- .check
---@param PLAYER_ID number|table Player ID or player object
---@param PLAYER_VALUES number|table Player ID or player object
function BLIP_MANAGER.check(PLAYER_ID, PLAYER_VALUES)
    local BLIP_NAME = ("CORE:JOBS:BLIP:PLAYER#%s"):format(PLAYER_ID)
    local BLIP_REGISTERED = BLIP_MANAGER.getFromId(PLAYER_ID)
    local PLAYER_SELECTED = GetPlayerFromServerId(tonumber(PLAYER_ID))
    local PLAYER_PED = ((PLAYER_SELECTED ~= -1 and GetPlayerPed(PLAYER_SELECTED)) or false)
    local PLAYER_COORDS = ((PLAYER_PED ~= false and GetEntityCoords(PLAYER_PED)) or PLAYER_VALUES["COORDS"]["POS"])
    local PLAYER_ROTATION = ((PLAYER_PED ~= false and GetEntityHeading(PLAYER_PED)) or PLAYER_VALUES["COORDS"]["HEADING"])

    local BLIP_CREATED = (not BLIP_REGISTERED and (PLAYER_SELECTED ~= -1 and AddBlipForEntity(PLAYER_PED) or AddBlipForCoord(PLAYER_COORDS.x, PLAYER_COORDS.y, PLAYER_COORDS.z)) or BLIP_REGISTERED)
    BLIP_MANAGER["LIST"][tonumber(PLAYER_ID)] = BLIP_CREATED

    if (BLIP_REGISTERED and (PLAYER_SELECTED ~= -1) and GetBlipInfoIdEntityIndex(BLIP_REGISTERED) == 0) then
        if (DoesBlipExist(BLIP_CREATED)) then
            RemoveBlip(BLIP_CREATED)
        end

        BLIP_CREATED = AddBlipForEntity(PLAYER_PED)
        BLIP_MANAGER["LIST"][tonumber(PLAYER_ID)] = BLIP_CREATED
    end

    SetBlipCategory(BLIP_CREATED, 7)
    ShowHeadingIndicatorOnBlip(BLIP_CREATED, true)
    SetBlipShrink(BLIP_CREATED, (PLAYER_SELECTED ~= -1 and false) or true)
    SetBlipScale(BLIP_CREATED,  0.5)
    SetBlipSprite(BLIP_CREATED, 1)
    SetBlipColour(BLIP_CREATED, 0)
    SetBlipCoords(BLIP_CREATED, PLAYER_COORDS)
    SetBlipRotation(BLIP_CREATED, math.ceil(PLAYER_ROTATION))

    AddTextEntry(BLIP_NAME, ("Bracelet de : %s"):format(tostring(PLAYER_VALUES["NAME"])))
    BeginTextCommandSetBlipName(BLIP_NAME)
    EndTextCommandSetBlipName(BLIP_CREATED)
end

---Delete BLIP_MANAGER.
---@param PLAYER_ID number|table Player ID or player object
---@return boolean
function BLIP_MANAGER.delete(PLAYER_ID)
    local SELECT_BLIP = BLIP_MANAGER.getFromId(PLAYER_ID)

    if (not SELECT_BLIP) then
        return false
    end

    if (DoesBlipExist(SELECT_BLIP)) then
        RemoveBlip(SELECT_BLIP)
    end

    BLIP_MANAGER["LIST"][tonumber(PLAYER_ID)] = nil
end

---@param DATA table
RegisterNetEvent("CORE:JOBS:BLIP:ACTIONS", function(DATA)
    if (DATA["ACTION"] == "LIST") then
        local myPLAYER_ID = GetPlayerServerId(PlayerId())
        local PLAYERS_REGISTERED = DATA["VALUE"]

        for PLAYER_ID, PLAYER_VALUES in pairs(PLAYERS_REGISTERED) do
            if ((tonumber(PLAYER_ID) ~= tonumber(myPLAYER_ID)) and type(PLAYER_VALUES) == "table") then
                BLIP_MANAGER.check(PLAYER_ID, PLAYER_VALUES)
            end
        end
    elseif (DATA["ACTION"] == "DELETE") then
        local BLIP_VALUE = DATA["VALUE"]

        if (BLIP_VALUE == "ALL") then
            for PLAYER_ID, _ in pairs(BLIP_MANAGER["LIST"]) do
                BLIP_MANAGER.delete(PLAYER_ID)
            end

            return
        end

        return BLIP_MANAGER.delete(DATA["VALUE"])
    end
end)

local lastZone = {}
local lastBlip = {}
local lastJob = nil

---Create Zone
---@param name string
---@param positions vector3|table Position
---@param interactLabel string
---@param interactKey any
---@param interactIcons any
---@param action any
---@param colors any
---@return number|table|boolean Created object or success status
local function createZone(name, positions, interactLabel, interactKey, interactIcons, action, colors)
    local zone = Worlds.Zone.Create(positions, 2, false, function()
        if action.onEnter then
            action.onEnter()
        end

        if action.onPress then
            VFW.RegisterInteraction(name, action.onPress)
        end

    end, function()
        VFW.RemoveInteraction(name)
        if action.onExit then
            action.onExit()
        end

    end, interactLabel, interactKey, interactIcons, colors)

    return zone
end

---Create Blip
---@param coords vector3|table Coordinates
---@param sprite any
---@param color any
---@param scale any
---@param name string
---@return number|table|boolean Created object or success status
local function createBlip(coords, sprite, color, scale, name)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)

    return blip
end

---Load Bracelet
local function loadBracelet()

    while not VFW.Jobs or not VFW.Jobs.Menu or not VFW.Jobs.Menu.Bracelet do
        Wait(100)
    end

    while not next(VFW.Jobs.Menu.Bracelet) do
        Wait(100)
    end

    if not lastJob or not VFW.Jobs.Menu.Bracelet[lastJob] then
        return
    end

    local config = VFW.Jobs.Menu.Bracelet[lastJob]

---@class lastZone
    lastZone = {}

    for _, pedData in ipairs(config.Point) do
        for _, coord in ipairs(pedData.coords) do
            local coords = vector(coord.x, coord.y, coord.z + 1.25)
            lastBlip[#lastBlip + 1] = createBlip(coords, pedData.blip.sprite, pedData.blip.color, pedData.blip.scale, pedData.blip.label)
            lastZone[#lastZone + 1] = createZone(
                    pedData.zone.name,
                    coords,
                    pedData.zone.interactLabel,
                    pedData.zone.interactKey,
                    pedData.zone.interactIcons,
                    { onPress = pedData.zone.onPress }
            )
            Wait(25)
        end
    end
end

--- deletingZone
local function deletingZone()

    for i, zone in ipairs(lastZone) do
        if zone then
            Worlds.Zone.Remove(zone)
            lastZone[i] = nil
        end
    end

    VFW.RemoveInteraction(("bracelet_%s"):format(lastJob))

---@class lastZone
    lastZone = {}
end

--- deletingBlip
local function deletingBlip()

    for i, blip in ipairs(lastBlip) do
        if blip then
            RemoveBlip(blip)
            lastBlip[i] = nil
        end
    end

---@class lastBlip
    lastBlip = {}
end

---@param Job table Job data
RegisterNetEvent("vfw:setJob", function(Job)
    if Job.name == lastJob then
        return
    end

    deletingZone()
    deletingBlip()

    if Job.name == "unemployed" then
        lastJob = nil
        return
    end

    lastJob = Job.name

    Wait(5000)

    loadBracelet()
end)

-- Check if ped is a freemode model (custom peds don't support component variations)
local function IsFreemodeModel(ped)
    local model = GetEntityModel(ped)
    return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

-- Applique le composant bracelet sur les accessoires (component 7 = teef/accessories)
local function ApplyBraceletComponent()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end
    if not IsFreemodeModel(ped) then return end
    local isMale = (GetEntityModel(ped) == `mp_m_freemode_01`)
    SetPedComponentVariation(ped, 7, isMale and 11 or 8, 0, 0)
end

local function ClearBraceletComponent()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end
    if not IsFreemodeModel(ped) then return end
    SetPedComponentVariation(ped, 7, 0, 0, 0)
end

RegisterNetEvent("vfw:playerReady", function()
    if lastJob then
        deletingZone()
        deletingBlip()
        lastJob = nil
    end

    if VFW.PlayerData.job.name == "unemployed" then
        return
    end

    lastJob = VFW.PlayerData.job.name

    Wait(5000)

    loadBracelet()

    if VFW.PlayerData.metadata and VFW.PlayerData.metadata.bracelet and VFW.PlayerData.metadata.bracelet.isBracelet then
        CreateThread(function()
            local myId = GetPlayerServerId(PlayerId())
            while true do
                if VFW.PlayerData.metadata and VFW.PlayerData.metadata.bracelet and VFW.PlayerData.metadata.bracelet.isBracelet then
                    local inStaff = false
                    for _, sid in ipairs(VFW.staffMode or {}) do
                        if sid == myId then inStaff = true; break end
                    end
                    if not inStaff then
                        ApplyBraceletComponent()
                    end
                else
                    ClearBraceletComponent()
                    break
                end
                Wait(1000)
            end
        end)
    end
end)

---@param status any
RegisterNetEvent("core:jobs:setBracelet", function(status)
    local myId = GetPlayerServerId(PlayerId())
    local inStaff = false
    for _, sid in ipairs(VFW.staffMode or {}) do
        if sid == myId then inStaff = true; break end
    end

    if status and not inStaff then
        ApplyBraceletComponent()
    elseif not status then
        ClearBraceletComponent()
    end
end)
