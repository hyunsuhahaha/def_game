local UI = require("src.ui")
local Frontend = require("src.frontend_ui")
local HUDArt = require("src.clearcut_ui_art")
local TraitFx = require("src.trait_fx")
local Cigarette = require("src.cigarette_sprite")
local CigaretteButts = require("src.cigarette_butts")
local CigaretteButtArt = require("src.cigarette_butt_art")
local OilTrailArt = require("src.oil_trail_art")
local OvercrowdWarningArt = require("src.overcrowd_warning_art")
local StrawBaleArt = require("src.straw_bale_art")
local MoleBurrowArt = require("src.mole_burrow_art")
local BruteForceArt = require("src.brute_force_art")
local MoleClawArt = require("src.mole_claw_art")
local ForestArt = require("src.forest_arcade_art")
local ForestScenery = require("src.forest_scenery")
local ForestUnderstory = require("src.forest_understory")
local BiomeVines = require("src.biome_vines")
local ForestFloor = require("src.forest_floor")
local ForestLighting = require("src.forest_lighting")
local Fusions = require("src.clearcut_fusions")
local BiomeEnemies = require("src.biome_enemies")
local AttackPlants = require("src.attack_plants")
local SupplementArt = require("src.supplement_art")
local PhilosopherArt = require("src.philosopher_art")
local RevivalCrowdArt = require("src.revival_crowd_art")
local PhilosopherFusionArt = require("src.philosopher_fusion_art")
local SmokeRingArt = require("src.smoke_ring_art")
local SecondhandSmokeArt = require("src.secondhand_smoke_art")
local BeeArt = require("src.bee_art")
local VeganForkArt = require("src.vegan_fork_art")
local RegrowthCastArt = require("src.regrowth_cast_art")
local ForestZones = require("src.forest_zones")
local BiomeBosses = require("src.biome_bosses")
local BossEntrance = require("src.boss_entrance")
local BossRewardPickup = require("src.boss_reward_pickup")
local WorldTreeSiege = require("src.worldtree_siege")
local WorldTreeAttackArt = require("src.worldtree_attack_art")
local CombatGeometry = require("src.combat_geometry")
local Maps = require("src.clearcut_maps")
local SkillBranches = require("src.clearcut_skill_branches")
local SmokerWeaponArt = require("src.smoker_weapon_art")
local FlamethrowerArt = require("src.flamethrower_art")
local ScoreOperations = require("src.score_operations")
local GraduateMonkeyArt = require("src.graduate_monkey_art")
local ScoreTierUpArt = require("src.score_tier_up_art")
local ScoreAxeArt = require("src.score_axe_art")
local WoodEconomy = require("src.wood_economy")
local WoodSettlementArt = require("src.wood_settlement_art")

local ClearcutMode = {}
ClearcutMode.__index = ClearcutMode
ClearcutMode.SCORE_TIME_DOUBLING_SECONDS=30
ClearcutMode.GrayOilCatArt = require("src.gray_oil_cat_art")
ClearcutMode.OilDrumSpillArt = require("src.oil_drum_spill_art")
ClearcutMode.OIL_BASE_RADIUS=180

ClearcutMode.scoreWeaponDefinitions = {
    {id="cigarette",name="담배"},
    {id="axe",name="도끼"},
    {id="firework",name="폭죽 로켓"},
    {id="flamethrower",name="화염방사기"},
}

local trackLabels = {destroy = "파괴력", spread = "확산력", suppress = "식탐력", develop = "개발력", dig = "굴착력", venom = "독설력", supplement = "보조력"}

-- 시그니처 업그레이드를 처음 고르면 1차 전직이 확정되고 기본 공격 자체가 바뀐다.
local jobFor = {berserker = "physical", molotov = "fire", fork_feast = "toxic", heavy_machinery = "developer", detector = "miner", monologue = "philosopher"}
local jobNames = {physical = "생계형 나무꾼", fire = "흡연자", toxic = "비건 단체 회장", developer = "부동산 개발업자", miner = "코인 채굴꾼", philosopher = "차라투스트라는 이렇게 말했다"}
local jobDesc = {
    physical = "그냥 오늘 할당량을 채우러 왔을 뿐이다. 대출은 갚아야 하니까.",
    fire = "마우스 위치에 꽁초를 빠르게 튕깁니다. 날아가는 도중 스치는 적에게는 그 자리에서 피해를 줍니다. 꽁초는 바닥에 남고 약 0.15초 뒤 주변 나무로 기본 90%(최대 96%) 확률로 불씨를 옮깁니다.",
    toxic = "커다란 포크로 전방의 여러 나무와 적을 한꺼번에 찍습니다. 이 타격으로 쓰러진 대상은 포크에 꿰어 끌어당긴 뒤 먹어 치웁니다.",
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
    {id="molotov", track="spread", name="꽁초 투척", desc="사거리와 꽁초의 불씨 전이 범위, 비행 직격 피해가 늘어납니다. 착화는 불티·재 파편이 터지는 강한 한 번으로 읽히고, 연소 중에는 0.15~0.35초의 불규칙한 박자마다 불꽃이 짧게 솟고 좌우 불티·밑동 파열·나무의 1~2픽셀 반응이 이어집니다. 다른 나무로 번질 때는 큰 불씨가 목표 방향으로 날아갑니다. 3레벨에는 화염 농축/줄꽁초 경로를 고르고, 6레벨에는 선택 경로에 따라 전자담배/폭죽 발사기로 자동 진화합니다. 연습장에서 꽁초 투척 레벨과 분기를 직접 시험할 수 있습니다.", max=6, color={1,.35,.12}, job="fire"},
    {id="dry_forest", track="spread", name="건조주의보 무시", desc="꽁초의 착화 확률이 레벨당 +2%p 높아지고(최대 96%), 붙은 불이 주변 나무로 더 빠르고 넓게 번집니다.", max=6, color={1,.5,.15}, job="fire"},
    {id="oil_drum", track="spread", name="라이터 기름 유출", desc="나무가 다 타버리면 레벨당 폭발 확률이 크게 올라(1렙 7.5%→5렙 63%), 6렙에서는 100% 확정 발동합니다.", max=6, color={1,.62,.1}, job="fire"},
    {id="straw_bale", track="spread", name="마른 건초더미 생성", desc="주기적으로 큰 건초더미를 둡니다. 꽁초가 닿으면 0.5초 뒤 불이 붙고, 레벨에 따라 넓어지는 화염 지대가 주변 나무와 적에게 지속 피해를 줍니다. 불이 옮겨붙어 다른 대상을 점화시키지는 않습니다.", max=6, color={.85,.72,.25}, job="fire"},
    {id="smoke_ring", track="spread", name="도넛 강화 — 니코틴 농축", desc="SPACE 도넛이 바닥 기울기와 분리된 둥근 연기로 날아가며, 보이는 외곽보다 후한 이동 궤적 판정으로 타격합니다. 강화하면 재사용 대기시간이 줄고 피해·넉백·크기가 늘어납니다. 6레벨 완충 시 초농축 도넛이 발사됩니다.", max=6, color={1,.68,.2}, job="fire"},
    -- 식탐력 (suppress) — 큰 포크로 찍고 마지막 한입까지 비운다 [비건 단체 회장 전용 + 공용]
    {id="fork_feast", track="suppress", name="대왕 포크", desc="기본 공격이 전방 다중 포크 찍기로 바뀝니다. 레벨마다 포크 피해와 사거리가 늘고, 이 타격으로 쓰러진 나무와 적은 끌어와 먹습니다.", max=6, color={.62,.92,.32}, job="toxic"},
    {id="buffet_fork", track="suppress", name="뷔페용 포크", desc="포크의 좌우 피격 폭과 동시에 찍는 대상 수가 늘어납니다. 6레벨에는 타격 순간 커다란 포크 잔상이 한 번 더 찍힙니다.", max=6, color={.48,.82,.66}, job="toxic"},
    {id="clean_plate", track="suppress", name="접시 비우기", desc="포크로 쓰러뜨린 대상을 먹을 때 체력을 회복하고, 나무라면 추가 목재도 얻습니다. 6레벨에는 부스러기가 주변 적에게 피해를 줍니다.", max=6, color={1,.76,.28}, job="toxic"},
    {id="seconds_please", track="suppress", name="한 그릇 더", desc="대상을 먹은 뒤 잠시 포크질 속도가 빨라집니다. 연속으로 먹을수록 식사 템포를 유지하기 쉬워집니다.", max=6, color={.92,.48,.68}, job="toxic"},
    -- 개발력 (develop) — 말뚝 → 중장비 → 폭파 [부동산 개발업자 전용]
    {id="pile_driving", track="develop", name="말뚝 박기", desc="돌진 사거리가 늘어나고 재사용 대기시간이 줄어듭니다.", max=6, color={.7,.62,.4}, job="developer"},
    {id="heavy_machinery", track="develop", name="중장비 투입", desc="돌진 경로의 폭이 넓어져 더 많은 나무를 밀어버립니다.", max=6, color={1,.72,.15}, job="developer"},
    {id="demolition", track="develop", name="철거 폭파", desc="돌진이 끝나는 지점에서 폭발이 일어나 주변 나무에도 피해를 줍니다.", max=6, color={1,.45,.15}, job="developer"},
    {id="site_clearance", track="develop", name="부지 정지 작업", desc="돌진이 지나간 자리는 다시는 나무가 자라지 않는 부지가 됩니다.", max=6, color={.55,.5,.55}, job="developer"},
    -- 굴착력 (dig) — 발톱 할퀴기와 지하 돌진으로 얼마나 거칠게 밀어내느냐 [코인 채굴꾼 전용]
    {id="detector", track="dig", name="손톱 강화 — 복리 발톱", desc="보이는 발톱 궤적 전체의 나무와 적을 모두 할퀴며 범위와 피해가 강화됩니다. 휘두르는 동안 이동해도 시작 방향의 판정이 두더지를 따라오고, 6레벨에는 양손으로 동시에 할퀴지만 대상별 피해는 한 번만 적용됩니다.", max=6, color={.85,.68,.22}, job="miner"},
    {id="burrow_uproot", track="dig", name="지하 강제집행", desc="SPACE 또는 우클릭 잠복의 재사용 시간이 줄고, 이동 경로에서 나무를 옆으로 튕깁니다. 잠복 중 다시 누르면 지상으로 돌파해 주변 몬스터에게 피해를 주고 공중에 띄웁니다.", max=6, color={.58,.42,.24}, job="miner"},
    {id="brute_force", track="dig", name="브루트포스 어택", desc="지상에서 수많은 숫자 조합을 빠르게 생성한 뒤 사방으로 발사합니다. 날아간 숫자는 닿는 나무와 적에게 피해를 줍니다.", max=6, color={.3,.9,.4}, job="miner"},
    -- 독설력 (venom) — 말을 오래 붙잡을수록 사거리와 독성이 강해진다 [차라투스트라는 이렇게 말했다 전용]
    {id="monologue", track="venom", name="끝없는 설교", desc="기본 공격이 장광설로 바뀝니다. 공격 버튼을 누르고 있는 동안 침방울을 연속으로 쏘며, 그동안 침 게이지가 계속 줄어듭니다. 게이지가 바닥나면 강제로 멈추고 25% 이상 회복해야 다시 쏠 수 있습니다. 말이 길어질수록 사거리와 피해가 늘어납니다.", max=6, color={.75,.85,.3}, job="philosopher"},
    {id="revival_meeting", track="venom", name="부흥회 강화 — 열성 신도", desc="SPACE로 여는 부흥회의 재사용 대기시간이 줄고, 지속시간과 그동안의 침 피해 배율이 늘어납니다.", max=6, color={.9,.85,.35}, job="philosopher"},
    {id="footnote", track="venom", name="각주 남발", desc="말하는 속도가 빨라져 침이 더 자주 튑니다.", max=6, color={.85,.9,.4}, job="philosopher"},
    {id="loud_voice", track="venom", name="목청 키우기", desc="침이 닿는 범위가 넓어집니다.", max=6, color={.65,.8,.3}, job="philosopher"},
    {id="saliva_gland", track="venom", name="침샘 발달", desc="침에 맞은 대상은 서서히 중독되어 지속 피해를 입습니다.", max=6, color={.55,.72,.25}, job="philosopher"},
    -- 보조력 (supplement) — 기본 공격과 무관하게 알아서 나가는 공용 패시브 [전 직업 공용]
    {id="bat_swarm", track="supplement", name="박쥐 떼", desc="주위를 맴도는 박쥐가 사거리 안의 생존 몬스터만 골라 주기적으로 급강하해 쪼아버립니다.", max=6, color={.55,.42,.72}},
    {id="thorn_aura", track="supplement", name="가시 오라", desc="몸 주위의 넓은 가시덩굴 지대가 주기적으로 주변 나무와 적에게 피해를 줍니다.", max=6, color={.42,.68,.32}},
    {id="crow_strike", track="supplement", name="까마귀 습격", desc="주기적으로 까마귀가 급강하해 사거리 내 가장 먼 생존 몬스터를 저격합니다.", max=6, color={.3,.28,.36}},
    {id="vine_whip", track="supplement", name="덩굴 채찍", desc="가장 가까운 생존 몬스터 방향으로 긴 덩굴을 휘둘러 넓은 부채꼴 범위를 가격합니다.", max=6, color={.35,.55,.22}},
    {id="boomerang_axe", track="supplement", name="부메랑 도끼", desc="가장 가까운 생존 몬스터를 향해 도끼가 날아가며, 넓은 회전 범위로 왕복 타격하고 손으로 돌아옵니다.", max=6, color={.6,.6,.65}},
    {id="seed_mine", track="supplement", name="씨앗 지뢰", desc="가장 가까운 생존 몬스터 방향에 씨앗 지뢰를 심습니다. 잠시 후 크게 터져 넓은 범위에 피해를 줍니다.", max=6, color={.65,.45,.2}},
    {id="chain_lightning", track="supplement", name="번개 사슬", desc="주기적으로 번개가 가까운 생존 몬스터 사이만 연쇄로 튀며 다단히트합니다.", max=6, color={.35,.75,.95}},
}
for _,definition in ipairs(ScoreOperations.definitions)do definitions[#definitions+1]=definition end

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
    {pct=10, text="숲 가장자리에서 작은 움직임이 감지된다.", wave={squirrel=1}},
    {pct=30, text="뿌리들이 벌목로를 막기 시작한다.", wave={vineSprout=1}},
    {pct=50, text="숲의 절반이 사라졌다.", wave={squirrel=1}, boss="ent"},
    {pct=70, text="공격 식물이 남은 숲을 둘러싼다.", wave={turret=1,vineSprout=1}},
    {pct=90, text="마지막 나무들이 뿌리 방어를 펼친다.", wave={vineSprout=2,turret=1}}
}

local enemyDefs = {
    squirrel = {name="화난 다람쥐", category="animal", hp=8, speed=155, damage=4, radius=13, color={.62,.38,.18}, hitCooldown=.85, reward=2},
    boar = {name="가시 멧돼지", category="animal", hp=30, speed=100, damage=9, radius=20, color={.4,.27,.19}, hitCooldown=1.1, reward=4},
    turret = {name="버섯 포탑", category="plant", hp=22, speed=0, damage=7, radius=18, color={.74,.34,.52}, ranged=true, range=300, fireInterval=1.9, reward=5},
    ent = {name="엘더 트렌트", category="plant", hp=260, speed=48, damage=16, radius=42, color={.33,.21,.12}, hitCooldown=1, boss=true,
        slamInterval=3.2, slamRadius=110, slamDamage=20, reward=40},
    worldtree = {name="세계수", category="plant", hp=1900, speed=0, damage=0, radius=420, color={.26,.5,.22}, boss=true, finalBoss=true,immovable=true,
        slamInterval=4, slamRadius=420, slamDamage=18, summonInterval=6.5, reward=0},
    reaper = {name="숲의 사신", category="animal", hp=550, speed=118, damage=14, radius=24, color={.1,.03,.05}, hitCooldown=.65, reward=60},
    vineSprout = {name="식충 덩굴괴수", category="plant", hp=42, speed=0, damage=6, radius=27, color={.35,.65,.25}, ranged=true, thornAttack=true, range=360, fireInterval=1.55, reward=7, hitCooldown=1},
    -- 직접 공격은 없지만, 주기적으로 주변에 쓰러진 나무를 되살린다 — 방치하면
    -- 애써 벤 자리가 다시 채워지니 먼저 처치하는 편이 이득인 "우선 처치" 유형.
    planter = {name="숲의 재생 프리즘", category="plant", hp=55, speed=0, damage=0, radius=19, color={.4,.78,.35}, hitCooldown=1, reward=9, plantInterval=7, plantRadius=190}
}

for kind,def in pairs(BiomeEnemies.definitions) do enemyDefs[kind]=def end
for kind,def in pairs(AttackPlants.definitions) do enemyDefs[kind]=def end
for kind,def in pairs(BiomeBosses.definitions) do enemyDefs[kind]=def end

local enemyCategories={plant=true,animal=true}
local ENEMY_BURN_DURATION,ENEMY_BURN_TICK=4,.5
for kind,def in pairs(enemyDefs) do
    assert(enemyCategories[def.category],"enemy definition requires plant/animal category: "..kind)
end
ClearcutMode.enemyDefinitions=enemyDefs
ClearcutMode.enemyCategories=enemyCategories

function ClearcutMode:enemyHasCategory(enemy,category)
    return enemyCategories[category] and enemy and enemy.def and enemy.def.category==category or false
end

local function formatTime(value)
    value = math.max(0, math.floor(value))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end

local function stageTimeLimit(stage,mapId)
    return require("src.clearcut_maps").stageTimeLimit(mapId,stage)
end

function ClearcutMode.new()
    return setmetatable({
        sandbox=false,
        levels={}, choices={}, level=1, xp=0, xpNext=10, pending=0,
        skillBranches={},smokerEvolution=nil,branchChoiceSkill=nil,branchChoices={},
        totalWood=0, treesFelled=0, elapsed=0, initialTrees=0, remainingTrees=0,lumberInventory={},resultSettlement=nil,
        maxMulti=1, maxChain=0, axeCooldown=0, axeRange=150, milestoneFired={},
        regrowTimer=0, regrowGrace=35, regrowInterval=12, regrowPulses=0, treesRevived=0, regrowFlash=0,
        forestZones={},zonesSecured=0,
        rootHazards={}, rootedTimer=0, rootedCount=0,
        bees={}, beeSlow=false, beeSwarmsTriggered=0, beehiveTotal=0,
        streak=0, lastHitAt=-10, molotovTimer=0, evolutions={}, molotovs={},
        cigaretteButts={}, emberTransfers={}, emberArrivals={}, cigaretteLandingImpacts={}, smokerGroundTime=0,cigaretteHitStop=0, secondhandSmokeClouds={},
        smokerWeaponProjectiles={},smokerWeaponCooldown=0,vapeCharge=0,vapeKick=0,vapeWindLeaves={},flameStream=nil,
        treeSparks={}, treeSparkArrivals={}, strawTimer=0, strawBales={}, strawBaleSequence=0,
        oilTrail={}, oilTrailTimer=0, oilTrailLastX=nil, oilTrailLastY=nil, oilTrailSequence=0,
        oilDrums={},oilDrumSpills={},oilDrumTimer=0,oilDrumSequence=0,oilPuddleGroups={},grayOilCat=nil,
        job=nil, attackCooldown=0, dashing=nil, dashTrail={}, smoking=nil,
        minerClawAction=nil, minerClawFx={}, minerClawMarks={}, minerBurrow=nil, minerBurrowCooldown=0, thrownTrees={}, burrowTracks={}, burrowTrackSequence=0,moleCompanion=nil,moleCompanions={},
        smokeRing=nil, smokeRingCooldown=0, smokeRingCharge=nil, smokeRingChargeDuration=1.5,
        salivaGauge=100, salivaGaugeMax=100, salivaDrainRate=30, salivaRegenRate=25, salivaExhausted=false,
        revivalTimer=0, revivalCooldown=0, eternalFields={},
        revivalChorusTimer=0, revivalChorusSequence=0, revivalChorusShots={}, revivalChorusImpacts={},
        physicalAction=nil, veganAction=nil, veganForkImpacts={}, veganConsumeFx={}, veganHaste=0, developerAction=nil,
        actionAudit={physicalImpact=0,cigaretteFlick=0,vapeShot=0,fireworkShot=0,veganFork=0,veganConsume=0,developerRemote=0},
        hp=100, maxHp=100, invulnTimer=0, dead=false,
        enemies={}, projectiles={}, bossTelegraphs={}, resinPuddles={}, waveFired={}, worldTreeSpawned=false, readyToFinish=false, activeBoss=nil,operationFinalBoss=false,operationBossName=nil,kills=0,
        chests={}, bossMagnetPickups={}, worldTreeDebris={}, chestPending=false, molotovShots=0, wildburstTimer=10, plagued={}, dodges=0,
        timeSpawnTimer=35, scoreEnemyTimer=45, eliteTimer=200, reaperSpawned=false,
        stage=1, stageBossHpMul=1, stageElapsed=0, stageTimeLimit=stageTimeLimit(1), failureReason=nil,
        scoreAttack=false,scoreHardCap=720,scoreStartingTrees=6,scoreBaseTreeAllowance=12,scoreTreeAllowance=12,scoreRegenTier=1,scoreTierFx=nil,
        scoreWoodEarned=0,scoreActiveWeapon="cigarette",scoreAxeAction=nil,scoreAxeImpacts={},savedMonkeyWeapons={"axe"},
        scoreFellTimes={},scoreFellHead=1,currentTreesPerSecond=0,peakTreesPerSecond=0,scoreDeficitTimer=0,scoreCollapseActive=false,
        treeSpawnRate=.55,scoreSpawnRateMultiplier=1,treeSpawnAccumulator=0,
        totalTreesSpawned=0,peakActiveTrees=0,scoreActiveTreeCap=180,scoreGrowthPulses=0,
        berserkState="idle", berserkTimer=170, berserkCycleCount=0, berserkTreeTimer=0, berserkKillsStart=0, berserkFlashNodes={},
        banished={}, rerollCount=0, banishArmed=false, selectionKind="upgrade", arcanaChoices={}, arcanaPicked={},
        dmgTakenMul=1, woodGainMul=1, curseBoostMul=1, eliteIntervalMul=1, reaperDelayMul=1, regrowSuppressed=false,
        berserkCooldownMul=1, berserkBonusMul=1,
        permanentTraits={
            attackSpeed=1, range=0, area=0, maxHp=0, reward=1,
            extraTargets=0, treeDamage=0, healOnFell=0, executeChance=0,
            burnSpeed=1, extraFires=0, spreadChance=0,
            biteDamage=0, plagueDuration=0,
            dashSpeed=1, sterileChance=0, aftershockRadius=0, cooldownRefund=0,
            moveSpeed=1, pickupRadius=0, hpRegen=0, reviveCharges=0,
            scoreInitialIgnitionReduction=0,scoreCigaretteImpact=0,scoreMoleCompanion=0,scoreMoleDamage=0,scoreMoleSpeed=0,
            scoreMoleAttackSpeed=0,scoreMoleClawTier=0,scoreMoleDualClaw=0,scoreMoleExtraCompanions=0,
            scoreOilDrum=0,scoreOilDrumInterval=0,scoreOilRadius=0,scoreOilIgnitionRadius=0,
            scoreOilDuration=0,scoreOilBurnDuration=0,scoreOilDamage=0,scoreOilSplashCount=0,scoreOilPatchScale=0,
            scoreGrayCat=0,scoreGrayCatChance=0,scoreGrayCatDelay=0,scoreGrayCatSpeed=0,scoreGrayCatExitSpeed=0,
            scoreReloadSpeed=0,scoreCartonSize=0,scoreCartonReload=0,scoreAutoThrowRate=0,
            scoreRocketTwin=0,scoreRocketCluster=0,scoreRocketFinale=0,
            scoreRocketCrew=0,scoreFlameUnlock=0,scoreFlameDamage=0,scoreFlameRange=0,scoreFlameWidth=0,scoreFlameIgnite=0
        },
        reviveCharges=0,
        vinePlantTimer=60, vineSpawns={},
        disasterState="idle", disasterTimer=150, disasterType=nil, rainSuppressFire=false, quakeShakes={},
        sproutFields={},
        offscreenPulse=0,
        traitFx=TraitFx.new()
    }, ClearcutMode)
end

function ClearcutMode:levelOf(id) return self.levels[id] or 0 end
function ClearcutMode:skillBranch(id)return self.skillBranches and self.skillBranches[id]end
function ClearcutMode:getUpgradeDefinition(id) return upgradeById[id] end
function ClearcutMode:smokerEvolutionId()
    local legacy=self:skillBranch("molotov")
    return self.smokerEvolution or ((legacy=="vape"or legacy=="fireworks")and legacy or nil)
end
function ClearcutMode:applySmokerEvolution(game)
    if self:levelOf("molotov")<6 then self.smokerEvolution=nil;return false end
    local evolution=SkillBranches.smokerEvolutionFor(self:skillBranch("molotov"))
    if not evolution then return false end
    local changed=self.smokerEvolution~=evolution
    self.smokerEvolution=evolution
    if changed then
        self.smoking=nil;self.smokerWeaponCooldown=0;self.vapeCharge=0;self.vapeKick=0;self.vapeWindLeaves={};self.flameStream=nil
        if game and game.player and game.player.clearClearcutAction then game.player:clearClearcutAction()end
        if game and game.setNotice then
            local def=SkillBranches.get(evolution)
            game:setNotice((def and def.name or evolution).." 자동 진화!","ore")
        end
    end
    return true
end

