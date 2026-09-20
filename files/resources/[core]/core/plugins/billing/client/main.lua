---@meta _
---@diagnostic disable: duplicate-doc-field

local lastId = nil
local lastData = {}
local lastSender = nil
local invoiceBillType = nil


local holdingNotepad = false
local notepadObj = nil
local pencilObj = nil

local function StartNotepad()
    local ped = PlayerPedId()
    local dict = "missheistdockssetup1clipboard@base"
    local anim = "base"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end

    RequestModel("prop_notepad_01")
    RequestModel("prop_pencil_01")
    while not HasModelLoaded("prop_notepad_01") or not HasModelLoaded("prop_pencil_01") do
        Citizen.Wait(100)
    end

    notepadObj = VFW.OneSync.CreateObject("prop_notepad_01", GetEntityCoords(ped))
    AttachEntityToEntity(notepadObj, ped, GetPedBoneIndex(ped, 18905), 0.1, 0.02, 0.05, 10.0, 0.0, 0.0, true, true, false,
        true, 1, true)

    pencilObj = VFW.OneSync.CreateObject("prop_pencil_01", GetEntityCoords(ped))
    AttachEntityToEntity(pencilObj, ped, GetPedBoneIndex(ped, 58866), 0.12, 0.0, 0.001, -150.0, 0.0, 0.0, true, true,
        false, true, 1, true)

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

    holdingNotepad = true
end

local function StopNotepad()
    local ped = PlayerPedId()

    ClearPedTasks(ped)

    if notepadObj and DoesEntityExist(notepadObj) then
        DeleteEntity(notepadObj)
        notepadObj = nil
    end

    if pencilObj and DoesEntityExist(pencilObj) then
        DeleteEntity(pencilObj)
        pencilObj = nil
    end

    holdingNotepad = false
end

RegisterNuiCallback("nui:invoice:close", function() -- sender & reicever
    VFW.Nui.Invoice(false)
    VFW.Nui.Focus(false)
    StopNotepad()
end)

RegisterNuiCallback("nui:invoice:send", function(data, cb) -- sender
    if not data.total or tonumber(data.total) <= 0 then
        VFW.Nui.Invoice(false)
        VFW.Nui.Focus(false)
        StopNotepad()
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous ne pouvez pas envoyer une facture à 0$."
        })
        return
    end

    VFW.Nui.Invoice(false)
    VFW.Nui.Focus(false)
    StopNotepad()
    lastData = data
    lastData.billType = invoiceBillType
    invoiceBillType = nil

    TriggerServerEvent("vfw:invoice:send", lastData, lastId)
end)

RegisterNetEvent("vfw:invoice:sendRecu", function() -- sender)
    if lastData.receiptReceiver then
        TriggerServerEvent("vfw:invoice:sendRecu", lastId, lastData)
    end
end)

RegisterNuiCallback("nui:invoice:payment", function(data) -- receiver
    VFW.Nui.Invoice(false)
    TriggerServerEvent("vfw:invoice:payment", data, lastSender)
end)


--@TODO make server side check
RegisterNUICallback("nui:invoice:payLater", function()
    VFW.Nui.Invoice(false)
    TriggerServerEvent("vfw:invoice:payLater", lastSender)
    StopNotepad()
end)

RegisterNuiCallback("nui:invoice:reject", function()
    VFW.Nui.Invoice(false)
    TriggerServerEvent("vfw:invoice:reject", lastSender)
    StopNotepad()
end)

-- Tout job de type police passe par IsPoliceJob() — saspsud/saspnord etc. auto-détectés
local canPayAfter = {
    ["ambulance"] = true,
    ["mecano"] = true,
}

local function CanPayAfter(societyName)
    if not societyName then return false end
    if canPayAfter[societyName] then return true end
    if IsPoliceJob and IsPoliceJob(societyName) then return true end
    return false
end


---@param data table
---@param sender any
RegisterNetEvent("nui:invoice:receive", function(data, sender) -- receiver
    lastSender = sender
    VFW.Nui.Invoice(false)
    VFW.Nui.Focus(false)

    VFW.Nui.Invoice(true, {
        sender = data.sender,
        receiver = data.receiver,
        receiverCompany = data.receiverCompany,
        date = data.date,
        reduce = data.reduce,
        items = data.items,
        societyName = data.societyName,
        societyImage = data.societyImage,
        billType = data.billType,
        payLater = CanPayAfter(data.societyName),
        total = data.total,
        isSender = false,
    })
end)




