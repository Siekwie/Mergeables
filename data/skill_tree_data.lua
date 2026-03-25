-- Skill Tree data
-- 6 branches radiating from center, one per animal
-- Nodes must be unlocked in order along their branch
-- Skill tree is NOT reset by prestige

local branches = {
    -- Each branch: angle (degrees from top), animal type, nodes
    {
        animal = "cow",
        angle = 0,  -- top
        color = {0.92, 0.90, 0.85},
        nodes = {
            {
                id = "cow_1", name = "Sturdy Hooves",
                description = "+10%% cow speed",
                cost = 1,
                effect = { type = "animal_speed", animal = "cow", value = 0.10 },
            },
            {
                id = "cow_2", name = "Rich Milk",
                description = "+15%% cow earnings",
                cost = 2,
                effect = { type = "animal_earning", animal = "cow", value = 0.15 },
            },
            {
                id = "cow_3", name = "Thick Hide",
                description = "+5%% all earnings",
                cost = 3,
                effect = { type = "earning_multiplier", value = 0.05 },
            },
            {
                id = "cow_4", name = "Golden Pasture",
                description = "+1 animal capacity",
                cost = 5,
                effect = { type = "extra_capacity", value = 1 },
            },
        },
    },
    {
        animal = "chicken",
        angle = 60,
        color = {0.95, 0.85, 0.40},
        nodes = {
            {
                id = "chicken_1", name = "Quick Pecking",
                description = "+10%% chicken speed",
                cost = 1,
                effect = { type = "animal_speed", animal = "chicken", value = 0.10 },
            },
            {
                id = "chicken_2", name = "Golden Eggs",
                description = "+15%% chicken earnings",
                cost = 2,
                effect = { type = "animal_earning", animal = "chicken", value = 0.15 },
            },
            {
                id = "chicken_3", name = "Flock Mentality",
                description = "+5%% all speed",
                cost = 3,
                effect = { type = "speed_bonus", value = 0.05 },
            },
            {
                id = "chicken_4", name = "Egg Fortune",
                description = "+1%% food skill point chance",
                cost = 5,
                effect = { type = "skill_point_food_chance", value = 0.01 },
            },
        },
    },
    {
        animal = "pig",
        angle = 120,
        color = {0.95, 0.72, 0.70},
        nodes = {
            {
                id = "pig_1", name = "Keen Snout",
                description = "+10%% pig speed",
                cost = 1,
                effect = { type = "animal_speed", animal = "pig", value = 0.10 },
            },
            {
                id = "pig_2", name = "Truffle Hunter",
                description = "+15%% pig earnings",
                cost = 2,
                effect = { type = "animal_earning", animal = "pig", value = 0.15 },
            },
            {
                id = "pig_3", name = "Feast",
                description = "+10%% food value",
                cost = 3,
                effect = { type = "food_value_bonus", value = 0.10 },
            },
            {
                id = "pig_4", name = "Glutton's Bounty",
                description = "+8%% all earnings",
                cost = 5,
                effect = { type = "earning_multiplier", value = 0.08 },
            },
        },
    },
    {
        animal = "goat",
        angle = 180,  -- bottom
        color = {0.75, 0.65, 0.55},
        nodes = {
            {
                id = "goat_1", name = "Mountain Climb",
                description = "+10%% goat speed",
                cost = 1,
                effect = { type = "animal_speed", animal = "goat", value = 0.10 },
            },
            {
                id = "goat_2", name = "Hardy Grazer",
                description = "+15%% goat earnings",
                cost = 2,
                effect = { type = "animal_earning", animal = "goat", value = 0.15 },
            },
            {
                id = "goat_3", name = "Iron Will",
                description = "+5%% prestige points",
                cost = 3,
                effect = { type = "prestige_bonus", value = 0.05 },
            },
            {
                id = "goat_4", name = "Alpine Mastery",
                description = "+10%% all earnings",
                cost = 5,
                effect = { type = "earning_multiplier", value = 0.10 },
            },
        },
    },
    {
        animal = "cat",
        angle = 240,
        color = {0.85, 0.55, 0.25},
        nodes = {
            {
                id = "cat_1", name = "Quick Paws",
                description = "+10%% cat speed",
                cost = 1,
                effect = { type = "animal_speed", animal = "cat", value = 0.10 },
            },
            {
                id = "cat_2", name = "Hunter's Prize",
                description = "+15%% cat earnings",
                cost = 2,
                effect = { type = "animal_earning", animal = "cat", value = 0.15 },
            },
            {
                id = "cat_3", name = "Nine Lives",
                description = "+8%% food spawn rate",
                cost = 3,
                effect = { type = "food_spawn_bonus", value = 0.08 },
            },
            {
                id = "cat_4", name = "Lucky Charm",
                description = "+5%% all earnings",
                cost = 5,
                effect = { type = "earning_multiplier", value = 0.05 },
            },
        },
    },
    {
        animal = "sheep",
        angle = 300,
        color = {0.85, 0.85, 0.90},
        nodes = {
            {
                id = "sheep_1", name = "Soft Wool",
                description = "+10%% sheep speed",
                cost = 1,
                effect = { type = "animal_speed", animal = "sheep", value = 0.10 },
            },
            {
                id = "sheep_2", name = "Premium Fleece",
                description = "+15%% sheep earnings",
                cost = 2,
                effect = { type = "animal_earning", animal = "sheep", value = 0.15 },
            },
            {
                id = "sheep_3", name = "Herd Growth",
                description = "+1 animal capacity",
                cost = 3,
                effect = { type = "extra_capacity", value = 1 },
            },
            {
                id = "sheep_4", name = "Shepherd's Blessing",
                description = "+8%% all speed",
                cost = 5,
                effect = { type = "speed_bonus", value = 0.08 },
            },
        },
    },
}

return branches
