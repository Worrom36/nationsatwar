# Setup and test – step by step

Follow these steps to install MOOSE, hook it into a mission, and confirm it loads.

---

## 1. Prerequisites

- **DCS World** installed and runnable.
- This repo cloned or unpacked (e.g. `nationsatwar`).
- **PowerShell** (for the MOOSE installer), or use the manual install option.

---

## 2. Install MOOSE

1. Open a terminal (PowerShell or Command Prompt).
2. Go to the repo root (the folder that contains `Scripts`, `Tools`, `Missions`):
   ```text
   cd D:\CardinalCollective\perforce\nationsatwar
   ```
   (Use your actual path.)
3. Run the MOOSE installer:
   ```powershell
   cd Tools
   .\install_moose.ps1
   ```
4. Wait for the script to download and extract MOOSE. It installs into `Scripts\MOOSE\`.
5. Optional: verify the install:
   ```batch
   verify_moose.bat
   ```
   You should see that MOOSE files are present.

**If you don’t use PowerShell:** run `install_moose_manual.bat` and follow the on-screen steps to download and extract MOOSE into `Scripts\MOOSE\` yourself.

---

## 3. Point Init.lua at your Scripts folder

DCS runs scripts with a working directory that may not be your repo. Init.lua must use the **full path** to your `Scripts` folder.

1. Open `Scripts\Init.lua` in an editor.
2. Find the line that sets `scriptPath` (e.g. `local scriptPath = "D:\\...\\Scripts\\"`).
3. Set it to the full path to your `Scripts` folder, with a trailing backslash and escaped backslashes in Lua (`\\`):
   ```lua
   local scriptPath = "D:\\CardinalCollective\\perforce\\nationsatwar\\Scripts\\"
   ```
   Use your actual path so MOOSE and Nations at War load correctly.
4. Save the file.

---

## 4. Create a test mission in DCS

1. Start **DCS World** and open the **Mission Editor**.
2. **File → New** (or open an existing mission).
3. Choose a map (e.g. Caucasus) and create a minimal mission (e.g. one unit or nothing).
4. **File → Save As** and save the mission into the repo’s missions folder:
   ```text
   nationsatwar\Missions\Development\TestMOOSE.miz
   ```
   (Full path example: `D:\CardinalCollective\perforce\nationsatwar\Missions\Development\TestMOOSE.miz`.)

---

## 5. Add the script to run on mission start

1. In the Mission Editor, open the **Triggers** panel (right side or **Trigger** menu).
2. Create a new trigger:
   - **Type:** MISSION START (or “Once” with no condition).
   - **Action:** **DO SCRIPT FILE** (or “Do Script File”).
3. In the action’s file picker, browse to and select:
   ```text
   D:\CardinalCollective\perforce\nationsatwar\Scripts\Init.lua
   ```
   (Use your actual path.)
4. Save the mission again (**Ctrl+S**).

Now, when the mission starts, DCS will run `Init.lua`, which will load MOOSE.

---

## 6. Test in-game

1. In the Mission Editor, click **Fly** or **Mission** (or **Save** and then run the mission from the main menu).
2. Start the mission and get in-cockpit or in-game as usual.
3. Open the **DCS log** to see script messages:
   - **Saved Games\DCS\Logs\dcs.log** (or **DCS.openbeta\Logs\dcs.log** if you use Open Beta).
4. In `dcs.log`, search for:
   - `Mission Scripts - Initializing`
   - `MOOSE loaded successfully`
   - `Initialization Complete` (or Nations at War init / zone health messages)

If you see those lines, MOOSE is loading correctly.

**Nations at War:** Use the in-game **F10** menu: **Nations at War** → **Last messages** (recent log lines) and **Nations at War** → **Zones** → *[zone]* for Swap, Kill All, Respawn All, Spawn Counter, etc. Zone health (0–100) is shown as digits over each zone on the F10 map. To change behavior (zones, replenishment, reinforcements), edit `Scripts/nationsatwar/Config.lua`; see README.md for main options.

---

## 7. If MOOSE doesn’t load

- **“MOOSE load failed”** in the log:
  - Confirm `Scripts\MOOSE\` exists and contains the MOOSE folder structure (e.g. `Moose Setup`, `Moose Development`).
  - Confirm the path in Init.lua (`scriptPath`) is the **full path** to the folder that **contains** `MOOSE` (i.e. your `Scripts` folder), with `\\` and a trailing `\\`.
- **Script not running at all:**
  - Confirm the trigger is **MISSION START** (or equivalent) and the action is **DO SCRIPT FILE** pointing to your `Init.lua`.
  - Confirm the path in the trigger is correct and the file exists.

---

## Quick checklist

- [ ] MOOSE installed under `Scripts\MOOSE\` (via `Tools\install_moose.ps1` or manual).
- [ ] `Scripts\Init.lua` updated with full `scriptPath` to your `Scripts` folder.
- [ ] Mission saved (e.g. in `Missions\Development\`).
- [ ] Trigger: MISSION START → DO SCRIPT FILE → `Scripts\Init.lua`.
- [ ] Mission run; `dcs.log` shows “MOOSE loaded successfully” and “Initialization Complete" (or Nations at War init).
- [ ] F10 → Nations at War → Zones shows zone submenus; zone health digits visible on map.

After that, to change mission logic edit scripts under `Scripts\nationsatwar\`. Main tunables (zones, replenishment, reinforcements) are in `Config.lua`; see README.md. Add or reorder modules in `Loader.lua` as needed.
