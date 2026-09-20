---@meta _
---@diagnostic disable: duplicate-doc-field

--[[
    ========================================
    PED CONTEXT MENU - FICHIER PRINCIPAL
    ========================================

    Contenu:
    - Actions sur soi-même (Self)
    - Actions sur les autres joueurs (Others)
    - Actions Staff sur NPC
    - Actions Staff sur joueurs

    Ordre d'affichage du menu:
    1. Actions Staff (sur soi / NPC / autres joueurs)
    2. Actions Faction
    3. Interactions (autres joueurs)
    4. Documents (soi-même)
    5. Animations (soi-même)
    6. Options (soi-même)
    7. Debug (soi-même)
    8. Boutons racine
]]

local hideHUD = false

local GOUV_IMG = VFW.CDN.Get("entreprise/gouvernement.png")
local function gouvNotif(subtitle, content)
    VFW.ShowNotification({ type = "JOB", title = "Gouvernement", subtitle = subtitle, image = GOUV_IMG, content = content })
end

-- Cache local pour les licences DVM (éviter les appels répétés au serveur)
local dvmLicensesCache = nil
local dvmLicensesCacheTime = 0
local DVM_CACHE_DURATION = 30000 -- 30 secondes

-- Mapping des types de documents vers les types DVM
local dvmTypeMapping = {
    driver = "car",
    motorbike = "motorcycle",
    truck = "truck"
}

--region ====== GLOBAL FUNCTIONS ======

function HasContextMenuPermission()
    return VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["contextmenu"]
end

function HasLisenseContext(licenseType)
    if licenseType == "job" then
        return VFW.PlayerData and VFW.PlayerData.job
    end

    if licenseType == "identity" then
        return true
    end

    -- Pour les PPA, vérifier la licence correspondante
    if licenseType == "weapon_leger" then
        local playerData = VFW.PlayerData
        return playerData and playerData.licenses and playerData.licenses["ppa_leger"]
    end

    if licenseType == "weapon_lourd" then
        local playerData = VFW.PlayerData
        return playerData and playerData.licenses and playerData.licenses["ppa_lourd"]
    end

    -- Vérifier d'abord les licences legacy
    local playerData = VFW.PlayerData
    if playerData and playerData.licenses and playerData.licenses[licenseType] then
        return true
    end

    -- Pour le permis de conduire, vérifier si le joueur a au moins un permis DVM
    if licenseType == "driver" then
        -- Rafraîchir le cache si nécessaire
        local currentTime = GetGameTimer()
        if not dvmLicensesCache or (currentTime - dvmLicensesCacheTime) > DVM_CACHE_DURATION then
            dvmLicensesCache = TriggerServerCallback("dvm:getPlayerLicensesForDocument") or {}
            dvmLicensesCacheTime = currentTime
        end

        -- Retourner true si le joueur a au moins un permis DVM (car, motorcycle, ou truck)
        return dvmLicensesCache and #dvmLicensesCache > 0
    end

    return false
end

--endregion

--region ====== DEATH STATE HELPER ======

--- Detecte si un ped joueur est mort (joue l'animation de mort)
--- Retourne le serverId du joueur si mort, nil sinon
function VFW.GetDeathCloneOwner(ped)
    if not DoesEntityExist(ped) or not IsPedAPlayer(ped) then return nil end

    local isDeathAnim = IsEntityPlayingAnim(ped, "dead", "dead_a", 3)
        or IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3)

    if isDeathAnim then
        local playerIndex = NetworkGetPlayerIndexFromPed(ped)
        if playerIndex >= 0 then
            return GetPlayerServerId(playerIndex)
        end
    end
    return nil
end

--endregion

--region ====== HELPER FUNCTIONS ======

local function isSamePlayer(ped)
    local isPlayer <const> = NetworkGetPlayerIndexFromPed(ped)
    local playerId <const> = GetPlayerServerId(isPlayer)
    local playerSource = GetPlayerServerId(PlayerId())
    return playerId == playerSource
end

local function IsOtherPlayer(ped)
    if not DoesEntityExist(ped) or not IsPedAPlayer(ped) then
        return false
    end
    if ped == PlayerPedId() then
        return false
    end
    -- Double check avec server ID
    local isPlayer = NetworkGetPlayerIndexFromPed(ped)
    if isPlayer then
        local targetServerId = GetPlayerServerId(isPlayer)
        local myServerId = GetPlayerServerId(PlayerId())
        if targetServerId == myServerId then
            return false
        end
    end
    return true
end

local function IsNPC(ped)
    return DoesEntityExist(ped) and not IsPedAPlayer(ped)
end

local function GetPlayerServerIdFromPed(ped)
    local playerId = NetworkGetPlayerIndexFromPed(ped)
    if playerId and playerId ~= -1 then
        return GetPlayerServerId(playerId)
    end
    return nil
end

local function formatNumber(num)
    return tonumber(string.format("%.2f", num))
end

local function HasStaffPermission(permission)
    return VFW.HasStaffPerm and VFW.HasStaffPerm(permission) or false
end

-- Fonctions TOUJOURS visibles (même quand mort) - pour "Voir mon ID" et "Copier l'ID"
local function canShowButton(ped)
    return IsPedAPlayer(ped) and isSamePlayer(ped) and HasContextMenuPermission()
end

-- Visible par TOUS les joueurs (même quand mort, sans permission)
local function canShowSelfButton(ped)
    return IsPedAPlayer(ped) and isSamePlayer(ped)
end

local function canInteractWithOtherPlayer(ped)
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    return IsOtherPlayer(ped)
end

-- Fonction pour copier l'ID (visible même quand mort)
local function canCopyOtherPlayerId(ped)
    return IsOtherPlayer(ped)
end

-- Fonction pour staff sur autres joueurs (visible même quand le staff est mort)
local function canStaffInteractWithOtherPlayer(ped)
    return IsOtherPlayer(ped)
end

-- Fonctions visibles UNIQUEMENT quand vivant - pour toutes les autres options
local function canShowButtonWhenAlive(ped)
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    return IsPedAPlayer(ped) and isSamePlayer(ped) and HasContextMenuPermission()
end

-- Visible par TOUS les joueurs (vivant + son propre perso, sans permission)
local function canShowSelfButtonWhenAlive(ped)
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    return IsPedAPlayer(ped) and isSamePlayer(ped)
end

local function canInteractWithOtherPlayerWhenAlive(ped)
    if not IsOtherPlayer(ped) then
        return false
    end
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    -- Pas d'interaction standard si la cible est dans le coma
    if IsPedDeadOrDying(ped, true) or VFW.GetDeathCloneOwner(ped) then
        return false
    end
    return true
end

-- Fonction staff (toujours visible car staff peut agir même mort)
local function canShowButtonAdmin(ped)
    return IsPedAPlayer(ped) and isSamePlayer(ped) and HasStaffPermission("contextmenu") and VFW.IsInStaffMode()
end

local lastStaffTeleportPos = nil

local function hasJob2()
    return VFW.PlayerData
            and VFW.PlayerData.faction
            and VFW.PlayerData.faction.name
            and VFW.PlayerData.faction.name ~= ""
           and VFW.PlayerData.faction.name ~= "nofaction"
           and VFW.PlayerData.faction.name ~= "nocrew"
end

local function isPlayerInGovernment()
    return VFW.PlayerData
            and VFW.PlayerData.job
            and VFW.PlayerData.job.name
            and VFW.PlayerData.job.name == "gouvernement"
end

local function isPlayerInCayoGouv()
    return VFW.PlayerData
            and VFW.PlayerData.job
            and VFW.PlayerData.job.name
            and VFW.PlayerData.job.name == "gouvernement_cayo"
end

local cayoVisaTargetCache = {}
local CAYO_VISA_CACHE_DURATION = 10000

local function getCayoVisaStatus(targetServerId)
    if not targetServerId then return nil end
    local now = GetGameTimer()
    local cached = cayoVisaTargetCache[targetServerId]
    if cached and (now - cached.time) < CAYO_VISA_CACHE_DURATION then
        return cached.hasVisa
    end
    local response = TriggerServerCallback("cayo_visa:checkTarget", { targetServerId = targetServerId })
    local hasVisa = response and response.hasVisa or false
    cayoVisaTargetCache[targetServerId] = { hasVisa = hasVisa, time = now }
    return hasVisa
end

local function invalidateCayoVisaCache(targetServerId)
    if targetServerId then
        cayoVisaTargetCache[targetServerId] = nil
    end
end

-- Cache permission security_actions (éviter les appels serveur répétés)
local gouvSecurityPermCache = nil
local gouvSecurityPermCacheTime = 0
local GOUV_PERM_CACHE_DURATION = 10000 -- 10 secondes

local function hasGouvSecurityPerm()
    if not isPlayerInGovernment() then
        gouvSecurityPermCache = nil
        return false
    end
    local currentTime = GetGameTimer()
    if gouvSecurityPermCache == nil or (currentTime - gouvSecurityPermCacheTime) > GOUV_PERM_CACHE_DURATION then
        gouvSecurityPermCache = TriggerServerCallback("gouvernement:checkPerm", "security_actions") or false
        gouvSecurityPermCacheTime = currentTime
    end
    return gouvSecurityPermCache
end

-- Cache permissions factures gouvernement
local gouvInvoicePermCache = nil
local gouvInvoiceCompanyPermCache = nil
local gouvInvoicePermCacheTime = 0

