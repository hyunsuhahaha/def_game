local Maps=require("src.clearcut_maps")
local Bosses=require("src.biome_bosses")
local Globe=require("src.stage_select_globe")
local F=require("src.frontend_ui")
local Select={};local previews={};local landmarkAtlas,landmarkQuads

local function imageFor(def)
    local key=def.preview or def.id
    if not previews[key]then previews[key]=love.graphics.newImage("assets/maps/"..key.."-preview-v1.png");previews[key]:setFilter("nearest","nearest")end
    return previews[key]
end


local function loadLandmarks()
    if landmarkAtlas then return end
    landmarkAtlas=love.graphics.newImage("assets/ui/globe-stage-landmarks-pixel-v1.png");landmarkAtlas:setFilter("nearest","nearest")
    landmarkQuads={};for i=1,#Maps.catalog do landmarkQuads[i]=love.graphics.newQuad((i-1)*64,0,64,64,landmarkAtlas:getDimensions())end
end

function Select.update(game,dt)Globe.update(game,dt)end
local function stageCapFor(index)
    local def=Maps.catalog[index]or Maps.catalog[1]
    return Bosses.stageCap(def.id)
end
function Select.stageFor(game,index)
    local cap=stageCapFor(index or game.clearcutMapFocus or 1)
    return math.max(1,math.min(cap,game.selectedClearcutStage or 1))
end
function Select.setStage(game,stage)
    game.selectedClearcutStage=math.max(1,math.min(stageCapFor(game.clearcutMapFocus or 1),stage or 1))
end
function Select.focus(game,index,snap)
    Globe.focus(game,index,snap)
    Select.setStage(game,game.selectedClearcutStage or 1)
end
function Select.stageAt(x,y,game)
    for _,entry in ipairs(game.clearcutStageBoxes or{})do
        local box=entry.box
        if x>=box.x and x<=box.x+box.w and y>=box.y and y<=box.y+box.h then return entry.stage end
    end
end
function Select.at(x,y,game)
    if not game then return nil end
    return Globe.at(game,x,y,love.graphics.getWidth(),love.graphics.getHeight())
