weaponOnBackName = nil
weaponOnBackProp = nil
weaponOnBackMeta = nil
weaponOnBackUniqueId = nil

local KVP_WEAPON_NAME = "vfw:weapon_on_back:name"
local KVP_WEAPON_UNIQUEID = "vfw:weapon_on_back:unique_id"

local function IsBigWeapon(weaponName)
    if not weaponName then return false end
    local allowed = GlobalState.WeaponBackAllowed
    if not allowed then return false end
    return allowed[weaponName:upper()] == true
end

local function HasBagEquipped()
    return VFW.HasEquippedBag and VFW.HasEquippedBag()
end

local function FindWeaponMetaInInventory(weaponName)
    if not VFW.PlayerData or not VFW.PlayerData.inventory then return nil end
    for _, item in pairs(VFW.PlayerData.inventory) do
        if item.name == weaponName then
            return item.meta or {}
        end
    end
    return nil
end

local function CreateWeaponBackProp(weaponName, weaponMeta)
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)

    if weaponOnBackProp and DoesEntityExist(weaponOnBackProp) then
        DeleteEntity(weaponOnBackProp)
        weaponOnBackProp = nil
    end

    RequestWeaponAsset(weaponHash, 31, 0)
    local timeout = 0
    while not HasWeaponAssetLoaded(weaponHash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasWeaponAssetLoaded(weaponHash) then
        return false
    end

    local coords = GetEntityCoords(ped)
    weaponOnBackProp = CreateWeaponObject(weaponHash, 0, coords.x, coords.y, coords.z, true, 1.0, 0, false, true)

    if not weaponOnBackProp or not DoesEntityExist(weaponOnBackProp) then
        return false
    end

    if weaponMeta and weaponMeta.tintIdx then
        SetWeaponObjectTintIndex(weaponOnBackProp, weaponMeta.tintIdx)
    end

    if weaponMeta and weaponMeta.components then
        for _, componentHash in ipairs(weaponMeta.components) do
            local componentModel = GetWeaponComponentTypeModel(componentHash)
            if componentModel ~= 0 then
                RequestModel(componentModel)
                local compTimeout = 0
                while not HasModelLoaded(componentModel) and compTimeout < 50 do
                    Wait(10)
                    compTimeout = compTimeout + 1
                end
                if HasModelLoaded(componentModel) then
                    GiveWeaponComponentToWeaponObject(weaponOnBackProp, componentHash)
                    SetModelAsNoLongerNeeded(componentModel)
                end
            end
        end
    end

    local attachment = Config.WeaponBack.attachment
    AttachEntityToEntity(
        weaponOnBackProp,
        ped,
        GetPedBoneIndex(ped, attachment.bone),
        attachment.offset.x, attachment.offset.y, attachment.offset.z,
        attachment.rotation.x, attachment.rotation.y, attachment.rotation.z,
        true, true, false, true, 0, true
    )

    weaponOnBackName = weaponName
    weaponOnBackMeta = weaponMeta

    SetResourceKvp(KVP_WEAPON_NAME, weaponName)
    if weaponMeta and weaponMeta.weaponId then
        weaponOnBackUniqueId = weaponMeta.weaponId
        SetResourceKvp(KVP_WEAPON_UNIQUEID, weaponMeta.weaponId)
    end

    SendNUIMessage({
        action = "nui:inventory:weaponOnBack",
        data = { weaponName = weaponName }
    })

    return true
end

local function DeletePropOnly()
    if weaponOnBackProp and DoesEntityExist(weaponOnBackProp) then
        DeleteEntity(weaponOnBackProp)
    end
    weaponOnBackProp = nil
end

function RemoveWeaponProp()
    DeletePropOnly()

    weaponOnBackName = nil
    weaponOnBackMeta = nil
    weaponOnBackUniqueId = nil

    DeleteResourceKvp(KVP_WEAPON_NAME)
    DeleteResourceKvp(KVP_WEAPON_UNIQUEID)

    SendNUIMessage({
        action = "nui:inventory:weaponOnBack",
        data = { weaponName = nil }
    })

    TriggerServerEvent("vfw:weapon:syncRemoveBackWeapon")
end

function PlayBackToHandAnim()
    local ped = PlayerPedId()
    VFW.Streaming.RequestAnimDict("reaction@intimidation@1h")
    TaskPlayAnim(ped, "reaction@intimidation@1h", "intro", 5.0, 1.0, -1, 50, 0, 0, 0, 0)
    Wait(800)
    ClearPedTasks(ped)
    RemoveAnimDict("reaction@intimidation@1h")
end

local function PlayHandToBackAnim()
    local ped = PlayerPedId()
    VFW.Streaming.RequestAnimDict("reaction@intimidation@1h")
    TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", 8.0, 3.0, -1, 50, 0, 0, 0.125, 0)
    Wait(1200)
    ClearPedTasks(ped)
    RemoveAnimDict("reaction@intimidation@1h")
end

local function AutoPutOnBack(weaponName, weaponMeta, skipAnim)
    if HasBagEquipped() then return end

    if weaponOnBackProp and DoesEntityExist(weaponOnBackProp) then
        DeleteEntity(weaponOnBackProp)
        weaponOnBackProp = nil
    end

    if not skipAnim then
        PlayHandToBackAnim()
    end

    local success = CreateWeaponBackProp(weaponName, weaponMeta or {})
    if success then
        TriggerServerEvent("vfw:weapon:syncBackWeapon", weaponName, weaponMeta or {})
    end
end

RegisterNetEvent("vfw:weapon:back", function(weaponName, weaponMeta)
    if not IsBigWeapon(weaponName) then return end
    AutoPutOnBack(weaponName, weaponMeta)
end)

RegisterNetEvent("vfw:weapon:removeFromBack", function()
    RemoveWeaponProp()
end)

local lastWeapon = nil
local autoBackCooldown = false
local backWeaponSyncHidden = false

-- External suppression flag (noclip, staff invisibility, etc.). When true,
-- the periodic loop will NOT recreate the back-weapon prop locally and will
-- broadcast a remove to other clients so they delete the attached prop too.
local backWeaponForceSuppressed = false

function VFW.SetBackWeaponSuppressed(suppressed)
    backWeaponForceSuppressed = suppressed == true
end

CreateThread(function()
    while true do
        Wait(500)

        local ped = PlayerPedId()
        if IsEntityDead(ped) then
            if weaponOnBackProp and DoesEntityExist(weaponOnBackProp) then
                DeletePropOnly()
            end
            lastWeapon = nil
            Wait(2000)
            goto continue
        end

        local currentWeapon = GetSelectedPedWeapon(ped)
        local currentWeaponName = nil

        if currentWeapon ~= `WEAPON_UNARMED` then
            if VFW.PlayerData and VFW.PlayerData.inventory then
                for _, item in pairs(VFW.PlayerData.inventory) do
                    if GetHashKey(item.name) == currentWeapon then
                        currentWeaponName = item.name
                        break
                    end
                end
            end
        end

        if lastWeapon and lastWeapon ~= currentWeaponName then
            if IsBigWeapon(lastWeapon) and not autoBackCooldown then
                autoBackCooldown = true
                local meta = FindWeaponMetaInInventory(lastWeapon)
                local weaponToStore = lastWeapon

                if weaponOnBackName and weaponOnBackName ~= weaponToStore then
                    RemoveWeaponProp()
                end

                CreateThread(function()
                    AutoPutOnBack(weaponToStore, meta, true)
                    Wait(1000)
                    autoBackCooldown = false
                end)
            end
        end

        if currentWeaponName and weaponOnBackName and GetHashKey(weaponOnBackName) == currentWeapon then
            DeletePropOnly()
            if not backWeaponSyncHidden then
                backWeaponSyncHidden = true
                TriggerServerEvent("vfw:weapon:syncRemoveBackWeapon")
            end
        elseif weaponOnBackName and (not currentWeaponName or GetHashKey(weaponOnBackName) ~= currentWeapon) then
            if not HasBagEquipped() and not backWeaponForceSuppressed then
                backWeaponSyncHidden = false
                if not weaponOnBackProp or not DoesEntityExist(weaponOnBackProp) then
                    local success = CreateWeaponBackProp(weaponOnBackName, weaponOnBackMeta)
                    if success then
                        TriggerServerEvent("vfw:weapon:syncBackWeapon", weaponOnBackName, weaponOnBackMeta or {})
                    end
                end
            else
                DeletePropOnly()
                if not backWeaponSyncHidden then
                    backWeaponSyncHidden = true
                    TriggerServerEvent("vfw:weapon:syncRemoveBackWeapon")
                end
            end
        end

        if weaponOnBackName and VFW.PlayerData and VFW.PlayerData.inventory then
            local found = false
            for _, item in pairs(VFW.PlayerData.inventory) do
                if item.name == weaponOnBackName then
                    found = true
                    break
                end
            end
            if not found then
                RemoveWeaponProp()
            end
        end

        lastWeapon = currentWeaponName

        ::continue::
    end
end)

local function FindFirstBigWeaponInInventory()
    if not VFW.PlayerData or not VFW.PlayerData.inventory then return nil, nil end
    for _, item in pairs(VFW.PlayerData.inventory) do
        if IsBigWeapon(item.name) then
            return item.name, item.meta or {}
        end
    end
    return nil, nil
end

local previousBigWeapons = {}

local function BuildBigWeaponSet(inventory)
    local set = {}
    if not inventory then return set end
    for _, item in pairs(inventory) do
        if IsBigWeapon(item.name) then
            set[item.name] = true
        end
    end
    return set
end

local function InitPreviousBigWeapons()
    if VFW.PlayerData and VFW.PlayerData.inventory then
        previousBigWeapons = BuildBigWeaponSet(VFW.PlayerData.inventory)
    end
end

local function LoadWeaponOnBackAtSpawn()
    local timeout = 0
    while (not VFW.PlayerData or not VFW.PlayerData.inventory or #VFW.PlayerData.inventory == 0) and timeout < 60 do
        Wait(500)
        timeout = timeout + 1
    end

    Wait(1000)

    if HasBagEquipped() then return end

    local savedName = GetResourceKvpString(KVP_WEAPON_NAME)
    local savedUniqueId = GetResourceKvpString(KVP_WEAPON_UNIQUEID)

    if savedName and savedName ~= "" then
        if VFW.PlayerData and VFW.PlayerData.inventory then
            for _, item in pairs(VFW.PlayerData.inventory) do
                if item.name == savedName then
                    if savedUniqueId == "" or (item.meta and item.meta.weaponId == savedUniqueId) then
                        CreateWeaponBackProp(savedName, item.meta or {})
                        TriggerServerEvent("vfw:weapon:syncBackWeapon", savedName, item.meta or {})
                        return
                    end
                end
            end
        end

        DeleteResourceKvp(KVP_WEAPON_NAME)
        DeleteResourceKvp(KVP_WEAPON_UNIQUEID)
    end

    local weaponName, weaponMeta = FindFirstBigWeaponInInventory()
    if weaponName then
        CreateWeaponBackProp(weaponName, weaponMeta)
        TriggerServerEvent("vfw:weapon:syncBackWeapon", weaponName, weaponMeta)
    end
end

RegisterNetEvent("vfw:playerReady", function()
    LoadWeaponOnBackAtSpawn()
    Wait(2000)
    InitPreviousBigWeapons()
end)

local otherPlayersWeaponProps = {}
local otherPlayersWeaponData = {}

local function CreateOtherPlayerWeaponProp(playerId, weaponName, weaponMeta)
    local playerIndex = GetPlayerFromServerId(playerId)
    if playerIndex == -1 then return end

    local targetPed = GetPlayerPed(playerIndex)
    if not DoesEntityExist(targetPed) then return end
    if targetPed == PlayerPedId() then return end

    if otherPlayersWeaponProps[playerId] and DoesEntityExist(otherPlayersWeaponProps[playerId]) then
        DeleteEntity(otherPlayersWeaponProps[playerId])
        otherPlayersWeaponProps[playerId] = nil
    end

    local weaponHash = GetHashKey(weaponName)

    RequestWeaponAsset(weaponHash, 31, 0)
    local timeout = 0
    while not HasWeaponAssetLoaded(weaponHash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasWeaponAssetLoaded(weaponHash) then return end

    local coords = GetEntityCoords(targetPed)
    local prop = CreateWeaponObject(weaponHash, 0, coords.x, coords.y, coords.z, true, 1.0, 0, false, true)

    if not prop or not DoesEntityExist(prop) then return end

    if weaponMeta and weaponMeta.tintIdx then
        SetWeaponObjectTintIndex(prop, weaponMeta.tintIdx)
    end

    local attachment = Config.WeaponBack.attachment
    AttachEntityToEntity(
        prop,
        targetPed,
        GetPedBoneIndex(targetPed, attachment.bone),
        attachment.offset.x, attachment.offset.y, attachment.offset.z,
        attachment.rotation.x, attachment.rotation.y, attachment.rotation.z,
        true, true, false, true, 0, true
    )

    otherPlayersWeaponProps[playerId] = prop
end

RegisterNetEvent("vfw:weapon:otherPlayerBackWeapon", function(playerId, weaponName, weaponMeta)
    if playerId == GetPlayerServerId(PlayerId()) then return end
    otherPlayersWeaponData[playerId] = { weaponName = weaponName, weaponMeta = weaponMeta }
    CreateOtherPlayerWeaponProp(playerId, weaponName, weaponMeta)
end)

RegisterNetEvent("vfw:weapon:otherPlayerRemoveBackWeapon", function(playerId)
    otherPlayersWeaponData[playerId] = nil
    if otherPlayersWeaponProps[playerId] and DoesEntityExist(otherPlayersWeaponProps[playerId]) then
        DeleteEntity(otherPlayersWeaponProps[playerId])
        otherPlayersWeaponProps[playerId] = nil
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        for playerId, data in pairs(otherPlayersWeaponData) do
            local prop = otherPlayersWeaponProps[playerId]
            if not prop or not DoesEntityExist(prop) then
                local playerIndex = GetPlayerFromServerId(playerId)
                if playerIndex ~= -1 then
                    local targetPed = GetPlayerPed(playerIndex)
                    if DoesEntityExist(targetPed) and targetPed ~= PlayerPedId() then
                        local currentWeapon = GetSelectedPedWeapon(targetPed)
                        if currentWeapon == `WEAPON_UNARMED` or GetHashKey(data.weaponName) ~= currentWeapon then
                            CreateOtherPlayerWeaponProp(playerId, data.weaponName, data.weaponMeta)
                        end
                    end
                end
            end
        end
    end
end)

AddEventHandler("playerSpawned", function()
    Wait(5000)
    TriggerServerEvent("vfw:weapon:requestBackWeapons")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if weaponOnBackProp and DoesEntityExist(weaponOnBackProp) then
            DeleteEntity(weaponOnBackProp)
        end
        for _, prop in pairs(otherPlayersWeaponProps) do
            if DoesEntityExist(prop) then
                DeleteEntity(prop)
            end
        end
        otherPlayersWeaponProps = {}
        otherPlayersWeaponData = {}
    end
end)

RegisterNetEvent("vfw:updateInventory", function(inventory)
    if HasBagEquipped() then
        previousBigWeapons = BuildBigWeaponSet(inventory)
        return
    end

    local newSet = BuildBigWeaponSet(inventory)
    local ped = PlayerPedId()
    local currentWeaponHash = GetSelectedPedWeapon(ped)

    for weaponName, _ in pairs(newSet) do
        if not previousBigWeapons[weaponName] then
            local weaponHash = GetHashKey(weaponName)
            if currentWeaponHash ~= weaponHash and not weaponOnBackName then
                local meta = nil
                for _, item in pairs(inventory) do
                    if item.name == weaponName then
                        meta = item.meta or {}
                        break
                    end
                end
                CreateThread(function()
                    AutoPutOnBack(weaponName, meta, true)
                end)
                break
            end
        end
    end

    previousBigWeapons = newSet
end)

exports("GetWeaponOnBack", function()
    return weaponOnBackName, weaponOnBackMeta
end)

exports("IsWeaponOnBack", function(weaponName)
    return weaponOnBackName == weaponName
end)

exports("IsBigWeapon", IsBigWeapon)

exports("RemoveWeaponProp", RemoveWeaponProp)
