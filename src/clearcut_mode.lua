local UI = require("src.ui")
local TraitFx = require("src.trait_fx")

local ClearcutMode = {}
ClearcutMode.__index = ClearcutMode

local trackLabels = {destroy = "파괴력", spread = "확산력", suppress = "억제력", develop = "개발력"}

-- 시그니처 업그레이드를 처음 고르면 1차 전직이 확정되고 기본 공격 자체가 바뀐다.
local jobFor = {berserker = "physical", molotov = "fire", toxic_rain = "toxic", heavy_machinery = "developer"}
local jobNames = {physical = "생계형 나무꾼", fire = "흡연자", toxic = "비건 단체 회장", developer = "부동산 개발업자"}
local jobDesc = {
    physical = "그냥 오늘 할당량을 채우러 왔을 뿐이다. 대출은 갚아야 하니까.",
    fire = "기본 공격이 도끼질 대신 마우스 위치에 담배꽁초를 튕기는 것으로 바뀝니다. 숲이 마른 건 내 탓이 아니다.",
    toxic = "기본 공격이 도끼질 대신 마우스 위치에 '친환경' 제초제를 살포하는 것으로 바뀝니다. 숲을 지키기 위해 숲을 없앤다.",
    developer = "기본 공격이 도끼질 대신 마우스 방향으로 중장비 돌진하는 것으로 바뀝니다. 여기에 아파트 지으면 됨."
}

-- job이 있는 카드는 해당 전직에서만 뜨는 전직 전용 카드다. job이 없으면 모든 전직에 공용으로 뜬다.
local definitions = {
    -- 파괴력 (destroy) — 얼마나 빨리 없애느냐 [생계형 나무꾼 전용 + 공용]
    {id="wide_blade", track="destroy", name="야근 수당", desc="범위와 한 번에 타격하는 나무 수가 늘어납니다. 잔업은 곧 돈이다.", max=3, color={1,.62,.18}, job="physical"},
    {id="berserker", track="destroy", name="이번 달 목표 초과", desc="쉬지 않고 벨수록 공격 속도가 빨라집니다 (멈추면 초기화).", max=3, color={1,.42,.22}, job="physical"},
    {id="shockwave", track="destroy", name="산재 위험수당", desc="나무를 쓰러뜨리면 주변 나무에도 충격파 피해를 줍니다.", max=3, color={1,.78,.2}, job="physical"},
    {id="domino", track="destroy", name="도미노", desc="쓰러지는 나무가 진행 방향의 다른 나무를 함께 쓰러뜨립니다.", max=3, color={.95,.55,.3}},
    -- 확산력 (spread) — 한 번의 행동으로 얼마나 넓게 없애느냐 [흡연자 전용]
    {id="molotov", track="spread", name="꽁초 투척", desc="사거리와 폭발 범위가 늘어나고, 주기적으로 무심코 하나 더 튕깁니다.", max=3, color={1,.35,.12}, job="fire"},
    {id="dry_forest", track="spread", name="건조주의보 무시", desc="불이 주변 나무로 더 빠르고 넓게 번집니다.", max=3, color={1,.5,.15}, job="fire"},
    {id="oil_drum", track="spread", name="라이터 기름 유출", desc="나무가 다 타버리면 확률적으로 주변이 한꺼번에 폭발합니다.", max=3, color={1,.62,.1}, job="fire"},
    {id="embers", track="spread", name="바람 부는 날 흡연", desc="다 타버린 나무에서 불씨가 튀어 멀리 있는 나무에도 옮겨붙습니다.", max=3, color={1,.75,.25}, job="fire"},
    -- 억제력 (suppress) — 자연이 얼마나 다시 못 자라게 하느냐 [비건 단체 회장 전용 + 공용]
    {id="herbicide", track="suppress", name="제초제", desc="벤 자리는 숲이 다시 자라지 않는 죽은 땅이 될 확률이 있습니다.", max=3, color={.62,.4,.85}},
    {id="root_cutting", track="suppress", name="뿌리 절단", desc="나무를 벨 때마다 숲의 재생력이 약해집니다.", max=3, color={.5,.62,.9}},
    {id="toxic_rain", track="suppress", name="친환경 제초 캠페인", desc="맹독 공격의 범위와 피해가 늘어나고, 평소에도 주변에 약하게 지속 피해를 줍니다.", max=3, color={.55,.85,.45}, job="toxic"},
    {id="forced_growth", track="suppress", name="강제 성장", desc="숲의 재생 속도가 크게 빨라지지만, 목재 경험치 획득량도 크게 늘어납니다.", max=3, color={.85,.7,.25}},
    -- 개발력 (develop) — 말뚝 → 중장비 → 폭파 [부동산 개발업자 전용]
    {id="pile_driving", track="develop", name="말뚝 박기", desc="돌진 사거리가 늘어나고 재사용 대기시간이 줄어듭니다.", max=3, color={.7,.62,.4}, job="developer"},
    {id="heavy_machinery", track="develop", name="중장비 투입", desc="돌진 경로의 폭이 넓어져 더 많은 나무를 밀어버립니다.", max=3, color={1,.72,.15}, job="developer"},
    {id="demolition", track="develop", name="철거 폭파", desc="돌진이 끝나는 지점에서 폭발이 일어나 주변 나무에도 피해를 줍니다.", max=3, color={1,.45,.15}, job="developer"},
    {id="site_clearance", track="develop", name="부지 정지 작업", desc="돌진이 지나간 자리는 다시는 나무가 자라지 않는 부지가 됩니다.", max=3, color={.55,.5,.55}, job="developer"}
}

-- 아르카나: 인크리멘탈 업그레이드와 별개로 스테이지를 깰 때마다 딱 1번 고르는 영구 룰 변경 카드.
-- 레벨이 없고 되돌릴 수 없는 트레이드오프 — 한 번 고르면 그 판 내내 유지된다.
local arcanaDefs = {
    {id="aging_body", name="몸이 예전 같지 않다", desc="최대 체력이 크게 늘어나지만, 몸이 무거워져 이동속도가 줄어듭니다.",
        color={.6,.7,1}, icon="blob",
        apply=function(self) self.maxHp=self.maxHp+40; self.hp=self.hp+40; self.baseSpeed=self.baseSpeed*.88 end},
    {id="all_in_bet", name="올인 베팅", desc="받는 피해가 크게 늘어나지만, 목재 획득량도 크게 늘어납니다.",
        color={1,.35,.3}, icon="diamond",
        apply=function(self) self.dmgTakenMul=(self.dmgTakenMul or 1)*1.35; self.woodGainMul=(self.woodGainMul or 1)*1.3 end},
    {id="overtime_request", name="연장근무 신청", desc="숲의 저주가 더 빠르게 짙어지지만, 정예와 사신의 등장 간격은 늘어납니다.",
        color={1,.6,.2}, icon="box",
        apply=function(self) self.curseBoostMul=(self.curseBoostMul or 1)*1.25; self.eliteIntervalMul=(self.eliteIntervalMul or 1)*1.25; self.reaperDelayMul=(self.reaperDelayMul or 1)*1.25 end},
    {id="refuse_mercy", name="숲의 자비를 거부한다", desc="숲이 더 이상 재생하지 않게 되지만, 목재 획득량이 늘어납니다.",
        color={.55,.35,.85}, icon="stick",
        apply=function(self) self.regrowSuppressed=true; self.woodGainMul=(self.woodGainMul or 1)*1.2 end},
    {id="deep_curse", name="뿌리 깊은 저주", desc="광폭화 라운드가 더 자주 찾아오지만, 그만큼 처치 보너스도 두 배로 불어납니다.",
        color={.85,.2,.5}, icon="diamond",
        apply=function(self) self.berserkCooldownMul=(self.berserkCooldownMul or 1)*.7; self.berserkBonusMul=(self.berserkBonusMul or 1)*2 end},
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
        slamInterval=4, slamRadius=150, slamDamage=18, summonInterval=7, reward=0},
    reaper = {name="숲의 사신", hp=550, speed=118, damage=14, radius=24, color={.1,.03,.05}, hitCooldown=.65, reward=60},
    vineSprout = {name="식충 덩굴괴수", hp=42, speed=0, damage=6, radius=27, color={.35,.65,.25}, ranged=true, thornAttack=true, range=360, fireInterval=1.55, reward=7, hitCooldown=1}
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
        job=nil, attackCooldown=0, dashing=nil, dashTrail={}, smoking=nil,
        smokerHeldLast=false, physicalAction=nil, veganAction=nil, developerAction=nil,
        actionAudit={physicalImpact=0,cigaretteFlick=0,veganBite=0,developerRemote=0},
        hp=100, maxHp=100, invulnTimer=0, dead=false,
        enemies={}, projectiles={}, bossTelegraphs={}, waveFired={}, worldTreeSpawned=false, readyToFinish=false, activeBoss=nil, kills=0,
        chests={}, chestPending=false, molotovShots=0, wildburstTimer=10, plagued={}, dodges=0,
        timeSpawnTimer=18, eliteTimer=200, reaperSpawned=false,
        stage=1, stageBossHpMul=1,
        berserkState="idle", berserkTimer=85, berserkCycleCount=0, berserkTreeTimer=0, berserkKillsStart=0, berserkFlashNodes={},
        banished={}, rerollCount=0, banishArmed=false, selectionKind="upgrade", arcanaChoices={}, arcanaPicked={},
        dmgTakenMul=1, woodGainMul=1, curseBoostMul=1, eliteIntervalMul=1, reaperDelayMul=1, regrowSuppressed=false,
        berserkCooldownMul=1, berserkBonusMul=1,
        permanentTraits={},
        vinePlantTimer=24, vineSpawns={},
        disasterState="idle", disasterTimer=75, disasterType=nil, rainSuppressFire=false, quakeShakes={},
        offscreenPulse=0,
        traitFx=TraitFx.new()
    }, ClearcutMode)
end

function ClearcutMode:levelOf(id) return self.levels[id] or 0 end
function ClearcutMode:pickupRadius() return 165 + self:levelOf("magnet") * 95 end
function ClearcutMode:pickupSpeed() return 15 + self:levelOf("magnet") * 4 end
function ClearcutMode:destructionPct() return self.initialTrees > 0 and math.min(100, (1 - self.remainingTrees / self.initialTrees) * 100) or 0 end
-- 뱀서라이크식 단일 난이도 다이얼: 진행도와 무관하게 순수 경과시간으로만 오른다 (농성 방지)
function ClearcutMode:curseLevel() return 1 + (self.elapsed / 60) ^ 1.25 * .16 * (self.curseBoostMul or 1) end
-- 광폭화 라운드 중 스폰/물량 배율: 경고 단계부터 서서히 조여오다 광란 단계에서 폭증한다
function ClearcutMode:berserkMultiplier()
    if self.berserkState == "active" then return 2.4 + self.berserkCycleCount * .25 end
    if self.berserkState == "warn" then return 1.3 end
    return 1
end

function ClearcutMode:setup(game)
    game.runType, game.clearcut = "clearcut", self
    game.time, game.ended, game.victory = math.huge, false, false
    game.world.nodes, game.world.drops, game.world.enemies, game.world.buildings = {}, {}, {}, {}
    game.world.spawnTimer = math.huge
    game.world.theme = "forest"
    game.world.hideBase = true
    -- The clear-cut variants are pre-baked at their final on-screen size.
    game.world.treeVisual.scale = 1
    game.world.treeVisual.variantScale = {1, 1, 1, 1}
    game.world.treeVisual.shadowRx, game.world.treeVisual.shadowRy, game.world.treeVisual.frontBias = 58, 8, 82
    local w, h = game.world.width, game.world.height
    local spawnX, spawnY = w / 2, h / 2
    game.player.x, game.player.y = spawnX, spawnY
    self.baseSpeed = 320
    game.player.speed, game.player.capacity, game.player.gather = self.baseSpeed, 99999, 1.15
    game.camera.x, game.camera.y, game.camera.zoom = spawnX, spawnY, .72
    self:generateForest(game, 260)
    game:setNotice("숲 전체를 밀어버려라 — 마우스를 누른 채 나무 근처로 이동하세요", "food")
    if self.job == "fire" then self:startSmoking(game) end
end

-- 나무 배치 로직: 최초 진입(setup)과 스테이지 전환(advanceStage)에서 공용으로 쓴다
function ClearcutMode:generateForest(game, target)
    local w, h = game.world.width, game.world.height
    local spawnX, spawnY = w / 2, h / 2
    local attempts, minSep = 0, 108
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
            local variantCount = math.max(1, #(game.world.images.treeVariants or {}))
            local treeVariant = (#game.world.nodes % variantCount) + 1
            game.world.nodes[#game.world.nodes+1] = {kind="tree",x=x,y=y,work=0,workTime=1,active=true,respawn=0,rushTree=true,rushHp=3,rushMaxHp=3,beehive=beehive,treeVariant=treeVariant}
            if beehive then self.beehiveTotal = self.beehiveTotal + 1 end
        end
    end
    self.initialTrees, self.remainingTrees = #game.world.nodes, #game.world.nodes
end

-- 스테이지 클리어: 세계수를 쓰러뜨리면 런을 끝내는 대신 더 큰 숲과 더 강한 저주로 다음 스테이지를 연다
function ClearcutMode:advanceStage(game)
    self.stage = self.stage + 1
    self.stageBossHpMul = 1 + (self.stage - 1) * .55
    game.world.nodes, game.world.drops = {}, {}
    self.enemies, self.projectiles, self.bossTelegraphs = {}, {}, {}
    self.rootHazards, self.bees, self.molotovs, self.chests, self.plagued = {}, {}, {}, {}, {}
    self.milestoneFired, self.worldTreeSpawned, self.worldTree, self.activeBoss = {}, false, nil, nil
    self.regrowTimer = 0
    local w, h = game.world.width, game.world.height
    game.player.x, game.player.y = w / 2, h / 2
    game.camera.x, game.camera.y = game.player.x, game.player.y
    self:generateForest(game, math.floor(260 + (self.stage - 1) * 45))
    game:setNotice("스테이지 " .. self.stage .. " — 숲이 더 거세게 반격한다!", "ore")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .3) end
    self.pending = self.pending + 1
    if #self:arcanaPool() > 0 then
        self.selectionKind = "arcana"
        self:rollArcanaChoices()
        game.mode = "clearcut_upgrade"
    else
        self:openUpgradeChoices(game)
    end
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
    self:updateTimeSpawner(dt, game)
    self:updateEliteTimer(dt, game)
    self:updateReaper(dt, game)
    self:updateBerserk(dt, game)
    self:updateBerserkFlashNodes(dt)
    self:updateVinePlants(dt, game)
    self:updateDisasters(dt, game)
    self:updateEnemies(dt, game)
    self:updateProjectiles(dt, game)
    self:updateBossTelegraphs(dt, game)
    self:updateChests(dt, game)
    self:updatePlague(dt, game)
    self.traitFx:update(dt)
    for i = #self.dashTrail, 1, -1 do
        local dtr = self.dashTrail[i]
        dtr.life = dtr.life - dt
        if dtr.life <= 0 then table.remove(self.dashTrail, i) end
    end
    if self.elapsed - self.lastHitAt > .9 then self.streak = 0 end
    self.regrowFlash = math.max(0, self.regrowFlash - dt)
    self.rootedTimer = math.max(0, self.rootedTimer - dt)
    self.invulnTimer = math.max(0, self.invulnTimer - dt)
    game.player.speed = self.baseSpeed * (self.rootedTimer > 0 and .18 or 1)
end

function ClearcutMode:updateRegrowth(dt, game)
    if self.regrowSuppressed then return end
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
                if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .3) end
                if hazard.berserk then
                    game:setNotice("미쳐버린 나무뿌리가 살을 파고든다!", "ore")
                    self:damagePlayer(9 + self.berserkCycleCount * 1.5, game)
                else
                    game:setNotice("가시덩굴이 발목을 붙잡았다!", "ore")
                end
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
    amount = amount * (self.dmgTakenMul or 1)
    if self:levelOf("berserker") >= 3 and self.streak >= 10 then
        self.dodges = self.dodges + 1
        self.invulnTimer = .2
        game:setNotice("칼퇴 직전 폭주 — 회피!", "food")
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

function ClearcutMode:spawnEnemy(kind, x, y, opts)
    local def = enemyDefs[kind]
    if not def then return end
    opts = opts or {}
    local curse = self:curseLevel()
    local hp = def.hp * (1 + (curse - 1) * .55) * (opts.hpMul or 1)
    local e = {
        kind = kind, def = def, x = x, y = y, hp = hp, maxHp = hp, hitTimer = 0,
        fireTimer = def.fireInterval, slamTimer = def.slamInterval, summonTimer = def.summonInterval, seed = love.math.random() * 10,
        speedMul = (1 + (curse - 1) * .22) * (opts.speedMul or 1),
        dmgMul = (1 + (curse - 1) * .35) * (opts.dmgMul or 1),
        elite = opts.elite,
    }
    self.enemies[#self.enemies + 1] = e
    if def.boss then self.activeBoss = e end
    return e
end

function ClearcutMode:spawnWave(counts, game)
    local swarmMul = (1 + (self:curseLevel() - 1) * .6) * self:berserkMultiplier()
    for kind, count in pairs(counts) do
        local scaledCount = math.max(count, math.floor(count * swarmMul + .5))
        for _ = 1, scaledCount do
            local a = love.math.random() * math.pi * 2
            local r = 480 + love.math.random() * 180
            self:spawnEnemy(kind, game.player.x + math.cos(a) * r, game.player.y + math.sin(a) * r)
        end
    end
    game:setNotice("적이 몰려온다!", "ore")
end

-- 뱀서라이크식 "시간이 지나면 화면이 적으로 가득 찬다" 압박: 파괴율과 무관하게 계속 스폰
function ClearcutMode:updateTimeSpawner(dt, game)
    self.timeSpawnTimer = self.timeSpawnTimer - dt
    if self.timeSpawnTimer > 0 then return end
    local curse = self:curseLevel()
    local berserkMul = self:berserkMultiplier()
    self.timeSpawnTimer = math.max(.5, (6.5 - curse * 1.1) / berserkMul)
    local count = math.floor((1 + curse * 1.4) * berserkMul)
    local pool = {"squirrel", "squirrel", "boar"}
    for _ = 1, count do
        local kind = pool[love.math.random(#pool)]
        local a = love.math.random() * math.pi * 2
        local r = 520 + love.math.random() * 200
        self:spawnEnemy(kind, game.player.x + math.cos(a) * r, game.player.y + math.sin(a) * r)
    end
end

-- 정기 엘리트: 진행도와 무관하게 몇 분마다 훨씬 강한 개체가 등장
function ClearcutMode:updateEliteTimer(dt, game)
    self.eliteTimer = self.eliteTimer - dt
    if self.eliteTimer > 0 then return end
    self.eliteTimer = 200 * (self.eliteIntervalMul or 1)
    local kind = love.math.random() < .5 and "boar" or "squirrel"
    local a = love.math.random() * math.pi * 2
    local e = self:spawnEnemy(kind, game.player.x + math.cos(a) * 520, game.player.y + math.sin(a) * 520, {hpMul = 6, speedMul = 1.15, dmgMul = 1.8, elite = true})
    game:setNotice((e and e.def.name or "적") .. " 정예 개체가 나타났다!", "ore")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .3) end
end

-- 뱀서라이크식 "사신" — 농성 방지용 무한 추격자, 오래 버틸수록 등장
function ClearcutMode:updateReaper(dt, game)
    if self.reaperSpawned or self.elapsed < 600 * (self.reaperDelayMul or 1) then return end
    self.reaperSpawned = true
    local a = love.math.random() * math.pi * 2
    self:spawnEnemy("reaper", game.player.x + math.cos(a) * 700, game.player.y + math.sin(a) * 700)
    game:setNotice("숲의 사신이 깨어났다 — 멈추면 죽는다.", "ore")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .35) end
end

-- 광폭화 라운드: 주기적으로 찾아오는 하드코어 서지 이벤트. 경고 → 광란 → 냉각 3단계로 돌며,
-- 광란 중엔 스폰이 폭증하고 근처에 남아있는 나무들이 직접 뿌리를 뻗어 플레이어를 물어뜯는다.
function ClearcutMode:updateBerserk(dt, game)
    self.berserkTimer = self.berserkTimer - dt
    if self.berserkState == "idle" then
        if self.berserkTimer <= 0 then
            self.berserkState, self.berserkTimer = "warn", 3.4
            game:setNotice("숲의 공기가 달라졌다...", "ore")
            if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .2) end
        end
    elseif self.berserkState == "warn" then
        if self.berserkTimer <= 0 then
            self.berserkCycleCount = self.berserkCycleCount + 1
            local dur = math.min(32, 16 + self.berserkCycleCount * 2.5)
            self.berserkState, self.berserkTimer, self.berserkTreeTimer, self.berserkKillsStart = "active", dur, 0, self.kills
            game:setNotice("광폭화 — 숲 전체가 미쳐 날뛴다!!", "ore")
            if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .55) end
            local a = love.math.random() * math.pi * 2
            self:spawnEnemy(love.math.random() < .5 and "boar" or "squirrel", game.player.x + math.cos(a) * 520, game.player.y + math.sin(a) * 520,
                {hpMul = 6 + self.berserkCycleCount, speedMul = 1.15, dmgMul = 1.8, elite = true})
        end
    elseif self.berserkState == "active" then
        if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + dt * .12) end
        self.berserkTreeTimer = self.berserkTreeTimer - dt
        if self.berserkTreeTimer <= 0 then
            self.berserkTreeTimer = math.max(.45, 1.6 - self.berserkCycleCount * .1)
            self:berserkTreeLash(game)
        end
        if self.berserkTimer <= 0 then
            local killed = math.max(0, self.kills - self.berserkKillsStart)
            local bonus = killed * 4
            if bonus > 0 then self:onWood(bonus, game) end
            game:setNotice(string.format("광폭화가 잦아들었다 — 처치 보너스 목재 +%d", bonus), "food")
            self.berserkState, self.berserkTimer = "cooldown", 1.5
        end
    else -- cooldown
        if self.berserkTimer <= 0 then
            self.berserkState, self.berserkTimer = "idle", math.max(42, 92 - self.berserkCycleCount * 6)
        end
    end