-- 스킬 연습장 전용: 현재 직업이 실제로 쓸 수 있는 스킬(직업 전용 + 공용) 전체를 나열한다.
-- 만렙/배니시/카드 뽑기 같은 정상 진행 제약 없이 화면에서 바로 레벨을 조절하기 위한 목록이다.
function ClearcutMode:sandboxSkillList()
    local list = {}
    for _, def in ipairs(definitions) do
        if (not def.scoreOperation or def.id=="baby_robot")and(not def.job or def.job==self.job)then list[#list+1]=def end
    end
    return list
end

function ClearcutMode:sandboxSetLevel(id, delta, game)
    local def = upgradeById[id]
    if not def then return false end
    local before=self:levelOf(id)
    self.levels[id] = math.max(0, math.min(def.max, self:levelOf(id) + delta))
    local trigger=SkillBranches.triggerLevel(id)
    if trigger and self:levelOf(id)<trigger then self.skillBranches[id]=nil end
    if id=="molotov"and self:levelOf(id)<6 then self.smokerEvolution=nil end
    -- Practice must reproduce the real level-up flow. Reaching a branch rank
    -- opens the same full-screen, mutually exclusive chooser immediately;
    -- hiding it at the bottom of the scroll panel made rank three look inert.
    if game and trigger and before<trigger and self:levelOf(id)>=trigger
        and not self:skillBranch(id) and SkillBranches.forSkill(id) then
        self:openBranchChoice(id,game)
    end
    if id=="molotov"then self:applySmokerEvolution(game)end
    return true
end

function ClearcutMode:sandboxSetAllSkills(maxed)
    for _,def in ipairs(self:sandboxSkillList())do self.levels[def.id]=maxed and def.max or 0 end
    if not maxed then self.skillBranches={};self.smokerEvolution=nil;self.evolutions={}
    else self:applySmokerEvolution() end
end

-- 연습장에서는 실제 카드 분기 조건을 그대로 보여 주되 선택만 즉시 적용한다.
-- 전자담배/폭죽도 여기서 정해야 실제 기본 공격 업데이트 경로가 바뀐다.
function ClearcutMode:sandboxBranchList()
    local available={};local owned={}
    for _,def in ipairs(self:sandboxSkillList())do owned[def.id]=true end
    for skill,list in pairs(SkillBranches.definitions)do if owned[skill]then
        local definition=upgradeById[skill];local trigger=SkillBranches.triggerLevel(skill)
        -- 직업 무기 진화는 처음부터 잠금 상태로 보여 발견 가능하게 하고,
        -- 공용 전문화는 해당 스킬을 실제 요구 레벨까지 찍었을 때 펼친다.
        if (definition and definition.job==self.job)or self:levelOf(skill)>=trigger then
            available[#available+1]={skill=skill,trigger=trigger,choices=list,definition=definition}
        end
    end end
    table.sort(available,function(a,b)return a.skill<b.skill end)
    return available
end

function ClearcutMode:sandboxSetBranch(skill,branchId,game)
    local branch=SkillBranches.get(branchId);local trigger=SkillBranches.triggerLevel(skill)
    if not branch or branch.skill~=skill or not SkillBranches.isChoice(skill,branchId)
        or not trigger or self:levelOf(skill)<trigger then return false end
    self.skillBranches[skill]=branchId
    if skill=="molotov"then self:applySmokerEvolution(game)end
    return true
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

-- 확산의 기준 연소 시간. 확산 수치는 원래 "초당 확률"이라 연소속도를 올릴수록 나무가
-- 빨리 타 없어져서 불씨를 옮길 시간 창이 줄었다. 즉 연소속도 특성이 확산 특성을
-- 직접 깎아먹어, 확산 만렙(초당 .30)이 연소속도 투자만으로 임계점 아래로 떨어졌다.
-- 이제 확산은 점화 시점에 "이 나무가 옮겨붙일 나무 수"를 확정하고 연소 구간에 균등
-- 배치한다. 연소속도는 회전율에만 영향을 주고 연쇄 규모는 건드리지 않는다.
local SPREAD_REFERENCE_BURN = 3.6

-- 불은 정해진 시간 동안 일정 주기로 피해를 넣는 지속 피해다. `연소속도`는 그 주기를
-- 짧게 만든다(1초 -> 0.9초 -> ...). 연소 시간은 고정이므로 주기가 짧아질수록 창 안에
-- 들어가는 타격 횟수가 늘어난다.
--   기본: 3.6초 동안 1초마다 4 -> 3회 12피해. 활엽수 12/소나무 9/자작 7은 넘어가고
--         단풍 16과 바오밥 25는 그을린 채 살아남는다.
--   타격 피해에는 공용 `무기 피해` 특성이 더해진다(연소속도는 "더 자주",
--   무기 피해는 "더 세게").
--   연소속도 만렙(x1.36): 주기 0.74초 -> 4회 16피해 -> 단풍까지 넘어간다.
--   + 런 카드까지(x2.09): 주기 0.48초 -> 7회 28피해 -> 바오밥까지 넘어간다.
local BURN_WINDOW = 3.6
local BURN_TICK_INTERVAL = 1
local BURN_TICK_DAMAGE = 4
ClearcutMode.BURN_WINDOW = BURN_WINDOW
ClearcutMode.BURN_TICK_INTERVAL = BURN_TICK_INTERVAL
ClearcutMode.BURN_TICK_DAMAGE = BURN_TICK_DAMAGE
ClearcutMode.SPREAD_REFERENCE_BURN = SPREAD_REFERENCE_BURN

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
-- 0..1 authored progression for skills whose first rank must establish identity
-- without immediately reaching the old screen-clearing values.
function ClearcutMode:growth(id)
    return math.min(1,(self:power(id)/levelCurve[7])^1.35)
end
function ClearcutMode:skillArea()return 1 end
-- Automatic skills keep their full visual footprint from rank one, but their
-- damage matures with rank. This prevents collecting many one-point skills
-- from producing the completed-build clear speed in the opening minutes.
function ClearcutMode:skillDamage(id)
    local growth=self:growth(id)
    return .20+(growth^1.5)*.80
end
function ClearcutMode:autoSkillCooldown()return 1 end
function ClearcutMode:pickupRadius() return 165 + self:power("magnet") * 95 + (self.permanentTraits.pickupRadius or 0) end
function ClearcutMode:pickupSpeed() return 15 + self:power("magnet") * 4 end
function ClearcutMode:destructionPct() return self.initialTrees > 0 and math.min(100, (1 - self.remainingTrees / self.initialTrees) * 100) or 0 end
-- Late runs become an escalating tug-of-war: stronger builds erase patches in
-- seconds while surviving regeneration cores refill them faster. Ordinary tree
-- HP never scales here, so the payoff remains mass felling rather than sponges.
function ClearcutMode:forestPressure()
    local stage=math.max(1,self.stage or 1)
    local level=math.max(1,self.level or 1)
    local elapsed=math.max(0,self.stageElapsed or self.elapsed or 0)
    return math.min(2.65,1+(stage-1)*.12+math.max(0,level-8)*.035+math.max(0,elapsed-150)/900)
end
-- 뱀서라이크식 단일 난이도 다이얼: 진행도와 무관하게 순수 경과시간으로만 오른다 (농성 방지)
function ClearcutMode:curseLevel() return 1 + (self.elapsed / 60) ^ 1.25 * .16 * (self.curseBoostMul or 1) end
-- 광폭화 라운드 중 스폰/물량 배율: 경고 단계부터 서서히 조여오다 광란 단계에서 폭증한다
function ClearcutMode:berserkMultiplier()
    if self.berserkState == "active" then return 1.45 + self.berserkCycleCount * .1 end
    if self.berserkState == "warn" then return 1.15 end
    return 1
end

function ClearcutMode:stageTimeRemaining()
    if self.scoreAttack then return math.huge end
    return math.max(0,(self.stageTimeLimit or stageTimeLimit(self.stage,self.mapId))-(self.stageElapsed or 0))
end

function ClearcutMode:scoreActiveTreeCount()
    local count=0
    for _,node in ipairs((self.mapWorld and self.mapWorld.nodes)or{})do
        if node.rushTree and node.active and not node.giantTree then count=count+1 end
    end
    self.remainingTrees=count
    self.peakActiveTrees=math.max(self.peakActiveTrees or 0,count)
    return count
end

function ClearcutMode:scoreOccupancy()
    return self:scoreActiveTreeCount()/math.max(1,self.scoreTreeAllowance or self.scoreBaseTreeAllowance or 12)
end

function ClearcutMode:checkScoreOvercrowding(game)
    if not self.scoreAttack or game.result then return false end
    if self:scoreActiveTreeCount()<(self.scoreTreeAllowance or 12)then self.scoreOvercrowdTimer=0;return false end
    local grace=ScoreOperations.overcrowdGrace(self)
    if grace>0 and(self.scoreOvercrowdTimer or 0)<grace then return false end
    self.failureReason="score_overcrowded"
    self:finish(game,true)
    return true
end

function ClearcutMode:scoreProductionRate()
    local times=self.scoreFellTimes or{}
    local head=self.scoreFellHead or 1
    local cutoff=(self.stageElapsed or 0)-1
    while head<=#times and times[head]<cutoff do head=head+1 end
    if head>1024 then
        local compact={}
        for i=head,#times do compact[#compact+1]=times[i] end
        self.scoreFellTimes,self.scoreFellHead=compact,1
        times,head=compact,1
    else
        self.scoreFellHead=head
    end
    local rate=math.max(0,#times-head+1)
    self.currentTreesPerSecond=rate
    self.peakTreesPerSecond=math.max(self.peakTreesPerSecond or 0,rate)
    return rate
end

function ClearcutMode:updateStageClock(dt,game)
    if self.sandbox or self.dead then return false end
    self.stageElapsed=(self.stageElapsed or 0)+dt
    if self.scoreAttack then
        self:scoreProductionRate()
        if self:scoreActiveTreeCount()>=(self.scoreTreeAllowance or 12)then self.scoreOvercrowdTimer=(self.scoreOvercrowdTimer or 0)+dt end
        if self:checkScoreOvercrowding(game)then return true end
        if self.stageElapsed>=(self.scoreHardCap or 720) then
            self.failureReason="score_hardcap"
            self:finish(game,true)
            return true
        end
        return false
    end
    if self:stageTimeRemaining()>0 then return false end
    self.failureReason="timeout"
    self.dead=true
    game:setNotice("제한 시간 초과 — 다음 구역 진입에 실패했습니다.","ore")
    self:finish(game,false)
    return true
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
    self.lumberInventory={}
    self.resultSettlement=nil
    self.stage=math.max(1,math.min(BiomeBosses.stageCap(self.mapId),self.stage or 1))
    self.stageElapsed,self.stageTimeLimit,self.failureReason=0,self.scoreAttack and math.huge or stageTimeLimit(self.stage,self.mapId),nil
    if self.scoreAttack then
        self.scoreFellTimes,self.scoreFellHead={},1
        self.currentTreesPerSecond,self.peakTreesPerSecond=0,0
        self.scoreWoodEarned=0
        -- 기록 모드는 첫 수십 초 동안 직접 착화와 영구 연구 빌드로 버틴다.
        -- 일반 스테이지의 파괴율 웨이브와 별도로, 45초 뒤부터 소수만 투입한다.
        self.scoreEnemyTimer=45
        self.scoreRegenTier=game.characterTraits and game.characterTraits.getRegenTier and game.characterTraits:getRegenTier()or 1
        self.scoreStartingRegenTier=self.scoreRegenTier
        self.scoreHighestRegenTier=self.scoreRegenTier
        self.scoreTierClearTimer,self.scoreTierClearLatch,self.scoreTierSpawned,self.scoreTierFx=0,false,0,nil
    end
    game.world.clearcutMapScale=self.scoreAttack and Maps.SCORE_MAP_SCALE or 1
    Maps.configure(game.world,self.mapId)
    Maps.configureStage(game.world,self.stage)
    self.mapWorld=game.world
    self.mapPlayer=game.player
    local w, h = game.world.width, game.world.height
    local spawnX, spawnY = w / 2, h / 2
    game.player.x, game.player.y = spawnX, spawnY
    if game.characterTraits then
        self.permanentTraits=self.scoreAttack and game.characterTraits.scoreAttackEffects and game.characterTraits:scoreAttackEffects()or game.characterTraits:effects(self.job)
    end
    self.scoreTreeAllowance=(self.scoreBaseTreeAllowance or 12)+(self.permanentTraits.scoreTreeAllowance or 0)
    if self.scoreAttack then
        self.permanentTraits.range=(self.permanentTraits.range or 0)+(self.permanentTraits.scoreRange or 0)
        self.permanentTraits.area=(self.permanentTraits.area or 0)+(self.permanentTraits.scoreArea or 0)
        self.permanentTraits.cigaretteIgnitionChance=(self.permanentTraits.cigaretteIgnitionChance or 0)+(self.permanentTraits.scoreIgnitionChance or 0)
        self.permanentTraits.spreadChance=(self.permanentTraits.spreadChance or 0)+(self.permanentTraits.scoreSpreadChance or 0)
        self.permanentTraits.attackSpeed=(self.permanentTraits.attackSpeed or 1)*(1+(self.permanentTraits.scoreAttackSpeed or 0))
        self.permanentTraits.burnSpeed=(self.permanentTraits.burnSpeed or 1)*(1+(self.permanentTraits.scoreBurnSpeed or 0))
        self.permanentTraits.extraFires=(self.permanentTraits.extraFires or 0)+math.floor(self.permanentTraits.scoreExtraFires or 0)
        -- 무기 슬롯 공용/도끼 수치. 도끼·폭죽 피해는 treeDamage를 읽으므로 여기서 합치고,
        -- 도끼 전용 범위/공속/폭죽 수치는 각 공격 함수가 permanentTraits에서 직접 읽는다.
        self.permanentTraits.treeDamage=(self.permanentTraits.treeDamage or 0)+(self.permanentTraits.scoreTreeDamage or 0)
        self.permanentTraits.extraTargets=(self.permanentTraits.extraTargets or 0)+math.floor(self.permanentTraits.scoreAxeTargets or 0)
        self.permanentTraits.executeChance=(self.permanentTraits.executeChance or 0)+(self.permanentTraits.scoreAxeExecute or 0)
        self.permanentTraits.cigaretteProjectileSpeed=1+(self.permanentTraits.scoreProjectileSpeed or 0)
        self.levels.baby_robot=math.max(self:levelOf("baby_robot"),math.floor(self.permanentTraits.scoreStartingBabyRobot or 0))
        self:applySmokerEvolution(game)
        self.totalWood=0
        -- 기록 모드는 플레이 중 레벨업/3택을 사용하지 않는다. 목재는 점수와
        -- 정산용 수종 재고로만 누적되고 성장은 로비 영구 연구에서만 일어난다.
        self.xp,self.xpNext,self.level,self.pending=0,0,1,0
        self.choices,self.choiceBoxes={},{}
        self.scoreDeficitTimer,self.scoreCollapseActive=0,false
        game.wood=0
    end
    if game.achievements then
        local ae=game.achievements:effects()
        self.permanentTraits.treeDamage=(self.permanentTraits.treeDamage or 0)+(ae.treeDamage or 0)
        self.permanentTraits.maxHp=(self.permanentTraits.maxHp or 0)+(ae.maxHp or 0)
        self.permanentTraits.woodYield=(self.permanentTraits.woodYield or 1)*(ae.woodYield or 1)
        self.permanentTraits.moveSpeed=(self.permanentTraits.moveSpeed or 1)*(ae.moveSpeed or 1)
    end
    self.baseSpeed = 320 * (self.permanentTraits.moveSpeed or 1)
    game.player.speed, game.player.capacity, game.player.gather = self.baseSpeed, 99999, 1.15
    game.camera.x, game.camera.y, game.camera.zoom = spawnX, spawnY, game.world.stageZoom or .84
    if game.world.overviewBounds and game.camera.update then game.camera:update(0,game.player,game.world) end
    self.maxHp = self.maxHp + (self.permanentTraits.maxHp or 0)
    self.hp = self.maxHp
    self.reviveCharges = math.floor(self.permanentTraits.reviveCharges or 0)
    self.stageBossHpMul=1+(self.stage-1)*.55
    self.regrowInterval=self.stage==1 and 12 or (self.stage==2 and 9 or 7)
    self:generateForest(game,self.scoreAttack and(self.scoreStartingTrees or 6)or Maps.treeTarget(self.mapId,self.stage))
    if self.scoreAttack then
        -- 시작 수목도 실제 과밀도와 총 공급 기록에 포함한다. 이후 발아 수목만
        -- spawnScoreTree의 등장 애니메이션을 사용한다.
        self.totalTreesSpawned=self.remainingTrees
        self.peakActiveTrees=self.remainingTrees
    end
    if not self.scoreAttack then self:initForestZones(game)else self.forestZones={};self.treeSpawnAccumulator=0 end
    if self.scoreAttack then
        -- Score mode has no equipment inventory. The click context owns the
        -- weapon: nearby authored targets use the axe, otherwise the current
        -- progression ranged weapon is used. A graduated monkey keeps the axe.
        self.scoreActiveWeapon=self:scoreRangedWeaponId()
        -- 졸업한 무기는 순서대로 원숭이에게 넘어간다. 도끼를 졸업하면 도끼 원숭이가,
        -- 폭죽까지 졸업하면 폭죽 원숭이가 추가로 따라붙는다.
        self.savedMonkeyWeapons={}
        if (self.permanentTraits.scoreAxeCrew or 0)>0 then self.savedMonkeyWeapons[#self.savedMonkeyWeapons+1]="axe" end
        if (self.permanentTraits.scoreRocketCrew or 0)>0 then self.savedMonkeyWeapons[#self.savedMonkeyWeapons+1]="firework" end
    end
    if self.scoreAttack and (self.permanentTraits.scoreMoleCompanion or 0)>0 then self:initMoleCompanion(game) end
    if self.scoreAttack then
        for slot,prop in ipairs(self.savedMonkeyWeapons or {})do self:initLumberjackCompanion(game,prop,slot) end
    end
    if self.scoreAttack and (self.permanentTraits.scoreOilDrum or 0)>0 then
        ClearcutMode.GrayOilCatArt.load()
        ClearcutMode.OilDrumSpillArt.load()
        self.oilDrumTimer=3.5
    end
    local notice=self.scoreAttack and string.format("벌목 기록 — 활성 나무가 %d그루에 닿으면 종료",self.scoreTreeAllowance)or(Maps.get(self.mapId).name.." — 마우스를 누른 채 나무 근처로 이동하세요")
    if self.job=="miner" then notice=Maps.get(self.mapId).name.." — 좌클릭 할퀴기 · SPACE/우클릭 잠복" end
    game:setNotice(notice, "food")
    if self.job == "fire" then self:startSmoking(game) end
end

-- 나무 종류(스프라이트 variant)별 기초 체력. 예전엔 전부 3으로 고정이라 종류와 상관없이
-- 도끼 몇 번(스킬 몇 개만 찍어도 한 방)이면 쓰러졌다 — 굵고 단단해 보이는 나무는 실제로도
-- 더 오래 버티도록 종류별로 나눴다. 순서는 world.lua/clearcut_maps.lua의 variant 그림 순서와 맞춘다.
-- 초반에 나무가 너무 순식간에 쓰러져 긴장감이 없다는 피드백으로 전반적으로 상향
-- (기존 대비 약 1.6~2배). 2026-08-31 다시 1.75배 상향 — 나무가 여전히 가벼웠다.
-- 주의: 불로 태워 쓰러뜨리는 경로는 burnDuration만 보고 체력을 전혀 읽지 않는다.
-- 따라서 이 표를 올리면 도끼·폭죽·두더지만 느려지고 흡연 빌드는 영향받지 않는다.
local treeHpByMapVariant = {
    forest = {12, 9, 7, 16},    -- 활엽수, 소나무, 자작나무, 단풍나무
    mangrove = {16, 12, 7},     -- 맹그로브, 아비케니아, 니파야자
    madagascar = {25, 12, 7},   -- 바오밥(굵은 몸통), 타마린드, 코미포라
    island = {9, 12, 12},       -- 야자, 씨아몬드, 판다누스
}
local function treeHpFor(mapId, variant)
    local list = treeHpByMapVariant[mapId] or treeHpByMapVariant.forest
    return list[variant or 1] or list[1] or 3
end

-- 기록 모드의 공급 곡선은 영구 저장되는 재생 단계 하나로만 결정한다.
-- 시간/최근 벌목량 추종은 원인을 읽기 어렵게 하므로 이 모드에서 의도적으로 비활성화한다.
-- 난도는 단단한 나무보다 빠르게 차오르는 숲에서 온다. 단계당 공급량은 75%씩
-- 늘리되 HP는 3%만 올려, 후반에도 완성된 빌드가 나무를 우두두 쓰러뜨리게 한다.
function ClearcutMode:scoreTimedTreeSpawnRate()return .14*1.75^math.max(0,(self.scoreRegenTier or 1)-1)end

-- 숲을 0그루로 만들지 않고 현재 생산량만 맞추는 무한 유지 전략을 막는다.
-- 실제 플레이 시간 30초마다 공급량이 두 배가 되는 연속 곡선이라 임계점이
-- 계단처럼 튀지 않고 매 프레임 가까워진다. 카드 선택/단계 연출로 멈춘 시간은
-- stageElapsed가 흐르지 않으므로 플레이어에게 불리하게 누적되지 않는다.
function ClearcutMode:scoreTimePressureMultiplier()
    if not self.scoreAttack then return 1 end
    return 2^math.max(0,(self.stageElapsed or 0)/ClearcutMode.SCORE_TIME_DOUBLING_SECONDS)
end

function ClearcutMode:scoreTreeSpawnRate()
    local density=self:scoreForestDensityMultiplier()
    local base=math.max(0,self.treeSpawnRate or .55)
    if self.scoreAttack then
        base=self:scoreTimedTreeSpawnRate()*self:scoreTimePressureMultiplier()*density
        if self.scoreCollapseActive then
            local age=math.max(0,(self.scoreDeficitTimer or 5)-5)
            return math.max(base*(1+math.min(5,age*1.2)),1.35+math.min(2.4,age*.40))
        end
    end
    return base
end

function ClearcutMode:scoreRecentProductionRate(window)
    window=window or 5
    local cutoff=(self.stageElapsed or 0)-window
    local count=0
    for index=#(self.scoreFellTimes or{}),1,-1 do
        if self.scoreFellTimes[index]<cutoff then break end
        count=count+1
    end
    return count/window
end

function ClearcutMode:updateScoreCollapse(dt)
    if not self.scoreAttack then return false end
    local occupancy=self:scoreActiveTreeCount()/math.max(1,self.scoreTreeAllowance or 12)
    local natural=self:scoreTimedTreeSpawnRate()*self:scoreTimePressureMultiplier()*self:scoreForestDensityMultiplier()
    local losing=occupancy>=.60 and self:scoreRecentProductionRate(5)+.001<natural
    if losing then self.scoreDeficitTimer=(self.scoreDeficitTimer or 0)+dt
    else self.scoreDeficitTimer=math.max(0,(self.scoreDeficitTimer or 0)-dt*2)end
    self.scoreCollapseActive=self.scoreDeficitTimer>=5
    return self.scoreCollapseActive
end

function ClearcutMode:scoreForestDensityMultiplier()
    if not self.scoreAttack then return 1 end
    return math.max(1,self.scoreSpawnRateMultiplier or 1)
end

function ClearcutMode:scoreTreeHealth(baseHp)
    local tierHealth=self.scoreAttack and 1.03^math.max(0,(self.scoreRegenTier or 1)-1)or 1
    -- ceil은 3% 증가도 즉시 HP +1로 만들어 낮은 단계에서 실제 증가율을 과장한다.
    -- 반올림을 사용해 체력은 몇 단계에 한 번만 오르고, 공급 배율과 완전히 분리한다.
    return math.max(1,math.floor((baseHp or 1)*tierHealth+.5))
end

local function moleCompanionAngle(y,x)
    if math.atan2 then return math.atan2(y,x) end
    return math.atan(y/x)+(x<0 and math.pi or 0)
end

function ClearcutMode:initMoleCompanion(game)
    local sprite=game.clearcutSprites and game.clearcutSprites.miner
    if not sprite or not sprite.image then return false end
    local fw,fh=sprite.image:getWidth()/6,sprite.image:getHeight()/2
    local frames={walk={},action={}}
    for i=0,5 do
        frames.walk[i+1]=love.graphics.newQuad(i*fw,0,fw,fh,sprite.image:getDimensions())
        frames.action[i+1]=love.graphics.newQuad(i*fw,fh,fw,fh,sprite.image:getDimensions())
    end
    local traits=self.permanentTraits or{}
    local count=1+math.max(0,math.min(2,math.floor(traits.scoreMoleExtraCompanions or 0)))
    self.moleCompanions={}
    for index=1,count do
        local angle=(index-1)/math.max(1,count)*math.pi*2
        local x,y=require("src.clearcut_maps").constrain(game.world,
            game.player.x-86+math.cos(angle)*54,game.player.y+54+math.sin(angle)*42,42)
        self.moleCompanions[index]={x=x,y=y,sprite=sprite,frames=frames,fw=fw,fh=fh,state="seek",target=nil,
            index=index,facing=-1,walkClock=(index-1)*.37,attackT=0,
            attackDuration=.62/(1+math.max(0,traits.scoreMoleAttackSpeed or 0)),struck=false,
            speed=225*(1+math.max(0,traits.scoreMoleSpeed or 0)),damage=2+math.max(0,traits.scoreMoleDamage or 0),
            clawLevel=1+math.max(0,math.min(2,math.floor(traits.scoreMoleClawTier or 0)))*2,
            attackReach=104+math.max(0,math.min(2,math.floor(traits.scoreMoleClawTier or 0)))*18,
            dualClaw=(traits.scoreMoleDualClaw or 0)>0,treesFelled=0}
    end
    self.moleCompanion=self.moleCompanions[1]
    return true
end

-- 도끼 갈래의 졸업 보상. 마스터한 빌드를 동료에게 전수해 자동 벌목을 추가한다.
-- 탐색/이동/타격 루프는 두더지와 같고 목록도 공유한다 — 그래야 서로 다른 나무를 맡는다.
-- 성능은 내 도끼의 절반이다. 별도 조작 없이 출력을 보존하되 두 배가 되지 않게 한다.
function ClearcutMode:initLumberjackCompanion(game,prop,slot)
    -- 졸업 동료는 사람이 아니라 공용 원숭이 몸체를 쓰고 손에 든 무기만 다르다.
    local sprite,frames,fw,fh=GraduateMonkeyArt.sprite()
    if not sprite then return false end
    local traits=self.permanentTraits or{}
    local weapon=prop or self.savedMonkeyWeapons[1]or"axe"
    local axeDamage=4+math.max(0,traits.treeDamage or 0)
    -- 두 마리 이상이면 같은 자리에 겹쳐 소환되지 않도록 슬롯마다 옆으로 밀어 세운다.
    local spread=((slot or 1)-1)*74
    local x,y=require("src.clearcut_maps").constrain(game.world,game.player.x+96+spread,game.player.y+48,42)
    self.moleCompanions=self.moleCompanions or{}
    self.moleCompanions[#self.moleCompanions+1]={
        kind="lumberjack",prop=weapon,x=x,y=y,sprite=sprite,frames=frames,fw=fw,fh=fh,state="seek",target=nil,
        index=#self.moleCompanions+1,facing=-1,walkClock=.21,attackT=0,drawScale=.34,
        attackDuration=.62/(1+math.max(0,traits.scoreAxeSpeed or 0)),struck=false,
        speed=210*(1+math.max(0,traits.moveSpeed and traits.moveSpeed-1 or 0)),
        damage=math.max(1,math.floor(axeDamage*.5+.5)),
        attackReach=104+math.max(0,traits.scoreAxeArea or 0)*.5,treesFelled=0,
        -- 두더지는 자기 갈래로 따로 자라는 독립 유닛이고, 나무꾼은 내 도끼 빌드의
        -- 복제다. 충격파·밑동 절단·연속 벌목을 그대로 물려받아야 "내가 하던 일을
        -- 대신한다"가 되고, 도끼 갈래에 넣은 코인이 졸업 후에도 계속 일한다.
        shockLevel=math.max(0,math.floor(traits.scoreAxeShock or 0)),
        executeChance=traits.scoreAxeExecute or 0,
        chainChance=traits.scoreAxeChain or 0}
    -- 도끼 기준으로 세워둔 사거리·피해·공격주기를 실제로 든 무기 기준으로 덮어쓴다.
    -- 폭죽 원숭이는 도끼 갈래가 아니라 폭죽 갈래의 수치를 물려받아야 한다.
    local companion=self.moleCompanions[#self.moleCompanions]
    self:configureGraduateMonkeyWeapon(companion)
    if weapon~="axe"then companion.shockLevel,companion.executeChance,companion.chainChance=0,0,0 end
    self.moleCompanion=self.moleCompanion or self.moleCompanions[1]
    return true
end

function ClearcutMode:findMoleCompanionTree(companion,game)
    local claimed={}
    for _,other in ipairs(self.moleCompanions or{})do
        if other~=companion and other.target and other.target.active and not other.target.treeEmergence then claimed[other.target]=true end
    end
    local best,bestDistance,fallback,fallbackDistance
    for _,node in ipairs(game.world.nodes)do
        -- giantTree는 큰 수관을 고르는 시각 표식일 뿐 살아 있는 벌목 대상이다. 이를
        -- 제외하면 큰 나무만 남은 순간 동료가 화면의 나무 옆에서 영원히 대기한다.
        if node.rushTree and node.active and not node.treeEmergence then
            local dx,dy=node.x-companion.x,node.y-companion.y
            local distance=dx*dx+dy*dy
            if not fallbackDistance or distance<fallbackDistance then fallback,fallbackDistance=node,distance end
            if not claimed[node]and(not bestDistance or distance<bestDistance)then best,bestDistance=node,distance end
        end
    end
    companion.target=best or fallback
    return companion.target
end

function ClearcutMode:moleCompanionImpact(companion,game)
    local node=companion.target
    if not node or not node.active or node.treeEmergence then return false end
    local dx,dy=node.x-companion.x,node.y-companion.y
    local distance=math.sqrt(dx*dx+dy*dy)
    if distance>(companion.attackReach or 104)+41 then return false end
    if distance<1 then dx,dy,distance=companion.facing or 1,0,1 end
    local nx,ny=dx/distance,dy/distance
    local contactX,contactY=companion.x+nx*math.min(72,distance),companion.y+ny*math.min(72,distance)
    local angle=moleCompanionAngle(ny,nx)
    local curveFlip=(companion.facing or 1)>0 and -1 or 1
    if companion.kind=="lumberjack"and companion.prop=="firework"then
        self:detonateFirework({x1=node.x,y1=node.y,radius=125,damage=math.max(3,companion.damage)},game)
        companion.treesFelled=companion.treesFelled+(not node.active and 1 or 0)
        return true
    elseif companion.kind=="lumberjack"and companion.prop=="cigarette"then
        self:beginTreeBurn(node,0);game.world:igniteFx(node.x,node.y,false)
        self:spawnFireSpark(companion.x,companion.y-24,node.x,node.y)
    elseif companion.kind=="lumberjack"then
        self.traitFx:emit("axe",contactX,contactY,{radius=58,power=1,particles=10})
    else
        MoleClawArt.spawn(self,contactX,contactY,angle,companion.clawLevel or 1,curveFlip,nil,1,companion.dualClaw)
    end
    if (companion.executeChance or 0)>0 and node.rushHp and love.math.random()<companion.executeChance then
        node.rushHp=1
    end
    local treeX,treeY=node.x,node.y
    node.rushHp=(node.rushHp or node.rushMaxHp)-companion.damage
    game.world:impactNode(node,game,true)
    SupplementArt.impact(self,"axe",contactX,contactY,20)
    if node.rushHp<=0 and self:fellTree(node,game)then
        companion.treesFelled=companion.treesFelled+1
        if (companion.shockLevel or 0)>0 then
            self:axeShockwave(treeX,treeY,companion.shockLevel,game)
        end
        -- 연속 벌목: 쓰러뜨리면 다음 휘두르기를 기다리지 않고 바로 이어 친다.
        if (companion.chainChance or 0)>0 and love.math.random()<companion.chainChance then
            companion.state,companion.target,companion.attackT,companion.struck="seek",nil,0,false
        end
    end
    return true
end

function ClearcutMode:configureGraduateMonkeyWeapon(companion)
    if companion.kind~="lumberjack"then return end
    if not companion.prop then companion.attackReach,companion.damage=0,0;return end
    local traits=self.permanentTraits or{}
    if companion.prop=="cigarette"then
        companion.attackReach=300+math.max(0,traits.scoreRange or 0)*.45
        companion.attackDuration=.92/(1+math.max(0,traits.scoreAttackSpeed or 0)*.5)
        companion.damage=math.max(1,math.floor((2+math.max(0,traits.scoreTreeDamage or 0))*.4+.5))
    elseif companion.prop=="firework"then
        companion.attackReach=410+math.max(0,traits.scoreRocketSpeed or 0)*80
        companion.attackDuration=1.15/(1+math.max(0,traits.scoreRocketCooldown or 0)*.5)
        companion.damage=math.max(3,math.floor((8+math.max(0,traits.scoreRocketDamage or 0))*.5+.5))
    else
        companion.attackReach=104+math.max(0,traits.scoreAxeArea or 0)*.5
        companion.attackDuration=.62/(1+math.max(0,traits.scoreAxeSpeed or 0))
        companion.damage=math.max(1,math.floor((4+math.max(0,traits.treeDamage or 0))*.5+.5))
    end
end

function ClearcutMode:updateOneMoleCompanion(companion,dt,game)
    self:configureGraduateMonkeyWeapon(companion)
    if companion.kind=="lumberjack"and not companion.prop then companion.state="idle";companion.target=nil;return false end
    companion.walkClock=companion.walkClock+dt*7.5
    if companion.state=="attack"then
        companion.attackT=math.min(companion.attackDuration,companion.attackT+dt)
        local progress=companion.attackT/companion.attackDuration
        if not companion.struck and progress>=.53 then
            companion.struck=true
            self:moleCompanionImpact(companion,game)
        end
        if companion.attackT>=companion.attackDuration then
            companion.state,companion.target,companion.attackT,companion.struck="seek",nil,0,false
        end
        return true
    end
    local target=companion.target
    if not target or not target.active or target.treeEmergence then target=self:findMoleCompanionTree(companion,game)end
    if not target then companion.state="seek";companion.stuckTime=0;return false end
    local dx,dy=target.x-companion.x,target.y-companion.y
    local distance=math.sqrt(dx*dx+dy*dy)
    if math.abs(dx)>2 then companion.facing=dx<0 and -1 or 1 end
    local attackReach=companion.attackReach or 104
    if distance>attackReach then
        local step=math.min(distance-attackReach,companion.speed*dt)
        local x,y=companion.x+dx/distance*step,companion.y+dy/distance*step
        local oldX,oldY=companion.x,companion.y
        companion.x,companion.y=require("src.clearcut_maps").constrain(game.world,x,y,42)
        local moved=(companion.x-oldX)^2+(companion.y-oldY)^2
        companion.stuckTime=moved<.01 and(companion.stuckTime or 0)+dt or 0
        if companion.stuckTime>=.35 then
            -- 축소 맵 가장자리나 섬 해안 제약에 막힌 타깃을 계속 바라보며 서 있지
            -- 않도록 즉시 포기하고 다음 프레임에 다른 살아 있는 나무를 고른다.
            companion.target=nil;companion.state="seek";companion.stuckTime=0
            return false
        end
        companion.state="walk"
    else
        companion.state,companion.attackT,companion.struck,companion.stuckTime="attack",0,false,0
    end
    return true
end

function ClearcutMode:updateMoleCompanion(dt,game)
    local companions=self.moleCompanions or{}
    if #companions==0 and self.moleCompanion then companions={self.moleCompanion}end
    if #companions==0 then return false end
    MoleClawArt.update(self,dt)
    local updated=false
    for _,companion in ipairs(companions)do
        updated=self:updateOneMoleCompanion(companion,dt,game)or updated
    end
    return updated
end

function ClearcutMode:drawMoleCompanion(companion)
    if not companion or not companion.sprite then return end
    local action=companion.state=="attack"
    local row=action and(companion.sprite.graduateMonkey and(companion.prop or"walk")or"action")or"walk"
    local progress=action and math.min(.999,companion.attackT/companion.attackDuration)or 0
    local frame=action and(math.floor(progress*6)+1)or(math.floor(companion.walkClock)%6+1)
    local sprite=companion.sprite
    local direction=(sprite[row.."Facing"]or{})[frame]or 1
    local flip=(companion.facing or 1)*(sprite.nativeFacing or 1)*direction
    local poseScale=(sprite[row.."Scale"]and sprite[row.."Scale"][frame])or 1
    local foot=(sprite[row.."Feet"]or{})[frame]or 380
    local bob=not action and math.abs(math.sin(companion.walkClock*math.pi))*1.5 or 0
    love.graphics.setColor(0,0,0,.38);love.graphics.ellipse("fill",companion.x+2,companion.y+3,23,7)
    love.graphics.setColor(1,1,1,1)
    local drawScale=companion.drawScale or .30
    love.graphics.draw(sprite.image,companion.frames[row][frame],companion.x,companion.y-bob,0,
        drawScale*flip*poseScale,drawScale*poseScale,companion.fw/2,foot)
    if sprite.graduateMonkey then
        GraduateMonkeyArt.drawProp(companion,row,frame,flip,foot,bob,drawScale*poseScale)
    end
end

local function clearcutDistance(ax,ay,bx,by)
    local dx,dy=bx-ax,by-ay
    return math.sqrt(dx*dx+dy*dy),dx,dy
end

local function oilNoise(seed,index)
    local value=math.sin(seed*12.9898+index*78.233)*43758.5453
    return value-math.floor(value)
end

function ClearcutMode:spawnOilDrum(game)
    if not self.scoreAttack or (self.permanentTraits.scoreOilDrum or 0)<=0 then return false end
    local live=0
    for _,drum in ipairs(self.oilDrums or{})do if drum.state~="spilled"then live=live+1 end end
    if live>=3 then return false end
    local MapsModule=require("src.clearcut_maps")
    local x,y
    for _=1,24 do
        local angle=love.math.random()*math.pi*2
        local radius=150+love.math.random()*120
        local candidateX,candidateY=MapsModule.constrain(game.world,
            game.player.x+math.cos(angle)*radius,game.player.y+math.sin(angle)*radius,58)
        local clear=true
        for _,node in ipairs(game.world.nodes or{})do
            if node.active and (node.x-candidateX)^2+(node.y-candidateY)^2<82^2 then clear=false;break end
        end
        if clear then x,y=candidateX,candidateY;break end
    end
    if not x then x,y=MapsModule.constrain(game.world,game.player.x+180,game.player.y+80,58)end
    self.oilDrumSequence=(self.oilDrumSequence or 0)+1
    self.oilDrums[#self.oilDrums+1]={
        id=self.oilDrumSequence,x=x,y=y,state="falling",age=0,fallDuration=.58,z=280,
        hp=8,maxHp=8,angle=0,squash=1,hitFlash=0,claimed=false
    }
    return self.oilDrums[#self.oilDrums]
end

function ClearcutMode:spillOilDrum(drum,source)
    if not drum or drum.state=="spilled"then return false end
    -- If the player beats the cat to its target, cancel that dispatch outright.
    -- Sending it through the exit animation still looks like it came to help.
    if source=="axe"and self.grayOilCat and self.grayOilCat.target==drum then
        self.grayOilCat=nil
    end
    drum.state,drum.spillAge,drum.claimed="spilled",0,false
    drum.angle=(drum.spillFacing or 1)*math.pi*.5
    drum.hasSpillFx=false
    local radius=ClearcutMode.OIL_BASE_RADIUS+(self.permanentTraits.scoreOilRadius or 0)
    local lifetime=20+(self.permanentTraits.scoreOilDuration or 0)
    local oilDamage=self.permanentTraits.scoreOilDamage or 0
    local splashCount=16+math.floor(self.permanentTraits.scoreOilSplashCount or 0)
    local patchScale=1+(self.permanentTraits.scoreOilPatchScale or 0)
    local burnDuration=5+(self.permanentTraits.scoreOilBurnDuration or 0)
    self.oilTrailSequence=(self.oilTrailSequence or 0)+1
    local group="drum_"..tostring(drum.id or self.oilTrailSequence)
    local seed=(drum.id or self.oilTrailSequence)*97+self.oilTrailSequence*31
    self.oilDrumSpills[#self.oilDrumSpills+1]={
        x=drum.x,y=drum.y,age=0,frameDuration=.085,lifetime=lifetime,
        radius=radius,facing=drum.spillFacing or 1,source=source,drumId=drum.id,group=group,seed=seed
    }
    local spots={}
    for index=1,splashCount do
        local facing=drum.spillFacing or 1
        local forward=(index==1 and 0 or(18+oilNoise(seed,index)*radius))
        if index%7==0 then forward=-oilNoise(seed,index+14)*radius*.28 end
        local lateral=(oilNoise(seed,index+29)-.5)*radius*1.05
        local x=drum.x+facing*forward
        local y=drum.y+lateral*.48
        local distance=math.sqrt((x-drum.x)^2+(y-drum.y)^2)
        local angle=math.atan2(y-drum.y,x-drum.x)
        local spreadDelay=.18+(distance/math.max(1,radius))*.48+oilNoise(seed,index+41)*.08
        local visualScale=(.72+oilNoise(seed,index+53)*.70)*patchScale
        local spot={
            x=x,y=y,
            spawnedAt=self.smokerGroundTime+spreadDelay,ignited=false,angle=angle,
            sequence=self.oilTrailSequence*100+index,pixelSeed=seed+index*13,
            source="drum",group=group,lifetime=lifetime,damage=4+oilDamage,
            visualScale=visualScale,stretchX=.82+oilNoise(seed,index+61)*.9,
            stretchY=.72+oilNoise(seed,index+67)*.55,pixelChunks=18+math.floor(oilNoise(seed,index+71)*13),
            hitRadius=32*visualScale,flameCount=1+math.floor(oilNoise(seed,index+79)*2),burnDuration=burnDuration
        }
        self.oilTrail[#self.oilTrail+1]=spot;spots[#spots+1]=spot
    end
    self.oilPuddleGroups[group]={id=group,x=drum.x,y=drum.y,radius=radius,spots=spots,tickTimer=0,source=source,damage=1+oilDamage}
    return true
end

function ClearcutMode:hitOilDrum(drum,damage,game)
    if not drum or drum.state~="settled"then return false end
    drum.hp=math.max(0,(drum.hp or drum.maxHp or 8)-(damage or 4))
    drum.hitFlash=.13
    drum.hitDirection=drum.x>game.player.x and 1 or-1
    drum.hitKickTime=.13
    drum.angle=(drum.angle or 0)+drum.hitDirection*(drum.hp<=0 and .13 or .065)
    drum.spillFacing=drum.hitDirection
    ScoreAxeArt.impact(self,drum.x,drum.y-54,drum.hitDirection)
    if game.feedback then game.feedback:play("metal",drum.hp<=0)end
    if game.camera then
        game.camera:impulse(-drum.hitDirection*24,0,-drum.hitDirection*.008,.025)
        game.camera.trauma=math.min(1,(game.camera.trauma or 0)+.07)
    end
    if drum.hp<=0 then self:spillOilDrum(drum,"axe")end
    return true
end

function ClearcutMode:findAxeOilDrum(game,tx,ty,range,reach)
    local best,bestDistance
    for _,drum in ipairs(self.oilDrums or{})do if drum.state=="settled"then
        local playerDistance=(drum.x-game.player.x)^2+(drum.y-game.player.y)^2
        local aimDistance=(drum.x-tx)^2+(drum.y-ty)^2
        if playerDistance<=range*range and aimDistance<=reach*reach and(not bestDistance or aimDistance<bestDistance)then
            best,bestDistance=drum,aimDistance
        end
    end end
    return best
end

local function offscreenPoint(camera,screenX,screenY)
    if camera and camera.screenToWorld then return camera:screenToWorld(screenX,screenY)end
    return screenX,screenY
end

function ClearcutMode:startGrayOilCat(drum,game)
    if self.grayOilCat or not drum or drum.state~="settled"then return false end
    local w,h=love.graphics.getDimensions()
    local screenX,screenY=w*.5,h*.58
    if game.camera and game.camera.worldToScreen then screenX,screenY=game.camera:worldToScreen(drum.x,drum.y)end
    local side=screenX<w*.5 and -1 or 1
    screenY=math.max(100,math.min(h-90,screenY))
    local startX,startY=offscreenPoint(game.camera,side<0 and-110 or w+110,screenY)
    local exitX,exitY=offscreenPoint(game.camera,side<0 and w+130 or-130,screenY)
    local facing=side<0 and 1 or-1
    drum.claimed=true
    self.grayOilCat={
        x=startX,y=startY,state="enter",stateTime=0,animClock=0,target=drum,
        facing=facing,approachX=drum.x-facing*62,approachY=drum.y+4,
        exitX=exitX,exitY=exitY,pushDuration=.78,jumpZ=0
    }
    return true
end

function ClearcutMode:beginGrayOilCatExit(cat)
    if not cat or cat.state=="exit"then return end
    cat.state,cat.stateTime,cat.jumpZ="exit",0,0
    local distance=clearcutDistance(cat.x,cat.y,cat.exitX,cat.exitY)
    cat.exitDuration=math.max(.22,distance/(430*(1+(self.permanentTraits.scoreGrayCatExitSpeed or 0))))
end

function ClearcutMode:updateGrayOilCat(dt,game)
    local cat=self.grayOilCat
    if not cat then return false end
    cat.animClock=(cat.animClock or 0)+dt
    cat.stateTime=(cat.stateTime or 0)+dt
    local drum=cat.target
    if cat.state~="exit"and(not drum or drum.state=="spilled")then self:beginGrayOilCatExit(cat)end
    if cat.state=="enter"then
        local distance,dx,dy=clearcutDistance(cat.x,cat.y,cat.approachX,cat.approachY)
        if distance<=6 then cat.x,cat.y,cat.state,cat.stateTime=cat.approachX,cat.approachY,"push",0
        else
            local step=math.min(distance,320*(1+(self.permanentTraits.scoreGrayCatSpeed or 0))*dt)
            cat.x,cat.y=cat.x+dx/distance*step,cat.y+dy/distance*step
        end
    elseif cat.state=="push"then
        local p=math.min(1,cat.stateTime/cat.pushDuration)
        drum.angle=cat.facing*p*1.28
        drum.spillFacing=cat.facing
        drum.x=drum.x+cat.facing*dt*18
        if p>=.56 and drum.state~="spilled"then self:spillOilDrum(drum,"cat")end
        if p>=.72 then self:beginGrayOilCatExit(cat)end
    elseif cat.state=="exit"then
        local p=math.min(1,cat.stateTime/(cat.exitDuration or 1))
        local smooth=p*p*(3-2*p)
        if not cat.exitStartX then cat.exitStartX,cat.exitStartY=cat.x,cat.y end
        cat.x=cat.exitStartX+(cat.exitX-cat.exitStartX)*smooth
        cat.y=cat.exitStartY+(cat.exitY-cat.exitStartY)*smooth
        cat.jumpZ=math.sin(p*math.pi)*42
        if p>=1 then self.grayOilCat=nil end
    end
    return true
end

function ClearcutMode:updateOilDrums(dt,game)
    if not self.scoreAttack or (self.permanentTraits.scoreOilDrum or 0)<=0 then return false end
    self.oilDrumTimer=(self.oilDrumTimer or 0)-dt
    if self.oilDrumTimer<=0 then
        self.oilDrumTimer=math.max(10,22-(self.permanentTraits.scoreOilDrumInterval or 0))
        self:spawnOilDrum(game)
    end
    for index=#self.oilDrums,1,-1 do
        local drum=self.oilDrums[index]
        drum.hitFlash=math.max(0,(drum.hitFlash or 0)-dt)
        drum.hitKickTime=math.max(0,(drum.hitKickTime or 0)-dt)
        if drum.state=="falling"then
            drum.age=drum.age+dt
            local p=math.min(1,drum.age/drum.fallDuration)
            drum.z=(1-p*p)*280
            drum.squash=p>.84 and 1-math.sin((p-.84)/.16*math.pi)*.18 or 1
            if p>=1 then drum.state,drum.z,drum.squash="settled",0,1 end
        elseif drum.state=="spilled"then
            drum.spillAge=(drum.spillAge or 0)+dt
            drum.alpha=math.max(0,1-drum.spillAge/1.4)
            if drum.spillAge>=1.4 then table.remove(self.oilDrums,index)end
        end
    end
    for index=#self.oilDrumSpills,1,-1 do
        local spill=self.oilDrumSpills[index]
        spill.age=(spill.age or 0)+dt
        if spill.age>(spill.lifetime or 20)+.7 then table.remove(self.oilDrumSpills,index)end
    end
    if (self.permanentTraits.scoreGrayCat or 0)>0 and not self.grayOilCat then
        for _,drum in ipairs(self.oilDrums)do
            if drum.state=="settled"and not drum.claimed then
                if drum.catDecision==nil then
                    drum.catDecision=true
                    local chance=math.min(.95,.35+(self.permanentTraits.scoreGrayCatChance or 0))
                    if love.math.random()<chance then
                        drum.catWillCome=true
                        drum.catDelay=math.max(.45,2.2-(self.permanentTraits.scoreGrayCatDelay or 0))
                    else drum.claimed=true end
                end
                if drum.catWillCome then
                    drum.catDelay=(drum.catDelay or 0)-dt
                    if drum.catDelay<=0 then self:startGrayOilCat(drum,game);break end
                end
            end
        end
    end
    self:updateGrayOilCat(dt,game)
    return true
end

function ClearcutMode:scoreDynamicTreeCap()
    if not self.scoreAttack then return self.scoreActiveTreeCap or 180 end
    return math.max((self.scoreTreeAllowance or 12)+32,self.scoreActiveTreeCap or 180,math.min(900,math.ceil(self:scoreTreeSpawnRate()*1.4)))
end

function ClearcutMode:spawnScoreTree(game)
    if not self.scoreAttack or self.remainingTrees>=self:scoreDynamicTreeCap()then return false end
    local Maps=require("src.clearcut_maps");local world=game.world;local w,h=world.width,world.height
    local variantCount=math.max(1,#(world.images.treeVariants or{}));local x,y,variant
    for _=1,90 do
        local zoning=self:levelOf("forest_zoning")
        local margin=130+zoning*35
        local px,py
        if zoning>0 and love.math.random()<(.28+zoning*.17)then
            local radius=math.max(180,520-zoning*70);local angle=love.math.random()*math.pi*2;local distance=love.math.random()*radius
            px=math.max(margin,math.min(w-margin,game.player.x+math.cos(angle)*distance))
            py=math.max(margin,math.min(h-margin,game.player.y+math.sin(angle)*distance))
        else px=love.math.random(margin,w-margin);py=love.math.random(margin,h-margin)end
        if Maps.treeSpace(world,px,py)and not ForestScenery.isSceneryPocket(px,py,w,h)then
            local separated=true
            local pressure=math.max(1,self:scoreTreeSpawnRate()/math.max(.01,self.treeSpawnRate or .55))
            local minSep=self.scoreAttack and math.max(48,118-math.floor(math.log(pressure)/math.log(2))*12)or 118
            for _,node in ipairs(world.nodes)do if node.rushTree and node.active and node.x and node.y and(node.x-px)^2+(node.y-py)^2<minSep^2 then separated=false;break end end
            if separated then
                local index=(self.totalTreesSpawned or 0)+1
                local candidate=Maps.treeVariant(world,px,py,index)or ForestScenery.treeVariant(px,py,w,h,self.stage,index,variantCount)
                if Maps.insideTreeVisual(world,px,py,candidate)then x,y,variant=px,py,candidate;break end
            end
        end
    end
    if not x then return false end
    local node
    for _,candidate in ipairs(world.nodes)do if candidate.rushTree and not candidate.active then node=candidate;break end end
    node=node or{};if not node.kind then world.nodes[#world.nodes+1]=node end
    local baseHp=treeHpFor(world.clearcutMap,variant);local hp=self:scoreTreeHealth(baseHp)
    node.kind,node.x,node.y,node.work,node.workTime="tree",x,y,0,1
    node.active,node.respawn,node.rushTree,node.rushHp,node.rushMaxHp=true,0,true,hp,hp
    node.scoreBaseHp,node.scoreHpMultiplier=baseHp,hp/baseHp
    node.beehive,node.treeVariant,node.giantTree,node.sterile=false,variant,false,nil
    node.burning,node.burnTimer,node.fallT,node.uprooted,node.damageStage=nil,nil,nil,nil,nil
    node.forestZone,node.swayAngle,node.swayVel=nil,0,0
    node.treeEmergence={t=0,duration=1.05,direction=((self.totalTreesSpawned or 0)%2==0)and-1 or 1,source="score_growth"}
    self.totalTreesSpawned=(self.totalTreesSpawned or 0)+1
    self.scoreTierSpawned=(self.scoreTierSpawned or 0)+1
    self.initialTrees=self.totalTreesSpawned;self.remainingTrees=self.remainingTrees+1
    self.peakActiveTrees=math.max(self.peakActiveTrees or 0,self.remainingTrees)
    return true,node
end

function ClearcutMode:updateScoreTreeGrowth(dt,game)
    if not self.scoreAttack then return false end
    self:updateScoreCollapse(dt)
    self.treeSpawnAccumulator=math.min(48,(self.treeSpawnAccumulator or 0)+dt*self:scoreTreeSpawnRate())
    local grown=0
    while self.treeSpawnAccumulator>=1 and grown<24 do
        if not self:spawnScoreTree(game)then break end
        self.treeSpawnAccumulator=self.treeSpawnAccumulator-1;grown=grown+1
    end
    if grown>0 then self.scoreGrowthPulses=(self.scoreGrowthPulses or 0)+1 end
    return self:checkScoreOvercrowding(game)
end

function ClearcutMode:updateScoreTierClear(dt,game)
    if not self.scoreAttack then return false end
    local fx=self.scoreTierFx
    if fx then
        fx.t=math.min(fx.duration,fx.t+dt)
        if not fx.spawned and fx.t>=fx.spawnAt then
            fx.spawned=true
            self.scoreTierSpawned,self.treeSpawnAccumulator=0,0
            for i=1,(self.scoreStartingTrees or 6)do
                local ok,node=self:spawnScoreTree(game)
                if not ok then break end
                if node and node.treeEmergence then
                    node.treeEmergence.t=-(i-1)*.065
                    node.treeEmergence.source="tier_up"
                end
            end
        end
        if fx.t>=fx.duration then
            self.scoreTierFx=nil
            self.scoreTierClearTimer,self.scoreTierClearLatch=0,false
        end
        return true
    end
    if self:scoreActiveTreeCount()>0 then self.scoreTierClearTimer=0;self.scoreTierClearLatch=false;return false end
    if self.scoreTierClearLatch then return true end
    self.scoreTierClearTimer=(self.scoreTierClearTimer or 0)+dt
    if self.scoreTierClearTimer<.3 then return true end
    self.scoreTierClearLatch=true
    self.scoreRegenTier=(self.scoreRegenTier or 1)+1
    self.scoreHighestRegenTier=math.max(self.scoreHighestRegenTier or 1,self.scoreRegenTier)
    if game.characterTraits and game.characterTraits.unlockRegenTier then game.characterTraits:unlockRegenTier(self.scoreRegenTier)end
    self.scoreTierFx={t=0,duration=.86,spawnAt=.38,fromTier=self.scoreRegenTier-1,toTier=self.scoreRegenTier,spawned=false}
    if game.feedback and game.feedback.play then game.feedback:play("tier_up",true)end
    return true
end

-- 나무 배치 로직: 최초 진입(setup)과 스테이지 전환(advanceStage)에서 공용으로 쓴다
function ClearcutMode:generateForest(game, target)
    local Maps=require("src.clearcut_maps")
    local w, h = game.world.width, game.world.height
    local spawnX, spawnY = w / 2, h / 2
    local stage=self.stage or 1
    -- 온대 숲에서만 조림 사업 특성이 스테이지 진행에 비례해
    -- 추가 나무를 심어준다. 다른 바이옴은 자기만의 나무 수 곡선을 유지한다.
    local isDefaultForest = game.world.clearcutMap=="forest"
    if isDefaultForest and not self.scoreAttack then
        target = target + math.floor((self.permanentTraits.forestRestock or 0) * stage)
    end
    local normalBase=stage==1 and 140 or (stage==2 and 120 or (stage==3 and 105 or 96))
    local normalFloor=stage==1 and 98 or (stage==2 and 82 or (stage==3 and 70 or 60))
    local islandBase=stage==1 and 100 or (stage==2 and 85 or (stage==3 and 75 or 68))
    local islandFloor=stage==1 and 78 or (stage==2 and 68 or (stage==3 and 58 or (stage==4 and 48 or 42)))
    local minSepBase = game.world.clearcutMap=="island" and islandBase or normalBase
    local minSepFloor = game.world.clearcutMap=="island" and islandFloor or normalFloor
    local attempts, minSep = 0, minSepBase
    -- 벌집은 나무 밀도에 그대로 비례시키면 첫 화면부터 수십 개가 보여
    -- 희귀 위험물이라는 의미가 사라진다. 스테이지별 확률과 상한을 함께 둔다.
    local hiveChance,hiveCap,hiveCount=.022,6,0
    -- Large islands need more land samples in later stages.
    local attemptLimit=game.world.clearcutMap=="island" and math.max(40000,target*160)
        or math.max(36000,target*180)
    while #game.world.nodes < target and attempts < attemptLimit do
        attempts = attempts + 1
        -- New open pockets must not reduce later stages' tree objectives.
        -- Relax spacing only after a dense placement pass stalls; never fill paths.
        if attempts%1200==0 then minSep=math.max(minSepFloor,minSep-8) end
        local x = love.math.random(130, w - 130)
        local y = love.math.random(130, h - 130)
        local sdx, sdy = x - spawnX, y - spawnY
        local clearSpawn = sdx*sdx + sdy*sdy > 260*260 and not ForestScenery.isOpen(x,y,w,h)
            and not ForestScenery.isSceneryPocket(x,y,w,h)
            and Maps.insidePlayable(game.world,x,y,110)
        if game.world.clearcutMap and game.world.clearcutMap~="forest" then
            clearSpawn=Maps.treeSpace(game.world,x,y)
        end
        local separated = true
        for _, node in ipairs(game.world.nodes) do
            local ndx, ndy = x - node.x, y - node.y
            if ndx*ndx + ndy*ndy < minSep*minSep then separated = false; break end
        end
        if clearSpawn and separated then
            local variantCount = math.max(1, #(game.world.images.treeVariants or {}))
            local treeVariant = Maps.treeVariant(game.world,x,y,#game.world.nodes+1)
                or ForestScenery.treeVariant(x,y,w,h,self.stage,#game.world.nodes+1,variantCount)
            -- 다수종 조림 협약을 아직 안 찍었으면 온대 숲 계열은 기본 수종 하나만 자란다.
            if isDefaultForest and (self.permanentTraits.treeVariety or 0) <= 0 then treeVariant = 1 end
            clearSpawn=Maps.insideTreeVisual(game.world,x,y,treeVariant)
            local baseHp=treeHpFor(game.world.clearcutMap,treeVariant)
            local hp=self.scoreAttack and self:scoreTreeHealth(baseHp)or baseHp
            local treeIndex=#game.world.nodes+1
            -- A few mature canopy landmarks make the temperate maps read as a
            -- forest at camera scale. They remain ordinary objective trees:
            -- no hidden HP, reward, collision, or regrowth rule changes.
            local giantTree=isDefaultForest and treeVariant==1 and treeIndex%17==0
            if clearSpawn then
                local beehive = hiveCount<hiveCap and love.math.random()<hiveChance
                game.world.nodes[treeIndex] = {kind="tree",x=x,y=y,work=0,workTime=1,active=true,respawn=0,rushTree=true,rushHp=hp,rushMaxHp=hp,beehive=beehive,treeVariant=treeVariant,giantTree=giantTree,scoreBaseHp=self.scoreAttack and baseHp or nil,scoreHpMultiplier=self.scoreAttack and hp/baseHp or nil}
                if beehive then hiveCount=hiveCount+1;self.beehiveTotal=self.beehiveTotal+1 end
            end
        end
    end
    self.initialTrees, self.remainingTrees = #game.world.nodes, #game.world.nodes
    ForestFloor.generate(game.world,self.stage)
    ForestLighting.generate(game.world,self.stage)
    ForestScenery.generate(game.world,self.stage)
    Maps.filterScenery(game.world)
    require("src.biome_life").generate(game.world,self.stage)
    ForestUnderstory.generate(game.world,self.stage)
    BiomeVines.generate(game.world,self.stage)
end

function ClearcutMode:initForestZones(game)
    self.forestZones=ForestZones.build(game.world,game.world.nodes);self.zonesSecured=0
    if self.sandbox then return end
    local coreTarget=Maps.regrowthCoreCount(self.mapId,self.stage)
    local priority={2,5,1,6,3,4}
    local selected={}
    for i=1,math.min(coreTarget,#priority) do selected[priority[i]]=true end
    local stats=Maps.regrowthTotemStats(self.mapId,self.stage,false)
    for _,zone in ipairs(self.forestZones) do
        if zone.initial>0 then
            zone.coreAlive=selected[zone.id] or false
            if selected[zone.id] then
            local coreX,coreY=ForestZones.corePosition(game.world,zone,game.world.nodes,Maps.canPlant)
            local core=self:spawnEnemy("planter",coreX,coreY,{hpMul=stats.hp/enemyDefs.planter.hp,artKey=stats.artKey})
            if core then
                local def={};for k,v in pairs(core.def) do def[k]=v end
                def.name=stats.name;def.plantInterval=stats.plantInterval;def.plantRadius=stats.plantRadius;def.plantCount=stats.plantCount;def.reward=12
                core.def=def;core.zoneCoreId=zone.id;core.plantTimer=8+zone.id*.7;zone.coreEntity=core
            end
            end
        end
    end
end

-- 스테이지 클리어: 세계수를 쓰러뜨리면 런을 끝내는 대신 더 큰 숲과 더 강한 저주로 다음 스테이지를 연다
function ClearcutMode:advanceStage(game)
    CigaretteButts.reset(self)
    self.supplementImpacts, self.crowFx, self.whipFx, self.lightningFx = {}, {}, {}, {}
    self.sproutFields={}
    self.stage = self.stage + 1
    self.stageElapsed,self.stageTimeLimit=0,stageTimeLimit(self.stage,self.mapId)
    self.timeSpawnTimer,self.eliteTimer=18,240
    require("src.clearcut_maps").configureStage(game.world,self.stage)
    game.camera.zoom=(game.world.stageZoom or game.camera.zoom)*(game.camera.userZoom or 1)
    self.regrowInterval=self.stage==1 and 12 or (self.stage==2 and 9 or 7)
    self.stageBossHpMul = 1 + (self.stage - 1) * .55
    game.world.nodes, game.world.drops = {}, {}
    self.enemies, self.projectiles, self.bossTelegraphs, self.resinPuddles = {}, {}, {}, {}
    -- Boss magnets survive the immediate world-tree stage handoff; otherwise
    -- the reward would be deleted on the same frame it dropped.
    self.rootHazards, self.bees, self.molotovs, self.chests, self.plagued, self.worldTreeDebris = {}, {}, {}, {}, {}, {}
    self.secondhandSmokeClouds={}
    self.smokerWeaponProjectiles={};self.smokerWeaponCooldown=0;self.vapeCharge=0;self.vapeKick=0;self.vapeWindLeaves={};self.flameStream=nil
    self.eternalFields,self.revivalChorusShots,self.revivalChorusImpacts={},{},{}
    self.veganForkImpacts,self.veganConsumeFx,self.veganHaste={},{},0
    self.milestoneFired, self.worldTreeSpawned, self.worldTree, self.activeBoss, self.operationFinalBoss, self.operationBossName = {}, false, nil, nil, false, nil
    self.regrowTimer = 0
    local w, h = game.world.width, game.world.height
    game.player.x, game.player.y = w / 2, h / 2
    game.camera.x, game.camera.y = game.player.x, game.player.y
    self:generateForest(game, require("src.clearcut_maps").treeTarget(self.mapId,self.stage))
    self:initForestZones(game)
    game:setNotice(Maps.stageCode(self.mapId,self.stage).." — 숲이 더 거세게 반격한다!", "ore")
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
    self:updateWorldTreeCamera(dt,game)
    if self.dead then return end
    require("src.biome_life").update(game.world,dt)
    ForestUnderstory.update(game.world,game.player,dt,game)
    BiomeVines.update(game.world,game.player,dt,game)
    self.elapsed = self.elapsed + dt
    if self:updateStageClock(dt,game) then return end
    local tierTransition=self:updateScoreTierClear(dt,game)
    if tierTransition then return end
    if self:updateScoreTreeGrowth(dt,game)then return end
    self:updateMoleCompanion(dt,game)
    self:updateOilDrums(dt,game)
    ScoreAxeArt.update(self,dt)
    self:updateHeldAxe(dt, game)
    self:updateThrownTrees(dt, game)
    self:updateBurrowTracks(dt)
    self:updateSupplementSkills(dt, game)
    self:updateRegrowth(dt, game)
    self:updateFire(dt, game)
    self:updateMolotovs(dt, game)
    self:updateSmokerWeaponProjectiles(dt,game)
    self:updateSmokeRing(dt, game)
    self:updateRevival(dt, game)
    VeganForkArt.update(self,dt)
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
    AttackPlants.updateWorld(self,dt,game)
    self:updateEnemies(dt, game)
    self:updateProjectiles(dt, game)
    self:updateBossTelegraphs(dt, game)
    self:updateChests(dt, game)
    BossRewardPickup.update(self,game)
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

function ClearcutMode:updateBossEntrance(dt,game)
    if not BossEntrance.active(self) then return false end
    require("src.biome_life").update(game.world,dt)
    self.elapsed=self.elapsed+dt
    BossEntrance.update(self,dt,game)
    -- Keep the completion frame frozen as well; ordinary combat resumes on
    -- the following update so no projectile or contact hit shares the landing.
    return true
end

function ClearcutMode:updateRegrowth(dt, game)
    if self.sandbox then return end
    if self.scoreAttack then return end
    if self.regrowSuppressed then return end
    if self.elapsed < self.regrowGrace then return end
    self.regrowTimer = self.regrowTimer + dt
    if self.regrowTimer < self.regrowInterval/self:forestPressure() then return end
    self.regrowTimer = 0
    self:regrowPulse(game)
end

function ClearcutMode:regrowPulse(game)
    if self.worldTreeSpawned then return end
    local available={}
    for _,zone in ipairs(self.forestZones or {}) do
        if zone.coreAlive and not zone.secured and zone.active<zone.initial then available[#available+1]=zone end
    end
    if #available==0 then return end
    local zone=available[love.math.random(#available)]
    local candidates=ForestZones.candidates(self,zone)
    if #candidates == 0 then return end
    for i = #candidates, 2, -1 do local j = love.math.random(i); candidates[i], candidates[j] = candidates[j], candidates[i] end
    local pressure=self:forestPressure()
    local count=math.min(#candidates,math.min(8,1+math.floor(self.elapsed/180)+math.floor((pressure-1)*2.4)))
    for i = 1, count do
        local node = candidates[i]
        node.active, node.rushHp = true, node.rushMaxHp
        node.burning, node.fallT, node.uprooted, node.damageStage = nil, nil, nil, nil
        node.treeEmergence={t=-((i-1)*.09),duration=.95,direction=i%2==0 and -1 or 1,source="regrow"}
        self.remainingTrees = self.remainingTrees + 1
    end
    ForestZones.refresh(self,zone.id)
    if count > 0 then
        self.regrowPulses = self.regrowPulses + 1
        self.treesRevived = self.treesRevived + count
        self.regrowFlash = 1.4
        game:setNotice(string.format("%s 재생핵 작동 — 나무 %d그루 복구",zone.name,count), "food")
        if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .25) end
        self:spawnRootBurst(candidates, count, game)
    end
end

-- "숲의 재생 성소" 전용: regrowPulse와 같은 원리(쓰러진 나무를 되살림)지만 숲
-- 전체가 아니라 이 몹 주변에만 국한된다. 살려두면 계속 되풀이되니 먼저 잡는
-- 편이 이득이라는 신호를 그대로 준다.
function ClearcutMode:plantTreesNear(e, game)
    if self.regrowSuppressed or (self.worldTreeSpawned and not e.worldTreeTotem) then return end
    local radius = e.def.plantRadius or 190
    local candidates = {}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and not node.active and not node.sterile and (e.worldTreeTotem or ForestZones.canRegrow(self,node)) and (not e.zoneCoreId or node.forestZone==e.zoneCoreId) then
            local dx, dy = node.x - e.x, node.y - e.y
            if dx*dx + dy*dy <= radius*radius then candidates[#candidates+1] = node end
        end
    end
    if #candidates == 0 then return end
    for i = #candidates, 2, -1 do local j = love.math.random(i); candidates[i], candidates[j] = candidates[j], candidates[i] end
    local pressure=self:forestPressure()
    local count = math.min(math.ceil((e.def.plantCount or 3)*(1+(pressure-1)*.55)), #candidates)
    for i = 1, count do
        local node = candidates[i]
        node.active, node.rushHp = true, node.rushMaxHp
        node.burning, node.fallT, node.uprooted, node.damageStage = nil, nil, nil, nil
        node.treeEmergence={t=-((i-1)*.09),duration=.95,direction=i%2==0 and -1 or 1,source="planter"}
        self.remainingTrees = self.remainingTrees + 1
    end
    self.treesRevived = self.treesRevived + count
    if e.zoneCoreId then ForestZones.refresh(self,e.zoneCoreId) end
    game:setNotice(string.format("%s이(가) 나무 %d그루를 심었다!", e.def.name, count), "food")
    self:spawnRootBurst(candidates, count, game)
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
            if CombatGeometry.circleOverlapsTarget(hazard.x,hazard.y,hazard.radius,game.player,CombatGeometry.PLAYER_RADIUS) then
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
    -- 벌목 기록 모드의 유일한 실패 조건은 숲 과밀이다. 일반 작전용 적과
    -- 재해가 남아 있더라도 플레이어 HP나 사망 상태를 만들지 않는다.
    if self.scoreAttack then return end
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
    ForestUnderstory.cutRadius(game.world,x,y,radius,game)
    BiomeVines.cutRadius(game.world,x,y,radius,game)
    for _, e in ipairs(self.enemies) do
        if CombatGeometry.circleOverlapsTarget(x,y,radius,e) then
            e.hp = e.hp - damage
            e.visualHit = .14
            for _ = 1, 4 do game.world:addParticle(e.x, e.y - 12, {1, .32, .2}, true, false) end
        end
    end
end

function ClearcutMode:igniteEnemy(e, game, depth, ignitedAt)
    if self.rainSuppressFire or not self:enemyHasCategory(e,"plant") or e.burning or e.hp <= 0 then return false end
    e.burning,e.burnTimer,e.fireTickTimer,e.spreadDepth=true,0,0,depth or 0
    e.burnDuration,e.fireIgnitedAt=ENEMY_BURN_DURATION,ignitedAt or self.smokerGroundTime or 0
    game.world:igniteFx(e.x, e.y, false)
    return true
end

function ClearcutMode:igniteEnemiesInRadius(x, y, radius, game, depth)
    if self.rainSuppressFire then return end
    for _, e in ipairs(self.enemies) do
        if not e.burning and CombatGeometry.circleOverlapsTarget(x,y,radius,e) then self:igniteEnemy(e, game, depth) end
    end
end

function ClearcutMode:spawnEnemy(kind, x, y, opts)
    kind=BiomeEnemies.resolve(self.mapId,kind)
    local def = enemyDefs[kind]
    if not def then return end
    x,y=BiomeEnemies.spawnPoint(self.mapWorld,self.mapPlayer,kind,x,y)
    x,y=require("src.clearcut_maps").constrain(self.mapWorld,x,y,math.max((def.radius or 20)+8,70))
    if def.category=="plant" and not def.boss and self.mapWorld then
        x,y=require("src.clearcut_maps").constrainGroundPlant(self.mapWorld,x,y)
    end
    opts = opts or {}
    local curse = self:curseLevel()
    local hp = def.hp * (1 + (curse - 1) * .55) * (opts.hpMul or 1)
    local e = {
        kind = kind, def = def, x = x, y = y, hp = hp, maxHp = hp, hitTimer = 0,
        fireTimer = def.fireInterval, slamTimer = def.slamInterval, summonTimer = def.summonInterval, seed = love.math.random() * 10,
        speedMul = (1 + (curse - 1) * .22) * (opts.speedMul or 1),
        dmgMul = (1 + (curse - 1) * .35) * (opts.dmgMul or 1),
        elite = opts.elite,
        artKey = opts.artKey,
        worldTreeTotem = opts.worldTreeTotem,
    }
    self.enemies[#self.enemies + 1] = e
    if def.boss then self.activeBoss = e end
    return e
end

function ClearcutMode:spawnWorldTreeTotems(game)
    local count=Maps.worldTreeTotemCount(self.mapId,self.stage)
    if count<=0 then return end
    local stats=Maps.regrowthTotemStats(self.mapId,self.stage,true)
    local radius=count==1 and 470 or 520
    for i=1,count do
        local a=-math.pi*.5+(i-1)*math.pi*2/count
        local x,y=self.worldTree.x+math.cos(a)*radius,self.worldTree.y+math.sin(a)*radius*.62
        x,y=Maps.constrainGroundPlant(game.world,x,y,{left=180,right=180,top=260,bottom=170})
        local core=self:spawnEnemy("planter",x,y,{hpMul=stats.hp/enemyDefs.planter.hp,
            artKey=stats.artKey,worldTreeTotem=true})
        if core then
            local def={};for k,v in pairs(core.def) do def[k]=v end
            def.name=stats.name;def.plantInterval=stats.plantInterval;def.plantRadius=stats.plantRadius;def.plantCount=stats.plantCount;def.reward=18
            core.def=def;core.plantTimer=5.5+i*.7
        end
    end
end

function ClearcutMode:spawnWave(counts, game)
    local swarmMul = (1 + (self:curseLevel() - 1) * .6) * self:berserkMultiplier()
    local stageMul = self.stage==1 and .38 or (self.stage==2 and .52 or .65)
    for kind, count in pairs(counts) do
        local scaledCount = math.max(1,math.floor(count*swarmMul*stageMul+.5))
        for _ = 1, scaledCount do
            local a = love.math.random() * math.pi * 2
            local r = 480 + love.math.random() * 180
            self:spawnEnemy(kind, game.player.x + math.cos(a) * r, game.player.y + math.sin(a) * r)
        end
    end
    game:setNotice("적이 몰려온다!", "ore")
end

-- 타임어택의 동선을 가끔 방해하는 소수 스폰. 시간 압박이 주 난이도이므로 대군을 만들지 않는다.
function ClearcutMode:timeSpawnPool()
    -- 1-1 teaches movement and cutting before attack plants become common.
    -- Duplicate animal entries are deliberate weights, kept visible for tuning/tests.
    if self.mapId=="forest" and self.stage==1 then
        if self.elapsed<90 then return {"squirrel","squirrel","boar","squirrel"} end
        if self.elapsed<180 then return {"squirrel","boar","squirrel","vineSprout"} end
        return {"squirrel","boar","vineSprout","turret"}
    end
    if self.elapsed<75 then return {"squirrel","vineSprout"} end
    if self.elapsed<150 then return {"thornHunter","seedPod","vineSprout","turret"} end
    return {"thornHunter","seedPod","hammerBloom","bambooCannon","resinSprayer","vineSprout"}
end

function ClearcutMode:updateTimeSpawner(dt, game)
    if self.sandbox then return end
    if self.scoreAttack then
        local elapsed=self.stageElapsed or 0
        self.scoreEnemyTimer=(self.scoreEnemyTimer or 45)-dt
        if self.scoreEnemyTimer>0 then return end

        -- 기록전의 적은 주 난이도가 아니라 벌목 동선을 조금 흔드는 방해물이다.
        -- 살아 있는 수를 제한해 타이머 한 번에 한 마리만 보충한다.
        local limit=elapsed<120 and 1 or(elapsed<240 and 2 or(elapsed<360 and 3 or 4))
        local alive=0
        for _,enemy in ipairs(self.enemies)do
            if not enemy.dead and(enemy.hp or 0)>0 then alive=alive+1 end
        end
        local interval=elapsed<120 and 32 or(elapsed<240 and 26 or(elapsed<360 and 22 or 18))
        if alive>=limit then
            self.scoreEnemyTimer=4
            return
        end
        self.scoreEnemyTimer=interval
        local kind=(elapsed<180 or love.math.random()<.72)and"squirrel"or"boar"
        local a=love.math.random()*math.pi*2
        local r=560+love.math.random()*120
        self:spawnEnemy(kind,game.player.x+math.cos(a)*r,game.player.y+math.sin(a)*r)
        return
    end
    self.timeSpawnTimer = self.timeSpawnTimer - dt
    if self.timeSpawnTimer > 0 then return end
    local curse = self:curseLevel()
    local opening=self.elapsed<90 and 1 or (self.elapsed<180 and 2 or nil)
    self.timeSpawnTimer = opening==1 and 24 or (opening==2 and 20 or math.max(12,20-curse*1.2))
    local count = (not opening and curse>=2.6 and love.math.random()<.35) and 2 or 1
    local pool = self:timeSpawnPool()
    for _ = 1, count do
        local kind = pool[love.math.random(#pool)]
        local a = love.math.random() * math.pi * 2
        local r = enemyDefs[kind].plantAttack and (180+love.math.random()*230) or (520 + love.math.random() * 200)
        self:spawnEnemy(kind, game.player.x + math.cos(a) * r, game.player.y + math.sin(a) * r)
    end
end

-- 정기 엘리트: 진행도와 무관하게 몇 분마다 훨씬 강한 개체가 등장
function ClearcutMode:updateEliteTimer(dt, game)
    if self.sandbox or self.scoreAttack then return end
    self.eliteTimer = self.eliteTimer - dt
    if self.eliteTimer > 0 then return end
    self.eliteTimer = 240 * (self.eliteIntervalMul or 1)
    local kind = love.math.random() < .5 and "boar" or "squirrel"
    local a = love.math.random() * math.pi * 2
    local e = self:spawnEnemy(kind, game.player.x + math.cos(a) * 520, game.player.y + math.sin(a) * 520, {hpMul = 6, speedMul = 1.15, dmgMul = 1.8, elite = true})
    game:setNotice((e and e.def.name or "적") .. " 정예 개체가 나타났다!", "ore")
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .3) end
end

-- 뱀서라이크식 "사신" — 농성 방지용 무한 추격자, 오래 버틸수록 등장
function ClearcutMode:updateReaper(dt, game)
    -- 농성 방지는 스테이지 제한 시간이 담당한다. 무한 추격자는 타임어택 동선을 과도하게 막으므로 비활성화한다.
    return
end

-- 광폭화 라운드: 주기적으로 찾아오는 하드코어 서지 이벤트. 경고 → 광란 → 냉각 3단계로 돌며,
-- 광란 중엔 스폰이 폭증하고 근처에 남아있는 나무들이 직접 뿌리를 뻗어 플레이어를 물어뜯는다.
function ClearcutMode:updateBerserk(dt, game)
    if self.sandbox or self.scoreAttack then return end
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
    if self.sandbox or self.scoreAttack then return end
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

-- 자연재해: 비, 뿌리 지진, 낙하 가지. 지면 경고 뒤 실제 식생이 공격한다.
function ClearcutMode:updateDisasters(dt, game)
    if self.sandbox or self.scoreAttack then return end
    if self.stage<2 then return end
    self.disasterTimer = self.disasterTimer - dt
    if self.disasterState == "idle" then
        if self.disasterTimer <= 0 then
            self.disasterState, self.disasterTimer = "warn", 3.4
            local roll=love.math.random();self.disasterType=roll<.34 and "rain" or (roll<.68 and "rootQuake" or "branchFall")
            game:setNotice(self.disasterType == "rain" and "먹구름이 몰려온다..." or (self.disasterType=="rootQuake" and "거대한 뿌리가 땅속을 뒤튼다..." or "수관 위에서 굵은 가지가 부러진다..."), "ore")
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
                for _,enemy in ipairs(self.enemies) do
                    if enemy.burning then
                        enemy.burning,enemy.burnTimer,enemy.fireTickTimer=false,nil,nil
                    end
                end
                game:setNotice("소나기 — 타오르던 불이 전부 꺼진다!", "food")
            else
                self.quakeTickTimer = 0
                game:setNotice(self.disasterType=="rootQuake" and "뿌리 지진 — 솟는 선을 피해라!" or "낙하 가지 — 그림자 밖으로 피해라!", "ore")
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
        if self.disasterType == "rootQuake" or self.disasterType=="branchFall" then
            self.quakeTickTimer = (self.quakeTickTimer or 0) - dt
            if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + dt * .3) end
            if self.quakeTickTimer <= 0 then
                self.quakeTickTimer = self.disasterType=="rootQuake" and .72 or 1.05
                local a = love.math.random() * math.pi * 2
                local r = 60 + love.math.random() * 260
                self.bossTelegraphs[#self.bossTelegraphs + 1] = {
                    x = game.player.x + math.cos(a) * r, y = game.player.y + math.sin(a) * r,
                    radius = self.disasterType=="rootQuake" and 58 or 76, phase = "warn", timer = self.disasterType=="rootQuake" and .65 or .9,
                    damage = self.disasterType=="rootQuake" and 13 or 17, rootQuake=self.disasterType=="rootQuake", branchFall=self.disasterType=="branchFall",
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
    if not BossEntrance.start(self,e,game) and game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.4) end
end

function ClearcutMode:spawnWorldTree(game)
    if self.worldTreeSpawned then return end
    self.worldTreeSpawned = true
    -- Reaching zero living trees is the boss trigger. Any surviving zone core
    -- becomes dormant immediately so it cannot undo the clear while the
    -- world-tree entrance is playing.
    for _,zone in ipairs(self.forestZones or {}) do
        zone.coreAlive=false;zone.active=0;zone.secured=true
    end
    for _,enemy in ipairs(self.enemies) do
        if enemy.zoneCoreId then enemy.planterCasting=false;enemy.plantTimer=math.huge end
    end
    local finalStage=self.stage>=BiomeBosses.stageCap(self.mapId)
    local kind=finalStage and BiomeBosses.forMap(self.mapId) or "worldtree"
    local bounds=game.world.playBounds or {x=0,y=0,w=game.world.width,h=game.world.height}
    local spawnX,spawnY=bounds.x+bounds.w*.5,bounds.y+bounds.h*.5
    self.worldTree=self:spawnEnemy(kind,spawnX,spawnY,{hpMul=finalStage and 1 or self.stageBossHpMul,dmgMul=1+(self.stage-1)*.22})
    if self.worldTree and kind=="worldtree" then
        self.worldTree.fixedX,self.worldTree.fixedY=self.worldTree.x,self.worldTree.y
        self.worldTree.worldTreeDamageStage=0
        WorldTreeSiege.startEmergence(self,self.worldTree,game)
        self:spawnWorldTreeTotems(game)
        local camera=game.camera
        if camera then
            self.worldTreeCamera={previousMode=camera.mode or "default",skyReturnStarted=false}
            camera.scriptedSkyviewBoss=true
            if camera.setMode then camera:setMode("skyview",.7) end
            -- Keep the root close to screen centre during SKYVIEW. The old
            -- 280-unit upward offset pushed it into the near, enlarged part of
            -- the projection and made the whole tree feel pressed against the
            -- camera. This changes framing only; user/stage zoom stays intact.
            if camera.focus then camera:focus(self.worldTree.x,self.worldTree.y-80,7.2,.96) end
        end
    end
    self.operationFinalBoss=finalStage
    if finalStage then
        BossEntrance.start(self,self.worldTree,game)
    elseif game.camera then
        game.camera.trauma=math.min(1,game.camera.trauma+.5)
    end
end

function ClearcutMode:updateWorldTreeCamera(dt,game)
    local state=self.worldTreeCamera
    if not state or not game.camera then return end
    local emergence=self.worldTreeEmergence
    if emergence and emergence.phase=="return" and not state.skyReturnStarted then
        state.skyReturnStarted=true
        game.camera.scriptedSkyviewBoss=nil
        if game.camera.setMode then game.camera:setMode(state.previousMode or "default",emergence.returnDuration or .8) end
    end
    if emergence and emergence.phase=="return" and state.skyReturnStarted
        and (game.camera.skyviewBlend or 0)<=.01 then
        emergence.cameraReturned=true
    end
end

-- The world-tree reveal is a real gameplay freeze, not merely invulnerability
-- on the boss. Only its authored rise, debris and camera transition advance;
-- enemies, projectiles, hazards, player attacks, cooldowns and the stage clock
-- remain on the exact frame where the forest reached zero trees.
function ClearcutMode:updateWorldTreeEmergence(dt,game)
    local state=self.worldTreeEmergence
    if not state then return false end
    local boss=state.boss
    if boss and boss.hp>0 then
        boss.visualTime=(boss.visualTime or 0)+dt
        WorldTreeSiege.updateBoss(self,boss,dt,game)
    end
    self:updateWorldTreeCamera(dt,game)
    WorldTreeSiege.updateDebris(self,dt,game)
    -- Freeze the completion frame too. Ordinary simulation resumes on the
    -- following update, after the camera has fully returned.
    return true
end

function ClearcutMode:restoreWorldTreeCamera(game)
    local state=self.worldTreeCamera
    if not state or not game.camera then
        if game.camera then game.camera.scriptedSkyviewBoss=nil end
        self.worldTreeCamera=nil;return
    end
    game.camera.scriptedSkyviewBoss=nil
    if game.camera.setMode then game.camera:setMode(state.previousMode or "default",.6) end
    self.worldTreeCamera=nil
end

function ClearcutMode:checkWorldTreeSpawn(game)
    if self.sandbox or self.scoreAttack or self.worldTreeSpawned or self.remainingTrees>0 then return false end
    self:spawnWorldTree(game)
    return self.worldTreeSpawned
end

function ClearcutMode:spawnEnemyProjectile(e, game)
    local dx, dy = game.player.x - e.x, game.player.y - e.y
    local d = math.sqrt(dx*dx + dy*dy)
    if d <= 0 then return end
    e.visualAttack = .24
    self.projectiles[#self.projectiles + 1] = {x = e.x, y = e.y, vx = dx / d * 150, vy = dy / d * 150, life = 3, damage = e.def.damage * (e.dmgMul or 1), hitRadius=5, color = e.def.color}
end

-- 정예 개체 전용 원거리 공격: 근접전만 하던 몹에게 가시 투사체를 추가로 부여한다
function ClearcutMode:spawnThornProjectile(e, game)
    local dx, dy = game.player.x - e.x, game.player.y - e.y
    local d = math.sqrt(dx*dx + dy*dy)
    if d <= 0 then return end
    e.visualAttack = .24
    self.projectiles[#self.projectiles + 1] = {
        x = e.x, y = e.y, vx = dx / d * 210, vy = dy / d * 210, life = 2.4,
        damage = e.def.damage * (e.dmgMul or 1) * .6, color = {.62, .42, .15}, kind = "thorn",hitRadius=11,
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
        local previousX,previousY=p.x,p.y
        p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
        p.life = p.life - dt
        if CombatGeometry.sweptCircleOverlapsTarget(previousX,previousY,p.x,p.y,p.hitRadius or 5,game.player,CombatGeometry.PLAYER_RADIUS) then
            self:damagePlayer(p.damage, game)
            AttackPlants.onProjectileExpired(self,p)
            table.remove(self.projectiles, i)
        elseif p.life <= 0 then
            AttackPlants.onProjectileExpired(self,p)
            table.remove(self.projectiles, i)
        end
    end
end

function ClearcutMode:bossSlam(e, game)
    self.bossTelegraphs[#self.bossTelegraphs + 1] = {x = e.x, y = e.y, radius = e.def.slamRadius, phase = "warn",
        timer = e.kind=="worldtree" and 1 or .75, warnDuration=e.kind=="worldtree" and 1 or .75,
        damage = e.def.slamDamage * (e.dmgMul or 1),worldTreeAttack=e.kind=="worldtree" and "rootSlam" or nil}
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
            radius = 62, phase = "warn", timer = .8, warnDuration=.8, damage = dmg,worldTreeAttack="rootBurst",
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
    local start=e.def.radius*.58
    local reach = 620
    self.bossTelegraphs[#self.bossTelegraphs + 1] = {
        kind = "line", x1 = e.x+nx*start, y1 = e.y+ny*start, x2 = e.x + nx * reach, y2 = e.y + ny * reach,
        halfWidth = 64, phase = "warn", timer = .72,warnDuration=.72, damage = 16 * (e.dmgMul or 1),worldTreeAttack="vineWhip",
    }
    game:setNotice("덩굴 채찍이 날아온다!", "ore")
end

-- 세계수 종합 AI: 기존 슬램·소환에 더해 뿌리 폭발/덩굴 채찍을 번갈아 쓰고, 체력 35% 이하부터는 격노해서 더 자주 공격한다
function ClearcutMode:updateWorldTreeAI(e, dt, game)
    WorldTreeSiege.updateBoss(self,e,dt,game)
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

function ClearcutMode:spawnWorldTreeGuards(e,game)
    local count=e.enraged and 3 or 2
    for i=1,count do
        local a=(i/count)*math.pi*2+(e.seed or 0)
        local kind=i%2==0 and "turret" or "vineSprout"
        local distance=480+love.math.random()*120
        self:spawnEnemy(kind,e.x+math.cos(a)*distance,e.y+math.sin(a)*distance,{hpMul=1.25,dmgMul=1.12})
    end
    game:setNotice("세계수의 뿌리와 원거리 식물이 솟아난다!","ore")
end

function ClearcutMode:updateBossTelegraphs(dt, game)
    for i = #self.bossTelegraphs, 1, -1 do
        local t = self.bossTelegraphs[i]
        t.timer = t.timer - dt
        if t.phase == "warn" and t.timer <= 0 then
            t.phase, t.timer = "active", .25
            local hit
            if t.kind == "line" then
                hit=CombatGeometry.sweptCircleOverlapsTarget(t.x1,t.y1,t.x2,t.y2,t.halfWidth or 40,game.player,CombatGeometry.PLAYER_RADIUS)
            else
                hit=CombatGeometry.circleOverlapsTarget(t.x,t.y,t.radius,game.player,CombatGeometry.PLAYER_RADIUS)
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
    BossRewardPickup.grant(self,e,game)
    if e.def.boss and game.achievements then game.achievements:add("bosses",1) end
    if e.def.reward and e.def.reward > 0 then self:onWood(e.def.reward, game) end
    if e.zoneCoreId then
        local zone=ForestZones.coreDestroyed(self,e.zoneCoreId)
        if zone then
            local text=zone.secured and (zone.name.." 제압 완료") or string.format("%s 재생 정지 — 남은 나무 %d",zone.name,zone.active)
            game:setNotice(text,"ore")
        end
    end
    if e == self.worldTree then
        self:restoreWorldTreeCamera(game)
        if self.operationFinalBoss then
            self.operationBossName=e.def.name
            game:setNotice(BiomeBosses.operationName(self.mapId).." 완료 — "..e.def.name.." 격파!","food")
            if game.achievements and game.achievements.recordMapClear then game.achievements:recordMapClear(self.mapId) end
            self:finish(game,true)
        else
            game:setNotice(Maps.stageCode(self.mapId,self.stage).." 클리어 — 세계수를 쓰러뜨렸다!", "food")
            self:advanceStage(game)
        end
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
    if self.scoreAttack then
        self:onWood(40,game)
        game:setNotice("보물상자 — 목재 점수 +40","food")
        return false
    end
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
    WorldTreeSiege.updateDebris(self,dt,game)
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        local def = e.def
        local previousX, previousY = e.x, e.y
        e.visualTime = (e.visualTime or 0) + dt
        e.visualHit = math.max(0, (e.visualHit or 0) - dt)
        e.impactKick = math.max(0, (e.impactKick or 0) - dt)
        e.visualAttack = math.max(0, (e.visualAttack or 0) - dt)
        e.hitTimer = math.max(0, e.hitTimer - dt)
        local airborneThisFrame=false
        local worldTreeEmerging=false
        if def.immovable then
            worldTreeEmerging=WorldTreeSiege.updateBoss(self,e,dt,game)
        elseif e.airborneT then
            airborneThisFrame=true
            local airborneStep=math.min(dt,e.airborneDuration-e.airborneT)
            e.airborneT=math.min(e.airborneDuration,e.airborneT+airborneStep)
            local p=e.airborneT/e.airborneDuration
            e.hopHeight=math.sin(p*math.pi)*e.airbornePeak
            e.x,e.y=e.x+e.airborneVX*airborneStep,e.y+e.airborneVY*airborneStep
            local drag=math.exp(-3.2*airborneStep)
            e.airborneVX,e.airborneVY=e.airborneVX*drag,e.airborneVY*drag
            e.moving=true
            if p>=1 then
                e.airborneT,e.airborneDuration,e.airbornePeak=nil,nil,nil
                e.airborneVX,e.airborneVY,e.hopHeight=nil,nil,0
            end
        elseif (e.knockTimer or 0) > 0 then
            e.knockTimer = e.knockTimer - dt
            e.x, e.y = e.x + e.knockVX * dt, e.y + e.knockVY * dt
            e.knockVX, e.knockVY = e.knockVX * .86, e.knockVY * .86
            e.moving = true
        elseif BiomeBosses.update(e,dt,self,game) then
            -- Regional final bosses own their locked telegraph, movement and recovery.
        elseif AttackPlants.update(e,dt,self,game) then
            -- Rooted attack plants own their authored windup, strike and recovery.
        elseif BiomeEnemies.update(e,dt,self,game) then
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
        if e.elite and not airborneThisFrame then
            e.eliteFireTimer = (e.eliteFireTimer or 2.4) - dt
            if e.eliteFireTimer <= 0 then
                e.eliteFireTimer = 2.6
                self:spawnThornProjectile(e, game)
            end
        end
        if e.kind == "worldtree" and not airborneThisFrame and not worldTreeEmerging then self:updateWorldTreeAI(e, dt, game) end
        if def.slamInterval and not airborneThisFrame and not worldTreeEmerging then
            e.slamTimer = e.slamTimer - dt
            if e.slamTimer <= 0 then
                e.slamTimer = def.slamInterval
                self:bossSlam(e, game)
            end
        end
        if def.summonInterval and not airborneThisFrame and not worldTreeEmerging then
            e.summonTimer = e.summonTimer - dt
            if e.summonTimer <= 0 then
                e.summonTimer = def.summonInterval
                if e.kind=="worldtree" then self:spawnWorldTreeGuards(e,game) else self:spawnWave({squirrel = 1}, game) end
            end
        end
        if def.plantInterval and not airborneThisFrame then
            e.plantTimer = (e.plantTimer or def.plantInterval) - dt
            e.planterCasting = e.plantTimer <= 1.5
            if e.planterCasting then e.visualAttack = math.max(e.visualAttack,.24) end
            if e.plantTimer <= 0 then
                e.plantTimer = def.plantInterval/self:forestPressure()
                e.planterCasting = false
                self:plantTreesNear(e, game)
            end
        end
        if e.hp <= 0 then
            self:onEnemyDefeated(e, game)
            table.remove(self.enemies, i)
        end
    end
    self:checkWorldTreeSpawn(game)
end

-- 담배꽁초가 나무에 처음 옮겨붙을 때 쓰는 불씨 궤적(emberTransfers/emberArrivals)과 똑같은
-- 그리기 함수를 그대로 재사용해, 나무에서 나무로 불이 번질 때도 같은 궤적 이펙트를 띄운다.
-- 게임 로직(점화 판정 등)은 그대로 두고 시각 효과만 얹는 별도 배열이라 기존 흐름을 건드리지 않는다.
function ClearcutMode:spawnFireSpark(sx, sy, tx, ty)
    local dist = math.sqrt((tx - sx) ^ 2 + (ty - sy) ^ 2)
    local duration = math.max(.28, math.min(.75, dist / 480))
    local now = self.smokerGroundTime
    self.treeSparks[#self.treeSparks + 1] = {x = sx, y = sy, tx = tx, ty = ty, startAt = now,
        duration = duration, arrivesAt = now + duration, treeSpread=true}
end

-- 마른 건초더미: 꽁초가 더미 위에 실제로 착지했을 때만 예열을 시작한다.
-- 0.5초 뒤 국소 화염 지대가 되며, 나무/다른 더미로는 절대 번지지 않는다.
function ClearcutMode:updateStrawBales(dt, game)
    local now = self.smokerGroundTime
    local growth=self:growth("straw_bale")
    local radius=150+growth*70
    local damage=7+growth*6
    local triggerRadius=110+growth*40
    local duration=6+growth*6
    for i = #self.strawBales, 1, -1 do
        local bale = self.strawBales[i]
        bale.radius,bale.damage,bale.triggerRadius,bale.duration=bale.radius or radius,bale.damage or damage,bale.triggerRadius or triggerRadius,bale.duration or duration
        if bale.ignited then
            bale.tickTimer = (bale.tickTimer or 0) - dt
            if bale.tickTimer <= 0 then
                bale.tickTimer = .4
                self:damageEnemiesInRadius(bale.x,bale.y,bale.radius,bale.damage,game)
                self:igniteEnemiesInRadius(bale.x,bale.y,bale.radius,game,0)
                -- 불씨를 옮겨붙이는 게 아니라, 반경 안의 나무를 곧바로 지속 피해로 태운다.
                for _,node in ipairs(game.world.nodes) do
                    if node.rushTree and node.active then
                        local dx,dy=node.x-bale.x,node.y-bale.y
                        if dx*dx+dy*dy<=bale.radius*bale.radius then
                            node.rushHp=(node.rushHp or node.rushMaxHp)-bale.damage
                            game.world:impactNode(node,game,false)
                            if node.rushHp<=0 then self:fellTree(node,game) end
                        end
                    end
                end
            end
            if now - bale.ignitedAt >= bale.duration then table.remove(self.strawBales, i) end
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
                    if dx*dx+dy*dy<=bale.triggerRadius*bale.triggerRadius then
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
        self.strawTimer = math.max(9, 15 - self:power("straw_bale") * 1.4)
        local a = love.math.random() * math.pi * 2
        local r = 70 + love.math.random() * 170
        self.strawBaleSequence=(self.strawBaleSequence or 0)+1
        self.strawBales[#self.strawBales + 1] = {
            x=game.player.x+math.cos(a)*r,y=game.player.y+math.sin(a)*r,
            age=0,ignited=false,variant=(self.strawBaleSequence-1)%2,spawnedAt=now,
            radius=radius,damage=damage,triggerRadius=triggerRadius,duration=duration
        }
    end
end

-- 융합 "불바다 출근길"(oil_drum+straw_bale 만렙): 이동하는 동안 지나온 자리에 기름 자국을
-- 남긴다. 담배꽁초가 그 위에 떨어지면 그 지점부터 이어진 자국을 따라(불이 옮겨붙듯 연쇄로)
-- 화염대가 켜지고, 유지되는 동안 닿는 적에게 지속 피해를 준다.
function ClearcutMode:updateOilTrail(dt, game)
    local playerTrailActive=self.evolutions.oilRoad
    if not playerTrailActive then
        self.oilTrailLastX,self.oilTrailLastY=nil,nil
    end
    if not playerTrailActive and #self.oilTrail==0 and next(self.oilPuddleGroups or{})==nil then return end
    local now = self.smokerGroundTime
    self.oilTrailTimer = self.oilTrailTimer - dt
    if playerTrailActive and game.player.isMoving and self.oilTrailTimer <= 0 then
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
    elseif playerTrailActive and not game.player.isMoving then
        self.oilTrailLastX,self.oilTrailLastY=game.player.x,game.player.y
    end
    if not self.rainSuppressFire then
        for _, butt in ipairs(self.cigaretteButts) do
            for _, spot in ipairs(self.oilTrail) do
                if not spot.ignited and now>=(spot.spawnedAt or 0)then
                    local dx, dy = spot.x - butt.x, spot.y - butt.y
                    local ignitionRadius=70+(spot.source=="drum"and(self.permanentTraits.scoreOilIgnitionRadius or 0)or 0)
                    if dx * dx + dy * dy <= ignitionRadius * ignitionRadius then self:igniteOilTrail(spot, game) end
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
                local hitRadius=spot.source=="drum"and(spot.hitRadius or 42)or 55
                self:damageEnemiesInRadius(spot.x, spot.y,hitRadius,spot.damage or 4, game)
                self:igniteEnemiesInRadius(spot.x,spot.y,hitRadius,game,0)
            end
            local burnDuration=5+(spot.source=="drum"and(self.permanentTraits.scoreOilBurnDuration or 0)or 0)
            if now - spot.ignitedAt >= math.min(burnDuration,spot.lifetime or burnDuration) then table.remove(self.oilTrail, i) end
        elseif now - spot.spawnedAt >= (spot.lifetime or 6) then
            table.remove(self.oilTrail, i)
        end
    end
    for id,group in pairs(self.oilPuddleGroups or{})do
        local live,ignited=false,false
        for _,spot in ipairs(self.oilTrail)do if spot.group==id then
            live=true;ignited=ignited or spot.ignited
        end end
        if not live then
            for _,spill in ipairs(self.oilDrumSpills or{})do if spill.group==id then
                spill.ignited=false;spill.ignitedAge=nil
            end end
            self.oilPuddleGroups[id]=nil
        elseif ignited then
            group.ignited=true
            for _,spill in ipairs(self.oilDrumSpills or{})do if spill.group==id then
                spill.ignited=true;spill.ignitedAge=(spill.ignitedAge or 0)+dt
            end end
            group.tickTimer=(group.tickTimer or 0)-dt
            if group.tickTimer<=0 then
                group.tickTimer=.45
                for _,node in ipairs(game.world.nodes or{})do if node.active and node.rushTree then
                    for _,spot in ipairs(self.oilTrail)do if spot.group==id and spot.ignited then
                        local dx,dy=node.x-spot.x,node.y-spot.y
                        local hitRadius=spot.hitRadius or 42
                        if dx*dx+dy*dy<=hitRadius*hitRadius then
                            self:damageTreeWithSmokerWeapon(node,group.damage or 1,game)
                            break
                        end
                    end end
                end end
            end
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

-- 불붙은 나무 한 그루가 다 탈 때까지 옮겨붙일 나무의 기대 개수. 1.0을 넘으면 산불이
-- 스스로 번지고(임계 돌파), 그 아래면 반드시 꺼진다. 연소속도와 무관하게 계산한다.
function ClearcutMode:spreadFactor()
    local dryPower = self:power("dry_forest")
    local routeFire = self:skillBranch("molotov") == "flame_route" and 1.3 or 1
    return (.12 + dryPower * .14 + (self.permanentTraits.spreadChance or 0))
        * routeFire * SPREAD_REFERENCE_BURN
end

-- 기대값을 정수 전파 횟수로 바꾼다. 소수부는 확률로 처리해 평균이 정확히 factor가 된다.
function ClearcutMode:rollSpreadBudget()
    local factor = self:spreadFactor()
    local whole = math.floor(factor)
    if love.math.random() < factor - whole then whole = whole + 1 end
    return whole
end

-- 나무 점화의 단일 진입점. 모든 점화 경로가 확산 예산을 같은 방식으로 받도록 한다.
function ClearcutMode:beginTreeBurn(node, depth)
    node.burning, node.burnTimer, node.fireTickTimer = true, 0, 0
    node.spreadDepth = depth or 0
    node.spreadBudget, node.spreadDone, node.burnDamageTimer = self:rollSpreadBudget(), 0, nil
end

-- 확정된 확산 예산을 연소 구간에 균등 배치한다. 예산 n은 연소의 1/(n+1), 2/(n+1) …
-- 지점에서 하나씩 나가므로, 연소가 빨라지면 간격만 좁아지고 총 전파량은 그대로다.
function ClearcutMode:releaseSpread(node, burnDuration)
    local budget, done = node.spreadBudget or 0, node.spreadDone or 0
    if done >= budget or burnDuration <= 0 then return false end
    if node.burnTimer / burnDuration < (done + 1) / (budget + 1) then return false end
    node.spreadDone = done + 1
    return true
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
        self:beginTreeBurn(candidates[i], depth)
        game.world:igniteFx(candidates[i].x, candidates[i].y, false)
        self:spawnFireSpark(source.x, source.y, candidates[i].x, candidates[i].y)
    end
end

-- wildfire=true: 산불 융합 전용 자동 투척. 그냥 투척 한 번 더가 아니라 두 개비를 한꺼번에
-- 부채꼴로 던지고, 비행 중 불타는 꼬리를 남겨 눈에 띄게 다르게 보이도록 flight.wildfire로 표시한다.
function ClearcutMode:throwMolotov(game, wildfire)
    local candidates = {}
    -- 자동 꽁초는 새로 쏟아져 아직 불붙지 않은 드럼통 기름을 가장 먼저 노린다.
    -- 한 자국이라도 예약 가능하면 나무 후보를 섞지 않는다. 그룹에 이미 불이 붙은
    -- 뒤에는 남은 가장자리 자국을 재조준하지 않고 기존 나무 선택으로 돌아간다.
    local now=self.smokerGroundTime or 0
    local burningOilGroups={}
    for _,spot in ipairs(self.oilTrail or{})do
        if spot.group and spot.ignited then burningOilGroups[spot.group]=true end
    end
    for id,group in pairs(self.oilPuddleGroups or{})do
        if group.ignited then burningOilGroups[id]=true end
    end
    for _,spot in ipairs(self.oilTrail or{})do
        local live=now>=(spot.spawnedAt or 0)and now-(spot.spawnedAt or 0)<(spot.lifetime or 6)
        if spot.source=="drum"and live and not spot.ignited and not spot.igniting
            and not burningOilGroups[spot.group]then
            local dx,dy=spot.x-game.player.x,spot.y-game.player.y
            if dx*dx+dy*dy<=620*620 then candidates[#candidates+1]=spot end
        end
    end
    local oilPriority=#candidates>0
    if not oilPriority then
        for _, node in ipairs(game.world.nodes) do
            if node.rushTree and node.active and node.x and node.y and not node.giantTree and not node.burning and not node.igniting then
                local dx, dy = node.x - game.player.x, node.y - game.player.y
                if dx*dx + dy*dy <= 620*620 then candidates[#candidates+1] = node end
            end
        end
    end
    if #candidates == 0 then return end
    local requested=wildfire and 2 or (self:skillBranch("molotov")=="butt_volley_route"and 3 or 1)
    local throws = math.min(requested,#candidates)
    for i = 1, throws do
        local pick = love.math.random(#candidates)
        local target = table.remove(candidates, pick)
        target.igniting = true
        local dist = math.sqrt((target.x-game.player.x)^2 + (target.y-game.player.y)^2)
        local _,mouthY,_,tipX=self:smokerMouthPose(game)
        local landingX,landingY=target.x+(oilPriority and 0 or 28),target.y+(oilPriority and 0 or 22)
        self.molotovs[#self.molotovs+1] = {
            x0=tipX, y0=mouthY, x1=landingX, y1=landingY,
            t=0, dur=math.max(.18,dist/(1200*(self.permanentTraits.cigaretteProjectileSpeed or 1))), target=target, wildfire=wildfire,
            radius=(90+self:power("molotov")*20+self.permanentTraits.area+ScoreOperations.weaponArea(self))
                *(self:skillBranch("molotov")=="flame_route"and 1.25 or 1),
            landingAngle=.18+math.sin(target.x*.013)*.6
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
    local _,mouthY,_,tipX=self:smokerMouthPose(game)
    local x1,y1=tx,ty
    local fallsOffMap=false
    local bounds=game.world and game.world.playBounds
    if game.world and game.world.northBackdrop and bounds and ty<bounds.y then
        fallsOffMap=true
        -- Intersect the aim ray using the player's ground point. mouthY is an
        -- elevated sprite attachment and would send near-edge throws backward.
        local denominator=ty-game.player.y
        local q=math.abs(denominator)>1e-6 and (bounds.y-game.player.y)/denominator or 1
        q=math.max(0,math.min(1,q))
        x1=tipX+(tx-tipX)*q
        y1=bounds.y+2
    end
    local dist=math.sqrt((x1-tipX)^2+(y1-mouthY)^2)
    local approachDur=math.max(.18,dist/(1200*(self.permanentTraits.cigaretteProjectileSpeed or 1)))
    local fallDuration=fallsOffMap and 1.45 or 0
    self.molotovs[#self.molotovs+1] = {
        x0=tipX, y0=mouthY, x1=x1, y1=y1,
        t=0, dur=approachDur+fallDuration, approachDur=approachDur,fallDuration=fallDuration,
        fallsOffMap=fallsOffMap,dropDistance=2600,dropDrift=(tx-x1)*.16,
        manual=true, radius=(90+self:power("molotov")*20+self.permanentTraits.area+ScoreOperations.weaponArea(self))
            *(self:skillBranch("molotov")=="flame_route"and 1.25 or 1),
        landingAngle=.18+math.sin(tx*.013+ty*.017)*.6
    }
    if not isBarrage then
        self:trackMolotovBarrage(game)
        if self:skillBranch("molotov")=="butt_volley_route"then
            local dx,dy=tx-game.player.x,ty-game.player.y;local length=math.max(1,math.sqrt(dx*dx+dy*dy))
            local px,py=-dy/length,dx/length
            self:hurlMolotovAt(tx+px*54,ty+py*54,game,true)
            self:hurlMolotovAt(tx-px*54,ty-py*54,game,true)
        end
        for _ = 1, math.floor(self.permanentTraits.extraFires) do
            self:hurlMolotovAt(tx + love.math.random(-40,40), ty + love.math.random(-40,40), game, true)
        end
    end
end

function ClearcutMode:updateMolotovs(dt, game)
    self:updateMolotovImpacts(dt, game)
    CigaretteButts.update(self,dt,game)
    self:updateTreeSparks()
end

-- 날아가는 꽁초가 몬스터를 스치면 피해와 함께 짧은 접촉 피드백을 준다.
-- 착지의 최초 즉시 점화와 이후 잔류 불씨 확산은 cigarette_butts.lua가 담당한다.
function ClearcutMode:updateMolotovImpacts(dt, game)
    if #self.enemies == 0 then return end
    local dmg = (6+self:power("molotov")*4)*(self:skillBranch("molotov")=="flame_route"and 1.35 or 1)
    for _, flight in ipairs(self.molotovs) do
        if not flight.fallsOffMap then
            local previousX,previousY=CigaretteButts.flightPosition(flight,flight.t)
            local x,y=CigaretteButts.flightPosition(flight,flight.t+dt)
            flight.hitSet = flight.hitSet or {}
            for _, e in ipairs(self.enemies) do
                if not flight.hitSet[e] then
                    if CombatGeometry.sweptCircleOverlapsTarget(previousX,previousY,x,y,24,e) then
                        flight.hitSet[e] = true
                        e.hp = e.hp - dmg
                        self:igniteEnemy(e,game,0)
                        local impactReady=not self.scoreAttack or(self.permanentTraits.scoreCigaretteImpact or 0)>0
                        if impactReady then
                            e.visualHit=math.max(e.visualHit or 0,.20)
                            e.impactKick=math.max(e.impactKick or 0,.10)
                            e.impactKickDir=(e.x-previousX)>=0 and 1 or -1
                            self.emberArrivals[#self.emberArrivals+1]={x=e.x,y=e.y,startAt=self.smokerGroundTime,
                                expiresAt=self.smokerGroundTime+.20,duration=.20,scale=.46,targetKind="enemy",instant=true}
                            self.cigaretteHitStop=math.max(self.cigaretteHitStop or 0,.025)
                            if game.feedback then game.feedback:play("butt_hit",true) end
                        else e.visualHit=math.max(e.visualHit or 0,.14)end
                    end
                end
            end
        end
    end
end

function ClearcutMode:onTreeBurnedDown(node, game)
    local oilLevel = self:levelOf("oil_drum")
    local oilChance = oilLevel >= 6 and 1 or self:power("oil_drum") * .15
    if oilLevel > 0 and love.math.random() < oilChance then
        self:igniteNear(node, game, 90 + self:power("oil_drum") * 30, 99)
        game.world:igniteFx(node.x, node.y, true)
    end
end

function ClearcutMode:emitSecondhandSmoke(game)
    local facing=game.player.facing or 1
    local clouds=self.secondhandSmokeClouds
    clouds[#clouds+1]={
        x=game.player.x+facing*64,y=game.player.y-17,
        vx=facing*7,vy=-2.5,age=0,life=3.2,tick=0,
        radiusX=320,radiusY=200,
    }
    -- A fast reload build can overlap a large local fog bank, but cannot leave
    -- an unlimited trail of transparent overlays across the whole stage.
    while #clouds>3 do table.remove(clouds,1) end
end

function ClearcutMode:updateSecondhandSmoke(dt, game)
    local clouds=self.secondhandSmokeClouds
    for index=#clouds,1,-1 do
        local cloud=clouds[index]
        local activeDt=math.min(dt,math.max(0,cloud.life-cloud.age))
        cloud.age=cloud.age+activeDt
        cloud.x=cloud.x+cloud.vx*activeDt
        cloud.y=cloud.y+cloud.vy*activeDt
        cloud.tick=cloud.tick+activeDt
        while cloud.tick>=.25 do
            cloud.tick=cloud.tick-.25
            local damage=2.1+self:power("molotov")*.22
            for _,enemy in ipairs(self.enemies) do
                if enemy.hp>0 then
                    if CombatGeometry.ellipseOverlapsTarget(cloud.x,cloud.y,cloud.radiusX,cloud.radiusY,enemy) then
                        enemy.hp=enemy.hp-damage
                        enemy.visualHit=.08
                    end
                end
            end
        end
        if cloud.age>=cloud.life then table.remove(clouds,index) end
    end
end

function ClearcutMode:updateBurningEnemies(dt,game)
    if self.rainSuppressFire then
        for _,e in ipairs(self.enemies) do
            if e.burning then e.burning,e.burnTimer,e.fireTickTimer=false,nil,nil end
        end
        return
    end
    local damage=(5+self:power("molotov")*3)*(self:skillBranch("molotov")=="flame_route"and 1.3 or 1)
    for _,e in ipairs(self.enemies) do
        if e.burning then
            -- Enemy fire is one boolean state, never a stack. Additional fire
            -- sources are ignored until this fixed lifetime ends.
            local duration=e.burnDuration or ENEMY_BURN_DURATION
            local activeDt=math.min(dt,math.max(0,duration-(e.burnTimer or 0)))
            e.burnTimer=(e.burnTimer or 0)+activeDt
            e.fireTickTimer=(e.fireTickTimer or 0)-activeDt
            while e.fireTickTimer<-.000000001 and activeDt>0 do
                e.fireTickTimer=e.fireTickTimer+ENEMY_BURN_TICK
                e.hp=e.hp-damage
                e.visualHit=.14
                for _=1,3 do game.world:addParticle(e.x,e.y-12,{1,.35,.18},true,false) end
            end
            if e.burnTimer>=duration then
                e.burning,e.burnTimer,e.fireTickTimer=false,nil,nil
            end
        end
    end
end

function ClearcutMode:updateFire(dt, game)
    local molotovLevel = self:levelOf("molotov")
    -- 기록 모드의 담배 자동 투척은 이 루프를 그대로 쓴다. 간격 2.6초는 수동 투척
    -- 주기(약 2.2초)보다 느려서, 손을 비우는 대가로 화력을 조금 내주는 교환이 된다.
    local autoThrow = self.scoreAttack and (self.permanentTraits.scoreAutoThrow or 0) > 0
    if molotovLevel > 0 or autoThrow then
        self.molotovTimer = self.molotovTimer + dt
        -- `자동 투척 주기 단축`이 이 2.6초 상수를 연다. 손이 도끼·폭죽으로 넘어간 뒤의
        -- 담배 화력은 오직 이 간격으로만 자라므로, 없으면 후반 담배 수치가 고정된다.
        local autoInterval = 2.6 / (1 + math.max(0, self.permanentTraits.scoreAutoThrowRate or 0))
        local interval = autoThrow and autoInterval or math.max(2.6, 8 - self:power("molotov") * 1.6)
        if self.molotovTimer >= interval then
            self.molotovTimer = 0
            self:throwMolotov(game)
        end
    end
    local dryLevel = self:levelOf("dry_forest")
    local dryPower = self:power("dry_forest")
    local spreadRadius = 130 + dryPower * 45
    -- 연소 시간이 끝날 때까지 체력을 다 깎지 못하면 나무는 쓰러지지 않고 불만 꺼진다.
    -- 연소 시간은 고정하고 `연소속도`는 타격 주기를 줄인다 — 연소 시간 자체를 줄이는
    -- 방식이면 특성을 살수록 총 피해가 오히려 줄어 자기 발등을 찍는다.
    local burnDuration = BURN_WINDOW
    local burnTickInterval = BURN_TICK_INTERVAL
        / self.permanentTraits.burnSpeed
    -- `무기 피해`는 공용 수치이므로 도끼·폭죽뿐 아니라 불에도 걸린다. 연소속도가
    -- "더 자주", 무기 피해가 "더 세게"를 맡아 두 갈래가 총 피해를 함께 올린다.
    local burnTickDamage = BURN_TICK_DAMAGE + (self.permanentTraits.treeDamage or 0)
        + ScoreOperations.weaponDamage(self)
    self:updateStrawBales(dt, game)
    self:updateOilTrail(dt, game)
    self:updateSecondhandSmoke(dt, game)
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
            node.burnDamageTimer = (node.burnDamageTimer or burnTickInterval) - dt
            if node.burnDamageTimer <= 0 then
                node.burnDamageTimer = node.burnDamageTimer + burnTickInterval
                node.rushHp = (node.rushHp or node.rushMaxHp or 1) - burnTickDamage
                -- 한 번 씹을 때마다 눈에 보이게. 몇 번 더 타야 넘어가는지 읽혀야 한다.
                node.hitFlash = math.max(node.hitFlash or 0, .14)
            end
            if node.rushHp <= 0 then
                node.burning = false
                -- 예정된 확산을 다 내보내기 전에 나무가 먼저 타 없어질 수 있다. 남은
                -- 몫을 여기서 털어야 "확산량 = 옮겨붙일 기대 그루"가 체력과 무관해진다.
                local pending = (node.spreadBudget or 0) - (node.spreadDone or 0)
                if pending > 0 then
                    node.spreadDone = node.spreadBudget
                    self:igniteNear(node, game, spreadRadius, pending)
                end
                self:onTreeBurnedDown(node, game)
                self:fellTree(node, game)
            elseif node.burnTimer >= burnDuration then
                -- 다 탔는데 아직 살아 있다. 그을린 채로 남고, 다시 불을 붙이거나
                -- 도끼로 마무리해야 한다.
                node.burning, node.burnTimer, node.fireTickTimer = false, nil, nil
                node.spreadBudget, node.spreadDone, node.burnDamageTimer = nil, nil, nil
            elseif self:releaseSpread(node, burnDuration) then
                self:igniteNear(node, game, spreadRadius, 1)
            end
        end
    end
    self:updateBurningEnemies(dt,game)
end

-- 흡연자 전용 SPACE 액션: 담배 연기로 도넛(스모크 링)을 만들어 입에서 앞으로 쏜다.
-- 화염/착화가 아니라 순수 연기 — 자기 자리에서 팽창하는 게 아니라, 실제 스모크링처럼
-- 고리 모양을 유지한 채 캐릭터가 바라보는 방향(마우스 조준이 아님)으로 날아가며
-- 닿는 적에게 피해와 넉백을 준다.
function ClearcutMode:beginSmokeRingCharge(game)
    if self.job ~= "fire" or self.dead or self.smokeRing or self.smokeRingCharge then return false end
    if self.smokeRingCooldown > 0 then
        game:setNotice(string.format("도넛 연기 재사용 %.1f초", self.smokeRingCooldown), "food")
        return false
    end
    if self:levelOf("smoke_ring") < 6 then return self:activateSmokeRing(game, false) end
    self.smokeRingCharge={t=0}
    if game.player.setClearcutAction then game.player:setClearcutAction(.03) end
    game:setNotice("초농축 도넛 차지 — SPACE 유지", "food")
    return true
end

function ClearcutMode:releaseSmokeRingCharge(game)
    if not self.smokeRingCharge then return false end
    self.smokeRingCharge=nil
    if game.player.clearClearcutAction then game.player:clearClearcutAction() end
    return self:activateSmokeRing(game, false)
end

function ClearcutMode:activateSmokeRing(game, charged)
    if self.job ~= "fire" or self.dead or self.smokeRing then return false end
    if self.smokeRingCooldown > 0 then
        game:setNotice(string.format("도넛 연기 재사용 %.1f초", self.smokeRingCooldown), "food")
        return false
    end
    local power = self:power("smoke_ring")
    self.smokeRingCooldown = math.max(4, 8 - power)
    charged=charged or false
    local maxRange = 460 * (charged and 1.45 or 1)
    local _, mouthY, facing, tipX = self:smokerMouthPose(game)
    local nx, ny = facing, 0
    local speed = 480 * (charged and 1.18 or 1)
    local strength=charged and 2.35 or 1
    self.smokeRing = {
        x=tipX, y=mouthY, vx=nx * speed, vy=ny * speed,
        radius=14, startRadius=14, maxRadius=(52 + power * 6) * (charged and 1.65 or 1),
        dmg=(10 + power * 3) * strength, knockback=(420 + power * 20) * (charged and 1.8 or 1),
        maxRange=maxRange, traveled=0, hit={}, charged=charged
    }
    game:setNotice(charged and "초농축 도넛 — 푸우우우!" or "도넛 연기 — 후우...", "food")
    return true
end

function ClearcutMode:updateSmokeRing(dt, game)
    self.smokeRingCooldown = math.max(0, self.smokeRingCooldown - dt)
    if self.smokeRingCharge then
        self.smokeRingCharge.t=math.min(self.smokeRingChargeDuration,self.smokeRingCharge.t+dt)
        local progress=self.smokeRingCharge.t/self.smokeRingChargeDuration
        if game.player.setClearcutAction then game.player:setClearcutAction(.03+progress*.42) end
        if progress>=1 then
            self.smokeRingCharge=nil
            if game.player.clearClearcutAction then game.player:clearClearcutAction() end
            self:activateSmokeRing(game,true)
            if game.camera then game.camera.trauma=math.min(1,(game.camera.trauma or 0)+.28) end
            -- The charge dt belongs to the charging phase. Applying the same
            -- full step to the newly spawned ring can move it past its entire
            -- range in one frame and make the activated skill invisible.
            return
        end
    end
    local ring = self.smokeRing
    if not ring then return end
    local previousX,previousY=ring.x,ring.y
    local step = math.sqrt(ring.vx * ring.vx + ring.vy * ring.vy) * dt
    ring.x, ring.y = ring.x + ring.vx * dt, ring.y + ring.vy * dt
    ring.traveled = ring.traveled + step
    -- 처음엔 작게 시작해서 날아갈수록 점점 커진다(실제 담배연기 도넛처럼).
    local grow = math.min(1, ring.traveled / ring.maxRange)
    ring.radius = ring.startRadius + (ring.maxRadius - ring.startRadius) * grow
    -- The ring is an upright billboard, so its circular screen silhouette is
    -- intentionally independent from the pitched ground mesh.  Give the
    -- entire outer puff band an additional forgiving envelope and sweep that
    -- envelope over the full travelled segment so a visible crossing cannot
    -- miss between frames.
    local hitRadius=math.max(40,ring.radius*1.45+20)
    ring.hitRadius=hitRadius
    for _, e in ipairs(self.enemies) do
        if not ring.hit[e] then
            local dx, dy = e.x - ring.x, e.y - ring.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if CombatGeometry.sweptCircleOverlapsTarget(previousX,previousY,ring.x,ring.y,hitRadius,e) then
                ring.hit[e] = true
                local nx, ny = dist > .01 and dx / dist or 1, dist > .01 and dy / dist or 0
                e.hp = e.hp - ring.dmg
                e.visualHit = .14
                e.knockVX, e.knockVY, e.knockTimer = nx * ring.knockback, ny * ring.knockback, .32
            end
        end
    end
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and not ring.hit[node] then
            if CombatGeometry.sweptCircleOverlapsTarget(previousX,previousY,ring.x,ring.y,hitRadius,node,0) then
                ring.hit[node] = true
                node.rushHp = (node.rushHp or node.rushMaxHp) - ring.dmg
                game.world:impactNode(node, game, true)
                if node.rushHp <= 0 then self:fellTree(node, game) end
            end
        end
    end
    if ring.traveled >= ring.maxRange then self.smokeRing = nil end
end

-- 도넛 모양이 확실히 보이도록: 원 둘레를 촘촘한 부드러운 연기 뭉치들로 채워 하나의
-- 고리 실루엣을 이루게 하고, 그 위에 살짝 밝은 테두리선을 더해 도넛 형태를 강조한다.
function ClearcutMode:drawSmokeRing(t)
    local ring = self.smokeRing
    if not ring then return end
    local puffs = math.max(12, math.floor(ring.radius / 6))
    local puffSize = 12 + ring.radius * .3
    for i = 1, puffs do
        local a = (i / puffs) * math.pi * 2 + t * .5
        local jitter = math.sin(t * 3 + i * 2.1) * ring.radius * .05
        local r = ring.radius + jitter
        local px, py = ring.x + math.cos(a) * r, ring.y + math.sin(a) * r
        for layer = 3, 1, -1 do
            love.graphics.setColor(.74, .73, .68, .12 / layer)
            love.graphics.circle("fill", px, py, puffSize * (layer / 3))
        end
    end
    love.graphics.setLineWidth(2)
    love.graphics.setColor(.88, .87, .82, .3)
    love.graphics.circle("line", ring.x, ring.y, ring.radius)
    love.graphics.setColor(1,1,1,1)
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

function ClearcutMode:markPhilosopherPlague(kind,ref,duration,damage)
    if ref.plagueMarked then
        for _,plague in ipairs(self.plagued) do
            if plague.ref==ref then
                plague.timer=math.max(plague.timer or 0,duration)
                plague.dmg=math.max(plague.dmg or 0,damage or 1)
                return
            end
        end
    end
    ref.plagueMarked=true
    self.plagued[#self.plagued+1]={kind=kind,ref=ref,timer=duration,tickTimer=0,dmg=damage}
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

-- `상시 흡연`을 찍으면 근접 도끼질이나 폭죽 공격 중에도 담배 재장전이 흐른다.
-- 찍기 전에는 자동으로 도끼를 드는 동안 재장전이 멈춘다.
-- 손은 도끼질 중이므로 플레이어 애니메이션은 건드리지 않는다.
function ClearcutMode:tickSmokerReload(dt, game)
    -- 기본은 담배 공격 중에만 피운다. `상시 흡연`을 찍어야 다른 공격 중에도
    -- 계속 재장전된다.
    if (self.permanentTraits.scoreAlwaysSmoking or 0)<=0 then return end
    local smoking=self.smoking
    if not smoking or smoking.phase~="reload" then return end
    smoking.t=math.min(smoking.dur,smoking.t+dt)
    if smoking.t>=smoking.dur then
        smoking.phase,smoking.loaded="loaded",true
        if smoking.newCarton then self.cartonAmmo=self.cartonSize end
    end
end

function ClearcutMode:updateHeldAxe(dt, game, heldOverride)
    if self.scoreAttack and self.job=="fire" then
        local held=heldOverride
        if held==nil then held=love.mouse.isDown(1)end
        local weapon=(self.scoreAxeAction or(held and self:scoreMeleeTargetAtAim(game)))and"axe"or self:scoreRangedWeaponId()
        self.scoreActiveWeapon=weapon
        game.player.scoreAxeEquipped=weapon=="axe"
        game.player.hideAxeRange=weapon=="axe"
        if weapon~="cigarette" then self:tickSmokerReload(dt,game)end
        if weapon=="axe" then return self:updateScoreAxeAttack(dt,game,heldOverride)end
        if weapon=="flamethrower" then return self:updateFlamethrowerAttack(dt,game,held)end
        if weapon=="firework" then return self:updateFireworkAttack(dt,game,held)end
        return self:updateFireAttack(dt,game,heldOverride,true)
    end
    if self.job == "fire" then return self:updateFireAttack(dt, game, heldOverride) end
    if self.job == "toxic" then return self:updateToxicAttack(dt, game, heldOverride) end
    if self.job == "developer" then return self:updateDeveloperAttack(dt, game, heldOverride) end
    if self.job == "miner" then return self:updateMinerAttack(dt, game, heldOverride) end
    if self.job == "philosopher" then return self:updatePhilosopherAttack(dt, game, heldOverride) end
    return self:updatePhysicalAttack(dt, game, heldOverride)
end

function ClearcutMode:scoreWeaponId()
    return self.scoreActiveWeapon or self:scoreRangedWeaponId()
end

function ClearcutMode:scoreRangedWeaponId()
    -- 손은 한 번에 하나만 쓴다. 뒤에 해금한 무기가 앞의 무기를 대체하고, 대체된
    -- 무기는 졸업 원숭이가 이어받는다 — 도끼 -> 폭죽 -> 화염방사기 순서다.
    if self:scoreWeaponUnlocked(4)then return"flamethrower"end
    return self:scoreWeaponUnlocked(3)and"firework"or"cigarette"
end

-- Contextual selection only claims the click when the cursor is actually on a
-- nearby axe target. Merely standing beside a tree must not steal a deliberate
-- ranged shot aimed elsewhere.
function ClearcutMode:scoreMeleeTargetAtAim(game)
    local range=190+self.permanentTraits.range+ScoreOperations.weaponRange(self)
    local axeArea=(self.permanentTraits.scoreAxeArea or 0)+ScoreOperations.weaponArea(self)
    local tx,ty=game.camera:screenToWorld(love.mouse.getPosition())
    local reach=82+axeArea
    if self:findAxeOilDrum(game,tx,ty,range,reach)then return true end
    for _,node in ipairs(game.world.nodes)do if node.rushTree and node.active then
        local playerDistance=(node.x-game.player.x)^2+(node.y-game.player.y)^2
        local aimDistance=(node.x-tx)^2+(node.y-ty)^2
        if playerDistance<=range*range and aimDistance<=reach*reach then return true end
    end end
    return false
end

-- 폭죽은 담배 자동 투척 다음 노드로 해금한다. 담배가 알아서 날아가기 시작해 손이
-- 비는 시점에 손으로 쏘는 무기가 열리는 순서다.
function ClearcutMode:scoreWeaponUnlocked(index)
    local definition=ClearcutMode.scoreWeaponDefinitions[index]
    if definition and definition.id=="firework"then
        return (self.permanentTraits.scoreRocketUnlock or 0)>0
    end
    if definition and definition.id=="flamethrower"then
        return (self.permanentTraits.scoreFlameUnlock or 0)>0
    end
    return true
end

function ClearcutMode:graduationMonkeys()
    local result={}
    for _,companion in ipairs(self.moleCompanions or{})do if companion.kind=="lumberjack"then result[#result+1]=companion end end
    return result
end
-- 쓰러진 나무 자리에서 퍼지는 충격파. 연쇄로 또 충격파를 부르지는 않는다 —
-- 한 번의 도끼질이 무한 연쇄가 되지 않게 여기서 끊는다.
function ClearcutMode:axeShockwave(x,y,level,game)
    local radius=70+level*34
    local damage=level*2
    local felled=0
    for _,node in ipairs(game.world.nodes)do
        if node.rushTree and node.active and not node.giantTree and not node.treeEmergence then
            local dx,dy=node.x-x,node.y-y
            if dx*dx+dy*dy<=radius*radius then
                if self:damageTreeWithSmokerWeapon(node,damage,game)then felled=felled+1 end
            end
        end
    end
    self:damageEnemiesInRadius(x,y,radius,8+damage*2,game)
    self.traitFx:emit("axe",x,y,{radius=radius,power=1,particles=16})
    return felled
end

function ClearcutMode:resolveScoreAxeAction(action,game)
    if action.drum then
        if action.drum.state=="settled"then
            self:hitOilDrum(action.drum,action.damage,game)
            return true
        end
        return false
    end
    local hit=0
    local shockLevel=math.max(0,math.floor(self.permanentTraits.scoreAxeShock or 0))
    local chainChance=self.permanentTraits.scoreAxeChain or 0
    for _,node in ipairs(action.targets or{})do if node.active and node.rushTree then
        if action.executeChance>0 and node.rushHp and love.math.random()<action.executeChance then node.rushHp=1 end
        local x,y=node.x,node.y
        local felled=self:damageTreeWithSmokerWeapon(node,action.damage,game)
        self:damageEnemiesInRadius(x,y,62+action.axeArea,14+action.damage*2,game)
        self.traitFx:emit("axe",x,y,{radius=66,power=1,particles=12})
        if felled then
            -- 도끼는 동시 타격 3그루가 하드캡이라 후반 공급량을 못 따라간다. 충격파는
            -- 쓰러진 자리에서 주변으로 퍼져 그 천장을 숲 밀도에 비례하게 바꾼다.
            if shockLevel>0 then self:axeShockwave(x,y,shockLevel,game) end
            if chainChance>0 and love.math.random()<chainChance then self.axeCooldown=0 end
        end
        hit=hit+1
    end end
    self.maxMulti=math.max(self.maxMulti or 0,hit)
    return hit>0
end

function ClearcutMode:updateScoreAxeAction(dt,game)
    local action=self.scoreAxeAction
    if not action then return false,false end
    if (action.hitStop or 0)>0 then action.hitStop=math.max(0,action.hitStop-dt)
    else action.elapsed=math.min(action.duration,action.elapsed+dt)end
    if game.player.autoAxeClock~=nil then game.player.autoAxeClock=action.elapsed end
    local impacted=false
    if not action.impacted and action.elapsed>=action.contactTime then
        action.impacted=true;action.hitStop=.045
        impacted=self:resolveScoreAxeAction(action,game)
        self.actionAudit.scoreAxe=(self.actionAudit.scoreAxe or 0)+1
    end
    if action.elapsed>=action.duration then
        self.scoreAxeAction=nil
        game.player.autoAxeClock=nil
    end
    return self.scoreAxeAction~=nil,impacted
end

function ClearcutMode:updateScoreAxeAttack(dt,game,heldOverride)
    local held=heldOverride
    if held==nil then held=love.mouse.isDown(1)end
    local range=190+self.permanentTraits.range+ScoreOperations.weaponRange(self)
    local axeArea=(self.permanentTraits.scoreAxeArea or 0)+ScoreOperations.weaponArea(self)
    local tx,ty=self:aimPoint(game,range)
    self.aimX,self.aimY,self.aimRadius=tx,ty,54+axeArea
    game.player.facing=tx<game.player.x and -1 or 1
    game.player.scoreAxeEquipped=true
    game.player.hideAxeRange=true
    local active,impacted=self:updateScoreAxeAction(dt,game)
    game.player.axeHolding=held or active
    self.axeCooldown=math.max(0,(self.axeCooldown or 0)-dt)
    if active or not held or self.axeCooldown>0 then return impacted end

    local reach=82+axeArea
    local drum=self:findAxeOilDrum(game,tx,ty,range,reach)
    local targets={}
    if not drum then
        local candidates={}
        for _,node in ipairs(game.world.nodes)do if node.rushTree and node.active then
            local playerDistance=(node.x-game.player.x)^2+(node.y-game.player.y)^2
            local aimDistance=(node.x-tx)^2+(node.y-ty)^2
            if playerDistance<=range*range and aimDistance<=reach*reach then
                candidates[#candidates+1]={node=node,d=aimDistance}
            end
        end end
        table.sort(candidates,function(a,b)return a.d<b.d end)
        for i=1,math.min(#candidates,1+math.floor(self.permanentTraits.extraTargets or 0))do targets[i]=candidates[i].node end
        if #targets==0 then targets[1]=self:closestTreeInAxeRange(game)end
        if not targets[1]then return false end
    end

    game.player:cancelInteraction()
    local targetX=drum and drum.x or targets[1].x
    local speed=(game.tools.axe.speed or 1)*game.player.gather*self.permanentTraits.attackSpeed
        *ScoreOperations.attackSpeedMultiplier(self)*(1+(self.permanentTraits.scoreAxeSpeed or 0))
    local swingDuration=math.max(.18,.36/speed)
    game.player:playAutoAxeSwing(targetX,swingDuration)
    self.scoreAxeAction={elapsed=0,duration=swingDuration,contactTime=swingDuration*.52,
        drum=drum,targets=targets,damage=4+(self.permanentTraits.treeDamage or 0)+ScoreOperations.weaponDamage(self),axeArea=axeArea,
        executeChance=self.permanentTraits.executeChance or 0}
    self.axeCooldown=math.max(swingDuration,.62/speed)
    return false
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

local function smokerAim(mode,game,maxRange)
    local tx,ty=mode:aimPoint(game,maxRange);local dx,dy=tx-game.player.x,ty-game.player.y
    local distance=math.sqrt(dx*dx+dy*dy);if distance<1 then dx,dy,distance=game.player.facing or 1,0,1 end
    return tx,ty,dx/distance,dy/distance
end

function ClearcutMode:damageTreeWithSmokerWeapon(node,damage,game)
    if not node.active then return false end
    node.rushHp=(node.rushHp or node.rushMaxHp)-damage
    game.world:impactNode(node,game,true)
    if node.rushHp<=0 then return self:fellTree(node,game) end
    return false
end

local function vapeAimAngle(nx,ny)return math.atan2 and math.atan2(ny,nx)or math.atan(ny/nx)end

function ClearcutMode:releaseVapePressure(game,charge)
    charge=math.max(.15,math.min(1,charge or 0))
    local _,_,nx,ny=smokerAim(self,game,650+self.permanentTraits.range)
    game.player.facing=nx<0 and -1 or 1
    local x,y=game.player.x+nx*43,game.player.y-66+ny*8
    local range=360+charge*270+self.permanentTraits.range
    self.smokerWeaponProjectiles[#self.smokerWeaponProjectiles+1]={
        kind="vape_gust",x=x,y=y,nx=nx,ny=ny,angle=vapeAimAngle(nx,ny),age=0,maxLife=.52,
        range=range,maxWidth=42+charge*72+self.permanentTraits.area*.28,
        damage=4+charge*9+self.permanentTraits.treeDamage*.8,enemyDamage=18+charge*24,
        charge=charge,fullCharge=charge>=.98,front=0,hitSet={}
    }
    self.actionAudit.vapeShot=(self.actionAudit.vapeShot or 0)+1
    self.vapeKick=charge
    return true
end

function ClearcutMode:updateVapeAttack(dt,game,held)
    self.smokerWeaponCooldown=math.max(0,(self.smokerWeaponCooldown or 0)-dt)
    self.vapeKick=math.max(0,(self.vapeKick or 0)-dt*5.5)
    local tx,ty,nx,ny=smokerAim(self,game,610+self.permanentTraits.range)
    self.aimX,self.aimY,self.aimRadius=tx,ty,64+self.permanentTraits.area*.2
    game.player.facing=nx<0 and -1 or 1
    local speed=(game.tools.axe.speed or 1)*game.player.gather*self.permanentTraits.attackSpeed
    local chargeDuration=math.max(.52,.92/speed)
    if held and self.smokerWeaponCooldown<=0 then
        self.vapeCharge=math.min(1,(self.vapeCharge or 0)+dt/chargeDuration)
        if game.player.setClearcutAction then game.player:setClearcutAction(.16+self.vapeCharge*.30)end
        if self.vapeCharge>=1 then
            local fired=self:releaseVapePressure(game,1)
            self.vapeCharge=0;self.smokerWeaponCooldown=.18/speed
            if game.player.clearClearcutAction then game.player:clearClearcutAction()end
            return fired
        end
        return false
    end
    if not held and (self.vapeCharge or 0)>=.15 then
        local charge=self.vapeCharge;self.vapeCharge=0
        self.smokerWeaponCooldown=.18/speed
        if game.player.clearClearcutAction then game.player:clearClearcutAction()end
        return self:releaseVapePressure(game,charge)
    end
    if not held then
        self.vapeCharge=0
        if game.player.clearClearcutAction then game.player:clearClearcutAction()end
    end
    return false
end

-- 굵기가 일정한 전방 화염 기둥 판정. 조준축 위의 투영 거리와 수직 거리를 따로
-- 재서, 멀어질수록 벌어지는 부채꼴 대신 둥근 끝을 가진 긴 화염 덩어리와 일치한다.
function ClearcutMode.flameStreamCovers(ox,oy,nx,ny,reach,halfWidth,x,y)
    local dx,dy=x-ox,y-oy
    local along=dx*nx+dy*ny
    if along<0 or along>reach then return false end
    local acrossX,acrossY=dx-nx*along,dy-ny*along
    return acrossX*acrossX+acrossY*acrossY<=halfWidth*halfWidth
end

-- 화염방사기는 담배·도끼·폭죽과 달리 단발이 아니다. 쿨다운으로 한 발을 끊는 대신
-- 누르고 있는 동안 이 간격마다 화염 기둥 안의 모든 나무를 한꺼번에 지진다. 공격속도는
-- 틱 간격을 줄여 초당 피해와 착화 기회를 함께 올린다. 이 파일은 Lua 5.1의 청크당
-- 지역변수 200개 한도에 닿아 있어 새 상수는 모듈 테이블에 붙인다.
ClearcutMode.FLAME_TICK=.12

function ClearcutMode:updateFlamethrowerAttack(dt,game,held)
    local traits=self.permanentTraits
    self.smokerWeaponCooldown=math.max(0,(self.smokerWeaponCooldown or 0)-dt)
    local reach=250+(traits.scoreFlameRange or 0)+ScoreOperations.weaponRange(self)*.4
    local halfWidth=72+(traits.scoreFlameWidth or 0)+ScoreOperations.weaponArea(self)*.35
    local tx,ty,nx,ny=smokerAim(self,game,reach)
    self.aimX,self.aimY,self.aimRadius=tx,ty,reach*.5
    if not held then
        self.flameStream=nil
        if game.player.clearClearcutAction then game.player:clearClearcutAction()end
        return false
    end
    game.player.facing=nx<0 and -1 or 1
    local originX,originY=game.player.x+nx*34,game.player.y-58+ny*10
    self.flameStream={x=originX,y=originY,nx=nx,ny=ny,reach=reach,halfWidth=halfWidth,
        angle=(math.atan2 and math.atan2(ny,nx)or math.atan(ny/(nx==0 and 1e-6 or nx))),
        t=(self.flameStream and self.flameStream.t or 0)+dt}
    if game.player.setClearcutAction then game.player:setClearcutAction(.5+math.sin(self.flameStream.t*22)*.16)end
    if self.smokerWeaponCooldown>0 then return false end
    local speed=(game.tools.axe.speed or 1)*game.player.gather*traits.attackSpeed
        *ScoreOperations.attackSpeedMultiplier(self)
    self.smokerWeaponCooldown=ClearcutMode.FLAME_TICK/math.max(.25,speed)
    -- 직접 피해가 본체다. 점화는 이 피해와 독립된 추가 효과라 비가 오거나 확률이
    -- 실패해도 누르고 있는 동안 매 틱 체력은 계속 깎인다.
    local damage=(3+(traits.treeDamage or 0)+(traits.scoreFlameDamage or 0)
        +ScoreOperations.weaponDamage(self))*ClearcutMode.FLAME_TICK
    local igniteChance=(.18+(traits.scoreFlameIgnite or 0))*ClearcutMode.FLAME_TICK
    local hit=false
    for _,node in ipairs(game.world.nodes)do
        if node.rushTree and node.active and not node.treeEmergence
            and ClearcutMode.flameStreamCovers(originX,originY,nx,ny,reach,halfWidth,node.x,node.y)then
            hit=true
            local felled=self:damageTreeWithSmokerWeapon(node,damage,game)
            if not felled and not self.rainSuppressFire and not node.burning
                and love.math.random()<igniteChance then
                self:beginTreeBurn(node,0);game.world:igniteFx(node.x,node.y,false)
            end
        end
    end
    for _,enemy in ipairs(self.enemies)do
        if enemy.hp>0 and ClearcutMode.flameStreamCovers(originX,originY,nx,ny,reach,halfWidth,enemy.x,enemy.y)then
            hit=true
            enemy.hp=enemy.hp-(6+damage*2);enemy.visualHit=.12
            self:igniteEnemy(enemy,game,self.smokerGroundTime)
        end
    end
    if hit then self.actionAudit.flameTick=(self.actionAudit.flameTick or 0)+1 end
    return hit
end

function ClearcutMode:updateFireworkAttack(dt,game,held)
    -- 도끼·담배·화염방사기와 같은 규약을 지킨다. 실제 게임 루프는 heldOverride
    -- 없이 부르므로, nil을 그대로 "안 누름"으로 읽으면 아무리 클릭해도 발사가
    -- 되지 않는다. 여기서 마우스 상태를 직접 확인한다.
    if held==nil then held=love.mouse.isDown(1)end
    self.smokerWeaponCooldown=math.max(0,(self.smokerWeaponCooldown or 0)-dt)
    -- 폭발 반경은 담배용 착화 범위(area)를 ×0.3으로 얻어 쓰던 것을 전용 수치로 분리했다.
    local blastRadius=(self.permanentTraits.scoreRocketRadius or 0)+ScoreOperations.weaponArea(self)
    local tx,ty,nx,ny=smokerAim(self,game,720+self.permanentTraits.range+ScoreOperations.weaponRange(self))
    self.aimX,self.aimY,self.aimRadius=tx,ty,178+blastRadius
    if not held or self.smokerWeaponCooldown>0 then return false end
    game.player.facing=nx<0 and -1 or 1
    local x0,y0=game.player.x+nx*46,game.player.y-64+ny*8
    local flightSpeed=820*(1+(self.permanentTraits.scoreRocketSpeed or 0))
    local damage=8+self.permanentTraits.treeDamage*1.1+(self.permanentTraits.scoreRocketDamage or 0)+ScoreOperations.weaponDamage(self)
    local px,py=-ny,nx
    local lanes=(self.permanentTraits.scoreRocketTwin or 0)>0 and{-1,1}or{0}
    for _,lane in ipairs(lanes)do
        local sx,sy=x0+px*lane*10,y0+py*lane*10
        local ex,ey=tx+px*lane*62,ty+py*lane*62
        local dx,dy=ex-sx,ey-sy
        local distance=math.sqrt(dx*dx+dy*dy);local dur=math.max(.38,distance/flightSpeed)
        self.smokerWeaponProjectiles[#self.smokerWeaponProjectiles+1]={
            kind="firework",x=sx,y=sy,x0=sx,y0=sy,x1=ex,y1=ey,t=0,age=0,dur=dur,
            angle=(math.atan2 and math.atan2(dy,dx) or math.atan(dy/dx)),radius=180+blastRadius,damage=damage,
            twinLane=lane
        }
    end
    self.actionAudit.fireworkShot=(self.actionAudit.fireworkShot or 0)+1
    self.smokerWeaponCooldown=.86
        /((game.tools.axe.speed or 1)*game.player.gather*self.permanentTraits.attackSpeed
            *ScoreOperations.attackSpeedMultiplier(self)*(1+(self.permanentTraits.scoreRocketCooldown or 0)))
    return true
end

function ClearcutMode:detonateFirework(projectile,game)
    local radius=projectile.radius;local felled=0
    for _,node in ipairs(game.world.nodes)do if node.rushTree and node.active and CombatGeometry.circleOverlapsTarget(projectile.x1,projectile.y1,radius,node,24)then
        if self:damageTreeWithSmokerWeapon(node,projectile.damage,game)then felled=felled+1
        elseif not self.rainSuppressFire and love.math.random()<.38+(self.permanentTraits.scoreRocketIgnite or 0) then self:beginTreeBurn(node,0) end
    end end
    for _,enemy in ipairs(self.enemies)do if enemy.hp>0 and CombatGeometry.circleOverlapsTarget(projectile.x1,projectile.y1,radius,enemy)then
        enemy.hp=enemy.hp-(28+projectile.damage*1.5);enemy.visualHit=.18
        if self:enemyHasCategory(enemy,"plant")then self:igniteEnemy(enemy,game,self.smokerGroundTime)end
    end end
    self.maxChain=math.max(self.maxChain,felled)
    self.smokerWeaponProjectiles[#self.smokerWeaponProjectiles+1]={kind="firework_burst",x=projectile.x1,y=projectile.y1,age=0,life=1,radius=radius}
    -- 쌍발 두 발이 각각 자탄과 대단원을 복제하면 한 번에 10개 자탄과 4개 후속
    -- 폭발이 겹쳐 화면을 가린다. 좌측 선두 탄만 고급 연쇄를 맡아 형태를 읽게 한다.
    if not projectile.clusterChild and not projectile.echo and (projectile.twinLane or 0)<=0 then
        if (self.permanentTraits.scoreRocketCluster or 0)>0 then
            local childCount=5
            for child=1,childCount do
                local angle=-math.pi/2+(child-1)*math.pi*2/childCount
                local distance=radius*.66
                local ex,ey=projectile.x1+math.cos(angle)*distance,projectile.y1+math.sin(angle)*distance
                self.smokerWeaponProjectiles[#self.smokerWeaponProjectiles+1]={
                    kind="firework",x=projectile.x1,y=projectile.y1,x0=projectile.x1,y0=projectile.y1,x1=ex,y1=ey,
                    t=0,age=0,dur=.24,angle=angle,radius=math.max(46,radius*.24),damage=projectile.damage*.38,clusterChild=true
                }
            end
        end
        if (self.permanentTraits.scoreRocketFinale or 0)>0 then
            self.smokerWeaponProjectiles[#self.smokerWeaponProjectiles+1]={kind="firework_echo",x1=projectile.x1,y1=projectile.y1,age=0,delay=.22,radius=radius*.72,damage=projectile.damage*.32,echo=true}
            self.smokerWeaponProjectiles[#self.smokerWeaponProjectiles+1]={kind="firework_echo",x1=projectile.x1,y1=projectile.y1,age=0,delay=.44,radius=radius*.48,damage=projectile.damage*.22,echo=true}
        end
    end
end

function ClearcutMode:updateSmokerWeaponProjectiles(dt,game)
    local list=self.smokerWeaponProjectiles or {}
    local bursts={}
    for index=#list,1,-1 do local projectile=list[index]
        if projectile.kind=="vape_gust" then
            projectile.age=projectile.age+dt
            local progress=math.min(1,projectile.age/projectile.maxLife)
            local eased=1-(1-progress)*(1-progress)*(1-progress)
            projectile.front=projectile.range*eased
            local px,py=-projectile.ny,projectile.nx
            local function inside(target,targetRadius)
                local dx,dy=target.x-projectile.x,target.y-projectile.y
                local along=dx*projectile.nx+dy*projectile.ny
                if along < -18 or along > projectile.front+(targetRadius or 0) then return false end
                local side=math.abs(dx*px+dy*py)
                local width=25+(math.max(0,along)/projectile.range)*projectile.maxWidth
                return side<=width+(targetRadius or 0)
            end
            for _,node in ipairs(game.world.nodes)do if node.rushTree and node.active and not projectile.hitSet[node]and inside(node,24)then
                projectile.hitSet[node]=true
                node.rushHp=(node.rushHp or node.rushMaxHp)-projectile.damage
                if game.world.windImpactNode then game.world:windImpactNode(node,projectile.nx,projectile.ny,projectile.charge)end
                local leafCount=math.floor(8+projectile.charge*22)
                for leafIndex=1,leafCount do
                    local side=(love.math.random()*2-1)*(35+projectile.charge*42)
                    local life=.72+love.math.random()*.62
                    self.vapeWindLeaves[#self.vapeWindLeaves+1]={
                        x=node.x+px*side,y=node.y-58-love.math.random()*82,
                        vx=projectile.nx*(155+love.math.random()*150)*(0.48+projectile.charge*.62)+px*side*.8,
                        vy=projectile.ny*(70+love.math.random()*80)-45-love.math.random()*85,
                        angle=love.math.random()*math.pi*2,spin=(love.math.random()*2-1)*(7+projectile.charge*7),
                        age=0,life=life,frame=1+(leafIndex%8),scale=.72+love.math.random()*.48
                    }
                end
                if node.rushHp<=0 then self:fellTree(node,game)end
            end end
            for _,enemy in ipairs(self.enemies)do if enemy.hp>0 and not projectile.hitSet[enemy]and inside(enemy,18)then
                projectile.hitSet[enemy]=true;enemy.hp=enemy.hp-projectile.enemyDamage;enemy.visualHit=.18
                enemy.knockVX,enemy.knockVY,enemy.knockTimer=projectile.nx*(430+projectile.charge*520),projectile.ny*(430+projectile.charge*520),.28+.18*projectile.charge
            end end
            if projectile.age>=projectile.maxLife then table.remove(list,index)end
        elseif projectile.kind=="firework" then
            projectile.t=math.min(projectile.dur,projectile.t+dt);projectile.age=projectile.t
            local u=projectile.t/projectile.dur;projectile.x=projectile.x0+(projectile.x1-projectile.x0)*u
            projectile.y=projectile.y0+(projectile.y1-projectile.y0)*u-math.sin(u*math.pi)*76
            if projectile.t>=projectile.dur then bursts[#bursts+1]=projectile;table.remove(list,index)end
        elseif projectile.kind=="firework_burst" then
            projectile.age=projectile.age+dt;if projectile.age>=projectile.life then table.remove(list,index)end
        elseif projectile.kind=="firework_echo" then
            projectile.age=projectile.age+dt
            if projectile.age>=projectile.delay then bursts[#bursts+1]=projectile;table.remove(list,index)end
        end
    end
    for _,projectile in ipairs(bursts)do self:detonateFirework(projectile,game)end
    for index=#self.vapeWindLeaves,1,-1 do local leaf=self.vapeWindLeaves[index]
        leaf.age=leaf.age+dt;leaf.x=leaf.x+leaf.vx*dt;leaf.y=leaf.y+leaf.vy*dt
        leaf.vx=leaf.vx*math.exp(-dt*.72);leaf.vy=leaf.vy+72*dt;leaf.angle=leaf.angle+leaf.spin*dt
        if leaf.age>=leaf.life then table.remove(self.vapeWindLeaves,index)end
    end
end

function ClearcutMode:updateFireAttack(dt, game, heldOverride, forceBaseWeapon)
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    local evolution=not forceBaseWeapon and self:smokerEvolutionId()or nil
    if evolution=="vape" then return self:updateVapeAttack(dt,game,held)end
    if evolution=="fireworks" then return self:updateFireworkAttack(dt,game,held)end
    local maxRange = 320 + self:power("molotov") * 40 + self.permanentTraits.range + ScoreOperations.weaponRange(self)
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY, self.aimRadius = tx, ty, 90 + self:power("molotov") * 20 + self.permanentTraits.area+ScoreOperations.weaponArea(self)
    if not self.smoking then self:startSmoking(game) end
    local smoking = self.smoking
    -- Movement owns facing while smoking/ready. Mouse aim only turns the body
    -- during an actual throw, and that throw keeps its original direction.

    if smoking.phase == "reload" then
        smoking.t = math.min(smoking.dur, smoking.t + dt)
        local reloadProgress=smoking.t/smoking.dur
        if self.evolutions.secondhand_smoke and not smoking.smokeEmitted and reloadProgress>=.42 then
            smoking.smokeEmitted=true
            self:emitSecondhandSmoke(game)
        end
        if game.player.setClearcutAction then game.player:setClearcutAction(math.min(.48, reloadProgress * .48)) end
        if smoking.t >= smoking.dur then
            smoking.phase, smoking.loaded = "loaded", true
            if smoking.newCarton then self.cartonAmmo = self.cartonSize end
            if game.player.clearClearcutAction then game.player:clearClearcutAction() end
        end
        return false
    end

    if smoking.phase == "loaded" then
        if not held then return false end
        smoking.phase, smoking.t, smoking.dur = "flick", 0, math.max(.24, .52 / ((game.tools.axe.speed or 1) * game.player.gather * self.permanentTraits.attackSpeed*ScoreOperations.attackSpeedMultiplier(self)))
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
        self.streak, self.lastHitAt = self.streak + 1, self.elapsed
        local spent=self:skillBranch("molotov")=="butt_volley_route"and 3 or 1
        self.cartonAmmo = math.max(0, (self.cartonAmmo or self.cartonSize or 20) - spent)
        fired = true
    end
    if smoking.t >= smoking.dur then self:startSmoking(game) end
    return fired
end

-- 흡연자는 한 보루(20개비) 단위로 탄창을 관리한다. 남아있는 동안은 기존과 똑같이
-- 담배 한 개비 필 때마다의 짧은 "재장전"만 반복되지만, 다 피우면 새 보루를 뜯어야
-- 하므로 훨씬 긴 재장전이 한 번 끼고 그 다음 다시 가득 찬 채로 시작한다.
function ClearcutMode:startSmoking(game)
    self.cartonSize = 20 + math.floor(math.max(0, self.permanentTraits.scoreCartonSize or 0))
    if self.cartonAmmo == nil then self.cartonAmmo = self.cartonSize end
    local speed = (game.tools.axe.speed or 1) * game.player.gather * self.permanentTraits.attackSpeed*ScoreOperations.attackSpeedMultiplier(self)
    local newCarton = self.cartonAmmo <= 0
    -- 두 재장전은 서로 다른 상수 벽에 막혀 있었다. 배수를 나눗셈으로 걸되 하한에도 같이
    -- 걸어야 한다 — 하한만 남기면 2~3단계부터 노드가 아무 일도 하지 않는다.
    local buttBoost = 1 + math.max(0, self.permanentTraits.scoreReloadSpeed or 0)
    local cartonBoost = 1 + math.max(0, self.permanentTraits.scoreCartonReload or 0)
    local dur = newCarton
        and math.max(2.4 / cartonBoost, 4.4 / (speed * cartonBoost))
        or math.max(.75 / buttBoost, 1.25 / (speed * buttBoost))
    if self.scoreAttack and not self.scoreInitialSmokingStarted then
        dur=math.max(.35,dur-math.max(0,self.permanentTraits.scoreInitialIgnitionReduction or 0))
        self.scoreInitialSmokingStarted=true
    end
    self.smoking = {phase="reload",t=0,dur=dur,loaded=false,fired=false,smokeEmitted=false,newCarton=newCarton}
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
    local forkPower=self:power("fork_feast")
    local maxRange = 108 + forkPower * 12 + self:power("buffet_fork")*5 + self.permanentTraits.range
    local tx, ty = self:aimPoint(game, maxRange)
    self.aimX, self.aimY = tx, ty
    self.aimRadius = 28 + self:power("buffet_fork")*7 + self.permanentTraits.area*.35
    if self.veganAction then
        local action = self.veganAction
        action.t = math.min(action.dur, action.t + dt)
        local progress = action.t / action.dur
        if game.player.setClearcutAction then game.player:setClearcutAction(progress) end
        local struck = false
        if not action.struck and progress >= .53 then
            action.struck = true
            self:applyVeganFork(action, game)
            self.actionAudit.veganFork = self.actionAudit.veganFork + 1
            self.streak, self.lastHitAt = self.streak + 1, self.elapsed
            struck = true
        end
        if action.t >= action.dur then
            self.veganAction = nil
            self.attackCooldown = .08
            if game.player.clearClearcutAction then game.player:clearClearcutAction() end
        end
        return struck
    end
    self.attackCooldown = math.max(0, self.attackCooldown - dt)
    if not held or self.attackCooldown > 0 then return false end
    local haste=(self.veganHaste or 0)>0 and (1+self:power("seconds_please")*.08) or 1
    local speed = (game.tools.axe.speed or 1) * game.player.gather * self.permanentTraits.attackSpeed * haste
    self.veganAction = {t=0,dur=math.max(.50,.78/speed),tx=tx,ty=ty,struck=false,facing=tx<game.player.x and -1 or 1}
    game.player.facing = tx < game.player.x and -1 or 1
    if game.player.setClearcutAction then game.player:setClearcutAction(0) end
    return false
end

function ClearcutMode:applyVeganFork(action, game)
    local px,py=game.player.x,game.player.y-10
    local dx,dy=action.tx-px,action.ty-py
    local length=math.sqrt(dx*dx+dy*dy)
    if length<1 then dx,dy,length=game.player.facing or 1,0,1 end
    local nx,ny=dx/length,dy/length
    local range=108+self:power("fork_feast")*12+self:power("buffet_fork")*5+self.permanentTraits.range
    local halfWidth=28+self:power("buffet_fork")*7+self.permanentTraits.area*.35
    local dmg=2+self:power("fork_feast")+self.permanentTraits.biteDamage
    local candidates={}
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local ox,oy=node.x-px,node.y-py
            local along=ox*nx+oy*ny
            local lateral=math.abs(ox*ny-oy*nx)
            if along>=-8 and along<=range and lateral<=halfWidth*(.72+along/range*.28) then
                candidates[#candidates+1]={node=node,along=along,lateral=lateral}
            end
        end
    end
    table.sort(candidates,function(a,b) return a.lateral+a.along*.05<b.lateral+b.along*.05 end)
    local reach=1+math.floor(self:power("buffet_fork")/2)+math.floor(self.permanentTraits.extraTargets)
    if self.evolutions.allYouCanEat then reach=reach+2; dmg=dmg+3 end
    local echo=self:levelOf("buffet_fork")>=6
    reach=math.min(#candidates,reach)
    local consumed=0
    for i = 1, reach do
        local node = candidates[i].node
        node.rushHp=(node.rushHp or node.rushMaxHp)-dmg-(echo and math.ceil(dmg*.5) or 0)
        game.world:impactNode(node,game,true)
        VeganForkArt.impact(self,node.x,node.y-38)
        if echo then VeganForkArt.impact(self,node.x+nx*12,node.y-38+ny*12) end
        if node.rushHp<=0 then
            VeganForkArt.consume(self,node,game)
            if self:fellTree(node,game) then
                consumed=consumed+1
                self.actionAudit.veganConsume=self.actionAudit.veganConsume+1
                if game.achievements then game.achievements:add("vegan_eaten",1) end
                local plate=self:power("clean_plate")
                if plate>0 then
                    self.hp=math.min(self.maxHp,self.hp+1+math.floor(plate/2))
                    self:onWood(math.max(1,math.floor(plate/2)),game)
                    if self:levelOf("clean_plate")>=6 then self:damageEnemiesInRadius(node.x,node.y,120,10+plate*2,game) end
                end
            end
        end
    end
    for _,e in ipairs(self.enemies) do
        local ox,oy=e.x-px,e.y-py
        local along=ox*nx+oy*ny
        local lateral=math.abs(ox*ny-oy*nx)
        local body=CombatGeometry.targetRadius(e)
        if along>=-body and along<=range+body and lateral<=halfWidth+body then
            local alive=e.hp>0
            e.hp=e.hp-dmg*(echo and 4.5 or 3); e.visualHit=.16
            VeganForkArt.impact(self,e.x,e.y-12)
            if alive and e.hp<=0 and not e.veganConsumed then
                e.veganConsumed=true
                VeganForkArt.consumeEnemy(self,e,game)
                consumed=consumed+1
                self.actionAudit.veganConsume=self.actionAudit.veganConsume+1
                if game.achievements then game.achievements:add("vegan_eaten",1) end
                local plate=self:power("clean_plate")
                if plate>0 then
                    self.hp=math.min(self.maxHp,self.hp+1+math.floor(plate/2))
                    if self:levelOf("clean_plate")>=6 then self:damageEnemiesInRadius(e.x,e.y,120,10+plate*2,game) end
                end
            end
        end
    end
    if consumed>0 then
        self.veganHaste=1.6+self:power("seconds_please")*.28
        if self.evolutions.allYouCanEat then self.veganHaste=self.veganHaste+1.2 end
    end
    if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+(consumed>0 and .24 or .12)) end
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
            local range=112+self:power("detector")*16+self.permanentTraits.range
            -- Clearcut movement continues during the wind-up. Keep the input
            -- direction, but rebuild the endpoint from the current player
            -- position so the claw cannot swing at a stale world coordinate.
            local strikeDistance=math.min(range,action.distance or range)
            local strikeX=game.player.x+(action.dirX or 1)*strikeDistance
            local strikeY=game.player.y+(action.dirY or 0)*strikeDistance
            self:applyClawSwipe(strikeX,strikeY,game)
            self.streak, self.lastHitAt = self.streak + 1, self.elapsed
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
    local dx,dy=tx-game.player.x,ty-game.player.y
    local distance=math.sqrt(dx*dx+dy*dy)
    if distance<1 then dx,dy,distance=game.player.facing or 1,0,1 end
    self.minerClawAction = {t=0, dur=math.max(.34, .62/speed), tx=tx, ty=ty,
        dirX=dx/distance,dirY=dy/distance,distance=math.min(distance,maxRange),struck=false}
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


-- The claw atlas is anchored at (96,64). Its visible contact reaches roughly
-- 72 native pixels behind and 85 ahead of that anchor, with 39px half-width.
-- These helpers keep area damage bound to the one visible swipe.
local function clawPointHit(x,y,radius,cx,cy,nx,ny,halfWidth)
    local rx,ry=x-cx,y-cy
    local along=rx*nx+ry*ny
    local side=math.abs(rx*ny-ry*nx)
    local back=halfWidth*(72/39)
    local forward=halfWidth*(85/39)
    radius=radius or 0
    return along>=-back-radius and along<=forward+radius and side<=halfWidth+radius
end

local function clawVerticalContact(x,top,bottom,radius,cx,cy,nx,ny,halfWidth)
    local back=halfWidth*(72/39)
    local forward=halfWidth*(85/39)
    local ys={top,(top+bottom)*.5,bottom,cy}
    if math.abs(nx)>.0001 then ys[#ys+1]=cy+(x-cx)*ny/nx end
    if math.abs(ny)>.0001 then
        ys[#ys+1]=cy+(-back-(x-cx)*nx)/ny
        ys[#ys+1]=cy+(forward-(x-cx)*nx)/ny
    end
    local bestY,bestSide
    for _,candidate in ipairs(ys) do
        local y=math.max(top,math.min(bottom,candidate))
        if clawPointHit(x,y,radius,cx,cy,nx,ny,halfWidth) then
            local side=math.abs((x-cx)*ny-(y-cy)*nx)
            if not bestSide or side<bestSide then bestY,bestSide=y,side end
        end
    end
    return bestY
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
    local contact=math.min(range,distance)
    local contactX,contactY=px+nx*contact,py+ny*contact
    -- A click owns one composite swipe. Every target consumes this same
    -- visible envelope and can never create another effect instance.
    MoleClawArt.spawn(self,contactX,contactY,angle,clawLevel,curveFlip,halfWidth,1,clawLevel>=6)
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local hitY=clawVerticalContact(node.x,node.y-150,node.y,0,contactX,contactY,nx,ny,halfWidth)
            if hitY then
                node.rushHp = (node.rushHp or node.rushMaxHp) - damage
                game.world:impactNode(node, game, true)
                SupplementArt.impact(self,"axe",node.x,hitY,30)
                if node.rushHp <= 0 then self:fellTree(node,game) end
            end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        local hitY=clawVerticalContact(enemy.x,enemy.y-28,enemy.y+4,enemy.def.radius or 0,contactX,contactY,nx,ny,halfWidth)
        if hitY then
            enemy.hp, enemy.visualHit = enemy.hp - damage*2.2, .14
            SupplementArt.impact(self,"axe",enemy.x,hitY,26)
        end
    end
    self.traitFx:emit("axe",contactX,contactY,{radius=halfWidth,power=.8,angle=angle})
    if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.09) end
end

function ClearcutMode:eruptMinerBurrow(game)
    local burrow=self.minerBurrow
    if not burrow or burrow.state~="tunnel" then return false end
    local power=self:power("burrow_uproot")
    local radius=150+power*10+self.permanentTraits.area*.35
    local damage=10+power*2+self.permanentTraits.treeDamage
    local hit=0
    for _,enemy in ipairs(self.enemies) do
        if enemy.hp>0 then
            local dx,dy=enemy.x-game.player.x,enemy.y-game.player.y
            local distance=math.sqrt(dx*dx+dy*dy)
            if distance<=radius+(enemy.def.radius or 0) then
                if distance<1 then dx,dy,distance=game.player.facing or 1,0,1 end
                local kick=120+power*15
                enemy.hp=enemy.hp-damage
                enemy.visualHit=.16
                enemy.knockTimer=0
                enemy.airborneT=0
                enemy.airborneDuration=.72+power*.02
                enemy.airbornePeak=92+power*9
                enemy.airborneVX,enemy.airborneVY=dx/distance*kick,dy/distance*kick
                hit=hit+1
            end
        end
    end
    burrow.state,burrow.t,burrow.erupted="exit",0,true
    self:addBurrowTrack(game.player.x,game.player.y,0,"burst")
    -- Reuse the authored underground/action cells in reverse: mound, half body,
    -- then normal standing pose. This reads as a surface burst instead of
    -- replaying the dive pose forward.
    if game.player.setClearcutAction then game.player:setClearcutAction(.72) end
    self.traitFx:emit("construction_blast",game.player.x,game.player.y,{radius=radius,particles=30,power=1.1,color={.55,.38,.2}})
    if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.3) end
    game:setNotice(string.format("지상 돌파 — 몬스터 %d마리 에어본!",hit),"ore")
    return true
end

function ClearcutMode:activateMinerBurrow(game)
    if self.job ~= "miner" or self.dead then return false end
    if self.minerBurrow then
        return self:eruptMinerBurrow(game)
    end
    if self.minerBurrowCooldown > 0 then
        game:setNotice(string.format("잠복 재사용 %.1f초",self.minerBurrowCooldown),"ore")
        return false
    end
    self.minerClawAction = nil
    self.attackCooldown = 0
    self.minerBurrow = {
        state="enter", t=0, duration=3.2+self:power("burrow_uproot")*.22,
        lastX=game.player.x,lastY=game.player.y,trackX=game.player.x,trackY=game.player.y,side=1,launched=0,
        cowardTimer=0,cowardSequence=0
    }
    self:addBurrowTrack(game.player.x,game.player.y,0,"entry")
    if game.player.setClearcutAction then game.player:setClearcutAction(.52) end
    game:setNotice(self.evolutions.coward_barrage and "비겁한 와다다다 — 땅속에서 마구 할퀸다!" or "지하 강제집행 — 나무 밑으로 파고들어라!","ore")
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

-- 융합 "비겁한 와다다다": 잠복 중에는 멈춰 있어도 지상의 실제 공격 지점을 연속으로 할퀸다.
-- 한 이펙트에 닿은 모든 나무와 적이 함께 맞으며 대상 수가 FX 수를 늘리지 않는다.
function ClearcutMode:burrowCowardBarrage(game,moveX,moveY)
    local burrow=self.minerBurrow
    if not self.evolutions.coward_barrage or not burrow or burrow.state~="tunnel" then return false end
    local px,py=game.player.x,game.player.y
    local range=205+self.permanentTraits.range*.25
    local targets={}
    for _,node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local d2=(node.x-px)^2+(node.y-py)^2
            if d2<=range^2 then targets[#targets+1]={kind="tree",ref=node,x=node.x,y=node.y-58,d2=d2} end
        end
    end
    for _,enemy in ipairs(self.enemies) do
        if enemy.hp>0 then
            local d2=(enemy.x-px)^2+(enemy.y-py)^2
            if d2<=range^2 then targets[#targets+1]={kind="enemy",ref=enemy,x=enemy.x,y=enemy.y-12,d2=d2} end
        end
    end
    if #targets==0 then return false end
    table.sort(targets,function(a,b)return a.d2<b.d2 end)
    burrow.cowardSequence=(burrow.cowardSequence or 0)+1
    local target=targets[(burrow.cowardSequence-1)%math.min(4,#targets)+1]
    local dx,dy=target.x-px,target.y-py
    local length=math.sqrt(dx*dx+dy*dy)
    if length<1 then dx,dy=moveX,moveY;length=math.sqrt(dx*dx+dy*dy) end
    if length<1 then dx,dy,length=game.player.facing or 1,0,1 end
    local nx,ny=dx/length,dy/length
    local angle=math.atan2 and math.atan2(ny,nx) or math.atan(ny/nx)+(nx<0 and math.pi or 0)
    local hand=burrow.cowardSequence%2+1
    local halfWidth=27+self.permanentTraits.area*.12
    MoleClawArt.spawn(self,target.x,target.y,angle,6,nx>=0 and -1 or 1,halfWidth,hand,true)
    local damage=2.2+self:power("detector")*.5+self.permanentTraits.treeDamage
    for _,node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local hitY=clawVerticalContact(node.x,node.y-150,node.y,0,target.x,target.y,nx,ny,halfWidth)
            if hitY then
                node.rushHp=(node.rushHp or node.rushMaxHp)-damage
                game.world:impactNode(node,game,true)
                SupplementArt.impact(self,"axe",node.x,hitY,25)
                if node.rushHp<=0 then self:fellTree(node,game) end
            end
        end
    end
    for _,enemy in ipairs(self.enemies) do
        if enemy.hp>0 then
            local hitY=clawVerticalContact(enemy.x,enemy.y-28,enemy.y+4,enemy.def.radius or 0,target.x,target.y,nx,ny,halfWidth)
            if hitY then
                enemy.hp=enemy.hp-damage*1.6
                enemy.visualHit=.14
                SupplementArt.impact(self,"axe",enemy.x,hitY,23)
            end
        end
    end
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
        if self.evolutions.coward_barrage then
            burrow.cowardTimer=(burrow.cowardTimer or 0)+dt
            local strikes=math.min(4,math.floor(burrow.cowardTimer/.14))
            burrow.cowardTimer=burrow.cowardTimer-strikes*.14
            if strikes==4 and burrow.cowardTimer>=.14 then burrow.cowardTimer=burrow.cowardTimer%.14 end
            for _=1,strikes do self:burrowCowardBarrage(game,moveX,moveY) end
        end
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
    if game.player.setClearcutAction then
        local exitPose=burrow.t<.055 and .72 or (burrow.t<.135 and .58 or .04)
        game.player:setClearcutAction(exitPose)
    end
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
        local previousX,previousY=tree.x,tree.y
        tree.x,tree.y=tree.x+tree.vx*dt,tree.y+tree.vy*dt
        tree.z=tree.z+tree.vz*dt
        tree.vz=tree.vz-tree.gravity*dt
        tree.angle=tree.angle+tree.spin*dt
        local remove=false
        for _,node in ipairs(game.world.nodes) do
            if not remove and node.rushTree and node.active and not tree.hit[node] then
                if CombatGeometry.segmentDistanceSquared(node.x,node.y,previousX,previousY,tree.x,tree.y)<=68*68 then
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
                if CombatGeometry.sweptCircleOverlapsTarget(previousX,previousY,tree.x,tree.y,62,enemy) then
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

-- 공용 보조 스킬 7종과 직업 전용 스킬. 시각 이벤트는 전투 시간으로만 진행한다.
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
    if level <= 0 then self.bats = nil;self.batAttackTimer=nil; return end
    local growth=self:growth("bat_swarm")
    local count = 1+math.floor(growth*3+.0001)
    self.bats = self.bats or {}
    for i = 1, count do
        self.bats[i] = self.bats[i] or {angle = (i / count) * math.pi * 2,state="orbit"}
    end
    for i = #self.bats, count + 1, -1 do self.bats[i] = nil end
    local orbitRadius = 78 + growth * 45
    local targetRange = 360 + growth * 180
    local dmg = (.35 + growth * 3.65)*self:skillDamage("bat_swarm")
    local atan2=math.atan2 or math.atan
    local function alive(target)
        return target and ((target.rushTree and target.active) or (not target.rushTree and target.hp and target.hp>0))
    end
    local function chooseTarget()
        local best,bestD2=nil,targetRange*targetRange
        -- Monster candidates are a separate first pass, so even a nearer tree
        -- cannot steal a dive while a living monster is in search range.
        for _,enemy in ipairs(self.enemies) do
            if enemy.hp>0 then
                local dx,dy=enemy.x-game.player.x,enemy.y-game.player.y
                local d2=dx*dx+dy*dy
                if d2<=bestD2 then best,bestD2=enemy,d2 end
            end
        end
        return best
    end
    for _, bat in ipairs(self.bats) do
        bat.angle = bat.angle + dt * 2.15
        local orbitX=game.player.x+math.cos(bat.angle)*orbitRadius
        local orbitY=game.player.y+math.sin(bat.angle)*orbitRadius*.6-14
        if bat.state=="dive" then
            bat.moveT=math.min(1,(bat.moveT or 0)+dt/(bat.moveDur or .28))
            local target=bat.target
            if alive(target) then
                bat.targetX=target.x;bat.targetY=target.y-(target.rushTree and 42 or 12)
            end
            local p=1-(1-bat.moveT)^3
            local oldX,oldY=bat.x or bat.startX,bat.y or bat.startY
            bat.x=bat.startX+(bat.targetX-bat.startX)*p
            bat.y=bat.startY+(bat.targetY-bat.startY)*p
            bat.flightAngle=atan2(bat.y-oldY,bat.x-oldX)
            if bat.moveT>=1 then
                if alive(target) then
                    if target.rushTree then
                        target.rushHp=(target.rushHp or target.rushMaxHp)-dmg
                        game.world:impactNode(target,game,false)
                        if target.rushHp<=0 then self:fellTree(target,game) end
                    else
                        target.hp=target.hp-dmg;target.visualHit=.14
                    end
                end
                SupplementArt.impact(self,"bat",bat.targetX,bat.targetY,32)
                bat.state="return";bat.moveT=0;bat.startX=bat.x;bat.startY=bat.y;bat.target=nil
            end
        elseif bat.state=="return" then
            bat.moveT=math.min(1,(bat.moveT or 0)+dt/.24)
            local p=bat.moveT*bat.moveT*(3-2*bat.moveT)
            local oldX,oldY=bat.x or bat.startX,bat.y or bat.startY
            bat.x=bat.startX+(orbitX-bat.startX)*p
            bat.y=bat.startY+(orbitY-bat.startY)*p
            bat.flightAngle=atan2(bat.y-oldY,bat.x-oldX)
            if bat.moveT>=1 then bat.state="orbit" end
        else
            bat.state="orbit";bat.x,bat.y=orbitX,orbitY
            bat.flightAngle=atan2(math.cos(bat.angle)*.6,-math.sin(bat.angle))
        end
    end
    self.batAttackTimer=(self.batAttackTimer or 0)-dt
    if self.batAttackTimer>0 then return end
    local target=chooseTarget()
    if not target then self.batAttackTimer=.18;return end
    local selected
    for step=1,count do
        local index=((self.batAttackCursor or 0)+step-1)%count+1
        if self.bats[index].state=="orbit" then selected=self.bats[index];self.batAttackCursor=index;break end
    end
    if not selected then self.batAttackTimer=.08;return end
    selected.state="dive";selected.moveT=0;selected.moveDur=.22+math.min(.16,math.sqrt((target.x-selected.x)^2+(target.y-selected.y)^2)/1500)
    selected.startX,selected.startY=selected.x,selected.y
    selected.target=target;selected.targetX=target.x;selected.targetY=target.y-(target.rushTree and 42 or 12)
    self.batAttackTimer=(1.8-growth*1.15)*self:autoSkillCooldown("bat_swarm")
end

function ClearcutMode:updateThornAura(dt, game)
    local level = self:levelOf("thorn_aura")
    if level <= 0 then return end
    self.auraTimer = (self.auraTimer or 0) - dt
    if self.auraTimer > 0 then return end
    local growth=self:growth("thorn_aura")
    self.auraTimer = (3.4-growth*2.4)*self:autoSkillCooldown("thorn_aura")
    local radius = (120 + growth*215)*self:skillArea("thorn_aura")
    local dmg = (.35 + growth*3.65)*self:skillDamage("thorn_aura")
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
    local growth=self:growth("crow_strike")
    self.crowTimer = (7-growth*5.6)*self:autoSkillCooldown("crow_strike")
    local range = 620
    -- 공용 스킬은 무조건 몬스터부터 노린다: 사거리 안에 적이 있으면 나무는 아예 후보에서 뺀다.
    local best, bestD2 = nil, -1
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - game.player.x, e.y - game.player.y
        local d2 = dx*dx + dy*dy
        if d2 <= range*range and d2 > bestD2 then best, bestD2 = e, d2 end
    end
    if not best then return end
    local dmg = (1.5 + growth*32.5)*self:skillDamage("crow_strike")
    local radius = (35 + growth*80)*self:skillArea("crow_strike")
    if best.rushTree then
        best.rushHp = (best.rushHp or best.rushMaxHp) - dmg
        game.world:impactNode(best, game, true)
        if best.rushHp <= 0 then self:fellTree(best, game) end
    else
        best.hp = best.hp - dmg
        best.visualHit = .14
    end
    if level>=2 then self:damageEnemiesInRadius(best.x,best.y,radius,dmg*.5,game) end
    self.crowFx[#self.crowFx+1] = {x=best.x,y=best.y,angle=math.atan2(best.y-game.player.y,best.x-game.player.x),radius=radius,life=.32,maxLife=.32}
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
    self.whipTimer = (self.whipTimer or 0) - dt
    if self.whipTimer > 0 then return end
    local growth=self:growth("vine_whip")
    self.whipTimer = (9-growth*5.5)*self:autoSkillCooldown("vine_whip")
    local range = (260+growth*330)*self:skillArea("vine_whip")
    -- 조준 방향은 몬스터를 우선한다: 사거리 안에 적이 있으면 나무는 후보에서 뺀다.
    local nearest, nearestD2 = nil, range * range
    for _, e in ipairs(self.enemies) do
        local dx, dy = e.x - game.player.x, e.y - game.player.y
        local d2 = dx*dx + dy*dy
        if d2 <= nearestD2 then nearest, nearestD2 = e, d2 end
    end
    if not nearest then self.whipTimer=.15;return end
    local atan2 = math.atan2 or math.atan
    local angle
    angle = atan2(nearest.y - game.player.y, nearest.x - game.player.x)
    local dmg = (.8+growth*17.2)*self:skillDamage("vine_whip")
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
            if CombatGeometry.coneOverlapsTarget(game.player.x,game.player.y,angle,range,cone,e) then
                e.hp = e.hp - dmg
                e.visualHit = .14
        end
    end
    self.whipFx[#self.whipFx+1] = {x=game.player.x,y=game.player.y,angle=angle, range=range, life=.22, maxLife=.22}
end

function ClearcutMode:updateBoomerangAxe(dt, game)
    local level = self:levelOf("boomerang_axe")
    self.boomerangs = self.boomerangs or {}
    for i = #self.boomerangs, 1, -1 do
        local b = self.boomerangs[i]
        local speed=b.speed or 480
        local previousX,previousY=b.x,b.y
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
                    local hitRadius=b.radius or 64
                    if CombatGeometry.segmentDistanceSquared(node.x,node.y,previousX,previousY,b.x,b.y)<=hitRadius*hitRadius then
                        b.hitSet[node] = true
                        SupplementArt.impact(self,"axe",node.x,node.y,hitRadius)
                        node.rushHp = (node.rushHp or node.rushMaxHp) - b.dmg
                        game.world:impactNode(node, game, false)
                        if node.rushHp <= 0 then self:fellTree(node, game) end
                    end
                end
            end
            for _, e in ipairs(self.enemies) do
                if not b.hitSet[e] then
                    local hitRadius=b.radius or 64
                    if CombatGeometry.sweptCircleOverlapsTarget(previousX,previousY,b.x,b.y,hitRadius,e) then
                        b.hitSet[e] = true
                        SupplementArt.impact(self,"axe",e.x,e.y,hitRadius)
                        e.hp = e.hp - b.dmg
                        e.visualHit = .14
                        if b.phase=="out" and b.branch=="ricochet_axe" and (b.ricochets or 0)<3 then
                            local nextTarget,nextD2=nil,340*340
                            for _,candidate in ipairs(self.enemies)do
                                if candidate~=e and candidate.hp and candidate.hp>0 and not b.hitSet[candidate]then
                                    local dx,dy=candidate.x-b.x,candidate.y-b.y;local d2=dx*dx+dy*dy
                                    if d2<nextD2 then nextTarget,nextD2=candidate,d2 end
                                end
                            end
                            if nextTarget then
                                local dx,dy=nextTarget.x-b.x,nextTarget.y-b.y;local dist=math.sqrt(dx*dx+dy*dy)
                                b.dx,b.dy=dx/dist,dy/dist;b.target=nextTarget;b.ricochets=(b.ricochets or 0)+1
                            end
                        end
                    end
                end
            end
        end
        -- Finish the outbound collision first, including its endpoint. Each leg
        -- may hit a target once; the return must not inherit outbound immunity.
        if turning and not remove then b.phase="back";b.hitSet={} end
    end
    if level <= 0 then return end
    self.boomerangTimer = (self.boomerangTimer or 0) - dt
    if self.boomerangTimer > 0 then return end
    local growth=self:growth("boomerang_axe")
    local branch=self:skillBranch("boomerang_axe")
    local branchCooldown=branch=="rapid_return" and .65 or 1
    self.boomerangTimer = (5.4-growth*4.2)*self:autoSkillCooldown("boomerang_axe")*branchCooldown
    local target,bestD2=nil,math.huge
    for _,enemy in ipairs(self.enemies)do
        if enemy.hp and enemy.hp>0 then local dx,dy=enemy.x-game.player.x,enemy.y-game.player.y;local d2=dx*dx+dy*dy;if d2<bestD2 then target,bestD2=enemy,d2 end end
    end
    if not target then self.boomerangTimer=.15;return end
    local atan2=math.atan2 or math.atan
    local a=atan2(target.y-game.player.y,target.x-game.player.x)
    local area=self:skillArea("boomerang_axe")*(branch=="broad_axe" and 1.45 or 1)
    local damage=self:skillDamage("boomerang_axe")*(branch=="broad_axe" and 1.18 or 1)
    local speed=480*(branch=="rapid_return" and 1.55 or 1)
    self.boomerangs[#self.boomerangs+1] = {
        x=game.player.x, y=game.player.y, dx=math.cos(a), dy=math.sin(a),
        traveled=0,maxDist=(200+growth*244)*2,phase="out",hitSet={},dmg=(.75+growth*13.45)*damage,
        radius=(64+growth*24)*area,angle=a,target=target,speed=speed,branch=branch,ricochets=0
    }
end

function ClearcutMode:updateSeedMine(dt, game)
    local level = self:levelOf("seed_mine")
    self.seeds = self.seeds or {}
    self.sproutFields=self.sproutFields or {}
    for i=#self.sproutFields,1,-1 do
        local field=self.sproutFields[i];field.life=field.life-dt;field.timer=field.timer-dt
        if field.timer<=0 then
            field.timer=.62
            for _,node in ipairs(game.world.nodes)do
                if node.rushTree and node.active then local dx,dy=node.x-field.x,node.y-field.y
                    if dx*dx+dy*dy<=field.radius*field.radius then
                        node.rushHp=(node.rushHp or node.rushMaxHp)-field.dmg;game.world:impactNode(node,game,false)
                        if node.rushHp<=0 then self:fellTree(node,game)end
                    end
                end
            end
            self:damageEnemiesInRadius(field.x,field.y,field.radius,field.dmg,game)
        end
        if field.life<=0 then table.remove(self.sproutFields,i)end
    end
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
            if s.branch=="scatter_mine" and not s.mini then
                for n=1,6 do local a=(n-1)/6*math.pi*2
                    self.seeds[#self.seeds+1]={x=s.x+math.cos(a)*58,y=s.y+math.sin(a)*42,
                        fuse=.24+n*.035,maxFuse=.45,radius=radius*.42,dmg=s.dmg*.38,mini=true}
                end
            elseif s.branch=="sprout_mine" and not s.mini then
                self.sproutFields[#self.sproutFields+1]={x=s.x,y=s.y,radius=radius*.58,dmg=s.dmg*.22,
                    life=4,maxLife=4,timer=.08}
            end
            table.remove(self.seeds, i)
        end
    end
    if level <= 0 then return end
    self.seedTimer = (self.seedTimer or 0) - dt
    if self.seedTimer > 0 then return end
    local growth=self:growth("seed_mine")
    self.seedTimer = (6.4-growth*4.8)*self:autoSkillCooldown("seed_mine")
    local target,bestD2=nil,math.huge
    for _,enemy in ipairs(self.enemies)do
        if enemy.hp and enemy.hp>0 then local dx,dy=enemy.x-game.player.x,enemy.y-game.player.y;local d2=dx*dx+dy*dy;if d2<bestD2 then target,bestD2=enemy,d2 end end
    end
    if not target then self.seedTimer=.15;return end
    local atan2=math.atan2 or math.atan
    local a=atan2(target.y-game.player.y,target.x-game.player.x)
    local r=math.min(160,math.sqrt(bestD2))
    local branch=self:skillBranch("seed_mine")
    local radius=(110+growth*185)*self:skillArea("seed_mine")*(branch=="heavy_mine" and 1.42 or 1)
    local damage=(1+growth*19.8)*self:skillDamage("seed_mine")*(branch=="heavy_mine" and 1.35 or 1)
    self.seeds[#self.seeds+1] = {
        x=game.player.x + math.cos(a) * r, y=game.player.y + math.sin(a) * r,
        fuse=1.1,maxFuse=1.1,radius=radius,dmg=damage,target=target,branch=branch
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
    self.lightningTimer = (self.lightningTimer or 0) - dt
    if self.lightningTimer > 0 then return end
    local growth=self:growth("chain_lightning")
    self.lightningTimer = (7-growth*5.2)*self:autoSkillCooldown("chain_lightning")
    local jumps = 2+math.floor(growth*5+.0001)
    local hopRange = 260
    local dmg = (.8+growth*13.4)*self:skillDamage("chain_lightning")
    local visited = {}
    local cx, cy = game.player.x, game.player.y
    local points = {{x=cx, y=cy}}
    for _ = 1, jumps do
        -- 매 점프마다 몬스터를 먼저 찾는다: 사거리 안에 아직 안 맞은 적이 있으면
        -- 나무는 후보에서 빠진다 (적이 소진돼야 비로소 나무로 넘어간다).
        local target, bestD2 = nil, hopRange * hopRange
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
            local previousX,previousY=d.x,d.y
            d.x,d.y=d.x+d.vx*dt,d.y+d.vy*dt
            d.life=d.life-dt
            if d.life<=0 then table.remove(self.digits,i) else
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active and not d.hitSet[node] then
                    if CombatGeometry.segmentDistanceSquared(node.x,node.y,previousX,previousY,d.x,d.y)<=18*18 then
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
                    if CombatGeometry.sweptCircleOverlapsTarget(previousX,previousY,d.x,d.y,18,e) then
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
        local previousX,previousY=p.x,p.y
        p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
        p.life = p.life - dt
        local hit = false
        if p.life <= 0 then
            table.remove(self.packets, i)
        else
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active then
                    if CombatGeometry.segmentDistanceSquared(node.x,node.y,previousX,previousY,p.x,p.y)<=14*14 then
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
                    if CombatGeometry.sweptCircleOverlapsTarget(previousX,previousY,p.x,p.y,14,e) then
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

-- 철학자 전용 SPACE 액션: 부흥회 개최. 광신도들이 잠깐 나타났다 사라지고, 그 몇 초 동안
-- "끝없는 설교"가 강화된다 — 침 게이지 소모 없이, 항상 최대 장광설(verbosity=1) 상태로,
-- 데미지도 크게 오른다. 새 자원을 만들지 않고 기존 설교 시스템 위에 얹는 버프형 스킬이다.
function ClearcutMode:activateRevival(game)
    if self.job ~= "philosopher" or self.dead then return false end
    if self.revivalCooldown > 0 then
        game:setNotice(string.format("부흥회 재개최 %.1f초", self.revivalCooldown), "food")
        return false
    end
    local power = self:power("revival_meeting")
    self.revivalCooldown = math.max(12, 20 - power * 1.5)
    self.revivalTimer = 6 + power
    self.revivalCenterX,self.revivalCenterY=game.player.x,game.player.y
    RevivalCrowdArt.start(self,game)
    self.revivalChorusTimer=0
    self.revivalChorusImpacts[#self.revivalChorusImpacts+1]={x=game.player.x,y=game.player.y,radius=72,age=0,life=.52,opening=true}
    game:setNotice("부흥회 개최 — 광신도들이 응답한다", "food")
    return true
end

function ClearcutMode:updateRevival(dt, game)
    self.revivalCooldown = math.max(0, self.revivalCooldown - dt)
    self.revivalTimer = math.max(0, self.revivalTimer - dt)
    PhilosopherArt.update(self,dt)
    RevivalCrowdArt.update(self,dt)
    self:updateEternalFields(dt,game)
    self:updateRevivalChorus(dt,game)
end

function ClearcutMode:spawnEternalField(x,y,game)
    local radius=(self.aimRadius or 60)*1.8
    self.eternalFields[#self.eternalFields+1]={x=x,y=y,radius=radius,age=0,life=7+self.permanentTraits.plagueDuration,tickTimer=0,
        damage=.7+self:power("monologue")*.22+self.permanentTraits.biteDamage*.16}
    if #self.eternalFields>3 then table.remove(self.eternalFields,1) end
    if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.22) end
end

function ClearcutMode:tickEternalField(field,game)
    local radius2=field.radius*field.radius
    local poisonDuration=math.max(1.4,2.2+self.permanentTraits.plagueDuration)
    for _,node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx,dy=node.x-field.x,node.y-field.y
            if dx*dx+dy*dy<=radius2 then
                node.rushHp=(node.rushHp or node.rushMaxHp)-field.damage
                self:markPhilosopherPlague("tree",node,poisonDuration,1)
                if node.rushHp<=0 then self:fellTree(node,game) end
            end
        end
    end
    for _,enemy in ipairs(self.enemies) do
        if enemy.hp>0 then
            if CombatGeometry.circleOverlapsTarget(field.x,field.y,field.radius,enemy) then
                self:markPhilosopherPlague("enemy",enemy,poisonDuration,2)
            end
        end
    end
    self:damageEnemiesInRadius(field.x,field.y,field.radius,field.damage*2.2,game)
end

function ClearcutMode:updateEternalFields(dt,game)
    for i=#self.eternalFields,1,-1 do
        local field=self.eternalFields[i]
        field.age=field.age+dt;field.life=field.life-dt;field.tickTimer=field.tickTimer-dt
        if field.tickTimer<=0 then field.tickTimer=math.max(.34, .5-self:power("footnote")*.025);self:tickEternalField(field,game) end
        if field.life<=0 then table.remove(self.eternalFields,i) end
    end
end

function ClearcutMode:spawnRevivalChorus(game)
    local crowd=self.revivalCrowd
    if not crowd or not crowd.people or #crowd.people==0 then return end
    local candidates={}
    local px,py=game.player.x,game.player.y
    for _,node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local d=(node.x-px)^2+(node.y-py)^2
            if d<=760*760 then candidates[#candidates+1]={kind="tree",ref=node,x=node.x,y=node.y,d=d} end
        end
    end
    for _,enemy in ipairs(self.enemies) do
        if enemy.hp>0 then
            local d=(enemy.x-px)^2+(enemy.y-py)^2
            if d<=760*760 then candidates[#candidates+1]={kind="enemy",ref=enemy,x=enemy.x,y=enemy.y,d=d} end
        end
    end
    table.sort(candidates,function(a,b)return a.d<b.d end)
    local count=math.min(3,#candidates)
    for i=1,count do
        self.revivalChorusSequence=self.revivalChorusSequence+1
        local person=crowd.people[(self.revivalChorusSequence-1)%#crowd.people+1]
        local target=candidates[i]
        local sx,sy=person.x,person.y-54
        local distance=math.sqrt((target.x-sx)^2+(target.y-sy)^2)
        local duration=math.max(.28,math.min(.72,distance/720))
        person.chorusTimer=duration+.18;person.chorusTargetX=target.x
        self.revivalChorusShots[#self.revivalChorusShots+1]={sx=sx,sy=sy,tx=target.x,ty=target.y,t=0,dur=duration,radius=56}
    end
end

function ClearcutMode:resolveRevivalChorus(shot,game)
    local damage=2.5+self:power("monologue")*.65+self:power("revival_meeting")*.45
    local r2=shot.radius*shot.radius
    for _,node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx,dy=node.x-shot.tx,node.y-shot.ty
            if dx*dx+dy*dy<=r2 then
                node.rushHp=(node.rushHp or node.rushMaxHp)-damage
                game.world:impactNode(node,game,true)
                if node.rushHp<=0 then self:fellTree(node,game) end
            end
        end
    end
    self:damageEnemiesInRadius(shot.tx,shot.ty,shot.radius,damage*2.3,game)
    self.revivalChorusImpacts[#self.revivalChorusImpacts+1]={x=shot.tx,y=shot.ty,radius=shot.radius,age=0,life=.48}
end

function ClearcutMode:updateRevivalChorus(dt,game)
    -- Age already-visible impacts first. Impacts created by shots below must survive
    -- at least one rendered frame even when a long frame exceeds their whole lifetime.
    for i=#self.revivalChorusImpacts,1,-1 do
        local impact=self.revivalChorusImpacts[i];impact.age=impact.age+dt
        if impact.age>=impact.life then table.remove(self.revivalChorusImpacts,i) end
    end
    if self.evolutions.revival_chorus and self.revivalTimer>0 then
        self.revivalChorusTimer=self.revivalChorusTimer-dt
        if self.revivalChorusTimer<=0 then
            self.revivalChorusTimer=math.max(.48,.86-self:power("revival_meeting")*.055)
            self:spawnRevivalChorus(game)
        end
    end
    for i=#self.revivalChorusShots,1,-1 do
        local shot=self.revivalChorusShots[i];shot.t=shot.t+dt
        if shot.t>=shot.dur then self:resolveRevivalChorus(shot,game);table.remove(self.revivalChorusShots,i) end
    end
end

-- 기본공격 "끝없는 설교": 누르고 있는 동안 침을 계속 쏘지만, 침 게이지가 계속 줄어든다.
-- 게이지가 바닥나면 강제로 채널링이 끊기고(exhausted), 25%까지 회복해야 다시 쏠 수 있다
-- — 딱 0을 스쳐 지나가며 쏘다 멈추다를 반복하는 깜빡임을 막기 위한 히스테리시스.
function ClearcutMode:updatePhilosopherAttack(dt, game, heldOverride)
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    if self.salivaExhausted and self.salivaGauge >= self.salivaGaugeMax * .25 then
        self.salivaExhausted = false
    end
    local firing = held and not self.salivaExhausted and self.salivaGauge > 0
    local maxRange = 200 + self:power("monologue") * 30 + self:power("loud_voice") * 30 + self.permanentTraits.range
    local tx, ty = self:aimPoint(game, maxRange)
    game.player.facing = tx < game.player.x and -1 or 1
    if firing then
        self.rantTimer = math.min(3, (self.rantTimer or 0) + dt)
    else
        self.rantTimer = math.max(0, (self.rantTimer or 0) - dt * 2)
    end
    local verbosity = self.revivalTimer > 0 and 1 or math.min(1, (self.rantTimer or 0) / 3)
    self.aimX, self.aimY = tx, ty
    local revivalSpread = self.revivalTimer > 0 and 1.5 or 1
    self.aimRadius = ((55 + self:power("monologue") * 10 + self:power("loud_voice") * 20) * (1 + verbosity * .55) + self.permanentTraits.area) * revivalSpread
    PhilosopherArt.channel(self,game,firing,tx,ty,verbosity,self.revivalTimer > 0)
    if game.player.setClearcutAction then game.player:setClearcutAction(.08 + ((self.rantTimer or 0) * 2.4 % 1) * .9) end
    local wasHeld = self.rantHeldLast
    self.rantHeldLast = firing
    if not firing then
        self.salivaGauge = math.min(self.salivaGaugeMax, self.salivaGauge + self.salivaRegenRate * dt)
        if wasHeld and verbosity >= .999 and self.evolutions.eternal_return then
            self:spawnEternalField(self.aimX, self.aimY, game)
        end
        if game.player.clearClearcutAction then game.player:clearClearcutAction() end
        return false
    end
    if self.revivalTimer <= 0 then
        self.salivaGauge = math.max(0, self.salivaGauge - self.salivaDrainRate * dt)
        if self.salivaGauge <= 0 then
            self.salivaExhausted = true
            game:setNotice("설교에 지쳤다 — 침이 마름", "food")
        end
    end
    self.spitTimer = (self.spitTimer or 0) - dt
    if self.spitTimer > 0 then return false end
    local rate = math.max(.14, (.5 - self:power("footnote") * .1 - verbosity * .2) / self.permanentTraits.attackSpeed)
    self.spitTimer = rate
    self.streak, self.lastHitAt = self.streak + 1, self.elapsed
    self:applySpit(tx, ty, verbosity, game)
    return true
end

function ClearcutMode:applySpit(tx, ty, verbosity, game, isBonus, isExtra)
    local radius = (self.aimRadius or 60) * (isBonus and 1.8 or 1)
    local revivalMul = (self.revivalTimer or 0) > 0 and (1.8 + self:power("revival_meeting") * .2) or 1
    local dmg = (2 + self:power("monologue") + verbosity * 2 + self.permanentTraits.biteDamage) * revivalMul
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
            if CombatGeometry.circleOverlapsTarget(tx,ty,radius,e) and not e.plagueMarked then
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
    self.streak, self.lastHitAt = self.streak + 1, self.elapsed
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
    if game.camera then
        game.camera.trauma=math.min(1,game.camera.trauma+.2)
        if game.camera.impulse then game.camera:impulse(-dx/dist*75,-dy/dist*38,(dx<0 and .032 or -.032),.028) end
    end
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
    -- 소수 수목으로 시작하는 기록 모드는 일반 작전보다 파괴율이 훨씬 빠르게 오른다.
    -- 일반 스테이지용 25/50/75% 웨이브를 실행하면 초반 몬스터가 한꺼번에
    -- 쏟아지므로 기록전에서는 파괴율 마일스톤 전체를 사용하지 않는다.
    if self.scoreAttack then return end
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
    if self.scoreAttack then
        self.scoreWoodEarned=(self.scoreWoodEarned or 0)+amount
        -- 과거 저장/테스트에서 남은 대기열까지 매 획득 시 정리해, 대량 목재가
        -- 들어와도 선택 창이 연속으로 다시 열리지 않게 한다.
        self.xp,self.pending=0,0
        self.choices,self.choiceBoxes={},{}
        return
    end
    self.xp = self.xp + amount
    while self.xp >= self.xpNext do
        self.xp = self.xp - self.xpNext
        self.level, self.pending = self.level + 1, self.pending + 1
        self.xpNext = math.floor(10+(self.level-1)*6.5)
    end
    if self.pending > 0 and game.mode == "playing" and not self.sandbox and not os.getenv("LAST_HAUL_SELF_TEST") then self:openUpgradeChoices(game) end
end

function ClearcutMode:upgradePool()
    -- 활성 벌목 기록 모드의 성장은 로비 영구 연구 하나로 통합했다. 정의는 일반
    -- 작전·샌드박스 복구를 위해 보존하지만 기록 모드 후보 풀에는 넣지 않는다.
    if self.scoreAttack then return {} end
    local pool = {}
    for _, def in ipairs(definitions) do
        -- 기록 모드는 위에서 빈 풀로 끝난다. 아래 분류는 일반 작전·샌드박스 복구용
        -- 정의를 삭제하지 않기 위해 보존한다.
        local jobOk = self.scoreAttack and def.scoreOperation==true or((not self.scoreAttack)and((def.job ~= nil and self.job ~= nil and def.job == self.job)or def.sharedDraft==true))
        local modeOk = not def.scoreOnly or self.scoreAttack
        if jobOk and modeOk and not self.banished[def.id] and self:levelOf(def.id) < def.max then pool[#pool+1]=def end
    end
    return pool
end

function ClearcutMode:rollChoices()
    local pool = self:upgradePool()
    for i=#pool,2,-1 do local j=love.math.random(i); pool[i],pool[j]=pool[j],pool[i] end
    self.choices={}
    for i=1,math.min(3,#pool) do self.choices[i]=pool[i] end
    if #self.choices==0 and not self.scoreAttack then self.choices[1]=recoveryChoice end
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
    if self.scoreAttack then
        self.xp,self.pending=0,0
        self.choices,self.choiceBoxes={},{}
        self.specialCard,self.fusionChoice,self.branchChoiceSkill=nil,nil,nil
        self.selectionKind="upgrade"
        game.mode="playing"
        return false
    end
    if not self.scoreAttack and self:checkEvolutions(game) then return end
    self.rerollCount, self.banishArmed, self.selectionKind = 0, false, "upgrade"
    self:rollChoices()
    if self.scoreAttack and #self.choices==0 then
        self.pending=0
        self.specialCard=nil
        self.choiceBoxes={}
        game.mode="playing"
        return false
    end
    self.specialCard = nil
    if not self.scoreAttack and love.math.random() < .12 and #self:arcanaPool() > 0 then
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
    if #self.choices==0 and not self.scoreAttack then self.choices[1]=recoveryChoice end
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
    if self.scoreAttack then return false end
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
    if not self.scoreAttack and self:checkEvolutions(game) then return true end
    if (self.fusionChestRewards or 0)>0 then
        self.fusionChestRewards=self.fusionChestRewards-1
        game.mode="playing"
        self:openChest(game)
        return true
    end
    if self.pending>0 then self:openUpgradeChoices(game) else game.mode="playing" end
    return true
end

function ClearcutMode:openBranchChoice(skill,game)
    if self.scoreAttack then
        self.branchChoiceSkill=nil;self.branchChoices={};self.pending=0
        game.mode="playing"
        return false
    end
    self.branchChoiceSkill=skill
    self.branchChoices=SkillBranches.forSkill(skill) or {}
    self.selectionKind="branch";self.specialCard=nil;self.banishArmed=false;self.choiceBoxes={}
    self.choicesRevealAt=love.timer.getTime();game.mode="clearcut_upgrade"
end

function ClearcutMode:chooseBranch(index,game)
    local def=self.branchChoices and self.branchChoices[index]
    if not def or def.skill~=self.branchChoiceSkill then return false end
    self.skillBranches[def.skill]=def.id
    if def.skill=="molotov" then
        self.smoking=nil;self.smokerWeaponCooldown=0;self.flameStream=nil
        if game.player.clearClearcutAction then game.player:clearClearcutAction()end
        self:applySmokerEvolution(game)
    end
    self.branchChoiceSkill=nil;self.branchChoices={};self.selectionKind="upgrade";self.choiceBoxes={}
    game:setNotice(def.name.." 선택 — "..def.desc,"ore")
    if self:checkEvolutions(game)then return true end
    if self.pending>0 then self:openUpgradeChoices(game)else game.mode="playing"end
    return true
end

function ClearcutMode:choose(index, game)
    if self.selectionKind == "fusion" then return self:chooseFusion(index,game) end
    if self.selectionKind == "branch" then return self:chooseBranch(index,game) end
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
        if self.scoreAttack and #self.choices==0 then
            self.pending=0
            self.choiceBoxes={}
            game.mode="playing"
        end
        return true
    end
    local wasChest=self.chestPending
    self.chestPending=false
    if def.recovery then self.hp=math.min(self.maxHp,self.hp+20)
    else
        self.levels[def.id]=self:levelOf(def.id)+1
        if self.scoreAttack and def.id=="yard_management"then self.scoreTreeAllowance=self.scoreTreeAllowance+1 end
    end
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
    if def.id=="molotov"then self:applySmokerEvolution(game)end
    local branchLevel=SkillBranches.triggerLevel(def.id)
    local branchReady=not def.recovery and branchLevel and self:levelOf(def.id)==branchLevel
        and not self:skillBranch(def.id) and SkillBranches.forSkill(def.id)
    self.choices={}
    self.choiceBoxes={}
    if branchReady then self:openBranchChoice(def.id,game);return true end
    if not self.scoreAttack and self:checkEvolutions(game) then return true end
    self.specialCard = nil
    if self.pending>0 then self:openUpgradeChoices(game) else game.mode="playing" end
    return true
end

function ClearcutMode:fellTree(node, game)
    if not node.active then return false end
    local wasBeehive = node.beehive
    node.active, node.respawn, node.rushHp = false, math.huge, 0
    -- 기본 수종보다 값나가는(=해금이 필요한) 수종은 더 많은 목재를 준다.
    local amount = (node.treeVariant and node.treeVariant > 1) and 6 or 4
    amount = math.floor(amount * (self.permanentTraits.woodYield or 1) + .5)
    game.world:harvestBurst(node, game, amount, "목재")
    game.world:spawnDrop("wood", amount, node.x, node.y - 10, 42, 30, 1.5)
    self.treesFelled = self.treesFelled + 1
    local lumber=WoodEconomy.forTree(self.mapId,node.treeVariant or 1)
    self.lumberInventory=self.lumberInventory or{}
    self.lumberInventory[lumber.id]=(self.lumberInventory[lumber.id]or 0)+1
    if self.scoreAttack then
        self.scoreFellTimes=self.scoreFellTimes or{}
        self.scoreFellTimes[#self.scoreFellTimes+1]=self.stageElapsed or self.elapsed or 0
        self:scoreProductionRate()
    end
    if game.achievements then game.achievements:recordTree(self.mapId,node.treeVariant or 1,self.job) end
    self.remainingTrees = math.max(0, self.remainingTrees - 1)
    if node.forestZone then
        local secured=ForestZones.refresh(self,node.forestZone)
        if secured then game:setNotice(secured.name.." 제압 완료 — 이 구역은 다시 자라지 않는다","food") end
    end
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
    -- The first card establishes multi-hit without handing out the old
    -- three-target clear immediately. Extra targets accelerate mainly at 4..6.
    local wideTargets=wideLevel>0 and math.max(1,math.floor(widePower*1.25)) or 0
    local targetCount = 1 + wideTargets + math.floor(self.permanentTraits.extraTargets)
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
    local baseReward
    if self.scoreAttack then
        local tierGain=math.max(0,(self.scoreHighestRegenTier or self.scoreRegenTier or 1)-(self.scoreStartingRegenTier or 1))
        baseReward=(self.scoreStartingRegenTier or 1)*3+math.min(20,math.floor(self.treesFelled/8))+tierGain*10
    else baseReward=math.floor(self.treesFelled/5)+self.kills*2+math.floor(self.level*1.5)+(victory and 30 or 0)end
    local traitReward = math.max(1, math.floor(baseReward * (self.permanentTraits.reward or 1) + .5))
    local lumberRows,lumberCoinTotal
    if self.scoreAttack then
        lumberRows,lumberCoinTotal=WoodEconomy.settlement(self.mapId,self.lumberInventory)
        -- Results from older fixtures/runs still settle instead of opening an empty panel.
        if #lumberRows==0 and self.treesFelled>0 then
            local fallback=WoodEconomy.forTree(self.mapId,1)
            self.lumberInventory={[fallback.id]=self.treesFelled}
            lumberRows,lumberCoinTotal=WoodEconomy.settlement(self.mapId,self.lumberInventory)
        end
        traitReward=0
    elseif game.characterTraits then game.characterTraits:addCurrency(traitReward) end
    local zonesSecured,zonesTotal=ForestZones.status(self)
    game.result={elapsed=math.floor(self.elapsed),wood=self.scoreAttack and math.floor(self.scoreWoodEarned or 0)or self.totalWood,woodBalance=math.floor(self.totalWood),trees=self.treesFelled,total=self.initialTrees,maxMulti=self.maxMulti,maxChain=self.maxChain,level=self.level,stage=self.stage,stageCode=Maps.stageCode(self.mapId,self.stage),regrowPulses=self.regrowPulses,treesRevived=self.treesRevived,rootedCount=self.rootedCount,beeSwarms=self.beeSwarmsTriggered,victory=victory,kills=self.kills,zonesSecured=zonesSecured,zonesTotal=zonesTotal,traitEarned=traitReward,traitCurrency=game.characterTraits and game.characterTraits.data.currency or traitReward,mapId=self.mapId,operationName=BiomeBosses.operationName(self.mapId),bossName=self.operationBossName,failureReason=self.failureReason,scoreAttack=self.scoreAttack,totalTreesSpawned=self.totalTreesSpawned,peakActiveTrees=self.peakActiveTrees,treeAllowance=self.scoreTreeAllowance,treeSpawnRate=self:scoreTreeSpawnRate(),peakTreesPerSecond=self.peakTreesPerSecond or 0,regenTier=self.scoreRegenTier,startingRegenTier=self.scoreStartingRegenTier,highestRegenTier=self.scoreHighestRegenTier,lumberRows=lumberRows,lumberCoinTotal=lumberCoinTotal or traitReward}
    if self.scoreAttack then
        local settlementUnits=0
        for _,row in ipairs(lumberRows or{})do settlementUnits=settlementUnits+(row.remaining or 0)end
        self.resultSettlement={rows=lumberRows or{},rowIndex=1,accumulator=0,rowPause=.32,elapsed=0,converted=0,total=lumberCoinTotal or 0,
            unitTotal=settlementUnits,batchSize=math.max(1,math.ceil(settlementUnits/90)),bursts={},saveCounter=0,complete=(lumberCoinTotal or 0)==0}
    end
    if game.achievements then game.achievements:recordRun(game.result) end
    game.mode="clearcut_results"
end

function ClearcutMode:updateResults(dt,game)
    local s=self.resultSettlement
    if not s or not game.result then return end
    -- Settlement completion stops currency conversion, not the presentation clock.
    -- Keeping this clock alive prevents the bank coin and any final transfer burst
    -- from freezing on an arbitrary frame and looking like a stalled result screen.
    s.elapsed=s.elapsed+dt
    for i=#s.bursts,1,-1 do local b=s.bursts[i];b.t=b.t+dt;if b.t>=b.dur then table.remove(s.bursts,i)end end
    if s.complete then return end
    if s.rowPause>0 then s.rowPause=math.max(0,s.rowPause-dt);return end
    local row=s.rows[s.rowIndex]
    if not row then s.complete=true;if game.characterTraits then game.characterTraits:save()end;return end
    local progress=s.total>0 and s.converted/s.total or 1
    local interval=math.max(.014,.032-progress*.018)
    s.accumulator=s.accumulator+dt
    local steps=0
    while s.accumulator>=interval and row.remaining>0 and steps<24 do
        s.accumulator=s.accumulator-interval;steps=steps+1
        local units=math.min(row.remaining,s.batchSize or 1)
        local coins=units*row.coin
        row.remaining=row.remaining-units;row.converted=row.converted+units
        s.converted=s.converted+coins
        game.result.traitEarned=(game.result.traitEarned or 0)+coins
        if game.characterTraits then game.characterTraits:addCurrency(coins,true);game.result.traitCurrency=game.characterTraits.data.currency end
        s.saveCounter=(s.saveCounter or 0)+units
        if s.saveCounter>=12 and game.characterTraits then game.characterTraits:save();s.saveCounter=0 end
        s.bursts[#s.bursts+1]={t=0,dur=.48,rowIndex=s.rowIndex,seed=(row.converted*17+s.rowIndex*31)%11}
        if #s.bursts>18 then table.remove(s.bursts,1)end
    end
    if row.remaining<=0 then if game.characterTraits then game.characterTraits:save();s.saveCounter=0 end;s.rowIndex=s.rowIndex+1;s.rowPause=.18;s.accumulator=0 end
end

function ClearcutMode:completeResultSettlement(game)
    local s=self.resultSettlement
    if not s or s.complete or not game.result then return end
    local add=0
    for _,row in ipairs(s.rows)do add=add+row.remaining*row.coin;row.converted=row.converted+row.remaining;row.remaining=0 end
    if add>0 and game.characterTraits then game.characterTraits:addCurrency(add,true)end
    game.result.traitEarned=(game.result.traitEarned or 0)+add
    game.result.traitCurrency=game.characterTraits and game.characterTraits.data.currency or(game.result.traitCurrency or 0)+add
    s.converted=s.total;s.rowIndex=#s.rows+1;s.complete=true
    if game.characterTraits then game.characterTraits:save()end
end

local function drawBeeBody(x, y, angle, wingPhase, scale)
    BeeArt.draw(x,y,angle,wingPhase,scale)
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
        drawBeeBody(bx, by, a + math.pi / 2, t * 30 + i,1.02)
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

    -- 움직이는 막대. 새 보루를 뜯는 중이면 색을 다르게 해서 평소 재장전과 구분한다.
    local barW = px * 3
    local barX = math.floor(x + charge * (w - barW))
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", barX - px, y - capH / 2 - px, barW + px * 2, capH + px * 2)
    if smoking.newCarton then love.graphics.setColor(1, .35, .32, 1) else love.graphics.setColor(1, .68, .26, 1) end
    love.graphics.rectangle("fill", barX, y - capH / 2, barW, capH)
end

-- 철학자 전용: "끝없는 설교"가 소모하는 침 게이지. 리로드 바와 달리 이건 잔량을 그대로
-- 보여주는 채움 막대(게이지) 형태 — 다 마시면 붉게 바뀌어 탈진 상태임을 알려준다.
function ClearcutMode:drawSalivaGauge(game)
    local ratio = math.max(0, math.min(1, self.salivaGauge / self.salivaGaugeMax))
    local w, px = 96, 2
    local x = math.floor(game.player.x - w / 2)
    local y = math.floor(game.player.y - 120)
    local capH = 8

    love.graphics.setColor(0, 0, 0, .4)
    love.graphics.rectangle("fill", x - px - 2, y - capH / 2 - 2, w + px * 2 + 4, capH + 4)

    -- 대괄호 [ ]
    love.graphics.setColor(1, 1, 1, .6)
    love.graphics.rectangle("fill", x - px, y - capH / 2, px, capH)
    love.graphics.rectangle("fill", x + w, y - capH / 2, px, capH)

    -- 빈 트랙
    love.graphics.setColor(1, 1, 1, .18)
    love.graphics.rectangle("fill", x, y - px / 2, w, px)

    -- 채워진 만큼(남은 침의 양)
    local fillW = math.floor(w * ratio)
    if fillW > 0 then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", x - px, y - capH / 2 - px, fillW + px * 2, capH + px * 2)
        if self.salivaExhausted then love.graphics.setColor(.75, .32, .3, 1) else love.graphics.setColor(.55, .85, .35, 1) end
        love.graphics.rectangle("fill", x, y - capH / 2, fillW, capH)
    end
end

function ClearcutMode:drawSmokerCigarette(game)
    if self.job~="fire" or not self.smoking or self.smoking.phase=="flick" then return false end
    local mouthX,mouthY,facing,tipX=self:smokerMouthPose(game)
    local sprite=game.player.clearcutSprite
    if sprite and sprite.walkMouth then
        if sprite.cigarette then
            Cigarette.draw(sprite.cigarette,mouthX,mouthY,facing,love.timer.getTime())
            return true
        end
    end
    -- 안전 폴백도 입 기준에서 끝까지 2px 텍셀로 직접 잇는다. 공용 그리드의
    -- +1px 이음새 확장은 작은 불씨를 뭉개므로 담배에는 적용하지 않는다.
    for i=0,11 do
        if i==11 then love.graphics.setColor(1,.48,.08,1)
        elseif i==10 then love.graphics.setColor(.42,.19,.08,1)
        elseif i<2 then love.graphics.setColor(.68,.49,.25,1)
        else love.graphics.setColor(.94,.92,.86,1) end
        love.graphics.rectangle("fill",math.floor(mouthX+facing*i*2+.5),math.floor(mouthY-3+.5),2,2)
    end
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
local cleanPlatePalette = {O={.16,.22,.05,1}, H={.85,.95,.6,1}, T={.4,.72,.22,1}}
local pileDrivingPalette = {O={.2,.14,.06,1}, H={.92,.85,.7,1}, T={.55,.4,.2,1}}
local forkPalette = {O={.08,.11,.12,1}, H={1,1,.86,1}, W={.72,.84,.86,1}, T={.52,.82,.24,1}, D={.34,.20,.42,1}}
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
local smokeRingPalette = {O={.22,.18,.05,1}, H={.95,.85,.6,1}, W={.85,.65,.25,1}}
local revivalMeetingPalette = {O={.24,.2,.04,1}, H={1,.95,.65,1}, W={.9,.8,.3,1}, D={.55,.45,.1,1}}
local forkRows = {
    "..O.O.O.O",
    "..W.W.W.W",
    "..WHWHWHW",
    "..OWWWWOO",
    "....WW...",
    "....WW...",
    "...TWWT..",
    "...TWWT..",
    "...DOOD..",
}
local strawBaleRows = {
    "..OOOOO..",
    ".OHYYYHO.",
    "OHYTYTYHO",
    "OHYYYYYHO",
    "OHYTYTYHO",
    "OHYYYYYHO",
    "OHYTYTYHO",
    ".OHHHHHO.",
    "..OOOOO..",
}
local strawBalePalette = {O={.2,.11,.025,1},H={.62,.34,.07,1},Y={.94,.68,.19,1},T={1,.87,.42,1}}

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
    straw_bale = {rows = strawBaleRows, palette = strawBalePalette},
    fork = {rows = forkRows, palette = forkPalette},
    fork_feast = {rows = forkRows, palette = forkPalette},
    buffet_fork = {rows = forkRows, palette = forkPalette},
    clean_plate = {rows = boxRows, palette = cleanPlatePalette},
    seconds_please = {rows = diamondRows, palette = forkPalette},
    pile_driving = {rows = stickRows, palette = pileDrivingPalette},
    heavy_machinery = {rows = heavyMachineryRows, palette = heavyMachineryPalette},
    demolition = {rows = diamondRows, palette = demolitionPalette},
    site_clearance = {rows = boxRows, palette = siteClearancePalette},
    smoke_ring = {rows = blobRows, palette = smokeRingPalette},
    pickaxe = {rows = pickaxeIconRows, palette = pickaxeIconPalette},
    detector = {rows = rootCuttingRows, palette = rootCuttingPalette},
    burrow_uproot = {rows = rootCuttingRows, palette = rootCuttingPalette},
    speech = {rows = speechIconRows, palette = speechIconPalette},
    monologue = {rows = speechIconRows, palette = speechIconPalette},
    footnote = {rows = stickRows, palette = footnotePalette},
    loud_voice = {rows = diamondRows, palette = loudVoicePalette},
    saliva_gland = {rows = blobRows, palette = salivaGlandPalette},
    revival_meeting = {rows = boxRows, palette = revivalMeetingPalette},
    bat_swarm = {rows = batIconRows, palette = batIconPalette},
    thorn_aura = {rows = thornIconRows, palette = thornIconPalette},
    crow_strike = {rows = crowIconRows, palette = crowIconPalette},
    vine_whip = {rows = vineIconRows, palette = vineIconPalette},
    boomerang_axe = {rows = axeIconRows, palette = boomerangAxePalette},
    seed_mine = {rows = seedIconRows, palette = seedIconPalette},
    chain_lightning = {rows = lightningIconRows, palette = lightningIconPalette},
    baby_robot = {rows = boxRows, palette = lightningIconPalette},
    brute_force = {rows = boxRows, palette = bruteForcePalette},
}
ClearcutMode.drawPixelGrid = drawPixelGrid

-- Threat markers remain above the canopy for combat readability; bodies do not.
local function drawEnemyThreat(e, t)
    BiomeEnemies.drawWarning(e)
    AttackPlants.drawWarning(e)
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
    elseif e.kind == "planter" then
        RegrowthCastArt.draw(e)
    end
    ForestArt.drawHealth(e,t)
end

-- Shared by the real world depth queue and headless renderer tests.
ClearcutMode.drawEnemy = ForestArt.drawBody
function ClearcutMode:queueWorldActors(queue,t)
    local groundTime=self.smokerGroundTime
    BossEntrance.queue(self,queue)
    PhilosopherFusionArt.queue(self,queue)
    RevivalCrowdArt.queue(self,queue)
    WorldTreeSiege.queue(self,queue)
    local moleActors=self.moleCompanions
    if not moleActors or #moleActors==0 then moleActors=self.moleCompanion and{self.moleCompanion}or{}end
    for _,value in ipairs(moleActors)do local companion=value
        queue[#queue+1]={x=companion.x,y=companion.y,anchorY=companion.y,sortBias=.002,
            draw=function()self:drawMoleCompanion(companion)end}
    end
    for _,value in ipairs(self.oilDrums or{})do local drum=value
        queue[#queue+1]={x=drum.x,y=drum.y,anchorY=drum.y,sortBias=.001,
            draw=function()ClearcutMode.GrayOilCatArt.drawDrum(drum)end}
    end
    for _,value in ipairs(self.scoreAxeImpacts or{})do local impact=value
        queue[#queue+1]={x=impact.x,y=impact.y+48,anchorY=impact.y+48,sortBias=.004,
            draw=function()ScoreAxeArt.drawImpact(impact)end}
    end
    for _,value in ipairs(self.oilDrumSpills or{})do local spill=value
        queue[#queue+1]={y=-100001+spill.y*.001,ground=true,
            draw=function()ClearcutMode.OilDrumSpillArt.drawGround(spill)end}
        if spill.ignited then
            queue[#queue+1]={x=spill.x,y=spill.y+.1,anchorY=spill.y,
                draw=function()ClearcutMode.OilDrumSpillArt.drawFire(spill)end}
        end
    end
    if self.grayOilCat then local cat=self.grayOilCat
        queue[#queue+1]={x=cat.x,y=cat.y,anchorY=cat.y,sortBias=.002,
            draw=function()ClearcutMode.GrayOilCatArt.drawCat(cat)end}
    end
    for _,value in ipairs(self.burrowTracks) do
        local mark=value
        queue[#queue+1]={y=-200000+mark.y*.001,ground=true,draw=function() MoleBurrowArt.draw(mark) end}
    end
    for _,value in ipairs(self.strawBales) do
        local bale=value
        queue[#queue+1]={x=bale.x,y=bale.y,draw=function() StrawBaleArt.draw(bale,groundTime) end}
    end
    for index,value in ipairs(self.oilTrail) do
        local spot=value
        -- Ground liquid is always behind actors; flame/smoke participates in
        -- the regular quarter-view foot-depth order.
        if not spot.hiddenGround then
            queue[#queue+1]={y=-100000+spot.y*.001,ground=true,draw=function() OilTrailArt.drawGround(spot,groundTime) end}
        end
        if spot.ignited and not spot.hiddenGround then
            queue[#queue+1]={x=spot.x,y=spot.y+.1,anchorY=spot.y,draw=function() OilTrailArt.drawFlame(spot,groundTime) end}
        end
        local previous=self.oilTrail[index-1]
        local sameGroup=previous and((not previous.group and not spot.group)or previous.group==spot.group)
        if sameGroup and not(previous.hiddenGround or spot.hiddenGround)then
            queue[#queue+1]={y=-99999+math.min(previous.y,spot.y)*.001,ground=true,draw=function() OilTrailArt.drawGroundBridge(previous,spot,groundTime) end}
            if previous.ignited and spot.ignited then
                queue[#queue+1]={x=(previous.x+spot.x)*.5,y=(previous.y+spot.y)*.5+.1,anchorY=(previous.y+spot.y)*.5,draw=function() OilTrailArt.drawFlameBridge(previous,spot,groundTime) end}
            end
        end
    end
    for _,value in ipairs(self.cigaretteButts) do
        local butt=value
        queue[#queue+1]={y=butt.y+3,ground=true,draw=function() CigaretteButtArt.drawGround(butt,groundTime) end}
    end
    for _, value in ipairs(self.enemies) do
        local enemy=value
        queue[#queue+1]={x=enemy.x,y=ForestArt.footY(enemy),anchorY=enemy.y,sortBias=.001,draw=function() ForestArt.drawBody(enemy,t) end}
        if enemy.burning then
            queue[#queue+1]={x=enemy.x,y=ForestArt.footY(enemy)+.1,anchorY=enemy.y,
                draw=function() CigaretteButtArt.drawEnemyFire(enemy,groundTime) end}
        end
    end
    for _, value in ipairs(self.vineSpawns) do
        local sprout=value
        local grow=1-math.max(0,sprout.timer)/1.15
        if grow>.3 then
            local growth=math.min(1,(grow-.3)/.7)
            queue[#queue+1]={x=sprout.x,y=sprout.y,draw=function() ForestArt.drawSprout(sprout.x,sprout.y,growth,t) end}
        end
    end
end

function ClearcutMode:drawCigaretteTreeFire(node)
    CigaretteButtArt.drawTreeFire(node,self.smokerGroundTime)
end

function ClearcutMode:drawCigaretteGroundEffects()
    local t=self.smokerGroundTime
    for _,impact in ipairs(self.cigaretteLandingImpacts or {}) do CigaretteButtArt.drawLandingImpact(impact,t) end
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
    BruteForceArt.draw(self,game,t)
    PhilosopherArt.draw(self)
    PhilosopherFusionArt.draw(self)
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

function ClearcutMode:drawHeldSmoker(game,t)
    SmokeRingArt.drawCharge(self,game,t)
    if self.scoreAttack and self:scoreWeaponId()=="axe"then
        return
    end
    -- 화염방사기는 담배를 입에 물지 않는다. 재장전 바와 꽁초 그리기로 떨어지면
    -- 손에 없는 담배가 화면에 남는다.
    if self.scoreAttack and self:scoreWeaponId()=="flamethrower"then
        FlamethrowerArt.drawHeld(self,game,t);return
    end
    if SmokerWeaponArt.drawHeld(self,game,t)then return end
    local smoking=self.smoking
    if not smoking or smoking.phase=="flick" then return end
    self:drawSmokerReloadBar(game);self:drawSmokerCigarette(game)
    local _,mouthY,facing,tipX=self:smokerMouthPose(game)
    local progress=smoking.phase=="loaded" and 1 or math.min(1,smoking.t/smoking.dur)
    local breath=smoking.phase=="loaded" and .58 or (.55+math.sin(progress*math.pi)*.45)
    local equipment=game.player.clearcutSprite and game.player.clearcutSprite.cigarette
    if equipment then Cigarette.drawSmoke(equipment,tipX,mouthY,facing,t);return end
    for i=0,13 do
        local rise=i*3;local drift=math.sin(t*1.65-i*.34)*i*.26+facing*i*.16
        love.graphics.setColor(.78,.79,.75,(.30-i*.018)*breath)
        love.graphics.rectangle("fill",math.floor(tipX+drift+.5),math.floor(mouthY-rise-2),2,2)
    end
end

local function queueUpright(queue,x,y,draw,sortY,anchorY)
    queue[#queue+1]={x=x,y=y,anchorY=anchorY or y,sortBias=(sortY and sortY-y or 0),draw=draw}
end

function ClearcutMode:queueProjectedOverlay(game,t)
    local queue=game.world.billboardQueue;if not queue then return end
    local player=game.player
    queueUpright(queue,player.x,player.y,function()
        local px,py=player.x+14,player.y-34
        if self.job=="fire" then self:drawHeldSmoker(game,t)
        elseif self.job=="toxic" then VeganForkArt.drawFork(self,game)
        elseif self.job=="physical" then drawPixelGrid(axeIconRows,axeIconPalette,px,py,2.2)
        elseif self.job=="developer" then drawPixelGrid(hardhatIconRows,hardhatIconPalette,px,py,2.4);self:drawDeveloperMachinery(game,t)
        elseif self.job=="philosopher" then
            drawPixelGrid(speechIconRows,speechIconPalette,px+math.sin(t*9)*1.5,py,2.2);self:drawSalivaGauge(game)
        end
        if self.rootedTimer>0 then
            for i=1,3 do love.graphics.setLineWidth(3);love.graphics.setColor(.26,.48,.13,.75-i*.12);love.graphics.ellipse("line",player.x,player.y+10-i*2,17-i*3,7-i) end
            for i=1,4 do
                local a=i/4*math.pi*2+t*2.4;local lx,ly=player.x+math.cos(a)*15,player.y+9+math.sin(a)*6
                love.graphics.push();love.graphics.translate(lx,ly);love.graphics.rotate(a)
                love.graphics.setColor(.36,.64,.2,.85);love.graphics.ellipse("fill",0,0,4.2,2)
                love.graphics.setColor(.16,.3,.07,.9);love.graphics.setLineWidth(.8);love.graphics.ellipse("line",0,0,4.2,2)
                love.graphics.setColor(.22,.42,.1,.9);love.graphics.setLineWidth(1);love.graphics.line(-3.5,0,3.5,0);love.graphics.pop()
            end
        end
        if self.invulnTimer>0 then love.graphics.setColor(1,.2,.15,.35);love.graphics.circle("fill",player.x,player.y-20,26) end
    end,player.y+.04,player.y)

    if self.job=="toxic" then VeganForkArt.queueFx(self,game,queue) end
    queueUpright(queue,player.x,player.y,function()
        SupplementArt.drawUpright(self,game,t);self.traitFx:draw()
    end,player.y+.02,player.y)
    local smokeRing=self.smokeRing
    if smokeRing then
        -- Moving smoke is an aerial billboard. Its centre follows the world
        -- projection, but its X/Y scale stays uniform instead of inheriting
        -- the tilted ground canvas.
        queueUpright(queue,smokeRing.x,smokeRing.y,function()self:drawSmokeRing(t)end,smokeRing.y+.035,smokeRing.y)
    end
    BruteForceArt.queue(self,queue,t)
    MoleClawArt.queue(self,queue,game.camera)
    local groundTime=self.smokerGroundTime
    for _,value in ipairs(self.cigaretteLandingImpacts or {}) do local impact=value
        queueUpright(queue,impact.x,impact.y,function()CigaretteButtArt.drawLandingImpact(impact,groundTime)end)
    end
    for _,value in ipairs(self.cigaretteButts) do local butt=value
        queueUpright(queue,butt.x,butt.y,function()CigaretteButtArt.drawSmolder(butt,groundTime)end)
    end
    for _,value in ipairs(self.emberTransfers) do local transfer=value
        queueUpright(queue,(transfer.x+transfer.tx)*.5,(transfer.y+transfer.ty)*.5,function()CigaretteButtArt.drawTransfer(transfer,groundTime)end)
    end
    for _,value in ipairs(self.emberArrivals) do local arrival=value
        queueUpright(queue,arrival.x,arrival.y,function()CigaretteButtArt.drawArrival(arrival,groundTime)end)
    end
    for _,value in ipairs(self.treeSparks) do local spark=value
        queueUpright(queue,(spark.x+spark.tx)*.5,(spark.y+spark.ty)*.5,function()CigaretteButtArt.drawTransfer(spark,groundTime)end)
    end
    for _,value in ipairs(self.treeSparkArrivals) do local arrival=value
        queueUpright(queue,arrival.x,arrival.y,function()CigaretteButtArt.drawArrival(arrival,groundTime)end)
    end

    for _,value in ipairs(self.thrownTrees) do local tree=value
        queueUpright(queue,tree.x,tree.y,function()
            local variants=(game.world.images and game.world.images.treeVariants)or{};local image=variants[math.max(1,math.min(#variants,tree.variant or 1))]
            if image then local height=math.max(0,tree.z or 0);love.graphics.setColor(1,1,1,1);love.graphics.draw(image,tree.x,tree.y-height,tree.angle or 0,.82,.82,image:getWidth()/2,image:getHeight()*.91) end
        end)
    end
    for _,value in ipairs(self.molotovs) do local flight=value;local x,y=CigaretteButts.flightPosition(flight)
        queueUpright(queue,x,y,function()CigaretteButtArt.drawFlight(flight,self.smokerGroundTime)end)
    end
    -- 화염방사기는 투사체가 없는 지속 무기다. 화염 기둥 판정과 같은 굵기·거리로 그려
    -- 보이는 불길과 실제로 타는 범위가 어긋나지 않게 한다.
    if self.flameStream then
        local stream=self.flameStream
        queueUpright(queue,stream.x+stream.nx*stream.reach*.5,stream.y+stream.ny*stream.reach*.5,
            function()FlamethrowerArt.drawStream(stream)end)
    end
    for _,value in ipairs(self.smokerWeaponProjectiles or {})do local projectile=value
        -- 삼단 대단원의 `firework_echo`는 착탄 지점만 들고 시간을 세는 예약 항목이라
        -- 그릴 좌표(x,y)가 없다. 그리는 목록에 넣으면 빌보드 정렬에서 nil 연산으로
        -- 폭발 프레임에서 게임이 죽는다. 좌표가 있는 투사체만 큐에 넣는다.
        if projectile.x and projectile.y then
            -- The burst is an aerial firework, not a ground actor. Keeping it in
            -- ordinary foot-depth order lets the dense score-attack canopy cover
            -- almost the entire authored sprite even though it was drawn.
            local sortY=projectile.kind=="firework_burst"and projectile.y+100000 or projectile.y+.03
            queueUpright(queue,projectile.x,projectile.y,function()SmokerWeaponArt.drawProjectile(projectile)end,sortY,projectile.y)
        end
    end
    for _,value in ipairs(self.vapeWindLeaves or {})do local leaf=value
        queueUpright(queue,leaf.x,leaf.y,function()SmokerWeaponArt.drawWindLeaf(leaf)end,leaf.y+.04,leaf.y)
    end
    for _,value in ipairs(self.bees) do local swarm=value
        queueUpright(queue,swarm.x,swarm.y,function()
            love.graphics.setColor(1,.9,.3,.08);love.graphics.circle("fill",swarm.x,swarm.y,40)
            for i=1,5 do local a=t*14+i*1.3;drawBeeBody(swarm.x+math.cos(a)*(8+i),swarm.y+math.sin(a*1.7)*(6+i*.4),a,t*34+i*2,1.30) end
        end)
    end
    for _,node in ipairs(game.world.nodes) do if node.rushTree and node.active and node.beehive and not node.treeEmergence then
        -- 나무와 같은 발 좌표를 쓰더라도 반드시 수관보다 뒤에 그려지도록
        -- 고정 sort bias를 둔다. 동일 키 table.sort의 프레임별 깜빡임을 막는다.
        queueUpright(queue,node.x,node.y,function()drawBeehive(node.x,node.y-150,t)end,node.y+.08,node.y)
    end end
    for _,value in ipairs(self.chests) do local chest=value;if not chest.collected then
        queueUpright(queue,chest.x,chest.y,function()
            local bob=math.sin(t*2.4+chest.x)*4;love.graphics.setColor(1,.85,.3,.18+math.sin(t*3)*.08)
            love.graphics.circle("fill",chest.x,chest.y+bob,34);drawPixelGrid(chestRows,chestPalette,chest.x,chest.y+bob,4.2)
        end)
    end end
    for _,value in ipairs(self.bossMagnetPickups) do local pickup=value
        queueUpright(queue,pickup.x,pickup.y,function()BossRewardPickup.draw(pickup,t)end)
    end
    for _,value in ipairs(self.projectiles) do local projectile=value
        queueUpright(queue,projectile.x,projectile.y,function()
            if projectile.kind=="plantSeed" or projectile.kind=="bambooBolt" or projectile.kind=="resinBlob" then AttackPlants.drawProjectile(projectile)
            elseif projectile.kind=="thorn" then
                love.graphics.push();love.graphics.translate(projectile.x,projectile.y);love.graphics.rotate(t*12);drawPixelGrid(thornRows,thornPalette,0,0,2.6);love.graphics.pop()
            else love.graphics.setColor(projectile.color);love.graphics.circle("fill",projectile.x,projectile.y,4.5) end
        end)
    end
    for _,value in ipairs(self.bossTelegraphs) do local tel=value
        if tel.phase~="warn" and tel.worldTreeAttack=="rootBurst" then
            queueUpright(queue,tel.x,tel.y,function()WorldTreeAttackArt.draw(tel,t)end)
        elseif tel.kind~="line" and tel.phase~="warn" and (tel.rootQuake or tel.branchFall or tel.plantKind) then
            queueUpright(queue,tel.x,tel.y,function()AttackPlants.drawTelegraph(tel)end)
        end
    end
    for _,value in ipairs(self.enemies) do local enemy=value;queueUpright(queue,enemy.x,enemy.y,function()drawEnemyThreat(enemy,t)end,enemy.y+.1,enemy.y) end
end

function ClearcutMode:drawWorldOverlay(game)
    love.graphics.setLineStyle("rough")
    local t = love.timer.getTime()
    local projected=game.world.deferBillboards
    if projected then self:queueProjectedOverlay(game,t) end
    local px, py = game.player.x + 14, game.player.y - 34
    if not projected and self.job=="toxic" then VeganForkArt.drawFx(self,game) end
    if self.job == "fire" then
        SecondhandSmokeArt.draw(self)
        if not projected then self:drawSmokeRing(t);self:drawHeldSmoker(game,t) end
    elseif self.job == "toxic" then
        if not projected then VeganForkArt.drawFork(self,game) end
    elseif self.job == "physical" then
        if not projected then drawPixelGrid(axeIconRows, axeIconPalette, px, py, 2.2) end
    elseif self.job == "developer" then
        if not projected then drawPixelGrid(hardhatIconRows, hardhatIconPalette, px, py, 2.4) end
    elseif self.job == "philosopher" then
        if not projected then local jitter=math.sin(t*9)*1.5;drawPixelGrid(speechIconRows,speechIconPalette,px+jitter,py,2.2) end
    end
    if (self.job == "fire" or self.job == "philosopher") and self.aimX then
        local ringColor = self.job == "fire" and {1, .5, .15} or {.75, .9, .35}
        love.graphics.setColor(ringColor[1], ringColor[2], ringColor[3], .16); love.graphics.circle("fill", self.aimX, self.aimY, self.aimRadius)
        love.graphics.setLineWidth(2); love.graphics.setColor(ringColor[1], ringColor[2], ringColor[3], .85)
        love.graphics.circle("line", self.aimX, self.aimY, self.aimRadius)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(self.aimX - 10, self.aimY, self.aimX - 4, self.aimY); love.graphics.line(self.aimX + 4, self.aimY, self.aimX + 10, self.aimY)
        love.graphics.line(self.aimX, self.aimY - 10, self.aimX, self.aimY - 4); love.graphics.line(self.aimX, self.aimY + 4, self.aimX, self.aimY + 10)
    elseif self.job=="toxic" and self.aimX then
        local dx,dy=self.aimX-game.player.x,self.aimY-(game.player.y-10)
        local dist=math.sqrt(dx*dx+dy*dy)
        if dist>1 then
            local nx,ny=dx/dist,dy/dist; local pxn,pyn=-ny,nx
            local width=self.aimRadius or 32
            love.graphics.setColor(.56,1,.36,.10)
            love.graphics.polygon("fill",game.player.x,game.player.y-10,self.aimX+pxn*width,self.aimY+pyn*width,self.aimX-pxn*width,self.aimY-pyn*width)
            love.graphics.setLineWidth(2); love.graphics.setColor(.72,1,.48,.72)
            love.graphics.line(game.player.x,game.player.y-10,self.aimX+pxn*width,self.aimY+pyn*width)
            love.graphics.line(game.player.x,game.player.y-10,self.aimX-pxn*width,self.aimY-pyn*width)
            love.graphics.setColor(1,.83,.35,.9); love.graphics.line(self.aimX+pxn*width,self.aimY+pyn*width,self.aimX-pxn*width,self.aimY-pyn*width)
        end
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
    if not projected and self.job == "philosopher" then self:drawSalivaGauge(game) end
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
    if not projected then
        if self.job=="developer" then self:drawDeveloperMachinery(game,t) end
        self:drawThrownTrees(game)
        self:drawSupplementSkills(game,t)
        MoleClawArt.draw(self,game,t)
        self.traitFx:draw()
    end
    if projected then SupplementArt.drawGround(self,game,t);BruteForceArt.drawGround(self,game,t);PhilosopherArt.draw(self) end
    AttackPlants.drawWorld(self,t)
    if not projected then for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active and node.beehive then
            drawBeehive(node.x, node.y - 150, t)
        end
    end end
    if not projected then for _, c in ipairs(self.chests) do
        if not c.collected then
            local bob = math.sin(t * 2.4 + c.x) * 4
            love.graphics.setColor(1, .85, .3, .18 + math.sin(t * 3) * .08)
            love.graphics.circle("fill", c.x, c.y + bob, 34)
            drawPixelGrid(chestRows, chestPalette, c.x, c.y + bob, 4.2)
        end
    end end
    if not projected then for _,pickup in ipairs(self.bossMagnetPickups) do BossRewardPickup.draw(pickup,t) end end
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
    if not projected then for _, swarm in ipairs(self.bees) do
        love.graphics.setColor(1, .9, .3, .08); love.graphics.circle("fill", swarm.x, swarm.y, 40)
        for i = 1, 5 do
            local a = t * 14 + i * 1.3
            local bx, by = swarm.x + math.cos(a) * (8 + i), swarm.y + math.sin(a * 1.7) * (6 + i * .4)
            drawBeeBody(bx, by, a, t * 34 + i * 2,1.30)
        end
    end end
    if not projected and self.rootedTimer > 0 then
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
    if not projected then self:drawCigaretteProjectiles(t) end
    if not projected then self:drawCigaretteGroundEffects() end
    for _, tel in ipairs(self.bossTelegraphs) do
        if tel.worldTreeAttack then
            if not (projected and tel.phase~="warn" and tel.worldTreeAttack=="rootBurst") then WorldTreeAttackArt.draw(tel,t) end
        elseif tel.kind == "line" then
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
        elseif projected and tel.phase~="warn" and (tel.rootQuake or tel.branchFall or tel.plantKind) then
            -- Active authored impact art is queued as an upright billboard.
        elseif AttackPlants.drawTelegraph(tel) then
            -- Authored counterattack atlas handles root eruptions, falling branches and plant impacts.
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
    if not projected then for _, e in ipairs(self.enemies) do drawEnemyThreat(e,t) end end
    if not projected then for _, p in ipairs(self.projectiles) do
        if p.kind=="plantSeed" or p.kind=="bambooBolt" or p.kind=="resinBlob" then
            AttackPlants.drawProjectile(p)
        elseif p.kind == "thorn" then
            love.graphics.setColor(1, .7, .3, .28); love.graphics.circle("fill", p.x, p.y, 9)
            love.graphics.push(); love.graphics.translate(p.x, p.y); love.graphics.rotate(t * 12)
            drawPixelGrid(thornRows, thornPalette, 0, 0, 2.6)
            love.graphics.pop()
        else
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], .3); love.graphics.circle("fill", p.x, p.y, 8)
            love.graphics.setColor(p.color); love.graphics.circle("fill", p.x, p.y, 4.5)
            love.graphics.setColor(0, 0, 0, .8); love.graphics.setLineWidth(1); love.graphics.circle("line", p.x, p.y, 4.5)
        end
    end end
    if not projected and self.invulnTimer > 0 then
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
    local uiScale=math.max(.88,math.min(1.2,w/1280))
    local remaining=self:stageTimeRemaining();local overtime=self.scoreAttack
    local occupancy=overtime and self:scoreOccupancy()or 0
    drawBerserkOverlay(self.berserkState, w, h, t)
    drawDisasterOverlay(self, w, h, t)
    if overtime then OvercrowdWarningArt.draw(occupancy,self.mapId,w,h,t)end
    drawOffscreenIndicators(self, game, fonts, w, h, t)
    local urgent=overtime and occupancy>=.80 or remaining<=60
    local timeText=overtime and formatTime(self.stageElapsed or 0)or formatTime(remaining)
    love.graphics.setFont(fonts.big);love.graphics.setColor(urgent and {1,.30,.18} or {1,.96,.82});love.graphics.print(timeText,18,16)
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(urgent and {1,.55,.30} or {.82,.84,.76});love.graphics.print(self.scoreAttack and"벌목 기록"or("제한 시간 · "..Maps.stageCode(self.mapId,self.stage).." · "..(jobNames[self.job]or"벌목꾼")),20,51)
    love.graphics.setColor(.92,.90,.72);love.graphics.print(self.scoreAttack and string.format("목재 %d   벌목 %d   생성 %d",self.totalWood,self.treesFelled,self.totalTreesSpawned or 0)or string.format("목재 %d   벌목 %d/%d",self.totalWood,self.treesFelled,self.initialTrees),20,71)
    local statusColor = (self.rootedTimer > 0 or self.beeSlow) and {1,.6,.35} or {.6,.72,.66}
    love.graphics.setColor(statusColor)
    local secured,totalZones=ForestZones.status(self)
    local status = self.rootedTimer > 0 and "발이 묶임!" or self.beeSlow and "벌떼에 쫓기는 중" or(self.scoreAttack and string.format("재생 %d단계 · 생성 %.2f그루/초",self.scoreRegenTier or 1,self:scoreTreeSpawnRate())or string.format("구역 %d/%d 확보 · 재생 %d회 · 숲 압력 x%.1f",secured,totalZones,self.regrowPulses,self:forestPressure()))
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(statusColor);love.graphics.print(status,20,91)
    local evoNames=Fusions.activeNames(self)
    if #evoNames>0 then
        love.graphics.setColor(1,.82,.3)
        love.graphics.printf("융합  "..table.concat(evoNames," · "),20,111,320,"left")
    end

    if not self.scoreAttack then
        local hpW=math.floor(260*uiScale);HUDArt.bar(20,135,hpW,14,math.max(0,self.hp/self.maxHp),"health",self.hp/self.maxHp<.3)
        love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(1,.94,.88);love.graphics.printf("HP  "..math.ceil(self.hp).." / "..self.maxHp,20,134,hpW,"center")
    end

    local pct = self:destructionPct()
    local barW = math.floor(330*uiScale)
    local flash = self.regrowFlash > 0
    local forestX=math.floor(w/2-barW/2);love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.90,.92,.78);love.graphics.print(self.scoreAttack and"숲 과밀도"or"남은 숲",forestX,17)
    local countColor=occupancy>=.90 and{1,.30,.16}or occupancy>=.80 and{1,.68,.20}or occupancy>=.70 and{1,.82,.28}or{.70,1,.55}
    love.graphics.setColor(flash and {1,.47,.32}or countColor);love.graphics.printf(self.scoreAttack and string.format("%d / %d그루",self.remainingTrees,self.scoreTreeAllowance or 12)or string.format("%.0f%%",100-pct),forestX,17,barW,"right")
    HUDArt.bar(forestX,38,barW,14,self.scoreAttack and occupancy or 1-pct/100,overtime and"health"or"forest",flash or(overtime and urgent))
    if not self.scoreAttack then ForestZones.drawHUD(self,fonts,w,61)end

    if self.activeBoss then
        local boss = self.activeBoss
        local intro=self.bossEntrance
        local reveal=intro and intro.impact and math.min(1,(intro.t-intro.duration*.58)/.28) or (intro and 0 or 1)
        if reveal>0 then
            local bw=math.floor(math.min(560,w*.48)*reveal);local bx=math.floor(w/2-bw/2);local by=151
            love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.94,.84,.70,reveal)
            love.graphics.printf(boss.def.name,w/2-180,by-19,360,"center")
            love.graphics.setColor(.10,.045,.035,.96*reveal);love.graphics.rectangle("fill",bx-2,by-2,bw+4,14)
            local fill=math.floor(bw*math.max(0,boss.hp/boss.maxHp))
            love.graphics.setColor(.52,.045,.035,reveal);love.graphics.rectangle("fill",bx,by,fill,10)
            love.graphics.setColor(.96,.17,.09,reveal);love.graphics.rectangle("fill",bx,by,fill,5)
            love.graphics.setColor(1,.48,.20,.72*reveal);love.graphics.rectangle("fill",bx+2,by+1,math.max(0,fill-4),2)
        end
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

    -- Fighting-game read: only the number and COMBO, never another HUD card.
    local harvestChain = game.world.harvestChain or 0
    if harvestChain >= 2 then
        local cbw = 180
        local cbx = w - 24 - cbw
        local stacked = 0
        if self.berserkState == "warn" or self.berserkState == "active" then stacked = stacked + 1 end
        if self.disasterState == "warn" or self.disasterState == "active" then stacked = stacked + 1 end
        local cby = 24 + stacked * 66
        local pop=1+math.min(.16,math.max(0,game.world.harvestChainTime or 0)*.05)
        love.graphics.push();love.graphics.translate(cbx+cbw/2,cby+36);love.graphics.scale(pop,pop)
        love.graphics.setFont(fonts.display or fonts.title);love.graphics.setColor(.06,.04,.02,.82);love.graphics.printf(tostring(harvestChain),-cbw/2+3,-15+3,cbw,"center")
        love.graphics.setColor(1,.72,.16,1);love.graphics.printf(tostring(harvestChain),-cbw/2,-15,cbw,"center")
        love.graphics.setFont(fonts.small);love.graphics.setColor(1,.94,.68,1);love.graphics.printf("COMBO",-cbw/2,38,cbw,"center")
        love.graphics.pop()
    end

    if not self.scoreAttack then
        local barH = 8
        local xpby = h - barH
        HUDArt.bar(0,xpby,w,barH,math.min(1,self.xp/self.xpNext),"xp")
        love.graphics.setFont(fonts.small); love.graphics.setColor(1,1,1,.9)
        love.graphics.print("Lv."..self.level,12,xpby-18)
        love.graphics.printf(math.floor(self.xp).." / "..self.xpNext,0,xpby-18,w-12,"right")
    end
    if self.job=="miner" then
        local ready=(self.minerBurrowCooldown or 0)<=0 and not self.minerBurrow
        local text=self.minerBurrow and (self.minerBurrow.state=="tunnel" and "SPACE / 우클릭  지상 돌파 · 주변 몬스터 에어본" or "잠복 전환 중") or ready and "SPACE / 우클릭  잠복 준비" or string.format("잠복 재사용 %.1f초",self.minerBurrowCooldown)
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(.035,.045,.035,.9); love.graphics.rectangle("fill",w/2-150,h-52,300,30,7,7)
        love.graphics.setColor(ready and {.94,.76,.28,1} or {.72,.65,.52,1})
        love.graphics.printf(text,w/2-146,h-45,292,"center")
    end
    if self.job=="fire" then
        local ready=(self.smokeRingCooldown or 0)<=0 and not self.smokeRing
        local text=self.smokeRing and "도넛 연기 — 후우..." or ready and "SPACE  도넛 연기 준비" or string.format("도넛 연기 재사용 %.1f초",self.smokeRingCooldown)
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(.035,.045,.035,.9); love.graphics.rectangle("fill",w/2-150,h-52,300,30,7,7)
        love.graphics.setColor(ready and {.94,.76,.28,1} or {.72,.65,.52,1})
        love.graphics.printf(text,w/2-146,h-45,292,"center")

        -- 보루 잔량: 화면 오른쪽 가장자리에 남은 개비 수만큼 아이콘을 하나씩 세로로 쌓아 보여준다.
        -- 배경 패널 없이 아이콘만 떠 있게 해서 화면을 가리지 않는다.
        local ammoMax=self.cartonSize or 20
        local ammo=math.max(0,math.min(ammoMax,self.cartonAmmo or ammoMax))
        local colX=w-26
        local top,bottom=140,h-70
        local avail=math.max(60,bottom-top)
        local pitch=math.min(22,avail/ammoMax)
        local colH=pitch*ammoMax
        local startY=top+(avail-colH)/2
        local iconDef=ClearcutMode.icons.cigarette
        local px=math.max(1.2,pitch/9)
        for i=1,ammo do
            local iy=startY+(i-1)*pitch+pitch/2
            love.graphics.setColor(0,0,0,.5)
            love.graphics.circle("fill",colX,iy,pitch*.34)
            if iconDef then drawPixelGrid(iconDef.rows,iconDef.palette,colX,iy,px) end
        end
    end
    if self.job=="philosopher" then
        local ready=(self.revivalCooldown or 0)<=0 and (self.revivalTimer or 0)<=0
        local text=self.revivalTimer>0 and string.format("부흥회 진행 중 — %.1f초",self.revivalTimer) or ready and "SPACE  부흥회 개최 준비" or string.format("부흥회 재개최 %.1f초",self.revivalCooldown)
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(.035,.045,.035,.9); love.graphics.rectangle("fill",w/2-150,h-52,300,30,7,7)
        love.graphics.setColor(ready and {.94,.76,.28,1} or {.72,.65,.52,1})
        love.graphics.printf(text,w/2-146,h-45,292,"center")
    end
    ScoreTierUpArt.draw(self.scoreTierFx,fonts,w,h)
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

-- 카드 묶음을 실제 화면의 가로·세로 중앙에 놓는 단일 레이아웃 소스.
-- 960×540은 drawSelection의 1280×720 가상 화면을 그대로 축소하고,
-- 큰 전체화면에서는 카드 폭·높이와 위아래 여백을 함께 늘린다.
local function selectionCardLayout(w,h,count,bottomOverride)
    local gap=count>=4 and 20 or 24
    local maxW=count>=4 and 330 or 350
    local cardW=math.min(maxW,(w-120-gap*(count-1))/count)
    local top,bottom=145,bottomOverride or (h-142)
    local available=math.max(410,bottom-top)
    local cardH=math.max(410,math.min(500,available))
    local y=top+math.max(0,(available-cardH)/2)
    local startX=(w-(cardW*count+gap*(count-1)))/2
    return startX,y,cardW,cardH,gap
end
ClearcutMode.selectionCardLayout=selectionCardLayout

local function selectionDescriptionFont(fonts,text,width,maxHeight)
    for _,font in ipairs({fonts.body,fonts.small,fonts.micro or fonts.small}) do
        local _,lines=font:getWrap(text,width)
        if #lines*font:getHeight()<=maxHeight then return font end
    end
    return fonts.micro or fonts.small
end

-- 카드에서는 효과를 빠르게 비교할 수 있도록 긴 기획 설명을 핵심 작동만 남겨 줄인다.
-- 상세 수치와 전체 문장은 인물 기록부/스킬 설명 원본(def.desc)에 그대로 보존한다.
local selectionDescriptions={
    molotov="3레벨에 화염 농축/줄꽁초 경로를 선택합니다. 화염은 착화·연소·확산을 강화하고, 줄꽁초는 한 번에 3개비를 던집니다. 6레벨에는 경로별 무기로 자동 진화합니다.",
    dry_forest="꽁초 착화 확률이 증가하고, 붙은 불이 주변 나무로 더 빠르고 넓게 번집니다.",
    oil_drum="불탄 나무가 폭발할 확률이 크게 증가합니다. 6레벨에는 폭발이 반드시 발생합니다.",
    straw_bale="큰 건초더미를 설치합니다. 꽁초가 닿으면 0.5초 뒤 넓은 화염 지대가 생겨 나무와 적에게 지속 피해를 줍니다.",
    smoke_ring="SPACE 도넛 연기의 재사용 시간·피해·넉백·크기를 강화합니다. 6레벨 완충 시 초농축 도넛을 발사합니다.",
    detector="보이는 발톱 궤적 전체를 공격합니다. 범위와 피해가 증가하며, 6레벨에는 양손으로 할퀵니다.",
    burrow_uproot="잠복 재사용 시간이 줄고 나무 투척이 강해집니다. 잠복 중 다시 입력하면 주변 몬스터를 공격해 공중에 띄웁니다.",
    monologue="공격이 장광설로 바뀝니다. 누르는 동안 침을 연속 발사하며, 오래 말할수록 사거리와 피해가 증가합니다. 게이지가 바닥나면 25% 회복 후 다시 발사합니다.",
    revival_meeting="SPACE 부흥회의 재사용 시간이 줄고 지속시간과 침 피해 배율이 증가합니다.",
    bat_swarm="박쥐가 주변 대상을 골라 급강하합니다. 사거리 안에서는 몬스터를 나무보다 먼저 노립니다.",
    vine_whip="가장 가까운 방향으로 긴 덩굴을 휘둘러 넓은 부채꼴 범위를 공격합니다.",
    chain_lightning="번개가 근처 나무와 적 사이를 연쇄로 튀며 여러 번 피해를 줍니다.",
}
local function selectionDescription(def)return selectionDescriptions[def.id] or def.desc end
local scoreOperationIconAliases={robot_scanner="chain_lightning",yard_management="straw_bale",forest_zoning="vine_whip",wood_sorter="seed_mine",safety_system="thorn_aura",
    score_attack_speed="cigarette",score_extra_butts="dry_forest",score_ignition_radius="oil_drum",score_burn_speed="dry_forest"}

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
    Frontend.backdrop(w,h,Frontend.colors.amber,.94)
    love.graphics.setFont(fonts.micro or fonts.small); love.graphics.setColor(Frontend.colors.amber)
    love.graphics.print(self.scoreAttack and"운영 레벨 업"or"레벨 업",34,24)
    self.choiceBoxes={}
    if self.selectionKind == "fusion" then Fusions.drawAcquisition(self,fonts,w,h); return end
    if self.selectionKind == "branch" then
        local skill=self:getUpgradeDefinition(self.branchChoiceSkill)
        love.graphics.setFont(fonts.title);love.graphics.setColor(1,.82,.3)
        local branchLevel=SkillBranches.triggerLevel(self.branchChoiceSkill)or 3
        love.graphics.printf((skill and skill.name or "스킬").." · "..branchLevel.."레벨 진화",0,66,w,"center")
        love.graphics.setFont(fonts.small);love.graphics.setColor(.72,.88,.76)
        love.graphics.printf("이번 런에서 사용할 공격 방식을 하나 선택합니다.",0,112,w,"center")
        local startX,cardY,cardW,cardH,gap=selectionCardLayout(w,h,#(self.branchChoices or {}),h-74)
        local mx,my=self:selectionMousePosition();local reveal=t-(self.choicesRevealAt or t)
        for i,def in ipairs(self.branchChoices or {})do
            local x,y=startX+(i-1)*(cardW+gap),cardY;self.choiceBoxes[i]={x=x,y=y,w=cardW,h=cardH}
            local hovered=mx>=x and mx<=x+cardW and my>=y and my<=y+cardH
            local scaleX=specialCardFlip(math.max(0,reveal-(i-1)*.08));local cx=x+cardW/2
            love.graphics.push();love.graphics.translate(cx,y+cardH/2);love.graphics.scale(scaleX,1);love.graphics.translate(-cx,-(y+cardH/2))
            if scaleX<.5 then drawCardBack(x,y,cardW,cardH,t,def.color)else
                drawUpgradeCardFrame(x,y,cardW,cardH,def.color,hovered,nil,t)
                local iconY=y+math.min(118,cardH*.28)
                if self.branchChoiceSkill=="molotov"then
                    if not SmokerWeaponArt.drawChoice(def.id,cx,iconY,.88)then
                        drawIconSocket(cx,iconY,def.color,ClearcutMode.icons.cigarette,t,true)
                    end
                else local icon=ClearcutMode.icons[self.branchChoiceSkill];drawIconSocket(cx,iconY,def.color,icon,t,true)end
                love.graphics.setColor(.06,.09,.08,.92);love.graphics.rectangle("fill",x+16,y+16,34,30,7,7)
                love.graphics.setFont(fonts.heading);love.graphics.setColor(1,1,1);love.graphics.printf(tostring(i),x+16,y+21,34,"center")
                love.graphics.setFont(fonts.heading);love.graphics.setColor(1,1,1);love.graphics.printf(def.name,x+18,y+cardH*.45,cardW-36,"center")
                love.graphics.setFont(fonts.small);love.graphics.setColor(def.color)
                love.graphics.printf("전문화 · 변경 불가",x+20,y+cardH*.45+38,cardW-40,"center")
                love.graphics.setColor(1,1,1,.17);love.graphics.line(x+22,y+cardH*.45+72,x+cardW-22,y+cardH*.45+72)
                love.graphics.setFont(fonts.body or fonts.small);love.graphics.setColor(.9,.94,.91)
                love.graphics.printf(def.desc,x+28,y+cardH*.45+92,cardW-56,"center")
            end
            love.graphics.pop()
        end
        return
    end
    if self.selectionKind == "arcana" then
        love.graphics.setFont(fonts.title); love.graphics.setColor(arcanaColor); love.graphics.printf("아르카나 선택",0,66,w,"center")
        love.graphics.setFont(fonts.small); love.graphics.setColor(.85,.78,.95); love.graphics.printf("선택한 효과는 이번 판 동안 유지됩니다.",0,112,w,"center")
        local startX,cardY,cardW,cardH,gap=selectionCardLayout(w,h,3)
        local mx,my=self:selectionMousePosition()
        local revealElapsed = t - (self.choicesRevealAt or t)
        for i,def in ipairs(self.arcanaChoices) do
            local x,y=startX+(i-1)*(cardW+gap),cardY
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
            local iconY=y+math.min(112,cardH*.25)
            local nameY=y+cardH*.42
            local tagY=nameY+31
            local descY=tagY+45
            local footerY=y+cardH-68
            drawIconSocket(x+cardW/2,iconY,arcanaColor,iconDef,t)
            love.graphics.setColor(.06,.09,.08,.92); love.graphics.rectangle("fill",x+16,y+16,34,30,7,7)
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(tostring(i),x+16,y+21,34,"center")
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,nameY,cardW-32,"center")
            do
                local tagText = "아르카나"
                love.graphics.setFont(fonts.small)
                local tagW = math.min(cardW-40, fonts.small:getWidth(tagText)+28)
                local tagX = cx - tagW/2
                love.graphics.setColor(arcanaColor[1],arcanaColor[2],arcanaColor[3],.22); love.graphics.rectangle("fill",tagX,tagY,tagW,22,11,11)
                love.graphics.setColor(arcanaColor[1],arcanaColor[2],arcanaColor[3],.9); love.graphics.setLineWidth(1.3); love.graphics.rectangle("line",tagX,tagY,tagW,22,11,11)
                love.graphics.setColor(1,.96,.85,1); love.graphics.printf(tagText,tagX,tagY+5,tagW,"center")
            end
            love.graphics.setColor(1,1,1,.17); love.graphics.line(x+22,descY-11,x+cardW-22,descY-11)
            local desc=selectionDescription(def)
            love.graphics.setFont(selectionDescriptionFont(fonts,desc,cardW-44,footerY-descY-14)); love.graphics.setColor(.92,.88,.97)
            love.graphics.printf(desc,x+22,descY,cardW-44,"center")
            love.graphics.setColor(1,1,1,.17); love.graphics.line(x+22,footerY-10,x+cardW-22,footerY-10)
            love.graphics.setColor(arcanaColor[1],arcanaColor[2],arcanaColor[3],.17); love.graphics.rectangle("fill",x+16,footerY,cardW-32,54,8,8)
            love.graphics.setFont(fonts.heading); love.graphics.setColor(arcanaColor)
            love.graphics.printf("영구 효과 · 되돌릴 수 없음",x+20,footerY+16,cardW-40,"center")
            end
            love.graphics.pop()
        end
        return
    end

    love.graphics.setFont(fonts.title); love.graphics.setColor(1,.82,.3); love.graphics.printf(self.scoreAttack and"현장 운영 선택"or"벌목 방식 진화",0,66,w,"center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.88,.76); love.graphics.printf(self.scoreAttack and"벌목 기록 모드는 인게임 강화를 사용하지 않습니다."or"스킬 하나를 선택합니다.",0,112,w,"center")
    local numCards = self.specialCard and 4 or 3
    local progressH=self.scoreAttack and 0 or 30+#Fusions.forJob(self)*22
    local buttonY=h-progressH-12-44-14
    local startX,cardY,cardW,cardH,gap=selectionCardLayout(w,h,numCards,buttonY-14)
    local mx,my=self:selectionMousePosition()
    local revealElapsed = t - (self.choicesRevealAt or t)
    for i,def in ipairs(self.choices) do
        local x,y=startX+(i-1)*(cardW+gap),cardY
        self.choiceBoxes[i]={x=x,y=y,w=cardW,h=cardH}
        local hovered = mx>=x and mx<=x+cardW and my>=y and my<=y+cardH
        local jobColor = self.scoreAttack and(def.color or universalColor)or(jobFlavorColors[def.job]or universalColor)
        local scaleX, flipP = specialCardFlip(math.max(0, revealElapsed - (i-1)*.08))
        local cx = x+cardW/2
        love.graphics.push(); love.graphics.translate(cx,y+cardH/2); love.graphics.scale(scaleX,1); love.graphics.translate(-cx,-(y+cardH/2))
        if scaleX < .5 then
            drawCardBack(x,y,cardW,cardH,t,jobColor)
        else
        drawUpgradeCardFrame(x,y,cardW,cardH,jobColor,hovered,def.job,t)
        local iconId=def.id=="molotov"and"cigarette"or(scoreOperationIconAliases[def.id]or def.id)
        local iconDef = ClearcutMode.icons[iconId]
        local iconY=y+math.min(112,cardH*.25)
        local nameY=y+cardH*.42
        local descY=nameY+52
        local footerY=y+cardH-68
        drawIconSocket(x+cardW/2,iconY,jobColor,iconDef,t)
        love.graphics.setColor(.06,.09,.08,.92); love.graphics.rectangle("fill",x+16,y+16,34,30,7,7)
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(tostring(i),x+16,y+21,34,"center")
        if self.banishArmed and not jobFor[def.id] then
            love.graphics.setColor(1,.3,.25,.5+math.sin(t*8)*.15); love.graphics.setLineWidth(3)
            love.graphics.rectangle("line",x+3,y+3,cardW-6,cardH-6,12,12)
        end
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,nameY,cardW-32,"center")
        love.graphics.setColor(1,1,1,.17); love.graphics.line(x+22,descY-11,x+cardW-22,descY-11)
        local desc=selectionDescription(def)
        love.graphics.setFont(selectionDescriptionFont(fonts,desc,cardW-44,footerY-descY-14)); love.graphics.setColor(.9,.94,.91)
        love.graphics.printf(desc,x+22,descY,cardW-44,"center")
        love.graphics.setColor(1,1,1,.17); love.graphics.line(x+22,footerY-10,x+cardW-22,footerY-10)
        love.graphics.setColor(jobColor[1],jobColor[2],jobColor[3],.17); love.graphics.rectangle("fill",x+16,footerY,cardW-32,54,8,8)
        local curLevel = self:levelOf(def.id)
        local label=def.recovery and "체력 +20" or ("Lv."..curLevel.."  →  Lv."..(curLevel+1))
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,.8,.32)
        love.graphics.printf(label,x+20,footerY+8,cardW-40,"center")
        if not def.recovery and def.max and def.max > 1 then
            local dotGap, dotR = 15, 4
            local dotsW = (def.max-1)*dotGap
            local dx0 = cx - dotsW/2
            for lvl = 1, def.max do
                local px = dx0 + (lvl-1)*dotGap
                if lvl <= curLevel then
                    love.graphics.setColor(jobColor[1],jobColor[2],jobColor[3],1); love.graphics.circle("fill",px,footerY+41,dotR)
                elseif lvl == curLevel+1 then
                    love.graphics.setColor(1,.8,.32,.6+math.sin(t*5)*.3); love.graphics.setLineWidth(2); love.graphics.circle("line",px,footerY+41,dotR+1)
                else
                    love.graphics.setColor(1,1,1,.22); love.graphics.setLineWidth(1); love.graphics.circle("line",px,footerY+41,dotR)
                end
            end
        end
        end
        love.graphics.pop()
    end

    if self.specialCard then
        local def = self.specialCard
        local i = 4
        local x,y = startX+(i-1)*(cardW+gap),cardY
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
            local iconY=y+math.min(112,cardH*.25)
            local nameY=y+cardH*.42
            local tagY=nameY+31
            local descY=tagY+45
            local footerY=y+cardH-68
            drawIconSocket(x+cardW/2,iconY,specialColor,iconDef,t,true)
            love.graphics.setColor(.06,.09,.08,.92); love.graphics.rectangle("fill",x+16,y+16,34,30,7,7)
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf("4",x+16,y+21,34,"center")
            love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf(def.name,x+16,nameY,cardW-32,"center")
            do
                local tagText = "★ 스페셜 카드"
                love.graphics.setFont(fonts.small)
                local tagW = math.min(cardW-40, fonts.small:getWidth(tagText)+28)
                local tagX = cx - tagW/2
                love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.22); love.graphics.rectangle("fill",tagX,tagY,tagW,22,11,11)
                love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.9); love.graphics.setLineWidth(1.3); love.graphics.rectangle("line",tagX,tagY,tagW,22,11,11)
                love.graphics.setColor(1,.95,.75,1); love.graphics.printf(tagText,tagX,tagY+5,tagW,"center")
            end
            love.graphics.setColor(1,1,1,.17); love.graphics.line(x+22,descY-11,x+cardW-22,descY-11)
            local desc=selectionDescription(def)
            love.graphics.setFont(selectionDescriptionFont(fonts,desc,cardW-44,footerY-descY-14)); love.graphics.setColor(.96,.92,.79)
            love.graphics.printf(desc,x+22,descY,cardW-44,"center")
            love.graphics.setColor(1,1,1,.17); love.graphics.line(x+22,footerY-10,x+cardW-22,footerY-10)
            love.graphics.setColor(specialColor[1],specialColor[2],specialColor[3],.17); love.graphics.rectangle("fill",x+16,footerY,cardW-32,54,8,8)
            love.graphics.setFont(fonts.heading); love.graphics.setColor(specialColor)
            love.graphics.printf("영구 효과 · 되돌릴 수 없음",x+20,footerY+16,cardW-40,"center")
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

    if not self.chestPending and not self.scoreAttack then
        local btnW,btnH,btnGap=150,44,16
        local by = buttonY
        local bx = w/2-(btnW*2+btnGap)/2
        self.rerollBox={x=bx,y=by,w=btnW,h=btnH}
        self.banishBox={x=bx+btnW+btnGap,y=by,w=btnW,h=btnH}
        local canReroll = self.totalWood >= self:rerollCost()
        UI.button(bx,by,btnW,btnH,string.format("리롤 (목재 %d)",self:rerollCost()),canReroll,fonts.small,mx,my)
        local canBanish = self.banishArmed or self.totalWood >= self:banishCost()
        UI.button(bx+btnW+btnGap,by,btnW,btnH,self.banishArmed and "배니시할 카드 선택" or string.format("배니시 (목재 %d)",self:banishCost()),canBanish,fonts.small,mx,my)
    end
    if not self.scoreAttack then Fusions.drawProgress(self,fonts,w,h)end
end

function ClearcutMode:choiceAt(x,y)
    if self.selectionKind == "upgrade" and not self.chestPending and not self.scoreAttack then
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

local function drawScoreSettlementResults(self,game,fonts)
    local w,h,r=love.graphics.getWidth(),love.graphics.getHeight(),game.result
    local scale=math.max(.72,math.min(1,w/1280,h/720));local contentW=math.min(920,w-36);local x=(w-contentW)/2
    local top=18*scale;local s=self.resultSettlement
    love.graphics.setColor(.006,.012,.009,.74);love.graphics.rectangle("fill",0,0,w,h)
    love.graphics.setFont(fonts.title);love.graphics.setColor(1,.94,.76);love.graphics.printf("작업 종료",x,top,contentW,"center")
    love.graphics.setFont(fonts.small);love.graphics.setColor(.72,.77,.69)
    love.graphics.printf(formatTime(r.elapsed).."  ·  "..tostring(r.trees or 0).."그루 벌목  ·  최고 "..tostring(r.peakTreesPerSecond or 0).."그루/초",x,top+46*scale,contentW,"center")

    local panelY=top+82*scale;local panelH=math.min(390*scale,h-panelY-86*scale)
    love.graphics.setColor(.018,.030,.022,.94);love.graphics.rectangle("fill",x,panelY,contentW,panelH,8,8)
    love.graphics.setColor(.74,.49,.20,.85);love.graphics.rectangle("fill",x,panelY,5,panelH,3,3)
    love.graphics.setFont(fonts.heading);love.graphics.setColor(.96,.91,.74);love.graphics.print("목재 정산",x+28*scale,panelY+18*scale)
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.60,.67,.59);love.graphics.print("수종별 목재가 차례로 연구 코인으로 바뀝니다",x+28*scale,panelY+50*scale)

    local bankW=238*scale;local bankX=x+contentW-bankW-22*scale;local bankY=panelY+26*scale
    love.graphics.setColor(.055,.068,.047,.98);love.graphics.rectangle("fill",bankX,bankY,bankW,panelH-52*scale,7,7)
    love.graphics.setColor(.79,.59,.24,.75);love.graphics.rectangle("line",bankX+.5,bankY+.5,bankW-1,panelH-53*scale,7,7)
    WoodSettlementArt.drawCoin(bankX+bankW/2,bankY+70*scale,(s and s.elapsed or 0),.78*scale,1)
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.72,.70,.57);love.graphics.printf("보유 연구 코인",bankX,bankY+114*scale,bankW,"center")
    love.graphics.setFont(fonts.big);love.graphics.setColor(1,.82,.30);love.graphics.printf(tostring(r.traitCurrency or 0),bankX,bankY+138*scale,bankW,"center")
    love.graphics.setFont(fonts.small);love.graphics.setColor(.54,1,.61);love.graphics.printf("이번 정산  +"..tostring(r.traitEarned or 0),bankX,bankY+184*scale,bankW,"center")
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.57,.62,.55)
    love.graphics.printf((s and s.complete)and"정산 완료"or"목재를 세는 중…",bankX,bankY+220*scale,bankW,"center")

    local rows=(s and s.rows)or r.lumberRows or{};local listX=x+24*scale;local listW=contentW-bankW-68*scale
    local rowStart=panelY+82*scale;local rowH=math.min(64*scale,(panelH-100*scale)/math.max(1,#rows))
    s=s or{rows=rows,rowIndex=#rows+1,bursts={},elapsed=0,complete=true};s.layout={rows={},bankX=bankX+bankW/2,bankY=bankY+70*scale}
    for i,row in ipairs(rows)do
        local ry=rowStart+(i-1)*rowH;local active=not s.complete and i==s.rowIndex
        if active then love.graphics.setColor(.18,.115,.036,.80);love.graphics.rectangle("fill",listX,ry,listW,rowH-5*scale,5,5)end
        love.graphics.setColor(active and{1,.66,.20}or{.25,.31,.24});love.graphics.rectangle("fill",listX,ry+rowH-6*scale,listW,2*scale)
        WoodSettlementArt.drawLog(listX+34*scale,ry+rowH*.43,.28*scale,row.color,1)
        love.graphics.setFont(fonts.small);love.graphics.setColor(.91,.90,.77);love.graphics.print(row.name,listX+70*scale,ry+10*scale)
        love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.62,.68,.59)
        love.graphics.print("1개 = "..row.coin.." 코인",listX+70*scale,ry+34*scale)
        love.graphics.setFont(fonts.heading);love.graphics.setColor(active and{1,.83,.37}or{.82,.82,.69})
        love.graphics.printf("× "..tostring(row.remaining or row.count),listX+listW-118*scale,ry+17*scale,96*scale,"right")
        s.layout.rows[i]={x=listX+listW-24*scale,y=ry+rowH*.42}
    end
    for _,b in ipairs(s.bursts or{})do
        local origin=s.layout.rows[b.rowIndex]
        if origin then local p=math.min(1,b.t/b.dur);local ease=1-(1-p)^3
            local bx=origin.x+(s.layout.bankX-origin.x)*ease
            local by=origin.y+(s.layout.bankY-origin.y)*ease-math.sin(p*math.pi)*(35+(b.seed or 0))*scale
            if p<.42 then
                local row=s.rows[b.rowIndex]
                WoodSettlementArt.drawLog(bx,by,.12*scale*(1-p*.7),row and row.color or{1,1,1},math.min(1,(1-p)*3))
            else
                WoodSettlementArt.drawCoin(bx,by,(s.elapsed or 0)+b.seed,.28*scale,math.min(1,(1-p)*2.8))
            end
        end
    end

    local buttonH=50*scale;local buttonW=230*scale;local by=h-buttonH-16*scale;local bx=w/2-buttonW-8*scale
    game.clearcutResultButtons={research={x=bx,y=by,w=buttonW,h=buttonH},retry={x=w/2+8*scale,y=by,w=buttonW,h=buttonH}}
    HUDArt.resultButton(bx,by,buttonW,buttonH,"강화하기","T",fonts.small,"neutral",true)
    HUDArt.resultButton(w/2+8*scale,by,buttonW,buttonH,"다시 도전","ENTER",fonts.small,"amber",true)
end

function ClearcutMode:drawResults(game,fonts)
    if game.result and game.result.scoreAttack then return drawScoreSettlementResults(self,game,fonts)end
    local w,h,r=love.graphics.getWidth(),love.graphics.getHeight(),game.result
    local victory=r.victory~=false
    local scale=math.max(.76,math.min(1.16,w/1280,h/720));local contentW=math.min(720,w-48);local x=(w-contentW)/2
    local top=math.max(24,(h-590*scale)/2)
    love.graphics.setColor(.004,.010,.007,.68);love.graphics.rectangle("fill",0,0,w,h)
    local title=r.scoreAttack and "산림 과밀"or(victory and((r.operationName or"벌목 작전").." 완료")or"작업 중단")
    love.graphics.setFont(fonts.title);love.graphics.setColor(victory and{1,.92,.64}or{1,.44,.30});love.graphics.printf(title,x,top,contentW,"center")
    love.graphics.setFont(fonts.small);love.graphics.setColor(.70,.77,.68)
    love.graphics.printf(r.scoreAttack and("재생 "..tostring(r.highestRegenTier or r.regenTier or 1).."단계")or((r.stageCode or Maps.stageCode(r.mapId,r.stage)).."  ·  "..(r.bossName or"지역 보스")),x,top+48*scale,contentW,"center")

    local heroY=top+82*scale
    love.graphics.setColor(.006,.018,.013,.72);love.graphics.rectangle("fill",x+80,heroY,contentW-160,94*scale,7,7)
    love.graphics.setColor(1,.74,.24,.9);love.graphics.rectangle("fill",x+80,heroY,5,94*scale,3,3)
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.68,.74,.66);love.graphics.printf(r.scoreAttack and"생존 기록"or"작업 시간",x+80,heroY+15*scale,contentW-160,"center")
    love.graphics.setFont(fonts.display or fonts.big);love.graphics.setColor(1,.97,.84);love.graphics.printf(formatTime(r.elapsed),x+80,heroY+40*scale,contentW-160,"center")

    local statY=heroY+116*scale;local gap=10*scale;local statW=(contentW-gap*2)/3
    local stats=r.scoreAttack and{{"총 벌목",(r.trees or 0).."그루"},{"최고 생산",(r.peakTreesPerSecond or 0).."/초"},{"도달 레벨",r.level or 1}}or{{"총 벌목",(r.trees or 0).."그루"},{"확보 구역",(r.zonesSecured or 0).." / "..(r.zonesTotal or 0)},{"도달 레벨",r.level or 1}}
    for i,stat in ipairs(stats)do local sx=x+(i-1)*(statW+gap)
        love.graphics.setColor(.006,.018,.013,.70);love.graphics.rectangle("fill",sx,statY,statW,72*scale,5,5)
        love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.63,.70,.62);love.graphics.printf(stat[1],sx,statY+11*scale,statW,"center")
        love.graphics.setFont(fonts.heading);love.graphics.setColor(.96,.94,.80);love.graphics.printf(tostring(stat[2]),sx,statY+37*scale,statW,"center")
    end

    local rewardY=statY+92*scale
    love.graphics.setColor(.006,.018,.013,.80);love.graphics.rectangle("fill",x+110,rewardY,contentW-220,74*scale,6,6)
    love.graphics.setFont(fonts.small);love.graphics.setColor(.68,.75,.66);love.graphics.print("이번 작업 성과",x+134,rewardY+14*scale)
    love.graphics.setFont(fonts.big);love.graphics.setColor(.50,1,.62);love.graphics.printf("+"..tostring(r.traitEarned or 0).." P",x+110,rewardY+29*scale,contentW-244,"right")
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.62,.68,.60)
    love.graphics.printf("보유 "..tostring(r.traitCurrency or r.traitEarned or 0).." P",x+134,rewardY+46*scale,150,"left")

    local buttonH=50*scale;local buttonW=230*scale;local by=rewardY+96*scale;local bx=w/2-buttonW-8
    game.clearcutResultButtons={research={x=bx,y=by,w=buttonW,h=buttonH},retry={x=w/2+8,y=by,w=buttonW,h=buttonH}}
    HUDArt.resultButton(bx,by,buttonW,buttonH,"강화하기","T",fonts.small,"neutral",true)
    HUDArt.resultButton(w/2+8,by,buttonW,buttonH,"다시 도전","ENTER",fonts.small,"amber",true)
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.58,.64,.58);love.graphics.printf("ESC  로비",x,by+buttonH+16*scale,contentW,"center")
end
ClearcutMode.characters = {
    {id="physical", name="생계형 나무꾼", icon="axe", color={1,.42,.22},
        tagline="그냥 오늘 할당량을 채우러 온 것뿐이다.",
        detail="왜 이렇게까지 하냐고? 대출이 있다. 쉬지 않고 벨수록 손이 미친 듯이 빨라진다. 사거리 안에서 자동으로 가장 가까운 나무를 벱니다."},
    {id="fire", name="흡연자", icon="cigarette", color={1,.35,.12},
        tagline="담배꽁초 하나가 뭐 대수라고.",
        detail="마우스 위치에 꽁초를 튕깁니다. 날아가는 도중 스치는 적에게는 즉시 피해를 줍니다. 꽁초는 바닥에서 7초간 타들어가며 주변 나무에 기본 42%(최대 75%) 확률로 불씨를 옮깁니다. 날아간 불씨가 나무에 닿아야 불이 붙습니다."},
    {id="toxic", name="비건 단체 회장", icon="fork", color={.55,.85,.45},
        tagline="남기면 음식물 쓰레기다. 나무도 예외는 아니다.",
        detail="마우스 방향으로 커다란 포크를 찍습니다. 포크 타격으로 HP가 0이 된 나무는 캐릭터 쪽으로 끌려와 통째로 사라집니다. 포크 폭과 연속 식사 속도를 키우면 여러 그루를 빠르게 비울 수 있습니다."},
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
