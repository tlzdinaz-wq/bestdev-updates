local GOUV_IMG = VFW.CDN.Get("entreprise/gouvernement.png")

local peds = {}
for _, pedCfg in ipairs((MairieConfig and MairieConfig.GovernmentPeds) or {}) do
    peds[#peds + 1] = {
        model = pedCfg.model or "s_m_m_highsec_01",
        coords = pedCfg.coords,
        scope = pedCfg.scope,
        title = pedCfg.title,
        npcName = pedCfg.npcName,
    }
end

local formData = { phone = "", reason = "" }
local dialogueStep = "none"
local activeScope = nil
local activeTitle = "Gouvernement"

local function gouvNotif(subtitle, content)
    VFW.ShowNotification({ type = "JOB", title = activeTitle, subtitle = subtitle, image = GOUV_IMG, content = content })
end

local function RequestModelSync(hash)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local i = 0
    while not HasModelLoaded(hash) and i < 100 do
        Wait(10)
        i = i + 1
    end
    return HasModelLoaded(hash)
end

local function spawnPed(pedConfig)
    if pedConfig.spawned then return end
    local pedModel = joaat(pedConfig.model or "s_m_m_highsec_01")
    if not RequestModelSync(pedModel) then return end

    local entity = CreatePed(4, pedModel, pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z, pedConfig.coords.w, false, false)
    if entity and DoesEntityExist(entity) then
        SetBlockingOfNonTemporaryEvents(entity, true)
        SetPedFleeAttributes(entity, 0, 0)
        SetPedCanRagdoll(entity, false)
        SetEntityInvincible(entity, true)
        FreezeEntityPosition(entity, true)
        pedConfig.entity = entity
        pedConfig.spawned = true
    end
end

local function openDialogue(pedConfig)
    formData = { phone = "", reason = "" }
    dialogueStep = "welcome"
    activeScope = pedConfig.scope
    activeTitle = pedConfig.title

    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = 'nui:npcDialogue:open',
        data = {
            npcName = pedConfig.npcName,
            initialMessage = 'Bonjour, souhaitez-vous prendre rendez-vous ?',
            npcAvatar = nil,
            choices = {
                { id = 'yes', label = 'Oui' },
                { id = 'no', label = 'Non, a bientot', type = 'cancel' }
            }
        }
    })
end

for _, pedConfig in ipairs(peds) do
    CreateThread(function()
        spawnPed(pedConfig)

        while true do
            local pcoords = GetEntityCoords(PlayerPedId())
            local dist = #(pcoords - vector3(pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z))

            if dist < 50.0 then
                if not pedConfig.spawned then spawnPed(pedConfig) end
            end

            if dist < 2.0 then
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour prendre un rendez-vous")
                if VFW.Interact.JustReleased(0, 38) then
                    openDialogue(pedConfig)
                end
            end

            Wait(0)
        end
    end)
end

CreateThread(function()
    while true do
        Wait(0)
        if dialogueStep ~= "none" then
            if IsControlJustReleased(0, 322) then
                VFW.Nui.Focus(false, false)
                SendNUIMessage({ action = 'nui:npcDialogue:close' })
                dialogueStep = "none"
                gouvNotif("Rendez-vous", "Vous avez quitté le dialogue.")
            end
        end
    end
end)

CreateThread(function()
    local lostFocusTicks = 0
    while true do
        Wait(500)
        if dialogueStep ~= "none" and not VFW.Nui.HasFocus() then
            lostFocusTicks = lostFocusTicks + 1
            if lostFocusTicks >= 3 then
                SendNUIMessage({ action = 'nui:npcDialogue:close' })
                dialogueStep = "none"
                lostFocusTicks = 0
            end
        else
            lostFocusTicks = 0
        end
    end
end)

