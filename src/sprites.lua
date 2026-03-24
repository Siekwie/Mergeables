-- Programmatic sprite drawing for animals and food
-- Each animal type has a unique silhouette drawn with Love2D primitives

local Sprites = {}

function Sprites.drawAnimal(animalType, tier, x, y, size, flipX, bobOffset)
    bobOffset = bobOffset or 0
    local data = require("data.animals")[animalType]
    if not data then return end

    local bc = data.bodyColor
    local sc = data.spotColor
    local dy = bobOffset

    love.graphics.push()
    love.graphics.translate(x, y + dy)
    if flipX then
        love.graphics.scale(-1, 1)
    end

    if animalType == "cow" then
        Sprites.drawCow(size, bc, sc, tier)
    elseif animalType == "chicken" then
        Sprites.drawChicken(size, bc, sc, tier)
    elseif animalType == "pig" then
        Sprites.drawPig(size, bc, sc, tier)
    elseif animalType == "sheep" then
        Sprites.drawSheep(size, bc, sc, tier)
    else
        -- Fallback: generic blob
        love.graphics.setColor(bc)
        love.graphics.ellipse("fill", 0, 0, size * 0.4, size * 0.3)
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.circle("fill", size * 0.15, -size * 0.1, size * 0.04)
    end

    -- Tier indicator (stars)
    if tier and tier > 1 then
        love.graphics.setColor(1, 0.85, 0.15)
        local starSize = math.max(3, size * 0.05)
        for i = 1, math.min(tier, 4) do
            local sx = (i - (math.min(tier, 4) + 1) / 2) * (starSize * 2.5)
            love.graphics.circle("fill", sx, -size * 0.45, starSize)
        end
    end

    love.graphics.pop()
end

