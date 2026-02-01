-- Nations at War - Spawn helpers (late-activated template registration, delayed spawn).

function NationsAtWar_EnsureSpawnTemplate(templateName)
    if not templateName or not _DATABASE or not _DATABASE.Templates or not _DATABASE.Templates.Groups then return end
    if not _DATABASE.Templates.Groups[templateName] then return end
    if GROUP and GROUP.FindByName and GROUP:FindByName(templateName) then return end
    _DATABASE:AddGroup(templateName)
end

function NationsAtWar_SpawnAtCoordDelayed(spawnObj, coord, delaySec, onDone)
    if not spawnObj or not coord then
        if onDone then onDone(false, nil) end
        return
    end
    delaySec = delaySec or 3
    if timer and timer.scheduleFunction then
        timer.scheduleFunction(function()
            local ok, group = pcall(spawnObj.SpawnFromCoordinate, spawnObj, coord)
            if onDone then onDone(ok, group) end
        end, nil, timer.getTime() + delaySec)
    else
        local ok, group = pcall(spawnObj.SpawnFromCoordinate, spawnObj, coord)
        if onDone then onDone(ok, group) end
    end
end
