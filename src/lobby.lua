local F=require("src.frontend_ui")
local Lobby={}; Lobby.__index=Lobby

-- 현재 플레이테스트는 기록 모드 하나에 집중한다. 일반 작전 버튼과 진입 코드는
-- 삭제하지 않았으며 Game:startClearcut 이하에 보존되어 있다.
local ACTIVE_DEVELOPMENT_MODE="score_attack"
local RADIO_STATIONS={
 {band="88.3",name="벌목반 호출",detail="현장 교신 · 작업 준비"},
 {band="91.7",name="산림 기상망",detail="맑음 · 동풍 2 m/s"},
 {band="104.2",name="야간 순찰",detail="무인 반복 송출"},
}

local function inside(b,x,y) return F.inside(b,x,y) end
local function fontHeight(font) return font and font:getHeight() or 14 end

function Lobby.new(images,fonts)
 return setmetatable({
  images=images,fonts=fonts,time=0,activeDevelopmentMode=ACTIVE_DEVELOPMENT_MODE,
  scoreAttackHover=0,traitsHover=0,radioStation=1,radioPlaying=true,radioSignal=.68,diagnosticTab=1,
  microFont=love.graphics.newFont("assets/font-korean-bold.ttf",12)
 },Lobby)
end

function Lobby:update(dt)
 self.time=self.time+dt
 local mx,my=love.mouse.getPosition();local k=math.min(1,dt*11)
 local scoreTarget=inside(self.scoreAttackBox,mx,my)and 1 or 0
 local traitsTarget=inside(self.traitsBox,mx,my)and 1 or 0
 self.scoreAttackHover=self.scoreAttackHover+(scoreTarget-self.scoreAttackHover)*k
 self.traitsHover=self.traitsHover+(traitsTarget-self.traitsHover)*k
end

function Lobby:cycleRadio(direction)
 self.radioStation=((self.radioStation or 1)-1+direction)%#RADIO_STATIONS+1
 self.radioPlaying=true
end

function Lobby:keypressed(key)
 if key=="return" or key=="space" or key=="m" then return "score_attack"
 elseif key=="a" then return "achievements"
 elseif key=="t" then return "character_traits"
 elseif key=="p" then return "skill_sandbox"
 elseif key=="1" or key=="2" or key=="3" then self.diagnosticTab=tonumber(key)
 elseif key=="r" then self.radioPlaying=not self.radioPlaying
 elseif key=="[" then self:cycleRadio(-1)
 elseif key=="]" then self:cycleRadio(1) end
end

function Lobby:mousepressed(x,y,button)
 if button~=1 then return end
 if inside(self.radioPrevBox,x,y) then self:cycleRadio(-1);return end
 if inside(self.radioPlayBox,x,y) then self.radioPlaying=not self.radioPlaying;return end
 if inside(self.radioNextBox,x,y) then self:cycleRadio(1);return end
 if inside(self.radioSignalBox,x,y) then self.radioSignal=math.max(.1,math.min(1,(x-self.radioSignalBox.x)/self.radioSignalBox.w));return end
 for i,box in ipairs(self.diagnosticBoxes or {}) do if inside(box,x,y) then self.diagnosticTab=i;return end end
 if inside(self.scoreAttackBox,x,y) then return "score_attack"
 elseif inside(self.traitsBox,x,y) or inside(self.nextResearchBox,x,y) then return "character_traits"
 elseif inside(self.achievementBox,x,y) then return "achievements"
 elseif inside(self.sandboxBox,x,y) then return "skill_sandbox"
 elseif inside(self.settingsBox,x,y) then return "settings" end
end

