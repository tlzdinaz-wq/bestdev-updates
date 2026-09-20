---@meta _
---@diagnostic disable: duplicate-doc-field

-- Prop Placer Dev Tool
-- Integrated from FivemBaseRef for debugging prop placement

-- DataView implementation for binary data manipulation (required for gizmo)
local DataView = setmetatable({
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
        Float32 = { code = "f", size = 4 },
        Float64 = { code = "d", size = 8 },
        LuaInt = { code = "j" },
        UluaInt = { code = "J" },
        LuaNum = { code = "n" },
        String = { code = "z", size = -1, },
    },
}, {
    __call = function(_, length)
        return DataView.ArrayBuffer(length)
    end
})
DataView.__index = DataView

function DataView.ArrayBuffer(length)
    return setmetatable({
        blob = string.blob(length),
        length = length,
        offset = 1,
        cangrow = true,
    }, DataView)
end

function DataView:Buffer() return self.blob end
function DataView:ByteLength() return self.length end
function DataView:ByteOffset() return self.offset end

local function ef(big) return (big and DataView.EndBig) or DataView.EndLittle end

local function packblob(self, offset, value, code)
    local packed = self.blob:blob_pack(offset, code, value)
    if self.cangrow or packed == self.blob then
        self.blob = packed
        self.length = packed:len()
        return true
    else
        return false
    end
end

-- Create API for DataView types
for label, datatype in pairs(DataView.Types) do
    if not datatype.size then
        datatype.size = string.packsize(datatype.code)
    end

    DataView["Get" .. label] = function(self, offset, endian)
        offset = offset or 0
        if offset >= 0 then
            local o = self.offset + offset
            local val, _ = self.blob:blob_unpack(o, ef(endian) .. datatype.code)
            return val
        end
        return nil
    end

    DataView["Set" .. label] = function(self, offset, value, endian)
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

local PropPlacer = {}
local glm = require and require('glm') or nil -- GLM might not be available

-- State
PropPlacer.active = false
PropPlacer.data = {}
PropPlacer.freeCam = nil
PropPlacer.objectMatrix = nil -- Store object matrix for gizmo calculations
PropPlacer.buttonId = nil -- ID for instructional buttons
PropPlacer.speedMultiplier = 1.0 -- Camera speed multiplier (adjustable with scroll wheel)

-- Function to update main instructional buttons (with current speed)
function PropPlacer.UpdateMainButtons()
    if not PropPlacer.buttonId then return end
    local speedText = string.format("Molette (x%.1f)", PropPlacer.speedMultiplier)
    instructionalButtons[PropPlacer.buttonId] = {
        { label = "Sélection d'os", control = 47 },      -- G
        { label = "Mode Gizmo", control = 311 },         -- K
        { label = "Avancer", control = 32 },             -- W
        { label = "Reculer", control = 33 },             -- S
        { label = "Gauche", control = 34 },              -- A
        { label = "Droite", control = 35 },              -- D
        { label = "Monter", control = 38 },              -- E
        { label = "Descendre", control = 44 },           -- Q
        { label = "Rapide", control = 21 },              -- Shift
        { label = "Lent", control = 36 },                -- Ctrl
        { label = speedText, control = 241 },            -- Scroll wheel (shows current speed)
    }
end

-- Configuration
local CFG = {
    DefaultPedModel = `mp_m_freemode_01`,
    DefaultObjectModel = `ba_prop_club_tonic_bottle`,
    DefaultObjectBone = 0x6F06, -- IK_L_Hand (57005)
    BoneSelectionModeControl = 47, -- G key
    GizmoModeControl = 311, -- K key (changed from H which is voice)
    DefaultAnim = { dict = 'mp_player_intdrink', anim = 'loop_bottle' }
}

