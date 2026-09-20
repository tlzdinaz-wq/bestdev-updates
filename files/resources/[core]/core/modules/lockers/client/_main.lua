--- @class Locker
local Locker = {}
Locker.__index = Locker

Locker.list = {}

Locker.hasInitialized = false
local vestiaireFloatingShown = false
local vestiaireFloatingId = nil

local VUI = exports["VUI"]
local main = VUI:CreateMenu("Menu vestiaire", VFW.CDN.Get("banners/vestiaire.png"), true)
local selectedOutfit = VUI:CreateMenu("Menu tenue actuelle", VFW.CDN.Get("banners/vestiaire.png"), true)

local currentOutfit = nil
local currentLocker = nil
local savedOutfit = nil

main.OnOpen(function()
    -- Utiliser la bannière custom de la société/faction si elle existe
    local customBanner = nil
    if Society.data and Society.data.banner and Society.data.banner ~= "" then
        customBanner = Society.data.banner
    elseif VFW.PlayerData and VFW.PlayerData.faction and VFW.PlayerData.faction.banner and VFW.PlayerData.faction.banner ~= "" then
        customBanner = VFW.PlayerData.faction.banner
    end
    if customBanner then
        main.ChangeBanner(customBanner)
        selectedOutfit.ChangeBanner(customBanner)
    end

    local locker <const> = Locker.list[currentLocker]

    if locker then
        if locker.whitelistType == "job" or locker.whitelistType == "faction" and locker.whitelistValue then
            if (VFW.PlayerData.job.name == locker.whitelistValue and (VFW.PlayerData.job.grade == 99 or VFW.PlayerData.job.grade == 98))
                    or (VFW.PlayerData.faction.name == locker.whitelistValue and (VFW.PlayerData.faction.grade == 99 or VFW.PlayerData.faction.grade == 98)) then
                main.Button("Enregistrer la tenue actuelle", "", nil, "chevron", false, function()
                    local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom de la tenue", "")
                    if name == "" then
                        return
                    end

                    TriggerServerEvent("core:lockers:addOutfit", currentLocker, {
                        label = name,
                        clothes = GetSkinClothes()
                    })

                    main.refresh()
                end)
            end
        end

        if savedOutfit then
            main.Button("Récupérer sa tenue classique", "", nil, "chevron", false, function()
                for name, value in pairs(savedOutfit) do
                    TriggerEvent("skinchanger:change", name, value)
                end

                savedOutfit = nil

                VFW.ShowNotification({
                    type = 'VERT',
                    content = "Vous avez récupéré votre tenue classique."
                })

                main.refresh()
            end)
        end

        if not locker.outfits or #locker.outfits == 0 then
            main.Separator("Aucune tenue enregistrée")
        else
            for index, data in pairs(locker.outfits) do
                main.Button(data.label, "", nil, "chevron", false, function()
                    currentOutfit = data
                    currentOutfit.index = index
                    currentOutfit.locker = currentLocker
                end, selectedOutfit)
            end
        end
    end
end)

selectedOutfit.OnOpen(function()
    selectedOutfit.Button("Équiper cette tenue", "", nil, "chevron", false, function()
        savedOutfit = GetSkinClothes()

        for name, value in pairs(currentOutfit.clothes) do
            TriggerEvent("skinchanger:change", name, value)
        end

        VFW.ShowNotification({
            type = 'VERT',
            content = "Vous avez équipé cette tenue."
        })
    end)

    if savedOutfit then
        selectedOutfit.Button("Récupérer sa tenue classique", "", nil, "chevron", false, function()
            for name, value in pairs(savedOutfit) do
                TriggerEvent("skinchanger:change", name, value)
            end

            savedOutfit = nil

            VFW.ShowNotification({
                type = 'VERT',
                content = "Vous avez récupéré votre tenue classique."
            })
        end)
    end

    local locker = Locker.list[currentOutfit.locker]
    if locker.whitelistType == "job" or locker.whitelistType == "faction" and locker.whitelistValue then
        if (VFW.PlayerData.job.name == locker.whitelistValue and (VFW.PlayerData.job.grade == 99 or VFW.PlayerData.job.grade == 98))
                or (VFW.PlayerData.faction.name == locker.whitelistValue and (VFW.PlayerData.faction.grade == 99 or VFW.PlayerData.faction.grade == 98)) then
            selectedOutfit.Button("Supprimer cette tenue", "", nil, "chevron", false, function()
                TriggerServerEvent("core:lockers:removeOutfit", currentOutfit.locker, currentOutfit.index)
                selectedOutfit.close()
            end)
        end
    end
end)