function Lobby:drawDiagnostics(box,f,micro,compact)
 local tabs={"산림","무기","동료"};self.diagnosticBoxes={}
 local gap=6;local tabW=(box.w-gap*2)/3
 for i,label in ipairs(tabs) do
  local b={x=box.x+(i-1)*(tabW+gap),y=box.y,w=tabW,h=compact and 25 or 29};self.diagnosticBoxes[i]=b
  F.button(b,label.."  "..i,micro,{accent=i==(self.diagnosticTab or 1) and F.colors.amber or F.colors.teal})
 end
 local y=box.y+(compact and 33 or 38);local selected=self.diagnosticTab or 1
 love.graphics.setColor(.035,.085,.068,.86);love.graphics.rectangle("fill",box.x,y,box.w,box.h-(y-box.y),3,3)
 if selected==1 then
  love.graphics.setColor(.48,.68,.56);love.graphics.print("시작 밀도",box.x+12,y+9)
  love.graphics.setColor(.90,.91,.79);love.graphics.printf("6 / 12",box.x+12,y+9,box.w-24,"right")
  local gx,gy,gw=box.x+12,y+(compact and 29 or 34),box.w-24
  love.graphics.setColor(.08,.13,.11,1);love.graphics.rectangle("fill",gx,gy,gw,8,2,2)
  love.graphics.setColor(.95,.62,.18,.9);love.graphics.rectangle("fill",gx,gy,gw*.5,8,2,2)
  if not compact then love.graphics.setColor(.44,.63,.52);love.graphics.print("0그루 달성 시 재생 단계 저장",box.x+12,gy+13) end
 elseif selected==2 then
  love.graphics.setColor(.88,.90,.78);love.graphics.print("문맥 자동 공격",box.x+12,y+9)
  love.graphics.setColor(.46,.68,.56);love.graphics.print("근접 도끼  ·  원거리 최종 해금 무기",box.x+12,y+(compact and 29 or 34))
 elseif selected==3 then
  love.graphics.setColor(.88,.90,.78);love.graphics.print("졸업 동료 자동 운용",box.x+12,y+9)
  love.graphics.setColor(.46,.68,.56);love.graphics.print("완성한 연구 갈래의 절반 성능 상속",box.x+12,y+(compact and 29 or 34))
 end
end

function Lobby:drawBackground(w,h)
 F.backdrop(w,h,F.colors.teal,.98)
 local grid=math.max(42,math.floor(math.min(w,h)/11))
 love.graphics.setColor(.26,.60,.48,.035)
 for x=0,w,grid do love.graphics.line(x,0,x,h) end
 for y=0,h,grid do love.graphics.line(0,y,w,y) end
 love.graphics.setColor(.95,.62,.18,.045)
 for i=0,5 do
  local yy=h*(.20+i*.13)
  love.graphics.line(w*.48,yy,w,yy-math.sin(self.time*.18+i)*18)
 end
 for i=1,6 do
  local t=(self.time*.08+i*.17)%1
  love.graphics.setColor(.40,.86,.65,.08*(1-t))
  love.graphics.circle("line",w*.83,h*.43,30+t*220)
 end
end

function Lobby:drawStartButton(box,f)
 local x,y,w,h=box.x,box.y,box.w,box.h
 local hover=self.scoreAttackHover or 0;local lift=hover*3;y=y-lift
 love.graphics.setColor(0,0,0,.5);love.graphics.rectangle("fill",x+5,y+8,w,h,5,5)
 love.graphics.setColor(.95+hover*.03,.58+hover*.05,.16,1);love.graphics.rectangle("fill",x,y,w,h,5,5)
 love.graphics.setColor(1,.83,.42,.72);love.graphics.rectangle("fill",x+2,y+2,w-4,3)
 love.graphics.setColor(.22,.12,.025,.9);love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,5,5)
 love.graphics.setColor(.10,.06,.015,1)
 love.graphics.polygon("fill",x+22,y+h/2-8,x+22,y+h/2+8,x+36,y+h/2)
 love.graphics.setFont(f.heading);love.graphics.print("게임 시작",x+50,y+h/2-fontHeight(f.heading)/2)
 local keyW=52;love.graphics.setColor(.16,.09,.02,.5);love.graphics.rectangle("fill",x+w-keyW-12,y+10,keyW,h-20,3,3)
 love.graphics.setFont(self.microFont or f.small);love.graphics.setColor(.12,.07,.015,1)
 love.graphics.printf("ENT",x+w-keyW-12,y+h/2-fontHeight(self.microFont or f.small)/2,keyW,"center")
end

