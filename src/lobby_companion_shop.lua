local Frontend=require("src.frontend_ui")
local Shop={}

local ITEMS={
    {id="ball_court",name="공놀이 울타리",cost=8,kind="ball",animal="모든 동물",
        desc="알록달록한 공 세 개. 동료들이 공터로 모여 번갈아 쫓아갑니다."},
    {id="sand_burrow",name="모래 굴 놀이터",cost=14,kind="sand",animal="두더지",
        desc="부드러운 모래와 짧은 굴. 두더지가 들어갔다 얼굴을 내밉니다."},
    {id="cat_tower",name="숲속 캣타워",cost=18,kind="cat_tower",animal="고양이",
        desc="세 층 발판과 숨숨집. 고양이가 꼭대기에 올랐다 아래로 뛰어내립니다."},
    {id="forest_swing",name="통나무 그네",cost=24,kind="swing",animal="원숭이·고양이",
        desc="튼튼한 통나무 프레임과 밧줄 좌석. 동료가 주기적으로 그네를 탑니다."},
}
Shop.ITEMS=ITEMS

local function inside(box,x,y)return box and x>=box.x and x<=box.x+box.w and y>=box.y and y<=box.y+box.h end
local function owned(traits,id)return traits and traits.data and traits.data.lobbyItems and traits.data.lobbyItems[id]==true end

local function loadImage(path)
    local ok,image=pcall(love.graphics.newImage,path)
    if not ok then return nil end
    image:setFilter("nearest","nearest");return image
end

function Shop.new()
    local state={open=false,message="",messageTime=0,itemBoxes={}}
    state.large=loadImage("assets/ui/lobby-companion-shop-pixel-v1.png")
    state.small=loadImage("assets/ui/lobby-companion-shop-small-pixel-v1.png")
    state.playgrounds=loadImage("assets/ui/lobby-playgrounds-pixel-v2.png")
    state.swingMotion=loadImage("assets/ui/lobby-swing-motion-pixel-v1.png")
    if state.playgrounds then
        state.quads={}
        for index=0,3 do state.quads[index+1]=love.graphics.newQuad(index*160,0,160,128,state.playgrounds:getDimensions())end
    end
    if state.swingMotion then
        state.swingQuads={}
        for index=0,7 do state.swingQuads[index+1]=love.graphics.newQuad(index*160,0,160,128,state.swingMotion:getDimensions())end
    end
    return state
end

function Shop.update(state,dt)
    if state then state.messageTime=math.max(0,(state.messageTime or 0)-dt)end
end

