-- Nations at War - Zone unit movement: redistribute on player kill, move orders.
-- EventHandlers and unit controls: see also D:\CardinalCollective\perforce\dcs\Scripts for shared patterns.

NationsAtWar_ZoneData = NationsAtWar_ZoneData or {}
NationsAtWar_GroupToZone = NationsAtWar_GroupToZone or {}
-- C component of zone health (0-30): drained 1/sec when enemy alone; capture at 0.
NationsAtWar_ZoneCValue = NationsAtWar_ZoneCValue or {}
-- Total defender unit count at registration (A = (living count / this) * 50).
NationsAtWar_ZoneDefenderUnitCount = NationsAtWar_ZoneDefenderUnitCount or {}

local RING_SLOTS = 12
local ROTATION_STEP_RAD = (2 * math.pi) / RING_SLOTS
local MOVE_ZONE_RADIUS = 25
local _moveZoneCounter = 0

local function shuffleArray(t)
    local n = #t
    for i = n, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function randomPermutationOfN(n, maxVal)
    local indices = {}
    for i = 1, maxVal do table.insert(indices, i) end
    shuffleArray(indices)
    local out = {}
    for i = 1, math.min(n, maxVal) do
        table.insert(out, indices[i])
    end
    return out
end

local function isGroupAlive(group)
    if not group then return false end
    if group.IsAlive and group:IsAlive() then return true end
    if group.GetSize and group:GetSize() and group:GetSize() > 0 then return true end
    return false
end

function NationsAtWar_IsGroupAlive(group)
    return isGroupAlive(group)
end

local GROUND_SPEED_KMH = 20
-- Delay 0 for redistribution so task is set immediately; delayed SetTask can run after a group is dead and log "is not alive anymore".
local ROUTE_DELAY_SEC = 0

local function giveGroupMoveOrder(group, coord)
    if not group or not coord then return false end
    if not isGroupAlive(group) then return false end
    -- Use MOOSE Route: From + To waypoints (DCS expects route to start at current position).
    if group.Route and group.GetCoordinate and coord.WaypointGround then
        return pcall(function()
            local fromCoord = group:GetCoordinate()
            if not fromCoord then return end
            local fromWP = fromCoord:WaypointGround(GROUND_SPEED_KMH, "Off Road")
            local toWP = coord:WaypointGround(GROUND_SPEED_KMH, "Off Road")
            if not fromWP or not toWP then return end
            group:Route({ fromWP, toWP }, ROUTE_DELAY_SEC)
        end)
    end
    -- Fallback: raw DCS setTask with From + To points (same waypoint format as MOOSE WaypointGround).
    local groupName = (group.GetName and group:GetName()) or (group.getName and group:getName())
    if not groupName then return false end
    local v = (coord.GetVec3 and coord:GetVec3()) or (coord.GetVec2 and coord:GetVec2())
    if not v then return false end
    local toX, toY = v.x, v.z or v.y
    if not toX or not toY then return false end
    local speedMs = GROUND_SPEED_KMH / 3.6
    return pcall(function()
        local dcsGroup = Group.getByName(groupName)
        if not dcsGroup or not dcsGroup.getController then return end
        local ctrl = dcsGroup:getController()
        if not ctrl or not ctrl.setTask then return end
        local fromX, fromY
        local u = dcsGroup:getUnit(1)
        if u and u.getPoint then
            local p = u:getPoint()
            if p then fromX, fromY = p.x, p.z end
        end
        fromX = fromX or toX
        fromY = fromY or toY
        local function mkWP(x, y)
            return {
                x = x, y = y,
                alt = 0, alt_type = 0,
                type = "Turning Point", action = "Off Road", formation_template = "",
                ETA = 0, ETA_locked = false,
                speed = speedMs, speed_locked = true,
                task = { id = "ComboTask", params = { tasks = {} } },
            }
        end
        ctrl:setTask({ id = "Mission", params = { airborne = false, route = { points = { mkWP(fromX, fromY), mkWP(toX, toY) } } } })
    end)
end

