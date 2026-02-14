# Plan: Zone static objects

Support static objects in capturable zones so they:
1. **Contribute to zone health** (like defender units).
2. **Belong to the correct faction** that owns the zone (coalition/country at spawn).
3. **Swap correctly on capture** (remove previous owner’s statics, spawn new owner’s).

---

## DCS API notes (spawning, hiding, respawning)

- **Spawn**: `coalition.addStaticObject(countryId, objectTable)` with `name`, `type`, `category`, `x`, `y`, `heading`, `groupId`, `unitId`. Names must be unique. MIST `mist.dynAddStatic(vars)` and MOOSE `SPAWNSTATIC` are alternatives.
- **Hide**: No Lua API to hide/unhide an existing static (ME “hidden” is editor-only). Workaround: destroy the static; “show” again = respawn.
- **Destroy**: `StaticObject.getByName(name):destroy()`. No `S_EVENT_DEAD` when script destroys.
- **Respawn**: Store type/position/heading; call `coalition.addStaticObject()` again (e.g. after delay). After destroy, `getByName` can be unreliable for some types—prefer storing your own descriptor table.
- **Existence**: `StaticObject.getByName(name)` then `:isExist()`.
- **Death event**: `S_EVENT_DEAD` fires when a static is destroyed in-world. Use **`EventData.IniUnitName`** (and optionally `IniTypeName`, `IniObjectCategory`) to identify the static; do **not** rely on `event.initiator:getName()` (can be nil for statics in some DCS versions).

---

## Current behavior (reference)

- **Zone health** = A (0–50) + B (0 or 20) + C (0–30).  
  - **A**: defender units only — `A = (living defender units / total at registration) * 50`.  
  - **B**: 20 if any “outside” friendly unit in zone.  
  - **C**: 0–30, drains 1/sec when enemy alone in zone; at 0 → capture.
- **Defender units**: `Config.ZoneUnits[zoneName] = { red = {"Group1", ...}, blue = {...} }`. Spawned at ring + square positions, registered in `NationsAtWar_ZoneData`, `NationsAtWar_GroupToZone`. Living count in `NationsAtWar_ZoneDefenderUnitCount`.
- **Capture**: When C hits 0, `NationsAtWar_DoZoneCapture(zoneName)` runs: set owner to other team, redraw F10, call `NationsAtWar_SpawnZoneDefenders(zoneName)`.
- **Swap (F10)**: `NationsAtWar_SwapZone` → `NationsAtWar_KillAllZone` (kill all defender groups, clear zone data) → set owner → `NationsAtWar_SpawnZoneDefenders`.
- **Kill All**: `NationsAtWar_KillAllZone` destroys all defender groups for the zone and clears `NationsAtWar_ZoneData[zoneName]` and `NationsAtWar_GroupToZone` entries.
- **Respawn All**: Kill All then SpawnZoneDefenders.
- **Owner presence**: “hasOwner” uses defender groups, `countLivingDefenderUnits`, and `HasOwnerUnitsInZone` (search **units** in zone). No statics today.

---

## 1. Config and static definitions

**Preferred: Option B (Mission Editor markers + dictionary).** Option A remains available for config-only setups.

### Option B: Mission Editor markers + dictionary (preferred)

- **In Mission Editor**: Place **late-activated group(s)** (or single unit) where each building should be. Give each a **unique name** that the script will recognize (e.g. `Anapa_AF_Static_Bunker_1`, or a convention like `ZoneName_Static_Key`). Leave them **late-activated** so they never spawn as units.
- **In script**: At init, read **`env.mission`** (e.g. `env.mission.coalition.red.country` / `blue.country` → groups → units). Find groups (or units) whose names match a convention or a config list. For each marker:
  - **Position**: from mission data (first unit’s `x`, `y`, `heading`; note DCS table often uses x/y for 2D position).
  - **Name** → **static type**: use the marker name as key in a **dictionary** (e.g. `StaticTypeFromName["Anapa_AF_Static_Bunker_1"] = "Bunker"`, or parse a suffix like `"Bunker_1"` → `"Bunker"`).
