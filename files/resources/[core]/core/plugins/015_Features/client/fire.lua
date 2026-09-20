local ActiveFires = {}

local function loadPtfxDict(dict)
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(dict) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end
    return HasNamedPtfxAssetLoaded(dict)
end

local function getGroundZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 1.0, true, 0)
    if found then return groundZ end

    found, groundZ = GetGroundZFor_3dCoord(x, y, 850.0, true, 0)
    if found then return groundZ end

    local rayHandle = StartShapeTestRay(x, y, 1000.0, x, y, -100.0, 1, PlayerPedId(), 0)
    local _, hit, endCoords = GetShapeTestResult(rayHandle)
    if hit then return endCoords.z end

    return z
end

local function createFire(fireId, data)
    if ActiveFires[fireId] then return end

    ActiveFires[fireId] = { data = data, scriptFires = {}, particles = {} }

    Citizen.CreateThread(function()
        local pos = data.position
        local info = data.info
        local count = data.flames or 15
        local spread = data.spread or 15

        local baseZ = getGroundZ(pos.x, pos.y, pos.z)

        for i = 1, count do
            if not ActiveFires[fireId] then return end

            local angle = (i / count) * math.pi * 2
            local dist = math.random() * spread
            local x = pos.x + math.cos(angle) * dist
            local y = pos.y + math.sin(angle) * dist
            local z = getGroundZ(x, y, baseZ)

            local fireHandle = StartScriptFire(x, y, z, 25, false)
            ActiveFires[fireId].scriptFires[#ActiveFires[fireId].scriptFires + 1] = fireHandle

            if info and info.dict and info.part then
                if loadPtfxDict(info.dict) then
                    UseParticleFxAssetNextCall(info.dict)
                    local ptfx = StartParticleFxLoopedAtCoord(
                        info.part, x, y, z + (info.zoffset or 0.0),
                        0.0, 0.0, 0.0,
                        info.scale or 1.0, false, false, false, false
                    )
                    ActiveFires[fireId].particles[#ActiveFires[fireId].particles + 1] = ptfx
                end
            end

            if info and info.smoke and info.smoke.playduring and info.smoke.dict and info.smoke.part then
                if loadPtfxDict(info.smoke.dict) then
                    UseParticleFxAssetNextCall(info.smoke.dict)
                    local smoke = StartParticleFxLoopedAtCoord(
                        info.smoke.part,
                        x, y, z + (info.smoke.zoffset or 0.0),
                        0.0, 0.0, 0.0,
                        info.smoke.scale or 1.0, false, false, false, false
                    )
                    ActiveFires[fireId].particles[#ActiveFires[fireId].particles + 1] = smoke
                end
            end

            if i % 3 == 0 then
                Citizen.Wait(0)
            end
        end
    end)
end

local function removeFire(fireId)
    local fire = ActiveFires[fireId]
    if not fire then return end

    for _, handle in ipairs(fire.scriptFires or {}) do
        RemoveScriptFire(handle)
    end

    for _, handle in ipairs(fire.particles or {}) do
        StopParticleFxLooped(handle, false)
    end

    local pos = fire.data.position
    local spread = fire.data.spread or 15
    StopFireInRange(pos.x, pos.y, pos.z, spread + 10.0)

    ActiveFires[fireId] = nil
end

local function removeAllFires()
    for id, _ in pairs(ActiveFires) do
        removeFire(id)
    end
    ActiveFires = {}
end

RegisterNetEvent("fire:sync", function(fireId, data)
    createFire(fireId, data)
end)

RegisterNetEvent("fire:remove", function(fireId)
    removeFire(fireId)
end)

RegisterNetEvent("fire:removeAll", function()
    removeAllFires()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == "core" then
        removeAllFires()
    end
end)
