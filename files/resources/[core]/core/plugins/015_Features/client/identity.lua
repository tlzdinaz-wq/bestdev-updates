---@meta _
---@diagnostic disable: duplicate-doc-field

local identityCardPeds = {}

--- OpenIdentityCard using new playerDocuments UI
---@param my_data table
-- Track if document is open
local documentOpen = false

local CardConfig = {
    identity = {
        type = "identity",
        label = "Carte d'identité",
        fields = {
            {label = "Nom", key = "lastName"},
            {label = "Prénom", key = "firstName"},
            {label = "Date de naissance", key = "date_of_birth"},
            {label = "Sexe", key = "sex"},
            {label = "Taille", key = "height"},
            {label = "Adresse", key = "address"}
        }
    } ,

    driver = {
        type = "driver_license",
        label = "Permis de conduire",
        fields = {
            {label = "Nom", key = "lastName"},
            {label = "Prénom", key = "firstName"},
            {label = "Date de naissance", key = "date_of_birth"},
            {label = "Catégorie", key = "category", default = "B"},
            {label = "Délivré le", key = "issued_date", default = "01/01/2024"},
            {label = "Valide jusqu'au", key = "expiry_date", default = "01/01/2034"}
        }
    } ,

    motorbike = {
        type = "motorbike_license",
        label = "Permis moto",
        fields = {
            {label = "Nom", key = "lastName"},
            {label = "Prénom", key = "firstName"},
            {label = "Date de naissance", key = "date_of_birth"},
            {label = "Catégorie", key = "category", default = "A"},
            {label = "Délivré le", key = "issued_date", default = "01/01/2024"},
            {label = "Valide jusqu'au", key = "expiry_date", default = "01/01/2034"}
        }
    } ,

    truck = {
        type = "truck_license",
        label = "Permis poids lourd",
        fields = {
            {label = "Nom", key = "lastName"},
            {label = "Prénom", key = "firstName"},
            {label = "Date de naissance", key = "date_of_birth"},
            {label = "Catégorie", key = "category", default = "C"},
            {label = "Délivré le", key = "issued_date", default = "01/01/2024"},
            {label = "Valide jusqu'au", key = "expiry_date", default = "01/01/2034"}
        }
    } ,
    weapon = {
        type = "weapon",
        label = "Permis de port d'arme",
        fields = {
            {label = "Nom", key = "lastName"},
            {label = "Prénom", key = "firstName"},
            {label = "Délivré le", key = "issued_date", default = "01/01/2024"},
            {label = "Valide jusqu'au", key = "expiry_date", default = "01/01/2025"},
            {label = "Type", key = "type", default = "Catégorie A et B"},
            {label = "Numéro", key = "number", default = "PPA-" .. math.random(100000, 999999)}
        }
    },

    job = {
        type = "job_card",
        label = "Carte de travail",
        fields = {
            {label = "Nom", key = "lastName"},
            {label = "Prénom", key = "firstName"},
            {label = "Entreprise", key = "job_label"},
            {label = "Poste", key = "job_grade_label"}
        }
    },

    cayo_visa = {
        type = "cayo_visa",
        label = "Visa de Cayo Perico",
        fields = {
            {label = "Nom", key = "lastName"},
            {label = "Prénom", key = "firstName"},
            {label = "Date de naissance", key = "date_of_birth"},
            {label = "Délivré le", key = "issued_date", default = "Non renseigné"},
            {label = "Expire le", key = "expires_date", default = "Non renseigné"},
            {label = "Numéro", key = "visa_number", default = "CAYO-00000"},
            {label = "Délivré par", key = "issuer", default = "Gouvernement de Cayo"}
        }
    }

}

local function OpenIdentityCard(my_data)
    local documentData = {}
    local cardType = ""
    local cardLabel = ""

    local data = CardConfig[my_data.type] or CardConfig["identity"]
    cardType = data.type
    cardLabel = data.label
    for i = 1, #data.fields do
        local field = data.fields[i]
        documentData[field.label] = my_data[field.key] or field.default
    end


    SendNUIMessage({
        action = "playerDocuments:toggle",
        data = {
            cardType = cardType,
            cardLabel = cardLabel,
            theme = "light",
            data = documentData,
            photoUrl = my_data.photo,
            visaExpired = my_data.visa_expired and true or false
        }
    })

    documentOpen = true

    -- Create thread to handle ESC key
    Citizen.CreateThread(function()
        while documentOpen do
            Wait(0)
            -- Disable pause menu ONLY while document is open
            DisableControlAction(0, 200, true) -- ESC / Pause menu
            DisableControlAction(0, 199, true) -- P / Pause menu

            -- Check if ESC (disabled), Enter, or Backspace/Return is pressed
            if IsDisabledControlJustPressed(0, 200) or -- ESC
               IsControlJustPressed(0, 191) or -- Enter
               IsControlJustPressed(0, 194) or -- Backspace
               IsControlJustPressed(0, 177) then -- KEY_BACK/Return
                documentOpen = false
                SendNUIMessage({
                    action = "playerDocuments:close"
                })
                -- Clear animation if any
                ExecuteCommand("+clearAnim")
            end
        end
        -- When loop ends (document closed), pause menu will work normally again
    end)

    Citizen.SetTimeout(10000, function()
        -- Close document after 10 seconds (if needed)
        ExecuteCommand("+clearAnim")
    end)
