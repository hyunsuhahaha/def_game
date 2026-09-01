-- 벌목 기록 모드의 40초 주기 세계수와 처치 보상.
--
-- 인게임 3택은 원래 목재 경험치로 열렸는데, 요구량이 선형(5+레벨*3)인데 수입은
-- 지수(재생 단계 1.75^n x 시간 압력 2^(초/30))로 늘어서 후반에 선택 창이 연달아
-- 떠 진행이 멈췄다. 그래서 통째로 제거됐다.
--
-- 여기서는 트리거를 목재가 아니라 **시간**으로 바꾼다. 수입이 아무리 폭증해도
-- 40초에 한 번이므로 그 사고가 구조적으로 재발할 수 없다.
--
-- 세계수는 공격하지 않는다. 기록 모드에는 플레이어 HP가 없어서 공격이 의미가
-- 없다. 1~9단계는 별도 성장형 세계수로 빠르게 솟고, 10단계부터만 완성형 거대
-- 세계수와 캠페인의 SKYVIEW·6.75초 등장 연출을 사용한다.
local ScoreWorldTree = {}

ScoreWorldTree.INTERVAL = 40
ScoreWorldTree.BASE_HP = 260
ScoreWorldTree.TIER_HP = 1.18   -- 재생 단계마다 체력 배수
-- 세계수는 항상 이동 가능 구역의 정중앙에 선다. 매번 다른 자리에 무작위로
-- 솟으면 화면 밖에서 조용히 자라 플레이어가 놓치고, 판마다 "어디에 있더라"를
-- 다시 찾아야 한다. 중앙 고정은 그 자체로 랜드마크가 되어 항상 같은 방향을 본다.
ScoreWorldTree.CENTER_SPAWN = true
ScoreWorldTree.GIANT_TIER = 10

-- 같은 그림을 단순 확대하지 않는다. 세 성장형은 서로 다른 가지·수관·뿌리 설계를
-- 가지며, 각 형 안에서만 작은 크기 보간을 해 단계가 매번 자라는 느낌을 준다.
local profiles = {
    {artKey="scoreWorldtreeYoung",artScale=1.20,radius=100,crownHeight=262},
    {artKey="scoreWorldtreeYoung",artScale=1.35,radius=115,crownHeight=295},
    {artKey="scoreWorldtreeYoung",artScale=1.50,radius=130,crownHeight=328},
    {artKey="scoreWorldtreeAdolescent",artScale=1.08,radius=138,crownHeight=344},
    {artKey="scoreWorldtreeAdolescent",artScale=1.20,radius=154,crownHeight=383},
    {artKey="scoreWorldtreeAdolescent",artScale=1.32,radius=172,crownHeight=421},
    {artKey="scoreWorldtreePrecursor",artScale=.98,radius=200,crownHeight=428},
    {artKey="scoreWorldtreePrecursor",artScale=1.10,radius=235,crownHeight=481},
    {artKey="scoreWorldtreePrecursor",artScale=1.28,radius=275,crownHeight=559},
}

function ScoreWorldTree.tier(modeOrTier)
    local value=type(modeOrTier)=="table" and modeOrTier.scoreRegenTier or modeOrTier
    return math.max(1,math.floor(value or 1))
end

function ScoreWorldTree.profile(modeOrTier)
    local tier=ScoreWorldTree.tier(modeOrTier)
    if tier>=ScoreWorldTree.GIANT_TIER then
        return {tier=tier,giant=true,artKey="worldtree",artScale=1,radius=420,crownHeight=960*1050/639}
    end
    local source=profiles[tier]
    return {tier=tier,giant=false,artKey=source.artKey,artScale=source.artScale,
        radius=source.radius,crownHeight=source.crownHeight}
end

