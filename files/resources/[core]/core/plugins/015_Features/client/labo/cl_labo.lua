local labos = {}
local isInsideLabo = nil
local currentLaboData = nil
local lastTpTime = 0
local lastExitTime = 0
local floatingShownId = nil
local laboBlips = {}
local attackGpsBlip = nil
local attackGpsLaboId = nil
local attackStates = {}

local INTERACT_DIST = 1.5
local TP_COOLDOWN = 3000
local ATTACK_RANGE = 5.0

Citizen.CreateThread(function()
    RequestIpl("bkr_biker_interior_placement_interior_2_biker_dlc_int_ware01_milo")
    local meth = GetInteriorAtCoords(1009.5, -3196.6, -38.99682)
    if meth ~= 0 then
        EnableInteriorProp(meth, "security_high")
        EnableInteriorProp(meth, "equipment_upgrade")
        EnableInteriorProp(meth, "production_upgrade")
        RefreshInterior(meth)
    end

    RequestIpl("bkr_biker_interior_placement_interior_2_biker_dlc_int_ware02_milo")
    local weed = GetInteriorAtCoords(1051.5, -3196.6, -38.99682)
    if weed ~= 0 then
        EnableInteriorProp(weed, "security_high")
        EnableInteriorProp(weed, "equipment_upgrade")
        EnableInteriorProp(weed, "production_upgrade")
        RefreshInterior(weed)
    end

    RequestIpl("bkr_biker_interior_placement_interior_2_biker_dlc_int_ware03_milo")
    local coke = GetInteriorAtCoords(1093.6, -3196.6, -38.99841)
    if coke ~= 0 then
        EnableInteriorProp(coke, "security_high")
        EnableInteriorProp(coke, "equipment_upgrade")
        EnableInteriorProp(coke, "production_upgrade")
        EnableInteriorProp(coke, "table_equipment_upgrade")
        EnableInteriorProp(coke, "coke_press_upgrade")
        RefreshInterior(coke)
    end
end)

local function ShowFloating(id, worldPos, buttons)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z)
    if not onScreen then
        if floatingShownId == id then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            floatingShownId = nil
        end
        return
    end

    local data = {
        id = id,
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = buttons
    }

    if floatingShownId == id then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        if floatingShownId then
            SendNUIMessage({ action = "floatingInteraction:hide" })
        end
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        floatingShownId = id
    end
end

local function HideFloating()
    if floatingShownId then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        floatingShownId = nil
    end
end