end

-- 광폭화 중엔 근처에 남아있는 나무가 직접 뿌리를 뻗어 공격한다 (일반 재생 가시덩굴보다 훨씬 아픔)
function ClearcutMode:berserkTreeLash(game)
    local candidates = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            if dx*dx + dy*dy < 620*620 then candidates[#candidates+1] = node end
        end
    end
    if #candidates == 0 then return end
    for i = #candidates, 2, -1 do local j = love.math.random(i); candidates[i], candidates[j] = candidates[j], candidates[i] end
    local count = math.min(#candidates, 2 + math.floor(self.berserkCycleCount * .4))
    for i = 1, count do
        local node = candidates[i]
        self.rootHazards[#self.rootHazards+1] = {x = node.x, y = node.y, phase = "warn", timer = .5, radius = 105, berserk = true}
        node.berserkFlash = 1.2
        self.berserkFlashNodes[#self.berserkFlashNodes+1] = node
    end
end

-- 반격한 나무의 붉은 기운을 서서히 꺼뜨린다 (world.lua가 node.berserkFlash를 보고 오라/균열을 그림)
function ClearcutMode:updateBerserkFlashNodes(dt)
    for i = #self.berserkFlashNodes, 1, -1 do
        local node = self.berserkFlashNodes[i]
        node.berserkFlash = (node.berserkFlash or 0) - dt
        if node.berserkFlash <= 0 then
            node.berserkFlash = nil
            table.remove(self.berserkFlashNodes, i)
        end
    end
end

-- 자이라식 소환 식물: 주기적으로 플레이어 주변 땅이 갈라지며 이빨 달린 덩굴괴수가 솟아나 가시를 쏜다.
-- 저주 레벨이 오를수록 더 자주, 더 많이 솟아난다. 진짜 몹으로 스폰되므로 처치하면 보상도 준다.
function ClearcutMode:updateVinePlants(dt, game)
    for i = #self.vineSpawns, 1, -1 do
        local v = self.vineSpawns[i]
        v.timer = v.timer - dt
        if v.timer <= 0 then
            table.remove(self.vineSpawns, i)
            self:spawnEnemy("vineSprout", v.x, v.y, {hpMul = 1 + (self:curseLevel() - 1) * .3})
            for _ = 1, 6 do game.world:addParticle(v.x + love.math.random(-10,10), v.y - love.math.random(0,16), {.38, .26, .14}, true, false) end
            for _ = 1, 5 do game.world:addParticle(v.x + love.math.random(-14,14), v.y - 6 - love.math.random(0,14), {.35, .65, .25}, true, false) end
            if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .15) end
        end
    end
    self.vinePlantTimer = self.vinePlantTimer - dt
    if self.vinePlantTimer > 0 then return end
    local curse = self:curseLevel()
    self.vinePlantTimer = math.max(15, 32 - curse * 2.4)
    local spawnCount = curse > 2.4 and 2 or 1
    for _ = 1, spawnCount do
        local a = love.math.random() * math.pi * 2
        local r = 260 + love.math.random() * 220
        self.vineSpawns[#self.vineSpawns + 1] = {x = game.player.x + math.cos(a) * r, y = game.player.y + math.sin(a) * r, timer = 1.15}
    end
    game:setNotice("땅속에서 무언가 꿈틀거린다...", "ore")
end

-- 자연재해: 화난 자연이 숲 그 자체를 무기로 쓴다. 비(방화 완전 봉쇄)와 지진(회피형 광역 낙석)을 순환시킨다.
function ClearcutMode:updateDisasters(dt, game)
    self.disasterTimer = self.disasterTimer - dt
    if self.disasterState == "idle" then
        if self.disasterTimer <= 0 then
            self.disasterState, self.disasterTimer = "warn", 3.4
            self.disasterType = love.math.random() < .5 and "rain" or "quake"
            game:setNotice(self.disasterType == "rain" and "먹구름이 몰려온다..." or "땅이 울렁이기 시작한다...", "ore")
        end
    elseif self.disasterState == "warn" then
        if self.disasterTimer <= 0 then
            self.disasterState, self.disasterTimer = "active", self.disasterType == "rain" and 16 or 13
            if self.disasterType == "rain" then
                self.rainSuppressFire = true
                self.lightningTimer = 2.5
                for _, node in ipairs(game.world.nodes) do
                    if node.burning then
                        node.burning, node.burnTimer = false, nil
                        for _ = 1, 5 do game.world:addParticle(node.x + love.math.random(-14,14), node.y - 20 - love.math.random(0,18), {.8, .82, .84}, true, false) end
                    end
                end
                game:setNotice("소나기 — 타오르던 불이 전부 꺼진다!", "food")
            else
                self.quakeTickTimer = 0
                game:setNotice("지진 발생 — 흔들리는 땅을 피해라!", "ore")
            end
        end
    elseif self.disasterState == "active" then
        if self.disasterType == "rain" then
            self.lightningTimer = (self.lightningTimer or 4) - dt
            if self.lightningTimer <= 0 then
                self.lightningTimer = 3.5 + love.math.random() * 3.5
                self.lightningFlashAt = love.timer.getTime()
                self.lightningBoltSeed = love.math.random() * 1000
                if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .12) end
            end
        end
        if self.disasterType == "quake" then
            self.quakeTickTimer = (self.quakeTickTimer or 0) - dt
            if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + dt * .3) end
            if self.quakeTickTimer <= 0 then
                self.quakeTickTimer = .8
                local a = love.math.random() * math.pi * 2
                local r = 60 + love.math.random() * 260
                self.bossTelegraphs[#self.bossTelegraphs + 1] = {
                    x = game.player.x + math.cos(a) * r, y = game.player.y + math.sin(a) * r,
                    radius = 72, phase = "warn", timer = .75, damage = 13, quake = true,
                }
            end
        end
        if self.disasterTimer <= 0 then
            self.disasterState, self.disasterTimer = "cooldown", 2
            if self.disasterType == "rain" then
                self.rainSuppressFire = false
                game:setNotice("비가 그쳤다", "food")
            else
                game:setNotice("땅이 다시 잠잠해졌다", "food")
            end
        end
    else
        if self.disasterTimer <= 0 then
            self.disasterState, self.disasterTimer, self.disasterType = "idle", math.max(55, 92 - self:curseLevel() * 3), nil
        end
    end
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
    self.worldTree = self:spawnEnemy("worldtree", game.player.x, game.player.y - 280, {hpMul = self.stageBossHpMul, dmgMul = 1 + (self.stage - 1) * .3})
    game:setNotice("세계수가 깨어났다 — 스테이지 " .. self.stage .. "의 마지막 저항이다!", "ore")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .5) end
end

function ClearcutMode:spawnEnemyProjectile(e, game)
    local dx, dy = game.player.x - e.x, game.player.y - e.y
    local d = math.sqrt(dx*dx + dy*dy)
    if d <= 0 then return end
    self.projectiles[#self.projectiles + 1] = {x = e.x, y = e.y, vx = dx / d * 150, vy = dy / d * 150, life = 3, damage = e.def.damage * (e.dmgMul or 1), color = e.def.color}
end

-- 정예 개체 전용 원거리 공격: 근접전만 하던 몹에게 가시 투사체를 추가로 부여한다
function ClearcutMode:spawnThornProjectile(e, game)
    local dx, dy = game.player.x - e.x, game.player.y - e.y
    local d = math.sqrt(dx*dx + dy*dy)
    if d <= 0 then return end
    self.projectiles[#self.projectiles + 1] = {
        x = e.x, y = e.y, vx = dx / d * 210, vy = dy / d * 210, life = 2.4,
        damage = e.def.damage * (e.dmgMul or 1) * .6, color = {.62, .42, .15}, kind = "thorn",
    }
end

-- 숲의 사신 전용 AI: 평소엔 추격, 가까워지면 멈춰서서 붉게 예열한 뒤 직선으로 돌진한다
function ClearcutMode:updateReaperAI(e, dt, game)
    local dx, dy = game.player.x - e.x, game.player.y - e.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if e.reaperState == "charging" then
        e.moving = false
        e.reaperChargeT = e.reaperChargeT - dt
        if dist > 1 then e.reaperDashDx, e.reaperDashDy = dx / dist, dy / dist end
        if e.reaperChargeT <= 0 then
            e.reaperState, e.reaperDashT = "dashing", .4
        end
        return
    elseif e.reaperState == "dashing" then
        e.moving = true
        e.reaperDashT = e.reaperDashT - dt
        local speed = e.def.speed * (e.speedMul or 1) * 3.2
        e.x, e.y = e.x + (e.reaperDashDx or 0) * speed * dt, e.y + (e.reaperDashDy or 0) * speed * dt
        e.hitTimer = math.max(0, e.hitTimer - dt)
        if dist <= e.def.radius + 26 and e.hitTimer <= 0 then
            e.hitTimer = .5
            self:damagePlayer(e.def.damage * (e.dmgMul or 1) * 1.6, game)
        end
        if e.reaperDashT <= 0 then e.reaperState, e.reaperTimer = "idle", 4 end
        return
    end
    e.reaperTimer = (e.reaperTimer or 4) - dt
    if dist > e.def.radius + 20 then
        local speed = e.def.speed * (e.speedMul or 1)
        e.x, e.y = e.x + dx / dist * speed * dt, e.y + dy / dist * speed * dt
        e.moving = true
    else
        e.moving = false
        if e.hitTimer <= 0 then
            e.hitTimer = e.def.hitCooldown
            self:damagePlayer(e.def.damage * (e.dmgMul or 1), game)
        end
    end
    if e.reaperTimer <= 0 and dist < 520 then
        e.reaperState, e.reaperChargeT = "charging", .6
        if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .15) end
    end
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
    self.bossTelegraphs[#self.bossTelegraphs + 1] = {x = e.x, y = e.y, radius = e.def.slamRadius, phase = "warn", timer = .75, damage = e.def.slamDamage * (e.dmgMul or 1)}
end

-- 세계수 전용 패턴 1: 플레이어 주변에 여러 지점 동시 예열 후 뿌리가 솟구침 (제자리 회피만으론 못 피함)
function ClearcutMode:worldTreeRootSpikes(e, game)
    local count = e.enraged and 6 or 4
    local dmg = 14 * (e.dmgMul or 1)
    for i = 1, count do
        local a = (i / count) * math.pi * 2 + love.math.random() * .6
        local r = 70 + love.math.random() * 190
        self.bossTelegraphs[#self.bossTelegraphs + 1] = {
            x = game.player.x + math.cos(a) * r, y = game.player.y + math.sin(a) * r,
            radius = 48, phase = "warn", timer = .8, damage = dmg,
        }
    end
    game:setNotice("뿌리가 솟구친다!", "ore")
end

-- 세계수 전용 패턴 2: 플레이어 방향으로 긴 직선 채찍 — 옆으로 피해야 하는 지향성 공격
function ClearcutMode:worldTreeVineWhip(e, game)
    local dx, dy = game.player.x - e.x, game.player.y - e.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist <= 0 then return end
    local nx, ny = dx / dist, dy / dist
    local reach = 420
    self.bossTelegraphs[#self.bossTelegraphs + 1] = {
        kind = "line", x1 = e.x, y1 = e.y, x2 = e.x + nx * reach, y2 = e.y + ny * reach,
        halfWidth = 46, phase = "warn", timer = .65, damage = 16 * (e.dmgMul or 1),
    }
    game:setNotice("덩굴 채찍이 날아온다!", "ore")
end

-- 세계수 종합 AI: 기존 슬램·소환에 더해 뿌리 폭발/덩굴 채찍을 번갈아 쓰고, 체력 35% 이하부터는 격노해서 더 자주 공격한다
function ClearcutMode:updateWorldTreeAI(e, dt, game)
    e.rootSpikeTimer = (e.rootSpikeTimer or 3) - dt
    e.vineWhipTimer = (e.vineWhipTimer or 5.5) - dt
    e.enraged = e.hp <= e.maxHp * .35
    if e.enraged and not e.enrageAnnounced then
        e.enrageAnnounced = true
        game:setNotice("세계수가 격노한다 — 뿌리와 덩굴이 미쳐 날뛴다!", "ore")
        if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .4) end
    end
    if e.rootSpikeTimer <= 0 then
        e.rootSpikeTimer = e.enraged and 2.6 or 4.2
        self:worldTreeRootSpikes(e, game)
    end
    if e.vineWhipTimer <= 0 then
        e.vineWhipTimer = e.enraged and 3.4 or 5.5
        self:worldTreeVineWhip(e, game)
    end
end

function ClearcutMode:updateBossTelegraphs(dt, game)
    for i = #self.bossTelegraphs, 1, -1 do
        local t = self.bossTelegraphs[i]
        t.timer = t.timer - dt
        if t.phase == "warn" and t.timer <= 0 then
            t.phase, t.timer = "active", .25
            local hit
            if t.kind == "line" then
                local ex, ey = t.x2 - t.x1, t.y2 - t.y1
                local len2 = ex * ex + ey * ey
                local rx, ry = game.player.x - t.x1, game.player.y - t.y1
                local proj = len2 > 0 and math.max(0, math.min(1, (rx * ex + ry * ey) / len2)) or 0
                local nx, ny = t.x1 + ex * proj, t.y1 + ey * proj
                local ddx, ddy = game.player.x - nx, game.player.y - ny
                hit = ddx * ddx + ddy * ddy <= (t.halfWidth or 40) ^ 2
            else
                local dx, dy = game.player.x - t.x, game.player.y - t.y
                hit = dx * dx + dy * dy <= t.radius * t.radius
            end
            if hit then self:damagePlayer(t.damage, game) end
            if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .4) end
            if t.quake then
                for i = 1, 10 do
                    local a = love.math.random() * math.pi * 2
                    local r = love.math.random() * (t.radius or 60) * .6
                    game.world:addParticle(t.x + math.cos(a) * r, t.y + math.sin(a) * r * .5, {.42, .32, .16}, true, false)
                end
            end
        elseif t.phase == "active" and t.timer <= 0 then
            table.remove(self.bossTelegraphs, i)
        end
    end
end

