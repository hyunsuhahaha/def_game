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
    self.core = {x = 1600, y = 1325, hp = 500, maxHp = 500, damage = 18, fireRate = 1.25, range = 510, cooldown = 0}
    self.wall = {y = 1115, level = 1, maxLevel = 4, hp = 220, maxHp = 220, brokenNotified = false}
    self.images = {
        industrial = image("assets/floor-industrial.png"), farm = image("assets/floor-biofarm.png"), quarry = image("assets/floor-quarry.png"),
        core = image("assets/supply-core.png"), crop = image("assets/crop-pod.png"), ore = image("assets/ore-node.png"),
        tree = image("assets/tree-v1.png"), stone = image("assets/stone-v1.png"),
        workerWalk = image("assets/worker-walk-v3.png"), workerActions = image("assets/worker-actions-v1.png"), workerRepair = image("assets/worker-repair-v1.png"),
        machine = image("assets/defense-machine.png"), tanks = image("assets/tank-bank.png")
    }
    self.nodes, self.props, self.enemies, self.defenders, self.shots = {}, {}, {}, {}, {}
    self.particles, self.popups, self.harvestChain, self.harvestChainTime = {}, {}, 0, 0
    self.effectFont = love.graphics.newFont("assets/font-korean.ttf", 18)
    self.spawnTimer, self.wave, self.kills = 3, 0, 0
    self:build()
    return self
end

local effectColors = {
    tree = {.86, .55, .2}, stone = {.78, .84, .88}, ore = {.25, .82, 1}, plot = {.42, 1, .45}
}

local function effectOrigin(node)
    if node.kind == "tree" then return node.x, node.y - 75 end
    if node.kind == "plot" then return node.x, node.y - 18 end
    return node.x, node.y - 28
end

function World:addParticle(x, y, color, strong, pickup)
    local angle = -math.pi * (.16 + love.math.random() * .68)
    local speed = (strong and 155 or 90) + love.math.random() * (strong and 145 or 75)
    self.particles[#self.particles + 1] = {
        x = x, y = y, vx = math.cos(angle) * speed, vy = math.sin(angle) * speed,
        life = pickup and .72 or (strong and .62 or .38), maxLife = pickup and .72 or (strong and .62 or .38),
        size = pickup and (5 + love.math.random() * 4) or (2 + love.math.random() * (strong and 5 or 3)),
        color = color, pickup = pickup
    }
end

function World:impactNode(node, game, strong)
    if not node or node.kind == "plot" or (not node.active and not strong) then return end
    local x, y = effectOrigin(node)
    local color = effectColors[node.kind]
    node.hitFlash, node.hitShake = strong and .2 or .12, strong and .24 or .14
    for _ = 1, strong and 15 or 6 do self:addParticle(x, y, color, strong, false) end
    self.particles[#self.particles + 1] = {x = x, y = y, life = .2, maxLife = .2, size = 12, color = color, ring = true}
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + (strong and .36 or .12)) end
    if game.feedback then game.feedback:play(node.kind, strong) end
end

