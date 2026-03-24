local util = require("src.util")

local Field = {}
Field.__index = Field

local TILE_SIZE = 64
local GRASS_COLORS = {
    {0.34, 0.60, 0.28},
    {0.36, 0.62, 0.30},
    {0.32, 0.58, 0.26},
    {0.38, 0.64, 0.32},
}

function Field.new(width, height)
    local self = setmetatable({}, Field)
    self.width = width or 2000
    self.height = height or 1500
    self.decorations = {}
    self:generateDecorations()
    -- Pre-generate grass tile colors
    self.grassMap = {}
    local cols = math.ceil(self.width / TILE_SIZE)
    local rows = math.ceil(self.height / TILE_SIZE)
    for r = 0, rows - 1 do
        self.grassMap[r] = {}
        for c = 0, cols - 1 do
            self.grassMap[r][c] = GRASS_COLORS[math.random(#GRASS_COLORS)]
        end
    end
    return self
end

function Field:resize(newW, newH)
    if newW == self.width and newH == self.height then return end
    self.width = newW
    self.height = newH
    self.decorations = {}
    self:generateDecorations()
    -- Regenerate grass map
    self.grassMap = {}
    local cols = math.ceil(self.width / TILE_SIZE)
    local rows = math.ceil(self.height / TILE_SIZE)
    for r = 0, rows - 1 do
        self.grassMap[r] = {}
        for c = 0, cols - 1 do
            self.grassMap[r][c] = GRASS_COLORS[math.random(#GRASS_COLORS)]
        end
    end
end

function Field:generateDecorations()
    -- Scatter bushes and rocks
    local types = {"bush", "rock", "flowers", "tree"}
    for i = 1, 35 do
        local dtype = types[math.random(#types)]
        local size = dtype == "tree" and math.random(80, 120) or math.random(20, 45)
        table.insert(self.decorations, {
            type = dtype,
            x = math.random(40, self.width - 40),
            y = math.random(40, self.height - 40),
            size = size,
            color = self:decorationColor(dtype),
        })
    end
    -- Sort by y for depth ordering
    table.sort(self.decorations, function(a, b) return a.y < b.y end)
end

function Field:decorationColor(dtype)
    if dtype == "bush" then
        return {0.22 + math.random() * 0.08, 0.50 + math.random() * 0.10, 0.18 + math.random() * 0.08}
    elseif dtype == "rock" then
        local g = 0.50 + math.random() * 0.15
        return {g, g, g * 0.95}
    elseif dtype == "flowers" then
        local colors = {{0.90, 0.40, 0.50}, {0.85, 0.70, 0.30}, {0.60, 0.40, 0.85}, {0.90, 0.60, 0.70}}
        return colors[math.random(#colors)]
    elseif dtype == "tree" then
        return {0.18 + math.random() * 0.06, 0.45 + math.random() * 0.10, 0.15 + math.random() * 0.06}
    end
    return {0.5, 0.5, 0.5}
end

function Field:draw()
    -- Draw grass tiles
    local cols = math.ceil(self.width / TILE_SIZE)
    local rows = math.ceil(self.height / TILE_SIZE)
    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            love.graphics.setColor(self.grassMap[r][c])
            love.graphics.rectangle("fill", c * TILE_SIZE, r * TILE_SIZE, TILE_SIZE, TILE_SIZE)
        end
    end

    -- Draw field border (fence)
    love.graphics.setColor(0.45, 0.30, 0.15)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", 2, 2, self.width - 4, self.height - 4)
    love.graphics.setLineWidth(1)
end

function Field:drawDecorations(yThreshold)
    -- Draw decorations that are above yThreshold (for depth sorting with animals)
    for _, d in ipairs(self.decorations) do
        if yThreshold == nil or d.y <= yThreshold then
            self:drawDecoration(d)
        end
    end
end

function Field:drawDecorationsAbove(yMin)
    for _, d in ipairs(self.decorations) do
        if d.y > yMin then
            self:drawDecoration(d)
        end
    end
end

function Field:drawDecoration(d)
    if d.type == "bush" then
        love.graphics.setColor(d.color)
        love.graphics.circle("fill", d.x, d.y, d.size * 0.6)
        love.graphics.setColor(d.color[1] + 0.05, d.color[2] + 0.05, d.color[3] + 0.05)
        love.graphics.circle("fill", d.x - d.size * 0.3, d.y - d.size * 0.1, d.size * 0.4)
        love.graphics.circle("fill", d.x + d.size * 0.3, d.y - d.size * 0.15, d.size * 0.45)
    elseif d.type == "rock" then
        love.graphics.setColor(d.color)
        love.graphics.ellipse("fill", d.x, d.y, d.size * 0.6, d.size * 0.4)
        love.graphics.setColor(d.color[1] + 0.08, d.color[2] + 0.08, d.color[3] + 0.08)
        love.graphics.ellipse("fill", d.x - d.size * 0.1, d.y - d.size * 0.1, d.size * 0.4, d.size * 0.25)
    elseif d.type == "flowers" then
        -- Stem
        love.graphics.setColor(0.25, 0.55, 0.20)
        love.graphics.setLineWidth(2)
        love.graphics.line(d.x, d.y, d.x, d.y - d.size * 0.5)
        love.graphics.setLineWidth(1)
        -- Petals
        love.graphics.setColor(d.color)
        local petalR = d.size * 0.2
        for a = 0, 4 do
            local angle = a * (math.pi * 2 / 5)
            love.graphics.circle("fill", d.x + math.cos(angle) * petalR, d.y - d.size * 0.5 + math.sin(angle) * petalR, petalR * 0.6)
        end
        love.graphics.setColor(1, 0.95, 0.40)
        love.graphics.circle("fill", d.x, d.y - d.size * 0.5, petalR * 0.35)
    elseif d.type == "tree" then
        -- Trunk
        love.graphics.setColor(0.45, 0.30, 0.15)
        love.graphics.rectangle("fill", d.x - d.size * 0.08, d.y - d.size * 0.3, d.size * 0.16, d.size * 0.4)
        -- Canopy
        love.graphics.setColor(d.color)
        love.graphics.circle("fill", d.x, d.y - d.size * 0.5, d.size * 0.4)
        love.graphics.setColor(d.color[1] + 0.04, d.color[2] + 0.04, d.color[3] + 0.04)
        love.graphics.circle("fill", d.x - d.size * 0.15, d.y - d.size * 0.6, d.size * 0.3)
        love.graphics.circle("fill", d.x + d.size * 0.2, d.y - d.size * 0.55, d.size * 0.28)
    end
end

return Field
