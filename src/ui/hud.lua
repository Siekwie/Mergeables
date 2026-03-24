local util = require("src.util")
local Economy = require("src.economy")
local Button = require("src.ui.button")

local HUD = {}
HUD.__index = HUD

-- Draw a simple gear icon
local function drawGear(cx, cy, r)
    local teeth = 6
    love.graphics.setColor(0.85, 0.85, 0.82)
    -- Outer ring with teeth
    for i = 0, teeth - 1 do
        local angle = (i / teeth) * math.pi * 2
        local tx = cx + math.cos(angle) * r
        local ty = cy + math.sin(angle) * r
        love.graphics.circle("fill", tx, ty, r * 0.35)
    end
    -- Center circle
    love.graphics.circle("fill", cx, cy, r * 0.55)
    -- Inner hole
    love.graphics.setColor(0.25, 0.28, 0.32)
    love.graphics.circle("fill", cx, cy, r * 0.22)
end

function HUD.new()
    local self = setmetatable({}, HUD)
    self.displayMoney = 0
    self.tabs = {"Inventory", "Upgrades", "Prestige"}
    self.activeTab = nil
    self.tabButtons = {}
    self.onTabClick = nil
    self.onResetZoom = nil
    self.onTogglePanel = nil
    self.resetZoomBtn = nil
    self.togglePanelBtn = nil
    self.settingsBtn = nil
    self:rebuildButtons()
    return self
end

function HUD:rebuildButtons()
    self.tabButtons = {}
    local sw = util.screenW()
    local btnW = 90
    local btnH = 30
    local startX = sw - (#self.tabs * (btnW + 6)) - 46
    local y = 10

    for i, tab in ipairs(self.tabs) do
        local x = startX + (i - 1) * (btnW + 6)
        local btn = Button.new({
            x = x, y = y, w = btnW, h = btnH,
            text = tab,
            color = {0.22, 0.38, 0.28},
            cornerRadius = 5,
            onClick = function()
                if self.onTabClick then
                    self.onTabClick(tab)
                end
            end,
        })
        self.tabButtons[i] = btn
    end

    -- Settings button (gear icon, right edge)
    self.settingsBtn = Button.new({
        x = sw - 40, y = 10, w = 30, h = 30,
        text = "",
        color = {0.25, 0.28, 0.32},
        cornerRadius = 5,
        customDraw = function(btn)
            drawGear(btn.x + btn.w / 2, btn.y + btn.h / 2, 7)
        end,
        onClick = function()
            if self.onTabClick then
                self.onTabClick("Settings")
            end
        end,
    })

    -- Reset Zoom button
    self.resetZoomBtn = Button.new({
        x = 16, y = 12, w = 50, h = 26,
        text = "Fit",
        color = {0.22, 0.28, 0.38},
        cornerRadius = 4,
        onClick = function()
            if self.onResetZoom then
                self.onResetZoom()
            end
        end,
    })

    -- Toggle Panel button
    self.togglePanelBtn = Button.new({
        x = startX - 36, y = 10, w = 28, h = 30,
        text = ">",
        color = {0.25, 0.25, 0.30},
        cornerRadius = 5,
        onClick = function()
            if self.onTogglePanel then
                self.onTogglePanel()
            end
        end,
    })
end

function HUD:update(dt, game, mx, my)
    local target = game.money
    local diff = target - self.displayMoney
    if math.abs(diff) < 1 then
        self.displayMoney = target
    else
        self.displayMoney = self.displayMoney + diff * math.min(1, dt * 8)
    end

    local sw = util.screenW()
    local expectedX = sw - (#self.tabs * 96) - 46
    if #self.tabButtons > 0 and math.abs(self.tabButtons[1].x - expectedX) > 5 then
        self:rebuildButtons()
    end

    for _, btn in ipairs(self.tabButtons) do
        btn:update(mx, my)
    end
    self.settingsBtn:update(mx, my)
    self.resetZoomBtn:update(mx, my)
    self.togglePanelBtn:update(mx, my)

    if game.panelVisible then
        self.togglePanelBtn.text = ">"
    else
        self.togglePanelBtn.text = "<"
    end
end

function HUD:draw(game)
    local sw = util.screenW()

    -- HUD background
    love.graphics.setColor(0.09, 0.09, 0.11, 1.0)
    love.graphics.rectangle("fill", 0, 0, sw, 50)
    -- Bottom accent
    love.graphics.setColor(0.35, 0.50, 0.35, 0.4)
    love.graphics.rectangle("fill", 0, 49, sw, 1)

    -- Money
    love.graphics.setColor(0.35, 0.88, 0.40)
    love.graphics.print(Economy.formatMoney(self.displayMoney), 80, 14)

    -- Animal count
    local maxAnimals = game:getMaxAnimals()
    local count = #game.animals
    love.graphics.setColor(0.78, 0.78, 0.75)
    love.graphics.print("Animals: " .. count .. "/" .. maxAnimals, 220, 14)

    -- Prestige currencies
    local px = 380
    local t1 = game.prestige.tiers[1]
    if t1.totalEarned > 0 or t1.points > 0 then
        love.graphics.setColor(1, 0.85, 0.25)
        love.graphics.print("*" .. t1.points, px, 14)
        px = px + 50
    end
    local t2 = game.prestige.tiers[2]
    if t2.totalEarned > 0 or t2.points > 0 then
        love.graphics.setColor(0.60, 0.45, 0.90)
        love.graphics.print("^" .. t2.points, px, 14)
        px = px + 50
    end
    local t3 = game.prestige.tiers[3]
    if t3.totalEarned > 0 or t3.points > 0 then
        love.graphics.setColor(0.40, 0.85, 0.95)
        love.graphics.print("<>" .. t3.points, px, 14)
    end

    -- Reset Zoom button
    self.resetZoomBtn:draw()

    -- Tab buttons
    for i, btn in ipairs(self.tabButtons) do
        if self.activeTab == self.tabs[i] then
            btn.color = {0.32, 0.52, 0.35}
        else
            btn.color = {0.22, 0.38, 0.28}
        end
        btn:draw()
    end

    -- Toggle Panel button
    self.togglePanelBtn:draw()

    -- Settings button
    if self.activeTab == "Settings" then
        self.settingsBtn.color = {0.35, 0.38, 0.42}
    else
        self.settingsBtn.color = {0.25, 0.28, 0.32}
    end
    self.settingsBtn:draw()
end

function HUD:mousepressed(x, y, button)
    if button ~= 1 then return false end
    for _, btn in ipairs(self.tabButtons) do
        if btn:click() then return true end
    end
    if self.settingsBtn:click() then return true end
    if self.resetZoomBtn:click() then return true end
    if self.togglePanelBtn:click() then return true end
    return false
end

function HUD:containsPoint(px, py)
    return py < 50
end

return HUD
