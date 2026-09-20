---@meta _
---@diagnostic disable: duplicate-doc-field

-- ═══════════════════════════════════════════════════════════════
-- Hub de gestion > Développeurs : panneaux natifs (NUI)
--
-- Chaque outil expose trois entrées génériques au NUI :
--   gestion:dev:open  { tool }                 -> { ok, data }
--   gestion:dev:call  { tool, action, args }   -> résultat de l'action
--   gestion:dev:close { tool }                 -> nettoyage (previews, skin...)
-- La logique métier réutilise exactement les callbacks / events serveur des
-- anciens menus VUI (developers.lua, gestionItems.lua, carlist.lua, ...).
-- ═══════════════════════════════════════════════════════════════

local OPEN, CALL, CLOSE = {}, {}, {}

local function Perms()
    return (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
end

local function Has(...)
    local perms = Perms()
    if perms["gestion"] then return true end
    for i = 1, select("#", ...) do
        if perms[select(i, ...)] then return true end
    end
    return false
end

local function Fail(msg) return { ok = false, error = msg } end
local function Ok(t) t = t or {}; t.ok = true; return t end

local function Str(v, max)
    if type(v) ~= "string" then return nil end
    v = v:gsub("^%s+", ""):gsub("%s+$", "")
    if v == "" then return nil end
    return max and v:sub(1, max) or v
end

local function Notify(variant, subtitle, message)
    VFW.ShowNotification({ type = 'STAFF', variant = variant, subtitle = subtitle, message = message })
end

--- Cache le hub et rend les contrôles au jeu (outils "monde" : freecam, gizmo...).
--- Retour au hub avec Retour arrière ou Échap.
local worldMode = false
local function EnterWorldMode(hint)
    if worldMode then return end
    worldMode = true
    StaffMenu.CoverGestionHub()
    VFW.Nui.Focus(false)
    CreateThread(function()
        while worldMode do
            Wait(0)
            if hint then
                VFW.ShowHelpNotification(hint)
            end
            if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 194) then
                worldMode = false
                Wait(150)
                if StaffMenu.IsGestionHubOpen() then
                    StaffMenu.UncoverGestionHub()
                end
            end
        end
    end)
end

local function LeaveWorldMode()
    worldMode = false
end

--- Liste paginée + recherche sur une table déjà triée.
local function Paginate(list, page, perPage)
    local total = #list
    local pages = math.max(1, math.ceil(total / perPage))
    page = math.max(1, math.min(tonumber(page) or 1, pages))
    local out = {}
    for i = (page - 1) * perPage + 1, math.min(page * perPage, total) do
        out[#out + 1] = list[i]
    end
    return { items = out, page = page, pages = pages, total = total }
end

local function Contains(hay, needle)
    return string.find(string.lower(tostring(hay or "")), needle, 1, true) ~= nil
end

-- ═══════════════════════════════════════════════════════════════
-- Création de caméra (camera.lua) — freecam AdminFreecam + config JSON
-- ═══════════════════════════════════════════════════════════════

local CAM_OPTIONS = {
    dofStrength = { "0.0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1.0" },
    transition  = { "0.0", "0.5", "1.0", "1.5", "2.0", "2.5", "3.0", "3.5", "4.0", "4.5", "5.0", "10.0", "15.0", "20.0", "30.0", "40.0", "50.0", "60.0" },
    effect      = { "Aucun", "DEATH_FAIL_IN_EFFECT_SHAKE", "DRUNK_SHAKE", "FAMILY5_DRUG_TRIP_SHAKE", "HAND_SHAKE", "JOLT_SHAKE", "LARGE_EXPLOSION_SHAKE", "MEDIUM_EXPLOSION_SHAKE", "SMALL_EXPLOSION_SHAKE", "ROAD_VIBRATION_SHAKE", "SKY_DIVING_SHAKE", "VIBRATE_SHAKE" },
    amplitude   = { "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1.0" },
    fov         = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "20", "30", "40", "50", "60", "70", "80", "90" },
}
local camState = { invisible = false, dof = false, dofStrength = 0.0, transition = 0.0, effect = "Aucun", amplitude = 0.5, fov = 45, freeze = false, preview = false }
local pastedCam = nil

local function CamHandle()
    return AdminFreecam and AdminFreecam._internal_camera or nil
end

OPEN.camera = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    CameraSettingsCopy = CameraSettingsCopy or {}
    return Ok({ state = camState, options = CAM_OPTIONS })
end

