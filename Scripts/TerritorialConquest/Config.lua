-- ============================================
-- Territorial Conquest Configuration
-- ============================================

TerritorialConquestConfig = {}

-- ============================================
-- Territory Settings
-- ============================================
TerritorialConquestConfig.Territory = {
    -- Control thresholds
    capture_threshold = 0.7,      -- Control % needed to capture (0.0 to 1.0)
    loss_threshold = 0.3,         -- Control % to lose territory
    contested_threshold = 0.4,    -- Control % range for contested status
    
    -- Detection settings
    check_interval = 5.0,         -- Seconds between control checks
    unit_detection_range = 10000, -- Meters - units within this range affect control
}

-- ============================================
-- Factory Settings
-- ============================================
TerritorialConquestConfig.Factory = {
    -- Health thresholds
    destruction_threshold = 0.2,  -- Health % to be considered destroyed
    critical_threshold = 0.5,     -- Health % for critical status
    
    -- Production settings
    production_interval = 300,    -- Seconds between production cycles
    production_rate = 10,         -- Resources per cycle
    
    -- Factory naming convention (must match Mission Editor names)
    name_prefix = "Factory_",    -- Prefix for factory names
}

-- ============================================
-- Tank Column Settings
-- ============================================
TerritorialConquestConfig.TankColumn = {
    -- Spawn settings
    spawn_cooldown = 600,         -- Seconds between spawns per territory
    max_active_per_side = 5,     -- Maximum active columns per coalition
    
    -- Health thresholds
    health_threshold = 0.3,      -- % health to be considered ineffective
    destruction_threshold = 0.1, -- % health to be destroyed
    
    -- Movement settings
    route_update_interval = 30,  -- Seconds between route checks
    waypoint_distance = 5000,    -- Meters between waypoints
    
    -- Template naming convention (must match Mission Editor names)
    template_prefix = "Tank_Column_Template_",
}

-- ============================================
-- Resource Settings
-- ============================================
TerritorialConquestConfig.Resources = {
    initial = 1000,               -- Starting resources per side
    max = 5000,                   -- Maximum resources
    min = 0,                      -- Minimum resources
    
    -- Costs
    attacking_column_cost = 100, -- Cost to spawn attacking column
    defending_column_cost = 75,  -- Cost to spawn defending column
    
    -- Generation
    base_generation = 5,          -- Resources per cycle (base)
    factory_bonus = 10,           -- Additional resources per factory
}

-- ============================================
-- Trigger System Settings
-- ============================================
TerritorialConquestConfig.Triggers = {
    -- Detection ranges
    threat_detection_range = 50000,    -- Meters to detect threats
    proximity_trigger_range = 30000,  -- Meters for proximity triggers
    
    -- Response times
    automatic_response_delay = 10,     -- Seconds before auto-response
    player_command_cooldown = 5,      -- Seconds between player commands
    
    -- Threat assessment
    min_threat_level = 2,              -- Minimum units for threat
    threat_escalation_time = 60,      -- Seconds to escalate threat
}

-- ============================================
-- Persistence Settings
-- ============================================
TerritorialConquestConfig.Persistence = {
    enabled = true,                    -- Enable state saving
    auto_save_interval = 300,          -- Seconds between auto-saves
    save_file = "territorial_conquest_state.json",
    save_path = (lfs and lfs.writedir and (lfs.writedir()..[[Config\TerritorialConquest\]])) or [[Config\TerritorialConquest\]],
}

-- ============================================
-- Debug Settings
-- ============================================
TerritorialConquestConfig.Debug = {
    enabled = true,                    -- Enable debug logging
    verbose = false,                   -- Verbose logging
    show_zones = true,                 -- Show zones on F10 map
    show_markers = true,                -- Show status markers
}

-- ============================================
-- Mission Editor Object Names
-- ============================================
-- IMPORTANT: These names must match objects placed in Mission Editor
TerritorialConquestConfig.Names = {
    -- Factory names (example - add your actual factory names)
    factories = {
        "Factory_Alpha",
        "Factory_Bravo",
        "Factory_Charlie",
    },
    
    -- Tank column template names (example - add your actual template names)
    tank_templates = {
        attacking = "Tank_Column_Template_Attacking",
        defending = "Tank_Column_Template_Defending",
    },
    
    -- Airfield names (if used)
    airfields = {
        "Kutaisi",
        "Batumi",
    },
}

-- ============================================
-- Territory Definitions
-- ============================================
-- Define territories with coordinates and radius
-- These can be created in code or reference Mission Editor zones
TerritorialConquestConfig.Territories = {
    {
        name = "Territory_Alpha",
        center = {lat = 42.0, lon = 41.5},
        radius = 10000,  -- Meters
        initial_owner = "Red",
        factories = {"Factory_Alpha"},
    },
    {
        name = "Territory_Bravo",
        center = {lat = 42.2, lon = 41.7},
        radius = 10000,
        initial_owner = "Blue",
        factories = {"Factory_Bravo"},
    },
    -- Add more territories as needed
}

-- ============================================
-- Helper Functions
-- ============================================
function TerritorialConquestConfig:GetConfig()
    return self
end

function TerritorialConquestConfig:IsDebugEnabled()
    return self.Debug.enabled
end

function TerritorialConquestConfig:GetFactoryNames()
    return self.Names.factories
end

function TerritorialConquestConfig:GetTankTemplateNames()
    return self.Names.tank_templates
end

env.info("Territorial Conquest Configuration loaded")

