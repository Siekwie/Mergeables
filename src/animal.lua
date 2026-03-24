local util = require("src.util")
local Sprites = require("src.sprites")

-- Load perks data safely (another worker may not have created it yet)
local perksOk, perksData = pcall(require, "data.perks_data")
if not perksOk then
    perksData = {}
end

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

    -- Perk state
    self.favFoodSpeedTimer = 0
    self.hasEatenThisSession = false
    self.eatStreak = 0
    self.eatStreakTimer = 0
    self.level = 0

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

function Animal:getMaxLevel()
    return self:getAnimalData().maxAnimalLevel or 10
end

function Animal:isMaxLevel()
    return self.level >= self:getMaxLevel()
end

function Animal:getEarning(earningBonus, prestigeBonus, animalLevel)
    local data = self:getAnimalData()
    local tierData = self:getTierData()
    local levelBonus = 1 + (animalLevel or 0) * 0.10
    return data.baseEarning * tierData.earningMult * levelBonus * (1 + (earningBonus or 0)) * (1 + (prestigeBonus or 0))
end

-- Helper: apply idle modifier trade-offs to idle duration
local function applyIdleModifier(animal)
    local perk = perksData[animal.type]
    if perk and perk.tradeOff then
        if perk.tradeOff.type == "idle_modifier" or perk.tradeOff.type == "idle_modifier_range" then
            local ignoreTradeOff = animal:isMaxLevel() and perk.maxLevelPerk and perk.maxLevelPerk.ignoreTradeOff
            if not ignoreTradeOff then
                animal.idleDuration = animal.idleDuration * (1 + perk.tradeOff.idlePenaltyMult)
            end
        end
    end
end

function Animal:update(dt, fieldW, fieldH, foods, game)
    self.bobTimer = self.bobTimer + dt * 3
    self.stateTimer = self.stateTimer + dt

    -- Perk timers
    if self.favFoodSpeedTimer > 0 then
        self.favFoodSpeedTimer = self.favFoodSpeedTimer - dt
    end
    if self.eatStreakTimer > 0 then
        self.eatStreakTimer = self.eatStreakTimer - dt
        if self.eatStreakTimer <= 0 then
            self.eatStreak = 0
        end
    end

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
            local animals = game and game.animals or nil
            local closestFood = self:findNearestFood(foods, animals)
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
            applyIdleModifier(self)
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

                -- Pig glutton: eat faster at max level
                local perk = perksData[self.type]
                if perk and perk.maxLevelPerk and perk.maxLevelPerk.type == "eat_speed_stack" then
                    if self:isMaxLevel() then
                        self.eatingTimer = self.eatingTimer * (1 - perk.maxLevelPerk.eatSpeedup)
                    end
                end
            end
        else
            self.targetFood = nil
            self.state = STATES.IDLE
            self.stateTimer = 0
            self.idleDuration = util.randomFloat(0.5, 1.5)
            applyIdleModifier(self)
        end
    elseif self.state == STATES.EATING then
        if self.stateTimer >= self.eatingTimer then
            -- Finish eating: earn money
            if self.targetFood and not self.targetFood.eaten then
                self.targetFood.eaten = true
                self.targetFood.respawnTimer = self.targetFood.respawnTime

                if game then
                    local lvl = game:getAnimalLevel(self.type)
                    local earning = self:getEarning(game:getEarningBonus(), game:getPrestigeEarningBonus(), lvl)
                    local foodMult = 1 + (game:getFoodValueBonus())
                    local amount = earning * foodMult * self.targetFood.value

                    local perk = perksData[self.type]
                    local isMaxLevel = self:isMaxLevel()

                    -- Favorite food speed boost
                    if perk and perk.favoriteFood and self.targetFood.type == perk.favoriteFood then
                        if perksData.favoriteFoodBoost then
                            self.favFoodSpeedTimer = perksData.favoriteFoodBoost.duration
                        end
                    end

                    -- Cow "Slow Starter": mark first eat
                    self.hasEatenThisSession = true

                    -- Chicken "Fragile": penalty for non-favorite food
                    if perk and perk.tradeOff and perk.tradeOff.type == "earning_modifier" then
                        local ignoreTradeOff = isMaxLevel and perk.maxLevelPerk and perk.maxLevelPerk.ignoreTradeOff
                        if not ignoreTradeOff then
                            if not perk.favoriteFood or self.targetFood.type ~= perk.favoriteFood then
                                amount = amount * (1 + perk.tradeOff.nonFavoritePenalty)
                            end
                        end
                    end

                    -- Pig "Glutton" max-level stacking bonus
                    if perk and perk.maxLevelPerk and perk.maxLevelPerk.type == "eat_speed_stack" and isMaxLevel then
                        self.eatStreak = math.min(self.eatStreak + 1, perk.maxLevelPerk.maxStacks)
                        self.eatStreakTimer = perk.maxLevelPerk.stackDecayTime
                        amount = amount * (1 + perk.maxLevelPerk.stackBonus * self.eatStreak)
                    end

                    -- Cow "Fertile Grazer" max-level: speed up food respawn
                    if perk and perk.maxLevelPerk and perk.maxLevelPerk.type == "respawn_speedup" and isMaxLevel then
                        self.targetFood.respawnTimer = self.targetFood.respawnTimer * (1 - perk.maxLevelPerk.respawnSpeedup)
                    end

                    -- Cat "Lucky Catch" max-level: crit chance
                    if perk and perk.maxLevelPerk and perk.maxLevelPerk.type == "crit_chance" and isMaxLevel then
                        if math.random() < perk.maxLevelPerk.critChance then
                            amount = amount * perk.maxLevelPerk.critMult
                        end
                    end

                    -- Goat "Iron Stomach" max-level: bonus on all food
                    if perk and perk.maxLevelPerk and perk.maxLevelPerk.type == "universal_bonus" and isMaxLevel then
                        amount = amount * (1 + perk.maxLevelPerk.allFoodBonus)
                    end

                    -- Sheep "Herd Instinct" max-level: proximity bonus
                    if perk and perk.maxLevelPerk and perk.maxLevelPerk.type == "proximity_bonus" and isMaxLevel then
                        local count = 0
                        if game.animals then
                            for _, other in ipairs(game.animals) do
                                if other ~= self and other.type == self.type then
                                    local d = util.distance(self.x, self.y, other.x, other.y)
                                    if d <= perk.maxLevelPerk.radius then
                                        count = count + 1
                                    end
                                end
                            end
                        end
                        local bonus = math.min(count * perk.maxLevelPerk.perAnimalBonus, perk.maxLevelPerk.maxBonus)
                        amount = amount * (1 + bonus)
                    end

                    game:addMoney(amount)
                    -- Grant XP to this animal type (higher tier = more XP)
                    game:addAnimalXP(self.type, 1 + (self.tier - 1))
                    if game.particles then
                        game.particles:spawnCoinPopup(self.x, self.y - self.size * 0.5, amount)
                    end
                end
            end
            self.targetFood = nil
            self.state = STATES.IDLE
            self.stateTimer = 0
            self.idleDuration = util.randomFloat(0.5, 1.5)
            applyIdleModifier(self)
        end
    end
