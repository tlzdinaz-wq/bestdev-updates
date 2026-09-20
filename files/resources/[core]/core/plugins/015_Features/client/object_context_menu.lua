---@meta _
---@diagnostic disable: duplicate-doc-field

--- AjustObject
---@param objS any
local function AjustObject(objS)
    local playerPed = VFW.PlayerData.ped
    local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
    local objCoords = coords + forward * 2.5
    local heading = GetEntityHeading(playerPed)
    local placed = false

    SetEntityHeading(objS, heading)
    PlaceObjectOnGroundProperly(objS)
    SetEntityAlpha(objS, 170, false)
    SetEntityCollision(objS, false, true)

    while not placed do
        coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
        objCoords = coords + forward * 2.5
        SetEntityCoords(objS, objCoords.x, objCoords.y, objCoords.z, false, false, false, true)
        PlaceObjectOnGroundProperly(objS)

        if IsControlPressed(0, 190) then
            heading = heading + 0.5
        elseif IsControlPressed(0, 189) then
            heading = heading - 0.5
        end

        SetEntityHeading(objS, heading)

        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour placer l'objet\n~INPUT_FRONTEND_LEFT~ ou ~INPUT_FRONTEND_RIGHT~ Pour faire pivoter l'objet")

        if VFW.Interact.JustPressed(0, 38) then
            placed = true
        end

        DisableControlAction(0, 22, true)

        Wait(0)
    end

    ResetEntityAlpha(objS)
    SetEntityCollision(objS, true, true)
    FreezeEntityPosition(objS, true)
end

VFW.ContextAddButton("object", ":box: Ramasser la boombox", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) == 1729911864 and NetworkGetEntityIsNetworked(object)
end, function(object)
    PickupBoombox(object)
end, {})

VFW.ContextAddButton("object", ":music: Utiliser la boombox", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) == 1729911864 and NetworkGetEntityIsNetworked(object)
end, function(object)
    OpenMusicRadioUI(object)
end, {})

VFW.ContextAddButton("object", " Mettre sur son épaule", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    local isAttached = IsEntityAttached(object)
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) == 1729911864 and not isAttached and NetworkGetEntityIsNetworked(object)
end, function(object)
    PorterBoombox(object)
end, {})

VFW.ContextAddButton("ped", ":pin: Poser la boombox", function(ped)
    -- Vérifier que c'est le joueur lui-même
    if ped ~= PlayerPedId() then
        return false
    end

    -- Vérifier qu'il y a une boombox proche attachée au joueur
    local closestBoombox = GetClosestObjectOfType(GetEntityCoords(ped), 3.0, `prop_boombox_01`, false)
    if closestBoombox == -1 then
        return false
    end

    local isAttached = IsEntityAttached(closestBoombox)
    local attachedTo = isAttached and GetEntityAttachedTo(closestBoombox) or 0

    return isAttached and attachedTo == ped
end, function(ped)
    PoseLaBoombox()
end, {})

local TV_Models = {}

CreateThread(function()
    local models = TriggerServerCallback("television:getModels")
    if models then
        for _, m in ipairs(models) do
            TV_Models[joaat(m.model)] = true
        end
    end
end)

RegisterNetEvent("ptelevision:syncModels", function(models)
    for hash, _ in pairs(models) do
        TV_Models[hash] = true
    end
end)

RegisterNetEvent("ptelevision:removeModel", function(modelHash)
    TV_Models[modelHash] = nil
end)

local function IsTvModel(object)
    return TV_Models[GetEntityModel(object)] == true
end

local tvSubmenu = VFW.ContextAddSubmenu("object", ":monitor: Télévision", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 25.0 and DoesEntityExist(object) and IsTvModel(object)
end, {}, nil)

VFW.ContextAddButton("object", ":arrow: Mettre une vidéo", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 25.0 and DoesEntityExist(object) and IsTvModel(object)
end, function(object)
    local coords = GetEntityCoords(object)
    local model = GetEntityModel(object)

    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local videoUrl = VFW.Nui.KeyboardInput(true, "Lien YouTube ou vidéo", "", 200)
        VFW.Nui.Focus(false)

        if videoUrl and videoUrl ~= "" and videoUrl ~= "KBD_CANCEL" then
            TriggerServerEvent("ptelevision:event", {coords = coords, model = model, entity = object}, "ptv_status", {
                type = "play",
                url = videoUrl
            })

            VFW.ShowNotification({
                type = 'VERT',
                content = "Vidéo lancée sur la TV"
           })
        end
    end)
end, {}, tvSubmenu)

VFW.ContextAddButton("object", ":megaphone: Gérer le volume", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 25.0 and DoesEntityExist(object) and IsTvModel(object)
end, function(object)
    local coords = GetEntityCoords(object)

    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local volume = VFW.Nui.KeyboardInput(true, "Volume (0-100)", "50", 3)
        VFW.Nui.Focus(false)

        if volume and volume ~= "" and volume ~= "KBD_CANCEL" and tonumber(volume) then
            local vol = math.max(0, math.min(100, tonumber(volume)))
            -- Trigger l'événement client de ptelevision pour changer le volume
            TriggerEvent("ptelevision:clientSetVolume", coords, vol / 100)

            VFW.ShowNotification({
                type = 'VERT',
                content = string.format("Volume réglé à %d%%", vol)
            })
        end
    end)
end, {}, tvSubmenu)

VFW.ContextAddButton("object", "⏹ Arrêter la vidéo", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 25.0 and DoesEntityExist(object) and IsTvModel(object)
end, function(object)
    local coords = GetEntityCoords(object)
    local model = GetEntityModel(object)

    -- Synchronisé server-side pour tous les joueurs
    TriggerServerEvent("ptelevision:event", {coords = coords, model = model, entity = object}, "ptv_status", {
        type = "stop"
   })

    VFW.ShowNotification({
        type = 'ORANGE',
        content = "Vidéo arrêtée"
   })
end, {}, tvSubmenu)

VFW.ContextAddButton("object", ":film: Gérer la vidéo", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    if distance >= 25.0 or not DoesEntityExist(object) or not IsTvModel(object) then
        return false
    end
    local coords = GetEntityCoords(object)
    local ok, result = pcall(exports["ptelevision"].IsVideoPlayingAt, exports["ptelevision"], coords)
    return ok and result
end, function(object)
    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(300)
        exports["ptelevision"]:OpenVideoController()
    end)
end, {}, tvSubmenu)

--region ------ Distributeurs

local VendingMachineModels = {
    "prop_vend_coffe_01",
    "prop_vend_soda_01",
    "prop_vend_soda_02",
    "prop_watercooler",
    "prop_vend_fridge01",
    "prop_vend_snak_01",
}

local VendingMachineIcons = {
    ["prop_vend_coffe_01"] = VFW.CDN.Get("icons/coffe_machine.png"),
    ["prop_vend_soda_01"] = VFW.CDN.Get("icons/ecola.webp"),
    ["prop_vend_soda_02"] = VFW.CDN.Get("icons/sprunk.png"),
    ["prop_watercooler"] = VFW.CDN.Get("icons/water_distributor.png"),
    ["prop_vend_fridge01"] = VFW.CDN.Get("icons/ecola.webp"),
    ["prop_vend_snak_01"] = VFW.CDN.Get("icons/donut.png"),
}

