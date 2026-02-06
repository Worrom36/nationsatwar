-- Nations at War - Digit drawing (seven-segment lines). Queue lives in Zones.lua.
-- Depends: Zones (GetZoneHealth, GetZoneCoord), CapturableZones (GetZoneOwner), Config.

NationsAtWar_NextLineId = NationsAtWar_NextLineId or 1000
NationsAtWar_TwoDigitsLineCount = 14
NationsAtWar_OneDigitLineCount = 7

-- Seven-segment geometry: each segment { lx1, lz1, lx2, lz2 } in local digit space (-0.5..0.5).
-- a=top, b=top-right, c=bottom-right, d=bottom, e=bottom-left, f=top-left, g=middle.
local SEGMENT_COORDS = {
    { -0.5, 0.5, 0.5, 0.5 },   -- a
    { 0.5, 0.5, 0.5, 0 },      -- b
    { 0.5, 0, 0.5, -0.5 },     -- c
    { -0.5, -0.5, 0.5, -0.5 }, -- d
    { -0.5, 0, -0.5, -0.5 },   -- e
    { -0.5, 0.5, -0.5, 0 },    -- f
    { -0.5, 0, 0.5, 0 },       -- g
}
local DIGIT_PATTERNS = {
    [0] = { 1, 2, 3, 4, 5, 6 },
    [1] = { 2, 3 },
    [2] = { 1, 2, 4, 5, 7 },
    [3] = { 1, 2, 3, 4, 7 },
    [4] = { 2, 3, 6, 7 },
    [5] = { 1, 3, 4, 6, 7 },
    [6] = { 1, 3, 4, 5, 6, 7 },
    [7] = { 1, 2, 3 },
    [8] = { 1, 2, 3, 4, 5, 6, 7 },
    [9] = { 1, 2, 3, 4, 6, 7 },
}

local function drawOneDigit(cx, cy, cz, digit, scale, xOffset, lineColor, coalition, lineType, readonly, idRef)
    local pattern = DIGIT_PATTERNS[digit]
    if not pattern then return end
    for _, segIdx in ipairs(pattern) do
        local seg = SEGMENT_COORDS[segIdx]
        if seg then
            local id
            if idRef and type(idRef.id) == "number" then
                id = idRef.id
                idRef.id = id + 1
            else
                NationsAtWar_NextLineId = NationsAtWar_NextLineId or 1000
                id = NationsAtWar_NextLineId
                NationsAtWar_NextLineId = id + 1
            end
            local lx1, lz1, lx2, lz2 = seg[1] + xOffset, seg[2], seg[3] + xOffset, seg[4]
            local startPoint = { x = cx + lz1 * scale, y = cy, z = cz + lx1 * scale }
            local endPoint   = { x = cx + lz2 * scale, y = cy, z = cz + lx2 * scale }
            pcall(trigger.action.lineToAll, coalition, id, startPoint, endPoint, lineColor, lineType, readonly, "")
        end
    end
end

--- Draw two digits (00-99) at coord. value = 0-99; scaleMeters = size per digit (default 100).
function NationsAtWar_DrawTwoDigitsAtCoord(coord, value, scaleMeters, opts, startId)
    if not coord or not coord.GetVec3 then return end
    if not trigger or not trigger.action or not trigger.action.lineToAll then return end
    NationsAtWar_NextLineId = NationsAtWar_NextLineId or 1000
    opts = opts or {}
    local scale = (type(scaleMeters) == "number" and scaleMeters > 0) and scaleMeters or 100
    local v = coord:GetVec3()
    local cx, cy, cz = v.x or 0, v.y or 0, v.z or 0
    local color = opts.color or { 1, 1, 1 }
    local r, g, b = color[1] or 1, color[2] or 1, color[3] or 1
    local lineColor = { r, g, b, opts.alpha or 1 }
    local coalition = opts.coalition or -1
    local lineType = opts.lineType or 1
    local readonly = opts.readonly ~= false
    local n = math.floor(tonumber(value) or 0)
    if n < 0 then n = 0 elseif n > 99 then n = 99 end
    if NationsAtWar_Log then
        NationsAtWar_Log("info", "DrawTwoDigitsAtCoord: value %s", tostring(n))
    end
    -- Always two digits: 01, 02, ... 09 for n<10; tens=0 for single-digit values.
    local tens = math.floor(n / 10)
    local ones = n % 10
    local digitWidth = 1.2
    local idRef = (type(startId) == "number" and startId >= 0) and { id = startId } or nil
    drawOneDigit(cx, cy, cz, tens, scale, -digitWidth / 2, lineColor, coalition, lineType, readonly, idRef)
    drawOneDigit(cx, cy, cz, ones, scale, digitWidth / 2, lineColor, coalition, lineType, readonly, idRef)
end

--- Draw one digit (0-9) at coord.
function NationsAtWar_DrawOneDigitAtCoord(coord, value, scaleMeters, opts, startId)
    if not coord or not coord.GetVec3 then return end
    if not trigger or not trigger.action or not trigger.action.lineToAll then return end
    NationsAtWar_NextLineId = NationsAtWar_NextLineId or 1000
    opts = opts or {}
    local scale = (type(scaleMeters) == "number" and scaleMeters > 0) and scaleMeters or 100
    local v = coord:GetVec3()
    local cx, cy, cz = v.x or 0, v.y or 0, v.z or 0
    local color = opts.color or { 1, 1, 1 }
    local r, g, b = color[1] or 1, color[2] or 1, color[3] or 1
    local lineColor = { r, g, b, opts.alpha or 1 }
    local coalition = opts.coalition or -1
    local lineType = opts.lineType or 1
    local readonly = opts.readonly ~= false
    local n = math.floor(tonumber(value) or 0)
    if n < 0 then n = 0 elseif n > 9 then n = 9 end
    local idRef = (type(startId) == "number" and startId >= 0) and { id = startId } or nil
    drawOneDigit(cx, cy, cz, n, scale, 0, lineColor, coalition, lineType, readonly, idRef)
end

--- Draw digit "8" at coord (single 8).
function NationsAtWar_DrawDigit8AtCoord(coord, scaleMeters, opts)
    NationsAtWar_DrawOneDigitAtCoord(coord, 8, scaleMeters, opts)
end