CALL.camera = function(action, a)
    a = a or {}
    if action == "set" then
        local cam = CamHandle()
        local k, v = a.key, a.value
        if k == "invisible" then
            camState.invisible = v == true
            CameraSettingsCopy.Invisible = camState.invisible
            SetEntityVisible(VFW.PlayerData.ped, not camState.invisible)
        elseif k == "dof" then
            camState.dof = v == true
            CameraSettingsCopy.Dof = camState.dof
        elseif k == "freeze" then
            camState.freeze = v == true
            if AdminFreecam then AdminFreecam.SetFreecamFrozen(camState.freeze) end
        elseif k == "dofStrength" then
            camState.dofStrength = tonumber(v) or 0.0
            CameraSettingsCopy.DofStrength = camState.dofStrength
            if cam then
                if camState.dofStrength > 0 then
                    SetCamUseShallowDofMode(cam, true)
                    SetCamNearDof(cam, 0.6)
                    SetCamFarDof(cam, 4.0)
                    SetCamDofStrength(cam, camState.dofStrength)
                else
                    SetCamUseShallowDofMode(cam, false)
                end
            end
        elseif k == "transition" then
            camState.transition = tonumber(v) or 0.0
            CameraSettingsCopy.Transition = camState.transition
        elseif k == "effect" then
            camState.effect = tostring(v or "Aucun")
            if camState.effect == "Aucun" then
                if cam then ShakeCam(cam, "DRUNK_SHAKE", 0.0) end
                CameraSettingsCopy.CamEffects = nil
            else
                if cam then ShakeCam(cam, camState.effect, camState.amplitude) end
                CameraSettingsCopy.CamEffects = camState.effect
            end
        elseif k == "amplitude" then
            camState.amplitude = tonumber(v) or 0.5
            CameraSettingsCopy.CamEffectsAmplitude = camState.amplitude
            if cam and CameraSettingsCopy.CamEffects then ShakeCam(cam, CameraSettingsCopy.CamEffects, camState.amplitude) end
        elseif k == "fov" then
            camState.fov = tonumber(v) or 45
            CameraSettingsCopy.Fov = camState.fov + 0.1
            if cam then SetCamFov(cam, camState.fov + 0.1) end
        end
        return Ok({ state = camState })
    elseif action == "preview" then
        if not AdminFreecam then return Fail("Freecam indisponible.") end
        local on = a.on == true
        camState.preview = on
        AdminFreecam.SetFreecamActive(on)
        if on then
            EnterWorldMode("Freecam : ~INPUT_CELLPHONE_CANCEL~ pour revenir au menu")
        end
        return Ok({ state = camState })
    elseif action == "copy" then
        local cam = CamHandle()
        if not cam or not DoesCamExist(cam) then return Fail("Activez d'abord la prévisualisation (freecam).") end
        local ped = VFW.PlayerData.ped
        local pedCoords = GetEntityCoords(ped)
        CameraSettingsCopy.CamRot = GetCamRot(cam)
        CameraSettingsCopy.CamCoords = GetCamCoord(cam)
        CameraSettingsCopy.OffsetPlayer = GetOffsetFromEntityGivenWorldCoords(ped, CameraSettingsCopy.CamCoords.x, CameraSettingsCopy.CamCoords.y, CameraSettingsCopy.CamCoords.z)
        local rot = GetCamRot(cam)
        local rx, rz = math.rad(rot.x), math.rad(rot.z)
        local dir = { x = -math.sin(rz) * math.abs(math.cos(rx)), y = math.cos(rz) * math.abs(math.cos(rx)), z = math.sin(rx) }
        local dest = { x = CameraSettingsCopy.CamCoords.x + dir.x * 5.0, y = CameraSettingsCopy.CamCoords.y + dir.y * 5.0, z = CameraSettingsCopy.CamCoords.z + dir.z * 5.0 }
        CameraSettingsCopy.OffsetLook = GetOffsetFromEntityGivenWorldCoords(ped, dest.x, dest.y, dest.z)
        CameraSettingsCopy.COH = vector4(pedCoords.x, pedCoords.y, pedCoords.z, GetEntityHeading(ped))
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local c = GetEntityCoords(veh)
            CameraSettingsCopy.COH = vector4(c.x, c.y, c.z, GetEntityHeading(veh))
            CameraSettingsCopy.Vehicle = GetEntityModel(veh)
        end
        local anim = VFW.GetPedAnimationIsPlaying()
        if anim then CameraSettingsCopy.Animation = { anim = anim[2], dict = anim[1] } end
        CameraSettingsCopy.Fov = camState.fov + 0.1
        local text = json.encode(CameraSettingsCopy)
        VFW.Clipboard(text)
        return Ok({ json = text })
    elseif action == "paste" then
        local ok, data = pcall(json.decode, tostring(a.json or ""))
        if not ok or type(data) ~= "table" or not data.CamCoords or not data.CamRot then
            return Fail("Configuration invalide (JSON attendu avec CamCoords / CamRot).")
        end
        local ped = VFW.PlayerData.ped
        if pastedCam and DoesCamExist(pastedCam) then
            DestroyCam(pastedCam, false)
            RenderScriptCams(false, false, 0, true, true)
        end
        if data.COH then
            SetEntityVisible(ped, data.Invisible ~= true)
            SetEntityCoords(ped, data.COH.x, data.COH.y, data.COH.z - 0.9)
            SetEntityHeading(ped, data.COH.w or 0.0)
        end
        if data.Animation and data.Animation.dict then
            RequestAnimDict(data.Animation.dict)
            local t = 0
            while not HasAnimDictLoaded(data.Animation.dict) and t < 200 do Wait(0) t = t + 1 end
            TaskPlayAnim(ped, data.Animation.dict, data.Animation.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
        end
        local fov = tonumber(data.Fov) or 45.0
        pastedCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", data.CamCoords.x, data.CamCoords.y, data.CamCoords.z, data.CamRot.x, data.CamRot.y, data.CamRot.z, fov, true, 0)
        SetCamActive(pastedCam, true)
        if data.Dof then
            SetCamUseShallowDofMode(pastedCam, true)
            SetCamNearDof(pastedCam, 0.6)
            SetCamFarDof(pastedCam, 4.0)
            SetCamDofStrength(pastedCam, tonumber(data.DofStrength) or 1.0)
        end
        local transition = tonumber(data.Transition) or 0
        RenderScriptCams(true, transition > 0, math.floor(transition * 1000), true, true)
        if data.Dof then
            local cam = pastedCam
            CreateThread(function()
                while DoesCamExist(cam) do
                    Wait(0)
                    SetUseHiDof()
                end
            end)
        end
        EnterWorldMode("Aperçu : ~INPUT_CELLPHONE_CANCEL~ pour revenir au menu")
        return Ok()
    elseif action == "stopPaste" then
        if pastedCam and DoesCamExist(pastedCam) then
            SetCamActive(pastedCam, false)
            DestroyCam(pastedCam, false)
            RenderScriptCams(false, false, 0, true, true)
            ClearPedTasks(VFW.PlayerData.ped)
        end
        pastedCam = nil
        return Ok()
    end
    return Fail("Action inconnue.")
end

CLOSE.camera = function()
    LeaveWorldMode()
    if pastedCam and DoesCamExist(pastedCam) then
        SetCamActive(pastedCam, false)
        DestroyCam(pastedCam, false)
        RenderScriptCams(false, false, 0, true, true)
        ClearPedTasks(VFW.PlayerData.ped)
        pastedCam = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- Prop placer (prop_placer.lua) — outil monde (gizmo), panneau de contrôle
-- ═══════════════════════════════════════════════════════════════

OPEN.propplacer = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    if not StaffMenu.isInDevMode then return Fail("Activez le mode développeur pour utiliser cet outil.") end
    if not PropPlacer or not PropPlacer.Toggle then return Fail("Prop Placer non disponible.") end
    return Ok({ active = PropPlacer.active == true })
end

CALL.propplacer = function(action, a)
    a = a or {}
    if not PropPlacer then return Fail("Prop Placer non disponible.") end
    if action == "start" then
        if not PropPlacer.active then PropPlacer.Toggle() end
        EnterWorldMode("Prop placer : G os, H gizmo, ~INPUT_CELLPHONE_CANCEL~ retour menu")
        return Ok({ active = PropPlacer.active == true })
    elseif action == "world" then
        if not PropPlacer.active then return Fail("Démarrez d'abord le Prop Placer.") end
        EnterWorldMode("Prop placer : G os, H gizmo, ~INPUT_CELLPHONE_CANCEL~ retour menu")
        return Ok()
    elseif action == "stop" then
        if PropPlacer.active then PropPlacer.Toggle() end
        return Ok({ active = PropPlacer.active == true })
    elseif action == "ped" then
        local m = Str(a.model, 64); if not m then return Fail("Modèle manquant.") end
        if not PropPlacer.active then return Fail("Démarrez d'abord le Prop Placer.") end
        PropPlacer.ChangePedModel(m)
        return Ok()
    elseif action == "object" then
        local m = Str(a.model, 64); if not m then return Fail("Modèle manquant.") end
        if not PropPlacer.active then return Fail("Démarrez d'abord le Prop Placer.") end
        PropPlacer.ChangeObjectModel(m)
        return Ok()
    elseif action == "anim" then
        local d, n = Str(a.dict, 128), Str(a.anim, 128)
        if not d or not n then return Fail("Dictionnaire et animation obligatoires.") end
        if not PropPlacer.active then return Fail("Démarrez d'abord le Prop Placer.") end
        PropPlacer.PlayAnimation(d, n)
        return Ok()
    elseif action == "copy" then
        if not PropPlacer.active then return Fail("Démarrez d'abord le Prop Placer.") end
        local d = PropPlacer.data or {}
        local pos = d.posOffset or vec3(0.0, 0.0, 0.0)
        local rot = d.rotOffset or vec3(0.0, 0.0, 0.0)
        local bone = d.selectedBoneTag or 57005
        local text = string.format("{\n    offset = vec3(%.3f, %.3f, %.3f),\n    rotation = vec3(%.3f, %.3f, %.3f),\n    boneTag = 0x%X,\n    rotOrder = 0 -- YXZ\n}", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, bone)
        VFW.Clipboard(text)
        return Ok({ text = text })
    elseif action == "import" then
        local t = Str(a.text, 2000); if not t then return Fail("Configuration vide.") end
        if not PropPlacer.active then return Fail("Démarrez d'abord le Prop Placer.") end
        PropPlacer.ImportResult(t)
        return Ok()
    end
    return Fail("Action inconnue.")
end

CLOSE.propplacer = function() LeaveWorldMode() end

-- ═══════════════════════════════════════════════════════════════
-- Items (gestionItems.lua)
-- ═══════════════════════════════════════════════════════════════

local ITEM_TYPES = {
    { value = "objects",    label = "Objet standard" },
    { value = "consumable", label = "Consommable" },
    { value = "drugs",      label = "Drogue" },
    { value = "weapon",     label = "Arme" },
    { value = "ammo",       label = "Munition" },
    { value = "component",  label = "Composant d'arme" },
    { value = "tint",       label = "Teinte d'arme" },
    { value = "gpb",        label = "GPB" },
}

local function inferRawType(item)
    if item.data and type(item.data.type) == "string" and item.data.type ~= "" then return item.data.type end
    if item.type == "weapons" then return "weapon" end
    if item.type == "food" then return "consumable" end
    if item.type == "items" then return "objects" end
    return nil
end

local function itemImageUrl(name, item)
    if VFW.ItemImageUrl then return VFW.ItemImageUrl(name, item) end
    local raw
    if type(item) == "table" then
        if type(item.image) == "string" and item.image ~= "" then raw = item.image end
        if type(item.data) == "table" and type(item.data.image) == "string" and item.data.image ~= "" then
            raw = item.data.image
        end
    end
    if type(raw) == "string" and (raw:sub(1, 7) == "http://" or raw:sub(1, 8) == "https://" or raw:sub(1, 6) == "nui://") then
        return raw
    end
    local path = (type(raw) == "string" and raw ~= "") and raw or ("items/" .. tostring(name) .. ".webp")
    if VFW.CdnUrl then return VFW.CdnUrl(path) end
    return path
end

local function toBool(v) return v == true or v == 1 or v == "1" end

local saveItemVersion = 0
local saveItemResult = nil
RegisterNetEvent("vfw:staff:saveItem:response", function(success)
    saveItemVersion = saveItemVersion + 1
    saveItemResult = success
end)

OPEN.items = function()
    if not Has("gestion_items") then return Fail("Permission gestion_items requise.") end
    local count = 0
    for _ in pairs(VFW.Items or {}) do count = count + 1 end
    return Ok({ types = ITEM_TYPES, count = count })
end

CALL.items = function(action, a)
    a = a or {}
    if action == "list" then
        local q = Str(a.query); q = q and string.lower(q) or nil
        local list = {}
        for name, item in pairs(VFW.Items or {}) do
            local label = item.label or name
            if not q or Contains(name, q) or Contains(label, q) then
                list[#list + 1] = { name = name, label = label, weight = item.weight or 0, type = inferRawType(item), premium = toBool(item.premium), imageUrl = itemImageUrl(name, item) }
            end
        end
        table.sort(list, function(x, y) return string.lower(x.label) < string.lower(y.label) end)
        return Ok(Paginate(list, a.page, 24))
    elseif action == "get" then
        local item = VFW.Items and VFW.Items[a.name or ""]
        if not item then return Fail("Item introuvable.") end
        local data = {}
        for k, v in pairs(item.data or {}) do data[k] = v end
        data.type = data.type or inferRawType(item)
        return Ok({ item = { name = a.name, label = item.label, weight = item.weight, premium = toBool(item.premium), perm = toBool(item.perm), data = data } })
    elseif action == "create" then
        local name = Str(a.name, 64); if not name then return Fail("Le nom est obligatoire.") end
        name = string.lower(name)
        if VFW.Items[name] then return Fail(("Un item nommé '%s' existe déjà."):format(name)) end
        local label = Str(a.label, 64); if not label then return Fail("Le label est obligatoire.") end
        local weight = tonumber(a.weight); if not weight then return Fail("Le poids est obligatoire.") end
        local data = type(a.data) == "table" and a.data or {}
        if not data.type then return Fail("Choisissez un type d'item.") end
        TriggerServerEvent("vfw:staff:createItem", name, label, weight, data, a.premium == true, a.perm == true)
        return Ok({ name = name })
    elseif action == "save" then
        local name = a.name or ""
        if not VFW.Items[name] then return Fail("Item introuvable.") end
        local edit = type(a.item) == "table" and a.item or {}
        if not Str(edit.label) then return Fail("Le label est obligatoire.") end
        if tonumber(edit.weight) == nil then return Fail("Le poids est obligatoire.") end
        local payload = { label = edit.label, weight = tonumber(edit.weight), premium = edit.premium == true, perm = edit.perm == true, data = type(edit.data) == "table" and edit.data or {} }
        local before = saveItemVersion
        TriggerServerEvent("vfw:staff:saveItem", name, payload)
        local deadline = GetGameTimer() + 4000
        while saveItemVersion == before and GetGameTimer() < deadline do Wait(50) end
        if saveItemVersion == before then return Ok({ pending = true }) end
        if saveItemResult then return Ok() end
        return Fail("Erreur lors de la sauvegarde.")
    elseif action == "delete" then
        local name = a.name or ""
        if not VFW.Items[name] then return Fail("Item introuvable.") end
        VFW.Items[name] = nil
        TriggerServerEvent("vfw:staff:deleteItem", name)
        return Ok()
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Gestion téléphone (gestion_phone.lua)
-- ═══════════════════════════════════════════════════════════════

OPEN.phone = function()
    if not Has("wipe") then return Fail("Permission wipe requise.") end
    local apps = {}
    for _, app in ipairs(StaffMenu.PhoneApps or {}) do
        local icon = app.label:match("^:([%w%-]+):")
        apps[#apps + 1] = {
            key = app.key,
            label = (app.label:gsub(":[%w%-]+:", "")):gsub("^%s+", ""),
            icon = icon,
            desc = app.desc,
            history = app.key ~= "all" and StaffMenu.PhoneAppsWithHistory and StaffMenu.PhoneAppsWithHistory[app.key] == true or false,
        }
    end
    return Ok({ apps = apps })
end

CALL.phone = function(action, a)
    a = a or {}
    if action == "list" then
        local data = TriggerServerCallback("vfw:staff:phone:listAllNumbers", tonumber(a.page) or 1, Str(a.query)) or { items = {}, total = 0, pageSize = 20 }
        local pageSize = data.pageSize or 20
        return Ok({ items = data.items or {}, total = data.total or 0, page = tonumber(a.page) or 1, pages = math.max(1, math.ceil((data.total or 0) / pageSize)) })
    elseif action == "history" then
        local number, app = Str(a.number), Str(a.app)
        if not number or not app then return Fail("Cible manquante.") end
        local r = TriggerServerCallback("vfw:staff:phone:getHistory", number, app, tonumber(a.page) or 1) or {}
        if not r.supported then return Fail("La consultation n'est pas configurée pour cette app.") end
        local pageSize = r.pageSize or 10
        return Ok({ items = r.items or {}, total = r.total or 0, page = tonumber(a.page) or 1, pages = math.max(1, math.ceil((r.total or 0) / pageSize)) })
    elseif action == "deleteItems" then
        local number, app = Str(a.number), Str(a.app)
        if not number or not app or type(a.ids) ~= "table" or #a.ids == 0 then return Fail("Rien à supprimer.") end
        TriggerServerEvent("vfw:staff:phone:deleteHistoryItems", number, app, a.ids)
        Wait(300)
        return Ok()
    elseif action == "wipe" then
        local number, app = Str(a.number), Str(a.app)
        if not number or not app then return Fail("Cible manquante.") end
        TriggerServerEvent("vfw:staff:phone:wipeApp", number, app)
        Wait(300)
        return Ok()
    elseif action == "certifs" then
        local number = Str(a.number); if not number then return Fail("Cible manquante.") end
        return Ok({ accounts = TriggerServerCallback("vfw:staff:phone:getCertifs", number) or {} })
    elseif action == "setCertif" then
        local number = Str(a.number); if not number then return Fail("Cible manquante.") end
        TriggerServerEvent("vfw:staff:phone:setCertif", number, a.app, a.username, a.verified == true)
        Wait(200)
        return Ok({ accounts = TriggerServerCallback("vfw:staff:phone:getCertifs", number) or {} })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Liste des véhicules (carlist.lua) — preview + spawn
-- ═══════════════════════════════════════════════════════════════

local carPreview = { veh = nil, model = nil, liveryMax = 0, isMod = false, spot = nil }

local function CarDeletePreview()
    if carPreview.veh and DoesEntityExist(carPreview.veh) then
        SetEntityAsMissionEntity(carPreview.veh, true, true)
        DeleteVehicle(carPreview.veh)
    end
    carPreview.veh, carPreview.model = nil, nil
end

local function CarApplyLivery(index)
    local veh = carPreview.veh
    if not veh or not DoesEntityExist(veh) then return end
    if carPreview.isMod then
        SetVehicleModKit(veh, 0)
        SetVehicleMod(veh, 48, index, false)
    else
        SetVehicleLivery(veh, index)
    end
end

local function CarSpot()
    local ped = PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(ped, 2.5, 8.0, 0.0)
    local found, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 5.0, false)
    return { x = pos.x, y = pos.y, z = (found and gz ~= 0.0) and gz or pos.z, h = GetEntityHeading(ped) }
end

OPEN.carlist = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    local cats = {}
    for name, vehs in pairs((VFW.Staff and VFW.Staff.Carlist) or {}) do
        local list = {}
        for _, v in ipairs(vehs) do list[#list + 1] = { model = v.model, label = v.label or v.model } end
        table.sort(list, function(x, y) return string.lower(x.label) < string.lower(y.label) end)
        cats[#cats + 1] = { name = name, count = #list, vehicles = list }
    end
    table.sort(cats, function(x, y) return string.lower(x.name) < string.lower(y.name) end)
    return Ok({ categories = cats })
end

CALL.carlist = function(action, a)
    a = a or {}
    if action == "preview" then
        local model = Str(a.model, 64); if not model then return Fail("Modèle manquant.") end
        local livery = tonumber(a.livery) or 0
        if carPreview.model == model and carPreview.veh and DoesEntityExist(carPreview.veh) then
            CarApplyLivery(math.min(livery, carPreview.liveryMax))
            return Ok({ liveryMax = carPreview.liveryMax })
        end
        CarDeletePreview()
        local hash = GetHashKey(model)
        if not IsModelInCdimage(hash) then return Fail("Modèle introuvable : " .. model) end
        RequestModel(hash)
        local deadline = GetGameTimer() + 5000
        while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(10) end
        if not HasModelLoaded(hash) then return Fail("Chargement du modèle impossible.") end
        local spot = CarSpot()
        local veh = CreateVehicle(hash, spot.x, spot.y, spot.z, spot.h, false, false)
        SetModelAsNoLongerNeeded(hash)
        if not veh or veh == 0 then return Fail("Impossible de créer le véhicule.") end
        SetEntityAsMissionEntity(veh, true, true)
        SetEntityInvincible(veh, true)
        FreezeEntityPosition(veh, true)
        SetEntityCollision(veh, false, false)
        SetEntityAlpha(veh, 160, false)
        SetVehicleEngineOn(veh, false, true, false)
        local lcount = GetVehicleLiveryCount(veh)
        local modCount = GetNumVehicleMods(veh, 48)
        local isMod = lcount <= 0 and modCount > 0
        carPreview.veh, carPreview.model, carPreview.isMod = veh, model, isMod
        carPreview.liveryMax = isMod and (modCount - 1) or ((lcount > 0) and (lcount - 1) or 0)
        if isMod then SetVehicleModKit(veh, 0) end
        CarApplyLivery(math.min(livery, carPreview.liveryMax))
        return Ok({ liveryMax = carPreview.liveryMax })
    elseif action == "spawn" then
        local model = Str(a.model, 64); if not model then return Fail("Modèle manquant.") end
        if not IsModelInCdimage(GetHashKey(model)) then return Fail("Modèle introuvable.") end
        CarDeletePreview()
        TriggerServerEvent("vfw:staff:carlist:spawnVehicle", model, tonumber(a.livery) or 0)
        return Ok()
    elseif action == "stop" then
        CarDeletePreview()
        return Ok()
    end
    return Fail("Action inconnue.")
end

CLOSE.carlist = function() CarDeletePreview() end

-- ═══════════════════════════════════════════════════════════════
-- Animation manager (animManager.lua) — overrides sur RP
-- ═══════════════════════════════════════════════════════════════

local animOverridesCache = nil

local function AnimCategories()
    local list = {}
    for name, group in pairs(RP or {}) do
        if type(group) == "table" then
            local count, modified, disabled = 0, 0, 0
            for key, v in pairs(group) do
                if type(v) == "table" then
                    count = count + 1
                    local ov = animOverridesCache[key]
                    if ov then
                        modified = modified + 1
                        if ov.disabled then disabled = disabled + 1 end
                    end
                end
            end
            list[#list + 1] = { name = name, label = type(group.label) == "string" and group.label or name, icon = type(group.icon) == "string" and group.icon or "", count = count, modified = modified, disabled = disabled }
        end
    end
    table.sort(list, function(x, y) return string.lower(x.label) < string.lower(y.label) end)
    return list
end

OPEN.animmanager = function()
    if not Has("manage_anim") then return Fail("Permission manage_anim requise.") end
    animOverridesCache = TriggerServerCallback("vfw:animManager:getOverrides") or {}
    local total, disabledCount, modifiedCount = 0, 0, 0
    local cats = AnimCategories()
    for _, c in ipairs(cats) do total = total + c.count end
    for _, ov in pairs(animOverridesCache) do
        modifiedCount = modifiedCount + 1
        if ov.disabled then disabledCount = disabledCount + 1 end
    end
    return Ok({ categories = cats, total = total, disabled = disabledCount, modified = modifiedCount })
end

local function AnimEntry(cat, key, v)
    local ov = animOverridesCache[key]
    local original = v[3] or v[2] or key
    return {
        name = key, category = cat, originalLabel = original,
        label = (ov and ov.label) or original,
        disabled = ov and ov.disabled == true or false,
        previewDisabled = ov and ov.previewDisabled == true or false,
        newCategory = ov and ov.category or nil,
        custom = v.custom == true,
        modified = ov ~= nil,
    }
end

CALL.animmanager = function(action, a)
    a = a or {}
    animOverridesCache = animOverridesCache or (TriggerServerCallback("vfw:animManager:getOverrides") or {})
    if action == "list" then
        local group = RP and RP[a.category or ""]
        if type(group) ~= "table" then return Fail("Catégorie inconnue.") end
        local q = Str(a.query); q = q and string.lower(q) or nil
        local list = {}
        for key, v in pairs(group) do
            if type(v) == "table" then
                local e = AnimEntry(a.category, key, v)
                if not q or Contains(e.label, q) or Contains(key, q) then list[#list + 1] = e end
            end
        end
        table.sort(list, function(x, y) return string.lower(x.label) < string.lower(y.label) end)
        return Ok(Paginate(list, a.page, 30))
    elseif action == "override" then
        local name = Str(a.name, 64); if not name then return Fail("Animation manquante.") end
        local ov = type(a.override) == "table" and a.override or nil
        if ov then
            local clean = { disabled = ov.disabled == true or nil, previewDisabled = ov.previewDisabled == true or nil, label = Str(ov.label, 64), category = Str(ov.category, 64) }
            if not next(clean) then clean = nil end
            ov = clean
        end
        animOverridesCache[name] = ov
        TriggerServerEvent("vfw:animManager:setOverride", name, ov)
        return Ok({ override = ov })
    elseif action == "categories" then
        return Ok({ categories = AnimCategories() })
    end
    return Fail("Action inconnue.")
end

RegisterNetEvent("vfw:animManager:overridesUpdated", function(overrides)
    animOverridesCache = overrides or {}
end)

-- ═══════════════════════════════════════════════════════════════
-- Taille du ped
-- ═══════════════════════════════════════════════════════════════

OPEN.pedscale = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    return Ok()
end

CALL.pedscale = function(action, a)
    if type(a) ~= "table" then a = {} end
    if action ~= "apply" then return Fail("Action inconnue.") end

    local target = tonumber(a.id or a.target)
    if not target then return Fail("Identifiant invalide.") end

    local scale = tonumber((tostring(a.scale or a.value or ""):gsub(",", ".")))
    if not scale then return Fail("Valeur invalide.") end

    local packed = { TriggerServerCallback("vfw:staff:applyPedScale", target, scale) }
    local success, applied = packed[1], packed[2]
    if success then
        return Ok({ applied = applied or scale })
    end
    return Fail(type(applied) == "string" and applied ~= "" and applied or "Impossible d'appliquer la taille.")
end

-- ═══════════════════════════════════════════════════════════════
-- Poids des joueurs (weight_management.lua)
-- ═══════════════════════════════════════════════════════════════

OPEN.weight = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    return Ok({ players = TriggerServerCallback("vfw:staff:getModifiedWeights") or {} })
end

CALL.weight = function(action, a)
    a = a or {}
    if action == "list" then
        return Ok({ players = TriggerServerCallback("vfw:staff:getModifiedWeights") or {} })
    elseif action == "characters" then
        local id = tonumber(a.id); if not id then return Fail("Identifiant invalide.") end
        local chars = TriggerServerCallback("vfw:staff:getPlayerCharacters", id)
        if not chars or #chars == 0 then return Fail("Joueur introuvable.") end
        return Ok({ characters = chars })
    elseif action == "set" then
        local id = tonumber(a.id); if not id then return Fail("Identifiant invalide.") end
        local weight = tonumber(a.weight); if not weight or weight <= 0 then return Fail("Poids invalide.") end
        local dur = a.duration
        if dur ~= "session" and dur ~= "days" and dur ~= "permanent" then return Fail("Durée invalide.") end
        local days = dur == "days" and tonumber(a.days) or nil
        if dur == "days" and (not days or days <= 0) then return Fail("Nombre de jours invalide.") end
        TriggerServerEvent("vfw:staff:setPlayerWeight", id, weight, dur, days, a.identifier)
        Wait(300)
        return Ok({ players = TriggerServerCallback("vfw:staff:getModifiedWeights") or {} })
    elseif action == "reset" then
        TriggerServerEvent("vfw:staff:resetPlayerWeight", a.id, a.identifier)
        Wait(300)
        return Ok({ players = TriggerServerCallback("vfw:staff:getModifiedWeights") or {} })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Mappings (mapCoords.lua)
-- ═══════════════════════════════════════════════════════════════

local MAP_TYPES = { legal = "Légal", illegal = "Illégal", other = "Autre" }

local function MapList()
    local maps = TriggerServerCallback("core:getAllMapCoords") or {}
    local list = {}
    for _, m in pairs(maps) do list[#list + 1] = m end
    table.sort(list, function(x, y) return string.lower(x.name or "") < string.lower(y.name or "") end)
    return list
end

OPEN.mappings = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    if not StaffMenu.isInDevMode then return Fail("Activez le mode développeur pour utiliser cet outil.") end
    return Ok({ maps = MapList(), types = MAP_TYPES })
end

CALL.mappings = function(action, a)
    a = a or {}
    if action == "list" then
        return Ok({ maps = MapList() })
    elseif action == "here" then
        local c = GetEntityCoords(PlayerPedId())
        return Ok({ position = { x = c.x, y = c.y, z = c.z } })
    elseif action == "create" or action == "update" then
        local name = Str(a.name, 64); if not name then return Fail("Nom obligatoire.") end
        local t = MAP_TYPES[a.type or ""] and a.type or "legal"
        local pos = type(a.position) == "table" and a.position or nil
        if not pos then
            local c = GetEntityCoords(PlayerPedId())
            pos = { x = c.x, y = c.y, z = c.z }
        end
        if action == "create" then
            TriggerServerEvent("core:createMapCoord", { name = name, type = t, position = pos })
        else
            if not a.id then return Fail("Mapping inconnu.") end
            TriggerServerEvent("core:updateMapCoord", a.id, { id = a.id, name = name, type = t, position = pos })
        end
        Wait(400)
        return Ok({ maps = MapList() })
    elseif action == "delete" then
        if not a.id then return Fail("Mapping inconnu.") end
        TriggerServerEvent("core:deleteMapCoord", a.id)
        Wait(400)
        return Ok({ maps = MapList() })
    elseif action == "tp" then
        local pos = type(a.position) == "table" and a.position or nil
        if not pos then return Fail("Position inconnue.") end
        local ped = PlayerPedId()
        if VFW.ToggleNoclip then VFW.ToggleNoclip() end
        SetEntityCoords(ped, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, false, false, false, false)
        return Ok()
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Staff logs
-- ═══════════════════════════════════════════════════════════════

OPEN.stafflogs = function()
    if not Has("staff_logs") then return Fail("Permission staff_logs requise.") end
    return Ok({ recent = TriggerServerCallback("vfw:stafflogs:getRecent") or {} })
end

CALL.stafflogs = function(action, a)
    a = a or {}
    if action == "recent" then
        return Ok({ recent = TriggerServerCallback("vfw:stafflogs:getRecent") or {} })
    elseif action == "clearRecent" then
        TriggerServerCallback("vfw:stafflogs:clearRecent")
        return Ok({ recent = TriggerServerCallback("vfw:stafflogs:getRecent") or {} })
    elseif action == "queue" then
        local logs, errorInfo = TriggerServerCallback("vfw:stafflogs:getQueue")
        return Ok({ queue = logs or {}, errorInfo = errorInfo })
    elseif action == "clearQueue" then
        TriggerServerCallback("vfw:stafflogs:clearQueue")
        local logs, errorInfo = TriggerServerCallback("vfw:stafflogs:getQueue")
        return Ok({ queue = logs or {}, errorInfo = errorInfo })
    elseif action == "deleteQueue" then
        if a.index == nil then return Fail("Log inconnu.") end
        TriggerServerCallback("vfw:stafflogs:deleteQueue", a.index)
        local logs, errorInfo = TriggerServerCallback("vfw:stafflogs:getQueue")
        return Ok({ queue = logs or {}, errorInfo = errorInfo })
    elseif action == "copy" then
        local t = Str(a.text, 4000); if not t then return Fail("Rien à copier.") end
        VFW.Clipboard(t)
        return Ok()
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Webhooks logs
-- ═══════════════════════════════════════════════════════════════

OPEN.webhooks = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    return Ok({ list = TriggerServerCallback("vfw:webhooks:list") or {} })
end

CALL.webhooks = function(action, a)
    a = a or {}
    if action == "list" then
        return Ok({ list = TriggerServerCallback("vfw:webhooks:list") or {} })
    elseif action == "set" then
        local url = Str(a.url, 512); if not url then return Fail("URL manquante.") end
        local ok, err = TriggerServerCallback("vfw:webhooks:set", a.category, url)
        if not ok then return Fail(err or "Échec de l'enregistrement.") end
        return Ok({ list = TriggerServerCallback("vfw:webhooks:list") or {} })
    elseif action == "test" then
        local ok, err = TriggerServerCallback("vfw:webhooks:test", a.category)
        if not ok then return Fail(err or "Échec du test.") end
        return Ok()
    elseif action == "toggle" then
        local ok = TriggerServerCallback("vfw:webhooks:toggle", a.category, a.enabled == true)
        if not ok then return Fail("Impossible de modifier l'état.") end
        return Ok({ list = TriggerServerCallback("vfw:webhooks:list") or {} })
    elseif action == "remove" then
        local ok = TriggerServerCallback("vfw:webhooks:remove", a.category)
        if not ok then return Fail("Suppression impossible.") end
        return Ok({ list = TriggerServerCallback("vfw:webhooks:list") or {} })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Donner item à tous (give_all_items.lua)
-- ═══════════════════════════════════════════════════════════════

OPEN.giveall = function()
    if not Has("gestion_items") then return Fail("Permission gestion_items requise.") end
    return Ok()
end

CALL.giveall = function(action, a)
    a = a or {}
    if action == "items" then
        local q = Str(a.query); q = q and string.lower(q) or nil
        local list = {}
        for name, item in pairs(VFW.Items or {}) do
            if not q or Contains(name, q) or Contains(item.label, q) then
                list[#list + 1] = { name = name, label = item.label or name, weight = item.weight or 0 }
            end
        end
        table.sort(list, function(x, y) return string.lower(x.label) < string.lower(y.label) end)
        return Ok(Paginate(list, a.page, 30))
    elseif action == "give" then
        local name = Str(a.item, 64); if not name or not VFW.Items[name] then return Fail("Item introuvable.") end
        local qty = math.floor(tonumber(a.quantity) or 0); if qty <= 0 then return Fail("Quantité invalide.") end
        TriggerServerEvent("vfw:staff:giveItemToAll", name, qty)
        print(("^3[Staff] Gave %dx %s to all players^0"):format(qty, name))
        return Ok({ label = VFW.Items[name].label or name, quantity = qty })
    elseif action == "money" then
        local amount = math.floor(tonumber(a.amount) or 0); if amount <= 0 then return Fail("Montant invalide.") end
        TriggerServerEvent("vfw:staff:giveItemToAll", "money", amount)
        return Ok({ amount = amount })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Bypass cooldown
-- ═══════════════════════════════════════════════════════════════

OPEN.cooldown = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    return Ok({ commands = TriggerServerCallback("vfw:cooldown:getCommands") or {}, bypasses = TriggerServerCallback("vfw:cooldown:listBypasses") or {} })
end

CALL.cooldown = function(action, a)
    a = a or {}
    if action == "update" then
        local field = a.field
        if field ~= "cooldown" and field ~= "maxUses" and field ~= "usageCooldown" then return Fail("Champ inconnu.") end
        local val = tonumber(a.value); if not val or val < 0 then return Fail("Valeur invalide.") end
        local r = TriggerServerCallback("vfw:cooldown:updateCommand", a.name, field, math.floor(val))
        if not r or not r.success then return Fail((r and r.message) or "Erreur lors de la sauvegarde.") end
        return Ok({ message = r.message, commands = TriggerServerCallback("vfw:cooldown:getCommands") or {} })
    elseif action == "addBypass" then
        local uid = tonumber(a.uniqueId); if not uid then return Fail("Identifiant invalide.") end
        local r = TriggerServerCallback("vfw:cooldown:addBypass", uid)
        if not r or not r.success then return Fail((r and r.message) or "Erreur") end
        return Ok({ message = r.message, bypasses = TriggerServerCallback("vfw:cooldown:listBypasses") or {} })
    elseif action == "removeBypass" then
        local r = TriggerServerCallback("vfw:cooldown:removeBypass", a.uniqueId)
        if not r or not r.success then return Fail((r and r.message) or "Erreur") end
        return Ok({ message = r.message, bypasses = TriggerServerCallback("vfw:cooldown:listBypasses") or {} })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Antiban
-- ═══════════════════════════════════════════════════════════════

OPEN.antiban = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    return Ok({ list = TriggerServerCallback("vfw:antiban:list") or {} })
end

CALL.antiban = function(action, a)
    a = a or {}
    if action == "add" then
        local uid = tonumber(a.uniqueId); if not uid then return Fail("Identifiant invalide.") end
        local r = TriggerServerCallback("vfw:antiban:add", uid)
        if not r or not r.success then return Fail((r and r.message) or "Erreur") end
        return Ok({ message = r.message, list = TriggerServerCallback("vfw:antiban:list") or {} })
    elseif action == "remove" then
        local r = TriggerServerCallback("vfw:antiban:remove", a.uniqueId)
        if not r or not r.success then return Fail((r and r.message) or "Erreur") end
        return Ok({ message = r.message, list = TriggerServerCallback("vfw:antiban:list") or {} })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Reset sanctions
-- ═══════════════════════════════════════════════════════════════

OPEN.sanctions = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    return Ok()
end

CALL.sanctions = function(action, a)
    a = a or {}
    if action == "search" then
        local q = Str(a.query, 64); if not q then return Fail("Recherche vide.") end
        return Ok({ results = TriggerServerCallback("vfw:staff:searchOfflinePlayers", q) or {} })
    elseif action == "counts" then
        if not a.id then return Fail("Joueur inconnu.") end
        return Ok({ counts = TriggerServerCallback("vfw:staff:getSanctionsCount", a.id) or {} })
    elseif action == "reset" then
        if not a.id then return Fail("Joueur inconnu.") end
        if a.confirm ~= "RESET" then return Fail("Tapez RESET pour confirmer.") end
        local r = TriggerServerCallback("vfw:staff:resetPlayerSanctions", a.id)
        if not r or not r.success then return Fail((r and r.message) or "Échec du reset.") end
        return Ok({ deleted = r.deleted or 0 })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Restauration inventaire
-- ═══════════════════════════════════════════════════════════════

OPEN.invrestore = function()
    if not Has("restore_inventory") then return Fail("Permission restore_inventory requise.") end
    return Ok({ cleans = TriggerServerCallback("vfw:staffinv:listCleans", "pending") or {}, filter = "pending" })
end

CALL.invrestore = function(action, a)
    a = a or {}
    if action == "list" then
        local f = a.filter
        if f == "all" then f = nil end
        return Ok({ cleans = TriggerServerCallback("vfw:staffinv:listCleans", f) or {} })
    elseif action == "detail" then
        if not a.id then return Fail("Snapshot inconnu.") end
        local d = TriggerServerCallback("vfw:staffinv:getCleanDetail", a.id)
        if not d then return Fail("Snapshot introuvable.") end
        return Ok({ detail = d })
    elseif action == "restore" then
        if not a.id then return Fail("Snapshot inconnu.") end
        local r = TriggerServerCallback("vfw:staffinv:restoreClean", a.id)
        if not r or not r.success then return Fail((r and r.message) or "Échec") end
        return Ok({ message = r.message })
    elseif action == "handled" then
        if not a.id then return Fail("Snapshot inconnu.") end
        local r = TriggerServerCallback("vfw:staffinv:markHandled", a.id)
        if not r or not r.success then return Fail((r and r.message) or "Échec") end
        return Ok({ message = r.message })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Véhicule blacklist
-- ═══════════════════════════════════════════════════════════════

OPEN.vehblacklist = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    return Ok({ list = TriggerServerCallback("vfw:staff:vehBlacklist:list") or {} })
end

CALL.vehblacklist = function(action, a)
    a = a or {}
    if action == "add" then
        local model = Str(a.model, 64); if not model then return Fail("Modèle manquant.") end
        local r = TriggerServerCallback("vfw:staff:vehBlacklist:add", string.lower(model), Str(a.reason, 128) or "")
        if not r or not r.success then return Fail((r and r.message) or "Erreur") end
        return Ok({ message = r.message, list = TriggerServerCallback("vfw:staff:vehBlacklist:list") or {} })
    elseif action == "remove" then
        local r = TriggerServerCallback("vfw:staff:vehBlacklist:remove", a.model)
        if not r or not r.success then return Fail((r and r.message) or "Erreur") end
        return Ok({ message = r.message, list = TriggerServerCallback("vfw:staff:vehBlacklist:list") or {} })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Potions
-- ═══════════════════════════════════════════════════════════════

local POTION_GROUPS = {
    { label = "Boost x2", icon = "bolt",   items = { "potion_1", "potion_2", "potion_3" } },
    { label = "Boost x3", icon = "shield", items = { "potion_4", "potion_5", "potion_6" } },
    { label = "Boost x4", icon = "fire",   items = { "potion_7", "potion_8", "potion_9" } },
}

OPEN.potions = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    local groups = {}
    for _, g in ipairs(POTION_GROUPS) do
        local items = {}
        for _, name in ipairs(g.items) do
            local it = VFW.Items and VFW.Items[name]
            items[#items + 1] = { name = name, label = it and it.label or name, known = it ~= nil }
        end
        groups[#groups + 1] = { label = g.label, icon = g.icon, items = items }
    end
    return Ok({ groups = groups, me = GetPlayerServerId(PlayerId()) })
end

CALL.potions = function(action, a)
    a = a or {}
    if action == "give" then
        local target = (a.target == "me" or a.target == "" or a.target == nil) and GetPlayerServerId(PlayerId()) or tonumber(a.target)
        if not target then return Fail("Identifiant invalide.") end
        local qty = math.floor(tonumber(a.amount) or 0); if qty <= 0 then return Fail("Quantité invalide.") end
        local r = TriggerServerCallback("vfw:dev:giveRestrictedItem", { targetId = target, item = a.item, amount = qty })
        if not r or not r.success then return Fail((r and r.message) or "Erreur") end
        return Ok({ message = r.message })
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- Poids des sacs / Plaques GPB — preview sur le ped du staff
-- ═══════════════════════════════════════════════════════════════

local skinBackup = { skin = nil, sex = "m", restored = false }

local function SkinCapture()
    if skinBackup.skin then return end
    TriggerEvent('skinchanger:getSkin', function(skin)
        skinBackup.skin = skin
        skinBackup.sex = skin and skin.sex == 1 and "f" or "m"
    end)
end

local function SkinRestore()
    if skinBackup.skin then
        TriggerEvent('skinchanger:loadSkin', skinBackup.skin)
    end
    skinBackup.skin = nil
    skinBackup.restored = false
end

local function ComponentPreview(component, drawable)
    if not skinBackup.restored and skinBackup.skin then
        TriggerEvent('skinchanger:loadSkin', skinBackup.skin)
        Wait(200)
        skinBackup.restored = true
    end
    SetPedComponentVariation(PlayerPedId(), component, drawable, 0, 2)
end

OPEN.bags = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    SkinCapture()
    local config = TriggerServerCallback("bagweight:getConfig") or {}
    local max = GetNumberOfPedDrawableVariations(PlayerPedId(), 5)
    local list = {}
    for i = 0, max - 1 do
        local w = config[skinBackup.sex .. "_" .. i]
        list[#list + 1] = { id = i, weight = w }
    end
    return Ok({ bags = list, sex = skinBackup.sex, default = 10 })
end

CALL.bags = function(action, a)
    a = a or {}
    if action == "preview" then
        ComponentPreview(5, tonumber(a.id) or 0)
        return Ok()
    elseif action == "set" then
        local id = tonumber(a.id); local w = tonumber(a.weight)
        if not id or not w or w < 0 then return Fail("Valeur invalide.") end
        TriggerServerCallback("bagweight:setWeight", skinBackup.sex, id, w)
        return Ok()
    elseif action == "remove" then
        local id = tonumber(a.id); if not id then return Fail("Sac inconnu.") end
        TriggerServerCallback("bagweight:removeWeight", skinBackup.sex, id)
        return Ok()
    end
    return Fail("Action inconnue.")
end

CLOSE.bags = SkinRestore

OPEN.gpb = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    SkinCapture()
    local config = TriggerServerCallback("gpbplates:getConfig") or {}
    local max = GetNumberOfPedDrawableVariations(PlayerPedId(), 9)
    local list = {}
    for i = 0, max - 1 do
        list[#list + 1] = { id = i, allowed = config[skinBackup.sex .. "_" .. i] ~= false }
    end
    return Ok({ gpb = list, sex = skinBackup.sex })
end

CALL.gpb = function(action, a)
    a = a or {}
    if action == "preview" then
        ComponentPreview(9, tonumber(a.id) or 0)
        return Ok()
    elseif action == "set" then
        local id = tonumber(a.id); if not id then return Fail("GPB inconnu.") end
        TriggerServerCallback("gpbplates:setAllowed", skinBackup.sex, id, a.allowed == true)
        return Ok()
    end
    return Fail("Action inconnue.")
end

CLOSE.gpb = SkinRestore

-- ═══════════════════════════════════════════════════════════════
-- Starter pack
-- ═══════════════════════════════════════════════════════════════

local function StarterConfig()
    local c = TriggerServerCallback("starterpack:getConfig") or {}
    local items = {}
    for _, it in ipairs(c.items or {}) do
        local d = VFW.Items and VFW.Items[it.name]
        items[#items + 1] = { name = it.name, count = it.count, label = d and d.label or it.name }
    end
    return { bank = c.bank or 0, cash = c.cash or 0, items = items }
end

OPEN.starterpack = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    return Ok({ config = StarterConfig() })
end

CALL.starterpack = function(action, a)
    a = a or {}
    if action == "setBank" or action == "setCash" then
        local amount = tonumber(a.amount); if not amount or amount < 0 then return Fail("Montant invalide.") end
        TriggerServerCallback(action == "setBank" and "starterpack:setBank" or "starterpack:setCash", amount)
        return Ok({ config = StarterConfig() })
    elseif action == "addItem" then
        local name = Str(a.name, 64); if not name or not VFW.Items[name] then return Fail("Item introuvable.") end
        local count = math.floor(tonumber(a.count) or 0); if count <= 0 then return Fail("Quantité invalide.") end
        TriggerServerCallback("starterpack:addItem", name, count)
        return Ok({ config = StarterConfig() })
    elseif action == "removeItem" then
        TriggerServerCallback("starterpack:removeItem", a.name)
        return Ok({ config = StarterConfig() })
    elseif action == "items" then
        local q = Str(a.query); q = q and string.lower(q) or nil
        local list = {}
        for name, item in pairs(VFW.Items or {}) do
            if not q or Contains(name, q) or Contains(item.label, q) then
                list[#list + 1] = { name = name, label = item.label or name }
            end
        end
        table.sort(list, function(x, y) return string.lower(x.label) < string.lower(y.label) end)
        return Ok(Paginate(list, 1, 30))
    end
    return Fail("Action inconnue.")
end

-- ═══════════════════════════════════════════════════════════════
-- État des toggles dev (mode dev, print props, poids)
-- ═══════════════════════════════════════════════════════════════

OPEN.devstate = function()
    if not Has("dev") then return Fail("Permission développeur requise.") end
    return Ok({ devMode = StaffMenu.isInDevMode == true, printProps = StaffMenu.PrintPropsAndEntities == true, devWeight = StaffMenu.hasDevWeight == true })
end

CALL.devstate = function(action, a)
    a = a or {}
    if action == "devMode" then
        StaffMenu.isInDevMode = a.value == true
    elseif action == "printProps" then
        StaffMenu.PrintPropsAndEntities = a.value == true
    elseif action == "devWeight" then
        StaffMenu.hasDevWeight = a.value == true
        TriggerServerEvent("vfw:staff:toggleDevWeight", StaffMenu.hasDevWeight)
    else
        return Fail("Action inconnue.")
    end
    return Ok({ devMode = StaffMenu.isInDevMode == true, printProps = StaffMenu.PrintPropsAndEntities == true, devWeight = StaffMenu.hasDevWeight == true })
end

-- ═══════════════════════════════════════════════════════════════
-- Callbacks NUI génériques
-- ═══════════════════════════════════════════════════════════════

-- Citizen.Await (TriggerServerCallback) doit tourner dans un thread scheduler,
-- sans pcall autour : pcall interdit le yield et renvoyait "Erreur interne".
local function runDevNui(label, cb, fn, ...)
    local n = select("#", ...)
    local args = { ... }
    CreateThread(function()
        local res = fn(table.unpack(args, 1, n))
        if type(res) ~= "table" then
            console.error("[GestionDev] " .. label .. " : réponse invalide")
            cb(Fail("Réponse invalide."))
            return
        end
        cb(res)
    end)
end

RegisterNuiCallback("gestion:dev:open", function(data, cb)
    local tool = type(data) == "table" and data.tool or nil
    local fn = tool and OPEN[tool]
    if not fn then cb(Fail("Outil inconnu : " .. tostring(tool))) return end
    runDevNui("open " .. tostring(tool), cb, fn)
end)

RegisterNuiCallback("gestion:dev:call", function(data, cb)
    local payload = type(data) == "table" and data or {}
    if payload.tool == nil and type(payload.data) == "table" then payload = payload.data end
    local tool = payload.tool
    local fn = tool and CALL[tool]
    if not fn then cb(Fail("Outil inconnu : " .. tostring(tool))) return end
    runDevNui(("%s.%s"):format(tostring(tool), tostring(payload.action)), cb, fn, payload.action, payload.args)
end)

RegisterNuiCallback("gestion:dev:close", function(data, cb)
    local tool = type(data) == "table" and data.tool or nil
    local fn = tool and CLOSE[tool]
    if fn then pcall(fn) end
    cb({ ok = true })
end)

-- Nettoyage global si le hub se ferme pendant qu'un outil est actif
AddEventHandler("gestion:hub:closed", function()
    for _, fn in pairs(CLOSE) do pcall(fn) end
end)
