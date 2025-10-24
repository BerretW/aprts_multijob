MySQL = exports.oxmysql
Core = exports.vorp_core:GetCore()
PlayedJobs = {}
Jobs = {}
PlayerNames = {}
function debugPrint(msg)
    if Config.Debug == true then
        print("^1[SCRIPT]^0 " .. msg)
    end
end
function notify(playerId, message)
    TriggerClientEvent('notifications:notify', playerId, "SCRIPT", message, 4000)
end

function table.count(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

local loaded = false
function LoadAllPlayerNames()
    MySQL:execute("SELECT charidentifier, firstname, lastname FROM characters", {}, function(result)
        for k, v in pairs(result) do
            PlayerNames[v.charidentifier] = v.firstname .. " " .. v.lastname
        end
        loaded = true
    end)
end

function GetPlayerName(source)
    local user = Core.getUser(source)
    if not user then
        return "nobody"
    end
    local character = user.getUsedCharacter
    local firstname = character.firstname
    local lastname = character.lastname
    return firstname .. " " .. lastname
end

function getCharName(charID)
    while not loaded do
        Wait(100)
    end
    local name = PlayerNames[charID]
    return name or "Neznámý"
end

function DiscordWeb(name, message, footer)
    if Config.WebHook == "" then
        return
    end
    local embed = {{
        ["color"] = Config.DiscordColor,
        ["title"] = "",
        ["description"] = "**" .. name .. "** \n" .. message .. "\n\n",
        ["footer"] = {
            ["text"] = footer
        }
    }}
    PerformHttpRequest(Config.WebHook, function(err, text, headers)
    end, 'POST', json.encode({
        username = Config.ServerName,
        embeds = embed
    }), {
        ['Content-Type'] = 'application/json'
    })
end

function LokiLog(event, player, playerName, message, ...)

    local text = Player(player).state.Character.CharId .. "/" .. playerName .. ": " .. message
    lib.logger(player, event, text, ...)

end

function LOG(player, event, message, ...)
    local playerName = GetPlayerName(player)
    local charID = 0
    if Player(player) and Player(player).state and Player(player).state.Character and
        Player(player).state.Character.CharId then
        charID = Player(player).state.Character.CharId
    end
    local text = charID .. "/" .. playerName .. ": " .. message
    if Config.Debug == true then
        print("^1[" .. event .. "]^0 " .. text)
    end
    DiscordWeb(event .. ", " .. playerName, message, os.date("Datum: %d.%m.%Y Čas: %H:%M:%S"))
    lib.logger(player, event, text, ...)

end

function getJobID(name)
    for k, v in pairs(Jobs) do
        if v.name == name then
            return v.id
        end
    end
    return nil
end

function getJobLabel(name)
    for k, v in pairs(Jobs) do
        if v.name == name then
            return v.label
        end
    end
    return name -- Fallback na jméno, pokud label nenajde
end

function IsPlayerBoss(player, jobName)
    local charID = Player(player).state.Character.CharId
    for k, v in pairs(PlayedJobs[charID]) do
        -- print(jobName)
        if Jobs[v.job] and Jobs[v.job].name == jobName and Jobs[v.job].boss > 0 and v.grade >= Jobs[v.job].boss then
            -- print(json.encode(Jobs[v.job]))
            return true
        end
    end
    return false
end

function setJob(player, job, grade, label)
    local user = Core.getUser(player) --[[@as User]]
    if not user then
        return
    end -- is player in session?
    if not label then
        label = ""
    end
    local character = user.getUsedCharacter --[[@as Character]]
    character.setJob(job)
    character.setJobGrade(grade)
    character.setJobLabel(label)
    debugPrint("Nastavuji práci hráči " .. player .. " na " .. job .. " s grade " .. grade .. " a label " .. label)
end

function getFirstPlayerJob(player)
    debugPrint("Získávám první práci pro hráče " .. player)
    local charID = Player(player).state.Character.CharId
    if PlayedJobs[charID] and PlayedJobs[charID][1] then
        local jobInfo = PlayedJobs[charID][1]
        if Jobs[jobInfo.job] then
            return Jobs[jobInfo.job].name, jobInfo.grade, Jobs[jobInfo.job].label
        end
    end
    return "unemployed", 0, "nezaměstnaný"
end

function getFirstCharacterJob(charID)
    if PlayedJobs[charID] and PlayedJobs[charID][1] then
        local jobInfo = PlayedJobs[charID][1]
        if Jobs[jobInfo.job] then
            return Jobs[jobInfo.job].name, jobInfo.grade, Jobs[jobInfo.job].label
        end
    end
    return "unemployed", 0, "nezaměstnaný"
end

function getNumOfPlayerJobs(player)
    local charID = Player(player).state.Character.CharId
    local count = 0
    count = table.count(PlayedJobs[charID] or {})
    --
    debugPrint("Počet jobů hráče " .. charID .. " je " .. count)
    return count
end

function getPlayerJobGrade(player, jobName)
    local charID = Player(player).state.Character.CharId
    for k, v in pairs(PlayedJobs) do
        if v.charid == charID and Jobs[v.job] and Jobs[v.job].name == jobName then
            return v.grade
        end
    end
    return nil
end

function getPlayerJobInfo(player, jobName)
    local charID = Player(player).state.Character.CharId
    if not PlayedJobs[charID] then return nil end
    for k, v in pairs(PlayedJobs[charID]) do
        if Jobs[v.job] and Jobs[v.job].name == jobName then
            return v
        end
    end
    return nil
end

function RegisterJob(name, label, bossGrade)
    local done = false
    MySQL:execute("INSERT INTO aprts_jobs (name, label, boss) VALUES (@name, @label, @boss)", {
        ['@name'] = name,
        ['@label'] = label,
        ['@boss'] = bossGrade
    }, function(result)
        if result and result.insertId then
            Jobs[result.insertId] = {
                id = result.insertId,
                name = name,
                label = label,
                boss = bossGrade
            }
            print("Zaregistrována nová práce: " .. name .. " s ID: " .. result.insertId)
            TriggerClientEvent('aprts_multijob:client:receiveJobs', -1, Jobs)
            LOG("0", "JOB", "Byla zaregistrována nová práce: " .. name .. " s ID: " .. result.insertId)
        end
        done = true
    end)
    while not done do
        Wait(100)
    end
end

function setPlayerJob(player, targetId, jobName, grade)
    if not Player(player) then
        return false
    end
    if not Player(targetId).state.Character then
        notify(player, "Hráč není online!")
        return false
    end
    local jobID = getJobID(jobName)
    if not jobID then
        print("Neznámá práce: " .. jobName)
        RegisterJob(jobName, jobName, Config.BossMenuGrade)
        jobID = getJobID(jobName)
    end
    local charId = Player(targetId).state.Character.CharId
    if getNumOfPlayerJobs(targetId) >= Config.MaxJobs then
        notify(player, "Hráč již má maximální počet prací!")
        return false
    end
    if not PlayedJobs[charId] then
        PlayedJobs[charId] = {}
    end

    local hasThisJob = false
    for k, v in pairs(PlayedJobs[charId]) do
        if v.job == jobID then
            hasThisJob = true
            break
        end
    end
    if hasThisJob then
        notify(player, "Hráč již má tuto práci!")
        return false
    end

    table.insert(PlayedJobs[charId], {
        charid = charId,
        job = jobID,
        grade = grade,
        name = Jobs[jobID] and Jobs[jobID].name or "Unknown",
        label = Jobs[jobID] and Jobs[jobID].label or "Unknown"
    })
    MySQL:execute("INSERT INTO aprts_jobs_users (charid, job, grade) VALUES (@charid, @job, @grade)", {
        ['@charid'] = charId,
        ['@job'] = jobID,
        ['@grade'] = grade
    })
    notify(targetId, "Byli jste najati do práce: " .. (Jobs[jobID] and Jobs[jobID].label or "Unknown") ..
        " na pozici: " .. grade)
    
    TriggerClientEvent("aprts_multijob:client:receiveMyJobs", targetId, PlayedJobs[charId])
    return true
end

-- TATO UDÁLOST JE STARÁ A DUPLIKOVANÁ, ZAKOMENTOVÁVÁM JI. POUŽIJEME NOVOU "vorp:playerLoaded"
-- AddEventHandler("vorp:playerJobChange", function(source, newjob, oldjob) ... end)


-- ====================================================================================
-- NOVÁ SEKCE: SYNCHRONIZACE PRÁCE PŘI PŘIHLÁŠENÍ HRÁČE
-- ====================================================================================
AddEventHandler("vorp:playerLoaded", function(user)
    local source = user.source
    local character = user.getUsedCharacter
    local charId = character.charIdentifier
    local activeJobName = character.job
    local activeJobGrade = character.jobgrade

    debugPrint("Spouštím synchronizaci práce pro hráče " .. GetPlayerName(source) .. " (CharID: " .. charId .. ")")
    debugPrint("Aktivní práce z VORP: " .. activeJobName .. " (Grade: " .. activeJobGrade .. ")")

    -- Ujistíme se, že hráč má pro sebe vytvořenou tabulku v paměti
    if not PlayedJobs[charId] then
        PlayedJobs[charId] = {}
    end

    -- Najdeme ID aktivní práce. Pokud neexistuje v `aprts_jobs`, vytvoříme ji.
    local jobId = getJobID(activeJobName)
    if not jobId then
        debugPrint("Práce '" .. activeJobName .. "' neexistuje v aprts_jobs. Vytvářím...")
        RegisterJob(activeJobName, activeJobName, Config.BossMenuGrade)
        jobId = getJobID(activeJobName)
        if not jobId then
            print("^1[aprts_multijob] CHYBA: Nepodařilo se vytvořit a načíst práci '"..activeJobName.."'!^0")
            return
        end
    end

    -- Zkontrolujeme, zda hráč již má tuto práci v seznamu `PlayedJobs`
    local hasJob = false
    for _, jobData in ipairs(PlayedJobs[charId]) do
        if jobData.job == jobId then
            hasJob = true
            -- Můžeme zde případně i synchronizovat grade, pokud se liší
            if jobData.grade ~= activeJobGrade then
                 debugPrint("Grade pro práci '"..activeJobName.."' se liší. Aktualizuji z "..jobData.grade.." na "..activeJobGrade)
                 jobData.grade = activeJobGrade
                 MySQL:execute("UPDATE aprts_jobs_users SET grade = @grade WHERE charid = @charid AND job = @job", {
                     ['@grade'] = activeJobGrade,
                     ['@charid'] = charId,
                     ['@job'] = jobId
                 })
            end
            break
        end
    end

    -- Pokud hráč práci v `aprts_jobs_users` nemá, přidáme mu ji
    if not hasJob then
        debugPrint("Hráč nemá práci '" .. activeJobName .. "' v aprts_jobs_users. Přidávám záznam.")
        
        table.insert(PlayedJobs[charId], {
            charid = charId,
            job = jobId,
            grade = activeJobGrade,
            name = Jobs[jobId].name,
            label = Jobs[jobId].label
        })

        MySQL:execute("INSERT INTO aprts_jobs_users (charid, job, grade) VALUES (@charid, @job, @grade)", {
            ['@charid'] = charId,
            ['@job'] = jobId,
            ['@grade'] = activeJobGrade
        })

        notify(source, "Vaše aktivní práce '" .. Jobs[jobId].label .. "' byla synchronizována.")
    end

    debugPrint("Synchronizace práce pro hráče " .. GetPlayerName(source) .. " dokončena.")
end)