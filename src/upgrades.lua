local Economy = require("src.economy")
local upgradesData = require("data.upgrades_data")

local Upgrades = {}
Upgrades.__index = Upgrades

function Upgrades.new()
    local self = setmetatable({}, Upgrades)
    self.levels = {}
    for _, ud in ipairs(upgradesData) do
        self.levels[ud.id] = 0
    end
    return self
end

function Upgrades:getLevel(id)
    return self.levels[id] or 0
end

function Upgrades:getData(id)
    for _, ud in ipairs(upgradesData) do
        if ud.id == id then return ud end
    end
    return nil
end

function Upgrades:getCost(id)
    local data = self:getData(id)
    if not data then return math.huge end
    return Economy.upgradeCost(data, self:getLevel(id))
end

function Upgrades:canBuy(id, money)
    local data = self:getData(id)
    if not data then return false end
    local level = self:getLevel(id)
    if level >= data.maxLevel then return false end
    return money >= self:getCost(id)
end

function Upgrades:buy(id)
    local cost = self:getCost(id)
    self.levels[id] = (self.levels[id] or 0) + 1
    return cost
end

function Upgrades:getEffect(id)
    local data = self:getData(id)
    if not data then return 0 end
    return data.effectPerLevel * self:getLevel(id)
end

-- Returns multiplier (0 = no bonus, 0.5 = 50% bonus)
function Upgrades:getSpeedBonus()
    return self:getEffect("animal_speed") / 100
end

function Upgrades:getEarningBonus()
    return self:getEffect("earning_bonus") / 100
end

function Upgrades:getFoodSpawnBonus()
    return self:getEffect("food_spawn_rate") / 100
end

function Upgrades:getFoodValueBonus()
    return self:getEffect("food_value") / 100
end

function Upgrades:getExtraCapacity()
    local data = self:getData("max_animals")
    if not data then return 0 end
    return data.effectPerLevel * self:getLevel("max_animals")
end

function Upgrades:getAllData()
    return upgradesData
end

function Upgrades:reset()
    for id in pairs(self.levels) do
        self.levels[id] = 0
    end
end

function Upgrades:getState()
    return { levels = self.levels }
end

function Upgrades:loadState(state)
    if state and state.levels then
        for id, level in pairs(state.levels) do
            self.levels[id] = level
        end
    end
end

return Upgrades
