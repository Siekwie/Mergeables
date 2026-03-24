local util = require("src.util")
local Sprites = require("src.sprites")

local Animal = {}
Animal.__index = Animal

local STATES = { WANDER = "wander", IDLE = "idle", EATING = "eating", DRAGGED = "dragged", MOVING_TO_FOOD = "moving_to_food" }

function Animal.new(animalType, tier, x, y)
    local animalData = require("data.animals")[animalType]
    local tierData = animalData.tiers[tier] or animalData.tiers[1]

    local self = setmetatable({}, Animal)
    self.type = animalType
    self.tier = tier or 1
    self.x = x
    self.y = y
    self.targetX = x
    self.targetY = y
    self.baseSpeed = animalData.baseSpeed
    self.speed = animalData.baseSpeed
    self.size = tierData.size
    self.state = STATES.IDLE
    self.stateTimer = 0
    self.idleDuration = util.randomFloat(0.5, 2.0)
    self.flipX = math.random() > 0.5
    self.bobTimer = math.random() * math.pi * 2
    self.targetFood = nil
    self.eatingTimer = 0
    self.mergeScale = 1.0
    self.mergeTimer = 0
    self.highlighted = false
    return self
end

function Animal:getAnimalData()
    return require("data.animals")[self.type]
end

function Animal:getTierData()
    local data = self:getAnimalData()
    return data.tiers[self.tier] or data.tiers[#data.tiers]
end

function Animal:getMaxTier()
    return #self:getAnimalData().tiers
end

function Animal:getEarning(earningBonus, prestigeBonus)
    local data = self:getAnimalData()
    local tierData = self:getTierData()
    return data.baseEarning * tierData.earningMult * (1 + (earningBonus or 0)) * (1 + (prestigeBonus or 0))
end

function Animal:update(dt, fieldW, fieldH, foods, game)
    self.bobTimer = self.bobTimer + dt * 3
    self.stateTimer = self.stateTimer + dt

    -- Merge scale animation
    if self.mergeTimer > 0 then
        self.mergeTimer = self.mergeTimer - dt
        self.mergeScale = 1.0 + math.sin(self.mergeTimer * 10) * 0.15 * (self.mergeTimer / 0.5)
        if self.mergeTimer <= 0 then
            self.mergeScale = 1.0
        end
    end

    if self.state == STATES.DRAGGED then
        return
    end

    if self.state == STATES.IDLE then
        if self.stateTimer >= self.idleDuration then
            -- Look for nearby food first
            local closestFood = self:findNearestFood(foods)
            if closestFood then
                self.targetFood = closestFood
                self.targetX = closestFood.x
                self.targetY = closestFood.y
                self.state = STATES.MOVING_TO_FOOD
            else
                -- Random wander
                local margin = self.size
                self.targetX = util.clamp(self.x + util.randomFloat(-200, 200), margin, fieldW - margin)
                self.targetY = util.clamp(self.y + util.randomFloat(-200, 200), margin, fieldH - margin)
                self.state = STATES.WANDER
            end
            self.stateTimer = 0
        end
    elseif self.state == STATES.WANDER then
        self:moveToTarget(dt)
        if util.distance(self.x, self.y, self.targetX, self.targetY) < 5 then
            self.state = STATES.IDLE
            self.stateTimer = 0
            self.idleDuration = util.randomFloat(1.0, 3.0)
        end
    elseif self.state == STATES.MOVING_TO_FOOD then
        if self.targetFood and not self.targetFood.eaten then
            self.targetX = self.targetFood.x
            self.targetY = self.targetFood.y
            self:moveToTarget(dt)
            if util.distance(self.x, self.y, self.targetFood.x, self.targetFood.y) < self.size * 0.5 then
                self.state = STATES.EATING
                self.stateTimer = 0
                self.eatingTimer = util.randomFloat(1.0, 2.0)
            end
        else
            self.targetFood = nil
            self.state = STATES.IDLE
            self.stateTimer = 0
        end
    elseif self.state == STATES.EATING then
        if self.stateTimer >= self.eatingTimer then
            -- Finish eating: earn money
            if self.targetFood and not self.targetFood.eaten then
                self.targetFood.eaten = true
                self.targetFood.respawnTimer = self.targetFood.respawnTime
                if game then
                    local earning = self:getEarning(game:getEarningBonus(), game:getPrestigeEarningBonus())
                    local foodMult = 1 + (game:getFoodValueBonus())
                    local amount = earning * foodMult * self.targetFood.value
                    game:addMoney(amount)
                    if game.particles then
                        game.particles:spawnCoinPopup(self.x, self.y - self.size * 0.5, amount)
                    end
                end
            end
            self.targetFood = nil
            self.state = STATES.IDLE
            self.stateTimer = 0
            self.idleDuration = util.randomFloat(0.5, 1.5)
        end
    end
end

function Animal:findNearestFood(foods)
    local closest = nil
    local closestDist = 400 -- detection range
    for _, food in ipairs(foods) do
        if not food.eaten then
            local d = util.distance(self.x, self.y, food.x, food.y)
            if d < closestDist then
                closestDist = d
                closest = food
            end
        end
    end
    return closest
end

function Animal:moveToTarget(dt)
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 1 then
        local nx, ny = dx / dist, dy / dist
        self.x = self.x + nx * self.speed * dt
        self.y = self.y + ny * self.speed * dt
        self.flipX = dx < 0
    end
end

function Animal:draw()
    local bobOffset = 0
    if self.state == STATES.WANDER or self.state == STATES.MOVING_TO_FOOD then
        bobOffset = math.sin(self.bobTimer) * 2
    elseif self.state == STATES.EATING then
        bobOffset = math.sin(self.bobTimer * 2) * 3 -- faster bob while eating
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.scale(self.mergeScale, self.mergeScale)
    love.graphics.translate(-self.x, -self.y)

    -- Highlight ring when selected or merge target
    if self.highlighted then
        love.graphics.setColor(1, 1, 0.3, 0.4)
        love.graphics.circle("line", self.x, self.y, self.size * 0.55)
        love.graphics.circle("line", self.x, self.y, self.size * 0.58)
    end

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.ellipse("fill", self.x, self.y + self.size * 0.35, self.size * 0.35, self.size * 0.1)

    Sprites.drawAnimal(self.type, self.tier, self.x, self.y, self.size, self.flipX, bobOffset)

    love.graphics.pop()
end

function Animal:containsPoint(px, py)
    return util.distance(px, py, self.x, self.y) < self.size * 0.5
end

function Animal:canMergeWith(other)
    return other ~= self
        and self.type == other.type
        and self.tier == other.tier
        and self.tier < self:getMaxTier()
end

function Animal:startDrag()
    self.state = STATES.DRAGGED
end

function Animal:stopDrag()
    self.state = STATES.IDLE
    self.stateTimer = 0
    self.idleDuration = 0.5
end

function Animal:triggerMergeAnimation()
    self.mergeTimer = 0.5
    local tierData = self:getTierData()
    self.size = tierData.size
end

function Animal:setSpeed(baseMultiplier, prestigeBonus)
    self.speed = self.baseSpeed * (1 + (baseMultiplier or 0)) * (1 + (prestigeBonus or 0))
end

return Animal
