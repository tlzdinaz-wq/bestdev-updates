local function installedBaseVersion()
    -- Read the installed release, not the latest release available online.
    -- The publisher and update.bat/update.sh maintain this file automatically.
    local ok, state = pcall(LoadResourceFile, "updater", "state.txt")
    if ok and type(state) == "string" then
        local version = state:match("^#version[\t ]+([^\t\r\n ]+)")
        if version and version:match("^%d+%.%d+%.%d+$") then return version end
    end

    -- Older distributed archives stored the same information as JSON.
    local readOk, raw = pcall(LoadResourceFile, "updater", "state.json")
    if readOk and type(raw) == "string" and raw ~= "" then
        local decodedOk, decoded = pcall(json.decode, raw)
        local version = decodedOk and type(decoded) == "table" and decoded.version
        if type(version) == "string" and version:match("^%d+%.%d+%.%d+$") then return version end
    end
    return nil
end

local baseVersion = installedBaseVersion()
print("")
print("^5  Version de la base : ^7" .. (baseVersion and ("v" .. baseVersion) or "non renseignée"))
print("^6")
print("  ██████╗ ███████╗███████╗████████╗    ██████╗ ███████╗██╗   ██╗")
print("  ██╔══██╗██╔════╝██╔════╝╚══██╔══╝    ██╔══██╗██╔════╝██║   ██║")
print("  ██████╔╝█████╗  ███████╗   ██║       ██║  ██║█████╗  ██║   ██║")
print("  ██╔══██╗██╔══╝  ╚════██║   ██║       ██║  ██║██╔══╝  ╚██╗ ██╔╝")
print("  ██████╔╝███████╗███████║   ██║       ██████╔╝███████╗ ╚████╔╝")
print("  ╚═════╝ ╚══════╝╚══════╝   ╚═╝       ╚═════╝ ╚══════╝  ╚═══╝")
print("^5                    ✦  B E S T   D E V  ✦^7")
print("")
