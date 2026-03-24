local Panel = require("src.ui.panel")
local Button = require("src.ui.button")
local Economy = require("src.economy")
local Sprites = require("src.sprites")
local util = require("src.util")

local Shop = {}
Shop.__index = Shop
setmetatable(Shop, { __index = Panel })

-- All animal types in display order
local ANIMAL_ORDER = {"cow", "chicken", "pig", "sheep"}
local ROW_HEIGHT = 160

function Shop.new()
    local self = Panel.new({ title = "INVENTORY" })
    setmetatable(self, Shop)
    self.buyButtons = {}
    self.levelButtons = {}
    self.game = nil
    return self
end

function Shop:buildRows(game)
    self.game = game
    self.buyButtons = {}
    self.levelButtons = {}
    local cx, cy, cw, ch = self:getContentArea()
    local animalsData = require("data.animals")
    local unlockedAnimals = game.prestige:getUnlockedAnimals()

    -- Build lookup for unlocked
    local unlocked = {}
    for _, id in ipairs(unlockedAnimals) do
        unlocked[id] = true
    end

    local y = 0
    for _, animalId in ipairs(ANIMAL_ORDER) do
        local data = animalsData[animalId]
        if not data then goto continue end

        local rowY = cy + y - self.scrollY

        if unlocked[animalId] then
            -- Buy button
            local ownedCount = 0
            for _, a in ipairs(game.animals) do
                if a.type == animalId then ownedCount = ownedCount + 1 end
            end
            local cost = Economy.animalCost(data, ownedCount)
            local canAfford = game.money >= cost
            local hasRoom = #game.animals < game:getMaxAnimals()

            local buyBtn = Button.new({
                x = cx, y = rowY + 125,
                w = math.floor(cw * 0.48), h = 28,
                text = "Buy " .. Economy.formatMoney(cost),
                color = {0.25, 0.50, 0.30},
                cornerRadius = 4,
                onClick = function()
                    game:buyAnimal(animalId)
                end,
            })
            buyBtn.enabled = canAfford and hasRoom
            buyBtn.animalId = animalId
            table.insert(self.buyButtons, buyBtn)

            -- Level up button
            local entry = game.animalLevels[animalId]
            local lvl = entry and entry.level or 0
            local maxLevel = data.maxAnimalLevel or 10
            local atMax = lvl >= maxLevel

            local lvlBtn
            if atMax then
                lvlBtn = Button.new({
                    x = cx + math.floor(cw * 0.52), y = rowY + 125,
                    w = math.floor(cw * 0.48), h = 28,
                    text = "MAX LEVEL",
                    color = {0.35, 0.35, 0.35},
                    cornerRadius = 4,
                    onClick = function() end,
                })
                lvlBtn.enabled = false
            else
                local lvlCost = Economy.animalLevelUpCost(data, lvl)
                local xpNeeded = Economy.animalXPNeeded(data, lvl)
                local xp = entry and entry.xp or 0
                local canLevel = xp >= xpNeeded and game.money >= lvlCost

                lvlBtn = Button.new({
                    x = cx + math.floor(cw * 0.52), y = rowY + 125,
                    w = math.floor(cw * 0.48), h = 28,
                    text = "Level Up " .. Economy.formatMoney(lvlCost),
                    color = {0.40, 0.45, 0.60},
                    cornerRadius = 4,
                    onClick = function()
                        game:levelUpAnimal(animalId)
                    end,
                })
                lvlBtn.enabled = canLevel
            end
            lvlBtn.animalId = animalId
            table.insert(self.levelButtons, lvlBtn)
        end

        y = y + ROW_HEIGHT + 8
        ::continue::
    end

    self:setContentHeight(y)
end

function Shop:update(mx, my, game)
    if not self.visible then return end
    self:buildRows(game)
    for _, btn in ipairs(self.buyButtons) do
        btn:update(mx, my)
    end
    for _, btn in ipairs(self.levelButtons) do
        btn:update(mx, my)
    end
end

function Shop:draw()
    if not self.visible then return end
    self:drawBackground()

    local cx, cy, cw, ch = self:getContentArea()
    local game = self.game
    if not game then return end

    love.graphics.setScissor(cx - 4, cy - 4, cw + 8, ch + 8)

    local animalsData = require("data.animals")
    local unlockedAnimals = game.prestige:getUnlockedAnimals()
    local unlocked = {}
    for _, id in ipairs(unlockedAnimals) do
        unlocked[id] = true
    end

    local y = 0
    for _, animalId in ipairs(ANIMAL_ORDER) do
        local data = animalsData[animalId]
        if not data then goto continue end

        local rowY = cy + y - self.scrollY

        -- Row background
        love.graphics.setColor(0.15, 0.15, 0.18, 0.7)
        love.graphics.rectangle("fill", cx, rowY, cw, ROW_HEIGHT, 6, 6)
        -- Subtle top highlight
        love.graphics.setColor(1, 1, 1, 0.03)
        love.graphics.rectangle("fill", cx, rowY, cw, ROW_HEIGHT * 0.4, 6, 6)

        if unlocked[animalId] then
            self:drawUnlockedRow(cx, rowY, cw, data, animalId, game)
        else
            self:drawLockedRow(cx, rowY, cw, data)
        end

        y = y + ROW_HEIGHT + 8
        ::continue::
    end

    -- Draw buttons on top
    for _, btn in ipairs(self.buyButtons) do
        btn:draw()
    end
    for _, btn in ipairs(self.levelButtons) do
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

