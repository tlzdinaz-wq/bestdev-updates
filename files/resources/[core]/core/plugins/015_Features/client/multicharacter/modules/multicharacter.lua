---@meta _
---@diagnostic disable: duplicate-doc-field

---@class Multicharacter
---@field _index any
---@field Characters table
---@field hidePlayers boolean
---@field inSelection boolean
Multicharacter = {}
Multicharacter._index = Multicharacter
Multicharacter.Characters = {}
Multicharacter.hidePlayers = false
Multicharacter.inSelection = false

CreateThread(function()
    while true do
        if Multicharacter.inSelection then
            DisableControlAction(0, 200, true) -- ESC / Pause menu
            DisableControlAction(0, 199, true) -- P / Pause menu
            Wait(0)
        else
            Wait(500)
        end
    end
end)

function Multicharacter:AwaitFadeIn()
    while IsScreenFadingIn() do
        Wait(200)
    end
end

function Multicharacter:AwaitFadeOut()
    while IsScreenFadingOut() do
        Wait(200)
    end
end

local HiddenCompents = {}

--- HideComponents
---@param hide number|string
local function HideComponents(hide)
    local components = {11, 12, 21}

    for i = 1, #components do
        if hide then
            local size = GetHudComponentSize(components[i])

            if size.x > 0 or size.y > 0 then
                HiddenCompents[components[i]] = size
                SetHudComponentSize(components[i], 0.0, 0.0)
            end
        else
            if HiddenCompents[components[i]] then
                local size = HiddenCompents[components[i]]

                SetHudComponentSize(components[i], size.x, size.y)
                HiddenCompents[components[i]] = nil
            end
        end
    end
    
    VFW.Nui.HudVisible(not hide)
end

function Multicharacter:HideHud(hide)
    self.hidePlayers = hide

    if hide then
        MumbleSetVolumeOverride(VFW.playerId, 0.0)
    else
        MumbleSetVolumeOverride(VFW.playerId, -1.0)
    end
    HideComponents(hide)
    TriggerEvent('pma-voice:toggleUi', not hide)
end