RegisterNUICallback('npcDialogue:formSubmit', function(data, cb)
    if not data then
        cb('error')
        return
    end

    formData = {
        phone = data.phone and tostring(data.phone) or "",
        reason = data.reason and tostring(data.reason) or ""
    }

    dialogueStep = "confirm"

    SendNUIMessage({ action = 'nui:npcDialogue:hideForm' })
    Wait(300)
    SendNUIMessage({
        action = 'nui:npcDialogue:addMessage',
        data = { type = "sent", content = "C'est bon, voici mon formulaire" }
    })
    Wait(500)
    SendNUIMessage({ action = 'nui:npcDialogue:showTyping', data = true })
    Wait(1000)
    SendNUIMessage({
        action = 'nui:npcDialogue:addMessage',
        data = { type = "received", content = "Merci ! Veuillez confirmer ou modifier votre rendez-vous." }
    })
    Wait(800)
    SendNUIMessage({ action = 'nui:npcDialogue:showTyping', data = false })
    Wait(400)
    SendNUIMessage({
        action = 'nui:npcDialogue:setChoices',
        data = {
            { id = 'confirm', label = 'Confirmer le rendez-vous' },
            { id = 'modify', label = 'Modifier le formulaire' },
            { id = 'cancel', label = 'Annuler', type = 'cancel' }
        }
    })

    cb('ok')
end)

RegisterNUICallback('npcDialogue:formCancel', function(data, cb)
    VFW.Nui.Focus(false, false)
    SendNUIMessage({ action = 'nui:npcDialogue:close' })
    dialogueStep = "none"
    gouvNotif("Rendez-vous", "Demande de rendez-vous annulée.")
    cb('ok')
end)

RegisterNUICallback('npcDialogue:choice', function(data, cb)
    local choiceId = data.choiceId

    if dialogueStep == "welcome" then
        if choiceId == 'yes' then
            SendNUIMessage({
                action = 'nui:npcDialogue:addMessage',
                data = { type = "sent", content = "Oui" }
            })

            dialogueStep = "form"

            Wait(500)
            SendNUIMessage({ action = 'nui:npcDialogue:showTyping', data = true })
            Wait(1000)
            SendNUIMessage({
                action = 'nui:npcDialogue:addMessage',
                data = { type = "received", content = "Pas de soucis, remplissez le formulaire ci-dessous s'il vous plait." }
            })
            Wait(800)
            SendNUIMessage({ action = 'nui:npcDialogue:showTyping', data = false })
            Wait(400)
            SendNUIMessage({
                action = 'nui:npcDialogue:showForm',
                data = {
                    form = {
                        { id = 'phone', label = 'Numero de telephone', placeholder = '555-0000', type = 'tel', maxLength = 8 },
                        { id = 'reason', label = 'Raison du rendez-vous', placeholder = 'Decrivez votre demande...', type = 'textarea', maxLength = 120 }
                    },
                    formTitle = 'Formulaire de Rendez-vous'
                }
            })

        elseif choiceId == 'no' then
            SendNUIMessage({
                action = 'nui:npcDialogue:addMessage',
                data = { type = "sent", content = "Non, a bientot" }
            })
            Wait(500)
            VFW.Nui.Focus(false, false)
            SendNUIMessage({ action = 'nui:npcDialogue:close' })
            dialogueStep = "none"
        end
    elseif dialogueStep == "confirm" then
        if choiceId == 'confirm' then
            SendNUIMessage({
                action = 'nui:npcDialogue:addMessage',
                data = { type = "sent", content = "Confirmer le rendez-vous" }
            })
            Wait(300)
            VFW.Nui.Focus(false, false)
            SendNUIMessage({ action = 'nui:npcDialogue:close' })
            dialogueStep = "none"
            Wait(200)

            TriggerServerEvent('gouvernement:addAppointment', {
                phone = formData.phone,
                reason = formData.reason,
                scope = activeScope
            })

            gouvNotif("Rendez-vous", "Votre demande de rendez-vous a bien été envoyée.")
        elseif choiceId == 'modify' then
            SendNUIMessage({
                action = 'nui:npcDialogue:addMessage',
                data = { type = "sent", content = "Modifier le formulaire" }
            })
            Wait(500)
            dialogueStep = "form"
            SendNUIMessage({
                action = 'nui:npcDialogue:showForm',
                data = {
                    form = {
                        { id = 'phone', label = 'Numero de telephone', placeholder = '555-0000', type = 'tel', maxLength = 8 },
                        { id = 'reason', label = 'Raison du rendez-vous', placeholder = 'Decrivez votre demande...', type = 'textarea', maxLength = 120 }
                    },
                    formTitle = 'Formulaire de Rendez-vous',
                    prefillData = formData
                }
            })
        elseif choiceId == 'cancel' then
            VFW.Nui.Focus(false, false)
            SendNUIMessage({ action = 'nui:npcDialogue:close' })
            dialogueStep = "none"
            gouvNotif("Rendez-vous", "Demande de rendez-vous annulée.")
        end
    end

    cb('ok')
end)
