-- 무기 슬롯 3종(담배·도끼·폭죽)의 영구 특성 회귀 검사.
--
-- 무기 슬롯이 생기기 전 기록 모드 특성은 전부 담배 전용이었다. 그래서
--   * 도끼(3+treeDamage)와 폭죽(8+treeDamage*1.1)의 주력 수치인 treeDamage에
--     노드가 하나도 없어 두 무기의 피해가 영구히 고정이었고,
--   * 도끼/폭죽 범위는 담배용 착화 범위(area)를 ×0.2, ×0.3으로 얻어 써서
--     담배 특성을 사야 다른 무기가 자라는 기묘한 의존이 있었으며,
--   * 폭죽 비행 속도(820)와 착탄 점화 확률(0.38)은 상수로 박혀 성장이 불가능했다.
--
-- 이 검사는 세 무기가 각자의 성장 경로를 갖고, 서로의 수치를 훔쳐 쓰지 않는지 고정한다.
package.path = "./?.lua;./?/init.lua;" .. package.path

love = {
    math = {random = math.random}, filesystem = {},
    graphics = {getDimensions = function() return 1600, 900 end},
    mouse = {getPosition = function() return 0, 0 end, isDown = function() return true end},
    keyboard = {isDown = function() return false end},
}

local CharacterTraits = require("src.character_traits")
local ClearcutMode = require("src.clearcut_mode")

local store = CharacterTraits.new(true)
local function nodeOf(id) return assert(CharacterTraits:getNode(id), id .. " 특성이 없다") end

-- 1. 무기별 갈래가 실제로 존재한다.
local axeNodes = {"fire_score_axe_area", "fire_score_axe_speed", "fire_score_axe_targets", "fire_score_axe_execute"}
local rocketNodes = {"fire_score_rocket_radius", "fire_score_rocket_damage", "fire_score_rocket_speed",
    "fire_score_rocket_ignite", "fire_score_rocket_cooldown"}
for _, id in ipairs(axeNodes) do assert(nodeOf(id).scoreMode, id .. "가 기록 모드 연구판에 없다") end
for _, id in ipairs(rocketNodes) do assert(nodeOf(id).scoreMode, id .. "가 기록 모드 연구판에 없다") end
assert(nodeOf("fire_score_edge").effect == "scoreTreeDamage", "공용 나무 피해 노드가 treeDamage를 올리지 않는다")

-- 2. 공용 수치의 설명에는 무기 이름을 나열하지 않는다. "담배·도끼·폭죽의 사거리"처럼
-- 적으면 무기가 늘거나 바뀔 때마다 설명을 전부 고쳐야 하므로, "무기 사거리"처럼 공용
-- 단어만 쓴다. 특정 무기에만 걸리는 수치는 그 무기 이름을 쓰는 게 맞으므로 제외한다.
local sharedNodes = {"fire_score_filter", "fire_score_drag", "fire_score_edge"}
for _, id in ipairs(sharedNodes) do
    local desc = nodeOf(id).desc
    for _, weapon in ipairs({"담배", "도끼", "폭죽", "꽁초", "로켓"}) do
        assert(not desc:find(weapon, 1, true),
            id .. " 공용 설명이 무기 이름 '" .. weapon .. "'을 하드코딩했다: " .. desc)
    end
    assert(desc:find("무기", 1, true), id .. " 공용 설명이 공용 단어 '무기'를 쓰지 않는다")
end

-- 3. 만렙 효과가 실제 수치로 합산된다.
for _, id in ipairs({"fire_score_edge", "fire_score_axe_area", "fire_score_axe_speed", "fire_score_axe_targets",
    "fire_score_axe_execute", "fire_score_rocket_radius", "fire_score_rocket_damage", "fire_score_rocket_speed",
    "fire_score_rocket_ignite", "fire_score_rocket_cooldown"}) do
    store.data.levels[id] = nodeOf(id).max
end
local effects = store:scoreAttackEffects()
assert(effects.scoreTreeDamage == 5, "공용 나무 피해 만렙이 +5가 아니다")
assert(effects.scoreAxeArea == 45 and effects.scoreAxeTargets == 2, "도끼 갈래 만렙 수치가 어긋난다")
assert(effects.scoreRocketRadius == 80 and effects.scoreRocketDamage == 10, "폭죽 갈래 만렙 수치가 어긋난다")

