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
    local BLIP_NAME = ("ADMIN:BLIP:PLAYER#%s"):format(PLAYER_ID)
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
    SetBlipColour(BLIP_CREATED, PLAYER_VALUES["COLOR"] or 0)
    SetBlipCoords(BLIP_CREATED, PLAYER_COORDS)
    SetBlipRotation(BLIP_CREATED, math.ceil(PLAYER_ROTATION))

    if (PLAYER_SELECTED ~= -1) then
        local BLIP_SPRITE = GetBlipSprite(BLIP_CREATED)
        local PLAYER_SELECTED_VEHICLE = GetVehiclePedIsIn(PLAYER_PED, false)

        if IsEntityDead(PLAYER_PED) then
            if BLIP_SPRITE ~= 303 then
                SetBlipSprite( BLIP_CREATED, 303)
                SetBlipColour(BLIP_CREATED, 1)
                ShowHeadingIndicatorOnBlip( BLIP_CREATED, false)
            end
        elseif PLAYER_SELECTED_VEHICLE ~= nil then
            if IsPedInAnyBoat(PLAYER_PED) then
                if BLIP_SPRITE ~= 427 then
                    SetBlipSprite(BLIP_CREATED, 427)
                    SetBlipColour(BLIP_CREATED, PLAYER_VALUES["COLOR"] or 0)
                    ShowHeadingIndicatorOnBlip(BLIP_CREATED, false)
                end
            elseif IsPedInAnyHeli(PLAYER_PED) then
                if BLIP_SPRITE ~= 43 then
                    SetBlipSprite(BLIP_CREATED, 43)
                    SetBlipColour(BLIP_CREATED, PLAYER_VALUES["COLOR"] or 0)
                    ShowHeadingIndicatorOnBlip(BLIP_CREATED, false)
                end
            elseif IsPedInAnyPlane(PLAYER_PED) then
                if BLIP_SPRITE ~= 423 then
                    SetBlipSprite(BLIP_CREATED, 423)
                    SetBlipColour(BLIP_CREATED, PLAYER_VALUES["COLOR"] or 0)
                    ShowHeadingIndicatorOnBlip(BLIP_CREATED, false)
                end
            elseif IsPedInAnyPoliceVehicle(PLAYER_PED) then
                if BLIP_SPRITE ~= 137 then
                    SetBlipSprite(BLIP_CREATED, 137)
                    SetBlipColour(BLIP_CREATED, PLAYER_VALUES["COLOR"] or 0)
                    ShowHeadingIndicatorOnBlip(BLIP_CREATED, false)
                end
            elseif IsPedInAnySub(PLAYER_PED) then
                if BLIP_SPRITE ~= 308 then
                    SetBlipSprite(BLIP_CREATED, 308)
                    SetBlipColour(BLIP_CREATED, PLAYER_VALUES["COLOR"] or 0)
                    ShowHeadingIndicatorOnBlip(BLIP_CREATED, false)
                end
            elseif IsPedInAnyVehicle(PLAYER_PED) then
                if BLIP_SPRITE ~= 225 then
                    SetBlipSprite(BLIP_CREATED, 225)
                    SetBlipColour(BLIP_CREATED, PLAYER_VALUES["COLOR"] or 0)
                    ShowHeadingIndicatorOnBlip(BLIP_CREATED, false)
                end
            else
                if BLIP_SPRITE ~= 1 then
                    SetBlipSprite(BLIP_CREATED, 1)
                    SetBlipColour(BLIP_CREATED, PLAYER_VALUES["COLOR"] or 0)
                    ShowHeadingIndicatorOnBlip( BLIP_CREATED, true)
                end
            end
        else
            if BLIP_SPRITE ~= 1 then
                SetBlipSprite(BLIP_CREATED, 1)
                SetBlipColour(BLIP_CREATED, PLAYER_VALUES["COLOR"] or 0)
                ShowHeadingIndicatorOnBlip(BLIP_CREATED, true)
            end
        end

        if PLAYER_SELECTED_VEHICLE then
            SetBlipRotation(BLIP_CREATED, math.ceil(GetEntityHeading(PLAYER_SELECTED_VEHICLE)))
        else
            SetBlipRotation(BLIP_CREATED, math.ceil(GetEntityHeading(PLAYER_PED)))
        end
    end

    AddTextEntry(BLIP_NAME, ("(%s) - %s"):format(PLAYER_VALUES["ID"], tostring(PLAYER_VALUES["NAME"])))
    BeginTextCommandSetBlipName(BLIP_NAME);
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
RegisterNetEvent("ADMIN:BLIP:ACTIONS", function(DATA)
    -- DISABLED: Player blips to reduce resource consumption
    -- Clean up any existing blips if they exist
    if (DATA["ACTION"] == "DELETE") then
        local BLIP_VALUE = DATA["VALUE"]

        if (BLIP_VALUE == "ALL") then
            for PLAYER_ID, _ in pairs(BLIP_MANAGER["LIST"]) do
                BLIP_MANAGER.delete(PLAYER_ID)
            end
            return
        end
        return BLIP_MANAGER.delete(DATA["VALUE"])
    end

    -- Do not create any new blips (LIST action disabled)
    return

    -- if (DATA["ACTION"] == "LIST") then
    --     local myPLAYER_ID = GetPlayerServerId(PlayerId())
    --     local PLAYERS_REGISTERED = DATA["VALUE"]

    --     for PLAYER_ID, PLAYER_VALUES in pairs(PLAYERS_REGISTERED) do
    --         if ((tonumber(PLAYER_ID) ~= tonumber(myPLAYER_ID)) and type(PLAYER_VALUES) == "table") then
    --             BLIP_MANAGER.check(PLAYER_ID, PLAYER_VALUES)
    --         end
    --     end
    -- end
end)
