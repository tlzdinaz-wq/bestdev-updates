PaidShopConfig = {}

-- CONFIGURABLE CATEGORIES
-- You can add, remove, or modify these categories (except VIP)
-- Each category can have specific behavior and item types
PaidShopConfig.ConfigurableCategories = {
    pour_moi = {
        enabled = true,
        label = "Pour Moi",
        icon = "fa-user-tag",
        order = 0,  -- First in the list
        itemType = "personal",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyPersonalItem",
        maxQuantity = 1,
        allowRefund = true,
        customFields = {
            "spawnName",
            "price",
            "originalPrice",
            "image",
            "tags",
            "description"
        }
    },
    vehicules = {
        enabled = true,                    -- Enable/disable this category
        label = "Véhicules",               -- Display name
        icon = "fa-car",                   -- Font Awesome icon
        order = 1,                         -- Display order (lower = first)
        itemType = "vehicle",              -- Type of items: vehicle, weapon, pack, consumable, admin
        requiresPreview = true,            -- Show preview before purchase
        adminOnly = false,                 -- Restrict to admins only
        purchaseHandler = "buyVehicle",    -- Server-side handler function
        maxQuantity = 1,                   -- Max items per purchase (nil = unlimited)
        allowRefund = true,                -- Allow refunding pending items
        customFields = {                   -- Required fields for this category's items
            "spawnName",                   -- Vehicle spawn code
            "price",                       -- Item price
            "image",                       -- Item image URL
            "tags",                        -- Display tags
            "description"                  -- Item description
        }
    },
    armes = {
        enabled = true,
        label = "Armes",
        icon = "fa-gun",
        order = 2,
        itemType = "weapon",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",
        maxQuantity = nil,
        allowRefund = true,
        customFields = {
            "spawnName",                   -- Weapon model (weapon_pistol, etc.)
            "price",
            "image",
            "tags",
            "description"
        }
    },
    packs = {
        enabled = true,
        label = "Packs",
        icon = "fa-cubes",
        order = 3,
        itemType = "pack",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",
        maxQuantity = 1,
        allowRefund = true,                 -- Packs sit in pending until claim → refundable like vehicles
        autoGenerateSpawnName = true,       -- spawnName is auto-generated (no inventory item backs the pack itself)
        customFields = {
            "price",
            "image",
            "tags",
            "description",
            "content"                       -- Pack content (vehicles, weapons, items)
        }
    },
    consommables = {
        enabled = true,
        label = "Consommables",
        icon = "fa-shopping-cart",
        order = 4,
        itemType = "consumable",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",
        maxQuantity = 10,                  -- Allow buying multiple consumables
        allowRefund = true,
        customFields = {
            "spawnName",                   -- Item name in inventory
            "price",
            "image",
            "tags",
            "description"
        }
    },
    caisses = {
        enabled = true,
        label = "Caisses",
        icon = "fa-box-open",
        order = 6,
        itemType = "case",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",
        maxQuantity = 5,
        allowRefund = false,
        autoGenerateSpawnName = true,  -- spawnName is auto-generated (cases open UI, not inventory items)
        customFields = {
            "price",
            "image",
            "tags",
            "description",
            "possible_items"
        }
    },
    accessoires_armes = {
        enabled = true,
        label = "Accessoires d'armes",
        icon = "fa-crosshairs",
        order = 7,
        itemType = "consumable",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",
        maxQuantity = 5,
        allowRefund = true,
        customFields = {
            "spawnName",
            "price",
            "image",
            "tags",
            "description"
        }
    },
    munitions = {
        enabled = true,
        label = "Munitions",
        icon = "fa-bullseye",
        order = 5,
        itemType = "consumable",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",
        maxQuantity = 10,
        allowRefund = true,
        customFields = {
            "spawnName",
            "price",
            "image",
            "tags",
            "description",
            "claimItem",
            "claimCount"
        }
    },
    potions = {
        enabled = true,
        label = "Potions",
        icon = "fa-flask",
        order = 8,
        itemType = "consumable",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",
        maxQuantity = 10,
        allowRefund = true,
        customFields = {
            "spawnName",
            "price",
            "image",
            "tags",
            "description"
        }
    },
    peintures = {
        enabled = true,
        label = "Peintures Caméléon",
        icon = "fa-spray-can",
        order = 10,
        itemType = "consumable",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",
        maxQuantity = 5,
        allowRefund = true,
        customFields = {
            "spawnName",
            "price",
            "image",
            "tags",
            "description"
        }
    },
    peds = {
        enabled = true,
        label = "Animaux",
        icon = "fa-paw",
        order = 11,
        itemType = "ped",                  -- Transformation joueur (model swap)
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",       -- Achat générique -> pending_items -> claim
        maxQuantity = 1,                   -- Possession permanente : un seul exemplaire
        allowRefund = true,
        customFields = {
            "spawnName",                   -- Modèle du ped ou hash (ex: a_c_shepherd)
            "price",
            "image",
            "tags",
            "description"
        }
    },
    daily_reward = {
        -- Catégorie désactivée : le bonus quotidien (50 SC) vit désormais dans
        -- l'ActivityRail (colonne droite). La roue Daily Reward / le builder
        -- admin restent en code mais l'entrée sidebar est masquée.
        enabled = false,
        label = "Daily Reward",
        icon = "fa-calendar-check",
        order = 9,
        itemType = "consumable",
        requiresPreview = false,
        adminOnly = false,
        purchaseHandler = "buyItem",
        maxQuantity = 1,
        allowRefund = false,
        customFields = {}
    }
    -- ADD NEW CATEGORIES HERE
}

