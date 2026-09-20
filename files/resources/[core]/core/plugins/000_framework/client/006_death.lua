---@meta _
---@diagnostic disable: duplicate-doc-field

---@class Death
---@field _index any
---@field isDead boolean
---@field secToWait number
---@field secLeft any
---@field GetAllDamagePed table
---@field GetBonesType any
---@field deatCause any
---@field GetDeathType any
---@field isDead boolean
Death = {}
Death._index = Death
Death.isDead = false
Death.clonePed = nil
Death.gettingRevived = false

local emsCallSession = 0 -- déclaré ici pour être accessible par ReviveSelf et le thread EMS
local cooldownems = false
local hasCalledEmsNoResponse = false

-- Fonction pour nettoyer les notifications de KO (doit être définie avant son utilisation)
local function ClearKONotifications()
    SendNUIMessage({
        action = "nui:hud:remove-notifications",
        data = "ko_waiting_notification"
    })
    SendNUIMessage({
        action = "nui:hud:remove-notifications",
        data = "ko_getup_notification"
    })
end
Death.secToWait = 300
Death.secLeft = Death.secToWait
Death.GetAllDamagePed = {}
Death.emsCount = 0
Death.deathCoords = nil
Death.deathHeading = nil
Death.wasFalling = false
Death.lastFallVelocity = 0.0
Death.lastDamageHash = 0
Death.lastDamageTime = 0
Death.GetBonesType = {
    ["Dos"] = { 0, 23553, 56604, 57597 },
    ["Crâne"] = { 1356, 11174, 12844, 17188, 17719, 19336, 20178, 20279, 20623, 21550, 25260, 27474, 29868, 31086,
                  35731, 43536, 45750, 46240, 47419, 47495, 49979, 58331, 61839, 39317 },
    ["Coude droit"] = { 2992 },
    ["Coude gauche"] = { 22711 },
    ["Main gauche"] = { 4089, 4090, 4137, 4138, 4153, 4154, 4169, 4170, 4185, 4186, 18905, 26610, 26611, 26612, 26613,
                        26614, 60309 },
    ["Main droite"] = { 6286, 28422, 57005, 58866, 58867, 58868, 58869, 58870, 64016, 64017, 64064, 64065, 64080, 64081,
                        64096, 64097, 64112, 64113 },
    ["Bras gauche"] = { 5232, 45509, 61007, 61163 },
    ["Bras droit"] = { 28252, 40269, 43810 },
    ["Jambe droite"] = { 6442, 16335, 51826, 36864 },
    ["Jambe gauche"] = { 23639, 46078, 58271, 63931 },
    ["Pied droit"] = { 20781, 24806, 35502, 52301 },
    ["Pied gauche"] = { 2108, 14201, 57717, 65245 },
    ["Poîtrine"] = { 10706, 64729, 24816, 24817, 24818 },
    ["Ventre"] = { 11816 }
}
Death.deatCause = {
    -- Armes de mêlée
    [joaat('WEAPON_UNARMED')] = { 'Tabassé', 'Poings' },
    [joaat('WEAPON_KNUCKLE')] = { 'Tabassé', 'Poing américain' },
    [joaat('WEAPON_NIGHTSTICK')] = { 'Tabassé', 'Matraque' },
    [joaat('WEAPON_HAMMER')] = { 'Tabassé', 'Marteau' },
    [joaat('WEAPON_BAT')] = { 'Tabassé', 'Batte de baseball' },
    [joaat('WEAPON_GOLFCLUB')] = { 'Tabassé', 'Club de golf' },
    [joaat('WEAPON_CROWBAR')] = { 'Tabassé', 'Pied de biche' },
    [joaat('WEAPON_BOTTLE')] = { 'Stabbed', 'Bouteille cassée' },
    [joaat('WEAPON_DAGGER')] = { 'Stabbed', 'Dague' },
    [joaat('WEAPON_HATCHET')] = { 'Stabbed', 'Hachette' },
    [joaat('WEAPON_MACHETE')] = { 'Stabbed', 'Machette' },
    [joaat('WEAPON_FLASHLIGHT')] = { 'Tabassé', 'Lampe torche' },
    [joaat('WEAPON_SWITCHBLADE')] = { 'Stabbed', 'Couteau à cran d\'arrêt' },
    [joaat('WEAPON_POOLCUE')] = { 'Tabassé', 'Queue de billard' },
    [joaat('WEAPON_PIPEWRENCH')] = { 'Tabassé', 'Clé à molette' },
    [joaat('WEAPON_STONE_HATCHET')] = { 'Stabbed', 'Hache en pierre' },

    -- Armes à feu
    [joaat('WEAPON_PISTOL')] = { 'Pistolled', 'Pistolet' },
    [joaat('WEAPON_PISTOL_MK2')] = { 'Pistolled', 'Pistolet MK2' },
    [joaat('WEAPON_COMBATPISTOL')] = { 'Pistolled', 'Pistolet de combat' },
    [joaat('WEAPON_APPISTOL')] = { 'Pistolled', 'Pistolet automatique' },
    [joaat('WEAPON_STUNGUN')] = { 'Electrocuté', 'Taser' },
    [joaat('WEAPON_PISTOL50')] = { 'Pistolled', 'Pistolet .50' },
    [joaat('WEAPON_SNSPISTOL')] = { 'Pistolled', 'Pistolet SNS' },
    [joaat('WEAPON_SNSPISTOL_MK2')] = { 'Pistolled', 'Pistolet SNS MK2' },
    [joaat('WEAPON_HEAVYPISTOL')] = { 'Pistolled', 'Pistolet lourd' },
    [joaat('WEAPON_VINTAGEPISTOL')] = { 'Pistolled', 'Pistolet vintage' },
    [joaat('WEAPON_FLAREGUN')] = { 'Brulé', 'Pistolet de détresse' },
    [joaat('WEAPON_MARKSMANPISTOL')] = { 'Pistolled', 'Pistolet marksman' },
    [joaat('WEAPON_REVOLVER')] = { 'Pistolled', 'Revolver' },
    [joaat('WEAPON_REVOLVER_MK2')] = { 'Pistolled', 'Revolver MK2' },
    [joaat('WEAPON_DOUBLEACTION')] = { 'Pistolled', 'Revolver à double action' },
    [joaat('WEAPON_RAYPISTOL')] = { 'Pistolled', 'Pistolet Up-n-Atomizer' },

    -- Mitraillettes
    [joaat('WEAPON_MICROSMG')] = { 'Riddled', 'Micro SMG' },
    [joaat('WEAPON_SMG')] = { 'Riddled', 'SMG' },
    [joaat('WEAPON_SMG_MK2')] = { 'Riddled', 'SMG MK2' },
    [joaat('WEAPON_ASSAULTSMG')] = { 'Riddled', 'SMG d\'assaut' },
    [joaat('WEAPON_COMBATPDW')] = { 'Riddled', 'PDW de combat' },
    [joaat('WEAPON_MACHINEPISTOL')] = { 'Riddled', 'Pistolet mitrailleur' },
    [joaat('WEAPON_MINISMG')] = { 'Riddled', 'Mini SMG' },

    -- Fusils
    [joaat('WEAPON_ASSAULTRIFLE')] = { 'Rifled', 'Fusil d\'assaut' },
    [joaat('WEAPON_ASSAULTRIFLE_MK2')] = { 'Rifled', 'Fusil d\'assaut MK2' },
    [joaat('WEAPON_CARBINERIFLE')] = { 'Rifled', 'Carabine' },
    [joaat('WEAPON_CARBINERIFLE_MK2')] = { 'Rifled', 'Carabine MK2' },
    [joaat('WEAPON_ADVANCEDRIFLE')] = { 'Rifled', 'Fusil avancé' },
    [joaat('WEAPON_SPECIALCARBINE')] = { 'Rifled', 'Carabine spéciale' },
    [joaat('WEAPON_SPECIALCARBINE_MK2')] = { 'Rifled', 'Carabine spéciale MK2' },
    [joaat('WEAPON_BULLPUPRIFLE')] = { 'Rifled', 'Fusil bullpup' },
    [joaat('WEAPON_BULLPUPRIFLE_MK2')] = { 'Rifled', 'Fusil bullpup MK2' },
    [joaat('WEAPON_COMPACTRIFLE')] = { 'Rifled', 'Fusil compact' },
    [joaat('WEAPON_MILITARYRIFLE')] = { 'Rifled', 'Fusil militaire' },
    [joaat('WEAPON_HEAVYRIFLE')] = { 'Rifled', 'Fusil lourd' },

    -- Fusils à pompe
    [joaat('WEAPON_PUMPSHOTGUN')] = { 'Pulverized', 'Fusil à pompe' },
    [joaat('WEAPON_PUMPSHOTGUN_MK2')] = { 'Pulverized', 'Fusil à pompe MK2' },
    [joaat('WEAPON_SAWNOFFSHOTGUN')] = { 'Pulverized', 'Fusil à canon scié' },
    [joaat('WEAPON_ASSAULTSHOTGUN')] = { 'Pulverized', 'Fusil d\'assaut' },
    [joaat('WEAPON_BULLPUPSHOTGUN')] = { 'Pulverized', 'Fusil bullpup' },
    [joaat('WEAPON_MUSKET')] = { 'Pulverized', 'Mousquet' },
    [joaat('WEAPON_HEAVYSHOTGUN')] = { 'Pulverized', 'Fusil à pompe lourd' },
    [joaat('WEAPON_DBSHOTGUN')] = { 'Pulverized', 'Fusil à double canon' },
    [joaat('WEAPON_AUTOSHOTGUN')] = { 'Pulverized', 'Fusil à pompe automatique' },

    -- Armes de précision
    [joaat('WEAPON_SNIPERRIFLE')] = { 'Sniped', 'Fusil de précision' },
    [joaat('WEAPON_HEAVYSNIPER')] = { 'Sniped', 'Fusil de précision lourd' },
    [joaat('WEAPON_HEAVYSNIPER_MK2')] = { 'Sniped', 'Fusil de précision lourd MK2' },
    [joaat('WEAPON_MARKSMANRIFLE')] = { 'Sniped', 'Fusil marksman' },
    [joaat('WEAPON_MARKSMANRIFLE_MK2')] = { 'Sniped', 'Fusil marksman MK2' },

    -- Armes lourdes
    [joaat('WEAPON_GRENADELAUNCHER')] = { 'Obliterated', 'Lance-grenades' },
    [joaat('WEAPON_GRENADELAUNCHER_SMOKE')] = { 'Obliterated', 'Lance-grenades fumigènes' },
    [joaat('WEAPON_RPG')] = { 'Obliterated', 'RPG' },
    [joaat('WEAPON_MINIGUN')] = { 'Obliterated', 'Minigun' },
    [joaat('WEAPON_FIREWORK')] = { 'Obliterated', 'Lanceur de feux d\'artifice' },
    [joaat('WEAPON_RAILGUN')] = { 'Obliterated', 'Railgun' },
    [joaat('WEAPON_HOMINGLAUNCHER')] = { 'Obliterated', 'Lance-missiles guidés' },
    [joaat('WEAPON_COMPACTLAUNCHER')] = { 'Obliterated', 'Lance-grenades compact' },
    [joaat('WEAPON_RAYMINIGUN')] = { 'Obliterated', 'Minigun Widowmaker' },

    -- Explosifs
    [joaat('WEAPON_GRENADE')] = { 'Bombed', 'Grenade' },
    [joaat('WEAPON_STICKYBOMB')] = { 'Bombed', 'Bombe collante' },
    [joaat('WEAPON_PROXMINE')] = { 'Bombed', 'Mine de proximité' },
    [joaat('WEAPON_PIPEBOMB')] = { 'Bombed', 'Bombe artisanale' },
    [joaat('WEAPON_SMOKEGRENADE')] = { 'Bombed', 'Grenade fumigène' },
    [joaat('WEAPON_BZGAS')] = { 'Bombed', 'Grenade à gaz BZ' },
    [joaat('WEAPON_MOLOTOV')] = { 'Brulé', 'Cocktail Molotov' },
    [joaat('WEAPON_FIREEXTINGUISHER')] = { 'Étouffé', 'Extincteur' },
    [joaat('WEAPON_PETROLCAN')] = { 'Brulé', 'Jerrican' },
    [joaat('WEAPON_FLARE')] = { 'Brulé', 'Fusée éclairante' },
    [joaat('WEAPON_SNOWBALL')] = { 'Tabassé', 'Boule de neige' },
    [joaat('WEAPON_BALL')] = { 'Tabassé', 'Balle' },

    -- Armes spéciales
    [joaat('WEAPON_KNIFE')] = { 'Stabbed', 'Couteau' },
    [joaat('WEAPON_NIGHTVISION')] = { 'Tabassé', 'Lunettes de vision nocturne' },
    [joaat('WEAPON_PARACHUTE')] = { 'Chute', 'Parachute' },
    [joaat('WEAPON_GARBAGEBAG')] = { 'Étouffé', 'Sac poubelle' },

    [joaat('WEAPON_PDGLOCK17')] = { 'Pistolled', 'Glock 17 PD' },
    [joaat('WEAPON_GLOCK20')] = { 'Pistolled', 'Glock 20' },
    [joaat('WEAPON_SWMP9L')] = { 'Pistolled', 'Smith & Wesson M&P9' },
    [joaat('WEAPON_SIG_SAUCER')] = { 'Pistolled', 'Sig Sauer' },
    [joaat('WEAPON_HK416')] = { 'Rifled', 'HK416' },
    [joaat('WEAPON_KS1')] = { 'Rifled', 'KAC KS-1' },
    [joaat('WEAPON_M4A1CD')] = { 'Rifled', 'M4A1' },
    [joaat('WEAPON_AR15')] = { 'Rifled', 'AR-15 PD' },
    [joaat('WEAPON_M870')] = { 'Pulverized', 'M870' },
    [joaat('WEAPON_PDPT700')] = { 'Sniped', 'Remington M700' },
    [joaat('WEAPON_gtaserx')] = { 'Electrocuté', 'Taser X vert' },
    [joaat('WEAPON_taserx')] = { 'Electrocuté', 'Taser X jaune' },
    [joaat('WEAPON_ASPBATON')] = { 'Tabassé', 'Matraque ASP' },
    [joaat('WEAPON_LESSLAUNCHER')] = { 'Obliterated', 'Lanceur 40mm non-letal' },
    [joaat('WEAPON_BEANBAG')] = { 'Pulverized', 'Beanbag' },
    [joaat('WEAPON_BEANBAG2')] = { 'Pulverized', 'Beanbag orange' },
    [joaat('WEAPON_PISTOLXM3')] = { 'Pistolled', 'Pistolet XM3' },
    [joaat('WEAPON_PEPPERSPRAY')] = { 'Tabassé', 'Spray au poivre' },

    -- Armes de véhicules
    [joaat('VEHICLE_WEAPON_ROTORS')] = { 'Découpé', 'Rotors d\'hélicoptère' },
    [joaat('VEHICLE_WEAPON_TANK')] = { 'Obliterated', 'Canon de char' },
    [joaat('VEHICLE_WEAPON_SPACE_ROCKET')] = { 'Obliterated', 'Roquette spatiale' },
    [joaat('VEHICLE_WEAPON_PLAYER_LASER')] = { 'Obliterated', 'Laser' },
    [joaat('VEHICLE_WEAPON_PLAYER_BUZZARD')] = { 'Obliterated', 'Mitrailleuse Buzzard' },
    [joaat('VEHICLE_WEAPON_PLAYER_LAZER')] = { 'Obliterated', 'Canon Lazer' },

    -- Causes spéciales
    [joaat('WEAPON_RAMMED_BY_CAR')] = { 'Carkill', 'Renversé par un véhicule' },
    [joaat('WEAPON_RUN_OVER_BY_CAR')] = { 'Carkill', 'Écrasé par un véhicule' },
    [joaat('WEAPON_EXPLOSION')] = { 'Bombed', 'Explosion' },
    [joaat('WEAPON_FALL')] = { 'Chute', 'Chute mortelle' },
    [joaat('WEAPON_DROWNING')] = { 'Noyade', 'Noyade' },
    [joaat('WEAPON_DROWNING_IN_VEHICLE')] = { 'Noyade', 'Noyade dans un véhicule' },
    [joaat('WEAPON_BLEEDING')] = { 'Saignement', 'Hémorragie' },
    [joaat('WEAPON_ELECTRIC_FENCE')] = { 'Electrocuté', 'Clôture électrique' },
    [joaat('WEAPON_BARBED_WIRE')] = { 'Blessé', 'Fil barbelé' },
    [joaat('WEAPON_FIRE')] = { 'Brulé', 'Feu' },
    [joaat('WEAPON_ANIMAL')] = { 'Animal', 'Attaque d\'animal' },
    [joaat('WEAPON_COUGAR')] = { 'Animal', 'Cougar' },
    [joaat('WEAPON_BARREL')] = { 'Écrasé', 'Baril' },
}
Death.GetDeathType = { "Non-Identifiée", "Dégâts de mêlée", "Blessure par balle", "Chute", "Dégâts explosifs", "Feu",
                       "Chute", "Électrique", "Écorchure", "Gaz", "Gaz", "Eau" }

