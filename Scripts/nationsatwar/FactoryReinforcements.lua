-- Nations at War - Factory reinforcements when zone health drops to or below threshold.
-- Nearest factory per faction (prefer >= half cap) spawns manufactured units and sends them to the zone at half radius.
-- Triggers once per zone ownership; can trigger again after ReinforcementIdleSec or when zone changes hands.
-- Maximum one active reinforcement per team per zone: if any sent group for (zone, faction) is still alive, no new reinforcement for that faction.

NationsAtWar_ReinforcementState = NationsAtWar_ReinforcementState or {}  -- zoneName -> { lastOwner, lastTriggerTime }
NationsAtWar_ReinforcementActiveGroups = NationsAtWar_ReinforcementActiveGroups or {}  -- zoneName -> { red = { group, ... }, blue = { ... } }
NationsAtWar_ReinforcementSourceFactory = NationsAtWar_ReinforcementSourceFactory or {}  -- zoneName -> { red = factoryName, blue = factoryName }
NationsAtWar_ReinforcementPendingDelay = NationsAtWar_ReinforcementPendingDelay or {}  -- zoneName -> true when a delayed check is scheduled

local function distSqFromCoordToCoord(coordA, coordB)
    if not coordA or not coordB then return math.huge end
    local vA = (coordA.GetVec3 and coordA:GetVec3()) or (coordA.GetVec2 and coordA:GetVec2())
    local vB = (coordB.GetVec3 and coordB:GetVec3()) or (coordB.GetVec2 and coordB:GetVec2())
    if not vA or not vB then return math.huge end
    local xA, zA = vA.x, vA.z or vA.y
    local xB, zB = vB.x, vB.z or vB.y
    if not xA or not zA or not xB or not zB then return math.huge end
    return (xA - xB) * (xA - xB) + (zA - zB) * (zA - zB)
end

--- Nearest factory owned by owner to attackedZoneName. Prefers factory with count >= half FactoryTankCap; if none, uses nearest.
function NationsAtWar_GetNearestFactoryByOwner(attackedZoneName, owner)
    if not attackedZoneName or not owner then return nil end
    local cfg = NationsAtWarConfig
    if not cfg or not cfg.FactoryZones or type(cfg.FactoryZones) ~= "table" then return nil end
    local cap = (type(cfg.FactoryTankCap) == "number" and cfg.FactoryTankCap > 0) and cfg.FactoryTankCap or 12
    local halfCap = cap / 2
    local attackedCoord = NationsAtWar_GetZoneCoord and NationsAtWar_GetZoneCoord(attackedZoneName)
    if not attackedCoord then return nil end
    local owned = {}
    for _, fz in ipairs(cfg.FactoryZones) do
        if fz and type(fz) == "string" and fz ~= "" then
            local fzOwner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(fz)
            if fzOwner == owner then
                local fzCoord = NationsAtWar_GetZoneCoord and NationsAtWar_GetZoneCoord(fz)
                if fzCoord then
                    local distSq = distSqFromCoordToCoord(attackedCoord, fzCoord)
                    table.insert(owned, { name = fz, distSq = distSq, count = NationsAtWar_GetFactoryTankCount and NationsAtWar_GetFactoryTankCount(fz) or 0 })
                end
            end
        end
    end
    if #owned == 0 then return nil end
    table.sort(owned, function(a, b) return a.distSq < b.distSq end)
    for _, e in ipairs(owned) do
        if e.count >= halfCap then return e.name end
    end
    return owned[1] and owned[1].name or nil
end

--- True if there is at least one alive reinforcement group for (zoneName, owner). Prunes dead groups from storage.
local function hasActiveReinforcementForFaction(zoneName, owner)
    NationsAtWar_ReinforcementActiveGroups = NationsAtWar_ReinforcementActiveGroups or {}
    local perZone = NationsAtWar_ReinforcementActiveGroups[zoneName]
    if not perZone or not perZone[owner] then return false end
    local alive = {}
    for _, g in ipairs(perZone[owner]) do
        if g and NationsAtWar_IsGroupAlive and NationsAtWar_IsGroupAlive(g) then
            table.insert(alive, g)
        end
    end
    NationsAtWar_ReinforcementActiveGroups[zoneName][owner] = alive
    return #alive > 0