local function capitaliser(s)
    if not s or s == "" then
        return ""
    end
    return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end


-- Fonction utilitaire pour créer le blip (basée sur ton code commenté)
function Locker.createBlip(data)

    Wait(5000)
    local blip = AddBlipForCoord(data.position.x, data.position.y, data.position.z)
    SetBlipSprite(blip, 73)
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, data.whitelistType == "faction" and 1 or 3)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    local jobLabel
    if data.whitelistType == "faction" then
        jobLabel = VFW.PlayerData and VFW.PlayerData.faction and VFW.PlayerData.faction.label or data.whitelistValue
    else
        jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or data.whitelistValue
    end
    local blipLabel = capitaliser(jobLabel) .. " • Vestiaire"
    AddTextComponentString(blipLabel)
    EndTextCommandSetBlipName(blip)

    return blip
end

RegisterNetEvent("core:lockers:retrieve", function(lockers)
    Locker.removeAll() -- Nettoie tout (blips inclus)
    Locker.list = lockers or {}

    -- Création des blips pour chaque locker reçu
    for k, v in pairs(Locker.list) do
        v.blip = Locker.createBlip(v)
    end

    Locker.init()
end)

RegisterNetEvent("core:lockers:remove", function(id)
    Locker.remove(id)
end)

RegisterNetEvent("core:lockers:update", function(data)
    Locker.remove(data.id) -- Supprime l'ancien (et son blip)

    -- Crée le nouveau blip
    data.blip = Locker.createBlip(data)
    Locker.list[data.id] = data

    -- Rafraîchir le menu si ouvert sur ce locker
    if currentLocker == data.id then
        main.refresh()
    end
end)

RegisterNetEvent("core:lockers:create", function(data)
    -- Crée le blip à la création
    data.blip = Locker.createBlip(data)
    Locker.list[data.id] = data
end)

local function ShowVestiaireFloating(id, worldPos, floatingZ)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + (floatingZ or 0.5))
    if not onScreen then
        if vestiaireFloatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            vestiaireFloatingShown = false
            vestiaireFloatingId = nil
        end
        return
    end

    local data = {
        id = "vestiaire_" .. tostring(id),
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = {
            { label = "Accéder au vestiaire", key = "E" }
        }
    }

    if vestiaireFloatingShown and vestiaireFloatingId == id then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        vestiaireFloatingShown = true
        vestiaireFloatingId = id
    end
end

local function HideVestiaireFloating()
    if vestiaireFloatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        vestiaireFloatingShown = false
        vestiaireFloatingId = nil
    end
end

function Locker.init()
    if Locker.hasInitialized then
        return
    end
    Locker.hasInitialized = true

    CreateThread(function()
        local interval

        while true do
            interval = 500

            if IsNuiFocused() then
                HideVestiaireFloating()
            else
                local coords = GetEntityCoords(PlayerPedId())
                local found = false

                for id, data in pairs(Locker.list) do
                    if data.whitelistType == "job" or data.whitelistType == "faction" and data.whitelistValue then
                        if VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.faction and VFW.PlayerData.job.name ~= data.whitelistValue and VFW.PlayerData.faction.name ~= data.whitelistValue then
                            goto continue
                        end
                    end

                    local dist = #(vector3(coords.x, coords.y, coords.z) - vector3(data.position.x, data.position.y, data.position.z))

                    if dist <= 3.0 then
                        found = true
                        interval = 0
                        ShowVestiaireFloating(id, vector3(data.position.x, data.position.y, data.position.z), data.floatingZ)

                        if VFW.Interact.JustPressed(0, 38) then
                            currentLocker = id
                            HideVestiaireFloating()
                            main.open()
                        end
                        break
                    end

                    :: continue ::
                end

                if not found then
                    HideVestiaireFloating()
                end
            end

            Wait(interval)
        end
    end)
end

function Locker.remove(id)
    if Locker.list[id] then
        -- Suppression du blip si il existe
        if DoesBlipExist(Locker.list[id].blip) then
            RemoveBlip(Locker.list[id].blip)
        end

        Locker.list[id] = nil
    end
end

function Locker.removeAll()
    for id, _ in pairs(Locker.list) do
        Locker.remove(id)
    end
end
