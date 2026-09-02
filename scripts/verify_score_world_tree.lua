-- 40초 주기 세계수와 처치 보상 회귀 검사.
--
-- 인게임 3택은 원래 목재 경험치로 열렸는데 요구량이 선형(5+레벨*3)인 반면 수입은
-- 지수(재생 단계 1.75^n x 시간 압력 2^(초/20))라, 후반에 선택 창이 연달아 떠서
-- 진행이 멈췄고 그래서 제거됐다. 이 검사는 트리거가 다시 목재로 돌아가지 않는지,
-- 즉 빈도가 수입과 무관한지를 고정한다.
package.path = "./?.lua;./?/init.lua;" .. package.path

love = {
    math = {random = math.random}, filesystem = {}, timer = {getTime = function() return 0 end},
    graphics = {getDimensions = function() return 1280, 720 end, newQuad = function() return {} end,
        newImage = function() return {setFilter = function() end,
            getWidth = function() return 64 end, getHeight = function() return 64 end,
            getDimensions = function() return 64, 64 end} end},
    mouse = {getPosition = function() return 0, 0 end, isDown = function() return false end},
    keyboard = {isDown = function() return false end},
}

local ClearcutMode = require("src.clearcut_mode")
local ScoreWorldTree = require("src.score_world_tree")

assert(ScoreWorldTree.INTERVAL == 40, "세계수 주기가 40초가 아니다")
assert(ScoreWorldTree.health(1)==260 and ScoreWorldTree.health(8)==17820
    and ScoreWorldTree.health(10)==40950 and ScoreWorldTree.health(11)==58968,
    "세계수 체력이 누적 빌드 DPS 기반 곡선과 다르다")
assert(ScoreWorldTree.REWARDS_ENABLED == false, "운영 모드에서 세계수 보상이 다시 활성화됐다")

local function mode()
    local m = ClearcutMode.new()
    m.scoreAttack, m.sandbox, m.job, m.mapId = true, true, "fire", "forest"
    ScoreWorldTree.reset(m)
    return m
end

local function world(trees)
    return {
        player = {x = 100, y = 100},
        world = {nodes = trees or {}, width = 2240, height = 1400,
            playBounds = {x = 0, y = 0, w = 2240, h = 1400},
            igniteFx = function() end, impactNode = function() end},
        setNotice = function() end, mode = "playing",
    }
end

-- 1. 트리거는 시간이다. 목재를 아무리 벌어도 세계수가 앞당겨지지 않는다.
local m, g = mode(), world()
m.scoreWoodEarned = 999999
m:updateScoreWorldTree(39, g)
assert(not m.scoreWorldTree, "40초 전에 세계수가 등장했다")
m:updateScoreWorldTree(1.5, g)
assert(m.scoreWorldTree, "40초가 지나도 세계수가 등장하지 않았다")

