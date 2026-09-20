--- Receives the live LTDItems.List from the server and overrides the
--- shared static fallback so client-side menus (society Prix Catalogue
--- builder, staff Gestion items LTD builder) always render fresh data.

RegisterNetEvent("vfw:ltd:items:sync", function(list)
    if type(list) ~= "table" then return end
    LTDItems = LTDItems or {}
    LTDItems.List = list
end)
