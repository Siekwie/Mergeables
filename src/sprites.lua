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
    elseif animalType == "goat" then
        Sprites.drawGoat(size, bc, sc, tier)
    elseif animalType == "cat" then
        Sprites.drawCat(size, bc, sc, tier)
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

function Sprites.drawGoat(size, bc, sc, tier)
    local hw = size * 0.40
    local hh = size * 0.28

    -- Body (slightly rectangular feel)
    love.graphics.setColor(bc)
    love.graphics.ellipse("fill", 0, 0, hw, hh)

    -- Head
    love.graphics.setColor(bc)
    love.graphics.ellipse("fill", hw * 0.72, -hh * 0.25, hw * 0.28, hh * 0.40)

    -- Horns (curved backward from top of head)
    love.graphics.setColor(sc)
    love.graphics.setLineWidth(math.max(2, size * 0.04))
    -- Left horn
    love.graphics.line(
        hw * 0.62, -hh * 0.55,
        hw * 0.50, -hh * 0.90,
        hw * 0.35, -hh * 1.05
    )
    -- Right horn
    love.graphics.line(
        hw * 0.82, -hh * 0.55,
        hw * 0.70, -hh * 0.90,
        hw * 0.55, -hh * 1.05
    )
    love.graphics.setLineWidth(1)

    -- Ears (angled to the sides)
    love.graphics.setColor(bc[1] * 0.85, bc[2] * 0.85, bc[3] * 0.85)
    love.graphics.ellipse("fill", hw * 0.50, -hh * 0.40, hw * 0.10, hh * 0.15)
    love.graphics.ellipse("fill", hw * 0.92, -hh * 0.35, hw * 0.10, hh * 0.15)

    -- Eyes
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", hw * 0.68, -hh * 0.32, size * 0.03)
    love.graphics.circle("fill", hw * 0.82, -hh * 0.30, size * 0.025)

    -- Beard (small triangle hanging below chin)
    love.graphics.setColor(sc)
    love.graphics.polygon("fill",
        hw * 0.72, hh * 0.10,
        hw * 0.78, hh * 0.10,
        hw * 0.75, hh * 0.35
    )

    -- Legs (slightly thinner than cow legs)
    love.graphics.setColor(sc)
    local legW = hw * 0.08
    local legH = hh * 0.50
    love.graphics.rectangle("fill", -hw * 0.50 - legW/2, hh * 0.70, legW, legH)
    love.graphics.rectangle("fill", -hw * 0.15 - legW/2, hh * 0.70, legW, legH)
    love.graphics.rectangle("fill", hw * 0.15 - legW/2, hh * 0.70, legW, legH)
    love.graphics.rectangle("fill", hw * 0.45 - legW/2, hh * 0.70, legW, legH)

    -- Hooves
    love.graphics.setColor(sc[1] * 0.6, sc[2] * 0.6, sc[3] * 0.6)
    local hoofH = hh * 0.10
    love.graphics.rectangle("fill", -hw * 0.50 - legW/2, hh * 0.70 + legH - hoofH, legW, hoofH)
    love.graphics.rectangle("fill", -hw * 0.15 - legW/2, hh * 0.70 + legH - hoofH, legW, hoofH)
    love.graphics.rectangle("fill", hw * 0.15 - legW/2, hh * 0.70 + legH - hoofH, legW, hoofH)
    love.graphics.rectangle("fill", hw * 0.45 - legW/2, hh * 0.70 + legH - hoofH, legW, hoofH)

    -- Tail (short upward-pointing line)
    love.graphics.setColor(sc)
    love.graphics.setLineWidth(2)
    love.graphics.line(-hw * 0.85, -hh * 0.05, -hw * 0.95, -hh * 0.35)
    love.graphics.setLineWidth(1)
end

