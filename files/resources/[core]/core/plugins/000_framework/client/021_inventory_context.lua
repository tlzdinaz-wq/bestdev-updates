---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- VFW.Inventory.ContextMenu
-- API pour personnaliser le context menu de l'inventaire par item
-- ============================================================

VFW.Inventory = VFW.Inventory or {}
VFW.Inventory.ContextMenu = {}

local customButtons = {}   -- { [itemName] = { { id, label, icon, event, serverEvent } } }
local removedButtons = {}  -- { [itemName] = { ["use"] = true, ["give"] = true, ... } }
local renamedButtons = {}  -- { [itemName] = { ["use"] = "Sortir", ["give"] = "Offrir", ... } }

local function sendConfig()
    SendNUIMessage({
        action = "nui:inventory:contextMenuConfig",
        data = {
            customButtons = customButtons,
            removedButtons = removedButtons,
            renamedButtons = renamedButtons
        }
    })
end

--- Ajouter un bouton custom au context menu pour un item spécifique
---@param itemName string Nom de l'item (ex: "radio", "skateboard")
---@param opts table { id: string, label: string, icon?: string, event?: string, serverEvent?: string, order?: number }
function VFW.Inventory.ContextMenu.AddButton(itemName, opts)
    if not customButtons[itemName] then
        customButtons[itemName] = {}
    end
    table.insert(customButtons[itemName], {
        id = opts.id,
        label = opts.label,
        icon = opts.icon or "►",
        event = opts.event,
        serverEvent = opts.serverEvent,
        order = opts.order
    })
    sendConfig()
end

--- Renommer un bouton par défaut du context menu pour un item spécifique
---@param itemName string Nom de l'item
---@param buttonId string ID du bouton à renommer ("use", "give", "drop", "rename")
---@param newLabel string Nouveau label à afficher
function VFW.Inventory.ContextMenu.RenameButton(itemName, buttonId, newLabel)
    if not renamedButtons[itemName] then
        renamedButtons[itemName] = {}
    end
    renamedButtons[itemName][buttonId] = newLabel
    sendConfig()
end

--- Retirer un bouton (par défaut ou custom) du context menu pour un item spécifique
---@param itemName string Nom de l'item
---@param buttonId string ID du bouton à retirer ("use", "give", "drop", "rename" ou un id custom)
function VFW.Inventory.ContextMenu.RemoveButton(itemName, buttonId)
    if not removedButtons[itemName] then
        removedButtons[itemName] = {}
    end
    removedButtons[itemName][buttonId] = true
    sendConfig()
end

--- Restaurer un bouton précédemment retiré via RemoveButton
---@param itemName string Nom de l'item
---@param buttonId string ID du bouton à restaurer
function VFW.Inventory.ContextMenu.RestoreButton(itemName, buttonId)
    if removedButtons[itemName] then
        removedButtons[itemName][buttonId] = nil
    end
    sendConfig()
end

-- Renvoyer la config à chaque ouverture d'inventaire (le NUI n'est pas prêt au boot)
AddEventHandler("core:inventory:opened", function()
    sendConfig()
end)

-- NUI callback pour router les actions custom vers les events Lua
RegisterNUICallback("nui:inventory:custom-action", function(data, cb)
    cb("ok")
    if not data or not data.itemName or not data.actionId then return end
    local buttons = customButtons[data.itemName]
    if buttons then
        for _, btn in ipairs(buttons) do
            if btn.id == data.actionId then
                if btn.event then
                    TriggerEvent(btn.event, data.item)
                end
                if btn.serverEvent then
                    TriggerServerEvent(btn.serverEvent, data.item)
                end
                break
            end
        end
    end
end)
