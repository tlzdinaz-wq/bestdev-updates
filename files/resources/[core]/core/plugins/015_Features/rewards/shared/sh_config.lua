Rewards = Rewards or {}

Rewards.Themes = {
    DEFAULT = 1,
    CHRISTMAS = 2,
    VALENTINE = 3,
    HALLOWEEN = 4,
    SUMMER = 5,
}

Rewards.ThemeNames = {
    [1] = "default",
    [2] = "christmas",
    [3] = "valentine",
    [4] = "halloween",
    [5] = "summer",
}

Rewards.MonthToTheme = {
    [1] = Rewards.Themes.DEFAULT,
    [2] = Rewards.Themes.VALENTINE,
    [3] = Rewards.Themes.DEFAULT,
    [4] = Rewards.Themes.DEFAULT,
    [5] = Rewards.Themes.DEFAULT,
    [6] = Rewards.Themes.SUMMER,
    [7] = Rewards.Themes.SUMMER,
    [8] = Rewards.Themes.SUMMER,
    [9] = Rewards.Themes.DEFAULT,
    [10] = Rewards.Themes.HALLOWEEN,
    [11] = Rewards.Themes.DEFAULT,
    [12] = Rewards.Themes.CHRISTMAS,
}

-- Cooldowns for each track (in milliseconds)
Rewards.RegularCooldown = 86400000  -- 24 hours for regular gifts
Rewards.VIPCooldown = 86400000      -- 24 hours for VIP gifts

-- Legacy cooldowns (deprecated, kept for backward compatibility)
Rewards.DefaultCooldown = 86400000

Rewards.VIPPermission = "vip_bronze"
Rewards.VIPPlusPermission = "vip_silver"

Rewards.ProgressionMode = "sequential"
Rewards.AllowEmptyDays = true

Rewards.ResetOnThemeChange = true
Rewards.KeepHistory = true

Rewards.ShowLoginNotification = true
Rewards.ShowClaimNotification = true

Rewards.PlayerCommand = "rewards"
Rewards.PlayerCommandAlias = "dailyrewards"
