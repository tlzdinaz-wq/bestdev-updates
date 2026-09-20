if not AntiAttachConfig then return end

local CFG = AntiAttachConfig
if not CFG.enabled then return end

-- ─── Lookup des modèles blacklistés (normalisé signed/unsigned) ─────────────
local blacklisted = {}
for _, hash in ipairs(CFG.blacklistedModels or {}) do
    local h = math.floor(hash)
    blacklisted[h] = true
    if h < 0 then
        blacklisted[h + 0x100000000] = true
    elseif h > 0x7FFFFFFF then
        blacklisted[h - 0x100000000] = true
    end
end

local function isBlacklistedModel(model)
    if not model then return false end
    return blacklisted[model] == true
end

-- ─── Anti-spam des reports (par objet / netId) ──────────────────────────────
local reportCooldowns = {}

-- IMPORTANT : on N'identifie PAS l'attaquant côté client. Quand le cheater
-- attache son objet à un joueur, la propriété réseau de l'objet MIGRE vers le
-- ped cible (l'entité attachée suit le owner de son parent) → NetworkGetEntityOwner
-- renverrait la VICTIME, pas le cheater. On envoie donc juste le netId de l'objet
-- + le serverId de la victime (le ped attaché). Le serveur résout le vrai
-- attaquant via NetworkGetFirstEntityOwner (premier propriétaire = créateur réel).
local function reportAttach(object, victimServerId)
    if not CFG.reportAttacker then return end
    if not victimServerId or victimServerId <= 0 then return end
    if not NetworkGetEntityIsNetworked(object) then return end

    local netId = NetworkGetNetworkIdFromEntity(object)
    if not netId or netId == 0 then return end

    local now = GetGameTimer()
    if reportCooldowns[netId] and now < reportCooldowns[netId] then return end
    reportCooldowns[netId] = now + (CFG.reportCooldownMs or 4000)

    TriggerServerEvent('eve:antiAttach:report', netId, victimServerId)
end

-- ─── Suppression de l'objet (best-effort, nécessite le contrôle réseau) ─────
local function destroyObject(object)
    if not CFG.deleteObject then return end
    if not DoesEntityExist(object) then return end

    CreateThread(function()
        local waited = 0
        while not NetworkHasControlOfEntity(object) and waited < 300 do
            NetworkRequestControlOfEntity(object)
            Wait(15)
            waited = waited + 15
        end
        if DoesEntityExist(object) then
            SetEntityAsMissionEntity(object, true, true)
            DeleteEntity(object)
        end
    end)
end

-- ─── Protection de la victime : détache + annule la propulsion ──────────────
local function protectSelf(myPed)
    if not CFG.detachSelf then return end
    if IsEntityAttached(myPed) then
        DetachEntity(myPed, true, true)
    end
    -- Annule la vélocité accumulée par l'attache pour empêcher tout "launch"
    -- résiduel qui déclencherait l'AC mouvement.
    SetEntityVelocity(myPed, 0.0, 0.0, 0.0)
end

-- ─── L'objet est-il attaché à un ped JOUEUR ? ───────────────────────────────
-- Renvoie (pedCible, serverIdVictime) si oui, sinon (nil, nil). Un parachute
-- attaché à un ped joueur n'est jamais légitime → aucun faux positif.
local function getAttachedPlayer(obj)
    local attachedTo = GetEntityAttachedTo(obj)
    if not attachedTo or attachedTo == 0 or GetEntityType(attachedTo) ~= 1 then
        return nil, nil
    end
    if GetPedParachuteState(attachedTo) ~= -1 then
        return nil, nil
    end
    for _, pid in ipairs(GetActivePlayers()) do
        if GetPlayerPed(pid) == attachedTo then
            return attachedTo, GetPlayerServerId(pid)
        end
    end
    return nil, nil
end

-- ─── Vérifie si un objet blacklisté est attaché à un ped joueur ─────────────
-- Renvoie true (+ agit) si malveillant : protège la victime, report, delete.
local function inspectAndHandle(obj, myPed)
    if not obj or obj == 0 or not DoesEntityExist(obj) then return false end
    if not isBlacklistedModel(GetEntityModel(obj)) then return false end

    local targetPed, victimServerId = getAttachedPlayer(obj)
    if not targetPed then return false end

    if targetPed == myPed then
        protectSelf(myPed)
    end
    reportAttach(obj, victimServerId)
    destroyObject(obj)
    return true
end

-- ─── Surveillance rapprochée d'un objet fraîchement créé ────────────────────
-- entityCreated se déclenche à l'instant où l'objet parachute stream chez la
-- victime, AVANT que le cheater ne l'attache (l'attache se fait 1+ frame plus
-- tard). On surveille donc cet objet précis frame par frame sur une courte
-- fenêtre pour intercepter l'attache à l'instant exact où elle se produit —
-- bien plus réactif que le polling global.
--
-- ANTI-DoS : un cheater peut spammer des milliers d'objets blacklistés. On
-- borne donc le nombre de surveillances simultanées (CFG.maxWatchers). Au-delà,
-- le filet de sécurité (polling global) prend le relais : on ne lance jamais
-- des milliers de threads par-frame qui freezeraient la victime.
local watched = {}
local activeWatchers = 0

