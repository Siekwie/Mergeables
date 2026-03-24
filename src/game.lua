local util = require("src.util")
local Animal = require("src.animal")
local Field = require("src.field")
local Camera = require("src.camera")
local FoodManager = require("src.food")
local Merge = require("src.merge")
local Upgrades = require("src.upgrades")
local Prestige = require("src.prestige")
local Particles = require("src.particles")
local Save = require("src.save")
local HUD = require("src.ui.hud")
local Shop = require("src.ui.shop")
local UpgradePanel = require("src.ui.upgrade_panel")
local PrestigePanel = require("src.ui.prestige_panel")

local Game = {}
Game.__index = Game

local FIELD_W = 2000
local FIELD_H = 1500
local BASE_MAX_ANIMALS = 8
local AUTOSAVE_INTERVAL = 30

function Game.new()
    local self = setmetatable({}, Game)

    -- Core state
    self.money = 0
    self.totalEarned = 0
    self.animals = {}

    -- Systems
    self.field = Field.new(FIELD_W, FIELD_H)
    self.camera = Camera.new()
    self.foodManager = FoodManager.new(FIELD_W, FIELD_H)
    self.upgrades = Upgrades.new()
    self.prestige = Prestige.new()
    self.particles = Particles.new()

    -- UI
    self.hud = HUD.new()
    self.shop = Shop.new()
    self.upgradePanel = UpgradePanel.new()
    self.prestigePanel = PrestigePanel.new()
    self.activePanel = nil
    self.panelVisible = true  -- toggle for hiding/showing the right panel area

    self.hud.onTabClick = function(tab)
        self:togglePanel(tab)
    end
    self.hud.onResetZoom = function()
        self.camera:resetZoom(FIELD_W, FIELD_H)
    end
    self.hud.onTogglePanel = function()
        self.panelVisible = not self.panelVisible
        if not self.panelVisible and self.activePanel then
            self.activePanel:hide()
            self.activePanel = nil
            self.hud.activeTab = nil
        end
    end

    -- Drag state
    self.draggedAnimal = nil
    self.mergeTarget = nil

    -- Timers
    self.autoSaveTimer = 0
    self.autoMergeTimer = 0

    -- Try to load save
    self:loadGame()

    -- If no animals, give starting cow
    if #self.animals == 0 then
        self:spawnStartingAnimals()
    end

    return self
end

function Game:spawnStartingAnimals()
    local startMoney = self.prestige:getStartingMoney()
    self.money = startMoney

    -- Start with 2 cows
    for i = 1, 2 do
        local x = util.randomFloat(200, FIELD_W - 200)
        local y = util.randomFloat(200, FIELD_H - 200)
        table.insert(self.animals, Animal.new("cow", 1, x, y))
    end

    -- Spawn initial food
    for i = 1, 5 do
        self.foodManager:spawnFood()
    end
end

function Game:togglePanel(panelName)
    -- Show the panel area if hidden
    if not self.panelVisible then
        self.panelVisible = true
    end

    local panels = {
        Shop = self.shop,
        Upgrades = self.upgradePanel,
        Prestige = self.prestigePanel,
    }
    local panel = panels[panelName]
    if not panel then return end

    if self.activePanel == panel then
        panel:hide()
        self.activePanel = nil
        self.hud.activeTab = nil
    else
        -- Close current panel
        if self.activePanel then
            self.activePanel:hide()
        end
        panel:show()
        self.activePanel = panel
        self.hud.activeTab = panelName
    end
end

function Game:update(dt)
    local mx, my = love.mouse.getPosition()

    -- Update camera
    self.camera:update(dt, FIELD_W, FIELD_H)

    -- Update food
    local foodSpawnBonus = self.upgrades:getFoodSpawnBonus() + self.prestige:getFoodSpawnBonus()
    self.foodManager:update(dt, foodSpawnBonus)

    -- Update animals
    for _, animal in ipairs(self.animals) do
        if animal ~= self.draggedAnimal then
            animal:setSpeed(self.upgrades:getSpeedBonus(), self.prestige:getSpeedBonus())
            animal:update(dt, FIELD_W, FIELD_H, self.foodManager:getFoods(), self)
        end
    end

    -- Update particles
    self.particles:update(dt)

    -- Update UI
    self.hud:update(dt, self, mx, my)
    if self.panelVisible and self.activePanel then
        self.activePanel:update(mx, my, self)
    end

    -- Update merge target highlight
    if self.draggedAnimal then
        local wx, wy = self.camera:screenToWorld(mx, my)
        self.draggedAnimal.x = wx
        self.draggedAnimal.y = wy

        -- Clear old highlight
        if self.mergeTarget then
            self.mergeTarget.highlighted = false
        end
        self.mergeTarget = Merge.findTarget(self.draggedAnimal, self.animals)
        if self.mergeTarget then
            self.mergeTarget.highlighted = true
        end
    end

    -- Auto-save
    self.autoSaveTimer = self.autoSaveTimer + dt
    if self.autoSaveTimer >= AUTOSAVE_INTERVAL then
        self:saveGame()
        self.autoSaveTimer = 0
    end
