local Player = {}
Player.__index = Player

local actionStart = {axe = 1, hoe = 3, pickaxe = 5, water = 7}

function Player.new(x, y, walkSheet, actionSheet)
    local self = setmetatable({
        x = x, y = y, speed = 260, sheet = walkSheet, actionSheet = actionSheet,
        food = 0, ore = 0, wood = 0, stone = 0, capacity = 18, gather = 1,
        walkClock = 0, actionClock = 0, isMoving = false, facing = 1,
        interactionTarget = nil, activeTool = nil
    }, Player)
    local fw, fh = walkSheet:getWidth() / 8, walkSheet:getHeight()
    self.frameWidth, self.frameHeight, self.frames = fw, fh, {}
    for i = 0, 7 do self.frames[i + 1] = love.graphics.newQuad(i * fw, 0, fw, fh, walkSheet:getDimensions()) end
    local aw, ah = actionSheet:getWidth() / 8, actionSheet:getHeight()
    self.actionFrameWidth, self.actionFrameHeight, self.actionFrames = aw, ah, {}
    for i = 0, 7 do self.actionFrames[i + 1] = love.graphics.newQuad(i * aw, 0, aw, ah, actionSheet:getDimensions()) end
    return self
end

function Player:totalCargo() return self.food + self.ore + self.wood + self.stone end

function Player:beginInteraction(node, world, game)
    local dx, dy = node.x - self.x, node.y - self.y
    if dx * dx + dy * dy > 180 * 180 then game:setNotice("대상에 더 가까이 가세요", "core"); return end
    local tool, label = world:getInteraction(node, game)
    if not tool then game:setNotice(label or "지금은 작업할 수 없습니다", "core"); return end
    self.interactionTarget, self.activeTool, self.actionClock = node, tool, 0
    self.facing = dx < 0 and -1 or 1
    game:setNotice(label .. " — " .. game.tools[tool].name .. " 자동 사용", tool == "pickaxe" and "ore" or tool == "axe" and "food" or "core")
end

function Player:cancelInteraction()
    self.interactionTarget, self.activeTool, self.actionClock = nil, nil, 0
end

function Player:update(dt, world, game)
    local dx, dy = 0, 0
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end
    local len = math.sqrt(dx * dx + dy * dy)
    self.isMoving = len > 0
    if self.isMoving then
        self:cancelInteraction()
        dx, dy = dx / len, dy / len
        if dx ~= 0 then self.facing = dx < 0 and -1 or 1 end
        self.x = math.max(75, math.min(world.width - 75, self.x + dx * self.speed * dt))
        self.y = math.max(75, math.min(world.height - 75, self.y + dy * self.speed * dt))
        self.walkClock = self.walkClock + dt * 9
    elseif self.interactionTarget then
        local node = self.interactionTarget
        local valid = node.kind == "plot" or node.active
        if not valid then self:cancelInteraction()
        else
            self.actionClock = self.actionClock + dt
            local keepWorking = world:workNode(node, game, self, self.activeTool, dt * self.gather)
            if not keepWorking then self:cancelInteraction() end
        end
    end
    local cx, cy = world.core.x - self.x, world.core.y - self.y
    if cx * cx + cy * cy < 145 * 145 and self:totalCargo() > 0 then
        game.food, game.ore, game.wood, game.stone = game.food + self.food, game.ore + self.ore, game.wood + self.wood, game.stone + self.stone
        self.food, self.ore, self.wood, self.stone = 0, 0, 0, 0
        game:setNotice("모든 자원을 거점에 납품했습니다", "core")
    end
end

function Player:draw()
    local pulse = self.isMoving and math.sin(self.walkClock * math.pi) or 0
    love.graphics.setColor(0, 0, 0, .5); love.graphics.ellipse("fill", self.x + 4, self.y + 22, 25 - math.abs(pulse) * 2, 10)
    love.graphics.setColor(1, 1, 1)
    if self.interactionTarget and self.activeTool then
        local first = actionStart[self.activeTool] or 1
        local frame = first + (math.floor(self.actionClock / .32) % 2)
        love.graphics.draw(self.actionSheet, self.actionFrames[frame], self.x, self.y, 0, .16 * self.facing, .16, self.actionFrameWidth / 2, self.actionFrameHeight * .9)
    else
        local frame = self.isMoving and (math.floor(self.walkClock) % 8 + 1) or 2
        love.graphics.draw(self.sheet, self.frames[frame], self.x, self.y - math.abs(pulse) * 2, pulse * .012, .17 * self.facing, .17 * (1 - math.abs(pulse) * .018), self.frameWidth / 2, self.frameHeight * .9)
    end
end

return Player
