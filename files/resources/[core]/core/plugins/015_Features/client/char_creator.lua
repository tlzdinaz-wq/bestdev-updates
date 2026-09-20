---@meta _
---@diagnostic disable: duplicate-doc-field

-- NUI requests CDN config lazily before clothing / vehicle uploads
RegisterNuiCallback("nui:getCdnConfig", function(_, cb)
    local cdnConfig = TriggerServerCallback("vfw:server:getCdnConfig")
    cb(cdnConfig or {})
end)

-- Chromakey is done in NUI (Fg/w6), then the PNG is sent here to FiveManage (API key stays server-side).
local mugshotUploadPending = {}
local mugshotUploadSeq = 0

RegisterNuiCallback("nui:uploadMugshotProcessed", function(data, cb)
    local payload = nil
    if type(data) == "table" then
        payload = data.data or data.base64 or data.image
    elseif type(data) == "string" then
        payload = data
    end
    if type(payload) ~= "string" or #payload < 32 then
        cb({ url = "" })
        return
    end

    mugshotUploadSeq = mugshotUploadSeq + 1
    local reqId = mugshotUploadSeq
    local waiter = promise.new()
    mugshotUploadPending[reqId] = waiter

    TriggerLatentServerEvent("vfw:server:uploadMugshot", 2000000, reqId, payload)

    SetTimeout(25000, function()
        local pending = mugshotUploadPending[reqId]
        if pending then
            mugshotUploadPending[reqId] = nil
            pending:resolve("")
        end
    end)

    local url = Citizen.Await(waiter)
    cb({ url = (type(url) == "string" and url) or "" })
end)

RegisterNetEvent("vfw:client:mugshotUploaded", function(reqId, url)
    reqId = tonumber(reqId)
    local waiter = reqId and mugshotUploadPending[reqId]
    if not waiter then return end
    mugshotUploadPending[reqId] = nil
    waiter:resolve(type(url) == "string" and url or "")
end)

-- Shared mugshot camera configuration (used by both normal and debug mode)
local MUGSHOT_CAM_CONFIG = {
    COH = { x = 306.60675048828125000, y = 217.95388793945312500, z = 104.30, w = 341.62274169921875000 },
    CamCoords = { x = 306.87799999999703005, y = 219.00900000000291357, z = 106.02900000000276748 },
    CamRot = { x = -3.00000000000000000, y = 0.00000000000000000, z = 166.38404846191406250 },
    Fov = 22.0,
    Freeze = true,
    Dof = false,
    DofStrength = 0.0
}

-- Configuration du fond vert pour mugshot (position calculée dynamiquement)
local GREEN_SCREEN_CONFIG = {
    SphereRadius = 3.0, -- Augmenté pour englober la caméra (distance cam ~2m du centre)
    Weather = 'EXTRASUNNY',
    Hour = 14
}

local greenScreenActive = false
local greenScreenColor = { r = 0, g = 0, b = 0 } -- Noir par défaut

-- Flag pour bloquer tous les mouvements/emotes pendant le mugshot
local isInMugshot = false
local mugshotPose = nil

function IsPlayerInMugshot()
    return isInMugshot
end

-- Pose debout d'origine, vitesse d'anim à 0 = visible et immobile.
local MUGSHOT_STILL = { dict = "rcmnigel1a", anim = "base" }

local function holdMugshotPed(ped)
    ped = ped or PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    DisableAllControlActions(0)
    FreezeEntityPosition(ped, true)
    if mugshotPose and mugshotPose.dict and IsEntityPlayingAnim(ped, mugshotPose.dict, mugshotPose.anim, 3) then
        SetEntityAnimSpeed(ped, mugshotPose.dict, mugshotPose.anim, 0.0)
    end
end

