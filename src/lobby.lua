local F=require("src.frontend_ui")
local Lobby={}; Lobby.__index=Lobby
-- 현재 플레이테스트는 기록 모드 하나에 집중한다. 일반 작전 버튼과 진입 코드는
-- 삭제하지 않았으며 Game:startClearcut 이하에 보존되어 있다.
local ACTIVE_DEVELOPMENT_MODE="score_attack"
local function inside(b,x,y) return F.inside(b,x,y) end
function Lobby.new(images,fonts)
 local bg=love.graphics.newImage("assets/lobby-forest-lofi-day-pixel-v4.png"); bg:setFilter("nearest","nearest")
 return setmetatable({images=images,fonts=fonts,background=bg,time=0,activeDevelopmentMode=ACTIVE_DEVELOPMENT_MODE,scoreAttackHover=0,traitsHover=0,microFont=love.graphics.newFont("assets/font-korean-bold.ttf",12)},Lobby)
end
function Lobby:update(dt)
 self.time=self.time+dt;local mx,my=love.mouse.getPosition();local k=math.min(1,dt*11)
 local scoreTarget=inside(self.scoreAttackBox,mx,my)and 1 or 0;self.scoreAttackHover=self.scoreAttackHover+(scoreTarget-self.scoreAttackHover)*k
 local traitsTarget=inside(self.traitsBox,mx,my)and 1 or 0;self.traitsHover=self.traitsHover+(traitsTarget-self.traitsHover)*k
end
function Lobby:keypressed(key)
 if key=="return" or key=="space" or key=="m" then return "score_attack" elseif key=="a" then return "achievements" elseif key=="t" then return "character_traits" elseif key=="p" then return "skill_sandbox" end
end
function Lobby:mousepressed(x,y,button)
 if button~=1 then return end
 if inside(self.scoreAttackBox,x,y) then return "score_attack" elseif inside(self.traitsBox,x,y) then return "character_traits" elseif inside(self.achievementBox,x,y) then return "achievements" elseif inside(self.sandboxBox,x,y) then return "skill_sandbox" elseif inside(self.settingsBox,x,y) then return "settings" end
end
function Lobby:drawBackground(w,h)
 local iw,ih=self.background:getDimensions(); local scale=math.max(w/iw,h/ih)*1.025; local dw,dh=iw*scale,ih*scale
 love.graphics.setColor(1,1,1,1); love.graphics.draw(self.background,(w-dw)/2+math.sin(self.time*.12)*4,(h-dh)/2,0,scale,scale)
 love.graphics.setColor(.96,.90,.58,.035); love.graphics.rectangle("fill",0,0,w,h)
 for i=0,24 do local t=i/24; love.graphics.setColor(.025,.11,.075,.22*(1-t)^2); love.graphics.rectangle("fill",t*w*.58,0,w*.58/24+2,h) end
 for y=0,h,4 do love.graphics.setColor(0,0,0,.045); love.graphics.rectangle("fill",0,y,w,1) end
end
function Lobby:drawStartButton(box,f)
 local x,y,w,h=box.x,box.y,box.w,box.h
 local hoverT=self.scoreAttackHover or 0; local lift=hoverT*4; local by=y-lift
 local pulse=.5+math.sin(self.time*2.2)*.5
 for i=1,3 do
  local t=i/3
  love.graphics.setColor(.95,.62,.18,(.09+.10*hoverT)*(1-t)*(.45+.55*pulse))
  love.graphics.rectangle("fill",x-4-i*6,by-4-i*6,w+8+i*12,h+8+i*12,9+i*2,9+i*2)
 end
 love.graphics.setColor(0,0,0,.5); love.graphics.rectangle("fill",x+5,by+9,w,h,7,7)
 love.graphics.setColor(.06,.04,.015,1); love.graphics.rectangle("fill",x,by,w,h,7,7)
 local bands=4; local innerY,innerH=by+2,h-4
 for i=0,bands-1 do
  local t=i/(bands-1)
  local r=math.min(1,.99-.16*t+(hoverT*.03)); local g=math.min(1,.68-.20*t+(hoverT*.04)); local b=.22-.10*t
  local yStart=innerY+math.floor(innerH*i/bands); local yEnd=innerY+math.floor(innerH*(i+1)/bands)
  love.graphics.setColor(r,g,b,1)
  love.graphics.rectangle("fill",x+2,yStart,w-4,yEnd-yStart)
 end
 love.graphics.setColor(.99,.86,.5,.45); love.graphics.rectangle("fill",x+2,by+3,7,h-6,3,3)
 love.graphics.setColor(1,1,1,.24); love.graphics.rectangle("fill",x+10,by+3,w-20,3)
 love.graphics.setColor(.32,.20,.05,.95); love.graphics.rectangle("line",x+.5,by+.5,w-1,h-1,7,7)
 local bl=10
 for _,corner in ipairs({{x+2,by+2,1,1},{x+w-2,by+2,-1,1},{x+2,by+h-2,1,-1},{x+w-2,by+h-2,-1,-1}}) do
  local cx,cy,dx,dy=corner[1],corner[2],corner[3],corner[4]
  love.graphics.setColor(1,.86,.55,.85); love.graphics.setLineWidth(2)
  love.graphics.line(cx,cy,cx+bl*dx,cy); love.graphics.line(cx,cy,cx,cy+bl*dy)
  love.graphics.setLineWidth(1)
 end
 local tf=f.title or f.heading; love.graphics.setFont(tf)
 love.graphics.setColor(.08,.05,.015,1)
 love.graphics.polygon("fill",x+26,by+h/2-9,x+26,by+h/2+9,x+41,by+h/2)
 love.graphics.printf("게임 시작",x+56,by+h/2-tf:getHeight()/2,w-56-64,"left")
 love.graphics.setColor(.10,.06,.02,.55); love.graphics.rectangle("fill",x+w-64,by+h/2-17,48,34,4,4)
 love.graphics.setColor(.08,.05,.015,1); love.graphics.setFont(f.small)
 love.graphics.printf("ENT",x+w-64,by+h/2-f.small:getHeight()/2,48,"center")
 return inside(box,love.mouse.getPosition())
