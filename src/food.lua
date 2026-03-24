local util = require("src.util")
local Sprites = require("src.sprites")

local FoodManager = {}
FoodManager.__index = FoodManager

local FOOD_TYPES = {"grass", "berries", "corn"}

function FoodManager.new(fieldW, fieldH)
    local self = setmetatable({}, FoodManager)
    self.foods = {}
    self.fieldW = fieldW
    self.fieldH = fieldH
    self.baseSpawnInterval = 3.0  -- seconds between spawns
    self.spawnTimer = 0
    self.maxFood = 15
    return self
end

function FoodManager:spawnFood()
    if #self.foods >= self.maxFood then return end
    local margin = 80
    local food = {
        type = FOOD_TYPES[math.random(#FOOD_TYPES)],
        x = util.randomFloat(margin, self.fieldW - margin),
        y = util.randomFloat(margin, self.fieldH - margin),
        size = util.randomFloat(22, 32),
        value = 1,
        eaten = false,
        respawnTimer = 0,
        respawnTime = util.randomFloat(4.0, 8.0),
        alpha = 0,  -- fade in
    }
    table.insert(self.foods, food)
end

function FoodManager:update(dt, spawnRateBonus)
    local interval = self.baseSpawnInterval / (1 + (spawnRateBonus or 0))
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= interval then
        self:spawnFood()
        self.spawnTimer = 0
    end

    -- Update food states
    for i = #self.foods, 1, -1 do
        local food = self.foods[i]
        if food.eaten then
            food.respawnTimer = food.respawnTimer - dt
            if food.respawnTimer <= 0 then
                -- Respawn at new location
                local margin = 80
                food.x = util.randomFloat(margin, self.fieldW - margin)
                food.y = util.randomFloat(margin, self.fieldH - margin)
                food.eaten = false
                food.alpha = 0
            end
        else
            -- Fade in
            if food.alpha < 1 then
                food.alpha = math.min(1, food.alpha + dt * 2)
            end
        end
    end
end

function FoodManager:draw()
    for _, food in ipairs(self.foods) do
        if not food.eaten then
            love.graphics.setColor(1, 1, 1, food.alpha)
            Sprites.drawFood(food.type, food.x, food.y, food.size)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function FoodManager:getFoods()
    return self.foods
end

function FoodManager:getState()
    local state = {}
    for _, food in ipairs(self.foods) do
        table.insert(state, {
            type = food.type,
            x = food.x,
            y = food.y,
            size = food.size,
            value = food.value,
            eaten = food.eaten,
            respawnTimer = food.respawnTimer,
            respawnTime = food.respawnTime,
        })
    end
    return state
end

return FoodManager
