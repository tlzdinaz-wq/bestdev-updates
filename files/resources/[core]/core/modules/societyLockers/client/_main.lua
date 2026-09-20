--- @class SocietyLocker
local SocietyLocker = {}
SocietyLocker.__index = SocietyLocker

SocietyLocker.list = {}
SocietyLocker.hasInitialized = false

local currentLocker = nil
local isLockerOpen = false
local isManageUIOpen = false
local lastInteraction = 0
local lockerFloatingShown = false
local lockerFloatingId = nil

RegisterNetEvent("vfw:setJob", function(job)
    VFW.PlayerData.job = job
end)

-- Fonction utilitaire pour créer le blip
function SocietyLocker.createBlip(data)
    local blip = AddBlipForCoord(data.position.x, data.position.y, data.position.z)
    SetBlipSprite(blip, 478) -- Icône casier/stockage
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, 3) -- Bleu
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")

    local jobLabel = (VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label) or "Inconnu"
    AddTextComponentString(jobLabel .. " • Casier")
    EndTextCommandSetBlipName(blip)

    return blip
end

RegisterNetEvent("core:societyLockers:retrieve", function(lockers)
    SocietyLocker.removeAll()
    SocietyLocker.list = lockers or {}

    -- Création des blips pour chaque casier reçu
    for k, v in pairs(SocietyLocker.list) do
        v.blip = SocietyLocker.createBlip(v)
    end

    SocietyLocker.init()
end)

RegisterNetEvent("core:societyLockers:remove", function(id)
    SocietyLocker.remove(id)
end)

RegisterNetEvent("core:societyLockers:update", function(data)
    SocietyLocker.remove(data.id)

    data.blip = SocietyLocker.createBlip(data)
    SocietyLocker.list[data.id] = data
end)

RegisterNetEvent("core:societyLockers:create", function(data)
    SocietyLocker.remove(data.id)
    data.blip = SocietyLocker.createBlip(data)
    SocietyLocker.list[data.id] = data
end)

local function ShowLockerFloating(id, worldPos, floatingZ)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + (floatingZ or 0.5))
    if not onScreen then
        if lockerFloatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            lockerFloatingShown = false
            lockerFloatingId = nil
        end
        return
    end

    local data = {
        id = "society_locker_" .. tostring(id),
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = {
            { label = "Ouvrir le casier", key = "E" }
        }
    }

    if lockerFloatingShown and lockerFloatingId == id then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        lockerFloatingShown = true
        lockerFloatingId = id
    end
end

local function HideLockerFloating()
    if lockerFloatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        lockerFloatingShown = false
        lockerFloatingId = nil
    end
end

function SocietyLocker.init()
    if SocietyLocker.hasInitialized then
        return
    end
    SocietyLocker.hasInitialized = true

    CreateThread(function()
        local interval

        while true do
            interval = 500
            local found = false

            if isLockerOpen then
                HideLockerFloating()
            else
                local coords = GetEntityCoords(PlayerPedId())

                for id, data in pairs(SocietyLocker.list) do
                    if not VFW.PlayerData or not VFW.PlayerData.job then
                        goto continue
                    end

                    if VFW.PlayerData.job.name ~= data.job then
                        goto continue
                    end

                    if data.gradeMin and data.gradeMin > 0 then
                        if not VFW.PlayerData.job.grade or VFW.PlayerData.job.grade < data.gradeMin then
                            goto continue
                        end
                    end

                    if not data._posVec then
                        data._posVec = vector3(data.position.x, data.position.y, data.position.z)
                    end

                    local dist = #(coords - data._posVec)

                    if dist <= 3.0 then
                        found = true
                        interval = 0
                        ShowLockerFloating(id, data._posVec, data.floatingZ)

                        local currentTime = GetGameTimer()
                        if VFW.Interact.JustPressed(0, 38) and (currentTime - lastInteraction) > 1000 then
                            lastInteraction = currentTime
                            currentLocker = id
                            isLockerOpen = true
                            HideLockerFloating()
                            TriggerServerEvent("core:societyLockers:open", id)
                        end
                        break
                    end

                    ::continue::
                end

                if not found then
                    HideLockerFloating()
                end
            end

            Wait(interval)
        end
    end)
end

function SocietyLocker.remove(id)
    if SocietyLocker.list[id] then
        -- Suppression du blip si il existe
        if DoesBlipExist(SocietyLocker.list[id].blip) then
            RemoveBlip(SocietyLocker.list[id].blip)
        end

        SocietyLocker.list[id] = nil
    end
end

function SocietyLocker.removeAll()
    for id, _ in pairs(SocietyLocker.list) do
        SocietyLocker.remove(id)
    end
end

-- Event pour ouvrir l'interface d'inventaire (casier personnel)
RegisterNetEvent("core:societyLockers:openInventory", function(chestId, label, maxSlots)
    if not chestId then return end

    isLockerOpen = true
    -- Utiliser le système de coffre existant
    VFW.OpenChest(chestId, label, maxSlots)
end)

-- Event pour ouvrir le menu de gestion (pour les managers) - UI React
RegisterNetEvent("core:societyLockers:openManageMenu", function(lockerId, lockerLabel, employeeLockers)
    isLockerOpen = true
    isManageUIOpen = true
    SendNUIMessage({ action = "nui:logo:visible", data = false })
    VFW.Nui.Focus(true)
    SendNUIMessage({
        action = "nui:societyLockers:visible",
        data = {
            visible = true,
            lockerId = lockerId,
            lockerLabel = lockerLabel,
            employeeLockers = employeeLockers or {}
        }
    })

    -- Bloquer les contrôles pendant que l'UI est ouverte
    CreateThread(function()
        while isManageUIOpen do
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            Wait(0)
        end
    end)
end)

-- Callback NUI pour ouvrir son propre casier
RegisterNUICallback("societyLockers:openOwn", function(data, cb)
    -- Fermer l'UI React
    isManageUIOpen = false
    VFW.Nui.Focus(false)
    SendNUIMessage({
        action = "nui:societyLockers:visible",
        data = { visible = false }
    })
    -- Ouvrir le casier après un petit délai
    SetTimeout(100, function()
        TriggerServerEvent("core:societyLockers:openOwnLocker", data.lockerId)
    end)
    cb("ok")
end)

-- Callback NUI pour ouvrir le casier d'un employé
RegisterNUICallback("societyLockers:openEmployee", function(data, cb)
    -- Fermer l'UI React
    isManageUIOpen = false
    VFW.Nui.Focus(false)
    SendNUIMessage({
        action = "nui:societyLockers:visible",
        data = { visible = false }
    })
    -- Ouvrir le casier après un petit délai
    SetTimeout(100, function()
        TriggerServerEvent("core:societyLockers:openEmployeeLocker", data.lockerId, data.chestId)
    end)
    cb("ok")
end)

-- Callback NUI pour fermer l'interface
RegisterNUICallback("societyLockers:close", function(data, cb)
    isManageUIOpen = false
    VFW.Nui.Focus(false)
    SendNUIMessage({ action = "nui:logo:visible", data = true })
    isLockerOpen = false
    currentLocker = nil
    cb("ok")
end)

-- Surveiller la fermeture de l'inventaire
CreateThread(function()
    while true do
        Wait(500)

        if isLockerOpen then
            -- Vérifier si l'inventaire est fermé
            local inventoryOpen = VFW.StateInventory and VFW.StateInventory()

            if not inventoryOpen and not IsNuiFocused() then
                isLockerOpen = false
                currentLocker = nil
            end
        end
    end
end)
