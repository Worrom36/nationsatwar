-- ============================================
-- Ground Unit Manager
-- Manages tank column spawning and movement
-- ============================================

GroundUnitManager = {}
GroundUnitManager.__index = GroundUnitManager

-- ============================================
-- Initialization
-- ============================================
function GroundUnitManager:Init()
    self.tank_columns = {}
    self.spawn_templates = {}
    self.lastUpdateTime = 0
    
    -- Load spawn templates from config
    -- Try immediate registration first, then retry after delay if needed
    if TerritorialConquestConfig and TerritorialConquestConfig.Names.tank_templates then
        local templates = TerritorialConquestConfig.Names.tank_templates
        local selfRef = self
        
        TerritorialConquestUtils:DebugLog("Registering spawn templates...")
        
        -- Try immediate registration
        if templates.attacking then
            self:RegisterSpawnTemplate(templates.attacking, "attacking")
        end
        if templates.defending then
            self:RegisterSpawnTemplate(templates.defending, "defending")
        end
        
        -- Also schedule a retry after delay in case groups weren't ready
        local scheduler, scheduleID = SCHEDULER:New(nil, function()
            TerritorialConquestUtils:DebugLog("Retrying spawn template registration after delay...")
            if templates.attacking and not selfRef.spawn_templates["attacking"] then
                selfRef:RegisterSpawnTemplate(templates.attacking, "attacking")
            end
            if templates.defending and not selfRef.spawn_templates["defending"] then
                selfRef:RegisterSpawnTemplate(templates.defending, "defending")
            end
        end, {}, 1.0)  -- 1 second delay for retry
        
        -- Start the scheduler
        if scheduler then
            scheduler:Start()
        end
    else
        TerritorialConquestUtils:WarningLog("Tank templates not found in config!")
    end
    
    TerritorialConquestUtils:DebugLog("GroundUnitManager initialized")
end

-- ============================================
-- Spawn Template Registration
-- ============================================
function GroundUnitManager:RegisterSpawnTemplate(name, type)
    TerritorialConquestUtils:DebugLog("Attempting to register spawn template: " .. name)
    
    -- First check if template exists in MOOSE's database
    if _DATABASE and _DATABASE.Templates and _DATABASE.Templates.Groups and _DATABASE.Templates.Groups[name] then
        TerritorialConquestUtils:DebugLog("  Template found in MOOSE database")
    else
        TerritorialConquestUtils:WarningLog("  Template NOT in MOOSE database: " .. name)
    end
    
    -- Check if group is registered in MOOSE's GROUP database
    local group = GROUP:FindByName(name)
    if not group then
        TerritorialConquestUtils:DebugLog("  Group not in MOOSE GROUP database (may be late-activated)")
        -- For late-activated groups, we need to manually register them in MOOSE
        -- Check if template exists and try to register the group
        if _DATABASE and _DATABASE.Templates and _DATABASE.Templates.Groups and _DATABASE.Templates.Groups[name] then
            TerritorialConquestUtils:DebugLog("  Template exists, attempting to register group in MOOSE...")
            -- Try to add the group to MOOSE's database
            local addSuccess = pcall(function()
                _DATABASE:AddGroup(name, true)  -- force=true to add even if not active
            end)
            if addSuccess then
                -- Try finding again
                group = GROUP:FindByName(name)
                if group then
                    TerritorialConquestUtils:DebugLog("  Group successfully registered in MOOSE!")
                else
                    TerritorialConquestUtils:WarningLog("  Group registration attempted but still not found")
                end
            else
                TerritorialConquestUtils:WarningLog("  Failed to register group in MOOSE database")
            end
        end
    end
    
    -- Now try SPAWN:New() - it requires GROUP:FindByName() to work
    local success, spawn = pcall(function()
        return SPAWN:New(name)
    end)
    
    if not success or not spawn then
        TerritorialConquestUtils:WarningLog("Spawn template registration failed: " .. name)
        TerritorialConquestUtils:WarningLog("  Template exists in mission but MOOSE can't access it")
        TerritorialConquestUtils:WarningLog("  This may be a MOOSE initialization timing issue")
        return nil
    end
    
    -- Success! SPAWN object created
    self.spawn_templates[type] = spawn
    TerritorialConquestUtils:DebugLog("Registered spawn template: " .. name .. " (" .. type .. ")")
    return spawn
end