function World:harvestBurst(node, game, amount, label)
    local x, y = effectOrigin(node)
    local color = effectColors[node.kind] or effectColors.plot
    self:impactNode(node, game, true)
    if node.kind == "plot" then
        node.hitFlash, node.hitShake = .2, .2
        for _ = 1, 15 do self:addParticle(x, y, color, true, false) end
        if game.feedback then game.feedback:play("harvest", true) end
        if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .2) end
    end
    for _ = 1, math.min(12, amount + 3) do self:addParticle(x, y, color, true, true) end
    self.harvestChain = self.harvestChainTime > 0 and math.min(99, self.harvestChain + 1) or 1
    self.harvestChainTime = 2.4
    self.popups[#self.popups + 1] = {x = x, y = y - 78, life = 1.05, maxLife = 1.05, text = "+" .. amount .. " " .. label, color = color, chain = self.harvestChain}
end

function World:updateEffects(dt, game)
    self.harvestChainTime = math.max(0, self.harvestChainTime - dt)
    for _, node in ipairs(self.nodes) do
        node.hitFlash = math.max(0, (node.hitFlash or 0) - dt)
        node.hitShake = math.max(0, (node.hitShake or 0) - dt)
    end
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.life = p.life - dt
        if p.pickup and game.player then
            local dx, dy = game.player.x - p.x, game.player.y - 25 - p.y
            p.vx, p.vy = p.vx + dx * dt * 12, p.vy + dy * dt * 12
        elseif not p.ring then p.vy = p.vy + 390 * dt end
        if not p.ring then p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt end
        if p.life <= 0 then table.remove(self.particles, i) end
    end
    for i = #self.popups, 1, -1 do
        local popup = self.popups[i]
        popup.life, popup.y = popup.life - dt, popup.y - 28 * dt
        if popup.life <= 0 then table.remove(self.popups, i) end
    end
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
    self:updateEffects(dt, game)
    for _, node in ipairs(self.nodes) do
        if node.kind == "plot" then
            if node.state == "growing" then node.grow = math.max(0, node.grow - dt * (game.upgrades and game.upgrades:cropGrowthMultiplier() or 1)); if node.grow <= 0 then node.state = "ready" end end
        elseif not node.active then
            node.respawn = node.respawn - dt
            if node.respawn <= 0 then node.active, node.work = true, 0 end
        end
    end
    self.spawnTimer = self.spawnTimer - dt
    if self.spawnTimer <= 0 and not game.ended then
        self.wave = self.wave + 1
        game:addRunXP(3 + math.floor(self.wave / 5))
        local count = math.min(15, 2 + math.floor(self.wave * .55))
        for i = 1, count do
            local lane = ({780, 1600, 2420})[((i - 1) % 3) + 1]
            self.enemies[#self.enemies + 1] = {x = lane + love.math.random(-55, 55), y = 90 - i * 35, hp = 22 + self.wave * 4, speed = 48 + self.wave * 1.4, hit = 5 + self.wave * .65}
        end
        self.spawnTimer = math.max(5.5, 11 - self.wave * .12)
    end
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        if self.wall.hp > 0 then
            local targetX, targetY = self.core.x, self.wall.y - 34
            local dx, dy = targetX - e.x, targetY - e.y; local d = math.sqrt(dx * dx + dy * dy)
            if d > 28 then e.x, e.y = e.x + dx / d * e.speed * dt, e.y + dy / d * e.speed * dt
            else
                self.wall.hp = math.max(0, self.wall.hp - e.hit * dt * (1 - (self.wall.damageReduction or 0)))
                if self.wall.hp <= 0 and not self.wall.brokenNotified then self.wall.brokenNotified = true; game:setNotice("방어벽이 무너졌습니다", "ore"); game.ended, game.victory = true, false end
            end
        else
            game.ended, game.victory = true, false
        end
        if e.hp <= 0 then table.remove(self.enemies, i); self.kills = self.kills + 1; game:addRunXP(1) end
    end
    for _, defender in ipairs(self.defenders) do
        defender.cooldown = (defender.cooldown or 0) - dt
        if defender.cooldown <= 0 then
            local target, best = nil, defender.kind == "drone" and 520 or 390
            for _, enemy in ipairs(self.enemies) do local dx, dy = enemy.x - defender.x, enemy.y - defender.y; local d = math.sqrt(dx*dx+dy*dy); if d < best then target, best = enemy, d end end
            if target then
                local damage = (defender.kind == "drone" and 10 or 7) + (defender.level or 1) * 3
                target.hp = target.hp - damage; self:applyCombatEffects(target, damage, game)
                self.shots[#self.shots + 1] = {x1=defender.x,y1=defender.y-20,x2=target.x,y2=target.y,life=.14,color=defender.kind=="drone" and {.3,.85,1} or {.45,1,.38}}
                defender.cooldown = (defender.kind == "drone" and .85 or 1.15) / (1 + (game.upgrades and game.upgrades:level("protein_feed") or 0) * .08)
            end
        end
    end
    self.core.cooldown = self.core.cooldown - dt
    if self.core.cooldown <= 0 then
        local target, best = nil, self.core.range or 510
        for _, e in ipairs(self.enemies) do local dx, dy = e.x - self.core.x, e.y - self.core.y; local d = math.sqrt(dx * dx + dy * dy); if d < best then target, best = e, d end end
        if target then target.hp = target.hp - self.core.damage; self:applyCombatEffects(target, self.core.damage, game); self.shots[#self.shots + 1] = {x1 = self.core.x, y1 = self.core.y - 70, x2 = target.x, y2 = target.y, life = .12}; self.core.cooldown = 1 / self.core.fireRate end
    end
    for i = #self.shots, 1, -1 do self.shots[i].life = self.shots[i].life - dt; if self.shots[i].life <= 0 then table.remove(self.shots, i) end end
end

function World:applyCombatEffects(target, damage, game)
    if not game.upgrades then return end
    local explosion = game.upgrades:level("explosive_payload")
    if explosion > 0 then
        local radius = 55 + explosion * 12
        for _, enemy in ipairs(self.enemies) do
            if enemy ~= target then local dx,dy=enemy.x-target.x,enemy.y-target.y; if dx*dx+dy*dy <= radius*radius then enemy.hp = enemy.hp - damage * (.18 + explosion * .04) end end
        end
        self.particles[#self.particles+1] = {x=target.x,y=target.y-20,life=.22,maxLife=.22,size=18,color={1,.38,.14},ring=true}
    end
    local chain = game.upgrades:level("chain_coil")
    if chain > 0 then
        local chained = 0
        for _, enemy in ipairs(self.enemies) do
            if enemy ~= target and chained < math.min(3, chain) then
                local dx,dy=enemy.x-target.x,enemy.y-target.y
                if dx*dx+dy*dy <= (145+chain*15)^2 then
                    enemy.hp=enemy.hp-damage*(.2+chain*.03); chained=chained+1
                    self.shots[#self.shots+1]={x1=target.x,y1=target.y,x2=enemy.x,y2=enemy.y,life=.1,color={.48,.78,1}}
                end
            end
        end
    end
end

function World:spawnDefender(kind, level, game)
    self.defenders[#self.defenders + 1] = {kind=kind or "bio", level=level or 1, x=self.core.x+love.math.random(-145,145), y=self.core.y-120-love.math.random(0,70), cooldown=.2}
    if game and game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .16) end
end

function World:fireRail(game, damage)
    local target
    for _, enemy in ipairs(self.enemies) do if not target or enemy.y > target.y then target = enemy end end
    if not target then return false end
    target.hp = target.hp - damage; self:applyCombatEffects(target, damage, game)
    self.shots[#self.shots+1]={x1=self.core.x,y1=self.core.y-90,x2=target.x,y2=target.y,life=.24,color={.25,.92,1}}
    self.particles[#self.particles+1]={x=target.x,y=target.y,life=.3,maxLife=.3,size=22,color={.25,.92,1},ring=true}
    if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.24) end
    return true
end

function World:bladeBurst(game, damage)
    local hits = 0
    for _, enemy in ipairs(self.enemies) do
        if hits < 5 and enemy.y > self.wall.y - 520 then enemy.hp=enemy.hp-damage; hits=hits+1; self.shots[#self.shots+1]={x1=self.core.x-180,y1=self.wall.y-25,x2=enemy.x,y2=enemy.y,life=.18,color={1,.62,.18}} end
    end
    if hits > 0 and game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.13) end
end

function World:sporeBurst(game, damage)
    local crops = 0
    for _, node in ipairs(self.nodes) do if node.kind=="plot" and (node.state=="growing" or node.state=="ready") then crops=crops+1 end end
    if crops == 0 then return end
    local hits=0
    for _,enemy in ipairs(self.enemies) do if hits<math.min(6,crops) then enemy.hp=enemy.hp+0-damage*(1+crops*.04); hits=hits+1; self.shots[#self.shots+1]={x1=650,y1=1350,x2=enemy.x,y2=enemy.y,life=.2,color={.45,1,.35}} end end
end

function World:resourcePulse(game, kind, amount, label)
    local color=effectColors[kind] or effectColors.plot
    local x,y=self.core.x,self.core.y-105
    for _=1,math.min(10,amount+2) do self:addParticle(x,y,color,true,true) end
    self.popups[#self.popups+1]={x=x,y=y-55,life=1,maxLife=1,text="+"..amount.." "..label,color=color,chain=0}
    if game.feedback then game.feedback:play(kind=="plot" and "harvest" or kind, false) end
end

function World:upgradeWall()
    if self.wall.level >= self.wall.maxLevel then return false end
    local maxHpByLevel = {220, 400, 650, 950}
    self.wall.level = self.wall.level + 1
    self.wall.maxHp = math.floor(maxHpByLevel[self.wall.level] * (self.wall.hpMultiplier or 1) + .5)
    self.wall.hp = self.wall.maxHp
    self.wall.brokenNotified = false
    return true
end

function World:isWallAt(x, y)
    return x >= 55 and x <= self.width - 55 and math.abs(y - self.wall.y) <= 58
end

function World:repairWall(game)
    local wall = self.wall
    if wall.hp >= wall.maxHp then game:setNotice("방어벽이 이미 완전히 수리되었습니다", "core"); return false end
    if game.wood < 1 or game.stone < 1 then game:setNotice("수리 재료가 부족합니다 — 목재 1 · 돌 1", "core"); return false end
    game.wood, game.stone = game.wood - 1, game.stone - 1
    local amount = 28 + wall.level * 10 + (game.repairBonus or 0)
    wall.hp = math.min(wall.maxHp, wall.hp + amount)
    wall.brokenNotified = false
    game:setNotice(string.format("방어벽 수리 +%d", amount), "core")
    return wall.hp < wall.maxHp
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
            local amount = game.upgrades and game.upgrades:duplicateAmount(6) or 6
            amount=math.min(amount,cargoSpace(player)); player.food, game.seeds, node.state = player.food + amount, game.seeds + 1, "empty"
            game.runStats.harvested = game.runStats.harvested + amount; game:addRunXP(amount)
            self:harvestBurst(node, game, amount, "식량")
            game:setNotice("작물 +"..amount.."  씨앗 +1", "food"); return false
        end
        return false
    end
    if cargoSpace(player) <= 0 then game:setNotice("가방이 가득 찼습니다", "core"); return false end
    node.work = node.work + speed * dt
    if node.work < node.workTime then return true end
    local amount = node.kind == "tree" and 6 or node.kind == "stone" and 5 or 5
    if game.upgrades then amount = game.upgrades:duplicateAmount(amount) end
    amount = math.min(amount, cargoSpace(player))
    player[node.kind == "tree" and "wood" or node.kind] = player[node.kind == "tree" and "wood" or node.kind] + amount
    game.runStats.harvested = game.runStats.harvested + amount; game.runStats[node.kind] = (game.runStats[node.kind] or 0) + amount; game:addRunXP(amount)
    node.active, node.work, node.respawn = false, 0, node.kind == "tree" and 18 or node.kind == "stone" and 15 or 22
    local label = node.kind == "tree" and "목재" or node.kind == "stone" and "돌" or "광석"
    self:harvestBurst(node, game, amount, label)
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

function World:drawWall(player)
    local wall, y, level = self.wall, self.wall.y, self.wall.level
    local integrity = wall.maxHp > 0 and wall.hp / wall.maxHp or 0
    local alpha = wall.hp > 0 and 1 or .34
    love.graphics.setColor(0, 0, 0, .48 * alpha); love.graphics.rectangle("fill", 55, y + 18, self.width - 110, 23)
    for x = 55, self.width - 55, 160 do
        local segmentW = math.min(156, self.width - 55 - x)
        if level == 1 then
            love.graphics.setColor(.19, .22, .22, alpha); love.graphics.rectangle("fill", x, y - 11, segmentW, 26, 3, 3)
            love.graphics.setColor(.55, .34, .13, alpha); love.graphics.rectangle("fill", x + 4, y - 7, segmentW - 8, 5); love.graphics.rectangle("fill", x + 4, y + 7, segmentW - 8, 5)
            love.graphics.setColor(.36, .4, .39, alpha); love.graphics.rectangle("fill", x, y - 22, 10, 45, 2, 2); love.graphics.rectangle("fill", x + segmentW - 10, y - 22, 10, 45, 2, 2)
        elseif level == 2 then
            love.graphics.setColor(.16, .2, .22, alpha); love.graphics.rectangle("fill", x, y - 25, segmentW, 51, 4, 4)
            love.graphics.setColor(.31, .37, .39, alpha); love.graphics.polygon("fill", x + 5, y - 20, x + segmentW - 14, y - 20, x + segmentW - 5, y, x + segmentW - 14, y + 20, x + 5, y + 20)
            love.graphics.setColor(.9, .52, .12, alpha); love.graphics.rectangle("fill", x + 10, y - 3, segmentW - 20, 6)
            love.graphics.setColor(.65, .7, .7, alpha); for r = 16, segmentW - 16, 42 do love.graphics.circle("fill", x + r, y - 15, 2); love.graphics.circle("fill", x + r, y + 15, 2) end
        else
            love.graphics.setColor(.09, .14, .17, alpha); love.graphics.rectangle("fill", x, y - 34, segmentW, 68, 5, 5)
            love.graphics.setColor(.27, .34, .38, alpha); love.graphics.polygon("fill", x + 7, y - 28, x + segmentW - 20, y - 28, x + segmentW - 7, y - 12, x + segmentW - 7, y + 28, x + 20, y + 28, x + 7, y + 12)
            love.graphics.setColor(.08, .1, .12, alpha); love.graphics.rectangle("fill", x + 17, y - 20, segmentW - 34, 40, 3, 3)
            love.graphics.setColor(level == 4 and {.15, .82, 1, alpha} or {1, .56, .12, alpha}); love.graphics.rectangle("fill", x + 20, y - 4, segmentW - 40, 8, 3, 3)
            love.graphics.circle("fill", x + 14, y, 5); love.graphics.circle("fill", x + segmentW - 14, y, 5)
        end
    end
    if level == 4 and wall.hp > 0 then
        local pulse = .25 + math.sin(love.timer.getTime() * 4) * .08
        love.graphics.setColor(.12, .78, 1, pulse); love.graphics.rectangle("fill", 55, y - 45, self.width - 110, 83, 8, 8)
        love.graphics.setColor(.38, .92, 1, .8); love.graphics.setLineWidth(3); love.graphics.line(55, y - 43, self.width - 55, y - 43)
    end
    love.graphics.setColor(0, 0, 0, .75); love.graphics.rectangle("fill", self.core.x - 90, y - 61, 180, 12, 4, 4)
    love.graphics.setColor(level == 4 and {.18, .86, 1, 1} or {.94, .58, .14, 1}); love.graphics.rectangle("fill", self.core.x - 90, y - 61, 180 * integrity, 12, 4, 4)
    if player.repairingWall then
        local pulse = 30 + math.sin(love.timer.getTime() * 8) * 5
        love.graphics.setColor(1, .78, .2, .95); love.graphics.setLineWidth(3); love.graphics.circle("line", player.x, y, pulse)
    end
end

function World:draw(player)
    drawTiled(self.images.industrial, 0, 0, self.width, 1160, 320)
    drawTiled(self.images.farm, 0, 1160, 1260, 840, 320)
    drawTiled(self.images.industrial, 1260, 1160, 680, 840, 320)
    drawTiled(self.images.quarry, 1940, 1160, 1260, 840, 320)
    love.graphics.setColor(.06, .075, .085, 1); love.graphics.rectangle("fill", 0, 0, self.width, 55); love.graphics.rectangle("fill", 0, self.height - 55, self.width, 55); love.graphics.rectangle("fill", 0, 0, 55, self.height); love.graphics.rectangle("fill", self.width - 55, 0, 55, self.height)
    local queue = {}
    for _, p in ipairs(self.props) do local prop = p; queue[#queue + 1] = {y = prop.y, draw = function() local img = self.images[prop.kind]; shadow(prop.x, prop.y, img:getWidth() * prop.scale * .38, img:getHeight() * prop.scale * .12, .5); grounded(img, prop.x, prop.y, prop.scale) end} end
    queue[#queue + 1] = {y = self.core.y, draw = function() shadow(self.core.x, self.core.y, 145, 48, .62); centered(self.images.core, self.core.x, self.core.y - 50, .23) end}
    queue[#queue + 1] = {y = self.wall.y, draw = function() self:drawWall(player) end}
    for _, n in ipairs(self.nodes) do
        if n.active or n.kind == "plot" then
            local node = n
            queue[#queue + 1] = {y = node.y, draw = function()
                local shake = (node.hitShake or 0) * 42
                local ox, oy = (love.math.random() * 2 - 1) * shake, (love.math.random() * 2 - 1) * shake * .35
                local bump = 1 + (node.hitFlash or 0) * .32
                if node.hitFlash and node.hitFlash > 0 then
                    local fx, fy = effectOrigin(node); love.graphics.setColor(1, .9, .42, node.hitFlash * 3.5); love.graphics.circle("fill", fx, fy, 36 + node.hitFlash * 70)
                end
                if node.kind == "plot" then love.graphics.push(); love.graphics.translate(ox, oy); self:drawPlot(node); love.graphics.pop()
                elseif node.kind == "tree" then shadow(node.x, node.y, 62, 20, .42); grounded(self.images.tree, node.x + ox, node.y + oy, .145 * bump)
                elseif node.kind == "stone" then shadow(node.x, node.y, 54, 16, .4); grounded(self.images.stone, node.x + ox, node.y + oy, .085 * bump)
                else shadow(node.x, node.y, 48, 15, .4); centered(self.images.ore, node.x + ox, node.y - 25 + oy, .075 * bump) end
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
    for _, p in ipairs(self.particles) do
        local alpha = math.max(0, p.life / p.maxLife)
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        if p.ring then
            love.graphics.setLineWidth(3); love.graphics.circle("line", p.x, p.y, p.size + (1 - alpha) * 42)
        elseif p.pickup then
            love.graphics.push(); love.graphics.translate(p.x, p.y); love.graphics.rotate((1 - alpha) * 7); love.graphics.rectangle("fill", -p.size, -p.size, p.size * 2, p.size * 2, 2, 2); love.graphics.pop()
        else love.graphics.circle("fill", p.x, p.y, p.size) end
    end
    love.graphics.setFont(self.effectFont)
    for _, popup in ipairs(self.popups) do
        local alpha = math.min(1, popup.life * 2.5)
        love.graphics.setColor(0, 0, 0, alpha * .7); love.graphics.printf(popup.text, popup.x - 99, popup.y + 2, 200, "center")
        love.graphics.setColor(popup.color[1], popup.color[2], popup.color[3], alpha); love.graphics.printf(popup.text, popup.x - 100, popup.y, 200, "center")
        if popup.chain >= 2 then love.graphics.setColor(1, .78, .2, alpha); love.graphics.printf("연속 채집 x" .. popup.chain, popup.x - 100, popup.y + 22, 200, "center") end
    end
    love.graphics.setLineWidth(4); for _, s in ipairs(self.shots) do local c=s.color or {.2,.85,1}; love.graphics.setColor(c[1],c[2],c[3],math.min(1,s.life/.12)); love.graphics.line(s.x1,s.y1,s.x2,s.y2) end
end

return World