function Lobby:drawResearchButton(box,f)
 local hover=self.traitsHover or 0
 F.frame(box.x,box.y-hover*2,box.w,box.h,F.colors.teal,{selected=hover>.25,corner=false})
 local y=box.y-hover*2
 love.graphics.setColor(.94,.63,.20,1);love.graphics.rectangle("fill",box.x+14,y+11,44,box.h-22,3,3)
 love.graphics.setFont(self.microFont or f.small);love.graphics.setColor(.08,.055,.018,1);love.graphics.printf("LAB",box.x+14,y+box.h/2-fontHeight(self.microFont or f.small)/2,44,"center")
 love.graphics.setColor(.92,.95,.79,1);love.graphics.setFont(f.heading);love.graphics.print("강화하기",box.x+72,y+8)
 love.graphics.setFont(self.microFont or f.small);love.graphics.setColor(.59,.76,.65,1);love.graphics.print("영구 전투 · 재생 단계 · 허용량",box.x+72,y+34)
 love.graphics.setColor(.05,.13,.10,.88);love.graphics.rectangle("fill",box.x+box.w-48,y+box.h/2-13,34,26,3,3)
 love.graphics.setColor(.72,.90,.73,1);love.graphics.printf("T",box.x+box.w-48,y+box.h/2-fontHeight(self.microFont or f.small)/2,34,"center")
end

function Lobby:drawOperationPanel(game,box,f,micro,compact)
 F.frame(box.x,box.y,box.w,box.h,F.colors.amber,{selected=true})
 F.label("active operation",box.x+22,box.y+18,micro,F.colors.amber)
 love.graphics.setFont(f.display);love.graphics.setColor(.93,.94,.82);love.graphics.print("벌목 기록 모드",box.x+22,box.y+43)
 love.graphics.setFont(micro);love.graphics.setColor(.54,.69,.59);love.graphics.print("SCORE ATTACK  /  DIRECT START",box.x+24,box.y+43+fontHeight(f.display)+3)

 local infoY=box.y+(compact and 111 or 126);local rowH=compact and 20 or 24
 local rows={{"시작","활성 나무 6그루"},{"종료","허용량 12그루"},{"위협","첫 45초 몬스터 없음"},{"성장","인게임 3택 없음 · 영구 연구"}}
 for i,row in ipairs(rows) do
  local yy=infoY+(i-1)*rowH
  love.graphics.setColor(.11,.18,.15,.95);love.graphics.rectangle("fill",box.x+22,yy,box.w-44,rowH-3,2,2)
  love.graphics.setFont(micro);love.graphics.setColor(.45,.68,.56);love.graphics.print(row[1],box.x+34,yy+3)
  love.graphics.setColor(.86,.89,.76);love.graphics.print(row[2],box.x+100,yy+3)
 end

 local buttonH=compact and 58 or 68
 self.traitsBox={x=box.x+22,y=box.y+box.h-(compact and 122 or 138),w=box.w-44,h=compact and 52 or 58}
 self.scoreAttackBox={x=box.x+22,y=box.y+box.h-buttonH-20,w=box.w-44,h=buttonH}
 local diagY=infoY+#rows*rowH+8
 self:drawDiagnostics({x=box.x+22,y=diagY,w=box.w-44,h=math.max(54,self.traitsBox.y-diagY-10)},f,micro,compact)
 self:drawResearchButton(self.traitsBox,f)
 self:drawStartButton(self.scoreAttackBox,f)
end

