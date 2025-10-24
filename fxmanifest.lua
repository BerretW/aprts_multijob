fx_version 'cerulean'
lua54 'yes'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'SpoiledMouse'
version '1.3'
description 'aprts_multijob with NUI and Admin Panel'

games {"rdr3"}

-- NUI soubory
ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    -- NOVÉ soubory pro admin panel --
    'html/admin_style.css'
}

-- Client scripty
client_scripts {
    'config.lua',
    'client/client.lua',
    'client/events.lua',
    'client/nui_handler.lua',
    'client/renderer.lua',
    'client/visualizer.lua',
    'client/commands.lua',
    'client/admin.lua' -- NOVÝ soubor
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/server.lua',
    'server/events.lua',
    'server/commands.lua',
    'server/admin.lua', -- NOVÝ soubor
}
shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

escrow_ignore {
    'config.lua',
    'html/*'
}