-- VIP CATEGORY - SPECIAL NON-CONFIGURABLE
-- This category has unique Tebex integration and cannot be modified through config
PaidShopConfig.VIPCategory = {
    id = "vip",
    label = "VIP",
    icon = "fa-crown",
    order = 999,                           -- Always last
    enabled = true,                        -- Can be disabled but not removed
    adminOnly = false,
    itemType = "vip",
    requiresPreview = false,
    allowRefund = false,
    -- VIP items don't have prices, they redirect to Tebex
    customFields = {
        "spawnName",
        "image",
        "tags",
        "description",
        "vipTier",
        "tebexUrl",
        "color",
        "advantages"
    }
}

-- Build Categories array from configurable categories + VIP
PaidShopConfig.Categories = {}

-- Rebuild PaidShopConfig.Categories from current ConfigurableCategories + VIPCategory.
-- Called at boot (initial build) and at runtime after an admin toggles a category
-- via the staff builder (paidshop:adminSetCategoryEnabled).
function PaidShopConfig.RebuildCategoriesList()
    PaidShopConfig.Categories = {}

    for categoryId, config in pairs(PaidShopConfig.ConfigurableCategories) do
        if config.enabled then
            table.insert(PaidShopConfig.Categories, {
                id = categoryId,
                label = config.label,
                icon = config.icon,
                adminOnly = config.adminOnly or false,
                order = config.order or 100
            })
        end
    end

    if PaidShopConfig.VIPCategory.enabled then
        table.insert(PaidShopConfig.Categories, {
            id = PaidShopConfig.VIPCategory.id,
            label = PaidShopConfig.VIPCategory.label,
            icon = PaidShopConfig.VIPCategory.icon,
            adminOnly = PaidShopConfig.VIPCategory.adminOnly,
            order = PaidShopConfig.VIPCategory.order
        })
    end

    table.sort(PaidShopConfig.Categories, function(a, b)
        return (a.order or 100) < (b.order or 100)
    end)
end

-- Initial build at file load (defaults from this file)
PaidShopConfig.RebuildCategoriesList()

-- Helper function to get category configuration
function PaidShopConfig.GetCategoryConfig(categoryId)
    -- Check if it's VIP category
    if categoryId == "vip" then
        return PaidShopConfig.VIPCategory
    end

    -- Check configurable categories
    return PaidShopConfig.ConfigurableCategories[categoryId]
end

-- Helper function to check if a category is enabled
function PaidShopConfig.IsCategoryEnabled(categoryId)
    local config = PaidShopConfig.GetCategoryConfig(categoryId)
    return config and config.enabled
end

-- Helper function to get all enabled categories
function PaidShopConfig.GetEnabledCategories()
    local categories = {}

    -- Add configurable categories
    for categoryId, config in pairs(PaidShopConfig.ConfigurableCategories) do
        if config.enabled then
            categories[categoryId] = config
        end
    end

    -- Add VIP if enabled
    if PaidShopConfig.VIPCategory.enabled then
        categories.vip = PaidShopConfig.VIPCategory
    end

    return categories
end

