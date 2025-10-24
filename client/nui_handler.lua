local nuiVisible = false

function setNui(state)
    nuiVisible = state
    SetNuiFocus(state, state)
end

-- ==========================
--      OTEVÍRÁNÍ MENU
-- ==========================
function OpenUnifiedMenu()
    if nuiVisible then return end

    local isBoss = IsClientPlayerBoss()

    -- Reset dat
    MyJobs = {}
    Employees = {}
    TriggerServerEvent("aprts_multijob:server:requestMyJobs")
    
    if isBoss then
        local jobName = LocalPlayer.state.Character.Job
        local jobId = JobsByName[jobName] and JobsByName[jobName].id or 0
        TriggerServerEvent('aprts_multijob:server:getEmployees', jobId)
    end
    
    -- Počkáme, až server pošle data
    local attempts = 0
    CreateThread(function()
        -- Čekáme na data. Pokud je boss, čekáme i na zaměstnance.
        while (#MyJobs == 0 or (isBoss and #Employees == 0)) and attempts < 50 do
            Wait(100)
            attempts = attempts + 1
        end

        if #MyJobs > 0 then
            -- Pokaždé načteme čerstvá data ze statebagu a pošleme je do NUI
            local charState = LocalPlayer.state.Character
            SendNUIMessage({
                action = "openMenu",
                -- Data pro job list
                jobs = MyJobs,
                currentJob = charState.Job,
                currentJobLabel = charState.JobLabel,
                currentGrade = charState.Grade, -- Přidáno pro zobrazení v NUI
                -- Data pro boss panel
                isBoss = isBoss,
                employees = Employees
            })
            setNui(true)
        else
            notify("Nepodařilo se načíst vaše zaměstnání.")
        end
    end)
end

-- ==========================
--      NUI CALLBACKS
-- ==========================

RegisterNUICallback('close', function(_, cb)
    setNui(false)
    cb({})
end)

RegisterNUICallback('setActiveJob', function(data, cb)
    if data.jobName then
        TriggerServerEvent("aprts_multijob:server:setJobActive", data.jobName)
    end
    setNui(false)
    cb({})
end)

RegisterNUICallback('quitJob', function(data, cb)
    if data.jobName then
        TriggerServerEvent("aprts_multijob:server:quitJob", data.jobName)
    end
    setNui(false)
    cb({})
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    if data.charid and data.jobName then
        TriggerServerEvent("aprts_multijob:server:fireEmployee", data.jobName, data.charid)
    end
    setNui(false)
    cb({})
end)

RegisterNUICallback('setGrade', function(data, cb)
    if data.charid and data.jobName and data.newGrade then
        TriggerServerEvent("aprts_multijob:server:setJobGrade", data.charid, data.jobName, data.newGrade)
    end
    setNui(false)
    cb({})
end)

RegisterNUICallback('hirePlayer', function(data, cb)
    setNui(false)
    Wait(200) 
    
    local Player = exports["aprts_selectPlayer"]:selectPlayer(2.0, true)
    if Player and Player > 0 then
        -- Najmeme s výchozí hodností 0
        TriggerServerEvent("aprts_multijob:server:hirePlayer", Player, data.jobName, 0)
    else
        notify("Nebyl vybrán žádný hráč.")
    end
    cb({})
end)

CreateThread(function()
    while true do
        if nuiVisible then
            DisableActions(PlayerPedId())
            DisableBodyActions(PlayerPedId())
        end
        Wait(0)
    end
end)