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

local IllegalGizmo = {}
IllegalGizmo.active = false
IllegalGizmo.prop = nil
IllegalGizmo.freeCam = nil
IllegalGizmo.callback = nil
IllegalGizmo.buttonId = nil
IllegalGizmo.speedMultiplier = 1.0
IllegalGizmo.markerColor = nil

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

local function RequestModelSync(model)
    if type(model) == "string" then
        model = GetHashKey(model)
    end
    if not IsModelInCdimage(model) then
        return false
    end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then return false end
    end
    return true
end

local function SetupPlayer(freeze)
    local playerPed = PlayerPedId()
    local playerId = PlayerId()
    SetPlayerControl(playerId, not freeze, 0)
    FreezeEntityPosition(playerPed, freeze)
    SetEntityInvincible(playerPed, freeze)
    SetEntityCollision(playerPed, not freeze, false)
    SetEntityVisible(playerPed, not freeze, false)
    SetEveryoneIgnorePlayer(playerId, freeze)
end

local function UpdateButtons()
    if not IllegalGizmo.buttonId then return end
    local speedText = string.format("Molette (x%.1f)", IllegalGizmo.speedMultiplier)
    instructionalButtons[IllegalGizmo.buttonId] = {
        { label = "Valider", control = 201 },
        { label = "Annuler", control = 202 },
        { label = "Mode Gizmo", control = 311 },
        { label = "Avancer", control = 32 },
        { label = "Reculer", control = 33 },
        { label = "Gauche", control = 34 },
        { label = "Droite", control = 35 },
        { label = "Monter", control = 38 },
        { label = "Descendre", control = 44 },
        { label = speedText, control = 241 },
    }
end

local function UpdateGizmoButtons()
    if not IllegalGizmo.buttonId then return end
    instructionalButtons[IllegalGizmo.buttonId] = {
        { label = "Valider", control = 201 },
        { label = "Annuler", control = 202 },
        { label = "Quitter Gizmo", control = 311 },
        { label = "Rotation", control = 45 },
        { label = "Translation", control = 245 },
    }
end

