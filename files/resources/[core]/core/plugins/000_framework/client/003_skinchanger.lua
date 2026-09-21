---@meta _
---@diagnostic disable: duplicate-doc-field

local LastSex     = -1
local LoadSkin    = nil
local LoadClothes = nil
local Character   = {}
local maskGaz = false

for i = 1, #Components, 1 do
    Character[Components[i].name] = Components[i].value
end

---Load DefaultModel
---@param malePed boolean True for male, false for female
---@param cb function? Optional callback fired after model is set (or after failure)
function LoadDefaultModel(malePed, cb)
    local characterModel

    if malePed then
        characterModel = joaat('mp_m_freemode_01')
    else
        characterModel = joaat('mp_f_freemode_01')
    end

    CreateThread(function()
        local loaded = false
        for attempt = 1, 3 do
            RequestModel(characterModel)
            local timeout = GetGameTimer() + 15000
            while not HasModelLoaded(characterModel) do
                if GetGameTimer() > timeout then break end
                Wait(0)
            end
            if HasModelLoaded(characterModel) then
                loaded = true
                break
            end
            print(("[skinchanger] ^3Retry %d/3 for model %s^7"):format(attempt, characterModel))
        end

        if loaded and IsModelInCdimage(characterModel) and IsModelValid(characterModel) then
            SetPlayerModel(PlayerId(), characterModel)
            SetPedDefaultComponentVariation(PlayerPedId())
            SetModelAsNoLongerNeeded(characterModel)
            TriggerEvent('skinchanger:modelLoaded')
        else
            print(("[skinchanger] ^1Model loading FAILED after retries: %s^7"):format(characterModel))
        end

        if cb ~= nil then
            cb()
        end
    end)
end