local VendingMachineHashes = {}
for _, model in ipairs(VendingMachineModels) do
    VendingMachineHashes[joaat(model)] = model
end

local function GetVendingMachineSettings()
    return GlobalState.VendingMachineSettings or {}
end

local function GetMachineData(model)
    local settings = GetVendingMachineSettings()
    local modelName = VendingMachineHashes[model]
    if modelName and settings[modelName] then
        return settings[modelName], modelName
    end
    return nil, nil
end

local isUsingVendingMachine = false
local lastMachineUse = {}

local function UseVendingMachine(object)
    if isUsingVendingMachine then return end

    local model = GetEntityModel(object)
    local machineData, modelName = GetMachineData(model)
    if not machineData then return end

    if machineData.cooldown and machineData.cooldown > 0 then
        local now = GetGameTimer()
        local lastUse = lastMachineUse[modelName] or 0
        if now - lastUse < machineData.cooldown then
            local remainingMs = machineData.cooldown - (now - lastUse)
            local remainingMin = math.ceil(remainingMs / 60000)
            VFW.ShowNotification({ type = 'ROUGE', content = "Attendez " .. remainingMin .. (remainingMin > 1 and " minutes." or " minute.") })
            return
        end
    end

    isUsingVendingMachine = true

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local machineCoords = GetEntityCoords(object)

    local dx = machineCoords.x - pedCoords.x
    local dy = machineCoords.y - pedCoords.y
    local heading = math.deg(math.atan2(-dx, dy))

    TaskTurnPedToFaceCoord(ped, machineCoords.x, machineCoords.y, machineCoords.z, 500)
    Wait(600)

    SetEntityHeading(ped, heading)
    Wait(100)

    local dict = "mini@sprunk"
   RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end

    TaskPlayAnim(ped, dict, "plyr_buy_drink_pt1", 8.0, -8.0, 2500, 0, 0, false, false, false)
    Wait(2500)

    ClearPedTasksImmediately(ped)

    local result = TriggerServerCallback("vfw:action:run", {
        action = "player:buyFromMachine",
        extra = {
            model = modelName
        }
    })

    if result and result.ok then
        if machineData.cooldown and machineData.cooldown > 0 then
            lastMachineUse[modelName] = GetGameTimer()
        end
        local labelCapitalized = machineData.label:sub(1,1):upper() .. machineData.label:sub(2)
        VFW.ShowNotification({
            type = "JOB",
            title = labelCapitalized,
            subtitle = "ACHAT EFFECTUÉ",
            logo = VendingMachineIcons[modelName],
            content = machineData.itemLabel .. " récupéré."
       })
    else
        local message = result and result.message or "Impossible d'utiliser le distributeur."
       if message:find("inventaire") then
            VFW.ShowNotification({
                type = "JOB",
                title = "Inventaire",
                subtitle = "CAPACITÉ MAXIMALE",
                logo = VFW.CDN.Get("icons/inventory.png"),
                content = message
            })
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = message
            })
        end
    end

    isUsingVendingMachine = false
end

local function IsVendingMachine(object)
    local model = GetEntityModel(object)
    return VendingMachineHashes[model] ~= nil
end

local function NormalizeItemLabel(label)
    if not label then return label end
    local lowerLabel = string.lower(label)
    if lowerLabel == "bouteille d'eau" then
        return "Eau"
   end
    return label
end

VFW.ContextAddInfo("object", " Distributeur", function(object)
    if not IsVendingMachine(object) then return false end
    if #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object)) > 2.5 then return false end
    local machineData = GetMachineData(GetEntityModel(object))
    return machineData ~= nil
end, function(object)
    local machineData = GetMachineData(GetEntityModel(object))
    if not machineData then return "" end
    local displayLabel = NormalizeItemLabel(machineData.itemLabel)
    if machineData.price > 0 then
        return displayLabel .. " - " .. VFW.Math.FormatMoney(machineData.price)
    else
        return displayLabel .. " - Gratuit"
   end
end, {}, nil)

VFW.ContextAddButton("object", " Acheter", function(object)
    if not IsVendingMachine(object) then return false end
    if #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object)) > 2.5 then return false end
    local machineData = GetMachineData(GetEntityModel(object))
    return machineData ~= nil and machineData.price > 0
end, function(object)
    UseVendingMachine(object)
end, {}, nil)

VFW.ContextAddButton("object", " Obtenir", function(object)
    if not IsVendingMachine(object) then return false end
    if #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object)) > 2.5 then return false end
    local machineData = GetMachineData(GetEntityModel(object))
    return machineData ~= nil and machineData.price == 0
end, function(object)
    UseVendingMachine(object)
end, {}, nil)

--endregion
--- ChairsandBedsRegion
-- VARIABLES GLOBALES
-- Sit system optimizado: menos redundancia, mismos comportamientos
-- Sit system optimizado: menos redundancia, mismos comportamientos
local SittingPeds = {}
local sitting = false
local localEntity = nil

local ListenerActive = {}
local BenchSlots = {}
local BenchReservations = {}

-- Parámetros de slot / calibración
local BENCH_Y_BACK = 0.35
local BENCH_X_SIDE = 0.60
local SLOT_OCCUPY_RADIUS = 0.35
local BENCH_INSET = -0.15
local BENCH_Z_ADJUST = -0.08

local SitTypes = {
    [`v_med_bed1`] = {
        label = ":home: S'coucher",
        type = "bed",
        zOffset = 0.65,
        pedZAdjust = -0.9
    },
    [`ch_chint03_campbedspz`] = {
        label = ":home: S'coucher",
        type = "bed",
        zOffset = 0.65,
        pedZAdjust = -0.9
    },
    [`h4_int_sub_bed`] = {
        label = ":home: S'coucher",
        type = "bed",
        zOffset = 0.65,
        pedZAdjust = -0.9
    },
    [`p_lestersbed_s`] = {
        label = ":home: S'coucher",
        type = "bed",
        zOffset = 0.65,
        pedZAdjust = -0.9
    },
    [`sm_charlie_bed`] = {
        label = ":home: S'coucher",
        type = "bed",
        zOffset = 0.65,
        pedZAdjust = -0.9
    },
    [`gr_prop_bunker_bed_01`] = {
        label = ":home: S'coucher",
        type = "bed",
        zOffset = 0.65,
        pedZAdjust = -0.9
    },
    [`v_med_bed2`] = {
        label = ":home: S'coucher",
        type = "bed",
        zOffset = 0.65,
        pedZAdjust = -0.9
    },
}


