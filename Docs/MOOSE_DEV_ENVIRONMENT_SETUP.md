# MOOSE Development Environment Setup Guide

## Overview

This document provides a comprehensive guide for setting up a development environment for creating DCS World missions using the MOOSE (Mission Object-Oriented Scripting Environment) framework. This environment will support the development of the Territorial Conquest system and other MOOSE-based missions.

---

## Prerequisites

### Required Software

1. **DCS World**
   - Latest stable version installed
   - At least one map module (Caucasus recommended for testing)
   - Mission Editor access
   - Location: Typically `C:\Users\[Username]\Saved Games\DCS\` or `D:\CardinalCollective\perforce\nationsatwar\`

2. **Text Editor / IDE**
   - **Recommended**: Visual Studio Code (VS Code)
   - **Alternatives**: Notepad++, Sublime Text, Lua IDE
   - **Optional**: Lua language support extensions

3. **Version Control**
   - **Git** (for version control)
   - **GitHub/GitLab account** (optional, for backup and collaboration)

4. **Lua Runtime** (Optional but Recommended)
   - Lua 5.1 or 5.3 interpreter for syntax checking
   - Helps catch errors before testing in DCS

### Required Knowledge

- Basic understanding of Lua scripting
- Familiarity with DCS Mission Editor
- Understanding of object-oriented programming concepts
- Basic Git knowledge (if using version control)

---

## Installation Steps

### Step 1: Install DCS World

1. Download and install DCS World from official website
2. Run DCS at least once to create Saved Games folder structure
3. Verify Mission Editor is accessible

### Step 2: Download MOOSE Framework

1. **Get MOOSE from GitHub**:
   - Visit: https://github.com/FlightControl-Master/MOOSE
   - Download latest release (ZIP file)
   - Or clone repository: `git clone https://github.com/FlightControl-Master/MOOSE.git`

