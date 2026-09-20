shared_script '@WaveShield/resource/include.lua'
shared_script '@WaveShield/resource/waveshield.js'

fx_version 'cerulean'

game 'gta5'
lua54 'yes'
version '1.12.11'

ui_page "interface/build/index.html"

files {
    'imports.lua',
    "interface/build/index.html",
    "interface/build/**/*",
    "interface/brand/**/*",
    "interface/hud/index.html",
    "interface/hud/**/*",
    -- Hub de gestion staff (NUI autonome embarqué en iframe dans l'interface)
    "interface/gestion/index.html",
    "interface/gestion/**/*",
    -- Annonces entreprise (tablette patron)
    "interface/boss-announces/index.html",
    "interface/boss-announces/**/*",
    "interface/pausemenu/index.html",
    "interface/pausemenu/**/*",
    "interface/boutique/index.html",
    "interface/boutique/**/*",
    "interface/documents/index.html",
    "interface/documents/**/*",
    'modules/dui/index.html',
    'modules/dui/assets/*',
    'modules/dui/icons/*.svg',
    'modules/loadingscreen/*',
    'modules/loadingscreen/**/*',
    'stream/**.ytyp',
    'stream/**.MP3',
    'stream/beanbag/common/*.meta',
    'plugins/015_Features/ui/weazel/**/*',
    'plugins/015_Features/ui/lifeinvader/**/*',
    'plugins/015_Features/ui/taxi-app/**/*',
    -- Scam Computer (NUI autonome embarqué en iframe dans l'interface)
    'plugins/015_Features/scam_computer/html/**/*',
    'modules/sirens/web/build/index.html',
    'modules/sirens/web/build/**/*',
    'modules/sirens/visualsettings.dat',
    'modules/sirens/audio/data/clem_sirens.dat54.rel',
    'modules/sirens/audio/dlc_clem/clem.awc',
}

loadscreen 'modules/loadingscreen/index.html'
loadscreen_cursor 'yes'
loadscreen_manual_shutdown 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    -- Configs racine (env, branding, colors, icons...) — chargées en PREMIER
    'config/*.lua',
    -- Configs sous-dossiers (framework, permissions, fuel, vehicles...) — chargées APRÈS
    'config/**/*.lua',
    'plugins/015_Features/config/paidshop.lua',
    "modules/**/shared/*.lua",
    "plugins/**/shared/**",
    "jobs/**/shared/**"
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    -- Mode serveur de test : DOIT être chargé en premier pour envelopper
    -- l'enregistrement des events/commandes avant tout module/plugin.
    'testserver/server/guard.lua',
    'testserver/server/permissions.lua',
    "endernative/server/*.lua",
    "modules/**/server/*.lua",
    "modules/**/server/submodules/*.lua",
    "plugins/000_framework/server/001_command_sync.lua",
    "plugins/**/server/**",
    "jobs/**/server/**",
}

client_scripts {
    "nui_gate.lua",
    "endernative/client/*.lua",
    "modules/**/client/*.lua",
    "modules/**/client/submodules/*.lua",
    "plugins/**/client/**",
    "jobs/**/client/**"
}


data_file 'DLC_ITYP_REQUEST' 'stream/**.ytyp'
data_file 'WEAPON_ANIMATIONS_FILE' 'stream/beanbag/common/weaponanimations.meta'
data_file 'WEAPONINFO_FILE' 'stream/beanbag/common/weapons.meta'
data_file 'WEAPON_METADATA_FILE' 'stream/beanbag/common/weaponarchetypes.meta'
data_file 'DLCTEXT_FILE' 'stream/beanbag/common/dlctext.meta'
data_file 'CONTENT_UNLOCKING_META_FILE' 'stream/beanbag/common/contentunlocks.meta'

-- Banque audio des sirènes
data_file 'AUDIO_WAVEPACK' 'modules/sirens/audio/dlc_clem'
data_file 'AUDIO_SOUNDDATA' 'modules/sirens/audio/data/clem_sirens.dat'

dependencies {
    '/native:0x6AE51D4B',
    '/native:0xA61C8FC6',
    '/assetpacks',
    'VUI'
}
