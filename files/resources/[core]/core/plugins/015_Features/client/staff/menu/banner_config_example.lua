---@meta _
--- Example configuration for custom admin menu banners
--- This file shows how to customize the banner image for the administration menu

-- ============================================
-- HOW TO USE CUSTOM BANNERS
-- ============================================

-- The banner system now supports both local and external URLs
-- The VUI system has been modified to detect and handle full URLs

-- OPTION 1: Use default banner from GitHub CDN (no configuration needed)
-- The default banner uses the GitHub CDN URL:
-- VFW.CDN.Get("banners/f5.png")

-- OPTION 2: Set a custom banner using full URL
-- Example: To use a different banner from GitHub
-- Uncomment and modify the following line in _manager.lua:
-- StaffMenu.Config.customBanner = VFW.CDN.Get("banners/custom_admin.png")

-- OPTION 3: Use a banner from any external source
-- Example: To use a banner from a different CDN
-- StaffMenu.Config.customBanner = "https://example.com/images/my-banner.png"

-- OPTION 4: Use local VUI banner (without URL)
-- If you just provide a name without http/https, it will use the local VUI assets
-- StaffMenu.Config.customBanner = "administration" -- Will use nui://vui/web/dist/assets/banners/administration.webp

-- OPTION 5: Dynamically change banner based on conditions
-- You can modify the banner at runtime before opening the menu:
--[[
if someCondition then
    StaffMenu.Config.customBanner = VFW.CDN.Get("banners/special_event.png")
else
    StaffMenu.Config.customBanner = VFW.CDN.Get("banners/f5.png")
end
]]

-- OPTION 6: Different banners for different menus
-- You can use different banner URLs for each menu:
--[[
local mainBanner = VFW.CDN.Get("banners/administration.png")
local reportsBanner = VFW.CDN.Get("banners/reports.png")
local playersBanner = VFW.CDN.Get("banners/players.png")

-- Then use them when creating menus:
StaffMenu.main = VUI:CreateMenu("MENU ADMINISTRATION", mainBanner, true)
StaffMenu.reports = VUI:CreateSubMenu(StaffMenu.main, "REPORTS", reportsBanner, true)
StaffMenu.players = VUI:CreateSubMenu(StaffMenu.main, "JOUEURS", playersBanner, true)
]]

-- ============================================
-- BANNER IMAGE RECOMMENDATIONS
-- ============================================
-- Recommended image dimensions: 512x128 pixels (or similar aspect ratio)
-- Supported formats: PNG, JPG, GIF, WEBP
-- File size: Keep under 500KB for optimal loading
-- Transparency: PNG with transparency is supported

-- ============================================
-- TROUBLESHOOTING
-- ============================================
-- 1. If banner doesn't load, check:
--    - The image URL is accessible (test in browser)
--    - The URL uses HTTPS (required for security)
--    - The image format is supported

-- 2. To test a banner URL:
--    - Open your browser
--    - Navigate to the full URL
--    - If you can see the image, it should work in-game

-- 3. Debug the current banner URL:
--    print("Current banner URL:", StaffMenu.GetBannerURL())