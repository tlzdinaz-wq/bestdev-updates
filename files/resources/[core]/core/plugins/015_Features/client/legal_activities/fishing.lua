local Fishing = {}

VFW_IsFishing = false

Fishing.__index = Fishing

-- CONFIGURATION
Fishing.config = {
    WaterDepthLimit = 1.0,
    CastDistance = 15.0,
    AnimDict = "amb@world_human_stand_fishing@idle_a",
    AnimName = "idle_a",
    PropName = "prop_fishing_rod_01"
}



-- CONSTRUCTEUR
function Fishing.new()
    local self = setmetatable({}, Fishing)
    self.isFishing = false
    self.inMinigame = false
    self.waitForInput = false

    self.fishingRodProp = nil

    self.timerStart = 0
    self.timeToWait = 0
    self.isBiting = false
    self.biteTimer = 0
    self.hasBait = false
    self.currentMenuState = nil
    self.vipChecked = false
    self.vipAutoFishing = false
    self.isVip = false
    self.autoFishingEnabled = false

    return self
end

function Fishing:initalizeResell()
    CreateThread(function()
        local sleep = 1000
        while true do
            Wait(sleep)
            local ped = PlayerPedId()
            local playerPos = GetEntityCoords(ped)

            for k, v in pairs(Config.fishing.resell) do
                local distance = #(vector3(playerPos.x, playerPos.y, playerPos.z) - vector3(v.coords.x, v.coords.y, v.coords.z))
                if distance < 2.0 then
                    sleep = 0
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre votre poisson")
                    if VFW.Interact.JustPressed(0, 51) then
                        local itemToResell = TriggerServerCallback("core:legal_activities:fishing:getMyFishes")
                        SendNUIMessage({
                            action = "legal_activities:resell:open",
                            data = {
                                type = "fishing",
                                items = itemToResell
                            }
                        })
                        VFW.Nui.Focus(true, false)
                        FreezeEntityPosition(PlayerPedId(), true)
                    end
                end
            end
        end
    end)

    RegisterNuiCallback("legal_activities:resell:close:fishing", function(data, cb)
        VFW.Nui.Focus(false)
        FreezeEntityPosition(PlayerPedId(), false)
        cb("ok")
    end)

    RegisterNuiCallback("legal_activities:resell:sell:fishing", function(data, cb)
        TriggerServerEvent("core:legal_activities:fishing:resell", data.name, data.count, data.paymentType)

        cb("ok")
    end)
end

local fishingButtonId = generateUniqueID(8)

-- 1. VÉRIFICATION EAU
function Fishing:checkWater()
    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    local forwardVector = GetEntityForwardVector(ped)
    local targetX = playerPos.x + (forwardVector.x * self.config.CastDistance)
    local targetY = playerPos.y + (forwardVector.y * self.config.CastDistance)

    local waterHit, waterHeight = TestProbeAgainstWater(targetX, targetY, playerPos.z + 10.0, targetX, targetY,
        playerPos.z - 20.0)
    if not waterHit then
        local success, height = GetWaterHeight(targetX, targetY, playerPos.z, 0)
        if success then
            waterHit = true; waterHeight = height
        end
    end
    if not waterHit then
        VFW.ShowNotification({ type = "ROUGE", content = "Il n'y a pas d'eau à proximité, rapproche-toi de l'eau." }); return false
    end

    local rayStart = vector3(targetX, targetY, waterHeight)
    local rayEnd = vector3(targetX, targetY, waterHeight - 50.0)
    local rayHandle = StartShapeTestRay(rayStart.x, rayStart.y, rayStart.z, rayEnd.x, rayEnd.y, rayEnd.z, 17, ped, 0)
    local _, hit, endCoords, _, _ = GetShapeTestResult(rayHandle)
    local depth = 20.0
    if hit == 1 then depth = waterHeight - endCoords.z end
    if depth < self.config.WaterDepthLimit then
        VFW.ShowNotification({ type = "ROUGE", content = "Eau trop peu profonde." }); return false
    end

    return true