function Shop.amenities(state,traits,w,h)
    local result={}
    local positions={{w*.43,h*.80},{w*.55,h*.875},{w*.67,h*.84},{w*.79,h*.79}}
    for index,item in ipairs(ITEMS)do if owned(traits,item.id)then
        result[#result+1]={id=item.id,kind=item.kind,x=math.floor(positions[index][1]),y=math.floor(positions[index][2])}
    end end
    return result
end

local function swingFrame(companions)
    for _,actor in ipairs(companions and companions.animals or{})do
        if actor.state=="play"and actor.playAmenity=="swing"then
            return actor.swingFrame or(math.floor((actor.playClock or 0)*5)%8+1)
        end
    end
    return 3
end

function Shop.drawPlaygrounds(state,traits,w,h,light,groundOffsetX,companions,pass,splitY)
    if not state or not state.playgrounds then return end
    local tint=.62+.38*(light or 1)
    love.graphics.setColor(tint,tint,tint,1)
    for _,amenity in ipairs(Shop.amenities(state,traits,w,h))do
        local selected=not pass or(pass=="behind"and amenity.y<(splitY or math.huge))or
            (pass=="front"and amenity.y>=(splitY or-math.huge))
        if selected then
            local index=amenity.kind=="ball"and 1 or amenity.kind=="sand"and 2 or amenity.kind=="cat_tower"and 3 or 4
            local x=amenity.x+math.floor(groundOffsetX or 0)
            love.graphics.draw(state.playgrounds,state.quads[index],x,amenity.y,0,1,1,80,116)
            if amenity.kind=="swing"and state.swingMotion then
                love.graphics.draw(state.swingMotion,state.swingQuads[swingFrame(companions)],x,amenity.y,0,1,1,80,116)
            end
        end
    end
    love.graphics.setColor(1,1,1,1)
end

function Shop.drawBuilding(state,w,h,light,font,groundOffsetX)
    if not state then return end
    local compact=w<1080 or h<640;local image=compact and state.small or state.large
    if not image then return end
    -- 로비 왼쪽 메뉴가 끝나는 아래쪽 공터에 발을 붙인다. 전경 나무 수관 위에
    -- 얹혀 보이던 우측 배치를 사용하지 않으며, 바닥선은 다른 전경 소품과 같다.
    local iw,ih=image:getDimensions();local x=math.floor(w*.04+(groundOffsetX or 0));local y=math.floor(h*.945-ih)
    state.buildingBox={x=x+8,y=y+8,w=iw-16,h=ih-8}
    local tint=.58+.42*(light or 1);love.graphics.setColor(tint,tint,tint,1);love.graphics.draw(image,x,y)
    local mx,my=love.mouse.getPosition();local hover=inside(state.buildingBox,mx,my)
    if hover then
        love.graphics.setColor(.95,.62,.18,.92);love.graphics.setLineWidth(2)
        love.graphics.rectangle("line",state.buildingBox.x+.5,state.buildingBox.y+.5,state.buildingBox.w-1,state.buildingBox.h-1,3,3)
        love.graphics.setFont(font);love.graphics.setColor(.98,.91,.67,1)
        love.graphics.printf("클릭 · 동물용품점",x-20,y-20,iw+40,"center")
        love.graphics.setLineWidth(1)
    end
    love.graphics.setColor(1,1,1,1)
end

function Shop.openAtBuilding(state,x,y)
    if state and inside(state.buildingBox,x,y)then state.open=true;state.message="";return true end
    return false
end

function Shop.mousepressed(state,x,y,button,traits)
    if not state or not state.open or button~=1 then return false end
    if inside(state.closeBox,x,y)then state.open=false;return true end
    for index,box in ipairs(state.itemBoxes or{})do if inside(box,x,y)then
        local item=ITEMS[index]
        if owned(traits,item.id)then state.message="이미 공터에 설치했습니다"
        elseif not traits or not traits.buyLobbyItem then state.message="구매 저장소를 불러오지 못했습니다"
        else
            local ok,reason=traits:buyLobbyItem(item.id,item.cost)
            state.message=ok and(item.name.." 설치 완료!")or reason
        end
        state.messageTime=3;return true
    end end
    return true
end

function Shop.drawOverlay(state,traits,fonts)
    if not state or not state.open then return end
    local w,h=love.graphics.getDimensions();local compact=w<1080 or h<640
    love.graphics.setColor(0,0,0,.76);love.graphics.rectangle("fill",0,0,w,h)
    local pw=math.min(compact and w-48 or 900,w-48);local ph=math.min(compact and h-30 or 610,h-30)
    local px,py=math.floor((w-pw)/2),math.floor((h-ph)/2)
    Frontend.frame(px,py,pw,ph,Frontend.colors.teal,{selected=true})
    Frontend.label("동물용품점",px+24,py+18,fonts.micro,Frontend.colors.teal)
    love.graphics.setFont(compact and fonts.heading or fonts.title);love.graphics.setColor(.98,.95,.82)
    love.graphics.print("숲속 꼬리 상점",px+24,py+42)
    love.graphics.setFont(fonts.small);love.graphics.setColor(.58,.70,.62)
    love.graphics.print("전투 성능과 무관한 로비 놀이터 · 구매 즉시 공터에 설치",px+24,py+(compact and 68 or 88))
    local coins=traits and traits.data and traits.data.currency or 0
    Frontend.badge(string.format("연구 코인  %d P",coins),px+pw-190,py+22,160,fonts.small,Frontend.colors.amber)
    state.closeBox={x=px+pw-66,y=py+ph-46,w=42,h=28}
    Frontend.button(state.closeBox,"X",fonts.small,{accent=Frontend.colors.teal})
    local top=py+(compact and 92 or 132);local gap=compact and 8 or 12
    local cardH=math.floor((ph-(top-py)-58-gap*3)/4);state.itemBoxes={}
    for index,item in ipairs(ITEMS)do
        local box={x=px+24,y=top+(index-1)*(cardH+gap),w=pw-48,h=cardH};state.itemBoxes[index]=box
        local has=owned(traits,item.id);local affordable=coins>=item.cost
        Frontend.frame(box.x,box.y,box.w,box.h,has and Frontend.colors.teal or Frontend.colors.amber,{selected=has,corner=false})
        love.graphics.setFont(fonts.body);love.graphics.setColor(.96,.94,.83);love.graphics.print(item.name,box.x+18,box.y+10)
        love.graphics.setFont(fonts.small);love.graphics.setColor(.58,.69,.62)
        if not compact then love.graphics.print(item.desc,box.x+18,box.y+35)end
        love.graphics.setColor(.47,.72,.56);love.graphics.print("이용: "..item.animal,box.x+18,box.y+cardH-(compact and 22 or 25))
        local label=has and"설치됨"or string.format("%d P",item.cost)
        love.graphics.setColor(has and Frontend.colors.teal or affordable and Frontend.colors.amber or Frontend.colors.rust)
        love.graphics.printf(label,box.x+box.w-128,box.y+cardH/2-fonts.body:getHeight()/2,104,"center")
    end
    if state.messageTime>0 then
        love.graphics.setFont(fonts.small);love.graphics.setColor(.98,.76,.28)
        love.graphics.printf(state.message,px+180,py+ph-38,pw-360,"center")
    end
end

function Shop.close(state)if state then state.open=false end end
function Shop.isOpen(state)return state and state.open==true end
function Shop.isOwned(traits,id)return owned(traits,id)end

return Shop
