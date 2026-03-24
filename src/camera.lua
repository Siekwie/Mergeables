local util = require("src.util")

local Camera = {}
Camera.__index = Camera

local MIN_SCALE = 0.3
local MAX_SCALE = 2.0

function Camera.new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.scale = 1
    self.targetScale = 1
    self.targetX = 0
    self.targetY = 0
    self.smoothing = 8
    self.dragStartX = nil
    self.dragStartY = nil
    self.camStartX = nil
    self.camStartY = nil
    return self
end

function Camera:update(dt, worldW, worldH)
    -- Smooth follow
    self.x = util.lerp(self.x, self.targetX, self.smoothing * dt)
    self.y = util.lerp(self.y, self.targetY, self.smoothing * dt)
    self.scale = util.lerp(self.scale, self.targetScale, self.smoothing * dt)

    -- Soft clamp: allow panning freely but keep at least half the field visible
    local sw, sh = util.screenW(), util.screenH()
    local viewW = sw / self.scale
    local viewH = sh / self.scale
    local margin = 200 / self.scale  -- extra margin so you don't lose the field
    local minX = -viewW * 0.5 + margin
    local minY = -viewH * 0.5 + margin
    local maxX = worldW - viewW * 0.5 - margin
    local maxY = worldH - viewH * 0.5 - margin

    -- If field is smaller than view, center it
    if maxX < minX then
        local center = worldW / 2 - viewW / 2
        minX = center
        maxX = center
    end
    if maxY < minY then
        local center = worldH / 2 - viewH / 2
        minY = center
        maxY = center
    end

    self.x = util.clamp(self.x, minX, maxX)
    self.y = util.clamp(self.y, minY, maxY)
    self.targetX = util.clamp(self.targetX, minX, maxX)
    self.targetY = util.clamp(self.targetY, minY, maxY)
end

function Camera:apply()
    love.graphics.push()
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-math.floor(self.x), -math.floor(self.y))
end

function Camera:release()
    love.graphics.pop()
end

function Camera:screenToWorld(sx, sy)
    return sx / self.scale + self.x, sy / self.scale + self.y
end

function Camera:worldToScreen(wx, wy)
    return (wx - self.x) * self.scale, (wy - self.y) * self.scale
end

function Camera:zoom(amount, mx, my)
    -- Zoom toward mouse position
    local wxBefore, wyBefore = self:screenToWorld(mx, my)

    local factor = 1 + amount * 0.1
    self.targetScale = util.clamp(self.targetScale * factor, MIN_SCALE, MAX_SCALE)

    -- Adjust target position to keep the point under cursor stable
    local newScale = self.targetScale
    self.targetX = wxBefore - mx / newScale
    self.targetY = wyBefore - my / newScale
end

function Camera:resetZoom(worldW, worldH)
    -- Fit the entire field in view, centered
    local sw, sh = util.screenW(), util.screenH()
    local scaleX = sw / worldW
    local scaleY = sh / worldH
    self.targetScale = math.min(scaleX, scaleY, 1.0)
    local viewW = sw / self.targetScale
    local viewH = sh / self.targetScale
    self.targetX = (worldW - viewW) / 2
    self.targetY = (worldH - viewH) / 2
end

function Camera:startDrag(mx, my)
    self.dragStartX = mx
    self.dragStartY = my
    self.camStartX = self.targetX
    self.camStartY = self.targetY
end

function Camera:drag(mx, my)
    if self.dragStartX then
        local dx = (self.dragStartX - mx) / self.scale
        local dy = (self.dragStartY - my) / self.scale
        self.targetX = self.camStartX + dx
        self.targetY = self.camStartY + dy
    end
end

function Camera:stopDrag()
    self.dragStartX = nil
    self.dragStartY = nil
end

function Camera:isDragging()
    return self.dragStartX ~= nil
end

return Camera