function Lobby:drawRadio(box,f,micro,compact)
 F.frame(box.x,box.y,box.w,box.h,F.colors.teal,{selected=self.radioPlaying})
 F.label("field radio",box.x+18,box.y+14,micro,F.colors.teal)
 local station=RADIO_STATIONS[self.radioStation or 1]
 local displayX,displayY=box.x+18,box.y+40
 local displayW=box.w-(compact and 92 or 120)-36
 love.graphics.setColor(.008,.025,.019,1);love.graphics.rectangle("fill",displayX,displayY,displayW,55,3,3)
 love.graphics.setColor(.32,.83,.56,self.radioPlaying and 1 or .38);love.graphics.setFont(f.heading);love.graphics.print(station.band,displayX+12,displayY+7)
 love.graphics.setFont(micro);love.graphics.setColor(.70,.86,.72,self.radioPlaying and 1 or .48);love.graphics.print(station.name,displayX+78,displayY+9)
 love.graphics.setColor(.42,.61,.49);love.graphics.print(station.detail,displayX+12,displayY+33)

 local speakerX=displayX+displayW+14;local speakerW=box.x+box.w-18-speakerX
 love.graphics.setColor(.025,.046,.038,1);love.graphics.rectangle("fill",speakerX,displayY,speakerW,55,3,3)
 for yy=0,4 do for xx=0,math.max(2,math.floor(speakerW/12)-1) do
  local pulse=self.radioPlaying and (.35+.65*math.abs(math.sin(self.time*3+xx*1.8+yy))) or .18
  love.graphics.setColor(.36,.64,.49,.18+pulse*.36);love.graphics.rectangle("fill",speakerX+6+xx*10,displayY+7+yy*10,3,3)
 end end

 local controlY=box.y+box.h-39;local size=30
 self.radioPrevBox={x=box.x+18,y=controlY,w=size,h=size}
 self.radioPlayBox={x=box.x+54,y=controlY,w=size,h=size}
 self.radioNextBox={x=box.x+90,y=controlY,w=size,h=size}
 F.button(self.radioPrevBox,"<",micro,{accent=F.colors.teal})
 F.button(self.radioPlayBox,self.radioPlaying and "II" or ">",micro,{accent=F.colors.amber})
 F.button(self.radioNextBox,">",micro,{accent=F.colors.teal})
 self.radioSignalBox={x=box.x+138,y=controlY+11,w=box.w-156,h=8}
 love.graphics.setColor(.08,.13,.11,1);love.graphics.rectangle("fill",self.radioSignalBox.x,self.radioSignalBox.y,self.radioSignalBox.w,self.radioSignalBox.h,2,2)
 love.graphics.setColor(.35,.78,.55,.9);love.graphics.rectangle("fill",self.radioSignalBox.x,self.radioSignalBox.y,self.radioSignalBox.w*(self.radioSignal or .68),self.radioSignalBox.h,2,2)
 love.graphics.setColor(.95,.68,.24,1);love.graphics.rectangle("fill",self.radioSignalBox.x+self.radioSignalBox.w*(self.radioSignal or .68)-2,self.radioSignalBox.y-3,4,14)
 love.graphics.setColor(.49,.65,.55);love.graphics.print("SIGNAL",self.radioSignalBox.x,controlY+21)
 love.graphics.printf("R  ON/OFF",self.radioSignalBox.x,controlY+21,self.radioSignalBox.w,"right")
end

function Lobby:drawProgress(game,box,f,micro,compact)
 F.frame(box.x,box.y,box.w,box.h,F.colors.amber,{corner=false})
 F.label("작업 기록",box.x+18,box.y+14,micro,F.colors.amber)
 local traits=game and game.characterTraits;local achievements=game and game.achievements
 local stats=achievements and achievements.data and achievements.data.stats or {}
 local rows={
  {"최고 재생 단계",tostring(stats.best_regen_tier or (traits and traits:getRegenTier()) or 1).."단계"},
  {"보유 연구 코인",string.format("%d P",traits and traits.data.currency or 0)},
  {"누적 벌목",string.format("%d 그루",stats.total_trees or 0)},
  {"작업 횟수",string.format("%d 회",stats.runs or 0)},
 }
 local y=box.y+42;local rowH=compact and 20 or 23
 for _,row in ipairs(rows) do
  love.graphics.setFont(micro);love.graphics.setColor(.48,.63,.54);love.graphics.print(row[1],box.x+18,y)
  love.graphics.setColor(.90,.91,.79);love.graphics.printf(row[2],box.x+18,y,box.w-36,"right");y=y+rowH
 end
 local goal=traits and traits:nextGoal()
 self.nextResearchBox={x=box.x+14,y=box.y+box.h-(compact and 47 or 55),w=box.w-28,h=compact and 34 or 42}
 local hover=inside(self.nextResearchBox,love.mouse.getPosition())
 love.graphics.setColor(.06+(hover and .025 or 0),.15+(hover and .035 or 0),.12,1);love.graphics.rectangle("fill",self.nextResearchBox.x,self.nextResearchBox.y,self.nextResearchBox.w,self.nextResearchBox.h,3,3)
 love.graphics.setColor(.28,.70,.52,hover and 1 or .62);love.graphics.rectangle("line",self.nextResearchBox.x+.5,self.nextResearchBox.y+.5,self.nextResearchBox.w-1,self.nextResearchBox.h-1,3,3)
 love.graphics.setFont(micro);love.graphics.setColor(.48,.68,.56);love.graphics.print("다음 연구",self.nextResearchBox.x+10,self.nextResearchBox.y+5)
 love.graphics.setColor(.88,.90,.76)
 local goalName=goal and goal.name or "연구망 확인";love.graphics.print(goalName,self.nextResearchBox.x+82,self.nextResearchBox.y+5)
 if goal then love.graphics.setColor(goal.affordable and {.44,.86,.53,1} or {.95,.63,.20,1});love.graphics.printf(string.format("%d P",goal.cost),self.nextResearchBox.x+10,self.nextResearchBox.y+5,self.nextResearchBox.w-20,"right") end