local function placeMugshotPed(ped, pos)
    ped = ped or PlayerPedId()
    if EmoteCancel then pcall(EmoteCancel) end
    ClearPedTasksImmediately(ped)
    RequestCollisionAtCoord(pos.x, pos.y, pos.z)
    SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
    SetEntityHeading(ped, pos.w)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)
    SetEntityAlpha(ped, 255, false)
    ResetEntityAlpha(ped)
    SetPedCanRagdoll(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
end

local function beginMugshotPose(ped, pos)
    ped = ped or PlayerPedId()
    mugshotPose = { x = pos.x, y = pos.y, z = pos.z, w = pos.w, dict = MUGSHOT_STILL.dict, anim = MUGSHOT_STILL.anim }
    placeMugshotPed(ped, pos)

    RequestAnimDict(MUGSHOT_STILL.dict)
    local t = 0
    while not HasAnimDictLoaded(MUGSHOT_STILL.dict) and t < 50 do
        Wait(0)
        t = t + 1
    end
    if HasAnimDictLoaded(MUGSHOT_STILL.dict) then
        TaskPlayAnim(ped, MUGSHOT_STILL.dict, MUGSHOT_STILL.anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
        Wait(80)
        SetEntityAnimSpeed(ped, MUGSHOT_STILL.dict, MUGSHOT_STILL.anim, 0.0)
    end
    SetEntityVisible(ped, true, false)
end

local function endMugshotPose(ped)
    mugshotPose = nil
    ped = ped or PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        SetPedCanRagdoll(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, false)
        ClearPedTasksImmediately(ped)
    end
end

local function startGreenScreenThread(playerPos, heading)
    if greenScreenActive then
        return
    end
    greenScreenActive = true

    CreateThread(function()
        local frameCount = 0

        while greenScreenActive do
            SetWeatherTypeOvertimePersist(GREEN_SCREEN_CONFIG.Weather, 0.0)
            NetworkOverrideClockTime(GREEN_SCREEN_CONFIG.Hour, 0, 0)
            DrawGlowSphere(playerPos.x, playerPos.y, playerPos.z, 3.0, greenScreenColor.r, greenScreenColor.g,
                greenScreenColor.b, 1.0, false, true)
            Wait(0)
        end
    end)
end

local function stopGreenScreenThread()
    greenScreenActive = false
end

local function setGreenScreenColor(r, g, b)
    greenScreenColor.r = r
    greenScreenColor.g = g
    greenScreenColor.b = b
end

local lastTattoos = {}
local creatorActive = false

CreateThread(function()
    while true do
        if isInMugshot then
            holdMugshotPed(PlayerPedId())
            Wait(0)
        elseif creatorActive then
            DisableControlAction(0, 200, true) -- ESC / Pause menu
            DisableControlAction(0, 199, true) -- P / Pause menu
            Wait(0)
        else
            Wait(500)
        end
    end
end)

local creaPersoData                                                                                = {
    ---@class catalogue
    catalogue = {},
    ---@class peds
    peds = {},
    ---@class pedsVariantes
    pedsVariantes = {},
    ---@class recoverableCharacters
    recoverableCharacters = {}
}

local temporaryDatas                                                                               = {
    playerType = "Homme",
    playerSex = "male"
}

--- Capitalize first letter of each word
---@param str string
---@return string
local function capitalizeWords(str)
    if not str or str == "" then return str end
    return str:gsub("(%a)([%w]*)", function(first, rest) return first:upper() .. rest:lower() end)
end

local TypePed, lastName, firstName, dateOfBirthdayr, birthplace, height                            = nil, nil, nil, nil,
    nil, nil, nil
local newP1, newP2, lastSkinValue, lastlookingValue                                                = nil, nil, nil, nil
local lastnoseX, lastnoseY                                                                         = nil, nil
local lastnosePointeX, lastnosePointeY                                                             = nil, nil
local lastnoseProfileX, lastnoseProfileY                                                           = nil, nil
local lastSourcilsX, lastSourcilsY                                                                 = nil, nil
local lastpommettesX, lastpommettesY                                                               = nil, nil
local lastMentonX, lastMentonY                                                                     = nil, nil
local lastMentonShapeX, lastMentonShapeY                                                           = nil, nil
local lastMachoireX, lastMachoireY                                                                 = nil, nil
local lastCou, lastlevres, lastjoues, lastyeux                                                     = nil, nil, nil, nil
local oldHair, oldColor1, oldColor2                                                                = nil, nil, nil
local oldBeard, oldColorbeard1, oldColorbeard2                                                     = nil, nil, nil
local oldsourcils, oldColorsourcils1, oldColorsourcils2, oldColorsourcils3                         = nil, nil, nil, nil
local oldpilosite, oldColorpilosite1, oldColorpilosite3                                            = nil, nil, nil
local ColorEyes                                                                                    = nil
local oldeyesmaquillage, oldColoreyesmaquillage1, oldColoreyesmaquillage2, oldColoreyesmaquillage3 = nil, nil, nil, nil
local oldfard, oldColorfard1, oldColorfard3                                                        = nil, nil, nil
local oldrougealevre, oldColorrougealevre1, oldColorrougealevre3                                   = nil, nil, nil
local oldOpacityTache, oldtaches                                                                   = nil, nil
local oldmarques, oldOpacityMarque                                                                 = nil, nil
local oldacne, oldOpacityAcne                                                                      = nil, nil
local oldteint, oldOpacityTeint                                                                    = nil, nil
local oldcicatrice, oldOpacityCicatrice                                                            = nil, nil
local oldrousseur, oldOpacityrousseur                                                              = nil, nil
local newPed, sexPed                                                                               = nil, nil
local lastTattoos                                                                                  = {}
local lastOnglet                                                                                   = nil
local lastLoadedPedId                                                                              = nil -- Cache pour éviter de recharger LoadVariationForPed inutilement

local zoneMap                                                                                      = {
    ["ZONE_HEAD"] = "head",
    ["ZONE_TORSO"] = "torso",
    ["ZONE_LEFT_ARM"] = "leftArm",
    ["ZONE_RIGHT_ARM"] = "rightArm",
    ["ZONE_LEFT_LEG"] = "leftLeg",
    ["ZONE_RIGHT_LEG"] = "rightLeg"
}

-- Noms lisibles pour les tatouages custom (partagé avec le shop)
local customTattooNames = {
    customface1 = "Visage Tribal 1", customface2 = "Visage Tribal 2", customface3 = "Visage Tribal 3",
    facefemale1 = "Visage Féminin 1", facefemale2 = "Visage Féminin 2",
    customthroat001 = "Gorge 1", customthroat002 = "Gorge 2", customthroat003 = "Gorge 3",
    customthroat004 = "Gorge 4", customthroat005 = "Gorge 5", customthroat006 = "Gorge 6",
    customthroat007 = "Gorge 7", customthroat008 = "Gorge 8", throatfemale = "Gorge Féminine",
    customleftarm = "Manchette Gauche", customrightarm = "Manchette Droite",
    flowersleave1 = "Manchette Fleurs", colorful2tonedflowersleave = "Manchette Fleurs Bicolore",
    blackl = "Bras Noir Gauche", blackr = "Bras Noir Droit",
    ghostrider = "Ghost Rider", crushedskull = "Crâne Brisé", dimentionalskull = "Crâne Dimensionnel",
    skullsnake = "Crâne Serpent", snake = "Serpent",
    customleftleg001 = "Jambe Gauche", customrightleg = "Jambe Droite",
    customback1 = "Dos 1", customback2 = "Dos 2", customtorso1 = "Torse 1",
    customvikings001 = "Viking 1", customvikings002 = "Viking 2", customvikings003 = "Viking 3",
    customvikings004 = "Viking 4", customvikings005 = "Viking 5", customvikings006 = "Viking 6",
    customvikings007 = "Viking 7", customvikings008 = "Viking 8",
    customvikings010 = "Viking 10", customvikings011 = "Viking 11",
    customvikings012 = "Viking 12", customvikings013 = "Viking 13",
    ballastattoo_001 = "Ballas 1", ballastattoo_002 = "Ballas 2", ballastattoo_003 = "Ballas 3",
    ballastattoo_004 = "Ballas 4", ballastattoo_005 = "Ballas 5", ballastattoo_006 = "Ballas 6",
    ballastattoo_007 = "Ballas 7", ballastattoo_008 = "Ballas 8", ballastattoo_009 = "Ballas 9",
    ballastattoo_010 = "Ballas 10", ballastattoo_011 = "Ballas 11", ballastattoo_012 = "Ballas 12",
    ballastattoo_013 = "Ballas 13", ballastattoo_014 = "Ballas 14",
    families_001 = "Families 1", families_002 = "Families 2", families_003 = "Families 3",
    families_004 = "Families 4", families_005 = "Families 5", families_006 = "Families 6",
    families_007 = "Families 7", families_008 = "Families 8", families_009 = "Families 9",
    families_010 = "Families 10", families_011 = "Families 11", families_012 = "Families 12",
    families_013 = "Families 13", families_014 = "Families 14",
    customfemale_001 = "Féminin 1", customfemale_002 = "Féminin 2", customfemale_003 = "Féminin 3",
    customfemale_004 = "Féminin 4", customfemale_005 = "Féminin 5", customfemale_006 = "Féminin 6",
    customfemale_007 = "Féminin 7", customfemale_008 = "Féminin 8", customfemale_009 = "Féminin 9",
    customfemale_010 = "Féminin 10",
    custom_swat_tattoo = "SWAT", ["50boyz"] = "50 Boyz",
}

local function getTattooLabel(tattoo)
    local name = tattoo.Name or ""
    if customTattooNames[name] then return customTattooNames[name] end
    if tattoo.LocalizedName and tattoo.LocalizedName ~= name then return tattoo.LocalizedName end
    local label = name:gsub("_", " "):gsub("(%d+)$", " %1")
    return label:sub(1, 1):upper() .. label:sub(2)
end

local function LoadTattooCatalogue()
    local tattoos = GetTattoos()
    creaPersoData.tattoos = {}

    for _, tattoo in ipairs(tattoos) do
        local hashName = temporaryDatas.playerType == "Femme" and tattoo.HashNameFemale or tattoo.HashNameMale
        if hashName and hashName ~= "" then
            local tempCatalogue = {
                id = hashName,
                label = getTattooLabel(tattoo),
                image =
                VFW.CDN.Get("catalogues/tattoo/tattooList/" .. string.lower(tattoo.Img) .. ".png"),
                price = tattoo.Price,
                category = zoneMap[tattoo.Zone] or tattoo.Zone,
                Collection = tattoo.Collection,        -- 👈 añade la colección
                HashNameMale = tattoo.HashNameMale,    -- 👈 añade hash male
                HashNameFemale = tattoo.HashNameFemale -- 👈 añade hash female
            }


            -- Guardar en tattoos
            table.insert(creaPersoData.tattoos, tempCatalogue)

            -- 🔹 Insertar también en catalogue
            table.insert(creaPersoData.catalogue, tempCatalogue)
        end
    end
end

---Load FaceFeatures
local function LoadFaceFeatures()
    local playerPed = PlayerPedId()
    local playerType = temporaryDatas.playerType

    --- AddToCatalogue
    ---@param id number|string
    ---@param labelPrefix string
    ---@param imgPath any
    ---@param category any
    local function AddToCatalogue(id, labelPrefix, imgPath, category)
        creaPersoData.catalogue[#creaPersoData.catalogue + 1] = {
            id = id,
            label = labelPrefix .. " N°" .. id,
            img = VFW.CDN.Get(imgPath .. id .. ".webp"),
            category = category,
        }
    end

    --- AddDefaultToCatalogue
    ---@param id number|string
    ---@param category any
    local function AddDefaultToCatalogue(id, category)
        creaPersoData.catalogue[#creaPersoData.catalogue + 1] = {
            id = id,
            label = "Aucun",
            img = "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg",
            category = category,
        }
    end

    AddDefaultToCatalogue(0, "hair")
    for i = 1, GetNumberOfPedDrawableVariations(playerPed, 2) - 1 do
        if not VFW.Table.TableContains(Config.BarberBan[playerType].CoupesBan, i) then
            AddToCatalogue(i, "Coiffure", "catalogues/barber/" .. playerType .. "/Coupes/", "hair")
        end
    end

    if playerType == "Homme" then
        AddDefaultToCatalogue(0, "beard")
        for i = 1, GetNumHeadOverlayValues(1) do
            AddToCatalogue(i, "Barbe", "catalogues/barber/" .. playerType .. "/Barbes/", "beard")
        end

        AddDefaultToCatalogue(-1, "pilosite")
        for i = 0, GetPedHeadOverlayNum(10) do
            AddToCatalogue(i, "Pilosité", "catalogues/shenails/" .. playerType .. "/PilositeTorse/", "pilosite")
        end

        AddDefaultToCatalogue(-1, "eyesmaquillage")
        for i = 0, GetPedHeadOverlayNum(4) do
            AddToCatalogue(i, "Maquillage", "catalogues/shenails/" .. playerType .. "/Maquillage/",
                "eyesmaquillage")
        end

        AddDefaultToCatalogue(-1, "rougealevre")
        for i = 0, GetPedHeadOverlayNum(8) do
            AddToCatalogue(i, "Rouge à levres", "catalogues/shenails/" .. playerType .. "/RougeLevre/",
                "rougealevre")
        end

        AddDefaultToCatalogue(-1, "sourcils")
        for i = 0, GetPedHeadOverlayNum(2) do
            AddToCatalogue(i, "Sourcils", "catalogues/shenails/" .. playerType .. "/Sourcils/", "sourcils")
        end
    end

    if playerType == "Femme" then
        AddDefaultToCatalogue(-1, "eye_makeup")
        for i = 0, GetPedHeadOverlayNum(4) do
            AddToCatalogue(i, "Maquillage", "catalogues/shenails/" .. playerType .. "/Maquillage/", "eye_makeup")
        end

        AddDefaultToCatalogue(-1, "lips_makeup")
        for i = 0, GetPedHeadOverlayNum(8) do
            AddToCatalogue(i, "Rouge à levres", "catalogues/shenails/" .. playerType .. "/RougeLevre/",
                "lips_makeup")
        end

        AddDefaultToCatalogue(-1, "eyebrows")
        for i = 0, GetPedHeadOverlayNum(2) do
            AddToCatalogue(i, "Sourcils", "catalogues/shenails/" .. playerType .. "/Sourcils/", "eyebrows")
        end
    end

    AddDefaultToCatalogue(-1, "fard")
    for i = 0, GetPedHeadOverlayNum(5) do
        AddToCatalogue(i, "Fard à joue", "catalogues/shenails/" .. playerType .. "/Blush/", "fard")
    end

    AddDefaultToCatalogue(-1, "taches")
    for i = 1, GetPedHeadOverlayNum(11) do
        AddToCatalogue(i, "Tâche cutanée", "character-creator/" .. playerType .. "/TacheCutanee/", "taches")
    end

    AddDefaultToCatalogue(-1, "marques")
    for i = 0, GetPedHeadOverlayNum(3) do
        AddToCatalogue(i, "Marque de la peau", "character-creator/" .. playerType .. "/MarquePeau/", "marques")
    end

    AddDefaultToCatalogue(-1, "acne")
    for i = 0, 24 do
        AddToCatalogue(i, "Acné", "character-creator/" .. playerType .. "/Acne/", "acne")
    end

    AddDefaultToCatalogue(-1, "teint")
    for i = 0, GetPedHeadOverlayNum(6) do
        AddToCatalogue(i, "Teint", "character-creator/" .. playerType .. "/Teint/", "teint")
    end

    AddDefaultToCatalogue(-1, "cicatrice")
    for i = 0, GetPedHeadOverlayNum(7) do
        AddToCatalogue(i, "Cicatrice", "character-creator/" .. playerType .. "/Cicatrice/", "cicatrice")
    end

    AddDefaultToCatalogue(-1, "rousseur")
    for i = 0, GetNumHeadOverlayValues(9) do
        AddToCatalogue(i, "Tâche de rousseu", "character-creator/" .. playerType .. "/Rousseur/", "rousseur")
    end
end

---Load PedsFeatures
local function LoadPedsFeatures()
    local pedsMale = Config.PedsJustForCrea.homme
    local pedsFemale = Config.PedsJustForCrea.femme

    for i = 1, #pedsMale do
        local v = pedsMale[i]
        if IsModelInCdimage(joaat(v)) then
            creaPersoData.peds[#creaPersoData.peds + 1] = {
                category = 'man',
                label = v,
                id = i
            }
        end
    end

    for i = 1, #pedsFemale do
        local v = pedsFemale[i]
        if IsModelInCdimage(joaat(v)) then
            creaPersoData.peds[#creaPersoData.peds + 1] = {
                category = 'woman',
                label = v,
                id = #pedsMale + i
            }
        end
    end
end

---Load ButtonsCreaPerso
local function LoadButtonsCreaPerso()
    local baseURL = VFW.CDN.Get("catalogues/binco/")
    local defaultType = temporaryDatas.playerType

    ---Create Button
    ---@param name string
    ---@param width number|string
    ---@param imagePath any
    ---@param price number
    ---@param progressBar any
    ---@return number|table|boolean Created object or success status
    local function CreateButton(name, width, imagePath, price, progressBar)
        return {
            name = name,
            width = width,
            image = imagePath,
            type = 'coverBackground',
            hoverStyle = 'fill-black stroke-black',
            price = price,
            progressBar = progressBar
        }
    end

    local images = {
        Hauts = baseURL .. defaultType .. '/torso2.webp',
        SousHauts = baseURL .. defaultType .. '/undershirt.webp',
        Bras = baseURL .. defaultType .. '/torso.webp',
        Bas = baseURL .. defaultType .. '/leg.webp',
        Chaussures = baseURL .. defaultType .. '/shoes.webp',
        Chapeaux = baseURL .. defaultType .. '/hat.webp',
        Lunettes = baseURL .. defaultType .. '/glasses.webp',
        Cou = baseURL .. defaultType .. '/cou.webp',
        Montre = baseURL .. defaultType .. '/watch.webp',
        Oreilles = baseURL .. defaultType .. '/earring.webp',
        Bracelet = baseURL .. defaultType .. '/bracelet.webp',
        Masque = baseURL .. defaultType .. '/mask.webp',
    }

    local progressBars = {
        { name = 'Variations' }
    }

    creaPersoData.buttons = {
        CreateButton('Hauts', 'full', images.Hauts, 100, { { name = 'Hauts' }, table.unpack(progressBars) }),
        CreateButton('Sous-hauts', 'half', images.SousHauts, 50, { { name = 'Sous-hauts' }, table.unpack(progressBars) }),
        CreateButton('Bras', 'half', images.Bras, 50, { { name = 'Bras' }, table.unpack(progressBars) }),
        CreateButton('Bas', 'full', images.Bas, 120, { { name = 'Bas' }, table.unpack(progressBars) }),
        CreateButton('Chaussures', 'full', images.Chaussures, 110,
            { { name = 'Chaussures' }, table.unpack(progressBars) }),
        CreateButton('Chapeaux', 'full', images.Chapeaux, 80, { { name = 'Chapeaux' }, table.unpack(progressBars) }),
        CreateButton('Lunettes', 'half', images.Lunettes, 50, { { name = 'Lunettes' }, table.unpack(progressBars) }),
        CreateButton('Cou', 'half', images.Cou, 20, { { name = 'Cou' }, table.unpack(progressBars) }),
        CreateButton('Montre', 'half', images.Montre, 50, { { name = 'Montre' }, table.unpack(progressBars) }),
        CreateButton('Oreilles', 'half', images.Oreilles, 50, { { name = 'Oreilles' }, table.unpack(progressBars) }),
        CreateButton('Bracelet', 'half', images.Bracelet, 50, { { name = 'Bracelet' }, table.unpack(progressBars) }),
        CreateButton('Masque', 'half', images.Masque, 50, { { name = 'Masque' }, table.unpack(progressBars) })
    }
end

---Load ClothesForCreator
---@param baseURL string sexe du ped ("male" | "female") — les URLs viennent de VFW.OutfitImage
local function LoadClothesForCreator(baseURL)
    local playerPed = PlayerPedId()
    local bans = Config.ClothesBan[temporaryDatas.playerType] or {}

    --- AddToCatalogue
    ---@param id number|string
    ---@param label string
    ---@param image any
    ---@param category any
    ---@param subCategory any
    ---@param idVariation number|string
    ---@param targetId number|string
    local function AddToCatalogue(id, label, image, category, subCategory, idVariation, targetId)
        creaPersoData.catalogue[#creaPersoData.catalogue + 1] = {
            id = id,
            label = label,
            image = image,
            category = category,
            subCategory = subCategory,
            idVariation = idVariation,
            targetId = targetId
        }
    end

    --- ProcessClothing
    ---@param drawableType any
    ---@param banList any
    ---@param category any
    ---@param subCategory any
    ---@param prefix any
    local function ProcessClothing(drawableType, banList, category, subCategory, prefix)
        for i = 0, GetNumberOfPedDrawableVariations(playerPed, drawableType) - 1 do
            if not VFW.Table.TableContains(banList, i) then
                local drawableURL = VFW.OutfitImage(baseURL, "clothing", prefix, i, 0)
                AddToCatalogue(i, string.format("%s N°%d", category, i), drawableURL, category, subCategory, i)

                for z = 0, GetNumberOfPedTextureVariations(playerPed, drawableType, i) - 1 do
                    local imageURL = z == 0 and drawableURL or VFW.OutfitImage(baseURL, "clothing", prefix, i, z)
                    AddToCatalogue(z, string.format("Variation N°%d", z), imageURL, category, "Variations", nil, i)
                end
            end
        end
    end

    --- ProcessProps
    ---@param propType any
    ---@param banList any
    ---@param category any
    ---@param prefix any
    local function ProcessProps(propType, banList, category, prefix)
        for i = 0, GetNumberOfPedPropDrawableVariations(playerPed, propType) - 1 do
            if not VFW.Table.TableContains(banList, i) then
                local drawableURL = VFW.OutfitImage(baseURL, "props", prefix, i, 0)
                AddToCatalogue(i, string.format("%s N°%d", category, i), drawableURL, category, category, i)

                for z = 0, GetNumberOfPedPropTextureVariations(playerPed, propType, i) - 1 do
                    local imageURL = z == 0 and drawableURL or VFW.OutfitImage(baseURL, "props", prefix, i, z)
                    AddToCatalogue(z, string.format("Variation N°%d", z), imageURL, category, "Variations", nil, i)
                end
            end
        end
    end

    ProcessClothing(4, bans.BanLeg, "Bas", "Bas", "leg")

    ProcessClothing(6, bans.BanShoes, "Chaussures", "Chaussures", "shoes")

    AddToCatalogue(15, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Hauts", "Hauts", 15)
    ProcessClothing(11, bans.BanTop, "Hauts", "Hauts", "torso2")

    -- Sous-hauts comme catégorie séparée
    local defaultUndershirtId = temporaryDatas.playerType == "Homme" and 15 or 14
    AddToCatalogue(defaultUndershirtId, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Sous-hauts", "Sous-hauts",
        defaultUndershirtId)
    ProcessClothing(8, bans.BanSous, "Sous-hauts", "Sous-hauts", "undershirt")

    -- Bras comme catégorie séparée
    local defaultBrasId = temporaryDatas.playerType == "Homme" and 15 or 15
    AddToCatalogue(defaultBrasId, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Bras", "Bras", defaultBrasId)
    ProcessClothing(3, bans.BanArm, "Bras", "Bras", "torso")

    AddToCatalogue(-1, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Chapeaux", "Chapeaux", -1)
    ProcessProps(0, bans.BanHat, "Chapeaux", "hat")

    local glassesDefaultId = temporaryDatas.playerType == "Homme" and 0 or -1
    AddToCatalogue(glassesDefaultId, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Lunettes", "Lunettes",
        glassesDefaultId)
    ProcessProps(1, bans.BanGlases, "Lunettes", "glasses")

    AddToCatalogue(0, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Cou", "Cou", 0)
    ProcessClothing(7, bans.BanCou, "Cou", "Cou", "accessory")

    AddToCatalogue(-1, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Montre", "Montre", -1)
    ProcessProps(6, bans.BanWatch or {}, "Montre", "watch")

    AddToCatalogue(-1, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Oreilles", "Oreilles", -1)
    ProcessProps(2, bans.BanEarring or {}, "Oreilles", "earring")

    AddToCatalogue(-1, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Bracelet", "Bracelet", -1)
    ProcessProps(7, bans.BanBracelet or {}, "Bracelet", "bracelet")

    AddToCatalogue(0, "Aucun", "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", "Masque", "Masque", 0)
    ProcessClothing(1, bans.BanMasque or {}, "Masque", "Masque", "mask")
end

---Load DataForCreator
---@param sex any
local function LoadDataForCreator(sex)
    creaPersoData.catalogue = {}
    creaPersoData.peds = {}
    creaPersoData.pedsVariantes = {} -- Clear PED variations when switching to normal character
    temporaryDatas.playerType = sex == 1 and "Femme" or "Homme"

    if temporaryDatas.playerType == "Homme" then
        temporaryDatas.playerSex = "male"
    elseif temporaryDatas.playerType == "Femme" then
        temporaryDatas.playerSex = "female"
    else
        temporaryDatas.playerSex = "ped"
    end

    local baseURL = temporaryDatas.playerSex

    creaPersoData.hideItemList = { 'Variations 3' }

    if temporaryDatas.playerType == "Homme" then
        creaPersoData.catalogue[#creaPersoData.catalogue + 1] = { id = 61, label = "Aucun", image =
        "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", category = "Bas", subCategory = "Bas", idVariation = 61 }
    else
        creaPersoData.catalogue[#creaPersoData.catalogue + 1] = { id = 17, label = "Aucun", image =
        "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", category = "Bas", subCategory = "Bas", idVariation = 17 }
    end

    if temporaryDatas.playerType == "Homme" then
        creaPersoData.catalogue[#creaPersoData.catalogue + 1] = { id = 34, label = "Aucun", image =
        "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", category = "Chaussures", subCategory = "Chaussures", idVariation = 34 }
    else
        creaPersoData.catalogue[#creaPersoData.catalogue + 1] = { id = 35, label = "Aucun", image =
        "https://cfx-nui-core/interface/brand/outfits_greenscreener/aucun.svg", category = "Chaussures", subCategory = "Chaussures", idVariation = 35 }
    end

    LoadFaceFeatures()
    LoadPedsFeatures()
    LoadButtonsCreaPerso()
    LoadTattooCatalogue()
    LoadClothesForCreator(baseURL)

    Wait(250)
    creatorActive = true
    TriggerEvent("pma-voice:toggleUi", false)
    VFW.Nui.Creator(true, creaPersoData)

    -- Apply default heritage (Daniel for both parents) on ped immediately
    newP1 = 1
    newP2 = 1
    TriggerEvent("skinchanger:change", "mom", 1)
    TriggerEvent("skinchanger:change", "dad", 1)
    TriggerEvent("skinchanger:change", "face_md_weight", 50)
    TriggerEvent("skinchanger:change", "skin_md_weight", 50)
    lastlookingValue = 0.5
    lastSkinValue = 0.5

    -- Fade in after UI is loaded
    Wait(100)
    DoScreenFadeIn(500)
end

---Load NewCharCreator
function LoadNewCharCreator()
    while VFW.PlayerGlobalData == nil do Wait(1000) end

    local p = promise.new()

    VFW.Nui.HudVisible(false)

    TriggerEvent("skinchanger:loadSkin", { sex = 0 }, function()
        p:resolve()
    end)

    Citizen.Await(p)

    TriggerServerEvent("core:server:instanceCreator", true)

    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, Config.CharCreator[1].COH.x, Config.CharCreator[1].COH.y, Config.CharCreator[1].COH.z - 1)
    SetEntityHeading(playerPed, Config.CharCreator[1].COH.w)
    SetEntityAsMissionEntity(playerPed, true, true)

    Wait(500)

    creaPersoData.vip = VFW.PlayerGlobalData.permissions["vip_bronze"] or
    VFW.PlayerGlobalData.permissions["vip_silver"] or VFW.PlayerGlobalData.permissions["vip_gold"]

    if creaPersoData.vip then
        local characters = TriggerServerCallback('core:server:characterCreator')

        if characters and #characters > 0 then
            for i = 1, #characters do
                local v = characters[i]
                creaPersoData.recoverableCharacters[#creaPersoData.recoverableCharacters + 1] = {
                    name = v.firstname .. " " .. v.lastname,
                    data = {
                        identity = {
                            firstName = v.lastname,
                            lastName = v.firstname,
                            dateOfBirthdayr = v.age,
                            birthplace = v.birthplaces,
                            sex = (v.sex == "F") and 1 or (v.sex == "M") and 0 or nil,
                        },
                        skin = v.skin
                    }
                }
            end
        end
    end

    VFW.Cam:Create("cam_creator", Config.CharCreator[1])

    NetworkOverrideClockTime(03, 0, 0)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')

    LoadDataForCreator(0)
end

---Load VariationForPed
---@param sex any
local function LoadVariationForPed(sex)
    local playerPed = PlayerPedId()

    creaPersoData.pedsVariantes = {}
    local categories = {
        { component = 0, category = "visage" },
        { component = 3, category = "haut" },
        { component = 4, category = "bas" },
        { component = 6, category = "chaussure" }
    }

    for i = 1, #categories do
        local valeur = categories[i]
        local component = valeur.component
        local category = valeur.category

        for ii = 0, GetNumberOfPedDrawableVariations(playerPed, component) - 1 do
            creaPersoData.pedsVariantes[#creaPersoData.pedsVariantes + 1] = {
                category = category,
                subCategory = sex,
                id = ii,
                idVariante = ii
            }

            for z = 0, GetNumberOfPedTextureVariations(playerPed, component, ii) - 1 do
                creaPersoData.pedsVariantes[#creaPersoData.pedsVariantes + 1] = {
                    category = category,
                    subCategory = sex,
                    id = z,
                    targetId = ii
                }
            end
        end
    end

    VFW.Nui.Creator(true, creaPersoData)

    -- Apply default heritage (Daniel for both parents) on ped immediately
    newP1 = 1
    newP2 = 1
    TriggerEvent("skinchanger:change", "mom", 1)
    TriggerEvent("skinchanger:change", "dad", 1)
    TriggerEvent("skinchanger:change", "face_md_weight", 50)
    TriggerEvent("skinchanger:change", "skin_md_weight", 50)
    lastlookingValue = 0.5
    lastSkinValue = 0.5
end

--- ToggleSound
---@param state any
local function ToggleSound(state)
    if state then
        StartAudioScene("MP_LEADERBOARD_SCENE");
    else
        StopAudioScene("MP_LEADERBOARD_SCENE");
    end
end

--- ClearScreen
local function ClearScreen()
    SetCloudsAlpha(0.01)
    HideHudAndRadarThisFrame()
    SetDrawOrigin(0.0, 0.0, 0.0, 0)
end

--- SpawnPlayerCharCreator
---@param spawnPoint any
local function SpawnPlayerCharCreator(spawnPoint)
    local playerPed = PlayerPedId()

    if VFW.Cam:Get("cam_creator") then
        VFW.Cam:Destroy("cam_creator")
    end
    RenderScriptCams(false, false, 0, true, true)

    ToggleSound(true)

    if not IsPlayerSwitchInProgress() then
        SwitchToMultiFirstpart(playerPed, 0, 1)
    end

    local firstPartDeadline = GetGameTimer() + 10000
    while GetPlayerSwitchState() ~= 5 and GetGameTimer() < firstPartDeadline do
        Wait(0)
        ClearScreen()
    end

    ShutdownLoadingScreen()
    DoScreenFadeIn(100)

    local spawnCoords = nil
    local spawnHeading = nil

    if spawnPoint == "cubes" then
        spawnCoords = vector3(-252.14, -304.92, 21.63)
        spawnHeading = 202.03
    elseif spawnPoint == "paletobay" then
        spawnCoords = vector3(-513.87, 6643.99, 4.68)
        spawnHeading = 228.03
    end

    if spawnCoords then
        -- Focus le streaming sur la zone de spawn avant de téléporter
        SetFocusPosAndVel(spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, 0.0, 0.0)
        RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
        NewLoadSceneStart(spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.x, spawnCoords.y, spawnCoords.z, 50.0, 0)

        local timeout = GetGameTimer() + 15000
        while not IsNewLoadSceneLoaded() and GetGameTimer() < timeout do
            Wait(100)
        end
        NewLoadSceneStop()

        -- Téléporter le joueur
        SetEntityCoords(playerPed, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
        SetEntityHeading(playerPed, spawnHeading)
        FreezeEntityPosition(playerPed, true)

        -- Attendre que la collision soit chargée autour du joueur
        timeout = GetGameTimer() + 10000
        while not HasCollisionLoadedAroundEntity(playerPed) and GetGameTimer() < timeout do
            RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
            Wait(100)
        end

        -- Relâcher le focus streaming (revient au joueur)
        ClearFocus()
        FreezeEntityPosition(playerPed, false)
    end

    FreezeEntityPosition(playerPed, true)

    local fadeDeadline = GetGameTimer() + 10000
    while not IsScreenFadedIn() and GetGameTimer() < fadeDeadline do
        Wait(0)
        ClearScreen()
    end

    local TIMER <const> = GetGameTimer()

    ToggleSound(false)

    while GetGameTimer() - TIMER <= 1000 do
        Wait(0)
    end

    SwitchToMultiSecondpart(playerPed)

    local secondPartDeadline = GetGameTimer() + 10000
    while GetPlayerSwitchState() ~= 12 and GetGameTimer() < secondPartDeadline do
        Wait(0)
        ClearScreen()
    end

    if IsPlayerSwitchInProgress() then
        StopPlayerSwitch()
    end

    ClearDrawOrigin()
    VFW.Nui.HudVisible(true)
    FreezeEntityPosition(playerPed, false)
    SetEntityInvincible(playerPed, false)
    -- OpenTutorialForm()

    -- Le serveur garde le bypass WaveShield actif jusqu'a ce que la
    -- cinematique de spawn (player switch GTA V) soit totalement terminee.
    TriggerServerEvent("vfw:multicharacter:spawnAnimationComplete")
end

RegisterNuiCallback("CreationPersonnageSetCamera", function(data, cb)
    local camConfig
    if data.newCamera == "full" then
        camConfig = Config.CharCreator[1]
    elseif data.newCamera == "face" then
        camConfig = Config.CharCreator[2]
    elseif data.newCamera == "chest" then
        camConfig = Config.CharCreator[12]
    elseif data.newCamera == "legs" then
        camConfig = Config.CharCreator[11]
    end

    if camConfig then
        if VFW.Cam:Get("cam_creator") then
            VFW.Cam:Update("cam_creator", camConfig)
        else
            VFW.Cam:Create("cam_creator", camConfig)
        end
    end
    cb("ok")
end)


-- Retourne les infos pour les sliders du créateur (max drawables, textures)
RegisterNuiCallback("nui:char-creator:checkName", function(data, cb)
    if not data.firstName or not data.lastName then
        cb({ available = true })
        return
    end
    local ok, err = TriggerServerCallback("core:server:checkIdentityName", data.firstName, data.lastName)
    cb({ available = ok == true, message = err })
end)

RegisterNuiCallback("nui:char-creator:getCategorySliderInfo", function(data, cb)
    local categoryName = data.category
    local playerPed = PlayerPedId()

    local categoryMapping = {
        ["Hauts"] = { type = "drawable", componentId = 11 },
        ["Sous-hauts"] = { type = "drawable", componentId = 8 },
        ["Bras"] = { type = "drawable", componentId = 3 },
        ["Bas"] = { type = "drawable", componentId = 4 },
        ["Chaussures"] = { type = "drawable", componentId = 6 },
        ["Chapeaux"] = { type = "prop", componentId = 0 },
        ["Lunettes"] = { type = "prop", componentId = 1 },
        ["Cou"] = { type = "drawable", componentId = 7 },
        ["Montre"] = { type = "prop", componentId = 6 },
        ["Oreilles"] = { type = "prop", componentId = 2 },
        ["Bracelet"] = { type = "prop", componentId = 7 },
        ["Masque"] = { type = "drawable", componentId = 1 },
    }

    local mapping = categoryMapping[categoryName]
    if not mapping then
        cb({ maxDrawable = 0, maxTexture = 0, currentDrawable = 0, currentTexture = 0 })
        return
    end

    local isDrawable = mapping.type == "drawable"
    local compId = mapping.componentId

    local getVariations = isDrawable and GetNumberOfPedDrawableVariations or GetNumberOfPedPropDrawableVariations
    local getCurrent = isDrawable and GetPedDrawableVariation or GetPedPropIndex
    local getCurrentTex = isDrawable and GetPedTextureVariation or GetPedPropTextureIndex
    local getTextures = isDrawable and GetNumberOfPedTextureVariations or GetNumberOfPedPropTextureVariations

    local currentDrawable = getCurrent(playerPed, compId)
    local currentTexture = getCurrentTex(playerPed, compId)
    local maxDrawable = getVariations(playerPed, compId) - 1
    local maxTexture = getTextures(playerPed, compId, currentDrawable) - 1

    cb({
        maxDrawable = math.max(maxDrawable, 0),
        maxTexture = math.max(maxTexture, 0),
        currentDrawable = currentDrawable,
        currentTexture = currentTexture
    })
end)

-- Retourne le nombre de textures pour un drawable donné dans le créateur
RegisterNuiCallback("nui:char-creator:getTextureCount", function(data, cb)
    local categoryName = data.category
    local drawableId = data.drawableId
    local playerPed = PlayerPedId()

    local categoryMapping = {
        ["Hauts"] = { type = "drawable", componentId = 11 },
        ["Sous-hauts"] = { type = "drawable", componentId = 8 },
        ["Bras"] = { type = "drawable", componentId = 3 },
        ["Bas"] = { type = "drawable", componentId = 4 },
        ["Chaussures"] = { type = "drawable", componentId = 6 },
        ["Chapeaux"] = { type = "prop", componentId = 0 },
        ["Lunettes"] = { type = "prop", componentId = 1 },
        ["Cou"] = { type = "drawable", componentId = 7 },
        ["Montre"] = { type = "prop", componentId = 6 },
        ["Oreilles"] = { type = "prop", componentId = 2 },
        ["Bracelet"] = { type = "prop", componentId = 7 },
        ["Masque"] = { type = "drawable", componentId = 1 },
    }

    local mapping = categoryMapping[categoryName]
    if not mapping then
        cb({ maxTexture = 0 })
        return
    end

    local getTextures = mapping.type == "drawable" and GetNumberOfPedTextureVariations or GetNumberOfPedPropTextureVariations
    local count = getTextures(playerPed, mapping.componentId, drawableId)

    cb({ maxTexture = math.max(count - 1, 0) })
end)

RegisterNuiCallback("CreationPersonnageClickHabit", function(data)
    if (data == nil) or (data.category == nil) then
        return
    end

    if data.category == "Hauts" then
        if data.subCategory == "Hauts" then
            TriggerEvent("skinchanger:change", "torso_1", data.id)
            TriggerEvent("skinchanger:change", "torso_2", 0)
            if Config.ClothsList[temporaryDatas.playerType]["Haut"][tostring(data.id)] then
                TriggerEvent("skinchanger:change", "arms",
                    Config.ClothsList[temporaryDatas.playerType]["Haut"][tostring(data.id)])
                TriggerEvent("skinchanger:change", "arms_2", 0)
            end
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "torso_2", data.id)
        end
    elseif data.category == "Sous-hauts" then
        if data.subCategory == "Sous-hauts" then
            TriggerEvent("skinchanger:change", "tshirt_1", data.id)
            TriggerEvent("skinchanger:change", "tshirt_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "tshirt_2", data.id)
        end
    elseif data.category == "Bras" then
        if data.subCategory == "Bras" then
            TriggerEvent("skinchanger:change", "arms", data.id)
            TriggerEvent("skinchanger:change", "arms_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "arms_2", data.id)
        end
    elseif data.category == "Bas" then
        if data.subCategory == "Bas" then
            TriggerEvent("skinchanger:change", "pants_1", data.id)
            TriggerEvent("skinchanger:change", "pants_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "pants_2", data.id)
        end
    elseif data.category == "Chaussures" then
        if data.subCategory == "Chaussures" then
            TriggerEvent("skinchanger:change", "shoes_1", data.id)
            TriggerEvent("skinchanger:change", "shoes_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "shoes_2", data.id)
        end
    elseif data.category == "Chapeaux" then
        if data.subCategory == "Chapeaux" then
            TriggerEvent("skinchanger:change", "helmet_1", data.id)
            TriggerEvent("skinchanger:change", "helmet_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "helmet_2", data.id)
        end
    elseif data.category == "Lunettes" then
        if data.subCategory == "Lunettes" then
            TriggerEvent("skinchanger:change", "glasses_1", data.id)
            TriggerEvent("skinchanger:change", "glasses_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "glasses_2", data.id)
        end
    elseif data.category == "Cou" then
        if data.subCategory == "Cou" then
            TriggerEvent("skinchanger:change", "chain_1", data.id)
            TriggerEvent("skinchanger:change", "chain_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "chain_2", data.id)
        end
    elseif data.category == "Montre" then
        if data.subCategory == "Montre" then
            TriggerEvent("skinchanger:change", "watches_1", data.id)
            TriggerEvent("skinchanger:change", "watches_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "watches_2", data.id)
        end
    elseif data.category == "Oreilles" then
        if data.subCategory == "Oreilles" then
            TriggerEvent("skinchanger:change", "ears_1", data.id)
            TriggerEvent("skinchanger:change", "ears_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "ears_2", data.id)
        end
    elseif data.category == "Bracelet" then
        if data.subCategory == "Bracelet" then
            TriggerEvent("skinchanger:change", "bracelets_1", data.id)
            TriggerEvent("skinchanger:change", "bracelets_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "bracelets_2", data.id)
        end
    elseif data.category == "Masque" then
        if data.subCategory == "Masque" then
            TriggerEvent("skinchanger:change", "mask_1", data.id)
            TriggerEvent("skinchanger:change", "mask_2", 0)
        elseif data.subCategory == "Variations" then
            TriggerEvent("skinchanger:change", "mask_2", data.id)
        end
    end
end)

RegisterNuiCallback("CreationPersonnageBackToMain", function(data)
    if lastOnglet ~= "vetements" then
        VFW.Cam:Update("cam_creator", Config.CharCreator[1])
    else
        VFW.Cam:Update("cam_creator", Config.CharCreator[6])
    end
end)

RegisterNuiCallback("CreationPersonnageClickBouton", function(data)
    if data == "Hauts" then
        VFW.Cam:Update("cam_creator", Config.CharCreator[6])
    elseif data == "Sous-hauts" then
        VFW.Cam:Update("cam_creator", Config.CharCreator[6])
    elseif data == "Bras" then
        VFW.Cam:Update("cam_creator", Config.CharCreator[6])
    elseif data == "Bas" then
        VFW.Cam:Update("cam_creator", Config.CharCreator[7])
    elseif data == "Chaussures" then
        VFW.Cam:Update("cam_creator", Config.CharCreator[8])
    elseif data == "Chapeaux" or data == "Lunettes" or data == "Cou" or data == "Masque" or data == "Oreilles" then
        VFW.Cam:Update("cam_creator", Config.CharCreator[9])
    elseif data == "Montre" or data == "Bracelet" then
        VFW.Cam:Update("cam_creator", Config.CharCreator[6])
    end
end)

RegisterNuiCallback("CreationPersonnageMouseMove", function(data)
    local playerPed = PlayerPedId()

    if data.moveCamera == 1 then
        SetEntityHeading(playerPed, GetEntityHeading(playerPed) + 3.0)
    else
        SetEntityHeading(playerPed, GetEntityHeading(playerPed) - 3.0)
    end
end)

RegisterNuiCallback("CreationPersonnageMouseZoom", function(data)
    local direction = data.direction
    local cam = VFW.Cam:Get("cam_creator")

    if cam then
        local currentFov = GetCamFov(cam)
        local newFov = currentFov + (direction * 2.0)

        if newFov < 10.0 then
            newFov = 10.0
        elseif newFov > 70.0 then
            newFov = 70.0
        end

        SetCamFov(cam, newFov)
    end
end)

local lastIdentityCharacterChoice = nil
RegisterNuiCallback("nui:char-creator:identity", function(data)
    local dataIdentity = data.newData

    if dataIdentity and dataIdentity ~= nil then
        -- Mise a jour des champs legers (toujours)
        firstName = capitalizeWords(dataIdentity.firstName)
        lastName = capitalizeWords(dataIdentity.lastName)
        dateOfBirthdayr = dataIdentity.birthDate
        sex = dataIdentity.sex
        birthplace = capitalizeWords(dataIdentity.birthPlace)
        height = dataIdentity.height or 175

        -- Le rechargement de skin / catalogues est tres lourd (~ -90 FPS).
        -- On ne le fait QUE quand le sexe change reellement, pas a chaque keystroke.
        if dataIdentity.characterChoice == lastIdentityCharacterChoice then
            return
        end
        lastIdentityCharacterChoice = dataIdentity.characterChoice

        -- Reset PED cache when changing character type to allow proper reloading
        lastLoadedPedId = nil

        if dataIdentity.characterChoice == "men" then
            TypePed = 0
            TriggerEvent('skinchanger:loadSkin', {
                sex          = 0,
                tshirt_1     = 15,
                tshirt_2     = 0,
                torso_1      = 15,
                torso_2      = 0,
                arms         = 15,
                arms_2       = 0,
                pants_1      = 21,
                pants_2      = 0,
                shoes_1      = 34,
                shoes_2      = 0,
                chain_1      = 0,
                chain_2      = 0,
                helmet_1     = -1,
                helmet_2     = 0,
                ears_1       = -1,
                ears_2       = 0,
                glasses_1    = 0,
                glasses_2    = 0,
                mask_1       = 0,
                mask_2       = 0,
                bproof_1     = 0,
                bproof_2     = 0,
                bags_1       = 0,
                bags_2       = 0,
                decals_1     = 0,
                decals_2     = 0,
                watches_1    = -1,
                watches_2    = 0,
                bracelets_1  = -1,
                bracelets_2  = 0,
                face         = 0,
                skin         = 0,
                age_1        = 0,
                age_2        = 0,
                beard_1      = 0,
                beard_2      = 0,
                beard_3      = 0,
                beard_4      = 0,
                hair_1       = 0,
                hair_2       = 0,
                hair_color_1 = 0,
                hair_color_2 = 0,
                eye_color    = 0,
                eyebrows_1   = 0,
                eyebrows_2   = 0,
                eyebrows_3   = 0,
                eyebrows_4   = 0,
                makeup_1     = 0,
                makeup_2     = 0,
                makeup_3     = 0,
                makeup_4     = 0,
                lipstick_1   = 0,
                lipstick_2   = 0,
                lipstick_3   = 0,
                lipstick_4   = 0,
                chest_1      = 0,
                chest_2      = 0,
                chest_3      = 0,
                chest_4      = 0,
                bodyb_1      = 0,
                bodyb_2      = 0
            })
            LoadDataForCreator(0)
        elseif dataIdentity.characterChoice == "women" then
            TypePed = 1
            TriggerEvent('skinchanger:loadSkin', {
                sex          = 1,
                tshirt_1     = 14,
                tshirt_2     = 0,
                torso_1      = 15,
                torso_2      = 0,
                arms         = 15,
                arms_2       = 0,
                pants_1      = 15,
                pants_2      = 0,
                shoes_1      = 35,
                shoes_2      = 0,
                chain_1      = 0,
                chain_2      = 0,
                helmet_1     = -1,
                helmet_2     = 0,
                ears_1       = -1,
                ears_2       = 0,
                glasses_1    = -1,
                glasses_2    = 0,
                mask_1       = 0,
                mask_2       = 0,
                bproof_1     = 0,
                bproof_2     = 0,
                bags_1       = 0,
                bags_2       = 0,
                decals_1     = 0,
                decals_2     = 0,
                watches_1    = -1,
                watches_2    = 0,
                bracelets_1  = -1,
                bracelets_2  = 0,
                face         = 0,
                skin         = 0,
                age_1        = 0,
                age_2        = 0,
                beard_1      = 0,
                beard_2      = 0,
                beard_3      = 0,
                beard_4      = 0,
                hair_1       = 0,
                hair_2       = 0,
                hair_color_1 = 0,
                hair_color_2 = 0,
                eye_color    = 0,
                eyebrows_1   = 0,
                eyebrows_2   = 0,
                eyebrows_3   = 0,
                eyebrows_4   = 0,
                makeup_1     = 0,
                makeup_2     = 0,
                makeup_3     = 0,
                makeup_4     = 0,
                lipstick_1   = 0,
                lipstick_2   = 0,
                lipstick_3   = 0,
                lipstick_4   = 0,
                chest_1      = 0,
                chest_2      = 0,
                chest_3      = 0,
                chest_4      = 0,
                bodyb_1      = 0,
                bodyb_2      = 0
            })
            LoadDataForCreator(1)
        elseif dataIdentity.characterChoice == "custom" then
            TypePed = 2
            TriggerEvent("skinchanger:loadSkin", { sex = 2 })
            LoadVariationForPed(2)
        end
    end
end)

---Handle SkinChange
---@param key any
---@param value any
---@param lastValue any
---@param scale any
---@return any
local function handleSkinChange(key, value, lastValue, scale)
    if value ~= nil and value ~= lastValue then
        local finalVal = scale and (value * scale) or value
        TriggerEvent("skinchanger:change", key, finalVal)
        return value
    end

    return lastValue
end

RegisterNuiCallback("nui:char-creator:character", function(data)
    if data.newData then
        local character = data.newData

        newP1 = handleSkinChange("mom", character.parent1, newP1)
        newP2 = handleSkinChange("dad", character.parent2, newP2)
        lastSkinValue = handleSkinChange("skin_md_weight", character.skinValue, lastSkinValue, 100)
        lastlookingValue = handleSkinChange("face_md_weight", character.lookingValue, lastlookingValue, 100)
    end
end)

---Handle VisageChange
---@param key any
---@param value any
---@param lastValue any
---@param scale any
---@return any
local function handleVisageChange(key, value, lastValue, scale)
    if value ~= nil and value ~= lastValue then
        TriggerEvent("skinchanger:change", key, scale and (value * scale) or (value / 10))
        return value
    end

    return lastValue
end

RegisterNuiCallback("nui:char-creator:visage", function(data)
    if data.newData then
        local visage = data.newData

        lastnoseX = handleVisageChange("nose_1", visage.nose and visage.nose.x, lastnoseX, 10)
        lastnoseY = handleVisageChange("nose_2", visage.nose and visage.nose.y, lastnoseY, 10)

        local nosePointeX = visage.nosePointe and visage.nosePointe.x
        local nosePointeY = visage.nosePointe and visage.nosePointe.y
        if nosePointeX then
            nosePointeX = -nosePointeX
        end

        lastnosePointeX = handleVisageChange("nose_5", nosePointeX, lastnosePointeX, 10)
        lastnosePointeY = handleVisageChange("nose_6", nosePointeY, lastnosePointeY, 10)

        local noseProfileX = visage.noseProfile and visage.noseProfile.x
        local noseProfileY = visage.noseProfile and visage.noseProfile.y
        if noseProfileX then
            noseProfileX = -noseProfileX
        end

        lastnoseProfileX = handleVisageChange("nose_3", noseProfileX, lastnoseProfileX, 10)
        lastnoseProfileY = handleVisageChange("nose_4", noseProfileY, lastnoseProfileY, 10)

        -- Eyebrows: NUI X/Y mappés sur eyebrows_6/eyebrows_5 (axes inversés côté GTA)
        local sourcilsX = visage.sourcils and visage.sourcils.x
        local sourcilsY = visage.sourcils and visage.sourcils.y
        lastSourcilsX = handleVisageChange("eyebrows_6", sourcilsX, lastSourcilsX, 10)
        lastSourcilsY = handleVisageChange("eyebrows_5", sourcilsY, lastSourcilsY, 10)

        local pommettesX = visage.pommettes and visage.pommettes.y -- Y devient X
        local pommettesY = visage.pommettes and visage.pommettes.x -- X devient Y
        if pommettesY then
            pommettesY = -pommettesY
        end

        lastpommettesX = handleVisageChange("cheeks_1", pommettesX, lastpommettesX, 10)
        lastpommettesY = handleVisageChange("cheeks_2", pommettesY, lastpommettesY, 10)

        -- Chin: NUI X/Y mappés sur chin_2/chin_1 (axes inversés côté GTA)
        local mentonX = visage.menton and visage.menton.x
        local mentonY = visage.menton and visage.menton.y
        lastMentonX = handleVisageChange("chin_2", mentonX, lastMentonX, 10)
        lastMentonY = handleVisageChange("chin_1", mentonY, lastMentonY, 10)

        local mentonShapeX = visage.mentonShape and visage.mentonShape.x
        local mentonShapeY = visage.mentonShape and visage.mentonShape.y
        if mentonShapeY then
            mentonShapeY = -mentonShapeY
        end

        if mentonShapeX then
            mentonShapeX = -mentonShapeX
        end

        lastMentonShapeX = handleVisageChange("chin_3", mentonShapeX, lastMentonShapeX, 10)
        lastMentonShapeY = handleVisageChange("chin_4", mentonShapeY, lastMentonShapeY, 10)

        local machoireX = visage.machoire and visage.machoire.x
        if machoireX then
            machoireX = -machoireX
        end

        lastMachoireX = handleVisageChange("jaw_1", machoireX, lastMachoireX, 10)
        lastMachoireY = handleVisageChange("jaw_2", visage.machoire and visage.machoire.y, lastMachoireY, 10)

        lastCou = handleVisageChange("neck_thickness", visage.cou, lastCou, 0.1)
        lastlevres = handleVisageChange("lip_thickness", visage.levres, lastlevres, 0.1)
        lastjoues = handleVisageChange("cheeks_3", visage.joues, lastjoues, 0.1)
        lastyeux = handleVisageChange("eye_squint", visage.yeux, lastyeux, 0.1)
    end
end)

--- applyChange
---@param field any
---@param value any
---@param oldValue any
---@param itemIdAdjust number|string
---@return any
local function applyChange(field, value, oldValue, itemIdAdjust)
    if value ~= nil and value ~= oldValue then
        TriggerEvent("skinchanger:change", field, value - (itemIdAdjust or 0))
        return value
    end

    return oldValue
end

--- applyColorChange
---@param field any
---@param value any
---@param oldValue any
---@param opacityAdjust any
---@return any
local function applyColorChange(field, value, oldValue, opacityAdjust)
    if value ~= nil and value ~= oldValue then
        local adjustedValue = (opacityAdjust and opacityAdjust ~= 0) and (value / opacityAdjust) or value
        TriggerEvent("skinchanger:change", field, adjustedValue)
        return value
    end

    return oldValue
end

RegisterNuiCallback("nui:char-creator:apparence", function(data)
    if data.newData ~= nil then
        local apparence = data.newData
        local playerType = temporaryDatas.playerType

        if apparence.hair ~= nil then
            oldHair = applyChange("hair_1", apparence.hair.item.id, oldHair)
            oldColor1 = applyColorChange("hair_color_1", apparence.hair.color1, oldColor1)
            oldColor2 = applyColorChange("hair_color_2", apparence.hair.color2, oldColor2)
        end

        if apparence.beard ~= nil and playerType == "Homme" then
            oldBeard = applyChange("beard_1", apparence.beard.item.id, oldBeard, 1)
            oldColorbeard1 = applyColorChange("beard_3", apparence.beard.color1, oldColorbeard1)
            if oldColorbeard2 == nil then
                TriggerEvent('skinchanger:change', "beard_2", 10)
            end

            oldColorbeard2 = applyColorChange("beard_2", apparence.beard.opacity, oldColorbeard2, 10)
        end

        if apparence.sourcils ~= nil then
            oldsourcils = applyChange("eyebrows_1", apparence.sourcils.item.id, oldsourcils)
            oldColorsourcils1 = applyColorChange("eyebrows_3", apparence.sourcils.color1, oldColorsourcils1)
            oldColorsourcils2 = applyColorChange("eyebrows_4", apparence.sourcils.color2, oldColorsourcils2)
            if oldColorsourcils3 == nil then
                TriggerEvent('skinchanger:change', "eyebrows_2", 10)
            end

            oldColorsourcils3 = applyColorChange("eyebrows_2", apparence.sourcils.opacity, oldColorsourcils3, 10)
        end

        if apparence.eyebrows ~= nil then
            oldsourcils = applyChange("eyebrows_1", apparence.eyebrows.item.id, oldsourcils)
            oldColorsourcils1 = applyColorChange("eyebrows_3", apparence.eyebrows.color1, oldColorsourcils1)
            oldColorsourcils2 = applyColorChange("eyebrows_4", apparence.eyebrows.color2, oldColorsourcils2)
            if oldColorsourcils3 == nil then
                TriggerEvent('skinchanger:change', "eyebrows_2", 10)
            end

            oldColorsourcils3 = applyColorChange("eyebrows_2", apparence.eyebrows.opacity, oldColorsourcils3, 10)
        end

        if apparence.pilosite ~= nil and playerType == "Homme" then
            oldpilosite = applyChange("chest_1", apparence.pilosite.item.id, oldpilosite)
            oldColorpilosite1 = applyColorChange("chest_3", apparence.pilosite.color1, oldColorpilosite1)
            if oldColorpilosite3 == nil then
                TriggerEvent('skinchanger:change', "chest_2", 10)
            end

            oldColorpilosite3 = applyColorChange("chest_2", apparence.pilosite.opacity, oldColorpilosite3, 10)
        end

        if apparence.eyes ~= nil then
            ColorEyes = applyChange("eye_color", apparence.eyes.color1, ColorEyes)
        end

        if apparence.eyesmaquillage ~= nil then
            oldeyesmaquillage = applyChange("makeup_1", apparence.eyesmaquillage.item.id, oldeyesmaquillage, 1)
            oldColoreyesmaquillage1 = applyColorChange("makeup_3", apparence.eyesmaquillage.color1,
                oldColoreyesmaquillage1)
            oldColoreyesmaquillage2 = applyColorChange("makeup_4", apparence.eyesmaquillage.color2,
                oldColoreyesmaquillage2)
            if oldColoreyesmaquillage3 == nil then
                TriggerEvent('skinchanger:change', "makeup_2", 10)
            end

            oldColoreyesmaquillage3 = applyColorChange("makeup_2", apparence.eyesmaquillage.opacity,
                oldColoreyesmaquillage3, 10)
        end

        if apparence.eye_makeup ~= nil then
            oldeyesmaquillage = applyChange("makeup_1", apparence.eye_makeup.item.id, oldeyesmaquillage, 1)
            oldColoreyesmaquillage1 = applyColorChange("makeup_3", apparence.eye_makeup.color1, oldColoreyesmaquillage1)
            oldColoreyesmaquillage2 = applyColorChange("makeup_4", apparence.eye_makeup.color2, oldColoreyesmaquillage2)
            if oldColoreyesmaquillage3 == nil then
                TriggerEvent('skinchanger:change', "makeup_2", 10)
            end

            oldColoreyesmaquillage3 = applyColorChange("makeup_2", apparence.eye_makeup.opacity, oldColoreyesmaquillage3,
                10)
        end

        if apparence.fard ~= nil then
            oldfard = applyChange("blush_1", apparence.fard.item.id, oldfard, 1)
            oldColorfard1 = applyColorChange("blush_3", apparence.fard.color1, oldColorfard1)
            if oldColorfard3 == nil then
                TriggerEvent('skinchanger:change', "blush_2", 10)
            end

            oldColorfard3 = applyColorChange("blush_2", apparence.fard.opacity, oldColorfard3, 10)
        end

        if apparence.rougealevre ~= nil then
            oldrougealevre = applyChange("lipstick_1", apparence.rougealevre.item.id, oldrougealevre, 1)
            oldColorrougealevre1 = applyColorChange("lipstick_3", apparence.rougealevre.color1, oldColorrougealevre1)
            if oldColorrougealevre3 == nil then
                TriggerEvent('skinchanger:change', "lipstick_2", 10)
            end

            oldColorrougealevre3 = applyColorChange("lipstick_2", apparence.rougealevre.opacity, oldColorrougealevre3, 10)
        end

        if apparence.lips_makeup ~= nil then
            oldrougealevre = applyChange("lipstick_1", apparence.lips_makeup.item.id, oldrougealevre, 1)
            oldColorrougealevre1 = applyColorChange("lipstick_3", apparence.lips_makeup.color1, oldColorrougealevre1)
            if oldColorrougealevre3 == nil then
                TriggerEvent('skinchanger:change', "lipstick_2", 10)
            end

            oldColorrougealevre3 = applyColorChange("lipstick_2", apparence.lips_makeup.opacity, oldColorrougealevre3, 10)
        end

        if apparence.taches ~= nil then
            oldtaches = applyChange("bodyb_1", apparence.taches.item.id, oldtaches)
            if oldOpacityTache == nil then
                TriggerEvent('skinchanger:change', "bodyb_2", 10)
            end

            oldOpacityTache = applyColorChange("bodyb_2", apparence.taches.opacity, oldOpacityTache, 10)
        end

        if apparence.marques ~= nil then
            oldmarques = applyChange("age_1", apparence.marques.item.id, oldmarques)
            if oldOpacityMarque == nil then
                TriggerEvent('skinchanger:change', "age_2", 10)
            end

            oldOpacityMarque = applyColorChange("age_2", apparence.marques.opacity, oldOpacityMarque, 10)
        end

        if apparence.acne ~= nil then
            oldacne = applyChange("blemishes_1", apparence.acne.item.id, oldacne)
            if oldOpacityAcne == nil then
                TriggerEvent('skinchanger:change', "blemishes_2", 10)
            end

            oldOpacityAcne = applyColorChange("blemishes_2", apparence.acne.opacity, oldOpacityAcne, 10)
        end

        if apparence.rousseur ~= nil then
            oldrousseur = applyChange("moles_1", apparence.rousseur.item.id, oldrousseur)
            if oldOpacityrousseur == nil then
                TriggerEvent('skinchanger:change', "moles_2", 10)
            end

            oldOpacityrousseur = applyColorChange("moles_2", apparence.rousseur.opacity, oldOpacityrousseur, 10)
        end

        if apparence.teint ~= nil then
            oldteint = applyChange("complexion_1", apparence.teint.item.id, oldteint)
            if oldOpacityTeint == nil then
                TriggerEvent('skinchanger:change', "complexion_2", 10)
            end

            oldOpacityTeint = applyColorChange("complexion_2", apparence.teint.opacity, oldOpacityTeint, 10)
        end

        if apparence.cicatrice ~= nil then
            oldcicatrice = applyChange("sun_1", apparence.cicatrice.item.id, oldcicatrice)
            if oldOpacityCicatrice == nil then
                TriggerEvent('skinchanger:change', "sun_2", 10)
            end

            oldOpacityCicatrice = applyColorChange("sun_2", apparence.cicatrice.opacity, oldOpacityCicatrice, 10)
        end
    end
end)

RegisterNuiCallback("nui:char-creator:ped", function(data)
    local dataPed = data.newData and data.newData.selectedPled
    local playerPed = PlayerPedId()

    if dataPed and dataPed.id then
        -- Ne recharger que si le PED a vraiment changé (évite les appels répétés coûteux)
        if lastLoadedPedId ~= dataPed.id then
            lastLoadedPedId = dataPed.id
            TriggerEvent("skinchanger:change", "sex", dataPed.id + 1)
            LoadVariationForPed(dataPed.id + 1)
        end
    end

    if data.newData and data.newData.ped and data.newData.ped.physique then
        local physique = data.newData.ped.physique

        if physique.visage ~= nil then
            if physique.visage.type.category == "visage" then
                SetPedComponentVariation(playerPed, 0, physique.visage.type.id, physique.visage.color.id)
                TriggerEvent("skinchanger:changeNoEffect", "head", physique.visage.type.id)
            end

            if physique.visage.color.category == "visage" then
                SetPedComponentVariation(playerPed, 0, physique.visage.type.id, physique.visage.color.id)
                TriggerEvent("skinchanger:changeNoEffect", "mask_1", physique.visage.color.id)
            end
        end

        if physique.haut ~= nil then
            if physique.haut.type.category == "haut" then
                SetPedComponentVariation(playerPed, 3, physique.haut.type.id, physique.haut.color.id)
                TriggerEvent("skinchanger:changeNoEffect", "arms", physique.haut.type.id)
            end

            if physique.haut.color.category == "haut" then
                SetPedComponentVariation(playerPed, 3, physique.haut.type.id, physique.haut.color.id)
                TriggerEvent("skinchanger:changeNoEffect", "arms_2", physique.haut.color.id)
            end
        end

        if physique.bas ~= nil then
            if physique.bas.type.category == "bas" then
                SetPedComponentVariation(playerPed, 4, physique.bas.type.id, physique.bas.color.id)
                TriggerEvent("skinchanger:changeNoEffect", "pants_1", physique.bas.type.id)
            end

            if physique.bas.color.category == "bas" then
                SetPedComponentVariation(playerPed, 4, physique.bas.type.id, physique.bas.color.id)
                TriggerEvent("skinchanger:changeNoEffect", "pants_2", physique.bas.color.id)
            end
        end

        if physique.chaussure ~= nil then
            if physique.chaussure.type.category == "chaussure" then
                SetPedComponentVariation(playerPed, 6, physique.chaussure.type.id, physique.chaussure.color.id)
                TriggerEvent("skinchanger:changeNoEffect", "shoes_1", physique.chaussure.type.id)
            end

            if physique.chaussure.color.category == "chaussure" then
                SetPedComponentVariation(playerPed, 6, physique.chaussure.type.id, physique.chaussure.color.id)
                TriggerEvent("skinchanger:changeNoEffect", "shoes_2", physique.chaussure.color.id)
            end
        end
    end
end)

RegisterNuiCallback("nui:char-creator:back-to-outfit", function(data)
    if not data.origin then
        return
    end

    local animations = {
        Hauts = { emote = "tryclothes2" },
        Bas = { emote = "tryclothes" },
        Chaussures = { emote = "tryclothes3" }
    }

    local animData = animations[data.origin]

    if animData then
        EmoteCancel()
        Wait(100)
        EmoteCommandStart(animData.emote, PlayerPedId())
    end
end)

RegisterNuiCallback("CreationPersonnage", function(data)
    local playerPed = PlayerPedId()
    local onglet = data.onglet

    if not onglet then
        return
    end

    local cam_positions = {
        vetements = 6,
        ["identité"] = 1,
        personnage = 1,
        visage = 1,
        apparence = 1,
    }

    local animations = {
        ["identité"] = "idle",
        personnage = "idle5",
        visage = "idle5",
        apparence = "idle5",
        vetements = "idle6",
    }

    lastOnglet = onglet

    if cam_positions[onglet] then
        local cam_name = "cam_creator"

        if VFW.Cam:Get(cam_name) then
            VFW.Cam:Destroy(cam_name)
        end

        VFW.Cam:Create(cam_name, Config.CharCreator[cam_positions[onglet]])

        local pos = Config.CharCreator[cam_positions[onglet]].COH
        SetEntityCoords(playerPed, pos.x, pos.y, pos.z - 1)
        SetEntityHeading(playerPed, pos.w)
    end

    if animations[onglet] then
        EmoteCancel()
        Wait(100)
        EmoteCommandStart(animations[onglet], playerPed)
    end
end)

RegisterNuiCallback("nui:char-creator:update-all", function(data)
    local playerPed = PlayerPedId()
    if not data then
        console.debug("Erreur : Données du personnage manquantes ou invalides.")
        return
    end

    local characters = TriggerServerCallback('core:server:characterCreator')

    if not characters or #characters == 0 then
        console.debug("Aucun personnage trouvé sur le serveur.")
        return
    end

    local found = false

    for i = 1, #characters do
        local character = characters[i]
        if character.firstname == data.lastName and character.lastname == data.firstName then
            local skin = character.skin
            TriggerEvent("skinchanger:loadSkin", {
                sex            = skin.sex,
                mom            = skin.mom,
                dad            = skin.dad,
                face_md_weight = skin.face_md_weight,
                skin_md_weight = skin.skin_md_weight,
                nose_1         = skin.nose_1,
                nose_2         = skin.nose_2,
                nose_3         = skin.nose_3,
                nose_4         = skin.nose_4,
                nose_5         = skin.nose_5,
                nose_6         = skin.nose_6,
                cheeks_1       = skin.cheeks_1,
                cheeks_2       = skin.cheeks_2,
                cheeks_3       = skin.cheeks_3,
                lip_thickness  = skin.lip_thickness,
                jaw_1          = skin.jaw_1,
                jaw_2          = skin.jaw_2,
                chin_1         = skin.chin_1,
                chin_2         = skin.chin_2,
                chin_3         = skin.chin_3,
                chin_4         = skin.chin_4,
                neck_thickness = skin.neck_thickness,
                age_1          = skin.age_1,
                age_2          = skin.age_2,
                beard_1        = skin.beard_1,
                beard_2        = skin.beard_2,
                beard_3        = skin.beard_3,
                beard_4        = skin.beard_4,
                hair_1         = skin.hair_1,
                hair_2         = skin.hair_2,
                hair_color_1   = skin.hair_color_1,
                hair_color_2   = skin.hair_color_2,
                eye_color      = skin.eye_color,
                eye_squint     = skin.eye_squint,
                eyebrows_1     = skin.eyebrows_1,
                eyebrows_2     = skin.eyebrows_2,
                eyebrows_3     = skin.eyebrows_3,
                eyebrows_4     = skin.eyebrows_4,
                eyebrows_5     = skin.eyebrows_5,
                eyebrows_6     = skin.eyebrows_6,
                makeup_1       = skin.makeup_1,
                makeup_2       = skin.makeup_2,
                makeup_3       = skin.makeup_3,
                makeup_4       = skin.makeup_4,
                lipstick_1     = skin.lipstick_1,
                lipstick_2     = skin.lipstick_2,
                lipstick_3     = skin.lipstick_3,
                lipstick_4     = skin.lipstick_4,
                blemishes_1    = skin.blemishes_1,
                blemishes_2    = skin.blemishes_2,
                blush_1        = skin.blush_1,
                blush_2        = skin.blush_2,
                blush_3        = skin.blush_3,
                complexion_1   = skin.complexion_1,
                complexion_2   = skin.complexion_2,
                sun_1          = skin.sun_1,
                sun_2          = skin.sun_2,
                moles_1        = skin.moles_1,
                moles_2        = skin.moles_2,
                chest_1        = skin.chest_1,
                chest_2        = skin.chest_2,
                chest_3        = skin.chest_3,
                bodyb_1        = skin.bodyb_1,
                bodyb_2        = skin.bodyb_2,
                bodyb_3        = skin.bodyb_3,
                bodyb_4        = skin.bodyb_4,

                tshirt_1       = skin.sex == 0 and 15 or 14,
                tshirt_2       = 0,
                torso_1        = 15,
                torso_2        = 0,
                arms           = 15,
                arms_2         = 0,
                pants_1        = 21,
                pants_2        = 0,
                shoes_1        = skin.sex == 0 and 34 or 35,
                shoes_2        = 0,
                chain_1        = 0,
                chain_2        = 0,
                helmet_1       = -1,
                helmet_2       = 0,
                ears_1         = -1,
                ears_2         = 0,
                glasses_1      = -1,
                glasses_2      = 0,
                mask_1         = 0,
                mask_2         = 0,
                bproof_1       = 0,
                bproof_2       = 0,
                bags_1         = 0,
                bags_2         = 0,
                decals_1       = 0,
                decals_2       = 0,
                watches_1      = -1,
                watches_2      = 0,
                bracelets_1    = -1,
                bracelets_2    = 0,
            })

            ClearPedDecorations(playerPed)

            TypePed = skin.sex
            LoadDataForCreator(skin.sex)

            ---@class lastTattoos
            lastTattoos = {}

            for _, tattoo in pairs(character.tattoos) do
                ApplyPedOverlay(playerPed, joaat(tattoo.Collection), joaat(tattoo.HashName))
                table.insert(lastTattoos, {
                    Collection = tattoo.Collection,
                    Hash = tattoo.HashName
                })
            end

            local emotesList = { "idle", "idle2", "idle6" }
            local emote = emotesList[VFW.Math.Random(1, #emotesList)]
            EmoteCancel()
            Wait(100)
            EmoteCommandStart(emote, playerPed)
            found = true
            break
        end
    end

    if not found then
        console.debug("Aucun personnage correspondant trouvé pour :", data.firstName, data.lastName)
    end
end)

local blockControls = true
local spawnPoint = nil

--- Thread
---@param state any
local function Thread(state)
    blockControls = state

    if not state then
        creatorActive = false
        TriggerEvent("pma-voice:toggleUi", true)
    end

    if blockControls then
        CreateThread(function()
            while blockControls do
                Wait(0)
                DisableAllControlActions(0)
            end
        end)
    end
end

---Load ingPrompt
---@param loadingText string
---@param spinnerType any
local function LoadingPrompt(loadingText, spinnerType)
    if BusyspinnerIsOn() then
        BusyspinnerOff()
    end

    if (loadingText == nil) then
        BeginTextCommandBusyString(nil)
    else
        BeginTextCommandBusyString("STRING");
        AddTextComponentSubstringPlayerName(loadingText);
    end

    EndTextCommandBusyString(spinnerType)
end

--- screenShot
local function screenShot()
    local playerPed = PlayerPedId()
    NetworkOverrideClockTime(17, 0, 0)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')

    SetPedComponentVariation(playerPed, 7, 0, 0, 2)
    ClearPedProp(playerPed, 0)
    ClearPedProp(playerPed, 1)

    Thread(true)

    TriggerEvent("skinchanger:getSkin", function(skin)
        if skin.sex == 1 then
            SetPedComponentVariation(playerPed, 6, 34, 0, 2)
        else
            SetPedComponentVariation(playerPed, 6, 35, 0, 2)
        end
    end)

    LoadingPrompt("Mugshot en cours...", 2)

    Wait(5000)

    exports['screenshot-basic']:requestScreenshot(function(data)
        SendNUIMessage({
            action = "nui:uploadMugshotFm",
            data = data
        })
    end)
end

local fastMugshot = {
    active = false,
    identityData = nil,
    onComplete = nil
}

--- captureFastMugshot - Silent and fast mugshot capture for character creation with green screen
local function captureFastMugshot(callback)
    isInMugshot = true

    local playerPed = PlayerPedId()
    local origCoords = GetEntityCoords(playerPed)
    local origHeading = GetEntityHeading(playerPed)

    local mugshotPos = MUGSHOT_CAM_CONFIG.COH
    RequestCollisionAtCoord(mugshotPos.x, mugshotPos.y, mugshotPos.z)
    placeMugshotPed(playerPed, mugshotPos)

    -- Sauvegarder le temps et la météo actuels pour restauration après capture
    local savedHour = VFW.currentHour or 12
    local savedMinute = VFW.currentMinute or 0
    local savedWeather = GlobalState.EnvironmentWeather or VFW.currentWeather or "EXTRASUNNY"

    -- SEUL AJOUT: fond vert
    startGreenScreenThread(vector3(mugshotPos.x, mugshotPos.y, mugshotPos.z), mugshotPos.w)

    -- Clean appearance for mugshot
    SetPedComponentVariation(playerPed, 7, 0, 0, 2)
    ClearPedProp(playerPed, 0)
    ClearPedProp(playerPed, 1)

    local savedSkin = nil
    TriggerEvent("skinchanger:getSkin", function(skin)
        savedSkin = skin -- Sauvegarder le skin complet pour restauration après capture
        if skin.sex == 1 then
            SetPedComponentVariation(playerPed, 6, 35, 0, 2)
        else
            SetPedComponentVariation(playerPed, 6, 34, 0, 2)
        end
    end)

    SetEntityVisible(playerPed, true, false)

    VFW.Cam:Create('cam_mugshot_fast', MUGSHOT_CAM_CONFIG)
    beginMugshotPose(PlayerPedId(), mugshotPos)
    VFW.Nui.HudVisible(false)

    -- Afficher le cadre photo booth
    SendNUIMessage({
        action = "nui:photobooth:visible",
        data = true
    })

    Wait(6000) -- Temps pour lire les informations et se préparer

    -- Cacher le cadre photo booth avant la capture
    SendNUIMessage({
        action = "nui:photobooth:visible",
        data = false
    })

    Wait(100) -- Laisser l'UI disparaitre

    -- Passer en vert juste avant la capture
    setGreenScreenColor(0, 255, 0)
    Wait(0) -- Attendre une frame pour que le rendu soit vert

    exports['screenshot-basic']:requestScreenshot(function(data)
        -- Repasser en noir immédiatement
        setGreenScreenColor(0, 0, 0)

        -- Jouer le son d'appareil photo
        SendNUIMessage({
            action = "nui:photobooth:shutter"
        })

        -- Arrêter le fond vert
        stopGreenScreenThread()

        -- Restaurer immédiatement le temps et la météo originaux
        NetworkOverrideClockTime(savedHour, savedMinute, 0)
        SetWeatherTypeOvertimePersist(savedWeather, 0.0)

        VFW.Cam:Destroy('cam_mugshot_fast')
        endMugshotPose(playerPed)
        VFW.Nui.HudVisible(true)

        -- Restaurer l'apparence originale du joueur (accessoires, chaussures, etc.)
        if savedSkin then
            TriggerEvent("skinchanger:loadSkin", savedSkin)
        end

        SetEntityCoords(playerPed, origCoords.x, origCoords.y, origCoords.z, false, false, false, false)
        SetEntityHeading(playerPed, origHeading)

        isInMugshot = false

        SendNUIMessage({
            action = "nui:uploadMugshotFm",
            data = data
        })

        fastMugshot.onComplete = callback

        -- Safety timeout: si l'upload CDN ne répond pas en 30s, continuer sans mugshot
        SetTimeout(30000, function()
            if fastMugshot.active and fastMugshot.onComplete then
                console.warn("[Core:Mugshot] Upload timeout after 30s, continuing without mugshot")
                local onComplete = fastMugshot.onComplete
                fastMugshot.onComplete = nil
                fastMugshot.identityData = nil
                onComplete()
            end
        end)
    end)
end

-- Variable pour les mugshots externes (doit être déclarée avant l'export)
local externalMugshot = {
    active = false,
    callback = nil,
    onPhotoCaptured = nil -- Callback intermédiaire appelé après capture mais avant upload
}

-- Fonction globale pour permettre la capture de mugshot depuis d'autres scripts (ex: mairie)
-- Avec fadeout/fadein pour une transition fluide
-- @param onComplete function(success, url) - Callback appelé après l'upload
-- @param skipInitialFade boolean - Si true, ne fait pas le fade out initial (déjà fait par l'appelant)
-- @param onPhotoCaptured function() - Callback intermédiaire appelé après la capture mais avant l'upload
function CaptureFastMugshotWithCallback(onComplete, skipInitialFade, onPhotoCaptured)
    isInMugshot = true

    -- Marquer comme mugshot externe pour éviter le flow character creator
    externalMugshot.active = true
    externalMugshot.callback = onComplete
    externalMugshot.onPhotoCaptured = onPhotoCaptured

    -- Fadeout avant la téléportation (sauf si déjà fait par l'appelant)
    if not skipInitialFade then
        DoScreenFadeOut(500)
        Wait(500)
    end

    -- Masquer la map et le HUD pendant le photomaton
    DisplayRadar(false)
    DisplayHud(false)
    VFW.Nui.HudVisible(false)

    local playerPed = PlayerPedId()
    local origCoords = GetEntityCoords(playerPed)
    local origHeading = GetEntityHeading(playerPed)

    local mugshotPos = MUGSHOT_CAM_CONFIG.COH
    RequestCollisionAtCoord(mugshotPos.x, mugshotPos.y, mugshotPos.z)
    placeMugshotPed(playerPed, mugshotPos)

    -- Sauvegarder le temps et la météo actuels pour restauration après capture
    local savedHour = VFW.currentHour or 12
    local savedMinute = VFW.currentMinute or 0
    local savedWeather = GlobalState.EnvironmentWeather or VFW.currentWeather or "EXTRASUNNY"

    -- Fond vert
    startGreenScreenThread(vector3(mugshotPos.x, mugshotPos.y, mugshotPos.z), mugshotPos.w)

    -- Clean appearance for mugshot
    SetPedComponentVariation(playerPed, 7, 0, 0, 2)
    ClearPedProp(playerPed, 0)
    ClearPedProp(playerPed, 1)

    local savedSkin = nil
    TriggerEvent("skinchanger:getSkin", function(skin)
        savedSkin = skin -- Sauvegarder le skin complet pour restauration après capture
        if skin.sex == 1 then
            SetPedComponentVariation(playerPed, 6, 35, 0, 2)
        else
            SetPedComponentVariation(playerPed, 6, 34, 0, 2)
        end
    end)

    SetEntityVisible(playerPed, true, false)

    VFW.Cam:Create('cam_mugshot_fast', MUGSHOT_CAM_CONFIG)
    beginMugshotPose(PlayerPedId(), mugshotPos)

    -- Fadein une fois le joueur positionné
    Wait(200)
    DoScreenFadeIn(500)
    Wait(500)

    -- Afficher le cadre photo booth
    SendNUIMessage({
        action = "nui:photobooth:visible",
        data = true
    })

    Wait(6000) -- Temps pour lire les informations et se préparer

    -- Cacher le cadre photo booth avant la capture
    SendNUIMessage({
        action = "nui:photobooth:visible",
        data = false
    })

    Wait(100)

    -- Passer en vert juste avant la capture
    setGreenScreenColor(0, 255, 0)
    Wait(0) -- Attendre une frame pour que le rendu soit vert

    exports['screenshot-basic']:requestScreenshot(function(data)
        -- Repasser en noir immédiatement
        setGreenScreenColor(0, 0, 0)

        -- Jouer le son d'appareil photo
        SendNUIMessage({
            action = "nui:photobooth:shutter"
        })

        -- Fadeout avant de retourner à la position d'origine
        DoScreenFadeOut(500)
        Wait(500)

        stopGreenScreenThread()

        -- Restaurer immédiatement le temps et la météo originaux
        NetworkOverrideClockTime(savedHour, savedMinute, 0)
        SetWeatherTypeOvertimePersist(savedWeather, 0.0)

        VFW.Cam:Destroy('cam_mugshot_fast')
        endMugshotPose(playerPed)

        SetEntityCoords(playerPed, origCoords.x, origCoords.y, origCoords.z, false, false, false, false)
        SetEntityHeading(playerPed, origHeading)

        isInMugshot = false

        -- Fadein de retour
        Wait(200)
        DoScreenFadeIn(500)

        -- Restaurer la map et le HUD
        DisplayRadar(true)
        DisplayHud(true)
        VFW.Nui.HudVisible(true)

        -- Restaurer l'apparence originale du joueur (accessoires, chaussures, etc.)
        if savedSkin then
            TriggerEvent("skinchanger:loadSkin", savedSkin)
        end

        -- Notifier que la photo est prise (avant l'upload) pour permettre d'afficher un dialogue d'attente
        if externalMugshot.onPhotoCaptured then
            externalMugshot.onPhotoCaptured()
        end

        -- L'upload continue en arrière-plan
        SendNUIMessage({
            action = "nui:uploadMugshotFm",
            data = data
        })

        -- Le callback sera appelé dans nui:mugshotUploaded après l'upload
    end)
end

local redoMugshot = {
    active = false,
    limit = 1,
    coords = nil
}

local redoCloneOffline = {
    active      = false,
    charId      = nil,
    origCoords  = nil,
    origSkin    = nil,
    origTattoos = nil
}

local postCreationMugshot = {
    active = false
}


RegisterNuiCallback("nui:mugshotUploaded", function(data, cb)
    cb({})
    local url = data.url
    if not url or url == "" then
        console.error("[Core:Mugshot] Upload failed or empty URL, continuing with empty mugshot")
        url = ""
    end

    -- Handle fast mugshot: on injecte l'URL dans identityData AVANT de créer l'identité
    if fastMugshot.active then
        if fastMugshot.identityData then
            fastMugshot.identityData.mugshot = (url ~= "") and url or nil
        end

        local onComplete = fastMugshot.onComplete
        fastMugshot.active = false
        fastMugshot.onComplete = nil
        fastMugshot.identityData = nil
        VFW.Cam:Destroy('cam_mugshot_fast')

        if onComplete then
            onComplete()
        end
        return
    end

    Wait(1000)
    VFW.Cam:Destroy('cam_mugshot')

    if redoCloneOffline.active then
        TriggerServerEvent("vfw:server:setMugshotForChar", redoCloneOffline.charId, url)

        TriggerEvent('skinchanger:loadSkin', redoCloneOffline.origSkin)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            ClearPedDecorations(ped)
            for _, tat in ipairs(redoCloneOffline.origTattoos or {}) do
                if type(tat) == "table" and type(tat.Collection) == "string" and tat.Collection ~= ""
                    and type(tat.HashName) == "string" and tat.HashName ~= "" then
                    ApplyPedOverlay(ped, joaat(tat.Collection), joaat(tat.HashName))
                end
            end
        end

        SetEntityCoords(PlayerPedId(), redoCloneOffline.origCoords.x, redoCloneOffline.origCoords.y,
            redoCloneOffline.origCoords.z)

        redoCloneOffline = { active = false, charId = nil, origCoords = nil, origSkin = nil, origTattoos = nil }
        if BusyspinnerIsOn() then
            BusyspinnerOff()
        end

        EmoteCancel()
        Thread(false)
        TriggerServerEvent("core:server:instanceCreator", false)
        return
    end

    -- Handle post-creation mugshot (replacement after character creation)
    if postCreationMugshot.active then
        TriggerServerEvent("vfw:server:setMugshot", url)
        postCreationMugshot.active = false

        VFW.Cam:Destroy('cam_mugshot_fast')

        console.debug("Post-creation mugshot updated successfully")
        return
    end

    -- Handle external mugshot (mairie, etc.)
    if externalMugshot.active then
        local callback = externalMugshot.callback
        externalMugshot.active = false
        externalMugshot.callback = nil
        externalMugshot.onPhotoCaptured = nil

        if callback then
            callback(true, url)
        end

        return
    end

    if redoMugshot.active then
        TriggerServerEvent("vfw:server:setMugshot", url)
        SetEntityCoords(PlayerPedId(), redoMugshot.coords.x, redoMugshot.coords.y, redoMugshot.coords.z - 1)
        redoMugshot.active = false
        redoMugshot.coords = nil

        if BusyspinnerIsOn() then
            BusyspinnerOff()
        end

        EmoteCancel()
        Thread(false)
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
        TriggerEvent('skinchanger:loadSkin', skin)
        TriggerServerEvent("core:server:instanceCreator", false)
        return
    end

    -- Original mugshot flow (manual)
    local sex = nil

    if TypePed == 1 or sexPed == "women" then
        sex = "f"
    else
        sex = "m"
    end

    TriggerEvent("skinchanger:getSkin", function(skin)
        local identityData = {
            firstname = firstName,
            lastname = lastName,
            dateofbirth = dateOfBirthdayr,
            sex = sex,
            birthplace = birthplace,
            height = height or 175,
            skin = skin,
            mugshot = url,
            tattoos = lastTattoos or {}
        }

        TriggerEvent('skinchanger:loadSkin', skin or {})
        EmoteCancel()
        Thread(false)
        SpawnPlayerCharCreator(spawnPoint)
        TriggerServerEvent("core:server:instanceCreator", false)
        TriggerServerEvent("core:server:createIdentity", identityData)

        Wait(250)

    end)
end)

RegisterNuiCallback("nui:char-creator:spawnpoint", function(data)
    if data.spawnPoint ~= nil then
        EmoteCancel()
        creatorActive = false
        TriggerEvent("pma-voice:toggleUi", true)
        VFW.Nui.Creator(false)
        lastLoadedPedId = nil -- Reset du cache PED

        spawnPoint = data.spawnPoint.id

        -- Prepare character data
        local sex = nil
        if TypePed == 1 or sexPed == "women" then
            sex = "f"
        else
            sex = "m"
        end

        -- Prepare identity data for fast mugshot BEFORE fade
        TriggerEvent("skinchanger:getSkin", function(skin)
            fastMugshot.identityData = {
                firstname = firstName,
                lastname = lastName,
                dateofbirth = dateOfBirthdayr,
                sex = sex,
                birthplace = birthplace,
                height = height or 175,
                skin = skin,
                mugshot = nil, -- Will be filled when uploaded
                tattoos = lastTattoos or {}
            }

            fastMugshot.active = true
            local savedIdentityData = fastMugshot.identityData

            -- Capture mugshot BEFORE screen fade (so it's not white/black)
            captureFastMugshot(function()
                -- After mugshot is captured, now do the fade and spawn
                DoScreenFadeOut(500)
                Wait(500)

                TriggerServerEvent("core:server:createIdentity", savedIdentityData or fastMugshot.identityData)

                -- Start spawn process
                TriggerEvent('skinchanger:loadSkin', skin or {})
                EmoteCancel()
                Thread(false)
                SpawnPlayerCharCreator(spawnPoint)
                TriggerServerEvent("core:server:instanceCreator", false)

                Wait(250)

            end)
        end)

        temporaryDatas = {
            playerType = (sex == "F") and "Femme" or "Homme"
        }
    end
end)

RegisterNetEvent("core:client:spawnCharCreator", LoadNewCharCreator)


-- Tatouages actifs du joueur local (indépendant du ped handle qui change au switch sex/model)
local activeTattoos = { list = {} }
local MAX_TATTOOS_PER_ZONE = 3

-- Callback: añadir o quitar tatuaje (toggle)
RegisterNuiCallback("CreationPersonnageClickTattoo", function(data, cb)
    local playerPed = PlayerPedId()

    if not data or not data.Hash or not data.Collection then
        print("^1[ERROR] Datos inválidos en ClickTattoo:^7", json.encode(data))
        cb({ success = false, error = "No tattoo data" })
        return
    end

    local tattooKey = data.Collection .. ":" .. data.Hash
    local zone = data.zone

    if not activeTattoos.list then activeTattoos.list = {} end

    local exists = false
    local newList = {}
    local countInZone = 0

    for _, tattoo in ipairs(activeTattoos.list) do
        local key = tattoo.Collection .. ":" .. tattoo.Hash
        if key == tattooKey then
            exists = true
        else
            table.insert(newList, tattoo)
            -- Compter les tatouages de la même zone
            if zone and tattoo.zone and tattoo.zone == zone then
                countInZone = countInZone + 1
            end
        end
    end

    if exists then
        activeTattoos.list = newList
    else
        -- Vérifier la limite par zone avant d'ajouter
        if zone and countInZone >= MAX_TATTOOS_PER_ZONE then
            cb({ success = false, error = "Zone limit reached" })
            return
        end
        table.insert(newList, { Collection = data.Collection, Hash = data.Hash, zone = zone })
        activeTattoos.list = newList
    end

    ClearPedDecorations(playerPed)
    for _, tattoo in ipairs(activeTattoos.list) do
        AddPedDecorationFromHashes(playerPed, tattoo.Collection, tattoo.Hash)
    end
    lastTattoos = activeTattoos.list or {}
    cb({ success = true })
end)



-- Callback: quitar tatuaje específico
RegisterNuiCallback("CreationPersonnageRemoveTattoo", function(data, cb)
    local playerPed = PlayerPedId()

    if not data or not data.Collection or not data.Hash then
        print("^1[ERROR] Datos inválidos en RemoveTattoo:^7", json.encode(data))
        cb({ success = false })
        return
    end

    local collection = data.Collection
    local hash = data.Hash

    local newList = {}
    for _, tattoo in ipairs(activeTattoos.list or {}) do
        local key = tattoo.Collection .. ":" .. tattoo.Hash
        if not (tattoo.Collection == collection and tattoo.Hash == hash) then
            table.insert(newList, tattoo)
        else
        end
    end
    activeTattoos.list = newList

    ClearPedDecorations(playerPed)
    for _, tattoo in ipairs(activeTattoos.list) do
        AddPedDecorationFromHashes(playerPed, tattoo.Collection, tattoo.Hash)
    end
    lastTattoos = activeTattoos.list or {}
    cb({ success = true })
end)

-- Callback: limpiar todos los tatuajes
RegisterNuiCallback("CreationPersonnageClearTattoos", function(_, cb)
    local playerPed = PlayerPedId()
    ClearPedDecorations(playerPed)
    activeTattoos.list = {}
    cb({ success = true })
end)

RegisterNuiCallback("nui:char-creator:tatouages", function(data, cb)
    cb({ success = true })
end)

-- Callback: reaplicar todos los tatuajes guardados
RegisterNuiCallback("CreationPersonnageReapplyTattoos", function(data, cb)
    local playerPed = PlayerPedId()

    -- Si no hay lista en memoria, inicializa
    if not activeTattoos.list then
        activeTattoos.list = {}
    end

    -- Si NUI te manda una lista de tattoos, actualiza la memoria
    if data and data.tattoos then
        local newList = {}
        for _, tattoo in ipairs(data.tattoos) do
            table.insert(newList, { Collection = tattoo.Collection, Hash = tattoo.Hash })
        end
        activeTattoos.list = newList
    end

    -- Limpia y reaplica todos los tattoos activos
    ClearPedDecorations(playerPed)
    for _, tattoo in ipairs(activeTattoos.list) do
        AddPedDecorationFromHashes(playerPed, tattoo.Collection, tattoo.Hash)
    end

    cb({ success = true })
end)
