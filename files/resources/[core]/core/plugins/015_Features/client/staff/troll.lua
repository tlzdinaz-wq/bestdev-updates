---@meta _
---@diagnostic disable: duplicate-doc-field

--- RoundNumberAucasou
---@param n any
---@return any
local function RoundNumberAucasou(n)
    n = n + 0.00000
    return n
end

local InsideOrbitalCannon, oc_manual, oc_automatic, oc_surveillance = false, false, false, true
local oc_speed = RoundNumberAucasou(8)
local oc_pos = vector3(0, 0, 0)
local cam = nil
local oc_height = RoundNumberAucasou(1000)
local oc_target = nil
local oc_countdown = false
local oc_countdown_text = 3

local orbitalOverlayShown = false
local orbitalMarkerSentAt = 0
local orbitalMarkerSignature = nil

local ORBITAL_MARKER_INTERVAL = 50

local function SetOrbitalOverlay(state, isDev)
    if orbitalOverlayShown == state then return end
    orbitalOverlayShown = state

    if not state then
        SendNUIMessage({ action = "hud:orbital:hide", data = {} })
        return
    end

    SendNUIMessage({
        action = "hud:orbital:show",
        data = { dev = isDev, surveillance = oc_surveillance }
    })
end

local function SendOrbitalMarkers()
    local now = GetGameTimer()
    if (now - orbitalMarkerSentAt) < ORBITAL_MARKER_INTERVAL then return end

    local markers = {}
    local parts = {}
    local localPlayer = PlayerId()

    for k, i in pairs(GetActivePlayers()) do
        if NetworkIsPlayerActive(i) and (IsEntityDead(GetPlayerPed(i)) == false) and (IsEntityVisible(GetPlayerPed(i))) then
            local pos = GetEntityCoords(GetPlayerPed(i))
            local b, x, y = GetHudScreenPositionFromWorldPosition(pos.x, pos.y, pos.z)
            local kind

            if i == localPlayer then
                kind = (not b) and "self" or "selfArrow"
            elseif oc_target == i then
                kind = "target"
            elseif not b then
                kind = "other"
            else
                kind = "otherArrow"
            end

            markers[#markers + 1] = { id = i, kind = kind, x = x, y = y }
            parts[#parts + 1] = string.format("%d:%s:%.4f:%.4f", i, kind, x, y)
        end
    end

    local signature = table.concat(parts, "|")
    if signature == orbitalMarkerSignature then return end

    orbitalMarkerSentAt = now
    orbitalMarkerSignature = signature

    SendNUIMessage({
        action = "hud:orbital:markers",
        data = { targeted = oc_target ~= nil, markers = markers }
    })
end

--- FireOrbitalCannon
---@param lock any
---@param var any
local function FireOrbitalCannon(lock, var)
    if lock then
        CreateThread(function()
            local playerPed = PlayerPedId()
            oc_countdown = true
            oc_countdown_text = 3

            Wait(1000)

            oc_countdown_text = 2

            Wait(1000)

            oc_countdown_text = 1

            Wait(1000)

            oc_countdown = false

            local ped = var
            local pos = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)

            if not HasWeaponAssetLoaded(GetHashKey("WEAPON_VEHICLE_ROCKET")) then
                RequestWeaponAsset(GetHashKey("WEAPON_VEHICLE_ROCKET"), 31, 0)

                while not HasWeaponAssetLoaded(GetHashKey("WEAPON_VEHICLE_ROCKET")) do
                    Wait(0)
                end
            end

            local offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, 0, 0, 0)
            RequestCollisionAtCoord(offset)
            offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, 0, 0, 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
            offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, RoundNumberAucasou(-3), 0, 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
            offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, RoundNumberAucasou(3), 0, 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
            offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, 0, RoundNumberAucasou(-3), 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
            offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, 0, RoundNumberAucasou(3), 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
            Wait(1000)
        end)
    else
        CreateThread(function()
            local playerPed = PlayerPedId()
            oc_countdown = true
            oc_countdown_text = 3

            Wait(1000)

            oc_countdown_text = 2

            Wait(1000)

            oc_countdown_text = 1

            Wait(1000)

            oc_countdown = false

            local pos = oc_pos
            local heading = 0

            SetFocusArea(pos, 0, 0, 0)

            if not HasWeaponAssetLoaded(GetHashKey("WEAPON_VEHICLE_ROCKET")) then
                RequestWeaponAsset(GetHashKey("WEAPON_VEHICLE_ROCKET"), 31, 0)

                while not HasWeaponAssetLoaded(GetHashKey("WEAPON_VEHICLE_ROCKET")) do
                    Wait(0)
                end
            end

            local offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, 0, 0, 0)
            RequestCollisionAtCoord(offset)
            offset = GetObjectOffsetFromCoords(pos.x ,pos.y, pos.z, heading, 0, 0, 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
            offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, RoundNumberAucasou(-3), 0, 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
            offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, RoundNumberAucasou(3), 0, 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
            offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, 0, RoundNumberAucasou(-3), 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
            offset = GetObjectOffsetFromCoords(pos.x, pos.y, pos.z, heading, 0, RoundNumberAucasou(3), 0)
            ShootSingleBulletBetweenCoords(offset + vector3(0, 0, 5), offset, 5000, 0, GetHashKey("WEAPON_VEHICLE_ROCKET"), playerPed, 1, 0, RoundNumberAucasou(9000))
        end)
    end
