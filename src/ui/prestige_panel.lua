local Panel = require("src.ui.panel")
local Button = require("src.ui.button")
local Economy = require("src.economy")
local util = require("src.util")

local prestigeData = require("data.prestige_data")

local PrestigePanel = {}
PrestigePanel.__index = PrestigePanel
setmetatable(PrestigePanel, { __index = Panel })

function PrestigePanel.new()
    local self = Panel.new({ title = "PRESTIGE" })
    setmetatable(self, PrestigePanel)
    self.activeTier = 1
    self.tierButtons = {}
    self.upgradeButtons = {}
    self.prestigeButton = nil
    return self
end

function PrestigePanel:buildContent(game)
    self.upgradeButtons = {}
    self.tierButtons = {}
    local cx, cy, cw, ch = self:getContentArea()

    -- Tier sub-tabs
    local tabW = math.floor((cw - 8) / 3)
    for t = 1, 3 do
        local tierData = prestigeData[t]
        local pts = game.prestige.tiers[t].points
        local label = tierData.name .. " (" .. pts .. ")"
        local btn = Button.new({
            x = cx + (t - 1) * (tabW + 4),
            y = cy - self.scrollY,
            w = tabW,
            h = 26,
            text = label,
            color = t == self.activeTier
                and {tierData.color[1] * 0.6, tierData.color[2] * 0.6, tierData.color[3] * 0.6}
                or {0.22, 0.22, 0.25},
            cornerRadius = 4,
            onClick = function()
                self.activeTier = t
                self.scrollY = 0
            end,
        })
        table.insert(self.tierButtons, btn)
    end

    local y = 34
    local tier = self.activeTier
    local tierData = prestigeData[tier]
    local prestige = game.prestige

    -- Pending points display
    local pendingPoints = 0
    if tier == 1 then
        pendingPoints = Economy.calcPrestigePoints(game.totalEarned)
        local bonus = prestige:getT1CurrencyBonus()
        if bonus > 0 then
            pendingPoints = math.floor(pendingPoints * (1 + bonus))
        end
    elseif tier == 2 then
        pendingPoints = Economy.calcT2Points(prestige.tiers[1].totalEarned)
        local bonus = prestige:getT2CurrencyBonus()
        if bonus > 0 then
            pendingPoints = math.floor(pendingPoints * (1 + bonus))
        end
    elseif tier == 3 then
        pendingPoints = Economy.calcT3Points(prestige.tiers[2].totalEarned)
    end

    -- Prestige reset button
    self.prestigeButton = Button.new({
        x = cx,
        y = cy + y - self.scrollY,
        w = cw,
        h = 50,
        text = "PRESTIGE (+" .. pendingPoints .. " " .. tierData.name .. ")",
        subText = tierData.resetLabel,
        color = {tierData.color[1] * 0.7, tierData.color[2] * 0.7, tierData.color[3] * 0.7},
        onClick = function()
            if pendingPoints > 0 then
                if tier == 1 then
                    game:doPrestigeT1()
                elseif tier == 2 then
                    game:doPrestigeT2()
                elseif tier == 3 then
                    game:doPrestigeT3()
                end
            end
        end,
    })
    self.prestigeButton.enabled = pendingPoints > 0
    y = y + 60

    -- Upgrades list
    for _, upg in ipairs(tierData.upgrades) do
        local level = prestige:getLevel(tier, upg.id)
        local atMax = level >= upg.maxLevel
        local cost = prestige:getUpgradeCost(tier, upg.id)
        local canBuy = prestige:canBuyUpgrade(tier, upg.id)

        local statusText
        if atMax then
            statusText = "MAX"
        else
            statusText = "Cost: " .. cost .. " " .. tierData.name
        end

        local levelText = ""
        if upg.maxLevel > 1 then
            levelText = " [" .. level .. "/" .. upg.maxLevel .. "]"
        elseif level >= 1 then
            levelText = " [OWNED]"
        end

        local desc = upg.description:gsub("%%%%", "%%")
        if upg.effect.perLevel and upg.maxLevel > 1 then
            local totalEffect = upg.effect.perLevel * level
            if upg.effect.type == "starting_money" then
                desc = desc .. " (total: $" .. math.floor(totalEffect) .. ")"
            elseif upg.effect.type == "extra_capacity" then
                desc = desc .. " (total: +" .. math.floor(totalEffect) .. ")"
            elseif upg.effect.type == "starting_t1_currency" or upg.effect.type == "starting_t2_currency" then
                desc = desc .. " (total: +" .. math.floor(totalEffect) .. ")"
            else
                desc = desc .. " (total: +" .. math.floor(totalEffect * 100) .. "%)"
            end
        end

        local btn = Button.new({
            x = cx,
            y = cy + y - self.scrollY,
            w = cw,
            h = 52,
            text = upg.name .. levelText,
            subText = desc .. " | " .. statusText,
            color = atMax and {0.20, 0.45, 0.25} or (canBuy and {0.35, 0.35, 0.50} or {0.22, 0.22, 0.25}),
            cornerRadius = 4,
            onClick = function()
                prestige:buyUpgrade(tier, upg.id)
            end,
        })
        btn.enabled = canBuy
        table.insert(self.upgradeButtons, btn)
        y = y + 58
    end

    self:setContentHeight(y)
end

function PrestigePanel:update(mx, my, game)
    if not self.visible then return end
    self:buildContent(game)
    for _, btn in ipairs(self.tierButtons) do
        btn:update(mx, my)
    end
    if self.prestigeButton then
        self.prestigeButton:update(mx, my)
    end
    for _, btn in ipairs(self.upgradeButtons) do
        btn:update(mx, my)
    end
end

function PrestigePanel:draw()
    if not self.visible then return end
    self:drawBackground()

    local cx, cy, cw, ch = self:getContentArea()
    love.graphics.setScissor(cx - 4, cy - 4, cw + 8, ch + 8)

    -- Tier tabs
    for _, btn in ipairs(self.tierButtons) do
        btn:draw()
    end

    -- Prestige button
    if self.prestigeButton then
        self.prestigeButton:draw()
    end

    -- Upgrade buttons
    for _, btn in ipairs(self.upgradeButtons) do
        btn:draw()
    end

    love.graphics.setScissor()

    -- Scroll indicators
    if self.scrollY > 0 then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.polygon("fill", cx + cw/2 - 8, cy - 2, cx + cw/2 + 8, cy - 2, cx + cw/2, cy - 10)
    end
    if self.scrollY < self.maxScrollY then
        love.graphics.setColor(1, 1, 1, 0.5)
        local by = cy + ch
        love.graphics.polygon("fill", cx + cw/2 - 8, by + 2, cx + cw/2 + 8, by + 2, cx + cw/2, by + 10)
    end
end

function PrestigePanel:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then return false end
    for _, btn in ipairs(self.tierButtons) do
        if btn:click() then return true end
    end
    if self.prestigeButton and self.prestigeButton:click() then
        return true
    end
    for _, btn in ipairs(self.upgradeButtons) do
        if btn:click() then return true end
    end
    return self:containsPoint(x, y)
end

function PrestigePanel:wheelmoved(x, y, wx, wy)
    if not self.visible then return false end
    if self:containsPoint(x, y) then
        self:scroll(wy)
        return true
    end
    return false
end

return PrestigePanel
