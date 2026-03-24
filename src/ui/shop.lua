local Panel = require("src.ui.panel")
local Button = require("src.ui.button")
local Economy = require("src.economy")
local Sprites = require("src.sprites")

local Shop = {}
Shop.__index = Shop
setmetatable(Shop, { __index = Panel })

function Shop.new()
    local self = Panel.new({ title = "SHOP - Buy Animals" })
    setmetatable(self, Shop)
    self.buttons = {}
    self.game = nil
    return self
end

function Shop:buildButtons(game)
    self.game = game
    self.buttons = {}
    local cx, cy, cw, ch = self:getContentArea()
    local y = 0
    local animalsData = require("data.animals")
    local unlockedAnimals = game.prestige:getUnlockedAnimals()

    for _, animalId in ipairs(unlockedAnimals) do
        local data = animalsData[animalId]
        if data then
            local ownedCount = 0
            for _, a in ipairs(game.animals) do
                if a.type == animalId then ownedCount = ownedCount + 1 end
            end
            local cost = Economy.animalCost(data, ownedCount)
            local canAfford = game.money >= cost
            local hasRoom = #game.animals < game:getMaxAnimals()

            local btn = Button.new({
                x = cx,
                y = cy + y - self.scrollY,
                w = cw,
                h = 65,
                text = "Buy " .. data.name,
                subText = Economy.formatMoney(cost) .. " | Earns " .. Economy.formatMoney(data.baseEarning) .. "/eat",
                color = {0.25, 0.50, 0.30},
                onClick = function()
                    if game.money >= cost and #game.animals < game:getMaxAnimals() then
                        game:buyAnimal(animalId)
                    end
                end,
            })
            btn.enabled = canAfford and hasRoom
            btn.animalType = animalId
            btn.animalData = data
            table.insert(self.buttons, btn)
            y = y + 72
        end
    end

    self:setContentHeight(y)
end

function Shop:update(mx, my, game)
    if not self.visible then return end
    self:buildButtons(game)
    for _, btn in ipairs(self.buttons) do
        btn:update(mx, my)
    end
end

function Shop:draw()
    if not self.visible then return end
    self:drawBackground()

    local cx, cy, cw, ch = self:getContentArea()

    -- Clip to content area
    love.graphics.setScissor(cx - 4, cy - 4, cw + 8, ch + 8)

    for _, btn in ipairs(self.buttons) do
        btn:draw()

        -- Draw small animal preview
        if btn.animalType then
            love.graphics.setColor(1, 1, 1, 1)
            Sprites.drawAnimal(btn.animalType, 1, btn.x + 28, btn.y + 32, 36, false, 0)
        end
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

function Shop:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then return false end
    for _, btn in ipairs(self.buttons) do
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
