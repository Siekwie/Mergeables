local Game = require("src.game")

local game

function love.load()
    love.graphics.setBackgroundColor(0.15, 0.15, 0.18)

    -- Set default font
    local font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    -- Seed random
    math.randomseed(os.time())

    -- Create game
    game = Game.new()
end

function love.update(dt)
    -- Cap dt to prevent spiral of death
    dt = math.min(dt, 1 / 30)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.mousepressed(x, y, button)
    game:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    game:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    game:mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    game:wheelmoved(x, y)
end

function love.keypressed(key)
    game:keypressed(key)
end

function love.resize(w, h)
    -- UI components will adapt via screenW/screenH functions
end

function love.quit()
    game:saveGame()
end
