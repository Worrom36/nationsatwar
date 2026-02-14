-- Nations at War - Mission logic (Zones.lua and SpawnHelper.lua loaded by Loader.lua).

-- Message queue (NationsAtWarConfig.Messages)
local cfg = NationsAtWarConfig and NationsAtWarConfig.Messages or {}
local maxLines = cfg.max_queue_lines or 20
local levelOrder = NationsAtWarConfig and NationsAtWarConfig._level_order or { debug = 1, info = 2, warning = 3, error = 4 }
local minLevel = levelOrder[cfg.min_level] or levelOrder.info
local messageQueue = {}

local function shouldSurface(level)
    return (levelOrder[level] or 0) >= minLevel
end

local function pushQueue(level, text)
    local t = (timer and timer.getTime) and timer.getTime() or nil
    table.insert(messageQueue, { level = level, text = text, time = t })
    while #messageQueue > maxLines do
        table.remove(messageQueue, 1)
    end
end

function NationsAtWar_Log(level, fmt, ...)
    local text = (fmt and #({...}) > 0) and string.format(fmt, ...) or tostring(fmt or "")
    pushQueue(level, text)
    if level == "debug" then env.info("[NaW] " .. text)
    elseif level == "info" then env.info("[NaW] " .. text)
    elseif level == "warning" then env.warning("[NaW] " .. text)
    else env.error("[NaW] " .. text)
    end
    if (cfg.show_in_game ~= false) and shouldSurface(level) then
        trigger.action.outText("[Nations at War] " .. text, cfg.out_text_duration or 8)
    end
end

-- F10 menu: Nations at War → Last messages
local function showLastMessages()
    local n = math.min(cfg.f10_show_last or 5, #messageQueue)
    if n == 0 then
        trigger.action.outText("[Nations at War] No messages yet.", 5)
        return
    end
    local lines = {}
    for i = #messageQueue - n + 1, #messageQueue do
        local e = messageQueue[i]
        table.insert(lines, string.format("[%s] %s", e.level, e.text))
    end
    trigger.action.outText("[Nations at War] Last " .. n .. ":\n" .. table.concat(lines, "\n"), 12)
end

-- F10 menu. EventHandlers.lua (loaded by Loader) guards against DCS passing a function instead of an event table.
if MENU_MISSION and MENU_MISSION_COMMAND then
    local root = MENU_MISSION:New("Nations at War")
    MENU_MISSION_COMMAND:New("Last messages", root, showLastMessages)
    local zoneMenuZones = NationsAtWarConfig and NationsAtWarConfig.ZoneMenuZones
    if zoneMenuZones and type(zoneMenuZones) == "table" and #zoneMenuZones > 0 then
        local zonesSub = MENU_MISSION:New("Zones", root)
        for _, zoneName in ipairs(zoneMenuZones) do
            if zoneName and type(zoneName) == "string" and zoneName ~= "" then
                local zoneSub = MENU_MISSION:New(zoneName, zonesSub)
                MENU_MISSION_COMMAND:New("Swap Zone", zoneSub, function()
                    if NationsAtWar_SwapZone then NationsAtWar_SwapZone(zoneName) end
                end)
                MENU_MISSION_COMMAND:New("Kill All", zoneSub, function()
                    if NationsAtWar_KillAllZone then NationsAtWar_KillAllZone(zoneName) end
                end)
                MENU_MISSION_COMMAND:New("Respawn All", zoneSub, function()
                    if NationsAtWar_RespawnAllZone then NationsAtWar_RespawnAllZone(zoneName) end
                end)
                MENU_MISSION_COMMAND:New("Spawn Counter", zoneSub, function()
                    if NationsAtWar_SpawnCounterZone then NationsAtWar_SpawnCounterZone(zoneName) end
                end)
                MENU_MISSION_COMMAND:New("Kill One", zoneSub, function()
                    if NationsAtWar_KillOneZoneUnit then NationsAtWar_KillOneZoneUnit(zoneName) end
                end)
                MENU_MISSION_COMMAND:New("Kill Two Fast", zoneSub, function()
                    if NationsAtWar_KillTwoZoneUnitsFast then NationsAtWar_KillTwoZoneUnitsFast(zoneName) end
                end)
                MENU_MISSION_COMMAND:New("Kill Half", zoneSub, function()
                    if NationsAtWar_KillHalfZoneUnits then NationsAtWar_KillHalfZoneUnits(zoneName) end
                end)
                MENU_MISSION_COMMAND:New("Destroy All Static", zoneSub, function()
                    if NationsAtWar_KillZoneStatics then NationsAtWar_KillZoneStatics(zoneName) end
                end)
                MENU_MISSION_COMMAND:New("Respawn All Static", zoneSub, function()
                    if NationsAtWar_KillZoneStatics then NationsAtWar_KillZoneStatics(zoneName) end
                    if NationsAtWar_SpawnZoneStatics then NationsAtWar_SpawnZoneStatics(zoneName) end
                end)
            end
        end
    end
end

NationsAtWar_Log("info", "Nations at War - Initializing")

NationsAtWar_InitCapturableZones()
if NationsAtWar_BuildZoneStaticDefinitions then NationsAtWar_BuildZoneStaticDefinitions() end
if NationsAtWar_InstallZoneMovementHandler then
    NationsAtWar_InstallZoneMovementHandler()
end
if NationsAtWar_StartPeriodicCaptureCheck then
    NationsAtWar_StartPeriodicCaptureCheck()
end
if NationsAtWar_StartZoneHealthUpdate then
    NationsAtWar_StartZoneHealthUpdate()
end

-- Initialize every zone in ZoneMenuZones: draw on F10, spawn defenders, register for capture/movement.
local function initOneZone(zoneName)
    if not zoneName or type(zoneName) ~= "string" or zoneName == "" then return end
    local coord, foundZoneName, zoneRadius = NationsAtWar_GetZoneCoord(zoneName)
    if not coord then
        NationsAtWar_Log("warning", "Zone [%s] not found (check mission trigger zone name)", zoneName)
        return
    end
    local vec3 = coord:GetVec3()
    NationsAtWar_Log("info", "Zone [%s] center: x=%.0f alt=%.0f z=%.0f radius=%s", foundZoneName or zoneName, vec3.x, vec3.y, vec3.z, zoneRadius and tostring(zoneRadius) or "n/a")
    local drawCoord, drawName, drawRadius = coord, foundZoneName or zoneName, zoneRadius
    local owner = NationsAtWar_GetZoneOwner(zoneName) or "red"
    local zoneColors = (NationsAtWarConfig and NationsAtWarConfig.ZoneColors) or {}
    local drawColor = (zoneColors[owner] and type(zoneColors[owner]) == "table" and #zoneColors[owner] >= 3)
        and zoneColors[owner]
        or { 1, 0, 0 }
    local initialHealth = (NationsAtWarConfig and type(NationsAtWarConfig.ZoneInitialHealth) == "number") and NationsAtWarConfig.ZoneInitialHealth or 75
    if NationsAtWar_SetZoneHealth then NationsAtWar_SetZoneHealth(drawName, initialHealth) end
        if timer and timer.scheduleFunction then
            timer.scheduleFunction(function()
                if NationsAtWar_DrawZoneOnMapFromCoord(drawCoord, drawName, drawRadius, { color = drawColor, fillAlpha = 0.2, coalition = -1, readonly = true }) then
                    NationsAtWar_ZoneGeometry = NationsAtWar_ZoneGeometry or {}
                    NationsAtWar_ZoneGeometry[drawName] = { centerCoord = drawCoord, radius = drawRadius }
                    NationsAtWar_Log("info", "Zone [%s] drawn on F10 map (%s)", drawName, owner)
                else
                    NationsAtWar_Log("warning", "Zone [%s] draw failed (no coord)", drawName)
                end
                -- Health number is drawn by the queue (1 Hz RunZoneHealthUpdate will queue and ProcessZoneHealthUpdateQueue will draw).
            end, nil, timer.getTime() + 2)
        else
            if NationsAtWar_DrawZoneOnMapFromCoord(drawCoord, drawName, drawRadius, { color = drawColor, fillAlpha = 0.2, coalition = -1, readonly = true }) then
                NationsAtWar_ZoneGeometry = NationsAtWar_ZoneGeometry or {}
                NationsAtWar_ZoneGeometry[drawName] = { centerCoord = drawCoord, radius = drawRadius }
            end
            -- Health number is drawn by the queue.
        end
    local zoneUnits = NationsAtWarConfig and NationsAtWarConfig.ZoneUnits and NationsAtWarConfig.ZoneUnits[zoneName]
    local ownerUnits = zoneUnits and zoneUnits[owner]
    if ownerUnits and type(ownerUnits) == "table" and #ownerUnits > 0 then
        local radius = (type(zoneRadius) == "number" and zoneRadius > 0) and zoneRadius or 1000
        local spawnCoords = NationsAtWar_GetZoneSpawnPositions(coord, radius)
        NationsAtWar_SpawnGroupsAtCoordsDelayed(ownerUnits, spawnCoords, 3, function(spawned, total, groups)
            if total > 0 then
                local r = (NationsAtWarConfig and type(NationsAtWarConfig.DefenderRingSlots) == "number" and NationsAtWarConfig.DefenderRingSlots > 0) and NationsAtWarConfig.DefenderRingSlots or 12
                local s = (NationsAtWarConfig and type(NationsAtWarConfig.DefenderSquareSlots) == "number" and NationsAtWarConfig.DefenderSquareSlots > 0) and NationsAtWarConfig.DefenderSquareSlots or 4
                NationsAtWar_Log("info", "Zone [%s] (%s): spawned %d/%d unit groups (%d ring + %d square)", drawName, owner, spawned, total, r, s)
                if spawned < total then
                    NationsAtWar_Log("warning", "Zone [%s]: %d groups failed to spawn (check late-activated group names in ME)", drawName, total - spawned)
                end
                if groups and #groups > 0 and NationsAtWar_RegisterZoneUnits then
                    NationsAtWar_RegisterZoneUnits(zoneName, coord, radius, groups)
                    if NationsAtWar_ZoneHasStatics and NationsAtWar_ZoneHasStatics(zoneName) and NationsAtWar_SpawnZoneStatics then
                        NationsAtWar_SpawnZoneStatics(zoneName)
                    end
                    local A = NationsAtWar_ComputeZoneHealthA and NationsAtWar_ComputeZoneHealthA(zoneName) or 0
                    local B = (NationsAtWar_HasAnyOutsideFriendlyInZone and NationsAtWar_HasAnyOutsideFriendlyInZone(zoneName)) and 20 or 0
                    local C = (NationsAtWar_ZoneCValue and NationsAtWar_ZoneCValue[zoneName]) or 30
                    if C < 0 then C = 0 elseif C > 30 then C = 30 end
                    local total = math.min(100, math.max(0, A + B + C))
                    if NationsAtWar_SetZoneHealth then NationsAtWar_SetZoneHealth(zoneName, total) end
                    -- Don't redraw on spawn so the initial number (from Init t+2) stays visible and doesn't disappear.
                    if NationsAtWar_Log then
                        NationsAtWar_Log("info", "Zone [%s]: defending units spawned, health %d (A=%d B=%d C=%d)", drawName, total, A, B, C)
                    end
                end
            end
        end)
    else
        NationsAtWar_Log("warning", "Zone [%s]: no ZoneUnits[%s][%s] or empty list; add unit template names in Config.lua", zoneName, zoneName, owner)
        if NationsAtWar_ZoneHasStatics and NationsAtWar_ZoneHasStatics(zoneName) and NationsAtWar_SpawnZoneStatics then
            NationsAtWar_SpawnZoneStatics(zoneName)
        end
    end
end

local zoneMenuZones = NationsAtWarConfig and NationsAtWarConfig.ZoneMenuZones
if zoneMenuZones and type(zoneMenuZones) == "table" then
    for _, zoneName in ipairs(zoneMenuZones) do
        initOneZone(zoneName)
    end
end

NationsAtWar_Log("info", "Initialization complete")

-- All zones: periodic replenishment of lost defender units. Interval by type (factory / airfield / default).
local function zoneInList(zoneName, list)
    if not zoneName or not list or type(list) ~= "table" then return false end
    for _, z in ipairs(list) do
        if z == zoneName then return true end
    end
    return false
end
local function getReplenishIntervalSec(zoneName)
    local cfg = NationsAtWarConfig
    if not cfg then return 300 end
    if zoneInList(zoneName, cfg.FactoryZones) then
        return (type(cfg.FactoryReplenishIntervalSec) == "number" and cfg.FactoryReplenishIntervalSec > 0) and cfg.FactoryReplenishIntervalSec or 120
    end
    if zoneInList(zoneName, cfg.AirfieldZones) then
        return (type(cfg.AirfieldReplenishIntervalSec) == "number" and cfg.AirfieldReplenishIntervalSec > 0) and cfg.AirfieldReplenishIntervalSec or 180
    end
    return (type(cfg.DefaultReplenishIntervalSec) == "number" and cfg.DefaultReplenishIntervalSec > 0) and cfg.DefaultReplenishIntervalSec or 300
end
local zoneMenuZonesReplenish = NationsAtWarConfig and NationsAtWarConfig.ZoneMenuZones
-- Replenishment timers always run; ReplenishZone no-ops when EnableZoneReplenishment is not true.
if zoneMenuZonesReplenish and type(zoneMenuZonesReplenish) == "table" and #zoneMenuZonesReplenish > 0 and timer and timer.scheduleFunction and timer.getTime then
    local started = 0
    for _, zoneName in ipairs(zoneMenuZonesReplenish) do
        if zoneName and type(zoneName) == "string" and zoneName ~= "" then
            local intervalSec = getReplenishIntervalSec(zoneName)
            if intervalSec > 0 then
                local function scheduleReplenish()
                    if NationsAtWar_ReplenishZone then NationsAtWar_ReplenishZone(zoneName) end
                    if timer and timer.scheduleFunction and timer.getTime then
                        timer.scheduleFunction(scheduleReplenish, nil, timer.getTime() + intervalSec)
                    end
                end
                timer.scheduleFunction(scheduleReplenish, nil, timer.getTime() + intervalSec)
                started = started + 1
            end
        end
    end
    if started > 0 and NationsAtWar_Log then
        NationsAtWar_Log("info", "Replenish started for %d zone(s) (factory / airfield / default intervals)", started)
    end
end

-- Factory tank production: shared timer (every 60 s), cap from Config, no map display.
if NationsAtWar_StartFactoryProductionTimer then
    NationsAtWar_StartFactoryProductionTimer()
end

-- Delayed ready message (init runs during load)
if timer and timer.scheduleFunction then
    timer.scheduleFunction(function()
        trigger.action.outText("[Nations at War] Ready. F10 → Nations at War → Last messages", 10)
    end, nil, 8)
end