--- GetClosestPlayer
---@param maxDistance number
---@return number|nil playerId, number|nil distance
local function GetClosestPlayer(maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPlayer = nil
    local closestDistance = maxDistance

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)

            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end

    return closestPlayer, closestDistance
end

--- OpenInvoice
---@param targetId number|nil
---@param billType string|nil "personal" or "company"
local function OpenInvoice(targetId, billType)
    local playerId
    if not targetId then
        playerId = GetClosestPlayer(5.0)
        if not playerId then
            VFW.ShowNotification({
                type = "ROUGE",
                content = "Aucune personne à proximité"
            })
            return
        end
    end

    invoiceBillType = billType or nil
    lastId = targetId or GetPlayerServerId(playerId)
    local tName, societyImage, tJobLabel = TriggerServerCallback("vfw:invoice:getName", lastId)
    StartNotepad()

    Wait(500)
    VFW.Nui.Invoice(true, {
        sender = VFW.PlayerData.name,
        receiver = tName,
        receiverCompany = tJobLabel,
        billType = invoiceBillType,
        societyName = VFW.PlayerData.job.label,
        societyImage = societyImage,
        date = nil,
        reduce = 0,
        ---@class items
        items = {},
        total = 0,
        isSender = true,
    })

end

RegisterNetEvent("vfw:radial:open:invoice", function(targetId, billType)
    OpenInvoice(targetId, billType)
end)

---@param data table
RegisterNetEvent("vfw:invoice:open", function(data)
    if data then
        VFW.CloseInventory()
        Wait(100)
        VFW.Nui.Recu(true, data)
    end
end)

-- ============================================================
-- AMENDE POLICE — Notification avec Y/N
-- ============================================================

RegisterNetEvent("police:fine:received", function(data)
    if not data or not data.billId then return end

    local choice = false

    VFW.ShowNotification({
        title = VFW.BrandName(),
        label = "Amende reçue",
        mainMessage = "Vous avez reçu une amende de " .. VFW.Math.FormatMoney(data.amount) .. ".\nMotif : " .. data.offense .. "\n" .. (data.category or "") .. ".",
        type = "INVITE_NOTIFICATION",
        duration = 30
    })

    CreateThread(function()
        local startTime = GetGameTimer()
        while not choice do
            Wait(0)

            if GetGameTimer() - startTime > 30000 then
                VFW.RemoveNotification()
                VFW.ShowNotification({ type = 'ORANGE', content = "Amende mise en impayée." })
                break
            end

            if IsControlJustPressed(0, 246) then -- Y
                choice = true
                VFW.RemoveNotification()
                TriggerServerEvent("police:fine:pay", data.billId, data.amount)
                break
            end

            if IsControlJustPressed(0, 306) then -- N
                choice = true
                VFW.RemoveNotification()
                VFW.ShowNotification({ type = 'ROUGE', content = "Vous avez refusé l'amende." })
                break
            end
        end
    end)
end)

-- ============================================================
-- AMENDE ANNULÉE — Notification
-- ============================================================

RegisterNetEvent("police:fine:cancelled", function(data)
    if not data then return end

    VFW.ShowNotification({
        title = VFW.BrandName(),
        label = "Amende annulée",
        mainMessage = "Une amende à votre nom a été annulée.\nMotif : " .. (data.offense or "") .. "\n" .. (data.category or "") .. "\nPrix : " .. VFW.Math.FormatMoney(data.amount or 0) .. ".",
        type = "VERT",
        duration = 15
    })
end)

-- ============================================================
-- PPA — Notification attribution / retrait
-- ============================================================

RegisterNetEvent("police:ppa:notify", function(data)
    if not data then return end

    if data.granted then
        VFW.ShowNotification({
            title = VFW.BrandName(),
            label = "PPA attribué",
            mainMessage = "Vous avez reçu votre " .. (data.ppaLabel or "PPA") .. ".",
            type = "VERT",
            duration = 15
        })
    else
        VFW.ShowNotification({
            title = VFW.BrandName(),
            label = "PPA retiré",
            mainMessage = "Votre " .. (data.ppaLabel or "PPA") .. " a été retiré.",
            type = "ROUGE",
            duration = 15
        })
    end
end)