local PedBoneTags = {
    -- Root & Pelvis
    ["SKEL_ROOT"] = 0x0,
    ["SKEL_Pelvis"] = 0x2E28,

    -- Left Leg
    ["SKEL_L_Thigh"] = 0xE39F,
    ["SKEL_L_Calf"] = 0xF9BB,
    ["SKEL_L_Foot"] = 0x3779,
    ["SKEL_L_Toe0"] = 0x83C,
    ["IK_L_Foot"] = 0xFEDD,

    -- Right Leg
    ["SKEL_R_Thigh"] = 0xCA72,
    ["SKEL_R_Calf"] = 0x9000,
    ["SKEL_R_Foot"] = 0xCC4D,
    ["SKEL_R_Toe0"] = 0x512D,
    ["IK_R_Foot"] = 0x8AAE,

    -- Spine
    ["SKEL_Spine_Root"] = 0xE0FD,
    ["SKEL_Spine0"] = 0x5C01,
    ["SKEL_Spine1"] = 0x60F0,
    ["SKEL_Spine2"] = 0x60F1,
    ["SKEL_Spine3"] = 0x60F2,

    -- Left Arm
    ["SKEL_L_Clavicle"] = 0xFCD9,
    ["SKEL_L_UpperArm"] = 0xB1C5,
    ["SKEL_L_Forearm"] = 0xEEEB,
    ["SKEL_L_Hand"] = 0x49D9,
    ["PH_L_Hand"] = 0xEB95,
    ["IK_L_Hand"] = 0x8CBD,

    -- Left Fingers
    ["SKEL_L_Finger00"] = 0x67F2,
    ["SKEL_L_Finger01"] = 0xFF9,
    ["SKEL_L_Finger02"] = 0xFFA,
    ["SKEL_L_Finger10"] = 0x67F3,
    ["SKEL_L_Finger11"] = 0x1049,
    ["SKEL_L_Finger12"] = 0x104A,
    ["SKEL_L_Finger20"] = 0x67F4,
    ["SKEL_L_Finger21"] = 0x1059,
    ["SKEL_L_Finger22"] = 0x105A,
    ["SKEL_L_Finger30"] = 0x67F5,
    ["SKEL_L_Finger31"] = 0x1029,
    ["SKEL_L_Finger32"] = 0x102A,
    ["SKEL_L_Finger40"] = 0x67F6,
    ["SKEL_L_Finger41"] = 0x1039,
    ["SKEL_L_Finger42"] = 0x103A,

    -- Right Arm
    ["SKEL_R_Clavicle"] = 0x29D2,
    ["SKEL_R_UpperArm"] = 0x9D4D,
    ["SKEL_R_Forearm"] = 0x6E5C,
    ["SKEL_R_Hand"] = 0xDEAD,
    ["PH_R_Hand"] = 0x6F06,
    ["IK_R_Hand"] = 0x188E,

    -- Right Fingers
    ["SKEL_R_Finger00"] = 0xE5F2,
    ["SKEL_R_Finger01"] = 0xFA10,
    ["SKEL_R_Finger02"] = 0xFA11,
    ["SKEL_R_Finger10"] = 0xE5F3,
    ["SKEL_R_Finger11"] = 0xFA60,
    ["SKEL_R_Finger12"] = 0xFA61,
    ["SKEL_R_Finger20"] = 0xE5F4,
    ["SKEL_R_Finger21"] = 0xFA70,
    ["SKEL_R_Finger22"] = 0xFA71,
    ["SKEL_R_Finger30"] = 0xE5F5,
    ["SKEL_R_Finger31"] = 0xFA40,
    ["SKEL_R_Finger32"] = 0xFA41,
    ["SKEL_R_Finger40"] = 0xE5F6,
    ["SKEL_R_Finger41"] = 0xFA50,
    ["SKEL_R_Finger42"] = 0xFA51,

    -- Neck & Head
    ["SKEL_Neck_1"] = 0x9995,
    ["SKEL_Head"] = 0x796E,
    ["IK_Head"] = 0x322C,

    -- Accessories
    ["MH_Watch"] = 0x2738,
    ["SPR_CopRadio"] = 0x8245,
}

-- Helper functions
local function RequestModelSync(model)
    if not IsModelInCdimage(model) then
        return false
    end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    return true
end

local function RequestAnimDictSync(dict)
    if not DoesAnimDictExist(dict) then
        return false
    end

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end

    return true
end

local function DeletePed()
    if PropPlacer.data.pedHandle then
        if DoesEntityExist(PropPlacer.data.pedHandle) then
            DeleteEntity(PropPlacer.data.pedHandle)
        end
        PropPlacer.data.pedHandle = nil
    end
end

local function DeleteObject()
    if PropPlacer.data.objectHandle then
        if DoesEntityExist(PropPlacer.data.objectHandle) then
            DeleteEntity(PropPlacer.data.objectHandle)
        end
        PropPlacer.data.objectHandle = nil
    end
end

local function SetupPlayer()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()

    SetPlayerControl(playerId, not PropPlacer.active, 0)
    FreezeEntityPosition(playerPed, PropPlacer.active)
    SetEntityInvincible(playerPed, PropPlacer.active)
    SetEntityCollision(playerPed, not PropPlacer.active, false)
    SetEntityVisible(playerPed, not PropPlacer.active, false)
    SetEveryoneIgnorePlayer(playerId, PropPlacer.active)
end

local function SpawnPed(model)
    local playerPed = PlayerPedId()
    -- Spawn ped in front of player, facing them, on the ground
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.0, -1.0)
    local heading = GetEntityHeading(playerPed)

    model = model or CFG.DefaultPedModel

    if RequestModelSync(model) then
        local pedHandle = CreatePed(4, model, coords.x, coords.y, coords.z, heading, false, false)

        FreezeEntityPosition(pedHandle, true)
        SetBlockingOfNonTemporaryEvents(pedHandle, true)
        SetEntityInvincible(pedHandle, true)

        -- Place ped on ground properly
        PlaceObjectOnGroundProperly(pedHandle)

        SetModelAsNoLongerNeeded(model)

        return pedHandle
    end

    return nil
end

local function GetPosAndRotOffset()
    local posOffset = PropPlacer.data.posOffset or vec3(0.0, 0.0, 0.0)
    local rotOffset = PropPlacer.data.rotOffset or vec3(0.0, 0.0, 0.0)
    return posOffset, rotOffset
end

local function SpawnObject(model)
    model = model or CFG.DefaultObjectModel

    if not PropPlacer.data.pedHandle then
        return nil
    end

    local coords = GetEntityCoords(PropPlacer.data.pedHandle)

    if RequestModelSync(model) then
        local objectHandle = CreateObject(model, coords.x, coords.y, coords.z, false, false, true)

        FreezeEntityPosition(objectHandle, true)

        local posOffset, rotOffset = GetPosAndRotOffset()
        local boneTag = PropPlacer.data.selectedBoneTag or CFG.DefaultObjectBone

        AttachEntityToEntity(
            objectHandle,
            PropPlacer.data.pedHandle,
            GetPedBoneIndex(PropPlacer.data.pedHandle, boneTag),
            posOffset.x, posOffset.y, posOffset.z,
            rotOffset.x, rotOffset.y, rotOffset.z,
            false, false, false, false,
            0, -- EulerRotOrder.YXZ
            true
        )

        SetModelAsNoLongerNeeded(model)

        return objectHandle
    end

    return nil
