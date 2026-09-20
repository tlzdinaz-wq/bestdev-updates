VigneronConfig = {
    harvest = {
        vec3(-1859.4, 2097.59, 137.81),
        vec3(-1876.34, 2098.12, 138.76),
        vec3(-1881.76, 2098.67, 138.74),
        vec3(-1890.62, 2099.63, 137.82),
        vec3(-1900.81, 2100.2, 135.71),
        vec3(-1903.96, 2100.99, 134.56),
        vec3( -1909.98, 2101.23, 132.75),
        vec3(-1850.87, 2101.61, 137.59),
        vec3(-1842.91, 2105.22, 137.54),
        vec3(-1833.54, 2109.36, 136.16)
    },
    processing = {
        ["white_grapes"] = vec3(-1931.32, 2058.18, 139.77),
        ["red_grapes"] = vec3(-1931.92, 2055.43, 139.75),
        ["yellow_grapes"] = vec3(-1932.47, 2052.63, 139.77),
    },
    items = {
        harvest = {
            "white_grapes",
            "red_grapes",
            "yellow_grapes"
        },
        process = {
            ["white_grapes"] = "wine_white",
            ["red_grapes"] = "wine_red",
            ["yellow_grapes"] = "wine_yellow"
        }
    }
}