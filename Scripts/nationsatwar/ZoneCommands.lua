-- Nations at War - Zone F10 commands: Swap, Kill All, Respawn All, Spawn Counter, Kill One.

NationsAtWar_ZoneData = NationsAtWar_ZoneData or {}
NationsAtWar_GroupToZone = NationsAtWar_GroupToZone or {}

local function isGroupAlive(group)
    if not group then return false end
    if group.IsAlive and group:IsAlive() then return true end
    if group.GetSize and group:GetSize() and group:GetSize() > 0 then return true end
    return false
end

local function getGroupName(group)
    if not group then return nil end
    return (group.GetName and group:GetName()) or (group.getName and group:getName())
end

local function areAllDefendersDead(zoneName)
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    if not data then return true end
    local ringGroups, squareGroups = data.ringGroups or {}, data.squareGroups or {}
    for slot = 1, 12 do
        local g = ringGroups[slot]
        if g and isGroupAlive(g) then return false end
    end
    for slot = 1, 4 do
        local g = squareGroups[slot]
        if g and isGroupAlive(g) then return false end
    end
    return true
end

local function hasOtherTeamUnitsInZone(zoneName)
    local centerCoord, radius
    local geom = NationsAtWar_ZoneGeometry and NationsAtWar_ZoneGeometry[zoneName]
    if geom and geom.centerCoord and geom.radius then
        centerCoord, radius = geom.centerCoord, geom.radius
    else
        local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
        if data and data.centerCoord and data.radius then
            centerCoord, radius = data.centerCoord, data.radius
        else
            local c, _, r = NationsAtWar_GetZoneCoord and NationsAtWar_GetZoneCoord(zoneName)
            centerCoord = c
            radius = (type(r) == "number" and r > 0) and r or 1000
        end
    end
    if not centerCoord then return false end
    local v = (centerCoord.GetVec3 and centerCoord:GetVec3()) or (centerCoord.GetVec2 and centerCoord:GetVec2())
    if not v then return false end
    -- DCS world.searchObjects expects a plain table for point (Vec3: x, y, z). Handle GetVec3 (x,y,z) and GetVec2 (x,z).
    local point
    if type(v) == "table" then
        if v.z ~= nil then
            point = { x = v.x or 0, y = v.y or 0, z = v.z }
        else
            point = { x = v.x or 0, y = 0, z = v.y or 0 }
        end
    else
        point = v
    end
    radius = (type(radius) == "number" and radius > 0) and radius or 1000
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
    local otherCoalitionId = (owner == "red") and 2 or 1  -- DCS: 1 = red, 2 = blue
    local found = false
    local vol = {
        id = world.VolumeType.SPHERE,
        params = { point = point, radius = radius },
    }
    local function handler(obj)
        if not obj or not obj.getCoalition then return true end
        local ok, coalitionId = pcall(function() return obj:getCoalition() end)
        if ok and coalitionId == otherCoalitionId then
            found = true
        end
        return true
    end
    pcall(function()
        if world and world.searchObjects then
            world.searchObjects(Object.Category.UNIT, vol, handler)
        end
    end)
    return found
end

function NationsAtWar_HasOtherTeamUnitsInZone(zoneName)
    return hasOtherTeamUnitsInZone(zoneName)
end

