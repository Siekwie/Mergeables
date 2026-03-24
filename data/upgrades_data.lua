-- Upgrade definitions
-- Each upgrade has a base cost, scaling factor, and effect per level
return {
    {
        id = "animal_speed",
        name = "Swift Hooves",
        description = "Animals move %d%% faster",
        baseCost = 25,
        costScale = 1.5,
        effectPerLevel = 10,  -- +10% speed per level
        maxLevel = 50,
    },
    {
        id = "earning_bonus",
        name = "Rich Harvest",
        description = "Animals earn %d%% more",
        baseCost = 50,
        costScale = 1.6,
        effectPerLevel = 15,  -- +15% earnings per level
        maxLevel = 50,
    },
    {
        id = "food_spawn_rate",
        name = "Fertile Fields",
        description = "Food spawns %d%% faster",
        baseCost = 40,
        costScale = 1.55,
        effectPerLevel = 12,  -- +12% spawn rate per level
        maxLevel = 30,
    },
    {
        id = "food_value",
        name = "Premium Feed",
        description = "Food is worth %d%% more",
        baseCost = 75,
        costScale = 1.65,
        effectPerLevel = 20,  -- +20% food value per level
        maxLevel = 30,
    },
    {
        id = "max_animals",
        name = "Bigger Pasture",
        description = "+%d animal capacity",
        baseCost = 100,
        costScale = 2.0,
        effectPerLevel = 2,  -- +2 slots per level
        maxLevel = 20,
    },
    {
        id = "offline_rate",
        name = "Caretaker",
        description = "Offline earnings +%d%%",
        baseCost = 80,
        costScale = 1.8,
        effectPerLevel = 10,  -- +10% offline rate per level (base 10%)
        maxLevel = 20,
    },
    {
        id = "offline_cap",
        name = "Night Watch",
        description = "Offline cap +%d hrs",
        baseCost = 200,
        costScale = 2.2,
        effectPerLevel = 2,  -- +2 hours per level (base 2h, max ~24h with upgrades)
        maxLevel = 11,
    },
    {
        id = "plot_size",
        name = "Expand Plot",
        description = "+%d%% field size",
        baseCost = 150,
        costScale = 2.5,
        effectPerLevel = 25,  -- +25% field size per level
        maxLevel = 10,
    },
}