function Shop:drawLockedRow(cx, rowY, cw, data)
    -- Lock icon (simple padlock shape)
    local lockX = cx + 30
    local lockY = rowY + ROW_HEIGHT / 2

    love.graphics.setColor(0.50, 0.50, 0.50, 0.6)
    -- Lock body
    love.graphics.rectangle("fill", lockX - 10, lockY - 4, 20, 16, 3, 3)
    -- Lock arc
    love.graphics.setLineWidth(3)
    love.graphics.arc("line", lockX, lockY - 4, 8, math.pi, 0)
    love.graphics.setLineWidth(1)

    -- Name
    love.graphics.setColor(0.60, 0.60, 0.60)
    love.graphics.print(data.name, cx + 55, rowY + ROW_HEIGHT / 2 - 14)

    love.graphics.setColor(0.45, 0.45, 0.45)
    love.graphics.print("Unlock via Prestige", cx + 55, rowY + ROW_HEIGHT / 2 + 4)
end

function Shop:drawUnlockedRow(cx, rowY, cw, data, animalId, game)
    local entry = game.animalLevels[animalId]
    local lvl = entry and entry.level or 0
    local maxLevel = data.maxAnimalLevel or 10

    -- Animal sprite
    love.graphics.setColor(1, 1, 1, 1)
    Sprites.drawAnimal(animalId, 1, cx + 28, rowY + 30, 40, false, 0)

    -- Name and level
    love.graphics.setColor(0.95, 0.90, 0.70)
    love.graphics.print(data.name .. "  Lv." .. lvl, cx + 55, rowY + 6)

    -- XP bar
    local barX = cx + 55
    local barY = rowY + 24
    local barW = cw - 62
    local barH = 12

    if lvl >= maxLevel then
        -- Max level - full golden bar
        love.graphics.setColor(0.20, 0.20, 0.20, 0.8)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 3, 3)
        love.graphics.setColor(1, 0.85, 0.25)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 3, 3)
        love.graphics.setColor(1, 0.90, 0.40)
        local font = love.graphics.getFont()
        love.graphics.printf("MAX", barX, barY, barW, "center")
    else
        local xpNeeded = Economy.animalXPNeeded(data, lvl)
        local xp = entry and entry.xp or 0
        local fill = math.min(xp / xpNeeded, 1.0)

        -- Bar background
        love.graphics.setColor(0.20, 0.20, 0.20, 0.8)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 3, 3)
        -- Bar fill
        if fill > 0 then
            love.graphics.setColor(0.30, 0.70, 0.90)
            love.graphics.rectangle("fill", barX, barY, barW * fill, barH, 3, 3)
        end
        -- Bar border
        love.graphics.setColor(0.50, 0.50, 0.50, 0.5)
        love.graphics.rectangle("line", barX, barY, barW, barH, 3, 3)
        -- XP text
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf(xp .. "/" .. xpNeeded .. " XP", barX, barY, barW, "center")
    end

    -- Stats: earnings at each tier
    local statsY = rowY + 42
    local earningBonus = game:getEarningBonus()
    local prestigeBonus = game:getPrestigeEarningBonus()
    local levelBonus = 1 + lvl * 0.10

    love.graphics.setColor(0.75, 0.75, 0.70)
    local earnLine = ""
    for t = 1, #data.tiers do
        local tierData = data.tiers[t]
        local earn = data.baseEarning * tierData.earningMult * levelBonus * (1 + earningBonus) * (1 + prestigeBonus)
        if t > 1 then earnLine = earnLine .. "  " end
        -- Star symbol for tier
        local stars = ""
        for s = 1, t do stars = stars .. "*" end
        earnLine = earnLine .. stars .. " " .. Economy.formatMoney(earn)
    end
    love.graphics.print("Earn: " .. earnLine, cx + 6, statsY)

    -- Speed stat
    local speedBonus = game.upgrades:getSpeedBonus()
    local prestigeSpeedBonus = game.prestige:getSpeedBonus()
    local levelSpeedBonus = lvl * 0.05
    local totalSpeedMult = (1 + speedBonus + levelSpeedBonus) * (1 + prestigeSpeedBonus)
    local actualSpeed = data.baseSpeed * totalSpeedMult
    local pctBonus = math.floor((totalSpeedMult - 1) * 100 + 0.5)

    love.graphics.setColor(0.70, 0.75, 0.80)
    local speedText = string.format("Speed: %.0f", actualSpeed)
    if pctBonus > 0 then
        speedText = speedText .. string.format(" (base %d +%d%%)", data.baseSpeed, pctBonus)
    end
    love.graphics.print(speedText, cx + 6, statsY + 16)

    -- Owned count
    local ownedCount = 0
    for _, a in ipairs(game.animals) do
        if a.type == animalId then ownedCount = ownedCount + 1 end
    end
    love.graphics.setColor(0.65, 0.65, 0.60)
    love.graphics.print("Owned: " .. ownedCount, cx + 6, statsY + 32)

    -- Level bonus info
    if lvl > 0 then
        love.graphics.setColor(0.50, 0.80, 0.50, 0.7)
        love.graphics.print("Lv bonus: +" .. (lvl * 10) .. "% earn, +" .. (lvl * 5) .. "% spd", cx + 6, statsY + 48)
    end
end

function Shop:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then return false end
    for _, btn in ipairs(self.buyButtons) do
        if btn:click() then return true end
    end
    for _, btn in ipairs(self.levelButtons) do
        if btn:click() then return true end
    end
    return self:containsPoint(x, y)
end

function Shop:wheelmoved(x, y, wx, wy)
    if not self.visible then return false end
    if self:containsPoint(x, y) then
        self:scroll(wy)
        return true
    end
    return false
end

return Shop