--- Count living units in zone's defender groups. Excludes units with HP <= 0 (dead or dying).
local function countLivingDefenderUnits(zoneName)
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    if not data then return 0 end
    local ringGroups = data.ringGroups or {}
    local squareGroups = data.squareGroups or {}
    local n = 0
    local function addGroup(group)
        if not group then return end
        local groupName = (group.GetName and group:GetName()) or (group.getName and group:getName())
        if not groupName then return end
        local ok, count = pcall(function()
            local dcsGroup = Group.getByName(groupName)
            if not dcsGroup or not dcsGroup.getSize or not dcsGroup.getUnit then return 0 end
            local sz = dcsGroup:getSize()
            if type(sz) ~= "number" or sz <= 0 then return 0 end
            local alive = 0
            for i = 1, sz do
                local u = dcsGroup:getUnit(i)
                if u and u.getLife then
                    local life = u:getLife()
                    if type(life) == "number" and life > 0 then alive = alive + 1 end
                end
            end
            return alive
        end)
        if ok and type(count) == "number" then n = n + count end
    end
    for slot = 1, RING_SLOTS do addGroup(ringGroups[slot]) end
    for slot = 1, 4 do addGroup(squareGroups[slot]) end
    return n
end

function NationsAtWar_RegisterZoneUnits(zoneName, centerCoord, radius, spawnedGroups)
    if not zoneName or not centerCoord or not radius or not spawnedGroups or type(spawnedGroups) ~= "table" then
        return
    end
    local r = (type(radius) == "number" and radius > 0) and radius or 1000
    -- Store by slot index so RedistributeZone assigns move orders by slot (fixes Respawn wrong positions).
    local ringGroups = {}   -- ringGroups[slot] = group for slot 1..12
    local squareGroups = {} -- squareGroups[slot] = group for slot 1..4 (spawn slots 13..16)
    for _, entry in ipairs(spawnedGroups) do
        local group = entry and entry.group
        local idx = entry and entry.coordIndex
        if group and idx then
            local name = (group.GetName and group:GetName()) and group:GetName() or nil
            if name then
                NationsAtWar_GroupToZone[name] = zoneName
                if idx >= 1 and idx <= RING_SLOTS then
                    ringGroups[idx] = group
                elseif idx >= 13 and idx <= 16 then
                    squareGroups[idx - 12] = group
                end
            end
        end
    end
    local direction = (math.random(1, 2) == 1) and 1 or -1
    NationsAtWar_ZoneData[zoneName] = {
        centerCoord = centerCoord,
        radius = r,
        ringGroups = ringGroups,
        squareGroups = squareGroups,
        rotationDirection = direction,
        rotationOffsetRad = 0,
    }
    -- Persist geometry for Respawn All (GetZoneCoord can return different/wrong radius from menu callback).
    NationsAtWar_ZoneGeometry = NationsAtWar_ZoneGeometry or {}
    NationsAtWar_ZoneGeometry[zoneName] = { centerCoord = centerCoord, radius = r }
    NationsAtWar_ZoneDefenderUnitCount[zoneName] = countLivingDefenderUnits(zoneName)
    NationsAtWar_ZoneCValue[zoneName] = 30
end

--- Return set of defender group names for zone (for B: outside-friendly check). Returns table name -> true.
function NationsAtWar_GetDefenderGroupNames(zoneName)
    local out = {}
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    if not data then return out end
    local ringGroups = data.ringGroups or {}
    local squareGroups = data.squareGroups or {}
    for slot = 1, RING_SLOTS do
        local g = ringGroups[slot]
        if g then
            local name = (g.GetName and g:GetName()) and g:GetName() or nil
            if name then out[name] = true end
        end
    end
    for slot = 1, 4 do
        local g = squareGroups[slot]
        if g then
            local name = (g.GetName and g:GetName()) and g:GetName() or nil
            if name then out[name] = true end
        end
    end
    return out
end

--- Health component A (0-50): based on defender unit count. A = (living count / total at registration) * 50.
function NationsAtWar_ComputeZoneHealthA(zoneName)
    local living = countLivingDefenderUnits(zoneName)
    local total = NationsAtWar_ZoneDefenderUnitCount and NationsAtWar_ZoneDefenderUnitCount[zoneName]
    if not total or total <= 0 then
        NationsAtWar_ZoneDefenderUnitCount = NationsAtWar_ZoneDefenderUnitCount or {}
        NationsAtWar_ZoneDefenderUnitCount[zoneName] = countLivingDefenderUnits(zoneName)
        total = NationsAtWar_ZoneDefenderUnitCount[zoneName]
    end
    if not total or total <= 0 then return 0 end
    return math.floor((living / total) * 50 + 0.5)
end