end

local function ParseResult()
    local objectPos = PropPlacer.data.posOffset or vec3(0.0, 0.0, 0.0)
    local objectRot = PropPlacer.data.rotOffset or vec3(0.0, 0.0, 0.0)
    local boneTag = PropPlacer.data.selectedBoneTag or CFG.DefaultObjectBone

    local result = string.format(
        "{\n    offset = vec3(%.3f, %.3f, %.3f),\n    rotation = vec3(%.3f, %.3f, %.3f),\n    boneTag = 0x%X,\n    rotOrder = 0 -- YXZ\n}",
        objectPos.x, objectPos.y, objectPos.z,
        objectRot.x, objectRot.y, objectRot.z,
        boneTag
    )

    return result
end

local function ToggleEntities()
    if not PropPlacer.active then
        DeletePed()
        DeleteObject()
        return
    end

    PropPlacer.data.pedHandle = SpawnPed()
    PropPlacer.data.objectHandle = SpawnObject()
end

-- Native gizmo functionality using DRAW_GIZMO native
local function makeMatrix(forward, right, up, at)
    local view = DataView.ArrayBuffer(60)

    view:SetFloat32(0, right[1] or right.x)
        :SetFloat32(4, right[2] or right.y)
        :SetFloat32(8, right[3] or right.z)
        :SetFloat32(12, 0)
        :SetFloat32(16, forward[1] or forward.x)
        :SetFloat32(20, forward[2] or forward.y)
        :SetFloat32(24, forward[3] or forward.z)
        :SetFloat32(28, 0)
        :SetFloat32(32, up[1] or up.x)
        :SetFloat32(36, up[2] or up.y)
        :SetFloat32(40, up[3] or up.z)
        :SetFloat32(44, 0)
        :SetFloat32(48, at[1] or at.x)
        :SetFloat32(52, at[2] or at.y)
        :SetFloat32(56, at[3] or at.z)
        :SetFloat32(60, 1)

    return view
end

local function StartGizmo(target, changeCb)
    local gizmoEnabled = true
    local isTargetCoords = type(target) == 'vector3'

    EnterCursorMode()

    if not isTargetCoords then
        SetEntityDrawOutline(target, true)
    end

    CreateThread(function()
        while gizmoEnabled do
            Wait(0)

            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 245, true)

            DisablePlayerFiring(PlayerId(), true)

            -- Create matrix buffer for gizmo
            local matrixBuffer = not isTargetCoords and
                makeMatrix(GetEntityMatrix(target)) or
                makeMatrix(vec3(1.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), vec3(1.0, 1.0, 1.0), target)

            -- Call native DRAW_GIZMO (0xEB2EDCA2)
            local matrixModified = Citizen.InvokeNative(0xEB2EDCA2, matrixBuffer:Buffer(), 'Editor1', Citizen.ReturnResultAnyway()) -- DRAW_GIZMO

            if matrixModified then
                local rtX, rtY, rtZ = matrixBuffer:GetFloat32(0), matrixBuffer:GetFloat32(4), matrixBuffer:GetFloat32(8)
                local fwX, fwY, fwZ = matrixBuffer:GetFloat32(16), matrixBuffer:GetFloat32(20), matrixBuffer:GetFloat32(24)
                local upX, upY, upZ = matrixBuffer:GetFloat32(32), matrixBuffer:GetFloat32(36), matrixBuffer:GetFloat32(40)
                local atX, atY, atZ = matrixBuffer:GetFloat32(48), matrixBuffer:GetFloat32(52), matrixBuffer:GetFloat32(56)

                if changeCb then
                    changeCb(rtX, rtY, rtZ, fwX, fwY, fwZ, upX, upY, upZ, atX, atY, atZ)
                end

                if isTargetCoords then
                    target = vec3(atX, atY, atZ)
                end
            end

            if not isTargetCoords and not DoesEntityExist(target) then
                break
            end
        end
    end)

    return function()
        gizmoEnabled = false
        LeaveCursorMode()

        if not isTargetCoords then
            SetEntityDrawOutline(target, false)
        end
    end
end