-- 1-4. 솟는 자리에 이미 서 있던 나무는 뿌리째 들려 바깥으로 날아간다. 자리를
-- 실제로 비워야 중앙 고정 배치에서도 첫 프레임부터 세계수가 통째로 보인다.
do
    local center = {x = 1120, y = 700}
    local function tree(x, y)
        return {kind = "tree", rushTree = true, active = true, x = x, y = y,
            rushHp = 12, rushMaxHp = 12, treeVariant = 1}
    end
    local inside, behind, outside = tree(center.x + 40, center.y + 20),
        tree(center.x - 30, center.y - 25), tree(center.x + 900, center.y)
    local em, eg = mode(), world({inside, behind, outside})
    eg.world.harvestBurst = function() end
    eg.world.spawnDrop = function() end
    em.remainingTrees = 3
    em:updateScoreWorldTree(41, eg)
    assert(em.scoreWorldTree, "세계수가 등장하지 않아 분출을 확인할 수 없다")
    assert(not inside.active, "세계수 밑동에 서 있던 나무가 그대로 남았다")
    assert(not behind.active, "세계수 뒤쪽 나무가 남아 수관을 끊는다")
    assert(outside.active, "밑동과 상관없는 먼 나무까지 날려버렸다")
    assert(#em.thrownTrees == 2, "치운 나무가 날아가는 물체로 넘어가지 않았다")
    assert(em.treesFelled == 2, "분출로 치운 나무가 벌목 기록에 남지 않았다")
    for _, thrown in ipairs(em.thrownTrees) do
        -- 쓰러지는 연출이 같이 재생되면 한 나무가 두 번 죽는다.
        assert(thrown.vx ~= 0 or thrown.vy ~= 0, "날아가는 나무가 제자리에 멈춰 있다")
        assert(thrown.vz > 0, "날아가는 나무가 위로 뜨지 않는다")
    end
    assert(inside.uprooted and inside.fallT == nil,
        "날아간 나무에 쓰러지는 연출이 남아 두 번 죽는다")
end

-- 2. 세계수가 서 있는 동안에는 타이머가 멈춰 두 그루가 겹치지 않는다.
local standing = m.scoreWorldTree

-- 1-1. 세계수는 항상 이동 가능 구역의 정중앙에 선다. 무작위 배치는 랜드마크를
-- 화면 밖으로 보내 60초마다 오는 유일한 선택을 놓치게 했다.
assert(standing.x==1120 and standing.y==700,
    "세계수가 이동 가능 구역 중앙에 서지 않았다")
assert(standing.fixedX==standing.x and standing.fixedY==standing.y,
    "세계수 고정 좌표가 중앙과 어긋났다")

-- 1-2. 밑동 앞을 덮는 바닥 장식은 세계수 뒤로 정렬된다. 판정은 발선(ForestArt.footY)
-- 규약을 그대로 쓰고, 발선 뒤쪽은 어차피 가려지므로 건드리지 않는다.
local guard = m:worldTreeGuard()
assert(guard and guard.hits, "세계수 가림 구역이 만들어지지 않았다")
local foot = standing.y + standing.def.radius * .65
assert(math.abs(guard.sortY-foot)<.001, "가림 구역 정렬선이 세계수 발선과 다르다")
assert(guard.hits(guard, standing.x, foot + 10),
    "밑동 바로 앞의 바닥 장식이 세계수를 덮는다")
assert(not guard.hits(guard, standing.x, foot - 40),
    "발선 뒤쪽까지 불필요하게 뒤로 밀었다")
assert(not guard.hits(guard, standing.x + guard.rx * 2, foot + 10),
    "세계수와 겹치지도 않는 먼 장식까지 뒤로 밀었다")
assert(not guard.hits(guard, standing.x, foot + guard.ry * 2),
    "앞쪽 원경 장식까지 세계수 뒤로 보내 깊이가 뒤집혔다")
assert(not ClearcutMode.worldTreeGuardHits(nil, 0, 0),
    "세계수가 없을 때도 가림 판정이 켜져 있다")

-- 1-3. 실제 큐잉 경로로 확인한다. 기하만 맞고 world.lua 연결이 빠지면 화면은
-- 그대로 가려진 채다. world.lua 는 정렬 y 가 작을수록 먼저(뒤에) 그린다.
do
    local Scenery = require("src.forest_scenery")
    local Understory = require("src.forest_understory")
    local near, far = foot + 12, foot + guard.ry * 2
    local stub = {
        width = 2240, height = 1400, clearcutMap = "temperate",
        playBounds = {x = 0, y = 0, w = 2240, h = 1400},
        worldTreeGuard = guard,
        forestScenery = {actors = {
            {kind = "rock", x = standing.x, y = near, scale = 1, flip = 1, angle = 0, tone = 1},
            {kind = "rock", x = standing.x, y = far, scale = 1, flip = 1, angle = 0, tone = 1},
        }},
        forestUnderstory = {patches = {
            {x = standing.x, y = near, scale = 1, flip = 1, bend = 0, rustle = 0},
            {x = standing.x, y = far, scale = 1, flip = 1, bend = 0, rustle = 0},
        }},
    }
    local queue = {}
    Scenery.queue(stub, queue, nil)
    Understory.queue(stub, queue, nil)
    assert(#queue == 4, "바닥 장식 큐잉 경로가 바뀌었다")
    for _, item in ipairs(queue) do
        if item.anchorY == near then
            assert(item.y < guard.sortY,
                "세계수 밑동을 덮는 바닥 장식이 여전히 세계수보다 앞에 그려진다")
        else
            assert(item.y >= guard.sortY,
                "세계수와 겹치지 않는 앞쪽 장식까지 뒤로 밀려 깊이가 뒤집혔다")
        end
    end
    stub.worldTreeGuard = nil
    local plain = {}
    Scenery.queue(stub, plain, nil)
    Understory.queue(stub, plain, nil)
    for _, item in ipairs(plain) do
        assert(math.abs(item.y - item.anchorY) <= 1,
            "세계수가 없을 때도 바닥 장식 정렬을 건드렸다")
    end
end

-- 2-1. 1단계부터 거대 공성 세계수를 재사용하지 않는다. 성장형은 실제 그림뿐 아니라
-- 충돌 반지름과 수관 높이도 작아야 주변 나무/공격 판정과 시각이 일치한다.
local firstProfile=ScoreWorldTree.profile(1)
assert(not firstProfile.giant and standing.artKey=="scoreWorldtreeYoung",
    "1단계가 어린 세계수 전용 디자인을 쓰지 않는다")
assert(standing.def.radius==firstProfile.radius and standing.def.radius>=100 and standing.def.radius<140,
    "1단계 세계수 충돌 범위가 표시 크기와 맞지 않거나 거대형처럼 크다")
assert(firstProfile.crownHeight>=250,
    "1단계 세계수가 일반 활엽수와 구분되지 않을 만큼 작다")
assert(standing.scoreWorldTreeCrownHeight==firstProfile.crownHeight and standing.scoreWorldTreeGrowing,
    "1단계 세계수의 빠른 성장 연출/수관 높이가 연결되지 않았다")
assert(not m.worldTreeEmergence, "1단계부터 6.75초 SKYVIEW 등장 컷이 발동했다")
m:updateScoreWorldTree(120, g)
assert(m.scoreWorldTree == standing, "세계수가 서 있는데 두 번째가 등장했다")

-- 세 형태는 단순 배율이 아니라 서로 다른 아트 키로 성장하고, 10단계에서만 기존
-- 거대 세계수로 교체된다.
assert(ScoreWorldTree.profile(3).artKey=="scoreWorldtreeYoung", "3단계 성장형이 바뀌었다")
assert(ScoreWorldTree.profile(4).artKey=="scoreWorldtreeAdolescent", "4단계 중간형이 없다")
assert(ScoreWorldTree.profile(7).artKey=="scoreWorldtreePrecursor", "7단계 성목 전환이 없다")
assert(not ScoreWorldTree.profile(9).giant and ScoreWorldTree.profile(9).radius<420,
    "9단계부터 거대형이 조기 등장한다")
assert(ScoreWorldTree.profile(10).giant and ScoreWorldTree.profile(10).artKey=="worldtree",
    "10단계에서 기존 거대 세계수로 전환되지 않는다")

-- 10단계부터는 기존 SKYVIEW+뿌리 상승 연출을 그대로 시작한다. 완료 뒤 기록 모드의
-- 비공격 규칙이 풀리면 안 된다.
do
    local giantMode=mode();giantMode.scoreRegenTier=10
    local camera={mode="default",skyviewBlend=0,trauma=0,
        setMode=function(self,name) self.mode=name;self.skyviewBlend=name=="skyview" and 1 or 0 end,
        focus=function(self,x,y) self.focusX,self.focusY=x,y end}
    local giantGame=world();giantGame.camera=camera
    assert(giantMode:spawnScoreWorldTree(giantGame), "10단계 거대 세계수를 생성하지 못했다")
    local giant=giantMode.scoreWorldTree
    assert(giant.scoreWorldTreeGiant and giant.artKey=="worldtree" and giant.def.radius==420,
        "10단계가 기존 거대 세계수 외형/크기를 쓰지 않는다")
    assert(giantMode.worldTreeEmergence and camera.mode=="skyview" and camera.scriptedSkyviewBoss,
        "10단계 거대형의 기존 SKYVIEW 등장 연출이 시작되지 않았다")
    for _=1,12 do giantMode:updateWorldTreeEmergence(.75,giantGame) end
    assert(not giantMode.worldTreeEmergence and not giantMode.worldTreeCamera,
        "거대형 등장 뒤 카메라 소유권이 기록 모드에 남았다")
    assert(giant.slamTimer==math.huge and giant.summonTimer==math.huge,
        "거대형 등장 종료 뒤 캠페인 공격 패턴이 켜졌다")
end

-- 3. 공격하지 않는다. 기록 모드에는 플레이어 HP가 없어 공격이 의미가 없다.
assert(standing.slamTimer == math.huge and standing.summonTimer == math.huge,
    "세계수 공격 타이머가 살아 있다")

-- 공격 타이머만 막아서는 부족하다. 체력 구간을 넘을 때 캠페인용 낙하 가지와
-- 경고 파편이 따로 생성되면 기록 모드에서도 세계수가 공격하는 것처럼 보인다.
do
    local WorldTreeSiege = require("src.worldtree_siege")
    m.worldTreeDebris = {}
    standing.worldTreeDamageStage = 0
    standing.hp = standing.maxHp * .2
    WorldTreeSiege.updateBoss(m, standing, 1 / 60, g)
    assert(#m.worldTreeDebris == 0,
        "기록 모드 세계수가 체력 구간 변화로 공격 파편/낙하 가지를 생성했다")

    local notices = 0
    local quietGame = world()
    quietGame.camera = {trauma = 0}
    quietGame.setNotice = function() notices = notices + 1 end
    standing.enraged, standing.enrageAnnounced = nil, nil
    m.bossTelegraphs = {}
    m:updateWorldTreeAI(standing, 1 / 60, quietGame)
    assert(notices == 0 and quietGame.camera.trauma == 0 and #m.bossTelegraphs == 0,
        "기록 모드 세계수의 격노 알림/화면 흔들림/공격 경고가 살아 있다")
end

-- 4. 체력은 재생 단계에 비례한다. 단계가 오를수록 치러 갈지 판단이 어려워져야 한다.
local low, high = mode(), mode()
low.scoreRegenTier, high.scoreRegenTier = 1, 8
assert(ScoreWorldTree.health(high) > ScoreWorldTree.health(low) * 2,
    "재생 단계가 세계수 체력에 반영되지 않는다")

-- 5. 운영 모드에서는 처치해도 보상 3택이 열리지 않는다.
local disabled = mode()
local disabledGame = world()
disabled.mapWorld=disabledGame.world
disabled.scoreWorldTree = {scoreWorldTree = true, hp = 0, def = {}, x = 0, y = 0}
disabled:onEnemyDefeated(disabled.scoreWorldTree, disabledGame)
assert(disabledGame.mode ~= "score_reward" and disabled.scoreRewardChoices == nil,
    "비활성화한 세계수 보상 3택이 운영 모드에서 열렸다")

-- 보상 코드와 스크립트는 복구 가능하게 보존한다.
ScoreWorldTree.REWARDS_ENABLED = true
local dead = mode()
local dg = world()
dead.stageElapsed=40
local survivingTree={rushTree=true,active=true,x=100,y=100}
dg.world.nodes={survivingTree}
dead.mapWorld=dg.world
dead.scoreWorldTree = {scoreWorldTree = true, hp = 0, def = {}, x = 0, y = 0}
dead:onEnemyDefeated(dead.scoreWorldTree, dg)
assert(dg.mode == "score_reward" and #dead.scoreRewardChoices == 3,
    "세계수를 쓰러뜨려도 보상 3택이 열리지 않는다")
assert(dead.scoreRegenTier==2 and dead.stageElapsed==0 and dead.scoreTierFx and not dead.scoreTierFx.reseed,
    "40초 세계수 처치가 현재 숲을 유지하는 재생 단계 상승을 시작하지 않았다")
assert(dg.world.nodes[1]==survivingTree and survivingTree.active,
    "세계수 승급이 살아 있는 숲을 공짜로 지웠다")

-- 6. 고른 보상은 이번 판에만 남고 후보에서 빠진다.
local pickId = dead.scoreRewardChoices[1].id
dead:chooseScoreReward(1, dg)
assert(dead:scoreReward(pickId) and dg.mode == "playing", "보상 선택이 적용되지 않았다")
assert(not dead.scoreRewardChoices, "선택 뒤에도 카드가 남아 있다")
for _, def in ipairs(ScoreWorldTree.roll(dead, 3)) do
    assert(def.id ~= pickId, "이미 고른 보상이 다시 후보로 나온다")
end

-- 7. 보상은 영구 연구와 겹치는 +N 수치가 아니라 규칙을 바꾼다.
local windy, calm = mode(), mode()
ScoreWorldTree.grant(windy, "dry_wind")
assert(math.abs(windy:spreadFactor() - calm:spreadFactor() * 2) < 1e-9,
    "마른 바람이 확산량을 두 배로 만들지 않는다")

-- 8. 새 런은 보상을 물려받지 않는다.
local fresh = mode()
assert(not fresh:scoreReward("dry_wind"), "이전 판의 보상이 다음 판까지 남았다")

-- 세계수는 공격하지 않으므로, 때리는 쪽에 반응이 없으면 체력만 많은 기둥이다.
-- 수관에서 쏟아지는 목재가 유일한 타격감이라 타격마다 실제로 나와야 한다.
do
    local mode = ClearcutMode.new()
    mode.scoreAttack = true
    mode.enemies = {}
    local catalog = require("src.forest_enemy_catalog")
    local tree = {x = 300, y = 200, hp = 260, maxHp = 260, scoreWorldTree = true,
        def = {radius = 420}}
    mode.scoreWorldTree = tree
    mode.scoreWorldTreeHp = tree.hp
    local fxGame = {world = {nodes = {}, playBounds = {x=0,y=0,w=800,h=600}},
        player = {x = 0, y = 0}, setNotice = function() end}

    -- 체력이 그대로면 아무것도 나오지 않는다.
    mode:updateScoreWorldTree(1/60, fxGame)
    assert(#mode.worldTreeLumber == 0, "때리지도 않았는데 목재가 쏟아진다")

    -- 한 대 때리면 나온다. 피해원마다 훅을 거는 대신 체력 변화를 관찰하므로
    -- 도끼든 폭죽이든 기름이든 전부 잡힌다.
    tree.hp = tree.hp - 12
    mode:updateScoreWorldTree(1/60, fxGame)
    local firstBurst = #mode.worldTreeLumber
    assert(firstBurst > 0, "세계수를 때렸는데 목재가 나오지 않는다")

    -- 수관에서 나와야 "위에서 쏟아진다" 로 읽힌다. 발밑에서 솟으면 안 된다.
    local crown = catalog.worldtree.height
    for _, piece in ipairs(mode.worldTreeLumber) do
        assert(piece.height > crown * .5, "목재가 수관이 아니라 발밑에서 나온다")
        assert(piece.height <= crown * 1.1, "목재가 수관보다 훨씬 위에서 나온다")
    end

    -- 큰 피해일수록 많이 쏟아지되 상한이 있다.
    mode.worldTreeLumber = {}
    tree.hp = tree.hp - 200
    mode:updateScoreWorldTree(1/60, fxGame)
    assert(#mode.worldTreeLumber > firstBurst, "큰 피해인데 목재가 더 나오지 않는다")
    assert(#mode.worldTreeLumber <= 6, "한 번의 타격에서 목재가 너무 많이 나온다")

    -- 순수 연출이다. 줍히는 목재로 만들면 때릴 때마다 수입이 붙어 경제가 바뀐다.
    assert(fxGame.world.drops == nil, "세계수 연출이 줍히는 목재를 만들었다")

    -- 떨어지고 나면 사라진다. 남으면 바닥에 목재가 쌓인 것처럼 보인다.
    for _ = 1, math.ceil(ClearcutMode.WORLD_TREE_LUMBER_LIFE * 60) + 4 do
        mode:updateWorldTreeLumber(1/60)
    end
    assert(#mode.worldTreeLumber == 0, "쏟아진 목재가 사라지지 않는다")

    -- 세계수가 쓰러진 뒤에도 떨어지던 목재는 마저 떨어져야 한다.
    tree.hp = 40
    mode.scoreWorldTreeHp = 60
    mode:updateScoreWorldTree(1/60, fxGame)
    assert(#mode.worldTreeLumber > 0, "마지막 타격에서 목재가 나오지 않는다")
    mode.scoreWorldTree = nil
    mode:updateWorldTreeLumber(1/60)
    assert(#mode.worldTreeLumber > 0, "세계수가 사라지자 떨어지던 목재도 같이 사라졌다")

    -- 상한을 넘게 쌓이지 않는다.
    for _ = 1, 60 do mode:spawnWorldTreeLumber(tree, 260, fxGame) end
    assert(#mode.worldTreeLumber <= ClearcutMode.WORLD_TREE_LUMBER_CAP,
        "쏟아진 목재가 상한 없이 쌓인다")
end

-- 7개짜리 풀에 작은 수치 증가만 있으면 매 판이 똑같다. 풀을 늘리는 것만으로는
-- 부족하고, 축이 배타적이어야 "이번 판은 이런 판" 이 만들어진다.
do
    assert(#ScoreWorldTree.rewards >= 20, "보상 풀이 20개 미만이다: " .. #ScoreWorldTree.rewards)

    local seen, groups = {}, {}
    for _, def in ipairs(ScoreWorldTree.rewards) do
        assert(not seen[def.id], "보상 id 가 중복이다: " .. def.id)
        seen[def.id] = true
        assert(def.name and def.desc and def.color, def.id .. " 에 이름/설명/색이 없다")
        if def.group then
            groups[def.group] = (groups[def.group] or 0) + 1
            assert(ScoreWorldTree.groupName(def), def.group .. " 에 표시 이름이 없다")
        end
    end
    -- 혼자뿐인 group 은 배타성이 아무 일도 하지 않으면서 풀만 잠근다.
    for group, count in pairs(groups) do
        assert(count >= 2, "group '" .. group .. "' 에 보상이 하나뿐이라 배타성이 무의미하다")
    end

    local mode = ClearcutMode.new()
    mode.scoreAttack = true
    local game = {setNotice = function() end, world = {nodes = {}}}

    -- 한 번의 3택에 같은 축이 둘 뜨면 실질 선택지가 준다.
    for _ = 1, 200 do
        local probe = ClearcutMode.new(); probe.scoreAttack = true
        local picks = ScoreWorldTree.roll(probe, 3)
        assert(#picks == 3, "선택지가 3개가 아니다: " .. #picks)
        local offered = {}
        for _, def in ipairs(picks) do
            assert(not (def.group and offered[def.group]), "한 번의 3택에 같은 축이 둘 떴다: " .. tostring(def.group))
            if def.group then offered[def.group] = true end
        end
    end

    -- 축을 하나 고르면 그 축의 나머지는 그 판에서 영원히 잠긴다.
    mode:applyScoreReward("dry_wind", game)
    assert(ScoreWorldTree.groupTaken(mode, "fire"), "축을 골랐는데 잠기지 않았다")
    for _ = 1, 200 do
        for _, def in ipairs(ScoreWorldTree.roll(mode, 3)) do
            assert(def.group ~= "fire", "이미 정한 축의 보상이 다시 나왔다: " .. def.id)
            assert(def.id ~= "dry_wind", "이미 고른 보상이 다시 나왔다")
        end
    end

    -- 풀이 마르면 빈 목록을 돌려주고 호출부가 창을 열지 않는다.
    local drained = ClearcutMode.new(); drained.scoreAttack = true
    for _, def in ipairs(ScoreWorldTree.rewards) do ScoreWorldTree.grant(drained, def.id) end
    assert(#ScoreWorldTree.roll(drained, 3) == 0, "다 가졌는데 선택지가 남아 있다")
end

-- 설명만 있고 코드에 걸려 있지 않은 보상은 순수 장식이다. 실제로 읽히는지 본다.
do
    local source = assert(io.open("src/clearcut_mode.lua", "rb"))
    local code = source:read("*a"); source:close()
    local butts = assert(io.open("src/cigarette_butts.lua", "rb"))
    code = code .. butts:read("*a"); butts:close()
    for _, def in ipairs(ScoreWorldTree.rewards) do
        assert(code:find('scoreReward("' .. def.id .. '")', 1, true)
            or code:find('id=="' .. def.id .. '"', 1, true),
            "보상 '" .. def.id .. "' 이 어디에서도 읽히지 않는다 — 설명만 있는 장식이다")
    end
end

-- 대가가 붙은 보상은 대가도 실제로 걸려 있어야 한다. 없으면 순수 상향이 된다.
do
    local mode = ClearcutMode.new(); mode.scoreAttack = true
    mode.permanentTraits.burnSpeed = 1
    local game = {setNotice = function() end, world = {nodes = {}}}

    local baseSpread = mode:spreadFactor()
    mode:applyScoreReward("slow_burn", game)
    assert(mode:spreadFactor() == 0, "뭉근한 불의 대가(확산 없음)가 걸려 있지 않다")
    assert(baseSpread > 0, "기본 확산이 0이라 검사가 무의미하다")

    local quota = ClearcutMode.new(); quota.scoreAttack = true
    assert(quota:scoreSettlementBonus() == 0, "아무것도 안 골랐는데 정산 보너스가 있다")
    quota:applyScoreReward("quota", game)
    assert(quota:scoreSettlementBonus() < 0, "할당량 감축의 대가(수입 감소)가 걸려 있지 않다")

    local cut = ClearcutMode.new(); cut.scoreAttack = true
    cut.scoreTreeAllowance = 12
    cut:applyScoreReward("clear_cut", game)
    assert(cut.scoreTreeAllowance == 8, "좁고 깊게의 대가(허용량 감소)가 걸려 있지 않다")
    assert(cut:scoreSettlementBonus() > 0, "좁고 깊게의 수입 증가가 걸려 있지 않다")

    local permit = ClearcutMode.new(); permit.scoreAttack = true
    permit.scoreTreeAllowance = 12
    permit:applyScoreReward("permit", game)
    assert(permit.scoreTreeAllowance == 22, "무허가 확장의 허용량이 늘지 않았다")
end

ScoreWorldTree.REWARDS_ENABLED = false
print("SCORE_WORLD_TREE_OK interval=40s tier=empty_or_kill reward=disabled legacy=verified")
