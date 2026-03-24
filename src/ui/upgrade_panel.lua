local Panel = require("src.ui.panel")
local Button = require("src.ui.button")
local Economy = require("src.economy")

local UpgradePanel = {}
UpgradePanel.__index = UpgradePanel
setmetatable(UpgradePanel, { __index = Panel })

function UpgradePanel.new()
    local self = Panel.new({ title = "UPGRADES" })
    setmetatable(self, UpgradePanel)
    self.buttons = {}
    return self
end

function UpgradePanel:buildButtons(game)
    self.buttons = {}
    local cx, cy, cw, ch = self:getContentArea()
    local y = 0
    local upgradesData = game.upgrades:getAllData()

    for _, ud in ipairs(upgradesData) do
        local level = game.upgrades:getLevel(ud.id)
        local cost = game.upgrades:getCost(ud.id)
        local canBuy = game.upgrades:canBuy(ud.id, game.money)
        local atMax = level >= ud.maxLevel
        local effectText = string.format(ud.description, ud.effectPerLevel * level)

        local costText = atMax and "MAX" or Economy.formatMoney(cost)
        local btn = Button.new({
            x = cx,
            y = cy + y - self.scrollY,
            w = cw,
            h = 65,
            text = ud.name .. " (Lv " .. level .. "/" .. ud.maxLevel .. ")",
            subText = effectText .. " | " .. costText,
            color = atMax and {0.45, 0.40, 0.15} or {0.25, 0.40, 0.55},
            onClick = function()
                if game.upgrades:canBuy(ud.id, game.money) then
                    local c = game.upgrades:buy(ud.id)
                    game:spendMoney(c)
                    game:applyUpgrades()
                end
            end,
        })
        btn.enabled = canBuy and not atMax
        table.insert(self.buttons, btn)
        y = y + 72
    end

    self:setContentHeight(y)
end

function UpgradePanel:update(mx, my, game)
    if not self.visible then return end
    self:buildButtons(game)
    for _, btn in ipairs(self.buttons) do
        btn:update(mx, my)
    end
end

function UpgradePanel:draw()
    if not self.visible then return end
    self:drawBackground()

    local cx, cy, cw, ch = self:getContentArea()
    love.graphics.setScissor(cx - 4, cy - 4, cw + 8, ch + 8)

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end

    love.graphics.setScissor()
end

function UpgradePanel:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then return false end
    for _, btn in ipairs(self.buttons) do
        if btn:click() then return true end
    end
    return self:containsPoint(x, y)
end

function UpgradePanel:wheelmoved(x, y, wx, wy)
    if not self.visible then return false end
    if self:containsPoint(x, y) then
        self:scroll(wy)
        return true
    end
    return false
end

return UpgradePanel
