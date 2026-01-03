# DCS Territorial Conquest System - Implementation Plan

## Overview

This document outlines the plan for implementing a Territorial Conquest game mode in DCS World, similar to Fighter Ace's system, using the MOOSE (Mission Object-Oriented Scripting Environment) framework.

### Goals
- Create a persistent territorial control system
- Implement dynamic tank column spawning (attacking/defending)
- Manage factory/strategic asset capture and control
- Provide player-driven strategic gameplay
- Support both PvP and PvE scenarios

---

## System Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────┐
│           Territorial Conquest Controller               │
│                  (Main Lua Script)                      │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼──────┐  ┌───────▼──────┐  ┌──────▼──────┐
│   Territory  │  │   Factory    │  │   Ground    │
│   Manager    │  │   Manager    │  │   Unit      │
│              │  │              │  │   Manager   │
└──────────────┘  └──────────────┘  └─────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼──────┐  ┌───────▼──────┐  ┌──────▼──────┐
│   Trigger    │  │   State      │  │   Player    │
│   System     │  │   Persistence│  │   Interface │
└──────────────┘  └──────────────┘  └─────────────┘
```

---

## MOOSE Classes to Utilize

### Primary Classes

1. **ZONE** - Territory boundaries and detection
   - Define circular/polygonal zones for territories
   - Monitor unit presence within zones
   - Calculate control percentages

2. **SPAWN** - Dynamic unit spawning
   - Spawn tank columns on demand
   - Create reinforcement units
   - Manage spawn templates

3. **GROUP** - Unit group management
   - Track tank column groups
   - Monitor unit health and status
   - Control group waypoints and tasks

4. **EVENT** - Event handling
   - Detect unit destruction
   - Monitor player actions
   - Trigger responses to game events

5. **COORDINATE** - Navigation and routing
   - Calculate tank column routes
   - Determine distances and bearings
   - Create waypoint paths

6. **SET** - Unit collections
   - Manage all factories
   - Track all territories
   - Organize units by type/territory

### Optional MOOSE Modules

- **CTLD** - Logistics and troop deployment (if needed)
- **MANTIS** - Air defense systems for territory defense
- **CSAR** - Downed pilot rescue (immersion enhancement)

---

## Core Components Design

### 1. Territory Manager

**Purpose**: Manage territory definitions, ownership, and control status

**Data Structure**:
```lua
Territory = {
    name = "Territory_Alpha",
    zone = ZONE object,
    owner = "Red" or "Blue" or "Neutral",
    factories = {factory1, factory2, ...},
    strategic_value = 100,
    control_percentage = 0.0,  -- 0.0 to 1.0
    is_contested = false,
    last_activity_time = 0
}
```

**Key Functions**:
- `CreateTerritory(name, zone, initial_owner)` - Initialize territory
- `CheckTerritoryControl(territory)` - Calculate current control status
- `ChangeTerritoryOwnership(territory, new_owner)` - Update ownership
- `IsTerritoryContested(territory)` - Check if actively being fought over
- `GetTerritoryUnits(territory)` - Get all units in territory

**MOOSE Usage**:
- Use `ZONE` class for territory boundaries
- Use `ZONE:IsUnitInZone()` to check unit presence
- Use `SET_GROUP` to track units within zones

---

### 2. Factory Manager

**Purpose**: Manage strategic assets (factories, airfields, supply depots)

**Data Structure**:
```lua
Factory = {
    name = "Factory_Alpha",
    group = GROUP object,
    territory = Territory reference,
    health_percentage = 100.0,
    is_operational = true,
    production_rate = 10,  -- Resources per cycle
    owner = "Red" or "Blue",
    position = COORDINATE object
}
```

**Key Functions**:
- `CreateFactory(name, position, territory, owner)` - Initialize factory
- `DamageFactory(factory, damage_amount)` - Apply damage
- `DestroyFactory(factory)` - Mark as destroyed
- `RepairFactory(factory)` - Restore factory (if implemented)
- `GetFactoryProduction(factory)` - Calculate resource generation

**MOOSE Usage**:
- Use `GROUP` class to track factory units
- Use `EVENT` handlers to detect factory destruction
- Use `COORDINATE` for factory positions

---

### 3. Ground Unit Manager

**Purpose**: Manage tank columns and ground unit spawning

**Data Structure**:
```lua
TankColumn = {
    id = unique_id,
    spawn_template = SPAWN template,
    group = GROUP object,
    type = "Attacking" or "Defending",
    origin_territory = Territory reference,
    target_territory = Territory reference,
    route = {waypoint1, waypoint2, ...},
    health_percentage = 100.0,
    units_alive = 0,
    status = "Spawning" or "Moving" or "Engaged" or "Destroyed" or "Arrived"
}
```

**Key Functions**:
- `SpawnTankColumn(type, origin, target, template)` - Create new column
- `UpdateColumnStatus(column)` - Check column health and progress
- `DestroyColumn(column)` - Clean up destroyed column
- `CalculateColumnEffectiveness(column)` - Determine impact on territory
- `GetColumnRoute(origin, target)` - Calculate movement path

**MOOSE Usage**:
- Use `SPAWN` class to create tank columns dynamically
- Use `GROUP` class to manage column units
- Use `COORDINATE` to calculate routes
- Use `EVENT` handlers to track unit destruction

---

### 4. Trigger System

**Purpose**: Handle all trigger conditions for tank column spawning

**Trigger Types**:

#### Attacking Tank Column Triggers

1. **Player-Initiated Attack**
   - Condition: Player command via F10 menu or radio
   - Action: Spawn attacking column from friendly territory to target

2. **Territory Capture Momentum**
   - Condition: Factory captured or strategic point secured
   - Action: Spawn attacking column to push into adjacent enemy territory

3. **Proximity-Based**
   - Condition: Friendly forces detected near enemy territory border
   - Action: Spawn supporting attacking column

4. **Mission-Based**
   - Condition: Scripted campaign event or objective
   - Action: Spawn column as part of mission narrative

#### Defending Tank Column Triggers

1. **Enemy Attack Detection**
   - Condition: Enemy aircraft/units detected approaching friendly territory
   - Action: Spawn defensive column to intercept

2. **Territory Under Threat**
   - Condition: Enemy forces within X km of friendly territory
   - Action: Spawn defensive column at strategic location

3. **Player-Requested Reinforcements**
   - Condition: Player calls for reinforcements via interface
   - Action: Spawn defensive column if resources available

4. **Factory Under Attack**
   - Condition: Factory taking damage or enemy units near factory
   - Action: Spawn defensive column to protect factory

**MOOSE Usage**:
- Use `EVENT` handlers for player actions and unit events
- Use `ZONE` detection for proximity triggers
- Use `GROUP` monitoring for threat detection
- Use scheduled functions for periodic checks

---

### 5. State Persistence

**Purpose**: Save and load campaign state across sessions

**Data to Persist**:
- Territory ownership
- Factory health and status
- Active tank columns and their positions
- Resource levels
- Campaign progress

**Implementation Options**:
1. **File-Based (JSON/Lua tables)**
   - Simple implementation
   - Easy to edit manually
   - Good for testing

2. **Database (SQLite)**
   - More robust for complex data
   - Better query capabilities
   - Requires external library

3. **MOOSE Built-in Persistence**
   - Check if MOOSE has persistence utilities
   - May need custom implementation

**Key Functions**:
- `SaveCampaignState()` - Write current state to file/DB
- `LoadCampaignState()` - Restore state on mission start
- `ResetCampaignState()` - Admin function to reset campaign

---

### 6. Player Interface

**Purpose**: Provide players with information and controls

**F10 Radio Menu Options**:
- "Request Attacking Tank Column" → Select target territory
- "Request Defensive Reinforcements" → Select territory to defend
- "Check Territory Status" → Display territory information
- "View Campaign Map" → Show territory control overview

**F10 Map Markers**:
- Territory boundaries (colored by ownership)
- Factory locations (with health indicators)
- Active tank columns (with movement arrows)
- Strategic objectives

**Briefing/Status Screen**:
- Territory control map
- Resource levels
- Active operations
- Campaign objectives

**MOOSE Usage**:
- Use DCS built-in F10 menu system
- Use `COORDINATE` for map marker placement
- Use `ZONE` information for status displays

---

## Implementation Phases

### Phase 1: Foundation & Territory System
**Duration**: 2-3 weeks

**Tasks**:
1. Set up MOOSE framework in mission
2. Create territory zone definitions (3-5 test territories)
3. Implement basic territory detection (unit presence in zones)
4. Create territory ownership tracking
5. Visual representation on F10 map
6. Basic territory control calculation

**Deliverables**:
- Working territory zones
- Ownership tracking system
- Visual feedback on map

**Testing**:
- Verify zones detect units correctly
- Test ownership changes
- Confirm visual markers update

---

### Phase 2: Factory/Asset System
**Duration**: 2-3 weeks

**Tasks**:
1. Place factory units in mission editor
2. Link factories to territories
3. Implement factory health tracking
4. Create factory destruction detection
5. Link factory status to territory control
6. Visual indicators for factory health

**Deliverables**:
- Factory management system
- Health tracking
- Destruction detection
- Territory-factory linkage

**Testing**:
- Destroy factories and verify detection
- Test territory control impact
- Verify visual updates

---

### Phase 3: Basic Tank Column System
**Duration**: 3-4 weeks

**Tasks**:
1. Create tank column spawn templates
2. Implement basic spawning system
3. Create waypoint routing system
4. Implement column health tracking
5. Basic column status monitoring
6. Column cleanup on destruction/arrival

**Deliverables**:
- Working tank column spawning
- Movement system
- Health tracking
- Status monitoring

**Testing**:
- Spawn columns manually
- Verify movement along routes
- Test destruction detection
- Confirm cleanup works

---

### Phase 4: Trigger System Implementation
**Duration**: 3-4 weeks

**Tasks**:
1. Implement player-initiated triggers (F10 menu)
2. Create automatic threat detection
3. Implement proximity-based triggers
4. Create factory capture triggers
5. Implement defensive response system
6. Add resource/cooldown management

**Deliverables**:
- Complete trigger system
- Player interface
- Automatic responses
- Resource management

**Testing**:
- Test all trigger types
- Verify automatic responses
- Test resource limits
- Confirm cooldowns work

---

### Phase 5: Territory Capture Flow
**Duration**: 2-3 weeks

**Tasks**:
1. Implement damage accumulation system
2. Create capture threshold logic
3. Implement ownership transfer
4. Create capture events and notifications
5. Link factory destruction to capture
6. Implement capture cooldowns

**Deliverables**:
- Complete capture system
- Ownership transfer
- Event notifications
- Capture mechanics

**Testing**:
- Test full capture flow
- Verify threshold calculations
- Test ownership changes
- Confirm event triggers

---

### Phase 6: Persistence & Polish
**Duration**: 2-3 weeks

**Tasks**:
1. Implement state saving system
2. Create state loading on mission start
3. Add admin tools (reset, adjust resources)
4. Performance optimization
5. UI/UX improvements
6. Documentation

**Deliverables**:
- Persistent campaign state
- Admin tools
- Optimized performance
- User documentation

**Testing**:
- Test save/load cycle
- Verify state persistence
- Test admin functions
- Performance testing

---

## Technical Details

### Territory Control Calculation

**Algorithm**:
```
For each territory:
    1. Count friendly units in zone
    2. Count enemy units in zone
    3. Calculate control percentage:
       control = (friendly_units / (friendly_units + enemy_units))
    4. If control > 0.7 and no enemy units: Territory captured
    5. If control < 0.3 and no friendly units: Territory lost
