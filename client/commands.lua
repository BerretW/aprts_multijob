-- Původní soubor byl prázdný, zde je jeho nový obsah.
-- Pokud v něm již máte příkazy, upravte je podle tohoto vzoru.

RegisterCommand("multijob", function(source, args, rawCommand)
    OpenUnifiedMenu()
end, false)
--[[
-- Tento příkaz již není potřeba, jeho logika je v /multijob
RegisterCommand("bossmenu", function(source, args, rawCommand)
    -- Tato kontrola se přesunula do /multijob
    if IsClientPlayerBoss() then
        OpenBossMenu()
    else
        notify("Nejste šéfem vaší aktuální práce.")
    end
end, false)
]]--