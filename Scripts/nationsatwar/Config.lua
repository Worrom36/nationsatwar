-- Nations at War - Config

NationsAtWarConfig = {}

-- Capturable zones: zone name -> initial owner ("red" or "blue"). In-memory only.
NationsAtWarConfig.CapturableZones = {
    Anapa_AF = "blue",
    Anapa_FactoryA = "blue",
    Anapa_FactoryB = "red",
}

-- Zone draw colors by owner (F10 map). RGB 0–1 per channel: { r, g, b }.
NationsAtWarConfig.ZoneColors = {
    red = { 1, 0, 0 },
    blue = { 0, 0, 1 },
}

-- Ordered list of zones that get an F10 submenu (Zones → zone name → commands).
NationsAtWarConfig.ZoneMenuZones = {
    "Anapa_AF",
    "Anapa_FactoryA",
    "Anapa_FactoryB",
}

-- Zone health 0–100 shown over each zone on F10. All zones start at this value (set per-zone later).
NationsAtWarConfig.ZoneInitialHealth = 75

-- Interval (seconds) for periodic capture check. Handles the case: last defender killed, enemy enters zone later.
NationsAtWarConfig.CaptureCheckIntervalSec = 5

-- Zone replenishment: refill lost defender units at a zone (unrelated to reinforcements sent to other zones).
-- EnableZoneReplenishment = true to replenish; false or omit to disable.
-- FactoryZones = zone names that use FactoryReplenishIntervalSec.
-- AirfieldZones = zone names that use AirfieldReplenishIntervalSec.
-- Zones not in either list use DefaultReplenishIntervalSec (one missing group per interval).
NationsAtWarConfig.EnableZoneReplenishment = true
NationsAtWarConfig.FactoryZones = { "Anapa_FactoryA", "Anapa_FactoryB" }
NationsAtWarConfig.AirfieldZones = { "Anapa_AF" }
NationsAtWarConfig.FactoryReplenishIntervalSec = 120
NationsAtWarConfig.AirfieldReplenishIntervalSec = 300
NationsAtWarConfig.DefaultReplenishIntervalSec = 300

-- Factory tank production: one shared timer adds production per minute; counter resets on capture.
-- TanksPerMinute = added each timer tick (default 2). FactoryTankCap = max count per factory (default 12). Not shown on map.
NationsAtWarConfig.TanksPerMinute = 2
NationsAtWarConfig.FactoryTankCap = 12

-- Factory reinforcements (attacking): when zone health drops to or below threshold, nearest factory per faction spawns units and sends to zone.
-- EnableAttackingReinforcements = true/false; when false, no attacking reinforcements spawn (default true).
-- ReinforcementTemplates = one late-activated group name per faction (create in ME).
-- ReinforcementIdleSec = min time before same zone can trigger again (default 600 = 10 min). Resets when zone changes hands.
-- ReinforcementGraceSec = ignore reinforcement events for this many seconds after match start (avoids race at mission start; default 3).
-- ReinforcementMoveOrderIntervalSec = seconds between issuing move order to each reinforcement group (stagger so they don't all move at once; default 1).
-- Require zone health at or below threshold for this many seconds before sending reinforcements; condition is re-evaluated after the delay (default 5).
-- When a zone that is an airfield is captured, attacking reinforcement units despawn after this many seconds (default 600 = 10 min).
NationsAtWarConfig.EnableAttackingReinforcements = true
NationsAtWarConfig.ReinforcementTemplates = { red = "NaW_Reinforcement_Red", blue = "NaW_Reinforcement_Blue" }
NationsAtWarConfig.ReinforcementGraceSec = 3
NationsAtWarConfig.ReinforcementMoveOrderIntervalSec = 2
NationsAtWarConfig.ReinforcementHealthThreshold = 49
NationsAtWarConfig.ReinforcementIdleSec = 600
NationsAtWarConfig.ReinforcementDelaySec = 5
NationsAtWarConfig.ReinforcementAirfieldDespawnSec = 600

-- Spawn Counter (F10): one group of the opposing team at zone center. Uses these templates (shared across zones).
NationsAtWarConfig.CounterSpawnTemplates = {
    blue = "NaW_Test_1INF_B",
    red = "NaW_Test_1INF_R",
}

-- Defender groups per zone: ring (full radius) + square (half-radius corners). Total = DefenderRingSlots + DefenderSquareSlots.
NationsAtWarConfig.DefenderRingSlots = 12
NationsAtWarConfig.DefenderSquareSlots = 4

-- Per-zone unit lists: zone name -> { blue = {"GroupName1", ...}, red = {...} }.
-- Each zone must use its own late-activated group names so each zone gets its own set of units (not shared).
-- Add one template per coalition; it is reused for all positions (ring + square). Duplicate the group in the ME per zone.
NationsAtWarConfig.ZoneUnits = {
    Anapa_AF = {
        blue = { "Anapa_AF_1INF_B" },
        red = { "Anapa_AF_1INF_R" },
    },
    Anapa_FactoryA = {
        blue = { "Anapa_FactoryA_1INF_B" },
        red = { "Anapa_FactoryA_1INF_R" },
    },
    Anapa_FactoryB = {
        blue = { "Anapa_FactoryB_1INF_B" },
        red = { "Anapa_FactoryB_1INF_R" },
    },
}

-- Zone static objects (buildings): ME markers + dictionary (preferred). Late-activated groups in ME mark position; name maps to static type.
-- ZoneStaticMarkerGroups[zoneName] = { "ME_GroupName1", "ME_GroupName2" } -- group names in mission that mark where to spawn statics for this zone.
-- StaticTypeFromName["ME_GroupName1"] = "Bunker" -- DCS static type name (e.g. "Bunker", "Sandbox"). Same marker list used for both owners; owner sets coalition at spawn.
NationsAtWarConfig.ZoneStaticMarkerGroups = {Anapa_AF = {"Anapa_AF_TechHangerA", "Anapa_AF_Bunker1"}}
-- NationsAtWarConfig.ZoneStaticMarkerGroups = { Anapa_AF = { "Anapa_AF_Static_1", "Anapa_AF_Static_2" } }
-- NationsAtWarConfig.StaticTypeFromName = { ["Anapa_AF_Static_1"] = "Bunker", ["Anapa_AF_Static_2"] = "Sandbox" }
NationsAtWarConfig.StaticTypeFromName = {["Anapa_AF_TechHangerA"] = "Tech hangar A", ["Anapa_AF_Bunker1"] = "Bunker 1"}
-- Country IDs for coalition.addStaticObject (red/blue). Match your mission: e.g. 0 = Russia, 2 = USA.
NationsAtWarConfig.StaticCountryIds = { red = 0, blue = 2 }

NationsAtWarConfig.Messages = {
    show_in_game = true,
    min_level = "info",
    max_queue_lines = 20,
    out_text_duration = 8,
    f10_show_last = 5,
}
NationsAtWarConfig._level_order = { debug = 1, info = 2, warning = 3, error = 4 }