-- 4. 런타임이 공용 키를 실제 전투 수치로 접어 넣는다.
local mode = ClearcutMode.new()
mode.scoreAttack, mode.sandbox, mode.job, mode.mapId = true, true, "fire", "forest"
for key, value in pairs(effects) do mode.permanentTraits[key] = value end
mode.permanentTraits.treeDamage = (mode.permanentTraits.treeDamage or 0) + effects.scoreTreeDamage
mode.permanentTraits.extraTargets = (mode.permanentTraits.extraTargets or 0) + effects.scoreAxeTargets
mode.permanentTraits.executeChance = (mode.permanentTraits.executeChance or 0) + effects.scoreAxeExecute
assert(mode.permanentTraits.treeDamage == 5, "나무 피해가 treeDamage로 합쳐지지 않았다")
assert(mode.permanentTraits.extraTargets == 2, "동시 타격이 extraTargets로 합쳐지지 않았다")
assert(math.abs(mode.permanentTraits.executeChance - .12) < 1e-9, "밑동 절단 확률이 executeChance로 합쳐지지 않았다")

-- 5. 도끼가 실제로 여러 나무를 때리고, 담배용 착화 범위에 의존하지 않는다.
local function axeGame(trees)
    return {
        player = {x = 0, y = 0, facing = 1, gather = 1, axeHolding = false,
            cancelInteraction = function() end, playAutoAxeSwing = function() end},
        camera = {screenToWorld = function() return 0, 0 end},
        world = {nodes = trees, impactNode = function() end},
        tools = {axe = {speed = 1}}, setNotice = function() end,
    }
end
local function tree(x) return {rushTree = true, active = true, x = x, y = 0, rushHp = 500, rushMaxHp = 500} end

local trees = {tree(0), tree(40), tree(80)}
local axe = ClearcutMode.new()
axe.scoreAttack, axe.sandbox, axe.job, axe.mapId = true, true, "fire", "forest"
axe.permanentTraits.scoreAxeArea, axe.permanentTraits.extraTargets = 45, 2
axe.permanentTraits.treeDamage, axe.scoreWeaponSlot = 5, 2
assert(axe:updateHeldAxe(1, axeGame(trees), true), "도끼 슬롯이 타격하지 않았다")
local hit = 0
for _, node in ipairs(trees) do if node.rushHp < 500 then hit = hit + 1 end end
assert(hit == 3, "동시 타격 나무 +2가 실제 타격으로 이어지지 않았다 (맞은 나무 " .. hit .. ")")
assert(trees[1].rushHp == 491, "도끼 피해가 기본 4+나무 피해 5로 계산되지 않았다")

-- 담배용 착화 범위(area)만 올려도 도끼 범위는 넓어지지 않아야 한다.
local narrow = ClearcutMode.new()
narrow.scoreAttack, narrow.sandbox, narrow.job, narrow.mapId = true, true, "fire", "forest"
narrow.permanentTraits.area, narrow.scoreWeaponSlot = 400, 2
local far = {tree(0), tree(150)}
narrow:updateHeldAxe(1, axeGame(far), true)
assert(far[2].rushHp == 500, "담배용 착화 범위가 아직 도끼 타격 범위를 넓히고 있다")

-- 6. 폭죽이 전용 반경·피해·비행 속도를 쓴다.
local rocketGame = axeGame({})
rocketGame.camera = {screenToWorld = function() return 600, 0 end}
local rocket = ClearcutMode.new()
rocket.scoreAttack, rocket.sandbox, rocket.job, rocket.mapId = true, true, "fire", "forest"
rocket.permanentTraits.scoreRocketRadius, rocket.permanentTraits.scoreRocketDamage = 80, 10
rocket.permanentTraits.scoreRocketSpeed, rocket.permanentTraits.treeDamage = 0.48, 5
rocket.permanentTraits.scoreRocketUnlock = 1
rocket.scoreWeaponSlot, rocket.smokerWeaponCooldown = 3, 0
assert(rocket:updateHeldAxe(1, rocketGame, true), "폭죽 슬롯이 발사하지 않았다")
local shot = rocket.smokerWeaponProjectiles[1]
assert(shot.radius == 260, "폭죽 폭발 반경이 전용 수치를 쓰지 않는다 (" .. shot.radius .. ")")
assert(math.abs(shot.damage - (8 + 5 * 1.1 + 10)) < 1e-9, "폭죽 폭발 피해가 전용 수치를 더하지 않는다")

local slowRocket = ClearcutMode.new()
slowRocket.scoreAttack, slowRocket.sandbox, slowRocket.job, slowRocket.mapId = true, true, "fire", "forest"
slowRocket.permanentTraits.scoreRocketUnlock = 1
slowRocket.scoreWeaponSlot, slowRocket.smokerWeaponCooldown = 3, 0
slowRocket:updateHeldAxe(1, rocketGame, true)
assert(slowRocket.smokerWeaponProjectiles[1].dur > shot.dur, "폭죽 비행 속도 특성이 도달 시간을 줄이지 않는다")

