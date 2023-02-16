fx_version 'cerulean'
game 'gta5'

author 'Shootalot#5812'
description 'sl-dealerships: Dealerships Script | Started Development: Feb. 13th, 2023'
version '1.0'

shared_script 'config.lua'

client_script {
    'client/cl_ottos.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_main.lua'
}

lua54 'yes'