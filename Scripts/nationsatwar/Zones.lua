-- Nations at War - Zone helpers (lookup, coords, draw on F10).

function NationsAtWar_GetZone(zoneName)
    if not zoneName or not ZONE or not ZONE.FindByName then return nil end
    return ZONE:FindByName(zoneName)
end

function NationsAtWar_GetZoneCoord(zoneName)
    if not zoneName or not env.mission or not env.mission.triggers or not env.mission.triggers.zones then
        return nil, nil, nil
    end
    local nameLower = zoneName:lower()
    for _, zoneData in pairs(env.mission.triggers.zones) do
        local name = zoneData.name
        if name and (name == zoneName or name:lower() == nameLower or name:lower():find(nameLower, 1, true)) then
            if zoneData.x and zoneData.y and COORDINATE and COORDINATE.NewFromVec2 then
                local radius = zoneData.radius
                if not radius and zoneData.type == 0 and trigger.misc and trigger.misc.getZone then
                    local z = trigger.misc.getZone(name)
                    if z and z.radius then radius = z.radius end
                end
                return COORDINATE:NewFromVec2({ x = zoneData.x, y = zoneData.y }), name, radius
            end
            break
        end
    end
    local zone = NationsAtWar_GetZone(zoneName)
    if zone and zone.GetCoordinate then
        local r = (zone.GetRadius and zone:GetRadius()) or nil
        return zone:GetCoordinate(), zoneName, r
    end
    return nil, nil, nil
end

function NationsAtWar_DrawZoneOnMap(zoneName, opts)
    if not zoneName then return end
    opts = opts or {}
    local zone = NationsAtWar_GetZone(zoneName)
    if not zone or not zone.DrawZone then return end
    local color = opts.color or {0, 1, 0}
    local alpha = opts.alpha or 1
    local fillColor = opts.fillColor or color
    local fillAlpha = opts.fillAlpha or 0.2
    local coalition = opts.coalition or -1
    local lineType = opts.lineType or 1
    local readonly = opts.readonly ~= false
    zone:DrawZone(coalition, color, alpha, fillColor, fillAlpha, lineType, readonly)
end

function NationsAtWar_DrawZoneOnMapFromCoord(coord, foundName, radius, opts)
    if not coord or not coord.CircleToAll then return false end
    opts = opts or {}
    local color = opts.color or {0, 1, 0}
    local alpha = opts.alpha or 1
    local fillColor = opts.fillColor or color
    local fillAlpha = opts.fillAlpha or 0.2
    local coalition = opts.coalition or -1
    local lineType = opts.lineType or 1
    local readonly = opts.readonly ~= false
    local r = radius or 1000
    coord:CircleToAll(r, coalition, color, alpha, fillColor, fillAlpha, lineType, readonly, foundName or "")
    return true
end
