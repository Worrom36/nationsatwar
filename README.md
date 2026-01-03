# DCS Territorial Conquest Mission

A dynamic territorial control mission for DCS World using the MOOSE framework.

## Project Structure

```
DCS/
├── Scripts/                    # All Lua scripts
│   ├── MOOSE/                 # MOOSE framework (link or copy)
│   └── TerritorialConquest/   # Mission-specific scripts
├── Missions/                   # Mission files (.miz)
│   └── Development/           # Development/test missions
├── Docs/                       # Documentation
└── Tools/                      # Development tools
```

## Quick Start

1. **Setup MOOSE**: Run `Tools\install_moose.ps1` to automatically download and install MOOSE
   - Or use `Tools\install_moose_manual.bat` for manual installation
   - Verify installation with `Tools\verify_moose.bat`
2. **Create Mission**: Use DCS Mission Editor to create base mission
3. **Load Scripts**: Add scripts to mission file
4. **Configure**: Edit `Scripts\TerritorialConquest\Config.lua`
5. **Test**: Load mission in DCS and test

## Development

See `Docs/` for detailed documentation:
- `TERRITORIAL_CONQUEST_PLAN.md` - Complete system design
- `MOOSE_DEV_ENVIRONMENT_SETUP.md` - Development setup guide
- `DCS_MISSION_EDITOR_REQUIREMENTS.md` - Editor requirements
- `INSTALLATION_STATUS.md` - Current installation and system status
- `DEVELOPMENT_CHECKLIST.md` - Development progress tracking
- `HOW_TO_ADD_SCRIPTS_TO_MISSION.md` - Script integration guide
- `QUICK_START.md` - Quick start guide
- `SETUP_INSTRUCTIONS.md` - Detailed setup instructions

## Status

✅ **Phase 1 Complete** - Foundation & Territory System Operational

### Current Features
- ✅ MOOSE framework integration
- ✅ Territory management system (2 territories configured)
- ✅ Factory management (3 factories registered and working)
- ✅ Ground unit (tank column) spawning system
- ✅ Event handling system
- ✅ Player interface framework
- ✅ State persistence framework
- ✅ In-game status messages with system diagnostics
- ✅ Comprehensive error handling
- ✅ Late-activated group detection and listing

### Mission Editor Integration
- ✅ Factories placed: Factory_Alpha, Factory_Bravo, Factory_Charlie
- ✅ Tank templates: Tank_Column_Template_Attacking, Tank_Column_Template_Defending
  - Automatic registration for late-activated groups working

### Next Steps
- Implement territory capture logic
- Add player commands and F10 menus
- Test tank column spawning and movement
- Test full gameplay loop

