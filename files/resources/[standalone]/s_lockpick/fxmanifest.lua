-- shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'

description 'Vehicle lockpick mini-game (export-only, NUI)'
version '2.1.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/style.css',
    'html/reset.css',
    'html/assets/*.png',
    'html/assets/*.js',
}

client_scripts {
    'cl.lua',
}
