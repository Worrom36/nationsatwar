-- ============================================
-- Territorial Conquest Main Controller
-- ============================================

TerritorialConquest = {}
TerritorialConquest.__index = TerritorialConquest

-- ============================================
-- Initialization
-- ============================================
function TerritorialConquest:Init()
    TerritorialConquestUtils:DebugLog("Initializing Territorial Conquest system")
    
    -- Initialize managers
    if TerritoryManager then
        TerritoryManager:Init()
    else
        TerritorialConquestUtils:ErrorLog("TerritoryManager not found!")
        return false
    end
    
    if FactoryManager then
        FactoryManager:Init()
    else
        TerritorialConquestUtils:WarningLog("FactoryManager not found - factories will not be managed")
    end
    
    if GroundUnitManager then
        GroundUnitManager:Init()
    else
        TerritorialConquestUtils:WarningLog("GroundUnitManager not found - tank columns will not work")
    end
    
    if TriggerSystem then
        TriggerSystem:Init()
    else
        TerritorialConquestUtils:WarningLog("TriggerSystem not found - triggers will not work")
    end
    
    if PlayerInterface then
        PlayerInterface:Init()
    else
        TerritorialConquestUtils:WarningLog("PlayerInterface not found - player commands will not work")
    end
    
    -- Initialize persistence if enabled
    if TerritorialConquestConfig and TerritorialConquestConfig.Persistence.enabled then
        if StatePersistence then
            StatePersistence:Init()
            StatePersistence:LoadState()
        else
            TerritorialConquestUtils:WarningLog("StatePersistence not found - persistence disabled")
        end
    end
    
    -- Start update scheduler
    self:StartUpdateScheduler()
    
    TerritorialConquestUtils:DebugLog("Territorial Conquest system initialized successfully")
    
    -- Display success message to all players
    local territoryCount = TerritoryManager and TerritoryManager:GetTerritoryCount() or 0
    local factoryCount = FactoryManager and FactoryManager:GetFactoryCount() or 0
    
    -- Collect group information for debugging
    local groupInfo = {}
    local tankGroupsFound = {}
    local lateActivatedGroups = {}
    
    -- Check for groups with "Tank" or "Column" in name
    if _DATABASE then
        -- Try to find groups via MOOSE
        local testGroup1 = GROUP:FindByName("Tank_Column_Template_Attacking")
        local testGroup2 = GROUP:FindByName("Tank_Column_Template_Defending")
        
        if testGroup1 then
            table.insert(tankGroupsFound, "Tank_Column_Template_Attacking (FOUND)")
        else
            table.insert(tankGroupsFound, "Tank_Column_Template_Attacking (NOT FOUND)")
        end
        
        if testGroup2 then
            table.insert(tankGroupsFound, "Tank_Column_Template_Defending (FOUND)")
        else
            table.insert(tankGroupsFound, "Tank_Column_Template_Defending (NOT FOUND)")
        end
        
        -- Get all late-activated groups from MOOSE's database
        -- MOOSE stores all group templates in _DATABASE.Templates.Groups
        if _DATABASE and _DATABASE.Templates and _DATABASE.Templates.Groups then
            for groupName, groupData in pairs(_DATABASE.Templates.Groups) do
                if groupData and groupData.Template then
                    local template = groupData.Template
                    -- Check if group is late-activated
                    if template.lateActivation == true then
                        table.insert(lateActivatedGroups, groupName)
                    end
                end
            end
        end
        
        -- Also try DCS native mission.getGroupTemplate for all coalitions
        local coalitionSides = {
            {side = coalition.side.RED, name = "RED"},
            {side = coalition.side.BLUE, name = "BLUE"},
            {side = coalition.side.NEUTRAL, name = "NEUTRAL"}
        }
        
        for _, coalitionData in ipairs(coalitionSides) do
            local coalitionGroups = coalition.getGroups(coalitionData.side)
            if coalitionGroups then
                for _, dcsGroup in pairs(coalitionGroups) do
                    if dcsGroup then
                        local groupName = dcsGroup:getName()
                        local success, template = pcall(function()
                            return mission.getGroupTemplate(groupName)
                        end)
                        if success and template and template.lateActivation == true then
                            -- Avoid duplicates
                            local found = false
                            for _, existing in ipairs(lateActivatedGroups) do
                                if existing == groupName or existing == (coalitionData.name .. ": " .. groupName) then
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                table.insert(lateActivatedGroups, coalitionData.name .. ": " .. groupName)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Build message
    local message = string.format(
        "Territorial Conquest System Initialized!\n" ..
        "Territories: %d | Factories: %d\n",
        territoryCount,
        factoryCount
    )
    
    -- Add tank template status
    if #tankGroupsFound > 0 then
        message = message .. "\nTank Templates:\n"
        for _, status in ipairs(tankGroupsFound) do
            message = message .. "  " .. status .. "\n"
        end
    end
    
    -- Add late-activated groups list
    if #lateActivatedGroups > 0 then
        message = message .. "\nLate-Activated Groups in Mission:\n"
        for _, groupName in ipairs(lateActivatedGroups) do
            message = message .. "  " .. groupName .. "\n"
        end
    else
        message = message .. "\nNo late-activated groups found in mission."
    end
    
    message = message .. "\nSystem ready for operations."
    
    -- Use MOOSE MESSAGE if available, otherwise use DCS native
    if MESSAGE then
        MESSAGE:New(message, 20, "Territorial Conquest"):ToAll():ToLog()
    else
        trigger.action.outText(message, 20)
    end
    
    return true
end

-- ============================================
-- Update Scheduler
-- ============================================
function TerritorialConquest:StartUpdateScheduler()
    -- Schedule periodic updates
    local updateInterval = 1.0  -- Update every second
    
    SCHEDULER:New(nil, function()
        self:Update()
    end, {}, 0, updateInterval)
    
    TerritorialConquestUtils:DebugLog("Update scheduler started")
end

-- ============================================
-- Main Update Loop
-- ============================================
function TerritorialConquest:Update()
    -- Update territory control
    if TerritoryManager then
        TerritoryManager:Update()
    end
    
    -- Update factories
    if FactoryManager then
        FactoryManager:Update()
    end
    
    -- Update ground units
    if GroundUnitManager then
        GroundUnitManager:Update()
    end
    
    -- Update triggers
    if TriggerSystem then
        TriggerSystem:Update()
    end
    
    -- Auto-save if enabled
    if TerritorialConquestConfig and 
       TerritorialConquestConfig.Persistence.enabled and
       StatePersistence then
        StatePersistence:AutoSave()
    end
end

-- ============================================
-- System Status
-- ============================================
function TerritorialConquest:GetStatus()
    local status = {
        initialized = true,
        territories = TerritoryManager and TerritoryManager:GetTerritoryCount() or 0,
        factories = FactoryManager and FactoryManager:GetFactoryCount() or 0,
        active_columns = GroundUnitManager and GroundUnitManager:GetActiveColumnCount() or 0,
    }
    return status
end

env.info("Territorial Conquest Main controller loaded")

