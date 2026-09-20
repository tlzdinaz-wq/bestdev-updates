---@meta _
---@diagnostic disable: duplicate-doc-field

-- Credit: https://github.com/citizenfx/lua/blob/luaglm-dev/cfx/libs/scripts/examples/dataview.lua
local dataView = setmetatable({
    EndBig = ">",
    EndLittle = "<",
    Types = {
        Int8 = { code = "i1" },
        Uint8 = { code = "I1" },
        Int16 = { code = "i2" },
        Uint16 = { code = "I2" },
        Int32 = { code = "i4" },
        Uint32 = { code = "I4" },
        Int64 = { code = "i8" },
        Uint64 = { code = "I8" },
        Float32 = { code = "f", size = 4 }, -- a float (native size)
        Float64 = { code = "d", size = 8 }, -- a double (native size)

        LuaInt = { code = "j" }, -- a lua_Integer
        UluaInt = { code = "J" }, -- a lua_Unsigned
        LuaNum = { code = "n" }, -- a lua_Number
        String = { code = "z", size = -1, }, -- zero terminated string
    },

    FixedTypes = {
        String = { code = "c" }, -- a fixed-sized string with n bytes
        Int = { code = "i" }, -- a signed int with n bytes
        Uint = { code = "I" }, -- an unsigned int with n bytes
    },
}, {
    __call = function(_, length)
        return dataView.ArrayBuffer(length)
    end
})
dataView.__index = dataView

--[[ Create an ArrayBuffer with a size in bytes --]]
--- .ArrayBuffer
---@param length any
---@return any
function dataView.ArrayBuffer(length)
    return setmetatable({
        blob = string.blob(length),
        length = length,
        offset = 1,
        cangrow = true,
    }, dataView)
end

--[[ Wrap a non-internalized string --]]
--- .Wrap
---@param blob any
---@return any
function dataView.Wrap(blob)
    return setmetatable({
        blob = blob,
        length = blob:len(),
        offset = 1,
        cangrow = true,
    }, dataView)
end

--[[ Return the underlying bytebuffer --]]
function dataView:Buffer() return self.blob end
function dataView:ByteLength() return self.length end
function dataView:ByteOffset() return self.offset end
function dataView:SubView(offset, length)
    return setmetatable({
        blob = self.blob,
        length = length or self.length,
        offset = 1 + offset,
        cangrow = false,
    }, dataView)
end

--[[ Return the Endianness format character --]]
--- ef
---@param big any
---@return any
local function ef(big) return (big and dataView.EndBig) or dataView.EndLittle end

--[[ Helper function for setting fixed datatypes within a buffer --]]
--- packblob
---@param self any
---@param offset any
---@param value any
---@param code any
---@return boolean
local function packblob(self, offset, value, code)
    -- If cangrow is false the dataview represents a subview, i.e., a subset
    -- of some other string view. Ensure the references are the same before
    -- updating the subview
    local packed = self.blob:blob_pack(offset, code, value)
    if self.cangrow or packed == self.blob then
        self.blob = packed
        self.length = packed:len()
        return true
    else
        return false
    end
end

--[[
    Create the API by using dataView.Types
--]]
for label,datatype in pairs(dataView.Types) do
    if not datatype.size then  -- cache fixed encoding size
        datatype.size = string.packsize(datatype.code)
    elseif datatype.size >= 0 and string.packsize(datatype.code) ~= datatype.size then
        local msg = "Pack size of %s (%d) does not match cached length: (%d)"
        error(msg:format(label, string.packsize(datatype.code), datatype.size))
        return nil
    end

    dataView["Get" .. label] = function(self, offset, endian)
        offset = offset or 0
        if offset >= 0 then
            local o = self.offset + offset
            local val,_ = self.blob:blob_unpack(o, ef(endian) .. datatype.code)
            return val
        end

        return nil
    end

    dataView["Set" .. label] = function(self, offset, value, endian)
        if offset >= 0 and value then
            local o = self.offset + offset
            local v_size = (datatype.size < 0 and value:len()) or datatype.size
            if self.cangrow or ((o + (v_size - 1)) <= self.length) then
                if not packblob(self, o, value, ef(endian) .. datatype.code) then
                    error("cannot grow subview")
                end
            else
                error("cannot grow dataview")
            end
        end

        return self
    end