end
function Select.boxes(w,h,game)
    local boxes={};if not game then return boxes end
    for _,m in ipairs(Globe.markers(game,w,h))do if m.visible then boxes[#boxes+1]={x=m.x-m.r,y=m.y-m.r,w=m.r*2,h=m.r*2,index=m.index}end end
    return boxes
end
function Select.mousepressed(game,x,y,button)
    if button==1 then local stage=Select.stageAt(x,y,game);if stage then Select.setStage(game,stage);return "stage"end end
    return Globe.mousepressed(game,x,y,button,love.graphics.getWidth(),love.graphics.getHeight())
end
function Select.mousemoved(game,x,y,dx,dy)return Globe.mousemoved(game,x,y,dx,dy,love.graphics.getWidth(),love.graphics.getHeight())end
function Select.mousereleased(game,x,y,button)return Globe.mousereleased(game,x,y,button,love.graphics.getWidth(),love.graphics.getHeight())end
function Select.wheelmoved(game,x,y,delta)return Globe.wheelmoved(game,x,y,delta,love.graphics.getWidth(),love.graphics.getHeight())end

local function drawMarker(m,selected,hovered,cleared,t,font)
    if not m.visible then return end
    loadLandmarks();local c=m.def.color;local pulse=1+math.sin(t*4+m.index)*.045;local uiScale=m.uiScale or 1;local size=(hovered and 48 or selected and 44 or 38)*pulse*uiScale;local r=size*.48
    love.graphics.setColor(0,0,0,.62);love.graphics.circle("fill",m.x+3,m.y+5,r+6)
    love.graphics.setColor(c[1],c[2],c[3],hovered and .25 or .12);love.graphics.circle("fill",m.x,m.y,r+9)
    if selected then love.graphics.setLineWidth(2);love.graphics.setColor(1,.67,.25,.78+.18*math.sin(t*5));love.graphics.circle("line",m.x,m.y,r+6)end
    love.graphics.setColor(1,1,1,m.z*.26+.74);love.graphics.draw(landmarkAtlas,landmarkQuads[m.index],math.floor(m.x-size/2),math.floor(m.y-size/2),0,size/64,size/64)
    if cleared then
        love.graphics.setLineWidth(2);love.graphics.setColor(.38,1,.62,.95);love.graphics.circle("line",m.x,m.y,r+5)
        local badge=9*uiScale;local bx,by=m.x+r+5,m.y-r-4;love.graphics.setColor(.025,.11,.07,1);love.graphics.circle("fill",bx,by,badge)
        love.graphics.setColor(.45,1,.67,1);love.graphics.circle("line",bx,by,badge-1);love.graphics.setLineWidth(2.5*uiScale);love.graphics.line(bx-badge*.45,by,bx-badge*.12,by+badge*.34,bx+badge*.56,by-badge*.45)
    end
    if hovered then
        local label=m.def.name..(cleared and " · 완료" or "");local tw=math.max(116,font:getWidth(label)+24);local tx=m.x-tw/2;local ty=m.y-r-42
        love.graphics.setColor(.012,.025,.021,.96);love.graphics.rectangle("fill",tx,ty,tw,27,3,3)
        love.graphics.setColor(c);love.graphics.rectangle("line",tx+.5,ty+.5,tw-1,26,3,3)
        love.graphics.setFont(font);love.graphics.printf(label,tx,ty+6,tw,"center")
    end
    love.graphics.setLineWidth(1)
end

function Select.draw(game)
    local w,h=love.graphics.getDimensions();local f=game.fonts;local mx,my=love.mouse.getPosition();local t=love.timer.getTime();local compact=h<620
    game.clearcutMapFocus=game.clearcutMapFocus or 1
    local focus=Maps.catalog[game.clearcutMapFocus];F.backdrop(w,h,focus.color,1)
    love.graphics.setFont(f.micro);love.graphics.setColor(focus.color);love.graphics.print("WORLD OPERATIONS",34,23)
    love.graphics.setFont(f.title);love.graphics.setColor(.97,.95,.85);love.graphics.print("작전 지역 선택",34,50)
    love.graphics.setFont(f.small);love.graphics.setColor(.53,.62,.56);love.graphics.print("지구본을 드래그해 회전하고 지역 표식을 선택합니다.",34,95)

    local markers=Globe.draw(game,w,h,t);local hover=Globe.at(game,mx,my,w,h);Globe.stateFor(game).hover=hover
    for _,m in ipairs(markers)do local cleared=game.achievements and game.achievements:isMapCleared(m.def.id);drawMarker(m,m.index==game.clearcutMapFocus,m.index==hover,cleared,t,f.small)end

    local displayIndex=hover or game.clearcutMapFocus;local def=Maps.catalog[displayIndex];local accent=def.color
    local gl=Globe.layout(w,h);local rx=math.max(gl.cx+gl.r+38,w*.57);local ry=124;local rw=w-rx-34;local rh=h-202
    F.frame(rx,ry,rw,rh,accent,{selected=true})
    F.label(hover and "지역 신호 포착" or "선택된 작전",rx+20,ry+17,f.micro,accent)
    local image=imageFor(def);local iw,ih=image:getDimensions();local previewH=compact and 92 or math.min(260,rh*.32,rw*.32);local scale=math.max((rw-8)/iw,previewH/ih)
    love.graphics.setScissor(rx+4,ry+48,rw-8,previewH);love.graphics.setColor(1,1,1,1);love.graphics.draw(image,rx+rw/2,ry+48+previewH/2,0,scale,scale,iw/2,ih/2)
    for i=0,9 do local q=i/9;love.graphics.setColor(.01,.025,.021,q*.78);love.graphics.rectangle("fill",rx+4,ry+48+previewH-48+q*48,rw-8,49/9)end
    love.graphics.setScissor()
    local ty=ry+58+previewH;love.graphics.setFont(f.big);love.graphics.setColor(.98,.96,.86);love.graphics.print(def.name,rx+20,ty)
    love.graphics.setFont(f.small);love.graphics.setColor(accent);love.graphics.print(def.region.."  ·  "..def.subtitle,rx+20,ty+36)
    love.graphics.setColor(.67,.74,.68);love.graphics.printf(def.desc,rx+20,ty+61,rw-40,"left")
    local cap=Bosses.stageCap(def.id);local cleared=game.achievements and game.achievements:isMapCleared(def.id)
    if rh>650 then
        local detailY=ty+116;love.graphics.setColor(1,1,1,.08);love.graphics.line(rx+20,detailY-14,rx+rw-20,detailY-14)
        F.label("OPERATION PROFILE",rx+20,detailY,f.micro,accent)
        local boss=Bosses.definitions[Bosses.forMap(def.id)]
        local rows={{"최종 표적",boss.name},{"작전 좌표",string.format("%.1f° %s  ·  %.1f° %s",math.abs(def.globeLat),def.globeLat>=0 and "N" or "S",math.abs(def.globeLon),def.globeLon>=0 and "E" or "W")},{"진입 순서","외곽 벌목 → 생태계 반격 → 지역 보스"}}
        for i,row in ipairs(rows)do local y=detailY+34+(i-1)*38;love.graphics.setFont(f.micro);love.graphics.setColor(.45,.54,.48);love.graphics.print(row[1],rx+20,y);love.graphics.setFont(f.small);love.graphics.setColor(i==1 and accent or F.colors.ivory);love.graphics.print(row[2],rx+142,y-2)end
    end
    local selectedCap=Bosses.stageCap(focus.id)
    local selectedStage=Select.stageFor(game,game.clearcutMapFocus);game.selectedClearcutStage=selectedStage
    local sy=ry+rh-70;love.graphics.setColor(1,1,1,.08);love.graphics.line(rx+20,sy-12,rx+rw-20,sy-12)
    love.graphics.setFont(f.micro);love.graphics.setColor(.46,.55,.49);love.graphics.print("진입 스테이지",rx+20,sy+2)
    game.clearcutStageBoxes={};local buttonW=compact and 34 or 40;local gap=6;local startX=rx+132
    for stage=1,selectedCap do
        local box={x=startX+(stage-1)*(buttonW+gap),y=sy-4,w=buttonW,h=30}
        game.clearcutStageBoxes[#game.clearcutStageBoxes+1]={stage=stage,box=box}
        F.button(box,tostring(stage),f.small,{primary=stage==selectedStage,accent=accent})
    end
    local target=Maps.treeTarget(focus.id,selectedStage);local seconds=Maps.stageTimeLimit(focus.id,selectedStage)
    love.graphics.setFont(f.micro);love.graphics.setColor(.64,.71,.65);love.graphics.printf(string.format("선택 지역 목표 %d그루  ·  제한 %d분",target,math.floor(seconds/60)),rx+20,sy+33,rw-40,"right")

    love.graphics.setFont(f.micro);love.graphics.setColor(.42,.52,.47);love.graphics.print("DRAG  360° ROTATE  ·  WHEEL  "..math.floor(Globe.stateFor(game).zoom*100+.5).."%",gl.cx-gl.r,gl.cy+gl.r+18)
    love.graphics.setColor(.63,.72,.65);love.graphics.printf("표식 클릭: 즉시 선택  ·  숫자키: 해당 지역으로 회전",gl.cx-gl.r,gl.cy+gl.r+36,gl.r*2,"center")
    game.clearcutMapBackBox={x=w-180,y=30,w=146,h=38};game.clearcutMapConfirmBox={x=w-330,y=h-88,w=296,h=47}
    F.button(game.clearcutMapBackBox,"← 작업자",f.small,{accent=F.colors.teal});F.button(game.clearcutMapConfirmBox,"선택 지역으로 이동",f.body,{primary=true,key="ENT",align="left",accent=focus.color})
    F.footer(w,h,"표식/1–6  지역 선택    ·    ↑↓  스테이지 선택    ·    드래그  회전    ·    휠  확대/축소    ·    ESC  작업자",f.small)
end

return Select
