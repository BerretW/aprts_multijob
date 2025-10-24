-- Event pro otevření admin panelu
-- Najděte stávající event a nahraďte ho tímto
RegisterServerEvent('aprts_multijob:server:requestAdminPanel')
AddEventHandler('aprts_multijob:server:requestAdminPanel', function()
    local player = source
    local user = Core.getUser(player)
    
    if user then
        -- Vytvoříme kopii, abychom neupravovali původní globální tabulku
        local jobsWithCounts = json.decode(json.encode(Jobs)) 
        
        -- Vytvoříme tabulku pro počty
        local employeeCounts = {}
        for _, charJobs in pairs(PlayedJobs) do
            for _, jobInfo in ipairs(charJobs) do
                employeeCounts[jobInfo.job] = (employeeCounts[jobInfo.job] or 0) + 1
            end
        end

        -- Přiřadíme počty k jednotlivým pracím
        for jobId, jobData in pairs(jobsWithCounts) do
            jobData.employeeCount = employeeCounts[tonumber(jobId)] or 0
        end

        TriggerClientEvent('aprts_multijob:client:openAdminPanel', player, jobsWithCounts)
    else
        notify(player, "Nemáte oprávnění pro přístup k tomuto panelu.")
    end
end)

-- Vytvoření nové práce
RegisterServerEvent('aprts_multijob:server:createJob')
AddEventHandler('aprts_multijob:server:createJob', function(name, label, bossGrade)
    local player = source
    local user = Core.getUser(player)
    
    if not user then return end
    
    -- Validace
    if not name or name == "" or not label or label == "" or not bossGrade or tonumber(bossGrade) < 0 then
        notify(player, "Všechna pole musí být vyplněna správně.")
        return
    end

    bossGrade = tonumber(bossGrade)

    -- Zkontrolujeme, zda práce s tímto jménem již neexistuje
    for _, job in pairs(Jobs) do
        if job.name == name then
            notify(player, "Práce s názvem '" .. name .. "' již existuje.")
            return
        end
    end

    MySQL:execute("INSERT INTO aprts_jobs (name, label, boss) VALUES (@name, @label, @boss)", {
        ['@name'] = name,
        ['@label'] = label,
        ['@boss'] = bossGrade
    }, function(result)
        if result and result.insertId then
            -- Přidáme novou práci do paměti
            local newJob = { id = result.insertId, name = name, label = label, boss = bossGrade }
            Jobs[result.insertId] = newJob
            
            notify(player, "Nová práce '" .. label .. "' byla úspěšně vytvořena.")
            LOG(player, "AdminJobCreate", "Vytvořil novou práci: " .. label .. " (Name: " .. name .. ", Boss Grade: " .. bossGrade .. ")")

            -- Synchronizace se všemi klienty
            TriggerClientEvent('aprts_multijob:client:receiveJobs', -1, Jobs)
            
            -- Zavřeme admin panel u admina
            TriggerClientEvent('aprts_multijob:client:adminActionSuccess', player)
        else
            notify(player, "Došlo k chybě při vytváření práce v databázi.")
        end
    end)
end)

RegisterServerEvent('aprts_multijob:server:editJob')
AddEventHandler('aprts_multijob:server:editJob', function(jobId, name, label, bossGrade)
    local player = source
    local user = Core.getUser(player)

    if not user then return end

    -- Validace
    if not jobId or not name or name == "" or not label or label == "" or not bossGrade or tonumber(bossGrade) < 0 then
        notify(player, "Všechna pole musí být vyplněna správně.")
        return
    end

    jobId = tonumber(jobId)
    bossGrade = tonumber(bossGrade)

    -- Zkontrolujeme, zda existuje práce s tímto ID
    if not Jobs[jobId] then
        notify(player, "Práce s tímto ID nebyla nalezena.")
        return
    end

    -- === ZMĚNA ZDE: SERVER-SIDE KONTROLA ===
    -- Zkontrolujeme, zda se administrátor nepokouší změnit interní název práce
    print( "Stávající název práce: " .. Jobs[jobId].name .. ", Pokus o změnu na: " .. name )  -- Debug výpis
    if name ~= Jobs[jobId].name then
        notify(player, "Interní název (name) práce nelze měnit z důvodu integrity dat VORP.")
        -- Pro jistotu můžeme logovat pokus o neoprávněnou změnu
        LOG(player, "AdminJobEditFail", "Pokus o změnu interního názvu práce ID: " .. jobId .. " z '" .. Jobs[jobId].name .. "' na '" .. name .. "'")
        return -- Zastavíme provádění eventu
    end
    -- =======================================

    MySQL:execute("UPDATE aprts_jobs SET name = @name, label = @label, boss = @boss WHERE id = @id", {
        ['@id'] = jobId,
        ['@name'] = name,
        ['@label'] = label,
        ['@boss'] = bossGrade
    }, function(affectedRows)
        if affectedRows then
            -- Aktualizujeme práci v paměti (název se nemění, ale pro úplnost ho zde necháme)
            Jobs[jobId].name = name
            Jobs[jobId].label = label
            Jobs[jobId].boss = bossGrade

            notify(player, "Práce '" .. label .. "' byla úspěšně upravena.")
            LOG(player, "AdminJobEdit", "Upravil práci (ID: " .. jobId .. "): " .. label .. " (Name: " .. name .. ", Boss Grade: " .. bossGrade .. ")")
            
            -- Synchronizace se všemi klienty
            TriggerClientEvent('aprts_multijob:client:receiveJobs', -1, Jobs)
            
            -- Zavřeme admin panel u admina
            TriggerClientEvent('aprts_multijob:client:adminActionSuccess', player)
        else
            notify(player, "Došlo k chybě při úpravě práce v databázi.")
        end
    end)
end)
-- Přidejte tento nový event na konec souboru server/admin.lua

