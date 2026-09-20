---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Staff Menu - Liste des Véhicules (Carlist)
-- UX :
--   Hover ↑↓ (items véhicules)  → preview live du véhicule
--   Flèches :back::arrow: sur un item      → changer livery en direct
--   Entrée sur un item          → spawner devant soi
-- ============================================================

local VEH_FORWARD = 8.0
local VEH_RIGHT   = 2.5

-- File de demandes de preview : le worker thread lit previewRequest en boucle.
-- On écrit dans previewRequest pour déclencher une preview, jamais de CreateThread
-- supplémentaire depuis OnIndexChange.
local previewRequest = nil   -- { model=..., livery=... } ou false (→ delete)

local previewVeh    = nil
local previewActive = false
local previewModel  = nil
local previewLivery = 0
local previewLivMax = 0

-- Position de spawn du véhicule preview (calculée à l'ouverture)
local previewSpawnX = 0.0
local previewSpawnY = 0.0
local previewSpawnZ = 0.0
local previewSpawnH = 0.0

local liveryMaxCache    = {}
local liveryByModel     = {}
local liveryIsModCache  = {}   -- true = mod-based (slot 48), false = native

local function ApplyLivery(veh, model, index)
    if liveryIsModCache[model] then
        SetVehicleModKit(veh, 0)
        SetVehicleMod(veh, 48, index, false)
    else
        SetVehicleLivery(veh, index)
    end
end

local currentCatName  = nil
local currentVehicles = nil

-- Sep(1) + List2_i(1+i)
local VEH_OFFSET = 1

-- ============================================================
-- Pousse les options de livery à jour dans le NUI pour un modèle donné.
-- Utilisé pour rafraîchir le List2 quand le cache vient d'être rempli
-- ou quand l'utilisateur survole un véhicule déjà connu.
-- ============================================================
local function PushLiveryOptionsToNUI(model)
    if not currentVehicles or not StaffMenu.carlistCat.opened then return end
    local lmax = liveryMaxCache[model]
    if not lmax then return end

    for i, vd in ipairs(currentVehicles) do
        if vd.model == model then
            local nuiIndex = VEH_OFFSET + i
            local menuItem = StaffMenu.carlistCat.items[nuiIndex]
            if menuItem then
                local newOptions = {}
                for j = 0, lmax do newOptions[#newOptions + 1] = ("Livery %d"):format(j) end
                menuItem.props.items = newOptions
                menuItem.props.index = math.min(liveryByModel[model] or 0, lmax)
                SendNUIMessage({
                    action = "vui:menu:update",
                    data   = { index = nuiIndex - 1, item = { type = "list2", props = menuItem.props } }
                })
            end
            return
        end
    end
end

-- ============================================================
-- Calcule la position de spawn du véhicule preview
-- ============================================================

local function ComputePreviewSpot()
    local ped = PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(ped, VEH_RIGHT, VEH_FORWARD, 0.0)
    local found, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 5.0, false)
    previewSpawnX = pos.x
    previewSpawnY = pos.y
    previewSpawnZ = (found and gz ~= 0.0) and gz or pos.z
    previewSpawnH = GetEntityHeading(ped)
end

-- ============================================================
-- Cleanup preview
-- ============================================================

local function DeletePreview()
    previewActive = false
    previewModel  = nil
    previewLivery = 0
    previewLivMax = 0

    if previewVeh and DoesEntityExist(previewVeh) then
        SetEntityAsMissionEntity(previewVeh, true, true)
        DeleteVehicle(previewVeh)
    end
    previewVeh = nil
end

-- ============================================================
-- Worker thread unique : traite les demandes de preview
-- ============================================================
-- previewRequest = nil          → rien à faire
-- previewRequest = false        → supprimer la preview
-- previewRequest = { model, livery } → charger ce modèle

local function DoSpawnPreview(model, wantedLivery, req)
    wantedLivery = wantedLivery or 0

    -- Même modèle déjà affiché → juste mettre à jour la livery
    if previewModel == model and previewVeh and DoesEntityExist(previewVeh) then
        local clamped = math.min(wantedLivery, previewLivMax)
        previewLivery = clamped
        ApplyLivery(previewVeh, model, clamped)
        -- Re-pousser les options au cas où la première mise à jour aurait été
        -- ignorée par le NUI (timing à l'ouverture du menu)
        PushLiveryOptionsToNUI(model)
        previewRequest = nil
        return
    end

    -- Nettoyer l'ancien preview
    DeletePreview()

    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        previewRequest = nil
        return
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
        if previewRequest ~= req then
            SetModelAsNoLongerNeeded(hash)
            return  -- nouvelle demande → on laisse le worker reprendre
        end
    end

    if previewRequest ~= req then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    local veh = CreateVehicle(hash, previewSpawnX, previewSpawnY, previewSpawnZ, previewSpawnH, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not veh or veh == 0 or previewRequest ~= req then
        if veh and veh ~= 0 then
            SetEntityAsMissionEntity(veh, true, true)
            DeleteVehicle(veh)
        end
        previewRequest = nil
        return
    end

    SetEntityAsMissionEntity(veh, true, true)
    SetEntityVisible(veh, true, false)
    SetEntityInvincible(veh, true)
    FreezeEntityPosition(veh, true)
    SetEntityCollision(veh, false, false)
    SetEntityCompletelyDisableCollision(veh, false, false)
    SetEntityAlpha(veh, 120, false)
    SetVehicleEngineOn(veh, false, true, false)
    SetVehicleLights(veh, 0)

    local lcount    = GetVehicleLiveryCount(veh)
    local modCount  = GetNumVehicleMods(veh, 48)
    local isMod     = lcount <= 0 and modCount > 0
    local lmax      = isMod and (modCount - 1) or ((lcount > 0) and (lcount - 1) or 0)

    liveryMaxCache[model]   = lmax
    liveryIsModCache[model] = isMod

    if isMod then SetVehicleModKit(veh, 0) end

    local clamped = math.min(wantedLivery, lmax)
    previewLivery = clamped
    previewLivMax = lmax
    ApplyLivery(veh, model, clamped)

    -- Mettre à jour la List2 dans le NUI
    PushLiveryOptionsToNUI(model)

    previewVeh    = veh
    previewModel  = model
    previewActive = true
    previewRequest = nil
end

CreateThread(function()
    while true do
        if previewActive and previewVeh and DoesEntityExist(previewVeh) then
            Wait(0)
            VFW.ShowHelpNotification("~INPUT_FRONTEND_ACCEPT~ Spawn   ~INPUT_FRONTEND_LEFT~ ~INPUT_FRONTEND_RIGHT~ Livery   ~INPUT_CELLPHONE_CANCEL~ Retour")
        else
            Wait(50)
        end

        if previewRequest == false then
            previewRequest = nil
            DeletePreview()
        elseif previewRequest and type(previewRequest) == "table" then
            local req = previewRequest
            DoSpawnPreview(req.model, req.livery, req)
        end
    end
end)

-- ============================================================
-- SpawnVehicle
-- ============================================================

local function SpawnVehicle(model, livery)
    DeletePreview()

    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        VFW.ShowNotification({ type='STAFF', variant='ERROR', subtitle='Carlist', message="Modèle introuvable." })
        return
    end

    TriggerServerEvent("vfw:staff:carlist:spawnVehicle", model, livery)

    -- Recalculer le spot et relancer la preview si le menu est toujours ouvert
    if StaffMenu.carlistCat.opened then
        ComputePreviewSpot()
        previewRequest = { model = model, livery = livery }
    end
end

-- ============================================================
-- Build menu catégorie
-- ============================================================

local function BuildCategoryMenu()
    if not currentVehicles then return end
    StaffMenu.carlistCat.ClearItems()

    StaffMenu.carlistCat.Separator(
        ("%s : %d véhicules  |  :back::arrow: livery  |  Entrée = spawn"):format(
            currentCatName or "Catégorie", #currentVehicles))

    for _, vd in ipairs(currentVehicles) do
        local lbl         = vd.label or vd.model
        local mdl         = vd.model
        local lmax        = liveryMaxCache[mdl] or 0
        local options     = {}
        for i = 0, lmax do options[#options + 1] = ("Livery %d"):format(i) end
        local savedLivery = liveryByModel[mdl] or 0
        local capturedMdl = mdl

        StaffMenu.carlistCat.List2(
            lbl,
            "Modèle : " .. capturedMdl,
            false,
            options,
            savedLivery + 1,
            -- onArrow : flèche :back::arrow: → update livery preview
            function(idx)
                local liv = idx - 1
                liveryByModel[capturedMdl] = liv
                if previewModel == capturedMdl and previewVeh and DoesEntityExist(previewVeh) then
                    local clamped = math.min(liv, previewLivMax)
                    previewLivery = clamped
                    ApplyLivery(previewVeh, capturedMdl, clamped)
                end
            end,
            -- onEnter : Entrée → spawn
            function()
                SpawnVehicle(capturedMdl, liveryByModel[capturedMdl] or 0)
            end
        )
    end
end

-- ============================================================
-- OnIndexChange : hover ↑↓ → preview du véhicule survolé
-- ============================================================

StaffMenu.carlistCat.OnIndexChange(function(index)
    if not currentVehicles then return end

    local vehIndex = index - VEH_OFFSET
    if vehIndex < 1 or vehIndex > #currentVehicles then return end

    local mdl    = currentVehicles[vehIndex].model
    local livery = liveryByModel[mdl] or 0

    -- Si on a déjà spawné ce modèle, on connaît son nombre de livery :
    -- on rafraîchit la liste des options du List2 sous le curseur.
    -- Le handler NUI applique l'update à l'item courant, donc cet appel
    -- garantit que le dropdown affiche les bonnes options dès que
    -- l'utilisateur survole un véhicule connu.
    PushLiveryOptionsToNUI(mdl)

    previewRequest = { model = mdl, livery = livery }
end)

-- ============================================================
-- Build menu principal (catégories)
-- ============================================================

local function BuildCarlistMain()
    StaffMenu.carlistMain.ClearItems()

    local cat = VFW.Staff and VFW.Staff.Carlist
    if not cat or not next(cat) then
        StaffMenu.carlistMain.Separator("Aucun véhicule configuré")
        return
    end

    local total, nc = 0, 0
    for _, v in pairs(cat) do total = total + #v; nc = nc + 1 end
    StaffMenu.carlistMain.Separator((":car: %d catégories, %d véhicules"):format(nc, total))

    for name, vehs in pairs(cat) do
        StaffMenu.carlistMain.Button(
            name .. (" [%d]"):format(#vehs),
            ("Voir les %d véhicules"):format(#vehs),
            nil, "chevron", false,
            function()
                currentCatName  = name
                currentVehicles = vehs
                BuildCategoryMenu()
                ComputePreviewSpot()
                if #vehs > 0 then
                    previewRequest = { model = vehs[1].model, livery = liveryByModel[vehs[1].model] or 0 }
                end
            end,
            StaffMenu.carlistCat
        )
    end
end

StaffMenu.carlistMain.OnOpen(function()
    BuildCarlistMain()
end)

StaffMenu.carlistCat.OnOpen(function()
    -- Preview déjà lancée depuis le callback du bouton parent
end)

StaffMenu.carlistMain.OnClose(function()
    if type(previewRequest) ~= "table" then
        previewRequest = false
        currentCatName  = nil
        currentVehicles = nil
    end
end)

StaffMenu.carlistCat.OnClose(function()
    -- Ne cleanup que si on revient au menu principal (pas si on ré-ouvre une autre catégorie)
    -- Le button callback post une nouvelle request AVANT que OnClose fire,
    -- donc si previewRequest est déjà une table, on ne l'écrase pas.
    if type(previewRequest) ~= "table" then
        previewRequest = false
    end
end)