---Get MaxVals
---@return any
function GetMaxVals()
    local playerPed = PlayerPedId()
    -- comptage vanilla + DLC + packs addon (collections), comme le magasin et le créateur
    local function nDraw(comp) return (VFW.PedDrawableCount and VFW.PedDrawableCount(playerPed, "clothing", comp)) or GetNumberOfPedDrawableVariations(playerPed, comp) end
    local function nTex(comp, d) return (VFW.PedTextureCount and VFW.PedTextureCount(playerPed, "clothing", comp, d)) or GetNumberOfPedTextureVariations(playerPed, comp, d) end
    local function nProp(prop) return (VFW.PedDrawableCount and VFW.PedDrawableCount(playerPed, "props", prop)) or GetNumberOfPedPropDrawableVariations(playerPed, prop) end
    local function nPropTex(prop, d) return (VFW.PedTextureCount and VFW.PedTextureCount(playerPed, "props", prop, d)) or GetNumberOfPedPropTextureVariations(playerPed, prop, d) end

    local data = {
        sex = #Config.PedsCharCreator + 3,
        mom = 45 + 25, -- numbers 21-41 and 45 are female (22 total)
        dad = 44 + 25, -- numbers 0-20 and 42-44 are male (24 total)
        face_md_weight = 100,
        skin_md_weight = 100,
        nose_1 = 10,
        nose_2 = 10,
        nose_3 = 10,
        nose_4 = 10,
        nose_5 = 10,
        nose_6 = 10,
        cheeks_1 = 10,
        cheeks_2 = 10,
        cheeks_3 = 10,
        lip_thickness = 10,
        jaw_1 = 10,
        jaw_2 = 10,
        chin_1 = 10,
        chin_2 = 10,
        chin_3 = 10,
        chin_4 = 10,
        neck_thickness = 10,
        age_1 = GetPedHeadOverlayNum(3) - 1,
        age_2 = 10,
        beard_1 = GetPedHeadOverlayNum(1) - 1,
        beard_2 = 10,
        beard_3 = GetNumHairColors() - 1,
        beard_4 = GetNumHairColors() - 1,
        hair_1 = nDraw(2) - 1,
        hair_2 = nTex(2, Character["hair_1"]) - 1,
        hair_color_1 = GetNumHairColors() - 1,
        hair_color_2 = GetNumHairColors() - 1,
        eye_color = 31,
        eye_squint = 10,
        eyebrows_1 = GetPedHeadOverlayNum(2) - 1,
        eyebrows_2 = 10,
        eyebrows_3 = GetNumHairColors() - 1,
        eyebrows_4 = GetNumHairColors() - 1,
        eyebrows_5 = 10,
        eyebrows_6 = 10,
        makeup_1 = GetPedHeadOverlayNum(4) - 1,
        makeup_2 = 10,
        makeup_3 = GetNumHairColors() - 1,
        makeup_4 = GetNumHairColors() - 1,
        lipstick_1 = GetPedHeadOverlayNum(8) - 1,
        lipstick_2 = 10,
        lipstick_3 = GetNumHairColors() - 1,
        lipstick_4 = GetNumHairColors() - 1,
        blemishes_1 = GetPedHeadOverlayNum(0) - 1,
        blemishes_2 = 10,
        blush_1 = GetPedHeadOverlayNum(5) - 1,
        blush_2 = 10,
        blush_3 = GetNumHairColors() - 1,
        complexion_1 = GetPedHeadOverlayNum(6) - 1,
        complexion_2 = 10,
        sun_1 = GetPedHeadOverlayNum(7) - 1,
        sun_2 = 10,
        moles_1 = GetPedHeadOverlayNum(9) - 1,
        moles_2 = 10,
        chest_1 = GetPedHeadOverlayNum(10) - 1,
        chest_2 = 10,
        chest_3 = GetNumHairColors() - 1,
        bodyb_1 = GetPedHeadOverlayNum(11) - 1,
        bodyb_2 = 10,
        bodyb_3 = GetPedHeadOverlayNum(12) - 1,
        bodyb_4 = 10,
        ears_1 = nProp(2) - 1,
        ears_2 = nPropTex(2, Character["ears_1"] - 1),
        tshirt_1 = nDraw(8) - 1,
        tshirt_2 = nTex(8, Character["tshirt_1"]) - 1,
        torso_1 = nDraw(11) - 1,
        torso_2 = nTex(11, Character["torso_1"]) - 1,
        decals_1 = nDraw(10) - 1,
        decals_2 = nTex(10, Character["decals_1"]) - 1,
        arms = nDraw(3) - 1,
        arms_2 = 10,
        pants_1 = nDraw(4) - 1,
        pants_2 = nTex(4, Character["pants_1"]) - 1,
        shoes_1 = nDraw(6) - 1,
        shoes_2 = nTex(6, Character["shoes_1"]) - 1,
        mask_1 = nDraw(1) - 1,
        mask_2 = nTex(1, Character["mask_1"]) - 1,
        bproof_1 = nDraw(9) - 1,
        bproof_2 = nTex(9, Character["bproof_1"]) - 1,
        chain_1 = nDraw(7) - 1,
        chain_2 = nTex(7, Character["chain_1"]) - 1,
        bags_1 = nDraw(5) - 1,
        bags_2 = nTex(5, Character["bags_1"]) - 1,
        helmet_1 = nProp(0) - 1,
        helmet_2 = nPropTex(0, Character["helmet_1"]) - 1,
        glasses_1 = nProp(1) - 1,
        glasses_2 = nPropTex(1, Character["glasses_1"] - 1),
        watches_1 = nProp(6) - 1,
        watches_2 = nPropTex(6, Character["watches_1"]) - 1,
        bracelets_1 = nProp(7) - 1,
        bracelets_2 = nPropTex(7, Character["bracelets_1"] - 1),
        degrade_collection = -1719270477,
        degrade_hashname = -1824026490,
    }

    return data
end