local function hasGouvInvoicePerm()
    if not isPlayerInGovernment() then
        gouvInvoicePermCache = nil
        gouvInvoiceCompanyPermCache = nil
        return false, false
    end
    local currentTime = GetGameTimer()
    if gouvInvoicePermCache == nil or (currentTime - gouvInvoicePermCacheTime) > GOUV_PERM_CACHE_DURATION then
        gouvInvoicePermCache = TriggerServerCallback("gouvernement:checkPerm", "create_invoice") or false
        gouvInvoiceCompanyPermCache = TriggerServerCallback("gouvernement:checkPerm", "create_invoice_company") or false
        gouvInvoicePermCacheTime = currentTime
    end
    return gouvInvoicePermCache, gouvInvoiceCompanyPermCache
end

-- Invalidate all gouvernement permission caches on job/duty change
RegisterNetEvent("vfw:setJob", function()
    gouvSecurityPermCache = nil
    gouvSecurityPermCacheTime = 0
    gouvInvoicePermCache = nil
    gouvInvoiceCompanyPermCache = nil
    gouvInvoicePermCacheTime = 0
end)

local function isTargetInGovernment(ped)
    if not canInteractWithOtherPlayerWhenAlive(ped) then
        return false
    end
    return isPlayerInGovernment()
end

local function isInFaction(ped)
    if not IsPedAPlayer(ped) then
        return false
    end
    return hasJob2()
end

local function isInFactionSelf(ped)
    return isSamePlayer(ped) and hasJob2()
end

local function isInFactionOther(ped)
    return canInteractWithOtherPlayerWhenAlive(ped) and hasJob2()
end

local function hasItem(itemName)
    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return false
    end
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.PlayerData.inventory[i].name == itemName and VFW.PlayerData.inventory[i].count > 0 then
            return true
        end
    end
    return false
end

-- Condition pour afficher le bouton menotter (affiche toujours si faction + distance OK)
local function canHandcuff(ped)
    if not isInFactionOther(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    return true
end

-- Condition pour gouvernement seulement - menotter
local function canHandcuffGovernment(ped)
    if not isTargetInGovernment(ped) then
        return false
    end
    if not hasGouvSecurityPerm() then
        return false
    end
    -- Vérifier s'il a les menottes OU les clés
    if not hasItem("handcuff") and not hasItem("handcuff_key") then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    return true
end

-- Condition pour afficher le bouton démenotter (affiche toujours si faction + distance OK)
local function canUncuff(ped)
    if not isInFactionOther(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    return true
end

-- Condition pour gouvernement seulement - démenotter
local function canUncuffGovernment(ped)
    if not isTargetInGovernment(ped) then
        return false
    end
    if not hasGouvSecurityPerm() then
        return false
    end
    -- Vérifier les clés de menottes
    if not hasItem("handcuff_key") then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    return true
end

-- Condition pour gouvernement seulement - fouiller
local function canFriskGovernment(ped)
    if not isTargetInGovernment(ped) then
        return false
    end
    if not hasGouvSecurityPerm() then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    return true
end

-- Condition pour afficher le bouton escorter (affiche toujours si faction + distance OK)
local function canEscort(ped)
    if not isInFactionOther(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    return true
end

local function canBagHead(ped)
    if not canInteractWithOtherPlayerWhenAlive(ped) then
        return false
    end
    local hasBag = hasItem("sactete")
    if not hasBag then
        return false
    end
    -- Vérifier la distance
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    -- Ne pas proposer si la cible a déjà un sac
    local targetState = Entity(ped).state
    if targetState and targetState.isBagged then
        return false
    end
    return true
end

local function canRemoveBag(ped)
    if not canInteractWithOtherPlayerWhenAlive(ped) then
        return false
    end
    -- Vérifier la distance
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    -- Vérifier si la cible a un sac
    local targetState = Entity(ped).state
    return targetState and targetState.isBagged
end

--endregion

--region ====== ACTION FUNCTIONS ======

local function meContextMenu()
    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local me = VFW.Nui.KeyboardInput(true, "Décrivez votre action (/me)", "", 100)
        if me ~= nil and me ~= "" and me ~= "KBD_CANCEL" then
            ExecuteCommand("me " .. tostring(me))
        end
    end)
end

local function refreshSkinContextMenu(ped)
    TriggerEvent('skinchanger:getSkin', function(skin)
        if skin then
            ClearPedTasks(ped)
            ClearPedSecondaryTask(ped)
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            TriggerEvent('skinchanger:loadSkin', skin)
            SetEntityCoords(ped, coords.x, coords.y, coords.z + 0.1, false, false, false, false)
            SetEntityHeading(ped, heading)
            Wait(100)
            ClearPedTasksImmediately(ped)
            VFW.ShowNotification({ type = 'VERT', content = "Skin rafraîchi" })
        else
            VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de récupérer le skin" })
        end
    end)
end

local function clearCharacterContextMenu(ped)
    ExecuteCommand("proper")
end

local function detachObjectContextMenu(ped)
    local isInStaff = VFW.IsInStaffMode()
    local detachedCount = 0

    -- Anti use-bug : ranger l'arme en main pour éviter une arme invisible
    local currentWeapon = GetSelectedPedWeapon(ped)
    if currentWeapon and currentWeapon ~= `WEAPON_UNARMED` then
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        LastWeaponId = nil
    end

    for i = 0, 12 do
        if not (i == 0 and isInStaff) then
            ClearPedProp(ped, i)
        end
    end

    if RemoveWeaponProp then
        RemoveWeaponProp()
    end

    TriggerServerEvent("vfw:newanim:deleteAllProps")

    if VFW.StopCarrying then
        VFW.StopCarrying()
    end

    if IsEntityAttached(ped) then
        DetachEntity(ped, true, true)
    end

    local objects = GetGamePool('CObject')
    for i = 1, #objects do
        local obj = objects[i]
        if DoesEntityExist(obj) and GetEntityAttachedTo(obj) == ped then
            DetachEntity(obj, true, true)
            DeleteEntity(obj)
            detachedCount = detachedCount + 1
        end
    end

    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)

    VFW.ShowNotification({ type = 'VERT', content = "Tous les objets ont été détachés" .. (detachedCount > 0 and (" (" .. detachedCount .. " supprimés)") or "") .. "." })
end

local function ToggleCinemaMode()
    TriggerEvent("vfw:toggleCinemaMode")
end

--endregion

--region ====== DATA TABLES ======

local documents <const> = {
    { label = ":id: Carte d'identité", type = "identity" },
    { label = ":car: Permis de conduire", type = "driver" },
    { label = ":gun: PPA Léger", type = "weapon_leger" },
    { label = ":gun: PPA Lourd", type = "weapon_lourd" },
    { label = ":briefcase: Carte de travail", type = "job" }
}

local animations <const> = {
    {
        label = " Emotes",
        emotes = {
            { label = " Lever les mains", name = "handsup" },
            { label = " Fuck", name = "finger" },
            { label = " Double Fuck", name = "flipoff2" },
            { label = " Coucou", name = "wave2" },
            { label = " Réfléchir", name = "crossarms" },
            { label = " C'est OK", name = "thumbsup" },
            { label = " Gifler", name = "slap" },
            { label = " Peace", name = "peace" },
            { label = " Au pied", name = "stop" },
        }
    },
    {
        label = ":music: Musique",
        emotes = {
            { label = " Tambour", name = "bongos" },
            { label = " Guitare", name = "guitar" },
            { label = " Saxophone", name = "sax" },
        }
    },
    {
        label = ":box: S'asseoir",
        emotes = {
            { label = " Sur une chaise", name = "sitchair" },
            { label = " Par terre", name = "sit3" },
        }
    },
    {
        label = ":user: Positions",
        emotes = {
            { label = " Allongé détendu", name = "cloudgaze2" },
            { label = ":hourglass: Attendre", name = "wait" },
            { label = " Attendre mains devant", name = "wait13" },
            { label = " Mains croisées", name = "crossarms2" },
            { label = " Mains derrière le dos", name = "crosshands" },
            { label = ":police: Main sur la ceinture", name = "cop" },
            { label = " Salut militaire", name = "airforce04" },
        }
    },
    {
        label = " Démarches",
        isWalkStyle = true,
        emotes = {
            { label = " Confiante", name = "move_" },
            { label = " Féminine", name = "move_f@heels@c" },
            { label = " Militaire", name = "move_m@brave" },
            { label = " Triste", name = "move_m@sad@a" },
        }
    },
    {
        label = " Sport",
        emotes = {
            { label = " Pompes", name = "pushup" },
            { label = " Abdos", name = "situp" },
            { label = " Jumping Jacks", name = "jumpingjacks" },
            { label = " Glissade genoux", name = "slide" },
            { label = ":target: Position combat", name = "fightme" },
        }
    },
    {
        label = ":heart: Love",
        emotes = {
            { label = " Bisous", name = "blowkiss" },
            { label = " Bisous 2", name = "blowkiss2" },
            { label = " Câlin", name = "hump2" },
        }
    },
}

local adminActions <const> = {
    { label = ":dot-green: Heal", action = "staff:heal", permission = "alt_heal" },
    { label = " Manger", action = "staff:eat", permission = "alt_heal" },
    { label = " Hydrater", action = "staff:thirst", permission = "alt_heal" },
    { label = ":shield: Armure", action = "staff:armor", permission = "alt_heal" },
    { label = ":skull: Kill", action = "staff:kill", permission = "alt_heal" },
}

local playerInfo <const> = {
    { label = ":user: Prénom", data = "firstName" },
    { label = ":user: Nom", data = "lastName" },
    { label = " Date de naissance", data = "date_of_birth" },
    { label = ":ruler: Taille", data = "height" },
    { label = ":briefcase: Job", data = "job_label" },
    { label = ":users: Groupe", data = "job2_label" },
    { label = ":money: Argent liquide", data = "money" },
    { label = ":building: Argent banque", data = "bank" },
    { label = ":money: Argent sale", data = "black_money" },
    { label = ":clock: Temps de jeu", data = "total_playtime" },
}

local factionEmotes <const> = {
    { label = " Mains dans les poches", name = "pockets" },
    { label = " Fumer", name = "smoke" },
    { label = ":monitor: Téléphone", name = "phone" },
    { label = " Boire", name = "drink" },
    { label = " Lever les mains", name = "handsup" },
    { label = " S'adosser au mur", name = "lean" },
    { label = " Croiser les bras", name = "crossarms" },
}

--endregion

--region ====== 1. ACTIONS STAFF (SUR SOI-MÊME) ======

local subMenuAdminSelf = VFW.ContextAddSubmenu("ped", ":police: Actions Staff", canShowButtonAdmin, {}, nil)
local subMenuPlayerAction = VFW.ContextAddSubmenu("ped", ":gamepad: Actions sur moi", canShowButtonAdmin, {}, subMenuAdminSelf)
local subMenuAdminInfo = VFW.ContextAddSubmenu("ped", ":report: Mes informations", canShowButtonAdmin, {}, subMenuAdminSelf)
VFW.ContextBindScope(subMenuAdminInfo, "player:identity")

-- Actions sur moi
for i = 1, #adminActions do
    local actions <const> = adminActions[i]
    VFW.ContextAddButton("ped", actions.label, canShowButtonAdmin, nil, {}, subMenuPlayerAction, {
        serverAction = actions.action,
        permission = actions.permission
    })
end

-- Mes informations
for i = 1, #playerInfo do
    local info <const> = playerInfo[i]
    VFW.ContextAddInfo("ped", info.label, canShowButtonAdmin, function(ped, scope)
        local value = scope and scope[info.data]
        if value == nil or value == "" then return "N/A" end
        return tostring(value)
    end, {}, subMenuAdminInfo, { useScope = true })
end

--endregion

--region ====== 2. ACTIONS DEV NPC ======

-- Top-level dev menu for peds (staff only)
local pedDevSubmenu = VFW.ContextAddSubmenu("ped", ":monitor: Action Dev", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu") and VFW.IsInStaffMode()
end, { color = { 255, 64, 64 } }, nil)

-- NPC-specific actions submenu
local npcActionsSubmenu = VFW.ContextAddSubmenu("ped", "Action NPC", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, {}, pedDevSubmenu)

VFW.ContextAddButton("ped", ":trash: Supprimer le NPC", function(ped)
    return IsNPC(ped) and HasStaffPermission("alt_delete_entity")
end, nil, {}, npcActionsSubmenu, { serverAction = "ped:delete", permission = "alt_delete_entity" })

local npcInfoSubmenu = VFW.ContextAddSubmenu("ped", ":chart: Infos", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, {}, npcActionsSubmenu)

local npcPositionSubmenu = VFW.ContextAddSubmenu("ped", ":pin: Position & Déplacement", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, {}, npcActionsSubmenu)

-- Infos NPC
VFW.ContextAddInfo("ped", "Modèle", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, function(ped)
    return GetEntityArchetypeName(ped)
end, {}, npcInfoSubmenu)

VFW.ContextAddButton("ped", ":report: Copier le nom", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, function(ped)
    VFW.Clipboard(GetEntityArchetypeName(ped))
    VFW.ShowNotification({ type = 'VERT', content = "Nom copié" })
end, {}, npcInfoSubmenu)

VFW.ContextAddButton("ped", ":report: Copier le hash", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, function(ped)
    VFW.Clipboard(GetEntityModel(ped))
    VFW.ShowNotification({ type = 'VERT', content = "Hash copié" })
end, {}, npcInfoSubmenu)

VFW.ContextAddButton("ped", ":report: Copier l'ID entité", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, function(ped)
    VFW.Clipboard(ped)
    VFW.ShowNotification({ type = 'VERT', content = "ID entité copié: " .. ped })
end, {}, npcInfoSubmenu)

-- Position & Déplacement NPC
VFW.ContextAddButton("ped", ":report: Copier la position", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, function(ped)
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local posFinal = formatNumber(pos.x) .. ", " .. formatNumber(pos.y) .. ", " .. formatNumber(pos.z) .. ", " .. formatNumber(heading)
    VFW.Clipboard(posFinal)
    VFW.ShowNotification({ type = 'VERT', content = "Position copiée" })
end, {}, npcPositionSubmenu)

VFW.ContextAddButton("ped", ":refresh: Déplacer", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, function(ped)
    Target:MouveEntity(ped)
end, {}, npcPositionSubmenu)

VFW.ContextAddButton("ped", ":report: Dupliquer", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, function(ped)
    local new = Target:DuplicateEntity(ped)
    Target:MouveEntity(new)
    VFW.ShowNotification({ type = 'VERT', content = "NPC dupliqué" })
end, {}, npcPositionSubmenu)

VFW.ContextAddButton("ped", ":refresh: Refresh le NPC", function(ped)
    return IsNPC(ped) and HasStaffPermission("contextmenu")
end, function(ped)
    -- Reset le comportement du NPC
    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)

    -- Vérifier si le NPC a une position originale stockée (via statebag)
    local state = Entity(ped).state
    if state and state.originalPos then
        local pos = state.originalPos
        SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
        if pos.heading then
            SetEntityHeading(ped, pos.heading)
        end
        VFW.ShowNotification({ type = 'VERT', content = "NPC remis a sa position originale" })
    else
        VFW.ShowNotification({ type = 'VERT', content = "NPC rafraichi" })
    end
end, {}, npcPositionSubmenu)

