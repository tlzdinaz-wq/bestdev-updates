---@meta _
---@diagnostic disable: duplicate-doc-field

local TimeoutCount = 0
local CancelledTimeouts = {}

---@param msec number
---@param cb function
---@return number
VFW.SetTimeout = function(msec, cb)
    local id <const> = TimeoutCount + 1

    SetTimeout(msec, function()
        if CancelledTimeouts[id] then
            CancelledTimeouts[id] = nil
            return
        end

        cb()
    end)

    TimeoutCount = id

    return id
end

---@param id number
---@return nil
VFW.ClearTimeout = function(id)
    CancelledTimeouts[id] = true
end
