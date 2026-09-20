--- LTD Catalog client.
--- Renders public catalog interaction points for societies of type "ltd"
--- and opens a VUI menu listing items and their resell prices.

local VUI = exports["VUI"]
local catalogBanner = VFW.CDN.Get("banners/catalogue_ltd.png")

local ltdCatalogActive = false
local catalogMenus = {}

local function getOrCreateMenu(jobName, label)
    if catalogMenus[jobName] then return catalogMenus[jobName] end
    local menu = VUI:CreateMenu("Catalogue " .. (label or jobName), catalogBanner, true)
    catalogMenus[jobName] = menu
    return menu
end

local function purchaseCatalogItem(jobName, entry)
    if not entry or not entry.item or (entry.price or 0) <= 0 then
        return
    end

    CreateThread(function()
        local result = TriggerServerCallback("vfw:ltd:purchaseCatalogItem", jobName, entry.item)

        if result and result.success then
            VFW.ShowNotification({
                type = "VERT",
                content = ("Achat effectué%s"):format(
                    result.paymentMethod == "bank" and " (carte)" or ""
                )
            })
        else
            local message = result and result.message or "Erreur lors de l'achat"
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
                    type = "ROUGE",
                    content = message
                })
            end
        end
    end)
end

local function openLTDCatalog(jobName)
    local data = TriggerServerCallback("vfw:ltd:getCatalogItems", jobName)
    if not data then
        VFW.ShowNotification({ type = 'ROUGE', content = "Catalogue indisponible." })
        return
    end

    local menu = getOrCreateMenu(jobName, data.label)
    menu.ClearItems()
    menu.Separator("LISTE DES VENTES")
    menu.Separator("Entrée = acheter l'article")

    if not data.items or #data.items == 0 then
        menu.Button("Aucun article", "Le catalogue est vide", nil, nil, true, function() end)
    else
        for _, entry in ipairs(data.items) do
            local price = entry.price or 0
            local canBuy = price > 0
            menu.Button(
                entry.label,
                VFW.Math.FormatMoney(price),
                canBuy and "Entrée pour acheter" or "Indisponible",
                nil,
                not canBuy,
                function()
                    purchaseCatalogItem(jobName, entry)
                end
            )
        end
    end

    menu.open()
end

local function showFloating(id, pos, shown)
    local onScreen, screenX, screenY = World3dToScreen2d(pos.x, pos.y, pos.z + 0.9)
    if not onScreen then
        if shown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            return false
        end
        return shown
    end

    local data = {
        id = id,
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = {
            { label = "Catalogue", key = "E" }
        }
    }

    if shown then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
    end
    return true
end

local function hideFloating(shown)
    if shown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
    end
    return false
end

local function loadLTDCatalogPoints()
    ltdCatalogActive = false
    Wait(100)

    local points = TriggerServerCallback("vfw:ltd:getCatalogPoints")
    if not points or #points == 0 then return end

    ltdCatalogActive = true

    for index, point in ipairs(points) do
        local pos = vector3(point.x, point.y, point.z)
        local heading = point.h or 0
        local jobName = point.society
        local floatingId = ("ltd_catalog_%s_%d"):format(jobName, index)

        CreateThread(function()
            local shown = false

            while ltdCatalogActive do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - pos)

                if distance < 10.0 then
                    if distance < 1.5 and not IsNuiFocused() then
                        shown = showFloating(floatingId, pos, shown)

                        if VFW.Interact.JustPressed(0, 38)
                            or IsControlJustPressed(0, 191)
                            or IsControlJustPressed(0, 201) then
                            shown = hideFloating(shown)
                            if heading ~= 0 then
                                SetEntityHeading(PlayerPedId(), heading)
                            end
                            openLTDCatalog(jobName)
                        end
                    else
                        shown = hideFloating(shown)
                    end

                    Wait(0)
                else
                    shown = hideFloating(shown)
                    Wait(500)
                end
            end

            hideFloating(shown)
        end)
    end
end

RegisterNetEvent("vfw:playerReady", function()
    loadLTDCatalogPoints()
end)

RegisterNetEvent("vfw:ltd:catalogUpdated", function()
    loadLTDCatalogPoints()
end)
