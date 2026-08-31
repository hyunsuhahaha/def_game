-- 문맥 자동 무기 3종(담배·도끼·폭죽)의 영구 특성 회귀 검사.
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
    graphics = {
        getDimensions = function() return 1600, 900 end, newQuad = function() return {} end,
        newImage = function() return {setFilter = function() end,
            getWidth = function() return 768 end, getHeight = function() return 256 end,
            getDimensions = function() return 768, 256 end} end,
    },
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
axe.permanentTraits.treeDamage = 5
-- 도끼 타격은 스윙 애니메이션의 접촉 프레임에서 해결된다(AGENTS.md의 타격 판정 규칙).
-- 그래서 한 번 부르는 것으로는 피해가 들어가지 않고, 접촉 시점까지 굴려야 한다.
local function swing(mode, world)
    mode:updateHeldAxe(1, world, true)
    for _ = 1, 240 do
        if not mode.scoreAxeAction then break end
        mode:updateScoreAxeAction(1 / 60, world)
    end
end
local axeWorld = axeGame(trees)
swing(axe, axeWorld)
local hit = 0
for _, node in ipairs(trees) do if node.rushHp < 500 then hit = hit + 1 end end
assert(hit == 3, "동시 타격 나무 +2가 실제 타격으로 이어지지 않았다 (맞은 나무 " .. hit .. ")")
assert(trees[1].rushHp == 491, "도끼 피해가 기본 4+나무 피해 5로 계산되지 않았다")

-- 담배용 착화 범위(area)만 올려도 도끼 범위는 넓어지지 않아야 한다.
local narrow = ClearcutMode.new()
narrow.scoreAttack, narrow.sandbox, narrow.job, narrow.mapId = true, true, "fire", "forest"
narrow.permanentTraits.area = 400
local far = {tree(0), tree(150)}
swing(narrow, axeGame(far))
assert(far[2].rushHp == 500, "담배용 착화 범위가 아직 도끼 타격 범위를 넓히고 있다")

-- 6. 폭죽이 전용 반경·피해·비행 속도를 쓴다.
local rocketGame = axeGame({})
rocketGame.camera = {screenToWorld = function() return 600, 0 end}
local rocket = ClearcutMode.new()
rocket.scoreAttack, rocket.sandbox, rocket.job, rocket.mapId = true, true, "fire", "forest"
rocket.permanentTraits.scoreRocketRadius, rocket.permanentTraits.scoreRocketDamage = 80, 10
rocket.permanentTraits.scoreRocketSpeed, rocket.permanentTraits.treeDamage = 0.48, 5
rocket.permanentTraits.scoreRocketUnlock = 1
rocket.smokerWeaponCooldown = 0
assert(rocket:updateHeldAxe(1, rocketGame, true), "원거리 문맥이 폭죽을 발사하지 않았다")
local shot = rocket.smokerWeaponProjectiles[1]
assert(shot.radius == 260, "폭죽 폭발 반경이 전용 수치를 쓰지 않는다 (" .. shot.radius .. ")")
assert(math.abs(shot.damage - (8 + 5 * 1.1 + 10)) < 1e-9, "폭죽 폭발 피해가 전용 수치를 더하지 않는다")

local slowRocket = ClearcutMode.new()
slowRocket.scoreAttack, slowRocket.sandbox, slowRocket.job, slowRocket.mapId = true, true, "fire", "forest"
slowRocket.permanentTraits.scoreRocketUnlock = 1
slowRocket.smokerWeaponCooldown = 0
slowRocket:updateHeldAxe(1, rocketGame, true)
assert(slowRocket.smokerWeaponProjectiles[1].dur > shot.dur, "폭죽 비행 속도 특성이 도달 시간을 줄이지 않는다")

-- 7. 상시 흡연은 루트 직후, 그 뒤 자동 투척 → 폭죽 순서로 이어진다.
assert(nodeOf("fire_score_alwayssmoke").requires[1][1] == "fire_score_prewarm",
    "상시 흡연이 루트 바로 다음 두 번째 노드가 아니다")
assert(nodeOf("fire_score_autothrow").requires[1][1] == "fire_score_alwayssmoke",
    "담배 자동 투척이 상시 흡연 다음 노드가 아니다")
assert(nodeOf("fire_score_rocket_unlock").requires[1][1] == "fire_score_autothrow",
    "폭죽 해금이 담배 자동 투척 다음 노드가 아니다")
for _, id in ipairs({"fire_score_rocket_radius", "fire_score_rocket_damage"}) do
    assert(nodeOf(id).requires[1][1] == "fire_score_rocket_unlock", id .. "가 폭죽 해금 뒤에 있지 않다")
end

