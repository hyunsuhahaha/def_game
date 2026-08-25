local UI = require("src.ui")

local ClearcutMode = {}
ClearcutMode.__index = ClearcutMode

local trackLabels = {destroy = "파괴력", spread = "확산력", suppress = "억제력"}

-- 시그니처 업그레이드를 처음 고르면 1차 전직이 확정되고 기본 공격 자체가 바뀐다.
local jobFor = {berserker = "physical", molotov = "fire", toxic_rain = "toxic"}
local jobNames = {physical = "광전사", fire = "화염 투척병", toxic = "맹독술사"}
local jobDesc = {
    physical = "도끼 손맛 그대로, 멈추지 않고 벨수록 미쳐 날뜁니다.",
    fire = "기본 공격이 도끼질 대신 마우스 위치로 화염병을 던지는 것으로 바뀝니다.",
    toxic = "기본 공격이 도끼질 대신 마우스 위치에 맹독을 터뜨리는 것으로 바뀝니다."
}

-- job이 있는 카드는 해당 전직에서만 뜨는 전직 전용 카드다. job이 없으면 모든 전직에 공용으로 뜬다.
local definitions = {
    -- 파괴력 (destroy) — 얼마나 빨리 없애느냐 [광전사 전용 + 공용]
    {id="wide_blade", track="destroy", name="넓은 날", desc="도끼 범위와 한 번에 타격하는 나무 수가 늘어납니다.", max=3, color={1,.62,.18}, job="physical"},
    {id="berserker", track="destroy", name="광전사", desc="쉬지 않고 벨수록 공격 속도가 빨라집니다 (멈추면 초기화).", max=3, color={1,.42,.22}, job="physical"},
    {id="shockwave", track="destroy", name="충격파", desc="나무를 쓰러뜨리면 주변 나무에도 충격파 피해를 줍니다.", max=3, color={1,.78,.2}, job="physical"},
    {id="domino", track="destroy", name="도미노", desc="쓰러지는 나무가 진행 방향의 다른 나무를 함께 쓰러뜨립니다.", max=3, color={.95,.55,.3}},
    -- 확산력 (spread) — 한 번의 행동으로 얼마나 넓게 없애느냐 [화염 투척병 전용]
    {id="molotov", track="spread", name="화염병", desc="화염병 공격의 사거리와 폭발 범위가 늘어나고, 주기적으로 저절로 하나 더 던집니다.", max=3, color={1,.35,.12}, job="fire"},
    {id="dry_forest", track="spread", name="마른 숲", desc="불이 주변 나무로 더 빠르고 넓게 번집니다.", max=3, color={1,.5,.15}, job="fire"},
    {id="oil_drum", track="spread", name="기름통", desc="나무가 다 타버리면 확률적으로 주변이 한꺼번에 폭발합니다.", max=3, color={1,.62,.1}, job="fire"},
    {id="embers", track="spread", name="불씨", desc="다 타버린 나무에서 불씨가 튀어 멀리 있는 나무에도 옮겨붙습니다.", max=3, color={1,.75,.25}, job="fire"},
    -- 억제력 (suppress) — 자연이 얼마나 다시 못 자라게 하느냐 [맹독술사 전용 + 공용]
    {id="herbicide", track="suppress", name="제초제", desc="벤 자리는 숲이 다시 자라지 않는 죽은 땅이 될 확률이 있습니다.", max=3, color={.62,.4,.85}},
    {id="root_cutting", track="suppress", name="뿌리 절단", desc="나무를 벨 때마다 숲의 재생력이 약해집니다.", max=3, color={.5,.62,.9}},
    {id="toxic_rain", track="suppress", name="독성 비", desc="맹독 공격의 범위와 피해가 늘어나고, 평소에도 주변에 약하게 지속 피해를 줍니다.", max=3, color={.55,.85,.45}, job="toxic"},
    {id="forced_growth", track="suppress", name="강제 성장", desc="숲의 재생 속도가 크게 빨라지지만, 목재 경험치 획득량도 크게 늘어납니다.", max=3, color={.85,.7,.25}}
}

local milestones = {
    {pct=10, text="\"숲이 당신의 존재를 알아챈 것 같다...\"", wave={squirrel=4}},
    {pct=30, text="다람쥐들이 사방으로 도망치기 시작한다.", wave={squirrel=4, boar=2}},
    {pct=50, text="숲의 절반이 사라졌다.", wave={squirrel=3}, boss="ent"},
    {pct=70, text="숲이... 이상할 정도로 조용해졌다.", wave={boar=4, turret=3}},
    {pct=90, text="거의 다 왔다. 마지막 나무들이 보인다.", wave={squirrel=6, boar=3, turret=2}}
}

local enemyDefs = {
    squirrel = {name="화난 다람쥐", hp=8, speed=155, damage=4, radius=13, color={.62,.38,.18}, hitCooldown=.85, reward=2},
    boar = {name="가시 멧돼지", hp=30, speed=100, damage=9, radius=20, color={.4,.27,.19}, hitCooldown=1.1, reward=4},
    turret = {name="버섯 포탑", hp=22, speed=0, damage=7, radius=18, color={.74,.34,.52}, ranged=true, range=300, fireInterval=1.9, reward=5},
    ent = {name="엘더 트렌트", hp=260, speed=48, damage=16, radius=42, color={.33,.21,.12}, hitCooldown=1, boss=true,
        slamInterval=3.2, slamRadius=110, slamDamage=20, reward=40},
    worldtree = {name="세계수", hp=950, speed=0, damage=0, radius=92, color={.26,.5,.22}, boss=true, finalBoss=true,
        slamInterval=4, slamRadius=150, slamDamage=18, summonInterval=7, reward=0}
}

local function formatTime(value)
    value = math.max(0, math.floor(value))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end

function ClearcutMode.new()
    return setmetatable({
        levels={}, choices={}, level=1, xp=0, xpNext=10, pending=0,
        totalWood=0, treesFelled=0, elapsed=0, initialTrees=0, remainingTrees=0,
        maxMulti=1, maxChain=0, axeCooldown=0, axeRange=150, milestoneFired={},
        regrowTimer=0, regrowGrace=45, regrowInterval=7, regrowPulses=0, treesRevived=0, regrowFlash=0,
        rootHazards={}, rootedTimer=0, rootedCount=0,
        bees={}, beeSlow=false, beeSwarmsTriggered=0, beehiveTotal=0,
        streak=0, lastHitAt=-10, molotovTimer=0, wildfireTimer=0, toxicTimer=0, evolutions={}, molotovs={},
        job=nil, attackCooldown=0,
        hp=100, maxHp=100, invulnTimer=0, dead=false,
        enemies={}, projectiles={}, bossTelegraphs={}, waveFired={}, worldTreeSpawned=false, readyToFinish=false, activeBoss=nil, kills=0,
        chests={}, chestPending=false, molotovShots=0, wildburstTimer=10, plagued={}, dodges=0
    }, ClearcutMode)
end

function ClearcutMode:levelOf(id) return self.levels[id] or 0 end
function ClearcutMode:pickupRadius() return 165 + self:levelOf("magnet") * 95 end
function ClearcutMode:pickupSpeed() return 15 + self:levelOf("magnet") * 4 end
function ClearcutMode:destructionPct() return self.initialTrees > 0 and math.min(100, (1 - self.remainingTrees / self.initialTrees) * 100) or 0 end