-- Fall tracking thread - monitors player falling state for better fall death detection
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        if playerPed and DoesEntityExist(playerPed) and not Death.isDead then
            local isFalling = IsPedFalling(playerPed)
            local velocity = GetEntityVelocity(playerPed)
            local verticalSpeed = -velocity.z -- Positive when falling down

            if isFalling and verticalSpeed > 5.0 then
                Death.wasFalling = true
                Death.lastFallVelocity = verticalSpeed
            elseif not isFalling and IsEntityInAir(playerPed) then
                -- Still in air but not in falling animation
                if verticalSpeed > 5.0 then
                    Death.wasFalling = true
                    Death.lastFallVelocity = verticalSpeed
                end
            end

            -- Reset fall state if player is on ground and alive
            if not isFalling and not IsEntityInAir(playerPed) and GetEntityHealth(playerPed) > 0 then
                Death.wasFalling = false
                Death.lastFallVelocity = 0.0
            end
        end
        Wait(100)
    end
end)


function Death:CreateDeathClone(coords, heading)
    self:DeleteDeathClone()
    local playerPed = PlayerPedId()

    -- Pre-charger l'anim dict avant de creer le clone
    local animDict = "dead"
    local animName = "dead_a"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    local clone = ClonePed(playerPed, true, true, true)
    if not DoesEntityExist(clone) then return end

    ClearPedBloodDamage(clone)
    ResetPedVisibleDamage(clone)
    SetEntityVelocity(clone, 0.0, 0.0, 0.0)

    SetEntityInvincible(clone, true)
    SetBlockingOfNonTemporaryEvents(clone, true)
    SetPedKeepTask(clone, true)
    SetPedCanRagdoll(clone, false)

    SetEntityCoordsNoOffset(clone, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(clone, heading)

    -- Pas de freeze avant l'anim, blend-in rapide (50.0 comme ars_ambulancejob)
    TaskPlayAnim(clone, animDict, animName, 50.0, -8.0, -1, 1, 0, false, false, false)
    RemoveAnimDict(animDict)

    -- Freeze une fois que le clone est allonge
    CreateThread(function()
        Wait(500)
        if DoesEntityExist(clone) then
            FreezeEntityPosition(clone, true)
        end
    end)

    Entity(clone).state:set("deathCloneOf", GetPlayerServerId(PlayerId()), true)
    self.clonePed = clone
    if NetworkGetEntityIsNetworked(clone) then
        self.clonePedNetId = NetworkGetNetworkIdFromEntity(clone)
    end
    LocalPlayer.state:set("deathCloneNetId", self.clonePedNetId, true)
end

function Death:DeleteDeathClone()
    local netId = self.clonePedNetId
    self.clonePed = nil
    self.clonePedNetId = nil
    LocalPlayer.state:set("deathCloneNetId", nil, true)

    if netId then
        TriggerServerEvent("death:deleteClone", netId)
    end
end

function Death:GetValueWithTable(value, table, number)
    if not value or not table or type(value) ~= "table" then
        return
    end

    for k, v in pairs(value) do
        if number and v[number] == table or v == table then
            return true, k
        end
    end
end

function Death:GetAllCauseOfDeath()
    local exist, lastBone = GetPedLastDamageBone(VFW.PlayerData.ped)
    local causeHash, what_cause, timeDeath = GetPedCauseOfDeath(VFW.PlayerData.ped), GetPedSourceOfDeath(VFW.PlayerData.ped),
    GetPedTimeOfDeath(VFW.PlayerData.ped)

    if (causeHash == 0 or causeHash == nil) and Death.lastDamageHash ~= 0 and (GetGameTimer() - Death.lastDamageTime) < 10000 then
        causeHash = Death.lastDamageHash
    end

    if IsEntityAPed(what_cause) then
        what_cause = "Traces de combat"
    elseif IsEntityAVehicle(what_cause) then
        what_cause = "Écrasé par un véhicule"
    elseif IsEntityAnObject(what_cause) then
        what_cause = "Semble s'être pris un objet"
    end

    what_cause = type(what_cause) == "string" and what_cause or "Non-Identifiée"

    local cause = nil
    local isFallDeath = false

    if VFW.StatusDamageSource then
        local src = VFW.StatusDamageSource
        if src == "hunger" then
            cause = "Affamé"
            what_cause = "Affamé"
        elseif src == "thirst" then
            cause = "Déshydraté"
            what_cause = "Déshydraté"
        elseif src == "both" then
            cause = "Affamé et Déshydraté"
            what_cause = "Affamé et Déshydraté"
        end
    end

    if not cause then
        local WEAPON_FALL_HASH = joaat('WEAPON_FALL')
        if causeHash == WEAPON_FALL_HASH then
            cause = "Chute"
            isFallDeath = true
        elseif causeHash and Death.deatCause[causeHash] then
            cause = Death.deatCause[causeHash][1]
        elseif IsWeaponValid(causeHash) then
            local damageType = GetWeaponDamageType(causeHash)
            cause = Death.GetDeathType[damageType + 1] or "Non-Identifiée"
        elseif IsModelInCdimage(causeHash) then
            cause = "Véhicule"
        end
    end

    if (not cause or cause == "Non-Identifiée" or cause == "Mêlée") and VFW.DeathOverrideCause then
        if VFW.DeathOverrideCause == "staff_kill" then
            cause = "Kill par un staff"
            what_cause = "Kill par un staff"
        elseif VFW.DeathOverrideCause == "suicide" then
            cause = "Tentative de suicide"
            what_cause = "Tentative de suicide"
        end
    end

    if (not cause or cause == "Non-Identifiée" or cause == "Mêlée") and Death.wasFalling and Death.lastFallVelocity > 15.0 then
        cause = "Chute"
        isFallDeath = true
        what_cause = "Chute mortelle"
    end

    local ped = VFW.PlayerData.ped
    if not cause or cause == "Non-Identifiée" or cause == "Mêlée" then
        if IsEntityInWater(ped) or IsPedSwimmingUnderWater(ped) then
            cause = "Noyade"
            what_cause = "Noyade"
        elseif IsEntityOnFire(ped) then
            cause = "Brulé"
            what_cause = "Feu"
        elseif GetPedConfigFlag(ped, 60, true) then
            cause = "Chute"
            isFallDeath = true
            what_cause = "Chute mortelle"
        elseif IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if IsEntityInWater(veh) then
                cause = "Noyade"
                what_cause = "Noyade dans un véhicule"
            elseif IsEntityOnFire(veh) then
                cause = "Brulé"
                what_cause = "Explosion de véhicule"
            end
        end
    end

    cause = type(cause) == "string" and cause or "Mêlée"
    local boneName = "Dos"

    -- For fall deaths, set a more appropriate body part
    if isFallDeath then
        boneName = "Corps entier"
    end

    if exist and lastBone then
        for k, v in pairs(Death.GetBonesType) do
            if self:GetValueWithTable(v, lastBone) then
                boneName = k
                break
            end
        end
    end

    return timeDeath, what_cause, cause, boneName
end

function Death:Died()
    self:ShowDeathScreen()
    VFW.Nui.HudVisible(false)
    VFW.Nui.NotificationsVisible(true)

    -- Keep staff HUD visible during death
    if IsStaffHUDVisible and IsStaffHUDVisible() then
        ToggleStaffHUD(true)
    end
end

-- List of controls to disable when dead (all except chat 245 and F10 via keybind)
Death.controlsToDisable = {
    1, 2,           -- Look
    21, 22,         -- Sprint, Jump
    23,             -- Enter vehicle
    24, 25,         -- Attack, Aim
    30, 31, 32, 33, 34, 35, -- Movement (WASD)
    36,             -- Stealth
    37,             -- Weapon wheel
    38,             -- E (interact)
    44, 45,         -- Cover, Reload
    47,             -- Weapon
    58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, -- Numpad (phone shortcuts)
    73,             -- X
    74,             -- H
    75,             -- Exit vehicle
    140, 141, 142, 143, -- Melee
    157, 158, 159, 160, 161, 162, 163, 164, 165, -- Vehicle controls
    170,            -- Phone
    288, 289,       -- Phone up/down
    -- 245 is Chat - NOT disabled
}

function Death:StartControlBlocker()
    if self.controlBlockerRunning then
        return -- Already running
    end

    self.controlBlockerRunning = true

    -- Mort = ne peut pas parler mais peut entendre.
    -- On utilise disableProximity (pma-voice) qui clear les voice targets toutes les 200ms
    -- => transmission bloquée mais MumbleAddVoiceChannelListen reste actif => on entend
    -- isDead bloque aussi la radio via pma-voice/radio.lua
    LocalPlayer.state:set('disableProximity', true, false)
    LocalPlayer.state:set('isDead', true, false)

    CreateThread(function()
        while self.isDead do
            if not self.gettingRevived then
                for _, control in ipairs(self.controlsToDisable) do
                    DisableControlAction(0, control, true)
                end

                DisablePlayerFiring(PlayerId(), true)
            end

            Wait(0)
        end

        LocalPlayer.state:set('disableProximity', false, false)
        LocalPlayer.state:set('isDead', false, false)
        self.controlBlockerRunning = false
    end)
end

function Death:ShowDeathScreen()
    self.isDead = true
    DisplayRadar(false)
    TriggerEvent("statushud:hide")
    TriggerScreenblurFadeIn(1000)

    -- Start control blocking (disable all actions except F10 and Chat)
    self:StartControlBlocker()

    -- Calculer la cause de mort immediatement pour affichage instantane
    local _, _, cause, _ = self:GetAllCauseOfDeath()
    cause = cause or "Inconnue"
    self.currentDeathCause = cause

    local initialTimer = self:GetRespawnTime()
    self.secToWait = initialTimer
    self.secLeft = initialTimer

    -- Décompte côté Lua pour garder secLeft synchronisé
    CreateThread(function()
        while self.isDead and self.secLeft > 0 do
            Wait(1000)
            if self.isDead and self.secLeft > 0 then
                self.secLeft = self.secLeft - 1
            end
        end
    end)

    local playerId = GetPlayerServerId(PlayerId())
    VFW.Nui.deathScreen(true, initialTimer, false, cause, playerId)

    TriggerServerEvent("death:getEMSCount")
end

RegisterNUICallback("nui:deathscreen:action", function(data, cb)
    if data.action == "DeathscreenRespawn" and Death.secLeft <= 0 then
        TriggerEvent("nui:deathscreen:hide")
        TriggerServerEvent("deathscreen:respawnPlayer")
    elseif data.action == "DeathscreenCallEmergency" then
        TriggerServerEvent("deathscreen:callEmergency")
    end

    cb("ok")
end)


AddEventHandler("vfw:onPlayerDeath", function()
    Death.isDead = true
    VFW.PlayerData.dead = true

    local deathPed = PlayerPedId()
    SetPedCanRagdoll(deathPed, false)

    CreateThread(function()
        -- Attendre que le ragdoll s'immobilise avant de capturer la position finale.
        -- Sinon, en cas de chute, la position capturée est intermédiaire et le corps
        -- continue à glisser → desync visible entre les observateurs.
        local inVehicle = GetVehiclePedIsIn(deathPed, false) ~= 0
        if not inVehicle then
            local elapsed = 0
            while elapsed < 3000 do
                if not Death.isDead then return end
                local v = GetEntityVelocity(deathPed)
                if (v.x * v.x + v.y * v.y + v.z * v.z) < 0.25 then break end
                Wait(100)
                elapsed = elapsed + 100
            end
        end

        local frozenCoords = GetEntityCoords(deathPed)
        local frozenHeading = GetEntityHeading(deathPed)
        SetEntityVelocity(deathPed, 0.0, 0.0, 0.0)

        Wait(2000)

        if not Death.isDead or (VFW.IsBeingCarried and VFW.IsBeingCarried()) then
            return
        end

        local playerPed = PlayerPedId()
        local coords = frozenCoords
        local heading = frozenHeading

        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 3.0, false)
        if found and math.abs(groundZ - coords.z) <= 3.0 then
            coords = vector3(coords.x, coords.y, groundZ)
        end

        Death.deathCoords = coords
        Death.deathHeading = heading

        -- Approche ars_ambulancejob : resurrect le vrai ped et jouer l'anim de mort dessus
        local animDict = "dead"
        local animName = "dead_a"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do Wait(10) end

        -- Sauvegarder le véhicule et le siège avant resurrect (qui éjecte le ped)
        local deathVehicle = GetVehiclePedIsIn(playerPed, false)
        local deathSeat = nil
        if deathVehicle and deathVehicle ~= 0 then
            for s = -1, GetVehicleMaxNumberOfPassengers(deathVehicle) - 1 do
                if GetPedInVehicleSeat(deathVehicle, s) == playerPed then
                    deathSeat = s
                    break
                end
            end
        else
            deathVehicle = nil
        end

        -- Resurrect le ped a la position de mort
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        playerPed = PlayerPedId()

        -- Invincible + ignore par les NPCs
        SetEntityInvincible(playerPed, true)
        SetEntityHealth(playerPed, 100)
        SetEveryoneIgnorePlayer(PlayerId(), true)

        -- Si dans un vehicule, remettre dedans
        if deathVehicle and DoesEntityExist(deathVehicle) then
            SetPedIntoVehicle(playerPed, deathVehicle, deathSeat or -1)
        end

        -- Boucle d'animation de mort : rejoue l'anim si elle est interrompue
        CreateThread(function()
            while Death.isDead do
                if not Death.gettingRevived and not (VFW.IsBeingCarried and VFW.IsBeingCarried()) then
                    local ped = PlayerPedId()
                    local anim
                    if deathVehicle and DoesEntityExist(deathVehicle) and GetVehiclePedIsIn(ped, false) == deathVehicle then
                        anim = { dict = "veh@low@front_ps@idle_duck", clip = "sit" }
                    else
                        anim = { dict = animDict, clip = animName }
                    end

                    if not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
                        if anim.dict ~= animDict then
                            RequestAnimDict(anim.dict)
                            while not HasAnimDictLoaded(anim.dict) do Wait(10) end
                        end
                        TaskPlayAnim(ped, anim.dict, anim.clip, 50.0, 8.0, -1, 1, 1.0, false, false, false)
                    end

                    DisableFirstPersonCamThisFrame()
                    Wait(0)
                else
                    Wait(500)
                end
            end
        end)
    end)

    Death:ShowDeathScreen()

    -- Keep staff HUD visible during death
    if IsStaffHUDVisible and IsStaffHUDVisible() then
        ToggleStaffHUD(true)
    end
end)


