-- CREATE TABLE IF NOT EXISTS `aprts_jobs` (
--   `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
--   `name` varchar(50) NOT NULL DEFAULT '',
--   `label` varchar(50) NOT NULL DEFAULT '',
--   `boss` tinyint(3) unsigned NOT NULL DEFAULT 0,
--   KEY `Index 1` (`id`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- INSERT INTO `aprts_jobs` (`id`, `name`, `label`, `boss`) VALUES
-- 	(1, 'unemployed', 'nezaměstnaný', 100);
-- CREATE TABLE IF NOT EXISTS `aprts_jobs_users` (
--   `charid` int(10) unsigned NOT NULL,
--   `job` int(10) unsigned NOT NULL DEFAULT 1,
--   `grade` tinyint(3) unsigned NOT NULL DEFAULT 0,
--   KEY `Index 1` (`charid`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
local loaded = false
AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        local jobsLoaded = false
        MySQL:execute("SELECT * FROM aprts_jobs", {}, function(result)
            for k, v in pairs(result) do
                Jobs[v.id] = v
            end
            jobsLoaded = true
        end)

        while not jobsLoaded do
            Wait(100)
        end
        local usersLoaded = false
        MySQL:execute("SELECT * FROM aprts_jobs_users", {}, function(result)
            for k, v in pairs(result) do
                if not PlayedJobs[v.charid] then
                    PlayedJobs[v.charid] = {}
                end
                v.label = Jobs[v.job] and Jobs[v.job].label or "Unknown"
                v.name = Jobs[v.job] and Jobs[v.job].name or "unknown"
                table.insert(PlayedJobs[v.charid], v)
            end
            usersLoaded = true
        end)
        while not usersLoaded do
            Wait(100)
        end
        loaded = true
        print("aprts_multijob loaded, found " .. table.count(Jobs) .. " jobs and " .. table.count(PlayedJobs) ..
                  " players with jobs.")
        -- LOG("0","MultiJobStarted","Script started")
    end
end)

RegisterServerEvent('aprts_multijob:server:requestJobs')
AddEventHandler('aprts_multijob:server:requestJobs', function()
    local player = source
    while not loaded do
        Wait(100)
    end
    if not Player(player) then
        return
    end
    TriggerClientEvent('aprts_multijob:client:receiveJobs', player, Jobs)
end)

RegisterServerEvent('aprts_multijob:server:requestMyJobs')
AddEventHandler('aprts_multijob:server:requestMyJobs', function()
    local player = source
    while not loaded do
        Wait(100)
    end
    if not Player(Player(player).state.Character) then
        notify(player, "Hráč není online!")
        return
    end
    local myJobs = {}
    local charId = Player(player).state.Character.CharId
    if not PlayedJobs[charId] then
        PlayedJobs[charId] = {}
        local defaultJob = {
            charid = charId,
            job = Config.DefaultJobID, -- unemployed
            grade = Config.DefaultJobGrade
        }
        table.insert(PlayedJobs[charId], defaultJob)
        MySQL:execute("INSERT INTO aprts_jobs_users (charid, job, grade) VALUES (@charid, @job, @grade)", {
            ['@charid'] = charId,
            ['@job'] = Config.DefaultJobID,
            ['@grade'] = Config.DefaultJobGrade
        })
    end

    if not PlayedJobs[charId] then
        PlayedJobs[charId] = {}
        return
    end
    
    for k, v in pairs(PlayedJobs[charId]) do
        v.label = Jobs[v.job] and Jobs[v.job].label or "Unknown"
        -- OPRAVA: Tento řádek chyběl a způsoboval zamrznutí NUI.
        -- Zajišťuje, že data poslaná klientovi vždy obsahují i interní jméno práce.
        v.name = Jobs[v.job] and Jobs[v.job].name or "unknown"
        table.insert(myJobs, v)
    end

    TriggerClientEvent('aprts_multijob:client:receiveMyJobs', player, myJobs)
end)

RegisterServerEvent('aprts_multijob:server:getEmployees')
AddEventHandler('aprts_multijob:server:getEmployees', function(jobId)
    -- print(jobId)
    local player = source
    if not Player(player).state.Character then
        notify(player, "Hráč není online!")
        return
    end
    local employees = {}
    LoadAllPlayerNames()
    for k, v in pairs(PlayedJobs) do

        -- print(name)
        for _, job in pairs(v) do
            if job.job == jobId then
                local name = getCharName(k)
                -- debugPrint("Found employee: " .. name .. " | CharID: " .. k .. " | Job: " .. job.job .. " | Grade: " ..
                --                job.grade)
                table.insert(employees, {
                    charid = k,
                    job = job.job,
                    grade = job.grade,
                    label = job.label,
                    name = name
                })

            end

        end
    end
    TriggerClientEvent('aprts_multijob:client:receiveEmployees', player, employees)
end)

RegisterServerEvent('aprts_multijob:server:setPlayerJob')
AddEventHandler('aprts_multijob:server:setPlayerJob', function(targetId, jobName, grade)
    local player = source
    setPlayerJob(player, targetId, jobName, grade)

end)

RegisterServerEvent('aprts_multijob:server:quitJob')
AddEventHandler('aprts_multijob:server:quitJob', function(jobName)
    local player = source
    if not Player(player) then
        return
    end
    if not Player(Player(player).state.Character) then
        notify(player, "Hráč není online!")
        return
    end
    local charId = Player(player).state.Character.CharId
    if not PlayedJobs[charId] then
        notify(player, "Nemáte žádné práce!")
        return
    end
    local jobId = getJobID(jobName)
    if not jobId or jobId == 0 then
        notify(player, "Neplatná práce!")
        return
    end
    if jobId == Config.DefaultJobID then
        notify(player, "Nemůžete opustit výchozí práci!")
        return
    end
    local jobFound = false
    for k, v in pairs(PlayedJobs[charId]) do
        -- OPRAVA: Podmínka byla změněna z porovnávání ID na porovnávání jména,
        -- aby byla konzistentní se zbytkem skriptu a spolehlivě fungovala.
        if v.name == jobName then
            jobFound = true
            table.remove(PlayedJobs[charId], k)
            MySQL:execute("DELETE FROM aprts_jobs_users WHERE charid = @charid AND job = @job", {
                ['@charid'] = charId,
                ['@job'] = jobId
            })
            notify(player, "Opustili jste práci: " .. (Jobs[jobId] and Jobs[jobId].label or "Unknown"))
            TriggerClientEvent("aprts_multijob:client:receiveMyJobs", player, PlayedJobs[charId])
            local newJob, newGrade, newLabel = getFirstPlayerJob(player)
            setJob(player, newJob, newGrade, newLabel)
            LOG(player, "JobQuit", "Player " .. GetPlayerName(player) .. " | ID: " .. player .. " quit job: " ..
                (Jobs[jobId] and Jobs[jobId].label or "Unknown") .. " | JobID: " .. jobId)
            break
        end
    end
    if not jobFound then
        notify(player, "Nemáte tuto práci!")
        return
    end
end)

RegisterServerEvent('aprts_multijob:server:setJobGrade')
AddEventHandler('aprts_multijob:server:setJobGrade', function(charID, jobName, grade)
    local player = source
    if not Player(player) then
        return
    end
    local targetUser = Core.getUserByCharId(charID)
    local targetId = targetUser and targetUser.source or 0
    
    local jobID = getJobID(jobName)
    if not jobID or jobID == 0 then
        notify(player, "Neplatná práce!")
        return
    end
    if jobID == Config.DefaultJobID then
        notify(player, "Nemůžete změnit pozici ve výchozí práci!")
        return
    end

    if not PlayedJobs[charID] then
        notify(player, "Hráč nemá žádné práce!")
        return
    end

    local jobFound = false
    for k, v in pairs(PlayedJobs[charID]) do
        if v.job == jobID then
            jobFound = true
            v.grade = grade
            MySQL:execute("UPDATE aprts_jobs_users SET grade = @grade WHERE charid = @charid AND job = @job", {
                ['@charid'] = charID,
                ['@job'] = jobID,
                ['@grade'] = grade
            })
            
            notify(player, "Pozice hráče v práci: " .. (Jobs[jobID] and Jobs[jobID].label or "Unknown") ..
                " byla změněna na: " .. grade)
            LOG(player, "JobGradeChange",
                "Player " .. GetPlayerName(player) .. " | ID: " .. player .. " changed job grade for charId " ..
                    charID .. " in job: " .. (Jobs[jobID] and Jobs[jobID].label or "Unknown") .. " | JobID: " .. jobID .. " to grade: " .. grade)
            
            if targetId and targetId > 0 then
                notify(targetId, "Vaše pozice v práci: " .. (Jobs[jobID] and Jobs[jobID].label or "Unknown") .. " byla změněna na: " .. grade)
                TriggerClientEvent("aprts_multijob:client:receiveMyJobs", targetId, PlayedJobs[charID])
                 -- Update active job if it's the one being changed
                if Player(targetId).state.Character.Job == jobName then
                    setJob(targetId, jobName, grade, Jobs[jobID].label)
                end
            end
            break
        end
    end
    if not jobFound then
        notify(player, "Hráč nemá tuto práci!")
        return
    end
end)

RegisterServerEvent('aprts_multijob:server:setJobActive')
AddEventHandler('aprts_multijob:server:setJobActive', function(jobName)
    local player = source
    if not Player(player) then
        return
    end
    if not Player(Player(player).state.Character) then
        notify(player, "Hráč není online!")
        return
    end
    local jobId = getJobID(jobName)
    if not jobId or jobId == 0 then
        notify(player, "Neplatná práce!")
        return
    end
    local charId = Player(player).state.Character.CharId
    if not PlayedJobs[charId] then
        notify(player, "Nemáte žádné práce!")
        return
    end
    
    local playerJob = getPlayerJobInfo(player, jobName)
    if not playerJob then
        notify(player, "Nemáte tuto práci!")
        return
    end

    -- OPRAVA ZDE: Přidán čtvrtý argument 'Jobs[jobId].label' do volání funkce setJob
    setJob(player, Jobs[jobId].name, playerJob.grade, Jobs[jobId].label)
    
    notify(player, "Nyní pracujete jako: " .. (Jobs[jobId] and Jobs[jobId].label or "Unknown"))
    LOG(player, "JobChange", "Player " .. GetPlayerName(player) .. " | ID: " .. player .. " changed job to: " ..
        (Jobs[jobId] and Jobs[jobId].label or "Unknown") .. " | JobID: " .. jobId)
end)

RegisterServerEvent('aprts_multijob:server:hirePlayer')
AddEventHandler('aprts_multijob:server:hirePlayer', function(targetId, jobName, grade)
    local player = source
    -- print(player, targetId, jobName, grade)
    if not IsPlayerBoss(player, jobName) then
        notify(player, "Nemáte oprávnění k najímání!")
        return
    else
        notify(player, "Hráč byl úspěšně najat!")
        if setPlayerJob(player, targetId, jobName, grade) then
            setJob(targetId, jobName, grade, getJobLabel(jobName))
            LOG(player, "JobHire",
                "Player " .. GetPlayerName(player) .. " | ID: " .. player .. " hired " .. GetPlayerName(targetId) ..
                    " | ID: " .. targetId .. " to job: " .. jobName .. " | Grade: " .. grade)
        end
    end

end)

RegisterServerEvent('aprts_multijob:server:fireEmployee')
AddEventHandler('aprts_multijob:server:fireEmployee', function(jobName, charId)
    local player = source
    local jobId = getJobID(jobName)
    -- print(charId, jobName, jobId)
    if not jobId or jobId == 0 then
        notify(player, "Neplatná práce!")
        return
    end
    if not IsPlayerBoss(player, jobName) then
        notify(player, "Nemáte oprávnění k propouštění!")
        return
    else
        if not PlayedJobs[charId] then
            notify(player, "Hráč nemá žádné práce!")
            return
        end

        if jobId == Config.DefaultJobID then
            notify(player, "Nemůžete propustit výchozí práci!")
            return
        end
        local jobFound = false
        for k, v in pairs(PlayedJobs[charId]) do
            if v.name == jobName then

                jobFound = true
                table.remove(PlayedJobs[charId], k)
                MySQL:execute("DELETE FROM aprts_jobs_users WHERE charid = @charid AND job = @job", {
                    ['@charid'] = charId,
                    ['@job'] = jobId
                })
                local targetId = Core.getUserByCharId(charId)
                local lastJob, lastGrade, lastLabel = getFirstCharacterJob(charId)
                if targetId and targetId.source and targetId.source ~= 0 then
                    notify(targetId.source,
                        "Byli jste propuštěni z práce: " .. (Jobs[jobId] and Jobs[jobId].label or "Unknown"))
                    TriggerClientEvent("aprts_multijob:client:receiveMyJobs", targetId.source, PlayedJobs[charId])
                    setJob(targetId.source, lastJob, lastGrade, lastLabel)
                else
                    MySQL:execute("UPDATE characters SET job = @job, jobgrade = @grade, joblabel = @label WHERE charidentifier = @charid",
                        {
                            ['@charid'] = charId,
                            ['@job'] = lastJob,
                            ['@grade'] = lastGrade,
                            ['@label'] = lastLabel
                        })
                end
                LOG(player, "JobFire",
                    "Player " .. GetPlayerName(player) .. " | ID: " .. player .. " fired charId: " .. charId ..
                        " from job: " .. (Jobs[jobId] and Jobs[jobId].label or "Unknown") .. " | JobID: " .. jobId)
                notify(player, "Propustili jste hráče z práce: " .. (Jobs[jobId] and Jobs[jobId].label or "Unknown"))
                break
            end
        end
        if not jobFound then
            notify(player, "Hráč nemá tuto práci!")
            return
        end
    end

end)