---@meta _
---@diagnostic disable: duplicate-doc-field

RegisterClientCallback("core:getStreetName", function(pos)
    local x, y, z = table.unpack(pos)
    local streetNameH, crossingRoadH = GetStreetNameAtCoord(x, y, z)
    local streetName = GetStreetNameFromHashKey(streetNameH)
    local crossingRoad = GetStreetNameFromHashKey(crossingRoadH)
    local place = streetName

    if (crossingRoad ~= "") then
        place = streetName .. ", " .. crossingRoad
    end

    local zoneCode = GetNameOfZone(x, y, z)
    local zoneName = zoneCode and GetLabelText(zoneCode) or ""
    if zoneName == "NULL" then zoneName = "" end

    return place, zoneName
end)
