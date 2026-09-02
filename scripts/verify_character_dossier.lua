local function read(path)
    local file=assert(io.open(path,"rb"));local value=file:read("*a");file:close();return value
end

local dossier=read("docs/character_dossier.html")
for _,removed in ipairs({
    "const SKILLS","const SYNERGIES","const SYNERGY_TAGS","const SKILL_BRANCHES",
    "const FUSIONS","renderSkillsPanel","스킬·운영","태그 시너지"
})do
    assert(not dossier:find(removed,1,true),"removed skill/synergy dossier content remains: "..removed)
end
assert(dossier:find('let mode = "traits"',1,true),"dossier does not open on permanent traits")
assert(dossier:find('<h1 class="masthead-title" id="masthead-title">영구 연구 기록부</h1>',1,true),"dossier still uses the character personnel-file framing")
assert(dossier:find('traits: { label: "영구 연구"',1,true),"permanent research dossier mode is missing")
assert(dossier:find('const ORDER = ["fire","universal"]',1,true),"dossier still exposes archived character selection tabs")
assert(dossier:find('label: "무기·전투"',1,true)and dossier:find('label: "동료·설비"',1,true),
    "active research groups are not presented without character classes")
assert(dossier:find('document.getElementById("score-mode-summary").hidden = false',1,true),
    "score rules disappear when switching active research groups")
assert(dossier:find("기존 조합 보너스의 계산·연계 파동·HUD·선택 카드 표시는 제거",1,true),
    "dossier system note does not record the removed combination system")
assert(dossier:find('id="score-mode-summary"',1,true),"dossier is missing the visible score-mode rules summary")
assert(dossier:find("활성 나무 0그루 달성 또는 40초 뒤 세계수 처치 · 0.86초 연출 · 6그루 순차 발아 · 다음 단계 영구 해금",1,true),
    "dossier score-mode opening pacing is stale")
assert(dossier:find("인게임 XP·레벨업·강화 3택 없음 · 목재는 점수와 정산만",1,true),"dossier score-mode growth summary is stale")
assert(dossier:find("없음 · 멧돼지·다람쥐 등 일반 몬스터 비활성",1,true),"dossier score-mode monster rule is stale")
assert(dossier:find("재생 단계 제한 및 목표 단계 가격 노드는 표의 고정 가격",1,true),"dossier research-price rule is stale")
assert(dossier:find("중앙 루트의 상·하·좌·우 분기 · 꽁초 즉시 타격은 기본 적용 · 방향별 동일 단계 간격 · 기준 간격의 85~115% 줌 · 화면 해상도별 한글 폰트 재래스터",1,true),
    "dossier research-board summary is stale")
assert(dossier:find("소량은 1개씩·대량은 묶음 단위로 코인 변환",1,true)and dossier:find("약 4초 상한",1,true),
    "dossier result-screen summary is stale")
assert(dossier:find("fire_score_prewarm",1,true)and not dossier:find("fire_score_impact",1,true)and dossier:find("fire_score_stock",1,true),
    "dossier score-mode permanent traits are stale")
assert(dossier:find('id:"fire_score_dash_distance"',1,true)and dossier:find("대시 이동거리가 130 증가",1,true),
    "dossier dash-distance research is stale")
assert(dossier:find('id:"fire_score_rocket_unlock"',1,true)and dossier:find("costs:[900],targetTier:5",1,true)and
    dossier:find('id:"fire_score_rocket_crew"',1,true)and dossier:find("costs:[7800],targetTier:7",1,true),
    "dossier firework tier 5-7 pricing is stale")
assert(dossier:find('id:"fire_score_flame_unlock"',1,true)and dossier:find("costs:[16000],targetTier:8",1,true)and
    dossier:find('id:"fire_score_flame_ignite_4"',1,true)and dossier:find("costs:[110000],targetTier:10",1,true),
    "dossier flamethrower tier 8+ pricing is stale")
assert(dossier:find("universal_robot_start",1,true)and dossier:find("universal_robot_motor",1,true),
    "dossier baby robot permanent research is stale")
for _,entry in ipairs({
    {'id:"universal_veteran_yard"','costs:[1800,2200,2600,3000]'},
    {'id:"universal_veteran_crew"','costs:[16000]'},
    {'id:"universal_wildfire"','costs:[80000,100000,120000]'}
})do
    local from=assert(dossier:find(entry[1],1,true),"dossier tier-gated research is missing: "..entry[1])
    assert(dossier:find(entry[2],from,true),"dossier tier-gated research cost is stale: "..entry[1])
end
for _,id in ipairs({
    "universal_mole_companion","universal_mole_damage","universal_mole_speed","universal_mole_attack_speed",
    "universal_mole_claw","universal_mole_dual","universal_mole_extra","universal_mole_burrow",
    "universal_mole_burrow_speed","universal_mole_burrow_damage","universal_mole_burrow_cooldown","universal_oil_drum",
    "universal_oil_interval","universal_oil_radius","universal_oil_splash_count","universal_oil_patch_scale",
    "universal_oil_radius_2","universal_oil_radius_3","universal_oil_splash_count_2","universal_oil_ignition_radius",
    "universal_oil_duration","universal_oil_burn_duration","universal_oil_damage",
    "universal_gray_cat","universal_gray_cat_chance","universal_gray_cat_delay","universal_gray_cat_speed","universal_gray_cat_exit_speed"
})do
    assert(dossier:find('id:"'..id..'"',1,true),"dossier permanent trait is missing: "..id)
end

print("CHARACTER_DOSSIER_OK permanent-research-only active-groups=weapon+companion archived-character-data=preserved")
