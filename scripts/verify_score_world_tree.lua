-- 1분 주기 세계수와 처치 보상 회귀 검사.
--
-- 인게임 3택은 원래 목재 경험치로 열렸는데 요구량이 선형(5+레벨*3)인 반면 수입은
-- 지수(재생 단계 1.75^n x 시간 압력 2^(초/30))라, 후반에 선택 창이 연달아 떠서
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

assert(ScoreWorldTree.INTERVAL == 60, "세계수 주기가 60초가 아니다")

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
m:updateScoreWorldTree(59, g)
assert(not m.scoreWorldTree, "60초 전에 세계수가 등장했다")
m:updateScoreWorldTree(1.5, g)
assert(m.scoreWorldTree, "60초가 지나도 세계수가 등장하지 않았다")

-- 2. 세계수가 서 있는 동안에는 타이머가 멈춰 두 그루가 겹치지 않는다.
local standing = m.scoreWorldTree
m:updateScoreWorldTree(120, g)
assert(m.scoreWorldTree == standing, "세계수가 서 있는데 두 번째가 등장했다")

-- 3. 공격하지 않는다. 기록 모드에는 플레이어 HP가 없어 공격이 의미가 없다.
assert(standing.slamTimer == math.huge and standing.summonTimer == math.huge,
    "세계수 공격 타이머가 살아 있다")

-- 4. 체력은 재생 단계에 비례한다. 단계가 오를수록 치러 갈지 판단이 어려워져야 한다.
local low, high = mode(), mode()
low.scoreRegenTier, high.scoreRegenTier = 1, 8
assert(ScoreWorldTree.health(high) > ScoreWorldTree.health(low) * 2,
    "재생 단계가 세계수 체력에 반영되지 않는다")

-- 5. 처치하면 보상 3택이 열리고 게임이 멈춘다.
local dead = mode()
local dg = world()
dead.scoreWorldTree = {scoreWorldTree = true, hp = 0, def = {}, x = 0, y = 0}
dead:onEnemyDefeated(dead.scoreWorldTree, dg)
assert(dg.mode == "score_reward" and #dead.scoreRewardChoices == 3,
    "세계수를 쓰러뜨려도 보상 3택이 열리지 않는다")

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

print("SCORE_WORLD_TREE_OK interval=60s trigger=time no_attack reward=3pick run_only")
