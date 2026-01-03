-- ============================================
-- Territorial Conquest Utility Functions
-- ============================================

TerritorialConquestUtils = {}

-- ============================================
-- Debug Logging
-- ============================================
function TerritorialConquestUtils:DebugLog(message, verbose)
    if TerritorialConquestConfig and TerritorialConquestConfig:IsDebugEnabled() then
        if not verbose or TerritorialConquestConfig.Debug.verbose then
            env.info("[TC] " .. tostring(message))
        end
    end
end

function TerritorialConquestUtils:ErrorLog(message)
    env.error("[TC ERROR] " .. tostring(message))
end

function TerritorialConquestUtils:WarningLog(message)
    env.warning("[TC WARNING] " .. tostring(message))
end

-- ============================================
-- Coordinate Utilities
-- ============================================
function TerritorialConquestUtils:CreateCoordinate(lat, lon, alt)
    alt = alt or 0
    return COORDINATE:New(lat, lon, alt)
end

function TerritorialConquestUtils:GetDistance(coord1, coord2)
    if not coord1 or not coord2 then
        return nil
    end
    return coord1:Get2DDistance(coord2)
end

function TerritorialConquestUtils:IsInRange(coord1, coord2, range)
    local distance = self:GetDistance(coord1, coord2)
    if not distance then
        return false
    end
    return distance <= range
end

-- ============================================
-- Coalition Utilities
-- ============================================
function TerritorialConquestUtils:GetCoalitionName(coalition)
    if coalition == coalition.side.BLUE then
        return "Blue"
    elseif coalition == coalition.side.RED then
        return "Red"
    else
        return "Neutral"
    end
end

function TerritorialConquestUtils:GetOppositeCoalition(coalition)
    if coalition == coalition.side.BLUE then
        return coalition.side.RED
    elseif coalition == coalition.side.RED then
        return coalition.side.BLUE
    else
        return coalition.side.NEUTRAL
    end
end

-- ============================================
-- Object Finding Utilities
-- ============================================
function TerritorialConquestUtils:FindGroupByName(name)
    local group = GROUP:FindByName(name)
    if group then
        self:DebugLog("Found group: " .. name)
        return group
    else
        self:WarningLog("Group not found: " .. name)
        return nil
    end
end

function TerritorialConquestUtils:FindStaticByName(name)
    local success, static = pcall(function()
        return STATIC:FindByName(name)
    end)
    
    if success and static then
        self:DebugLog("Found static: " .. name)
        return static
    else
        self:WarningLog("Static not found: " .. name .. " (not placed in mission yet)")
        return nil
    end
end

function TerritorialConquestUtils:FindAirbaseByName(name)
    local airbase = AIRBASE:FindByName(name)
    if airbase then
        self:DebugLog("Found airbase: " .. name)
        return airbase
    else
        self:WarningLog("Airbase not found: " .. name)
        return nil
    end
end

-- ============================================
-- Zone Utilities
-- ============================================
function TerritorialConquestUtils:CreateZone(name, center, radius)
    if not center or not radius then
        TerritorialConquestUtils:ErrorLog("CreateZone: center and radius required")
        return nil
    end
    
    -- Use ZONE_RADIUS for circular zones (MOOSE class)
    -- ZONE_RADIUS:New(ZoneName, Vec2, Radius)
    -- Convert COORDINATE to Vec2
    local vec2 = center:GetVec2()
    local zone = ZONE_RADIUS:New(name, vec2, radius)
    if zone then
        TerritorialConquestUtils:DebugLog("Created zone: " .. name .. " radius " .. tostring(radius) .. "m")
    else
        TerritorialConquestUtils:ErrorLog("Failed to create zone: " .. name)
    end
    return zone
end

function TerritorialConquestUtils:IsUnitInZone(unit, zone)
    if not unit or not zone then
        return false
    end
    return zone:IsUnitInZone(unit)
end

-- ============================================
-- Health/Status Utilities
-- ============================================
function TerritorialConquestUtils:GetHealthPercentage(object)
    if not object then
        return 0
    end
    
    local current = object:GetLife()
    local max = object:GetLife0()
    
    if max and max > 0 then
        return current / max
    else
        return 0
    end
end

function TerritorialConquestUtils:IsDestroyed(object, threshold)
    threshold = threshold or 0.1
    local health = self:GetHealthPercentage(object)
    return health <= threshold
end

function TerritorialConquestUtils:IsCritical(object, threshold)
    threshold = threshold or 0.5
    local health = self:GetHealthPercentage(object)
    return health <= threshold
end

-- ============================================
-- Table Utilities
-- ============================================
function TerritorialConquestUtils:TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function TerritorialConquestUtils:TableCount(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- ============================================
-- String Utilities
-- ============================================
function TerritorialConquestUtils:FormatNumber(number, decimals)
    decimals = decimals or 2
    return string.format("%." .. decimals .. "f", number)
end

function TerritorialConquestUtils:FormatPercentage(value)
    return self:FormatNumber(value * 100, 1) .. "%"
end

-- ============================================
-- Time Utilities
-- ============================================
function TerritorialConquestUtils:GetCurrentTime()
    return timer.getTime()
end

function TerritorialConquestUtils:HasTimeElapsed(lastTime, interval)
    return (self:GetCurrentTime() - lastTime) >= interval
end

-- ============================================
-- Safe Execution
-- ============================================
function TerritorialConquestUtils:SafeExecute(func, errorMessage)
    local success, result = pcall(func)
    if not success then
        self:ErrorLog(errorMessage .. ": " .. tostring(result))
        return nil
    end
    return result
end

env.info("Territorial Conquest Utils loaded")