-- AnimationTypes (sin cambios funcionales)
local AnimationTypes = {
    [`normale`] = { label = "Normale", animation = { "Scenario", "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER" } },
    [`focus`] = { label = "Focus", animation = { "Scenario", "PROP_HUMAN_SEAT_STRIP_WATCH" } },
    [`Pensif`] = { label = "Pensif", animation = { "anim@amb@business@cfid@cfid_desk_no_work_bgen_chair_no_work@", "transition_wakeup_lazyworker" } },
    [`Brasdecôté`] = { label = "Bras de côté", animation = { "veh@truck@barracks@rds@base","lean_back_idle" } },
    [`Brascroisés`] = { label = "Bras croisés", animation = { "anim@scripted@charlie_missions@mission_5@ig2_avi_sitting@","idle_e" } },
    [`Regardantenbas`] = { label = "Regardant en bas", animation = { "anim@amb@business@cfm@cfm_machine_no_work@","sleep_cycle_v2_operator" } },
    -- Lying down animations (for couches)
    [`allonge`]       = { label = "S'allonger",       animation = { "savecouch@", "t_sleep_loop_couch" } },
    [`allongecote`]   = { label = "Allonge de cote",  animation = { "timetable@tracy@sleep@", "idle_c" } },
    [`allongesurdos`] = { label = "Sur le dos",        animation = { "anim@scripted@submarine@special_peds@pavel@hs4_pavel_ig3_sleep_p1", "base_idle" } },
    [`fetale`]        = { label = "Position foetale", animation = { "anim@amb@nightclub@lazlow@lo_alone@", "lowalone_base_laz" } },
}

local AnimationTypesBed = {
    [`côté`] = {
        label = "Allongé sur le côté, bras ouvert",
        animation = { "timetable@tracy@sleep@", "idle_c" },
        HeadingOffset = -80,
        zAdjust = 0.0
    },
    [`latéral`] = {
        label = "Allongé latéralement",
        animation = { "anim@scripted@submarine@special_peds@pavel@hs4_pavel_ig3_sleep_p1", "base_idle" },
        HeadingOffset = 0,
        zAdjust = -0.3
    },
    [`sur_le_dos`] = {
        label = "Allongé sur le dos",
        animation = { "savecouch@", "t_sleep_loop_couch" },
        HeadingOffset = 180,
        zAdjust = -0.4
    },
    [`fetale`] = {
        label = "Position fœtale",
        animation = { "anim@amb@nightclub@lazlow@lo_alone@", "lowalone_base_laz" },
        HeadingOffset = 180,
        zAdjust = 0.0
    },
    [`détendu`] = {
        label = "Allongé détendu",
        animation = { "amb@world_human_bum_slumped@male@laying_on_left_side@base", "base" },
        HeadingOffset = 240,
        zAdjust = 0.0
    }
}

-- Animation groups: limit available animations per model type
-- Add animGroup = "basic" to a SitTypes entry to restrict to only these anims
-- Models without animGroup (or nil) get all animations
-- Bench-like models (Scenario-based chairs) are auto-detected as "basic"
local AnimGroups = {
    basic = { [`normale`] = true, [`focus`] = true },
}

-- Per-model ground Z adjustments (raise/lower ped for specific chair models)
local ModelZAdjust = {
    [2051175944] = 0.50,
}

local SitAnimZCompensation = {
    [`normale`]        = 0,
    [`focus`]          = 0.011,
    [`Pensif`]         = 0.528,
    [`Brasdecôté`]     = -0.063,
    [`Brascroisés`]    = 0.060,
    [`Regardantenbas`] = 0.704,
}

local SitAnimForwardCompensation = {
    [`Pensif`]         = 0.05,
    [`Brasdecôté`]     = 0.05,
    [`Regardantenbas`] = 0.15,
}

local ChairAnimOverrides = {}

exports('applyChairAnimOverrides', function(overrides)
    ChairAnimOverrides = overrides or {}
end)

exports('getChairAnimOverrides', function()
    return ChairAnimOverrides
end)

exports('getChairSitTypes', function()
    return SitTypes
end)

exports('applyModelZAdjust', function(hash, value)
    if value and value ~= 0 then
        ModelZAdjust[hash] = value
    else
        ModelZAdjust[hash] = nil
    end
end)

-- Per-model custom sit positions from chair builder (local offset: {x, y, z, h})
local ChairSitPositions = {}

exports('applyChairSitPositions', function(positions)
    ChairSitPositions = positions or {}
end)

-- Wide-angle view for custom sit positions (uses gameplay camera, no scripted cam)
local savedCamViewMode = nil

local function ActivateSitView()
    savedCamViewMode = GetFollowPedCamViewMode()
    SetFollowPedCamViewMode(3)
end

local function RestoreSitView()
    if savedCamViewMode then
        SetFollowPedCamViewMode(savedCamViewMode)
        savedCamViewMode = nil
    end
end

-- Helpers de posición
local function GetBenchSlotCoords(entity, slot, zOffset)
    local x = (slot == "left" and -BENCH_X_SIDE) or (slot == "right" and BENCH_X_SIDE) or 0.0
    local base = GetOffsetFromEntityInWorldCoords(entity, x, -BENCH_Y_BACK, 0.0)
    return vec3(base.x, base.y, GetEntityCoords(entity).z + (zOffset or 0.6))
end

local function GetBenchSlotCoordsAdjusted(entity, slot, zOffset)
    local base = GetBenchSlotCoords(entity, slot, zOffset)
    local forward = GetOffsetFromEntityInWorldCoords(entity, 0.0, -BENCH_INSET, 0.0)
    return vec3((base.x + forward.x) * 0.5, (base.y + forward.y) * 0.5, base.z + BENCH_Z_ADJUST)
end

local function IsSlotOccupied(entity, slot)
    local slots = BenchSlots[entity]
    if slots and slots[slot] and DoesEntityExist(slots[slot]) then return true end
    local model = GetEntityModel(entity)
    local zOffset = SitTypes[model] and SitTypes[model].zOffset or 0.6
    local pos = GetBenchSlotCoords(entity, slot, zOffset)
    local localPed = PlayerPedId()
    if DoesEntityExist(localPed) and #(GetEntityCoords(localPed) - pos) < SLOT_OCCUPY_RADIUS then return true end
    local radius = SLOT_OCCUPY_RADIUS + 0.25
    local handle, pedFound = FindFirstPed()
    local success
    repeat
        if DoesEntityExist(pedFound) then
            if #(GetEntityCoords(pedFound) - pos) < radius and pedFound ~= localPed then EndFindPed(handle) return true end
        end
        success, pedFound = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    return false
end

local function FindFreeBenchSlot(entity)
    if not IsSlotOccupied(entity, "center") then return "center" end
    if not IsSlotOccupied(entity, "left") then return "left" end
    if not IsSlotOccupied(entity, "right") then return "right" end
    return nil
end

local function ReleaseBenchSlot(entity, slot, ped)
    if not entity or not slot then return end
    local slots = BenchSlots[entity]; if not slots then return end
    if slots[slot] == ped then slots[slot] = nil end
    if not (slots.center or slots.left or slots.right) then BenchSlots[entity] = nil end
end

-- ── Chair multi-slot helpers (server-side tracking) ──

