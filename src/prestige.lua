local Economy = require("src.economy")
local prestigeData = require("data.prestige_data")

local Prestige = {}
Prestige.__index = Prestige

function Prestige.new()
    local self = setmetatable({}, Prestige)
    self.points = 0
    self.totalEarnedPoints = 0
    self.unlockedNodes = {}
    return self
end

function Prestige:getNodes()
    return prestigeData
end

function Prestige:isUnlocked(nodeId)
    return self.unlockedNodes[nodeId] == true
end

function Prestige:canUnlock(nodeId)
    for _, node in ipairs(prestigeData) do
        if node.id == nodeId then
            if self:isUnlocked(nodeId) then return false end
            if self.points < node.cost then return false end
            -- Check prerequisites
            for _, req in ipairs(node.requires) do
                if not self:isUnlocked(req) then return false end
            end
            return true
        end
    end
    return false
end

function Prestige:unlock(nodeId)
    for _, node in ipairs(prestigeData) do
        if node.id == nodeId then
            self.points = self.points - node.cost
            self.unlockedNodes[nodeId] = true
            return true
        end
    end
    return false
end

function Prestige:calcPointsFromRun(totalEarned)
    return Economy.calcPrestigePoints(totalEarned)
end

function Prestige:addPoints(points)
    self.points = self.points + points
    self.totalEarnedPoints = self.totalEarnedPoints + points
end

-- Get all unlocked animal types from skill tree
function Prestige:getUnlockedAnimals()
    local animals = {"cow"}  -- cow is always unlocked
    for _, node in ipairs(prestigeData) do
        if self:isUnlocked(node.id) and node.effect.type == "unlock_animal" then
            table.insert(animals, node.effect.value)
        end
    end
    return animals
end

-- Get total earning multiplier from prestige
function Prestige:getEarningMultiplier()
    local mult = 0
    for _, node in ipairs(prestigeData) do
        if self:isUnlocked(node.id) and node.effect.type == "earning_multiplier" then
            mult = mult + node.effect.value
        end
    end
    return mult
end

-- Get total speed bonus from prestige
function Prestige:getSpeedBonus()
    local bonus = 0
    for _, node in ipairs(prestigeData) do
        if self:isUnlocked(node.id) and node.effect.type == "speed_bonus" then
            bonus = bonus + node.effect.value
        end
    end
    return bonus
end

-- Get food spawn bonus from prestige
function Prestige:getFoodSpawnBonus()
    local bonus = 0
    for _, node in ipairs(prestigeData) do
        if self:isUnlocked(node.id) and node.effect.type == "food_spawn_bonus" then
            bonus = bonus + node.effect.value
        end
    end
    return bonus
end

-- Get extra capacity from prestige
function Prestige:getExtraCapacity()
    local cap = 0
    for _, node in ipairs(prestigeData) do
        if self:isUnlocked(node.id) and node.effect.type == "extra_capacity" then
            cap = cap + node.effect.value
        end
    end
    return cap
end

-- Get starting money from prestige
function Prestige:getStartingMoney()
    local money = 0
    for _, node in ipairs(prestigeData) do
        if self:isUnlocked(node.id) and node.effect.type == "starting_money" then
            money = money + node.effect.value
        end
    end
    return money
end

function Prestige:getState()
    return {
        points = self.points,
        totalEarnedPoints = self.totalEarnedPoints,
        unlockedNodes = self.unlockedNodes,
    }
end

function Prestige:loadState(state)
    if state then
        self.points = state.points or 0
        self.totalEarnedPoints = state.totalEarnedPoints or 0
        self.unlockedNodes = state.unlockedNodes or {}
    end
end

return Prestige
