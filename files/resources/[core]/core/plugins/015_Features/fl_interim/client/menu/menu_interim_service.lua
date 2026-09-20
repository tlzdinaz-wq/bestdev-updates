local VUI = exports["VUI"]

InterimVehicleMenu = {}
InterimVehicleMenu.__index = InterimVehicleMenu

local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

RegisterNetEvent("vfw:setJob", function(job)
    PlayerData.job = job
end)

function InterimVehicleMenu.new(jobId, opts, outfits)
    local self = setmetatable({}, InterimVehicleMenu)
    self.jobId  = jobId
    self.title  = (opts and opts.title)  or ("VEHICULE - " .. tostring(jobId))
    self.banner = (opts and opts.banner) or "default"
    self.getVehicleOut = opts and opts.getVehicleOut
    self.onSpawn  = opts and opts.onSpawn
    self.onStore  = opts and opts.onStore
    self.outfits  = outfits or {}
    self.serviceOutfit = false
    self.cooldownMs     = math.floor(((opts and opts.cooldownSeconds) or 5) * 1000)
    self._lastToggleAt  = 0

    self.menu = VUI:CreateMenu(self.title, self.banner, false)

    local ref = self
    self.menu.OnOpen(function()
        ref:build()
    end)
    self.menu.OnClose(function()
        ref.menu.ClearItems()
    end)

    return self
end

local function truthy(v) return v == true or v == 1 or v == "true" end
local function nowMs() return GetGameTimer() end

function InterimVehicleMenu:_notify(msg)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({ type = "JAUNE", content = msg })
    end
end

function InterimVehicleMenu:_cooldownReady()
    local dt = nowMs() - (self._lastToggleAt or 0)
    if dt < self.cooldownMs then
        local left = math.ceil((self.cooldownMs - dt) / 1000)
        self:_notify(("Veuillez patienter %ds avant de réessayer."):format(left))
        return false
    end
    return true
end

function InterimVehicleMenu:_isVehicleOut()
    local ok, val = pcall(self.getVehicleOut or function() return false end)
    return ok and truthy(val)
end

local function toggleProps(vehicleOut)
    if vehicleOut then
        return { title = "Ranger le véhicule", icon = "chevron" }
    else
        return { title = "Sortir le véhicule", icon = "chevron" }
    end
end

function InterimVehicleMenu:_reopen()
    if self.menu.opened then
        self.menu.close()
    end
    self.menu.open()
end

function InterimVehicleMenu:build()
    local m = self.menu
    m.ClearItems()

    local vehicleOut = self:_isVehicleOut()

    m.Title("Gestion du travail", "", "", "", nil)
    m.Separator(nil)

    if next(self.outfits) then
        if self.serviceOutfit then
            m.Button(
                    "Déposer la tenue",
                    "Déposez votre tenue de service",
                    nil,
                    nil,
                    false,
                    function()
                        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
                        TriggerEvent('skinchanger:loadSkin', skin or {})
                        self.serviceOutfit = false
                        m.refresh()
                    end
            )
            m.Separator(nil)
        else
            m.Button(
                    "Prendre la tenue",
                    "Prenez votre tenue de service",
                    nil,
                    nil,
                    false,
                    function()
                        TriggerEvent('skinchanger:getSkin', function(skin)
                            if skin.sex == 0 then
                                TriggerEvent('skinchanger:loadClothes', skin, self.outfits[1])
                            else
                                TriggerEvent('skinchanger:loadClothes', skin, self.outfits[2])
                            end
                        end)
                        self.serviceOutfit = true
                        m.refresh()
                    end)
        end
    end



    local p = toggleProps(vehicleOut)
    m.Button(p.title, nil, nil, p.icon, false, function()
        if not self:_cooldownReady() then return end

        if PlayerData.job and PlayerData.job.name and PlayerData.job.name ~= "unemployed" then
            VFW.ShowNotification({ type = "JAUNE", content = "Vous ne pouvez pas effectuer cette action en tant que travailleur." })
            return
        end

        if vehicleOut then
            if self.onStore then
                local okpc, ret = pcall(self.onStore)
                if okpc and truthy(ret) then
                    self._lastToggleAt = nowMs()
                    self:_reopen()
                end
            end
        else
            if self.onSpawn then
                local okpc, ret = pcall(self.onSpawn)
                if okpc and truthy(ret) then
                    self._lastToggleAt = nowMs()
                    self:toggle()
                end
            end
        end
    end)
end

function InterimVehicleMenu:toggle()
    self.menu.toggle()
end

function InterimVehicleMenu:open()
    self:_reopen()
end

return InterimVehicleMenu
