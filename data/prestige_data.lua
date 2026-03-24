-- 3-tier prestige system
-- Each tier has its own currency, upgrades, and reset scope
return {
    -- TIER 1: Stars
    -- Resets: cash, animals, animal levels
    -- Keeps: normal upgrades, all prestige progress
    [1] = {
        name = "Stars",
        icon = "*",
        color = {1, 0.85, 0.25},
        resetLabel = "Reset cash, animals & animal levels",
        upgrades = {
            {
                id = "p1_unlock_chicken", name = "Chicken Coop",
                description = "Unlock chickens",
                baseCost = 3, costScale = 1, maxLevel = 1,
                effect = { type = "unlock_animal", value = "chicken" },
            },
            {
                id = "p1_unlock_pig", name = "Pig Pen",
                description = "Unlock pigs",
                baseCost = 5, costScale = 1, maxLevel = 1,
                effect = { type = "unlock_animal", value = "pig" },
            },
            {
                id = "p1_unlock_sheep", name = "Sheep Meadow",
                description = "Unlock sheep",
                baseCost = 8, costScale = 1, maxLevel = 1,
                effect = { type = "unlock_animal", value = "sheep" },
            },
            {
                id = "p1_unlock_goat", name = "Goat Cliff",
                description = "Unlock goats",
                baseCost = 10, costScale = 1, maxLevel = 1,
                effect = { type = "unlock_animal", value = "goat" },
            },
            {
                id = "p1_earning", name = "Keen Eye",
                description = "+15%% earnings per level",
                baseCost = 2, costScale = 1.6, maxLevel = 10,
                effect = { type = "earning_multiplier", perLevel = 0.15 },
            },
            {
                id = "p1_speed", name = "Quick Feet",
                description = "+10%% speed per level",
                baseCost = 2, costScale = 1.5, maxLevel = 10,
                effect = { type = "speed_bonus", perLevel = 0.10 },
            },
            {
                id = "p1_starting_money", name = "Head Start",
                description = "+$200 starting cash per level",
                baseCost = 1, costScale = 1.8, maxLevel = 8,
                effect = { type = "starting_money", perLevel = 200 },
            },
            {
                id = "p1_food_spawn", name = "Green Thumb",
                description = "+12%% food spawn per level",
                baseCost = 2, costScale = 1.5, maxLevel = 5,
                effect = { type = "food_spawn_bonus", perLevel = 0.12 },
            },
            {
                id = "p1_capacity", name = "Wide Pasture",
                description = "+2 animal slots per level",
                baseCost = 3, costScale = 1.8, maxLevel = 5,
                effect = { type = "extra_capacity", perLevel = 2 },
            },
        },
    },

    -- TIER 2: Crowns
    -- Resets: everything T1 resets + T1 currency & upgrades + normal upgrades
    -- Keeps: T2 and T3 progress
    [2] = {
        name = "Crowns",
        icon = "^",
        color = {0.60, 0.45, 0.90},
        resetLabel = "Reset T1 progress, upgrades & all below",
        upgrades = {
            {
                id = "p2_earning", name = "Sharp Instincts",
                description = "+25%% earnings per level",
                baseCost = 2, costScale = 1.8, maxLevel = 10,
                effect = { type = "earning_multiplier", perLevel = 0.25 },
            },
            {
                id = "p2_speed", name = "Swift Wind",
                description = "+15%% speed per level",
                baseCost = 2, costScale = 1.7, maxLevel = 10,
                effect = { type = "speed_bonus", perLevel = 0.15 },
            },
            {
                id = "p2_starting_stars", name = "Star Keeper",
                description = "+2 starting Stars per level",
                baseCost = 3, costScale = 2.0, maxLevel = 5,
                effect = { type = "starting_t1_currency", perLevel = 2 },
            },
            {
                id = "p2_capacity", name = "Grand Ranch",
                description = "+3 animal slots per level",
                baseCost = 3, costScale = 2.0, maxLevel = 5,
                effect = { type = "extra_capacity", perLevel = 3 },
            },
            {
                id = "p2_plot_size", name = "Land Baron",
                description = "+15%% field size per level",
                baseCost = 4, costScale = 2.2, maxLevel = 5,
                effect = { type = "plot_size_bonus", perLevel = 0.15 },
            },
            {
                id = "p2_food_spawn", name = "Fertile Grounds",
                description = "+20%% food spawn per level",
                baseCost = 3, costScale = 1.8, maxLevel = 5,
                effect = { type = "food_spawn_bonus", perLevel = 0.20 },
            },
        },
    },

    -- TIER 3: Diamonds
    -- Resets: everything except T3 progress
    -- Keeps: only T3 upgrades
    [3] = {
        name = "Diamonds",
        icon = "<>",
        color = {0.40, 0.85, 0.95},
        resetLabel = "Reset everything except Diamonds",
        upgrades = {
            {
                id = "p3_global_mult", name = "Golden Touch",
                description = "+50%% all earnings per level",
                baseCost = 2, costScale = 2.0, maxLevel = 10,
                effect = { type = "earning_multiplier", perLevel = 0.50 },
            },
            {
                id = "p3_starting_crowns", name = "Crown Reserve",
                description = "+1 starting Crown per level",
                baseCost = 3, costScale = 2.5, maxLevel = 5,
                effect = { type = "starting_t2_currency", perLevel = 1 },
            },
            {
                id = "p3_speed", name = "Lightning Hooves",
                description = "+20%% speed per level",
                baseCost = 2, costScale = 2.0, maxLevel = 5,
                effect = { type = "speed_bonus", perLevel = 0.20 },
            },
            {
                id = "p3_t1_currency", name = "Star Forge",
                description = "+25%% Stars earned per level",
                baseCost = 3, costScale = 2.0, maxLevel = 5,
                effect = { type = "t1_currency_bonus", perLevel = 0.25 },
            },
            {
                id = "p3_t2_currency", name = "Crown Mint",
                description = "+25%% Crowns earned per level",
                baseCost = 4, costScale = 2.5, maxLevel = 5,
                effect = { type = "t2_currency_bonus", perLevel = 0.25 },
            },
            {
                id = "p3_capacity", name = "Endless Fields",
                description = "+5 animal slots per level",
                baseCost = 3, costScale = 2.5, maxLevel = 3,
                effect = { type = "extra_capacity", perLevel = 5 },
            },
        },
    },
}