--- Ask server to claim a free slot. Returns slotIdx or nil.
local function ClaimChairSlot(entity, positions)
    local modelHash = GetEntityModel(entity)
    local objPos = GetEntityCoords(entity)
    local slotIdx = TriggerServerCallback('chairSlot:claim', modelHash, objPos.x, objPos.y, objPos.z, #positions)
    return slotIdx
end

--- Tell server to release a slot (uses stored data, entity may no longer exist)
local function ReleaseChairSlot(chairModelHash, chairObjX, chairObjY, chairObjZ, slotIdx)
    if not chairModelHash or not slotIdx then return end
    TriggerServerCallback('chairSlot:release', chairModelHash, chairObjX, chairObjY, chairObjZ, slotIdx)
end

-- Estado / validación
local function CanSit(ped)
    if not ped or not DoesEntityExist(ped) then return false end
    if SittingPeds[ped] ~= nil then return false end
    for ent, info in pairs(BenchReservations) do if info and info.ped == ped then return true end end
    return not sitting
end

-- Utiles pequeños
local function NormalizeHeading(h) while h < 0 do h = h + 360 end while h >= 360 do h = h - 360 end return h end
local function FixZ(x,y,z,extra) local got,gz = GetGroundZFor_3dCoord(x,y,z+1.0,0) if got and gz then return gz + (extra or 0) end return z + (extra or 0) end
local function InvertHeading(h) return NormalizeHeading(h + 180) end

--- Get reliable ground Z under an entity
--- Uses GetGroundZFor_3dCoord (probes actual collision) with bounding box fallback
local function GetEntityGroundZ(entity)
    local ec = GetEntityCoords(entity)
    -- Method 1: Probe collision geometry from above entity
    local got, gz = GetGroundZFor_3dCoord(ec.x, ec.y, ec.z + 3.0, false)
    if got and gz > 0.0 then
        return gz
    end
    -- Method 2: Bounding box bottom (fallback for unloaded collision)
    local model = GetEntityModel(entity)
    local min, _ = GetModelDimensions(model)
    return ec.z + min.z
end

-- Dibujar marcador temporal
local function DrawTempMarker(x,y,z,r,g,b,a,duration,entity)
    Citizen.CreateThread(function()
        local start = GetGameTimer(); local dur = duration or 5000
        local gx,gy,gz = x,y,z local got,groundZ = GetGroundZFor_3dCoord(gx,gy,gz+1.0,0)
        local drawZ = (got and groundZ) and groundZ or z
        while GetGameTimer() - start < dur do
            if entity and not DoesEntityExist(entity) then break end
            DrawMarker(1,x,y,drawZ,0,0,0,0,0,0,0.2,0.2,0.2,r or 0,g or 255,b or 255,a or 100,false,true,2,nil,nil,false)
            Wait(0)
        end
    end)
end


-- "Press E to stand up" help notification (top-left HUD via VFW.ShowHelpNotification)
local sitExitHintActive = false

local function ShowSitExitHint()
    if sitExitHintActive then return end
    sitExitHintActive = true
    Citizen.CreateThread(function()
        while sitExitHintActive do
            VFW.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour vous relever")
            Wait(250)
        end
    end)
end

local function HideSitExitHint()
    sitExitHintActive = false
end

-- Exit Sit (limpia y restaura)
local function ExitSit(ped)
    HideSitExitHint()
    local state = SittingPeds[ped]
    if DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
    end

    if state then
        if state.wasTeleported and state.entity and DoesEntityExist(state.entity) then
            local entCoords = GetEntityCoords(state.entity)
            local heading = GetEntityHeading(state.entity)


            local offsetY = -0.2
            local offsetX = 0.6

            -- Calcular costados con heading aplicado
            local rad = math.rad(heading)
            local cosH = math.cos(rad)
            local sinH = math.sin(rad)

            local function offsetFrom(x, y)
                return vec3(
                        entCoords.x + x * cosH - y * sinH,
                        entCoords.y + x * sinH + y * cosH,
                        entCoords.z
                )
            end

            local right = offsetFrom(offsetX, offsetY)
            local left = offsetFrom(-offsetX, offsetY)

            -- Raycast para detectar pared
            local function IsBlocked(from, to)
                local ray = StartShapeTestRay(from.x, from.y, from.z + 0.5, to.x, to.y, to.z + 0.5, 1, state.entity, 0)
                local _, hit, _, _, _ = GetShapeTestResult(ray)
                return hit == 1
            end

            local rightBlocked = IsBlocked(entCoords, right)
            local leftBlocked = IsBlocked(entCoords, left)



            local target = nil
            if not rightBlocked then
                target = right

            elseif not leftBlocked then
                target = left

            else
                local fallback = GetOffsetFromEntityInWorldCoords(state.entity, 0.0, offsetY, 0.0)
                target = vec3(fallback.x, fallback.y, FixZ(fallback.x, fallback.y, fallback.z, 0.0))

            end

            local groundZ = FixZ(target.x, target.y, target.z, 0.0)

            SetEntityCoordsNoOffset(ped, target.x, target.y, groundZ, false, false, false)
        end

        if state.benchSlot and state.entity then
            ReleaseBenchSlot(state.entity, state.benchSlot, ped)
        end
        if state.chairSlot and state.chairModelHash then
            ReleaseChairSlot(state.chairModelHash, state.chairObjX, state.chairObjY, state.chairObjZ, state.chairSlot)
        end
        SittingPeds[ped] = nil
    else

        for ent, info in pairs(BenchReservations) do
            if info and info.ped == ped then
                BenchReservations[ent] = nil

                break
            end
        end
    end

    localEntity = nil
    sitting = false
    ListenerActive[ped] = false

    -- Destroy wide-angle camera if active
    RestoreSitView()

    -- Animación de salida
    local animDict, animName, durationMs = "anim@heists@box_carry@", "exit", 1000
    RequestAnimDict(animDict)
    local to = GetGameTimer() + 2000
    while not HasAnimDictLoaded(animDict) and GetGameTimer() < to do Wait(10) end
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, durationMs or -1, 0, 0, false, false, false)
    Wait((durationMs or 1000) + 80)
    ClearPedTasks(ped)
    ListenerActive[ped] = false
end



-- Exit listener
local function StartExitListener(ped)
    if ListenerActive[ped] then return end
    ListenerActive[ped] = true
    local state = SittingPeds[ped]
    if state and state.entity and DoesEntityExist(state.entity) then
        ShowSitExitHint(state.entity)
    end
    Citizen.CreateThread(function()
        while ListenerActive[ped] and (SittingPeds[ped] or sitting) do
            if not DoesEntityExist(ped) then ListenerActive[ped] = false; sitting = false break end
            if IsControlPressed(0,30) or IsControlPressed(0,31) or IsControlPressed(0,32) or IsControlPressed(0,33) or IsControlJustPressed(0,73) or IsControlJustPressed(0,245) or VFW.Interact.JustPressed(0, 38) then
                ClearPedTasks(ped); ExitSit(ped); break
            end
            Wait(100)
        end
        ListenerActive[ped] = false
    end)
end

