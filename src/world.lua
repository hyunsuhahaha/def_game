local World = {}
World.__index = World

local buildingDefs = require("src.buildings")
local buildingById = {}
for _, def in ipairs(buildingDefs) do buildingById[def.id] = def end

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

local function cargoSpace(player) return player.capacity - player:totalCargo() end

function World.new()
    local self = setmetatable({}, World)
    self.width, self.height = 3200, 2000
    self.core = {x = 1600, y = 1325, hp = 500, maxHp = 500, damage = 18, fireRate = 1.25, range = 510, cooldown = 0}
    self.wall = {y = 1115, level = 1, maxLevel = 4, hp = 220, maxHp = 220, brokenNotified = false}
    self.images = {
        industrial = image("assets/floor-industrial.png"), farm = image("assets/floor-biofarm.png"), quarry = image("assets/floor-quarry.png"),
        core = image("assets/supply-core-v2.png"), turret = image("assets/turret-v1.png"), drone = image("assets/combat-drone-v1.png"), crop = image("assets/crop-pod.png"), ore = image("assets/ore-node.png"),
        tree = image("assets/tree-v1.png"), stone = image("assets/stone-v1.png"), lumber = image("assets/lumber-drop-v1.png"),
        workerWalk = image("assets/worker-walk-v3.png"), workerActions = image("assets/worker-actions-v1.png"), workerRepair = image("assets/worker-repair-v1.png")
    }
    self.buildingIcons = {}
    for _, def in ipairs(buildingDefs) do self.buildingIcons[def.id] = image(def.icon or ("assets/upgrades/" .. def.id .. ".png")) end
    self.nodes, self.enemies, self.defenders, self.turrets, self.buildings, self.shots, self.drops = {}, {}, {}, {}, {}, {}, {}
    self.particles, self.popups, self.harvestChain, self.harvestChainTime = {}, {}, 0, 0
    self.effectFont = love.graphics.newFont("assets/font-korean.ttf", 18)
    self.quarryVisual = {shadowX = 5, shadowY = 7, shadowRx = 104, shadowRy = 11, shadowAlpha = .22, frontBias = 130}
    self.treeVisual = {scale = .28, shadowX = 4, shadowY = 9, shadowRx = 92, shadowRy = 12, shadowAlpha = .22, frontBias = 120}
    self.spawnTimer, self.wave, self.kills = 3, 0, 0
    self:build()
    return self
end

local effectColors = {
    tree = {.86, .55, .2}, wood = {.76, .48, .2}, stone = {.78, .84, .88}, ore = {.25, .82, 1}, quarry = {.65, .78, .86}, plot = {.42, 1, .45}
}

local function effectOrigin(node)
    if node.kind == "tree" then return node.x, node.y - 145 end
    if node.kind == "quarry" then return node.x, node.y - 105 end
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

function World:spawnDrop(kind, amount, x, y, spreadX, spreadY)
    spreadX, spreadY = spreadX or 24, spreadY or 0
    for _ = 1, amount do
        local minVx, maxVx = kind == "wood" and 25 or -125, kind == "wood" and 125 or 35
        self.drops[#self.drops + 1] = {
            kind = kind, amount = 1,
            x = x + love.math.random(-spreadX, spreadX), y = y - 34 + love.math.random(-spreadY, spreadY),
            vx = love.math.random(minVx, maxVx), vy = love.math.random(28, 82),
            height = love.math.random(36, 58), vz = love.math.random(85, 135),
            magnet = false
        }
    end
end