end

-- Delay (seconds) before giving move orders so all spawned groups are in the world.
local REINFORCEMENT_ROUTE_DELAY_SEC = 2

local function spawnAndRouteReinforcementsForFaction(attackedZoneName, owner, factoryName, count, factoryCoord, destRingCoords)
    if not count or count <= 0 or not factoryCoord or not destRingCoords or #destRingCoords == 0 then return end
    local templates = NationsAtWarConfig and NationsAtWarConfig.ReinforcementTemplates
    local templateName = templates and templates[owner]
    if not templateName or type(templateName) ~= "string" or templateName == "" then return end
    if NationsAtWar_EnsureSpawnTemplate then NationsAtWar_EnsureSpawnTemplate(templateName) end
    local ok, spawnObj = pcall(SPAWN.New, SPAWN, templateName)
    if not ok or not spawnObj then return end
    local groups = {}
    for i = 1, count do
        local okSpawn, group = pcall(spawnObj.SpawnFromCoordinate, spawnObj, factoryCoord)
        if okSpawn and group then
            table.insert(groups, group)
        end
    end
    if #groups == 0 then return end
    local nRing = #destRingCoords
    local orderIntervalSec = (type(NationsAtWarConfig.ReinforcementMoveOrderIntervalSec) == "number" and NationsAtWarConfig.ReinforcementMoveOrderIntervalSec >= 0) and NationsAtWarConfig.ReinforcementMoveOrderIntervalSec or 1
    -- Build (group, destCoord) pairs and give move orders after a delay so all groups exist in DCS; stagger each group by orderIntervalSec.
    local routeList = {}
    for i, group in ipairs(groups) do
        local coordIndex = ((i - 1) % nRing) + 1
        local destCoord = destRingCoords[coordIndex]
        if destCoord then
            table.insert(routeList, { group = group, destCoord = destCoord })
        end
    end
    if timer and timer.scheduleFunction and timer.getTime and NationsAtWar_RouteGroupToCoord and #routeList > 0 then
        local baseTime = timer.getTime() + REINFORCEMENT_ROUTE_DELAY_SEC
        for idx, e in ipairs(routeList) do
            local orderTime = baseTime + (idx - 1) * orderIntervalSec
            local group = e.group
            local destCoord = e.destCoord
            timer.scheduleFunction(function()
                if group and destCoord and NationsAtWar_RouteGroupToCoord then
                    NationsAtWar_RouteGroupToCoord(group, destCoord)
                end
            end, nil, orderTime)
        end
    else
        for _, e in ipairs(routeList) do
            if e.group and e.destCoord and NationsAtWar_RouteGroupToCoord then
                NationsAtWar_RouteGroupToCoord(e.group, e.destCoord)
            end
        end
    end
    if NationsAtWar_ResetFactoryTankCount and factoryName then
        NationsAtWar_ResetFactoryTankCount(factoryName)
    end
    NationsAtWar_ReinforcementActiveGroups[attackedZoneName] = NationsAtWar_ReinforcementActiveGroups[attackedZoneName] or {}
    NationsAtWar_ReinforcementActiveGroups[attackedZoneName][owner] = groups
    NationsAtWar_ReinforcementSourceFactory[attackedZoneName] = NationsAtWar_ReinforcementSourceFactory[attackedZoneName] or {}
    NationsAtWar_ReinforcementSourceFactory[attackedZoneName][owner] = factoryName
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "Reinforcements: [%s] %s spawned %d at [%s], routing to [%s] (orders in %s s)", attackedZoneName, owner, #groups, factoryName or "?", attackedZoneName, tostring(REINFORCEMENT_ROUTE_DELAY_SEC))
    end
end