-- WalkToFrontSit: walk ped to ground level in front of chair
-- The scenario handles seat height — ped must be at ground level
local function WalkToFrontSit(ped, entity, offset)
    if not DoesEntityExist(entity) or not DoesEntityExist(ped) then return end
    if not CanSit(ped) then return CanSit(ped) end
    sitting = true
    ClearPedTasksImmediately(ped); FreezeEntityPosition(entity, true)
    local groundZ = GetEntityGroundZ(entity)
    local sitHeading = (GetEntityHeading(entity) + 180.0) % 360.0
    local raw = GetOffsetFromEntityInWorldCoords(entity, 0.0, -(offset or 0.6), 0.0)
    local targetPos = vec3(raw.x, raw.y, groundZ)
    TaskGoStraightToCoord(ped, targetPos.x, targetPos.y, targetPos.z, 1.0, -1, sitHeading, 0.0)
    local start, reached = GetGameTimer(), false
    while GetGameTimer() - start < 4000 do
        if not DoesEntityExist(ped) then break end
        local pedPos = GetEntityCoords(ped)
        if #(vec3(pedPos.x, pedPos.y, 0) - vec3(targetPos.x, targetPos.y, 0)) <= 0.5 then reached = true break end
        Wait(100)
    end
    if not reached then
        sitting = true
        ClearPedTasks(ped)
        DoScreenFadeOut(150)
        Wait(150)
        SetEntityCollision(ped, false, false)
        SetEntityCoordsNoOffset(ped, targetPos.x, targetPos.y, targetPos.z, false, false, false)
        Wait(50)
        SetEntityCollision(ped, true, true)
        SetEntityHeading(ped, sitHeading)
        FreezeEntityPosition(entity, true)
        localEntity = entity
        SittingPeds[ped] = { wasTeleported = true, entity = entity, offset = offset or 0.6 }
        DoScreenFadeIn(150)
    else
        sitting = true
        SetEntityHeading(ped, sitHeading)
        FreezeEntityPosition(entity, true)
        localEntity = entity
        SittingPeds[ped] = { wasTeleported = false, entity = entity, offset = offset or 0.6 }
    end

    SetEntityHeading(ped, sitHeading)
    StartExitListener(ped)
end

-- Core sit: guarda anchor la primera vez y la reutiliza para cambios in-place (solución 1)
function sit(entity, newCoords, benchSlot, animationmood)
    local playerPed = PlayerPedId()
    if not CanSit(playerPed) then
        if not (animationmood and animationmood[1] and animationmood[2]) then return end
        local kind, name = tostring(animationmood[1]), tostring(animationmood[2])
        local playerCoords = GetEntityCoords(playerPed)
        local entityCoords = (entity and DoesEntityExist(entity)) and GetEntityCoords(entity) or playerCoords
        local entName = entity and (GetEntityArchetypeName(entity) or "") or ""
       local heading = entity and (GetEntityHeading(entity) + 180.0) or GetEntityHeading(playerPed)
        if entName == "prop_table_01_chr_b" then heading = heading + 90.0 end
        local scenarioZ = (entity and DoesEntityExist(entity)) and GetEntityGroundZ(entity) or playerCoords.z
        SittingPeds[playerPed] = SittingPeds[playerPed] or {}
        local sp = SittingPeds[playerPed]
        local useX, useY, useZ, useHeading
        if sp and sp.anchor then
            useX, useY, useZ, useHeading = sp.anchor.x, sp.anchor.y, sp.anchor.z, sp.anchor.heading
        else
            useX, useY, useZ, useHeading = entityCoords.x, entityCoords.y, scenarioZ, heading
        end
        if kind:lower() == "scenario" then
            ClearPedTasks(playerPed)
            Citizen.Wait(60)
            SetEntityCoordsNoOffset(playerPed, useX, useY, useZ, false, false, false)
            SetEntityHeading(playerPed, useHeading)
            if entity and DoesEntityExist(entity) then FreezeEntityPosition(entity, true) end
            TaskStartScenarioAtPosition(playerPed, name, useX, useY, useZ, useHeading, 0, true, true)
            return
        end

        if useHeading then SetEntityHeading(playerPed, useHeading) end
        RequestAnimDict(tostring(animationmood[1]))
        local to = GetGameTimer() + 2000
        while not HasAnimDictLoaded(tostring(animationmood[1])) and GetGameTimer() < to do Wait(10) end
        if HasAnimDictLoaded(tostring(animationmood[1])) then
            TaskPlayAnim(playerPed, tostring(animationmood[1]), tostring(animationmood[2]), 4.0, -4.0, -1, 49, 0, false, false, false)
        end
        return
    end

    if not DoesEntityExist(entity) or not DoesEntityExist(playerPed) then return end

    local playerCoords = GetEntityCoords(playerPed)
    local entityCoords = GetEntityCoords(entity)
    local name = GetEntityArchetypeName(entity) or ""
   local heading = GetEntityHeading(entity) + 180.0
    local model = GetEntityModel(entity)
    local data = SitTypes[model]
    local groundZ = GetEntityGroundZ(entity)
    local zAdj = ModelZAdjust[model]
    if zAdj then groundZ = groundZ + zAdj end

    if string.find(name:lower(), "bench") and newCoords then
        entityCoords = newCoords
    end
    if name == "prop_table_01_chr_b" then heading = heading + 90.0 end

    localEntity = entity
    FreezeEntityPosition(localEntity, true)

    if data and data.animation then
        local anim = data.animation
        if animationmood[1] == "Scenario" then
            TaskStartScenarioAtPosition(
                    playerPed,
                    animationmood[2],
                    entityCoords.x,
                    entityCoords.y,
                    groundZ,
                    heading,
                    0,
                    true,
                    true
            )
        else
            -- Pre-load custom animation dict while scenario plays
            local moodDict, moodName
            if animationmood and animationmood[1] and animationmood[2] then
                moodDict = tostring(animationmood[1])
                moodName = tostring(animationmood[2])
                RequestAnimDict(moodDict)
            end

            TaskStartScenarioAtPosition(
                    playerPed,
                    "PROP_HUMAN_SEAT_BENCH",
                    entityCoords.x,
                    entityCoords.y,
                    groundZ,
                    heading,
                    0,
                    true,
                    true
            )

            -- Wait for ped to enter scenario (dynamic instead of fixed 1700ms)
            local waitStart = GetGameTimer()
            while not IsPedUsingAnyScenario(playerPed) and GetGameTimer() - waitStart < 2000 do
                Wait(50)
            end
            Wait(600)

            if moodDict and moodName then
                local to = GetGameTimer() + 1000
                while not HasAnimDictLoaded(moodDict) and GetGameTimer() < to do Wait(10) end
                if HasAnimDictLoaded(moodDict) then
                    TaskPlayAnim(playerPed, moodDict, moodName, 8.0, -4.0, -1, 49, 0, false, false, false)
                end
            end
        end
    end

    sitting = true
    SittingPeds[playerPed] = SittingPeds[playerPed] or {}
    SittingPeds[playerPed].wasTeleported = SittingPeds[playerPed].wasTeleported or false
    SittingPeds[playerPed].entity = entity
    if benchSlot then SittingPeds[playerPed].benchSlot = benchSlot end
    SittingPeds[playerPed].anchor = {
        x = entityCoords.x,
        y = entityCoords.y,
        z = groundZ,
        heading = heading
    }

    StartExitListener(playerPed)
end


