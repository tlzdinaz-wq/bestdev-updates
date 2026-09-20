---@meta _
---@diagnostic disable: duplicate-doc-field

local weaponCases = {}
local needDouille = false
local boucle = false
local cooldown = 0

---Trigger VFW.Douille
---@param weapon string Weapon name
function VFW.TriggerDouille(weapon)
    if needDouille and (GetGameTimer() > cooldown) then
        cooldown = GetGameTimer() + 2000
        TriggerServerEvent("core:jobs:server:shootingcases", GetEntityCoords(VFW.PlayerData.ped), GetWeapontypeGroup(weapon), LastWeaponId)
    end
end

---@param data table
RegisterNetEvent("core:jobs:client:shootingcases", function(data)
    table.insert(weaponCases, data)
end)

--- PlayAnim
---@param animDict any
---@param animName string
---@param duration any
local function PlayAnim(animDict, animName, duration)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end

    TaskPlayAnim(VFW.PlayerData.ped, animDict, animName, 8.0, -8.0, duration, 0, 0, false, false, false)
    RemoveAnimDict(animDict)
    Wait(duration)
end

local defaultTextConfig = {
    xyz = { x = -1377.514282266, y = -2852.64941406, z = 13.9448 },
    text = {
        content = "Test",
        rgb = { 255, 255, 255 },
        textOutline = true,
        scaleMultiplier = 0.8,
        font = 0
    },
    perspectiveScale = 0.1,
}

--- Draw3DText
---@param params table Parameters
local function Draw3DText(params)
    params = params or defaultTextConfig
    local textCfg = params.text or defaultTextConfig.text
    local coords = params.xyz or defaultTextConfig.xyz

    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)

    if onScreen then
        SetTextScale(0.0, 0.35 * (textCfg.scaleMultiplier or 0.8))
        SetTextFont(textCfg.font)
        SetTextProportional(true)
        SetTextColour(textCfg.rgb[1], textCfg.rgb[2], textCfg.rgb[3], 255)
        if textCfg.textOutline then
            SetTextOutline()
        end

        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(textCfg.content or "Test")
        DrawText(x, y)
    end
end

--- IsLookingAtCoords
---@param x any
---@param y any
---@param z any
---@param tolerance any
---@return boolean
local function IsLookingAtCoords(x, y, z, tolerance)
    local camCoords = GetGameplayCamCoord()
    local direction = GetGameplayCamRot(2)
    local camForward = {
        x = -math.sin(math.rad(direction.z)) * math.abs(math.cos(math.rad(direction.x))),
        y = math.cos(math.rad(direction.z)) * math.abs(math.cos(math.rad(direction.x))),
        z = math.sin(math.rad(direction.x))
    }

    local targetVector = vector3(x - camCoords.x, y - camCoords.y, z - camCoords.z)
    local dotProduct = camForward.x * targetVector.x + camForward.y * targetVector.y + camForward.z * targetVector.z
    local targetMagnitude = math.sqrt(targetVector.x * targetVector.x + targetVector.y * targetVector.y + targetVector.z * targetVector.z)
    local camMagnitude = math.sqrt(camForward.x * camForward.x + camForward.y * camForward.y + camForward.z * camForward.z)

    local angle = math.acos(dotProduct / (targetMagnitude * camMagnitude)) * (180 / math.pi)

    if angle < tolerance then
        return true
    else
        return false
    end
end

---Load DouilleWeapon
local function loadDouilleWeapon()
    CreateThread(function()
        while boucle do
            if next(weaponCases) then
                local playerPed = VFW.PlayerData.ped
                local playerCoords = GetEntityCoords(playerPed)

                if VFW.PlayerData.job.type == "faction" and GetSelectedPedWeapon(playerPed) == `weapon_flashlight` and IsPlayerFreeAiming(PlayerId()) then
                    for k, v in pairs(weaponCases) do
                        local distance = #(playerCoords - v.pos)

                        if distance < 10.0 and IsLookingAtCoords(v.pos.x, v.pos.y, v.pos.z, 20.0) then
                            DrawMarker(25, v.pos.x, v.pos.y, v.pos.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 255, 255, 170, 0, 1, 2, 0, nil, nil, 0)

                            Draw3DText({
                                xyz = { x = v.pos.x, y = v.pos.y, z = v.pos.z - 0.95 },
                                text = {
                                    content = string.format("Munition %s\nHeure : %s", v.typeAmmo, v.time),
                                    rgb = { 255, 255, 255 },
                                    textOutline = true,
                                    scaleMultiplier = 0.8,
                                    font = 0
                                }
                            })

                            if distance < 2.0 and VFW.Interact.JustPressed(0, 38) then
                                PlayAnim("amb@medic@standing@kneel@base", "base", 2000)

                                VFW.ShowNotification({
                                    type = 'VERT',
                                    content = "~c Vous avez récupéré la douille"
                                })

                                table.remove(weaponCases, k)
                                ClearPedTasks(playerPed)
                                RemoveAnimDict("amb@medic@standing@kneel@base")

                                TriggerServerEvent("core:jobs:server:addDouille", {
                                    time = v.time,
                                    typeAmmo = v.typeAmmo,
                                    id = v.id
                                })
                            end
                        end
                    end

                    Wait(0)
                else
                    Wait(1000)
                end
            else
                Wait(5000)
            end
        end
    end)
end

---@param metadata table
RegisterNetEvent("core:jobs:clientusedouille", function(metadata)
    VFW.CloseInventory()

    Wait(150)

    local message = string.format("Information sur la douille :\nHeure : %s\nMunition %s", metadata.time, metadata.typeAmmo)

    if metadata.id then
        message = message .. string.format("\nNuméro de série de l'arme : %s", metadata.id)
    else
        message = message .. "\nNuméro de série de l'arme rayé"
    end

    VFW.ShowNotification({
        type = 'JAUNE',
        content = message
    })
end)

local lastJob = nil
local lastJob2 = nil

---@param Job table Job data
RegisterNetEvent("vfw:setJob", function(Job)
    if Job.type == "faction" then
        lastJob = nil
        needDouille = false
        return
    end

    lastJob = Job.type
    needDouille = true
end)

RegisterNetEvent("vfw:playerReady", function()
    if lastJob == VFW.PlayerData.job.type then
        return
    end

    if VFW.PlayerData.job.type == "faction" then
        needDouille = false
        return
    end

    needDouille = true
end)

---@param Job table Job data
RegisterNetEvent("vfw:setJob", function(Job)
    if Job.type ~= "faction" then
        lastJob2 = nil
        boucle = false
        return
    end

    lastJob2 = Job.type
    boucle = true
    loadDouilleWeapon()
end)

RegisterNetEvent("vfw:playerReady", function()
    if lastJob2 == VFW.PlayerData.job.type then
        return
    end

    if VFW.PlayerData.job.type ~= "faction" then
        boucle = false
        return
    end

    boucle = true
    loadDouilleWeapon()
end)
