local Economy = {}

-- Calculate upgrade cost at a given level
function Economy.upgradeCost(upgradeData, level)
    return math.floor(upgradeData.baseCost * (upgradeData.costScale ^ level))
end

-- Calculate animal purchase cost based on how many you own of that type
function Economy.animalCost(animalData, ownedCount)
    return math.floor(animalData.baseCost * (animalData.costScale ^ ownedCount))
end

-- Calculate prestige points earned from total money this run
function Economy.calcPrestigePoints(totalEarned)
    if totalEarned < 1000 then return 0 end
    return math.floor(math.sqrt(totalEarned / 1000))
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

return Economy
