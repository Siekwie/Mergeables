local util = require("src.util")
local Button = require("src.ui.button")
local Sprites = require("src.sprites")
local skillTreeData = require("data.skill_tree_data")

local SkillTreePanel = {}
SkillTreePanel.__index = SkillTreePanel

local NODE_RADIUS = 28
local NODE_SPACING = 100
local CENTER_RADIUS = 36

function SkillTreePanel.new()
    local self = setmetatable({}, SkillTreePanel)
    self.visible = false
    self.hoveredNode = nil
    self.hoveredBranch = nil
    self.closeBtn = nil
    self.scrollX = 0
    self.scrollY = 0
    self.dragging = false
    self.dragStartX = 0
    self.dragStartY = 0
    self.dragScrollStartX = 0
    self.dragScrollStartY = 0
    return self
end

function SkillTreePanel:show()
    self.visible = true
    self.hoveredNode = nil
    self.hoveredBranch = nil
    self.scrollX = 0
    self.scrollY = 0
end

function SkillTreePanel:hide()
    self.visible = false
    self.dragging = false
end

-- Get the center of the tree in screen coordinates
local function getTreeCenter()
    local sw = util.screenW()
    local sh = util.screenH()
    return sw / 2, sh / 2
end

-- Get screen position of a node given branch angle and node index
local function getNodePos(branchAngle, nodeIndex)
    local cx, cy = getTreeCenter()
    local rad = math.rad(branchAngle - 90)  -- -90 so angle=0 is up
    local dist = 80 + nodeIndex * NODE_SPACING
    return cx + math.cos(rad) * dist, cy + math.sin(rad) * dist
end

function SkillTreePanel:update(mx, my, game)
    if not self.visible then return end

    self.hoveredNode = nil
    self.hoveredBranch = nil

    -- Check node hover (offset by scroll)
    local omx = mx - self.scrollX
    local omy = my - self.scrollY

    for bi, branch in ipairs(skillTreeData) do
        for ni, node in ipairs(branch.nodes) do
            local nx, ny = getNodePos(branch.angle, ni)
            local d = util.distance(omx, omy, nx, ny)
            if d < NODE_RADIUS + 4 then
                self.hoveredNode = node
                self.hoveredBranch = branch
                return
            end
        end
    end
end

