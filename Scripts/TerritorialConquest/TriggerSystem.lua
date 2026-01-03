-- ============================================
-- Trigger System
-- Handles all trigger conditions and responses
-- ============================================

TriggerSystem = {}
TriggerSystem.__index = TriggerSystem

-- ============================================
-- Initialization
-- ============================================
function TriggerSystem:Init()
    self.eventHandlers = {}
    self.lastUpdateTime = 0
    
    -- Setup event handlers
    self:SetupEventHandlers()
    
    TerritorialConquestUtils:DebugLog("TriggerSystem initialized")
end

-- ============================================
-- Event Handler Setup
-- ============================================
function TriggerSystem:SetupEventHandlers()
    -- Unit destroyed events (Dead events)
    -- Use world.onEvent directly - MOOSE will process it first, then we handle it
    local originalOnEvent = world.onEvent
    world.onEvent = function(event)
        -- Call original handler first (MOOSE processes it)
        if originalOnEvent then
            originalOnEvent(event)
        end
        
        -- Handle Dead events for our system
        if event.id == world.event.S_EVENT_DEAD then
            self:OnUnitDestroyed(event)
        end
    end
    
    TerritorialConquestUtils:DebugLog("Event handlers registered")
end

-- ============================================
-- Unit Destroyed Handler
-- ============================================
function TriggerSystem:OnUnitDestroyed(event)
    -- MOOSE event structure: event.IniUnit or event.IniDCSUnit
    local unit = nil
    if event.IniUnit then
        unit = event.IniUnit
    elseif event.IniDCSUnit then
        -- Try to wrap DCS unit in MOOSE UNIT wrapper
        local success, wrappedUnit = pcall(function()
            return UNIT:FindByName(event.IniUnitName)
        end)
        if success and wrappedUnit then
            unit = wrappedUnit
        end
    end
    
    if not unit then
        return
    end
    
    -- Check if it's a factory (static object)
    if FactoryManager and event.IniObjectCategory == Object.Category.STATIC then
        local factories = FactoryManager:GetAllFactories()
        for _, factory in ipairs(factories) do
            if factory.static and event.IniUnitName and factory.static:GetName() == event.IniUnitName then
                -- Factory destruction handled by FactoryManager
                FactoryManager:OnFactoryDestroyed(factory.name)
                return
            end
        end
    end
    
    -- Check if it's a unit in a territory
    if TerritoryManager and unit and event.IniObjectCategory == Object.Category.UNIT then
        local territories = TerritoryManager:GetAllTerritories()
        for _, territory in ipairs(territories) do
            if territory.zone and TerritorialConquestUtils:IsUnitInZone(unit, territory.zone) then
                -- Territory activity
                territory.last_activity_time = TerritorialConquestUtils:GetCurrentTime()
            end
        end
    end
end

-- ============================================
-- Territory Events
-- ============================================
function TriggerSystem:OnTerritoryCaptured(territory, oldOwner, newOwner)
    TerritorialConquestUtils:DebugLog(
        string.format("Territory %s captured by %s", territory.name, newOwner)
    )
    
    -- Spawn attacking column from captured territory
    if GroundUnitManager and territory.zone then
        local territoryCoord = territory.zone:GetCoordinate()
        -- Find adjacent enemy territory to attack
        -- This is a simplified example
        if newOwner == "Blue" then
            -- Spawn column to attack next Red territory
            -- Implementation would find adjacent territory
        end
    end
end

-- ============================================
-- Factory Events
-- ============================================
function TriggerSystem:OnFactoryUnderAttack(factory)
    TerritorialConquestUtils:DebugLog("Factory under attack: " .. factory.name)
    
    -- Spawn defensive column
    if GroundUnitManager then
        local factoryCoord = factory.position
        GroundUnitManager:SpawnTankColumn("defending", factoryCoord, factoryCoord, factory.owner)
    end
end

function TriggerSystem:OnFactoryDestroyed(factory)
    TerritorialConquestUtils:DebugLog("Factory destroyed: " .. factory.name)
    
    -- Factory destruction may trigger territory vulnerability
    if TerritoryManager and factory.territory then
        -- Territory becomes more vulnerable
    end
end

-- ============================================
-- Tank Column Events
-- ============================================
function TriggerSystem:OnTankColumnArrived(column)
    TerritorialConquestUtils:DebugLog("Tank column arrived: " .. column.id)
    
    -- Column arrival may affect territory control
    if column.target and TerritoryManager then
        -- Find territory at target location
        -- Update territory control
    end
end

function TriggerSystem:OnTankColumnDestroyed(column)
    TerritorialConquestUtils:DebugLog("Tank column destroyed: " .. column.id)
    -- Handle column destruction
end

-- ============================================
-- Updates
-- ============================================
function TriggerSystem:Update()
    -- Periodic trigger checks can be added here
    -- For example, proximity-based triggers
end

env.info("TriggerSystem loaded")