function ClearcutMode:onEnemyDefeated(e, game)
    self.kills = self.kills + 1
    if e.def.reward and e.def.reward > 0 then self:onWood(e.def.reward, game) end
    if e == self.worldTree then
        game:setNotice("스테이지 " .. self.stage .. " 클리어 — 세계수를 쓰러뜨렸다!", "food")
        self:advanceStage(game)
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
    self.specialCard = nil
    game.mode = "clearcut_upgrade"
    game:setNotice("보물상자 — 전직 전용 스킬을 하나 고르세요!", "food")
end

function ClearcutMode:updateEnemies(dt, game)
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        local def = e.def
        e.hitTimer = math.max(0, e.hitTimer - dt)
        if e.kind == "reaper" then
            self:updateReaperAI(e, dt, game)
        elseif def.ranged then
            local dx, dy = game.player.x - e.x, game.player.y - e.y
            local dist = math.sqrt(dx*dx + dy*dy)
            e.fireTimer = e.fireTimer - dt
            if dist <= def.range and e.fireTimer <= 0 then
                e.fireTimer = def.fireInterval
                if def.thornAttack then self:spawnThornProjectile(e, game) else self:spawnEnemyProjectile(e, game) end
            end
        elseif def.speed > 0 or not def.boss then
            local dx, dy = game.player.x - e.x, game.player.y - e.y
            local dist = math.sqrt(dx*dx + dy*dy)
            local speed = def.speed * (e.speedMul or 1)
            if dist > def.radius + 20 then
                e.x, e.y = e.x + dx / dist * speed * dt, e.y + dy / dist * speed * dt
                e.moving = true
            else
                e.moving = false
                if e.hitTimer <= 0 then
                    e.hitTimer = def.hitCooldown
                    self:damagePlayer(def.damage * (e.dmgMul or 1), game)
                end
            end
        end
        if e.elite then
            e.eliteFireTimer = (e.eliteFireTimer or 2.4) - dt
            if e.eliteFireTimer <= 0 then
                e.eliteFireTimer = 2.6
                self:spawnThornProjectile(e, game)
            end
        end
        if e.kind == "worldtree" then self:updateWorldTreeAI(e, dt, game) end
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
    if self.rainSuppressFire then return end
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
    local _,mouthY,_,tipX=self:smokerMouthPose(game)
    self.molotovs[#self.molotovs+1] = {
        x0=tipX, y0=mouthY, x1=target.x, y1=target.y,
        t=0, dur=math.max(.34, dist/850), target=target
    }
    self:trackMolotovBarrage(game)
end

function ClearcutMode:trackMolotovBarrage(game)
    if self:levelOf("molotov") < 3 then return end
    self.molotovShots = self.molotovShots + 1
    if self.molotovShots % 3 == 0 then
        game:setNotice("줄담배 — 꽁초 투척 만렙 특수효과!", "food")
        for _ = 1, 2 do
            local a = love.math.random() * math.pi * 2
            local r = 60 + love.math.random() * 100
            self:hurlMolotovAt(game.player.x + math.cos(a) * (200 + r), game.player.y + math.sin(a) * (200 + r), game, true)
        end
    end
end

