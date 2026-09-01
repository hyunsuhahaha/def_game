-- 벌목 기록 모드의 1분 주기 세계수와 처치 보상.
--
-- 인게임 3택은 원래 목재 경험치로 열렸는데, 요구량이 선형(5+레벨*3)인데 수입은
-- 지수(재생 단계 1.75^n x 시간 압력 2^(초/30))로 늘어서 후반에 선택 창이 연달아
-- 떠 진행이 멈췄다. 그래서 통째로 제거됐다.
--
-- 여기서는 트리거를 목재가 아니라 **시간**으로 바꾼다. 수입이 아무리 폭증해도
-- 1분에 한 번이므로 그 사고가 구조적으로 재발할 수 없다.
--
-- 세계수는 공격하지 않는다. 기록 모드에는 플레이어 HP가 없어서 공격이 의미가
-- 없고, 캠페인의 공격 패턴·텔레그래프·등장 연출(6.75초)은 1분 주기에 맞지 않는다.
-- 여기서는 "치러 갈지 말지"를 고르게 하는 파괴 대상일 뿐이다.
local ScoreWorldTree = {}

ScoreWorldTree.INTERVAL = 60
ScoreWorldTree.BASE_HP = 260
ScoreWorldTree.TIER_HP = 1.18   -- 재생 단계마다 체력 배수
ScoreWorldTree.MIN_DISTANCE = 420

-- 판 한정 보상. 영구 연구와 겹치는 +N 수치는 넣지 않는다. 판당 두세 번뿐인 선택이
-- 로비에서 사는 것과 같은 종류면 멈춰 설 가치가 없다. 전부 규칙을 바꾼다.
ScoreWorldTree.rewards = {
    {id="dry_wind", name="마른 바람", desc="이번 작업 동안 불의 확산량이 두 배가 됩니다.",
        color={1,.52,.18}},
    {id="chain_ignition", name="연쇄 발화", desc="나무가 쓰러질 때 주변 나무 2그루에 불이 옮겨붙습니다.",
        color={1,.36,.14}},
    {id="cleave", name="벌목 특수", desc="도끼가 한 번에 나무 2그루를 더 벱니다.",
        color={.74,.80,.86}},
    {id="crew_rush", name="작업반 증원", desc="동료 전부의 이동속도와 공격속도가 두 배가 됩니다.",
        color={.94,.72,.34}},
    {id="permit", name="무허가 확장", desc="나무 허용량 +10. 대신 나무가 자라는 속도가 50% 빨라집니다.",
        color={.58,.78,.44}},
    {id="tinder", name="불쏘시개", desc="불의 타격 피해가 두 배. 대신 꽁초 착화 확률이 절반이 됩니다.",
        color={.98,.62,.24}},
    {id="deep_roots", name="깊은 뿌리", desc="목재 정산 수입이 이번 작업 동안 40% 증가합니다.",
        color={.96,.84,.40}},
}

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

-- 이미 고른 보상은 후보에서 빠진다. 남은 게 없으면 빈 목록을 돌려주고 호출부가
-- 선택 창을 열지 않는다.
function ScoreWorldTree.roll(mode, count)
    local pool = {}
    for _, def in ipairs(ScoreWorldTree.rewards) do
        if not ScoreWorldTree.has(mode, def.id) then pool[#pool+1] = def end
    end
    for i = #pool, 2, -1 do
        local j = love.math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local picked = {}
    for i = 1, math.min(count or 3, #pool) do picked[i] = pool[i] end
    return picked
end

function ScoreWorldTree.health(mode)
    local tier = math.max(1, math.floor(mode.scoreRegenTier or 1))
    return math.floor(ScoreWorldTree.BASE_HP * ScoreWorldTree.TIER_HP ^ (tier - 1) + .5)
end

return ScoreWorldTree
