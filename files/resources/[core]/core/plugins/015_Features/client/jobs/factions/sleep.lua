---@meta _
---@diagnostic disable: duplicate-doc-field

local models = {
    [-119016924] = true,
    [-21971647] = true,
    [-21971647] = true,
    [-1601317712] = true,
}

--- Sleep
---@param object any
local function Sleep(object)
    local playerPed = PlayerPedId()
    local objectHeading = GetEntityHeading(object)
    local bedOffset = GetOffsetFromEntityInWorldCoords(object, 0.0, 0.0, 0.0)

    SetEntityCoords(playerPed, bedOffset.x, bedOffset.y, bedOffset.z)
    SetEntityHeading(playerPed, objectHeading + 180.0)

    ExecuteCommand("e sleep")
end

VFW.ContextAddButton("object", "S'allonger", function(object)
    return models[GetEntityModel(object)]
end, function(object)
    Sleep(object)
end)