-- Bone selection mode
local function HandleBoneSelectMode()
    PropPlacer.data.boneSelectMode = true

    -- Update instructional buttons for bone mode
    if PropPlacer.buttonId then
        instructionalButtons[PropPlacer.buttonId] = {
            { label = "Sélectionner", control = 24 },         -- Left Click
            { label = "Quitter mode bone", control = 47 },    -- G
        }
    end

    if PropPlacer.data.pedHandle then
        SetEntityAlpha(PropPlacer.data.pedHandle, 100, false)
    end

    CreateThread(function()
        local previewObject = nil

        while PropPlacer.active and PropPlacer.data.boneSelectMode do
            Wait(0)

            -- CRITICAL: Show mouse cursor every frame!
            SetMouseCursorActiveThisFrame()

            local cursorX, cursorY = GetNuiCursorPosition()
            local hoveredBoneName = nil
            local closestDist = 15.0 -- Pixel distance threshold
            local screenWidth, screenHeight = GetActiveScreenResolution()

            -- Pass 1: Find the closest bone to cursor
            for boneName, boneTag in pairs(PedBoneTags) do
                local boneCoords = GetPedBoneCoords(PropPlacer.data.pedHandle, boneTag, 0.0, 0.0, 0.0)
                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(boneCoords.x, boneCoords.y, boneCoords.z)

                if onScreen and screenX and screenY then
                    local diffX = screenX * screenWidth - cursorX
                    local diffY = screenY * screenHeight - cursorY
                    local diff = math.sqrt(diffX * diffX + diffY * diffY)

                    if diff < closestDist then
                        closestDist = diff
                        hoveredBoneName = boneName
                    end
                end
            end

            -- Pass 2: Draw all markers with correct colors
            for boneName, boneTag in pairs(PedBoneTags) do
                local boneCoords = GetPedBoneCoords(PropPlacer.data.pedHandle, boneTag, 0.0, 0.0, 0.0)
                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(boneCoords.x, boneCoords.y, boneCoords.z)

                if onScreen and screenX and screenY then
                    local r, g, b = 0, 0, 255 -- Blue by default
                    if boneName == hoveredBoneName then
                        r, g, b = 0, 255, 0 -- Green for hovered
                    end

                    DrawMarker(28, boneCoords.x, boneCoords.y, boneCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02, 0.02, 0.02, r, g, b, 200, false, true, 2, false, nil, nil, false)
                end
            end

            -- Show bone name
            if hoveredBoneName then
                local boneTag = PedBoneTags[hoveredBoneName]
                local boneCoords = GetPedBoneCoords(PropPlacer.data.pedHandle, boneTag, 0.0, 0.0, 0.0)

                -- Draw 3D text
                SetDrawOrigin(boneCoords.x, boneCoords.y, boneCoords.z, 0)
                SetTextScale(0.35, 0.35)
                SetTextFont(4)
                SetTextProportional(1)
                SetTextColour(255, 255, 255, 215)
                SetTextEntry("STRING")
                SetTextCentre(true)
                AddTextComponentString(hoveredBoneName)
                DrawText(0.0, 0.0)
                ClearDrawOrigin()

                -- Preview object on hover
                if not previewObject and PropPlacer.data.objectModel then
                    if RequestModelSync(PropPlacer.data.objectModel) then
                        previewObject = CreateObject(PropPlacer.data.objectModel, 0.0, 0.0, 0.0, false, false, false)
                        SetEntityAlpha(previewObject, 150, false)
                    end
                end

                if previewObject then
                    local posOffset, rotOffset = GetPosAndRotOffset()
                    AttachEntityToEntity(
                        previewObject,
                        PropPlacer.data.pedHandle,
                        GetPedBoneIndex(PropPlacer.data.pedHandle, boneTag),
                        posOffset.x, posOffset.y, posOffset.z,
                        rotOffset.x, rotOffset.y, rotOffset.z,
                        false, false, false, false,
                        0, -- EulerRotOrder.YXZ
                        true
                    )
                end

                -- Click to select (use pressed instead of released for better responsiveness)
                if IsControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 24) then -- Left click
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'INFO', subtitle = 'Placement Props',
                        message = string.format("Objet placé sur le bone: %s.", hoveredBoneName)
                    })

                    PropPlacer.data.selectedBoneTag = boneTag

                    -- Attach actual object
                    if PropPlacer.data.objectHandle then
                        local posOffset, rotOffset = GetPosAndRotOffset()
                        AttachEntityToEntity(
                            PropPlacer.data.objectHandle,
                            PropPlacer.data.pedHandle,
                            GetPedBoneIndex(PropPlacer.data.pedHandle, boneTag),
                            posOffset.x, posOffset.y, posOffset.z,
                            rotOffset.x, rotOffset.y, rotOffset.z,
                            false, false, false, false,
                            0, -- EulerRotOrder.YXZ
                            true
                        )
                    end
                end
            elseif previewObject then
                DeleteEntity(previewObject)
                previewObject = nil
            end
        end

        -- Cleanup
        if previewObject then
            DeleteEntity(previewObject)
        end

        if PropPlacer.data.pedHandle then
            ResetEntityAlpha(PropPlacer.data.pedHandle)
        end
    end)
end

local function ToggleBoneSelectMode()
    if not PropPlacer.data.boneSelectMode then
        HandleBoneSelectMode()
    else
        PropPlacer.data.boneSelectMode = nil
        -- Restore instructional buttons for main mode
        if PropPlacer.buttonId then
            instructionalButtons[PropPlacer.buttonId] = {
                { label = "Sélection d'os", control = 47 },      -- G
                { label = "Mode Gizmo", control = 311 },         -- K
                { label = "Avancer", control = 32 },             -- W
                { label = "Reculer", control = 33 },             -- S
                { label = "Gauche", control = 34 },              -- A
                { label = "Droite", control = 35 },              -- D
                { label = "Monter", control = 38 },              -- E
                { label = "Descendre", control = 44 },           -- Q
            }
        end
    end
end

-- Matrix math functions from reference (required for proper gizmo offset calculations)
local function normalizeMat(mat)
    if not glm then return mat end
    mat[3] = glm.normalize(mat[3])
    mat[1] = glm.cross(mat[2], mat[3])
    mat[1] = glm.normalize(mat[1])
    mat[2] = glm.cross(mat[3], mat[1])
    return mat
