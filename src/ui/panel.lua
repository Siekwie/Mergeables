local util = require("src.util")

local Panel = {}
Panel.__index = Panel

function Panel.new(opts)
    local self = setmetatable({}, Panel)
    self.title = opts.title or "Panel"
    self.visible = opts.visible or false
    self.bgColor = opts.bgColor or {0.12, 0.12, 0.15, 1.0}
    self.titleColor = opts.titleColor or {0.95, 0.90, 0.70}
    self.scrollY = 0
    self.maxScrollY = 0
    self.contentHeight = 0
    return self
end

function Panel:getRect()
    local sw = util.screenW()
    local sh = util.screenH()
    local w = math.floor(sw * 0.30)
    local x = sw - w
    local y = 50  -- below HUD
    local h = sh - y
    return x, y, w, h
end

function Panel:show()
    self.visible = true
    self.scrollY = 0
end

function Panel:hide()
    self.visible = false
end

function Panel:toggle()
    if self.visible then self:hide() else self:show() end
end

function Panel:drawBackground()
    if not self.visible then return end
    local x, y, w, h = self:getRect()

    -- Background
    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", x, y, w, h, 0, 0)

    -- Left border accent
    love.graphics.setColor(0.45, 0.65, 0.40, 0.6)
    love.graphics.rectangle("fill", x, y, 3, h)

    -- Title bar
    love.graphics.setColor(0.08, 0.08, 0.10, 1.0)
    love.graphics.rectangle("fill", x, y, w, 36)
    love.graphics.setColor(self.titleColor)
    local font = love.graphics.getFont()
    love.graphics.print(self.title, x + 12, y + 8)
end

function Panel:setContentHeight(height)
    local _, _, _, h = self:getRect()
    local viewH = h - 44  -- minus title bar + padding
    self.contentHeight = height
    self.maxScrollY = math.max(0, height - viewH)
end

function Panel:getContentArea()
    local x, y, w, h = self:getRect()
    return x + 8, y + 44, w - 16, h - 52
end

function Panel:scroll(amount)
    self.scrollY = util.clamp(self.scrollY - amount * 30, 0, self.maxScrollY)
end

function Panel:containsPoint(px, py)
    if not self.visible then return false end
    local x, y, w, h = self:getRect()
    return util.pointInRect(px, py, x, y, w, h)
end

return Panel
