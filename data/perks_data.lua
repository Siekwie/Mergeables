-- Animal perk definitions
-- Each animal has: favoriteFood, tradeOff, maxLevelPerk
-- Perks are data-only; mechanics are implemented in src/animal.lua
return {
    -- Global perk settings
    favoriteFoodBoost = {
        speedMultiplier = 1.5,
        duration = 5.0,
    },

    -- Repulsion aura mechanic (unassigned - reserved for future skill tree)
    repulsionAura = {
        radius = 80,
        pushForce = 60,
        description = "Pushes other animals away from targeted food",
    },

    -- Per-animal definitions
    cow = {
        favoriteFood = "grass",
        tradeOff = {
            id = "cow_slow_starter",
            name = "Slow Starter",
            description = "-20% speed until first eat",
            type = "conditional_speed",
            speedPenalty = -0.20,
        },
        maxLevelPerk = {
            id = "cow_fertile_grazer",
            name = "Fertile Grazer",
            description = "Eaten food respawns 40% faster",
            type = "respawn_speedup",
            respawnSpeedup = 0.40,
        },
    },
    chicken = {
        favoriteFood = "corn",
        tradeOff = {
            id = "chicken_fragile",
            name = "Fragile",
            description = "-15% earnings from non-favorite food",
            type = "earning_modifier",
            nonFavoritePenalty = -0.15,
        },
        maxLevelPerk = nil,
    },
    pig = {
        favoriteFood = "mushrooms",
        tradeOff = {
            id = "pig_lazy",
            name = "Lazy",
            description = "+30% idle duration",
            type = "idle_modifier",
            idlePenaltyMult = 0.30,
        },
        maxLevelPerk = {
            id = "pig_glutton",
            name = "Glutton",
            description = "Eats 30% faster, +5% earning per consecutive eat (max 5 stacks)",
            type = "eat_speed_stack",
            eatSpeedup = 0.30,
            stackBonus = 0.05,
            maxStacks = 5,
            stackDecayTime = 8.0,
        },
    },
    sheep = {
        favoriteFood = "flowers",
        tradeOff = {
            id = "sheep_timid",
            name = "Timid",
            description = "Avoids food another animal is already eating",
            type = "food_filter_occupied",
        },
        maxLevelPerk = {
            id = "sheep_herd_instinct",
            name = "Herd Instinct",
            description = "+5% earnings per nearby sheep (max 25%)",
            type = "proximity_bonus",
            radius = 150,
            perAnimalBonus = 0.05,
            maxBonus = 0.25,
        },
    },
    cat = {
        favoriteFood = "fish",
        tradeOff = {
            id = "cat_picky",
            name = "Picky Eater",
            description = "Only eats fish and berries",
            type = "food_filter_type",
            allowedFoods = {"fish", "berries"},
        },
        maxLevelPerk = {
            id = "cat_lucky_catch",
            name = "Lucky Catch",
            description = "10% chance to earn 3x from eating",
            type = "crit_chance",
            critChance = 0.10,
            critMult = 3.0,
        },
    },
    goat = {
        favoriteFood = "berries",
        tradeOff = {
            id = "goat_stubborn",
            name = "Stubborn",
            description = "+50% idle time, won't chase food >300px away",
            type = "idle_modifier_range",
            idlePenaltyMult = 0.50,
            maxFoodRange = 300,
        },
        maxLevelPerk = {
            id = "goat_iron_stomach",
            name = "Iron Stomach",
            description = "+20% value from all food, ignores own trade-off",
            type = "universal_bonus",
            allFoodBonus = 0.20,
            ignoreTradeOff = true,
        },
    },
}