function Sprites.drawCow(size, bc, sc, tier)
    local hw = size * 0.40  -- half width
    local hh = size * 0.28  -- half height

    -- Body
    love.graphics.setColor(bc)
    love.graphics.ellipse("fill", 0, 0, hw, hh)

    -- Spots
    love.graphics.setColor(sc)
    love.graphics.ellipse("fill", -hw * 0.3, -hh * 0.1, hw * 0.18, hh * 0.22)
    love.graphics.ellipse("fill", hw * 0.2, hh * 0.15, hw * 0.15, hh * 0.18)

    -- Head
    love.graphics.setColor(bc)
    love.graphics.ellipse("fill", hw * 0.75, -hh * 0.2, hw * 0.32, hh * 0.45)

    -- Snout
    love.graphics.setColor(0.90, 0.75, 0.70)
    love.graphics.ellipse("fill", hw * 0.95, -hh * 0.05, hw * 0.15, hh * 0.2)

    -- Eyes
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", hw * 0.72, -hh * 0.35, size * 0.03)

    -- Ears
    love.graphics.setColor(bc[1] * 0.9, bc[2] * 0.9, bc[3] * 0.9)
    love.graphics.ellipse("fill", hw * 0.55, -hh * 0.55, hw * 0.1, hh * 0.18)

    -- Legs
    love.graphics.setColor(sc)
    local legW = hw * 0.1
    local legH = hh * 0.45
    love.graphics.rectangle("fill", -hw * 0.5 - legW/2, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", -hw * 0.15 - legW/2, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", hw * 0.15 - legW/2, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", hw * 0.45 - legW/2, hh * 0.7, legW, legH)

    -- Golden glow for max tier
    if tier and tier >= 4 then
        love.graphics.setColor(1, 0.85, 0.15, 0.15)
        love.graphics.ellipse("fill", 0, 0, hw * 1.3, hh * 1.3)
    end
end

function Sprites.drawChicken(size, bc, sc, tier)
    local hw = size * 0.30
    local hh = size * 0.28

    -- Body
    love.graphics.setColor(bc)
    love.graphics.ellipse("fill", 0, 0, hw, hh)

    -- Wing
    love.graphics.setColor(bc[1] * 0.85, bc[2] * 0.85, bc[3] * 0.85)
    love.graphics.ellipse("fill", -hw * 0.2, 0, hw * 0.5, hh * 0.55)

    -- Head
    love.graphics.setColor(bc)
    love.graphics.circle("fill", hw * 0.65, -hh * 0.5, hw * 0.4)

    -- Beak
    love.graphics.setColor(0.95, 0.65, 0.15)
    love.graphics.polygon("fill",
        hw * 0.95, -hh * 0.45,
        hw * 1.2, -hh * 0.35,
        hw * 0.95, -hh * 0.25
    )

    -- Comb
    love.graphics.setColor(sc)
    love.graphics.circle("fill", hw * 0.55, -hh * 0.85, hw * 0.12)
    love.graphics.circle("fill", hw * 0.70, -hh * 0.90, hw * 0.14)
    love.graphics.circle("fill", hw * 0.85, -hh * 0.82, hw * 0.11)

    -- Eye
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", hw * 0.75, -hh * 0.55, size * 0.025)

    -- Legs
    love.graphics.setColor(0.90, 0.60, 0.15)
    love.graphics.setLineWidth(2)
    love.graphics.line(-hw * 0.15, hh * 0.8, -hw * 0.15, hh * 1.3)
    love.graphics.line(hw * 0.15, hh * 0.8, hw * 0.15, hh * 1.3)
    love.graphics.setLineWidth(1)

    -- Tail feathers
    love.graphics.setColor(bc[1] * 0.8, bc[2] * 0.8, bc[3] * 0.8)
    love.graphics.ellipse("fill", -hw * 0.8, -hh * 0.2, hw * 0.25, hh * 0.4)

    if tier and tier >= 4 then
        love.graphics.setColor(1, 0.85, 0.15, 0.15)
        love.graphics.circle("fill", 0, 0, hw * 1.3)
    end
end

function Sprites.drawPig(size, bc, sc, tier)
    local hw = size * 0.38
    local hh = size * 0.30

    -- Body (round)
    love.graphics.setColor(bc)
    love.graphics.ellipse("fill", 0, 0, hw, hh)

    -- Head
    love.graphics.setColor(bc)
    love.graphics.circle("fill", hw * 0.7, -hh * 0.1, hw * 0.38)

    -- Snout
    love.graphics.setColor(sc)
    love.graphics.ellipse("fill", hw * 0.98, -hh * 0.0, hw * 0.18, hh * 0.22)
    -- Nostrils
    love.graphics.setColor(bc[1] * 0.6, bc[2] * 0.5, bc[3] * 0.5)
    love.graphics.circle("fill", hw * 0.94, -hh * 0.04, size * 0.02)
    love.graphics.circle("fill", hw * 1.02, -hh * 0.04, size * 0.02)

    -- Ears
    love.graphics.setColor(sc)
    love.graphics.ellipse("fill", hw * 0.45, -hh * 0.55, hw * 0.14, hh * 0.22)
    love.graphics.ellipse("fill", hw * 0.75, -hh * 0.55, hw * 0.14, hh * 0.22)

    -- Eye
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", hw * 0.65, -hh * 0.25, size * 0.03)

    -- Legs
    love.graphics.setColor(sc)
    local legW = hw * 0.12
    local legH = hh * 0.4
    love.graphics.rectangle("fill", -hw * 0.45, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", -hw * 0.1, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", hw * 0.15, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", hw * 0.4, hh * 0.7, legW, legH)

    -- Curly tail
    love.graphics.setColor(sc)
    love.graphics.setLineWidth(2)
    local segments = 8
    local points = {}
    for i = 0, segments do
        local t = i / segments
        local angle = t * math.pi * 2.5
        table.insert(points, -hw * 0.85 - math.cos(angle) * hw * 0.12)
        table.insert(points, -hh * 0.1 + math.sin(angle) * hh * 0.12 - t * hh * 0.15)
    end
    if #points >= 4 then
        love.graphics.line(points)
    end
    love.graphics.setLineWidth(1)

    if tier and tier >= 4 then
        love.graphics.setColor(1, 0.85, 0.15, 0.15)
        love.graphics.ellipse("fill", 0, 0, hw * 1.3, hh * 1.3)
    end
end

function Sprites.drawSheep(size, bc, sc, tier)
    local hw = size * 0.38
    local hh = size * 0.30

    -- Fluffy body (multiple overlapping circles)
    love.graphics.setColor(bc)
    love.graphics.ellipse("fill", 0, 0, hw, hh)
    -- Wool bumps
    local bumpR = hw * 0.22
    love.graphics.circle("fill", -hw * 0.4, -hh * 0.3, bumpR)
    love.graphics.circle("fill", 0, -hh * 0.45, bumpR)
    love.graphics.circle("fill", hw * 0.35, -hh * 0.3, bumpR)
    love.graphics.circle("fill", -hw * 0.5, hh * 0.1, bumpR)
    love.graphics.circle("fill", hw * 0.45, hh * 0.1, bumpR)

    -- Head (dark)
    love.graphics.setColor(sc)
    love.graphics.ellipse("fill", hw * 0.72, -hh * 0.1, hw * 0.28, hh * 0.35)

    -- Eyes
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", hw * 0.78, -hh * 0.22, size * 0.035)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", hw * 0.80, -hh * 0.22, size * 0.02)

    -- Ears
    love.graphics.setColor(sc[1] * 0.8, sc[2] * 0.8, sc[3] * 0.8)
    love.graphics.ellipse("fill", hw * 0.52, -hh * 0.38, hw * 0.08, hh * 0.15)
    love.graphics.ellipse("fill", hw * 0.88, -hh * 0.35, hw * 0.08, hh * 0.15)

    -- Legs
    love.graphics.setColor(sc)
    local legW = hw * 0.1
    local legH = hh * 0.5
    love.graphics.rectangle("fill", -hw * 0.4, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", -hw * 0.1, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", hw * 0.15, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", hw * 0.4, hh * 0.7, legW, legH)

    if tier and tier >= 4 then
        love.graphics.setColor(1, 0.85, 0.15, 0.15)
        love.graphics.ellipse("fill", 0, 0, hw * 1.3, hh * 1.3)
    end
end

function Sprites.drawFood(foodType, x, y, size)
    love.graphics.push()
    love.graphics.translate(x, y)

    if foodType == "grass" then
        love.graphics.setColor(0.30, 0.70, 0.25)
        love.graphics.ellipse("fill", 0, 0, size * 0.5, size * 0.25)
        -- Blades
        love.graphics.setColor(0.25, 0.65, 0.20)
        love.graphics.setLineWidth(2)
        love.graphics.line(-size * 0.15, 0, -size * 0.2, -size * 0.35)
        love.graphics.line(0, 0, 0, -size * 0.4)
        love.graphics.line(size * 0.15, 0, size * 0.2, -size * 0.3)
        love.graphics.setLineWidth(1)
    elseif foodType == "berries" then
        -- Bush
        love.graphics.setColor(0.25, 0.50, 0.20)
        love.graphics.ellipse("fill", 0, 0, size * 0.45, size * 0.3)
        -- Berries
        love.graphics.setColor(0.80, 0.15, 0.20)
        love.graphics.circle("fill", -size * 0.15, -size * 0.1, size * 0.08)
        love.graphics.circle("fill", size * 0.1, -size * 0.15, size * 0.07)
        love.graphics.circle("fill", size * 0.0, size * 0.05, size * 0.08)
        love.graphics.circle("fill", size * 0.2, 0.0, size * 0.06)
    elseif foodType == "corn" then
        -- Stalk
        love.graphics.setColor(0.30, 0.60, 0.20)
        love.graphics.setLineWidth(2)
        love.graphics.line(0, size * 0.2, 0, -size * 0.4)
        love.graphics.setLineWidth(1)
        -- Cob
        love.graphics.setColor(0.95, 0.85, 0.25)
        love.graphics.ellipse("fill", 0, -size * 0.1, size * 0.12, size * 0.25)
        -- Leaves
        love.graphics.setColor(0.30, 0.60, 0.20)
        love.graphics.ellipse("fill", -size * 0.2, 0, size * 0.2, size * 0.06)
        love.graphics.ellipse("fill", size * 0.2, -size * 0.2, size * 0.2, size * 0.06)
    end

    love.graphics.pop()
end

return Sprites