-- ============================================
-- Tank Column Spawning
-- ============================================
function GroundUnitManager:SpawnTankColumn(type, originCoord, targetCoord, coalition)
    local templateType = type or "attacking"
    local spawn = self.spawn_templates[templateType]
    
    if not spawn then
        TerritorialConquestUtils:ErrorLog("Spawn template not found for type: " .. templateType)
        return nil
    end
    
    -- Check spawn limits
    if not self:CanSpawnColumn(coalition) then
        TerritorialConquestUtils:WarningLog("Cannot spawn column - limit reached for " .. coalition)
        return nil
    end
    
    -- Create column object
    local currentTime = TerritorialConquestUtils:GetCurrentTime()
    local column = {
        id = "Column_" .. type .. "_" .. math.floor(currentTime * 1000),
        type = type,
        coalition = coalition,
        group = nil,
        origin = originCoord,
        target = targetCoord,
        status = "spawning",
        spawn_time = currentTime,
        health_percentage = 1.0,
    }
    
    -- Spawn with callback
    spawn:OnSpawnGroup(function(spawnedGroup)
        column.group = spawnedGroup
        column.status = "moving"
        
        -- Set route
        if originCoord and targetCoord then
            local route = {originCoord, targetCoord}
            spawnedGroup:RouteGroundTo(route)
        end
        
        -- Monitor health
        spawnedGroup:MonitorHealth(function(group, health)
            GroundUnitManager:OnColumnHealthChanged(column, health)
        end)
        
        TerritorialConquestUtils:DebugLog("Tank column spawned: " .. column.id)
    end)
    
    -- Spawn at origin
    if originCoord then
        spawn:SpawnAtCoordinate(originCoord)
    else
        spawn:Spawn()
    end
    
    table.insert(self.tank_columns, column)
    return column
end

-- ============================================
-- Column Updates
-- ============================================
function GroundUnitManager:Update()
    local currentTime = TerritorialConquestUtils:GetCurrentTime()
    
    -- Update each column
    for i = #self.tank_columns, 1, -1 do
        local column = self.tank_columns[i]
        
        if column.group then
            -- Check if destroyed
            if not column.group:IsAlive() then
                self:DestroyColumn(column)
                table.remove(self.tank_columns, i)
            else
                -- Update health
                column.health_percentage = TerritorialConquestUtils:GetHealthPercentage(column.group)
                
                -- Check if reached target
                if column.target then
                    local currentPos = column.group:GetCoordinate()
                    local distance = TerritorialConquestUtils:GetDistance(currentPos, column.target)
                    if distance and distance < 1000 then  -- Within 1km
                        self:OnColumnArrived(column)
                    end
                end
            end
        end
    end
end

-- ============================================
-- Column Health
-- ============================================
function GroundUnitManager:OnColumnHealthChanged(column, health)
    column.health_percentage = TerritorialConquestUtils:GetHealthPercentage(column.group)
    
    if column.health_percentage <= TerritorialConquestConfig.TankColumn.destruction_threshold then
        TerritorialConquestUtils:DebugLog("Tank column destroyed: " .. column.id)
        self:DestroyColumn(column)
    end
end

-- ============================================
-- Column Arrival
-- ============================================
function GroundUnitManager:OnColumnArrived(column)
    TerritorialConquestUtils:DebugLog("Tank column arrived at target: " .. column.id)
    column.status = "arrived"
    
    -- Trigger events
    if TriggerSystem then
        TriggerSystem:OnTankColumnArrived(column)
    end
end

-- ============================================
-- Column Destruction
-- ============================================
function GroundUnitManager:DestroyColumn(column)
    column.status = "destroyed"
    TerritorialConquestUtils:DebugLog("Tank column destroyed: " .. column.id)
    
    -- Trigger events
    if TriggerSystem then
        TriggerSystem:OnTankColumnDestroyed(column)
    end
end

-- ============================================
-- Spawn Limits
-- ============================================
function GroundUnitManager:CanSpawnColumn(coalition)
    local count = 0
    for _, column in ipairs(self.tank_columns) do
        if column.coalition == coalition and column.status ~= "destroyed" then
            count = count + 1
        end
    end
    
    return count < TerritorialConquestConfig.TankColumn.max_active_per_side
end

-- ============================================
-- Getters
-- ============================================
function GroundUnitManager:GetActiveColumnCount()
    local count = 0
    for _, column in ipairs(self.tank_columns) do
        if column.status ~= "destroyed" then
            count = count + 1
        end
    end
    return count
end

function GroundUnitManager:GetColumnsByCoalition(coalition)
    local columns = {}
    for _, column in ipairs(self.tank_columns) do
        if column.coalition == coalition then
            table.insert(columns, column)
        end
    end
    return columns
end

env.info("GroundUnitManager loaded")

