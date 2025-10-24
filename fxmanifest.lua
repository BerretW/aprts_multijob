fx_version 'cerulean'
lua54 'yes'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'SpoiledMouse'
version '1.0'
description 'aprts_multijob'

games {"rdr3"}

client_scripts {'config.lua','client/client.lua','client/events.lua','client/renderer.lua','client/visualizer.lua','client/commands.lua','client/menu.lua'}
server_scripts {'@oxmysql/lib/MySQL.lua','config.lua','server/server.lua','server/events.lua','server/commands.lua',}
shared_scripts {
    'config.lua',
    '@jo_libs/init.lua',
    '@ox_lib/init.lua'
}


ui_page "nui://jo_libs/nui/menu/index.html"

escrow_ignore {
    'config.lua'
  }