2. **Extract MOOSE**:
   - Extract to a development folder (e.g., `D:\CardinalCollective\perforce\nationsatwar\Scripts\MOOSE\`)
   - Keep folder structure intact

3. **Verify MOOSE Structure**:
   ```
   MOOSE/
   ├── MOOSE.lua
   ├── Core/
   ├── Missions/
   └── (other folders)
   ```

### Step 3: Set Up Development Workspace

**Recommended Folder Structure**:
```
D:\CardinalCollective\perforce\nationsatwar\
├── Scripts\
│   └── MOOSE\                # MOOSE framework
│   └── (MOOSE files)
├── Projects\                 # Your mission projects
│   ├── TerritorialConquest\
│   │   ├── Scripts\
│   │   ├── Missions\
│   │   └── Docs\
│   └── (other projects)
├── Tools\                     # Development tools
│   ├── LuaCheck\             # Lua syntax checker (optional)
│   └── MissionConverter\    # Any conversion tools
└── Saved Games\              # DCS Saved Games (if linking)
    └── DCS\
        └── Missions\
```

### Step 4: Configure Text Editor (VS Code)

#### Install Extensions

1. **Lua Language Support**:
   - Extension: "Lua" by sumneko
   - Provides syntax highlighting, autocomplete, error checking

2. **Lua Debug** (Optional):
   - Extension: "Lua Debug" by actboy168
   - Enables debugging capabilities

3. **Git Integration**:
   - Built-in VS Code Git support
   - Or "GitLens" extension for enhanced Git features

4. **Markdown Support**:
   - Built-in or "Markdown All in One"

#### VS Code Settings

Create `.vscode/settings.json` in your project root:
```json
{
    "lua.runtime.version": "Lua 5.1",
    "lua.workspace.library": [
        "${workspaceFolder}/MOOSE/Core",
        "${workspaceFolder}/MOOSE/Missions"
    ],
    "files.associations": {
        "*.lua": "lua"
    },
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "files.eol": "\n"
}
```

### Step 5: Create Test Mission

1. **Create Basic Test Mission**:
   - Open DCS Mission Editor
   - Create new mission on Caucasus map
   - Add a few units (aircraft, ground units)
   - Save as `Test_MOOSE.miz`

2. **Add MOOSE to Mission**:
   - Extract `.miz` file (it's a ZIP archive)
   - Copy MOOSE files to `Scripts/MOOSE/` folder
   - Re-zip and rename to `.miz`
   - Or use mission editor's script loading feature

3. **Create Simple Test Script**:
   ```lua
   -- Test script to verify MOOSE loads
   local function TestMOOSE()
       env.info("MOOSE Test: Framework loaded successfully!")
       return true
   end
   
   TestMOOSE()
   ```

4. **Test in DCS**:
   - Load mission in DCS
   - Check log files for MOOSE initialization
   - Verify no errors

---

## Development Tools Setup

### 1. Lua Syntax Checker

**Purpose**: Catch syntax errors before testing in DCS

**Installation**:
1. Download Lua interpreter (5.1 recommended for DCS compatibility)
2. Add to system PATH
3. Configure VS Code to use it

**Usage**:
```bash
# Check a Lua file
lua -l script.lua

# Or use VS Code Lua extension (automatic)
```

### 2. Git Repository Setup

**Initialize Git Repository**:
```bash
cd D:\CardinalCollective\perforce\nationsatwar
git init
git add .
git commit -m "Initial commit"
```

**Create .gitignore**:
```
# DCS specific
*.miz
*.log
*.tmp

# Lua
*.luac

# OS
.DS_Store
Thumbs.db
*.swp
*.swo

# IDE
.vscode/
.idea/
*.sublime-project
*.sublime-workspace
```

### 3. Mission File Management

**Understanding .miz Files**:
- `.miz` files are ZIP archives
- Can be extracted and modified
- Contains: mission file, scripts, media

**Development Workflow**:
1. Extract mission: `unzip Mission.miz -d Mission/`
2. Edit scripts in extracted folder
3. Re-zip: `zip -r Mission.miz Mission/`
4. Or use DCS Mission Editor to load scripts directly

**Automation Script** (Optional):
Create a batch/PowerShell script to automate extraction/repacking:
```powershell
# extract_mission.ps1
param($missionFile)
$name = [System.IO.Path]::GetFileNameWithoutExtension($missionFile)
Expand-Archive -Path $missionFile -DestinationPath $name -Force
Write-Host "Extracted to: $name"
```

### 4. Log File Monitoring

**DCS Log Locations**:
- Windows: `C:\Users\[Username]\Saved Games\DCS\Logs\`
- Log file: `dcs.log` (latest)

**Tools for Log Monitoring**:
- **DCS Log Viewer**: Community tool for parsing logs
- **VS Code**: Open log file and use search/filter
- **Notepad++**: With log viewer plugins

**Useful Log Commands**:
```lua
-- In your scripts
env.info("Debug: Variable value = " .. tostring(variable))
env.warning("Warning: Something happened")
env.error("Error: Something went wrong")
```

---

## Project Structure Template

### Recommended Structure

```
TerritorialConquest/
├── .git/
├── .vscode/
│   └── settings.json
├── Scripts/
│   ├── MOOSE/              # MOOSE framework (or symlink)
│   │   ├── MOOSE.lua
│   │   └── Core/
│   ├── TerritorialConquest/
│   │   ├── Main.lua
│   │   ├── TerritoryManager.lua
│   │   ├── FactoryManager.lua
│   │   ├── GroundUnitManager.lua
│   │   ├── TriggerSystem.lua
│   │   ├── StatePersistence.lua
│   │   ├── PlayerInterface.lua
│   │   ├── Config.lua
│   │   └── Utils.lua
│   └── Init.lua
├── Missions/
│   ├── Test_TerritorialConquest.miz
│   └── Development_Test.miz
├── Docs/
│   ├── TERRITORIAL_CONQUEST_PLAN.md
│   ├── MOOSE_DEV_ENVIRONMENT_SETUP.md
│   └── API_REFERENCE.md
├── Tools/
│   └── (utility scripts)
├── .gitignore
└── README.md
```

### Script Organization

**Main Entry Point** (`Scripts/Init.lua`):
```lua
-- Load MOOSE
dofile(lfs.writedir()..[[Scripts\MOOSE\MOOSE.lua]])

-- Load project scripts
dofile(lfs.writedir()..[[Scripts\TerritorialConquest\Config.lua]])
dofile(lfs.writedir()..[[Scripts\TerritorialConquest\Utils.lua]])
dofile(lfs.writedir()..[[Scripts\TerritorialConquest\TerritoryManager.lua]])
-- ... other modules
dofile(lfs.writedir()..[[Scripts\TerritorialConquest\Main.lua]])

-- Initialize system
TerritorialConquest:Init()
```

---

## Development Workflow

### Daily Development Cycle

1. **Planning**
   - Review task/feature to implement
   - Check MOOSE documentation for relevant classes
   - Plan implementation approach

2. **Coding**
   - Write code in VS Code with Lua support
   - Use syntax checker to catch errors
   - Follow coding standards (see below)

3. **Testing**
   - Load mission in DCS
   - Test functionality
   - Check log files for errors
   - Iterate on fixes

4. **Documentation**
   - Update code comments
   - Update documentation if needed
   - Commit changes to Git

### Testing Workflow

1. **Unit Testing** (Individual Components):
   - Test each module in isolation
   - Create test missions for specific features
   - Verify MOOSE class usage

2. **Integration Testing** (Component Interaction):
   - Test modules working together
   - Verify data flow between components
   - Test edge cases

3. **System Testing** (Full System):
   - Test complete Territorial Conquest system
   - Multiplayer testing (if applicable)
   - Performance testing

4. **Regression Testing**:
   - Verify existing features still work
   - Test after each major change

### Debugging Workflow

1. **Enable Debug Logging**:
   ```lua
   local DEBUG = true
   
   function DebugLog(message)
       if DEBUG then
           env.info("[DEBUG] " .. message)
       end
   end
   ```

2. **Use DCS Log Files**:
   - Monitor `dcs.log` in real-time
   - Search for error messages
   - Check MOOSE initialization

3. **In-Game Testing**:
   - Use F10 map to visualize zones
   - Check unit positions
   - Verify triggers fire correctly

4. **MOOSE Debug Tools**:
   - MOOSE may have built-in debug modes
   - Check MOOSE documentation
   - Use MOOSE's logging functions

---

## Coding Standards

### Lua Style Guide

**Naming Conventions**:
```lua
-- Classes (PascalCase)
TerritoryManager = {}
FactoryManager = {}

-- Functions (camelCase)
function calculateTerritoryControl()
end

-- Variables (camelCase)
local territoryName = "Alpha"
local isContested = false

-- Constants (UPPER_SNAKE_CASE)
local MAX_TERRITORIES = 10
local CAPTURE_THRESHOLD = 0.7

-- MOOSE objects (PascalCase, match MOOSE style)
local ZoneAlpha = ZONE:New("Zone_Alpha")
local SpawnTemplate = SPAWN:New("Tank_Column")
```

**Code Organization**:
```lua
-- 1. Module declaration
TerritoryManager = {}

-- 2. Dependencies/Imports
local MOOSE = require("MOOSE")

-- 3. Constants
local DEFAULT_CAPTURE_THRESHOLD = 0.7

-- 4. Module-level variables
local territories = {}

-- 5. Private functions
local function calculateControl(territory)
    -- Implementation
end

-- 6. Public functions
function TerritoryManager:CreateTerritory(name, zone, owner)
    -- Implementation
end

-- 7. Initialization
function TerritoryManager:Init()
    -- Setup code
end
```

**Comments**:
```lua
-- Single line comment

--[[
    Multi-line comment
    for complex explanations
]]

--- Function documentation comment
-- @param territory Territory object
-- @return boolean success status
function TerritoryManager:CaptureTerritory(territory)
    -- Implementation
end
```

**Error Handling**:
```lua
function SafeFunction()
    local success, result = pcall(function()
        -- Risky operation
        return riskyOperation()
    end)
    
    if not success then
        env.error("Error in SafeFunction: " .. tostring(result))
        return nil
    end
    
    return result
end
```

---

## MOOSE-Specific Development Tips

### 1. Understanding MOOSE Classes

**Study MOOSE Documentation**:
- Read class documentation before using
- Understand class methods and properties
- Check examples in MOOSE repository

**Common Patterns**:
```lua
-- Zone creation and usage
local zone = ZONE:New("Zone_Name")
if zone:IsUnitInZone(unit) then
    -- Unit is in zone
end

-- Spawn creation
local spawn = SPAWN:New("Unit_Template")
spawn:OnSpawnGroup(function(group)
    -- Handle spawned group
end)
spawn:Spawn()

-- Event handling
local eventHandler = EVENT:New()
eventHandler:OnEventUnitDestroyed(function(event)
    -- Handle unit destroyed
end)
```

### 2. MOOSE Initialization

**Proper MOOSE Loading**:
```lua
-- Load MOOSE first
local moosePath = lfs.writedir()..[[Scripts\MOOSE\MOOSE.lua]]
if lfs.attributes(moosePath) then
    dofile(moosePath)
    env.info("MOOSE loaded successfully")
else
    env.error("MOOSE not found at: " .. moosePath)
    return
end
```

### 3. MOOSE Object Lifecycle

**Understanding Object Creation**:
- MOOSE objects are created with `:New()` method
- Objects persist until explicitly destroyed
- Some objects auto-cleanup, others need manual cleanup

**Memory Management**:
```lua
-- Store references to avoid garbage collection
local zones = {}  -- Keep references
zones["Alpha"] = ZONE:New("Zone_Alpha")

-- Cleanup when done
function Cleanup()
    zones = nil
    collectgarbage()
end
```

### 4. MOOSE Event System

**Event Handler Pattern**:
```lua
-- Create event handler
local handler = EVENT:New()

-- Register event
handler:OnEventUnitDestroyed(function(event)
    local unit = event.IniUnit
    local initiator = event.IniUnit:GetGroup()
    
    -- Handle event
    ProcessUnitDestroyed(unit, initiator)
end)

-- Handler is active until mission ends or handler is destroyed
```

---

## Testing Setup

### Test Mission Template

**Create Test Mission Structure**:
1. Small map area (for performance)
2. Basic units (player aircraft, test ground units)
3. Test zones defined
4. Minimal complexity for focused testing

**Test Script Template**:
```lua
-- Test script template
local TestSuite = {}

function TestSuite:RunAll()
    env.info("=== Starting Test Suite ===")
    
    self:TestTerritoryCreation()
    self:TestZoneDetection()
    self:TestFactoryManagement()
    
    env.info("=== Test Suite Complete ===")
end

function TestSuite:TestTerritoryCreation()
    env.info("Test: Territory Creation")
    -- Test code here
end

-- Run tests
TestSuite:RunAll()
```

### Automated Testing (Optional)

**Create Test Runner**:
```lua
-- Simple test framework
local TestFramework = {}

function TestFramework:Assert(condition, message)
    if not condition then
        env.error("TEST FAILED: " .. (message or "Assertion failed"))
        return false
    end
    return true
end

function TestFramework:RunTest(testName, testFunction)
    env.info("Running test: " .. testName)
    local success, result = pcall(testFunction)
    if success and result then
        env.info("Test PASSED: " .. testName)
    else
        env.error("Test FAILED: " .. testName)
    end
end
```

---

## Performance Optimization

### Best Practices

1. **Limit Active Objects**:
   - Don't spawn unlimited units
   - Clean up destroyed objects
   - Use object pooling where possible

2. **Efficient Zone Detection**:
   - Don't check zones every frame
   - Use scheduled checks (every 5-10 seconds)
   - Cache zone checks when possible

3. **Event Handler Management**:
   - Don't create excessive event handlers
   - Reuse handlers when possible
   - Clean up handlers when done

4. **Logging**:
   - Disable debug logging in production
   - Use appropriate log levels
   - Don't log in tight loops

**Example Optimized Code**:
```lua
-- Bad: Checks every frame
function Update()
    for _, territory in pairs(territories) do
        CheckTerritoryControl(territory)  -- Expensive operation
    end
end

-- Good: Scheduled checks
function Update()
    -- Only check every 5 seconds
    if timer % 300 == 0 then  -- 5 seconds at 60 FPS
        for _, territory in pairs(territories) do
            CheckTerritoryControl(territory)
        end
    end
end
```

---

## Troubleshooting

### Common Issues

**MOOSE Not Loading**:
- Check file path is correct
- Verify MOOSE files are in mission
- Check DCS log for errors
- Ensure MOOSE.lua is loaded first

**Scripts Not Executing**:
- Verify scripts are in mission file
- Check Init.lua is loading scripts
- Look for syntax errors in log
- Verify script execution order

**Performance Issues**:
- Check for infinite loops
- Verify object cleanup
- Monitor unit count
- Check zone detection frequency

**MOOSE Objects Not Working**:
- Verify MOOSE is loaded before using classes
- Check object creation syntax
- Verify object references are maintained
- Check MOOSE documentation for correct usage

### Debug Checklist

- [ ] MOOSE loaded successfully (check log)
- [ ] Scripts loaded in correct order
- [ ] No syntax errors in log
- [ ] Objects created correctly
- [ ] Event handlers registered
- [ ] Zone definitions correct
- [ ] Unit names match templates
- [ ] File paths are correct

---

## Resources and Documentation

### Essential Links

1. **MOOSE Framework**:
   - GitHub: https://github.com/FlightControl-Master/MOOSE
   - Documentation: https://flightcontrol-master.github.io/MOOSE/
   - Releases: https://github.com/FlightControl-Master/MOOSE/releases

2. **DCS Scripting**:
   - Wiki: https://wiki.hoggitworld.com/view/Scripting_Engine_Introduction
   - Forums: https://forums.eagle.ru/

3. **Lua Documentation**:
   - Lua 5.1 Manual: https://www.lua.org/manual/5.1/
   - Lua Reference: https://www.lua.org/docs.html

### Learning Resources

1. **MOOSE Tutorials**:
   - YouTube: Search "MOOSE DCS tutorial"
   - Community examples in MOOSE repository
   - MOOSE documentation examples

2. **DCS Mission Editing**:
   - Official DCS documentation
   - Community tutorials
   - Example missions

3. **Lua Programming**:
   - "Programming in Lua" book
   - Online Lua tutorials
   - Lua reference guides

---

## Version Control Best Practices

### Git Workflow

**Branch Strategy**:
```
main                    # Stable, tested code
├── develop             # Development branch
│   ├── feature/territory-system
│   ├── feature/factory-system
│   └── bugfix/zone-detection
└── release/v1.0        # Release branches
```

**Commit Messages**:
```
feat: Add territory capture system
fix: Resolve zone detection issue
docs: Update API documentation
test: Add factory destruction tests
refactor: Optimize territory control calculation
```

**Regular Commits**:
- Commit working code frequently
- Don't commit broken code to main
- Use feature branches for new work
- Tag releases

---

## Maintenance and Updates

### Keeping MOOSE Updated

1. **Check for Updates**:
   - Monitor MOOSE GitHub releases
   - Check DCS forums for announcements
   - Subscribe to MOOSE updates

2. **Update Process**:
   - Backup current MOOSE version
   - Download new version
   - Test with existing missions
   - Update if compatible

3. **Version Compatibility**:
   - Document MOOSE version used
   - Test after updates
   - Keep changelog of MOOSE versions

### Project Maintenance

1. **Regular Backups**:
   - Commit to Git regularly
   - Backup mission files
   - Keep documentation updated

2. **Code Review**:
   - Review own code before committing
   - Get feedback from community
   - Refactor as needed

3. **Documentation**:
   - Keep code commented
   - Update documentation with changes
   - Maintain API reference

---

## Quick Start Checklist

Use this checklist to set up your development environment:

- [ ] DCS World installed and running
- [ ] MOOSE framework downloaded
- [ ] Development folder structure created
- [ ] VS Code installed with Lua extension
- [ ] Test mission created
- [ ] MOOSE loaded in test mission
- [ ] Simple test script working
- [ ] Git repository initialized (optional)
- [ ] Documentation reviewed
- [ ] Ready to start development!

---

## Next Steps

After completing this setup:

1. Review the **TERRITORIAL_CONQUEST_PLAN.md** document
2. Start with Phase 1: Foundation & Territory System
3. Create your first territory zone
4. Test zone detection
5. Begin iterative development

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Status**: Setup Guide