end

-- 2. DÉMARRAGE SESSION
function Fishing:startSession()
    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)

    self.isFishing = true
    self.inMinigame = false
    self.waitForInput = false

    VFW_IsFishing = true
    SetEntityInvincible(ped, true)
    SetEntityCanBeDamaged(ped, false)

    self.timeToWait = math.random(10000, 20000)
    self.timerStart = GetGameTimer()
    self.isBiting = false
    self.biteTimer = 0
    self.hasBait = false
    self.currentMenuState = "default"
    self.vipChecked = false
    self.vipAutoFishing = false
    self.isVip = false
    self.autoFishingEnabled = false

    VFW.ShowNotification({ type = "BLEU", content = "Vous commencez à pêcher..." })

    -- Bloquer s'accroupir / s'allonger pendant la pêche.
    -- Ctrl est registered via RegisterKeyMapping('+stance', ...) donc DisableControlAction
    -- ne le bloque pas — il faut passer par le flag exposé par stance.lua.
    SetStanceDisabled(true)

    -- Détection VIP en début de session : auto OFF par défaut, basculable via Espace
    CreateThread(function()
        local isVip = TriggerServerCallback("core:legal_activities:fishing:isVip")
        if isVip and self.isFishing then
            self.isVip = true
            self.autoFishingEnabled = false
            self.currentMenuState = nil
            VFW.ShowNotification({ type = "BLEU", content = "Mode VIP : pêche auto disponible (Espace pour activer)" })
        end
    end)

    -- Animation
    RequestAnimDict(self.config.AnimDict)
    while not HasAnimDictLoaded(self.config.AnimDict) do Wait(10) end

    -- Canne à pêche
    local rodHash = GetHashKey(self.config.PropName)
    RequestModel(rodHash)
    while not HasModelLoaded(rodHash) do Wait(10) end

    local boneIndex = GetPedBoneIndex(ped, 60309)
    self.fishingRodProp = VFW.OneSync.CreateObject(rodHash, playerPos)
    AttachEntityToEntity(self.fishingRodProp, ped, boneIndex, 0, 0, 0, 0, 0, 0, true, true, false, true, 1, true)

    TaskPlayAnim(ped, self.config.AnimDict, self.config.AnimName, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Helper : reconstruit les boutons selon l'état + ajoute le toggle VIP si applicable
    local function refreshButtons(state)
        local btns = {}
        if state == "restart" then
            table.insert(btns, { label = "Relancer la ligne", control = 38 })
            table.insert(btns, { label = "Arrêter", control = 73 })
        elseif state == "biting" then
            table.insert(btns, { label = "FERRER LE POISSON !", control = 38 })
            table.insert(btns, { label = "Arrêter", control = 73 })
        else -- default
            table.insert(btns, { label = "Mettre un appât", control = 23 })
            table.insert(btns, { label = "Arrêter de pêcher", control = 73 })
        end
        if self.isVip then
            table.insert(btns, { label = self.autoFishingEnabled and "Auto: ON" or "Auto: OFF", control = 22 })
        end
        instructionalButtons[fishingButtonId] = btns
    end

    refreshButtons("default")

    CreateThread(function()
        while self.isFishing do
            if self.inMinigame then
                Wait(500)
            else
                Wait(0)

                -- Toggle pêche auto VIP (Espace = control 22)
                if self.isVip and IsControlJustPressed(0, 22) then
                    self.autoFishingEnabled = not self.autoFishingEnabled
                    VFW.ShowNotification({
                        type = "BLEU",
                        content = self.autoFishingEnabled and "Pêche auto activée" or "Pêche auto désactivée"
                    })
                    self.currentMenuState = nil -- force refresh des boutons
                end

                -- CAS 1 : ATTENTE DE RELANCE (Après capture ou échec)
                if self.waitForInput then
                    if self.currentMenuState ~= "restart" then
                        refreshButtons("restart")
                        self.currentMenuState = "restart"
                    end

                    if VFW.Interact.JustPressed(0, 38) then -- E pour Relancer
                        self.waitForInput = false
                        self.isBiting = false
                        self.biteTimer = 0
                        self.hasBait = false
                        self.vipChecked = false
                        self.vipAutoFishing = false
                        self.timerStart = GetGameTimer()
                        self.timeToWait = math.random(10000, 20000)

                        TaskPlayAnim(ped, self.config.AnimDict, self.config.AnimName, 8.0, -8.0, -1, 1, 0, false, false,
                            false)

                        refreshButtons("default")
                        self.currentMenuState = "default"
                        VFW.ShowNotification({ type = "VERT", content = "Ligne relancée !" })
                    end
                    if IsControlJustPressed(0, 73) then self:stopFishing() end

                    -- CAS 2 : PÊCHE EN COURS
                else
                    if not self.isBiting then
                        if self.currentMenuState ~= "default" then
                            refreshButtons("default")
                            self.currentMenuState = "default"
                        end

                        if GetGameTimer() - self.timerStart > self.timeToWait then
                            self.isBiting = true
                            self.biteTimer = GetGameTimer()
                            -- Pas de notif "Ça mord !" en mode auto VIP (le thread auto la remplace)
                            if not (self.isVip and self.autoFishingEnabled) then
                                VFW.ShowNotification({ type = "BLEU", content = "Ça mord !" })
                                ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.1)
                            end
                        end

                        if IsControlJustPressed(0, 23) and not self.hasBait then
                            local putBait = TriggerServerCallback("core:legal_activities:fishing:putBait")
                            if putBait then
                                TaskPlayAnim(ped, self.config.AnimDict, "idle_c", 8.0, -8.0, -1, 1, 0, false, false,
                                    false)
                                Wait(3000)
                                if self.isFishing then
                                    TaskPlayAnim(ped, self.config.AnimDict, self.config.AnimName, 8.0,
                                        -8.0, -1, 1, 0, false, false, false)
                                end
                                VFW.ShowNotification({ type = "VERT", content = "Appât mis !" })
                                self.hasBait = true
                                self.timeToWait = math.random(3000, 6000)
                                self.timerStart = GetGameTimer()
                            end
                        end
                    else
                        -- CAS 3 : ÇA MORD

                        -- Pêche automatique VIP : seulement si activé via toggle
                        if self.isVip and self.autoFishingEnabled and not self.vipChecked then
                            self.vipChecked = true
                            self.vipAutoFishing = true
                            CreateThread(function()
                                local result = TriggerServerCallback("core:legal_activities:fishing:autoFishResult")
                                if not (result and result.isVip and self.isFishing) then
                                    -- Cas où le serveur dit "non VIP" entre-temps : on bascule en manuel
                                    self.vipAutoFishing = false
                                    self.vipChecked = true
                                    return
                                end

                                StopGameplayCamShaking(true)

                                -- Délai de ferrage
                                Wait(math.random(500, 1500))
                                if not self.isFishing then return end

                                if result.success then
                                    VFW.ShowNotification({ type = "VERT", content = "Poisson pêché automatiquement !" })
                                    TaskPlayAnim(ped, self.config.AnimDict, "idle_c", 8.0, -8.0, -1, 1, 0, false, false, false)
                                    Wait(2000)
                                else
                                    VFW.ShowNotification({ type = "ROUGE", content = "Le poisson s'est enfui..." })
                                    Wait(1000)
                                end

                                if not self.isFishing then return end

                                -- Animation idle
                                TaskPlayAnim(ped, self.config.AnimDict, self.config.AnimName, 8.0, -8.0, -1, 1, 0, false, false, false)

                                -- Reset atomique : timerStart AVANT isBiting=false pour respecter le cooldown
                                self.timerStart = GetGameTimer()
                                self.timeToWait = math.random(10000, 20000)
                                self.hasBait = false
                                self.waitForInput = false
                                self.inMinigame = false
                                self.currentMenuState = nil
                                self.isBiting = false
                                self.biteTimer = 0
                                self.vipAutoFishing = false
                                self.vipChecked = false
                            end)
                        end

                        -- Flow manuel (non-VIP, ou VIP avec auto désactivé)
                        if not self.vipAutoFishing then
                            if self.currentMenuState ~= "biting" then
                                refreshButtons("biting")
                                self.currentMenuState = "biting"
                            end

                            if GetGameTimer() - self.biteTimer > 3000 then
                                self.isBiting = false
                                StopGameplayCamShaking(true)
                                VFW.ShowNotification({ type = "ROUGE", content = "Raté..." })
                                self.waitForInput = true
                                self.timerStart = GetGameTimer()
                                self.currentMenuState = nil
                                self.vipChecked = false
                            end

                            if VFW.Interact.JustPressed(0, 38) then
                                StopGameplayCamShaking(true)
                                self.inMinigame = true
                                self.vipChecked = false
                                VFW.Nui.Focus(true)
                                SendNUIMessage({
                                    action = "fishing:openGame",
                                    data = {
                                        difficulty = self.hasBait and 1 or 0
                                    }
                                })
                            end
                        end
                    end
                    if IsControlJustPressed(0, 73) then self:stopFishing() end
                    if IsEntityDead(ped) or IsPedSwimming(ped) then self:stopFishing() end
                end
            end
        end
    end)