--- True if any owner-coalition unit is in the zone (defenders or other).
local function hasOwnerUnitsInZone(zoneName)
    local centerCoord, radius
    local geom = NationsAtWar_ZoneGeometry and NationsAtWar_ZoneGeometry[zoneName]
    if geom and geom.centerCoord and geom.radius then
        centerCoord, radius = geom.centerCoord, geom.radius
    else
        local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
        if data and data.centerCoord and data.radius then
            centerCoord, radius = data.centerCoord, data.radius
        else
            local c, _, r = NationsAtWar_GetZoneCoord and NationsAtWar_GetZoneCoord(zoneName)
            centerCoord = c
            radius = (type(r) == "number" and r > 0) and r or 1000
        end
    end
    if not centerCoord then return false end
    local v = (centerCoord.GetVec3 and centerCoord:GetVec3()) or (centerCoord.GetVec2 and centerCoord:GetVec2())
    if not v then return false end
    local point = (type(v) == "table" and v.z ~= nil) and { x = v.x or 0, y = v.y or 0, z = v.z } or { x = v.x or 0, y = 0, z = v.y or 0 }
    radius = (type(radius) == "number" and radius > 0) and radius or 1000
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
    local ownerCoalitionId = (owner == "red") and 1 or 2
    local found = false
    local vol = { id = world.VolumeType.SPHERE, params = { point = point, radius = radius } }
    local function handler(obj)
        if obj and obj.getCoalition then
            local ok, cid = pcall(function() return obj:getCoalition() end)
            if ok and cid == ownerCoalitionId then found = true end
        end
        return true
    end
    pcall(function()
        if world and world.searchObjects then world.searchObjects(Object.Category.UNIT, vol, handler) end
    end)
    return found
end

function NationsAtWar_HasOwnerUnitsInZone(zoneName)
    return hasOwnerUnitsInZone(zoneName)
end

--- True if any friendly (owner) unit in zone is NOT part of the zone's defender set. Used for health B (0 or 20).
local function hasAnyOutsideFriendlyInZone(zoneName)
    local defenderNames = NationsAtWar_GetDefenderGroupNames and NationsAtWar_GetDefenderGroupNames(zoneName)
    if not defenderNames or type(defenderNames) ~= "table" then return false end
    local centerCoord, radius
    local geom = NationsAtWar_ZoneGeometry and NationsAtWar_ZoneGeometry[zoneName]
    if geom and geom.centerCoord and geom.radius then
        centerCoord, radius = geom.centerCoord, geom.radius
    else
        local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
        if data and data.centerCoord and data.radius then
            centerCoord, radius = data.centerCoord, data.radius
        else
            local c, _, r = NationsAtWar_GetZoneCoord and NationsAtWar_GetZoneCoord(zoneName)
            centerCoord, radius = c, (type(r) == "number" and r > 0) and r or 1000
        end
    end
    if not centerCoord then return false end
    local v = (centerCoord.GetVec3 and centerCoord:GetVec3()) or (centerCoord.GetVec2 and centerCoord:GetVec2())
    if not v then return false end
    local point = (type(v) == "table" and v.z ~= nil) and { x = v.x or 0, y = v.y or 0, z = v.z } or { x = v.x or 0, y = 0, z = v.y or 0 }
    radius = (type(radius) == "number" and radius > 0) and radius or 1000
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
    local ownerCoalitionId = (owner == "red") and 1 or 2
    local foundOutside = false
    local vol = { id = world.VolumeType.SPHERE, params = { point = point, radius = radius } }
    local function handler(obj)
        if not obj or not obj.getCoalition then return true end
        local ok, cid = pcall(function() return obj:getCoalition() end)
        if not ok or cid ~= ownerCoalitionId then return true end
        local gname
        pcall(function()
            if obj.getGroup and obj:getGroup() then
                local grp = obj:getGroup()
                if grp and grp.getName then gname = grp:getName() end
            end
        end)
        if gname and type(gname) == "string" and defenderNames[gname] ~= true then
            foundOutside = true
        end
        return true
    end
    pcall(function()
        if world and world.searchObjects then world.searchObjects(Object.Category.UNIT, vol, handler) end
    end)
    return foundOutside
end

function NationsAtWar_HasAnyOutsideFriendlyInZone(zoneName)
    return hasAnyOutsideFriendlyInZone(zoneName)
end

--- Perform capture: set owner to other team, redraw F10, spawn new defenders (defenders already destroyed).
function NationsAtWar_DoZoneCapture(zoneName)
    if not zoneName then return end
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName)
    if not owner then return end
    local other = (owner == "red") and "blue" or "red"
    if NationsAtWar_SetZoneOwner then NationsAtWar_SetZoneOwner(zoneName, other) end
    if NationsAtWar_SetZoneCValue then NationsAtWar_SetZoneCValue(zoneName, 30) end
    if NationsAtWar_RedrawZoneOnMap then NationsAtWar_RedrawZoneOnMap(zoneName) end
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "Zone [%s]: captured by %s, spawning defenders", zoneName, other)
    end
    NationsAtWar_SpawnZoneDefenders(zoneName)
