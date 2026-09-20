---@meta _
---@diagnostic disable: duplicate-doc-field

IID = {}

local IID_Factory = {}
local __instance = {
    __index = IID_Factory,
    __type = "IID_Factory"
} -- Metatable for instances

function IID.NewFactory(min, max)
    local self = setmetatable({}, __instance)
    self.min = min or 1
    self.max = max or 0xFFFF
    self.idTracker = self.min - 1
    return self
end

function IID_Factory:NextId()
    self.idTracker = self.idTracker < self.max and self.idTracker + 1 or self.min
    return self.idTracker
end