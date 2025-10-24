-- Event pro otevření admin panelu
RegisterServerEvent('aprts_multijob:server:requestAdminPanel')
AddEventHandler('aprts_multijob:server:requestAdminPanel', function()
    local player = source
    local user = Core.getUser(player)
    
    if user and user.getGroup() == Config.AdminGroup then
        -- Pošleme klientovi seznam všech prací a signál k otevření panelu
        TriggerClientEvent('aprts_multijob:client:openAdminPanel', player, Jobs)
    else
        notify(player, "Nemáte oprávnění pro přístup k tomuto panelu.")
    end
end)

-- Vytvoření nové práce
RegisterServerEvent('aprts_multijob:server:createJob')
AddEventHandler('aprts_multijob:server:createJob', function(name, label, bossGrade)
    local player = source
    local user = Core.getUser(player)
    
    if not (user and user.getGroup() == Config.AdminGroup) then return end
    
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

-- Editace existující práce
RegisterServerEvent('aprts_multijob:server:editJob')
AddEventHandler('aprts_multijob:server:editJob', function(jobId, name, label, bossGrade)
    local player = source
    local user = Core.getUser(player)

    if not (user and user.getGroup() == Config.AdminGroup) then return end

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

    MySQL:execute("UPDATE aprts_jobs SET name = @name, label = @label, boss = @boss WHERE id = @id", {
        ['@id'] = jobId,
        ['@name'] = name,
        ['@label'] = label,
        ['@boss'] = bossGrade
    }, function(affectedRows)
        if affectedRows > 0 then
            -- Aktualizujeme práci v paměti
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