end

--- If all defenders dead and other team has units in zone, trigger capture. Call after a defender kill.
function NationsAtWar_CheckAndCaptureZone(zoneName)
    if not zoneName then return end
    if not areAllDefendersDead(zoneName) then return end
    if not hasOtherTeamUnitsInZone(zoneName) then return end
    NationsAtWar_DoZoneCapture(zoneName)
end

--- Swap zone owner to the other team (capture): kill all defenders, set owner, redraw F10, spawn new owner's defenders.
function NationsAtWar_SwapZone(zoneName)
    if not zoneName then return end
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName)
    if not owner then return end
    local other = (owner == "red") and "blue" or "red"
    NationsAtWar_KillAllZone(zoneName)
    if NationsAtWar_SetZoneOwner then NationsAtWar_SetZoneOwner(zoneName, other) end
    if NationsAtWar_RedrawZoneOnMap then
        NationsAtWar_RedrawZoneOnMap(zoneName)
    end
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "Zone [%s]: captured by %s, spawning defenders", zoneName, other)
    end
    NationsAtWar_SpawnZoneDefenders(zoneName)
end

--- Kill all units spawned by the zone; clear zone data and group-to-zone map.
function NationsAtWar_KillAllZone(zoneName)
    if not zoneName then return end
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    if not data then
        if NationsAtWar_Log then NationsAtWar_Log("info", "Zone [%s]: no zone data (no units to kill)", zoneName) end
        return
    end
    local namesToRemove = {}
    local ringGroups, squareGroups = data.ringGroups or {}, data.squareGroups or {}
    for slot = 1, 12 do
        local g = ringGroups[slot]
        if g then
            local name = getGroupName(g)
            if name then namesToRemove[name] = true end
            if g.Destroy and isGroupAlive(g) then pcall(function() g:Destroy() end) end
        end
    end
    for slot = 1, 4 do
        local g = squareGroups[slot]
        if g then
            local name = getGroupName(g)
            if name then namesToRemove[name] = true end
            if g.Destroy and isGroupAlive(g) then pcall(function() g:Destroy() end) end
        end
    end
    for name, _ in pairs(namesToRemove) do
        if NationsAtWar_GroupToZone then NationsAtWar_GroupToZone[name] = nil end
    end
    NationsAtWar_ZoneData[zoneName] = nil
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "Zone [%s]: killed all units", zoneName)
    end
end

--- Spawn current owner's defenders at ring + square (uses stored geometry). Used by Respawn All and after Swap (capture).
function NationsAtWar_SpawnZoneDefenders(zoneName)
    if not zoneName then return end
    local centerCoord, radius, foundName
    local geom = NationsAtWar_ZoneGeometry and NationsAtWar_ZoneGeometry[zoneName]
    if geom and geom.centerCoord and geom.radius then
        centerCoord = geom.centerCoord
        radius = geom.radius
        foundName = zoneName
    else
        local cz, fn, zr = NationsAtWar_GetZoneCoord and NationsAtWar_GetZoneCoord(zoneName)
        centerCoord, foundName = cz, fn
        radius = (type(zr) == "number" and zr > 0) and zr or 1000
    end
    if not centerCoord then
        if NationsAtWar_Log then NationsAtWar_Log("warning", "Zone [%s]: no coord for spawn", zoneName) end
        return
    end
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
    local zoneUnits = NationsAtWarConfig and NationsAtWarConfig.ZoneUnits and NationsAtWarConfig.ZoneUnits[zoneName]
    local ownerUnits = zoneUnits and zoneUnits[owner]
    if not ownerUnits or type(ownerUnits) ~= "table" or #ownerUnits == 0 then
        if NationsAtWar_Log then NationsAtWar_Log("warning", "Zone [%s]: no unit templates for owner %s", zoneName, owner) end
        return
    end
    local spawnCoords = NationsAtWar_GetZoneSpawnPositions and NationsAtWar_GetZoneSpawnPositions(centerCoord, radius)
    if not spawnCoords or #spawnCoords == 0 then
        if NationsAtWar_Log then NationsAtWar_Log("warning", "Zone [%s]: no spawn positions", zoneName) end
        return
    end
    NationsAtWar_SpawnGroupsAtCoordsDelayed(ownerUnits, spawnCoords, 2, function(spawned, total, groups)
        if total > 0 and NationsAtWar_Log then
            NationsAtWar_Log("info", "Zone [%s] (%s): spawned %d/%d unit groups", foundName or zoneName, owner, spawned, total)
        end
        if groups and #groups > 0 and NationsAtWar_RegisterZoneUnits then
            NationsAtWar_RegisterZoneUnits(zoneName, centerCoord, radius, groups)
        end
    end)