end

local function asinf(sine)
    if not glm then return math.asin(sine) end
    assert(1.0 - (sine * sine) >= 0.0, 'invalid sine')
    return glm.asin(sine)
end

local function asinfSafe(sine)
    if not glm then
        return (sine > -1.0 and (sine < 1.0 and math.asin(sine) or 0.5 * math.pi) or -0.5 * math.pi)
    end
    return (sine > -1.0 and (sine < 1.0 and glm.asin(sine) or 0.5 * glm.pi) or -0.5 * glm.pi)
end

local function isNearZero(number, tolerance)
    if not glm then return math.abs(number) < tolerance end
    return glm.abs(number) < tolerance
end

local function fromEulersYXZ(e)
    if not glm then
        -- Fallback without GLM
        local sx, sy, sz = math.sin(e.x), math.sin(e.y), math.sin(e.z)
        local cx, cy, cz = math.cos(e.x), math.cos(e.y), math.cos(e.z)
        return {
            vec3(cy * cz - sy * sx * sz, cy * sz + sy * sx * cz, -sy * cx),
            vec3(-cx * sz, cx * cz, sx),
            vec3(sy * cz + cy * sx * sz, sy * sz - cy * sx * cz, cy * cx)
        }
    end

    local sx, sy, sz = 0.0, 0.0, 0.0
    local cx, cy, cz = 0.0, 0.0, 0.0

    if e.x == 0.0 then
        sx, cx = 0.0, 1.0
    else
        sx, cx = glm.sincos(e.x)
    end

    if e.y == 0.0 then
        sy, cy = 0.0, 1.0
    else
        sy, cy = glm.sincos(e.y)
    end

    if e.z == 0.0 then
        sz, cz = 0.0, 1.0
    else
        sz, cz = glm.sincos(e.z)
    end

    return mat3x3(
        vec3(cy * cz - sy * sx * sz, cy * sz + sy * sx * cz, -sy * cx),
        vec3(-cx * sz, cx * cz, sx),
        vec3(sy * cz + cy * sx * sz, sy * sz - cy * sx * cz, cy * cx)
    )
end

local function toEulersYXZ(mat)
    local SMALL_FLOAT = 1e-6

    if glm then
        normalizeMat(mat)

        if ((isNearZero(mat[2].x, SMALL_FLOAT) and isNearZero(mat[2].y, SMALL_FLOAT)) or
            (isNearZero(mat[1].z, SMALL_FLOAT) and isNearZero(mat[3].z, SMALL_FLOAT)) or
            (glm.abs(mat[2].z) > (1.0 - SMALL_FLOAT))) then
            return vec3(asinfSafe(mat[2].z), glm.atan2(mat[3].x, mat[1].x), 0)
        end

        return vec3(
            asinf(mat[2].z),
            glm.atan2(-mat[1].z, mat[3].z),
            glm.atan2(-mat[2].x, mat[2].y)
        )
    else
        -- Fallback without GLM
        return vec3(
            math.asin(mat[2].z or mat[2][3]),
            math.atan2(-(mat[1].z or mat[1][3]), mat[3].z or mat[3][3]),
            math.atan2(-(mat[2].x or mat[2][1]), mat[2].y or mat[2][2])
        )
    end
end

local function mat34toMat44(ma)
    if glm then
        return mat4x4(vec4(ma[1].xyz, 0), vec4(ma[2].xyz, 0), vec4(ma[3].xyz, 0), vec4(ma[4].xyz, 1))
    else
        -- Fallback without GLM
        return {
            {ma[1].x, ma[1].y, ma[1].z, 0},
            {ma[2].x, ma[2].y, ma[2].z, 0},
            {ma[3].x, ma[3].y, ma[3].z, 0},
            {ma[4].x, ma[4].y, ma[4].z, 1}
        }
    end
end

-- Calculate B relative matrix to A based on their world matrix
local function calculateRelativeTransform(a, b)
    if glm then
        local aHomogeneous = mat34toMat44(a)
        local bHomogeneous = mat34toMat44(b)
        local aInv = glm.inverse(aHomogeneous)
        local bRelative = aInv * bHomogeneous
        return mat4x3(bRelative)
    else
        -- Simplified fallback - just return difference in positions
        return {
            b[1], b[2], b[3],
            vec3(b[4].x - a[4].x, b[4].y - a[4].y, b[4].z - a[4].z)
        }
    end
end

local function createTransformMatrix(position, eulerAngles)
    if glm then
        local rotMatrix = fromEulersYXZ(eulerAngles)
        return mat4x3(rotMatrix[1], rotMatrix[2], rotMatrix[3], position)
    else
        local rotMatrix = fromEulersYXZ(eulerAngles)
        return {rotMatrix[1], rotMatrix[2], rotMatrix[3], position}
    end
end

local function decomposeTransformMatrix(ma)
    if glm then
        return ma[4], toEulersYXZ(mat3x3(ma[1], ma[2], ma[3]))
    else
        return ma[4], toEulersYXZ({ma[1], ma[2], ma[3]})
    end
end