- **Config**: e.g. `NationsAtWarConfig.ZoneStaticMarkers = { Anapa_AF = true, ... }` to enable ME-marker mode per zone, and `NationsAtWarConfig.StaticTypeFromName = { ["Anapa_AF_Static_Bunker_1"] = "Bunker", ... }` (or a function that maps marker name → type). Marker names can be the group name or the first unit name.
- **Result**: One late-activated “unit” per building: used only for position and name; never activated. Script spawns the real static at that position with the type from the dictionary.

### Option A: Config-only (slots / explicit coords) — alternative

- **Config**: e.g. `NationsAtWarConfig.ZoneStatics` (optional). `ZoneStatics[zoneName] = { red = { ... }, blue = { ... } }`.
- **Per-faction value**: list of static definitions. Each entry: **type** (DCS static type name), **position** from zone geometry (slot 1..N via `NationsAtWar_GetZoneSlotCoord`) or explicit `{ x, y, heading }`.
- Use when ME markers are not desired; same spawn/kill/health logic applies.

### Country ID

- Map faction name to DCS country ID (red/blue) so spawned statics have the correct coalition. Use existing mission country setup or a small config map.

---

## 2. Spawning and storing zone statics

- **API**: DCS `coalition.addStaticObject(countryId, { name = "...", type = "...", x = ..., y = ..., heading = ..., category = "Fortifications", ... })`. Name must be unique; generate e.g. `zoneName .. "_static_" .. owner .. "_" .. index`.
- **Where**: New helpers (e.g. in `ZoneStatics.lua`):  
  - **Static list source (preferred: ME markers)**: Build the per-zone static list once at init by scanning `env.mission` for marker groups (by name convention or config list), reading position and mapping name → type via dictionary. Store the resulting list (zone → list of { type, x, y, heading }; same positions for both owners) so it can be reused for spawn; marker groups are never activated. **Alternative (Option A)**: list from `ZoneStatics[zoneName][owner]` and slot/coords.
  - `NationsAtWar_SpawnZoneStatics(zoneName)`  
    - Uses current owner; gets list of static definitions (from ME-marker-derived list, or from config). Resolves positions (ME position or slot coords), spawns each with `coalition.addStaticObject` and owner’s country ID, stores spawned object names.
  - **Storage**: e.g. `NationsAtWar_ZoneData[zoneName].staticObjects = { [objectName] = true }` or a list of object names so we can destroy them and count “living” for health.
- **When to spawn**:
  - **Init**: After defender unit spawn for each zone, if zone has statics (config or ME markers), call `NationsAtWar_SpawnZoneStatics(zoneName)`.
  - **After capture**: In `NationsAtWar_DoZoneCapture`, after `NationsAtWar_SpawnZoneDefenders`, call `NationsAtWar_SpawnZoneStatics(zoneName)` (new owner).
  - **Swap (F10)** / **Respawn All**: Same — after killing zone units (and zone statics) and spawning new defenders, call `NationsAtWar_SpawnZoneStatics(zoneName)`.

---

## 3. Killing zone statics on swap / Kill All / Respawn

- **New**: `NationsAtWar_KillZoneStatics(zoneName)`  
  - For each stored static object for that zone, if object exists (e.g. `Object.getByName(name)` and `obj:isExist()`), destroy it (e.g. `obj:destroy()`).  
  - Clear `NationsAtWar_ZoneData[zoneName].staticObjects` (or equivalent).
- **Integration**:
  - **NationsAtWar_KillAllZone**: Before or after killing defender groups, call `NationsAtWar_KillZoneStatics(zoneName)`. Optionally clear a dedicated `NationsAtWar_ZoneStaticIds` or similar if stored outside ZoneData.
  - **NationsAtWar_DoZoneCapture**: Before spawning new owner’s defenders/statics, kill current zone statics (current owner’s) — so call `NationsAtWar_KillZoneStatics(zoneName)` at start of capture, then set owner, then spawn defenders and statics.
  - **NationsAtWar_SwapZone**: Already calls `NationsAtWar_KillAllZone`; ensure KillAllZone includes killing zone statics (so no separate call needed if KillAllZone is the single place that clears everything).
