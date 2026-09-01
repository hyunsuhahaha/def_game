local F=require("src.frontend_ui")
local LobbyAudio=require("src.lobby_audio")
local CdArt=require("src.lobby_cd_art")
local TimeOfDay=require("src.lobby_time_of_day")
local LobbyCompanions=require("src.lobby_companions")
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
 return setmetatable({images=images,fonts=fonts,time=0,activeDevelopmentMode=ACTIVE_DEVELOPMENT_MODE,menuFocus=1,audio=LobbyAudio.new(),audioCd=CdArt.newState(),audioTrack=1,audioPlaying=true,lobbyCompanions=LobbyCompanions.new(),backgroundTrees=backgroundTrees,backgroundProps=backgroundProps,backgroundFloor=floor,backgroundFloorQuads=floorQuads,backgroundParallax=0,
  pixelTiny=love.graphics.newFont(pixel,13),pixelSmall=love.graphics.newFont(pixel,17),pixelMenu=love.graphics.newFont(pixel,26),pixelTitle=love.graphics.newFont(pixel,58)},Lobby)
end

function Lobby:update(dt,game)
 self.time=self.time+dt
 local mx,my=love.mouse.getPosition()
 local target=mx>=0 and math.max(-1,math.min(1,(mx/love.graphics.getWidth()-.5)*2))or 0
 self.backgroundParallax=(self.backgroundParallax or 0)+(target-(self.backgroundParallax or 0))*math.min(1,dt*4)
 for i,box in ipairs(self.menuBoxes or {})do if inside(box,mx,my)then self.menuFocus=i end end
 CdArt.update(self.audioCd,dt,self.audioPlaying and true or false)
 local w,h=love.graphics.getDimensions()
 LobbyCompanions.sync(self.lobbyCompanions,game and game.characterTraits,w,h)
 LobbyCompanions.update(self.lobbyCompanions,dt)
end

-- Game:update 이 모드와 무관하게 매 프레임 부른다. 로비를 떠나면 Lobby:update 가
-- 멈추므로, 정지를 여기서 처리하지 않으면 작전 중에도 로비 음악이 계속 흐른다.
function Lobby:syncAudio(mode,volume)
 if not self.audio then return end
 self.audio:setVolume(volume or 1)
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

