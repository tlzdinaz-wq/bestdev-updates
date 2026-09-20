local doorbellThread  = nil
local doorbellCooldown = false
local floatingShown   = false
local currentFloatingDbId = nil
local globalDoorbells = {}

local function ShowDoorbellFloating(db, screenX, screenY)
    local data = {
        id = "doorbell_" .. tostring(db.id),
        title = "",
        subtitle = doorbellCooldown and "Veuillez patienter" or nil,
        screenX = screenX,
        screenY = screenY,
        size = "small",
        buttons = doorbellCooldown and {} or {
            { label = "Sonnette", key = "E", icon = "bell" }
        }
    }

    if floatingShown and currentFloatingDbId == db.id then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        floatingShown = true
        currentFloatingDbId = db.id
    end
end

local function HideDoorbellFloating()
    if floatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        floatingShown = false
        currentFloatingDbId = nil
    end
end

local function StartDoorbellThread()
    if doorbellThread then return end

    doorbellThread = CreateThread(function()
        while true do
            if #globalDoorbells == 0 then
                Wait(5000)
                goto continue
            end

            local playerCoords = GetEntityCoords(PlayerPedId())
            local nearestDist = math.huge
            local nearestDb   = nil

            for _, db in ipairs(globalDoorbells) do
                local dist = #(playerCoords - vector3(db.x, db.y, db.z))
                if dist < nearestDist then
                    nearestDist = dist
                    nearestDb   = db
                end
            end

            if nearestDist < 3.0 then
                local onScreen, screenX, screenY = World3dToScreen2d(nearestDb.x, nearestDb.y, nearestDb.z + 0.3)

                if onScreen then
                    ShowDoorbellFloating(nearestDb, screenX, screenY)
                else
                    HideDoorbellFloating()
                end

                if nearestDist < 1.5 and not doorbellCooldown and VFW.Interact.JustPressed(0, 38) then
                    doorbellCooldown = true
                    TriggerServerEvent("society:doorbell:ring", nearestDb.jobName, nearestDb.id)
                    SetTimeout(30000, function() doorbellCooldown = false end)
                end

                Wait(0)
            else
                HideDoorbellFloating()
                Wait(500)
            end

            ::continue::
        end
    end)
end

local function LoadGlobalDoorbells()
    globalDoorbells = TriggerServerCallback("society:doorbell:getAll") or {}
    StartDoorbellThread()
end

-- Load doorbells when player is ready
CreateThread(function()
    while not VFW?.PlayerData?.ped do
        Wait(500)
    end
    LoadGlobalDoorbells()
end)

-- Refresh when staff adds/updates/deletes a doorbell
RegisterNetEvent("society:doorbell:refresh", function()
    globalDoorbells = TriggerServerCallback("society:doorbell:getAll") or {}
end)

RegisterNetEvent("society:doorbell:callerNotif", function(data)
    VFW.ShowNotification({
        type    = 'JOB',
        logo    = data.image,
        title   = data.label,
        subtitle = "Sonnette",
        content = data.message,
    })
end)

-- Keep these for backward compatibility (called by Society._main.lua)
function Society.initDoorbell() end
function Society.unloadDoorbell() end