function Sprites.drawCat(size, bc, sc, tier)
    local hw = size * 0.38
    local hh = size * 0.28

    -- Body (horizontal ellipse)
    love.graphics.setColor(bc)
    love.graphics.ellipse("fill", 0, 0, hw, hh)

    -- Tabby stripes on body
    love.graphics.setColor(sc)
    love.graphics.setLineWidth(math.max(1, size * 0.02))
    love.graphics.line(-hw * 0.2, -hh * 0.6, -hw * 0.15, hh * 0.5)
    love.graphics.line(hw * 0.05, -hh * 0.65, hw * 0.1, hh * 0.45)
    love.graphics.line(hw * 0.3, -hh * 0.55, hw * 0.3, hh * 0.4)
    love.graphics.setLineWidth(1)

    -- Head (circle, offset forward)
    love.graphics.setColor(bc)
    love.graphics.circle("fill", hw * 0.72, -hh * 0.2, hw * 0.38)

    -- Ears (pointed triangles)
    love.graphics.setColor(bc)
    love.graphics.polygon("fill",
        hw * 0.50, -hh * 0.50,
        hw * 0.58, -hh * 1.15,
        hw * 0.72, -hh * 0.50
    )
    love.graphics.polygon("fill",
        hw * 0.78, -hh * 0.50,
        hw * 0.88, -hh * 1.12,
        hw * 0.98, -hh * 0.48
    )
    -- Inner ear (accent color)
    love.graphics.setColor(sc)
    love.graphics.polygon("fill",
        hw * 0.54, -hh * 0.55,
        hw * 0.58, -hh * 0.95,
        hw * 0.68, -hh * 0.55
    )
    love.graphics.polygon("fill",
        hw * 0.82, -hh * 0.55,
        hw * 0.88, -hh * 0.92,
        hw * 0.94, -hh * 0.53
    )

    -- Eyes (green/yellow)
    love.graphics.setColor(0.45, 0.75, 0.20)
    love.graphics.circle("fill", hw * 0.62, -hh * 0.30, size * 0.035)
    love.graphics.circle("fill", hw * 0.82, -hh * 0.28, size * 0.035)
    -- Pupils
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", hw * 0.63, -hh * 0.30, size * 0.018)
    love.graphics.circle("fill", hw * 0.83, -hh * 0.28, size * 0.018)

    -- Nose
    love.graphics.setColor(sc)
    love.graphics.circle("fill", hw * 0.72, -hh * 0.10, size * 0.025)

    -- Whiskers
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setLineWidth(1)
    -- Left whiskers
    love.graphics.line(hw * 0.55, -hh * 0.10, hw * 0.20, -hh * 0.25)
    love.graphics.line(hw * 0.55, -hh * 0.05, hw * 0.18, -hh * 0.05)
    love.graphics.line(hw * 0.55, 0, hw * 0.22, hh * 0.15)
    -- Right whiskers
    love.graphics.line(hw * 0.90, -hh * 0.10, hw * 1.25, -hh * 0.25)
    love.graphics.line(hw * 0.90, -hh * 0.05, hw * 1.28, -hh * 0.05)
    love.graphics.line(hw * 0.90, 0, hw * 1.22, hh * 0.15)

    -- Legs
    love.graphics.setColor(bc)
    local legW = hw * 0.1
    local legH = hh * 0.45
    love.graphics.rectangle("fill", -hw * 0.45, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", -hw * 0.15, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", hw * 0.15, hh * 0.7, legW, legH)
    love.graphics.rectangle("fill", hw * 0.40, hh * 0.7, legW, legH)

    -- Tail (curved series of circles)
    love.graphics.setColor(bc)
    local segments = 8
    for i = 0, segments do
        local t = i / segments
        local tx = -hw * 0.85 - math.sin(t * math.pi * 0.8) * hw * 0.35
        local ty = -hh * 0.1 - t * hh * 0.8
        local r = hw * 0.08 * (1 - t * 0.3)
        love.graphics.circle("fill", tx, ty, r)
    end
    -- Tail tip accent
    love.graphics.setColor(sc)
    love.graphics.circle("fill",
        -hw * 0.85 - math.sin(math.pi * 0.8) * hw * 0.35,
        -hh * 0.1 - hh * 0.8,
        hw * 0.06)

    -- Golden glow for max tier
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
    elseif foodType == "mushrooms" then
        -- Green mound
        love.graphics.setColor(0.30, 0.65, 0.25)
        love.graphics.ellipse("fill", 0, size * 0.15, size * 0.35, size * 0.12)
        -- Stem
        love.graphics.setColor(0.90, 0.88, 0.80)
        love.graphics.rectangle("fill", -size * 0.06, -size * 0.1, size * 0.12, size * 0.25)
        -- Cap
        love.graphics.setColor(0.55, 0.30, 0.15)
        love.graphics.ellipse("fill", 0, -size * 0.15, size * 0.22, size * 0.14)
        -- White spots
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", -size * 0.08, -size * 0.17, size * 0.035)
        love.graphics.circle("fill", size * 0.07, -size * 0.14, size * 0.03)
        love.graphics.circle("fill", 0, -size * 0.22, size * 0.025)
    elseif foodType == "fish" then
        -- Blue puddle
        love.graphics.setColor(0.40, 0.65, 0.90, 0.5)
        love.graphics.ellipse("fill", 0, size * 0.1, size * 0.4, size * 0.12)
        -- Fish body
        love.graphics.setColor(0.55, 0.70, 0.85)
        love.graphics.ellipse("fill", 0, -size * 0.05, size * 0.25, size * 0.12)
        -- Tail
        love.graphics.setColor(0.45, 0.60, 0.80)
        love.graphics.polygon("fill",
            -size * 0.22, -size * 0.05,
            -size * 0.38, -size * 0.18,
            -size * 0.38, size * 0.08
        )
        -- Eye
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.circle("fill", size * 0.12, -size * 0.08, size * 0.03)
    elseif foodType == "flowers" then
        -- Stem
        love.graphics.setColor(0.25, 0.60, 0.20)
        love.graphics.setLineWidth(2)
        love.graphics.line(0, size * 0.25, 0, -size * 0.05)
        love.graphics.setLineWidth(1)
        -- Petals (5 pink/purple circles around center)
        love.graphics.setColor(0.85, 0.40, 0.70)
        local petalR = size * 0.1
        local centerY = -size * 0.15
        for i = 0, 4 do
            local angle = (i / 5) * math.pi * 2 - math.pi / 2
            local px = math.cos(angle) * size * 0.12
            local py = centerY + math.sin(angle) * size * 0.12
            love.graphics.circle("fill", px, py, petalR)
        end
        -- Center
        love.graphics.setColor(0.95, 0.85, 0.25)
        love.graphics.circle("fill", 0, centerY, size * 0.07)
    elseif foodType == "pumpkin" then
        -- Body
        love.graphics.setColor(0.90, 0.55, 0.15)
        love.graphics.ellipse("fill", 0, 0, size * 0.3, size * 0.25)
        -- Segment lines
        love.graphics.setColor(0.75, 0.40, 0.10)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(-size * 0.1, -size * 0.2, -size * 0.1, size * 0.2)
        love.graphics.line(size * 0.1, -size * 0.2, size * 0.1, size * 0.2)
        love.graphics.setLineWidth(1)
        -- Stem
        love.graphics.setColor(0.30, 0.55, 0.20)
        love.graphics.rectangle("fill", -size * 0.04, -size * 0.32, size * 0.08, size * 0.1)
    end

    love.graphics.pop()
end

return Sprites