-- 판 한정 보상. 영구 연구와 겹치는 +N 수치는 넣지 않는다. 판당 두세 번뿐인 선택이
-- 로비에서 사는 것과 같은 종류면 멈춰 설 가치가 없다. 전부 규칙을 바꾼다.
--
-- 7개짜리 풀에 작은 수치 증가만 있으면 매 판이 똑같아진다. 뱀파이어 서바이버즈가
-- 굴러가는 이유는 영구 강화가 아니라 진화·시너지로 "이번 판은 이런 판"이 만들어지기
-- 때문이다. 그래서 풀을 20개로 늘리고 축이 겹치는 것끼리 group 으로 묶는다.
--
-- **같은 group 은 판당 하나만 가질 수 있다.** 불의 성격을 정했으면 그 판은 그 불로
-- 간다. 배타성이 없으면 결국 전부 다 갖게 되고, 그러면 로비 연구와 다를 게 없다.
-- 한 번의 3택에도 같은 group 이 두 개 뜨지 않는다 — 실질 선택지가 줄기 때문이다.
--
-- 대가가 붙은 보상(cost)이 여럿 있는 이유는, 순수 상향만 있으면 "무엇을 포기할까"가
-- 없어서 고르는 행위 자체가 사라지기 때문이다.
ScoreWorldTree.rewards = {
    -- 불의 성격 — 확산이냐, 지속이냐, 속도냐.
    {id="dry_wind", group="fire", name="마른 바람", desc="불의 확산량이 두 배가 됩니다.",
        color={1,.52,.18}},
    {id="slow_burn", group="fire", name="뭉근한 불", desc="연소 시간이 두 배. 대신 불이 옮겨붙지 않습니다.",
        color={.94,.44,.22}},
    {id="flashover", group="fire", name="들불", desc="연소가 절반 시간에 끝나지만 훨씬 자주, 세게 태웁니다.",
        color={1,.70,.26}},

    -- 손의 역할 — 넓게냐, 확실하게냐, 무겁게냐.
    {id="cleave", group="hand", name="벌목 특수", desc="도끼가 한 번에 나무 2그루를 더 벱니다.",
        color={.74,.80,.86}},
    {id="undercut", group="hand", name="밑동 절단", desc="도끼질의 25%가 나무를 한 번에 쓰러뜨립니다.",
        color={.86,.88,.78}},
    {id="heavy_swing", group="hand", name="힘껏", desc="도끼 피해가 2.4배. 대신 휘두르는 속도가 느려집니다.",
        color={.68,.72,.80}},

    -- 숲과의 거래 — 허용량과 수입을 맞바꾼다.
    {id="permit", group="forest", name="무허가 확장", desc="나무 허용량 +10. 대신 나무가 자라는 속도가 50% 빨라집니다.",
        color={.58,.78,.44}},
    {id="quota", group="forest", name="할당량 감축", desc="나무가 자라는 속도가 40% 느려집니다. 대신 목재 수입이 25% 줄어듭니다.",
        color={.52,.70,.58}},
    {id="clear_cut", group="forest", name="좁고 깊게", desc="목재 수입이 50% 늘어납니다. 대신 나무 허용량이 4 줄어듭니다.",
        color={.72,.82,.40}},

    -- 자동화 — 손을 떠난 화력을 어디에 붙일까.
    {id="crew_rush", group="crew", name="작업반 증원", desc="동료 전부의 이동속도와 공격속도가 두 배가 됩니다.",
        color={.94,.72,.34}},
    {id="mole_pack", group="crew", name="두더지 무리", desc="두더지 동료가 두 마리 늘어납니다.",
        color={.80,.62,.42}},
    {id="drum_run", group="crew", name="드럼통 남발", desc="기름 드럼통이 두 배로 자주 떨어집니다.",
        color={.62,.60,.52}},

    -- 무기 개조 — 이번 판에 어느 무기를 키울지 하나만 고른다.
    {id="auto_carton", group="weapon", name="줄담배", desc="담배를 알아서 던지기 시작하고, 그 주기가 절반이 됩니다.",
        color={.86,.86,.78}},
    {id="wide_blast", group="weapon", name="큰 불꽃", desc="폭죽의 폭발 반경이 1.8배가 됩니다.",
        color={.98,.46,.62}},
    {id="flame_wall", group="weapon", name="화염 장벽", desc="화염 기둥이 훨씬 넓고 길어집니다.",
        color={1,.60,.20}},

    -- 규칙 자체를 바꾸는 것들.
    {id="chain_ignition", name="연쇄 발화", desc="나무가 쓰러질 때 주변 나무 2그루에 불이 옮겨붙습니다.",
        color={1,.36,.14}},
    {id="tinder", name="불쏘시개", desc="불의 타격 피해가 두 배. 대신 꽁초 착화 확률이 절반이 됩니다.",
        color={.98,.62,.24}},
    {id="deep_roots", name="깊은 뿌리", desc="목재 정산 수입이 40% 증가합니다.",
        color={.96,.84,.40}},
    {id="windfall", name="노다지", desc="벌목한 나무의 12%가 목재를 두 배로 냅니다.",
        color={1,.90,.52}},
    {id="second_tree", name="잦은 세계수", desc="세계수가 40% 더 자주 솟습니다. 보상을 더 고를 수 있습니다.",
        color={.56,.92,.66}},
}

