-- Nations at War - Zone helpers (lookup, coords, draw on F10).

-- Zone health 0–100 per zone. Use Get/Set; init sets from Config.ZoneInitialHealth (default 75).
NationsAtWar_ZoneHealth = NationsAtWar_ZoneHealth or {}
-- Health display queue and state (drawing is in RenderDigits.lua).
NationsAtWar_ZoneHealthLastDrawn = NationsAtWar_ZoneHealthLastDrawn or {}
NationsAtWar_ZoneHealthLastDrawStartId = NationsAtWar_ZoneHealthLastDrawStartId or {}
NationsAtWar_ZoneHealthUpdateQueue = NationsAtWar_ZoneHealthUpdateQueue or {}
NationsAtWar_ZoneHealthDrawScheduled = NationsAtWar_ZoneHealthDrawScheduled or false
NationsAtWar_ZoneHealthLastCoord = NationsAtWar_ZoneHealthLastCoord or {}

function NationsAtWar_GetZoneHealth(zoneName)
    if not zoneName then return 75 end
    local v = NationsAtWar_ZoneHealth[zoneName]
    if type(v) ~= "number" then return (NationsAtWarConfig and type(NationsAtWarConfig.ZoneInitialHealth) == "number") and NationsAtWarConfig.ZoneInitialHealth or 75 end
    if v < 0 then return 0 elseif v > 100 then return 100 end
    return v
end

function NationsAtWar_SetZoneHealth(zoneName, value)
    if not zoneName then return end
    local n = tonumber(value)
    if not n then return end
    local clamped = (n < 0 and 0) or (n > 100 and 100) or n
    local current = NationsAtWar_ZoneHealth and NationsAtWar_ZoneHealth[zoneName]
    if current == clamped then return end
    NationsAtWar_ZoneHealth[zoneName] = clamped
    -- Factory reinforcements: when health crosses to or below threshold, trigger once per ownership + idle cooldown.
    local threshold = (NationsAtWarConfig and type(NationsAtWarConfig.ReinforcementHealthThreshold) == "number") and NationsAtWarConfig.ReinforcementHealthThreshold or 50
    if clamped <= threshold and (current == nil or current > threshold) and NationsAtWar_OnZoneHealthBelow50 then
        NationsAtWar_OnZoneHealthBelow50(zoneName)
    end
end

function NationsAtWar_GetZone(zoneName)
    if not zoneName or not ZONE or not ZONE.FindByName then return nil end
    return ZONE:FindByName(zoneName)
end

function NationsAtWar_GetZoneCoord(zoneName)
    if not zoneName or not env.mission or not env.mission.triggers or not env.mission.triggers.zones then
        return nil, nil, nil
    end
    local nameLower = zoneName:lower()
    for _, zoneData in pairs(env.mission.triggers.zones) do
        local name = zoneData.name
        if name and (name == zoneName or name:lower() == nameLower or name:lower():find(nameLower, 1, true)) then
            if zoneData.x and zoneData.y and COORDINATE and COORDINATE.NewFromVec2 then
                local radius = zoneData.radius
                if not radius and zoneData.type == 0 and trigger.misc and trigger.misc.getZone then
                    local z = trigger.misc.getZone(name)
                    if z and z.radius then radius = z.radius end
                end
                return COORDINATE:NewFromVec2({ x = zoneData.x, y = zoneData.y }), name, radius
            end
            break
        end
    end
    local zone = NationsAtWar_GetZone(zoneName)
    if zone and zone.GetCoordinate then
        local r = (zone.GetRadius and zone:GetRadius()) or nil
        return zone:GetCoordinate(), zoneName, r
    end
    return nil, nil, nil
end

