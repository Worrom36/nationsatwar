-- Nations at War - Factory tank production (shared timer, no map display).
-- Factories accumulate a counter at TanksPerMinute per minute, capped at FactoryTankCap. Counter resets on capture.

NationsAtWar_FactoryTankCount = NationsAtWar_FactoryTankCount or {}

--- Get current tank count for a factory zone (internal only; not shown on map).
function NationsAtWar_GetFactoryTankCount(zoneName)
    if not zoneName then return 0 end
    local n = NationsAtWar_FactoryTankCount[zoneName]
    return (type(n) == "number") and n or 0
end

--- Reset factory tank count to 0 (e.g. on capture). Call from NationsAtWar_SetZoneOwner when zone is a factory.
function NationsAtWar_ResetFactoryTankCount(zoneName)
    if zoneName then
        NationsAtWar_FactoryTankCount[zoneName] = 0
    end
end

--- Add n to factory tank count (e.g. when attacking reinforcements are removed after zone capture). Capped at FactoryTankCap.
function NationsAtWar_AddFactoryTankCount(zoneName, n)
    if not zoneName or not n or n <= 0 then return end
    local cfg = NationsAtWarConfig
    local cap = (cfg and type(cfg.FactoryTankCap) == "number" and cfg.FactoryTankCap > 0) and cfg.FactoryTankCap or 12
    local current = NationsAtWar_GetFactoryTankCount(zoneName)
    NationsAtWar_FactoryTankCount[zoneName] = math.min(cap, current + n)
end

--- One tick of the shared production timer: add TanksPerMinute to each factory, cap at FactoryTankCap.
local function runFactoryProductionTick()
    local cfg = NationsAtWarConfig
    if not cfg then return end
    local factoryZones = cfg.FactoryZones
    if not factoryZones or type(factoryZones) ~= "table" or #factoryZones == 0 then return end
    local rate = (type(cfg.TanksPerMinute) == "number" and cfg.TanksPerMinute >= 0) and cfg.TanksPerMinute or 2
    local cap = (type(cfg.FactoryTankCap) == "number" and cfg.FactoryTankCap > 0) and cfg.FactoryTankCap or 12
    for _, zoneName in ipairs(factoryZones) do
        if zoneName and type(zoneName) == "string" and zoneName ~= "" then
            local current = NationsAtWar_GetFactoryTankCount(zoneName)
            local nextCount = math.min(cap, current + rate)
            NationsAtWar_FactoryTankCount[zoneName] = nextCount
        end
    end
end

--- Start the shared factory production timer (runs every 60 seconds). Call from Init.lua.
function NationsAtWar_StartFactoryProductionTimer()
    local cfg = NationsAtWarConfig
    if not cfg then return end
    local factoryZones = cfg.FactoryZones
    if not factoryZones or type(factoryZones) ~= "table" or #factoryZones == 0 then return end
    if not (timer and timer.scheduleFunction and timer.getTime) then return end
    local intervalSec = 60
    local function scheduleNext()
        runFactoryProductionTick()
        timer.scheduleFunction(scheduleNext, nil, timer.getTime() + intervalSec)
    end
    -- Initialize counts to cap (max manufactured tanks) for each factory zone
    local cap = (type(cfg.FactoryTankCap) == "number" and cfg.FactoryTankCap > 0) and cfg.FactoryTankCap or 12
    for _, zoneName in ipairs(factoryZones) do
        if zoneName and type(zoneName) == "string" and zoneName ~= "" then
            if NationsAtWar_FactoryTankCount[zoneName] == nil then
                NationsAtWar_FactoryTankCount[zoneName] = cap
            end
        end
    end
    timer.scheduleFunction(scheduleNext, nil, timer.getTime() + intervalSec)
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "Factory production timer started (every %d s, cap %s)", intervalSec, tostring(cfg.FactoryTankCap or 12))
    end
end