function ClearcutMode:hurlMolotovAt(tx, ty, game, isBarrage)
    local dist = math.sqrt((tx-game.player.x)^2 + (ty-game.player.y)^2)
    local _,mouthY,_,tipX=self:smokerMouthPose(game)
    self.molotovs[#self.molotovs+1] = {
        x0=tipX, y0=mouthY, x1=tx, y1=ty,
        t=0, dur=math.max(.34, dist/850), manual=true, radius=90 + self:levelOf("molotov") * 20
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
            elseif m.target.active and not m.target.burning and not self.rainSuppressFire then
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
    if emberLevel > 0 and not node.emberChained and not self.rainSuppressFire then
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
                game:setNotice("산불경보 발령 — 건조주의보 무시 만렙 특수효과!", "food")
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
    if self.job == "developer" then return self:updateDeveloperAttack(dt, game, heldOverride) end
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
    local maxRange = 320 + self:levelOf("molotov") * 40
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY, self.aimRadius = tx, ty, 90 + self:levelOf("molotov") * 20
    if not self.smoking then self:startSmoking(game) end
    local smoking = self.smoking
    local pressed = held and not self.smokerHeldLast
    self.smokerHeldLast = held
    game.player.facing = tx < game.player.x and -1 or 1

    if smoking.phase == "reload" then
        smoking.t = math.min(smoking.dur, smoking.t + dt)
        if game.player.setClearcutAction then game.player:setClearcutAction(math.min(.48, (smoking.t / smoking.dur) * .48)) end
        if smoking.t >= smoking.dur then
            smoking.phase, smoking.loaded = "loaded", true
            if game.player.clearClearcutAction then game.player:clearClearcutAction() end
        end
        return false
    end

    if smoking.phase == "loaded" then
        if not pressed then return false end
        smoking.phase, smoking.t, smoking.dur = "flick", 0, math.max(.38, .52 / ((game.tools.axe.speed or 1) * game.player.gather))
        smoking.loaded, smoking.fired, smoking.tx, smoking.ty = false, false, tx, ty
        if game.player.setClearcutAction then game.player:setClearcutAction(.5) end
        return false
    end

    smoking.t = math.min(smoking.dur, smoking.t + dt)
    local progress = smoking.t / smoking.dur
    if game.player.setClearcutAction then game.player:setClearcutAction(.5 + progress * .499) end
    local fired = false
    if not smoking.fired and progress >= .58 then
        smoking.fired = true
        self:hurlMolotovAt(smoking.tx, smoking.ty, game)
        self.actionAudit.cigaretteFlick = self.actionAudit.cigaretteFlick + 1
        fired = true
    end
    if smoking.t >= smoking.dur then self:startSmoking(game) end
    return fired
end

function ClearcutMode:startSmoking(game)
    local speed = (game.tools.axe.speed or 1) * game.player.gather
    self.smoking = {phase="reload",t=0,dur=math.max(.75,1.25/speed),loaded=false,fired=false}
    if game.player.setClearcutAction then game.player:setClearcutAction(0) end
end

-- Mouth anchors inside each 96x192 smoker action cell. The action row moves
-- the head independently from the idle pose, so the cigarette must follow the
-- active cell instead of remaining at the idle world-space offset.
local smokerActionMouthAnchors = {
    {68, 30}, {68, 30}, {68, 31}, {68, 31}, {68, 31}, {68, 31},
}

function ClearcutMode:smokerMouthPose(game)
    local player = game.player
    local facing = player.facing or 1
    local progress = player.clearcutActionProgress
    local sprite = player.clearcutSprite

    if self.smoking and self.smoking.phase == "reload" and progress ~= nil
        and sprite and player.clearcutFrameWidth then
        local frame = math.max(1, math.min(#smokerActionMouthAnchors, math.floor(progress * 6) + 1))
        local anchor = smokerActionMouthAnchors[frame]
        local scale = sprite.scale or .61
        local foot = (sprite.actionFeet or {})[frame] or 190
        local mouthX = player.x + (anchor[1] - player.clearcutFrameWidth / 2) * scale * facing
        local mouthY = player.y + (anchor[2] - foot) * scale
        return mouthX, mouthY, facing, mouthX + 16 * facing
    end

    local mouthX, mouthY = player.x + 8 * facing, player.y - 91
    return mouthX, mouthY, facing, mouthX + 16 * facing
end

function ClearcutMode:updateToxicAttack(dt, game, heldOverride)
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    local maxRange = 260 + self:levelOf("toxic_rain") * 40
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY, self.aimRadius = tx, ty, 90 + self:levelOf("toxic_rain") * 25
    if self.veganAction then
        local action = self.veganAction
        action.t = math.min(action.dur, action.t + dt)
        local progress = action.t / action.dur
        if game.player.setClearcutAction then game.player:setClearcutAction(progress) end
        local bit = false
        if not action.bit and progress >= .55 then
            action.bit = true
            self:applyVeganBite(action.tx, action.ty, game)
            self.actionAudit.veganBite = self.actionAudit.veganBite + 1
            bit = true
        end
        if action.t >= action.dur then
            self.veganAction = nil
            self.attackCooldown = .1
            if game.player.clearClearcutAction then game.player:clearClearcutAction() end
        end
        return bit
    end
    self.attackCooldown = math.max(0, self.attackCooldown - dt)
    if not held or self.attackCooldown > 0 then return false end
    local speed = (game.tools.axe.speed or 1) * game.player.gather
    self.veganAction = {t=0,dur=math.max(.48,.72/speed),tx=tx,ty=ty,bit=false}
    game.player.facing = tx < game.player.x and -1 or 1
    if game.player.setClearcutAction then game.player:setClearcutAction(0) end
    return false
end

function ClearcutMode:applyVeganBite(tx, ty, game)
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
    return true
end

function ClearcutMode:updateDeveloperAttack(dt, game, heldOverride)
    if self.dashing then
        if game.player.setClearcutAction then game.player:setClearcutAction(.62) end
        self:updateDash(dt, game)
        return true
    end
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    self.attackCooldown = math.max(0, self.attackCooldown - dt)
    local maxRange = self:developerDashDistance()
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY = tx, ty
    self.aimRadius = self:developerDashWidth()
    if not held or self.attackCooldown > 0 then return false end
    self:startDash(tx, ty, game)
    return true
end

function ClearcutMode:developerDashDistance()
    return 200 + self:levelOf("pile_driving") * 70
end

function ClearcutMode:developerDashWidth()
    return 55 + self:levelOf("heavy_machinery") * 20
end

function ClearcutMode:startDash(tx, ty, game)
    local dx, dy = tx - game.player.x, ty - game.player.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist < 1 then return end
    local heavyLevel = self:levelOf("heavy_machinery")
    local width = self:developerDashWidth()
    local megaProject = heavyLevel >= 3 and love.math.random() < .2
    if megaProject then width = width * 2.2 end
    self.dashing = {
        dx = dx / dist, dy = dy / dist,
        angle = (math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx)),
        remaining = math.min(dist, self:developerDashDistance()),
        width = width,
        hitSet = {}
    }
    game.player.facing = dx < 0 and -1 or 1
    if game.player.setClearcutAction then game.player:setClearcutAction(.58) end
    game:setNotice(megaProject and "초고층 프로젝트 — 중장비 투입 만렙 특수효과!" or "돌진!", "food")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .2) end
end

function ClearcutMode:updateDash(dt, game)
    local d = self.dashing
    local speed = 720
    local moveDist = math.min(d.remaining, speed * dt)
    local px, py = game.player.x, game.player.y
    game.player.x, game.player.y = game.player.x + d.dx * moveDist, game.player.y + d.dy * moveDist
    self.traitFx:emit("construction_dash",px,py,{angle=d.angle,radius=42,particles=3})
    d.remaining = d.remaining - moveDist
    self.dashTrail[#self.dashTrail + 1] = {x=px,y=py,dx=d.dx,dy=d.dy,angle=d.angle,width=d.width,life=.42,maxLife=.42}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and not d.hitSet[node] then
            local segX, segY = game.player.x - px, game.player.y - py
            local segLen2 = segX*segX + segY*segY
            local proj = segLen2 > 0 and math.max(0, math.min(1, ((node.x-px)*segX + (node.y-py)*segY) / segLen2)) or 0
            local closeX, closeY = px + segX*proj, py + segY*proj
            local ddx, ddy = node.x - closeX, node.y - closeY
            if ddx*ddx + ddy*ddy <= d.width * d.width then
                d.hitSet[node] = true
                node.rushHp = 0
                game.world:impactNode(node, game, true)
                if self:fellTree(node, game) then
                    local siteLevel = self:levelOf("site_clearance")
                    if siteLevel >= 3 or (siteLevel > 0 and love.math.random() < siteLevel * .3) then node.sterile = true end
                end
            end
        end
    end
    self:damageEnemiesInRadius((px + game.player.x) / 2, (py + game.player.y) / 2, d.width + 20, 12, game)
    if d.remaining <= 0 then
        self.dashing = nil
        if game.player.clearClearcutAction then game.player:clearClearcutAction() end
        if self:levelOf("demolition") > 0 then self:demolitionBlast(game.player.x, game.player.y, game) end
        if self.evolutions.newtown then
            local radius = 160
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree then
                    local dx, dy = node.x - game.player.x, node.y - game.player.y
                    if dx*dx + dy*dy <= radius*radius then node.sterile = true end
                end
            end
            self.traitFx:emit("construction_blast",game.player.x,game.player.y,{radius=radius,particles=42,power=1.45})
        end
        local pileLevel = self:levelOf("pile_driving")
        self.attackCooldown = math.max(1, 3.2 - pileLevel * .7)
        if pileLevel >= 3 and love.math.random() < .25 then
            self.attackCooldown = 0
            game:setNotice("기초 공사 완료 — 말뚝 박기 만렙 특수효과!", "food")
        end
    end
end

function ClearcutMode:demolitionBlast(x, y, game)
    local demoLevel = self:levelOf("demolition")
    local radius = 90 + demoLevel * 30
    self.traitFx:emit("construction_blast",x,y,{radius=radius,particles=36,power=1.35})
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .35) end
    self:damageEnemiesInRadius(x, y, radius, 22, game)
    local felled = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - x, node.y - y
            if dx*dx + dy*dy <= radius*radius then
                node.rushHp = 0
                game.world:impactNode(node, game, true)
                if self:fellTree(node, game) then felled[#felled+1] = node end
            end
        end
    end
    if demoLevel >= 3 and #felled > 0 then
        local second = felled[love.math.random(#felled)]
        self:demolitionEcho(second.x, second.y, game)
    end
end

function ClearcutMode:demolitionEcho(x, y, game)
    local radius = 70
    self.traitFx:emit("construction_blast",x,y,{radius=radius,particles=20,power=.9})
    self:damageEnemiesInRadius(x, y, radius, 14, game)
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - x, node.y - y
            if dx*dx + dy*dy <= radius*radius then
                node.rushHp = 0
                game.world:impactNode(node, game, true)
                self:fellTree(node, game)
            end
        end
    end
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
    amount = amount * (self.woodGainMul or 1)
    self.totalWood = self.totalWood + amount
    game.wood = self.totalWood
    local xpMult = 1 + self:levelOf("forced_growth") * .4
    self.xp = self.xp + amount * xpMult
    while self.xp >= self.xpNext do
        self.xp = self.xp - self.xpNext
        self.level, self.pending = self.level + 1, self.pending + 1
        self.xpNext = math.floor(10 + (self.level - 1) * 6.5)
    end
    if self.pending > 0 and game.mode == "playing" and not os.getenv("LAST_HAUL_SELF_TEST") then self:openUpgradeChoices(game) end
end

function ClearcutMode:upgradePool()
    local pool = {}
    for _, def in ipairs(definitions) do
        local jobOk = not def.job or not self.job or def.job == self.job
        if jobOk and not self.banished[def.id] and self:levelOf(def.id) < def.max then pool[#pool+1]=def end
    end
    return pool
end

function ClearcutMode:rollChoices()
    local pool = self:upgradePool()
    for i=#pool,2,-1 do local j=love.math.random(i); pool[i],pool[j]=pool[j],pool[i] end
    self.choices={}
    for i=1,math.min(3,#pool) do self.choices[i]=pool[i] end
end

-- 아직 안 고른 아르카나만 모아 셔플한다. 스테이지 클리어 강제 선택과, 일반 카드 화면의
-- 희귀 4번째 슬롯(스페셜 카드) 둘 다 여기서 뽑는다.
function ClearcutMode:arcanaPool()
    local pool = {}
    for _, def in ipairs(arcanaDefs) do if not self.arcanaPicked[def.id] then pool[#pool+1]=def end end
    return pool
end

function ClearcutMode:rollArcanaChoices()
    local pool = self:arcanaPool()
    for i=#pool,2,-1 do local j=love.math.random(i); pool[i],pool[j]=pool[j],pool[i] end
    self.arcanaChoices={}
    for i=1,math.min(3,#pool) do self.arcanaChoices[i]=pool[i] end
end

function ClearcutMode:rerollCost() return 18 + self.rerollCount * 12 end
function ClearcutMode:banishCost() return 45 end

-- 새 업그레이드 3택 화면을 여는 공용 진입점. 리롤 횟수/배니시 무장 상태를 초기화하고,
-- 아주 낮은 확률로 뒷면에서 앞면으로 뒤집히며 등장하는 4번째 스페셜(아르카나) 카드를 끼워 넣는다.
function ClearcutMode:openUpgradeChoices(game)
    self.rerollCount, self.banishArmed, self.selectionKind = 0, false, "upgrade"
    self:rollChoices()
    self.specialCard = nil
    if love.math.random() < .12 and #self:arcanaPool() > 0 then
        local pool = self:arcanaPool()
        self.specialCard = pool[love.math.random(#pool)]
        self.specialCardRevealAt = love.timer.getTime()
    end
    game.mode = "clearcut_upgrade"
end

function ClearcutMode:rerollChoice(game)
    if self.selectionKind ~= "upgrade" or self.chestPending then return false end
    local cost = self:rerollCost()
    if self.totalWood < cost then game:setNotice("목재가 부족합니다", "ore"); return false end
    self.totalWood = self.totalWood - cost
    self.rerollCount = self.rerollCount + 1
    self.banishArmed = false
    self:rollChoices()
    return true
end

function ClearcutMode:toggleBanishArm(game)
    if self.selectionKind ~= "upgrade" or self.chestPending then return false end
    if not self.banishArmed then
        local cost = self:banishCost()
        if self.totalWood < cost then game:setNotice("목재가 부족합니다", "ore"); return false end
    end
    self.banishArmed = not self.banishArmed
    return true
end

-- 배니시로 빠진 슬롯 하나만 다시 채운다 (나머지 두 장은 그대로 유지)
function ClearcutMode:refillChoice(index)
    local used = {}
    for i, def in ipairs(self.choices) do if i ~= index and def then used[def.id] = true end end
    local pool = {}
    for _, def in ipairs(self:upgradePool()) do if not used[def.id] then pool[#pool+1] = def end end
    self.choices[index] = #pool > 0 and pool[love.math.random(#pool)] or nil
end

function ClearcutMode:chooseArcana(index, game)
    local def = self.arcanaChoices[index]
    if not def then return false end
    self.arcanaPicked[def.id] = true
    def.apply(self)
    game:setNotice("아르카나 — " .. def.name .. "! " .. def.desc, "ore")
    self.selectionKind = "upgrade"
    if self.pending > 0 then self:openUpgradeChoices(game) else game.mode = "playing" end
    return true
end

function ClearcutMode:checkEvolutions(game)
    if not self.evolutions.wildfire and self:levelOf("molotov") >= 3 and self:levelOf("oil_drum") >= 3 then
        self.evolutions.wildfire = true
        game:setNotice("융합 스킬 — 산불! 습관성 흡연이 결국 걷잡을 수 없이 번진다.", "ore")
    end
    if not self.evolutions.collapse and self:levelOf("shockwave") >= 3 and self:levelOf("domino") >= 3 then
        self.evolutions.collapse = true
        game:setNotice("융합 스킬 — 벌목 붕괴! 초과근무가 부른 대참사 — 쓰러진 나무가 또 다른 붕괴를 부른다.", "ore")
    end
    if not self.evolutions.deadGround and self:levelOf("herbicide") >= 3 and self:levelOf("root_cutting") >= 3 then
        self.evolutions.deadGround = true
        game:setNotice("융합 스킬 — 죽은 땅! '친환경' 관리의 최종 결과 — 한 번 벤 땅은 다시는 자라지 않는다.", "ore")
    end
    if not self.evolutions.frenzy and self:levelOf("berserker") >= 3 and self:levelOf("shockwave") >= 3 then
        self.evolutions.frenzy = true
        game:setNotice("융합 스킬 — 무한 야근! 콤보가 절정에 달하면 모든 타격이 충격파를 뿜는다.", "ore")
    end
    if not self.evolutions.necrosis and self:levelOf("toxic_rain") >= 3 and self:levelOf("root_cutting") >= 3 then
        self.evolutions.necrosis = true
        game:setNotice("융합 스킬 — 생태계 다이어트! 맹독이 닿은 땅은 그 자리에서 불모지가 된다.", "ore")
    end
    if not self.evolutions.newtown and self:levelOf("heavy_machinery") >= 3 and self:levelOf("site_clearance") >= 3 then
        self.evolutions.newtown = true
        game:setNotice("융합 스킬 — 뉴타운 계획! 돌진이 끝난 자리 주변까지 통째로 불모지가 된다.", "ore")
    end
end

function ClearcutMode:choose(index, game)
    if index == "reroll" then return self:rerollChoice(game) end
    if index == "banish" then return self:toggleBanishArm(game) end
    if index == "special" then
        local def = self.specialCard
        if not def then return false end
        self.arcanaPicked[def.id] = true
        self.specialCard = nil
        def.apply(self)
        game:setNotice("스페셜 카드 — " .. def.name .. "! " .. def.desc, "ore")
        return true
    end
    if self.selectionKind == "arcana" then return self:chooseArcana(index, game) end
    local def=self.choices[index]
    if not def then return false end
    self.chestPending = false
    if self.banishArmed then
        if jobFor[def.id] then game:setNotice("전직 카드는 제외할 수 없습니다", "ore"); return false end
        self.totalWood = self.totalWood - self:banishCost()
        self.banished[def.id] = true
        self.banishArmed = false
        self:refillChoice(index)
        game:setNotice(def.name .. " — 영구 제외", "ore")
        return true
    end
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
    self.specialCard = nil
    if self.pending>0 then self:openUpgradeChoices(game) else game.mode="playing" end
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
    game:setNotice("월급날 — 야근 수당 만렙 특수효과!", "food")
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
    local baseReward = math.floor(self.treesFelled / 5) + self.kills * 2 + math.floor(self.level * 1.5) + (victory and 30 or 0)
    local traitReward = math.max(1, math.floor(baseReward * (self.permanentTraits.reward or 1) + .5))
    if game.characterTraits then game.characterTraits:addCurrency(traitReward) end
    game.result={elapsed=math.floor(self.elapsed),wood=self.totalWood,trees=self.treesFelled,total=self.initialTrees,maxMulti=self.maxMulti,maxChain=self.maxChain,level=self.level,stage=self.stage,regrowPulses=self.regrowPulses,treesRevived=self.treesRevived,rootedCount=self.rootedCount,beeSwarms=self.beeSwarmsTriggered,victory=victory,kills=self.kills,traitEarned=traitReward,traitCurrency=game.characterTraits and game.characterTraits.data.currency or traitReward}
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
    love.graphics.setColor(0, 0, 0, .24); love.graphics.ellipse("fill", x + 2, hy + 21, 15, 5)
    local layers = {{0, 11, 14, 7.5}, {0, 2.5, 11.8, 6.8}, {0, -5.5, 9, 6}, {0, -12.5, 6, 5}, {0, -18.5, 3.6, 3.4}}
    for i, l in ipairs(layers) do
        local lx, ly, rx, ry = x + l[1], hy + l[2], l[3], l[4]
        local shade = 1 - (i - 1) * .045
        love.graphics.setColor(.6 * shade, .42 * shade, .17 * shade, 1)
        love.graphics.ellipse("fill", lx, ly, rx, ry)
        love.graphics.setColor(1, .87, .56, .32)
        love.graphics.ellipse("fill", lx - rx * .3, ly - ry * .42, rx * .55, ry * .4)
        love.graphics.setColor(.26, .15, .05, .32)
        love.graphics.ellipse("fill", lx + rx * .32, ly + ry * .4, rx * .5, ry * .38)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(.32, .2, .07, .55); love.graphics.ellipse("line", lx, ly, rx, ry)
        love.graphics.setColor(.32, .2, .07, .3); love.graphics.ellipse("line", lx, ly - ry * .35, rx * .82, ry * .55)
    end
    love.graphics.setColor(.08, .04, .015, 1); love.graphics.ellipse("fill", x, hy + 11.5, 3.6, 2.3)
    love.graphics.setColor(0, 0, 0, .4); love.graphics.ellipse("fill", x - .5, hy + 11.8, 2.4, 1.4)
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

local function drawFacingPixelGrid(rows, palette, cx, cy, px, facing)
    local gh, gw = #rows, #rows[1]
    local ox, oy = gw * px / 2, gh * px / 2
    for ry=1,gh do
        local row=rows[ry]
        for rx=1,gw do
            local sourceX=facing<0 and (gw-rx+1) or rx
            local col=palette[row:sub(sourceX,sourceX)]
            if col then
                love.graphics.setColor(col)
                love.graphics.rectangle("fill",math.floor(cx-ox+(rx-1)*px),math.floor(cy-oy+(ry-1)*px),px+1,px+1)
            end
        end
    end
end

local function darkenPalette(base, mul, alphaMul)
    local out = {}
    for k, c in pairs(base) do out[k] = {c[1] * mul, c[2] * mul, c[3] * mul, c[4] * (alphaMul or 1)} end
    return out
end

-- 나무는 고해상도로 미리 그려둔 채색 이미지를 축소해서 쓰기 때문에 매끈한데, 몹은 셀 10~20개짜리
-- 픽셀 그리드를 그대로 확대해서 각진 사각형이 그대로 드러났다. 그래서 몹도 한 번만 캔버스에 구워두고
-- (linear 필터로) 그 캔버스를 늘려서 그린다 — 셀 경계가 매끄럽게 보간되어 "칠해진 그림"에 가까워진다.
local spriteCanvasCache = setmetatable({}, {__mode = "k"})
local eliteSpriteCache = setmetatable({}, {__mode = "k"})
local SPRITE_BAKE_PX = 22

-- linear 필터만으로는 축소할 때(멀리서 작게 그릴 때) 제대로 블러가 안 걸려서 각짐이 남는다.
-- 밉맵을 구워두면 축소 시 실제로 다운샘플된 블러 레벨을 골라 쓰기 때문에 훨씬 매끈해진다.
local function finalizeSpriteCanvas(canvas)
    canvas:setFilter("linear", "linear")
    canvas:setMipmapFilter("linear")
    canvas:generateMipmaps()
    return canvas
end

local function bakeSpriteCanvas(rows, palette, outline)
    local gw, gh = #rows[1], #rows
    local w, h = gw * SPRITE_BAKE_PX, gh * SPRITE_BAKE_PX
    local canvasW, canvasH = math.ceil(w * 1.3), math.ceil(h * 1.3)
    local canvas = love.graphics.newCanvas(canvasW, canvasH, {mipmaps = "manual"})
    local prevCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas({canvas, stencil = true})
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.push()
    love.graphics.origin()
    local cx, cy = canvasW / 2, canvasH / 2
    drawPixelGrid(rows, outline or darkenPalette(palette, .22, .88), cx, cy, SPRITE_BAKE_PX * 1.08)
    drawPixelGrid(rows, palette, cx, cy, SPRITE_BAKE_PX)
    love.graphics.stencil(function() drawPixelGrid(rows, palette, cx, cy, SPRITE_BAKE_PX) end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.setColor(1, 1, 1, .11)
    love.graphics.ellipse("fill", cx - w * .18, cy - h * .28, w * .38, h * .32)
    love.graphics.setColor(0, 0, 0, .13)
    love.graphics.ellipse("fill", cx + w * .16, cy + h * .22, w * .34, h * .3)
    love.graphics.setStencilTest()
    love.graphics.pop()
    love.graphics.setCanvas(prevCanvas)
    return finalizeSpriteCanvas(canvas)
end

local function eliteTintPalette(base)
    local out = {}
    for k, c in pairs(base) do
        local lum = (c[1] + c[2] + c[3]) / 3
        out[k] = {math.min(1, lum * .3 + .55), math.min(1, lum * .12 + .05), math.min(1, lum * .55 + .2), c[4]}
    end
    return out
end

-- 정예 틴트는 매 프레임 새 테이블을 만들지 않도록 원본 스프라이트 기준으로 한 번만 계산해 캐싱한다
local function getEliteSprite(sprite)
    local cached = eliteSpriteCache[sprite]
    if cached then return cached end
    local tinted = eliteTintPalette(sprite.palette)
    cached = {rows = sprite.rows, palette = tinted, outline = darkenPalette(tinted, .08)}
    eliteSpriteCache[sprite] = cached
    return cached
end

local function drawShadedSprite(sprite, cx, cy, px)
    local canvas = spriteCanvasCache[sprite]
    if not canvas then
        canvas = sprite.customBake and sprite.customBake(sprite.rows) or bakeSpriteCanvas(sprite.rows, sprite.palette, sprite.outline)
        spriteCanvasCache[sprite] = canvas
    end
    local scale = px / SPRITE_BAKE_PX
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, cx, cy, 0, scale, scale, canvas:getWidth() / 2, canvas:getHeight() / 2)
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

-- 세계수: 원형 그라데이션 밴딩(중심부일수록 밝게)으로 캐노피 음영을 넣고, 줄기는 짙은/중간/밝은 나무결 3톤 + 황금빛 눈으로 마무리
local worldTreeRows = {
    "........ODO........",
    ".....ODGGHGGDO.....",
    "...ODGGGHHHGGGDO...",
    "..ODGGGGHHHGGGGDO..",
    ".ODGGGGHHWHHGGGGDO.",
    ".ODGGGGHHWHHGGGGDO.",
    ".ODGGGGHHWHHGGGGDO.",
    "..ODGGGGHHHGGGGDO..",
    "....ODGGHHHGGDO....",
    "......ODGHGDO......",
    ".....OKBBLBBKO.....",
    ".....OKBYLYBKO.....",
    ".....OKBYLYBKO.....",
    "......OKBLBKO......",
    "......OKBLBKO......",
    "....OKBBBLBBBKO....",
    "...OKBBBBLBBBBKO...",
    "..OKBBBBBLBBBBBKO..",
}
local worldTreePalette = {
    O={.05,.03,.02,1}, D={.1,.24,.09,1}, G={.18,.4,.16,1}, H={.36,.62,.28,1}, W={.55,.82,.4,1},
    K={.16,.1,.05,1}, B={.32,.2,.1,1}, L={.5,.36,.2,1}, Y={1,.92,.5,1},
}

-- 숲의 사신: 짐승이 아니라 두건 쓴 망령 실루엣 — 낫을 든 도끼 사냥꾼 컨셉
local reaperRows = {
    "....OOO....",
    "...OGGGO...",
    "..OGRRRGO..",
    "..OGGGGGO..",
    ".OOGGGGGOO.",
    "OBBBBBBBBBO",
    "OBBBBBBBBBO",
    "OBBBBBBBBBO",
    "OBBBBBBBBBO",
    ".OBBBBBBBO.",
    ".OB.BOB.BO.",
    "OO.O.O.O.OO",
}
local reaperPalette = {O={.03,.02,.02,1}, G={.12,.14,.1,1}, R={1,.15,.1,1}, B={.1,.06,.12,1}}

-- 식충 덩굴괴수: 자이라식 소환 식물 — 이빨 달린 붉은 아가리 봉오리(발광 코어 포함) + 가시 돋친 덩굴 줄기/뿌리.
-- 나무 이미지와의 해상도 격차(캐릭터가 20x18칸짜리 픽셀 격자를 그대로 확대해 각져 보이던 문제)를 줄이려고
-- 31x34칸으로 다시 그렸다 — 캔버스 굽기+linear 필터링과 합쳐지면 매끄러운 그라데이션으로 보인다.
local vineSproutRows = {
    ".............DDGDD.............",
    "...........DDGGRGGDD...........",
    ".........DDGGRRRRRGGDD.........",
    ".......DDGGRRRRRRRRRGGDD.......",
    ".....DDGGRRRRRRRRRRRRRGGDD.....",
    "....DDGGRRRRRRRRRRRRRRRGGDD....",
    "...DDGGRRRRRRRRRRRRRRRRRGGDD...",
    "..DDGGRRRRRRRRRRRRRRRRRRRGGDD..",
    ".DDGGRRRRRRRRRRRRRRRRRRRRRGGDD.",
    "DDGGRRRRRRRWWWWWWWWWRRRRRRRGGDD",
    "DDGGRRRRRRRWWWWWWWWWRRRRRRRGGDD",
    "DDGGRRRRRRRWWWWWWWWWRRRRRRRGGDD",
    ".DDGGRRRRRRRRRRRRRRRRRRRRRGGDD.",
    "..DDGGRRRRRRRRRRRRRRRRRRRGGDD..",
    "...DDGGRRRRRRRRRRRRRRRRRGGDD...",
    ".....DDGGRRRRRRRRRRRRRGGDD.....",
    ".......DDGGRRRRRRRRRGGDD.......",
    ".........DDGGRRRRRGGDD.........",
    "...........DDGGRGGDD...........",
    ".............KBLBK.............",
    ".............KBLBK.............",
    ".............KBLBK.............",
    "............KKBLBKK............",
    "............KKBLBKK............",
    "............KKBLBKK............",
    "...........KKBBLBBKK...........",
    "...........KKBBLBBKK...........",
    "...........KKBBLBBKK...........",
    "..........KKKBBLBBKKK..........",
    "..........KKKBBLBBKKK..........",
    ".........KKKBBBLBBBKKK.........",
    "........KKKKBBBLBBBKKKK........",
    ".......KKKKBBBBLBBBBKKKK.......",
    "......KKKKKBBBBLBBBBKKKKK......",
}
-- 배경의 가을숲 채색과 어울리도록 네온 핑크 대신 흙빛이 도는 브릭레드/올리브 톤으로 눌렀다
local vineSproutPalette = {
    D={.09,.16,.07,1}, G={.2,.3,.14,1}, R={.5,.19,.15,1}, W={.82,.52,.32,1}, S={.06,.11,.05,1},
    K={.11,.15,.08,1}, B={.2,.26,.13,1}, L={.3,.38,.19,1},
}

-- 덩굴괴수는 칸마다 고정된 팔레트 색 하나를 칠하는 대신, 칸 위치에서 연속적인 그라데이션 색을
-- 직접 계산해서 픽셀 단위로 찍는다 — 몇 개짜리 단색 밴드가 아니라 진짜 연속된 음영이 나오고,
-- 아주 옅은 노이즈까지 섞어서 평평한 디지털 그라데이션 티가 안 나게 한다.
local function lerp3(a, b, t) return a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t end

local function bakeVineSproutCanvas(rows)
    local gw, gh = #rows[1], #rows
    local headRows = 19
    local px = SPRITE_BAKE_PX
    local SUBDIV = 4
    local subPx = px / SUBDIV
    local w, h = gw * px, gh * px
    local canvasW, canvasH = math.ceil(w * 1.22), math.ceil(h * 1.12)
    local canvas = love.graphics.newCanvas(canvasW, canvasH, {mipmaps = "manual"})
    local prevCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas({canvas, stencil = true})
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.push()
    love.graphics.origin()
    local originX, originY = (canvasW - w) / 2, (canvasH - h) / 2
    local headCx, headCy = w / 2, (headRows / 2) * px
    local headRx, headRy = 15.2 * px, 9.4 * px
    local W3, R3, D3 = {.86, .56, .34}, {.5, .19, .15}, {.09, .16, .07}
    local L3, B3, K3 = {.32, .4, .2}, {.2, .26, .13}, {.11, .15, .08}
    local rng = love.math.newRandomGenerator(4242)
    -- 외곽선: 실루엣을 살짝 키워서 어두운 톤으로 먼저 깔아둔다
    local outlinePalette = {}
    for k in pairs(vineSproutPalette) do outlinePalette[k] = {.05, .07, .04, 1} end
    drawPixelGrid(rows, outlinePalette, originX + w / 2, originY + h / 2, px * 1.1)
    for ry = 1, gh do
        local row = rows[ry]
        local first, last
        for rx = 1, gw do
            if row:sub(rx, rx) ~= "." then
                first = first or rx
                last = rx
            end
        end
        if first then
            -- 칸 하나를 4x4(=16칸)로 더 쪼개서, 칸 경계에서 색이 뚝 끊기는 대신
            -- 서브셀 단위 연속 좌표로 그라데이션을 다시 계산한다 — 칸당 단색이 아니라
            -- 칸 "안"에서도 위치에 따라 색이 계속 바뀌게 만드는 게 핵심.
            local midPx = originX + ((first - 1) + (last - first + 1) / 2) * px
            local halfSpanPx = math.max(px, ((last - first + 1) / 2) * px)
            for rx = first, last do
                if row:sub(rx, rx) ~= "." then
                    for syi = 0, SUBDIV - 1 do
                        for sxi = 0, SUBDIV - 1 do
                            local cx = originX + (rx - 1) * px + (sxi + .5) * subPx
                            local cy = originY + (ry - 1) * px + (syi + .5) * subPx
                            local r, g, b
                            if ry <= headRows then
                                local dx, dy = (cx - headCx) / headRx, (cy - headCy) / headRy
                                local dist = math.min(1, math.sqrt(dx * dx + dy * dy))
                                local t = dist ^ 1.25
                                if t < .5 then r, g, b = lerp3(W3, R3, t / .5) else r, g, b = lerp3(R3, D3, (t - .5) / .5) end
                            else
                                local t = math.min(1, math.abs(cx - midPx) / halfSpanPx)
                                if t < .5 then r, g, b = lerp3(L3, B3, t / .5) else r, g, b = lerp3(B3, K3, (t - .5) / .5) end
                                local depth = (ry - headRows) / (gh - headRows) * .12
                                r, g, b = r - depth, g - depth, b - depth
                            end
                            local n = (rng:random() - .5) * .045
                            love.graphics.setColor(math.max(0, r + n), math.max(0, g + n), math.max(0, b + n), 1)
                            love.graphics.rectangle("fill", cx - subPx / 2, cy - subPx / 2, subPx + 1, subPx + 1)
                        end
                    end
                end
            end
        end
    end
    love.graphics.stencil(function() drawPixelGrid(rows, vineSproutPalette, originX + w/2, originY + h/2, px) end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.setColor(1, 1, 1, .1)
    love.graphics.ellipse("fill", originX + w * .32, originY + h * .18, w * .34, h * .22)
    love.graphics.setColor(0, 0, 0, .12)
    love.graphics.ellipse("fill", originX + w * .66, originY + h * .16, w * .3, h * .2)
    love.graphics.setStencilTest()
    love.graphics.pop()
    love.graphics.setCanvas(prevCanvas)
    return finalizeSpriteCanvas(canvas)
end

-- 덩굴괴수 소환 텔레그래프 전용 새싹 스프라이트: 다 자라기 전 미리보기로, 자라날수록 스케일이 커진다
local vineSproutTipRows = {
    "...G...",
    "..GLG..",
    ".GLLLG.",
    "..BLB..",
    "..BLB..",
    "..KBK..",
    "..KBK..",
    ".KKBKK.",
}
local vineSproutTipPalette = {G={.38,.56,.26,1}, L={.3,.38,.19,1}, B={.2,.26,.13,1}, K={.11,.15,.08,1}}

local enemySprites = {
    squirrel = {rows = squirrelRows, palette = squirrelPalette},
    boar = {rows = boarRows, palette = boarPalette},
    turret = {rows = turretRows, palette = turretPalette},
    ent = {rows = entRows, palette = entPalette},
    worldtree = {rows = worldTreeRows, palette = worldTreePalette},
    reaper = {rows = reaperRows, palette = reaperPalette},
    vineSprout = {rows = vineSproutRows, palette = vineSproutPalette, customBake = bakeVineSproutCanvas},
}

local thornRows = {"..O..", ".OYO.", "OYHYO", ".OYO.", "..O.."}
local thornPalette = {O={.15,.08,.04,1}, Y={.62,.42,.15,1}, H={.92,.78,.35,1}}

-- 정예(elite) 개체는 별도 스프라이트를 새로 그리는 대신, 기존 실루엣을 어둡고 채도 높은 "타락" 톤으로 재염색해서 확실히 다르게 보이게 한다
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

-- 캐릭터 아이콘 (로비 선택 카드 + 인게임 소지품 표시에 재사용)
local axeIconRows = {
    "...OO...",
    "..OMMO..",
    ".OMMMMO.",
    "OMMMMOO.",
    "..OHO...",
    "..OHO...",
    "..OHO...",
    "...OO...",
}
local axeIconPalette = {O={.14,.09,.05,1}, M={.82,.85,.88,1}, H={.5,.32,.16,1}}

local cigaretteIconRows = {
    "........",
    "........",
    "........",
    "........",
    "........",
    "WWWWWWFO",
    "........",
    "........",
}
local cigaretteIconPalette = {W={.92,.9,.82,1}, F={1,.55,.15,1}, O={.35,.22,.13,1}}

local cigaretteButtRows = {
    "....AA....",
    "...AHA....",
    "..EHHHE...",
    "..EHHHE...",
    ".EEHHHEE..",
    ".EEEEEEE..",
    "BBBBBBBBB.",
    "BBBBBBBBB.",
    "OBBBBBBBO.",
    "OWWWWWWWO.",
    "OWWWWWWWO.",
    "OWWWWWWWO.",
    "OWWWWWWWO.",
    "OWWWWWWWO.",
    "OWWWWWWWO.",
    "OWWWWWWWO.",
    "OYYYYYYYO.",
    "OYYYYYYYO.",
    "OFFFFFFFO.",
    "OFfFFfFFO.",
    "OFFfFFfFO.",
    "OFfFFFfFO.",
    "OFFFFFFFO.",
    ".OOOOOOO..",
}
local cigaretteButtPalette = {
    A={.68,.66,.62,.85}, H={1,.92,.55,1}, E={1,.42,.12,1}, B={.12,.09,.08,1},
    O={.16,.11,.08,1}, W={.93,.91,.85,1}, Y={.82,.68,.32,1}, F={.78,.55,.28,1}, f={.55,.36,.18,1}
}

function ClearcutMode:drawSmokerCigarette(game)
    if self.job~="fire" or not self.smoking or self.smoking.phase=="flick" then return false end
    local mouthX,mouthY,facing,tipX=self:smokerMouthPose(game)
    drawFacingPixelGrid(cigaretteIconRows,cigaretteIconPalette,(mouthX+tipX)/2,mouthY-2,2,facing)
    return true
end

function ClearcutMode:drawCigaretteProjectiles(t)
    local drawn=0
    for _,m in ipairs(self.molotovs) do
        local p=math.max(0,math.min(1,m.t/m.dur))
        local x=m.x0+(m.x1-m.x0)*p
        local y=m.y0+(m.y1-m.y0)*p-math.sin(p*math.pi)*120
        love.graphics.setColor(.76,.75,.72,.22)
        for i=1,4 do love.graphics.circle("fill",x-(m.x1-m.x0)*.012*i,y-(m.y1-m.y0)*.012*i+i*3,2+i*.8) end
        love.graphics.push(); love.graphics.translate(math.floor(x+.5),math.floor(y+.5)); love.graphics.rotate(p*14)
        local buttPx=1.05
        local emberY=-(#cigaretteButtRows*buttPx/2)+4*buttPx
        local flicker=.72+math.sin((t or 0)*30)*.28
        love.graphics.setColor(.18,.08,.03,.72); love.graphics.rectangle("fill",-4,math.floor(emberY)-4,8,8)
        love.graphics.setColor(1,.42,.08,.9*flicker); love.graphics.rectangle("fill",-3,math.floor(emberY)-3,6,6)
        drawPixelGrid(cigaretteButtRows,cigaretteButtPalette,0,0,buttPx)
        love.graphics.pop()
        drawn=drawn+1
    end
    return drawn
end

local leafIconRows = {
    "...OO...",
    "..OGGO..",
    ".OGGGGO.",
    "OGGGGGGO",
    "OGGGVGGO",
    ".OGGVGO.",
    "..OGVO..",
    "...OO...",
}
local leafIconPalette = {O={.1,.24,.08,1}, G={.32,.65,.2,1}, V={.2,.45,.13,1}}

local hardhatIconRows = {
    "........",
    "..OOOO..",
    ".OYYYYO.",
    "OYYWYYYO",
    "OYYYYYYO",
    "OOOOOOOO",
    "..O..O..",
    "........",
}
local hardhatIconPalette = {O={.25,.17,.02,1}, Y={1,.78,.12,1}, W={1,.96,.72,1}}

-- 업그레이드 카드용 아이콘: 원형/다이아몬드/사각/막대 4가지 실루엣 틀을 색상·세부만 바꿔 재사용한다.
local diamondRows = {
    "....O....",
    "...OHO...",
    "..OHWHO..",
    ".OHWWWHO.",
    "OHWWWWWHO",
    ".OHWWWHO.",
    "..OHWHO..",
    "...OHO...",
    "....O....",
}
local blobRows = {
    "...OOO...",
    "..OHHHO..",
    ".OHWWWHO.",
    "OHWWWWWHO",
    "OHWWWWWHO",
    "OHWWWWWHO",
    ".OHWWWHO.",
    "..OHHHO..",
    "...OOO...",
}
local boxRows = {
    ".OOOOOOO.",
    "OHHHHHHHO",
    "OHWWWWWHO",
    "OHWWWWWHO",
    "OHDDDDDHO",
    "OHWWWWWHO",
    "OHWWWWWHO",
    "OHHHHHHHO",
    ".OOOOOOO.",
}
local stickRows = {
    "....O....",
    "...OHO...",
    "...OHO...",
    "....O....",
    "...OTO...",
    "...OTO...",
    "...OTO...",
    "...OTO...",
    "..OOOOO..",
}

-- 아르카나/스페셜 카드는 새 아이콘을 따로 그리지 않고 기존 도형 실루엣을 재사용해,
-- def.color 하나로 O(외곽)/H(하이라이트)/W·T(본체)/D(그림자) 톤을 즉석에서 만든다.
local arcanaShapeRows = {diamond=diamondRows, blob=blobRows, box=boxRows, stick=stickRows}
local function arcanaIconPalette(c)
    return {
        O={c[1]*.22,c[2]*.22,c[3]*.22,1}, H={math.min(1,c[1]*1.3+.15),math.min(1,c[2]*1.3+.15),math.min(1,c[3]*1.3+.15),1},
        W={c[1],c[2],c[3],1}, T={c[1],c[2],c[3],1}, D={c[1]*.55,c[2]*.55,c[3]*.55,1},
    }
end

local wideBladePalette = {O={.15,.17,.2,1}, H={1,1,1,1}, W={.75,.8,.86,1}}
local berserkerPalette = {O={.28,.08,.04,1}, H={1,.7,.55,1}, W={.85,.42,.3,1}, D={.5,.18,.1,1}}
local shockwavePalette = {O={.4,.28,.02,1}, H={1,.96,.7,1}, W={1,.8,.25,1}}
local dryForestPalette = {O={.3,.08,.02,1}, H={1,.85,.4,1}, W={1,.42,.1,1}}
local demolitionPalette = {O={.3,.05,.02,1}, H={1,.75,.35,1}, W={1,.35,.15,1}}
local oilDrumPalette = {O={.18,.11,.02,1}, H={1,.82,.4,1}, W={.75,.5,.15,1}, D={.4,.24,.05,1}}
local siteClearancePalette = {O={.15,.15,.16,1}, H={.85,.85,.85,1}, W={.55,.5,.5,1}, D={.35,.32,.32,1}}
local herbicidePalette = {O={.2,.1,.28,1}, H={.9,.8,1,1}, T={.6,.4,.85,1}}
local forcedGrowthPalette = {O={.16,.22,.05,1}, H={.85,.95,.6,1}, T={.4,.72,.22,1}}
local pileDrivingPalette = {O={.2,.14,.06,1}, H={.92,.85,.7,1}, T={.55,.4,.2,1}}
local toxicRainPalette = {O={.14,.24,.1,1}, H={.9,.98,.85,1}, W={.6,.85,.5,1}}

local dominoRows = {
    ".OOOOOOO.",
    "OHHHHHHHO",
    "OHWPWPWHO",
    "OHWWWWWHO",
    "OHWPWPWHO",
    "OHWWWWWHO",
    "OHWPWPWHO",
    "OHHHHHHHO",
    ".OOOOOOO.",
}
local dominoPalette = {O={.28,.16,.06,1}, H={.95,.88,.72,1}, W={.88,.78,.58,1}, P={.2,.14,.08,1}}

local rootCuttingRows = {
    "....O....",
    "...OHO...",
    "...OHO...",
    "...OXO...",
    "..BOTOB..",
    "...OTO...",
    "..BOTOB..",
    "...OTO...",
    "..OOOOO..",
}
local rootCuttingPalette = {O={.15,.18,.24,1}, H={.85,.9,.95,1}, T={.55,.62,.72,1}, B={.4,.48,.58,1}, X={1,.3,.25,1}}

local heavyMachineryRows = {
    "...OOO...",
    "..OHHHO..",
    ".OHWTWHO.",
    "OHWTWTWHO",
    "OHWWDWWHO",
    "OHWTWTWHO",
    ".OHWTWHO.",
    "..OHHHO..",
    "...OOO...",
}
local heavyMachineryPalette = {O={.22,.16,.02,1}, H={1,.9,.55,1}, W={.85,.62,.15,1}, T={.6,.42,.08,1}, D={.28,.19,.03,1}}

local embersRows = {
    "O........",
    ".........",
    "....O....",
    ".........",
    "..O......",
    ".........",
    "......O..",
    ".........",
    "O....O...",
}
local embersPalette = {O={1,.7,.25,.95}}

ClearcutMode.icons = {
    axe = {rows = axeIconRows, palette = axeIconPalette},
    cigarette = {rows = cigaretteIconRows, palette = cigaretteIconPalette},
    leaf = {rows = leafIconRows, palette = leafIconPalette},
    hardhat = {rows = hardhatIconRows, palette = hardhatIconPalette},
    wide_blade = {rows = diamondRows, palette = wideBladePalette},
    berserker = {rows = boxRows, palette = berserkerPalette},
    shockwave = {rows = diamondRows, palette = shockwavePalette},
    domino = {rows = dominoRows, palette = dominoPalette},
    dry_forest = {rows = diamondRows, palette = dryForestPalette},
    oil_drum = {rows = boxRows, palette = oilDrumPalette},
    embers = {rows = embersRows, palette = embersPalette},
    herbicide = {rows = stickRows, palette = herbicidePalette},
    root_cutting = {rows = rootCuttingRows, palette = rootCuttingPalette},
    toxic_rain = {rows = blobRows, palette = toxicRainPalette},
    forced_growth = {rows = stickRows, palette = forcedGrowthPalette},
    pile_driving = {rows = stickRows, palette = pileDrivingPalette},
    heavy_machinery = {rows = heavyMachineryRows, palette = heavyMachineryPalette},
    demolition = {rows = diamondRows, palette = demolitionPalette},
    site_clearance = {rows = boxRows, palette = siteClearancePalette},
}
ClearcutMode.drawPixelGrid = drawPixelGrid

local function drawEnemy(e, t)
    local def = e.def
    local walking = def.speed > 0 and (e.moving or false)
    local seed = e.seed or 0
    local bob = walking and math.abs(math.sin(t * 6 + seed)) * def.radius * .05 or (def.boss and math.sin(t * 1.6 + seed) * def.radius * .03 or 0)
    local sprite = enemySprites[e.kind]
    love.graphics.setColor(0, 0, 0, .32)
    love.graphics.ellipse("fill", e.x, e.y + def.radius * .8, def.radius * .95, def.radius * .3)
    if e.elite then
        local pulse = .5 + math.sin(t * 3.5 + seed) * .5
        love.graphics.setColor(1, .78, .2, .25 + pulse * .2)
        love.graphics.circle("fill", e.x, e.y - bob, def.radius * 1.35)
        love.graphics.setLineWidth(2); love.graphics.setColor(1, .84, .3, .8 + pulse * .2)
        love.graphics.circle("line", e.x, e.y - bob, def.radius * 1.35)
    elseif e.kind == "reaper" then
        local charging = e.reaperState == "charging"
        local pulse = .5 + math.sin(t * (charging and 12 or 5) + seed) * .5
        love.graphics.setColor(1, .12, .1, (charging and .55 or .3) + pulse * .18)
        love.graphics.circle("fill", e.x, e.y - bob, def.radius * (charging and 1.9 or 1.5))
        if charging and e.reaperDashDx then
            love.graphics.setLineWidth(3); love.graphics.setColor(1, .2, .12, .5 + pulse * .3)
            love.graphics.line(e.x, e.y - bob, e.x + e.reaperDashDx * 260, e.y - bob + e.reaperDashDy * 260)
        end
    elseif e.kind == "worldtree" and e.enraged then
        local pulse = .5 + math.sin(t * 6 + seed) * .5
        love.graphics.setColor(1, .15, .08, .16 + pulse * .12)
        love.graphics.circle("fill", e.x, e.y - bob - def.radius * .2, def.radius * 1.2)
        for i = 1, 5 do
            local a = i / 5 * math.pi * 2 + t * .6
            local r1, r2 = def.radius * .3, def.radius * (.75 + pulse * .25)
            love.graphics.setLineWidth(2 + pulse); love.graphics.setColor(1, .25, .1, .6 + pulse * .3)
            love.graphics.line(e.x + math.cos(a) * r1, e.y - bob + math.sin(a) * r1 * .6, e.x + math.cos(a) * r2, e.y - bob + math.sin(a) * r2 * .6)
        end
    end
    if sprite then
        local px = (def.radius * 2.1) / #sprite.rows[1]
        local drawSprite = e.elite and getEliteSprite(sprite) or sprite
        drawShadedSprite(drawSprite, e.x, e.y - bob, px)
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

function ClearcutMode:drawDeveloperMachinery(game, t)
    local d, image = self.dashing, game.clearcutMachineryImage
    if not d or not image then return false end
    local imageW, imageH = image:getDimensions()
    local targetWidth = 174 + self:levelOf("heavy_machinery") * 9
    local scale = targetWidth / imageW
    local bounce = math.floor(math.sin((t or 0) * 28) * 1.4)
    love.graphics.push()
    love.graphics.translate(math.floor(game.player.x+.5),math.floor(game.player.y+.5))
    love.graphics.rotate(d.angle or 0)
    love.graphics.setColor(0,0,0,.32)
    love.graphics.ellipse("fill",-7,17,targetWidth*.43,targetWidth*.13)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(image,0,2+bounce,0,scale,scale,imageW/2,imageH/2)
    local beaconX,beaconY=math.floor(-targetWidth*.23),math.floor(-targetWidth*.22)
    love.graphics.setColor(.22,.08,.04,.9); love.graphics.rectangle("fill",beaconX-5,beaconY-5,10,10)
    love.graphics.setColor(1,.24,.08,.65+math.sin((t or 0)*18)*.3); love.graphics.rectangle("fill",beaconX-3,beaconY-3,6,6)
    love.graphics.pop()
    return true
end

function ClearcutMode:drawWorldOverlay(game)
    love.graphics.setLineStyle("rough")
    local t = love.timer.getTime()
    local px, py = game.player.x + 14, game.player.y - 34
    if self.job == "fire" then
        local smoking = self.smoking
        if smoking and smoking.phase ~= "flick" then
            self:drawSmokerCigarette(game)
            local mouthX,mouthY,facing,tipX=self:smokerMouthPose(game)
            local progress=smoking.phase=="loaded" and 1 or math.min(1,smoking.t/smoking.dur)
            local breath=smoking.phase=="loaded" and .58 or (.55+math.sin(progress*math.pi)*.45)
            for i=1,11 do
                local rise=i*6.5
                local drift=math.sin(t*1.65+i*1.17)*(2+i*.82)+facing*i*1.55
                local radius=4.2+i*.7
                local alpha=math.max(.035,(.36-i*.016)*breath)
                -- A darker back-puff gives the pale smoke enough contrast over
                -- both grass and bright tree crowns without becoming opaque.
                love.graphics.setColor(.38,.4,.37,alpha*.44)
                love.graphics.circle("fill",tipX+drift-facing*2,mouthY-rise+2,radius+2.2)
                love.graphics.setColor(.88,.89,.85,alpha)
                love.graphics.circle("fill",tipX+drift,mouthY-rise,radius)
            end
            -- Draw the ember last so smoke never washes it out. Three hard
            -- pixel layers keep it readable against every forest backdrop.
            local emberPulse=.82+math.sin(t*13)*.18
            local ex,ey=math.floor(tipX+.5),math.floor(mouthY+.5)
            love.graphics.setColor(.22,.07,.025,.88)
            love.graphics.rectangle("fill",ex-5,ey-5,10,10)
            love.graphics.setColor(1,.32,.035,.9*emberPulse)
            love.graphics.rectangle("fill",ex-3,ey-3,6,6)
            love.graphics.setColor(1,.88,.32,.96)
            love.graphics.rectangle("fill",ex-1,ey-1,3,3)
        end
    elseif self.job == "toxic" then
        local bob = math.sin(t * 2.4) * 2
        drawPixelGrid(leafIconRows, leafIconPalette, px, py + bob, 2.4)
    elseif self.job == "physical" then
        drawPixelGrid(axeIconRows, axeIconPalette, px, py, 2.2)
    elseif self.job == "developer" then
        drawPixelGrid(hardhatIconRows, hardhatIconPalette, px, py, 2.4)
    end
    if (self.job == "fire" or self.job == "toxic") and self.aimX then
        local ringColor = self.job == "fire" and {1, .5, .15} or {.55, .85, .45}
        love.graphics.setColor(ringColor[1], ringColor[2], ringColor[3], .16); love.graphics.circle("fill", self.aimX, self.aimY, self.aimRadius)
        love.graphics.setLineWidth(2); love.graphics.setColor(ringColor[1], ringColor[2], ringColor[3], .85)
        love.graphics.circle("line", self.aimX, self.aimY, self.aimRadius)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(self.aimX - 10, self.aimY, self.aimX - 4, self.aimY); love.graphics.line(self.aimX + 4, self.aimY, self.aimX + 10, self.aimY)
        love.graphics.line(self.aimX, self.aimY - 10, self.aimX, self.aimY - 4); love.graphics.line(self.aimX, self.aimY + 4, self.aimX, self.aimY + 10)
    elseif self.job == "developer" and self.aimX and not self.dashing then
        local dx, dy = self.aimX - game.player.x, self.aimY - game.player.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 1 then
            local nx, ny = dx / dist, dy / dist
            local perpx, perpy = -ny, nx
            local hw = self.aimRadius
            local bx, by = self.aimX, self.aimY
            local steps = math.max(1, math.floor(dist / 32))
            for i=1,steps do
                local along=math.min(dist,i*32)
                local cx,cy=game.player.x+nx*along,game.player.y+ny*along
                for side=-1,1,2 do
                    local mx,my=math.floor(cx+perpx*hw*side+.5),math.floor(cy+perpy*hw*side+.5)
                    love.graphics.setColor(.16,.12,.07,.72); love.graphics.rectangle("fill",mx-7,my-5,14,10)
                    love.graphics.setColor(.96,.57,.12,.44+(i%2)*.2); love.graphics.rectangle("fill",mx-5,my-3,10,6)
                end
            end
            local ex,ey=math.floor(bx+.5),math.floor(by+.5)
            love.graphics.setColor(.16,.11,.07,.82); love.graphics.rectangle("fill",ex-12,ey-4,24,8); love.graphics.rectangle("fill",ex-4,ey-12,8,24)
            love.graphics.setColor(1,.66,.16,.9); love.graphics.rectangle("fill",ex-9,ey-2,18,4); love.graphics.rectangle("fill",ex-2,ey-9,4,18)
        end
    end
    if self.job == "developer" and #self.dashTrail > 0 then
        for _, tr in ipairs(self.dashTrail) do
            local a = math.max(0, tr.life / tr.maxLife)
            local nx,ny=tr.dx or 1,tr.dy or 0
            local pxn,pyn=-ny,nx
            local trackGap=math.min(34,(tr.width or 55)*.42)
            for side=-1,1,2 do
                local ox,oy=pxn*trackGap*side,pyn*trackGap*side
                love.graphics.push(); love.graphics.translate(math.floor(tr.x+ox+.5),math.floor(tr.y+oy+.5)); love.graphics.rotate(tr.angle or 0)
                love.graphics.setColor(.12,.09,.055,a*.56); love.graphics.rectangle("fill",-25,-6,48,12)
                love.graphics.setColor(.42,.29,.14,a*.34)
                for block=-20,16,9 do love.graphics.rectangle("fill",block,-4,6,8) end
                love.graphics.pop()
            end
        end
    end
    if self.job=="developer" then self:drawDeveloperMachinery(game,t) end
    self.traitFx:draw()
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
        if hazard.berserk then
            if hazard.phase == "warn" then
                local pulse = 1 - math.max(0, hazard.timer) / .5
                love.graphics.setLineWidth(3); love.graphics.setColor(1, .15, .08, .8 - pulse * .3)
                love.graphics.circle("line", hazard.x, hazard.y, hazard.radius * pulse)
                for i = 1, 10 do
                    local ang = i / 10 * math.pi * 2 + t * .5
                    local r0, r1 = hazard.radius * pulse * .3, hazard.radius * pulse * .88
                    love.graphics.setLineWidth(2 + math.sin(t * 9 + i) * .6); love.graphics.setColor(1, .25, .05, .55)
                    love.graphics.line(hazard.x + math.cos(ang) * r0, hazard.y + math.sin(ang) * r0 * .5, hazard.x + math.cos(ang) * r1, hazard.y + math.sin(ang) * r1 * .5)
                end
                love.graphics.setColor(1, .5, .15, .25 + pulse * .18); love.graphics.circle("fill", hazard.x, hazard.y, hazard.radius * pulse * .4)
            else
                local fade = math.max(0, hazard.timer) / 1.1
                love.graphics.setColor(1, .2, .1, fade * .32); love.graphics.circle("fill", hazard.x, hazard.y, hazard.radius * .55)
                for a = 0, 7 do
                    local ang = a / 8 * math.pi * 2
                    local px, py = hazard.x, hazard.y
                    local segs = 5
                    for s = 1, segs do
                        local sr = hazard.radius * .95 * (s / segs)
                        local jag = (s % 2 == 0 and 1 or -1) * 7
                        local nx = hazard.x + math.cos(ang) * sr + math.cos(ang + math.pi / 2) * jag
                        local ny = hazard.y + math.sin(ang) * sr * .5 + math.sin(ang + math.pi / 2) * jag * .5
                        love.graphics.setLineWidth(5.2); love.graphics.setColor(.1, .03, .02, fade * .95)
                        love.graphics.line(px, py, nx, ny)
                        love.graphics.setLineWidth(2.4); love.graphics.setColor(1, .2, .08, fade)
                        love.graphics.line(px, py, nx, ny)
                        if s == segs then
                            love.graphics.setColor(1, .35, .12, fade)
                            love.graphics.polygon("fill", nx, ny - 6, nx - 3.6, ny + 4, nx + 3.6, ny + 4)
                            love.graphics.setColor(.3, .04, .02, fade); love.graphics.setLineWidth(1)
                            love.graphics.polygon("line", nx, ny - 6, nx - 3.6, ny + 4, nx + 3.6, ny + 4)
                        end
                        px, py = nx, ny
                    end
                end
            end
        elseif hazard.phase == "warn" then
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
    self:drawCigaretteProjectiles(t)
    for _, tel in ipairs(self.bossTelegraphs) do
        if tel.kind == "line" then
            if tel.phase == "warn" then
                local pulse = 1 - math.max(0, tel.timer) / .65
                love.graphics.setLineWidth((tel.halfWidth or 40) * 2 * pulse); love.graphics.setColor(1, .3, .15, .3)
                love.graphics.line(tel.x1, tel.y1, tel.x2, tel.y2)
                love.graphics.setLineWidth(4); love.graphics.setColor(1, .4, .2, .85 - pulse * .3)
                love.graphics.line(tel.x1, tel.y1, tel.x2, tel.y2)
            else
                local fade = math.max(0, tel.timer) / .25
                love.graphics.setLineWidth((tel.halfWidth or 40) * 2); love.graphics.setColor(1, .55, .25, fade * .55)
                love.graphics.line(tel.x1, tel.y1, tel.x2, tel.y2)
                love.graphics.setLineWidth(8); love.graphics.setColor(1, .85, .35, fade)
                love.graphics.line(tel.x1, tel.y1, tel.x2, tel.y2)
            end
        elseif tel.quake then
            if tel.phase == "warn" then
                local pulse = 1 - math.max(0, tel.timer) / .75
                love.graphics.setLineWidth(4); love.graphics.setColor(.6, .42, .18, .85 - pulse * .3)
                love.graphics.circle("line", tel.x, tel.y, tel.radius * pulse)
                for i = 1, 6 do
                    local ang = i / 6 * math.pi * 2
                    love.graphics.setLineWidth(2); love.graphics.setColor(.55, .38, .15, .6)
                    love.graphics.line(tel.x, tel.y, tel.x + math.cos(ang) * tel.radius * pulse, tel.y + math.sin(ang) * tel.radius * pulse * .5)
                end
                love.graphics.setColor(.5, .34, .14, .12); love.graphics.circle("fill", tel.x, tel.y, tel.radius * pulse)
            else
                local fade = math.max(0, tel.timer) / .25
                love.graphics.setColor(.42, .3, .12, fade * .55); love.graphics.circle("fill", tel.x, tel.y, tel.radius)
                love.graphics.setLineWidth(6); love.graphics.setColor(.75, .55, .2, fade); love.graphics.circle("line", tel.x, tel.y, tel.radius)
                for i = 1, 8 do
                    local ang = i / 8 * math.pi * 2 + i
                    local dist = tel.radius * (.5 + (i % 3) * .2)
                    love.graphics.setColor(.3, .22, .1, fade * .8)
                    love.graphics.circle("fill", tel.x + math.cos(ang) * dist, tel.y + math.sin(ang) * dist * .5, 3 + (i % 3))
                end
            end
        elseif tel.phase == "warn" then
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
    for _, v in ipairs(self.vineSpawns) do
        local grow = 1 - math.max(0, v.timer) / 1.15
        -- 1단계: 땅이 갈라진다 — 각지고 들쭉날쭉한 균열이 중심에서 뻗어나가며 점점 벌어진다
        local crackSeed = v.seed or (v.x * .13 + v.y * .07)
        v.seed = crackSeed
        love.graphics.setColor(0, 0, 0, .3 + grow * .2)
        love.graphics.ellipse("fill", v.x, v.y + 4, 22 + grow * 12, 8 + grow * 5)
        for i = 1, 7 do
            local baseAng = i / 7 * math.pi * 2 + crackSeed
            local segs = 3
            local px0, py0 = v.x, v.y
            for s = 1, segs do
                local sr = (6 + grow * 30) * (s / segs)
                local jag = math.sin(crackSeed * 3 + i * 2.7 + s * 5.1) * (3 + grow * 4)
                local nx = v.x + math.cos(baseAng) * sr + math.cos(baseAng + math.pi / 2) * jag
                local ny = v.y + math.sin(baseAng) * sr * .55 + math.sin(baseAng + math.pi / 2) * jag * .5
                love.graphics.setLineWidth(3.2 - s * .6); love.graphics.setColor(.06, .05, .03, .8 * (.4 + grow * .6))
                love.graphics.line(px0, py0, nx, ny)
                love.graphics.setLineWidth(1.6 - s * .3); love.graphics.setColor(.42, .68, .3, .5 * grow)
                love.graphics.line(px0, py0, nx, ny)
                px0, py0 = nx, ny
            end
        end
        -- 2단계: 갈라진 틈 사이로 빛이 새어나오며 새싹이 실루엣을 드러낸다
        if grow > .12 then
            local glowT = math.min(1, (grow - .12) / .5)
            love.graphics.setColor(.5, .9, .4, glowT * (.35 + math.sin(t * 10) * .12))
            love.graphics.ellipse("fill", v.x, v.y, 14 * glowT, 6 * glowT)
        end
        if grow > .3 then
            local tipT = math.min(1, (grow - .3) / .7)
            local wobble = math.sin(t * 9 + crackSeed) * (1 - tipT) * 4
            local px = (5 + tipT * 4.2)
            local cx, cy = v.x + wobble, v.y - tipT * 15
            local outline = darkenPalette(vineSproutTipPalette, .1, 1)
            drawPixelGrid(vineSproutTipRows, outline, cx, cy, px * 1.16)
            drawPixelGrid(vineSproutTipRows, vineSproutTipPalette, cx, cy, px)
        end
    end
    for _, e in ipairs(self.enemies) do drawEnemy(e, t) end
    for _, p in ipairs(self.projectiles) do
        if p.kind == "thorn" then
            love.graphics.setColor(1, .7, .3, .28); love.graphics.circle("fill", p.x, p.y, 9)
            love.graphics.push(); love.graphics.translate(p.x, p.y); love.graphics.rotate(t * 12)
            drawPixelGrid(thornRows, thornPalette, 0, 0, 2.6)
            love.graphics.pop()
        else
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], .3); love.graphics.circle("fill", p.x, p.y, 8)
            love.graphics.setColor(p.color); love.graphics.circle("fill", p.x, p.y, 4.5)
            love.graphics.setColor(0, 0, 0, .8); love.graphics.setLineWidth(1); love.graphics.circle("line", p.x, p.y, 4.5)
        end
    end
    if self.invulnTimer > 0 then
        love.graphics.setColor(1, .2, .15, .35); love.graphics.circle("fill", game.player.x, game.player.y - 20, 26)
    end
    love.graphics.setLineStyle("smooth")
end

-- 광폭화 경고/진행 중 화면 전체에 붉은 비네트 + 흩날리는 낙엽 파편으로 위협감을 준다 (상태만으로 계산, 별도 입자 리스트 불필요)
local function drawBerserkOverlay(state, w, h, t)
    if state ~= "warn" and state ~= "active" then return end
    local active = state == "active"
    local pulse = .5 + math.sin(t * (active and 5.5 or 2)) * .5
    local peak = active and (.4 + pulse * .18) or (.16 + pulse * .1)
    local depth = active and 170 or 90
    local steps = 18
    for i = 0, steps do
        local p = i / steps
        local a = peak * (1 - p) ^ 1.6
        local band = depth / steps + 1
        love.graphics.setColor(.5, .03, .02, a)
        love.graphics.rectangle("fill", 0, i * band, w, band)
        love.graphics.rectangle("fill", 0, h - (i + 1) * band, w, band)
        love.graphics.rectangle("fill", i * band, 0, band, h)
        love.graphics.rectangle("fill", w - (i + 1) * band, 0, band, h)
    end
    if active then
        for i = 1, 14 do
            local seed = i * 3.37
            local speed = 90 + (i % 5) * 40
            local x = (t * speed + seed * 220) % (w + 160) - 80
            local y = (h * ((seed * 1.7) % 1)) + math.sin(t * 2 + seed) * 26
            love.graphics.push(); love.graphics.translate(x, y); love.graphics.rotate(t * 3 + seed)
            love.graphics.setColor(.3, .16, .08, .5)
            love.graphics.polygon("fill", -5, 0, 0, -8, 5, 0, 0, 8)
            love.graphics.pop()
        end
    end
end

-- 자연재해 화면 연출: 비는 대각선 빗줄기 + 어두운 청회색 톤, 지진은 흙먼지 파티클 + 갈색 톤
local function drawDisasterOverlay(self, w, h, t)
    local kind, state = self.disasterType, self.disasterState
    if not kind or (state ~= "warn" and state ~= "active") then return end
    local active = state == "active"
    if kind == "rain" then
        -- 하늘에서 짙은 먹구름이 위쪽부터 깔리며 내려온다
        local cloudDepth = active and h * .34 or h * .16
        local steps = 14
        for i = 0, steps do
            local p = i / steps
            local a = (active and .5 or .22) * (1 - p) ^ 1.4
            love.graphics.setColor(.04, .06, .09, a)
            love.graphics.rectangle("fill", 0, p * cloudDepth, w, cloudDepth / steps + 1)
        end
        local pulse = .5 + math.sin(t * 2) * .5
        love.graphics.setColor(.04, .06, .09, active and (.22 + pulse * .05) or (.1 + pulse * .04))
        love.graphics.rectangle("fill", 0, 0, w, h)
        if active then
            -- 빗줄기: 굵기/밝기로 원근감을 준다 (가까운 줄기=굵고 밝음, 먼 줄기=가늘고 흐림)
            for i = 1, 90 do
                local seed = i * 5.7
                local depth = .4 + (i % 5) * .15
                local speed = 760 * depth + (i % 7) * 60
                local x = (t * speed * .32 + seed * 37) % (w + 220) - 110
                local y = (t * speed + seed * 91) % (h + 140) - 70
                love.graphics.setLineWidth(1 + depth * 1.6)
                love.graphics.setColor(.72, .82, .94, (.16 + depth * .22))
                love.graphics.line(x, y, x - 10 * depth, y + 30 * depth)
            end
            -- 빗방울이 땅에 튀는 잔물결
            for i = 1, 16 do
                local seed = i * 11.3
                local cycle = (t * .8 + seed) % 1
                if cycle < .4 then
                    local sx, sy = (seed * 197) % w, (seed * 331) % h
                    local ring = cycle / .4
                    love.graphics.setLineWidth(1.4); love.graphics.setColor(.75, .85, .95, (1 - ring) * .35)
                    love.graphics.ellipse("line", sx, sy, 3 + ring * 9, 1.4 + ring * 3.2)
                end
            end
            -- 번개: 하늘에서 들쭉날쭉한 번개가 내리치고, 화면 전체가 순간적으로 하얗게 번쩍인다
            local flashElapsed = t - (self.lightningFlashAt or -10)
            if flashElapsed >= 0 and flashElapsed < .5 then
                local seed = self.lightningBoltSeed or 0
                local boltA = math.max(0, 1 - flashElapsed / .5)
                if flashElapsed < .12 then
                    love.graphics.setColor(1, 1, 1, (1 - flashElapsed / .12) * .5)
                    love.graphics.rectangle("fill", 0, 0, w, h)
                end
                local bx = w * (.2 + (seed % 100) / 100 * .6)
                local px0, py0 = bx, 0
                love.graphics.setLineWidth(3)
                for s = 1, 7 do
                    local nx = bx + math.sin(seed + s * 2.3) * 50 * (s / 7)
                    local ny = h * .55 * (s / 7)
                    love.graphics.setColor(.85, .9, 1, boltA * .9)
                    love.graphics.line(px0, py0, nx, ny)
                    if s == 4 then
                        local bx2, by2 = nx, ny
                        for s2 = 1, 3 do
                            local nx2 = bx2 + math.sin(seed * 1.7 + s2 * 3.1) * 40
                            local ny2 = by2 + s2 * 22
                            love.graphics.setColor(.85, .9, 1, boltA * .6)
                            love.graphics.line(bx2, by2, nx2, ny2)
                            bx2, by2 = nx2, ny2
                        end
                    end
                    px0, py0 = nx, ny
                end
            end
        end
    elseif kind == "quake" then
        local shakeAmt = active and 1 or .35
        local shake = math.sin(t * 47) * 2 * shakeAmt + math.sin(t * 71) * 1.5 * shakeAmt
        love.graphics.setColor(.16, .11, .05, active and .13 or .06)
        love.graphics.rectangle("fill", shake, shake * .6, w, h)
        -- 화면 가장자리 흙먼지 얼룩(비네트)
        local steps = 10
        for i = 0, steps do
            local p = i / steps
            local a = (active and .32 or .12) * (1 - p) ^ 1.6
            love.graphics.setColor(.32, .24, .12, a)
            love.graphics.rectangle("fill", 0, h - (i + 1) * (60 / steps), w, 60 / steps + 1)
        end
        if active then
            -- 회전하며 떨어지는 돌 파편: 낙하 궤적에 잔상을 남기고, 밝은 테두리로 어두운 숲 배경에서도 확실히 도드라진다
            for i = 1, 16 do
                local seed = i * 4.1
                local fallSpeed = 130 + (i % 5) * 30
                local x = (seed * 173 + math.sin(t * 3 + seed) * 10) % w
                local y = (t * fallSpeed + seed * 210) % (h + 80) - 40
                local size = 5 + (i % 4) * 2.2
                local rot = t * (2 + (i % 3)) + seed
                love.graphics.setLineWidth(size * .7); love.graphics.setColor(.85, .74, .5, .35)
                love.graphics.line(x, y - fallSpeed * .16, x, y - fallSpeed * .3)
                love.graphics.push(); love.graphics.translate(x, y); love.graphics.rotate(rot)
                love.graphics.setColor(0, 0, 0, .45)
                love.graphics.polygon("fill", -size, size * .8, size * .9, size, size * .7, -size * .9)
                love.graphics.polygon("fill", -size * 1.15, size * .95, size * 1.05, size * 1.15, size * .85, -size * 1.05)
                love.graphics.setColor(.44, .33, .17, 1)
                love.graphics.polygon("fill", -size, size * .3, size * .3, -size, size * .9, size * .4, 0, size)
                love.graphics.setColor(.86, .76, .52, .95)
                love.graphics.polygon("line", -size, size * .3, size * .3, -size, size * .9, size * .4, 0, size)
                love.graphics.setColor(1, .95, .8, .55)
                love.graphics.polygon("fill", -size * .5, -size * .1, size * .1, -size * .5, size * .3, -size * .1)
                love.graphics.pop()
            end
            -- 낮게 깔린 흙먼지 안개가 천천히 흐른다
            for i = 1, 6 do
                local seed = i * 7.3
                local x = ((t * 24 + seed * 130) % (w + 300)) - 150
                local y = h - 40 - (i % 3) * 26
                love.graphics.setColor(.4, .32, .18, .1)
                love.graphics.ellipse("fill", x, y, 160, 34)
            end
        end
    end
end

-- 화면 밖 위협 인디케이터: 사신/정예/격노한 세계수처럼 반응이 늦으면 위험한 대상이 화면 밖에 있으면
-- 화면 가장자리에 화살표 + 거리로 방향을 알려준다. 갑자기 튀어나와서 맞기 전에 미리 대비하라는 취지.
local function drawOffscreenIndicators(self, game, fonts, w, h, t)
    local camera = game.camera
    if not camera then return end
    local margin, cx, cy = 44, w / 2, h / 2
    for _, e in ipairs(self.enemies) do
        if e.kind == "reaper" or e.elite or (e.kind == "worldtree" and e.enraged) then
            local sx, sy = cx + (e.x - camera.x) * camera.zoom, cy + (e.y - camera.y) * camera.zoom
            if sx < 0 or sx > w or sy < 0 or sy > h then
                local dx, dy = e.x - camera.x, e.y - camera.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist <= 0 then dist = 1 end
                local nx, ny = dx / dist, dy / dist
                local scaleX = nx ~= 0 and (cx - margin) / math.abs(nx) or math.huge
                local scaleY = ny ~= 0 and (cy - margin) / math.abs(ny) or math.huge
                local scale = math.min(scaleX, scaleY)
                local ix, iy = cx + nx * scale, cy + ny * scale
                local ang = math.atan2 and math.atan2(ny, nx) or math.atan(ny / nx)
                local color = e.kind == "reaper" and {1, .15, .1} or (e.kind == "worldtree" and {1, .35, .1} or {1, .8, .2})
                local pulse = .55 + math.sin(t * 7) * .45
                love.graphics.push(); love.graphics.translate(ix, iy); love.graphics.rotate(ang)
                love.graphics.setColor(color[1], color[2], color[3], .22 + pulse * .16)
                love.graphics.circle("fill", 0, 0, 24)
                love.graphics.setColor(0, 0, 0, .65)
                love.graphics.polygon("fill", 15, 0, -8, -10, -8, 10)
                love.graphics.setColor(color[1], color[2], color[3], .85 + pulse * .15)
                love.graphics.polygon("fill", 13, 0, -6, -8, -6, 8)
                love.graphics.setLineWidth(1); love.graphics.setColor(1, 1, 1, .5)
                love.graphics.polygon("line", 13, 0, -6, -8, -6, 8)
                love.graphics.pop()
                love.graphics.setFont(fonts.small); love.graphics.setColor(1, 1, 1, .9)
                love.graphics.printf(string.format("%d", dist / 10), ix - 24, iy + 18, 48, "center")
            end
        end
    end
end

function ClearcutMode:drawHUD(game,fonts)
    local w,h=love.graphics.getDimensions()
    local t = love.timer.getTime()
    drawBerserkOverlay(self.berserkState, w, h, t)
    drawDisasterOverlay(self, w, h, t)
    drawOffscreenIndicators(self, game, fonts, w, h, t)
    UI.panel(16,16,360,168,{.35,1,.52,1},.94)
    love.graphics.setFont(fonts.big); love.graphics.setColor(1,1,1); love.graphics.print(formatTime(self.elapsed),32,27)
    love.graphics.setFont(fonts.body); love.graphics.setColor(.95,.7,.25); love.graphics.print("STAGE " .. self.stage .. "  ·  " .. (jobNames[self.job] or "벌목꾼"),155,35)
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
    if self.evolutions.frenzy then evoNames[#evoNames+1] = "무한 야근" end
    if self.evolutions.necrosis then evoNames[#evoNames+1] = "생태계 다이어트" end
    if self.evolutions.newtown then evoNames[#evoNames+1] = "뉴타운 계획" end
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

    if self.berserkState == "warn" or self.berserkState == "active" then
        local active = self.berserkState == "active"
        local pulse = .5 + math.sin(t * (active and 6 or 2.4)) * .5
        local bbw = 300
        local bbx = w - 16 - bbw
        love.graphics.setColor(.16 + pulse*.05, .02, .02, .92)
        love.graphics.rectangle("fill", bbx, 16, bbw, 54, 8, 8)
        love.graphics.setColor(1, .28 + pulse*.22, .14, .95)
        love.graphics.rectangle("line", bbx + .5, 16.5, bbw - 1, 53, 8, 8)
        love.graphics.setFont(fonts.body); love.graphics.setColor(1, .93, .82, 1)
        love.graphics.printf(active and "광폭화 진행 중" or "광폭화 임박", bbx, 23, bbw, "center")
        love.graphics.setFont(fonts.small); love.graphics.setColor(1, .78, .68, .92)
        love.graphics.printf(active and string.format("%.0f초만 버텨라", math.max(0,self.berserkTimer)) or "숲이 곧 폭주한다...", bbx, 47, bbw, "center")
    end

    if self.disasterState == "warn" or self.disasterState == "active" then
        local active = self.disasterState == "active"
        local isRain = self.disasterType == "rain"
        local pulse = .5 + math.sin(t * (active and 5 or 2.2)) * .5
        local dbw = 300
        local dbx = w - 16 - dbw
        local dby = (self.berserkState == "warn" or self.berserkState == "active") and 78 or 16
        local baseColor = isRain and {.08, .14, .22} or {.16, .11, .04}
        local accentColor = isRain and {.55, .75, 1} or {.75, .55, .22}
        love.graphics.setColor(baseColor[1] + pulse*.03, baseColor[2] + pulse*.03, baseColor[3] + pulse*.03, .92)
        love.graphics.rectangle("fill", dbx, dby, dbw, 54, 8, 8)
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], .95)
        love.graphics.rectangle("line", dbx + .5, dby + .5, dbw - 1, 53, 8, 8)
        love.graphics.setFont(fonts.body); love.graphics.setColor(1, .95, .9, 1)
        love.graphics.printf(isRain and (active and "소나기 — 방화 봉쇄" or "먹구름 접근") or (active and "지진 발생 중" or "지진 임박"), dbx, dby + 7, dbw, "center")
        love.graphics.setFont(fonts.small); love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], .95)
        local sub = isRain and (active and "불이 붙지 않는다" or "곧 비가 쏟아진다...") or (active and "낙석을 피해 움직여라" or "곧 땅이 흔들린다...")
        love.graphics.printf(sub, dbx, dby + 31, dbw, "center")
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

local function octagonPoints(cx, cy, r, rot)
    local pts = {}
    for i = 0, 7 do
        local a = (i / 8) * math.pi * 2 + (rot or math.pi / 8)
        pts[#pts + 1] = cx + math.cos(a) * r
        pts[#pts + 1] = cy + math.sin(a) * r
    end
    return pts
end

local jobFlavorColors = {physical = {.68, .5, .3, 1}, fire = {1, .42, .14, 1}, toxic = {.45, .82, .35, 1}, developer = {1, .72, .15, 1}}
local universalColor = {.56, .57, .6, 1}

local function drawShadedRivet(cx, cy, color)
    love.graphics.setColor(.05, .04, .03, 1); love.graphics.circle("fill", cx, cy, 3.2)
    love.graphics.setColor(color[1] * .6, color[2] * .6, color[3] * .6, 1); love.graphics.circle("fill", cx, cy, 2.6)
    love.graphics.setColor(1, 1, 1, .55); love.graphics.circle("fill", cx - .7, cy - .7, 1.1)
end

local pixelFlameRowsA = {
    "...O...",
    "..OYO..",
    "..OEO..",
    ".OEHEO.",
    ".OEHEO.",
    "OEEHEEO",
    "OEEHEEO",
    ".OEHEEO",
    "..OOO..",
}
local pixelFlameRowsB = {}
for i, row in ipairs(pixelFlameRowsA) do pixelFlameRowsB[i] = row:reverse() end
local pixelFlamePalette = {O = {.22, .05, .02, 1}, Y = {1, .95, .55, 1}, E = {1, .4, .1, 1}, H = {1, .82, .3, 1}}
local function alphaScaledPalette(base, mul)
    local out = {}
    for k, c in pairs(base) do out[k] = {c[1], c[2], c[3], c[4] * mul} end
    return out
end

-- job별 배경 이펙트: 흡연자=픽셀 불꽃, 비건=나뭇잎, 나무꾼=톱밥, 개발업자=먼지+청사진 격자, 공용=은은한 회색 먼지
local function drawJobFlavorBg(x, y, w, h, job, t)
    if job == "fire" then
        for i = 1, 4 do
            local seed = i * 3.7
            local life = (t * .55 + i * .43) % 1
            local px = x + w * (.16 + (i - 1) * .24) + math.sin(t * 1.6 + seed) * 4
            local py = y + h - 14 - life * (h * .5)
            local flicker = math.floor(t * 9 + seed) % 2 == 0
            local rows = flicker and pixelFlameRowsA or pixelFlameRowsB
            local scale = (2.6 + math.sin(t * 8 + seed) * .5) * (1 - life * .35)
            drawPixelGrid(rows, alphaScaledPalette(pixelFlamePalette, (1 - life) * .85), px, py, scale)
        end
    elseif job == "toxic" then
        for i = 1, 5 do
            local seed = i * 2.3
            local life = (t * .25 + i * .41) % 1
            local px = x + w * (.12 + (i - 1) * .2) + math.sin(t * .8 + seed) * 10
            local py = y + 16 + life * (h - 32)
            love.graphics.push(); love.graphics.translate(px, py); love.graphics.rotate(math.sin(t + seed) * .6)
            love.graphics.setColor(.4, .75, .3, (1 - math.abs(life - .5) * 1.7) * .4)
            love.graphics.ellipse("fill", 0, 0, 7, 3.4)
            love.graphics.pop()
        end
    elseif job == "physical" then
        for i = 1, 5 do
            local seed = i * 4.1
            local life = (t * .7 + i * .31) % 1
            local px = x + w * (.15 + (i - 1) * .18) + math.sin(t * 1.7 + seed) * 5
            local py = y + h * .12 + life * h * .76
            love.graphics.push(); love.graphics.translate(px, py); love.graphics.rotate(t * 3 + seed)
            love.graphics.setColor(.62, .44, .2, (1 - life) * .42)
            love.graphics.rectangle("fill", -4, -2, 8, 4)
            love.graphics.pop()
        end
    elseif job == "developer" then
        love.graphics.setLineWidth(1); love.graphics.setColor(1, .72, .15, .06)
        for gx = 0, w, 26 do love.graphics.line(x + gx, y, x + gx, y + h) end
        for gy = 0, h, 26 do love.graphics.line(x, y + gy, x + w, y + gy) end
        for i = 1, 4 do
            local seed = i * 5.2
            local life = (t * .35 + i * .27) % 1
            local px = x + w * (.2 + (i - 1) * .22)
            local py = y + h - life * h * .55
            love.graphics.setColor(.62, .57, .5, (1 - life) * .3)
            love.graphics.circle("fill", px, py, 4 + life * 6)
        end
    else
        for i = 1, 4 do
            local seed = i * 6.1
            local life = (t * .15 + i * .24) % 1
            local px = x + w * (.15 + (i - 1) * .24) + math.sin(t * .5 + seed) * 8
            local py = y + h * .18 + life * h * .62
            love.graphics.setColor(.62, .62, .64, (1 - math.abs(life - .5) * 2) * .28)
            love.graphics.circle("fill", px, py, 2)
        end
    end
end

local function drawUpgradeCardFrame(x, y, w, h, color, hovered, job, t)
    for i = 3, 1, -1 do
        love.graphics.setColor(color[1], color[2], color[3], .05 * i)
        love.graphics.rectangle("fill", x - i * 4, y - i * 4, w + i * 8, h + i * 8, 14 + i * 3, 14 + i * 3)
    end
    UI.verticalGradient(x, y, w, h, 12, {.045, .04, .038, .99}, {.1, .075, .05, .99}, 64)
    love.graphics.stencil(function() love.graphics.rectangle("fill", x, y, w, h, 12, 12) end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    drawJobFlavorBg(x, y, w, h, job, t)
    love.graphics.setColor(1, 1, 1, .05)
    love.graphics.polygon("fill", x - 20, y, x + w * .38, y, x + w * .1, y + h, x - 60, y + h)
    love.graphics.setStencilTest()
    love.graphics.setLineWidth(1); love.graphics.setColor(1, 1, 1, .09)
    love.graphics.rectangle("line", x, y, w, h, 12, 12)
    love.graphics.setLineWidth(hovered and 3 or 2)
    love.graphics.setColor(color[1], color[2], color[3], hovered and 1 or .68)
    love.graphics.rectangle("line", x + 4, y + 4, w - 8, h - 8, 9, 9)
    love.graphics.setLineWidth(1); love.graphics.setColor(1, 1, 1, .35)
    love.graphics.line(x + 10, y + 4.5, x + w - 10, y + 4.5)
    love.graphics.setColor(0, 0, 0, .35)
    love.graphics.line(x + 10, y + h - 4.5, x + w - 10, y + h - 4.5)
    local corners = {{x + 10, y + 10}, {x + w - 10, y + 10}, {x + 10, y + h - 10}, {x + w - 10, y + h - 10}}
    for _, c in ipairs(corners) do drawShadedRivet(c[1], c[2], color) end
end

local function drawIconSocket(cx, cy, color, iconDef, t, special)
    local r = 58
    local pulse = .5 + math.sin(t * 2.4) * .5
    if special then
        -- 스페셜 카드 전용: 소켓 뒤에서 회전하는 빛줄기 + 궤도를 도는 반짝임으로 확실히 차별화한다
        for i = 1, 8 do
            local ang = i / 8 * math.pi * 2 + t * .7
            local len = r + 26 + math.sin(t * 3 + i) * 6
            love.graphics.setLineWidth(3); love.graphics.setColor(1, .9, .5, .22 + pulse * .12)
            love.graphics.line(cx + math.cos(ang) * r * .5, cy + math.sin(ang) * r * .5, cx + math.cos(ang) * len, cy + math.sin(ang) * len)
        end
        for i = 1, 5 do
            local ang = t * 1.4 + i * (math.pi * 2 / 5)
            local orbit = r + 20
            local sx, sy = cx + math.cos(ang) * orbit, cy + math.sin(ang) * orbit
            local tw = .5 + math.sin(t * 5 + i * 2) * .5
            love.graphics.setColor(1, .95, .7, .5 + tw * .5)
            love.graphics.circle("fill", sx, sy, 1.6 + tw * 1.8)
        end
    end
    for i = 3, 1, -1 do
        love.graphics.setColor(color[1], color[2], color[3], (.14 + pulse * .05) / i)
        love.graphics.circle("fill", cx, cy, r + i * 9)
    end
    love.graphics.setColor(0, 0, 0, .5); love.graphics.circle("fill", cx + 2, cy + 2, r + 2)
    love.graphics.setColor(.035, .04, .05, 1)
    love.graphics.polygon("fill", octagonPoints(cx, cy, r))
    love.graphics.setLineWidth(3); love.graphics.setColor(color[1] * .5, color[2] * .5, color[3] * .5, .9)
    love.graphics.polygon("line", octagonPoints(cx, cy, r + 1))
    love.graphics.setLineWidth(2.4); love.graphics.setColor(color[1], color[2], color[3], .9 + pulse * .1)
    love.graphics.polygon("line", octagonPoints(cx, cy, r))
    love.graphics.setLineWidth(1); love.graphics.setColor(1, 1, 1, .5)
    love.graphics.polygon("line", octagonPoints(cx, cy, r - 4))
    love.graphics.setColor(color[1], color[2], color[3], .95)
    love.graphics.polygon("fill", cx - 7, cy - r - 3, cx + 7, cy - r - 3, cx, cy - r - 14)
    love.graphics.polygon("fill", cx - 7, cy + r + 3, cx + 7, cy + r + 3, cx, cy + r + 14)
    love.graphics.setColor(1, 1, 1, .4)
    love.graphics.polygon("fill", cx - 4, cy - r - 5, cx + 4, cy - r - 5, cx, cy - r - 11)
    if iconDef then
        love.graphics.setColor(0, 0, 0, .32); love.graphics.ellipse("fill", cx + 2, cy + r * .58, 34, 9)
        local px = 96 / #iconDef.rows
        local iw, ih = #iconDef.rows[1] * px, #iconDef.rows * px
        local outline = iconDef.outline or darkenPalette(iconDef.palette, .14, 1)
        drawPixelGrid(iconDef.rows, outline, cx, cy, px * 1.15)
        drawPixelGrid(iconDef.rows, iconDef.palette, cx, cy, px)
        love.graphics.stencil(function() drawPixelGrid(iconDef.rows, iconDef.palette, cx, cy, px) end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        love.graphics.setColor(1, 1, 1, .28)
        love.graphics.ellipse("fill", cx - iw * .16, cy - ih * .26, iw * .34, ih * .28)
        love.graphics.setColor(0, 0, 0, .22)
        love.graphics.ellipse("fill", cx + iw * .15, cy + ih * .22, iw * .3, ih * .26)
        love.graphics.setStencilTest()
    end
end

local arcanaColor = {.72,.4,1,1}
local specialColor = {1,.84,.25,1}

-- 뒷면(물음표+금테)에서 앞면으로 뒤집히며 튀어나오는 스페셜 카드 전용 팝인 애니메이션.
-- x축 스케일을 0 근처까지 접었다가 살짝 오버슈트하며 펼쳐 "카드가 뒤집힌다"는 느낌을 준다.
local function specialCardFlip(elapsed)
    local dur = .42
    local p = math.min(1, elapsed / dur)
    local scaleX
    if p < .55 then
        local q = p / .55
        scaleX = .04 + (1.1 - .04) * (q*q)
    else
        local q = (p - .55) / .45
        scaleX = 1.1 + (1 - 1.1) * q
    end
    return scaleX, p
end

local specialBackFont = nil
local function drawCardBack(x,y,w,h,t)
    local cx, cy = x + w/2, y + h/2
    love.graphics.stencil(function() love.graphics.rectangle("fill",x,y,w,h,14,14) end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.setColor(.1,.07,.17,1); love.graphics.rectangle("fill",x,y,w,h)
    for i = 0, 10 do
        local p = i / 10
        love.graphics.setColor(specialColor[1]*.4, specialColor[2]*.3, specialColor[3]*.5, .1*(1-p))
        love.graphics.circle("fill", cx, cy, (w*.75)*(1-p))
    end
    love.graphics.setStencilTest()
    love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.85); love.graphics.setLineWidth(3)
    love.graphics.rectangle("line",x+6,y+6,w-12,h-12,10,10)
    love.graphics.setLineWidth(1); love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.5)
    love.graphics.rectangle("line",x+12,y+12,w-24,h-24,6,6)
    for _, corner in ipairs({{x+16,y+16,1,1},{x+w-16,y+16,-1,1},{x+16,y+h-16,1,-1},{x+w-16,y+h-16,-1,-1}}) do
        love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.7)
        love.graphics.line(corner[1], corner[2], corner[1]+10*corner[3], corner[2])
        love.graphics.line(corner[1], corner[2], corner[1], corner[2]+10*corner[4])
    end
    local pulse = .5+math.sin(t*6)*.5
    for i = 1, 8 do
        local ang = i/8*math.pi*2 + t*.6
        love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.25+pulse*.15)
        love.graphics.line(cx,cy, cx+math.cos(ang)*(30+pulse*6), cy+math.sin(ang)*(30+pulse*6))
    end
    love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.6+pulse*.3)
    love.graphics.circle("line", cx, cy, 26)
    specialBackFont = specialBackFont or love.graphics.newFont(46)
    love.graphics.setFont(specialBackFont)
    love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.55+pulse*.35)
    love.graphics.printf("?",x,y+h/2-30,w,"center")
end

function ClearcutMode:drawSelection(game,fonts)
    local w,h=love.graphics.getDimensions()
    local t = love.timer.getTime()
    love.graphics.setColor(.015,.035,.025,.84); love.graphics.rectangle("fill",0,0,w,h)
    self.choiceBoxes={}
    if self.selectionKind == "arcana" then
        love.graphics.setFont(fonts.title); love.graphics.setColor(arcanaColor); love.graphics.printf("아르카나 — 룰을 바꾸는 선택",0,66,w,"center")
        love.graphics.setFont(fonts.small); love.graphics.setColor(.85,.78,.95); love.graphics.printf("되돌릴 수 없습니다. 한 번 고르면 이번 판 내내 유지됩니다",0,112,w,"center")
        local gap,cardW,cardH=24,math.min(320,(w-96)/3),360
        local startX=w/2-(cardW*3+gap*2)/2
        local mx,my=love.mouse.getPosition()
        for i,def in ipairs(self.arcanaChoices) do
            local x,y=startX+(i-1)*(cardW+gap),165
            self.choiceBoxes[i]={x=x,y=y,w=cardW,h=cardH}
            local hovered = mx>=x and mx<=x+cardW and my>=y and my<=y+cardH
            drawUpgradeCardFrame(x,y,cardW,cardH,arcanaColor,hovered,nil,t)
            local iconDef = {rows=arcanaShapeRows[def.icon], palette=arcanaIconPalette(def.color)}
            drawIconSocket(x+cardW/2,y+108,arcanaColor,iconDef,t)
            love.graphics.setColor(.06,.09,.08,.92); love.graphics.rectangle("fill",x+16,y+16,34,30,7,7)
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(tostring(i),x+16,y+21,34,"center")
            love.graphics.setFont(fonts.small); love.graphics.setColor(arcanaColor[1],arcanaColor[2],arcanaColor[3],.95); love.graphics.printf("아르카나", x, y+18, cardW, "center")
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,y+195,cardW-32,"center")
            love.graphics.setFont(fonts.body); love.graphics.setColor(.78,.72,.88); love.graphics.printf(def.desc,x+28,y+245,cardW-56,"center")
            love.graphics.setColor(arcanaColor); love.graphics.printf("영구 효과 · 되돌릴 수 없음",x+20,y+320,cardW-40,"center")
        end
        return
    end

    love.graphics.setFont(fonts.title); love.graphics.setColor(1,.82,.3); love.graphics.printf("벌목 방식 진화",0,66,w,"center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.88,.76); love.graphics.printf("계속 움직이고 더 많은 숲을 한 번에 쓸어버리세요",0,112,w,"center")
    local numCards = self.specialCard and 4 or 3
    local gap = 22
    local cardW = math.min(300, (w-96-gap*(numCards-1))/numCards)
    local cardH = 360
    local startX = w/2-(cardW*numCards+gap*(numCards-1))/2
    local mx,my=love.mouse.getPosition()
    for i,def in ipairs(self.choices) do
        local x,y=startX+(i-1)*(cardW+gap),165
        self.choiceBoxes[i]={x=x,y=y,w=cardW,h=cardH}
        local hovered = mx>=x and mx<=x+cardW and my>=y and my<=y+cardH
        local jobColor = jobFlavorColors[def.job] or universalColor
        drawUpgradeCardFrame(x,y,cardW,cardH,jobColor,hovered,def.job,t)
        local iconDef = ClearcutMode.icons[def.id == "molotov" and "cigarette" or def.id]
        drawIconSocket(x+cardW/2,y+108,jobColor,iconDef,t)
        love.graphics.setColor(.06,.09,.08,.92); love.graphics.rectangle("fill",x+16,y+16,34,30,7,7)
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(tostring(i),x+16,y+21,34,"center")
        love.graphics.setFont(fonts.small); love.graphics.setColor(jobColor[1],jobColor[2],jobColor[3],.95); love.graphics.printf(trackLabels[def.track] or "", x, y+18, cardW, "center")
        if self.banishArmed and not jobFor[def.id] then
            love.graphics.setColor(1,.3,.25,.5+math.sin(t*8)*.15); love.graphics.setLineWidth(3)
            love.graphics.rectangle("line",x+3,y+3,cardW-6,cardH-6,12,12)
        end
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,y+195,cardW-32,"center")
        love.graphics.setFont(fonts.body); love.graphics.setColor(.72,.82,.77); love.graphics.printf(def.desc,x+28,y+245,cardW-56,"center")
        love.graphics.setColor(1,.75,.25); love.graphics.printf("Lv."..self:levelOf(def.id).." → Lv."..(self:levelOf(def.id)+1),x+20,y+320,cardW-40,"center")
    end

    if self.specialCard then
        local def = self.specialCard
        local i = 4
        local x,y = startX+(i-1)*(cardW+gap),165
        self.choiceBoxes.special={x=x,y=y,w=cardW,h=cardH}
        local hovered = mx>=x and mx<=x+cardW and my>=y and my<=y+cardH
        local elapsed = t - (self.specialCardRevealAt or t)
        local scaleX, p = specialCardFlip(elapsed)
        local cx = x+cardW/2
        love.graphics.push(); love.graphics.translate(cx,y+cardH/2); love.graphics.scale(scaleX,1); love.graphics.translate(-cx,-(y+cardH/2))
        if scaleX < .5 then
            drawCardBack(x,y,cardW,cardH,t)
        else
            drawUpgradeCardFrame(x,y,cardW,cardH,specialColor,hovered,nil,t)
            local iconDef = {rows=arcanaShapeRows[def.icon], palette=arcanaIconPalette(def.color)}
            drawIconSocket(x+cardW/2,y+108,specialColor,iconDef,t,true)
            love.graphics.setColor(.06,.09,.08,.92); love.graphics.rectangle("fill",x+16,y+16,34,30,7,7)
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf("4",x+16,y+21,34,"center")
            love.graphics.setFont(fonts.small); love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.95); love.graphics.printf("★ 스페셜 카드", x, y+18, cardW, "center")
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,y+195,cardW-32,"center")
            love.graphics.setFont(fonts.body); love.graphics.setColor(.85,.8,.65); love.graphics.printf(def.desc,x+28,y+245,cardW-56,"center")
            love.graphics.setColor(specialColor); love.graphics.printf("영구 효과 · 되돌릴 수 없음",x+20,y+320,cardW-40,"center")
        end
        love.graphics.pop()
        if p >= 1 then
            local glow = .3+math.sin(t*3)*.15
            love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],glow)
            love.graphics.setLineWidth(2); love.graphics.rectangle("line",x-4,y-4,cardW+8,cardH+8,16,16)
            -- 홀로그램 사선 광택이 카드 위를 주기적으로 훑고 지나간다 (포일 카드 느낌)
            love.graphics.stencil(function() love.graphics.rectangle("fill",x,y,cardW,cardH,14,14) end, "replace", 1)
            love.graphics.setStencilTest("greater", 0)
            local sweep = ((t * .5) % 1.6) - .3
            love.graphics.setColor(1, .97, .85, .16)
            love.graphics.polygon("fill", x+cardW*sweep-40,y-10, x+cardW*sweep+10,y-10, x+cardW*sweep-60,y+cardH+10, x+cardW*sweep-110,y+cardH+10)
            love.graphics.setStencilTest()
            for i = 1, 6 do
                local seed = i * 2.7
                local sx = x + (math.sin(t * .9 + seed) * .5 + .5) * cardW
                local sy = y + ((t * .3 + seed * .3) % 1) * cardH
                local tw = .5 + math.sin(t * 6 + seed * 3) * .5
                love.graphics.setColor(1, .95, .7, tw * .8)
                love.graphics.circle("fill", sx, sy, .8 + tw * 1.6)
            end
        end
    end

    if not self.chestPending then
        local btnW,btnH,btnGap=150,44,16
        local by = 165+cardH+26
        local bx = w/2-(btnW*2+btnGap)/2
        self.rerollBox={x=bx,y=by,w=btnW,h=btnH}
        self.banishBox={x=bx+btnW+btnGap,y=by,w=btnW,h=btnH}
        local canReroll = self.totalWood >= self:rerollCost()
        UI.button(bx,by,btnW,btnH,string.format("리롤 (목재 %d)",self:rerollCost()),canReroll,fonts.small)
        local canBanish = self.banishArmed or self.totalWood >= self:banishCost()
        UI.button(bx+btnW+btnGap,by,btnW,btnH,self.banishArmed and "배니시할 카드 선택" or string.format("배니시 (목재 %d)",self:banishCost()),canBanish,fonts.small)
    end
end

function ClearcutMode:choiceAt(x,y)
    if self.selectionKind == "upgrade" and not self.chestPending then
        if self.rerollBox and x>=self.rerollBox.x and x<=self.rerollBox.x+self.rerollBox.w and y>=self.rerollBox.y and y<=self.rerollBox.y+self.rerollBox.h then
            return self.totalWood >= self:rerollCost() and "reroll" or nil
        end
        if self.banishBox and x>=self.banishBox.x and x<=self.banishBox.x+self.banishBox.w and y>=self.banishBox.y and y<=self.banishBox.y+self.banishBox.h then
            return (self.banishArmed or self.totalWood >= self:banishCost()) and "banish" or nil
        end
        if self.choiceBoxes and self.choiceBoxes.special then
            local box = self.choiceBoxes.special
            if x>=box.x and x<=box.x+box.w and y>=box.y and y<=box.y+box.h then return "special" end
        end
    end
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
    local rows={{"도달 스테이지",r.stage or 1},{"걸린 시간",formatTime(r.elapsed)},{"총 목재",r.wood},{"쓰러뜨린 나무",r.trees.." / "..r.total},{"처치한 적",r.kills or 0},{"최대 동시 타격",r.maxMulti},{"최대 연쇄 벌목",r.maxChain},{"도달 레벨",r.level},{"숲 재생 펄스 · 되살아난 나무",r.regrowPulses.."회 · "..r.treesRevived.."그루"},{"가시덩굴에 붙잡힌 횟수",r.rootedCount},{"자극한 벌집",r.beeSwarms}}
    for i,row in ipairs(rows) do local y=h/2-140+(i-1)*38; love.graphics.setColor(i%2==0 and {.07,.12,.1,.9} or {.045,.085,.07,.9}); love.graphics.rectangle("fill",w/2-270,y,540,32,4,4); love.graphics.setColor(.72,.82,.76); love.graphics.print(row[1],w/2-250,y+7); love.graphics.setColor(1,.75,.25); love.graphics.printf(tostring(row[2]),w/2+40,y+7,270,"center") end
    UI.button(w/2-250,h/2+270,240,48,"로비로",true,fonts.body); UI.button(w/2+10,h/2+270,240,48,"다시 실험",true,fonts.body)
end

ClearcutMode.characters = {
    {id="physical", name="생계형 나무꾼", icon="axe", color={1,.42,.22},
        tagline="그냥 오늘 할당량을 채우러 온 것뿐이다.",
        detail="왜 이렇게까지 하냐고? 대출이 있다. 쉬지 않고 벨수록 손이 미친 듯이 빨라진다. 사거리 안에서 자동으로 가장 가까운 나무를 벱니다."},
    {id="fire", name="흡연자", icon="cigarette", color={1,.35,.12},
        tagline="담배꽁초 하나가 뭐 대수라고.",
        detail="마우스 위치에 무심코 꽁초를 튕깁니다. 숲이 마른 건 내 탓이 아니다. 붙은 불은 알아서 번지고 퍼집니다."},
    {id="toxic", name="비건 단체 회장", icon="leaf", color={.55,.85,.45},
        tagline="나무도 생명이지만... 일단 먹어야 한다.",
        detail="마우스 위치에 '친환경' 제초제를 살포합니다. 숲을 지키기 위해 숲을 없앱니다. 화력은 약하지만 재생력 자체를 짓누릅니다."},
    {id="developer", name="부동산 개발업자", icon="hardhat", color={1,.74,.1},
        tagline="여기에 아파트 지으면 됨.",
        detail="조준 방향으로 직접 돌진하며 경로상의 모든 것을 밀어버립니다. 넓은 범위를 순식간에 밀어내지만 재사용까지 잠깐 숨을 고릅니다."}
}

return ClearcutMode
