-- ============================================
-- DCS Territorial Conquest Mission
-- Main Initialization Script
-- ============================================

env.info("============================================")
env.info("Territorial Conquest Mission - Initializing")
env.info("============================================")

-- Get script directory
-- Development folder: D:\CardinalCollective\perforce\nationsatwar\Scripts\
-- Use absolute path to development folder
local devScriptPath = [[D:\CardinalCollective\perforce\nationsatwar\Scripts\]]
local missionScriptPath = [[Scripts\]]

-- Try development folder first
local scriptPath = devScriptPath
env.info("Using development folder: " .. scriptPath)

-- ============================================
-- Load MOOSE Framework (Dynamic Loader)
-- ============================================
-- Try to load MOOSE dynamic loader from development folder
-- Use dofile() directly with absolute path - it may work better than loadfile()
local mooseDynamicLoader = scriptPath..[[MOOSE\Moose Setup\Moose Templates\Moose_Dynamic_Loader.lua]]
local mooseLoaded = false

-- Try dofile() with absolute path (may work in DCS)
local success, err = pcall(function()
    MOOSE_DEVELOPMENT_FOLDER = scriptPath..[[MOOSE\Moose Development]]
    dofile(mooseDynamicLoader)
    mooseLoaded = true
end)

if mooseLoaded then
    env.info("MOOSE Framework loaded successfully (Dynamic)")
else
    -- Try mission folder as fallback
    env.info("Not found in dev folder, trying mission folder")
    local missionMoosePath = missionScriptPath..[[MOOSE\Moose Setup\Moose Templates\Moose_Dynamic_Loader.lua]]
    local missionSuccess, missionErr = pcall(function()
        scriptPath = missionScriptPath
        MOOSE_DEVELOPMENT_FOLDER = scriptPath..[[MOOSE\Moose Development]]
        dofile(missionMoosePath)
        mooseLoaded = true
    end)
    
    if mooseLoaded then
        env.info("MOOSE Framework loaded from mission folder")
    else
        env.error("MOOSE dynamic loader not found")
        env.error("Tried: " .. mooseDynamicLoader)
        env.error("Error: " .. tostring(err or missionErr))
        env.error("Please ensure MOOSE is at: D:\\CardinalCollective\\perforce\\nationsatwar\\Scripts\\MOOSE\\")
        return
    end
end

-- ============================================
-- Load Configuration
-- ============================================
local configPath = scriptPath..[[TerritorialConquest\Config.lua]]
local success, err = pcall(function()
    dofile(configPath)
    env.info("Configuration loaded")
end)
if not success then
    env.warning("Config.lua not found, using defaults: " .. tostring(err))
end

-- ============================================
-- Load Utility Functions
-- ============================================
local utilsPath = scriptPath..[[TerritorialConquest\Utils.lua]]
local success, err = pcall(function()
    dofile(utilsPath)
    env.info("Utils loaded")
end)
if not success then
    env.warning("Utils.lua not found: " .. tostring(err))
end

-- ============================================
-- Load Core Modules
-- ============================================
local modules = {
    "TerritoryManager",
    "FactoryManager",
    "GroundUnitManager",
    "TriggerSystem",
    "StatePersistence",
    "PlayerInterface"
}

for _, module in ipairs(modules) do
    local modulePath = scriptPath..[[TerritorialConquest\]]..module..[[.lua]]
    local success, err = pcall(function()
        dofile(modulePath)
        env.info("Loaded module: " .. module)
    end)
    if not success then
        env.warning("Module not found: " .. module .. " - " .. tostring(err))
    end
end

-- ============================================
-- Load Main Controller
-- ============================================
local mainPath = scriptPath..[[TerritorialConquest\Main.lua]]
local success, err = pcall(function()
    dofile(mainPath)
    env.info("Main controller loaded")
end)
if not success then
    env.error("Main.lua not found! Error: " .. tostring(err))
    return
end

-- ============================================
-- Initialize System
-- ============================================
if TerritorialConquest then
    TerritorialConquest:Init()
    env.info("Territorial Conquest system initialized successfully")
else
    env.error("TerritorialConquest object not found - initialization failed!")
end

env.info("============================================")
env.info("Initialization Complete")
env.info("============================================")

