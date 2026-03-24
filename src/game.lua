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
local Economy = require("src.economy")
local HUD = require("src.ui.hud")
local Shop = require("src.ui.shop")
local UpgradePanel = require("src.ui.upgrade_panel")
local PrestigePanel = require("src.ui.prestige_panel")

local Game = {}
Game.__index = Game

local BASE_FIELD_W = 1000
local BASE_FIELD_H = 750
local BASE_MAX_ANIMALS = 8
local AUTOSAVE_INTERVAL = 30

function Game.new()
    local self = setmetatable({}, Game)

    -- Core state
    self.money = 0
    self.totalEarned = 0
    self.animals = {}

    -- Animal levels (per type, not per individual)
    local animalsData = require("data.animals")
    self.animalLevels = {}
    for id, _ in pairs(animalsData) do
        self.animalLevels[id] = { level = 0, xp = 0 }
    end

    -- Systems
    self.upgrades = Upgrades.new()
    self.prestige = Prestige.new()
    self.particles = Particles.new()
    self.camera = Camera.new()

    local fw, fh = self:getFieldSize()
    self.field = Field.new(fw, fh)
    self.foodManager = FoodManager.new(fw, fh)

    -- UI
    self.hud = HUD.new()
    self.shop = Shop.new()
    self.upgradePanel = UpgradePanel.new()
    self.prestigePanel = PrestigePanel.new()
    self.activePanel = nil
    self.panelVisible = true

    self.hud.onTabClick = function(tab)
        self:togglePanel(tab)
    end
    self.hud.onResetZoom = function()
        local rfw, rfh = self:getFieldSize()
        self.camera:resetZoom(rfw, rfh)
    end
    self.lastPanelName = "Inventory"
    self.hud.onTogglePanel = function()
        if self.panelVisible then
            -- Hide: remember which panel was open
            if self.activePanel then
                self.activePanel:hide()
                self.activePanel = nil
                self.hud.activeTab = nil
            end
            self.panelVisible = false
        else
            -- Show: restore last panel or default to Inventory
            self.panelVisible = true
            self:togglePanel(self.lastPanelName or "Inventory")
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

    -- Apply field size after loading upgrades
    self:applyFieldSize()

    -- Open Inventory by default
    self:togglePanel("Inventory")

    return self
end

function Game:getFieldSize()
    local bonus = self.upgrades and self.upgrades:getPlotSizeBonus() or 0
    local w = math.floor(BASE_FIELD_W * (1 + bonus))
    local h = math.floor(BASE_FIELD_H * (1 + bonus))
    return w, h
end

function Game:applyFieldSize()
    local fw, fh = self:getFieldSize()
    self.field:resize(fw, fh)
    self.foodManager:setFieldBounds(fw, fh)
end

function Game:spawnStartingAnimals()
    local startMoney = self.prestige:getStartingMoney()
    self.money = startMoney

    local fw, fh = self:getFieldSize()
    for i = 1, 2 do
        local x = util.randomFloat(200, fw - 200)
        local y = util.randomFloat(200, fh - 200)
        table.insert(self.animals, Animal.new("cow", 1, x, y))
    end

    for i = 1, 5 do
        self.foodManager:spawnFood()
    end
end