local function watchObject(obj)
    if watched[obj] then return end

    local maxWatchers = math.max(1, CFG.maxWatchers or 16)
    if activeWatchers >= maxWatchers then return end

    watched[obj] = true
    activeWatchers = activeWatchers + 1

    CreateThread(function()
        local elapsed = 0
        local duration = math.max(500, CFG.watchDurationMs or 3000)
        local reported = false

        while DoesEntityExist(obj) and elapsed < duration do
            local myPed = PlayerPedId()
            local malicious = false
            local victimServerId = nil

            -- Cas A : NOTRE ped est attaché à cet objet (on est la victime).
            if myPed ~= 0 and GetEntityAttachedTo(myPed) == obj and GetPedParachuteState(myPed) == -1 then
                protectSelf(myPed)  -- détache chaque frame tant que l'attache persiste
                malicious = true
                victimServerId = GetPlayerServerId(PlayerId())
            end

            -- Cas B : l'objet est attaché à un ped joueur (autre victime / nous).
            local _, vSrv = getAttachedPlayer(obj)
            if vSrv then
                malicious = true
                victimServerId = victimServerId or vSrv
            end

            -- Report + suppression une seule fois (cooldown couvre le reste),
            -- mais on continue de détacher chaque frame jusqu'à disparition.
            if malicious and not reported then
                reported = true
                reportAttach(obj, victimServerId)
                destroyObject(obj)
            end

            Wait(0)  -- chaque frame, pour intercepter l'attache à l'instant T
            elapsed = elapsed + math.floor(GetFrameTime() * 1000) + 1
        end

        watched[obj] = nil
        activeWatchers = activeWatchers - 1
    end)
end

-- Hook création d'entité : signal le plus précoce possible côté victime pour
-- un objet réseau streamé depuis le client du cheater.
AddEventHandler('entityCreated', function(entity)
    if not entity or entity == 0 then return end
    if GetEntityType(entity) ~= 3 then return end -- objets uniquement
    if not isBlacklistedModel(GetEntityModel(entity)) then return end
    watchObject(entity)
end)

-- ─── Filet de sécurité 1 : AUTO-PROTECTION (fréquent, quasi-gratuit) ─────────
-- Sur un serveur chargé, ceci tourne en permanence sur chaque client : on le
-- garde donc minimal (≈4 natives, aucune itération de pool). Ne protège QUE ce
-- client (le cas réellement critique : éviter le faux ban mouvement).
CreateThread(function()
    Wait(2000)
    local interval = math.max(100, CFG.selfCheckIntervalMs or 200)

    while true do
        local myPed = PlayerPedId()
        if myPed and myPed ~= 0 and IsEntityAttached(myPed) then
            local parent = GetEntityAttachedTo(myPed)
            if parent and parent ~= 0 and DoesEntityExist(parent)
                and GetEntityType(parent) == 3
                and isBlacklistedModel(GetEntityModel(parent))
                and GetPedParachuteState(myPed) == -1 then
                protectSelf(myPed)
                reportAttach(parent, GetPlayerServerId(PlayerId()))
                destroyObject(parent)
            end
        end
        Wait(interval)
    end
end)

-- ─── Filet de sécurité 2 : balayage du pool (espacé, coûteux) ───────────────
-- Couvre : objets présents avant le start du script, objets dont entityCreated
-- n'aurait pas fired (selon le build), ou attache survenue après la fenêtre de
-- surveillance rapprochée. `entityCreated` étant le mécanisme principal, ce
-- balayage complet est espacé (poolScanIntervalMs) pour ne pas peser en continu.
CreateThread(function()
    Wait(3000)
    local interval = math.max(500, CFG.poolScanIntervalMs or 2000)

    while true do
        local myPed = PlayerPedId()
        local objects = GetGamePool('CObject')
        for i = 1, #objects do
            inspectAndHandle(objects[i], myPed)
        end
        Wait(interval)
    end
end)