--endregion

--region ====== 3. ACTIONS STAFF JOUEUR (AUTRES) ======

local playerStaffSubmenu = VFW.ContextAddSubmenu("ped", ":police: Action Staff", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("contextmenu") and VFW.IsInStaffMode()
end, { color = { 255, 64, 64 } }, nil)

local playerInfoSubmenu = VFW.ContextAddSubmenu("ped", ":chart: Infos", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("contextmenu") and VFW.IsInStaffMode()
end, {}, playerStaffSubmenu)
VFW.ContextBindScope(playerInfoSubmenu, "player:identity")

local playerTeleportSubmenu = VFW.ContextAddSubmenu("ped", ":rocket: Téléportation", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_teleport") and VFW.IsInStaffMode()
end, {}, playerStaffSubmenu)

local playerAnimSubmenu = VFW.ContextAddSubmenu("ped", ":film: Animations", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_ped_management") and VFW.IsInStaffMode()
end, {}, playerStaffSubmenu)

local playerActionsSubmenu = VFW.ContextAddSubmenu("ped", ":wrench: Actions", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("contextmenu") and VFW.IsInStaffMode()
end, {}, playerStaffSubmenu)

-- Infos Joueur (avec scope player:identity)
local otherPlayerInfo <const> = {
    { label = ":user: Prénom", data = "firstName" },
    { label = ":user: Nom", data = "lastName" },
    { label = " Date de naissance", data = "date_of_birth" },
    { label = ":ruler: Taille", data = "height" },
    { label = ":briefcase: Job", data = "job_label" },
    { label = ":users: Groupe", data = "job2_label" },
    { label = ":money: Argent liquide", data = "money" },
    { label = ":building: Argent banque", data = "bank" },
    { label = ":money: Argent sale", data = "black_money" },
    { label = ":clock: Temps de jeu", data = "total_playtime" },
}

for i = 1, #otherPlayerInfo do
    local info <const> = otherPlayerInfo[i]
    VFW.ContextAddInfo("ped", info.label, function(ped)
        return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("contextmenu") and VFW.IsInStaffMode()
    end, function(ped, scope)
        local value = scope and scope[info.data]
        if value == nil or value == "" then return "N/A" end
        return tostring(value)
    end, {}, playerInfoSubmenu, { useScope = true })
end

VFW.ContextAddInfo("ped", ":id: ID Serveur", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("contextmenu") and VFW.IsInStaffMode()
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    return serverId and ("#" .. serverId) or "Inconnu"
end, {}, playerInfoSubmenu)

VFW.ContextAddButton("ped", ":report: Copier l'ID", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("contextmenu") and VFW.IsInStaffMode()
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if serverId then
        VFW.Clipboard("#" .. serverId)
        VFW.ShowNotification({ type = 'VERT', content = "ID copié: #" .. serverId })
    end
end, {}, playerInfoSubmenu)

-- Actions Joueur
VFW.ContextAddButton("ped", ":document: Ouvrir la page admin", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("staff_menu") and VFW.IsInStaffMode()
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if serverId then
        VFW.CloseContextMenu()
        ExecuteCommand("openplayer " .. serverId)
    end
end, {}, playerActionsSubmenu)

VFW.ContextAddButton("ped", ":scales: Sanctionner", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("sanctions") and VFW.IsInStaffMode()
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if serverId then
        VFW.OpenContextMenu()
        CreateThread(function()
            Wait(250)
            local playerInfo = TriggerServerCallback("vfw:staff:getPlayerInfo", serverId)
            if playerInfo and StaffMenu and StaffMenu.OpenSanctionsUI then
                local playerData = {
                    id = playerInfo.id,
                    source = serverId,
                    name = playerInfo.name,
                    identifier = playerInfo.identifier,
                    discord = playerInfo.discord,
                    online = true
                }
                StaffMenu.OpenSanctionsUI(playerData)
            else
                VFW.ShowNotification({ type = 'ROUGE', content = "Impossible d'ouvrir l'interface sanctions" })
            end
        end)
    end
end, {}, playerActionsSubmenu)

VFW.ContextAddButton("ped", " Voir inventaire", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("inventaire") and VFW.IsInStaffMode()
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if serverId then
        VFW.CloseContextMenu()
        VFW.OpenShearchStaff(serverId)
    end
end, {}, playerActionsSubmenu)