local function getBoneMatrix(entity, boneIndex)
    local boneCoords = GetWorldPositionOfEntityBone(entity, boneIndex)
    local boneRotation = GetEntityBoneRotation(entity, boneIndex)

    if glm then
        return createTransformMatrix(boneCoords, glm.radians(boneRotation))
    else
        -- Convert degrees to radians manually
        local radRotation = vec3(
            boneRotation.x * (math.pi / 180),
            boneRotation.y * (math.pi / 180),
            boneRotation.z * (math.pi / 180)
        )
        return createTransformMatrix(boneCoords, radRotation)
    end
end

-- Toggle gizmo mode with proper matrix handling
local function ToggleGizmoMode()
    if not PropPlacer.data.gizmoMode then
        -- Enable gizmo mode
        if PropPlacer.data.objectHandle then
            DetachEntity(PropPlacer.data.objectHandle)

            -- Get and store initial object matrix
            local _fw, _rt, _up, _at = GetEntityMatrix(PropPlacer.data.objectHandle)

            if glm then
                PropPlacer.objectMatrix = mat4x3(_rt.xyz, _fw.xyz, _up.xyz, _at.xyz)
            else
                PropPlacer.objectMatrix = {_rt, _fw, _up, _at}
            end

            PropPlacer.data.gizmoMode = StartGizmo(PropPlacer.data.objectHandle, function(rtX, rtY, rtZ, fwX, fwY, fwZ, upX, upY, upZ, atX, atY, atZ)
                SetEntityMatrix(
                    PropPlacer.data.objectHandle,
                    fwX, fwY, fwZ,
                    rtX, rtY, rtZ,
                    upX, upY, upZ,
                    atX, atY, atZ
                )

                -- Update stored matrix
                if glm then
                    PropPlacer.objectMatrix = mat4x3(vec3(rtX, rtY, rtZ), vec3(fwX, fwY, fwZ), vec3(upX, upY, upZ), vec3(atX, atY, atZ))
                else
                    PropPlacer.objectMatrix = {
                        vec3(rtX, rtY, rtZ),
                        vec3(fwX, fwY, fwZ),
                        vec3(upX, upY, upZ),
                        vec3(atX, atY, atZ)
                    }
                end
            end)

            PropPlacer.freeCamFrozen = true

            -- Update instructional buttons for gizmo mode
            if PropPlacer.buttonId then
                instructionalButtons[PropPlacer.buttonId] = {
                    { label = "Quitter gizmo", control = 311 },       -- K
                    { label = "Rotation", control = 45 }, -- R
                    { label = "Translation", control = 245 }, -- T
                }
            end
        end
    else
        -- Disable gizmo mode and calculate proper relative transform
        if PropPlacer.data.objectHandle and PropPlacer.data.pedHandle and PropPlacer.objectMatrix then
            local boneTag = PropPlacer.data.selectedBoneTag or CFG.DefaultObjectBone
            local ped = PropPlacer.data.pedHandle
            local boneIndex = GetPedBoneIndex(ped, boneTag)

            -- Get bone matrix and calculate relative transform
            local boneMatrix = getBoneMatrix(ped, boneIndex)
            local objectRelativeMatrix = calculateRelativeTransform(boneMatrix, PropPlacer.objectMatrix)
            local oRPos, oRRot = decomposeTransformMatrix(objectRelativeMatrix)

            -- Convert radians to degrees
            if glm then
                oRRot = glm.degrees(oRRot)
            else
                oRRot = vec3(
                    oRRot.x * (180 / math.pi),
                    oRRot.y * (180 / math.pi),
                    oRRot.z * (180 / math.pi)
                )
            end

            -- Store calculated offsets
            PropPlacer.data.posOffset = oRPos
            PropPlacer.data.rotOffset = oRRot

            -- Re-attach with calculated offsets
            AttachEntityToEntity(
                PropPlacer.data.objectHandle,
                ped,
                boneIndex,
                oRPos.x, oRPos.y, oRPos.z,
                oRRot.x, oRRot.y, oRRot.z,
                false, false, false, false,
                0, -- EulerRotOrder.YXZ
                true
            )
        end

        PropPlacer.data.gizmoMode()
        PropPlacer.data.gizmoMode = nil
        PropPlacer.objectMatrix = nil
        PropPlacer.freeCamFrozen = false

        -- Restore instructional buttons for main mode
        if PropPlacer.buttonId then
            instructionalButtons[PropPlacer.buttonId] = {
                { label = "Sélection d'os", control = 47 },      -- G
                { label = "Mode Gizmo", control = 311 },         -- K
                { label = "Avancer", control = 32 },             -- W
                { label = "Reculer", control = 33 },             -- S
                { label = "Gauche", control = 34 },              -- A
                { label = "Droite", control = 35 },              -- D
                { label = "Monter", control = 38 },              -- E
                { label = "Descendre", control = 44 },           -- Q
            }
        end
    end
end