end

function Lobby:draw(game)
 local w,h=love.graphics.getDimensions();local f=self.fonts;local micro=self.microFont or self.labelFont or f.small
 self:drawBackground(w,h)
 local compact=w<1080 or h<640;local margin=compact and 24 or math.max(30,w*.035);local gap=compact and 14 or 20
 local headerH=compact and 86 or 108;local footerH=compact and 44 or 48

 love.graphics.setColor(.008,.024,.020,.93);love.graphics.rectangle("fill",0,0,w,headerH)
 love.graphics.setColor(.30,.72,.54,.38);love.graphics.rectangle("fill",margin,headerH-2,w-margin*2,1)
 love.graphics.setFont(micro);love.graphics.setColor(.43,.75,.58);love.graphics.print("LAST HAUL  /  OPERATIONS DESK",margin,compact and 14 or 18)
 love.graphics.setFont(f.display);love.graphics.setColor(.92,.94,.82);love.graphics.print("산림 관제실",margin,compact and 33 or 41)
 local statusW=compact and 206 or 252
 love.graphics.setColor(.04,.12,.095,.96);love.graphics.rectangle("fill",w-margin-statusW,compact and 17 or 24,statusW,compact and 48 or 58,4,4)
 love.graphics.setColor(.34,.84,.57,1);love.graphics.circle("fill",w-margin-statusW+18,compact and 40 or 51,4)
 love.graphics.setFont(micro);love.graphics.setColor(.72,.87,.74);love.graphics.print("NETWORK ONLINE",w-margin-statusW+30,compact and 31 or 39)
 love.graphics.setColor(.46,.62,.51);love.graphics.printf("기록전 전용 빌드",w-margin-statusW+20,compact and 49 or 58,statusW-34,"right")

 local contentY=headerH+gap;local contentH=h-contentY-footerH-gap
 local usableW=w-margin*2;local leftW=math.floor((usableW-gap)*(compact and .56 or .58));local rightW=usableW-gap-leftW
 local leftBox={x=margin,y=contentY,w=leftW,h=contentH};local rightX=margin+leftW+gap
 self:drawOperationPanel(game,leftBox,f,micro,compact)
 local radioH=compact and 150 or 174
 self:drawRadio({x=rightX,y=contentY,w=rightW,h=radioH},f,micro,compact)
 self:drawProgress(game,{x=rightX,y=contentY+radioH+gap,w=rightW,h=contentH-radioH-gap},f,micro,compact)

 local nav={{"연습  P","sandboxBox"},{"업적  A","achievementBox"},{"설정","settingsBox"}}
 local navW=compact and 86 or 104;local navGap=6;local navY=h-footerH+5;local navX=w-margin-(navW*#nav+navGap*(#nav-1))
 for i,item in ipairs(nav) do local b={x=navX+(i-1)*(navW+navGap),y=navY,w=navW,h=footerH-12};self[item[2]]=b;F.button(b,item[1],micro,{accent=F.colors.teal}) end
 love.graphics.setFont(micro);love.graphics.setColor(.44,.58,.49);love.graphics.print("R 라디오  ·  [ ] 채널  ·  ESC 종료",margin,h-footerH+15)
end

return Lobby