end

---@param type any
RegisterNetEvent("identity:opencard", function(type)
    VFW.CloseInventory()

    local result = VFW.StartSelect(3.0, true)
    local idS = GetPlayerServerId(result)

    if result and idS then
        TriggerServerEvent("core:identity:display", idS, type)
        ExecuteCommand("e idcard")
        Citizen.SetTimeout(10000, function()
            ExecuteCommand("+clearAnim")
        end)
    end
end)

---@param data table
RegisterNetEvent("core:identity:show", function(data)
    VFW.CloseInventory()
    OpenIdentityCard(data)
end)

-- Document closing is now handled by the playerDocuments component via ESC key
-- RegisterNuiCallback("nui:identity:close", function()
--     -- Deprecated: handled by new UI
-- end)

-- NUI Callback to close player documents
RegisterNUICallback("nui:playerDocuments:close", function(data, cb)
    documentOpen = false
    cb('ok')
end)

-- Command to view your own identity card (used by F5 menu)
RegisterCommand("opencard", function()
    local my_data = TriggerServerCallback("identity:getData", GetPlayerServerId(PlayerId()))
    if my_data then
        OpenIdentityCard(my_data)
    end
end)

-- Event to view your own identity card directly
RegisterNetEvent("identity:viewOwnCard", function(type)
    local my_data = TriggerServerCallback("identity:getData", GetPlayerServerId(PlayerId()))
    if my_data then
        my_data.type = type or "identity"
        OpenIdentityCard(my_data)
    end
end)

-- Event pour forcer la fermeture du document (quand le joueur qui montre s'éloigne)
RegisterNetEvent("vfw:identity:forceCloseDocument", function()
    documentOpen = false
    SendNUIMessage({
        action = "playerDocuments:close"
    })
end)

local function spawnIdentityCardNpc(pos, model, scenario)
    VFW.Streaming.RequestModel(model)
    local ped = CreatePed(4, joaat(model), pos.x, pos.y, pos.z, pos.w, false, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if scenario and scenario ~= "" then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(joaat(model))
    return ped
end

CreateThread(function()
    while not VFW.PlayerLoaded do
        Wait(100)
    end

    local cfg = IdentityConfig and IdentityConfig.IdentityCardNpc
    if not cfg or cfg.enabled == false then
        return
    end

    local positions = cfg.positions or {}
    if #positions == 0 then
        return
    end

    local model = cfg.model or "a_f_y_business_01"
    local scenario = cfg.scenario

    for i = 1, #positions do
        local ped = spawnIdentityCardNpc(positions[i], model, scenario)
        if ped and DoesEntityExist(ped) then
            identityCardPeds[#identityCardPeds + 1] = {
                ped = ped,
                coords = vector3(positions[i].x, positions[i].y, positions[i].z),
            }
        end
    end

    if cfg.blip and cfg.blip.enabled and positions[1] then
        local blip = AddBlipForCoord(positions[1].x, positions[1].y, positions[1].z)
        SetBlipSprite(blip, cfg.blip.sprite or 498)
        SetBlipScale(blip, cfg.blip.scale or 0.5)
        SetBlipColour(blip, cfg.blip.color or 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(cfg.blip.name or "Carte d'identité")
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    while not VFW.PlayerLoaded do
        Wait(100)
    end

    local cfg = IdentityConfig and IdentityConfig.IdentityCardNpc
    if not cfg or cfg.enabled == false then
        return
    end

    local interactionDistance = cfg.interactionDistance or 2.0
    local helpText = cfg.helpText or "Appuyez sur ~INPUT_CONTEXT~ pour récupérer votre carte d'identité"

    while true do
        local sleep = 500

        if #identityCardPeds > 0 then
            local playerCoords = GetEntityCoords(PlayerPedId())

            for i = 1, #identityCardPeds do
                local npcData = identityCardPeds[i]
                if npcData.ped and DoesEntityExist(npcData.ped) then
                    local dist = #(playerCoords - npcData.coords)

                    if dist < interactionDistance then
                        sleep = 0
                        VFW.ShowHelpNotification(helpText)

                        if VFW.Interact.JustPressed(0, 38) then
                            TriggerServerEvent("identity:givemycard")
                        end

                        break
                    end
                end
            end
        end

        Wait(sleep)
    end
end)