RegisterServerEvent('aprts_multijob:server:deleteJob')
AddEventHandler('aprts_multijob:server:deleteJob', function(jobId)
    local player = source
    local user = Core.getUser(player)

    if not user then return end

    jobId = tonumber(jobId)
    if not jobId or not Jobs[jobId] then
        notify(player, "Práce s tímto ID neexistuje.")
        return
    end

    if jobId == Config.DefaultJobID then
        notify(player, "Nelze smazat výchozí práci (nezaměstnaný).")
        return
    end

    -- === OPRAVA ZDE: Uložíme si potřebné údaje PŘED smazáním ===
    local jobLabel = Jobs[jobId].label
    local jobName = Jobs[jobId].name
    -- ==========================================================

    -- 1. Smazání z tabulky aprts_jobs
    MySQL:execute("DELETE FROM aprts_jobs WHERE id = @id", { ['@id'] = jobId })
    
    -- 2. Smazání z tabulky aprts_jobs_users (odebrání všem hráčům)
    MySQL:execute("DELETE FROM aprts_jobs_users WHERE job = @job", { ['@job'] = jobId })

    -- 3. Aktualizace paměti serveru
    Jobs[jobId] = nil -- Smazání ze seznamu prací

    -- Projdeme všechny hráče v paměti a odstraníme jim danou práci
    for charId, jobsList in pairs(PlayedJobs) do
        for i = #jobsList, 1, -1 do
            if jobsList[i].job == jobId then
                table.remove(jobsList, i)
                
                -- Pokud je hráč online, aktualizujeme mu data a případně i aktivní práci
                local targetUser = Core.getUserByCharId(charId)
                if targetUser and targetUser.source then
                    local targetId = targetUser.source
                    notify(targetId, "Vaše práce '" .. jobLabel .. "' byla zrušena administrátorem.")
                    TriggerClientEvent("aprts_multijob:client:receiveMyJobs", targetId, PlayedJobs[charId])
                    
                    -- Pokud to byla jeho aktivní práce, nastavíme mu první dostupnou
                    -- === OPRAVA ZDE: Používáme uložený jobName ===
                    if Player(targetId).state.Character.Job == jobName then
                        local newJob, newGrade, newLabel = getFirstCharacterJob(charId)
                        setJob(targetId, newJob, newGrade, newLabel)
                        notify(targetId, "Vaše aktivní práce byla změněna na: " .. newLabel)
                    end
                end
            end
        end
    end

    notify(player, "Práce '" .. jobLabel .. "' byla úspěšně smazána.")
    LOG(player, "AdminJobDelete", "Smazal práci: " .. jobLabel .. " (ID: " .. jobId .. ")")

    -- Synchronizace se všemi klienty
    TriggerClientEvent('aprts_multijob:client:receiveJobs', -1, Jobs)
    
    -- Zavřeme admin panel
    TriggerClientEvent('aprts_multijob:client:adminActionSuccess', player)
end)


RegisterServerEvent('aprts_multijob:server:assignJobToPlayer')
AddEventHandler('aprts_multijob:server:assignJobToPlayer', function(data)
    local player = source
    local user = Core.getUser(player)

    if not user then return end

    local targetId = tonumber(data.targetId)
    local jobId = tonumber(data.jobId)
    local grade = tonumber(data.grade)

    -- Základní validace
    if not targetId or not jobId or not grade or grade < 0 then
        notify(player, "Neplatné údaje. Zkontrolujte ID hráče, ID práce a hodnost.")
        return
    end

    local targetUser = Core.getUser(targetId)
    if not targetUser then
        notify(player, "Hráč s ID " .. targetId .. " není online.")
        return
    end

    if not Jobs[jobId] then
        notify(player, "Práce s ID " .. jobId .. " neexistuje.")
        return
    end
    
    local jobName = Jobs[jobId].name
    local targetCharId = Player(targetId).state.Character.CharId

    -- Kontrola, zda hráč může mít další práci
    if getNumOfPlayerJobs(targetId) >= Config.MaxJobs then
        notify(player, "Hráč '" .. GetPlayerName(targetId) .. "' již má maximální počet prací.")
        notify(targetId, "Admin se vám pokusil přiřadit práci, ale máte plný počet zaměstnání.")
        return
    end

    -- Kontrola, zda hráč již práci nemá
    if not PlayedJobs[targetCharId] then
        PlayedJobs[targetCharId] = {}
    end
    for _, existingJob in ipairs(PlayedJobs[targetCharId]) do
        if existingJob.job == jobId then
            notify(player, "Hráč '" .. GetPlayerName(targetId) .. "' již tuto práci má.")
            return
        end
    end

    -- Všechny kontroly prošly, přiřadíme práci
    table.insert(PlayedJobs[targetCharId], {
        charid = targetCharId,
        job = jobId,
        grade = grade,
        name = Jobs[jobId].name,
        label = Jobs[jobId].label
    })

    MySQL:execute("INSERT INTO aprts_jobs_users (charid, job, grade) VALUES (@charid, @job, @grade)", {
        ['@charid'] = targetCharId,
        ['@job'] = jobId,
        ['@grade'] = grade
    }, function()
        notify(player, "Úspěšně jste přiřadili práci '" .. Jobs[jobId].label .. "' hráči '" .. GetPlayerName(targetId) .. "'.")
        notify(targetId, "Admin vám přiřadil práci: " .. Jobs[jobId].label .. " s hodností " .. grade .. ".")
        
        -- Aktualizujeme data u cílového hráče
        TriggerClientEvent("aprts_multijob:client:receiveMyJobs", targetId, PlayedJobs[targetCharId])
    end)
end)