end

function Fishing:canFish()
    local canFish = self:checkWater()
    if canFish then
        self:startSession()
        return true
    end
    return false
end

function Fishing:stopFishing()
    self.isFishing = false
    self.inMinigame = false
    self.waitForInput = false
    StopGameplayCamShaking(true)
    SetStanceDisabled(false)

    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)

    VFW_IsFishing = false
    SetEntityInvincible(ped, false)
    SetEntityCanBeDamaged(ped, true)

    if self.fishingRodProp and DoesEntityExist(self.fishingRodProp) then
        DeleteObject(self.fishingRodProp)
        self.fishingRodProp = nil
    end

    instructionalButtons[fishingButtonId] = nil
    VFW.ShowNotification({ type = "BLEU", content = "Pêche terminée." })
end

local CFishing = Fishing.new()
CFishing:initalizeResell()


RegisterClientCallback("core:legal_activities:fishing:canFish", function()
    return CFishing:canFish()
end)

RegisterNUICallback('fishing:result', function(data, cb)
    cb('ok')
    VFW.Nui.Focus(false)
    local ped = PlayerPedId()

    if CFishing then
        CFishing.isBiting = false
        CFishing.biteTimer = 0
    end

    if data.success then
        VFW.ShowNotification({ type = "VERT", content = "Poisson attrapé !" })
        TaskPlayAnim(ped, "amb@world_human_stand_fishing@idle_a", "idle_c", 8.0, -8.0, -1, 1, 0, false, false, false)
        Wait(2000)

        if CFishing and CFishing.isFishing then
            TaskPlayAnim(ped, "amb@world_human_stand_fishing@idle_a", "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)
            CFishing.timerStart = GetGameTimer()
            CFishing.timeToWait = math.random(10000, 20000)


            CFishing.waitForInput = true
            CFishing.currentMenuState = nil
            CFishing.inMinigame = false


            local isVip = TriggerServerCallback("core:legal_activities:fishing:reward")
            if CFishing.isFishing and isVip then
                CFishing.waitForInput = false
                VFW.ShowNotification({ type = "BLEU", content = "Relance automatique..." })
            end
        end
    else
        VFW.ShowNotification({ type = "ROUGE", content = "Le poisson s'est enfui..." })
        if CFishing.isFishing then
            CFishing.timerStart = GetGameTimer()
            CFishing.currentMenuState = nil
            CFishing.inMinigame = false
            CFishing.waitForInput = true
            CreateThread(function()
                local isVip = TriggerServerCallback("core:legal_activities:fishing:isVip")
                if CFishing.isFishing and isVip then
                    CFishing.waitForInput = false
                    CFishing.isBiting = false
                    CFishing.hasBait = false
                end
            end)
        end
    end
end)