RegisterNetEvent("vfw:revivePlayer", function()
    Death.gettingRevived = true
    local playerPed = PlayerPedId()

    local wasResurrected = false
    if IsEntityDead(playerPed) or IsPedDeadOrDying(playerPed, true) then
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        playerPed = PlayerPedId()
        wasResurrected = true
    end

    SetEntityInvincible(playerPed, false)
    SetEveryoneIgnorePlayer(PlayerId(), false)
    ClearPedBloodDamage(playerPed)
    ClearPedTasksImmediately(playerPed)

    SetEntityMaxHealth(playerPed, 200)
    SetEntityHealth(playerPed, 200)
    if wasResurrected then
        Citizen.CreateThread(function()
            Citizen.Wait(500)
            local ped = PlayerPedId()
            SetEntityMaxHealth(ped, 200)
            if GetEntityHealth(ped) < 200 then
                SetEntityHealth(ped, 200)
            end
        end)
    end

    if isKnockedOut then
        isKnockedOut = false
        LocalPlayer.state:set("isKnockedOut", false, false)
        DisplayRadar(true)
    end

    ClearKONotifications()

    VFW.ReviveSelf()
    VFW.Nui.Focus(false, false)

    TriggerServerEvent("vfw:onPlayerRevived")
end)

AddEventHandler("chat:closed", function()
    if Death.isDead then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
    end
end)

