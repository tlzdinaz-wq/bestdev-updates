---@meta _
---@diagnostic disable: duplicate-doc-field

local freemodeModels<const> = {
    [`mp_m_freemode_01`] = 'mp_m_freemode_01',
    [`mp_f_freemode_01`] = 'mp_f_freemode_01'
}

local maskFixConfig = {
    ['mp_m_freemode_01'] = {
        shrinkHead = {
            108, -- Skull mask
            30,  -- Hockey mask (homme)
            11,
            114,
            145,
            148,
            298,
            297,
            296,
            294,
            293,
            292,
            291,
            290,
            289,
            286,
            283,
            282,
            274,
            273,
            272,
            271,
            257,
            255,
            254,
            253,
            252,
            251,
            250,
            244
        },

        shrinkFace = {
            11,
            114,
            145,
            148,
            298,
            297,
            296,
            294,
            293,
            292,
            291,
            290,
            289,
            286,
            283,
            282,
            274,
            273,
            272,
            271,
            257,
            255,
            254,
            253,
            252,
            251,
            250,
            244  -- Masques homme à shrink
        }
    },

    ['mp_f_freemode_01'] = {
        shrinkHead = {
            108, -- Skull mask
            29,  -- Hockey mask (femme)
            365, -- masque covid
            364, -- masque covid 2
            264, -- masque gang
            263, -- masque hockey ?
            262, -- masque covid 2
            254, -- masque gang 2
            253, -- masque gang 3
            252, -- masque gang 4
            251, -- masque gang 5
            248, -- masque gang 5
        },

        shrinkFace = {
            11,
            114,
            145,
            148,
            365,
            364,
            264,
            263,
            262,
            254,
            253,
            252,
            251,
            248 -- Masques femme à shrink
        }
    }
}

--- isFreemodeModel
---@param modelHash any
---@return boolean
local function isFreemodeModel(modelHash)
    return freemodeModels[modelHash] ~= nil
end

---Get HeadBlendData
---@param ped number Ped handle
---@return table
local function getHeadBlendData(ped)
    local tbl<const> = {
        Citizen.InvokeNative(0x2746BD9D88C5C5D0, ped,
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueFloatInitialized(0),
                Citizen.PointerValueFloatInitialized(0),
                Citizen.PointerValueFloatInitialized(0)
        )
    }

    return {
        shapeFirst = tbl[1],
        shapeSecond = tbl[2],
        shapeThird = tbl[3],
        skinFirst = tbl[4],
        skinSecond = tbl[5],
        skinThird = tbl[6],
        shapeMix = tbl[7],
        skinMix = tbl[8],
        thirdMix = tbl[9]
    }
end

local savedBlendData, savedFaceFeatures

---Save restoredBlendData
---@param ped number Ped handle
local function restoreSavedBlendData(ped)
    SetPedHeadBlendData(ped, savedBlendData.shapeFirst, savedBlendData.shapeSecond, savedBlendData.shapeThird, savedBlendData.skinFirst, savedBlendData.skinSecond, savedBlendData.skinThird, savedBlendData.shapeMix, savedBlendData.skinMix, savedBlendData.thirdMix, false)
end

---Save restoredFaceFeatures
---@param ped number Ped handle
local function restoreSavedFaceFeatures(ped)

    for i = 0, 19 do
        SetPedFaceFeature(ped, i, savedFaceFeatures[i])
    end
end

--- shrinkFaceFeatures
---@param ped number Ped handle
local function shrinkFaceFeatures(ped)
    repeat Wait(0) until HasPedHeadBlendFinished(ped)
    for i = 0, 19 do
        if not savedFaceFeatures[i] then
            savedFaceFeatures[i] = GetPedFaceFeature(ped, i)
        end

        SetPedFaceFeature(ped, i, 0.0)
    end
end

--- shrinkHead
---@param ped number Ped handle
---@param pedModelHash number Ped handle
local function shrinkHead(ped, pedModelHash)
    SetPedHeadBlendData(ped, freemodeModels[pedModelHash] == 'mp_m_freemode_01' and 0 or 21, 0, 0, savedBlendData.skinFirst, savedBlendData.skinSecond, savedBlendData.skinThird, 0.0, savedBlendData.skinMix, 0.0, false)
end

--- isEncryptedMask
---@param maskHash any
---@return boolean
local function isEncryptedMask(maskHash)
    local encryptedMasks = {
        [286] = true,
        [289] = true,
        [290] = true,
        [291] = true,
        [292] = true,
        [293] = true,
        [294] = true,
        [297] = true,
        [298] = true,
    }
    return encryptedMasks[maskHash] ~= nil
end

--- fixMask
---@param ped number Ped handle
---@param pedModelHash number Ped handle
---@return any
local function fixMask(ped, pedModelHash)
    local currentMaskDrawable = GetPedDrawableVariation(ped, 1)
    local currentMaskTexture = GetPedTextureVariation(ped, 1)

    local modelName = freemodeModels[pedModelHash]
    if not modelName then
        return
    end

    local modelConfig = maskFixConfig[modelName]
    if not modelConfig then
        return
    end

    local maskHash = GetHashNameForComponent(ped, 1, currentMaskDrawable, currentMaskTexture)

    if currentMaskDrawable > 0 then
        if maskHash == 0 then
            return
        end

        if isEncryptedMask(maskHash) then
            console.debug("Masque crypté détecté, pas de réduction appliquée : " .. maskHash)
            return
        end

        local headBlendData = getHeadBlendData(ped)
        local needsShrinkHead = DoesShopPedApparelHaveRestrictionTag(maskHash, `SHRINK_HEAD`, 0)

        for _, id in ipairs(modelConfig.shrinkHead) do
            if currentMaskDrawable == id then
                needsShrinkHead = true
                break
            end
        end

        if needsShrinkHead then
            if not savedBlendData then
                savedBlendData = headBlendData
            end

            shrinkHead(ped, pedModelHash)
        elseif savedBlendData then
            restoreSavedBlendData(ped)
            savedBlendData = nil
        end

        local needsShrinkFace = not DoesShopPedApparelHaveRestrictionTag(maskHash, `HAT`, 0) and not DoesShopPedApparelHaveRestrictionTag(maskHash, `EAR_PIECE`, 0)

        for _, id in ipairs(modelConfig.shrinkFace) do
            if currentMaskDrawable == id then
                needsShrinkFace = true
                break
            end
        end

        if needsShrinkFace then
            if not savedFaceFeatures then
                savedFaceFeatures = {}
            end

            shrinkFaceFeatures(ped)
        elseif savedFaceFeatures then
            restoreSavedFaceFeatures(ped)
            savedFaceFeatures = nil
        end
    else
        if savedBlendData then
            restoreSavedBlendData(ped)
            savedBlendData = nil
        end

        if savedFaceFeatures then
            restoreSavedFaceFeatures(ped)
            savedFaceFeatures = nil
        end
    end
end

--- fixClothing
---@return any
local function fixClothing()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        return
    end

    local pedModelHash = GetEntityModel(ped)
    if not isFreemodeModel(pedModelHash) then
        return
    end

    fixMask(ped, pedModelHash)
end

CreateThread(function()
    while true do
        fixClothing()
        Wait(100)
    end
end)
