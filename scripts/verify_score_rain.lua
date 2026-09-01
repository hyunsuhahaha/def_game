-- 기록 모드 소나기 회귀 검사.
--
-- 캠페인 재해 3종(비·뿌리지진·낙하가지)은 연출까지 완성돼 있는데 기록 모드에서는
-- 통째로 꺼져 있었다. 그 결과 판이 처음부터 끝까지 같은 조건이고, 후반에는 불이
-- 언제나 최적이라 도끼가 손에서 사라진다. 비는 그 독점을 짧게 끊는 장치다.
--
-- 주기와 지속시간이 고정이면 세어서 대비할 수 있고 그러면 긴장이 사라진다. 이
-- 검사는 둘 다 실제로 흔들리는지, 그러면서도 상한(5초)과 하한 간격을 넘지 않는지,
-- 그리고 세기가 항상 경고로 먼저 알려지는지를 고정한다.
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

-- Lua의 부정 문자셋은 UTF-8 문자가 아니라 바이트를 자른다. 실제 HUD에 들어가는
-- 문자열이 한글 코드포인트 중간에서 끊기지 않는지 고정한다.
assert(ClearcutMode.scoreRainApproachName({banner="소나기 — 방화 봉쇄"}) == "소나기",
    "소나기 접근 문구가 UTF-8 구분자 앞에서 안전하게 잘리지 않는다")
assert(ClearcutMode.scoreRainApproachName({banner="장대비 — 방화 봉쇄"}) == "장대비",
    "장대비 접근 문구가 UTF-8 구분자 앞에서 안전하게 잘리지 않는다")
assert(ClearcutMode.scoreRainApproachName({banner="지나가는 비"}) == "지나가는 비",
    "구분자가 없는 비 이름이 잘렸다")
do
    local source=assert(io.open("src/clearcut_mode.lua","rb"))
    local code=source:read("*a");source:close()
    assert(not code:find('match("^[^ —]+")',1,true),
        "UTF-8을 중간 바이트에서 자르는 구형 HUD 패턴이 남아 있다")
end

-- 5초를 넘기면 벌목 자체가 멈춘다. 어떤 세기도 이 상한을 넘지 못한다.
assert(ClearcutMode.SCORE_RAIN_MAX_DURATION == 5, "소나기 상한이 5초가 아니다")
local heaviest = 0
for _, kind in ipairs(ClearcutMode.SCORE_RAIN_KINDS) do
    assert(kind.maxDuration <= ClearcutMode.SCORE_RAIN_MAX_DURATION,
        kind.id .. " 의 최대 지속시간이 상한을 넘는다")
    assert(kind.minDuration < kind.maxDuration, kind.id .. " 의 지속시간이 고정이다")
    assert(kind.warn > 0 and kind.warnNotice and kind.banner and kind.warnBanner,
        kind.id .. " 에 경고 문구가 없다 — 예고 없는 비는 불공정하다")
    heaviest = math.max(heaviest, kind.maxDuration)
end
assert(heaviest == ClearcutMode.SCORE_RAIN_MAX_DURATION, "상한 5초에 닿는 비가 하나도 없다")
assert(ClearcutMode.SCORE_RAIN_MIN_GAP > ClearcutMode.SCORE_RAIN_MAX_DURATION * 6,
    "비 간격이 지속시간에 비해 너무 짧다 — 너무 자주 온다")
assert(ClearcutMode.SCORE_RAIN_FIRST >= ScoreWorldTree.INTERVAL,
    "첫 비가 첫 세계수보다 먼저 온다 — 두 이벤트가 서로를 가린다")

