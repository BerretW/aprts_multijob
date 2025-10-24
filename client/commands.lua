-- Tento soubor zůstává téměř stejný, jen upravíme obsah příkazů /multijob a /bossmenu

RegisterCommand("listJobs", function(source, args, rawCommand)
    local _source = source
    if _source == 0 then
        print("List of jobs:")
        for k, v in pairs(Jobs) do
            print("ID: " .. v.id .. ", Name: " .. v.name .. ", Label: " .. v.label .. ", Boss: " .. v.boss)
        end
    else
        print("This command can only be used from the server console.")
    end
end, false)

RegisterCommand("quitJob", function(source, args, rawCommand)
    local jobName = args[1]
    if jobName then
        TriggerServerEvent("aprts_multijob:server:quitJob", jobName)
    else
        notify("Použití: /quitJob [nazev_prace]")
    end
end, false)


RegisterCommand("setPlayerJob", function(source, args, rawCommand)
    local _source = source
    if LocalPlayer.state.Character.Group == "admin" then

        local target = tonumber(args[1])
        local jobName = args[2]
        local grade = tonumber(args[3]) or Config.DefaultJobGrade

        if target and jobName then
            TriggerServerEvent("aprts_multijob:server:setPlayerJob", target, jobName, grade)
        else
            print("Usage: /setPlayerJob [charId] [jobName] [grade]")
        end
    else
        notify(source, "Nemáte oprávnění k použití tohoto příkazu.")
    end
end, false)

-- ZMĚNA ZDE
RegisterCommand("multijob", function(source, args, rawCommand)
    OpenJobMenu()
end, false)

-- ZMĚNA ZDE
RegisterCommand("bossmenu", function(source, args, rawCommand)
    local jobName = LocalPlayer.state.Character.Job
    local grade = LocalPlayer.state.Character.Grade
    local boss = false
    
    if jobName and JobsByName[jobName] then
        if grade >= JobsByName[jobName].boss then
            boss = true
        end
    end

    if boss then
        OpenBossMenu()
    else
        notify("Nejste šéfem své aktuální práce nebo pro ni není nastaven boss grade.")
    end
end, false)