--- ApplySkin
---@param skin any
---@param clothes any
function ApplySkin(skin, clothes)
    local playerPed = PlayerPedId()

    -- merge incoming data en Character
    for k, v in pairs(skin or {}) do
        Character[k] = v
    end
    if clothes ~= nil then
        for k, v in pairs(clothes) do
            if k ~= "sex" and k ~= "mom" and k ~= "dad" and k ~= "face_md_weight" and k ~= "skin_md_weight" and
                    k ~= "nose_1" and k ~= "nose_2" and k ~= "nose_3" and k ~= "nose_4" and k ~= "nose_5" and k ~= "nose_6" and
                    k ~= "cheeks_1" and k ~= "cheeks_2" and k ~= "cheeks_3" and k ~= "lip_thickness" and k ~= "jaw_1" and
                    k ~= "jaw_2" and k ~= "chin_1" and k ~= "chin_2" and k ~= "chin_3" and k ~= "chin_4" and
                    k ~= "neck_thickness" and k ~= "age_1" and k ~= "age_2" and k ~= "eye_color" and k ~= "eye_squint" and
                    k ~= "beard_1" and k ~= "beard_2" and k ~= "beard_3" and k ~= "beard_4" and k ~= "hair_1" and k ~= "hair_2" and
                    k ~= "hair_color_1" and k ~= "hair_color_2" and k ~= "eyebrows_1" and k ~= "eyebrows_2" and
                    k ~= "eyebrows_3" and k ~= "eyebrows_4" and k ~= "eyebrows_5" and k ~= "eyebrows_6" and
                    k ~= "makeup_1" and k ~= "makeup_2" and k ~= "makeup_3" and k ~= "makeup_4" and
                    k ~= "lipstick_1" and k ~= "lipstick_2" and k ~= "lipstick_3" and k ~= "lipstick_4" and
                    k ~= "blemishes_1" and k ~= "blemishes_2" and k ~= "blemishes_3" and
                    k ~= "blush_1" and k ~= "blush_2" and k ~= "blush_3" and
                    k ~= "complexion_1" and k ~= "complexion_2" and
                    k ~= "sun_1" and k ~= "sun_2" and
                    k ~= "moles_1" and k ~= "moles_2" and
                    k ~= "chest_1" and k ~= "chest_2" and k ~= "chest_3" and
                    k ~= "bodyb_1" and k ~= "bodyb_2" and k ~= "bodyb_3" and k ~= "bodyb_4" and
                    k ~= "degrade_collection" and k ~= "degrade_hashname" then
                Character[k] = v
            end
        end
    end

    -- head blend
    local face_weight = (Character["face_md_weight"] / 100) + 0.0
    local skin_weight = (Character["skin_md_weight"] / 100) + 0.0
    SetPedHeadBlendData(playerPed, Character["mom"], Character["dad"], 0, Character["mom"], Character["dad"], 0, face_weight, skin_weight, 0.0, false)

    -- face features
    SetPedFaceFeature(playerPed, 0,  (Character["nose_1"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 1,  (Character["nose_2"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 2,  (Character["nose_3"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 3,  (Character["nose_4"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 4,  (Character["nose_5"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 5,  (Character["nose_6"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 6,  (Character["eyebrows_5"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 7,  (Character["eyebrows_6"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 8,  (Character["cheeks_1"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 9,  (Character["cheeks_2"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 10, (Character["cheeks_3"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 11, (Character["eye_squint"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 12, (Character["lip_thickness"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 13, (Character["jaw_1"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 14, (Character["jaw_2"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 15, (Character["chin_1"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 16, (Character["chin_2"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 17, (Character["chin_3"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 18, (Character["chin_4"] / 10) + 0.0)
    SetPedFaceFeature(playerPed, 19, (Character["neck_thickness"] / 10) + 0.0)

    -- overlays y hair
    SetPedHairColor(playerPed, Character["hair_color_1"], Character["hair_color_2"])
    SetPedHeadOverlay(playerPed, 3,  Character["age_1"],       (Character["age_2"] / 10) + 0.0)
    SetPedHeadOverlay(playerPed, 0,  Character["blemishes_1"], (Character["blemishes_2"] / 10) + 0.0)
    SetPedHeadOverlay(playerPed, 1,  Character["beard_1"],     (Character["beard_2"] / 10) + 0.0)
    SetPedEyeColor(playerPed, Character["eye_color"])
    SetPedHeadOverlay(playerPed, 2,  Character["eyebrows_1"],  (Character["eyebrows_2"] / 10) + 0.0)
    SetPedHeadOverlay(playerPed, 4,  Character["makeup_1"],    (Character["makeup_2"] / 10) + 0.0)
    SetPedHeadOverlay(playerPed, 8,  Character["lipstick_1"],  (Character["lipstick_2"] / 10) + 0.0)
    SetPedComponentVariation(playerPed, 2, Character["hair_1"], Character["hair_2"], 2)
    SetPedHeadOverlayColor(playerPed, 1, 1, Character["beard_3"],    Character["beard_4"])
    SetPedHeadOverlayColor(playerPed, 2, 1, Character["eyebrows_3"], Character["eyebrows_4"])
    SetPedHeadOverlayColor(playerPed, 4, 1, Character["makeup_3"],   Character["makeup_4"])
    SetPedHeadOverlayColor(playerPed, 8, 1, Character["lipstick_3"], Character["lipstick_4"])
    SetPedHeadOverlay(playerPed, 5,  Character["blush_1"], (Character["blush_2"] / 10) + 0.0)
    SetPedHeadOverlayColor(playerPed, 5, 1, Character["blush_3"])
    SetPedHeadOverlay(playerPed, 6,  Character["complexion_1"], (Character["complexion_2"] / 10) + 0.0)
    SetPedHeadOverlay(playerPed, 7,  Character["sun_1"],        (Character["sun_2"] / 10) + 0.0)
    SetPedHeadOverlay(playerPed, 9,  Character["moles_1"],      (Character["moles_2"] / 10) + 0.0)
    SetPedHeadOverlay(playerPed, 10, Character["chest_1"],      (Character["chest_2"] / 10) + 0.0)
    SetPedHeadOverlayColor(playerPed, 10, 1, Character["chest_3"])

    if Character["bodyb_1"] == -1 then
        SetPedHeadOverlay(playerPed, 11, 255, (Character["bodyb_2"] / 10) + 0.0)
    else
        SetPedHeadOverlay(playerPed, 11, Character["bodyb_1"], (Character["bodyb_2"] / 10) + 0.0)
    end

    if Character["bodyb_3"] == -1 then
        SetPedHeadOverlay(playerPed, 12, 255, (Character["bodyb_4"] / 10) + 0.0)
    else
        SetPedHeadOverlay(playerPed, 12, Character["bodyb_3"], (Character["bodyb_4"] / 10) + 0.0)
    end

    -- Clamp drawable/textura a la range válida del modelo actual. Sin esto, valores
    -- inválidos (ej. outfit guardado en otro modelo) generan "CPedVariation invalid"
    -- en F8 y SetPedComponentVariation/SetPedPropIndex fallan silenciosamente.
    -- Comptage vanilla + DLC + packs addon (collections) : GetNumberOfPedDrawableVariations
    -- seul peut ignorer les slots streamés, et un vêtement addon serait alors remis à 0.
    local function clampComp(slotId, d, t)
        local maxDraw = ((VFW.PedDrawableCount and VFW.PedDrawableCount(playerPed, "clothing", slotId)) or GetNumberOfPedDrawableVariations(playerPed, slotId)) - 1
        if maxDraw >= 0 and d > maxDraw then
            return 0, 0
        end
        if t == nil or t < 0 then t = 0 end
        local maxTex = ((VFW.PedTextureCount and VFW.PedTextureCount(playerPed, "clothing", slotId, d)) or GetNumberOfPedTextureVariations(playerPed, slotId, d)) - 1
        if maxTex >= 0 and t > maxTex then t = 0 end
        return d, t
    end

    local function clampProp(slotId, d, t)
        local maxDraw = ((VFW.PedDrawableCount and VFW.PedDrawableCount(playerPed, "props", slotId)) or GetNumberOfPedPropDrawableVariations(playerPed, slotId)) - 1
        if maxDraw >= 0 and d > maxDraw then
            return 0, 0
        end
        if t == nil or t < 0 then t = 0 end
        local maxTex = ((VFW.PedTextureCount and VFW.PedTextureCount(playerPed, "props", slotId, d)) or GetNumberOfPedPropTextureVariations(playerPed, slotId, d)) - 1
        if maxTex >= 0 and t > maxTex then t = 0 end
        return d, t
    end

    -- props: clear cuando *_1 == -1; si no, aplica con textura >= 0
    local function applyProp(slotId, dRaw, tRaw)
        if dRaw == -1 or dRaw == nil then
            ClearPedProp(playerPed, slotId)
            return
        end
        local t = (tRaw ~= nil and tRaw >= 0) and tRaw or 0
        local d, finalT = clampProp(slotId, dRaw, t)
        SetPedPropIndex(playerPed, slotId, d, finalT, 2)
    end

    applyProp(2, Character["ears_1"],      Character["ears_2"])
    applyProp(0, Character["helmet_1"],    Character["helmet_2"])
    applyProp(1, Character["glasses_1"],   Character["glasses_2"])
    applyProp(6, Character["watches_1"],   Character["watches_2"])
    applyProp(7, Character["bracelets_1"], Character["bracelets_2"])

    -- componentes: aplica solo cuando drawable >= 0; fuerza textura=0 en “desnudos base”.
    local function comp(slotId, d, t)
        d = tonumber(d)
        t = tonumber(t)
        if d ~= nil and d >= 0 then
            d, t = clampComp(slotId, d, t)
            if (slotId == 8 and d == 15) or (slotId == 11 and d == 15) or (slotId == 3 and d == 15) or (slotId == 6 and d == 34) then
                t = 0
            end
            SetPedComponentVariation(playerPed, slotId, d, t, 2)
        end
    end

    -- orden crítico: camiseta → torso → brazos
    comp(8,  Character["tshirt_1"], Character["tshirt_2"])
    comp(11, Character["torso_1"],  Character["torso_2"])
    comp(3,  Character["arms"],     Character["arms_2"])

    -- resto de componentes
    comp(10, Character["decals_1"], Character["decals_2"])
    comp(4,  Character["pants_1"],  Character["pants_2"])
    comp(6,  Character["shoes_1"],  Character["shoes_2"])
    comp(1,  Character["mask_1"],   Character["mask_2"])
    comp(9,  Character["bproof_1"], Character["bproof_2"])

    -- chain y bags con “clear” explícito usando drawable 0 cuando *_1 < 0
    do
        local d, t
        if Character["chain_1"] ~= nil and Character["chain_1"] >= 0 then
            local tex = (Character["chain_2"] ~= nil and Character["chain_2"] >= 0) and Character["chain_2"] or 0
            d, t = clampComp(7, Character["chain_1"], tex)
        else
            d, t = 0, 0
        end
        SetPedComponentVariation(playerPed, 7, d, t, 2)
    end

    do
        local d, t
        if Character["bags_1"] ~= nil and Character["bags_1"] >= 0 then
            local tex = (Character["bags_2"] ~= nil and Character["bags_2"] >= 0) and Character["bags_2"] or 0
            d, t = clampComp(5, Character["bags_1"], tex)
        else
            d, t = 0, 0
        end
        SetPedComponentVariation(playerPed, 5, d, t, 2)
    end

    -- tatuajes
    ClearPedDecorations(playerPed)
    AddPedDecorationFromHashes(playerPed, Character["degrade_collection"], Character["degrade_hashname"])
    if VFW.PlayerData and VFW.PlayerData.tattoos then
        for _, tattoo in ipairs(VFW.PlayerData.tattoos) do
            AddPedDecorationFromHashes(playerPed, tattoo.Collection, tattoo.Hash)
        end
    end

    -- máscara de gas / permisos
    if (GetConvar('core_type', 'FA') == 'WL') then
        if Character["mask_1"] == 245 or Character["mask_1"] == 246 then
            maskGaz = true
            Wait(250)
            CreateThread(function()
                while Character["mask_1"] == 245 or Character["mask_1"] == 246 do
                    SetEntityProofs(playerPed, false, false, false, false, false, false, true, true, false)
                    Wait(100)
                end
            end)
        else
            if maskGaz then
                maskGaz = false
                SetEntityProofs(playerPed, false, false, false, false, false, false, false, false, false)
                Wait(250)
            end
        end
    end
end

---@param loadMale boolean Load male model
---@param cb function? Optional callback
AddEventHandler('skinchanger:loadDefaultModel', function(loadMale, cb)
    LoadDefaultModel(loadMale, cb)
end)

---@param cb function Callback function
AddEventHandler('skinchanger:getData', function(cb)
    local components = json.decode(json.encode(Components))

    for charProperty, charValue in pairs(Character) do
        for componentIndex=1, #components, 1 do
            if charProperty == components[componentIndex].name then
                components[componentIndex].value = charValue
            end
        end
    end

    cb(components, GetMaxVals())
end)

---@param key string Component key
---@param val any Component value
AddEventHandler('skinchanger:change', function(key, val)
    Character[key] = val

    if key == 'sex' then
        TriggerEvent('skinchanger:loadSkin', Character)
    else
        ApplySkin(Character)
    end
end)

---@param cb function Callback function
AddEventHandler('skinchanger:getSkin', function(cb)
    cb(Character)
end)

AddEventHandler('skinchanger:modelLoaded', function()
    ClearPedProp(PlayerPedId(), 0)

    if LoadSkin ~= nil then
        ApplySkin(LoadSkin)
        LoadSkin = nil
    end

    if LoadClothes ~= nil then
        ApplySkin(LoadClothes.playerSkin, LoadClothes.clothesSkin)
        LoadClothes = nil
    end
end)

RegisterNetEvent('skinchanger:loadSkin')
---@param skin table Skin data
---@param cb function? Optional callback fired after model is set (or after failure / sync if no model change)
AddEventHandler('skinchanger:loadSkin', function(skin, cb)
    local characterModel
    local sexChanged = (skin['sex'] ~= LastSex)

    if sexChanged then
        LoadSkin = skin

        if skin['sex'] == 0 then
            LoadDefaultModel(true, cb)
        elseif skin['sex'] > 1 then
            characterModel = Config.PedsCharCreator[skin.sex - 1]
        else
            LoadDefaultModel(false, cb)
        end
    else
        ApplySkin(skin)
        if cb ~= nil then
            cb()
        end
    end

    LastSex = skin['sex']

    if sexChanged and characterModel then
        CreateThread(function()
            local validModel = IsModelInCdimage(characterModel) and IsModelValid(characterModel)
            local loaded = false

            if validModel then
                for attempt = 1, 3 do
                    RequestModel(characterModel)
                    local timeout = GetGameTimer() + 15000
                    while not HasModelLoaded(characterModel) do
                        if GetGameTimer() > timeout then break end
                        Wait(0)
                    end
                    if HasModelLoaded(characterModel) then
                        loaded = true
                        break
                    end
                    print(("[skinchanger] ^3Retry %d/3 for model %s^7"):format(attempt, characterModel))
                end
            end

            if loaded then
                SetPlayerModel(PlayerId(), characterModel)
                SetPedDefaultComponentVariation(PlayerPedId())
                SetModelAsNoLongerNeeded(characterModel)
                TriggerEvent('skinchanger:modelLoaded')
            elseif validModel then
                print(("[skinchanger] ^1Model loading FAILED after retries: %s^7"):format(characterModel))
            else
                print(("[skinchanger] ^1Invalid model: %s^7"):format(tostring(characterModel)))
            end

            if cb ~= nil then
                cb()
            end
        end)
    end
end)

RegisterNetEvent('skinchanger:loadClothes')
---@param playerSkin table Player skin
---@param clothesSkin table Clothes skin
AddEventHandler('skinchanger:loadClothes', function(playerSkin, clothesSkin)
    local characterModel
    local sexChanged = (playerSkin['sex'] ~= LastSex)

    if sexChanged then
        LoadClothes = {
            playerSkin  = playerSkin,
            clothesSkin = clothesSkin
        }

        if playerSkin['sex'] == 0 then
            LoadDefaultModel(true)
        elseif playerSkin['sex'] > 1 then
            characterModel = Config.PedsCharCreator[playerSkin.sex - 1]
        else
            LoadDefaultModel(false)
        end
    else
        ApplySkin(playerSkin, clothesSkin)
    end

    LastSex = playerSkin['sex']

    if sexChanged and characterModel then
        CreateThread(function()
            if not (IsModelInCdimage(characterModel) and IsModelValid(characterModel)) then
                print(("[skinchanger] ^1Invalid model: %s^7"):format(tostring(characterModel)))
                return
            end

            local loaded = false
            for attempt = 1, 3 do
                RequestModel(characterModel)
                local timeout = GetGameTimer() + 15000
                while not HasModelLoaded(characterModel) do
                    if GetGameTimer() > timeout then break end
                    Wait(0)
                end
                if HasModelLoaded(characterModel) then
                    loaded = true
                    break
                end
                print(("[skinchanger] ^3Retry %d/3 for model %s^7"):format(attempt, characterModel))
            end

            if loaded then
                SetPlayerModel(PlayerId(), characterModel)
                SetPedDefaultComponentVariation(PlayerPedId())
                SetModelAsNoLongerNeeded(characterModel)
                TriggerEvent('skinchanger:modelLoaded')
            else
                print(("[skinchanger] ^1Model loading FAILED after retries: %s^7"):format(characterModel))
            end
        end)
    end
end)

function GetSkinClothes()
    local clothes = {}

    for k, v in pairs(Character) do
       local compData <const> = GetSkinCompData(k)

       if compData then
           clothes[k] = v
       end
    end

    return clothes
end

local SkinCompMap <const> = {
    tshirt_1 = {type = "clothes", index = 8},
    tshirt_2 = {type = "clothes", index = 8},
    torso_1 = {type = "clothes", index = 11},
    torso_2 = {type = "clothes", index = 11},
    arms = {type = "clothes", index = 3},
    decals_1 = {type = "clothes", index = 10},
    decals_2 = {type = "clothes", index = 10},
    pants_1 = {type = "clothes", index = 4},
    pants_2 = {type = "clothes", index = 4},
    shoes_1 = {type = "clothes", index = 6},
    shoes_2 = {type = "clothes", index = 6},
    mask_1 = {type = "clothes", index = 1},
    mask_2 = {type = "clothes", index = 1},
    bproof_1 = {type = "clothes", index = 9},
    bproof_2 = {type = "clothes", index = 9},
    chain_1 = {type = "clothes", index = 7},
    chain_2 = {type = "clothes", index = 7},
    bags_1 = {type = "clothes", index = 5},
    bags_2 = {type = "clothes", index = 5},
    helmet_1 = {type = "props", index = 0},
    helmet_2 = {type = "props", index = 0},
    glasses_1 = {type = "props", index = 1},
    glasses_2 = {type = "props", index = 1},
}

function GetSkinCompData(key)
    local comp <const> = SkinCompMap[key]
    if comp then
        return comp.type, comp.index
    end
end