function Multicharacter:SetupCharacters()
    if self._settingUp then return end
    self._settingUp = true

    VFW.PlayerLoaded = false
    VFW.PlayerData = {}

    self.spawned = false
    self.playerPed = PlayerPedId()
    self.sceneReady = false
    self.spawnCoords = nil
    self.sceneCam = nil

    local randomIndex = VFW.Math.Random(1, #Config.Multicharacter.Spawn)
    local selectedSpawn = Config.Multicharacter.Spawn[randomIndex]
    self.cameras = selectedSpawn
    -- Les scènes actuelles n’ont plus de COH : la position du clone
    -- est calculée dans SetupScene() à partir de la caméra.

    self:HideHud(true)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    -- Nettoyer les KVP de l'arme dans le dos pour éviter la persistance entre personnages
    DeleteResourceKvp("vfw:weapon_on_back:name")
    DeleteResourceKvp("vfw:weapon_on_back:unique_id")

    TriggerServerEvent("vfw:multicharacter:SetupCharacters")
end

function Multicharacter:GetSkin()
    local character = self.Characters[self.tempIndex]
    local skin = character and character.skin or nil
    if type(skin) ~= "table" or skin.sex == nil then
        return nil
    end
    return skin
end

--- Recherche le z du sol sous un point (la collision doit être streamée).
---@param x number
---@param y number
---@param zHint number
---@return number
local function FindGroundZ(x, y, zHint)
    RequestCollisionAtCoord(x, y, zHint)
    local deadline = GetGameTimer() + 2000
    local probes = { zHint + 1.0, zHint + 10.0, zHint + 40.0, zHint + 120.0 }

    while GetGameTimer() < deadline do
        for i = 1, #probes do
            local found, groundZ = GetGroundZFor_3dCoord(x, y, probes[i], false)
            if found and groundZ > 0.0 then
                return groundZ
            end
        end
        Wait(50)
    end

    return zHint
end

-- Hauteur de l'origine d'un ped (bassin) au-dessus de ses pieds
local PED_ORIGIN_HEIGHT <const> = 1.0

--- Calcule la position du personnage et de la lumière par rapport à la caméra
--- d'une entrée de Config.Multicharacter.Spawn.
---@param scene table
---@return table ped { x, y, z (pieds), heading }, table cam { x, y, z, rot }, table light
local function ComputeScene(scene)
    local cam = {
        x = scene.CamCoords.x,
        y = scene.CamCoords.y,
        z = scene.CamCoords.z,
        rot = { x = scene.CamRot.x or 0.0, y = scene.CamRot.y or 0.0, z = scene.CamRot.z or 0.0 },
    }

    -- Heading GTA : 0 = nord, sens anti-horaire
    local yaw = math.rad(cam.rot.z)
    local fwdX, fwdY = -math.sin(yaw), math.cos(yaw)
    local rightX, rightY = math.cos(yaw), math.sin(yaw)

    local distance = scene.PedDistance or 3.2
    local side = scene.PedSide or 0.0
    local drop = scene.PedDrop or 0.7

    local ped = {
        x = cam.x + fwdX * distance + rightX * side,
        y = cam.y + fwdY * distance + rightY * side,
        z = cam.z - drop,
        heading = (cam.rot.z + 180.0 + (scene.PedTurn or 0.0)) % 360.0,
    }

    -- Lumière entre la caméra et le personnage, décalée pour modeler le visage
    local light = {
        x = cam.x + fwdX * (distance * 0.45) + rightX * (side + 0.8),
        y = cam.y + fwdY * (distance * 0.45) + rightY * (side + 0.8),
        z = cam.z + 0.8,
    }

    return ped, cam, light
end

--- Prépare la scène (caméra, position du personnage, lumière). Appelée une seule fois par passage dans la sélection.
function Multicharacter:SetupScene()
    if self.sceneReady and self.spawnCoords then return end

    local randomIndex = VFW.Math.Random(1, #Config.Multicharacter.Spawn)
    local scene = Config.Multicharacter.Spawn[randomIndex]
    if not scene or not scene.CamCoords then
        console.warn("[Multicharacter] Scène de spawn invalide")
        return
    end
    self.cameras = scene

    local ped, cam, light = ComputeScene(scene)

    ClearFocus()
    SetFocusArea(ped.x, ped.y, ped.z, 0.0, 0.0, 0.0)

    if scene.SnapToGround then
        local groundZ = FindGroundZ(ped.x, ped.y, ped.z)
        local delta = groundZ - ped.z
        ped.z = groundZ
        cam.z = cam.z + delta
        light.z = light.z + delta
    end

    -- spawnCoords.z = origine du ped (bassin), pas les pieds
    self.spawnCoords = { x = ped.x, y = ped.y, z = ped.z + PED_ORIGIN_HEIGHT, w = ped.heading }
    self.sceneCam = cam
    self.sceneReady = true

    VFW.Cam:Create("multichar", {
        CamCoords = { x = cam.x, y = cam.y, z = cam.z },
        CamRot = cam.rot,
        Fov = scene.Fov or 45.0,
        Dof = scene.Dof,
        DofStrength = scene.DofStrength or 0.0,
    }, self.characterClone)

    -- La sélection se joue de nuit : sans lumière d'appoint le personnage est dans l'ombre.
    if scene.Light then
        local l = scene.Light
        CreateThread(function()
            while self.inSelection and self.sceneReady do
                DrawLightWithRange(light.x, light.y, light.z, l.r or 255, l.g or 240, l.b or 220,
                    l.range or 7.0, l.intensity or 1.5)
                Wait(0)
            end
        end)
    end
end

function Multicharacter:CreateCharacterClone()
    if self.characterClone then
        DeleteEntity(self.characterClone)
        self.characterClone = nil
    end
    self.cloneIndex = nil

    if not self.Characters[self.tempIndex] then
        console.warn("Character data not found for index: " .. tostring(self.tempIndex))
        return
    end

    local skin = self:GetSkin()
    if not skin then
        -- Personnage sans apparence (créateur non terminé) : rien à afficher.
        return
    end

    local tattoos = self.Characters[self.tempIndex].tattoos or {}
    if not self.spawnCoords then
        self.sceneReady = false
        self:SetupScene()
    end
    local coords = self.spawnCoords
    if type(coords) ~= "table" or coords.x == nil then
        console.warn("[Multicharacter] spawnCoords manquant, clone annulé")
        return
    end
    local index = self.tempIndex

    local ok, clone = pcall(VFW.CreatePlayerClone, skin, tattoos,
        vector3(coords.x, coords.y, coords.z), coords.w or 0.0)

    if not ok or not clone or not DoesEntityExist(clone) then
        console.warn("[Multicharacter] Impossible de créer le clone du personnage : " .. tostring(clone))
        return
    end

    -- Le survol a changé pendant la création du clone : on jette celui-ci.
    if self.tempIndex ~= index or not self.inSelection then
        DeleteEntity(clone)
        return
    end

    self.characterClone = clone
    self.cloneIndex = index

    FreezeEntityPosition(clone, self.cameras.Freeze ~= false)
    SetEntityCoordsNoOffset(clone, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(clone, coords.w or 0.0)
    SetEntityInvincible(clone, true)
    SetBlockingOfNonTemporaryEvents(clone, true)
    SetPedCanRagdoll(clone, false)
    SetEntityAsMissionEntity(clone, true, true)
    SetEntityCollision(clone, false, false)

    local animation = self.cameras.Animation
    if animation then
        RequestAnimDict(animation.dict)
        local deadline = GetGameTimer() + 2000
        while not HasAnimDictLoaded(animation.dict) and GetGameTimer() < deadline do
            Wait(10)
        end
        if HasAnimDictLoaded(animation.dict) and DoesEntityExist(clone) then
            TaskPlayAnim(clone, animation.dict, animation.anim, 4.0, -4.0, -1, 1, 0.0, false, false, false)
        end
    end

    -- Apparition en fondu pour éviter le "pop" au changement de personnage.
    SetEntityAlpha(clone, 0, false)
    CreateThread(function()
        local alpha = 0
        while alpha < 255 and DoesEntityExist(clone) and self.characterClone == clone do
            alpha = math.min(255, alpha + 51)
            SetEntityAlpha(clone, alpha, false)
            Wait(30)
        end
        if DoesEntityExist(clone) and self.characterClone == clone then
            ResetEntityAlpha(clone)
        end
    end)
end

function Multicharacter:SetupCharacter(index)
    self.tempIndex = index
    self.spawned = index

    if not self.sceneReady or not self.spawnCoords then
        self.sceneReady = false
        self:SetupScene()
    end

    if self.cloneIndex == index and self.characterClone and DoesEntityExist(self.characterClone) then
        return
    end

    self:CreateCharacterClone()
end

function Multicharacter:Cleanup()
    if self.characterClone then
        DeleteEntity(self.characterClone)
        self.characterClone = nil
    end
    self.cloneIndex = nil
    self.sceneReady = false
    self.sceneCam = nil
end

function Multicharacter:SetupUI(characters, slots)
    self._settingUp = false

    local waitCount = 0
    while VFW.PlayerGlobalData == nil do
        Wait(100)
        waitCount = waitCount + 1
        if waitCount > 300 then
            console.error("[Multicharacter] PlayerGlobalData failed to load after 30s")
            return
        end
    end

    self.Characters = characters
    self.slots = slots
    self.inSelection = true

    local Character = next(self.Characters)

    NetworkOverrideClockTime(23, 0, 0)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')

    if not Character then
        TriggerServerEvent("vfw:multicharacter:CharacterChosen", 1, true)
        Wait(250)
        LoadNewCharCreator()
    else
        self:SetupCharacter(1)
        Wait(50)

        local items = {}
        
        for i = 1, #self.Characters do
            local char = self.Characters[i]
            items[i] = {
                id = i,
                info = char.info,
                firstName = char.firstname,
                lastName = char.lastname,
                img = char.mugshot,
                jobLabel = char.jobLabel,
                factionLabel = char.factionLabel,
                cash = char.cash,
                height = char.height,
                dateOfBirth = char.dateofbirth,
            }
        end
        
        local tier = tonumber(VFW.PlayerGlobalData and VFW.PlayerGlobalData.vip_tier) or 0
        local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
        local isVip = tier >= 1 or perms["vip_bronze"] or perms["vip_silver"] or perms["vip_gold"] or false
        local isVipPlus = tier >= 2 or perms["vip_silver"] or perms["vip_gold"] or false
        local uniqueId = VFW.PlayerGlobalData and VFW.PlayerGlobalData.id
        local vipTierLabel = VIPConfig.GetTierLabel(tier)
        if tier <= 0 then
            vipTierLabel = "Aucun"
        end

        VFW.Nui.Multicharacter(true, {
            visible = true,
            items = items,
            isVip = isVip,
            isVipPlus = isVipPlus,
            uniqueId = uniqueId,
            vipTierLabel = vipTierLabel,
            brandName = (VFW.BrandName and VFW.BrandName()) or (BRANDING and BRANDING.name) or "",
        })
    end

    DoScreenFadeIn(150)
end

function Multicharacter:Reset()
    self.Characters = {}
    self.tempIndex = nil
    self.cloneIndex = nil
    self.sceneReady = false
    self.sceneCam = nil
    self.playerPed = PlayerPedId()
    self.hidePlayers = false
    self.inSelection = false
    self._settingUp = false
    self.slots = nil
end

function Multicharacter:PlayerLoaded(playerData, isNew, skin)
    VFW.PlayerData = playerData

---Load finishing
    local function finishLoading()
        TriggerEvent("vfw:client:playerLoaded")
        TriggerServerEvent("vfw:onPlayerLoaded")
        TriggerEvent("vfw:onPlayerLoaded")
        TriggerEvent("vfw:restoreLoadout")
        TriggerServerEvent("vfw:sync:onPlayerJoined")


        self:Reset()
    end

    if isNew or not skin or next(skin) == nil then
        TriggerEvent("skinchanger:getSkin", function(cb)
            skin = cb
            finishLoading()

            TriggerServerEvent("core:server:startCreator")
        end)
    else
        local selectedSkin = skin or (self.spawned and self.Characters[self.spawned] and self.Characters[self.spawned].skin)

        SetFocusPosAndVel(playerData.coords.x, playerData.coords.y, playerData.coords.z, 0.0, 0.0, 0.0)

        -- Recuperer le staff ped AVANT VFW.SpawnPlayer (avec callbacks VFW)
        local staffPed = TriggerServerCallback("vfw:staff:getStaffPed")

        VFW.SpawnPlayer(selectedSkin, playerData.coords, function()
            self.playerPed = PlayerPedId()

            -- IMPORTANT: Liberer le focus apres le spawn pour eviter les problemes de streaming
            ClearFocus()

            self:HideHud(false)
            Core.FreezePlayer(false)
            SetEntityCollision(self.playerPed, true, true)
            SetEntityVisible(self.playerPed, true)
            SetEntityAlpha(self.playerPed, 255, false)

            -- Appliquer le staff ped recupere AVANT finishLoading
            if staffPed then
                local pedModel = type(staffPed) == "string" and GetHashKey(staffPed) or staffPed
                if IsModelInCdimage(pedModel) and IsModelValid(pedModel) then
                    RequestModel(pedModel)
                    while not HasModelLoaded(pedModel) do
                        Wait(10)
                    end
                    SetPlayerModel(PlayerId(), pedModel)
                    SetPedDefaultComponentVariation(PlayerPedId())
                    SetModelAsNoLongerNeeded(pedModel)
                    self.playerPed = PlayerPedId()
                end
            end

            -- Appeler finishLoading APRES l'application du staff ped
            finishLoading()

            -- Fade in screen after everything is done
            DoScreenFadeIn(500)
        end)
    end
end

RegisterNuiCallback("multicharacter:createNewPersonnage", function()
    if not Multicharacter.inSelection then return end
    Multicharacter.inSelection = false
    for i = 1, Multicharacter.slots do
        if not Multicharacter.Characters[i] then
            -- Instant fade to black to hide time change
            DoScreenFadeOut(0)
            VFW.Nui.Multicharacter(false)
            Multicharacter:AwaitFadeOut()

            -- Clear time override and immediately sync server time
            NetworkClearClockTimeOverride()
            Multicharacter.inSelection = false

            -- Request immediate time sync from server
            TriggerServerEvent("vfw:multicharacter:RequestTimeSync")
            Wait(100)

            TriggerServerEvent("vfw:multicharacter:CharacterChosen", i, true)
            VFW.Cam:Destroy("multichar")
            ClearFocus()
            Multicharacter:Cleanup()

            -- Safety: si LoadNewCharCreator crash, on rétablit l'écran après 15s
            local fadeStart = GetGameTimer()
            CreateThread(function()
                Wait(15000)
                if IsScreenFadedOut() and (GetGameTimer() - fadeStart) >= 15000 then
                    console.warn("[Multicharacter] Fade-in safety triggered after creator load timeout")
                    DoScreenFadeIn(500)
                end
            end)

            LoadNewCharCreator()
            break
        end
    end
end)

RegisterNuiCallback("multicharacter:PlayerHovered", function(id)
    if not id or not Multicharacter.Characters[id] then
        return
    end

    Multicharacter:SetupCharacter(id)
end)

RegisterNuiCallback("multicharacter:PlayerSelected", function(id)
    if not id or not Multicharacter.inSelection then
        return
    end
    Multicharacter.inSelection = false

    -- Instant fade to black to hide time change
    DoScreenFadeOut(500)
    VFW.Nui.Multicharacter(false)
    Multicharacter:AwaitFadeOut()

    -- Clear time override and immediately sync server time
    NetworkClearClockTimeOverride()
    Multicharacter.inSelection = false

    -- Request immediate time sync from server
    TriggerServerEvent("vfw:multicharacter:RequestTimeSync")
    Wait(100)

    VFW.Cam:Destroy("multichar")
    -- ClearFocus() moved to after spawn completes in VFW.SpawnPlayer
    Multicharacter:Cleanup()
    TriggerServerEvent("vfw:multicharacter:CharacterChosen", id, false)

end)

-- Forcer le retour au creator après un crash
RegisterNetEvent("vfw:multicharacter:forceCreator")
AddEventHandler("vfw:multicharacter:forceCreator", function(charId)
    VFW.Cam:Destroy("multichar")
    ClearFocus()
    Multicharacter:Cleanup()
    LoadNewCharCreator()
end)
