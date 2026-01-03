# Territorial Conquest Mission Setup Instructions

## Prerequisites

1. DCS World installed and running
2. MOOSE framework downloaded
3. Mission Editor access

## Step 1: Install MOOSE

1. Download MOOSE from: https://github.com/FlightControl-Master/MOOSE
2. Extract MOOSE to: `Scripts/MOOSE/`
3. Verify structure: `Scripts/MOOSE/MOOSE.lua` exists

## Step 2: Create Base Mission

1. Open DCS Mission Editor
2. Create new mission on Caucasus map (or your preferred map)
3. Set mission date/time/weather
4. Set up Red and Blue coalitions
5. Save mission as `Territorial_Conquest.miz` in `Missions/Development/`

## Step 3: Place Factories

For each factory defined in `Config.lua`:

1. In Mission Editor, select **Static Objects**
2. Choose **Factory** category
3. Place factory at coordinates specified in config
4. **IMPORTANT**: Name the factory group exactly as specified:
   - Example: `Factory_Alpha`
   - Must match `TerritorialConquestConfig.Names.factories`

### Factory Placement Example

```
Factory_Alpha:
- Coordinates: Lat 42.0, Lon 41.5
- Name: "Factory_Alpha"
- Coalition: Red
- Country: Russia
```

## Step 4: Create Tank Column Templates

1. In Mission Editor, create a ground unit group
2. Add units:
   - 4x T-72B (or your preferred tanks)
   - 2x BMP-2 (or APCs)
   - 1x ZSU-23-4 Shilka (or AA)
3. **IMPORTANT**: Name the group exactly:
   - Attacking: `Tank_Column_Template_Attacking`
   - Defending: `Tank_Column_Template_Defending`
4. Position template off-map or hidden (it's just a template)
5. Set coalition and country

## Step 5: Add Scripts to Mission

### Option A: Direct Script Loading

1. Extract `.miz` file (it's a ZIP)
2. Copy all files from `Scripts/` to extracted mission's `Scripts/` folder
3. Re-zip and rename to `.miz`

### Option B: Mission Editor Script Loading

1. In Mission Editor, go to **Triggers** → **Mission Start**
2. Add **DO SCRIPT FILE** action
3. Point to: `Scripts/Init.lua`
4. Save mission

## Step 6: Configure Territories

Edit `Scripts/TerritorialConquest/Config.lua`:

1. Update `Territories` table with your territory definitions
2. Set coordinates and radii
3. Link factories to territories
4. Set initial owners

## Step 7: Test Mission

1. Load mission in DCS
2. Check DCS log file for errors
3. Verify MOOSE loads: Look for "MOOSE Framework loaded successfully"
4. Verify system initializes: Look for "Territorial Conquest system initialized"
5. Test F10 menu: Should see "Territorial Conquest" menu

## Troubleshooting

### MOOSE Not Loading
- Check file path in `Init.lua`
- Verify MOOSE files are in correct location
- Check DCS log for path errors

### Factories Not Found
- Verify factory names match exactly (case-sensitive)
- Check factory groups are named, not just units
- Verify factories are placed in mission

### Scripts Not Running
- Check `Init.lua` is loaded in mission
- Verify script paths are correct
- Check DCS log for Lua errors

## Next Steps

See `TERRITORIAL_CONQUEST_PLAN.md` for development roadmap.

