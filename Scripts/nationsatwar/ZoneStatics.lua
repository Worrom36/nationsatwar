-- Nations at War - Zone static objects: spawn, kill, health. ME markers + dictionary (Option B).

NationsAtWar_ZoneData = NationsAtWar_ZoneData or {}
-- Per-zone list of static definitions (type, x, y, heading) from ME markers. Built once.
NationsAtWar_ZoneStaticDefinitions = NationsAtWar_ZoneStaticDefinitions or {}
-- Total static count at registration (for health A).
NationsAtWar_ZoneDefenderStaticCount = NationsAtWar_ZoneDefenderStaticCount or {}
-- Static object name -> zone name (for S_EVENT_DEAD).
NationsAtWar_StaticNameToZone = NationsAtWar_StaticNameToZone or {}

local _cfg = NationsAtWarConfig
local DEFAULT_CATEGORY = "Fortifications"

--- Recursively find a group table with group.name == groupName and group.units[1]. Return first unit x, y, heading.
local function findGroupInTable(t, groupName, depth)
    depth = (depth or 0) + 1
    if depth > 20 or not t or type(t) ~= "table" then return nil end
    local gname = t.name or t.groupName
    if type(gname) == "string" and gname == groupName then
        local units = t.units
        if type(units) == "table" and #units >= 1 then
            local u = units[1]
            local x = type(u.x) == "number" and u.x or nil
            local y = type(u.y) == "number" and u.y or (type(u.z) == "number" and u.z or nil)
            local heading = type(u.heading) == "number" and u.heading or 0
            if x and y then
                return { x = x, y = y, heading = heading }
            end
        end
        return nil
    end
    for _, val in pairs(t) do
        if type(val) == "table" then
            local res = findGroupInTable(val, groupName, depth)
            if res then return res end
        end
    end
    return nil
end

--- Find group in env.mission by name. Walks coalition tree (any keys: red/blue, 1/2, country.group or country.plane/vehicle/etc).
local function getGroupPositionFromMission(groupName)
    if not env or not env.mission or not groupName or type(groupName) ~= "string" then return nil end
    local coalition = env.mission.coalition
    if not coalition or type(coalition) ~= "table" then return nil end
    for _, side in pairs(coalition) do
        if type(side) == "table" then
            local res = findGroupInTable(side, groupName, 0)
            if res then return res end
        end
    end
    return nil
end