-- Items available in the shop
PaidShopConfig.Items = {
    vehicules = {
        {
            name = "Sultan",
            price = 2500,
            spawnName = "sultan",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M12 8.5H7L4 11H3c-1.11 0-2 .89-2 2v3h2.17c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2h6.35c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2H23v-1c0-1.11-1.03-1.47-2-2zM5.25 12l2.25-2h4l4 2zM6 13.5A1.5 1.5 0 0 1 7.5 15A1.5 1.5 0 0 1 6 16.5A1.5 1.5 0 0 1 4.5 15A1.5 1.5 0 0 1 6 13.5m12 0a1.5 1.5 0 0 1 1.5 1.5a1.5 1.5 0 0 1-1.5 1.5a1.5 1.5 0 0 1-1.5-1.5a1.5 1.5 0 0 1 1.5-1.5'/%3E%3C/svg%3E",
            tags = {"NOUVEAU", "BEST SELLER"},
            description = "Une voiture de sport exclusive"
        },
        {
            name = "M4 Coupé",
            price = 2500,
            spawnName = "bmwm4",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M12 8.5H7L4 11H3c-1.11 0-2 .89-2 2v3h2.17c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2h6.35c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2H23v-1c0-1.11-1.03-1.47-2-2zM5.25 12l2.25-2h4l4 2zM6 13.5A1.5 1.5 0 0 1 7.5 15A1.5 1.5 0 0 1 6 16.5A1.5 1.5 0 0 1 4.5 15A1.5 1.5 0 0 1 6 13.5m12 0a1.5 1.5 0 0 1 1.5 1.5a1.5 1.5 0 0 1-1.5 1.5a1.5 1.5 0 0 1-1.5-1.5a1.5 1.5 0 0 1 1.5-1.5'/%3E%3C/svg%3E",
            tags = {"NOUVEAU", "PROMO"},
            description = "Une voiture de sport exclusive"
        },
        {
            name = "Avantabor",
            price = 2500,
            spawnName = "aventador",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M12 8.5H7L4 11H3c-1.11 0-2 .89-2 2v3h2.17c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2h6.35c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2H23v-1c0-1.11-1.03-1.47-2-2zM5.25 12l2.25-2h4l4 2zM6 13.5A1.5 1.5 0 0 1 7.5 15A1.5 1.5 0 0 1 6 16.5A1.5 1.5 0 0 1 4.5 15A1.5 1.5 0 0 1 6 13.5m12 0a1.5 1.5 0 0 1 1.5 1.5a1.5 1.5 0 0 1-1.5 1.5a1.5 1.5 0 0 1-1.5-1.5a1.5 1.5 0 0 1 1.5-1.5'/%3E%3C/svg%3E",
            tags = {"ALEZONTOP"},
            description = "Une voiture de sport exclusive"
        },
        {
            name = "G63 Wagon",
            price = 2500,
            spawnName = "g63amg",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M12 8.5H7L4 11H3c-1.11 0-2 .89-2 2v3h2.17c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2h6.35c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2H23v-1c0-1.11-1.03-1.47-2-2zM5.25 12l2.25-2h4l4 2zM6 13.5A1.5 1.5 0 0 1 7.5 15A1.5 1.5 0 0 1 6 16.5A1.5 1.5 0 0 1 4.5 15A1.5 1.5 0 0 1 6 13.5m12 0a1.5 1.5 0 0 1 1.5 1.5a1.5 1.5 0 0 1-1.5 1.5a1.5 1.5 0 0 1-1.5-1.5a1.5 1.5 0 0 1 1.5-1.5'/%3E%3C/svg%3E",
            tags = {"SALUT", "BEST SELLER"},
            description = "Une voiture de sport exclusive"
        },
        {
            name = "Chiroon",
            price = 2500,
            spawnName = "chiron",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M12 8.5H7L4 11H3c-1.11 0-2 .89-2 2v3h2.17c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2h6.35c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2H23v-1c0-1.11-1.03-1.47-2-2zM5.25 12l2.25-2h4l4 2zM6 13.5A1.5 1.5 0 0 1 7.5 15A1.5 1.5 0 0 1 6 16.5A1.5 1.5 0 0 1 4.5 15A1.5 1.5 0 0 1 6 13.5m12 0a1.5 1.5 0 0 1 1.5 1.5a1.5 1.5 0 0 1-1.5 1.5a1.5 1.5 0 0 1-1.5-1.5a1.5 1.5 0 0 1 1.5-1.5'/%3E%3C/svg%3E",
            tags = {"NOUVEAU", "BEST SELLER"},
            description = "Une voiture de sport exclusive"
        }
    },
    armes = {
        {
            name = "Pistolet",
            price = 1000,
            spawnName = "weapon_pistol",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M7 5h16v4h-1v1h-6a1 1 0 0 0-1 1v1a2 2 0 0 1-2 2H9.62c-.38 0-.73.22-.9.56l-2.45 4.89c-.17.34-.51.55-.89.55H2s-3 0 1-6c0 0 3-4-1-4V5h1l.5-1h3zm7 7v-1a1 1 0 0 0-1-1h-1s-1 1 0 2a2 2 0 0 1-2-2a1 1 0 0 0-1 1v1a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1'/%3E%3C/svg%3E",
            tags = {"PROMO"},
            description = "Pistolet précision accrue"
        }
    },
    packs = {
        {
            name = "Pack Débutant",
            price = 2000,
            spawnName = "starter_pack",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M21 16.5c0 .38-.21.71-.53.88l-7.9 4.44c-.16.12-.36.18-.57.18s-.41-.06-.57-.18l-7.9-4.44A.99.99 0 0 1 3 16.5v-9c0-.38.21-.71.53-.88l7.9-4.44c.16-.12.36-.18.57-.18s.41.06.57.18l7.9 4.44c.32.17.53.5.53.88zM12 4.15l-1.89 1.07L16 8.61l1.96-1.11zM6.04 7.5L12 10.85l1.96-1.1l-5.88-3.4zM5 15.91l6 3.38v-6.71L5 9.21zm14 0v-6.7l-6 3.37v6.71z'/%3E%3C/svg%3E",
            tags = {"BEST SELLER"},
            description = "Pack idéal pour bien démarrer",
            content = {
                vehicles = {
                    {
                        name = "Sultan RS",
                        model = "sultanrs",
                        image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M12 8.5H7L4 11H3c-1.11 0-2 .89-2 2v3h2.17c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2h6.35c.43 1.2 1.56 2 2.83 2s2.4-.8 2.82-2H23v-1c0-1.11-1.03-1.47-2-2zM5.25 12l2.25-2h4l4 2zM6 13.5A1.5 1.5 0 0 1 7.5 15A1.5 1.5 0 0 1 6 16.5A1.5 1.5 0 0 1 4.5 15A1.5 1.5 0 0 1 6 13.5m12 0a1.5 1.5 0 0 1 1.5 1.5a1.5 1.5 0 0 1-1.5 1.5a1.5 1.5 0 0 1-1.5-1.5a1.5 1.5 0 0 1 1.5-1.5'/%3E%3C/svg%3E"
                    }
                },
                weapons = {
                    {
                        name = "Pistolet",
                        model = "weapon_pistol",
                        ammo = 100,
                        image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M7 5h16v4h-1v1h-6a1 1 0 0 0-1 1v1a2 2 0 0 1-2 2H9.62c-.38 0-.73.22-.9.56l-2.45 4.89c-.17.34-.51.55-.89.55H2s-3 0 1-6c0 0 3-4-1-4V5h1l.5-1h3zm7 7v-1a1 1 0 0 0-1-1h-1s-1 1 0 2a2 2 0 0 1-2-2a1 1 0 0 0-1 1v1a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1'/%3E%3C/svg%3E"
                    }
                },
                items = {
                    {
                        name = "Pain",
                        item = "bread",
                        count = 5,
                        image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M12 2c5.5 0 10 3.36 10 7.5c0 1.69-.74 3.25-2 4.5v8H4v-8c-1.26-1.25-2-2.81-2-4.5C2 5.36 6.5 2 12 2M8 18h4v-4H8z'/%3E%3C/svg%3E"
                    },
                    {
                        name = "Eau",
                        item = "water",
                        count = 3,
                        image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M18.32 8H5.67l-.44-4h13.54M12 19a3 3 0 0 1-3-3c0-2 3-5.4 3-5.4s3 3.4 3 5.4a3 3 0 0 1-3 3M3 2l2 18.23c.13 1 .97 1.77 2 1.77h10c1 0 1.87-.77 2-1.77L21 2z'/%3E%3C/svg%3E"
                    }
                }
            }
        }
    },
    consommables = {
        {
            name = "Pain",
            price = 100,
            spawnName = "bread",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M12 2c5.5 0 10 3.36 10 7.5c0 1.69-.74 3.25-2 4.5v8H4v-8c-1.26-1.25-2-2.81-2-4.5C2 5.36 6.5 2 12 2M8 18h4v-4H8z'/%3E%3C/svg%3E",
            tags = {"NOURRITURE"},
            description = "Du pain frais pour vous restaurer"
        },
        {
            name = "Eau",
            price = 50,
            spawnName = "water",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M18.32 8H5.67l-.44-4h13.54M12 19a3 3 0 0 1-3-3c0-2 3-5.4 3-5.4s3 3.4 3 5.4a3 3 0 0 1-3 3M3 2l2 18.23c.13 1 .97 1.77 2 1.77h10c1 0 1.87-.77 2-1.77L21 2z'/%3E%3C/svg%3E",
            tags = {"BOISSON"},
            description = "Une bouteille d'eau fraîche"
        }
    },
    munitions = {
        -- Munitions Légères (ammo_pistol) : pistolets, revolvers
        {
            name = "Munitions Légères x50",
            price = 300,
            spawnName = "munitions_legere_50",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M14 22h-4v-1h4zm-1-12V7h-2v3l-1 1.5V20h4v-8.5zm-1-8s-1 1-1 3v1h2V5s0-2-1-3'/%3E%3C/svg%3E",
            claimItem = "ammo_pistol",
            claimCount = 50,
            tags = {"LÉGÈRE"},
            description = "50 munitions pour pistolets et revolvers"
        },
        {
            name = "Munitions Légères x100",
            price = 500,
            spawnName = "munitions_legere_100",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M14 22h-4v-1h4zm-1-12V7h-2v3l-1 1.5V20h4v-8.5zm-1-8s-1 1-1 3v1h2V5s0-2-1-3'/%3E%3C/svg%3E",
            claimItem = "ammo_pistol",
            claimCount = 100,
            tags = {"LÉGÈRE", "POPULAIRE"},
            description = "100 munitions pour pistolets et revolvers"
        },
        {
            name = "Munitions Légères x250",
            price = 800,
            spawnName = "munitions_legere_250",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M14 22h-4v-1h4zm-1-12V7h-2v3l-1 1.5V20h4v-8.5zm-1-8s-1 1-1 3v1h2V5s0-2-1-3'/%3E%3C/svg%3E",
            claimItem = "ammo_pistol",
            claimCount = 250,
            tags = {"LÉGÈRE", "BEST SELLER"},
            description = "250 munitions pour pistolets et revolvers"
        },
        -- Munitions Moyennes (ammo_rifle) : SMG, rifles
        {
            name = "Munitions Moyennes x50",
            price = 400,
            spawnName = "munitions_moyenne_50",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M14 22h-4v-1h4zm-1-12V7h-2v3l-1 1.5V20h4v-8.5zm-1-8s-1 1-1 3v1h2V5s0-2-1-3'/%3E%3C/svg%3E",
            claimItem = "ammo_rifle",
            claimCount = 50,
            tags = {"MOYENNE"},
            description = "50 munitions pour SMG et fusils d'assaut"
        },
        {
            name = "Munitions Moyennes x100",
            price = 625,
            spawnName = "munitions_moyenne_100",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M14 22h-4v-1h4zm-1-12V7h-2v3l-1 1.5V20h4v-8.5zm-1-8s-1 1-1 3v1h2V5s0-2-1-3'/%3E%3C/svg%3E",
            claimItem = "ammo_rifle",
            claimCount = 100,
            tags = {"MOYENNE", "POPULAIRE"},
            description = "100 munitions pour SMG et fusils d'assaut"
        },
        {
            name = "Munitions Moyennes x250",
            price = 900,
            spawnName = "munitions_moyenne_250",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M14 22h-4v-1h4zm-1-12V7h-2v3l-1 1.5V20h4v-8.5zm-1-8s-1 1-1 3v1h2V5s0-2-1-3'/%3E%3C/svg%3E",
            claimItem = "ammo_rifle",
            claimCount = 250,
            tags = {"MOYENNE", "BEST SELLER"},
            description = "250 munitions pour SMG et fusils d'assaut"
        },
        -- Cartouches de Pompe (ammo_shotgun)
        {
            name = "Cartouches de Pompe x30",
            price = 350,
            spawnName = "munitions_pompe_30",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M14 22h-4v-1h4zm-1-12V7h-2v3l-1 1.5V20h4v-8.5zm-1-8s-1 1-1 3v1h2V5s0-2-1-3'/%3E%3C/svg%3E",
            claimItem = "ammo_shotgun",
            claimCount = 30,
            tags = {"POMPE"},
            description = "30 cartouches pour fusils à pompe"
        },
        {
            name = "Cartouches de Pompe x50",
            price = 500,
            spawnName = "munitions_pompe_50",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M14 22h-4v-1h4zm-1-12V7h-2v3l-1 1.5V20h4v-8.5zm-1-8s-1 1-1 3v1h2V5s0-2-1-3'/%3E%3C/svg%3E",
            claimItem = "ammo_shotgun",
            claimCount = 50,
            tags = {"POMPE", "POPULAIRE"},
            description = "50 cartouches pour fusils à pompe"
        },
        {
            name = "Cartouches de Pompe x100",
            price = 850,
            spawnName = "munitions_pompe_100",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M14 22h-4v-1h4zm-1-12V7h-2v3l-1 1.5V20h4v-8.5zm-1-8s-1 1-1 3v1h2V5s0-2-1-3'/%3E%3C/svg%3E",
            claimItem = "ammo_shotgun",
            claimCount = 100,
            tags = {"POMPE", "BEST SELLER"},
            description = "100 cartouches pour fusils à pompe"
        }
    },
    peds = {
        {
            name = "Berger Allemand",
            price = 1500,
            spawnName = "a_c_shepherd",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M18 4c-1.71 0-2.75.33-3.35.61C13.88 4.23 13 4 12 4s-1.88.23-2.65.61C8.75 4.33 7.71 4 6 4c-3 0-5 8-5 10c0 .83 1.32 1.59 3.14 1.9c.64 2.24 3.66 3.95 7.36 4.1v-4.28c-.59-.37-1.5-1.04-1.5-1.72c0-1 2-1 2-1s2 0 2 1c0 .68-.91 1.35-1.5 1.72V20c3.7-.15 6.72-1.86 7.36-4.1C21.68 15.59 23 14.83 23 14c0-2-2-10-5-10M4.15 13.87c-.5-.12-.89-.26-1.15-.37c.25-2.77 2.2-7.1 3.05-7.5c.54 0 .95.06 1.32.11c-2.1 2.31-2.93 5.93-3.22 7.76M9 12a1 1 0 0 1-1-1c0-.54.45-1 1-1a1 1 0 0 1 1 1c0 .56-.45 1-1 1m6 0a1 1 0 0 1-1-1c0-.54.45-1 1-1a1 1 0 0 1 1 1c0 .56-.45 1-1 1m4.85 1.87c-.29-1.83-1.12-5.45-3.22-7.76c.37-.05.78-.11 1.32-.11c.85.4 2.8 4.73 3.05 7.5c-.25.11-.64.25-1.15.37'/%3E%3C/svg%3E",
            tags = {"NOUVEAU"},
            description = "Transformez-vous en berger allemand"
        },
        {
            name = "Husky",
            price = 1500,
            spawnName = "a_c_husky",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='white' d='M18 4c-1.71 0-2.75.33-3.35.61C13.88 4.23 13 4 12 4s-1.88.23-2.65.61C8.75 4.33 7.71 4 6 4c-3 0-5 8-5 10c0 .83 1.32 1.59 3.14 1.9c.64 2.24 3.66 3.95 7.36 4.1v-4.28c-.59-.37-1.5-1.04-1.5-1.72c0-1 2-1 2-1s2 0 2 1c0 .68-.91 1.35-1.5 1.72V20c3.7-.15 6.72-1.86 7.36-4.1C21.68 15.59 23 14.83 23 14c0-2-2-10-5-10M4.15 13.87c-.5-.12-.89-.26-1.15-.37c.25-2.77 2.2-7.1 3.05-7.5c.54 0 .95.06 1.32.11c-2.1 2.31-2.93 5.93-3.22 7.76M9 12a1 1 0 0 1-1-1c0-.54.45-1 1-1a1 1 0 0 1 1 1c0 .56-.45 1-1 1m6 0a1 1 0 0 1-1-1c0-.54.45-1 1-1a1 1 0 0 1 1 1c0 .56-.45 1-1 1m4.85 1.87c-.29-1.83-1.12-5.45-3.22-7.76c.37-.05.78-.11 1.32-.11c.85.4 2.8 4.73 3.05 7.5c-.25.11-.64.25-1.15.37'/%3E%3C/svg%3E",
            tags = {"POPULAIRE"},
            description = "Transformez-vous en husky"
        }
    },
    vip = {
        {
            name = "VIP Bronze",
            spawnName = "vip_tier_1",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='%23cd7f32' d='M20 2H4v2l5.81 4.36a7.004 7.004 0 0 0-4.46 8.84a6.996 6.996 0 0 0 8.84 4.46a7 7 0 0 0 0-13.3L20 4zm-5.06 17.5L12 17.78L9.06 19.5l.78-3.33l-2.59-2.24l3.41-.29L12 10.5l1.34 3.14l3.41.29l-2.59 2.24z'/%3E%3C/svg%3E",
            tags = {"POPULAIRE"},
            description = "Débloquez des avantages exclusifs avec le VIP Bronze",
            vipTier = 1,
            tebexUrl = "https://eve-rp.fr/boutique",
            color = "#CD7F32",
            advantages = {
                "500 Coins offerts chaque mois",
                "10 Coins par heure de jeu",
                "40kg de capacite d'inventaire (+10kg)",
                "3000$ d'aide d'etat toutes les 30 minutes",
                "30% de réduction à la fourrière",
                "+30% coffre vehicule",
                "+30% stockage Dynasty",
                "2 emplacements de personnage",
                "10 objets permanents / 5 objets temporaires",
                "Interim : gains x1.3",
                "Go Fast : gains x1.2",
                "Vente de drogue : gains x1.15",
                "Peche automatique sans mini-jeu",
                "1 changement de plaque / mois",
                "Véhicule d'urgence personnel",
                "Vehicule mensuel gratuit (commun)",
                "GPS de localisation de vehicules (dans le telephone)",
                "Role Discord VIP Bronze"
            }
        },
        {
            name = "VIP Silver",
            spawnName = "vip_tier_2",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='%23c0c0c0' d='M17 4V2H7v2H2v7c0 1.1.9 2 2 2h3.1a5.01 5.01 0 0 0 3.9 3.9v2.18C8 19.54 8 22 8 22h8s0-2.46-3-2.92V16.9a5.01 5.01 0 0 0 3.9-3.9H20c1.1 0 2-.9 2-2V4zM4 11V6h3v5zm16 0h-3V6h3z'/%3E%3C/svg%3E",
            tags = {"BEST SELLER"},
            description = "Profitez d'avantages améliorés avec le VIP Silver",
            vipTier = 2,
            tebexUrl = "https://eve-rp.fr/boutique",
            color = "#C0C0C0",
            advantages = {
                "1000 Coins offerts chaque mois",
                "20 Coins par heure de jeu",
                "50kg de capacite d'inventaire (+20kg)",
                "4000$ d'aide d'etat toutes les 30 minutes",
                "40% de réduction à la fourrière",
                "+50% coffre vehicule",
                "+50% stockage Dynasty",
                "2 emplacements de personnage",
                "20 objets permanents / 10 objets temporaires",
                "Interim : gains x1.7",
                "Go Fast : gains x1.5",
                "Vente de drogue : gains x1.3",
                "Peche automatique sans mini-jeu",
                "2 changements de plaque / mois",
                "Véhicule d'urgence personnel",
                "Vehicule mensuel gratuit (rare)",
                "GPS de localisation de vehicules (dans le telephone)",
                "Permis de port d'armes disponible",
                "Role Discord VIP Silver"
            }
        },
        {
            name = "VIP Gold",
            spawnName = "vip_tier_3",
            image = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='%23ffd700' d='M5 16L3 5l5.5 5L12 4l3.5 6L21 5l-2 11zm14 3c0 .6-.4 1-1 1H6c-.6 0-1-.4-1-1v-1h14z'/%3E%3C/svg%3E",
            tags = {"PREMIUM", "ULTIMATE"},
            description = "L'expérience VIP ultime avec tous les avantages",
            vipTier = 3,
            tebexUrl = "https://eve-rp.fr/boutique",
            color = "#FFD700",
            advantages = {
                "1500 Coins offerts chaque mois",
                "30 Coins par heure de jeu",
                "60kg de capacite d'inventaire (+30kg)",
                "5000$ d'aide d'etat toutes les 30 minutes",
                "50% de réduction à la fourrière",
                "+100% coffre vehicule",
                "+100% stockage Dynasty",
                "2 emplacements de personnage",
                "30 objets permanents / 15 objets temporaires",
                "Interim : gains x2",
                "Go Fast : gains x2",
                "Vente de drogue : gains x2",
                "Peche automatique sans mini-jeu",
                "3 changements de plaque / mois",
                "Véhicule d'urgence personnel",
                "Vehicule mensuel gratuit (premium)",
                "GPS de localisation de vehicules (dans le telephone)",
                "Permis de port d'armes garanti",
                "Acces prioritaire aux evenements",
                "Role Discord VIP Gold"
            }
        }
    }
}