VFW.ContextAddButton("ped", ":money: Confisquer l'inventaire", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("inventaire") and VFW.IsInStaffMode()
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if serverId then
        VFW.OpenContextMenu()
        CreateThread(function()
            Wait(250)
            local info = TriggerServerCallback("vfw:staff:getPlayerInfo", serverId) or {}
            local rpName = "Inconnu"
           if info.firstName and info.lastName then
                rpName = info.firstName .. " " .. info.lastName
            elseif info.name then
                rpName = info.name
            end
            VFW.InventoryCleaner(serverId, rpName)
        end)
    end
end, {}, playerActionsSubmenu)

-- Téléportation Joueur
VFW.ContextAddButton("ped", ":rocket: Aller vers lui", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_teleport")
end, function(ped)
    lastStaffTeleportPos = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    StaffTeleportToCoords(targetCoords.x + 1.0, targetCoords.y, targetCoords.z)
    VFW.ShowNotification({ type = 'VERT', content = "Téléporté vers le joueur" })
end, {}, playerTeleportSubmenu)

VFW.ContextAddButton("ped", " L'amener à moi", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_teleport")
end, nil, {}, playerTeleportSubmenu, { serverAction = "ped:teleportToMe", permission = "alt_teleport" })

VFW.ContextAddButton("ped", ":car: TP Fourrière", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_teleport")
end, nil, {}, playerTeleportSubmenu, { serverAction = "ped:teleportToPound", permission = "alt_teleport" })

VFW.ContextAddButton("ped", " TP PC", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_teleport")
end, nil, {}, playerTeleportSubmenu, { serverAction = "ped:teleportToPolice", permission = "alt_teleport" })

VFW.ContextAddButton("ped", " TP Place des Cubes", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_teleport")
end, nil, {}, playerTeleportSubmenu, { serverAction = "ped:teleportToPlaceDesCubes", permission = "alt_teleport" })

VFW.ContextAddButton("ped", ":back: Retour", function(ped)
    return lastStaffTeleportPos ~= nil and HasStaffPermission("alt_teleport")
end, function(ped)
    local pos = lastStaffTeleportPos
    lastStaffTeleportPos = nil
    StaffTeleportToCoords(pos.x, pos.y, pos.z)
    VFW.ShowNotification({ type = 'VERT', content = "Retour à la position précédente" })
end, {}, playerTeleportSubmenu)

-- Animations Joueur
VFW.ContextAddButton("ped", " Mains en l'air", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_ped_management")
end, nil, {}, playerAnimSubmenu, { serverAction = "ped:playAnim", extra = { dict = "missminuteman_1ig_2", anim = "handsup_base", flag = 49 }, permission = "alt_ped_management" })

VFW.ContextAddButton("ped", " Mains sur la tête", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_ped_management")
end, nil, {}, playerAnimSubmenu, { serverAction = "ped:playAnim", extra = { dict = "random@arrests@busted", anim = "idle_a", flag = 49 }, permission = "alt_ped_management" })

VFW.ContextAddButton("ped", " S'agenouiller", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_ped_management")
end, nil, {}, playerAnimSubmenu, { serverAction = "ped:playAnim", extra = { dict = "random@arrests", anim = "kneeling_arrest_idle", flag = 1 }, permission = "alt_ped_management" })

VFW.ContextAddButton("ped", ":arrow: Plaquer au sol", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_ped_management")
end, nil, {}, playerAnimSubmenu, { serverAction = "ped:tackleDown", extra = { dict = "missfbi3_sniping", anim = "prone_dave", flag = 1 }, permission = "alt_ped_management" })

VFW.ContextAddButton("ped", ":box: S'asseoir", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_ped_management")
end, nil, {}, playerAnimSubmenu, { serverAction = "ped:playAnim", extra = { dict = "anim@amb@business@bgen@bgen_no_work@", anim = "sit_phone_phoneputdown_idle_nowork", flag = 1 }, permission = "alt_ped_management" })

VFW.ContextAddButton("ped", "⏹ Arrêter l'animation", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("alt_ped_management")
end, nil, {}, playerAnimSubmenu, { serverAction = "ped:stopAnim", permission = "alt_ped_management" })

-- Contrôle Joueur

--endregion

--region ====== 4. ACTIONS ANIMATEUR JOUEUR ======

local playerAnimatorSubmenu = VFW.ContextAddSubmenu("ped", ":mask: Action Animateur", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, { color = { 138, 43, 226 } }, nil)

VFW.ContextAddButton("ped", ":document: Ouvrir la page joueur", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if serverId then
        VFW.CloseContextMenu()
        VFW.Nui.Focus(false)
        StaffMenu.OpenPlayerMenu(serverId, true)
    end
end, {}, playerAnimatorSubmenu)

local animatorTeleportSubmenu = VFW.ContextAddSubmenu("ped", ":rocket: Téléportation", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, {}, playerAnimatorSubmenu)

VFW.ContextAddButton("ped", ":rocket: Aller vers lui", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, function(ped)
    lastStaffTeleportPos = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    StaffTeleportToCoords(targetCoords.x + 1.0, targetCoords.y, targetCoords.z)
    VFW.ShowNotification({ type = 'VERT', content = "Téléporté vers le joueur" })
end, {}, animatorTeleportSubmenu)

VFW.ContextAddButton("ped", " L'amener à moi", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, nil, {}, animatorTeleportSubmenu, { serverAction = "ped:teleportToMe", permission = "menu_anim" })

VFW.ContextAddButton("ped", ":car: TP Fourrière", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, nil, {}, animatorTeleportSubmenu, { serverAction = "ped:teleportToPound", permission = "menu_anim" })

VFW.ContextAddButton("ped", " TP PC", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, nil, {}, animatorTeleportSubmenu, { serverAction = "ped:teleportToPolice", permission = "menu_anim" })

VFW.ContextAddButton("ped", " TP Place des Cubes", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, nil, {}, animatorTeleportSubmenu, { serverAction = "ped:teleportToPlaceDesCubes", permission = "menu_anim" })

VFW.ContextAddButton("ped", ":back: Retour", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, nil, {}, animatorTeleportSubmenu, { serverAction = "ped:returnBroughtPlayer", permission = "menu_anim" })

VFW.ContextAddButton("ped", ":gift: Give Item Temporaire", function(ped)
    return canStaffInteractWithOtherPlayer(ped) and HasStaffPermission("menu_anim") and VFW.IsInAnimatorMode()
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if serverId then
        VFW.CloseContextMenu()
        StaffMenu.animatorData.giveType = 1
        StaffMenu.animatorData.targetPlayerId = serverId
        StaffMenu.animatorData.itemQuery = nil
        StaffMenu.animatorData.currentPage = 1
        StaffMenu.animatorData.selectedQuantity = 1
        StaffMenu.animatorStandaloneGiveItem.open()
    end
end, {}, playerAnimatorSubmenu)

--endregion

--region ====== job action ======

local POLICE_JOBS_CTX = PoliceJobsList
local LAW_ENFORCEMENT_JOBS_CTX = LawEnforcementJobsList

local function isUSSSJob(jobName)
    return jobName and string.lower(jobName):find("usss") ~= nil
end

