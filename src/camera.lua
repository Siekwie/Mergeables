local util = require("src.util")

local Camera = {}
Camera.__index = Camera

function Camera.new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.scale = 1
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

    -- Clamp to world bounds
    local sw, sh = util.screenW(), util.screenH()
    local panelW = sw * 0.30
    local viewW = (sw - panelW) / self.scale
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
