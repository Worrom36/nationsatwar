-- DCS Mission - MOOSE loader; Nations at War via Loader.lua.

env.info("Mission Scripts - Initializing")

-- Full path to Scripts folder (DCS working dir is not your project). Edit if you move the repo.
local scriptPath = "D:\\CardinalCollective\\perforce\\nationsatwar\\Scripts\\"
local mooseLoader = scriptPath .. "MOOSE\\Moose Setup\\Moose Templates\\Moose_Dynamic_Loader.lua"

local success, err = pcall(function()
    MOOSE_DEVELOPMENT_FOLDER = scriptPath .. "MOOSE\\Moose Development"
    dofile(mooseLoader)
end)

if success then
    env.info("MOOSE loaded successfully")
else
    env.error("MOOSE load failed: " .. tostring(err))
    env.error("Path: " .. mooseLoader)
    env.error("If path still shows Scripts/, re-add this script in Mission Editor and save the mission.")
    return
end

_NATIONSATWAR_SCRIPT_PATH = scriptPath .. "nationsatwar\\"
dofile(_NATIONSATWAR_SCRIPT_PATH .. "Loader.lua")

env.info("Initialization Complete")
