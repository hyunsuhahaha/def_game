local World = {}
World.__index = World

local function image(path)
    local value = love.graphics.newImage(path)
    value:setFilter("linear", "linear", 4)
    return value
end

local function resource(kind, x, y, workTime)
    return {kind = kind, x = x, y = y, work = 0, workTime = workTime, active = true, respawn = 0}
end

local function plot(x, y)
    return {kind = "plot", x = x, y = y, state = "empty", grow = 0, growMax = 12, active = true}
end

function World.new()
    local self = setmetatable({}, World)
    self.width, self.height = 3200, 2000
    self.core = {x = 1600, y = 940, hp = 500, maxHp = 500, damage = 18, fireRate = 1.25, cooldown = 0}
    self.images = {
        industrial = image("assets/floor-industrial.png"), farm = image("assets/floor-biofarm.png"), quarry = image("assets/floor-quarry.png"),
        core = image("assets/supply-core.png"), crop = image("assets/crop-pod.png"), ore = image("assets/ore-node.png"),
        tree = image("assets/tree-v1.png"), stone = image("assets/stone-v1.png"),
        workerWalk = image("assets/worker-walk-v3.png"), workerActions = image("assets/worker-actions-v1.png"),
        machine = image("assets/defense-machine.png"), tanks = image("assets/tank-bank.png")
    }
    self.nodes, self.props, self.enemies, self.defenders, self.shots = {}, {}, {}, {}, {}
    self.spawnTimer, self.wave, self.kills = 3, 0, 0
    self:build()
    return self
end

