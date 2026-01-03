-- ============================================
-- Factory Manager
-- Manages factory objects, health, and production
-- ============================================

FactoryManager = {}
FactoryManager.__index = FactoryManager

-- ============================================
-- Initialization
-- ============================================
function FactoryManager:Init()
    self.factories = {}
    self.lastUpdateTime = 0
    
    -- Load factories from config
    if TerritorialConquestConfig and TerritorialConquestConfig.Names.factories then
        for _, factoryName in ipairs(TerritorialConquestConfig.Names.factories) do
            self:RegisterFactory(factoryName)
        end
    end
    
    TerritorialConquestUtils:DebugLog("FactoryManager initialized with " .. #self.factories .. " factories")
end

-- ============================================
-- Factory Registration
-- ============================================
function FactoryManager:RegisterFactory(name)
    -- Find factory static object in mission
    local factoryStatic = TerritorialConquestUtils:FindStaticByName(name)
    
    if not factoryStatic then
        TerritorialConquestUtils:WarningLog("Factory not found in mission: " .. name .. " - skipping (place in Mission Editor to enable)")
        return nil
    end
    
    local factory = {
        name = name,
        static = factoryStatic,
        territory = nil,  -- Will be linked by TerritoryManager
        health_percentage = 1.0,
        is_operational = true,
        owner = "Neutral",  -- Will be determined from static
        position = factoryStatic:GetCoordinate(),
        last_production_time = 0,
    }
    
    -- Get initial owner from static object
    local staticCoalition = factoryStatic:GetCoalition()
    if staticCoalition == 1 then  -- RED
        factory.owner = "Red"
    elseif staticCoalition == 2 then  -- BLUE
        factory.owner = "Blue"
    else
        factory.owner = "Neutral"
    end
    
    -- Get initial health (will be updated in Update() loop)
    local life0 = factoryStatic:GetLife0() or 1
    local currentLife = factoryStatic:GetLife() or life0
    factory.health_percentage = currentLife / life0
    
    table.insert(self.factories, factory)
    TerritorialConquestUtils:DebugLog("Registered factory: " .. name)
    
    return factory
end

-- ============================================
-- Factory Updates
-- ============================================
function FactoryManager:Update()
    local currentTime = TerritorialConquestUtils:GetCurrentTime()
    local productionInterval = TerritorialConquestConfig.Factory.production_interval
    
    -- Update each factory
    for _, factory in ipairs(self.factories) do
        -- Check production
        if factory.is_operational then
            if TerritorialConquestUtils:HasTimeElapsed(factory.last_production_time, productionInterval) then
                self:GenerateProduction(factory)
                factory.last_production_time = currentTime
            end
        end
        
        -- Update health
        local oldHealth = factory.health_percentage
        factory.health_percentage = TerritorialConquestUtils:GetHealthPercentage(factory.static)
        
        -- Check for critical status (health dropped below threshold)
        if factory.health_percentage <= TerritorialConquestConfig.Factory.critical_threshold and
           oldHealth > TerritorialConquestConfig.Factory.critical_threshold then
            if factory.is_operational then
                self:OnFactoryHealthChanged(factory, factory.health_percentage)
            end
        end
        
        -- Check if destroyed
        if factory.health_percentage <= TerritorialConquestConfig.Factory.destruction_threshold then
            if factory.is_operational then
                self:OnFactoryDestroyed(factory)
            end
        end
    end
end

-- ============================================
-- Health Monitoring
-- ============================================
function FactoryManager:OnFactoryHealthChanged(factory, health)
    factory.health_percentage = TerritorialConquestUtils:GetHealthPercentage(factory.static)
    
    -- Check for critical status
    if factory.health_percentage <= TerritorialConquestConfig.Factory.critical_threshold then
        if factory.is_operational then
            TerritorialConquestUtils:WarningLog("Factory " .. factory.name .. " is critically damaged!")
            -- Trigger defensive response
            if TriggerSystem then
                TriggerSystem:OnFactoryUnderAttack(factory)
            end
        end
    end
end

-- ============================================
-- Factory Destruction
-- ============================================
function FactoryManager:OnFactoryDestroyed(factory)
    factory.is_operational = false
    TerritorialConquestUtils:DebugLog("Factory destroyed: " .. factory.name)
    
    -- Trigger events
    if TriggerSystem then
        TriggerSystem:OnFactoryDestroyed(factory)
    end
    
    -- Update territory if linked
    if factory.territory and TerritoryManager then
        TerritoryManager:OnFactoryDestroyed(factory.territory, factory)
    end
end

-- ============================================
-- Production
-- ============================================
function FactoryManager:GenerateProduction(factory)
    if not factory.is_operational then
        return
    end
    
    local production = TerritorialConquestConfig.Factory.production_rate
    TerritorialConquestUtils:DebugLog(
        string.format("Factory %s generated %d resources", factory.name, production)
    )
    
    -- Add resources to owner (if resource system implemented)
    -- This would integrate with a resource management system
end

-- ============================================
-- Getters
-- ============================================
function FactoryManager:GetFactory(name)
    for _, factory in ipairs(self.factories) do
        if factory.name == name then
            return factory
        end
    end
    return nil
end

function FactoryManager:GetFactoryCount()
    return #self.factories
end

function FactoryManager:GetAllFactories()
    return self.factories
end

env.info("FactoryManager loaded")

