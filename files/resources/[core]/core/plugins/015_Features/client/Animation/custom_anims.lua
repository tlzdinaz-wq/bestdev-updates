---@meta _
---@diagnostic disable: duplicate-doc-field

-- ═══════════════════════════════════════════════════════════════
-- Animations personnalisées
-- Créées depuis Gestion > Développeurs > "Ajouter une animation" (hub NUI),
-- stockées côté serveur (variable `anim_custom`) et injectées dans `RP`
-- au chargement : elles apparaissent dans le menu emotes (K), la commande /e
-- et l'Animation manager comme n'importe quelle animation de base.
-- ═══════════════════════════════════════════════════════════════

local customAnims = {}
local applied = {}      -- clé -> catégorie où l'entrée a été injectée dans RP
local customVersion = 0
local loaded = false

--- Convertit une définition sauvegardée en entrée RP (format rpemotes).
---@param def table
---@return table
local function BuildEntry(def)
    if def.kind == "walk" or def.kind == "expression" then
        return { def.dict, def.label }
    end

    local entry = { def.kind == "scenario" and "Scenario" or def.dict, def.anim, def.label }

    local o = def.options
    if o and def.kind ~= "scenario" then
        local opts = {}
        if o.loop then opts.EmoteLoop = true end
        if o.moving then opts.EmoteMoving = true end
        if o.stuck then opts.EmoteStuck = true end
        if o.fullBody then opts.FullBody = true end
        if o.duration and o.duration > 0 then opts.EmoteDuration = o.duration end
        if o.prop and o.prop ~= "" then
            opts.Prop = o.prop
            opts.PropBone = o.propBone or 57005
            opts.PropPlacement = o.propPlacement or { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
        end
        if next(opts) then entry.AnimationOptions = opts end
    end

    return entry
end

--- Remplace les animations personnalisées injectées dans RP par `data`.
---@param data table|nil clé -> définition
function VFW.ApplyCustomAnims(data)
    for key, cat in pairs(applied) do
        if RP[cat] then RP[cat][key] = nil end
    end
    applied = {}
    customAnims = type(data) == "table" and data or {}

    for key, def in pairs(customAnims) do
        if type(def) == "table" and type(def.category) == "string" and RP[def.category] then
            local entry = BuildEntry(def)
            entry.custom = true
            RP[def.category][key] = entry
            applied[key] = def.category
        end
    end

    customVersion = customVersion + 1
    loaded = true

    if StaffMenu and StaffMenu.ResetAnimManagerCache then
        StaffMenu.ResetAnimManagerCache()
    end
end

function VFW.GetCustomAnims()
    return customAnims
end

RegisterNetEvent("vfw:animManager:customUpdated", function(data)
    VFW.ApplyCustomAnims(data)
end)

local function LoadCustomAnims()
    local data = TriggerServerCallback("vfw:animManager:getCustom") or {}
    VFW.ApplyCustomAnims(data)
end

AddEventHandler("vfw:onPlayerLoaded", function()
    CreateThread(LoadCustomAnims)
end)

-- Restart de la ressource en jeu : le joueur est déjà chargé
CreateThread(function()
    Wait(3000)
    if VFW.PlayerLoaded and not loaded then
        LoadCustomAnims()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- Hub de gestion (NUI) : ouverture / test / sauvegarde / suppression
-- ═══════════════════════════════════════════════════════════════

local function HasAnimPerm()
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["manage_anim"] or perms["dev"] or perms["gestion"] or false
end

--- Type d'animation d'une catégorie RP ("emote" | "walk" | "expression").
---@param group table
---@return string
local function CategoryKind(group)
    local t = type(group.type) == "string" and group.type or "emote"
    if t == "walk" then return "walk" end
    if t == "expresion" or t == "expression" then return "expression" end
    return "emote"
end

local function ListCategories()
    local list = {}
    for name, group in pairs(RP) do
        if type(group) == "table" then
            list[#list + 1] = {
                name = name,
                label = type(group.label) == "string" and group.label or name,
                icon = type(group.icon) == "string" and group.icon or "",
                kind = CategoryKind(group),
            }
        end
    end
    table.sort(list, function(a, b) return string.lower(a.label) < string.lower(b.label) end)
    return list
end

local function ListCustoms()
    local list = {}
    for key, def in pairs(customAnims) do
        if type(def) == "table" then
            local copy = {}
            for k, v in pairs(def) do copy[k] = v end
            copy.key = key
            list[#list + 1] = copy
        end
    end
    table.sort(list, function(a, b) return string.lower(a.label or a.key) < string.lower(b.label or b.key) end)
    return list
end

local testWalkActive = false
local testExpressionActive = false

local function StopTest()
    local ped = PlayerPedId()
    if EmoteCancel then pcall(EmoteCancel) else ClearPedTasks(ped) end
    if testWalkActive then
        local saved = GetResourceKvpString("walkstyle")
        if saved and saved ~= "" then
            RequestWalking(saved)
            SetPedMovementClipset(ped, saved, 0.2)
        else
            ResetPedMovementClipset(ped, 0.0)
        end
        testWalkActive = false
    end
    if testExpressionActive then
        local saved = GetResourceKvpString("expression")
        if saved and saved ~= "" then
            SetFacialIdleAnimOverride(ped, saved, 0)
        else
            ClearFacialIdleAnimOverride(ped)
        end
        testExpressionActive = false
    end
end

--- Joue la définition sur le joueur (sans la sauvegarder).
---@param def table
---@return boolean ok, string|nil err
local function PlayTest(def)
    local ped = PlayerPedId()
    if def.kind == "walk" then
        if not def.dict or def.dict == "" then return false, "Clipset manquant." end
        StopTest()
        RequestWalking(def.dict)
        SetPedMovementClipset(ped, def.dict, 0.2)
        testWalkActive = true
        return true
    elseif def.kind == "expression" then
        if not def.dict or def.dict == "" then return false, "Expression manquante." end
        StopTest()
        SetFacialIdleAnimOverride(ped, def.dict, 0)
        testExpressionActive = true
        return true
    end

    local entry = BuildEntry(def)
    if not entry[1] or entry[1] == "" or not entry[2] or entry[2] == "" then
        return false, def.kind == "scenario" and "Nom du scénario manquant." or "Dictionnaire et animation obligatoires."
    end
    if entry[1] ~= "Scenario" then
        RequestAnimDict(entry[1])
        local deadline = GetGameTimer() + 3000
        while not HasAnimDictLoaded(entry[1]) and GetGameTimer() < deadline do Wait(50) end
        if not HasAnimDictLoaded(entry[1]) then
            return false, ("Dictionnaire introuvable : %s"):format(entry[1])
        end
    end
    StopTest()
    PlayAnimation(ped, entry)
    return true
end

RegisterNuiCallback("gestion:anims:open", function(_, cb)
    if not HasAnimPerm() then
        cb({ ok = false, error = "Permission manquante (manage_anim)." })
        return
    end
    if not loaded then LoadCustomAnims() end
    cb({ ok = true, categories = ListCategories(), customs = ListCustoms() })
end)

RegisterNuiCallback("gestion:anims:test", function(data, cb)
    if not HasAnimPerm() or type(data) ~= "table" then
        cb({ ok = false, error = "Permission manquante." })
        return
    end
    local ok, err = PlayTest(data)
    cb({ ok = ok, error = err })
end)

RegisterNuiCallback("gestion:anims:stop", function(_, cb)
    StopTest()
    cb({ ok = true })
end)

--- Attend la diffusion serveur (customUpdated) pour renvoyer la liste à jour.
local function WaitForVersion(before)
    local deadline = GetGameTimer() + 3000
    while customVersion == before and GetGameTimer() < deadline do Wait(50) end
    return customVersion ~= before
end

RegisterNuiCallback("gestion:anims:save", function(data, cb)
    if not HasAnimPerm() or type(data) ~= "table" then
        cb({ ok = false, error = "Permission manquante." })
        return
    end
    local before = customVersion
    TriggerServerEvent("vfw:animManager:setCustom", data)
    if not WaitForVersion(before) then
        -- Refusé par le serveur (la notification rouge donne la raison)
        cb({ ok = false, error = "Enregistrement refusé : vérifiez les champs.", customs = ListCustoms() })
        return
    end
    cb({ ok = true, customs = ListCustoms() })
end)

RegisterNuiCallback("gestion:anims:delete", function(data, cb)
    if not HasAnimPerm() or type(data) ~= "table" or type(data.key) ~= "string" then
        cb({ ok = false, error = "Permission manquante." })
        return
    end
    local before = customVersion
    TriggerServerEvent("vfw:animManager:deleteCustom", data.key)
    if not WaitForVersion(before) then
        cb({ ok = false, error = "Suppression impossible.", customs = ListCustoms() })
        return
    end
    cb({ ok = true, customs = ListCustoms() })
end)