-- LayOnBed (reducido)
function LayOnBed(entity, animationData, addheading, addz)

    local ped = PlayerPedId()
    if not DoesEntityExist(entity) or not DoesEntityExist(ped) then return end

    local model = GetEntityModel(entity)
    local cfg = SitTypes[model]
    if not cfg or cfg.type ~= "bed" then return end

    -- Si ya está acostado en esta cama, solo cambiar animación
    local state = SittingPeds[ped]
    if state and state.isBed and state.entity == entity then
        SetEntityHeading(ped, GetEntityHeading(entity) + addheading)

        if animationData and animationData[1] and animationData[2] then
            local dict = animationData[1]
            local name = animationData[2]
            RequestAnimDict(dict)
            local timeout = GetGameTimer() + 2000
            while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(10) end

            if HasAnimDictLoaded(dict) then
                TaskPlayAnim(ped, dict, name, 8.0, -8.0, -1, 1, 0, false, false, false)

            else
            end
        else
        end
        return
    end


    -- Posicionamiento inicial
    local heading = GetEntityHeading(entity)
    local zOffset = cfg.zOffset or 0.65
    local raw = GetOffsetFromEntityInWorldCoords(entity, 0.0, 0.0, 0.0)
    local target = vec3(raw.x, raw.y, GetEntityCoords(entity).z + zOffset + addz)

    ClearPedTasksImmediately(ped)
    SetEntityCoordsNoOffset(ped, target.x, target.y, target.z , false, false, false)
    SetEntityHeading(ped, heading + addheading)
    FreezeEntityPosition(entity, true)
    localEntity = entity

    -- Animación inicial
    if animationData and animationData[1] and animationData[2] then
        local dict = animationData[1]
        local name = animationData[2]
        RequestAnimDict(dict)
        local timeout = GetGameTimer() + 2000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(10) end

        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(ped, dict, name, 8.0, -8.0, -1, 1, 0, false, false, false)
        else
            return
        end
    else
        return
    end

    SittingPeds[ped] = {
        wasTeleported = true,
        entity = entity,
        offset = 0.6,
        isBed = true
    }

    StartExitListener(ped)

end



-- PlayAnimationFromDefCompatible
-- Uses chair XY + ground Z at entity position (via collision probe)
local function PlayAnimationFromDefCompatible(animDef, ped, object, animOffsetTable, coordsFallback, can, zCompensation)
    if not animDef or type(animDef) ~= "table" or not animDef[1] then return end
    local kindLower = tostring(animDef[1]):lower()
    local animDict, animName = tostring(animDef[1]), tostring(animDef[2])
    local zComp = zCompensation or 0

    local entityCoords = object and GetEntityCoords(object) or coordsFallback
    local groundZ
    if object and DoesEntityExist(object) then
        groundZ = GetEntityGroundZ(object)
        local zAdj = ModelZAdjust[GetEntityModel(object)]
        if zAdj then groundZ = groundZ + zAdj end
    else
        groundZ = GetEntityCoords(ped).z
    end

    local targetHeading = nil
    if animOffsetTable and object then
        targetHeading = animOffsetTable.Heading and NormalizeHeading(GetEntityHeading(object) + animOffsetTable.Heading) or GetEntityHeading(object)
    elseif object then
        targetHeading = GetEntityHeading(object)
    else
        targetHeading = GetEntityHeading(ped)
    end
    if targetHeading then targetHeading = InvertHeading(targetHeading) end

    if can == false then
        if targetHeading then SetEntityHeading(ped, targetHeading) end

        if kindLower == "scenario" then
            ClearPedSecondaryTask(ped)
            TaskStartScenarioInPlace(ped, animName, 0, false)
            return
        end

        RequestAnimDict(animDict)
        local to = GetGameTimer() + 2000
        while not HasAnimDictLoaded(animDict) and GetGameTimer() < to do Wait(10) end
        if HasAnimDictLoaded(animDict) then
            TaskPlayAnim(ped, animDict, animName, 4.0, -4.0, -1, 49, 0, false, false, false)
        end
        return
    end

    if kindLower == "scenario" then
        TaskStartScenarioAtPosition(ped, animName, entityCoords.x, entityCoords.y, groundZ, targetHeading or GetEntityHeading(ped), 0, false, true)
        return
    end

    RequestAnimDict(animDict)

    TaskStartScenarioAtPosition(ped, "PROP_HUMAN_SEAT_CHAIR", entityCoords.x, entityCoords.y, groundZ + zComp, targetHeading or GetEntityHeading(ped), 0, false, true)

    local waitStart = GetGameTimer()
    while not IsPedUsingAnyScenario(ped) and GetGameTimer() - waitStart < 2000 do
        Wait(50)
    end
    Wait(600)

    local loadTimeout = GetGameTimer() + 1000
    while not HasAnimDictLoaded(animDict) and GetGameTimer() < loadTimeout do Wait(10) end
    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(ped, animDict, animName, 8.0, -4.0, -1, 49, 0, false, false, false)
    end
end


local ScenarioToAnim = {
    ["PROP_HUMAN_SEAT_CHAIR_MP_PLAYER"] = { "amb@prop_human_seat_chair@male@generic@idle_a", "idle_a" },
    ["PROP_HUMAN_SEAT_STRIP_WATCH"]     = { "amb@prop_human_seat_strip_watch@bouncy_guy@base", "base" },
}

-- Re-pose helper: ped is already seated on `object` (same chair), just swap the animation.
function ApplyChairPose(ped, object, sitPos, animDef, animKey)
    if not DoesEntityExist(object) or not DoesEntityExist(ped) or not sitPos then return end

    local objPos = GetEntityCoords(object)
    local objH = GetEntityHeading(object)
    local rad = math.rad(objH)
    local cosH, sinH = math.cos(rad), math.sin(rad)
    local worldZ = objPos.z + sitPos.z + (SitAnimZCompensation[animKey] or 0)
    local worldH = (objH + sitPos.h) % 360.0
    local fwdComp = SitAnimForwardCompensation[animKey] or 0
    local fwdRad = math.rad(worldH)
    local worldX = objPos.x + sitPos.x * cosH - sitPos.y * sinH + (-math.sin(fwdRad)) * fwdComp
    local worldY = objPos.y + sitPos.x * sinH + sitPos.y * cosH + math.cos(fwdRad) * fwdComp

    local animDict, animName
    if animDef and animDef[1] then
        local kindLower = tostring(animDef[1]):lower()
        if kindLower == "scenario" then
            local fallback = ScenarioToAnim[tostring(animDef[2])]
            if fallback then animDict, animName = fallback[1], fallback[2] end
        else
            animDict, animName = tostring(animDef[1]), tostring(animDef[2])
        end
        if animDict then
            RequestAnimDict(animDict)
            local to = GetGameTimer() + 2000
            while not HasAnimDictLoaded(animDict) and GetGameTimer() < to do Wait(10) end
        end
    end

    ClearPedTasks(ped)
    Wait(50)
    SetEntityCoordsNoOffset(ped, worldX, worldY, worldZ, false, false, false)
    SetEntityHeading(ped, worldH)

    if animDict and animName and HasAnimDictLoaded(animDict) then
        TaskPlayAnim(ped, animDict, animName, 8.0, -4.0, -1, 1, 0, false, false, false)
    end
end

