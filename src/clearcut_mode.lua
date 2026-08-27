local UI = require("src.ui")
local TraitFx = require("src.trait_fx")
local Cigarette = require("src.cigarette_sprite")
local CigaretteButts = require("src.cigarette_butts")
local CigaretteButtArt = require("src.cigarette_butt_art")
local OilTrailArt = require("src.oil_trail_art")
local StrawBaleArt = require("src.straw_bale_art")
local MoleBurrowArt = require("src.mole_burrow_art")
local BruteForceArt = require("src.brute_force_art")
local MoleClawArt = require("src.mole_claw_art")
local ForestArt = require("src.forest_arcade_art")
local ForestScenery = require("src.forest_scenery")
local Fusions = require("src.clearcut_fusions")
local BiomeEnemies = require("src.biome_enemies")
local SupplementArt = require("src.supplement_art")

local ClearcutMode = {}
ClearcutMode.__index = ClearcutMode

local trackLabels = {destroy = "파괴력", spread = "확산력", suppress = "억제력", develop = "개발력", dig = "굴착력", venom = "독설력", supplement = "보조력"}

-- 시그니처 업그레이드를 처음 고르면 1차 전직이 확정되고 기본 공격 자체가 바뀐다.
local jobFor = {berserker = "physical", molotov = "fire", toxic_rain = "toxic", heavy_machinery = "developer", detector = "miner", monologue = "philosopher"}
local jobNames = {physical = "생계형 나무꾼", fire = "흡연자", toxic = "비건 단체 회장", developer = "부동산 개발업자", miner = "코인 채굴꾼", philosopher = "차라투스트라는 이렇게 말했다"}
local jobDesc = {
    physical = "그냥 오늘 할당량을 채우러 왔을 뿐이다. 대출은 갚아야 하니까.",
    fire = "마우스 위치에 꽁초를 튕깁니다. 꽁초는 바닥에 남아 타들어가며 주변 나무로 기본 42%(최대 75%) 확률로 불씨를 옮깁니다. 착지 즉시 불붙지는 않습니다.",
    toxic = "기본 공격이 도끼질 대신 마우스 위치에 '친환경' 제초제를 살포하는 것으로 바뀝니다. 숲을 지키기 위해 숲을 없앤다.",
    developer = "기본 공격이 도끼질 대신 마우스 방향으로 중장비 돌진하는 것으로 바뀝니다. 여기에 아파트 지으면 됨.",
    miner = "거대한 발톱으로 전방을 할퀴고, 땅속에 잠복해 지나치는 나무를 뿌리째 뽑아 던집니다.",
    philosopher = "기본 공격이 도끼질 대신 마우스 방향으로 끝없는 일장연설이 됩니다. 침이 사방으로 튀고, 말이 길어질수록 사거리와 독성이 강해집니다."
}

-- job이 있는 카드는 해당 전직에서만 뜨는 전직 전용 카드다. job이 없으면 모든 전직에 공용으로 뜬다.
local definitions = {
    -- 파괴력 (destroy) — 얼마나 빨리 없애느냐 [생계형 나무꾼 전용 + 공용]
    {id="wide_blade", track="destroy", name="야근 수당", desc="범위와 한 번에 타격하는 나무 수가 늘어납니다. 잔업은 곧 돈이다.", max=6, color={1,.62,.18}, job="physical"},
    {id="berserker", track="destroy", name="이번 달 목표 초과", desc="쉬지 않고 벨수록 공격 속도가 빨라집니다 (멈추면 초기화).", max=6, color={1,.42,.22}, job="physical"},
    {id="shockwave", track="destroy", name="산재 위험수당", desc="나무를 쓰러뜨리면 주변 나무에도 충격파 피해를 줍니다.", max=6, color={1,.78,.2}, job="physical"},
    -- 확산력 (spread) — 한 번의 행동으로 얼마나 넓게 없애느냐 [흡연자 전용]
    {id="molotov", track="spread", name="꽁초 투척", desc="사거리와 꽁초의 불씨 전이 범위가 늘어나고, 주기적으로 하나 더 튕깁니다. 바닥의 꽁초는 7초간 남아 주변 나무에 기본 42%(최대 75%) 확률로 불을 옮깁니다.", max=6, color={1,.35,.12}, job="fire"},
    {id="dry_forest", track="spread", name="건조주의보 무시", desc="꽁초의 착화 확률이 레벨당 +6%p 높아지고(최대 75%), 붙은 불이 주변 나무로 더 빠르고 넓게 번집니다.", max=6, color={1,.5,.15}, job="fire"},
    {id="oil_drum", track="spread", name="라이터 기름 유출", desc="나무가 다 타버리면 레벨당 폭발 확률이 크게 올라(1렙 7.5%→5렙 63%), 6렙에서는 100% 확정 발동합니다.", max=6, color={1,.62,.1}, job="fire"},
    {id="straw_bale", track="spread", name="마른 건초더미 생성", desc="주기적으로 주변에 마른 건초더미를 둡니다. 그 위에 담배꽁초를 던지면 0.5초 뒤 불이 붙어 주변 적에게 지속 피해를 줍니다. 불은 다른 대상으로 번지지 않습니다.", max=6, color={.85,.72,.25}, job="fire"},
    -- 억제력 (suppress) — 자연이 얼마나 다시 못 자라게 하느냐 [비건 단체 회장 전용 + 공용]
    {id="toxic_rain", track="suppress", name="친환경 제초 캠페인", desc="맹독 공격의 범위와 피해가 늘어나고, 평소에도 주변에 약하게 지속 피해를 줍니다.", max=6, color={.55,.85,.45}, job="toxic"},
    {id="forced_growth", track="suppress", name="강제 성장", desc="숲의 재생 속도가 크게 빨라지지만, 목재 경험치 획득량도 크게 늘어납니다.", max=6, color={.85,.7,.25}},
    -- 개발력 (develop) — 말뚝 → 중장비 → 폭파 [부동산 개발업자 전용]
    {id="pile_driving", track="develop", name="말뚝 박기", desc="돌진 사거리가 늘어나고 재사용 대기시간이 줄어듭니다.", max=6, color={.7,.62,.4}, job="developer"},
    {id="heavy_machinery", track="develop", name="중장비 투입", desc="돌진 경로의 폭이 넓어져 더 많은 나무를 밀어버립니다.", max=6, color={1,.72,.15}, job="developer"},
    {id="demolition", track="develop", name="철거 폭파", desc="돌진이 끝나는 지점에서 폭발이 일어나 주변 나무에도 피해를 줍니다.", max=6, color={1,.45,.15}, job="developer"},
    {id="site_clearance", track="develop", name="부지 정지 작업", desc="돌진이 지나간 자리는 다시는 나무가 자라지 않는 부지가 됩니다.", max=6, color={.55,.5,.55}, job="developer"},
    -- 굴착력 (dig) — 발톱 할퀴기와 지하 돌진으로 얼마나 거칠게 밀어내느냐 [코인 채굴꾼 전용]
    {id="detector", track="dig", name="손톱 강화 — 복리 발톱", desc="기본 할퀴기의 범위와 피해가 늘어납니다. 강화할수록 손톱 궤적이 길고 굵어지며, 3단계와 5단계에서 카툰 픽셀 잔상도 강해집니다.", max=6, color={.85,.68,.22}, job="miner"},
    {id="burrow_uproot", track="dig", name="지하 강제집행", desc="SPACE 또는 우클릭 잠복의 재사용 시간이 줄고, 이동 경로에서 자동으로 옆으로 튕겨 나가는 나무의 피해와 관통 횟수가 늘어납니다.", max=6, color={.58,.42,.24}, job="miner"},
    {id="brute_force", track="dig", name="브루트포스 어택", desc="지상에서 수많은 숫자 조합을 빠르게 생성한 뒤 사방으로 발사합니다. 날아간 숫자는 닿는 나무와 적에게 피해를 줍니다.", max=6, color={.3,.9,.4}, job="miner"},
    -- 독설력 (venom) — 말을 오래 붙잡을수록 사거리와 독성이 강해진다 [차라투스트라는 이렇게 말했다 전용]
    {id="monologue", track="venom", name="아무 말 대잔치", desc="기본 공격이 장광설로 바뀝니다. 마우스 방향으로 계속 침을 튀기며, 말이 길어질수록 사거리와 피해가 늘어납니다.", max=6, color={.75,.85,.3}, job="philosopher"},
    {id="footnote", track="venom", name="각주 남발", desc="말하는 속도가 빨라져 침이 더 자주 튑니다.", max=6, color={.85,.9,.4}, job="philosopher"},
    {id="loud_voice", track="venom", name="목청 키우기", desc="침이 닿는 범위가 넓어집니다.", max=6, color={.65,.8,.3}, job="philosopher"},
    {id="saliva_gland", track="venom", name="침샘 발달", desc="침에 맞은 대상은 서서히 중독되어 지속 피해를 입습니다.", max=6, color={.55,.72,.25}, job="philosopher"},
    -- 보조력 (supplement) — 기본 공격과 무관하게 알아서 나가는 공용 패시브 [전 직업 공용]
    {id="bat_swarm", track="supplement", name="박쥐 떼", desc="박쥐가 주위를 맴돌며 닿는 나무와 적에게 지속적으로 피해를 줍니다.", max=6, color={.55,.42,.72}},
    {id="thorn_aura", track="supplement", name="가시 오라", desc="몸 주위에 가시덩굴이 돋아나 주기적으로 주변 나무와 적에게 피해를 줍니다.", max=6, color={.42,.68,.32}},
    {id="crow_strike", track="supplement", name="까마귀 습격", desc="주기적으로 까마귀가 급강하해 사거리 내 가장 먼 나무나 적을 공격합니다.", max=6, color={.3,.28,.36}},
    {id="vine_whip", track="supplement", name="덩굴 채찍", desc="주기적으로 덩굴을 채찍처럼 휘둘러 가장 가까운 방향의 부채꼴 범위를 가격합니다.", max=6, color={.35,.55,.22}},
    {id="boomerang_axe", track="supplement", name="부메랑 도끼", desc="주기적으로 도끼가 날아가 나무와 적을 가르고 손으로 돌아옵니다.", max=6, color={.6,.6,.65}},
    {id="seed_mine", track="supplement", name="씨앗 지뢰", desc="주기적으로 씨앗 지뢰를 심습니다. 잠시 후 터져 주변 나무와 적에게 피해를 줍니다.", max=6, color={.65,.45,.2}},
    {id="chain_lightning", track="supplement", name="번개 사슬", desc="주기적으로 번개가 근처 나무·적 사이를 연쇄로 튀며 피해를 줍니다.", max=6, color={.35,.75,.95}},
}

local upgradeById = {}
for _, def in ipairs(definitions) do upgradeById[def.id] = def end
local recoveryChoice = {id="field_rest",name="현장 휴식",track="suppress",color={.4,.9,.6},
    desc="모든 남은 스킬을 마스터했습니다. 체력을 20 회복하고 계속합니다.",recovery=true}

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

for kind,def in pairs(BiomeEnemies.definitions) do enemyDefs[kind]=def end

local function formatTime(value)
    value = math.max(0, math.floor(value))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end

function ClearcutMode.new()
    return setmetatable({
        sandbox=false,
        levels={}, choices={}, level=1, xp=0, xpNext=10, pending=0,
        totalWood=0, treesFelled=0, elapsed=0, initialTrees=0, remainingTrees=0,
        maxMulti=1, maxChain=0, axeCooldown=0, axeRange=150, milestoneFired={},
        regrowTimer=0, regrowGrace=45, regrowInterval=7, regrowPulses=0, treesRevived=0, regrowFlash=0,
        rootHazards={}, rootedTimer=0, rootedCount=0,
        bees={}, beeSlow=false, beeSwarmsTriggered=0, beehiveTotal=0,
        streak=0, lastHitAt=-10, molotovTimer=0, wildfireTimer=0, toxicTimer=0, evolutions={}, molotovs={},
        cigaretteButts={}, emberTransfers={}, emberArrivals={}, smokerGroundTime=0,
        treeSparks={}, treeSparkArrivals={}, strawTimer=0, strawBales={}, strawBaleSequence=0,
        oilTrail={}, oilTrailTimer=0, oilTrailLastX=nil, oilTrailLastY=nil, oilTrailSequence=0,
        job=nil, attackCooldown=0, dashing=nil, dashTrail={}, smoking=nil,
        minerClawAction=nil, minerClawFx={}, minerClawMarks={}, minerBurrow=nil, minerBurrowCooldown=0, thrownTrees={}, burrowTracks={}, burrowTrackSequence=0,
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
        permanentTraits={
            attackSpeed=1, range=0, area=0, maxHp=0, reward=1,
            extraTargets=0, treeDamage=0, healOnFell=0, executeChance=0,
            burnSpeed=1, extraFires=0, spreadChance=0,
            biteDamage=0, plagueDuration=0,
            dashSpeed=1, sterileChance=0, aftershockRadius=0, cooldownRefund=0,
            moveSpeed=1, pickupRadius=0, hpRegen=0, reviveCharges=0
        },
        reviveCharges=0,
        vinePlantTimer=24, vineSpawns={},
        disasterState="idle", disasterTimer=75, disasterType=nil, rainSuppressFire=false, quakeShakes={},
        offscreenPulse=0,
        traitFx=TraitFx.new()
    }, ClearcutMode)
end

function ClearcutMode:levelOf(id) return self.levels[id] or 0 end
function ClearcutMode:getUpgradeDefinition(id) return upgradeById[id] end