--- Get zone center as { x, y, z } and radius from mission data (no DCS objects). For use in timer callbacks where coord objects may be invalid.
function NationsAtWar_GetZoneCenterAndRadius(zoneName)
    if not zoneName or not env.mission or not env.mission.triggers or not env.mission.triggers.zones then
        return nil, nil
    end
    local nameLower = zoneName:lower()
    for _, zoneData in pairs(env.mission.triggers.zones) do
        local name = zoneData.name
        if name and (name == zoneName or name:lower() == nameLower or name:lower():find(nameLower, 1, true)) then
            local x = type(zoneData.x) == "number" and zoneData.x or 0
            local z = type(zoneData.y) == "number" and zoneData.y or 0
            local r = type(zoneData.radius) == "number" and zoneData.radius > 0 and zoneData.radius or 1000
            return { x = x, y = 0, z = z }, r
        end
    end
    return nil, nil
end

function NationsAtWar_DrawZoneOnMap(zoneName, opts)
    if not zoneName then return end
    opts = opts or {}
    local zone = NationsAtWar_GetZone(zoneName)
    if not zone or not zone.DrawZone then return end
    local color = opts.color or {0, 1, 0}
    local alpha = opts.alpha or 1
    local fillColor = opts.fillColor or color
    local fillAlpha = opts.fillAlpha or 0.2
    local coalition = opts.coalition or -1
    local lineType = opts.lineType or 1
    local readonly = opts.readonly ~= false
    zone:DrawZone(coalition, color, alpha, fillColor, fillAlpha, lineType, readonly)
end

-- Returns n COORDINATEs equally spaced on the circle at full radius. rotationOffsetRad optional (radians).
function NationsAtWar_GetZoneRingPositions(centerCoord, zoneRadius, n, rotationOffsetRad)
    if not centerCoord or not centerCoord.GetVec3 or not COORDINATE or not COORDINATE.NewFromVec2 then
        return {}
    end
    local r = (type(zoneRadius) == "number" and zoneRadius > 0) and zoneRadius or 1000
    local num = (type(n) == "number" and n > 0) and n or 12
    local v = centerCoord:GetVec3()
    local cx, cz = v.x, v.z
    local offset = type(rotationOffsetRad) == "number" and rotationOffsetRad or 0
    local coords = {}
    local pi = math.pi
    for i = 0, num - 1 do
        local theta = (i / num) * 2 * pi + offset
        local x = cx + r * math.cos(theta)
        local z = cz + r * math.sin(theta)
        table.insert(coords, COORDINATE:NewFromVec2({ x = x, y = z }))
    end
    return coords
end

-- Returns up to 4 COORDINATEs at half radius (square corners at 45,135,225,315 deg). Optional count (default 4).
function NationsAtWar_GetZoneSquarePositions(centerCoord, zoneRadius, count)
    if not centerCoord or not centerCoord.GetVec3 or not COORDINATE or not COORDINATE.NewFromVec2 then
        return {}
    end
    local r = (type(zoneRadius) == "number" and zoneRadius > 0) and zoneRadius or 1000
    local half = r * 0.5
    local v = centerCoord:GetVec3()
    local cx, cz = v.x, v.z
    local n = (type(count) == "number" and count >= 0) and math.min(4, count) or 4
    local coords = {}
    local pi = math.pi
    local angles = { 45, 135, 225, 315 }
    for i = 1, n do
        local angleDeg = angles[i]
        local theta = (angleDeg / 180) * pi
        local x = cx + half * math.cos(theta)
        local z = cz + half * math.sin(theta)
        table.insert(coords, COORDINATE:NewFromVec2({ x = x, y = z }))
    end
    return coords
end

-- Returns ring then square COORDINATEs (for initial spawn). Counts from Config DefenderRingSlots, DefenderSquareSlots.
function NationsAtWar_GetZoneSpawnPositions(centerCoord, zoneRadius)
    local cfg = NationsAtWarConfig
    local ringSlots = (cfg and type(cfg.DefenderRingSlots) == "number" and cfg.DefenderRingSlots > 0) and cfg.DefenderRingSlots or 12
    local squareSlots = (cfg and type(cfg.DefenderSquareSlots) == "number" and cfg.DefenderSquareSlots > 0) and cfg.DefenderSquareSlots or 4
    local ring = NationsAtWar_GetZoneRingPositions(centerCoord, zoneRadius, ringSlots, 0)
    local square = NationsAtWar_GetZoneSquarePositions(centerCoord, zoneRadius, squareSlots)
    local coords = {}
    for _, c in ipairs(ring) do table.insert(coords, c) end
    for _, c in ipairs(square) do table.insert(coords, c) end
    return coords