-- 7. 후반 해금 순서: 담배 자동 투척 → 그 다음 노드가 폭죽 해금.
assert(nodeOf("fire_score_alwayssmoke").requires[1][1] == "fire_score_stock",
    "상시 흡연이 담배 갈래 끝에 붙어 있지 않다")
assert(nodeOf("fire_score_autothrow").requires[1][1] == "fire_score_alwayssmoke",
    "담배 자동 투척이 상시 흡연 다음 노드가 아니다")
assert(nodeOf("fire_score_rocket_unlock").requires[1][1] == "fire_score_autothrow",
    "폭죽 해금이 담배 자동 투척 다음 노드가 아니다")
for _, id in ipairs({"fire_score_rocket_radius", "fire_score_rocket_damage"}) do
    assert(nodeOf(id).requires[1][1] == "fire_score_rocket_unlock", id .. "가 폭죽 해금 뒤에 있지 않다")
end

-- 8. 폭죽 슬롯은 해금 전에는 선택되지 않는다.
local locked = ClearcutMode.new()
locked.scoreAttack, locked.sandbox, locked.job, locked.mapId = true, true, "fire", "forest"
assert(locked:setScoreWeaponSlot(2), "도끼 슬롯은 해금 없이 열려 있어야 한다")
assert(not locked:setScoreWeaponSlot(3) and locked:scoreWeaponId() == "axe",
    "폭죽이 영구 연구 없이 선택된다")
locked.permanentTraits.scoreRocketUnlock = 1
assert(locked:setScoreWeaponSlot(3) and locked:scoreWeaponId() == "firework",
    "폭죽 해금을 사도 슬롯이 열리지 않는다")

-- 9. 자동 투척은 특성을 사야 돌고, 어떤 무기를 들고 있든 꽁초가 나간다.
local autoGame = axeGame({tree(120)})
local auto = ClearcutMode.new()
auto.scoreAttack, auto.sandbox, auto.job, auto.mapId = true, true, "fire", "forest"
auto.scoreWeaponSlot = 2
auto:updateFire(3, autoGame)
assert(#auto.molotovs == 0, "자동 투척 특성 없이 꽁초가 날아갔다")
auto.permanentTraits.scoreAutoThrow = 1
auto:updateFire(3, autoGame)
assert(#auto.molotovs > 0, "담배 자동 투척 특성이 자동 투척을 켜지 않는다")

-- 10. 인벤토리로 담배를 잠깐 바꿔 들고 바로 던질 수 있어야 한다.
-- 도끼를 든 동안에도 담배 재장전이 흘러야 슬롯 전환이 "휙"이 된다.
local swap = ClearcutMode.new()
swap.scoreAttack, swap.sandbox, swap.job, swap.mapId = true, true, "fire", "forest"
local swapGame = axeGame({tree(120)})
swap.scoreWeaponSlot = 1
swap:updateHeldAxe(0, swapGame, false)
-- 기본은 담배를 들어야만 피운다. 도끼를 들면 재장전이 멈춰 있어야 한다.
local stalled = swap.smoking.t
swap:setScoreWeaponSlot(2, swapGame)
for _ = 1, 200 do swap:updateHeldAxe(1 / 60, swapGame, false) end
assert(swap.smoking.phase == "reload" and swap.smoking.t == stalled,
    "상시 흡연 특성 없이도 다른 무기를 든 채 담배가 재장전된다")
swap.permanentTraits.scoreAlwaysSmoking = 1
swap:setScoreWeaponSlot(1, swapGame)
swap:updateHeldAxe(0, swapGame, false)
assert(swap.smoking and swap.smoking.phase == "reload", "담배를 들었는데 재장전이 시작되지 않았다")
swap:setScoreWeaponSlot(2, swapGame)
for _ = 1, 200 do swap:updateHeldAxe(1 / 60, swapGame, false) end
assert(swap.smoking.phase == "loaded",
    "도끼를 드는 동안 담배 재장전이 멈춰 있다 — 슬롯을 바꿔도 바로 던질 수 없다")
swap:setScoreWeaponSlot(1, swapGame)
assert(swap:updateHeldAxe(1 / 60, swapGame, true) == false and swap.smoking.phase == "flick",
    "슬롯을 담배로 되돌린 직후 투척 동작이 바로 시작되지 않았다")

print("SCORE_WEAPON_TRAITS_OK shared=tree_damage axe=area+speed+targets+execute rocket=radius+damage+speed+ignite+cooldown")
