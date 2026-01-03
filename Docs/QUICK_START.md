# Quick Start Guide

## 5-Minute Setup

### 1. Install MOOSE (2 minutes)

```powershell
# Download MOOSE from GitHub
# Extract to: D:\CardinalCollective\perforce\nationsatwar\Scripts\MOOSE\
# Verify: Scripts\MOOSE\MOOSE.lua exists
```

### 2. Create Test Mission (2 minutes)

1. Open DCS Mission Editor
2. Create new mission on Caucasus
3. Place ONE factory:
   - Static Object → Factory
   - Name: `Factory_Alpha`
   - Position: Lat 42.0, Lon 41.5
   - Coalition: Red
4. Save as `Missions/Development/Test.miz`

### 3. Add Scripts (1 minute)

1. Extract `.miz` file (it's a ZIP)
2. Copy `Scripts/` folder into extracted mission
3. Re-zip and rename to `.miz`

### 4. Test (30 seconds)

1. Load mission in DCS
2. Check log: Should see "MOOSE Framework loaded successfully"
3. Press F10 → Should see "Territorial Conquest" menu

## Next Steps

- Add more factories (see `Config.lua`)
- Create tank column templates
- Define territories
- See `SETUP_INSTRUCTIONS.md` for details

## Troubleshooting

**MOOSE not found?**
- Check path in `Scripts/Init.lua`
- Verify MOOSE files exist

**Factory not found?**
- Check factory name matches exactly
- Must be group name, not unit name

**Scripts not running?**
- Check `Init.lua` is loaded in mission
- Check DCS log for errors

