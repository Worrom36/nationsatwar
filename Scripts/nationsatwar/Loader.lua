-- Nations at War - Loader. Edit this file to add/reorder scripts; Scripts/Init.lua stays unchanged.

local path = _NATIONSATWAR_SCRIPT_PATH
if not path then
    env.error("[NaW] Loader: _NATIONSATWAR_SCRIPT_PATH not set.")
    return
end

local ok, err = pcall(function()
    dofile(path .. "Config.lua")
    dofile(path .. "CapturableZones.lua")
    dofile(path .. "Zones.lua")
    dofile(path .. "RenderDigits.lua")
    dofile(path .. "SpawnHelper.lua")
    dofile(path .. "ZoneMovement.lua")
    dofile(path .. "EventHandlers.lua")
    dofile(path .. "ZoneCommands.lua")
    dofile(path .. "ZoneStatics.lua")
    dofile(path .. "FactoryProduction.lua")
    dofile(path .. "FactoryReinforcements.lua")
    dofile(path .. "Init.lua")
end)

if not ok then
    env.error("Nations at War init failed: " .. tostring(err))
end
