-- 해금 동물만 로비에 나타나고 걷기/휴식/수면 상태가 순환하는지 검사한다.
package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Companions=require("src.lobby_companions")

local function fakeTraits(levels)
    return{getLevel=function(_,id)return levels[id]or 0 end}
end

local function read(path)
    local file=assert(io.open(path,"rb"));local data=file:read("*a");file:close();return data
end
local function be32(png,offset)
    local a,b,c,d=png:byte(offset,offset+3);return((a*256+b)*256+c)*256+d
end

local sizes={
    ["assets/characters/companions/lobby-monkey-sleep-atlas-pixel-v2.png"]={1152,160},
    ["assets/characters/companions/lobby-mole-sleep-atlas-pixel-v2.png"]={1920,384},
    ["assets/characters/companions/lobby-cat-sleep-atlas-pixel-v2.png"]={1152,160},
    ["assets/characters/companions/lobby-interaction-props-atlas-pixel-v1.png"]={384,320},
}
read("assets/characters/companions/concepts/lobby-companion-sleep-concept-v1.png")
for path,size in pairs(sizes)do
    local png=read(path)
    assert(png:sub(2,4)=="PNG"and be32(png,17)==size[1]and be32(png,21)==size[2],
        path..": 수면 아틀라스 크기 오류")
    assert(png:byte(26)==6,path..": 투명 RGBA가 아니다")
end

local state=Companions.new()
assert(Companions.sync(state,fakeTraits({}),1280,720)==0,
    "해금하지 않은 동료가 로비에 나타났다")

local levels={
    fire_score_axe_crew=1,fire_score_rocket_crew=1,fire_score_popper_unlock=1,
    fire_score_popper_extra=1,universal_veteran_crew=1,
    universal_mole_companion=1,universal_mole_extra=2,universal_gray_cat=1,
}
assert(Companions.sync(state,fakeTraits(levels),1280,720)==3,
    "해금한 동물 종류마다 한 마리씩 로비에 합류하지 않았다")
assert(state.bounds.x1<=1280*.15 and state.bounds.x2>=1280*.89,
    "동료 산책 범위가 로비 왼쪽 공터까지 열리지 않았다")
local kinds={monkey=0,mole=0,cat=0}
for _,actor in ipairs(state.animals)do kinds[actor.kind]=kinds[actor.kind]+1 end
assert(kinds.monkey==1 and kinds.mole==1 and kinds.cat==1,
    "원숭이·두더지·고양이가 종류별 한 마리로 제한되지 않았다")

local initialLeft,initialRight=0,0
for _,actor in ipairs(state.animals)do
    if actor.x<state.bounds.width*.42 then initialLeft=initialLeft+1 end
    if actor.x>state.bounds.width*.62 then initialRight=initialRight+1 end
end
assert(initialLeft>=1 and initialRight>=1,
    "실제 초기 동료 배치가 개체별 산책 구역 없이 한쪽에 몰렸다")

local resized=Companions.new();Companions.sync(resized,fakeTraits(levels),1280,720)
assert(Companions.prepareInteractionPreview(resized,"banana_toss"),"리사이즈 상호작용 준비 실패")
local oldBounds=resized.bounds
local actor=resized.animals[1]
local actorNX=(actor.x-oldBounds.x1)/(oldBounds.x2-oldBounds.x1)
local actorNY=(actor.y-oldBounds.y1)/(oldBounds.y2-oldBounds.y1)
local targetNX=(actor.targetX-oldBounds.x1)/(oldBounds.x2-oldBounds.x1)
local interactionNX=(resized.interaction.x-oldBounds.x1)/(oldBounds.x2-oldBounds.x1)
Companions.sync(resized,fakeTraits(levels),2560,1440)
local newBounds=resized.bounds
local function normalized(value,low,high)return(value-low)/(high-low)end
assert(math.abs(normalized(actor.x,newBounds.x1,newBounds.x2)-actorNX)<.001 and
    math.abs(normalized(actor.y,newBounds.y1,newBounds.y2)-actorNY)<.001 and
    math.abs(normalized(actor.targetX,newBounds.x1,newBounds.x2)-targetNX)<.001,
    "창/전체 화면 전환 시 동료와 목적지의 정규화 좌표가 보존되지 않았다")
assert(math.abs(normalized(resized.interaction.x,newBounds.x1,newBounds.x2)-interactionNX)<.001,
    "화면 전환 시 진행 중인 동료 상호작용만 이전 절대 좌표에 남았다")

local roaming=Companions.new();Companions.sync(roaming,fakeTraits(levels),1920,1080)
roaming.nextInteraction=math.huge
for checkpoint=1,6 do
    for _=1,300 do Companions.update(roaming,1/30)end
    local minX,maxX=math.huge,-math.huge
    for _,candidate in ipairs(roaming.animals)do minX=math.min(minX,candidate.x);maxX=math.max(maxX,candidate.x)end
    local occupied=(maxX-minX)/(roaming.bounds.x2-roaming.bounds.x1)
    assert(occupied>.46,"장시간 산책 중 동료가 다시 한쪽 구역으로 수렴했다: "..checkpoint)
