fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'EnderDevelopment'
description 'Realistic tire replacement system for ESX + ox_target + ox_lib'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/animations.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/items.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'es_extended',
    'ox_inventory',
}
