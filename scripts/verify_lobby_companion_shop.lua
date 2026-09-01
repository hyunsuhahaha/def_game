package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Traits=require("src.character_traits")
local Shop=require("src.lobby_companion_shop")
local Companions=require("src.lobby_companions")

local function read(path)local file=assert(io.open(path,"rb"));local data=file:read("*a");file:close();return data end
local function be32(png,offset)local a,b,c,d=png:byte(offset,offset+3);return((a*256+b)*256+c)*256+d end
for path,size in pairs({
    ["assets/ui/lobby-companion-shop-pixel-v1.png"]={192,144},
    ["assets/ui/lobby-companion-shop-small-pixel-v1.png"]={144,108},
    ["assets/ui/lobby-playgrounds-pixel-v2.png"]={640,128},
    ["assets/ui/lobby-swing-motion-pixel-v1.png"]={1280,128},
})do
    local png=read(path)
    assert(png:sub(2,4)=="PNG"and be32(png,17)==size[1]and be32(png,21)==size[2],path..": 크기 오류")
    assert(png:byte(26)==6,path..": 투명 RGBA가 아니다")
end

local traits=Traits.new(true);traits.data.currency=30
assert(traits:buyLobbyItem("ball_court",8)and traits.data.currency==22,"저가 놀이터 구매가 적용되지 않았다")
assert(traits:hasLobbyItem("ball_court"),"구매한 놀이터 소유 상태가 없다")
local duplicate=traits:buyLobbyItem("ball_court",8);assert(not duplicate and traits.data.currency==22,"중복 구매가 코인을 차감했다")
local decoded=Traits.decode(Traits.encode(traits.data))
assert(decoded.lobbyItems.ball_court,"놀이터 구매가 저장/복원되지 않았다")
traits.data.currency=3;assert(not traits:buyLobbyItem("forest_swing",24),"코인이 부족한 구매가 승인됐다")