-- 카드에 띄우는 축 이름. 배타성이 보이지 않으면 고르는 순간의 무게가 전달되지 않는다.
ScoreWorldTree.groupNames = {
    fire="불의 성격", hand="손의 역할", forest="숲과의 거래", crew="자동화",
    weapon="무기 개조",
}
function ScoreWorldTree.groupName(def)
    return def and def.group and ScoreWorldTree.groupNames[def.group] or nil
end

local byId = {}
for _, def in ipairs(ScoreWorldTree.rewards) do byId[def.id] = def end
function ScoreWorldTree.get(id) return byId[id] end

function ScoreWorldTree.reset(mode)
    mode.scoreWorldTreeTimer = ScoreWorldTree.INTERVAL
    mode.scoreWorldTree = nil
    mode.scoreRewards = {}
end

function ScoreWorldTree.has(mode, id)
    return (mode.scoreRewards or {})[id] == true
end

function ScoreWorldTree.grant(mode, id)
    mode.scoreRewards = mode.scoreRewards or {}
    mode.scoreRewards[id] = true
end

-- 이미 가진 group 은 통째로 잠긴다. 불의 성격을 정했으면 그 판은 그 불로 간다.
function ScoreWorldTree.groupTaken(mode, group)
    if not group then return false end
    for _, def in ipairs(ScoreWorldTree.rewards) do
        if def.group == group and ScoreWorldTree.has(mode, def.id) then return true end
    end
    return false
end

-- 이미 고른 보상과 잠긴 group 은 후보에서 빠진다. 남은 게 없으면 빈 목록을 돌려주고
-- 호출부가 선택 창을 열지 않는다.
function ScoreWorldTree.roll(mode, count)
    local pool = {}
    for _, def in ipairs(ScoreWorldTree.rewards) do
        if not ScoreWorldTree.has(mode, def.id) and not ScoreWorldTree.groupTaken(mode, def.group) then
            pool[#pool+1] = def
        end
    end
    for i = #pool, 2, -1 do
        local j = love.math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    -- 한 번의 3택에 같은 group 이 둘 뜨면 어차피 하나는 못 쓰므로 실질 선택지가 준다.
    local picked, offered = {}, {}
    for _, def in ipairs(pool) do
        if #picked >= (count or 3) then break end
        if not def.group or not offered[def.group] then
            picked[#picked+1] = def
            if def.group then offered[def.group] = true end
        end
    end
    return picked
end

function ScoreWorldTree.health(mode)
    local tier = ScoreWorldTree.tier(mode)
    return math.floor(ScoreWorldTree.BASE_HP * ScoreWorldTree.TIER_HP ^ (tier - 1) + .5)
end

return ScoreWorldTree
