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

    -- Clamp to world bounds
    local sw, sh = util.screenW(), util.screenH()
    local viewW = sw / self.scale
    local viewH = sh / self.scale
    self.x = util.clamp(self.x, 0, math.max(0, worldW - viewW))
    self.y = util.clamp(self.y, 0, math.max(0, worldH - viewH))
    self.targetX = util.clamp(self.targetX, 0, math.max(0, worldW - viewW))
    self.targetY = util.clamp(self.targetY, 0, math.max(0, worldH - viewH))
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
    -- Fit the entire field in view
    local sw, sh = util.screenW(), util.screenH()
    local scaleX = sw / worldW
    local scaleY = sh / worldH
    self.targetScale = math.min(scaleX, scaleY, 1.0)
    self.targetX = 0
    self.targetY = 0
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
