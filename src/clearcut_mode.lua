local UI = require("src.ui")

local ClearcutMode = {}
ClearcutMode.__index = ClearcutMode

local trackLabels = {destroy = "파괴력", spread = "확산력", suppress = "억제력"}

local definitions = {
    -- 파괴력 (destroy) — 얼마나 빨리 없애느냐
    {id="wide_blade", track="destroy", name="넓은 날", desc="도끼 범위와 한 번에 타격하는 나무 수가 늘어납니다.", max=3, color={1,.62,.18}},
    {id="berserker", track="destroy", name="광전사", desc="쉬지 않고 벨수록 공격 속도가 빨라집니다 (멈추면 초기화).", max=3, color={1,.42,.22}},
    {id="shockwave", track="destroy", name="충격파", desc="나무를 쓰러뜨리면 주변 나무에도 충격파 피해를 줍니다.", max=3, color={1,.78,.2}},
    {id="domino", track="destroy", name="도미노", desc="쓰러지는 나무가 진행 방향의 다른 나무를 함께 쓰러뜨립니다.", max=3, color={.95,.55,.3}},
    -- 확산력 (spread) — 한 번의 행동으로 얼마나 넓게 없애느냐
    {id="molotov", track="spread", name="화염병", desc="주기적으로 화염병을 던져 나무에 불을 붙입니다.", max=3, color={1,.35,.12}},
    {id="dry_forest", track="spread", name="마른 숲", desc="불이 주변 나무로 더 빠르고 넓게 번집니다.", max=3, color={1,.5,.15}},
    {id="oil_drum", track="spread", name="기름통", desc="나무가 다 타버리면 확률적으로 주변이 한꺼번에 폭발합니다.", max=3, color={1,.62,.1}},
    {id="embers", track="spread", name="불씨", desc="다 타버린 나무에서 불씨가 튀어 멀리 있는 나무에도 옮겨붙습니다.", max=3, color={1,.75,.25}},
    -- 억제력 (suppress) — 자연이 얼마나 다시 못 자라게 하느냐
    {id="herbicide", track="suppress", name="제초제", desc="벤 자리는 숲이 다시 자라지 않는 죽은 땅이 될 확률이 있습니다.", max=3, color={.62,.4,.85}},
    {id="root_cutting", track="suppress", name="뿌리 절단", desc="나무를 벨 때마다 숲의 재생력이 약해집니다.", max=3, color={.5,.62,.9}},
    {id="toxic_rain", track="suppress", name="독성 비", desc="주기적으로 주변 나무에게 지속 피해를 줍니다.", max=3, color={.55,.85,.45}},
    {id="forced_growth", track="suppress", name="강제 성장", desc="숲의 재생 속도가 크게 빨라지지만, 목재 경험치 획득량도 크게 늘어납니다.", max=3, color={.85,.7,.25}}
}

