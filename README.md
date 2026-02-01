# DCS Mission – MOOSE

Minimal project for DCS World missions using the [MOOSE](https://github.com/FlightControl-Master/MOOSE) framework. Nations at War mission logic is loaded via `Scripts/nationsatwar/Loader.lua`.

## Structure

```
nationsatwar/
  Scripts/
    Init.lua           # Loads MOOSE, then nationsatwar/Loader.lua
    nationsatwar/      # Nations at War scripts (Loader.lua, Config, Zones, SpawnHelper, Init)
    MOOSE/             # MOOSE framework (install via Tools)
  Missions/         # Missions folder – put .miz files here
    Development/    # Development/test missions
  Tools/            # MOOSE install/verify scripts
```

## Quick start

1. **Install MOOSE** (from repo root):
   ```powershell
   cd Tools
   .\install_moose.ps1
   ```
   Or run `install_moose_manual.bat` for manual steps. Use `verify_moose.bat` to check the install.

2. **Set script path**: edit `Scripts/Init.lua` and set `scriptPath` to the full path to your `Scripts` folder (see SETUP_AND_TEST.md).

3. **Create a mission** in the DCS Mission Editor and save it under `Missions/Development/`.

4. **Add the loader** to the mission: trigger MISSION START → DO SCRIPT FILE → `Scripts/Init.lua`. To change Nations at War behavior, edit files under `Scripts/nationsatwar/` (only `Init.lua` in the mission needs to point at the repo).

## Requirements

- DCS World
- MOOSE in `Scripts/MOOSE/` (same layout as the official MOOSE repo after extraction)

## Notes

- `Init.lua` must use the full path to your `Scripts` folder in `scriptPath`; see SETUP_AND_TEST.md.
- MOOSE is not included in the repo; install it with the Tools scripts or by copying MOOSE into `Scripts/MOOSE/`.