end

function Game:getGameAreaWidth()
    local sw = util.screenW()
    if self.panelVisible then
        return math.floor(sw * 0.70)
    end
    return sw
end

function Game:draw()
    local sw = util.screenW()
    local sh = util.screenH()
    local gameW = self:getGameAreaWidth()

    -- Clip game rendering to the left game area
    love.graphics.setScissor(0, 0, gameW, sh)

    -- Draw world (field + animals + food)
    self.camera:apply()

    self.field:draw()
    self.foodManager:draw()

    -- Sort animals by Y for depth
    local sorted = {}
    for _, a in ipairs(self.animals) do
        table.insert(sorted, a)
    end
    table.sort(sorted, function(a, b) return a.y < b.y end)

    -- Draw decorations and animals interleaved by Y
    local decoIdx = 1
    local decos = self.field.decorations
    for _, animal in ipairs(sorted) do
        -- Draw decorations that are behind this animal
        while decoIdx <= #decos and decos[decoIdx].y <= animal.y do
            self.field:drawDecoration(decos[decoIdx])
            decoIdx = decoIdx + 1
        end
        animal:draw()
    end
    -- Draw remaining decorations
    while decoIdx <= #decos do
        self.field:drawDecoration(decos[decoIdx])
        decoIdx = decoIdx + 1
    end

    -- Particles (world space)
    self.particles:draw()

    self.camera:release()

    love.graphics.setScissor()  -- Remove clipping

    -- Draw panel background area (solid, right side)
    if self.panelVisible then
        love.graphics.setColor(0.10, 0.10, 0.12, 1.0)
        love.graphics.rectangle("fill", gameW, 50, sw - gameW, sh - 50)
        -- Separator line
        love.graphics.setColor(0.45, 0.65, 0.40, 0.6)
        love.graphics.rectangle("fill", gameW, 50, 2, sh - 50)
    end

    -- Draw UI (screen space)
    self.hud:draw(self)

    if self.activePanel and self.panelVisible then
        self.activePanel:draw()
    end

    -- Draw drag hint
    if self.draggedAnimal and not self.mergeTarget then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf("Drop on same animal to merge!", 0, sh - 30, gameW, "center")
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Game:mousepressed(x, y, button)
    -- UI first (highest priority)
    if self.hud:mousepressed(x, y, button) then return end

    if self.panelVisible and self.activePanel then
        if self.activePanel:mousepressed(x, y, button) then return end
    end

    -- Middle mouse: camera drag
    if button == 2 or button == 3 then
        self.camera:startDrag(x, y)
        return
    end

    -- Left click: try to pick up animal
    if button == 1 then
        local wx, wy = self.camera:screenToWorld(x, y)
        -- Check animals in reverse order (topmost first)
        for i = #self.animals, 1, -1 do
            local animal = self.animals[i]
            if animal:containsPoint(wx, wy) then
                self.draggedAnimal = animal
                animal:startDrag()
                return
            end
        end
    end
end

function Game:mousereleased(x, y, button)
    if button == 2 or button == 3 then
        self.camera:stopDrag()
        return
    end

    if button == 1 and self.draggedAnimal then
        -- Try merge
        if self.mergeTarget then
            self.mergeTarget.highlighted = false
            Merge.execute(self.draggedAnimal, self.mergeTarget, self.animals, self.particles)
            self.draggedAnimal = nil
            self.mergeTarget = nil
        else
            self.draggedAnimal:stopDrag()
            -- Clamp to field
            self.draggedAnimal.x = util.clamp(self.draggedAnimal.x, 20, FIELD_W - 20)
            self.draggedAnimal.y = util.clamp(self.draggedAnimal.y, 20, FIELD_H - 20)
            self.draggedAnimal = nil
        end
    end
end

function Game:mousemoved(x, y, dx, dy)
    if self.camera:isDragging() then
        self.camera:drag(x, y)
    end
end

function Game:wheelmoved(x, y)
    local mx, my = love.mouse.getPosition()
    -- Check if over a panel
    if self.panelVisible and self.activePanel and self.activePanel:wheelmoved(mx, my, x, y) then
        return
    end
    -- Check if over HUD
    if my < 50 then return end
    -- Zoom the camera
    self.camera:zoom(y, mx, my)
end

