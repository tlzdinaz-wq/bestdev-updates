---@meta _
---@diagnostic disable: duplicate-doc-field

local translateSkin = {
    ["bottom"]   = {"pants_1","pants_2"},
    ["shoe"]     = {"shoes_1","shoes_2"},
    ["hat"]      = {"helmet_1","helmet_2"},
    ["glasses"]  = {"glasses_1","glasses_2"},
    ["bag"]      = {"bags_1","bags_2"},
    ["necklace"] = {"chain_1","chain_2"},
    ["watch"]    = {"watches_1","watches_2"},
    ["mask"]     = {"mask_1","mask_2"},
    ["bracelet"] = {"bracelets_1","bracelets_2"},
    ["earring"]  = {"ears_1","ears_2"},
    ["piercing"] = {"decals_1","decals_2"},
    ["nails"]    = {"decals_1","decals_2"},
    ["gpb"]      = {"bproof_1","bproof_2"},
    ["top"]      = {"torso_1","torso_2"},
    ["shirt"]    = {"tshirt_1","tshirt_2"},
    ["arms"]     = {"arms","arms_2"},
}

local nakedSkin = {
    ["m"] = {
        ["arms"] = 15,
        ["arms_2"] = 0,
        ["torso_1"] = 15,
        ["torso_2"] = 0,
        ["tshirt_1"] = 15,
        ["tshirt_2"] = 0,
        ["pants_1"] = 61,
        ["pants_2"] = 0,
        ["shoes_1"] = 34,
        ["shoes_2"] = 0,
        ["bproof_1"] = 0,
        ["bproof_2"] = 0,
        ["decals_1"] = 0,
        ["decals_2"] = 0,
        ["mask_1"] = 0,
        ["mask_2"] = 0,
        ["watches_1"] = -1,
        ["watches_2"] = -1,
        ["glasses_1"] = -1,
        ["glasses_2"] = 0,
        ["chain_1"] = -1,
        ["chain_2"] = -1,
        ["bags_1"] = -1,
        ["bags_2"] = -1,
        ["helmet_1"] = -1,
        ["helmet_2"] = -1,
        ["bracelets_1"] = -1,
        ["bracelets_2"] = -1,
        ["ears_1"] = -1,
        ["ears_2"] = -1,
    },
    ["w"] = {
        ["arms"] = 15,
        ["arms_2"] = 0,
        ["torso_1"] = 15,
        ["torso_2"] = 0,
        ["tshirt_1"] = 15,
        ["tshirt_2"] = 0,
        ["pants_1"] = 15,
        ["pants_2"] = 0,
        ["shoes_1"] = 35,
        ["shoes_2"] = 0,
        ["bproof_1"] = 0,
        ["bproof_2"] = 0,
        ["decals_1"] = 0,
        ["decals_2"] = 0,
        ["mask_1"] = 0,
        ["mask_2"] = 0,
        ["watches_1"] = -1,
        ["watches_2"] = -1,
        ["glasses_1"] = -1,
        ["glasses_2"] = 0,
        ["chain_1"] = -1,
        ["chain_2"] = -1,
        ["bags_1"] = -1,
        ["bags_2"] = -1,
        ["helmet_1"] = -1,
        ["helmet_2"] = -1,
        ["bracelets_1"] = -1,
        ["bracelets_2"] = -1,
        ["ears_1"] = -1,
        ["ears_2"] = -1,
    }
}

-- 🆕 Estado para rastrear si hay un outfit equipado y qué slots bloquea
local currentOutfitSkin = nil

-- Permet aux autres modules (ex: initializeEquippedClothes au reconnect)
-- de restaurer l'état "outfit équipé" pour que le déséquipement futur ne
-- tombe pas dans le fallback "reset tout" qui retirerait aussi les vêtements
-- individuels portés par-dessus la tenue.
function VFW.SetCurrentOutfitSkin(skinTable)
    currentOutfitSkin = skinTable
end

GetClothes = {
    ["bottom"] = false,
    ["shoe"] = false,
    ["hat"] = false,
    ["glasses"] = false,
    ["bag"] = false,
    ["necklace"] = false,
    ["watch"] = false,
    ["mask"] = false,
    ["bracelet"] = false,
    ["earring"] = false,
    ["piercing"] = false,
    ["nails"] = false,
    ["ring"] = false,
    ["outfit"] = false,
    ["top"] = false,
    ["arms"] = false,
    ["gpb"] = false
}