function SkillTreePanel:draw(game)
    if not self.visible then return end

    local sw = util.screenW()
    local sh = util.screenH()
    local skillTree = game.skillTree

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.push()
    love.graphics.translate(self.scrollX, self.scrollY)

    local cx, cy = getTreeCenter()

    -- Draw branch lines and nodes
    for _, branch in ipairs(skillTreeData) do
        local prevX, prevY = cx, cy

        for ni, node in ipairs(branch.nodes) do
            local nx, ny = getNodePos(branch.angle, ni)
            local unlocked = skillTree:isUnlocked(node.id)
            local canUnlock = skillTree:canUnlock(node.id)

            -- Draw connecting line
            if unlocked then
                love.graphics.setColor(branch.color[1], branch.color[2], branch.color[3], 0.8)
                love.graphics.setLineWidth(3)
            elseif canUnlock then
                love.graphics.setColor(branch.color[1], branch.color[2], branch.color[3], 0.4)
                love.graphics.setLineWidth(2)
            else
                love.graphics.setColor(0.3, 0.3, 0.35, 0.4)
                love.graphics.setLineWidth(1)
            end
            love.graphics.line(prevX, prevY, nx, ny)
            love.graphics.setLineWidth(1)

            prevX, prevY = nx, ny
        end
    end

    -- Draw nodes (second pass so nodes are on top of lines)
    for _, branch in ipairs(skillTreeData) do
        for ni, node in ipairs(branch.nodes) do
            local nx, ny = getNodePos(branch.angle, ni)
            local unlocked = skillTree:isUnlocked(node.id)
            local canUnlock = skillTree:canUnlock(node.id)
            local isHovered = self.hoveredNode == node

            -- Node circle
            if unlocked then
                -- Filled, bright
                love.graphics.setColor(branch.color[1], branch.color[2], branch.color[3], 0.9)
                love.graphics.circle("fill", nx, ny, NODE_RADIUS)
                -- Border
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.circle("line", nx, ny, NODE_RADIUS)
            elseif canUnlock then
                -- Pulsing outline
                local pulse = 0.5 + math.sin(love.timer.getTime() * 3) * 0.2
                love.graphics.setColor(branch.color[1], branch.color[2], branch.color[3], 0.25)
                love.graphics.circle("fill", nx, ny, NODE_RADIUS)
                love.graphics.setColor(branch.color[1], branch.color[2], branch.color[3], pulse)
                love.graphics.circle("line", nx, ny, NODE_RADIUS)
                love.graphics.circle("line", nx, ny, NODE_RADIUS + 2)
            else
                -- Dark, locked
                love.graphics.setColor(0.18, 0.18, 0.20, 0.8)
                love.graphics.circle("fill", nx, ny, NODE_RADIUS)
                love.graphics.setColor(0.3, 0.3, 0.35, 0.5)
                love.graphics.circle("line", nx, ny, NODE_RADIUS)
            end

            -- Hover highlight
            if isHovered then
                love.graphics.setColor(1, 1, 1, 0.15)
                love.graphics.circle("fill", nx, ny, NODE_RADIUS + 3)
            end

            -- Node cost or checkmark
            if unlocked then
                love.graphics.setColor(0.1, 0.1, 0.12, 0.9)
                local font = love.graphics.getFont()
                local checkStr = "ok"
                love.graphics.print(checkStr, nx - font:getWidth(checkStr) / 2, ny - font:getHeight() / 2)
            else
                love.graphics.setColor(0.9, 0.9, 0.85, 0.8)
                local font = love.graphics.getFont()
                local costStr = tostring(node.cost)
                love.graphics.print(costStr, nx - font:getWidth(costStr) / 2, ny - font:getHeight() / 2)
            end

            -- Node name (small, below node)
            love.graphics.setColor(0.75, 0.75, 0.70, unlocked and 1 or 0.5)
            local font = love.graphics.getFont()
            love.graphics.printf(node.name, nx - 60, ny + NODE_RADIUS + 4, 120, "center")
        end
    end

    -- Draw center node
    love.graphics.setColor(0.30, 0.80, 0.40, 0.9)
    love.graphics.circle("fill", cx, cy, CENTER_RADIUS)
    love.graphics.setColor(0.45, 0.95, 0.55, 0.6)
    love.graphics.circle("line", cx, cy, CENTER_RADIUS)
    love.graphics.circle("line", cx, cy, CENTER_RADIUS + 2)
    -- Center label
    love.graphics.setColor(0.05, 0.12, 0.05, 0.9)
    local font = love.graphics.getFont()
    local centerText = "Skills"
    love.graphics.print(centerText, cx - font:getWidth(centerText) / 2, cy - font:getHeight() / 2)

    -- Draw animal icons at end of each branch
    for _, branch in ipairs(skillTreeData) do
        local lastNode = #branch.nodes
        local nx, ny = getNodePos(branch.angle, lastNode)
        -- Animal name label past the last node
        local rad = math.rad(branch.angle - 90)
        local lx = nx + math.cos(rad) * 45
        local ly = ny + math.sin(rad) * 45
        love.graphics.setColor(branch.color[1], branch.color[2], branch.color[3], 0.7)
        love.graphics.printf(branch.animal:sub(1,1):upper() .. branch.animal:sub(2), lx - 40, ly - 6, 80, "center")
    end

    love.graphics.pop()

    -- Draw skill points display (top center, above tree)
    love.graphics.setColor(0.09, 0.09, 0.11, 0.9)
    love.graphics.rectangle("fill", sw / 2 - 120, 8, 240, 34, 6, 6)
    love.graphics.setColor(0.30, 0.80, 0.40)
    local ptText = string.format("Skill Points: %.2f", skillTree.points)
    love.graphics.printf(ptText, sw / 2 - 115, 16, 230, "center")

    -- Draw tooltip for hovered node
    if self.hoveredNode then
        self:drawTooltip(game)
    end

    -- Close hint
    love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
    love.graphics.printf("Press ESC or click here to close", sw - 220, sh - 28, 210, "right")