--- Actually send reinforcements for zone (after delay re-evaluation). State/ownership/coords must already be valid.
local function trySendReinforcements(zoneName)
    if not zoneName or type(zoneName) ~= "string" or zoneName == "" then return end
    local cfg = NationsAtWarConfig
    if not cfg then return end
    local now = (timer and timer.getTime) and timer.getTime() or 0
    local threshold = (type(cfg.ReinforcementHealthThreshold) == "number") and cfg.ReinforcementHealthThreshold or 50
    local idleSec = (type(cfg.ReinforcementIdleSec) == "number" and cfg.ReinforcementIdleSec > 0) and cfg.ReinforcementIdleSec or 600
    local currentOwner = NationsAtWar_GetZoneOwner and NationsAtWar_GetZoneOwner(zoneName)
    if not currentOwner then return end
    NationsAtWar_ReinforcementState = NationsAtWar_ReinforcementState or {}
    local state = NationsAtWar_ReinforcementState[zoneName]
    local allow = false
    if not state then
        allow = true
    elseif state.lastOwner ~= currentOwner then
        allow = true
    elseif (now - (state.lastTriggerTime or 0)) >= idleSec then
        allow = true
    end
    if not allow then return end
    NationsAtWar_ReinforcementState[zoneName] = { lastOwner = currentOwner, lastTriggerTime = now }
    local attackedCoord, _, attackedRadius = NationsAtWar_GetZoneCoord and NationsAtWar_GetZoneCoord(zoneName)
    if not attackedCoord then return end
    local halfR = (type(attackedRadius) == "number" and attackedRadius > 0) and (attackedRadius * 0.5) or 500
    local maxRing = (cfg and type(cfg.DefenderRingSlots) == "number" and cfg.DefenderRingSlots > 0) and cfg.DefenderRingSlots or 12
    local destRingCoords = NationsAtWar_GetZoneRingPositions and NationsAtWar_GetZoneRingPositions(attackedCoord, halfR, maxRing, 0) or {}
    if #destRingCoords == 0 then return end
    for _, owner in ipairs({ "red", "blue" }) do
        if hasActiveReinforcementForFaction(zoneName, owner) then
            -- Already have active reinforcement for this zone from this team; do not send another.
        else
            local factoryName = NationsAtWar_GetNearestFactoryByOwner(zoneName, owner)
            if factoryName then
                local count = NationsAtWar_GetFactoryTankCount and NationsAtWar_GetFactoryTankCount(factoryName) or 0
                if count > 0 then
                    local factoryCoord = NationsAtWar_GetZoneCoord and NationsAtWar_GetZoneCoord(factoryName)
                    if factoryCoord then
                        spawnAndRouteReinforcementsForFaction(zoneName, owner, factoryName, count, factoryCoord, destRingCoords)
                    end
                end
            end
        end
    end
    -- Re-evaluate every ReinforcementIdleSec while health stays below threshold (catch cases where health never crosses back up).
    if timer and timer.scheduleFunction and timer.getTime and idleSec > 0 then
        timer.scheduleFunction(function()
            local currentHealth = (NationsAtWar_GetZoneHealth and NationsAtWar_GetZoneHealth(zoneName)) or 100
            if currentHealth > threshold then return end
            trySendReinforcements(zoneName)
        end, nil, now + idleSec)
    end
end

--- Called when zone health crosses to or below threshold. Delays by ReinforcementDelaySec, then re-evaluates; sends only if health still at/below threshold.
function NationsAtWar_OnZoneHealthBelow50(zoneName)
    if not zoneName or type(zoneName) ~= "string" or zoneName == "" then return end
    local cfg = NationsAtWarConfig
    if not cfg then return end
    if cfg.EnableAttackingReinforcements == false then return end
    local now = (timer and timer.getTime) and timer.getTime() or 0
    local graceSec = (type(cfg.ReinforcementGraceSec) == "number" and cfg.ReinforcementGraceSec >= 0) and cfg.ReinforcementGraceSec or 3
    if graceSec > 0 and now < graceSec then return end
    local delaySec = (type(cfg.ReinforcementDelaySec) == "number" and cfg.ReinforcementDelaySec >= 0) and cfg.ReinforcementDelaySec or 5
    local threshold = (type(cfg.ReinforcementHealthThreshold) == "number") and cfg.ReinforcementHealthThreshold or 50

    if delaySec > 0 then
        NationsAtWar_ReinforcementPendingDelay = NationsAtWar_ReinforcementPendingDelay or {}
        if NationsAtWar_ReinforcementPendingDelay[zoneName] then return end
        NationsAtWar_ReinforcementPendingDelay[zoneName] = true
        if timer and timer.scheduleFunction and timer.getTime then
            timer.scheduleFunction(function()
                NationsAtWar_ReinforcementPendingDelay[zoneName] = nil
                local currentHealth = (NationsAtWar_GetZoneHealth and NationsAtWar_GetZoneHealth(zoneName)) or 100
                if currentHealth > threshold then return end
                trySendReinforcements(zoneName)
            end, nil, timer.getTime() + delaySec)
        else
            NationsAtWar_ReinforcementPendingDelay[zoneName] = nil
            trySendReinforcements(zoneName)
        end
        return
    end

    trySendReinforcements(zoneName)