end

for label,datatype in pairs(dataView.FixedTypes) do
    datatype.size = -1 -- Ensure cached encoding size is invalidated

    dataView["GetFixed" .. label] = function(self, offset, typelen, endian)
        if offset >= 0 then
            local o = self.offset + offset
            if (o + (typelen - 1)) <= self.length then
                local code = ef(endian) .. "c" .. tostring(typelen)
                local val,_ = self.blob:blob_unpack(o, code)
                return val
            end
        end

        return nil -- Out of bounds
    end

    dataView["SetFixed" .. label] = function(self, offset, typelen, value, endian)
        if offset >= 0 and value then
            local o = self.offset + offset
            if self.cangrow or ((o + (typelen - 1)) <= self.length) then
                local code = ef(endian) .. "c" .. tostring(typelen)
                if not packblob(self, o, value, code) then
                    error("cannot grow subview")
                end
            else
                error("cannot grow dataview")
            end
        end

        return self
    end
end

local gizmoEnabled = false
local currentMode = 'translate'
local currentEntity

--- normalize
---@param x any
---@param y any
---@param z any
---@return number
local function normalize(x, y, z)
    local length = math.sqrt(x * x + y * y + z * z)
    if length == 0 then
        return 0, 0, 0
    end

    return x / length, y / length, z / length
end

--- makeEntityMatrix
---@param entity any
---@return any
local function makeEntityMatrix(entity)
    local f, r, u, a = GetEntityMatrix(entity)
    local view = dataView.ArrayBuffer(60)

    view:SetFloat32(0, r[1])
        :SetFloat32(4, r[2])
        :SetFloat32(8, r[3])
        :SetFloat32(12, 0)
        :SetFloat32(16, f[1])
        :SetFloat32(20, f[2])
        :SetFloat32(24, f[3])
        :SetFloat32(28, 0)
        :SetFloat32(32, u[1])
        :SetFloat32(36, u[2])
        :SetFloat32(40, u[3])
        :SetFloat32(44, 0)
        :SetFloat32(48, a[1])
        :SetFloat32(52, a[2])
        :SetFloat32(56, a[3])
        :SetFloat32(60, 1)

    return view
end

--- applyEntityMatrix
---@param entity any
---@param view any
local function applyEntityMatrix(entity, view)
    local x1, y1, z1 = view:GetFloat32(16), view:GetFloat32(20), view:GetFloat32(24)
    local x2, y2, z2 = view:GetFloat32(0), view:GetFloat32(4), view:GetFloat32(8)
    local x3, y3, z3 = view:GetFloat32(32), view:GetFloat32(36), view:GetFloat32(40)
    local tx, ty, tz = view:GetFloat32(48), view:GetFloat32(52), view:GetFloat32(56)

    if not enableScale then
        x1, y1, z1 = normalize(x1, y1, z1)
        x2, y2, z2 = normalize(x2, y2, z2)
        x3, y3, z3 = normalize(x3, y3, z3)
    end

    SetEntityMatrix(entity,
        x1, y1, z1,
        x2, y2, z2,
        x3, y3, z3,
        tx, ty, tz
    )
end

--- gizmoLoop
---@param entity any
local function gizmoLoop(entity)
    CreateThread(function()
        while gizmoEnabled and DoesEntityExist(entity) do
            if IsDisabledControlJustPressed(0, 20) or IsControlJustPressed(0, 20) then
                PlaceObjectOnGroundProperly_2(entity)
            end
    
            local matrixBuffer = makeEntityMatrix(entity)
            local changed = Citizen.InvokeNative(0xEB2EDCA2, matrixBuffer:Buffer(), 'Editor1',
                Citizen.ReturnResultAnyway())
    
            if changed then
                applyEntityMatrix(entity, matrixBuffer)
            end
            
            Wait(0)
        end
    
        gizmoEnabled = false
        currentEntity = nil
    end)