function ClearcutMode:setup(game)
    game.runType, game.clearcut = "clearcut", self
    game.time, game.ended, game.victory = math.huge, false, false
    game.world.nodes, game.world.drops, game.world.enemies, game.world.buildings = {}, {}, {}, {}
    game.world.spawnTimer = math.huge
    game.world.theme = "forest"
    game.world.hideBase = true
    game.world.treeVisual.scale = .16
    game.world.treeVisual.shadowRx, game.world.treeVisual.shadowRy, game.world.treeVisual.frontBias = 58, 8, 82
    local w, h = game.world.width, game.world.height
    local spawnX, spawnY = w / 2, h / 2
    game.player.x, game.player.y = spawnX, spawnY
    self.baseSpeed = 320
    game.player.speed, game.player.capacity, game.player.gather = self.baseSpeed, 99999, 1.15
    game.camera.x, game.camera.y, game.camera.zoom = spawnX, spawnY, .72
    local attempts, target, minSep = 0, 260, 108
    while #game.world.nodes < target and attempts < 12000 do
        attempts = attempts + 1
        local x = love.math.random(130, w - 130)
        local y = love.math.random(130, h - 130)
        local sdx, sdy = x - spawnX, y - spawnY
        local clearSpawn = sdx*sdx + sdy*sdy > 260*260
        local separated = true
        for _, node in ipairs(game.world.nodes) do
            local ndx, ndy = x - node.x, y - node.y
            if ndx*ndx + ndy*ndy < minSep*minSep then separated = false; break end
        end
        if clearSpawn and separated then
            local beehive = love.math.random() < .07
            game.world.nodes[#game.world.nodes+1] = {kind="tree",x=x,y=y,work=0,workTime=1,active=true,respawn=0,rushTree=true,rushHp=3,rushMaxHp=3,beehive=beehive}
            if beehive then self.beehiveTotal = self.beehiveTotal + 1 end
        end
    end
    self.initialTrees, self.remainingTrees = #game.world.nodes, #game.world.nodes
    game:setNotice("숲 전체를 밀어버려라 — 마우스를 누른 채 나무 근처로 이동하세요", "food")
end

function ClearcutMode:update(dt, game)
    if self.dead then return end
    self.elapsed = self.elapsed + dt
    self:updateHeldAxe(dt, game)
    self:updateRegrowth(dt, game)
    self:updateRootHazards(dt, game)
    self:updateBees(dt, game)
    self:updateFire(dt, game)
    self:updateMolotovs(dt, game)
    self:updateToxicRain(dt, game)
    self:updateEnemies(dt, game)
    self:updateProjectiles(dt, game)
    self:updateBossTelegraphs(dt, game)
    self:updateChests(dt, game)
    self:updatePlague(dt, game)
    if self.elapsed - self.lastHitAt > .9 then self.streak = 0 end
    self.regrowFlash = math.max(0, self.regrowFlash - dt)
    self.rootedTimer = math.max(0, self.rootedTimer - dt)
    self.invulnTimer = math.max(0, self.invulnTimer - dt)
    game.player.speed = self.baseSpeed * (self.rootedTimer > 0 and .18 or 1)
end

function ClearcutMode:updateRegrowth(dt, game)
    if self.elapsed < self.regrowGrace then return end
    self.regrowTimer = self.regrowTimer + dt
    if self.regrowTimer < self.regrowInterval then return end
    self.regrowTimer = 0
    self:regrowPulse(game)
end

function ClearcutMode:regrowPulse(game)
    local activeTrees = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then activeTrees[#activeTrees+1] = node end
    end
    if #activeTrees == 0 then return end
    local minutes = self.elapsed / 60
    local base = math.min(.16, .02 + minutes * .022)
    local suppress = math.min(.75, self:levelOf("root_cutting") * .16)
    local boost = self:levelOf("forced_growth") * .5
    local regrowPct = base * (1 - suppress) * (1 + boost)
    local radius = 230
    local candidates = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and not node.active and not node.sterile then
            for _, active in ipairs(activeTrees) do
                local dx, dy = node.x - active.x, node.y - active.y
                if dx*dx + dy*dy <= radius*radius then candidates[#candidates+1] = node; break end
            end
        end
    end
    if #candidates == 0 then return end
    for i = #candidates, 2, -1 do local j = love.math.random(i); candidates[i], candidates[j] = candidates[j], candidates[i] end
    local desired = math.max(1, math.floor(#activeTrees * regrowPct))
    local count = math.min(desired, #candidates)
    for i = 1, count do
        local node = candidates[i]
        node.active, node.rushHp = true, node.rushMaxHp
        node.dominoChild, node.burning, node.fallT = nil, nil, nil
        self.remainingTrees = self.remainingTrees + 1
    end
    if count > 0 then
        self.regrowPulses = self.regrowPulses + 1
        self.treesRevived = self.treesRevived + count
        self.regrowFlash = 1.4
        game:setNotice(string.format("숲이 재생하고 있다 — 나무 %d그루가 되살아났다!", count), "food")
        if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .25) end
        self:spawnRootBurst(candidates, count, game)
    end
end

function ClearcutMode:spawnRootBurst(candidates, count, game)
    local picks = math.min(3, count)
    for i = 1, picks do
        local node = candidates[i]
        local dx, dy = node.x - game.player.x, node.y - game.player.y
        if dx*dx + dy*dy <= 900*900 then
            self.rootHazards[#self.rootHazards+1] = {x=node.x, y=node.y, phase="warn", timer=.6, radius=95}
        end
    end
end

function ClearcutMode:updateRootHazards(dt, game)
    for i = #self.rootHazards, 1, -1 do
        local hazard = self.rootHazards[i]
        hazard.timer = hazard.timer - dt
        if hazard.phase == "warn" and hazard.timer <= 0 then
            hazard.phase, hazard.timer = "active", 1.1
            local dx, dy = game.player.x - hazard.x, game.player.y - hazard.y
            if dx*dx + dy*dy <= hazard.radius*hazard.radius then
                self.rootedTimer = math.max(self.rootedTimer, 1.3)
                self.rootedCount = self.rootedCount + 1
                game:setNotice("가시덩굴이 발목을 붙잡았다!", "ore")
                if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .3) end
            end
            for _ = 1, 14 do game.world:addParticle(hazard.x, hazard.y - 20, {.42, .62, .18}, true, false) end
        elseif hazard.phase == "active" and hazard.timer <= 0 then
            table.remove(self.rootHazards, i)
        end
    end
end

function ClearcutMode:updateBees(dt, game)
    for i = #self.bees, 1, -1 do
        local swarm = self.bees[i]
        swarm.life = swarm.life - dt
        local dx, dy = game.player.x - swarm.x, game.player.y - swarm.y
        local d = math.sqrt(dx*dx + dy*dy)
        if d > 4 then swarm.x, swarm.y = swarm.x + dx / d * swarm.speed * dt, swarm.y + dy / d * swarm.speed * dt end
        if swarm.life <= 0 then table.remove(self.bees, i) end
    end
    self.beeSlow = false
    for _, swarm in ipairs(self.bees) do
        local dx, dy = game.player.x - swarm.x, game.player.y - swarm.y
        if dx*dx + dy*dy <= 100*100 then self.beeSlow = true end
    end
end

function ClearcutMode:damagePlayer(amount, game)
    if self.dead or self.invulnTimer > 0 or amount <= 0 then return end
    if self:levelOf("berserker") >= 3 and self.streak >= 10 then
        self.dodges = self.dodges + 1
        self.invulnTimer = .2
        game:setNotice("불멸의 분노 — 회피!", "food")
        for _ = 1, 6 do game.world:addParticle(game.player.x, game.player.y - 20, {1, .85, .3}, true, false) end
        return
    end
    self.hp = math.max(0, self.hp - amount)
    self.invulnTimer = .35
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .3) end
    for _ = 1, 8 do game.world:addParticle(game.player.x, game.player.y - 30, {1, .22, .16}, true, false) end
    if self.hp <= 0 then
        self.dead = true
        self:finish(game, false)
    end
end

function ClearcutMode:damageEnemiesInRadius(x, y, radius, damage, game)
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - x, e.y - y
        if dx*dx + dy*dy <= radius*radius then
            e.hp = e.hp - damage
            for _ = 1, 4 do game.world:addParticle(e.x, e.y - 12, {1, .32, .2}, true, false) end
        end
    end
end

function ClearcutMode:spawnEnemy(kind, x, y)
    local def = enemyDefs[kind]
    if not def then return end
    local e = {kind = kind, def = def, x = x, y = y, hp = def.hp, maxHp = def.hp, hitTimer = 0, fireTimer = def.fireInterval, slamTimer = def.slamInterval, summonTimer = def.summonInterval}
    self.enemies[#self.enemies + 1] = e
    if def.boss then self.activeBoss = e end
    return e
end

function ClearcutMode:spawnWave(counts, game)
    for kind, count in pairs(counts) do
        for _ = 1, count do
            local a = love.math.random() * math.pi * 2
            local r = 480 + love.math.random() * 180
            self:spawnEnemy(kind, game.player.x + math.cos(a) * r, game.player.y + math.sin(a) * r)
        end
    end
    game:setNotice("적이 몰려온다!", "ore")
end

function ClearcutMode:spawnBoss(kind, game)
    local a = love.math.random() * math.pi * 2
    local e = self:spawnEnemy(kind, game.player.x + math.cos(a) * 420, game.player.y + math.sin(a) * 420)
    game:setNotice((e and e.def.name or "보스") .. " 등장!", "ore")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .4) end
end

function ClearcutMode:spawnWorldTree(game)
    if self.worldTreeSpawned then return end
    self.worldTreeSpawned = true
    self.worldTree = self:spawnEnemy("worldtree", game.player.x, game.player.y - 280)
    game:setNotice("세계수가 깨어났다 — 이것이 숲의 마지막 저항이다!", "ore")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .5) end
end

function ClearcutMode:spawnEnemyProjectile(e, game)
    local dx, dy = game.player.x - e.x, game.player.y - e.y
    local d = math.sqrt(dx*dx + dy*dy)
    if d <= 0 then return end
    self.projectiles[#self.projectiles + 1] = {x = e.x, y = e.y, vx = dx / d * 150, vy = dy / d * 150, life = 3, damage = e.def.damage, color = e.def.color}
end

function ClearcutMode:updateProjectiles(dt, game)
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
        p.life = p.life - dt
        local dx, dy = game.player.x - p.x, game.player.y - p.y
        if dx*dx + dy*dy <= 22*22 then
            self:damagePlayer(p.damage, game)
            table.remove(self.projectiles, i)
        elseif p.life <= 0 then
            table.remove(self.projectiles, i)
        end
    end
end

function ClearcutMode:bossSlam(e, game)
    self.bossTelegraphs[#self.bossTelegraphs + 1] = {x = e.x, y = e.y, radius = e.def.slamRadius, phase = "warn", timer = .75, damage = e.def.slamDamage}
end

function ClearcutMode:updateBossTelegraphs(dt, game)
    for i = #self.bossTelegraphs, 1, -1 do
        local t = self.bossTelegraphs[i]
        t.timer = t.timer - dt
        if t.phase == "warn" and t.timer <= 0 then
            t.phase, t.timer = "active", .25
            local dx, dy = game.player.x - t.x, game.player.y - t.y
            if dx*dx + dy*dy <= t.radius * t.radius then self:damagePlayer(t.damage, game) end
            if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .4) end
        elseif t.phase == "active" and t.timer <= 0 then
            table.remove(self.bossTelegraphs, i)
        end
    end
end

function ClearcutMode:onEnemyDefeated(e, game)
    self.kills = self.kills + 1
    if e.def.reward and e.def.reward > 0 then self:onWood(e.def.reward, game) end
    if e == self.worldTree then
        self.readyToFinish = true
        game:setNotice("세계수를 쓰러뜨렸다 — 숲이 완전히 멈췄다.", "food")
    end
    if e.def.boss and not e.def.finalBoss then
        self.chests[#self.chests + 1] = {x = e.x, y = e.y, collected = false}
        game:setNotice(e.def.name .. "가 보물상자를 떨어뜨렸다!", "ore")
    end
    if e == self.activeBoss then self.activeBoss = nil end
end

function ClearcutMode:updateChests(dt, game)
    for _, c in ipairs(self.chests) do
        if not c.collected then
            local dx, dy = game.player.x - c.x, game.player.y - c.y
            if dx*dx + dy*dy <= 46*46 then
                c.collected = true
                self:openChest(game)
            end
        end
    end
end

function ClearcutMode:openChest(game)
    local pool = {}
    for _, def in ipairs(definitions) do
        if def.job == self.job and self:levelOf(def.id) < def.max then pool[#pool + 1] = def end
    end
    if #pool == 0 then
        self:onWood(40, game)
        game:setNotice("보물상자 — 전직 스킬을 이미 전부 마스터했다! 목재 +40", "food")
        return
    end
    for i = #pool, 2, -1 do local j = love.math.random(i); pool[i], pool[j] = pool[j], pool[i] end
    self.choices = {}
    for i = 1, math.min(3, #pool) do self.choices[i] = pool[i] end
    self.chestPending = true
    game.mode = "clearcut_upgrade"
    game:setNotice("보물상자 — 전직 전용 스킬을 하나 고르세요!", "food")
end

function ClearcutMode:updateEnemies(dt, game)
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        local def = e.def
        e.hitTimer = math.max(0, e.hitTimer - dt)
        if def.ranged then
            local dx, dy = game.player.x - e.x, game.player.y - e.y
            local dist = math.sqrt(dx*dx + dy*dy)
            e.fireTimer = e.fireTimer - dt
            if dist <= def.range and e.fireTimer <= 0 then
                e.fireTimer = def.fireInterval
                self:spawnEnemyProjectile(e, game)
            end
        elseif def.speed > 0 or not def.boss then
            local dx, dy = game.player.x - e.x, game.player.y - e.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > def.radius + 20 then
                e.x, e.y = e.x + dx / dist * def.speed * dt, e.y + dy / dist * def.speed * dt
                e.moving = true
            else
                e.moving = false
                if e.hitTimer <= 0 then
                    e.hitTimer = def.hitCooldown
                    self:damagePlayer(def.damage, game)
                end
            end
        end
        if def.slamInterval then
            e.slamTimer = e.slamTimer - dt
            if e.slamTimer <= 0 then
                e.slamTimer = def.slamInterval
                self:bossSlam(e, game)
            end
        end
        if def.summonInterval then
            e.summonTimer = e.summonTimer - dt
            if e.summonTimer <= 0 then
                e.summonTimer = def.summonInterval
                self:spawnWave({squirrel = 2, boar = 1}, game)
            end
        end
        if e.hp <= 0 then
            self:onEnemyDefeated(e, game)
            table.remove(self.enemies, i)
        end
    end
    if self.remainingTrees <= 0 and not self.worldTreeSpawned then self:spawnWorldTree(game) end
end

function ClearcutMode:igniteNear(source, game, radius, count, depth)
    local candidates = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and not node.burning and node ~= source then
            local dx, dy = node.x - source.x, node.y - source.y
            if dx*dx + dy*dy <= radius*radius then candidates[#candidates+1] = node end
        end
    end
    for i = #candidates, 2, -1 do local j = love.math.random(i); candidates[i], candidates[j] = candidates[j], candidates[i] end
    depth = depth or ((source.spreadDepth or 0) + 1)
    for i = 1, math.min(count, #candidates) do
        candidates[i].burning, candidates[i].burnTimer, candidates[i].spreadDepth, candidates[i].fireTickTimer = true, 0, depth, 0
        game.world:igniteFx(candidates[i].x, candidates[i].y, false)
    end
end

function ClearcutMode:throwMolotov(game)
    local candidates = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and not node.burning and not node.igniting then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            if dx*dx + dy*dy <= 620*620 then candidates[#candidates+1] = node end
        end
    end
    if #candidates == 0 then return end
    local target = candidates[love.math.random(#candidates)]
    target.igniting = true
    local dist = math.sqrt((target.x-game.player.x)^2 + (target.y-game.player.y)^2)
    self.molotovs[#self.molotovs+1] = {
        x0=game.player.x, y0=game.player.y-40, x1=target.x, y1=target.y,
        t=0, dur=math.max(.28, dist/900), target=target
    }
    self:trackMolotovBarrage(game)
end

function ClearcutMode:trackMolotovBarrage(game)
    if self:levelOf("molotov") < 3 then return end
    self.molotovShots = self.molotovShots + 1
    if self.molotovShots % 3 == 0 then
        game:setNotice("융단 폭격 — 화염병 만렙 특수효과!", "food")
        for _ = 1, 2 do
            local a = love.math.random() * math.pi * 2
            local r = 60 + love.math.random() * 100
            self:hurlMolotovAt(game.player.x + math.cos(a) * (200 + r), game.player.y + math.sin(a) * (200 + r), game, true)
        end
    end
end

function ClearcutMode:hurlMolotovAt(tx, ty, game, isBarrage)
    local dist = math.sqrt((tx-game.player.x)^2 + (ty-game.player.y)^2)
    self.molotovs[#self.molotovs+1] = {
        x0=game.player.x, y0=game.player.y-40, x1=tx, y1=ty,
        t=0, dur=math.max(.2, dist/1100), manual=true, radius=90 + self:levelOf("molotov") * 20
    }
    if not isBarrage then self:trackMolotovBarrage(game) end
end

function ClearcutMode:updateMolotovs(dt, game)
    for i = #self.molotovs, 1, -1 do
        local m = self.molotovs[i]
        m.t = m.t + dt
        if m.t >= m.dur then
            if m.manual then
                self:igniteNear({x=m.x1, y=m.y1}, game, m.radius, 99, 0)
                self:damageEnemiesInRadius(m.x1, m.y1, m.radius, 9, game)
                game.world:igniteFx(m.x1, m.y1, true)
            elseif m.target.active and not m.target.burning then
                m.target.burning, m.target.burnTimer, m.target.igniting, m.target.spreadDepth, m.target.fireTickTimer = true, 0, nil, 0, 0
                game.world:igniteFx(m.target.x, m.target.y, true)
            elseif m.target then
                m.target.igniting = nil
            end
            table.remove(self.molotovs, i)
        end
    end
end

function ClearcutMode:onTreeBurnedDown(node, game)
    local oilLevel = self:levelOf("oil_drum")
    local oilChance = oilLevel >= 3 and 1 or oilLevel * .15
    if oilLevel > 0 and love.math.random() < oilChance then
        self:igniteNear(node, game, 90 + oilLevel * 30, 99)
        game.world:igniteFx(node.x, node.y, true)
    end
    local emberLevel = self:levelOf("embers")
    if emberLevel > 0 and not node.emberChained then
        local far = {}
        for _, other in ipairs(game.world.nodes) do
            if other.rushTree and other.active and not other.burning then
                local dx, dy = other.x - node.x, other.y - node.y
                local d2 = dx*dx + dy*dy
                if d2 <= 620*620 then far[#far+1] = {node=other, d2=d2} end
            end
        end
        table.sort(far, function(a, b) return a.d2 > b.d2 end)
        for i = 1, math.min(emberLevel, #far) do
            local target = far[i].node
            target.burning, target.burnTimer, target.emberChained = true, 0, true
            target.spreadDepth, target.fireTickTimer = (node.spreadDepth or 0) + 1, 0
            game.world:igniteFx(target.x, target.y, false)
            if emberLevel >= 3 then self:igniteNear(target, game, 90, 2, target.spreadDepth) end
        end
    end
end

function ClearcutMode:updateFire(dt, game)
    local molotovLevel = self:levelOf("molotov")
    if molotovLevel > 0 then
        self.molotovTimer = self.molotovTimer + dt
        local interval = math.max(2.6, 8 - molotovLevel * 1.6)
        if self.molotovTimer >= interval then
            self.molotovTimer = 0
            self:throwMolotov(game)
        end
    end
    if self.evolutions.wildfire then
        self.wildfireTimer = self.wildfireTimer + dt
        if self.wildfireTimer >= 3 then
            self.wildfireTimer = 0
            self:throwMolotov(game)
        end
    end
    local dryLevel = self:levelOf("dry_forest")
    local spreadChancePerSec = .12 + dryLevel * .14
    local spreadRadius = 130 + dryLevel * 45
    local burnDuration = math.max(2.2, 3.6 - dryLevel * .35)
    if dryLevel >= 3 then
        self.wildburstTimer = self.wildburstTimer - dt
        if self.wildburstTimer <= 0 then
            self.wildburstTimer = 10
            local burning = {}
            for _, node in ipairs(game.world.nodes) do if node.rushTree and node.active and node.burning then burning[#burning+1] = node end end
            if #burning > 0 then
                game:setNotice("들불 — 마른 숲 만렙 특수효과!", "food")
                for _, source in ipairs(burning) do self:igniteNear(source, game, spreadRadius * 1.4, 2) end
            end
        end
    end
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and node.burning then
            node.burnTimer = node.burnTimer + dt
            node.fireTickTimer = (node.fireTickTimer or 0) - dt
            if node.fireTickTimer <= 0 then
                node.fireTickTimer = .5
                local falloff = .5 ^ (node.spreadDepth or 0)
                self:damageEnemiesInRadius(node.x, node.y, 75, 3 * falloff, game)
            end
            if node.burnTimer >= burnDuration then
                node.burning = false
                self:onTreeBurnedDown(node, game)
                self:fellTree(node, game)
            elseif love.math.random() < spreadChancePerSec * dt then
                self:igniteNear(node, game, spreadRadius, 1)
            end
        end
    end
end

function ClearcutMode:updateToxicRain(dt, game)
    local lvl = self:levelOf("toxic_rain")
    if lvl == 0 then return end
    self.toxicTimer = self.toxicTimer + dt
    local interval = math.max(2, 6 - lvl * 1.2)
    if self.toxicTimer < interval then return end
    self.toxicTimer = 0
    local radius = 120 + lvl * 20
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            if dx*dx + dy*dy <= radius*radius then
                node.rushHp = (node.rushHp or node.rushMaxHp) - lvl
                game.world:impactNode(node, game, false)
                if node.rushHp <= 0 then self:fellTree(node, game) end
            end
        end
    end
    game.world:toxicPulseFx(game.player.x, game.player.y, radius)
end

function ClearcutMode:updatePlague(dt, game)
    for i = #self.plagued, 1, -1 do
        local p = self.plagued[i]
        p.timer = p.timer - dt
        p.tickTimer = (p.tickTimer or 0) - dt
        local alive
        if p.kind == "tree" then
            alive = p.ref.rushTree and p.ref.active
            if alive and p.tickTimer <= 0 then
                p.tickTimer = .6
                game.world:addParticle(p.ref.x, p.ref.y - 60, {.5, .85, .35}, false, false)
                p.ref.rushHp = (p.ref.rushHp or p.ref.rushMaxHp) - 1
                game.world:impactNode(p.ref, game, false)
                if p.ref.rushHp <= 0 then self:fellTree(p.ref, game) end
            end
        else
            alive = p.ref.hp > 0
            if alive and p.tickTimer <= 0 then
                p.tickTimer = .6
                p.ref.hp = p.ref.hp - 2
                game.world:addParticle(p.ref.x, p.ref.y - 10, {.5, .85, .35}, false, false)
            end
        end
        if not alive or p.timer <= 0 then
            if p.ref then p.ref.plagueMarked = nil end
            table.remove(self.plagued, i)
        end
    end
end

function ClearcutMode:onTreeFallen(node, game)
    local dominoLevel = self:levelOf("domino")
    if dominoLevel == 0 then return end
    if node.dominoChild and not self.evolutions.collapse then return end
    local reach = 90 + dominoLevel * 40
    local dirX = node.fallDir or 1
    local tx, ty = node.x + dirX * reach, node.y
    local best, bestD
    for _, other in ipairs(game.world.nodes) do
        if other.rushTree and other.active and other ~= node then
            local dx, dy = other.x - tx, other.y - ty
            local d2 = dx*dx + dy*dy
            if d2 <= (reach * .65) ^ 2 and (not bestD or d2 < bestD) then best, bestD = other, d2 end
        end
    end
    if best then
        best.dominoChild = true
        best.rushHp = 0
        game.world:impactNode(best, game, true)
        self:fellTree(best, game)
    end
end

function ClearcutMode:closestTreeInAxeRange(game)
    local bestNode, bestDistance
    local range2 = self.axeRange * self.axeRange
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            local distance = dx * dx + dy * dy
            if distance <= range2 and (not bestDistance or distance < bestDistance) then
                bestNode, bestDistance = node, distance
            end
        end
    end
    return bestNode
end

function ClearcutMode:berserkerSpeedMult()
    local lvl = self:levelOf("berserker")
    if lvl == 0 then return 1 end
    return 1 + lvl * .07 * math.min(self.streak, 14)
end

function ClearcutMode:updateHeldAxe(dt, game, heldOverride)
    if self.job == "fire" then return self:updateFireAttack(dt, game, heldOverride) end
    if self.job == "toxic" then return self:updateToxicAttack(dt, game, heldOverride) end
    return self:updatePhysicalAttack(dt, game, heldOverride)
end

function ClearcutMode:updatePhysicalAttack(dt, game, heldOverride)
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    game.player.axeHolding = held
    self.axeRange = 150 + self:levelOf("wide_blade") * 20
    game.player.axeRange = self.axeRange
    self.axeCooldown = math.max(0, self.axeCooldown - dt)
    if not held or self.axeCooldown > 0 then return false end
    local target = self:closestTreeInAxeRange(game)
    if not target then return false end
    game.player:cancelInteraction()
    game.player:playAutoAxeSwing(target.x)
    self:hitTree(target, game)
    local speed = (game.tools.axe.speed or 1) * game.player.gather * (self.beeSlow and .6 or 1) * self:berserkerSpeedMult()
    self.axeCooldown = .82 / speed
    return true
end

function ClearcutMode:aimPoint(game, maxRange)
    game.player.axeHolding = false
    local tx, ty = game.camera:screenToWorld(love.mouse.getPosition())
    local dx, dy = tx - game.player.x, ty - game.player.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > maxRange and dist > 0 then
        tx, ty = game.player.x + dx / dist * maxRange, game.player.y + dy / dist * maxRange
    end
    return tx, ty
end

function ClearcutMode:updateFireAttack(dt, game, heldOverride)
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    self.attackCooldown = math.max(0, self.attackCooldown - dt)
    local maxRange = 320 + self:levelOf("molotov") * 40
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY, self.aimRadius = tx, ty, 90 + self:levelOf("molotov") * 20
    if not held or self.attackCooldown > 0 then return false end
    self:hurlMolotovAt(tx, ty, game)
    local speed = (game.tools.axe.speed or 1) * game.player.gather
    self.attackCooldown = 1.05 / speed
    return true
end

function ClearcutMode:updateToxicAttack(dt, game, heldOverride)
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    self.attackCooldown = math.max(0, self.attackCooldown - dt)
    local maxRange = 260 + self:levelOf("toxic_rain") * 40
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY, self.aimRadius = tx, ty, 90 + self:levelOf("toxic_rain") * 25
    if not held or self.attackCooldown > 0 then return false end
    local dmg = 2 + self:levelOf("toxic_rain")
    local plagueLv3 = self:levelOf("toxic_rain") >= 3
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree then
            local dx, dy = node.x - tx, node.y - ty
            if dx*dx + dy*dy <= self.aimRadius * self.aimRadius then
                if self.evolutions.necrosis and not node.sterile then
                    node.sterile = true
                    game.world:addParticle(node.x, node.y - 30, {.55, .35, .25}, false, false)
                end
                if node.active then
                    node.rushHp = (node.rushHp or node.rushMaxHp) - dmg
                    game.world:impactNode(node, game, true)
                    if node.rushHp <= 0 then self:fellTree(node, game)
                    elseif plagueLv3 and not node.plagueMarked then
                        node.plagueMarked = true
                        self.plagued[#self.plagued+1] = {kind="tree", ref=node, timer=4, tickTimer=0}
                    end
                end
            end
        end
    end
    if plagueLv3 then
        for _, e in ipairs(self.enemies) do
            local dx, dy = e.x - tx, e.y - ty
            if dx*dx + dy*dy <= self.aimRadius * self.aimRadius and not e.plagueMarked then
                e.plagueMarked = true
                self.plagued[#self.plagued+1] = {kind="enemy", ref=e, timer=4, tickTimer=0}
            end
        end
    end
    self:damageEnemiesInRadius(tx, ty, self.aimRadius, dmg * 3, game)
    game.world:toxicPulseFx(tx, ty, self.aimRadius)
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .18) end
    local speed = (game.tools.axe.speed or 1) * game.player.gather
    self.attackCooldown = .85 / speed
    return true
end

function ClearcutMode:checkMilestones(game)
    local pct = self:destructionPct()
    for _, m in ipairs(milestones) do
        if pct >= m.pct and not self.milestoneFired[m.pct] then
            self.milestoneFired[m.pct] = true
            game:setNotice(m.text, "food")
            if m.wave then self:spawnWave(m.wave, game) end
            if m.boss then self:spawnBoss(m.boss, game) end
        end
    end
end

function ClearcutMode:onWood(amount, game)
    self.totalWood = self.totalWood + amount
    game.wood = self.totalWood
    local xpMult = 1 + self:levelOf("forced_growth") * .4
    self.xp = self.xp + amount * xpMult
    while self.xp >= self.xpNext do
        self.xp = self.xp - self.xpNext
        self.level, self.pending = self.level + 1, self.pending + 1
        self.xpNext = math.floor(10 + (self.level - 1) * 6.5)
    end
    if self.pending > 0 and game.mode == "playing" and not os.getenv("LAST_HAUL_SELF_TEST") then self:rollChoices(); game.mode="clearcut_upgrade" end
end

function ClearcutMode:rollChoices()
    local pool = {}
    for _, def in ipairs(definitions) do
        local jobOk = not def.job or not self.job or def.job == self.job
        if jobOk and self:levelOf(def.id) < def.max then pool[#pool+1]=def end
    end
    for i=#pool,2,-1 do local j=love.math.random(i); pool[i],pool[j]=pool[j],pool[i] end
    self.choices={}
    for i=1,math.min(3,#pool) do self.choices[i]=pool[i] end
end

function ClearcutMode:checkEvolutions(game)
    if not self.evolutions.wildfire and self:levelOf("molotov") >= 3 and self:levelOf("oil_drum") >= 3 then
        self.evolutions.wildfire = true
        game:setNotice("진화 — 산불! 불이 걷잡을 수 없이 번지기 시작한다.", "ore")
    end
    if not self.evolutions.collapse and self:levelOf("shockwave") >= 3 and self:levelOf("domino") >= 3 then
        self.evolutions.collapse = true
        game:setNotice("진화 — 벌목 붕괴! 쓰러진 나무가 또 다른 붕괴를 부른다.", "ore")
    end
    if not self.evolutions.deadGround and self:levelOf("herbicide") >= 3 and self:levelOf("root_cutting") >= 3 then
        self.evolutions.deadGround = true
        game:setNotice("진화 — 죽은 땅! 한 번 벤 땅은 다시는 자라지 않는다.", "ore")
    end
    if not self.evolutions.frenzy and self:levelOf("berserker") >= 3 and self:levelOf("shockwave") >= 3 then
        self.evolutions.frenzy = true
        game:setNotice("융합 스킬 — 광란 충격! 콤보가 절정에 달하면 모든 타격이 충격파를 뿜는다.", "ore")
    end
    if not self.evolutions.necrosis and self:levelOf("toxic_rain") >= 3 and self:levelOf("root_cutting") >= 3 then
        self.evolutions.necrosis = true
        game:setNotice("융합 스킬 — 괴사의 비! 맹독이 닿은 땅은 그 자리에서 불모지가 된다.", "ore")
    end
end

function ClearcutMode:choose(index, game)
    local def=self.choices[index]
    if not def then return false end
    self.levels[def.id]=self:levelOf(def.id)+1
    self.pending=math.max(0,self.pending-1)
    if not self.job and jobFor[def.id] and self.levels[def.id]==1 then
        self.job = jobFor[def.id]
        self.attackCooldown = 0
        game:setNotice("1차 전직 — " .. jobNames[self.job] .. "! " .. jobDesc[self.job], "ore")
    else
        game:setNotice(def.name.." Lv."..self:levelOf(def.id),"food")
    end
    self:checkEvolutions(game)
    if self.pending>0 then self:rollChoices() else game.mode="playing" end
    return true
end

function ClearcutMode:fellTree(node, game)
    if not node.active then return false end
    local wasBeehive = node.beehive
    node.active, node.respawn, node.rushHp = false, math.huge, 0
    local amount = 4
    game.world:harvestBurst(node, game, amount, "목재")
    game.world:spawnDrop("wood", amount, node.x, node.y - 10, 42, 30, 1.5)
    self.treesFelled = self.treesFelled + 1
    self.remainingTrees = math.max(0, self.remainingTrees - 1)
    local herbLevel = self:levelOf("herbicide")
    if self.evolutions.deadGround or (herbLevel > 0 and love.math.random() < herbLevel * .22) then
        node.sterile = true
    end
    if wasBeehive and #self.bees < 5 then
        self.bees[#self.bees+1] = {x=node.x, y=node.y, speed=150, life=7}
        self.beeSwarmsTriggered = self.beeSwarmsTriggered + 1
        game:setNotice("벌집을 건드렸다 — 벌떼가 쫓아온다!", "ore")
    end
    self:checkMilestones(game)
    return true
end

function ClearcutMode:megaCleave(primary, game)
    local radius = 380
    game:setNotice("광역 참격 — 넓은 날 만렙 특수효과!", "food")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .5) end
    self:damageEnemiesInRadius(primary.x, primary.y, radius, 30, game)
    game.world:igniteFx(primary.x, primary.y, true)
    local hit = 0
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and hit < 40 then
            local dx, dy = node.x - primary.x, node.y - primary.y
            if dx*dx + dy*dy <= radius*radius then
                node.rushHp = 0
                game.world:impactNode(node, game, true)
                if self:fellTree(node, game) then hit = hit + 1 end
            end
        end
    end
end

function ClearcutMode:hitTree(primary, game)
    if not primary.active then return end
    self.streak = self.streak + 1
    self.lastHitAt = self.elapsed
    local wideLevel = self:levelOf("wide_blade")
    local radius = 75 + wideLevel * 45
    local targetCount = 1 + wideLevel * 2
    self:damageEnemiesInRadius(primary.x, primary.y, radius, 9 + self:levelOf("berserker") * 2, game)
    if wideLevel >= 3 and love.math.random() < .15 then self:megaCleave(primary, game) end
    local candidates={}
    for _,node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx,dy=node.x-primary.x,node.y-primary.y
            local d2=dx*dx+dy*dy
            if d2<=radius*radius then candidates[#candidates+1]={node=node,d2=d2} end
        end
    end
    table.sort(candidates,function(a,b) return a.d2<b.d2 end)
    local felled={}
    local hits=math.min(targetCount,#candidates)
    self.maxMulti=math.max(self.maxMulti,hits)
    local frenzyActive = self.evolutions.frenzy and self.streak >= 10
    for i=1,hits do
        local node=candidates[i].node
        node.rushHp=(node.rushHp or node.rushMaxHp)-1
        game.world:impactNode(node,game,false)
        if node.rushHp<=0 and self:fellTree(node,game) then felled[#felled+1]=node end
        if frenzyActive then
            self:damageEnemiesInRadius(node.x, node.y, 65, 4, game)
            game.world:addParticle(node.x, node.y - 40, {1, .82, .25}, false, false)
        end
    end
    local shockLevel = self:levelOf("shockwave")
    if shockLevel > 0 and #felled > 0 then
        local shockRadius = 70 + shockLevel * 25
        local hitSet, chainCount, shockFelled = {}, 0, {}
        for _, source in ipairs(felled) do
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active and not hitSet[node] then
                    local dx, dy = node.x - source.x, node.y - source.y
                    if dx*dx + dy*dy <= shockRadius * shockRadius then
                        hitSet[node] = true
                        node.rushHp = (node.rushHp or node.rushMaxHp) - shockLevel
                        game.world:impactNode(node, game, true)
                        if node.rushHp <= 0 and self:fellTree(node, game) then chainCount = chainCount + 1; shockFelled[#shockFelled+1] = node end
                    end
                end
            end
        end
        if shockLevel >= 3 and #shockFelled > 0 then
            local r2 = shockRadius * .7
            for _, source in ipairs(shockFelled) do
                for _, node in ipairs(game.world.nodes) do
                    if node.rushTree and node.active and not hitSet[node] then
                        local dx, dy = node.x - source.x, node.y - source.y
                        if dx*dx + dy*dy <= r2 * r2 then
                            hitSet[node] = true
                            node.rushHp = (node.rushHp or node.rushMaxHp) - math.ceil(shockLevel / 2)
                            game.world:impactNode(node, game, true)
                            if node.rushHp <= 0 and self:fellTree(node, game) then chainCount = chainCount + 1 end
                        end
                    end
                end
            end
        end
        self.maxChain = math.max(self.maxChain, chainCount)
    end
    self:checkMilestones(game)
end

function ClearcutMode:finish(game, victory)
    if game.result then return end
    if victory == nil then victory = true end
    game.ended, game.victory = true, victory
    game.result={elapsed=math.floor(self.elapsed),wood=self.totalWood,trees=self.treesFelled,total=self.initialTrees,maxMulti=self.maxMulti,maxChain=self.maxChain,level=self.level,regrowPulses=self.regrowPulses,treesRevived=self.treesRevived,rootedCount=self.rootedCount,beeSwarms=self.beeSwarmsTriggered,victory=victory,kills=self.kills}
    game.mode="clearcut_results"
end

local function drawBeeBody(x, y, angle, wingPhase)
    love.graphics.push(); love.graphics.translate(x, y); love.graphics.rotate(angle)
    local flap = math.abs(math.sin(wingPhase)) * .9 + .15
    love.graphics.setColor(1, 1, 1, .5 * flap)
    love.graphics.ellipse("fill", -.5, -2.4, 2.6, 1.3 * flap)
    love.graphics.ellipse("fill", 1.6, -2.2, 2.2, 1.1 * flap)
    love.graphics.setColor(.12, .09, .02, 1); love.graphics.ellipse("fill", 0, 0, 3.1, 2)
    love.graphics.setColor(1, .78, .1, 1)
    love.graphics.ellipse("fill", -1.6, 0, 1, 1.9)
    love.graphics.ellipse("fill", .8, 0, 1, 1.9)
    love.graphics.setColor(0, 0, 0, .8); love.graphics.setLineWidth(.7); love.graphics.ellipse("line", 0, 0, 3.1, 2)
    love.graphics.setColor(.08, .06, .02, 1); love.graphics.circle("fill", 3, 0, 1)
    love.graphics.pop()
end

local function drawBeehive(x, y, t)
    local bob = math.sin(t * 3 + x) * 3
    local hy = y + bob
    local layers = {{0, 10, 13, 7}, {0, 2, 11, 6.5}, {0, -6, 8.5, 6}, {0, -13, 5.5, 5}}
    for _, l in ipairs(layers) do
        love.graphics.setColor(.8, .6, .26, 1); love.graphics.ellipse("fill", x + l[1], hy + l[2], l[3], l[4])
        love.graphics.setColor(.5, .34, .1, .85); love.graphics.setLineWidth(1.3); love.graphics.ellipse("line", x + l[1], hy + l[2], l[3], l[4])
    end
    love.graphics.setColor(.16, .09, .03, 1); love.graphics.ellipse("fill", x, hy + 11, 3.2, 2)
    for i = 1, 3 do
        local a = t * 4.5 + i * 2.1
        local bx, by = x + math.cos(a) * 15, hy - 5 + math.sin(a * 1.4) * 9
        drawBeeBody(bx, by, a + math.pi / 2, t * 30 + i)
    end
end

-- 픽셀 그리드 스프라이트: 문자 하나 = 픽셀 한 칸. '.'은 투명.
local function drawPixelGrid(rows, palette, cx, cy, px)
    local gh, gw = #rows, #rows[1]
    local ox, oy = gw * px / 2, gh * px / 2
    for ry = 1, gh do
        local row = rows[ry]
        for rx = 1, gw do
            local col = palette[row:sub(rx, rx)]
            if col then
                love.graphics.setColor(col)
                love.graphics.rectangle("fill", math.floor(cx - ox + (rx - 1) * px), math.floor(cy - oy + (ry - 1) * px), px + 1, px + 1)
            end
        end
    end
end

local squirrelRows = {
    "..OO....",
    ".OBBO.TT",
    "OBBBBOTT",
    "OBEOBEOT",
    "OBBBBBO.",
    ".OBBBO..",
    "..OLOL..",
    "..OO.OO.",
}
local squirrelPalette = {O={.15,.09,.05,1}, B={.72,.4,.14,1}, E={1,.16,.1,1}, T={.5,.28,.11,1}, L={.4,.22,.09,1}}

local boarRows = {
    "..OOOOOO..",
    ".ODDDDDDO.",
    "ODDDDDDDDO",
    "ODEDDDDEDO",
    "ODDDDDDDDO",
    "OWO....OWO",
    ".OL.OO.LO.",
    "..O....O.",
}
local boarPalette = {O={.14,.08,.05,1}, D={.42,.26,.16,1}, E={.05,.03,.02,1}, W={.92,.86,.72,1}, L={.28,.16,.09,1}}

local turretRows = {
    "..OOOO..",
    ".OCCCCO.",
    "OCCwCCCO",
    "OCCCwCCO",
    "OCCCCCCO",
    "..OSSO..",
    "..OSSO..",
    "..OOOO..",
}
local turretPalette = {O={.16,.05,.13,1}, C={.72,.28,.5,1}, w={.96,.82,.9,1}, S={.72,.62,.48,1}}

local entRows = {
    "..OOOOOOOO..",
    ".OGGGGGGGGO.",
    "OGGgGGGgGGGO",
    "OGGGGGGGGGGO",
    ".OGGGGGGGGO.",
    "..OOBBBBOO..",
    "...OBEBEOO..",
    "...OBBBBOO..",
    "...OBBBBOO..",
    "..OOBBBBOO..",
    ".OO.OBBO.OO.",
    "OO..OBBO..OO",
    "....OLO.OLO.",
    "....OO...OO.",
}
local entPalette = {O={.1,.07,.03,1}, G={.2,.42,.14,1}, g={.28,.55,.2,1}, B={.42,.27,.14,1}, E={1,.82,.2,1}, L={.24,.15,.07,1}}

local worldTreeRows = {
    "...OOOOOOOOOOO...",
    "..OGGGGGGGGGGGO..",
    ".OGGgGGGGGgGGGGO.",
    "OGGGGGGgGGGGGGGGO",
    "OGGgGGGGGGGgGGGGO",
    ".OGGGGGGGGGGGGGO.",
    "..OGGGGGGGGGGGO..",
    "...OOBBBBBBBOO...",
    "....OBBYYYBBOO...",
    "....OBBYYYBBOO...",
    "....OBBBBBBBOO...",
    "...OOBB.BBBOO....",
    "..OO.BB.BB.OO....",
    ".OO..BB.BB..OO...",
    "OO...OO.OO...OO..",
    "O....O...O....O..",
}
local worldTreePalette = {O={.08,.05,.02,1}, G={.18,.4,.16,1}, g={.26,.56,.24,1}, B={.32,.2,.1,1}, Y={1,.9,.45,1}}

local enemySprites = {
    squirrel = {rows = squirrelRows, palette = squirrelPalette},
    boar = {rows = boarRows, palette = boarPalette},
    turret = {rows = turretRows, palette = turretPalette},
    ent = {rows = entRows, palette = entPalette},
    worldtree = {rows = worldTreeRows, palette = worldTreePalette},
}

local chestRows = {
    "..OOOOOO..",
    ".OGGGGGGO.",
    "OGGGGGGGGO",
    "OOOOOOOOOO",
    "OWWWKWWWWO",
    "OWWWKWWWWO",
    "OWWWKWWWWO",
    ".OOOOOOOO.",
}
local chestPalette = {O={.16,.1,.04,1}, G={.85,.68,.28,1}, W={.5,.3,.13,1}, K={1,.92,.4,1}}

local function drawEnemy(e, t)
    local def = e.def
    local walking = def.speed > 0 and (e.moving or false)
    local bob = walking and math.abs(math.sin(t * 10 + e.x)) * def.radius * .12 or (def.boss and math.sin(t * 1.6 + e.x) * def.radius * .04 or 0)
    local sprite = enemySprites[e.kind]
    love.graphics.setColor(0, 0, 0, .32)
    love.graphics.ellipse("fill", e.x, e.y + def.radius * .8, def.radius * .95, def.radius * .3)
    if sprite then
        local px = (def.radius * 2.1) / #sprite.rows[1]
        if walking then
            love.graphics.push(); love.graphics.rotate(math.sin(t * 10 + e.x) * .05)
        end
        drawPixelGrid(sprite.rows, sprite.palette, e.x, e.y - bob, px)
        if walking then love.graphics.pop() end
    end
    if e.plagueMarked then
        love.graphics.setColor(.5, .9, .35, .3 + math.sin(t * 8) * .12)
        love.graphics.rectangle("fill", e.x - def.radius, e.y - bob - def.radius, def.radius * 2, def.radius * 2)
    end
    local hpPct = math.max(0, e.hp / e.maxHp)
    local barW = def.radius * 2.2
    love.graphics.setColor(0, 0, 0, .7); love.graphics.rectangle("fill", math.floor(e.x - barW/2), math.floor(e.y - def.radius - 16), math.floor(barW), 6)
    love.graphics.setColor(hpPct > .3 and 1 or 1, hpPct > .3 and .3 or .12, .16, 1)
    love.graphics.rectangle("fill", math.floor(e.x - barW/2), math.floor(e.y - def.radius - 16), math.floor(barW * hpPct), 6)
    love.graphics.setColor(1, 1, 1, .5); love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", math.floor(e.x - barW/2), math.floor(e.y - def.radius - 16), math.floor(barW), 6)
end

function ClearcutMode:drawWorldOverlay(game)
    love.graphics.setLineStyle("rough")
    local t = love.timer.getTime()
    if (self.job == "fire" or self.job == "toxic") and self.aimX then
        local ringColor = self.job == "fire" and {1, .5, .15} or {.55, .85, .45}
        love.graphics.setColor(ringColor[1], ringColor[2], ringColor[3], .16); love.graphics.circle("fill", self.aimX, self.aimY, self.aimRadius)
        love.graphics.setLineWidth(2); love.graphics.setColor(ringColor[1], ringColor[2], ringColor[3], .85)
        love.graphics.circle("line", self.aimX, self.aimY, self.aimRadius)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(self.aimX - 10, self.aimY, self.aimX - 4, self.aimY); love.graphics.line(self.aimX + 4, self.aimY, self.aimX + 10, self.aimY)
        love.graphics.line(self.aimX, self.aimY - 10, self.aimX, self.aimY - 4); love.graphics.line(self.aimX, self.aimY + 4, self.aimX, self.aimY + 10)
    end
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and node.beehive then
            drawBeehive(node.x, node.y - 150, t)
        end
    end
    for _, c in ipairs(self.chests) do
        if not c.collected then
            local bob = math.sin(t * 2.4 + c.x) * 4
            love.graphics.setColor(1, .85, .3, .18 + math.sin(t * 3) * .08)
            love.graphics.circle("fill", c.x, c.y + bob, 34)
            drawPixelGrid(chestRows, chestPalette, c.x, c.y + bob, 4.2)
        end
    end
    for _, hazard in ipairs(self.rootHazards) do
        if hazard.phase == "warn" then
            local pulse = 1 - math.max(0, hazard.timer) / .6
            love.graphics.setLineWidth(2.4); love.graphics.setColor(1, .55, .2, .75 - pulse * .3)
            love.graphics.circle("line", hazard.x, hazard.y, hazard.radius * pulse)
            for i = 1, 8 do
                local ang = i / 8 * math.pi * 2 + t * .6
                local r0, r1 = hazard.radius * pulse * .45, hazard.radius * pulse * .7
                love.graphics.line(hazard.x + math.cos(ang) * r0, hazard.y + math.sin(ang) * r0 * .5, hazard.x + math.cos(ang) * r1, hazard.y + math.sin(ang) * r1 * .5)
            end
        else
            local fade = math.max(0, hazard.timer) / 1.1
            for a = 0, 5 do
                local ang = a / 6 * math.pi * 2
                local px, py = hazard.x, hazard.y
                love.graphics.setLineWidth(4.5); love.graphics.setColor(.24, .42, .12, fade * .9)
                local segs = 5
                for s = 1, segs do
                    local sr = hazard.radius * .8 * (s / segs)
                    local curl = math.sin(s * 1.4 + a * 3) * 9
                    local nx = hazard.x + math.cos(ang) * sr + math.cos(ang + math.pi / 2) * curl
                    local ny = hazard.y + math.sin(ang) * sr * .5 + math.sin(ang + math.pi / 2) * curl * .5
                    love.graphics.line(px, py, nx, ny)
                    if s % 2 == 0 then
                        love.graphics.setColor(.32, .56, .16, fade)
                        love.graphics.polygon("fill", nx, ny - 3.5, nx - 2.6, ny + 2, nx + 2.6, ny + 2)
                        love.graphics.setColor(.14, .26, .07, fade * .9); love.graphics.setLineWidth(1)
                        love.graphics.polygon("line", nx, ny - 3.5, nx - 2.6, ny + 2, nx + 2.6, ny + 2)
                        love.graphics.setColor(.24, .42, .12, fade * .9)
                    end
                    px, py = nx, ny
                end
            end
        end
    end
    for _, swarm in ipairs(self.bees) do
        love.graphics.setColor(1, .9, .3, .08); love.graphics.circle("fill", swarm.x, swarm.y, 40)
        for i = 1, 5 do
            local a = t * 14 + i * 1.3
            local bx, by = swarm.x + math.cos(a) * (8 + i), swarm.y + math.sin(a * 1.7) * (6 + i * .4)
            drawBeeBody(bx, by, a, t * 34 + i * 2)
        end
    end
    if self.rootedTimer > 0 then
        for i = 1, 3 do
            love.graphics.setLineWidth(3); love.graphics.setColor(.26, .48, .13, .75 - i * .12)
            love.graphics.ellipse("line", game.player.x, game.player.y + 10 - i * 2, 17 - i * 3, 7 - i)
        end
        for i = 1, 4 do
            local a = i / 4 * math.pi * 2 + t * 2.4
            local lx, ly = game.player.x + math.cos(a) * 15, game.player.y + 9 + math.sin(a) * 6
            love.graphics.push(); love.graphics.translate(lx, ly); love.graphics.rotate(a)
            love.graphics.setColor(.36, .64, .2, .85); love.graphics.ellipse("fill", 0, 0, 4.2, 2)
            love.graphics.setColor(.16, .3, .07, .9); love.graphics.setLineWidth(.8); love.graphics.ellipse("line", 0, 0, 4.2, 2)
            love.graphics.setColor(.22, .42, .1, .9); love.graphics.setLineWidth(1); love.graphics.line(-3.5, 0, 3.5, 0)
            love.graphics.pop()
        end
    end
    for _, m in ipairs(self.molotovs) do
        local p = m.t / m.dur
        local x = m.x0 + (m.x1 - m.x0) * p
        local y = m.y0 + (m.y1 - m.y0) * p - math.sin(p * math.pi) * 120
        love.graphics.setColor(.3, .3, .3, .25)
        for i = 1, 3 do love.graphics.circle("fill", x - (m.x1 - m.x0) * .015 * i, y - (m.y1 - m.y0) * .015 * i + i * 2.5, 2 + i * .8) end
        love.graphics.push(); love.graphics.translate(x, y); love.graphics.rotate(p * 20)
        love.graphics.setColor(0, 0, 0, .3); love.graphics.ellipse("fill", 1, 8, 4.5, 2)
        love.graphics.setColor(.14, .4, .2, .96); love.graphics.rectangle("fill", -3.4, -5, 6.8, 11, 2.4, 2.4)
        love.graphics.setColor(.35, .7, .4, .5); love.graphics.rectangle("fill", -2.6, -4, 2, 9, 1.5, 1.5)
        love.graphics.setColor(.08, .26, .12, 1); love.graphics.setLineWidth(1); love.graphics.rectangle("line", -3.4, -5, 6.8, 11, 2.4, 2.4)
        love.graphics.setColor(.14, .4, .2, .96); love.graphics.rectangle("fill", -1.6, -8.5, 3.2, 4.2)
        love.graphics.setColor(.85, .78, .58, 1); love.graphics.rectangle("fill", -1, -12, 2, 4.5)
        local fl = .7 + math.sin(t * 30) * .3
        love.graphics.setColor(1, .55, .15, .9 * fl); love.graphics.circle("fill", 0, -13, 2.8 * fl)
        love.graphics.setColor(1, .85, .35, .85 * fl); love.graphics.circle("fill", 0, -13.6, 1.4 * fl)
        love.graphics.pop()
    end
    for _, tel in ipairs(self.bossTelegraphs) do
        if tel.phase == "warn" then
            local pulse = 1 - math.max(0, tel.timer) / .75
            love.graphics.setLineWidth(4); love.graphics.setColor(1, .3, .15, .85 - pulse * .3)
            love.graphics.circle("line", tel.x, tel.y, tel.radius * pulse)
            love.graphics.setColor(1, .3, .15, .1); love.graphics.circle("fill", tel.x, tel.y, tel.radius * pulse)
        else
            local fade = math.max(0, tel.timer) / .25
            love.graphics.setColor(1, .45, .2, fade * .5); love.graphics.circle("fill", tel.x, tel.y, tel.radius)
            love.graphics.setLineWidth(6); love.graphics.setColor(1, .8, .3, fade); love.graphics.circle("line", tel.x, tel.y, tel.radius)
        end
    end
    for _, e in ipairs(self.enemies) do drawEnemy(e, t) end
    for _, p in ipairs(self.projectiles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], .3); love.graphics.circle("fill", p.x, p.y, 8)
        love.graphics.setColor(p.color); love.graphics.circle("fill", p.x, p.y, 4.5)
        love.graphics.setColor(0, 0, 0, .8); love.graphics.setLineWidth(1); love.graphics.circle("line", p.x, p.y, 4.5)
    end
    if self.invulnTimer > 0 then
        love.graphics.setColor(1, .2, .15, .35); love.graphics.circle("fill", game.player.x, game.player.y - 20, 26)
    end
    love.graphics.setLineStyle("smooth")
end

function ClearcutMode:drawHUD(game,fonts)
    local w,h=love.graphics.getDimensions()
    UI.panel(16,16,360,168,{.35,1,.52,1},.94)
    love.graphics.setFont(fonts.big); love.graphics.setColor(1,1,1); love.graphics.print(formatTime(self.elapsed),32,27)
    love.graphics.setFont(fonts.body); love.graphics.setColor(.95,.7,.25); love.graphics.print("숲 전멸 실험실  ·  " .. (jobNames[self.job] or "벌목꾼"),155,35)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.9,.76); love.graphics.print(string.format("목재 %d   쓰러뜨린 나무 %d / %d",self.totalWood,self.treesFelled,self.initialTrees),32,76)
    love.graphics.print(string.format("동시 타격 %d   연쇄 %d   Lv.%d",self.maxMulti,self.maxChain,self.level),32,101)
    local statusColor = (self.rootedTimer > 0 or self.beeSlow) and {1,.6,.35} or {.6,.72,.66}
    love.graphics.setColor(statusColor)
    local status = self.rootedTimer > 0 and "발이 묶임!" or self.beeSlow and "벌떼에 쫓기는 중" or ("숲 재생 " .. self.regrowPulses .. "회 · 되살아난 나무 " .. self.treesRevived)
    love.graphics.print(status, 32, 124)
    local evoNames = {}
    if self.evolutions.wildfire then evoNames[#evoNames+1] = "산불" end
    if self.evolutions.collapse then evoNames[#evoNames+1] = "벌목 붕괴" end
    if self.evolutions.deadGround then evoNames[#evoNames+1] = "죽은 땅" end
    if self.evolutions.frenzy then evoNames[#evoNames+1] = "광란 충격" end
    if self.evolutions.necrosis then evoNames[#evoNames+1] = "괴사의 비" end
    if #evoNames > 0 then
        love.graphics.setColor(1, .82, .3); love.graphics.print("진화: " .. table.concat(evoNames, " · "), 32, 146)
    end

    love.graphics.setColor(.04,.07,.055,.9); love.graphics.rectangle("fill",16,192,360,34,8,8)
    love.graphics.setFont(fonts.small); love.graphics.setColor(1,.4,.35); love.graphics.print("HP",30,199)
    UI.bar(66,199,296,18,math.max(0,self.hp/self.maxHp),{1,.32,.26,1},{.14,.06,.05,.95})
    love.graphics.setFont(fonts.small); love.graphics.setColor(1,1,1); love.graphics.printf(math.ceil(self.hp).." / "..self.maxHp,66,201,296,"center")

    local pct = self:destructionPct()
    local barW = 300
    local flash = self.regrowFlash > 0
    UI.panel(w/2-barW/2-16,16,barW+32,70,flash and {1,.25,.2,1} or {1,.55,.2,1},.94)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.95,.85,.7); love.graphics.printf("FOREST REMAINING",w/2-barW/2,25,barW,"center")
    UI.bar(w/2-barW/2,45,barW,16,1-pct/100,flash and {1,.4,.3,1} or {.35,1,.45,1},{.1,.06,.04,.95})
    love.graphics.setFont(fonts.body); love.graphics.setColor(1,1,1); love.graphics.printf(string.format("%.0f%%",100-pct),w/2-barW/2,63,barW,"center")

    if self.activeBoss then
        local boss = self.activeBoss
        local bw = math.min(700, w*.55)
        UI.panel(w/2-bw/2,96,bw,42,{1,.3,.15,1},.95)
        love.graphics.setFont(fonts.small); love.graphics.setColor(1,.85,.7); love.graphics.printf(boss.def.name,w/2-bw/2,102,bw,"center")
        UI.bar(w/2-bw/2+14,120,bw-28,12,math.max(0,boss.hp/boss.maxHp),{1,.3,.2,1},{.12,.05,.04,.95})
    end

    local xpBarW = math.min(520, w*.42)
    local bx, by = w/2-xpBarW/2, h-108
    love.graphics.setColor(.04,.07,.055,.9); love.graphics.rectangle("fill",bx-16,by-10,xpBarW+32,46,8,8)
    love.graphics.setFont(fonts.small); love.graphics.setColor(1,.82,.3); love.graphics.print("Lv."..self.level,bx-6,by-4)
    UI.bar(bx+44,by+1,xpBarW-54,14,math.min(1,self.xp/self.xpNext),{1,.78,.25,1},{.12,.08,.04,.95})
    love.graphics.setFont(fonts.small); love.graphics.setColor(1,1,1)
    love.graphics.printf(math.floor(self.xp).." / "..self.xpNext.."  ·  다음 3택까지",bx+44,by+18,xpBarW-54,"center")

    love.graphics.setColor(.04,.07,.055,.86); love.graphics.rectangle("fill",16,h-52,565,36,8,8)
    love.graphics.setColor(.82,.9,.84); love.graphics.print("마우스 누른 채 이동: 범위 자동 벌목  ·  WASD: 이동  ·  ESC: 로비",30,h-43)
end

function ClearcutMode:drawSelection(game,fonts)
    local w,h=love.graphics.getDimensions()
    love.graphics.setColor(.015,.035,.025,.84); love.graphics.rectangle("fill",0,0,w,h)
    love.graphics.setFont(fonts.title); love.graphics.setColor(1,.82,.3); love.graphics.printf("벌목 방식 진화",0,66,w,"center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.88,.76); love.graphics.printf("계속 움직이고 더 많은 숲을 한 번에 쓸어버리세요",0,112,w,"center")
    local gap,cardW,cardH=24,math.min(320,(w-96)/3),360
    local startX=w/2-(cardW*3+gap*2)/2
    self.choiceBoxes={}
    for i,def in ipairs(self.choices) do
        local x,y=startX+(i-1)*(cardW+gap),165
        self.choiceBoxes[i]={x=x,y=y,w=cardW,h=cardH}
        UI.panel(x,y,cardW,cardH,{def.color[1],def.color[2],def.color[3],1},.97)
        love.graphics.setColor(def.color[1],def.color[2],def.color[3],.18); love.graphics.circle("fill",x+cardW/2,y+105,62)
        love.graphics.setColor(def.color); love.graphics.setLineWidth(6); love.graphics.circle("line",x+cardW/2,y+105,38)
        love.graphics.setFont(fonts.big); love.graphics.setColor(1,1,1); love.graphics.printf(tostring(i),x,y+85,cardW,"center")
        love.graphics.setFont(fonts.small); love.graphics.setColor(def.color[1],def.color[2],def.color[3],.9); love.graphics.printf(trackLabels[def.track] or "", x, y+18, cardW, "center")
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,y+190,cardW-32,"center")
        love.graphics.setFont(fonts.body); love.graphics.setColor(.72,.82,.77); love.graphics.printf(def.desc,x+28,y+242,cardW-56,"center")
        love.graphics.setColor(1,.75,.25); love.graphics.printf("Lv."..self:levelOf(def.id).." → Lv."..(self:levelOf(def.id)+1),x+20,y+318,cardW-40,"center")
    end
end

function ClearcutMode:choiceAt(x,y)
    for i,box in ipairs(self.choiceBoxes or {}) do if x>=box.x and x<=box.x+box.w and y>=box.y and y<=box.y+box.h then return i end end
end

function ClearcutMode:drawResults(game,fonts)
    local w,h,r=love.graphics.getWidth(),love.graphics.getHeight(),game.result
    local victory = r.victory ~= false
    love.graphics.setColor(0,0,0,.84); love.graphics.rectangle("fill",0,0,w,h)
    UI.panel(w/2-330,h/2-260,660,590,victory and {.35,1,.52,1} or {1,.3,.28,1},.98)
    love.graphics.setFont(fonts.title); love.graphics.setColor(1,1,1)
    love.graphics.printf(victory and "세계수를 쓰러뜨렸다 — 숲을 완전히 정복했다" or "숲의 반격에 쓰러졌다",w/2-300,h/2-230,600,"center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.7,.85,.76)
    love.graphics.printf((victory and "숲 파괴율 100%  ·  " or "미완의 정복  ·  ") .. "핵심 재미 검증 보고서",w/2-300,h/2-182,600,"center")
    local rows={{"걸린 시간",formatTime(r.elapsed)},{"총 목재",r.wood},{"쓰러뜨린 나무",r.trees.." / "..r.total},{"처치한 적",r.kills or 0},{"최대 동시 타격",r.maxMulti},{"최대 연쇄 벌목",r.maxChain},{"도달 레벨",r.level},{"숲 재생 펄스 · 되살아난 나무",r.regrowPulses.."회 · "..r.treesRevived.."그루"},{"가시덩굴에 붙잡힌 횟수",r.rootedCount},{"자극한 벌집",r.beeSwarms}}
    for i,row in ipairs(rows) do local y=h/2-140+(i-1)*38; love.graphics.setColor(i%2==0 and {.07,.12,.1,.9} or {.045,.085,.07,.9}); love.graphics.rectangle("fill",w/2-270,y,540,32,4,4); love.graphics.setColor(.72,.82,.76); love.graphics.print(row[1],w/2-250,y+7); love.graphics.setColor(1,.75,.25); love.graphics.printf(tostring(row[2]),w/2+40,y+7,270,"center") end
    UI.button(w/2-250,h/2+270,240,48,"로비로",true,fonts.body); UI.button(w/2+10,h/2+270,240,48,"다시 실험",true,fonts.body)
end

ClearcutMode.characters = {
    {id="physical", name="광전사", color={1,.42,.22}, tagline="도끼 하나로 숲을 쓸어버리는 근접 벌목광.", detail="쉬지 않고 벨수록 공격 속도가 미친 듯이 빨라집니다. 사거리 안에서 자동으로 가장 가까운 나무를 벱니다."},
    {id="fire", name="화염 투척병", color={1,.35,.12}, tagline="마우스 위치에 화염병을 던져 원거리에서 숲을 불태웁니다.", detail="근접할 필요 없이 조준만으로 광역 발화. 붙은 불은 알아서 번지고 퍼집니다."},
    {id="toxic", name="맹독술사", color={.55,.85,.45}, tagline="마우스 위치에 맹독을 터뜨려 나무와 재생력을 동시에 억누릅니다.", detail="화력은 약하지만 숲이 다시 자라나는 능력 자체를 짓누릅니다."}
}

return ClearcutMode
