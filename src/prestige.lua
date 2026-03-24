local Economy = require("src.economy")
local prestigeData = require("data.prestige_data")

local Prestige = {}
Prestige.__index = Prestige

function Prestige.new()
    local self = setmetatable({}, Prestige)
    -- Each tier has its own currency and upgrade levels
    self.tiers = {}
    for t = 1, 3 do
        self.tiers[t] = {
            points = 0,
            totalEarned = 0,
            levels = {},
        }
        for _, upg in ipairs(prestigeData[t].upgrades) do
            self.tiers[t].levels[upg.id] = 0
        end
    end
    return self
end

-- Get upgrade level for a specific tier
function Prestige:getLevel(tier, upgId)
    return self.tiers[tier] and self.tiers[tier].levels[upgId] or 0
end

-- Get upgrade data by id within a tier
function Prestige:getUpgradeData(tier, upgId)
    for _, upg in ipairs(prestigeData[tier].upgrades) do
        if upg.id == upgId then return upg end
    end
    return nil
end

-- Cost for next level of an upgrade
function Prestige:getUpgradeCost(tier, upgId)
    local upg = self:getUpgradeData(tier, upgId)
    if not upg then return math.huge end
    local level = self:getLevel(tier, upgId)
    return math.floor(upg.baseCost * (upg.costScale ^ level))
end

function Prestige:canBuyUpgrade(tier, upgId)
    local upg = self:getUpgradeData(tier, upgId)
    if not upg then return false end
    local level = self:getLevel(tier, upgId)
    if level >= upg.maxLevel then return false end
    local cost = self:getUpgradeCost(tier, upgId)
    return self.tiers[tier].points >= cost
end

function Prestige:buyUpgrade(tier, upgId)
    if not self:canBuyUpgrade(tier, upgId) then return false end
    local cost = self:getUpgradeCost(tier, upgId)
    self.tiers[tier].points = self.tiers[tier].points - cost
    self.tiers[tier].levels[upgId] = self:getLevel(tier, upgId) + 1
    return true
end

function Prestige:addPoints(tier, points)
    self.tiers[tier].points = self.tiers[tier].points + points
    self.tiers[tier].totalEarned = self.tiers[tier].totalEarned + points
end

-- Reset a tier's currency and upgrades (used by higher tier prestiges)
function Prestige:resetTier(tier)
    self.tiers[tier].points = 0
    self.tiers[tier].totalEarned = 0
    for id in pairs(self.tiers[tier].levels) do
        self.tiers[tier].levels[id] = 0
    end
end

-- Sum effect of a given type across specified tiers
function Prestige:sumEffect(effectType, tiers)
    local total = 0
    for _, t in ipairs(tiers) do
        for _, upg in ipairs(prestigeData[t].upgrades) do
            if upg.effect.type == effectType then
                local level = self:getLevel(t, upg.id)
                if level > 0 then
                    if upg.effect.perLevel then
                        total = total + upg.effect.perLevel * level
                    elseif upg.effect.value then
                        total = total + upg.effect.value
                    end
                end
            end
        end
    end
    return total
end

-- Sum effect across all 3 tiers
function Prestige:sumAllEffect(effectType)
    return self:sumEffect(effectType, {1, 2, 3})
end

-- Unlock animal checks (tier 1 only, one-time unlocks)
function Prestige:getUnlockedAnimals()
    local animals = {"cow"}
    for _, upg in ipairs(prestigeData[1].upgrades) do
        if upg.effect.type == "unlock_animal" then
            local level = self:getLevel(1, upg.id)
            if level >= 1 then
                table.insert(animals, upg.effect.value)
            end
        end
    end
    return animals
end

function Prestige:getEarningMultiplier()
    return self:sumAllEffect("earning_multiplier")
end

function Prestige:getSpeedBonus()
    return self:sumAllEffect("speed_bonus")
end

function Prestige:getFoodSpawnBonus()
    return self:sumAllEffect("food_spawn_bonus")
end

function Prestige:getExtraCapacity()
    return math.floor(self:sumAllEffect("extra_capacity"))
end

function Prestige:getStartingMoney()
    return self:sumEffect("starting_money", {1})
end

function Prestige:getPlotSizeBonus()
    return self:sumAllEffect("plot_size_bonus")
end

function Prestige:getStartingT1Currency()
    return math.floor(self:sumEffect("starting_t1_currency", {2}))
end

function Prestige:getStartingT2Currency()
    return math.floor(self:sumEffect("starting_t2_currency", {3}))
end

function Prestige:getT1CurrencyBonus()
    return self:sumEffect("t1_currency_bonus", {3})
end

function Prestige:getT2CurrencyBonus()
    return self:sumEffect("t2_currency_bonus", {3})
end

-- State serialization
function Prestige:getState()
    local state = {}
    for t = 1, 3 do
        state[t] = {
            points = self.tiers[t].points,
            totalEarned = self.tiers[t].totalEarned,
            levels = {},
        }
        for id, lvl in pairs(self.tiers[t].levels) do
            state[t].levels[id] = lvl
        end
    end
    return state
end

function Prestige:loadState(state)
    if not state then return end
    for t = 1, 3 do
        if state[t] then
            self.tiers[t].points = state[t].points or 0
            self.tiers[t].totalEarned = state[t].totalEarned or 0
            if state[t].levels then
                for id, lvl in pairs(state[t].levels) do
                    self.tiers[t].levels[id] = lvl
                end
            end
        end
    end
end

return Prestige
