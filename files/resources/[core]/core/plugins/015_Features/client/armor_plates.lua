local monitorThread = false
local lastArmor = 0

-- Combat cooldown: impossible d'equiper GPB ou plaque pendant 2 min apres degats
local COMBAT_COOLDOWN_MS = 120000
local combatLastDamageTime = 0
local combatTrackerActive = false
local trackedHealth = 0
local trackedArmor = 0

local function StartCombatTracker()
    if combatTrackerActive then return end
    combatTrackerActive = true
    trackedHealth = GetEntityHealth(PlayerPedId())
    trackedArmor = GetPedArmour(PlayerPedId())

    Citizen.CreateThread(function()
        while combatTrackerActive do
            local ped = PlayerPedId()
            local currentHealth = GetEntityHealth(ped)
            local currentArmor = GetPedArmour(ped)

            if currentHealth < trackedHealth or currentArmor < trackedArmor then
                combatLastDamageTime = GetGameTimer()
            end

            trackedHealth = currentHealth
            trackedArmor = currentArmor
            Citizen.Wait(200)
        end
    end)
end

VFW.IsInCombatCooldown = function()
    if combatLastDamageTime == 0 then return false, 0 end
    local remaining = COMBAT_COOLDOWN_MS - (GetGameTimer() - combatLastDamageTime)
    if remaining > 0 then
        return true, math.ceil(remaining / 1000)
    end
    return false, 0
end

local function StartArmorMonitor()
    if monitorThread then return end
    monitorThread = true

    Citizen.CreateThread(function()
        while monitorThread do
            local currentArmor = GetPedArmour(PlayerPedId())

            if currentArmor < lastArmor then
                local damageTaken = lastArmor - currentArmor
                TriggerServerEvent("vfw:armor:syncDamage", damageTaken)
            end

            lastArmor = currentArmor
            Citizen.Wait(100)
        end
    end)
end

local function StopArmorMonitor()
    monitorThread = false
    lastArmor = 0
end

RegisterNetEvent("vfw:armor:plateEquipped")
AddEventHandler("vfw:armor:plateEquipped", function(data)
    SetPedArmour(PlayerPedId(), data.totalArmor)
    lastArmor = data.totalArmor
    trackedArmor = data.totalArmor

    local message = "+" .. data.plateValue .. " armure (" .. data.plateAdded .. ")"
    if data.surplus and data.surplus > 0 then
        message = message .. " - " .. data.surplus .. " perdu (max 100)"
    end

    VFW.ShowNotification({
        type = 'VERT',
        content = message
    })

    StartArmorMonitor()
    Citizen.Wait(200)
    VFW.LoadInventories()
end)


RegisterNetEvent("vfw:armor:plateDestroyed")
AddEventHandler("vfw:armor:plateDestroyed", function(data)
    VFW.ShowNotification({
        type = 'ROUGE',
        content = data.plateType .. " détruite !"
    })
end)

RegisterNetEvent("vfw:armor:durabilityUpdated")
AddEventHandler("vfw:armor:durabilityUpdated", function(data)
    -- Stopper le monitor avant de réécrire l'armure pour éviter qu'il interprète
    -- l'écart (ancien armor -> nouveau) comme des dégâts
    StopArmorMonitor()

    SetPedArmour(PlayerPedId(), data.totalArmor)
    trackedArmor = data.totalArmor

    if data.totalArmor > 0 then
        -- Attendre que SetPedArmour soit appliqué avant de relancer le monitor
        Citizen.SetTimeout(800, function()
            lastArmor = GetPedArmour(PlayerPedId())
            if lastArmor > 0 then
                StartArmorMonitor()
            end
        end)
    end

    Citizen.Wait(200)
    VFW.LoadInventories()
end)

RegisterNetEvent("vfw:armor:equipFailed")
AddEventHandler("vfw:armor:equipFailed", function(reason)
    VFW.ShowNotification({
        type = 'ROUGE',
        content = reason
    })
end)

RegisterNetEvent("vfw:armor:vestRemoved")
AddEventHandler("vfw:armor:vestRemoved", function(hasPlates)
    StopArmorMonitor()
    SetPedArmour(PlayerPedId(), 0)
    trackedArmor = 0
    Citizen.Wait(200)
    VFW.LoadInventories()
end)

AddEventHandler("vfw:armor:restorePlates", function(totalArmor)
    lastArmor = totalArmor
    trackedArmor = totalArmor
    StartArmorMonitor()
end)

local function InitArmorState()
    StartCombatTracker()
    local data = TriggerServerCallback("vfw:armor:getEquippedPlates")
    if data and data.totalArmor and data.totalArmor > 0 then
        SetPedArmour(PlayerPedId(), data.totalArmor)
        trackedArmor = data.totalArmor
        Citizen.Wait(1000)
        lastArmor = GetPedArmour(PlayerPedId())
        if lastArmor > 0 then
            StartArmorMonitor()
        end
    end
end

AddEventHandler("vfw:playerLoaded", function()
    Citizen.Wait(5000)
    InitArmorState()
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if not (VFW and VFW.PlayerLoaded) then return end
    Citizen.Wait(2000)
    InitArmorState()
end)
