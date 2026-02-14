-- Nations at War - Capturable zone state (in-memory, no persistence).

NationsAtWar_CapturableZoneOwner = NationsAtWar_CapturableZoneOwner or {}

local VALID_OWNERS = { red = true, blue = true }

function NationsAtWar_InitCapturableZones()
    NationsAtWar_CapturableZoneOwner = {}
    local cfg = NationsAtWarConfig and NationsAtWarConfig.CapturableZones
    if not cfg or type(cfg) ~= "table" then return end
    for zoneName, initialOwner in pairs(cfg) do
        local owner = (type(initialOwner) == "string" and initialOwner:lower()) or "red"
        if not VALID_OWNERS[owner] then owner = "red" end
        NationsAtWar_CapturableZoneOwner[zoneName] = owner
    end
end

function NationsAtWar_GetZoneOwner(zoneName)
    if not zoneName then return nil end
    return NationsAtWar_CapturableZoneOwner[zoneName]
end

function NationsAtWar_SetZoneOwner(zoneName, owner)
    if not zoneName then return end
    owner = (type(owner) == "string" and owner:lower()) or "red"
    if VALID_OWNERS[owner] then
        NationsAtWar_CapturableZoneOwner[zoneName] = owner
        -- Reset factory tank count on capture (factory changes hands)
        local factoryZones = NationsAtWarConfig and NationsAtWarConfig.FactoryZones
        if factoryZones and type(factoryZones) == "table" then
            for _, z in ipairs(factoryZones) do
                if z == zoneName then
                    if NationsAtWar_ResetFactoryTankCount then NationsAtWar_ResetFactoryTankCount(zoneName) end
                    break
                end
            end
        end
    end
end
