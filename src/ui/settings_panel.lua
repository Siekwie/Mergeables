local Panel = require("src.ui.panel")
local Button = require("src.ui.button")
local Save = require("src.save")
local util = require("src.util")

local SettingsPanel = {}
SettingsPanel.__index = SettingsPanel
setmetatable(SettingsPanel, { __index = Panel })

function SettingsPanel.new()
    local self = Panel.new({ title = "SETTINGS" })
    setmetatable(self, SettingsPanel)
    self.buttons = {}
    self.statusMessage = nil
    self.statusTimer = 0
    return self
end

function SettingsPanel:buildButtons(game)
    self.buttons = {}
    local cx, cy, cw, ch = self:getContentArea()
    local y = 0

    -- Fullscreen toggle
    local isFs = love.window.getFullscreen()
    local fsBtn = Button.new({
        x = cx, y = cy + y - self.scrollY,
        w = cw, h = 38,
        text = isFs and "Windowed Mode" or "Fullscreen",
        color = {0.28, 0.32, 0.40},
        onClick = function()
            local fs = love.window.getFullscreen()
            love.window.setFullscreen(not fs, "desktop")
        end,
    })
    table.insert(self.buttons, fsBtn)
    y = y + 46

    -- Separator
    y = y + 10

    -- Export Save
    local exportBtn = Button.new({
        x = cx, y = cy + y - self.scrollY,
        w = cw, h = 44,
        text = "Export Save",
        subText = "Copy save data to clipboard",
        color = {0.30, 0.40, 0.55},
        onClick = function()
            game:saveGame()
            local content = love.filesystem.read("mergeables_save.lua")
            if content then
                love.system.setClipboardText(content)
                self.statusMessage = "Save copied to clipboard!"
                self.statusTimer = 3
            else
                self.statusMessage = "Error: could not read save file"
                self.statusTimer = 3
            end
        end,
    })
    table.insert(self.buttons, exportBtn)
    y = y + 52

    -- Import Save
    local importBtn = Button.new({
        x = cx, y = cy + y - self.scrollY,
        w = cw, h = 44,
        text = "Import Save",
        subText = "Load save data from clipboard",
        color = {0.40, 0.40, 0.55},
        onClick = function()
            local clipboard = love.system.getClipboardText()
            if not clipboard or clipboard == "" then
                self.statusMessage = "Clipboard is empty!"
                self.statusTimer = 3
                return
            end
            -- Validate it's a valid save
            local state, err = util.deserialize(clipboard)
            if not state then
                self.statusMessage = "Invalid save data!"
                self.statusTimer = 3
                return
            end
            -- Write to save file and reload
            love.filesystem.write("mergeables_save.lua", clipboard)
            game:reloadGame()
            self.statusMessage = "Save imported!"
            self.statusTimer = 3
        end,
    })
    table.insert(self.buttons, importBtn)
    y = y + 52

    -- Separator
    y = y + 20

    -- Reset Save
    local resetBtn = Button.new({
        x = cx, y = cy + y - self.scrollY,
        w = cw, h = 44,
        text = "Reset Save",
        subText = "Delete all progress (cannot undo!)",
        color = {0.60, 0.20, 0.20},
        onClick = function()
            if self.confirmReset then
                Save.delete()
                game:reloadGame()
                self.statusMessage = "Save reset!"
                self.statusTimer = 3
                self.confirmReset = false
            else
                self.confirmReset = true
                self.statusMessage = "Click again to confirm reset!"
                self.statusTimer = 5
            end
        end,
    })
    table.insert(self.buttons, resetBtn)
    y = y + 52

    self:setContentHeight(y)
end

function SettingsPanel:update(mx, my, game)
    if not self.visible then return end
    self:buildButtons(game)
    for _, btn in ipairs(self.buttons) do
        btn:update(mx, my)
    end
    -- Update status timer
    if self.statusTimer > 0 then
        self.statusTimer = self.statusTimer - love.timer.getDelta()
        if self.statusTimer <= 0 then
            self.statusMessage = nil
            self.confirmReset = false
        end
    end
end

function SettingsPanel:draw()
    if not self.visible then return end
    self:drawBackground()

    local cx, cy, cw, ch = self:getContentArea()
    love.graphics.setScissor(cx - 4, cy - 4, cw + 8, ch + 8)

    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end

    -- Status message
    if self.statusMessage then
        local msgY = cy + ch - 30
        love.graphics.setColor(0.10, 0.10, 0.12, 0.9)
        love.graphics.rectangle("fill", cx, msgY - 4, cw, 24, 4, 4)
        love.graphics.setColor(1, 0.90, 0.50)
        love.graphics.printf(self.statusMessage, cx, msgY, cw, "center")
    end

    love.graphics.setScissor()
end

function SettingsPanel:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then return false end
    for _, btn in ipairs(self.buttons) do
        if btn:click() then return true end
    end
    return self:containsPoint(x, y)
end

function SettingsPanel:wheelmoved(x, y, wx, wy)
    if not self.visible then return false end
    if self:containsPoint(x, y) then
        self:scroll(wy)
        return true
    end
    return false
end

return SettingsPanel