- **Order**: On capture, recommended order: kill defender units → kill zone statics → set owner → redraw F10 → spawn new defenders → spawn new statics. That way the zone is “empty” before the new owner’s objects appear.

---

## 4. Zone health: statics contribute to A (preferred: single combined A)

- **Goal**: Static objects contribute to the same 0–100 health so that losing statics (e.g. destroyed by players) reduces health like losing units.
- **Chosen approach: Option A — fold statics into the existing A component.**  
  - Define “total defender strength” = total defender **units** at registration + total **statics** at registration.  
  - “Living defender strength” = living defender units + living statics (each static 0 or 1).  
  - Formula: `A = (living / total) * 50`, with total/living including both units and statics.  
  - When registering defenders, also set “total static count” for the zone; in `NationsAtWar_ComputeZoneHealthA`, add `countLivingZoneStatics(zoneName)` and use `(livingUnits + livingStatics) / (totalUnits + totalStatics) * 50`. If a zone has no statics, totalStatics = 0 and behavior stays as today.
- **Implementation**:
  - **Total at registration**: When `NationsAtWar_SpawnZoneStatics` runs, set e.g. `NationsAtWar_ZoneDefenderStaticCount[zoneName] = #spawned` (or from ME-marker list length). Optionally combine with unit count into one “total defender strength” in ZoneData.
  - **Living count**: `countLivingZoneStatics(zoneName)` iterates stored static names, checks existence (`StaticObject.getByName(name)` + `:isExist()`), returns count.
  - **NationsAtWar_ComputeZoneHealthA**: Change to `(livingUnits + livingStatics) / (totalUnits + totalStatics) * 50`, with safe handling when total is 0 (return 0). Ensure `NationsAtWar_ZoneDefenderUnitCount` and the new static total are both set at spawn/registration time.
- **Not chosen**: Separate A_units and A_statics (e.g. 0–25 each); would add config and tuning without changing behavior goals.

---

## 5. Faction ownership and “hasOwner”

- **Spawning**: Always use the **current zone owner** to choose which list to spawn: `ZoneStatics[zoneName][NationsAtWar_GetZoneOwner(zoneName)]`, and use that faction’s country ID for `coalition.addStaticObject`. So statics always belong to the correct faction.
- **hasOwner**: Today “hasOwner” prevents C drain and is used for capture logic. Include zone statics: if any registered static for the zone (for current owner) still exists, treat as “owner has presence” (same as having living defender units). So in `NationsAtWar_UpdateZoneHealthAndDisplay`, `hasOwner` should be true if either:
  - existing conditions (defender groups, living defender units, `HasOwnerUnitsInZone`), or
  - `countLivingZoneStatics(zoneName) > 0` (only count statics that are registered for this zone and current owner; storage should make this clear).
- No change to B or C formulas; only A and hasOwner are extended.

---

## 6. Static object death and health updates

- **Event**: `S_EVENT_DEAD` fires when a static is destroyed in-world. Use **`EventData.IniUnitName`** to get the static name (do not use `event.initiator:getName()` — it can be nil for statics). Handler: resolve zone from static name (e.g. prefix `zoneName .. "_static_"` or lookup table), then call `NationsAtWar_UpdateZoneHealthAndDisplay(zoneName)` for immediate health/display update.
- **If no handler**: Rely on the 1 Hz `NationsAtWar_RunZoneHealthUpdate`; `countLivingZoneStatics` will see the object gone on the next tick. No functional gap, only a short delay.

---

## 7. Load order and init