end

--- Kill all zone units then respawn for current owner (ring + square).
function NationsAtWar_RespawnAllZone(zoneName)
    if not zoneName then return end
    NationsAtWar_KillAllZone(zoneName)
    NationsAtWar_SpawnZoneDefenders(zoneName)
end

--- Replenish one missing defender group at the first dead/empty slot. Used by factory zones on a timer.
function NationsAtWar_ReplenishZone(zoneName)
    if not zoneName then return end
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    if not data or not data.centerCoord or not data.radius then return end
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
    local zoneUnits = NationsAtWarConfig and NationsAtWarConfig.ZoneUnits and NationsAtWarConfig.ZoneUnits[zoneName]
    local ownerUnits = zoneUnits and zoneUnits[owner]
    if not ownerUnits or type(ownerUnits) ~= "table" or #ownerUnits == 0 then return end
    local templateName = ownerUnits[1]
    if not templateName or type(templateName) ~= "string" or templateName == "" then return end
    local ringGroups = data.ringGroups or {}
    local squareGroups = data.squareGroups or {}
    local slot = nil
    for s = 1, 12 do
        local g = ringGroups[s]
        if not g or not isGroupAlive(g) then slot = s break end
    end
    if not slot then
        for s = 1, 4 do
            local g = squareGroups[s]
            if not g or not isGroupAlive(g) then slot = 12 + s break end
        end
    end
    if not slot then return end
    local coord = NationsAtWar_GetZoneSlotCoord and NationsAtWar_GetZoneSlotCoord(zoneName, slot)
    if not coord then return end
    if not NationsAtWar_EnsureSpawnTemplate then return end
    NationsAtWar_EnsureSpawnTemplate(templateName)
    local okNew, spawnObj = pcall(SPAWN.New, SPAWN, templateName)
    if not okNew or not spawnObj then return end
    local delaySec = 1
    if NationsAtWar_SpawnAtCoordDelayed then
        NationsAtWar_SpawnAtCoordDelayed(spawnObj, coord, delaySec, function(ok, group)
            if ok and group and NationsAtWar_RegisterZoneUnitReplenish then
                NationsAtWar_RegisterZoneUnitReplenish(zoneName, slot, group)
                if NationsAtWar_Log then
                    NationsAtWar_Log("info", "Zone [%s]: replenished slot %d (%s)", zoneName, slot, templateName)
                end
            end
        end)
    end
end

