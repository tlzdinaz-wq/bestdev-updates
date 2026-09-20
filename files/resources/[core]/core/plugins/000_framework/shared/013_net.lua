---@meta _
---@diagnostic disable: duplicate-doc-field

--[[ Net Class ]]--
--- @class Net
Net = {}
local __instance = {
    __index = Net,
    __type = "Net"
} -- Metatable for instances

--- Return a new instance of Net.
---
--- @return Net
function Net.New()
    local self = setmetatable({}, __instance)

    self.listeners = {}

    return self
end

-- remove listener without mutating preventing us from emitting in reversal order or doing mutex way
function Net:removeListener(name, fn)
    if not self.listeners[name] then
        return
    end

    local listeners = self.listeners[name]
    local _listeners, _count = { idTracker = listeners.idTracker }, 0

    for i = 1, #listeners do
        local listener = listeners[i]

        if listener.fn ~= fn then
            _count = _count + 1
            _listeners[_count] = listener
        end
    end

    self.listeners[name] = _listeners

    return self
end

function Net:removeListeners(name)
    self.listeners[name] = nil
    return self
end

function Net:removeAllListeners()
    self.listeners = {}
    return self
end

local function netOnInternal(self, name, fn)
    local listeners = self.listeners[name]
    if not listeners then
        listeners = { idTracker = 0 }
        self.listeners[name] = listeners
    end

    listeners.idTracker = listeners.idTracker < 0xFFFF and listeners.idTracker + 1 or 1
    local id = listeners.idTracker

    local listener = { id = id, fn = fn }
    listeners[#listeners + 1] = listener

    return listener
end

function Net:on(name, fn)
    netOnInternal(self, name, fn)
    return self
end

function Net:once(name, fn)
    netOnInternal(self, name, fn).once = true
    return self
end

function Net:emitSync(name, ...)
    if not self.listeners[name] then
        return
    end

    local listeners = self.listeners[name]

    for i = 1, #listeners do
        local listener = listeners[i]

        if listener.once then
            self:removeListener(name, listener.fn)
        end

        listener.fn(...)
    end

    return self
end

local function removeListenersInternal(self, listeners, fns)
    local _listeners, _count = { idTracker = listeners.idTracker }, 0

    for i = 1, #listeners do
        local listener = listeners[i]

        if not fns[listener.fn] then
            _count = _count + 1
            _listeners[_count] = listener
        end
    end

    return _listeners
end

function Net:emit(name, ...)
    if not self.listeners[name] then
        return
    end

    local listeners = self.listeners[name]
    local hadFnsToDelete = false
    local fnsToDelete = {}
    local args = { ... }

    for i = 1, #listeners do
        Citizen.CreateThreadNow(function()
            local listener = listeners[i]

            if listener.once then
                hadFnsToDelete = true
                fnsToDelete[listener.fn] = true
            end

            listener.fn(table.unpack(args))
        end)
    end

    if hadFnsToDelete then
        self.listeners[name] = removeListenersInternal(self, listeners, fnsToDelete)
    end

    return self
end

setmetatable(Net, {
    __call = function(self, ...)
        return Net.New(...)
    end
})