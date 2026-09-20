---@meta _
---@diagnostic disable: duplicate-doc-field

Config.ClothesFaction = {
    ["Homme"] = {
---@class Hat
        Hat = {},
---@class Glases
        Glases = {},
---@class Top
        Top = {},
---@class Leg
        Leg = {},
---@class Bag
        Bag = {},
---@class Sous
        Sous = {},
---@class Arm
        Arm = {},
---@class Cou
        Cou = {},
---@class Shoes
        Shoes = {},
    },
    ["Femme"] = {
---@class Hat
        Hat = {},
---@class Glases
        Glases = {},
---@class Top
        Top = {},
---@class Leg
        Leg = {},
---@class Bag
        Bag = {},
---@class Sous
        Sous = {},
---@class Arm
        Arm = {},
---@class Cou
        Cou = {},
---@class Shoes
        Shoes = {},
    }
}

for i = 36, 255 do
    table.insert(Config.ClothesFaction["Femme"].Hat, i)
end

for i = 0, 139 do
    table.insert(Config.ClothesFaction["Femme"].Glases, i)
end

for i = 541, 678 do
    table.insert(Config.ClothesFaction["Femme"].Top, i)
end

for i = 85, 241 do
    table.insert(Config.ClothesFaction["Femme"].Leg, i)
end

for i = 110, 174 do
    table.insert(Config.ClothesFaction["Femme"].Bag, i)
end

for i = 252, 336 do
    table.insert(Config.ClothesFaction["Femme"].Sous, i)
end

for i = 0, 369 do
    table.insert(Config.ClothesFaction["Femme"].Arm, i)
end

for i = 94, 180 do
    table.insert(Config.ClothesFaction["Femme"].Cou, i)
end

for i = 0, 342 do
    table.insert(Config.ClothesFaction["Femme"].Shoes, i)
end

for i = 114, 279 do
    table.insert(Config.ClothesFaction["Homme"].Hat, i)
end

for i = 0, 139 do
    table.insert(Config.ClothesFaction["Homme"].Glases, i)
end

for i = 532, 740 do
    table.insert(Config.ClothesFaction["Homme"].Top, i)
end

for i = 199, 240 do
    table.insert(Config.ClothesFaction["Homme"].Leg, i)
end

for i = 116, 190 do
    table.insert(Config.ClothesFaction["Homme"].Bag, i)
end

for i = 121, 322 do
    table.insert(Config.ClothesFaction["Homme"].Sous, i)
end

for i = 0, 369 do
    table.insert(Config.ClothesFaction["Homme"].Arm, i)
end

for i = 124, 232 do
    table.insert(Config.ClothesFaction["Homme"].Cou, i)
end

for i = 0, 342 do
    table.insert(Config.ClothesFaction["Homme"].Shoes, i)
end