--- Spawn one group of the other team at zone center (counter to capture). Uses CounterSpawnTemplates (NaW_Test_1INF_B / NaW_Test_1INF_R).
function NationsAtWar_SpawnCounterZone(zoneName)
    if not zoneName then return end
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
    local other = (owner == "red") and "blue" or "red"
    local counterTemplates = NationsAtWarConfig and NationsAtWarConfig.CounterSpawnTemplates
    local templateName = counterTemplates and counterTemplates[other]
    if not templateName or type(templateName) ~= "string" or templateName == "" then
        if NationsAtWar_Log then NationsAtWar_Log("warning", "Zone [%s]: no CounterSpawnTemplates[%s]", zoneName, other) end
        return
    end
    local centerCoord = NationsAtWar_GetZoneCoord and NationsAtWar_GetZoneCoord(zoneName)
    if not centerCoord then
        if NationsAtWar_Log then NationsAtWar_Log("warning", "Zone [%s]: no coord for counter spawn", zoneName) end
        return
    end
    if not NationsAtWar_EnsureSpawnTemplate then return end
    NationsAtWar_EnsureSpawnTemplate(templateName)
    local okNew, spawnObj = pcall(SPAWN.New, SPAWN, templateName)
    if not okNew or not spawnObj then
        if NationsAtWar_Log then NationsAtWar_Log("warning", "Zone [%s]: SPAWN.New(%s) failed", zoneName, templateName) end
        return
    end
    -- Use single-spawn helper with 1s delay so spawn runs in timer context (menu callback can fail to spawn same frame).
    local delaySec = 1
    if NationsAtWar_SpawnAtCoordDelayed then
        NationsAtWar_SpawnAtCoordDelayed(spawnObj, centerCoord, delaySec, function(ok, group)
            if NationsAtWar_Log then
                if ok and group then
                    NationsAtWar_Log("info", "Zone [%s]: spawned counter %s at center", zoneName, templateName)
                else
                    NationsAtWar_Log("warning", "Zone [%s]: counter spawn %s failed", zoneName, templateName)
                end
            end
            -- Re-check capture shortly after spawn so we don't wait for the next periodic tick (defenders dead + counter in zone).
            if ok and timer and timer.scheduleFunction and timer.getTime and NationsAtWar_CheckAndCaptureZone then
                timer.scheduleFunction(function()
                    NationsAtWar_CheckAndCaptureZone(zoneName)
                end, nil, timer.getTime() + 2)
            end
        end)
    end
end

--- Kill one unit in the zone and trigger redistribution (ring/square move orders).
function NationsAtWar_KillOneZoneUnit(zoneName)
    if not zoneName then return end
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    if not data or type(data) ~= "table" then
        if NationsAtWar_Log then NationsAtWar_Log("warning", "Zone [%s]: no zone data", zoneName) end
        return
    end
    local all = {}
    local ringGroups, squareGroups = data.ringGroups or {}, data.squareGroups or {}
    for slot = 1, 12 do local g = ringGroups[slot]; if g then table.insert(all, g) end end
    for slot = 1, 4 do local g = squareGroups[slot]; if g then table.insert(all, g) end end
    for _, group in ipairs(all) do
        if isGroupAlive(group) then
            local groupName = getGroupName(group)
            if groupName then
                local ok = pcall(function()
                    local dcsGroup = Group.getByName(groupName)
                    if not dcsGroup or not dcsGroup.getUnit then return end
                    local dcsUnit = dcsGroup:getUnit(1)
                    if dcsUnit and dcsUnit.destroy then dcsUnit:destroy() end
                end)
                if ok and NationsAtWar_RedistributeZone then
                    NationsAtWar_RedistributeZone(zoneName)
                end
                -- Health update is done by player-kill handler (onKill in ZoneMovement.lua), triggered when unit is destroyed.
                if NationsAtWar_Log and not ok then
                    NationsAtWar_Log("warning", "Zone [%s]: kill one failed", zoneName)
                end
                return
            end
        end
    end
    if NationsAtWar_Log then
        NationsAtWar_Log("warning", "Zone [%s]: no living unit to kill", zoneName)
    end
end

--- Kill two units in the zone: one immediately, one after 0.5 s. Triggers redistribution after each.
function NationsAtWar_KillTwoZoneUnitsFast(zoneName)
    if not zoneName then return end
    if not NationsAtWar_KillOneZoneUnit then return end
    NationsAtWar_KillOneZoneUnit(zoneName)
    if timer and timer.scheduleFunction and timer.getTime then
        timer.scheduleFunction(function()
            if NationsAtWar_KillOneZoneUnit then NationsAtWar_KillOneZoneUnit(zoneName) end
        end, nil, timer.getTime() + 0.5)
    else
        NationsAtWar_KillOneZoneUnit(zoneName)
    end
end