end
function Lobby:drawResearchButton(box,f)
 local x,y,w,h=box.x,box.y,box.w,box.h;local hover=self.traitsHover or 0;y=y-hover*2
 love.graphics.setColor(0,0,0,.40);love.graphics.rectangle("fill",x+4,y+7,w,h,5,5)
 local bands={{.055,.18,.14},{.065,.23,.17},{.075,.28,.20},{.085,.32,.23}}
 for i,c in ipairs(bands)do local yy=y+math.floor((i-1)*h/#bands);local yn=y+math.floor(i*h/#bands);love.graphics.setColor(c[1]+hover*.018,c[2]+hover*.035,c[3]+hover*.025,1);love.graphics.rectangle("fill",x+1,yy,w-2,yn-yy)end
 love.graphics.setColor(.34,.82,.56,.78+hover*.18);love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,5,5)
 love.graphics.setColor(.94,.63,.20,1);love.graphics.rectangle("fill",x+14,y+12,46,h-24,3,3)
 love.graphics.setFont(f.small);love.graphics.setColor(.08,.055,.018,1);love.graphics.printf("LAB",x+14,y+h/2-f.small:getHeight()/2,46,"center")
 love.graphics.setColor(.92,.95,.79,1);love.graphics.setFont(f.heading);love.graphics.print("강화하기",x+74,y+9)
 love.graphics.setFont(self.microFont or f.small);love.graphics.setColor(.59,.76,.65,1);love.graphics.print("영구 전투 · 재생 단계 · 허용량",x+75,y+36)
 love.graphics.setColor(.05,.13,.10,.88);love.graphics.rectangle("fill",x+w-50,y+h/2-13,36,26,3,3)
 love.graphics.setColor(.72,.90,.73,1);love.graphics.printf("T",x+w-50,y+h/2-(self.microFont or f.small):getHeight()/2,36,"center")
end

function Lobby:drawActiveRules(x,y,w,f)
 love.graphics.setColor(.015,.055,.038,.90);love.graphics.rectangle("fill",x,y,w,132,6,6)
 love.graphics.setColor(.38,.78,.52,.76);love.graphics.rectangle("line",x+.5,y+.5,w-1,131,6,6)
 love.graphics.setFont(self.microFont or f.small);love.graphics.setColor(.95,.63,.20);love.graphics.print("ACTIVE BUILD  ·  DIRECT START",x+18,y+14)
 local rows={{"종료","활성 나무 12그루"},{"산림","시작 6그루 · 영구 재생 단계"},{"위협","첫 45초 몬스터 없음"},{"성장","인게임 3택 없음 · 영구 연구"}}
 for i,row in ipairs(rows)do local yy=y+36+(i-1)*22;love.graphics.setColor(.48,.67,.55);love.graphics.print(row[1],x+18,yy);love.graphics.setColor(.88,.91,.76);love.graphics.print(row[2],x+82,yy)end
