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

if MENU_MISSION and MENU_MISSION_COMMAND then
    local root = MENU_MISSION:New("Nations at War")
    MENU_MISSION_COMMAND:New("Last messages", root, showLastMessages)
end

NationsAtWar_Log("info", "Nations at War - Initializing")

-- Anapa zone: draw on F10, spawn 1 infantry from late-activated template NaW_Test_1INF
local zoneName = "Anapa_AF_BL"
local coord, foundZoneName, zoneRadius = NationsAtWar_GetZoneCoord(zoneName)
if coord then
    local vec3 = coord:GetVec3()
    NationsAtWar_Log("info", "Zone [%s] center: x=%.0f alt=%.0f z=%.0f radius=%s", foundZoneName or zoneName, vec3.x, vec3.y, vec3.z, zoneRadius and tostring(zoneRadius) or "n/a")
    local drawCoord, drawName, drawRadius = coord, foundZoneName or zoneName, zoneRadius
    if timer and timer.scheduleFunction then
        timer.scheduleFunction(function()
            if NationsAtWar_DrawZoneOnMapFromCoord(drawCoord, drawName, drawRadius, { color = {0, 1, 0}, fillAlpha = 0.2, coalition = -1, readonly = true }) then
                NationsAtWar_Log("info", "Zone [%s] drawn on F10 map", drawName)
            else
                NationsAtWar_Log("warning", "Zone [%s] draw failed (no coord)", drawName)
            end
        end, nil, timer.getTime() + 2)
    else
        NationsAtWar_DrawZoneOnMapFromCoord(drawCoord, drawName, drawRadius, { color = {0, 1, 0}, fillAlpha = 0.2, coalition = -1, readonly = true })
    end
    local templateName = "NaW_Test_1INF"
    NationsAtWar_EnsureSpawnTemplate(templateName)
    local ok, spawnInf = pcall(SPAWN.New, SPAWN, templateName)
    if ok and spawnInf then
        NationsAtWar_SpawnAtCoordDelayed(spawnInf, coord, 3, function(ok2, group)
            if ok2 and group then
                NationsAtWar_Log("info", "NaW_Test_1INF spawned at %s", foundZoneName or zoneName)
            else
                NationsAtWar_Log("warning", "NaW_Test_1INF spawn failed: %s", ok2 and "no group" or tostring(group))
            end
        end)
    else
        NationsAtWar_Log("warning", "Template %s not found. In Mission Editor: add a late-activated ground group named exactly '%s' (e.g. 1 infantry).", templateName, templateName)
    end
else
    NationsAtWar_Log("warning", "Zone %s not found", zoneName)
end

NationsAtWar_Log("info", "Initialization complete")

-- Delayed ready message (init runs during load)
if timer and timer.scheduleFunction then
    timer.scheduleFunction(function()
        trigger.action.outText("[Nations at War] Ready. F10 → Nations at War → Last messages", 10)
    end, nil, 8)
end