--- Return C value (0-30) for zone; init to 30 if nil.
local function getZoneCValue(zoneName)
    if not NationsAtWar_ZoneCValue[zoneName] then
        NationsAtWar_ZoneCValue[zoneName] = 30
    end
    local v = NationsAtWar_ZoneCValue[zoneName]
    if v < 0 then return 0 elseif v > 30 then return 30 end
    return v
end

--- Set C value (e.g. after capture). Clamped 0-30.
function NationsAtWar_SetZoneCValue(zoneName, value)
    if not zoneName then return end
    local n = tonumber(value)
    if n then NationsAtWar_ZoneCValue[zoneName] = (n < 0 and 0) or (n > 30 and 30) or n end
end

--- Return coord for slot 1..16 (1–12 ring, 13–16 square). Used by replenish to spawn at a specific slot.
function NationsAtWar_GetZoneSlotCoord(zoneName, slot)
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    if not data or not data.centerCoord or not data.radius then return nil end
    local centerCoord, radius = data.centerCoord, data.radius
    local offset = data.rotationOffsetRad or 0
    if slot >= 1 and slot <= RING_SLOTS then
        local ringCoords = NationsAtWar_GetZoneRingPositions(centerCoord, radius, RING_SLOTS, offset)
        return ringCoords and ringCoords[slot]
    elseif slot >= 13 and slot <= 16 then
        local squareCoords = NationsAtWar_GetZoneSquarePositions(centerCoord, radius)
        local idx = slot - 12
        return squareCoords and squareCoords[idx]
    end
    return nil
end

--- Register one replenished group into an existing zone at the given slot (1–16). Updates ZoneData and GroupToZone.
function NationsAtWar_RegisterZoneUnitReplenish(zoneName, slot, group)
    if not zoneName or not group then return end
    local name = (group.GetName and group:GetName()) and group:GetName() or nil
    if not name then return end
    NationsAtWar_GroupToZone[name] = zoneName
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    if not data then return end
    if slot >= 1 and slot <= RING_SLOTS then
        data.ringGroups = data.ringGroups or {}
        data.ringGroups[slot] = group
    elseif slot >= 13 and slot <= 16 then
        data.squareGroups = data.squareGroups or {}
        data.squareGroups[slot - 12] = group
    end
    NationsAtWar_ZoneDefenderUnitCount[zoneName] = countLivingDefenderUnits(zoneName)
end

function NationsAtWar_RedistributeZone(zoneName)
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    if not data or not data.centerCoord or not data.radius then return end
    local centerCoord = data.centerCoord
    local radius = data.radius
    local ringGroups = data.ringGroups or {}
    local squareGroups = data.squareGroups or {}
    local dir = data.rotationDirection or 1
    local offset = data.rotationOffsetRad or 0
    local nRingAlive, nSquareAlive = 0, 0
    -- Ring: assign by slot so group at slot i goes to ringCoords[destIdx(i)].
    local ringCoords = NationsAtWar_GetZoneRingPositions(centerCoord, radius, RING_SLOTS, offset)
    for slot = 1, RING_SLOTS do
        local group = ringGroups[slot]
        if group and isGroupAlive(group) then
            nRingAlive = nRingAlive + 1
            local destIdx = ((slot - 1 + dir + RING_SLOTS) % RING_SLOTS) + 1
            if ringCoords[destIdx] then
                giveGroupMoveOrder(group, ringCoords[destIdx])
            end
        end
    end
    data.rotationOffsetRad = offset + dir * ROTATION_STEP_RAD
    -- Square: assign by slot; permute which corner each slot gets.
    local squareCoords = NationsAtWar_GetZoneSquarePositions(centerCoord, radius)
    local perm = randomPermutationOfN(4, 4)
    for slot = 1, 4 do
        local group = squareGroups[slot]
        if group and isGroupAlive(group) then
            nSquareAlive = nSquareAlive + 1
            local cornerIdx = perm[slot]
            if cornerIdx and squareCoords[cornerIdx] then
                giveGroupMoveOrder(group, squareCoords[cornerIdx])
            end
        end
    end
    if NationsAtWar_Log and (nRingAlive > 0 or nSquareAlive > 0) then
        NationsAtWar_Log("info", "Zone [%s]: redistributed %d ring, %d square (player kill)", zoneName, nRingAlive, nSquareAlive)
    end
end