-- Le serveur (core:staff:treatZone) a déjà écrit health=200 dans les métadonnées
-- du joueur soigné ; seul le ped local reste à remettre à niveau.
RegisterNetEvent("vfw:healPlayer", function()
    local playerPed = PlayerPedId()
    SetEntityMaxHealth(playerPed, 200)
    SetEntityHealth(playerPed, 200)
end)

RegisterNetEvent("vfw:setArmor", function(amount)
    local playerPed = PlayerPedId()
    local value = tonumber(amount)
    if not value then value = 100 end
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    SetPedArmour(playerPed, math.floor(value))
end)

--- .ReviveSelf
function VFW.ReviveSelf()
    Death.gettingRevived = false
    Death.isDead = false;
    VFW.PlayerData.dead = false;
    VFW.Nui.deathScreen(false);
    TriggerScreenblurFadeOut(800)
    VFW.Nui.HudVisible(true);
    -- Restaurer la voix (proximité + radio)
    LocalPlayer.state:set('disableProximity', false, false)
    LocalPlayer.state:set('isDead', false, false)

    VFW.DeathOverrideCause = nil
    VFW.DeathOverrideStaffSource = nil
    VFW.StatusDamageSource = nil

    -- Re-sync staff HUD after revive so it persists through multiple deaths
    if IsStaffHUDVisible and IsStaffHUDVisible() then
        ToggleStaffHUD(true)
    end

    -- Reset alert cooldown so player can call again if they die shortly after
    -- Incrementing emsCallSession invalidates any running Wait(120000) thread
    emsCallSession = emsCallSession + 1
    cooldownems = false
    hasCalledEmsNoResponse = false

    -- Show StatusHUD again when player is revived/alive
    TriggerEvent("statushud:show")
