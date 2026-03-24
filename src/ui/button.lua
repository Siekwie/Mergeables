local util = require("src.util")

local Button = {}
Button.__index = Button

function Button.new(opts)
    local self = setmetatable({}, Button)
    self.x = opts.x or 0
    self.y = opts.y or 0
    self.w = opts.w or 160
    self.h = opts.h or 40
    self.text = opts.text or "Button"
    self.onClick = opts.onClick or function() end
    self.enabled = true
    self.hovered = false
    self.color = opts.color or {0.30, 0.55, 0.35}
    self.disabledColor = opts.disabledColor or {0.22, 0.22, 0.24}
    self.textColor = opts.textColor or {1, 1, 1}
    self.cornerRadius = opts.cornerRadius or 6
    self.fontSize = opts.fontSize or nil
    self.subText = opts.subText or nil
    self.customDraw = opts.customDraw or nil
    return self
end

function Button:setPosition(x, y)
    self.x = x
    self.y = y
end

function Button:update(mx, my)
    self.hovered = util.pointInRect(mx, my, self.x, self.y, self.w, self.h)
end

function Button:draw()
    local color = self.enabled and self.color or self.disabledColor
    local alpha = self.enabled and 1 or 0.5

    local r, g, b = color[1], color[2], color[3]
    if self.hovered and self.enabled then
        r, g, b = r + 0.08, g + 0.08, b + 0.08
    end

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.25 * alpha)
    love.graphics.rectangle("fill", self.x, self.y + 2, self.w, self.h, self.cornerRadius, self.cornerRadius)

    -- Main body
    love.graphics.setColor(r, g, b, alpha)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, self.cornerRadius, self.cornerRadius)

    -- Top highlight (subtle gradient feel)
    love.graphics.setColor(1, 1, 1, 0.06 * alpha)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h * 0.45, self.cornerRadius, self.cornerRadius)

    -- Bottom edge darken
    love.graphics.setColor(0, 0, 0, 0.10 * alpha)
    love.graphics.rectangle("fill", self.x, self.y + self.h * 0.7, self.w, self.h * 0.3, 0, 0, self.cornerRadius, self.cornerRadius)

    -- Custom draw callback (for icons)
    if self.customDraw then
        self.customDraw(self)
        return
    end

    -- Text
    local font = love.graphics.getFont()
    love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], alpha)

    if self.subText then
        local textY = self.y + self.h * 0.15
        love.graphics.printf(self.text, self.x + 4, textY, self.w - 8, "center")
        love.graphics.setColor(self.textColor[1] * 0.8, self.textColor[2] * 0.8, self.textColor[3] * 0.8, alpha * 0.7)
        love.graphics.printf(self.subText, self.x + 4, textY + font:getHeight() + 2, self.w - 8, "center")
    else
        local textW = font:getWidth(self.text)
        local textH = font:getHeight()
        love.graphics.print(self.text, self.x + (self.w - textW) / 2, self.y + (self.h - textH) / 2)
    end
end

function Button:click()
    if self.enabled and self.hovered then
        self.onClick()
        return true
    end
    return false
end

function Button:containsPoint(px, py)
    return util.pointInRect(px, py, self.x, self.y, self.w, self.h)
end

return Button
