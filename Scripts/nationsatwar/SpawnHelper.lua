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

-- Spawn a list of late-activated group templates at a coordinate (e.g. zone center). delaySec then spawn all.
function NationsAtWar_SpawnGroupsAtCoordDelayed(groupNames, coord, delaySec, onDone)
    if not groupNames or type(groupNames) ~= "table" or not coord then
        if onDone then onDone(0, #(groupNames or {})) end
        return
    end
    delaySec = delaySec or 3
    local spawnObjs = {}
    for _, templateName in ipairs(groupNames) do
        if templateName and type(templateName) == "string" and templateName ~= "" then
            NationsAtWar_EnsureSpawnTemplate(templateName)
            local ok, spawnObj = pcall(SPAWN.New, SPAWN, templateName)
            if ok and spawnObj then
                table.insert(spawnObjs, { name = templateName, obj = spawnObj })
            end
        end
    end
    local n = #spawnObjs
    if n == 0 then
        if onDone then onDone(0, 0) end
        return
    end
    local function doSpawn()
        local spawned = 0
        for _, entry in ipairs(spawnObjs) do
            local ok = pcall(entry.obj.SpawnFromCoordinate, entry.obj, coord)
            if ok then spawned = spawned + 1 end
        end
        if onDone then onDone(spawned, n) end
    end
    if timer and timer.scheduleFunction then
        timer.scheduleFunction(function() doSpawn() end, nil, timer.getTime() + delaySec)
    else
        doSpawn()
    end
end

-- Spawn group templates at a list of coordinates. Templates cycle. onDone(spawned, total, groups) with groups in order of coords.
function NationsAtWar_SpawnGroupsAtCoordsDelayed(groupNames, coords, delaySec, onDone)
    if not groupNames or type(groupNames) ~= "table" or not coords or type(coords) ~= "table" then
        if onDone then onDone(0, 0, {}) end
        return
    end
    delaySec = delaySec or 3
    local templates = {}
    for _, templateName in ipairs(groupNames) do
        if templateName and type(templateName) == "string" and templateName ~= "" then
            NationsAtWar_EnsureSpawnTemplate(templateName)
            local ok, spawnObj = pcall(SPAWN.New, SPAWN, templateName)
            if ok and spawnObj then
                table.insert(templates, spawnObj)
            end
        end
    end
    local nTemplates = #templates
    local nCoords = #coords
    if nTemplates == 0 or nCoords == 0 then
        if onDone then onDone(0, nCoords, {}) end
        return
    end
    local function doSpawn()
        local spawned = 0
        local groups = {}
        for i, coord in ipairs(coords) do
            if coord then
                local idx = ((i - 1) % nTemplates) + 1
                local ok, group = pcall(templates[idx].SpawnFromCoordinate, templates[idx], coord)
                if ok and group then
                    spawned = spawned + 1
                    table.insert(groups, { group = group, coordIndex = i })
                end
            end
        end
        if onDone then onDone(spawned, nCoords, groups) end
    end
    if timer and timer.scheduleFunction then
        timer.scheduleFunction(function() doSpawn() end, nil, timer.getTime() + delaySec)
    else
        doSpawn()
    end
end
