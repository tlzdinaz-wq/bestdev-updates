---@class Web
Web = {}

---@param action string
---@param data table
---@return void
Web.Send = function(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

---@param visible boolean
---@return void
Web.Visible = function(visible)
    Web.Send("nui:visible", visible)
end

---@return void
Web.Close = function()
    Web.Send("nui:close")
end

---@param focus boolean
---@param keep boolean
---@return void
Web.Focus = function(focus, keep)
    SetNuiFocus(focus, focus)
    SetNuiFocusKeepInput(keep or false)
end

---@param url string
---@return void
Web.OpenUrl = function(url)
    Web.Send("nui:open_url", url)
end