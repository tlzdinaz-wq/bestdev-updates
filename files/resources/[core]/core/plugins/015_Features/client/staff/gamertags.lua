---@meta _
---@diagnostic disable: duplicate-doc-field

local gamerTags = {}         -- PED -> tag handle
local gamerTagsData = {}     -- PED -> { displayText, crew }
local pendingRecreate = {}   -- PED -> timestamp (delay between remove & create)
local pendingPlayers = {}
local datas = {}
local gamerTagActive = false
local hiddenPlayers  = {}

-- Preview system for color picker
local previewColor = nil
local previewPlayerId = nil

local RECREATE_DELAY = 500 -- ms to wait after RemoveMpGamerTag before creating a new one
local PENDING_REQUEST_TIMEOUT = 3000 -- ms before re-requesting player data when no response
local BULK_CLEAR_COOLDOWN = 500 -- ms to wait after a bulk clear before creating new tags

-- CreateFakeMpGamerTag est conçu pour les peds humanoïdes (mp_freemode, humains).
-- Sur un ped animal (a_c_*) ou non-humanoïde, la native crash le renderer interne
-- de GTA quand le tag tente de s'attacher au squelette. Cache les modèles déjà
-- vérifiés pour éviter de re-requêter GetEntityModel chaque tick.
-- Cache uniquement les résultats positifs: IsPedHuman peut renvoyer false
-- transitoirement sur un ped fraichement streamé (mp_freemode_*) avant que
-- ses composants soient chargés. Cacher un false bloquerait à vie tous les
-- joueurs partageant ce hash de modèle.
local humanoidModelCache = {}
local function isHumanoidPed(ped)
    if not ped or ped == 0 then return false end
    local model = GetEntityModel(ped)
    if humanoidModelCache[model] then
        return true
    end
    if IsPedHuman(ped) then
        humanoidModelCache[model] = true
        return true
    end
    return false
end

-- Timestamp en ms (GetGameTimer) jusqu'auquel CreateFakeMpGamerTag est bloqué
-- après un bulk-remove. Le moteur GTA traite RemoveMpGamerTag en async; créer
-- de nouveaux tags juste après échoue silencieusement (retour 0) et laisse
-- les gamertags absents jusqu'à un re-toggle staff (symptôme observé après /goto).
local bulkClearCooldownUntil = 0

--- hexToDecimal - Convert hex color to decimal
---@param hex string Hex color string (e.g., "#FF5733" or "FF5733")
---@return number|nil Decimal color value
local function hexToDecimal(hex)
    if not hex or type(hex) ~= "string" then
        return nil
    end

    hex = hex:gsub("#", "")

    if not hex:match("^%x%x%x%x%x%x$") then
        return nil
    end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)

    if r and g and b then
        return r * 65536 + g * 256 + b
    end

    return nil
end

--- Centralized tag removal: removes the native tag and schedules delayed recreation.
--- ALL code that needs to remove a gamertag MUST go through this function.
---@param ped number The PED entity handle
local function removeTag(ped)
    if gamerTags[ped] then
        RemoveMpGamerTag(gamerTags[ped])
        gamerTags[ped] = nil
    end
    gamerTagsData[ped] = nil
    pendingRecreate[ped] = GetGameTimer()
end

--- Remove all gamertags and schedule delayed recreation for each.
local function removeAllTags()
    for ped, _ in pairs(gamerTags) do
        removeTag(ped)
    end
end

--- Clear all gamertags after a TP / pause menu / bucket switch.
--- Le moteur traite RemoveMpGamerTag en async — sans cooldown global,
--- les CreateFakeMpGamerTag immédiats suivants retournent 0 et les tags
--- n'apparaissent plus jamais (le symptôme "/goto désactive les gamertags").
local function clearAllTagsImmediate()
    for ped, _ in pairs(gamerTags) do
        RemoveMpGamerTag(gamerTags[ped])
    end
    gamerTags = {}
    gamerTagsData = {}
    pendingRecreate = {}
    bulkClearCooldownUntil = GetGameTimer() + BULK_CLEAR_COOLDOWN
