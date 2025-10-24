local adminNuiVisible = false

function setAdminNui(state)
    adminNuiVisible = state
    SetNuiFocus(state, state)
end

RegisterCommand("multijobadmin", function()
    -- Požádáme server, aby ověřil, jestli jsme admin
    TriggerServerEvent("aprts_multijob:server:requestAdminPanel")
end, false)

RegisterNetEvent("aprts_multijob:client:openAdminPanel", function(jobs)
    if adminNuiVisible then return end
    
    SendNUIMessage({
        action = "openAdminPanel",
        jobs = jobs
    })
    setAdminNui(true)
end)

RegisterNUICallback('admin:close', function(_, cb)
    setAdminNui(false)
    cb({})
end)

RegisterNUICallback('admin:createJob', function(data, cb)
    TriggerServerEvent("aprts_multijob:server:createJob", data.name, data.label, data.boss)
    -- NUI se zavře až po úspěšném callbacku ze serveru
    cb({})
end)

RegisterNUICallback('admin:editJob', function(data, cb)
    TriggerServerEvent("aprts_multijob:server:editJob", data.id, data.name, data.label, data.boss)
    cb({})
end)

-- Tento event zavře NUI a obnoví data po úspěšné akci na serveru
RegisterNetEvent("aprts_multijob:client:adminActionSuccess", function()
    setAdminNui(false)
end)

CreateThread(function()
    while true do
        if adminNuiVisible then
            DisableActions(PlayerPedId())
            DisableBodyActions(PlayerPedId())
        end
        Wait(0)
    end
end)