end

RegisterNUICallback("nui:deathscreen:respawn", function()
    if not Death.isDead then return end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    -- Demande au serveur les coords du spawn (hôpital le plus proche en DB)
    TriggerServerEvent("deathscreen:respawnPlayer", { x = coords.x, y = coords.y, z = coords.z })
end)

RegisterNetEvent("deathscreen:doRespawn")
AddEventHandler("deathscreen:doRespawn", function(spawnCoords)
    if not Death.isDead then return end

    Death.gettingRevived = true

    local playerPed = PlayerPedId()
    local respawnHealth = (Death.emsCount == 0) and 200 or 100

    -- Resurrect si le ped est encore en etat mort natif
    if IsEntityDead(playerPed) or IsPedDeadOrDying(playerPed, true) then
        NetworkResurrectLocalPlayer(spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.h or 0.0, true, false)
        playerPed = PlayerPedId()
    end

    SetEntityInvincible(playerPed, false)
    SetEveryoneIgnorePlayer(PlayerId(), false)
    ClearPedBloodDamage(playerPed)
    ClearPedTasksImmediately(playerPed)
    SetEntityCoords(playerPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
    SetEntityHeading(playerPed, spawnCoords.h or 0.0)
    SetEntityMaxHealth(playerPed, 200)
    SetEntityHealth(playerPed, respawnHealth)

    -- Reset KO si actif (melee KO -> mort -> respawn hopital)
    if isKnockedOut then
        isKnockedOut = false
        LocalPlayer.state:set("isKnockedOut", false, false)
    end

    ClearKONotifications()
    VFW.ReviveSelf()
    VFW.Nui.Focus(false, false)
    TriggerServerEvent("core:server:onPlayerRespawn", Death.emsCount)
end)




RegisterNUICallback("nui:deathscreen:send-report", function(data)
    ExecuteCommand("report " .. data.report)
end)

RegisterNUICallback("nui:deathscreen:callemergency", function()
    if not cooldownems then
        cooldownems = true
        emsCallSession = emsCallSession + 1
        local mySession = emsCallSession

        -- Check if there are EMS online
        if Death.emsCount == 0 then
            hasCalledEmsNoResponse = true

            -- Determine reduced time based on VIP tier (configurable via builder VIP)
            local targetTime = TriggerServerCallback("vip:getRespawnTime")

            if targetTime and targetTime < 600 and Death.secLeft > targetTime then
                Death.secLeft = targetTime

                local minutes = math.floor(targetTime / 60)
                -- Libellé selon la mentalité serveur (uiModel du panel) : FR = "secours", US = "EMS".
                VFW.ShowNotification({
                    type = 'JAUNE',
                    content = (MENTA_SERVER == "FR" and "Aucune unité de secours en service." or "Aucun EMS en service.")
                        .. " Temps réduit à " .. minutes .. " minutes (VIP)."
                })

                VFW.Nui.updateDeathScreen({
                    secToWait = Death.secToWait,
                    secLeft = Death.secLeft
                })
            else
                VFW.ShowNotification({
                    type = 'JAUNE',
                    content = MENTA_SERVER == "FR" and "Aucune unité de secours en service." or "Aucun EMS en service."
                })
            end
        else
            -- EMS online - send call with street name
            local coords = GetEntityCoords(VFW.PlayerData.ped)
            local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local streetName = GetStreetNameFromHashKey(streetHash)

            local msg = "Patient dans le coma"
            if streetName and streetName ~= "" then
                msg = msg .. ", " .. streetName
            end

            VFW.ShowNotification({
                type = 'JAUNE',
                content = MENTA_SERVER == "FR" and "Vous avez envoyé un appel aux secours." or "Vous avez envoyé un appel aux SAMS."
            })

            TriggerServerEvent('sn_sams:newCallAlert', "mort", coords, msg)
        end

        Wait(120000)
        if mySession == emsCallSession then
            cooldownems = false
        end
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous avez déjà envoyé un appel"
        })
    end
end)

local meleeWeapon = {}
for _, hash in ipairs({
    joaat("weapon_flashlight"),
    joaat("weapon_bat"),
    joaat("weapon_bottle"),
    joaat("weapon_crowbar"),
    joaat("weapon_golfclub"),
    joaat("weapon_hatchet"),
    joaat("weapon_knuckle"),
    joaat("weapon_machete"),
    joaat("weapon_nightstick"),
    joaat("weapon_wrench"),
    joaat("weapon_knife"),
    joaat("weapon_switchblade"),
    joaat("weapon_battleaxe"),
    joaat("weapon_poolcue"),
    joaat("weapon_molotov"),
    joaat("weapon_snowball"),
    joaat("weapon_ball"),
    joaat("weapon_petrolcan"),
    joaat("weapon_fireextinguisher"),
    joaat("gadget_parachute"),
    joaat("weapon_dagger"),
    joaat("weapon_canette"),
    joaat("weapon_bouteille"),
    joaat("weapon_pelle"),
    joaat("weapon_pickaxe"),
    joaat("weapon_sledgehammer"),
    joaat("weapon_katana"),
    joaat("weapon_beambag"),
    joaat("weapon_unarmed"),
}) do
    meleeWeapon[hash] = true