end

---@param ADMIN_KEY any
---@param ADMIN_DATA table
RegisterNetEvent("Admin:updateValue", function(ADMIN_KEY, ADMIN_DATA)
    local key = tonumber(ADMIN_KEY) or ADMIN_KEY
    datas[key] = ADMIN_DATA
    pendingPlayers[key] = nil
    hiddenPlayers[key] = nil

    -- Color changes are applied every tick, text/crew changes are detected via needsRecreate.
    -- No tag removal needed here.
end)

---@param ADMIN_KEY any
RegisterNetEvent("Admin:removeValue", function(ADMIN_KEY)
    local key = tonumber(ADMIN_KEY) or ADMIN_KEY
    datas[key] = nil
    pendingPlayers[key] = nil
    hiddenPlayers[key] = true

    for ped, _ in pairs(gamerTags) do
        local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
        if serverId == key then
            -- No recreation needed for removed players, just clean up
            RemoveMpGamerTag(gamerTags[ped])
            gamerTags[ped] = nil
            gamerTagsData[ped] = nil
            pendingRecreate[ped] = nil
            break
        end
    end
end)

---@param BOOLEAN any
RegisterNetEvent("Admin:gamerTag", function(BOOLEAN)
    gamerTagActive = BOOLEAN
    if gamerTagActive then
        CreateThread(function()
            local lastKnownPeds = {}
            local wasPauseMenuActive = false
            local lastSelfCoords = GetEntityCoords(PlayerPedId(), false)
            -- Seuil de "déplacement brutal" entre 2 ticks (TP, noclip rapide).
            -- Au-dessus, on force un removeAllTags() pour relancer la création
            -- propre — sinon les peds re-streamés gardent un handle stale.
            local FAST_MOVE_THRESHOLD = 50.0

            while gamerTagActive do
                local myPed = PlayerPedId()
                local activePlayers = GetActivePlayers()

                -- Détection TP / noclip rapide : les handles côté Lua deviennent
                -- stale après re-streaming des peds. Pas de RECREATE_DELAY car les
                -- handles ne sont plus valides — Remove est un no-op donc aucune
                -- race condition GTA possible. Recréation immédiate au tick suivant.
                local myCoords = GetEntityCoords(myPed, false)
                if #(myCoords - lastSelfCoords) > FAST_MOVE_THRESHOLD then
                    clearAllTagsImmediate()
                    lastKnownPeds = {}
                end
                lastSelfCoords = myCoords

                -- Pause menu : l'engine détruit les gamertags en interne. Nos
                -- handles sont stale — pas de RECREATE_DELAY nécessaire.
                local isPauseMenuActive = IsPauseMenuActive()
                if wasPauseMenuActive and not isPauseMenuActive then
                    clearAllTagsImmediate()
                end
                wasPauseMenuActive = isPauseMenuActive

                if isPauseMenuActive then
                    Wait(100)
                    goto continue_main_loop
                end

                for i = 1, #activePlayers do
                    local playerId = activePlayers[i]
                    local playerPed = GetPlayerPed(playerId)
                    local playerServerId = GetPlayerServerId(playerId)

                    -- Skip handles invalides (ped en cours de streaming / recyclé par
                    -- l'engine après destream rapide en noclip). Sans ce guard, les
                    -- natives suivantes (CreateFakeMpGamerTag, SetMpGamerTag*) opèrent
                    -- sur un handle fantôme et crashent le moteur de rendu des tags.
                    if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) then
                        goto continue_player_loop
                    end

                    -- PED changed (respawn, model change) -> remove old tag
                    local oldPed = lastKnownPeds[playerServerId]
                    if oldPed and oldPed ~= playerPed then
                        if gamerTags[oldPed] then
                            RemoveMpGamerTag(gamerTags[oldPed])
                            gamerTags[oldPed] = nil
                            gamerTagsData[oldPed] = nil
                            pendingRecreate[oldPed] = nil -- old PED is gone, no recreation
                        end
                    end
                    lastKnownPeds[playerServerId] = playerPed

                    -- Entity no longer exists -> clean up
                    if gamerTags[playerPed] and not DoesEntityExist(playerPed) then
                        RemoveMpGamerTag(gamerTags[playerPed])
                        gamerTags[playerPed] = nil
                        gamerTagsData[playerPed] = nil
                        pendingRecreate[playerPed] = nil
                    end

                    -- Skip non-humanoid peds (animal, zombie, alien, etc. via menu staff)
                    -- CreateFakeMpGamerTag et SetMpGamerTag* crashent sur ces modèles.
                    if not isHumanoidPed(playerPed) then
                        if gamerTags[playerPed] then
                            RemoveMpGamerTag(gamerTags[playerPed])
                            gamerTags[playerPed] = nil
                            gamerTagsData[playerPed] = nil
                            pendingRecreate[playerPed] = nil
                        end
                        goto continue_player_loop
                    end

                    local dist = #(GetEntityCoords(myPed, false) - GetEntityCoords(playerPed, false))
                    if dist < 5000.0 then
                        local playerData = datas[playerServerId]

                        if not playerData and not hiddenPlayers[playerServerId] then
                            local pending = pendingPlayers[playerServerId]
                            -- pendingPlayers stocke un timestamp pour pouvoir retry en cas
                            -- de réponse perdue (typiquement après /goto où le serveur
                            -- peut ne jamais répondre si VFW.GamerTags[id] est manquant).
                            if not pending or (GetGameTimer() - pending) > PENDING_REQUEST_TIMEOUT then
                                pendingPlayers[playerServerId] = GetGameTimer()
                                TriggerServerEvent("Admin:requestPlayerData", playerServerId)
                            end
                        end

                        if type(playerData) == "table" and not hiddenPlayers[playerServerId] then
                            local tag = tostring(playerData["NAME"])
                            if StaffMenu.showRPNamesOnPlayerTags then
                                tag = tostring(playerData["RP_NAME"])
                            end

                            local rawCrew = playerData["CREW"] and tostring(playerData["CREW"]) or ""
                          local playerCrew = (rawCrew == "" or rawCrew:lower() == "nocrew") and "" or rawCrew
                            if playerCrew ~= "" and #playerCrew > 10 then
                                playerCrew = playerCrew:sub(1, 7) .. "..."
                          end

                            local displayText = string.format('UUID: %s | %s | ID: %s',
                                tostring(playerData["UUID"] or playerData["ID"] or "Unknown"),
                                tag,
                                tostring(playerData["SOURCE_ID"] or playerServerId)
                            )

                            -- Check if tag needs to be recreated (data changed or doesn't exist).
                            -- On compare aussi le serverId: les ped handles GTA peuvent être
                            -- recyclés entre joueurs (un ped destreamé puis un autre joueur
                            -- streamé qui hérite du même handle), ce qui faisait que le tag
                            -- de l'ancien joueur s'appliquait au nouveau (couleurs qui
                            -- "s'échangent" en noclip après approche).
                            local currentData = gamerTagsData[playerPed]
                            local needsRecreate = not gamerTags[playerPed]
                                or not currentData
                                or currentData.serverId ~= playerServerId
                                or currentData.displayText ~= displayText
                                or currentData.crew ~= playerCrew

                            if needsRecreate then
                                -- If tag exists, remove it and schedule delayed recreation
                                if gamerTags[playerPed] then
                                    removeTag(playerPed)
                                    goto continue_player
                                end

                                -- If waiting for delay after removal, skip creation
                                if pendingRecreate[playerPed] then
                                    if GetGameTimer() - pendingRecreate[playerPed] < RECREATE_DELAY then
                                        goto continue_player
                                    end
                                    pendingRecreate[playerPed] = nil
                                end

                                -- Cooldown global après un bulk clear (cf. clearAllTagsImmediate)
                                if GetGameTimer() < bulkClearCooldownUntil then
                                    goto continue_player
                                end

                                -- Create new tag
                                local newTag = CreateFakeMpGamerTag(playerPed, displayText, false, false, playerCrew, 0, 0, 0, 0)
                                if newTag and newTag ~= 0 then
                                    gamerTags[playerPed] = newTag
                                    gamerTagsData[playerPed] = {
                                        displayText = displayText,
                                        crew = playerCrew,
                                        serverId = playerServerId
                                    }
                                end
                            end

                            if not gamerTags[playerPed] then
                                goto continue_player
                            end

                            -- Apply visibility & alpha
                            SetMpGamerTagAlpha(gamerTags[playerPed], 0, 255)
                            SetMpGamerTagAlpha(gamerTags[playerPed], 2, 255)
                            SetMpGamerTagAlpha(gamerTags[playerPed], 4, 255)
                            SetMpGamerTagVisibility(gamerTags[playerPed], 0, true)
                            SetMpGamerTagVisibility(gamerTags[playerPed], 2, true)


                            SetMpGamerTagVisibility(gamerTags[playerPed], 4, NetworkIsPlayerTalking(playerId))

                            local hasCrew = playerCrew ~= ""
                          SetMpGamerTagVisibility(gamerTags[playerPed], 1, hasCrew)
                            SetMpGamerTagAlpha(gamerTags[playerPed], 1, hasCrew and 255 or 0)

                            if playerData["NEW"] then
                                SetMpGamerTagVisibility(gamerTags[playerPed], 6, true)
                                SetMpGamerTagAlpha(gamerTags[playerPed], 6, 255)
                            else
                                SetMpGamerTagVisibility(gamerTags[playerPed], 6, false)
                                SetMpGamerTagAlpha(gamerTags[playerPed], 6, 0)
                            end

                            if playerData["IS_GAMERTAG"] then
                                SetMpGamerTagVisibility(gamerTags[playerPed], 14, true)
                                SetMpGamerTagAlpha(gamerTags[playerPed], 14, 255)
                            else
                                SetMpGamerTagVisibility(gamerTags[playerPed], 14, false)
                                SetMpGamerTagAlpha(gamerTags[playerPed], 14, 0)
                            end

                            if playerData["PREMIUM"] then
                                SetMpGamerTagVisibility(gamerTags[playerPed], 7, true)
                                SetMpGamerTagAlpha(gamerTags[playerPed], 7, 255)
                                if playerData["PREMIUM_COLOR"] then
                                    local pColorValue = tonumber(playerData["PREMIUM_COLOR"])
                                    if not pColorValue then
                                        pColorValue = hexToDecimal(playerData["PREMIUM_COLOR"])
                                    end
                                    if pColorValue then
                                        SetMpGamerTagColour(gamerTags[playerPed], 7, VFW.DecimalColorToHUDColor(pColorValue).id)
                                    end
                                end
                            else
                                SetMpGamerTagVisibility(gamerTags[playerPed], 7, false)
                                SetMpGamerTagAlpha(gamerTags[playerPed], 7, 0)
                            end

                            if playerData["STAFF_DUTY"] or playerData["ANIMATOR_DUTY"] then
                                SetMpGamerTagVisibility(gamerTags[playerPed], 9, true)
                                SetMpGamerTagAlpha(gamerTags[playerPed], 9, 255)
                                if playerData["STAFF_DUTY"] then
                                    SetMpGamerTagColour(gamerTags[playerPed], 9, VFW.DecimalColorToHUDColor(39423).id)
                                else
                                    SetMpGamerTagColour(gamerTags[playerPed], 9, VFW.DecimalColorToHUDColor(16766720).id)
                                end
                            else
                                SetMpGamerTagVisibility(gamerTags[playerPed], 9, false)
                                SetMpGamerTagAlpha(gamerTags[playerPed], 9, 0)
                            end

                            ::continue_player::
                        end

                        -- Apply color every tick (outside needsRecreate block).
                        -- La garde sur serverId évite d'écrire une couleur sur un tag dont le
                        -- ped handle vient d'être réassigné à un autre joueur (cas rare où
                        -- needsRecreate ne s'est pas encore déclenché sur ce tick).
                        local cachedData = gamerTagsData[playerPed]
                        if playerData ~= nil and gamerTags[playerPed]
                            and cachedData and cachedData.serverId == playerServerId then
                            if NetworkIsPlayerTalking(playerId) then
                                SetMpGamerTagColour(gamerTags[playerPed], 0, 18)
                            elseif previewColor and previewPlayerId == playerServerId then
                                SetMpGamerTagColour(gamerTags[playerPed], 0, previewColor)
                            elseif playerData["COLOR"] then
                                local colorValue = tonumber(playerData["COLOR"])
                                if not colorValue then
                                    colorValue = hexToDecimal(playerData["COLOR"])
                                end
                                if colorValue then
                                    SetMpGamerTagColour(gamerTags[playerPed], 0, VFW.DecimalColorToHUDColor(colorValue).id)
                                else
                                    SetMpGamerTagColour(gamerTags[playerPed], 0, 0)
                                end
                            else
                                SetMpGamerTagColour(gamerTags[playerPed], 0, 0)
                            end
                        end
                    else
                        -- Out of range, remove tag permanently (no recreation)
                        if gamerTags[playerPed] then
                            RemoveMpGamerTag(gamerTags[playerPed])
                            gamerTags[playerPed] = nil
                            gamerTagsData[playerPed] = nil
                            pendingRecreate[playerPed] = nil
                        end
                    end
                    ::continue_player_loop::
                end

                ::continue_main_loop::
                Wait(25)
            end

            -- Cleanup on disable
            for ped, tag in pairs(gamerTags) do
                RemoveMpGamerTag(tag)
            end
            gamerTags = {}
            gamerTagsData = {}
            pendingRecreate = {}
            hiddenPlayers = {}
            lastKnownPeds = {}
        end)
    else
        hiddenPlayers = {}
        datas = {}
        pendingPlayers = {}
        pendingRecreate = {}
    end
end)

VFW.GetTagColorFromPlayerServerId = function(playerServerId)
    local playerData = datas[playerServerId]
    if not playerData or not playerData["COLOR"] then
        return 0
    end

    local colorValue = tonumber(playerData["COLOR"])
    if not colorValue then
        colorValue = hexToDecimal(playerData["COLOR"])
    end

    if colorValue then
        local hudColor = VFW.DecimalColorToHUDColor(colorValue)
        return hudColor and hudColor.id or 0
    end

    return 0
end

--- Remove all gamertags and let the main loop recreate them with proper delay.
--- Used by nametag toggle and other features that need a full refresh.
function VFW.UpdateAllGamerTags()
    removeAllTags()
end

--- Refresh all gamertags (clear data and let them recreate)
RegisterNetEvent("Admin:refreshGamerTags", function()
    datas = {}
    pendingPlayers = {}
    removeAllTags()
end)

---@return boolean
function VFW.IsGamerTagsActive()
    return gamerTagActive
end

--- Preview a gamertag color change for a specific player (local only)
---@param playerServerId number
---@param hexColor string
function VFW.PreviewGamerTagColor(playerServerId, hexColor)
    if not hexColor or type(hexColor) ~= "string" then
        return
    end

    local colorValue = hexToDecimal(hexColor)
    if not colorValue then
        return
    end

    local hudColor = VFW.DecimalColorToHUDColor(colorValue)
    if hudColor then
        previewColor = hudColor.id
        previewPlayerId = playerServerId
    end
end

--- Clear the gamertag color preview
function VFW.ClearGamerTagPreview()
    previewColor = nil
    previewPlayerId = nil
end