local milestones = {
    {pct=10, text="\"숲이 당신의 존재를 알아챈 것 같다...\""},
    {pct=30, text="다람쥐들이 사방으로 도망치기 시작한다."},
    {pct=50, text="숲의 절반이 사라졌다."},
    {pct=70, text="숲이... 이상할 정도로 조용해졌다."},
    {pct=90, text="거의 다 왔다. 마지막 나무들이 보인다."}
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
        streak=0, lastHitAt=-10, molotovTimer=0, wildfireTimer=0, toxicTimer=0, evolutions={}, molotovs={}
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
    self.elapsed = self.elapsed + dt
    self:updateHeldAxe(dt, game)
    self:updateRegrowth(dt, game)
    self:updateRootHazards(dt, game)
    self:updateBees(dt, game)
    self:updateFire(dt, game)
    self:updateMolotovs(dt, game)
    self:updateToxicRain(dt, game)
    if self.elapsed - self.lastHitAt > .9 then self.streak = 0 end
    self.regrowFlash = math.max(0, self.regrowFlash - dt)
    self.rootedTimer = math.max(0, self.rootedTimer - dt)
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

function ClearcutMode:igniteNear(source, game, radius, count)
    local candidates = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and not node.burning and node ~= source then
            local dx, dy = node.x - source.x, node.y - source.y
            if dx*dx + dy*dy <= radius*radius then candidates[#candidates+1] = node end
        end
    end
    for i = #candidates, 2, -1 do local j = love.math.random(i); candidates[i], candidates[j] = candidates[j], candidates[i] end
    for i = 1, math.min(count, #candidates) do
        candidates[i].burning, candidates[i].burnTimer = true, 0
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
end

function ClearcutMode:updateMolotovs(dt, game)
    for i = #self.molotovs, 1, -1 do
        local m = self.molotovs[i]
        m.t = m.t + dt
        if m.t >= m.dur then
            if m.target.active and not m.target.burning then
                m.target.burning, m.target.burnTimer, m.target.igniting = true, 0, nil
                game.world:igniteFx(m.target.x, m.target.y, true)
            else
                m.target.igniting = nil
            end
            table.remove(self.molotovs, i)
        end
    end
end

function ClearcutMode:onTreeBurnedDown(node, game)
    local oilLevel = self:levelOf("oil_drum")
    if oilLevel > 0 and love.math.random() < oilLevel * .15 then
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
            far[i].node.burning, far[i].node.burnTimer, far[i].node.emberChained = true, 0, true
            game.world:igniteFx(far[i].node.x, far[i].node.y, false)
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
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and node.burning then
            node.burnTimer = node.burnTimer + dt
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

function ClearcutMode:checkMilestones(game)
    local pct = self:destructionPct()
    for _, m in ipairs(milestones) do
        if pct >= m.pct and not self.milestoneFired[m.pct] then
            self.milestoneFired[m.pct] = true
            game:setNotice(m.text, "food")
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
    for _, def in ipairs(definitions) do if self:levelOf(def.id) < def.max then pool[#pool+1]=def end end
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
end

function ClearcutMode:choose(index, game)
    local def=self.choices[index]
    if not def then return false end
    self.levels[def.id]=self:levelOf(def.id)+1
    self.pending=math.max(0,self.pending-1)
    game:setNotice(def.name.." Lv."..self:levelOf(def.id),"food")
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
    return true
end

function ClearcutMode:hitTree(primary, game)
    if not primary.active then return end
    self.streak = self.streak + 1
    self.lastHitAt = self.elapsed
    local wideLevel = self:levelOf("wide_blade")
    local radius = 75 + wideLevel * 45
    local targetCount = 1 + wideLevel * 2
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
    for i=1,hits do
        local node=candidates[i].node
        node.rushHp=(node.rushHp or node.rushMaxHp)-1
        game.world:impactNode(node,game,false)
        if node.rushHp<=0 and self:fellTree(node,game) then felled[#felled+1]=node end
    end
    local shockLevel = self:levelOf("shockwave")
    if shockLevel > 0 and #felled > 0 then
        local shockRadius = 70 + shockLevel * 25
        local hitSet, chainCount = {}, 0
        for _, source in ipairs(felled) do
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active and not hitSet[node] then
                    local dx, dy = node.x - source.x, node.y - source.y
                    if dx*dx + dy*dy <= shockRadius * shockRadius then
                        hitSet[node] = true
                        node.rushHp = (node.rushHp or node.rushMaxHp) - shockLevel
                        game.world:impactNode(node, game, true)
                        if node.rushHp <= 0 and self:fellTree(node, game) then chainCount = chainCount + 1 end
                    end
                end
            end
        end
        self.maxChain = math.max(self.maxChain, chainCount)
    end
    self:checkMilestones(game)
end

function ClearcutMode:finish(game)
    if game.result then return end
    game.ended, game.victory = true, true
    game.result={elapsed=math.floor(self.elapsed),wood=self.totalWood,trees=self.treesFelled,total=self.initialTrees,maxMulti=self.maxMulti,maxChain=self.maxChain,level=self.level,regrowPulses=self.regrowPulses,treesRevived=self.treesRevived,rootedCount=self.rootedCount,beeSwarms=self.beeSwarmsTriggered}
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

function ClearcutMode:drawWorldOverlay(game)
    local t = love.timer.getTime()
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and node.beehive then
            drawBeehive(node.x, node.y - 150, t)
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
end

function ClearcutMode:drawHUD(game,fonts)
    local w,h=love.graphics.getDimensions()
    UI.panel(16,16,360,168,{.35,1,.52,1},.94)
    love.graphics.setFont(fonts.big); love.graphics.setColor(1,1,1); love.graphics.print(formatTime(self.elapsed),32,27)
    love.graphics.setFont(fonts.body); love.graphics.setColor(.95,.7,.25); love.graphics.print("숲 전멸 실험실",155,35)
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
    if #evoNames > 0 then
        love.graphics.setColor(1, .82, .3); love.graphics.print("진화: " .. table.concat(evoNames, " · "), 32, 146)
    end

    local pct = self:destructionPct()
    local barW = 300
    local flash = self.regrowFlash > 0
    UI.panel(w/2-barW/2-16,16,barW+32,70,flash and {1,.25,.2,1} or {1,.55,.2,1},.94)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.95,.85,.7); love.graphics.printf("FOREST REMAINING",w/2-barW/2,25,barW,"center")
    UI.bar(w/2-barW/2,45,barW,16,1-pct/100,flash and {1,.4,.3,1} or {.35,1,.45,1},{.1,.06,.04,.95})
    love.graphics.setFont(fonts.body); love.graphics.setColor(1,1,1); love.graphics.printf(string.format("%.0f%%",100-pct),w/2-barW/2,63,barW,"center")

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
    love.graphics.setColor(0,0,0,.84); love.graphics.rectangle("fill",0,0,w,h)
    UI.panel(w/2-330,h/2-260,660,556,{.35,1,.52,1},.98)
    love.graphics.setFont(fonts.title); love.graphics.setColor(1,1,1); love.graphics.printf("숲을 전부 밀어버렸다",w/2-300,h/2-230,600,"center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.7,.85,.76); love.graphics.printf("숲 파괴율 100%  ·  핵심 재미 검증 보고서",w/2-300,h/2-182,600,"center")
    local rows={{"걸린 시간",formatTime(r.elapsed)},{"총 목재",r.wood},{"쓰러뜨린 나무",r.trees.." / "..r.total},{"최대 동시 타격",r.maxMulti},{"최대 연쇄 벌목",r.maxChain},{"도달 레벨",r.level},{"숲 재생 펄스 · 되살아난 나무",r.regrowPulses.."회 · "..r.treesRevived.."그루"},{"가시덩굴에 붙잡힌 횟수",r.rootedCount},{"자극한 벌집",r.beeSwarms}}
    for i,row in ipairs(rows) do local y=h/2-140+(i-1)*38; love.graphics.setColor(i%2==0 and {.07,.12,.1,.9} or {.045,.085,.07,.9}); love.graphics.rectangle("fill",w/2-270,y,540,32,4,4); love.graphics.setColor(.72,.82,.76); love.graphics.print(row[1],w/2-250,y+7); love.graphics.setColor(1,.75,.25); love.graphics.printf(tostring(row[2]),w/2+40,y+7,270,"center") end
    UI.button(w/2-250,h/2+236,240,48,"로비로",true,fonts.body); UI.button(w/2+10,h/2+236,240,48,"다시 실험",true,fonts.body)
end

return ClearcutMode