end

-- Unique numeric ids per zone so each zone circle is drawn separately (DCS id must be unique).
NationsAtWar_ZoneCircleId = NationsAtWar_ZoneCircleId or {}
NationsAtWar_NextZoneCircleId = NationsAtWar_NextZoneCircleId or 1

function NationsAtWar_DrawZoneOnMapFromCoord(coord, foundName, radius, opts)
    if not coord then return false end
    opts = opts or {}
    local color = opts.color or {0, 1, 0}
    local alpha = opts.alpha or 1
    local fillColor = opts.fillColor or color
    local fillAlpha = opts.fillAlpha or 0.2
    local coalition = opts.coalition or -1
    local lineType = opts.lineType or 1
    local readonly = opts.readonly ~= false
    local r = radius or 1000
    local idKey = foundName and tostring(foundName) or ""
    if idKey == "" then idKey = "_zone_" .. tostring(NationsAtWar_NextZoneCircleId) end
    if not NationsAtWar_ZoneCircleId[idKey] then
        NationsAtWar_ZoneCircleId[idKey] = NationsAtWar_NextZoneCircleId
        NationsAtWar_NextZoneCircleId = NationsAtWar_NextZoneCircleId + 1
    end
    local id = NationsAtWar_ZoneCircleId[idKey]
    local v = (coord.GetVec3 and coord:GetVec3()) or (coord.GetVec2 and coord:GetVec2())
    if not v then return false end
    local center = type(v) == "table" and v.z ~= nil and { x = v.x or 0, y = v.y or 0, z = v.z }
        or { x = v.x or 0, y = 0, z = v.y or 0 }
    if trigger and trigger.action and trigger.action.circleToAll then
        -- Remove existing circle so redraw (e.g. on capture) shows new color; DCS does not update circle appearance when same id is used. Skip when caller will remove then delay draw.
        if not opts.skipRemove and trigger.action.removeMark then
            pcall(trigger.action.removeMark, id)
        end
        local outlineColor = { color[1] or 0, color[2] or 1, color[3] or 0, alpha }
        local fill = { fillColor[1] or color[1], fillColor[2] or color[2], fillColor[3] or color[3], fillAlpha }
        pcall(trigger.action.circleToAll, coalition, id, center, r, outlineColor, fill, lineType, readonly, idKey)
        return true
    end
    if coord.CircleToAll then
        coord:CircleToAll(r, coalition, color, alpha, fillColor, fillAlpha, lineType, readonly, idKey)
        return true
    end
    return false
end