end

local weaponHashToName = {}
for _, w in ipairs(Config.Weapons) do
    weaponHashToName[joaat(w.name)] = w.name:upper()
end
-- Fallback pour toute arme présente dans meleeWeapon[] mais absente de Config.Weapons
-- (ex: WEAPON_UNARMED, WEAPON_MOLOTOV, etc.) - sans ça leur config DB est ignorée
local meleeWeaponNames = {
    [joaat("weapon_unarmed")] = "WEAPON_UNARMED",
    [joaat("weapon_snowball")] = "WEAPON_SNOWBALL",
    [joaat("weapon_ball")] = "WEAPON_BALL",
    [joaat("weapon_petrolcan")] = "WEAPON_PETROLCAN",
    [joaat("weapon_fireextinguisher")] = "WEAPON_FIREEXTINGUISHER",
    [joaat("gadget_parachute")] = "GADGET_PARACHUTE",
}
for hash, name in pairs(meleeWeaponNames) do
    if not weaponHashToName[hash] then
        weaponHashToName[hash] = name
    end
end

local meleeHitCounters = {}
local meleeHitTimers = {}

-- Track HP entre les hits pour calculer les vrais dégâts (entityDamaged arrive après le moteur GTA)
local lastTrackedHP = 0
CreateThread(function()
    while true do
        lastTrackedHP = GetEntityHealth(PlayerPedId())
        Wait(200)
    end
end)

--- Build positional context (street, zone, vehicle) for a ped at given coords
---@param ped number|nil Ped entity (may be 0)
---@param coords vector3
---@return table
local function BuildDeathContext(ped, coords)
    local ctx = {}

    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = streetHash ~= 0 and GetStreetNameFromHashKey(streetHash) or nil
    local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil
    local zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

    if street and street ~= "" then ctx.street = street end
    if crossing and crossing ~= "" and crossing ~= street then ctx.crossing = crossing end
    if zone and zone ~= "" and zone ~= "NULL" then ctx.zone = zone end

    if ped and ped ~= 0 and DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then
            local label = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
            if label and label ~= "" and label ~= "CARNOTFOUND" then
                ctx.vehicle = label
            end
        end
    end

    return ctx
end

--- PlayerKilledByPlayer
---@param killerServerId number|string
---@param killerClientId number|string
---@param killerWeapon string Weapon name
local function PlayerKilledByPlayer(killerServerId, killerClientId, killerWeapon)
    local victimPed = VFW.PlayerData.ped
    local killerPed = GetPlayerPed(killerClientId)
    local victimCoords = GetEntityCoords(victimPed)
    local killerCoords = GetEntityCoords(killerPed)
    local distance = #(vector3(victimCoords.x, victimCoords.y, victimCoords.z) - vector3(killerCoords.x, killerCoords.y, killerCoords.z))
    local rawCause = GetPedCauseOfDeath(victimPed)
    if (rawCause == 0 or rawCause == nil) and Death.lastDamageHash ~= 0 and (GetGameTimer() - Death.lastDamageTime) < 10000 then
        rawCause = Death.lastDamageHash
    end
    local causeDeathData = table.pack(Death:GetAllCauseOfDeath())
    local bonePart = causeDeathData[4]
    local data = {
        victimCoords = {
            x = math.round(victimCoords.x, 1),
            y = math.round(victimCoords.y, 1),
            z = math.round(victimCoords.z, 1)
        },
        killerCoords = {
            x = math.round(killerCoords.x, 1),
            y = math.round(killerCoords.y, 1),
            z = math.round(killerCoords.z, 1)
        },
        causeDeath = causeDeathData,
        killedByPlayer = true,
        deathCause = rawCause,
        computedCause = causeDeathData[3],
        distance = math.round(distance, 1),
        statusDamageSource = VFW.StatusDamageSource or nil,
        bonePart = bonePart,
        isHeadshot = bonePart == "Crâne",
        victimContext = BuildDeathContext(victimPed, victimCoords),
        killerContext = BuildDeathContext(killerPed, killerCoords),

        killerServerId = killerServerId,
        killerClientId = killerClientId
    }

    if VFW.DeathOverrideCause then
        data.deathOverride = VFW.DeathOverrideCause
        if VFW.DeathOverrideCause == "staff_kill" and VFW.DeathOverrideStaffSource then
            data.killerServerId = VFW.DeathOverrideStaffSource
        elseif VFW.DeathOverrideCause == "suicide" then
            data.killedByPlayer = false
            data.killerServerId = nil
            data.killerClientId = nil
        end
    end

    Death.wasFalling = false
    Death.lastFallVelocity = 0.0
    Death.lastDamageHash = 0
    Death.lastDamageTime = 0

    TriggerEvent("vfw:onPlayerDeath")
    TriggerServerEvent("vfw:onPlayerDeath", "killed", killerServerId)
    TriggerServerEvent("vfw:logs:onPlayerDeath", data)
end

--- PlayerKilled
local function PlayerKilled()
    local playerPed = VFW.PlayerData.ped
    local victimCoords = GetEntityCoords(playerPed)
    local rawCause = GetPedCauseOfDeath(playerPed)
    if (rawCause == 0 or rawCause == nil) and Death.lastDamageHash ~= 0 and (GetGameTimer() - Death.lastDamageTime) < 10000 then
        rawCause = Death.lastDamageHash
    end
    local causeDeathData = table.pack(Death:GetAllCauseOfDeath())
    local bonePart = causeDeathData[4]
    local data = {
        victimCoords = {
            x = math.round(victimCoords.x, 1),
            y = math.round(victimCoords.y, 1),
            z = math.round(victimCoords.z, 1)
        },

        killedByPlayer = false,
        deathCause = rawCause,
        computedCause = causeDeathData[3],
        causeDeath = causeDeathData,
        statusDamageSource = VFW.StatusDamageSource or nil,
        bonePart = bonePart,
        isHeadshot = bonePart == "Crâne",
        victimContext = BuildDeathContext(playerPed, victimCoords)
    }

    if VFW.DeathOverrideCause then
        data.deathOverride = VFW.DeathOverrideCause
        if VFW.DeathOverrideCause == "staff_kill" and VFW.DeathOverrideStaffSource then
            data.killedByPlayer = true
            data.killerServerId = VFW.DeathOverrideStaffSource
        end
    end

    Death.wasFalling = false
    Death.lastFallVelocity = 0.0
    Death.lastDamageHash = 0
    Death.lastDamageTime = 0

    TriggerEvent("vfw:onPlayerDeath")
    TriggerServerEvent("vfw:onPlayerDeath", "killed", data.killerServerId)
    TriggerServerEvent("vfw:logs:onPlayerDeath", data)
end

--- CEventNetworkEntityDamage
---@param victim any
---@param victimDied any
---@return any
local function CEventNetworkEntityDamage(victim, victimDied)
    if not IsPedAPlayer(victim) or Death.isDead then
        return
    end

    local player = PlayerId()
    local _, killerWeapon = NetworkGetEntityKillerOfPlayer(player)
    local playerPed = VFW.PlayerData.ped

    if victimDied and NetworkGetPlayerIndexFromPed(victim) == player and (IsPedDeadOrDying(victim, true) or IsPedFatallyInjured(victim)) then
        local killerEntity = GetPedSourceOfDeath(playerPed)
        local killerServerId = NetworkGetPlayerIndexFromPed(killerEntity)
        local rawHash = GetPedCauseOfDeath(playerPed)
        if (rawHash == 0 or rawHash == nil) and killerWeapon and killerWeapon ~= 0 then
            rawHash = killerWeapon
        end
        if (rawHash == 0 or rawHash == nil) and Death.lastDamageHash ~= 0 and (GetGameTimer() - Death.lastDamageTime) < 10000 then
            rawHash = Death.lastDamageHash
        end
        local DeathCause = Death.deatCause[rawHash]

        if killerEntity ~= playerPed and killerServerId > 0 then
            PlayerKilledByPlayer(GetPlayerServerId(killerServerId), killerServerId, killerWeapon)
        else
            if DeathCause and DeathCause[1] then
                local kPed = GetPedSourceOfDeath(playerPed)
                local kPlayer = NetworkGetPlayerIndexFromPed(kPed)

                if not kPlayer or kPlayer < 0 then
                    PlayerKilled()
                else
                    PlayerKilledByPlayer(GetPlayerServerId(kPlayer), kPlayer, DeathCause[2])
                end
            else
                PlayerKilled()
            end
        end
    end
