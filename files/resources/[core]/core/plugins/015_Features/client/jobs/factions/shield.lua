---@meta _
---@diagnostic disable: duplicate-doc-field

local shield = false
local shield_net = nil

-- Modèles par priorité : custom d'abord, fallback vanilla
local SHIELD_MODELS = {
    lspd = { "lspd_ballistic_shieldon_h", "prop_riot_shield" },
    lssd = { "lssd_ballistic_shieldon_b", "prop_riot_shield" },
}

local SHIELD_DICT = "smo@shield_pistol_req_01"
local SHIELD_ANIM = "shield_pistol_req_01_clip"

--- Tente de charger un modèle parmis une liste (premier qui charge = utilisé)
local function TryLoadModel(models)
    for _, modelName in ipairs(models) do
        local hash = joaat(modelName)
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 20 do
            Wait(50)
            timeout = timeout + 1
        end
        if HasModelLoaded(hash) then
            return hash
        end
        SetModelAsNoLongerNeeded(hash)
    end
    return nil
end

local function ToggleShield(models)
    CreateThread(function()
        if not shield then
            local ped = PlayerPedId()

            -- Charger le premier modèle disponible
            local prop = TryLoadModel(models)
            if not prop then return end

            local attachProps = VFW.OneSync.CreateObject(prop, GetEntityCoords(ped))
            SetModelAsNoLongerNeeded(prop)
            shield_net = ObjToNet(attachProps)

            -- Charger l'animation (optionnel — on continue même si elle échoue)
            RequestAnimDict(SHIELD_DICT)
            local timeout = 0
            while not HasAnimDictLoaded(SHIELD_DICT) and timeout < 60 do
                Wait(10)
                timeout = timeout + 1
            end
            if HasAnimDictLoaded(SHIELD_DICT) then
                TaskPlayAnim(ped, SHIELD_DICT, SHIELD_ANIM, 1.0, 4.0, -1, 49, 0, 0, 0, 0)
            end

            AttachEntityToEntity(attachProps, ped, GetPedBoneIndex(ped, 57005), -0.20, 0.27, -0.15, 42.0, 315.0, 80.0, false, false, false, true, 1, true)

            shield = true
        else
            shield = false
            ClearPedSecondaryTask(PlayerPedId())
            if shield_net then
                local obj = NetToObj(shield_net)
                if DoesEntityExist(obj) then
                    DetachEntity(obj, true, true)
                    DeleteEntity(obj)
                end
            end
            shield_net = nil
        end
    end)
end

-- Fonctions globales appelables depuis menu.lua
function TogglePoliceShield()
    ToggleShield(SHIELD_MODELS.lspd)
end

function ToggleLSSDShield()
    ToggleShield(SHIELD_MODELS.lssd)
end

RegisterNetEvent("shield:TogglePoliceShield")
AddEventHandler("shield:TogglePoliceShield", TogglePoliceShield)

RegisterNetEvent("shield:ToggleLSSDShield")
AddEventHandler("shield:ToggleLSSDShield", ToggleLSSDShield)
