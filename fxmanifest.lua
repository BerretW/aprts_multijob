fx_version 'cerulean'
lua54 'yes'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'SpoiledMouse'
version '1.2'
description 'aprts_multijob with NUI'

games {"rdr3"}

-- NUI soubory
ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Client scripty (menu.lua je nahrazeno nui_handler.lua)
client_scripts {
    'config.lua',
    'client/client.lua',
    'client/events.lua',
    'client/nui_handler.lua', -- NOVÝ soubor místo menu.lua
    'client/renderer.lua',
    'client/visualizer.lua',
    'client/commands.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/server.lua',
    'server/events.lua',
    'server/commands.lua',
}
shared_scripts {
    'config.lua',
    '@ox_lib/init.lua' -- jo_libs už není potřeba pro UI, ale může být pro jiné funkce, ponechávám
}

escrow_ignore {
    'config.lua',
    'html/*'
  }