end

local tree={kind="tree",x=790,y=670,rx=38,ry=52}
Companions.setScenery(state,{tree})
assert(Companions.isSceneryBlocked(state,state.animals[1],tree.x,tree.y,true),
    "전경 나무 밑동 점유 영역이 동료 충돌에 등록되지 않았다")
for _=1,120 do Companions.update(state,1/30)end
for _,actor in ipairs(state.animals)do
    assert(not Companions.isSceneryBlocked(state,actor,actor.x,actor.y,actor.state=="sleep"),
        "동료가 전경 나무 밑동 위에 배치됐다: "..actor.id)
    assert(not Companions.isSceneryBlocked(state,actor,actor.targetX,actor.targetY,true),
        "동료의 이동/수면 목표가 전경 나무 밑동과 겹친다: "..actor.id)
end
assert(Companions.depthScaleForY(state.bounds.y1,state.bounds)<
    Companions.depthScaleForY(state.bounds.y2,state.bounds),
    "동료 크기에 전경/후경 원근 배율이 없다")

Companions.preparePreview(state)
local states={}
local leftCount,rightCount=0,0
for _,actor in ipairs(state.animals)do
    states[actor.state]=true
    if actor.x<state.bounds.width*.38 then leftCount=leftCount+1 end
    if actor.x>state.bounds.width*.62 then rightCount=rightCount+1 end
end
assert(states.walk and states.idle and states.sleep,"생활 상태 세 종류가 준비되지 않았다")
assert(leftCount>=1 and rightCount>=1,"동료 검수 배치가 좌우 공터에 고르게 퍼지지 않는다")
local function radius(actor)
    if actor.state=="sleep"then return actor.kind=="monkey"and 35 or(actor.kind=="mole"and 47 or 48)end
    return actor.kind=="monkey"and 19 or(actor.kind=="mole"and 27 or 23)
end
for left=1,#state.animals-1 do for right=left+1,#state.animals do
    local a,b=state.animals[left],state.animals[right]
    local dx,dy=a.x-b.x,a.y-b.y
    assert(math.sqrt(dx*dx+dy*dy)>=radius(a)+radius(b)-1,
        "일상 동료끼리 몸체가 겹친다: "..a.id.." / "..b.id)
end end

local walker
for _,actor in ipairs(state.animals)do if actor.state=="walk"then walker=actor;break end end
local oldX=walker.x;Companions.update(state,.25)
assert(walker.x~=oldX,"걷는 동료가 목표를 향해 이동하지 않는다")
local sleeper
for _,actor in ipairs(state.animals)do if actor.state=="sleep"then sleeper=actor;break end end
sleeper.timer=.01;Companions.update(state,.02)
assert(sleeper.state=="walk","잠든 동료가 깨어나 다시 산책하지 않는다")
for _,actor in ipairs(state.animals)do
    assert(actor.x>=state.bounds.x1 and actor.x<=state.bounds.x2 and
        actor.y>=state.bounds.y1 and actor.y<=state.bounds.y2,
        "동료가 로비 산책 범위를 벗어났다")
end

Companions.preparePreview(state);fixture.reset();Companions.draw(state,.35)
local sourceKinds,sleepDraws,zMarks={},0,0
for _,op in ipairs(fixture.commands)do
    if op.op=="draw"then
        sourceKinds[op.file]=true
        if op.file:find("sleep%-atlas")then sleepDraws=sleepDraws+1 end
        assert(op.filter=="nearest","로비 동료가 nearest 필터를 사용하지 않는다")
    elseif op.op=="rectangle"then zMarks=zMarks+1 end
end
for _,actor in ipairs(state.animals)do actor.state="idle"end
fixture.reset();Companions.draw(state,.35)
for _,op in ipairs(fixture.commands)do
    if op.op=="draw"then sourceKinds[op.file]=true end
end
assert(sourceKinds["assets/characters/companions/graduate-monkey-atlas-pixel-v3.png"]and
    sourceKinds["assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png"]and
    sourceKinds["assets/characters/companions/gray-oil-cat-atlas-pixel-v1.png"],
    "승인된 원숭이·두더지·고양이 몸체가 걷기 경로에 연결되지 않았다")
assert(sleepDraws>=1 and zMarks>=15,"이불 수면 자세 또는 세 단계 Z Z Z가 그려지지 않았다")
for kind,spec in pairs(Companions.ART)do
    assert(spec.sleepCellW>spec.cellW and spec.sleepCellH>=spec.cellH and spec.sleepFoot,
        kind.." 수면 자세가 서 있는 몸과 같은 작은 셀에 축소됐다")
end
local behind=Companions.draw(state,.35,"behind",state.bounds.y1+(state.bounds.y2-state.bounds.y1)*.62)
local front=Companions.draw(state,.35,"front",state.bounds.y1+(state.bounds.y2-state.bounds.y1)*.62)
assert(behind>0 and front>0 and behind+front==#state.animals,
    "동료가 나무 앞뒤 두 깊이로 나뉘지 않는다")