-- Context buttons (mantén integración, reducido prints)
for model, data in pairs(SitTypes) do
    local subMenu = VFW.ContextAddSubmenu("object", data.label, function(object)
        local ped = VFW.PlayerData.ped
        if not DoesEntityExist(object) or not DoesEntityExist(ped) then return false end
        if sitting then return false end
        if GetEntityModel(object) ~= model then return false end
        if not ChairAnimOverrides[model] then return false end
        return #(GetEntityCoords(ped) - GetEntityCoords(object)) <= 3.0
    end, {}, nil)

    -- "Changer de pose" submenu: visible only while seated on this chair
    local changePoseSubMenu = (data.type == "chair") and VFW.ContextAddSubmenu("object", ":refresh: Changer de pose", function(object)
        local ped = VFW.PlayerData.ped
        if not DoesEntityExist(object) or not DoesEntityExist(ped) then return false end
        if not sitting then return false end
        local state = SittingPeds[ped]
        if not state or state.entity ~= object then return false end
        if GetEntityModel(object) ~= model then return false end
        if not ChairAnimOverrides[model] then return false end
        return true
    end, {}, nil) or nil

    local animSource = (data.type == "bed") and AnimationTypesBed or AnimationTypes
    -- Limit animations based on seat size (animGroup field on SitTypes entry)
    local allowedAnims = data.animGroup and AnimGroups[data.animGroup] or nil

    for k, v in pairs(animSource) do
        local checkVisible = function(object)
            local ped = VFW.PlayerData.ped
            if not DoesEntityExist(object) or not DoesEntityExist(ped) then return false end
            -- Dynamic filtering: check runtime overrides first, then static animGroup
            local m = GetEntityModel(object)
            local override = ChairAnimOverrides[m]
            if override then
                return override[k] == true
            end
            if allowedAnims and not allowedAnims[k] then
                return false
            end
            return true
        end
        local onClick = function(object)
            local ped = VFW.PlayerData.ped
            if not DoesEntityExist(object) or not DoesEntityExist(ped) then return end
            if data.type == "bed" then
                local bedAnim = data.animation
                if type(LayOnBed) == "function" then

                    LayOnBed(object, v.animation, v.HeadingOffset , v.zAdjust)
                elseif bedAnim and bedAnim[1] and bedAnim[2] then

                    WalkToFrontSit(ped, object, 0.6)
                    PlayAnimationFromDefCompatible(bedAnim, ped, object, nil, GetEntityCoords(object), true)
                else

                end
                return
            end
            if data.type == "chair" then
                local chairModel = GetEntityModel(object)
                local sitPositions = ChairSitPositions[chairModel]
                local name = GetEntityArchetypeName(object)
                local isBench = name and string.find(name:lower(), "bench")

                if sitPositions and #sitPositions > 0 then
                    -- Already sitting on this same chair? Just swap the pose.
                    local existingState = SittingPeds[ped]
                    if existingState and existingState.entity == object and existingState.chairSlot then
                        ApplyChairPose(ped, object, sitPositions[existingState.chairSlot], v.animation, k)
                        return
                    end

                    -- Multi-slot: ask server for a free slot
                    local slotIdx = ClaimChairSlot(object, sitPositions)
                    if not slotIdx then
                        VFW.ShowNotification({ type = 'ROUGE', content = "Pas de place disponible" })
                        return
                    end

                    local sitPos = sitPositions[slotIdx]
                    sitting = true
                    ClearPedTasksImmediately(ped)
                    FreezeEntityPosition(object, true)

                    local objPos = GetEntityCoords(object)
                    local objH = GetEntityHeading(object)
                    local rad = math.rad(objH)
                    local cosH, sinH = math.cos(rad), math.sin(rad)

                    local worldZ = objPos.z + sitPos.z + (SitAnimZCompensation[k] or 0)
                    local worldH = (objH + sitPos.h) % 360.0
                    local fwdComp = SitAnimForwardCompensation[k] or 0
                    local fwdRad = math.rad(worldH)
                    local worldX = objPos.x + sitPos.x * cosH - sitPos.y * sinH + (-math.sin(fwdRad)) * fwdComp
                    local worldY = objPos.y + sitPos.x * sinH + sitPos.y * cosH + math.cos(fwdRad) * fwdComp

                    local ScenarioToAnim = {
                        ["PROP_HUMAN_SEAT_CHAIR_MP_PLAYER"] = { "amb@prop_human_seat_chair@male@generic@idle_a", "idle_a" },
                        ["PROP_HUMAN_SEAT_STRIP_WATCH"]     = { "amb@prop_human_seat_strip_watch@bouncy_guy@base", "base" },
                    }

                    local animDef = v.animation
                    local animDict, animName
                    if animDef and animDef[1] then
                        local kindLower = tostring(animDef[1]):lower()
                        if kindLower == "scenario" then
                            local fallback = ScenarioToAnim[tostring(animDef[2])]
                            if fallback then
                                animDict = fallback[1]
                                animName = fallback[2]
                            end
                        else
                            animDict = tostring(animDef[1])
                            animName = tostring(animDef[2])
                        end
                        if animDict then
                            RequestAnimDict(animDict)
                            local to = GetGameTimer() + 5000
                            while not HasAnimDictLoaded(animDict) and GetGameTimer() < to do Wait(10) end
                        end
                    end

                    DoScreenFadeOut(150)
                    Wait(150)
                    FreezeEntityPosition(ped, true)
                    SetEntityCoordsNoOffset(ped, worldX, worldY, worldZ, false, false, false)
                    SetEntityHeading(ped, worldH)
                    Wait(50)

                    if animDict and animName and HasAnimDictLoaded(animDict) then
                        TaskPlayAnim(ped, animDict, animName, 8.0, -4.0, -1, 1, 0, false, false, false)
                    end

                    localEntity = object
                    SittingPeds[ped] = {
                        wasTeleported = true, entity = object, offset = 0.6,
                        chairSlot = slotIdx,
                        chairModelHash = chairModel,
                        chairObjX = objPos.x, chairObjY = objPos.y, chairObjZ = objPos.z
                    }
                    DoScreenFadeIn(150)
                    ActivateSitView()
                    StartExitListener(ped)
                elseif isBench then
                    local benchData = SitTypes[GetEntityModel(object)] or data
                    local slot = FindFreeBenchSlot(object); if not slot then return end
                    local slotCoords = GetBenchSlotCoordsAdjusted(object, slot, benchData.zOffset or 0.6)
                    sit(object, slotCoords, slot, v.animation); BenchReservations[object] = nil
                else
                    local can = WalkToFrontSit(ped, object, 0.6)
                    PlayAnimationFromDefCompatible(v.animation, ped, object, {
                        right_left_X = v.right_left_X or 0, forward_backwards_Y = v.forward_backwards_Y or 0,
                        up_down_z = v.up_down_z or 0, Heading = v.Heading or 0
                    }, GetEntityCoords(object), can, SitAnimZCompensation[k])
                    ShowSitExitHint(object)
                    Citizen.CreateThread(function()
                        ListenerActive[ped] = true
                        while SittingPeds[ped] do
                            if not DoesEntityExist(ped) then break end
                            if IsControlPressed(0,30) or IsControlPressed(0,31) or IsControlPressed(0,32) or IsControlPressed(0,33) or IsControlJustPressed(0,73) or VFW.Interact.JustPressed(0, 38) then
                                ExitSit(ped); break
                            end
                            Wait(100)
                        end
                        ListenerActive[ped] = false
                    end)
                end
                return
            end
            WalkToFrontSit(ped, object, 0.6)
            if data.animation then PlayAnimationFromDefCompatible(data.animation, playerPed, object, nil, GetEntityCoords(object), true) end
        end

        VFW.ContextAddButton("object", v.label, checkVisible, onClick, {}, subMenu, {})
        if changePoseSubMenu then
            VFW.ContextAddButton("object", v.label, checkVisible, onClick, {}, changePoseSubMenu, {})
        end
    end