-- 스킬 연습장 전용: 현재 직업이 실제로 쓸 수 있는 스킬(직업 전용 + 공용) 전체를 나열한다.
-- 만렙/배니시/카드 뽑기 같은 정상 진행 제약 없이 화면에서 바로 레벨을 조절하기 위한 목록이다.
function ClearcutMode:sandboxSkillList()
    local list = {}
    for _, def in ipairs(definitions) do
        if not def.job or def.job == self.job then list[#list + 1] = def end
    end
    return list
end

function ClearcutMode:sandboxSetLevel(id, delta)
    local def = upgradeById[id]
    if not def then return end
    self.levels[id] = math.max(0, math.min(def.max, self:levelOf(id) + delta))
end

-- 융합 스킬은 정상적으로는 재료 두 스킬을 만렙 찍고 3택 카드 화면에서 확정 획득해야
-- 하는데, 연습장은 그 카드 흐름 자체를 건너뛰므로(checkEvolutions가 절대 호출 안 됨)
-- 재료를 만렙 찍어도 자동으로 붙지 않는다. 그래서 배움 여부를 직접 켜고 끌 수 있게 한다.
function ClearcutMode:sandboxFusionList()
    return Fusions.forJob(self)
end

function ClearcutMode:sandboxToggleFusion(id)
    self.evolutions[id] = not self.evolutions[id]
end
-- 레벨→실질 파워 곡선 (만렙 3→6 확장에 맞춘 재설계).
-- 초반 픽은 완만하고, 3레벨이 옛 만렙과 거의 같고, 6레벨에서 옛 만렙의 약 1.87배로 마무리된다.
-- 파워 스케일링(범위/피해/사거리 등)엔 이걸 쓰고, "만렙에서만" 발동하는 보너스 판정은 levelOf(id)>=6으로 확인한다.
local levelCurve = {0, .5, 1.2, 2.0, 3.0, 4.2, 5.6}
function ClearcutMode:power(id)
    local lvl = self:levelOf(id)
    if lvl <= 0 then return 0 end
    if lvl >= 6 then return levelCurve[7] end
    local lo, hi = math.floor(lvl), math.ceil(lvl)
    if lo == hi then return levelCurve[lo + 1] end
    local frac = lvl - lo
    return levelCurve[lo + 1] + (levelCurve[hi + 1] - levelCurve[lo + 1]) * frac
end
-- 개수/횟수처럼 정수여야 하는 값용: 커브를 따르되 한 포인트라도 찍으면 최소 1은 보장한다
-- (그렇지 않으면 초반 커브 값이 1 미만이라 "찍었는데 아무 효과 없음"이 되어버린다).
function ClearcutMode:powerCount(id)
    if self:levelOf(id) <= 0 then return 0 end
    return math.max(1, math.floor(self:power(id)))
end
function ClearcutMode:pickupRadius() return 165 + self:power("magnet") * 95 + (self.permanentTraits.pickupRadius or 0) end
function ClearcutMode:pickupSpeed() return 15 + self:power("magnet") * 4 end
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
    if game.world.useArcadeForest then game.world:useArcadeForest() end
    local Maps=require("src.clearcut_maps")
    self.mapId=Maps.get(self.mapId).id
    Maps.configure(game.world,self.mapId)
    self.mapWorld=game.world
    self.mapPlayer=game.player
    local w, h = game.world.width, game.world.height
    local spawnX, spawnY = w / 2, h / 2
    game.player.x, game.player.y = spawnX, spawnY
    self.permanentTraits = (game.characterTraits and game.characterTraits:effects(self.job)) or self.permanentTraits
    self.baseSpeed = 320 * (self.permanentTraits.moveSpeed or 1)
    game.player.speed, game.player.capacity, game.player.gather = self.baseSpeed, 99999, 1.15
    game.camera.x, game.camera.y, game.camera.zoom = spawnX, spawnY, .72
    if game.world.overviewBounds and game.camera.update then game.camera:update(0,game.player,game.world) end
    self.maxHp = self.maxHp + (self.permanentTraits.maxHp or 0)
    self.hp = self.maxHp
    self.reviveCharges = math.floor(self.permanentTraits.reviveCharges or 0)
    self:generateForest(game, Maps.treeTarget(self.mapId,1))
    local notice=Maps.get(self.mapId).name.." — 마우스를 누른 채 나무 근처로 이동하세요"
    if self.job=="miner" then notice=Maps.get(self.mapId).name.." — 좌클릭 할퀴기 · SPACE/우클릭 잠복" end
    game:setNotice(notice, "food")
    if self.job == "fire" then self:startSmoking(game) end
end

-- 나무 종류(스프라이트 variant)별 기초 체력. 예전엔 전부 3으로 고정이라 종류와 상관없이
-- 도끼 몇 번(스킬 몇 개만 찍어도 한 방)이면 쓰러졌다 — 굵고 단단해 보이는 나무는 실제로도
-- 더 오래 버티도록 종류별로 나눴다. 순서는 world.lua/clearcut_maps.lua의 variant 그림 순서와 맞춘다.
local treeHpByMapVariant = {
    forest = {4, 3, 2, 5},      -- 활엽수, 소나무, 자작나무, 단풍나무
    beginner = {4, 3, 2, 5},    -- 초심자의 숲도 같은 4종
    mangrove = {5, 4, 2},       -- 맹그로브, 아비케니아, 니파야자
    madagascar = {8, 4, 2},     -- 바오밥(굵은 몸통), 타마린드, 코미포라
    island = {3, 4, 4},         -- 야자, 씨아몬드, 판다누스
}
local function treeHpFor(mapId, variant)
    local list = treeHpByMapVariant[mapId] or treeHpByMapVariant.forest
    return list[variant or 1] or list[1] or 3
end

-- 나무 배치 로직: 최초 진입(setup)과 스테이지 전환(advanceStage)에서 공용으로 쓴다
function ClearcutMode:generateForest(game, target)
    local Maps=require("src.clearcut_maps")
    local w, h = game.world.width, game.world.height
    local spawnX, spawnY = w / 2, h / 2
    local minSepBase = game.world.clearcutMap=="island" and 70 or (game.world.clearcutMap=="beginner" and 165 or 108)
    local minSepFloor = game.world.clearcutMap=="island" and 42 or (game.world.clearcutMap=="beginner" and 90 or 60)
    local attempts, minSep = 0, minSepBase
    -- Large islands (and the beginner map's tighter world, which needs many relax cycles
    -- to walk minSep down from its sparse starting value) need more land samples in later stages.
    local attemptLimit=game.world.clearcutMap=="island" and math.max(12000,target*70)
        or game.world.clearcutMap=="beginner" and math.max(60000,target*350)
        or 12000
    while #game.world.nodes < target and attempts < attemptLimit do
        attempts = attempts + 1
        -- New open pockets must not reduce later stages' tree objectives.
        -- Relax spacing only after a dense placement pass stalls; never fill paths.
        if attempts%1800==0 then minSep=math.max(minSepFloor,minSep-8) end
        local x = love.math.random(130, w - 130)
        local y = love.math.random(130, h - 130)
        local sdx, sdy = x - spawnX, y - spawnY
        local clearSpawn = sdx*sdx + sdy*sdy > 260*260 and not ForestScenery.isOpen(x,y,w,h)
            and not ForestScenery.isSceneryPocket(x,y,w,h)
        if game.world.clearcutMap and game.world.clearcutMap~="forest" then
            clearSpawn=Maps.treeSpace(game.world,x,y)
        end
        local separated = true
        for _, node in ipairs(game.world.nodes) do
            local ndx, ndy = x - node.x, y - node.y
            if ndx*ndx + ndy*ndy < minSep*minSep then separated = false; break end
        end
        if clearSpawn and separated then
            local beehive = love.math.random() < .07
            local variantCount = math.max(1, #(game.world.images.treeVariants or {}))
            local treeVariant = Maps.treeVariant(game.world,x,y,#game.world.nodes+1)
                or ForestScenery.treeVariant(x,y,w,h,self.stage,#game.world.nodes+1,variantCount)
            local hp = treeHpFor(game.world.clearcutMap, treeVariant)
            game.world.nodes[#game.world.nodes+1] = {kind="tree",x=x,y=y,work=0,workTime=1,active=true,respawn=0,rushTree=true,rushHp=hp,rushMaxHp=hp,beehive=beehive,treeVariant=treeVariant}
            if beehive then self.beehiveTotal = self.beehiveTotal + 1 end
        end
    end
    self.initialTrees, self.remainingTrees = #game.world.nodes, #game.world.nodes
    ForestScenery.generate(game.world,self.stage)
    Maps.filterScenery(game.world)
    require("src.biome_life").generate(game.world,self.stage)
end

-- 스테이지 클리어: 세계수를 쓰러뜨리면 런을 끝내는 대신 더 큰 숲과 더 강한 저주로 다음 스테이지를 연다
function ClearcutMode:advanceStage(game)
    CigaretteButts.reset(self)
    self.supplementImpacts, self.crowFx, self.whipFx, self.lightningFx = {}, {}, {}, {}
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
    self:generateForest(game, require("src.clearcut_maps").treeTarget(self.mapId,self.stage))
    game:setNotice("스테이지 " .. self.stage .. " — 숲이 더 거세게 반격한다!", "ore")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .3) end
    self.pending = self.pending + 1
    if #self:arcanaPool() > 0 then
        self.selectionKind = "arcana"
        self:rollArcanaChoices()
        self.choicesRevealAt = love.timer.getTime()
        game.mode = "clearcut_upgrade"
    else
        self:openUpgradeChoices(game)
    end
end

function ClearcutMode:update(dt, game)
    if self.dead then return end
    require("src.biome_life").update(game.world,dt)
    self.elapsed = self.elapsed + dt
    self:updateHeldAxe(dt, game)
    self:updateThrownTrees(dt, game)
    self:updateBurrowTracks(dt)
    self:updateSupplementSkills(dt, game)
    self:updateRegrowth(dt, game)
    self:updateFire(dt, game)
    self:updateMolotovs(dt, game)
    self:updateToxicRain(dt, game)
    -- 연습장(sandbox)에서는 이 함수들이 자기 안에서 바로 return 하므로(각 함수 상단의
    -- sandbox 가드 참고) 자동 위협/스폰이 전부 꺼지고 "몹 소환" 버튼으로만 적이 생긴다.
    self:updateRootHazards(dt, game)
    self:updateBees(dt, game)
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
    local burrowSpeed=(self.minerBurrow and self.minerBurrow.state=="tunnel") and 1.48 or 1
    game.player.speed = self.baseSpeed * (self.rootedTimer > 0 and .18 or burrowSpeed)
    if self.permanentTraits.hpRegen and self.permanentTraits.hpRegen > 0 then
        self.hp = math.min(self.maxHp, self.hp + self.permanentTraits.hpRegen * dt)
    end
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
    local boost = self:power("forced_growth") * .5
    local regrowPct = base * (1 + boost)
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
        node.burning, node.fallT, node.uprooted = nil, nil, nil
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
    if self.sandbox then return end
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
    if self.sandbox then return end
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
    if self.minerBurrow and (self.minerBurrow.state=="enter" or self.minerBurrow.state=="tunnel") then return end
    amount = amount * (self.dmgTakenMul or 1)
    if self:levelOf("berserker") >= 6 and self.streak >= 10 then
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
        if (self.reviveCharges or 0) > 0 then
            self.reviveCharges = self.reviveCharges - 1
            self.hp = math.floor(self.maxHp * .5)
            self.invulnTimer = 1.2
            game:setNotice("퇴직 위로금 정산 — 한 번은 봐준다", "food")
            for _ = 1, 16 do game.world:addParticle(game.player.x, game.player.y - 20, {1, .9, .5}, true, false) end
        else
            self.dead = true
            self:finish(game, false)
        end
    end
end

function ClearcutMode:damageEnemiesInRadius(x, y, radius, damage, game)
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - x, e.y - y
        if dx*dx + dy*dy <= radius*radius then
            e.hp = e.hp - damage
            e.visualHit = .14
            for _ = 1, 4 do game.world:addParticle(e.x, e.y - 12, {1, .32, .2}, true, false) end
        end
    end
end

function ClearcutMode:igniteEnemy(e, game, depth)
    if self.rainSuppressFire or e.burning or e.hp <= 0 then return end
    e.burning, e.burnTimer, e.fireTickTimer, e.spreadDepth = true, 0, 0, depth or 0
    game.world:igniteFx(e.x, e.y, false)
end

function ClearcutMode:igniteEnemiesInRadius(x, y, radius, game, depth)
    if self.rainSuppressFire then return end
    for _, e in ipairs(self.enemies) do
        if not e.burning then
            local dx, dy = e.x - x, e.y - y
            if dx*dx + dy*dy <= radius*radius then self:igniteEnemy(e, game, depth) end
        end
    end
end

function ClearcutMode:spawnEnemy(kind, x, y, opts)
    kind=BiomeEnemies.resolve(self.mapId,kind)
    local def = enemyDefs[kind]
    if not def then return end
    x,y=BiomeEnemies.spawnPoint(self.mapWorld,self.mapPlayer,kind,x,y)
    x,y=require("src.clearcut_maps").constrain(self.mapWorld,x,y,(def.radius or 20)+8)
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
    if self.sandbox then return end
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
    if self.sandbox then return end
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
    if self.sandbox then return end
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
    if self.sandbox then return end
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
    if self.sandbox then return end
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
    if self.sandbox then return end
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
    e.visualAttack = .24
    self.projectiles[#self.projectiles + 1] = {x = e.x, y = e.y, vx = dx / d * 150, vy = dy / d * 150, life = 3, damage = e.def.damage * (e.dmgMul or 1), color = e.def.color}
end

-- 정예 개체 전용 원거리 공격: 근접전만 하던 몹에게 가시 투사체를 추가로 부여한다
function ClearcutMode:spawnThornProjectile(e, game)
    local dx, dy = game.player.x - e.x, game.player.y - e.y
    local d = math.sqrt(dx*dx + dy*dy)
    if d <= 0 then return end
    e.visualAttack = .24
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
    if game.mode~="playing" then return end
    for _, c in ipairs(self.chests) do
        if not c.collected then
            local dx, dy = game.player.x - c.x, game.player.y - c.y
            if dx*dx + dy*dy <= 46*46 then
                c.collected = true
                self:openChest(game)
                if game.mode~="playing" then return end
            end
        end
    end
end

function ClearcutMode:openChest(game)
    if self:checkEvolutions(game) then
        self.fusionChestRewards=(self.fusionChestRewards or 0)+1
        return
    end
    local pool = {}
    for _, def in ipairs(self:upgradePool()) do
        if def.job == self.job then pool[#pool + 1] = def end
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
    self.selectionKind, self.banishArmed = "upgrade", false
    self.specialCard = nil
    self.choicesRevealAt = love.timer.getTime()
    game.mode = "clearcut_upgrade"
    game:setNotice("보물상자 — 전직 전용 스킬을 하나 고르세요!", "food")
end

function ClearcutMode:updateEnemies(dt, game)
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        local def = e.def
        local previousX, previousY = e.x, e.y
        e.visualTime = (e.visualTime or 0) + dt
        e.visualHit = math.max(0, (e.visualHit or 0) - dt)
        e.visualAttack = math.max(0, (e.visualAttack or 0) - dt)
        e.hitTimer = math.max(0, e.hitTimer - dt)
        if BiomeEnemies.update(e,dt,self,game) then
            -- Regional attacks own their windup, swept hit and recovery phases.
        elseif e.kind == "reaper" then
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
                    e.visualAttack = .24
                    self:damagePlayer(def.damage * (e.dmgMul or 1), game)
                end
            end
        end
        e.x,e.y=require("src.clearcut_maps").constrain(game.world,e.x,e.y,(def.radius or 20)+8)
        local movedX, movedY = e.x-previousX, e.y-previousY
        if math.abs(movedX) > .001 then e.facing = movedX < 0 and -1 or 1 end
        e.moving = movedX*movedX + movedY*movedY > .000001
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
    if not self.sandbox and self.remainingTrees <= 0 and not self.worldTreeSpawned then self:spawnWorldTree(game) end
end

-- 담배꽁초가 나무에 처음 옮겨붙을 때 쓰는 불씨 궤적(emberTransfers/emberArrivals)과 똑같은
-- 그리기 함수를 그대로 재사용해, 나무에서 나무로 불이 번질 때도 같은 궤적 이펙트를 띄운다.
-- 게임 로직(점화 판정 등)은 그대로 두고 시각 효과만 얹는 별도 배열이라 기존 흐름을 건드리지 않는다.
function ClearcutMode:spawnFireSpark(sx, sy, tx, ty)
    local dist = math.sqrt((tx - sx) ^ 2 + (ty - sy) ^ 2)
    local duration = math.max(.28, math.min(.75, dist / 480))
    local now = self.smokerGroundTime
    self.treeSparks[#self.treeSparks + 1] = {x = sx, y = sy, tx = tx, ty = ty, startAt = now, duration = duration, arrivesAt = now + duration}
end

-- 마른 건초더미: 꽁초가 더미 위에 실제로 착지했을 때만 예열을 시작한다.
-- 0.5초 뒤 국소 화염 지대가 되며, 나무/다른 더미로는 절대 번지지 않는다.
function ClearcutMode:updateStrawBales(dt, game)
    local now = self.smokerGroundTime
    for i = #self.strawBales, 1, -1 do
        local bale = self.strawBales[i]
        if bale.ignited then
            bale.tickTimer = (bale.tickTimer or 0) - dt
            if bale.tickTimer <= 0 then
                bale.tickTimer = .4
                self:damageEnemiesInRadius(bale.x, bale.y, 60, 4, game)
            end
            if now - bale.ignitedAt >= 6 then table.remove(self.strawBales, i) end
        else
            bale.age = bale.age + dt
            if bale.primedAt then
                if self.rainSuppressFire then
                    bale.primedAt=nil
                elseif now-bale.primedAt>=.5 then
                    bale.ignited,bale.ignitedAt,bale.tickTimer=true,now,0
                end
            elseif not self.rainSuppressFire then
                for _,butt in ipairs(self.cigaretteButts) do
                    local dx,dy=butt.x-bale.x,butt.y-bale.y
                    if dx*dx+dy*dy<=48*48 then
                        bale.primedAt=now
                        break
                    end
                end
            end
            if not bale.primedAt and bale.age >= 22 then
                table.remove(self.strawBales, i)
            end
        end
    end
    local level = self:levelOf("straw_bale")
    if level <= 0 then return end
    self.strawTimer = self.strawTimer - dt
    if self.strawTimer <= 0 then
        self.strawTimer = math.max(5, 12 - self:power("straw_bale") * 1.4)
        local a = love.math.random() * math.pi * 2
        local r = 70 + love.math.random() * 170
        self.strawBaleSequence=(self.strawBaleSequence or 0)+1
        self.strawBales[#self.strawBales + 1] = {
            x=game.player.x+math.cos(a)*r,y=game.player.y+math.sin(a)*r,
            age=0,ignited=false,variant=(self.strawBaleSequence-1)%2
        }
    end
end

-- 융합 "불바다 출근길"(oil_drum+straw_bale 만렙): 이동하는 동안 지나온 자리에 기름 자국을
-- 남긴다. 담배꽁초가 그 위에 떨어지면 그 지점부터 이어진 자국을 따라(불이 옮겨붙듯 연쇄로)
-- 화염대가 켜지고, 유지되는 동안 닿는 적에게 지속 피해를 준다.
function ClearcutMode:updateOilTrail(dt, game)
    if not self.evolutions.oilRoad then
        self.oilTrailLastX,self.oilTrailLastY=nil,nil
        return
    end
    local now = self.smokerGroundTime
    self.oilTrailTimer = self.oilTrailTimer - dt
    if game.player.isMoving and self.oilTrailTimer <= 0 then
        self.oilTrailTimer = .16
        local dx=game.player.x-(self.oilTrailLastX or game.player.x-(game.player.facing or 1))
        local dy=game.player.y-(self.oilTrailLastY or game.player.y)
        local angle=(math.abs(dx)+math.abs(dy)>.001) and math.atan2(dy,dx) or ((game.player.facing or 1)>0 and 0 or math.pi)
        self.oilTrailSequence=(self.oilTrailSequence or 0)+1
        self.oilTrail[#self.oilTrail + 1] = {
            x=game.player.x,y=game.player.y,spawnedAt=now,ignited=false,
            angle=angle,variant=(self.oilTrailSequence-1)%3+1,sequence=self.oilTrailSequence
        }
        self.oilTrailLastX,self.oilTrailLastY=game.player.x,game.player.y
        if #self.oilTrail > 90 then table.remove(self.oilTrail, 1) end
    elseif not game.player.isMoving then
        self.oilTrailLastX,self.oilTrailLastY=game.player.x,game.player.y
    end
    if not self.rainSuppressFire then
        for _, butt in ipairs(self.cigaretteButts) do
            for _, spot in ipairs(self.oilTrail) do
                if not spot.ignited then
                    local dx, dy = spot.x - butt.x, spot.y - butt.y
                    if dx * dx + dy * dy <= 70 * 70 then self:igniteOilTrail(spot, game) end
                end
            end
        end
    end
    for i = #self.oilTrail, 1, -1 do
        local spot = self.oilTrail[i]
        if spot.ignited then
            spot.tickTimer = (spot.tickTimer or 0) - dt
            if spot.tickTimer <= 0 then
                spot.tickTimer = .4
                self:damageEnemiesInRadius(spot.x, spot.y, 55, 4, game)
            end
            if now - spot.ignitedAt >= 5 then table.remove(self.oilTrail, i) end
        elseif now - spot.spawnedAt >= 6 then
            table.remove(self.oilTrail, i)
        end
    end
end

function ClearcutMode:igniteOilTrail(spot, game)
    if spot.ignited then return end
    local now = self.smokerGroundTime
    spot.ignited, spot.ignitedAt = true, now
    local frontier, total = {spot}, 1
    while #frontier > 0 and total < 40 do
        local current = table.remove(frontier)
        for _, other in ipairs(self.oilTrail) do
            if not other.ignited and total < 40 then
                local dx, dy = other.x - current.x, other.y - current.y
                if dx * dx + dy * dy <= 55 * 55 then
                    other.ignited, other.ignitedAt = true, now
                    frontier[#frontier + 1] = other
                    total = total + 1
                end
            end
        end
    end
end

function ClearcutMode:updateTreeSparks()
    local now = self.smokerGroundTime
    for i = #self.treeSparks, 1, -1 do
        local spark = self.treeSparks[i]
        if now >= spark.arrivesAt then
            self.treeSparkArrivals[#self.treeSparkArrivals + 1] = {x = spark.tx, y = spark.ty - 6, startAt = now}
            table.remove(self.treeSparks, i)
        end
    end
    for i = #self.treeSparkArrivals, 1, -1 do
        if now - self.treeSparkArrivals[i].startAt >= .65 then table.remove(self.treeSparkArrivals, i) end
    end
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
        self:spawnFireSpark(source.x, source.y, candidates[i].x, candidates[i].y)
    end
end

-- wildfire=true: 산불 융합 전용 자동 투척. 그냥 투척 한 번 더가 아니라 두 개비를 한꺼번에
-- 부채꼴로 던지고, 비행 중 불타는 꼬리를 남겨 눈에 띄게 다르게 보이도록 flight.wildfire로 표시한다.
function ClearcutMode:throwMolotov(game, wildfire)
    local candidates = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and not node.burning and not node.igniting then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            if dx*dx + dy*dy <= 620*620 then candidates[#candidates+1] = node end
        end
    end
    if #candidates == 0 then return end
    local throws = wildfire and math.min(2, #candidates) or 1
    for i = 1, throws do
        local pick = love.math.random(#candidates)
        local target = table.remove(candidates, pick)
        target.igniting = true
        local dist = math.sqrt((target.x-game.player.x)^2 + (target.y-game.player.y)^2)
        local _,mouthY,_,tipX=self:smokerMouthPose(game)
        self.molotovs[#self.molotovs+1] = {
            x0=tipX, y0=mouthY, x1=target.x+28, y1=target.y+22,
            t=0, dur=math.max(.34, dist/850), target=target, wildfire=wildfire,
            radius=90+self:power("molotov")*20+self.permanentTraits.area, landingAngle=.18+math.sin(target.x*.013)*.6
        }
    end
    self:trackMolotovBarrage(game)
    for _ = 1, math.floor(self.permanentTraits.extraFires) do
        if #candidates > 0 then self:hurlMolotovAt(candidates[love.math.random(#candidates)].x, candidates[love.math.random(#candidates)].y, game, true) end
    end
end

function ClearcutMode:trackMolotovBarrage(game)
    if self:levelOf("molotov") < 6 then return end
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
        t=0, dur=math.max(.34, dist/850), manual=true, radius=90 + self:power("molotov") * 20 + self.permanentTraits.area,
        landingAngle=.18+math.sin(tx*.013+ty*.017)*.6
    }
    if not isBarrage then
        self:trackMolotovBarrage(game)
        for _ = 1, math.floor(self.permanentTraits.extraFires) do
            self:hurlMolotovAt(tx + love.math.random(-40,40), ty + love.math.random(-40,40), game, true)
        end
    end
end

function ClearcutMode:updateMolotovs(dt, game)
    CigaretteButts.update(self,dt,game)
    self:updateTreeSparks()
end

function ClearcutMode:onTreeBurnedDown(node, game)
    local oilLevel = self:levelOf("oil_drum")
    local oilChance = oilLevel >= 6 and 1 or self:power("oil_drum") * .15
    if oilLevel > 0 and love.math.random() < oilChance then
        self:igniteNear(node, game, 90 + self:power("oil_drum") * 30, 99)
        game.world:igniteFx(node.x, node.y, true)
    end
end

function ClearcutMode:updateFire(dt, game)
    local molotovLevel = self:levelOf("molotov")
    if molotovLevel > 0 then
        self.molotovTimer = self.molotovTimer + dt
        local interval = math.max(2.6, 8 - self:power("molotov") * 1.6)
        if self.molotovTimer >= interval then
            self.molotovTimer = 0
            self:throwMolotov(game)
        end
    end
    if self.evolutions.wildfire then
        self.wildfireTimer = self.wildfireTimer + dt
        if self.wildfireTimer >= 3 then
            self.wildfireTimer = 0
            self:throwMolotov(game, true)
        end
    end
    local dryLevel = self:levelOf("dry_forest")
    local dryPower = self:power("dry_forest")
    local spreadChancePerSec = .12 + dryPower * .14 + self.permanentTraits.spreadChance
    local spreadRadius = 130 + dryPower * 45
    if self.evolutions.wildfire then
        spreadRadius=spreadRadius*1.35
        spreadChancePerSec=spreadChancePerSec*1.5
    end
    local burnDuration = math.max(2.2, (3.6 - dryPower * .35) / self.permanentTraits.burnSpeed)
    self:updateStrawBales(dt, game)
    self:updateOilTrail(dt, game)
    if dryLevel >= 6 then
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
                self:igniteEnemiesInRadius(node.x, node.y, 75, game, node.spreadDepth)
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
    local enemyBurnDamage = 5 + self:power("molotov") * 3
    for _, e in ipairs(self.enemies) do
        if e.burning then
            e.burnTimer = e.burnTimer + dt
            e.fireTickTimer = (e.fireTickTimer or 0) - dt
            if e.fireTickTimer <= 0 then
                e.fireTickTimer = .5
                local falloff = .5 ^ (e.spreadDepth or 0)
                e.hp = e.hp - enemyBurnDamage * falloff
                e.visualHit = .14
                for _ = 1, 3 do game.world:addParticle(e.x, e.y - 12, {1, .35, .18}, true, false) end
            end
            if e.burnTimer >= burnDuration then e.burning = false end
        end
    end
end

function ClearcutMode:updateToxicRain(dt, game)
    local lvl = self:levelOf("toxic_rain")
    if lvl == 0 then return end
    local power = self:power("toxic_rain")
    self.toxicTimer = self.toxicTimer + dt
    local interval = math.max(2, 6 - power * 1.2)
    if self.toxicTimer < interval then return end
    self.toxicTimer = 0
    local radius = 120 + power * 20
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            if dx*dx + dy*dy <= radius*radius then
                node.rushHp = (node.rushHp or node.rushMaxHp) - power
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
                p.ref.rushHp = (p.ref.rushHp or p.ref.rushMaxHp) - (p.dmg or 1)
                game.world:impactNode(p.ref, game, false)
                if p.ref.rushHp <= 0 then self:fellTree(p.ref, game) end
            end
        else
            alive = p.ref.hp > 0
            if alive and p.tickTimer <= 0 then
                p.tickTimer = .6
                p.ref.hp = p.ref.hp - (p.dmg or 2)
                game.world:addParticle(p.ref.x, p.ref.y - 10, {.5, .85, .35}, false, false)
            end
        end
        if not alive or p.timer <= 0 then
            if p.ref then p.ref.plagueMarked = nil end
            table.remove(self.plagued, i)
        end
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
    if self:levelOf("berserker") == 0 then return 1 end
    return 1 + self:power("berserker") * .07 * math.min(self.streak, 14)
end

function ClearcutMode:updateHeldAxe(dt, game, heldOverride)
    if self.job == "fire" then return self:updateFireAttack(dt, game, heldOverride) end
    if self.job == "toxic" then return self:updateToxicAttack(dt, game, heldOverride) end
    if self.job == "developer" then return self:updateDeveloperAttack(dt, game, heldOverride) end
    if self.job == "miner" then return self:updateMinerAttack(dt, game, heldOverride) end
    if self.job == "philosopher" then return self:updatePhilosopherAttack(dt, game, heldOverride) end
    return self:updatePhysicalAttack(dt, game, heldOverride)
end

function ClearcutMode:updatePhysicalAttack(dt, game, heldOverride)
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    game.player.axeHolding = held
    self.axeRange = 150 + self:power("wide_blade") * 20 + self.permanentTraits.range
    game.player.axeRange = self.axeRange
    self.axeCooldown = math.max(0, self.axeCooldown - dt)
    if not held or self.axeCooldown > 0 then return false end
    local target = self:closestTreeInAxeRange(game)
    if not target then return false end
    game.player:cancelInteraction()
    game.player:playAutoAxeSwing(target.x)
    self:hitTree(target, game)
    local speed = (game.tools.axe.speed or 1) * game.player.gather * (self.beeSlow and .6 or 1) * self:berserkerSpeedMult() * self.permanentTraits.attackSpeed
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
    local maxRange = 320 + self:power("molotov") * 40 + self.permanentTraits.range
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY, self.aimRadius = tx, ty, 90 + self:power("molotov") * 20 + self.permanentTraits.area
    if not self.smoking then self:startSmoking(game) end
    local smoking = self.smoking
    local pressed = held and not self.smokerHeldLast
    self.smokerHeldLast = held
    -- Movement owns facing while smoking/ready. Mouse aim only turns the body
    -- during an actual throw, and that throw keeps its original direction.

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
        smoking.phase, smoking.t, smoking.dur = "flick", 0, math.max(.38, .52 / ((game.tools.axe.speed or 1) * game.player.gather * self.permanentTraits.attackSpeed))
        smoking.loaded, smoking.fired, smoking.tx, smoking.ty = false, false, tx, ty
        smoking.facing = tx < game.player.x and -1 or 1
        game.player.facing = smoking.facing
        if game.player.setClearcutAction then game.player:setClearcutAction(.5) end
        return false
    end

    game.player.facing = smoking.facing or game.player.facing
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
    local speed = (game.tools.axe.speed or 1) * game.player.gather * self.permanentTraits.attackSpeed
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

    if sprite and sprite.walkMouth and sprite.actionMouth and player.clearcutPose then
        local row, frame, flip, foot, bob = player:clearcutPose()
        local anchor = sprite[row .. "Mouth"][frame]
        local scale = sprite.scale or .61
        local mouthX = player.x + (anchor[1] - player.clearcutFrameWidth / 2) * scale * flip
        local mouthY = player.y - bob + (anchor[2] - foot) * scale
        local length = sprite.cigarette and sprite.cigarette.length or 4 * scale
        return mouthX, mouthY, facing, mouthX + length * facing
    end

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
    local maxRange = 260 + self:power("toxic_rain") * 40 + self.permanentTraits.range
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY, self.aimRadius = tx, ty, 90 + self:power("toxic_rain") * 25 + self.permanentTraits.area
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
    local speed = (game.tools.axe.speed or 1) * game.player.gather * self.permanentTraits.attackSpeed
    self.veganAction = {t=0,dur=math.max(.48,.72/speed),tx=tx,ty=ty,bit=false}
    game.player.facing = tx < game.player.x and -1 or 1
    if game.player.setClearcutAction then game.player:setClearcutAction(0) end
    return false
end

function ClearcutMode:applyVeganBite(tx, ty, game)
    local dmg = 2 + self:power("toxic_rain") + self.permanentTraits.biteDamage
    local plagueLv3 = self:levelOf("toxic_rain") >= 6
    local plagueTimer = 4 + self.permanentTraits.plagueDuration
    -- Reach = however many trees fall inside the bite radius, plus a few more of the
    -- next-closest trees when extraTargets lets the bite snipe past its usual edge.
    local candidates, radiusCount = {}, 0
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree then
            local dx, dy = node.x - tx, node.y - ty
            local d2 = dx*dx + dy*dy
            candidates[#candidates+1] = {node=node, d2=d2}
            if d2 <= self.aimRadius * self.aimRadius then radiusCount = radiusCount + 1 end
        end
    end
    table.sort(candidates, function(a,b) return a.d2 < b.d2 end)
    local reach = math.min(#candidates, radiusCount + math.floor(self.permanentTraits.extraTargets))
    for i = 1, reach do
        local node = candidates[i].node
        if node.active then
            node.rushHp = (node.rushHp or node.rushMaxHp) - dmg
            game.world:impactNode(node, game, true)
            if node.rushHp <= 0 then self:fellTree(node, game)
            elseif plagueLv3 and not node.plagueMarked then
                node.plagueMarked = true
                self.plagued[#self.plagued+1] = {kind="tree", ref=node, timer=plagueTimer, tickTimer=0}
            end
        end
    end
    if plagueLv3 then
        for _, e in ipairs(self.enemies) do
            local dx, dy = e.x - tx, e.y - ty
            if dx*dx + dy*dy <= self.aimRadius * self.aimRadius and not e.plagueMarked then
                e.plagueMarked = true
                self.plagued[#self.plagued+1] = {kind="enemy", ref=e, timer=plagueTimer, tickTimer=0}
            end
        end
    end
    self:damageEnemiesInRadius(tx, ty, self.aimRadius, dmg * 3, game)
    game.world:toxicPulseFx(tx, ty, self.aimRadius)
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .18) end
    return true
end

function ClearcutMode:updateMinerAttack(dt, game, heldOverride)
    MoleClawArt.update(self,dt)
    if self.minerBurrow then
        self:updateMinerBurrow(dt, game)
        return false
    end
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    local maxRange = 112 + self:power("detector") * 16 + self.permanentTraits.range
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY = tx, ty
    self.aimRadius = 34 + self:power("detector") * 5 + self.permanentTraits.area * .35
    if self.minerClawAction then
        local action = self.minerClawAction
        action.t = math.min(action.dur, action.t + dt)
        local progress = action.t / action.dur
        if game.player.setClearcutAction then game.player:setClearcutAction(math.min(.49, progress * .49)) end
        local struck = false
        -- 0.68 maps to action cell 3 (the authored claw-contact pose).
        if not action.struck and progress >= .68 then
            action.struck = true
            self:applyClawSwipe(action.tx, action.ty, game)
            struck = true
        end
        if action.t >= action.dur then
            self.minerClawAction = nil
            self.attackCooldown = .1
            if game.player.clearClearcutAction then game.player:clearClearcutAction() end
        end
        return struck
    end
    self.attackCooldown = math.max(0, self.attackCooldown - dt)
    if not held or self.attackCooldown > 0 then return false end
    local speed = (game.tools.axe.speed or 1) * game.player.gather * self.permanentTraits.attackSpeed
    self.minerClawAction = {t=0, dur=math.max(.34, .62/speed), tx=tx, ty=ty, struck=false}
    game.player.facing = tx < game.player.x and -1 or 1
    if game.player.setClearcutAction then game.player:setClearcutAction(0) end
    return false
end

local function pointSegmentDistanceSquared(px, py, ax, ay, bx, by)
    local vx, vy = bx - ax, by - ay
    local length2 = vx*vx + vy*vy
    if length2 <= .001 then return (px-ax)^2 + (py-ay)^2 end
    local u = math.max(0, math.min(1, ((px-ax)*vx + (py-ay)*vy) / length2))
    local dx, dy = px - (ax + vx*u), py - (ay + vy*u)
    return dx*dx + dy*dy
end

function ClearcutMode:applyClawSwipe(tx, ty, game)
    local px, py = game.player.x, game.player.y
    local dx, dy = tx - px, ty - py
    local distance = math.sqrt(dx*dx + dy*dy)
    if distance < 1 then dx, dy, distance = game.player.facing or 1, 0, 1 end
    local nx, ny = dx / distance, dy / distance
    local range = 112 + self:power("detector") * 16 + self.permanentTraits.range
    local halfWidth = 34 + self:power("detector") * 5 + self.permanentTraits.area * .35
    local damage = 2 + self:power("detector") * .65 + self.permanentTraits.treeDamage
    local clawLevel = self:levelOf("detector")
    local angle
    if math.atan2 then angle=math.atan2(ny,nx)
    else angle=math.atan(ny/nx)+(nx<0 and math.pi or 0) end
    -- Preserve the accepted left-facing curve. Right-facing swipes use its
    -- exact mirror image rather than a 180-degree rotation with wrong chirality.
    local curveFlip=(game.player.facing or 1)>0 and -1 or 1
    local candidates = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local rx, ry = node.x - px, node.y - py
            local along, side = rx*nx + ry*ny, math.abs(rx*ny - ry*nx)
            if along >= 0 and along <= range and side <= halfWidth then
                candidates[#candidates+1] = {node=node, along=along}
            end
        end
    end
    table.sort(candidates, function(a,b) return a.along < b.along end)
    local limit = 1 + math.floor(self.permanentTraits.extraTargets or 0)
    local marked=false
    for index=1,math.min(limit,#candidates) do
        local node = candidates[index].node
        MoleClawArt.spawn(self,node.x,node.y-54,angle,clawLevel,curveFlip)
        marked=true
        node.rushHp = (node.rushHp or node.rushMaxHp) - damage
        game.world:impactNode(node, game, true)
        SupplementArt.impact(self,"axe",node.x,node.y,30)
        if node.rushHp <= 0 then self:fellTree(node,game) end
    end
    for _, enemy in ipairs(self.enemies) do
        local rx, ry = enemy.x-px, enemy.y-py
        local along, side = rx*nx+ry*ny, math.abs(rx*ny-ry*nx)
        if along >= 0 and along <= range and side <= halfWidth then
            MoleClawArt.spawn(self,enemy.x,enemy.y-12,angle,clawLevel,curveFlip)
            marked=true
            enemy.hp, enemy.visualHit = enemy.hp - damage*2.2, .14
            SupplementArt.impact(self,"axe",enemy.x,enemy.y,26)
        end
    end
    if not marked then
        local contact=math.min(range,distance)
        MoleClawArt.spawn(self,px+nx*contact,py+ny*contact,angle,clawLevel,curveFlip)
    end
    self.traitFx:emit("axe",px+nx*range*.58,py+ny*range*.58,{radius=halfWidth,power=.8,angle=math.atan2 and math.atan2(ny,nx) or 0})
    if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.09) end
end

function ClearcutMode:activateMinerBurrow(game)
    if self.job ~= "miner" or self.dead or self.minerBurrow then return false end
    if self.minerBurrowCooldown > 0 then
        game:setNotice(string.format("잠복 재사용 %.1f초",self.minerBurrowCooldown),"ore")
        return false
    end
    self.minerClawAction = nil
    self.attackCooldown = 0
    self.minerBurrow = {
        state="enter", t=0, duration=3.2+self:power("burrow_uproot")*.22,
        lastX=game.player.x,lastY=game.player.y,trackX=game.player.x,trackY=game.player.y,side=1,launched=0
    }
    self:addBurrowTrack(game.player.x,game.player.y,0,"entry")
    if game.player.setClearcutAction then game.player:setClearcutAction(.52) end
    game:setNotice("지하 강제집행 — 나무 밑으로 파고들어라!","ore")
    return true
end

function ClearcutMode:addBurrowTrack(x,y,angle,kind)
    self.burrowTrackSequence=(self.burrowTrackSequence or 0)+1
    self.burrowTracks[#self.burrowTracks+1]={
        x=x,y=y,angle=angle or 0,kind=kind,variant=(self.burrowTrackSequence-1)%6+1,life=18,maxLife=18
    }
    if #self.burrowTracks>360 then table.remove(self.burrowTracks,1) end
end

function ClearcutMode:updateBurrowTracks(dt)
    for index=#self.burrowTracks,1,-1 do
        local mark=self.burrowTracks[index];mark.life=mark.life-dt
        if mark.life<=0 then table.remove(self.burrowTracks,index) end
    end
end

function ClearcutMode:launchTreeSideways(node, moveX, moveY, burrow, game)
    local length = math.sqrt(moveX*moveX + moveY*moveY)
    if length < .01 then moveX,moveY,length=game.player.facing or 1,0,1 end
    local nx,ny=moveX/length,moveY/length
    local side=burrow.side
    burrow.side=-burrow.side
    local sx,sy=-ny*side,nx*side
    local power=self:power("burrow_uproot")
    local speed=610+power*55
    local variant=node.treeVariant or 1
    local x,y=node.x,node.y
    if not self:fellTree(node,game) then return false end
    node.fallT=nil
    node.uprooted=true
    self.thrownTrees[#self.thrownTrees+1]={
        x=x,y=y,z=8,vx=sx*speed+nx*90,vy=sy*speed+ny*90,vz=390,
        gravity=820,angle=0,spin=side*(3.8+power*.18),variant=variant,
        damage=3.5+power*1.35,penetration=1+self:powerCount("burrow_uproot"),hit={}
    }
    burrow.launched=burrow.launched+1
    self:addBurrowTrack(x,y,math.atan2(moveY,moveX),"root")
    self.traitFx:emit("construction_blast",x,y,{radius=78,particles=24,power=1.05,color={.48,.3,.12}})
    if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.22) end
    return true
end

function ClearcutMode:updateMinerBurrow(dt, game)
    local burrow=self.minerBurrow
    if not burrow then return end
    burrow.t=burrow.t+dt
    if burrow.state=="enter" then
        if game.player.setClearcutAction then game.player:setClearcutAction(.5+math.min(.16,burrow.t/.28*.16)) end
        if burrow.t>=.28 then
            burrow.state,burrow.t="tunnel",0
            burrow.lastX,burrow.lastY=game.player.x,game.player.y
        end
        return
    end
    if burrow.state=="tunnel" then
        local phase=math.floor(burrow.t*10)%2
        if game.player.setClearcutAction then game.player:setClearcutAction(phase==0 and .72 or .88) end
        local x0,y0=burrow.lastX,burrow.lastY
        local x1,y1=game.player.x,game.player.y
        local moveX,moveY=x1-x0,y1-y0
        local trackDx,trackDy=x1-burrow.trackX,y1-burrow.trackY
        local trackDistance=math.sqrt(trackDx*trackDx+trackDy*trackDy)
        if trackDistance>=22 then
            local nx,ny=trackDx/trackDistance,trackDy/trackDistance
            local angle=math.atan2(ny,nx)
            local traveled=22
            while traveled<=trackDistance do
                local tx,ty=burrow.trackX+nx*traveled,burrow.trackY+ny*traveled
                self:addBurrowTrack(tx,ty,angle)
                traveled=traveled+22
            end
            local used=traveled-22
            burrow.trackX,burrow.trackY=burrow.trackX+nx*used,burrow.trackY+ny*used
        end
        local hitRadius=72+self:power("burrow_uproot")*5+self.permanentTraits.area*.25
        for _,node in ipairs(game.world.nodes) do
            if node.rushTree and node.active and pointSegmentDistanceSquared(node.x,node.y,x0,y0,x1,y1)<=hitRadius*hitRadius then
                self:launchTreeSideways(node,moveX,moveY,burrow,game)
            end
        end
        burrow.lastX,burrow.lastY=x1,y1
        if burrow.t>=burrow.duration then
            burrow.state,burrow.t="exit",0
            self:addBurrowTrack(game.player.x,game.player.y,math.atan2(moveY,moveX),"exit")
        end
        return
    end
    if game.player.setClearcutAction then game.player:setClearcutAction(.62) end
    if burrow.t>=.2 then
        self.minerBurrow=nil
        self.minerBurrowCooldown=math.max(3.4,7-self:power("burrow_uproot")*.55)
        if game.player.clearClearcutAction then game.player:clearClearcutAction() end
    end
end

function ClearcutMode:updateThrownTrees(dt, game)
    self.minerBurrowCooldown=math.max(0,(self.minerBurrowCooldown or 0)-dt)
    for index=#self.thrownTrees,1,-1 do
        local tree=self.thrownTrees[index]
        tree.x,tree.y=tree.x+tree.vx*dt,tree.y+tree.vy*dt
        tree.z=tree.z+tree.vz*dt
        tree.vz=tree.vz-tree.gravity*dt
        tree.angle=tree.angle+tree.spin*dt
        local remove=false
        for _,node in ipairs(game.world.nodes) do
            if not remove and node.rushTree and node.active and not tree.hit[node] then
                local dx,dy=node.x-tree.x,node.y-tree.y
                if dx*dx+dy*dy<=68*68 then
                    tree.hit[node]=true
                    node.rushHp=(node.rushHp or node.rushMaxHp)-tree.damage
                    game.world:impactNode(node,game,true)
                    SupplementArt.impact(self,"axe",node.x,node.y,42)
                    if node.rushHp<=0 then self:fellTree(node,game) end
                    tree.penetration=tree.penetration-1
                    remove=tree.penetration<=0
                end
            end
        end
        for _,enemy in ipairs(self.enemies) do
            if not remove and enemy.hp>0 and not tree.hit[enemy] then
                local dx,dy=enemy.x-tree.x,enemy.y-tree.y
                if dx*dx+dy*dy<=62*62 then
                    tree.hit[enemy]=true
                    enemy.hp,enemy.visualHit=enemy.hp-tree.damage*2.5,.18
                    tree.penetration=tree.penetration-1
                    remove=tree.penetration<=0
                end
            end
        end
        if tree.z<=0 and tree.vz<0 then remove=true end
        if tree.x<40 or tree.y<40 or tree.x>game.world.width-40 or tree.y>game.world.height-40 then remove=true end
        if remove then
            self.traitFx:emit("construction_blast",tree.x,tree.y,{radius=68,particles=18,power=.85,color={.45,.28,.12}})
            table.remove(self.thrownTrees,index)
        end
    end
end

-- 공용 보조 스킬 8종과 직업 전용 스킬. 시각 이벤트는 전투 시간으로만 진행한다.
function ClearcutMode:updateSupplementSkills(dt, game)
    SupplementArt.update(self,dt)
    self:updateBatSwarm(dt, game)
    self:updateThornAura(dt, game)
    self:updateCrowStrike(dt, game)
    self:updateVineWhip(dt, game)
    self:updateBoomerangAxe(dt, game)
    self:updateSeedMine(dt, game)
    self:updateChainLightning(dt, game)
    self:updateBruteForce(dt, game)
    if self.auraPulse then self.auraPulse = math.max(0, self.auraPulse - dt * 2.2) end
end

function ClearcutMode:updateBatSwarm(dt, game)
    local level = self:levelOf("bat_swarm")
    if level <= 0 then self.bats = nil; return end
    local power = self:power("bat_swarm")
    local count = self:powerCount("bat_swarm") + 1
    self.bats = self.bats or {}
    for i = 1, count do
        self.bats[i] = self.bats[i] or {angle = (i / count) * math.pi * 2, hitTimer = 0}
    end
    for i = #self.bats, count + 1, -1 do self.bats[i] = nil end
    local radius = 78 + power * 8
    local dmg = 1 + power * .6
    for _, bat in ipairs(self.bats) do
        bat.angle = bat.angle + dt * 2.6
        bat.hitTimer = math.max(0, bat.hitTimer - dt)
        local bx, by = game.player.x + math.cos(bat.angle) * radius, game.player.y + math.sin(bat.angle) * radius * .6 - 14
        bat.x, bat.y = bx, by
        if bat.hitTimer <= 0 then
            bat.hitTimer = .45
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active then
                    local dx, dy = node.x - bx, node.y - by
                    if dx*dx + dy*dy <= 24*24 then
                        node.rushHp = (node.rushHp or node.rushMaxHp) - dmg
                        game.world:impactNode(node, game, false)
                        if node.rushHp <= 0 then self:fellTree(node, game) end
                    end
                end
            end
            self:damageEnemiesInRadius(bx, by, 24, dmg, game)
        end
    end
end

function ClearcutMode:updateThornAura(dt, game)
    local level = self:levelOf("thorn_aura")
    if level <= 0 then return end
    self.auraTimer = (self.auraTimer or 0) - dt
    if self.auraTimer > 0 then return end
    local power = self:power("thorn_aura")
    self.auraTimer = math.max(1, 1.9 - power * .3)
    local radius = 60 + power * 70
    local dmg = 1 + power
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            if dx*dx + dy*dy <= radius*radius then
                node.rushHp = (node.rushHp or node.rushMaxHp) - dmg
                game.world:impactNode(node, game, false)
                if node.rushHp <= 0 then self:fellTree(node, game) end
            end
        end
    end
    self:damageEnemiesInRadius(game.player.x, game.player.y, radius, dmg, game)
    self.auraRadius, self.auraPulse = radius, 1
end

function ClearcutMode:updateCrowStrike(dt, game)
    local level = self:levelOf("crow_strike")
    self.crowFx = self.crowFx or {}
    for i = #self.crowFx, 1, -1 do
        local fx = self.crowFx[i]
        fx.life = fx.life - dt
        if fx.life <= 0 then table.remove(self.crowFx, i) end
    end
    if level <= 0 then return end
    self.crowTimer = (self.crowTimer or 0) - dt
    if self.crowTimer > 0 then return end
    local power = self:power("crow_strike")
    self.crowTimer = math.max(1.4, 3.6 - power * .8)
    local range = 620
    local best, bestD2 = nil, -1
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            local d2 = dx*dx + dy*dy
            if d2 <= range*range and d2 > bestD2 then best, bestD2 = node, d2 end
        end
    end
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - game.player.x, e.y - game.player.y
        local d2 = dx*dx + dy*dy
        if d2 <= range*range and d2 > bestD2 then best, bestD2 = e, d2 end
    end
    if not best then return end
    local dmg = 6 + power * 5
    local radius = 55 + power * 10
    if best.rushTree then
        best.rushHp = (best.rushHp or best.rushMaxHp) - dmg
        game.world:impactNode(best, game, true)
        if best.rushHp <= 0 then self:fellTree(best, game) end
    else
        best.hp = best.hp - dmg
        best.visualHit = .14
    end
    self:damageEnemiesInRadius(best.x, best.y, radius, dmg * .5, game)
    self.crowFx[#self.crowFx+1] = {x=best.x, y=best.y, angle=math.atan2(best.y-game.player.y,best.x-game.player.x), life=.32, maxLife=.32}
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .12) end
end

function ClearcutMode:updateVineWhip(dt, game)
    local level = self:levelOf("vine_whip")
    self.whipFx = self.whipFx or {}
    for i = #self.whipFx, 1, -1 do
        local fx = self.whipFx[i]
        fx.life = fx.life - dt
        if fx.life <= 0 then table.remove(self.whipFx, i) end
    end
    if level <= 0 then return end
    local power = self:power("vine_whip")
    self.whipTimer = (self.whipTimer or 0) - dt
    if self.whipTimer > 0 then return end
    self.whipTimer = math.max(3.5, 8 - power * 1.5)
    local range = 140 + power * 85
    local nearest, nearestD2 = nil, range * range
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            local d2 = dx*dx + dy*dy
            if d2 <= nearestD2 then nearest, nearestD2 = node, d2 end
        end
    end
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - game.player.x, e.y - game.player.y
        local d2 = dx*dx + dy*dy
        if d2 <= nearestD2 then nearest, nearestD2 = e, d2 end
    end
    local atan2 = math.atan2 or math.atan
    local angle
    if nearest then angle = atan2(nearest.y - game.player.y, nearest.x - game.player.x)
    else angle = (game.player.facing or 1) > 0 and 0 or math.pi end
    local dmg = 4 + power * 2.5
    local cone = .75
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            local d2 = dx*dx + dy*dy
            if d2 <= range*range then
                local a = atan2(dy, dx)
                local diff = math.abs((a - angle + math.pi) % (math.pi * 2) - math.pi)
                if diff <= cone then
                    node.rushHp = (node.rushHp or node.rushMaxHp) - dmg
                    game.world:impactNode(node, game, false)
                    if node.rushHp <= 0 then self:fellTree(node, game) end
                end
            end
        end
    end
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - game.player.x, e.y - game.player.y
        local d2 = dx*dx + dy*dy
        if d2 <= range*range then
            local a = atan2(dy, dx)
            local diff = math.abs((a - angle + math.pi) % (math.pi * 2) - math.pi)
            if diff <= cone then
                e.hp = e.hp - dmg
                e.visualHit = .14
            end
        end
    end
    self.whipFx[#self.whipFx+1] = {x=game.player.x,y=game.player.y,angle=angle, range=range, life=.22, maxLife=.22}
end

function ClearcutMode:updateBoomerangAxe(dt, game)
    local level = self:levelOf("boomerang_axe")
    self.boomerangs = self.boomerangs or {}
    local speed = 480
    for i = #self.boomerangs, 1, -1 do
        local b = self.boomerangs[i]
        local remove, turning = false, false
        b.trail=b.trail or {}
        table.insert(b.trail,1,{x=b.x,y=b.y,angle=(self.supplementTime or 0)*17})
        if #b.trail>5 then table.remove(b.trail) end
        if b.phase == "out" then
            b.x, b.y = b.x + b.dx * speed * dt, b.y + b.dy * speed * dt
            b.traveled = b.traveled + speed * dt
            turning = b.traveled >= b.maxDist
        else
            local dx, dy = game.player.x - b.x, game.player.y - b.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < 24 then
                remove = true
            else
                b.x, b.y = b.x + dx / dist * speed * dt, b.y + dy / dist * speed * dt
            end
        end
        if remove then
            table.remove(self.boomerangs, i)
        else
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active and not b.hitSet[node] then
                    local dx2, dy2 = node.x - b.x, node.y - b.y
                    if dx2*dx2 + dy2*dy2 <= 30*30 then
                        b.hitSet[node] = true
                        SupplementArt.impact(self,"axe",node.x,node.y,24)
                        node.rushHp = (node.rushHp or node.rushMaxHp) - b.dmg
                        game.world:impactNode(node, game, false)
                        if node.rushHp <= 0 then self:fellTree(node, game) end
                    end
                end
            end
            for _, e in ipairs(self.enemies) do
                if not b.hitSet[e] then
                    local dx2, dy2 = e.x - b.x, e.y - b.y
                    if dx2*dx2 + dy2*dy2 <= 30*30 then
                        b.hitSet[e] = true
                        SupplementArt.impact(self,"axe",e.x,e.y,24)
                        e.hp = e.hp - b.dmg
                        e.visualHit = .14
                    end
                end
            end
        end
        -- Finish the outbound collision first, including its endpoint. Each leg
        -- may hit a target once; the return must not inherit outbound immunity.
        if turning and not remove then b.phase="back";b.hitSet={} end
    end
    if level <= 0 then return end
    local power = self:power("boomerang_axe")
    self.boomerangTimer = (self.boomerangTimer or 0) - dt
    if self.boomerangTimer > 0 then return end
    self.boomerangTimer = math.max(1.2, 2.6 - power * .4)
    local a = love.math.random() * math.pi * 2
    self.boomerangs[#self.boomerangs+1] = {
        x=game.player.x, y=game.player.y, dx=math.cos(a), dy=math.sin(a),
        traveled=0, maxDist=220 + power * 40, phase="out", hitSet={}, dmg=3 + power * 2, angle=a
    }
end

function ClearcutMode:updateSeedMine(dt, game)
    local level = self:levelOf("seed_mine")
    self.seeds = self.seeds or {}
    for i = #self.seeds, 1, -1 do
        local s = self.seeds[i]
        s.fuse = s.fuse - dt
        if s.fuse <= 0 then
            local radius = s.radius
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active then
                    local dx, dy = node.x - s.x, node.y - s.y
                    if dx*dx + dy*dy <= radius*radius then
                        node.rushHp = (node.rushHp or node.rushMaxHp) - s.dmg
                        game.world:impactNode(node, game, true)
                        if node.rushHp <= 0 then self:fellTree(node, game) end
                    end
                end
            end
            self:damageEnemiesInRadius(s.x, s.y, radius, s.dmg, game)
            SupplementArt.impact(self,"seed",s.x,s.y,radius)
            table.remove(self.seeds, i)
        end
    end
    if level <= 0 then return end
    local power = self:power("seed_mine")
    self.seedTimer = (self.seedTimer or 0) - dt
    if self.seedTimer > 0 then return end
    self.seedTimer = math.max(1.6, 3.2 - power * .5)
    local a = love.math.random() * math.pi * 2
    local r = 40 + love.math.random() * 120
    self.seeds[#self.seeds+1] = {
        x=game.player.x + math.cos(a) * r, y=game.player.y + math.sin(a) * r,
        fuse=1.1, maxFuse=1.1, radius=55 + power * 15, dmg=4 + power * 3
    }
end

function ClearcutMode:updateChainLightning(dt, game)
    local level = self:levelOf("chain_lightning")
    self.lightningFx = self.lightningFx or {}
    for i = #self.lightningFx, 1, -1 do
        local fx = self.lightningFx[i]
        fx.life = fx.life - dt
        if fx.life <= 0 then table.remove(self.lightningFx, i) end
    end
    if level <= 0 then return end
    local power = self:power("chain_lightning")
    self.lightningTimer = (self.lightningTimer or 0) - dt
    if self.lightningTimer > 0 then return end
    self.lightningTimer = math.max(1.8, 4 - power * .6)
    local jumps = 2 + self:powerCount("chain_lightning")
    local hopRange = 260
    local dmg = 3 + power * 2
    local visited = {}
    local cx, cy = game.player.x, game.player.y
    local points = {{x=cx, y=cy}}
    for _ = 1, jumps do
        local target, bestD2 = nil, hopRange * hopRange
        for _, node in ipairs(game.world.nodes) do
            if node.rushTree and node.active and not visited[node] then
                local dx, dy = node.x - cx, node.y - cy
                local d2 = dx*dx + dy*dy
                if d2 <= bestD2 then target, bestD2 = node, d2 end
            end
        end
        for _, e in ipairs(self.enemies) do
            if not visited[e] then
                local dx, dy = e.x - cx, e.y - cy
                local d2 = dx*dx + dy*dy
                if d2 <= bestD2 then target, bestD2 = e, d2 end
            end
        end
        if not target then break end
        visited[target] = true
        if target.rushTree then
            target.rushHp = (target.rushHp or target.rushMaxHp) - dmg
            game.world:impactNode(target, game, true)
            if target.rushHp <= 0 then self:fellTree(target, game) end
        else
            target.hp = target.hp - dmg
            target.visualHit = .14
        end
        points[#points+1] = {x=target.x, y=target.y}
        cx, cy = target.x, target.y
    end
    if #points > 1 then
        self.lightningFx[#self.lightningFx+1] = {points=points, life=.25, maxLife=.25}
    end
end

-- 코인 채굴꾼 전용: 지상에서 비트코인 하드월렛 암호를 무식하게 전수조사한다.
-- 전방의 지갑으로 숫자 레이저를 두두둑 입력한 뒤, 잠금이 열리는 순간 사방으로 발사된다.
function ClearcutMode:updateBruteForce(dt, game)
    self.digits = self.digits or {}
    self.bruteCastFx=self.bruteCastFx or {}
    self.bruteImpactFx=self.bruteImpactFx or {}
    for i=#self.bruteCastFx,1,-1 do local fx=self.bruteCastFx[i];fx.life=fx.life-dt;if fx.life<=0 then table.remove(self.bruteCastFx,i) end end
    for i=#self.bruteImpactFx,1,-1 do local fx=self.bruteImpactFx[i];fx.life=fx.life-dt;if fx.life<=0 then table.remove(self.bruteImpactFx,i) end end
    for i = #self.digits, 1, -1 do
        local d = self.digits[i]
        d.age=(d.age or 0)+dt
        if d.state=="charge" then
            if d.age<d.inputStart then
                d.x,d.y=d.startX,d.startY
            elseif d.age<d.arriveAt then
                local p=(d.age-d.inputStart)/(d.arriveAt-d.inputStart)
                local step=math.floor(p*8)/8
                d.x=d.startX+(d.walletX-d.startX)*step
                d.y=d.startY+(d.walletY-d.startY)*step+math.sin((d.index or 0)*2.3)*3
            else
                local orbit=(d.index or 0)/12*math.pi*2
                d.x=d.walletX+math.cos(orbit)*8
                d.y=d.walletY+math.sin(orbit)*5
            end
            if d.age>=d.launchAt then d.state="fly";d.x,d.y=d.walletX,d.walletY;d.life=.9 end
        elseif d.state=="fly" then
            d.x,d.y=d.x+d.vx*dt,d.y+d.vy*dt
            d.life=d.life-dt
            if d.life<=0 then table.remove(self.digits,i) else
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active and not d.hitSet[node] then
                    local dx, dy = node.x - d.x, node.y - d.y
                    if dx*dx + dy*dy <= 18*18 then
                        d.hitSet[node] = true
                        node.rushHp = (node.rushHp or node.rushMaxHp) - d.dmg
                        game.world:impactNode(node, game, false)
                        self.bruteImpactFx[#self.bruteImpactFx+1]={x=node.x,y=node.y,life=.34,maxLife=.34,glyph=d.glyph}
                        if node.rushHp <= 0 then self:fellTree(node, game) end
                    end
                end
            end
            for _, e in ipairs(self.enemies) do
                if not d.hitSet[e] then
                    local dx, dy = e.x - d.x, e.y - d.y
                    if dx*dx + dy*dy <= 18*18 then
                        d.hitSet[e] = true
                        e.hp = e.hp - d.dmg
                        e.visualHit = .14
                        self.bruteImpactFx[#self.bruteImpactFx+1]={x=e.x,y=e.y,life=.34,maxLife=.34,glyph=d.glyph}
                    end
                end
            end
            end
        end
    end
    if self.job ~= "miner" then return end
    local level = self:levelOf("brute_force")
    if level <= 0 then return end
    local power = self:power("brute_force")
    self.bruteTimer = (self.bruteTimer or 0) - dt
    if self.bruteTimer > 0 then return end
    if self.minerBurrow then return end
    self.bruteTimer = math.max(.9, 2.2 - power * .4)
    local oldCount=5+self:powerCount("brute_force")*3
    local count=22+self:powerCount("brute_force")*4
    local dmg=oldCount*(2+power)/count
    local speed=350+power*12
    local facing=game.player.facing or 1
    local startX,startY=game.player.x+facing*24,game.player.y-38
    -- Keep the encrypted target clear of the mole so the rapid number input
    -- reads as a deliberate hack beam instead of a body attachment.
    local walletX,walletY=game.player.x+facing*205,game.player.y-22
    for index=1,count do
        local a=(index/count)*math.pi*2+love.math.random()*.16
        local inputStart=(index-1)*.008
        self.digits[#self.digits+1] = {
            x=startX,y=startY,startX=startX,startY=startY,walletX=walletX,walletY=walletY,
            vx=math.cos(a) * speed, vy=math.sin(a) * speed,
            state="charge",age=0,visibleAt=inputStart,inputStart=inputStart,arriveAt=inputStart+.30,launchAt=.67+(index-1)*.0015,
            life=.9,dmg=dmg,hitSet={},glyph=tostring(love.math.random(0,9)),index=index
        }
    end
    self.bruteCastFx[#self.bruteCastFx+1]={x=walletX,y=walletY,life=.82,maxLife=.82,startX=startX,startY=startY,facing=facing}
    game:setNotice("브루트포스 어택 — 비트코인 지갑 암호 대입 중...", "food")
end

function ClearcutMode:updateDdosAttack(dt, game)
    self.packets = self.packets or {}
    for i = #self.packets, 1, -1 do
        local p = self.packets[i]
        p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
        p.life = p.life - dt
        local hit = false
        if p.life <= 0 then
            table.remove(self.packets, i)
        else
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active then
                    local dx, dy = node.x - p.x, node.y - p.y
                    if dx*dx + dy*dy <= 14*14 then
                        node.rushHp = (node.rushHp or node.rushMaxHp) - p.dmg
                        game.world:impactNode(node, game, false)
                        if node.rushHp <= 0 then self:fellTree(node, game) end
                        hit = true
                        break
                    end
                end
            end
            if not hit then
                for _, e in ipairs(self.enemies) do
                    local dx, dy = e.x - p.x, e.y - p.y
                    if dx*dx + dy*dy <= 14*14 then
                        e.hp = e.hp - p.dmg
                        e.visualHit = .14
                        hit = true
                        break
                    end
                end
            end
            if hit then table.remove(self.packets, i) end
        end
    end
    if self.job ~= "miner" then return end
    local level = self:levelOf("ddos_attack")
    if level <= 0 then return end
    local power = self:power("ddos_attack")
    self.ddosBurst = self.ddosBurst or 0
    self.ddosShotTimer = (self.ddosShotTimer or 0) - dt
    if self.ddosBurst > 0 and self.ddosShotTimer <= 0 then
        self.ddosShotTimer = .07
        self.ddosBurst = self.ddosBurst - 1
        local dx, dy = self.ddosTargetX - game.player.x, self.ddosTargetY - game.player.y
        local d = math.sqrt(dx*dx + dy*dy)
        if d > 0 then
            self.packets[#self.packets+1] = {x=game.player.x, y=game.player.y, vx=dx/d*620, vy=dy/d*620, life=1, dmg=2+power}
        end
    end
    self.ddosTimer = (self.ddosTimer or 0) - dt
    if self.ddosTimer > 0 then return end
    self.ddosTimer = math.max(1.6, 3.4 - power * .5)
    local best, bestD2 = nil, 620 * 620
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            local d2 = dx*dx + dy*dy
            if d2 <= bestD2 then best, bestD2 = node, d2 end
        end
    end
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - game.player.x, e.y - game.player.y
        local d2 = dx*dx + dy*dy
        if d2 <= bestD2 then best, bestD2 = e, d2 end
    end
    if not best then return end
    self.ddosTargetX, self.ddosTargetY = best.x, best.y
    self.ddosBurst = 5 + self:powerCount("ddos_attack") * 2
    game:setNotice("DDoS 공격 — 트래픽 폭주!", "food")
end

function ClearcutMode:updateRansomware(dt, game)
    self.infections = self.infections or {}
    for i = #self.infections, 1, -1 do
        local inf = self.infections[i]
        local node = inf.node
        local alive = node.rushTree and node.active
        if alive then
            inf.tickTimer = (inf.tickTimer or 0) - dt
            if inf.tickTimer <= 0 then
                inf.tickTimer = .6
                node.rushHp = (node.rushHp or node.rushMaxHp) - inf.dmg
                game.world:impactNode(node, game, false)
                if node.rushHp <= 0 then
                    self:fellTree(node, game)
                    alive = false
                    local spreadRadius = 140
                    local target, bestD2 = nil, spreadRadius * spreadRadius
                    for _, other in ipairs(game.world.nodes) do
                        if other.rushTree and other.active and not other.ransomwareMarked then
                            local dx, dy = other.x - node.x, other.y - node.y
                            local d2 = dx*dx + dy*dy
                            if d2 <= bestD2 then target, bestD2 = other, d2 end
                        end
                    end
                    if target then
                        target.ransomwareMarked = true
                        self.infections[#self.infections+1] = {node=target, dmg=inf.dmg, tickTimer=.6}
                    end
                end
            end
        end
        if not alive then
            node.ransomwareMarked = nil
            table.remove(self.infections, i)
        end
    end
    if self.job ~= "miner" then return end
    local level = self:levelOf("ransomware")
    if level <= 0 then return end
    local power = self:power("ransomware")
    self.ransomwareTimer = (self.ransomwareTimer or 0) - dt
    if self.ransomwareTimer > 0 then return end
    self.ransomwareTimer = math.max(2.5, 5 - power)
    local range = 460
    local target, bestD2 = nil, range * range
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and not node.ransomwareMarked then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            local d2 = dx*dx + dy*dy
            if d2 <= bestD2 then target, bestD2 = node, d2 end
        end
    end
    if not target then return end
    target.ransomwareMarked = true
    self.infections[#self.infections+1] = {node=target, dmg=1.5 + power * 1.2, tickTimer=0}
end

function ClearcutMode:updateZeroDay(dt, game)
    self.zerodayFx = self.zerodayFx or {}
    for i = #self.zerodayFx, 1, -1 do
        local fx = self.zerodayFx[i]
        fx.life = fx.life - dt
        if fx.life <= 0 then table.remove(self.zerodayFx, i) end
    end
    if self.job ~= "miner" then return end
    local level = self:levelOf("zeroday_exploit")
    if level <= 0 then return end
    local power = self:power("zeroday_exploit")
    self.zerodayTimer = (self.zerodayTimer or 0) - dt
    if self.zerodayTimer > 0 then return end
    self.zerodayTimer = math.max(6, 13 - power * 2.5)
    local range = 700
    local candidates = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            if dx*dx + dy*dy <= range*range then candidates[#candidates+1] = node end
        end
    end
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - game.player.x, e.y - game.player.y
        if dx*dx + dy*dy <= range*range then candidates[#candidates+1] = e end
    end
    if #candidates == 0 then return end
    local target = candidates[love.math.random(#candidates)]
    local dmg = 40 + power * 30
    if target.rushTree then
        target.rushHp = (target.rushHp or target.rushMaxHp) - dmg
        game.world:impactNode(target, game, true)
        if target.rushHp <= 0 then self:fellTree(target, game) end
    else
        target.hp = target.hp - dmg
        target.visualHit = .2
    end
    self:damageEnemiesInRadius(target.x, target.y, 70, dmg * .4, game)
    self.zerodayFx[#self.zerodayFx+1] = {x=target.x, y=target.y, life=.5, maxLife=.5}
    game:setNotice("제로데이 익스플로잇 — 치명적 취약점 발견!", "food")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .4) end
end

function ClearcutMode:updatePortScan(dt, game)
    self.portScanFx = self.portScanFx or {}
    for i = #self.portScanFx, 1, -1 do
        local fx = self.portScanFx[i]
        fx.life = fx.life - dt
        if fx.life <= 0 then table.remove(self.portScanFx, i) end
    end
    if self.job ~= "miner" then return end
    local level = self:levelOf("port_scan")
    if level <= 0 then return end
    local power = self:power("port_scan")
    self.portScanTimer = (self.portScanTimer or 0) - dt
    if self.portScanTimer > 0 then return end
    self.portScanTimer = math.max(1.8, 3.6 - power * .6)
    local range = 500
    local threshold = .18 + power * .07
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            if dx*dx + dy*dy <= range*range then
                local frac = (node.rushHp or node.rushMaxHp) / node.rushMaxHp
                if frac > 0 and frac <= threshold then
                    node.rushHp = 0
                    game.world:impactNode(node, game, true)
                    self:fellTree(node, game)
                    self.portScanFx[#self.portScanFx+1] = {x=node.x, y=node.y, life=.3, maxLife=.3}
                end
            end
        end
    end
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - game.player.x, e.y - game.player.y
        if dx*dx + dy*dy <= range*range then
            local frac = e.hp / e.maxHp
            if frac > 0 and frac <= threshold then
                e.hp = 0
                self.portScanFx[#self.portScanFx+1] = {x=e.x, y=e.y, life=.3, maxLife=.3}
            end
        end
    end
end

function ClearcutMode:updatePhilosopherAttack(dt, game, heldOverride)
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    local maxRange = 200 + self:power("monologue") * 30 + self:power("loud_voice") * 30 + self.permanentTraits.range
    local tx, ty = self:aimPoint(game, maxRange)
    game.player.facing = tx < game.player.x and -1 or 1
    if held then
        self.rantTimer = math.min(3, (self.rantTimer or 0) + dt)
    else
        self.rantTimer = math.max(0, (self.rantTimer or 0) - dt * 2)
    end
    local verbosity = math.min(1, (self.rantTimer or 0) / 3)
    self.aimX, self.aimY = tx, ty
    self.aimRadius = (55 + self:power("monologue") * 10 + self:power("loud_voice") * 20) * (1 + verbosity * .55) + self.permanentTraits.area
    if game.player.setClearcutAction then game.player:setClearcutAction(.5 + verbosity * .3) end
    local wasHeld = self.rantHeldLast
    self.rantHeldLast = held
    if not held then
        if wasHeld and verbosity >= .999 and self.evolutions.eternal_return then
            self:applySpit(self.aimX, self.aimY, 1, game, true)
        end
        if game.player.clearClearcutAction then game.player:clearClearcutAction() end
        return false
    end
    self.spitTimer = (self.spitTimer or 0) - dt
    if self.spitTimer > 0 then return false end
    local rate = math.max(.14, (.5 - self:power("footnote") * .1 - verbosity * .2) / self.permanentTraits.attackSpeed)
    self.spitTimer = rate
    self:applySpit(tx, ty, verbosity, game)
    return true
end

function ClearcutMode:applySpit(tx, ty, verbosity, game, isBonus, isExtra)
    local radius = (self.aimRadius or 60) * (isBonus and 1.8 or 1)
    local dmg = 2 + self:power("monologue") + verbosity * 2 + self.permanentTraits.biteDamage
    local salivaLevel = self:levelOf("saliva_gland")
    local plagueTimer = (isBonus and 7 or 4) + self.permanentTraits.plagueDuration
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - tx, node.y - ty
            if dx*dx + dy*dy <= radius*radius then
                node.rushHp = (node.rushHp or node.rushMaxHp) - dmg
                game.world:impactNode(node, game, true)
                if node.rushHp <= 0 then self:fellTree(node, game)
                elseif salivaLevel > 0 and not node.plagueMarked then
                    node.plagueMarked = true
                    self.plagued[#self.plagued+1] = {kind="tree", ref=node, timer=plagueTimer, tickTimer=0}
                end
            end
        end
    end
    if salivaLevel > 0 then
        for _, e in ipairs(self.enemies) do
            local dx, dy = e.x - tx, e.y - ty
            if dx*dx + dy*dy <= radius*radius and not e.plagueMarked then
                e.plagueMarked = true
                self.plagued[#self.plagued+1] = {kind="enemy", ref=e, timer=plagueTimer, tickTimer=0}
            end
        end
    end
    self:damageEnemiesInRadius(tx, ty, radius, dmg * 2.2, game)
    game.world:toxicPulseFx(tx, ty, radius)
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + (isBonus and .3 or .08)) end
    if not isExtra then
        for _ = 1, math.floor(self.permanentTraits.extraTargets) do
            local a = love.math.random() * math.pi * 2
            local r = radius * .6
            self:applySpit(tx + math.cos(a) * r, ty + math.sin(a) * r, verbosity, game, false, true)
        end
    end
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
    return 200 + self:power("pile_driving") * 70 + self.permanentTraits.range
end

function ClearcutMode:developerDashWidth()
    return 55 + self:power("heavy_machinery") * 20 + self.permanentTraits.area
end

function ClearcutMode:startDash(tx, ty, game)
    local dx, dy = tx - game.player.x, ty - game.player.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist < 1 then return end
    local heavyLevel = self:levelOf("heavy_machinery")
    local width = self:developerDashWidth()
    local megaProject = heavyLevel >= 6 and love.math.random() < .2
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
    local speed = 720 * self.permanentTraits.dashSpeed
    local moveDist = math.min(d.remaining, speed * dt)
    local px, py = game.player.x, game.player.y
    game.player.x, game.player.y = game.player.x + d.dx * moveDist, game.player.y + d.dy * moveDist
    game.player.x,game.player.y=require("src.clearcut_maps").constrain(game.world,game.player.x,game.player.y,18)
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
                    if siteLevel >= 6 or (siteLevel > 0 and love.math.random() < self:power("site_clearance") * .3) then node.sterile = true end
                end
            end
        end
    end
    self:damageEnemiesInRadius((px + game.player.x) / 2, (py + game.player.y) / 2, d.width + 20, 12, game)
    if d.remaining <= 0 then
        self.dashing = nil
        if game.player.clearClearcutAction then game.player:clearClearcutAction() end
        if self:levelOf("demolition") > 0 then self:demolitionBlast(game.player.x, game.player.y, game) end
        self:traitAftershock(game.player.x, game.player.y, game)
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
        self.attackCooldown = math.max(1, (3.2 - self:power("pile_driving") * .7) / self.permanentTraits.attackSpeed)
        if (pileLevel >= 6 and love.math.random() < .25) or love.math.random() < self.permanentTraits.cooldownRefund then
            self.attackCooldown = 0
            game:setNotice("기초 공사 완료 — 말뚝 박기 만렙 특수효과!", "food")
        end
    end
end

function ClearcutMode:traitAftershock(x, y, game)
    local bonus = self.permanentTraits.aftershockRadius
    if bonus <= 0 then return end
    local radius = 20 + bonus
    self.traitFx:emit("blast", x, y, {radius=radius, particles=14})
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - x, node.y - y
            if dx*dx + dy*dy <= radius*radius then
                node.rushHp = (node.rushHp or node.rushMaxHp) - 1
                game.world:impactNode(node, game, true)
                if node.rushHp <= 0 then self:fellTree(node, game) end
            end
        end
    end
    self:damageEnemiesInRadius(x, y, radius, 8, game)
end

function ClearcutMode:demolitionBlast(x, y, game)
    local demoLevel = self:levelOf("demolition")
    local radius = 90 + self:power("demolition") * 30
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
    if demoLevel >= 6 and #felled > 0 then
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
    local xpMult = 1 + self:power("forced_growth") * .4
    self.xp = self.xp + amount * xpMult
    while self.xp >= self.xpNext do
        self.xp = self.xp - self.xpNext
        self.level, self.pending = self.level + 1, self.pending + 1
        self.xpNext = math.floor(10 + (self.level - 1) * 6.5)
    end
    if self.pending > 0 and game.mode == "playing" and not self.sandbox and not os.getenv("LAST_HAUL_SELF_TEST") then self:openUpgradeChoices(game) end
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
    if #self.choices==0 then self.choices[1]=recoveryChoice end
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
    if self:checkEvolutions(game) then return end
    self.rerollCount, self.banishArmed, self.selectionKind = 0, false, "upgrade"
    self:rollChoices()
    self.specialCard = nil
    if love.math.random() < .12 and #self:arcanaPool() > 0 then
        local pool = self:arcanaPool()
        self.specialCard = pool[love.math.random(#pool)]
        self.specialCardRevealAt = love.timer.getTime()
    end
    -- 렙업 순간에 마우스를 누른 채로 공격 중이면 카드가 뜨자마자 클릭돼버리므로,
    -- 카드가 뒤집혀 등장하는 짧은 시간 동안은 선택 입력을 잠근다.
    self.choicesRevealAt = love.timer.getTime()
    game.mode = "clearcut_upgrade"
end

function ClearcutMode:choicesLocked()
    return love.timer.getTime() - (self.choicesRevealAt or 0) < .62
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
    if #pool > 0 then self.choices[index] = pool[love.math.random(#pool)]
    else table.remove(self.choices,index) end
    if #self.choices==0 then self.choices[1]=recoveryChoice end
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

-- Guaranteed acquisition screen; never mixed into a random upgrade pool.
function ClearcutMode:checkEvolutions(game)
    local def=Fusions.nextReady(self)
    if not def then return false end
    self.fusionChoice=def
    self.selectionKind="fusion"
    self.specialCard=nil
    self.banishArmed=false
    self.choiceBoxes={}
    self.choicesRevealAt = love.timer.getTime()
    game.mode="clearcut_upgrade"
    return true
end

function ClearcutMode:chooseFusion(index,game)
    local def=self.fusionChoice
    if index~=1 or not def or not Fusions.ready(self,def) then return false end
    self.evolutions[def.id]=true
    self.fusionChoice=nil
    self.selectionKind="upgrade"
    self.choices={}
    self.choiceBoxes={}
    self.chestPending=false
    game:setNotice("융합 획득 — "..def.name.."! "..def.desc,"ore")
    if self:checkEvolutions(game) then return true end
    if (self.fusionChestRewards or 0)>0 then
        self.fusionChestRewards=self.fusionChestRewards-1
        game.mode="playing"
        self:openChest(game)
        return true
    end
    if self.pending>0 then self:openUpgradeChoices(game) else game.mode="playing" end
    return true
end

function ClearcutMode:choose(index, game)
    if self.selectionKind == "fusion" then return self:chooseFusion(index,game) end
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
    if not def.recovery and (not upgradeById[def.id] or self:levelOf(def.id)>=def.max
        or (def.job and self.job and def.job~=self.job)) then return false end
    if self.banishArmed then
        if jobFor[def.id] or def.recovery then game:setNotice("이 카드는 제외할 수 없습니다", "ore"); return false end
        if self.totalWood<self:banishCost() then return false end
        self.totalWood = self.totalWood - self:banishCost()
        self.banished[def.id] = true
        self.banishArmed = false
        self:refillChoice(index)
        game:setNotice(def.name .. " — 영구 제외", "ore")
        return true
    end
    local wasChest=self.chestPending
    self.chestPending=false
    if def.recovery then self.hp=math.min(self.maxHp,self.hp+20)
    else self.levels[def.id]=self:levelOf(def.id)+1 end
    if not wasChest then self.pending=math.max(0,self.pending-1) end
    if def.recovery then
        game:setNotice("현장 휴식 — 체력 +20","food")
    elseif not self.job and jobFor[def.id] and self.levels[def.id]==1 then
        self.job = jobFor[def.id]
        self.attackCooldown = 0
        game:setNotice("1차 전직 — " .. jobNames[self.job] .. "! " .. jobDesc[self.job], "ore")
    else
        game:setNotice(def.name.." Lv."..self:levelOf(def.id),"food")
    end
    self.choices={}
    self.choiceBoxes={}
    if self:checkEvolutions(game) then return true end
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
    if love.math.random() < (self.permanentTraits.sterileChance or 0) then
        node.sterile = true
    end
    if self.permanentTraits.healOnFell and self.permanentTraits.healOnFell > 0 then
        self.hp = math.min(self.maxHp, self.hp + self.permanentTraits.healOnFell)
    end
    if wasBeehive and #self.bees < 5 then
        self.bees[#self.bees+1] = {x=node.x, y=node.y, speed=150, life=7}
        self.beeSwarmsTriggered = self.beeSwarmsTriggered + 1
        game:setNotice("벌집을 건드렸다 — 벌떼가 쫓아온다!", "ore")
    end
    if not self.sandbox then self:checkMilestones(game) end
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

function ClearcutMode:frenzyShockwave(x,y,game)
    local radius=145
    self:damageEnemiesInRadius(x,y,radius,12,game)
    self.traitFx:emit("construction_blast",x,y,{radius=radius,particles=18,power=.8,color={1,.78,.3}})
    local felled=0
    for _,node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and (node.x-x)^2+(node.y-y)^2<=radius^2 then
            node.rushHp=(node.rushHp or node.rushMaxHp)-3
            game.world:impactNode(node,game,true)
            if node.rushHp<=0 and self:fellTree(node,game) then felled=felled+1 end
        end
    end
    self.maxChain=math.max(self.maxChain,felled)
end

function ClearcutMode:hitTree(primary, game)
    if not primary.active then return end
    self.streak = self.streak + 1
    self.lastHitAt = self.elapsed
    local wideLevel = self:levelOf("wide_blade")
    local widePower = self:power("wide_blade")
    local radius = 75 + widePower * 45 + self.permanentTraits.area
    local targetCount = 1 + self:powerCount("wide_blade") * 2 + math.floor(self.permanentTraits.extraTargets)
    self:damageEnemiesInRadius(primary.x, primary.y, radius, 9 + self:power("berserker") * 2, game)
    if wideLevel >= 6 and love.math.random() < .15 then self:megaCleave(primary, game) end
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
    local executeChance = self.permanentTraits.executeChance or 0
    for i=1,hits do
        local node=candidates[i].node
        node.rushHp=(node.rushHp or node.rushMaxHp)-(1+self.permanentTraits.treeDamage)
        if executeChance > 0 and love.math.random() < executeChance then node.rushHp = 0 end
        game.world:impactNode(node,game,false)
        if node.rushHp<=0 and self:fellTree(node,game) then felled[#felled+1]=node end
    end
    -- One wave per axe contact, not per multi-hit target. No recursive shock loops.
    if frenzyActive then self:frenzyShockwave(primary.x,primary.y,game) end
    local shockLevel = self:levelOf("shockwave")
    if shockLevel > 0 and #felled > 0 then
        local shockPower = self:power("shockwave")
        local shockRadius = 70 + shockPower * 25
        local hitSet, chainCount, shockFelled = {}, 0, {}
        for _, source in ipairs(felled) do
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active and not hitSet[node] then
                    local dx, dy = node.x - source.x, node.y - source.y
                    if dx*dx + dy*dy <= shockRadius * shockRadius then
                        hitSet[node] = true
                        node.rushHp = (node.rushHp or node.rushMaxHp) - shockPower
                        game.world:impactNode(node, game, true)
                        if node.rushHp <= 0 and self:fellTree(node, game) then chainCount = chainCount + 1; shockFelled[#shockFelled+1] = node end
                    end
                end
            end
        end
        if shockLevel >= 6 and #shockFelled > 0 then
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
    if not self.sandbox then self:checkMilestones(game) end
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
-- Legacy model/baker definitions retained for provenance only. The active v3
-- bodies are ForestArt sprites, never these enlarged grids or linear canvases.
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

-- Legacy block model kept for provenance only; flights/ground use CigaretteButtArt.
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

-- 재장전(다음 꽁초를 던질 수 있을 때까지의 대기시간) 바. `[------------------]`
-- 형태의 얇은 픽셀 대시 트랙 가운데를 막대 하나가 왼쪽(방금 던짐)에서 오른쪽
-- (=가득 참)으로 이동한다. 좌표를 math.floor로 정수에 고정해 안티에일리어싱 없이
-- 각진 픽셀 그대로 보이게 그린다. 장전이 다 되면(ready) 바 자체를 그리지 않고 사라진다.
function ClearcutMode:drawSmokerReloadBar(game)
    local smoking = self.smoking
    if not smoking or smoking.phase ~= "reload" then return end
    local charge = math.min(1, smoking.t / smoking.dur)
    local w, h, px = 96, 2, 2
    local x = math.floor(game.player.x - w / 2)
    local y = math.floor(game.player.y - 120)
    local capH = 8

    love.graphics.setColor(0, 0, 0, .4)
    love.graphics.rectangle("fill", x - px - 2, y - capH / 2 - 2, w + px * 2 + 4, capH + 4)

    -- 대괄호 [ ]
    love.graphics.setColor(1, 1, 1, .6)
    love.graphics.rectangle("fill", x - px, y - capH / 2, px, capH)
    love.graphics.rectangle("fill", x + w, y - capH / 2, px, capH)

    -- 대시 트랙
    love.graphics.setColor(1, 1, 1, .32)
    local dash, gap = px * 2, px * 2
    local dx = x
    while dx < x + w - .5 do
        love.graphics.rectangle("fill", dx, y - px / 2, math.min(dash, x + w - dx), px)
        dx = dx + dash + gap
    end

    -- 움직이는 막대
    local barW = px * 3
    local barX = math.floor(x + charge * (w - barW))
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", barX - px, y - capH / 2 - px, barW + px * 2, capH + px * 2)
    love.graphics.setColor(1, .68, .26, 1)
    love.graphics.rectangle("fill", barX, y - capH / 2, barW, capH)
end

function ClearcutMode:drawSmokerCigarette(game)
    if self.job~="fire" or not self.smoking or self.smoking.phase=="flick" then return false end
    local mouthX,mouthY,facing,tipX=self:smokerMouthPose(game)
    local sprite=game.player.clearcutSprite
    if sprite and sprite.walkMouth then
        if sprite.cigarette then
            Cigarette.draw(sprite.cigarette,mouthX,mouthY,facing,love.timer.getTime())
        end
        return true
    end
    drawFacingPixelGrid(cigaretteIconRows,cigaretteIconPalette,(mouthX+tipX)/2,mouthY-2,2,facing)
    return true
end

function ClearcutMode:drawCigaretteProjectiles(t)
    for _,flight in ipairs(self.molotovs) do CigaretteButtArt.drawFlight(flight,self.smokerGroundTime) end
    return #self.molotovs
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

local pickaxeIconRows = {
    "OO......",
    ".OMO....",
    "..OMO...",
    "...OMMO.",
    "..OHMO..",
    "..OHO...",
    "..OHO...",
    "..OO....",
}
local pickaxeIconPalette = {O={.12,.1,.08,1}, M={.75,.77,.8,1}, H={.45,.3,.15,1}}

local speechIconRows = {
    "OOOOOOOO",
    "OWWWWWWO",
    "OWWSWSWO",
    "OWWWWWWO",
    "OWSWWSWO",
    "OOOOOOOO",
    "..OO....",
    ".O......",
}
local speechIconPalette = {O={.16,.2,.06,1}, W={.92,.97,.82,1}, S={.6,.78,.28,1}}

local batIconRows = {
    "O.....O",
    "OO...OO",
    "OOOOOOO",
    ".OOOOO.",
    "..OWO..",
    "..O.O..",
    ".O...O.",
}
local batIconPalette = {O={.16,.12,.2,1}, W={.9,.8,.3,1}}

local thornIconRows = {
    "....O....",
    "...OVO...",
    "..OVOVO..",
    ".OVOOOVO.",
    "OVOOOOOVO",
    ".OVOOOVO.",
    "..OVOVO..",
    "...OVO...",
    "....O....",
}
local thornIconPalette = {O={.1,.22,.06,1}, V={.42,.7,.3,1}}

local crowIconRows = {
    "O......O",
    "OO....OO",
    "OOO..OOO",
    ".OOOOOO.",
    "..OWOWO.",
    "...OOO..",
    "....O...",
}
local crowIconPalette = {O={.08,.07,.1,1}, W={.85,.3,.2,1}}

local vineIconRows = {
    "..O......",
    ".OVO.....",
    "..OVO....",
    "...OVO...",
    "....OVO..",
    "...OVO.O.",
    "..OVO.OVO",
    ".O......O",
}
local vineIconPalette = {O={.1,.2,.06,1}, V={.4,.65,.24,1}}

local seedIconRows = {
    "...O....",
    "..OVO...",
    ".OVVVO..",
    "OVVVVVO.",
    "OVVVVVO.",
    ".OVVVO..",
    "..OVO...",
    "...O....",
}
local seedIconPalette = {O={.22,.14,.05,1}, V={.72,.5,.24,1}}

local lightningIconRows = {
    "...OO...",
    "..OZO...",
    ".OZO....",
    "OZOOOO..",
    "..OOZO..",
    "....OZO.",
    "....OZ..",
    "....O...",
}
local lightningIconPalette = {O={.08,.24,.32,1}, Z={.55,.9,1,1}}

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
local forcedGrowthPalette = {O={.16,.22,.05,1}, H={.85,.95,.6,1}, T={.4,.72,.22,1}}
local pileDrivingPalette = {O={.2,.14,.06,1}, H={.92,.85,.7,1}, T={.55,.4,.2,1}}
local toxicRainPalette = {O={.14,.24,.1,1}, H={.9,.98,.85,1}, W={.6,.85,.5,1}}
local footnotePalette = {O={.16,.22,.04,1}, H={.9,.98,.6,1}, W={.85,.9,.4,1}}
local loudVoicePalette = {O={.1,.16,.04,1}, H={.82,.95,.5,1}, W={.65,.8,.3,1}}
local salivaGlandPalette = {O={.1,.15,.03,1}, H={.78,.92,.42,1}, W={.55,.72,.25,1}}
local boomerangAxePalette = {O={.14,.09,.05,1}, M={.75,.77,.8,1}, H={.55,.55,.6,1}}
local bruteForcePalette = {O={.05,.2,.08,1}, H={.55,1,.6,1}, W={.25,.85,.35,1}}

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

ClearcutMode.icons = {
    axe = {rows = axeIconRows, palette = axeIconPalette},
    cigarette = {rows = cigaretteIconRows, palette = cigaretteIconPalette},
    leaf = {rows = leafIconRows, palette = leafIconPalette},
    hardhat = {rows = hardhatIconRows, palette = hardhatIconPalette},
    wide_blade = {rows = diamondRows, palette = wideBladePalette},
    berserker = {rows = boxRows, palette = berserkerPalette},
    shockwave = {rows = diamondRows, palette = shockwavePalette},
    dry_forest = {rows = diamondRows, palette = dryForestPalette},
    oil_drum = {rows = boxRows, palette = oilDrumPalette},
    toxic_rain = {rows = blobRows, palette = toxicRainPalette},
    forced_growth = {rows = stickRows, palette = forcedGrowthPalette},
    pile_driving = {rows = stickRows, palette = pileDrivingPalette},
    heavy_machinery = {rows = heavyMachineryRows, palette = heavyMachineryPalette},
    demolition = {rows = diamondRows, palette = demolitionPalette},
    site_clearance = {rows = boxRows, palette = siteClearancePalette},
    pickaxe = {rows = pickaxeIconRows, palette = pickaxeIconPalette},
    detector = {rows = rootCuttingRows, palette = rootCuttingPalette},
    burrow_uproot = {rows = rootCuttingRows, palette = rootCuttingPalette},
    speech = {rows = speechIconRows, palette = speechIconPalette},
    monologue = {rows = speechIconRows, palette = speechIconPalette},
    footnote = {rows = stickRows, palette = footnotePalette},
    loud_voice = {rows = diamondRows, palette = loudVoicePalette},
    saliva_gland = {rows = blobRows, palette = salivaGlandPalette},
    bat_swarm = {rows = batIconRows, palette = batIconPalette},
    thorn_aura = {rows = thornIconRows, palette = thornIconPalette},
    crow_strike = {rows = crowIconRows, palette = crowIconPalette},
    vine_whip = {rows = vineIconRows, palette = vineIconPalette},
    boomerang_axe = {rows = axeIconRows, palette = boomerangAxePalette},
    seed_mine = {rows = seedIconRows, palette = seedIconPalette},
    chain_lightning = {rows = lightningIconRows, palette = lightningIconPalette},
    brute_force = {rows = boxRows, palette = bruteForcePalette},
}
ClearcutMode.drawPixelGrid = drawPixelGrid

-- Threat markers remain above the canopy for combat readability; bodies do not.
local function drawEnemyThreat(e, t)
    BiomeEnemies.drawWarning(e)
    local def = e.def
    local walking = def.speed > 0 and (e.moving or false)
    local seed = e.seed or 0
    local bob = walking and math.abs(math.sin(t * 6 + seed)) * def.radius * .05 or (def.boss and math.sin(t * 1.6 + seed) * def.radius * .03 or 0)
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
    ForestArt.drawHealth(e,t)
end

-- Shared by the real world depth queue and headless renderer tests.
ClearcutMode.drawEnemy = ForestArt.drawBody
function ClearcutMode:queueWorldActors(queue,t)
    local groundTime=self.smokerGroundTime
    for _,value in ipairs(self.burrowTracks) do
        local mark=value
        queue[#queue+1]={y=-200000+mark.y*.001,draw=function() MoleBurrowArt.draw(mark) end}
    end
    for _,value in ipairs(self.strawBales) do
        local bale=value
        queue[#queue+1]={y=bale.y,draw=function() StrawBaleArt.draw(bale,groundTime) end}
    end
    for index,value in ipairs(self.oilTrail) do
        local spot=value
        -- Ground liquid is always behind actors; flame/smoke participates in
        -- the regular quarter-view foot-depth order.
        queue[#queue+1]={y=-100000+spot.y*.001,draw=function() OilTrailArt.drawGround(spot,groundTime) end}
        if spot.ignited then
            queue[#queue+1]={y=spot.y+.1,draw=function() OilTrailArt.drawFlame(spot,groundTime) end}
        end
        local previous=self.oilTrail[index-1]
        if previous then
            queue[#queue+1]={y=-99999+math.min(previous.y,spot.y)*.001,draw=function() OilTrailArt.drawGroundBridge(previous,spot,groundTime) end}
            if previous.ignited and spot.ignited then
                queue[#queue+1]={y=(previous.y+spot.y)*.5+.1,draw=function() OilTrailArt.drawFlameBridge(previous,spot,groundTime) end}
            end
        end
    end
    for _,value in ipairs(self.cigaretteButts) do
        local butt=value
        queue[#queue+1]={y=butt.y+3,draw=function() CigaretteButtArt.drawGround(butt,groundTime) end}
    end
    for _, value in ipairs(self.enemies) do
        local enemy=value
        queue[#queue+1]={y=ForestArt.footY(enemy),draw=function() ForestArt.drawBody(enemy,t) end}
    end
    for _, value in ipairs(self.vineSpawns) do
        local sprout=value
        local grow=1-math.max(0,sprout.timer)/1.15
        if grow>.3 then
            local growth=math.min(1,(grow-.3)/.7)
            queue[#queue+1]={y=sprout.y,draw=function() ForestArt.drawSprout(sprout.x,sprout.y,growth,t) end}
        end
    end
end

function ClearcutMode:drawCigaretteTreeFire(node)
    CigaretteButtArt.drawTreeFire(node,self.smokerGroundTime)
end

function ClearcutMode:drawCigaretteGroundEffects()
    local t=self.smokerGroundTime
    for _,butt in ipairs(self.cigaretteButts) do CigaretteButtArt.drawSmolder(butt,t) end
    for _,transfer in ipairs(self.emberTransfers) do CigaretteButtArt.drawTransfer(transfer,t) end
    for _,arrival in ipairs(self.emberArrivals) do CigaretteButtArt.drawArrival(arrival,t) end
    -- 나무→나무 확산도 담배꽁초 확산과 동일한 궤적/도착 이펙트를 재사용한다.
    for _,spark in ipairs(self.treeSparks) do CigaretteButtArt.drawTransfer(spark,t) end
    for _,arrival in ipairs(self.treeSparkArrivals) do CigaretteButtArt.drawArrival(arrival,t) end
end

function ClearcutMode:drawDeveloperMachinery(game, t)
    local d, image = self.dashing, game.clearcutMachineryImage
    if not d or not image then return false end
    local imageW, imageH = image:getDimensions()
    local targetWidth = 174 + self:power("heavy_machinery") * 9
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

function ClearcutMode:drawSupplementSkills(game, t)
    SupplementArt.draw(self,game,t)
    MoleClawArt.draw(self,game,t)
    BruteForceArt.draw(self,game,t)
end

function ClearcutMode:drawThrownTrees(game)
    local variants=(game.world.images and game.world.images.treeVariants) or {}
    for _,tree in ipairs(self.thrownTrees) do
        local image=variants[math.max(1,math.min(#variants,tree.variant or 1))]
        if image then
            local height=math.max(0,tree.z or 0)
            local shadowScale=math.max(.35,1-height/520)
            love.graphics.setColor(0,0,0,.3)
            love.graphics.ellipse("fill",tree.x,tree.y+8,58*shadowScale,9*shadowScale)
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(image,tree.x,tree.y-height,tree.angle or 0,.82,.82,image:getWidth()/2,image:getHeight()*.91)
        end
    end
end

function ClearcutMode:drawWorldOverlay(game)
    love.graphics.setLineStyle("rough")
    local t = love.timer.getTime()
    local px, py = game.player.x + 14, game.player.y - 34
    if self.job == "fire" then
        local smoking = self.smoking
        if smoking and smoking.phase ~= "flick" then
            self:drawSmokerReloadBar(game)
            self:drawSmokerCigarette(game)
            local mouthX,mouthY,facing,tipX=self:smokerMouthPose(game)
            local progress=smoking.phase=="loaded" and 1 or math.min(1,smoking.t/smoking.dur)
            local breath=smoking.phase=="loaded" and .58 or (.55+math.sin(progress*math.pi)*.45)
            local equipment=game.player.clearcutSprite and game.player.clearcutSprite.cigarette
            if equipment then
                Cigarette.drawSmoke(equipment,tipX,mouthY,facing,t)
            else
                -- Legacy fallback for sprites without the authored equipment.
                for i=0,13 do
                    local rise=i*3
                    local drift=math.sin(t*1.65-i*.34)*i*.26+facing*i*.16
                    local alpha=(.30-i*.018)*breath
                    love.graphics.setColor(.78,.79,.75,alpha)
                    love.graphics.rectangle("fill",math.floor(tipX+drift+.5),math.floor(mouthY-rise-2),2,2)
                end
                love.graphics.setColor(.92,.34,.10,.55+math.sin(t*8)*.12)
                love.graphics.rectangle("fill",math.floor(tipX+.5),math.floor(mouthY-.5),2,2)
            end
        end
    elseif self.job == "toxic" then
        local bob = math.sin(t * 2.4) * 2
        drawPixelGrid(leafIconRows, leafIconPalette, px, py + bob, 2.4)
    elseif self.job == "physical" then
        drawPixelGrid(axeIconRows, axeIconPalette, px, py, 2.2)
    elseif self.job == "developer" then
        drawPixelGrid(hardhatIconRows, hardhatIconPalette, px, py, 2.4)
    elseif self.job == "philosopher" then
        local jitter = math.sin(t * 9) * 1.5
        drawPixelGrid(speechIconRows, speechIconPalette, px + jitter, py, 2.2)
    end
    if (self.job == "fire" or self.job == "toxic" or self.job == "philosopher") and self.aimX then
        local ringColor = self.job == "fire" and {1, .5, .15} or self.job == "toxic" and {.55, .85, .45} or {.75, .9, .35}
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
    self:drawThrownTrees(game)
    self:drawSupplementSkills(game, t)
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
    self:drawCigaretteGroundEffects()
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
    end
    for _, e in ipairs(self.enemies) do drawEnemyThreat(e, t) end
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
    local evoNames=Fusions.activeNames(self)
    if #evoNames>0 then
        love.graphics.setColor(1,.82,.3)
        love.graphics.printf("융합: "..table.concat(evoNames," · "),32,146,328,"left")
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

    local barH = 8
    local xpby = h - barH
    love.graphics.setColor(.04,.07,.055,.9); love.graphics.rectangle("fill",0,xpby,w,barH)
    love.graphics.setColor(1,.78,.25,1); love.graphics.rectangle("fill",0,xpby,w*math.min(1,self.xp/self.xpNext),barH)
    love.graphics.setFont(fonts.small); love.graphics.setColor(1,1,1,.9)
    love.graphics.print("Lv."..self.level,12,xpby-18)
    love.graphics.printf(math.floor(self.xp).." / "..self.xpNext,0,xpby-18,w-12,"right")
    if self.job=="miner" then
        local ready=(self.minerBurrowCooldown or 0)<=0 and not self.minerBurrow
        local text=self.minerBurrow and "잠복 중 — 나무 밑으로 이동" or ready and "SPACE / 우클릭  잠복 준비" or string.format("잠복 재사용 %.1f초",self.minerBurrowCooldown)
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(.035,.045,.035,.9); love.graphics.rectangle("fill",w/2-150,h-52,300,30,7,7)
        love.graphics.setColor(ready and {.94,.76,.28,1} or {.72,.65,.52,1})
        love.graphics.printf(text,w/2-146,h-45,292,"center")
    end
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

local jobFlavorColors = {physical = {.68, .5, .3, 1}, fire = {1, .42, .14, 1}, toxic = {.45, .82, .35, 1}, developer = {1, .72, .15, 1}, miner = {.85, .68, .22, 1}, philosopher = {.75, .9, .35, 1}}
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
    elseif job == "miner" then
        for i = 1, 5 do
            local seed = i * 3.3
            local life = (t * .5 + i * .37) % 1
            local px = x + w * (.14 + (i - 1) * .2) + math.sin(t * 1.3 + seed) * 5
            local py = y + h * .1 + life * h * .82
            love.graphics.push(); love.graphics.translate(px, py); love.graphics.rotate(t * 2 + seed)
            love.graphics.setColor(.42, .3, .16, (1 - life) * .4)
            love.graphics.rectangle("fill", -3, -3, 6, 6)
            love.graphics.pop()
            if i % 2 == 0 then
                local sparkle = .5 + math.sin(t * 6 + seed) * .5
                love.graphics.setColor(1, .84, .3, sparkle * (1 - life) * .5)
                love.graphics.circle("fill", px + 4, py - 4, 1.4)
            end
        end
    elseif job == "philosopher" then
        for i = 1, 6 do
            local seed = i * 2.7
            local life = (t * .9 + i * .29) % 1
            local px = x + w * (.1 + (i - 1) * .16) + math.sin(t * 2.1 + seed) * 4
            local py = y + h * .08 + life * h * .8
            love.graphics.setColor(.65, .82, .3, (1 - life) * .5)
            love.graphics.circle("fill", px, py, 1.6 + math.sin(t * 5 + seed) * .5)
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
local function drawCardBack(x,y,w,h,t,backColor)
    local color = backColor or specialColor
    local cx, cy = x + w/2, y + h/2
    love.graphics.stencil(function() love.graphics.rectangle("fill",x,y,w,h,14,14) end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.setColor(.1,.07,.17,1); love.graphics.rectangle("fill",x,y,w,h)
    for i = 0, 10 do
        local p = i / 10
        love.graphics.setColor(color[1]*.4, color[2]*.3, color[3]*.5, .1*(1-p))
        love.graphics.circle("fill", cx, cy, (w*.75)*(1-p))
    end
    love.graphics.setStencilTest()
    love.graphics.setColor(color[1],color[2],color[3],.85); love.graphics.setLineWidth(3)
    love.graphics.rectangle("line",x+6,y+6,w-12,h-12,10,10)
    love.graphics.setLineWidth(1); love.graphics.setColor(color[1],color[2],color[3],.5)
    love.graphics.rectangle("line",x+12,y+12,w-24,h-24,6,6)
    for _, corner in ipairs({{x+16,y+16,1,1},{x+w-16,y+16,-1,1},{x+16,y+h-16,1,-1},{x+w-16,y+h-16,-1,-1}}) do
        love.graphics.setColor(color[1],color[2],color[3],.7)
        love.graphics.line(corner[1], corner[2], corner[1]+10*corner[3], corner[2])
        love.graphics.line(corner[1], corner[2], corner[1], corner[2]+10*corner[4])
    end
    local pulse = .5+math.sin(t*6)*.5
    for i = 1, 8 do
        local ang = i/8*math.pi*2 + t*.6
        love.graphics.setColor(color[1],color[2],color[3],.25+pulse*.15)
        love.graphics.line(cx,cy, cx+math.cos(ang)*(30+pulse*6), cy+math.sin(ang)*(30+pulse*6))
    end
    love.graphics.setColor(color[1],color[2],color[3],.6+pulse*.3)
    love.graphics.circle("line", cx, cy, 26)
    specialBackFont = specialBackFont or love.graphics.newFont(46)
    love.graphics.setFont(specialBackFont)
    love.graphics.setColor(color[1],color[2],color[3],.55+pulse*.35)
    love.graphics.printf("?",x,y+h/2-30,w,"center")
end

function ClearcutMode:selectionMousePosition()
    local x,y=love.mouse.getPosition()
    local v=self.selectionView
    if v then return (x-v.x)/v.scale,(y-v.y)/v.scale end
    return x,y
end

function ClearcutMode:drawSelection(game,fonts)
    local w,h=love.graphics.getDimensions()
    local vw,vh=math.max(1280,w),math.max(720,h)
    local scale=math.min(w/vw,h/vh)
    local ox,oy=(w-vw*scale)/2,(h-vh*scale)/2
    self.selectionView={x=ox,y=oy,scale=scale}
    self.rerollBox,self.banishBox=nil,nil
    love.graphics.push();love.graphics.translate(ox,oy);love.graphics.scale(scale,scale)
    self:drawSelectionContent(game,fonts,vw,vh)
    love.graphics.pop()
    local function screenBox(box)
        if box then box.x=ox+box.x*scale;box.y=oy+box.y*scale;box.w=box.w*scale;box.h=box.h*scale end
    end
    for _,box in pairs(self.choiceBoxes or {}) do screenBox(box) end
    screenBox(self.rerollBox);screenBox(self.banishBox)
end

function ClearcutMode:drawSelectionContent(game,fonts,w,h)
    local t = love.timer.getTime()
    love.graphics.setColor(.015,.035,.025,.84); love.graphics.rectangle("fill",0,0,w,h)
    self.choiceBoxes={}
    if self.selectionKind == "fusion" then Fusions.drawAcquisition(self,fonts,w,h); return end
    if self.selectionKind == "arcana" then
        love.graphics.setFont(fonts.title); love.graphics.setColor(arcanaColor); love.graphics.printf("아르카나 — 룰을 바꾸는 선택",0,66,w,"center")
        love.graphics.setFont(fonts.small); love.graphics.setColor(.85,.78,.95); love.graphics.printf("되돌릴 수 없습니다. 한 번 고르면 이번 판 내내 유지됩니다",0,112,w,"center")
        local gap,cardW,cardH=24,math.min(320,(w-96)/3),430
        local startX=w/2-(cardW*3+gap*2)/2
        local mx,my=self:selectionMousePosition()
        local revealElapsed = t - (self.choicesRevealAt or t)
        for i,def in ipairs(self.arcanaChoices) do
            local x,y=startX+(i-1)*(cardW+gap),165
            self.choiceBoxes[i]={x=x,y=y,w=cardW,h=cardH}
            local hovered = mx>=x and mx<=x+cardW and my>=y and my<=y+cardH
            local cx = x+cardW/2
            local scaleX = specialCardFlip(math.max(0, revealElapsed - (i-1)*.08))
            love.graphics.push(); love.graphics.translate(cx,y+cardH/2); love.graphics.scale(scaleX,1); love.graphics.translate(-cx,-(y+cardH/2))
            if scaleX < .5 then
                drawCardBack(x,y,cardW,cardH,t,arcanaColor)
            else
            drawUpgradeCardFrame(x,y,cardW,cardH,arcanaColor,hovered,nil,t)
            local iconDef = {rows=arcanaShapeRows[def.icon], palette=arcanaIconPalette(def.color)}
            drawIconSocket(x+cardW/2,y+108,arcanaColor,iconDef,t)
            love.graphics.setColor(.06,.09,.08,.92); love.graphics.rectangle("fill",x+16,y+16,34,30,7,7)
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(tostring(i),x+16,y+21,34,"center")
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,y+182,cardW-32,"center")
            do
                local tagText = "아르카나"
                love.graphics.setFont(fonts.small)
                local tagW = math.min(cardW-40, fonts.small:getWidth(tagText)+28)
                local tagX = cx - tagW/2
                love.graphics.setColor(arcanaColor[1],arcanaColor[2],arcanaColor[3],.22); love.graphics.rectangle("fill",tagX,y+211,tagW,22,11,11)
                love.graphics.setColor(arcanaColor[1],arcanaColor[2],arcanaColor[3],.9); love.graphics.setLineWidth(1.3); love.graphics.rectangle("line",tagX,y+211,tagW,22,11,11)
                love.graphics.setColor(1,.96,.85,1); love.graphics.printf(tagText,tagX,y+216,tagW,"center")
            end
            love.graphics.setColor(1,1,1,.14); love.graphics.line(x+22,y+245,x+cardW-22,y+245)
            love.graphics.setFont(fonts.small); love.graphics.setColor(.86,.82,.92)
            love.graphics.printf(def.desc,x+22,y+256,cardW-44,"center")
            love.graphics.setColor(1,1,1,.14); love.graphics.line(x+22,y+352,x+cardW-22,y+352)
            love.graphics.setColor(arcanaColor[1],arcanaColor[2],arcanaColor[3],.14); love.graphics.rectangle("fill",x+16,y+362,cardW-32,58,8,8)
            love.graphics.setFont(fonts.heading); love.graphics.setColor(arcanaColor)
            love.graphics.printf("영구 효과 · 되돌릴 수 없음",x+20,y+382,cardW-40,"center")
            end
            love.graphics.pop()
        end
        return
    end

    love.graphics.setFont(fonts.title); love.graphics.setColor(1,.82,.3); love.graphics.printf("벌목 방식 진화",0,66,w,"center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.88,.76); love.graphics.printf("계속 움직이고 더 많은 숲을 한 번에 쓸어버리세요",0,112,w,"center")
    local numCards = self.specialCard and 4 or 3
    local gap = 22
    local cardW = math.min(300, (w-96-gap*(numCards-1))/numCards)
    local cardH = 430
    local startX = w/2-(cardW*numCards+gap*(numCards-1))/2
    local mx,my=self:selectionMousePosition()
    local revealElapsed = t - (self.choicesRevealAt or t)
    for i,def in ipairs(self.choices) do
        local x,y=startX+(i-1)*(cardW+gap),165
        self.choiceBoxes[i]={x=x,y=y,w=cardW,h=cardH}
        local hovered = mx>=x and mx<=x+cardW and my>=y and my<=y+cardH
        local jobColor = jobFlavorColors[def.job] or universalColor
        local scaleX, flipP = specialCardFlip(math.max(0, revealElapsed - (i-1)*.08))
        local cx = x+cardW/2
        love.graphics.push(); love.graphics.translate(cx,y+cardH/2); love.graphics.scale(scaleX,1); love.graphics.translate(-cx,-(y+cardH/2))
        if scaleX < .5 then
            drawCardBack(x,y,cardW,cardH,t,jobColor)
        else
        drawUpgradeCardFrame(x,y,cardW,cardH,jobColor,hovered,def.job,t)
        local iconDef = ClearcutMode.icons[def.id == "molotov" and "cigarette" or def.id]
        drawIconSocket(x+cardW/2,y+108,jobColor,iconDef,t)
        love.graphics.setColor(.06,.09,.08,.92); love.graphics.rectangle("fill",x+16,y+16,34,30,7,7)
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(tostring(i),x+16,y+21,34,"center")
        if self.banishArmed and not jobFor[def.id] then
            love.graphics.setColor(1,.3,.25,.5+math.sin(t*8)*.15); love.graphics.setLineWidth(3)
            love.graphics.rectangle("line",x+3,y+3,cardW-6,cardH-6,12,12)
        end
        -- 이름 · 트랙 태그 칩 · 구분선 · 설명 · 구분선 · 레벨 진행도 순으로 명확히 분리한다.
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,y+182,cardW-32,"center")
        local trackText = trackLabels[def.track] or ""
        if trackText ~= "" then
            love.graphics.setFont(fonts.small)
            local tagW = math.min(cardW-40, fonts.small:getWidth(trackText)+28)
            local tagX = cx - tagW/2
            love.graphics.setColor(jobColor[1],jobColor[2],jobColor[3],.22); love.graphics.rectangle("fill",tagX,y+211,tagW,22,11,11)
            love.graphics.setColor(jobColor[1],jobColor[2],jobColor[3],.9); love.graphics.setLineWidth(1.3); love.graphics.rectangle("line",tagX,y+211,tagW,22,11,11)
            love.graphics.setColor(jobColor[1]*.4+.6,jobColor[2]*.4+.6,jobColor[3]*.4+.6,1); love.graphics.printf(trackText,tagX,y+216,tagW,"center")
        end
        love.graphics.setColor(1,1,1,.14); love.graphics.line(x+22,y+245,x+cardW-22,y+245)
        love.graphics.setFont(fonts.small); love.graphics.setColor(.8,.87,.83)
        love.graphics.printf(def.desc,x+22,y+256,cardW-44,"center")
        love.graphics.setColor(1,1,1,.14); love.graphics.line(x+22,y+352,x+cardW-22,y+352)
        love.graphics.setColor(jobColor[1],jobColor[2],jobColor[3],.14); love.graphics.rectangle("fill",x+16,y+362,cardW-32,58,8,8)
        local curLevel = self:levelOf(def.id)
        local label=def.recovery and "체력 +20" or ("Lv."..curLevel.."  →  Lv."..(curLevel+1))
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,.8,.32)
        love.graphics.printf(label,x+20,y+370,cardW-40,"center")
        if not def.recovery and def.max and def.max > 1 then
            local dotGap, dotR = 15, 4
            local dotsW = (def.max-1)*dotGap
            local dx0 = cx - dotsW/2
            for lvl = 1, def.max do
                local px = dx0 + (lvl-1)*dotGap
                if lvl <= curLevel then
                    love.graphics.setColor(jobColor[1],jobColor[2],jobColor[3],1); love.graphics.circle("fill",px,y+404,dotR)
                elseif lvl == curLevel+1 then
                    love.graphics.setColor(1,.8,.32,.6+math.sin(t*5)*.3); love.graphics.setLineWidth(2); love.graphics.circle("line",px,y+404,dotR+1)
                else
                    love.graphics.setColor(1,1,1,.22); love.graphics.setLineWidth(1); love.graphics.circle("line",px,y+404,dotR)
                end
            end
        end
        end
        love.graphics.pop()
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
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,y+182,cardW-32,"center")
            do
                local tagText = "★ 스페셜 카드"
                love.graphics.setFont(fonts.small)
                local tagW = math.min(cardW-40, fonts.small:getWidth(tagText)+28)
                local tagX = cx - tagW/2
                love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.22); love.graphics.rectangle("fill",tagX,y+211,tagW,22,11,11)
                love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.9); love.graphics.setLineWidth(1.3); love.graphics.rectangle("line",tagX,y+211,tagW,22,11,11)
                love.graphics.setColor(1,.95,.75,1); love.graphics.printf(tagText,tagX,y+216,tagW,"center")
            end
            love.graphics.setColor(1,1,1,.14); love.graphics.line(x+22,y+245,x+cardW-22,y+245)
            love.graphics.setFont(fonts.small); love.graphics.setColor(.9,.86,.72)
            love.graphics.printf(def.desc,x+22,y+256,cardW-44,"center")
            love.graphics.setColor(1,1,1,.14); love.graphics.line(x+22,y+352,x+cardW-22,y+352)
            love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.14); love.graphics.rectangle("fill",x+16,y+362,cardW-32,58,8,8)
            love.graphics.setFont(fonts.heading); love.graphics.setColor(specialColor)
            love.graphics.printf("영구 효과 · 되돌릴 수 없음",x+20,y+382,cardW-40,"center")
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
        UI.button(bx,by,btnW,btnH,string.format("리롤 (목재 %d)",self:rerollCost()),canReroll,fonts.small,mx,my)
        local canBanish = self.banishArmed or self.totalWood >= self:banishCost()
        UI.button(bx+btnW+btnGap,by,btnW,btnH,self.banishArmed and "배니시할 카드 선택" or string.format("배니시 (목재 %d)",self:banishCost()),canBanish,fonts.small,mx,my)
    end
    Fusions.drawProgress(self,fonts,w)
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
        detail="마우스 위치에 꽁초를 튕깁니다. 꽁초는 바닥에서 7초간 타들어가며 주변 나무에 기본 42%(최대 75%) 확률로 불씨를 옮깁니다. 날아간 불씨가 나무에 닿아야 불이 붙습니다."},
    {id="toxic", name="비건 단체 회장", icon="leaf", color={.55,.85,.45},
        tagline="나무도 생명이지만... 일단 먹어야 한다.",
        detail="마우스 위치에 '친환경' 제초제를 살포합니다. 숲을 지키기 위해 숲을 없앱니다. 화력은 약하지만 재생력 자체를 짓누릅니다."},
    {id="developer", name="부동산 개발업자", icon="hardhat", color={1,.74,.1},
        tagline="여기에 아파트 지으면 됨.",
        detail="조준 방향으로 직접 돌진하며 경로상의 모든 것을 밀어버립니다. 넓은 범위를 순식간에 밀어내지만 재사용까지 잠깐 숨을 고릅니다."},
    {id="miner", name="코인 채굴꾼", icon="detector", color={.85,.68,.22},
        tagline="어릴 적 등산 갔다가 잃어버린 그 USB, 지금 시세로 수백억이다.",
        detail="좌클릭으로 작은 굴착 발톱을 세워 전방을 할퀴고, SPACE 또는 우클릭으로 잠복합니다. 흙더미로 나무 밑을 지나가면 땅속 충격에 나무가 뿌리째 솟아 좌우로 날아갑니다."},
    {id="philosopher", name="차라투스트라는 이렇게 말했다", icon="speech", color={.75,.9,.35},
        tagline="태어난 것 자체가 형벌이다. 나는 그저 해방시켜줄 뿐이다.",
        detail="말이 너무 많다. 침이 마를 날이 없다. 마우스 방향으로 끝없이 일장연설을 쏟아내며 침을 튀깁니다. 버튼을 오래 붙잡을수록 사거리와 독성이 강해지고, 맞은 나무와 적은 서서히 '해방'됩니다."}
}

return ClearcutMode