function Game:keypressed(key)
    if key == "f11" then
        local isFs = love.window.getFullscreen()
        love.window.setFullscreen(not isFs, "desktop")
    elseif key == "1" then
        self:togglePanel("Shop")
    elseif key == "2" then
        self:togglePanel("Upgrades")
    elseif key == "3" then
        self:togglePanel("Prestige")
    elseif key == "escape" then
        if self.activePanel then
            self.activePanel:hide()
            self.activePanel = nil
            self.hud.activeTab = nil
        end
    elseif key == "tab" then
        self.panelVisible = not self.panelVisible
        if not self.panelVisible and self.activePanel then
            self.activePanel:hide()
            self.activePanel = nil
            self.hud.activeTab = nil
        end
    elseif key == "home" then
        self.camera:resetZoom(FIELD_W, FIELD_H)
    end
end

-- Economy helpers
function Game:addMoney(amount)
    self.money = self.money + amount
    self.totalEarned = self.totalEarned + amount
end

function Game:spendMoney(amount)
    self.money = self.money - amount
end

function Game:getMaxAnimals()
    return BASE_MAX_ANIMALS + self.upgrades:getExtraCapacity() + self.prestige:getExtraCapacity()
end

function Game:getEarningBonus()
    return self.upgrades:getEarningBonus()
end

function Game:getPrestigeEarningBonus()
    return self.prestige:getEarningMultiplier()
end

function Game:getFoodValueBonus()
    return self.upgrades:getFoodValueBonus()
end

function Game:buyAnimal(animalType)
    local animalsData = require("data.animals")
    local data = animalsData[animalType]
    if not data then return false end

    local ownedCount = 0
    for _, a in ipairs(self.animals) do
        if a.type == animalType then ownedCount = ownedCount + 1 end
    end

    local Economy = require("src.economy")
    local cost = Economy.animalCost(data, ownedCount)
    if self.money < cost then return false end
    if #self.animals >= self:getMaxAnimals() then return false end

    self:spendMoney(cost)
    local x = util.randomFloat(100, FIELD_W - 100)
    local y = util.randomFloat(100, FIELD_H - 100)
    local animal = Animal.new(animalType, 1, x, y)
    animal:setSpeed(self.upgrades:getSpeedBonus(), self.prestige:getSpeedBonus())
    table.insert(self.animals, animal)
    return true
end

function Game:applyUpgrades()
    for _, animal in ipairs(self.animals) do
        animal:setSpeed(self.upgrades:getSpeedBonus(), self.prestige:getSpeedBonus())
    end
end

function Game:doPrestige()
    local Economy = require("src.economy")
    local points = Economy.calcPrestigePoints(self.totalEarned)
    if points <= 0 then return end

    self.prestige:addPoints(points)

    -- Reset run state
    self.money = 0
    self.totalEarned = 0
    self.animals = {}
    self.upgrades:reset()
    self.foodManager = FoodManager.new(FIELD_W, FIELD_H)
    self.draggedAnimal = nil
    self.mergeTarget = nil

    -- Spawn with prestige bonuses
    self:spawnStartingAnimals()
    self:saveGame()
end

-- Save/Load
function Game:saveGame()
    local animalStates = {}
    for _, a in ipairs(self.animals) do
        table.insert(animalStates, {
            type = a.type,
            tier = a.tier,
            x = a.x,
            y = a.y,
        })
    end

    local state = {
        money = self.money,
        totalEarned = self.totalEarned,
        animals = animalStates,
        upgrades = self.upgrades:getState(),
        prestige = self.prestige:getState(),
        timestamp = os.time(),
    }
    Save.save(state)
end

function Game:loadGame()
    local state = Save.load()
    if not state then return end

    self.money = state.money or 0
    self.totalEarned = state.totalEarned or 0

    -- Restore animals
    self.animals = {}
    if state.animals then
        for _, as in ipairs(state.animals) do
            local animal = Animal.new(as.type, as.tier, as.x, as.y)
            table.insert(self.animals, animal)
        end
    end

    -- Restore upgrades
    if state.upgrades then
        self.upgrades:loadState(state.upgrades)
    end

    -- Restore prestige
    if state.prestige then
        self.prestige:loadState(state.prestige)
    end

    -- Calculate offline earnings (capped at 2 hours)
    if state.timestamp then
        local elapsed = os.time() - state.timestamp
        elapsed = math.min(elapsed, 7200)  -- cap at 2 hours
        if elapsed > 10 then
            local earningPerSec = 0
            for _, a in ipairs(self.animals) do
                earningPerSec = earningPerSec + a:getEarning(self:getEarningBonus(), self:getPrestigeEarningBonus()) * 0.3
            end
            local offlineEarnings = earningPerSec * elapsed
            if offlineEarnings > 0 then
                self:addMoney(offlineEarnings)
            end
        end
    end

    -- Apply upgrades to animals
    self:applyUpgrades()

    -- Refill food
    for i = 1, 5 do
        self.foodManager:spawnFood()
    end
end

return Game