end

local koRecoveryTimer = 0

---@param event any
---@param args any
AddEventHandler("gameEventTriggered", function(event, args)
    if event == "CEventNetworkEntityDamage" then
        if IsEntityAPed(args[1]) and IsPedAPlayer(args[1]) and args[1] == VFW.PlayerData.ped then
            local attacker = args[2]
            local playerPed = VFW.PlayerData.ped
            if attacker and DoesEntityExist(attacker) then
                if IsEntityAPed(attacker) and not IsPedAPlayer(attacker) and GetPedType(attacker) == 28 then
                    -- Animal (K9 ou faune) — PedType 28 = animal
                    Death.lastDamageHash = joaat('WEAPON_ANIMAL')
                    Death.lastDamageTime = GetGameTimer()
                elseif IsEntityAPed(attacker) then
                    local weapon = GetSelectedPedWeapon(attacker)
                    if weapon and weapon ~= 0 then
                        Death.lastDamageHash = weapon
                        Death.lastDamageTime = GetGameTimer()
                    end
                elseif IsEntityAVehicle(attacker) then
                    Death.lastDamageHash = joaat('WEAPON_RAMMED_BY_CAR')
                    Death.lastDamageTime = GetGameTimer()
                end
            end
            if Death.lastDamageHash == 0 or (GetGameTimer() - Death.lastDamageTime) > 5000 then
                if IsEntityInWater(playerPed) or IsPedSwimmingUnderWater(playerPed) then
                    Death.lastDamageHash = joaat('WEAPON_DROWNING')
                    Death.lastDamageTime = GetGameTimer()
                elseif IsEntityOnFire(playerPed) then
                    Death.lastDamageHash = joaat('WEAPON_FIRE')
                    Death.lastDamageTime = GetGameTimer()
                elseif IsPedFalling(playerPed) then
                    Death.lastDamageHash = joaat('WEAPON_FALL')
                    Death.lastDamageTime = GetGameTimer()
                end
            end
        end
    end

    if event == "CEventNetworkEntityDamage" and args[6] == 1 then
        if not IsEntityAPed(args[1]) or not IsPedAPlayer(args[1]) or (args[1] ~= VFW.PlayerData.ped) then
            return
        end

        -- Si le ped est réellement mort (HP=0, ragdoll, fatally injured), on doit
        -- traiter la mort même si l'état KO ou invincible est encore actif :
        -- sinon vfw:onPlayerDeath n'est jamais déclenché et le joueur reste stuck
        -- en KO/invincible avec 0 HP sans écran de mort.
        local victimPed = args[1]
        local actuallyDead = IsEntityDead(victimPed) or IsPedDeadOrDying(victimPed, true) or IsPedFatallyInjured(victimPed)

        -- Staff godmode : on ignore sauf si réellement mort (bypass forcé)
        if GetPlayerInvincible(PlayerId()) and not actuallyDead then
            return
        end

        -- KO en cours : on ignore sauf si réellement mort. Dans ce cas, on cleanup
        -- l'état KO côté client + serveur AVANT de laisser la logique de mort se dérouler.
        if isKnockedOut then
            if not actuallyDead then
                return
            end

            isKnockedOut = false
            LocalPlayer.state:set("isKnockedOut", false, false)
            ClearKONotifications()
            VFW.Nui.deathScreen(false)
            TriggerScreenblurFadeOut(1000)
            DisplayRadar(true)
            TriggerEvent("statushud:show")
            koRecoveryTimer = GetGameTimer() + 5000
            TriggerServerEvent("vfw:onPlayerRevived")
        end

        local weaponHash = GetPedCauseOfDeath(VFW.PlayerData.ped)
        if meleeWeapon[weaponHash] then
            local dmgConfig = GlobalState.WeaponDamageConfig
            local wName = weaponHashToName[weaponHash]
            local wConfig = dmgConfig and wName and dmgConfig[wName]

            if wConfig and wConfig.canKill then
                CEventNetworkEntityDamage(args[1], args[4])
                return
            end

            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(playerPed), true, false)
            playerPed = PlayerPedId()
            SetEntityHealth(playerPed, 150)

            -- Invincibilité uniquement si on enclenche réellement un KO.
            -- Sinon (recovery / déjà KO) on resterait stuck invincible sans
            -- thread de getup pour clear le flag.
            if not isKnockedOut and koRecoveryTimer <= GetGameTimer() then
                SetEntityInvincible(playerPed, true)
                TriggerServerEvent("vfw:startko", GetPlayerServerId(PlayerId()))
            end
            return
        end

        CEventNetworkEntityDamage(args[1], args[4])
    end
end)

local knockoutStates = {}
local cooldown = {}
isKnockedOut = false

-- Reset les flags locaux qui empêchent un re-KO après relèvement.
-- knockoutStates et cooldown sont posés par TriggerKO et n'expirent autrement
-- qu'après 20s, ce qui bloquait tout nouveau KO sur ce joueur.
local function ResetLocalKOState()
    local pid = PlayerId()
    knockoutStates[pid] = nil
    cooldown[pid] = nil
    meleeHitCounters[pid] = nil
    meleeHitTimers[pid] = nil
end

RegisterNUICallback("nui:deathscreen:up", function()
    if not isKnockedOut then
        return
    end

    isKnockedOut = false
    LocalPlayer.state:set("isKnockedOut", false, false)

    ClearKONotifications()

    VFW.Nui.deathScreen(false)

    TriggerEvent("statushud:show")

    local ped = PlayerPedId()
    SetPedCanRagdoll(ped, false)
    ClearPedTasksImmediately(ped)
    TriggerScreenblurFadeOut(1000)
    SetEntityInvincible(ped, false)
    DisplayRadar(true)
    koRecoveryTimer = GetGameTimer() + 5000

    ResetLocalKOState()
    TriggerServerEvent("vfw:onPlayerRevived")

    Wait(250)

    SetPedCanRagdoll(ped, true)
end)

local function TriggerKO(victim, playerId)
    CancelEvent()
    SetEntityHealth(victim, 150)

    if not knockoutStates[playerId] then
        knockoutStates[playerId] = true
        cooldown[playerId] = GetGameTimer() + 1000

        -- Protection immédiate contre les hits pendant le round-trip serveur
        -- (le SetEntityInvincible(true) définitif arrive dans le handler vfw:startko)
        if victim == PlayerPedId() then
            SetEntityInvincible(victim, true)
        end

        TriggerServerEvent("vfw:startko", GetPlayerServerId(playerId))

        SetTimeout(20000, function()
            knockoutStates[playerId] = nil
            cooldown[playerId] = nil
        end)
    end
end

