local skillTreeData = require("data.skill_tree_data")

local SkillTree = {}
SkillTree.__index = SkillTree

-- Base chance of getting a skill point from eating food
local BASE_FOOD_SKILL_CHANCE = 0.005  -- 0.5%

function SkillTree.new()
    local self = setmetatable({}, SkillTree)
    self.points = 0          -- fractional (0.25 per level up)
    self.totalEarned = 0
    self.unlocked = {}       -- set of unlocked node ids
    return self
end

function SkillTree:isUnlocked(nodeId)
    return self.unlocked[nodeId] == true
end

-- Check if a node can be unlocked (has points + prerequisites met)
function SkillTree:canUnlock(nodeId)
    if self:isUnlocked(nodeId) then return false end

    -- Find the node and its branch
    for _, branch in ipairs(skillTreeData) do
        for i, node in ipairs(branch.nodes) do
            if node.id == nodeId then
                -- Must have enough points
                if self.points < node.cost then return false end
                -- First node in branch: no prereq
                if i == 1 then return true end
                -- Otherwise: previous node must be unlocked
                return self:isUnlocked(branch.nodes[i - 1].id)
            end
        end
    end
    return false
end

function SkillTree:unlock(nodeId)
    if not self:canUnlock(nodeId) then return false end

    -- Find the node to get cost
    for _, branch in ipairs(skillTreeData) do
        for _, node in ipairs(branch.nodes) do
            if node.id == nodeId then
                self.points = self.points - node.cost
                self.unlocked[nodeId] = true
                return true
            end
        end
    end
    return false
end

function SkillTree:addPoints(amount)
    self.points = self.points + amount
    self.totalEarned = self.totalEarned + amount
end

-- Sum up all unlocked effects of a given type
function SkillTree:sumEffect(effectType, animalFilter)
    local total = 0
    for _, branch in ipairs(skillTreeData) do
        for _, node in ipairs(branch.nodes) do
            if self:isUnlocked(node.id) and node.effect.type == effectType then
                if animalFilter then
                    if node.effect.animal == animalFilter then
                        total = total + node.effect.value
                    end
                else
                    total = total + node.effect.value
                end
            end
        end
    end
    return total
end

-- Convenience getters
function SkillTree:getEarningMultiplier()
    return self:sumEffect("earning_multiplier")
end

function SkillTree:getSpeedBonus()
    return self:sumEffect("speed_bonus")
end

function SkillTree:getAnimalSpeedBonus(animalType)
    return self:sumEffect("animal_speed", animalType)
end

function SkillTree:getAnimalEarningBonus(animalType)
    return self:sumEffect("animal_earning", animalType)
end

function SkillTree:getExtraCapacity()
    return math.floor(self:sumEffect("extra_capacity"))
end

function SkillTree:getFoodValueBonus()
    return self:sumEffect("food_value_bonus")
end

function SkillTree:getFoodSpawnBonus()
    return self:sumEffect("food_spawn_bonus")
end

function SkillTree:getPrestigeBonus()
    return self:sumEffect("prestige_bonus")
end

function SkillTree:getFoodSkillPointChance()
    return BASE_FOOD_SKILL_CHANCE + self:sumEffect("skill_point_food_chance")
end

-- Save/load
function SkillTree:getState()
    local unlockedList = {}
    for id in pairs(self.unlocked) do
        table.insert(unlockedList, id)
    end
    return {
        points = self.points,
        totalEarned = self.totalEarned,
        unlocked = unlockedList,
    }
end

function SkillTree:loadState(state)
    if not state then return end
    self.points = state.points or 0
    self.totalEarned = state.totalEarned or 0
    self.unlocked = {}
    if state.unlocked then
        for _, id in ipairs(state.unlocked) do
            self.unlocked[id] = true
        end
    end
end

return SkillTree
