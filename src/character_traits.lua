local CharacterTraits = {}
CharacterTraits.__index = CharacterTraits

local jobs = {
    physical = {
        currencyName="성과 포인트",
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
            {id="physical_report", name="초과 달성 보고서", short="할당량 초과", desc="런 종료 성과 포인트 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"physical_sharpen",1},{"physical_overtime",1}}, x=.78,y=.50, icon="report", color={.94,.66,.22}},
            {id="physical_union", name="노조 없는 현장", short="최종 잔업", desc="도끼 타격 범위 +36", max=1, costs={110}, effect="area", value=36, requires={{"physical_report",3}}, x=.94,y=.50, icon="capstone", color={.95,.32,.18}, capstone=true}
        }
    },
    fire = {
        currencyName="성과 포인트",
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
            {id="fire_insurance", name="화재보험 가입 직후", short="보상 준비", desc="런 종료 성과 포인트 +6%", max=3, costs={42,66,92}, effect="reward", value=.06, requires={{"fire_ashtray",2}}, x=.68,y=.92, icon="policy", color={.74,.61,.35}},
            {id="fire_denial", name="인과관계 불분명", short="증거 불충분", desc="런 종료 성과 포인트 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"fire_wind",1},{"fire_ashtray",1}}, x=.78,y=.50, icon="question", color={.69,.53,.72}},
            {id="fire_chain", name="연쇄 실화", short="최종 불씨", desc="흡연·투척 속도 +18%", max=1, costs={110}, effect="attackSpeed", value=.18, requires={{"fire_denial",3}}, x=.94,y=.50, icon="capstone", color={1,.27,.09}, capstone=true}
        }
    },
    toxic = {
        currencyName="성과 포인트",
        tagline="숲을 먹어 치우는 것도 엄연한 채식이다.",
        doctrine="산지 직송을 명분으로 가지를 뜯고 넓은 구역을 한입에 비운다.",
        palette={.38,.68,.27},
        nodes={
            {id="toxic_raw", name="생식주의", short="세척 생략", desc="가지 섭취 속도 +7%", max=3, costs={18,32,50}, effect="attackSpeed", value=.07, x=.10,y=.50, icon="leaf", color={.45,.76,.28}},
            {id="toxic_tongs", name="산지 직송 집게", short="원산지 현장", desc="집게 사거리 +20", max=3, costs={22,38,58}, effect="range", value=20, requires={{"toxic_raw",1}}, x=.32,y=.28, icon="tongs", color={.68,.72,.55}},
            {id="toxic_cert", name="탄소중립 인증", short="스티커 부착", desc="한입 피해 범위 +12", max=3, costs={22,38,58}, effect="area", value=12, requires={{"toxic_raw",1}}, x=.32,y=.72, icon="certificate", color={.34,.67,.62}},
            {id="toxic_molar", name="친환경 어금니", short="씹어서 해결", desc="한입 피해 범위 +8", max=3, costs={28,46,68}, effect="area", value=8, requires={{"toxic_tongs",1}}, x=.56,y=.20, icon="tooth", color={.86,.83,.66}},
            {id="toxic_delivery", name="제로마일 식탁", short="걸어서 산지로", desc="집게 사거리 +16", max=3, costs={28,46,68}, effect="range", value=16, requires={{"toxic_cert",1}}, x=.56,y=.80, icon="basket", color={.72,.48,.25}},
            {id="toxic_protein", name="식물성 단백질 과다", short="강한 턱", desc="한입 피해 +1", max=3, costs={34,54,78}, effect="biteDamage", value=1, requires={{"toxic_molar",1}}, x=.70,y=.30, icon="tooth", color={.87,.72,.45}},
            {id="toxic_buffet_coupon", name="무제한 리필 쿠폰", short="한입 더", desc="한 번에 물어뜯는 나무 +1", max=2, costs={48,82}, effect="extraTargets", value=1, requires={{"toxic_molar",2}}, x=.68,y=.08, icon="coupon", color={.72,.38,.62}},
            {id="toxic_compost", name="자가 퇴비화", short="먹고 회복", desc="나무를 먹을 때 체력 +1", max=3, costs={34,54,78}, effect="healOnFell", value=1, requires={{"toxic_delivery",1}}, x=.70,y=.70, icon="heartleaf", color={.38,.78,.46}},
            {id="toxic_manifesto", name="48쪽짜리 성명문", short="효과 지속", desc="감염 지속시간 +0.8초", max=3, costs={42,66,92}, effect="plagueDuration", value=.8, requires={{"toxic_delivery",2}}, x=.68,y=.92, icon="document", color={.55,.64,.75}},
            {id="toxic_sponsor", name="후원금 사용 내역 비공개", short="영수증 없음", desc="런 종료 성과 포인트 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"toxic_molar",1},{"toxic_delivery",1}}, x=.78,y=.50, icon="donation", color={.86,.62,.27}},
            {id="toxic_buffet", name="숲 전체 샐러드바", short="최종 식사", desc="한입 피해 범위 +34", max=1, costs={110}, effect="area", value=34, requires={{"toxic_sponsor",3}}, x=.94,y=.50, icon="capstone", color={.25,.82,.28}, capstone=true}
        }
    },
    developer = {
        currencyName="성과 포인트",
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
            {id="developer_presale", name="사전분양 완판", short="모형도 매진", desc="런 종료 성과 포인트 +10%", max=3, costs={38,58,84}, effect="reward", value=.10, requires={{"developer_rezone",1},{"developer_subcontract",1}}, x=.78,y=.50, icon="tower", color={.47,.65,.82}},
            {id="developer_expropriate", name="공익사업 강제수용", short="최종 고시", desc="돌진 폭 +32", max=1, costs={110}, effect="area", value=32, requires={{"developer_presale",3}}, x=.94,y=.50, icon="capstone", color={.20,.63,.92}, capstone=true}
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
            wx=position[1],wy=position[2],icon=definition.icon or "capstone",color=definition.color,
            max=max,costs=definition.costs or (max==1 and {135} or max==2 and {48,86} or {36,62,94}),
            capstone=definition.capstone
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
    {id="physical_kpi",name="분기별 벌목 KPI",short="목표 재설정",desc="성과 포인트 +7%",effect="reward",value=.07,requires={{"physical_report",2}},icon="report",color={.88,.62,.20}},
    {id="physical_hydraulic",name="유압 도끼 불법 개조",short="압력 상승",desc="도끼 피해 +1",effect="treeDamage",value=1,requires={{"physical_kpi",1}},icon="machine",color={.66,.72,.74}},
    {id="physical_sawback",name="톱날 겸용 도끼",short="넓은 절단",desc="타격 범위 +10",effect="area",value=10,requires={{"physical_kpi",1}},icon="axe",color={.72,.46,.25}},
    {id="physical_nohire",name="인력 충원 계획 없음",short="혼자 두 배",desc="동시 타격 나무 +1",effect="extraTargets",value=1,requires={{"physical_hydraulic",2}},icon="split",color={.84,.40,.18},max=2},
    {id="physical_erasure",name="산재 기록 말소",short="기록 없음",desc="즉시 벌목 확률 +4%",effect="executeChance",value=.04,requires={{"physical_sawback",2}},icon="document",color={.65,.42,.50}},
    {id="physical_employee",name="분기 최우수 사원",short="실적 독식",desc="성과 포인트 +12%",effect="reward",value=.12,requires={{"physical_nohire",2},{"physical_erasure",2}},icon="report",color={.96,.66,.18},max=1,capstone=true},
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
    {id="fire_nosign",name="금연 표지판 뒤집기",short="표지 무시",desc="성과 포인트 +6%",effect="reward",value=.06,requires={{"fire_hotash",2}},icon="document",color={.72,.40,.36}},
    {id="fire_balcony",name="베란다 투척 숙련",short="포물선 숙련",desc="꽁초 사거리 +20",effect="range",value=20,requires={{"fire_drymouth",2}},icon="wind",color={.45,.65,.76}},
    {id="fire_fireline",name="산불 방화선 역이용",short="하단 전문화",desc="불 확산 확률 +10%",effect="spreadChance",value=.10,requires={{"fire_nosign",2},{"fire_balcony",2}},icon="capstone",color={.94,.50,.12},max=1,capstone=true},
    {id="fire_carton",name="면세점 보루 구매",short="불씨 재고",desc="추가 불씨 +1",effect="extraFires",value=1,requires={{"fire_denial",2}},icon="pack",color={.68,.30,.24},max=2},
    {id="fire_tailwind",name="계절풍 흡연 지침",short="순풍 투척",desc="꽁초 사거리 +18",effect="range",value=18,requires={{"fire_carton",1}},icon="wind",color={.44,.68,.72}},
    {id="fire_resin",name="송진 묻은 필터",short="고열 필터",desc="연소 속도 +8%",effect="burnSpeed",value=.08,requires={{"fire_carton",1}},icon="filter",color={.78,.54,.24}},
    {id="fire_emberstorm",name="불씨 폭풍",short="불씨 증식",desc="추가 불씨 +1",effect="extraFires",value=1,requires={{"fire_tailwind",2}},icon="ember",color={1,.34,.08},max=2},
    {id="fire_press",name="언론 대응 매뉴얼",short="원인 부인",desc="성과 포인트 +9%",effect="reward",value=.09,requires={{"fire_resin",2}},icon="policy",color={.62,.55,.66}},
    {id="fire_claim",name="실화 책임 전면 부인",short="책임 없음",desc="성과 포인트 +14%",effect="reward",value=.14,requires={{"fire_emberstorm",2},{"fire_press",2}},icon="question",color={.82,.42,.60},max=1,capstone=true},
    {id="fire_redsky",name="하늘이 붉은 건 노을",short="최종 산불",desc="착화 범위 +42",effect="area",value=42,requires={{"fire_claim",1}},icon="capstone",color={1,.18,.04},max=1,capstone=true,costs={190}}
})

expand("toxic",{
    {id="toxic_bamboo",name="대나무 집게",short="긴 집게",desc="포식 사거리 +14",effect="range",value=14,requires={{"toxic_tongs",2}},icon="tongs",color={.55,.67,.38}},
    {id="toxic_organic",name="유기농 소금",short="간 맞추기",desc="한입 피해 +1",effect="biteDamage",value=1,requires={{"toxic_bamboo",1}},icon="basket",color={.78,.72,.48}},
    {id="toxic_jaw",name="저작근 단련",short="강한 턱",desc="한입 피해 +1",effect="biteDamage",value=1,requires={{"toxic_bamboo",1}},icon="tooth",color={.84,.76,.58}},
    {id="toxic_family",name="가족 단위 시식회",short="동시 시식",desc="추가 포식 대상 +1",effect="extraTargets",value=1,requires={{"toxic_organic",2}},icon="coupon",color={.70,.40,.58},max=2},
    {id="toxic_fork",name="다회용 포크 12개",short="범위 식사",desc="포식 범위 +10",effect="area",value=10,requires={{"toxic_jaw",2}},icon="tongs",color={.48,.72,.64}},
    {id="toxic_rawbar",name="숲속 생식 뷔페",short="상단 전문화",desc="추가 포식 대상 +2",effect="extraTargets",value=2,requires={{"toxic_family",2},{"toxic_fork",2}},icon="capstone",color={.35,.86,.28},max=1,capstone=true},
    {id="toxic_badge",name="비건 인증 배지 8개",short="인증 중첩",desc="성과 포인트 +5%",effect="reward",value=.05,requires={{"toxic_cert",2}},icon="certificate",color={.34,.66,.62}},
    {id="toxic_digest",name="초고속 소화",short="바로 다음 입",desc="포식 속도 +5%",effect="attackSpeed",value=.05,requires={{"toxic_badge",1}},icon="leaf",color={.46,.74,.28}},
    {id="toxic_gut",name="장내 미생물 회의",short="공생 주장",desc="감염 지속 +0.7초",effect="plagueDuration",value=.7,requires={{"toxic_badge",1}},icon="smoke",color={.50,.62,.38}},
    {id="toxic_donationbox",name="투명하지 않은 모금함",short="현금 후원",desc="성과 포인트 +7%",effect="reward",value=.07,requires={{"toxic_digest",2}},icon="donation",color={.80,.58,.24}},
    {id="toxic_reusable",name="다회용 위장",short="섭취 회복",desc="벌목 시 체력 +2",effect="healOnFell",value=2,requires={{"toxic_gut",2}},icon="heartleaf",color={.34,.78,.42}},
    {id="toxic_manifest",name="먹어서 지키는 선언",short="하단 전문화",desc="포식 속도 +14%",effect="attackSpeed",value=.14,requires={{"toxic_donationbox",2},{"toxic_reusable",2}},icon="capstone",color={.42,.82,.24},max=1,capstone=true},
    {id="toxic_board",name="이사회 전원 공복",short="단체 공복",desc="포식 범위 +9",effect="area",value=9,requires={{"toxic_sponsor",2}},icon="document",color={.55,.62,.48}},
    {id="toxic_influencer",name="먹방 인플루언서 영입",short="먹방 확장",desc="추가 포식 대상 +1",effect="extraTargets",value=1,requires={{"toxic_board",1}},icon="coupon",color={.72,.44,.60},max=2},
    {id="toxic_superfood",name="세계수 슈퍼푸드 지정",short="고영양 목재",desc="한입 피해 +2",effect="biteDamage",value=2,requires={{"toxic_board",1}},icon="leaf",color={.38,.76,.30}},
    {id="toxic_retreat",name="원시림 디톡스 수련회",short="장기 감염",desc="감염 지속 +1초",effect="plagueDuration",value=1,requires={{"toxic_influencer",2}},icon="smoke",color={.48,.66,.42}},
    {id="toxic_receipt",name="후원 영수증 선택 발급",short="후원 정산",desc="성과 포인트 +9%",effect="reward",value=.09,requires={{"toxic_superfood",2}},icon="report",color={.84,.62,.30}},
    {id="toxic_congress",name="국제 채식 총회 유치",short="숲 전체 식탁",desc="포식 범위 +30",effect="area",value=30,requires={{"toxic_retreat",2},{"toxic_receipt",2}},icon="certificate",color={.30,.72,.52},max=1,capstone=true},
    {id="toxic_eatforest",name="숲을 먹어 숲을 구한다",short="최종 포식",desc="한입 피해 +5",effect="biteDamage",value=5,requires={{"toxic_congress",1}},icon="capstone",color={.22,.90,.24},max=1,capstone=true,costs={190}}
})

expand("developer",{
    {id="developer_drone",name="측량 드론 배터리 증설",short="원거리 측량",desc="돌진 거리 +18",effect="range",value=18,requires={{"developer_boundary",2}},icon="machine",color={.42,.65,.76}},
    {id="developer_night",name="야간 공사 허가",short="24시간 공사",desc="리모컨 속도 +5%",effect="attackSpeed",value=.05,requires={{"developer_drone",1}},icon="moon",color={.48,.52,.68}},
    {id="developer_lane",name="차선 두 개 무단 점유",short="넓은 진입로",desc="돌진 폭 +9",effect="area",value=9,requires={{"developer_drone",1}},icon="road",color={.56,.60,.62}},
    {id="developer_turbo",name="중장비 터보 개조",short="과속 공사",desc="돌진 속도 +8%",effect="dashSpeed",value=.08,requires={{"developer_night",2}},icon="machine",color={.92,.52,.18}},
    {id="developer_border",name="경계석 임의 이동",short="부지 확장",desc="돌진 거리 +20",effect="range",value=20,requires={{"developer_lane",2}},icon="ruler",color={.82,.68,.32}},
    {id="developer_fasttrack",name="패스트트랙 심의",short="상단 전문화",desc="쿨다운 초기화 확률 +14%",effect="cooldownRefund",value=.14,requires={{"developer_turbo",2},{"developer_border",2}},icon="capstone",color={.26,.68,.92},max=1,capstone=true},
    {id="developer_crane",name="타워크레인 선반입",short="장비 선점",desc="돌진 폭 +10",effect="area",value=10,requires={{"developer_machinery",2}},icon="tower",color={.86,.62,.20}},
    {id="developer_advancepay",name="하도급 선급금 보류",short="자금 회전",desc="성과 포인트 +6%",effect="reward",value=.06,requires={{"developer_crane",1}},icon="coins",color={.82,.65,.28}},
    {id="developer_concrete",name="조경 전 콘크리트 타설",short="재생 차단",desc="불모지화 확률 +9%",effect="sterileChance",value=.09,requires={{"developer_crane",1}},icon="machine",color={.55,.57,.56}},
    {id="developer_subsub",name="재하청의 재하청",short="책임 분산",desc="리모컨 속도 +5%",effect="attackSpeed",value=.05,requires={{"developer_advancepay",2}},icon="helmet",color={.90,.70,.24}},
    {id="developer_dust",name="비산먼지 측정기 철거",short="폭파 확대",desc="종점 충격파 +16",effect="aftershockRadius",value=16,requires={{"developer_concrete",2}},icon="blast",color={.76,.42,.28}},
    {id="developer_turnkey",name="턴키 수의계약",short="하단 전문화",desc="돌진 속도 +18%",effect="dashSpeed",value=.18,requires={{"developer_subsub",2},{"developer_dust",2}},icon="capstone",color={.24,.72,.88},max=1,capstone=true},
    {id="developer_modelhouse",name="모델하우스 우선 준공",short="실물은 나중",desc="성과 포인트 +7%",effect="reward",value=.07,requires={{"developer_presale",2}},icon="tower",color={.48,.66,.80}},
    {id="developer_bypass",name="환경영향평가 우회",short="평가 생략",desc="불모지화 확률 +10%",effect="sterileChance",value=.10,requires={{"developer_modelhouse",1}},icon="document",color={.44,.62,.46}},
    {id="developer_doublelane",name="중장비 전용 복선",short="복선 돌진",desc="돌진 폭 +12",effect="area",value=12,requires={{"developer_modelhouse",1}},icon="road",color={.62,.58,.48}},
    {id="developer_detonator",name="무선 발파 승인",short="원격 발파",desc="종점 충격파 +20",effect="aftershockRadius",value=20,requires={{"developer_bypass",2}},icon="blast",color={.92,.38,.18}},
    {id="developer_finance",name="프로젝트 파이낸싱 연장",short="자금 재투입",desc="쿨다운 초기화 확률 +8%",effect="cooldownRefund",value=.08,requires={{"developer_doublelane",2}},icon="coins",color={.82,.64,.22}},
    {id="developer_megacity",name="메가시티 특별법",short="도시 지정",desc="돌진 거리 +55",effect="range",value=55,requires={{"developer_detonator",2},{"developer_finance",2}},icon="tower",color={.30,.64,.86},max=1,capstone=true},
    {id="developer_noforest",name="숲은 계획도에 없었다",short="최종 개발",desc="돌진 폭 +48",effect="area",value=48,requires={{"developer_megacity",1}},icon="capstone",color={.12,.58,.94},max=1,capstone=true,costs={190}}
})

local byId = {}
for job, group in pairs(jobs) do
    for _, node in ipairs(group.nodes) do node.job = job; byId[node.id] = node end
end
local orderedIds = {}
for id in pairs(byId) do orderedIds[#orderedIds+1] = id end
table.sort(orderedIds)

local function defaults()
    local data = {currency=0, levels={}}
    for id in pairs(byId) do data.levels[id] = 0 end
    return data
end

function CharacterTraits.decode(text)
    local data = defaults()
    for key, value in (text or ""):gmatch("([%w_]+)=([%d]+)") do
        local number = math.max(0, math.floor(tonumber(value) or 0))
        if key == "currency" then data.currency = number
        elseif byId[key] then data.levels[key] = math.min(number, byId[key].max) end
    end
    return data
end

function CharacterTraits.encode(data)
    local lines = {"version=2", "currency=" .. math.floor(data.currency or 0)}
    for _, id in ipairs(orderedIds) do
        local node = byId[id]
        lines[#lines+1] = id .. "=" .. math.min(node.max, math.floor(data.levels[id] or 0))
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
function CharacterTraits:getNode(id) return byId[id] end
function CharacterTraits:getLevel(id) return self.data.levels[id] or 0 end

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
    if self.data.currency < cost then return false, "성과 포인트 " .. cost .. " 필요" end
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

function CharacterTraits:addCurrency(amount)
    amount = math.max(0, math.floor(amount or 0))
    self.data.currency = self.data.currency + amount
    self:save()
    return amount
end

function CharacterTraits:effects(job)
    local effects = {
        attackSpeed=1, range=0, area=0, maxHp=0, reward=1,
        extraTargets=0, treeDamage=0, healOnFell=0, executeChance=0,
        burnSpeed=1, extraFires=0, spreadChance=0,
        biteDamage=0, plagueDuration=0,
        dashSpeed=1, sterileChance=0, aftershockRadius=0, cooldownRefund=0
    }
    for _, node in ipairs(self:getNodes(job)) do
        local amount = self:getLevel(node.id) * node.value
        if node.effect == "attackSpeed" or node.effect == "reward" or node.effect == "burnSpeed" or node.effect == "dashSpeed" then
            effects[node.effect] = effects[node.effect] + amount
        else effects[node.effect] = (effects[node.effect] or 0) + amount end
    end
    return effects
end

function CharacterTraits:reset()
    self.data = defaults()
    self:save()
end

return CharacterTraits
