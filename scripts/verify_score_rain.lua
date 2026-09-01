-- 기록 모드 소나기 회귀 검사.
--
-- 캠페인 재해 3종(비·뿌리지진·낙하가지)은 연출까지 완성돼 있는데 기록 모드에서는
-- 통째로 꺼져 있었다. 그 결과 판이 처음부터 끝까지 같은 조건이고, 후반에는 불이
-- 언제나 최적이라 도끼가 손에서 사라진다. 비는 그 독점을 짧게 끊는 장치다.
--
-- 이 검사는 (1) 비만 오고 지진·낙하 가지는 안 오는지, (2) 5초를 넘기지 않는지,
-- (3) 세계수 주기와 겹쳐 돌지 않는지, (4) 비가 그친 뒤 불이 다시 붙는지를 고정한다.
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

assert(ClearcutMode.SCORE_RAIN_DURATION == 5, "소나기 지속시간이 5초가 아니다")
assert(ClearcutMode.SCORE_RAIN_FIRST >= ScoreWorldTree.INTERVAL,
    "첫 소나기가 첫 세계수보다 먼저 온다 — 두 이벤트가 서로를 가린다")

-- 주기가 세계수와 정수배로 맞물리면 매번 같이 뜬다.
local cycle = ClearcutMode.SCORE_RAIN_INTERVAL + ClearcutMode.SCORE_RAIN_WARN
    + ClearcutMode.SCORE_RAIN_DURATION + 2
assert(cycle % ScoreWorldTree.INTERVAL ~= 0, "소나기 주기가 세계수 주기의 배수라 항상 함께 뜬다")
assert(cycle > ScoreWorldTree.INTERVAL, "소나기가 세계수보다 자주 온다")

local mode = ClearcutMode.new()
mode.scoreAttack = true
mode.enemies = {}

local notices = {}
local game = {
    world = {nodes = {}, addParticle = function() end},
    camera = {trauma = 0},
    setNotice = function(_, text) notices[#notices+1] = text end,
}

local burning = {x = 0, y = 0, burning = true, burnTimer = .4, fireTickTimer = .1}
game.world.nodes[1] = burning

-- 시작 직후에는 비가 오지 않는다. 첫 판 첫 1분은 배우는 구간이다.
mode:updateScoreRain(1, game)
assert(mode.disasterState == "idle" and not mode.rainSuppressFire, "시작하자마자 비가 온다")

local STEP = 1/60
local function advance(seconds)
    local left = seconds
    while left > 0 do
        local dt = math.min(STEP, left)
        mode:updateScoreRain(dt, game)
        left = left - dt
    end
end

-- 절대 시각이 아니라 각 구간이 실제로 몇 초 지속되는지를 잰다. 프레임 경계에서
-- 남는 자투리를 검사가 직접 떠안지 않도록.
local function advanceTo(state, limit)
    local spent = 0
    while mode.disasterState ~= state do
        advance(STEP); spent = spent + STEP
        assert(spent <= limit, "구간 '" .. state .. "' 에 " .. limit .. "초 안에 도달하지 못했다")
    end
    return spent
end

-- 경고 구간: 아직 불은 살아 있어야 한다.
local untilWarn = advanceTo("warn", 200)
assert(mode.disasterType == "rain", "예고된 재해가 비가 아니다")
assert(untilWarn >= ScoreWorldTree.INTERVAL, "첫 비가 첫 세계수보다 먼저 왔다")
assert(not mode.rainSuppressFire, "경고 단계에서 이미 불이 막힌다")
assert(burning.burning, "경고 단계에서 불이 꺼졌다")

-- 실제 강우: 타던 불이 전부 꺼지고 새 점화가 막힌다.
local warnLength = advanceTo("active", 10)
assert(math.abs(warnLength - ClearcutMode.SCORE_RAIN_WARN) <= STEP * 2,
    "경고 길이가 " .. warnLength .. "초다")
assert(mode.rainSuppressFire, "비가 오는데 점화 억제가 걸리지 않았다")
assert(not burning.burning and burning.burnTimer == nil and burning.fireTickTimer == nil,
    "비가 오는데 타던 나무가 그대로다")

-- 실제 지속시간이 5초여야 한다. 길면 벌목 자체가 멈춘다.
local rainLength = advanceTo("cooldown", 30)
assert(math.abs(rainLength - ClearcutMode.SCORE_RAIN_DURATION) <= STEP * 2,
    "소나기가 " .. rainLength .. "초 동안 왔다")
assert(not mode.rainSuppressFire, "비가 그쳤는데 점화 억제가 남아 있다")

-- 그친 뒤에는 다시 불이 붙어야 한다. 억제가 남으면 판이 죽는다.
mode:beginTreeBurn(burning, 0)
assert(burning.burning, "비가 그친 뒤에도 점화가 막혀 있다")

-- 다음 비까지는 충분히 멀어야 한다.
advanceTo("idle", 10)
assert(mode.disasterType == nil, "비 종료 후 재해 종류가 남아 있다")
local gap = advanceTo("warn", 200)
assert(gap >= ScoreWorldTree.INTERVAL, "비 간격(" .. gap .. "초)이 세계수 주기보다 짧다")

-- 캠페인 재해는 기록 모드에 들어오지 않는다.
for _ = 1, 400 do
    advance(1)
    assert(mode.disasterType == nil or mode.disasterType == "rain",
        "기록 모드에 지진/낙하 가지가 들어왔다: " .. tostring(mode.disasterType))
end

for _, text in ipairs(notices) do
    assert(not text:find("지진") and not text:find("가지"), "기록 모드에 캠페인 재해 안내가 뜬다: " .. text)
end

-- 캠페인 쪽 경로는 건드리지 않았다.
local campaign = ClearcutMode.new()
campaign.stage = 1
campaign:updateDisasters(1, game)
assert(campaign.disasterTimer == 150, "1스테이지 캠페인에서 재해 타이머가 흘렀다")

print("PASS score rain")
