-- ============================================
-- State Persistence
-- Saves and loads campaign state
-- ============================================

StatePersistence = {}
StatePersistence.__index = StatePersistence

-- ============================================
-- Initialization
-- ============================================
function StatePersistence:Init()
    if not TerritorialConquestConfig or not TerritorialConquestConfig.Persistence then
        TerritorialConquestUtils:WarningLog("StatePersistence: Config not available")
        return
    end
    
    self.lastSaveTime = 0
    self.savePath = TerritorialConquestConfig.Persistence.save_path
    self.saveFile = TerritorialConquestConfig.Persistence.save_file
    
    -- Ensure save directory exists
    if self.savePath and lfs and lfs.mkdir then
        lfs.mkdir(self.savePath)
    end
    
    TerritorialConquestUtils:DebugLog("StatePersistence initialized")
end

-- ============================================
-- Save State
-- ============================================
function StatePersistence:SaveState()
    if not TerritorialConquestConfig.Persistence.enabled then
        return
    end
    
    local state = {
        timestamp = os.time(),
        territories = {},
        factories = {},
        resources = {},
    }
    
    -- Save territory states
    if TerritoryManager then
        local territories = TerritoryManager:GetAllTerritories()
        for _, territory in ipairs(territories) do
            table.insert(state.territories, {
                name = territory.name,
                owner = territory.owner,
                control_percentage = territory.control_percentage,
            })
        end
    end
    
    -- Save factory states
    if FactoryManager then
        local factories = FactoryManager:GetAllFactories()
        for _, factory in ipairs(factories) do
            table.insert(state.factories, {
                name = factory.name,
                health_percentage = factory.health_percentage,
                is_operational = factory.is_operational,
                owner = factory.owner,
            })
        end
    end
    
    -- Convert to JSON (simplified - would need JSON library)
    -- For now, just log that we would save
    TerritorialConquestUtils:DebugLog("State saved (simplified implementation)")
    
    -- Full implementation would:
    -- 1. Serialize state to JSON
    -- 2. Write to file
    -- 3. Handle errors
end

-- ============================================
-- Load State
-- ============================================
function StatePersistence:LoadState()
    if not TerritorialConquestConfig.Persistence.enabled then
        return
    end
    
    local filePath = self.savePath .. self.saveFile
    
    if lfs and lfs.attributes then
        if not lfs.attributes(filePath) then
            TerritorialConquestUtils:DebugLog("No saved state found, starting fresh")
            return
        end
    else
        TerritorialConquestUtils:DebugLog("lfs not available, cannot check for saved state")
        return
    end
    
    -- Load state from file
    -- Full implementation would:
    -- 1. Read JSON file
    -- 2. Parse JSON
    -- 3. Restore territory/factory states
    -- 4. Handle errors
    
    TerritorialConquestUtils:DebugLog("State loaded (simplified implementation)")
end

-- ============================================
-- Auto Save
-- ============================================
function StatePersistence:AutoSave()
    local interval = TerritorialConquestConfig.Persistence.auto_save_interval
    
    if TerritorialConquestUtils:HasTimeElapsed(self.lastSaveTime, interval) then
        self:SaveState()
        self.lastSaveTime = TerritorialConquestUtils:GetCurrentTime()
    end
end

env.info("StatePersistence loaded")

