local HOLD_DURATION = 5000
local BLINKS_COUNT = 10
local BG_ALPHA = 190
local PROGRESS_INTERVAL = 50

local function ShowWarningPopup(message, reason)
    local buttonId = generateUniqueID()

    instructionalButtons[buttonId] = {
        { control = 22, label = "Maintenir pour masquer" }
    }

    SendNUIMessage({
        action = "hud:warn:show",
        data = { message = message or "", reason = reason or "" }
    })

    CreateThread(function()
        local timeBlinkStarted = nil
        local lastSend = 0
        local lastProgress = -1
        local lastAlpha = -1

        while true do
            local timeNow = GetGameTimer()

            if IsControlPressed(0, 22) or IsDisabledControlPressed(0, 22) then
                if timeBlinkStarted == nil then
                    timeBlinkStarted = timeNow
                    PlaySoundFrontend(-1, "CLICK_BACK", "WEB_NAVIGATION_SOUNDS_PHONE", true)
                elseif timeNow - timeBlinkStarted > HOLD_DURATION then
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    break
                end
            else
                if timeBlinkStarted ~= nil then
                    PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                end
                timeBlinkStarted = nil
            end

            local alpha = BG_ALPHA
            local progress = 0

            if timeBlinkStarted then
                local timeHeld = timeNow - timeBlinkStarted
                local blinkPhaseDuration = HOLD_DURATION / BLINKS_COUNT
                local blinkPhaseIdx = math.floor(timeHeld / blinkPhaseDuration)
                local isInverted = (blinkPhaseIdx % 2) == 0

                local blinkPhaseTime = timeHeld % blinkPhaseDuration
                local blinkPhaseAlpha = math.floor((blinkPhaseTime / blinkPhaseDuration) * BG_ALPHA)

                if isInverted then
                    blinkPhaseAlpha = BG_ALPHA - blinkPhaseAlpha
                end

                alpha = blinkPhaseAlpha
                progress = math.min(timeHeld / HOLD_DURATION, 1.0)
            end

            if (alpha ~= lastAlpha or progress ~= lastProgress) and (timeNow - lastSend) >= PROGRESS_INTERVAL then
                lastSend = timeNow
                lastAlpha = alpha
                lastProgress = progress

                SendNUIMessage({
                    action = "hud:warn:progress",
                    data = { progress = progress, alpha = alpha }
                })
            end

            Wait(0)
        end

        SendNUIMessage({ action = "hud:warn:hide", data = {} })

        instructionalButtons[buttonId] = {}
    end)
end

RegisterNetEvent("vfw:warn:showPopup")
AddEventHandler("vfw:warn:showPopup", function(message, reason)
    ShowWarningPopup(message, reason)
end)

RegisterNetEvent("vfw:staff:warn:chooseMode")
AddEventHandler("vfw:staff:warn:chooseMode", function()
    local choice = VFW.Nui.ChoiceInput("Mode d'affichage", "Choisissez le type d'avertissement", {
        { label = "Avertissement Visuel", value = "visual", icon = ":monitor:" },
        { label = "Message Chat", value = "chat", icon = ":chat:" }
    })
    if not choice then return end
    TriggerServerEvent("vfw:staff:warn:execute", choice == "visual")
end)

RegisterNetEvent("vfw:staff:sanction:chooseMode")
AddEventHandler("vfw:staff:sanction:chooseMode", function(callbackEvent, ...)
    local extraArgs = { ... }
    local choice = VFW.Nui.ChoiceInput("Mode d'affichage", "Choisissez le type d'avertissement", {
        { label = "Avertissement Visuel", value = "visual", icon = ":monitor:" },
        { label = "Message Chat", value = "chat", icon = ":chat:" }
    })
    if not choice then return end
    TriggerServerEvent(callbackEvent, choice == "visual", table.unpack(extraArgs))
end)
