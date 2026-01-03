# How to Add Scripts to DCS Mission

## Method 1: Using Mission Editor (Recommended for Development)

### Step-by-Step Instructions

1. **Open Your Mission in DCS Mission Editor**
   - Launch DCS World
   - Open Mission Editor
   - Load or create your mission

2. **Navigate to Triggers**
   - Click on the **"Triggers"** tab at the top
   - You'll see trigger groups on the left side

3. **Create or Use Mission Start Trigger**
   - Look for a trigger named **"Mission Start"** (or create one)
   - If it doesn't exist:
     - Right-click in the triggers area
     - Select **"Add Trigger"**
     - Name it "Mission Start"
     - Set condition to **"ONCE"** → **"TIME MORE"** → **"1"** (1 second)

4. **Add Script Action**
   - Select the "Mission Start" trigger
   - In the **Actions** section (right side), click **"Add Action"**
   - Select **"DO SCRIPT FILE"**
   - Click the folder icon to browse for your script

5. **Select Init.lua**
   - Navigate to: `D:\CardinalCollective\perforce\nationsatwar\Scripts\Init.lua`
   - Select the file
   - The path will be added to the action

6. **Save Mission**
   - Save your mission
   - The script will now load when the mission starts

### Visual Guide

```
Mission Editor → Triggers Tab
├── Mission Start (Trigger)
    └── Actions
        └── DO SCRIPT FILE
            └── D:\CardinalCollective\perforce\nationsatwar\Scripts\Init.lua
```

---

## Method 2: Extract and Repack Mission File (Alternative)

If you prefer to work directly with files:

### Step 1: Extract Mission File

1. **Locate your mission file**
   - Mission files are `.miz` files (they're actually ZIP archives)
   - Example: `Missions/Development/Test.miz`

2. **Extract the mission**
   - Rename `.miz` to `.zip` (or use extraction tool)
   - Extract to a folder (e.g., `Missions/Development/Test/`)

### Step 2: Copy Scripts

1. **Copy Scripts folder**
   - Copy the entire `Scripts` folder from `D:\CardinalCollective\perforce\nationsatwar\Scripts\`
   - Paste it into the extracted mission folder
   - Structure should be:
     ```
     Test/
     ├── mission
     ├── options
     └── Scripts/
         ├── Init.lua
         ├── MOOSE/
         └── TerritorialConquest/
     ```

### Step 3: Repack Mission

1. **Zip the folder**
   - Select all files in the extracted folder
   - Create a ZIP archive
   - Rename `.zip` to `.miz`

2. **Load in DCS**
   - The mission will now have all scripts included
   - Scripts will load automatically

---

## Method 3: Using Mission Editor Script Path (Advanced)

### Direct Script Loading

1. **In Mission Editor**
   - Go to **Triggers** → **Mission Start**
   - Add action: **"DO SCRIPT FILE"**
   - Enter path: `Scripts\Init.lua`
   - Note: This path is relative to the mission file location

2. **Ensure Scripts are in Mission**
   - Scripts must be inside the `.miz` file
   - Use Method 2 to embed scripts, or
   - DCS will look in `Saved Games\DCS\Scripts\` if not found in mission

---

## Verification

### Check if Scripts Load

1. **Load mission in DCS**
2. **Check DCS log file**
   - Location: `C:\Users\[YourName]\Saved Games\DCS\Logs\dcs.log`
   - Open the log file
   - Look for:
     - `"MOOSE Framework loaded successfully (Dynamic)"`
     - `"Territorial Conquest Mission - Initializing"`
     - `"Territorial Conquest system initialized successfully"`

3. **In-Game Check**
   - Press **F10** (Map view)
   - You should see **"Territorial Conquest"** menu option
   - This confirms scripts loaded

### Common Issues

**Scripts not loading?**
- Check file path is correct
- Verify `Init.lua` exists at the specified path
- Check DCS log for error messages
- Ensure MOOSE is installed in `Scripts/MOOSE/`

**MOOSE not found?**
- Verify MOOSE installation: `Tools\verify_moose.bat`
- Check `Scripts/MOOSE/Moose Development/Moose/Modules.lua` exists
- Reinstall MOOSE if needed: `Tools\install_moose.ps1`

**Mission won't load?**
- Check for syntax errors in scripts
- Verify all script files are present
- Check DCS log for specific error messages

---

## Quick Reference

### File Paths

- **Scripts location**: `D:\CardinalCollective\perforce\nationsatwar\Scripts\`
- **Init script**: `D:\CardinalCollective\perforce\nationsatwar\Scripts\Init.lua`
- **Mission files**: `D:\CardinalCollective\perforce\nationsatwar\Missions\Development\`
- **DCS log**: `C:\Users\[YourName]\Saved Games\DCS\Logs\dcs.log`

### Tools

- **Verify MOOSE**: `Tools\verify_moose.bat`

---

## Recommended Workflow

For development, I recommend **Method 1** (Mission Editor):
- Easy to update scripts
- No need to repack mission each time
- Scripts load from your development folder
- Faster iteration

For distribution, use **Method 2** (Extract/Repack):
- Scripts embedded in mission
- Mission is self-contained
- No external dependencies
- Better for sharing

---

## Next Steps

After adding scripts:
1. ✅ Scripts added to mission
2. ⏳ Place factories in Mission Editor (see `SETUP_INSTRUCTIONS.md`)
3. ⏳ Create tank column templates
4. ⏳ Configure territories in `Config.lua`
5. ⏳ Test the mission