for _,kind in ipairs(Companions.INTERACTION_KINDS)do
    local scene=Companions.new();Companions.sync(scene,fakeTraits(levels),1280,720)
    for _,actor in ipairs(scene.animals)do actor.state="idle"end
    assert(Companions.prepareInteractionPreview(scene,kind),kind.." 상호작용을 구성하지 못했다")
    assert(scene.interaction and scene.interaction.kind==kind and scene.interaction.phase=="play",
        kind.." 상호작용 참여자가 함께 예약되지 않았다")
    fixture.reset();Companions.draw(scene,.7)
    local propDraws,lines=0,0
    for _,op in ipairs(fixture.commands)do
        if op.op=="draw"and op.file:find("lobby%-interaction%-props")then propDraws=propDraws+1 end
        if op.op=="line"then lines=lines+1 end
    end
    assert(propDraws>0,kind.." 전용 장난감/반응 픽셀이 그려지지 않았다")
    if kind=="cat_wand"then assert(lines>=2,"낚싯대와 줄이 고양이 장난감에 연결되지 않았다")end
    Companions.update(scene,9)
    assert(not scene.interaction,"끝난 상호작용이 참여자를 계속 붙잡는다: "..kind)
end

local scheduled=Companions.new();Companions.sync(scheduled,fakeTraits(levels),1280,720)
for _,actor in ipairs(scheduled.animals)do actor.state="idle"end
scheduled.nextInteraction=.01;Companions.update(scheduled,.02)
assert(scheduled.interaction and scheduled.interaction.kind=="cat_wand",
    "일상 상태에서 첫 상호작용이 자동 예약되지 않았다")
local sleepingCat=Companions.new();Companions.sync(sleepingCat,fakeTraits(levels),1280,720)
for _,actor in ipairs(sleepingCat.animals)do if actor.kind=="cat"then actor.state="sleep"end end
assert(not Companions.prepareInteractionPreview(sleepingCat,"cat_wand"),
    "자던 고양이가 이불을 순간적으로 없애고 상호작용에 끌려갔다")
local chase=Companions.new();Companions.sync(chase,fakeTraits(levels),1280,720)
for _,actor in ipairs(chase.animals)do actor.state="idle"end
Companions.prepareInteractionPreview(chase,"chase_train")
local chaseKinds={}
for _,actor in ipairs(chase.interaction.actors)do chaseKinds[actor.kind]=true end
assert(chaseKinds.monkey and chaseKinds.mole and chaseKinds.cat,
    "최대 해금 술래잡기가 세 동물 종을 섞지 않는다")
for index=2,#chase.interaction.actors do
    local a,b=chase.interaction.actors[index-1],chase.interaction.actors[index]
    local dx,dy=a.x-b.x,a.y-b.y
    assert(math.sqrt(dx*dx+dy*dy)>=50,"술래잡기 대열의 동료가 서로 겹친다")
end

local anchored=Companions.new();Companions.sync(anchored,fakeTraits(levels),1280,720)
for _,actor in ipairs(anchored.animals)do actor.state="idle"end
Companions.prepareInteractionPreview(anchored,"cat_wand")
fixture.reset();Companions.draw(anchored,.7,nil,nil,0)
local baseX
for _,op in ipairs(fixture.commands)do if op.op=="draw"then baseX=op.args[1];break end end
fixture.reset();Companions.draw(anchored,.7,nil,nil,-37)
local shiftedX
for _,op in ipairs(fixture.commands)do if op.op=="draw"then shiftedX=op.args[1];break end end
assert(baseX and shiftedX and math.abs((shiftedX-baseX)+37)<.001,
    "동료·장난감이 전경 지면 패럴랙스와 함께 이동하지 않는다")

local lobby=read("src/lobby.lua")
local game=read("src/game.lua")
assert(lobby:find('require("src.lobby_companions")',1,true)and
    lobby:find("LobbyCompanions.sync",1,true)and lobby:find("groundOffset=-parallax*unit*7",1,true)and
    lobby:find("companionSplit,groundOffset",1,true)and lobby:find("x+groundOffset",1,true)and
    lobby:find("LobbyCompanions.setScenery",1,true)and lobby:find('kind="tree"',1,true),
    "로비가 동료 생활 모듈을 사용하지 않는다")
assert(game:find("self.lobby:update(dt,self)",1,true),
    "실제 해금 저장값이 로비 업데이트에 전달되지 않는다")
local baker=read("scripts/build_lobby_companion_sleep.py")
assert(baker:find("lobby%-companion%-sleep%-concept%-v1%.png")and
    baker:find("blanket=1",1,true)and baker:find("sleeping cap",1,true)and
    not baker:find("rotate(",1,true),
    "수면 자산이 실제 이불 원화 대신 회전 몸체를 사용한다")

print("LOBBY_COMPANIONS_OK unlocked_only=true roam=left+center+right ground_anchor=foreground_parallax tree_collision=roots+paths perspective=scale+speed+shadow sleep_scale=physical_v2 interactions=cat_wand+banana_toss+mole_peek+chase_train depth=behind_foreground")
