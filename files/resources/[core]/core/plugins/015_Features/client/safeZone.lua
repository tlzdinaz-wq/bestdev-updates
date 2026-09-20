---@meta _
---@diagnostic disable: duplicate-doc-field

---@class AllSafeZone
AllSafeZone = {}

local isInSafeZone = false
local newSystemInControl = false  -- Flag to prevent OLD system from overriding NEW system

--- isInSafeZoneArea
---@param zonePoints any
---@param x any
---@param y any
---@return boolean
local function isInSafeZoneArea(zonePoints, x, y)
    local inZone = false
    local j = #zonePoints

    for i = 1, #zonePoints do
        if zonePoints[i] and zonePoints[j] then
            if ((zonePoints[i].y < y and zonePoints[j].y >= y) or (zonePoints[j].y < y and zonePoints[i].y >= y)) and (zonePoints[i].x <= x or zonePoints[j].x <= x) then
                if zonePoints[i].x + (y - zonePoints[i].y) / (zonePoints[j].y - zonePoints[i].y) * (zonePoints[j].x - zonePoints[i].x) < x then
                    inZone = not inZone
                end
            end
        end

        j = i
    end

    return inZone
end

---Handle SafeZoneState
---@param entering any
local function handleSafeZoneState(entering)
    if entering then
        SetEntityInvincible(VFW.PlayerData.ped, true)
        SetCanAttackFriendly(VFW.PlayerData.ped, false, false)

        if not isInSafeZone then
            isInSafeZone = true
            VFW.Nui.SafeZoneVisible(true)
        end
    else
        if isInSafeZone then
            isInSafeZone = false
            SetEntityInvincible(VFW.PlayerData.ped, false)
            SetCanAttackFriendly(VFW.PlayerData.ped, true, false)
            VFW.Nui.SafeZoneVisible(false)
        end
    end
end

---@param name string
---@param pos vector3|table
RegisterNetEvent('core:createZoneSafe', function(name, pos)
    AllSafeZone[name] = { pos = pos }
end)

---@param name string
RegisterNetEvent('core:deleteZoneSafe', function(name)
    AllSafeZone[name] = nil
end)

CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(100) end

    AllSafeZone = TriggerServerCallback('core:admin:getAllZoneSafe')
    while not AllSafeZone do Wait(100) end

    while true do
        -- Skip if NEW system (ZoneSafe) is managing the state
        if not newSystemInControl then
            local playerX, playerY = table.unpack(GetEntityCoords(VFW.PlayerData.ped, true))
            local foundInZone = false

            for _, zone in pairs(AllSafeZone) do
                if isInSafeZoneArea(zone.pos, playerX, playerY) then
                    foundInZone = true
                    break
                end
            end

            handleSafeZoneState(foundInZone)
        end

        Wait(750)
    end
end)

---Get VFW.SafeZone
---@return any
function VFW.GetSafeZone()
    return isInSafeZone
end

---Set VFW.SafeZone (used by new ZoneSafe system)
---@param state boolean
---@param bypass boolean|nil
function VFW.SetSafeZone(state, bypass)
    newSystemInControl = state
    if state then
        if not bypass then
            handleSafeZoneState(true)
        end
    else
        handleSafeZoneState(false)
    end
end