- **Loader**: Ensure the new script (e.g. `ZoneStatics.lua`) is loaded after `Zones.lua`, `CapturableZones.lua`, and `ZoneMovement.lua` / `ZoneCommands.lua` so that `NationsAtWar_GetZoneOwner`, `NationsAtWar_GetZoneCoord` / geometry, `NationsAtWar_ZoneData`, and spawn/kill helpers exist.
- **Init**: In `Init.lua`, inside `initOneZone`, after spawning defender units and calling `NationsAtWar_RegisterZoneUnits`, call `NationsAtWar_SpawnZoneStatics(zoneName)` when `ZoneStatics[zoneName]` is present.
- **ZoneCommands**: In `NationsAtWar_DoZoneCapture` and `NationsAtWar_SwapZone`, after setting owner and spawning defenders, call `NationsAtWar_SpawnZoneStatics(zoneName)`. In `NationsAtWar_KillAllZone`, call `NationsAtWar_KillZoneStatics(zoneName)` so Respawn All and Swap also reset statics.

---

## 8. Summary of touchpoints

| Area | Change |
|------|--------|
| **Config.lua** | Prefer `ZoneStaticMarkers`, `StaticTypeFromName` (or name→type function) for ME-marker mode; optionally `ZoneStatics` for config-only (Option A). Country-id map for red/blue. |
| **Mission Editor** | **Preferred**: Late-activated groups per building; name = dictionary key, position = spawn position. |
| **New (e.g. ZoneStatics.lua)** | Build static list from `env.mission` (ME markers) or from config. `NationsAtWar_SpawnZoneStatics`, `NationsAtWar_KillZoneStatics`, `countLivingZoneStatics`, storage in ZoneData. |
| **ZoneMovement.lua** | `NationsAtWar_ComputeZoneHealthA`: include static living/total in A. `NationsAtWar_UpdateZoneHealthAndDisplay`: include statics in `hasOwner`. |
| **ZoneCommands.lua** | `NationsAtWar_KillAllZone`: call KillZoneStatics. `NationsAtWar_DoZoneCapture` / `NationsAtWar_SwapZone`: after kill + spawn defenders, call SpawnZoneStatics. |
| **Init.lua** | In `initOneZone`, after defender spawn/register, call SpawnZoneStatics when zone has statics (config or ME markers). |
| **Loader.lua** | Load new script in correct order. |
| **Optional** | `S_EVENT_DEAD` handler using `EventData.IniUnitName` → resolve zone → `UpdateZoneHealthAndDisplay(zoneName)`. |

---

## 9. Edge cases

- **Zone has no statics (no config, no ME markers)**: No spawn/kill of statics; A and hasOwner unchanged (current behavior).
- **Zone has statics but no units**: A can still be 0–50 from statics alone; total = totalStatics, living = livingStatics. hasOwner = true if any zone static exists.
- **Respawn All**: Kill All (units + statics) then spawn defenders + statics for current owner — consistent.
- **ME markers**: Late-activated marker groups are never activated; they exist only in mission data for position + name. Script reads `env.mission`, spawns statics, never spawns the marker units.

---

## 10. Summary

| What | How |
|------|-----|
| **Define statics** | **Preferred (B)**: Late-activated groups in ME; script reads `env.mission` for position, name → dictionary for static type. **Alternative (A)**: Config `ZoneStatics[zone][red/blue]` with type + slot or coords. |
| **Spawn** | `coalition.addStaticObject(countryId, { name, type, category, x, y, heading, ... })`. Spawn at init and after capture/Swap/Respawn for current owner. |
| **Kill** | `NationsAtWar_KillZoneStatics(zoneName)`: for each stored name, `StaticObject.getByName(name):destroy()` if `:isExist()`. Called from KillAllZone and before respawning on capture. |
| **Health A** | **Preferred (A)**: Single combined A = (livingUnits + livingStatics) / (totalUnits + totalStatics) × 50. `countLivingZoneStatics` via `getByName` + `isExist()`. |
| **hasOwner** | True if any defender units/groups or any living zone static (for current owner). |
| **Death** | Optional: `S_EVENT_DEAD` handler using `EventData.IniUnitName` → `UpdateZoneHealthAndDisplay(zoneName)`. Else 1 Hz tick picks it up. |

This plan keeps zone health, ownership, and swap logic consistent while adding static objects as first-class zone defenders that contribute to health, belong to the zone owner, and swap on capture.
