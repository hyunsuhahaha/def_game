local ScoreOperations = {}

-- SCORE ATTACK ONLY. These cards reset every run and deliberately avoid
-- damage/range/cooldown bonuses. Permanent combat growth lives in the lobby.
ScoreOperations.definitions = {
    {id="baby_robot",track="supplement",name="아기 운반 로봇",desc="떨어진 목재를 찾아 즉시 목재 경험치로 회수합니다. 강화하면 로봇 수와 기본 기동력이 늘어납니다.",max=3,color={.40,.86,1},scoreOperation=true,sharedDraft=true},
    {id="robot_scanner",track="supplement",name="목재 탐지 안테나",desc="아기 로봇은 맵 전체의 목재를 항상 탐지합니다. 강화하면 이동속도가 증가합니다. 여러 로봇은 서로 다른 목재를 나눠 회수합니다.",max=3,color={.34,.78,1},scoreOperation=true},
    {id="yard_management",track="supplement",name="작업장 확장",desc="이번 작업의 나무 허용량이 단계마다 1그루 증가합니다.",max=3,color={.54,.76,.38},scoreOperation=true},
    {id="forest_zoning",track="supplement",name="조림 구획 지정",desc="새 나무가 가장자리보다 작업자 주변의 벌목 가능한 구역에 모여 자랍니다.",max=3,color={.38,.72,.34},scoreOperation=true},
    {id="wood_sorter",track="supplement",name="목재 선별기",desc="회수한 목재가 주는 경험치가 단계마다 15% 증가합니다.",max=3,color={.90,.68,.24},scoreOperation=true},
    {id="safety_system",track="supplement",name="안전 관리 장치",desc="나무가 허용량에 닿았을 때 과밀 판정 전 유예시간을 단계마다 0.25초 확보합니다.",max=3,color={.88,.48,.28},scoreOperation=true},
}

local byId={}
for _,definition in ipairs(ScoreOperations.definitions)do byId[definition.id]=definition end
function ScoreOperations.is(id)return byId[id]~=nil end
function ScoreOperations.get(id)return byId[id]end
function ScoreOperations.woodXpMultiplier(mode)return 1+(mode:levelOf("wood_sorter")*.15)end
function ScoreOperations.overcrowdGrace(mode)return mode:levelOf("safety_system")*.25 end

return ScoreOperations
