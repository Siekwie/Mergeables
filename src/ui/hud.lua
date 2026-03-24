local util = require("src.util")
local Economy = require("src.economy")
local Button = require("src.ui.button")

local HUD = {}
HUD.__index = HUD

function HUD.new()
    local self = setmetatable({}, HUD)
    self.displayMoney = 0
    self.tabs = {"Inventory", "Upgrades", "Prestige"}
    self.activeTab = nil
    self.tabButtons = {}
    self.onTabClick = nil  -- callback(tabName)
    self.onResetZoom = nil  -- callback()
    self.onTogglePanel = nil  -- callback()
    self.fullscreenBtn = nil
    self.resetZoomBtn = nil
    self.togglePanelBtn = nil
    self:rebuildButtons()
    return self
end

function HUD:rebuildButtons()
    self.tabButtons = {}
    local sw = util.screenW()
    local btnW = 90
    local btnH = 30
    local startX = sw - (#self.tabs * (btnW + 8)) - 50
    local y = 10

    for i, tab in ipairs(self.tabs) do
        local x = startX + (i - 1) * (btnW + 8)
        local btn = Button.new({
            x = x, y = y, w = btnW, h = btnH,
            text = tab,
            color = {0.25, 0.45, 0.30},
            onClick = function()
                if self.onTabClick then
                    self.onTabClick(tab)
                end
            end,
        })
        self.tabButtons[i] = btn
    end

    -- Fullscreen button
    self.fullscreenBtn = Button.new({
        x = sw - 40, y = 10, w = 30, h = 30,
        text = "F",
        color = {0.30, 0.30, 0.35},
        onClick = function()
            local isFs = love.window.getFullscreen()
            love.window.setFullscreen(not isFs, "desktop")
        end,
    })

    -- Reset Zoom button (left side, after info)
    self.resetZoomBtn = Button.new({
        x = 16, y = 10, w = 60, h = 30,
        text = "Fit",
        color = {0.30, 0.35, 0.50},
        onClick = function()
            if self.onResetZoom then
                self.onResetZoom()
            end
        end,
    })

    -- Toggle Panel button (just before tab buttons)
    self.togglePanelBtn = Button.new({
        x = startX - 40, y = 10, w = 30, h = 30,
        text = ">",
        color = {0.35, 0.35, 0.40},
        onClick = function()
            if self.onTogglePanel then
                self.onTogglePanel()
            end
        end,
    })
end

function HUD:update(dt, game, mx, my)
    -- Smooth money display
    local target = game.money
    local diff = target - self.displayMoney
    if math.abs(diff) < 1 then
        self.displayMoney = target
    else
        self.displayMoney = self.displayMoney + diff * math.min(1, dt * 8)
    end

    -- Rebuild buttons if screen resized
    local sw = util.screenW()
    local expectedX = sw - (#self.tabs * 98) - 50
    if #self.tabButtons > 0 and math.abs(self.tabButtons[1].x - expectedX) > 5 then
        self:rebuildButtons()
    end

    for _, btn in ipairs(self.tabButtons) do
        btn:update(mx, my)
    end
    self.fullscreenBtn:update(mx, my)
    self.resetZoomBtn:update(mx, my)
    self.togglePanelBtn:update(mx, my)

    -- Update toggle panel button text
    if game.panelVisible then
        self.togglePanelBtn.text = ">"
    else
        self.togglePanelBtn.text = "<"
    end
end

function HUD:draw(game)
    local sw = util.screenW()

    -- HUD background
    love.graphics.setColor(0.08, 0.08, 0.10, 1.0)
    love.graphics.rectangle("fill", 0, 0, sw, 50)
    love.graphics.setColor(0.45, 0.65, 0.40, 0.5)
    love.graphics.rectangle("fill", 0, 49, sw, 1)

    -- Money
    love.graphics.setColor(0.30, 0.85, 0.35)
    love.graphics.print(Economy.formatMoney(self.displayMoney), 90, 14)

    -- Animal count
    local maxAnimals = game:getMaxAnimals()
    local count = #game.animals
    love.graphics.setColor(0.85, 0.85, 0.80)
    love.graphics.print("Animals: " .. count .. "/" .. maxAnimals, 250, 14)

    -- Prestige points
    if game.prestige.totalEarnedPoints > 0 then
        love.graphics.setColor(1, 0.85, 0.25)
        love.graphics.print("Stars: " .. game.prestige.points, 420, 14)
    end

    -- Reset Zoom button
    self.resetZoomBtn:draw()

    -- Tab buttons
    for i, btn in ipairs(self.tabButtons) do
        if self.activeTab == self.tabs[i] then
            btn.color = {0.40, 0.65, 0.40}
        else
            btn.color = {0.25, 0.45, 0.30}
        end
        btn:draw()
    end

    -- Toggle Panel button
    self.togglePanelBtn:draw()

    -- Fullscreen button
    self.fullscreenBtn:draw()
end

function HUD:mousepressed(x, y, button)
    if button ~= 1 then return false end
    for _, btn in ipairs(self.tabButtons) do
        if btn:click() then return true end
    end
    if self.fullscreenBtn:click() then return true end
    if self.resetZoomBtn:click() then return true end
    if self.togglePanelBtn:click() then return true end
    return false
end

function HUD:containsPoint(px, py)
    return py < 50
end

return HUD