function World:build()
    for row = 0, 2 do for col = 0, 3 do self.nodes[#self.nodes + 1] = plot(470 + col * 175, 1290 + row * 185) end end
    local trees = {{145, 1270}, {215, 1530}, {160, 1840}, {1110, 1260}, {1125, 1570}, {1050, 1860}, {430, 1900}, {760, 1910}}
    for _, p in ipairs(trees) do self.nodes[#self.nodes + 1] = resource("tree", p[1], p[2], 3.5) end
    local stones = {{2070, 1300}, {2310, 1290}, {2140, 1540}, {2390, 1740}, {2110, 1880}}
    for _, p in ipairs(stones) do self.nodes[#self.nodes + 1] = resource("stone", p[1], p[2], 3) end
    local ores = {{2650, 1270}, {2920, 1320}, {2720, 1540}, {3020, 1640}, {2630, 1840}, {2900, 1880}}
    for _, p in ipairs(ores) do self.nodes[#self.nodes + 1] = resource("ore", p[1], p[2], 5.5) end
    local placements = {
        {"machine", 410, 310, .18}, {"machine", 960, 320, .18}, {"machine", 2240, 320, .18}, {"machine", 2790, 310, .18},
        {"tanks", 560, 680, .17}, {"tanks", 2640, 680, .17}, {"machine", 860, 690, .16}, {"machine", 2340, 690, .16},
        {"tanks", 430, 1070, .15}, {"tanks", 2770, 1070, .15}, {"machine", 1320, 1370, .13}, {"machine", 1880, 1370, .13},
        {"tanks", 1320, 1740, .12}, {"tanks", 1880, 1740, .12}
    }
    for _, p in ipairs(placements) do self.props[#self.props + 1] = {kind = p[1], x = p[2], y = p[3], scale = p[4]} end
end

function World:update(dt, game)
    for _, node in ipairs(self.nodes) do
        if node.kind == "plot" then
            if node.state == "growing" then node.grow = math.max(0, node.grow - dt); if node.grow <= 0 then node.state = "ready" end end
        elseif not node.active then
            node.respawn = node.respawn - dt
            if node.respawn <= 0 then node.active, node.work = true, 0 end
        end
    end
    self.spawnTimer = self.spawnTimer - dt
    if self.spawnTimer <= 0 and not game.ended then
        self.wave = self.wave + 1
        local count = math.min(15, 2 + math.floor(self.wave * .55))
        for i = 1, count do
            local lane = ({780, 1600, 2420})[((i - 1) % 3) + 1]
            self.enemies[#self.enemies + 1] = {x = lane + love.math.random(-55, 55), y = 90 - i * 35, hp = 22 + self.wave * 4, speed = 48 + self.wave * 1.4, hit = 5 + self.wave * .65}
        end
        self.spawnTimer = math.max(5.5, 11 - self.wave * .12)
    end
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        local dx, dy = self.core.x - e.x, self.core.y - e.y; local d = math.sqrt(dx * dx + dy * dy)
        if d > 115 then e.x, e.y = e.x + dx / d * e.speed * dt, e.y + dy / d * e.speed * dt
        else self.core.hp = self.core.hp - e.hit * dt; if self.core.hp <= 0 then game.ended, game.victory = true, false end end
        if e.hp <= 0 then table.remove(self.enemies, i); self.kills = self.kills + 1 end
    end
    self.core.cooldown = self.core.cooldown - dt
    if self.core.cooldown <= 0 then
        local target, best = nil, 510
        for _, e in ipairs(self.enemies) do local dx, dy = e.x - self.core.x, e.y - self.core.y; local d = math.sqrt(dx * dx + dy * dy); if d < best then target, best = e, d end end
        if target then target.hp = target.hp - self.core.damage; self.shots[#self.shots + 1] = {x1 = self.core.x, y1 = self.core.y - 70, x2 = target.x, y2 = target.y, life = .12}; self.core.cooldown = 1 / self.core.fireRate end
    end
    for i = #self.shots, 1, -1 do self.shots[i].life = self.shots[i].life - dt; if self.shots[i].life <= 0 then table.remove(self.shots, i) end end
end

function World:findNodeAt(x, y)
    local best, bestScore
    for _, node in ipairs(self.nodes) do
        if node.active or node.kind == "plot" then
            local rx, ry, centerY = 72, 52, node.y
            if node.kind == "tree" then rx, ry, centerY = 105, 125, node.y - 82 end
            if node.kind == "plot" then rx, ry = 82, 42 end
            if node.kind == "stone" then rx, ry, centerY = 78, 62, node.y - 28 end
            if node.kind == "ore" then rx, ry, centerY = 68, 58, node.y - 24 end
            local dx, dy = (x - node.x) / rx, (y - centerY) / ry
            local score = dx * dx + dy * dy
            if score <= 1 and (not bestScore or score < bestScore) then best, bestScore = node, score end
        end
    end
    return best
end

function World:getInteraction(node, game)
    if not node or (node.kind ~= "plot" and not node.active) then return end
    if node.kind == "tree" then return "axe", "나무 베기" end
    if node.kind == "stone" then return "pickaxe", "돌 캐기" end
    if node.kind == "ore" then return "pickaxe", "광석 캐기" end
    if node.state == "empty" then return game.seeds > 0 and "hoe" or nil, game.seeds > 0 and "씨앗 심기" or "씨앗이 없습니다" end
    if node.state == "planted" then return "water", "물 주기" end
    if node.state == "growing" then return nil, string.format("성장 중 %.0f초", node.grow) end
    if node.state == "ready" then return "hoe", "작물 수확" end
end

local function cargoSpace(player) return player.capacity - player:totalCargo() end

function World:workNode(node, game, player, tool, dt)
    local speed = game.tools[tool] and game.tools[tool].speed or 1
    if node.kind == "plot" then
        node.work = (node.work or 0) + speed * dt
        if node.work < .75 then return true end
        node.work = 0
        if node.state == "empty" and game.seeds > 0 then game.seeds = game.seeds - 1; node.state = "planted"; game:setNotice("씨앗을 심었습니다", "food"); return false end
        if node.state == "planted" then node.state, node.grow = "growing", node.growMax; game:setNotice("물을 주었습니다 — 성장을 시작합니다", "core"); return false end
        if node.state == "ready" then
            if cargoSpace(player) < 6 then game:setNotice("가방이 가득 찼습니다", "core"); return false end
            player.food, game.seeds, node.state = player.food + 6, game.seeds + 1, "empty"
            game:setNotice("작물 +6  씨앗 +1", "food"); return false
        end
        return false
    end
    if cargoSpace(player) <= 0 then game:setNotice("가방이 가득 찼습니다", "core"); return false end
    node.work = node.work + speed * dt
    if node.work < node.workTime then return true end
    local amount = node.kind == "tree" and 6 or node.kind == "stone" and 5 or 5
    amount = math.min(amount, cargoSpace(player))
    player[node.kind == "tree" and "wood" or node.kind] = player[node.kind == "tree" and "wood" or node.kind] + amount
    node.active, node.work, node.respawn = false, 0, node.kind == "tree" and 18 or node.kind == "stone" and 15 or 22
    local label = node.kind == "tree" and "목재" or node.kind == "stone" and "돌" or "광석"
    game:setNotice(label .. " +" .. amount, node.kind == "ore" and "ore" or "core")
    return false
end

local function drawTiled(img, x, y, w, h, tile)
    love.graphics.setColor(1, 1, 1, 1)
    local sx, sy = tile / img:getWidth(), tile / img:getHeight()
    for py = y, y + h, tile do for px = x, x + w, tile do love.graphics.draw(img, px, py, 0, sx, sy) end end
end

local function shadow(x, y, rx, ry, alpha) love.graphics.setColor(0, 0, 0, alpha or .38); love.graphics.ellipse("fill", x + 8, y + 14, rx, ry) end
local function centered(img, x, y, scale) love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(img, x, y, 0, scale, scale, img:getWidth() / 2, img:getHeight() / 2) end
local function grounded(img, x, y, scale) love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(img, x, y, 0, scale, scale, img:getWidth() / 2, img:getHeight() * .91) end

function World:drawPlot(node)
    local wet = node.state == "growing" or node.state == "planted"
    love.graphics.setColor(wet and {.105, .065, .04, .96} or {.17, .095, .045, .94})
    love.graphics.polygon("fill", node.x - 70, node.y - 28, node.x + 42, node.y - 28, node.x + 70, node.y + 25, node.x - 42, node.y + 25)
    love.graphics.setLineWidth(1.5); love.graphics.setColor(.38, .2, .075, .9)
    for row = -2, 2 do love.graphics.line(node.x - 50 + row * 9, node.y - 19, node.x + 45 + row * 9, node.y + 17) end
    love.graphics.setColor(.62, .38, .12, .7); love.graphics.polygon("line", node.x - 70, node.y - 28, node.x + 42, node.y - 28, node.x + 70, node.y + 25, node.x - 42, node.y + 25)
    if node.state == "planted" then love.graphics.setColor(.72, .55, .18); for i = -1, 1 do love.graphics.circle("fill", node.x + i * 24, node.y, 3) end end
    if node.state == "growing" or node.state == "ready" then
        local progress = node.state == "ready" and 1 or 1 - node.grow / node.growMax
        centered(self.images.crop, node.x, node.y - 25, .035 + progress * .035)
        if node.state == "growing" then
            love.graphics.setColor(.02, .04, .03, .9); love.graphics.rectangle("fill", node.x - 35, node.y - 58, 70, 7, 3, 3)
            love.graphics.setColor(.35, .92, .4); love.graphics.rectangle("fill", node.x - 35, node.y - 58, 70 * progress, 7, 3, 3)
        end
    end
end

function World:draw(player)
    drawTiled(self.images.industrial, 0, 0, self.width, 1160, 320)
    drawTiled(self.images.farm, 0, 1160, 1260, 840, 320)
    drawTiled(self.images.industrial, 1260, 1160, 680, 840, 320)
    drawTiled(self.images.quarry, 1940, 1160, 1260, 840, 320)
    love.graphics.setColor(.06, .075, .085, 1); love.graphics.rectangle("fill", 0, 0, self.width, 55); love.graphics.rectangle("fill", 0, self.height - 55, self.width, 55); love.graphics.rectangle("fill", 0, 0, 55, self.height); love.graphics.rectangle("fill", self.width - 55, 0, 55, self.height)
    love.graphics.setColor(.9, .55, .12, .65); love.graphics.rectangle("fill", 55, 1115, self.width - 110, 5)
    local queue = {}
    for _, p in ipairs(self.props) do local prop = p; queue[#queue + 1] = {y = prop.y, draw = function() local img = self.images[prop.kind]; shadow(prop.x, prop.y, img:getWidth() * prop.scale * .38, img:getHeight() * prop.scale * .12, .5); grounded(img, prop.x, prop.y, prop.scale) end} end
    queue[#queue + 1] = {y = self.core.y, draw = function() shadow(self.core.x, self.core.y, 145, 48, .62); centered(self.images.core, self.core.x, self.core.y - 50, .23) end}
    for _, n in ipairs(self.nodes) do
        if n.active or n.kind == "plot" then
            local node = n
            queue[#queue + 1] = {y = node.y, draw = function()
                if node.kind == "plot" then self:drawPlot(node)
                elseif node.kind == "tree" then shadow(node.x, node.y, 62, 20, .5); grounded(self.images.tree, node.x, node.y, .145)
                elseif node.kind == "stone" then shadow(node.x, node.y, 54, 16, .48); grounded(self.images.stone, node.x, node.y, .085)
                else shadow(node.x, node.y, 48, 15, .48); centered(self.images.ore, node.x, node.y - 25, .075) end
                if player.interactionTarget == node then
                    love.graphics.setColor(1, .7, .18, .9); love.graphics.setLineWidth(3); love.graphics.ellipse("line", node.x, node.y + 8, node.kind == "tree" and 75 or 58, node.kind == "tree" and 25 or 19)
                    if node.kind ~= "plot" then love.graphics.setColor(.08, .1, .1, .9); love.graphics.rectangle("fill", node.x - 35, node.y - 70, 70, 7); love.graphics.setColor(.95, .62, .16); love.graphics.rectangle("fill", node.x - 35, node.y - 70, 70 * node.work / node.workTime, 7) end
                end
            end}
        end
    end
    for _, d in ipairs(self.defenders) do local defender = d; queue[#queue + 1] = {y = defender.y, draw = function() shadow(defender.x, defender.y, 20, 8, .5); love.graphics.setColor(.25, .9, .38); love.graphics.circle("fill", defender.x, defender.y - 20, 22) end} end
    for _, e in ipairs(self.enemies) do local enemy = e; queue[#queue + 1] = {y = enemy.y, draw = function() shadow(enemy.x, enemy.y, 20, 9, .5); love.graphics.setColor(.65, .12, .15); love.graphics.circle("fill", enemy.x, enemy.y - 22, 24); love.graphics.setColor(1, .35, .25); love.graphics.circle("line", enemy.x, enemy.y - 22, 24) end} end
    queue[#queue + 1] = {y = player.y, draw = function() player:draw() end}
    table.sort(queue, function(a, b) return a.y < b.y end); for _, item in ipairs(queue) do item.draw() end
    love.graphics.setLineWidth(4); for _, s in ipairs(self.shots) do love.graphics.setColor(.2, .85, 1, s.life / .12); love.graphics.line(s.x1, s.y1, s.x2, s.y2) end
end

return World
