---@meta _
---@diagnostic disable: duplicate-doc-field

-- =============================================
--              VFW.Tutorial
--   Lib de tutoriel/onboarding
-- =============================================

VFW.Tutorial = {}

-- État interne
local currentTutorial = nil
local currentStepIndex = 1
local tutorialBlip = nil
local locationCheckThread = nil
local inputListenerActive = false

-- Config
local NEXT_STEP_KEY = 51 -- Touche E (INPUT_CONTEXT)
local SKIP_KEY = 322 -- Touche ESC (INPUT_FRONTEND_CANCEL)
local LOCATION_RADIUS = 5.0 -- Rayon pour détecter l'arrivée à une location

-- =============================================
--              FONCTIONS UTILITAIRES
-- =============================================

local function saveTutorialCompleted(tutorialId)
    SetResourceKvp("tutorial_" .. tutorialId, "completed")
end

local function removeTutorialBlip()
    if tutorialBlip then
        RemoveBlip(tutorialBlip)
        tutorialBlip = nil
    end
end

local function stopLocationCheck()
    locationCheckThread = nil
end

local function createStepBlip(step)
    removeTutorialBlip()

    if step.type == "location" and step.coords then
        local coords = step.coords
        tutorialBlip = AddBlipForCoord(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])

        if step.blip then
            SetBlipSprite(tutorialBlip, step.blip.sprite or 1)
            SetBlipColour(tutorialBlip, step.blip.color or 3)
            SetBlipScale(tutorialBlip, step.blip.scale or 0.5)
        else
            SetBlipSprite(tutorialBlip, 1)
            SetBlipColour(tutorialBlip, 3)
            SetBlipScale(tutorialBlip, 0.5)
        end

        SetBlipRoute(tutorialBlip, true)
        SetBlipRouteColour(tutorialBlip, step.blip and step.blip.color or 3)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(step.title or "Objectif")
        EndTextCommandSetBlipName(tutorialBlip)
    end
end

local function startLocationCheck(step)
    stopLocationCheck()

    if step.type ~= "location" or not step.coords then return end

    local coords = step.coords
    local targetPos = vector3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
    local radius = step.radius or LOCATION_RADIUS

    locationCheckThread = true

    CreateThread(function()
        while locationCheckThread and currentTutorial do
            Wait(500)

            local playerPos = GetEntityCoords(PlayerPedId())
            local distance = #(playerPos - targetPos)

            if distance <= radius then
                stopLocationCheck()
                VFW.Tutorial.Next()
                break
            end
        end
    end)
end

local function sendCurrentStepToNui()
    if not currentTutorial then return end

    local step = currentTutorial.steps[currentStepIndex]
    if not step then return end

    createStepBlip(step)

    if step.type == "location" then
        startLocationCheck(step)
    else
        stopLocationCheck()
    end

    VFW.Nui.Tutorial(true, {
        id = currentTutorial.id,
        title = currentTutorial.title,
        skippable = currentTutorial.skippable ~= false,
        currentStep = currentStepIndex,
        totalSteps = #currentTutorial.steps,
        step = step
    })
end

local function startInputListener()
    if inputListenerActive then return end
    local myListener = {}
    inputListenerActive = myListener

    CreateThread(function()
        while inputListenerActive == myListener and currentTutorial do
            Wait(0)

            local step = currentTutorial and currentTutorial.steps[currentStepIndex]

            -- Touche E pour continuer (seulement pour info/tip)
            if step and (step.type == "info" or step.type == "tip") then
                if IsControlJustPressed(0, NEXT_STEP_KEY) then
                    VFW.Tutorial.Next()
                    Wait(300)
                end
            end

            -- ECHAP pour passer le tuto (si skippable)
            if currentTutorial and currentTutorial.skippable ~= false then
                DisableControlAction(0, 200, true) -- Désactiver le pause menu
                if IsDisabledControlJustPressed(0, 200) then
                    VFW.Tutorial.Skip()
                    break
                end
            end
        end

        if inputListenerActive == myListener then
            inputListenerActive = false
        end
    end)
end

local function stopInputListener()
    inputListenerActive = false
end

-- =============================================
--              API PUBLIQUE
-- =============================================

--- Démarre un tutoriel
---@param config table Configuration du tutoriel
---@return boolean success
function VFW.Tutorial.Start(config)
    if not config or not config.steps or #config.steps == 0 then
        console.error("[VFW.Tutorial] Configuration invalide ou pas d'étapes")
        return false
    end

    if not config.force and config.id and VFW.Tutorial.IsCompleted(config.id) then
        return false
    end

    if currentTutorial then
        VFW.Tutorial.End(true)
    end

    currentTutorial = config
    currentStepIndex = 1

    sendCurrentStepToNui()
    startInputListener()

    return true
end

--- Passe à l'étape suivante
function VFW.Tutorial.Next()
    if not currentTutorial then return false end

    if currentStepIndex < #currentTutorial.steps then
        currentStepIndex = currentStepIndex + 1
        sendCurrentStepToNui()
        return true
    else
        VFW.Tutorial.End()
        return false
    end
end

--- Revient à l'étape précédente
function VFW.Tutorial.Previous()
    if not currentTutorial then return false end

    if currentStepIndex > 1 then
        currentStepIndex = currentStepIndex - 1
        sendCurrentStepToNui()
        return true
    end

    return false