end
function Lobby:drawScoreAttackButton(box,f)
 local x,y,w,h=box.x,box.y,box.w,box.h;local hover=self.scoreAttackHover or 0;local lift=hover*2;y=y-lift
 love.graphics.setColor(0,0,0,.42);love.graphics.rectangle("fill",x+4,y+7,w,h,5,5)
 local bands={{.055,.18,.14},{.065,.23,.17},{.075,.28,.20},{.085,.32,.23}}
 for i,c in ipairs(bands)do local yy=y+math.floor((i-1)*h/#bands);local yn=y+math.floor(i*h/#bands);love.graphics.setColor(c[1]+hover*.018,c[2]+hover*.035,c[3]+hover*.025,1);love.graphics.rectangle("fill",x+1,yy,w-2,yn-yy)end
 love.graphics.setColor(.34,.82,.56,.78+hover*.18);love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,5,5)
 love.graphics.setColor(.94,.63,.20,1);love.graphics.rectangle("fill",x+14,y+12,46,h-24,3,3)
 love.graphics.setFont(f.small);love.graphics.setColor(.08,.055,.018,1);love.graphics.printf("LIVE",x+14,y+h/2-f.small:getHeight()/2,46,"center")
 love.graphics.setColor(.92,.95,.79,1);love.graphics.setFont(f.heading);love.graphics.print("벌목 기록 모드",x+74,y+9)
 love.graphics.setFont(self.microFont or f.small);love.graphics.setColor(.59,.76,.65,1);love.graphics.print("나무가 허용량에 닿으면 종료",x+75,y+36)
 love.graphics.setColor(.05,.13,.10,.88);love.graphics.rectangle("fill",x+w-50,y+h/2-13,36,26,3,3)
 love.graphics.setColor(.72,.90,.73,1);love.graphics.printf("M",x+w-50,y+h/2-(self.microFont or f.small):getHeight()/2,36,"center")
end
function Lobby:draw()
 local w,h=love.graphics.getDimensions(); local f=self.fonts; local micro=self.microFont or self.labelFont or f.small; self:drawBackground(w,h)
 local left=math.max(34,w*.045); local compact=w<1080
 love.graphics.setColor(.96,.92,.70,.76); love.graphics.rectangle("fill",left-14,18,math.min(410,w*.37),166,6,6)
 love.graphics.setColor(.08,.27,.20,.58); love.graphics.rectangle("line",left-13.5,18.5,math.min(410,w*.37)-1,165,6,6)
 love.graphics.setColor(.08,.19,.12,.95); love.graphics.setFont(micro); love.graphics.print("ACTIVE PROTOTYPE  /  FOREST CLEARING",left,30)
 love.graphics.setColor(.05,.31,.28); love.graphics.setFont(f.display); love.graphics.print("LAST HAUL",left,52)
 love.graphics.setColor(.12,.15,.08,.96); love.graphics.setFont(f.heading); love.graphics.print("숲 전멸 기록 실험",left,111)
 love.graphics.setColor(.08,.36,.31,.75); love.graphics.rectangle("fill",left,145,math.min(390,w*.35),2)
 love.graphics.setFont(micro); love.graphics.setColor(.12,.28,.18,.9); love.graphics.print("WEAPON  ·  COMPANION  ·  FACILITY BUILD",left,158)
 local nav={{"연습","sandboxBox"},{"업적","achievementBox"},{"설정","settingsBox"}}
 local nw,ng=compact and 58 or 72,6; local navY=h-62; local nx=w-34-(nw*#nav+ng*(#nav-1))
 for i,item in ipairs(nav) do local b={x=nx+(i-1)*(nw+ng),y=navY,w=nw,h=36}; self[item[2]]=b; F.button(b,item[1],micro,{accent=i==4 and F.colors.teal or F.colors.amber}) end
 local bw=math.min(370,w*.34); local bh=82
 self.scoreAttackBox={x=left,y=math.max(205,h*.39),w=bw,h=bh}
 self:drawStartButton(self.scoreAttackBox,f)
 self.traitsBox={x=left,y=self.scoreAttackBox.y+bh+14,w=bw,h=62}
 self:drawResearchButton(self.traitsBox,f)
 self:drawActiveRules(math.max(left+bw+28,w-390),math.max(205,h*.39),350,f)
 local py=h-74; love.graphics.setColor(.008,.018,.025,.88); love.graphics.rectangle("fill",left,py,math.min(420,w*.40),48,5,5)
 love.graphics.setColor(.28,.70,.66,.7); love.graphics.rectangle("line",left+.5,py+.5,math.min(420,w*.40)-1,47,5,5)
 love.graphics.setFont(f.heading); love.graphics.setColor(.91,.91,.80); love.graphics.print("◀",left+18,py+10); love.graphics.print("Ⅱ",left+64,py+9); love.graphics.print("▶",left+108,py+10)
 for i=0,15 do local bar=4+math.floor((math.sin(i*1.7+self.time*2)+1)*5); love.graphics.setColor(.93,.62,.20,.8); love.graphics.rectangle("fill",left+164+i*7,py+24-bar/2,3,bar) end
 love.graphics.setFont(micro); love.graphics.setColor(.68,.78,.70); love.graphics.print("FOREST DAY / LOOP 07",left+292,py+17)
 love.graphics.setColor(.62,.70,.66); love.graphics.printf("ESC  종료",0,h-24,w-34,"right")
end
return Lobby