function Game:togglePanel(panelName)
    if not self.panelVisible then
        self.panelVisible = true
    end

    local panels = {
        Inventory = self.shop,
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
        if self.activePanel then
            self.activePanel:hide()
        end
        panel:show()
        self.activePanel = panel
        self.hud.activeTab = panelName
        self.lastPanelName = panelName
    end
end

function Game:update(dt)
    local mx, my = love.mouse.getPosition()
    local fw, fh = self:getFieldSize()

    -- Update camera
    self.camera:update(dt, fw, fh)

    -- Update food
    local foodSpawnBonus = self.upgrades:getFoodSpawnBonus() + self.prestige:getFoodSpawnBonus()
    self.foodManager:update(dt, foodSpawnBonus)

    -- Update animals
    for _, animal in ipairs(self.animals) do
        if animal ~= self.draggedAnimal then
            local lvl = self:getAnimalLevel(animal.type)
            animal:setSpeed(self.upgrades:getSpeedBonus(), self.prestige:getSpeedBonus(), lvl)
            animal:update(dt, fw, fh, self.foodManager:getFoods(), self)
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
        while decoIdx <= #decos and decos[decoIdx].y <= animal.y do
            self.field:drawDecoration(decos[decoIdx])
            decoIdx = decoIdx + 1
        end
        animal:draw()
    end
    while decoIdx <= #decos do
        self.field:drawDecoration(decos[decoIdx])
        decoIdx = decoIdx + 1
    end

    -- Particles (world space)
    self.particles:draw()

    self.camera:release()

    love.graphics.setScissor()

    -- Draw panel background area (solid, right side)
    if self.panelVisible then
        love.graphics.setColor(0.10, 0.10, 0.12, 1.0)
        love.graphics.rectangle("fill", gameW, 50, sw - gameW, sh - 50)
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
    if self.hud:mousepressed(x, y, button) then return end

    if self.panelVisible and self.activePanel then
        if self.activePanel:mousepressed(x, y, button) then return end
    end

    if button == 2 or button == 3 then
        self.camera:startDrag(x, y)
        return
    end

    if button == 1 then
        local wx, wy = self.camera:screenToWorld(x, y)
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
        if self.mergeTarget then
            self.mergeTarget.highlighted = false
            Merge.execute(self.draggedAnimal, self.mergeTarget, self.animals, self.particles)
            self.draggedAnimal = nil
            self.mergeTarget = nil
        else
            self.draggedAnimal:stopDrag()
            local fw, fh = self:getFieldSize()
            self.draggedAnimal.x = util.clamp(self.draggedAnimal.x, 20, fw - 20)
            self.draggedAnimal.y = util.clamp(self.draggedAnimal.y, 20, fh - 20)
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
    if self.panelVisible and self.activePanel and self.activePanel:wheelmoved(mx, my, x, y) then
        return
    end
    if my < 50 then return end
    self.camera:zoom(y, mx, my)
end

function Game:keypressed(key)
    if key == "f11" then
        local isFs = love.window.getFullscreen()
        love.window.setFullscreen(not isFs, "desktop")
    elseif key == "1" then
        self:togglePanel("Inventory")
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
        if self.panelVisible then
            if self.activePanel then
                self.activePanel:hide()
                self.activePanel = nil
                self.hud.activeTab = nil
            end
            self.panelVisible = false
        else
            self.panelVisible = true
            self:togglePanel(self.lastPanelName or "Inventory")
        end
    elseif key == "home" then
        local fw, fh = self:getFieldSize()
        self.camera:resetZoom(fw, fh)
    end
end

-- Animal level helpers
function Game:getAnimalLevel(animalType)
    local entry = self.animalLevels[animalType]
    return entry and entry.level or 0
end

function Game:addAnimalXP(animalType, amount)
    local entry = self.animalLevels[animalType]
    if not entry then return end
    local animalsData = require("data.animals")
    local data = animalsData[animalType]
    if entry.level >= (data.maxAnimalLevel or 10) then return end
    entry.xp = entry.xp + amount
end

function Game:canLevelUpAnimal(animalType)
    local entry = self.animalLevels[animalType]
    if not entry then return false end
    local animalsData = require("data.animals")
    local data = animalsData[animalType]
    if entry.level >= (data.maxAnimalLevel or 10) then return false end
    local xpNeeded = Economy.animalXPNeeded(data, entry.level)
    local cost = Economy.animalLevelUpCost(data, entry.level)
    return entry.xp >= xpNeeded and self.money >= cost
end

function Game:levelUpAnimal(animalType)
    if not self:canLevelUpAnimal(animalType) then return false end
    local entry = self.animalLevels[animalType]
    local animalsData = require("data.animals")
    local data = animalsData[animalType]
    local cost = Economy.animalLevelUpCost(data, entry.level)
    self:spendMoney(cost)
    entry.level = entry.level + 1
    entry.xp = 0
    -- Update speed for all animals of this type
    for _, animal in ipairs(self.animals) do
        if animal.type == animalType then
            animal:setSpeed(self.upgrades:getSpeedBonus(), self.prestige:getSpeedBonus(), entry.level)
        end
    end
    return true
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

    local cost = Economy.animalCost(data, ownedCount)
    if self.money < cost then return false end
    if #self.animals >= self:getMaxAnimals() then return false end

    self:spendMoney(cost)
    local fw, fh = self:getFieldSize()
    local x = util.randomFloat(100, fw - 100)
    local y = util.randomFloat(100, fh - 100)
    local animal = Animal.new(animalType, 1, x, y)
    local lvl = self:getAnimalLevel(animalType)
    animal:setSpeed(self.upgrades:getSpeedBonus(), self.prestige:getSpeedBonus(), lvl)
    table.insert(self.animals, animal)
    return true
end

function Game:applyUpgrades()
    for _, animal in ipairs(self.animals) do
        local lvl = self:getAnimalLevel(animal.type)
        animal:setSpeed(self.upgrades:getSpeedBonus(), self.prestige:getSpeedBonus(), lvl)
    end
    self:applyFieldSize()
end

function Game:doPrestige()
    local points = Economy.calcPrestigePoints(self.totalEarned)
    if points <= 0 then return end

    self.prestige:addPoints(points)

    -- Reset run state
    self.money = 0
    self.totalEarned = 0
    self.animals = {}
    self.upgrades:reset()
    self.draggedAnimal = nil
    self.mergeTarget = nil

    -- Reset animal levels
    for k, v in pairs(self.animalLevels) do
        v.level = 0
        v.xp = 0
    end

    -- Reset field to base size
    local fw, fh = self:getFieldSize()
    self.field:resize(fw, fh)
    self.foodManager = FoodManager.new(fw, fh)

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
        animalLevels = self.animalLevels,
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

    -- Restore animal levels
    if state.animalLevels then
        for animalType, data in pairs(state.animalLevels) do
            if self.animalLevels[animalType] then
                self.animalLevels[animalType].level = data.level or 0
                self.animalLevels[animalType].xp = data.xp or 0
            end
        end
    end

    -- Calculate offline earnings
    if state.timestamp then
        local now = os.time()
        local elapsedFromSave = now - state.timestamp

        -- Cross-check with file modification time to catch save editing
        local fileModTime = Save.getFileModTime()
        local elapsedFromFile = fileModTime and (now - fileModTime) or elapsedFromSave

        -- Use the more conservative (smaller) elapsed, reject negative (clock went back)
        local elapsed = math.min(elapsedFromSave, elapsedFromFile)
        if elapsed < 0 then elapsed = 0 end

        -- Apply upgradeable cap
        local capHours = self.upgrades:getOfflineCapHours()
        local capSeconds = capHours * 3600
        elapsed = math.min(elapsed, capSeconds)

        if elapsed > 10 then
            local offlineRate = self.upgrades:getOfflineRate()
            local earningPerSec = 0
            for _, a in ipairs(self.animals) do
                local lvl = self:getAnimalLevel(a.type)
                earningPerSec = earningPerSec + a:getEarning(self:getEarningBonus(), self:getPrestigeEarningBonus(), lvl) * offlineRate
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
