local F=require("src.frontend_ui")
local Lobby={};Lobby.__index=Lobby

-- 현재 플레이테스트는 기록 모드 하나에 집중한다. 일반 작전 버튼과 진입 코드는
-- 삭제하지 않았으며 Game:startClearcut 이하에 보존되어 있다.
local ACTIVE_DEVELOPMENT_MODE="score_attack"
local TRACKS={"FOREST DAY / LOOP 07","RIVER LINE / LOOP 03","OWL SHIFT / LOOP 11"}
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
 return setmetatable({images=images,fonts=fonts,time=0,activeDevelopmentMode=ACTIVE_DEVELOPMENT_MODE,menuFocus=1,audioTrack=1,audioPlaying=true,microFont=love.graphics.newFont("assets/font-korean-bold.ttf",12)},Lobby)
end

function Lobby:update(dt)
 self.time=self.time+dt
 local mx,my=love.mouse.getPosition()
 for i,box in ipairs(self.menuBoxes or {})do if inside(box,mx,my)then self.menuFocus=i end end
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
 love.graphics.setColor(.008,.016,.013,1);love.graphics.rectangle("fill",0,0,w,h)
 for y=0,h,6 do love.graphics.setColor(.20,.42,.32,.018);love.graphics.rectangle("fill",0,y,w,1)end
 local step=math.max(24,math.floor(math.min(w,h)/18))
 for y=step,h,step do for x=(y/step%2)*step,w,step*2 do
  love.graphics.setColor(.34,.62,.44,.022);love.graphics.rectangle("fill",x,y,2,2)
 end end
end

function Lobby:drawMenu(game,x,y,w,rowH,gap,f,micro)
 self.menuBoxes={}
 for i,item in ipairs(MENU)do
  local box={x=x,y=y+(i-1)*(rowH+gap),w=w,h=rowH};self.menuBoxes[i]=box
  if item.action=="score_attack"then self.scoreAttackBox=box
  elseif item.action=="character_traits"then self.traitsBox=box
  elseif item.action=="skill_sandbox"then self.sandboxBox=box
  elseif item.action=="achievements"then self.achievementBox=box
  elseif item.action=="settings"then self.settingsBox=box end
  local selected=i==(self.menuFocus or 1);local offset=selected and 10 or 0
  love.graphics.setColor(selected and {.035,.10,.075,1}or{.012,.027,.022,1});love.graphics.rectangle("fill",box.x,box.y,box.w,box.h)
  love.graphics.setColor(selected and {.95,.62,.18,1}or{.16,.38,.29,.65});love.graphics.rectangle("fill",box.x,box.y,selected and 4 or 1,box.h)
  love.graphics.setColor(.22,.47,.35,selected and .68 or .20);love.graphics.rectangle("fill",box.x+12,box.y+box.h-1,box.w-12,1)
  love.graphics.setFont(f.heading);love.graphics.setColor(selected and {.95,.94,.80,1}or{.58,.67,.59,1});love.graphics.print(item.label,box.x+18+offset,box.y+box.h/2-f.heading:getHeight()/2)
  love.graphics.setFont(micro);love.graphics.setColor(selected and {.95,.62,.18,1}or{.35,.48,.40,1})
  local suffix="["..item.key.."]"
  if item.action=="character_traits"and game and game.characterTraits then suffix=string.format("%d P   %s",game.characterTraits.data.currency or 0,suffix)end
  love.graphics.printf(suffix,box.x,box.y+box.h/2-micro:getHeight()/2,box.w-16,"right")
 end
end

function Lobby:drawAudio(x,y,w,h,f,micro)
 love.graphics.setColor(.005,.012,.010,.96);love.graphics.rectangle("fill",x,y,w,h)
 love.graphics.setColor(.25,.58,.43,.72);love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1)
 love.graphics.setColor(.95,.62,.18,.85);love.graphics.rectangle("fill",x,y,3,h)
 local button=math.min(28,h-12);local by=y+(h-button)/2
 self.audioPrevBox={x=x+12,y=by,w=button,h=button};self.audioPlayBox={x=x+46,y=by,w=button,h=button};self.audioNextBox={x=x+80,y=by,w=button,h=button}
 for _,data in ipairs({{self.audioPrevBox,"<"},{self.audioPlayBox,self.audioPlaying and "II"or">"},{self.audioNextBox,">"}})do
  local box,label=data[1],data[2];local hover=inside(box,love.mouse.getPosition())
  love.graphics.setColor(hover and {.10,.22,.16,1}or{.025,.06,.045,1});love.graphics.rectangle("fill",box.x,box.y,box.w,box.h)
  love.graphics.setColor(hover and {.95,.62,.18,1}or{.39,.68,.52,1});love.graphics.rectangle("line",box.x+.5,box.y+.5,box.w-1,box.h-1)
  love.graphics.setFont(micro);love.graphics.printf(label,box.x,box.y+box.h/2-micro:getHeight()/2,box.w,"center")
 end
 local waveX=x+122;local waveW=math.min(112,w*.27)
 for i=0,15 do
  local height=self.audioPlaying and 3+math.floor((math.sin(i*1.7+self.time*3)+1)*5)or 3
  love.graphics.setColor(.95,.62,.18,self.audioPlaying and .84 or .28);love.graphics.rectangle("fill",waveX+i*(waveW/16),y+h/2-height/2,3,height)
 end
 love.graphics.setFont(micro);love.graphics.setColor(.53,.66,.56);love.graphics.printf(TRACKS[self.audioTrack or 1],waveX+waveW+12,y+h/2-micro:getHeight()/2,w-(waveX-x)-waveW-24,"right")
end

function Lobby:draw(game)
 local w,h=love.graphics.getDimensions();local f=self.fonts;local micro=self.microFont or f.small
 local display=f.display or self.displayFont or f.heading
 self:drawBackground(w,h)
 local compact=w<1080 or h<640;local x=math.max(24,math.floor(w*.07));local menuW=math.min(compact and 430 or 470,math.floor(w*.46))
 local titleY=math.floor(h*(compact and .09 or .11))
 love.graphics.setFont(display);love.graphics.setColor(.93,.94,.80);love.graphics.print("LAST HAUL",x,titleY)
 love.graphics.setFont(micro);love.graphics.setColor(.38,.62,.48);love.graphics.print("벌목 기록",x,titleY+display:getHeight()+4)
 local rowH=compact and 43 or 50;local gap=compact and 4 or 6;local menuY=titleY+display:getHeight()+42
 self:drawMenu(game,x,menuY,menuW,rowH,gap,f,micro)
 local audioW=math.min(compact and 530 or 590,w-x*2);self:drawAudio(x,h-(compact and 58 or 68),audioW,compact and 40 or 44,f,micro)
 love.graphics.setFont(micro);love.graphics.setColor(.30,.43,.35);love.graphics.printf("R 재생  ·  [ ] 트랙  ·  ESC 종료",0,h-20,w-x,"right")
end

return Lobby
