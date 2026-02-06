-- Nations at War - DCS World event handler (loaded by Loader.lua). This is the only event handler script; no Scripts/World/EventHandlers.lua.
-- DCS expects a table with an onEvent method; passing a bare function can cause wrong arguments and "attempt to index local 'handler' (a function value)".

if world and world.addEventHandler then
    local handler = {}
    function handler:onEvent(event)
        if type(event) ~= "table" or not event.id then
            return
        end
        -- Optional: dispatch by event.id (e.g. world.event.S_EVENT_DEAD, world.event.S_EVENT_KILL)
        -- ZoneMovement.lua registers the kill handler; no need to duplicate here.
    end
    world.addEventHandler(handler)
end