end

local function zoneInList(zoneName, list)
    if not zoneName or not list or type(list) ~= "table" then return false end
    for _, z in ipairs(list) do
        if z == zoneName then return true end
    end
    return false
end

local function destroyReinforcementGroups(groups)
    if not groups or type(groups) ~= "table" then return end
    for _, g in ipairs(groups) do
        if g and g.Destroy and NationsAtWar_IsGroupAlive and NationsAtWar_IsGroupAlive(g) then
            pcall(function() g:Destroy() end)
        end
    end
end

--- Call when a zone is captured. Removes previous owner's attacking reinforcements; adds their count back to source factory.
--- If the captured zone is an airfield, reinforcements despawn after ReinforcementAirfieldDespawnSec (tunable).
function NationsAtWar_OnZoneCaptured(zoneName, previousOwner)
    if not zoneName or not previousOwner then return end
    NationsAtWar_ReinforcementActiveGroups = NationsAtWar_ReinforcementActiveGroups or {}
    NationsAtWar_ReinforcementSourceFactory = NationsAtWar_ReinforcementSourceFactory or {}
    local groups = NationsAtWar_ReinforcementActiveGroups[zoneName] and NationsAtWar_ReinforcementActiveGroups[zoneName][previousOwner]
    local factoryName = NationsAtWar_ReinforcementSourceFactory[zoneName] and NationsAtWar_ReinforcementSourceFactory[zoneName][previousOwner]
    local count = (groups and type(groups) == "table") and #groups or 0
    -- Clear state so this faction can send new reinforcements to other zones
    if NationsAtWar_ReinforcementActiveGroups[zoneName] then
        NationsAtWar_ReinforcementActiveGroups[zoneName][previousOwner] = nil
    end
    if NationsAtWar_ReinforcementSourceFactory[zoneName] then
        NationsAtWar_ReinforcementSourceFactory[zoneName][previousOwner] = nil
    end
    if count == 0 then return end
    local cfg = NationsAtWarConfig
    local isAirfield = cfg and zoneInList(zoneName, cfg.AirfieldZones)
    if isAirfield then
        local despawnSec = (cfg and type(cfg.ReinforcementAirfieldDespawnSec) == "number" and cfg.ReinforcementAirfieldDespawnSec >= 0) and cfg.ReinforcementAirfieldDespawnSec or 600
        if timer and timer.scheduleFunction and timer.getTime then
            timer.scheduleFunction(function()
                destroyReinforcementGroups(groups)
                if factoryName and NationsAtWar_AddFactoryTankCount and cfg and zoneInList(factoryName, cfg.FactoryZones) then
                    NationsAtWar_AddFactoryTankCount(factoryName, count)
                end
                if NationsAtWar_Log then
                    NationsAtWar_Log("info", "Reinforcements: [%s] %s despawned after %d s (airfield captured), %d count returned to factory [%s]", zoneName, previousOwner, despawnSec, count, factoryName or "?")
                end
            end, nil, timer.getTime() + despawnSec)
        else
            destroyReinforcementGroups(groups)
            if factoryName and NationsAtWar_AddFactoryTankCount and cfg and zoneInList(factoryName, cfg.FactoryZones) then
                NationsAtWar_AddFactoryTankCount(factoryName, count)
            end
        end
    else
        destroyReinforcementGroups(groups)
        if factoryName and NationsAtWar_AddFactoryTankCount and cfg and zoneInList(factoryName, cfg.FactoryZones) then
            NationsAtWar_AddFactoryTankCount(factoryName, count)
        end
        if NationsAtWar_Log then
            NationsAtWar_Log("info", "Reinforcements: [%s] %s removed on capture, %d count returned to factory [%s]", zoneName, previousOwner, count, factoryName or "?")
        end
    end
end
