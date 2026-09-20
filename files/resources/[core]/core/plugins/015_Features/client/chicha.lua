---@meta _
---@diagnostic disable: duplicate-doc-field

local ChichaPos = vector3(-1177.9136962891, -179.33055114746, 74.766883850098)
local ChichaPosCayo = vector3(4903.5463867188, -4945.076171875, 2.3947477340698)
local ChichaModel = 4037417364
local TableChicha = {
    {
        model = -516909923, -- Table Cayo
        offset = vector3(0.0, 0.0, 0.5)
    }
}
local MyChicha
local TubeObj

--- ChichaAnimCarry
local function ChichaAnimCarry()
    local ped = PlayerPedId()
    local ad = "anim@heists@humane_labs@finale@keycards"
    local anim = "ped_a_enter_loop"

    while (not HasAnimDictLoaded(ad)) do
        RequestAnimDict(ad)
        Wait(1)
    end

    TaskPlayAnim(ped, ad, anim, 8.00, -8.00, -1, (2 + 16 + 32), 0.00, 0, 0, 0)
end

RegisterNetEvent("core:usechciha", function()
    local playerPed = PlayerPedId()
    if not MyChicha then
        RequestModel(ChichaModel)
        while not HasModelLoaded(ChichaModel) do Wait(1) end

        local obj = cEntity.Manager:CreateObject(ChichaModel, GetEntityCoords(playerPed)).id

        SetEntityAsMissionEntity(obj, true, true)

        NetworkRegisterEntityAsNetworked(obj)

        if NetworkGetEntityIsNetworked(obj) then
            SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(obj), true)
            SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(obj), true)
        end

        FreezeEntityPosition(obj, true)

        MyChicha = obj

        AttachEntityToEntity(obj, playerPed, GetPedBoneIndex(playerPed, 24818), -0.15, 0.2, 0.18, 0.0, 90.0, 0.0, true, true, false, true, 1, true)

        ChichaAnimCarry()

        Wait(100)
    else
        ClearPedTasks(playerPed)

        DeleteEntity(MyChicha)

        MyChicha = nil
    end
end)

--- TakeChichaFromTable
---@param closestChicha any
local function TakeChichaFromTable(closestChicha)
    local playerPed = PlayerPedId()
    NetworkRequestControlOfEntity(closestChicha)

    while not NetworkHasControlOfEntity(closestChicha) do Wait(1) end

    DeleteEntity(closestChicha)

    RequestModel(ChichaModel)
    while not HasModelLoaded(ChichaModel) do Wait(1) end

    local obj = cEntity.Manager:CreateObject(ChichaModel, GetEntityCoords(playerPed)).id

    SetEntityAsMissionEntity(obj, true, true)

    NetworkRegisterEntityAsNetworked(obj)

    if NetworkGetEntityIsNetworked(obj) then
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(obj), true)
        SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(obj), true)
    end

    FreezeEntityPosition(obj, true)

    local boneIndex2 = GetPedBoneIndex(playerPed, 24818)

    MyChicha = obj

    ChichaAnimCarry()

    AttachEntityToEntity(obj, playerPed, boneIndex2, -0.15, 0.2, 0.18, 0.0, 90.0, 0.0, true, true, false, true, 1, true)

    if TubeObj then
        DeleteEntity(TubeObj)
        TubeObj = nil
    end
end

--- PoseLaChichaTable
---@param coord any
local function PoseLaChichaTable(coord)
    DetachEntity(MyChicha, true)

    DeleteEntity(MyChicha)

    MyChicha = nil

    local obj = cEntity.Manager:CreateObject(ChichaModel, coord).id

    SetEntityAsMissionEntity(obj, true, true)

    NetworkRegisterEntityAsNetworked(obj)

    if NetworkGetEntityIsNetworked(obj) then
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(obj), true)
        SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(obj), true)
    end

    FreezeEntityPosition(obj, true)

    ClearPedTasks(PlayerPedId())
end

CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(100) end

    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distMain = #(playerCoords - ChichaPos)
        local distCayo = #(playerCoords - ChichaPosCayo)

        if distMain > 75.5 and distCayo > 30.5 then
            Wait(2000)
            goto continue
        end

        Wait(0)

        if VFW.PlayerData.job and VFW.PlayerData.job.name == "skyblue" then
            if distMain < 2.5 or distCayo < 2.5 then
                    if not MyChicha then
                        VFW.ShowHelpNotification("~INPUT_PICKUP~ Prendre une chicha")
                    else
                        VFW.ShowHelpNotification("~INPUT_PICKUP~ Ranger la chicha")
                    end

                    if VFW.Interact.JustPressed(0, 38) then
                        if not MyChicha then
                            RequestModel(ChichaModel)
                            while not HasModelLoaded(ChichaModel) do Wait(1) end

                            local obj = cEntity.Manager:CreateObject(ChichaModel, GetEntityCoords(playerPed)).id

                            SetEntityAsMissionEntity(obj, true, true)

                            NetworkRegisterEntityAsNetworked(obj)

                            if NetworkGetEntityIsNetworked(obj) then
                                SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(obj), true)
                                SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(obj), true)
                            end

                            FreezeEntityPosition(obj, true)

                            MyChicha = obj

                            AttachEntityToEntity(obj, playerPed, GetPedBoneIndex(playerPed, 24818), -0.15, 0.2, 0.18, 0.0, 90.0, 0.0, true, true, false, true, 1, true)

                            ChichaAnimCarry()

                            Wait(100)
                        else
                            ClearPedTasks(playerPed)

                            DeleteEntity(MyChicha)

                            MyChicha = nil

                            Wait(100)
                        end
                    end
                end
            end

            if MyChicha then
                for tableIndex, tableData in pairs(Masalar) do
                    local dist = #(GetEntityCoords(playerPed) - tableData.coords)

                    if dist < 2.0 then
                        VFW.ShowHelpNotification("~INPUT_PICKUP~ Mettre la chicha sur la table")

                        if VFW.Interact.JustPressed(0, 38) then
                            PoseLaChichaTable(tableData.coords)
                            Wait(300)
                        end
                    end
                end

                for tableIndex, tableConfig in pairs(TableChicha) do
                    local TableOjb = GetClosestObjectOfType(GetEntityCoords(playerPed), 2.0, tableConfig.model, true)
                    local coordsTable = GetEntityCoords(TableOjb) + tableConfig.offset

                    if TableOjb ~= 0 then
                        VFW.ShowHelpNotification("~INPUT_PICKUP~ Mettre la chicha sur la table")

                        if VFW.Interact.JustPressed(0, 38) then
                            PoseLaChichaTable(coordsTable)
                            Wait(300)
                        end
                    end
                end
            end

            local closestChicha = GetClosestObjectOfType(GetEntityCoords(playerPed), 1.9, ChichaModel, true)

            if closestChicha ~= 0 then
                if not IsEntityAttached(closestChicha) then
                    if VFW.PlayerData.job and VFW.PlayerData.job.name == "skyblue" then
                        VFW.ShowHelpNotification("~INPUT_PICKUP~ Prendre la chicha\n~INPUT_ENTER~ Fumer")

                        if VFW.Interact.JustReleased(0, 38) then
                            TakeChichaFromTable(closestChicha)
                        end
                    else
                        VFW.ShowHelpNotification("~INPUT_ENTER~ Fumer")
                    end

                    if IsControlJustReleased(0, 23) then
                        ChichaAnimCarry()

                        local playerPed  = playerPed
                        local coords     = GetEntityCoords(playerPed)
                        local boneIndex  = GetPedBoneIndex(playerPed, 12844)
                        local boneIndex2 = GetPedBoneIndex(playerPed, 24818)
                        local model      = joaat('v_corp_lngestoolfd')

                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(100)
                        end

                        TubeObj = cEntity.Manager:CreateObject(model, vector3(coords.x+0.5, coords.y+0.1, coords.z+0.4)).id

                        SetEntityAsMissionEntity(TubeObj, true, true)

                        AttachEntityToEntity(TubeObj, playerPed, boneIndex2, -0.43, 0.68, 0.18, 0.0, 90.0, 90.0, true, true, false, true, 1, true)

                        Wait(700)

                        local x,y,z = table.unpack(GetEntityCoords(playerPed))

                        TriggerServerEvent("hookah_smokes", PedToNet(playerPed), x,y,z)

                        Wait(2000)

                        if TubeObj then
                            local ad = "anim@heists@humane_labs@finale@keycards"
                            local anim = "ped_a_enter_loop"

                            StopAnimTask(playerPed, ad, anim, 1.0)

                            DeleteEntity(TubeObj)

                            TubeObj = nil
                        end
                    end
                end
            end

        ::continue::
    end
end)

--- showLoopParticle
---@param dict any
---@param particleName string
---@param coords vector3|table Coordinates
---@param scale any
---@param time any
local function showLoopParticle(dict, particleName, coords, scale, time)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(0)
    end

    UseParticleFxAssetNextCall(dict)

    local particleHandle = StartParticleFxLoopedAtCoord(particleName, coords, 0.0, 0.0, 0.0, scale, false, false, false)

    SetParticleFxLoopedColour(particleHandle, 0, 255, 0 ,0)

    Wait(time)

    StopParticleFxLooped(particleHandle, false)

    return particleHandle
end

---@param c_ped any
---@param x any
---@param y any
---@param z any
RegisterNetEvent("c_hookah_smokes", function(c_ped, x,y,z)
    local p_smoke_location = { 20279 }
    local p_smoke_particle_asset = "scr_agencyheistb"
    local p_smoke_particle = "scr_agency3b_elec_box"

    for boneIndex, boneId in pairs(p_smoke_location) do
        if DoesEntityExist(NetToPed(c_ped)) and not IsEntityDead(NetToPed(c_ped)) then
            showLoopParticle(p_smoke_particle_asset, p_smoke_particle, vector3(x,y,z+0.9), 3.5, 5000)

            Wait(5000)

            StopParticleFxLooped(createdSmoke, 1)

            RemoveParticleFxFromEntity(NetToPed(c_ped))

            break
        end
    end
end)
