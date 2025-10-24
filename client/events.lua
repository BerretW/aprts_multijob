AddEventHandler("onClientResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    TriggerServerEvent("aprts_multijob:server:requestJobs")
    TriggerServerEvent("aprts_multijob:server:requestMyJobs")
end)


RegisterNetEvent("aprts_multijob:client:receiveJobs", function(jobs)
    Jobs = jobs
    for k, v in pairs(Jobs) do
        JobsByName[v.name] = v
    end
    debugPrint("Načteny práce: ")
    -- print(json.encode(Jobs))
end)

RegisterNetEvent("aprts_multijob:client:receiveMyJobs", function(myJobs)
    MyJobs = myJobs
    debugPrint("Načteny moje práce: ")
    print(json.encode(MyJobs))
end)

RegisterNetEvent("aprts_multijob:client:receivePlayerJobs", function(targetId, jobList)
    TargetJobs = jobList
    debugPrint("Načteny práce hráče: " .. targetId)
    -- print(json.encode(jobList))
end)


RegisterNetEvent("aprts_multijob:client:receiveEmployees", function(employees)
    Employees = employees
    debugPrint("Načteni zaměstnanci: ")
    print(json.encode(Employees))
end)