local function isKillerPlayer(initiator)
    if not initiator then return false end
    local name
    local ok = pcall(function()
        if initiator.getPlayerName and type(initiator.getPlayerName) == "function" then
            name = initiator:getPlayerName()
        elseif initiator.GetPlayerName and type(initiator.GetPlayerName) == "function" then
            name = initiator:GetPlayerName()
        end
    end)
    return ok and name and type(name) == "string" and name ~= ""
end

local function onKill(event)
    if not event or event.id ~= 28 then return end
    local target = event.target
    local initiator = event.initiator
    if not target then return end
    if not isKillerPlayer(initiator) then return end
    local group
    pcall(function()
        group = target.getGroup and target:getGroup() or (target.GetGroup and target:GetGroup())
    end)
    if not group then return end
    local groupName
    pcall(function()
        groupName = group.getName and group:getName() or (group.GetName and group:GetName())
    end)
    if not groupName then return end
    local zoneName = NationsAtWar_GroupToZone and NationsAtWar_GroupToZone[groupName]
    if not zoneName then return end
    NationsAtWar_RedistributeZone(zoneName)
    if NationsAtWar_CheckAndCaptureZone then
        NationsAtWar_CheckAndCaptureZone(zoneName)
    end
    -- Same trigger: set health when we redistribute (count uses getLife() > 0 so dead unit is excluded).
    if NationsAtWar_UpdateZoneHealthAndDisplay then
        NationsAtWar_UpdateZoneHealthAndDisplay(zoneName)
    end
end

local function installKillHandler()
    if world and world.addEventHandler then
        local handler = {}
        function handler:onEvent(event)
            if type(event) == "table" and event.id then
                onKill(event)
            end
        end
        world.addEventHandler(handler)
        if NationsAtWar_Log then
            NationsAtWar_Log("info", "Zone movement: kill handler installed (redistribute on player kill)")
        end
    end
end

function NationsAtWar_InstallZoneMovementHandler()
    installKillHandler()
end

--- Periodic capture check: when last defender was killed but enemy enters zone later, we still capture.
--- Runs every NationsAtWarConfig.CaptureCheckIntervalSec; started from Init.lua.
function NationsAtWar_RunPeriodicCaptureCheck()
    if not NationsAtWar_ZoneData or type(NationsAtWar_ZoneData) ~= "table" then return end
    if not NationsAtWar_CheckAndCaptureZone then return end
    for zoneName, _ in pairs(NationsAtWar_ZoneData) do
        if zoneName and type(zoneName) == "string" then
            NationsAtWar_CheckAndCaptureZone(zoneName)
        end
    end
    local interval = (NationsAtWarConfig and type(NationsAtWarConfig.CaptureCheckIntervalSec) == "number" and NationsAtWarConfig.CaptureCheckIntervalSec > 0)
        and NationsAtWarConfig.CaptureCheckIntervalSec or 5
    if timer and timer.scheduleFunction and timer.getTime then
        timer.scheduleFunction(NationsAtWar_RunPeriodicCaptureCheck, nil, timer.getTime() + interval)
    end
end

--- Start the periodic capture check (first run after one interval). Call from Init.lua.
function NationsAtWar_StartPeriodicCaptureCheck()
    local interval = (NationsAtWarConfig and type(NationsAtWarConfig.CaptureCheckIntervalSec) == "number" and NationsAtWarConfig.CaptureCheckIntervalSec > 0)
        and NationsAtWarConfig.CaptureCheckIntervalSec or 5
    if timer and timer.scheduleFunction and timer.getTime then
        timer.scheduleFunction(NationsAtWar_RunPeriodicCaptureCheck, nil, timer.getTime() + interval)
        if NationsAtWar_Log then
            NationsAtWar_Log("info", "Periodic capture check started (interval %s s)", tostring(interval))
        end
    end
end