function World:updateDrops(dt, game)
    local player = game.player
    for i = #self.drops, 1, -1 do
        local drop = self.drops[i]
        local dx, dy = player.x - drop.x, player.y - drop.y
        local distance = math.sqrt(dx * dx + dy * dy)
        if drop.height <= 0 and distance <= 80 and cargoSpace(player) > 0 then drop.magnet = true end
        if drop.magnet then
            local pull = math.min(1, dt * 12)
            drop.x, drop.y = drop.x + dx * pull, drop.y + dy * pull
            drop.height = drop.height + (10 - drop.height) * pull
            if distance <= 26 then
                local amount = math.min(drop.amount, cargoSpace(player))
                if amount > 0 then
                    if game.upgrades then amount = math.min(game.upgrades:applyGain(drop.kind, amount), cargoSpace(player)) end
                    player[drop.kind] = player[drop.kind] + amount
                    game.runStats.harvested = game.runStats.harvested + amount
                    game.runStats[drop.kind] = (game.runStats[drop.kind] or 0) + amount
                    game:addRunXP(amount)
                    local label = drop.kind == "stone" and "돌" or drop.kind == "wood" and "목재" or "광석"
                    local color = effectColors[drop.kind]
                    self.popups[#self.popups + 1] = {x=drop.x,y=drop.y-32,life=.8,maxLife=.8,text="+"..amount.." "..label,color=color,chain=0}
                    table.remove(self.drops, i)
                else
                    drop.magnet = false
                end
            end
        else
            drop.x, drop.y = drop.x + drop.vx * dt, drop.y + drop.vy * dt
            drop.vx, drop.vy = drop.vx * math.exp(-dt * 4.5), drop.vy * math.exp(-dt * 4.5)
            drop.height, drop.vz = drop.height + drop.vz * dt, drop.vz - 360 * dt
            if drop.height <= 0 then
                drop.height = 0
                if drop.vz < -45 then drop.vz = -drop.vz * .22 else drop.vz = 0 end
            end
        end
    end
end

function World:harvestHit(node, game, player)
    self:impactNode(node, game, false)
    if node.kind == "tree" then
        self:spawnDrop("wood", 1, node.x + 160, node.y + 70, 130, 100)
    elseif node.kind == "quarry" then
        node.oreCounter = (node.oreCounter or 0) + 1
        local isOre = node.oreCounter % 5 == 0
        self:spawnDrop(isOre and "ore" or "stone", 1, node.x - 160, node.y + 70, 130, 100)
    end
end

function World:build()
    for row = 0, 2 do for col = 0, 3 do self.nodes[#self.nodes + 1] = plot(1320 + col * 160, 1580 + row * 175) end end
    self.nodes[#self.nodes + 1] = resource("tree", 1110, 1420, 4.5)
    self.nodes[#self.nodes + 1] = resource("quarry", 2070, 1420, 4.5)
end

function World:update(dt, game)
    self:updateEffects(dt, game)
    self:updateDrops(dt, game)
    self:updateBuildings(dt, game)
    for _, turret in ipairs(self.turrets) do turret.flash = math.max(0, (turret.flash or 0) - dt) end
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
        if target then
            local source = self.turrets[1]
            local sx, sy = source and source.x or self.core.x, source and source.y - 35 or self.core.y - 70
            if source then source.flash = .14 end
            target.hp = target.hp - self.core.damage; self:applyCombatEffects(target, self.core.damage, game); self.shots[#self.shots + 1] = {x1 = sx, y1 = sy, x2 = target.x, y2 = target.y, life = .12}; self.core.cooldown = 1 / self.core.fireRate
        end
    end
    for i = #self.shots, 1, -1 do self.shots[i].life = self.shots[i].life - dt; if self.shots[i].life <= 0 then table.remove(self.shots, i) end end
end

local turretSlots = {{x=-61,y=-66},{x=61,y=-66},{x=-61,y=28},{x=61,y=28}}

function World:canPlaceBuilding(x, y, footprint)
    footprint = footprint or 46
    if x < self.core.x - 680 or x > self.core.x + 680 then return false end
    if y < self.wall.y + 60 or y > self.height - 70 then return false end
    local coreDx, coreDy = x - self.core.x, y - self.core.y
    if coreDx * coreDx + coreDy * coreDy < 190 * 190 then return false end
    for _, building in ipairs(self.buildings) do
        local other = buildingById[building.kind]
        local minDist = footprint / 2 + (other and other.footprint or 46) / 2 + 6
        local dx, dy = x - building.x, y - building.y
        if dx * dx + dy * dy < minDist * minDist then return false end
    end
    for _, node in ipairs(self.nodes) do
        local nodeRadius = node.kind == "quarry" and 220 or node.kind == "tree" and 150 or 60
        local minDist = footprint / 2 + nodeRadius
        local dx, dy = x - node.x, y - node.y
        if dx * dx + dy * dy < minDist * minDist then return false end
    end
    for _, turret in ipairs(self.turrets) do
        local minDist = footprint / 2 + 40
        local dx, dy = x - turret.x, y - turret.y
        if dx * dx + dy * dy < minDist * minDist then return false end
    end
    return true
end

function World:addBuilding(kind, x, y)
    local def = buildingById[kind]
    if not def or not self:canPlaceBuilding(x, y, def.footprint) then return nil end
    local building = {kind = kind, x = x, y = y, timer = def.interval, flash = .4}
    self.buildings[#self.buildings + 1] = building
    return building
end

function World:updateBuildings(dt, game)
    for _, b in ipairs(self.buildings) do
        b.flash = math.max(0, (b.flash or 0) - dt)
        local def = buildingById[b.kind]
        b.timer = (b.timer or def.interval) - dt
        if b.timer <= 0 then
            b.timer = def.interval
            if def.behavior == "produce" then
                local amount = game.upgrades and game.upgrades:applyGain(def.resource, def.amount) or def.amount
                game[def.resource] = game[def.resource] + amount
                game.runStats.harvested = game.runStats.harvested + amount
                game.runStats[def.resource] = (game.runStats[def.resource] or 0) + amount
                game:addRunXP(math.max(1, math.floor(amount / 2)))
                local pulseKind = def.resource == "food" and "plot" or def.resource == "wood" and "tree" or def.resource
                local label = def.resource == "food" and "자동 식량" or def.resource == "wood" and "자동 목재" or "자동 광석"
                self:resourcePulse(game, pulseKind, amount, label)
                b.flash = .3
            elseif def.behavior == "spawn" then
                local affordable = true
                for res, amt in pairs(def.spawnCost) do if (game[res] or 0) < amt then affordable = false end end
                if affordable and #self.defenders < 5 + #self.buildings * 2 then
                    for res, amt in pairs(def.spawnCost) do game[res] = game[res] - amt end
                    self:spawnDefender(def.spawnKind, 1, game)
                    b.flash = .35
                end
            elseif def.behavior == "rail" then
                if (game.ore or 0) >= (def.spawnCost.ore or 0) then
                    game.ore = game.ore - def.spawnCost.ore
                    self:fireRail(b, game, def.damage + (game.upgrades and game.upgrades:level("super_magnet") or 0) * 7)
                end
            elseif def.behavior == "blade" then
                self:bladeBurst(b, game, def.damage)
            elseif def.behavior == "spore" then
                self:sporeBurst(b, game, def.damage)
            elseif def.behavior == "repair" then
                if self.wall.hp < self.wall.maxHp and (game.wood or 0) >= (def.spawnCost.wood or 0) and (game.stone or 0) >= (def.spawnCost.stone or 0) then
                    game.wood, game.stone = game.wood - def.spawnCost.wood, game.stone - def.spawnCost.stone
                    self.wall.hp = math.min(self.wall.maxHp, self.wall.hp + def.repairAmount)
                    self:resourcePulse(game, "plot", def.repairAmount, "자동 수리")
                    b.flash = .45
                end
            elseif def.behavior == "carrier" then
                if game.player:totalCargo() > 0 then game:depositCargo("운반 드론 자동 납품"); b.flash = .25 end
            elseif def.behavior == "turret" then
                local target, best = nil, def.range
                for _, enemy in ipairs(self.enemies) do
                    local dx, dy = enemy.x - b.x, enemy.y - b.y; local d = math.sqrt(dx * dx + dy * dy)
                    if d < best then target, best = enemy, d end
                end
                if target then
                    target.hp = target.hp - def.damage; self:applyCombatEffects(target, def.damage, game)
                    self.shots[#self.shots + 1] = {x1 = b.x, y1 = b.y - 30, x2 = target.x, y2 = target.y, life = .12}
                    b.flash = .2
                end
            end
        end
    end
end

function World:addTurret(kind, level)
    if #self.turrets < #turretSlots then
        local slot = turretSlots[#self.turrets + 1]
        self.turrets[#self.turrets + 1] = {kind=kind or "autocannon", level=level or 1, x=self.core.x+slot.x, y=self.core.y-50+slot.y, flash=.25}
        return self.turrets[#self.turrets]
    end
    local target = self.turrets[1]
    for _, turret in ipairs(self.turrets) do if turret.level < target.level then target = turret end end
    target.level, target.flash = math.min(5, target.level + 1), .3
    if kind == "rail" then target.kind = "rail" end
    return target
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
    kind = kind or "bio"
    local x,y
    if kind == "drone" then x,y=self.core.x+love.math.random(-245,245),self.core.y+85+love.math.random(0,65)
    else x,y=self.core.x+love.math.random(-145,145),self.core.y-120-love.math.random(0,70) end
    self.defenders[#self.defenders + 1] = {kind=kind, level=level or 1, x=x, y=y, cooldown=.2}
    if game and game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .16) end
end

function World:fireRail(source, game, damage)
    local target
    for _, enemy in ipairs(self.enemies) do if not target or enemy.y > target.y then target = enemy end end
    if not target then return false end
    source.flash = .3
    target.hp = target.hp - damage; self:applyCombatEffects(target, damage, game)
    self.shots[#self.shots+1]={x1=source.x,y1=source.y-38,x2=target.x,y2=target.y,life=.24,color={.25,.92,1}}
    self.particles[#self.particles+1]={x=target.x,y=target.y,life=.3,maxLife=.3,size=22,color={.25,.92,1},ring=true}
    if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.24) end
    return true
end

function World:bladeBurst(source, game, damage)
    local hits = 0
    for _, enemy in ipairs(self.enemies) do
        if hits < 5 and enemy.y > self.wall.y - 520 then enemy.hp=enemy.hp-damage; hits=hits+1; self.shots[#self.shots+1]={x1=source.x,y1=source.y-25,x2=enemy.x,y2=enemy.y,life=.18,color={1,.62,.18}} end
    end
    if hits > 0 then source.flash = .3; if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.13) end end
end

function World:sporeBurst(source, game, damage)
    local crops = 0
    for _, node in ipairs(self.nodes) do if node.kind=="plot" and (node.state=="growing" or node.state=="ready") then crops=crops+1 end end
    if crops == 0 then return end
    local hits=0
    for _,enemy in ipairs(self.enemies) do if hits<math.min(6,crops) then enemy.hp=enemy.hp-damage*(1+crops*.04); hits=hits+1; self.shots[#self.shots+1]={x1=source.x,y1=source.y,x2=enemy.x,y2=enemy.y,life=.2,color={.45,1,.35}} end end
    if hits > 0 then source.flash = .3 end
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
            if node.kind == "tree" then rx, ry, centerY = 188, 228, node.y - 150 end
            if node.kind == "plot" then rx, ry = 82, 42 end
            if node.kind == "stone" then rx, ry, centerY = 78, 62, node.y - 28 end
            if node.kind == "ore" then rx, ry, centerY = 68, 58, node.y - 24 end
            if node.kind == "quarry" then rx, ry, centerY = 190, 145, node.y - 92 end
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
    if node.kind == "quarry" then return "pickaxe", "채석장 채굴" end
    if node.state == "empty" then return game.seeds > 0 and "hoe" or nil, game.seeds > 0 and "씨앗 심기" or "씨앗이 없습니다" end
    if node.state == "planted" then return "water", "물 주기" end
    if node.state == "growing" then return nil, string.format("성장 중 %.0f초", node.grow) end
    if node.state == "ready" then return "hoe", "작물 수확" end
end

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
            if game.upgrades then amount = game.upgrades:applyGain("food", amount) end
            amount=math.min(amount,cargoSpace(player)); player.food, game.seeds, node.state = player.food + amount, game.seeds + 1, "empty"
            game.runStats.harvested = game.runStats.harvested + amount; game:addRunXP(amount)
            self:harvestBurst(node, game, amount, "식량")
            game:setNotice("작물 +"..amount.."  씨앗 +1", "food"); return false
        end
        return false
    end
    if cargoSpace(player) <= 0 then game:setNotice("가방이 가득 찼습니다", "core"); return false end
    if node.kind == "quarry" or node.kind == "tree" then return true end
    node.work = node.work + speed * dt
    if node.work < node.workTime then return true end
    local amount = node.kind == "stone" and 5 or 5
    if game.upgrades then amount = game.upgrades:duplicateAmount(amount) end
    if game.upgrades then amount = game.upgrades:applyGain(node.kind, amount) end
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
    queue[#queue + 1] = {y = self.core.y, draw = function() shadow(self.core.x, self.core.y, 145, 48, .5); centered(self.images.core, self.core.x, self.core.y - 50, .23) end}
    queue[#queue + 1] = {y = self.core.y + 1, draw = function()
        for _, turret in ipairs(self.turrets) do
            local pulse = 1 + turret.level * .025 + (turret.flash or 0) * .45
            shadow(turret.x, turret.y + 25, 28, 9, .35)
            love.graphics.setColor(1,1,1,1); grounded(self.images.turret, turret.x, turret.y + 30, .058 * pulse)
            if turret.flash and turret.flash > 0 then love.graphics.setColor(turret.kind=="rail" and {.25,.92,1,turret.flash*4} or {1,.7,.2,turret.flash*4}); love.graphics.circle("fill",turret.x-30,turret.y-22,8+turret.flash*45) end
        end
    end}
    for _, value in ipairs(self.buildings) do local building = value; queue[#queue + 1] = {y = building.y, draw = function()
        local flash, icon = building.flash or 0, self.buildingIcons[building.kind]
        shadow(building.x, building.y + 10, 62, 19, .42)
        if flash > 0 then love.graphics.setColor(.35, 1, .62, flash * 1.8); love.graphics.circle("fill", building.x, building.y - 40, 52 + flash * 48) end
        if icon then
            love.graphics.setColor(1, 1, 1, 1)
            local scale = 78 / math.max(icon:getWidth(), icon:getHeight())
            grounded(icon, building.x, building.y + 12, scale * (1 + flash * .08))
        end
    end} end
    queue[#queue + 1] = {y = self.wall.y, draw = function() self:drawWall(player) end}
    for _, n in ipairs(self.nodes) do
        if n.active or n.kind == "plot" then
            local node = n
            local sortY = node.kind == "quarry" and (node.y - self.quarryVisual.frontBias) or node.kind == "tree" and (node.y - self.treeVisual.frontBias) or node.y
            queue[#queue + 1] = {y = sortY, draw = function()
                local shake = (node.hitShake or 0) * 42
                local ox, oy = (love.math.random() * 2 - 1) * shake, (love.math.random() * 2 - 1) * shake * .35
                local bump = 1 + (node.hitFlash or 0) * .32
                if node.hitFlash and node.hitFlash > 0 then
                    local fx, fy = effectOrigin(node); love.graphics.setColor(1, .9, .42, node.hitFlash * 3.5); love.graphics.circle("fill", fx, fy, 36 + node.hitFlash * 70)
                end
                if node.kind == "plot" then love.graphics.push(); love.graphics.translate(ox, oy); self:drawPlot(node); love.graphics.pop()
                elseif node.kind == "tree" then
                    local visual = self.treeVisual
                    love.graphics.setColor(0, 0, 0, visual.shadowAlpha)
                    love.graphics.ellipse("fill", node.x + visual.shadowX, node.y + visual.shadowY, visual.shadowRx, visual.shadowRy)
                    grounded(self.images.tree, node.x + ox, node.y + oy, visual.scale * bump)
                elseif node.kind == "quarry" then
                    local visual = self.quarryVisual
                    love.graphics.setColor(0, 0, 0, visual.shadowAlpha)
                    love.graphics.ellipse("fill", node.x + visual.shadowX, node.y + visual.shadowY, visual.shadowRx, visual.shadowRy)
                    grounded(self.images.stone, node.x + ox, node.y + oy, .285 * bump)
                    love.graphics.setColor(.25, .82, 1, .82); centered(self.images.ore, node.x + 68 + ox, node.y - 112 + oy, .055 * bump)
                elseif node.kind == "stone" then shadow(node.x, node.y, 54, 16, .4); grounded(self.images.stone, node.x + ox, node.y + oy, .085 * bump)
                else shadow(node.x, node.y, 48, 15, .4); centered(self.images.ore, node.x + ox, node.y - 25 + oy, .075 * bump) end
                if player.interactionTarget == node then
                    love.graphics.setColor(1, .7, .18, .9); love.graphics.setLineWidth(3); love.graphics.ellipse("line", node.x, node.y + 8, node.kind == "quarry" and 175 or (node.kind == "tree" and 128 or 58), node.kind == "quarry" and 52 or (node.kind == "tree" and 36 or 19))
                    if node.kind ~= "plot" and node.kind ~= "tree" and node.kind ~= "quarry" then
                        local barWidth = 70
                        local barY = node.y - 70
                        love.graphics.setColor(.08, .1, .1, .9); love.graphics.rectangle("fill", node.x - barWidth / 2, barY, barWidth, 7)
                        love.graphics.setColor(.95, .62, .16); love.graphics.rectangle("fill", node.x - barWidth / 2, barY, barWidth * node.work / node.workTime, 7)
                    end
                end
            end}
        end
    end
    for _, d in ipairs(self.defenders) do local defender = d; queue[#queue + 1] = {y = defender.y, draw = function()
        if defender.kind == "drone" then
            local bob=math.sin(love.timer.getTime()*4+defender.x*.01)*5; shadow(defender.x,defender.y+8,31,10,.38); love.graphics.setColor(1,1,1); centered(self.images.drone,defender.x,defender.y-34+bob,.052)
        else shadow(defender.x, defender.y, 20, 8, .42); love.graphics.setColor(.25, .9, .38); love.graphics.circle("fill", defender.x, defender.y - 20, 22) end
    end} end
    for _, value in ipairs(self.drops) do local drop = value; queue[#queue + 1] = {y = drop.y, draw = function()
        local img = drop.kind == "stone" and self.images.stone or drop.kind == "wood" and self.images.lumber or self.images.ore
        local width = drop.kind == "stone" and 38 or drop.kind == "wood" and 48 or 31
        local scale = width / img:getWidth()
        love.graphics.setColor(0, 0, 0, drop.magnet and .12 or .24)
        love.graphics.ellipse("fill", drop.x + 2, drop.y + 3, width * .38, width * .11)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, drop.x, drop.y - drop.height, 0, scale, scale, img:getWidth() / 2, img:getHeight() * .91)
    end} end
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
