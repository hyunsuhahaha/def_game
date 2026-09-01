-- 1분 주기 세계수와 처치 보상 회귀 검사.
--
-- 인게임 3택은 원래 목재 경험치로 열렸는데 요구량이 선형(5+레벨*3)인 반면 수입은
-- 지수(재생 단계 1.75^n x 시간 압력 2^(초/30))라, 후반에 선택 창이 연달아 떠서
-- 진행이 멈췄고 그래서 제거됐다. 이 검사는 트리거가 다시 목재로 돌아가지 않는지,
-- 즉 빈도가 수입과 무관한지를 고정한다.
package.path = "./?.lua;./?/init.lua;" .. package.path

love = {
    math = {random = math.random}, filesystem = {},
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

print("SCORE_WORLD_TREE_OK interval=60s trigger=time no_attack reward=3pick run_only")
