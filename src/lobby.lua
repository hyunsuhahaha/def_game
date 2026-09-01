local F=require("src.frontend_ui")
local LobbyAudio=require("src.lobby_audio")
local CdArt=require("src.lobby_cd_art")
local Lobby={};Lobby.__index=Lobby

-- 현재 플레이테스트는 기록 모드 하나에 집중한다. 일반 작전 버튼과 진입 코드는
-- 삭제하지 않았으며 Game:startClearcut 이하에 보존되어 있다.
local ACTIVE_DEVELOPMENT_MODE="score_attack"
-- 트랙 이름은 UI 문자열이 아니라 실제로 재생되는 곡 목록에서 읽는다. 예전에는
-- 여기 이름 셋만 있고 뒤에 소리가 없어서, 재생 버튼이 달린 가짜 플레이어였다.
local TRACKS={}
for _,track in ipairs(LobbyAudio.TRACKS)do TRACKS[#TRACKS+1]=track.name end

-- 배경음이 계속 흐르는 화면들. 로비 배경 위에 겹쳐 그리는 메뉴는 같은 곡을
-- 이어 듣는 편이 자연스럽고, 작전에 들어가면 멎어야 한다.
local AUDIO_MODES={lobby=true,settings=true,achievements=true,character_traits=true}
local MENU={
 {label="게임 시작",key="ENT",action="score_attack"},
 {label="강화",key="T",action="character_traits"},
 {label="연습",key="P",action="skill_sandbox"},
 {label="업적",key="A",action="achievements"},
 {label="설정",key="S",action="settings"},
}

local function inside(box,x,y)return F.inside(box,x,y)end
local function menuAction(self,index)return MENU[index or self.menuFocus or 1].action end

function Lobby.new(images,fonts)
 local pixel="assets/font-korean-pixel.ttf"
 local backgroundTrees={}
 for _,name in ipairs({"broadleaf","pine","birch","maple"})do
  local image=love.graphics.newImage("assets/trees/"..name.."-tree-cartoon-v3.png");image:setFilter("nearest","nearest");backgroundTrees[#backgroundTrees+1]=image
 end
 local backgroundProps={}
 for _,name in ipairs({"rock","fern","log"})do
  local image=love.graphics.newImage("assets/scenery/forest/"..name.."-pixel-v1.png");image:setFilter("nearest","nearest");backgroundProps[name]=image
 end
 local floor=love.graphics.newImage("assets/scenery/forest/forest-floor-decal-atlas-pixel-v1.png");floor:setFilter("nearest","nearest")
 local floorQuads={};for index=1,10 do local zero=index-1;floorQuads[index]=love.graphics.newQuad((zero%5)*128,math.floor(zero/5)*96,128,96,floor:getDimensions())end
 return setmetatable({images=images,fonts=fonts,time=0,activeDevelopmentMode=ACTIVE_DEVELOPMENT_MODE,menuFocus=1,audio=LobbyAudio.new(),audioCd=CdArt.newState(),audioTrack=1,audioPlaying=true,backgroundTrees=backgroundTrees,backgroundProps=backgroundProps,backgroundFloor=floor,backgroundFloorQuads=floorQuads,backgroundParallax=0,
  pixelTiny=love.graphics.newFont(pixel,13),pixelSmall=love.graphics.newFont(pixel,17),pixelMenu=love.graphics.newFont(pixel,26),pixelTitle=love.graphics.newFont(pixel,58)},Lobby)
end

function Lobby:update(dt)
 self.time=self.time+dt
 local mx,my=love.mouse.getPosition()
 local target=mx>=0 and math.max(-1,math.min(1,(mx/love.graphics.getWidth()-.5)*2))or 0
 self.backgroundParallax=(self.backgroundParallax or 0)+(target-(self.backgroundParallax or 0))*math.min(1,dt*4)
 for i,box in ipairs(self.menuBoxes or {})do if inside(box,mx,my)then self.menuFocus=i end end
 CdArt.update(self.audioCd,dt,self.audioPlaying and true or false)
end

-- Game:update 이 모드와 무관하게 매 프레임 부른다. 로비를 떠나면 Lobby:update 가
-- 멈추므로, 정지를 여기서 처리하지 않으면 작전 중에도 로비 음악이 계속 흐른다.
function Lobby:syncAudio(mode)
 if not self.audio then return end
 self.audio:sync(self.audioTrack or 1,AUDIO_MODES[mode] and self.audioPlaying or false)
end

function Lobby:cycleTrack(direction)
 self.audioTrack=((self.audioTrack or 1)-1+direction)%#TRACKS+1
 self.audioPlaying=true
end

function Lobby:keypressed(key)
 if key=="up" or key=="w" then self.menuFocus=((self.menuFocus or 1)-2)%#MENU+1
 elseif key=="down" then self.menuFocus=(self.menuFocus or 1)%#MENU+1
 elseif key=="return" or key=="kpenter" or key=="space" then return menuAction(self)
 elseif key=="m" then return "score_attack"
 elseif key=="t" then return "character_traits"
 elseif key=="p" then return "skill_sandbox"
 elseif key=="a" then return "achievements"
 elseif key=="s" then return "settings"
 elseif key=="r" then self.audioPlaying=not self.audioPlaying
 elseif key=="[" then self:cycleTrack(-1)
 elseif key=="]" then self:cycleTrack(1) end
end

function Lobby:mousepressed(x,y,button)
 if button~=1 then return end
 if inside(self.audioPrevBox,x,y)then self:cycleTrack(-1);return end
 if inside(self.audioPlayBox,x,y)then self.audioPlaying=not self.audioPlaying;return end
 if inside(self.audioNextBox,x,y)then self:cycleTrack(1);return end
 for i,box in ipairs(self.menuBoxes or {})do if inside(box,x,y)then self.menuFocus=i;return menuAction(self,i)end end
 -- Headless navigation tests provide the named boxes directly.
 if inside(self.scoreAttackBox,x,y)then return "score_attack"
 elseif inside(self.traitsBox,x,y)then return "character_traits"
 elseif inside(self.achievementBox,x,y)then return "achievements"
 elseif inside(self.sandboxBox,x,y)then return "skill_sandbox"
 elseif inside(self.settingsBox,x,y)then return "settings" end
end

function Lobby:drawBackground(w,h)
 local horizon=math.floor(h*.57);local unit=math.max(4,math.floor(h/120));local parallax=self.backgroundParallax or 0
 local top,middle,bottom={.11,.29,.42},{.39,.49,.55},{.89,.58,.36}
 for y=0,horizon,unit do
  local t=math.min(1,y/horizon);local a,b,mix
  if t<.55 then a,b,mix=top,middle,t/.55 else a,b,mix=middle,bottom,(t-.55)/.45 end
  mix=mix*mix*(3-2*mix);love.graphics.setColor(a[1]+(b[1]-a[1])*mix,a[2]+(b[2]-a[2])*mix,a[3]+(b[3]-a[3])*mix,1);love.graphics.rectangle("fill",0,y,w,unit+1)
 end
 local function drawBlob(x,y,radius,step,color,rowStep)
  rowStep=rowStep or step;love.graphics.setColor(color);for row=-radius,radius do local half=math.floor(math.sqrt(radius*radius-row*row));love.graphics.rectangle("fill",x-half*step,y+row*rowStep,(half*2+1)*step,rowStep)end
 end
 local sunX,sunY=math.floor((w*.80-parallax*unit*2)/unit)*unit,math.floor(h*.28/unit)*unit
 drawBlob(sunX,sunY,8,unit,{1,.66,.38,.07});drawBlob(sunX,sunY,5,unit,{1,.84,.52,1})
 local function drawCloud(x,y,size,alpha)
  x=math.floor((x-parallax*unit)/size)*size;y=math.floor(y/size)*size
  local rowStep=math.max(2,math.floor(size*.55))
  love.graphics.setColor(.27,.36,.45,alpha*.78);love.graphics.rectangle("fill",x+size*2,y,size*23,size*2)
  for _,part in ipairs({{5,0,4},{11,-2,6},{18,-1,5},{23,1,3}})do drawBlob(x+part[1]*size,y+part[2]*rowStep,part[3],size,{.27,.36,.45,alpha*.78},rowStep)end
  love.graphics.setColor(.66,.65,.66,alpha);love.graphics.rectangle("fill",x+size*2,y-rowStep,size*20,size*2)
  for _,part in ipairs({{6,-2,3},{11,-4,4},{17,-3,4},{21,-1,3}})do drawBlob(x+part[1]*size,y+part[2]*rowStep,part[3],size,{.66,.65,.66,alpha},rowStep)end
  for _,part in ipairs({{9,-5,2},{13,-6,3},{18,-4,2}})do drawBlob(x+part[1]*size,y+part[2]*rowStep,part[3],size,{.96,.82,.67,alpha*.92},rowStep)end
 end
 drawCloud(w*.70,h*.31,unit,.88);drawCloud(w*.50,h*.14,math.max(3,unit-1),.48);drawCloud(w*.90,h*.10,math.max(3,unit-1),.34)
 local function ridge(base,height,step,color,phase,shift)
  local points={0,h,0,base}
  for x=0,w+step,step do
   local sample=x+(shift or 0);local y=base-height*(.48+.22*math.sin(sample*.009+phase)+.14*math.sin(sample*.021+phase*2))
   points[#points+1]=x;points[#points+1]=math.floor(y/unit)*unit
  end
  points[#points+1]=w;points[#points+1]=h;love.graphics.setColor(color);love.graphics.polygon("fill",points)
 end
 ridge(horizon+unit*5,h*.20,unit*4,{.23,.31,.39,1},.8,parallax*unit*2)
 ridge(horizon+unit*9,h*.13,unit*3,{.10,.24,.29,1},2.1,parallax*unit*4)
 local trees=self.backgroundTrees or{}
 local function drawRow(ground,startX,count,targetH,tint,offset,overlap,shift,sway)
  if #trees>0 then
   local span=w-startX;local spacing=span/math.max(1,count-(overlap or 0))
   for i=1,count do
    local image=trees[(i+offset-2)%#trees+1];local iw,ih=image:getDimensions();local scale=targetH/ih
    local x=startX+(i-1)*spacing+(i%2)*spacing*.10+(shift or 0)+math.floor(math.sin(self.time*.55+i*1.7)*(sway or 0))
    love.graphics.setColor(tint);love.graphics.draw(image,math.floor(x),math.floor(ground-targetH),0,scale,scale)
   end
  end
 end
 drawRow(horizon+unit*8,-unit*3,14,h*.24,{.58,.64,.49,.76},2,1,-parallax*unit*3,1)
 love.graphics.setColor(.30,.43,.21,1);love.graphics.rectangle("fill",0,horizon,w,h-horizon)
 love.graphics.setColor(.42,.54,.27,1);love.graphics.rectangle("fill",0,horizon,w,unit*5)
 local floor,floorQuads=self.backgroundFloor,self.backgroundFloorQuads or{}
 local function drawFloor(index,x,y,scale,alpha,flip)
  if not floor or not floorQuads[index]then return end
  love.graphics.setColor(1,1,1,alpha);love.graphics.draw(floor,floorQuads[index],math.floor(x-parallax*unit*5),math.floor(y),0,scale*(flip or 1),scale,64,48)
 end
 drawFloor(4,w*.67,h*.62,.80,.38);drawFloor(1,w*.68,h*.72,1.18,.42,-1);drawFloor(4,w*.70,h*.84,1.72,.48)
 drawFloor(8,w*.27,h*.72,1.38,.24,-1);drawFloor(4,w*.42,h*.84,1.50,.27);drawFloor(3,w*.35,h*.91,.76,.58,-1)
 drawFloor(2,w*.55,h*.89,.78,.82);drawFloor(3,w*.46,h*.78,.68,.66,-1);drawFloor(6,w*.91,h*.86,.82,.78)
 drawRow(h*.93,w*.55,5,h*.43,{1,1,1,1},1,1,-parallax*unit*7,2)
 local props=self.backgroundProps or{}
 local function drawProp(name,x,ground,targetH,tint)
  local image=props[name];if not image then return end
  local iw,ih=image:getDimensions();local scale=targetH/ih;love.graphics.setColor(tint or{1,1,1,1});love.graphics.draw(image,math.floor(x-parallax*unit*8),math.floor(ground-targetH),0,scale,scale)
 end
 drawProp("rock",w*.50,h*.93,h*.10,{1,1,1,1});drawProp("log",w*.73,h*.96,h*.11,{1,1,1,1})
 drawProp("fern",w*.46,h*.91,h*.085,{1,1,1,1});drawProp("fern",w*.88,h*.94,h*.10,{1,1,1,1})
 love.graphics.setColor(.14,.28,.16,.72);love.graphics.rectangle("fill",0,h*.955,w,h*.045)
 for i=1,18 do
  local x=math.floor(w*(.43+((i*37)%57)/100));local y=math.floor(h*(.31+((i*23)%54)/100))
  love.graphics.setColor(1,.75,.24,.18+.18*math.abs(math.sin(self.time*1.4+i)));love.graphics.rectangle("fill",x,y,unit,unit)
 end
end

local function pixelFrame(x,y,w,h,selected)
 love.graphics.setColor(.006,.028,.020,.58);love.graphics.rectangle("fill",x+5,y+6,w,h)
 love.graphics.setColor(selected and {.072,.205,.132,1}or{.032,.098,.068,1})
 love.graphics.rectangle("fill",x+5,y,w-10,h);love.graphics.rectangle("fill",x,y+5,w,h-10)
 local color=selected and {.98,.67,.20,1}or{.25,.57,.40,.88};love.graphics.setColor(color)
 love.graphics.rectangle("fill",x+6,y,w-12,2);love.graphics.rectangle("fill",x+6,y+h-2,w-12,2)
 love.graphics.rectangle("fill",x,y+6,2,h-12);love.graphics.rectangle("fill",x+w-2,y+6,2,h-12)
 love.graphics.rectangle("fill",x+2,y+2,5,2);love.graphics.rectangle("fill",x+w-7,y+2,5,2)
 love.graphics.rectangle("fill",x+2,y+h-4,5,2);love.graphics.rectangle("fill",x+w-7,y+h-4,5,2)
end

local function drawCursor(x,y,h,pulse)
 local offset=pulse and 2 or 0;love.graphics.setColor(.98,.65,.18,1)
 love.graphics.rectangle("fill",x+offset,y+h/2-9,5,18)
 love.graphics.rectangle("fill",x+5+offset,y+h/2-6,5,12)
 love.graphics.rectangle("fill",x+10+offset,y+h/2-3,5,6)
end

function Lobby:drawMenu(game,x,y,w,rowH,gap,menuFont,keyFont)
 self.menuBoxes={}
 for i,item in ipairs(MENU)do
  local box={x=x,y=y+(i-1)*(rowH+gap),w=w,h=rowH};self.menuBoxes[i]=box
  if item.action=="score_attack"then self.scoreAttackBox=box
  elseif item.action=="character_traits"then self.traitsBox=box
  elseif item.action=="skill_sandbox"then self.sandboxBox=box
  elseif item.action=="achievements"then self.achievementBox=box
  elseif item.action=="settings"then self.settingsBox=box end
  local selected=i==(self.menuFocus or 1);pixelFrame(box.x+22,box.y,box.w-22,box.h,selected)
  if selected then drawCursor(box.x,box.y,box.h,math.floor(self.time*3)%2==0)end
  love.graphics.setFont(menuFont);love.graphics.setColor(selected and {.995,.96,.77,1}or{.68,.79,.65,1});love.graphics.print(item.label,box.x+48,box.y+box.h/2-menuFont:getHeight()/2-1)
  love.graphics.setFont(keyFont);love.graphics.setColor(selected and {.98,.67,.20,1}or{.43,.68,.51,1})
  local suffix="["..item.key.."]"
  if item.action=="character_traits"and game and game.characterTraits then suffix=string.format("%d P   %s",game.characterTraits.data.currency or 0,suffix)end
  love.graphics.printf(suffix,box.x,box.y+box.h/2-keyFont:getHeight()/2,box.w-16,"right")
 end
end

function Lobby:drawAudio(x,y,w,h,font)
 love.graphics.setColor(.020,.070,.050,.97);love.graphics.rectangle("fill",x,y,w,h)
 love.graphics.setColor(.34,.72,.50,.88);love.graphics.rectangle("fill",x,y,w,2);love.graphics.rectangle("fill",x,y+h-2,w,2);love.graphics.rectangle("fill",x,y,2,h);love.graphics.rectangle("fill",x+w-2,y,2,h)
 love.graphics.setColor(.95,.62,.18,.92);love.graphics.rectangle("fill",x,y,5,h)
 local button=math.min(28,h-12);local by=y+(h-button)/2
 self.audioPrevBox={x=x+12,y=by,w=button,h=button};self.audioPlayBox={x=x+46,y=by,w=button,h=button};self.audioNextBox={x=x+80,y=by,w=button,h=button}
 for _,data in ipairs({{self.audioPrevBox,"<"},{self.audioPlayBox,self.audioPlaying and "II"or">"},{self.audioNextBox,">"}})do
  local box,label=data[1],data[2];local hover=inside(box,love.mouse.getPosition())
  love.graphics.setColor(hover and {.12,.28,.19,1}or{.04,.13,.09,1});love.graphics.rectangle("fill",box.x,box.y,box.w,box.h)
  love.graphics.setColor(hover and {.95,.62,.18,1}or{.39,.68,.52,1});love.graphics.rectangle("line",box.x+.5,box.y+.5,box.w-1,box.h-1)
  love.graphics.setFont(font);love.graphics.printf(label,box.x,box.y+box.h/2-font:getHeight()/2-1,box.w,"center")
 end
 local waveX=x+122;local waveW=math.min(112,w*.27)
 for i=0,15 do
  local blocks=self.audioPlaying and 1+math.floor((math.sin(i*1.7+self.time*3)+1)*2.5)or 1
  for b=1,blocks do love.graphics.setColor(.95,.62,.18,self.audioPlaying and .88 or .28);love.graphics.rectangle("fill",waveX+i*(waveW/16),y+h/2+10-b*5,4,3)end
 end
 love.graphics.setFont(font);love.graphics.setColor(.70,.82,.67);love.graphics.printf(TRACKS[self.audioTrack or 1],waveX+waveW+12,y+h/2-font:getHeight()/2-1,w-(waveX-x)-waveW-24,"right")
 self:drawAudioDeck(x,y,h)
end

-- 플레이어 바 위에 솟은 CD 데크. 원반만 띄우면 아이콘으로 보인다. 바와 같은
-- 색·테두리로 짓고 아랫변을 일부러 바에 물려서 이음매를 지운다 — 두 상자가
-- 붙어 있는 게 아니라 한 기계의 위층으로 읽혀야 한다.
function Lobby:drawAudioDeck(x,y,h)
 local deckW=64
 local cx=x+deckW/2
 local top=y-58
 local cy=y-30
 love.graphics.setColor(.020,.070,.050,.97)
 love.graphics.rectangle("fill",x,top,deckW,y-top+2)
 love.graphics.setColor(.34,.72,.50,.88)
 love.graphics.rectangle("fill",x,top,deckW,2)
 love.graphics.rectangle("fill",x,top,2,y-top)
 love.graphics.rectangle("fill",x+deckW-2,top,2,y-top+2)
 -- 바의 주황 강조를 그대로 이어 올려 한 기계로 묶는다.
 love.graphics.setColor(.95,.62,.18,.92)
 love.graphics.rectangle("fill",x,top,5,y-top)
 -- 데크와 바 사이의 이음매를 지운다. 바의 윗변 테두리가 데크 밑으로 지나가면
 -- 한 기계의 위층이 아니라 바 위에 올려놓은 별개의 상자로 보인다.
 love.graphics.setColor(.020,.070,.050,1)
 love.graphics.rectangle("fill",x+5,y-2,deckW-7,5)
 -- 원반이 앉는 우묵한 자리. 이게 없으면 원반이 패널 위에 붙은 스티커로 보인다.
 love.graphics.setColor(.008,.030,.022,.95)
 love.graphics.circle("fill",cx,cy,25)
 love.graphics.setColor(.20,.44,.33,.85)
 love.graphics.circle("line",cx,cy,25)
 CdArt.draw(self.audioCd,cx,cy)
 -- 재생 표시등. 멈추면 꺼지는 게 아니라 어두워진다 — 전원은 들어와 있다.
 love.graphics.setColor(.95,.62,.18,self.audioPlaying and .95 or .30)
 love.graphics.rectangle("fill",x+deckW-11,top+6,4,4)
end

function Lobby:draw(game)
 local w,h=love.graphics.getDimensions();local f=self.fonts
 local titleFont=self.pixelTitle or f.display or self.displayFont or f.heading
 local menuFont=self.pixelMenu or f.heading;local smallFont=self.pixelSmall or f.small;local tinyFont=self.pixelTiny or f.small
 self:drawBackground(w,h)
 local compact=w<1080 or h<640;local x=math.max(24,math.floor(w*.07));local menuW=math.min(compact and 430 or 470,math.floor(w*.46))
 local titleY=math.floor(h*(compact and .09 or .11))
 love.graphics.setFont(titleFont);love.graphics.setColor(.035,.16,.11,1);love.graphics.print("LAST HAUL",x+4,titleY+5)
 love.graphics.setColor(1,.95,.72);love.graphics.print("LAST HAUL",x,titleY)
 love.graphics.setFont(smallFont);love.graphics.setColor(.52,.88,.62);love.graphics.print("벌목 기록",x+3,titleY+titleFont:getHeight()+1)
 local rowH=compact and 46 or 54;local gap=compact and 5 or 7;local menuY=titleY+titleFont:getHeight()+44
 self:drawMenu(game,x,menuY,menuW,rowH,gap,menuFont,tinyFont)
 local audioW=math.min(compact and 530 or 590,w-x*2);self:drawAudio(x,h-(compact and 62 or 72),audioW,compact and 44 or 48,tinyFont)
 love.graphics.setFont(tinyFont);love.graphics.setColor(.48,.70,.55);love.graphics.printf("R 재생  ·  [ ] 트랙  ·  ESC 종료",0,h-22,w-x,"right")
end

return Lobby
