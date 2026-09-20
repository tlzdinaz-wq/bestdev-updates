---@meta _
---@diagnostic disable: duplicate-doc-field

local npc = nil
local isInDialogue = false
local dialogueCam = nil
local capturedMugshotUrl = nil

-- Spawn NPC au démarrage
CreateThread(function()
    while not VFW.PlayerLoaded do
        Wait(100)
    end

    local cfg = Config.MairiePhoto
    if not cfg then
        print("^1[MAIRIE PHOTO]^0 Config.MairiePhoto non trouvée!")
        return
    end

    VFW.Streaming.RequestModel(cfg.npc.model)
    npc = CreatePed(4, joaat(cfg.npc.model), cfg.npc.coords.x, cfg.npc.coords.y, cfg.npc.coords.z, cfg.npc.coords.w, false, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    TaskStartScenarioInPlace(npc, cfg.npc.scenario, 0, true)
    SetModelAsNoLongerNeeded(joaat(cfg.npc.model))

    -- Blip
    if cfg.blip.enabled then
        local blip = AddBlipForCoord(cfg.npc.coords.x, cfg.npc.coords.y, cfg.npc.coords.z)
        SetBlipSprite(blip, cfg.blip.sprite)
        SetBlipScale(blip, cfg.blip.scale)
        SetBlipColour(blip, cfg.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(cfg.blip.name)
        EndTextCommandSetBlipName(blip)
    end

end)

-- Détection proximité et interaction E
CreateThread(function()
    while true do
        local sleep = 500

        if npc and DoesEntityExist(npc) and not isInDialogue then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local npcCoords = GetEntityCoords(npc)
            local dist = #(playerCoords - npcCoords)

            if dist < 2.0 then
                sleep = 0
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour parler")

                if VFW.Interact.JustPressed(0, 38) then -- E key
                    StartPhotoDialogue()
                end
            end
        end

        Wait(sleep)
    end
end)

function StartPhotoDialogue()
    if isInDialogue then return end
    isInDialogue = true

    local cfg = Config.MairiePhoto

    -- Caméra sur le PNJ
    local headBone = GetPedBoneCoords(npc, 31086, 0.0, 0.0, 0.0)
    local npcForward = GetEntityForwardVector(npc)
    local camCoords = vector3(
        headBone.x + npcForward.x * 1.0,
        headBone.y + npcForward.y * 1.0,
        headBone.z
    )

    dialogueCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(dialogueCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(dialogueCam, headBone.x, headBone.y, headBone.z)
    SetCamActive(dialogueCam, true)
    RenderScriptCams(true, true, 500, true, true)

    -- Ouvrir le dialogue NUI
    SendNUIMessage({
        action = "nui:npcDialogue:open",
        data = {
            npcName = cfg.npc.name,
            npcAvatar = cfg.npc.avatar,
            initialMessage = "Bonjour, je suis Marie, la secrétaire du Gouvernement de l'État de San Andreas.\n\nComment puis-je vous aider ?",
            choices = {
                { id = "photo", label = "Refaire ma photo d'identité (" .. VFW.Math.FormatMoney(cfg.price) .. ")" },
                { id = "cancel", label = "Non merci, au revoir", type = "cancel" }
            }
        }
    })

    VFW.Nui.Focus(true, false)
end

function EndDialogue()
    isInDialogue = false

    if dialogueCam then
        RenderScriptCams(false, true, 500, true, true)
        SetCamActive(dialogueCam, false)
        DestroyCam(dialogueCam, false)
        dialogueCam = nil
    end

    SendNUIMessage({ action = "nui:npcDialogue:close" })
    VFW.Nui.Focus(false, false)
end

function ShowPhotoPreview(url)
    isInDialogue = true

    local cfg = Config.MairiePhoto

    -- Caméra sur le PNJ
    local headBone = GetPedBoneCoords(npc, 31086, 0.0, 0.0, 0.0)
    local npcForward = GetEntityForwardVector(npc)
    local camCoords = vector3(
        headBone.x + npcForward.x * 1.0,
        headBone.y + npcForward.y * 1.0,
        headBone.z
    )

    dialogueCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(dialogueCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(dialogueCam, headBone.x, headBone.y, headBone.z)
    SetCamActive(dialogueCam, true)
    RenderScriptCams(true, true, 500, true, true)

    -- Ouvrir le dialogue avec la photo
    SendNUIMessage({
        action = "nui:npcDialogue:open",
        data = {
            npcName = cfg.npc.name,
            npcAvatar = cfg.npc.avatar,
            initialMessage = "Voici votre nouvelle photo. Souhaitez-vous la conserver ?",
            initialImage = url,
            choices = {
                { id = "keep_photo", label = "Oui, garder cette photo" },
                { id = "retake_photo", label = "Non, reprendre la photo", type = "cancel" }
            }
        }
    })

    VFW.Nui.Focus(true, false)
end

-- Ouvre le dialogue avec un message d'attente pendant l'upload de la photo
function ShowWaitingDialogue()
    isInDialogue = true

    local cfg = Config.MairiePhoto

    -- Caméra sur le PNJ
    local headBone = GetPedBoneCoords(npc, 31086, 0.0, 0.0, 0.0)
    local npcForward = GetEntityForwardVector(npc)
    local camCoords = vector3(
        headBone.x + npcForward.x * 1.0,
        headBone.y + npcForward.y * 1.0,
        headBone.z
    )

    dialogueCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(dialogueCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(dialogueCam, headBone.x, headBone.y, headBone.z)
    SetCamActive(dialogueCam, true)
    RenderScriptCams(true, true, 500, true, true)

    -- Ouvrir le dialogue avec message d'attente
    SendNUIMessage({
        action = "nui:npcDialogue:open",
        data = {
            npcName = cfg.npc.name,
            npcAvatar = cfg.npc.avatar,
            initialMessage = "Parfait ! Laissez-moi quelques instants, votre photo est en cours d'impression...",
            choices = {}  -- Pas de choix pendant l'attente
        }
    })

    VFW.Nui.Focus(true, false)
end

-- Met à jour le dialogue existant avec la photo une fois l'upload terminé
function UpdateDialogueWithPhoto(url)
    -- Afficher l'indicateur de typing pendant 800ms pour l'effet
    SendNUIMessage({
        action = "nui:npcDialogue:showTyping",
        data = true
    })

    SetTimeout(800, function()
        -- Cacher l'indicateur de typing
        SendNUIMessage({
            action = "nui:npcDialogue:showTyping",
            data = false
        })

        -- Ajouter le message avec la photo
        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = {
                type = "received",
                content = "Et voilà ! Qu'en pensez-vous ?",
                image = url
            }
        })

        -- Petit délai puis ajouter les choix
        SetTimeout(300, function()
            SendNUIMessage({
                action = "nui:npcDialogue:setChoices",
                data = {
                    { id = "keep_photo", label = "Oui, garder cette photo" },
                    { id = "retake_photo", label = "Non, reprendre la photo", type = "cancel" }
                }
            })
        end)
    end)
end

-- Callback pour les choix du joueur
RegisterNUICallback("npcDialogue:choice", function(data, cb)
    local choice = data.choiceId
    local cfg = Config.MairiePhoto

    if choice == "cancel" or choice == "goodbye" then
        -- Réponse du joueur
        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "sent", content = "Au revoir !" }
        })

        Wait(300)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = true })
        Wait(800)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = false })
        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "received", content = "Bonne journée !" }
        })

        Wait(1000)
        EndDialogue()

    elseif choice == "photo" then
        -- Joueur demande la photo
        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "sent", content = "Je voudrais refaire ma photo d'identité" }
        })

        Wait(300)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = true })
        Wait(1200)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = false })
        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "received", content = "Bien sûr ! Cela vous coûtera " .. VFW.Math.FormatMoney(cfg.price) .. ". Comment souhaitez-vous payer ?" }
        })

        Wait(300)
        SendNUIMessage({
            action = "nui:npcDialogue:setChoices",
            data = {
                { id = "pay_cash", label = "Payer en espèces" },
                { id = "pay_bank", label = "Payer par carte" },
                { id = "cancel", label = "Annuler", type = "cancel" }
            }
        })

    elseif choice == "pay_cash" or choice == "pay_bank" then
        local paymentMethod = choice == "pay_cash" and "cash" or "bank"

        -- Hide choices while processing
        SendNUIMessage({
            action = "nui:npcDialogue:setChoices",
            data = {}
        })

        local result = TriggerServerCallback("mairie:photo:pay", paymentMethod)

        if result and result.success then
            SendNUIMessage({
                action = "nui:npcDialogue:addMessage",
                data = { type = "sent", content = "Voilà le paiement" }
            })

            Wait(300)
            SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = true })
            Wait(1000)
            SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = false })
            SendNUIMessage({
                action = "nui:npcDialogue:addMessage",
                data = { type = "received", content = "Parfait ! Suivez-moi pour la photo..." }
            })

            Wait(1500)

            -- Fade out AVANT de fermer le dialogue pour cacher la transition de caméra
            DoScreenFadeOut(500)
            Wait(500)

            EndDialogue()

            -- Lancer la capture du mugshot (skipInitialFade = true car déjà fait)
            CaptureFastMugshotWithCallback(
                -- Callback final: quand l'upload est terminé
                function(success, mugshotUrl)
                    if success and mugshotUrl then
                        capturedMugshotUrl = mugshotUrl
                        UpdateDialogueWithPhoto(mugshotUrl)
                    else
                        SendNUIMessage({
                            action = "nui:npcDialogue:addMessage",
                            data = { type = "received", content = "Oh non, il y a eu un problème avec l'imprimante..." }
                        })
                    end
                end,
                true,  -- skipInitialFade
                -- Callback immédiat après la photo (ouvre le dialogue d'attente)
                function()
                    ShowWaitingDialogue()
                end
            )
        else
            -- Proposer l'autre moyen de paiement ou revenir plus tard
            local alternativeChoice, alternativeLabel
            if paymentMethod == "cash" then
                alternativeChoice = "pay_bank"
                alternativeLabel = "Payer par carte"
            else
                alternativeChoice = "pay_cash"
                alternativeLabel = "Payer en espèces"
            end

            local errorMsg = (result and result.error or "Fonds insuffisants")
                .. " Souhaitez-vous essayer un autre moyen de paiement ?"

            SendNUIMessage({
                action = "nui:npcDialogue:addMessage",
                data = { type = "received", content = errorMsg }
            })

            Wait(300)
            SendNUIMessage({
                action = "nui:npcDialogue:setChoices",
                data = {
                    { id = alternativeChoice, label = alternativeLabel },
                    { id = "comeback_later", label = "Je reviendrai plus tard" }
                }
            })
        end

    elseif choice == "keep_photo" then
        -- Sauvegarder la photo
        TriggerServerEvent("vfw:server:setMugshot", capturedMugshotUrl)
        capturedMugshotUrl = nil

        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "sent", content = "Parfait, je la garde !" }
        })

        Wait(300)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = true })
        Wait(800)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = false })
        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "received", content = "C'est enregistré ! Bonne journée !" }
        })

        Wait(1000)
        EndDialogue()

        VFW.ShowNotification({
            type = "SUCCESS",
            content = "Votre photo d'identité a été mise à jour."
        })

    elseif choice == "retake_photo" then
        capturedMugshotUrl = nil

        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "sent", content = "Je préfère reprendre la photo" }
        })

        Wait(300)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = true })
        Wait(600)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = false })
        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "received", content = "Pas de problème, retournons au studio..." }
        })

        Wait(1000)

        -- Fade out AVANT de fermer le dialogue pour cacher la transition de caméra
        DoScreenFadeOut(500)
        Wait(500)

        EndDialogue()

        -- Reprendre la photo (skipInitialFade = true car déjà fait)
        CaptureFastMugshotWithCallback(
            -- Callback final: quand l'upload est terminé
            function(success, mugshotUrl)
                if success and mugshotUrl then
                    capturedMugshotUrl = mugshotUrl
                    UpdateDialogueWithPhoto(mugshotUrl)
                else
                    SendNUIMessage({
                        action = "nui:npcDialogue:addMessage",
                        data = { type = "received", content = "Oh non, il y a eu un problème avec l'imprimante..." }
                    })
                end
            end,
            true,  -- skipInitialFade
            -- Callback immédiat après la photo (ouvre le dialogue d'attente)
            function()
                ShowWaitingDialogue()
            end
        )

    elseif choice == "comeback_later" then
        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "sent", content = "Je reviendrai plus tard" }
        })

        Wait(300)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = true })
        Wait(600)
        SendNUIMessage({ action = "nui:npcDialogue:showTyping", data = false })
        SendNUIMessage({
            action = "nui:npcDialogue:addMessage",
            data = { type = "received", content = "Pas de problème, revenez quand vous voulez ! Bonne journée !" }
        })

        Wait(1500)
        EndDialogue()
    end

    cb({ success = true })
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if npc and DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
        if dialogueCam then
            DestroyCam(dialogueCam, false)
        end
    end
end)
