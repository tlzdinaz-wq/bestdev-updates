--- LTD Items Configuration
--- Static fallback used to seed the `ltd_items` DB table on first boot.
--- After that, the staff "Gestion items LTD" builder is the canonical
--- source of truth and `server/items_manager.lua` rewrites LTDItems.List.
--- Clients receive updates via the `vfw:ltd:items:sync` event.
---
--- Field reference:
---   item        : DB item key (must match `items.name`)
---   label       : display label (used when seeding spacemarket)
---   normalPrice : retail price in supermarkets (nil = not sold in supermarkets)
---   buyPrice    : Market buy price for the LTD society (nil = not orderable)
---   sellPrice   : default LTD resell price (catalog)

LTDItems = LTDItems or {}

LTDItems.Category = "Produits LTD"

LTDItems.List = LTDItems.List or {
    { item = "bread",           label = "Pain",                 normalPrice = 200,  buyPrice = 100,  sellPrice = 150  },
    { item = "eau_plate",       label = "Eau",                  normalPrice = 200,  buyPrice = 100,  sellPrice = 150  },
    { item = "bait",            label = "Appât",                normalPrice = 50,   buyPrice = 10,   sellPrice = 25   },
    { item = "fishroad",        label = "Canne à pêche",        normalPrice = 2000, buyPrice = 500,  sellPrice = 1200 },
    { item = "ticket_gratter",  label = "Ticket à gratter",     normalPrice = nil,  buyPrice = 350,  sellPrice = 500  },
    { item = "cordes",          label = "Corde Véhicule",       normalPrice = nil,  buyPrice = 100,  sellPrice = 500  },
    { item = "weapon_petrolcan",label = "Bidon d'essence",      normalPrice = nil,  buyPrice = 200,  sellPrice = 600  },
    { item = "phone",           label = "Téléphone",            normalPrice = 750,  buyPrice = 200,  sellPrice = 500  },
    { item = "radio_public",    label = "Radio",                normalPrice = 1200, buyPrice = 200,  sellPrice = 750  },
    { item = "gadget_parachute",label = "Parachute",            normalPrice = nil,  buyPrice = 1000, sellPrice = 5000 },
    { item = "megaphone",       label = "Mégaphone",            normalPrice = nil,  buyPrice = 1000, sellPrice = 5000 },
    { item = "spray",           label = "Bombe à peinture",     normalPrice = nil,  buyPrice = 500,  sellPrice = 2000 },
    { item = "spray_remover",   label = "Nettoyant graffiti",   normalPrice = nil,  buyPrice = 250,  sellPrice = 1000 },
    { item = "boombox",         label = "Boombox",              normalPrice = nil,  buyPrice = 1000, sellPrice = 5000 },
    { item = "scuba_mask",      label = "Masque de plongée",    normalPrice = nil,  buyPrice = 200,  sellPrice = 1000 },
    { item = "pince",           label = "Pince à cheveux",      normalPrice = 1000, buyPrice = 100,  sellPrice = 500  }
}

--- Build the default catalog prices map (item -> sellPrice).
function LTDItems.GetDefaultCatalogPrices()
    local out = {}
    for _, entry in ipairs(LTDItems.List) do
        out[entry.item] = entry.sellPrice
    end
    return out
end

--- Resolve the effective catalog price for an item, given a society override map.
function LTDItems.GetCatalogPrice(item, override)
    if override and override[item] then
        return tonumber(override[item]) or 0
    end
    for _, entry in ipairs(LTDItems.List) do
        if entry.item == item then return entry.sellPrice end
    end
    return 0
end