-- 경고가 길수록 센 비여야 한다. 그래야 경고를 보고 담배를 털지 아낄지 정한다.
local sorted = {}
for _, kind in ipairs(ClearcutMode.SCORE_RAIN_KINDS) do sorted[#sorted+1] = kind end
table.sort(sorted, function(a, b) return a.maxDuration < b.maxDuration end)
for i = 2, #sorted do
    assert(sorted[i].warn > sorted[i-1].warn,
        "센 비의 경고가 더 길지 않다 — 경고로 세기를 읽을 수 없다")
    assert(sorted[i].minDuration >= sorted[i-1].maxDuration,
        "세기 구간이 겹친다 — 경고가 지속시간을 알려주지 못한다")
end

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

local STEP = 1/60
local function advance(seconds)
    local left = seconds
    while left > 0 do
        local dt = math.min(STEP, left)
        mode:updateScoreRain(dt, game)
        left = left - dt
    end
end
-- 절대 시각이 아니라 각 구간이 실제로 몇 초 지속되는지를 잰다.
local function advanceTo(state, limit)
    local spent = 0
    while mode.disasterState ~= state do
        advance(STEP); spent = spent + STEP
        assert(spent <= limit, "구간 '" .. state .. "' 에 " .. limit .. "초 안에 도달하지 못했다")
    end
    return spent
end

-- 시작 직후에는 비가 오지 않는다. 첫 판 첫 1분은 배우는 구간이다.
mode:updateScoreRain(1, game)
assert(mode.disasterState == "idle" and not mode.rainSuppressFire, "시작하자마자 비가 온다")

local untilWarn = advanceTo("warn", 200)
assert(untilWarn >= ScoreWorldTree.INTERVAL, "첫 비가 첫 세계수보다 먼저 왔다")
assert(mode.disasterType == "rain", "예고된 재해가 비가 아니다")
assert(mode.scoreRainKind, "비의 세기가 정해지지 않았다")
assert(not mode.rainSuppressFire and burning.burning, "경고 단계에서 이미 불이 꺼졌다")

local warnLength = advanceTo("active", 20)
assert(math.abs(warnLength - mode.scoreRainKind.warn) <= STEP * 2,
    "경고 길이가 세기와 다르다: " .. warnLength)
assert(mode.rainSuppressFire, "비가 오는데 점화 억제가 걸리지 않았다")
assert(not burning.burning and burning.burnTimer == nil and burning.fireTickTimer == nil,
    "비가 오는데 타던 나무가 그대로다")

local rainLength = advanceTo("cooldown", 20)
assert(rainLength <= ClearcutMode.SCORE_RAIN_MAX_DURATION + STEP * 2,
    "비가 상한 5초를 넘겼다: " .. rainLength)
assert(not mode.rainSuppressFire, "비가 그쳤는데 점화 억제가 남아 있다")

-- 비가 오는 동안에는 화면에 화염이 하나도 남지 않고 화염 피해가 전부 멎어야 한다.
-- 점화 경로를 하나씩 막는 방식은 화염원이 늘 때마다 빠뜨리므로 여기서 전부 본다.
do
    local wet = ClearcutMode.new()
    wet.scoreAttack = true
    wet.rainSuppressFire = true
    wet.enemies = {{x = 0, y = 0, hp = 10, burning = true, burnTimer = .3, fireTickTimer = .1}}
    wet.oilTrail = {{x = 0, y = 0, ignited = true, ignitedAt = 0, tickTimer = .1}}
    wet.oilDrumSpills = {{group = "g", ignited = true, ignitedAge = 1}}
    wet.oilPuddleGroups = {g = {id = "g", ignited = true, tickTimer = .1, spots = {}}}
    wet.strawBales = {{x = 0, y = 0, ignited = true, ignitedAt = 0, tickTimer = .1}}
    wet.flameStream = {x = 0, y = 0, nx = 1, ny = 0, reach = 250, halfWidth = 72, t = 1}
    wet.emberArrivals = {{x = 0, y = 0}}
    wet.treeSparks = {{x = 0, y = 0}}
    local tree = {x = 40, y = 0, burning = true, burnTimer = .5, fireTickTimer = .2, rushTree = true, active = true}
    local wetGame = {
        world = {nodes = {tree}, addParticle = function() end,
            particles = {{ember = true}, {ember = true}, {ember = nil}}},
        camera = {trauma = 0}, setNotice = function() end,
    }

    wet:extinguishAllFire(wetGame)

    assert(not tree.burning and tree.burnTimer == nil, "비가 오는데 나무가 계속 탄다")
    assert(not wet.enemies[1].burning, "비가 오는데 적이 계속 탄다")
    assert(wet.flameStream == nil, "비가 오는데 화염 기둥이 남아 있다")
    assert(not wet.oilTrail[1].ignited, "비가 오는데 기름 화염대가 남아 있다")
    assert(not wet.oilDrumSpills[1].ignited, "비가 오는데 기름 자국이 계속 탄다")
    assert(not wet.oilPuddleGroups.g.ignited, "비가 오는데 기름 웅덩이가 계속 탄다")
    assert(not wet.strawBales[1].ignited, "비가 오는데 짚단이 계속 탄다")
    assert(#wet.emberArrivals == 0 and #wet.treeSparks == 0, "비가 오는데 불씨 이펙트가 남아 있다")
    assert(#wetGame.world.particles == 1 and wetGame.world.particles[1].ember == nil,
        "비가 오는데 불티 파티클이 남아 있다")

    -- 점화 입구가 전부 막혀야 한다. 나무 점화는 beginTreeBurn 하나로 모인다.
    wet:beginTreeBurn(tree, 0)
    assert(not tree.burning, "비가 오는데 새로 불이 붙는다")
    wet:igniteNear({x = 0, y = 0, spreadDepth = 0}, wetGame, 200, 3, 0)
    assert(not tree.burning, "비가 오는데 연쇄 점화가 들어온다")
    local oilSpot = {x = 0, y = 0, ignited = false}
    wet.oilTrail = {oilSpot}
    wet:igniteOilTrail(oilSpot, wetGame)
    assert(not oilSpot.ignited, "비가 오는데 기름에 불이 붙는다")

    -- 화염방사기는 직접 피해까지 화염이다. 비 중에는 기둥도 판정도 없어야 한다.
    wet.permanentTraits.scoreFlameUnlock = 1
    local healthy = {x = 60, y = 0, rushTree = true, active = true, rushHp = 100, rushMaxHp = 100}
    wetGame.world.nodes = {healthy}
    wetGame.player = {x = 0, y = 0, facing = 1, gather = 1, isMoving = false}
    wetGame.tools = {axe = {speed = 1}}
    local fired = wet:updateFlamethrowerAttack(1/60, wetGame, true)
    assert(fired == false, "비가 오는데 화염방사기가 판정을 냈다")
    assert(wet.flameStream == nil, "비가 오는데 화염 기둥이 그려진다")
    assert(healthy.rushHp == 100, "비가 오는데 화염방사기 직접 피해가 들어갔다")
end

-- 그친 뒤에는 다시 불이 붙어야 한다. 억제가 남으면 판이 죽는다.
mode:beginTreeBurn(burning, 0)
assert(burning.burning, "비가 그친 뒤에도 점화가 막혀 있다")

-- 여러 바퀴를 돌려 간격과 지속시간이 실제로 흔들리는지, 그러면서도 경계를 지키는지 본다.
local gaps, durations, seen = {}, {}, {}
local previousHeavy = false
for _ = 1, 60 do
    advanceTo("idle", 20)
    assert(mode.disasterType == nil and mode.scoreRainKind == nil, "비 종료 후 상태가 남아 있다")
    local gap = advanceTo("warn", 400)
    local floor = previousHeavy and ClearcutMode.SCORE_RAIN_HEAVY_GAP or ClearcutMode.SCORE_RAIN_MIN_GAP
    assert(gap >= floor - STEP * 2, "비 간격이 하한보다 짧다: " .. gap .. " < " .. floor)
    assert(gap <= ClearcutMode.SCORE_RAIN_MAX_GAP + STEP * 2, "비 간격이 상한을 넘었다: " .. gap)
    gaps[#gaps+1] = gap

    advanceTo("active", 20)
    local kind = mode.scoreRainKind
    seen[kind.id] = (seen[kind.id] or 0) + 1
    previousHeavy = kind.heavy and true or false
    local length = advanceTo("cooldown", 20)
    assert(length <= ClearcutMode.SCORE_RAIN_MAX_DURATION + STEP * 2, "비가 상한을 넘겼다: " .. length)
    assert(length >= kind.minDuration - STEP * 2, "비가 세기의 하한보다 짧다: " .. length)
    durations[#durations+1] = length
end

local function spread(list)
    local low, high = list[1], list[1]
    for _, v in ipairs(list) do low = math.min(low, v); high = math.max(high, v) end
    return high - low
end
assert(spread(gaps) > 20, "비 간격이 사실상 고정이다 — 세어서 대비할 수 있다")
assert(spread(durations) > 1, "비 지속시간이 사실상 고정이다")
for _, kind in ipairs(ClearcutMode.SCORE_RAIN_KINDS) do
    assert((seen[kind.id] or 0) > 0, kind.id .. " 가 60번 중 한 번도 나오지 않았다")
end

-- 캠페인 재해는 기록 모드에 들어오지 않는다.
for _, text in ipairs(notices) do
    assert(not text:find("지진") and not text:find("가지"), "기록 모드에 캠페인 재해 안내가 뜬다: " .. text)
end

-- 캠페인 쪽 경로는 건드리지 않았다.
local campaign = ClearcutMode.new()
campaign.stage = 1
campaign:updateDisasters(1, game)
assert(campaign.disasterTimer == 150, "1스테이지 캠페인에서 재해 타이머가 흘렀다")
assert(campaign.scoreRainKind == nil, "캠페인이 기록 모드 비 경로로 흘렀다")

print("PASS score rain")
