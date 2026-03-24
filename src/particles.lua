local util = require("src.util")
local Economy = require("src.economy")

local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({}, Particles)
    self.particles = {}
    self.coinPopups = {}
    return self
end

function Particles:update(dt)
    -- Update sparkle particles
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 80 * dt  -- gravity
        p.life = p.life - dt
        p.alpha = math.max(0, p.life / p.maxLife)
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end

    -- Update coin popups
    for i = #self.coinPopups, 1, -1 do
        local c = self.coinPopups[i]
        c.y = c.y - 40 * dt  -- float up
        c.life = c.life - dt
        c.alpha = math.max(0, c.life / c.maxLife)
        if c.life <= 0 then
            table.remove(self.coinPopups, i)
        end
    end
end

function Particles:draw()
    -- Draw sparkle particles
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size * p.alpha)
    end

    -- Draw coin popups
    local font = love.graphics.getFont()
    for _, c in ipairs(self.coinPopups) do
        love.graphics.setColor(0.15, 0.12, 0.08, c.alpha * 0.5)
        love.graphics.print(c.text, c.x + 1, c.y + 1)
        love.graphics.setColor(0.2, 0.75, 0.15, c.alpha)
        love.graphics.print(c.text, c.x, c.y)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Particles:spawnMergeEffect(x, y)
    local colors = {
        {1, 0.85, 0.15},
        {1, 0.95, 0.40},
        {1, 0.70, 0.10},
        {1, 1, 0.80},
    }
    for i = 1, 20 do
        local angle = math.random() * math.pi * 2
        local speed = util.randomFloat(60, 180)
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 40,
            size = util.randomFloat(2, 5),
            color = colors[math.random(#colors)],
            life = util.randomFloat(0.4, 0.9),
            maxLife = 0.9,
            alpha = 1,
        })
    end
end

function Particles:spawnCoinPopup(x, y, amount)
    table.insert(self.coinPopups, {
        x = x - 15,
        y = y,
        text = "+" .. Economy.formatMoney(amount),
        life = 1.2,
        maxLife = 1.2,
        alpha = 1,
    })
end

return Particles
