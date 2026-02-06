-- Nations at War - Config

NationsAtWarConfig = {}

-- Capturable zones: zone name -> initial owner ("red" or "blue"). In-memory only.
NationsAtWarConfig.CapturableZones = {
    Anapa_AF = "blue",
    Anapa_Factory = "blue",
}

-- Zone draw colors by owner (F10 map). RGB 0–1 per channel: { r, g, b }.
NationsAtWarConfig.ZoneColors = {
    red = { 1, 0, 0 },
    blue = { 0, 0, 1 },
}

-- Ordered list of zones that get an F10 submenu (Zones → zone name → commands).
NationsAtWarConfig.ZoneMenuZones = {
    "Anapa_AF",
    "Anapa_Factory",
}

-- Zone health 0–100 shown over each zone on F10. All zones start at this value (set per-zone later).
NationsAtWarConfig.ZoneInitialHealth = 75

-- Interval (seconds) for periodic capture check. Handles the case: last defender killed, enemy enters zone later.
NationsAtWarConfig.CaptureCheckIntervalSec = 5

-- Factory zones replenish lost defender units. List zone names that get periodic replenishment.
-- ReplenishIntervalSec = how often to try replenishing (one missing group per interval).
NationsAtWarConfig.FactoryZones = { "Anapa_Factory" }
NationsAtWarConfig.ReplenishIntervalSec = 120

-- Spawn Counter (F10): one group of the opposing team at zone center. Uses these templates (shared across zones).
NationsAtWarConfig.CounterSpawnTemplates = {
    blue = "NaW_Test_1INF_B",
    red = "NaW_Test_1INF_R",
}

-- Per-zone unit lists: zone name -> { blue = {"GroupName1", ...}, red = {...} }.
-- Each zone must use its own late-activated group names so each zone gets its own set of units (not shared).
-- Add one template per coalition; it is reused for all 16 positions (12 ring + 4 square). Duplicate the group in the ME per zone.
NationsAtWarConfig.ZoneUnits = {
    Anapa_AF = {
        blue = { "Anapa_AF_1INF_B" },
        red = { "Anapa_AF_1INF_R" },
    },
    Anapa_Factory = {
        blue = { "Anapa_Factory_1INF_B" },
        red = { "Anapa_Factory_1INF_R" },
    },
}

NationsAtWarConfig.Messages = {
    show_in_game = true,
    min_level = "info",
    max_queue_lines = 20,
    out_text_duration = 8,
    f10_show_last = 5,
}
NationsAtWarConfig._level_order = { debug = 1, info = 2, warning = 3, error = 4 }
