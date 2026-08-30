-- The static dossier is a required mirror of every in-game skill definition.
package.path="./?.lua;./?/init.lua;"..package.path
local function read(path)
    local file=assert(io.open(path,"rb"));local value=file:read("*a");file:close();return value
end
local source=read("src/clearcut_mode.lua")
local dossier=read("docs/character_dossier.html")
-- Index once. Re-running a leading [^\r\n]* pattern against the dossier's
-- intentionally long system-note line for every skill caused quadratic
-- backtracking as that documentation grew.
local dossierById={}
for line in dossier:gmatch("[^\r\n]+") do
    local id=line:match('id:"([^"]+)"')
    if id then dossierById[id]=line end
end
local checked=0
for line in source:gmatch("[^\r\n]+") do
    local id=line:match('{id="([^"]+)"')
    local name=line:match('name="([^"]+)"')
    local desc=line:match('desc="([^"]*)"')
    local max=line:match('max=(%d+)')
    if id and name and desc and max then
        local dossierLine=dossierById[id]
        assert(dossierLine,"character_dossier.html is missing skill "..id)
        assert(dossierLine:find('name:"'..name..'"',1,true),"dossier skill name is stale: "..id)
        assert(dossierLine:find('desc:"'..desc..'"',1,true),"dossier skill description is stale: "..id)
        -- Older static entries may omit max only when it is the universal 6.
        local documentedMax=dossierLine:match('max:(%d+)') or "6"
        assert(documentedMax==max,"dossier skill max level is stale: "..id)
        checked=checked+1
    end
end
assert(checked>=29,"dossier verifier found too few skill definitions")
local fusionSource=read("src/clearcut_fusions.lua")
local fusionChecked=0
for id,name,needs,desc in fusionSource:gmatch('{id="([^"]+)".-name="([^"]+)".-needs={(.-)}.-\n%s*desc="([^"]*)"') do
    local dossierLine=dossierById[id]
    assert(dossierLine,"character_dossier.html is missing fusion "..id)
    assert(dossierLine:find('name:"'..name..'"',1,true),"dossier fusion name is stale: "..id)
    assert(dossierLine:find('desc:"'..desc..'"',1,true),"dossier fusion description is stale: "..id)
    for ingredient in needs:gmatch('"([^"]+)"') do
        assert(dossierLine:find('"'..ingredient..'"',1,true),"dossier fusion ingredient is stale: "..id)
    end
    fusionChecked=fusionChecked+1
end
assert(fusionChecked>=7,"dossier verifier found too few fusion definitions")
assert(dossier:find('id="score-mode-summary"',1,true),"dossier is missing the visible score-mode rules summary")
assert(dossier:find("시작 6그루 · 0.16그루/초 · 허용량 12",1,true)and dossier:find("첫 45초 없음",1,true),"dossier score-mode opening pacing is stale")
assert(dossier:find("목재 경험치 → 흡연자 전용 스킬 3택",1,true),"dossier score-mode growth summary is stale")
assert(dossier:find("목재를 얻으면 경험치가 올라",1,true),"dossier score-mode system note is stale")
assert(dossier:find("공용 패시브 · 현재 드래프트 제외",1,true),"dossier does not document the temporarily excluded shared cards")
assert(dossier:find("fire_score_prewarm",1,true)and dossier:find("fire_score_heat",1,true),"dossier score-mode permanent research is stale")
assert(not dossier:find("fire_score_procurement",1,true)and not dossier:find('id:"forest_expansion"',1,true),"removed automation content remains in dossier")
print("CHARACTER_DOSSIER_OK skills="..checked.." fusions="..fusionChecked.." names/descriptions/max=synced")