end

--- Termine le tutoriel
function VFW.Tutorial.End(silent)
    if not currentTutorial then return end

    local tutorial = currentTutorial

    if tutorial.id then
        saveTutorialCompleted(tutorial.id)
    end

    removeTutorialBlip()
    stopLocationCheck()
    stopInputListener()
    currentTutorial = nil
    currentStepIndex = 1

    VFW.Nui.Tutorial(false)

    if not silent and tutorial.onComplete then
        tutorial.onComplete()
    end


end

--- Passe le tutoriel
function VFW.Tutorial.Skip()
    if not currentTutorial then return end

    local tutorial = currentTutorial

    removeTutorialBlip()
    stopLocationCheck()
    stopInputListener()
    currentTutorial = nil
    currentStepIndex = 1

    VFW.Nui.Tutorial(false)

    if tutorial.onSkip then
        tutorial.onSkip()
    end


end

-- =============================================
--     COMPLETION D'ACTIONS (API SIMPLE)
-- =============================================

--- Complete l'étape actuelle si c'est une action
--- Usage: VFW.Tutorial.Complete() ou VFW.Tutorial.Complete("hack_completed")
---@param actionName? string Nom de l'action (optionnel, vérifie si match)
---@return boolean success
function VFW.Tutorial.Complete(actionName)
    if not currentTutorial then return false end

    local step = currentTutorial.steps[currentStepIndex]
    if not step then return false end

    -- Si c'est une étape action
    if step.type == "action" then
        -- Si un nom d'action est spécifié, vérifier qu'il match
        if actionName and step.action and step.action ~= actionName then
            return false
        end

        VFW.Tutorial.Next()
        return true
    end

    return false
end

--- Alias pour Complete - plus explicite
---@param actionName string Nom de l'action
---@return boolean success
function VFW.Tutorial.CompleteAction(actionName)
    return VFW.Tutorial.Complete(actionName)
end

--- Vérifie si le tutoriel actuel attend une action spécifique
---@param actionName string
---@return boolean
function VFW.Tutorial.IsWaitingFor(actionName)
    if not currentTutorial then return false end

    local step = currentTutorial.steps[currentStepIndex]
    if not step or step.type ~= "action" then return false end

    return step.action == actionName
end

--- Retourne l'action attendue par l'étape actuelle (ou nil)
---@return string|nil
function VFW.Tutorial.GetCurrentAction()
    if not currentTutorial then return nil end

    local step = currentTutorial.steps[currentStepIndex]
    if not step or step.type ~= "action" then return nil end

    return step.action
end

-- =============================================
--              AUTRES FONCTIONS
-- =============================================

function VFW.Tutorial.GoToStep(stepIndex)
    if not currentTutorial then return false end

    if stepIndex >= 1 and stepIndex <= #currentTutorial.steps then
        currentStepIndex = stepIndex
        sendCurrentStepToNui()
        return true
    end

    return false
end

function VFW.Tutorial.IsActive()
    return currentTutorial ~= nil
end

function VFW.Tutorial.GetCurrentId()
    return currentTutorial and currentTutorial.id or nil
end

function VFW.Tutorial.GetCurrentStep()
    return currentStepIndex
end

function VFW.Tutorial.IsCompleted(tutorialId)
    return GetResourceKvpString("tutorial_" .. tutorialId) == "completed"
end

function VFW.Tutorial.Reset(tutorialId)
    DeleteResourceKvp("tutorial_" .. tutorialId)
end

function VFW.Tutorial.ResetAll()
    local handle = StartFindKvp("tutorial_")
    local key = FindKvp(handle)

    while key do
        DeleteResourceKvp(key)
        key = FindKvp(handle)
    end

    EndFindKvp(handle)
end

-- =============================================
--              QUICK TIPS
-- =============================================

function VFW.Tutorial.ShowTip(config)
    if not config or not config.description then
        return
    end

    VFW.Nui.TutorialTip(true, {
        title = config.title or "Astuce",
        description = config.description,
        icon = config.icon or "info",
        position = config.position or "bottom-right"
    })

    local duration = config.duration or 5000
    if duration > 0 then
        SetTimeout(duration, function()
            VFW.Nui.TutorialTip(false)
        end)
    end
end

function VFW.Tutorial.HideTip()
    VFW.Nui.TutorialTip(false)
end

-- =============================================
--              EXPORTS
-- =============================================

-- API principale
exports("TutorialStart", VFW.Tutorial.Start)
exports("TutorialNext", VFW.Tutorial.Next)
exports("TutorialEnd", VFW.Tutorial.End)
exports("TutorialSkip", VFW.Tutorial.Skip)

-- Completion d'actions
exports("TutorialComplete", VFW.Tutorial.Complete)
exports("TutorialCompleteAction", VFW.Tutorial.CompleteAction)
exports("TutorialIsWaitingFor", VFW.Tutorial.IsWaitingFor)
exports("TutorialGetCurrentAction", VFW.Tutorial.GetCurrentAction)

-- Utilitaires
exports("TutorialIsActive", VFW.Tutorial.IsActive)
exports("TutorialIsCompleted", VFW.Tutorial.IsCompleted)
exports("TutorialReset", VFW.Tutorial.Reset)
exports("TutorialShowTip", VFW.Tutorial.ShowTip)

