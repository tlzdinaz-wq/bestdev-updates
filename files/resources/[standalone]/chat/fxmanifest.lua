fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'chat'
description 'Chat du serveur (T) : messages, commandes avec complétion, même API que la ressource chat de cfx'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/assets/*',
}

client_script 'client.lua'
server_script 'server.lua'