end

function SkillTreePanel:drawTooltip(game)
    local mx, my = love.mouse.getPosition()
    local node = self.hoveredNode
    local branch = self.hoveredBranch
    local skillTree = game.skillTree

    local tw = 220
    local th = 80
    local tx = mx + 16
    local ty = my - 10

    -- Keep on screen
    local sw = util.screenW()
    local sh = util.screenH()
    if tx + tw > sw then tx = mx - tw - 16 end
    if ty + th > sh then ty = sh - th - 4 end
    if ty < 0 then ty = 4 end

    -- Background
    love.graphics.setColor(0.08, 0.08, 0.10, 0.95)
    love.graphics.rectangle("fill", tx, ty, tw, th, 4, 4)
    love.graphics.setColor(branch.color[1], branch.color[2], branch.color[3], 0.5)
    love.graphics.rectangle("line", tx, ty, tw, th, 4, 4)

    -- Name
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(node.name, tx + 8, ty + 6)

    -- Description
    love.graphics.setColor(0.8, 0.8, 0.75, 0.9)
    love.graphics.printf(node.description, tx + 8, ty + 24, tw - 16, "left")

    -- Cost / status
    local unlocked = skillTree:isUnlocked(node.id)
    if unlocked then
        love.graphics.setColor(0.4, 0.9, 0.4, 0.9)
        love.graphics.print("Unlocked", tx + 8, ty + th - 20)
    else
        local canAfford = skillTree.points >= node.cost
        if canAfford then
            love.graphics.setColor(0.4, 0.9, 0.4, 0.9)
        else
            love.graphics.setColor(0.9, 0.4, 0.4, 0.9)
        end
        love.graphics.printf("Cost: " .. node.cost .. " SP", tx + 8, ty + th - 20, tw - 16, "left")
    end
end

function SkillTreePanel:mousepressed(x, y, button, game)
    if not self.visible then return false end
    if button ~= 1 then return false end

    -- Check close area (bottom-right text)
    local sw = util.screenW()
    local sh = util.screenH()
    if x > sw - 220 and y > sh - 34 then
        self:hide()
        return true
    end

    -- Check if clicking on a node (offset by scroll)
    local ox = x - self.scrollX
    local oy = y - self.scrollY
    local skillTree = game.skillTree

    for _, branch in ipairs(skillTreeData) do
        for ni, node in ipairs(branch.nodes) do
            local nx, ny = getNodePos(branch.angle, ni)
            local d = util.distance(ox, oy, nx, ny)
            if d < NODE_RADIUS + 4 then
                if skillTree:canUnlock(node.id) then
                    skillTree:unlock(node.id)
                    game:applyUpgrades()
                end
                return true
            end
        end
    end

    -- Start pan drag
    self.dragging = true
    self.dragStartX = x
    self.dragStartY = y
    self.dragScrollStartX = self.scrollX
    self.dragScrollStartY = self.scrollY
    return true
end

function SkillTreePanel:mousereleased(x, y, button)
    if not self.visible then return false end
    if button == 1 then
        self.dragging = false
    end
    return self.visible
end

function SkillTreePanel:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    if self.dragging then
        self.scrollX = self.dragScrollStartX + (x - self.dragStartX)
        self.scrollY = self.dragScrollStartY + (y - self.dragStartY)
    end
    return self.visible
end

function SkillTreePanel:wheelmoved(mx, my, wx, wy)
    if not self.visible then return false end
    -- Could add zoom later, for now just consume the event
    return true
end

function SkillTreePanel:containsPoint(px, py)
    return self.visible
end

return SkillTreePanel