```

**MOOSE Implementation**:
- Use `ZONE:IsUnitInZone()` for each unit
- Use `SET_GROUP` to filter units by coalition
- Calculate ratios and update territory status

---

### Tank Column Routing

**Algorithm**:
```
1. Get origin territory center
2. Get target territory center
3. Calculate direct route
4. Check for obstacles (mountains, enemy territory)
5. Create waypoints along route
6. Assign waypoints to spawned group
```

**MOOSE Implementation**:
- Use `COORDINATE` to get positions
- Use `COORDINATE:GetDirectionTo()` for routing
- Use `GROUP:RouteGroundTo()` for waypoint assignment

---

### Factory Damage System

**Algorithm**:
```
1. Monitor factory group health
2. On unit destroyed in factory group:
   - Calculate damage percentage
   - Update factory health
   - If health < threshold: Mark as destroyed
   - Update territory control impact
```

**MOOSE Implementation**:
- Use `EVENT` handlers for unit destroyed
- Use `GROUP:GetSize()` and `GROUP:GetUnits()` for health calculation
- Link to territory control system

---

## Data Structures Summary

### Global State
```lua
TerritorialConquest = {
    territories = {},      -- Table of Territory objects
    factories = {},         -- Table of Factory objects
    tank_columns = {},      -- Table of TankColumn objects
    resources = {
        red = 1000,
        blue = 1000
    },
    campaign_state = "active",
    last_save_time = 0
}
```

### Territory Object
```lua
{
    name = string,
    zone = ZONE,
    owner = string,
    factories = table,
    strategic_value = number,
    control_percentage = number,
    is_contested = boolean,
    units_inside = SET_GROUP
}
```

### Factory Object
```lua
{
    name = string,
    group = GROUP,
    territory = Territory,
    health_percentage = number,
    is_operational = boolean,
    production_rate = number,
    owner = string,
    position = COORDINATE
}
```

### Tank Column Object
```lua
{
    id = string,
    spawn_template = SPAWN,
    group = GROUP,
    type = string,
    origin_territory = Territory,
    target_territory = Territory,
    route = table,
    health_percentage = number,
    status = string,
    spawn_time = number
}
```

---

## Testing Strategy

### Unit Testing
- Test each component in isolation
- Verify MOOSE class usage
- Test edge cases

### Integration Testing
- Test component interactions
- Verify trigger chains
- Test state persistence

### Gameplay Testing
- Test with small player groups (2-4 players)
- Verify balance and pacing
- Test all trigger conditions
- Verify persistence across restarts

### Performance Testing
- Monitor FPS with multiple territories
- Test with many active tank columns
- Verify cleanup of destroyed units
- Test zone detection performance

---

## Configuration Options

### Mission Designer Settings
```lua
Config = {
    -- Territory Settings
    territory_capture_threshold = 0.7,  -- Control % needed to capture
    territory_loss_threshold = 0.3,     -- Control % to lose territory
    
    -- Factory Settings
    factory_destruction_threshold = 0.2, -- Health % to be destroyed
    factory_production_interval = 300,  -- Seconds between production
    
    -- Tank Column Settings
    tank_column_spawn_cooldown = 600,   -- Seconds between spawns
    tank_column_max_active = 5,         -- Max columns per side
    tank_column_health_threshold = 0.3,  -- % health to be ineffective
    
    -- Resource Settings
    resource_initial = 1000,            -- Starting resources
    resource_max = 5000,                 -- Maximum resources
    attacking_column_cost = 100,        -- Cost to spawn attacking column
    defending_column_cost = 75,         -- Cost to spawn defending column
    
    -- Detection Settings
    threat_detection_range = 50000,     -- Meters to detect threats
    proximity_trigger_range = 30000,    -- Meters for proximity triggers
    
    -- Persistence Settings
    auto_save_interval = 300,           -- Seconds between auto-saves
    persistence_enabled = true          -- Enable state saving
}
```

---

## Future Enhancements

### Phase 7+ (Optional)
- Air support missions (CAS for tank columns)
- Supply line mechanics
- Resource production from factories
- Advanced AI coordination
- Multi-map campaigns
- Web-based campaign management interface
- Statistics and leaderboards
- Dynamic weather affecting operations
- Night/day cycle affecting visibility
- Integration with other MOOSE modules (MANTIS, CTLD)

---

## File Structure

```
mission/
├── Scripts/
│   ├── MOOSE/
│   │   └── (MOOSE framework files)
│   ├── TerritorialConquest/
│   │   ├── Main.lua                    -- Main controller
│   │   ├── TerritoryManager.lua        -- Territory system
│   │   ├── FactoryManager.lua          -- Factory system
│   │   ├── GroundUnitManager.lua       -- Tank column system
│   │   ├── TriggerSystem.lua           -- Trigger handling
│   │   ├── StatePersistence.lua        -- Save/load system
│   │   ├── PlayerInterface.lua         -- F10 menu and UI
│   │   ├── Config.lua                  -- Configuration
│   │   └── Utils.lua                   -- Helper functions
│   └── Init.lua                        -- Mission initialization
└── (mission .miz file)
```

---

## Dependencies

### Required
- DCS World (latest stable version)
- MOOSE Framework (latest release)
- Mission Editor access

### Optional
- MIST (Mission Scripting Tools) - Additional utilities
- External persistence library (if using database)

---

## Success Criteria

### Phase 1 Success
- ✅ Territories defined and visible
- ✅ Ownership tracking works
- ✅ Zone detection functional

### Phase 2 Success
- ✅ Factories linked to territories
- ✅ Health tracking works
- ✅ Destruction detection functional

### Phase 3 Success
- ✅ Tank columns spawn correctly
- ✅ Movement along routes works
- ✅ Health tracking functional

### Phase 4 Success
- ✅ All trigger types work
- ✅ Player interface functional
- ✅ Automatic responses trigger correctly

### Phase 5 Success
- ✅ Complete capture flow works
- ✅ Ownership transfers correctly
- ✅ Events trigger appropriately

### Phase 6 Success
- ✅ State persists across restarts
- ✅ Performance is acceptable
- ✅ System is playable and balanced

---

## Notes

- Start with a small test map (2-3 territories) for initial development
- Test each phase thoroughly before moving to next
- Keep MOOSE documentation handy for reference
- Consider creating a test mission specifically for development
- Document any custom modifications to standard MOOSE usage
- Plan for server restart handling (state persistence critical)

---

## Resources

- MOOSE Documentation: https://flightcontrol-master.github.io/MOOSE/
- MOOSE GitHub: https://github.com/FlightControl-Master/MOOSE
- DCS Scripting Documentation: https://wiki.hoggitworld.com/view/Scripting_Engine_Introduction
- DCS Forums: https://forums.eagle.ru/

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Status**: Planning Phase