local function RefreshBlips()
    for _, blip in pairs(laboBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    laboBlips = {}

    for _, labo in pairs(labos) do
        if labo.has_access and labo.blip_sprite and labo.owner_faction ~= "no_owner" then
            local blip = AddBlipForCoord(labo.door_x, labo.door_y, labo.door_z)
            SetBlipSprite(blip, labo.blip_sprite or 499)
            SetBlipColour(blip, labo.blip_color or 1)
            SetBlipScale(blip, labo.blip_scale or 0.5)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(labo.label or labo.name or "Laboratoire")
            EndTextCommandSetBlipName(blip)
            laboBlips[labo.id] = blip
        end
    end
end

local function RemoveAttackGps(laboId)
    if not attackGpsBlip then return end
    if laboId and attackGpsLaboId and laboId ~= attackGpsLaboId then return end
    if DoesBlipExist(attackGpsBlip) then
        RemoveBlip(attackGpsBlip)
    end
    attackGpsBlip = nil
    attackGpsLaboId = nil
    SetNewWaypoint(0.0, 0.0)
    DeleteWaypoint()
end

local function SendAttackBarNUI(state)
    if not state then return end
    SendNUIMessage({
        action = "attackBar:update",
        data = {
            laboName = state.laboName or "Labo",
            progress = (state.progress or 0) / 100,
            paused = state.paused or false,
            timeLeft = (state.timeLeft or 0) * 1000,
            attackerCount = state.attackerCount or 0,
            defenderCount = state.defenderCount or 0,
            isDefender = state.isDefender or false,
            attackerLabel = state.attackerLabel or "Attaquants",
            defenderLabel = state.defenderLabel or "Defenseurs"
        }
    })
end

local function ShowAttackBar(state)
    SendNUIMessage({
        action = "attackBar:show",
        data = {
            laboName = state.laboName or "Labo",
            progress = (state.progress or 0) / 100,
            paused = state.paused or false,
            timeLeft = (state.timeLeft or 0) * 1000,
            attackerCount = state.attackerCount or 0,
            defenderCount = state.defenderCount or 0,
            isDefender = state.isDefender or false,
            attackerLabel = state.attackerLabel or "Attaquants",
            defenderLabel = state.defenderLabel or "Defenseurs"
        }
    })
end

local function HideAttackBar()
    SendNUIMessage({ action = "attackBar:hide" })
end

CreateThread(function()
    while not VFW.IsPlayerLoaded() do
        Wait(500)
    end
    while not VFW.PlayerData.faction do
        Wait(1000)
    end
    labos = TriggerServerCallback("labo:getLabos") or {}
    RefreshBlips()

    for attempt = 1, 5 do
        Wait(2000)
        local reconnectData = TriggerServerCallback("labo:checkReconnect")
        if reconnectData then
            isInsideLabo = reconnectData.id
            currentLaboData = reconnectData
            TriggerEvent("labo:refreshPoints", reconnectData.id)
            break
        end
    end
end)

CreateThread(function()
    while not VFW.IsPlayerLoaded() do
        Wait(500)
    end
    while true do
        Wait(2000)
        if not isInsideLabo then
            local data = TriggerServerCallback("labo:bucketCheck")
            if data then
                isInsideLabo = data.id
                currentLaboData = data
                TriggerEvent("labo:refreshPoints", data.id)
            end
        elseif currentLaboData and currentLaboData.interior_x then
            local interiorCoords = vector3(currentLaboData.interior_x, currentLaboData.interior_y, currentLaboData.interior_z)
            if #(GetEntityCoords(PlayerPedId()) - interiorCoords) > 100.0 then
                TriggerServerEvent("labo:exit")
            end
        end
    end
end)

RegisterNetEvent("laboBuilder:syncLabos", function()
    labos = TriggerServerCallback("labo:getLabos") or {}
    RefreshBlips()
    if isInsideLabo then
        local fresh = TriggerServerCallback("labo:getInteriorData", isInsideLabo)
        if fresh then
            currentLaboData = fresh
        end
    end
end)

RegisterNetEvent("labo:refreshBlips", function()
    labos = TriggerServerCallback("labo:getLabos") or {}
    RefreshBlips()
end)

RegisterNetEvent("vfw:setJob2", function()
    labos = TriggerServerCallback("labo:getLabos") or {}
    RefreshBlips()
end)

CreateThread(function()
    while not VFW.IsPlayerLoaded() do
        Wait(500)
    end
    while true do
        Wait(10000)
        labos = TriggerServerCallback("labo:getLabos") or {}
        RefreshBlips()
    end
end)

RegisterNetEvent("labo:enterInterior", function(data)
    isInsideLabo = data.id
    currentLaboData = data
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(ped, data.interior_x, data.interior_y, data.interior_z, false, false, false, false)
    SetEntityHeading(ped, data.interior_heading)
    Wait(200)
    DoScreenFadeIn(500)
    FreezeEntityPosition(ped, false)
end)

RegisterNetEvent("labo:exitInterior", function(data)
    HideFloating()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(ped, data.door_x, data.door_y, data.door_z, false, false, false, false)
    SetEntityHeading(ped, data.door_heading)
    Wait(200)
    DoScreenFadeIn(500)
    FreezeEntityPosition(ped, false)
    isInsideLabo = nil
    currentLaboData = nil
    lastExitTime = GetGameTimer()
    labos = TriggerServerCallback("labo:getLabos") or {}
    RefreshBlips()
end)

RegisterNetEvent("labo:notify", function(msg)
    VFW.ShowNotification({ type = "ROUGE", content = msg })
end)

RegisterNetEvent("labo:attackAlert", function(data)
    PlaySoundFrontend(-1, "CHARTER_COMPLETE", "BASE_JUMP_PASSED_SOUNDS", false)

    VFW.ShowNotification({
        type = "ROUGE",
        content = "Alerte ! Le " .. data.laboName .. " est attaqué par " .. data.attackerFaction .. " !"
    })

    Citizen.SetTimeout(1000, function()
        PlaySoundFrontend(-1, "CHARTER_COMPLETE", "BASE_JUMP_PASSED_SOUNDS", false)
    end)

    RemoveAttackGps()

    attackGpsBlip = AddBlipForCoord(data.door_x, data.door_y, data.door_z)
    attackGpsLaboId = data.laboId
    SetBlipSprite(attackGpsBlip, 487)
    SetBlipColour(attackGpsBlip, 1)
    SetBlipScale(attackGpsBlip, 0.5)
    SetBlipFlashes(attackGpsBlip, true)
    SetBlipRoute(attackGpsBlip, true)
    SetBlipRouteColour(attackGpsBlip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("LABO ATTAQUÉ - " .. data.laboName)
    EndTextCommandSetBlipName(attackGpsBlip)

    attackStates[data.laboId] = {
        progress = 0,
        paused = false,
        laboName = data.laboName,
        isDefender = true,
        attackerCount = 0,
        defenderCount = 0
    }
    ShowAttackBar(attackStates[data.laboId])
end)

RegisterNetEvent("labo:attackProgress", function(laboId, progress, paused, timeLeft, laboName, attackerCount, defenderCount, isDefender, attackerLabel, defenderLabel)
    local isNew = not attackStates[laboId]
    if isNew then
        attackStates[laboId] = {
            progress = 0,
            paused = false,
            laboName = laboName or "Labo",
            isDefender = isDefender or false,
            attackerCount = attackerCount or 0,
            defenderCount = defenderCount or 0,
            attackerLabel = attackerLabel or "Attaquants",
            defenderLabel = defenderLabel or "Defenseurs"
        }
    end
    attackStates[laboId].progress = progress
    attackStates[laboId].paused = paused
    attackStates[laboId].timeLeft = timeLeft
    attackStates[laboId].attackerCount = attackerCount or 0
    attackStates[laboId].defenderCount = defenderCount or 0
    attackStates[laboId].isDefender = isDefender or false
    attackStates[laboId].attackerLabel = attackerLabel or attackStates[laboId].attackerLabel or "Attaquants"
    attackStates[laboId].defenderLabel = defenderLabel or attackStates[laboId].defenderLabel or "Defenseurs"
    if laboName then
        attackStates[laboId].laboName = laboName
    end
    if isNew then
        ShowAttackBar(attackStates[laboId])
    else
        SendAttackBarNUI(attackStates[laboId])
    end
end)

RegisterNetEvent("labo:attackEnd", function(laboId)
    attackStates[laboId] = nil
    HideAttackBar()
    RemoveAttackGps(laboId)
end)

RegisterNetEvent("labo:attackResult", function(data)
    if data.success then
        VFW.ShowNotification({ type = "VERT", content = data.message })
    else
        VFW.ShowNotification({ type = "ROUGE", content = data.message })
    end
    labos = TriggerServerCallback("labo:getLabos") or {}
    RefreshBlips()
end)

CreateThread(function()
    while not VFW.IsPlayerLoaded() do
        Wait(500)
    end
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local myPos = GetEntityCoords(ped)

        if isInsideLabo and currentLaboData then
            local closestType = nil
            local closestDist = INTERACT_DIST + 1
            local closestPos = nil

            local exitPos = vector3(currentLaboData.interior_x, currentLaboData.interior_y, currentLaboData.interior_z)
            local exitDist = #(myPos - exitPos)
            if exitDist < closestDist then
                closestDist = exitDist
                closestType = "exit"
                closestPos = exitPos
            end

            if currentLaboData.chest_x and currentLaboData.chest_y and currentLaboData.chest_z then
                local chestPos = vector3(currentLaboData.chest_x, currentLaboData.chest_y, currentLaboData.chest_z)
                local chestDist = #(myPos - chestPos)
                if chestDist < closestDist then
                    closestDist = chestDist
                    closestType = "chest"
                    closestPos = chestPos
                end
            end

            if closestType and closestDist < INTERACT_DIST and not IsNuiFocused() then
                sleep = 0

                if closestType == "exit" then
                    HideFloating()
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ~y~sortir~w~ du laboratoire")
                    if VFW.Interact.JustPressed(0, 38) and GetGameTimer() - lastTpTime > TP_COOLDOWN then
                        lastTpTime = GetGameTimer()
                        TriggerServerEvent("labo:exit")
                    end
                elseif closestType == "chest" then
                    ShowFloating("labo_chest", closestPos, {
                        { label = "Ouvrir le coffre", key = "E" }
                    })
                    if VFW.Interact.JustPressed(0, 38) then
                        HideFloating()
                        local canOpen = TriggerServerCallback("labo:canOpenChest", isInsideLabo)
                        if canOpen then
                            local chestId = "labo:" .. isInsideLabo
                            VFW.OpenChest(chestId, "Coffre - " .. (currentLaboData.label or "Labo"), currentLaboData.chest_max_slots or 20)
                        else
                            VFW.ShowNotification({ type = "ROUGE", content = "Vous n'avez pas accès au coffre." })
                        end
                    end
                end
            else
                HideFloating()
            end

            if (currentLaboData.is_owner or currentLaboData.management_access) and currentLaboData.management_x and currentLaboData.management_y and currentLaboData.management_z then
                local mgmtPos = vector3(currentLaboData.management_x, currentLaboData.management_y, currentLaboData.management_z)
                local mgmtDist = #(myPos - mgmtPos)

                if mgmtDist < 10.0 then
                    sleep = 0
                    DrawMarker(25, mgmtPos.x, mgmtPos.y, mgmtPos.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, 0, 0, 255, 255, false, true, 2, false, nil, nil, false)
                    if mgmtDist < 2.5 and not IsNuiFocused() then
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir la ~b~gestion~w~ du labo")
                        if VFW.Interact.JustPressed(0, 38) then
                            TriggerEvent("labo:openManagement", isInsideLabo)
                        end
                    end
                end
            end
        else
            local closestLabo = nil
            local closestDist = 999.0

            for _, labo in pairs(labos) do
                local doorPos = vector3(labo.door_x, labo.door_y, labo.door_z)
                local dist = #(myPos - doorPos)
                if dist < closestDist then
                    closestDist = dist
                    closestLabo = labo
                end
            end

            if closestLabo and closestDist < INTERACT_DIST and GetGameTimer() - lastExitTime > 1000 then
                sleep = 0
                if closestLabo.has_access then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ~g~entrer~w~ dans le laboratoire")
                    if VFW.Interact.JustPressed(0, 38) and GetGameTimer() - lastTpTime > TP_COOLDOWN then
                        lastTpTime = GetGameTimer()
                        TriggerServerEvent("labo:enter", closestLabo.id)
                    end
                else
                    VFW.ShowHelpNotification("Vous ~r~n'avez pas accès~w~ à cet endroit")
                end
            elseif closestLabo and closestDist < 50.0 then
                sleep = 500
            end
        end

        Wait(sleep)
    end
end)

local lastMolotovEquipTime = 0

AddEventHandler("vfw:weaponChange", function()
    if isInsideLabo then return end
    Wait(100)
    local weapon = GetSelectedPedWeapon(PlayerPedId())
    if weapon ~= `WEAPON_MOLOTOV` then return end

    lastMolotovEquipTime = GetGameTimer()

    local myPos = GetEntityCoords(PlayerPedId())
    local nearestLabo = nil
    local nearestDist = 50.0
    for _, labo in pairs(labos) do
        local doorPos = vector3(labo.door_x, labo.door_y, labo.door_z)
        local dist = #(myPos - doorPos)
        if dist < nearestDist and not attackStates[labo.id] then
            nearestDist = dist
            nearestLabo = labo
        end
    end
    if not nearestLabo then return end

    local result = TriggerServerCallback("labo:preCheckAttack", nearestLabo.id)
    if result then
        if result.ok then
            VFW.ShowNotification({ type = "VERT", content = result.message })
        elseif result.message then
            VFW.ShowNotification({ type = "ROUGE", content = result.message })
        end
    end
end)

CreateThread(function()
    while not VFW.IsPlayerLoaded() do
        Wait(500)
    end
    while true do
        Wait(500)
        if not isInsideLabo then
            local weapon = GetSelectedPedWeapon(PlayerPedId())
            if weapon == `WEAPON_MOLOTOV` then
                lastMolotovEquipTime = GetGameTimer()
            end
        else
            Wait(2000)
        end
    end
end)

CreateThread(function()
    while not VFW.IsPlayerLoaded() do
        Wait(500)
    end
    local fireCooldown = {}
    while true do
        Wait(1000)
        if isInsideLabo then
            Wait(2000)
        else
            local ped = PlayerPedId()
            local myPos = GetEntityCoords(ped)

            for _, labo in pairs(labos) do
                local doorPos = vector3(labo.door_x, labo.door_y, labo.door_z)
                if #(myPos - doorPos) < 20.0 and not attackStates[labo.id] then
                    local hadMolotov = (GetGameTimer() - lastMolotovEquipTime) < 10000
                    local fires = GetNumberOfFiresInRange(doorPos.x, doorPos.y, doorPos.z, 3.5)
                    if fires > 0 and hadMolotov and (not fireCooldown[labo.id] or GetGameTimer() - fireCooldown[labo.id] > 10000) then
                        fireCooldown[labo.id] = GetGameTimer()
                        local result = TriggerServerCallback("labo:startAttack", labo.id)
                        if result and result.success then
                            VFW.ShowNotification({ type = "VERT", content = "Attaque lancée !" })
                            attackStates[labo.id] = {
                                progress = 0,
                                paused = false,
                                laboName = labo.label or labo.name,
                                isDefender = false,
                                attackerCount = 0,
                                defenderCount = 0
                            }
                            ShowAttackBar(attackStates[labo.id])
                        elseif result and result.message then
                            VFW.ShowNotification({ type = "ROUGE", content = result.message })
                        end
                    end
                end
            end
        end
    end
end)
