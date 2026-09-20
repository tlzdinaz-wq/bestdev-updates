---@meta _
---@diagnostic disable: duplicate-doc-field

local hasgear = false
local TankObject
local MaskObject

--- GearAnim
local function GearAnim()
    VFW.Streaming.RequestAnimDict("clothingshirt")
    TaskPlayAnim(PlayerPedId(), "clothingshirt", "try_shirt_positive_d", 8.0, 1.0, -1, 49, 0, 0, 0, 0)
end