--- Redraw zone on F10 map. opts.blink = true: remove health digits then redraw (blink every tick).
-- Draws new circle with new id (same context as caller so circleToAll works), then removes old circle.
function NationsAtWar_RedrawZoneOnMap(zoneName, opts)
    if not zoneName then return false end
    opts = opts or {}
    local coord, radius
    local geom = NationsAtWar_ZoneGeometry and NationsAtWar_ZoneGeometry[zoneName]
    if geom and geom.centerCoord and geom.radius then
        coord, radius = geom.centerCoord, geom.radius
    else
        local c, _, r = NationsAtWar_GetZoneCoord(zoneName)
        coord, radius = c, (type(r) == "number" and r > 0) and r or 1000
    end
    if not coord then return false end
    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
    local zoneColors = (NationsAtWarConfig and NationsAtWarConfig.ZoneColors) or {}
    local drawColor = (zoneColors[owner] and type(zoneColors[owner]) == "table" and #zoneColors[owner] >= 3)
        and zoneColors[owner]
        or { 1, 0, 0 }
    local idKey = tostring(zoneName)
    NationsAtWar_ZoneCircleId = NationsAtWar_ZoneCircleId or {}
    local oldId = NationsAtWar_ZoneCircleId[idKey]
    NationsAtWar_NextZoneCircleId = NationsAtWar_NextZoneCircleId or 1
    local newId = NationsAtWar_NextZoneCircleId
    NationsAtWar_NextZoneCircleId = NationsAtWar_NextZoneCircleId + 1
    -- Draw new circle first (same context as menu so circleToAll works), then remove old. Use trigger.misc.getZone for DCS-native point/radius.
    local center, resRadius
    if trigger and trigger.misc and trigger.misc.getZone then
        local z = trigger.misc.getZone(zoneName)
        if z and z.point and z.radius then
            center, resRadius = z.point, z.radius
        end
    end
    if not center or not resRadius then
        center, resRadius = NationsAtWar_GetZoneCenterAndRadius and NationsAtWar_GetZoneCenterAndRadius(zoneName)
    end
    if center and resRadius and trigger and trigger.action and trigger.action.circleToAll then
        local outlineColor = { drawColor[1] or 0, drawColor[2] or 1, drawColor[3] or 0, 1 }
        local fill = { drawColor[1] or 0, drawColor[2] or 1, drawColor[3] or 0, 0.2 }
        pcall(trigger.action.circleToAll, -1, newId, center, resRadius, outlineColor, fill, 1, true, idKey)
        NationsAtWar_ZoneCircleId[idKey] = newId
        if oldId and trigger.action.removeMark then
            pcall(trigger.action.removeMark, oldId)
        end
        NationsAtWar_ZoneHealthUpdateQueue = NationsAtWar_ZoneHealthUpdateQueue or {}
        NationsAtWar_ZoneHealthUpdateQueue[zoneName] = true
        if NationsAtWar_ProcessZoneHealthUpdateQueue then NationsAtWar_ProcessZoneHealthUpdateQueue() end
        return true
    end
    local ok = NationsAtWar_DrawZoneOnMapFromCoord(coord, zoneName, radius, { color = drawColor, fillAlpha = 0.2, coalition = -1, readonly = true })
    if ok then
        NationsAtWar_ZoneGeometry = NationsAtWar_ZoneGeometry or {}
        NationsAtWar_ZoneGeometry[zoneName] = { centerCoord = coord, radius = radius }
        NationsAtWar_ZoneHealthUpdateQueue = NationsAtWar_ZoneHealthUpdateQueue or {}
        NationsAtWar_ZoneHealthUpdateQueue[zoneName] = true
        if NationsAtWar_ProcessZoneHealthUpdateQueue then NationsAtWar_ProcessZoneHealthUpdateQueue() end
    end
    return ok
end

--- Resolve coord for a zone (geom, lastCoord, GetZoneCoord). Returns coord or nil.
local function resolveZoneCoord(zoneName)
    local geom = NationsAtWar_ZoneGeometry and NationsAtWar_ZoneGeometry[zoneName]
    if geom and geom.centerCoord and geom.centerCoord.GetVec3 then return geom.centerCoord end
    local last = NationsAtWar_ZoneHealthLastCoord and NationsAtWar_ZoneHealthLastCoord[zoneName]
    if last and last.GetVec3 then return last end
    if NationsAtWar_GetZoneCoord then
        local c = NationsAtWar_GetZoneCoord(zoneName)
        if c and c.GetVec3 then return c end
    end
    return nil
end

--- Process queued health updates: hide now, schedule draw for 2s with captured zones+coords. Drawing in RenderDigits.
function NationsAtWar_ProcessZoneHealthUpdateQueue()
    local queue = NationsAtWar_ZoneHealthUpdateQueue
    if not queue or type(queue) ~= "table" then return end

    local seen = {}
    local zonesToUpdate = {}
    for zoneName, _ in pairs(queue) do
        if zoneName and type(zoneName) == "string" and zoneName ~= "" and not seen[zoneName] then
            seen[zoneName] = true
            table.insert(zonesToUpdate, zoneName)
        end
    end
    table.sort(zonesToUpdate)
    if #zonesToUpdate == 0 then return end

    local lineCount = NationsAtWar_TwoDigitsLineCount or 14
    local coordsByZone = {}
    for _, zoneName in ipairs(zonesToUpdate) do
        local coord = resolveZoneCoord(zoneName)
        if coord and coord.GetVec3 then coordsByZone[zoneName] = coord end
    end

    for _, zoneName in ipairs(zonesToUpdate) do
        local startId = NationsAtWar_ZoneHealthLastDrawStartId and NationsAtWar_ZoneHealthLastDrawStartId[zoneName]
        if startId and type(startId) == "number" and trigger and trigger.action and trigger.action.removeMark then
            for id = startId, startId + lineCount - 1 do
                pcall(trigger.action.removeMark, id)
            end
        end
    end

    if NationsAtWar_ZoneHealthDrawScheduled then
        NationsAtWar_ZoneHealthUpdateQueue = NationsAtWar_ZoneHealthUpdateQueue or {}
        for _, zoneName in ipairs(zonesToUpdate) do NationsAtWar_ZoneHealthUpdateQueue[zoneName] = true end
        return
    end
    NationsAtWar_ZoneHealthDrawScheduled = true

    local BLANK_SEC = 2.0
    if timer and timer.scheduleFunction and timer.getTime then
        timer.scheduleFunction(function()
            NationsAtWar_ZoneHealthDrawScheduled = false
            local q = NationsAtWar_ZoneHealthUpdateQueue
            if not q or type(q) ~= "table" then return end
            local seen2 = {}
            local zones = {}
            for zoneName, _ in pairs(q) do
                if zoneName and type(zoneName) == "string" and zoneName ~= "" and not seen2[zoneName] then
                    seen2[zoneName] = true
                    table.insert(zones, zoneName)
                end
            end
            table.sort(zones)
            if #zones == 0 then return end
            NationsAtWar_ZoneHealthLastDrawStartId = NationsAtWar_ZoneHealthLastDrawStartId or {}
            NationsAtWar_ZoneHealthLastDrawn = NationsAtWar_ZoneHealthLastDrawn or {}
            NationsAtWar_ZoneHealthLastCoord = NationsAtWar_ZoneHealthLastCoord or {}
            for _, zoneName in ipairs(zones) do
                local coord = coordsByZone[zoneName] or resolveZoneCoord(zoneName)
                if not (coord and coord.GetVec3) then coord = nil end
                if coord then
                    NationsAtWar_ZoneHealthLastCoord[zoneName] = coord
                    local oldStartId = NationsAtWar_ZoneHealthLastDrawStartId[zoneName]
                    if oldStartId and type(oldStartId) == "number" and trigger and trigger.action and trigger.action.removeMark then
                        for id = oldStartId, oldStartId + lineCount - 1 do pcall(trigger.action.removeMark, id) end
                    end
                    NationsAtWar_NextLineId = NationsAtWar_NextLineId or 1000
                    local startId = NationsAtWar_NextLineId
                    NationsAtWar_NextLineId = startId + lineCount
                    local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
                    local zoneColors = (NationsAtWarConfig and NationsAtWarConfig.ZoneColors) or {}
                    local drawColor = (zoneColors[owner] and type(zoneColors[owner]) == "table" and #zoneColors[owner] >= 3) and zoneColors[owner] or { 1, 0, 0 }
                    local health = NationsAtWar_GetZoneHealth(zoneName)
                    local displayVal = (health > 99) and 99 or math.floor(health)
                    NationsAtWar_DrawTwoDigitsAtCoord(coord, displayVal, 100, { color = drawColor, coalition = -1, readonly = true }, startId)
                    NationsAtWar_ZoneHealthLastDrawStartId[zoneName] = startId
                    NationsAtWar_ZoneHealthLastDrawn[zoneName] = health
                end
            end
            NationsAtWar_ZoneHealthUpdateQueue = {}
        end, nil, timer.getTime() + BLANK_SEC)
    else
        NationsAtWar_ZoneHealthDrawScheduled = false
        NationsAtWar_ZoneHealthLastDrawStartId = NationsAtWar_ZoneHealthLastDrawStartId or {}
        NationsAtWar_ZoneHealthLastDrawn = NationsAtWar_ZoneHealthLastDrawn or {}
        NationsAtWar_ZoneHealthLastCoord = NationsAtWar_ZoneHealthLastCoord or {}
        for _, zoneName in ipairs(zonesToUpdate) do
            local coord = coordsByZone[zoneName]
            if coord and coord.GetVec3 then
                NationsAtWar_ZoneHealthLastCoord[zoneName] = coord
                local oldStartId = NationsAtWar_ZoneHealthLastDrawStartId[zoneName]
                if oldStartId and type(oldStartId) == "number" and trigger and trigger.action and trigger.action.removeMark then
                    for id = oldStartId, oldStartId + lineCount - 1 do pcall(trigger.action.removeMark, id) end
                end
                NationsAtWar_NextLineId = NationsAtWar_NextLineId or 1000
                local startId = NationsAtWar_NextLineId
                NationsAtWar_NextLineId = startId + lineCount
                local owner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName) or "red"
                local zoneColors = (NationsAtWarConfig and NationsAtWarConfig.ZoneColors) or {}
                local drawColor = (zoneColors[owner] and type(zoneColors[owner]) == "table" and #zoneColors[owner] >= 3) and zoneColors[owner] or { 1, 0, 0 }
                local health = NationsAtWar_GetZoneHealth(zoneName)
                local displayVal = (health > 99) and 99 or math.floor(health)
                NationsAtWar_DrawTwoDigitsAtCoord(coord, displayVal, 100, { color = drawColor, coalition = -1, readonly = true }, startId)
                NationsAtWar_ZoneHealthLastDrawStartId[zoneName] = startId
                NationsAtWar_ZoneHealthLastDrawn[zoneName] = health
            end
        end
        NationsAtWar_ZoneHealthUpdateQueue = {}
    end
end

--- Update health numbers for specific zones (queue and process).
function NationsAtWar_UpdateZoneHealthDisplay(zonesToUpdate)
    if not zonesToUpdate or type(zonesToUpdate) ~= "table" or #zonesToUpdate == 0 then return end
    NationsAtWar_ZoneHealthUpdateQueue = NationsAtWar_ZoneHealthUpdateQueue or {}
    for _, zoneName in ipairs(zonesToUpdate) do
        if zoneName and type(zoneName) == "string" and zoneName ~= "" then
            NationsAtWar_ZoneHealthUpdateQueue[zoneName] = true
        end
    end
    if NationsAtWar_ProcessZoneHealthUpdateQueue then NationsAtWar_ProcessZoneHealthUpdateQueue() end
end

--- Redraw all zone health numbers on F10. Queues all zones and processes.
function NationsAtWar_RedrawAllZoneHealthOnMap(opts)
    opts = opts or {}
    local zoneMenuZones = NationsAtWarConfig and NationsAtWarConfig.ZoneMenuZones
    if not zoneMenuZones or type(zoneMenuZones) ~= "table" then return end
    NationsAtWar_ZoneHealthUpdateQueue = NationsAtWar_ZoneHealthUpdateQueue or {}
    for _, zoneName in ipairs(zoneMenuZones) do
        if zoneName and type(zoneName) == "string" and zoneName ~= "" then
            NationsAtWar_ZoneHealthUpdateQueue[zoneName] = true
        end
    end
    if NationsAtWar_ProcessZoneHealthUpdateQueue then NationsAtWar_ProcessZoneHealthUpdateQueue() end
end
