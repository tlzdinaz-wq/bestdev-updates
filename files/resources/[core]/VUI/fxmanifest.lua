-- shared_script '@WaveShield/resource/include.lua'

fx_version "cerulean"
game "gta5"

-- NUI des menus : bundle web/dist habille par assets/skin.css (source hors de la base).
-- web/app est une page alternative, non chargee.
ui_page 'web/dist/index.html'

files {
	'web/app/index.html',
	'web/app/assets/*',
	'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
    'web/dist/assets/*.mp3',
    'web/dist/assets/banners/*.webp',
    'web/dist/assets/icons/*.webp',
    'web/dist/assets/sounds/*.mp3',
}

client_scripts {
    'vui.lua',
    'callbacks.lua',
    'keybinds.lua',
}

server_scripts {}

exports {
    'CreateMenu',
    'CreateSubMenu',
    'OpenWithReturn',
    'OpenInHub',
    'IsHubMode',
    'ToggleStaffAlert',
    'SetSoundEnabled',
    'GetMenuPosition',
    'SetMenuPosition',
    'GetMenuOffset',
    'SetMenuOffset',
    'GetPreviewOffset',
    'SetPreviewOffset',
    'SetMenuOrientation',
    'GetMaxItems',
    'SetMaxItems',
    'CloseAll',
}