function Lobby:drawBackground(w,h,showCompanions)
 local horizon=math.floor(h*.57);local unit=math.max(4,math.floor(h/120));local parallax=self.backgroundParallax or 0
 -- os.date("*t") reads the player's PC-local civil time. The optional override
 -- exists only for deterministic offscreen captures and regression tests.
 local sky=TimeOfDay.state(self.timeOfDayOverride or TimeOfDay.localHour())
 local top,middle,bottom=sky.top,sky.middle,sky.bottom
 for y=0,horizon,unit do
  local t=math.min(1,y/horizon);local a,b,mix
  if t<.55 then a,b,mix=top,middle,t/.55 else a,b,mix=middle,bottom,(t-.55)/.45 end
  mix=mix*mix*(3-2*mix);love.graphics.setColor(a[1]+(b[1]-a[1])*mix,a[2]+(b[2]-a[2])*mix,a[3]+(b[3]-a[3])*mix,1);love.graphics.rectangle("fill",0,y,w,unit+1)
 end
 local function drawBlob(x,y,radius,step,color,rowStep)
  rowStep=rowStep or step;love.graphics.setColor(color);for row=-radius,radius do local half=math.floor(math.sqrt(radius*radius-row*row));love.graphics.rectangle("fill",x-half*step,y+row*rowStep,(half*2+1)*step,rowStep)end
 end
 -- Sparse fixed-grid stars stay behind clouds and scenery. Their brightness is
 -- continuous through dusk/dawn, so crossing 18:00 never pops a whole layer on.
 if sky.stars>0 then for index=1,34 do
  local x=math.floor(w*((index*73)%997)/997/unit)*unit
  local y=math.floor(h*(.055+((index*47)%409)/409*.40)/unit)*unit
  local twinkle=.52+.48*math.abs(math.sin(self.time*.75+index*1.91))
  love.graphics.setColor(.72,.82,1,sky.stars*(index%5==0 and .88 or .48)*twinkle)
  love.graphics.rectangle("fill",x,y,index%7==0 and unit*2 or unit,unit)
 end end
 local celestialX=math.floor((w*sky.celestialX-parallax*unit*2)/unit)*unit
 local celestialY=math.floor(h*sky.celestialY/unit)*unit
 if sky.celestial=="sun"then
  drawBlob(celestialX,celestialY,8,unit,{1,.61,.27,.09});drawBlob(celestialX,celestialY,5,unit,{1,.84,.52,1})
  drawBlob(celestialX-unit,celestialY-unit,3,unit,{1,.91,.63,1})
 else
  drawBlob(celestialX,celestialY,7,unit,{.48,.61,.86,.10});drawBlob(celestialX,celestialY,5,unit,{.80,.86,.82,1})
  drawBlob(celestialX-unit,celestialY-unit,4,unit,{.91,.88,.72,1})
  drawBlob(celestialX-unit*2,celestialY+unit,1,unit,{.56,.62,.61,.72})
  drawBlob(celestialX+unit*2,celestialY-unit,1,unit,{.62,.66,.63,.66})
 end
 local function drawCloud(x,y,size,alpha)
  x=math.floor((x-parallax*unit)/size)*size;y=math.floor(y/size)*size
  local rowStep=math.max(2,math.floor(size*.55))
  local light=sky.light;local shadow={.11+.16*light,.16+.20*light,.24+.21*light,alpha*.78}
  local body={.24+.42*light,.28+.37*light,.34+.32*light,alpha}
  local highlight={.48+.48*light,.50+.32*light,.55+.12*light+sky.warm*.10,alpha*.92}
  love.graphics.setColor(shadow);love.graphics.rectangle("fill",x+size*2,y,size*23,size*2)
  for _,part in ipairs({{5,0,4},{11,-2,6},{18,-1,5},{23,1,3}})do drawBlob(x+part[1]*size,y+part[2]*rowStep,part[3],size,shadow,rowStep)end
  love.graphics.setColor(body);love.graphics.rectangle("fill",x+size*2,y-rowStep,size*20,size*2)
  for _,part in ipairs({{6,-2,3},{11,-4,4},{17,-3,4},{21,-1,3}})do drawBlob(x+part[1]*size,y+part[2]*rowStep,part[3],size,body,rowStep)end
  for _,part in ipairs({{9,-5,2},{13,-6,3},{18,-4,2}})do drawBlob(x+part[1]*size,y+part[2]*rowStep,part[3],size,highlight,rowStep)end
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
 local light=sky.light
 ridge(horizon+unit*5,h*.20,unit*4,{.07+.16*light,.10+.21*light,.17+.22*light,1},.8,parallax*unit*2)
 ridge(horizon+unit*9,h*.13,unit*3,{.035+.065*light,.08+.16*light,.12+.17*light,1},2.1,parallax*unit*4)
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
 drawRow(horizon+unit*8,-unit*3,14,h*.24,{.18+.40*light,.23+.41*light,.22+.27*light,.76},2,1,-parallax*unit*3,1)
 love.graphics.setColor(.08+.22*light,.15+.28*light,.10+.11*light,1);love.graphics.rectangle("fill",0,horizon,w,h-horizon)
 love.graphics.setColor(.12+.30*light,.19+.35*light,.13+.14*light,1);love.graphics.rectangle("fill",0,horizon,w,unit*5)
 local groundOffset=-parallax*unit*7
 local floor,floorQuads=self.backgroundFloor,self.backgroundFloorQuads or{}
 local function drawFloor(index,x,y,scale,alpha,flip)
  if not floor or not floorQuads[index]then return end
  love.graphics.setColor(.30+.70*light,.34+.66*light,.42+.58*light,alpha);love.graphics.draw(floor,floorQuads[index],math.floor(x+groundOffset),math.floor(y),0,scale*(flip or 1),scale,64,48)
 end
 drawFloor(4,w*.67,h*.62,.80,.38);drawFloor(1,w*.68,h*.72,1.18,.42,-1);drawFloor(4,w*.70,h*.84,1.72,.48)
 drawFloor(8,w*.27,h*.72,1.38,.24,-1);drawFloor(4,w*.42,h*.84,1.50,.27);drawFloor(3,w*.35,h*.91,.76,.58,-1)
 drawFloor(2,w*.55,h*.89,.78,.82);drawFloor(3,w*.46,h*.78,.68,.66,-1);drawFloor(6,w*.91,h*.86,.82,.78)
 -- 동료는 뒤쪽 공터의 지면에 서고 전경 나무가 그 위를 덮는다. 그래서 나무
 -- 앞에 붙인 스티커가 아니라 실제 숲 사이를 돌아다니는 깊이로 읽힌다.
 local companionSplit=h*.82
 if showCompanions then LobbyCompanions.draw(self.lobbyCompanions,light,"behind",companionSplit,groundOffset)end
 drawRow(h*.93,w*.55,5,h*.43,{.24+.76*light,.29+.71*light,.38+.62*light,1},1,1,groundOffset,2)
 if showCompanions then LobbyCompanions.draw(self.lobbyCompanions,light,"front",companionSplit,groundOffset)end
 local props=self.backgroundProps or{}
 local function drawProp(name,x,ground,targetH,tint)
  local image=props[name];if not image then return end
  local iw,ih=image:getDimensions();local scale=targetH/ih;love.graphics.setColor(tint or{1,1,1,1});love.graphics.draw(image,math.floor(x+groundOffset),math.floor(ground-targetH),0,scale,scale)
 end
 local propTint={.28+.72*light,.31+.69*light,.40+.60*light,1}
 drawProp("rock",w*.50,h*.93,h*.10,propTint);drawProp("log",w*.73,h*.96,h*.11,propTint)
 drawProp("fern",w*.46,h*.91,h*.085,propTint);drawProp("fern",w*.88,h*.94,h*.10,propTint)
 love.graphics.setColor(.04+.10*light,.10+.18*light,.07+.09*light,.72);love.graphics.rectangle("fill",0,h*.955,w,h*.045)
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
 -- 원반을 먼저 그린다. 바가 그 위를 덮어야 "뒤에서 솟았다"가 된다.
 self:drawAudioDisc(x,y,w)
 love.graphics.setColor(.020,.070,.050,.97);love.graphics.rectangle("fill",x,y,w,h)
 love.graphics.setColor(.34,.72,.50,.88);love.graphics.rectangle("fill",x,y,w,2);love.graphics.rectangle("fill",x,y+h-2,w,2);love.graphics.rectangle("fill",x,y,2,h);love.graphics.rectangle("fill",x+w-2,y,2,h)
 love.graphics.setColor(.95,.62,.18,.92);love.graphics.rectangle("fill",x,y,5,h)
 -- 원반이 드나드는 슬롯. 바 윗변의 초록 테두리를 원반 폭만큼 어둡게 끊어 준다.
 local key,cdx=self:audioDiscPlacement(x,w)
 if key then
  local slot=CdArt.radius(key)*.34
  love.graphics.setColor(.008,.030,.022,.95)
  love.graphics.rectangle("fill",cdx-slot,y,slot*2,3)
 end
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
end

