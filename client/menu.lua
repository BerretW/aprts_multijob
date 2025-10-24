function OpenJobMenu()
    local id = "job_menu"
    local mainMenu = jo.menu.create(id, {
        title = LocalPlayer.state.Character.JobLabel or "Nezaměstnaný",
        subtitle = LocalPlayer.state.Character.Job .. " - " .. LocalPlayer.state.Character.JobLabel .. "/" ..
            LocalPlayer.state.Character.Grade,
        numberOnScreen = 6,
        onBack = function()
            jo.menu.show(false);
            menuOpen = false
        end
    })
    for k, v in pairs(MyJobs) do
        print(json.encode(v))
        local jobLabel = Jobs[v.job].label or "Nezaměstnaný"
        mainMenu:addItem({
            icon = "circle",
            title = jobLabel .. " (" .. v.grade .. ")",
            value = v.job,
            description = "Změnit zaměstnání na " .. jobLabel,
            onClick = function()
                jo.menu.show(false);
                menuOpen = false
                TriggerServerEvent("aprts_multijob:server:setJobActive", Jobs[v.job].name)
            end
        })
    end
    mainMenu:send()
    menuOpen = true
    jo.menu.setCurrentMenu(id)
    jo.menu.show(true)
end

function OpenBossMenu()
    while table.count(Employees) == 0 do
        Wait(100)
    end
    local id = "boss_menu"
    local mainMenu = jo.menu.create(id, {
        title = "Boss Menu",
        subtitle = LocalPlayer.state.Character.Job .. " - " .. LocalPlayer.state.Character.JobLabel .. "/" ..
            LocalPlayer.state.Character.Grade,
        numberOnScreen = 12,
        onBack = function()
            jo.menu.show(false);
            menuOpen = false
        end
    })

    local fireMenu = jo.menu.create("fire_menu", {
        title = "Propustit zaměstnance",
        subtitle = LocalPlayer.state.Character.Job .. " - " .. LocalPlayer.state.Character.JobLabel .. "/" ..
            LocalPlayer.state.Character.Grade,
        numberOnScreen = 12,

    })

    local PromoteMenu = jo.menu.create("promote_menu", {
        title = "Povýšit zaměstnance",
        subtitle = LocalPlayer.state.Character.Job .. " - " .. LocalPlayer.state.Character.JobLabel .. "/" ..
            LocalPlayer.state.Character.Grade,
        numberOnScreen = 12,

    })
    for _, emplo in pairs(Employees) do

        PromoteMenu:addItem({
            icon = "circle",
            title = emplo.name .. " - " .. emplo.grade,
            description = "Povýšit " .. emplo.name .. " v vaší firmě",
            onClick = function()
                SetNuiFocus(true, true)
                local input = lib.inputDialog("Nastavit Grade", {{
                    type = 'number',
                    label = 'Nový Grade',
                    description = '',
                    required = true,
                    precision = 1,
                    min = 0,
                    max = 10,
                    step = 1
                }})
                -- SetNuiFocus(false, false)
                if input then
                    TriggerServerEvent("aprts_multijob:server:setJobGrade", emplo.charid,
                        LocalPlayer.state.Character.Job, tonumber(input[1]))
                end
                jo.menu.show(false);
                menuOpen = false
            end
        })
    end
    PromoteMenu:send()
    for _, emplo in pairs(Employees) do

        fireMenu:addItem({
            icon = "circle",
            title = emplo.name .. " - " .. emplo.grade,
            description = "Propustit " .. emplo.name .. " z vaší firmy",
            onClick = function()
                jo.menu.show(false);
                menuOpen = false
                TriggerServerEvent("aprts_multijob:server:fireEmployee", LocalPlayer.state.Character.Job, emplo.charid)
            end
        })
    end
    fireMenu:send()

    mainMenu:addItem({
        icon = "circle",
        title = "Nábor nových zaměstnanců",
        description = "Nábor nových zaměstnanců do vaší firmy",
        onClick = function()

            jo.menu.show(false);
            menuOpen = false
            local Player = exports["aprts_selectPlayer"]:selectPlayer(2.0, true)
            if Player > 0 then
                TriggerServerEvent("aprts_multijob:server:hirePlayer", Player, LocalPlayer.state.Character.Job, 0)
            end
        end
    })
    mainMenu:addItem({
        icon = "circle",
        title = "Povýšit zaměstnance",
        description = "Povíšit zaměstnance z vaší firmy",
        child = "promote_menu",
        onClick = function()
            jo.menu.show(false);
            menuOpen = false
        end
    })
    mainMenu:addItem({
        icon = "circle",
        title = "Propustit zaměstnance",
        description = "Propustit zaměstnance z vaší firmy",
        child = "fire_menu",
        onClick = function()
            jo.menu.show(false);
            menuOpen = false
        end
    })
    mainMenu:send()
    menuOpen = true
    jo.menu.setCurrentMenu(id)
    jo.menu.show(true)
end