local jobContext = VFW.ContextAddSubmenu("ped", " Action Métier", function(ped)
    -- Bloquer si le joueur est mort
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    -- Exclure les jobs SAMS/LSFD (gérés par sn_sams)
    if VFW.PlayerData.job and (VFW.PlayerData.job.name == "sams_pib" or VFW.PlayerData.job.name == "sams_pab") then
        return false
    end
    -- Exclure les jobs police et milice (gérés par le context menu police)
    if VFW.PlayerData.job and LAW_ENFORCEMENT_JOBS_CTX[VFW.PlayerData.job.name] then
        return false
    end
    if isUSSSJob(VFW.PlayerData.job.name) then
        return false
    end
    if not IsOtherPlayer(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then return false end
    return VFW.PlayerData.job and VFW.PlayerData.job.name ~= "unemployed"
end, {}, nil)

-- Facture pour les jobs non-gouvernement
VFW.ContextAddButton("ped", ":edit: Faire une facture", function(ped)
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if not IsOtherPlayer(ped) then return false end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then return false end
    if not VFW.PlayerData.job or VFW.PlayerData.job.name == "unemployed" then return false end
    return not isPlayerInGovernment()
end, function(ped)
    local playerId = GetPlayerServerIdFromPed(ped)
    OpenInvoice(playerId)
end, {}, jobContext)

-- Facture personnelle gouvernement (permission create_invoice)
VFW.ContextAddButton("ped", ":edit: Facture personnelle", function(ped)
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if not IsOtherPlayer(ped) then return false end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then return false end
    local hasPerm = hasGouvInvoicePerm()
    return hasPerm
end, function(ped)
    local playerId = GetPlayerServerIdFromPed(ped)
    TriggerEvent("vfw:radial:open:invoice", playerId, "personal")
end, {}, jobContext)

-- Facture entreprise gouvernement (permission create_invoice_company)
VFW.ContextAddButton("ped", ":edit: Facture entreprise", function(ped)
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if not IsOtherPlayer(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    local _, hasCompanyPerm = hasGouvInvoicePerm()
    return hasCompanyPerm
end, function(ped)
    local playerId = GetPlayerServerIdFromPed(ped)
    TriggerEvent("vfw:radial:open:invoice", playerId, "company")
end, {}, jobContext)

-- Actions Gouvernement (dans le même submenu)
-- Menotter / Démenotter
VFW.ContextAddButton("ped", ":chat: Menotter / Démenotter", canHandcuffGovernment, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        gouvNotif("Menottes", "Joueur introuvable")
        return
    end
    TriggerServerEvent("gouvernement:toggleHandcuff", targetServerId)
end, {}, jobContext)

-- Fouiller
VFW.ContextAddButton("ped", ":money: Fouiller", canFriskGovernment, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        gouvNotif("Fouille", "Joueur introuvable")
        return
    end
    TriggerServerEvent("gouvernement:search", targetServerId)
end, {}, jobContext)

-- Escorter
VFW.ContextAddButton("ped", " Escorter", function(ped)
    if not isTargetInGovernment(ped) then
        return false
    end
    return hasGouvSecurityPerm()
end, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        gouvNotif("Escorte", "Joueur introuvable")
        return
    end
    TriggerServerEvent("gouvernement:escort", targetServerId)
end, {}, jobContext)

VFW.ContextAddButton("ped", " Délivrer Visa de Cayo", function(ped)
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then return false end
    if not IsOtherPlayer(ped) then return false end
    if not isPlayerInCayoGouv() then return false end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then return false end
    local targetServerId = GetPlayerServerIdFromPed(ped)
    return getCayoVisaStatus(targetServerId) == false
end, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Joueur introuvable." })
        return
    end
    local response = TriggerServerCallback("cayo_visa:grant", { targetServerId = targetServerId })
    if response then
        VFW.ShowNotification({ type = response.success and 'VERT' or 'ROUGE', content = response.message })
        if response.success then invalidateCayoVisaCache(targetServerId) end
    end
end, {}, jobContext)

VFW.ContextAddButton("ped", " Retirer Visa de Cayo", function(ped)
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then return false end
    if not IsOtherPlayer(ped) then return false end
    if not isPlayerInCayoGouv() then return false end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then return false end
    local targetServerId = GetPlayerServerIdFromPed(ped)
    return getCayoVisaStatus(targetServerId) == true
end, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Joueur introuvable." })
        return
    end
    local response = TriggerServerCallback("cayo_visa:revoke", { targetServerId = targetServerId })
    if response then
        VFW.ShowNotification({ type = response.success and 'VERT' or 'ROUGE', content = response.message })
        if response.success then invalidateCayoVisaCache(targetServerId) end
    end
end, {}, jobContext)

--endregion

--region ====== 4. ACTIONS FACTION (SUR AUTRES) ======

local subMenuFactionOther = VFW.ContextAddSubmenu("ped", ":users: Actions Faction", isInFactionOther, {}, nil)

-- Attacher avec serflex
VFW.ContextAddButton("ped", ":chat: Attacher", canHandcuff, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Personne introuvable" })
        return
    end

    -- Vérifier si le joueur a un serflex
    if not hasItem("serflex") then
        VFW.ShowNotification({ type = 'ROUGE', content = "Pour attacher quelqu'un tu dois avoir un serflex sur toi" })
        return
    end

    -- Retirer le serflex et menotter (l'alignement se fait automatiquement via xPlayer.handcuff)
    local result = TriggerServerCallback("faction:menu:handcuff", targetServerId)
    if result and result.success then
        VFW.ShowNotification({ type = 'VERT', content = result.message })
    elseif result then
        VFW.ShowNotification({ type = 'ROUGE', content = result.message })
    end
end, {}, subMenuFactionOther)

-- Détacher avec pince à serflex
VFW.ContextAddButton("ped", ":unlock: Détacher", canUncuff, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Personne introuvable" })
        return
    end

    -- Vérifier si le joueur a une pince à serflex
    if not hasItem("pince_serflex") then
        VFW.ShowNotification({ type = 'ROUGE', content = "Pour détacher quelqu'un tu dois avoir une pince à serflex sur toi" })
        return
    end

    -- Vérifier si la cible est menottée
    local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", targetServerId)
    if not isCuffed then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette personne n'est pas attachée" })
        return
    end

    -- Démenotter (la pince ne se consomme pas, l'alignement n'est pas nécessaire)
    local result = TriggerServerCallback("faction:menu:uncuff", targetServerId)
    if result and result.success then
        VFW.ShowNotification({ type = 'VERT', content = result.message })
    elseif result then
        VFW.ShowNotification({ type = 'ROUGE', content = result.message })
    end
end, {}, subMenuFactionOther)

-- Escorter
VFW.ContextAddButton("ped", " Escorter", canEscort, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Personne introuvable" })
        return
    end

    local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", targetServerId)
    if not isCuffed then
        VFW.ShowNotification({ type = 'ROUGE', content = "La personne doit être attachée pour l'escorter" })
        return
    end

    if VFW.isEscorting then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous escortez déjà quelqu'un" })
        return
    end

    if VFW.Jobs.StartEscort(targetServerId, ped) then
        VFW.ShowNotification({ type = 'VERT', content = "Vous escortez la personne" })
    end
end, {}, subMenuFactionOther)

-- Arrêter l'escorte (visible hors du sous-menu faction, accessible sur n'importe quel ped)
VFW.ContextAddButton("ped", " Arrêter l'escorte", function()
    return VFW.isEscorting
end, function()
    VFW.Jobs.StopEscort()
    VFW.ShowNotification({ type = 'VERT', content = "Escorte arrêtée" })
end)

VFW.ContextAddButton("ped", ":money: Fouiller", function(ped)
    if not isInFactionOther(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    return true
end, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Personne introuvable" })
        return
    end

    local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", targetServerId)
    local isHandsUp = VFW.IsPlayerHandsUp(ped)

    if not isCuffed and not isHandsUp then
        VFW.ShowNotification({ type = 'ROUGE', content = "La personne doit avoir les mains en l'air ou être attachée" })
        return
    end

    VFW.OpenShearch(targetServerId)
end, {}, subMenuFactionOther)

-- Event pour téléporter le joueur (utilisé par le staff bring)
RegisterNetEvent("vfw:teleportTo", function(x, y, z)
    StaffTeleportToCoords(x, y, z)
end)

--endregion

--region ====== 6. INTERACTIONS (AUTRES JOUEURS) ======

-- Helper functions pour vérifier les items du joueur
local function hasAnyGiveableItem()
    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return false
    end
    if not VFW.Items then
        return false
    end
    for i = 1, #VFW.PlayerData.inventory do
        local invItem = VFW.PlayerData.inventory[i]
        if invItem and invItem.count > 0 and invItem.name ~= "money" and invItem.name ~= "dirty_money" then
            local itemData = VFW.Items[invItem.name]
            -- Accepter les items avec type valide OU sans type (pour compatibilité)
            if itemData then
                local itemType = itemData.type
                if not itemType or (itemType ~= "clothes" and itemType ~= "outfit") then
                    return true
                end
            end
        end
    end
    return false
end

local function hasGiveableItemOfType(itemType)
    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return false
    end
    if not VFW.Items then
        return false
    end
    for i = 1, #VFW.PlayerData.inventory do
        local invItem = VFW.PlayerData.inventory[i]
        if invItem and invItem.count > 0 and invItem.name ~= "money" and invItem.name ~= "dirty_money" then
            local itemData = VFW.Items[invItem.name]
            if itemData then
                local dataType = itemData.type
                -- Accepter les items avec type valide OU sans type (pour compatibilité)
                if not dataType or (dataType ~= "clothes" and dataType ~= "outfit") then
                    local isConsumable = itemData.data and itemData.data.type == "consumable"
                   if itemType == "consumable" and isConsumable then
                        return true
                    elseif itemType == "objects" and not isConsumable then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local interactionsSubmenu = VFW.ContextAddSubmenu("ped", " Interactions", function(ped)
    if not IsOtherPlayer(ped) then
        return false
    end
    -- Bloquer les interactions si le joueur est mort
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    return #(myCoords - targetCoords) <= 3.0
end, {}, nil)

-- Premiers secours: etat
local isDoingCPR = false
local cprTargetId = nil -- server id du ped soigne

-- Premiers secours (accessible à TOUS les joueurs sur un ped mort/coma)
VFW.ContextAddButton("ped", " Faire les premiers secours", function(ped)
    if isDoingCPR then
        return false
    end
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if not IsOtherPlayer(ped) then
        return false
    end
    if not IsPedDeadOrDying(ped, true) and not VFW.GetDeathCloneOwner(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    return #(myCoords - targetCoords) <= 3.0
end, function(ped)
    local myPed = PlayerPedId()
    local animDict = "mini@cpr@char_a@cpr_str"
   local animName = "cpr_pumpchest"

   isDoingCPR = true
    cprTargetId = GetPlayerServerIdFromPed(ped)

    VFW.CloseContextMenu()

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    TaskPlayAnim(myPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)

    VFW.ShowNotification({
        type = 'BLEU',
        content = "Vous effectuez les premiers secours..."
   })

    local cancelledByRevive = false

    while isDoingCPR do
        Wait(0)
        if IsControlJustPressed(0, 73) then
            isDoingCPR = false
            cprTargetId = nil
            break
        end
        if not IsPedDeadOrDying(ped, true) and not VFW.GetDeathCloneOwner(ped) then
            isDoingCPR = false
            cprTargetId = nil
            cancelledByRevive = true
            break
        end
        if not IsEntityPlayingAnim(myPed, animDict, animName, 3) then
            TaskPlayAnim(myPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end

    ClearPedTasks(myPed)
    RemoveAnimDict(animDict)

    if cancelledByRevive then
        VFW.ShowNotification({
            type = 'ORANGE',
            content = "La personne a été réanimée, premiers secours annulés"
       })
    else
        VFW.ShowNotification({
            type = 'VERT',
            content = "Premiers secours terminés"
       })
    end
end, {}, interactionsSubmenu)

-- Bouton pour arreter les premiers secours (context menu sur le ped cible)
VFW.ContextAddButton("ped", ":x: Arrêter les premiers secours", function(ped)
    if not isDoingCPR then
        return false
    end
    local targetServerId = GetPlayerServerIdFromPed(ped)
    return targetServerId ~= nil and targetServerId == cprTargetId
end, function()
    isDoingCPR = false
    cprTargetId = nil
end, { color = { 255, 60, 60 } }, nil)

-- Réanimation civile (medikit + aucun SAMS en service)
VFW.ContextAddButton("ped", ":flask: Réanimer (Kit d'urgence)", function(ped)
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if not IsOtherPlayer(ped) then
        return false
    end
    if not IsPedDeadOrDying(ped, true) and not VFW.GetDeathCloneOwner(ped) then
        return false
    end
    if not hasItem("medikit") then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 3.0 then
        return false
    end
    return true
end, function(ped)
    -- Verifier qu'aucun SAMS n'est en service
    local samsOnDuty = TriggerServerCallback("sn_sams:isSamsOnDuty")
    if samsOnDuty then
        VFW.ShowNotification({ type = 'ROUGE', content = "Des médecins sont en service, appelez le SAMS !" })
        return
    end

    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Personne introuvable" })
        return
    end

    VFW.CloseContextMenu()
    TriggerServerEvent("sn_sams:civilRevive", targetServerId)
end, {}, interactionsSubmenu)

VFW.ContextAddButton("ped", " Porter", function(ped)
    if not IsOtherPlayer(ped) then
        return false
    end
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    return #(myCoords - targetCoords) <= 3.0
end, function(ped)
    VFW.CloseContextMenu()
    VFW.CarryPeople(ped)
end, {}, interactionsSubmenu)

VFW.ContextAddButton("ped", " Couper les cheveux", function(ped)
    if not IsOtherPlayer(ped) then
        return false
    end
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if not hasItem("ciseau") then
        return false
    end
    if not VFW.IsPlayerHandsUp(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    return #(myCoords - targetCoords) <= 3.0
end, function(ped)
    VFW.CloseContextMenu()
    if VFW.UseCiseau then
        VFW.UseCiseau(ped)
    end
end, {}, interactionsSubmenu)

-- Mettre un sac sur la tête (nécessite headbag + distance < 3m)
VFW.ContextAddButton("ped", " Mettre un sac", canBagHead, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Personne introuvable" })
        return
    end
    TriggerServerEvent("headbag:server:apply", targetServerId)
end, {}, interactionsSubmenu)

-- Retirer le sac de la tête (nécessite que la cible ait un sac + distance < 3m)
VFW.ContextAddButton("ped", ":x: Retirer le sac", canRemoveBag, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Personne introuvable" })
        return
    end
    TriggerServerEvent("headbag:server:remove", targetServerId)
end, {}, interactionsSubmenu)

VFW.ContextAddButton("ped", " Plaquer au sol", function(ped)
    return canInteractWithOtherPlayerWhenAlive(ped)
end, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        return
    end
    VFW.CloseContextMenu()
    TriggerServerEvent("interaction:tackle", targetServerId)
end, {}, interactionsSubmenu)

local giveItemSubmenu = VFW.ContextAddSubmenu("ped", ":gift: Donner un objet", function(ped)
    return canInteractWithOtherPlayerWhenAlive(ped) and hasAnyGiveableItem()
end, {}, interactionsSubmenu, { scrollable = true })

-- Fonction pour donner un item spécifique
local function giveItemToPed(ped, itemName, itemLabel)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de trouver le joueur" })
        return
    end

    -- Obtenir la quantité max
    local maxCount = 0
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.PlayerData.inventory[i].name == itemName then
            maxCount = maxCount + VFW.PlayerData.inventory[i].count
        end
    end

    if maxCount <= 0 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas cet item" })
        return
    end

    -- Fermer le context menu et attendre avant d'ouvrir le clavier
    VFW.CloseContextMenu()

    -- Utiliser CreateThread pour ne pas bloquer les callbacks
    Citizen.CreateThread(function()
        Wait(500)

        local numericCount = maxCount

        if maxCount > 1 then
            VFW.Nui.Focus(true)
            local count = VFW.Nui.KeyboardInput(true, "Quantité à donner (max: " .. maxCount .. ")", "", 10)

            if count == nil or count == "" or count == "KBD_CANCEL" then
                return
            end

            numericCount = tonumber(count)

            if not numericCount or numericCount <= 0 then
                VFW.ShowNotification({ type = 'ROUGE', content = "Cette quantité n'est pas valide" })
                return
            end

            if numericCount > maxCount then
                VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas assez de cet item" })
                return
            end
        end

        local success, inventoryOrError, weight = TriggerServerCallback("vfw:giveItemSpecific", targetServerId, itemName, math.floor(numericCount))

        if success then
            VFW.PlayerData.inventory = inventoryOrError
            VFW.PlayerData.weight = weight
            VFW.LoadInventories()
        else
            VFW.ShowNotification({ type = 'ROUGE', content = inventoryOrError or "Erreur lors du transfert" })
        end
    end)
end

-- Fonction pour obtenir les items de l'inventaire par type
local function getInventoryItemsByType(itemType)
    local items = {}
    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return items
    end
    if not VFW.Items then
        return items
    end

    for i = 1, #VFW.PlayerData.inventory do
        local invItem = VFW.PlayerData.inventory[i]
        if invItem and invItem.count > 0 and invItem.name ~= "money" and invItem.name ~= "dirty_money" then
            local itemData = VFW.Items[invItem.name]
            if itemData then
                local dataType = itemData.type
                -- Accepter les items avec type valide OU sans type (pour compatibilité)
                if not dataType or (dataType ~= "clothes" and dataType ~= "outfit") then
                    local isConsumable = itemData.data and itemData.data.type == "consumable"
                   if (itemType == "consumable" and isConsumable) or (itemType == "objects" and not isConsumable) then
                        -- Vérifier si l'item est déjà dans la liste
                        local found = false
                        for j = 1, #items do
                            if items[j].name == invItem.name then
                                items[j].count = items[j].count + invItem.count
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(items, {
                                name = invItem.name,
                                label = itemData.label or invItem.name,
                                count = invItem.count
                            })
                        end
                    end
                end
            end
        end
    end

    -- Trier par label
    table.sort(items, function(a, b)
        return a.label < b.label
    end)
    return items
end

-- Créer des boutons pour tous les items possibles du jeu
-- Les boutons ne s'afficheront que si le joueur possède l'item
local itemContextButtonsBuilt = false

local function generateItemContextButtons()
    if itemContextButtonsBuilt then return true end
    if not VFW.Items or next(VFW.Items) == nil then return false end

    local count = 0
    for itemName, itemData in pairs(VFW.Items) do
        if itemData and itemName ~= "money" and itemName ~= "dirty_money" then
            local itemType = itemData.type
            if not itemType or (itemType ~= "clothes" and itemType ~= "outfit") then
                local isConsumable = itemData.data and itemData.data.type == "consumable"
                local icon = isConsumable and "" or ":box:"
                local label = itemData.label or itemName

                VFW.ContextAddButton("ped", icon .. " " .. label, function(ped)
                    if not IsOtherPlayer(ped) then
                        return false
                    end
                    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
                        return false
                    end
                    if not VFW.PlayerData or not VFW.PlayerData.inventory then
                        return false
                    end
                    for i = 1, #VFW.PlayerData.inventory do
                        if VFW.PlayerData.inventory[i].name == itemName and VFW.PlayerData.inventory[i].count > 0 then
                            return true
                        end
                    end
                    return false
                end, function(ped)
                    giveItemToPed(ped, itemName, label)
                end, {}, giveItemSubmenu)
                count = count + 1
            end
        end
    end

    itemContextButtonsBuilt = true
    print(("^2[Context Menu] %d boutons d'objets générés^0"):format(count))
    return true
end

RegisterNetEvent("vfw:loadItems", function()
    generateItemContextButtons()
end)

CreateThread(function()
    local warned = false
    while not generateItemContextButtons() do
        Wait(500)
        if not warned then
            local waited = GetGameTimer()
            if waited >= 30000 then
                warned = true
                print("^3[Context Menu] En attente de VFW.Items (catalogue pas encore chargé)...^0")
            end
        end
    end
end)

-- Les boutons d'objets et consommables sont maintenant générés automatiquement ci-dessus

-- Fonction helper pour vérifier si le joueur a un type d'argent
local function hasMoneyType(moneyType)
    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return false
    end
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.PlayerData.inventory[i].name == moneyType and VFW.PlayerData.inventory[i].count > 0 then
            return true
        end
    end
    return false
end

-- Fonction helper pour obtenir le montant d'un type d'argent
local function getMoneyAmount(moneyType)
    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return 0
    end
    local total = 0
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.PlayerData.inventory[i].name == moneyType then
            total = total + VFW.PlayerData.inventory[i].count
        end
    end
    return total
end

-- Donner de l'argent propre (directement dans le menu Interactions)
VFW.ContextAddButton("ped", ":money: Donner argent propre", function(ped)
    return canInteractWithOtherPlayerWhenAlive(ped) and hasMoneyType("money")
end, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de trouver le joueur" })
        return
    end

    local maxAmount = getMoneyAmount("money")
    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local count = VFW.Nui.KeyboardInput(true, ":money: Montant à donner (max: " .. VFW.Math.FormatMoney(maxAmount) .. ")", "", 15)
        if count ~= nil and count ~= "" and count ~= "KBD_CANCEL" then
            local numericCount = tonumber(count)

            if not numericCount or numericCount <= 0 then
                VFW.ShowNotification({ type = 'ROUGE', content = "Ce montant n'est pas valide" })
                return
            end

            if numericCount > maxAmount then
                VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas assez d'argent" })
                return
            end

            local inventory, weight = TriggerServerCallback("vfw:giveMoneyType", targetServerId, "money", math.floor(numericCount))

            if inventory then
                VFW.PlayerData.inventory = inventory
                VFW.PlayerData.weight = weight
                VFW.LoadInventories()
            end
        end
    end)
end, {}, interactionsSubmenu)

-- Donner de l'argent sale (directement dans le menu Interactions)
VFW.ContextAddButton("ped", ":money: Donner argent sale", function(ped)
    return canInteractWithOtherPlayerWhenAlive(ped) and hasMoneyType("dirty_money")
end, function(ped)
    local targetServerId = GetPlayerServerIdFromPed(ped)
    if not targetServerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de trouver le joueur" })
        return
    end

    local maxAmount = getMoneyAmount("dirty_money")
    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local count = VFW.Nui.KeyboardInput(true, ":money: Montant à donner (max: " .. VFW.Math.FormatMoney(maxAmount) .. ")", "", 15)
        if count ~= nil and count ~= "" and count ~= "KBD_CANCEL" then
            local numericCount = tonumber(count)

            if not numericCount or numericCount <= 0 then
                VFW.ShowNotification({ type = 'ROUGE', content = "Ce montant n'est pas valide" })
                return
            end

            if numericCount > maxAmount then
                VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas assez d'argent sale" })
                return
            end

            local inventory, weight = TriggerServerCallback("vfw:giveMoneyType", targetServerId, "dirty_money", math.floor(numericCount))

            if inventory then
                VFW.PlayerData.inventory = inventory
                VFW.PlayerData.weight = weight
                VFW.LoadInventories()
            end
        end
    end)
end, {}, interactionsSubmenu)

--endregion

--endregion

--region ====== 9. OPTIONS (SOI-MÊME) ======

local subMenuOption = VFW.ContextAddSubmenu("ped", ":settings: Options", canShowSelfButton, {}, nil)

VFW.ContextAddButton("ped", ":eye: Masquer/Afficher HUD", canShowSelfButtonWhenAlive, function()
    hideHUD = not hideHUD
    VFW.ShowNotification({
        type = hideHUD and 'JAUNE' or 'VERT',
        content = hideHUD and "HUD masqué" or "HUD affiché"
   })
    VFW.Nui.HudVisible(not hideHUD)
end, {}, subMenuOption)

VFW.ContextAddButton("ped", ":film: Mode Cinéma", canShowSelfButtonWhenAlive, ToggleCinemaMode, {}, subMenuOption)

VFW.ContextAddButton("ped", " Annuler la démarche", canShowSelfButtonWhenAlive, function()
    ExecuteCommand("resetwalkstyle")
end, {}, subMenuOption)

-- Option "Voir mon ID" accessible même quand mort
VFW.ContextAddButton("ped", ":id: Voir mon ID", function(ped)
    return IsPedAPlayer(ped) and isSamePlayer(ped)
end, function()
    local serverId = GetPlayerServerId(PlayerId())
    local uuid = TriggerServerCallback("vfw:getPlayerUUID")

    if uuid and serverId then
        VFW.ShowNotification({
            type = 'BLEU',
            content = "UUID: " .. tostring(uuid) .. "\nID Serveur: " .. tostring(serverId)
        })
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Erreur lors de la récupération de vos informations"
       })
    end
end, {}, subMenuOption)

VFW.ContextAddButton("ped", " Sortir le skate", function(ped)
    return canShowSelfButtonWhenAlive(ped) and IsSkateOnBack
end, function(ped)
    TriggerServerEvent("skating:server:spawnSkate")
    TriggerServerEvent("skating:server:removeSkateItem")
end, {}, subMenuOption)

VFW.ContextAddButton("ped", ":chat: Faire un /me", canShowSelfButtonWhenAlive, meContextMenu, {}, subMenuOption)

--endregion

--region ====== 10. DEBUG (SOI-MÊME) ======

local subMenuDebug = VFW.ContextAddSubmenu("ped", ":wrench: Debug", canShowSelfButtonWhenAlive, {}, nil)

VFW.ContextAddButton("ped", ":monitor: Debug UI", canShowSelfButtonWhenAlive, function() ExecuteCommand('debug') end, {}, subMenuDebug)
VFW.ContextAddButton("ped", ":image: Debug Textures", canShowSelfButtonWhenAlive, function() ExecuteCommand('debugtextures') end, {}, subMenuDebug)
VFW.ContextAddButton("ped", ":refresh: Refresh Skin", canShowSelfButtonWhenAlive, refreshSkinContextMenu, {}, subMenuDebug)
VFW.ContextAddButton("ped", " Nettoyer son personnage", canShowSelfButtonWhenAlive, clearCharacterContextMenu, {}, subMenuDebug)
VFW.ContextAddButton("ped", ":trash: Détacher les objets", canShowSelfButtonWhenAlive, detachObjectContextMenu, {}, subMenuDebug)

--endregion

--region ====== 11. BOUTONS RACINE ======

-- Montrer un document à un autre joueur (seulement si proche)
local showDocSubmenu = VFW.ContextAddSubmenu("ped", ":document: Montrer un document", function(ped)
    if not IsOtherPlayer(ped) then
        return false
    end
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    if IsPedDeadOrDying(ped, true) or VFW.GetDeathCloneOwner(ped) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    return #(myCoords - targetCoords) <= 3.0
end, {}, interactionsSubmenu)

local showDocuments <const> = {
    { label = ":id: Carte d'identité", type = "identity" },
    { label = ":car: Permis de conduire", type = "driver" },
    { label = ":gun: PPA Léger", type = "weapon_leger", license = "ppa_leger" },
    { label = ":gun: PPA Lourd", type = "weapon_lourd", license = "ppa_lourd" },
    { label = ":briefcase: Carte de travail", type = "job" }
}

for i = 1, #showDocuments do
    local doc <const> = showDocuments[i]
    VFW.ContextAddButton("ped", doc.label, function(ped)
        return canInteractWithOtherPlayerWhenAlive(ped) and HasLisenseContext(doc.type)
    end, function(ped)
        local targetServerId = GetPlayerServerIdFromPed(ped)
        if targetServerId then
            TriggerServerEvent("core:identity:display", targetServerId, doc.type)
            ExecuteCommand("e idcard")

            -- Vérifier la distance et arrêter si trop loin
            CreateThread(function()
                local maxDistance = 3.0 -- 3 mètres max
                local maxDuration = 10000 -- 10 secondes max
                local startTime = GetGameTimer()

                while true do
                    Wait(500)

                    -- Timeout après 10 secondes
                    if GetGameTimer() - startTime > maxDuration then
                        ExecuteCommand("cancelemote")
                        TriggerServerEvent("vfw:identity:closeDocument", targetServerId)
                        break
                    end

                    -- Vérifier si le ped existe encore
                    if not DoesEntityExist(ped) then
                        ExecuteCommand("cancelemote")
                        TriggerServerEvent("vfw:identity:closeDocument", targetServerId)
                        break
                    end

                    -- Vérifier la distance
                    local myCoords = GetEntityCoords(PlayerPedId())
                    local targetCoords = GetEntityCoords(ped)
                    local distance = #(myCoords - targetCoords)

                    if distance > maxDistance then
                        ExecuteCommand("cancelemote")
                        TriggerServerEvent("vfw:identity:closeDocument", targetServerId)
                        VFW.ShowNotification({ type = 'ORANGE', content = "Trop éloigné, document rangé" })
                        break
                    end
                end
            end)
        end
    end, {}, showDocSubmenu)
end


--endregion

--region ====== 12. COPIER EMOTE / DÉMARCHE ======

-- Cache pour stocker temporairement l'emote du joueur ciblé
local targetEmoteCache = {}
local targetWalkCache = {}

-- Helper: Vérifie si un joueur fait une emote et retourne son nom
local function getPlayerEmote(ped)
    if not IsOtherPlayer(ped) then
        return nil
    end
    local serverId = GetPlayerServerIdFromPed(ped)
    if not serverId then
        return nil
    end

    -- Check cache first
    if targetEmoteCache[serverId] and targetEmoteCache[serverId].time > GetGameTimer() - 2000 then
        return targetEmoteCache[serverId].emote
    end

    -- Get from server
    local emoteName = TriggerServerCallback("vfw:newanim:copy", serverId)
    if emoteName then
        targetEmoteCache[serverId] = { emote = emoteName, time = GetGameTimer() }
    else
        targetEmoteCache[serverId] = nil
    end
    return emoteName
end

-- Helper: Vérifie si un joueur a une démarche personnalisée
local function getPlayerWalk(ped)
    if not IsOtherPlayer(ped) then
        return nil
    end
    local serverId = GetPlayerServerIdFromPed(ped)
    if not serverId then
        return nil
    end

    -- Check cache first
    if targetWalkCache[serverId] and targetWalkCache[serverId].time > GetGameTimer() - 2000 then
        return targetWalkCache[serverId].walk
    end

    -- Get from server
    local walkStyle = TriggerServerCallback("vfw:animation:getWalk", serverId)
    if walkStyle then
        targetWalkCache[serverId] = { walk = walkStyle, time = GetGameTimer() }
    else
        targetWalkCache[serverId] = nil
    end
    return walkStyle
end

-- Helper: Trouve les données d'animation à partir du nom de l'emote
local function getAnimationData(emoteName)
    if not emoteName then
        return nil
    end
    local name = string.lower(emoteName)

    if RP.Emotes and RP.Emotes[name] then
        return RP.Emotes[name]
    elseif RP.Dances and RP.Dances[name] then
        return RP.Dances[name]
    elseif RP.PropEmotes and RP.PropEmotes[name] then
        return RP.PropEmotes[name]
    elseif RP.ActivitesEmotes and RP.ActivitesEmotes[name] then
        return RP.ActivitesEmotes[name]
    elseif RP.GestesEmotes and RP.GestesEmotes[name] then
        return RP.GestesEmotes[name]
    elseif RP.PositionsEmotes and RP.PositionsEmotes[name] then
        return RP.PositionsEmotes[name]
    elseif RP.SportEmotes and RP.SportEmotes[name] then
        return RP.SportEmotes[name]
    elseif RP.GangEmotes and RP.GangEmotes[name] then
        return RP.GangEmotes[name]
    elseif RP.AutresEmotes and RP.AutresEmotes[name] then
        return RP.AutresEmotes[name]
    elseif RP.Vehicules and RP.Vehicules[name] then
        return RP.Vehicules[name]
    end

    return nil
end

-- Sous-menu pour copier emote/démarche
local copyAnimSubmenu = VFW.ContextAddSubmenu("ped", ":mask: Copier Animation", function(ped)
    if not IsOtherPlayer(ped) then
        return false
    end
    -- Bloquer si le joueur est mort
    if Death.isDead or (VFW.PlayerData and VFW.PlayerData.dead) then
        return false
    end
    local myCoords = GetEntityCoords(PlayerPedId())
    local targetCoords = GetEntityCoords(ped)
    if #(myCoords - targetCoords) > 10.0 then
        return false
    end
    -- Masquer si le joueur cible ne joue aucune animation
    if not getPlayerEmote(ped) then
        return false
    end
    return true
end, {}, nil)

-- Copier l'emote (normal - sans synchronisation)
VFW.ContextAddButton("ped", ":film: Copier l'emote", function(ped)
    return canInteractWithOtherPlayerWhenAlive(ped)
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if not serverId then
        return
    end

    local emoteName = getPlayerEmote(ped)
    if not emoteName then
        VFW.ShowNotification({ type = 'ROUGE', content = "Ce joueur ne fait aucune animation" })
        return
    end

    -- Vérifier que la fonction existe
    if not EmoteCommandStart then
        VFW.ShowNotification({ type = 'ROUGE', content = "Système d'emotes non disponible" })
        return
    end

    -- Jouer l'emote normalement
    local success = pcall(function()
        EmoteCommandStart(emoteName, VFW.PlayerData.ped, false)
        TriggerServerEvent("vfw:newanim:sync", emoteName)
    end)

    if success then
        VFW.ShowNotification({ type = 'VERT', content = "Emote copiée" })
    else
        VFW.ShowNotification({ type = 'ROUGE', content = "Erreur lors de la copie de l'emote" })
    end
end, {}, copyAnimSubmenu)

-- Copier l'emote (synchronisé - phase-lock via horloge serveur)
-- Le flag PendingPhaseInherit est lu dans PlayAnimation: la nouvelle emote
-- hérite du startedAt du joueur cible côté serveur, donc TOUS les clients
-- (et pas seulement nous deux) voient les deux peds locked sur la même phase.
VFW.ContextAddButton("ped", ":refresh: Copier l'emote (synchro)", function(ped)
    return canInteractWithOtherPlayerWhenAlive(ped)
end, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if not serverId then
        return
    end

    local emoteName = getPlayerEmote(ped)
    if not emoteName then
        VFW.ShowNotification({ type = 'ROUGE', content = "Ce joueur ne fait aucune animation" })
        return
    end

    if not EmoteCommandStart then
        VFW.ShowNotification({ type = 'ROUGE', content = "Système d'emotes non disponible" })
        return
    end

    local animData = getAnimationData(emoteName)
    local isScenario = animData and animData[1] == "Scenario"

   -- Scenarios n'ont pas de timeline animable, mais on copie quand même.
    -- Pour les vraies animations, on arme le flag d'héritage avant EmoteCommandStart.
    if not isScenario then
        PendingPhaseInherit = serverId
    end

    local success = pcall(function()
        EmoteCommandStart(emoteName, VFW.PlayerData.ped, false)
        TriggerServerEvent("vfw:newanim:sync", emoteName)
    end)

    if not success then
        PendingPhaseInherit = nil
        VFW.ShowNotification({ type = 'ROUGE', content = "Erreur lors de la copie de l'emote" })
        return
    end

    if isScenario then
        VFW.ShowNotification({ type = 'JAUNE', content = "Emote copiée (scénario - pas de synchro)" })
    else
        VFW.ShowNotification({ type = 'VERT', content = "Emote synchronisée" })
    end
end, {}, copyAnimSubmenu)

-- Copier la démarche
VFW.ContextAddButton("ped", " Copier la démarche", function(ped)
    return canInteractWithOtherPlayerWhenAlive(ped)
end, function(ped)
    local walkStyle = getPlayerWalk(ped)
    if not walkStyle then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette personne n'a pas de démarche personnalisée" })
        return
    end

    ExecuteCommand("setwalkstyle " .. walkStyle)
end, {}, copyAnimSubmenu)

--endregion

-- Copier l'ID d'un autre joueur (accessible à tous, même quand mort) - en bas du menu
VFW.ContextAddButton("ped", ":report: Copier l'ID", canCopyOtherPlayerId, function(ped)
    local serverId = GetPlayerServerIdFromPed(ped)
    if serverId then
        VFW.Clipboard(tostring(serverId))
        VFW.ShowNotification({ type = 'VERT', content = "ID copié: " .. serverId })
    else
        VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de récupérer l'ID" })
    end
end, {})

--endregion




--region ====== EVENTS CLIENT ======

RegisterNetEvent("vfw:ped:apply", function(action, netId, extra)
    local ped = NetworkGetEntityFromNetworkId(netId)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return
    end

    -- Sécurité: Vérifier que c'est bien notre ped
    if ped ~= PlayerPedId() then
        return
    end

    if action == "ped:calm" then
        ClearPlayerWantedLevel(PlayerId())
        SetPlayerWantedLevel(PlayerId(), 0, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
        SetMaxWantedLevel(0)
        Wait(100)
        SetMaxWantedLevel(5)

        local pedPos = GetEntityCoords(ped)
        local nearbyPeds = GetGamePool('CPed')
        for _, npc in ipairs(nearbyPeds) do
            if DoesEntityExist(npc) and not IsPedAPlayer(npc) then
                local npcPos = GetEntityCoords(npc)
                if #(pedPos - npcPos) < 50.0 then
                    SetPedFleeAttributes(npc, 0, false)
                    SetPedCombatAttributes(npc, 17, true)
                    TaskSetBlockingOfNonTemporaryEvents(npc, false)
                    ClearPedTasks(npc)
                end
            end
        end
        VFW.ShowNotification({ type = 'VERT', content = "Vous avez été apaisé" })

    elseif action == "ped:changeOutfit" then
        if VFW.OpenClothingMenu then
            VFW.OpenClothingMenu()
        else
            VFW.ShowNotification({ type = 'ORANGE', content = "Menu de tenue non disponible" })
        end

    elseif action == "ped:flee" then
        TaskReactAndFleePed(ped, VFW.PlayerData.ped)
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous prenez la fuite !" })

    elseif action == "ped:setInvincible" then
        local invincible = (extra and extra.invincible) or false
        SetEntityInvincible(ped, invincible)
        VFW.ShowNotification({
            type = invincible and 'VERT' or 'ORANGE',
            content = invincible and "Vous êtes invincible" or "Invincibilité désactivée"
       })

    elseif action == "ped:setFrozen" then
        local frozen = (extra and extra.frozen) or false
        FreezeEntityPosition(ped, frozen)
        VFW.ShowNotification({
            type = frozen and 'ROUGE' or 'VERT',
            content = frozen and "Vous êtes immobilisé" or "Vous pouvez bouger à nouveau"
       })

    elseif action == "ped:playAnim" then
        local dict = (extra and extra.dict) or ""
       local anim = (extra and extra.anim) or ""
       local flag = (extra and extra.flag) or 0

        if dict ~= "" and anim ~= "" then
            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Wait(10)
            end
            TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, flag, 0, false, false, false)

            Citizen.CreateThread(function()
                while IsEntityPlayingAnim(ped, dict, anim, 3) do
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_VEH_DUCK~ pour annuler")
                    if IsControlJustPressed(0, 73) then -- X key
                        ClearPedTasks(ped)
                        break
                    end
                    Wait(0)
                end
            end)
        end

    elseif action == "ped:tackleDown" then
        local dict = (extra and extra.dict) or ""
       local anim = (extra and extra.anim) or ""
       local flag = (extra and extra.flag) or 0

        if dict ~= "" and anim ~= "" then
            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Wait(10)
            end
            TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, flag, 0, false, false, false)

            Citizen.CreateThread(function()
                while IsEntityPlayingAnim(ped, dict, anim, 3) do
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vous relever")
                    if VFW.Interact.JustPressed(0, 38) then -- E key
                        ClearPedTasks(ped)
                        break
                    end
                    Wait(0)
                end
            end)
        end

    elseif action == "ped:stopAnim" then
        ClearPedTasks(ped)
        VFW.ShowNotification({ type = 'VERT', content = "Animation arrêtée" })
    end
end)

--endregion

--region ====== DVM LICENSE CACHE INVALIDATION ======

-- Invalider le cache DVM quand les licences sont rechargées
RegisterNetEvent("vfw:license:load", function()
    dvmLicensesCache = nil
end)

-- Invalider le cache DVM quand le joueur est prêt
RegisterNetEvent("vfw:playerReady", function()
    dvmLicensesCache = nil
end)

--endregion
