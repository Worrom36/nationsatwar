-- ============================================
-- Territory Manager
-- Manages territory definitions, ownership, and control
-- ============================================

TerritoryManager = {}
TerritoryManager.__index = TerritoryManager

-- ============================================
-- Initialization
-- ============================================
function TerritoryManager:Init()
    self.territories = {}
    self.lastUpdateTime = 0
    
    -- Load territory definitions from config
    if TerritorialConquestConfig and TerritorialConquestConfig.Territories then
        for _, territoryDef in ipairs(TerritorialConquestConfig.Territories) do
            self:CreateTerritory(
                territoryDef.name,
                territoryDef.center,
                territoryDef.radius,
                territoryDef.initial_owner,
                territoryDef.factories
            )
        end
    end
    
    TerritorialConquestUtils:DebugLog("TerritoryManager initialized with " .. #self.territories .. " territories")
end

-- ============================================
-- Territory Creation
-- ============================================
function TerritoryManager:CreateTerritory(name, center, radius, initialOwner, factories)
    local territory = {
        name = name,
        zone = nil,
        owner = initialOwner or "Neutral",
        factories = factories or {},
        control_percentage = 0.0,
        is_contested = false,
        last_activity_time = 0,
        units_inside = {}
    }
    
    -- Create zone
    if center and radius then
        local coord = TerritorialConquestUtils:CreateCoordinate(center.lat, center.lon)
        territory.zone = TerritorialConquestUtils:CreateZone(name, coord, radius)
        if territory.zone then
            TerritorialConquestUtils:DebugLog("Created territory zone: " .. name)
        else
            TerritorialConquestUtils:ErrorLog("Failed to create zone for territory: " .. name)
        end
    else
        -- Try to find zone by name (if placed in Mission Editor)
        territory.zone = ZONE:FindByName(name)
        if territory.zone then
            TerritorialConquestUtils:DebugLog("Found existing zone: " .. name)
        else
            TerritorialConquestUtils:WarningLog("Could not create or find zone for territory: " .. name)
        end
    end
    
    table.insert(self.territories, territory)
    return territory
end

-- ============================================
-- Territory Updates
-- ============================================
function TerritoryManager:Update()
    local currentTime = TerritorialConquestUtils:GetCurrentTime()
    local checkInterval = TerritorialConquestConfig.Territory.check_interval
    
    -- Check if it's time to update
    if not TerritorialConquestUtils:HasTimeElapsed(self.lastUpdateTime, checkInterval) then
        return
    end
    
    self.lastUpdateTime = currentTime
    
    -- Update each territory
    for _, territory in ipairs(self.territories) do
        self:UpdateTerritoryControl(territory)
    end
end

-- ============================================
-- Control Calculation
-- ============================================
function TerritoryManager:UpdateTerritoryControl(territory)
    if not territory.zone then
        return
    end
    
    -- Count units by coalition
    local redUnits = 0
    local blueUnits = 0
    
    -- Get all groups in the mission
    local allGroups = SET_GROUP:New():FilterCoalitions("red"):FilterActive():GetSet()
    for _, group in pairs(allGroups) do
        if group:IsAlive() then
            local units = group:GetUnits()
            for _, unit in pairs(units) do
                if TerritorialConquestUtils:IsUnitInZone(unit, territory.zone) then
                    redUnits = redUnits + 1
                end
            end
        end
    end
    
    allGroups = SET_GROUP:New():FilterCoalitions("blue"):FilterActive():GetSet()
    for _, group in pairs(allGroups) do
        if group:IsAlive() then
            local units = group:GetUnits()
            for _, unit in pairs(units) do
                if TerritorialConquestUtils:IsUnitInZone(unit, territory.zone) then
                    blueUnits = blueUnits + 1
                end
            end
        end
    end
    
    -- Calculate control percentage
    local totalUnits = redUnits + blueUnits
    if totalUnits > 0 then
        if territory.owner == "Red" then
            territory.control_percentage = redUnits / totalUnits
        elseif territory.owner == "Blue" then
            territory.control_percentage = blueUnits / totalUnits
        else
            -- Neutral territory - whoever has more units
            if redUnits > blueUnits then
                territory.control_percentage = redUnits / totalUnits
            else
                territory.control_percentage = blueUnits / totalUnits
            end
        end
    else
        territory.control_percentage = 0.0
    end
    
    -- Check for capture/loss
    self:CheckTerritoryStatus(territory)
end

-- ============================================
-- Status Checking
-- ============================================
function TerritoryManager:CheckTerritoryStatus(territory)
    local config = TerritorialConquestConfig.Territory
    
    -- Check for capture
    if territory.owner == "Neutral" or territory.owner == "Red" then
        if territory.control_percentage >= config.capture_threshold then
            self:CaptureTerritory(territory, "Blue")
        end
    elseif territory.owner == "Blue" then
        if territory.control_percentage >= config.capture_threshold then
            self:CaptureTerritory(territory, "Red")
        end
    end
    
    -- Check for loss
    if territory.control_percentage <= config.loss_threshold then
        territory.is_contested = true
    else
        territory.is_contested = false
    end
end

-- ============================================
-- Territory Capture
-- ============================================
function TerritoryManager:CaptureTerritory(territory, newOwner)
    if territory.owner == newOwner then
        return  -- Already owned
    end
    
    local oldOwner = territory.owner
    territory.owner = newOwner
    territory.control_percentage = 1.0
    territory.is_contested = false
    territory.last_activity_time = TerritorialConquestUtils:GetCurrentTime()
    
    TerritorialConquestUtils:DebugLog(
        string.format("Territory %s captured by %s (was %s)", 
        territory.name, newOwner, oldOwner)
    )
    
    -- Trigger events
    if TriggerSystem then
        TriggerSystem:OnTerritoryCaptured(territory, oldOwner, newOwner)
    end
end

-- ============================================
-- Getters
-- ============================================
function TerritoryManager:GetTerritory(name)
    for _, territory in ipairs(self.territories) do
        if territory.name == name then
            return territory
        end
    end
    return nil
end

function TerritoryManager:GetTerritoryCount()
    return #self.territories
end

function TerritoryManager:GetAllTerritories()
    return self.territories
end

env.info("TerritoryManager loaded")