-- Vehicle preview location
PaidShopConfig.PreviewLocation = {
    coords = vector4(-1095.51, -3196.6, 13.94, 60.0),
    camera = {
        offset = vector3(3.0, 3.0, 2.0),
        fov = 50.0
    }
}

-- Database configuration
PaidShopConfig.Database = {
    vehicleTable = 'owned_vehicles'
}

-- Weapon configuration (true = give weapon as item, false = give weapon directly)
PaidShopConfig.WeaponItem = true

-- Bonus quotidien streak 7 jours (ActivityRail).
-- Le joueur progresse dans un cycle 1→7 ; chaque claim avance d'un cran (le
-- streak ne reset pas s'il loupe un jour : il reprend où il en était).
-- Une seule récompense par jour calendaire (cooldown 24h, vérifié serveur).
--
-- Types supportés par slot :
--   { type = "spacecoins", amount = 50 }
--   { type = "money",      amount = 5000 }
--   { type = "item",       item = "bread", count = 5, label = "Pain x5" }
--   { type = "vehicle",    vehicle = "sultan", label = "Sultan" }
--
-- `label`  : texte court affiché dans le bouton "Réclamer" (auto si omis pour money/SC).
-- `icon`   : (optionnel) classe FontAwesome pour la cellule de jour.
PaidShopConfig.DailyBonus = {
    -- Conservé pour compat (legacy) — équivaut au montant du jour 3
    CoinsAmount = 50,

    -- 7 slots configurables via le builder admin (override .json en runtime,
    -- voir SPaidShop.lua / paidshop:getDailyStreak / paidshop:editDailyStreakSlot)
    StreakRewards = {
        [1] = { type = "spacecoins", amount = 25,  label = "25 SC" },
        [2] = { type = "spacecoins", amount = 35,  label = "35 SC" },
        [3] = { type = "spacecoins", amount = 50,  label = "50 SC" },
        [4] = { type = "spacecoins", amount = 75,  label = "75 SC" },
        [5] = { type = "spacecoins", amount = 100, label = "100 SC" },
        [6] = { type = "spacecoins", amount = 150, label = "150 SC" },
        [7] = { type = "spacecoins", amount = 250, label = "Jackpot 250 SC" },
    },
}