local state=Shop.new()
local amenities=Shop.amenities(state,{data=decoded},1280,720)
assert(#amenities==1 and amenities[1].kind=="ball","구매한 시설만 로비 공터에 배치되지 않았다")
local allItems={data={lobbyItems={ball_court=true,sand_burrow=true,cat_tower=true,forest_swing=true}}}
local layout=Shop.amenities(state,allItems,1280,720);local byKind={}
for _,amenity in ipairs(layout)do byKind[amenity.kind]=amenity end
assert(#layout==4 and byKind.swing.y<byKind.ball.y and byKind.ball.y<byKind.cat_tower.y and
    byKind.cat_tower.y<byKind.sand.y,"놀이터가 뒤·중간·앞 깊이로 분산되지 않았다")
assert(byKind.swing.y<720*.75 and byKind.sand.y>720*.85,"그네는 뒤쪽, 모래굴은 앞쪽 지면에 있어야 한다")
assert(byKind.swing.scale<byKind.ball.scale and byKind.ball.scale<byKind.sand.scale,
    "뒤쪽 놀이터가 동료와 같은 원근 배율로 작아지지 않는다")
love.graphics.getDimensions=function()return 1280,720 end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}
local fonts={}
for name,size in pairs({micro=12,small=14,body=17,heading=21,title=36})do fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)end
fixture.reset();Shop.drawBuilding(state,1280,720,1,fonts.small)
assert(state.buildingBox and Shop.openAtBuilding(state,state.buildingBox.x+4,state.buildingBox.y+4),"배경 상점 건물이 클릭 영역을 열지 않는다")
local shopDraw=false
for _,op in ipairs(fixture.commands)do if op.op=="draw"and op.file:find("lobby%-companion%-shop")then shopDraw=true end end
fixture.reset();Shop.drawOverlay(state,traits,fonts)
assert(#state.itemBoxes==4 and state.closeBox,"상점 오버레이에 네 상품과 닫기 버튼이 없다")
traits.data.currency=30
local sandBox=state.itemBoxes[2]
assert(Shop.mousepressed(state,sandBox.x+sandBox.w/2,sandBox.y+sandBox.h/2,1,traits)and
    traits:hasLobbyItem("sand_burrow")and traits.data.currency==16,"상점 상품 클릭이 구매·차감·설치로 이어지지 않았다")
local playDraw=false
fixture.reset();Shop.drawPlaygrounds(state,{data=decoded},1280,720,1)
local playgroundX
for _,op in ipairs(fixture.commands)do if op.op=="draw"and op.file:find("lobby%-playgrounds")then playDraw=true end end
assert(shopDraw and playDraw,"상점 건물 또는 구매 시설 자산이 실제로 그려지지 않았다")
for _,op in ipairs(fixture.commands)do if op.op=="draw"and op.file:find("lobby%-playgrounds")then playgroundX=op.args[1];break end end
fixture.reset();Shop.drawPlaygrounds(state,{data=decoded},1280,720,1,-37)
local shiftedX
for _,op in ipairs(fixture.commands)do if op.op=="draw"and op.file:find("lobby%-playgrounds")then shiftedX=op.args[1];break end end
assert(playgroundX and shiftedX and math.abs((shiftedX-playgroundX)+37)<.001,"놀이터가 로비 지면 패럴랙스에서 미끄러진다")

local levels={fire_score_axe_crew=1,universal_mole_companion=1,universal_gray_cat=1}
local fake={getLevel=function(_,id)return levels[id]or 0 end}
local companions=Companions.new();Companions.sync(companions,fake,1280,720)
Companions.setAmenities(companions,{{id="ball_court",kind="ball",x=600,y=590},{id="sand_burrow",kind="sand",x=740,y=620},
    {id="cat_tower",kind="cat_tower",x=880,y=600},{id="forest_swing",kind="swing",x=1020,y=570}})
for _,kind in ipairs({"ball","sand","cat_tower","swing"})do
    assert(Companions.prepareAmenityPreview(companions,kind),kind.." 시설을 이용할 동료를 찾지 못했다")
    local actor
    for _,candidate in ipairs(companions.animals)do if candidate.state=="play"and candidate.playAmenity==kind then actor=candidate;break end end
    assert(actor,kind.." 시설에서 동료 놀이 상태가 시작되지 않았다")
    Companions.update(companions,.1)
    assert(math.abs(actor.interactionLift or 0)>0 or math.abs(actor.renderOffsetY or 0)>0 or
        math.abs(actor.renderOffsetX or 0)>0,kind.." 시설 전용 동작이 없다")
end

local motion=Companions.new();Companions.sync(motion,fake,1280,720)
Companions.setAmenities(motion,{{id="cat_tower",kind="cat_tower",x=860,y=605},{id="forest_swing",kind="swing",x=1010,y=570}})
assert(Companions.prepareAmenityPreview(motion,"cat_tower"),"캣타워 동작 준비 실패")
local cat
for _,actor in ipairs(motion.animals)do if actor.kind=="cat"then cat=actor;break end end
Companions.setAmenities(motion,{{id="cat_tower",kind="cat_tower",x=1060,y=690},{id="forest_swing",kind="swing",x=1010,y=570}})
assert(cat.x==1030 and cat.y==690,"화면 전환 뒤 이용 중인 동료가 새 시설 앵커를 따라가지 않는다")
fixture.reset();Companions.draw(motion,1)
local scaleBefore
for _,op in ipairs(fixture.commands)do if op.op=="draw"and op.file:find("gray%-oil%-cat")then scaleBefore=math.abs(op.args[4]);break end end
Companions.update(motion,1.7)
assert(cat.renderOffsetY<=-70,"고양이가 캣타워 꼭대기까지 실제로 오르지 않는다")
Companions.update(motion,1.55)
assert(cat.renderOffsetX>35 and cat.renderOffsetY<0,"고양이의 꼭대기→지면 포물선 점프가 없다")
fixture.reset();Companions.draw(motion,1)
local scaleDuring
for _,op in ipairs(fixture.commands)do if op.op=="draw"and op.file:find("gray%-oil%-cat")then scaleDuring=math.abs(op.args[4]);break end end
assert(scaleBefore and scaleDuring and math.abs(scaleBefore-scaleDuring)<.0001,"시설 이용 중 고양이 몸 크기가 변한다")
Companions.update(motion,2.3)
assert(cat.state=="walk"and not motion.amenities[1].reservedBy,"캣타워 착지 후 시설 예약이 해제되지 않는다")
assert(Companions.prepareAmenityPreview(motion,"swing"),"그네 동작 준비 실패")
local rider
for _,actor in ipairs(motion.animals)do if actor.state=="play"and actor.playAmenity=="swing"then rider=actor;break end end
Companions.update(motion,.9)
assert(rider.swingFrame and rider.renderOffsetY<-15 and math.abs(rider.renderOffsetX)>0,
    "그네 프레임과 동물 발선이 같은 궤도를 사용하지 않는다")

local lobby=read("src/lobby.lua");local game=read("src/game.lua")
assert(lobby:find('require("src.lobby_companion_shop")',1,true)and
    lobby:find("CompanionShop.drawBuilding",1,true)and lobby:find("CompanionShop.openAtBuilding",1,true)and
    lobby:find("CompanionShop.drawPlaygrounds",1,true),"로비 배경 건물 클릭 흐름이 연결되지 않았다")
assert(game:find("self.lobby:mousepressed(x, y, button)",1,true)and
    lobby:find("self.shopTraits",1,true),"구매 저장소가 로비 클릭에 전달되지 않았다")
local migrated=Traits.decode("currency=0\nlobby_item_log_jungle=1\n")
assert(migrated.lobbyItems.cat_tower and not migrated.lobbyItems.log_jungle,"초기 정글짐 구매가 캣타워로 승계되지 않았다")
print("LOBBY_COMPANION_SHOP_OK building=left_ground_click prices=8+14+18+24 persistence=true amenities=ball+sand+cat_tower+swing")