end

local instrucOC = {
    [1] = generateUniqueID(),
    [2] = generateUniqueID()
}

--- StartOrbital
function StartOrbital()
    local playerPed = PlayerPedId()

    Wait(250)

    instructionalButtons[instrucOC[1]] = {
        { control = 202, label = "Retour" },
        { control = 15, label = "Zoom" },
        { control = 16, label = "Zoom" },
        -- { control = 201, label = "Tirer" },
    }

    InsideOrbitalCannon = true

    local antispam = false
    local lastCountdown = nil
    local lastCountdownText = nil

    while true do
        Wait(0)

        if InsideOrbitalCannon then
            if not antispam then
                antispam = true

                local ped = playerPed
                local pos = GetEntityCoords(ped)

                FreezeEntityPosition(ped, true)
                SetEntityCollision(ped, false, 0)
                SetEntityInvincible(ped, true)
                SetPedDiesInWater(ped, 0)

                if not DoesCamExist(cam) then
                    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA",false)

                    SetCamCoord(cam,vector3(pos.x, pos.y, oc_height))
                    SetCamRot(cam, -RoundNumberAucasou(90), RoundNumberAucasou(0), RoundNumberAucasou(0), 2)
                    SetCamActive(cam, true)
                    StopCamPointing(cam)
                    RenderScriptCams(true,true,0,0,0,0)
                else
                    SetCamRot(cam, -RoundNumberAucasou(90), RoundNumberAucasou(0), RoundNumberAucasou(0), 2)
                    SetCamActive(cam, true)
                    StopCamPointing(cam)
                    RenderScriptCams(true,true,0,0,0,0)
                end

                StartScreenEffect("DeathFailNeutralIn",0,true)
            end
        else
            SetOrbitalOverlay(false)
            StopScreenEffect("DeathFailNeutralIn")

            local ped = playerPed

            FreezeEntityPosition(ped, false)
            SetEntityCollision(ped, true, 1)
            SetEntityInvincible(ped, false)
            SetPedDiesInWater(ped, 1)
            SetCamActive(cam,false)
            StopCamPointing(cam)
            RenderScriptCams(0, 0, 0, 0, 0, 0)
            SetFocusEntity(ped)

            Wait(250)

        end

        if InsideOrbitalCannon then
            if IsEntityDead(playerPed) then
                StopScreenEffect("DeathFailNeutralIn")

                local ped = playerPed

                FreezeEntityPosition(ped, false)
                SetEntityCollision(ped, true, 1)
                SetEntityInvincible(ped, false)
                SetPedDiesInWater(ped, 1)
                SetCamActive(cam,false)
                StopCamPointing(cam)
                RenderScriptCams(0, 0, 0, 0, 0, 0)
                SetFocusEntity(ped)

                Wait(250)

                break
            end

            DisableControlAction(2, 26, true)
            DisableControlAction(2, 16, true)
            DisableControlAction(2, 17, true)

            local isDev = (VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["dev"]) and true or false

            SetOrbitalOverlay(true, isDev)

            if oc_countdown ~= lastCountdown or oc_countdown_text ~= lastCountdownText then
                lastCountdown = oc_countdown
                lastCountdownText = oc_countdown_text

                SendNUIMessage({
                    action = "hud:orbital:countdown",
                    data = { active = oc_countdown, value = oc_countdown_text }
                })
            end

            if oc_automatic or oc_manual or oc_surveillance then
                SendOrbitalMarkers()
            end

            if IsControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 202) then
                InsideOrbitalCannon = false

                StopScreenEffect("DeathFailNeutralIn")

                local ped = playerPed

                FreezeEntityPosition(ped, false)
                SetEntityCollision(ped, true, 1)
                SetEntityInvincible(ped, false)
                SetPedDiesInWater(ped, 1)
                SetCamActive(cam,false)
                StopCamPointing(cam)
                RenderScriptCams(0, 0, 0, 0, 0, 0)
                SetFocusEntity(ped)
                StopScreenEffect("DeathFailNeutralIn")
                instructionalButtons[instrucOC[1]] = {}

                Wait(250)

                break
            end

            if oc_manual or oc_surveillance then
                if IsPauseMenuActive() == false then
                    local rotation = GetCamRot(cam, 2)
                    local position = GetCamCoord(cam)
                    local heading = rotation.z
                    local g = Citizen.InvokeNative(0xC906A7DAB05C8D2B,position, Citizen.PointerValueFloat(), 0)

                    SetFocusArea(position.x, position.y, g, 0, 0, 0)

                    if IsDisabledControlPressed(2,15) or IsControlPressed(2,15) then
                        if oc_height > 50 then
                            oc_height = oc_height - oc_speed * 2

                            SetCamCoord(cam, vector3(position.x, position.y, oc_height))
                            RenderScriptCams(1, 1, 0, 0, 0)
                        end
                    end

                    if IsDisabledControlPressed(2, 16) or IsControlPressed(2, 16) then
                        if oc_height < 2000 then
                            oc_height = oc_height + oc_speed * 2

                            SetCamCoord(cam, vector3(position.x, position.y, oc_height))
                            RenderScriptCams(1, 1, 0, 0, 0)
                        end
                    end

                    if IsDisabledControlPressed(2, 33) then
                        SetCamCoord(cam, GetObjectOffsetFromCoords(position.x, position.y, position.z, heading, 0, -oc_speed, 0))
                    end

                    if IsDisabledControlPressed(2, 32) then
                        SetCamCoord(cam, GetObjectOffsetFromCoords(position.x, position.y, position.z, heading, 0, oc_speed, 0))
                    end

                    if IsDisabledControlPressed(2, 34) then
                        SetCamCoord(cam, GetObjectOffsetFromCoords(position.x, position.y, position.z, heading, -oc_speed, 0, 0))
                    end

                    if IsDisabledControlPressed(2, 35) then
                        SetCamCoord(cam, GetObjectOffsetFromCoords(position.x, position.y, position.z, heading, oc_speed, 0, 0))
                    end

                    local rightAxisX = GetDisabledControlNormal(0, 270)
                    local rightAxisY = GetDisabledControlNormal(0, 272)

                    if (rightAxisX ~= 0 and rightAxisY ~= 0) then
                        local newY = position.y - rightAxisY * RoundNumberAucasou(10) * oc_speed
                        local newX = position.x + rightAxisX * RoundNumberAucasou(10) * oc_speed

                        SetCamCoord(cam,newX, newY, position.z,2)
                    end

                    if oc_manual then
                        oc_pos = vector3(position.x, position.y, g)

                        if IsDisabledControlJustPressed(2, 201) or IsDisabledControlJustPressed(2, 24) then
                            if oc_countdown == false then
                                FireOrbitalCannon(false)
                            end
                        end
                    end
                end
            elseif oc_automatic then
                local ped = GetPlayerPed(oc_target)
                local position = GetEntityCoords(ped)

                SetCamCoord(cam,vector3(position.x,position.y,position.z+ 250))

                oc_height = position.z+ 250

                SetFocusArea(position, 0, 0, 0)
            end
        end
    end

    SetOrbitalOverlay(false)
end

RegisterCommand("orbital", function()
    if not VFW.PlayerData or not VFW.PlayerGlobalData.permissions or not VFW.PlayerGlobalData.permissions["dev"] then
        return
    end
    
    StartOrbital()
end)