-- Clean up everything when closing
function PropPlacer.Cleanup()
    print("^2[PROP PLACER] Cleanup function called^7")

    -- Stop any ongoing modes
    if PropPlacer.data.gizmoMode then
        print("^3[PROP PLACER] Stopping gizmo mode^7")
        PropPlacer.data.gizmoMode()
        PropPlacer.data.gizmoMode = nil
    end

    if PropPlacer.data.boneSelectMode then
        print("^3[PROP PLACER] Stopping bone select mode^7")
        PropPlacer.data.boneSelectMode = nil
        -- Make sure to leave cursor mode if it's active
        LeaveCursorMode()
    end

    -- Delete entities
    print("^3[PROP PLACER] Deleting entities^7")
    DeletePed()
    DeleteObject()

    -- Clear camera
    if PropPlacer.freeCam then
        print("^3[PROP PLACER] Destroying camera^7")
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(PropPlacer.freeCam, false)
        PropPlacer.freeCam = nil
    end

    -- Reset player state
    print("^3[PROP PLACER] Resetting player state^7")
    local playerPed = PlayerPedId()
    local playerId = PlayerId()
    SetPlayerControl(playerId, true, 0)
    FreezeEntityPosition(playerPed, false)
    SetEntityInvincible(playerPed, false)
    SetEntityCollision(playerPed, true, false)
    SetEntityVisible(playerPed, true, false)
    SetEveryoneIgnorePlayer(playerId, false)

    -- Clear display
    DisplayRadar(true)

    -- Clear instructional buttons
    if PropPlacer.buttonId then
        instructionalButtons[PropPlacer.buttonId] = nil
        PropPlacer.buttonId = nil
    end

    -- Clear data
    PropPlacer.data = {}
    PropPlacer.active = false

    print("^2[PROP PLACER] Cleanup completed, active = false^7")
end

-- Main toggle function
function PropPlacer.Toggle()
    if PropPlacer.active then
        -- Deactivate and clean up
        PropPlacer.Cleanup()
        return
    end

    -- Activate prop placer
    PropPlacer.active = true
    PropPlacer.speedMultiplier = 1.0 -- Reset speed multiplier

    -- Initialize data
    PropPlacer.data = {
        posOffset = vec3(0.0, 0.0, 0.0),
        rotOffset = vec3(0.0, 0.0, 0.0),
        selectedBoneTag = CFG.DefaultObjectBone
    }

    -- Setup freecam
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)

    PropPlacer.freeCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(PropPlacer.freeCam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(PropPlacer.freeCam, camRot.x, camRot.y, camRot.z, 2)
    SetCamActive(PropPlacer.freeCam, true)
    RenderScriptCams(true, false, 0, true, false)

    DisplayRadar(false)
    SetupPlayer()
    ToggleEntities()

    -- Setup instructional buttons (legends)
    PropPlacer.buttonId = generateUniqueID(8)
    PropPlacer.UpdateMainButtons()

    -- Start control thread
    CreateThread(function()
        while PropPlacer.active do
            Wait(0)

            -- Disable some controls during prop placer (but NOT mouse in gizmo mode!)
            if not PropPlacer.data.gizmoMode then
                DisableControlAction(0, 1, true) -- Look left/right
                DisableControlAction(0, 2, true) -- Look up/down
            end
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 142, true) -- Melee attack
            DisableControlAction(0, 106, true) -- Vehicle mouse control

            -- Freecam controls (only when not in other modes or frozen)
            if PropPlacer.freeCam and not PropPlacer.data.boneSelectMode and not PropPlacer.data.gizmoMode and not PropPlacer.freeCamFrozen then
                -- Scroll wheel speed control (241 = CURSOR_SCROLL_UP, 242 = CURSOR_SCROLL_DOWN)
                local speedChanged = false
                if IsDisabledControlJustPressed(0, 241) or IsControlJustPressed(0, 241) or IsControlJustPressed(0, 17) then -- Scroll Up
                    PropPlacer.speedMultiplier = math.min(PropPlacer.speedMultiplier * 1.5, 10.0)
                    speedChanged = true
                elseif IsDisabledControlJustPressed(0, 242) or IsControlJustPressed(0, 242) or IsControlJustPressed(0, 16) then -- Scroll Down
                    PropPlacer.speedMultiplier = math.max(PropPlacer.speedMultiplier / 1.5, 0.1)
                    speedChanged = true
                end

                -- Update instructional buttons with new speed
                if speedChanged and PropPlacer.buttonId then
                    PropPlacer.UpdateMainButtons()
                end

                local camCoords = GetCamCoord(PropPlacer.freeCam)
                local camRot = GetCamRot(PropPlacer.freeCam, 2)
                local moveSpeed = 0.3 * PropPlacer.speedMultiplier

                if IsDisabledControlPressed(0, 21) then -- Shift for fast
                    moveSpeed = moveSpeed * 3.0
                elseif IsDisabledControlPressed(0, 36) then -- Ctrl for slow
                    moveSpeed = moveSpeed * 0.15
                end

                -- Get forward and right vectors from camera rotation
                local rad = math.rad
                local cos = math.cos
                local sin = math.sin

                local rotX = rad(camRot.x)
                local rotZ = rad(camRot.z)

                local forward = vector3(
                    -sin(rotZ) * cos(rotX),
                    cos(rotZ) * cos(rotX),
                    sin(rotX)
                )

                local right = vector3(
                    cos(rotZ),
                    sin(rotZ),
                    0.0
                )

                -- Camera movement with WASD (use disabled controls)
                local movement = vector3(0, 0, 0)

                if IsDisabledControlPressed(0, 32) then -- W (forward)
                    movement = movement + forward * moveSpeed
                end
                if IsDisabledControlPressed(0, 33) then -- S (backward)
                    movement = movement - forward * moveSpeed
                end
                if IsDisabledControlPressed(0, 34) then -- A (left)
                    movement = movement - right * moveSpeed
                end
                if IsDisabledControlPressed(0, 35) then -- D (right)
                    movement = movement + right * moveSpeed
                end
                if IsDisabledControlPressed(0, 44) then -- Q (down)
                    movement = movement - vector3(0, 0, moveSpeed)
                end
                if IsDisabledControlPressed(0, 38) then -- E (up)
                    movement = movement + vector3(0, 0, moveSpeed)
                end

                -- Apply movement
                if movement.x ~= 0 or movement.y ~= 0 or movement.z ~= 0 then
                    local newCoords = camCoords + movement
                    SetCamCoord(PropPlacer.freeCam, newCoords.x, newCoords.y, newCoords.z)
                end

                -- Camera rotation with mouse (always active in freecam)
                local mouseX = GetDisabledControlNormal(0, 1) * 8.0
                local mouseY = GetDisabledControlNormal(0, 2) * 8.0

                if mouseX ~= 0 or mouseY ~= 0 then
                    local newRotX = camRot.x - mouseY
                    local newRotZ = camRot.z - mouseX

                    -- Clamp pitch to prevent flipping
                    newRotX = math.max(-89.0, math.min(89.0, newRotX))

                    SetCamRot(PropPlacer.freeCam, newRotX, 0.0, newRotZ, 2)
                end
            end

            -- Mode controls
            if IsDisabledControlJustReleased(0, CFG.BoneSelectionModeControl) then
                if PropPlacer.data.gizmoMode then
                    ToggleGizmoMode()
                end
                ToggleBoneSelectMode()
            elseif IsDisabledControlJustPressed(0, CFG.GizmoModeControl) then
                if PropPlacer.data.boneSelectMode then
                    ToggleBoneSelectMode()
                end
                ToggleGizmoMode()
            end
        end
    end)

    -- Show instructions
    VFW.ShowNotification({
        type = 'STAFF', variant = 'INFO', subtitle = 'Placement Props',
        message = "Prop Placer activé | G: Bones | K: Gizmo | WASD: Move | Molette: Vitesse."
  })