--- Update health for one zone (A+B+C), store. F10 display updates via normal 1 Hz queue (RunZoneHealthUpdate). Returns new total.
function NationsAtWar_UpdateZoneHealthAndDisplay(zoneName, opts)
    if not zoneName or type(zoneName) ~= "string" or zoneName == "" then return nil end
    opts = opts or {}
    local data = NationsAtWar_ZoneData and NationsAtWar_ZoneData[zoneName]
    local A = NationsAtWar_ComputeZoneHealthA and NationsAtWar_ComputeZoneHealthA(zoneName) or 0
    local B = (NationsAtWar_HasAnyOutsideFriendlyInZone and NationsAtWar_HasAnyOutsideFriendlyInZone(zoneName)) and 20 or 0
    local C = (NationsAtWar_ZoneCValue and NationsAtWar_ZoneCValue[zoneName])
    if type(C) ~= "number" or C < 0 then C = 30 end
    if C > 30 then C = 30 end
    if data and C == 0 then
        C = 30
        NationsAtWar_ZoneCValue = NationsAtWar_ZoneCValue or {}
        NationsAtWar_ZoneCValue[zoneName] = 30
    end
    -- Treat zone as having owner if defenders are registered (don't drain C when GetSize() is 0 right after spawn).
    local hasDefenderGroups = data and (next(data.ringGroups or {}) or next(data.squareGroups or {}))
    local hasOwner = (data and countLivingDefenderUnits(zoneName) > 0)
        or hasDefenderGroups
        or (NationsAtWar_HasOwnerUnitsInZone and NationsAtWar_HasOwnerUnitsInZone(zoneName))
    local hasOther = NationsAtWar_HasOtherTeamUnitsInZone and NationsAtWar_HasOtherTeamUnitsInZone(zoneName)
    if data and hasOther and not hasOwner then
        C = math.max(0, C - 1)
        NationsAtWar_ZoneCValue[zoneName] = C
        if C <= 0 and NationsAtWar_DoZoneCapture then
            NationsAtWar_DoZoneCapture(zoneName)
            NationsAtWar_SetZoneCValue(zoneName, 30)
        end
    end
    local total = math.min(100, math.max(0, A + B + C))
    if NationsAtWar_SetZoneHealth then NationsAtWar_SetZoneHealth(zoneName, total) end
    return total
end

--- Health update: A (0-50 defenders) + B (0 or 20 outside friendlies) + C (0-30, -1/sec when enemy alone). Redraw F10 only if any zone health changed.
function NationsAtWar_RunZoneHealthUpdate()
    local zoneMenuZones = NationsAtWarConfig and NationsAtWarConfig.ZoneMenuZones
    if not zoneMenuZones or type(zoneMenuZones) ~= "table" then
        if timer and timer.scheduleFunction and timer.getTime then
            timer.scheduleFunction(NationsAtWar_RunZoneHealthUpdate, nil, timer.getTime() + 1)
        end
        return
    end
    for _, zoneName in ipairs(zoneMenuZones) do
        if zoneName and type(zoneName) == "string" and zoneName ~= "" then
            NationsAtWar_UpdateZoneHealthAndDisplay(zoneName)
        end
    end
    -- Queue zones that changed for update (processed together in next batch)
    local lastDrawn = NationsAtWar_ZoneHealthLastDrawn or {}
    for _, zoneName in ipairs(zoneMenuZones) do
        if zoneName and type(zoneName) == "string" and zoneName ~= "" then
            local current = NationsAtWar_ZoneHealth and NationsAtWar_ZoneHealth[zoneName]
            local drawn = lastDrawn[zoneName]
            if current ~= drawn then
                -- Tag this zone for update in the queue
                NationsAtWar_ZoneHealthUpdateQueue = NationsAtWar_ZoneHealthUpdateQueue or {}
                NationsAtWar_ZoneHealthUpdateQueue[zoneName] = true
            end
        end
    end
    -- Process queued updates (draw all queued zones together)
    if NationsAtWar_ProcessZoneHealthUpdateQueue then
        NationsAtWar_ProcessZoneHealthUpdateQueue()
    end
    
    if timer and timer.scheduleFunction and timer.getTime then
        timer.scheduleFunction(NationsAtWar_RunZoneHealthUpdate, nil, timer.getTime() + 1)
    end
end

--- Start 1 Hz zone health update (A+B+C, F10 display, C drain when enemy alone). Call from Init.lua after ZoneCommands loaded.
function NationsAtWar_StartZoneHealthUpdate()
    local zoneMenuZones = NationsAtWarConfig and NationsAtWarConfig.ZoneMenuZones
    if zoneMenuZones and type(zoneMenuZones) == "table" then
        for _, zoneName in ipairs(zoneMenuZones) do
            if zoneName and type(zoneName) == "string" and zoneName ~= "" then
                NationsAtWar_ZoneCValue[zoneName] = 30
            end
        end
    end
    if timer and timer.scheduleFunction and timer.getTime then
        timer.scheduleFunction(NationsAtWar_RunZoneHealthUpdate, nil, timer.getTime() + 1)
        if NationsAtWar_Log then
            NationsAtWar_Log("info", "Zone health update started (1 Hz)")
        end
    end
end