end

--- .UseGizmo
---@param entity any
function VFW.UseGizmo(entity)

    Wait(250)

    gizmoEnabled = true
    currentEntity = entity
    gizmoLoop(entity)

    _gizmoInstructionalId = VFW.AddInstructionalButtons({
        { label = "Valider", control = 201 },
        { label = "Annuler", control = 200 },
        { label = "Placer au sol", control = 20 },
        { label = "Rotation / Translation", control = 45 },
        { label = "Supprimer l'objet", control = 202 },
    })
end

--- .StopGizmo
---@return any
function VFW.StopGizmo()
    local data = {
        handle = currentEntity,
        pos = GetEntityCoords(currentEntity),
        rot = GetEntityRotation(currentEntity)
    }
    gizmoEnabled = false
    currentEntity = nil

    VFW.RemoveInstructionalButtons(_gizmoInstructionalId)
    _gizmoInstructionalId = nil

    Wait(250)


    return data
end

exports("useGizmo", function(entity)

    Wait(250)

    gizmoEnabled = true
    currentEntity = entity
    gizmoLoop(entity)

    local _exportGizmoInstructionalId = VFW.AddInstructionalButtons({
        { label = "Valider", control = 201 },
        { label = "Annuler", control = 200 },
        { label = "Mode normal", control = 202 },
        { label = "Curseur", control = 47 },
        { label = "Placer au sol", control = 20 },
        { label = "Rotation / Translation", control = 45 },
    })
    EnterCursorMode()
    SetEntityAlpha(entity, 200)

    local isCursorActive = true
    local cancelled = false
    local switchedBack = false

    while gizmoEnabled do
        if IsControlJustPressed(0, 47) then
            if isCursorActive then
                LeaveCursorMode()
            else
                EnterCursorMode()
            end

            isCursorActive = not isCursorActive
        end

        if IsControlJustPressed(0, 201) then
            gizmoEnabled = false
            Wait(250)
        end

        if IsControlJustPressed(0, 200) then
            cancelled = true
            gizmoEnabled = false
            Wait(250)
        end

        -- Suppr = retour au mode normal
        if IsControlJustPressed(0, 177) then
            switchedBack = true
            gizmoEnabled = false
            Wait(250)
        end

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisablePlayerFiring(VFW.PlayerData.ped, true)
        Wait(0)
    end

    if isCursorActive then
        LeaveCursorMode()
    end

    VFW.RemoveInstructionalButtons(_exportGizmoInstructionalId)

    if cancelled then
        return nil
    end

    if switchedBack then
        return { switchedBack = true, handle = entity }
    end

    return {
        handle = entity,
        position = GetEntityCoords(entity),
        rotation = GetEntityRotation(entity)
    }
end)

RegisterCommand('+_gizmoSelect', function()
    if (not gizmoEnabled) or IsPauseMenuActive() then
        return
    end

    ExecuteCommand('+gizmoSelect')
end)
RegisterCommand('-_gizmoSelect', function()
    if (not gizmoEnabled) or IsPauseMenuActive() then
        return
    end

    ExecuteCommand('-gizmoSelect')
end)
RegisterKeyMapping('+_gizmoSelect', "Sélectionner gizmo", "MOUSE_BUTTON", "MOUSE_LEFT")

RegisterCommand('+_gizmoRotation', function()
    if (not gizmoEnabled) or IsPauseMenuActive() then
        return
    end

    if currentMode == 'Rotate' then
        currentMode = 'Translate'
        ExecuteCommand('+gizmoTranslation')
    else
        currentMode = 'Rotate'
        ExecuteCommand('+gizmoRotation')
    end
end)
RegisterCommand('-_gizmoRotation', function()
    if (not gizmoEnabled) or IsPauseMenuActive() then
        return
    end

    if currentMode == 'Rotate' then
        ExecuteCommand('-gizmoRotation')
    else
        ExecuteCommand('-gizmoTranslation')
    end
end)
RegisterKeyMapping('+_gizmoRotation', "Rotation gizmo", "keyboard", "R")