-- local Prompt = nil
-- local promptGroup = GetRandomIntInRange(0, 0xffffff)
Jobs = {}
JobsByName = {}
MyJobs = {}
TargetJobs = {}
Employees = {}


function debugPrint(msg)
    if Config.Debug == true then
        print("^1[SCRIPT]^0 " .. msg)
    end
end

function notify(text)
    TriggerEvent('notifications:notify', "SCRIPT", text, 3000)
end

function table.count(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function round(num)
    return math.floor(num * 100 + 0.5) / 100
end


-- NOVÁ FUNKCE PRO KONTROLU BOSSE NA KLIENTOVI
function IsClientPlayerBoss()
    if not LocalPlayer.state.Character then return false end

    local activeJobName = LocalPlayer.state.Character.Job
    local activeJobGrade = LocalPlayer.state.Character.Grade

    if not activeJobName or not JobsByName[activeJobName] then
        debugPrint("IsClientPlayerBoss: Hráč nemá platnou aktivní práci.")
        return false
    end

    local jobData = JobsByName[activeJobName]

    -- Zkontroluje, zda má práce definovanou hodnost pro šéfa a zda ji hráč splňuje
    if jobData.boss and jobData.boss > 0 and activeJobGrade >= jobData.boss then
        debugPrint("IsClientPlayerBoss: Hráč JE šéfem. Grade: " .. activeJobGrade .. ", Požadováno: " .. jobData.boss)
        return true
    end

    debugPrint("IsClientPlayerBoss: Hráč NENÍ šéfem. Grade: " .. activeJobGrade .. ", Požadováno: " .. (jobData.boss or "N/A"))
    return false
end


function DisableBodyActions(ped)
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x27D1C284, true) -- loot
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x399C6619, true) -- loot
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x41AC83D1, true) -- loot
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xBE8593AF, true) -- INPUT_PICKUP_CARRIABLE2
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xEB2AC491, true) -- INPUT_PICKUP_CARRIABLE
end
function DisableActions(ped)
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xA987235F, true) -- LookLeftRight
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xD2047988, true) -- LookUpDown
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x39CCABD5, true) -- VehicleMouseControlOverride

    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x4D8FB4C1, true) -- disable left/right
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xFDA83190, true) -- disable forward/back
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xDB096B85, true) -- INPUT_DUCK
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x8FFC75D6, true) -- disable sprint

    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x9DF54706, true) -- veh turn left
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x97A8FD98, true) -- veh turn right
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x5B9FD4E2, true) -- veh forward
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x6E1F639B, true) -- veh backwards
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xFEFAB9B4, true) -- disable exit vehicle

    Citizen.InvokeNative(0x2970929FD5F9FC89, ped, true) -- Disable weapon firing
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x07CE1E61, true) -- disable attack
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xF84FA74F, true) -- disable aim
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xAC4BD4F1, true) -- disable weapon select
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x73846677, true) -- disable weapon
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x0AF99998, true) -- disable weapon
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xB2F377E8, true) -- disable melee
    Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xADEAF48C, true) -- disable melee
end