function IllegalGizmo.Start(propModel, initialCoords, initialRotation, callback, markerColor)
    if IllegalGizmo.active then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Illégaux', message = "Un gizmo est déjà actif." })
        return
    end

    if not propModel or propModel == "" then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Illégaux', message = "Modèle de prop requis." })
        return
    end

    if not RequestModelSync(propModel) then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Illégaux', message = "Ce modèle n'est pas valide: " .. tostring(propModel) .. "." })
        return
    end

    IllegalGizmo.active = true
    IllegalGizmo.callback = callback
    IllegalGizmo.speedMultiplier = 1.0
    IllegalGizmo.gizmoMode = false
    IllegalGizmo.markerColor = markerColor

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local spawnCoords = initialCoords or vector3(playerCoords.x, playerCoords.y + 3.0, playerCoords.z)
    local spawnRotation = initialRotation or vector3(0.0, 0.0, 0.0)

    local modelHash = type(propModel) == "string" and GetHashKey(propModel) or propModel
    IllegalGizmo.prop = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityRotation(IllegalGizmo.prop, spawnRotation.x, spawnRotation.y, spawnRotation.z, 2, true)
    SetEntityAlpha(IllegalGizmo.prop, 200, false)
    FreezeEntityPosition(IllegalGizmo.prop, true)
    SetEntityCollision(IllegalGizmo.prop, false, false)
    SetEntityDrawOutline(IllegalGizmo.prop, true)

    SetModelAsNoLongerNeeded(modelHash)

    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)

    IllegalGizmo.freeCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(IllegalGizmo.freeCam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(IllegalGizmo.freeCam, camRot.x, camRot.y, camRot.z, 2)
    SetCamActive(IllegalGizmo.freeCam, true)
    RenderScriptCams(true, false, 0, true, false)

    DisplayRadar(false)
    SetupPlayer(true)

    IllegalGizmo.buttonId = generateUniqueID(8)
    UpdateButtons()

    VFW.ShowNotification({
        type = 'STAFF', variant = 'INFO', subtitle = 'Outils Illégaux',
        message = "Gizmo activé | Entrée: Valider | Retour: Annuler | K: Mode Gizmo"
  })

    CreateThread(function()
        local stopGizmoFn = nil

        while IllegalGizmo.active do
            Wait(0)

            if IllegalGizmo.prop and DoesEntityExist(IllegalGizmo.prop) and IllegalGizmo.markerColor then
                local propCoords = GetEntityCoords(IllegalGizmo.prop)
                local propRotation = GetEntityRotation(IllegalGizmo.prop, 2)
                local heading = math.rad(propRotation.z or 0)
                local markerX = propCoords.x + math.sin(heading) * 1.0
                local markerY = propCoords.y - math.cos(heading) * 1.0
                DrawMarker(
                    1,
                    markerX, markerY, propCoords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.6, 0.6, 0.1,
                    IllegalGizmo.markerColor.r or 139,
                    IllegalGizmo.markerColor.g or 0,
                    IllegalGizmo.markerColor.b or 0,
                    IllegalGizmo.markerColor.a or 100,
                    false, false,
                    2, false,
                    nil, nil, false
                )
            end

            if not IllegalGizmo.gizmoMode then
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
            end
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 106, true)
            DisableControlAction(0, 25, true)

            if IsDisabledControlJustPressed(0, 311) then
                if not IllegalGizmo.gizmoMode then
                    IllegalGizmo.gizmoMode = true
                    EnterCursorMode()
                    UpdateGizmoButtons()

                    stopGizmoFn = function()
                        IllegalGizmo.gizmoMode = false
                        LeaveCursorMode()
                        UpdateButtons()
                    end
                else
                    if stopGizmoFn then stopGizmoFn() end
                    stopGizmoFn = nil
                end
            end

            if IllegalGizmo.gizmoMode and IllegalGizmo.prop then
                local matrixBuffer = makeMatrix(GetEntityMatrix(IllegalGizmo.prop))
                local matrixModified = Citizen.InvokeNative(0xEB2EDCA2, matrixBuffer:Buffer(), 'IllegalBuilder', Citizen.ReturnResultAnyway())

                if matrixModified then
                    local rtX, rtY, rtZ = matrixBuffer:GetFloat32(0), matrixBuffer:GetFloat32(4), matrixBuffer:GetFloat32(8)
                    local fwX, fwY, fwZ = matrixBuffer:GetFloat32(16), matrixBuffer:GetFloat32(20), matrixBuffer:GetFloat32(24)
                    local upX, upY, upZ = matrixBuffer:GetFloat32(32), matrixBuffer:GetFloat32(36), matrixBuffer:GetFloat32(40)
                    local atX, atY, atZ = matrixBuffer:GetFloat32(48), matrixBuffer:GetFloat32(52), matrixBuffer:GetFloat32(56)

                    SetEntityMatrix(IllegalGizmo.prop, fwX, fwY, fwZ, rtX, rtY, rtZ, upX, upY, upZ, atX, atY, atZ)
                end
            end

            if IllegalGizmo.freeCam and not IllegalGizmo.gizmoMode then
                local speedChanged = false
                if IsDisabledControlJustPressed(0, 241) or IsControlJustPressed(0, 241) or IsControlJustPressed(0, 17) then
                    IllegalGizmo.speedMultiplier = math.min(IllegalGizmo.speedMultiplier * 1.5, 10.0)
                    speedChanged = true
                elseif IsDisabledControlJustPressed(0, 242) or IsControlJustPressed(0, 242) or IsControlJustPressed(0, 16) then
                    IllegalGizmo.speedMultiplier = math.max(IllegalGizmo.speedMultiplier / 1.5, 0.1)
                    speedChanged = true
                end

                if speedChanged then
                    UpdateButtons()
                end

                local camCoords = GetCamCoord(IllegalGizmo.freeCam)
                local camRot = GetCamRot(IllegalGizmo.freeCam, 2)
                local moveSpeed = 0.3 * IllegalGizmo.speedMultiplier

                if IsDisabledControlPressed(0, 21) then
                    moveSpeed = moveSpeed * 3.0
                elseif IsDisabledControlPressed(0, 36) then
                    moveSpeed = moveSpeed * 0.15
                end

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

                local movement = vector3(0, 0, 0)

                if IsDisabledControlPressed(0, 32) then
                    movement = movement + forward * moveSpeed
                end
                if IsDisabledControlPressed(0, 33) then
                    movement = movement - forward * moveSpeed
                end
                if IsDisabledControlPressed(0, 34) then
                    movement = movement - right * moveSpeed
                end
                if IsDisabledControlPressed(0, 35) then
                    movement = movement + right * moveSpeed
                end
                if IsDisabledControlPressed(0, 44) then
                    movement = movement - vector3(0, 0, moveSpeed)
                end
                if IsDisabledControlPressed(0, 38) then
                    movement = movement + vector3(0, 0, moveSpeed)
                end

                if movement.x ~= 0 or movement.y ~= 0 or movement.z ~= 0 then
                    local newCoords = camCoords + movement
                    SetCamCoord(IllegalGizmo.freeCam, newCoords.x, newCoords.y, newCoords.z)
                end

                local mouseX = GetDisabledControlNormal(0, 1) * 8.0
                local mouseY = GetDisabledControlNormal(0, 2) * 8.0

                if mouseX ~= 0 or mouseY ~= 0 then
                    local newRotX = camRot.x - mouseY
                    local newRotZ = camRot.z - mouseX
                    newRotX = math.max(-89.0, math.min(89.0, newRotX))
                    SetCamRot(IllegalGizmo.freeCam, newRotX, 0.0, newRotZ, 2)
                end
            end

            if IsDisabledControlJustPressed(0, 201) then
                local coords = GetEntityCoords(IllegalGizmo.prop)
                local rotation = GetEntityRotation(IllegalGizmo.prop, 2)

                if stopGizmoFn then stopGizmoFn() end
                IllegalGizmo.Stop(true, coords, rotation)
                break
            end

            if IsDisabledControlJustPressed(0, 202) then
                if stopGizmoFn then stopGizmoFn() end
                IllegalGizmo.Stop(false)
                break
            end
        end
    end)