-- 원반은 바 폭에 맞춰 두 크기 중 하나를 고른다. 한쪽을 확대·축소해 쓰면 트랙
-- 링이 반씩 잘려 무늬가 깨지므로, 각 크기를 자기 격자에서 따로 구워 두고 고른다.
function Lobby:audioDiscPlacement(x,w)
 local key=w>=560 and "large" or "small"
 return key,math.floor(x+w*.5)
end

-- 바 뒤에서 솟아 위쪽 절반만 보이는 CD. 원반 중심을 바 윗변에 두면 가운데
-- 구멍까지 반원으로 잘려 기계에 물려 있는 것으로 읽힌다.
function Lobby:drawAudioDisc(x,y,w)
 local key,cx=self:audioDiscPlacement(x,w)
 local radius=CdArt.radius(key)
 -- 별도 원형 후광은 두지 않는다. 바 아래로 후광의 아래쪽 반원이 새어 나오면
 -- 원반을 실제보다 두 배 크게 보이게 하고 숲 바닥을 가린다.
 CdArt.draw(self.audioCd,key,self.audioTrack or 1,cx,y)
 -- 재생 표시등은 바 위가 아니라 원반 옆 슬롯 어깨에 둔다.
 love.graphics.setColor(.95,.62,.18,self.audioPlaying and .95 or .30)
 love.graphics.rectangle("fill",cx+radius-6,y-7,4,4)
end

function Lobby:draw(game)
 local w,h=love.graphics.getDimensions();local f=self.fonts
 local titleFont=self.pixelTitle or f.display or self.displayFont or f.heading
 local menuFont=self.pixelMenu or f.heading;local smallFont=self.pixelSmall or f.small;local tinyFont=self.pixelTiny or f.small
 LobbyCompanions.sync(self.lobbyCompanions,game and game.characterTraits,w,h)
 self:drawBackground(w,h,true)
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