end

function Animal:findNearestFood(foods, animals)
    local perk = perksData[self.type]
    local isMaxLevel = self:isMaxLevel()
    local ignoreTradeOff = isMaxLevel and perk and perk.maxLevelPerk and perk.maxLevelPerk.ignoreTradeOff

    local closest = nil
    local closestDist = 400  -- default detection range

    -- Goat "Stubborn" trade-off: reduced detection range
    if not ignoreTradeOff and perk and perk.tradeOff and perk.tradeOff.maxFoodRange then
        closestDist = perk.tradeOff.maxFoodRange
    end

    for _, food in ipairs(foods) do
        if not food.eaten then
            -- Cat "Picky Eater" trade-off: only eats specific food types
            if not ignoreTradeOff and perk and perk.tradeOff and perk.tradeOff.type == "food_filter_type" then
                local allowed = false
                for _, ft in ipairs(perk.tradeOff.allowedFoods) do
                    if food.type == ft then allowed = true; break end
                end
                if not allowed then goto continue end
            end

            -- Sheep "Timid" trade-off: avoid food another animal is eating
            if not ignoreTradeOff and perk and perk.tradeOff and perk.tradeOff.type == "food_filter_occupied" then
                if animals then
                    local occupied = false
                    for _, other in ipairs(animals) do
                        if other ~= self and other.targetFood == food and other.state == "eating" then
                            occupied = true; break
                        end
                    end
                    if occupied then goto continue end
                end
            end

            local d = util.distance(self.x, self.y, food.x, food.y)
            if d < closestDist then
                closestDist = d
                closest = food
            end

            ::continue::
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

    -- Favorite food speed boost visual indicator
    if self.favFoodSpeedTimer > 0 then
        local alpha = math.min(1, self.favFoodSpeedTimer / 2) * 0.6
        love.graphics.setColor(0.3, 0.8, 1.0, alpha)
        local dir = self.flipX and 1 or -1
        for i = 1, 3 do
            local ox = dir * (self.size * 0.3 + i * 4)
            local oy = -self.size * 0.1 + (i - 2) * 6
            love.graphics.line(self.x + ox, self.y + oy, self.x + ox + dir * 8, self.y + oy)
        end
    end

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

function Animal:setSpeed(baseMultiplier, prestigeBonus, animalLevel)
    self.level = animalLevel or 0
    local levelBonus = self.level * 0.05
    self.speed = self.baseSpeed * (1 + (baseMultiplier or 0) + levelBonus) * (1 + (prestigeBonus or 0))

    -- Cow "Slow Starter" trade-off: speed penalty until first eat
    local perk = perksData[self.type]
    if perk and perk.tradeOff and perk.tradeOff.type == "conditional_speed" then
        if not self.hasEatenThisSession then
            self.speed = self.speed * (1 + perk.tradeOff.speedPenalty)
        end
    end

    -- Favorite food speed boost (temporary)
    if self.favFoodSpeedTimer > 0 then
        if perksData.favoriteFoodBoost then
            self.speed = self.speed * perksData.favoriteFoodBoost.speedMultiplier
        end
    end
end

return Animal