--- Build NationsAtWar_ZoneStaticDefinitions from ME marker groups. Call once at init (or on first use).
function NationsAtWar_BuildZoneStaticDefinitions()
    local markerGroups = _cfg and _cfg.ZoneStaticMarkerGroups
    local typeFromName = _cfg and _cfg.StaticTypeFromName
    if NationsAtWar_Log then
        if not markerGroups or type(markerGroups) ~= "table" then
            NationsAtWar_Log("info", "Zone statics: ZoneStaticMarkerGroups missing or empty; no statics built")
        elseif not typeFromName or type(typeFromName) ~= "table" then
            NationsAtWar_Log("info", "Zone statics: StaticTypeFromName missing or empty; no statics built")
        end
    end
    if not markerGroups or type(markerGroups) ~= "table" or not typeFromName or type(typeFromName) ~= "table" then
        return
    end
    NationsAtWar_ZoneStaticDefinitions = NationsAtWar_ZoneStaticDefinitions or {}
    for zoneName, list in pairs(markerGroups) do
        if zoneName and type(zoneName) == "string" and list and type(list) == "table" then
            local defs = {}
            for _, groupName in ipairs(list) do
                if type(groupName) == "string" and groupName ~= "" then
                    local staticType = typeFromName[groupName]
                    if type(staticType) ~= "string" or staticType == "" then
                        if NationsAtWar_Log then
                            NationsAtWar_Log("warning", "Zone statics: [%s] marker [%s] has no StaticTypeFromName entry", zoneName, groupName)
                        end
                    else
                        local pos = getGroupPositionFromMission(groupName)
                        if pos then
                            table.insert(defs, { type = staticType, x = pos.x, y = pos.y, heading = pos.heading })
                            if NationsAtWar_Log then
                                NationsAtWar_Log("info", "Zone statics: [%s] marker [%s] -> type=%s at x=%.0f y=%.0f heading=%.1f", zoneName, groupName, staticType, pos.x, pos.y, pos.heading or 0)
                            end
                        elseif NationsAtWar_Log then
                            NationsAtWar_Log("warning", "Zone statics: marker group [%s] not found in mission", groupName)
                        end
                    end
                end
            end
            if #defs > 0 then
                NationsAtWar_ZoneStaticDefinitions[zoneName] = defs
                if NationsAtWar_Log then
                    NationsAtWar_Log("info", "Zone statics: [%s] built %d static definition(s)", zoneName, #defs)
                end
            elseif NationsAtWar_Log then
                NationsAtWar_Log("warning", "Zone statics: [%s] no valid definitions", zoneName)
            end
        end
    end
end

--- Return list of static definitions for zone (from ME markers or nil if none).
local function getZoneStaticDefinitions(zoneName)
    if not zoneName then return nil end
    if not NationsAtWar_ZoneStaticDefinitions[zoneName] then
        NationsAtWar_BuildZoneStaticDefinitions()
    end
    return NationsAtWar_ZoneStaticDefinitions[zoneName]
end

--- True if zone has static definitions (ME markers).
function NationsAtWar_ZoneHasStatics(zoneName)
    local defs = getZoneStaticDefinitions(zoneName)
    return defs and #defs > 0
end

--- Spawn zone statics for current owner. Stores names in ZoneData, sets ZoneDefenderStaticCount.
function NationsAtWar_SpawnZoneStatics(zoneName)
    if not zoneName or type(zoneName) ~= "string" then return end
    local defs = getZoneStaticDefinitions(zoneName)
    if not defs or #defs == 0 then
        if NationsAtWar_Log then
            NationsAtWar_Log("info", "Zone statics: [%s] spawn skipped (no definitions)", zoneName)
        end
        return
    end
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
    local countryIds = _cfg and _cfg.StaticCountryIds
    local countryId = countryIds and type(countryIds[owner]) == "number" and countryIds[owner]
    if not countryId then
        if NationsAtWar_Log then NationsAtWar_Log("warning", "Zone [%s]: no StaticCountryIds[%s]; statics not spawned", zoneName, owner) end
        return
    end
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "Zone statics: [%s] spawning %d static(s) for owner=%s countryId=%s", zoneName, #defs, owner, tostring(countryId))
    end
    NationsAtWar_ZoneData[zoneName] = NationsAtWar_ZoneData[zoneName] or {}
    local data = NationsAtWar_ZoneData[zoneName]
    local existingNames = data.staticObjectNames or {}
    for _, name in ipairs(existingNames) do
        NationsAtWar_StaticNameToZone[name] = nil
    end
    data.staticObjectNames = {}
    local spawnedNames = {}
    for i, def in ipairs(defs) do
        local name = string.format("%s_static_%s_%d", zoneName, owner, i)
        local ok, err = pcall(function()
            coalition.addStaticObject(countryId, {
                name = name,
                type = def.type,
                category = DEFAULT_CATEGORY,
                x = def.x,
                y = def.y,
                heading = def.heading or 0,
                groupId = 900000 + i,
                unitId = 900000 + i,
            })
        end)
        if ok then
            table.insert(spawnedNames, name)
            NationsAtWar_StaticNameToZone[name] = zoneName
            if NationsAtWar_Log then
                NationsAtWar_Log("info", "Zone statics: [%s] spawned static %d: type=%s name=%s at x=%.0f y=%.0f", zoneName, i, def.type, name, def.x, def.y)
            end
        elseif NationsAtWar_Log then
            NationsAtWar_Log("warning", "Zone [%s]: failed to spawn static %d type=%s: %s", zoneName, i, def.type, tostring(err))
        end
    end
    data.staticObjectNames = spawnedNames
    NationsAtWar_ZoneDefenderStaticCount[zoneName] = #spawnedNames
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "Zone [%s] (%s): spawned %d/%d statics", zoneName, tostring(owner), #spawnedNames, #defs)
    end
end

--- Apply damage equal to object's full health (so it dies from HP loss). Uses MOOSE-style net.dostring_in with a_unit_set_life_percentage(id, 0); falls back to destroy().
local function damageStaticToZero(obj)
    if not obj then return end
    local okId, id = pcall(function() return obj:getID() end)
    if okId and id and net and net.dostring_in then
        pcall(net.dostring_in, "mission", string.format("a_unit_set_life_percentage(%s, 0)", tostring(id)))
    end
    pcall(function() obj:destroy() end)
end

--- Kill all zone statics; clear stored names and StaticNameToZone. Applies damage equal to full health then destroys (MOOSE a_unit_set_life_percentage when available).
function NationsAtWar_KillZoneStatics(zoneName)
    if not zoneName then return end
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    local names = data and data.staticObjectNames
    if not names or type(names) ~= "table" then return end
    for _, name in ipairs(names) do
        local ok, obj = pcall(StaticObject.getByName, name)
        if ok and obj and obj.isExist and obj:isExist() then
            if STATIC and type(STATIC.FindByName) == "function" then
                local okStatic, static = pcall(function() return STATIC:FindByName(name, false) end)
                if okStatic and static and type(static) == "table" and type(static.SetLife) == "function" then
                    pcall(function() static:SetLife(0) end)
                end
            end
            damageStaticToZero(obj)
        end
        NationsAtWar_StaticNameToZone[name] = nil
    end
    data.staticObjectNames = {}
    if NationsAtWar_ZoneDefenderStaticCount then
        NationsAtWar_ZoneDefenderStaticCount[zoneName] = 0
    end
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "Zone [%s]: killed all statics", zoneName)
    end
end

--- Count living zone statics (for health A).
function NationsAtWar_CountLivingZoneStatics(zoneName)
    if not zoneName then return 0 end
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    local names = data and data.staticObjectNames
    if not names or type(names) ~= "table" then return 0 end
    local n = 0
    for _, name in ipairs(names) do
        local ok, obj = pcall(StaticObject.getByName, name)
        if ok and obj and obj.isExist and obj:isExist() then
            n = n + 1
        end
    end
    return n
end

--- Resolve zone name from static object name (for S_EVENT_DEAD).
function NationsAtWar_GetZoneFromStaticName(staticName)
    return NationsAtWar_StaticNameToZone and NationsAtWar_StaticNameToZone[staticName]
end

--- Install S_EVENT_DEAD handler for zone statics: use EventData.IniUnitName, resolve zone, update health.
function NationsAtWar_InstallZoneStaticDeathHandler()
    if not world or not world.addEventHandler then return end
    local S_EVENT_DEAD = 28
    local handler = {}
    function handler:onEvent(event)
        if type(event) ~= "table" or event.id ~= S_EVENT_DEAD then return end
        local staticName = event.IniUnitName or event.iniUnitName
        if not staticName or type(staticName) ~= "string" then return end
        local zoneName = NationsAtWar_GetZoneFromStaticName(staticName)
        if zoneName and NationsAtWar_UpdateZoneHealthAndDisplay then
            NationsAtWar_UpdateZoneHealthAndDisplay(zoneName)
        end
    end
    world.addEventHandler(handler)
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "Zone statics: S_EVENT_DEAD handler installed")
    end
end
NationsAtWar_InstallZoneStaticDeathHandler()
