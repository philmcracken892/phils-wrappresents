fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

author 'phil'
description 'Christmas Present System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    
    'client/client.lua'
}

server_scripts {
    
    'server/server.lua'
}

dependencies {
    'rsg-core',
    'rsg-inventory',
    'ox_lib'
}

lua54 'yes'


