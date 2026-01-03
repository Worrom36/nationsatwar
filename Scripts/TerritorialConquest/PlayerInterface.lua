-- ============================================
-- Player Interface
-- F10 menus, map markers, and player commands
-- ============================================

PlayerInterface = {}
PlayerInterface.__index = PlayerInterface

-- ============================================
-- Initialization
-- ============================================
function PlayerInterface:Init()
    self.menus = {}
    self.markers = {}
    
    -- Create F10 menus
    self:CreateMenus()
    
    -- Create map markers if enabled
    if TerritorialConquestConfig and TerritorialConquestConfig.Debug.show_markers then
        self:CreateMapMarkers()
    end
    
    TerritorialConquestUtils:DebugLog("PlayerInterface initialized")
end

-- ============================================
-- F10 Menu Creation
-- ============================================
function PlayerInterface:CreateMenus()
    -- Main menu
    local mainMenu = MENU_COALITION:New(coalition.side.BLUE, "Territorial Conquest")
    local mainMenuRed = MENU_COALITION:New(coalition.side.RED, "Territorial Conquest")
    
    -- Territory Status
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Territory Status", mainMenu, 
        function() PlayerInterface:ShowTerritoryStatus() end)
    MENU_COALITION_COMMAND:New(coalition.side.RED, "Territory Status", mainMenuRed, 
        function() PlayerInterface:ShowTerritoryStatus() end)
    
    -- Request Attacking Column
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Request Attacking Column", mainMenu, 
        function() PlayerInterface:RequestAttackingColumn() end)
    MENU_COALITION_COMMAND:New(coalition.side.RED, "Request Attacking Column", mainMenuRed, 
        function() PlayerInterface:RequestAttackingColumn() end)
    
    -- Request Defensive Reinforcements
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Request Defensive Reinforcements", mainMenu, 
        function() PlayerInterface:RequestDefensiveReinforcements() end)
    MENU_COALITION_COMMAND:New(coalition.side.RED, "Request Defensive Reinforcements", mainMenuRed, 
        function() PlayerInterface:RequestDefensiveReinforcements() end)
    
    table.insert(self.menus, mainMenu)
    table.insert(self.menus, mainMenuRed)
end

-- ============================================
-- Menu Functions
-- ============================================
function PlayerInterface:ShowTerritoryStatus()
    if not TerritoryManager then
        MESSAGE:New("Territory system not available", 10):ToAll()
        return
    end
    
    local territories = TerritoryManager:GetAllTerritories()
    local message = "Territory Status:\n"
    
    for _, territory in ipairs(territories) do
        message = message .. string.format(
            "%s: %s (%.0f%%)\n",
            territory.name,
            territory.owner,
            territory.control_percentage * 100
        )
    end
    
    MESSAGE:New(message, 15):ToAll()
end

function PlayerInterface:RequestAttackingColumn()
    MESSAGE:New("Attacking column request - feature in development", 10):ToAll()
    -- Implementation: Show territory selection menu
end

function PlayerInterface:RequestDefensiveReinforcements()
    MESSAGE:New("Defensive reinforcements request - feature in development", 10):ToAll()
    -- Implementation: Show territory selection menu
end

-- ============================================
-- Map Markers
-- ============================================
function PlayerInterface:CreateMapMarkers()
    if not TerritoryManager then
        return
    end
    
    local territories = TerritoryManager:GetAllTerritories()
    
    for _, territory in ipairs(territories) do
        if territory.zone then
            local coord = territory.zone:GetCoordinate()
            local marker = MARKER:New(coord, territory.name)
            marker:ToAll()
            table.insert(self.markers, marker)
        end
    end
end

function PlayerInterface:UpdateMapMarkers()
    -- Update markers with current status
    -- This would be called periodically to update territory colors, etc.
end

env.info("PlayerInterface loaded")

