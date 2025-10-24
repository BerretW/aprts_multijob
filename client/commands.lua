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
    local _source = source

    local jobName = LocalPlayer.state.Character.Job
    if jobName then
        TriggerServerEvent("aprts_multijob:server:quitJob", jobName)
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

RegisterCommand("multijob", function(source, args, rawCommand)
    local _source = source

    if _source then
        MyJobs = {}
        TriggerServerEvent("aprts_multijob:server:requestMyJobs")
        while table.count(MyJobs) == 0 do
            Wait(100)
        end
        OpenJobMenu()

    end

end, false)

RegisterCommand("bossmenu", function(source, args, rawCommand)
    local _source = source

    if _source then
        local jobName = LocalPlayer.state.Character.Job
        local grade = LocalPlayer.state.Character.Grade
        local boss = false
        if jobName and Jobs then
            for k, v in pairs(Jobs) do
                if v.name == jobName and grade >= v.boss then
                    boss = true
                    break
                end
            end
        end
        if boss then
            Employees = {}

            TriggerServerEvent('aprts_multijob:server:getEmployees', JobsByName[jobName] and JobsByName[jobName].id or 0)
            OpenBossMenu()
        else
            print("You are not a boss of your job.")
            notify("Nejste šéfem své práce.")
        end

    end

end, false)
