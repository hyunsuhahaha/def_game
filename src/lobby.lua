local F=require("src.frontend_ui")
local Lobby={}; Lobby.__index=Lobby
local function inside(b,x,y) return F.inside(b,x,y) end
function Lobby.new(images,fonts)
 local bg=love.graphics.newImage("assets/lobby-forest-field-hq-pixel-v2.png"); bg:setFilter("linear","linear",8)
 return setmetatable({images=images,fonts=fonts,background=bg,time=0,clearcutHover=0,microFont=love.graphics.newFont("assets/font-korean-bold.ttf",12)},Lobby)
end
function Lobby:update(dt) self.time=self.time+dt; local mx,my=love.mouse.getPosition(); local target=inside(self.clearcutBox,mx,my) and 1 or 0; self.clearcutHover=self.clearcutHover+(target-self.clearcutHover)*math.min(1,dt*11) end
function Lobby:keypressed(key)
 if key=="return" or key=="space" or key=="c" then return "clearcut" elseif key=="a" then return "achievements" elseif key=="t" then return "character_traits" elseif key=="d" then return "character_codex" elseif key=="p" then return "skill_sandbox" end
end
function Lobby:mousepressed(x,y,button)
 if button~=1 then return end
 if inside(self.clearcutBox,x,y) then return "clearcut" elseif inside(self.achievementBox,x,y) then return "achievements" elseif inside(self.traitsBox,x,y) then return "character_traits" elseif inside(self.codexBox,x,y) then return "character_codex" elseif inside(self.sandboxBox,x,y) then return "skill_sandbox" elseif inside(self.settingsBox,x,y) then return "settings" end
end
function Lobby:drawBackground(w,h)
 local iw,ih=self.background:getDimensions(); local scale=math.max(w/iw,h/ih)*1.025; local dw,dh=iw*scale,ih*scale
 love.graphics.setColor(1,1,1,1); love.graphics.draw(self.background,(w-dw)/2+math.sin(self.time*.12)*4,(h-dh)/2,0,scale,scale)
 love.graphics.setColor(.008,.020,.016,.18); love.graphics.rectangle("fill",0,0,w,h)
 for i=0,24 do local t=i/24; love.graphics.setColor(.005,.016,.012,.9*(1-t)^2); love.graphics.rectangle("fill",t*w*.72,0,w*.72/24+2,h) end
 for i=0,12 do local t=i/12; love.graphics.setColor(.004,.012,.01,.6*(1-t)); love.graphics.rectangle("fill",0,h-170+t*170,w,170/12+1) end
end
function Lobby:drawStartButton(box,f)
 local x,y,w,h=box.x,box.y,box.w,box.h
 local hoverT=self.clearcutHover or 0; local lift=hoverT*4; local by=y-lift
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
function Lobby:draw()
 local w,h=love.graphics.getDimensions(); local f=self.fonts; local micro=self.microFont or self.labelFont or f.small; self:drawBackground(w,h)
 love.graphics.setColor(.01,.025,.02,.92); love.graphics.rectangle("fill",0,0,w,76); love.graphics.setColor(.94,.61,.18,.7); love.graphics.rectangle("fill",0,74,w,2)
 love.graphics.setFont(micro); love.graphics.setColor(.95,.91,.76); love.graphics.print("LAST HAUL",34,20); love.graphics.setColor(.48,.58,.52); love.graphics.print("벌목 사무소",34,43)
 local nav={{"스킬 연습장","sandboxBox"},{"인물 기록","codexBox"},{"업적 기록","achievementBox"},{"특성 연구","traitsBox"},{"환경 설정","settingsBox"}}; local nw,ng,ny=108,7,18; local nx=w-30-(nw*#nav+ng*(#nav-1))
 for i,item in ipairs(nav) do local b={x=nx+(i-1)*(nw+ng),y=ny,w=nw,h=42}; self[item[2]]=b; F.button(b,item[1],micro,{accent=i==4 and F.colors.teal or F.colors.amber}) end
 local left=math.max(42,w*.05); local bw=math.min(360,w*.32); local bh=94
 self.clearcutBox={x=left,y=math.max(180,h*.42),w=bw,h=bh}
 self:drawStartButton(self.clearcutBox,f)
 love.graphics.setFont(micro); love.graphics.setColor(.48,.55,.50); love.graphics.print("BUILD 0.9  ·  SAVE ONLINE",left,h-29); love.graphics.setColor(.66,.72,.66); love.graphics.printf("ESC  종료",0,h-29,w-34,"right")
end
return Lobby
