local nuiVisible = false

-- Funkce pro zobrazení/schování NUI a zaměření myši
function setNui(state)
    nuiVisible = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and "show" or "hide" })
end

-- ==========================
--      OTEVÍRÁNÍ MENU
-- ==========================

function OpenJobMenu()
    if nuiVisible then return end

    MyJobs = {}
    TriggerServerEvent("aprts_multijob:server:requestMyJobs")
    
    -- Počkáme, až server pošle data
    local attempts = 0
    while #MyJobs == 0 and attempts < 50 do -- max 5s timeout
        Wait(100)
        attempts = attempts + 1
    end

    if #MyJobs > 0 then
        SendNUIMessage({
            action = "openJobMenu",
            jobs = MyJobs,
            currentJob = LocalPlayer.state.Character.Job,
            currentJobLabel = LocalPlayer.state.Character.JobLabel
        })
        setNui(true)
    else
        notify("Nepodařilo se načíst vaše zaměstnání.")
    end
end

function OpenBossMenu()
    if nuiVisible then return end
    local jobName = LocalPlayer.state.Character.Job
    
    Employees = {}
    TriggerServerEvent('aprts_multijob:server:getEmployees', JobsByName[jobName] and JobsByName[jobName].id or 0)
    
    -- Počkáme na data
    local attempts = 0
    while #Employees == 0 and attempts < 50 do -- max 5s timeout
        Wait(100)
        attempts = attempts + 1
    end

    SendNUIMessage({
        action = "openBossMenu",
        employees = Employees,
        jobName = jobName,
        jobLabel = LocalPlayer.state.Character.JobLabel
    })
    setNui(true)
end

-- ==========================
--      NUI CALLBACKS
-- ==========================

-- Zavření NUI
RegisterNUICallback('close', function(_, cb)
    setNui(false)
    cb({})
end)

-- Aktivace jobu
RegisterNUICallback('setActiveJob', function(data, cb)
    if data.jobName then
        TriggerServerEvent("aprts_multijob:server:setJobActive", data.jobName)
    end
    setNui(false)
    cb({})
end)

-- Opuštění jobu
RegisterNUICallback('quitJob', function(data, cb)
    if data.jobName then
        TriggerServerEvent("aprts_multijob:server:quitJob", data.jobName)
    end
    setNui(false)
    cb({})
end)

-- Propustit zaměstnance
RegisterNUICallback('fireEmployee', function(data, cb)
    if data.charid and data.jobName then
        TriggerServerEvent("aprts_multijob:server:fireEmployee", data.jobName, data.charid)
    end
    setNui(false)
    cb({})
end)

-- Změna hodnosti
RegisterNUICallback('setGrade', function(data, cb)
    if data.charid and data.jobName and data.newGrade then
        TriggerServerEvent("aprts_multijob:server:setJobGrade", data.charid, data.jobName, data.newGrade)
    end
    setNui(false)
    cb({})
end)

-- Najmutí hráče
RegisterNUICallback('hirePlayer', function(data, cb)
    setNui(false)
    Wait(200) -- Dáme NUI čas se zavřít
    
    local Player = exports["aprts_selectPlayer"]:selectPlayer(2.0, true)
    if Player and Player > 0 then
        -- Najmeme s výchozí hodností 0, šéf ji může později změnit
        TriggerServerEvent("aprts_multijob:server:hirePlayer", Player, data.jobName, 0)
    else
        notify("Nebyl vybrán žádný hráč.")
    end
    cb({})
end)

-- Loop pro vypnutí ovládání, když je NUI otevřené
CreateThread(function()
    while true do
        if nuiVisible then
            DisableActions(PlayerPedId())
            DisableBodyActions(PlayerPedId())
        end
        Wait(0)
    end
end)