end

-- Export functions for menu
_G.PropPlacer = PropPlacer

-- Menu functions
function PropPlacer.ChangePedModel(modelName)
    if not PropPlacer.active then return end

    local model = GetHashKey(modelName)
    if not IsModelInCdimage(model) then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Placement Props',
            message = "Ce modèle de ped n'est pas valide."
      })
        return
    end

    DeletePed()
    DeleteObject()
    PropPlacer.data.pedHandle = SpawnPed(model)
    PropPlacer.data.objectHandle = SpawnObject(PropPlacer.data.objectModel)
end

function PropPlacer.ChangeObjectModel(modelName)
    if not PropPlacer.active then return end

    local model = GetHashKey(modelName)
    if not IsModelInCdimage(model) then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Placement Props',
            message = "Ce modèle d'objet n'est pas valide."
      })
        return
    end

    DeleteObject()
    PropPlacer.data.objectModel = model
    PropPlacer.data.objectHandle = SpawnObject(model)
end

function PropPlacer.PlayAnimation(dict, anim)
    if not PropPlacer.active or not PropPlacer.data.pedHandle then return end

    dict = dict or CFG.DefaultAnim.dict
    anim = anim or CFG.DefaultAnim.anim

    if RequestAnimDictSync(dict) then
        TaskPlayAnim(PropPlacer.data.pedHandle, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        PropPlacer.data.anim = { dict = dict, anim = anim, paused = false }
        RemoveAnimDict(dict)
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Placement Props',
            message = "Cette animation n'est pas valide."
      })
    end
end

function PropPlacer.CopyResult()
    local result = ParseResult()

    VFW.Clipboard(result)

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Placement Props',
        message = "Configuration copiée dans le presse-papier."
  })

    print("^2[Prop Placer Result]^7")
    print(result)
end

function PropPlacer.ImportResult(resultStr)
    if not PropPlacer.active then return end

    -- Parse the result string
    local func, err = load("return " .. resultStr)
    if err then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Placement Props',
            message = "Ce format n'est pas valide."
      })
        return
    end

    local result = func()
    if not result or not result.offset or not result.rotation or not result.boneTag then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Placement Props',
            message = "Données manquantes."
      })
        return
    end

    PropPlacer.data.posOffset = result.offset
    PropPlacer.data.rotOffset = result.rotation
    PropPlacer.data.selectedBoneTag = result.boneTag

    -- Apply to current object
    if PropPlacer.data.objectHandle and PropPlacer.data.pedHandle then
        AttachEntityToEntity(
            PropPlacer.data.objectHandle,
            PropPlacer.data.pedHandle,
            GetPedBoneIndex(PropPlacer.data.pedHandle, result.boneTag),
            result.offset.x, result.offset.y, result.offset.z,
            result.rotation.x, result.rotation.y, result.rotation.z,
            false, false, false, false,
            result.rotOrder or 0,
            true
        )
    end

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Placement Props',
        message = "Configuration importée."
  })
end

-- Register key mappings for gizmo controls
RegisterKeyMapping('+gizmoSelect', 'Sélectionner le gizmo', 'MOUSE_BUTTON', 'MOUSE_LEFT')
RegisterKeyMapping('+gizmoTranslation', 'Mode déplacement (gizmo)', 'keyboard', 'T')
RegisterKeyMapping('+gizmoRotation', 'Mode rotation (gizmo)', 'keyboard', 'R')

-- Register the prop placer with the dev menu
Citizen.CreateThread(function()
    while not StaffMenu or not StaffMenu.developers do
        Wait(100)
    end

    -- The menu integration will be done in the developers.lua file
end)