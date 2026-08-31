local CharacterTraits = {}
CharacterTraits.__index = CharacterTraits

local jobs = {
    physical = {
        currencyName="연구 코인",
        tagline="오늘 벤 나무만큼 오늘을 버틴다.",
        doctrine="체력과 도끼날을 갈아 넣어 정면에서 숲을 밀어낸다.",
        palette={.91,.47,.19},
        nodes={
            {id="physical_quota", name="일당제", short="출근 도장", desc="도끼질 속도 +7%", max=3, costs={18,32,50}, effect="attackSpeed", value=.07, x=.10,y=.50, icon="clock", color={.90,.55,.23}},
            {id="physical_axe", name="개인 장비 지참", short="내 도끼", desc="도끼 사거리 +14", max=3, costs={22,38,58}, effect="range", value=14, requires={{"physical_quota",1}}, x=.32,y=.28, icon="axe", color={.68,.72,.75}},
            {id="physical_waiver", name="산재 포기 각서", short="서명 완료", desc="최대 체력 +10", max=3, costs={22,38,58}, effect="maxHp", value=10, requires={{"physical_quota",1}}, x=.32,y=.72, icon="document", color={.78,.66,.47}},
            {id="physical_sharpen", name="점심시간 숫돌질", short="날 세우기", desc="도끼 타격 범위 +8", max=3, costs={28,46,68}, effect="area", value=8, requires={{"physical_axe",1}}, x=.56,y=.20, icon="sharpen", color={.52,.76,.83}},
            {id="physical_overtime", name="무급 연장근무", short="해 질 때까지", desc="도끼질 속도 +5%", max=3, costs={28,46,68}, effect="attackSpeed", value=.05, requires={{"physical_waiver",1}}, x=.56,y=.80, icon="moon", color={.57,.62,.78}},
            {id="physical_splinter", name="쐐기 두 개 박기", short="동시 벌목", desc="한 번에 타격하는 나무 +1", max=2, costs={42,72}, effect="extraTargets", value=1, requires={{"physical_sharpen",2}}, x=.68,y=.08, icon="split", color={.77,.58,.30}},
            {id="physical_grip", name="굳은살 손잡이", short="묵직한 한 방", desc="도끼 피해 +1", max=3, costs={34,54,78}, effect="treeDamage", value=1, requires={{"physical_sharpen",1}}, x=.70,y=.30, icon="fist", color={.72,.43,.25}},
            {id="physical_lunchbox", name="식은 도시락", short="쓰러지면 한입", desc="나무를 벨 때 체력 +1", max=3, costs={34,54,78}, effect="healOnFell", value=1, requires={{"physical_overtime",1}}, x=.70,y=.70, icon="lunch", color={.62,.72,.42}},
            {id="physical_severance", name="퇴직금 선지급", short="밑동 절단", desc="타격 시 4% 확률로 즉시 벌목", max=3, costs={42,66,92}, effect="executeChance", value=.04, requires={{"physical_overtime",2}}, x=.68,y=.92, icon="stump", color={.76,.33,.20}},
            {id="physical_report", name="초과 달성 보고서", short="할당량 초과", desc="런 종료 연구 코인 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"physical_sharpen",1},{"physical_overtime",1}}, x=.78,y=.50, icon="report", color={.94,.66,.22}},
            {id="physical_union", name="노조 없는 현장", short="최종 잔업", desc="도끼 타격 범위 +36", max=1, costs={110}, effect="area", value=36, requires={{"physical_report",3}}, x=.94,y=.50, icon="capstone", color={.95,.32,.18}, capstone=true}
        }
    },
    fire = {
        currencyName="연구 코인",
        tagline="불씨 하나쯤은 자연이 알아서 처리하겠지.",
        doctrine="긴 흡연 준비 끝에 꽁초를 날려 넓은 숲을 연쇄 점화한다.",
        palette={.82,.28,.22},
        nodes={
            {id="fire_nicotine", name="니코틴 내성", short="한 모금 더", desc="흡연·투척 속도 +7%", max=3, costs={18,32,50}, effect="attackSpeed", value=.07, x=.10,y=.50, icon="cigarette", color={.80,.76,.67}},
            {id="fire_filter", name="장초 필터", short="끝까지 태우기", desc="꽁초 투척 사거리 +24", max=3, costs={22,38,58}, effect="range", value=24, requires={{"fire_nicotine",1}}, x=.32,y=.28, icon="filter", color={.91,.66,.32}},
            {id="fire_warning", name="건조주의보 무시", short="습도 18%", desc="착화 범위 +12", max=3, costs={22,38,58}, effect="area", value=12, requires={{"fire_nicotine",1}}, x=.32,y=.72, icon="warning", color={.88,.37,.19}},
            {id="fire_wind", name="풍향 확인 생략", short="맞바람 투척", desc="꽁초 투척 사거리 +18", max=3, costs={28,46,68}, effect="range", value=18, requires={{"fire_filter",1}}, x=.56,y=.20, icon="wind", color={.48,.70,.74}},
            {id="fire_ashtray", name="휴대용 재떨이 분실", short="바닥이 재떨이", desc="착화 범위 +9", max=3, costs={28,46,68}, effect="area", value=9, requires={{"fire_warning",1}}, x=.56,y=.80, icon="ash", color={.55,.52,.50}},
            {id="fire_deep_drag", name="필터까지 태우기", short="깊은 한 모금", desc="나무가 타는 시간 -8%", max=3, costs={34,54,78}, effect="burnSpeed", value=.08, requires={{"fire_wind",1}}, x=.70,y=.30, icon="ember", color={.96,.43,.16}},
            {id="fire_pack", name="한 갑째 개봉", short="꽁초 추가", desc="투척 시 추가 불씨 +1", max=2, costs={48,82}, effect="extraFires", value=1, requires={{"fire_wind",2}}, x=.68,y=.08, icon="pack", color={.78,.24,.18}},
            {id="fire_secondhand", name="간접흡연 구역", short="연기 확산", desc="초당 불 확산 확률 +4%", max=3, costs={34,54,78}, effect="spreadChance", value=.04, requires={{"fire_ashtray",1}}, x=.70,y=.70, icon="smoke", color={.62,.65,.65}},
            {id="fire_insurance", name="화재보험 가입 직후", short="보상 준비", desc="런 종료 연구 코인 +6%", max=3, costs={42,66,92}, effect="reward", value=.06, requires={{"fire_ashtray",2}}, x=.68,y=.92, icon="policy", color={.74,.61,.35}},
            {id="fire_denial", name="인과관계 불분명", short="증거 불충분", desc="런 종료 연구 코인 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"fire_wind",1},{"fire_ashtray",1}}, x=.78,y=.50, icon="question", color={.69,.53,.72}},
            {id="fire_chain", name="연쇄 실화", short="최종 불씨", desc="흡연·투척 속도 +18%", max=1, costs={110}, effect="attackSpeed", value=.18, requires={{"fire_denial",3}}, x=.94,y=.50, icon="capstone", color={1,.27,.09}, capstone=true}
        }
    },
    toxic = {
        currencyName="연구 코인",
        tagline="남기면 음식물 쓰레기다. 나무도 예외는 아니다.",
        doctrine="대왕 포크로 밑동을 찍고 마지막 타격에 나무를 통째로 비운다.",
        palette={.38,.68,.27},
        nodes={
            {id="toxic_raw", name="빈속 출근", short="첫 접시", desc="포크질 속도 +7%", max=3, costs={18,32,50}, effect="attackSpeed", value=.07, x=.10,y=.50, icon="fork", color={.55,.86,.30}},
            {id="toxic_tongs", name="긴 포크 손잡이", short="멀리 찍기", desc="포크 사거리 +20", max=3, costs={22,38,58}, effect="range", value=20, requires={{"toxic_raw",1}}, x=.32,y=.28, icon="tongs", color={.68,.78,.72}},
            {id="toxic_cert", name="넓은 네 갈래", short="옆 접시까지", desc="포크 타격 폭 +12", max=3, costs={22,38,58}, effect="area", value=12, requires={{"toxic_raw",1}}, x=.32,y=.72, icon="split", color={.34,.76,.62}},
            {id="toxic_molar", name="손목 스냅", short="깊게 찍기", desc="포크 타격 폭 +8", max=3, costs={28,46,68}, effect="area", value=8, requires={{"toxic_tongs",1}}, x=.56,y=.20, icon="fist", color={.86,.78,.46}},
            {id="toxic_delivery", name="접시 앞으로 당기기", short="내 자리로", desc="포크 사거리 +16", max=3, costs={28,46,68}, effect="range", value=16, requires={{"toxic_cert",1}}, x=.56,y=.80, icon="basket", color={.72,.48,.25}},
            {id="toxic_protein", name="스테인리스 강화", short="단단한 포크", desc="포크 피해 +1", max=3, costs={34,54,78}, effect="biteDamage", value=1, requires={{"toxic_molar",1}}, x=.70,y=.30, icon="sharpen", color={.87,.82,.70}},
            {id="toxic_buffet_coupon", name="포크 두 개 들기", short="양손 식사", desc="동시 타격 나무 +1", max=2, costs={48,82}, effect="extraTargets", value=1, requires={{"toxic_molar",2}}, x=.68,y=.08, icon="split", color={.72,.38,.62}},
            {id="toxic_compost", name="깨끗한 접시", short="남김 없음", desc="나무를 먹을 때 체력 +1", max=3, costs={34,54,78}, effect="healOnFell", value=1, requires={{"toxic_delivery",1}}, x=.70,y=.70, icon="heartleaf", color={.38,.78,.46}},
            {id="toxic_manifesto", name="씹는 시간 단축", short="바로 삼키기", desc="포크질 속도 +8%", max=3, costs={42,66,92}, effect="attackSpeed", value=.08, requires={{"toxic_delivery",2}}, x=.68,y=.92, icon="clock", color={.68,.72,.84}},
            {id="toxic_sponsor", name="후원금 사용 내역 비공개", short="영수증 없음", desc="런 종료 연구 코인 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"toxic_molar",1},{"toxic_delivery",1}}, x=.78,y=.50, icon="donation", color={.86,.62,.27}},
            {id="toxic_buffet", name="숲 전체 뷔페", short="최종 접시", desc="포크 타격 폭 +34", max=1, costs={110}, effect="area", value=34, requires={{"toxic_sponsor",3}}, x=.94,y=.50, icon="capstone", color={.25,.82,.28}, capstone=true}
        }
    },
    developer = {
        currencyName="연구 코인",
        tagline="나무가 보이면 아직 용적률이 남았다는 뜻이다.",
        doctrine="행정과 중장비를 동시에 밀어붙여 긴 직선의 숲을 개발 부지로 만든다.",
        palette={.28,.58,.76},
        nodes={
            {id="developer_permit", name="신속 인허가", short="도장 먼저", desc="리모컨 조작 속도 +7%", max=3, costs={18,32,50}, effect="attackSpeed", value=.07, x=.10,y=.50, icon="stamp", color={.85,.35,.30}},
            {id="developer_boundary", name="측량 오차", short="경계선 이동", desc="돌진 거리 +25", max=3, costs={22,38,58}, effect="range", value=25, requires={{"developer_permit",1}}, x=.32,y=.28, icon="ruler", color={.87,.70,.30}},
            {id="developer_machinery", name="중장비 추가 투입", short="장비 증차", desc="돌진 폭 +10", max=3, costs={22,38,58}, effect="area", value=10, requires={{"developer_permit",1}}, x=.32,y=.72, icon="machine", color={.88,.48,.20}},
            {id="developer_rezone", name="녹지 용도변경", short="선 하나 수정", desc="돌진 거리 +20", max=3, costs={28,46,68}, effect="range", value=20, requires={{"developer_boundary",1}}, x=.56,y=.20, icon="map", color={.38,.70,.65}},
            {id="developer_subcontract", name="하청의 재하청", short="인력 복사", desc="리모컨 조작 속도 +5%", max=3, costs={28,46,68}, effect="attackSpeed", value=.05, requires={{"developer_machinery",1}}, x=.56,y=.80, icon="helmet", color={.94,.67,.18}},
            {id="developer_expressway", name="진입도로 우선 개통", short="중장비 과속", desc="돌진 속도 +10%", max=3, costs={34,54,78}, effect="dashSpeed", value=.10, requires={{"developer_rezone",1}}, x=.70,y=.30, icon="road", color={.48,.58,.66}},
            {id="developer_greenbelt", name="그린벨트 해제", short="빈 땅 확보", desc="벌목지가 불모지가 될 확률 +12%", max=3, costs={42,66,92}, effect="sterileChance", value=.12, requires={{"developer_rezone",2}}, x=.68,y=.08, icon="map", color={.42,.68,.40}},
            {id="developer_changeorder", name="설계변경 17차", short="끝점 폭파", desc="돌진 종료 폭발 범위 +18", max=3, costs={34,54,78}, effect="aftershockRadius", value=18, requires={{"developer_subcontract",1}}, x=.70,y=.70, icon="blast", color={.92,.42,.18}},
            {id="developer_advance", name="공사대금 선지급", short="바로 재투입", desc="돌진 쿨다운 초기화 확률 +7%", max=3, costs={42,66,92}, effect="cooldownRefund", value=.07, requires={{"developer_subcontract",2}}, x=.68,y=.92, icon="coins", color={.88,.68,.24}},
            {id="developer_presale", name="사전분양 완판", short="모형도 매진", desc="런 종료 연구 코인 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"developer_rezone",1},{"developer_subcontract",1}}, x=.78,y=.50, icon="tower", color={.47,.65,.82}},
            {id="developer_expropriate", name="공익사업 강제수용", short="최종 고시", desc="돌진 폭 +32", max=1, costs={110}, effect="area", value=32, requires={{"developer_presale",3}}, x=.94,y=.50, icon="capstone", color={.20,.63,.92}, capstone=true}
        }
    },
    miner = {
        currencyName="연구 코인",
        tagline="그 삽질이 언젠가는 하드월렛을 찾아줄 것이다.",
        doctrine="탐지와 발굴을 번갈아 밀어붙여 넓은 구역을 통째로 파헤친다.",
        palette={.85,.68,.22},
        nodes={
            {id="miner_signal", name="탐지 신호음", short="삐빅", desc="삽질 속도 +7%", max=3, costs={18,32,50}, effect="attackSpeed", value=.07, x=.10,y=.50, icon="clock", color={.85,.68,.22}},
            {id="miner_coil", name="코일 감도 조정", short="더 멀리 삐빅", desc="탐지 사거리 +14", max=3, costs={22,38,58}, effect="range", value=14, requires={{"miner_signal",1}}, x=.32,y=.28, icon="ruler", color={.80,.72,.40}},
            {id="miner_knee", name="무릎 보호대", short="장시간 굴착", desc="최대 체력 +10", max=3, costs={22,38,58}, effect="maxHp", value=10, requires={{"miner_signal",1}}, x=.32,y=.72, icon="helmet", color={.60,.50,.35}},
            {id="miner_headphone", name="고급 헤드폰", short="잡음 제거", desc="굴착 범위 +8", max=3, costs={28,46,68}, effect="area", value=8, requires={{"miner_coil",1}}, x=.56,y=.20, icon="stamp", color={.90,.78,.35}},
            {id="miner_overnight", name="야간 무허가 발굴", short="달빛 삽질", desc="삽질 속도 +5%", max=3, costs={28,46,68}, effect="attackSpeed", value=.05, requires={{"miner_knee",1}}, x=.56,y=.80, icon="moon", color={.55,.58,.70}},
            {id="miner_dualdetector", name="듀얼 탐지기", short="양손 탐지", desc="동시 굴착 지점 +1", max=2, costs={42,72}, effect="extraTargets", value=1, requires={{"miner_headphone",2}}, x=.68,y=.08, icon="split", color={.78,.60,.28}},
            {id="miner_titanium", name="티타늄 삽날", short="더 깊이", desc="굴착 피해 +1", max=3, costs={34,54,78}, effect="treeDamage", value=1, requires={{"miner_headphone",1}}, x=.70,y=.30, icon="fist", color={.72,.66,.60}},
            {id="miner_thermos", name="식은 보온병 커피", short="한 모금", desc="굴착 시 체력 +1", max=3, costs={34,54,78}, effect="healOnFell", value=1, requires={{"miner_overnight",1}}, x=.70,y=.70, icon="lunch", color={.62,.50,.30}},
            {id="miner_permit", name="발굴허가 없음", short="일단 판다", desc="'발견' 판정 확률 +4%", max=3, costs={42,66,92}, effect="executeChance", value=.04, requires={{"miner_overnight",2}}, x=.68,y=.92, icon="warning", color={.85,.45,.20}},
            {id="miner_gpscoord", name="그때 그 GPS 좌표", short="기억 재구성", desc="런 종료 연구 코인 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"miner_headphone",1},{"miner_overnight",1}}, x=.78,y=.50, icon="map", color={.92,.70,.25}},
            {id="miner_landrights", name="산 전체 매입 시도", short="최종 발굴", desc="굴착 범위 +36", max=1, costs={110}, effect="area", value=36, requires={{"miner_gpscoord",3}}, x=.94,y=.50, icon="capstone", color={1,.80,.20}, capstone=true}
        }
    },
    philosopher = {
        currencyName="연구 코인",
        tagline="태어난 것 자체가 형벌이다. 나는 그저 해방시켜줄 뿐이다.",
        doctrine="그칠 줄 모르는 일장연설과 침으로 넓은 숲을 계속 '해방'시킨다.",
        palette={.75,.90,.35},
        nodes={
            {id="philosopher_soliloquy", name="독백 연습", short="아무도 안 듣는데", desc="장광설 속도 +7%", max=3, costs={18,32,50}, effect="attackSpeed", value=.07, x=.10,y=.50, icon="question", color={.75,.85,.30}},
            {id="philosopher_lungs", name="폐활량 단련", short="숨 안 쉬고 말하기", desc="침 사거리 +14", max=3, costs={22,38,58}, effect="range", value=14, requires={{"philosopher_soliloquy",1}}, x=.32,y=.28, icon="wind", color={.70,.82,.35}},
            {id="philosopher_thickskin", name="비난에 대한 초연함", short="욕먹어도 상관없다", desc="최대 체력 +10", max=3, costs={22,38,58}, effect="maxHp", value=10, requires={{"philosopher_soliloquy",1}}, x=.32,y=.72, icon="helmet", color={.55,.65,.40}},
            {id="philosopher_footnotes", name="각주와 방점", short="말이 곁가지를 침", desc="침 범위 +8", max=3, costs={28,46,68}, effect="area", value=8, requires={{"philosopher_lungs",1}}, x=.56,y=.20, icon="document", color={.80,.88,.40}},
            {id="philosopher_allnighter", name="밤샘 토론회", short="새벽까지 붙잡기", desc="장광설 속도 +5%", max=3, costs={28,46,68}, effect="attackSpeed", value=.05, requires={{"philosopher_thickskin",1}}, x=.56,y=.80, icon="moon", color={.50,.55,.60}},
            {id="philosopher_crowd", name="지나가는 행인 붙잡기", short="양손으로 붙듦", desc="동시에 붙잡는 대상 +1", max=2, costs={42,72}, effect="extraTargets", value=1, requires={{"philosopher_footnotes",2}}, x=.68,y=.08, icon="split", color={.68,.78,.32}},
            {id="philosopher_venomtongue", name="독설 훈련", short="말이 더 따갑다", desc="침 피해 +1", max=3, costs={34,54,78}, effect="biteDamage", value=1, requires={{"philosopher_footnotes",1}}, x=.70,y=.30, icon="tooth", color={.62,.75,.28}},
            {id="philosopher_martyrdom", name="순교자 코스프레", short="말할수록 강해짐", desc="설파 성공 시 체력 +1", max=3, costs={34,54,78}, effect="healOnFell", value=1, requires={{"philosopher_allnighter",1}}, x=.70,y=.70, icon="heartleaf", color={.50,.70,.40}},
            {id="philosopher_manifesto_base", name="자비출판 선언문", short="800쪽짜리", desc="중독 지속시간 +0.8초", max=3, costs={42,66,92}, effect="plagueDuration", value=.8, requires={{"philosopher_allnighter",2}}, x=.68,y=.92, icon="policy", color={.58,.68,.30}},
            {id="philosopher_cultfollow", name="추종자 세 명 확보", short="믿음의 증거", desc="런 종료 연구 코인 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"philosopher_footnotes",1},{"philosopher_allnighter",1}}, x=.78,y=.50, icon="donation", color={.85,.75,.30}},
            {id="philosopher_finalsermon", name="최후의 설파", short="최종 해방", desc="침 범위 +34", max=1, costs={110}, effect="area", value=34, requires={{"philosopher_cultfollow",3}}, x=.94,y=.50, icon="capstone", color={.70,1,.25}, capstone=true}
        }
    }
}

-- 한 화면짜리 메뉴가 아니라 실제로 탐색하는 연구 월드를 만들기 위한 확장 분기.
-- 공통 좌표 골격을 쓰되, 노드의 명칭/효과/선행 관계는 캐릭터별 플레이 방식에 맞춰 전부 다르게 설계했다.
local expansionPositions = {
    {720,360},{1050,190},{1120,430},{1410,145},{1490,390},{1760,260},
    {720,1540},{1050,1710},{1120,1470},{1410,1750},{1490,1510},{1760,1640},
    {1980,760},{2260,540},{2260,960},{2530,410},{2530,1090},{2820,750},{3100,750}
}

local function expand(job, definitions)
    for index, definition in ipairs(definitions) do
        local position=expansionPositions[index]
        local max=definition.max or 3
        jobs[job].nodes[#jobs[job].nodes+1]={
            id=definition.id,name=definition.name,short=definition.short,desc=definition.desc,
            effect=definition.effect,value=definition.value,requires=definition.requires,
            wx=definition.wx or position[1],wy=definition.wy or position[2],icon=definition.icon or "capstone",color=definition.color,
            max=max,costs=definition.costs or (max==1 and {135} or max==2 and {48,86} or {36,62,94}),
            capstone=definition.capstone,scoreMode=definition.scoreMode
        }
    end
end

expand("physical",{
    {id="physical_boots",name="현장 안전화 자비 구매",short="미끄럼 방지",desc="최대 체력 +8",effect="maxHp",value=8,requires={{"physical_axe",2}},icon="helmet",color={.62,.55,.42}},
    {id="physical_whetstone",name="편의점 숫돌",short="급한 연마",desc="도끼 피해 +1",effect="treeDamage",value=1,requires={{"physical_boots",1}},icon="sharpen",color={.52,.72,.78}},
    {id="physical_longhaft",name="연장 손잡이 테이핑",short="긴 자루",desc="도끼 사거리 +12",effect="range",value=12,requires={{"physical_boots",1}},icon="axe",color={.68,.57,.36}},
    {id="physical_grain",name="목재 결 읽기",short="약점 파악",desc="즉시 벌목 확률 +3%",effect="executeChance",value=.03,requires={{"physical_whetstone",2}},icon="stump",color={.72,.36,.20}},
    {id="physical_two_jobs",name="두 사람 몫 혼자 하기",short="인원 절감",desc="동시 타격 나무 +1",effect="extraTargets",value=1,requires={{"physical_longhaft",2}},icon="split",color={.86,.54,.22},max=2},
    {id="physical_piecework",name="건당 수당 계약",short="상단 전문화",desc="도끼 피해 +2",effect="treeDamage",value=2,requires={{"physical_grain",2},{"physical_two_jobs",2}},icon="capstone",color={1,.48,.16},max=1,capstone=true},
    {id="physical_coffee",name="캔커피 두 캔",short="카페인 노동",desc="도끼질 속도 +4%",effect="attackSpeed",value=.04,requires={{"physical_waiver",2}},icon="lunch",color={.52,.40,.28}},
    {id="physical_backbelt",name="허리 보호대 돌려쓰기",short="허리 고정",desc="최대 체력 +9",effect="maxHp",value=9,requires={{"physical_coffee",1}},icon="helmet",color={.48,.58,.62}},
    {id="physical_foreman",name="작업반장 눈치",short="손이 빨라짐",desc="도끼질 속도 +5%",effect="attackSpeed",value=.05,requires={{"physical_coffee",1}},icon="clock",color={.84,.53,.24}},
    {id="physical_scrapshield",name="폐목재 방패",short="임시 방호",desc="최대 체력 +12",effect="maxHp",value=12,requires={{"physical_backbelt",2}},icon="document",color={.55,.66,.48}},
    {id="physical_route",name="왕복 없는 작업 동선",short="동선 단축",desc="도끼 사거리 +10",effect="range",value=10,requires={{"physical_foreman",2}},icon="road",color={.45,.63,.70}},
    {id="physical_meal",name="잔업 식대 청구",short="하단 전문화",desc="벌목 시 체력 +3",effect="healOnFell",value=3,requires={{"physical_scrapshield",2},{"physical_route",2}},icon="capstone",color={.58,.78,.32},max=1,capstone=true},
    {id="physical_kpi",name="분기별 벌목 KPI",short="목표 재설정",desc="연구 코인 +7%",effect="reward",value=.07,requires={{"physical_report",2}},icon="report",color={.88,.62,.20}},
    {id="physical_hydraulic",name="유압 도끼 불법 개조",short="압력 상승",desc="도끼 피해 +1",effect="treeDamage",value=1,requires={{"physical_kpi",1}},icon="machine",color={.66,.72,.74}},
    {id="physical_sawback",name="톱날 겸용 도끼",short="넓은 절단",desc="타격 범위 +10",effect="area",value=10,requires={{"physical_kpi",1}},icon="axe",color={.72,.46,.25}},
    {id="physical_nohire",name="인력 충원 계획 없음",short="혼자 두 배",desc="동시 타격 나무 +1",effect="extraTargets",value=1,requires={{"physical_hydraulic",2}},icon="split",color={.84,.40,.18},max=2},
    {id="physical_erasure",name="산재 기록 말소",short="기록 없음",desc="즉시 벌목 확률 +4%",effect="executeChance",value=.04,requires={{"physical_sawback",2}},icon="document",color={.65,.42,.50}},
    {id="physical_employee",name="분기 최우수 사원",short="실적 독식",desc="연구 코인 +12%",effect="reward",value=.12,requires={{"physical_nohire",2},{"physical_erasure",2}},icon="report",color={.96,.66,.18},max=1,capstone=true},
    {id="physical_lifetime",name="정년 없는 평생 현역",short="최종 노동",desc="도끼질 속도 +22%",effect="attackSpeed",value=.22,requires={{"physical_employee",1}},icon="capstone",color={1,.30,.12},max=1,capstone=true,costs={190}}
})

expand("fire",{
    {id="fire_padding",name="담뱃불 구멍 난 패딩",short="불씨 내성",desc="최대 체력 +8",effect="maxHp",value=8,requires={{"fire_filter",2}},icon="helmet",color={.48,.40,.38}},
    {id="fire_longfinger",name="유난히 긴 검지",short="멀리 튕기기",desc="꽁초 사거리 +16",effect="range",value=16,requires={{"fire_padding",1}},icon="cigarette",color={.78,.68,.54}},
    {id="fire_stormlighter",name="폭풍 방지 라이터",short="불씨 고정",desc="불 확산 확률 +3%",effect="spreadChance",value=.03,requires={{"fire_padding",1}},icon="ember",color={.92,.46,.16}},
    {id="fire_chain_drag",name="두 모금 연속 흡입",short="연속 흡입",desc="흡연 속도 +5%",effect="attackSpeed",value=.05,requires={{"fire_longfinger",2}},icon="smoke",color={.64,.66,.68}},
    {id="fire_sparepack",name="주머니 속 예비 갑",short="불씨 비축",desc="추가 불씨 +1",effect="extraFires",value=1,requires={{"fire_stormlighter",2}},icon="pack",color={.82,.28,.16},max=2},
    {id="fire_rooftop",name="옥상 흡연구역 폐쇄",short="상단 전문화",desc="착화 범위 +26",effect="area",value=26,requires={{"fire_chain_drag",2},{"fire_sparepack",2}},icon="capstone",color={1,.33,.08},max=1,capstone=true},
    {id="fire_cough",name="기침으로 불씨 날리기",short="기침 확산",desc="불 확산 확률 +3%",effect="spreadChance",value=.03,requires={{"fire_warning",2}},icon="wind",color={.58,.67,.68}},
    {id="fire_hotash",name="뜨거운 재 털기",short="잔불 유지",desc="연소 속도 +6%",effect="burnSpeed",value=.06,requires={{"fire_cough",1}},icon="ash",color={.62,.54,.48}},
    {id="fire_drymouth",name="입안까지 건조주의보",short="완전 건조",desc="연소 속도 +7%",effect="burnSpeed",value=.07,requires={{"fire_cough",1}},icon="warning",color={.86,.42,.18}},
    {id="fire_nosign",name="금연 표지판 뒤집기",short="표지 무시",desc="연구 코인 +6%",effect="reward",value=.06,requires={{"fire_hotash",2}},icon="document",color={.72,.40,.36}},
    {id="fire_balcony",name="베란다 투척 숙련",short="포물선 숙련",desc="꽁초 사거리 +20",effect="range",value=20,requires={{"fire_drymouth",2}},icon="wind",color={.45,.65,.76}},
    {id="fire_fireline",name="산불 방화선 역이용",short="하단 전문화",desc="불 확산 확률 +10%",effect="spreadChance",value=.10,requires={{"fire_nosign",2},{"fire_balcony",2}},icon="capstone",color={.94,.50,.12},max=1,capstone=true},
    {id="fire_carton",name="면세점 보루 구매",short="불씨 재고",desc="추가 불씨 +1",effect="extraFires",value=1,requires={{"fire_denial",2}},icon="pack",color={.68,.30,.24},max=2},
    {id="fire_tailwind",name="계절풍 흡연 지침",short="순풍 투척",desc="꽁초 사거리 +18",effect="range",value=18,requires={{"fire_carton",1}},icon="wind",color={.44,.68,.72}},
    {id="fire_resin",name="송진 묻은 필터",short="고열 필터",desc="연소 속도 +8%",effect="burnSpeed",value=.08,requires={{"fire_carton",1}},icon="filter",color={.78,.54,.24}},
    {id="fire_emberstorm",name="불씨 폭풍",short="불씨 증식",desc="추가 불씨 +1",effect="extraFires",value=1,requires={{"fire_tailwind",2}},icon="ember",color={1,.34,.08},max=2},
    {id="fire_press",name="언론 대응 매뉴얼",short="원인 부인",desc="연구 코인 +9%",effect="reward",value=.09,requires={{"fire_resin",2}},icon="policy",color={.62,.55,.66}},
    {id="fire_claim",name="실화 책임 전면 부인",short="책임 없음",desc="연구 코인 +14%",effect="reward",value=.14,requires={{"fire_emberstorm",2},{"fire_press",2}},icon="question",color={.82,.42,.60},max=1,capstone=true},
    {id="fire_redsky",name="하늘이 붉은 건 노을",short="최종 산불",desc="착화 범위 +42",effect="area",value=42,requires={{"fire_claim",1}},icon="capstone",color={1,.18,.04},max=1,capstone=true,costs={190}}
})

-- 벌목 기록 모드의 개인 장비 특성. 인게임 스킬 레벨을 통째로 선구매하지 않고
-- 투척·착화·확산·연소의 작은 수치를 갈래별로 올린다. 기존 ID는 저장 호환을
-- 위해 유지하되 scoreSkill 연결은 두지 않는다.
-- 일반 흡연자 연구는 삭제하지 않고 저장 호환을 위해 위에 그대로 보존한다.
local scoreFireNodes={
    {id="fire_score_prewarm",name="출근 전 라이터 예열",short="첫 불씨 단축",desc="벌목 기록 모드 최초 흡연 준비시간 -0.08초",effect="scoreInitialIgnitionReduction",value=.08,wx=390,wy=710,icon="ember",color={1,.48,.12}},
    {id="fire_score_filter",name="긴 필터 밀어 던지기",short="무기 사거리",desc="무기 사거리 +16",effect="scoreRange",value=16,max=6,costs={18,32,50,74,104,142},wx=730,wy=520,icon="filter",color={.88,.66,.32},requires={{"fire_score_prewarm",1}}},
    {id="fire_score_lighter",name="불씨 반경 넓히기",short="착화 범위",desc="꽁초가 불씨를 옮기는 착화 반경 +12",effect="scoreArea",value=12,max=6,costs={18,32,50,74,104,142},wx=730,wy=900,icon="ember",color={.96,.43,.16},requires={{"fire_score_prewarm",1}}},
    {id="fire_score_spark",name="심지 끝까지 달구기",short="착화 확률",desc="꽁초의 착화 성공 확률 +1.2%p",effect="scoreIgnitionChance",value=.012,wx=1080,wy=380,icon="ember",color={1,.56,.16},requires={{"fire_score_filter",2}}},
    {id="fire_score_launch",name="손가락 튕기기 연습",short="비행 속도",desc="꽁초 비행 속도 +7%",effect="scoreProjectileSpeed",value=.07,wx=1080,wy=650,icon="wind",color={.82,.72,.42},requires={{"fire_score_prewarm",1}}},
    -- 값은 초당 확률 단위로 저장하고 런타임이 기준 연소시간(3.6초)을 곱해 "옮겨붙는
    -- 기대 그루 수"로 쓴다. 0레벨 0.43그루 → 6레벨 1.45그루로, 만렙이 임계점 1.00을
    -- 확실히 넘겨 산불이 스스로 번지게 한다.
    {id="fire_score_ash",name="마른 재 흩뿌리기",short="확산량",desc="불붙은 나무가 옮겨붙이는 기대 그루 +0.17 (만렙 1.45그루 — 1.00을 넘으면 산불이 스스로 번집니다)",effect="scoreSpreadChance",value=.047,max=6,costs={18,32,50,74,104,142},wx=1080,wy=940,icon="ash",color={.72,.52,.36},requires={{"fire_score_lighter",2}}},
    {id="fire_score_drag",name="한 모금만 피우기",short="공격속도",desc="무기 공격속도 +4%",effect="scoreAttackSpeed",value=.04,max=6,costs={18,32,50,74,104,142},wx=1430,wy=470,icon="clock",color={.78,.76,.67},requires={{"fire_score_launch",2}}},
    {id="fire_score_heat",name="송진 묻은 불씨",short="연소 속도",desc="불이 나무를 태우는 주기 6% 단축 (기본 1초마다 4피해, 연소 3.6초)",effect="scoreBurnSpeed",value=.06,max=6,costs={18,32,50,74,104,142},wx=1430,wy=820,icon="warning",color={1,.34,.08},requires={{"fire_score_prewarm",1}}},
    {id="fire_score_stock",name="주머니 속 마지막 한 개비",short="추가 꽁초",desc="투척할 때 추가 꽁초 +1",effect="scoreExtraFires",value=1,max=1,costs={180},wx=1780,wy=650,icon="pack",color={1,.30,.08},requires={{"fire_score_heat",3}},capstone=true},

    -- 무기 슬롯 공용 갈래. 공용 수치의 설명에는 무기 이름을 나열하지 않는다 —
    -- "무기 사거리", "무기 공격속도"처럼 공용 단어만 쓴다. 무기가 늘거나 바뀔 때마다
    -- 설명을 전부 고쳐야 하는 하드코딩을 피하기 위한 규칙이다. 특정 무기에만 걸리는
    -- 수치(도끼 범위, 폭죽 반경 등)는 그 무기 이름을 그대로 쓴다. 도끼는 3+treeDamage, 폭죽은
    -- 8+treeDamage*1.1로 피해를 계산하는데 기록 모드에는 treeDamage 노드가 하나도
    -- 없어서 두 무기의 주력 수치가 영구히 고정돼 있었다. 여기가 그 성장 경로다.
    {id="fire_score_edge",name="나무 피해 상승",short="무기 피해",desc="무기가 나무에 주는 타격 피해 +1",effect="scoreTreeDamage",value=1,max=5,costs={26,46,72,104,142},wx=390,wy=1120,icon="fist",color={.86,.62,.34},requires={{"fire_score_prewarm",1}}},

    -- 도끼 갈래. 이전에는 담배용 착화 범위(scoreArea)를 ×0.2로 얻어 쓰고 있어서
    -- 담배 특성을 사야 도끼가 자라는 기묘한 의존이 있었다. 전용 수치로 분리한다.
    {id="fire_score_axe_area",name="도끼 타격 범위 상승",short="도끼 범위",desc="도끼의 조준 포착 범위와 주변 타격 범위 +9",effect="scoreAxeArea",value=9,max=5,wx=730,wy=1320,icon="split",color={.72,.76,.80},requires={{"fire_score_edge",1}}},
    {id="fire_score_axe_speed",name="도끼 공격속도 상승",short="도끼 공속",desc="도끼 연속 타격 속도 +7%",effect="scoreAxeSpeed",value=.07,max=5,wx=730,wy=1640,icon="clock",color={.90,.72,.36},requires={{"fire_score_edge",1}}},
    {id="fire_score_axe_targets",name="도끼 동시 타격 나무 +1",short="동시 타격",desc="한 번의 도끼질이 조준 범위 안의 나무를 단계마다 1그루 더 때립니다",effect="scoreAxeTargets",value=1,max=2,costs={96,158},wx=380,wy=1470,icon="axe",color={.82,.52,.28},requires={{"fire_score_axe_area",3}}},
    {id="fire_score_axe_execute",name="도끼 밑동 절단 확률 상승",short="즉시 벌목",desc="도끼 타격이 단계마다 3% 확률로 나무를 체력과 무관하게 즉시 쓰러뜨립니다",effect="scoreAxeExecute",value=.03,max=4,costs={54,84,120,164},wx=380,wy=1790,icon="stump",color={.76,.33,.20},requires={{"fire_score_axe_speed",3}}},

    -- 폭죽 갈래. 폭발 반경도 담배용 scoreArea를 ×0.3으로 나눠 쓰고 있었고,
    -- 비행 속도(820)와 착탄 점화 확률(0.38)은 상수로 박혀 성장 자체가 불가능했다.
    -- 담배 갈래의 종착점. 여기서부터 손이 비고, 그 빈손이 폭죽 해금으로 이어진다.
    -- 자동 투척 루프 자체는 updateFire에 이미 있고(캠페인의 molotov 레벨용), 이 노드가
    -- 기록 모드에서 그 루프를 깨운다.
    -- 기본 흡연자는 담배를 손에 들어야만 한 모금 빨고 던진다. 다른 무기를 들면
    -- 재장전이 멈추므로, 슬롯을 바꿔 던지려면 매번 기다려야 한다. 이 특성을 찍으면
    -- 무엇을 들고 있든 계속 피우고 있어서 바꾸는 즉시 던질 수 있다.
    {id="fire_score_alwayssmoke",name="상시 흡연",short="상시 흡연",desc="다른 무기를 들고 있어도 계속 담배를 피웁니다. 담배로 바꾼 즉시 던질 수 있습니다.",effect="scoreAlwaysSmoking",value=1,max=1,costs={200},wx=2020,wy=760,icon="cigarette",color={.94,.72,.36},requires={{"fire_score_stock",1}},capstone=true},
    {id="fire_score_autothrow",name="담배 자동 투척",short="자동 투척",desc="어떤 무기를 들고 있든 2.6초마다 꽁초가 자동으로 날아갑니다. 담배를 직접 들면 수동 투척이 그 위에 더해집니다.",effect="scoreAutoThrow",value=1,max=1,costs={240},wx=2020,wy=900,icon="cigarette",color={1,.46,.14},requires={{"fire_score_alwayssmoke",1}},capstone=true},
    {id="fire_score_rocket_unlock",name="폭죽 로켓 해금",short="폭죽 해금",desc="3번 무기 슬롯에 폭죽 로켓이 열립니다. 담배가 알아서 날아가는 동안 손으로 쏘는 원거리 광역 무기입니다.",effect="scoreRocketUnlock",value=1,max=1,costs={260},wx=1150,wy=1250,icon="blast",color={1,.34,.10},requires={{"fire_score_autothrow",1}},capstone=true},
    {id="fire_score_rocket_radius",name="폭죽 폭발 반경 상승",short="폭발 반경",desc="폭죽 로켓의 폭발 반경 +16",effect="scoreRocketRadius",value=16,max=5,wx=1700,wy=1300,icon="blast",color={1,.52,.18},requires={{"fire_score_rocket_unlock",1}}},
    {id="fire_score_rocket_damage",name="폭죽 폭발 피해 상승",short="폭발 피해",desc="폭죽 폭발이 나무에 주는 피해 +2",effect="scoreRocketDamage",value=2,max=5,wx=2050,wy=1350,icon="ember",color={1,.38,.14},requires={{"fire_score_rocket_unlock",1}}},
    {id="fire_score_rocket_speed",name="폭죽 비행 속도 상승",short="비행 속도",desc="폭죽 로켓이 목표까지 날아가는 속도 +12%",effect="scoreRocketSpeed",value=.12,max=4,costs={22,38,58,82},wx=1420,wy=1560,icon="wind",color={.82,.74,.46},requires={{"fire_score_rocket_radius",2}}},
    {id="fire_score_rocket_ignite",name="폭죽 착탄 점화 확률 상승",short="착탄 점화",desc="폭발로 쓰러지지 않은 나무에 불이 붙을 확률 +6%p (기본 38%)",effect="scoreRocketIgnite",value=.06,max=5,wx=1790,wy=1660,icon="ember",color={1,.62,.24},requires={{"fire_score_rocket_radius",3}}},
    {id="fire_score_rocket_cooldown",name="폭죽 발사 속도 상승",short="발사 속도",desc="폭죽 로켓 재발사 대기시간 단계마다 9% 감소",effect="scoreRocketCooldown",value=.09,max=5,wx=2130,wy=1400,icon="clock",color={.94,.58,.22},requires={{"fire_score_rocket_damage",3}}},
}
for _,node in ipairs(scoreFireNodes)do node.job="fire";node.scoreMode=true;node.max=node.max or 5;node.costs=node.costs or{18,32,50,74,104};jobs.fire.nodes[#jobs.fire.nodes+1]=node end

expand("toxic",{
    {id="toxic_bamboo",name="손잡이 두 칸 연장",short="긴 포크",desc="포크 사거리 +14",effect="range",value=14,requires={{"toxic_tongs",2}},icon="tongs",color={.55,.67,.38}},
    {id="toxic_organic",name="포크 끝 재연마",short="뾰족하게",desc="포크 피해 +1",effect="biteDamage",value=1,requires={{"toxic_bamboo",1}},icon="sharpen",color={.78,.72,.48}},
    {id="toxic_jaw",name="양팔로 내려찍기",short="체중 싣기",desc="포크 피해 +1",effect="biteDamage",value=1,requires={{"toxic_bamboo",1}},icon="fist",color={.84,.76,.58}},
    {id="toxic_family",name="옆자리 포크 빌리기",short="포크 추가",desc="동시 타격 나무 +1",effect="extraTargets",value=1,requires={{"toxic_organic",2}},icon="coupon",color={.70,.40,.58},max=2},
    {id="toxic_fork",name="뷔페 포크 12개",short="넓은 식사",desc="포크 타격 폭 +10",effect="area",value=10,requires={{"toxic_jaw",2}},icon="tongs",color={.48,.72,.64}},
    {id="toxic_rawbar",name="단체 테이블 점령",short="상단 전문화",desc="동시 타격 나무 +2",effect="extraTargets",value=2,requires={{"toxic_family",2},{"toxic_fork",2}},icon="capstone",color={.35,.86,.28},max=1,capstone=true},
    {id="toxic_badge",name="비건 인증 배지 8개",short="인증 중첩",desc="연구 코인 +5%",effect="reward",value=.05,requires={{"toxic_cert",2}},icon="certificate",color={.34,.66,.62}},
    {id="toxic_digest",name="초고속 소화",short="바로 다음 접시",desc="포크질 속도 +5%",effect="attackSpeed",value=.05,requires={{"toxic_badge",1}},icon="clock",color={.46,.74,.28}},
    {id="toxic_gut",name="튼튼한 위장",short="한 그루 더",desc="최대 체력 +7",effect="maxHp",value=7,requires={{"toxic_badge",1}},icon="heartleaf",color={.50,.62,.38}},
    {id="toxic_donationbox",name="투명하지 않은 모금함",short="현금 후원",desc="연구 코인 +7%",effect="reward",value=.07,requires={{"toxic_digest",2}},icon="donation",color={.80,.58,.24}},
    {id="toxic_reusable",name="다회용 위장",short="먹고 회복",desc="나무를 먹을 때 체력 +2",effect="healOnFell",value=2,requires={{"toxic_gut",2}},icon="heartleaf",color={.34,.78,.42}},
    {id="toxic_manifest",name="한 접시 30초",short="하단 전문화",desc="포크질 속도 +14%",effect="attackSpeed",value=.14,requires={{"toxic_donationbox",2},{"toxic_reusable",2}},icon="capstone",color={.42,.82,.24},max=1,capstone=true},
    {id="toxic_board",name="이사회 전원 공복",short="단체 공복",desc="포크 타격 폭 +9",effect="area",value=9,requires={{"toxic_sponsor",2}},icon="document",color={.55,.62,.48}},
    {id="toxic_influencer",name="먹방 인플루언서 영입",short="먹방 확장",desc="추가 포식 대상 +1",effect="extraTargets",value=1,requires={{"toxic_board",1}},icon="coupon",color={.72,.44,.60},max=2},
    {id="toxic_superfood",name="세계수 메인 요리 지정",short="단단한 식재료",desc="포크 피해 +2",effect="biteDamage",value=2,requires={{"toxic_board",1}},icon="fork",color={.38,.76,.30}},
    {id="toxic_retreat",name="원시림 푸드파이터 합숙",short="위장 단련",desc="최대 체력 +10",effect="maxHp",value=10,requires={{"toxic_influencer",2}},icon="heartleaf",color={.48,.66,.42}},
    {id="toxic_receipt",name="후원 영수증 선택 발급",short="후원 정산",desc="연구 코인 +9%",effect="reward",value=.09,requires={{"toxic_superfood",2}},icon="report",color={.84,.62,.30}},
    {id="toxic_congress",name="국제 뷔페 총회 유치",short="숲 전체 식탁",desc="포크 타격 폭 +30",effect="area",value=30,requires={{"toxic_retreat",2},{"toxic_receipt",2}},icon="certificate",color={.30,.72,.52},max=1,capstone=true},
    {id="toxic_eatforest",name="숲 한 접시 완식",short="최종 포크",desc="포크 피해 +5",effect="biteDamage",value=5,requires={{"toxic_congress",1}},icon="capstone",color={.22,.90,.24},max=1,capstone=true,costs={190}}
})

expand("developer",{
    {id="developer_drone",name="측량 드론 배터리 증설",short="원거리 측량",desc="돌진 거리 +18",effect="range",value=18,requires={{"developer_boundary",2}},icon="machine",color={.42,.65,.76}},
    {id="developer_night",name="야간 공사 허가",short="24시간 공사",desc="리모컨 속도 +5%",effect="attackSpeed",value=.05,requires={{"developer_drone",1}},icon="moon",color={.48,.52,.68}},
    {id="developer_lane",name="차선 두 개 무단 점유",short="넓은 진입로",desc="돌진 폭 +9",effect="area",value=9,requires={{"developer_drone",1}},icon="road",color={.56,.60,.62}},
    {id="developer_turbo",name="중장비 터보 개조",short="과속 공사",desc="돌진 속도 +8%",effect="dashSpeed",value=.08,requires={{"developer_night",2}},icon="machine",color={.92,.52,.18}},
    {id="developer_border",name="경계석 임의 이동",short="부지 확장",desc="돌진 거리 +20",effect="range",value=20,requires={{"developer_lane",2}},icon="ruler",color={.82,.68,.32}},
    {id="developer_fasttrack",name="패스트트랙 심의",short="상단 전문화",desc="쿨다운 초기화 확률 +14%",effect="cooldownRefund",value=.14,requires={{"developer_turbo",2},{"developer_border",2}},icon="capstone",color={.26,.68,.92},max=1,capstone=true},
    {id="developer_crane",name="타워크레인 선반입",short="장비 선점",desc="돌진 폭 +10",effect="area",value=10,requires={{"developer_machinery",2}},icon="tower",color={.86,.62,.20}},
    {id="developer_advancepay",name="하도급 선급금 보류",short="자금 회전",desc="연구 코인 +6%",effect="reward",value=.06,requires={{"developer_crane",1}},icon="coins",color={.82,.65,.28}},
    {id="developer_concrete",name="조경 전 콘크리트 타설",short="재생 차단",desc="불모지화 확률 +9%",effect="sterileChance",value=.09,requires={{"developer_crane",1}},icon="machine",color={.55,.57,.56}},
    {id="developer_subsub",name="재하청의 재하청",short="책임 분산",desc="리모컨 속도 +5%",effect="attackSpeed",value=.05,requires={{"developer_advancepay",2}},icon="helmet",color={.90,.70,.24}},
    {id="developer_dust",name="비산먼지 측정기 철거",short="폭파 확대",desc="종점 충격파 +16",effect="aftershockRadius",value=16,requires={{"developer_concrete",2}},icon="blast",color={.76,.42,.28}},
    {id="developer_turnkey",name="턴키 수의계약",short="하단 전문화",desc="돌진 속도 +18%",effect="dashSpeed",value=.18,requires={{"developer_subsub",2},{"developer_dust",2}},icon="capstone",color={.24,.72,.88},max=1,capstone=true},
    {id="developer_modelhouse",name="모델하우스 우선 준공",short="실물은 나중",desc="연구 코인 +7%",effect="reward",value=.07,requires={{"developer_presale",2}},icon="tower",color={.48,.66,.80}},
    {id="developer_bypass",name="환경영향평가 우회",short="평가 생략",desc="불모지화 확률 +10%",effect="sterileChance",value=.10,requires={{"developer_modelhouse",1}},icon="document",color={.44,.62,.46}},
    {id="developer_doublelane",name="중장비 전용 복선",short="복선 돌진",desc="돌진 폭 +12",effect="area",value=12,requires={{"developer_modelhouse",1}},icon="road",color={.62,.58,.48}},
    {id="developer_detonator",name="무선 발파 승인",short="원격 발파",desc="종점 충격파 +20",effect="aftershockRadius",value=20,requires={{"developer_bypass",2}},icon="blast",color={.92,.38,.18}},
    {id="developer_finance",name="프로젝트 파이낸싱 연장",short="자금 재투입",desc="쿨다운 초기화 확률 +8%",effect="cooldownRefund",value=.08,requires={{"developer_doublelane",2}},icon="coins",color={.82,.64,.22}},
    {id="developer_megacity",name="메가시티 특별법",short="도시 지정",desc="돌진 거리 +55",effect="range",value=55,requires={{"developer_detonator",2},{"developer_finance",2}},icon="tower",color={.30,.64,.86},max=1,capstone=true},
    {id="developer_noforest",name="숲은 계획도에 없었다",short="최종 개발",desc="돌진 폭 +48",effect="area",value=48,requires={{"developer_megacity",1}},icon="capstone",color={.12,.58,.94},max=1,capstone=true,costs={190}}
})

expand("miner",{
    {id="miner_groundradar",name="지표투과레이더 대여",short="렌탈 장비",desc="탐지 사거리 +16",effect="range",value=16,requires={{"miner_coil",2}},icon="machine",color={.70,.75,.80}},
    {id="miner_remotecontrol",name="블루투스 삽 리모컨",short="원격 삽질",desc="삽질 속도 +5%",effect="attackSpeed",value=.05,requires={{"miner_groundradar",1}},icon="stamp",color={.85,.70,.30}},
    {id="miner_magnetometer",name="자력계 병행 사용",short="이중 확인",desc="'발견' 판정 확률 +3%",effect="executeChance",value=.03,requires={{"miner_groundradar",1}},icon="warning",color={.88,.50,.22}},
    {id="miner_batterypack",name="예비 배터리 두 개",short="꺼지지 않는다",desc="삽질 속도 +6%",effect="attackSpeed",value=.06,requires={{"miner_remotecontrol",2}},icon="coins",color={.90,.75,.30},max=2},
    {id="miner_triplecheck",name="삼중 확인 탐지",short="확신 상승",desc="'발견' 판정 확률 +4%",effect="executeChance",value=.04,requires={{"miner_magnetometer",2}},icon="certificate",color={.80,.55,.25}},
    {id="miner_thisisit",name="이 밑이 확실하다",short="상단 전문화",desc="굴착 범위 +26",effect="area",value=26,requires={{"miner_batterypack",2},{"miner_triplecheck",2}},icon="capstone",color={1,.75,.20},max=1,capstone=true},
    {id="miner_backbelt2",name="허리 보호대 겸용",short="이중 보호",desc="최대 체력 +8",effect="maxHp",value=8,requires={{"miner_knee",2}},icon="helmet",color={.55,.48,.36}},
    {id="miner_gloves",name="장갑 두 겹",short="물집 방지",desc="굴착 피해 +1",effect="treeDamage",value=1,requires={{"miner_backbelt2",1}},icon="fist",color={.68,.60,.50}},
    {id="miner_kneepad2",name="무릎 패드 업그레이드",short="이중 쿠션",desc="최대 체력 +9",effect="maxHp",value=9,requires={{"miner_backbelt2",1}},icon="helmet",color={.60,.52,.38}},
    {id="miner_reforge",name="삽날 재련",short="대장간 방문",desc="굴착 피해 +1",effect="treeDamage",value=1,requires={{"miner_gloves",2}},icon="sharpen",color={.75,.70,.65},max=2},
    {id="miner_discignore",name="허리 디스크 무시",short="병원은 나중에",desc="삽질 속도 +5%",effect="attackSpeed",value=.05,requires={{"miner_kneepad2",2}},icon="clock",color={.70,.40,.30}},
    {id="miner_bodybreaks",name="몸이 부서져도 판다",short="하단 전문화",desc="굴착 피해 +2",effect="treeDamage",value=2,requires={{"miner_reforge",2},{"miner_discignore",2}},icon="capstone",color={.90,.50,.20},max=1,capstone=true},
    {id="miner_memoryreconstruct",name="그날의 기억 재구성",short="기억 되짚기",desc="런 종료 연구 코인 +6%",effect="reward",value=.06,requires={{"miner_gpscoord",2}},icon="document",color={.85,.72,.30}},
    {id="miner_hikingclub",name="등산 동호회 탐문",short="목격자 수소문",desc="탐지 사거리 +16",effect="range",value=16,requires={{"miner_memoryreconstruct",1}},icon="map",color={.65,.75,.50}},
    {id="miner_usedmarket",name="중고 거래 게시글 추적",short="혹시 그 USB?",desc="런 종료 연구 코인 +6%",effect="reward",value=.06,requires={{"miner_memoryreconstruct",1}},icon="coins",color={.88,.68,.25}},
    {id="miner_cctv",name="산장 CCTV 확보",short="화질 깨짐",desc="탐지 사거리 +18",effect="range",value=18,requires={{"miner_hikingclub",2}},icon="machine",color={.60,.70,.78}},
    {id="miner_diary",name="그 해 일기장 발견",short="단서 확보",desc="런 종료 연구 코인 +9%",effect="reward",value=.09,requires={{"miner_usedmarket",2}},icon="report",color={.82,.62,.28}},
    {id="miner_certainty",name="확신의 좌표",short="하단2 전문화",desc="런 종료 연구 코인 +14%",effect="reward",value=.14,requires={{"miner_cctv",2},{"miner_diary",2}},icon="capstone",color={1,.70,.15},max=1,capstone=true},
    {id="miner_definitelyhere",name="여기 어딘가에 반드시 있다",short="최종 발굴",desc="굴착 범위 +48",effect="area",value=48,requires={{"miner_certainty",1}},icon="capstone",color={1,.85,.10},max=1,capstone=true,costs={190}}
})

expand("philosopher",{
    {id="philosopher_megaphone",name="휴대용 확성기",short="더 크게",desc="침 사거리 +16",effect="range",value=16,requires={{"philosopher_lungs",2}},icon="wind",color={.72,.85,.32}},
    {id="philosopher_runonsentence",name="끝나지 않는 문장",short="접속사 남발",desc="장광설 속도 +5%",effect="attackSpeed",value=.05,requires={{"philosopher_megaphone",1}},icon="clock",color={.80,.88,.35}},
    {id="philosopher_strawman",name="허수아비 논증",short="반박 무시",desc="침 피해 +1",effect="biteDamage",value=1,requires={{"philosopher_megaphone",1}},icon="tooth",color={.65,.78,.30}},
    {id="philosopher_podcast",name="주간 팟캐스트 개설",short="구독자 3명",desc="장광설 속도 +6%",effect="attackSpeed",value=.06,requires={{"philosopher_runonsentence",2}},icon="wind",color={.75,.85,.38},max=2},
    {id="philosopher_gaslighting",name="논점 흐리기 숙련",short="화제 전환",desc="침 피해 +1",effect="biteDamage",value=1,requires={{"philosopher_strawman",2}},icon="question",color={.60,.72,.32}},
    {id="philosopher_neverwrong",name="한 번도 틀린 적 없다",short="상단 전문화",desc="침 범위 +26",effect="area",value=26,requires={{"philosopher_podcast",2},{"philosopher_gaslighting",2}},icon="capstone",color={.85,.95,.30},max=1,capstone=true},
    {id="philosopher_earplugsforthem",name="상대방 귀마개 뺏기",short="도망 못 감",desc="최대 체력 +8",effect="maxHp",value=8,requires={{"philosopher_thickskin",2}},icon="helmet",color={.52,.60,.42}},
    {id="philosopher_coldbrew",name="식은 아메리카노 다섯 잔",short="카페인 중독",desc="장광설 속도 +4%",effect="attackSpeed",value=.04,requires={{"philosopher_earplugsforthem",1}},icon="lunch",color={.48,.55,.40}},
    {id="philosopher_thickerskin",name="더 두꺼운 낯짝",short="수치심 상실",desc="최대 체력 +9",effect="maxHp",value=9,requires={{"philosopher_earplugsforthem",1}},icon="helmet",color={.50,.62,.44}},
    {id="philosopher_debateclub",name="동네 토론 동아리 장악",short="회장 취임",desc="침 피해 +1",effect="biteDamage",value=1,requires={{"philosopher_coldbrew",2}},icon="tooth",color={.62,.72,.35},max=2},
    {id="philosopher_sleepdeprivation",name="수면 부족 3일째",short="눈이 풀림",desc="중독 지속시간 +0.7초",effect="plagueDuration",value=.7,requires={{"philosopher_thickerskin",2}},icon="ash",color={.55,.58,.45}},
    {id="philosopher_untouchable",name="비판이 닿지 않는다",short="하단 전문화",desc="중독 지속시간 +1.2초",effect="plagueDuration",value=1.2,requires={{"philosopher_debateclub",2},{"philosopher_sleepdeprivation",2}},icon="capstone",color={.78,.90,.32},max=1,capstone=true},
    {id="philosopher_donationbox2",name="후원 계좌 개설",short="첫 입금 확인",desc="런 종료 연구 코인 +6%",effect="reward",value=.06,requires={{"philosopher_cultfollow",2}},icon="donation",color={.82,.72,.30}},
    {id="philosopher_livestream",name="실시간 스트리밍 설파",short="시청자 2명",desc="침 사거리 +16",effect="range",value=16,requires={{"philosopher_donationbox2",1}},icon="wind",color={.70,.82,.36}},
    {id="philosopher_bookdeal",name="출판사 세 곳 거절",short="자비출판 확정",desc="런 종료 연구 코인 +6%",effect="reward",value=.06,requires={{"philosopher_donationbox2",1}},icon="report",color={.86,.70,.28}},
    {id="philosopher_viral",name="한 번 화제가 됨",short="캡처돼서 퍼짐",desc="침 사거리 +18",effect="range",value=18,requires={{"philosopher_livestream",2}},icon="wind",color={.68,.80,.34}},
    {id="philosopher_disciple",name="진짜 제자가 생김",short="한 명이지만",desc="런 종료 연구 코인 +9%",effect="reward",value=.09,requires={{"philosopher_bookdeal",2}},icon="certificate",color={.80,.68,.30}},
    {id="philosopher_movement",name="'해방' 운동 본격화",short="하단2 전문화",desc="런 종료 연구 코인 +14%",effect="reward",value=.14,requires={{"philosopher_viral",2},{"philosopher_disciple",2}},icon="capstone",color={.90,1,.28},max=1,capstone=true},
    {id="philosopher_liberation",name="모든 것을 해방시킨다",short="최종 해방",desc="침 범위 +42",effect="area",value=42,requires={{"philosopher_movement",1}},icon="capstone",color={.65,1,.15},max=1,capstone=true,costs={190}}
})

-- 공용 특성: 특정 직업 트리가 아니라 총무팀 복지처럼 어떤 직업을 고르든 항상 함께 적용되는
-- 범용 스탯 트리. 서바이버류 장르에서 흔히 쓰이는 메타 진행 축(체력, 이동속도, 재화 획득량,
-- 자원 획득 반경=자석, 체력 자연 회복, 부활)을 이 게임의 블랙코미디 톤에 맞춰 구성했다.
jobs.universal = {
    currencyName="연구 코인",
    tagline="복지는 직무를 가리지 않는다.",
    doctrine="어떤 현장에 배치되든 몸과 통장은 공통으로 챙긴다 — 선택한 직업과 무관하게 항상 적용된다.",
    palette={.62,.70,.78},
    nodes={
        {id="universal_shuttle", name="통근버스 신설", short="출근 단축", desc="이동 속도 +6%", max=3, costs={18,32,50}, effect="moveSpeed", value=.06, x=.10,y=.50, icon="road", color={.55,.68,.78}},
        {id="universal_checkup", name="정기 건강검진", short="이상 무", desc="최대 체력 +12", max=3, costs={22,38,58}, effect="maxHp", value=12, requires={{"universal_shuttle",1}}, x=.32,y=.28, icon="helmet", color={.62,.72,.60}},
        {id="universal_incentive", name="분기 인센티브 신설", short="약간의 성의", desc="런 종료 연구 코인 +8%", max=3, costs={22,38,58}, effect="reward", value=.08, requires={{"universal_shuttle",1}}, x=.32,y=.72, icon="coins", color={.82,.68,.30}},
        {id="universal_locker", name="개인 사물함 확장", short="더 담긴다", desc="자원 획득 반경 +40", max=3, costs={28,46,68}, effect="pickupRadius", value=40, requires={{"universal_checkup",1}}, x=.56,y=.20, icon="basket", color={.66,.70,.50}},
        {id="universal_snackbar", name="탕비실 간식 무제한", short="상시 비치", desc="초당 체력 자연 회복 +0.4", max=3, costs={28,46,68}, effect="hpRegen", value=.4, requires={{"universal_incentive",1}}, x=.56,y=.80, icon="lunch", color={.72,.58,.40}},
        {id="universal_insurance", name="단체 상해보험 특약", short="다치면 보험", desc="최대 체력 +14", max=2, costs={42,72}, effect="maxHp", value=14, requires={{"universal_locker",2}}, x=.68,y=.08, icon="document", color={.60,.70,.62}},
        {id="universal_bike", name="사내 자전거 대여", short="따릉이 지원", desc="이동 속도 +5%", max=3, costs={34,54,78}, effect="moveSpeed", value=.05, requires={{"universal_locker",1}}, x=.70,y=.30, icon="road", color={.58,.70,.80}},
        {id="universal_profitshare", name="성과공유제 시범 도입", short="나눠 갖기", desc="런 종료 연구 코인 +10%", max=3, costs={34,54,78}, effect="reward", value=.10, requires={{"universal_snackbar",1}}, x=.70,y=.70, icon="donation", color={.84,.70,.32}},
        {id="universal_cart", name="물류용 카트 지급", short="손 안 대도 된다", desc="자원 획득 반경 +30", max=3, costs={34,54,78}, effect="pickupRadius", value=30, requires={{"universal_snackbar",1}}, x=.68,y=.92, icon="basket", color={.68,.72,.52}},
        {id="universal_severance", name="퇴직 위로금 사전 적립", short="한 번은 봐준다", desc="쓰러졌을 때 1회 부활 (체력 50% 회복)", max=1, costs={110}, effect="reviveCharges", value=1, requires={{"universal_bike",1},{"universal_profitshare",1}}, x=.78,y=.50, icon="heartleaf", color={.85,.45,.55}},
        {id="universal_finalwelfare", name="총무팀의 마지막 배려", short="최종 복지", desc="쓰러졌을 때 부활 횟수 +1", max=1, costs={190}, effect="reviveCharges", value=1, requires={{"universal_severance",1}}, x=.94,y=.50, icon="capstone", color={1,.55,.65}, capstone=true}
    }
}

-- 나무 = 재화라는 컨셉을 공용 트리에 반영: 목재 획득량 보너스는 루트(통근버스)
-- 바로 다음 단계에 배치해 "루트에서 바로 이어지는" 재화 특성이 되게 하고, 조림
-- 사업으로 스테이지당 나무 수를 늘리며, 그 조림 사업이 있어야 비로소 더 값나가는
-- 수종(=지금 숲에 이미 있던 소나무/자작나무/단풍나무)이 함께 자라기 시작한다.
expand("universal",{
    {id="universal_lumberbonus",name="목재 실적 인정",short="벤 만큼 잡힌다",desc="목재 획득량 +12%",effect="woodYield",value=.12,requires={{"universal_shuttle",1}},icon="coins",color={.78,.62,.30}},
    {id="universal_afforestation",name="선제적 조림 사업",short="미리 심어둔다",desc="스테이지 진행마다 나무 +6그루(스테이지 배수)",effect="forestRestock",value=6,requires={{"universal_shuttle",1}},icon="map",color={.42,.68,.40}},
    {id="universal_seedbank",name="다수종 조림 협약",short="한 종만 심지 않는다",desc="벌목지에 더 값나가는 수종이 함께 자란다",effect="treeVariety",value=1,max=1,requires={{"universal_afforestation",1}},icon="leaf",color={.55,.72,.35}},
    {id="universal_yard",name="벌목장 부지 확장",short="쌓아둘 자리",desc="벌목 기록 모드의 나무 허용량 +4그루",effect="scoreTreeAllowance",value=4,max=7,costs={16,26,40,58,80,108,142},wx=520,wy=850,icon="map",color={.48,.72,.42},scoreMode=true},
    {id="universal_robot_start",name="아기 로봇 기본 지급",short="첫 출근 동행",desc="벌목 기록 모드를 아기 운반 로봇 Lv.1로 시작",effect="scoreStartingBabyRobot",value=1,max=1,costs={42},wx=900,wy=680,icon="basket",color={.40,.86,1},scoreMode=true},
    {id="universal_robot_motor",name="아기 로봇 고속 모터",short="더 빨리 줍는다",desc="아기 운반 로봇 이동속도 +10%",effect="scoreRobotSpeed",value=.10,max=5,costs={22,38,58,82,112},wx=1260,wy=680,icon="clock",color={.55,.90,1},requires={{"universal_robot_start",1}},scoreMode=true},
    {id="universal_mole_companion",name="두더지 동료 채용",short="두더지 채용",desc="벌목 기록 모드에 두더지 동료 1마리가 합류합니다.",effect="scoreMoleCompanion",value=1,max=1,costs={78},wx=1100,wy=1100,icon="fist",color={.78,.62,.30},requires={{"universal_robot_start",1}},scoreMode=true},
    {id="universal_mole_damage",name="두더지 피해 상승",short="피해 상승",desc="두더지 발톱 피해가 단계마다 1 증가합니다.",effect="scoreMoleDamage",value=1,max=3,costs={30,48,72},wx=700,wy=1320,icon="fist",color={.86,.48,.24},requires={{"universal_mole_companion",1}},scoreMode=true},
    {id="universal_mole_speed",name="두더지 이동속도 상승",short="이동속도 상승",desc="두더지 이동속도가 단계마다 10% 증가합니다.",effect="scoreMoleSpeed",value=.10,max=3,costs={26,44,66},wx=1100,wy=1370,icon="road",color={.48,.72,.82},requires={{"universal_mole_companion",1}},scoreMode=true},
    {id="universal_mole_attack_speed",name="두더지 공격속도 상승",short="공격속도 상승",desc="두더지 공격속도가 단계마다 12% 증가합니다.",effect="scoreMoleAttackSpeed",value=.12,max=3,costs={32,52,78},wx=1500,wy=1320,icon="clock",color={.82,.68,.30},requires={{"universal_mole_companion",1}},scoreMode=true},
    {id="universal_mole_claw",name="두더지 공격범위 상승",short="공격범위 상승",desc="두더지의 공격 가능 거리와 발톱 자국 크기가 단계마다 증가합니다.",effect="scoreMoleClawTier",value=1,max=2,costs={56,92},wx=500,wy=1570,icon="split",color={.92,.42,.22},requires={{"universal_mole_damage",2}},scoreMode=true},
    {id="universal_mole_dual",name="두더지 양손 공격",short="양손 공격",desc="두더지가 한 번의 공격에 양손 발톱 자국을 남깁니다.",effect="scoreMoleDualClaw",value=1,max=1,costs={125},wx=500,wy=1820,icon="capstone",color={1,.32,.16},requires={{"universal_mole_claw",2}},scoreMode=true},
    {id="universal_mole_extra",name="두더지 추가 채용",short="추가 동료 채용",desc="단계마다 두더지 동료 1마리가 추가로 합류합니다.",effect="scoreMoleExtraCompanions",value=1,max=2,costs={110,180},wx=1100,wy=1650,icon="split",color={.72,.58,.32},requires={{"universal_mole_speed",2},{"universal_mole_attack_speed",2}},scoreMode=true},
    {id="universal_oil_drum",name="기름 드럼통 생성",short="드럼통 생성",desc="벌목 기록 모드에서 22초마다 기름 드럼통이 떨어집니다. 도끼로 두 번 타격하면 주변에 기름이 쏟아집니다.",effect="scoreOilDrum",value=1,max=1,costs={64},wx=1740,wy=930,icon="basket",color={.42,.50,.52},requires={{"universal_robot_start",1}},scoreMode=true},
    {id="universal_gray_cat",name="회색 고양이 동료",short="드럼통 자동 전복",desc="회색 고양이가 화면 밖에서 달려와 떨어진 기름 드럼통을 넘어뜨리고, 반대편 화면 밖으로 점프해 나갑니다.",effect="scoreGrayCat",value=1,max=1,costs={92},wx=2050,wy=1190,icon="fist",color={.56,.62,.68},requires={{"universal_oil_drum",1}},scoreMode=true},
})

local byId = {}
for job, group in pairs(jobs) do
    for _, node in ipairs(group.nodes) do node.job = job; byId[node.id] = node end
end
local orderedIds = {}
for id in pairs(byId) do orderedIds[#orderedIds+1] = id end
table.sort(orderedIds)

-- 도입부 스토리를 강제로 본 적 있는지 캐릭터(직업)별로 저장한다. "universal"은
-- 실제로 고를 수 있는 캐릭터가 아니라서 목록에서 뺀다.
local storyJobs = {"physical", "fire", "toxic", "developer", "miner", "philosopher"}

local function defaults()
    local data = {currency=0, regenTier=1, levels={}, storySeen={}}
    for id in pairs(byId) do data.levels[id] = 0 end
    for _, job in ipairs(storyJobs) do data.storySeen[job] = false end
    return data
end

function CharacterTraits.decode(text)
    local data = defaults()
    local legacyMoleRank,seenNewMoleNode=0,false
    for key, value in (text or ""):gmatch("([%w_]+)=([%d]+)") do
        local number = math.max(0, math.floor(tonumber(value) or 0))
        if key=="universal_mole_companion"then legacyMoleRank=number end
        if key:match("^universal_mole_")and key~="universal_mole_companion"then seenNewMoleNode=true end
        if key == "currency" then data.currency = number
        elseif key == "regenTier" then data.regenTier = math.max(1,number)
        elseif byId[key] then data.levels[key] = math.min(number, byId[key].max)
        elseif key:match("^story_") then
            local job = key:sub(7)
            if data.storySeen[job] ~= nil then data.storySeen[job] = number > 0 end
        end
    end
    if legacyMoleRank>1 and not seenNewMoleNode then
        data.levels.universal_mole_damage=math.min(3,legacyMoleRank-1)
        data.levels.universal_mole_speed=math.min(3,math.max(0,legacyMoleRank-2))
        data.levels.universal_mole_attack_speed=math.min(3,math.max(0,legacyMoleRank-3))
        data.levels.universal_mole_claw=math.min(2,math.max(0,legacyMoleRank-4))
        data.levels.universal_mole_dual=legacyMoleRank>=6 and 1 or 0
        data.levels.universal_mole_extra=legacyMoleRank>=6 and 1 or 0
    end
    return data
end

function CharacterTraits.encode(data)
    local lines = {"version=3", "currency=" .. math.floor(data.currency or 0),"regenTier="..math.max(1,math.floor(data.regenTier or 1))}
    for _, id in ipairs(orderedIds) do
        local node = byId[id]
        lines[#lines+1] = id .. "=" .. math.min(node.max, math.floor(data.levels[id] or 0))
    end
    for _, job in ipairs(storyJobs) do
        lines[#lines+1] = "story_" .. job .. "=" .. ((data.storySeen or {})[job] and 1 or 0)
    end
    return table.concat(lines, "\n") .. "\n"
end

function CharacterTraits.new(memoryOnly)
    local self = setmetatable({memoryOnly=memoryOnly, file="character_traits.sav", data=defaults()}, CharacterTraits)
    if not memoryOnly and love.filesystem.getInfo(self.file) then
        local text = love.filesystem.read(self.file)
        if text then self.data = CharacterTraits.decode(text) end
    end
    return self
end

function CharacterTraits:save()
    if self.memoryOnly then return true end
    return love.filesystem.write(self.file, CharacterTraits.encode(self.data))
end

function CharacterTraits:getJobs() return jobs end
function CharacterTraits:getNodes(job) return jobs[job] and jobs[job].nodes or {} end
-- 현재 로비 연구망은 기록 모드에 실제 적용되는 노드만 노출한다. 일반 작전
-- 노드와 구매 기록은 삭제하지 않고 getNodes/effects에 그대로 보존한다.
function CharacterTraits:getScoreAttackNodes(job)
    local visible={}
    for _,node in ipairs(self:getNodes(job))do if node.scoreMode then visible[#visible+1]=node end end
    return visible
end
function CharacterTraits:getNode(id) return byId[id] end
function CharacterTraits:getLevel(id) return self.data.levels[id] or 0 end
function CharacterTraits:getRegenTier()return math.max(1,math.floor(self.data.regenTier or 1))end
function CharacterTraits:unlockRegenTier(tier)
    tier=math.max(1,math.floor(tier or 1))
    if tier<=self:getRegenTier()then return false end
    self.data.regenTier=tier
    self:save()
    return true
end

local function requirementsOf(node)
    if not node or not node.requires then return {} end
    if type(node.requires[1]) == "string" then return {node.requires} end
    return node.requires
end

function CharacterTraits:getRequirements(id)
    return requirementsOf(type(id)=="table" and id or byId[id])
end

function CharacterTraits:status(id)
    local node = byId[id]
    if not node then return false, "존재하지 않는 특성" end
    local level = self:getLevel(id)
    if level >= node.max then return false, "최고 단계" end
    for _, requirement in ipairs(requirementsOf(node)) do
        if self:getLevel(requirement[1]) < requirement[2] then
            return false, byId[requirement[1]].name .. " " .. requirement[2] .. "단계 필요"
        end
    end
    local cost = node.costs[level+1]
    if self.data.currency < cost then return false, "연구 코인 " .. cost .. " 필요" end
    return true, "해금 가능", cost
end

function CharacterTraits:buy(id)
    local ok, reason, cost = self:status(id)
    if not ok then return false, reason end
    self.data.currency = self.data.currency - cost
    self.data.levels[id] = self:getLevel(id) + 1
    self:save()
    return true, byId[id].name .. " " .. self:getLevel(id) .. "단계 해금"
end

function CharacterTraits:addCurrency(amount, deferSave)
    amount = math.max(0, math.floor(amount or 0))
    self.data.currency = self.data.currency + amount
    if not deferSave then self:save() end
    return amount
end

function CharacterTraits:hasSeenStory(jobId)
    return self.data.storySeen[jobId] == true
end

function CharacterTraits:markStorySeen(jobId)
    if self.data.storySeen[jobId] == nil then return end
    self.data.storySeen[jobId] = true
    self:save()
end

local multiplicativeEffects = {attackSpeed=true, reward=true, burnSpeed=true, dashSpeed=true, moveSpeed=true, woodYield=true}

-- 직업 전용 트리 + 공용(universal) 트리를 합산한다: 어떤 직업을 골라도 공용 특성은 항상 적용된다.
function CharacterTraits:effects(job)
    local effects = {
        attackSpeed=1, range=0, area=0, maxHp=0, reward=1,
        extraTargets=0, treeDamage=0, healOnFell=0, executeChance=0,
        burnSpeed=1, extraFires=0, spreadChance=0,
        biteDamage=0, plagueDuration=0,
        dashSpeed=1, sterileChance=0, aftershockRadius=0, cooldownRefund=0,
        moveSpeed=1, pickupRadius=0, hpRegen=0, reviveCharges=0,
        woodYield=1, forestRestock=0, treeVariety=0, scoreTreeAllowance=0,
        scoreRange=0,scoreArea=0,scoreAttackSpeed=0,scoreIgnitionChance=0,scoreSpreadChance=0,
        scoreProjectileSpeed=0,scoreBurnSpeed=0,scoreExtraFires=0,
        scoreInitialIgnitionReduction=0,scoreStartingBabyRobot=0,scoreRobotSpeed=0,scoreMoleCompanion=0,
        scoreMoleDamage=0,scoreMoleSpeed=0,scoreMoleAttackSpeed=0,scoreMoleClawTier=0,scoreMoleDualClaw=0,scoreMoleExtraCompanions=0,
        scoreOilDrum=0,scoreGrayCat=0
    }
    local function accumulate(nodes)
        for _, node in ipairs(nodes) do
            local amount = self:getLevel(node.id) * node.value
            if multiplicativeEffects[node.effect] then effects[node.effect] = effects[node.effect] + amount
            else effects[node.effect] = (effects[node.effect] or 0) + amount end
        end
    end
    accumulate(self:getNodes(job))
    accumulate(self:getNodes("universal"))
    return effects
end

-- 기록 모드는 기존 캐릭터 트리의 누적 수치에 종속되지 않는다. 현재 활성 연구와
-- 공용 허용량만 합산하며, 이전 모드의 구매 데이터는 저장 파일에 그대로 남긴다.
function CharacterTraits:scoreAttackEffects()
    local effects={
        attackSpeed=1,range=0,area=0,maxHp=0,reward=1,extraTargets=0,treeDamage=0,
        healOnFell=0,executeChance=0,burnSpeed=1,extraFires=0,spreadChance=0,
        moveSpeed=1,pickupRadius=0,hpRegen=0,reviveCharges=0,woodYield=1,
        scoreTreeAllowance=0,scoreRange=0,scoreArea=0,scoreAttackSpeed=0,
        scoreIgnitionChance=0,scoreSpreadChance=0,scoreProjectileSpeed=0,
        scoreBurnSpeed=0,scoreExtraFires=0,scoreInitialIgnitionReduction=0,
        scoreStartingBabyRobot=0,scoreRobotSpeed=0,scoreMoleCompanion=0,
        scoreMoleDamage=0,scoreMoleSpeed=0,scoreMoleAttackSpeed=0,scoreMoleClawTier=0,scoreMoleDualClaw=0,scoreMoleExtraCompanions=0,
        scoreOilDrum=0,scoreGrayCat=0,
        -- 무기 슬롯 3종용. scoreTreeDamage는 도끼·폭죽 공용이고, 나머지는 각 무기가
        -- 담배용 수치를 계수로 나눠 쓰던 것을 전용으로 분리한 값이다.
        scoreTreeDamage=0,
        scoreAxeArea=0,scoreAxeSpeed=0,scoreAxeTargets=0,scoreAxeExecute=0,
        scoreRocketRadius=0,scoreRocketDamage=0,scoreRocketSpeed=0,scoreRocketIgnite=0,scoreRocketCooldown=0,
        scoreAutoThrow=0,scoreRocketUnlock=0,scoreAlwaysSmoking=0
    }
    for _,job in ipairs({"fire","universal"})do
        for _,node in ipairs(self:getScoreAttackNodes(job))do
            effects[node.effect]=(effects[node.effect]or 0)+self:getLevel(node.id)*node.value
        end
    end
    return effects
end

function CharacterTraits:reset()
    self.data = defaults()
    self:save()
end

return CharacterTraits