-- "Pour Moi" — sélection personnelle quotidienne pondérée par rareté.
-- Rotation : minuit (timezone serveur). Génération lazy à l'ouverture de la
-- boutique. Voir docs/plans/2026-05-05-paidshop-pour-moi-refactor-design.md
PaidShopConfig.PourMoi = {
    -- Nombre d'items dans la sélection par tier VIP
    SizeByVip = {
        [0] = 6,   -- Aucun
        [1] = 7,   -- Bronze
        [2] = 8,   -- Silver
        [3] = 10,  -- Gold
    },

    -- Poids de tirage par tier VIP × rareté
    WeightsByVip = {
        [0] = { common = 50, uncommon = 25, rare = 15, epic = 7,  legendary = 3 },
        [1] = { common = 48, uncommon = 25, rare = 16, epic = 8,  legendary = 3 },
        [2] = { common = 45, uncommon = 25, rare = 17, epic = 9,  legendary = 4 },
        [3] = { common = 42, uncommon = 25, rare = 18, epic = 10, legendary = 5 },
    },

    -- Cap réduction max (anti-erreur admin lors de la saisie)
    MaxReductionPercent = 90,

    -- Catégories non-éligibles comme source pour le pool Pour-moi
    BlockedSourceCategories = { "pour_moi", "vip", "daily_reward" },
}

-- Rarity colors for case items
PaidShopConfig.RarityColors = {
    common = "#b0b0b0",
    uncommon = "#6bdb6b",
    rare = "#4a90e2",
    epic = "#b24ae2",
    legendary = "#f4b245"
}
