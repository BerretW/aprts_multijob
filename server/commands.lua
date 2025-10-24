-- migration_marshal_to_aprts.lua
-- Spustíš jednou po startu resource; po migraci klidně smaž/zakomentuj.
local DRY_RUN = false
local db = exports.oxmysql -- používáš MySQL = exports.oxmysql, ale raději vlastní lokální alias

-- --- Pomocné promise wrappery pro exports.oxmysql ---
local function sql_scalar(q, p)
    local pr = promise.new()
    db:scalar(q, p or {}, function(res)
        pr:resolve(res)
    end)
    return Citizen.Await(pr)
end

local function sql_insert(q, p)
    local pr = promise.new()
    db:insert(q, p or {}, function(res)
        pr:resolve(res)
    end)
    return Citizen.Await(pr)
end

local function sql_query(q, p)
    local pr = promise.new()
    db:fetch(q, p or {}, function(res)
        pr:resolve(res or {})
    end)
    return Citizen.Await(pr)
end
-- ----------------------------------------------------

local function log(fmt, ...)
    print(('[MIGRATION] ' .. fmt):format(...))
end

local function titleCase(s)
    return (tostring(s or ''):gsub("^%l", string.upper))
end

local function ensureUnemployedJob()
    local id = sql_scalar('SELECT id FROM aprts_jobs WHERE name = ?', {'unemployed'})
    if id then
        return id
    end

    if DRY_RUN then
        log("DRY: INSERT aprts_jobs unemployed")
        return 1
    end

    local insertId = sql_insert('INSERT INTO aprts_jobs (name, label, boss) VALUES (?, ?, ?)',
        {'unemployed', 'Nezaměstnaný', 100})
    log("Vložen job 'unemployed' id=%s", tostring(insertId))
    return insertId
end

local function getOrCreateJobId(jobName)
    local existingId = sql_scalar('SELECT id FROM aprts_jobs WHERE name = ?', {jobName})
    if existingId then
        return existingId
    end

    local label = titleCase(jobName)

    if DRY_RUN then
        log("DRY: INSERT aprts_jobs name=%s label=%s", jobName, label)
        return -1
    end

    local insertId = sql_insert('INSERT INTO aprts_jobs (name, label, boss) VALUES (?, ?, ?)', {jobName, label, 0})
    log("Vložen job '%s' id=%s", jobName, tostring(insertId))
    return insertId
end

local function insertUserJobIfMissing(charid, jobId, grade)
    local exists = sql_scalar('SELECT 1 FROM aprts_jobs_users WHERE charid = ? AND job = ? LIMIT 1', {charid, jobId})
    if exists then
        log("Skip existující pair charid=%s job=%s", tostring(charid), tostring(jobId))
        return false
    end

    if DRY_RUN then
        log("DRY: INSERT aprts_jobs_users charid=%s job=%s grade=%s", tostring(charid), tostring(jobId), tostring(grade))
        return true
    end

    sql_insert('INSERT INTO aprts_jobs_users (charid, job, grade) VALUES (?, ?, ?)', {charid, jobId, grade})
    log("Vložen aprts_jobs_users: charid=%s job=%s grade=%s", tostring(charid), tostring(jobId), tostring(grade))
    return true
end

local function runMigration()
    log("Start migrace marshal_multi_jobs -> aprts_jobs/aprts_jobs_users")

    ensureUnemployedJob()

    -- mapování všech jobů
    local jobs = sql_query('SELECT DISTINCT job FROM marshal_multi_jobs')
    if not jobs or #jobs == 0 then
        log("Nenalezeny žádné joby v marshal_multi_jobs.")
        return
    end

    local jobIdMap = {}
    for _, row in ipairs(jobs) do
        local name = tostring(row.job or '')
        if name ~= '' then
            jobIdMap[name] = getOrCreateJobId(name)
        end
    end

    -- vlastní migrace
    local rows = sql_query([[
        SELECT cid, job, jobgrade
        FROM marshal_multi_jobs
        ORDER BY cid ASC, job ASC
    ]])

    if not rows or #rows == 0 then
        log("Žádné řádky k migraci.")
        return
    end

    local inserted, skipped = 0, 0

    for _, r in ipairs(rows) do
        local charid = tonumber(r.cid)
        local jobname = tostring(r.job or '')
        local grade = tonumber(r.jobgrade) or 0

        if charid and jobname ~= '' then
            local jobId = jobIdMap[jobname] or getOrCreateJobId(jobname)
            jobIdMap[jobname] = jobId

            if insertUserJobIfMissing(charid, jobId, grade) then
                inserted = inserted + 1
            else
                skipped = skipped + 1
            end
        end
    end

    log("Hotovo. Vloženo: %d, přeskočeno: %d", inserted, skipped)
end

RegisterCommand("migrateJobs", function()
    if Config.Debug then
        runMigration()
    end
end, false)
