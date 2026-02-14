# DCS Mission – MOOSE

Minimal project for DCS World missions using the [MOOSE](https://github.com/FlightControl-Master/MOOSE) framework. Nations at War mission logic is loaded via `Scripts/nationsatwar/Loader.lua`.

## Structure

```
nationsatwar/
  Scripts/
    Init.lua              # Loads MOOSE, then nationsatwar/Loader.lua
    nationsatwar/         # Nations at War scripts (loaded by Loader.lua in order):
      Config.lua          # Zone list, colors, health, replenish, etc.
      CapturableZones.lua # Zone ownership (red/blue)
      Zones.lua           # Zone lookup, coords, F10 circle draw, health queue
      RenderDigits.lua    # Seven-segment digit drawing (00–99) for zone health
      SpawnHelper.lua     # Delayed spawn at coords
      ZoneMovement.lua    # Kill handler, redistribution, health (A+B+C), 1 Hz update
      EventHandlers.lua   # Mission/event wiring
      ZoneCommands.lua    # F10 commands: Swap, Kill All, Respawn, Spawn Counter, Kill One, Kill Two Fast, Kill Half
      FactoryProduction.lua   # Factory tank production (TanksPerMinute, FactoryTankCap)
      FactoryReinforcements.lua  # Attacking reinforcements when zone health drops
      Init.lua            # F10 menu, zone init, spawn defenders, replenishment timers
    MOOSE/                # MOOSE framework (install via Tools)
  Missions/               # Missions folder – put .miz files here
    Development/          # Development/test missions
  Tools/                  # MOOSE install/verify scripts
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

5. **If you see** `Mission script error: [string "Scripts/World/EventHandlers.lua"]:13: attempt to index local 'handler' (a function value)`: the mission is still loading the old World script. In the Mission Editor, remove any trigger or script that loads `Scripts/World/EventHandlers.lua` (or `World/EventHandlers.lua`). Event handling is now in `Scripts/nationsatwar/EventHandlers.lua` and is loaded automatically by the Loader.

## Requirements

- DCS World
- MOOSE in `Scripts/MOOSE/` (same layout as the official MOOSE repo after extraction)

## F10 menu

- **Nations at War** → **Last messages** (recent log lines).
- **Nations at War** → **Zones** → *[zone name]*:
  - **Swap Zone** – flip zone owner (red/blue).
  - **Kill All** – destroy all defenders in the zone.
  - **Respawn All** – respawn defenders at ring/square positions.
  - **Spawn Counter** – spawn one opposing unit at center.
  - **Kill One** – kill one defender and redistribute.
  - **Kill Two Fast** – kill one defender, then a second 0.5 s later.
  - **Kill Half** – kill half of the zone’s defender groups and redistribute.

Zone health (0–100) is shown as two digits over each zone on the F10 map; updates are queued and redrawn after a short delay. Capture is by C-drain only: when only enemy units are in the zone, the last 30 “hitpoints” (C) drain at 1/sec; at 0 the zone is captured.

## Notes

- `Init.lua` must use the full path to your `Scripts` folder in `scriptPath`; see SETUP_AND_TEST.md.
- MOOSE is not included in the repo; install it with the Tools scripts or by copying MOOSE into `Scripts/MOOSE/`.
- **Zones**: Each capturable zone needs its own late-activated group templates in the Mission Editor. In `Config.lua`, `ZoneUnits[zoneName]` lists one blue and one red template per zone; duplicate the group in the ME and name it exactly as in config (e.g. `Anapa_FactoryA_1INF_B` for Anapa_FactoryA blue) so each zone spawns its own set of units.

## Config (Scripts/nationsatwar/Config.lua)

- **Zone replenishment** (refill lost defenders at a zone; unrelated to reinforcements): `EnableZoneReplenishment`, `FactoryReplenishIntervalSec`, `AirfieldReplenishIntervalSec`, `DefaultReplenishIntervalSec`. Replenishment does not run while an enemy unit is in the zone.
- **Defender count per zone**: `DefenderRingSlots`, `DefenderSquareSlots` (default 12 ring + 4 square).
- **Factory production**: `TanksPerMinute`, `FactoryTankCap`; factory tank count resets to 0 on capture.
- **Attacking reinforcements**: when a zone’s health is at or below `ReinforcementHealthThreshold` for `ReinforcementDelaySec` seconds, the nearest factory per faction can send units to that zone. Controlled by `EnableAttackingReinforcements`, `ReinforcementTemplates`, `ReinforcementIdleSec`, `ReinforcementAirfieldDespawnSec`, etc. On zone capture, attacking reinforcement units are removed (or despawn after a delay for airfields) and their count is returned to the source factory.
