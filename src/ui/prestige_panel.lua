local Panel = require("src.ui.panel")
local Button = require("src.ui.button")
local Economy = require("src.economy")

local PrestigePanel = {}
PrestigePanel.__index = PrestigePanel
setmetatable(PrestigePanel, { __index = Panel })

function PrestigePanel.new()
    local self = Panel.new({ title = "PRESTIGE - Skill Tree" })
    setmetatable(self, PrestigePanel)
    self.buttons = {}
    self.prestigeButton = nil
    return self
end

function PrestigePanel:buildButtons(game)
    self.buttons = {}
    local cx, cy, cw, ch = self:getContentArea()
    local y = 0

    -- Prestige info
    local pendingPoints = Economy.calcPrestigePoints(game.totalEarned)
    local infoText = "Stars: " .. game.prestige.points .. " | Pending: +" .. pendingPoints

    -- Prestige reset button
    self.prestigeButton = Button.new({
        x = cx,
        y = cy + y - self.scrollY,
        w = cw,
        h = 50,
        text = "PRESTIGE (+" .. pendingPoints .. " Stars)",
        subText = "Reset run, keep skill tree progress",
        color = {0.65, 0.50, 0.15},
        onClick = function()
            if pendingPoints > 0 then
                game:doPrestige()
            end
        end,
    })
    self.prestigeButton.enabled = pendingPoints > 0
    y = y + 60

    -- Separator
    y = y + 10

    -- Skill tree nodes
    local nodes = game.prestige:getNodes()
    for _, node in ipairs(nodes) do
        local unlocked = game.prestige:isUnlocked(node.id)
        local canUnlock = game.prestige:canUnlock(node.id)

        local statusText
        if unlocked then
            statusText = "UNLOCKED"
        else
            -- Check if prerequisites are met
            local prereqsMet = true
            for _, req in ipairs(node.requires) do
                if not game.prestige:isUnlocked(req) then
                    prereqsMet = false
                    break
                end
            end
            if not prereqsMet then
                statusText = "Locked (requires prerequisites)"
            else
                statusText = "Cost: " .. node.cost .. " Stars"
            end
        end

        local btn = Button.new({
            x = cx,
            y = cy + y - self.scrollY,
            w = cw,
            h = 58,
            text = node.name,
            subText = node.description .. " | " .. statusText,
            color = unlocked and {0.20, 0.50, 0.25} or (canUnlock and {0.45, 0.40, 0.55} or {0.25, 0.25, 0.28}),
            onClick = function()
                if canUnlock then
                    game.prestige:unlock(node.id)
                end
            end,
        })
        btn.enabled = canUnlock
        table.insert(self.buttons, btn)
        y = y + 65
    end

    self:setContentHeight(y)
end

function PrestigePanel:update(mx, my, game)
    if not self.visible then return end
    self:buildButtons(game)
    if self.prestigeButton then
        self.prestigeButton:update(mx, my)
    end
    for _, btn in ipairs(self.buttons) do
        btn:update(mx, my)
    end
end

function PrestigePanel:draw()
    if not self.visible then return end
    self:drawBackground()

    local cx, cy, cw, ch = self:getContentArea()
    love.graphics.setScissor(cx - 4, cy - 4, cw + 8, ch + 8)

    -- Prestige button
    if self.prestigeButton then
        self.prestigeButton:draw()
    end

    -- Skill nodes
    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end

    love.graphics.setScissor()
end

function PrestigePanel:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then return false end
    if self.prestigeButton and self.prestigeButton:containsPoint(x, y) then
        self.prestigeButton:click()
        return true
    end
    for _, btn in ipairs(self.buttons) do
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