-- 8. 폭죽은 해금 전에는 원거리 문맥을 차지하지 않는다.
local locked = ClearcutMode.new()
locked.scoreAttack, locked.sandbox, locked.job, locked.mapId = true, true, "fire", "forest"
assert(locked:scoreRangedWeaponId()=="cigarette","폭죽 해금 전에 원거리 담배가 사라졌다")
assert(not locked:scoreWeaponUnlocked(3),"폭죽이 영구 연구 없이 열린다")
locked.permanentTraits.scoreRocketUnlock = 1
assert(locked:scoreWeaponUnlocked(3)and locked:scoreRangedWeaponId()=="firework",
    "폭죽 해금 뒤 원거리 공격이 자동 전환되지 않는다")

-- 9. 자동 투척은 특성을 사야 돌고, 어떤 무기를 들고 있든 꽁초가 나간다.
local autoGame = axeGame({tree(120)})
local auto = ClearcutMode.new()
auto.scoreAttack, auto.sandbox, auto.job, auto.mapId = true, true, "fire", "forest"
auto:updateFire(3, autoGame)
assert(#auto.molotovs == 0, "자동 투척 특성 없이 꽁초가 날아갔다")
auto.permanentTraits.scoreAutoThrow = 1
auto:updateFire(3, autoGame)
assert(#auto.molotovs > 0, "담배 자동 투척 특성이 자동 투척을 켜지 않는다")

-- 10. 상시 흡연은 문맥상 도끼가 선택된 동안에도 재장전을 진행한다.
local swap = ClearcutMode.new()
swap.scoreAttack, swap.sandbox, swap.job, swap.mapId = true, true, "fire", "forest"
local swapGame = axeGame({tree(120)})
swap.smoking={phase="reload",t=0,dur=2,loaded=false}
swap.scoreMeleeTargetAtAim=function()return true end
swap.updateScoreAxeAttack=function()return false end
for _ = 1, 60 do swap:updateHeldAxe(1 / 60, swapGame, true) end
assert(swap.smoking.phase == "reload" and swap.smoking.t == 0,
    "상시 흡연 특성 없이도 도끼질 중 담배가 재장전된다")
swap.permanentTraits.scoreAlwaysSmoking = 1
for _ = 1, 130 do swap:updateHeldAxe(1 / 60, swapGame, true) end
assert(swap.smoking.phase == "loaded",
    "상시 흡연을 샀는데 도끼질 중 담배 재장전이 멈춘다")

-- 11. 공용 단어를 쓴 수치는 실제로 3무기 전부에 걸려야 한다. `공격속도 상승` 카드는
-- 이름이 공용인데 담배 쿨다운만 읽고 있었다 — 도끼를 든 초반에는 죽은 카드였다.
local function axeCooldownWith(cardLevel)
    local m = ClearcutMode.new()
    m.scoreAttack, m.sandbox, m.job, m.mapId = true, true, "fire", "forest"
    m.levels.score_attack_speed = cardLevel
    m:updateHeldAxe(1, axeGame({tree(0)}), true)
    return m.axeCooldown
end
assert(axeCooldownWith(3) < axeCooldownWith(0),
    "공격속도 상승 카드가 도끼를 빠르게 하지 않는다 — 공용 이름인데 담배 전용이다")

local function rocketCooldownWith(cardLevel)
    local m = ClearcutMode.new()
    m.scoreAttack, m.sandbox, m.job, m.mapId = true, true, "fire", "forest"
    m.permanentTraits.scoreRocketUnlock = 1
    m.levels.score_attack_speed,m.smokerWeaponCooldown=cardLevel,0
    local g = axeGame({})
    g.camera = {screenToWorld = function() return 600, 0 end}
    m:updateHeldAxe(1, g, true)
    return m.smokerWeaponCooldown
end
assert(rocketCooldownWith(3) < rocketCooldownWith(0),
    "공격속도 상승 카드가 폭죽을 빠르게 하지 않는다")

-- `무기 피해`도 공용 이름이므로 불의 타격 피해에도 더해져야 한다.
local function burnTotalWith(treeDamage)
    local m = ClearcutMode.new()
    m.scoreAttack, m.sandbox, m.job, m.mapId = true, true, "fire", "forest"
    m.permanentTraits.treeDamage = treeDamage
    local node = {kind = "tree", rushTree = true, active = true, x = 0, y = 0, rushHp = 9999, rushMaxHp = 9999}
    local g = {player = {x = 0, y = 0},
        world = {nodes = {node}, igniteFx = function() end, impactNode = function() end},
        setNotice = function() end}
    m.fellTree = function(_, t) t.active = false; return true end
    m:beginTreeBurn(node, 0)
    for _ = 1, 600 do
        if not node.burning then break end
        m:updateFire(1 / 60, g)
    end
    return 9999 - node.rushHp
end
assert(burnTotalWith(5) > burnTotalWith(0),
    "무기 피해가 불의 타격 피해에 더해지지 않는다 — 공용 이름인데 도끼·폭죽 전용이다")

-- 12. 수동 핫바·장비 인벤토리는 활성 모드에서 제거됐다.
local hud = ClearcutMode.new()
hud.scoreAttack, hud.sandbox, hud.job, hud.mapId = true, true, "fire", "forest"
assert(hud.drawScoreWeaponSlots==nil and hud.setScoreWeaponSlot==nil and hud.toggleCompanionInventory==nil,
    "문맥 자동 무기 전환 뒤에도 수동 장비 UI가 남아 있다")

-- 13. 도끼 상위 갈래는 기본 도끼의 하드캡(동시 타격 3그루)을 밀도에 비례하게 푼다.
assert(nodeOf("fire_score_axe_shock").requires[1][1] == "fire_score_axe_targets",
    "도끼 충격파가 기본 도끼 갈래 뒤에 있지 않다")
assert(nodeOf("fire_score_axe_chain").requires[1][1] == "fire_score_axe_execute",
    "연속 벌목이 기본 도끼 갈래 뒤에 있지 않다")

local shockMode = ClearcutMode.new()
shockMode.scoreAttack, shockMode.sandbox, shockMode.job, shockMode.mapId = true, true, "fire", "forest"
shockMode.permanentTraits.scoreAxeShock = 3
local ring = {tree(0), tree(60), tree(120)}
for _, node in ipairs(ring) do node.rushHp, node.rushMaxHp = 40, 40 end
local shockGame = axeGame(ring)
shockMode:axeShockwave(0, 0, 3, shockGame)
assert(ring[2].rushHp < 40 and ring[3].rushHp < 40,
    "도끼 충격파가 쓰러진 자리 주변 나무를 때리지 않는다")

-- 14. 나무꾼 고용은 도끼 상위 갈래를 다 찍어야 열리고, 실제 동료를 합류시킨다.
local crew = nodeOf("fire_score_axe_crew")
local crewReq = {}
for _, r in ipairs(crew.requires) do crewReq[r[1]] = r[2] end
assert(crewReq.fire_score_axe_shock == 3 and crewReq.fire_score_axe_chain == 3,
    "나무꾼 고용이 도끼 상위 갈래 만렙을 요구하지 않는다")
assert(crew.costs[1] > nodeOf("fire_score_axe_shock").costs[3],
    "나무꾼 고용이 상위 강화보다 싸다 — 졸업 보상이 가장 비싸야 한다")

local crewGame = axeGame({})
crewGame.world.width, crewGame.world.height = 3000, 3000
local hire = ClearcutMode.new()
hire.scoreAttack, hire.sandbox, hire.job, hire.mapId = true, true, "fire", "forest"
hire.permanentTraits.treeDamage = 5
assert(hire:initLumberjackCompanion(crewGame), "나무꾼 동료가 합류하지 않았다")
local jack = hire.moleCompanions[1]
assert(jack.kind == "lumberjack", "합류한 동료가 나무꾼이 아니다")
assert(jack.damage == 5, "나무꾼 피해가 내 도끼(4+5=9)의 절반이 아니다 (" .. jack.damage .. ")")

-- 두더지는 자기 갈래로 따로 자라는 독립 유닛이고, 나무꾼은 내 도끼 빌드의 복제다.
-- 충격파·밑동 절단·연속 벌목을 물려받지 않으면 두더지와 스프라이트만 다른 같은 유닛이 된다.
local built = ClearcutMode.new()
built.scoreAttack, built.sandbox, built.job, built.mapId = true, true, "fire", "forest"
built.permanentTraits.treeDamage = 5
built.permanentTraits.scoreAxeShock = 3
built.permanentTraits.scoreAxeExecute = .12
built.permanentTraits.scoreAxeChain = .54
assert(built:initLumberjackCompanion(crewGame), "나무꾼 동료가 합류하지 않았다")
local skilled = built.moleCompanions[1]
assert(skilled.shockLevel == 3 and math.abs(skilled.executeChance - .12) < 1e-9
    and math.abs(skilled.chainChance - .54) < 1e-9,
    "나무꾼이 내 도끼 빌드(충격파·밑동 절단·연속 벌목)를 물려받지 않았다")

local plain = ClearcutMode.new()
plain.scoreAttack, plain.sandbox, plain.job, plain.mapId = true, true, "fire", "forest"
plain:initLumberjackCompanion(crewGame)
assert(plain.moleCompanions[1].shockLevel == 0,
    "도끼 상위 갈래를 안 찍었는데 나무꾼이 충격파를 쓴다")

print("SCORE_WEAPON_TRAITS_OK shared=tree_damage axe=area+speed+targets+execute rocket=radius+damage+speed+ignite+cooldown")
