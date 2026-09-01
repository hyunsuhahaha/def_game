local function read(path)
    local file=assert(io.open(path,"rb"));local text=file:read("*a");file:close();return text
end

local readme=read("README.md")
local active=read("docs/ACTIVE_DEVELOPMENT_MODE.md")
local system=read("docs/SYSTEM_MAP.md")
local narrative=read("docs/NARRATIVE_DIRECTION.md")
local settings=read("docs/SETTINGS.md")
local frontend=read("docs/FRONTEND_UI_REDESIGN.md")
local companions=read("docs/LOBBY_COMPANIONS.md")
local meta=read("docs/SCORE_ATTACK_META_LOOP.md")

assert(readme:find("40초 뒤 세계수 처치",1,true)and
    not readme:find("60초 뒤 세계수 처치",1,true),
    "README world-tree interval is stale")
assert(active:find("/30초",1,true)and active:find("40초 뒤 세계수 처치",1,true),
    "active-mode pressure or world-tree timing is stale")
assert(system:find("과거의 트라우마를 불태우려고 꿈속의 숲에서 싸우고 있다",1,true)and
    system:find("해금 단계와 결말은 아직 미정",1,true)and
    system:find("단계 시작 40초 뒤에 오는 승급 기회",1,true)and
    not system:find("60초마다 오는 유일한 선택",1,true),
    "system map invented or omitted the confirmed dream premise")
for _,phrase in ipairs({"과거의 트라우마","꿈속의 숲","자각몽","염동력·초능력·물리 법칙 왜곡","아직 정하지 않은 것"})do
    assert(narrative:find(phrase,1,true),"narrative direction is missing: "..phrase)
end
assert(settings:find("musicVolume",1,true)and settings:find("sfxVolume",1,true)and
    settings:find("last_haul_settings_v1.txt",1,true),"persistent audio settings are undocumented")
assert(frontend:find("LOBBY_COMPANIONS.md",1,true)and frontend:find("SETTINGS.md",1,true),
    "frontend guide is not linked to new lobby systems")
assert(frontend:find("로비 종료 메뉴",1,true)and frontend:find("즉시 종료하지 않고",1,true),
    "frontend guide does not describe the lobby exit confirmation")
assert(companions:find("universal_mole_companion",1,true)and companions:find("universal_gray_cat",1,true),
    "lobby companion unlock documentation is incomplete")
assert(meta:find("로비 `P` 연습장",1,true)and meta:find("영구 연구 빌드",1,true),
    "meta-loop documentation still describes the archived practice panel")
print("DOCUMENTATION_SYNC_OK narrative=bounded timing=40s/30s practice=current settings=persistent lobby_companions=linked")