end

function IllegalGizmo.Stop(success, coords, rotation)
    if IllegalGizmo.gizmoMode then
        LeaveCursorMode()
        IllegalGizmo.gizmoMode = false
    end

    if IllegalGizmo.prop and DoesEntityExist(IllegalGizmo.prop) then
        DeleteEntity(IllegalGizmo.prop)
        IllegalGizmo.prop = nil
    end

    if IllegalGizmo.freeCam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(IllegalGizmo.freeCam, false)
        IllegalGizmo.freeCam = nil
    end

    SetupPlayer(false)
    DisplayRadar(true)

    if IllegalGizmo.buttonId then
        instructionalButtons[IllegalGizmo.buttonId] = nil
        IllegalGizmo.buttonId = nil
    end

    local callback = IllegalGizmo.callback
    IllegalGizmo.callback = nil
    IllegalGizmo.active = false
    IllegalGizmo.markerColor = nil

    if callback then
        if success then
            callback(coords, rotation)
        else
            callback(nil, nil)
        end
    end
end

RegisterNetEvent("illegalBuilder:startGizmo", function(propModel, initialCoords, initialRotation, callback, markerColor)
    IllegalGizmo.Start(propModel, initialCoords, initialRotation, callback, markerColor)
end)

_G.IllegalGizmo = IllegalGizmo