end

-- Dynamic context menu for configured chairs NOT in SitTypes (builder-only configs)
local configuredChairSubMenu = VFW.ContextAddSubmenu("object", ":box: S'asseoir", function(object)
    local ped = VFW.PlayerData.ped
    if not DoesEntityExist(object) or not DoesEntityExist(ped) then return false end
    if sitting then return false end
    local model = GetEntityModel(object)
    -- Only show for models that are configured but NOT already in SitTypes
    if SitTypes[model] then return false end
    if not ChairAnimOverrides[model] then return false end
    return #(GetEntityCoords(ped) - GetEntityCoords(object)) <= 3.0
end, {}, nil)

-- "Changer de pose" submenu for configured chairs: visible only while seated on this chair
local configuredChangePoseSubMenu = VFW.ContextAddSubmenu("object", ":refresh: Changer de pose", function(object)
    local ped = VFW.PlayerData.ped
    if not DoesEntityExist(object) or not DoesEntityExist(ped) then return false end
    if not sitting then return false end
    local state = SittingPeds[ped]
    if not state or state.entity ~= object then return false end
    local model = GetEntityModel(object)
    if SitTypes[model] then return false end
    if not ChairAnimOverrides[model] then return false end
    return true
end, {}, nil)

for k, v in pairs(AnimationTypes) do
    local checkVisible = function(object)
        local ped = VFW.PlayerData.ped
        if not DoesEntityExist(object) or not DoesEntityExist(ped) then return false end
        local m = GetEntityModel(object)
        -- Only for non-SitTypes configured models
        if SitTypes[m] then return false end
        local override = ChairAnimOverrides[m]
        if not override then return false end
        return override[k] == true
    end
    local onClick = function(object)
        local ped = VFW.PlayerData.ped
        if not DoesEntityExist(object) or not DoesEntityExist(ped) then return end

        local chairModel = GetEntityModel(object)
        local sitPositions = ChairSitPositions[chairModel]

        if sitPositions and #sitPositions > 0 then
            -- Already sitting on this same chair? Just swap the pose.
            local existingState = SittingPeds[ped]
            if existingState and existingState.entity == object and existingState.chairSlot then
                ApplyChairPose(ped, object, sitPositions[existingState.chairSlot], v.animation, k)
                return
            end

            local slotIdx = ClaimChairSlot(object, sitPositions)
            if not slotIdx then
                VFW.ShowNotification({ type = 'ROUGE', content = "Pas de place disponible" })
                return
            end

            local sitPos = sitPositions[slotIdx]
            sitting = true
            ClearPedTasksImmediately(ped)
            FreezeEntityPosition(object, true)

            local objPos = GetEntityCoords(object)
            local objH = GetEntityHeading(object)
            local rad = math.rad(objH)
            local cosH, sinH = math.cos(rad), math.sin(rad)

            local worldZ = objPos.z + sitPos.z + (SitAnimZCompensation[k] or 0)
            local worldH = (objH + sitPos.h) % 360.0
            local fwdComp = SitAnimForwardCompensation[k] or 0
            local fwdRad = math.rad(worldH)
            local worldX = objPos.x + sitPos.x * cosH - sitPos.y * sinH + (-math.sin(fwdRad)) * fwdComp
            local worldY = objPos.y + sitPos.x * sinH + sitPos.y * cosH + math.cos(fwdRad) * fwdComp

            local ScenarioToAnim = {
                ["PROP_HUMAN_SEAT_CHAIR_MP_PLAYER"] = { "amb@prop_human_seat_chair@male@generic@idle_a", "idle_a" },
                ["PROP_HUMAN_SEAT_STRIP_WATCH"]     = { "amb@prop_human_seat_strip_watch@bouncy_guy@base", "base" },
            }

            local animDef = v.animation
            local animDict, animName
            if animDef and animDef[1] then
                local kindLower = tostring(animDef[1]):lower()
                if kindLower == "scenario" then
                    local fallback = ScenarioToAnim[tostring(animDef[2])]
                    if fallback then
                        animDict = fallback[1]
                        animName = fallback[2]
                    end
                else
                    animDict = tostring(animDef[1])
                    animName = tostring(animDef[2])
                end
                if animDict then
                    RequestAnimDict(animDict)
                    local to = GetGameTimer() + 5000
                    while not HasAnimDictLoaded(animDict) and GetGameTimer() < to do Wait(10) end
                end
            end

            DoScreenFadeOut(150)
            Wait(150)
            FreezeEntityPosition(ped, true)
            SetEntityCoordsNoOffset(ped, worldX, worldY, worldZ, false, false, false)
            SetEntityHeading(ped, worldH)
            Wait(50)

            if animDict and animName and HasAnimDictLoaded(animDict) then
                TaskPlayAnim(ped, animDict, animName, 8.0, -4.0, -1, 1, 0, false, false, false)
            end

            localEntity = object
            SittingPeds[ped] = {
                wasTeleported = true, entity = object, offset = 0.6,
                chairSlot = slotIdx,
                chairModelHash = chairModel,
                chairObjX = objPos.x, chairObjY = objPos.y, chairObjZ = objPos.z
            }
            DoScreenFadeIn(150)
            ActivateSitView()
            StartExitListener(ped)
        else
            local can = WalkToFrontSit(ped, object, 0.6)
            PlayAnimationFromDefCompatible(v.animation, ped, object, nil, GetEntityCoords(object), can, SitAnimZCompensation[k])
            ShowSitExitHint(object)
            Citizen.CreateThread(function()
                ListenerActive[ped] = true
                while SittingPeds[ped] do
                    if not DoesEntityExist(ped) then break end
                    if IsControlPressed(0,30) or IsControlPressed(0,31) or IsControlPressed(0,32) or IsControlPressed(0,33) or IsControlJustPressed(0,73) or VFW.Interact.JustPressed(0, 38) then
                        ExitSit(ped); break
                    end
                    Wait(100)
                end
                ListenerActive[ped] = false
            end)
        end
    end

    VFW.ContextAddButton("object", v.label, checkVisible, onClick, {}, configuredChairSubMenu, {})
    VFW.ContextAddButton("object", v.label, checkVisible, onClick, {}, configuredChangePoseSubMenu, {})
end

-- "Se relever" button: visible only when the player is sitting on this chair/bench
VFW.ContextAddButton("object", ":user: Se relever", function(object)
    local ped = VFW.PlayerData.ped
    if not ped or not DoesEntityExist(ped) then return false end
    if not sitting then return false end
    local state = SittingPeds[ped]
    if not state then return false end
    -- Show only on the chair the player is sitting on
    return state.entity == object or localEntity == object
end, function(object)
    local ped = VFW.PlayerData.ped
    if not ped or not DoesEntityExist(ped) then return end
    ClearPedTasks(ped)
    ExitSit(ped)
end, {}, nil, {})