-- Animations par slot (équiper / déséquiper)
local clothingAnimations = {
    -- Hauts (haut du corps : ajuster le col / tirer sur le tissu)
    ["top_on"]       = {Dict = "clothingtie", Anim = "try_tie_positive_a", Move = 51, Dur = 1800},
    ["top_off"]      = {Dict = "missmic4", Anim = "michael_tux_fidget", Move = 51, Dur = 1500},

    -- Sous-haut / Tshirt
    ["shirt_on"]     = {Dict = "clothingtie", Anim = "try_tie_negative_a", Move = 51, Dur = 1200},
    ["shirt_off"]    = {Dict = "missmic4", Anim = "michael_tux_fidget", Move = 51, Dur = 1200},

    -- Pantalon (ajuster la ceinture)
    ["bottom_on"]    = {Dict = "re@construction", Anim = "out_of_breath", Move = 51, Dur = 1300},
    ["bottom_off"]   = {Dict = "re@construction", Anim = "out_of_breath", Move = 51, Dur = 1300},

    -- Chaussures (se baisser)
    ["shoe_on"]      = {Dict = "random@domestic", Anim = "pickup_low", Move = 0, Dur = 1200},
    ["shoe_off"]     = {Dict = "random@domestic", Anim = "pickup_low", Move = 0, Dur = 1200},

    -- Gants
    ["gloves_on"]    = {Dict = "nmt_3_rcm-10", Anim = "cs_nigel_dual-10", Move = 51, Dur = 1200},
    ["gloves_off"]   = {Dict = "nmt_3_rcm-10", Anim = "cs_nigel_dual-10", Move = 51, Dur = 1200},

    -- Masque (mettre/enlever sur le visage)
    ["mask_on"]      = {Dict = "mp_masks@standard_car@ds@", Anim = "put_on_mask", Move = 51, Dur = 1000},
    ["mask_off"]     = {Dict = "mp_masks@standard_car@ds@", Anim = "put_on_mask", Move = 51, Dur = 1000},

    -- Chapeau (poser sur la tête / retirer)
    ["hat_on"]       = {Dict = "mp_masks@standard_car@ds@", Anim = "put_on_mask", Move = 51, Dur = 800},
    ["hat_off"]      = {Dict = "missheist_agency2ahelmet", Anim = "take_off_helmet_stand", Move = 51, Dur = 1200},

    -- Lunettes (mettre / retirer)
    ["glasses_on"]   = {Dict = "clothingspecs", Anim = "take_off", Move = 51, Dur = 1200},
    ["glasses_off"]  = {Dict = "clothingspecs", Anim = "take_off", Move = 51, Dur = 1200},

    -- Collier (ajuster autour du cou)
    ["necklace_on"]  = {Dict = "clothingtie", Anim = "try_tie_positive_a", Move = 51, Dur = 1800},
    ["necklace_off"] = {Dict = "clothingtie", Anim = "try_tie_negative_a", Move = 51, Dur = 1200},

    -- Montre (attacher au poignet)
    ["watch_on"]     = {Dict = "nmt_3_rcm-10", Anim = "cs_nigel_dual-10", Move = 51, Dur = 1200},
    ["watch_off"]    = {Dict = "nmt_3_rcm-10", Anim = "cs_nigel_dual-10", Move = 51, Dur = 1200},

    -- Bracelet (poignet)
    ["bracelet_on"]  = {Dict = "nmt_3_rcm-10", Anim = "cs_nigel_dual-10", Move = 51, Dur = 1000},
    ["bracelet_off"] = {Dict = "nmt_3_rcm-10", Anim = "cs_nigel_dual-10", Move = 51, Dur = 1000},

    -- Boucles d'oreilles (toucher l'oreille)
    ["earring_on"]   = {Dict = "mp_masks@standard_car@ds@", Anim = "put_on_mask", Move = 51, Dur = 900},
    ["earring_off"]  = {Dict = "mp_masks@standard_car@ds@", Anim = "put_on_mask", Move = 51, Dur = 900},

    -- Sac (enfiler sur l'épaule)
    ["bag_on"]       = {Dict = "anim@heists@ornate_bank@grab_cash", Anim = "intro", Move = 51, Dur = 1600},
    ["bag_off"]      = {Dict = "anim@heists@ornate_bank@grab_cash", Anim = "intro", Move = 51, Dur = 1200},

    -- Gilet pare-balles (ajuster sur le torse)
    ["gpb_on"]       = {Dict = "clothingtie", Anim = "try_tie_negative_a", Move = 51, Dur = 1500},
    ["gpb_off"]      = {Dict = "missmic4", Anim = "michael_tux_fidget", Move = 51, Dur = 1500},

    -- Tenue complète (s'habiller)
    ["outfit_on"]    = {Dict = "missmic4", Anim = "michael_tux_fidget", Move = 51, Dur = 2000},
    ["outfit_off"]   = {Dict = "missmic4", Anim = "michael_tux_fidget", Move = 51, Dur = 2000},

    -- Accessoire collier (cou)
    ["accessory_on"] = {Dict = "clothingtie", Anim = "try_tie_positive_a", Move = 51, Dur = 1500},
    ["accessory_off"]= {Dict = "clothingtie", Anim = "try_tie_negative_a", Move = 51, Dur = 1200},
}

-- Jouer une animation sans bloquer
local function playAnim(animKey)
    local ped = PlayerPedId()
    local anim = clothingAnimations[animKey]
    if not anim then
        return
    end

    RequestAnimDict(anim.Dict)
    local tries = 0
    while not HasAnimDictLoaded(anim.Dict) and tries < 50 do
        Citizen.Wait(0)
        tries = tries + 1
    end

    if HasAnimDictLoaded(anim.Dict) then
        TaskPlayAnim(ped, anim.Dict, anim.Anim, 3.0, 3.0, anim.Dur, anim.Move, 0, false, false, false)
    end
end

-- 🆕 Función para verificar si un slot está bloqueado por el outfit
local function isSlotLockedByOutfit(typeItem)
    if not currentOutfitSkin then
        return false -- No hay outfit, ningún slot está bloqueado
    end

    -- Mapeo de tipos de prenda a componentes de skin
    local slotToSkinKey = {
        ["hat"] = "helmet_1",
        ["glasses"] = "glasses_1",
        ["mask"] = "mask_1",
        ["top"] = "torso_1",
        ["shirt"] = "tshirt_1",
        ["bottom"] = "pants_1",
        ["shoe"] = "shoes_1",
        ["bag"] = "bags_1",
        ["necklace"] = "chain_1",
        ["watch"] = "watches_1",
        ["bracelet"] = "bracelets_1",
        ["earring"] = "ears_1",
        ["gpb"] = "bproof_1",
        ["arms"] = "arms",
    }

    local skinKey = slotToSkinKey[typeItem]
    if not skinKey then
        return false -- Tipo desconocido, no está bloqueado
    end

    local outfitValue = currentOutfitSkin[skinKey]

    -- Props usan -1 como vacío, componentes usan 0
    local isEmpty = outfitValue == nil or outfitValue == -1 or outfitValue == 0

    if not isEmpty then
        --print(string.format("⚠️ SLOT BLOQUEADO: El outfit contiene %s (valor: %s)", typeItem, tostring(outfitValue)))
        return true
    end

    return false
end

-- Evento principal completo
RegisterNetEvent('vfw:clothes', function(itemName, meta)
    --print("========================================")
    --print("========================================")
    --print("📦 itemName:", itemName)
    --print("📦 meta completo:", json.encode(meta or {}, {indent = true}))

    if meta then
        --print("🔍 meta.sex:", meta.sex)
        --print("🔍 tipo meta.sex:", type(meta.sex))
        --print("🔍 meta.action:", meta.action)
        --print("🔍 meta.type:", meta.type)
        --print("🔍 meta.id:", meta.id)
        --print("🔍 meta.var:", meta.var)
    else
        --print("⚠️ meta es NIL")
    end

    -- 1. Obtener la skin actual del servidor
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

    if not skin then
        --print("❌ Error: No se pudo obtener la skin del servidor")
        return
    end

    -- Determinamos el sexo (m/w)
    --local playerSex = (meta and meta.sex) or "m"
    --print("🔍 playerSex ANTES de conversión:", playerSex, "(" .. type(playerSex) .. ")")
    --
    --if playerSex == "male" then playerSex = "m" end
    --if playerSex == "female" then playerSex = "w" end
    -- Determinamos el sexo (m/w)
    local playerSex = (meta and meta.sex) or "m"
    --print("🔍 playerSex ANTES de conversión:", playerSex, "(" .. type(playerSex) .. ")")

    -- Normalizar a "m" o "w"
    if type(playerSex) == "string" then
        playerSex = string.lower(playerSex)

        -- Convertir todas las variantes de masculino a "m"
        if playerSex == "male" or playerSex == "man" or playerSex == "m" then
            playerSex = "m"
            -- Convertir todas las variantes de femenino a "w"
        elseif playerSex == "female" or playerSex == "woman" or playerSex == "w" or playerSex == "f" then
            playerSex = "w"
        else
            --print("⚠️ Sexo desconocido: " .. tostring(playerSex) .. ", usando 'm' por defecto")
            playerSex = "m"
        end
    elseif type(playerSex) == "number" then
        -- Por si viene como número (0=hombre, 1=mujer)
        playerSex = (playerSex == 0) and "m" or "w"
    else
        --print("⚠️ Tipo de sexo inválido: " .. type(playerSex) .. ", usando 'm' por defecto")
        playerSex = "m"
    end
    --print("🔍 playerSex DESPUÉS de conversión:", playerSex)
    --print("🔍 ¿Existe nakedSkin['" .. playerSex .. "']?:", nakedSkin[playerSex] ~= nil)

    if nakedSkin[playerSex] then
        --print("✅ Configuración encontrada para:", playerSex)
    else
        --print("❌ NO existe configuración para:", playerSex)
        --print("Claves disponibles en nakedSkin:")
        --for k, v in pairs(nakedSkin) do
        --    print("  -", k)
        --end
    end
    --print("========================================")

    -----------------------------------------
    -- CASO A: OUTFIT COMPLETO
    -----------------------------------------
    if itemName == "outfit" then
        if meta.action == "on" then
            --print("🟢 EQUIPANDO OUTFIT COMPLETO...")
            if not meta.skipAnimation then
                playAnim("outfit_on")
            end

            if meta.skin then
                -- Si une tenue est déjà équipée, reset complet vers naked d'abord
                -- pour éviter que des composants de l'ancienne tenue restent collés au ped
                if currentOutfitSkin then
                    local nakedComponents = nakedSkin[playerSex]
                    if nakedComponents then
                        for component, nakedValue in pairs(nakedComponents) do
                            skin[component] = nakedValue
                            TriggerEvent("skinchanger:change", component, nakedValue)
                        end
                    end
                    TriggerServerEvent("vfw:bag:removeWeightBonus")
                    currentOutfitSkin = nil
                end

                -- 🆕 Guardar el skin del outfit para bloquear slots
                currentOutfitSkin = meta.skin

                -- 🆕 Aplicar solo los componentes que el outfit realmente tiene
                -- NO sobrescribir componentes vacíos (-1 o 0) para preservar prendas individuales
                for component, value in pairs(meta.skin) do
                    -- Determinar si este componente está "vacío" en el outfit
                    local isEmpty = false

                    -- Props (helmet, glasses, etc.) usan -1 como vacío
                    if component:match("helmet_") or component:match("glasses_") or
                            component:match("watches_") or component:match("bracelets_") or
                            component:match("ears_") then
                        isEmpty = (value == -1)
                        -- Componentes (mask, bags, chain, bproof) pueden usar 0 como vacío
                    elseif component:match("mask_") or component:match("bags_") or
                            component:match("chain_") or component:match("bproof_") then
                        isEmpty = (value == 0 or value == -1)
                    end

                    -- Solo aplicar si NO está vacío, para preservar prendas individuales
                    if not isEmpty then
                        skin[component] = value
                        TriggerEvent("skinchanger:change", component, value)
                        --print(string.format("  ✅ Aplicando %s = %s", component, value))
                    else
                        --print(string.format("  ⏭️  Ignorando %s (vacío en outfit, preservando prenda individual)", component))
                    end
                end

                GetClothes["outfit"] = true
                --print("✅ Outfit equipado - Slots bloqueados según componentes del outfit")

                -- Apply bag weight bonus if outfit contains a bag
                local bagDrawable = meta.skin.bags_1
                if bagDrawable and bagDrawable > 0 then
                    TriggerServerEvent("vfw:bag:removeWeightBonus")
                    TriggerServerEvent("vfw:bag:addWeightBonus", 0, bagDrawable, playerSex)
                else
                    TriggerServerEvent("vfw:bag:removeWeightBonus")
                end

                -- Rafraîchir l'inventaire si demandé (pour sync avec frontend après création de personnage)
                if meta.refreshInventory then
                    SetTimeout(200, function()
                        VFW.LoadInventories()
                    end)
                end
            end

        elseif meta.action == "off" then
            --print("🔴 DESEQUIPANDO OUTFIT (Reseteando solo componentes del outfit)...")
            playAnim("outfit_off")

            -- 🆕 En lugar de resetear TODO, solo resetear los componentes que el outfit estaba usando
            if currentOutfitSkin then
                local componentsToReset = nakedSkin[playerSex]

                if not componentsToReset then
                    --print("❌ ERROR CRÍTICO: No existe configuración nakedSkin para sexo:", playerSex)
                    return
                end

                for component, outfitValue in pairs(currentOutfitSkin) do
                    -- Solo resetear componentes que el outfit tenía (no vacíos)
                    local wasUsedByOutfit = false

                    -- Props usan -1 como vacío
                    if component:match("helmet_") or component:match("glasses_") or
                            component:match("watches_") or component:match("bracelets_") or
                            component:match("ears_") then
                        wasUsedByOutfit = (outfitValue ~= -1)
                        -- Componentes (mask, bags, chain, bproof) usan 0 como vacío
                    elseif component:match("mask_") or component:match("bags_") or
                            component:match("chain_") or component:match("bproof_") then
                        wasUsedByOutfit = (outfitValue ~= 0 and outfitValue ~= -1)
                        -- Ropa principal (torso, pants, etc.) siempre se resetea
                    else
                        wasUsedByOutfit = true
                    end

                    -- Solo resetear si el outfit lo estaba usando
                    if wasUsedByOutfit and componentsToReset[component] then
                        local nakedValue = componentsToReset[component]
                        skin[component] = nakedValue
                        TriggerEvent("skinchanger:change", component, nakedValue)
                        --print(string.format("  ✅ Reseteando %s = %s", component, nakedValue))
                    else
                        --print(string.format("  ⏭️  Preservando %s (no era parte del outfit)", component))
                    end
                end

                --print("✅ Componentes del outfit reseteados - Prendas individuales preservadas")
            else
                -- Si por alguna razón no tenemos currentOutfitSkin, resetear todo como fallback
                --print("⚠️ No se encontró currentOutfitSkin, reseteando todo como fallback")
                local componentsToReset = nakedSkin[playerSex]

                if not componentsToReset then
                    --print("❌ ERROR CRÍTICO: No existe configuración nakedSkin para sexo:", playerSex)
                    return
                end

                if componentsToReset then
                    for component, value in pairs(componentsToReset) do
                        skin[component] = value
                        TriggerEvent("skinchanger:change", component, value)
                    end
                end
            end

            -- Remove bag weight bonus when unequipping outfit
            TriggerServerEvent("vfw:bag:removeWeightBonus")

            -- 🆕 Limpiar el outfit bloqueado
            currentOutfitSkin = nil
            GetClothes["outfit"] = false
        end

        -----------------------------------------
        -- CASO B: PRENDA INDIVIDUAL
        -----------------------------------------
    else
        local typeItem = meta.type and meta.type or itemName

        if typeItem == "kevlar" then
            typeItem = "gpb"
        end

        -- Normaliser undershirt → top (items composites avec meta.skin)
        if typeItem == "undershirt" and meta.skin then
            typeItem = "top"
        end


        -- Si l'item a un bag_uuid, c'est un sac - forcer le type
        if meta.bag_uuid and typeItem ~= "bag" then
            typeItem = "bag"
        end

        -- 🆕 Verificar si el slot está bloqueado por el outfit
        -- Permitir re-equipar desde el toggle de outfit (eye icon)
        if meta.action == "on" and not meta.fromOutfit and isSlotLockedByOutfit(typeItem) then
            --print(string.format("❌ ACCIÓN RECHAZADA: No puedes equipar %s porque el outfit está usando ese slot", typeItem))
            --print("💡 Desequipa el outfit primero para usar esta prenda")
            -- Aquí podrías enviar una notificación al cliente
            -- TriggerEvent('inventory:notify', 'error', 'No puedes equipar esto sobre el outfit')
            return
        end

        -- Prevent equipping a second bag (but allow re-equipping or if no bag visible)
        if typeItem == "bag" and meta.action == "on" and GetClothes["bag"] then
            local currentBagUUID = VFW.GetEquippedBagUUID and VFW.GetEquippedBagUUID()
            -- Check actual visual state - if no bag visible on model, allow equipping
            local currentBagDrawable = GetPedDrawableVariation(PlayerPedId(), 5) -- Component 5 = bags
            local bagActuallyVisible = currentBagDrawable and currentBagDrawable > 0

            -- Si c'est un sac différent ET un sac est visuellement équipé, bloquer
            if bagActuallyVisible and currentBagUUID and meta.bag_uuid and currentBagUUID ~= meta.bag_uuid then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Vous portez déjà un sac"
                })
                return
            end
            -- Si pas de sac visible, le même sac, ou pas de bag_uuid, continuer
        end

        local comp1 = translateSkin[typeItem] and translateSkin[typeItem][1]
        local comp2 = translateSkin[typeItem] and translateSkin[typeItem][2]

        if not comp1 or not comp2 then
            --print("❌ No se encontró mapeo para:", typeItem)
            return
        end

        --print("🔍 Componentes mapeados:", comp1, comp2)

        if meta.action == "off" then
            --print("🔴 DESEQUIPANDO PRENDA:", typeItem)

            playAnim(typeItem.."_off")

            -- 1. PROPS REALES (Gafas, Cascos, Relojes...) -> usan -1
            local isRealProp = (typeItem == "hat" or typeItem == "glasses" or typeItem == "watch" or typeItem == "bracelet" or typeItem == "earring")

            if isRealProp then
                --print("  → Es prop real, usando -1")
                skin[comp1] = -1
                skin[comp2] = 0
                TriggerEvent("skinchanger:change", comp1, -1)
                TriggerEvent("skinchanger:change", comp2, 0)

                -- 2. MÁSCARA, BOLSA ET KEVLAR (Componentes) -> usan 0
            elseif typeItem == "mask" or typeItem == "bag" or typeItem == "gpb" then
                --print("  → Es máscara/bolsa, usando 0")
                skin[comp1] = 0
                skin[comp2] = 0
                TriggerEvent("skinchanger:change", comp1, 0)
                TriggerEvent("skinchanger:change", comp2, 0)

                -- Clear equipped bag when unequipping (detect by type or component)
                if typeItem == "bag" or comp1 == "bags_1" then
                    -- Remove inventory weight bonus before clearing bag
                    TriggerServerEvent("vfw:bag:removeWeightBonus")
                    VFW.SetEquippedBag(nil, nil)
                    GetClothes["bag"] = false
                    -- Close bag inventory if open
                    if VFW.StateInventory() and VFW.PlayerData.target and VFW.PlayerData.target.bagUUID then
                        VFW.CloseInventory()
                    end
                end

                if typeItem == "gpb" then
                    TriggerServerEvent("vfw:bodyArmor:unequipped")
                end

                -- 3. TORSO / TOP / SHIRT
            elseif typeItem == "torso" or typeItem == "top" or typeItem == "shirt" then
                --print("  → Es torso/top/shirt, reseteando conjunto completo")
                local config = nakedSkin[playerSex]

                if not config then
                    --print("❌ ERROR CRÍTICO: No existe configuración nakedSkin para sexo:", playerSex)
                    return
                end

                skin["tshirt_1"] = config.tshirt_1
                skin["tshirt_2"] = 0
                skin["torso_1"] = config.torso_1
                skin["torso_2"] = 0
                skin["arms"] = config.arms
                skin["arms_2"] = 0

                TriggerEvent("skinchanger:change", "tshirt_1", config.tshirt_1)
                TriggerEvent("skinchanger:change", "tshirt_2", 0)
                TriggerEvent("skinchanger:change", "torso_1", config.torso_1)
                TriggerEvent("skinchanger:change", "torso_2", 0)
                TriggerEvent("skinchanger:change", "arms", config.arms)
                TriggerEvent("skinchanger:change", "arms_2", 0)

                -- 4. OTROS (Pantalones, zapatos usando la tabla base)
            else
                --print("  → Es otro tipo, usando tabla nakedSkin")
                local config = nakedSkin[playerSex]

                if not config then
                    --print("❌ ERROR CRÍTICO en línea 385: No existe configuración nakedSkin para sexo:", playerSex)
                    --print("Claves disponibles en nakedSkin:")
                    --for k, v in pairs(nakedSkin) do
                    --    print("  -", k)
                    --end
                    return
                end

                local nakedVal = 0

                if typeItem == "bottom" or typeItem == "pants" then
                    nakedVal = config.pants_1
                    --print("  → Usando pants_1:", nakedVal)
                elseif typeItem == "shoe" then
                    nakedVal = config.shoes_1
                    --print("  → Usando shoes_1:", nakedVal)
                elseif typeItem == "arms" then
                    nakedVal = config.arms
                end

                skin[comp1] = nakedVal
                skin[comp2] = 0
                TriggerEvent("skinchanger:change", comp1, nakedVal)
                TriggerEvent("skinchanger:change", comp2, 0)
            end

            -- Utiliser typeItem comme clé pour les accessoires (bag, bracelet, etc.)
            GetClothes[typeItem] = false

            if typeItem == "gpb" then
                TriggerServerEvent("vfw:gpb:markEquipped", false)
            end

        elseif meta.action == "on" then
            --print("🟢 EQUIPANDO PRENDA:", typeItem)

            playAnim(typeItem.."_on")

            if typeItem == "gpb" then
                local drawable = tonumber(meta.id) or (playerSex == "w" and 20 or 17)
                local texture = tonumber(meta.var) or 0

                skin[comp1] = drawable
                skin[comp2] = texture
                TriggerEvent("skinchanger:change", comp1, drawable)
                TriggerEvent("skinchanger:change", comp2, texture)
                GetClothes["gpb"] = true

                -- Marquer comme équipé côté serveur
                TriggerServerEvent("vfw:gpb:markEquipped", true)

                if meta.plates and #meta.plates > 0 then
                    local totalArmor = 0
                    for _, plate in ipairs(meta.plates) do
                        totalArmor = totalArmor + (plate.durability or 0)
                    end
                    totalArmor = math.min(totalArmor, 100)
                    if totalArmor > 0 then
                        SetPedArmour(PlayerPedId(), totalArmor)
                        TriggerEvent("vfw:armor:restorePlates", totalArmor)
                    end
                end

            -- Gérer les hauts composites avec meta.skin (top + undershirt + arms)
            elseif (typeItem == "top" or typeItem == "shirt") and meta.skin then
                --print("🔄 Haut composite détecté, application de tous les composants")
                for component, value in pairs(meta.skin) do
                    if value and value >= 0 then
                        skin[component] = value
                        TriggerEvent("skinchanger:change", component, value)
                        --print("  → " .. component .. " = " .. value)
                    end
                end
                -- Utiliser typeItem comme clé (top ou shirt)
                GetClothes[typeItem] = true
            else
                -- Items simples (non-composites)
                local safeId = meta.id or 0
                local safeVar = meta.var or 0

                skin[comp1] = safeId
                skin[comp2] = (safeVar < 0) and 0 or safeVar

                TriggerEvent("skinchanger:change", comp1, skin[comp1])
                TriggerEvent("skinchanger:change", comp2, skin[comp2])
                -- Utiliser typeItem comme clé pour les accessoires (bag, bracelet, etc.)
                GetClothes[typeItem] = true

                -- Set equipped bag when equipping a bag (detect by type or bag_uuid)
                local isBag = typeItem == "bag" or (meta.bag_uuid and comp1 == "bags_1")
                if isBag and meta.bag_uuid then
                    VFW.SetEquippedBag(meta.bag_uuid, meta)
                    -- Add inventory weight bonus from bag capacity (send drawable + sex for custom config lookup)
                    if meta.bag_capacity then
                        local bagDrawableId = meta.id or 0
                        local bagSex = meta.sex or "m"
                        TriggerServerEvent("vfw:bag:addWeightBonus", meta.bag_capacity, bagDrawableId, bagSex)
                    end
                end
            end

            --print("✅ Prenda equipada")
        end
    end

    -- Guardado final
    --print("💾 Guardando cambios en el servidor...")
    TriggerServerEvent("vfw:skin:save", skin)

    -- Mettre à jour le clone ped de l'inventaire si ouvert
    if VFW.HasClonedPed and VFW.HasClonedPed() then
        SetTimeout(150, function()
            if VFW.SyncPedAppearance then
                VFW.SyncPedAppearance()
            end
        end)
    end
    --print("=========================================")
end)