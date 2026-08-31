-- 확산 모델 회귀 검사.
--
-- 이전 모델은 확산을 "초당 확률"로 굴려서 연소속도를 올릴수록 나무가 빨리 사라지고
-- 불씨를 옮길 시간 창이 줄었다. 그래서 연소속도 특성이 확산 특성을 직접 깎아먹었고,
-- 확산 만렙이 연소속도 투자만으로 임계점(1.00) 아래로 떨어졌다.
--
-- 이 검사는 두 가지를 고정한다.
--   1. 연쇄 규모가 연소속도와 완전히 무관하다.
--   2. 확산 만렙이 임계점 1.00을 확실히 넘는다.
package.path = "./?.lua;./?/init.lua;" .. package.path

love = {math = {random = math.random}, filesystem = {}, graphics = {getDimensions = function() return 1600, 900 end}}

local ClearcutMode = require("src.clearcut_mode")
local CharacterTraits = require("src.character_traits")

local REFERENCE_BURN = ClearcutMode.SPREAD_REFERENCE_BURN
assert(REFERENCE_BURN == 3.6, "기준 연소시간이 바뀌었다면 아래 기대값도 함께 갱신해야 한다")

local function near(a, b, tolerance)
    return math.abs(a - b) <= (tolerance or 1e-6)
end

local function scoreMode(spreadChance, burnSpeed)
    local mode = ClearcutMode.new()
    mode.scoreAttack, mode.sandbox, mode.job, mode.mapId = true, true, "fire", "forest"
    mode.permanentTraits.spreadChance = spreadChance
    mode.permanentTraits.burnSpeed = burnSpeed or 1
    return mode
end

-- 1. 기본 확산량. 특성 0에서 꽁초 하나가 붙인 불은 평균 0.43그루로 번진다.
local base = scoreMode(0):spreadFactor()
assert(near(base, .12 * REFERENCE_BURN, 1e-9),
    string.format("기본 확산량이 %.4f로 바뀌었다 (기대 %.4f)", base, .12 * REFERENCE_BURN))
assert(base < 1, "기본 확산량이 임계점을 넘으면 신규 플레이어부터 산불이 자가증식한다")

-- 2. 연소속도는 확산량을 건드리지 않는다. 이 검사가 이번 수정의 핵심이다.
for _, burnSpeed in ipairs({1, 1.36, 1.85, 3.0}) do
    local factor = scoreMode(.282, burnSpeed):spreadFactor()
    assert(near(factor, scoreMode(.282, 1):spreadFactor(), 1e-9),
        string.format("연소속도 %.2f가 확산량을 %.4f로 바꿨다 — 두 특성이 다시 서로를 깎고 있다", burnSpeed, factor))
end

-- 3. 확산 특성 만렙이 임계점 1.00을 넘는다. 값은 특성 트리에서 직접 읽어 하드코딩을 피한다.
local ash = assert(CharacterTraits:getNode("fire_score_ash"), "fire_score_ash 특성이 사라졌다")
local maxedFactor = scoreMode(ash.value * ash.max):spreadFactor()
assert(maxedFactor > 1.0,
    string.format("확산 만렙 확산량이 %.4f — 임계점 1.00 아래라 산불이 스스로 번지지 않는다", maxedFactor))
assert(maxedFactor > 1.35 and maxedFactor < 1.6,
    string.format("확산 만렙 확산량 %.4f가 의도한 1.35~1.60 범위를 벗어났다", maxedFactor))

-- 4. 전파 횟수의 평균이 확산량과 일치한다 (소수부의 확률 반올림 검증).
math.randomseed(20260831)
local mode = scoreMode(ash.value * ash.max)
local total, samples = 0, 40000
for _ = 1, samples do total = total + mode:rollSpreadBudget() end
local mean = total / samples
assert(near(mean, maxedFactor, .03),
    string.format("전파 횟수 평균 %.4f가 확산량 %.4f와 어긋난다", mean, maxedFactor))

-- 5. 예산은 연소 구간에 균등 배치되고, 연소시간이 달라져도 총 전파량은 같다.
local function releasesOver(budget, burnDuration)
    local node = {spreadBudget = budget, spreadDone = 0, burnTimer = 0}
    local released, dt = 0, 1 / 60
    while node.burnTimer < burnDuration do
        node.burnTimer = node.burnTimer + dt
        if mode:releaseSpread(node, burnDuration) then released = released + 1 end
    end
    return released
end

for _, budget in ipairs({0, 1, 2, 5}) do
    local slow, fast = releasesOver(budget, 3.6), releasesOver(budget, 2.2)
    assert(slow == budget and fast == budget,
        string.format("예산 %d가 연소시간에 따라 %d/%d로 갈렸다 — 전파량이 연소속도에 다시 묶였다", budget, slow, fast))
end

-- 6. 예산을 넘겨 전파하지 않는다.
local node = {spreadBudget = 2, spreadDone = 0, burnTimer = 0}
local extra = 0
for _ = 1, 600 do
    node.burnTimer = node.burnTimer + 1 / 60
    if mode:releaseSpread(node, 2.2) then extra = extra + 1 end
end
assert(extra == 2, string.format("확산 예산 2가 %d번 전파됐다", extra))

-- 7. 모든 나무 점화 경로가 예산을 받는다.
local ignited = {active = true, rushTree = true, x = 0, y = 0}
mode:beginTreeBurn(ignited, 0)
assert(ignited.burning and ignited.spreadBudget ~= nil and ignited.spreadDone == 0,
    "beginTreeBurn이 확산 예산을 초기화하지 않았다")

print(string.format("FIRE_SPREAD_MODEL_OK base=%.2f maxed=%.2f burn_speed_independent", base, maxedFactor))