---@param victim any
---@param culprit any
---@param weapon any
---@param baseDamage any
AddEventHandler("entityDamaged", function(victim, culprit, weapon, baseDamage)
    -- entityDamaged fire sur tous les clients qui voient l'entité. On ne traite que notre propre KO :
    -- seul le client victime peut légitimement déclencher son KO (validé côté serveur par src==playerId).
    if victim ~= PlayerPedId() then
        return
    end

    if not DoesEntityExist(culprit) then
        return
    end

    if not IsPedAPlayer(culprit) then
        return
    end

    -- Anti self-KO : ragdoll/chute/environnement ne doit pas déclencher un KO
    if victim == culprit then
        return
    end

    if not meleeWeapon[weapon] then
        CancelEvent()
        return
    end

    -- Annule les dégâts bruts du moteur GTA pour appliquer uniquement la version réduite
    CancelEvent()

    -- Déjà KO : on laisse les hits traverser sans relancer la logique
    if isKnockedOut then
        return
    end

    -- Staff invincible : ne doit jamais tomber KO
    if GetPlayerInvincible(PlayerId()) then
        return
    end

    local playerId = NetworkGetPlayerIndexFromPed(victim)
    if not playerId or playerId < 0 then
        return
    end

    if koRecoveryTimer > GetGameTimer() then
        return
    end

    if cooldown[playerId] and cooldown[playerId] > GetGameTimer() then
        return
    end

    -- Le moteur GTA a déjà appliqué les dégâts bruts. On calcule la vraie perte
    -- en comparant avec le dernier HP connu, puis on restaure pour n'appliquer que 1/4.
    local currentHealth = GetEntityHealth(victim)
    local actualDamage = lastTrackedHP - currentHealth
    if actualDamage < 0 then actualDamage = 0 end
    local reducedDamage = math.floor(actualDamage / 4)
    local newHealth = lastTrackedHP - reducedDamage
    if newHealth < 150 then newHealth = 150 end
    SetEntityHealth(victim, newHealth)
    lastTrackedHP = newHealth

    local dmgConfig = GlobalState.WeaponDamageConfig
    local weaponName = weaponHashToName[weapon] or ("0x" .. string.format("%X", weapon))
    local wConfig = dmgConfig and weaponHashToName[weapon] and dmgConfig[weaponHashToName[weapon]]

    if wConfig then
        if wConfig.oneshot then
            TriggerKO(victim, playerId)
            meleeHitCounters[playerId] = nil
            meleeHitTimers[playerId] = nil
            return
        end

        if wConfig.hitsToKO > 0 then
            meleeHitCounters[playerId] = (meleeHitCounters[playerId] or 0) + 1
            meleeHitTimers[playerId] = GetGameTimer()

            SetTimeout(10000, function()
                if meleeHitTimers[playerId] and GetGameTimer() - meleeHitTimers[playerId] >= 9900 then
                    meleeHitCounters[playerId] = nil
                    meleeHitTimers[playerId] = nil
                end
            end)

            if meleeHitCounters[playerId] >= wConfig.hitsToKO then
                meleeHitCounters[playerId] = nil
                meleeHitTimers[playerId] = nil
                TriggerKO(victim, playerId)
                return
            end

            if not wConfig.canKill then
                local playerLife = GetEntityHealth(victim)
                if playerLife <= 150 then
                    SetEntityHealth(victim, 150)
                end
            end
            return
        end

        if not wConfig.canKill then
            local playerLife = GetEntityHealth(victim)
            if playerLife <= 150 then
                TriggerKO(victim, playerId)
            end
            return
        end
    end

    local playerLife = GetEntityHealth(victim)

    if playerLife <= 150 then
        TriggerKO(victim, playerId)
    end
end)

-- Durée par défaut du KO (doit matcher KnockoutConfig.duration côté serveur)
local KO_DURATION_DEFAULT = 30000

RegisterNetEvent("vfw:startko", function(duration)
    if isKnockedOut then
        return
    end

    duration = duration or KO_DURATION_DEFAULT
    isKnockedOut = true
    LocalPlayer.state:set("isKnockedOut", true, false)

    SetEntityInvincible(PlayerPedId(), true)

    Wait(250)

    DisplayRadar(false)
    TriggerEvent("statushud:hide")

    local startTime = GetGameTimer()
    local readyTime = startTime + duration -- Peut se relever quand la durée KO est écoulée
    local notifiedReady = false
    local notifiedWaiting = false
    local lastNotify = 0

    -- Ragdoll initial longue durée pour que le ped reste au sol sans se relever entre deux cycles
    local ped = PlayerPedId()
    SetPedCanRagdoll(ped, true)
    SetPedToRagdoll(ped, duration + 5000, duration + 5000, 0, true, true, false)

    CreateThread(function()
        while isKnockedOut do
            if not Death.gettingRevived then
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 21, true)
                DisableControlAction(0, 22, true)
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 32, true)
                DisableControlAction(0, 33, true)
                DisableControlAction(0, 34, true)
                DisableControlAction(0, 35, true)
                DisableControlAction(0, 36, true)
                DisableControlAction(0, 44, true)
                DisableControlAction(0, 45, true)
                DisableControlAction(0, 47, true)
                DisableControlAction(0, 73, true)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 143, true)
                DisableControlAction(0, 200, true)
                DisablePlayerFiring(VFW.playerId, true)

                local ped = PlayerPedId()
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)

                -- Re-ragdoll uniquement si le ped est sorti du ragdoll (collision, script externe, etc.)
                if not IsPedRagdoll(ped) then
                    SetPedToRagdoll(ped, duration + 5000, duration + 5000, 0, true, true, false)
                end

                local now = GetGameTimer()

                local remaining = math.floor((readyTime - now) / 1000)
                if remaining < 0 then remaining = 0 end

                if not notifiedReady and remaining > 0 then
                    if (
                            IsControlJustPressed(0, 24) or
                                    IsControlJustPressed(0, 25) or
                                    IsControlJustPressed(0, 22) or
                                    IsControlJustPressed(0, 21) or
                                    IsControlJustPressed(0, 32) or
                                    IsControlJustPressed(0, 33) or
                                    IsControlJustPressed(0, 34) or
                                    IsControlJustPressed(0, 35) or
                                    IsControlJustPressed(0, 36)
                    ) then
                        if GetGameTimer() - lastNotify > 2000 then
                            VFW.ShowNotification({
                                type = "ROUGE",
                                content = "Vous êtes étourdi, il reste " .. remaining .. " secondes avant de vous relever."
                            })
                            lastNotify = GetGameTimer()
                        end
                    end
                end

                local currentTime = GetGameTimer()

                if not notifiedWaiting and not notifiedReady and currentTime < readyTime then
                    VFW.ShowNotification({
                        type = "JAUNE",
                        content = "Vous êtes KO, vous pourrez bientôt vous relever.",
                        duration = 30,
                        id = "ko_waiting_notification"
                    })
                    notifiedWaiting = true
                end

                if not notifiedReady and currentTime >= readyTime then
                    VFW.ShowNotification({
                        type = "VERT",
                        content = "Appuyez sur [E] pour vous relever.",
                        duration = -1,
                        id = "ko_getup_notification"
                    })
                    notifiedReady = true
                    lastNotify = currentTime
                end

                if notifiedReady and VFW.Interact.JustPressed(0, 38) then
                    isKnockedOut = false
                    LocalPlayer.state:set("isKnockedOut", false, false)

                    ClearKONotifications()

                    local ped = PlayerPedId()
                    SetPedCanRagdoll(ped, false)
                    ClearPedTasksImmediately(ped)
                    SetEntityInvincible(ped, false)
                    DisplayRadar(true)
                    TriggerEvent("statushud:show")
                    koRecoveryTimer = GetGameTimer() + 5000

                    ResetLocalKOState()
                    TriggerServerEvent("vfw:onPlayerRevived")

                    VFW.ShowNotification({
                        type = "VERT",
                        content = "Vous vous êtes relevé."
                    })

                    Citizen.Wait(250)
                    SetPedCanRagdoll(ped, true)

                    break
                end
            end

            Wait(0)
        end

        -- Safety net : si la boucle sort autrement que par le getup (revive
        -- externe, mort réelle, etc.), on force le clear de l'invincibilité.
        -- Le staff godmode rejoue son SetEntityInvincible(true) dans son
        -- propre thread (50ms tick) donc on ne casse pas son état.
        SetEntityInvincible(PlayerPedId(), false)
    end)
end)





RegisterNetEvent("death:receiveEMSCount", function(count, id)
    Death.emsCount = count
end)


function Death:GetRespawnTime()
    return 600 -- 10 min fixe pour tout le monde
end

