local Economy = {}

-- Calculate upgrade cost at a given level
function Economy.upgradeCost(upgradeData, level)
    return math.floor(upgradeData.baseCost * (upgradeData.costScale ^ level))
end

-- Calculate animal purchase cost based on how many you own of that type
function Economy.animalCost(animalData, ownedCount)
    return math.floor(animalData.baseCost * (animalData.costScale ^ ownedCount))
end

-- Prestige tier 1: Stars from total money earned
function Economy.calcPrestigePoints(totalEarned)
    if totalEarned < 1000 then return 0 end
    return math.floor(math.sqrt(totalEarned / 1000))
end

-- Prestige tier 2: Crowns from total Stars earned
function Economy.calcT2Points(totalT1Earned)
    if totalT1Earned < 10 then return 0 end
    return math.floor(math.sqrt(totalT1Earned / 10))
end

-- Prestige tier 3: Diamonds from total Crowns earned
function Economy.calcT3Points(totalT2Earned)
    if totalT2Earned < 5 then return 0 end
    return math.floor(math.sqrt(totalT2Earned / 5))
end

-- Format money for display
function Economy.formatMoney(amount)
    local suffixes = {"", "K", "M", "B", "T", "Q"}
    local tier = 1
    local scaled = math.abs(amount)
    while scaled >= 1000 and tier < #suffixes do
        scaled = scaled / 1000
        tier = tier + 1
    end
    local prefix = amount < 0 and "-" or ""
    if tier == 1 then
        return prefix .. "$" .. tostring(math.floor(scaled))
    else
        return prefix .. "$" .. string.format("%.1f", scaled) .. suffixes[tier]
    end
end

-- Calculate animal level-up cost
function Economy.animalLevelUpCost(animalData, level)
    return math.floor(animalData.levelUpBaseCost * (animalData.levelUpCostScale ^ level))
end

-- Calculate XP needed for next animal level
function Economy.animalXPNeeded(animalData, level)
    return math.floor(animalData.xpPerLevel * (animalData.xpScale ^ level))
end

return Economy
