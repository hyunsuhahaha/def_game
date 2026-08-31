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
assert(dossier:find("0그루 달성 · 0.86초 잎/프리즘 단계 상승 연출 · 6그루 순차 발아 · 다음 단계 영구 해금",1,true),
    "dossier score-mode opening pacing is stale")
assert(dossier:find("인게임 XP·레벨업·강화 3택 없음 · 목재는 점수와 정산만",1,true),"dossier score-mode growth summary is stale")
assert(dossier:find("중앙 루트의 기존 상·하·좌·우 분기 + 초반 즉시 타격 대각선 가지 · 방향별 동일 단계 간격 · 기준 간격의 85~115% 줌 · 화면 해상도별 한글 폰트 재래스터",1,true),
    "dossier research-board summary is stale")
assert(dossier:find("수종별 목재 집계 → 1개씩 회전 코인으로 순차 변환 → 강화하기/재도전 (이동 시 잔여분 즉시 정산)",1,true),
    "dossier result-screen summary is stale")
assert(dossier:find("fire_score_prewarm",1,true)and dossier:find("fire_score_impact",1,true)and dossier:find("fire_score_stock",1,true),
    "dossier score-mode permanent traits are stale")
assert(dossier:find("universal_robot_start",1,true)and dossier:find("universal_robot_motor",1,true),
    "dossier baby robot permanent research is stale")
for _,id in ipairs({
    "universal_mole_companion","universal_mole_damage","universal_mole_speed","universal_mole_attack_speed",
    "universal_mole_claw","universal_mole_dual","universal_mole_extra","universal_oil_drum",
    "universal_oil_interval","universal_oil_radius","universal_oil_splash_count","universal_oil_patch_scale","universal_oil_ignition_radius",
    "universal_oil_duration","universal_oil_burn_duration","universal_oil_damage",
    "universal_gray_cat","universal_gray_cat_chance","universal_gray_cat_delay","universal_gray_cat_speed","universal_gray_cat_exit_speed"
})do
    assert(dossier:find('id:"'..id..'"',1,true),"dossier permanent trait is missing: "..id)
end

print("CHARACTER_DOSSIER_OK permanent-research-only active-groups=weapon+companion archived-character-data=preserved")
