local Player = {}
Player.__index = Player

local actionStart = {axe = 1, hoe = 3, pickaxe = 5, water = 7}

function Player.new(x, y, walkSheet, actionSheet, repairSheet)
    local self = setmetatable({
        x = x, y = y, speed = 260, sheet = walkSheet, actionSheet = actionSheet, repairSheet = repairSheet,
        food = 0, ore = 0, wood = 0, stone = 0, capacity = 18, gather = 1,
        walkClock = 0, actionClock = 0, isMoving = false, facing = 1,
        interactionTarget = nil, activeTool = nil, repairingWall = false
    }, Player)
    local fw, fh = walkSheet:getWidth() / 8, walkSheet:getHeight()
    self.frameWidth, self.frameHeight, self.frames = fw, fh, {}
    self.walkFootAnchors = {628, 618, 616, 618, 630, 622, 626, 624}
    for i = 0, 7 do self.frames[i + 1] = love.graphics.newQuad(i * fw, 0, fw, fh, walkSheet:getDimensions()) end
    local aw, ah = actionSheet:getWidth() / 8, actionSheet:getHeight()
    self.actionFrameWidth, self.actionFrameHeight, self.actionFrames = aw, ah, {}
    self.actionFootAnchors = {632, 676, 632, 666, 650, 678, 628, 646}
    for i = 0, 7 do self.actionFrames[i + 1] = love.graphics.newQuad(i * aw, 0, aw, ah, actionSheet:getDimensions()) end
    local rw, rh = repairSheet:getWidth() / 2, repairSheet:getHeight()
    self.repairFrameWidth, self.repairFrameHeight, self.repairFrames = rw, rh, {}
    self.repairFootAnchors = {862, 892}
    for i = 0, 1 do self.repairFrames[i + 1] = love.graphics.newQuad(i * rw, 0, rw, rh, repairSheet:getDimensions()) end
    return self
end

function Player:totalCargo() return self.food + self.ore + self.wood + self.stone end

function Player:beginInteraction(node, world, game)
    local dx, dy = node.x - self.x, node.y - self.y
    if dx * dx + dy * dy > 180 * 180 then game:setNotice("대상에 더 가까이 가세요", "core"); return end
    local tool, label = world:getInteraction(node, game)
    if not tool then game:setNotice(label or "지금은 작업할 수 없습니다", "core"); return end
    self.interactionTarget, self.activeTool, self.actionClock, self.repairingWall = node, tool, 0, false
    self.actionFrameDuration = .32 / ((game.tools[tool].speed or 1) * self.gather)
    self.nextImpact = self.actionFrameDuration
    self.facing = dx < 0 and -1 or 1
end

function Player:beginWallRepair(world, game)
    if math.abs(self.y - world.wall.y) > 185 then game:setNotice("방어벽에 더 가까이 가세요", "core"); return end
    if world.wall.hp >= world.wall.maxHp then game:setNotice("방어벽이 이미 완전히 수리되었습니다", "core"); return end
    self.interactionTarget, self.activeTool, self.actionClock, self.repairingWall = nil, "hammer", 0, true
    self.facing = 1
end

function Player:cancelInteraction()
    self.interactionTarget, self.activeTool, self.actionClock, self.repairingWall, self.nextImpact = nil, nil, 0, false, nil
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
        dx, dy = dx / len, dy / len
        if dx ~= 0 then self.facing = dx < 0 and -1 or 1 end
        self.x = math.max(75, math.min(world.width - 75, self.x + dx * self.speed * dt))
        self.y = math.max(75, math.min(world.height - 75, self.y + dy * self.speed * dt))
        self.walkClock = self.walkClock + dt * 9
    end
    if self.repairingWall then
        if math.abs(self.y - world.wall.y) > 210 then self:cancelInteraction()
        else
            local cycle = .64 / (game.tools.hammer.speed * self.gather)
            local before = math.floor(self.actionClock / cycle)
            self.actionClock = self.actionClock + dt
            if math.floor(self.actionClock / cycle) > before and not world:repairWall(game) then self:cancelInteraction() end
        end
    elseif self.interactionTarget then
        local node = self.interactionTarget
        local ndx, ndy = node.x - self.x, node.y - self.y
        local valid = (node.kind == "plot" or node.active) and ndx * ndx + ndy * ndy <= 210 * 210
        if not valid then self:cancelInteraction()
        else
            self.actionClock = self.actionClock + dt
            local impacts = 0
            if node.kind ~= "plot" and self.nextImpact then
                while self.actionClock >= self.nextImpact do
                    impacts = impacts + 1
                    self.nextImpact = self.nextImpact + self.actionFrameDuration * 2
                end
            end
            local keepWorking = world:workNode(node, game, self, self.activeTool, dt * self.gather)
            if keepWorking then
                if node.kind == "tree" or node.kind == "quarry" then
                    for _ = 1, impacts do world:harvestHit(node, game, self) end
                else
                    for _ = 1, impacts do world:impactNode(node, game, false) end
                end
            else
                self:cancelInteraction()
            end
        end
    end
    local cx, cy = world.core.x - self.x, world.core.y - self.y
    if not game.rush and cx * cx + cy * cy < 145 * 145 then game:depositCargo() end
end

function Player:draw()
    local pulse = self.isMoving and math.sin(self.walkClock * math.pi) or 0
    love.graphics.setColor(0, 0, 0, .42); love.graphics.ellipse("fill", self.x + 3, self.y + 3, 22 - math.abs(pulse) * 2, 7)
    love.graphics.setColor(1, 1, 1)
    if self.repairingWall then
        local frame = math.floor(self.actionClock / .32) % 2 + 1
        love.graphics.draw(self.repairSheet, self.repairFrames[frame], self.x, self.y, 0, .145 * self.facing, .145, self.repairFrameWidth / 2, self.repairFootAnchors[frame])
    elseif self.interactionTarget and self.activeTool then
        local first = actionStart[self.activeTool] or 1
        local frame = first + (math.floor(self.actionClock / (self.actionFrameDuration or .32)) % 2)
        love.graphics.draw(self.actionSheet, self.actionFrames[frame], self.x, self.y, 0, .16 * self.facing, .16, self.actionFrameWidth / 2, self.actionFootAnchors[frame])
    else
        local frame = self.isMoving and (math.floor(self.walkClock) % 8 + 1) or 2
        love.graphics.draw(self.sheet, self.frames[frame], self.x, self.y - math.abs(pulse) * 2, pulse * .012, .17 * self.facing, .17 * (1 - math.abs(pulse) * .018), self.frameWidth / 2, self.walkFootAnchors[frame])
    end
end

return Player
