local util = {}

function util.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function util.lerp(a, b, t)
    return a + (b - a) * t
end

function util.clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function util.pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

function util.formatNumber(n)
    if n >= 1e15 then return string.format("%.2fQ", n / 1e15) end
    if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
    if n >= 1e9  then return string.format("%.2fB", n / 1e9) end
    if n >= 1e6  then return string.format("%.2fM", n / 1e6) end
    if n >= 1e3  then return string.format("%.1fK", n / 1e3) end
    return tostring(math.floor(n))
end

function util.randomFloat(min, max)
    return min + math.random() * (max - min)
end

function util.screenW()
    return love.graphics.getWidth()
end

function util.screenH()
    return love.graphics.getHeight()
end

-- Simple deep copy for tables
function util.deepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = util.deepCopy(v)
    end
    return copy
end

-- Simple table serialization for save/load
function util.serialize(val, indent)
    indent = indent or 0
    local pad = string.rep("  ", indent)
    if type(val) == "number" then
        return tostring(val)
    elseif type(val) == "string" then
        return string.format("%q", val)
    elseif type(val) == "boolean" then
        return tostring(val)
    elseif type(val) == "table" then
        local parts = {}
        local isArray = #val > 0
        table.insert(parts, "{\n")
        if isArray then
            for i, v in ipairs(val) do
                table.insert(parts, pad .. "  " .. util.serialize(v, indent + 1) .. ",\n")
            end
        else
            local keys = {}
            for k in pairs(val) do table.insert(keys, k) end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for _, k in ipairs(keys) do
                local key = type(k) == "string" and k:match("^[%a_][%w_]*$") and k or ("[" .. util.serialize(k) .. "]")
                table.insert(parts, pad .. "  " .. key .. " = " .. util.serialize(val[k], indent + 1) .. ",\n")
            end
        end
        table.insert(parts, pad .. "}")
        return table.concat(parts)
    end
    return "nil"
end

function util.deserialize(str)
    local code = str
    if not str:match("^%s*return%s") then
        code = "return " .. str
    end
    local fn, err = load(code)
    if fn then
        return fn()
    end
    return nil, err
end

return util
